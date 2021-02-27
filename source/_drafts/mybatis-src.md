---
layout: "post"
title: "Mybatis源码解析"
date: "2020-11-13 22:13"
categories: [java]
tags: [mybatis, src]
---

## 类

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
    - SqlSessionFactoryBuilder
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

## 新增/修改流程分析

```java
// DefaultSqlSession
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

// 1 SimpleExecutor
@Override
public int doUpdate(MappedStatement ms, Object parameter) throws SQLException {
    Statement stmt = null;
    try {
        Configuration configuration = ms.getConfiguration();
        // 1.1 实例化 StatementHandler 
        StatementHandler handler = configuration.newStatementHandler(this, ms, parameter, RowBounds.DEFAULT, null, null);
        // 获取数据连接，进行数据预设
        stmt = prepareStatement(handler, ms.getStatementLog());
        // 执行
        return handler.update(stmt);
    } finally {
        closeStatement(stmt);
    }
}

// 1.1 Configuration
public StatementHandler newStatementHandler(Executor executor, MappedStatement mappedStatement, Object parameterObject, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) {
    // new RoutingStatementHandler() 判断获取普通STATEMENT、占位PREPARED、可执行CALLABLE中某一个类型
        // 在 BaseStatementHandler 实例化时，会判断是否需要调用 generateKeys 组装生成主键的 Statement
    StatementHandler statementHandler = new RoutingStatementHandler(executor, mappedStatement, parameterObject, rowBounds, resultHandler, boundSql);
    // 依次组装插件：反射获取插件类，通过 Plugin#wrap 组装代理对象
    statementHandler = (StatementHandler) interceptorChain.pluginAll(statementHandler);
    return statementHandler;
}
```

## mybatis-spring

### @MapperScan

- 使用：一般在springboot主类(或任何配置类)上注解`@MapperScan({"cn.aezo.**.mapper"})`表明需要扫码的包
- 原理
    - 主要由于@MapperScan注解上有一行`@Import({MapperScannerRegistrar.class})`，从而以`MapperScannerRegistrar`为入口对mybatis进行初始化
    - 而MapperScannerRegistrar实现了`ImportBeanDefinitionRegistrar`接口从而通过registerBeanDefinitions方法注册Bean。参考[spring.md#@Import给容器导入一个组件](/_posts/java/spring.md#@Import给容器导入一个组件)

### SqlSessionFactoryBean

- SqlSessionFactoryBean实现接口
    - `InitializingBean` 作用是spring初始化的时候会执行实现了InitializingBean接口的afterPropertiesSet方法
    - `ApplicationListener` 作用是在spring容器执行的各个阶段进行监听，为了容器刷新的时候，更新sqlSessionFactory，可参考onApplicationEvent方法实现
    - `FactoryBean` 表示这个类是一个工厂bean，通常是为了给返回的类进行加工处理的，而且获取类返回的是通过getObj返回的

