---
layout: "post"
title: "Hadoop"
date: "2018-03-13 20:31"
categories: bigdata
tags: [hadoop]
---

## 简介

- `Hadoop`([hædu:p])作者`Doug cutting`，名字来源于Doug Cutting儿子的玩具大象
- 模块
    - 分布式存储系统`HDFS`(Hadoop Distributed File System)
    - 分布式计算框架`Hadoop MapReduce`
    - `Hadoop YARN`
    - `Hadoop Common`
- 网址
    - [官网](http://hadoop.apache.org/)
    - [r1.0.4中文文档](http://hadoop.apache.org/docs/r1.0.4/cn/index.html)
    - [r2.5.2文档](http://hadoop.apache.org/docs/r2.5.2/)
- 谷歌论文(理论来源)
    - 《The Google File System》 2003年
    - 《MapReduce: Simplified Data Processing on Large Clusters》 2004年
    - 《Bigtable: A Distributed Storage System for Structured Data》 2006年
- 版本：2016年10月hadoop-2.6.5，2017年12月hadoop-3.0.0
- [大数据生态CDH提供商](http://www.cloudera.com)
- 本文基于`hadoop-2.5.1`**(需要`jdk1.7`)**

## HDFS概念

- HDFS优缺点
    - 优点：高容错性(自动保存副本，自动恢复)、适合批处理、适合大数据(TB/PB)处理、可构建在廉价机器上
    - 缺点：占用内存大、修改文件成本过高
- 存储模型
    - 文件线性按字节切割成块(block)，具有offset，id
    - 文件与文件的block大小可以不一样
    - 一个文件除最后一个block，其他block大小一致
    - block的大小依据硬件的I/O特性调整
    - block被分散存放在集群的节点中，具有location
    - Block具有副本(replication)，没有主从概念，副本不能出现在同一个节点。副本是满足可靠性和性能的关键
    - 文件上传可以指定block大小和副本数，上传后只能修改副本数
    - 一次写入多次读取，不支持修改
    - 支持追加数据
    - 数据块/数据存储单元(Block)说明
        - 文件被切分成固定大小的数据块，数据块默认大小为128MB(Hadoop 1.x默认为64M，后来发展为256M，可调整)。若文件大小不到128MB，则单独存成一个Block
        - 一个文件存储方式：按大小被切分成若干个Block，存储到不同节点上。默认情况下每个Block都有三个副本
        - Block大小和副本数通过Client端上传文件时设置，文件上传成功后副本数可以变更，Block Size不可变更
- 架构设计
    - HDFS是一个主从(Master/Slaves)架构
    - 由一个NameNode和一些DataNode组成
    - 面向文件包含：文件数据(data)和文件元数据(metadata)
    - NameNode负责存储和管理文件元数据，并维护了一个层次型的文件目录树
    - DataNode负责存储文件数据(block块)，并提供block的读写
    - DataNode与NameNode维持心跳，并汇报自己持有的block信息
    - Client和NameNode交互文件元数据和DataNode交互文件block数据
- 角色功能
    - `NameNode`(NN)
        - NameNode主要功能
            - **完全基于内存存储文件`metadate`元数据、目录结构、文件block的映射**
                - 需要持久化方案保证数据可靠性
                - 提供副本放置策略
            - 接受客户端的读写服务
        - NameNode的metadate信息说明
            - 元数据信息包括 **`fsimage`和`edits`**
                - `fsimage` metadata存储到磁盘文件名为fsimage(format格式化的时候产生)
                - `edits` 记录对metadata的操作日志(客户端读写日志)，会自动合并到fsimage中
                - 以上两个文件主要记录了文件包含哪些Block，Block保存在哪个DataNode(由DataNode启动时上报)
            - NameNode的metadate信息在启动后会加载到内存
            - Block的位置信息不会保存到fsimage(NN将block位置存放到内存中)
    - `DataNode`(DN)
        - 基于本地磁盘存储Block(文件的形式)
        - 并保存block的校验和数据保证block的可靠性
        - 与NameNode保持心跳，汇报block列表状态
            - 启动DN线程的时候会向NN汇报block信息(NN将block位置存放到内存中)
            - 通过向NN发送心跳保持与其联系（3秒一次），如果NN 10分钟没有收到DN的心跳，则认为其已经lost，并copy其上的block到其它DN
    - `SecondaryNameNode`(SNN, 非HA模式)
        - 它不是NN的备份，也不是HA，它的主要工作是帮助NN合并edits日志，减少NN启动时间
        - SNN执行合并时机：根据配置文件设置的时间间隔`fs.checkpoint.period`默认3600秒；根据配置文件设置edits日志大小 `fs.checkpoint.size`规定edits文件的最大值默认是64MB
- 元数据持久化
    - NameNode使用了FsImage(镜像) + EditLog(日志)整合的方案。类似redis的持久化方式
        - HDFS搭建时会格式化，格式化操作会产生一个空的FsImage
        - 当Namenode启动时，它从硬盘中读取Editlog和FsImage
        - 将所有Editlog中的事务作用在内存中的FsImage上
        - 并将这个新版本的FsImage从内存中保存到本地磁盘上
        - 然后删除旧的Editlog，因为这个旧的Editlog的事务都已经作用在FsImage上了
- 安全模式
    - Namenode启动后会进入一个称为安全模式的特殊状态
    - 处于安全模式的Namenode是不会进行数据块的复制的
    - Namenode从所有的 Datanode接收心跳信号和块状态报告
    - 每当Namenode检测确认某个数据块的副本数目达到这个最小值，那么该数据块就会被认为是副本安全(safely replicated)的
    - 在一定百分比（这个参数可配置）的数据块被Namenode检测确认是安全之后（加上一个额外的30秒等待时间），Namenode将退出安全模式状态
    - 接下来它会确定还有哪些数据块的副本没有达到指定数目，并将这些数据块复制到其他Datanode上
- Block的副本放置策略
    - 第一个副本：放置在上传文件的DN；如果是集群外提交，则随机挑选一台磁盘不太满，CPU不太忙的节点
    - 第二个副本：放置在于第一个副本不同的 机架的节点上
    - 第三个副本：与第二个副本相同机架的节点
    - 更多副本：随机节点

### 读写流程

- 写流程

    ![hadoop-hdfs-write](/data/images/bigdata/hadoop-hdfs-write.png)
    - Client和NN连接创建文件元数据
    - NN判定元数据是否有效
    - NN触发副本放置策略，返回一个有序的DN列表
    - Client和DN建立Pipeline连接
    - Client将块切分成packet（64KB），并使用chunk（512B）+ chucksum（4B）填充
    - **基于流式传输数据，其实也是变种的并行计算**
        - Client将packet放入发送队列dataqueue中，并向第一个DN发送
        - 第一个DN收到packet后本地保存并发送给第二个DN
        - 第二个DN收到packet后本地保存并发送给第三个DN
    - 当block传输完成，DN们各自向NN汇报，同时client继续传输下一个block，client的传输和block的汇报也是并行的
- 读流程

    ![hadoop-hdfs-read](/data/images/bigdata/hadoop-hdfs-read.png)
    - 为了降低整体的带宽消耗和读取延时，HDFS会尽量让读取程序读取离它最近的副本
    - 如果读取程序的本机上，则直接读取本机
    - 如果在读取程序的同一个机架上有一个副本，那么就读取该副本
    - 如果一个HDFS集群跨越多个数据中心，那么客户端也将首先读本地数据中心的副本
    - 语义：下载一个文件
        - Client和NN交互文件元数据获取fileBlockLocation
        - NN会按距离策略排序返回
        - Client尝试下载block并校验数据完整性
    - **语义：下载一个文件其实是获取文件的所有的block元数据，那么子集获取某些block应该成立**
        - HDFS支持client给出文件的offset自定义连接哪些block的DN，自定义获取数据
        - 这个是支持计算层的分治、并行计算的核心




## Hadoop 2.x 概念及架构

- Hadoop 2.x由HDFS、MapReduce和YARN三个分支构成
    - HDFS：NN Federation、 HA
    - MapReduce：运行在YARN上的MR
    - YARN：资源管理系统
- 解决HDFS 1.0中单点故障和内存受限问题
    - 解决单点故障
        - HDFS HA：通过多个主备NameNode解决
        - 如果主NameNode发生故障，则切换到备NameNode上(备NameNode会同步主NameNode元数据)
        - 所有DataNode同时向两个NameNode汇报数据块信息
    - 解决内存受限问题
        - HDFS Federation(联邦)
        - 水平扩展，支持多个NameNode
        - 每个NameNode分管一部分目录
        - 所有NameNode共享所有DataNode存储资
- 基于Zookeeper自动切换方案(也可手动切换)
    - `Zookeeper Failover Controller`(ZKFC) 监控NameNode健康状态，并向Zookeeper注册NameNode。NameNode挂掉后，ZKFC为NameNode竞争锁，获得ZKFC锁的NameNode变为active
- HA架构图

    ![HA架构图](/data/images/bigdata/hadoop-ha.png)

    - `NameNode`分为`Active`(主)和`Standby`(备)。主备切换的条件是两天NN的元数据一致
    - `NameNode(Active)`会将`edits`文件保存到`JournalNode`中(服务数>=2)。`NameNode(Standby)`会同步`JournalNode`中的`edits`数据。初始化时，将其中一台进行`fsimage`格式化，然后将此`fsimage`复制到其他机器。确保元数据(fsimage + edits)一致
    - 所有DataNode启动时同时向两个NameNode汇报数据块信息
    - `Zookeeper Failover Controller`和`NameNode`是一一对应。作用：通过远程命令控制`NameNode`切换；对`NameNode`做健康检查，并汇报给`Zookeeper`

- Federation架构图

    ![Federation架构图](/data/images/bigdata/hadoop-federation.gif)

    - 通过多个namenode/namespace把元数据的存储和管理分散到多个节点中，使到namenode/namespace可以通过增加机器来进行水平扩展。多个namenode相会独立
    - 能把单个namenode的负载分散到多个节点中，在HDFS数据规模较大的时候不会也降低HDFS的性能。可以通过多个namespace来隔离不同类型的应用，把不同类型应用的HDFS元数据的存储和管理分派到不同的namenode中

## MapReduce

- Map-reduce的思想就是"分而治之"
- 主要分为`Map`和`Reduce`两个阶段，也可细分为`Split`、`Map`、`Shuffler(sort、copy、merge)`、`Reduce`几个阶段
- split大小：`max(min.split,min(max.split, block))` 其中默认min.split=10M，max.split=100M，block=128M
- MapReduce架构图

    ![MapReduce架构图](/data/images/bigdata/hadoop-mp.png)

## 安装

### Hadoop 2.x HA 安装

> HA模式安装：http://hadoop.apache.org/docs/r2.5.2/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html

- 服务器配置

服务器名 | ip | NameNode| DataNode| Zookeeper| ZKFC| JN|
---------|----------|---------|---------|---------|---------|---------
server1 | 192.168.6.131 | Y |   | Y | Y
server2 | 192.168.6.132 | Y | Y | Y | Y | Y
server3 | 192.168.6.133 |   | Y | Y |   | Y
server4 | 192.168.6.134 |   | Y |   |   | Y

- 安装并启动Zookeeper，参考《Zookeeper》
- `date` 检查4台机器的时间是否相差不大(30秒内)，并查看是否关闭防火墙
- 4台主机的`/etc/hosts`文件都需要包含一下内容

    ```bash
    192.168.6.131	server1
    192.168.6.132	server2
    192.168.6.133	server3
    192.168.6.134	server4
    ```
- 免密码登录：使server1可以免密码登录到其他3台服务器。启动hdfs的时候通过server1启动其他3台机器
   
    ```bash
    ## 为4台机器都生成ssh密钥和公钥文件(可通过xshell的快速命令发送到全部会话)
    ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa # 或者直接 ssh-keygen
    ## 将本机器公钥文件内容追加到认证文件中。此时可以通过命令如`ssh server1`无需密码即可登录本地机器，记得要`exit`退出会话
    cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
    ## 将server1和server2(NameNode)的公钥文件内容追加到其他3台机器的的认证文件中
    # 在server1下执行复制server1的公钥到其他机器的/root目录
    scp ~/.ssh/id_dsa.pub root@server2:/root/
    scp ~/.ssh/id_dsa.pub root@server3:/root/
    scp ~/.ssh/id_dsa.pub root@server4:/root/
    # 分别在其他3台服务器下运行公钥追加到认证文件命令(>>表示追加)
    cat ~/id_dsa.pub >> ~/.ssh/authorized_keys
    # 测试登录
    ssh server3
    # server2公钥复制同理
    ```
- 在server1上进行安装hadoop
    - `tar -zxvf hadoop-2.5.1_x64.tar.gz -C /opt/soft`
        - 解压`hadoop-2.5.1_x64.tar.gz`(官方提供的是32位；32位的包可以运行在64位机器上，只是有警告；反之不行)
    - `cd /opt/soft/hadoop-2.5.1`
    - `vi etc/hadoop/hadoop-env.sh`修改`export JAVA_HOME=${JAVA_HOME}`的JAVA_HOME，如`export JAVA_HOME=/opt/soft/jdk1.7.0_80`
    - `vi etc/hadoop/core-site.xml` 进行如下配置。[配置项参考](http://hadoop.apache.org/docs/r2.5.2/hadoop-project-dist/hadoop-common/core-default.xml)
        
        ```xml
        <configuration>
            <property>
                <!--配置NameNode的dfs.nameservices-->
                <name>fs.defaultFS</name>
                <value>hdfs://aezocn</value>
            </property>
            <property>
                <!-- Zookeeper集群 -->
                <name>ha.zookeeper.quorum</name>
                <value>server1:2181,server2:2181,server3:2181</value>
            </property>
            <property>
                <!-- fsimage文件会存放在此目录，默认是/tmp/hadoop-${user.name}，而此目录重启会清空，容易造成fsimage丢失。会自动创建 -->
                <name>hadoop.tmp.dir</name>
                <value>/opt/data/hadoop</value>
            </property>
        </configuration>
        ```
    - `vi etc/hadoop/hdfs-site.xml` 进行如下配置。[配置项参考文档]( http://hadoop.apache.org/docs/r2.5.2/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)

        ```xml
        <configuration>
            <property>
                <!-- 一个hdfs实例的唯一标识 -->
                <name>dfs.nameservices</name>
                <value>aezocn</value>
            </property>
            <property>
                <!-- NameNode标识(dfs.ha.namenodes.[dfs.nameservices])，多个用逗号分割 -->
                <name>dfs.ha.namenodes.aezocn</name>
                <value>nn1,nn2</value>
            </property>
            <property>
                <!-- rpc协议用于hdfs文件上传和读取 -->
                <name>dfs.namenode.rpc-address.aezocn.nn1</name>
                <value>server1:8020</value>
            </property>
            <property>
                <name>dfs.namenode.rpc-address.aezocn.nn2</name>
                <value>server2:8020</value>
            </property>
            <property>
                <!-- http协议用于后台监控 -->
                <name>dfs.namenode.http-address.aezocn.nn1</name>
                <value>server1:50070</value>
            </property>
            <property>
                <name>dfs.namenode.http-address.aezocn.nn2</name>
                <value>server2:50070</value>
            </property>
            <property>
                <!-- 指定3台JournalNode服务地址，jndir目录会自动新建，用于存放edits数据 -->
                <name>dfs.namenode.shared.edits.dir</name>
                <value>qjournal://server2:8485;server3:8485;server4:8485/jndir</value>
            </property>
            <property>
                <!-- 为JournalNode存放edits数据文件的根目录(会在此目录创建jndir)，会自动创建 -->
                <name>dfs.journalnode.edits.dir</name>
                <value>/opt/data/hadoop/journalnode</value>
            </property>
            <property>
                <!-- 启用Zookeeper Failover Controller自动切换 -->
                <name>dfs.ha.automatic-failover.enabled</name>
                <value>true</value>
            </property>
            <property>
                <!-- 帮助客户端查询一个活动的NameNode(Active)，固定为下面的类名 -->
                <name>dfs.client.failover.proxy.provider.aezocn</name>
                <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
            </property>
            <!-- 对NameNode进行远程切换时，需要运行远程命令。下面为ssh相关配置 -->    
            <property>
                <name>dfs.ha.fencing.methods</name>
                <value>sshfence</value>
            </property>
            <property>
                <name>dfs.ha.fencing.ssh.private-key-files</name>
                <value>/root/.ssh/id_dsa</value>
            </property>
        </configuration>
        ```
    - `vi etc/hadoop/slaves` 配置`DataNode`主机名

        ```bash
        server2
        server3
        server4
        ```
- 拷贝项目目录到其他3台机器，如：`scp -r /opt/soft/hadoop-2.5.1/ root@server2:/opt/soft/`
- 配置环境变量
    - 配置4台机器的hadoop环境变量，`vi ~/.bash_profile`

    ```bash
    export HADOOP_HOME=/opt/soft/hadoop-2.5.1
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
    ```
    - 如果几台机器的配置一致，可通过`scp ~/.bash_profile root@server2:/root/`进行server1拷贝到server2
    - `source ~/.bash_profile` 使`.bash_profile`生效
- `hadoop-daemon.sh start journalnode` 分别启动三台`JournalNode`(server2、server3、server4)。并查看日志是否有错`tail -200 /opt/soft/hadoop-2.5.1/logs/hadoop-root-journalnode-server2.log`
- 初始化元数据
    - 格式化`server1(NameNode)`的hdfs：`hdfs namenode -format` 第一次运行格式化hdfx获得元数据(不报错则成功)。会创建上述`/opt/data/hadoop`文件夹，并在里面创建`fsimage`
    - 拷贝上述fsimage到另外一台`NameNode(server2)`：`scp -r /opt/data/hadoop root@server2:/opt/data/`
- 在某一台NameNode上初始化Zookeeper：`hdfs zkfc -formatZK`
- 启动与停止
    - **`start-dfs.sh`** 在某一台NameNode上启动。
        - 此时server1会通过免密码登录启动其他机器上的hadoop服务(NN、DN、JN、ZKFC)
        - journalnode在上述启动过，此处不会重新启动
        - 单独启动一个NameNode `hadoop-daemon.sh start namenode`
        - 单独启动一个DataNode **`hadoop-daemon.sh start datanode`**
    - **`stop-dfs.sh`** 停止所有hadoop服务
    - 所有的启动日志均在`logs`目录
- 访问`http://192.168.6.131:50070`和`http://192.168.6.132:50070` 查看NameNode监控。会发现一个为active，一个为standby
    - 关闭active对应的NameNode服务，可发现standby对应的服务变为active，实现了NameNode接管。如server2无法切换为active，可查看对应ZKFC的日志 `tail -200 /opt/soft/hadoop-2.5.1/logs/hadoop-root-zkfc-server2.log`。常见无法切换错误
        - 提示`Unable to fence NameNode`，可检查是否可进行免密码登录
        - 提示`ssh: bash: fuser: 未找到命令`，可在NameNode上安装 `yum -y install psmisc`
    - 手动切换nn2为active：`hdfs haadmin -transitionToActive nn2`(在未开启自动切换模式下才可使用)

### 单节点安装(不常用)

> 单节点：http://hadoop.apache.org/docs/r2.5.2/hadoop-project-dist/hadoop-common/SingleCluster.html

- 服务器配置

服务器名 | ip | 角色
---------|----------|---------
server1 | 192.168.6.131 | NameNode
server2 | 192.168.6.132 | SecondaryNameNode、DataNode
server3 | 192.168.6.133 | DataNode
server4 | 192.168.6.134 | DataNode

- 检查date、修改hosts、免密码登录(参考上述HA安装)
- 在server1上进行安装hadoop(参考上述HA安装)
    - `vi etc/hadoop/core-site.xml` 进行如下配置
        
        ```xml
        <configuration>
            <!--配置NameNode的主机名和数据传输端口(文件上传下载)-->
            <property>
                <name>fs.defaultFS</name>
                <value>hdfs://server1:9000</value>
            </property>
            <property>
                <name>hadoop.tmp.dir</name>
                <value>/opt/data/hadoop</value>
            </property>
        </configuration>
        ```
    - `vi etc/hadoop/hdfs-site.xml` 进行如下配置

        ```xml
        <configuration>
            <!-- 配置SecondaryNameNode的Http相关端口 -->
            <property>
                <name>dfs.namenode.secondary.http-address</name>
                <value>server2:50090</value>
            </property>
            <property>
                <name>dfs.namenode.secondary.https-address</name>
                <value>server2:50091</value>
            </property>
        </configuration>
        ```
    - `vi etc/hadoop/slaves` 配置`DataNode`主机名

        ```bash
        server2
        server3
        server4
        ```
    - `vi etc/hadoop/masters` 配置`SecondaryNameNode`主机名(默认无此文件。HA模式下无SecondaryNameNode，因此无效此步骤)

        ```bash
        server2
        ```
- 拷贝项目目录到其他3台机器并配置hadoop环境变量(参考上述HA安装)
- 在`server1(NameNode)`上运行
    - `hdfs namenode -format` 在`server1(NameNode)`上运行
    - `start-dfs.sh` 在`server1(NameNode)`上执行
    - `stop-dfs.sh` 停止所有hadoop服务
- 访问`http://192.168.6.131:50070` 查看NameNode监控、`http://192.168.6.132:50090` 查看SecondaryNameNode监控




---

参考文章

- [hdfs-HA原理及安装](http://www.cnblogs.com/tgzhu/category/868038.html)
- [Hadoop集群Web管理工具ambari](http://ambari.apache.org/)

