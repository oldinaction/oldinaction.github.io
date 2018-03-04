---
layout: "post"
title: "memcached缓存数据库"
date: "2018-03-03 14:32"
categories: db
tags: arch
---

## 简介

- [菜鸟教程](http://www.runoob.com/memcached/memcached-tutorial.html)

## 安装和使用

- `yum –y install memcached` 安装
- `systemctl start memcached` 启动(默认端口11211)
- 测试存值取值

    ```bash
    telnet localhost 11211
    # 设置变量abc的长度为5
    set abc 0 0 5
    # 设置abc的值为12345，长度必须和上面一致
    12345
    # 获取abc的值
    get abc
    # 退出
    quit
    ```

## 解决session一致性(session共享)

参考《nginx》的【反向代理和负载均衡】部分










---