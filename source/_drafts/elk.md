---
layout: "post"
title: "ELK(Elasticsearch、Logstash、Kibana)"
date: "2019-05-26 15:05"
categories: bigdata
tags: [web]
---

## ELK简介

- [官网](https://www.elastic.co)、[官方中文文档](https://www.elastic.co/guide/cn/index.html)、[docs](https://www.elastic.co/guide/index.html)
- ELK平台主要有由ElasticSearch、Logstash和Kiabana三个开源免费工具组成
    - `Elasticsearch` 是个开源分布式搜索引擎，它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等
    - `Logstash` 可以对日志进行收集、过滤，并将其存储供以后使用
    - `Kibana` Kibana可以为 Logstash 和 ElasticSearch 提供的日志分析友好的 Web 界面，可以帮助汇总、分析和搜索重要数据日志

## 与springcloud结合

- Spring Cloud与ELK平台整合使用时，只需要实现与负责日志收集的Logstash完成数据对接即可，且Logstash自身也支持收集logback日志，所有通过在logback配置中增加对logstash的appender，就能非常方便的将日志转换成以json的格式存储和输出了 [^1]

### 基于容器安装

- 安装`Elasticsearch`(下载会较慢，可尝试下载几次)
    - `docker run -d -it --name es -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.1.0`
    - 重新启动`docker start es`
    - 访问`http://192.168.99.100:9200/`查看Elasticsearch信息。(其中`192.168.99.100`为docker所在宿主机IP，此处为docker运行在windows虚拟机上的IP)
        - http://192.168.99.100:9200/_cat/ 和 http://192.168.99.100:9200/_cat/nodes 信息
    - 访问`http://192.168.99.100:9200/micro-sq-auth/_search` 查看micro-sq-auth这个index下的日志信息
- 安装`Logstash`，并指定输入输出。将输入声明为TCP(兼容LogstashTcpSocketAppender的日志记录器)，声明Elasticsearch为输出
    - `docker run -d -it --name logstash -p 5000:5000 docker.elastic.co/logstash/logstash:7.1.0 -e 'input { tcp { port => 5000 codec => "json" } } output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "micro-%{serviceName}" } }'`
        - 此处的`-e`为logstash的参数而不是docker命令的参数(`192.168.99.100:9200`为elasticsearch服务端口)
        - input表示Logstash开放5000的TCP端口供外部调用
        - **可以在output中同时加入控制台输出调试观察日志是否传入Logstash**，如`output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "micro-%{serviceName}" } stdout { codec => rubydebug } }`
- 安装`Kibana`，并将其连接到Elasticsearch
    - `docker run -d -it --name kibana --link es:elasticsearch -p 5601:5601 docker.elastic.co/kibana/kibana:7.1.0`
    - 重新启动`docker start kibana`
    - 访问`http://192.168.99.100:5601`显示日志UI界面

### Elasticsearch

- 如果想在生产环境下启动，需要将 Linux 核心配置项 vm.max_map_count 设置为不小于 262144 的数
    - 查看 `more /proc/sys/vm/max_map_count`
    - 设置 `sysctl -w vm.max_map_count=262144`

### Logstash

#### Springboot引入依赖

```xml
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

<!-- 定义环境变量 -->
<springProperty scope="context" name="springApplicationName" source="spring.application.name"/>
<property name="LOGSTASH_DESTINATION" value="${LOGSTASH_DESTINATION:-192.168.99.100:5000}"/>

<appender name="LOGSTASH-TCP" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>${LOGSTASH_DESTINATION}</destination>
    <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
        <providers>
            <mdc />
            <context />
            <logLevel />
            <loggerName />
            <pattern>
                <!-- 此处 serviceName 对应 `output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "micro-%{serviceName}" }` 中的 serviceName -->
                <pattern>
                    {
                        "serviceName": "${springAppName:-}",
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
    <appender-ref ref="LOGSTASH-TCP" />
</root>
```

#### 与Kafka结合

https://yq.aliyun.com/articles/645316

### Kibana

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

#### Discover显示

- 需要先创建索引表达式

#### Management

Elasticsearch设置

Kibana设置

- Index Patterns
        - 创建索引表达式：Create index pattern - 输入正则匹配现有的索引 - 可在Discover中查看
- Advanced Settings
    - General 
        - 修改日志日期显示：Date format - `YYYY/MM/DD HH:mm:ss.SSS`; Day of week - `Monday`
        - 接收异常邮件：Admin email
    - Discover
        - 定义"发现"标签页上默认显示的列：Default columns - `message,logger_name` (默认显示message和logger_name两个字段)


#### 其他

- Stack Monitoring
    - 首次进入 Turn on monitoring 开启ELK服务器磁盘，内存等监控





---

参考文章

[^1]: https://www.oschina.net/translate/monitoring-microservices-with-spring-cloud-sleuth

