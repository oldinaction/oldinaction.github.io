---
layout: "post"
title: "kafka"
date: "2017-07-23 16:11"
categories: arch
tags: [mq]
---

## 简介

- 官网：[http://kafka.apache.org/](http://kafka.apache.org/)
- 相关文章
    - https://blog.csdn.net/weixin_45366499/article/details/106943229
- Kafka是由LinkedIn开发的分布式消息系统，现由Apache维护，使用Scala实现
- 是一个分布式、支持分区的（partition）、多副本的（replica），基于zookeeper协调的分布式消息系统，它的最大的特性就是可以实时的处理大量数据以满足各种需求场景
- 特点
    - 高吞吐量、低延迟：kafka每秒可以处理几十万条消息，它的延迟最低只有几毫秒
    - 可扩展性：kafka集群支持热扩展
    - 持久性、可靠性：消息被持久化到本地磁盘，并且支持数据备份防止数据丢失
    - 容错性：允许集群中节点失败（若副本数量为n,则允许n-1个节点失败）
    - 高并发：支持数千个客户端同时读写
- Kafka场景应用
    - 日志收集：可以用Kafka可以收集各种服务的log，通过kafka以统一接口服务的方式开放给各种consumer，例如hadoop、Hbase、Solr等
    - 消息队列：解耦和生产者和消费者、缓存消息等
    - 用户活动跟踪
    - 运营指标：Kafka也经常用来记录运营监控数据。包括收集各种分布式应用的数据，生产各种操作的集中反馈，比如报警和报告
    - 流式处理：比如spark streaming和storm
    - 事件源
- 通信模式
    - 点对点：消费者手动去取消息
    - 发布/订阅：Kafka自动推送消息给消费者
- 为什么 Kafka 是 pull 模型
    - Kafka 选择由 Producer 向 broker push 消息并由 Consumer 从 broker pull 消息
    - push 模式很难适应消费速率不同的消费者，因为消息发送速率是由 broker 决定的；而 pull 模式则可以根据 Consumer 的消费能力以适当的速率消费消息
        - 假设三个消费者处理速度分别是8M/s、5M/s、2M/s；如果队列推送的速度为5M/s，则第三个消费者扛不住，如果以2M/s则前两个消费者比较浪费资源
- 关于消息的顺序性
    - Kafka 只会保证在 Partition 内消息是有序的，而不管全局的情况
    - Kafka 中一个 topic 中的消息是被打散分配在多个 Partition(分区) 中存储的， Consumer Group 在消费时需要从不同的 Partition 获取消息，最终无法重建出 Topic 中消息的顺序
- 关于消息的有效性
    - 无论消息是否被消费，除非消息到期，Partition 从不删除消息
    - Partition 会为每个 Consumer Group 保存一个偏移量，记录 Group 消费到的位置

## 安装

- 安装(示例版本`2.12_2.2.0`)
    - 下载[kafka_2.12_2.2.0.tgz](https://www.apache.org/dyn/closer.cgi?path=/kafka/2.2.0/kafka_2.12-2.2.0.tgz)解压即可
    - 其中`bin`目录为shell文件，`bin/windows`为bat文件，`config`目录为配置文件

## 启动(以windows为例)

- 启动`Zookeeper`(kafka内置)：`bin/windows/zookeeper-server-start.bat ./config/zookeeper.properties`
    - 此时需要指定zookeeper的配置文件所在路径，zookeeper默认绑定`2181`端口
- 启动`Kafka`：`bin/windows/kafka-server-start.bat ./config/server.properties`
    - `2.2.0`版本要java为1.8
- 创建topic：`bin/windows/kafka-topics.bat --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test` (topic名为test)
- 创建生产者：`bin/windows/kafka-console-producer.bat --broker-list localhost:9092 --topic test`
    - 此是如果没有test的`Topic`，则会自动创建(也可使用`kafka-topics`命令创建)
- 发送消息：在命令行输入消息，由于此时没有消费者，这些消息均会阻塞在名为test的`Topic`中，直到消费者将其消费掉
- 创建消费者：`bin/windows/kafka-console-consumer.bat --bootstrap-server localhost:9092 --topic test --from-beginning`
    - 此时会看到消费者接收到了刚才发送的消息
    - 版本v2.12_0.11.0为`bin/windows/kafka-console-consumer.bat --zookeeper localhost:2181 --topic test --from-beginning`

## 其他命令

- 查看当前Kafka中的Topic：`kafka-topics.bat --list --zookeeper localhost:2181`






