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
- zookeeper每个节点需配置两个端口，如监听2888和3888端口
    - 2888：leader接受write请求
    - 3888：选主投票用的
    - 启动后3888端口的连接如下，假设4个节点，则每个节点和其他3个节点进行连接
        
        ![zookeeper-3888](/data/images/arch/zookeeper-3888.png)

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

## Java中使用








---



