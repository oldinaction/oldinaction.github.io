---
layout: "post"
title: "HBase"
date: "2021-07-18 12:01"
categories: bigdata
tags: [hadoop, db]
---

## 简介

> Use Apache HBase™ when you need random, realtime read/write access to your Big Data. This project's goal is the hosting of very large tables -- billions of rows X millions of columns -- atop clusters of commodity hardware. Apache HBase is an open-source, distributed, versioned, non-relational database modeled after Google's Bigtable: A Distributed Storage System for Structured Data by Chang et al. Just as Bigtable leverages the distributed data storage provided by the Google File System, Apache HBase provides Bigtable-like capabilities on top of Hadoop and HDFS.

- [官网](http://hbase.apache.org/)、[wiki v2.3](http://hbase.apache.org/2.3/book.html)、[hbase相关配置说明](http://abloz.com/hbase/book.html#hbase_default_configurations)
- HBase的全称是Hadoop Database，是一个高可靠性，高性能、面向列、可伸缩、实时读写的分布式数据库
    - 利用Hadoop HDFS作为其文件存储系统，利用Hadoop MapReduce来处理HBase中的海量数据，利用Zookeeper作为其分布式协同服务
    - 主要用来存储非结构化和半结构化数据的松散数据（列存NoSQL数据库，NoSQL的全称是Not Only SQL，泛指非关系型数据库）
- [phoenix](https://phoenix.apache.org/index.html)，phoenix支持jdbc连接和标准的SQL语句，架构上处于hbase和client之间，从而client只需要提交标准SQL即可

### HBase数据模型

- Rowkey
    - 决定一行数据，每行记录的唯一标识
    - 按照字典序排序
    - RowKey只能存储64K的字节数据，但是一般使用10-100个字节
- Column Family & Qualifier
    - HBase表中的每个列都归属于某个列族，列族必须作为表模式(schema)定义的一部分预先给出。如 `create 'test', 'course'`
    - 列名以列族作为前缀，每个“列族”都可以有多个列成员(column)；如course:math, course:english, 新的列族成员（列）可以随后按需、动态加入
    - 权限控制、存储以及调优都是在列族层面进行的
    - HBase把同一列族里面的数据存储在同一目录下，由几个文件保存
- TimeStamp时间戳
    - 在HBase每个cell存储单元对同一份数据有多个版本，根据唯一的时间戳来区分每个版本之间的差异，不同版本的数据按照时间倒序排序，最新的数据版本排在最前面
    - 时间戳的类型是64位整型
    - 时间戳可以由HBase(在数据写入时自动)赋值，此时间戳是精确到毫秒的当前系统时间
    - 时间戳也可以由客户显式赋值，如果应用程序要避免数据版本冲突，就必须自己生成具有唯一性的时间戳
- Cell
    - 由行和列的坐标交叉决定
    - 单元格是有版本的
    - 单元格的内容是未解析的字节数组
    - 由 **`{rowKey, column(=<family>+<qualifier>), version}`** 唯一确定的单元，rowKey类似主键
    - cell中的数据是没有类型的，全部是字节数组形式存贮

### 架构

![hbase-arch.png](/data/images/bigdata/hbase-arch.png)

#### 角色介绍

- Client
    - 包含访问HBase的接口并维护cache来加快对HBase的访问
- Zookeeper
    - 保证任何时候，集群中只有一个活跃master
    - 存储所有region(表名)的寻址入口
    - 实时监控region server的上线和下线信息，并实时通知master
    - 存储HBase的schema和table元数据
- HMaster
    - 为region server分配region
    - 负责region server的负载均衡
    - 发现失效的region server并重新分配其上的region
    - 管理用户对table的增删改操作
- HRegionServer
    - region server维护region，处理对这些region的IO请求
    - region server负责切分在运行过程中变得过大的region

#### HRegionServer组件介绍

- HRegion
    - HBase自动把表水平划分成多个区域(region)，每个region会保存一个表里某段连续的数据
    - 每个表一开始只有一个region，随着数据不断插入表，region不断增大，当增大到一个阈值的时候，region就会等分会两个新的region（裂变），保存到不同的RegionServer
    - HRegion是HBase中分布式存储和负载均衡的最小单元。最小单元就表示不同的HRegion可以分布在不同的 HRegion server上
    - 一个HRegion由多个store组成，一个store对应一个CF（列族）
- Store中的Memstore与Storefile
    - store包括位于内存中的memstore和位于磁盘(hdfs)的storefile。写操作先写入memstore，当memstore中的数据达到某个阈值，regionserver会启动flashcache进程写入storefile，每次写入形成单独的一个storefile
    - 当storefile文件的数量增长到一定阈值后，系统会进行合并(minor、major)，在合并过程中会进行版本合并和删除工作(majar)，形成更大的storefile
    - 当一个region所有storefile的大小和数量超过一定阈值后，会把当前的region分割为两个，并由hmaster分配到相应的regionserver服务器，实现负载均衡
    - 客户端检索数据，先在memstore找，找不到去blockcache，找不到再找storefile(从storefile找到的数据会缓存到blockcache)
    - StoreFile以HFile格式保存在HDFS上

#### HBase读写流程

- 读流程
    - 客户端从zookeeper中获取meta表(存储HBase表字段信息)所在的regionserver节点信息
    - 客户端访问meta表所在的regionserver节点，获取到region所在的regionserver信息
    - 客户端访问具体的region所在的regionserver，找到对应的region及store
    - 然后从memstore中读取数据，如果读取到了那么直接将数据返回，如果没有，则去blockcache读取数据
    - 如果blockcache中读取到数据，则直接返回数据给客户端，如果读取不到，则遍历storefile文件，查找数据
    - 如果从storefile中读取到数据，那么需要将数据先缓存到`blockcache`中（方便下一次读取），然后再将数据返回给客户端
        - blockcache是内存空间，如果缓存的数据比较多，满了之后会采用LRU策略，将比较老的数据进行删除
        - blockcache有三块内存空间(类似JVM的新生代)，第一次、第二次、第三次访问分别放到第一个、第二个、第三个内存空间，淘汰时会优先淘汰第一个内存空间
- 写流程
    ​- 客户端从zookeeper中获取meta表所在的regionserver节点信息
    - 客户端访问meta表所在的regionserver节点，获取到region所在的regionserver信息
    - 客户端访问具体的region所在的regionserver，找到对应的region及store
    - 开始写数据，写数据的时候会先想hlog中写一份数据（方便memstore中数据丢失后能够根据hlog恢复数据，向hlog中写数据的时候也是优先写入内存，后台会有一个线程定期异步刷写数据到hdfs，如果hlog的数据也写入失败，那么数据就会发生丢失）
    - hlog写数据完成之后，会先将数据写入到memstore，memstore默认大小是64M，当memstore满了之后会进行统一的溢写操作，将memstore中的数据持久化到hdfs中
    - 频繁的溢写会导致产生很多的小文件，因此会进行文件的合并，文件在合并的时候有两种方式，minor和major，minor表示小范围文件的合并，major表示将所有的storefile文件都合并成一个

## HBase安装

- 本文基于Hbase v2.3.5(要求JDK1.8, Hadoop v2.10.x), [下载](https://mirrors.bfsu.edu.cn/apache/hbase/2.3.5/hbase-2.3.5-bin.tar.gz)
- HA安装参考：http://hbase.apache.org/book.html#quickstart_fully_distributed
- HMaster: node01、node04(备), HRegionServer: node02-node04
- 设置时间同步，关闭防火墙，node01/node04可免密登录其他机器(test账号)
- 安装

```bash
## node01上执行
cd /opt/bigdata
tar -zxvf hbase-2.3.5-bin.tar.gz
rm -rf /opt/bigdata/hbase-2.3.5/docs/ # 加快之后传输速度
# 开启JAVA_HOME配置，即`export JAVA_HOME=/usr/java/jdk1.8.0_202-amd64`
# 关闭内置ZK，即`export HBASE_MANAGES_ZK=false`
vi /opt/bigdata/hbase-2.3.5/conf/hbase-env.sh
# 参考下文配置
vi /opt/bigdata/hbase-2.3.5/conf/hbase-site.xml
# 设置RegionServer分布在哪几台节点，此处node02、node03、node04(换行写入，删掉原来的localhost)
vi /opt/bigdata/hbase-2.3.5/conf/regionservers
# 创建下列文件，写入`node04`备用Master，达到高可用
vi /opt/bigdata/hbase-2.3.5/conf/backup-masters
# 拷贝hdfs-site.xml文件到conf目录下
cp /opt/bigdata/hadoop-2.10.1/etc/hadoop/hdfs-site.xml /opt/bigdata/hbase-2.3.5/conf
# 复制文件到node02-node04节点。/opt/bigdata所有者为test，如果为root可以先移动过去再修改文件所有权
scp -r /opt/bigdata/hbase-2.3.5 test@node02:/opt/bigdata
scp -r /opt/bigdata/hbase-2.3.5 test@node03:/opt/bigdata
scp -r /opt/bigdata/hbase-2.3.5 test@node04:/opt/bigdata

## 在node01-node04上，增加配置 `export HBASE_HOME=/opt/bigdata/hbase-2.3.5`，并在export PATH后面加上`:$HBASE_HOME/bin`
vi /etc/profile
source /etc/profile

## 在node01上(master节点)启动，会自动其他其他RegionServer节点。jps查看会出现HMaster、HRegionServer的进程
start-hbase.sh
# 进入hbase命令行，显示 `hbase(main):001:0>`
hbase shell
# 访问hbase管理页面
http://node01:16010/
```
- 在 hbase-site.xml 中增加如下配置

```xml
<configuration>
  <!-- 会自动在hdfs中创建hbase目录(data表空间数据目录，WALs存储未过期的日志，oldWALs存储已过期的2天内的日志) -->
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://aezocn/hbase</value>
  </property>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <!-- zk中默认使用 /hbase 的命名空间 -->
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>node01,node02,node03</value>
  </property>
</configuration>
```

## 启停

```bash
# 在node01上(master节点)启动，会自动其他其他RegionServer节点。jps查看会出现HMaster、HRegionServer的进程
start-hbase.sh
# 进入hbase命令行，显示 `hbase(main):001:0>`，`help`查看命令帮助
hbase shell
# 访问hbase管理页面
http://node01:16010/

# 停止
stop-hbase.sh
```

## 命令

```bash
# 进入命令行
hbase shell
# 查看某个HStoreFile文件
# 下列HStoreFile，不是一般的文本格式，需要使用以下命令查看，返回结果如下
# K: 1/cf:name/1626701620132/Put/vlen=8/seqid=4 V: zhangsan
# Scanned kv count -> 1
hbase hfile -p -f /hbase/data/default/psn/c6eb6d681adeb57094901c220f049784/cf/6b35a028d9ff43eb9ef9533968e01da4

## hbase shell命令
help # 查看命令帮助
help "create" # 查看某个命令帮助，注意双引号

# 列举命名空间，类似数据库。默认有hbase(元数据)、default(默认)
list_namespace
# 列举某个表空间的表
list_namespace_tables 'hbase'

# 在当前表空间创建表psn, 并定义一个column family名为cf. 对应在hdfs中创建 /hbase/data/default/psn 文件夹
create 'psn', 'cf'
# 列举当前表空间的表
list

# 往psn表中插入一条数据，rowKey=1(类似主键), cf族中name=zhangsan
put 'psn', '1', 'cf:name', 'zhangsan'
put 'psn', '2', 'cf:name', 'lisi'
put 'psn', '1', 'cf:name', 'zhang san' # 插入新值，等同于修改原数据(获取数据时，会返回最新时间戳下的数据)
# 查询psn中，rowKey=1的name列值. 返回CELL：timestamp=2021-07-19T21:28:49.334, value=zhang san
get 'psn', '1', 'cf:name'

# 查询psn表的所有数据，尽量规避使用scan
scan 'psn'
# 统计psn表行个数
count 'psn'
# 清空psn表
truncate 'psn'

# 必须先禁用表后，才能删除表
disable 'psn'
drop 'psn'

# 手动刷新缓存，每次手动或自动flush都会产生一个HStoreFile(达到一定条件则会进行合并)
flush 'psn'
```

## 客户端API操作(java)

- HBase支持多种语言的API操作，参考：http://hbase.apache.org/2.3/book.html#external_apis
- 基于Java操作时，对于对象的序列化可使用`ProtoBuf`
    - 从而将相同rowKey的列操作进行合并成对象提交，从而减少了rowKey的重复次数，到达节省空间的目的
    - 由于序列化后，查看hfile时无法直接人眼识别，需要反序列化才可





---

hbase api前缀过滤器
mr <-> hbase
hbase表设计原则: 用户角色设计，协处理器(触发器删除修改)、设计原则
lsm
