---
layout: "post"
title: "Solr"
date: "2018-03-13 20:31"
categories: bigdata
tags: [lucene, solr]
---

## 简介

- `Solr`它是一种开放源码的、基于 Lucene Java 的搜索服务器，易于加入到 Web 应用程序中。
    - 基于开放接口（XML和HTTP）的标准进行索引创建和查询**(基于Lucene通过HTTP请求进行数据索引管理)**
    - 可伸缩性－能够有效地复制到另外一个Solr搜索服务器
    - 附带了一个基于HTTP管理界面
- Solr与Lucene 并不是竞争对立关系，恰恰相反Solr 依存于Lucene，因为Solr底层的核心技术是使用Lucene 来实现的。Lucene专注于搜索底层的建设，而Solr专注于企业应用
- Solr内嵌Jetty和ZooKeeper。`SolrCloud` 模式是基于ZooKeeper的，会自动启动ZooKeeper服务。
- [官网：https://lucene.apache.org/solr/](https://lucene.apache.org/solr/)
- [官方教程](https://lucene.apache.org/solr/guide/7_2/solr-tutorial.html)、[solr-7.2-pdf](http://mirror.bit.edu.cn/apache/lucene/solr/ref-guide/apache-solr-ref-guide-7.2.pdf)
- [各版本下载地址](http://archive.apache.org/dist/lucene/solr/)**(本文基于`solr-7.2.0`进行说明，需要jdk1.8及以上)**

### 相关概念

- `collection`/`core` 均指以不同的数据结构来对数据进行索引(索引库、集合)
- `schema`为一个xml配置文件，主要用于配置字段和字段类型，动态字段等。（如某个字段可忽略大小写也可在其中配置）

## 安装及使用 [^1]

### 下载解压说明

- 下载tar包解压 `tar -zxvf solr-7.2.1.tgz -C /opt/soft`，目录说明
- `example` 几个solr的实例
- `server` solr的核心应用程序
    - `solr-webapp`为solr提供的控制面板
    - `resources` 日志配置
    - `solr/configsets` 全局配置文件(有`_default`和`sample_techproducts_configs`两种)。`SolrCloud`模式启动后选择此其中一种模式（应该在启动前对此目录下文件进行配置），普通模式启动需要复制其中的配置文件到相应实例目录
        - `sample_techproducts_configs/conf/managed-schema` 配置(添加)字段、字段类型、动态字段等信息
        - `sample_techproducts_configs/conf/solrconfig.xml` 配置sorl相关服务，如classpath配置、增加导入db数据访问端点等

### 启动停止服务

- 配置IK中文分析器/DB数据导入需要在启动前配置好
- 初始化solr集合
    - 以`SolrCloud`模式启动**`./bin/solr start -e cloud`**(因权限可强制启动**`./bin/solr start -e cloud -force`**)
        - 启动时会询问相关配置，`[]`中即为默认配置(默认启动2个solr节点，分别为8983、7574)。其他使用默认；**solr配置项使用`sample_techproducts_configs`**，集合名称也可再此时配置
        - SolrCloud模式创建的集合instanceDir在`/example/cloud/node1/solr/aezocn_shard1_replica_n1`等目录下创建
    - 普通默认启动 `./bin/solr start`
        - 此时需要添加Core。需要先在`/server/solr`创建对应的instanDir，并将`/server/solr/configsets/_default/conf`目录下所有文件拷贝到instanDir目录下
- 访问`http://localhost:8983/solr`即可看到solr的管理面板
- 停止服务
    - **`./bin/solr stop -all`** 停止全部solr
    - `./bin/solr stop -p 8983` 停止8983端口的solr
- **重启服务**
    `./bin/solr start -c -p 8983 -s example/cloud/node1/solr -force` 启动node1，其中`-s`后面接`solr.home`(此时会启动一个内嵌的ZooKeeper服务)
    `./bin/solr start -c -p 7574 -s example/cloud/node2/solr -z localhost:9983 -force` 启动node2，其中`-z localhost:9983`为连接ZooKeeper的配置

### 配置IK中文分析器

- **需要在启动前配置好，`SolrCloud`模式启动为例**
- [资源下载](https://download.csdn.net/download/oldinaction/10306498)
- `ik-analyzer-solr5-5.x.jar`和`solr-analyzer-ik-5.1.0.jar`复制到`/server/solr-webapp/webapp/WEB-INF/lib`目录下
- 在`/server/solr-webapp/webapp/WEB-INF`下创建`classes`目录
- 将`IKAnalyzer.cfg.xml`(如下)、`stopword.dic`(分割词，如"的"等。每行一个)、`ext.dic`(每行一个，可为空文件)复制到`classes`目录下

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">  
    <properties>  
        <comment>IK Analyzer 扩展配置</comment>
        <!--用户可以在这里配置自己的扩展字典 -->
        <entry key="ext_dict">ext.dic;</entry> 
        
        <!--用户可以在这里配置自己的扩展停止词字典-->
        <entry key="ext_stopwords">stopword.dic;</entry> 
        
    </properties>
    ```
- 编辑`server/solr/configsets/sample_techproducts_configs/conf/managed-schema`在`</schema>`前加如下代码

    ```xml
    <fieldType name="text_ik" class="solr.TextField">
        <analyzer class="org.wltea.analyzer.lucene.IKAnalyzer"/>
    </fieldType>

    <!-- 示例（此时非必须）。添加一个字段desc，类型为text_ik。只有创建类似这种字段才能进行中文分词 -->
    <field name="desc" type="text_ik" indexed="true" stored="true" multiValued="false" />
    ```

### 同步db数据 [^3]

- 将以下jar包复制到`/server/solr-webapp/webapp/WEB-INF/lib`目录下
    - solr-dataimporthandler-7.2.1.jar(在dist目录中)
    - solr-dataimporthandler-extras-7.2.1.jar
    - mysql-connector-java-5.1.43.jar
- 在配置文件`server/solr/configsets/sample_techproducts_configs/conf/solrconfig.xml`末尾加入如下代码(基于`SolrCloud`模式的`sample_techproducts_configs`配置)

    ```xml
    <requestHandler name="/dataimport" class="org.apache.solr.handler.dataimport.DataImportHandler">
        <lst name="defaults">
            <str name="config">data-config.xml</str>
        </lst>
    </requestHandler>
    ```
- 新增配置文件`server/solr/configsets/sample_techproducts_configs/conf/data-config.xml`

    ```xml
    <dataConfig>
        <dataSource type="JdbcDataSource"
                driver="com.mysql.jdbc.Driver"
                url="jdbc:mysql://192.168.6.1:3306/test"
                user="root"
                password="root" />
        <document>
            <!-- 此处可以有多个entity，entity也可以嵌套。dataimporter.request.id为控制面板中Dataimport-Custom Parameters的传入参数 -->
            <!-- deltaQuery/deltaImportQuery为增量更新的sql -->
            <entity name="test_solr" 
                pk="id"
                transformer="DateFormatTransformer"
                query="SELECT id, `name`, `desc`, update_time FROM test_solr WHERE id >= ${dataimporter.request.id}"
                deltaQuery="select id from test_solr where update_time > '${dih.last_index_time}'"
                deltaImportQuery="SELECT id, `name`, `desc`, update_time FROM test_solr where id='${dih.delta.id}'">
                <!-- column为数据库字段，name为managed_schema里配置的字段 -->
                <field column='update_time' name="last_modified" dateTimeFormat='yyyy-MM-dd HH:mm:ss' />
            </entity>
        </document>
    </dataConfig>
    ```
    - 可能会连接数据库失败，可在控制面板的`Logging`中查看日志。常见如：`"Host '192.168.6.131' is not allowed to connect to this MySQL server"`
- 编辑`server/solr/configsets/sample_techproducts_configs/conf/managed-schema`在`</schema>`中加入`<field name="desc" type="text_ik" indexed="true" stored="true" multiValued="false" />`来进行中文存储（在可在控制面板中进行添加）
- 加载配置文件，参考下文【solr相关命令】
- 控制面板中进行数据导入，参考下文【控制面板-collection】
    - `Command=full-import`；`Entity=test_solr`；`Dataimport-Custom Parameters`传入`id=1`表示导入所有id>1的数据
    - 增量更新主要看`update_time`字段值是否比`dataimport.properties`中`last_index_time`的值大。此时最好去掉`clean`的勾选，否则全导入后`update_time`未变更的记录将被删除
    - 或者访问`http://192.168.6.131:8983/solr/aezocn/dataimport?command=delta-import`进行数据导入
- 查询数据 `http://192.168.6.131:8983/solr/aezocn/select?q={!term f=desc}中国人`

## 控制面板

- 访问`http://localhost:8983/solr/aezocn/browse`为查询前端界面(类似百度搜索)
- 点击cloud查看集合分片节点信息：collection(aezocn)分成两片(shard1、shard2)，且每片都对应两个节点(192.168.6.131:8983、192.168.6.131:7574)
- `Logging` 日志。如数据导入出错会在此处打印日志

### collection(aezocn)

- `Dataimport` db数据同步
    - `Command`分为`full-import`(全导入)和`delta-import`(增量导入)
- `Documents` post文档数据
- `Query` 检索
    - `common`-`q`输入检索词汇，支持`""`、`+`、`-`等符号
- `Schema` 字段配置，添加字段等

## solr相关命令

```bash
## **`SolrCloud`配置文件加载**
# `SolrCloud`模式下配置文件是基于`server/solr/configsets`中配置文件加载的。可以在`configsets`新建配置文件模版文件夹
# 如果在控制面板`Cloud`-`Tree`-`configs`中无名为aezocn的Configset则会自动新建一个。如果存在则会进行更新
bin/solr zk upconfig -z localhost:9983 -n aezocn -d /opt/soft/solr-7.2.1/server/solr/configsets/sample_techproducts_configs
# 配置文件加载后需要刷新集合aezocn
http://192.168.6.131:8983/solr/admin/collections?action=RELOAD&name=aezocn

## 创建新集合
# 创建新集合名为movie，2个shades(`-s`)和2个replicas(`-rf`), 默认使用`_default`作为配置模板
./bin/solr create -c movie -s 2 -rf 2

## 删除集合
./bin/solr delete -c aezocn

## **清空数据**
# 删除`example/cloud`文件夹即可删除`SolrCloud`模式启动的集合
rm -Rf example/cloud/

## 给集合添加字段
# 往movie集合中添加一个字段名为username、文本型、不可存放多个值、可检索查询 
curl -X POST -H 'Content-type:application/json' --data-binary '{"add-field": {"name":"username", "type":"text_general", "multiValued":false, "stored":true}}' http://localhost:8983/solr/movie/schema

## 添加文档数据，以自带exampledocs为例导入测试数据。往集合aezocn中post数据(也可在控制面板中post文档数据)
./bin/post -c aezocn example/exampledocs/*
```

## Client APIs

- 基于`solrj`进行数据提交和查询 [^2]
- [Solrj API](https://lucene.apache.org/solr/7_2_0//solr-solrj/)

```xml
<dependency>
  <groupId>org.apache.solr</groupId>
  <artifactId>solr-solrj</artifactId>
  <version>7.2.0</version>
</dependency>
```







---

参考文章

[^1]: [solr-tutorial](https://lucene.apache.org/solr/guide/7_2/solr-tutorial.html)
[^2]: [Using-SolrJ](https://lucene.apache.org/solr/guide/7_2/using-solrj.html#using-solrj)
[^3]: [Data-Import-Handler](https://lucene.apache.org/solr/guide/7_2/uploading-structured-data-store-data-with-the-data-import-handler.html)
[^4]: [CentOs7.3搭建SolrCloud集群服务](https://segmentfault.com/a/1190000010836061)
[^5]: [solr安全控制](https://blog.csdn.net/sqh201030412/article/details/51253819)

