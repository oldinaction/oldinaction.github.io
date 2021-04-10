---
layout: "post"
title: "springboot-plugin-framework —— 插件化"
date: "2021-04-06 21:54"
categories: java
tags: [src, springboot, plugin]
---

## 简介

- **2021-04转向sofastack**
- [springboot-plugin-framework](https://gitee.com/starblues/springboot-plugin-framework-parent)、[文档](http://www.starblues.cn/)
- 基于[pf4j](https://github.com/pf4j/pf4j)
- [springboot-plugin-framework扩展](https://gitee.com/starblues/springboot-plugin-framework-parent/tree/master/springboot-plugin-framework-extension)
    - 对mybatis和mybatis-plus进行了支持，插件中可使用mybatis
    - 对resources进行了支持，插件中可使用资源文件，从而显示视图层返回模板页面
- **开发时**，开发时需要提前将插件编译出jar，再启动主程序
    - 从而可让 idea 启动主程序时，自动编译插件包的配置。为了在每次启动主程序的时候，能够动态编译插件包，保证插件包的target是最新的
    - 选择 File->Project Structure->Project Settings->Artifacts->点击+号->JAR->From modules whith dependencies->选择对应的插件包->确认OK
    - 启动配置: 在Before launch 下-> 点击小+号 -> Build -> Artifacts -> 选择上一步新增的>Artifacts
    - 之后启动时会产生一个out/artifacts的目录保存编译好的插件jar包

## 使用

- 新建插件时，**需要继承`BasePlugin`类，并将其放在插件src根目录**(插件只能扫描到当前类同级目录或其子目录下的类)
    - 因为会基于此类进行扫描插件其他类，并进行分组，分组相关逻辑参考包`com.gitee.starblues.factory.process.pipe.classs.group`
- **插件controller层路径**
    - `"http://ip:port/" + server.servlet.context-path + DefaultIntegrationConfiguration.pluginRestPathPrefix + (enablePluginIdRestPathPrefix=true时还需加入插件ID) + Controller#RequestMapping + Method#RequestMapping`
- **在插件中无法直接注入主项目Bean，需要通过`PluginUtils`间接获取**
    - PluginUtils可直接注入到插件项目中，然后通过`@PostConstruct`在初始化方法中调用`pluginUtils.getMainBean(MainIService.class)`获取主程序Bean
    - PluginUtils功能：可在插件中获取主程序中Spring容器中的bean，可获取当前插件的信息，只能作用于当前插件
- 插件自定义yml配置，映射Bean时，不能通过`@ConfigurationProperties`注解，而要使用`@ConfigDefinition`
- maven配置说明

    ```xml
    <!-- 主项目：高版本(>Spring-boot 2.1.1.RELEASE)需要新增repackage -->

    <!-- 
        1.插件如果引入了第三方包(而主程序又没有引入的)，则需要使用 maven-assembly-plugin 的 jar-with-dependencies 功能将依赖的class全部打包到插件的jar包中 
        2.打包插件时，必须将插件包与主程序相同的依赖(特别是版本号不同的)排除掉，不要打入jar包中
    -->
    ```
- 插件相互调用
    - 插件1调用插件2方法，插件1的POM中无需引入插件2。主程序也无需引入插件的POM
    - 插件1调用插件2方法，插件1中需要重新定义一次插件2中需要调用的方法
- 使用mybatis扩展(参考官方源码中文的)
    - xmlLocationsMatch中定义的xml路径不能和主程序中的xml路径在`resources`相对一致，建议使用不同名称区分开。如`xmlLocationsMatch.add("classpath:mapper/minions/**/*Mapper.xml");`
    - **定义的Mapper接口需要加上注解`@Mapper`**
    - 插件默认使用主程序的数据源配置，可通过reSetMainConfig进行重写配置（重写后不影响主程序的配置, 只在当前插件中起作用）；插件也可以使用自定义的数据源
    - **在插件中无法使用mybatis-plus的 `LambdaQueryWrapper` 条件构造器**，部分场景可使用QueryWrapper + Lombok的@SuperBuilder链式调用
    - 插件的mapper.xml文件无法引用主程序中的sql片段
- 使用resources扩展(参考官方源码中文的)
    - 插件中需实现接口`StaticResourceConfig`，并映射出静态文件目录如`classpath:static/minions`
    - 插件中`resources`中存放的资源文件目录一定不能和主程序相同，否则就会加载到主程序的资源
- 插件依赖其他jar包时配置说明

```xml
<!-- sqbiz-plugin父工程 -->
<build>
    <pluginManagement>
        <plugins>
            <plugin>
                <!--支持自定义的打包结构，也可以定制依赖项，设置MANIFEST.MF文件等-->
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>${maven-assembly-plugin.version}</version>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <finalName>sqbiz-${project.artifactId}-${project.version}</finalName>
                    <archive>
                        <manifest>
                            <addDefaultImplementationEntries>true</addDefaultImplementationEntries>
                            <addDefaultSpecificationEntries>true</addDefaultSpecificationEntries>
                        </manifest>
                        <manifestEntries>
                            <Plugin-Id>${plugin.id}</Plugin-Id>
                            <Plugin-Version>${plugin.version}</Plugin-Version>
                            <Plugin-Provider>${plugin.provider}</Plugin-Provider>
                            <Plugin-Class>${plugin.class}</Plugin-Class>
                            <Plugin-Description>${plugin.dependencies}</Plugin-Description>
                        </manifestEntries>
                    </archive>
                    <descriptors>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptors>
                </configuration>
            </plugin>
        </plugins>
    </pluginManagement>
</build>

<!-- 插件 -->
<!-- 假设插件的dependencies依赖了一个A.jar，如果A.jar中用到了和主程序相同的依赖，则需要去除 -->
<!-- build配置 -->
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-assembly-plugin</artifactId>
        </plugin>

        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <version>2.8</version>
            <executions>
                <execution>
                    <id>copy-dependencies</id>
                    <phase>package</phase>
                    <goals>
                        <!-- 复制依赖到lib目录，因为pf4j会把target/lib下的jar包也作为classpath环境 -->
                        <goal>copy-dependencies</goal>
                    </goals>
                    <configuration>
                        <outputDirectory>${project.build.directory}/lib</outputDirectory>
                        <!-- 去除主程序中的依赖 -->
                        <excludeScope>provided</excludeScope>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

## 源码说明

### 启动流程

```java
// 初始化插件系统入口
@Bean
public PluginApplication pluginApplication() {
    return new AutoPluginApplication();
}

// 调用父类DefaultPluginApplication进行初始化
public class AutoPluginApplication extends DefaultPluginApplication
    implements PluginApplication, InitializingBean, ApplicationContextAware {

    // 实现了InitializingBean的afterPropertiesSet方法。从而Spring boot bean属性被Set完后，调用会自动初始化插件
    @Override
    public void afterPropertiesSet() throws Exception {
        if(applicationContext == null){
            throw new Exception("Auto initialize failed. ApplicationContext Not injected.");
        }
        super.initialize(applicationContext, pluginInitializerListener);
    } 
}

// DefaultPluginApplication.java
@Override
public synchronized void initialize(ApplicationContext applicationContext,
                                    PluginInitializerListener listener) {
    Objects.requireNonNull(applicationContext, "ApplicationContext can't be null");
    if(beInitialized.get()){
        throw new RuntimeException("Plugin has been initialized");
    }
    IntegrationConfiguration configuration = getConfiguration(applicationContext);
    // 如果当前环境没有Pf4jFactory，则创建默认的DefaultPf4jFactory
    if(integrationFactory == null){
        integrationFactory = new DefaultPf4jFactory(configuration);
    }
    PluginManager pluginManager = integrationFactory.getPluginManager();
    pluginUser = createPluginUser(applicationContext, pluginManager);
    pluginOperator = createPluginOperator(applicationContext, pluginManager, configuration);
    try {
        setBeanFactory(applicationContext);
        // 初始化插件
        pluginOperator.initPlugins(listener);
        beInitialized.set(true);
    } catch (Exception e) {
        e.printStackTrace();
    }
}

// DefaultPluginOperator.java
@Override
public synchronized boolean initPlugins(PluginInitializerListener pluginInitializerListener) throws Exception {
    if(isInit){
        throw new RuntimeException("Plugins Already initialized. Cannot be initialized again");
    }
    try {
        pluginInitializerListenerFactory.addPluginInitializerListeners(pluginInitializerListener);
        log.info("Plugins start initialize of root path '{}'", pluginManager.getPluginsRoot().toString());
        // 触发插件初始化监听器
        pluginInitializerListenerFactory.before();
        if(!integrationConfiguration.enable()){
            // 如果禁用的话, 直接返回
            pluginInitializerListenerFactory.complete();
            return false;
        }

        // 启动前, 清除空文件
        PluginFileUtils.cleanEmptyFile(pluginManager.getPluginsRoot());

        // 开始初始化插件工厂
        pluginFactory.initialize();
        // 开始加载插件
        pluginManager.loadPlugins();
        pluginManager.startPlugins();
        List<PluginWrapper> pluginWrappers = pluginManager.getStartedPlugins();
        if(pluginWrappers == null || pluginWrappers.isEmpty()){
            log.warn("Not found plugin!");
            return false;
        }
        boolean isFoundException = false;
        for (PluginWrapper pluginWrapper : pluginWrappers) {
            String pluginId = pluginWrapper.getPluginId();
            GlobalRegistryInfo.addOperatorPluginInfo(pluginId,
                    PluginOperatorInfo.OperatorType.INSTALL, false);
            try {
                // PluginRegistryInfo.build 构建一个插件的基本属性，返回 PluginRegistryInfo 对象
                // ***DefaultPluginFactory 依次注册插件信息到Spring boot
                pluginFactory.registry(PluginRegistryInfo.build(pluginWrapper, pluginManager,
                        applicationContext, true));
            } catch (Exception e){
                log.error("Plugin '{}' registry failure. Reason : {}", pluginId, e.getMessage(), e);
                isFoundException = true;
            }
        }
        // ***插件注册完成之后，进行后续构建操作
        pluginFactory.build();
        isInit = true;
        if(isFoundException){
            log.error("Plugins initialize failure");
            return false;
        } else {
            log.info("Plugins initialize success");
            pluginInitializerListenerFactory.complete();
            return true;
        }
    }  catch (Exception e){
        pluginInitializerListenerFactory.failure(e);
        throw e;
    }
}

// DefaultPluginFactory.java 注册某个插件
@Override
public synchronized PluginFactory registry(PluginRegistryInfo pluginRegistryInfo) throws Exception {
    if(pluginRegistryInfo == null){
        throw new IllegalArgumentException("Parameter:pluginRegistryInfo cannot be null");
    }
    PluginWrapper pluginWrapper = pluginRegistryInfo.getPluginWrapper();
    if(registerPluginInfoMap.containsKey(pluginWrapper.getPluginId())){
        throw new IllegalAccessException("The plugin '"
                + pluginWrapper.getPluginId() +"' already exists, Can't register");
    }
    if(!buildContainer.isEmpty() && buildType == 2){
        throw new IllegalAccessException("Unable to Registry operate. Because there's no build");
    }
    try {
        // ***对一个插件进行流水线处理
        // PluginPipeProcessorFactory 为入口，后续流水线如：PluginClassProcess(对class进行分组)、PluginPipeApplicationContextProcessor(进行插件bean的扫描和注册)、PluginInterceptorsPipeProcessor、ThymeleafProcessor(官方extension扩展)
        // 详细参考下文[注册流水线处理](#注册流水线处理)
        pluginPipeProcessor.registry(pluginRegistryInfo);
        registerPluginInfoMap.put(pluginWrapper.getPluginId(), pluginRegistryInfo);
        buildContainer.add(pluginRegistryInfo);
        return this;
    } catch (Exception e) {
        pluginListenerFactory.failure(pluginWrapper.getPluginId(), e);
        throw e;
    } finally {
        buildType = 1;
    }
}

// 注册成功的后续操作
@Override
public synchronized void build() throws Exception {
    if(buildContainer.isEmpty()){
        return;
    }
    // 构建注册的Class插件监听者
    pluginListenerFactory.buildListenerClass(applicationContext);
    try {
        if(buildType == 1){
            // 注册的后续操作
            registryBuild();
        } else {
            unRegistryBuild();
        }
    } finally {
        if(buildType != 1){
            for (PluginRegistryInfo pluginRegistryInfo : buildContainer) {
                pluginRegistryInfo.destroy();
            }
        }
        buildContainer.clear();
        buildType = 0;
    }
}

private void registryBuild() throws Exception {
    // 流水线执行插件注册后的一系列操作，PluginPostProcessorFactory为入口：PluginControllerPostProcessor(处理插件中的controller)，参考下文[Controller处理](#Controller处理)
    pluginPostProcessor.registry(buildContainer);
    for (PluginRegistryInfo pluginRegistryInfo : buildContainer) {
        pluginListenerFactory.registry(
                pluginRegistryInfo.getPluginWrapper().getPluginId(),
                pluginRegistryInfo.isFollowingInitial());
    }
}
```

### 注册插件流水线处理

#### PluginClassProcess.java对类进行分组

```java
// 初始化组类型
@Override
public void initialize() {
    pluginClassGroups.add(new ComponentGroup());
    // 处理Controller
    pluginClassGroups.add(new ControllerGroup());
    pluginClassGroups.add(new RepositoryGroup());
    pluginClassGroups.add(new ConfigDefinitionGroup());
    pluginClassGroups.add(new ConfigBeanGroup());
    pluginClassGroups.add(new SupplierGroup());
    pluginClassGroups.add(new CallerGroup());
    pluginClassGroups.add(new OneselfListenerGroup());
    // 添加扩展
    pluginClassGroups.addAll(ExtensionInitializer.getClassGroupExtends());
}

// 流水线处理某个插件
@Override
public void registry(PluginRegistryInfo pluginRegistryInfo) throws Exception {
    BasePlugin basePlugin = pluginRegistryInfo.getBasePlugin();
    ResourceWrapper resourceWrapper = pluginRegistryInfo.getPluginLoadResource(PluginClassLoader.KEY);
    if(resourceWrapper == null){
        return;
    }
    List<Resource> pluginResources = resourceWrapper.getResources();
    if(pluginResources == null){
        return;
    }
    for (PluginClassGroup pluginClassGroup : pluginClassGroups) {
        try {
            pluginClassGroup.initialize(basePlugin);
        } catch (Exception e){
            log.error("PluginClassGroup {} initialize exception. {}", pluginClassGroup.getClass(),
                    e.getMessage(), e);
        }
    }
    Set<String> classPackageNames = resourceWrapper.getClassPackageNames();
    ClassLoader classLoader = basePlugin.getWrapper().getPluginClassLoader();
    for (String classPackageName : classPackageNames) {
        Class<?> aClass = Class.forName(classPackageName, false, classLoader);
        if(aClass == null){
            continue;
        }
        boolean findGroup = false;
        // 判断属于哪个组，并将类添加到该组
        for (PluginClassGroup pluginClassGroup : pluginClassGroups) {
            if(pluginClassGroup == null || StringUtils.isEmpty(pluginClassGroup.groupId())){
                continue;
            }
            if(pluginClassGroup.filter(aClass)){
                pluginRegistryInfo.addGroupClasses(pluginClassGroup.groupId(), aClass);
                findGroup = true;
            }
        }
        if(!findGroup){
            // 默认放到其他组
            pluginRegistryInfo.addGroupClasses(OTHER, aClass);
        }
        pluginRegistryInfo.addClasses(aClass);
    }
}
```

#### PluginPipeApplicationContextProcessor.java进行插件bean的扫描和注册

```java
@Override
public void initialize() throws Exception {
    pluginBeanDefinitionRegistrars.add(new PluginInsetBeanRegistrar());
    // 插件中实现 ConfigBean 接口的的处理者
    pluginBeanDefinitionRegistrars.add(new ConfigBeanRegistrar());
    pluginBeanDefinitionRegistrars.add(new ConfigFileBeanRegistrar(mainApplicationContext));
    pluginBeanDefinitionRegistrars.add(new BasicBeanRegistrar());
    pluginBeanDefinitionRegistrars.add(new InvokeBeanRegistrar());
    pluginBeanDefinitionRegistrars.addAll(ExtensionInitializer.getPluginBeanRegistrarExtends());
}

@Override
public void registry(PluginRegistryInfo pluginRegistryInfo) throws Exception {
    GenericApplicationContext pluginApplicationContext = pluginRegistryInfo.getPluginApplicationContext();
    // 进行bean注册
    for (PluginBeanRegistrar pluginBeanDefinitionRegistrar : pluginBeanDefinitionRegistrars) {
        pluginBeanDefinitionRegistrar.registry(pluginRegistryInfo);
    }
    ClassLoader contextClassLoader = Thread.currentThread().getContextClassLoader();
    try {
        Thread.currentThread().setContextClassLoader(pluginRegistryInfo.getPluginClassLoader());
        pluginApplicationContext.refresh();
    } finally {
        Thread.currentThread().setContextClassLoader(contextClassLoader);
    }

    // 向插件静态容器中新增插件的ApplicationContext
    String pluginId = pluginRegistryInfo.getPluginWrapper().getPluginId();
    PluginInfoContainers.addPluginApplicationContext(pluginId, pluginApplicationContext);
}

// ConfigBeanRegistrar.java为例，其他也是调用SpringBeanRegister进行注册到插件IOC
@Override
public void registry(PluginRegistryInfo pluginRegistryInfo) throws Exception {
    List<Class<?>> configBeans =
            pluginRegistryInfo.getGroupClasses(ConfigBeanGroup.GROUP_ID);
    if(configBeans == null || configBeans.isEmpty()){
        return;
    }
    String pluginId = pluginRegistryInfo.getPluginWrapper().getPluginId();
    SpringBeanRegister springBeanRegister = pluginRegistryInfo.getSpringBeanRegister();
    for (Class<?> aClass : configBeans) {
        if(aClass == null){
            continue;
        }
        // 注册Bean到IOC
        springBeanRegister.register(pluginId, aClass);
    }
}

// SpringBeanRegister.java 通用Bean注册
public String register(String pluginId, Class<?> aClass,
                           Consumer<AnnotatedGenericBeanDefinition> consumer) {
    AnnotatedGenericBeanDefinition beanDefinition = new AnnotatedGenericBeanDefinition(aClass);
    beanDefinition.setBeanClass(aClass);
    BeanNameGenerator beanNameGenerator =
            new PluginAnnotationBeanNameGenerator(pluginId);
    String beanName = beanNameGenerator.generateBeanName(beanDefinition, applicationContext);

    if(applicationContext.containsBean(beanName)){
        String error = MessageFormat.format("Bean name {0} already exist of {1}",
                beanName, aClass.getName());
        logger.debug(error);
        return beanName;
    }
    if(consumer != null){
        consumer.accept(beanDefinition);
    }
    // 此处为插件级别上下文，因此Bean是注册到插件的IOC容器中。上下文为实例化 PluginRegistryInfo 时初始化
    applicationContext.registerBeanDefinition(beanName, beanDefinition);
    return beanName;
}
```

#### PluginInterceptorsPipeProcessor.java处理SpringMVC拦截器

```java
@Override
public void registry(PluginRegistryInfo pluginRegistryInfo) throws Exception {
    if(handlerMapping == null){
        return;
    }
    // 获取插件上下文
    GenericApplicationContext pluginApplicationContext = pluginRegistryInfo.getPluginApplicationContext();
    // 获取PluginInterceptorRegister(starblues)类型的Bean，需要将插件中SpringMVC的拦截器HandlerInterceptor通过此类进行注册
    // 因此常规的通过Spring的InterceptorRegistry进行注册是无法成功的
    List<PluginInterceptorRegister> interceptorRegisters = SpringBeanUtils.getBeans(pluginApplicationContext,
            PluginInterceptorRegister.class);
    List<HandlerInterceptor> interceptorsObjects = new ArrayList<>();
    List<HandlerInterceptor> adaptedInterceptors = getAdaptedInterceptors();
    if(adaptedInterceptors == null){
        return;
    }
    // 根据拦截的controller的前缀进行处理，如：/plugins/plugin-id
    String pluginRestPrefix = CommonUtils.getPluginRestPrefix(configuration, pluginRegistryInfo.getPluginWrapper().getPluginId());

    for (PluginInterceptorRegister interceptorRegister : interceptorRegisters) {
        PluginInterceptorRegistry interceptorRegistry = new PluginInterceptorRegistry(pluginRestPrefix);
        // 注册实际的SpringMVC的拦截器HandlerInterceptor
        interceptorRegister.registry(interceptorRegistry);
        // 获取插件拦截器
        List<Object> interceptors = interceptorRegistry.getInterceptors();
        if(interceptors == null || interceptors.isEmpty()){
            continue;
        }
        for (Object interceptor : interceptors) {
            // 转换拦截器为 HandlerInterceptor 类
            HandlerInterceptor handlerInterceptor = adaptInterceptor(interceptor);
            adaptedInterceptors.add(handlerInterceptor);
            interceptorsObjects.add(handlerInterceptor);
        }
    }
    pluginRegistryInfo.addExtension(INTERCEPTORS, interceptorsObjects);
}
```

### 插件注册后流水线处理

#### Controller处理

```java
// 以 PluginControllerPostProcessor 为例
public PluginControllerPostProcessor(ApplicationContext mainApplicationContext){
    Objects.requireNonNull(mainApplicationContext);
    // 获取主系统的RequestMappingHandlerMapping对象
    this.requestMappingHandlerMapping = mainApplicationContext.getBean(RequestMappingHandlerMapping.class);
    this.configuration = mainApplicationContext.getBean(IntegrationConfiguration.class);
    this.pluginControllerProcessors = ExtensionFactory
            .getPluginControllerProcessorExtend(mainApplicationContext);
}

@Override
public void registry(List<PluginRegistryInfo> pluginRegistryInfos) throws Exception {
    for (PluginRegistryInfo pluginRegistryInfo : pluginRegistryInfos) {
        // 获取 spring_controller 组下的所有类
        List<Class<?>> groupClasses = pluginRegistryInfo.getGroupClasses(ControllerGroup.GROUP_ID);
        if(groupClasses == null || groupClasses.isEmpty()){
            continue;
        }
        String pluginId = pluginRegistryInfo.getPluginWrapper().getPluginId();
        List<ControllerWrapper> controllerBeanWrappers = new ArrayList<>();
        for (Class<?> groupClass : groupClasses) {
            if(groupClass == null){
                continue;
            }
            try {
                // 构建一个ControllerWrapper
                ControllerWrapper controllerBeanWrapper = registry(pluginRegistryInfo, groupClass);
                controllerBeanWrappers.add(controllerBeanWrapper);
            } catch (Exception e){
                pluginRegistryInfo.addProcessorInfo(getKey(pluginRegistryInfo), controllerBeanWrappers);
                throw e;
            }
        }
        // 调用扩展出的接口控制器
        resolveProcessExtend(extend->{
            try {
                extend.registry(pluginId, controllerBeanWrappers);
            }catch (Exception e){
                log.error("'{}' process plugin[{}] error in registry",
                        extend.getClass().getName(),
                        pluginId,  e);
            }
        });
        pluginRegistryInfo.addProcessorInfo(getKey(pluginRegistryInfo), controllerBeanWrappers);
    }
}

// 构建ControllerWrapper
private ControllerWrapper registry(PluginRegistryInfo pluginRegistryInfo, Class<?> aClass)
            throws Exception {
    String pluginId = pluginRegistryInfo.getPluginWrapper().getPluginId();
    GenericApplicationContext pluginApplicationContext = pluginRegistryInfo.getPluginApplicationContext();
    try {
        Object object = pluginApplicationContext.getBean(aClass);
        ControllerWrapper controllerBeanWrapper = new ControllerWrapper();
        // 设置插件controller的前缀，如：/plugins/plugin-id
        setPathPrefix(pluginId, aClass);
        Method getMappingForMethod = ReflectionUtils.findMethod(RequestMappingHandlerMapping.class,
                "getMappingForMethod", Method.class, Class.class);
        getMappingForMethod.setAccessible(true);
        Method[] methods = aClass.getMethods();
        Set<RequestMappingInfo> requestMappingInfos = new HashSet<>();
        for (Method method : methods) {
            if (isHaveRequestMapping(method)) {
                RequestMappingInfo requestMappingInfo = (RequestMappingInfo)
                        getMappingForMethod.invoke(requestMappingHandlerMapping, method, aClass);
                // 最终会调用到springmvc的AbstractHandlerMethodMapping#register方法
                // 将URL-HandlerMethod映射关系保存到**主系统**的mappingRegistry中(requestMappingHandlerMapping为主系统Bean)
                // 参考[spring-mvc-src.md#mappingRegistry初始化](/_posts/java/java-src/spring-mvc-src.md#mappingRegistry初始化)
                requestMappingHandlerMapping.registerMapping(requestMappingInfo, object, method);
                requestMappingInfos.add(requestMappingInfo);
            }
        }
        controllerBeanWrapper.setRequestMappingInfos(requestMappingInfos);
        controllerBeanWrapper.setBeanClass(aClass);
        return controllerBeanWrapper;
    } catch (Exception e){
        // 出现异常, 卸载该 controller bean
        throw e;
    }
}

private void setPathPrefix(String pluginId, Class<?> aClass) {
    // 获取类注解 @RequestMapping 进行添加前缀
    RequestMapping requestMapping = aClass.getAnnotation(RequestMapping.class);
    if(requestMapping == null){
        return;
    }
    String pathPrefix = CommonUtils.getPluginRestPrefix(configuration, pluginId);
    if(StringUtils.isNullOrEmpty(pathPrefix)){
        return;
    }
    InvocationHandler invocationHandler = Proxy.getInvocationHandler(requestMapping);
    Set<String> definePaths = new HashSet<>();
    definePaths.addAll(Arrays.asList(requestMapping.path()));
    definePaths.addAll(Arrays.asList(requestMapping.value()));
    try {
        Field field = invocationHandler.getClass().getDeclaredField("memberValues");
        field.setAccessible(true);
        Map<String, Object> memberValues = (Map<String, Object>) field.get(invocationHandler);
        String[] newPath = new String[definePaths.size()];
        int i = 0;
        for (String definePath : definePaths) {
            // 解决插件启用、禁用后, 路径前缀重复的问题。
            if(definePath.contains(pathPrefix)){
                newPath[i++] = definePath;
            } else {
                newPath[i++] = CommonUtils.restJoiningPath(pathPrefix, definePath);
            }
        }
        if(newPath.length == 0){
            newPath = new String[]{ pathPrefix };
        }
        memberValues.put("path", newPath);
        memberValues.put("value", new String[]{});
    } catch (Exception e) {
        log.error("Define Plugin RestController pathPrefix error : {}", e.getMessage(), e);
    }
}
```

## pf4j

- **2021-04转向sofastack**
- [PF4J](https://github.com/pf4j/pf4j) 是一个 Java 的插件框架，为第三方提供应用扩展的渠道。PF4J 本身非常轻量级，只有 50KB 左右，目前只依赖了 slf4j。Gitblit 项目使用的就是 PF4J 进行插件管理
- 组件
    - `Plugin` 是所有插件类型的基类。为了避免冲突，每个插件都被加载到一个单独的类加载器中
    - `PluginManager` 用于插件管理的所有方面（加载、启动、停止）
    - `PluginLoader` 加载插件所需的所有信息（类）
    - 可以将任何接口或抽象类标记为扩展点（即继承`ExtensionPoint`接口），并使用`@Extension`标记扩展点的实现类
- 相关生态
    - pf4j-update（PF4J的更新机制）
    - pf4j-spring（PF4J-Spring框架集成）
    - pf4j-wicket（PF4J-Wicket集成）
    - pf4j-web（web应用程序中的PF4J）
    - springboot-plugin-framework（见下文）
- 案例

```java
// 参考：https://www.cnblogs.com/fengyun2050/p/12809204.html
// 主程序定义扩展点
public interface Greeting extends ExtensionPoint {
    String getGreeting();
}

// 插件定义实现类
@Extension
public class WelcomeGreeting implements Greeting {
    public String getGreeting() {
        return "Welcome";
    }
}
// 插件maven打包（参考下文maven配置），会在MANIFEST.MF文件生成如下(可以将插件作为jar文件分发)
// 插件id为welcome-plugin（强制属性）、版本为0.0.1（强制属性）、类为cn.aezo.test.pf4j.welcome.WelcomePlugin（可选属性）作者为Smalle的插件；以及与插件x, y, z（可选属性）的依赖关系
Plugin-Id: welcome-plugin
Plugin-Version: 0.0.1
Plugin-Class: cn.aezo.test.pf4j.welcome.WelcomePlugin
Plugin-Provider: Smalle
Plugin-Dependencies: x, y, z

// 主程序中使用插件
public static void main(String[] args) {
    // jar插件管理器
    PluginManager pluginManager = new JarPluginManager();// or "new ZipPluginManager() / new DefaultPluginManager()"

    // 加载指定路径插件
    pluginManager.loadPlugin(Paths.get("plugins-0.0.1-SNAPSHOT.jar")); // 或 pluginManager.loadPlugins(); 加载所有

    // 启动指定插件(也可以加载所有插件)
    pluginManager.startPlugin("welcome-plugin"); // 或 pluginManager.startPlugins(); 启动所有

    // 执行插件
    List<Greeting> greetings = pluginManager.getExtensions(Greeting.class);
    for (Greeting greeting : greetings) {
        System.out.println(">>> " + greeting.getGreeting()); // Welcome
    }
}
```
- 插件maven打包

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-jar-plugin</artifactId>
  <version>2.3.1</version>
  <configuration>
    <archive>
      <manifestEntries>
        <Plugin-Id>welcome-plugin</Plugin-Id>
        <Plugin-Version>0.0.1</Plugin-Version>
      </manifestEntries>
    </archive>
  </configuration>
</plugin>
```
