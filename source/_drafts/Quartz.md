---
layout: "post"
title: "Quartz任务调度"
date: "2022-05-12 12:10"
categories: [java]
tags: [job]
---

## 简介

- Quartz是OpenSymphony开源组织在Job scheduling领域又一个开源项目
- [官网](http://www.quartz-scheduler.org/)
- [Doc v2.3.0](http://www.quartz-scheduler.org/documentation/quartz-2.3.0/)
- 核心概念
    - `Job` 表示一个工作，要执行的具体内容。此接口中只有一个方法，`void execute(JobExecutionContext context) `
    - `JobDetail` 表示一个具体的可执行的调度程序，Job 是这个可执行程调度程序所要执行的内容，另外 JobDetail 还包含了这个任务调度的方案和策略
    - `Trigger` 代表一个调度参数的配置，什么时候去调
        - 为JobDetail字表，必须和JobDetail的JobKey一致(JobName+JobGroup)，一个JobDetail可以有多个Trigger
    - `Scheduler` 代表一个调度容器，一个调度容器中可以注册多个 JobDetail 和 Trigger。当 Trigger 与 JobDetail 组合，就可以被 Scheduler 容器调度了
        - 常用实现类为StdScheduler
        - 而QuartzScheduler不属于此Scheduler，QuartzScheduler属于Quartz内置的调度器，用于增删改查任务即触发器等，调度逻辑在QuartzSchedulerThread中
- [cron表达式在线生成](https://qqe2.com/cron)

## 执行原理

- Quartz是通过一个调度线程不断的扫描数据库中的数据来获取到那些已经到点要触发的任务，然后调度执行它的。这个线程就是 QuartzSchedulerThread 类，其run方法中就是quartz的调度逻辑
- QuartzSchedulerThread.run
    - `triggers = this.qsRsrcs.getJobStore().acquireNextTriggers(...)`
        - acquireNextTriggers 基于 JobStoreSupport类(实际是访问数据库)完成，获取将要触发的触发器集合
            - executeInNonManagedTXLock()方法，保证了在分布式的情况，同一时刻，只有一个线程可以执行这个方法
    - `this.qsRsrcs.getJobStore().triggersFired(triggers)`
        - triggersFired 也是在 JobStoreSupport 类中完成，改变trigger状态为 EXECUTING
    - `this.qsRsrcs.getThreadPool().runInThread(shell)` 将任务加入到线程池，等待CPU调度
- 拉取待触发trigger [^1]
    - 调度线程会一次性拉取距离现在，一定时间窗口内的，一定数量内的，即将触发的trigger信息。时间窗口和数量信息可通过参数配置
        - idleWaitTime：默认30s，可通过配置属性org.quartz.scheduler.idleWaitTime设置
        - availThreadCount：获取可用（空闲）的工作线程数量，总会大于1，因为该方法会一直阻塞，直到有工作线程空闲下来。
        - maxBatchSize：一次拉取trigger的最大数量，默认是1，可通过org.quartz.scheduler.batchTriggerAcquisitionMaxCount改写
        - batchTimeWindow：时间窗口调节参数，默认是0，可通过org.quartz.scheduler.batchTriggerAcquisitionFireAheadTimeWindow改写
        - misfireThreshold：超过这个时间还未触发的trigger,被认为发生了misfire,默认60s，可通过org.quartz.jobStore.misfireThreshold设置
    - 调度线程一次会拉取NEXT_FIRE_TIME小于(now + idleWaitTime +batchTimeWindow)，大于(now - misfireThreshold)的，min(availThreadCount,maxBatchSize)个triggers。默认情况下，会拉取未来30s，过去60s之间还未fire的1个trigger。随后将这些triggers的状态由WAITING改为ACQUIRED，并插入fired_triggers表
- 触发trigger [^1]
    - 首先，会检查每个trigger的状态是不是ACQUIRED，如果是，则将状态改为EXECUTING
    - 然后更新trigger的NEXT_FIRE_TIME，如果这个trigger的NEXT_FIRE_TIME为空，也就是未来不再触发，就将其状态改为COMPLETE
    - 如果trigger不允许并发执行（即Job的实现类标注了`@DisallowConcurrentExecution`），则将状态变为BLOCKED，否则就将状态改为WAITING
- 包装trigger，丢给工作线程池
    - 根据trigger信息实例化JobRunShell（实现了Thread接口），同时依据JOB_CLASS_NAME实例化Job，随后将JobRunShell实例丢入工作线程
- 相关注解
    - `@DisallowConcurrentExecution` 加在Job类上，是否允许Job并发执行
        - Quartz定时任务默认都是并发执行的，不会等待此trigger的上一次任务执行完毕，只要trigger间隔时间到就会执行。加上@DisallowConcurrentExecution注解则会等上一次任务执行完毕
    - `@PersistJobDataAfterExecution` 加在Job类上，是否持久化JobDataMap数据
        - 如果加了此注解，在执行任务时修改了JobDataMap的数据，则会将最终的数据持久化到数据库。下次执行任务则获取的新数据

## 基于springboot简单使用

- 下列方式不会将任务持久化(即无需创建Quartz相关任务持久化表)
- pom.xml

```xml
<!--spring boot集成quartz-->
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-quartz</artifactId>
</dependency>
```
- java

```java
public class DateTimeJob extends QuartzJobBean {
    @Override
    protected void executeInternal(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        //获取JobDetail中关联的数据
        String msg = (String) jobExecutionContext.getJobDetail().getJobDataMap().get("msg");
        System.out.println("current time :"+new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()) + "---" + msg);
    }
}

@Configuration
public class QuartzConfig {
    @Bean
    public JobDetail printTimeJobDetail(){
        return JobBuilder.newJob(DateTimeJob.class)//PrintTimeJob我们的业务类
                .withIdentity("DateTimeJob")//可以给该JobDetail起一个id
                //每个JobDetail内都有一个Map，包含了关联到这个Job的数据，在Job类中可以通过context获取
                .usingJobData("msg", "Hello Quartz")//关联键值对
                .storeDurably()//即使没有Trigger关联时，也不需要删除该JobDetail
                .build();
    }
    
    @Bean
    public Trigger printTimeJobTrigger() {
        CronScheduleBuilder cronScheduleBuilder = CronScheduleBuilder.cronSchedule("0/1 * * * * ?");
        return TriggerBuilder.newTrigger()
                .forJob(printTimeJobDetail())//关联上述的JobDetail
                .withIdentity("quartzTaskService")//给Trigger起个名字
                .withSchedule(cronScheduleBuilder)
                .build();
    }
}
```

## 基于数据库持久化任务案例

- 参考: https://blog.csdn.net/qq_34397273/article/details/116853291
    - 源码: https://github.com/liululee/spring-boot-learning
- mysql表结构: https://blog.csdn.net/qq_30285985/article/details/112171744 (含字段说明)
- oracle表结构: https://blog.csdn.net/qq_34397273/article/details/116853291

## 常见问题

### 重复执行

- Quartz会重复执行任务，特别是项目启动时 [^1]
    - 增加配置`org.quartz.jobStore.acquireTriggersWithinLock=true`表示在拉取triggers的时候进行加锁
- 如果两个trigger的间隔周期很短，比如都是1s执行一次，假设A任务很耗时，B任务很快。会出现A任何和B任务被调度到一个线程中了，从而导致B任务也被拖慢(会出现漏执行次数，也可能1s里面执行了多次)
    - 暂未细究原因，A/B任务的间隔周期大一点就很少出现

### quartz设置新增任务默认暂停

- 参考：https://blog.51cto.com/abcd/2478761
- qrtz_paused_trigger_grps(sched_name, trigger_group)触发器组暂停表有两个字段，在通过`scheduler.scheduleJob`创建或更新任务时都会读取此表，如果任务符合则不管原来状态为什么都会改成暂停。而业务需要新增时暂停，之后修改不改变任务的状态(如任务时运行中，修改后任务仍然为运行中)
    - 可通过手动操作此表完成：新增时默认创建qrtz_paused_trigger_grps；修改时读取Tigger状态，如果是暂停则不操作，如果是运行则先删除qrtz_paused_trigger_grps之后，再修改Tigger，最后重新创建qrtz_paused_trigger_grps






---

参考文章

[^1]: https://www.jianshu.com/p/5fae8fd2feb0
