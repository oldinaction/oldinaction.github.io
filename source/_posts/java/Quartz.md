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

## 配置

- 调度(scheduleJob)或恢复调度(resumeTrigger,resumeJob)后不同的misfire对应的处理规则. [参考](https://www.cnblogs.com/skyLogin/p/6927629.html)
    - 参考`MisfireHandler.class`对应线程
    - CronTrigger
        
        withMisfireHandlingInstructionDoNothing
        ——不触发立即执行
        ——等待下次Cron触发频率到达时刻开始按照Cron频率依次执行

        withMisfireHandlingInstructionIgnoreMisfires
        ——以错过的第一个频率时间立刻开始执行
        ——重做错过的所有频率周期后
        ——当下一次触发频率发生时间大于当前时间后，再按照正常的Cron频率依次执行

        withMisfireHandlingInstructionFireAndProceed
        ——以当前时间为触发频率立刻触发一次执行
        ——然后按照Cron频率依次执行
    - SimpleTrigger
        
        withMisfireHandlingInstructionFireNow
        ——以当前时间为触发频率立即触发执行
        ——执行至FinalTIme的剩余周期次数
        ——以调度或恢复调度的时刻为基准的周期频率，FinalTime根据剩余次数和当前时间计算得到
        ——调整后的FinalTime会略大于根据starttime计算的到的FinalTime值

        withMisfireHandlingInstructionIgnoreMisfires
        ——以错过的第一个频率时间立刻开始执行
        ——重做错过的所有频率周期
        ——当下一次触发频率发生时间大于当前时间以后，按照Interval的依次执行剩下的频率
        ——共执行RepeatCount+1次

        withMisfireHandlingInstructionNextWithExistingCount
        ——不触发立即执行
        ——等待下次触发频率周期时刻，执行至FinalTime的剩余周期次数
        ——以startTime为基准计算周期频率，并得到FinalTime
        ——即使中间出现pause，resume以后保持FinalTime时间不变

        withMisfireHandlingInstructionNowWithExistingCount
        ——以当前时间为触发频率立即触发执行
        ——执行至FinalTIme的剩余周期次数
        ——以调度或恢复调度的时刻为基准的周期频率，FinalTime根据剩余次数和当前时间计算得到
        ——调整后的FinalTime会略大于根据starttime计算的到的FinalTime值

        withMisfireHandlingInstructionNextWithRemainingCount
        ——不触发立即执行
        ——等待下次触发频率周期时刻，执行至FinalTime的剩余周期次数
        ——以startTime为基准计算周期频率，并得到FinalTime
        ——即使中间出现pause，resume以后保持FinalTime时间不变

        withMisfireHandlingInstructionNowWithRemainingCount
        ——以当前时间为触发频率立即触发执行
        ——执行至FinalTIme的剩余周期次数
        ——以调度或恢复调度的时刻为基准的周期频率，FinalTime根据剩余次数和当前时间计算得到
        ——调整后的FinalTime会略大于根据starttime计算的到的FinalTime值

        MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_REMAINING_REPEAT_COUNT
        ——此指令导致trigger忘记原始设置的starttime和repeat-count
        ——触发器的repeat-count将被设置为剩余的次数
        ——这样会导致后面无法获得原始设定的starttime和repeat-count值

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
- 参考源码目录: org.quartz.impl.jdbcjobstore
    - mysql表结构: https://blog.csdn.net/qq_30285985/article/details/112171744 (含字段说明)
    - oracle表结构: https://blog.csdn.net/qq_34397273/article/details/116853291
- 查看任务列表

```sql
-- 基于CRON_TRIGGERS
SELECT
    QRTZ_JOB_DETAILS.SCHED_NAME AS "调度器",
    QRTZ_JOB_DETAILS.JOB_GROUP AS "任务组",
    QRTZ_JOB_DETAILS.JOB_NAME AS "任务代码",
    QRTZ_JOB_DETAILS.DESCRIPTION AS "任务描述",
    QRTZ_CRON_TRIGGERS.CRON_EXPRESSION AS "cron表达式",
    QRTZ_TRIGGERS.TRIGGER_STATE AS "任务状态",
    case when QRTZ_TRIGGERS.PREV_FIRE_TIME > 0 then (to_date('1970-01-01 08:00:00','yyyy-mm-dd hh24:mi:ss') + QRTZ_TRIGGERS.PREV_FIRE_TIME/1000/24/60/60) end "上次时间",
    case when QRTZ_TRIGGERS.NEXT_FIRE_TIME > 0 then (to_date('1970-01-01 08:00:00','yyyy-mm-dd hh24:mi:ss') + QRTZ_TRIGGERS.NEXT_FIRE_TIME/1000/24/60/60) end "下次时间",
    case when QRTZ_TRIGGERS.START_TIME > 0 then (to_date('1970-01-01 08:00:00','yyyy-mm-dd hh24:mi:ss') + QRTZ_TRIGGERS.START_TIME/1000/24/60/60) end "开始时间",
    case when QRTZ_TRIGGERS.END_TIME > 0 then (to_date('1970-01-01 08:00:00','yyyy-mm-dd hh24:mi:ss') + QRTZ_TRIGGERS.END_TIME/1000/24/60/60) end "结束时间",
    QRTZ_JOB_DETAILS.JOB_CLASS_NAME AS "任务执行类"
FROM QRTZ_JOB_DETAILS
left JOIN QRTZ_TRIGGERS ON QRTZ_JOB_DETAILS.SCHED_NAME = QRTZ_TRIGGERS.SCHED_NAME
    and QRTZ_JOB_DETAILS.JOB_NAME = QRTZ_TRIGGERS.JOB_NAME and QRTZ_JOB_DETAILS.JOB_GROUP = QRTZ_TRIGGERS.JOB_GROUP
left JOIN QRTZ_CRON_TRIGGERS ON QRTZ_TRIGGERS.SCHED_NAME = QRTZ_CRON_TRIGGERS.SCHED_NAME
    AND QRTZ_TRIGGERS.TRIGGER_NAME = QRTZ_CRON_TRIGGERS.TRIGGER_NAME
    AND QRTZ_TRIGGERS.TRIGGER_GROUP = QRTZ_CRON_TRIGGERS.TRIGGER_GROUP
where 1=1
```

## 常见问题

### 重复执行

- Quartz会重复执行任务，特别是项目启动时 [^1]
    - 增加配置`org.quartz.jobStore.acquireTriggersWithinLock=true`表示在拉取triggers的时候进行加锁
- 如果两个trigger的间隔周期很短，比如都是1s执行一次，假设A任务很耗时，B任务很快。会出现A任何和B任务被调度到一个线程中了，从而导致B任务也被拖慢(会出现漏执行次数，也可能1s里面执行了多次)
    - 暂未细究原因，A/B任务的间隔周期大一点就很少出现

### quartz设置新增任务默认暂停

- 参考：https://blog.51cto.com/abcd/2478761
- qrtz_paused_trigger_grps(sched_name, trigger_group)触发器组暂停表有两个字段
    - 在通过`scheduler.scheduleJob`创建或更新任务时都会读取此表，如果任务符合则不管原来状态为什么都会改成暂停。而业务需要新增时暂停，之后修改不改变任务的状态(如任务时运行中，修改后任务仍然为运行中)
    - 可通过手动操作此表完成
        - 新增时默认创建qrtz_paused_trigger_grps，创建完之后再删除
        - 修改时读取Tigger状态，如果是暂停则不操作，如果是运行则先删除qrtz_paused_trigger_grps之后，再修改Tigger，最后重新创建qrtz_paused_trigger_grps
        - quartz需要和此处操作数据库使用同一数据源(即将quartz使用应用数据源；否则执行scheduleJob时，quartz读取不到创建的临时暂停组)
    - 注意 qrtz_paused_trigger_grps此表示也是`MisfireHandler`线程检查到漏任务后判断是否需要暂停当前任务的依据

### 会自动暂停任务

- 如果上一次job 执行未完成，下一次就不会执行了
    - 解决方法: 如job里面不能抛出异常
- 如应用停止时间过长，导致任务有一次没有执行，那么应用重新启动时就回自动暂停
    - 原因时有一个`MisfireHandler.class`线程，会定时检查任务是否漏执行，如果漏执行了，再判断是否存在对应的暂停组，如果存在则会将此任务暂停
    - 解决: 去掉无用的暂停组
- 如果一个job执行很耗时，超过了定时间隔（如每1小时执行一次，但是每次执行超过了1小时），则有可能自动暂停
    - [未遇到，参考摘录](https://blog.51cto.com/u_15082395/4356459)；简单测试下来结果为：如果阻塞在执行任务时，当阻塞完成后，之前漏掉的执行次数会立刻执行
    - 在耗时较长的任务调整为异步执行，job中只是组织数据，放入缓存，由另外一条线程从缓存中获取数据进行处理，如果另外一条线程还未处理完上一批次的数据，则下次job任务执行时不再向缓存中添加数据


---

参考文章

[^1]: https://www.jianshu.com/p/5fae8fd2feb0
