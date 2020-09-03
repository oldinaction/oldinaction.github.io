---
layout: "post"
title: "ELK"
date: "2019-05-26 15:05"
categories: bigdata
tags: [Elasticsearch, db, kafka]
---

## ELK简介

- [官网](https://www.elastic.co)、[官方中文文档](https://www.elastic.co/guide/cn/index.html)、[docs](https://www.elastic.co/guide/index.html)
- `ELK`平台主要有由ElasticSearch、Logstash和Kiabana三个开源免费工具组成
    - `Elasticsearch` 是个开源分布式搜索引擎，它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等
    - `Logstash` 可以对日志进行收集、过滤，并将其存储供以后使用
    - `Kibana` Kibana可以为 Logstash 和 ElasticSearch 提供的日志分析友好的 Web 界面，可以帮助汇总、分析和搜索重要数据日志
- [elasticsearch-curator](https://github.com/elastic/curator)，主要用于管理elasticsearch索引和快照
  - Curator是有python开发的，之后被elasticsearch合并

## Elasticsearch

- [Elasticsearch文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

### 基础概念

- `Lucence`：一个Jar包，主要用做分词。其集群实现较难维护
- ES`倒排索引`
  - 正排索引是从文档到关键字的映射（已知文档求关键字），`倒排索引`是从关键字到文档的映射（已知关键字求文档）
  - 倒排表以字词为关键字进行索引，可查询到这个字词的所有文档，它记录该文档的ID和字符在该文档中出现的位置情况
  - 存储的数据结构
    - 包含关键词的doc list
    - 关键词在每个doc中出现的次数（TF：item frequency）
    - 关键词在整个索引中出现的次数（IDF：inverse doc frequency）
    - 关键词在当前doc中出现的次数
    - 每个doc的长度，越长相关度越低
    - 包含每个关键词的所有doc的平均长度
- 应用领域
  - 百度（全文检索、高亮、搜索推荐）
  - 用户行为日志（用户点击、浏览、收藏、评论）
  - BI（Business Intelligence商业智能），数据分析，数据挖掘统计
  - Github：代码托管平台，几千亿行代码
  - ELK：Elasticsearch（数据存储）、Logstash（日志采集）、Kibana（可视化）
- 核心概念
  - Field：一个数据字段，与index和type一起，可以定位一个doc
  - Document：ES最小的数据单元，JSON格式
  - Type：逻辑上的数据分类，es 7.x中删除了type的概念
  - Index：一类相同或者类似的doc，不能包含大写字母
  - 和传统数据库对比：Document->row，Type->table，Index-db

#### 读写过程及原理

- ES 写数据过程 [^2]
  - 客户端选择一个 node 发送请求过去，这个 node 就是 coordinating node （协调节点）
  - coordinating node 对 document 进行路由，将请求转发给对应的 node（有 primary shard）
  - 实际的 node 上的 primary shard 处理请求，然后将数据同步到 replica node
  - primary node 和所有 replica node 都写完之后，协调节点就返回响应结果给客户端
- ES 搜索数据过程
  - 客户端发送请求到一个 coordinate node
  - 协调节点将搜索请求转发到所有对应的 primary shard 或 replica shard
  - query phase：每个 shard 将自己的搜索结果（其实就是一些 doc id ）返回给协调节点，由协调节点进行数据的合并、排序、分页等操作，产出最终结果
  - fetch phase：接着由协调节点根据 doc id 去各个节点上拉取实际的 document 数据，最终返回给客户端
- ES 读数据过程（基于doc id）
  - 客户端发送请求到任意一个 node，这个 node 就是 coordinate node 
  - coordinate node 对 doc id 进行哈希路由，将请求转发到对应的 node，此时会使用 round-robin 随机轮询算法，在 primary shard 以及其所有 replica 中随机选择一个，让读请求负载均衡
  - 接收请求的 node 返回 document 给 coordinate node
  - coordinate node 返回 document 给客户端
- 写入数据底层原理
  - 数据先写入内存 buffer（ES进程），并同时写入translog
  - 然后每隔 1s或内存 buffer快满了，将数据 **`refresh`** 到一个新的segment file（中间还是会先写到os cache），到了 os cache 数据就能被搜索到（所以ES为NRT近实时，near real-time，因为中间有 1s 的延迟）
  - **`translog`** 大到一定程度，或者默认每隔 30min，会触发 commit 操作，将缓冲区的数据都 **`flush`** 到 segment file 磁盘文件中
    - commit/flush操作
      - 将buffer中现有数据refresh到os cache中去，清空buffer
      - 将一个commit point写入磁盘文件，里面标识着这个commit point对应的所有segment file
      - 将os cache数据fsync强刷到磁盘上去
      - 清空translog日志文件
    - translog其实也是先写入os cache的，默认每隔5秒刷一次到磁盘中去，所以可能会丢失5秒钟的数据
    - translog日志作用：在你执行commit操作之前，数据要么是停留在buffer中，要么是停留在os cache中，二者都是内存，一旦这台机器死了，内存中的数据就全丢；而此时重启后可通过translog日志进行恢复
  - 如果是删除操作，commit的时候会生成一个.del文件，里面将某个doc标识为deleted状态
  - 如果是更新操作，就是将原来的doc标识为deleted状态，然后新写入一条数据
  - buffer每1秒refresh一次，就会产生一个新的segment file，因此会定期执行 **`merge`**，即将多个segment file合并成一个，同时这里会将标识为deleted的doc给物理删除掉，然后将新的segment file写入磁盘

### 语法

#### REST API

```bash
## 索引操作
PUT /my_index # 创建索引。返回结果`"acknowledged" : true`表示创建成功
DELETE /my_index # 删除索引
GET _cat/indices?v # 查询索引列表
## 插入数据（_id=1）
PUT /my_index/_doc/1
{
  "name": "smalle",
  "age": 18 
}
## 更新数据
# 更新字段
POST /my_index/_doc/1/_update
{
  "doc": {
    "name": "aezo"
  }
}
# 全量更新：会完整替换原始数据（_source），因此会丢失age参数
PUT /my_index/_doc/1
{
  "name": "hello"
}
## 查询
GET /my_index/_search # 查询所有。也可使用：GET /my_index/_doc/_search，但是v7.x已经不推荐使用type
GET /my_index/_search?q=name:smalle # 查询name字段包含smalle的
GET /my_index/_search?from=0&size=2&sort=age:asc # 分页和排序
GET /_search?timeout=1s # 超时机制（单位:s/ms/m）。默认没有timeout，如果设置了timeout，那么会执行timeout机制
```

#### Query DSL

```bash
## https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
## 伪代码
GET /product/_search
{
  "query": {
    ## 全文检索
    # 1.match_all 匹配所有
    "match_all": {},
    # 2.match：匹配name中包含nfc的
    "match": {
      "name": "nfc"
    },
    # 3.multi_match：匹配多个字段，即匹配name、desc字段中包含nfc的doc
    "multi_match": {
      "query": "nfc",
      "fields": ["name","desc"]
    },
    ## Term-level queries
    # match和term区别：term不会被分词，而match会被分词。即此时term会查包含"nfc phone"，而match会查包含"nfc"和"phone"
    "term": {
      "name": "nfc phone"
    },
    # name必须包含nfc和phone
    "terms": {
      "name":["nfc","phone"]
    },
    ## 短语搜索：和全文检索相反。"nfc phone"会作为一个短语去检索(可以理解为也不分词)
    "match_phrase": {
      "name": "nfc phone"
    }
  },
  # constant_score：类似query，区别在于constant_score不计算分数，查询更快，但是不会排序(query默认基于分数排序)
  "constant_score": {
      "match_all": {},
  },

  # 排序
  "sort": [
    {
      "price": "desc"
    }
  ],
  # _source 元数据：默认包含所有，此时只会返回结果下面定义的字段
  "_source": ["name","desc","price"],
  # 分页：查询第一页（每页两条数据）
  "from": 0,
  "size": 2
}

## 组合查询(Compound queries)、过滤
GET /product/_search
{
  "query": {
    # bool：可以组合多个查询条件，采用more_matches_is_better的机制，因此满足must和should子句的文档将会合并起来计算分值
    "bool": {
      # must：必须都包含。子句（查询）必须出现在匹配的文档中，并将有助于得分
      "must": [
        {"match": {"name": "xiaomi"}},
        {"match": {"desc": "shouji"}}
      ],
      # must_not：必须都不包含。子句在过滤器上下文中执行，这意味着计分被忽略，并且子句被视为用于缓存
      "must_not": [
        {"match": {"name": "erji"}}
      ],
      # should：至少满足几个条件（由于下文"minimum_should_match": 1，所以至少满足一个条件）。参见下面的minimum_should_match的解释
      "should": [
        {"match": {
          "desc": "nfc"
        }}
      ],
      # minimum_should_match：参数指定should返回的文档必须匹配的子句的数量或百分比。如果bool查询包含至少一个should子句，而没有must或filter子句，则默认值为1。否则，默认值为0
      "minimum_should_match": 1,
      # filter：过滤器，不计算相关度分数，且有缓存机制，filter一般会先与query之前执行。子句（查询）必须出现在匹配的文档中，但是分数将被忽略。filter子句在filter上下文中执行，这意味着计分被忽略，并且子句被考虑用于缓存
      "filter": [
        {"match_phrase": {"name": "xiaomi phone"}},
        # range：区间匹配。查询 price > 1999 的
        {"range": {
          "price": {
            "gt": 1999
          }
        }},
        # 嵌套查询
        "bool": {
          "must": [
            {"match": {"name": "nfc"}}
          ]
        }
      ]
    }
  }
}

## Deep paging和Scroll search
# Deep paging分页：如果要取前100条数据，假设该索引有3个分片，则会在3个分片中取出前100条数据，之后合并后再次排序进行返回。比较耗性能，因此当数据超过1W或需要的结果超过1000个(500个以下为宜)尽量不要使用
# Scroll search查询：解决Deep paging问题；Scroll search只能下一页，没办法上一页或跳页
GET /product/_search?scroll=1m # 第一次查询设置scroll的时间窗口期为1分钟，进行查询，会返回scroll_id(第二次查询会用到)
{
  "query": {
    "match_all": {}
  },
  "sort": [
    {
      "price": "desc"
    }
  ],
  "size": 2
}
GET /_search?scroll # 第二次查询的时间间隔如果再1分钟内则可通过上一次返回的scroll_id进行继续查询，并更新时间窗口
{
  "scroll": "1m",
  "scroll_id": "FGluY2x1ZGVfY29udGV4dF91dWlkDXF1ZXJ5QW5kRmV0Y2gBFGlzOFZUblFCb3JVcHBIUVpZS21QAAAAAAAAAY4WcWxraDZOSGxTMmVEczhyUXJkYTJiUQ=="
}

## mapping
GET /product/_mapping

## 测试分词。使用standard分词器对text文本分词，会返回分词的结果，此时为4个次
GET /_analyze
{
  "analyzer": "standard",
  "text":"xiaomi nfc zhineng phone"
}
```
- filter缓存原理

    ![es-filter-cache.png](/data/images/bigdata/es-filter-cache.png)
    - filter cache保存的是匹配结果，下次查询不需要再从倒排索引中去查找比对，提供了查询速度
    - 当filter执行某个查询一定次数（动态变化）时才会进行cache
    - filter会优先从稀疏的数据中进行过滤来保存cache数据
    - filter一般会在query之前执行，过滤掉一部分数据，从而提供query速度
    - filter不计算相关度分数，执行效率较query高
    - 当元数据发生变化时，cache也会更新

#### mapping

### 集群

- ES集群优点
  - 面向开发者友好，屏蔽了Lucene的复杂特性，集群自动发现（cluster discovery）
  - 自动维护数据在多个节点上的建立
  - 包含搜索请求的负载均衡
  - 自动维护冗余副本，保证了部分节点宕机的情况下仍然不会有任何数据丢失
  - ES基于Lucene提供了很多高级功能：复合查询、聚合分析、基于地理位置等
  - 可以构建几百台服务器的大型分布式集群，处理PB级别数据
  - 相比统数据库的有点：提供了全文检索，同义词处理，相关度排名，聚合分析以及海量数据的近实时（`NTR`）处理
- Shard分片
  - 一个index包含多个Shard，默认5P，默认每个P(primary shrad分片)分配一个R(replica shard副本)。P的数量在创建索引的时候设置，如果想修改，需要重建索引
  - 每个Shard都是一个Lucene实例，有完整的创建索引的处理请求能力
  - ES会自动在nodes上为做shard均衡
  - 一个doc是不可能同时存在于多个PShard中的，但是可以存在于多个RShard中
  - P和对应的R不能同时存在于同一个节点，所以最低的可用配置是两个节点，互为主备

#### ES生
- es 生产集群我们部署了 5 台机器，每台机器是 6 核 64G 的，集群总内存是 320G
- 我们 es 集群的日增量数据大概是 2000 万条，每天日增量数据大概是 500MB，每月增量数据大概是 6 亿，15G。目前系统已经运行了几个月（6个月），现在 es 集群里数据总量大概是 100G 左右
- 目前线上有 5 个索引（这个结合你们自己业务来，看看自己有哪些数据可以放 es 的），每个索引的数据量大概是 20G，所以这个数据量之内，我们每个索引分配的是 8 个 shard（比默认的 5 个 shard 多了 3 个 shard）

### 性能优化

- 增加系统内存
- 无用的字段（不用来做检索的字段）不要保存到es中。可将全量数据保存在mysql/hbase中，通过关键字在es中查询到id，然后去获取相应数据
- 数据预热：就是对热数据（如热销商品、微博大V）每隔一段时间，就提前访问一下，让数据进入内存里面去
- 冷热分离：es 可以做类似于 mysql 的水平拆分，冷数据写入一个索引中，然后热数据写入另外一个索引中
- document 模型设计：先在 Java 系统里就完成关联（复杂的SQL查询），将关联好的数据直接写入 es 中（document 模型存储复杂SQL的结果），尽量避免在es中进行 join/nested/parent-child 等查询
- 分页性能优化：使用scroll search或search_after来防止深度分页

## Logstash

```bash
# 测试向Logstash发送数据
curl -X POST 'http://192.168.99.100:5000' -H 'Content-Type: application/json' -d '{"Say" : "Hello world!"}'
```

## Kibana

- 面板介绍
    - Discover：日志管理视图(主要进行搜索和查询)
    - Visualize：统计视图(构建可视化的图表)
    - Dashboard：仪表视图(将构建的图表组合形成图表盘)
    - Timelion：时间轴视图(随着时间流逝的数据)
    - APM：性能管理视图(应用程序的性能管理系统)
    - Canvas：大屏展示图
    - Dev Tools： 开发者命令视图
    - Monitoring：健康视图(请求访问性能预警)
    - Management：管理视图
- 左上角`CHANGE CURRENT SPACE`可切换或管理SPACE(可以理解为一个组)，每一SPACE需要自行管理Kibana的`Index Patterns`和`Advanced Settings`等

### Discover显示

- 需要先创建索引表达式，参考 Management - Kibana设置 - Index Patterns
- New新增查询、Save保存当前查询、Open打开查询、Share分享查询、Inspect


### Management

- Elasticsearch设置
- Kibana设置
  - Index Patterns 显示的是创建好的索引表达式
    - Create index pattern创建索引表达式 - 输入正则匹配现有的索引(如：sq-demo-*) - 可在Discover中查看
  - Saved Objects 为保存的Objects，如：配置信息（Advanced Settings）、索引表达式（index pattern）、查询面板（search）、分享短连接
  - Advanced Settings
    - General
      - `Date format` 日志时间显示，如：`YYYY/MM/DD HH:mm:ss.SSS`
      - `Day of week` 没周的第一天，如`Monday`
      - `Admin email` 接收异常邮件
    - Discover
      - `Default columns` 定义"发现"标签页上默认显示的列(默认为显示列为_source，即以key:value的格式显示在一起)。此处修改如：`spring_application_name,level,thread_name,logger_name,message` (基于springboot项目定制，这样会影响全局，不建议修改)

### 其他

- Stack Monitoring
  - 首次进入 Turn on monitoring 开启ELK服务器磁盘，内存等监控

## SpringCloud整合ELK

- Spring Cloud与ELK平台整合使用时，只需要实现与负责日志收集的Logstash完成数据对接即可，且Logstash自身也支持收集logback日志，所有通过在logback配置中增加对logstash的appender，就能非常方便的将日志转换成以json的格式存储和输出了 [^1]

### 基于容器安装

```bash
## 安装 **Elasticsearch** (下载会较慢，可尝试下载几次)
docker run -d -it --name es -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.mirrors.ustc.edu.cn/elastic/elasticsearch:7.1.0
# docker start es # 重新启动
# 查看Elasticsearch信息。(其中`192.168.99.100`为docker所在宿主机IP，此处为docker运行在windows虚拟机上的IP)。其他的地址如：http://192.168.99.100:9200/_cat/ 和 http://192.168.99.100:9200/_cat/nodes 信息。访问`http://192.168.99.100:9200/micro-sq-auth/_search` 查看micro-sq-auth这个index下的日志信息
http://192.168.99.100:9200/

## 安装 **Logstash**，并指定输入输出。将输入声明为TCP(兼容LogstashTcpSocketAppender的日志记录器)，声明Elasticsearch为输出
# 此处的 -e 为logstash的参数而不是docker命令的参数(192.168.99.100:9200为elasticsearch服务端口)
    # input表示Logstash开放5000的TCP端口供外部调用
    # 可以在output中同时加入控制台输出调试观察日志是否传入Logstash，如`output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "micro-%{serviceName}" } stdout { codec => rubydebug } }`
docker run -d -it --name logstash -p 5000:5000 docker.mirrors.ustc.edu.cn/elastic/logstash:7.1.0 -e 'input { tcp { port => 5000 codec => "json" } } output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "micro-%{serviceName}" } }'

## 安装 **Kibana**，并将其连接到Elasticsearch
docker run -d -it --name kibana --link es:elasticsearch -p 5601:5601 docker.mirrors.ustc.edu.cn/elastic/kibana:7.1.0
# docker start kibana # 重新启动
http://192.168.99.100:5601 # 显示日志UI界面
```

### Elasticsearch

- 如果想在生产环境下启动，需要将 Linux 核心配置项 vm.max_map_count 设置为不小于 262144 的数
    - 查看 `more /proc/sys/vm/max_map_count`
    - 设置 `sysctl -w vm.max_map_count=262144`

### Logstash

#### SpringBoot引入依赖

```xml
<!-- 参考：https://github.com/logstash/logstash-logback-encoder -->
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>4.9</version>
</dependency>
```
- `logback-spring.xml`加入appender

```xml
<!--
说明：
    1. 文件的命名和加载顺序有关：logback.xml早于application.yml加载，logback-spring.xml晚于application.yml加载；如果logback配置需要使用application.yml中的属性，需要命名为logback-spring.xml
    2. logback使用application.yml中的属性：必须通过springProperty才可引入application.yml中的值，可以设置默认值
-->

<!-- 定义环境变量spring_application_name，供logstash使用 -->
<springProperty scope="context" name="spring_application_name" source="spring.application.name"/>
<property name="LOGSTASH_DESTINATION" value="${LOGSTASH_DESTINATION:-192.168.99.100:5000}"/>

<appender name="LOGSTASH_TCP" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>${LOGSTASH_DESTINATION}</destination>
    <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
        <providers>
            <mdc />
            <context /><!-- 会把spring_application_name传递进来 -->
            <logLevel />
            <loggerName />
            <pattern>
                <pattern>
                    {
                        "pid": "${PID:-}"
                    }
                </pattern>
            </pattern>
            <threadName />
            <message />
            <logstashMarkers />
            <stackTrace />
        </providers>
    </encoder>
</appender>

<root level="INFO">
    <appender-ref ref="LOGSTASH_TCP" />
</root>
```

#### 与Kafka结合

https://yq.aliyun.com/articles/645316

### 测试

- 配置好上述流程后，运行SpringBoot项目
- 进入Kibana面板创建索引表达式
  - Management - Stack Management - Kibana - Index patterns(显示的是创建好的索引表达式) - Create index pattern(创建新的所有表达式，可查看到所有的索引)
- 进入Discover查看日志




---

参考文章

[^1]: https://www.oschina.net/translate/monitoring-microservices-with-spring-cloud-sleuth
[^2]: https://github.com/doocs/advanced-java/blob/master/docs/high-concurrency/es-write-query-search.md


