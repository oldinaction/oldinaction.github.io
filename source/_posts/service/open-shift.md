---
layout: "post"
title: "OpenShift空间"
date: "2016-04-16 15:37"
categories: [extend]
tags: [hosts]
---

## OpenShift空间介绍

> OpenShift空间是红帽RedHat旗下的，支持多种语言环境(如java、php、nodejs等)，每个注册用户可以免费创建3个应用，[进入官网](https://www.openshift.com/)

## 关于远程登录

### 安装 PuTTY 和 WinSCP

安装包下载见上面链接

### 设置密钥

- 打开 PuTTY 点击 Generate 按钮生成一个密钥
- 点击下面的 `save public key` 和 `save private key` 保存公钥和私钥到本地文件
- 登录 OpenShift 后台进入到 setting，在 public keys 处添加一个公钥。名字随便取，公钥内容为 Putty 最顶部生成的一大段代码

### 远程SSH登录(两种都可尝试一下)

- 在PuTTY上登录

  1. 打开PuTTY，点击Session
  2. Host Name填写OpenShift提供的ssh登录网址，如：`8888f31389f5cf0b1d0000ff@app-oldinaction.rhcloud.com`
  3. Saved Session 随便取名，再点击 Save
  5. 点击 Connection - SSH - Auth，再点击Browse，选择刚刚保存的私钥文件
  6. 点击Open进行登录
  7. 输入私钥文件密码即可登录，但是界面是命令行的

- 在WinSCP上登录

  1. 打开WinSCP新建会话
  2. 协议：SFTP，主机名：如app-oldinaction.rhcloud.com，端口：22，用户名：8888f31389f5cf0b1d0000ff
  3. 高级 - SSH - 验证 - 密钥文件：为刚刚保存的私钥文件
  4. 点击登录，输入私钥文件密码即可看到相应的目录

## 文件上传

我们的项目文件应该放在 `/var/lib/openshift/8888f31389f5cf0b1d0000ff/app-root/runtime/repo/` 下。

- 少量文件可以使用WinSCP上传，可见即可得
- 较大的文件压缩成zip
  - 将文件压缩成zip后利用 WinSCP 上传到 repo 目录下
  - 登录PuTTY(默认在8888f31389f5cf0b1d0000ff目录)，使用 cd 命令进入到 repo 目录下 (ls 查看目录文件)
  - 使用命令 `unzip XXX.zip` 解压文件 XXX.zip
  - 如果要移动位置，再使用 WinSCP 进行移动
- 在线文件上传：使用 `wget 文件下载地址(http://www.xxx.comg/XXX.zip)`
