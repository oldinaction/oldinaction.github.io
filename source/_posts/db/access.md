---
layout: "post"
title: "access"
date: "2018-11-20 14:06"
categories: [db]
tags: [microsoft, db]
---

## access数据简介

- `Access 2000-2003`文件格式`*.mdb`，数据加密容易被破解
- `Access > 2007`文件格式为`*.accdb`

## 特殊语法

- 仅查询10条数据：`select top 10 * from my_table order by id`

## java连接(基于springboot)

> 参考项目：https://github.com/oldinaction/springboot/tree/master/z-exe4j-accessdb

- 基于`UcanAccess`驱动连接
    - [官网](http://ucanaccess.sourceforge.net/site.html)
    - 内部基于`HSQLDB`实现。无需ODBC支持
- 数据源路径支持绝对路径、相对路径、局域网路径(不支持FTP/HTTP)。**其中使用局域网路径时，第一次访问保存目标数据所在主机的登录凭证即可，下次(运行程序过程中)无需登录。**
- pom.xml

```xml
<!--连接access驱动-->
<dependency>
    <groupId>net.sf.ucanaccess</groupId>
    <artifactId>ucanaccess</artifactId>
    <version>3.0.1</version>
</dependency>

<!-- 连接加密access数据库时需要 -->
<!-- https://mvnrepository.com/artifact/com.healthmarketscience.jackcess/jackcess -->
<dependency>
    <groupId>com.healthmarketscience.jackcess</groupId>
    <artifactId>jackcess</artifactId>
    <version>2.1.0</version>
</dependency>
<!-- https://mvnrepository.com/artifact/com.healthmarketscience.jackcess/jackcess-encrypt -->
<dependency>
    <groupId>com.healthmarketscience.jackcess</groupId>
    <artifactId>jackcess-encrypt</artifactId>
    <version>2.1.4</version>
</dependency>
```
- application.yml

```yml
spring:
  datasource:
    driver-class-name: net.ucanaccess.jdbc.UcanaccessDriver
    # url: jdbc:ucanaccess://D:/gitwork/springboot/z-exe4j-accessdb/test.accdb;memory=true
    # 通过vm参数传递，可传递相对路径。jackcessOpener为加密access配置
    jdbc-url: jdbc:ucanaccess://${myexe.dbpath};jackcessOpener=cn.com.unilog.fedex.config.CryptCodecOpener;memory=true
    password: 123456F0C2785DA271888
```
- 访问加密数据源时需要

```java
@Configuration
public class CryptCodecOpener implements JackcessOpenerInterface {
    public Database open(File fl,String pwd) throws IOException {
        DatabaseBuilder dbd =new DatabaseBuilder(fl);
        dbd.setAutoSync(false);
        dbd.setCodecProvider(new CryptCodecProvider(pwd));
        dbd.setReadOnly(false);
        return dbd.open();
    }
}
```

## nodejs连接

> 参考项目：https://github.com/oldinaction/smweb/tree/master/nwjs-demo/demo3-accessdb

- 安装插件[node-adodb](https://github.com/nuintun/node-adodb)
    - `npm install node-adodb` 即可使用
- 常见错误
    - 未找到提供程序。该程序可能未正确安装
        - 需要按照access版本安装驱动。本案例基于win64操作系统，Access2016 32位，因此此时需要下载Access2016 32位驱动(https://www.microsoft.com/en-us/download/details.aspx?id=54920)。打包nw.js后，客户端也需要安装对于驱动
        - Access 2000-2003 (*.mdb) Microsoft.Jet.OLEDB.4.0 (对于 Windows XP SP2 以上系统默认支持 Microsoft.Jet.OLEDB.4.0)
        - Access > 2007 (*.accdb) 如Access2016对应配置为：Microsoft.ACE.OLEDB.16.0
    - 文件名无效(-2147467259, Not a valid file name)
        - `Data Source`中文件支持绝对路径、相对路径、局域网路径(不支持FTP/HTTP)，主要字符串编码和路径分隔符
    - 不可识别的数据库格式(-2147467259)
        - 使用`Microsoft.Jet.OLEDB.4.0`连接字符串，去连接Access2016的文件(.accdb)则报此错误，此时需要Access2016驱动
        - 使用`Microsoft.ACE.OLEDB.16.0`可以同时解析`.accdb`和`.mdb`(对于 Windows XP SP2 以上系统默认支持 Microsoft.Jet.OLEDB.4.0，其它需要自己安装支持)


