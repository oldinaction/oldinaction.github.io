---
layout: "post"
title: "大数据项目相关工具"
date: "2021-08-07 13:48"
categories: bigdata
tags:
---

## 相关工具说明

- `ETL`(Extract-Transform-Load，抽取-转换-存储）即在数据抽取过程中进行数据的加工转换，然后加载到存储中。常见的如Informatics和开源工具Kettle

## Flume

### Flume简介

- Apache Flume 是一个分布式、高可靠、高可用的用来收集、聚合、转移不同来源的大量日志数据到中央数据仓库的工具
- [官网](http://flume.apache.org/)、[v1.9中文文档](https://flume.liyifeng.org/)
- 相关概念
    - Event是Flume定义的一个数据流传输的最小单元
    - Agent就是一个Flume的实例，本质是一个JVM进程，该JVM进程控制Event数据流从外部日志生产者那里传输到目的地（或者是下一个Agent）
    - 当Source接收Event时，它将其存储到一个或多个channel。该channel是一个被动存储器（或者说叫存储池），可以存储Event直到它被Sink消耗
- Flume支持以下比较流行的日志类型读取：Avro(Apache Avro)、Thrift、Syslog、Netcat
- 数据流模型

    ![flume-arch.png](/data/images/bigdata/flume-arch.png)
    - 次数据流只是一种组合方式，简单的只需要一个Agent，甚至还有更复杂的组合
- 结合HDFS使用参考[bigdata-project-user-analysis.md#Flume传输日志](/_posts/bigdata/bigdata-project-user-analysis.md#Flume传输日志)

### Flume安装

```bash
cd /opt/bigdata/
wget https://ftp.jaist.ac.jp/pub/apache/flume/1.9.0/apache-flume-1.9.0-bin.tar.gz
tar -zxvf apache-flume-1.9.0-bin.tar.gz
mv apache-flume-1.9.0-bin flume-1.9.0
rm -rf flume-1.9.0/docs
# **设置环境变量 export FLUME_HOME=/opt/bigdata/flume-1.9.0 并暴露 $FLUME_HOME/bin
vi /etc/profile
source /etc/profile
# **配置flume环境 export JAVA_HOME=/usr/java/jdk1.8.0_202-amd64
cp conf/flume-env.sh.template conf/flume-env.sh && vi conf/flume-env.sh
# 执行 flume-ng 命令查看安装版本
flume-ng version
# 参考 conf/flume-conf.properties.template 创建Agent配置文件conf-file，并启动Agent
flume-ng agent --conf-file my-flume-conf.properties --name a1 -Dflume.root.logger=INFO,console
```

### 单Agent测试

- 配置文件(~/flume/test.conf)

```bash
# Name the components on this agent 名称和后面对应，其中a1为当前Agent名称，
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source 配置数据源，此处监听node01:44444(netcat，可监听telnet的数据传输)
# Source配置参考 https://flume.liyifeng.org/#flume-sources
a1.sources.r1.type = netcat # 还可以为 avro、exec(读取命令输出)、spooldir(读取目录下文件，可设置后缀等)
a1.sources.r1.bind = node01
a1.sources.r1.port = 44444

# Describe the sink 配置输出
# Sink配置参考 https://flume.liyifeng.org/#flume-sinks
a1.sinks.k1.type = logger

# Use a channel which buffers events in memory 缓存队列，transactionCapacity表示每次读取的任务数
# Channel配置参考 https://flume.liyifeng.org/#flume-channels
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel 对相关角色绑定Channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```
- 启动并测试

```bash
# node01启动，指定Agent的名称为 a1
flume-ng agent --conf-file ~/flume/test.conf --name a1 -Dflume.root.logger=INFO,console
# 在其他节点如node2上测试
# 连接后随便输入，在node01上便会打印，如`21/08/07 23:55:50 INFO sink.LoggerSink: Event: { headers:{} body: 31 32 33 0D                                     123. }`
telnet node01 44444
```

### 两个Agent连接测试

- node02配置文件(~/flume/test2.conf)

```bash
# Name the components on this agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source
a1.sources.r1.type = netcat
a1.sources.r1.bind = node02
a1.sources.r1.port = 44444

# Describe the sink 输出到 node01:10086 端口
a1.sinks.k1.type = avro
a1.sinks.k1.hostname = node01
a1.sinks.k1.port = 10086

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```
- node01配置文件(~/flume/test2.conf)

```bash
# Name the components on this agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source 监听 node01:10086 端口数据源输入
a1.sources.r1.type = avro
a1.sources.r1.bind = node01
a1.sources.r1.port = 10086

# Describe the sink
a1.sinks.k1.type = logger

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```
- 启动

```bash
# 启动 node01/node02
flume-ng agent --conf-file ~/flume/test2.conf --name a1 -Dflume.root.logger=INFO,console
# 连接node02并发送数据给node02，会发现数据打印在node01
telnet node02 44444
```




## sqoop


