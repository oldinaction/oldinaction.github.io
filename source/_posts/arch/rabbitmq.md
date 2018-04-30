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

## RabbitMQ安装

Rabbit MQ 是建立在强大的Erlang OTP平台上，因此安装Rabbit MQ的前提是安装Erlang。通过下面两个连接下载安装3.2.3 版本：

- 安装 [Eralng OTP For Windows (vR16B03)](http://www.erlang.org/download/otp_win32_R16B03.exe)
- 安装 [RabbitMQ Server (3.6.5)](https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.5/rabbitmq-server-3.6.5.exe)
- 默认监听`5672`端口(客户端连接使用此端口)，后台使用端口`15672`

## RabbitMQ启动

- 激活Rabbit MQ's Management Plugin(可激活管理插件)
  - CMD进入RabbitMQ安装目录，进入到rabbitmq_server-3.6.5/sbin目录
  - 运行 `rabbitmq-plugins.bat enable rabbitmq_management`
- 运行 `rabbitmq-service.bat start` 启动RabbitMQ服务
- 运行 `rabbitmq-service.bat stop` 停止服务
- 查看用户
  - 运行 `rabbitmqctl.bat list_users` 查看用户(有一个guest默认用户)
- 登录管理后台
  - `http://localhost:15672` 使用guest/guest登录















----
