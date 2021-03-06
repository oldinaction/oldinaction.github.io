---
layout: "post"
title: "kafka"
date: "2017-07-23 16:11"
categories: arch
tags: [mq]
---

## 简介

- 官网：[http://kafka.apache.org/](http://kafka.apache.org/)
- Kafka是由LinkedIn开发的分布式消息系统，现由Apache维护，使用Scala实现
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






