---
layout: "post"
title: "mongodb"
date: "2016-08-14 18:08"
categories: db
tags: [db, mongodb]
---

## mongodb简介

- MongoDB 是一个基于分布式文件存储的数据库。由 C++ 语言编写。旨在为 WEB 应用提供可扩展的高性能数据存储解决方案。MongoDB 是一个介于关系数据库和非关系数据库之间的产品，是非关系数据库当中功能最丰富，最像关系数据库的。
- 官网：[https://www.mongodb.com](https://www.mongodb.com)

## mongodb安装

- [下载地址](https://www.mongodb.com/dr/fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-ssl-3.2.8-signed.msi/download)
- 运行.msi文件，选择custom模式后可以选择安装位置(如：D:/software/mongodb)
- 进入到安装目录D:/software/mongodb
- 新建 `log` 和 `db` 两个文件夹

## 运行mongodb

1. 法一：命令行运行
  - cmd进入到安装目录的bin目录下
  - 运行 `mongod.exe --dbpath D:\software\mongodb\db --auth`
      - 其中参数`--auth`表示开启安全验证。如若不开启，则admin无密码登录可以查看admin下其他用户的数据
2. 法二：将MongoDB服务器作为Windows服务运行
    - (以管理员运行)cmd进入到安装目录的`D:\software\mongodb\bin`目录下
    - 运行(注意参数说明) `mongod.exe --logpath "D:\software\mongodb\log\mongodb.log" --logappend --dbpath "D:\software\mongodb\db" --port 27017 --serviceName "mongodb" --serviceDisplayName "mongodb" --install`
        - 参数描述
            - `--bind_ip 127.0.0.1`	绑定服务IP，若绑定127.0.0.1，数据库实例将只监听127.0.0.1的请求，即只能本机访问，不指定默认本地所有IP
            - `--logpath`	定MongoDB日志文件，注意是指定文件不是目录
            - `--logappend`	使用追加的方式写日志
            - `--dbpath`	指定数据库路径
            - `--port`	指定服务端口号，默认端口27017
            - `--serviceName`	指定服务名称
            - `--serviceDisplayName`	指定服务名称，有多个mongodb服务时执行。
            - `--install`	指定作为一个Windows服务安装。
        - `mongod.exe --auth --logpath "D:\software\mongodb\log\mongodb.log" --logappend --dbpath "D:\software\mongodb\db" --port 27017 --serviceName "mongodb" --serviceDisplayName "mongodb" --reinstall` 其中`--auth`表示开启安全验证、`--reinstall`表示重新注册服务
    - 卸载：管理员运行`sc delete 服务名称`

## MongoDB牛刀小试

MongoDB Shell是MongoDB自带的交互式Javascript shell,用来对MongoDB进行操作和管理的交互式环境。

- 重启一个dos窗口，进入到安装目录的bin目录下
- 运行命令 `mongo`, 看到版本号则运行成功。当你进入mongoDB后台后，它默认会链接到 test 文档（数据库），mongodb默认内置有两个数据库，一个名为admin，一个名为local
    - `mongo --port 27017` 指定端口进行连接
- 牛刀小试
  - 输入 `2+2` 回车，会打印 4
  - 运行 `db` 查看当前数据库(test)
  - 运行 `db.myvar.insert({"num":10})` 表示将10插入到集合myvar的num字段中(直接运行后如果没有myvar的集合则新建一个)
  - 运行 `db.myvar.find()` 会打印集合myvar的情况

## MongoDB使用

### 设置用户名密码

- `use admin` 切换到admin数据库
- `db.createUser({user:"root",pwd:"root",roles:["root"]})` 创建管理员账号
- `db.auth("root","root")` 验证登录
- `exit` 退出
- 重新启动，并以`--auth`模式启动
- `mongo --port 27017 -u root -p root admin` 使用root/root登录admin数据库

### MongoDB管理工具robomongo

1. 下载地址 `https://robomongo.org/download` (`Download portable version for Windows 64-bit`为免安装版)



> 参考文章
>
> - [MongoDB 教程] http://www.runoob.com/mongodb/mongodb-tutorial.html
