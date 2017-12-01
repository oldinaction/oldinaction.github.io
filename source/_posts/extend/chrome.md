---
layout: "post"
title: "chrome"
date: "2017-09-13 12:56"
categories: [extend]
tags: [plugins, debug]
---

## chrome插件收集

- `Postman` Http请求客户端
- `JSONView` 将Http请求获取的json字符串格式化(可收缩)
- `Secure Shell` ssh客户端
- `Axure RP Extension for Chrome` Axure设计
- `Set Character Encoding` 解决chrome查看源码乱码问题
- `Vue.js devtools` Vue.js调试工具
- `AdBlock` 广告拦截
- `有道词典Chrome划词插件`
- `印象笔记·剪藏`
- `Infinity新标签页` 标签管理

- `Octo Mate` github单文件下载(也可右键github按钮raw另存为)

## 调试技巧

- `ctrl + shift + i`/`F12` 打开开发者工具
- 主面板介绍
    - `Elements` html文件显示，Css样式调试
    - `Console` js代码打印面板
    - `Sources` 静态文件(html、css、js、images等)
        -  `{}`/`Pretty Print`可对压缩文件进行格式化
    - `NetWork` 网络显示面板：记录所有请求加载(XHR/JS/CSS/Img等)
        - `Initiator` 可查看此执行此请求的运行栈(如：某按钮被点击 - 发起XHR请求)
        - 点击某个请求可查看请求头(Headers)、响应结果等
    - `Application` 查看网址的Cookies、Storage等
    - `更多按钮`
        - `Search all files` 基于此url地址请求的所有静态文件进行查询。多用于js函数搜索
- VM文件查看
    - VM文件是V8引擎计算出的临时代码，VM文件出现情况，如：（1）直接在console控制台运行js代码 （2）使用eval函数计算js代码(如果一些函数通过eval定义)（3）js添加的`<script>`标签产生的
    - 查看VM函数
        - `debugger` 相应代码。如某些函数通过eval定义，在调用此函数的地方debugger，运行到该行后，点击此行数就会出VM文件