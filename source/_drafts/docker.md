---
layout: "post"
title: "docker"
date: "2017-06-25 14:03"
categories: [clound]
tags: [docker, centos]
---

## Docker介绍

- 支持Linux、Windows、Mac等系统
- 传统虚拟化(虚拟机)是在硬件层面实现虚拟化，需要额外的虚拟机管理应用和虚拟机操作系统层。Docker容器是在操作系统层面实现虚拟化，直接复用本地本机的操作系统，因此更加轻量级。
- Docker镜像存在版本和仓库的概念，类似Git

## centos镜像

- 官方提供的centos镜像，无netstat、sshd等服务
    - 安装netstat：`yum install net-tools`
    - 安装sshd：`yum install openssh-server`，启动如下：
        - `mkdir -p /var/run/sshd`
        - `/usr/sbin/sshd -D &`
