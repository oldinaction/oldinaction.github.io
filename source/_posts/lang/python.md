---
layout: "post"
title: "python"
date: "2017-04-28 11:39"
categories: [extend]
tags: [python]
---

## python简介

- python有两个版本python2(最新的为python2.7)和python3，两个大版本同时在维护
- Linux下默认有python环境

## python基础(易混淆/常用)


## 模块

1. 模块安装
    - 可在`/Scripts`和`/Lib/site-packages`中查看可执行文件和模块源码
2. 常用模块
    - `pip` 可用于安装管理python其他模块
        - 安装（windows默认已经安装）
            - 将`https://bootstrap.pypa.io/get-pip.py`中的内容保存到本地`get-pip.py`文件中
            - 上传`get-pip.py`至服务器，并设置为可执行
            - `python get-pip.py` 安装
            - 检查是否安装成功：`pip list` 可查看已经被管理的模块
        - 常见问题
            - 安装成功后，使用`pip list`仍然报错。windows执行`where pip`查看那些目录有pip程序，如strawberry(perl语言相关)目录也存在pip.exe，一种方法是将strawberry卸载
    - `fabric` 主要在python自动化运维中使用(能自动登录其他服务器进行各种操作)
        - `pip install fabric` 安装
        - 常见问题
            - 报错`fatal error: Python.h: No such file or directory`
                - 安装`yum install python-devel` 安装python-devel(或者`yum install python-devel3`)
            - 报错` fatal error: ffi.h: No such file or directory`
                - `yum install libffi libffi-devel` 安装libffi libffi-devel
    - `scrapy` 主要用在python爬虫。可以css的形式方便的获取html的节点数据
        - `pip install scrapy` 安装
        - 文档：[0.24-Zh](http://scrapy-chs.readthedocs.io/zh_CN/0.24/index.html)、[latest-En](https://doc.scrapy.org/en/latest/index.html)
