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
- Hive产生的原因
    - 方便对文件及数据的元数据进行管理，提供统一的元数据管理方式
    - 提供更加简单的方式来访问大规模的数据集，使用SQL语言进行数据分析（无需写MapReduce程序，降低数据分析门槛）
- Hive经常被大数据企业用作企业级数据仓库
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
## 启动hdfs集群

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
# 启动Thrift server(阻塞式窗口，卡住是正常现象)。去mysql查看hive数据库已经自动创建了一些表
hive --service metastore

## 在node03上安装Hive(当做Driver)
scp -r /opt/bigdata/hive-2.3.8 root@node03:/opt/bigdata
# 同上文一样增加环境变量
vi /etc/profile
# 配置，然后参考下文Driver上hive-site.xml配置
vi hive-site.xml
# 进入hive命令行
hive
```
- Thrift server上hive-site.xml配置

```xml
<configuration>
  <!-- 在hdfs中的根目录 -->
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


