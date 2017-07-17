---
layout: "post"
title: "vmware"
date: "2017-06-24 11:19"
categories: [linux]
tags: [vmware, linux, centos]
---

* 目录
{:toc}

## 虚拟机安装

- 下载安装VMware
- 下载centos7镜像文件 [https://www.centos.org/download/](https://www.centos.org/download/). `DVD ISO`安装包含有桌面系统，`Minimal ISO`是最小安装包，不含桌面系统
- 虚拟机的安装位置选择在较空闲的磁盘，也可使用移动硬盘
- 除了安装位置，其他使用默认配置，点击安装（下面以`Minimal ISO`为例）
- 进入到Centos7安装界面，点击`Install Linux Centos7`。进入到安装图形化界面，选择中文
- 设置安装位置(之前推荐设置的20G磁盘)。**设置网络和主机名，点击开启以太网**，可酌情修改主机名
    - 连接后显示`ens33已连接`，安装成功后使用`ip addr`查看ip地址也是看`ens33`那一栏
    - 使用`DVD ISO`可不关注
- 开始安装，安装期间设置Root密码(root)，创建用户(smalle/smalle)并设置为管理员

## 远程连接虚拟机

- `ip addr`查看虚拟机地址，`ipconfig`查看windows主机地址，并看能否双向`ping`通
- `systemctl status sshd` 查看ssh服务是否启动(如果未安装，可手动安装sshd)
- 使用`xshell`/`xftp`以ssh/sftp的方式连接，端口`22`，用户名要使用`smalle/smalle`（root连接失败）
