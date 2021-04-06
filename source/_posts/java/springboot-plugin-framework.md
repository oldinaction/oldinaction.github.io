---
layout: "post"
title: "springboot-plugin-framework库"
date: "2021-04-06 21:54"
categories: java
tags: [src, springboot, plugin]
---

## 简介

- [springboot-plugin-framework](https://gitee.com/starblues/springboot-plugin-framework-parent)、[文档](http://www.starblues.cn/)
- 基于[pf4j](https://github.com/pf4j/pf4j)
- [springboot-plugin-framework扩展](https://gitee.com/starblues/springboot-plugin-framework-parent/tree/master/springboot-plugin-framework-extension)
    - 对mybatis和mybatis-plus进行了支持，插件中可使用mybatis
    - 对resources进行了支持，插件中可使用资源文件，从而显示视图层返回模板页面

## 使用

- 插件相互调用
    - 插件1调用插件2方法，插件1的POM中无需引入插件2。主程序也无需引入插件的POM
    - 插件1调用插件2方法，插件1中需要重新定义一次插件2中需要调用的方法
- 说明
    - **开发时**，开发时需要提前将插件编译出jar，再启动主程序
        - 从而可让 idea 启动主程序时，自动编译插件包的配置。为了在每次启动主程序的时候，能够动态编译插件包，保证插件包的target是最新的
        - 选择 File->Project Structure->Project Settings->Artifacts->点击+号->JAR->From modules whith dependencies->选择对应的插件包->确认OK
        - 启动配置: 在Before launch 下-> 点击小+号 -> Build -> Artifacts -> 选择上一步新增的>Artifacts
        - 之后启动时会产生一个out/artifacts的目录保存编译好的插件jar包
    - 新建插件时，**需要继承`BasePlugin`类，并将其放在插件src根目录**(否则插件中的controller等将无法扫描到)。因为会基于此类进行扫描插件其他类，并进行分组，分组相关逻辑参考包`com.gitee.starblues.factory.process.pipe.classs.group`
    - **插件controller层路径**：`"http://ip:port/" + server.servlet.context-path + DefaultIntegrationConfiguration.pluginRestPathPrefix + (enablePluginIdRestPathPrefix=true时还需加入插件ID) + Controller#RequestMapping + Method#RequestMapping`
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
- 使用mybatis扩展(参考官方源码中文的)
    - xmlLocationsMatch中定义的xml路径不能和主程序中的xml路径在`resources`相对一致，建议使用不同名称区分开。如`xmlLocationsMatch.add("classpath:mapper/minions/**/*Mapper.xml");`
    - **定义的Mapper接口需要加上注解`@Mapper`**
    - 插件默认使用主程序的数据源配置，可通过reSetMainConfig进行重写配置（重写后不影响主程序的配置, 只在当前插件中起作用）；插件也可以使用自定义的数据源
    - **在插件中无法使用mybatis-plus的 `LambdaQueryWrapper` 条件构造器**，部分场景可使用QueryWrapper + Lombok的@SuperBuilder链式调用
    - 插件的mapper.xml文件无法引用主程序中的sql片段
- 使用resources扩展(参考官方源码中文的)
    - 插件中需实现接口`StaticResourceConfig`，并映射出静态文件目录如`classpath:static/minions`
    - 插件中`resources`中存放的资源文件目录一定不能和主程序相同，否则就会加载到主程序的资源


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

// DefaultPluginFactory.java
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
        // PluginPipeProcessorFactory为入口，后续流水线如：PluginClassProcess(对class进行分组)、PluginInterceptorsPipeProcessor、ThymeleafProcessor(官方extension扩展)
        // 详细参考
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

### 注册流水线

- PluginClassProcess.java

### Controller处理

```java
// 以 PluginControllerPostProcessor 为例
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
