---
layout: "post"
title: "Yarn"
date: "2018-06-01 21:42"
categories: web
tags: nodejs
---

## 简介

- 官网：[https://yarnpkg.com/zh-Hans/](https://yarnpkg.com/zh-Hans/)
- 安装 `npm install -g yarn`，通过官网的`msi`容易报'yarn' 不是内部或外部命令，也不是可运行的程序
- 类似于`npm`，基于`package.json`进行包管理

## 使用

```bash
# 查看版本 
yarn --version

# 初始化新项目 (新建package.json)
yarn init 

# 添加依赖包
yarn add [package]
yarn add [package]@[version]
yarn add [package]@[tag]

# 将依赖项添加到不同依赖项类别，分别添加到 devDependencies、peerDependencies 和 optionalDependencies：
yarn add [package] --dev
yarn add [package] --peer
yarn add [package] --optional

# 升级依赖包
yarn upgrade [package]
yarn upgrade [package]@[version]
yarn upgrade [package]@[tag]

# 移除依赖包
yarn remove [package]

# 安装项目的全部依赖
yarn 或 yarn install

# 运行package.json里面的脚本
yarn run dev
```
