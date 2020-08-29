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
    - 也可以不用先发送给交换机，直接点对点进行传输
    - 生成者和消费者必须通过Channel向虚拟机开启一个会话
- 7种消息模型：https://www.rabbitmq.com/getstarted.html
    
    ![消息模型](/data/images/arch/rabbitmq-message-model.png)
    - 常用：点对点、work、订阅（fanout广播、direct直连、topic主题）
    - Direct直连（RouteKey固定）；Topic基于通配符（RouteKey包含通配符：*匹配一个单词，#匹配多个单词）

## RabbitMQ安装

### windows

Rabbit MQ 是建立在强大的Erlang OTP平台上，因此安装Rabbit MQ的前提是安装Erlang。通过下面两链接下载安装3.7.7版本

- 安装 [Eralng OTP For Windows (opt21)](http://erlang.org/download/otp_win64_21.0.exe)
- 安装 [RabbitMQ Server (3.7.7)](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.7/rabbitmq-server-3.7.7.exe)
- **默认监听`5672`端口(客户端连接使用此端口)，开启后台则默认使用端口`15672`，默认超级管理员`guest/guest`**

### linux

```bash
## 安装erlang。安装成功后可执行`erl`测试
yum install erlang

## 安装rabbitmq
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.7/rabbitmq-server-generic-unix-3.8.7.tar.xz
tar -xvf rabbitmq-server-generic-unix-3.8.7.tar.xz -C /opt/
echo 'export PATH=$PATH:/opt/rabbitmq_server-3.8.7/sbin' >> /etc/profile
source /etc/profile
# 添加web管理插件
rabbitmq-plugins enable rabbitmq_management

## 后台启动rabbitmq服务
rabbitmq-server -detached
 


# centos8则为.../el/8/
cat > /etc/yum.repos.d/erlang.repo << EOF
[rabbitmq-erlang]
name=rabbitmq-erlang
baseurl=https://dl.bintray.com/rabbitmq-erlang/rpm/erlang/21/el/7
gpgcheck=1
gpgkey=https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc
repo_gpgcheck=0
enabled=1
EOF
yum install erlang -y

```

## 相关命令

### RabbitMQ启动与停止

- windows
    - `rabbitmq-service start` 启动RabbitMQ服务
    - `rabbitmq-service stop` 停止服务
- linux
    - `rabbitmq-server -detached` 后台启动
    - `rabbitmqctl stop` 停止
    - `rabbitmqctl status`

### 其他命令

```bash
## 1.添加用户并设置权限
rabbitmqctl list_users # 查看用户(有一个guest默认用户)
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

rabbitmqctl set_policy

## 客户端使用

- 相关代码参考github
- 引入客户端依赖

```xml
<dependency>
    <groupId>com.rabbitmq</groupId>
    <artifactId>amqp-client</artifactId>
    <version>5.9.0</version>
</dependency>
```
- 核心代码（topic为例）

```java
// 获取连接
ConnectionFactory factory = new ConnectionFactory();
factory.setHost("127.0.0.1");
factory.setPort(5672);
factory.setUsername("guest");
factory.setPassword("guest");
factory.setVirtualHost("/test"); // 需要提前创建好此虚拟主机
Connection onnection = factory.newConnection();

// 生成者发布消息
channel.exchangeDeclare("my_exchange_name", "topic");
channel.basicPublish("my_exchange_name", "aezo.user", null, ("这是一条消息").getBytes());

// 消费者
Channel channel = connection.createChannel();
channel.exchangeDeclare("my_exchange_name", "topic");
String queueName = channel.queueDeclare().getQueue(); // 获取一个临时队列。管理后台的Queues-Features会增加"AD"(autoDelete)和"Excl"(exclusive)标识
channel.queueBind(queueName, "my_exchange_name", "aezo.#"); // *匹配一个单词，#匹配多个单词
channel.queueBind(queueName, "my_exchange_name", "*.vip");
channel.basicConsume(queueName, true, new DefaultConsumer(channel) {
    @Override
    public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
        System.out.println("consumer收到消息：" + new String(body, "UTF-8"));
    }
});

// 关闭资源
channel.close();
connection.close();
```

## 整合SpringBoot

- RabbitMQ是实现了高级消息队列协议(AMQP)的开源消息代理软件，也称为面向消息的中间件。后续操作需要先安装RabbitMQ服务
- 引入对amqp协议支持依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```
- 配置rabbitmq服务器链接

    ```yml
    spring:
      rabbitmq:
        host: localhost
        port: 5672
        username: guest
		password: guest
		# 可以基于多环境配置rabbitmq虚拟服务器(队列是隔离的)
		virtualHost: /test
    ```
- 配置队列、生产者、消费者

    ```java
    // 配置队列 hello
    @Bean
    public Queue helloQueue() {
        return new Queue("hello");
    }

    // 生产者
    @Component
    public class Provider {

        @Autowired
        private AmqpTemplate rabbitTemplate;

        // 发送消息
        public void send() {
            String context = "hello " + new Date();
            System.out.println("Provider: " + context);
            rabbitTemplate.convertAndSend("hello", context);
        }
    }

    // 消费者
    @Component
    @RabbitListener(queues = "hello")
    public class Consumer {

        @RabbitHandler
        public void process(String msg) {
            System.out.println("Consumer: " + msg);
        }
    }
    ```

## 集群搭建



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


## erlang

- [erlang](https://www.erlang.org/)

```bash
# 进入erlang shell。表示版为 R16B03-1 (rabbitmq 3.8.7 至少需要版本 OTP 21.3，参考：https://www.rabbitmq.com/which-erlang.html)
erl # Erlang R16B03-1 (erts-5.10.4) [source] [64-bit] [smp:2:2] [async-threads:10] [hipe] [kernel-poll:false]
Ctrl+G, q # 退出（需要输入两次两次命令）
```









---
