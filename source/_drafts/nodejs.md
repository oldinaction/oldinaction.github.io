---
layout: "post"
title: "Nodejs"
date: "2020-04-19 01:18"
categories: lang
tags: [nodejs]
---

## 安装使用

### 安装

- [nodejs官网](https://nodejs.org/zh-cn/)
- centos

```bash
wget https://npm.taobao.org/mirrors/node/v10.23.0/node-v10.23.0-linux-x64.tar.gz
tar -zxvf node-v10.23.0-linux-x64.tar.gz -C /opt
ln -s /opt/node-v10.23.0-linux-x64/bin/node /usr/local/bin/
ln -s /opt/node-v10.23.0-linux-x64/bin/npm /usr/local/bin/
ln -s /opt/node-v10.23.0-linux-x64/bin/npx /usr/local/bin/
chown -R root:root /opt/node-v10.23.0-linux-x64 # 文件夹权限默认是500:500
node -v

# 提供node、npm可通过sudo执行
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/node /usr/bin/node
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/node /usr/lib/node
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/npm /usr/bin/npm
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/node-waf /usr/bin/node-waf
```

### 多版本管理

- 基于[nvm](https://github.com/coreybutler/nvm-windows)等工具实现node多版本管理
- [下载安装包](https://github.com/coreybutler/nvm-windows/releases/download/1.1.7/nvm-setup.zip)
- 安装前可先卸载之前的nodejs，安装时需要指定nvm和之后nodejs的安装目录
- 使用

```bash
nvm list # 查看已安装的版本
nvm install 12.16.3 # 安装指定版本node：8.17.0、10.20.1

nvm use 12.16.3 # 使用某版本(需要管理员运行)，实际是将该版本nodejs包释放到指定nodejs安装目录
node -v
```

## 常用依赖包

### PM2

- PM2是node进程管理工具，可以利用它来简化很多node应用管理的繁琐任务，如性能监控、自动重启、负载均衡等，而且使用非常简单
- 使用

```bash
# 全局安装
npm install -g pm2

pm2 -h # 查看帮助
pm2 l # 列举所有进程
```

## 零散

### 获取命令行参数

```bash
node arg.js arg1 arg2 arg3 # 执行命令
#  process是一个全局对象，argv返回的是一组包含命令行参数的数组
process.argv # ["D:\\software\\nodejs\\node.exe", "D:\\test\\arg.js", "arg1", "arg2", "arg3"]
var args = process.argv.splice(2) # ["arg1", "arg2", "arg3"]
```
