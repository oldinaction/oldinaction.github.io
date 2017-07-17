---
layout: "post"
title: "RocketMQ"
date: "2016-07-11 09:26"
categories: middleware
tags: [mq, alibaba]
---

* 目录
{:toc}

## RocketMQ简介

- RocketMQ是阿里巴巴开源的分布式、队列模型的消息中间件。
- [【GitHub源码】](https://github.com/alibaba/RocketMQ) [【下载地址(v3.2.6)】](https://github.com/alibaba/RocketMQ/releases/download/v3.2.6/alibaba-rocketmq-3.2.6.tar.gz)
- 文档：[RocketMQ Developer Guide.pdf](/data/doc/middleware/RocketMQ Developer Guide.pdf)

## 启动RocketMQ服务

1. 启动mqnamesrv.exe（在bin目录下，也有对应Linux的启动程序）
2. 启动mqbroker.exe
	- 最好不要直接双击，而是应该在CMD中输入`mqbroker.exe -n localhost:9876`
	- `mqbroker.exe -h`查看相关命令帮助

> 关于命令行
>
> 1. 可启动mqadmin.exe查看相关命令（不能直接双击，要在cmd命令行中启动）
>   - 启动mqadmin.exe后可运行一些命令，如`mqadmin topicList -n 192.168.0.1:9876`查看该NameServer所有的topic
>   - 可运行`mqadmin help 命令`或者某个命令的更多帮助
>   - mqadmin.exe启动后可以新增/更新Topic（因为Broker默认关闭了自动创建Topic功能，可能会导致Producer向Broker发送消息，服务器校验不通过，[详细issure](https://github.com/alibaba/RocketMQ/issues/38)）

## Producer生产者

### Producer启动

- 一个应用创建一个Producer，由应用来维护此对象，可以设置为全局对象或者单例。
- ProducerGroupName需要由应用来保证唯一。ProducerGroup这个概念发送普通的消息时，作用不大，但是发送分布式事务消息时，比较关键，因为服务器会回查这个Group下的任意一个Producer
- Producer对象在使用之前必须要调用start初始化，初始化一次即可。可伴随应用启动而启动。切记不可以在每次发送消息时，都调用start方法
- 代码如下：
  ```java
  DefaultMQProducer producer = new DefaultMQProducer("UniqueProducerGroupName"); // 保证UniqueProducerGroupName唯一
  producer.setNamesrvAddr("127.0.0.1:9876"); // 设置NameServer地址
  producer.setInstanceName("Producer"); // 客户端实例名称
  producer.start();
	```

### Producer发送消息

```java
Message msg = new Message("TopicTest1", "TagA", "OrderID2016061001", ("Hello").getBytes());
msg.putUserProperty("orderId", "OrderID2016061001"); // 设置参数
SendResult sendResult = producer.send(msg);
System.out.println(sendResult);
```

- 此示例中实例化Message的参数分别为Topic(主题，必填唯一)、Tag(该主题下的细化类型，可选)、Key(可选唯一)、Body(消息的body)
- 一个应用尽可能用一个 Topic，消息子类型用 tags 来标识
- 如果是第一次发送/接收某主题的消息，broker中无此topic，可能会报错(No topic route info in name server for the topic:XXX，无此topic的路由信息)，第二次就不会报错。可以尝试发送消息前就将此topic加到broker中(如运行命令`mqadmin updateTopic -b 192.168.0.1:10911 -n 192.168.0.1:9876 -t NewTopicName`)

### Producer关闭

- 应用退出时，要调用shutdown来清理资源，关闭网络连接，从MetaQ(RocketMQ前身)服务器上注销自己
- 建议应用在JBOSS、Tomcat等容器的退出钩子里调用shutdown方法

```java
producer.shutdown();
```

## Consumer消费者

- 一个应用创建一个Consumer，由应用来维护此对象，可以设置为全局对象或者单例
- ConsumerGroupName需要由应用来保证唯一

```java
DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("UniqueConsumerGroupName");
consumer.setNamesrvAddr("127.0.0.1:9876");
consumer.setInstanceName("Consumber");
consumer.setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_FIRST_OFFSET); // 设置Consumer第一次启动是从队列头部开始消费还是队列尾部开始消费，如果非第一次启动，那么按照上次消费的位置继续消费
  consumer.subscribe("TopicTest1", "TagA"); // 订阅指定topic为TopicTest1下TagA类型的消息。一个consumer可订阅多个主题
  consumer.registerMessageListener(new MessageListenerConcurrently() {
      @Override
      public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs,
              ConsumeConcurrentlyContext context) {
          // 开始消费
          System.out.println(Thread.currentThread().getName() + " Receive New Messages: " + msgs);
          String orderId = msg.getUserProperty("orderId"); // 获取参数值
          return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
      }
  });
  consumer.start();
```
