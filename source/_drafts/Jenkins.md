---
layout: "post"
title: "Jenkins"
date: "2018-10-09 16:35"
categories: ops
tags: hook
---

## 运行环境

- 依赖jdk
- 安装：windows、linux、docker

## 功能

- 添加应用服务器
    - linux：密码/秘钥连接
    - windows：安装ssh server连接
- git服务器交互
    - 连接git服务器：密码/秘钥
    - 拉取项目到Jenkins工作目录
    - git提交后，通过git hook调用Jenkins服务
        - 根据某特定分支进行构建 **TODO**
        - 可检查git commit中的内容来判断是否需要构建发布 **TODO**
- 与应用服务器交互
    - 执行不同服务器命令：bat、sh
        - 执行成功发送邮件 **TODO**
        - 执行失败停止构建并发送邮件 **TODO**
- 工作流
    - 基于Jenkins项目运行工作流
    - 构建时按照一定顺序执行脚本
        - 依次调用不同服务器脚本
- 代码检查
    - 代码重复率等检查(sonal)
    - maven build
- 构建版本记录，类似git日志、

## 运行监控

## 文档中心



