---
layout: "post"
title: "OFBiz源码"
date: "2017-12-09 10:17"
categories: java
tags: [ofbiz, uml, src]
---

## 模型

### 模型列表

- webapp 中类图
- Event 调用过程
- Contorl 处理过程
- 登录
- 校验登录 extensionCheckLogin
- view 渲染
- screen 渲染
    - 菜单渲染参考: ModelMenu、HtmlMenuRenderer

<embed width="1000" height="800" src="/data/pdf/OFBiz-UML.pdf" internalinstanceid="7">

### 服务/任务机制模型图

<embed width="1000" height="800" src="/data/pdf/OFBiz-Service-Job.pdf" internalinstanceid="7">

## 服务

### 服务调用

- ServiceDispatcher
    - `getInstance(Delegator)` 基于Delegator组装ServiceDispatcher实例(传入Delegator是需要考虑Tenant机制)
    - `runSync(String localName, ModelService service, Map<String, ? extends Object> context)` 调用服务方法
        - `invokeResult = engine.runSync(localName, modelService, context);` 基于engine实例调用服务，如StandardJavaEngine
            - StandardJavaEngine#serviceInvoker: `result = m.invoke(null, dctx, context);` dctx为服务DispatchContext对象, context为Map参数
    - ServiceDispatcher的创建
        - ServiceContainer#getLocalDispatcher(String dispatcherName, Delegator delegator)
            - GenericDispatcherFactory#createLocalDispatcher
                - new GenericDispatcher: `ServiceDispatcher.getInstance(delegator)`
        - 其中dispatcherName只是一个标识符(用于缓存)
            - HTTP场景: `ContextFilter.makeWebappDispatcher` 中取的是web.xml中的localDispatcherName参数
            - 任务场景: `JobManager#getDispatcher` 中取的是delegator.getDelegatorName(), 如default#SAAS1

        ```java
        public static LocalDispatcher getLocalDispatcher(String dispatcherName, Delegator delegator) {
            if (dispatcherName == null) {
                // 类似JobManager#getDispatcher
                dispatcherName = delegator.getDelegatorName();
                Debug.logWarning("ServiceContainer.getLocalDispatcher method called with a null dispatcherName, defaulting to delegator name.", module);
            }
            if (UtilValidate.isNotEmpty(delegator.getDelegatorTenantId())) {
                // 考虑了Tenant，如 demo#SAAS1
                dispatcherName = dispatcherName.concat("#").concat(delegator.getDelegatorTenantId());
            }
            // 先读取本地缓存
            LocalDispatcher dispatcher = dispatcherCache.get(dispatcherName);
            if (dispatcher == null) {
                dispatcher = dispatcherFactory.createLocalDispatcher(dispatcherName, delegator);
                dispatcherCache.putIfAbsent(dispatcherName, dispatcher);
                dispatcher = dispatcherCache.get(dispatcherName);
                if (Debug.infoOn()) Debug.logInfo("Created new dispatcher [" + dispatcherName + "] (" + Thread.currentThread().getName() + ")", module);
            }
            return dispatcher;
        }
        ```

### 任务机制源码分析

- `org.ofbiz.service.job.JobPoller` 加载时会启动一个自动拉取任务的线程(从数据拉取任务放到执行器池中)

```java
// 线程池执行器(调度线程执行，BlockingQueue中必须存放线程对象)
private static final ThreadPoolExecutor executor = createThreadPoolExecutor();
private static final JobPoller instance = new JobPoller();

// ...

// 初始化线程池执行器
private static ThreadPoolExecutor createThreadPoolExecutor() {
    try {
        ThreadPool threadPool = ServiceConfigUtil.getServiceEngine(ServiceConfigUtil.engine).getThreadPool();

        return new ThreadPoolExecutor(
            threadPool.getMinThreads(), threadPool.getMaxThreads(), threadPool.getTtl(), TimeUnit.MILLISECONDS,
            // 将所有的Job(继承了Runnable)放到LinkedBlockingQueue中
            new LinkedBlockingQueue<Runnable>(threadPool.getJobs()),
            // 线程实例化工厂
            new JobInvokerThreadFactory(),
            new ThreadPoolExecutor.AbortPolicy());
    } catch (GenericConfigException e) {
       // ...
    }
}

private static class JobInvokerThreadFactory implements ThreadFactory {
    public Thread newThread(Runnable runnable) {
        return new Thread(runnable, "OFBiz-JobQueue-" + created.getAndIncrement());
    }
}

// 自动执行任务的线程
private final Thread jobManagerPollerThread;

private JobPoller() {
    if (pollEnabled()) {
        jobManagerPollerThread = new Thread(new JobManagerPoller(), "OFBiz-JobPoller");
        jobManagerPollerThread.setDaemon(false);
        jobManagerPollerThread.start();
    } else {
        jobManagerPollerThread = null;
    }
    ServiceConfigUtil.registerServiceConfigListener(this);
}
```

- `org.ofbiz.service.job.GenericServiceJob` 任务执行(线程调度器会进行调度)

```java
public void exec() throws InvalidJobException {
    if (currentState != State.QUEUED) {
        throw new InvalidJobException("Illegal state change");
    }
    currentState = State.RUNNING;
    // 持久化的任务(JobSandbox)通过此方法初始化(修改任务状态)
    init();
    Throwable thrown = null;
    Map<String, Object> result = null;
    try {
        LocalDispatcher dispatcher = dctx.getDispatcher();
        // 执行任务
        result = dispatcher.runSync(getServiceName(), getContext());

        // ...
    } catch (Throwable t) {
        // ...
    }
    if (thrown == null) {
        // 任务执行成功
        finish(result);
    } else {
        // 任务执行失败
        failed(thrown);
    }
}
```

### 服务并发

- 主要参数
  - `semaphore`: `none`(默认，并发调用服务)、`wait`(阻塞)、`fail`(报错)
  - `semaphore-sleep` 服务阻塞时间(默认 500 毫秒, semaphore="wait"时才有)
  - `semaphore-wait-seconds` 服务等待时间(默认 300 秒, semaphore="wait"时才有)
  - `wait`模式必须获取锁，该线程才可以运行此服务。有这么一种情况在进行 600 次(300s/500ms=600)获取锁的尝试中，正好都有锁；而在每次 500ms 睡眠中恰好被其他线程获得了该服务的锁，再次检查锁的时候，该服务可能正在运行。(这是一种极端情况)
- `semaphore="wait"` 阻塞模式，实现方式
  - 每次运行此类型服务时需要先获取**此服务**的锁
  - 获取锁的标志是可以往表`ServiceSemaphore`添加一条数据，源代码如下
    - `semaphore = delegator.makeValue("ServiceSemaphore", "serviceName", model.name, "lockedByInstanceId", JobManager.instanceId, "lockThread", threadName, "lockTime", lockTime);` (`org.ofbiz.service.semaphore.ServiceSemaphore`)
  - 每次获取锁前需要先判断`ServiceSemaphore`中是否已经有锁，如果有则阻塞
  - 阻塞时进行线程 sleep，然后循环判断获取锁
  - 每次项目重启会清除`ServiceSemaphore`中**此实例**的锁，源代码如下
    - `delegator.removeByAnd("ServiceSemaphore", "lockedByInstanceId", JobManager.instanceId);` (`org.ofbiz.service.ServiceDispatcher`)
- 详细流程参考 UML 图解

#### 线上故障分析

- 故障情景
  - 线上开启了两个实例`yard`和`yardcrossing`，它们处于同一个服务池 pool
  - 服务池 pool 中需要定时运行服务`messageTimer`(此服务 semaphore="wait")
  - 某天下午(大概 17:30 左右)因某些原因重启数据库，此时重启了`yard`，但是未重启`yardcrossing`
  - 此后上述服务一直运行失败，报错`Service [messageTimer] with wait semaphore exceeded wait timeout`
- 故障排查

  - 查看此段时间`messageTimer`运行的`JobSandbox`记录和 log 日志
  - 日志数据如下

  ```bash
  # log日志
  2018-04-12 17:33:51,038 |OFBiz-JobQueue-0     |ServiceDispatcher             |W| Exception thrown while unlocking semaphore:

  # 通过下列sql查询JobSandbox记录如下图(其中SERVICE_CRASHED可不用考虑，此状态在服务重启时才被置为损坏)
  select t.job_id, t.service_name, t.status_id, t.run_by_instance_id, t.start_date_time, t.finish_date_time, t.job_result
  from job_sandbox t
  where t.service_name = 'messageTimer'
  and t.start_date_time between '2018-04-12 17:20:00' and '2018-04-13 12:00:00'
  order by t.start_date_time
  ```

  ![ofbiz-180416](/data/images/java/ofbiz-180416.png)

  - 时间节点分析
    - `xx:xx:xx` jobId=2793652 的服务开始加锁
    - `17:33:41` (ofbiz1-yardcrossing:SERVICE_FINISHED start_date_time) jobId=2793652 的服务开始运行
    - `17:33:47` (ofbiz1-yardcrossing:SERVICE_FINISHED finish_date_time) jobId=2793652 的服务运行成功，状态修改完成
    - `17:33:51` (unlocking error) 解锁失败
    - `17:48:56` (ofbiz1:SERVICE_FAILED) 运行失败，报错`Service [messageTimer] with wait semaphore exceeded wait timeout`
    - `17:48:59` (ofbiz1-yardcrossing:SERVICE_FAILED) 运行失败，报错`Service [messageTimer] with wait semaphore exceeded wait timeout`
    - ... 一直报上述错误

- 故障分析：运行`jobId=2793652`时服务获取锁，并运行成功，服务状态修改成功，但是在解锁时敲好数据库重启导致解锁失败。而数据库中保存的正好是`ofbiz1-yardcrossing`实例的锁，且重启服务器后并没有重启`ofbiz1-yardcrossing`实例(重启了`yard`实例，因此只清除了`yard`相关的锁)。当实例重新获取数据库连接时，数据库中一直有一个`messageTimer`服务的锁，因此两个实例永远获取不到锁，最终超时运行失败。(获取锁时仅根据服务判断数据库中是否有此服务的锁，具体参考 UML 流程图)
- 经验教训：重启数据库后，虽然实例会自动重新获取数据库连接，但是此时就会出现问题，因此重启数据库后应该重启所有的实例

### 服务历史数据清理

- Job 积累太多，导致清理服务历史数据时，占用内存过大，最后 GC 太频繁，CPU 飙升，服务器宕机。具体参考[Java 应用 CPU 和内存异常分析.md#应用服务器故障](/_posts/devops/Java应用CPU和内存异常分析.md#应用服务器故障)

## 实战经验

### tomcat压缩大致jvm异常退出

- 具体参考[Java 应用 CPU 和内存异常分析.md#JVM 致命错误日志(hs_err_xxx-pid.log)](</_posts/java/Java应用CPU和内存异常分析.md#JVM致命错误日志(hs_err_xxx-pid.log)>)

