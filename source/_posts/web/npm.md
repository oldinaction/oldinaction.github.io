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
    - `npm install npm@latest -g` 更新npm
    - `npm -version` 查看npm版本
- 安装[cnpm](http://npm.taobao.org/)镜像(淘宝镜像下载较快)：`npm install -g cnpm --registry=https://registry.npm.taobao.org`
    - `cnpm install <module-name>` 安装模块

## 常用命令

### 基本命令 

```bash
## 安装xxx(在当前项目安装)，**更新模块也是此命令**
npm install <module-name>
# npm i <module-name> # 简写方式
# -g 全局安装。如果以Windows管理员运行的命令行，则会安装在nodejs安装目录的node_modules目录下。如果以普通用户运行的命令行，则会安装在用户的 AppData/Roaming/npm/node_modules 的目录下。建议以管理员运行
npm install <module-name> -g
# --save (简写`-S`) 自动将依赖更新到package.json文件的dependencies(依赖)中
# --save-dev(简写`-D`) 自动将依赖更新到package.json文件的devDependencies(运行时依赖)中
npm install <module-name> -S
npm install <module-name> -D

## 移除(全局依赖)
npm uninstall -g <module-name>

## 对于某个node项目
# 初始化项目，生成`package.json`
npm init
# 基于`package.json`安装依赖
# npm install
# npm install --registry=https://registry.npm.taobao.org
cnpm install
# 运行 package.json 中的 scripts 属性
npm run <xxx>
npm run dev # 常见的启动项目命令(具体run的命令名称根据package.json来)
npm run build # 常见的打包项目命令(具体run的命令名称根据package.json来)
```

### npm版本管理

- package.json版本

```json
{
  "name": "test",
  // 此项目版本
  "version": "1.0.0",
  // 依赖和对应版本
  "dependencies": {
      // 波浪符号（~）：固定大、中版本，只升级小版本到最新版本
      "vue": "~2.5.13",
      // 插入符号（^）：固定大版本，升级中、小版本到最新版本。当前npm安装包默认符号
      "iview": "^2.8.0",
  }
}
```

- 命令行修改版本号(执行命令会读取并修改package.json中的版本)

```bash
# major.minor.patch premajor/preminor/prepatch/prerelease

# version = v1.0.0
npm version patch # v1.0.1 # major.minor.patch 如果之前为稳定版，则会在对应位置+1，下级位置清空为0；如果之前为预发布版，则还会额外去掉预发布版标识
npm version minor # v1.1.0
npm version major # v2.0.0

npm version prepatch # v2.0.1-0 # 如果之前为稳定版，则会先按照 major.minor.patch 的规律 +1，再在版本末尾加上预发布标识`-0`
npm version preminor # v2.1.0-0
npm version premajor # v3.0.0-0
npm version premajor # v4.0.0-0 # 重复运行 premajor 则只增加 major.minor.patch，且 prepatch/preminor 同理
npm version prerelease # v4.0.0-1 # 如果没有预发布号，则增加预发布号为 `-0`；如果之前为预发布版本，则对预发布版 +1
npm version prerelease --preid=alpha # v4.0.0-alpha.0 (预发布推荐方式) # npm 6.4.0 之后，可以使用 --preid 参数，取值如：alpha/beta
npm version 1.0.0-alpha.1 # 1.0.0-alpha.1 # 直接指定版本

# version = v4.0.0-1
npm version minor # v4.0.0 # 如果有预发布版本，则将预发布版本去掉。且如果下级位置为0，则不升级中号；如果下级位置不为0，则升级中号，并将下级位置清空。major同理
# version = v4.0.1-1
npm version minor # v4.1.0
```


