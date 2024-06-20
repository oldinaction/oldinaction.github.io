---
layout: "post"
title: "面试手册"
date: "2021-08-31 19:28"
categories: java
tags: [concurrence]
---

## 简介

- [Java面试+学习指南](https://javaguide.cn/)

## OS

### 计算机底层知识

- [计算机底层知识.md](/_posts/linux/计算机底层知识.md)
- CPU 的基本组成
- 三级缓存和伪共享
- 乱序执行与防止指令重排
- 进程/线程/纤程
- 中断
- 内存的分页装入、虚拟地址、软硬件结合寻址
- nio包中的ByteBuffer和FileChannel.map的读写
- BIO、NIO、多路复用器
- Netty

### 其他

- TCP三次握手和四次挥手
- HTTPS

## JAVA

### JVM

- [jvm.md](/_posts/java/jvm.md)
- Class File Format
- 关于对象
    - 类加载过程
    - 对象头
- 运行时数据区
- 常用指令
- 垃圾回收器
    - 分代模型
    - 垃圾查找算法
    - 垃圾清除算法
    - 常见的垃圾回收器
- JVM调优
- jvm常用配置

### 多线程

- [concurrence.md](/_posts/java/concurrence.md)
- 线程的几种状态和进行状态切换的相关方法
- wait()和sleep()的区别
- 几个锁相关的概念
- synchronized
    - 加锁方式
    - synchronized锁升级流程
    - synchronized实现细节
- volitail的作用
- CAS
    - 实现
    - ABA问题
- AQS
    - VarHandle
- ReentrantLock与synchronized区别
- ThreadLocal
    - 内部为什么要使用弱引用
- 整体谈谈容器
- ThreadPoolExecutor的7个参数
- Disruptor

### 设计模式

- [design-pattern.md](/_posts/arch/design-pattern.md)
- 口诀
- 创建型
- 结构型
- 行为型

### Zookeeper

- [zookeeper.md](/_posts/arch/zookeeper.md)
- ZooKeeper特点
- 数据模型
- 角色及相关端口
- Zab协议
    - Zab协议主要功能：消息广播、崩溃恢复、数据同步的实现原理
- CAP理论
- 分布式锁实现

### MQ

- [rabbitmq.md](/_posts/arch/rabbitmq.md)
    - 消息队列的作用
    - 消息模型
    - 如何保证消息幂等
    - RabbitMQ如何保证消息不丢失
    - 如何保证消息的顺序
    - 关于RabbitMQ的数据堆积问题
    - https://cloud.tencent.com/developer/article/1816305
- kafka
    - Kafka场景应用
    - 通信模式
    - 关于消息的顺序性
    - 工作流程分析
        - 发送数据
        - 保存数据
        - 消费数据

### Spring

- Spring AOP的底层实现
    - jdk动态代理和cglib动态代理实现的区别

### SpringCloud

### Dubbo

- https://developer.aliyun.com/article/808571

## DB

### Redis

- [redis.md](/_posts/db/redis.md)
- 数据结构
- 常用命令
- 使用场景
    - 点赞数、评论数、抢购、秒杀
    - 分布式锁
    - 统计一段时间的活跃用户数
    - 发布订阅
- 事物
- 数据有效期设置，及过期方式、过期策略
- 持久化方式
- 集群模式
- 分区方式
- 击穿、穿透、雪崩
- 双写一致性问题

### Mysql

- 三范式
- VARCHAR(20)与VARCHAR(200)的区别
- mysql事物
    - AICD
    - 脏读、不可重复读、幻读
    - 隔离级别
- Mysql日志原理
- mysql锁机制
- 索引相关
    - mysql索引类型
    - mysql索引匹配方式
    - 什么是回表(innodb、myisam)
        - 如何减少回表
    - mysql索引采用的数据结构
        - innodb为什么不选择其他树
    - innodb更新数据时两阶段提交的过程
        - 为什么要分两阶段提交
    - innodb刷新数据到磁盘有哪几种方式(innodb_flush_log_at_trx_commit)

## 算法

## 大数据

## Devops

## WEB

- vue的生命周期

## 面试题

- JAVA 中堆和栈的区别，说下java 的内存机制
a.基本数据类型比变量和对象的引用都是在栈分配的
b.堆内存用来存放由new创建的对象和数组
c.类变量（static修饰的变量），程序在一加载的时候就在堆中为类变量分配内存，堆中的内存地址存放在栈中
d.实例变量：当你使用java关键字new的时候，系统在堆中开辟并不一定是连续的空间分配给变量，是根据零散的堆内存地址，通过哈希算法换算为一长串数字以表征这个变量在堆中的”物理位置”,实例变量的生命周期–当实例变量的引用丢失后，将被GC（垃圾回收器）列入可回收“名单”中，但并不是马上就释放堆中内存
e.局部变量: 由声明在某方法，或某代码段里（比如for循环），执行到它的时候在栈中开辟内存，当局部变量一但脱离作用域，内存立即释放（释放的是变量和对象的引用，此时堆内存中new出的对象就丢失了变量的引用，在堆中分配的内存，由Java虚拟机的自动垃圾回收器来管理。）

- JVM调优
    - -Xms256m -Xmx512m -XX:PermSize=256m -XX:MaxPermSize=512m


- IOC反射，AOP动态代理

- jdk动态代理和cglib动态代理实现的区别
Spring的两种代理方式：JDK动态代理和CGLIB动态代理
1、jdk动态代理生成的代理类和委托类实现了相同的接口；
2、cglib动态代理中生成的字节码更加复杂，生成的代理类是委托类的子类，且不能处理被final关键字修饰的方法；
3、jdk采用反射机制调用委托类的方法，cglib采用类似索引的方式直接调用委托类方法；

- Spring的`BeanFactory`和`FactoryBean`区别 https://www.cnblogs.com/aspirant/p/9082858.html


- 数据库悲观锁/乐观锁，hibernate/mybatis对其实现
https://www.cnblogs.com/lr393993507/p/5909804.html
https://chenzhou123520.iteye.com/blog/1860954
https://chenzhou123520.iteye.com/blog/1863407
