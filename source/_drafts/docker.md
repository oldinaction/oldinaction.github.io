---
layout: "post"
title: "docker"
date: "2017-06-25 14:03"
categories: arch
tags: [docker, centos]
---

## Docker介绍

- 支持Linux、Windows、Mac等系统
- 传统虚拟化(虚拟机)是在硬件层面实现虚拟化，需要额外的虚拟机管理应用和虚拟机操作系统层。Docker容器是在操作系统层面实现虚拟化，直接复用本地本机的操作系统，因此更加轻量级。
- Docker镜像存在版本和仓库的概念，类似Git。docker官方仓库为`Docker Hub`(https://hub.docker.com/)
- [官方文档](https://docs.docker.com)

## 安装

- Windows
    - 通过安装`DockerToolbox`，[安装文档和下载地址](https://docs.docker.com/toolbox/toolbox_install_windows/)
        - 安装完成后桌面快捷方式：`Docker Quickstart Terminal`、`kitematic`、`Oracle VM VirtualBox`
        - 运行`Docker Quickstart Terminal`，提示找不到`bash.exe`，可以浏览选择git中包含的bash(或者右键修改此快捷方式启动参数。目标：`"D:\software\Git\bin\bash.exe" --login -i "D:\software\Docker Toolbox\start.sh"`)。第一次启动较慢，启动成功会显示docker的图标
        - `kitematic`是docker推出的GUI工具(启动后，会后台运行docker)
        - `Oracle VM VirtualBox`其实是一个虚拟机，docker就运行在此虚拟机上（下载的docker镜像在虚拟硬盘上）；`Kitematic (Alpha)`为docker界面版管理工具
        - 如果DockerToolbox运行出错`Looks like something went wrong in step ´Checking status on default..`，可以单独更新安装`VirtualBox`
    - 或者安装[Boot2Docker](https://github.com/boot2docker/windows-installer)
- linux
    - `yum install docker` 安装

## 镜像

- `docker pull NAME[:TAG]` 拉取镜像。如：`docker pull ubuntu:latest`，省略TAG则默认为`latest`
    - `docker pull www.aezo.cn/smtools:latest` 从私有镜像站下载镜像
- `docker run -t -i nginx /bin/bash` 运行nginx镜像
- `docker images` 列出所有本地镜像
    - `docker inspect c28687f7c6c8` 获取某个image ID的详细信息
- `docker search mysql` 搜索远程仓库镜像
    - 查看某个Name的所有TAG：如centos访问`https://hub.docker.com/r/library/centos/tags/`查看

## 常用docker镜像

### centos镜像

- 官方提供的centos镜像，无netstat、sshd等服务
    - 安装netstat：`yum install net-tools`
    - 安装sshd：`yum install openssh-server`，启动如下：
        - `mkdir -p /var/run/sshd`
        - `/usr/sbin/sshd -D &`
