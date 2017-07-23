---
layout: "post"
title: "kafka"
date: "2017-07-23 16:11"
---

## 简介

- 官网：[http://kafka.apache.org/](http://kafka.apache.org/)，当前版本`0.11.0.0`
- Kafka是有LinkedIn开发的分布式消息系统，现由Apache维护，使用Scala实现
- 安装：下载kafka_2.12-0.11.0.0.tgz解压即可。其中`bin`为shell文件，`bin/windows`为bat文件，`config`目录为配置文件

## 启动(以windows为例)

- 启动`Zookeeper`：`zookeeper-server-start ../../config/zookeeper.properties`
    - 此时需要指定zookeeper的配置文件所在路径，zookeeper默认绑定`2181`端口
- 启动`Kafka`：`kafka-server-start ../../config/server.properties`
    - `0.11.0.0`版本要java为1.8
- 创建生产者：`kafka-console-producer --broker-list localhost:9092 --topic test`
    - 此是如果没有test的`Topic`，则会自动创建(也可使用`kafka-topics`命令创建)
- 发送消息：在命令行输入消息，由于此时没有消费者，这些消息均会阻塞在名为test的`Topic`中，直到消费者将其消费掉
- 创建消费者：`kafka-console-consumer --zookeeper localhost:2181 --topic test --from-beginning`
    - 此时会看到消费者接收到了刚才发送的消息

## 其他命令

- 查看当前Kafka中的Topic：`kafka-topics --list --zookeeper localhost:2181`
