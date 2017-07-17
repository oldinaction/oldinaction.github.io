---
layout: "post"
title: "SpringCloud"
date: "2017-07-01 13:11"
categories: [java]
tags: [SpringCloud, 微服务]
---

* 目录
{:toc}

## 介绍

- 架构演进
    1. 单体架构：复杂度逐渐变高、部署速度慢、阻碍技术创新、无法按需伸缩
    2. SOA [^1]
    3. 微服务
- 微服务特点
    - 微服务可独立运行在自己的进程里
    - 一系列独立运行的微服务构成整个系统
    - 每个服务独立开发维护
    - 微服务之间通过REST API或RPC等方式通信
    - 优点：易于开发和维护，启动快，技术栈不受限制，按需伸缩，DevOps
    - 挑战：运维要求较高，分布式的复杂性，接口调整成本高
- 微服务设计原则：单一职责原则、服务自治原则、轻量级通信原则、接口明确原则
- 微服务开发框架：`Spring Cloud`、`Dubbo`、`Dropwizard`、`Consul`等
- Spring Cloud是基于Spring Boot的用于快速构建分布式系统工具集
- Spring Cloud特点：约定优于配置、开箱即用，快速启动、轻量级组件、组件丰富、选型中立
- 本文相关软件：JDK: 1.8，SpringCloud: Dalston.SR1

## 微服务构建

- 服务提供者、服务消费者
- 服务消费者中通过restTemp调用服务提供者提供的服务
    - 如：`User user = this.restTemplate.getForObject("http://localhost:7900/simple/" + id, User.class);`

## Eureka服务发现

- 服务注册与发现

    ![服务注册与发现](/data/images/2017/07/服务注册与发现.png)

    - 服务发现方式 [^2]
        - 客户端发现：Eureka、Zk
        - 服务端发现：Consul + nginx
    - 服务注册表是一个记录当前可用服务实例的网络信息的数据库，是服务发现机制的核心。服务注册表提供查询API和管理API，使用查询API获得可用的服务实例，使用管理API实现注册和注销

- 简介：Eureka是`Netflix`开发的服务发现框架，本身是一个基于REST的服务，主要用于定位运行在AWS域中的中间层服务，以达到负载均衡和中间层服务故障转移的目的。Spring Cloud将它集成在其子项目`spring-cloud-netflix`中，以实现Spring Cloud的服务发现功能
- 架构图

    ![eureka](/data/images/2017/07/eureka.png)

    - AWS概念：us-east-1c、us-east-1d等是zone，它们都属于us-east-1这个region
    - 在应用启动后，将会向Eureka Server发送心跳（默认周期为30秒）。如果Eureka Server在多个心跳周期内没有接收到某个节点的心跳，Eureka Server将会从服务注册表中把这个服务节点移除（默认90秒）
    - Eureka还提供了客户端缓存的机制，即使所有的Eureka Server都挂掉，客户端依然可以利用缓存中的信息消费其他服务的API
- eureka server
    - 引入依赖

        ```xml
        <dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-eureka-server</artifactId>
		</dependency>

        <!-- 用于注册中心访问账号认证，非必须 -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-security</artifactId>
		</dependency>
        ```
    - 在Application.java中加注解`@EnableEurekaServer`
    - application.yml配置

        ```yml
        server:
          port: 8761

        security:
          basic:
            enabled: true #开启eureka后台登录认证
          user:
            name: smalle
            password: smalle

        eureka:
          instance:
            hostname: localhost
          client:
            # eureka server默认也是一个eureka client.以下两行仅将此App当成eureka server，不当成eureka client(由于是单点测试)
            register-with-eureka: false
            fetch-registry: false
            # 将eureka注册到哪个url
            serviceUrl:
              defaultZone: http://user:password@${eureka.instance.hostname}:${server.port}/eureka/
        ```
    - 后台地址：`http://localhost:8761`
- eureka client
    - 引入依赖

        ```xml
        <dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-eureka</artifactId>
		</dependency>
        ```
    - 在Application.java中加注解`@EnableEurekaClient`
    - application.yml配置

        ```yml
        # eureka客户端配置
        eureka:
          client:
            serviceUrl:
              defaultZone: http://smalle:smalle@localhost:8761/eureka/
          instance:
            # 启用ip访问eureka server(默认是使用主机名进行访问)
            prefer-ip-address: true
            # 实例id
            instanceId: ${spring.application.name}:${spring.application.instance_id:${server.port}}
        ```
## Ribbon负载均衡

- 简介
    - Ribbon是Netflix发布的云中间层服务开源项目，其主要功能是提供客户端侧负载均衡算法。Ribbon客户端组件提供一系列完善的配置项如连接超时，重试等。简单的说，Ribbon是一个客户端负载均衡器，我们可以在配置文件中列出Load Balancer后面所有的机器，Ribbon会自动基于某种规则（如简单轮询，随机连接等）去连接这些机器，我们也很容易使用Ribbon实现自定义的负载均衡算法。
    - Eureka与Ribbon连用

        ![eureka-ribbon](/data/images/2017/07/eureka-ribbon.png)

        - Ribbon工作时分为两步：第一步先选择 Eureka Server, 它优先选择在同一个Zone且负载较少的Server；第二步再根据用户指定的策略，在从Server取到的服务注册列表中选择一个地址。其中Ribbon提供了多种策略，例如轮询round robin、随机Random、根据响应时间加权等
- 基本使用
    - 引入依赖：group：`org.springframework.cloud`，artifact id：`spring-cloud-starter-ribbon`
        - 如果引入了`spring-cloud-starter-eureka`中默认引入了，此时可无需再引入
    - 在restTemplate对应的Bean上注解`@LoadBalanced`

        ```java
    	@Bean
    	@LoadBalanced // 使用ribbon实现客户端负载均衡
    	public RestTemplate restTemplate() {
    		return new RestTemplate();
    	}
        ```
    - 备注：此时需要启动多个服务提供者进行测试，IDEA中：
        - 可以先启动一个后再将端口改掉再启动另外一个
        - (推荐) `Eidt Configurations`再配置一个Spring boot的启动项，配置时将`Spring Boot Settings` - `Override parameters`添加一个参数`server.port=8080`
- 自定义负载均衡策略

    ```yml
    # robbin负载均衡策略优先级：配置文件策略 > 代码级别策略 > ribbon默认策略(com.netflix.loadbalancer.ZoneAvoidanceRule)
    provider-user:
      ribbon:
          # 当访问服务provider-user时采用随机策略RandomRule，此时访问其他服务时仍然为默认策略ZoneAvoidanceRule；WeightedResponseTimeRule响应时间加权策略
          NFLoadBalancerRuleClassName: com.netflix.loadbalancer.RandomRule
    ```
- 脱离Eureka的配置，此时仍然可以运行Eureka，但是不从eureka中获取服务地址，而是从配置文件中读取

    ```yml
    stores:
      ribbon:
        listOfServers: example.com,aezo.cn
    ```

## Feign声明式服务调用

- 简介
- 基本使用(服务消费者)
    - 引入依赖

        ```xml
        <!--Feign声明式服务调用-->
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-feign</artifactId>
		</dependency>
        ```
    - 启动类加注解`@EnableFeignClients`
    - 定义FeignClient接口Bean

        ```java
        // 此服务消费者需要调用的服务声明
        @FeignClient("provider-user")
        public interface UserFeignClient {
            // Feign不支持@GetMapping, @PathVariable必须指明参数值
            @RequestMapping(method = RequestMethod.GET, value = "/simple/{id}")
            User findById(@PathVariable("id") Long id);

            @RequestMapping(method = RequestMethod.POST, value = "/feign-post")
            User postFeignUser(@RequestBody User user);
        }
        ```
    - 在controller中直接调用接口中方法(此时不直接调用restTemplate)

## Hystrix服务容错保护(断路器)

- 简介
- 基本使用(服务消费者)
    - 引入依赖

        ```xml
        <!--服务容错保护(断路器) Hystrix-->
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-hystrix</artifactId>
		</dependency>
        ```
    - 启动类加注解`@EnableCircuitBreaker`
    - 声明断路后回调函数

        ```java
        @HystrixCommand(fallbackMethod = "findByIdFallBack")
        public User findById(Long id) {
            // virtual ip: 服务的spring.application.name
            return this.restTemplate.getForObject("http://provider-user/simple/" + id, User.class);
        }

        // 当服务调用失败或者超时则回调此函数. 此函数参数和返回值必须和调用函数一致
        public User findByIdFallBack(Long id) {
            System.out.println(id + ", error[hystrix]");
            return null;
        }
        ```





































---
[^1]: [SOA和微服务架构的区别](https://www.zhihu.com/question/37808426)
[^2]: [服务发现的可行方案以及实践案例](http://blog.daocloud.io/microservices-4/)
