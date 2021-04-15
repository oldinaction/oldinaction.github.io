---
layout: "post"
title: "SOFAStack源码分析"
date: "2021-04-13 22:23"
categories: java
tags: [springboot, plugin, 微服务, src]
---

## runtime-sofa-boot组件

### 初始化

#### BeanPostProcessor注册组件入口

- Spring初始化时，会调用其 postProcessBeforeInitialization 方法
- 如根据`@SofaReference`注解，将组件信息(此时为ReferenceComponent类)保存到ComponentManagerImpl#registry集合中，集合中的key为ComponentName类型
    - 此时ComponentName如：`reference:com.alipay.sofa.isle.sample.SampleJvmService:#2120635923`(reference表示基于此注解解析的)
- ReferenceAnnotationBeanPostProcessor.java为例

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

                // 创建ReferenceComponent的代理对象，具体参考下文
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
                // 执行激活组件方法，参考下文
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
            // 实例化 JvmServiceInvoker，通过此对象调用服务？
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

## isle-sofa-boot

### 初始化

- 初始化SOFABoot模块

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
- FileDeploymentDescriptor.java 基于文件安装的模块

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
2021-04-15 20:34:58.727  INFO 10844 --- [           main] com.alipay.sofa                          : Registering component: reference:com.alipay.sofa.isle.sample.SampleJvmService:#1173235289
2021-04-15 20:34:58.731  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Begins - com.alipay.sofa.isle.sample.SampleJvmService.
2021-04-15 20:34:58.759  INFO 10844 --- [           main] com.alipay.sofa                          :  >>In Binding [jvm] Ends - com.alipay.sofa.isle.sample.SampleJvmService.
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
