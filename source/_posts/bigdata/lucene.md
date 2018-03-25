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

> 具体参考 `smjava/lucene`

- 相关jar包

```bash
lucene-core-4.9.1.jar # 核心包
lucene-queries-4.9.1.jar # 检索
lucene-queryparser-4.9.1.jar 
lucene-analyzers-common-4.9.1.jar # 分词器
lucene-highlighter-4.9.1.jar # 高亮
```

- 写索引

```java
/** 会生成下列索引文件
_0.cfe
_0.cfs
_0.si
segments.gen
segments_1
write.lock
*/
public static final String indexDir = System.getProperty("user.dir") + "/demo_index"; // 存放索引的文件夹
public static final String dataDir = System.getProperty("user.dir") + "/qq"; // 数据文件夹

@Test
public void writerIndex() {
    try {
        // 将索引保存到硬盘中
        Directory dir = FSDirectory.open(new File(indexDir));
        // Directory directory = new RAMDirectory(); // 将索引保存到内存中

        // 默认分词器(只支持英文，中文需要中文分词器，如：IKAnalyzer2012_FF.jar)
        Analyzer analyzer = new StandardAnalyzer(Version.LUCENE_4_9);
        IndexWriterConfig config = new IndexWriterConfig(Version.LUCENE_4_9, analyzer);
        config.setOpenMode(IndexWriterConfig.OpenMode.CREATE_OR_APPEND); // 增量添加索引(之前的索引数据不会覆盖)

        // 索引生成器
        IndexWriter writer = new IndexWriter(dir, config);

        File fileData = new File(dataDir);
        // 列出目录下所有文件
        Collection<File> files = FileUtils.listFiles(fileData, TrueFileFilter.INSTANCE, TrueFileFilter.INSTANCE);
        for(File  f : files) {
            // 文档
            Document doc = new Document();
            // 字段
            doc.add(new StringField("fileName", f.getAbsolutePath(), Field.Store.YES)); // 文件名
            doc.add(new TextField("content", FileUtils.readFileToString(f), Field.Store.YES)); // 文件内容
            doc.add(new LongField("lastModify", f.lastModified(), Field.Store.YES)); // 上次修改时间

            writer.addDocument(doc);
        }
        writer.close();
    } catch (IOException e) {
        e.printStackTrace();
    }
}
```

- 检索

```java
@Test
public void search() {
    try {
        Directory dir = FSDirectory.open(new File(WriterIndex.indexDir));
        IndexReader reader = DirectoryReader.open(dir);
        IndexSearcher searcher = new IndexSearcher(reader);

        StandardAnalyzer standardAnalyzer = new StandardAnalyzer(Version.LUCENE_4_9);
        QueryParser qp = new QueryParser(Version.LUCENE_4_9, "content", standardAnalyzer);
        Query query = qp.parse("sitemap");
        TopDocs search = searcher.search(query, 10); // 获取前10个文档

        ScoreDoc[] scoreDocs = search.scoreDocs;
        for(ScoreDoc sc : scoreDocs) {
            int docId = sc.doc;
            Document document = reader.document(docId);
            System.out.println(document.get("fileName"));
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

## solr企业级搜索服务器

详细参考《solr》




---
