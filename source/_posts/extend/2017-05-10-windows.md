---
layout: "post"
title: "windows"
date: "2017-05-10 15:26"
categories: [extend]
tags: [, ]
---


### 常用命令

- 后台运行bat文件

    ```shell
    @echo off
    if "%1" == "h" goto begin
    mshta vbscript:createobject("wscript.shell").run("%~nx0 h",0)(window.close)&&exit
    :begin
    :: 此处运行脚本，如：java -jar my.jar
    ```

- `title`: 设置cmd窗口标题(乱码时，需要将文件记事本打开另保存为ANSI)
