---
layout: "post"
title: "ELK(Elasticsearch、Logstash、Kibana)"
date: "2019-05-26 15:05"
categories: bigdata
tags: [web]
---

## ELK简介

- [官网](https://www.elastic.co)、[docs](https://www.elastic.co/guide/index.html)
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
    - 访问`http://192.168.99.100:9200/`查看Elasticsearch信息。(其中`192.168.99.100`为docker所在服务器IP，此处未docker运行在windows虚拟机上的IP)
- 安装`Logstash`，并指定输入输出。将输入声明为TCP(兼容LogstashTcpSocketAppender的日志记录器)，声明Elasticsearch为输出
    - `docker run -d -it --name logstash -p 5000:5000 docker.elastic.co/logstash/logstash:7.1.0 -e 'input { tcp { port => 5000 codec => "json" } } output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "micro-%{serviceName}" } }'`
        - 此处的`-e`为logstash的参数而不是docker命令的参数
        - 可以在output中同时加入控制台输出，如`output { elasticsearch { hosts => ["192.168.99.100:9200"] index => "micro-%{serviceName}" } stdout { codec => rubydebug } }`
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
- logback-spring.xml加入appender

```xml
<appender name="logstash-tcp" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>192.168.99.100:5000</destination>
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
```

#### 与Kafka结合

https://yq.aliyun.com/articles/645316

### Kibana

- Discover显示
    - 创建索引表达式：Management - Kibana - Index Patterns - Create index pattern - 输入正则匹配现有的索引 - 可在Discover中查看




---

参考文章

[^1]: https://www.oschina.net/translate/monitoring-microservices-with-spring-cloud-sleuth

