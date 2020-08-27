---
layout: "post"
title: "RabbitMQ"
date: "2016-08-14 16:49"
categories: [arch]
tags: [mq, rabbitMQ]
---

## RabbitMQ简介

- rabbitMQ是一个在AMQP协议(高级消息队列协议)标准基础上完整的，可服用的企业消息系统。他遵循Mozilla Public License开源协议。采用 Erlang 实现的工业级的消息队列(MQ)服务器。
- RabbitMQ的官方站：http://www.rabbitmq.com/
- 相关概念
    - `Broker` 消息队列服务器实体
    - `Exchange` 消息交换机，它指定消息按什么规则，路由到哪个队列
    - `Queue` 消息队列载体，每个消息都会被投入到一个或多个队列
    - `Binding` 绑定，它的作用就是把exchange和queue按照路由规则绑定起来
    - `RoutingKey` 路由关键字，exchange根据这个关键字进行消息投递
    - `VirtualHost` 在RabbitMQ中可以虚拟消息服务器VirtualHost，每个VirtualHost相当月一个相对独立的RabbitMQ服务器，每个VirtualHost之间是相互隔离的，一个broker里可以开设多个vhost，用作不同用户的权限分离。exchange、queue、message不能互通。VirtualName一般以/开头
    - `Producer` 消息生产者，就是投递消息的程序
    - `Consumer` 消息消费者，就是接受消息的程序
    - `Channel` 消息通道，在客户端的每个连接里，可建立多个channel，每个channel代表一个会话任务
- 数据传输

    ![数据传输](/data/images/arch/rabbitmq-arch.png)

## RabbitMQ安装

Rabbit MQ 是建立在强大的Erlang OTP平台上，因此安装Rabbit MQ的前提是安装Erlang。通过下面两个连接下载安装3.2.3 版本：

- 安装 [Eralng OTP For Windows (opt21)](http://erlang.org/download/otp_win64_21.0.exe)
- 安装 [RabbitMQ Server (3.7.7)](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.7/rabbitmq-server-3.7.7.exe)
- 默认监听`5672`端口(客户端连接使用此端口)，开启后台则默认使用端口`15672`

## 相关命令

### RabbitMQ启动与停止

- 运行 `rabbitmq-service.bat start` 启动RabbitMQ服务
- 运行 `rabbitmq-service.bat stop` 停止服务

### 其他命令

```bash
## 1.添加用户并设置权限
rabbitmqctl.bat list_users # 查看用户(有一个guest默认用户)
# 添加用户和设置权限
rabbitmqctl add_user {用户名} {密码}
rabbitmqctl set_user_tags {用户名} {权限}
# 权限
# management：普通管理者
# policymaker：策略制定者
# monitoring：监控者
# administrator：超级管理员
rabbitmqctl set_permissions -p / {用户名} '.*' '.*' '.*'

# 列举所有队列
rabbitmqctl list_queues
# 清空某个队列里的数据
rabbitmqctl purge_queue <queue_name>
```

## 后台管理

- 激活Rabbit MQ's Management Plugin(可激活管理插件)
  - CMD进入RabbitMQ安装目录，进入到rabbitmq_server-3.6.5/sbin目录
  - 运行 `rabbitmq-plugins.bat enable rabbitmq_management`
- 登录管理后台
  - `http://localhost:15672` 使用`guest/guest`登录(需要激活rabbitmq_management)
- Admin
    - Users 用户管理
        - Add a user 添加用户
        - 点击用户进入详情页面
            - Permissions 和 Topic permissions 可设置用户权限
                - 选择Virtual Host，其他为`.*`表示所有权限
    - Virtual Hosts 虚拟主机管理
        - Add a new virtual host 添加虚拟主机
            - 输入名称如`/vhost_aezocn_test`，命名上 abc 和 /abc 是不同的
            - 需要先有对应的虚拟主机，客户端才能连接
        - 点击某个虚拟主机进入到详情页面
            - Permissions 和 Topic permissions 可设置用户权限，参考Users中的














----
