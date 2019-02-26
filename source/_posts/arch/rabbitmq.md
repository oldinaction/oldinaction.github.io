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
    - VirtualHost：在RabbitMQ中可以虚拟消息服务器VirtualHost，每个VirtualHost相当月一个相对独立的RabbitMQ服务器，每个VirtualHost之间是相互隔离的。exchange、queue、message不能互通。VirtualName一般以/开头

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
```

## 后台管理

- 激活Rabbit MQ's Management Plugin(可激活管理插件)
  - CMD进入RabbitMQ安装目录，进入到rabbitmq_server-3.6.5/sbin目录
  - 运行 `rabbitmq-plugins.bat enable rabbitmq_management`
- 登录管理后台
  - `http://localhost:15672` 使用`guest/guest`登录(需要激活rabbitmq_management)
- 添加virtual host：Admin - Virtual Hosts - Add a new virtual host - 输入名称如`/vhost_aezocn_test`
- 给某用户设置权限：Admin - Users - 选择某用户 - Set permission - 选择Virtual Host，其他一般为`.*`














----
