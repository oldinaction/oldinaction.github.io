---
layout: "post"
title: "Hive"
date: "2021-06-01 19:58"
categories: bigdata
tags: [hadoop]
---

## 简介

> The Apache Hive ™ data warehouse software facilitates reading, writing, and managing large datasets residing in distributed storage using SQL. Structure can be projected onto data already in storage. A command line tool and JDBC driver are provided to connect users to Hive.

- [Hive官网](https://hive.apache.org/)、[下载](https://mirrors.bfsu.edu.cn/apache/hive/)
- Hive是基于Hadoop的一个数据仓库工具，用来进行数据提取、转化、加载，这是一种可以存储、查询和分析存储在Hadoop中的大规模数据的机制。hive数据仓库工具能将结构化的数据文件映射为一张数据库表，并提供SQL查询功能，能将SQL语句转变成MapReduce任务来执行
- Hive产生的原因
    - 方便对文件及数据的元数据进行管理，提供统一的元数据管理方式
    - 提供更加简单的方式来访问大规模的数据集，使用SQL语言进行数据分析（无需写MapReduce程序，降低数据分析门槛）
- 架构图

    ![hive-arch.png](/data/images/bigdata/hive-arch.png)
    - 用户访问接口
        - CLI（Command Line Interface）：用户可以使用Hive自带的命令行接口执行Hive QL(有称HQL)、设置参数等功能
        - JDBC/ODBC：用户可以使用JDBC或者ODBC的方式在代码中操作Hive
        - Web GUI：浏览器接口，用户可以在浏览器中对Hive进行操作（2.2之后淘汰）
    - Thrift Server：可使用Java、C++、Ruby等多种语言运行Thrift服务，通过编程的方式远程访问Hive
    - Driver：是Hive的核心，其中包含解释器、编译器、优化器等各个组件，完成从SQL语句到MapReduce任务的解析优化执行过程
    - Metastore：Hive的元数据存储服务，一般将数据存储在关系型数据库中
        - HDFS中存有大量不同类型的数据，在做MR计算时，需要知道使用的数据集和一些数据特征(如数据分割符，分割后每个字段意思)，对应Hive中表结构，因此Hive将这些元数据(表结构)单独保存
        - Hive的数据存储在HDFS中，大部分的查询、计算由MapReduce完成（但是包含*的查询，比如select * from tbl不会生成MapRedcue任务）

## 安装

- 元数据存储分类，参考：https://cwiki.apache.org/confluence/display/Hive/AdminManual+Metastore+Administration
    - 使用Hive自带的内存数据库Derby作为元数据存储(一般不使用)
    - 使用远程数据库mysql作为元数据存储
    - 使用本地/远程元数据服务模式安装Hive，可以基于Zookeeper对Thrift server进行HA配置(一般用于生产环境)
- `v2.3.8`适用于`Hadoop 2.x`(本文使用版本)，`v3.x`适用于`Hadoop 3.x`
- 安装

```bash
## 启动hdfs和yarn集群

## 在node01上安装mysql，略
create database hive; # 提前创建好元数据存储库

## 在node02上安装Hive(当做Thrift server)
wget https://mirrors.bfsu.edu.cn/apache/hive/hive-2.3.8/apache-hive-2.3.8-bin.tar.gz
tar -zxvf apache-hive-2.3.8-bin.tar.gz
mv apache-hive-2.3.8-bin hive-2.3.8
# 增加环境变量
    # HIVE_HOME=/opt/bigdata/hive-2.3.8
    # export PATH=$PATH:$HIVE_HOME/bin
vi /etc/profile
source /etc/profile
# 配置
cd $HIVE_HOME/conf
# 先删除configuration中原默认配置，然后参考下文Thrift server上hive-site.xml配置
cp hive-default.xml.template hive-site.xml
# 拷贝mysql-connector-java-5.1.49.jar到$HIVE_HOME/lib目录
cp mysql-connector-java-5.1.49.jar $HIVE_HOME/lib
# ***启动Thrift server(阻塞式窗口，卡住是正常现象)***。去mysql查看hive数据库已经自动创建了一些表
hive --service metastore

## 在node03上安装Hive(当做Driver)
scp -r /opt/bigdata/hive-2.3.8 root@node03:/opt/bigdata
# 同上文一样增加环境变量
cd $HIVE_HOME/conf
vi /etc/profile
# 配置，然后参考下文Driver上hive-site.xml配置
vi hive-site.xml
# ***使用test用(需要对hive.metastore.warehouse.dir有写入权限)，进入hive命令行***
hive
```
- Thrift server上hive-site.xml配置

```xml
<configuration>
  <!-- 在hdfs中的根目录。无需提前创建，hive会自动创建 -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://node01:3306/hive?useSSL=false</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>root</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>Hello1234!</value>
  </property>
  <!-- 不加会报错 MetaException(message:Version information not found in metastore. ) -->
  <property>
    <name>hive.metastore.schema.verification</name>
    <value>false</value>
  </property>
  <!-- 自动创建表 -->
  <property>
    <name>datanucleus.schema.autoCreateAll</name>
    <value>true</value>
  </property>
</configuration>
```
- Driver上hive-site.xml配置

```xml
<configuration>
  <!-- 在hdfs中的根目录。无需提前创建，hive会自动创建 -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://node02:9083</value>
  </property>
  <property>
    <name>hive.metastore.local</name>
    <value>false</value>
  </property>
</configuration>
```

## SQL操作

- DDL参考：https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL
- DML参考：https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DML
- 数据库说明
    - 默认情况下，所有的表存在于default数据库，在hdfs上的展示形式是将此数据库的表保存在hive的默认路径下
    - 如果创建了数据库，那么会在hive的默认路径下生成一个database_name.db的文件夹，此数据库的所有表会保存在database_name.db的目录下
- 内部表跟外部表的区别
	- hive内部表创建的时候数据存储在hive的默认存储目录中，外部表在创建的时候需要制定额外的目录(不会在hive默认数据目录创建数据库文件夹)
	- hive内部表删除的时候，会将元数据和数据都删除，而外部表只会删除元数据，不会删除数据
	- 应用场景
		- 内部表: 需要先创建表，然后向表中添加数据，适合做中间表的存储
		- 外部表: 可以先创建表，再添加数据，也可以先有数据，再创建表，本质上是将hdfs的某一个目录的数据跟hive的表关联映射起来，因此适合原始数据的存储，不会因为误操作将数据给删除掉
- 分区表
    - hive默认将表的数据保存在某一个hdfs的存储目录下，当需要检索符合条件的某一部分数据的时候，需要全量遍历数据，io量比较大，效率比较低。因此可以采用分而治之的思想，将符合某些条件的数据放置在某一个目录，此时检索的时候只需要搜索指定目录即可，不需要全量遍历数据
    - 注意项
        - 当创建完分区表之后，在保存数据的时候，会在hdfs目录中看到分区列会成为一个目录，多个分区以多级目录的形式存在
        - 当创建多分区表之后，插入数据的时候不可以只添加一个分区列，需要将所有的分区列都添加值
        - 多分区表在添加分区列的值得时候，与顺序无关，与分区表的分区列的名称相关，按照名称就行匹配
        - 修改表时，添加分区列的值的时候，如果定义的是多分区表，那么必须给所有的分区列都赋值
		- 修改表时，删除分区列的值的时候，无论是单分区表还是多分区表，都可以将指定的分区进行删除
    - 修复分区
        - `msck repair table my_table;`
	    - 在使用hive外部表的时候，可以先将数据上传到hdfs的某一个目录中，然后再创建外部表建立映射关系，如果在上传数据的时候，参考分区表的形式也创建了多级目录，那么此时创建完表之后，是查询不到数据的，原因是分区的元数据没有保存在mysql中，因此需要修复分区，将元数据同步更新到mysql中，此时才可以查询到元数据

### 简单使用 

- 启动说明

```bash
# 启动hdfs和yarn集群，略
# 在node01上启动mysql数据库，略
# 在node02上启动Thrift server
hive --service metastore
# 使用test用(需要对hive.metastore.warehouse.dir有写入权限)，在node03上进入hive命令行. 参考：https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
hive
```
- 简单操作

```sql
-- 切换成test数据库
use test;

-- 创建hive表. 会在hdfs中创建 /user/hive/warehouse/test.db/psn 目录
create table psn
(
    id int,
    name string,
    likes array<string>,
    address map<string,string>
);

-- 查看所有表
show tables;
-- 查看某个表
desc psn;
describe formatted psn; -- 查看详细信息

-- 插入数据. 加载本地(local)数据(/home/test/data/psn_data)到hive表
-- /home/test/data/psn_data 文件内容为 `1^Asmalle^Agames^Bmusica^Addr1^Cshanghai`，其中 ^A 使用 `Control + V + A` 进行输入。且启动hive的用户需要对此文件有访问权限
load data local inpath '/home/test/data/psn_data' into table psn;

-- 查询数据. 结果为：1	smalle	["games","music"]	{"addr1":"shanghai"}
select * from psn;
```

### 数据库操作

```sql
-- 展示所有数据库，默认有一个 default 数据库
show databases;
-- 切换成test数据库
use test;
-- 创建数据库		
create database test;
-- 删除数据库
drop database test;
```

### 表操作

- 创建表. 参考：https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL#LanguageManualDDL-CreateTable

```sql
-- 外部表(需要添加external和location的关键字). 不会在hive默认数据目录创建文件夹
-- 分区表(partitioned)
-- 自定义分隔符
create external table psn_part
(
    id int,
    name string,
    likes array<string>,
    address map<string,string>
)
partitioned by(gender string, age int) -- 定义多个分区，注意分区字段和普通字段不能重复。如产生目录 /data/hive/psn_part/gender=man/age=10
row format delimited -- 自定义分隔符。默认分隔符`^A(\001)、^B(\002)、^C(\003)`，其中 ^A 等为特殊分割符(cat文件时不可见)，需使用 `Control + V + A` 进行输入
fields terminated by ',' -- 字段分割符
collection items terminated by '-' -- 集合分隔符
map keys terminated by ':' -- map的key:value分隔符
location '/data/hive/psn_part'; -- 数据保存在/data目录，表
;
```
- 修改表结构

```sql
--给分区表添加分区列的值。添加分区列的值的时候，如果定义的是多分区表，那么必须给所有的分区列都赋值
alter table table_name add partition(col_name=col_value)
--删除分区列的值。删除分区列的值的时候，无论是单分区表还是多分区表，都可以将指定的分区进行删除
alter table table_name drop partition(col_name=col_value)
```
- 修复分区

```sql
-- 在hdfs创建目录并上传文件
hdfs dfs -mkdir /data
hdfs dfs -mkdir /data/hive
hdfs dfs -mkdir /data/hive/psn_part
hdfs dfs -mkdir /data/hive/psn_part/age=10
hdfs dfs -mkdir /data/hive/psn_part/age=20
-- 数据为：1,smalle,games-music,addr1:shanghai-add2:beijing
hdfs dfs -put /home/test/data/psn_part_data_10 /data/hive/psn_part/age=10
-- 数据为
-- 2,test1,book-music1,addr1:guangzhou-add2:beijing
-- 3,test2,book-music2,addr1:guangzhou
hdfs dfs -put /home/test/data/psn_part_data_20 /data/hive/psn_part/age=20

-- 在hive中创建外部分区表
create external table psn_part
(
    id int,
    name string,
    likes array<string>,
    address map<string,string>
)
partitioned by(age int)
row format delimited
fields terminated by ','
collection items terminated by '-'
map keys terminated by ':'
location '/data/hive/psn_part';

--查询结果（没有数据）
select * from psn_part;
--修复分区
msck repair table psn_part;
--查询结果（有数据）
-- 1	smalle	["games","music"]	{"addr1":"shanghai","add2":"beijing"}	10
-- 2	test1	["book","music1"]	{"addr1":"guangzhou","add2":"beijing"}	20
-- 3	test2	["book","music2"]	{"addr1":"guangzhou"}	20
select * from psn_part;
```

