---
layout: "post"
title: "SOFAStack源码分析"
date: "2021-04-13 22:23"
categories: java
tags: [springboot, plugin, 微服务, src]
---

## isle-sofa-boot模块隔离

### 初始化

- **初始化SOFABoot模块：主要是初始化各模块的SpringContext上下文**
- 如基于多Ark Biz启动，一般不会包含此包，各Biz间通信基于runtime-sofa-boot包完成

#### Spring启动完成后广播事件

- Spring相关

```java
// AbstractApplicationContext.java，参考[spring-ioc-src.md#refresh方法概览](/_posts/java/java-src/spring-ioc-src.md#refresh方法概览)
public void refresh() throws BeansException, IllegalStateException {
    // ...
    this.finishRefresh();
}

// ServletWebServerApplicationContext.java
protected void finishRefresh() {
    // 调用父类
    super.finishRefresh();
    WebServer webServer = this.startWebServer();
    if (webServer != null) {
        this.publishEvent(new ServletWebServerInitializedEvent(webServer, this));
    }
}

// AbstractApplicationContext.java
protected void finishRefresh() {
    this.clearResourceCaches();
    this.initLifecycleProcessor();
    this.getLifecycleProcessor().onRefresh();
    // 广播事件
    this.publishEvent((ApplicationEvent)(new ContextRefreshedEvent(this)));
    LiveBeansView.registerApplicationContext(this);
}
```
- SofaModuleContextRefreshedListener.java 监听Spring启动后事件

```java
// SofaModuleContextRefreshedListener实例化参考[sofa-boot-autoconfigure](#sofa-boot-autoconfigure)
public class SofaModuleContextRefreshedListener implements PriorityOrdered,
                                               ApplicationListener<ContextRefreshedEvent>,
                                               ApplicationContextAware {
   @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        if (applicationContext.equals(event.getApplicationContext())) {
            try {
                // 处理 pipeline 流水线
                pipelineContext.process();
            } catch (Throwable t) {
                SofaLogger.error("process pipeline error", t);
                throw new RuntimeException(t);
            }
        }
    }                                                
}
```

#### 处理pipeline流水线

- DefaultPipelineContext.java, 其实例化参考[sofa-boot-autoconfigure](#sofa-boot-autoconfigure)

```java
public class DefaultPipelineContext implements PipelineContext {
    @Autowired
    private List<PipelineStage> stageList;

    @Override
    public void process() throws Exception {
        // 依次处理所有 PipelineStage：**ModelCreatingStage、SpringContextInstallStage、ModuleLogOutputStage**
        for (PipelineStage pipelineStage : stageList) {
            pipelineStage.process();
        }
    }

    // ...
}
```

##### SpringContextInstallStage为例

```java
// AbstractPipelineStage.java
public abstract class AbstractPipelineStage implements PipelineStage {
    @Override
    public void process() throws Exception {
        // ++++++++++++++++++ SpringContextInstallStage of SqBiz Main Start +++++++++++++++++
        SofaLogger.info("++++++++++++++++++ {} of {} Start +++++++++++++++++", this.getClass()
            .getSimpleName(), appName); // appName 为 spring.application.name
        // 实际处理程序
        doProcess();
        // ++++++++++++++++++ SpringContextInstallStage of SqBiz Main End +++++++++++++++++
        SofaLogger.info("++++++++++++++++++ {} of {} End +++++++++++++++++", this.getClass()
            .getSimpleName(), appName);
    }
}

// SpringContextInstallStage.java, 其实例化参考[sofa-boot-autoconfigure](#sofa-boot-autoconfigure)
public class SpringContextInstallStage extends AbstractPipelineStage {
    private void doProcess(ApplicationRuntimeModel application) throws Exception {
        // 打印模块信息
        /*
        All activated module list(2) >>>>>>>
            ├─ cn.aezo.sqbiz.sqbiz-plugin.service-consumer
            └─ cn.aezo.sqbiz.sqbiz-plugin.service-provider

        Modules that could install(2) >>>>>>>
            ├─ cn.aezo.sqbiz.sqbiz-plugin.service-provider
            └─ cn.aezo.sqbiz.sqbiz-plugin.service-consumer
        */
        outputModulesMessage(application);
        // 创建模块的SpringContextLoader(上下文加载器). new DynamicSpringContextLoader(applicationContext)
        SpringContextLoader springContextLoader = createSpringContextLoader();
        // **加载SpringContext配置文件**
        installSpringContext(application, springContextLoader);

        if (sofaModuleProperties.isModuleStartUpParallel()) {
            // **并行刷新SpringContext，初始化Bean**
            refreshSpringContextParallel(application);
        } else {
            // 刷新SpringContext
            refreshSpringContext(application);
        }
    }
}
```

###### 创建模块的SpringContextLoader(上下文加载器)

- SpringContextInstallStage.java

```java
protected SpringContextLoader createSpringContextLoader() {
    return new DynamicSpringContextLoader(applicationContext);
}
```

- DynamicSpringContextLoader.java解析spring配置文件，加载Bean。下文[加载SpringContext配置文件](#加载SpringContext配置文件)会调用

```java
public class DynamicSpringContextLoader implements SpringContextLoader {
    // 加载SpringContext配置文件时会调用
    @Override
    public void loadSpringContext(DeploymentDescriptor deployment,
                                  ApplicationRuntimeModel application) throws Exception {
        // rootApplicationContext 如主模块上下文
        SofaModuleProperties sofaModuleProperties = rootApplicationContext
            .getBean(SofaModuleProperties.class);

        BeanLoadCostBeanFactory beanFactory = new BeanLoadCostBeanFactory(
            sofaModuleProperties.getBeanLoadCost(), deployment.getModuleName());
        beanFactory
            .setAutowireCandidateResolver(new QualifierAnnotationAutowireCandidateResolver());
        GenericApplicationContext ctx = sofaModuleProperties.isPublishEventToParent() ? new GenericApplicationContext(
            beanFactory) : new SofaModuleApplicationContext(beanFactory);
        // 获取激活的环境类型
        String activeProfiles = sofaModuleProperties.getActiveProfiles();
        if (StringUtils.hasText(activeProfiles)) {
            String[] profiles = activeProfiles.split(SofaBootConstants.PROFILE_SEPARATOR);
            ctx.getEnvironment().setActiveProfiles(profiles);
        }
        setUpParentSpringContext(ctx, deployment, application);
        final ClassLoader moduleClassLoader = deployment.getClassLoader();
        ctx.setClassLoader(moduleClassLoader);
        CachedIntrospectionResults.acceptClassLoader(moduleClassLoader);

        // set allowBeanDefinitionOverriding
        ctx.setAllowBeanDefinitionOverriding(sofaModuleProperties.isAllowBeanDefinitionOverriding());

        ctx.getBeanFactory().setBeanClassLoader(moduleClassLoader);
        ctx.getBeanFactory().addPropertyEditorRegistrar(new PropertyEditorRegistrar() {

            public void registerCustomEditors(PropertyEditorRegistry registry) {
                registry.registerCustomEditor(Class.class, new ClassEditor(moduleClassLoader));
                registry.registerCustomEditor(Class[].class,
                    new ClassArrayEditor(moduleClassLoader));
            }
        });
        deployment.setApplicationContext(ctx);

        XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(ctx);
        beanDefinitionReader.setValidating(true);
        beanDefinitionReader.setNamespaceAware(true);
        beanDefinitionReader
            .setBeanClassLoader(deployment.getApplicationContext().getClassLoader());
        beanDefinitionReader.setResourceLoader(ctx);
        // 加载配置文件中定义的Bean
        loadBeanDefinitions(deployment, beanDefinitionReader);
        addPostProcessors(beanFactory);
    }
}
```

###### 加载SpringContext配置文件

- SpringContextInstallStage.java

```java
// 加载SpringContext配置文件
protected void installSpringContext(ApplicationRuntimeModel application,
                                    SpringContextLoader springContextLoader) {
    ClassLoader oldClassLoader = Thread.currentThread().getContextClassLoader();
    // 循环处理依赖的模块：sofa-module.properties
    for (DeploymentDescriptor deployment : application.getResolvedDeployments()) {
        // 判断是否有Spring配置文件
        if (deployment.isSpringPowered()) {
            // Start install SqBiz Main's module: cn.aezo.sqbiz.sqbiz-plugin.service-provider
            SofaLogger.info("Start install " + application.getAppName() + "'s module: "
                            + deployment.getName());
            try {
                // 记录加载器，如：BizClassLoader(bizIdentity=Startup In IDE:Mock version)
                Thread.currentThread().setContextClassLoader(deployment.getClassLoader());
                // 参考上文[创建模块的SpringContextLoader(上下文加载器)](#创建模块的SpringContextLoader(上下文加载器))
                springContextLoader.loadSpringContext(deployment, application);
            } catch (Throwable t) {
                SofaLogger.error("Install module {} got an error!", deployment.getName(), t);
                application.addFailed(deployment);
            } finally {
                Thread.currentThread().setContextClassLoader(oldClassLoader);
            }
        }
    }
}
```
- AbstractDeploymentDescriptor.java

```java
public abstract class AbstractDeploymentDescriptor implements DeploymentDescriptor {
    // Spring配置文件
    Map<String, Resource>                   springResources;

    @Override
    public boolean isSpringPowered() {
        // 配置文件不存在则先读取XML文件
        if (springResources == null) {
            this.loadSpringXMLs();
        }
        // 如果存在配置文件，则说明存在Spring上下文环境，之后可进行刷新SpringContext
        return !springResources.isEmpty();
    }
}
```
- FileDeploymentDescriptor.java 基于文件安装的模块，另外一个实现是基于Jar(JarDeploymentDescriptor)

```java
public class FileDeploymentDescriptor extends AbstractDeploymentDescriptor {
    @Override
    public void loadSpringXMLs() {
        springResources = new HashMap<>();

        try {
            // When path contains special characters (e.g., white space, Chinese), URL converts them to UTF8 code point.
            // In order to processing correctly, create File from URI
            // Spring配置文件目录, 如: C:\Users\smalle\Desktop\sofa-ark-dynamic-guides-master\ark-dynamic-module\target\classes\META-INF\spring
            URI springXmlUri = new URI("file://"
                                       + url.getFile().substring(
                                           0,
                                           url.getFile().length()
                                                   - SofaBootConstants.SOFA_MODULE_FILE.length())
                                       + SofaBootConstants.SPRING_CONTEXT_PATH); // META-INF/spring
            File springXml = new File(springXmlUri);
            List<File> springFiles = new ArrayList<>();
            if (springXml.exists()) {
                listFiles(springFiles, springXml, ".xml");
            }

            for (File f : springFiles) {
                // 保存到 springResources 缓存中
                springResources.put(f.getAbsolutePath(), new FileSystemResource(f));
            }
        } catch (Throwable e) {
            throw new RuntimeException(e);
        }
    }
}
```

###### 并行刷新SpringContext

- SpringContextInstallStage.java

```java
private void refreshSpringContextParallel(ApplicationRuntimeModel application) {
    ClassLoader oldClassLoader = Thread.currentThread().getContextClassLoader();
    List<DeploymentDescriptor> coreRoots = new ArrayList<>();
    // 定义线程执行器，初始化模块时的线程名如：sofa-module-start-cn.aezo.sqbiz.sqbiz-plugin.service-provider
    ThreadPoolExecutor executor = new SofaThreadPoolExecutor(CPU_COUNT + 1, CPU_COUNT + 1, 60,
        TimeUnit.MILLISECONDS, new SynchronousQueue<Runnable>(), new NamedThreadFactory(
            "sofa-module-start"), new ThreadPoolExecutor.CallerRunsPolicy(),
        "sofa-module-start", "sofa-boot", 60, 30, TimeUnit.SECONDS);
    try {
        // 循环处理依赖的模块：sofa-module.properties
        for (DeploymentDescriptor deployment : application.getResolvedDeployments()) {
            DependencyTree.Entry entry = application.getDeployRegistry().getEntry(
                deployment.getModuleName());
            // 判断当前模块是否有依赖, Require-Module
            if (entry != null && entry.getDependencies() == null) {
                coreRoots.add(deployment);
            }
        }
        // 处理底层(被依赖)模块，内部包含了处理上层调用模块，具体见下文
        refreshSpringContextParallel(coreRoots, application.getResolvedDeployments().size(),
            application, executor);

    } finally {
        executor.shutdown();
        Thread.currentThread().setContextClassLoader(oldClassLoader);
    }
}

private void refreshSpringContextParallel(List<DeploymentDescriptor> rootDeployments,
                                              int totalSize,
                                              final ApplicationRuntimeModel application,
                                              final ThreadPoolExecutor executor) {
    if (rootDeployments == null || rootDeployments.size() == 0) {
        return;
    }

    final CountDownLatch latch = new CountDownLatch(totalSize);
    List<Future> futures = new CopyOnWriteArrayList<>();

    // 依次处理每个模块
    for (final DeploymentDescriptor deployment : rootDeployments) {
        refreshSpringContextParallel(deployment, application, executor, latch, futures);
    }

    try {
        latch.await();
    } catch (InterruptedException e) {
        throw new RuntimeException("Wait for Sofa Module Refresh Fail", e);
    }

    for (Future future : futures) {
        try {
            future.get();
        } catch (Throwable e) {
            throw new RuntimeException(e);
        }
    }

}

// 某个模块处理逻辑
private void refreshSpringContextParallel(final DeploymentDescriptor deployment,
                                              final ApplicationRuntimeModel application,
                                              final ThreadPoolExecutor executor,
                                              final CountDownLatch latch, final List<Future> futures) {
    // 提交任务
    futures.add(executor.submit(new Runnable() {
        @Override
        public void run() {
            // 任务逻辑
            String oldName = Thread.currentThread().getName();
            try {
                Thread.currentThread().setName(
                    "sofa-module-start-" + deployment.getModuleName());
                Thread.currentThread().setContextClassLoader(deployment.getClassLoader());
                if (deployment.isSpringPowered()
                    && !application.getFailed().contains(deployment)) {
                    // 是Spring应用，且加载成功时执行
                    doRefreshSpringContext(deployment, application);
                }
                // 当前模块
                DependencyTree.Entry<String, DeploymentDescriptor> entry = application
                    .getDeployRegistry().getEntry(deployment.getModuleName());
                if (entry != null && entry.getDependsOnMe() != null) {
                    // 循环初始化依赖我的模块(初始化上层调用模块)
                    for (final DependencyTree.Entry<String, DeploymentDescriptor> child : entry
                        .getDependsOnMe()) {
                        child.getDependencies().remove(entry);
                        if (child.getDependencies().size() == 0) {
                            refreshSpringContextParallel(child.get(), application, executor,
                                latch, futures);
                        }
                    }
                }
            }
            // ...
        }
    }));
}

protected void doRefreshSpringContext(DeploymentDescriptor deployment,
                                          ApplicationRuntimeModel application) {
    // Begin refresh Spring Application Context of module cn.aezo.sqbiz.sqbiz-plugin.service-provider of application SqBiz Main.
    SofaLogger.info("Begin refresh Spring Application Context of module {} of application {}.",
        deployment.getName(), application.getAppName());
    // 获取模块的上下文
    ConfigurableApplicationContext ctx = (ConfigurableApplicationContext) deployment
        .getApplicationContext();
    if (ctx != null) {
        try {
            deployment.startDeploy(); // 只是记录一下时间
            // 刷新，即调用 ApplicationContext#refresh 方法。参考上文[ServiceComponent为例](#ServiceComponent为例)
            // 依次打印日志：Registering component - <<PreOut Binding - <<Out Binding - Register Service
            ctx.refresh();
            // 注册SpringContext组件，参考上文[SpringContextComponent为例](#SpringContextComponent为例)。方法详细参考下文
            publishContextAsSofaComponent(deployment, application, ctx);
            application.addInstalled(deployment);
        } catch (Throwable t) {
            SofaLogger.error(
                "Refreshing Spring Application Context of module {} got an error.",
                deployment.getName(), t);
            application.addFailed(deployment);
        } finally {
            deployment.deployFinish();
        }
    } else {
        String errorMsg = "Spring Application Context of module " + deployment.getName()
                            + " is null!";
        application.addFailed(deployment);
        SofaLogger.error(errorMsg, new RuntimeException(errorMsg));
    }
}

private void publishContextAsSofaComponent(DeploymentDescriptor deployment,
                                               ApplicationRuntimeModel application,
                                               ApplicationContext context) {
    // 实例化
    ComponentName componentName = ComponentNameFactory.createComponentName(
        SpringContextComponent.SPRING_COMPONENT_TYPE, deployment.getModuleName());
    Implementation implementation = new SpringContextImplementation(context);
    ComponentInfo componentInfo = new SpringContextComponent(componentName, implementation,
        application.getSofaRuntimeContext());
    // 注册
    application.getSofaRuntimeContext().getComponentManager().register(componentInfo);
}
```

## runtime-sofa-boot

- runtime-sofa-boot-starter-3.1.4.jar

### 初始化

- **基于SofaBoot的简单模块隔离，或者基于多Ark Biz启动，都会用到此包**
- 主要是管理组件(Component, 本质是Bean/服务. 包括ReferenceComponent,ServiceComponent,SpringContextComponent)生命周期
- 组件管理类ComponentManagerImpl
    - register/registerAndGet 注册组件
        - 服务端Biz, 其Spring初始化时调用，如：ServiceFactoryBean(通过扫描含@SofaReference注解的Bean)、ExtensionFactoryBean
        - 服务端基于API初始化时调用：ServiceClientImpl、ExtensionClientImpl
        - 客户端Biz初始化@SofaReference应用，ReferenceRegisterHelper
            - ReferenceFactoryBean(InitializingBean)
            - ReferenceAnnotationBeanPostProcessor(BeanPostProcessor)
            - ReferenceClientImpl 客户端基于API注册引用
- Spring初始化时，会调用其 postProcessBeforeInitialization 方法
    - 如根据`@SofaReference`注解，将组件信息(此时为ReferenceComponent类)保存到ComponentManagerImpl#registry集合中，集合中的key为ComponentName类型
        - 此时ComponentName如：`reference:com.alipay.sofa.isle.sample.SampleJvmService:#2120635923`(reference表示基于此注解解析的引用信息，会创建其代理对象)
    - 如根据`@SofaService`注解，将组件信息(此时为ServiceComponent类)保存到registry集合中

#### BeanPostProcessor注册组件入口

##### ReferenceAnnotationBeanPostProcessor为例

- ReferenceAnnotationBeanPostProcessor.java

```java
public class ReferenceAnnotationBeanPostProcessor implements BeanPostProcessor, PriorityOrdered {

    // Spring初始化时，会调用其此方法
    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName)
                                                                               throws BeansException {
        processSofaReference(bean);
        return bean;
    }

    private void processSofaReference(final Object bean) {
        // 被Spring扫描的Bean
        final Class<?> beanClass = bean.getClass();

        // 遍历Bean的所有属性，并执行回调
        ReflectionUtils.doWithFields(beanClass, new ReflectionUtils.FieldCallback() {

            @Override
            @SuppressWarnings("unchecked")
            public void doWith(Field field) throws IllegalArgumentException, IllegalAccessException {
                AnnotationWrapperBuilder<SofaReference> builder = AnnotationWrapperBuilder.wrap(
                    field.getAnnotation(SofaReference.class)).withBinder(binder);
                SofaReference sofaReferenceAnnotation = builder.build();

                if (sofaReferenceAnnotation == null) {
                    return;
                }

                Class<?> interfaceType = sofaReferenceAnnotation.interfaceType();
                if (interfaceType.equals(void.class)) {
                    interfaceType = field.getType();
                }

                // 创建ReferenceComponent的代理对象，并注册，具体参考下文
                Object proxy = createReferenceProxy(sofaReferenceAnnotation, interfaceType);
                ReflectionUtils.makeAccessible(field);
                // 将代理对象设置为此属性值
                ReflectionUtils.setField(field, bean, proxy);
            }
        }, new ReflectionUtils.FieldFilter() { // 字段过滤器，符合要求的才执行回调

            @Override
            public boolean matches(Field field) {
                if (!field.isAnnotationPresent(SofaReference.class)) {
                    return false;
                }
                if (Modifier.isStatic(field.getModifiers())) {
                    SofaLogger.warn(
                        "SofaReference annotation is not supported on static fields: {}", field);
                    return false;
                }
                return true;
            }
        });

        ReflectionUtils.doWithMethods(beanClass, new ReflectionUtils.MethodCallback() {
            @Override
            @SuppressWarnings("unchecked")
            public void doWith(Method method) throws IllegalArgumentException,
                                             IllegalAccessException {
                Class[] parameterTypes = method.getParameterTypes();
                Assert.isTrue(parameterTypes.length == 1,
                    "method should have one and only one parameter.");

                SofaReference sofaReferenceAnnotation = method.getAnnotation(SofaReference.class);
                if (sofaReferenceAnnotation == null) {
                    return;
                }
                AnnotationWrapperBuilder<SofaReference> builder = AnnotationWrapperBuilder.wrap(
                    sofaReferenceAnnotation).withBinder(binder);
                sofaReferenceAnnotation = builder.build();

                Class<?> interfaceType = sofaReferenceAnnotation.interfaceType();
                if (interfaceType.equals(void.class)) {
                    interfaceType = parameterTypes[0];
                }

                Object proxy = createReferenceProxy(sofaReferenceAnnotation, interfaceType);
                ReflectionUtils.invokeMethod(method, bean, proxy);
            }
        }, new ReflectionUtils.MethodFilter() {
            @Override
            public boolean matches(Method method) {
                return method.isAnnotationPresent(SofaReference.class);
            }
        });
    }

    // 创建ReferenceComponent的代理对象，并注册
    private Object createReferenceProxy(SofaReference sofaReferenceAnnotation,
                                        Class<?> interfaceType) {
        Reference reference = new ReferenceImpl(sofaReferenceAnnotation.uniqueId(), interfaceType,
            InterfaceMode.annotation, sofaReferenceAnnotation.jvmFirst());
        BindingConverter bindingConverter = bindingConverterFactory
            .getBindingConverter(new BindingType(sofaReferenceAnnotation.binding().bindingType()));
        if (bindingConverter == null) {
            throw new ServiceRuntimeException("Can not found binding converter for binding type "
                                              + sofaReferenceAnnotation.binding().bindingType());
        }

        BindingConverterContext bindingConverterContext = new BindingConverterContext();
        bindingConverterContext.setInBinding(true);
        bindingConverterContext.setApplicationContext(applicationContext);
        bindingConverterContext.setAppName(sofaRuntimeContext.getAppName());
        bindingConverterContext.setAppClassLoader(sofaRuntimeContext.getAppClassLoader());
        Binding binding = bindingConverter.convert(sofaReferenceAnnotation,
            sofaReferenceAnnotation.binding(), bindingConverterContext);
        reference.addBinding(binding);
        // 注册组件
        return ReferenceRegisterHelper.registerReference(reference, bindingAdapterFactory,
            sofaRuntimeContext);
    }
}
```

- ReferenceRegisterHelper.java

```java
public class ReferenceRegisterHelper {
    public static Object registerReference(Reference reference,
                                           BindingAdapterFactory bindingAdapterFactory,
                                           SofaRuntimeContext sofaRuntimeContext) {
        Binding binding = (Binding) reference.getBindings().toArray()[0];

        if (!binding.getBindingType().equals(JvmBinding.JVM_BINDING_TYPE)
            && !SofaRuntimeProperties.isDisableJvmFirst(sofaRuntimeContext)
            && reference.isJvmFirst()) {
            // as rpc invocation would be serialized, so here would Not ignore serialized
            reference.addBinding(new JvmBinding());
        }

        ComponentManager componentManager = sofaRuntimeContext.getComponentManager();
        ReferenceComponent referenceComponent = new ReferenceComponent(reference,
            new DefaultImplementation(), bindingAdapterFactory, sofaRuntimeContext);

        if (componentManager.isRegistered(referenceComponent.getName())) {
            return componentManager.getComponentInfo(referenceComponent.getName())
                .getImplementation().getTarget();
        }

        // 注册组件并获取返回的组件信息，参考下文
        ComponentInfo componentInfo = componentManager.registerAndGet(referenceComponent);
        return componentInfo.getImplementation().getTarget();

    }
}
```

##### ServiceBeanFactoryPostProcessor为例

- ServiceBeanFactoryPostProcessor.java 修改(Component)Bean的定义

```java
public class ServiceBeanFactoryPostProcessor implements BeanFactoryPostProcessor {

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        Arrays.stream(beanFactory.getBeanDefinitionNames())
            .collect(Collectors.toMap(Function.identity(), beanFactory::getBeanDefinition))
            // 循环所有的bean定义配置，transformSofaBeanDefinition最终会调用到 generateSofaServiceDefinitionOnClass
            .forEach((key, value) -> transformSofaBeanDefinition(key, value, beanFactory));
    }

    private void generateSofaServiceDefinitionOnClass(String beanId, Class<?> beanClass,
                                                      BeanDefinition beanDefinition,
                                                      ConfigurableListableBeanFactory beanFactory) {
        // 获取有 SofaService 注解的类
        SofaService sofaServiceAnnotation = beanClass.getAnnotation(SofaService.class);
        generateSofaServiceDefinition(beanId, sofaServiceAnnotation, beanClass, beanDefinition,
            beanFactory);
    }

    private void generateSofaServiceDefinition(String beanId, SofaService sofaServiceAnnotation,
                                               Class<?> beanClass, BeanDefinition beanDefinition,
                                               ConfigurableListableBeanFactory beanFactory) {
        if (sofaServiceAnnotation == null) {
            return;
        }
        // 生成 SofaService 定义对象
        AnnotationWrapperBuilder<SofaService> wrapperBuilder = AnnotationWrapperBuilder.wrap(
            sofaServiceAnnotation).withBinder(binder);
        sofaServiceAnnotation = wrapperBuilder.build();

        Class<?> interfaceType = sofaServiceAnnotation.interfaceType();
        if (interfaceType.equals(void.class)) {
            Class<?> interfaces[] = beanClass.getInterfaces();

            if (beanClass.isInterface() || interfaces == null || interfaces.length == 0) {
                interfaceType = beanClass;
            } else if (interfaces.length == 1) {
                interfaceType = interfaces[0];
            } else {
                throw new FatalBeanException("Bean " + beanId + " has more than one interface.");
            }
        }

        BeanDefinitionBuilder builder = BeanDefinitionBuilder.genericBeanDefinition();
        String serviceId = SofaBeanNameGenerator.generateSofaServiceBeanName(interfaceType,
            sofaServiceAnnotation.uniqueId());

        // 在Bean实例化之前，修改Bean的定义
        if (!beanFactory.containsBeanDefinition(serviceId)) {
            builder.getRawBeanDefinition().setScope(beanDefinition.getScope());
            builder.setLazyInit(beanDefinition.isLazyInit());
            builder.getRawBeanDefinition().setBeanClass(ServiceFactoryBean.class);
            builder.addPropertyValue(AbstractContractDefinitionParser.INTERFACE_CLASS_PROPERTY,
                interfaceType);
            builder.addPropertyValue(AbstractContractDefinitionParser.UNIQUE_ID_PROPERTY,
                sofaServiceAnnotation.uniqueId());
            builder.addPropertyValue(AbstractContractDefinitionParser.BINDINGS,
                getSofaServiceBinding(sofaServiceAnnotation, sofaServiceAnnotation.bindings()));
            builder.addPropertyReference(ServiceDefinitionParser.REF, beanId);
            builder.addPropertyValue(ServiceDefinitionParser.BEAN_ID, beanId);
            builder.addPropertyValue(AbstractContractDefinitionParser.DEFINITION_BUILDING_API_TYPE,
                true);
            builder.addDependsOn(beanId);
            ((BeanDefinitionRegistry) beanFactory).registerBeanDefinition(serviceId,
                builder.getBeanDefinition());
        } else {
            SofaLogger.error("SofaService was already registered: {0}", serviceId);
        }
    }
}
```
- AbstractContractFactoryBean.java 触发Component注册

```java
public abstract class AbstractContractFactoryBean implements InitializingBean, FactoryBean,
                                                 ApplicationContextAware {
    // org.springframework.beans.factory.InitializingBean                 
    @Override
    public void afterPropertiesSet() throws Exception {
        List<Element> tempElements = new ArrayList<>();
        if (elements != null) {
            for (TypedStringValue element : elements) {
                DocumentBuilderFactory documentBuilderFactory = DocumentBuilderFactory
                    .newInstance();
                documentBuilderFactory.setNamespaceAware(true);
                InputSource inputSource = new InputSource(new ByteArrayInputStream(element
                    .getValue().getBytes()));
                inputSource.setEncoding(documentEncoding);
                Element node = documentBuilderFactory.newDocumentBuilder().parse(inputSource)
                    .getDocumentElement();
                tempElements.add(node);
            }
        }
        sofaRuntimeContext = applicationContext.getBean(
            SofaRuntimeFrameworkConstants.SOFA_RUNTIME_CONTEXT_BEAN_ID, SofaRuntimeContext.class);
        bindingConverterFactory = getBindingConverterFactory();
        bindingAdapterFactory = getBindingAdapterFactory();
        if (!apiType) {
            this.bindings = parseBindings(tempElements, applicationContext, isInBinding());
        }

        // 执行bean创建完后的操作
        doAfterPropertiesSet();
    }
}
```

- ServiceFactoryBean.java
    - 同理还有ReferenceFactoryBean

```java
public class ServiceFactoryBean extends AbstractContractFactoryBean {
    @Override
    protected void doAfterPropertiesSet() {
        if (!apiType && hasSofaServiceAnnotation()) {
            throw new ServiceRuntimeException(
                "Bean " + beanId + " of type " + ref.getClass()
                        + " has already annotated by @SofaService,"
                        + " can not be registered using xml. Please check it.");
        }

        Implementation implementation = new DefaultImplementation();
        implementation.setTarget(ref);
        service = buildService();

        // default add jvm binding and service jvm binding should set serialize as true
        if (bindings.size() == 0) {
            JvmBinding jvmBinding = new JvmBinding();
            JvmBindingParam jvmBindingParam = new JvmBindingParam().setSerialize(true);
            bindings.add(new JvmBinding().setJvmBindingParam(jvmBindingParam));
        }

        for (Binding binding : bindings) {
            service.addBinding(binding);
        }

        ComponentInfo componentInfo = new ServiceComponent(implementation, service,
            bindingAdapterFactory, sofaRuntimeContext);
        // 注册Component，参考下文 ComponentManagerImpl
        sofaRuntimeContext.getComponentManager().register(componentInfo);
    }
}
```

#### 组件即其生命周期

- Component接口，组件级别，可以理解为一个服务类相关信息
    - 方法：register、unregister、resolve、unresolve、activate、deactivate、exception
    - 子接口：ComponentInfo，主要需要提供getType、getName等功能
    - 抽象类：AbstractComponent，主要是实现 ComponentInfo，减少代码量
    - 对应实现如：SpringContextComponent(类型为Spring)、ServiceComponent(类型为service)、ReferenceComponent(类型为reference)

```java
/**
 * SOFA Component Lifecycle:
 * <pre>
 *                  [UNREGISTERED]
 *                      |   ▲
 *           register   │   │   unregister
 *                      |   |
 *                   [REGISTERED]
 *                      |   ▲
 *           resolve    │   │   unresolve
 *                      |   |
 *                    [RESOLVED]
 *                      |   ▲
 *                 ┌────┘   └────┐
 *                 │             │
 *        activate |             ▲ deactivate
 *                 │             │
 *                 └───┐    ┌────┘
 *                          |
 *                   [ACTIVATED]
 * </pre>
 */
public interface Component {
    // ...
}
```
- `ComponentManagerImpl` 组件管理者(基于组件类维度)

```java
public class ComponentManagerImpl implements ComponentManager {
    protected ConcurrentMap<ComponentName, ComponentInfo> registry;
    protected ConcurrentMap<ComponentType, Map<ComponentName, ComponentInfo>> resolvedRegistry;

    // 注册组件
    public ComponentInfo registerAndGet(ComponentInfo componentInfo) {
        return doRegister(componentInfo);
    }

    // 执行组件注册
    private ComponentInfo doRegister(ComponentInfo ci) {
        ComponentName name = ci.getName();
        if (isRegistered(name)) {
            SofaLogger.error("Component was already registered: {}", name);
            if (ci.canBeDuplicate()) {
                return getComponentInfo(name);
            }
            throw new ServiceRuntimeException("Component can not be registered duplicated: " + name);
        }

        try {
            // 设置 componentStatus = ComponentStatus.REGISTERED 为已注册
            ci.register();
        } catch (Throwable t) {
            SofaLogger.error("Failed to register component: {}", ci.getName(), t);
            return null;
        }

        // Registering component: reference:com.alipay.sofa.isle.sample.SampleJvmService:#2120635923
        // Registering component: service:com.alipay.sofa.isle.sample.SampleJvmService
        // Registering component: Spring:cn.aezo.sqbiz.sqbiz-plugin.service-provider
        SofaLogger.info("Registering component: {}", ci.getName());

        try {
            // 将组件缓存到 registry 集合中
            ComponentInfo old = registry.putIfAbsent(ci.getName(), ci);
            if (old != null) {
                SofaLogger.error("Component was already registered: {}", name);
                if (ci.canBeDuplicate()) {
                    return old;
                }
                throw new ServiceRuntimeException("Component can not be registered duplicated: "
                                                  + name);

            }
            if (ci.resolve()) { // 设置 componentStatus = ComponentStatus.RESOLVED 为已归纳
                // 按照 ComponentType 类型进行归纳，包含：service/reference/Spring等
                typeRegistry(ci);
                // **执行激活组件方法，参考下文**
                ci.activate();
            }
        } catch (Throwable t) {
            ci.exception(new Exception(t));
            SofaLogger.error("Failed to create the component {}", ci.getName(), t);
        }

        return ci;
    }

    // 卸载
    public void unregister(ComponentInfo componentInfo) throws ServiceRuntimeException {
        ComponentName componentName = componentInfo.getName();
        registry.remove(componentName);

        if (componentName != null) {
            ComponentType componentType = componentName.getType();

            Map<ComponentName, ComponentInfo> typesRi = resolvedRegistry.get(componentType);
            typesRi.remove(componentName);
        }

        componentInfo.unregister();
    }

    // 基于类型归纳组件信息
    private void typeRegistry(ComponentInfo componentInfo) {
        ComponentName name = componentInfo.getName();
        if (name != null) {
            ComponentType type = name.getType();
            Map<ComponentName, ComponentInfo> typesRi = resolvedRegistry.get(type);

            if (typesRi == null) {
                resolvedRegistry.putIfAbsent(type, new HashMap<ComponentName, ComponentInfo>());
                typesRi = resolvedRegistry.get(type);
            }

            typesRi.put(name, componentInfo);
        }
    }
}
```

#### 激活组件

##### ReferenceComponent为例

```java
public class ReferenceComponent extends AbstractComponent {

    @Override
    public void activate() throws ServiceRuntimeException {
        // 是否存在Binding，如：JvmBinding
        if (reference.hasBinding()) {
            Binding candidate = null;
            Set<Binding> bindings = reference.getBindings();
            if (bindings.size() == 1) {
                candidate = bindings.iterator().next();
            } else if (bindings.size() > 1) {
                Object backupProxy = null;
                for (Binding binding : bindings) {
                    if (JvmBinding.JVM_BINDING_TYPE.getType().equals(binding.getName())) {
                        candidate = binding;
                    } else {
                        // Under normal RPC reference (local-first/jvm-first is not set to false) binding,
                        // backup proxy is the RPC proxy, which will be invoked if Jvm service is not found
                        backupProxy = createProxy(reference, binding);
                    }
                }
                if (candidate != null) {
                    ((JvmBinding) candidate).setBackupProxy(backupProxy);
                }
            }

            Object proxy = null;
            if (candidate != null) {
                // 基于选择的Binding创建代理
                proxy = createProxy(reference, candidate);
            }
            
            // 实例化一个默认实现(类似一个包装类，最终是通过proxy调用)
            this.implementation = new DefaultImplementation();
            implementation.setTarget(proxy);
        }

        // componentStatus = ComponentStatus.ACTIVATED;
        super.activate();
        latch.countDown();
    }

    private Object createProxy(Reference reference, Binding binding) {
        // JvmBindingAdapter
        BindingAdapter<Binding> bindingAdapter = bindingAdapterFactory.getBindingAdapter(binding
            .getBindingType());
        if (bindingAdapter == null) {
            throw new ServiceRuntimeException("Can't find BindingAdapter of type "
                                              + binding.getBindingType() + " for reference "
                                              + reference + ".");
        }
        // >>In Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService.
        SofaLogger.info(" >>In Binding [{}] Begins - {}.", binding.getBindingType(), reference);
        Object proxy;
        try {
            // 获取代理对象，参考下文
            proxy = bindingAdapter.inBinding(reference, binding, sofaRuntimeContext);
        } finally {
            // >>In Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService.
            SofaLogger.info(" >>In Binding [{}] Ends - {}.", binding.getBindingType(), reference);
        }
        return proxy;
    }

    // 检查当前组件的状态，在Biz启动完成后执行健康检查，Biz下所有组件检查通过则将Biz标记为actived
    @Override
    public HealthResult isHealthy() {
        if (!isActivated()) {
            return super.isHealthy();
        }

        HealthResult result = new HealthResult(componentName.getRawName());
        List<HealthResult> bindingHealth = new ArrayList<>();

        JvmBinding jvmBinding = null;
        HealthResult jvmBindingHealthResult = null;
        if (reference.hasBinding()) {
            for (Binding binding : reference.getBindings()) {
                bindingHealth.add(binding.healthCheck());
                if (JvmBinding.JVM_BINDING_TYPE.equals(binding.getBindingType())) {
                    jvmBinding = (JvmBinding) binding;
                    jvmBindingHealthResult = bindingHealth.get(bindingHealth.size() - 1);
                }
            }
        }

        // check reference has a corresponding service
        // 可通过 com.alipay.sofa.boot.skipJvmReferenceHealthCheck=true 设置为不检查组件的健康状态（如有些组件实现是通过ark动态安装进来的，就会出现Biz启动不成功的问题）
        if (!SofaRuntimeProperties.isSkipJvmReferenceHealthCheck(sofaRuntimeContext)
            && jvmBinding != null) {
            Object serviceTarget = getServiceTarget();
            if (serviceTarget == null && !jvmBinding.hasBackupProxy()) {
                jvmBindingHealthResult.setHealthy(false);
                jvmBindingHealthResult.setHealthReport("can not find corresponding jvm service");
            }
        }

        List<HealthResult> failedBindingHealth = new ArrayList<>();

        for (HealthResult healthResult : bindingHealth) {
            if (healthResult != null && !healthResult.isHealthy()) {
                failedBindingHealth.add(healthResult);
            }
        }

        if (failedBindingHealth.size() == 0) {
            result.setHealthy(true);
        } else {
            StringBuilder healthReport = new StringBuilder("|");
            for (HealthResult healthResult : failedBindingHealth) {
                healthReport.append(healthResult.getHealthName()).append("#")
                    .append(healthResult.getHealthReport());
            }
            result.setHealthReport(healthReport.substring(1, healthReport.length()));
            result.setHealthy(false);
        }

        return result;
    }
}
```
- JvmBindingAdapter.java

```java
public class JvmBindingAdapter implements BindingAdapter<JvmBinding> {

    // 实现 BindingAdapter 接口方法
    public Object inBinding(Object contract, JvmBinding binding,
                            SofaRuntimeContext sofaRuntimeContext) {
        return createServiceProxy((Contract) contract, binding, sofaRuntimeContext);
    }

    private Object createServiceProxy(Contract contract, JvmBinding binding,
                                      SofaRuntimeContext sofaRuntimeContext) {
        ClassLoader newClassLoader;
        // 获取加载器，如：BizClassLoader(bizIdentity=Startup In IDE:Mock version)
        ClassLoader appClassLoader = sofaRuntimeContext.getAppClassLoader();
        Class<?> javaClass = contract.getInterfaceType();

        try {
            Class appLoadedClass = appClassLoader.loadClass(javaClass.getName());

            if (appLoadedClass == javaClass) {
                newClassLoader = appClassLoader;
            } else {
                newClassLoader = javaClass.getClassLoader();
            }
        } catch (ClassNotFoundException e) {
            newClassLoader = javaClass.getClassLoader();
        }

        ClassLoader oldClassLoader = Thread.currentThread().getContextClassLoader();

        try {
            Thread.currentThread().setContextClassLoader(newClassLoader);
            // 实例化 JvmServiceInvoker，通过此对象调用服务
            ServiceProxy handler = new JvmServiceInvoker(contract, binding, sofaRuntimeContext);
            ProxyFactory factory = new ProxyFactory();
            if (javaClass.isInterface()) {
                factory.addInterface(javaClass);
            } else {
                factory.setTargetClass(javaClass);
                factory.setProxyTargetClass(true);
            }
            factory.addAdvice(handler);
            // 返回代理对象
            return factory.getProxy(newClassLoader);
        } finally {
            Thread.currentThread().setContextClassLoader(oldClassLoader);
        }
    }

    // ***执行组件服务调用，即找到对应的 @SofaService 声明的服务***
    static class JvmServiceInvoker extends ServiceProxy {
        @Override
        public Object invoke(MethodInvocation invocation) throws Throwable {
            if (!SofaRuntimeProperties.isJvmFilterEnable()) {
                // Jvm filtering is not enabled
                return super.invoke(invocation);
            }

            ClassLoader oldClassLoader = Thread.currentThread().getContextClassLoader();
            JvmFilterContext context = new JvmFilterContext(invocation);
            Object rtn;

            if (getTarget() == null) {
                // 获取目标服务（实现类）
                ServiceComponent serviceComponent = DynamicJvmServiceProxyFinder
                    .getDynamicJvmServiceProxyFinder().findServiceComponent(
                        sofaRuntimeContext.getAppClassLoader(), contract);
                if (serviceComponent == null) {
                    // Jvm service is not found in normal or Ark environment
                    // We're actually invoking an RPC service, skip Jvm filtering
                    return super.invoke(invocation);
                }
                context.setSofaRuntimeContext(serviceComponent.getContext());
            } else {
                context.setSofaRuntimeContext(sofaRuntimeContext);
            }

            long startTime = System.currentTimeMillis();
            try {
                Thread.currentThread().setContextClassLoader(serviceClassLoader);
                // Do Jvm filter <code>before</code> invoking
                // if some filter returns false, skip remaining filters and actual Jvm invoking
                if (JvmFilterHolder.beforeInvoking(context)) {
                    rtn = doInvoke(invocation);
                    context.setInvokeResult(rtn);
                }
            } catch (Throwable e) {
                // Exception occurs, set <code>e</code> in Jvm context
                context.setException(e);
                doCatch(invocation, e, startTime);
                throw e;
            } finally {
                // Do Jvm Filter <code>after</code> invoking regardless of the fact whether exception happens or not
                JvmFilterHolder.afterInvoking(context);
                rtn = context.getInvokeResult();
                doFinally(invocation, startTime);
                Thread.currentThread().setContextClassLoader(oldClassLoader);
            }
            return rtn;
        }

        @Override
        public Object doInvoke(MethodInvocation invocation) throws Throwable {
            if (binding.isDestroyed()) {
                throw new IllegalStateException("Can not call destroyed reference! JVM Reference["
                                                + getInterfaceName() + "#" + getUniqueId()
                                                + "] has already been destroyed.");
            }

            SofaLogger.debug(">> Start in JVM service invoke, the service interface is  - {}",
                getInterfaceName());

            Object retVal;
            Object targetObj = this.getTarget();

            // invoke internal dynamic-biz jvm service
            if (targetObj == null) {
                ServiceProxy serviceProxy = DynamicJvmServiceProxyFinder
                    .getDynamicJvmServiceProxyFinder().findServiceProxy(
                        sofaRuntimeContext.getAppClassLoader(), contract);
                if (serviceProxy != null) {
                    try {
                        return serviceProxy.invoke(invocation);
                    } finally {
                        SofaLogger.debug(
                            "<< Finish Cross App JVM service invoke, the service is  - {}]",
                            (getInterfaceName() + "#" + getUniqueId()));
                    }
                }
            }

            if (targetObj == null || ((targetObj instanceof Proxy) && binding.hasBackupProxy())) {
                targetObj = binding.getBackupProxy();
                SofaLogger.debug("<<{}.{} backup proxy invoke.", getInterfaceName().getName(),
                    invocation.getMethod().getName());
            }

            if (targetObj == null) {
                throw new IllegalStateException(
                    "JVM Reference["
                            + getInterfaceName()
                            + "#"
                            + getUniqueId()
                            + "] can not find the corresponding JVM service. "
                            + "Please check if there is a SOFA deployment publish the corresponding JVM service. "
                            + "If this exception occurred when the application starts up, please add Require-Module to SOFA deployment's MANIFEST.MF to indicate the startup dependency of SOFA modules.");
            }

            ClassLoader tcl = Thread.currentThread().getContextClassLoader();
            try {
                pushThreadContextClassLoader(sofaRuntimeContext.getAppClassLoader());
                retVal = invocation.getMethod().invoke(targetObj, invocation.getArguments());
            } catch (InvocationTargetException ex) {
                throw ex.getTargetException();
            } finally {
                SofaLogger.debug(
                    "<< Finish JVM service invoke, the service implementation is  - {}]",
                    (this.target == null ? "null" : this.target.getClass().getName()));

                popThreadContextClassLoader(tcl);
            }

            return retVal;
        }
    }
}
```

##### ServiceComponent为例

- 初始化模块的时候会调用，参考下文[并行刷新SpringContext](#并行刷新SpringContext)

```java
public class ServiceComponent extends AbstractComponent {
    // ...

    @Override
    public boolean resolve() {
        resolveBinding();
        return super.resolve();
    }

    private void resolveBinding() {
        Object target = service.getTarget();

        if (target == null) {
            throw new ServiceRuntimeException(
                "Must contains the target object whiling registering Service.");
        }

        if (service.hasBinding()) {
            Set<Binding> bindings = service.getBindings();
            boolean allPassed = true;
            for (Binding binding : bindings) {
                BindingAdapter<Binding> bindingAdapter = this.bindingAdapterFactory
                    .getBindingAdapter(binding.getBindingType());

                if (bindingAdapter == null) {
                    throw new ServiceRuntimeException("Can't find BindingAdapter of type "
                                                      + binding.getBindingType()
                                                      + " while registering service " + service
                                                      + ".");
                }

                // <<PreOut Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService.
                SofaLogger.info(" <<PreOut Binding [{}] Begins - {}.", binding.getBindingType(),
                    service);
                try {
                    bindingAdapter.preOutBinding(service, binding, target, getContext());
                } catch (Throwable t) {
                    allPassed = false;
                    SofaLogger.error(" <<PreOut Binding [{}] for [{}] occur exception.",
                        binding.getBindingType(), service, t);
                    continue;
                }
                // <<PreOut Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService.
                SofaLogger.info(" <<PreOut Binding [{}] Ends - {}.", binding.getBindingType(),
                    service);
            }

            if (!allPassed) {
                throw new ServiceRuntimeException(" <<PreOut Binding [" + service
                                                  + "] occur exception.");
            }
        }
    }

    @Override
    public void activate() throws ServiceRuntimeException {
        activateBinding();
        super.activate();
    }

    private void activateBinding() {

        Object target = service.getTarget();

        if (target == null) {
            throw new ServiceRuntimeException(
                "Must contains the target object whiling registering Service.");
        }

        if (service.hasBinding()) {
            boolean allPassed = true;
            Set<Binding> bindings = service.getBindings();
            for (Binding binding : bindings) {
                BindingAdapter<Binding> bindingAdapter = this.bindingAdapterFactory
                    .getBindingAdapter(binding.getBindingType());

                if (bindingAdapter == null) {
                    throw new ServiceRuntimeException("Can't find BindingAdapter of type "
                                                      + binding.getBindingType()
                                                      + " while registering service " + service
                                                      + ".");
                }

                Object outBindingResult;
                // <<Out Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService.
                SofaLogger.info(" <<Out Binding [{}] Begins - {}.", binding.getBindingType(),
                    service);
                try {
                    outBindingResult = bindingAdapter.outBinding(service, binding, target,
                        getContext());
                } catch (Throwable t) {
                    allPassed = false;
                    binding.setHealthy(false);
                    SofaLogger.error(" <<Out binding [{}] for [{}] occur exception.",
                        binding.getBindingType(), service, t);
                    continue;
                }
                if (!Boolean.FALSE.equals(outBindingResult)) {
                    // <<Out Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService.
                    SofaLogger.info(" <<Out Binding [{}] Ends - {}.", binding.getBindingType(),
                        service);
                } else {
                    binding.setHealthy(false);
                    SofaLogger.info(" <<Out Binding [{}] Fails, Don't publish service - {}.",
                        binding.getBindingType(), service);
                }
            }

            if (!allPassed) {
                throw new ServiceRuntimeException(" <<Out Binding [" + service
                                                  + "] occur exception.");
            }
        }

        // Register Service - com.alipay.sofa.isle.sample.SampleJvmService
        SofaLogger.info("Register Service - {}", service);
    }
}
```

##### SpringContextComponent为例

- sofa v3.6.0才有
- 初始化模块的时候会调用，参考下文[并行刷新SpringContext](#并行刷新SpringContext)

```java
public class SpringContextComponent extends AbstractComponent {
    // 可知，只是改了状态，没做过多操作
    @Override
    public void activate() throws ServiceRuntimeException {
        if (componentStatus != ComponentStatus.RESOLVED) {
            return;
        }

        componentStatus = ComponentStatus.ACTIVATED;
    }
}
```

### 扩展点初始化

- 入口

```java
// AbstractExtFactoryBean => CommonContextBean -> InitializingBean
public class ExtensionPointFactoryBean extends AbstractExtFactoryBean {

    // Spring会调用
    public void afterPropertiesSet() throws Exception {
        // ...

        // targetBeanName: 扩展点所作用在的 bean 的名字
        // determine serviceClass (can still be null if using a FactoryBean
        // which doesn't declare its product type)
        Class<?> extensionPointClass = (target != null ? target.getClass() : beanFactory
            .getType(targetBeanName));

        // ...

        try {
            // 1.发布扩展点
            publishAsNuxeoExtensionPoint(extensionPointClass);
        } catch (Exception e) {
            SofaLogger.error(e, "Failed to publish extension point.");
            throw e;
        }
    }

    // 1.
    private void publishAsNuxeoExtensionPoint(Class<?> beanClass) throws Exception {
        Assert.notNull(beanClass, "Service must be implement!");

        ExtensionPointBuilder extensionPointBuilder = ExtensionPointBuilder.genericExtensionPoint(
            this.name, applicationContext.getClassLoader());

        // ...

        Implementation implementation = new SpringImplementationImpl(targetBeanName,
            applicationContext);
        ComponentInfo extensionPointComponent = new ExtensionPointComponent(
            extensionPointBuilder.getExtensionPoint(), sofaRuntimeContext, implementation);
        // 2.注册扩展到，参考 ComponentManagerImpl (类似SofaReference等注册)
        sofaRuntimeContext.getComponentManager().register(extensionPointComponent);
    }
}
```

## sofa-boot-autoconfigure

- spring.factories

```java
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  com.alipay.sofa.boot.autoconfigure.runtime.SofaRuntimeAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.isle.SofaModuleAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.rpc.SofaRpcAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.tracer.OpenTracingSpringMvcAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.tracer.SofaTracerAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.tracer.SofaTracerDataSourceAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.tracer.SofaTracerFeignClientAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.tracer.ZipkinSofaTracerAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.tracer.SofaTracerRestTemplateAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.tracer.TracerAnnotationAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.startup.SofaStartupAutoConfiguration,\
  com.alipay.sofa.boot.autoconfigure.startup.SofaStartupIsleAutoConfiguration
```

- SofaModuleAutoConfiguration.java

```java
@Configuration
@EnableConfigurationProperties(SofaModuleProperties.class)
@ConditionalOnClass(ApplicationRuntimeModel.class)
@ConditionalOnProperty(value = "com.alipay.sofa.boot.enable-isle", matchIfMissing = true)
public class SofaModuleAutoConfiguration {
    // ...

    // 参考上文[Spring启动完成后广播事件](#Spring启动完成后广播事件)
    @Bean
    @ConditionalOnMissingBean
    public SofaModuleContextRefreshedListener sofaModuleContextRefreshedListener() {
        return new SofaModuleContextRefreshedListener();
    }

    @Bean
    @ConditionalOnMissingBean
    public ModelCreatingStage modelCreatingStage(ApplicationContext applicationContext) {
        return new ModelCreatingStage((AbstractApplicationContext) applicationContext);
    }

    // 参考上文[SpringContextInstallStage为例](#SpringContextInstallStage为例)
    @Bean
    @ConditionalOnMissingBean
    public SpringContextInstallStage springContextInstallStage(ApplicationContext applicationContext) {
        return new SpringContextInstallStage((AbstractApplicationContext) applicationContext);
    }

    @Bean
    @ConditionalOnMissingBean
    public ModuleLogOutputStage moduleLogOutputStage(ApplicationContext applicationContext) {
        return new ModuleLogOutputStage((AbstractApplicationContext) applicationContext);
    }

    // 实例化DefaultPipelineContext，参考上文[处理pipeline流水线](#处理pipeline流水线)
    @Bean
    @ConditionalOnMissingBean
    public PipelineContext pipelineContext() {
        return new DefaultPipelineContext();
    }

    // ...
}
```

## Ark容器启动流程

- 参考：https://www.sofastack.tech/projects/sofa-boot/sofa-ark-startup/
- 流程图

    ![sofa-ark.png](/data/images/java/sofa-ark.png)
- SofaArk相关常量参考`com.alipay.sofa.ark.spi.constant.Constants`

### sofa-ark-support-starter

- 启动Ark入口
- ArkApplicationStartListener.java 监听类

```java
// spring.factories声明此类
// org.springframework.context.ApplicationListener=com.alipay.sofa.ark.springboot.listener.ArkApplicationStartListener
public class ArkApplicationStartListener implements ApplicationListener<SpringApplicationEvent> {
    // ...

    @Override
    public void onApplicationEvent(SpringApplicationEvent event) {
        try {
            // springboot 2.x 启动
            if (isSpringBoot2()
                && APPLICATION_STARTING_EVENT.equals(event.getClass().getCanonicalName())) {
                startUpArk(event);
            }

            if (isSpringBoot1()
                && APPLICATION_STARTED_EVENT.equals(event.getClass().getCanonicalName())) {
                startUpArk(event);
            }
        } catch (Throwable e) {
            throw new RuntimeException("Meet exception when determine whether to start SOFAArk!", e);
        }
    }

    public void startUpArk(SpringApplicationEvent event) {
        if (LAUNCH_CLASSLOADER_NAME.equals(this.getClass().getClassLoader().getClass().getName())) {
            // 执行 SofaArkBootstrap 启动
            SofaArkBootstrap.launch(event.getArgs());
        }
    }
}
```
- SofaArkBootstrap.java

```java
public class SofaArkBootstrap {
    private static final String BIZ_CLASSLOADER = "com.alipay.sofa.ark.container.service.classloader.BizClassLoader";
    private static final String MAIN_ENTRY_NAME = "remain";
    private static EntryMethod  entryMethod;

    public static void launch(String[] args) {
        try {
            if (!isSofaArkStarted()) {
                entryMethod = new EntryMethod(Thread.currentThread());
                IsolatedThreadGroup threadGroup = new IsolatedThreadGroup(
                    entryMethod.getDeclaringClassName());
                // 下面launchThread线程会执行的任务
                // 传入参数：类名、方法名、参数。最终LaunchRunner#run中反射调用此方法(MAIN_ENTRY_NAME=remain)，即此类下文方法
                LaunchRunner launchRunner = new LaunchRunner(SofaArkBootstrap.class.getName(),
                    MAIN_ENTRY_NAME, args);
                Thread launchThread = new Thread(threadGroup, launchRunner,
                    entryMethod.getMethodName());
                launchThread.start();
                // 等threadGroup执行完成时(执行launchThread的线程)，程序启动后阻塞在此处
                LaunchRunner.join(threadGroup);
                threadGroup.rethrowUncaughtException();
                System.exit(0);
            }
        } catch (Throwable e) {
            throw new RuntimeException(e);
        }
    }

    // LaunchRunner#run最终反射调用此方法
    private static void remain(String[] args) throws Exception {// NOPMD
        AssertUtils.assertNotNull(entryMethod, "No Entry Method Found.");
        URL[] urls = getURLClassPath();
        // 执行 ClasspathLauncher#launch。传入参数 ClassPathArchive 记录了
            // urls：classpath下依赖的jar
            // arkConfBaseDir: 配置conf/ark/bootstrap.properties文件路径
        // 最终反射调用ArkContainer入口：ArkContainer.main 方法，见[sofa-ark-container](#sofa-ark-container)
        new ClasspathLauncher(new ClassPathArchive(entryMethod.getDeclaringClassName(), entryMethod.getMethodName(), urls))
            .launch(args, getClasspath(urls), entryMethod.getMethod());
    }
}
```

### sofa-ark-container

#### ArkContainer

- **ArkContainer.java**

```java
public class ArkContainer {
    // args中包含上文传入的3个参数
    // -Aclasspath=...
    // -BclassName=cn.aezo.sqbiz.SqBizApplication
    // -BmethodName=main
    public static Object main(String[] args) throws ArkRuntimeException {
        try {
            // 解析参数
            LaunchCommand launchCommand = LaunchCommand.parse(args);
            // ...

            ClassPathArchive classPathArchive = new ClassPathArchive(
                launchCommand.getEntryClassName(), launchCommand.getEntryMethodName(),
                launchCommand.getClasspath());
            // 创建Ark容器并启动
            return new ArkContainer(classPathArchive, launchCommand).start();
        } catch (IOException e) {
            throw new ArkRuntimeException(String.format("SOFAArk startup failed, commandline=%s",
                LaunchCommand.toString(args)), e);
        }
    }

    public Object start() throws ArkRuntimeException {
        AssertUtils.assertNotNull(arkServiceContainer, "arkServiceContainer is null !");
        if (started.compareAndSet(false, true)) {
            Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
                @Override
                public void run() {
                    stop();
                }
            }));
            // 准备参数：将conf/ark/bootstrap.properties中的参数缓存到ArkConfigs.CFG中
            prepareArkConfig();
            // 重新初始化ark日志. 获取配置优先级：System.getProperty > ArkConfigs.CFG > defaultValue
            reInitializeArkLogger();
            // 启动 ArkServiceContainer (控制台会显示 SOFA-ARK-telnet-server-worker 的日志)
            arkServiceContainer.start();
            // 初始化Pipeline，会返回 StandardPipeline
            Pipeline pipeline = arkServiceContainer.getService(Pipeline.class);
            // 会依次执行Pipeline：
                // HandleArchiveStage   解析出Ark包
                // RegisterServiceStage 注册Ark包：只是将所有包下的服务都记录下来
                // ExtensionLoaderStage 扩展，参考 sofa-ark-spi
                // DeployPluginStage    启动所有的Ark插件
                // DeployBizStage       启动所有的Ark Biz(见下文)
                    // ArkTomcatWebServer.initialize 主程序和其他Biz程序启动
                // FinishStartupStage   启动完成事件
            pipeline.process(pipelineContext);
            // Ark container started in xxx ms. 项目启动成功
            System.out.println("Ark container started in " + (System.currentTimeMillis() - start) //NOPMD
                               + " ms.");
        }
        return this;
    }
}
```

#### 以DeployBizStage为例(执行Biz的main方法)

- DeployBizStage.java

```java
@Singleton
public class DeployBizStage implements PipelineStage {
    @Inject
    private BizDeployService  bizDeployService;

    @Override
    public void process(PipelineContext pipelineContext) throws ArkRuntimeException {
        String[] args = pipelineContext.getLaunchCommand().getLaunchArgs();
        // 启动
        bizDeployService.deploy(args);
        eventAdminService.sendEvent(new AfterFinishDeployEvent());
    }
}
```
- BizDeployServiceImpl.java

```java
@Override
public void deploy(String[] args) throws ArkRuntimeException {
    ServiceReference<BizDeployer> serviceReference = registryService
        .referenceService(BizDeployer.class);
    // DefaultBizDeployer
    bizDeployer = serviceReference.getService();

    LOGGER.info(String.format("BizDeployer=\'%s\' is starting.", bizDeployer.getDesc()));

    bizDeployer.init(args);
    // 启动Biz
    bizDeployer.deploy();
}
```
- DefaultBizDeployer.java

```java
@Override
public void deploy() {
    // 循环启动所有Biz,优先级可在maven中配置
    for (Biz biz : bizManagerService.getBizInOrder()) {
        try {
            LOGGER.info(String.format("Begin to start biz: %s", biz.getBizName()));
            // 执行启动
            biz.start(arguments);
            LOGGER.info(String.format("Finish to start biz: %s", biz.getBizName()));
        } catch (Throwable e) {
            LOGGER.error(String.format("Start biz: %s meet error", biz.getBizName()), e);
            throw new ArkRuntimeException(e);
        }
    }
}
```
- BizModel.java

```java
public class BizModel implements Biz {
    @Override
    public void start(String[] args) throws Throwable {
        AssertUtils.isTrue(bizState == BizState.RESOLVED, "BizState must be RESOLVED");
        if (mainClass == null) {
            throw new ArkRuntimeException(String.format("biz: %s has no main method", getBizName()));
        }
        ClassLoader oldClassLoader = ClassLoaderUtils.pushContextClassLoader(this.classLoader);
        EventAdminService eventAdminService = ArkServiceContainerHolder.getContainer().getService(
            EventAdminService.class);
        try {
            // 触发Biz启动前事件，可自定义进行监听
            eventAdminService.sendEvent(new BeforeBizStartupEvent(this));
            resetProperties();

            // 包装Biz的mian方法
            MainMethodRunner mainMethodRunner = new MainMethodRunner(mainClass, args);
            // 反射调用Biz的main方法，如SpringBootApplication.main
            mainMethodRunner.run();

            // 触发Biz启动后事件，可自定义进行监听
            // this can trigger health checker handler 会触发检查Biz状态事件，参考 SofaEventHandler#doHealthCheck
            // 在Biz启动完成后执行健康检查：会获取Biz下所有组件，并依次检查各组件，参考上文[ReferenceComponent为例](#ReferenceComponent为例)
            // 只有此Biz下全部组件通过，则将Biz标记为 ACTIVATED，否则为 BROKEN
            eventAdminService.sendEvent(new AfterBizStartupEvent(this));
        } catch (Throwable e) {
            bizState = BizState.BROKEN;
            throw e;
        } finally {
            ClassLoaderUtils.popContextClassLoader(oldClassLoader);
        }
        BizManagerService bizManagerService = ArkServiceContainerHolder.getContainer().getService(
            BizManagerService.class);
        if (bizManagerService.getActiveBiz(bizName) == null) {
            bizState = BizState.ACTIVATED;
        } else {
            bizState = BizState.DEACTIVATED;
        }
    }
}
```

#### 启动Biz的服务

- 上文mainMethodRunner.run()会调用各Biz的SpringBootApplication.main方法，从而相当于启动一个SpringBoot项目。那么Spring项目启动则势必会调用到refresh方法，最终触发此处onRefresh(refresh - finishRefresh - onRefresh)方法，从而初始化Tomcat
- refresh过程还会刷新SofaBoot Component(如ReferenceComponent,即@SofaReference等注解)的生命周期，参考[runtime-sofa-boot](#runtime-sofa-boot)
- ServletWebServerApplicationContext.java

```java
// org.springframework.boot.web.servlet.context
public class ServletWebServerApplicationContext extends GenericWebApplicationContext implements ConfigurableWebServerApplicationContext {
    protected void onRefresh() {
        super.onRefresh();

        try {
            // 创建Web服务器
            this.createWebServer();
        } catch (Throwable var2) {
            throw new ApplicationContextException("Unable to start web server", var2);
        }
    }

    private void createWebServer() {
        WebServer webServer = this.webServer;
        ServletContext servletContext = this.getServletContext();
        if (webServer == null && servletContext == null) {
            ServletWebServerFactory factory = this.getWebServerFactory();
            this.webServer = factory.getWebServer(new ServletContextInitializer[]{this.getSelfInitializer()});
        } else if (servletContext != null) {
            try {
                this.getSelfInitializer().onStartup(servletContext);
            } catch (ServletException var4) {
                throw new ApplicationContextException("Cannot initialize servlet context", var4);
            }
        }

        this.initPropertySources();
    }
}
```
- ArkTomcatServletWebServerFactory.java

```java
// sofa-ark-springboot-starter-1.1.5.jar
public class ArkTomcatServletWebServerFactory extends TomcatServletWebServerFactory {

    @Override
    public WebServer getWebServer(ServletContextInitializer... initializers) {
        if (embeddedServerService == null) {
            return super.getWebServer(initializers);
        } else if (embeddedServerService.getEmbedServer() == null) {
            embeddedServerService.setEmbedServer(initEmbedTomcat());
        }

        // tomcat-embed-core-9.0.37.jar > org.apache.catalina.startup.Tomcat
        Tomcat embedTomcat = embeddedServerService.getEmbedServer();
        prepareContext(embedTomcat.getHost(), initializers);
        return getWebServer(embedTomcat);
    }

    protected WebServer getWebServer(Tomcat tomcat) {
        return new ArkTomcatWebServer(tomcat, getPort() >= 0, tomcat);
    }
}
```
- ArkTomcatWebServer

```java
public class ArkTomcatWebServer implements WebServer {
    // 初始化
    private void initialize() throws WebServerException {
        logger.info("Tomcat initialized with port(s): " + getPortsDescription(false));
        synchronized (this.monitor) {
            // ...
        }
    }
}
```

## Biz类加载流程(BizClassLoader)

- Biz类加载流程参考`BizClassLoader`
    - Plugin类加载流程参考`PluginClassLoader`

```java
public class BizClassLoader extends AbstractClasspathClassLoader {

    @Override
    protected Class<?> loadClassInternal(String name, boolean resolve) throws ArkLoaderException {
        Class<?> clazz = null;

        // 0. sun reflect related class throw exception directly
        if (classloaderService.isSunReflectClass(name)) {
            throw new ArkLoaderException(
                String
                    .format(
                        "[ArkBiz Loader] %s : can not load class: %s, this class can only be loaded by sun.reflect.DelegatingClassLoader",
                        bizIdentity, name));
        }

        // 1. findLoadedClass
        if (clazz == null) {
            clazz = findLoadedClass(name);
        }

        // 2. JDK related class
        if (clazz == null) {
            clazz = resolveJDKClass(name);
        }

        // 3. Ark Spi class
        if (clazz == null) {
            clazz = resolveArkClass(name);
        }

        // 4. pre find class
        if (clazz == null) {
            clazz = preLoadClass(name);
        }

        // 5. Plugin Export class
        if (clazz == null) {
            clazz = resolveExportClass(name);
        }

        // 6. Biz classpath class
        if (clazz == null) {
            clazz = resolveLocalClass(name);
        }

        // 7. Java Agent ClassLoader for agent problem
        if (clazz == null) {
            clazz = resolveJavaAgentClass(name);
        }

        // 8. post find class
        if (clazz == null) {
            clazz = postLoadClass(name);
        }

        if (clazz != null) {
            if (resolve) {
                super.resolveClass(clazz);
            }
            return clazz;
        }

        throw new ArkLoaderException(String.format("[ArkBiz Loader] %s : can not load class: %s",
            bizIdentity, name));
    }
}
```

## sofa-ark-maven-plugin打包Biz插件

- 打包流程参考：https://zhuanlan.zhihu.com/p/114647271

## 启动日志示例

- 设置`logging.level.io.sofastack.guides.master=INFO`记录日志

```log
20:34:34.539 [main] DEBUG io.netty.util.internal.logging.InternalLoggerFactory - Using SLF4J as the default logging framework
# ...
20:34:36.093 [SOFA-ARK-telnet-server-worker-0-T1] INFO io.netty.handler.logging.LoggingHandler - [id: 0xd2963d81] REGISTERED
20:34:36.117 [SOFA-ARK-telnet-server-worker-0-T1] INFO io.netty.handler.logging.LoggingHandler - [id: 0xd2963d81] BIND: 0.0.0.0/0.0.0.0:1234
20:34:36.167 [SOFA-ARK-telnet-server-worker-0-T1] INFO io.netty.handler.logging.LoggingHandler - [id: 0xd2963d81, L:/0:0:0:0:0:0:0:0:1234] ACTIVE

2021-04-15 20:34:40.233  INFO 10844 --- [           main] com.alipay.sofa                          : SOFABoot Runtime Starting!
# ...
# -->由于当前模块中使用 @SofaReference 引用了服务 SampleJvmService, 因此扫描到此注解时，会根据注解的信息创建相应的代理对象
2021-04-15 20:34:58.727  INFO 10844 --- [           main] com.alipay.sofa                          : Registering component: reference:com.alipay.sofa.isle.sample.SampleJvmService:#1173235289
# 开始创建代理对象
2021-04-15 20:34:58.731  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService.
2021-04-15 20:34:58.759  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService.
# <--解析完一个 @SofaReference
2021-04-15 20:34:58.760  INFO 10844 --- [           main] com.alipay.sofa                          : Registering component: reference:com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl#1173235289
2021-04-15 20:34:58.761  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl.
2021-04-15 20:34:58.761  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl.
2021-04-15 20:34:58.761  INFO 10844 --- [           main] com.alipay.sofa                          : Registering component: reference:com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl#1173235289
2021-04-15 20:34:58.761  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl.
2021-04-15 20:34:58.762  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl.
# ...
2021-04-15 20:35:20.688  INFO 10844 --- [           main] com.alipay.sofa                          : ++++++++++++++++++ ModelCreatingStage of SqBiz Main Start +++++++++++++++++
2021-04-15 20:35:20.717  INFO 10844 --- [           main] com.alipay.sofa                          : ++++++++++++++++++ ModelCreatingStage of SqBiz Main End +++++++++++++++++
2021-04-15 20:35:20.717  INFO 10844 --- [           main] com.alipay.sofa                          : ++++++++++++++++++ SpringContextInstallStage of SqBiz Main Start +++++++++++++++++
2021-04-15 20:35:20.720  INFO 10844 --- [           main] com.alipay.sofa                          : 
All activated module list(2) >>>>>>>
  ├─ cn.aezo.sqbiz.sqbiz-plugin.service-consumer
  └─ cn.aezo.sqbiz.sqbiz-plugin.service-provider

Modules that could install(2) >>>>>>>
  ├─ cn.aezo.sqbiz.sqbiz-plugin.service-provider
  └─ cn.aezo.sqbiz.sqbiz-plugin.service-consumer

2021-04-15 20:35:20.724  INFO 10844 --- [           main] com.alipay.sofa                          : Start install SqBiz Main's module: cn.aezo.sqbiz.sqbiz-plugin.service-provider
2021-04-15 20:35:20 JRebel: Monitoring Spring bean definitions in 'D:\gitwork\oschina\sqbiz\sqbiz-parent\sqbiz-plugin\service-provider\target\classes\META-INF\spring\service-provide.xml'.
2021-04-15 20:35:21.717  INFO 10844 --- [           main] com.alipay.sofa                          : Start install SqBiz Main's module: cn.aezo.sqbiz.sqbiz-plugin.service-consumer
2021-04-15 20:35:21 JRebel: Monitoring Spring bean definitions in 'D:\gitwork\oschina\sqbiz\sqbiz-parent\sqbiz-plugin\service-consumer\target\classes\META-INF\spring\service-consumer.xml'.
2021-04-15 20:40:08.094  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Begin refresh Spring Application Context of module cn.aezo.sqbiz.sqbiz-plugin.service-provider of application SqBiz Main.
2021-04-15 20:41:36.672  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Registering component: service:com.alipay.sofa.isle.sample.SampleJvmService
2021-04-15 20:41:36.673  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<PreOut Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService.
2021-04-15 20:41:36.675  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<PreOut Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService.
2021-04-15 20:43:22.438  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<Out Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService.
2021-04-15 21:03:18.238  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<Out Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService.
2021-04-15 21:03:55.586  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Register Service - com.alipay.sofa.isle.sample.SampleJvmService
2021-04-15 21:05:16.719  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Registering component: service:com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl
2021-04-15 21:05:16.719  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<PreOut Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl.
2021-04-15 21:05:16.719  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<PreOut Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl.
2021-04-15 21:05:29.506  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<Out Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl.
2021-04-15 21:05:29.506  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<Out Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl.
2021-04-15 21:05:29.506  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Register Service - com.alipay.sofa.isle.sample.SampleJvmService:serviceClientImpl
2021-04-15 21:05:29.527  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Registering component: service:com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl
2021-04-15 21:05:29.528  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<PreOut Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl.
2021-04-15 21:05:29.528  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<PreOut Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl.
2021-04-15 21:05:29.528  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<Out Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl.
2021-04-15 21:05:29.528  INFO 10844 --- [ervice-provider] com.alipay.sofa                          :  <<Out Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl.
2021-04-15 21:05:29.528  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Register Service - com.alipay.sofa.isle.sample.SampleJvmService:annotationImpl
2021-04-15 21:07:37.682  INFO 10844 --- [ervice-provider] com.alipay.sofa                          : Registering component: Spring:cn.aezo.sqbiz.sqbiz-plugin.service-provider

2021-04-15 21:17:32.013  INFO 10844 --- [ervice-consumer] com.alipay.sofa                          : Begin refresh Spring Application Context of module cn.aezo.sqbiz.sqbiz-plugin.service-consumer of application SqBiz Main.
Hello, jvm service xml implementation.
Hello, jvm service annotation implementation.
Hello, jvm service service client implementation.
2021-04-15 21:17:35.675  INFO 10844 --- [ervice-consumer] com.alipay.sofa                          : Registering component: Spring:cn.aezo.sqbiz.sqbiz-plugin.service-consumer
2021-04-15 21:17:35.675  INFO 10844 --- [           main] com.alipay.sofa                          : ++++++++++++++++++ SpringContextInstallStage of SqBiz Main End +++++++++++++++++
2021-04-15 21:17:35.676  INFO 10844 --- [           main] com.alipay.sofa                          : ++++++++++++++++++ ModuleLogOutputStage of SqBiz Main Start +++++++++++++++++
2021-04-15 21:17:35.677  INFO 10844 --- [           main] com.alipay.sofa                          : 
Spring context initialize success module list(2) >>>>>>> [totalTime = 1780555 ms, realTime = 2177614 ms]
  ├─cn.aezo.sqbiz.sqbiz-plugin.service-provider [1776894 ms]
  │   `---D:\gitwork\oschina\sqbiz\sqbiz-parent\sqbiz-plugin\service-provider\target\classes\META-INF\spring\service-provide.xml
  └─cn.aezo.sqbiz.sqbiz-plugin.service-consumer [3661 ms]
      `---D:\gitwork\oschina\sqbiz\sqbiz-parent\sqbiz-plugin\service-consumer\target\classes\META-INF\spring\service-consumer.xml

Spring context initialize failed module list(0) >>>>>>>

Spring bean load time cost list(2) >>>>>>> [totalTime = 1780555 ms, realTime = 2177614 ms]
  ├─[Module] cn.aezo.sqbiz.sqbiz-plugin.service-provider [1776894 ms]
  │   ├─com.alipay.sofa.runtime.spring.factory.ServiceFactoryBean (sampleJvmService)  [1420319ms]
  │   ├─com.alipay.sofa.isle.sample.PublishServiceWithClient (publishServiceWithClient)  [12795ms]
  │   ├─com.alipay.sofa.boot.autoconfigure.runtime.SofaRuntimeAutoConfiguration (runtimeContextBeanFactoryPostProcessor)  [529ms]
  │   ├─org.springframework.boot.autoconfigure.jdbc.DataSourceInitializerPostProcessor (dataSourceInitializerPostProcessor)  [175ms]
  │   ├─org.springframework.boot.actuate.autoconfigure.metrics.MetricsAutoConfiguration (meterRegistryPostProcessor)  [173ms]
  │   ├─org.springframework.boot.autoconfigure.dao.PersistenceExceptionTranslationAutoConfiguration (persistenceExceptionTranslationPostProcessor)  [154ms]
  │   ├─com.alipay.sofa.boot.autoconfigure.runtime.SofaRuntimeAutoConfiguration (jvmFilterPostProcessor)  [122ms]
  │   └─com.alipay.sofa.boot.autoconfigure.isle.SofaModuleAutoConfiguration (sofaModuleBeanFactoryPostProcessor)  [121ms]
  └─[Module] cn.aezo.sqbiz.sqbiz-plugin.service-consumer [3661 ms]
      └─com.alipay.sofa.isle.sample.JvmServiceConsumer (consumer)  [3364ms]

2021-04-15 21:17:35.678  INFO 10844 --- [           main] com.alipay.sofa                          : ++++++++++++++++++ ModuleLogOutputStage of SqBiz Main End +++++++++++++++++
Ark container started in 44129 ms.
```
