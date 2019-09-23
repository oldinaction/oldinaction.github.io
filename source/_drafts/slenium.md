---
layout: "post"
title: "Selenium"
date: "2019-04-30 14:29"
categories: extend
tags: test
---

## 简介

- selenium 是一个 web 的自动化测试工具，开源。支持多平台，支持Java、Python、Perl、PHP、C#等语言进行测试脚本编写。支持ie、chrome、firefox、opera、safari等浏览器，支持录制
- selenium包含selenium1(早期版本)、selenium2(selenium1与webdriver合并版)、selenium3(兼容selenium2，去掉selenium RC等不常用功能)
- selenium套件
    - 录制工具(可将录制转换成基础脚本，也可直接编写脚本)：selenium ide(官方插件，可到chrome插件中下载)、katalon recorder
    - Selenium Grid：能并行的运行测试，也就是说，不同的测试可以同时跑在不同的远程机器上
- [官方Doc](https://docs.seleniumhq.org/docs/)、[github](https://github.com/SeleniumHQ/selenium)

## 基于python编写测试脚本

### 安装

- 安装 `pip install -U selenium` (需要安装python3)
- 安装对应版本chromedriver(否则为selenium内置chrome)
    
    ```py
    # 查看chrome版本
    chrome://settings/help

    # 下载对应版本chromedriver，v2.33之前和chrome版本对照https://blog.csdn.net/morling05/article/details/81094151，
    https://npm.taobao.org/mirrors/chromedriver

    # 使用。参考：https://www.cnblogs.com/yhleng/p/9503819.html
    from selenium import webdriver
    # 此时自定义chrome驱动，则会自动启动系统chrome.exe，如果不行可设置chrome.exe到path
    driver = webdriver.Chrome(r'D:\software\greensoft\chromedriver.exe')
    # 使用selenium内置chrome.exe，selenium3内置chrome v50.0
    driver = webdriver.Chrome()
    ```

### 简单案例

- 不用启动Chrome浏览器，只需安装即可

```py
# coding = utf-8
from selenium import webdriver

driver = webdriver.Chrome()  # 当然也可以换成 Ie 或 Firefox
driver.get("http://www.baidu.com")
driver.find_element_by_id("kw").send_keys("selenium")
driver.find_element_by_id("su").click()
driver.quit()
```






