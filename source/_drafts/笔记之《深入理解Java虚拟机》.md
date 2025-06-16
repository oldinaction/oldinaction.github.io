---
layout: "post"
title: "《深入理解Java虚拟机》读书笔记"
date: "2018-09-02 08:23"
categories: java
tags: [jvm, book]
---

## 编译JDK

- 地址
    - OpenJDK官网：`http://openjdk.java.net/install/index.html`
    - 书中下载地址：https://download.java.net/openjdk/jdk7 (地址中的下载链接有误，需要将前面的域名换掉，最终为下载地址为`http://download.java.net/openjdk/jdk7/promoted/b147/openjdk-7-fcs-src-b147-27_jun_2011.zip`)
    - 

## jvm内存分配

- 内存分配示意图

    ![jvm内存分配](/data/images/java/jvm-memory-allocation.png)

    - 不同虚拟机的对象访问方式可能不同，主要有句柄和指针来进行访问

- 堆 [^1]
    - 在32位windows的机器上，堆最大可以达到1.4G至1.6G
    - 在32位solaris的机器上，堆最大可以达到2G 
    - 而在64位的操作系统上，32位的JVM，堆大小可以达到4G 
- 栈
    - 一般说的指虚拟机栈，还有本地方法栈(调用操作系统方法)
    - 对于栈的异常，`StackOverflowError`一般出现于递归，`OutOfMemoryError`一般出现于多线程
- 方法区
    - 方法区(Method Area)和Java堆一样是线程共享的。主要用来存放类信息(类型修饰符、)、常量、静态变量、及时编译器编译后的代码。习惯上叫PermGen(永久代)，但本质上两者并不等价。
    - 由不同的类加载器实例根据同一类文件加载的类(型)也会视为不同的类(型)，哪怕是同一类型类加载器的不同实例加载的，都会在PermGen区域分配相应的空间来存储每个类(型)的信息
    - 新类型加载时，会在PermGen区域申请相应的空间来存储类型信息，类型被卸载后，PermGen区域上的垃圾收集会释放对应的内存空间
    - 一种类型被卸载的前提条件是：类对应的普通实例、类对应的java.lang.Class实例、加载此类的ClassLoader实例，三者中有任何一种或者多种是reachable(可达)状态的，那么此类型就不可能被卸载。（unreachable不可达状态. 大致可以理解为不能通过特定活动线程对应的栈出发通过引用计算来到达对应的实例）
    - jdk1.8 去除了方法区，方法区中存储的信息保存到了本地内存中(元空间)。(同时-XX:PermSize、-XX:MaxPermSize两个JVM参数作废)
    - 方法区OOM出现的常见情况有：大量JSP或动态生成JSP的应用(JSP第一次运行时需要先编译成Java类)、基于OSGi(Java动态模型系统)的应用
- 程序计数器
    - 当前线程执行字节码的指示器。如一个处理器上执行多线程程序，在切换线程时程序计数器会记录此线程上一次执行的位置。
    - 每个线程会有一个独立的程序计数器(不会出现OOM)
- 直接内存：JDK1.4后加入NIO，它可以通过Native函数库直接分配对外内存



--- 

参考文章

[^1]: http://blog.sina.com.cn/s/blog_4adc4b090102vr3a.html
