---
layout: "post"
title: "firebase"
date: "2017-03-19 21:21"
categories: [service]
tags: [google]
---

## 简介

- Firebase是google提供的快速构件应用的云服务。简单的可以说通过引入Firebase，你可以通过api去构建实时性的应用。
- [官网](https://firebase.google.com/)

## Hello World

### Firebase帐号注册

- 可通过google账户登录，选择免费版，新建一个项目。
- 点击`Authentication` - `登录方法` - 启用Google登录
- 点击`overview` - `将 Firebase 添加到您的网页应用` - 复制代码供下面使用

### 下载web版示例

- [quickstart-js](https://github.com/firebase/quickstart-js)
- 该文件中包含了auth验证、database数据库、storage存储、messaging消息等示例
- 找到database/index.html，将上文复制的代码放到head中

### 为开发运行本地 Web 服务器

- 安装firebase命令行工具：`npm install -g firebase-tools`(重新运行安装命令，可更新此工具)
- cmd进入到下文的database文件夹
- 启动服务器 `firebase serve`
- 访问：`http://localhost:5000`
- 点击登录，就会自动调用google登录验证api
- 该示例登录进入可书写博文，数据可在控制面板的`Database`中查看

### 部署应用

最终可在控制面板的Hosting中查看
- 启动一个新的命令行，cmd进入到下文的database文件夹
- 登录Google并授权 `firebase login`
- 初始化应用 `firebase init`，运行后确认 - 选择Hosting - 选择创建的项目，创建根目录（默认会在此目录创建一个public的目作为根目录）
    - 运行 firebase init 命令会在您的项目的根目录下创建 firebase.json
    - 当您初始化应用时，系统将提示您指定用作公共根目录的目录（默认为"public"）。如果您的公共根目录下不存在有效的 index.html 文件，系统将为您创建一个。
    - 如一个firebase.json

    ```json
    {
      "hosting": {
        "public": "./",
        "rewrites": [
          {
            "source": "**",
            "destination": "/index.html"
          }
        ],
        "ignore": [
          "firebase.json",
          "**/.*",
          "**/node_modules/**",
          "functions"
        ]
      },
      "database": {
        "rules": "database.rules.json"
      }
    }
    ```

- 部署网站 `firebase deploy`
