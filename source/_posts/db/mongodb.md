---
layout: "post"
title: "mongodb"
date: "2016-08-14 18:08"
categories: db
tags: [db, mongodb]
---

## mongodb简介

- MongoDB 是一个基于分布式文件存储的数据库。由 C++ 语言编写。旨在为 WEB 应用提供可扩展的高性能数据存储解决方案。MongoDB 是一个介于关系数据库和非关系数据库之间的产品，是非关系数据库当中功能最丰富，最像关系数据库的 [^1]
- 官网：[https://www.mongodb.com](https://www.mongodb.com)

## mongodb安装运行

### windows

- [下载地址](https://www.mongodb.com/dr/fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-ssl-3.2.8-signed.msi/download)
- 运行.msi文件，选择custom模式后可以选择安装位置(如：D:/software/mongodb)
- 进入到安装目录D:/software/mongodb
- 新建 `log` 和 `db` 两个文件夹
- `D:/software/mongodb/bin/mongo --version` 查看版本

### linux

```shell
sudo curl -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.0.6.tgz    # 下载（下载到了当前目录）
tar -zxvf mongodb-linux-x86_64-3.0.6.tgz                                        # 解压（解压到了当前目录）
sudo mv mongodb-linux-x86_64-3.0.6/ /usr/local/mongodb                          # 将解压包拷贝到指定目录
export PATH=/usr/local/mongodb/bin:$PATH                                        # 将其添加到 PATH 路径
sudo mkdir -p /data/db                                                          # 创建数据库目录 /data/db 是 MongoDB 默认的启动的数据库路径(--dbpath可指定数据库目录)

# 运行测试
cd /usr/local/mongodb/bin
mongo --version                                                                 # 查看版本
sudo ./mongod                                                                   # 启动服务
sudo ./mongo                                                                    # 登录后台管理

## 启动web服务
# sudo ./mongod --dbpath=/data/db --rest                                        # 访问 http://localhost:28017 可进入web界面
```

### 运行mongodb

- 法一：命令行运行
  - cmd进入到安装目录的bin目录下
  - 运行 `mongod.exe --dbpath D:\software\mongodb\db --auth`
      - **其中参数`--auth`表示开启安全验证。如若不开启，则无密码登录可以查看admin下其他用户的数据**
- 法二：将MongoDB服务器作为Windows服务运行
    - (以管理员运行)cmd进入到安装目录的`D:\software\mongodb\bin`目录下
    - 运行(注意参数说明) `mongod.exe --logpath "D:\software\mongodb\log\mongodb.log" --logappend --dbpath "D:\software\mongodb\db" --port 27018 --serviceName "mongodb" --serviceDisplayName "mongodb" --install`
        - 参数描述
            - `--bind_ip 127.0.0.1`	绑定服务IP，若绑定127.0.0.1，数据库实例将只监听127.0.0.1的请求，即只能本机访问，不指定默认本地所有IP
            - `--logpath`	定MongoDB日志文件，注意是指定文件不是目录
            - `--logappend`	使用追加的方式写日志
            - `--dbpath`	指定数据库路径
            - `--port`	指定服务端口号(默认端口27017)
            - `--serviceName`	指定服务名称
            - `--serviceDisplayName`	指定服务名称，有多个mongodb服务时执行。
            - `--install`	指定作为一个Windows服务安装。
        - `mongod.exe --auth --logpath "D:\software\mongodb\log\mongodb.log" --logappend --dbpath "D:\software\mongodb\db" --port 27018 --serviceName "mongodb" --serviceDisplayName "mongodb" --reinstall` 其中`--auth`表示开启安全验证、`--reinstall`表示重新注册服务
    - 卸载：管理员运行`sc delete 服务名称`

## MongoDB使用

- **mongodb默认内置有3个数据库，一个名为admin，一个名为local、还有一个默认库test(隐藏库)**
- MongoDB Shell是MongoDB自带的交互式Javascript shell，用来对MongoDB进行操作和管理的交互式环境
- 连接MongoDB Shell
    - 重启一个dos窗口，进入到安装目录的bin目录下
    - 运行命令 `mongo`，看到版本号则运行成功，之后会进入MongoDB Shell，它默认会链接到 test 数据库
        - `mongo --port 27018` 指定端口进行连接

### 数据库和集合(表)

```bash
2+2 # 执行计算，会打印 4

## 数据库操作
db # 查看当前数据库(不选择数据库则默认是test)
show dbs # 查看所有数据库
use aezo # 如果数据库不存在，则创建数据库，否则切换到指定数据库
db.dropDatabase() # 删除当前数据库，可使用db查看

## 集合操作
show collections # 或show tables，查看当前数据库所有集合
db.createCollection("mycol1") # 简单的创建集合
db.createCollection("mycol2", {capped: true, autoIndexId: true, size: 6142800, max: 10000}) # 创建集合并指定参数。此时为创建固定集合(capped: true)，自动在 _id 字段创建索引(autoIndexId: true)，整个集合空间大小 6142800 KB, 文档最大个数为 10000 个
db.mycol3.insert({"name": "smalle"}) # 自动创建集合。在插入一些文档时，如果没有对应集合，MongoDB 会自动创建集合
db.mycol1.drop() # 删除指定集合

## 插入并查询文档
db.mydoc.insert({title: 'hello world', view: 10, tags: ['hello', 'world']}) # 插入成功会自动创建_id字段
db.mydoc.find() # 会打印集合mydoc的所有数据
```

### CRUD

- 插入文档 `db.COLLECTION_NAME.insert(document)`
- 更新文档


### 用户管理

- 创建用户

    ```sql
    -- 切换到admin数据库
    use admin
    -- 创建管理员账号。具体参数见下文
    db.createUser({user: "smalle", pwd: "smalle", roles:[{role: "root", db: "admin"}]})
    -- 验证密码
    db.auth("smalle", "smalle")
    ```
    - roles：指定用户的角色，可以用一个空数组给新用户设定空角色。其中role字段，可以指定内置角色和用户定义的角色
    - db：指定该用户某个指定数据库的角色
    - role：用户角色，内置角色如下
        - 数据库用户角色：read、readWrite
        - 数据库管理角色：dbAdmin、dbOwner、userAdmin
        - 集群管理角色：clusterAdmin、clusterManager、clusterMonitor、hostManager
        - 备份恢复角色：backup、restore
        - 所有数据库角色：readAnyDatabase、readWriteAnyDatabase、userAdminAnyDatabase、dbAdminAnyDatabase
        - 超级用户角色：root // 这里还有几个角色间接或直接提供了系统超级用户的访问（dbOwner 、userAdmin、userAdminAnyDatabase）
        - 内部角色：__system
    - 具体角色的功能
        - read：允许用户读取指定数据库
        - readWrite：允许用户读写指定数据库
        - dbAdmin：允许用户在指定数据库中执行管理函数，如索引创建、删除，查看统计或访问system.profile
        - userAdmin：允许用户向system.users集合写入，可以找指定数据库里创建、删除和管理用户
        - clusterAdmin：只在admin数据库中可用，赋予用户所有分片和复制集相关函数的管理权限
        - readAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的读权限
        - readWriteAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的读写权限
        - userAdminAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的userAdmin权限
        - dbAdminAnyDatabase：只在admin数据库中可用，赋予用户所有数据库的dbAdmin权限
        - root：只在admin数据库中可用。超级账号，超级权限
    - 一般可给某数据库管理员角色：read、readWrite、dbAdmin、userAdmin

## 复杂查询




## 客户端管理工具Robo 3T

- 下载地址 `https://robomongo.org/download` (`Download portable version for Windows 64-bit`为免安装版)






---

参考文章

[^1]: http://www.runoob.com/mongodb/mongodb-tutorial.html (MongoDB 教程)
