---
layout: "post"
title: "spring"
date: "2017-07-01 18:47"
categories: [java]
tags: [spring, spring-mvc]
---

## 介绍

1. spring项目官网：[https://spring.io/projects](https://spring.io/projects) ，其中的`spring-framework`即是spring框架内容
2. 历史：(1) spring 1.x，xml配置时代 (2) spring 2.x，注解时代 (3) **spring 3.x，java配置**
3. spring模块(每个模块有个jar包)：
    - 核心容器：`spring-core`, `spring-beans`, `spring-context`(运行时spring容器), `spring-context-support`(spring对第三方包的集成支持), `spring-expression`(使用表达式语言在运行时查询和操作对象)
    - AOP：spring-aop, spring-aspects
    - 消息：spring-messaging
    - 数据访问：`spring-jdbc`, `spring-tx`(提供编程式和声明明式事物支持), `spring-orm`, `spring-oxm`(提供对对象/xml映射技术支持), `spring-jms`(提供jms支持)
    - Web： `spring-web`(在web项目中提供spring容器), `spring-webmvc`(基于Servlet的SpringMVC), `spring-websocket`, `spring-webmvc-portlet`
4. spring生态：`Spring Boot`(使用默认开发配置来快速开发)、`Spring Cloud`(为分布式系统开发提供工具集)等
5. 本文档基于spring4.3.8

## Hello World

- maven依赖

    ```xml
        <dependency>
            <groupId>org.springframework</groupId>
            <!--包含spring-core、spring-beans、spring-aop、spring-expression、spring-instrument-->
            <artifactId>spring-context</artifactId>
            <version>4.3.8.RELEASE</version>
        </dependency>
    ```
- 依赖注入
    - 声明Bean的注解(下面几个注解效果一样)：
        - `@Component` 没有明确的角色
        - `@Service` 在业务逻辑层(cn.aezo.spring.aop_spel.service)使用
        - `@Repository` 在数据访问层(cn.aezo.spring.aop_spel.dao)使用
        - `@Controller` 在展现层使用
    - 注入Bean的注解(效果一样)
        - `@Autowired` Spring提供(默认按类型by type(根据类); 如果想用by name，则使用`@Qualifier("my-bean-name")`)
        - `@Resource` JSR-250提供(常用)
        - `@Inject` JSR-330提供
- java配置
    - `@Configuration` 注解类表示此类是一个配置类，里面有0个或者多个`@Bean`
        - `@ComponetScan("cn.aezo")` 定义需要扫描的包名，并将里面的`@Component`、`@Service`、`@Repository`、`@Controller`注解的类注册为Bean
    - `@Bean` 注解方法，表示当前方法的返回值是一个Bean，Bean的名称是方法名
    - 一般公共类使用java配置进行Bean声明，业务相关类使用注解进行Bean声明
- 调用

    ```java
       // ApplicationContext context = new ClassPathXmlApplicationContext("beans.xml");
       ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class); // AppConfig为定义的java配置类

       Hello hello = context.getBean("hello", Hello.class);
       hello.hello();
    ```

## 知识点

### AOP

- 相关注解
    - `@Aspect` 声明一个切面
    - `@Before`、`@After`、`@Around` 定义建言(advice)
- maven依赖

    ```xml
    <dependency>
        <groupId>org.aspectj</groupId>
        <artifactId>aspectjrt</artifactId><!--不要也可测试成功-->
        <version>1.8.10</version>
    </dependency>
    <dependency>
        <groupId>org.aspectj</groupId>
        <artifactId>aspectjweaver</artifactId>
        <version>1.8.10</version>
    </dependency>
    ```
- 编写切面

    ```java
    @Aspect // 声明一个切面
    @Component
    public class LogAspect {
        // 法一：简单
        @Before("execution(* cn.aezo.spring.base.annotation.aop.DemoMethodService.*(..))")
        public void before(JoinPoint joinPoint) {
            MethodSignature methodSignature = (MethodSignature) joinPoint.getSignature();
            Method method = methodSignature.getMethod();
            System.out.println("方法规则式拦截[@Before-execution]：" + method.getName());
        }
    }
    ```
- 调用service

### Scope

- `@Scope("prototype")` 注解类(配置Bean的作用域)
    - `singleton` 整个容器共享一个实例（默认配置）
    - `prototype` 每次调用新建一个实例
    - `request` Web项目中，每一个Http Request新建一个实例
    - `session`
    - `globalSession` 用于portal应用

### EL(Spring-EL)

- `@Value` 在其中输入EL表达式。可对资源进行注入
- 实例

    ```java
    @Configuration
    @ComponentScan("cn.aezo.spring.base.annotation.el")
    @PropertySource("classpath:cn/aezo/spring/base/annotation/el/el.properties") // 注入配置文件
    public class ELConfig {
        @Value("I Love You")
        private String normal;

        @Value("#{systemProperties['os.name']}")
        private String osName;

        @Value("#{T(java.lang.Math).random() * 100.0}")
        private String randomNumber;

        @Value("${site.url:www.aezo.cn}") // 读取配置文件(需要注入配置文件)，使用$而不是#。冒号后面是缺省值
        private Resource siteUrl;

        @Value("#{demoService.another}") // 读取其他类属性的@Value注解值
        private String fromAnother;

        @Value("classpath:cn/aezo/spring/base/annotation/el/test.txt")
        private Resource testFile;

        @Value("http://www.baidu.com")
        private Resource testUrl;

        @Autowired
        private Environment environment;

        // @Bean
        // public static PropertySourcesPlaceholderConfigurer propertyConfigurer() {
        //     return new PropertySourcesPlaceholderConfigurer();
        // }

        public void outputResource() {
            System.out.println("normal = " + normal);
            System.out.println("osName = " + osName);
            System.out.println("randomNumber = " + randomNumber);
            System.out.println("normal = " + siteUrl);
            System.out.println("fromAnother = " + fromAnother);
            System.out.println("environment = " + environment.getProperty("site.url"));

            try {
                System.out.println("testFile = " + IOUtils.toString(testFile.getInputStream(), "UTF-8"));
                System.out.println("testUrl = " + IOUtils.toString(testUrl.getInputStream(), "UTF-8"));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

    }
    ```

### Profile

- 不同的环境读取不同的配置文件：`dev`/`prod`

### Application Event

- 事件：一个Bean(A)完成某个任务后，可以给另外一个Bean(B)发送事件，前提是B对A进行了监听
- 方法：
    - 继承`ApplicationEvent` 进行事件定义

        ```java
        public class DemoEvent extends ApplicationEvent {
            private String message;

            public DemoEvent(Object source, String message) {
                super(source);
                this.message = message;
            }

            public String getMessage() {
                return message;
            }

            public void setMessage(String message) {
                this.message = message;
            }
        }
        ```
    - 实现`ApplicationListener` 进行事件监听

        ```java
        @Component
        public class DemoListener implements ApplicationListener<DemoEvent> {
            @Override
            public void onApplicationEvent(DemoEvent demoEvent) {
                String message = demoEvent.getMessage();
                System.out.println("DemoListener.onApplicationEvent==" + message);
            }
        }
        ```
    - `applicationContext.publishEvent(new DemoEvent(this, message));` 发布事件

        ```java
        @Component
        public class DemoPublisher {
            @Autowired
            ApplicationContext applicationContext;

            public void publish(String message) {
                applicationContext.publishEvent(new DemoEvent(this, message));
            }
        }
        ```

### Spring Aware

- Spring依赖注入最大的亮点就是你所有的Bean对Spring容器的存在是无意识的。即你可以将容器换成其他容器，如Google Guice，这是Bean之间的耦合度很低。
- Spring Aware可以让你的Bean调用Spring提供的资源，缺点是Bean会和Spring框架耦合。
- 相关接口
    - `BeanNameAware` 获得容器中Bean的名称
    - `BeanFactoryAware` 获得当前Bean Factory，这样就有可以调用容器服务
    - `ApplicationContextAware` 获得当前Application Context，这样就有可以调用容器服务
    - `MessageSourceAware` 获得当前Message Source，可以获得文本信息
    - `ApplicationEventPublisherAware` 应用事件发布器，可以发布事件
    - `ResourceLoaderAware` 获得资源加载器，可以获取外部资源
- 实例

    ```java
    @Component
    public class AwareService implements BeanNameAware, ResourceLoaderAware {
        private String beanName;
        private ResourceLoader loader;

        @Override
        public void setBeanName(String s) {
            this.beanName = s;
        }

        @Override
        public void setResourceLoader(ResourceLoader resourceLoader) {
            this.loader = resourceLoader;
        }

        public void outputResult() {
            System.out.println("beanName = " + beanName);
            Resource resource = loader.getResource("classpath:cn/aezo/spring/base/annotation/springaware/test.txt");
            try {
                String test = IOUtils.toString(resource.getInputStream(), "UTF-8");
                System.out.println("test = " + test);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
    ```


### 多线程

- Spring通过任务执行器(TaskExecutor)来实现多线程和并发编程。使用`ThreadPoolTaskExecutor`可实现一个基于线程池的TaskExecutor。
- `@EnableAsync` 可开启对异步任务的支持。需要对应的配置类实现
- `@Async` 注解执行异步任务的方法
- 示例

    ```java
    // 获取线程池
    @Configuration
    @ComponentScan("cn.aezo.spring.base.annotation.thread")
    @EnableAsync // 开启异步任务支持
    public class TaskExecutorConfig implements AsyncConfigurer {
        @Override
        public Executor getAsyncExecutor() {
            ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
            taskExecutor.setCorePoolSize(5);
            taskExecutor.setMaxPoolSize(10);
            taskExecutor.setQueueCapacity(25);
            taskExecutor.initialize();
            return taskExecutor;
        }

        @Override
        public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
            return null;
        }
    }

    // 定义异步方法
    @Service
    public class AsyncTaskService {
        @Async
        public void executeAsyncTask(Integer i) {
            System.out.println("i = " + i);
        }

        @Async
        public void executeAsyncTaskPlus(Integer i) {
            System.out.println("i+1 = " + (i+1));
        }
    }
    ```

### 计划任务

- `@EnableScheduling` 开启定时任务
- `@Scheduled` 执行任务的方法

    ```java
    @Configuration
    @ComponentScan("cn.aezo.spring.base.annotation.scheduled")
    @EnableScheduling
    public class TaskScheduledConfig {
    }

    @Service
    public class ScheduledTaskService {
        private static final SimpleDateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");

        @Scheduled(fixedRate = 5000) // 5000毫秒. fixedRate每隔固定时间执行
        public void reportCurrentTime() {
            System.out.println("每隔5秒执行一次：" + dateFormat.format(new Date()));
        }

        @Scheduled(cron = "0 50 14 ? * *") // 每天14.50执行
        public void fixTimeException() {
            System.out.println("在指定时间执行：" + dateFormat.format(new Date()));
        }
    }
    ```

### 条件注解(Condition)

- `@Condition` 根据满足某一特定条件来创建某个特定的Bean. 如某个Bean创建后才会创建另一个Bean(Spring 4.x)
- 方法
    - 条件类实现`Condition`接口
    - 自定义服务接口，并有多种实现
    - 在`@Configuration`中`@Bean`的方法上注解`@Conditional(条件类.class)`表示符合此条件才会创建对应的Bean

### 组合注解、元注解

- 元注解是指可以注解到其他注解上的注解，被元注解注解之后的注解称之为组合注解
- 如`@Configuration`是包含`@Component`的组合注解，`@Component`为元注解
- 示例，将`@Configuration`和`@ComponentScan`组合成一个注解

    ```java
    @Target(ElementType.TYPE)
    @Retention(RetentionPolicy.RUNTIME)
    @Documented
    @Configuration
    @ComponentScan
    public @interface WiselyConfiguration {
        String[] value() default {};
    }
    ```
