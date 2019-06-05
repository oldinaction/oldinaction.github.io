---
layout: "post"
title: "Apache JMeter压力测试"
date: "2017-12-09 12:02"
categories: arch
tags: [test, apache]
---

## 简介

- Apache JMeter是Apache组织开发的基于Java的压力测试工具。用于对软件做压力测试，它最初被设计用于Web应用测试，但后来扩展到其他测试领域。 它可以用于测试静态和动态资源，例如静态文件、Java 小服务程序、CGI 脚本、Java 对象、数据库、FTP 服务器， 等等
- 官网：[http://jmeter.apache.org/](http://jmeter.apache.org/)
- 推荐文档：[菜鸟入门到进阶](https://www.cnblogs.com/imyalost/p/7062784.html) [^1]

### 安装运行

- 到[http://jmeter.apache.org/download_jmeter.cgi](http://jmeter.apache.org/download_jmeter.cgi)下载二进制文件apache-jmeter-3.3.zip解压（需要先安装JDK）
- 运行：`/bin/jmeter.bat`会出现GUI界面
- 支持中文：选项-语言

## 基础概念

### 组成部分

- 负载发生器：产生负载，多进程或多线程模拟用户行为
- 用户运行器：脚本运行引擎，用户运行器附加在进程或线程上，根据脚本模拟指定的用户行为
- 资源生成器：生成测试过程中服务器、负载机的资源数据
- 报表生成器：根据测试中获得的数据生成报表，提供可视化的数据显示方式

### 核心组件

- 测试计划（Test Plan）：描述一个性能测试，包含本次测试所有相关功能
- Threads（users）线程
    - Thread group：通常添加使用的线程，一般一个线程组可看做一个虚拟用户组，其中每个线程为一个虚拟用户
    - Setup thread group：一种特殊类型的线程，可用于执行预测试操作。即执行测试前进行定期线程组的执行
    - Teardown thread group：执行测试后的动作
- 测试片段（Test Fragment）
- 控制器：取样器（Sampler）和逻辑控制器（Logic Controller），用这些原件驱动处理一个测试
    - 取样器（Sampler）：是性能测试中向服务器发送请求，记录响应信息，记录响应时间的最小单元，JMeter 原生支持多种不同的sampler。如 HTTP Request Sampler 、 FTP  Request Sampler 、TCP  Request Sampler 、JDBC Request Sampler 等
    - 逻辑控制器（Logic Controller），包含两类原件
        - 一类是控制Test Plan中Sampler节点发送请求的逻辑顺序控制器，常用的有：If Controller、Swith Controller、Loop Controller、Random Controller等
        - 另一类是用来组织和控制Sampler节点的，如Transaction Controller、Throughput Controller等
- 监听器（Listener）：对测试结果进行处理和可视化展示的一系列组件，常用的有图形结果、查看结果树、聚合报告等

### 其他组件




---

参考文章

[^1]: https://www.cnblogs.com/imyalost/p/7062784.html (jmeter：菜鸟入门到进阶)


