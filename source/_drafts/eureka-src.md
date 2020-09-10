---
layout: "post"
title: "Eureka源码解析"
date: "2020-08-21 14:58"
categories: src
tags: [springcloud, eureka]
---

## 简介

- 简单使用参考 [Eureka服务发现](/_posts/java/springcloud.md#Eureka服务发现)
- 参考：http://www.iocoder.cn/Eureka/

## 客户端初始化

- 客户端在引入pom依赖后，通过`@EnableDiscoveryClient`即可开启服务发现功能，因此以此注解为入口进行查看源码 [^1]
    - 此类属于`spring-cloud-commons-2.0.2.RELEASE.jar`包下，为 springcloud 对 netflix-eureka 的封装
- `@EnableDiscoveryClient` 注解是用来启用 `DiscoveryClient` 的实现，核心的实现为`EurekaDiscoveryClient`

    ```java
    public class EurekaDiscoveryClient implements DiscoveryClient {
        public static final String DESCRIPTION = "Spring Cloud Eureka Discovery Client";
        private final EurekaInstanceConfig config;
        // EurekaDiscoveryClient 只是关联了 com.netflix.discovery.EurekaClient，具体的服务发现还是由 EurekaClient 完成
        private final EurekaClient eurekaClient;

        public EurekaDiscoveryClient(EurekaInstanceConfig config, EurekaClient eurekaClient) {
            this.config = config;
            this.eurekaClient = eurekaClient;
        }
        // ...
    }
    ```
- EurekaClient 接口类图说明

    ![CloudEurekaClient](/data/images/java/eureka-1.png)
    - CloudEurekaClient 为 springcloud 对 DiscoveryClient 的继承，具体的逻辑还是由 DiscoveryClient 完成
- **`DiscoveryClient`** 类说明
    - register() 客户端注册
    - renew() 客户端续约
    - fetchRegistry() 获取注册的服务列表
    - shutdown() 客户端下线

```java
// AbstractDiscoveryClientOptionalArgs 自定义参数，可通过自定义Bean继承此类以到达定制化某些功能
@Inject
DiscoveryClient(ApplicationInfoManager applicationInfoManager, EurekaClientConfig config, AbstractDiscoveryClientOptionalArgs args, Provider<BackupRegistry> backupRegistryProvider) {
    // ...
    logger.info("Initializing Eureka in region {}", this.clientConfig.getRegion());
    // 获取配置 eureka.client.register-with-eureka=true(是否注册到eureka)、eureka.client.fetch-registry=true(是否拉取已注册的服务列表)
    if (!config.shouldRegisterWithEureka() && !config.shouldFetchRegistry()) {
        logger.info("Client configured to neither register nor query for data.");
        this.scheduler = null;
        this.heartbeatExecutor = null;
        this.cacheRefreshExecutor = null;
        this.eurekaTransport = null;
        this.instanceRegionChecker = new InstanceRegionChecker(new PropertyBasedAzToRegionMapper(config), this.clientConfig.getRegion());
        DiscoveryManager.getInstance().setDiscoveryClient(this);
        DiscoveryManager.getInstance().setEurekaClientConfig(config);
        this.initTimestampMs = System.currentTimeMillis();
        logger.info("Discovery Client initialized at timestamp {} with initial instances count: {}", this.initTimestampMs, this.getApplications().size());
    } else {
        try {
            // 创建scheduler定时任务的线程池
            this.scheduler = Executors.newScheduledThreadPool(2, (new ThreadFactoryBuilder()).setNameFormat("DiscoveryClient-%d").setDaemon(true).build());
            // 心跳检查线程池(服务续约)
            this.heartbeatExecutor = new ThreadPoolExecutor(1, this.clientConfig.getHeartbeatExecutorThreadPoolSize(), 0L, TimeUnit.SECONDS, new SynchronousQueue(), (new ThreadFactoryBuilder()).setNameFormat("DiscoveryClient-HeartbeatExecutor-%d").setDaemon(true).build());
            // 服务获取
            this.cacheRefreshExecutor = new ThreadPoolExecutor(1, this.clientConfig.getCacheRefreshExecutorThreadPoolSize(), 0L, TimeUnit.SECONDS, new SynchronousQueue(), (new ThreadFactoryBuilder()).setNameFormat("DiscoveryClient-CacheRefreshExecutor-%d").setDaemon(true).build());
            this.eurekaTransport = new DiscoveryClient.EurekaTransport();
            // 初始化 EurekaHttpClient：eurekaTransport.registrationClient 和 eurekaTransport.queryClient。基于 EurekaHttpClientFactory 初始化
            this.scheduleServerEndpointTask(this.eurekaTransport, args);
        }
        // ...

        // 开启上面三个线程池，往上面3个线程池分别添加相应任务
        // 然后创建了一个instanceInfoReplicator(Runnable任务)，然后调用InstanceInfoReplicator.start方法，把这个任务放进上面scheduler定时任务线程池(服务注册并更新)
        this.initScheduledTasks();

        // ...
    }
    // ...
}
```
- 流程图

    ![Eureka客户端原理](/data/images/java/Eureka客户端原理.jpg)





---

参考文章

[^1]: https://mp.weixin.qq.com/s/47TUd96NMz67_PCDyvyInQ

