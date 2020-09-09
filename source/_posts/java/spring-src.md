---
layout: "post"
title: "Spring源码解析"
date: "2020-09-08 09:25"
categories: [java]
tags: [spring, src]
---

## IOC

### 类关系

![spring-ioc](/data/images/java/spring-src-ioc.png)

- **AnnotationConfigApplicationContext**
    - AnnotationConfigRegistry
    - BeanDefinitionRegistry
    - ApplicationContext
        - ListableBeanFactory
            - BeanFactory
    - ~DefaultListableBeanFactory beanFactory
- **DefaultListableBeanFactory**
    - BeanFactory
    - BeanDefinitionRegistry
- BeanDefinition 描述了一个Bean实例的属性值，构造函数参数值        

### 

```java
// 测试入口代码
@ComponentScan("cn.aezo.smjava.javaee.spring5.bean.c01_ioc_flow.annotation")
public class App {
    public static void main( String[] args ) {
        AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext(App.class); // 可传入多个配置类
        System.out.println("创建IOC完成...");
        MyService myService = (MyService) ctx.getBean("myService");
        myService.doService();
    }
}

// 创建AnnotationConfigApplicationContext
public AnnotationConfigApplicationContext(Class<?>... annotatedClasses) {
    this(); // 1.实例化 AnnotationConfigApplicationContext：reader、scanner初始化
    register(annotatedClasses); // 2.注册传入参数App.class对应的bean，会走 AnnotatedBeanDefinitionReader#doRegisterBean
    refresh(); // 3.注册
}

// 1.1 会先实例化父类 GenericApplicationContext(实例化时会创建一个 DefaultListableBeanFactory)
public AnnotationConfigApplicationContext() {
    this.reader = new AnnotatedBeanDefinitionReader(this); // 会调用 AnnotationConfigUtils.registerAnnotationConfigProcessors 注册内置的 internalConfigurationAnnotationProcessor 等
    this.scanner = new ClassPathBeanDefinitionScanner(this);
}

// 3.注册(AbstractApplicationContext#refresh)
@Override
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        // Prepare this context for refreshing.
        prepareRefresh();

        // Tell the subclass to refresh the internal bean factory.
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory(); // 3.1

        // Prepare the bean factory for use in this context.
        prepareBeanFactory(beanFactory);

        try {
            // Allows post-processing of the bean factory in context subclasses.
            postProcessBeanFactory(beanFactory); // 3.2

            // Invoke factory processors registered as beans in the context.
            invokeBeanFactoryPostProcessors(beanFactory); // 3.3 调用工厂处理器注册bean到上下文中

            // Register bean processors that intercept bean creation.
            registerBeanPostProcessors(beanFactory);

            // Initialize message source for this context.
            initMessageSource();

            // Initialize event multicaster for this context.
            initApplicationEventMulticaster();

            // Initialize other special beans in specific context subclasses.
            onRefresh();

            // Check for listener beans and register them.
            registerListeners();

            // Instantiate all remaining (non-lazy-init) singletons.
            finishBeanFactoryInitialization(beanFactory);

            // Last step: publish corresponding event.
            finishRefresh();
        }

        catch (BeansException ex) {
            if (logger.isWarnEnabled()) {
                logger.warn("Exception encountered during context initialization - " +
                        "cancelling refresh attempt: " + ex);
            }

            // Destroy already created singletons to avoid dangling resources.
            destroyBeans();

            // Reset 'active' flag.
            cancelRefresh(ex);

            // Propagate exception to caller.
            throw ex;
        }

        finally {
            // Reset common introspection caches in Spring's core, since we
            // might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
        }
    }
}

// 3.3 ConfigurationClassPostProcessor#processConfigBeanDefinitions
public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
    // ...
    Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates); // configCandidates为配置类，如上文传入的App.class
    // ...
    parser.parse(candidates); // 3.3.1 使用 ConfigurationClassParser 解析配置类(实际是进行扫描包)
    // ...
}

// 3.3.1 ComponentScanAnnotationParser#parse 解析配置类(实际是进行扫描包)
public Set<BeanDefinitionHolder> parse(AnnotationAttributes componentScan, final String declaringClass) {
    // componentScan 为配置类的注解 @ComponentScan
    ClassPathBeanDefinitionScanner scanner = new ClassPathBeanDefinitionScanner(this.registry,
            componentScan.getBoolean("useDefaultFilters"), this.environment, this.resourceLoader);
    // ...
    // 获取 @ComponentScan 的 basePackages 参数
    Set<String> basePackages = new LinkedHashSet<>();
    String[] basePackagesArray = componentScan.getStringArray("basePackages");
    for (String pkg : basePackagesArray) {
        String[] tokenized = StringUtils.tokenizeToStringArray(this.environment.resolvePlaceholders(pkg),
                ConfigurableApplicationContext.CONFIG_LOCATION_DELIMITERS);
        Collections.addAll(basePackages, tokenized);
    }
    // ...

    return scanner.doScan(StringUtils.toStringArray(basePackages)); // 3.3.1.1 基于 basePackages 扫描bean
}

// 3.3.1.1 基于 basePackages 扫描bean
protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
    Assert.notEmpty(basePackages, "At least one base package must be specified");
    Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<>();
    for (String basePackage : basePackages) {
        Set<BeanDefinition> candidates = findCandidateComponents(basePackage); // 获取包下的所有Bean
        for (BeanDefinition candidate : candidates) {
            ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(candidate);
            candidate.setScope(scopeMetadata.getScopeName());
            String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
            if (candidate instanceof AbstractBeanDefinition) {
                postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
            }
            if (candidate instanceof AnnotatedBeanDefinition) {
                AnnotationConfigUtils.processCommonDefinitionAnnotations((AnnotatedBeanDefinition) candidate);
            }
            if (checkCandidate(beanName, candidate)) {
                BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(candidate, beanName);
                definitionHolder =
                        AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
                beanDefinitions.add(definitionHolder);
                registerBeanDefinition(definitionHolder, this.registry); // 注册到registry中，调用 BeanDefinitionReaderUtils.registerBeanDefinition
            }
        }
    }
    return beanDefinitions;
}
```

