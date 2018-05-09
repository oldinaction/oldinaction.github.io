---
layout: "post"
title: "vmware"
date: "2017-06-24 11:19"
categories: [linux]
tags: [vmware, linux, centos]
---

## 虚拟机安装

- 下载安装VMware
- 下载centos7镜像文件 [https://www.centos.org/download/](https://www.centos.org/download/). `DVD ISO`安装包含有桌面系统，`Minimal ISO`是最小安装包，不含桌面系统
- 虚拟机的安装位置选择在较空闲的磁盘，也可使用移动硬盘
- 除了安装位置，其他使用默认配置，点击安装（下面以`Minimal ISO`为例）
- 进入到Centos7安装界面，点击`Install Linux Centos7`。进入到安装图形化界面，选择中文
- 设置安装位置(之前推荐设置的20G磁盘)。**设置网络和主机名，点击开启以太网**，可酌情修改主机名
    - 连接后显示`ens33已连接`，安装成功后使用`ip addr`查看ip地址也是看`ens33`那一栏
    - `ip addr`不显示ip：查看NAT是否连接，宿主机VMware相关的网络适配器是否启用，`/etc/sysconfig/network-scripts/ifcfg-ens33`中`ONBOOT=yes`(修改后，`systemctl restart network`重启)
    - 使用`DVD ISO`可不关注
- 开始安装，安装期间设置Root密码(root)，创建用户(smalle/smalle)并设置为管理员
- **开启windows下和VMware相关的两块虚拟网卡**
- **快照**：可对保留虚拟主机当前的配置状态
- **克隆虚拟主机**：基于某个虚拟主机进行克隆出一台主机。克隆后需要进行以下修改
    - `hostnamectl set-hostname aezocn` 修改主机名
    - `vi /etc/sysconfig/network-scripts/ifcfg-ens33`，修改`IPADDR`的值从而修改机器ip
    - vmware克隆时会自动改变mac地址，如果没有改变可在vmware控制台中重新生成一个mac地址：设置-网络适配器-高级-生成

## 远程连接虚拟机

- `ip addr`查看虚拟机地址(`ens33`/`eth0`)，`ipconfig`查看windows主机地址，并看能否双向`ping`通
- `systemctl status sshd` 查看ssh服务是否启动(如果未安装，可手动安装sshd)
- 使用`xshell`/`xftp`以ssh/sftp的方式连接，端口`22`，用户名要使用`smalle/smalle`（root连接失败）
