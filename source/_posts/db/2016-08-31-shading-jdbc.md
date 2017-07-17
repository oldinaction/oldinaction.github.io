---
layout: "post"
title: "shading-jdbc"
date: "2016-08-31 19:13"
categories: db
tags: [shading, shading-jdbc]
---

## Shading介绍

| 功能          | Cobar         | Mycat         | Heisenberg     | TDDL          | Sharding-JDBC |
| ------------- | ------------- | ------------- | -------------- | ------------- | ------------- |
| 是否开源      | 开源          | 开源          | 开源           | 部分开源      | 开源          |
| 架构模型      | Proxy架构     | Proxy架构     | Proxy架构      | 应用集成架构  | 应用集成架构  |
| 数据库支持    | MySQL         | 任意          | 任意           | 任意          | MySQL(计划Oracle)         |
| 外围依赖      | 无            | 无            | 无             | Diamond       | 无            |
| 使用复杂度    | 一般          | 一般          | 一般           | 复杂          | 一般          |
| 技术文档支持  | 较少          | 付费          | 较少           | 无            | 一般          |
| 开源组织  | 阿里          | 社区(Cobar衍生)          | 社区(Cobar衍生)           | 阿里            | 当当          |

1. 其中TDDL是文档较少，github上代码还是4年前更新。现在TDDL已经在阿里云上架，名为DRDS(Distribute Relational Database Service 分布式关系型数据库服务)
2. 基于Proxy的架构的缺点：网络消耗会产生性能问题，并且多一个外围系统依赖就意味着需要多增加和承担一份风险

## Shading-JDBC简介

- Sharding-JDBC是当当开源的数据库分库分表中间件。Sharding-JDBC直接封装JDBC协议，可以理解为增强版的JDBC驱动，旧代码迁移成本几乎为零。Sharding-JDBC定位为轻量级java框架，使用客户端直连数据库，以jar包形式提供服务，无proxy代理层，无需额外部署，无其他依赖，DBA也无需改变原有的运维方式。
- 主要特点
  - 可适用于任何基于java的ORM框架，如：JPA, Hibernate, Mybatis, Spring JDBC Template或直接使用JDBC。
  - 理论上可支持任意实现JDBC规范的数据库。虽然目前仅支持MySQL，但已有支持Oracle，SQLServer，DB2等数据库的计划。
  - 分片策略灵活，可支持=，BETWEEN，IN等多维度分片，也可支持多分片键共用。
  - SQL解析功能完善，支持聚合，分组，排序，Limit，OR等查询，并且支持Binding Table以及笛卡尔积的表查询。
  - 支持柔性事务(目前仅完成最大努力送达型)。支持读写分离。
  - 性能高。单库查询QPS为原生JDBC的99.8%；双库查询QPS比单库增加94%。
- [GitHub源码](https://github.com/dangdangdotcom/Sharding-JDBC/) 、 [官方文档](http://dangdangdotcom.github.io/sharding-jdbc/)

## 整体架构图

![shading-jdbc架构图](/data/images/2016/08/shading-jdbc-architecture.png)

## 相关概念

### 逻辑表与实际表映射关系

配置分库分表的目的是将原有一张表的数据分散到不同库不同表中，且不改变原有SQL语句的情况下来使用这一张表。那么从一张表到多张的映射关系需要使用逻辑表与实际表这两种概念。下面通过一个例子来解释一下。假设在使用PreparedStatement访问数据库，SQL如下：

```SQL
  select * from t_order where user_id = ? and order_id = ?;
```

当`user_id=0`且`order_id=0`时，Sharding-JDBC将会将SQL语句转换为如下形式：

```SQL
select * from db0.t_order_0 where user_id = ? and order_id = ?;
```

其中原始SQL中的t_order就是逻辑表，而转换后的db0.t_order_0就是实际表。

那么，为什么当`user_id=0`且`order_id=0`时会进行这样的转换，如果当`user_id=1`且`order_id=1`时又会是什么情况？`user_id`和`order_id`这两个字段有什么特殊含义吗？

### 分片键

官方解释：分片键是分片策略的第一个参数。分片键表示的是SQL语句中WHERE中的条件列。

方言：分片键就是逻辑sql语句中的某个字段，通过某个字段(或者某几个字段)可以将逻辑sql语句转换成实际运行的sql语句。上例中的`user_id`和`order_id`就是分片键。

### 分片策略和分片算法

我将上面的分片键定义一个算法(如`user_id`对2取余`user_id % 2`的结果就是实际表的尾数，当然可以自己定义更复杂的算法)，对数据库或者表加上了如上的分片算法就属于分片策略。

## 柔性事物

- 柔性事务（遵循BASE理论）是指相对于ACID刚性事务而言的。柔性事务分为：两阶段型、补偿型、异步确保型、最大努力通知型几种。

## 其他(略)

- `CAP`理论、`ACID`、`BASE`
  - `CAP`理论

    Web服务无法同时满足以下3个属性
    - Consistency(一致性)，数据一致更新，所有数据变动都是同步的
    - Availability(可用性)，每个操作都必须以可预期的响应结束
    - Partition tolerance(分区容错性)，即使出现单个组件无法可用,操作依然可以完成

    在任何数据库设计中,一个Web应用至多只能同时支持上面的两个属性，不可能三者兼顾。对于分布式系统来说，分区容错是基本要求，所以必然要放弃一致性。对于大型网站来说， 分区容错和可用性的要求更高，所以一般都会选择适当放弃一致性。对应CAP理论，NoSQL追求的是AP，而传统数据库追求的是CA，这也可以解释为什么 传统数据库的扩展能力有限的原因。

  - `ACID`解决方案

    ACID数据库事务极大地简化了应用开发人员的工作.正如其缩写标识所示,ACID事务提供以下几种保证:
    - Atomicity（原子性），事务中的所有操作,要么全部成功,要么全部不做.
    - Consistency（一致性）在事务开始与结束时,数据库处于一致状态.
    - Isolation（隔离性） 事务如同只有这一个操作在被数据库所执行一样.
    - Durability（持久性）. 在事务结束时,此操作将不可逆转.(也就是只要事务提交,系统将保证数据不会丢失,即使出现系统Crash,译者补充).

    数据库厂商在很久以前就认识到数据库分区的必要性,并引入了一种称为2PC(两阶段提交)的技术来提供跨越多个数据库实例的ACID保证

  - `BASE`解决方案
    - Basically Available（基本可用）
    - Soft-state（ 软状态/柔性事务）
    - Eventual Consistency（最终一致性）

    BASE模型是传统ACID模型的反面，不同与ACID，BASE强调牺牲高一致性，从而获得可用性，数据允许在一段时间内的不一致，只要保证最终一致就可以了。
















> 参考文章
>
> - [sharding-jdbc Wiki] http://dangdangdotcom.github.io/sharding-jdbc/
>
> - [柔性事物] http://www.zhihu.com/question/31813039/answer/53437637
>
> - [CAP理论、ACID和BASE] http://blog.itpub.net/58054/viewspace-660826/
