---
layout: "post"
title: "Zookeeper"
date: "2017-10-22 19:24"
categories: arch
tags: HA
---

## 介绍

- ZooKeeper是一个分布式的，开放源码的分布式应用程序协调服务(提供分布式锁)，是Google的Chubby一个开源的实现，是Hadoop和Hbase的重要组件。它是一个为分布式应用提供一致性服务的软件，提供的功能包括：配置维护、域名服务、分布式同步、组服务等。
- Paxos协议
- ZooKeeper特点
	- 最终一致性：为客户端展示同一个视图
	- 可靠性：如果消息被一台服务器接受，那么它将被所有的服务器接受
	- 实时性：zookeeper不能保证两个客户端能同时得到刚更新的数据，如果需要最新数据，应该在读数据之前调用sync()接口
	- 独立性：各个Client之间互不干预
	- 原子性：更新只能成功或者失败，没有中间状态
	- 顺序型：所有Server，同一消息发布顺序一致
- ZooKeeper工作原理
	- 每个Server在内存中存储一份数据(有的会存在在磁盘)
	- zookeeper启动时，将从实例中选举一个leader(Paxos协议)
	- Leader负责处理数据更新等操作
	- 一个更新操作成功的标志是当且仅当大多数Server在内存中成功修改数据

## zookeeper安装

> 基于v3.4.6，使用3台机器进行搭建。文档[http://zookeeper.apache.org/doc/r3.4.6/index.html](http://zookeeper.apache.org/doc/r3.4.6/index.html)

- `date` 检查4台机器的时间是否相差不大(30秒内)，并查看是否关闭防火墙
- 下载`zookeeper-3.4.6.tar.gz`并上传到某一台服务器(如server1)，解压`tar -zxvf zookeeper-3.4.6.tar.gz -C /opt/soft`
- `cd /opt/soft/zookeeper-3.4.6`
- 创建`zoo.cfg`配置文件：`vi conf/zoo.cfg`，并写入一下内容

	```bash
	tickTime=2000
	# 内存数据库存放目录
	dataDir=/opt/data/zookeeper
	clientPort=2181
	initLimit=5
	syncLimit=2
	# zookeeper服务名 = 服务器地址和端口。每台机器将自己服务名(server.X)中的X存放在dataDir下的myid文件中
	server.1=server1:2888:3888
	server.2=server2:2888:3888
	server.3=server3:2888:3888
	```
- 复制server1下的zookeeper目录到其他两台机器(server2、server3)的相应目录
	- `scp -r /opt/soft/zookeeper-3.4.6 root@server2:/opt/soft/` server3同理
- 创建dataDir目录，并再此目录创建`myid`文件，然后在每台机器的`myid`文件中写入对应的服务号(服务名server.X中的X)
- **`bin/zkServer.sh start`** 分别启动3台机器上的服务
	- `tail -100 zookeeper.out` 可查看机器启动日志信息
	- `jps`查看显示`QuorumPeerMain`
- `bin/zkServer.sh status` 查看zookpeer状态。显示`Mode: leader`或`Mode: follower`则成功
- `bin/zkServer.sh stop` 停止服务



---



