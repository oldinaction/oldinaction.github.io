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
zkCli.sh # 进入zookeeper客户端命令行，如：[zk: localhost:2181(CONNECTED) 0]

help # 见下文客户端命令说明
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
    # cZxid = 0x100000002                               # 该数据节点被创建时的事务ID
    # ctime = Mon Jul 20 23:12:45 CST 2020              # 节点创建时间
    # mZxid = 0x200000006                               # 该数据节点被修改时的事务ID
    # mtime = Mon Jul 20 23:44:21 CST 2020              # 修改时间
    # pZxid = 0x200000003                               # 该节点的子节点列表个数最后一次被修改时生成的事务ID，如果某个子节点内容修改并不会生成新的pzxid
    # cversion = 4                                      # 子节点的version
    # dataVersion = 1                                   # 当前节点数据的版本号
    # aclVersion = 0                                    # 权限Version
    # ephemeralOwner = 0x0                              # 临时节点所有者(对应session id)，如：ephemeralOwner = 0x200008343170002
    # dataLength = 11                                   # 数据长度
    # numChildren = 4                                   # 子节点个数
```
- 客户端命令

```bash
# help展示帮助
ZooKeeper -server host:port -client-configuration properties-file cmd args
	addWatch [-m mode] path # optional mode is one of [PERSISTENT, PERSISTENT_RECURSIVE] - default is PERSISTENT_RECURSIVE
	addauth scheme auth
	close 
	config [-c] [-w] [-s]
	connect host:port
	create [-s] [-e] [-c] [-t ttl] path [data] [acl] # 其中，-s或-e分别指顺序或临时节点，若不指定，则表示持久节点(可同时使用)；acl用来进行权限控制
	delete [-v version] path # 删除节点，delete /test
	deleteall path [-b batch size]
	delquota [-n|-b] path
	get [-s] [-w] path # 获取节点数据，get /test
	getAcl [-s] path
	getAllChildrenNumber path
	getEphemerals path
	history 
	listquota path
	ls [-s] [-w] [-R] path
	printwatches on|off
	quit 
	reconfig [-s] [-v version] [[-file path] | [-members serverID=host:port1:port2;port3[,...]*]] | [-add serverId=host:port1:port2;port3[,...]]* [-remove serverId[,...]*]
	redo cmdno
	removewatches path [-c|-d|-a] [-l]
	set [-s] [-v version] path data # 设置节点数据，set /test "hello"；每次修改版本会变化，如果基于版本设值，则传入的版本和数据版本一致才会修改成功
	setAcl [-s] [-v version] [-R] path acl
	setquota -n|-b val path
	stat [-w] path
	sync path  # 同步节点，sync /test
	version 
Command not found: Command not found help
```


## 原理

- 角色：Leader、Follower、Observer
    - 只有Follower才能选举(加快恢复速度)
    - Observer只提供读取服务，不能选举。利用Observer放大查询能力，读写分离。zk适合读多写少的场景
- zookeeper每个节点需配置几个端口。可通过`netstat -natp | egrep '(2188|2888|3888)'`查看
    - 2188：客户端连接使用
    - 2888：leader接受write请求，即其他从节点会连接到leader的2888端口
    - 3888：选主投票用的
    - 启动后3888端口的连接如下，假设4个节点，则每个节点和其他3个节点进行连接
        
        ![zookeeper-3888](/data/images/arch/zookeeper-3888.png)
- 客户端watch一个目录后，当该目录发生改变后，会触发事件通知到客户端

    ![zookeeper-watch](/data/images/arch/zookeeper-watch.png)
- zookeeper是有session的概念，因此客户端使用时不能使用线程池

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
    - 当发现Leader挂掉后，将本节点变更状态，变更为 Looking(选举状态)
    - 然后上述节点会发出一个投票，参与选举
    - 其他节点收到投票提议，开始处理投票选举
        - 新Leader选举原则：**先考虑Zxid大的，再考虑myid大的**。如初始化集群启动时Zxid=0，因此看myid；和启动顺序有关，如果过半，则已启动的中的myid最大的为Leader
        - 如果A节点收到B节点的投票提议，当A发现B的zxid-myid比自己小时，会反驳提议(即A也发起自己的投票提议)
        - 发起投票者都会投一票给自己
        - 如果收到超过半数的票则会当选为Leader，即3个节点得2票、4个节点得3票。只要有超过半数的节点存活，则ZK服务仍然可用
- **数据同步**
    - 崩溃恢复完成选举以后，接下来的工作就是数据同步，在选举过程中，通过投票已经确认 Leader 服务器是最大Zxid 的节点，同步阶段就是利用 Leader 前一阶段获得的最新Proposal历史，同步集群中所有的副本

### 一致性

- CAP理论
- 一致性分类
- 对于zookeeper来说，它实现了A可用性、P分区容错性、C中的写入强一致性，丧失的是C中的读取一致性

https://blog.csdn.net/nawenqiang/article/details/85236952

## Java中使用

- pom中导入客户端依赖(客户端需要和服务端保持同一版本)

```xml
<!-- https://mvnrepository.com/artifact/org.apache.zookeeper/zookeeper -->
<dependency>
    <groupId>org.apache.zookeeper</groupId>
    <artifactId>zookeeper</artifactId>
    <version>3.6.1</version>
</dependency>
```

### 简单示例

<details>
<summary>测试代码</summary>

```java
/**
 * 1.启动日志，可见session id = 0x100033765980001，且连接到的是192.168.6.131：
 *
 * 2020-07-25 13:24:23,918 [myid:] - INFO  [main:ZooKeeper@1005] - Initiating client connection, connectString=192.168.6.131:2181,192.168.6.132:2181,192.168.6.133:2181 sessionTimeout=5000 watcher=cn.aezo.zookeeper.App$1@27f8302d
 * 2020-07-25 13:24:23,923 [myid:] - INFO  [main:X509Util@77] - Setting -D jdk.tls.rejectClientInitiatedRenegotiation=true to disable client-initiated TLS renegotiation
 * 2020-07-25 13:24:24,634 [myid:] - INFO  [main:ClientCnxnSocket@239] - jute.maxbuffer value is 1048575 Bytes
 * 2020-07-25 13:24:24,649 [myid:] - INFO  [main:ClientCnxn@1703] - zookeeper.request.timeout value is 0. feature enabled=false
 * 2020-07-25 13:24:26,348 [myid:192.168.6.131:2181] - INFO  [main-SendThread(192.168.6.131:2181):ClientCnxn$SendThread@1154] - Opening socket connection to server 192.168.6.131/192.168.6.131:2181.
 * 2020-07-25 13:24:26,349 [myid:192.168.6.131:2181] - INFO  [main-SendThread(192.168.6.131:2181):ClientCnxn$SendThread@1156] - SASL config status: Will not attempt to authenticate using SASL (unknown error)
 * 2020-07-25 13:24:26,354 [myid:192.168.6.131:2181] - INFO  [main-SendThread(192.168.6.131:2181):ClientCnxn$SendThread@986] - Socket connection established, initiating session, client: /192.168.6.1:52677, server: 192.168.6.131/192.168.6.131:2181
 * 2020-07-25 13:24:26,394 [myid:192.168.6.131:2181] - INFO  [main-SendThread(192.168.6.131:2181):ClientCnxn$SendThread@1420] - Session establishment complete on server 192.168.6.131/192.168.6.131:2181, session id = 0x100033765980001, negotiated timeout = 3000
 * ZooKeeper watchedEvent = WatchedEvent state:SyncConnected type:None path:null
 * ZooKeeper path = null
 * ZooKeeper SyncConnected...
 * CONNECTED...
 * s = /aezo
 * ......此处省略testGetSync和testGetAsync的日志
 *
 * 2.当停掉192.168.6.131上的ZK服务时，日志如下：此时会自动重新连接192.168.6.132这台ZK服务器，且session id = 0x100033765980001不变
 *
 * 2020-07-25 13:25:39,978 [myid:192.168.6.131:2181] - WARN  [main-SendThread(192.168.6.131:2181):ClientCnxn$SendThread@1272] - Session 0x100033765980001 for sever 192.168.6.131/192.168.6.131:2181, Closing socket connection. Attempting reconnect except it is a SessionExpiredException.
 * java.io.IOException: 远程主机强迫关闭了一个现有的连接。
 * ......
 * getData watchedEvent = WatchedEvent state:Disconnected type:None path:null
 * 2020-07-25 13:25:40,236 [myid:192.168.6.132:2181] - INFO  [main-SendThread(192.168.6.132:2181):ClientCnxn$SendThread@1154] - Opening socket connection to server ingress.aezocn.local/192.168.6.132:2181.
 * 2020-07-25 13:25:40,237 [myid:192.168.6.132:2181] - INFO  [main-SendThread(192.168.6.132:2181):ClientCnxn$SendThread@1156] - SASL config status: Will not attempt to authenticate using SASL (unknown error)
 * 2020-07-25 13:25:40,240 [myid:192.168.6.132:2181] - INFO  [main-SendThread(192.168.6.132:2181):ClientCnxn$SendThread@986] - Socket connection established, initiating session, client: /192.168.6.1:52722, server: ingress.aezocn.local/192.168.6.132:2181
 * 2020-07-25 13:25:40,256 [myid:192.168.6.132:2181] - INFO  [main-SendThread(192.168.6.132:2181):ClientCnxn$SendThread@1420] - Session establishment complete on server ingress.aezocn.local/192.168.6.132:2181, session id = 0x100033765980001, negotiated timeout = 5000
 * ZooKeeper watchedEvent = WatchedEvent state:Disconnected type:None path:null
 * ZooKeeper path = null
 * getData watchedEvent = WatchedEvent state:SyncConnected type:None path:null
 * ZooKeeper watchedEvent = WatchedEvent state:SyncConnected type:None path:null
 * ZooKeeper path = null
 * ZooKeeper SyncConnected...
 */
public class HelloWorld {
    public static void main( String[] args ) throws IOException, InterruptedException, KeeperException {

        // 创建时，会迅速返回一个ZooKeeper对象，然后异步去连接服务器，因此可通过CountDownLatch等待
        CountDownLatch countDownLatch = new CountDownLatch(1);

        // 此处设置session超时时间为3s(即表示断开连接，如此线程执行完毕，等待3s之后，session消失，对应的临时节点也会消失)。由于session的存在，因此zookeeper连接时不存在线程池的概念
        ZooKeeper zk = new ZooKeeper("192.168.6.131:2181,192.168.6.132:2181,192.168.6.133:2181", 3000, new Watcher() {
            // ZooKeeper连接服务的监听
            @Override
            public void process(WatchedEvent watchedEvent) {
                Event.EventType type = watchedEvent.getType();
                Event.KeeperState state = watchedEvent.getState();
                String path = watchedEvent.getPath();

                System.out.println("ZooKeeper watchedEvent = " + watchedEvent);
                System.out.println("ZooKeeper path = " + path);

                switch (type) {
                    case None:
                        break;
                    case NodeCreated:
                        System.out.println("ZooKeeper NodeCreated...");
                        break;
                    case NodeDeleted:
                        break;
                    case NodeDataChanged:
                        break;
                    case NodeChildrenChanged:
                        break;
                    case DataWatchRemoved:
                        break;
                    case ChildWatchRemoved:
                        break;
                    case PersistentWatchRemoved:
                        break;
                }

                switch (state) {
                    case Unknown:
                        break;
                    case Disconnected:
                        break;
                    case NoSyncConnected:
                        break;
                    case SyncConnected:
                        countDownLatch.countDown();
                        System.out.println("ZooKeeper SyncConnected...");
                        break;
                    case AuthFailed:
                        break;
                    case ConnectedReadOnly:
                        break;
                    case SaslAuthenticated:
                        break;
                    case Expired:
                        break;
                    case Closed:
                        break;
                }
            }
        });

        countDownLatch.await();
        ZooKeeper.States state = zk.getState();
        switch (state) {
            case CONNECTING:
                System.out.println("CONNECTING...");
                break;
            case ASSOCIATING:
                break;
            case CONNECTED:
                System.out.println("CONNECTED...");
                break;
            case CONNECTEDREADONLY:
                break;
            case CLOSED:
                break;
            case AUTH_FAILED:
                break;
            case NOT_CONNECTED:
                break;
        }

        // 创建节点
        String s = zk.create("/aezo", "v1".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL);
        System.out.println("s = " + s);

        // 获取数据
        testGetSync(zk);
        testGetAsync(zk);

        Thread.sleep(1000*60);
        zk.close();
    }

    /**
     * 打印如下：
     *
     * new String(b) = v1
     * stat = 25769803781,25769803781,1595651178729,1595651178729,0,0,0,216176315692285952,2,0,25769803781
     *
     * getData watchedEvent = WatchedEvent state:SyncConnected type:NodeDataChanged path:/aezo
     * newStat1 = 25769803781,25769803782,1595651178729,1595651178802,1,0,0,216176315692285952,2,0,25769803781
     *
     * getData watchedEvent = WatchedEvent state:SyncConnected type:NodeDataChanged path:/aezo // 此行为增加zk.getData("/aezo", this, stat);时才会有
     * newStat2 = 25769803781,25769803783,1595651178729,1595651178821,2,0,0,216176315692285952,2,0,25769803781
     *
     */
    private static void testGetSync(ZooKeeper zk) throws KeeperException, InterruptedException {
        // 创建一个Stat用于存储节点元信息；节点的数据信息同步方法可直接返回异步方法可通过回调获取
        Stat stat = new Stat();
        byte[] b = zk.getData("/aezo", new Watcher() {
            // 此Watcher是监控节点在数据发生变化时触发，且只会触发一次
            @Override
            public void process(WatchedEvent watchedEvent) {
                System.out.println("getData watchedEvent = " + watchedEvent);

                // 由于Watcher只会触发一次，因此此处重新watch，从而每次修改数据都可以监控到
                try {
                    zk.getData("/aezo", this, stat);
                    // zk.getData("/aezo", true, stat); // true表示重新创建new ZooKeeper时的监控
                } catch (KeeperException | InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }, stat);
        System.out.println("new String(b) = " + new String(b)); // new String(b) = v1
        System.out.println("stat = " + stat);


        Stat newStat = zk.setData("/aezo", "v2".getBytes(), 0);
        System.out.println("newStat1 = " + newStat);

        // 如果不在Watcher中增加zk.getData("/aezo", this, stat);的重新调用，则第二次修改数据不会被监听到
        newStat = zk.setData("/aezo", "v2".getBytes(), newStat.getVersion());
        System.out.println("newStat2 = " + newStat);
    }

    /**
     * ------async start--------
     * ------async end--------
     * ------async callback--------
     * o = abc
     * new String(bytes) = v2
     */
    private static void testGetAsync(ZooKeeper zk) {
        System.out.println("------async start--------");
        zk.getData("/aezo", new Watcher() {
            @Override
            public void process(WatchedEvent watchedEvent) {
                System.out.println("getData2 watchedEvent = " + watchedEvent);
            }
        }, new AsyncCallback.DataCallback() {
            @Override
            public void processResult(int i, String s, Object o, byte[] bytes, Stat stat) {
                System.out.println("------async callback--------");
                System.out.println("o = " + o); // o = abc
                System.out.println("new String(bytes) = " + new String(bytes)); // new String(bytes) = v2
            }
        }, "abc");
        System.out.println("------async end--------");
    }
}
```
</details>

### 实现分布式配置中心/服务发现

- 使用zk的`watch`功能
- 参考：https://github.com/oldinaction/smjava/tree/master/zookeeper/src/main/java/cn/aezo/zookeeper/distributed_config_center_service_discover

### 实现分布式锁

- 使用zk的session功能可防止死锁
- 使用zk的sequence+watch
    - 使用zk的`watch`功能可在释放锁时，其他节点更快得知(如果主动轮询判断是否可获取锁则会有延时)
    - 使用sequence可让后一个节点关注前一个节点的变化。永远让第一个节点获得锁，当第一个节点执行完毕后释放锁，从而触发后面一个节点的事件回调进行锁获取
        - 释放锁只会给后一个节点发送回调通知，如果释放锁给全部节点发送回调，一个弊端是zk需要对多个节点发送数据，另外一个弊端是其他节点获取通知后可能产生锁争抢
- 参考：https://github.com/oldinaction/smjava/tree/master/zookeeper/src/main/java/cn/aezo/zookeeper/distributed_lock


---

参考文章

[^1]: https://www.cnblogs.com/zz-ksw/p/12786067.html

