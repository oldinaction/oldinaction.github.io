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

- **一张表由一组HRegion组成，一个HRegion由一组Store组成，一个Store对应一个列族(CF)，一个Store包含一个Memstore和一组StoreFile，一个StoreFile由一组HFile组成**
- HRegion
    - HBase自动把表水平划分成多个区域(region)，每个region会保存一个表里某段连续的数据
    - 每个表一开始只有一个region，随着数据不断插入表，region不断增大，当增大到一个阈值的时候，region就会等分会两个新的region（裂变），保存到不同的RegionServer
    - HRegion是HBase中分布式存储和负载均衡的最小单元。最小单元就表示不同的HRegion可以分布在不同的 HRegion server上
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

### 基本使用

- 引入依赖

```xml
<!-- https://mvnrepository.com/artifact/org.apache.hbase/hbase-client -->
<dependency>
    <groupId>org.apache.hbase</groupId>
    <artifactId>hbase-client</artifactId>
    <version>2.3.5</version>
</dependency>
```
- 简要代码举例(无需引入core-site.xml等)

```java
import org.apache.hadoop.hbase.*;
import org.apache.hadoop.hbase.client.*;

// ===== 初始化
//创建配置文件对象
Configuration conf = HBaseConfiguration.create();
//加载zookeeper的配置
conf.set("hbase.zookeeper.quorum","node01,node02,node03");
//获取连接
Connection conn = ConnectionFactory.createConnection(conf);
//获取管理对象
Admin admin = conn.getAdmin();
//获取数据操作对象
TableName tableName = TableName.valueOf("phone");
Table table = conn.getTable(tableName);

// ====== 创建表
@Test
public void createTable() throws IOException {
    //定义表描述对象
    TableDescriptorBuilder tableDescriptorBuilder = TableDescriptorBuilder.newBuilder(tableName);
    //定义列族描述对象
    ColumnFamilyDescriptorBuilder columnFamilyDescriptorBuilder = ColumnFamilyDescriptorBuilder.newBuilder("cf".getBytes());
    //添加列族信息给表
    tableDescriptorBuilder.setColumnFamily(columnFamilyDescriptorBuilder.build());
    if(admin.tableExists(tableName)){
        // 必须先禁用表才能删除表
        admin.disableTable(tableName);
        admin.deleteTable(tableName);
    }
    //创建表
    admin.createTable(tableDescriptorBuilder.build());
}

// ====== 插入数据
@Test
public void insert() throws IOException {
    // HBase所有的数据需要转成字节数组，建议使用官方提供的工具类 org.apache.hadoop.hbase.util.Bytes 进行转换，而不是自己手动转换
    Put put = new Put(Bytes.toBytes("1"));
    put.addColumn(Bytes.toBytes("cf"),Bytes.toBytes("name"),Bytes.toBytes("zhangsan"));
    put.addColumn(Bytes.toBytes("cf"),Bytes.toBytes("age"),Bytes.toBytes("18"));
    put.addColumn(Bytes.toBytes("cf"),Bytes.toBytes("sex"),Bytes.toBytes("man"));
    table.put(put);
}

// ===== 获取某行数据
@Test
public void get() throws IOException {
    Get get = new Get(Bytes.toBytes("1"));
    //在服务端做数据过滤，挑选出符合需求的列。如果不设置会把当前行的所有列都取出
    get.addColumn(Bytes.toBytes("cf"),Bytes.toBytes("name"));
    get.addColumn(Bytes.toBytes("cf"),Bytes.toBytes("age"));
    Result result = table.get(get);
    Cell cell1 = result.getColumnLatestCell(Bytes.toBytes("cf"), Bytes.toBytes("name"));
    String name = Bytes.toString(CellUtil.cloneValue(cell1));
    System.out.println(name); // zhangsan
}

// ===== 基于条件和过滤器获取数据: 获取 1-100 行的数据
@Test
public void scanByCondition() throws Exception {
    Scan scan = new Scan();
    scan.withStartRow(Bytes.toBytes("1"));
    scan.withStopRow(Bytes.toBytes("100"));

    //创建过滤器集合，HBase提供多种过滤器
    FilterList filters = new FilterList(FilterList.Operator.MUST_PASS_ALL);
    //创建相等过滤器
    SingleColumnValueFilter filter1 = new SingleColumnValueFilter(Bytes.toBytes("cf"),Bytes.toBytes("age"),CompareOperator.EQUAL,Bytes.toBytes("18"));
    filters.addFilter(filter1);
    //创建前缀过滤器
    PrefixFilter filter2 = new PrefixFilter(Bytes.toBytes("zhang"));
    filters.addFilter(filter2);
    scan.setFilter(filters);

    ResultScanner rss = table.getScanner(scan);
    for (Result rs : rss) {
        Cell cell1 = rs.getColumnLatestCell(Bytes.toBytes("cf"), Bytes.toBytes("name")));
        Cell cell2 = rs.getColumnLatestCell(Bytes.toBytes("cf"), Bytes.toBytes("age")));
        String name = Bytes.toString(CellUtil.cloneValue(cell1)); // zhangsan
    }
}

// ===== 关闭资源
table.close();
admin.close();
conn.close();
```

### 结合MapReduce

- MR是分布式计算框架，对于数据源和数据目的地没有限制，用户可以任意选择，只不过需要实现两个类
    - InputFormat: getsplits()、createRecordReader()
    - OutputFormat: getRecordWriter(), 返回值RecordWriter(write、close)
- 注意
    - 当需要从hbase读取数据的时候，必须使用 TableMapReduceUtil.initTableMapperJob()
    - 当需要写数据到hbase的时候，必须使用 TableMapReduceUtil.initTableReduceJob()
        - 如果再代码逻辑进行实现的时候，不需要reduce，只要是向hbase写数据，那么上面的方法必须存在(reducer=null)

## 设计案例

- 人员角色表
    - 关系型数据库一般需要人员、角色、人员角色关系3张表
    - hbase设计
    
    ```bash
    # 如删除角色时，需要同时删除人员表下的角色信息，此时可以使用协处理器(触发器删除修改)
    # 人员表
    rowkey			    cf1:(属性信息)					  cf2:(角色列表)
    001					cf1:name=..,cf1:age=..,	         cf2:100=10,cf2:200=9
    002
    # 角色表
    rowkey			    cf1:(角色信息)					  cf2:(人员列表)
    100					cf1:name=班长。。。。			   cf2:001=小黑，cf2:002=小宝
    200
    ```

## HBase表设计原则

### 表的设计

#### Pre-Creating Regions

- 默认情况下，在创建HBase表的时候会自动创建一个region分区，当导入数据的时候，所有的HBase客户端都向这一个region写数据，直到这个region足够大了才进行切分
- **预分区**：通过预先创建一些空的regions，这样当数据写入HBase时，会按照region分区情况，在集群内做数据的负载均衡，可以加快批量写入速度

```java
//第一种实现方式是使用admin对象的切分策略
byte[] startKey = ...;      // your lowest key
byte[] endKey = ...;        // your highest key
int numberOfRegions = ...;  // # of regions to create
admin.createTable(table, startKey, endKey, numberOfRegions);

//第二种实现方式是用户自定义切片
byte[][] splits = ...;   // create your own splits
// byte[][] splits = new byte[][] { Bytes.toBytes("100"), Bytes.toBytes("200"), Bytes.toBytes("400"), Bytes.toBytes("500") };
admin.createTable(table, splits);
```

#### Rowkey设计

- Rowkey说明
    - HBase中row key用来检索表中的记录，支持以下三种方式
        - 通过单个row key访问：即按照某个row key键值进行get操作
        - 通过row key的range进行scan：即通过设置startRowKey和endRowKey，在这个范围内进行扫描
        - 全表扫描：即直接扫描整张表中所有行记录
    - 在HBase中，rowkey可以是任意字符串，最大长度64KB，实际应用中一般为10~100bytes，存为byte[]字节数组，一般设计成定长的
    ​- rowkey是按照字典序存储，因此设计row key时，要充分利用这个排序特点，将经常一起读取的数据存储到一块，将最近可能会被访问的数据放在一块
- Rowkey设计原则
    - **越短越好**，提高效率
        - 数据的持久化文件HFile中是按照KeyValue存储的，如果rowkey过长，比如操作100字节，1000万行数据，单单是存储rowkey的数据就要占用10亿个字节，将近1G数据，这样会影响HFile的存储效率
        - HBase中包含缓存机制，每次会将查询的结果暂时缓存到HBase的内存中，如果rowkey字段过长，内存的利用率就会降低，系统不能缓存更多的数据，这样会降低检索效率。
    - **散列原则**，实现负载均衡
        - 如果Rowkey是按时间戳的方式递增，不要将时间放在二进制码的前面，建议将Rowkey的高位作为散列字段，由程序循环生成，低位放时间字段，这样将提高数据均衡分布在每个Regionserver实现负载均衡的几率
        - 如果没有散列字段，首字段直接是时间信息将产生所有新数据都在一个 RegionServer上堆积的热点现象，这样在做数据检索的时候负载将会集中在个别RegionServer，降低查询效率，解决方法如下：
            - 加盐：添加随机值
            - hash：采用md5散列算法取前4位做前缀
            - 反转：将手机号反转
    - **唯一原则**，字典序排序存储
        - 必须在设计上保证其唯一性，rowkey是按照字典顺序排序存储的，因此设计rowkey的时候，要充分利用这个排序的特点，将经常读取的数据存储到一块，将最近可能会被访问的数据放到一块

#### 列族的设计

- **不要在一张表里定义太多的column family**。目前Hbase并不能很好的处理超过2~3个column family的表。因为某个column family在flush的时候，它邻近的column family也会因关联效应被触发flush，最终导致系统产生更多的I/O	。原因：
    - 当开始向hbase中插入数据的时候，数据会首先写入到memstore，而memstore是一个内存结构，每个列族对应一个memstore，当包含更多的列族的时候，会导致存在多个memstore，每一个memstore在flush的时候会对应一个hfile的文件，因此会产生很多的hfile文件。更加严重的是，flush操作的是region级别，当region中的某个memstore被flush的时候，同一个region的其他memstore也会进行flush操作，当某一张表拥有很多列族的时候，且列族之间的数据分布不均匀的时候，会产生更多的磁盘文件
    - 当hbase表的某个region过大，会被拆分成两个，如果我们有多个列族，且这些列族之间的数据量相差悬殊的时候，region的split操作会导致原本数据量小的文件被进一步的拆分，而产生更多的小文件
    - 与 Flush 操作一样，目前 HBase 的 Compaction 操作也是 Region 级别的，过多的列族也会产生不必要的 IO
    - HDFS 其实对一个目录下的文件数有限制的（`dfs.namenode.fs-limits.max-directory-items`）。如果我们有 N 个列族，M 个 Region，那么我们持久化到 HDFS 至少会产生 N\*M 个文件；而每个列族对应底层的 HFile 文件往往不止一个，我们假设为 K 个，那么最终表在 HDFS 目录下的文件数将是 N\*M\*K，这可能会操作 HDFS 的限制

#### in memory

- hbase在LRU缓存基础之上采用了分层设计，整个blockcache分成了三个部分，分别是single、multi和inMemory
- 三者区别如下
    - single：如果一个block第一次被访问，放在该优先队列中
    - multi：如果一个block被多次访问，则从single队列转移到multi队列
    - inMemory：优先级最高，常驻cache，因此一般只有hbase系统的元数据，如meta表之类的才会放到inMemory队列中

#### Max Version

- 创建表的时候，可以通过`ColumnFamilyDescriptorBuilder.setMaxVersions(int maxVersions)`设置表中数据的最大版本，如果只需要保存最新版本的数据，那么可以设置setMaxVersions(1)，保留更多的版本信息会占用更多的存储空间

#### Time to Live

- 创建表的时候，可以通过`ColumnFamilyDescriptorBuilder.setTimeToLive(int timeToLive)`设置表中数据的存储生命期，过期数据将自动被删除，例如如果只需要存储最近两天的数据，那么可以设置`setTimeToLive(2 * 24 * 60 * 60)`

#### Compaction

- HBase为了防止小文件（被刷到磁盘的menstore）过多，以保证保证查询效率，hbase需要在必要的时候将这些小的store file合并成相对较大的store file，这个过程就称之为compaction。在hbase中，主要存在两种类型的compaction：minor compaction和major compaction
    - 在HBase中，数据在更新时首先写入WAL 日志(HLog)和内存(MemStore)中，MemStore中的数据是排序的，当MemStore累计到一定阈值时，就会创建一个新的MemStore，并且将老的MemStore添加到flush队列，由单独的线程flush到磁盘上，成为一个StoreFile。于此同时， 系统会在zookeeper中记录一个redo point，表示这个时刻之前的变更已经持久化了(**minor compact**)
    - StoreFile是只读的，一旦创建后就不可以再修改，因此Hbase的更新其实是不断追加的操作。当一个Store中的StoreFile达到一定的阈值后，就会进行一次合并(**major compact**)，将对同一个key的修改合并到一起，形成一个大的StoreFile，当StoreFile的大小达到一定阈值后，又会对 StoreFile 进行分割(**split**)，等分为两个StoreFile
- 由于对表的更新是不断追加的，处理读请求时，需要访问Store中全部的StoreFile和MemStore，将它们按照row key进行合并，由于StoreFile和MemStore都是经过排序的，并且StoreFile带有内存中索引，通常合并过程还是比较快的
- 实际应用中，可以考虑必要时手动进行major compact，将同一个row key的修改进行合并形成一个大的StoreFile。同时，可以将StoreFile设置大些，减少split的发生
- minor compaction：是较小、很少文件的合并，它的运行机制由以下几个参数共同决定
    - `hbase.hstore.compaction.min` 默认值为 3，表示至少需要三个满足条件的store file时，minor compaction才会启动
    - `hbase.hstore.compaction.max` 默认值为10，表示一次minor compaction中最多选取10个store file
    - `hbase.hstore.compaction.min.size` 表示文件大小小于该值的store file 一定会加入到minor compaction的store file中
    - `hbase.hstore.compaction.max.size` 表示文件大小大于该值的store file 一定不会被添加到minor compaction
    - `hbase.hstore.compaction.ratio` 将 StoreFile 按照文件年龄排序，minor compaction 总是从 older store file 开始选择，如果该文件的 size 小于后面 hbase.hstore.compaction.max 个 store file size 之和乘以 ratio 的值，那么该 store file 将加入到 minor compaction 中。如果满足 minor compaction 条件的文件数量大于 hbase.hstore.compaction.min，才会启动
- major compaction：是将所有的store file合并成一个，触发major compaction的可能条件有
    - major_compact 命令
    - majorCompact() API
    - region server自动运行
        - `hbase.hregion.majorcompaction` 默认为24 小时
        - `hbase.hregion.majorcompaction.jetter` 默认值为0.2 防止region server 在同一时间进行major compaction。对参数hbase.hregion.majorcompaction 规定的值起到浮动的作用，假如两个参数都为默认值24和0.2，那么major compact最终使用的数值为：19.2~28.8 这个范围

### 写优化	

#### WAL日志

- 优化建议
    - 根据业务关注点在WAL机制与写入吞吐量之间做出选择，决定是否需要写WAL或者调整写入频率
- 优化原理
    - 数据写入流程可以理解为一次顺序写WAL+一次写缓存，通常情况下写缓存延迟很低，因此提升写性能就只能从WAL入手
    - WAL机制一方面是为了确保数据即使写入缓存丢失也可以恢复，另一方面是为了集群之间异步复制。默认WAL机制开启且使用同步机制写入WAL
    - 首先考虑业务是否需要写WAL，通常情况下大多数业务都会开启WAL机制（默认），但是对于部分业务可能并不特别关心异常情况下部分数据的丢失，而更关心数据写入吞吐量，比如某些推荐业务，这类业务即使丢失一部分用户行为数据可能对推荐结果并不构成很大影响，但是对于写入吞吐量要求很高，不能造成数据队列阻塞
        - 这种场景下可以考虑关闭WAL写入，写入吞吐量可以提升2x~3x
        - 退而求其次，有些业务不能接受不写WAL，但可以接受WAL异步写入，也是可以考虑优化写入频率，通常也会带来1x~2x的性能提升

#### Put批量提交

- 优化建议
    - 尽量使用批量put进行写入请求，在业务可以接受的情况下开启异步批量提交
- 优化原理
    - HBase分别提供了单条put以及批量put的API接口，使用批量put接口可以减少客户端到RegionServer之间的RPC连接数，提高写入性能。另外需要注意的是，批量put请求要么全部成功返回，要么抛出异常
    - 业务如果可以接受异常情况下少量数据丢失的话，还可以使用异步批量提交的方式提交请求。提交分为两阶段执行：用户提交写请求之后，数据会写入客户端缓存，并返回用户写入成功；当客户端缓存达到阈值（默认2M）之后批量提交给RegionServer。需要注意的是，在某些情况下客户端异常的情况下缓存数据有可能丢失。使用方式`setAutoFlush(false)`

#### Region是否太少

- 优化建议
    - 在`Num(Region of Table) < Num(RegionServer)`的场景下切分部分请求负载高的Region并迁移到其他RegionServer
- 优化原理
    - 当前集群中表的Region个数如果小于RegionServer个数，即Num(Region of Table) < Num(RegionServer)，可以考虑切分Region并尽可能分布到不同RegionServer来提高系统请求并发度，如果Num(Region of Table) > Num(RegionServer)，再增加Region个数效果并不明显	

#### 写入请求是否不均衡

- 优化建议
    - 检查RowKey设计以及预分区策略，保证写入请求均衡
- 优化原理
    - 另一个需要考虑的问题是写入请求是否均衡，如果不均衡，一方面会导致系统并发度较低，另一方面也有可能造成部分节点负载很高，进而影响其他业务
    - 分布式系统中特别害怕一个节点负载很高的情况，一个节点负载很高可能会拖慢整个集群，这是因为很多业务会使用Mutli批量提交读写请求，一旦其中一部分请求落到该节点无法得到及时响应，就会导致整个批量请求超时。因此不怕节点宕掉，就怕节点奄奄一息！

#### 写入KeyValue数据是否太大

- KeyValue大小对写入性能的影响巨大，一旦遇到写入性能比较差的情况，需要考虑是否由于写入KeyValue数据太大导致。随着单行数据大小不断变大，写入吞吐量急剧下降，写入延迟在100K之后急剧增大

#### Utilize Flash storage for WAL(HBASE-12848)

- 这个特性意味着可以将WAL单独置于SSD上，这样即使在默认情况下（WALSync），写性能也会有很大的提升。需要注意的是，该特性建立在HDFS 2.6.0+的基础上，HDFS以前版本不支持该特性。具体可以参考官方jira：https://issues.apache.org/jira/browse/HBASE-12848

#### Multiple WALs(HBASE-14457)

- 该特性也是对WAL进行改造，当前WAL设计为一个RegionServer上所有Region共享一个WAL，可以想象在写入吞吐量较高的时候必然存在资源竞争，降低整体性能。针对这个问题，社区小伙伴（阿里巴巴大神）提出Multiple WALs机制，管理员可以为每个Namespace下的所有表设置一个共享WAL，通过这种方式，写性能大约可以提升20%～40%左右。具体可以参考官方jira：https://issues.apache.org/jira/browse/HBASE-14457


### 读优化

#### scan缓存是否设置合理

- 优化建议
    - 大scan场景下将scan缓存从100增大到500或者1000，用以减少RPC次数
- 优化原理
    - 在解释这个问题之前，首先需要解释什么是scan缓存，通常来讲一次scan会返回大量数据，因此客户端发起一次scan请求，实际并不会一次就将所有数据加载到本地，而是分成多次RPC请求进行加载，这样设计一方面是因为大量数据请求可能会导致网络带宽严重消耗进而影响其他业务，另一方面也有可能因为数据量太大导致本地客户端发生OOM。在这样的设计体系下用户会首先加载一部分数据到本地，然后遍历处理，再加载下一部分数据到本地处理，如此往复，直至所有数据都加载完成。数据加载到本地就存放在scan缓存中，默认100条数据大小
    - 通常情况下，默认的scan缓存设置就可以正常工作的。但是在一些大scan（一次scan可能需要查询几万甚至几十万行数据）来说，每次请求100条数据意味着一次scan需要几百甚至几千次RPC请求，这种交互的代价无疑是很大的。因此可以考虑将scan缓存设置增大，比如设为500或者1000就可能更加合适。笔者之前做过一次试验，在一次scan扫描10w+条数据量的条件下，将scan缓存从100增加到1000，可以有效降低scan请求的总体延迟，延迟基本降低了25%左右

#### get请求是否可以使用批量请求

- 优化建议
    - 使用批量get进行读取请求
- 优化原理
    - HBase分别提供了单条get以及批量get的API接口，使用批量get接口可以减少客户端到RegionServer之间的RPC连接数，提高读取性能。另外需要注意的是，批量get请求要么成功返回所有请求数据，要么抛出异常

#### 请求是否可以显示指定列族或者列

- 优化建议
    - 可以指定列族或者列进行精确查找的尽量指定查找
- 优化原理
    - HBase是典型的列族数据库，意味着同一列族的数据存储在一起，不同列族的数据分开存储在不同的目录下。如果一个表有多个列族，只是根据Rowkey而不指定列族进行检索的话不同列族的数据需要独立进行检索，性能必然会比指定列族的查询差很多，很多情况下甚至会有2倍~3倍的性能损失

#### 离线批量读取请求是否设置禁止缓存

- 优化建议
    - 离线批量读取请求设置禁用缓存，`scan.setBlockCache(false)`
- 优化原理
    - 通常离线批量读取数据会进行一次性全表扫描，一方面数据量很大，另一方面请求只会执行一次。这种场景下如果使用scan默认设置，就会将数据从HDFS加载出来之后放到缓存。可想而知，大量数据进入缓存必将其他实时业务热点数据挤出，其他业务不得不从HDFS加载，进而会造成明显的读延迟

#### 读请求是否均衡

- 优化建议
    - RowKey必须进行散列化处理（比如MD5散列），同时建表必须进行预分区处理
- 优化原理
    - 极端情况下假如所有的读请求都落在一台RegionServer的某几个Region上，这一方面不能发挥整个集群的并发处理能力，另一方面势必造成此台RegionServer资源严重消耗（比如IO耗尽、handler耗尽等），落在该台RegionServer上的其他业务会因此受到很大的波及。可见，读请求不均衡不仅会造成本身业务性能很差，还会严重影响其他业务。当然，写请求不均衡也会造成类似的问题，可见负载不均衡是HBase的大忌
- 观察确认
    - 观察所有RegionServer的读请求QPS曲线，确认是否存在读请求不均衡现象

#### BlockCache是否设置合理

- 优化建议
    - JVM内存配置量 < 20G，BlockCache策略选择LRUBlockCache；否则选择BucketCache策略的offheap模式
- 优化原理
    - BlockCache作为读缓存，对于读性能来说至关重要。默认情况下BlockCache和Memstore的配置相对比较均衡（各占40%），可以根据集群业务进行修正，比如读多写少业务可以将BlockCache占比调大。另一方面，BlockCache的策略选择也很重要，不同策略对读性能来说影响并不是很大，但是对GC的影响却相当显著，尤其BucketCache的offheap模式下GC表现很优越。另外，HBase 2.0对offheap的改造（HBASE-11425）将会使HBase的读性能得到2～4倍的提升，同时GC表现会更好
- 观察确认
    - 观察所有RegionServer的缓存未命中率、配置文件相关配置项一级GC日志，确认BlockCache是否可以优化

#### HFile文件是否太多

- 优化建议
    - `hbase.hstore.compaction.min` 设置不能太大，默认是3个；设置需要根据Region大小确定，通常可以简单的认为`hbase.hstore.compaction.max.size = RegionSize / hbase.hstore.compaction.min`
- 优化原理
    - HBase读取数据通常首先会到Memstore和BlockCache中检索（读取最近写入数据&热点数据），如果查找不到就会到文件中检索。HBase的类LSM结构会导致每个store包含多数HFile文件，文件越多，检索所需的IO次数必然越多，读取延迟也就越高。文件数量通常取决于Compaction的执行策略，一般和两个配置参数有关：hbase.hstore.compaction.min和hbase.hstore.compaction.max.size，前者表示一个store中的文件数超过多少就应该进行合并，后者表示参数合并的文件大小最大是多少，超过此大小的文件不能参与合并。这两个参数不能设置太松（前者不能设置太大，后者不能设置太小），导致Compaction合并文件的实际效果不明显，进而很多文件得不到合并。这样就会导致HFile文件数变多
- 观察确认
    - 观察RegionServer级别以及Region级别的storefile数，确认HFile文件是否过多

#### Compaction是否消耗系统资源过多

- 优化建议
    - Minor Compaction设置：hbase.hstore.compaction.min设置不能太小，又不能设置太大，因此建议设置为5~6；`hbase.hstore.compaction.max.size = RegionSize / hbase.hstore.compaction.min`
    - Major Compaction设置：大Region读延迟敏感业务（100G以上）通常不建议开启自动Major Compaction，手动低峰期触发。小Region或者延迟不敏感业务可以开启Major Compaction，但建议限制流量
- 优化原理
    - Compaction是将小文件合并为大文件，提高后续业务随机读性能，但是也会带来IO放大以及带宽消耗问题（数据远程读取以及三副本写入都会消耗系统带宽）。正常配置情况下Minor Compaction并不会带来很大的系统资源消耗，除非因为配置不合理导致Minor Compaction太过频繁，或者Region设置太大情况下发生Major Compaction
- 观察确认
    - 观察系统IO资源以及带宽资源使用情况，再观察Compaction队列长度，确认是否由于Compaction导致系统资源消耗过多

#### 数据本地率是否太低

- 优化建议
    - 避免Region无故迁移，比如关闭自动balance、RS宕机及时拉起并迁回飘走的Region等；在业务低峰期执行major_compact提升数据本地率
- 优化原理
    - 数据本地率：HDFS数据通常存储三份，假如当前RegionA处于Node1上，数据a写入的时候三副本为(Node1,Node2,Node3)，数据b写入三副本是(Node1,Node4,Node5)，数据c写入三副本(Node1,Node3,Node5)，可以看出来所有数据写入本地Node1肯定会写一份，数据都在本地可以读到，因此数据本地率是100%。现在假设RegionA被迁移到了Node2上，只有数据a在该节点上，其他数据（b和c）读取只能远程跨节点读，本地率就为33%（假设a，b和c的数据大小相同）
    - 数据本地率太低很显然会产生大量的跨网络IO请求，必然会导致读请求延迟较高，因此提高数据本地率可以有效优化随机读性能。数据本地率低的原因一般是因为Region迁移（自动balance开启、RegionServer宕机迁移、手动迁移等），因此一方面可以通过避免Region无故迁移来保持数据本地率，另一方面如果数据本地率很低，也可以通过执行major_compact提升数据本地率到100%

## LSM设计

- LSM树（Log-Structured Merge Tree）存储引擎，支持增、删、读、改、顺序扫描操作。而且通过批量存储技术规避磁盘随机写入问题。当然凡事有利有弊，LSM树和B+树相比，LSM树牺牲了部分读性能，用来大幅提高写性能
- LSM树的由来，在了解LSM树之前，需要对hash表和B+树有所了解
    - hash存储方式支持增、删、改以及随机读取操作，但不支持顺序扫描，对应的存储系统为key-value存储系统。对于key-value的插入以及查询，哈希表的复杂度都是O(1)，明显比树的操作O(n)快，如果不需要有序的遍历数据，哈希表就是最佳选择
    - B+树不仅支持单条记录的增、删、读、改操作，还支持顺序扫描（B+树的叶子节点之间的指针），对应的存储系统就是关系数据库（Mysql等）。但是删除和更新操作比较麻烦
- LSM的设计思想
    - 将对数据的修改增量保持在内存中，达到指定的大小限制后将这些修改操作批量写入磁盘
    - 不过读取的时候稍微麻烦，需要合并磁盘中历史数据和内存中最近修改操作，所以写入性能大大提升，读取时可能需要先看是否命中内存，否则需要访问较多的磁盘文件
    - 极端的说，基于LSM树实现的HBase的写性能比Mysql高了一个数量级，读性能低了一个数量级
- LSM树原理
    - 把一棵大树拆分成N棵小树，它首先写入内存中，随着小树越来越大，内存中的小树会flush到磁盘中，磁盘中的树定期可以做merge操作，合并成一棵大树，以优化读性能
    - 流程参考：[LSM树插入和合并操作](https://github.com/msbbigdata/hbase/blob/master/notes/LSM%E6%A0%91%E6%8F%92%E5%85%A5%E5%92%8C%E5%90%88%E5%B9%B6%E6%93%8D%E4%BD%9C.png)、[LSM树查找和删除操作](https://github.com/msbbigdata/hbase/blob/master/notes/LSM%E6%A0%91%E6%9F%A5%E6%89%BE%E5%92%8C%E5%88%A0%E9%99%A4%E6%93%8D%E4%BD%9C.png)
- HBase中LSM的应用流程如下
    - 因为小树先写到内存中，为了防止内存数据丢失，写内存的同时需要暂时持久化到磁盘，对应了HBase的MemStore和HLog
    - MemStore上的树达到一定大小之后，需要flush到HRegion磁盘中（一般是Hadoop DataNode），这样MemStore就变成了DataNode上的磁盘文件StoreFile，定期HRegionServer对DataNode的数据做merge操作，彻底删除无效空间，多棵小树在这个时机合并成大树，来增强读性能

## HBase协处理器
