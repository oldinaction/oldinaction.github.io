---
layout: "post"
title: "Rancher"
date: "2020-01-07 19:15"
categories: devops
tags: [k8s, docker, cncf]
---

## 简介

- [rancher](https://www.rancher.cn/) 对所有环境进行集成的. [github](https://github.com/rancher/rancher)、[中文文档](https://docs.rancher.cn/)
- [k3s](https://www.rancher.cn/k3s/) 适用于物联网/树莓派的轻量级Kubernetes版本

## 安装

- 简单安装

```bash
# v2.5.3 硬件要求：4GB内存、Centos 7.5
sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged docker.mirrors.ustc.edu.cn/rancher/rancher:v2.5.3
# 安装成功后访问：http://localhost 即可显示管理界面
```
