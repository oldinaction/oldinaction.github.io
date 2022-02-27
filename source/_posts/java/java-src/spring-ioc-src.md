---
layout: "post"
title: "Spring IOC源码解析"
date: "2020-09-08 09:25"
categories: [java]
tags: [spring, src]
---

> 转载自：https://javadoop.com/post/spring-ioc

## 类关系

- 类关系图 [^1]

    ![spring-ioc](/data/images/java/spring-src-ioc.png)
    - ApplicationContext 继承了 ListableBeanFactory，这个 Listable 的意思就是，通过这个接口，我们可以获取多个 Bean。最顶层 BeanFactory 接口的方法都是获取单个 Bean 的
    - ApplicationContext 继承了 HierarchicalBeanFactory, Hierarchical 单词本身(分层的)已经能说明问题了，也就是说我们可以在应用中起多个 BeanFactory，然后可以将各个 BeanFactory 设置为父子关系
    - AutowireCapableBeanFactory 这个名字中的 Autowire，它就是用来自动装配 Bean 用的，但是仔细看上图，ApplicationContext 并没有继承它，但是使用组合可以获取它，从 ApplicationContext 接口定义中的最后一个方法 getAutowireCapableBeanFactory() 可说明
    - ConfigurableListableBeanFactory 也是一个特殊的接口，看图，特殊之处在于它继承了第二层所有的三个接口，而 ApplicationContext 没有
- **AnnotationConfigApplicationContext**
    - 实现接口: ApplicationContext - ListableBeanFactory - BeanFactory
    - 继承自: DefaultListableBeanFactory
    - AnnotationConfigRegistry
    - BeanDefinitionRegistry
- **DefaultListableBeanFactory**
    - 实现接口: BeanFactory、BeanDefinitionRegistry
    - 子类: AnnotationConfigApplicationContext
- BeanDefinition 描述了一个Bean实例的属性值，构造函数参数值

## 基于ClassPathXmlApplicationContext执行流程

### 测试入口代码

```java
public class AppXml {
    public static void main(String[] args) {
        // 创建AnnotationConfigApplicationContext
        ApplicationContext ac = new ClassPathXmlApplicationContext("classpath:spring5/beans.xml");
        MyService myService = ac.getBean("myService", MyService.class);
        myService.doService();
    }
}
```

### AnnotationConfigApplicationContext创建

```java
public class ClassPathXmlApplicationContext extends AbstractXmlApplicationContext {
    private Resource[] configResources;

    // 如果已经有 ApplicationContext 并需要配置成父子关系，那么调用这个构造方法
    public ClassPathXmlApplicationContext(ApplicationContext parent) {
		super(parent);
	}

    // 上文main方法调用函数
    public ClassPathXmlApplicationContext(String configLocation) throws BeansException {
		this(new String[] {configLocation}, true, null);
	}

    public ClassPathXmlApplicationContext(
			String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
			throws BeansException {
		super(parent);
        // 根据提供的路径，处理成配置文件数组(以分号、逗号、空格、tab、换行符分割)
		setConfigLocations(configLocations);
		if (refresh) {
            // ***************
            // 核心方法
            // 为什么取名不是init：因为 ApplicationContext 建立起来以后，其实我们是可以通过调用 refresh() 这个方法重建的，refresh() 会将原来的 ApplicationContext 销毁，然后再重新执行一次初始化操作
			refresh();
		}
	}
}
```

### refresh方法概览

```java
// AbstractApplicationContext.java
@Override
public void refresh() throws BeansException, IllegalStateException {
    // 来个锁，不然 refresh() 还没结束，你又来个启动或销毁容器的操作，那不就乱套了嘛
    synchronized (this.startupShutdownMonitor) {
        // [创建 Bean 容器前的准备工作](#创建%20Bean%20容器前的准备工作)
        // 准备工作，记录下容器的启动时间、标记“已启动”状态、处理配置文件中的占位符
        prepareRefresh();

        // ***************
        // [创建 Bean 容器，加载并注册 Bean](#创建%20Bean%20容器，加载并注册%20Bean)
        // 这步比较关键，这步完成后，配置文件就会解析成一个个 Bean 定义，注册到 BeanFactory 中，
        // 当然，这里说的 Bean 还没有初始化，只是配置信息都提取出来了，注册也只是将这些信息都保存到了注册中心(***说到底核心是一个 beanName-> beanDefinition 的 map***)
        // 资源(bean)读取基于XmlBeanDefinitionReader；如果是基于注解进行初始化spring的，则是基于ClassPathMapperScanner 进行类扫描和注册的
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

        // [Bean 容器实例化完成后](#Bean%20容器实例化完成后)
        // 设置 BeanFactory 的类加载器，添加几个 BeanPostProcessor，手动注册几个特殊的 bean
        // 这块待会会展开说
        prepareBeanFactory(beanFactory);

        try {
            // 这里需要知道 BeanFactoryPostProcessor 这个知识点，Bean 如果实现了此接口，那么在容器初始化以后，Spring 会负责调用里面的 postProcessBeanFactory 方法(主要做一些初始化)

            // 到这里的时候，所有的 Bean 都加载、注册完成了，**但是都还没有初始化**
            // 这里是提供给子类的扩展点，具体的子类可以在这步的时候添加一些特殊的 BeanFactoryPostProcessor 的实现类或做点什么事
            postProcessBeanFactory(beanFactory);
            // 调用 BeanFactoryPostProcessor 各个实现类的 postProcessBeanFactory(factory) 方法
            invokeBeanFactoryPostProcessors(beanFactory);

            // 注册 BeanPostProcessor 的实现类，注意看和 BeanFactoryPostProcessor 的区别
            // 此接口两个方法: postProcessBeforeInitialization 和 postProcessAfterInitialization
            // 两个方法分别在 Bean 初始化之前和初始化之后得到执行。注意，到这里 Bean 还没初始化
            registerBeanPostProcessors(beanFactory);

            // 初始化当前 ApplicationContext 的 MessageSource，国际化这里就不展开说了，不然没完没了了
            initMessageSource();

            // 初始化当前 ApplicationContext 的事件广播器，这里也不展开了
            initApplicationEventMulticaster();

            // 从方法名就可以知道，典型的模板方法(钩子方法)，
            // 具体的子类可以在这里初始化一些特殊的 Bean（在初始化 singleton beans 之前）
            onRefresh();

            // 注册事件监听器，监听器需要实现 ApplicationListener 接口。这也不是我们的重点，过
            registerListeners();

            // ***************
            // 重点，重点，重点
            // 到目前为止（执行此行代码前），应该说 BeanFactory 已经创建完成，并且所有的实现了 BeanFactoryPostProcessor 接口的 Bean 都已经初始化并且其中的 postProcessBeanFactory(factory) 方法已经得到回调执行了。而且 Spring 已经“手动”注册了一些特殊的 Bean，如 environment、systemProperties 等
            // 初始化所有的 singleton beans （lazy-init 的除外） => 创建Bean
            finishBeanFactoryInitialization(beanFactory);

            // 最后，广播事件，ApplicationContext 初始化完成
            finishRefresh();
        }

        catch (BeansException ex) {
            if (logger.isWarnEnabled()) {
                logger.warn("Exception encountered during context initialization - " +
                    "cancelling refresh attempt: " + ex);
            }

            // Destroy already created singletons to avoid dangling resources.
            // 销毁已经初始化的 singleton 的 Beans，以免有些 bean 会一直占用资源
            destroyBeans();

            // Reset 'active' flag.
            cancelRefresh(ex);

            // 把异常往外抛
            throw ex;
        }

        finally {
            // Reset common introspection caches in Spring's core, since we
            // might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
        }
    }
}
```

### 创建Bean容器前的准备工作

#### prepareRefresh创建Bean容器前的准备工作

```java
protected void prepareRefresh() {
    // 记录启动时间，
    // 将 active 属性设置为 true，closed 属性设置为 false，它们都是 AtomicBoolean 类型
    this.startupDate = System.currentTimeMillis();
    this.closed.set(false);
    this.active.set(true);

    if (logger.isInfoEnabled()) {
        logger.info("Refreshing " + this);
    }

    // Initialize any placeholder property sources in the context environment
    initPropertySources();

    // 校验 xml 配置文件
    getEnvironment().validateRequiredProperties();

    this.earlyApplicationEvents = new LinkedHashSet<ApplicationEvent>();
}
```

### 创建 Bean 容器，加载并注册 Bean

- obtainFreshBeanFactory 创建 Bean 容器，加载并注册 Bean
    - customizeBeanFactory 配置是否允许 BeanDefinition 覆盖、循环引用
    - loadBeanDefinitions 加载并注册 Bean
        - registerBeanDefinition 注册Bean

#### obtainFreshBeanFactory

- 这里将会初始化 BeanFactory、加载 Bean、注册 Bean 等等。当然，这步结束后，Bean 并没有完成初始化，即 Bean 实例并未在这一步生成
- AbstractApplicationContext.java

```java
protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
    // 关闭旧的 BeanFactory (如果有)，创建新的 BeanFactory，加载 Bean 定义、注册 Bean 等等。
    // 具体见下文
    refreshBeanFactory();

    // 返回刚刚创建的 BeanFactory
    ConfigurableListableBeanFactory beanFactory = getBeanFactory();
    if (logger.isDebugEnabled()) {
        logger.debug("Bean factory for " + getDisplayName() + ": " + beanFactory);
    }
    return beanFactory;
}
```
- AbstractRefreshableApplicationContext.java

```java
@Override
protected final void refreshBeanFactory() throws BeansException {
    // 如果 ApplicationContext 中已经加载过 BeanFactory 了，销毁所有 Bean，关闭 BeanFactory
    // 注意，应用中 BeanFactory 本来就是可以多个的，这里可不是说应用全局是否有 BeanFactory，
    // 而是当前 ApplicationContext 是否有 BeanFactory
    if (hasBeanFactory()) {
        destroyBeans();
        closeBeanFactory();
    }
    try {
        // ***************
        // 1.初始化一个 DefaultListableBeanFactory，为什么用这个：从上文类图可知，DefaultListableBeanFactory通吃两路父类接口
        // 2.ApplicationContext 继承自 BeanFactory，但是它不应该被理解为 BeanFactory 的实现类，
        // 而是说其内部持有一个实例化的 BeanFactory（DefaultListableBeanFactory）,
        // 以后所有的 BeanFactory 相关的操作其实是委托给这个实例来处理的
        DefaultListableBeanFactory beanFactory = createBeanFactory();

        // 用于 BeanFactory 的序列化，我想部分人应该都用不到
        beanFactory.setSerializationId(getId());

        // ***************
        // 下面这两个方法很重要，别跟丢了，具体细节之后说
        // 设置 BeanFactory 的两个配置属性：是否允许 Bean 覆盖、是否允许循环引用
        customizeBeanFactory(beanFactory);
        // 加载 Bean 到 BeanFactory 中
        loadBeanDefinitions(beanFactory);

        synchronized (this.beanFactoryMonitor) {
            this.beanFactory = beanFactory;
        }
    }
    catch (IOException ex) {
        throw new ApplicationContextException("I/O error parsing bean definition source for " + getDisplayName(), ex);
    }
}
```

#### customizeBeanFactory配置是否允许BeanDefinition覆盖、循环引用

- BeanDefinition 的覆盖问题
    - 就是在配置文件中定义 bean 时使用了相同的 id 或 name，默认情况下，allowBeanDefinitionOverriding 属性为 null，如果在同一配置文件中重复了，会抛错，但是如果不是同一配置文件中，会发生覆盖
    - 参考：[解决spring中不同配置文件中存在name或者id相同的bean可能引起的问题](https://blog.csdn.net/zgmzyr/article/details/39380477)
- BeanDefinition 的循环引用
    - 如：A 依赖 B，而 B 依赖 A。或 A 依赖 B，B 依赖 C，而 C 依赖 A
    - 默认情况下，Spring 允许循环依赖，当然如果你在 A 的构造方法中依赖 B，在 B 的构造方法中依赖 A 是不行的

```java
protected void customizeBeanFactory(DefaultListableBeanFactory beanFactory) {
    if (this.allowBeanDefinitionOverriding != null) {
        // 是否允许 Bean 定义覆盖
        beanFactory.setAllowBeanDefinitionOverriding(this.allowBeanDefinitionOverriding);
    }
    if (this.allowCircularReferences != null) {
        // 是否允许 Bean 间的循环依赖
        beanFactory.setAllowCircularReferences(this.allowCircularReferences);
    }
}
```

#### loadBeanDefinitions加载并注册Bean

- AbstractXmlApplicationContext.java

```java
// 这个方法将根据配置，加载各个 Bean，然后放到 BeanFactory 中。读取配置的操作在 XmlBeanDefinitionReader 中，其负责加载配置、解析
@Override
protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
    // 给这个 BeanFactory 实例化一个 XmlBeanDefinitionReader
    XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);

    // Configure the bean definition reader with this context's
    // resource loading environment.
    beanDefinitionReader.setEnvironment(this.getEnvironment());
    beanDefinitionReader.setResourceLoader(this);
    beanDefinitionReader.setEntityResolver(new ResourceEntityResolver(this));

    // 初始化 BeanDefinitionReader，其实这个是提供给子类覆写的，
    // 我看了一下，没有类覆写这个方法，我们姑且当做不重要吧
    initBeanDefinitionReader(beanDefinitionReader);
    // 通过刚刚初始化的 Reader 开始来加载 xml 配置，并转换为 Resource 进行循环处理
    loadBeanDefinitions(beanDefinitionReader);
}

// 上面转换后的 Resource 在此处处理
@Override
public int loadBeanDefinitions(Resource... resources) throws BeanDefinitionStoreException {
    Assert.notNull(resources, "Resource array must not be null");
    int counter = 0;
    // 注意这里是个 for 循环，也就是每个文件是一个 resource
    for (Resource resource : resources) {
        // 继续往下看
        counter += loadBeanDefinitions(resource);
    }
    // 最后返回 counter，表示总共加载了多少的 BeanDefinition
    return counter;
}
```

<details>
<summary>解析Resource</summary>

- XmlBeanDefinitionReader.java 上面转换后的 Resource 进行循环处理，单个的处理如下

```java
@Override
public int loadBeanDefinitions(Resource resource) throws BeanDefinitionStoreException {
    return loadBeanDefinitions(new EncodedResource(resource));
}

public int loadBeanDefinitions(EncodedResource encodedResource) throws BeanDefinitionStoreException {
    // ...

    // 用一个 ThreadLocal 来存放配置文件资源
    Set<EncodedResource> currentResources = this.resourcesCurrentlyBeingLoaded.get();

    // ...
    try {
        InputStream inputStream = encodedResource.getResource().getInputStream();
        try {
            InputSource inputSource = new InputSource(inputStream);
            if (encodedResource.getEncoding() != null) {
                inputSource.setEncoding(encodedResource.getEncoding());
            }
            // 核心部分是这里，往下面看
            return doLoadBeanDefinitions(inputSource, encodedResource.getResource());
        }
        finally {
            inputStream.close();
        }
    }
    // ...
}

protected int doLoadBeanDefinitions(InputSource inputSource, Resource resource)
      throws BeanDefinitionStoreException {
    try {
        // 这里就不看了，将 xml 文件转换为 Document 对象
        Document doc = doLoadDocument(inputSource, resource);
        // 继续
        return registerBeanDefinitions(doc, resource);
    }
    // ...
}

// 返回值：返回从当前配置文件加载了多少数量的 Bean
public int registerBeanDefinitions(Document doc, Resource resource) throws BeanDefinitionStoreException {
    BeanDefinitionDocumentReader documentReader = createBeanDefinitionDocumentReader();
    int countBefore = getRegistry().getBeanDefinitionCount();
    // ***************
    // 这里
    documentReader.registerBeanDefinitions(doc, createReaderContext(resource));
    return getRegistry().getBeanDefinitionCount() - countBefore;
}
```
- DefaultBeanDefinitionDocumentReader.java

```java
@Override
public void registerBeanDefinitions(Document doc, XmlReaderContext readerContext) {
    this.readerContext = readerContext;
    logger.debug("Loading bean definitions");
    Element root = doc.getDocumentElement();
    // 从 xml 根节点开始解析文件
    doRegisterBeanDefinitions(root);
}

protected void doRegisterBeanDefinitions(Element root) {
    // 我们看名字就知道，BeanDefinitionParserDelegate 必定是一个重要的类，它负责解析 Bean 定义，
    // 这里为什么要定义一个 parent? 看到后面就知道了，是递归问题，
    // 因为 <beans /> 内部是可以定义 <beans /> 的，所以这个方法的 root 其实不一定就是 xml 的根节点
    // 也可以是嵌套在里面的 <beans /> 节点，从源码分析的角度，我们当做根节点就好了
    BeanDefinitionParserDelegate parent = this.delegate;
    this.delegate = createDelegate(getReaderContext(), root, parent);

    if (this.delegate.isDefaultNamespace(root)) {
        // 这块说的是根节点 <beans ... profile="dev" /> 中的 profile 是否是当前环境需要的，
        // 如果当前环境配置的 profile 不包含此 profile，那就直接 return 了，不对此 <beans /> 解析
        String profileSpec = root.getAttribute(PROFILE_ATTRIBUTE);
        if (StringUtils.hasText(profileSpec)) {
            String[] specifiedProfiles = StringUtils.tokenizeToStringArray(
                profileSpec, BeanDefinitionParserDelegate.MULTI_VALUE_ATTRIBUTE_DELIMITERS);
            if (!getReaderContext().getEnvironment().acceptsProfiles(specifiedProfiles)) {
                if (logger.isInfoEnabled()) {
                    logger.info("Skipped XML bean definition file due to specified profiles [" + profileSpec +
                            "] not matching: " + getReaderContext().getResource());
                }
                return;
            }
        }
    }

    preProcessXml(root); // 钩子
    // ***************
    // 往下看
    parseBeanDefinitions(root, this.delegate);
    postProcessXml(root); // 钩子

    this.delegate = parent;
}

protected void parseBeanDefinitions(Element root, BeanDefinitionParserDelegate delegate) {
    if (delegate.isDefaultNamespace(root)) {
        NodeList nl = root.getChildNodes();
        for (int i = 0; i < nl.getLength(); i++) {
            Node node = nl.item(i);
            if (node instanceof Element) {
                Element ele = (Element) node;
                if (delegate.isDefaultNamespace(ele)) {
                    // 解析 default namespace 下面的几个元素，涉及到的就四个标签(其他的属于 custom 的)： <import />、<alias />、<bean /> 和 <beans />
                    // 这里的四个标签之所以是 default 的，是因为它们是处于 http://www.springframework.org/schema/beans 这个 namespace 下定义的
                    parseDefaultElement(ele, delegate);
                }
                else {
                    // 解析其他 namespace 的元素：如我们经常会使用到的 <mvc />、<task />、<context />、<aop />等
                    // 如果需要使用上面这些 “非 default” 标签，那么 xml 头部的地方也要引入相应的 namespace 和 .xsd 文件的路径
                    // 同时代码中需要提供相应的 parser 来解析，如 MvcNamespaceHandler、TaskNamespaceHandler、ContextNamespaceHandler、AopNamespaceHandler 等
                    // 同理，以后你要是碰到 <dubbo /> 这种标签，那么就应该搜一搜是不是有 DubboNamespaceHandler 这个处理类
                    delegate.parseCustomElement(ele);
                }
            }
        }
    }
    else {
        delegate.parseCustomElement(root);
    }
}

// 解析 default namespace 下面的几个元素
private void parseDefaultElement(Element ele, BeanDefinitionParserDelegate delegate) {
    if (delegate.nodeNameEquals(ele, IMPORT_ELEMENT)) {
        // 处理 <import /> 标签
        importBeanDefinitionResource(ele);
    }
    else if (delegate.nodeNameEquals(ele, ALIAS_ELEMENT)) {
        // 处理 <alias /> 标签定义
        // <alias name="fromName" alias="toName"/>
        processAliasRegistration(ele);
    }
    else if (delegate.nodeNameEquals(ele, BEAN_ELEMENT)) {
        // 处理 <bean /> 标签定义，这也算是我们的重点吧
        processBeanDefinition(ele, delegate);
    }
    else if (delegate.nodeNameEquals(ele, NESTED_BEANS_ELEMENT)) {
        // 如果碰到的是嵌套的 <beans /> 标签，需要递归
        doRegisterBeanDefinitions(ele);
    }
}

// 以解析  <bean /> 标签为例
protected void processBeanDefinition(Element ele, BeanDefinitionParserDelegate delegate) {
    // ***************
    // 将 <bean /> 节点中的信息提取出来，然后封装到一个 BeanDefinitionHolder 中，细节往下看
    // 下面这行结束后，一个 BeanDefinition 实例就出来了
    BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele);

    if (bdHolder != null) {
        // 如果有自定义属性的话，进行相应的解析，先忽略
        bdHolder = delegate.decorateBeanDefinitionIfRequired(ele, bdHolder);
        try {
            // ***************
            // 我们把这步叫做 注册Bean 吧。具体见下文[registerBeanDefinition 注册Bean](#registerBeanDefinition%20注册Bean)
            BeanDefinitionReaderUtils.registerBeanDefinition(bdHolder, getReaderContext().getRegistry());
        }
        catch (BeanDefinitionStoreException ex) {
            getReaderContext().error("Failed to register bean definition with name '" +
                bdHolder.getBeanName() + "'", ele, ex);
        }
        // 注册完成后，发送事件，本文不展开说这个
        getReaderContext().fireComponentRegistered(new BeanComponentDefinition(bdHolder));
    }
}
```
- BeanDefinitionParserDelegate.java

```java
public BeanDefinitionHolder parseBeanDefinitionElement(Element ele, BeanDefinition containingBean) {
    String id = ele.getAttribute(ID_ATTRIBUTE);
    String nameAttr = ele.getAttribute(NAME_ATTRIBUTE);

    List<String> aliases = new ArrayList<String>();

    // 将 name 属性的定义按照 “逗号、分号、空格” 切分，形成一个 别名列表数组，
    // 当然，如果你不定义 name 属性的话，就是空的了
    if (StringUtils.hasLength(nameAttr)) {
        String[] nameArr = StringUtils.tokenizeToStringArray(nameAttr, MULTI_VALUE_ATTRIBUTE_DELIMITERS);
        aliases.addAll(Arrays.asList(nameArr));
    }

    String beanName = id;
    // 如果没有指定id, 那么用别名列表的第一个名字作为beanName
    if (!StringUtils.hasText(beanName) && !aliases.isEmpty()) {
        beanName = aliases.remove(0);
        if (logger.isDebugEnabled()) {
            logger.debug("No XML 'id' specified - using '" + beanName +
                "' as bean name and " + aliases + " as aliases");
        }
    }

    if (containingBean == null) {
        checkNameUniqueness(beanName, aliases, ele);
    }

    // ***************
    // 根据 <bean ...>...</bean> 中的配置创建 BeanDefinition，然后把配置中的信息都设置到实例中,
    // 细节后面细说，先知道下面这行结束后，一个 BeanDefinition 实例就出来了。
    AbstractBeanDefinition beanDefinition = parseBeanDefinitionElement(ele, beanName, containingBean);

    // 到这里，整个 <bean /> 标签就算解析结束了，一个 BeanDefinition 就形成了。
    if (beanDefinition != null) {
        // ...
        String[] aliasesArray = StringUtils.toStringArray(aliases);
        // 返回 BeanDefinitionHolder
        return new BeanDefinitionHolder(beanDefinition, beanName, aliasesArray);
    }

    return null;
}

// 根据配置创建 BeanDefinition 实例
public AbstractBeanDefinition parseBeanDefinitionElement(
      Element ele, String beanName, BeanDefinition containingBean) {

    this.parseState.push(new BeanEntry(beanName));

    String className = null;
    if (ele.hasAttribute(CLASS_ATTRIBUTE)) {
        className = ele.getAttribute(CLASS_ATTRIBUTE).trim();
    }

    try {
        String parent = null;
        if (ele.hasAttribute(PARENT_ATTRIBUTE)) {
            parent = ele.getAttribute(PARENT_ATTRIBUTE);
        }
        // 创建 BeanDefinition，然后设置类信息而已，很简单，就不贴代码了
        AbstractBeanDefinition bd = createBeanDefinition(className, parent);

        // 设置 BeanDefinition 的一堆属性，这些属性定义在 AbstractBeanDefinition 中
        // 如：scope、lazy-initialization 等
        parseBeanDefinitionAttributes(ele, beanName, containingBean, bd);
        bd.setDescription(DomUtils.getChildElementValueByTagName(ele, DESCRIPTION_ELEMENT));

        /**
        * 下面的一堆是解析 <bean>......</bean> 内部的子元素，
        * 解析出来以后的信息都放到 bd 的属性中
        */

        // 解析 <meta />
        parseMetaElements(ele, bd);
        // 解析 <lookup-method />
        parseLookupOverrideSubElements(ele, bd.getMethodOverrides());
        // 解析 <replaced-method />
        parseReplacedMethodSubElements(ele, bd.getMethodOverrides());
        // 解析 <constructor-arg />
        parseConstructorArgElements(ele, bd);
        // 解析 <property />
        parsePropertyElements(ele, bd);
        // 解析 <qualifier />
        parseQualifierElements(ele, bd);

        bd.setResource(this.readerContext.getResource());
        bd.setSource(extractSource(ele));

        return bd;
    }
    catch (ClassNotFoundException ex) {
        error("Bean class [" + className + "] not found", ele, ex);
    }
    catch (NoClassDefFoundError err) {
        error("Class that bean class [" + className + "] depends on not found", ele, err);
    }
    catch (Throwable ex) {
        error("Unexpected failure during bean definition parsing", ele, ex);
    }
    finally {
        this.parseState.pop();
    }

    return null;
}
```
</details>

#### registerBeanDefinition注册Bean

- BeanDefinitionReaderUtils.java 上文 BeanDefinitionReaderUtils.registerBeanDefinition 进行调用的

```java
public static void registerBeanDefinition(
      BeanDefinitionHolder definitionHolder, BeanDefinitionRegistry registry)
      throws BeanDefinitionStoreException {

    String beanName = definitionHolder.getBeanName();
    // ***************
    // 注册这个 Bean
    registry.registerBeanDefinition(beanName, definitionHolder.getBeanDefinition());

    // 如果还有别名的话，也要根据别名全部注册一遍，不然根据别名就会找不到 Bean 了
    String[] aliases = definitionHolder.getAliases();
    if (aliases != null) {
        for (String alias : aliases) {
            // alias -> beanName 保存它们的别名信息，这个很简单，用一个 map 保存一下就可以了，
            // 获取的时候，会先将 alias 转换为 beanName，然后再查找
            registry.registerAlias(beanName, alias);
        }
    }
}
```
- DefaultListableBeanFactory.java 注册Bean

```java
@Override
public void registerBeanDefinition(String beanName, BeanDefinition beanDefinition)
      throws BeanDefinitionStoreException {

    Assert.hasText(beanName, "Bean name must not be empty");
    Assert.notNull(beanDefinition, "BeanDefinition must not be null");

    if (beanDefinition instanceof AbstractBeanDefinition) {
        try {
            ((AbstractBeanDefinition) beanDefinition).validate();
        }
        catch (BeanDefinitionValidationException ex) {
            throw new BeanDefinitionStoreException(...);
        }
    }

    // old? 还记得 “允许 bean 覆盖” 这个配置吗？allowBeanDefinitionOverriding
    BeanDefinition oldBeanDefinition;

    // 之后会看到，所有的 Bean 注册后会放入这个 beanDefinitionMap 中
    oldBeanDefinition = this.beanDefinitionMap.get(beanName);

    // 处理重复名称的 Bean 定义的情况
    if (oldBeanDefinition != null) {
        if (!isAllowBeanDefinitionOverriding()) {
            // 如果不允许覆盖的话，抛异常
            throw new BeanDefinitionStoreException(beanDefinition.getResourceDescription())
            // ...
        }
        else if (oldBeanDefinition.getRole() < beanDefinition.getRole()) {
            // log...用框架定义的 Bean 覆盖用户自定义的 Bean 
        }
        else if (!beanDefinition.equals(oldBeanDefinition)) {
            // log...用新的 Bean 覆盖旧的 Bean
        }
        else {
            // log...用同等的 Bean 覆盖旧的 Bean，这里指的是 equals 方法返回 true 的 Bean
        }
        // 覆盖
        this.beanDefinitionMap.put(beanName, beanDefinition);
    }
    else {
        // 判断是否已经有其他的 Bean 开始初始化了.
        // 注意，"注册Bean" 这个动作结束，Bean 依然还没有初始化，我们后面会有大篇幅说初始化过程，
        // 在 Spring 容器启动的最后，会 预初始化 所有的 singleton beans
        if (hasBeanCreationStarted()) {
            // Cannot modify startup-time collection elements anymore (for stable iteration)
            synchronized (this.beanDefinitionMap) {
                this.beanDefinitionMap.put(beanName, beanDefinition);
                List<String> updatedDefinitions = new ArrayList<String>(this.beanDefinitionNames.size() + 1);
                updatedDefinitions.addAll(this.beanDefinitionNames);
                updatedDefinitions.add(beanName);
                this.beanDefinitionNames = updatedDefinitions;
                if (this.manualSingletonNames.contains(beanName)) {
                    Set<String> updatedSingletons = new LinkedHashSet<String>(this.manualSingletonNames);
                    updatedSingletons.remove(beanName);
                    this.manualSingletonNames = updatedSingletons;
                }
            }
        }
        else {
            // 最正常的应该是进到这个分支。

            // 将 BeanDefinition 放到这个 map 中，这个 map 保存了所有的 BeanDefinition
            this.beanDefinitionMap.put(beanName, beanDefinition);
            // 这是个 ArrayList，所以会按照 bean 配置的顺序保存每一个注册的 Bean 的名字
            this.beanDefinitionNames.add(beanName);
            // 这是个 LinkedHashSet，代表的是手动注册的 singleton bean，这不是重点。
            // 手动指的是通过调用 registerSingleton(String beanName, Object singletonObject) 册的 bean
            // Spring 会在 refresh#prepareBeanFactory 中"手动"注册一些 Bean，如 "environment"、"systemProperties" 等 bean
            // 我们自己也可以在运行时注册 Bean 到容器中的
            this.manualSingletonNames.remove(beanName);
        }
        // 这个不重要，在预初始化的时候会用到，不必管它。
        this.frozenBeanDefinitionNames = null;
    }

    if (oldBeanDefinition != null || containsSingleton(beanName)) {
        resetBeanDefinition(beanName);
    }
}
```

### Bean容器实例化完成后

- prepareBeanFactory 准备 Bean 容器
- finishBeanFactoryInitialization 初始化所有的 singleton beans
    - preInstantiateSingletons 开始初始化
        - getBean 获取或创建Bean
            - createBean 创建Bean

#### prepareBeanFactory准备Bean容器

```java
protected void prepareBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    // 设置 BeanFactory 的类加载器，我们知道 BeanFactory 需要加载类，也就需要类加载器，
    // 这里设置为加载当前 ApplicationContext 类的类加载器
    beanFactory.setBeanClassLoader(getClassLoader());

    // 设置 BeanExpressionResolver
    beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()));
    beanFactory.addPropertyEditorRegistrar(new ResourceEditorRegistrar(this, getEnvironment()));

    // 添加一个 BeanPostProcessor，这个 processor 比较简单：
    // 实现了 Aware 接口的 beans 在初始化的时候，这个 processor 负责回调，
    // 这个我们很常用，如我们会为了获取 ApplicationContext 而 implement ApplicationContextAware
    // 注意：它不仅仅回调 ApplicationContextAware，还会负责回调 EnvironmentAware、ResourceLoaderAware 等，看下源码就清楚了
    beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));

    // 下面几行的意思就是，如果某个 bean 依赖于以下几个接口的实现类，在自动装配的时候忽略它们，
    // Spring 会通过其他方式来处理这些依赖。
    beanFactory.ignoreDependencyInterface(EnvironmentAware.class);
    beanFactory.ignoreDependencyInterface(EmbeddedValueResolverAware.class);
    beanFactory.ignoreDependencyInterface(ResourceLoaderAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class);
    beanFactory.ignoreDependencyInterface(MessageSourceAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationContextAware.class);

    /**
    * 下面几行就是为特殊的几个 bean 赋值，如果有 bean 依赖了以下几个，会注入这边相应的值，
    * 之前我们说过，"当前 ApplicationContext 持有一个 BeanFactory"，这里解释了第一行。
    * ApplicationContext 还继承了 ResourceLoader、ApplicationEventPublisher、MessageSource
    * 所以对于这几个依赖，可以赋值为 this，注意 this 是一个 ApplicationContext
    * 那这里怎么没看到为 MessageSource 赋值呢？那是因为 MessageSource 被注册成为了一个普通的 bean
    */
    beanFactory.registerResolvableDependency(BeanFactory.class, beanFactory);
    beanFactory.registerResolvableDependency(ResourceLoader.class, this);
    beanFactory.registerResolvableDependency(ApplicationEventPublisher.class, this);
    beanFactory.registerResolvableDependency(ApplicationContext.class, this);

    // 这个 BeanPostProcessor 也很简单，在 bean 实例化后，如果是 ApplicationListener 的子类，
    // 那么将其添加到 listener 列表中，可以理解成：注册 事件监听器
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));

    // 这里涉及到特殊的 bean，名为：loadTimeWeaver，这不是我们的重点，忽略它
    // tips: ltw 是 AspectJ 的概念，指的是在运行期进行织入，这个和 Spring AOP 不一样，
    //    感兴趣的读者请参考我写的关于 AspectJ 的另一篇文章 https://www.javadoop.com/post/aspectj
    if (beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        // Set a temporary ClassLoader for type matching.
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }

    /**
    * 从下面几行代码我们可以知道，Spring 往往很 "智能" 就是因为它会帮我们默认注册一些有用的 bean，
    * 我们也可以选择覆盖
    */

    // 如果没有定义 "environment" 这个 bean，那么 Spring 会 "手动" 注册一个
    if (!beanFactory.containsLocalBean(ENVIRONMENT_BEAN_NAME)) {
        beanFactory.registerSingleton(ENVIRONMENT_BEAN_NAME, getEnvironment());
    }
    // 如果没有定义 "systemProperties" 这个 bean，那么 Spring 会 "手动" 注册一个
    if (!beanFactory.containsLocalBean(SYSTEM_PROPERTIES_BEAN_NAME)) {
        beanFactory.registerSingleton(SYSTEM_PROPERTIES_BEAN_NAME, getEnvironment().getSystemProperties());
    }
    // 如果没有定义 "systemEnvironment" 这个 bean，那么 Spring 会 "手动" 注册一个
    if (!beanFactory.containsLocalBean(SYSTEM_ENVIRONMENT_BEAN_NAME)) {
        beanFactory.registerSingleton(SYSTEM_ENVIRONMENT_BEAN_NAME, getEnvironment().getSystemEnvironment());
    }
}
```

#### finishBeanFactoryInitialization初始化所有的singleton-beans

- 到目前为止，应该说 BeanFactory 已经创建完成，并且所有的实现了 BeanFactoryPostProcessor 接口的 Bean 都已经初始化并且其中的 postProcessBeanFactory(factory) 方法已经得到回调执行了。而且 Spring 已经“手动”注册了一些特殊的 Bean，如 environment、systemProperties 等
- AbstractApplicationContext.java

```java
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
    // 首先，初始化名字为 conversionService 的 Bean
    // 注意了，初始化的动作包装在 beanFactory.getBean(...) 中，这里先不说细节，先往下看吧
    if (beanFactory.containsBean(CONVERSION_SERVICE_BEAN_NAME) &&
            beanFactory.isTypeMatch(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class)) {
        beanFactory.setConversionService(
            beanFactory.getBean(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class));
    }

    // Register a default embedded value resolver if no bean post-processor
    // (such as a PropertyPlaceholderConfigurer bean) registered any before:
    // at this point, primarily for resolution in annotation attribute values.
    if (!beanFactory.hasEmbeddedValueResolver()) {
        beanFactory.addEmbeddedValueResolver(new StringValueResolver() {
            @Override
            public String resolveStringValue(String strVal) {
            return getEnvironment().resolvePlaceholders(strVal);
            }
        });
    }

    // 先初始化 LoadTimeWeaverAware 类型的 Bean
    // 之前也说过，这是 AspectJ 相关的内容，放心跳过吧
    String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
    for (String weaverAwareName : weaverAwareNames) {
        getBean(weaverAwareName);
    }

    // Stop using the temporary ClassLoader for type matching.
    beanFactory.setTempClassLoader(null);

    // 没什么别的目的，因为到这一步的时候，Spring 已经开始预初始化 singleton beans 了，
    // 肯定不希望这个时候还出现 bean 定义解析、加载、注册。
    beanFactory.freezeConfiguration();

    // ***************
    // 开始初始化
    beanFactory.preInstantiateSingletons();
}
```

#### preInstantiateSingletons开始初始化

- DefaultListableBeanFactory.java

```java
@Override
public void preInstantiateSingletons() throws BeansException {
    if (this.logger.isDebugEnabled()) {
        this.logger.debug("Pre-instantiating singletons in " + this);
    }
    // this.beanDefinitionNames 保存了所有的 beanNames
    List<String> beanNames = new ArrayList<String>(this.beanDefinitionNames);

    // ***下面这个循环，触发所有的非懒加载的 singleton beans 的初始化操作***
    for (String beanName : beanNames) {

        // 合并父 Bean 中的配置，<bean id="" class="" parent="" /> 中的 parent 用的不多
        RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);

        // 非抽象、非懒加载的 singletons。如果配置了 'abstract = true'，那是不需要初始化的
        if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
            // 处理 FactoryBean
            if (isFactoryBean(beanName)) {
                // FactoryBean 的话，在 beanName 前面加上 ‘&’ 符号。再调用 getBean(见下文)
                final FactoryBean<?> factory = (FactoryBean<?>) getBean(FACTORY_BEAN_PREFIX + beanName);
                // 判断当前 FactoryBean 是否是 SmartFactoryBean 的实现，此处忽略，直接跳过
                boolean isEagerInit;
                if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
                    isEagerInit = AccessController.doPrivileged(new PrivilegedAction<Boolean>() {
                        @Override
                        public Boolean run() {
                            return ((SmartFactoryBean<?>) factory).isEagerInit();
                        }
                    }, getAccessControlContext());
                }
                else {
                    isEagerInit = (factory instanceof SmartFactoryBean &&
                            ((SmartFactoryBean<?>) factory).isEagerInit());
                }
                if (isEagerInit) {
                    getBean(beanName);
                }
            }
            else {
                // ***************
                // 对于普通的 Bean，只要调用 getBean(beanName) 这个方法就可以进行初始化了(见下文)
                getBean(beanName);
            }
        }
    }

    // ***到这里说明所有的非懒加载的 singleton beans 已经完成了初始化***
    // 如果我们定义的 bean 是实现了 SmartInitializingSingleton 接口的，那么在这里得到回调，忽略
    for (String beanName : beanNames) {
        Object singletonInstance = getSingleton(beanName);
        if (singletonInstance instanceof SmartInitializingSingleton) {
            final SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
            if (System.getSecurityManager() != null) {
                AccessController.doPrivileged(new PrivilegedAction<Object>() {
                    @Override
                    public Object run() {
                        smartSingleton.afterSingletonsInstantiated();
                        return null;
                    }
                }, getAccessControlContext());
            }
            else {
                smartSingleton.afterSingletonsInstantiated();
            }
        }
    }
}
```

#### getBean获取或创建Bean

- AbstractBeanFactory.java

```java
@Override
public Object getBean(String name) throws BeansException {
   return doGetBean(name, null, null, false);
}

// 我们在剖析初始化 Bean 的过程，但是 getBean 方法我们经常是用来从容器中获取 Bean 用的，注意切换思路，
// 已经初始化过了就从容器中直接返回，否则就先初始化再返回
@SuppressWarnings("unchecked")
protected <T> T doGetBean(
      final String name, final Class<T> requiredType, final Object[] args, boolean typeCheckOnly)
      throws BeansException {
    // 获取一个 “正统的” beanName，处理两种情况
    // 一个是前面说的 FactoryBean(前面带 ‘&’)，
    // 一个是别名问题，因为这个方法是 getBean，获取 Bean 用的，你要是传一个别名进来，是完全可以的
    final String beanName = transformedBeanName(name);

    // 注意跟着这个，这个是返回值
    Object bean; 

    // 检查下是不是已经创建过了
    Object sharedInstance = getSingleton(beanName);

    // 这里说下 args 呗，虽然看上去一点不重要。前面我们一路进来的时候都是 getBean(beanName)，
    // 所以 args 传参其实是 null 的，但是如果 args 不为空的时候，那么意味着调用方不是希望获取 Bean，而是创建 Bean
    if (sharedInstance != null && args == null) {
        if (logger.isDebugEnabled()) {
            if (isSingletonCurrentlyInCreation(beanName)) {
                logger.debug("...");
            }
            else {
                logger.debug("Returning cached instance of singleton bean '" + beanName + "'");
            }
        }
        // 下面这个方法：如果是普通 Bean 的话，直接返回 sharedInstance，
        // 如果是 FactoryBean 的话，返回它创建的那个实例对象
        bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
    }

    else {
        if (isPrototypeCurrentlyInCreation(beanName)) {
            // 创建过了此 beanName 的 prototype 类型的 bean，那么抛异常，
            // 往往是因为陷入了循环引用
            throw new BeanCurrentlyInCreationException(beanName);
        }

        // 检查一下这个 BeanDefinition 在容器中是否存在
        BeanFactory parentBeanFactory = getParentBeanFactory();
        if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
            // 如果当前容器不存在这个 BeanDefinition，试试父容器中有没有
            String nameToLookup = originalBeanName(name);
            if (args != null) {
                // 返回父容器的查询结果
                return (T) parentBeanFactory.getBean(nameToLookup, args);
            }
            else {
                // No args -> delegate to standard getBean method.
                return parentBeanFactory.getBean(nameToLookup, requiredType);
            }
        }

        if (!typeCheckOnly) {
            // typeCheckOnly 为 false，将当前 beanName 放入一个 alreadyCreated 的 Set 集合中。
            markBeanAsCreated(beanName);
        }

        /*
        * 稍稍总结一下：
        * 到这里的话，要准备创建 Bean 了，对于 singleton 的 Bean 来说，容器中还没创建过此 Bean；
        * 对于 prototype 的 Bean 来说，本来就是要创建一个新的 Bean。
        */
        try {
            final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
            checkMergedBeanDefinition(mbd, beanName, args);

            // 先初始化依赖的所有 Bean，这个很好理解。
            // 注意，这里的依赖指的是 depends-on 中定义的依赖
            String[] dependsOn = mbd.getDependsOn();
            if (dependsOn != null) {
                for (String dep : dependsOn) {
                    // 检查是不是有循环依赖，这里的循环依赖和我们前面说的循环依赖又不一样，这里肯定是不允许出现的，不然要乱套了，读者想一下就知道了
                    if (isDependent(beanName, dep)) {
                        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                "Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
                    }
                    // 注册一下依赖关系
                    registerDependentBean(dep, beanName);
                    // 先初始化被依赖项
                    getBean(dep);
                }
            }

            // 如果是 singleton scope 的，创建 singleton 的实例
            if (mbd.isSingleton()) {
                sharedInstance = getSingleton(beanName, new ObjectFactory<Object>() {
                    @Override
                    public Object getObject() throws BeansException {
                        try {
                            // ***************
                            // 执行创建 Bean，详情后面再说
                            return createBean(beanName, mbd, args);
                        }
                        catch (BeansException ex) {
                            destroySingleton(beanName);
                            throw ex;
                        }
                    }
                });
                bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
            }

            // 如果是 prototype scope 的，创建 prototype 的实例
            else if (mbd.isPrototype()) {
                // It's a prototype -> create a new instance.
                Object prototypeInstance = null;
                try {
                    beforePrototypeCreation(beanName);
                    // 执行创建 Bean
                    prototypeInstance = createBean(beanName, mbd, args);
                }
                finally {
                    afterPrototypeCreation(beanName);
                }
                bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
            }

            // 如果不是 singleton 和 prototype 的话，需要委托给相应的实现类来处理
            else {
                String scopeName = mbd.getScope();
                final Scope scope = this.scopes.get(scopeName);
                if (scope == null) {
                    throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
                }
                try {
                    Object scopedInstance = scope.get(beanName, new ObjectFactory<Object>() {
                        @Override
                        public Object getObject() throws BeansException {
                            beforePrototypeCreation(beanName);
                            try {
                                // 执行创建 Bean
                                return createBean(beanName, mbd, args);
                            }
                            finally {
                                afterPrototypeCreation(beanName);
                            }
                        }
                    });
                    bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                }
                catch (IllegalStateException ex) {
                    throw new BeanCreationException(beanName,
                            "Scope '" + scopeName + "' is not active for the current thread; consider " +
                            "defining a scoped proxy for this bean if you intend to refer to it from a singleton",
                            ex);
                }
            }
        }
        catch (BeansException ex) {
            cleanupAfterBeanCreationFailure(beanName);
            throw ex;
        }
    }

    // 最后，检查一下类型对不对，不对的话就抛异常，对的话就返回了
    if (requiredType != null && bean != null && !requiredType.isInstance(bean)) {
        try {
            return getTypeConverter().convertIfNecessary(bean, requiredType);
        }
        catch (TypeMismatchException ex) {
            if (logger.isDebugEnabled()) {
                logger.debug("Failed to convert bean '" + name + "' to required type '" +
                    ClassUtils.getQualifiedName(requiredType) + "'", ex);
            }
            throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
        }
    }
    return (T) bean;
}
```

#### createBean创建Bean

- AbstractAutowireCapableBeanFactory.java 在Bean属性赋值时，可自动对 @Autowired 注解的属性注入属性值

```java
@Override
protected Object createBean(String beanName, RootBeanDefinition mbd, Object[] args) throws BeanCreationException {
    if (logger.isDebugEnabled()) {
        logger.debug("Creating instance of bean '" + beanName + "'");
    }
    RootBeanDefinition mbdToUse = mbd;

    // 确保 BeanDefinition 中的 Class 被加载
    Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
    if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
        mbdToUse = new RootBeanDefinition(mbd);
        mbdToUse.setBeanClass(resolvedClass);
    }

    // 准备方法覆写，这里又涉及到一个概念：MethodOverrides，它来自于 bean 定义中的 <lookup-method /> 
    // 和 <replaced-method />，如果读者感兴趣，回到 bean 解析的地方看看对这两个标签的解析
    try {
        mbdToUse.prepareMethodOverrides();
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(),
                beanName, "Validation of method overrides failed", ex);
    }

    try {
        // 让 InstantiationAwareBeanPostProcessor 在这一步有机会返回代理，更多可了解AOP相关原理
        Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
        if (bean != null) {
            return bean; 
        }
    }
    catch (Throwable ex) {
        throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName,
                "BeanPostProcessor before instantiation of bean failed", ex);
    }

    // ***************
    // 重头戏，创建 bean
    Object beanInstance = doCreateBean(beanName, mbdToUse, args);
    if (logger.isDebugEnabled()) {
        logger.debug("Finished creating instance of bean '" + beanName + "'");
    }
    return beanInstance;
}

// 创建 bean
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final Object[] args)
      throws BeanCreationException {

    // Instantiate the bean.
    BeanWrapper instanceWrapper = null;
    if (mbd.isSingleton()) {
        instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
    }
    if (instanceWrapper == null) {
        // ***************
        // 说明不是 FactoryBean，这里实例化 Bean，这里非常关键，细节之后再说
        instanceWrapper = createBeanInstance(beanName, mbd, args);
    }
    // 这个就是 Bean 里面的 我们定义的类 的实例，很多地方我直接描述成 "bean 实例"
    final Object bean = (instanceWrapper != null ? instanceWrapper.getWrappedInstance() : null);
    // 类型
    Class<?> beanType = (instanceWrapper != null ? instanceWrapper.getWrappedClass() : null);
    mbd.resolvedTargetType = beanType;

    // 建议跳过吧，涉及接口：MergedBeanDefinitionPostProcessor
    synchronized (mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
                // MergedBeanDefinitionPostProcessor，这个我真不展开说了，直接跳过吧，很少用的
                applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            }
            catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Post-processing of merged bean definition failed", ex);
            }
            mbd.postProcessed = true;
        }
    }

    // Eagerly cache singletons to be able to resolve circular references
    // even when triggered by lifecycle interfaces like BeanFactoryAware.
    // 下面这块代码是为了解决循环依赖的问题
    boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
            isSingletonCurrentlyInCreation(beanName));
    if (earlySingletonExposure) {
        if (logger.isDebugEnabled()) {
            logger.debug("Eagerly caching bean '" + beanName +
                "' to allow for resolving potential circular references");
        }
        addSingletonFactory(beanName, new ObjectFactory<Object>() {
            @Override
            public Object getObject() throws BeansException {
                return getEarlyBeanReference(beanName, mbd, bean);
            }
        });
    }

    // Initialize the bean instance.
    Object exposedObject = bean;
    try {
        // ***************
        // 这一步也是非常关键的，这一步负责属性装配，因为前面的实例只是实例化了，并没有设值，这里就是设值
        // 包含对 @Autowired 注解的属性注入属性值
        populateBean(beanName, mbd, instanceWrapper);
        if (exposedObject != null) {
            // ***************
            // 还记得 init-method 吗？还有 InitializingBean 接口？还有 BeanPostProcessor 接口？
            // 这里就是处理 bean 初始化完成后的各种回调，具体参考[initializeBean处理回调](#initializeBean处理回调)
            exposedObject = initializeBean(beanName, exposedObject, mbd);
        }
    }
    catch (Throwable ex) {
        if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
            throw (BeanCreationException) ex;
        }
        else {
            throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
        }
    }

    if (earlySingletonExposure) {
        Object earlySingletonReference = getSingleton(beanName, false);
        if (earlySingletonReference != null) {
            if (exposedObject == bean) {
                exposedObject = earlySingletonReference;
            }
            else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
                String[] dependentBeans = getDependentBeans(beanName);
                Set<String> actualDependentBeans = new LinkedHashSet<String>(dependentBeans.length);
                for (String dependentBean : dependentBeans) {
                    if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                        actualDependentBeans.add(dependentBean);
                    }
                }
                if (!actualDependentBeans.isEmpty()) {
                    throw new BeanCurrentlyInCreationException(beanName,
                        "Bean with name '" + beanName + "' has been injected into other beans [" +
                        StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
                        "] in its raw version as part of a circular reference, but has eventually been " +
                        "wrapped. This means that said other beans do not use the final version of the " +
                        "bean. This is often the result of over-eager type matching - consider using " +
                        "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
                }
            }
        }
    }

    // Register bean as disposable.
    try {
        registerDisposableBeanIfNecessary(beanName, bean, mbd);
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
    }

    return exposedObject;
}
```

#### createBeanInstance创建Bean实例

- AbstractAutowireCapableBeanFactory.java

```java
protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, Object[] args) {
    // 确保已经加载了此 class
    Class<?> beanClass = resolveBeanClass(mbd, beanName);

    // 校验一下这个类的访问权限
    if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                "Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
    }

    if (mbd.getFactoryMethodName() != null)  {
        // 采用工厂方法实例化，注意，不是 FactoryBean
        return instantiateUsingFactoryMethod(beanName, mbd, args);
    }

    // 如果不是第一次创建，比如第二次创建 prototype bean。
    // 这种情况下，我们可以从第一次创建知道，采用无参构造函数，还是构造函数依赖注入 来完成实例化
    boolean resolved = false;
    boolean autowireNecessary = false;
    if (args == null) {
        synchronized (mbd.constructorArgumentLock) {
            if (mbd.resolvedConstructorOrFactoryMethod != null) {
                resolved = true;
                autowireNecessary = mbd.constructorArgumentsResolved;
            }
        }
    }
    if (resolved) {
        if (autowireNecessary) {
            // 构造函数依赖注入
            return autowireConstructor(beanName, mbd, null, null);
        }
        else {
            // 无参构造函数
            return instantiateBean(beanName, mbd);
        }
    }

    // 判断是否采用有参构造函数
    Constructor<?>[] ctors = determineConstructorsFromBeanPostProcessors(beanClass, beanName);
    if (ctors != null ||
            mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_CONSTRUCTOR ||
            mbd.hasConstructorArgumentValues() || !ObjectUtils.isEmpty(args))  {
        // 构造函数依赖注入
        return autowireConstructor(beanName, mbd, ctors, args);
    }

    // 调用无参构造函数
    return instantiateBean(beanName, mbd);
}

// 调用无参构造函数
protected BeanWrapper instantiateBean(final String beanName, final RootBeanDefinition mbd) {
    try {
        Object beanInstance;
        final BeanFactory parent = this;
        if (System.getSecurityManager() != null) {
            beanInstance = AccessController.doPrivileged(new PrivilegedAction<Object>() {
                @Override
                public Object run() {
                    return getInstantiationStrategy().instantiate(mbd, beanName, parent);
                }
            }, getAccessControlContext());
        }
        else {
            // ***************
            // 实例化
            beanInstance = getInstantiationStrategy().instantiate(mbd, beanName, parent);
        }
        // 包装一下，返回
        BeanWrapper bw = new BeanWrapperImpl(beanInstance);
        initBeanWrapper(bw);
        return bw;
    }
    catch (Throwable ex) {
        throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Instantiation of bean failed", ex);
    }
}
```
- SimpleInstantiationStrategy.java

```java
@Override
public Object instantiate(RootBeanDefinition bd, String beanName, BeanFactory owner) {
    // 如果不存在方法覆写，那就使用 java 反射进行实例化，否则使用 CGLIB,
    // 方法覆写 请参考 lookup-method 和 replaced-method
    if (bd.getMethodOverrides().isEmpty()) {
        Constructor<?> constructorToUse;
        synchronized (bd.constructorArgumentLock) {
            constructorToUse = (Constructor<?>) bd.resolvedConstructorOrFactoryMethod;
            if (constructorToUse == null) {
                final Class<?> clazz = bd.getBeanClass();
                if (clazz.isInterface()) {
                    throw new BeanInstantiationException(clazz, "Specified class is an interface");
                }
                try {
                    if (System.getSecurityManager() != null) {
                        constructorToUse = AccessController.doPrivileged(new PrivilegedExceptionAction<Constructor<?>>() {
                            @Override
                            public Constructor<?> run() throws Exception {
                                return clazz.getDeclaredConstructor((Class[]) null);
                            }
                        });
                    }
                    else {
                        constructorToUse = clazz.getDeclaredConstructor((Class[]) null);
                    }
                    bd.resolvedConstructorOrFactoryMethod = constructorToUse;
                }
                catch (Throwable ex) {
                    throw new BeanInstantiationException(clazz, "No default constructor found", ex);
                }
            }
        }
        // 利用构造方法进行实例化
        return BeanUtils.instantiateClass(constructorToUse);
    }
    else {
        // 存在方法覆写，利用 CGLIB 来完成实例化，需要依赖于 CGLIB 生成子类，这里就不展开了。
        // tips: 因为如果不使用 CGLIB 的话，存在 override 的情况 JDK 并没有提供相应的实例化支持
        return instantiateWithMethodInjection(bd, beanName, owner);
    }
}
```

#### populateBean注入Bean属性

- AbstractAutowireCapableBeanFactory.java

```java
protected void populateBean(String beanName, RootBeanDefinition mbd, BeanWrapper bw) {
    // bean 实例的所有属性都在这里了
    PropertyValues pvs = mbd.getPropertyValues();

    if (bw == null) {
        if (!pvs.isEmpty()) {
            throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
        }
        else {
            // Skip property population phase for null instance.
            return;
        }
    }

    // 到这步的时候，bean 实例化完成（通过工厂方法或构造方法），但是还没开始属性设值，
    // InstantiationAwareBeanPostProcessor 的实现类可以在这里对 bean 进行状态修改，
    // 我也没找到有实际的使用，所以我们暂且忽略这块吧
    boolean continueWithPropertyPopulation = true;
    if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof InstantiationAwareBeanPostProcessor) {
                InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                // 如果返回 false，代表不需要进行后续的属性设值，也不需要再经过其他的 BeanPostProcessor 的处理
                if (!ibp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
                    continueWithPropertyPopulation = false;
                    break;
                }
            }
        }
    }

    if (!continueWithPropertyPopulation) {
        return;
    }

    if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME ||
            mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
        MutablePropertyValues newPvs = new MutablePropertyValues(pvs);

        // 通过名字找到所有属性值，如果是 bean 依赖，先初始化依赖的 bean。记录依赖关系
        if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME) {
            autowireByName(beanName, mbd, bw, newPvs);
        }

        // 通过类型装配。复杂一些
        if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
            autowireByType(beanName, mbd, bw, newPvs);
        }

        pvs = newPvs;
    }

    boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
    boolean needsDepCheck = (mbd.getDependencyCheck() != RootBeanDefinition.DEPENDENCY_CHECK_NONE);

    if (hasInstAwareBpps || needsDepCheck) {
        PropertyDescriptor[] filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
        if (hasInstAwareBpps) {
            for (BeanPostProcessor bp : getBeanPostProcessors()) {
                if (bp instanceof InstantiationAwareBeanPostProcessor) {
                    InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                    // 这里有个非常有用的 BeanPostProcessor 进到这里: AutowiredAnnotationBeanPostProcessor
                    // 对采用 @Autowired、@Value 注解的依赖进行设值，这里的内容也是非常丰富的，不过本文不会展开说了，感兴趣的读者请自行研究
                    pvs = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
                    if (pvs == null) {
                        return;
                    }
                }
            }
        }
        if (needsDepCheck) {
            checkDependencies(beanName, mbd, filteredPds, pvs);
        }
    }
    // 设置 bean 实例的属性值
    applyPropertyValues(beanName, mbd, bw, pvs);
}
```

#### initializeBean处理回调

- AbstractAutowireCapableBeanFactory.java

```java
protected Object initializeBean(final String beanName, final Object bean, RootBeanDefinition mbd) {
    if (System.getSecurityManager() != null) {
        AccessController.doPrivileged(new PrivilegedAction<Object>() {
            @Override
            public Object run() {
                invokeAwareMethods(beanName, bean);
                return null;
            }
        }, getAccessControlContext());
    }
    else {
        // 如果 bean 实现了 BeanNameAware、BeanClassLoaderAware 或 BeanFactoryAware 接口，回调
        invokeAwareMethods(beanName, bean);
    }

    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        // ***BeanPostProcessor 的 postProcessBeforeInitialization 回调***
        // 这个方法接受的第一个参数是 bean 实例，第二个参数是 bean 的名字，重点在返回值将会作为新的 bean 实例，所以，没事的话这里不能随便返回个 null
        // BeanPostProcessor 的两个回调都发生在此方法，只不过中间处理了 init-Method
        // 在 bean 实例化完成、属性注入完成之后，首先会回调几个实现了 Aware 接口的 bean
        // 再调用 postProcessBeforeInitialization - init-Method - postProcessAfterInitialization
        wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
    }

    try {
        // ***处理 bean 中定义的 init-method***
        // 或者如果 bean 实现了 InitializingBean 接口，调用 afterPropertiesSet() 方法
        invokeInitMethods(beanName, wrappedBean, mbd);
    }
    catch (Throwable ex) {
        throw new BeanCreationException(
                (mbd != null ? mbd.getResourceDescription() : null),
                beanName, "Invocation of init method failed", ex);
    }

    if (mbd == null || !mbd.isSynthetic()) {
        // ***BeanPostProcessor 的 postProcessAfterInitialization 回调***
        wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }
    return wrappedBean;
}
```

## 基于AnnotationConfigApplicationContext执行流程

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

// 3.注册(AbstractApplicationContext#refresh)，参考上文[refresh方法概览](#refresh方法概览)
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
            // 3.2
            // Allows post-processing of the bean factory in context subclasses.
            postProcessBeanFactory(beanFactory);

            // 3.3 调用工厂处理器注册bean(此处并没有实例化)到上下文中
            // Invoke factory processors registered as beans in the context.
            invokeBeanFactoryPostProcessors(beanFactory);

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
    // 3.3.1 使用 ConfigurationClassParser 解析配置类(实际是进行扫描包)
    parser.parse(candidates);
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

    // 3.3.1.1 基于 basePackages 扫描bean
    return scanner.doScan(StringUtils.toStringArray(basePackages));
}

// 3.3.1.1 基于 basePackages 扫描bean
protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
    Assert.notEmpty(basePackages, "At least one base package must be specified");
    Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<>();
    for (String basePackage : basePackages) {
        // 获取包下的所有Bean
        Set<BeanDefinition> candidates = findCandidateComponents(basePackage);
        for (BeanDefinition candidate : candidates) {
            ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(candidate);
            candidate.setScope(scopeMetadata.getScopeName());
            String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
            if (candidate instanceof AbstractBeanDefinition) {
                postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
            }
            if (candidate instanceof AnnotatedBeanDefinition) {
                // 处理bean修饰符，如注解@Lazy/@Primary，将对应状态设置到BeanDefinition中
                AnnotationConfigUtils.processCommonDefinitionAnnotations((AnnotatedBeanDefinition) candidate);
            }
            // 验证bean是否能符合后面实例化的要求，如没有和其他bean冲突
            if (checkCandidate(beanName, candidate)) {
                BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(candidate, beanName);
                definitionHolder =
                        AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
                beanDefinitions.add(definitionHolder);
                // **注册到registry中**，调用 BeanDefinitionReaderUtils.registerBeanDefinition
                registerBeanDefinition(definitionHolder, this.registry);
            }
        }
    }
    return beanDefinitions;
}
```

## 说明

### id 和 name

- 每个 Bean 在 Spring 容器中都有一个唯一的名字（beanName）和 0 个或多个别名（aliases）。获取Bean `beanFactory.getBean("beanName or alias");`

```xml
<!-- 配置的结果就是：beanName 为 messageService，别名有 3 个，分别为 m1、m2、m3 -->
<bean id="messageService" name="m1, m2, m3" class="com.javadoop.example.MessageServiceImpl">

<!-- 此配置的结果就是：beanName 为 m1，别名有 2 个，分别为 m2、m3 -->
<bean name="m1, m2, m3" class="com.javadoop.example.MessageServiceImpl" />

<!-- beanName 为：com.javadoop.example.MessageServiceImpl#0；别名 1 个，为： com.javadoop.example.MessageServiceImpl -->
<bean class="com.javadoop.example.MessageServiceImpl">

<!-- beanName 为 messageService，没有别名 -->
<bean id="messageService" class="com.javadoop.example.MessageServiceImpl">
```

### BeanDefinition 接口定义说明

- BeanFactory 是 Bean 容器，那么 Bean 又是什么呢？
    - 这里的 BeanDefinition 就是我们所说的 Spring 的 Bean，我们自己定义的各个 Bean 其实会转换成一个个 BeanDefinition 存在于 Spring 的 BeanFactory 中
    - 所以，如果有人问你 Bean 是什么的时候，你要知道 Bean 在代码层面上可以简单认为是 BeanDefinition 的实例
    - BeanDefinition 中保存了我们的 Bean 信息，比如这个 Bean 指向的是哪个类、是否是单例的、是否懒加载、这个 Bean 依赖了哪些 Bean 等等
- BeanDefinition

```java
public interface BeanDefinition extends AttributeAccessor, BeanMetadataElement {
    // 我们可以看到，默认只提供 sington 和 prototype 两种，
    // 很多读者可能知道还有 request, session, globalSession, application, websocket 这几种，
    // 不过，它们属于基于 web 的扩展。
    String SCOPE_SINGLETON = ConfigurableBeanFactory.SCOPE_SINGLETON;
    String SCOPE_PROTOTYPE = ConfigurableBeanFactory.SCOPE_PROTOTYPE;

    // 比较不重要，直接跳过吧
    int ROLE_APPLICATION = 0;
    int ROLE_SUPPORT = 1;
    int ROLE_INFRASTRUCTURE = 2;

    // 设置父 Bean，这里涉及到 bean 继承，不是 java 继承
    // 一句话就是：继承父 Bean 的配置信息而已
    void setParentName(String parentName);
    // 获取父 Bean
    String getParentName();

    // 设置 Bean 的类名称，将来是要通过反射来生成实例的
    void setBeanClassName(String beanClassName);
    // 获取 Bean 的类名称
    String getBeanClassName();

    // 设置 bean 的 scope
    void setScope(String scope);
    String getScope();

    // 设置是否懒加载
    void setLazyInit(boolean lazyInit);
    boolean isLazyInit();

    // 设置该 Bean 依赖的所有的 Bean，注意，这里的依赖不是指属性依赖(如 @Autowire 标记的)，
    // 而是 depends-on="" 属性设置的值。
    void setDependsOn(String... dependsOn);
    // 返回该 Bean 的所有依赖
    String[] getDependsOn();

    // 设置该 Bean 是否可以注入到其他 Bean 中，只对根据类型注入有效，
    // 如果根据名称注入，即使这边设置了 false，也是可以的
    void setAutowireCandidate(boolean autowireCandidate);
    // 该 Bean 是否可以注入到其他 Bean 中
    boolean isAutowireCandidate();

    // 主要的。同一接口的多个实现，如果不指定名字的话，Spring 会优先选择设置 primary 为 true 的 bean
    void setPrimary(boolean primary);
    // 是否是 primary 的
    boolean isPrimary();

    // 如果该 Bean 采用工厂方法生成，指定工厂名称
    // 一句话就是：有些实例不是用反射生成的，而是用工厂模式生成的
    void setFactoryBeanName(String factoryBeanName);
    // 获取工厂名称
    String getFactoryBeanName();
    // 指定工厂类中的 工厂方法名称
    void setFactoryMethodName(String factoryMethodName);
    // 获取工厂类中的 工厂方法名称
    String getFactoryMethodName();

    // 构造器参数
    ConstructorArgumentValues getConstructorArgumentValues();

    // Bean 中的属性值，后面给 bean 注入属性值的时候会说到
    MutablePropertyValues getPropertyValues();

    // 是否 singleton
    boolean isSingleton();

    // 是否 prototype
    boolean isPrototype();

    // 如果这个 Bean 是被设置为 abstract，那么不能实例化，
    // 常用于作为 父bean 用于继承，其实也很少用......
    boolean isAbstract();

    int getRole();
    String getDescription();
    String getResourceDescription();
    BeanDefinition getOriginatingBeanDefinition();
}
```

### BeanFactoryPostProcessor和BeanPostProcessor

- BeanFactoryPostProcessor
    - **在spring的bean定义文件加载之后，Bean创建之前**，添加处理逻辑，如修改bean的定义属性
        - 也就是说，Spring允许BeanFactoryPostProcessor在容器实例化任何其它bean之前读取配置元数据，并可以根据需要进行修改，例如可以把bean的scope从singleton改为prototype，也可以把property的值给修改掉
    - 可以同时配置多个BeanFactoryPostProcessor，并通过设置'order'属性来控制各个BeanFactoryPostProcessor的执行次序
- BeanPostProcessor
    - **在spring容器实例化bean之后，在执行bean的初始化方法前后**，添加处理逻辑


### 工厂模式生成 Bean

- 请读者注意 `factory-bean` 和 `FactoryBean` 的区别。这节说的是前者，是说静态工厂或实例工厂，而后者是 Spring 中的特殊接口，代表一类特殊的 Bean
- 设计模式里，工厂方法模式分静态工厂和实例工厂
- 静态工厂

```xml
<bean id="clientService"
    class="examples.ClientService"
    factory-method="createInstance"/>
```

```java
public class ClientService {
    private static ClientService clientService = new ClientService();
    private ClientService() {}

    // 静态方法
    public static ClientService createInstance() {
        return clientService;
    }
}
```
- 实例工厂

```xml
<bean id="serviceLocator" class="examples.DefaultServiceLocator">
    <!-- inject any dependencies required by this locator bean -->
</bean>

<bean id="clientService"
    factory-bean="serviceLocator"
    factory-method="createClientServiceInstance"/>

<bean id="accountService"
    factory-bean="serviceLocator"
    factory-method="createAccountServiceInstance"/>
```

```java
public class DefaultServiceLocator {

    private static ClientService clientService = new ClientServiceImpl();

    private static AccountService accountService = new AccountServiceImpl();

    public ClientService createClientServiceInstance() {
        return clientService;
    }

    public AccountService createAccountServiceInstance() {
        return accountService;
    }
}
```

### FactoryBean

- FactoryBean参考 [spring.md#使用Spring提供的FactoryBean(工厂Bean)](/_posts/java/spring.md#使用Spring提供的FactoryBean(工厂Bean))

### ConversionService

- 像前端传过来的字符串、整数要转换为后端的 String、Integer 很容易，但是如果 controller 方法需要的是一个枚举值，或者是 Date 这些非基础类型（含基础类型包装类）值的时候，我们就可以考虑采用 ConversionService 来进行转换
- xml

```xml
<bean id="conversionService"
  class="org.springframework.context.support.ConversionServiceFactoryBean">
  <property name="converters">
    <list>
      <bean class="com.javadoop.learning.utils.StringToEnumConverterFactory"/>
    </list>
  </property>
</bean>
```
- java

```java
public class StringToDateConverter implements Converter<String, Date> {
    @Override
    public Date convert(String source) {
        try {
            return DateUtils.parseDate(source, "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "HH:mm:ss", "HH:mm");
        } catch (ParseException e) {
            return null;
        }
    }
}
```

### Bean 继承

```xml
<!-- parent bean 设置了 abstract="true" 所以它不会被实例化，child bean 继承了 parent bean 的两个属性，但是对 name 属性进行了覆写 -->
<bean id="inheritedTestBean" abstract="true" class="org.springframework.beans.TestBean">
    <property name="name" value="parent"/>
    <property name="age" value="1"/>
</bean>

<!-- child bean 会继承 scope、构造器参数值、属性值、init-method、destroy-method 等等 -->
<bean id="inheritsWithDifferentClass" class="org.springframework.beans.DerivedTestBean"
        parent="inheritedTestBean" init-method="initialize">
    <property name="name" value="override"/>
</bean>
```

### 方法注入

- 一般来说，我们的应用中大多数的 Bean 都是 singleton 的。singleton 依赖 singleton，或者 prototype 依赖 prototype 都很好解决，直接设置属性依赖就可以了
- 但是，如果是 singleton 依赖 prototype 呢？这个时候不能用属性依赖，因为如果用属性依赖的话，我们每次其实拿到的还是第一次初始化时候的 bean
    - 一种常用的解决方案就是不要用属性依赖，每次获取依赖的 bean 的时候从 BeanFactory 中取
    - 另一种解决方案就是这里要介绍的通过使用 Lookup method

## 执行顺序

- @PostConstruct
- ApplicationContextAware#setApplicationContext




---

参考文章

[^1]: https://javadoop.com/post/spring-ioc (Spring IOC 容器源码分析)

