---
layout: "post"
title: "npm"
date: "2017-04-02 11:13"
categories: [extend]
tags: [node]
---

## npm介绍

## 安装

- 安装node的时候会默认包含npm
    - 更新：`npm install npm@latest -g`
- 安装[cnpm](http://npm.taobao.org/)镜像(淘宝镜像下载较快)：`npm install -g cnpm --registry=https://registry.npm.taobao.org`
    - 安装模块则是`cnpm install <module-name>`

## 常用命令

- `npm install <module-name>` 安装xxx(在当前项目安装)，**更新模块也是此命令**
    - `npm i <module-name>` 简写方式
    - `-g` 全局安装
        - 如果以Windows管理员运行的命令行，则会安装在nodejs安装目录的node_modules目录下。如果以普通用户运行的命令行，则会安装在用户的AppData/Roaming/npm/node_modules的目录下。建议以管理员运行
    - `--save`(简写`-S`) 自动将依赖更新到package.json文件的dependencies(依赖)中
    - `--save-dev`(简写`-D`) 自动将依赖更新到package.json文件的devDependencies(运行时依赖)中
- `npm init` 初始化项目，生成`package.json`
- `npm uninstall -g cross-env` 移除全局依赖
