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

## HelloWorld

- maven依赖

    ```xml
        <dependency>
            <groupId>org.springframework</groupId>
            <!--包含spring-core、spring-beans、spring-aop、spring-expression、spring-instrument-->
            <artifactId>spring-context</artifactId>
            <version>4.3.8.RELEASE</version>
        </dependency>
    ```
- 调用

    ```java
       // ApplicationContext context = new ClassPathXmlApplicationContext("beans.xml");
       ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class); // AppConfig为定义的java配置类

       Hello hello = context.getBean("hello", Hello.class);
       hello.hello();
    ```

## 常见注解

### 往容器中注册Bean(组件)

#### 包扫描+组件注解

##### @ComponetScan("cn.aezo")

- 定义需要扫描的包名，并将里面的`@Component`、`@Service`、`@Repository`、`@Controller`注解的类注册为Bean

```java
// java8 @Repeatable表示可重复注解 excludeFilters不扫描过滤，includeFilters扫描过滤(需设置useDefaultFilters=false)
@ComponentScan(value = "cn.aezo.demo", excludeFilters = {
            @ComponentScan.Filter(type = FilterType.ANNOTATION, classes = {Controller.class}) // 基于注解
            @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = {cn.aezo.demo.MyTest}) // 基于类全名
            @ComponentScan.Filter(type = FilterType.CUSTOM, classes = {MyFilterType.class})}) // 基于自定义规则(实现FilterType接口)
@ComponentScan(value = "cn.aezo.demo", includeFilters = {
            @ComponentScan.Filter(type = FilterType.REGEX, pattern = "cn\\.aezo\\.test.*")}, useDefaultFilters = false)

// java8之前可使用@ComponentScans
@ComponentScans({@ComponentScan()})
```

- 注解类表示此类是一个配置类，里面有0个或者多个`@Bean`

##### 组件注解

- `@Component` 没有明确的角色
- `@Service` 在业务逻辑层(cn.aezo.spring.aop_spel.service)使用
- `@Repository` 在数据访问层(cn.aezo.spring.aop_spel.dao)使用
- `@Controller` 在展现层使用
- 上面几个注解效果一样

#### @Bean导入第三方包里面的组件

- `@Bean`
    - 注解配置类中的方法，表示当前方法的返回值是一个Bean，Bean的名称(id)默认是方法名
    - `@Bean("newBeanName")` 自定义Bean名称
    - Springboot项目，将`@Bean`加入在test的代码中时无法注入

#### @Import给容器导入一个组件

- `@Import("cn.aezo.test.MyBean")`
    - Spring Boot中大量的EnableXXX都使用了@Import注解
    - 可以导入导入普通的POJO类或带有`@Configuration`注解的配置类，或导入实现了`ImportSelector`/`ImportBeanDefinitionRegistrar`/`DeferredImportSelector`接口的返回的类。功能类似XML配置用来导入配置类
        - DeferredImportSelector 为 ImportSelector 的子接口。区别是他会在所有的@Configuration类加载完成之后再加载返回的配置类，而ImportSelector会在当前Configuration类加载之前去加载返回的配置类
        - 可以使用@Order注解或者Ordered接口来指定DeferredImportSelector的加载顺序
    - `@ImportResource` 和@Import类似，区别就是@ImportResource导入的是配置文件。其属性default和locations作用相同，都是用来指定配置文件的位置；reader属性则用来指定配置文件解析器，内置XmlBeanDefinitionReader和GroovyBeanDefinitionReader，也可自定义。Spring还是推荐使用@Import而不是@ImportResource
- `@Import`结合`ImportSelector`

```java
// ### 基于导入选择器
public class MyImportSelector implements ImportSelector {
    // AnnotationMetadata可获取当前注解@Import类的所有注解信息
    @Override
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        // 返回需要的导入的Bean类全名（可以不用是真实类名）
        return new String[] {"cn.aezo.smjava.javaee.spring5.bean.demo2.MyImportSelectorBean", MyImportSelectorBean.class.getName()};
    }
}

// ### 使用
@Import({MyImportSelector.class})
public class AppImport {
    public static void main( String[] args ) {
        AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext(AppImport.class);

        System.out.println(ctx.getBean(MyImportSelectorBean.class));

        String[] names = ctx.getBeanDefinitionNames();
        for (String name : names) {
            System.out.println(name);
        }
    }
}
```
- `@Import`结合`ImportBeanDefinitionRegistrar`

```java
// ### 基于ImportBeanDefinitionRegistrar
public class SmImportBeanDefinitionRegistrar implements ImportBeanDefinitionRegistrar {
    /**
     * @param annotationMetadata 当前类的注解信息
     * @param beanDefinitionRegistry BeanDefinition注册类
     */
    @Override
    public void registerBeanDefinitions(AnnotationMetadata annotationMetadata, BeanDefinitionRegistry beanDefinitionRegistry) {
        BeanDefinitionBuilder beanDefinitionBuilder = BeanDefinitionBuilder.genericBeanDefinition(MyBean.class);
        beanDefinitionBuilder.addPropertyValue("name", "ImportBeanDefinitionRegistrar#registerBeanDefinitions");

        GenericBeanDefinition genericBeanDefinition = (GenericBeanDefinition) beanDefinitionBuilder.getBeanDefinition();

        beanDefinitionRegistry.registerBeanDefinition("myBean", genericBeanDefinition);
    }
}

// ### 使用
@Import(SmImportBeanDefinitionRegistrar.class)
public class AppConfig {}
```

#### 使用Spring提供的FactoryBean(工厂Bean)

- 通过`id(name)`获取的是FactoryBean的getObject返回的对象。使用`&name`可获取FactoryBean本身
- `BeanFactory`和`FactoryBean`区别 https://www.cnblogs.com/aspirant/p/9082858.html
- 模拟mybatis参考源码`smjava -> javaee -> springArch -> spring5 -> demo3`

```java
// ### 实现FactoryBean
public class MyFactoryBean implements FactoryBean {
    @Override
    public MyBean getObject() throws Exception {
        return new MyBean();
    }

    @Override
    public Class<?> getObjectType() {
        return MyBean.class;
    }

    // JDK8可提供isSingleton默认实现
}

// ### 使用
public class App {
    public static void main( String[] args ) {
        AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext(App.class);

        // 获取的是FactoryBean中getObject返回的对象
        MyBean myBean = (MyBean) ctx.getBean("myFactoryBean");
        System.out.println(myBean);

        // 获取的是FactoryBean本身
        MyFactoryBean myFactoryBean = (MyFactoryBean) ctx.getBean("&myFactoryBean");
    }

    @Bean
    public MyFactoryBean myFactoryBean() {
        return new MyFactoryBean();
    }
}
```

### 自动装配(取出Bean赋值给当前类属性)

- `@Autowired` Spring提供
    - 默认按类型by type(根据类)
    - 如果想用by name，则联合使用`@Qualifier("my-bean-name")`
    - `@Autowired List<Monitor> monitors;` 也可以注入集合
- `@Resource` JSR-250提供(常用)
- `@Inject` JSR-330提供

### @Scope

- `@Scope("prototype")` 注解类(配置Bean的作用域，可和`@Bean`联合使用)
    - `singleton` 整个容器共享一个实例(默认配置). IOC容器启动(`new AnnotationConfigApplicationContext()`)，就会创建所有的Bean(`@Lazy`懒加载，仅用于单例模式，只有在第一次获取Bean时才创建此Bean)
    - `prototype` 每次调用新建一个实例. IOC容器启动，不会创建Bean，只有在获取的时候创建Bean
        - **此对象`@Autowired`注入几次就会产生几个对象，和调用此对象方法无关**
        - 如果此类型Bean含有有状态字段，则也容易产生并发问题，prototype并不能解决
    - `request` Web项目中，每一个HttpRequest新建一个实例
    - `session` Web项目中，同一个session创建一个实例
    - `globalSession` 用于portal应用
- SpringBoot的作用域如：`@RequestScope`、`@SessionScope`、`@ApplicationScope`(`@Component`等默认是`singleton`)

### 条件注解@Conditional

- 根据满足某一特定条件来创建某个特定的Bean. 如某个Bean创建后才会创建另一个Bean(Spring 4.x)
- 内置条件
    - `@ConditionalOnProperty` 要求配置属性匹配条件
        - eg：@ConditionalOnProperty(value = {"feign.compression.response.enabled"}, matchIfMissing = false) 、@ConditionalOnProperty(name = "zuul.use-filter", havingValue = "true", matchIfMissing = false) matchIfMissing=false表示无此参数则不符合条件
    - `@ConditionalOnMissingBean` 当给定的类型、类名、注解、昵称在beanFactory中不存在时返回true，各类型间是or的关系
        - eg：@ConditionalOnMissingBean(type = {"okhttp3.OkHttpClient"})
    - `@ConditionalOnBean` 与上相反，在存在某个bean的时候
        - eg：@ConditionalOnBean({Client.class})
    - `@ConditionalOnMissingClass` 当前classpath不可以找到某个类型的类时，各类型间是and的关系
    - `@ConditionalOnClass` 与上相反，当前classpath可以找到某个类型的类时
        - eg：@ConditionalOnClass({Feign.class})、@ConditionalOnClass(name = {"feign.hystrix.HystrixFeign"})
    - `@ConditionalOnResource` 当前classpath是否存在某个资源文件
    - `@ConditionalOnWebApplication` 当前spring context是否是web应用程序
    - `@ConditionalOnNotWebApplication`	web环境不存在时
    - `@ConditionalOnExpression` spel表达式执行为true
    - `@ConditionalOnSingleCandidate` 当给定类型的bean存在并且指定为Primary的给定类型存在时返回true
    - `@ConditionalOnCloudPlatform` 当所配置的CloudPlatform为激活时返回true
    - `@ConditionalOnJava` 运行时的java版本号是否包含给定的版本号，如果包含返回匹配，否则返回不匹配
    - `@ConditionalOnJndi` 给定的jndi的Location 必须存在一个，否则返回不匹配
- 自定义条件

```java
// ## 条件判断
@Conditional({MyWindowsCondition.class}) // 必须符合所有的条件才会注入此Bean(可以注解在类或方法上)
@Bean("myBean3")
public MyBean myBean3() {
    return new MyBean();
}

// ## 条件
public class MyWindowsCondition implements Condition {
    /**
     * 判断是否符合条件
     * @param context 判断条件能使用的上下文
     * @param metadata 注解信息
     * @return
     */
    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        // 1.可以获取到IOC使用的BeanFactory
        ConfigurableListableBeanFactory ctx = context.getBeanFactory();
        // 2.可以获取类加载器
        ClassLoader classLoader = context.getClassLoader();
        // 3.可以获取当前环境信息
        Environment environment = context.getEnvironment();
        // 4.可以获取Bean定义注册类
        BeanDefinitionRegistry registry = context.getRegistry();
        ResourceLoader resourceLoader = context.getResourceLoader();

        if(environment.getProperty("os.name").contains("Windows")) {
            return true;
        }

        return false;
    }
}
```

### Bean生命周期

- 初始化和销毁方法实现方式
    - 指定@Bean初始化和销毁方法属性：`initMethod`, `destroyMethod`
    - 实现`InitializingBean`, `DisposableBean`(org.springframework.beans.factory.DisposableBean) 
    - 使用JSR250：`@PostConstruct` Bean创建完成并完成属性赋值后调用, `@PreDestroy`(javax.annotation.PreDestroy) 销毁Bean前调用
- **后置处理器`BeanPostProcessor`** (org.springframework.beans.factory.config.BeanPostProcessor)
    - postProcessBeforeInitialization 在Bean创建完成并完成属性赋值后，且在初始化方法调用之前调用
    - postProcessAfterInitialization 在初始化之后调用
    - `@Autowired`是基于BeanPostProcessor实现的

```java
public class App {
    public static void main( String[] args ) {
        /*
        constructor MyBean2...
        postProcessBeforeInitialization...
        init MyBean2...(afterPropertiesSet...)
        postProcessAfterInitialization...
        创建IOC完成...
        destroy MyBean2...
        */
        AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext(App.class);
        System.out.println("创建IOC完成...");

        ctx.close(); // 容器关闭调用destroyMethod
    }

    @Bean(initMethod = "init", destroyMethod = "destroy")
    public MyBean2 myBean2() {
        return new MyBean2();
    }

    @Bean
    public MyBean3 myBean3() {
        return new MyBean3();
    }

    // MyBeanPostProcessor需要实现BeanPostProcessor后置处理器
    @Bean
    public MyBeanPostProcessor myBeanPostProcessor() {
        return new MyBeanPostProcessor();
    }
}

// ###
public class MyBean2 {
    public MyBean2() {
        System.out.println("constructor MyBean2...");
    }

    // @PostConstruct // Bean创建完成并完成属性赋值后调用（使用JSR250方式需要的代码）
    public void init() {
        System.out.println("init MyBean2...");
    }

    // @PreDestroy
    public void destroy() {
        System.out.println("destroy MyBean2...");
    }
}

// ### 基于接口实现
public class MyBean3 implements InitializingBean, DisposableBean {
    // Bean创建完成，且属性赋值完成后调用
    @Override
    public void afterPropertiesSet() throws Exception {
        System.out.println("afterPropertiesSet MyBean3...");
    }

    @Override
    public void destroy() throws Exception {
        System.out.println("destroy MyBean3...");
    }
}
```

### 属性赋值

- `@Value` 在其中输入EL表达式(Spring-EL)。可对资源进行注入
- `@PropertySource` 注入外部配置文件值。springboot通过spring-boot-configuration-processor这个依赖会把配置文件的值注入到@Value里面

```java
@Configuration
@ComponentScan("cn.aezo.spring.base.annotation.el")
@PropertySource("classpath:cn/aezo/spring/base/annotation/el/el.properties") // 注入配置文件
public class ELConfig {
    @Value("I Love You") // 基本数值赋值
    private String normal;

    @Value("#{systemProperties['os.name']}") // 获取系统名称. SpEL: @Value("#{20-2}") => 18
    private String osName;

    @Value("#{T(java.lang.Math).random() * 100.0}")
    private String randomNumber;

    @Value("${site.url:www.aezo.cn}/index.html") // 读取配置文件(需要注入配置文件)，使用$而不是#。冒号后面是缺省值. `${site.url:}`无则为""，防止为定义此参数值(特别是通过命令行传入的参数)
    private Resource siteUrl;

    @Value("${site.tags}")
    private String[] tags; // 获取数组，yml中可定义site.tags=a,b,c # 默认会基于`,`分割。(yml中使用`-`则需要定义配置类实体)

    @Value("#{demoService.another}") // 读取其他类属性的@Value注解值
    private String fromAnother;

    @Value("classpath:cn/aezo/spring/base/annotation/el/test.txt")
    private Resource testFile;

    @Value("http://www.baidu.com")
    private Resource testUrl;

    @Autowired
    private Environment environment;

    public void outputResource() {
        System.out.println("normal = " + normal);
        System.out.println("osName = " + osName);
        System.out.println("randomNumber = " + randomNumber);
        System.out.println("normal = " + siteUrl);
        System.out.println("fromAnother = " + fromAnother);
        System.out.println("environment = " + environment.getProperty("site.url")); // 配置文件中的值默认全部赋值到了环境变量中了

        try {
            System.out.println("testFile = " + IOUtils.toString(testFile.getInputStream(), "UTF-8"));
            System.out.println("testUrl = " + IOUtils.toString(testUrl.getInputStream(), "UTF-8"));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

// el.properties
site.url=www.aezo.cn
```

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

## AOP

- 说明
    - Spring AOP的底层原理就是动态代理，因此局限于方法拦截
    - Spring AOP默认是使用JDK动态代理，如果代理的类没有接口则会使用CGLib代理
    - JDK动态代理是需要实现某个接口了，而我们类未必全部会有接口，于是CGLib代理就有了，CGLib代理其生成的动态代理对象是目标类的子类。如果是单例的我们最好使用CGLib代理，如果是多例的我们最好使用JDK代理(JDK在创建代理对象时的性能要高于CGLib代理，而生成代理对象的运行性能却比CGLib的低)
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

    <!-- springboot项目依赖 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-aop</artifactId>
    </dependency>
    ```
- 编写切面

    ```java
    // 示例一
    @Aspect // 声明一个切面
    @Component
    public class LogAspect {
        // 此接口/类中方法
        @Before("execution(* cn.aezo.spring.base.annotation.aop.DemoMethodService.*(..)) || execution(* cn.aezo.spring.base.annotation.aop.DemoMethodService2.*(..))")
        // execution(* cn.aezo.spring.base.annotation.aop.*.*(..)) // 此包中方法(第一个*代替了public void；此表达式也会拦截含throws的方法)
        // execution(public * cn.aezo.spring.base.annotation.aop..*.*(..)) // 此包或者子包中public类型的方法

        // this：方法是在那个类中被调用的；target：目标对象是否是某种类型；within：当前执行代码是否属于某个类(静态植入)
        // within(cn.aezo.spring.base.*) // 任何此包中的方法
        // within(cn.aezo.spring.base..*) // 任何此包或其子包中的方法
        // target(org.springframework.web.client.RestTemplate) // 任何目标对象实现了此接口的方法。**如果使用 execution(* org.springframework.web.client.RestTemplate.execute(..))是无法拦截到的，RestTemplate本身是由代理执行的**
        // this(cn.aezo.spring.base.annotation.aop.DemoMethodService) // 实现了此接口中的方法
        // args(java.io.Serializable) // 有且只有一个Serializable参数
        
        // @within(org.springframework.transaction.annotation.Transactional) // 任何一个目标对象声明的类型有一个 @Transactional 注解的连接点
        // @target(org.springframework.transaction.annotation.Transactional) // 目标对象中有一个 @Transactional 注解的任意连接点
        // @annotation(org.springframework.transaction.annotation.Transactional) // 任何一个执行的方法有一个 @Transactional 注解的连接点
        // @args(org.springframework.transaction.annotation.Transactional) // 有且仅有一个参数并且参数上类型上有@Transactional注解(注意是参数类型上有@Transactional注解，而不是方法的参数上有注解)
        
        // bean(simpleSay) // bean名字为simpleSay中的所有方法
        // bean(*Impl) // bean名字匹配*Impl的bean中的所有方法
        public void before(JoinPoint joinPoint) {
            MethodSignature methodSignature = (MethodSignature) joinPoint.getSignature();
            Method method = methodSignature.getMethod();
            System.out.println("方法规则式拦截[@Before-execution]：" + method.getName());
        }
    }

    // 示例二
    @Aspect
    @Component
    public class LogIntercept {
        @Pointcut("execution(public * cn.aezo.spring.base.annotation.aop..*.*(..))")
        public void pointcut(){}

        @Before("pointcut()")
        public void before(JoinPoint joinPoint) {
            this.printLog("execution方法执行前");
        }

        @Around("pointcut()")
        public Object around(ProceedingJoinPoint pjp) throws Throwable {
            Object[] args = pjp.getArgs(); // 获取被切入方法参数值

            this.printLog("execution方法执行前");
            Object retObj = pjp.proceed();
            this.printLog("execution方法执行后");

            return retObj;
        }

        @After("recordLog()")
        public void after() {
            this.printLog("execution方法执行后");
        }

        // returning属性指定一个形参名，用于表示Advice方法中可定义与此同名的形参，该形参可用于访问目标方法的返回值
        @AfterReturning(value = "pointcut()", returning = "result")
        public void afterReturning(JoinPoint joinPoint, Object result) {
            Object[] args = joinPoint.getArgs(); // 获取被切入方法参数值
            System.out.println("afterReturning...");
        }

        @AfterThrowing(value = "pointcut() && @annotation(myExecption)", throwing = "ex")
        public void afterThrowing(JoinPoint joinPoint, MyException myExecption, Exception ex){
            String methodName = joinPoint.getSignature().getName();
            System.out.println("afterThrowing...");
        }
    }

    // 示例三
    @Aspect
    @Component
    public class OptimisticCheckAspect {
        @Value("sq.tableName:ds_test")
        private String tableName;

        private List<String> tableList;

        public JdbcTemplateAspect() {
            tableList = new ArrayList<>();
            if(tableName != null) {
                tableList.addAll(Arrays.asList(tableName.split(",")));
            }
        }

        // 检查通过 JdbcTemplate 执行的sql语句是否携带session字段
        @Before("execution(* org.springframework.jdbc.core.JdbcTemplate.update(..)) " +
                " || execution(* org.springframework.jdbc.core.JdbcTemplate.batchUpdate(..))")
        public void before(JoinPoint joinPoint) {
            Object[] args = joinPoint.getArgs();
            if(args != null && args.length > 0 && args[0] instanceof String) {
                String sql = ((String) args[0]).trim();
                if(sql.toLowerCase().startsWith("insert") || sql.toLowerCase().startsWith("update")) {
                    if(!sql.matches("(.*)\\s+((?i)version)\\s*=(.*)")) {
                        throw new RuntimeException("修改此实体需要基于乐观锁实现");
                    }
                }
            }
        }
    }
    ```
- 调用service

## Profile

- 不同的环境读取不同的配置文件：`dev`/`prod`

## Application Event

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

## Spring Aware

- Spring依赖注入最大的亮点就是你所有的Bean对Spring容器的存在是无意识的。即你可以将容器换成其他容器，如Google Guice，这是Bean之间的耦合度很低。
- Spring Aware可以让你的Bean调用Spring提供的资源，缺点是Bean会和Spring框架耦合。
- 相关接口
    - `BeanNameAware` 获得容器中Bean的名称
    - `BeanFactoryAware` 获得当前BeanFactory，这样就有可以调用容器服务
    - `ApplicationContextAware` 获得当前ApplicationContext，这样就有可以调用容器服务
    - `MessageSourceAware` 获得当前MessageSource，可以获得文本信息
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

## 多线程 @EnableAsync

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

## 计划任务 @Scheduled

- `@EnableScheduling` 开启定时任务
- `@Scheduled` 执行任务的方法

    ```java
    @Configuration
    @ComponentScan("cn.aezo.spring.base.annotation.scheduled") // springboot无需
    @EnableScheduling
    public class TaskScheduledConfig {
        // 默认同一时刻只会运行一个@Scheduled修饰的方法，时间太长会阻塞其他定时
        // 此时定义成5个线程并发(被@Scheduled修饰的不同方法可以并发执行，同一个方法不会产生并发)
        @Bean
        public Executor taskScheduler() { // java.util.concurrent.Executor
            return Executors.newScheduledThreadPool(5);
        }
    }

    @Service
    public class ScheduledTaskService {
        private static final SimpleDateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");

        // 方法访问权限必须为protected或以下
        @Scheduled(fixedRate = 5000) // 5000毫秒. fixedRate每隔固定时间执行
        public void reportCurrentTime() {
            System.out.println("每隔5秒执行一次：" + dateFormat.format(new Date()));
        }

        @Scheduled(cron = "0 50 14 ? * *") // 每天14.50执行。程序启动并不会立即运行，比如 14:45 启动，只有等到 14:50 才会第一次运行
        // @Scheduled(cron = "${myVal.cron}") // springboot只需再yml里面定义配置即可，无需创建JavaBean配置
        public void fixTimeException() {
            System.out.println("在指定时间执行：" + dateFormat.format(new Date()));
        }
    }
    ```
- cron配置说明 [^1]
    - `{秒} {分} {时} {日} {月} {周} {年(可选)}`
        - Seconds可出现`, -  *  /`四个字符，有效范围为0-59的整数    
        - Minutes可出现`, -  *  /`四个字符，有效范围为0-59的整数    
        - Hours可出现`, -  *  /`四个字符，有效范围为0-23的整数
            - `*` 代表每隔1秒/分/时触发；
            - `,` 代表在指定的秒/分/时触发，比如"10,20,40"代表10秒/分/时、20秒/分/时和40秒/分/时时触发任务 
            - `-` 代表在指定的范围内触发，比如"5-30"代表从5秒/分/时开始触发到30秒/分/时结束触 发，每隔1秒/分/时触发
            - `/` 代表触发步进(step)，"/"前面的值代表初始值("\*"等同"0")，后面的值代表偏移量。比如"0/25"或者"\*/25"代表从0秒/分/时开始，每隔25秒/分/时触发1次
    - 常用定时配置

        ```bash
        "0/10 * * * * ?" 每10秒触发(程序启动后/任务添加后，第一次触发为0/10/20/30/40/50秒中离当前时间最近的时刻。下同) 
        "0 0/5 * * * ?" 每5分钟执行一次("* 0/5 * * * ?" 每5分钟连续执行60秒，这60秒期间每秒执行一次)
        "0 0 12 * * ?" 每天中午12点触发
        "0 15 10 ? * *" 每天上午10:15触发 
        "0 15 10 * * ?" 每天上午10:15触发 
        "0 15 10 * * ? *" 每天上午10:15触发 
        "0 0 10,14,16 * * ?" 每天上午10点，下午2点，4点 
        "0 0/30 9-17 * * ?" 朝九晚五工作时间内每半小时 
        "0 0 12 ? * WED" 表示每个星期三中午12点 
        "0 15 10 * * ? 2005" 2005年的每天上午10:15触发 
        "0 * 14 * * ?" 在每天下午2点到下午2:59期间的每1分钟触发 
        "0 0/5 14 * * ?" 在每天下午2点到下午2:55期间的每5分钟触发 
        "0 0/5 14,18 * * ?" 在每天下午2点到2:55期间和下午6点到6:55期间的每5分钟触发 
        "0 0-5 14 * * ?" 在每天下午2点到下午2:05期间的每1分钟触发 
        "0 10,44 14 ? 3 WED" 每年三月的星期三的下午2:10和2:44触发 
        "0 15 10 ? * MON-FRI" 周一至周五的上午10:15触发 
        "0 15 10 15 * ?" 每月15日上午10:15触发
        "0 15 10 L * ?" 每月最后一日的上午10:15触发 
        "0 15 10 ? * 6L" 每月的最后一个星期五上午10:15触发(6代表一周中的第6天，即周五)
        "0 15 10 ? * 6L 2002-2005" 2002年至2005年的每月的最后一个星期五上午10:15触发 
        "0 15 10 ? * 6#3" 每月的第三个星期五上午10:15触发
        ```
- 手动启动任务和停止任务(基于springboot v2.0.1测试)

```java
// ## Job接口
public interface Job extends Runnable {
    String getName();

    String getCron();

    String setCron();
}

// ## Job管理器
@Component
public class JobManager {
    @Autowired
    private ThreadPoolTaskScheduler threadPoolTaskScheduler;

    @Bean
    public ThreadPoolTaskScheduler threadPoolTaskScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(20);
        return scheduler;
    }

    private Map<String, ScheduledFuture<?>> jobMap = new ConcurrentHashMap<>();

    /**
     * 初始化定时任务
     * @param job
     * @param runImmediately 是否立即运行任务
     */
    public void startJob(Job job, boolean runImmediately) {
        if(runImmediately) job.run();
        ScheduledFuture<?> future = threadPoolTaskScheduler.schedule(job, new CronTrigger(job.getCron()));
        jobMap.put(job.getName(), future);
    }

    /**
     * 停止定时任务
     */
    public void stopJob(String jobName) {
        Assert.notNull(jobName, "JobName can not be null");

        ScheduledFuture<?> future = jobMap.get(jobName);
        if(future != null) {
            future.cancel(true);
        }
    }
}
```

## SpringMVC

### 拦截器

- 在Filter上注解@Component
- 往FilterRegistrationBean中注册并暴露Bean，可指定拦截某路径
- 实现WebMvcConfigurer并暴露Bean，可指定拦截某路径和设定Order顺序

```java
@Configuration
public class CustomerWebMvcConfig implements WebMvcConfigurer {
    /**
     * 往InterceptorRegistry中注册。需要实现 WebMvcConfigurer 接口
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 可添加多个
        registry.addInterceptor(new CustomerHandlerInterceptor()).addPathPatterns("/**");
    }

    /**
     * 直接返回Filter. 解决同源策略问题（Access-Control-Allow-Origin跨域）。或者在Filter上注解@Component
     */
    @Bean
    public Filter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        config.addAllowedOrigin("*");
        config.addAllowedHeader("*");
        config.addAllowedMethod("*");
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source); // org.springframework.web.filter.CorsFilter extends OncePerRequestFilter
    }

    /**
     * 往FilterRegistrationBean中注册. Token验证拦截
     */
    @Bean
    public FilterRegistrationBean indexFilterRegistration() {
        FilterRegistrationBean<> registrationBean = new FilterRegistrationBean<>();
        registrationBean.setFilter(new AuthFilter());
        registrationBean.setUrlPatterns("/*");
        // Filter的init方法中可获取到此参数值：exclusions = filterConfig.getInitParameter("exclusions");
        registrationBean.addInitParameter("exclusions", "*.js,*.gif,*.jpg,*.png,*.css,*.ico");
        registrationBean.setOrder(1);
        return registrationBean;
    }
}

@Configuration
public class CustomerHandlerInterceptor implements HandlerInterceptor {
    // 是否进行拦截，返回True表示拦截
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {
        return true;
    }

    // 处理拦截
    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
                           ModelAndView modelAndView) throws Exception {
    }

    // 拦截后处理
    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex)
            throws Exception {
    }
}
```

## Spring相关类/接口说明

### org.springframework.context

- annotation
    - `@Import` 导入Bean，具体见上文
    - `@ImportResource`
    - `ImportSelector`
    - `DeferredImportSelector`
    - `ImportBeanDefinitionRegistrar`

### org.springframework.boot

- context.properties
    - `@ConfigurationProperties` 将properties配置文件中的属性对应到类上，需要和@EnableConfigurationProperties或@Component等结合使用
    - `@EnableConfigurationProperties` 使使用@ConfigurationProperties注解的类生效，可在任何配置类上定义
        - 如果一个配置类只配置@ConfigurationProperties注解，而没有使用@Component，那么在IOC容器中是获取不到properties配置文件转化的bean(但是可以通过@Value直接获取properties的值)。说白了@EnableConfigurationProperties相当于把使用@ConfigurationProperties的类进行了一次注入。如：@EnableConfigurationProperties({FeignClientEncodingProperties.class})
- autoconfigure
    - `@AutoConfigureBefore`
    - `@AutoConfigureAfter` 在加载某配置的类之后再加载当前类。如：@AutoConfigureAfter({FeignAutoConfiguration.class})



---

参考文章

[^1]: https://www.cnblogs.com/X-World/p/6113910.html (cron表达式)