---
layout: "post"
title: "thymeleaf"
date: "2017-10-22 11:41"
categories: [lang]
tags: [thymeleaf, java, springboot, template]
---

## 简介


## 页面布局

- layout.hmtl(如路径为：templates/includes/layout.hmtl)

    ```html
    <!DOCTYPE html>
    <html lang="zh-CN" xmlns:th="http://www.thymeleaf.org"
        xmlns:layout="http://www.ultraq.net.nz/web/thymeleaf/layout">

    <head>
        <meta charset="utf-8">
        <title>AEZO.CN</title>
    </head>

    <body>
        <div layout:fragment="content"></div>
    </body>
    </html>
    ```
- 引用

    ```hmtl
    <!DOCTYPE html>
    <html xmlns:th="http://www.thymeleaf.org"
        xmlns:layout="http://www.ultraq.net.nz/web/thymeleaf/layout"
        layout:decorator="includes/layout">

    <div layout:fragment="content">
        hello
    </div>
    </html>
    ```