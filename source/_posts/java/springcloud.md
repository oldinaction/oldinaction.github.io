---
layout: "post"
title: "SpringCloud"
date: "2017-08-05 19:36"
categories: [java]
tags: [SpringCloud, 微服务, Eureka, Ribbon, Feign, Hystrix, Zuul, Config, Bus]
---

## 介绍

- 架构演进
    - 单体架构：复杂度逐渐变高、部署速度慢、阻碍技术创新、无法按需伸缩
    - SOA [^1]
    - 微服务
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
- 本文相关软件：JDK: 1.8，SpringCloud: `Dalston.SR1`

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

        # 引入了spring-boot-starter-security则会默认开启认证
        security:
          basic:
            enabled: true #开启eureka后台登录认证
          # 不配置user，则默认的用户名为user，密码为自动生成(在控制台可查看)
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
    - 示例请看源码
        - 示例中使用H2数据库，IDEA连接方式：path:`mem:testdb`, user:`sa`, password:空, url:`jdbc:h2:mem:testdb`, 使用`Embedded`或`In-memory`方式连接

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

## Zuul (API GateWay：网关)

- 简介
- 基本使用
    - 引入依赖

        ```xml
        <!-- API网关。包含actuator、hystrix、ribbon -->
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-zuul</artifactId>
		</dependency>
        ```
    - 启动类声明`@EnableZuulProxy`
    - 基础配置application.yml

        ```yml
        zuul:
          # 忽略表达式。当遇到路径中有admin的不进行路由
          # ignored-patterns: /**/admin/**
          # 路由前缀
          # prefix: /api
          # zuul默认会过滤路由前缀(strip-prefix=true)，此处是关闭此过滤
          # strip-prefix: false
          routes:
            # 通配符(ant规范)：? 代表一个任意字符，* 代表多个任意字符，** 代表多个任意字符且支持多级目录
            # 此处路径在配置文件中越靠前的约优先（系统将所有路径放到LinkedHashMap中，当匹配到一个后就终止匹配）
            # 现在可以同时访问http://localhost:5555/consumer-movie-ribbon/movie/1?accessToken=smalle 和 http://localhost:5555/api-movie/movie/1?accessToken=smalle （有熔断保护，可能会超时，多刷新几遍）
            # api-movie为规则名, 可通过spring cloud config进行动态加载(覆盖)
            api-movie:
              path: /api-movie/**
              # 从eureka中获取此服务(spring.application.name)的地址(面向服务的路由)
              serviceId: consumer-movie-ribbon
            api-user:
              path: /api-user/**
              serviceId: provider-user
            # 本地跳转(当访问/api-local/**的时候，则会转到当前应用的/local/**的地址)
            # api-local:
            #   path: /api-local/**
            #   url: forward:/local
            # 禁用过滤器：zuul.<FilterClassName>.<filterType>.disable=true
            # AccessFilter:
            #   pre:
            #     disable: true
        ```
- 自定义路由规则

    ```java
    @Bean
    public PatternServiceRouteMapper serviceRouteMapper() {
        // 将serviceName-v1映射成/v1/serviceName. 未匹配到则按照原始的
        return new PatternServiceRouteMapper(
                "(?<name>^.+)-(?<version>v.+$)",
                "${version}/${name}");
    }
    ```
- 过滤器
    - Zuul过滤器核心处理器(`com.netflix.zuul.FilterProcessor`)
    - 核心过滤器处理(对应包`org.springframework.cloud.netflix.zuul.filters`)
    - 自定义过滤器

        ```java
        @Component
        public class AccessFilter extends ZuulFilter {
            private static Logger logger = LoggerFactory.getLogger(AccessFilter.class);

            // 过滤器类型，决定过滤器在请求的哪个生命周期中执行
            // pre：表示请求在路由之前执行
            // routing：在路由请求时被执行(调用真实服务应用时)
            // post：路由完成(服务调用完成)被执行
            // error：出错时执行
            @Override
            public String filterType() {
                return "pre";
            }

            // 多个过滤器时，控制过滤器的执行顺序（数值越小越优先）
            @Override
            public int filterOrder() {
                return 0;
            }

            // 判断该过滤器是否需要被执行(true需要执行)，可根据实际情况进行范围限定
            @Override
            public boolean shouldFilter() {
                return true;
            }

            // 过滤器的具体逻辑
            @Override
            public Object run() {
                RequestContext ctx = RequestContext.getCurrentContext();
                HttpServletRequest request = ctx.getRequest();

                logger.info("send {} request to {}", request.getMethod(), request.getRequestURL().toString()); // send GET request to http://localhost:5555/api-movie/movie/1

                Object accessToken = request.getParameter("accessToken");
                if(accessToken == null) {
                    logger.warn("access token is empty, add parameter like: accessToken=smalle");
                    ctx.setSendZuulResponse(false); // 令zuul过滤此请求，不进行路由
                    ctx.setResponseStatusCode(401);
                    ctx.setResponseBody("zuul filter");
                    return null;
                }

                logger.info("access token ok");

                // 测试异常过滤器（org.springframework.cloud.netflix.zuul.filters.post.SendErrorFilter）
                // doSomteing();

                return null;
            }

            private void doSomteing() {
                throw new RuntimeException("run error");
            }
        }
        ```
- 自定义异常信息：出现异常会forward到`/error`的端点，`/error`端点的实现来源于Spring Boot的`org.springframework.boot.autoconfigure.web.BasicErrorController`

    ```java
    // 最好使用postman等工具测试
    public class CustomErrorAttributes extends DefaultErrorAttributes {
        @Override
        public Map<String, Object> getErrorAttributes(RequestAttributes requestAttributes, boolean includeStackTrace) {
            Map<String, Object> map = super.getErrorAttributes(requestAttributes, includeStackTrace);
            map.remove("exception"); // 移除exception信息，客户端将看不到此信息
            map.put("myAttr", "hello");
            return map;
        }
    }
    ```
- 动态路由：请见分布式配置中心(Config)部分

## Config 分布式配置中心(Spring Cloud Config)

- 配置中心(Config服务器端)
    - 引入依赖

        ```xml
        <!-- 配置中心 -->
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-config-server</artifactId>
		</dependency>

        <!-- 用于配置中心访问账号认证 -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-security</artifactId>
		</dependency>

        <!--向eureka注册，服务化配置中心-->
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-eureka</artifactId>
		</dependency>
        ```
    - 启动类添加`@EnableConfigServer`，开启服务发现则还要加`@EnableDiscoveryClient`
    - 配置文件

        ```yml
        spring:
          cloud:
            config:
              server:
                git:
                  # 可以使用占位符{application}、{profile}、{label}
                  uri: https://git.oschina.net/smalle/spring-cloud-config-test.git
                  # 搜索此git仓库的配置文件目录
                  search-paths: config-repo
                  username: smalle
                  password: aezocn

          server:
            port: 7000

          security:
            basic:
              enabled: true # 开启权限验证(默认是false)
            user:
              name: smalle
              password: smalle

          # eureka客户端配置
          eureka:
            client:
              serviceUrl:
                defaultZone: http://smalle:smalle@localhost:8761/eureka/
            instance:
              # 启用ip访问
              prefer-ip-address: true
              instanceId: ${spring.application.name}:${spring.application.instance_id:${server.port}}
        ```
    - 在git仓库的config-repo目录下添加配置文件: `consumer-movie-ribbon.yml`(写如配置如：from: git-default-1.0. 下同)、`consumer-movie-ribbon-dev.yml`、`consumer-movie-ribbon-test.yml`、`consumer-movie-ribbon-prod.yml`，并写入参数
    - 访问：`http://localhost:7000/consumer-movie-ribbon/prod/master`即可获取应用为`consumer-movie-ribbon`，profile为`prod`，git分支为`master`的配置数据(`/{application}/{profile}/{label}`)
        - 某application对应的配置命名必须为`{application}-{profile}.yml`，其中`{profile}`和`{label}`可在对应的application的`bootstrap.yml`中指定
        - 访问配置路径后，程序默认会将配置数据下载到本地，当git仓库不可用时则获取本地的缓存数据
        - 支持git/svn/本地文件等
- 客户端配置映射
    - 引入依赖

        ```xml
        <!-- 配置中心客户端 -->
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-config</artifactId>
		</dependency>
        ```
    - 添加`bootstrap.yml`配置文件(不能放在application.yml中)

        ```yml
        # bootstrap.yml其优先级高于application.yml
        spring:
          # application:
          #  name: consumer-movie-ribbon
          cloud:
            config:
              # (1) config server地址
              # uri: http://localhost:7000/
              # (2) 配置中心实行服务化(向eureka注册了自己)，此处要开启服务发现，并指明配置中心服务id
              discovery:
                enabled: true
                service-id: config-server
              profile: prod
              label: master
              # 如果配置中心开启了权限验证，此处填写相应的用户名和密码
              username: smalle
              password: smalle

        # eureka客户端配置(使用了spring cloud config, 则eureka的配置必须写在bootstrap.yml中，否则报找不到config server )
        eureka:
          client:
            serviceUrl:
              defaultZone: http://smalle:smalle@localhost:8761/eureka/
          instance:
            # 启用ip访问
            prefer-ip-address: true
            instanceId: ${spring.application.name}:${spring.application.instance_id:${server.port}}
        ```
    - 测试程序

        ```java
        // @RefreshScope // 之后刷新config后可重新注入值
        @RestController
        public class ConfigController {
            @Value("${from:none}")
            private String from;

            // 测试从配置中心获取配置数据，访问http://localhost:9000/from
            @RequestMapping("/from")
            public String from() {
                return this.from; // 会从git仓库中读取配置数据
            }
        }
        ```
- 动态刷新配置(可获取最新配置信息的git提交)
    - config客户端重启会刷新配置(重新注入配置信息)
    - 动态刷新
        - 在需要动态加载配置的Bean上加注解`@RefreshScope`
        - 给 **config client** 加入权限验证依赖(`org.springframework.boot/spring-boot-starter-security`)，并在对应的application.yml中开启验证
            - 否则访问`/refresh`端点会失败，报错：`Consider adding Spring Security or set 'management.security.enabled' to false.`(需要加入Spring Security或者关闭端点验证)
        - 对应的需要注入配置的类加`@RefreshScope`
        - `POST`请求`http://localhost:9000/refresh`(将Postman的Authorization选择Basic Auth和输入用户名/密码)
        - 再次访问config client的 http://localhost:9000/from 即可获取最新git提交的数据(由于开启了验证，所有端点都需要输入用户名密码)
            - 得到如`["from"]`的结果(from配置文件中改变的key)
- 动态加载网关配置
    - 在`api-gateway-zuul`服务中同上述一样加`bootstrap.yml`，并对eureka和config server进行配置
    - 在`application.yml`对

        ```yml
        zuul:
          routes:
            api-movie:
              path: /api-movie/**
              serviceId: consumer-movie-ribbon
              # 如果consumer-movie-ribbon服务开启了权限验证，则需要防止zuul将头信息(Cookie/Set-Cookie/Authorization)过滤掉了.(多用于API网关下的权限验证等服务)
              # 此方法是对指定规则开启自定义敏感头. 还有一中解决方法是设置路由敏感头为空(则不会过滤任何头信息)：zuul.routes.<route>.sensitiveHeaders=
              customSensitiveHeaders: true

        # 为了动态刷新配置(spring cloud config)，执行/refresh端点(此端点需要加入Spring Security或者关闭端点验证)
        security:
          basic:
            enabled: true
          user:
            name: smalle
            password: smalle
        ```
    - 在git仓库中加入`api-gateway-zuul-prod.yml`等配置文件，并加入配置

        ```yml
        zuul:
          routes:
            api-movie:
              path: /api-movie-config/**
              serviceId: consumer-movie-ribbon
        ```
    - `POST`请求`http://localhost:5555/refresh`即可刷新`api-gateway-zuul`的配置，因此动态加载了路由规则zuul.routes.api-movie

## Bus 消息总线(Spring Cloud Bus)

- 简介：使用轻量级的消息代理来构建一个公用的消息主题让系统中所有微服务都连接上来，由于该主题会被所有实例监听和消费所以称消息总线。各个实例都可以广播消息让其他实例消费。
- 是基于消息队列(如：ActiveMQ/Kafka/RabbitMQ/RocketMQ), Spring Cloud Bus暂时支持RabbitMQ和Kafka

### 以RabbitMQ为例

> RabbitMQ是实现了高级消息队列协议(AMQP)的开源消息代理软件，也称为面向消息的中间件。后续操作需要先安装RabbitMQ服务。关于RabbitMQ在SpringBoot中的使用参考SpringBoot章节

- 在`config-server`和`consumer-movie-ribbon`两个服务中加入bus依赖

    ```xml
    <!-- 消息总线 -->
	<dependency>
		<groupId>org.springframework.cloud</groupId>
		<artifactId>spring-cloud-starter-bus-amqp</artifactId>
	</dependency>
    ```
- 启动RabbitMQ服务(如果未修改默认配置，则SpringBoot会自动连接。自定义配置如下)

    ```yml
    # 这是springboot的默认配置，可根据实际情况修改
    spring:
      rabbitmq:
        host: localhost
        port: 5672
        username: guest
        password: guest
    ```
- 启动一个`config-server`和两个`consumer-movie-ribbon`(9000、9002)
- 修改上述【分布式配置中心】的git管理的配置字段`from`
- 刷新`config-server`：`POST`访问http://localhost:7000/bus/refresh
    - `POST`访问http://localhost:7000/refresh 只能刷新`config-server`本身
    - `POST`访问http://localhost:7000/bus/refresh 可以刷新消息总线上所有的服务
    - `POST`访问http://localhost:7000/bus/refresh?destination=consumer-movie-ribbon:9000 可以刷新的指定服务实例
    - `POST`访问http://localhost:7000/bus/refresh?destination=consumer-movie-ribbon:** 可以刷新服务consumer-movie-ribbon下的所有实例
    - 刷新消息总线上的任何一个服务都可以到达此效果(消息总线上的其他服务会收到触发刷新服务的消息，进行同步刷新)
- 原理如下 [^3]

    ![spring-cloud-bus](/data/images/2017/07/spring-cloud-bus.png)

### 以Kafka为例

> Kafka是有LinkedIn开发的分布式消息系统，现由Apache维护，使用Scala实现。

- 更换依赖

    ```xml
    <dependency>
		<groupId>org.springframework.cloud</groupId>
		<artifactId>spring-cloud-starter-bus-kafka</artifactId>
	</dependency>
    ```
- 只需更换依赖，其他地方同rabbitmq即可(使用kafka默认配置时会产生一个Topic为)
- 启动kafka(包括zookeeper). 关于`Kafka`使用可查看文章【Kafka】
- 启动应用后会产生一个名为springCloudBus的Topic

## Stream 消息驱动(Spring Cloud Stream)

- 简介
    - Spring Cloud Stream本质上是整合了Spring Boot和Spring integration，主要包含发布-订阅、消息组、分区三个概念
    - 其功能是为应用程序(Spring Boot)和消息中间件之间添加一个绑定器(Binder)，只对应用程序提供统一的Channel通道，从而应用程序不需要考虑不同消息中间件的实现(调用规则)
    - 暂时只支持RabbitMQ和Kafka的自动化配置
- 入门案例
    - 引入依赖(以服务`consumer-movie-ribbon`为例)

        ```xml
        <!-- 消息驱动 -->
		<!-- 基于rabbitmq(也可以引入spring-cloud-stream-binder-rabbit/kafka/redis) -->
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-stream-rabbit</artifactId>
		</dependency>
        ```
    - application.yml 部分配置(consumer-movie-ribbon)

        ```yml
        spring:
          application:
            name: consumer-movie-ribbon
          cloud:
            # Spring Cloud Stream配置
            stream:
              bindings:
                # input为定义的通道名称
                input:
                  # 通道数据传输类型
                  # content-type: text/plain # application/json
                  # 将此实例的某个Stream(input)定义为某个消费组(同一个消费组里面的实例只有其中一个对消息进行消费, 否则所有的实例都会消费, 建议定义)
                  group: group-movie
                  # 应用中的监听的input通道对应中间件的主题(rabbitmq的Exchange, kafka的Topic)为xxx(默认是通道名称, 此时即input)
                  # destination: xxx
                # ...此处省略其他通道配置...
        ```
    - 消息接受者(consumer-movie-ribbon)

        ```java
        // 开启绑定，启动消息驱动。
        // @EnableBinding属性value可指定多个关于消息通道的配置(类)，表示需要加载的类，即根据这些类中的注解(@Input、@Output生成bean)
        @EnableBinding(value = {Processor.class, MyChannel.class})
        public class SinkReceiver {

            // 消息消费者监听的通道名称.
            @StreamListener(Processor.INPUT)
            public void receive(Object msg) {
                System.out.println("msg = " + msg);
            }

            // @StreamListener可将收到的消息(json/xml数据格式)转换成具体的对象
            @StreamListener(MyChannel.CHANNEL2_INPUT) // 接受rabbitmq的channel1_output
            @SendTo(MyChannel.CHANNEL2_OUTPUT) // 收到消息后进行反馈(给rabbitmq的channel1_input发送)
            public Object receive2(User user) {
                System.out.println("user.getUsername() ==> " + user.getUsername());
                return "SinkReceiver.receive2 = " + user; // 将此数据返回给消息发送这或者其他服务
            }
        }

        // 定义通道
        public interface MyChannel {
            // 输入输出通道名称最好不要相同
            String CHANNEL2_INPUT = "channel2_input";
            String CHANNEL2_OUTPUT = "channel2_output";

            @Input(MyChannel.CHANNEL2_INPUT)
            SubscribableChannel channel2_input(); // 设置消息通道名称(默认使用方法名作为消息通道名)，表示从该通道发送数据

            @Output(MyChannel.CHANNEL2_OUTPUT)
            MessageChannel channel2_output();
        }
        ```
        - 易错点：
            - 在两个类中分别@EnableBinding绑定Processor，并同时监听@Input则报错 unknown.channel.name.(一个应用中不能绑定多个相同名称的@Input、@Output; 同理, Processor只能被一个类@EnableBinding绑定或者被两个类分别绑定@Input、@Output)
            - 如果一个应用需要监听相同的主题(如：input)，可以重新命名一个@Input("xxx"), 然后通过spring.cloud.stream.bindings.xxx.destination=input来监听input主题。或者将监听程序写在一个类中

    - 消息发送者(provider-user)

        ```java
        @EnableBinding(MyChannel.class)
        public class SinkSender {
            // 法一：注入绑定接口
            @Autowired
            private MyChannel myChannel;

            // 法二：注入消息通道
            @Autowired @Qualifier("input") // 此时有多个MessageChannel(根据SinkSender中@Output注入的), 需要指明
            private MessageChannel channel;

            private MessageChannel channel1_output;

            // 也可以这样注入
            @Autowired
            public SinkSender(@Qualifier("channel1_output") MessageChannel channel) {
                this.channel1_output = channel;
            }

            // 测试基本的消息发送和接受
            public void sendMessage() {
                // 此条消息会在测试程序中打印
                myChannel.channel().send(MessageBuilder.withPayload("hello stream [from provider-user]").build());

                // 此条消息会在消息消费者中显示
                channel.send(MessageBuilder.withPayload("hello channel [from provider-user]").build());
            }

            // 测试@StreamListener对消息自动转换和消息反馈
            public void msgTransform() {
                channel1_output.send(MessageBuilder.withPayload("{\"id\": 1, \"username\": \"smalle\"}").build());
            }
        }

        // 用于接受反馈消息
        @EnableBinding(value = {MyChannel.class})
        public class ChannelReceiver {
            // 接受反馈的消息
            @StreamListener(MyChannel.CHANNEL1_INPUT)
            public void receiveSendTo(Object msg) {
                System.out.println("ChannelReceiver.receiveSendTo ==> " + msg);
            }
        }

        // 定义通道
        public interface MyChannel {
            String CHANNEL = "input";
            String CHANNEL1_INPUT = "channel1_input";
            String CHANNEL1_OUTPUT = "channel1_output";

            @Input(MyChannel.CHANNEL1_INPUT)
            SubscribableChannel channel1_input();

            @Output(MyChannel.CHANNEL)
            MessageChannel channel();

            @Output(MyChannel.CHANNEL1_OUTPUT)
            MessageChannel channel1_output();
        }
        ```
- Spring integration原生支持(了解，Spring Cloud Stream是基于它实现的)
    - 消息消费者(consumer-movie-ribbon)

        ```java
        @EnableBinding(value = {MyChannel.class}) // 收发消息的通道不能使用同一个MessageChannel
        public class MyReceiver {
            @ServiceActivator(inputChannel = MyChannel.POLLER_INPUT) // 收发消息的通道不能使用同一个MessageChannel
            public void receive(Object msg) {
                System.out.println("MyReceiver: msg = " + msg);
            }

            // 消息转换(也可放在MySender中)，@ServiceActivator本身不具备消息转换功能(如：json/xml转成具体的对象)
            @Transformer(inputChannel = MyChannel.POLLER_INPUT, outputChannel = MyChannel.POLLER_OUTPUT)
            public Object transform(Date msg) {
                return new SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(msg);
            }
        }
        ```
    - 消息生产者(provider-user)

        ```java
        @EnableBinding(value = {MyChannel.class})
        public class MySender {

            @Bean // 项目启动后便会执行
            @InboundChannelAdapter(value = MyChannel.POLLER_OUTPUT, poller = @Poller(fixedDelay = "5000")) // 对MyChannel.POLLER_OUTPUT通道进行输出. poller表示轮询，此时为每5秒执行一次方法
            public MessageSource<Date> timeMsgSource() {
                return () -> new GenericMessage<>(new Date());
            }
        }
        ```
- 消息分区(未测试)

    ```java
    # 消费者配置
    # 当前消费者的总实例数量(消息分区需要设置)
    spring.cloud.stream.instanceCount=2
    # 当前实例的索引号(消息分区需要设置，最大为instance-count - 1)
    spring.cloud.stream.instanceIndex=0
    # 开启消费者分区功能
    spring.cloud.stream.bindings.input.consumer.partitioned=true

    # 生成者配置
    spring.cloud.stream.bindings.output.destination=input
    # 可根据实际消息规则配置SpEL表达式生成分区键用于分配出站数据, 用于消息分区
    spring.cloud.stream.bindings.output.producer.partitionKeyExpression=payload
    # 分区数量
    spring.cloud.stream.bindings.output.producer.partitionCount=2
    ```
- 绑定器SPI
    - 绑定器是将程序(SpringBoot)中的输入/输出通道和消息中间件的输入输出做绑定
    - Spring Cloud Stream暂时只实现了RabbitMQ和Kafka的绑定其，因此只支持此二者的自动化配置
    - 可自己实现其他消息中间件的绑定器
        - 一个实现Binder接口的类
        - 一个Spring配置加载类，用来连接中间件
        - 一个或多个能够在classpath下找到META-INF/spring.binders定义绑定器定的文件。如：

            ```java
            rabbit:\
            org.springframework.cloud.stream.binder.rabbit.config.RabbitServiceAutoConfiguration
            ```
    - 绑定器配置

        ```java
        # 默认的绑定器为rabbit(名字是META-INF/spring.binders中定义的)
        spring.cloud.stream.defaultBinder=rabbit
        # 定义某个通道(input)的绑定器
        spring.cloud.stream.bindings.input.binder=kafka

        # 为不同通道定义同一类型不同环境的绑定器
        spring.cloud.stream.bindings.input.binder=rabbit1
        spring.cloud.stream.bindings.output.binder=rabbit2
        # 定义rabbit1的类型和环境(此处省略rabbit2的配置)
        spring.cloud.stream.binders.rabbit1.type=rabbit1
        spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.host=127.0.0.1
        spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.port=5672
        spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.username=guest
        spring.cloud.stream.binders.rabbit1.environment.spring.rabbitmq.password=guest
        ```

## Sleuth 分布式服务跟踪(Spring Cloud Sleuth)

- 简介
    - 用来跟踪每个请求在全链路调用的过程，可快速发现每条链路上的性能瓶颈
    - 构建后会自动监控RabbitMQ/Kafka传递的请求、Zuul代理传递的请求、RestTemplate发起的请求
- 入门案例
    - 引入依赖(在生产者和消费者中都引入)

        ```xml
        <!-- 服务跟踪 -->
    	<dependency>
    		<groupId>org.springframework.cloud</groupId>
    		<artifactId>spring-cloud-starter-sleuth</artifactId>
    	</dependency>
        ```
    - 访问生产者`http://localhost:8000/simple/1`，控制台输出类似`TRACE [provider-user,0ec3c3b4ee83efd5,0ec3c3b4ee83efd5,false]`的信息，信息中括号的值分别代表：应用名称、Trace ID(一个请求链路的唯一标识)、Span ID(一个基本工作单元，如一个Http请求)、是否将信息收集到Zipkin等服务中来收集和展示
    - 添加配置`logging.level.org.springframework.web.servlet.DispatcherServlet=DEBUG`可打印更多信息
- 请求头信息：`org.springframework.cloud.sleuth.Span`
- 抽样收集
    - Spring Cloud Sleuth收集策略通过Sampler接口实现(通过isSampled返回boolean判断是否收集)，默认会使用PercentageBasedSampler实现的抽样策略
    - `spring.sleuth.sampler.percentage=0.1` 代表收集10%的请求跟踪信息
    - 可收集请求头信息中包含某个tag的样品

        ```java
        public class TagSampler implements Sampler {
            private String tag;

            public TagSampler(String tag) {
                this.tag = tag;
            }

            @Override
            public boolean isSampled(Span span) {
                return span.tags().get(tag) != null;
            }
        }
        ```
- 与Zipkin整合(推荐)
    - 建立zipkin server
        - 新建服务`zipkin-server`
        - 引入依赖

            ```xml
            <!-- eureka客户端 -->
    		<dependency>
    			<groupId>org.springframework.cloud</groupId>
    			<artifactId>spring-cloud-starter-eureka</artifactId>
    		</dependency>

    		<!-- Zipkin创建sleuth主题的stream -->
    		<dependency>
    			<groupId>org.springframework.cloud</groupId>
    			<artifactId>spring-cloud-starter-stream-rabbit</artifactId>
    		</dependency>

    		<!--包含Zipkin服务的核心依赖(zipkin-server)、消息中间件的核心依赖、扩展数据存依赖等. 不包含Zipkin前端界面依赖-->
    		<dependency>
    			<groupId>org.springframework.cloud</groupId>
    			<artifactId>spring-cloud-sleuth-zipkin-stream</artifactId>
    		</dependency>
    		<!-- Zipkin前端界面依赖 -->
    		<dependency>
    			<groupId>io.zipkin.java</groupId>
    			<artifactId>zipkin-autoconfigure-ui</artifactId>
    			<scope>runtime</scope>
    		</dependency>

    		<!-- 存储Zipkin跟踪信息到mysql(可选. 使用mysql后, Zipkin前端界面显示的数据是通过Restful API从数据库中获取的. 不使用数据存储在Zipkin内部) -->
    		<dependency>
    			<groupId>org.springframework.boot</groupId>
    			<artifactId>spring-boot-starter-data-jpa</artifactId>
    		</dependency>
    		<dependency>
    			<groupId>mysql</groupId>
    			<artifactId>mysql-connector-java</artifactId>
    		</dependency>
            ```
        - 启动类加注解`@EnableEurekaClient`、`@EnableZipkinStreamServer`(用stream方式启动，包含常规启动@EnableZipkinServer和创建sleuth的stream主题)
        - application.yml配置

            ```yml
            server:
              port: 9411

            spring:
              application:
                name: zipkin-server
              datasource:
                # 建表语句, 用来新建zipkin跟踪信息相关表(zipkin_spans、zipkin_annotations、zipkin_dependencies), 文件在Maven:io.zipkin.java:zipkin.storage.mysql目录下
                schema: classpath:/mysql.sql
                url: jdbc:mysql://localhost:3306/test
                username: root
                password: root
                initialize: true
                continue-on-error: true
              # 不对此服务开启跟踪
              sleuth:
                enabled: false

            # 改变zipkin日志跟踪信息存储方式为mysql(测试也可不使用mysql存储)
            zipkin:
              storage:
                type: mysql
            ```
    - 被跟踪的应用(在生产者和消费者中都引入)
        - 引入依赖

            ```xml
            <!--服务跟踪与Zipkin整合(可选)-->
    		<dependency>
    			<groupId>org.springframework.cloud</groupId>
    			<artifactId>spring-cloud-starter-zipkin</artifactId>
    		</dependency>
            ```
        - 如果zipkin没有使用eureka， 则需要在application.yml中添加`spring.zipkin.base-url: http://localhost:9411/` (zipkin server地址)
    - 进入到zipkin server后台界面查看跟踪信息：http://localhost:9411/ (跟踪信息可能会有延迟)
- 整合ELK日志分析系统(Logstash)
    - ELK平台包含：ElasticSerch(分布式搜索引擎)、Logstash(日志收集-过滤-存储)、Kibana(界面展现)三个开源工具。(与Zipkin类似，二者不建议同时使用)
    - 引入依赖

        ```xml
        <!--服务跟踪与ELK日志分析平台整合(可选，此包用于Logstash收集日志)-->
		<dependency>
			<groupId>net.logstash.logback</groupId>
			<artifactId>logstash-logback-encoder</artifactId>
			<version>4.6</version>
		</dependency>
        ```
    - 将spring.application.name配置到bootstrap.yml中
    - 在resources目录加logback-spring.xml文件(请看源码)




---

参考文章

[^1]: [SOA和微服务架构的区别](https://www.zhihu.com/question/37808426)
[^2]: [服务发现的可行方案以及实践案例](http://blog.daocloud.io/microservices-4/)
[^3]: [Spring-Cloud-Bus原理](http://blog.csdn.net/sosfnima/article/details/53178326)
