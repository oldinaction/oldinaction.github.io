---
layout: "post"
title: "RabbitMQ"
date: "2016-08-14 16:49"
categories: [arch]
tags: [mq, rabbitMQ]
---

## RabbitMQ 简介

- rabbitMQ 是一个在 AMQP 协议(高级消息队列协议)标准基础上完整的，可服用的企业消息系统。他遵循 Mozilla Public License 开源协议。采用 Erlang 实现的工业级的消息队列(MQ)服务器。
- RabbitMQ 的官方站：http://www.rabbitmq.com/
- 相关概念
  - `Broker` 消息队列服务器实体
  - `Exchange` 消息交换机，它指定消息按什么规则，路由到哪个队列
  - `Queue` 消息队列载体，每个消息都会被投入到一个或多个队列
  - `Binding` 绑定，它的作用就是把 exchange 和 queue 按照路由规则绑定起来
  - `RoutingKey` 路由关键字，exchange 根据这个关键字进行消息投递
  - `VirtualHost` 在 RabbitMQ 中可以虚拟消息服务器 VirtualHost，每个 VirtualHost 相当月一个相对独立的 RabbitMQ 服务器，每个 VirtualHost 之间是相互隔离的，一个 broker 里可以开设多个 vhost，用作不同用户的权限分离。exchange、queue、message 不能互通。VirtualName 一般以/开头
  - `Producer` 消息生产者，就是投递消息的程序
  - `Consumer` 消息消费者，就是接受消息的程序
  - `Channel` 消息通道，在客户端的每个连接里，可建立多个 channel，每个 channel 代表一个会话任务
- 数据传输

  ![数据传输](/data/images/arch/rabbitmq-arch.png)

  - 也可以不用先发送给交换机，直接点对点进行传输
  - 生成者和消费者必须通过 Channel 向虚拟机开启一个会话

- 7 种消息模型：https://www.rabbitmq.com/getstarted.html
  ![消息模型](/data/images/arch/rabbitmq-message-model.png)
  - 常用：点对点、work、订阅（fanout 广播、direct 直连、topic 主题）
  - Direct 直连（RoutingKey 固定）；Topic 基于通配符（RoutingKey 包含通配符：\*匹配一个单词，#匹配多个单词）

## RabbitMQ 安装

### linux

```bash
## 安装erlang，版本有一定的要求，参考：https://www.rabbitmq.com/which-erlang.html。具体[参考下文](#erlang)
# 不能使用默认源，否则安装的是R16B03-1。如是centos8则配置为.../el/8/
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

## 安装rabbitmq
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.7/rabbitmq-server-generic-unix-3.8.7.tar.xz
tar -xvf rabbitmq-server-generic-unix-3.8.7.tar.xz -C /opt/
echo 'export PATH=$PATH:/opt/rabbitmq_server-3.8.7/sbin' >> /etc/profile
source /etc/profile
# 添加web管理插件
rabbitmq-plugins enable rabbitmq_management

## 后台启动rabbitmq服务
rabbitmq-server -detached

## 设置loopback_users.guest = false，[参考下文](#配置文件)
```

### windows

Rabbit MQ 是建立在强大的 Erlang OTP 平台上，因此安装 Rabbit MQ 的前提是安装 Erlang。通过下面两链接下载安装 3.7.7 版本

- 安装 [Eralng OTP For Windows (opt21)](http://erlang.org/download/otp_win64_21.3.exe)
- 设置`ERLANG_HOME=D:\software\erl10.3`
- 安装 [RabbitMQ Server (3.8.7)](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.7/rabbitmq-server-3.8.7.exe)
- **默认监听`5672`端口(客户端连接使用此端口)，开启后台则默认使用端口`15672`，默认超级管理员`guest/guest`**

#### 配置文件

- 参考：https://www.rabbitmq.com/configure.html#config-location
- 增加配置文件（可选）：手动创建`$RABBITMQ_HOME/etc/rabbitmq/rabbitmq.conf`
- 相关参数说明，配置文件样例 `https://github.com/rabbitmq/rabbitmq-server/blob/v3.7.x/docs/rabbitmq.conf.example`

```bash
# 默认为true，仅允许guest用户通过localhost访问；false表示任何网络均可访问
loopback_users.guest = false
```
- 默认端口
  - `5672` 客户端通信amqp端口
  - `15672` 开启后台则默认此http端口访问管理界面
  - `25672` 集群通信端口

## 相关命令

### RabbitMQ 启动与停止

- windows
  - `rabbitmq-service start` 启动 RabbitMQ 服务
  - `rabbitmq-service stop` 停止服务
- linux
  - `rabbitmq-server -detached` 后台启动服务
  - `rabbitmqctl stop` 停止
  - `rabbitmqctl status`

### 命令说明

```bash
rabbitmq-server # **启动 RabbitMQ 和 Erlang VM**（关闭需要使用rabbitmqctl）
rabbitmqctl # 管理工具。rabbitmqctl help [command]
rabbitmq-diagnostics # 诊断。rabbitmq-diagnostics help [command]
rabbitmq-plugins # 插件管理。rabbitmq-plugins help [command]
rabbitmq-env # 环境配置
rabbitmq-defaults # 默认参数设置
```

### rabbitmqctl

```bash
### rabbitmqctl
Usage

rabbitmqctl [--node <node>] [--timeout <timeout>] [--longnames] [--quiet] <command> [<command options>]

Available commands:

Help:

   autocomplete                  Provides command name autocomplete variants
   help                          Displays usage information for a command
   version                       Displays CLI tools version

Nodes: ### 节点

   await_startup                 Waits for the RabbitMQ application to start on the target node
   reset                         # 设置节点离开集群并回到初始状态
   rotate_logs                   Instructs the RabbitMQ node to perform internal log rotation
   shutdown                      Stops RabbitMQ and its runtime (Erlang VM). Monitors progress for local nodes. Does not require a PID file path.
   start_app                     # 启动 RabbitMQ 程序. Starts the RabbitMQ application but leaves the runtime (Erlang VM) running
   stop                          # 关闭 RabbitMQ 和 Erlang VM 程序. Requires a local node pid file path to monitor progress.
   stop_app                      # 仅关闭 RabbitMQ 程序. leaving the runtime (Erlang VM) running
   wait                          Waits for RabbitMQ node startup by monitoring a local PID file. See also 'rabbitmqctl await_online_nodes'

Cluster: ### 集群

   await_online_nodes            Waits for <count> nodes to join the cluster
   change_cluster_node_type      Changes the type of the cluster node
   cluster_status                # 查看集群状态
   force_boot                    Forces node to start even if it cannot contact or rejoin any of its previously known peers
   force_reset                   Forcefully returns a RabbitMQ node to its virgin state
   forget_cluster_node           Removes a node from the cluster
   join_cluster                  # 加入集群
   rename_cluster_node           Renames cluster nodes in the local database
   update_cluster_nodes          Instructs a cluster member node to sync the list of known cluster members from <seed_node>

Replication:

   cancel_sync_queue             Instructs a synchronising mirrored queue to stop synchronising itself
   sync_queue                    Instructs a mirrored queue with unsynchronised mirrors (follower replicas) to synchronise them

Users: ## 账户管理

   add_user                      # 创建用户。如：rabbitmqctl add_user <用户名> <密码>
   authenticate_user             Attempts to authenticate a user. Exits with a non-zero code if authentication fails.
   change_password               Changes the user password
   clear_password                Clears (resets) password and disables password login for a user
   delete_user                   Removes a user from the internal database. Has no effect on users provided by external backends such as LDAP
   list_users                    # 查看用户（有一个guest默认用户）和角色（tag）
   set_user_tags                 # 设置用户角色（administrator：超级管理员；management：虚拟机管理者；policymaker：策略制定者；monitoring：监控者；none）
        # rabbitmqctl set_user_tags smalle administrator

Access Control: ## 权限控制

   clear_permissions             Revokes user permissions for a vhost
   clear_topic_permissions       Clears user topic permissions for a vhost or exchange
   list_permissions              Lists user permissions in a virtual host
   list_topic_permissions        Lists topic permissions in a virtual host
   list_user_permissions         Lists permissions of a user across all virtual hosts
   list_user_topic_permissions   Lists user topic permissions
   list_vhosts                   Lists virtual hosts
   set_permissions               # 设置用户对虚拟机的访问权限
        # rabbitmqctl set_permissions -p /test smalle '.*' '.*' '.*' # 设置smalle用户对/test虚拟机拥有所有权限
   set_topic_permissions         Sets user topic permissions for an exchange

Monitoring, observability and health checks: ## 健康观测

   list_bindings                 Lists all bindings on a vhost
   list_channels                 Lists all channels in the node
   list_ciphers                  Lists cipher suites supported by encoding commands
   list_connections              Lists AMQP 0.9.1 connections for the node
   list_consumers                Lists all consumers for a vhost
   list_exchanges                Lists exchanges
   list_hashes                   Lists hash functions supported by encoding commands
   list_queues                   # 列举所有队列和其配置
   list_unresponsive_queues      Tests queues to respond within timeout. Lists those which did not respond
   ping                          Checks that the node OS process is up, registered with EPMD and CLI tools can authenticate with it
   report                        Generate a server status report containing a concatenation of all server status information for support purposes
   schema_info                   Lists schema database tables and their properties
   status                        Displays status of a node

Parameters:

   clear_global_parameter        Clears a global runtime parameter
   clear_parameter               Clears a runtime parameter.
   list_global_parameters        Lists global runtime parameters
   list_parameters               Lists runtime parameters for a virtual host
   set_global_parameter          Sets a runtime parameter.
   set_parameter                 Sets a runtime parameter.

Policies: ### 策略

   clear_operator_policy         Clears an operator policy
   clear_policy                  Clears (removes) a policy
   list_operator_policies        Lists operator policy overrides for a virtual host
   list_policies                 # 列举策略
   set_operator_policy           Sets an operator policy that overrides a subset of arguments in user policies
   set_policy                    # 设置或更新策略
        # rabbitmqctl set_policy -p /test ha-all '^hello' '{"ha-mode":"all","ha-sync-mode":"automatic"}' # 对/test虚拟主机增加策略，策略名为ha-all，且交换机和队列以hello开头的，策略描述为 {"ha-mode":"all","ha-sync-mode":"automatic"} (automatic自动同步镜像到集群的all所有节点)。策略增加成功后，会在对应的对应的Features上显示`ha-all`的标识

Virtual hosts: ## 虚拟机

   add_vhost                     Creates a virtual host
   clear_vhost_limits            Clears virtual host limits
   delete_vhost                  Deletes a virtual host
   list_vhost_limits             Displays configured virtual host limits
   restart_vhost                 Restarts a failed vhost data stores and queues
   set_vhost_limits              Sets virtual host limits
   trace_off
   trace_on

Configuration and Environment:

   decode                        Decrypts an encrypted configuration value
   encode                        Encrypts a sensitive configuration value
   environment                   Displays the name and value of each variable in the application environment for each running application
   set_cluster_name              Sets the cluster name
   set_disk_free_limit           Sets the disk_free_limit setting
   set_log_level                 Sets log level in the running node
   set_vm_memory_high_watermark  Sets the vm_memory_high_watermark setting

Definitions:

   export_definitions            Exports definitions in JSON or compressed Erlang Term Format.
   import_definitions            Imports definitions in JSON or compressed Erlang Term Format.

Feature flags:

   enable_feature_flag           Enables a feature flag on target node
   list_feature_flags            Lists feature flags

Operations:

   close_all_connections         Instructs the broker to close all connections for the specified vhost or entire RabbitMQ node
   close_connection              Instructs the broker to close the connection associated with the Erlang process id
   eval                          Evaluates a snippet of Erlang code on the target node
   eval_file                     Evaluates a file that contains a snippet of Erlang code on the target node
   exec                          Evaluates a snippet of Elixir code on the CLI node
   force_gc                      Makes all Erlang processes on the target node perform/schedule a full sweep garbage collection

Queues: ## 队列

   delete_queue                  Deletes a queue
   purge_queue                   # 清空某个队列里的数据。rabbitmqctl purge_queue <queue_name>
Deprecated:

   hipe_compile                  DEPRECATED. This command is a no-op. HiPE is no longer supported by modern Erlang versions
   node_health_check             DEPRECATED. Performs intrusive, opinionated health checks on a fully booted node. See https://www.rabbitmq.com/monitoring.html#health-checks instead

Use 'rabbitmqctl help <command>' to learn more about a specific command
```

### rabbitmq-diagnostics

```bash
# rabbitmq-diagnostics [--node <node>] [--timeout <timeout>] [--longnames] [--quiet] <command> [<command options>]
status # 获取rabbitmq状态
```

### 简单使用

```bash
# 添加用户和设置角色和权限
rabbitmqctl add_user smalle mypass
rabbitmqctl set_user_tags smalle administrator
rabbitmqctl set_permissions -p /test smalle '.*' '.*' '.*' # 可访问/test虚拟机的
```

## 客户端使用

### 简单使用

- 相关代码参考 github
- 引入客户端依赖

```xml
<dependency>
    <groupId>com.rabbitmq</groupId>
    <artifactId>amqp-client</artifactId>
    <version>5.9.0</version>
</dependency>
```

- 核心代码（topic 为例）

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

### 整合 SpringBoot

- RabbitMQ 是实现了高级消息队列协议(AMQP)的开源消息代理软件，也称为面向消息的中间件。后续操作需要先安装 RabbitMQ 服务
- 引入对 amqp 协议支持依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

- 配置 rabbitmq 服务器链接

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

## (镜像)集群搭建

```bash
## 在 test1、test2、test3 三台机器上搭建rabbit服务
## 同步 .erlang.cookie 文件：在 test1 机器上找到 .erlang.cookie 文件（如：`/root/.erlang.cookie`，`C:/Users/smalle/.erlang.cookie`，具体位置可find一下），将此文件复制到B、C相同的目录

## 后台启动所有节点服务（erlang vm 和 rabbitmq）
rabbitmq-server -detached

## 在 test2、test3 上操作
# 关闭 rabbitmq, 但是会保留 erlang vm 进程
rabbitmqctl stop_app
# 加入到集群 rabbit@test1 （需要hosts中有test1的ip映射）
rabbitmqctl join_cluster rabbit@test1 # 成功则提示 Clustering node rabbit@test2 with rabbit@test1
# 重新启动 rabbitmq 进程
rabbitmqctl stop_app

## 查看集群状态。也可以在管理界面的 Overview-Nodes 看到多个节点
rabbitmqctl cluster_status
## 此时 test1 的队列等信息会映射到其他两个节点。客户端可以连接任何一个节点读写消息，但是如果 test1 宕机，则映射过来的队列的 State=down，且改队列不可对外通过服务

## 增加镜像策略解决上述问题
# 对/test虚拟主机增加策略，策略名为ha-all，且交换机和队列以hello开头的，策略描述为 {"ha-mode":"all","ha-sync-mode":"automatic"} (automatic自动同步镜像到集群的all所有节点)。策略增加成功后，会在对应的对应的Features上显示`ha-all`的标识
rabbitmqctl set_policy -p /test ha-all '^hello' '{"ha-mode":"all","ha-sync-mode":"automatic"}'
rabbitmqctl list_policy # 查看策略
# 此时尽管 test1 宕机，其他节点还是可以对外提供服务
```

- 常见错误：`Authentication failed (rejected by the remote node), please check the Erlang cookie`

  ```bash
  # 还有如下输出，此时 Erlang cookie hash 是.erlang.cookie文件内容经过hash得到，且.erlang.cookie文件处于/root目录。出现此问题可能是：
  # 1.几个节点的.erlang.cookie内容不一致
  # 2.Erlang VM没有启动
  # 3.rabbitmq app没有关闭（需执行rabbitmqctl stop_app）
  Current node details:
  * node name: 'rabbitmqcli79@LAPTOP-SDG10LIN'
  * effective user's home directory: /root
  * Erlang cookie hash: Jx59lsGpH45Mhu5eAkFMGQ==
  ```

## 后台管理

- 激活 Rabbit MQ's Management Plugin(可激活管理插件)
  - CMD 进入 RabbitMQ 安装目录，进入到 rabbitmq_server-3.8.7/sbin 目录
  - 运行 `rabbitmq-plugins enable rabbitmq_management`
- 登录管理后台
  - `http://localhost:15672` 使用`guest/guest`登录(需要激活 rabbitmq_management)
  - 如果需要通过内网访问，可设置配置 loopback_users.guest=false，具体参考上文安装
- Admin
  - Users 用户管理
    - Add a user 添加用户
    - 点击用户进入详情页面
      - Permissions 和 Topic permissions 可设置用户权限
        - 选择 Virtual Host，其他为`.*`表示所有权限
  - Virtual Hosts 虚拟主机管理
    - Add a new virtual host 添加虚拟主机
      - 输入名称如`/vhost_aezocn_test`，命名上 abc 和 /abc 是不同的
      - 需要先有对应的虚拟主机，客户端才能连接
    - 点击某个虚拟主机进入到详情页面
      - Permissions 和 Topic permissions 可设置用户权限，参考 Users 中的
  - Policies 策略管理

## erlang

- [erlang](https://www.erlang.org/)
- 安装 [^1]

```bash
# 不能使用默认源，否则安装的是R16B03-1。如是centos8则配置为.../el/8/
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

- 命令

```bash
# 进入erlang shell。表示版为 R16B03-1 (rabbitmq 3.8.7 至少需要版本 OTP 21.3，参考：https://www.rabbitmq.com/which-erlang.html)
erl # Erlang R16B03-1 (erts-5.10.4) [source] [64-bit] [smp:2:2] [async-threads:10] [hipe] [kernel-poll:false]
Ctrl+G, q # 退出（需要输入两次两次命令）
```

---

参考文章

[^1]: https://blog.csdn.net/qq_41709494/article/details/86740162

