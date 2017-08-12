---
layout: "post"
title: "gitlab"
date: "2016-11-20 10:39"
categories: [extend]
tags: [git]
---

## gitlab介绍

[gitlab官方文档](https://docs.gitlab.com/omnibus/README.html)。如[centos7安装](https://about.gitlab.com/downloads/#centos7)

### 常用命令

- 重新启动：`sudo gitlab-ctl restart`
- 重新配置：`sudo gitlab-ctl reconfigure`（运行中的项目，重新配置后，数据也不会丢失）

## 问题集锦

- 访问项目首页(如：http://114.55.888.888/)，结果页面不显示，地址栏的地址变成 http://gitlab/users/sign_in
    - 尝试方法：首先确保`/etc/gitlab/gitlab.rb`中的设置了`external_url`（如：`external_url "http://www.example.com"`），如果设置了，运行命令重新配置（`sudo gitlab-ctl reconfigure`，无需重启）。



-----------------------
