---
layout: "post"
title: "windows"
date: "2017-05-10 15:26"
categories: [extend]
tags: [bat]
---

## 常用命令

- `ipconfig` 查看ip地址
- `arp -a` 查看局域网下所有机器mac地址
- `ping 192.168.1.1`
- `telnet 192.168.1.1 8080`

## 常用技巧

- 开机启动java等程序
    - 新建`bat`启动脚本
    - 运行栏输入`taskschd.msc`打开`计划任务工具`，这里可以创建`基本任务`，有开机启动执行程序等选项可以设置
        - 运行exe程序的最好写成bat脚本运行。如nginx.exe写到bat脚本中去运行，然后任务中运行此脚本
    - 创建服务也可实现

## bat脚本

参考《bat》