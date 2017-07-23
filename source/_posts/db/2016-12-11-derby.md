---
layout: "post"
title: "derby"
date: "2016-12-11 21:13"
categories: [extend]
tags: [apache, db]
---

## 简介

1. Apache Derby是一个完全用java编写的数据库，非常小巧，核心部分derby.jar只有2M，所以既可以做为单独的数据库服务器使用，也可以内嵌在应用程序中使用。
2. Derby数据库有两种运行模式
    - 内嵌模式：Derby数据库与应用程序共享同一个JVM，通常由应用程序负责启动和停止，对除启动它的应用程序外的其它应用程序不可见，即其它应用程序不可访问它。如ofbiz自带的数据库即为derby
    - 网络模式：Derby数据库独占一个JVM，做为服务器上的一个独立进程运行。在这种模式下，允许有多个应用程序来访问同一个Derby数据库
3. 官方网址：[http://db.apache.org/derby/](http://db.apache.org/derby/)。目前最新版本为`10.13.1.1`(需要jdk1.8)

## 安装与运行

1. 下载压缩包到本地解压即可，如根目录为：`D:\java\db-derby-10.13.1.1-bin`
2. 设置`DERBY_HOME`：`set DERBY_HOME=D:\java\db-derby-10.13.1.1-bin`
3. 运行`setEmbeddedCP.bat`设置`CLASSPATH`：`D:\derby\db-derby-10.X.Y.0-bin\bin>setEmbeddedCP.bat`
4. 运行`ij.bat`查看ij版本：`D:\derby\db-derby-10.X.Y.0-bin\bin>ij.bat`（退出ij：`ij> quit;`）
5. 启动derby服务：`D:\derby\db-derby-10.X.Y.0-bin\bin>startNetworkServer.bat`（默认使用端口1527）

## 基本sql举例

> 文档：%DERBY_HOME%/docs/html/getstart/index.html 中 Creating a Derby database and running SQL statements

1. 运行`ij.bat`
2. 创建数据库：`connect 'jdbc:derby:mytest;create=true;user=root;password=root';`
    - `create=true`表示当数据库mytest不存在时自动创建一个。（此时会看到bin目录下多一个mytest文件夹，里面即为数据文件）
    - `user=root;password=root`表示创建数据库后，登录该数据库的用户名密码。derby的用户名密码是在创建数据库的时候设置的。如果不填则不需用户名也可登录
3. 创建表：`create table mytable (id int primary key, name varchar(12));`
4. 新增数据：`insert into mytable values (10,'ten'),(20,'twenty'),(30,'thirty');`
5. 查询数据：`select * from mytable where id=20;`

## 客户端使用

1. 使用客户端时，需要的jar包为：`%DERBY_HOME%/lib/derbyclient.jar`
2. 迷你型客户端：`sqleonardo` 纯java编写，并开源。[客户端和源码](/data/download/sqleonardo.zip)
3. 增强版：`squirrel-sql-3.7.1-standard.jar` [官网下载](http://www.squirrelsql.org/#installation)，[jb51](http://www.jb51.net/database/467890.html)
    - driver使用上述jar包
    - url：`jdbc:derby://127.0.0.1:1527/mytest`


---
