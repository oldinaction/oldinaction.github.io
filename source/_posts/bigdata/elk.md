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
- ES的`正排索引`和`倒排索引`
  - `正排索引`是从文档到关键字的映射（已知文档求关键字：doc_id, terms），`倒排索引`是从关键字到文档的映射（已知关键字求文档：term, doc_ids）
  - 二者都是在索引创建的时候生成的，会保存在磁盘，如果内存足够大也会保存在内存中
  - 倒排索引以字词为关键字进行索引，可查询到这个字词的所有文档，它记录该文档的ID和字符在该文档中出现的位置情况
  - 倒排索引存储的数据结构
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
  - 然后每隔 1s或内存 buffer快满了，将数据 **`refresh`** 到一个新的segment file（中间还是会先写到os cache），到了 os cache 数据就能被搜索到（所以ES为NRT近实时，near real-time，**因为中间有 1s 的延迟**）
  - **`translog`** 大到一定程度，或者默认每隔 30min，会触发 commit 操作，将缓冲区的数据都 **`flush`** 到 segment file 磁盘文件中
    - commit/flush操作
      - 将buffer中现有数据refresh到os cache中去，清空buffer
      - 将一个commit point写入磁盘文件，里面标识着这个commit point对应的所有segment file
      - 将os cache数据fsync强刷到磁盘上去
      - 清空translog日志文件
    - translog其实也是先写入os cache的，默认每隔5秒刷一次到磁盘中去，**所以可能会丢失5秒钟的数据**
    - translog日志作用：在你执行commit操作之前，数据要么是停留在buffer中，要么是停留在os cache中，二者都是内存，一旦这台机器死了，内存中的数据就全丢；而此时重启后可通过translog日志进行恢复
  - 如果是删除操作，commit的时候会生成一个.del文件，里面将某个doc标识为deleted状态
  - 如果是更新操作，就是将原来的doc标识为deleted状态，然后新写入一条数据
  - buffer每1秒refresh一次，就会产生一个新的segment file，因此会定期执行 **`merge`**，即将多个segment file合并成一个，同时这里会将标识为deleted的doc给物理删除掉，然后将新的segment file写入磁盘

### 语法

- 字段搜索方式
  - `exact value` 精确匹配：在倒排索引过程中，分词器会将field作为一个整体创建到索引中
  - `full text` 全文检索：分词、近义词同义词、混淆词、大小写、词性、过滤、时态转换等（normaliztion）

#### CRUD

```bash
## 索引操作
PUT /my_index # 创建索引。返回结果`"acknowledged" : true`表示创建成功
DELETE /my_index # 删除索引
GET _cat/indices?v # 查询索引列表

## 插入数据（_id=1）
PUT /my_index/_doc/1
# PUT /my_index/_create/1 # 强制创建（如果存在则返回错误）
# PUT /my_index/_doc # 自动创建ID
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

## 查询(REST API)，DSL的查询见下文
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
  # _source 元数据，默认包含所有。(1)如果为false则不返回_source原数据 (2)数组，只会返回结果下面定义的字段 (3) 对象，可在定义`include: []`和`exclude: []`
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
        # 短语搜索
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

## _mget 批量查询
GET /product/_mget
{
    "ids": [2,3]
}

## _bulk 批量增删改：create(为强制创建)、update、index(创建或更新)、delete
POST /_bulk
# POST /_bulk?filter_path=items.*.error # 创建时，只返回执行失败的数据
{ "create": { "_index": "my_index",  "_id": "1" }} # create创建。json格式必须在一行
{ "name": "_bulk create 1" } # 为上一行create插入的数据
{ "create": { "_index": "my_index",  "_id": "2" }}
{ "name": "_bulk create 2" }
{ "update": { "_index": "my_index",  "_id": "1", "retry_on_conflict" : "3"} } # update更新，更新如果出现并发冲突(乐观锁)，则重试3次
{ "doc" : {"name" : "_bulk update 1"} }
{ "index":  { "_index": "my_index",  "_id": "2" }} # index创建或更新
{ "doc" : {"name" : "_bulk index(create/update) 2"} }
{ "delete": { "_index": "my_index",  "_id": "3" }} # delete删除。由于没有id=3的数据，会返回"status" : 404

## mapping，具体参考下文
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

##### mapping定义和dynamic mapping

- mapping定义
  - mapping就是字段field的元数据（可理解为MySQL的字段定义）
  - ES在创建索引的时候，通过dynamic mapping机制会自动为不同的数据指定相应mapping，当然也可以手动定义mapping
  - mapping中包含了字段的类型、搜索方式（exact value或者full text）、分词器等

```bash
# 手动创建mappings
PUT /my_index
{
  "mappings": {
    "properties": {
        "xxx_field": {
          "type": "xxx_file_type",
          "xxx_mapping_parameter": "xxx_parameter_value"
        }
      }
  }
}

# dynamic mapping案例
# 1.自动创建my_index索引（只有在第一次新增数据的时候才会创建mapping）
PUT /my_index/_doc/1
{
  "name": "smalle",
  "age": 18,
  "birthday": "2020-01-01"
}
# 2.查看mapping，返回如下json结果
GET /my_index/_mapping
{
  "my_index" : {
    "mappings" : {
      "properties" : {
        "age" : {
          "type" : "long" # 此处是long类型而不是integer，主要是因为es的mapping_type是由JSON分析器检测数据类型，而Json没有隐式类型转换（integer=>long or float=> double），所以dynamic mapping会选择一个比较宽的数据类型
        },
        "birthday" : {
          "type" : "date" # 自动转成了日期类型
        },
        "name" : {
          "type" : "text", # 字符串类型
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        }
      }
    }
  }
}
```

##### ES数据类型

> https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-types.html

- 核心类型
  - 数字类型：long, integer, short, byte, double, float, half_float, scaled_float
  - 字符串：keyword、text
    - keyword：适用于索引结构化的字段，可以用于过滤、排序、聚合。keyword类型的字段只能通过精确值（exact value）搜索到。Id应该用keyword
    - text：字段内容会被分析，在生成倒排索引以前，字符串会被分析器分成一个一个词项，从而用于全文检索，如产品描述。text类型的字段不用于排序，很少用于聚合（主要是字段数据会占用大量堆空间，加载字段数据是一个昂贵的过程）
    - 同一个字段有时可能同时具有text和keyword：一个用于全文本搜索，另一个用于聚合和排序
  - 日期：date、date_nanos(ES7 新增)
  - 布尔：boolean
  - 二进制：binary
  - 区间类型：integer_range、float_range、long_range、double_range、date_range
- array：数组。在ES中，数组不需要专用的字段数据类型，默认情况下，任何字段都可以包含零个或多个值，但是，数组中的所有值都必须具有相同的数据类型
- 复杂类型
  - object：用于单个JSON对象
  - nested：用于JSON对象数组
- 地理位置
    - geo-point：纬度/经度积分
    - geo-shape：用于多边形等复杂形状
- 特有类型
  - ip：用于IPv4和IPv6地址
  - completion：提供自动完成建议
  - token_count：计算字符串中令牌的数量
  - murmur3：在索引时计算值的哈希并将其存储在索引中
  - annotated-text：索引包含特殊标记的文本（通常用于标识命名实体）
  - percolator：接受来自query-dsl的查询
  - join：为同一索引内的文档定义父/子关系
  - rank_features：记录数字功能以提高查询时的点击率
  - dense_vector：记录浮点值的密集向量
  - sparse_vector：记录浮点值的稀疏向量
  - search-as-you-type：针对查询优化的文本字段，以实现按需输入的完成
  - alias：为现有字段定义别名
  - flattened：允许将整个JSON对象索引为单个字段
  - shape：对于任意笛卡尔几何
  - histogram：用于百分位数聚合的预聚合数值
  - constant_keyword：当所有文档都具有相同值时的情况

##### Mapping parameters

```bash
# 参考：https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-params.html
PUT /my_index
{
    "mappings": {
        "properties": {
            "username": {
                # 类型
                "type": "text",
                # mapping_parameter
                "index": true, # 是否对当前字段创建索引，默认true，如果不创建索引，该字段不会通过索引被搜索到，但是仍然会在_source元数据中展示
                "doc_values": true, # 是否生成正排索引，为了提升排序和聚合效率，默认true。如果确定不需要对字段进行排序或聚合，也不需要通过脚本访问字段值，则可以禁用doc值以节省磁盘空间，但是设置完了之后则不能改变，需要改变则只能重新创建索引。（不支持text和annotated_text）
                "fielddata": false, #（慎用）默认text类型的数据类型是不能用作聚合、排序等操作的，可使用keyword、doc_values、fielddata=true，但fielddata的效率没有keyword高
                "coerce": false, # 是否允许强制类型转换。true时，"1" => 1（可转换成功）
                "eager_global_ordinal": , # 用于聚合的字段上，优化聚合性能。Frozen indices（冻结索引）：有些索引使用率很高，会被保存在内存中，有些使用率特别低，宁愿在使用的时候重新创建，在使用完毕后丢弃数据，Frozen indices的数据命中频率小，不适用于高搜索负载，数据不会被保存在内存中，堆空间占用比普通索引少得多，Frozen indices是只读的，请求可能是秒级或者分钟级。eager_global_ordinals不适用于Frozen indices 
                "fields": , # 给field创建多字段，用于不同目的（全文检索或者聚合分析排序）
                "search_analyzer": "standard", # 设置单独的查询时分析器，可存储的分词器不同

                "analyzer": "character filter", # 指定分析器，如：character filter、tokenizer、Token filters
                "boost": 1, # 对当前字段相关度的评分权重，默认1
                "copy_to": "full_name", # 将username的值拷贝到full_name字段中，实际full_name中并不会保存的，但是查询full_name是可以查到username的值的
                "dynamic": true, # 控制是否可以动态添加新字段。(1) true：新检测到的字段将添加到映射中（默认）；(2) false：新检测到的字段将被忽略，这些字段将不会被索引，因此将无法搜索，但仍会出现在_source返回的匹配项中；(3) strict：如果检测到新字段，则会引发异常并拒绝文档，必须将新字段显式添加到映射中
                "enable": false, # 是否创建倒排索引，可以对字段操作，也可以对索引操作，如果不创建索引，仍然可以检索并在_source元数据中展示，谨慎使用，该状态无法修改
                "format" "yyyy-MM-dd", # 格式化。如type=date时，可使用yyyy-MM-dd等
                "ignore_above": 256, # 超过长度将被忽略
                "ignore_malformed": true, # 忽略类型错误。如type=integer，当输入字符串时不报错
                "index_options": , # 控制将哪些信息添加到反向索引中以进行搜索和突出显示。仅用于text字段
                "index_phrases": , # 提升exact_value查询速度，但是要消耗更多磁盘空间
                "index_prefixes": { # 前缀搜索
                    "min_chars" : 1, # 前缀最小长度>1，默认2（包含）
                    "max_chars" : 10 # 前缀最大长度<10，默认5（包含）
                },
                "meta": , # 附加元数据
                "normalizer": ,
                "norms": true, # 是否禁用评分（在filter和聚合字段上应该禁用）
                "null_value": "NULL", # 为null值设置默认值
                "position_increment_gap": ,
                "proterties": , # 除了mapping还可用于object的属性设置
                "similarity" , # 为字段设置相关度算法，支持BM25、claassic（TF-IDF）、boolean
                "store": , # 设置字段是否仅查询
                "term_vector": ,
            }
        }
    }
}
```
- `doc_values`和`fielddata`
  - 当字段的doc_values=false，但是又需要聚合时，可打开fielddata，然后临时在内存中创建正排索引（首次查询时生成），fielddata的构建和管理都发生在JVM Heap中
  - fielddata使用的是JVM内存；doc_value在内存不足时会保存在磁盘中，只有当内存充足时，才会加载到内存加快查询
  - ES采用circuit breaker（熔断）机制避免fielddata一次性超过物理内存大小而导致内存溢出。如果触发熔断，查询会被终止并返回异常
  - fielddata默认是false的，因为text字段较长，一般只做分词和索引，很少拿来做聚合排序

##### Metadata fields元数据字段

- `_field_names`
- `_ignored`
- `_id`
- `_index`
- `_meta`
- `_routing`
- `_source` 原始数据
- `_type`

#### aggregations聚合查询

```bash
# https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html

GET /product/_search
{
    # 使用聚合查询
    "aggs": {
        # 自定义的聚合查询名称
        "my_tag_agg_avg": {
            # 1.根据平均值降序排列所有的关键字
            # terms：基于某个字段(field)进行聚合(group by)，且聚合字段必须是exact value类型；返回结果中包含一个 buckets[{"key": "聚合字段值","doc_count": 文档数}]
            "terms": {
                # 聚合字段是tags.keyword，案例中tags字段为text，所有需要使用tags.keyword
                "field": "tags.keyword",
                "order": {
                    "my_avg_price": "desc"
                }
            },
            # 聚合嵌套
            "aggs": {
                "my_avg_price": {
                    # 调用avg函数计算price字段
                    "avg": {
                        "field": "price"
                    }
                }
            }
            # 2.对字段price进行分组，此时会分成两组，然后求平均值
            "range": {
                "field": "price",
                "ranges": [{
                    "from": 1000,
                    "to": 2000
                }, {
                    "from": 2000
                }]
            },
            # 过滤
            "filters" : {
                "filters" : {
                    "errors" :   { "match" : { "level" : "ERROR"   }},
                    "warnings" : { "match" : { "level" : "WARNING" }}
                }
            }
        }
    },
    # 不返回原始数据，只返回聚合结果aggregations
    "size":0
}
```

#### Scripts脚本

- ES脚本语言支持 painless(默认)、expression、mustache、java
  - painless：用于内联和存储脚本，类似于Java，也有注释、关键字、类型、变量、函数等，安全的脚本语言
  - expression：可以非常快速地执行，甚至比编写native脚本还要快，支持javascript语法的子集：单个表达式。缺点：只能访问数字，布尔值，日期和geo_point字段，存储的字段不可用
  - ES 5.0之前还支持Groovy，但是由于其不安全（容易爆内存），被弃用了
- script模板
  - 缓存在集群的cache中，作用域为整个集群，只有发生变更时重新编译。没有过期时间，默认缓存大小是100MB，脚本最大64MB
  - 可以手工设置过期时间script.cache.expire，通过script.cache.max_size设置缓存大小，通过script.max_size_in_bytes配置脚本大小
- `doc['field'].value` 和 `params['_source']['field']`区别
  - 首先，使用doc关键字，将导致该字段的条件被加载到内存（缓存），这将导致更快的执行，但更多的内存消耗。此外，`doc[...]`符号只允许简单类型（不能返回一个复杂类型(json对象或者nested类型)），只有在非分析或单个词条的基础上有意义
  - `_source`每次使用时都必须加载并解析，使用_source非常缓慢。因此，doc仍然是从文档访问值的推荐方式
- 案例

```bash
## https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-scripting.html

## 简单使用
POST /product/_update/1
{
    # ctx为内部变量
    # 可以简写为 `"script": "ctx._source.price -= 1"`
    "script": {
        # 脚本代码。脚本可保存为模板，见下文
        "source": "ctx._source.price -= 1" # 将所有doc的price字段数值-1

        # 给tags字段(数组)增加一个元素
        # "source": "ctx._source.tags.add('new_tag')"

        # 删除id=1的文档。ctx.op = 'noop' 则不做任何操作
        # "source": "ctx.op = 'delete'"

        # Dates日期：ZonedDateTime类型，因此它们支持诸如之类的方法getYear，getDayOfWeek，或例如从历元开始到毫秒getMillis。要在脚本中使用它们，需省略get前缀并继续使用首字母小写的方法名其余部分
        # "source": "doc.createtime.value.year" # 获取字段createtime的年份
    }
}

# upsert：无此文档则新增（此时不会执行脚本代码），有则执行脚本代码
POST /product/_update/10
{
    "script": {
        "source": "ctx._source.price -= 1"
    },
    "upsert": {
      "price": 10
    }
}

# lang脚本语言指定
GET /product/_search
{
    "script_fields": {
        # 返回字段名称
        "test_lang": {
            "script": {
                # 指定脚本语言。默认为painless（可以省略），如果是painless，则source为`doc['price'].value * 0.8`
                "lang": "expression", # expression更适合数字计算，效率比painless高
                "source": "doc['price'] * 0.8",
            }
        }
    }
}

# 参数化脚本
GET /product/_search
{
    "script_fields": {
        # 返回字段名称
        "discount_price": {
            "script": {
                # 参数化查询。第一次查询会把script.source中的表达式进行编译，之后查询速度会更快；如果表达式改变了则需要重新编译，此时使用参数则无需重新编译即可实现不同的算法
                # doc为内置变量
                "source": "doc['price'].value * params.discount",
                # "id": "calculate-discount", # 或者使用script模板，参考下文
                "params": {
                    "discount": 0.8
                }
            }
        },
        # 返回字段为数组
        "array_price": {
            "script": {
                "source": "[doc['price'].value * params.discount_9, doc['price'].value * params.discount_8, doc['price'].value * params.discount_7]",
                # "id": "calculate-discount", # 或者使用script模板，参考下文
                "params": {
                    "discount_9": 0.9,
                    "discount_8": 0.8,
                    "discount_7": 0.7
                }
            }
        }
    }
}

## script模板
# 创建、查询、删除模板，具体使用参考上文
POST _scripts/calculate-discount # 脚本模板名称calculate-discount
{
  "script": {
    "lang": "painless",
    "source": "doc['price'].value * params.discount"
  }
}
GET _scripts/calculate-discount
DELETE _scripts/calculate-discount

## painless复杂脚本
POST /product/_update/1
{
    "script": {
        # 使用多行脚本。里面可使用变量、if、for、正则(需要开启对应配置，不推荐使用，会越过painless的内存安全控制)等
        "source": """
        if(ctx._source.price < 1000) {
            ctx._source.name += '~~hot~~'
        }
        """
    }
}
GET /product/_search
{
    "aggs": {
        "sum_color_red": {
            "sum": {
                "script": {
                    "source": """
                    int total = 0;
                    # 由于tags_obj为复杂对象，因此不能直接通过doc取值，而要使用params['_source']取值
                    for(int i=0; i < params['_source']['tags_obj'].length; i++) {
                        if(params['_source']['tags_obj'][i]['color'] == 'red') {
                            total += 1;
                        }
                    }
                    return total;
                    """
                }
            }
        }
    }
}
```

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

#### ES生产集群部署(基本表)

- ES 生产集群我们部署了 5 台机器，每台机器是 6 核 64G 的，集群总内存是 320G
- 我们 es 集群的日增量数据大概是 2000 万条，每天日增量数据大概是 500MB，每月增量数据大概是 6 亿，15G。目前系统已经运行了几个月（6个月），现在 es 集群里数据总量大概是 100G 左右
- 目前线上有 5 个索引（这个结合你们自己业务来，看看自己有哪些数据可以放 es 的），每个索引的数据量大概是 20G，所以这个数据量之内，我们每个索引分配的是 8 个 shard（比默认的 5 个 shard 多了 3 个 shard）

### 性能优化

- 增加系统内存
- 无用的字段（不用来做检索的字段）不要保存到es中。可将全量数据保存在mysql/hbase中，通过关键字在es中查询到id，然后去获取相应数据
- 数据预热：就是对热数据（如热销商品、微博大V）每隔一段时间，就提前访问一下，让数据进入内存里面去
- 冷热分离：es 可以做类似于 mysql 的水平拆分，冷数据写入一个索引中，然后热数据写入另外一个索引中
- document 模型设计：先在 Java 系统里就完成关联（复杂的SQL查询），将关联好的数据直接写入 es 中（document 模型存储复杂SQL的结果），尽量避免在es中进行 join/nested/parent-child 等查询
- 分页性能优化：使用scroll search或search_after来防止深度分页

### 运维

#### 集群信息

- `_cat` 信息

```bash
## 查看_cat子路径
GET _cat

## 子路径明细
# /_cat/allocation?v # 加上参数v表示显示标题
/_cat/allocation                # 查看集群所在磁盘的分配状况。shards: 各节点的分片数；disk.indices: 该节点中所有索引在该磁盘所占空间
/_cat/shards
/_cat/shards/{index}
/_cat/master
/_cat/nodes                     # 集群的节点信息
/_cat/tasks
/_cat/indices                   # 索引信息
/_cat/indices/{index}
/_cat/segments                  # segments文件状态
/_cat/segments/{index}
/_cat/count
/_cat/count/{index}
/_cat/recovery
/_cat/recovery/{index}
/_cat/health                    # 集群的健康状态。status: 集群健康状态(green健康，yellow警告，red不可用)；node.data: 数据节点个数；pri: 主分片数(primary shards)
/_cat/pending_tasks
/_cat/aliases
/_cat/aliases/{alias}
/_cat/thread_pool
/_cat/thread_pool/{thread_pools}
/_cat/plugins
/_cat/fielddata
/_cat/fielddata/{fields}
/_cat/nodeattrs
/_cat/repositories
/_cat/snapshots/{repository}
/_cat/templates
```

## Logstash

```bash
# 测试向Logstash发送数据
curl -X POST 'http://192.168.99.100:5000' -H 'Content-Type: application/json' -d '{"Say" : "Hello world!"}'
```

## Kibana

- [文档](https://www.elastic.co/guide/en/kibana/7.8/index.html)
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

- 基于k8s-helm安装参考：[ELK](/_posts/devops/helm.md#ELK)
- 基于docker安装

```bash
## 安装 **Elasticsearch** (下载会较慢，可尝试下载几次)
docker run -d -it --name es -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.mirrors.ustc.edu.cn/elastic/elasticsearch:7.1.0
# docker start es # 重新启动
# 查看Elasticsearch信息。(其中`192.168.99.100`为docker所在宿主机IP，此处为docker运行在windows虚拟机上的IP)。其他的地址如：http://192.168.99.100:9200/_cat/ 和 http://192.168.99.100:9200/_cat/nodes 信息。访问`http://192.168.99.100:9200/micro-sq-auth/_search` 查看micro-sq-auth这个index下的日志信息
http://192.168.99.100:9200/

## 安装 **Logstash**，并指定输入输出。将输入声明为TCP(兼容LogstashTcpSocketAppender的日志记录器)，声明Elasticsearch为输出
# 此处的 -e 为logstash的参数而不是docker命令的参数(192.168.99.100:9200为elasticsearch服务端口)
    # input表示Logstash开放5000的TCP端口供外部调用
    # 可以在output中同时加入控制台输出调试观察日志是否传入Logstash，如`output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "%{spring_application_name}-%{+YYYY.MM}" } stdout { codec => rubydebug } }`
docker run -d -it --name logstash -p 5000:5000 docker.mirrors.ustc.edu.cn/elastic/logstash:7.1.0 -e 'input { tcp { port => 5000 codec => "json" } } output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "%{spring_application_name}-%{+YYYY.MM}" } }'

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


