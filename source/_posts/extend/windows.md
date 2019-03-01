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
    - 基于创建服务也可实现
    - 基于创建bat脚本
        - 法一：将bat脚本的快捷方式放到启动目录
            - 全局启动目录：`C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp`(.../「开始」菜单/程序/启动)
            - 用户启动目录：`C:\Users\smalle\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`
        - 法二：运行栏输入`taskschd.msc`打开`计划任务工具`，这里可以创建`基本任务`，有开机启动执行程序等选项可以设置
            - 运行exe程序的最好写成bat脚本运行。如nginx.exe写到bat脚本中去运行，然后任务中运行此脚本
## bat脚本

参考《bat》

## 其他

### ssh客户端(不好用)

> **使用cmder即可**

- 下载openssh: [https://github.com/PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
- 解压后将其根目录设置到Path中即可在cmd命令中使用ssh命令连接linux服务器