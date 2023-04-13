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
    - `Configuration` 全局配置类
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

    // 最终覆写 BeanFactoryPostProcessor 的此方法
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

## mybatis

### sql-xml文件解析

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
            // 会调用 MybatisConfiguration.addMappedStatement 方法
            bindMapperForNamespace();
        }

        parsePendingResultMaps();
        parsePendingCacheRefs();
        parsePendingStatements();
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

## mybatis-plus

### mybatis-plus初始化

- `spring.factories`

```java
# Auto Configure
org.springframework.boot.env.EnvironmentPostProcessor=\
  com.baomidou.mybatisplus.autoconfigure.SafetyEncryptProcessor
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  com.baomidou.mybatisplus.autoconfigure.MybatisPlusLanguageDriverAutoConfiguration,\
  com.baomidou.mybatisplus.autoconfigure.MybatisPlusAutoConfiguration
```

- MybatisPlusAutoConfiguration.java (springboot自动初始化此类)

```java
@Configuration
@ConditionalOnClass({SqlSessionFactory.class, SqlSessionFactoryBean.class})
@ConditionalOnSingleCandidate(DataSource.class)
@EnableConfigurationProperties({MybatisPlusProperties.class})
@AutoConfigureAfter({DataSourceAutoConfiguration.class, MybatisPlusLanguageDriverAutoConfiguration.class})
public class MybatisPlusAutoConfiguration implements InitializingBean {

    // 1.初始化SqlSessionFactory(会进行xml文件检索)
    @Bean
    @ConditionalOnMissingBean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        // 为 FactoryBean, 通过 getObject 获取 bean
        MybatisSqlSessionFactoryBean factory = new MybatisSqlSessionFactoryBean();
        // 2.设置各种参数
        factory.setDataSource(dataSource);
        // ...

        // ****
        // 2.1 基于 MybatisPlusProperties#mapperLocations = new String[]{"classpath*:/mapper/**/*.xml"}; 进行xml文件路径扫描
        Resource[] mapperLocations = this.properties.resolveMapperLocations();
        if (!ObjectUtils.isEmpty(mapperLocations)) {
            factory.setMapperLocations(mapperLocations);
        }

        factory.setGlobalConfig(globalConfig);
        // 3.见下文返回实际bean
        return factory.getObject();
    }
}
```

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
        if (xmlConfigBuilder != null) {
            // 解析mybatis-config.xml的配置文件
            xmlConfigBuilder.parse();
        }

        // 3.3 sql xml的配置文件位置
        if (this.mapperLocations != null) {
            if (this.mapperLocations.length == 0) {
                LOGGER.warn(() -> "Property 'mapperLocations' was specified but matching resources are not found.");
            } else {
                for (Resource mapperLocation : this.mapperLocations) {
                    if (mapperLocation == null) {
                        continue;
                    }
                    try {
                        XMLMapperBuilder xmlMapperBuilder = new XMLMapperBuilder(mapperLocation.getInputStream(),
                            targetConfiguration, mapperLocation.toString(), targetConfiguration.getSqlFragments());
                        // 3.4 解析sql xml文件，见[sql-xml文件解析](#sql-xml文件解析)
                        // 解析完sql xml，将其添加到 MybatisConfiguration#mappedStatements，见下文
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

- MybatisConfiguration

```java
public class MybatisConfiguration extends Configuration {

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
}
```

### 查询流程

```java
// testMapper基于mybatis-plus定义，**在spring-ioc实例化时注入的是 MybatisMapperProxy 代理对象**
// 1.入口
testMapper.selectById("1");

// 2.从 org.apache.ibatis.binding.MapperProxy 复制到mybatis-plus中的类
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

