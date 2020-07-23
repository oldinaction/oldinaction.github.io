---
layout: "post"
title: "Zookeeper"
date: "2017-10-22 19:24"
categories: arch
tags: HA
---

## 介绍

- [ZooKeeper官网](http://zookeeper.apache.org/)
- ZooKeeper **分布式协调服务(提供分布式锁)，是一个为分布式应用提供一致性服务的软件**，提供的功能包括：配置维护、域名服务、分布式同步、组服务等。是Google的Chubby一个开源的实现，是Hadoop和Hbase的重要组件

## 基本概念

- Paxos协议
- ZooKeeper特点
	- 最终一致性：为客户端展示同一个视图
	- 可靠性：如果消息被一台服务器接受，那么它将被所有的服务器接受
	- 实时性：zookeeper不能保证两个客户端能同时得到刚更新的数据，如果需要最新数据，应该在读数据之前调用sync()接口
	- 独立性：各个Client之间互不干预
	- 原子性：更新只能成功或者失败，没有中间状态
	- 顺序型：所有Server，同一消息发布顺序一致
- ZooKeeper工作原理
	- 每个Server在内存中存储一份数据(有的会存在磁盘)
	- zookeeper启动时，将从实例中选举一个leader(Paxos协议)
	- Leader负责处理数据更新等操作
	- 一个更新操作成功的标志是当且仅当大多数Server在内存中成功修改数据
- ZooKeeper可能出现可用和不可用两种状态
    - 当Leader挂掉后，集群短暂不可用，此时不会接受客户端请求
    - 并且会在200ms左右恢复成可用，即重新选出Leader
- 是一个目录树结构
    - 每个节点可以存放1MB数据
    - 节点分为：持久节点、临时节点(session)、序列节点
    - 实现功能
        - 1M数据 -> 统一配置
        - path结构 -> 分组管理
        - sequential -> 统一命名
        - 临时节点 -> 同步 -> 分布式锁
- 特征
    - 顺序一致性：客户端的更新将按发送顺序应用
    - 原子性：全部更新成功或失败
    - 统一视图：无论服务器连接到哪个服务器，客户端都将看到相同的服务视图(临时节点数据也可见)
    - 可靠性：一旦应用了更新，它将从那时起持续到客户端覆盖更新
    - 及时性：系统的客户视图保证在特定时间范围内是最新的

## ZooKeeper安装和使用

- 基于v3.4.6，使用3台机器进行搭建。文档[http://zookeeper.apache.org/doc/r3.4.6/index.html](http://zookeeper.apache.org/doc/r3.4.6/index.html)

    ```bash
    ## 需要保证安装了JDK，参考[CentOS服务器使用说明.md#安装jdk](/_posts/linux/CentOS服务器使用说明.md#安装jdk)
    ## 安装
    date # 检查所有机器的时间是否相差不大(30秒内)，并查看是否关闭防火墙
    wget https://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.6.1/apache-zookeeper-3.6.1-bin.tar.gz
    mkdir /opt/soft
    tar -zxvf apache-zookeeper-3.6.1-bin.tar.gz -C /opt/soft
    cd /opt/soft/apache-zookeeper-3.6.1-bin
    cp conf/zoo_sample.cfg conf/zoo.cfg
    vi conf/zoo.cfg # 参考下文
    scp -r /opt/soft/apache-zookeeper-3.6.1-bin root@node2:/opt/soft/apache-zookeeper-3.6.1-bin/ # 复制node1下的zookeeper目录到其他两台机器
    scp -r /opt/soft/apache-zookeeper-3.6.1-bin root@node3:/opt/soft/apache-zookeeper-3.6.1-bin/

    mkdir -p /opt/data/zookeeper
    echo 1 > /opt/data/zookeeper/myid # 创建dataDir目录，并再此目录创建`myid`文件，然后在每台机器的`myid`文件中写入对应的服务号(服务名server.X中的X)

    vi /etc/profile # 加入如下配置
    #export ZOOKEEPER_HOME=/opt/soft/apache-zookeeper-3.6.1-bin
    #export PATH=$PATH:$ZOOKEEPER_HOME/bin
    source /etc/profile
    ```
    - conf/zoo.cfg配置示例

        ```bash
        tickTime=2000
        initLimit=10
        syncLimit=2
        # 内存数据库存放目录
        dataDir=/opt/data/zookeeper
        clientPort=2181
        # zookeeper服务名 = 服务器地址和端口。每台机器将自己服务名(server.X)中的X存放在dataDir下的myid文件中
        server.1=node1:2888:3888
        server.2=node2:2888:3888
        server.3=node3:2888:3888
        #server.4=node4:2888:3888:observer # 设置节点为Observer角色
        ```
- 启动与停止

```bash
zkServer.sh start # zkServer.sh start-foreground 此方式日志直接打印在前台
tail -100 logs/zookeeper-root-server-node1.out # [LeaderConnector-node3/192.168.6.133:2888:Learner$LeaderConnector@330] - Successfully connected to leader, using address: node3/192.168.6.133:2888
zkServer.sh status # 查看zookpeer状态。显示`Mode: leader`或`Mode: follower`则成功
zkServer.sh stop # 停止服务
```
- 客户端使用

```bash
## 命令
create [-s] [-e] [-c] [-t ttl] path [data] [acl] # 其中，-s或-e分别指顺序或临时节点，若不指定，则表示持久节点(可同时使用)；acl用来进行权限控制

## 测试
zkCli.sh # 进入zookeeper客户端命令行，如：[zk: localhost:2181(CONNECTED) 0]
help
ls / # 查看根节点，默认有一个[zookeeper]的子目录
create /abc "" # 打印Created /abc，创建/abc目录，此时根目录为：[abc, zookeeper]
create -s /abc/123 # 打印Created 创建/abc/1230000000000的序列目录，此时根目录不变，且/abc/目录为：[1230000000000]
create -s /abc/123 # 再次运行，此时/abc目录为：[1230000000000, 1230000000001]
create -e /abc/d # 创建临时节点(退出客户端后，此节点消失；临时节点也是全局可见的，即统一视图)，此时/abc目录为：[1230000000000, 1230000000001, d]
create -s -e /abc/e # 创建临时性顺序节点，此时/abc目录为：[1230000000000, 1230000000001, d, e0000000003]
set /abc "hello world" # 设置节点数据
get /abc # 获取节点数据，hello world
ls -s /abc # 结果如下
    # [1230000000000, 1230000000001, d, e0000000003]    # 节点
    # cZxid = 0x100000002                               # Zookeeper为节点分配的Id
    # ctime = Mon Jul 20 23:12:45 CST 2020              # 节点创建时间
    # mZxid = 0x200000006                               # 修改后的id
    # mtime = Mon Jul 20 23:44:21 CST 2020              # 修改时间
    # pZxid = 0x200000003                               # 子节点id
    # cversion = 4                                      # 子节点的version
    # dataVersion = 1                                   # 当前节点数据的版本号
    # aclVersion = 0                                    # 权限Version
    # ephemeralOwner = 0x0
    # dataLength = 11                                   # 数据长度
    # numChildren = 4                                   # 子节点个数
```

## 原理

- 角色：Leader、Follower、Observer
    - 只有Follower才能选举(加快恢复速度)
    - Observer只提供读取服务，不能选举。利用Observer放大查询能力，读写分离。zk适合读多写少的场景
- zookeeper每个节点需配置两个端口
    - 如监听2888和3888端口，可通过`netstat -natp | egrep '(2888|3888)'`查看
        - 2888：leader接受write请求，即其他从节点会连接到leader的2888端口
        - 3888：选主投票用的
    - 启动后3888端口的连接如下，假设4个节点，则每个节点和其他3个节点进行连接
        
        ![zookeeper-3888](/data/images/arch/zookeeper-3888.png)

### Zab协议

- ZooKeeper 是通过 `Zab`(ZooKeeper Atomic Broadcast，ZooKeeper 原子广播协议)协议来保证分布式事务的最终一致性和支持崩溃恢复 [^1]
    - ZAB基于[Paxos](https://zh.wikipedia.org/zh-cn/Paxos%E7%AE%97%E6%B3%95)算法演进而来。Paxos 是理论，Zab 是实践
- Zab 协议主要功能：消息广播、崩溃恢复、数据同步
- **消息广播**。写操作可理解为2PC过程

    ![zookeeper-2pc](/data/images/arch/zookeeper-2pc.png)
    - 接受写请求：在 ZooKeeper 中所有的事务请求都由 Leader 节点来处理，其他服务器为 Follower
        - Leader或Follower都对外提供读写操作
        - 客户端对Follower发起写操作时，会由Follower提交到Leader进行写操作
    - 广播事务操作：Leader 将客户端的事务请求转换为事务 Proposal(提议)，并且将 Proposal 分发给集群中其他所有的 Follower
        - Leader会为每个请求生成一个Zxid(高32位是epoch，用来标识leader选举周期；低32位用于递增计数。在Paxos中epoch叫Ballot Number)
        - Leader 会为每一个 Follower 服务器分配一个单独的 FIFO 队列，然后把 Proposal 放到队列中
        - Follower 节点收到对应的 Proposal 之后会把它持久到磁盘上(zk的数据状态在内存，用磁盘保存日志)。当完全写入之后，发一个 ACK 给 Leader
    - 广播提交操作：Leader 等待 Follwer 反馈，当有过半数的 Follower 反馈信息后，Leader 将再次向集群内 Follower 广播 Commit 信息(上述Proposal)，Follower 收到 Commit 之后，完成各自的事务提交
- **崩溃恢复**。若某一时刻 Leader 挂了，此时便开始 Leader 选举，过程如
    - 各个节点变更状态，变更为 Looking(选举状态)
    - 各个 Server 节点都会发出一个投票(第一次默认投自己)，参与选举
    - 集群接收来自各个服务器的投票，开始处理投票和选举
    - 新Leader选举原则：先考虑Zxid大的，再考虑myid大的
- **数据同步**
    - 崩溃恢复完成选举以后，接下来的工作就是数据同步，在选举过程中，通过投票已经确认 Leader 服务器是最大Zxid 的节点，同步阶段就是利用 Leader 前一阶段获得的最新Proposal历史，同步集群中所有的副本

### 一致性

- CAP理论
- 一致性分类
- 对于zookeeper来说，它实现了A可用性、P分区容错性、C中的写入强一致性，丧失的是C中的读取一致性

https://blog.csdn.net/nawenqiang/article/details/85236952

## Java中使用








---

参考文章

[^1]: https://www.cnblogs.com/zz-ksw/p/12786067.html

