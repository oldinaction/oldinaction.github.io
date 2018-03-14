---
layout: "post"
title: "Lucene"
date: "2018-03-13 20:31"
categories: bigdata
tags: [lucene, solr]
---

## 简介

- `Lucene`是一个基于java开发的全文搜索框架。本文基于`lucene-4.9.1`(文档/API在解压文件的/lucene-4.9.1/docs目录)
- 倒排索引：根据属性的值来查找记录。这种索引表中的每一项都包括一个属性值和具有该属性值的各记录的地址。由于不是由记录来确定属性值，而是由属性值来确定记录的位置，因而称为倒排索引(invertedindex)
- lucene提供的服务实际包含两部分：一入一出。所谓入是写入，即将你提供的源（本质是字符串）写入索引或者将其从索引中删除；所谓出是读出，即向用户提供全文搜索服务，让用户可以通过关键词定位源
    - 写入流程：源字符串首先经过analyzer分词处理。将源中需要的信息加入Document的各个Field中，并把需要索引的Field索引起来，把需要存储的Field存储起来。将索引写入存储器(内存或磁盘)
    - 读出流程：用户提供搜索关键词，经过analyzer处理。对处理后的关键词搜索索引找出对应的Document。用户根据需要从找到的Document中提取需要的Field

- 企业海量数据搜索服务器架构

![企业海量数据搜索服务器架构](/data/bigdata/solr-arch.png)

## 本地文件内容搜索实践











---

linliangyi2007.javaeye.com