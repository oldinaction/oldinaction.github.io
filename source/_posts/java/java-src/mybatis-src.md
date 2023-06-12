---
layout: "post"
title: "Mybatis源码解析"
date: "2020-11-13 22:13"
categories: [java]
tags: [mybatis, src]
---

## 简介

- [深入剖析 MyBatis 核心原理](https://learn.lianglianglee.com/%E4%B8%93%E6%A0%8F/%E6%B7%B1%E5%85%A5%E5%89%96%E6%9E%90%20MyBatis%20%E6%A0%B8%E5%BF%83%E5%8E%9F%E7%90%86-%E5%AE%8C)

## 类

![mybatis-class.webp](/data/images/java/mybatis-class.webp)

- org.apache.ibatis.session
    - `Configuration` **全局配置类**
    - `SqlSession` 数据库连接Session接口
        - `DefaultSqlSession` 包含部分方法如下
            - insert 基于update实现
            - update
            - select
            - delete
            - commit
            - rollback
    - SqlSessionFactory 从流中读取mapper并初始化
    - SqlSessionFactoryBuilder 参考下文org.apache.ibatis.builder，主要是创建SqlSessionFactory
    - SqlSessionManager 实现了 SqlSessionFactory 和 SqlSession
- builder
    - `XMLMapperBuilder` 编译xml类型mapper，保存到Configuration
    - `MapperAnnotationBuilder` 编译注解类型mapper，保存到Configuration
- executor
    - `BaseExecutor` 抽象类
        - `SimpleExecutor`
    - `BaseStatementHandler` 抽象的Statement处理器，有以下3中不同类型的执行器
        - `SimpleStatementHandler`
        - `PreparedStatementHandler`
        - `CallableStatementHandler`
- reflection
    - `Reflector` 获取实体的Get/Set方法(会和字段类型做对应)并缓存

## 入口

```java
String resource = "mybatis-config.xml";
InputStream inputStream = Resources.getResourceAsStream(resource);
SqlSessionFactory sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
SqlSession sqlSession = sqlSessionFactory.openSession();
List list = sqlSession.selectList("cn.aezo.TestMapper.select");
```

- 关于SqlSessionFactory的初始化(会读取配置文件)
    - 手动实现
        - 通过 mybatis 原生API创建 **SqlSessionFactory**: `new SqlSessionFactoryBuilder().build()` (配置文件中需要配置数据源)
        - 基于 mybatis-spring 提供的 SqlSessionFactory 创建bean (数据源由spring提供)
            - 通过@Bean定义返回`new org.mybatis.spring.SqlSessionFactoryBean();` 在执行getObject()返回对象时，会执行其buildSqlSessionFactory方法进行构建
            - 此时需要自己设置 Interceptor、DatabaseIdProvider 等属性
            - 还需定义一个 SqlSessionTemplate 的bean
    - 通过 mybatis-spring-boot-starter 的自动装配
        - 在 **MybatisAutoConfiguration**#sqlSessionFactory 中定义的 **SqlSessionFactoryBean**
        - 且包含了@ConditionalOnMissingBean注解，即优先使用自定义的
    - 基于mybatis-plus的自动装配(mybatis-plus-boot-starter)
        - 在 **MybatisPlusAutoConfiguration**#sqlSessionFactory 中定义的 **MybatisSqlSessionFactoryBean**
        - 且包含了@ConditionalOnMissingBean，即优先使用自定义的
        - 如果使用mybatis-plus, 则无需引入mybatis-spring-boot-starter; 如果引入两个，得看new SqlSessionFactory是谁的，从而决定执行MapperProxy还是MybatisMapperProxy代理对象

## mybatis

### sql-xml文件解析

- mybatis + mybatis-spring-boot-starter 类似 mybatis-plus 的初始化
- mybatis-plus会在初始化自身时进行sql xml文件扫描并解析，参考[mybatis-plus初始化](#mybatis-plus初始化)

```java
// 每个sql xml文件会实例化一个 XMLMapperBuilder 进行解析
public class XMLMapperBuilder extends BaseBuilder {

    public void parse() {
        if (!configuration.isResourceLoaded(resource)) {
            // 基于 XPathParser 进行xml节点获取
            // 获取 <mapper namespace="cn.aezo.test.TestMapper"></mapper> 节点
            configurationElement(parser.evalNode("/mapper"));
            configuration.addLoadedResource(resource);
            // 绑定 Namespace，即绑定mapper接口
            bindMapperForNamespace();
        }

        parsePendingResultMaps();
        parsePendingCacheRefs();
        parsePendingStatements();
    }

    private void bindMapperForNamespace() {
        String namespace = builderAssistant.getCurrentNamespace();
        if (namespace != null) {
            Class<?> boundType = null;
            try {
                boundType = Resources.classForName(namespace);
            } catch (ClassNotFoundException e) {
                // ignore, bound type is not required
            }
            if (boundType != null && !configuration.hasMapper(boundType)) {
                // Spring may not know the real resource name so we set a flag
                // to prevent loading again this resource from the mapper interface
                // look at MapperAnnotationBuilder#loadXmlResource
                configuration.addLoadedResource("namespace:" + namespace);
                // 将mapper接口通过 MapperProxy 包装并注册到 MapperRegistry 中
                // 在执行 testMapper.selectById("1") 时，实际是调用 MapperProxy 代理对象
                // ***如果使用 mybatis-plus，则此configuration为plus自定义的MybatisConfiguration，此时是包装一个 MybatisMapperProxy 代理对象，并注册到MybatisMapperRegistry中，从而最终调用的是 MybatisMapperProxy
                configuration.addMapper(boundType);
            }
        }
    }
}
```

### SQL语句执行流程

```java
public class DefaultSqlSession implements SqlSession {
    // ...

    @Override
    public <E> List<E> selectList(String statement, Object parameter, RowBounds rowBounds) {
        try {
            // configuration见下文 Configuration 类，如果集成了 mybatis-plus 则包装一层 MybatisConfiguration
            MappedStatement ms = configuration.getMappedStatement(statement);
            return executor.query(ms, wrapCollection(parameter), rowBounds, Executor.NO_RESULT_HANDLER);
        } catch (Exception e) {
            throw ExceptionFactory.wrapException("Error querying database.  Cause: " + e, e);
        } finally {
            ErrorContext.instance().reset();
        }
    }

    // ...
    @Override
    public int update(String statement, Object parameter) {
        try {
            dirty = true;
            // 从Configuration中获取映射信息。如：statement=cn.aezo.mapper.BasicMaintenanceMapper.updateById
            MappedStatement ms = configuration.getMappedStatement(statement);
            // 1.执行
            return executor.update(ms, wrapCollection(parameter));
        } catch (Exception e) {
            throw ExceptionFactory.wrapException("Error updating database.  Cause: " + e, e);
        } finally {
            ErrorContext.instance().reset();
        }
    }
}
```

- SimpleExecutor

```java
@Override
public int doUpdate(MappedStatement ms, Object parameter) throws SQLException {
    Statement stmt = null;
    try {
        Configuration configuration = ms.getConfiguration();
        // 1.1 实例化 StatementHandler (获取sql语句模板)
        StatementHandler handler = configuration.newStatementHandler(this, ms, parameter, RowBounds.DEFAULT, null, null);
        // 获取数据连接，进行数据预设
        stmt = prepareStatement(handler, ms.getStatementLog());
        // 执行
        return handler.update(stmt);
    } finally {
        closeStatement(stmt);
    }
}
```

- Configuration

```java
public StatementHandler newStatementHandler(Executor executor, MappedStatement mappedStatement, Object parameterObject, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) {
    // new RoutingStatementHandler() 判断获取普通STATEMENT、占位PREPARED、可执行CALLABLE中某一个类型
        // 在 BaseStatementHandler 实例化时，会判断是否需要调用 generateKeys 组装生成主键的 Statement
    StatementHandler statementHandler = new RoutingStatementHandler(executor, mappedStatement, parameterObject, rowBounds, resultHandler, boundSql);
    // 依次组装插件：反射获取插件类，通过 Plugin#wrap 组装代理对象
    statementHandler = (StatementHandler) interceptorChain.pluginAll(statementHandler);
    return statementHandler;
}
```

### 插件机制

- MyBatis 将插件单独分离出一个模块，位于 org.apache.ibatis.plugin 包中，在该模块中主要使用了两种设计模式：代理模式和责任链模式
- MyBatis 插件模块中最核心的接口就是 Interceptor 接口

```java
public interface Interceptor {

  // 插件实现类中需要实现的拦截逻辑
  Object intercept(Invocation invocation) throws Throwable;

  // 在该方法中会决定是否触发intercept()方法，如果有对应插件则创建代理对象，否则返回target本身
  default Object plugin(Object target) {
    return Plugin.wrap(target, this);
  }

  default void setProperties(Properties properties) {
    // 在整个MyBatis初始化过程中用来初始化该插件的方法
  }
}
```
- 代理对象

```java
public class Plugin implements InvocationHandler {
  // 判断是否需要创建代理对象(即是否需要拦截)
  public static Object wrap(Object target, Interceptor interceptor) {
    // 获取自定义Interceptor实现类上的@Signature注解信息，
    // 这里的getSignatureMap()方法会解析@Signature注解，得到要拦截的类以及要拦截的方法集合
    Map<Class<?>, Set<Method>> signatureMap = getSignatureMap(interceptor);
    Class<?> type = target.getClass();
    // 检查当前传入的target对象是否为@Signature注解要拦截的类型，如果是的话，就
    // 使用JDK动态代理的方式创建代理对象
    Class<?>[] interfaces = getAllInterfaces(type, signatureMap);
    if (interfaces.length > 0) {
      // 创建JDK动态代理
      return Proxy.newProxyInstance(
          type.getClassLoader(),
          interfaces,
          // target原始对象或者已经经过前面拦截器包装之后的对象，interceptor为当前插件对象
          new Plugin(target, interceptor, signatureMap));
    }
    return target;
  }

  // 执行调用
  @Override
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
      Set<Method> methods = signatureMap.get(method.getDeclaringClass());
      // 如果当前方法需要被代理，则执行intercept()方法进行拦截处理
      if (methods != null && methods.contains(method)) {
        return interceptor.intercept(new Invocation(target, method, args));
      }
      // 如果当前方法不需要被代理，则调用target对象的相应方法
      return method.invoke(target, args);
    } catch (Exception e) {
      throw ExceptionUtil.unwrapThrowable(e);
    }
  }
  // ...
}
```
- 组装责任链

```java
// 在Configuration对象中实例化
public class InterceptorChain {

  // 后加入进去的先执行
  private final List<Interceptor> interceptors = new ArrayList<>();

  // 组装责任链
  public Object pluginAll(Object target) {
    for (Interceptor interceptor : interceptors) {
      target = interceptor.plugin(target);
    }
    return target;
  }
  // ...
}
```

### 相关类

- MappedStatement 映射对象
- 枚举
    - SqlCommandType: INSERT/UPDATE/DELETE/SELECT...
    - StatementType: STATEMENT/PREPARED/CALLABLE
    - ResultSetType: DEFAULT/FORWARD_ONLY/SCROLL_INSENSITIVE/SCROLL_SENSITIVE

## mybatis-spring-boot-autoconfigure(mybatis-spring-boot-starter)

```java
// ...
public class MybatisAutoConfiguration implements InitializingBean {
    @Bean
    @ConditionalOnMissingBean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        // ...
    }

    @Bean
    @ConditionalOnMissingBean
    public SqlSessionTemplate sqlSessionTemplate(SqlSessionFactory sqlSessionFactory) {

    }
}
```

## mybatis-spring

- mybatis可以脱离spring运行，如果整合spring则需要增加`mybatis-spring`依赖。原本入口可如上文手动定义，接入spring之后，通过定义`@MapperScan`即可自动扫描mapper注册成bean
- `@MapperScan`
    - 使用：一般在springboot主类(或任何配置类)上注解`@MapperScan({"cn.aezo.**.mapper"})`表明需要扫码的包
    - 原理参考下文源码截取
        - 主要由于@MapperScan注解上有一行`@Import({MapperScannerRegistrar.class})`，从而以`MapperScannerRegistrar`为入口对mybatis进行初始化
        - 而MapperScannerRegistrar实现了`ImportBeanDefinitionRegistrar`接口从而通过registerBeanDefinitions方法注册Bean。参考[spring.md#@Import给容器导入一个组件](/_posts/java/spring.md#@Import给容器导入一个组件)
- `SqlSessionFactoryBean` 实现接口
    - `InitializingBean` 作用是spring初始化的时候会执行(实现了InitializingBean接口的afterPropertiesSet方法)
    - `ApplicationListener` 作用是在spring容器执行的各个阶段进行监听，为了容器刷新的时候，更新sqlSessionFactory，可参考onApplicationEvent方法实现
    - `FactoryBean` 表示这个类是一个工厂bean，通常是为了给返回的类进行加工处理的，而且获取类返回的是通过getObj返回的

### mybatis-spring源码

```java
// 1.MapperScan注解中通过 @Import({MapperScannerRegistrar.class}) 进行bean注册
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE})
@Documented
@Import({MapperScannerRegistrar.class})
@Repeatable(MapperScans.class)
public @interface MapperScan {
    String[] value() default {};

    String[] basePackages() default {};

    // ...
}

public class MapperScannerRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware {

    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
        // 获取注解的属性，如 value="cn.aezo.**.mapper"、basePackages 等
        AnnotationAttributes mapperScanAttrs = AnnotationAttributes.fromMap(importingClassMetadata.getAnnotationAttributes(MapperScan.class.getName()));
        if (mapperScanAttrs != null) {
            this.registerBeanDefinitions(importingClassMetadata, mapperScanAttrs, registry, generateBaseBeanName(importingClassMetadata, 0));
        }
    }

    void registerBeanDefinitions(AnnotationMetadata annoMeta, AnnotationAttributes annoAttrs, BeanDefinitionRegistry registry, String beanName) {
        // 定义的bean类为 MapperScannerConfigurer
        BeanDefinitionBuilder builder = BeanDefinitionBuilder.genericBeanDefinition(MapperScannerConfigurer.class);
        // ...设置各种bean属性
        basePackages.addAll((Collection)Arrays.stream(annoAttrs.getStringArray("value")).filter(StringUtils::hasText).collect(Collectors.toList()));
        basePackages.addAll((Collection)Arrays.stream(annoAttrs.getStringArray("basePackages")).filter(StringUtils::hasText).collect(Collectors.toList()));
        basePackages.addAll((Collection)Arrays.stream(annoAttrs.getClassArray("basePackageClasses")).map(ClassUtils::getPackageName).collect(Collectors.toList()));
        // ...
        // 2.注册 MapperScannerConfigurer 此bean(并没有实例化)，此bean会监听spring的初始化过程，见下文
        // beanName=cn.aezo.sqbiz.core.common.entity.mp.MybatisPlusConfig#MapperScannerRegistrar#0
        registry.registerBeanDefinition(beanName, builder.getBeanDefinition());
    }
}

public class MapperScannerConfigurer
    implements BeanDefinitionRegistryPostProcessor, InitializingBean, ApplicationContextAware, BeanNameAware {
    // ...

    // 最终覆写 BeanFactoryPostProcessor 的此方法，从而进行mapper接口对应的bean的注册(上文MapperScannerRegistrar已经将没有主键的mapper接口扫描到并定义成了bean)
    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
        if (this.processPropertyPlaceHolders) {
            processPropertyPlaceHolders();
        }

        ClassPathMapperScanner scanner = new ClassPathMapperScanner(registry);
        scanner.setAddToConfig(this.addToConfig);
        scanner.setAnnotationClass(this.annotationClass);
        scanner.setMarkerInterface(this.markerInterface);
        scanner.setSqlSessionFactory(this.sqlSessionFactory);
        scanner.setSqlSessionTemplate(this.sqlSessionTemplate);
        scanner.setSqlSessionFactoryBeanName(this.sqlSessionFactoryBeanName);
        scanner.setSqlSessionTemplateBeanName(this.sqlSessionTemplateBeanName);
        scanner.setResourceLoader(this.applicationContext);
        scanner.setBeanNameGenerator(this.nameGenerator);
        scanner.setMapperFactoryBeanClass(this.mapperFactoryBeanClass);
        if (StringUtils.hasText(lazyInitialization)) {
            scanner.setLazyInitialization(Boolean.valueOf(lazyInitialization));
        }
        scanner.registerFilters();
        // 扫描包配置下的符合条件的Mapper类，进行bean注册(并没有实例化)
        // 扫描过程参考: [基于AnnotationConfigApplicationContext执行流程](/_posts/java/java-src/spring-ioc-src.md#基于AnnotationConfigApplicationContext执行流程)
        scanner.scan(
            // 如包配置 cn.aezo.**.mapper
            StringUtils.tokenizeToStringArray(this.basePackage, ConfigurableApplicationContext.CONFIG_LOCATION_DELIMITERS));
    }
}
```

- SqlSessionTemplate

```java
public class SqlSessionTemplate implements SqlSession, DisposableBean {

    // select 返回list 的情况
    @Override
    public <E> List<E> selectList(String statement, Object parameter) {
        // sqlSessionProxy 为 SqlSessionInterceptor 对象，见下文
        return this.sqlSessionProxy.selectList(statement, parameter);
    }

    private class SqlSessionInterceptor implements InvocationHandler {
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        SqlSession sqlSession = getSqlSession(SqlSessionTemplate.this.sqlSessionFactory,
            SqlSessionTemplate.this.executorType, SqlSessionTemplate.this.exceptionTranslator);
        try {
            // 最终进入 DefaultSqlSession 类中进行处理，参考下文[SQL语句执行流程](#SQL语句执行流程)
            Object result = method.invoke(sqlSession, args);
            if (!isSqlSessionTransactional(sqlSession, SqlSessionTemplate.this.sqlSessionFactory)) {
                // force commit even on non-dirty sessions because some databases require
                // a commit/rollback before calling close()
                sqlSession.commit(true);
            }
            return result;
        } catch (Throwable t) {
            Throwable unwrapped = unwrapThrowable(t);
            // ...
            throw unwrapped;
        } finally {
            if (sqlSession != null) {
                closeSqlSession(sqlSession, SqlSessionTemplate.this.sqlSessionFactory);
            }
        }
    }
  }
}
```

## mybatis-plus

### mybatis-plus初始化

#### mybatis-plus-boot-starter

- `mybatis-plus-boot-starter`模块下的`spring.factories`

```java
# Auto Configure
org.springframework.boot.env.EnvironmentPostProcessor=\
  com.baomidou.mybatisplus.autoconfigure.SafetyEncryptProcessor
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  com.baomidou.mybatisplus.autoconfigure.MybatisPlusLanguageDriverAutoConfiguration,\
  com.baomidou.mybatisplus.autoconfigure.MybatisPlusAutoConfiguration
```

#### MybatisPlusAutoConfiguration.java

- springboot自动初始化此类

```java
@Configuration
@ConditionalOnClass({SqlSessionFactory.class, SqlSessionFactoryBean.class})
@ConditionalOnSingleCandidate(DataSource.class)
@EnableConfigurationProperties({MybatisPlusProperties.class})
@AutoConfigureAfter({DataSourceAutoConfiguration.class, MybatisPlusLanguageDriverAutoConfiguration.class})
public class MybatisPlusAutoConfiguration implements InitializingBean {

    public MybatisPlusAutoConfiguration(MybatisPlusProperties properties,
        ObjectProvider<Interceptor[]> interceptorsProvider, 
        ObjectProvider<TypeHandler[]> typeHandlersProvider,
        ObjectProvider<LanguageDriver[]> languageDriversProvider, 
        ResourceLoader resourceLoader,
        ObjectProvider<DatabaseIdProvider> databaseIdProvider, 
        ObjectProvider<List<ConfigurationCustomizer>> configurationCustomizersProvider, 
        ObjectProvider<List<MybatisPlusPropertiesCustomizer>> mybatisPlusPropertiesCustomizerProvider, 
        ApplicationContext applicationContext) {
        // ...自动注入参数
    }

    // 1.初始化 SqlSessionFactory (会进行xml文件检索)；类似 mybatis-spring-boot-starter#MybatisAutoConfiguration 初始化 SqlSessionFactory
    @Bean
    @ConditionalOnMissingBean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        // 为 FactoryBean, 通过 getObject 获取 bean
        // com.baomidou.mybatisplus.extension.spring.MybatisSqlSessionFactoryBean 类似 org.mybatis.spring.SqlSessionFactoryBean
        MybatisSqlSessionFactoryBean factory = new MybatisSqlSessionFactoryBean();
        
        // 2.设置各种参数
        factory.setDataSource(dataSource);
        // 设置 mybatis 相关配置
        if (StringUtils.hasText(this.properties.getConfigLocation())) {
            factory.setConfigLocation(this.resourceLoader.getResource(this.properties.getConfigLocation()));
        }
        // 见下文，给factory设置configuration(无则初始化)
        this.applyConfiguration(factory);
        if (this.properties.getConfigurationProperties() != null) {
            factory.setConfigurationProperties(this.properties.getConfigurationProperties());
        }
        // 设置插件
        if (!ObjectUtils.isEmpty(this.interceptors)) {
            factory.setPlugins(this.interceptors);
        }
        // 设置 databaseIdProvider
        if (this.databaseIdProvider != null) {
            factory.setDatabaseIdProvider(this.databaseIdProvider);
        }
        // ...

        // ****
        // 2.1 基于 MybatisPlusProperties#mapperLocations = new String[]{"classpath*:/mapper/**/*.xml"}; 进行xml文件路径扫描
        Resource[] mapperLocations = this.properties.resolveMapperLocations();
        if (!ObjectUtils.isEmpty(mapperLocations)) {
            factory.setMapperLocations(mapperLocations);
        }

        factory.setGlobalConfig(globalConfig);
        // 3.见下文返回实际bean；会在初始化时构建factory，包含了解析初始化mapper xml等步骤
        return factory.getObject();
    }

    private void applyConfiguration(MybatisSqlSessionFactoryBean factory) {
        // TODO 使用 MybatisConfiguration
        MybatisConfiguration configuration = this.properties.getConfiguration();
        if (configuration == null && !StringUtils.hasText(this.properties.getConfigLocation())) {
            configuration = new MybatisConfiguration();
        }
        if (configuration != null && !CollectionUtils.isEmpty(this.configurationCustomizers)) {
            for (ConfigurationCustomizer customizer : this.configurationCustomizers) {
                customizer.customize(configuration);
            }
        }
        factory.setConfiguration(configuration);
    }
}
```

#### MybatisSqlSessionFactoryBean

- MybatisSqlSessionFactoryBean (构建SqlSessionFactory)

```java
public class MybatisSqlSessionFactoryBean implements FactoryBean<SqlSessionFactory>, InitializingBean, ApplicationListener<ApplicationEvent> {

    // 存放sql xml的配置文件位置
    private Resource[] mapperLocations;

    public void setMapperLocations(Resource... mapperLocations) {
        this.mapperLocations = mapperLocations;
    }

    public SqlSessionFactory getObject() throws Exception {
        if (this.sqlSessionFactory == null) {
            // 3.1 调用下文
            this.afterPropertiesSet();
        }

        return this.sqlSessionFactory;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        notNull(dataSource, "Property 'dataSource' is required");
        state((configuration == null && configLocation == null) || !(configuration != null && configLocation != null),
            "Property 'configuration' and 'configLocation' can not specified with together");
        // 3.2 构建 SqlSessionFactory
        this.sqlSessionFactory = buildSqlSessionFactory();
    }

    protected SqlSessionFactory buildSqlSessionFactory() throws Exception {
        final Configuration targetConfiguration;

        // ...
        // 当定义了 configLocation 属性，才会初始化 xmlConfigBuilder 进行 mybatis-config.xml 配置文件解析
        if (xmlConfigBuilder != null) {
            // 解析mybatis-config.xml的配置文件
            xmlConfigBuilder.parse();
        }

        // 根据配置文件初始化所以配置, 如databaseIdProvider、mapperLocations(解析mapper)

        if (xmlConfigBuilder != null) {
            // 非主要分支: 使用mybatis-plus 一般很少设置 mybatis-config.xml
            try {
                // 会解析 mybatis-config.xml > configuration > mappers > 存在一个分支(如果mapperClass存在，则调用configuration.addMapper(mapperInterface)将mapper接口通过MybatisMapperProxy包装并注册到MybatisMapperRegistry中)
                xmlConfigBuilder.parse();
                LOGGER.debug(() -> "Parsed configuration file: '" + this.configLocation + "'");
            } catch (Exception ex) {
                throw new NestedIOException("Failed to parse config resource: " + this.configLocation, ex);
            } finally {
                ErrorContext.instance().reset();
            }
        }

        // 3.3 sql xml的配置文件位置，解析mapper xml
        if (this.mapperLocations != null) {
            if (this.mapperLocations.length == 0) {
                LOGGER.warn(() -> "Property 'mapperLocations' was specified but matching resources are not found.");
            } else {
                for (Resource mapperLocation : this.mapperLocations) {
                    if (mapperLocation == null) {
                        continue;
                    }
                    try {
                        // org.apache.ibatis.builder.xml.XMLMapperBuilder
                        XMLMapperBuilder xmlMapperBuilder = new XMLMapperBuilder(mapperLocation.getInputStream(),
                            targetConfiguration, mapperLocation.toString(), targetConfiguration.getSqlFragments());
                        // 3.4 解析sql xml文件。见上文[sql-xml文件解析](#sql-xml文件解析)
                        xmlMapperBuilder.parse();
                    } catch (Exception e) {
                        throw new NestedIOException("Failed to parse mapping resource: '" + mapperLocation + "'", e);
                    } finally {
                        ErrorContext.instance().reset();
                    }
                    LOGGER.debug(() -> "Parsed mapper file: '" + mapperLocation + "'");
                }
            }
        } else {
            LOGGER.debug(() -> "Property 'mapperLocations' was not specified.");
        }

        final SqlSessionFactory sqlSessionFactory = new MybatisSqlSessionFactoryBuilder().build(targetConfiguration);

        // SqlRunner
        SqlHelper.FACTORY = sqlSessionFactory;

        // 所有配置文件初始化完成，包含了xml解析完成
        // 打印骚东西 Banner
        if (globalConfig.isBanner()) {
            System.out.println(" _ _   |_  _ _|_. ___ _ |    _ ");
            System.out.println("| | |\\/|_)(_| | |_\\  |_)||_|_\\ ");
            System.out.println("     /               |         ");
            System.out.println("                        " + MybatisPlusVersion.getVersion() + " ");
        }

        return sqlSessionFactory;
    }
}
```

#### XMLMapperBuilder

- org.apache.ibatis.builder.xml.XMLMapperBuilder
- 解析mapper xml，并将mapper接口通过MybatisMapperProxy包装并注册到MybatisMapperRegistry中
- 见上文[sql-xml文件解析](#sql-xml文件解析)

#### MybatisMapperRegistry

```java
// com.baomidou.mybatisplus.core
public class MybatisMapperRegistry extends MapperRegistry {
    private final Map<Class<?>, MybatisMapperProxyFactory<?>> knownMappers = new HashMap<>();

    @Override
    public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
        // TODO 这里换成 MybatisMapperProxyFactory 而不是 MapperProxyFactory
        final MybatisMapperProxyFactory<T> mapperProxyFactory = (MybatisMapperProxyFactory<T>) knownMappers.get(type);
        if (mapperProxyFactory == null) {
            throw new BindingException("Type " + type + " is not known to the MybatisPlusMapperRegistry.");
        }
        try {
            // 实例化代理对象(当然每次调用的时候会先判断是否有缓存此对象)
            return mapperProxyFactory.newInstance(sqlSession);
        } catch (Exception e) {
            throw new BindingException("Error getting mapper instance. Cause: " + e, e);
        }
    }

    @Override
    public <T> void addMapper(Class<T> type) {
        if (type.isInterface()) {
            if (hasMapper(type)) {
                // TODO 如果之前注入 直接返回
                return;
                // TODO 这里就不抛异常了
//                throw new BindingException("Type " + type + " is already known to the MapperRegistry.");
            }
            boolean loadCompleted = false;
            try {
                // TODO 这里也换成 MybatisMapperProxyFactory 而不是 MapperProxyFactory
                knownMappers.put(type, new MybatisMapperProxyFactory<>(type));
                // It's important that the type is added before the parser is run
                // otherwise the binding may automatically be attempted by the
                // mapper parser. If the type is already known, it won't try.
                // TODO 这里也换成 MybatisMapperAnnotationBuilder 而不是 MapperAnnotationBuilder
                MybatisMapperAnnotationBuilder parser = new MybatisMapperAnnotationBuilder(config, type);
                parser.parse();
                loadCompleted = true;
            } finally {
                if (!loadCompleted) {
                    knownMappers.remove(type);
                }
            }
        }
    }
}
```

#### MybatisConfiguration

```java
public class MybatisConfiguration extends Configuration {

    // Mapper注册器，通过addMapper进行添加(会自动将添加的mapper增加一层代理MybatisMapperProxyFactory)
    protected final MybatisMapperRegistry mybatisMapperRegistry = new MybatisMapperRegistry(this);

    protected final Map<String, MappedStatement> mappedStatements = new StrictMap<MappedStatement>("Mapped Statements collection")
        .conflictMessageProducer((savedValue, targetValue) ->
            ". please check " + savedValue.getResource() + " and " + targetValue.getResource());

    
    // 在解析每个sql xml的时候调 addMappedStatement，参考 [sql-xml文件解析](#sql-xml文件解析)
    /**
     * MybatisPlus 加载 SQL 顺序：
     * <p> 1、加载 XML中的 SQL </p>
     * <p> 2、加载 SqlProvider 中的 SQL </p>
     * <p> 3、XmlSql 与 SqlProvider不能包含相同的 SQL </p>
     * <p>调整后的 SQL优先级：XmlSql > sqlProvider > CurdSql </p>
     */
    @Override
    public void addMappedStatement(MappedStatement ms) {
        // MappedStatement.resource 为java类或xml文件路径(即定义sql的文件)
        logger.debug("addMappedStatement: " + ms.getId());
        if (mappedStatements.containsKey(ms.getId())) {
            /*
             * 说明已加载了xml中的节点； 忽略mapper中的 SqlProvider 数据
             */
            logger.error("mapper[" + ms.getId() + "] is ignored, because it exists, maybe from xml file");
            return;
        }
        mappedStatements.put(ms.getId(), ms);
    }

    @Override
    public <T> void addMapper(Class<T> type) {
        mybatisMapperRegistry.addMapper(type);
    }
}
```

### 查询流程

```java
// testMapper基于mybatis-plus定义，**在spring-ioc实例化时注入的是 MybatisMapperProxy 代理对象**
// 仅mybatis环境，则最终调用 MapperProxy 代理对象
// 1.入口
testMapper.selectById("1");

// 2.从 org.apache.ibatis.binding.MapperProxy 复制到mybatis-plus中的类
// mybatis-plus 3.0.6 是基于 PageMapperMethod 实现
// mybatis-plus 3.4.2 是基于 MybatisMapperMethod 实现
public class MybatisMapperProxy<T> implements InvocationHandler, Serializable {
    // ...

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        try {
            if (Object.class.equals(method.getDeclaringClass())) {
                return method.invoke(this, args);
            } else {
                // 3.一般在此处判断是否有缓存此方法(mapper实现)，并进行调用
                return cachedInvoker(method)
                    // 4.反射进行调用
                    .invoke(proxy, method, args, sqlSession);
            }
        } catch (Throwable t) {
            throw ExceptionUtil.unwrapThrowable(t);
        }
    }

    // 3.1 获取mapper方法实现
    private MapperMethodInvoker cachedInvoker(Method method) throws Throwable {
        try {
            // CollectionUtils.computeIfAbsent如果有缓存则返回缓存方法实现，如果无缓存则加入缓存并返回此方法
            // methodCache 缓存的方法，第一次调用时为空
            return CollectionUtils.computeIfAbsent(methodCache, method, 
                // 没有缓存则通过此lambda进行定义
                m -> {
                    // 是否为接口的默认方法(jdk1.8特性)
                    if (m.isDefault()) {
                        try {
                            if (privateLookupInMethod == null) {
                                return new DefaultMethodInvoker(getMethodHandleJava8(method));
                            } else {
                                return new DefaultMethodInvoker(getMethodHandleJava9(method));
                            }
                        } catch (IllegalAccessException | InstantiationException | InvocationTargetException
                            | NoSuchMethodException e) {
                            throw new RuntimeException(e);
                        }
                    } else {
                        // 3.1.1 一般会进入此处返回此方法实现，PlainMethodInvoker 和 MybatisMapperMethod 见下文的定义
                        return new PlainMethodInvoker(new MybatisMapperMethod(mapperInterface, method, sqlSession.getConfiguration()));
                    }
                });
        } catch (RuntimeException re) {
            Throwable cause = re.getCause();
            throw cause == null ? re : cause;
        }
    }

    interface MapperMethodInvoker {
        Object invoke(Object proxy, Method method, Object[] args, SqlSession sqlSession) throws Throwable;
    }
    
    private static class PlainMethodInvoker implements MapperMethodInvoker {
        private final MybatisMapperMethod mapperMethod;
        
        public PlainMethodInvoker(MybatisMapperMethod mapperMethod) {
            super();
            this.mapperMethod = mapperMethod;
        }
        
        // 4.1 调用mapper方法实现(执行sql)
        @Override
        public Object invoke(Object proxy, Method method, Object[] args, SqlSession sqlSession) throws Throwable {
            return mapperMethod.execute(sqlSession, args);
        }
    }

    // ...
}

// mybatis-plus 3.0.6 是基于 PageMapperMethod 实现
// mybatis-plus 3.4.2 是基于 MybatisMapperMethod 实现
public class MybatisMapperMethod {
    public Object execute(SqlSession sqlSession, Object[] args) {
        Object result;
        switch (command.getType()) {
            // ... 省略 INSERT、UPDATE等
            case SELECT:
                if (method.returnsVoid() && method.hasResultHandler()) {
                    executeWithResultHandler(sqlSession, args);
                    result = null;
                } else if (method.returnsMany()) {
                    // 4.2 如返回结果为List
                    result = executeForMany(sqlSession, args);
                } else if (method.returnsMap()) {
                    result = executeForMap(sqlSession, args);
                } else if (method.returnsCursor()) {
                    result = executeForCursor(sqlSession, args);
                } else {
                    // 对参数进行转换
                    Object param = method.convertArgsToSqlCommandParam(args);
                    if (IPage.class.isAssignableFrom(method.getReturnType())) {
                        result = executeForIPage(sqlSession, args);
                    } else {
                        // 和spring结合时刻参考：[mybatis-spring下的SqlSessionTemplate](#mybatis-spring源码)
                        // command.getName() = cn.aezo.sqbiz.core.party.mapper.UserOauthTokenMapper.selectById
                        result = sqlSession.selectOne(command.getName(), param);
                        if (method.returnsOptional()
                            && (result == null || !method.getReturnType().equals(result.getClass()))) {
                            result = Optional.ofNullable(result);
                        }
                    }
                }
                break;
        }
        if (result == null && method.getReturnType().isPrimitive() && !method.returnsVoid()) {
            throw new BindingException("Mapper method '" + command.getName()
                + " attempted to return null from a method with a primitive return type (" + method.getReturnType() + ").");
        }
        return result;
    }

    private <E> Object executeForMany(SqlSession sqlSession, Object[] args) {
        List<E> result;
        Object param = method.convertArgsToSqlCommandParam(args);
        // 是否有List中没行记录的映射
        if (method.hasRowBounds()) {
            RowBounds rowBounds = method.extractRowBounds(args);
            result = sqlSession.selectList(command.getName(), param, rowBounds);
        } else {
            // 4.3 如返回 List<Map> 的情况
            // 和spring结合时刻参考：[mybatis-spring下的SqlSessionTemplate](#mybatis-spring源码)
            result = sqlSession.selectList(command.getName(), param);
        }
        // issue #510 Collections & arrays support
        if (!method.getReturnType().isAssignableFrom(result.getClass())) {
            if (method.getReturnType().isArray()) {
                return convertToArray(result);
            } else {
                return convertToDeclaredCollection(sqlSession.getConfiguration(), result);
            }
        }
        return result;
    }
}
```

