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

- Spring Cloud Sleuth在与ELK平台整合使用时，只需要实现与负责日志收集的Logstash完成数据对接即可，且Logstash自身也支持收集logback日志，所有通过在logback配置中增加对logstash的appender，就能非常方便的将日志转换成以json的格式存储和输出了

### 基于容器安装

- 安装Elasticsearch(下载会较慢)
    - `docker run -d -it --name es -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.1.0`
- 安装Kibana，并将其连接到Elasticsearch
    - `docker run -d -it --name kibana --link es:elasticsearch -p 5601:5601 docker.elastic.co/kibana/kibana:7.1.0`
- 安装Logstash，并指定输入输出。将输入声明为TCP(兼容LogstashTcpSocketAppender的日志记录器)，声明Elasticsearch为输出
    - `docker run -d -it --name logstash -p 5000:5000 logstash -e 'input { tcp { port => 5000 codec => "json" } } output { elasticsearch { hosts => ["192.168.99.100"] index => "micro-%{serviceName}" } }'`

### Elasticsearch

- 如果想在生产环境下启动，需要将 Linux 核心配置项 vm.max_map_count 设置为不小于 262144 的数
    - 查看 `more /proc/sys/vm/max_map_count`
    - 设置 `sysctl -w vm.max_map_count=262144`


