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
- Hive是基于Hadoop的一个数据仓库工具，用来进行数据提取、转化、加载，这是一种可以存储、查询和分析存储在Hadoop中的大规模数据的机制
    - hive数据仓库工具能将结构化的数据文件映射为一张数据库表，并提供SQL查询功能，能将SQL语句转变成MapReduce任务来执行
    - **hive基于hdfs做存储，基于mr进行计算(将sql语句转成mr程序)**
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
- HiveServer2模块(主要在是提供hive查询服务给远程用户)
    - HiveServer2的实现，依托于Thrift RPC，它被设计用来提供更好的支持对于open API例如JDBC和ODBC
    - HiveServer2提供了一种新的命令行接口(Beeline)，可以提交执行SQL语句

## 安装

- 元数据存储分类，参考：https://cwiki.apache.org/confluence/display/Hive/AdminManual+Metastore+Administration
    - 使用Hive自带的内存数据库Derby作为元数据存储(一般不使用)
    - 使用远程数据库mysql作为元数据存储
    - 使用本地/远程元数据服务模式安装Hive，可以基于Zookeeper对Thrift server进行HA配置(一般用于生产环境)
- `v2.3.8`适用于`Hadoop 2.x`(本文使用版本)，`v3.x`适用于`Hadoop 3.x`
- 安装

```bash
## **启动hdfs和yarn集群**，参考[hadoop.md#启动/停止/使用](/_posts/bigdata/hadoop.md#启动/停止/使用)

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
# ***启动Thrift server(使用root用户启动亦可，阻塞式窗口，卡住是正常现象)***。去mysql查看hive数据库已经自动创建了一些表
hive --service metastore

## 在node03上安装Hive(当做Driver)
scp -r /opt/bigdata/hive-2.3.8 root@node03:/opt/bigdata
# 同上文一样增加环境变量
cd $HIVE_HOME/conf
vi /etc/profile
# 配置，然后参考下文Driver上hive-site.xml配置
vi hive-site.xml
# ***使用test用户(需要对hive.metastore.warehouse.dir有写入权限)执行，进入hive命令行***
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

## 使用HiveServer2组件

- 可选。使用共享metastore server的hiveserver2模式搭建
    - 需先在修改Hadoop配置

        ```xml
        <!-- 修改hdfs的超级用户的管理权限（其中test为Hadoop启动用户），否则报错：org.apache.hadoop.security.authorize.AuthorizationException -->
        <property>
            <name>hadoop.proxyuser.test.groups</name>	
            <value>*</value>
        </property>
        <property>
            <name>hadoop.proxyuser.test.hosts</name>	
            <value>*</value>
        </property>
        ```
        - 然后在所有NameNode上执行命令`hdfs dfsadmin -fs hdfs://node01:8020 -refreshSuperUserGroupsConfiguration`刷新配置
            - node01:8020为各NN监听的rpc端口，`hdfs dfsadmin -fs hdfs://node02:8020 -refreshSuperUserGroupsConfiguration`
    - 在node02上执行`hive --service metastore`启动元数据服务
    - 在node03上执行`hive --service hiveserver2`或`hiveserver2`两个命令其中一个都可以(阻塞式命令行)
        - 会监听两个端口10000(接受HiveServer2客户端连接)、10002
    - 在任意一台包含beeline脚本(hive-2.3.8/bin/beeline)的虚拟机中执行`beeline`的命令进行连接
- `beeline`命令行
    - `!connect jdbc:hive2://node03:10000/default test 123` 连接HiveServer2服务器，test对应密码123可随便输入
        - 在beeline命令行下执行非hive sql语句需要使用`!`
        - 或者bash下直接连接 `beeline -u jdbc:hive2://192.168.6.133:10000/default -n test` -u表示url，-n表示登录用户(用处不大，只要此用户有hdfs的/tmp目录权限即可)，其中default为hive数据库
    - `!help` 查看命令帮助
    - `!quit` 退出命令行
    - `show tables;` 链接上数据库后即可和hive cli一样执行SQL语句
- jdbc的访问方式：创建普通的java项目，将hive的jar包添加到classpath中，最精简的jar包如下

```bash
commons-lang-2.6.jar
commons-logging-1.2.jar
curator-client-2.7.1.jar
curator-framework-2.7.1.jar
guava-14.0.1.jar
hive-exec-2.3.4.jar
hive-jdbc-2.3.4.jar
hive-jdbc-handler-2.3.4.jar
hive-metastore-2.3.4.jar
hive-service-2.3.4.jar
hive-service-rpc-2.3.4.jar
httpclient-4.4.jar
httpcore-4.4.jar
libfb303-0.9.3.jar
libthrift-0.9.3.jar
log4j-1.2-api-2.6.2.jar
log4j-api-2.6.2.jar
log4j-core-2.6.2.jar
log4j-jul-2.5.jar
log4j-slf4j-impl-2.6.2.jar
log4j-web-2.6.2.jar
zookeeper-3.4.6.jar
```

## 启停

- 启动hdfs和yarn集群，参考[hadoop.md#启动/停止/使用](/_posts/bigdata/hadoop.md#启动/停止/使用)
- 启动mysql (在node01上启动, 存放hive元数据)
- `hive --service metastore` 在node02上root即可启动Thrift server，阻塞式窗口，卡住是正常现象
- `hive` 在node03上使用test用户执行，进入hive命令行即可执行增删改SQL
    - `quit;` 退出命令行
- `hive --service hiveserver2` 在node03上执行，启动Hiveserver2，参考[使用HiveServer2组件](#使用HiveServer2组件)
- `beeline` 连接到Hiveserver2，从而执行(查询)SQL

## Hive命令使用

- hive运行方式分类
    - 命令行方式或者控制台模式
    - 脚本运行方式（实际生产环境中用最多）
    - JDBC方式：hiveserver2
    - web GUI接口：hwi(hive v2.2以后已抛弃)、[hue](https://gethue.com/)等

### Hive Cli

```bash
hive --service cli # 可简写为 `hive` 命令
hive --service cli -h # 查看 hive cli 命令帮助
# 帮助信息如下
usage: hive
 -d,--define <key=value>          Variable substitution to apply to Hive
                                  commands. e.g. -d A=B or --define A=B
    # hive -d myid=1
    # select * from psn where id = ${myid}; # 使用上述定义的变量
    --database <databasename>     Specify the database to use
 -e <quoted-query-string>         SQL from command line
    # hive -e "select * from psn; show tables;" > result.log # 可执行多个SQL，打印结果到文件(不会包含hive启动日志)，执行完后退出命令行
 -f <filename>                    SQL from files
    # hive -f ~/test.sql # 执行sql文件，完后会退出命令行
    # hive> source test.sql; # 在hive命令行也可以执行本地sql文件，当前目录不能加~
 -H,--help                        Print help information
    --hiveconf <property=value>   Use value for given property
    --hivevar <key=value>         Variable substitution to apply to Hive
                                  commands. e.g. --hivevar A=B
 -i <filename>                    Initialization SQL file
    # hive -i ~/test.sql # 执行初始化sql文件，完后会停留在命令行
 -S,--silent                      Silent mode in interactive shell
    # hive -S # 静默模式，不会打印OK、Time taken等日志
 -v,--verbose                     Verbose mode (echo executed SQL to the console)
```
- 执行命令

```bash
select * from psn; # 执行Hive SQL
dfs ls / # 可以与HDFS交互
! ls / # 可以和linux交互
quit; # 退出hive命令行
```

### 参数操作

- hive当中的参数、变量都是以命名空间开头的，详情如下表所示：

| 命名空间      | 读写权限      | 含义                                                     |
| ------------ | ------------ | ------------------------------------------------------------ |
| hiveconf     | 可读写       | hive-site.xml当中的各配置变量例：hive --hiveconf hive.cli.print.header=true |
| system       | 可读写       | 系统变量，包含JVM运行参数等例：system:user.name=root         |
| env          | 只读         | 环境变量例：env：JAVA_HOME                                   |
| hivevar      | 可读写       | 例：hive -d val=key。hive的变量可以通过`${}`方式进行引用，其中system、env下的变量必须以前缀开头 |

- 设置参数

```bash
# 在启动hive cli时设置，此次会话生效。修改${HIVE_HOME}/conf/hive-site.xml则永久生效
hive --hiveconf hive.cli.print.header=true # 打印表头

# 在进入到cli之后，通过set命令设置
set; # 查看所有参数, xxx=yyy、env:xxx=yyy、system:xxx=yyy
set hive.cli.print.header; # 查看hive.cli.print.header的值
set hive.cli.print.header=true; # 设值

# hive参数初始化设置。当前用户每次进入hive cli的时候，都会加载.hiverc的文件，执行文件中的命令
vi ~/.hiverc # 在其中加入如`set hive.cli.print.header=true;`的参数配置
# cat ~/.hivehistory # 此文件中保存了hive cli中执行的所有命令
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
# 在node02上启动Thrift server，启动后jps查看有一个RunJar的进程（如果是cli连接hive则可不用启动）
hive --service metastore
# 进入hive命令行(类似mysql命令行)，在node03上使用test用户执行(需要对hive.metastore.warehouse.dir有写入权限). 参考：https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
hive
```
- 简单操作

```sql
-- 查看数据库
show databases;

-- 切换成test数据库
use test;

-- 创建hive表. 会在hdfs中创建 /user/hive/warehouse/test.db/psn 目录(/user/hive/warehouse为hive默认数据根目录)
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

### DDL(表操作)

#### 创建表语法

- 参考：https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL#LanguageManualDDL-CreateTable

```sql
CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name   -- (Note: TEMPORARY available in Hive 0.14.0 and later)
[(col_name data_type [COMMENT col_comment], ... [constraint_specification])]
[COMMENT table_comment]
-- 分区
[PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)]
-- 分桶
[CLUSTERED BY (col_name, col_name, ...) [SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]
[SKEWED BY (col_name, col_name, ...)  -- (Note: Available in Hive 0.10.0 and later)]
ON ((col_value, col_value, ...), (col_value, col_value, ...), ...)
[STORED AS DIRECTORIES]
[
    [ROW FORMAT row_format] 
    [STORED AS file_format]
    | STORED BY 'storage.handler.class.name' [WITH SERDEPROPERTIES (...)]  -- (Note: Available in Hive 0.6.0 and later)
]
[LOCATION hdfs_path]
[TBLPROPERTIES (property_name=property_value, ...)]   -- (Note: Available in Hive 0.6.0 and later)
[AS select_statement];   -- (Note: Available in Hive 0.5.0 and later; not supported for external tables)

CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
    LIKE existing_table_or_view_name
[LOCATION hdfs_path];
-- 复杂数据类型
data_type
    : primitive_type
    | array_type
    | map_type
    | struct_type
    | union_type  -- (Note: Available in Hive 0.7.0 and later)
-- 基本数据类型
primitive_type
    : TINYINT
    | SMALLINT
    | INT
    | BIGINT
    | BOOLEAN
    | FLOAT
    | DOUBLE
    | DOUBLE PRECISION -- (Note: Available in Hive 2.2.0 and later)
    | STRING
    | BINARY      -- (Note: Available in Hive 0.8.0 and later)
    | TIMESTAMP   -- (Note: Available in Hive 0.8.0 and later)
    | DECIMAL     -- (Note: Available in Hive 0.11.0 and later)
    | DECIMAL(precision, scale)  -- (Note: Available in Hive 0.13.0 and later)
    | DATE        -- (Note: Available in Hive 0.12.0 and later)
    | VARCHAR     -- (Note: Available in Hive 0.12.0 and later)
    | CHAR        -- (Note: Available in Hive 0.13.0 and later)

array_type
    : ARRAY < data_type >

map_type
    : MAP < primitive_type, data_type >

struct_type
    : STRUCT < col_name : data_type [COMMENT col_comment], ...>

union_type
    : UNIONTYPE < data_type, data_type, ... >  -- (Note: Available in Hive 0.7.0 and later)
-- 行格式规范
row_format
    : DELIMITED [FIELDS TERMINATED BY char [ESCAPED BY char]] [COLLECTION ITEMS 				TERMINATED BY char]
    [MAP KEYS TERMINATED BY char] [LINES TERMINATED BY char]
    [NULL DEFINED AS char]   -- (Note: Available in Hive 0.13 and later)
    | SERDE serde_name [WITH SERDEPROPERTIES (property_name=property_value, 				property_name=property_value, ...)]
-- 文件基本类型
file_format:
    : SEQUENCEFILE
    | TEXTFILE    -- (Default, depending on hive.default.fileformat configuration)
    | RCFILE      -- (Note: Available in Hive 0.6.0 and later)
    | ORC         -- (Note: Available in Hive 0.11.0 and later)
    | PARQUET     -- (Note: Available in Hive 0.13.0 and later)
    | AVRO        -- (Note: Available in Hive 0.14.0 and later)
    | JSONFILE    -- (Note: Available in Hive 4.0.0 and later)
    | INPUTFORMAT input_format_classname OUTPUTFORMAT output_format_classname
-- 表约束
constraint_specification:
    : [, PRIMARY KEY (col_name, ...) DISABLE NOVALIDATE ]
    [, CONSTRAINT constraint_name FOREIGN KEY (col_name, ...) REFERENCES 					table_name(col_name, ...) DISABLE NOVALIDATE 
```

#### 创建表案例

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
location '/data/hive/psn_part'; -- 数据保存的目录
;

-- 删除表(如果为外部表则不会删除dfs数据)
drop table psn_part;
```

#### 修改表结构案例

```sql
--给分区表添加分区列的值。添加分区列的值的时候，如果定义的是多分区表，那么必须给所有的分区列都赋值
alter table table_name add partition(col_name=col_value)
--删除分区列的值。删除分区列的值的时候，无论是单分区表还是多分区表，都可以将指定的分区进行删除
alter table table_name drop partition(col_name=col_value)
```

#### 修复分区使用

- 一般是先有数据文件，后创建的hive表，需要用到修复分区

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
--**修复分区**
msck repair table psn_part;
--查询结果（有数据）
-- 1	smalle	["games","music"]	{"addr1":"shanghai","add2":"beijing"}	10
-- 2	test1	["book","music1"]	{"addr1":"guangzhou","add2":"beijing"}	20
-- 3	test2	["book","music2"]	{"addr1":"guangzhou"}	20
select * from psn_part;
```

### DML(数据操作)

- 数据更新和删除：在使用hive的过程中，我们一般不会产生删除和更新的操作

#### 插入数据语法

```sql
-- 1.Loading files into tables(导入数据)
LOAD DATA [LOCAL] INPATH 'filepath' [OVERWRITE] INTO TABLE tablename [PARTITION(partcol1=val1, partcol2=val2 ...)]
LOAD DATA [LOCAL] INPATH 'filepath' [OVERWRITE] INTO TABLE tablename [PARTITION(partcol1=val1, partcol2=val2 ...)] [INPUTFORMAT 'inputformat' SERDE 'serde']

-- 2.Inserting data into Hive Tables from queries
-- 2.1 Standard syntax:
INSERT OVERWRITE TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...) [IF NOT EXISTS]] select_statement1 FROM from_statement;
INSERT INTO TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...)] select_statement1 FROM from_statement;
-- 2.2 Hive extension (multiple inserts):
FROM from_statement
    INSERT OVERWRITE TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...) [IF NOT EXISTS]] select_statement1
    [INSERT OVERWRITE TABLE tablename2 [PARTITION ... [IF NOT EXISTS]] select_statement2]
    [INSERT INTO TABLE tablename2 [PARTITION ...] select_statement2] ...;
FROM from_statement
    INSERT INTO TABLE tablename1 [PARTITION (partcol1=val1, partcol2=val2 ...)] select_statement1
    [INSERT INTO TABLE tablename2 [PARTITION ...] select_statement2]
    [INSERT OVERWRITE TABLE tablename2 [PARTITION ... [IF NOT EXISTS]] select_statement2] ...;
-- 2.3 Hive extension (dynamic partition inserts):
INSERT OVERWRITE TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;
INSERT INTO TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;

-- 3.Writing data into the filesystem from queries
-- 3.1 Standard syntax:
INSERT OVERWRITE [LOCAL] DIRECTORY directory1
[ROW FORMAT row_format] [STORED AS file_format] -- (Note: Only available starting with Hive 0.11.0)
SELECT ... FROM ...
-- 3.2 Hive extension (multiple inserts):
FROM from_statement
    INSERT OVERWRITE [LOCAL] DIRECTORY directory1 select_statement1
    [INSERT OVERWRITE [LOCAL] DIRECTORY directory2 select_statement2] ... 
    row_format
    : DELIMITED [FIELDS TERMINATED BY char [ESCAPED BY char]] [COLLECTION ITEMS TERMINATED BY char]
    [MAP KEYS TERMINATED BY char] [LINES TERMINATED BY char]
    [NULL DEFINED AS char] -- (Note: Only available starting with Hive 0.13)

-- 4.Inserting values into tables from SQL(使用传统关系型数据库的方式插入数据，效率较低)
INSERT INTO TABLE tablename [PARTITION (partcol1[=val1], partcol2[=val2] ...)] VALUES values_row [, values_row ...]
Where values_row is:
( value [, value ...] )
where a value is either null or any valid SQL literal
```

#### 插入数据案例

```sql
--**导入数据(使用较多)**
--加载本地数据到hive表（复制文件）
load data local inpath '/home/test/data/psn_data' into table psn;--(/home/test/data/psn_data指的是本地linux目录)
--加载hdfs数据文件到hive表（移动文件）
load data inpath '/data/psn_data' into table psn;--(/data/psn_data指的是hdfs的目录)

--下面两种方式插入数据的时候需要预先创建好结果表
--**从表中查询数据插入结果表(使用较多)**
insert overwrite table psn1
    select id,name from psn;
--从表中获取部分列插入到新表中
from psn
    insert overwrite table psn1 -- 将psn中的id,name字段覆盖psn1
    select id,name
    insert into table psn2 -- 将psn中的id字段追加到psn2                         
    select id;

--注意：overwrite为覆盖，路径千万不要填写根目录，会把所有的数据文件都覆盖
--将查询到的结果导入到hdfs文件系统中
insert overwrite directory '/result' select * from psn;
--将查询的结果导入到本地文件系统中
insert overwrite local directory '/result' select * from psn;

--类似传统SQL语句一样插入数据(效率较低)
insert into psn values(1,'zhangsan')
```

### Serde进行数据处理

- Hive Serde用来做序列化和反序列化，构建在数据存储和执行引擎之间，对两者实现解耦
    - hive主要用来存储结构化数据，如果结构化数据存储的格式嵌套比较复杂的时候，可以使用serde的方式，如利用正则表达式匹配的方法来读取数据
- 语法

```bash
row_format
: DELIMITED 
    [FIELDS TERMINATED BY char [ESCAPED BY char]] 
    [COLLECTION ITEMS TERMINATED BY char] 
    [MAP KEYS TERMINATED BY char] 
    [LINES TERMINATED BY char] 
# 如 serde_name=org.apache.hadoop.hive.serde2.RegexSerDe 表示使用正则进行数据处理
: SERDE serde_name [WITH SERDEPROPERTIES (property_name=property_value, property_name=property_value, ...)]
```
- 案例

```bash
# 对于下列数据，希望数据显示的时候包含[]或者""
# /root/data/log文件如下
192.168.57.4 - - [29/Feb/2019:18:14:35 +0800] "GET /bg-upper.png HTTP/1.1" 304 -
192.168.57.4 - - [29/Feb/2019:18:14:35 +0800] "GET /bg-nav.png HTTP/1.1" 304 -

# 创建表
# org.apache.hadoop.hive.serde2.RegexSerDe：表示使用正则进行数据处理(类名，注意大小写)
# 正则表达式：([^ ]*) ([^ ]*) ([^ ]*) \\[(.*)\\] \"(.*)\" (-|[0-9]*) (-|[0-9]*)，前3个括号君表示匹配非空
create table logtbl (
    host string,
    identity string,
    t_user string,
    time string,
    request string,
    referer string,
    agent string
)
row format serde 'org.apache.hadoop.hive.serde2.RegexSerDe'
with serdeproperties ("input.regex" = "([^ ]*) ([^ ]*) ([^ ]*) \\[(.*)\\] \"(.*)\" (-|[0-9]*) (-|[0-9]*)")
stored as textfile;

# 加载数据
load data local inpath '/home/test/data/logtbl' into table logtbl;

# 查询
select * from logtbl;
```

### Hive函数

- 和关系型数据库差不多，hive内置了很多函数，如substr、count、explore等

#### 自定义函数

- 分类
    - `UDF`(User-Defined-Function): 一进一出
    - `UDAF`(Aggregation): 聚合函数，多进一出，类似count/max/min
    - `UDTF`(Table-Generating): 一进多出，如explore
- 引用依赖

```xml
<!--
    无法下载pentaho-aggdesigner-algorithm-5.1.5-jhyde.jar，可手动下载后放到.m2相应目录
    下载地址：https://public.nexus.pentaho.org/repository/proxy-public-3rd-party-release/org/pentaho/pentaho-aggdesigner-algorithm/5.1.5-jhyde/pentaho-aggdesigner-algorithm-5.1.5-jhyde.jar
-->
<dependency>
    <groupId>org.apache.hive</groupId>
    <artifactId>hive-exec</artifactId>
    <version>${hive.version}</version>
</dependency>
```
- 案例

```java
// org.apache.hadoop.hive.ql.exec.UDF
// org.apache.hadoop.io.Text
public class TuoMin extends UDF {
    // 需要实现evaluate函数，evaluate函数支持重载
    public Text evaluate(final Text s) {
        if (s == null) {
            return null;
        }
        String str = s.toString().substring(0, 1) + "***";
        return new Text(str);
    }
}
```
- 使用
    - 把程序打包成jar上传到hdfs集群的/jar目录下：`hdfs dfs -D dfs.blocksize=1048576 -put bigdata-hive-0.0.1-SNAPSHOT.jar /jar`
    - 创建函数：hive> `create function sq_tuomin as 'cn.aezo.bigdata.hive.func.TuoMin' using jar "hdfs://aezocn/jar/bigdata-hive-0.0.1-SNAPSHOT.jar";`
    - 查询HQL语句：`select sq_tuomin(name) from psn;` 返回`s***`
    - 销毁临时函数：hive> `drop function sq_tuomin;`
- 临时使用：此种方式创建的函数属于临时函数，当关闭了当前会话之后，函数会无法使用，因为jar的引用没有了
    - hive> `add jar /home/test/bigdata-hive-0.0.1-SNAPSHOT.jar;` 在客户端执行，使用服务器本地目录(/home/test)
    - 创建临时函数：hive> `create temporary function sq_tuomin AS 'cn.aezo.bigdata.hive.func.TuoMin';`

#### 1.内置运算符

##### 1.1关系运算符

| 运算符        | 类型         | 说明                                                         |
| ------------- | ------------ | ------------------------------------------------------------ |
| A = B         | 所有原始类型 | 如果A与B相等,返回TRUE,否则返回FALSE                          |
| A == B        | 无           | 失败，因为无效的语法。 SQL使用”=”，不使用”==”。              |
| A <> B        | 所有原始类型 | 如果A不等于B返回TRUE,否则返回FALSE。如果A或B值为”NULL”，结果返回”NULL”。 |
| A < B         | 所有原始类型 | 如果A小于B返回TRUE,否则返回FALSE。如果A或B值为”NULL”，结果返回”NULL”。 |
| A <= B        | 所有原始类型 | 如果A小于等于B返回TRUE,否则返回FALSE。如果A或B值为”NULL”，结果返回”NULL”。 |
| A > B         | 所有原始类型 | 如果A大于B返回TRUE,否则返回FALSE。如果A或B值为”NULL”，结果返回”NULL”。 |
| A >= B        | 所有原始类型 | 如果A大于等于B返回TRUE,否则返回FALSE。如果A或B值为”NULL”，结果返回”NULL”。 |
| A IS NULL     | 所有类型     | 如果A值为”NULL”，返回TRUE,否则返回FALSE                      |
| A IS NOT NULL | 所有类型     | 如果A值不为”NULL”，返回TRUE,否则返回FALSE                    |
| A LIKE B      | 字符串       | 如 果A或B值为”NULL”，结果返回”NULL”。字符串A与B通过sql进行匹配，如果相符返回TRUE，不符返回FALSE。B字符串中 的”_”代表任一字符，”%”则代表多个任意字符。例如： (‘foobar’ like ‘foo’)返回FALSE，（ ‘foobar’ like ‘foo_ _ _’或者 ‘foobar’ like ‘foo%’)则返回TURE |
| A RLIKE B     | 字符串       | 如 果A或B值为”NULL”，结果返回”NULL”。字符串A与B通过java进行匹配，如果相符返回TRUE，不符返回FALSE。例如：（ ‘foobar’ rlike ‘foo’）返回FALSE，（’foobar’ rlike ‘^f.*r$’ ）返回TRUE。 |
| A REGEXP B    | 字符串       | 与RLIKE相同。                                                |

##### 1.2算术运算符

| 运算符 | 类型         | 说明                                                         |
| ------ | ------------ | ------------------------------------------------------------ |
| A + B  | 所有数字类型 | A和B相加。结果的与操作数值有共同类型。例如每一个整数是一个浮点数，浮点数包含整数。所以，一个浮点数和一个整数相加结果也是一个浮点数。 |
| A – B  | 所有数字类型 | A和B相减。结果的与操作数值有共同类型。                       |
| A * B  | 所有数字类型 | A和B相乘，结果的与操作数值有共同类型。需要说明的是，如果乘法造成溢出，将选择更高的类型。 |
| A / B  | 所有数字类型 | A和B相除，结果是一个double（双精度）类型的结果。             |
| A % B  | 所有数字类型 | A除以B余数与操作数值有共同类型。                             |
| A & B  | 所有数字类型 | 运算符查看两个参数的二进制表示法的值，并执行按位”与”操作。两个表达式的一位均为1时，则结果的该位为 1。否则，结果的该位为 0。 |
| A\|B   | 所有数字类型 | 运算符查看两个参数的二进制表示法的值，并执行按位”或”操作。只要任一表达式的一位为 1，则结果的该位为 1。否则，结果的该位为 0。 |
| A ^ B  | 所有数字类型 | 运算符查看两个参数的二进制表示法的值，并执行按位”异或”操作。当且仅当只有一个表达式的某位上为 1 时，结果的该位才为 1。否则结果的该位为 0。 |
| ~A     | 所有数字类型 | 对一个表达式执行按位”非”（取反）。                           |

##### 1.3逻辑运算符

| 运算符  | 类型   | 说明                                                         |
| ------- | ------ | ------------------------------------------------------------ |
| A AND B | 布尔值 | A和B同时正确时,返回TRUE,否则FALSE。如果A或B值为NULL，返回NULL。 |
| A && B  | 布尔值 | 与”A AND B”相同                                              |
| A OR B  | 布尔值 | A或B正确,或两者同时正确返返回TRUE,否则FALSE。如果A和B值同时为NULL，返回NULL。 |
| A \| B  | 布尔值 | 与”A OR B”相同                                               |
| NOT A   | 布尔值 | 如果A为NULL或错误的时候返回TURE，否则返回FALSE。             |
| ! A     | 布尔值 | 与”NOT A”相同                                                |

##### 1.4复杂类型函数

| 函数   | 类型                            | 说明                                                        |
| ------ | ------------------------------- | ----------------------------------------------------------- |
| map    | (key1, value1, key2, value2, …) | 通过指定的键/值对，创建一个map。                            |
| struct | (val1, val2, val3, …)           | 通过指定的字段值，创建一个结构。结构字段名称将COL1，COL2，… |
| array  | (val1, val2, …)                 | 通过指定的元素，创建一个数组。                              |

1.5对复杂类型函数操作

| 函数   | 类型                  | 说明                                                         |
| ------ | --------------------- | ------------------------------------------------------------ |
| A[n]   | A是一个数组，n为int型 | 返回数组A的第n个元素，第一个元素的索引为0。如果A数组为['foo','bar']，则A[0]返回’foo’和A[1]返回”bar”。 |
| M[key] | M是Map<K, V>，关键K型 | 返回关键值对应的值，例如mapM为 \{‘f’ -> ‘foo’, ‘b’ -> ‘bar’, ‘all’ -> ‘foobar’\}，则M['all'] 返回’foobar’。 |
| S.x    | S为struct             | 返回结构x字符串在结构S中的存储位置。如 foobar \{int foo, int bar\} foobar.foo的领域中存储的整数。 |

#### 2.内置函数

##### 2.1数学函数

| 返回类型   | 函数                                              | 说明                                                         |
| ---------- | ------------------------------------------------- | ------------------------------------------------------------ |
| BIGINT     | round(double a)                                   | 四舍五入                                                     |
| DOUBLE     | round(double a, int d)                            | 小数部分d位之后数字四舍五入，例如round(21.263,2),返回21.26   |
| BIGINT     | floor(double a)                                   | 对给定数据进行向下舍入最接近的整数。例如floor(21.2),返回21。 |
| BIGINT     | ceil(double a), ceiling(double a)                 | 将参数向上舍入为最接近的整数。例如ceil(21.2),返回23.         |
| double     | rand(), rand(int seed)                            | 返回大于或等于0且小于1的平均分布随机数（依重新计算而变）     |
| double     | exp(double a)                                     | 返回e的n次方                                                 |
| double     | ln(double a)                                      | 返回给定数值的自然对数                                       |
| double     | log10(double a)                                   | 返回给定数值的以10为底自然对数                               |
| double     | log2(double a)                                    | 返回给定数值的以2为底自然对数                                |
| double     | log(double base, double a)                        | 返回给定底数及指数返回自然对数                               |
| double     | pow(double a, double p) power(double a, double p) | 返回某数的乘幂                                               |
| double     | sqrt(double a)                                    | 返回数值的平方根                                             |
| string     | bin(BIGINT a)                                     | 返回二进制格式                                               |
| string     | hex(BIGINT a) hex(string a)                       | 将整数或字符转换为十六进制格式                               |
| string     | unhex(string a)                                   | 十六进制字符转换由数字表示的字符。                           |
| string     | conv(BIGINT num, int from_base, int to_base)      | 将 指定数值，由原来的度量体系转换为指定的试题体系。例如CONV(‘a’,16,2),返回。参考：’1010′ http://dev.mysql.com/doc/refman/5.0/en/mathematical-functions.html#function_conv |
| double     | abs(double a)                                     | 取绝对值                                                     |
| int double | pmod(int a, int b) pmod(double a, double b)       | 返回a除b的余数的绝对值                                       |
| double     | sin(double a)                                     | 返回给定角度的正弦值                                         |
| double     | asin(double a)                                    | 返回x的反正弦，即是X。如果X是在-1到1的正弦值，返回NULL。     |
| double     | cos(double a)                                     | 返回余弦                                                     |
| double     | acos(double a)                                    | 返回X的反余弦，即余弦是X，，如果-1<= A <= 1，否则返回null.   |
| int double | positive(int a) positive(double a)                | 返回A的值，例如positive(2)，返回2。                          |
| int double | negative(int a) negative(double a)                | 返回A的相反数，例如negative(2),返回-2。                      |

##### 2.2收集函数

| 返回类型 | 函数           | 说明                      |
| -------- | -------------- | ------------------------- |
| int      | size(Map<K.V>) | 返回的map类型的元素的数量 |
| int      | size(Array<T>) | 返回数组类型的元素数量    |

##### 2.3类型转换函数

| 返回类型    | 函数                 | 说明                                                         |
| ----------- | -------------------- | ------------------------------------------------------------ |
| 指定 “type” | cast(expr as <type>) | 类型转换。例如将字符”1″转换为整数:cast(’1′ as bigint)，如果转换失败返回NULL。 |

##### 2.4日期函数

| 返回类型 | 函数                                            | 说明                                                         |
| -------- | ----------------------------------------------- | ------------------------------------------------------------ |
| string   | from_unixtime(bigint unixtime[, string format]) | UNIX_TIMESTAMP参数表示返回一个值’YYYY- MM – DD HH：MM：SS’或YYYYMMDDHHMMSS.uuuuuu格式，这取决于是否是在一个字符串或数字语境中使用的功能。该值表示在当前的时区。 |
| bigint   | unix_timestamp()                                | 如果不带参数的调用，返回一个Unix时间戳（从’1970- 01 – 0100:00:00′到现在的UTC秒数）为无符号整数。 |
| bigint   | unix_timestamp(string date)                     | 指定日期参数调用UNIX_TIMESTAMP（），它返回参数值’1970- 01 – 0100:00:00′到指定日期的秒数。 |
| bigint   | unix_timestamp(string date, string pattern)     | 指定时间输入格式，返回到1970年秒数：unix_timestamp(’2009-03-20′, ‘yyyy-MM-dd’) = 1237532400 |
| string   | to_date(string timestamp)                       | 返回时间中的年月日： to_date(“1970-01-01 00:00:00″) = “1970-01-01″ |
| string   | to_dates(string date)                           | 给定一个日期date，返回一个天数（0年以来的天数）              |
| int      | year(string date)                               | 返回指定时间的年份，范围在1000到9999，或为”零”日期的0。      |
| int      | month(string date)                              | 返回指定时间的月份，范围为1至12月，或0一个月的一部分，如’0000-00-00′或’2008-00-00′的日期。 |
| int      | day(string date) dayofmonth(date)               | 返回指定时间的日期                                           |
| int      | hour(string date)                               | 返回指定时间的小时，范围为0到23。                            |
| int      | minute(string date)                             | 返回指定时间的分钟，范围为0到59。                            |
| int      | second(string date)                             | 返回指定时间的秒，范围为0到59。                              |
| int      | weekofyear(string date)                         | 返回指定日期所在一年中的星期号，范围为0到53。                |
| int      | datediff(string enddate, string startdate)      | 两个时间参数的日期之差。                                     |
| int      | date_add(string startdate, int days)            | 给定时间，在此基础上加上指定的时间段。                       |
| int      | date_sub(string startdate, int days)            | 给定时间，在此基础上减去指定的时间段。                       |

##### 2.5条件函数

| 返回类型 | 函数                                                       | 说明                                                         |
| -------- | ---------------------------------------------------------- | ------------------------------------------------------------ |
| T        | if(boolean testCondition, T valueTrue, T valueFalseOrNull) | 判断是否满足条件，如果满足返回一个值，如果不满足则返回另一个值。 |
| T        | COALESCE(T v1, T v2, …)                                    | 返回一组数据中，第一个不为NULL的值，如果均为NULL,返回NULL。  |
| T        | CASE a WHEN b THEN c [WHEN d THEN e]* [ELSE f] END         | 当a=b时,返回c；当a=d时，返回e，否则返回f。                   |
| T        | CASE WHEN a THEN b [WHEN c THEN d]* [ELSE e] END           | 当值为a时返回b,当值为c时返回d。否则返回e。                   |

##### 2.6字符函数

| 返回类型                     | 函数                                                         | 说明                                                         |
| ---------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| int                          | length(string A)                                             | 返回字符串的长度                                             |
| string                       | reverse(string A)                                            | 返回倒序字符串                                               |
| string                       | concat(string A, string B…)                                  | 连接多个字符串，合并为一个字符串，可以接受任意数量的输入字符串 |
| string                       | concat_ws(string SEP, string A, string B…)                   | 链接多个字符串，字符串之间以指定的分隔符分开。               |
| string                       | substr(string A, int start) substring(string A, int start)   | 从文本字符串中指定的起始位置后的字符。                       |
| string                       | substr(string A, int start, int len) substring(string A, int start, int len) | 从文本字符串中指定的位置指定长度的字符。                     |
| string                       | upper(string A) ucase(string A)                              | 将文本字符串转换成字母全部大写形式                           |
| string                       | lower(string A) lcase(string A)                              | 将文本字符串转换成字母全部小写形式                           |
| string                       | trim(string A)                                               | 删除字符串两端的空格，字符之间的空格保留                     |
| string                       | ltrim(string A)                                              | 删除字符串左边的空格，其他的空格保留                         |
| string                       | rtrim(string A)                                              | 删除字符串右边的空格，其他的空格保留                         |
| string                       | regexp_replace(string A, string B, string C)                 | 字符串A中的B字符被C字符替代                                  |
| string                       | regexp_extract(string subject, string pattern, int index)    | 通过下标返回正则表达式指定的部分。regexp_extract(‘foothebar’, ‘foo(.*?)(bar)’, 2) returns ‘bar.’ |
| string                       | parse_url(string urlString, string partToExtract [, string keyToExtract]) | 返回URL指定的部分。parse_url(‘http://facebook.com/path1/p.php?k1=v1&k2=v2#Ref1′, ‘HOST’) 返回：’facebook.com’ |
| string                       | get_json_object(string json_string, string path)             | select a.timestamp, get_json_object(a.appevents, ‘$.eventid’), get_json_object(a.appenvets, ‘$.eventname’) from log a; |
| string                       | space(int n)                                                 | 返回指定数量的空格                                           |
| string                       | repeat(string str, int n)                                    | 重复N次字符串                                                |
| int                          | ascii(string str)                                            | 返回字符串中首字符的数字值                                   |
| string                       | lpad(string str, int len, string pad)                        | 返回指定长度的字符串，给定字符串长度小于指定长度时，由指定字符从左侧填补。 |
| string                       | rpad(string str, int len, string pad)                        | 返回指定长度的字符串，给定字符串长度小于指定长度时，由指定字符从右侧填补。 |
| array                        | **split(string str, string pat)**                                | 将字符串转换为数组 `select split(name, '-') from psn`                                         |
| int                          | find_in_set(string str, string strList)                      | 返回字符串str第一次在strlist出现的位置。如果任一参数为NULL,返回NULL；如果第一个参数包含逗号，返回0。 |
| array<array<string>>         | sentences(string str, string lang, string locale)            | 将字符串中内容按语句分组，每个单词间以逗号分隔，最后返回数组。 例如sentences(‘Hello there! How are you?’) 返回：( (“Hello”, “there”), (“How”, “are”, “you”) ) |
| array<struct<string,double>> | ngrams(array<array<string>>, int N, int K, int pf)           | SELECT ngrams(sentences(lower(tweet)), 2, 100 [, 1000]) FROM twitter; |
| array<struct<string,double>> | context_ngrams(array<array<string>>, array<string>, int K, int pf) | SELECT context_ngrams(sentences(lower(tweet)), array(null,null), 100, [, 1000]) FROM twitter; |

#### 3.内置的聚合函数（UDAF）

| 返回类型                 | 函数                                                         | 说明                                                         |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| bigint                   | count(*) , count(expr), count(DISTINCT expr[, expr_., expr_.]) | 返回记录条数。                                               |
| double                   | sum(col), sum(DISTINCT col)                                  | 求和                                                         |
| double                   | avg(col), avg(DISTINCT col)                                  | 求平均值                                                     |
| double                   | min(col)                                                     | 返回指定列中最小值                                           |
| double                   | max(col)                                                     | 返回指定列中最大值                                           |
| double                   | var_pop(col)                                                 | 返回指定列的方差                                             |
| double                   | var_samp(col)                                                | 返回指定列的样本方差                                         |
| double                   | stddev_pop(col)                                              | 返回指定列的偏差                                             |
| double                   | stddev_samp(col)                                             | 返回指定列的样本偏差                                         |
| double                   | covar_pop(col1, col2)                                        | 两列数值协方差                                               |
| double                   | covar_samp(col1, col2)                                       | 两列数值样本协方差                                           |
| double                   | corr(col1, col2)                                             | 返回两列数值的相关系数                                       |
| double                   | percentile(col, p)                                           | 返回数值区域的百分比数值点。0<=P<=1,否则返回NULL,不支持浮点型数值。 |
| array<double>            | percentile(col, array(p~1,,\ [, p,,2,,]…))                   | 返回数值区域的一组百分比值分别对应的数值点。0<=P<=1,否则返回NULL,不支持浮点型数值。 |
| double                   | percentile_approx(col, p[, B])                               | Returns an approximate p^th^ percentile of a numeric column (including floating point types) in the group. The B parameter controls approximation accuracy at the cost of memory. Higher values yield better approximations, and the default is 10,000. When the number of distinct values in col is smaller than B, this gives an exact percentile value. |
| array<double>            | percentile_approx(col, array(p~1,, [, p,,2_]…) [, B])        | Same as above, but accepts and returns an array of percentile values instead of a single one. |
| array<struct\{‘x’,'y’\}> | histogram_numeric(col, b)                                    | Computes a histogram of a numeric column in the group using b non-uniformly spaced bins. The output is an array of size b of double-valued (x,y) coordinates that represent the bin centers and heights |
| array                    | collect_set(col)                                             | 返回无重复记录                                               |

#### 4.内置表生成函数（UDTF）

| 返回类型 | 函数                   | 说明                                                         |
| -------- | ---------------------- | ------------------------------------------------------------ |
| 数组     | explode(array<TYPE> a) | 数组一条记录中有多个参数，将参数拆分，每个参数生成一列。     |
|          | json_tuple             | get_json_object 语句：select a.timestamp, get_json_object(a.appevents, ‘$.eventid’), get_json_object(a.appenvets, ‘$.eventname’) from log a; json_tuple语句: select a.timestamp, b.* from log a lateral view json_tuple(a.appevent, ‘eventid’, ‘eventname’) b as f1, f2 |

### Hive动态分区

- hive的静态分区需要用户在插入数据的时候必须手动指定hive的分区字段值，但是这样的话会导致用户的操作复杂度提高，而且在使用的时候会导致数据只能插入到某一个指定分区，无法让数据散列分布，因此更好的方式是当数据在进行插入的时候，根据数据的某一个字段或某几个字段**值**(静态分区必须要知道所有值，而动态分区无需提前知道)动态的将数据插入到不同的目录中，此时引入动态分区
- hive的动态分区配置

```sql
--hive设置hive动态分区开启。默认：true
set hive.exec.dynamic.partition=true;
--hive的动态分区模式。默认：strict（至少有一个分区列是静态分区，为了防止动态产生的分区过多）
set hive.exec.dynamic.partition.mode=nostrict;

-- 每一个执行mr节点上，允许创建的动态分区的最大数量(100)
-- set hive.exec.max.dynamic.partitions.pernode;
-- 所有执行mr节点上，允许创建的所有动态分区的最大数量(1000)	
-- set hive.exec.max.dynamic.partitions;
-- 所有的mr job允许创建的文件的最大数量(100000)	
-- set hive.exec.max.created.files;
```
- 语法

```sql
--Hive extension (dynamic partition inserts):
INSERT OVERWRITE TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;
INSERT INTO TABLE tablename PARTITION (partcol1[=val1], partcol2[=val2] ...) select_statement FROM from_statement;
```
- 案例

```sql
-- 创建临时数据库
create table psn_dynamic_part_tmp(
    id int,
    name string,
    age int,
    sex int,
    likes array<string>,
    address map<string, string>
)
row format delimited
fields terminated by ','
collection items terminated by '-'
map keys terminated by ':'
;
-- 往临时表加载数据
load data local inpath '/home/test/data/psn_dynamic_part' into table psn_dynamic_part_tmp;
select * from psn_dynamic_part_tmp;

-- 创建分区表
create table psn_dynamic_part(
    id int,
    name string,
    likes array<string>,
    address map<string, string>
)
partitioned by(age int, sex int)
row format delimited
fields terminated by ','
collection items terminated by '-'
map keys terminated by ':'
;

-- **插入数据时，此时会产生一个MR任务**
-- 注意select字段的顺序，需要和目标表字段对应，不能select *
insert into table psn_dynamic_part
partition (age,sex)
select id,name,likes,address,age,sex from psn_dynamic_part_tmp
;
-- 最终会动态根据值创建dfs分区目录，如：/user/hive/warehouse/psn_dynamic_part/age=18|age=.../sex=1|sex=0
select * from psn_dynamic_part;
```
- 案例数据(/home/test/data/psn_dynamic_part)

```bash
1,smalle,18,1,games-music,addr1:shanghai-add2:beijing
2,test1,20,1,book-music1,addr1:guangzhou-add2:beijing
3,test2,18,0,book-music2,addr1:guangzhou
4,test3,18,0,music3,addr1:guangzhou
5,test4,54,0,music2,addr1:shanghai
6,test5,37,1,book-music2,addr1:shanghai-add2:beijing
7,test6,18,0,book,addr1:shanghai-add2:beijing
8,test7,28,1,book,add1:beijing
```

### 分桶

- 分桶说明
    - Hive分桶表是对列值取hash值得方式，将不同数据放到不同文件中存储
    - 对于hive中每一个表、分区都可以进一步进行分桶，从而降低每个文件的大小
    - 由列的hash值除以桶的个数来决定每条数据划分在哪个桶中
    - 一次作业产生的桶（文件数量）和reduce task个数一致
        - mr运行时会根据bucket的个数自动分配reduce task个数（用户也可以通过mapred.reduce.tasks自己设置reduce任务个数，但分桶时不推荐使用）
- `set hive.enforce.bucketing=true;` 开启hive分桶支持(v2.3.8可不用设置)
- Hive分桶的抽样查询

```sql
--案例
select * from xxx_bucket_table tablesample(bucket 1 out of 4 on xxx_columns)
--TABLESAMPLE语法：
tablesample(bucket x out of y on cols)
-- x：表示从哪个bucket开始抽取数据，x=1表示从第一个开始提取，当超过bucket文件个数时会报错
-- y：必须为该表总bucket数的倍数或因子。假设bucket文件数为4
    -- 当y=4, 表示从第x个bucket中取4/4=1份数据(即整个x文件的数据)
    -- 当y=8, 表示从第x个bucket中取4/8=0.5份数据(即整个文件的上半部分行数据)
    -- 尽量不要让其除不尽，因此取其倍数或因子
```
- 案例

```sql
-- 创建临时数据
create table psn_bucket_tmp(id int, name string, age int) 
row format delimited fields terminated by ','
;
load data local inpath '/home/test/data/psn_bucket' into table psn_bucket_tmp;

-- **创建分桶表**(可和分区表结合使用，也可单独使用)
create table psn_bucket(id int, name string, age int)
clustered by (age) into 4 buckets
row format delimited fields terminated by ','
;
-- 插入数据，会启动一个MR任务(Hadoop job information for Stage-1: number of mappers: 1; number of reducers: 4)
insert into table psn_bucket select id, name, age from psn_bucket_tmp;
-- 会产生4个文件：/user/hive/warehouse/psn_bucket/
-- 抽样
select id, name, age from psn_bucket tablesample(bucket 2 out of 4 on age);
```
- 案例测试数据(/home/test/data/psn_bucket)

```bash
1,tom,11
2,cat,22
3,dog,33
4,hive,44
5,hbase,55
6,mr,66
7,alice,77
8,scala,88
```

### lateral view


