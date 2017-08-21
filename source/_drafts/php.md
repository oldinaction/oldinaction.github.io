---
layout: "post"
title: "php"
date: "2017-08-20 11:39"
categories: [extend]
tags: [php]
---

## php简介


## php基本语法

## php扩展

## 易错点

- `$_POST`接受数据 [^1]
    - Coentent-Type仅在取值为`application/x-www-data-urlencoded`和`multipart/form-data`两种情况下，PHP才会将http请求数据包中相应的数据填入全局变量`$_POST`。（jquery会默认转换请求头）
    - Coentent-Type为`application/json`时，可以使用`$input = file_get_contents('php://input')`接受数据，再通过`json_decode($input, TRUE)`转换成json对象
    - 微信小程序wx.request的header设置成`application/x-www-data-urlencoded`时`$_POST`也接受失败(基础库版本1.5.0，仅供个人参考)，使用file_get_contents('php://input')可以获取成功







---
[^1]: [微信小程序$_POST无法接受参数](http://blog.csdn.net/qw_xingzhe/article/details/59693782)
