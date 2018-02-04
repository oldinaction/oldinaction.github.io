---
layout: "post"
title: "windows"
date: "2017-05-10 15:26"
categories: [extend]
tags: [bat]
---

## 语法

- 注释：`::`、`rem`等 [^1]
- `title`: 设置cmd窗口标题(乱码时，需要将文件记事本打开另保存为ANSI)

## 常用命令

- 运行java

    ```bat
    title=cmd窗口的标题
    echo off
    rem 我的注释：`%~d0`挂载项目到第一个驱动器，并设置当前目录为项目根目录
    %~d0
    set MY_PROJECT_HOME=%~p0
    cd %MY_PROJECT_HOME%
    echo on
    "%JAVA_HOME%\bin\java" -jar my.jar
    echo off
    ```

    - 此时配置文件应和jar包位于同一目录
    - 如果`set MY_PROJECT_HOME=%~p0..\`则表示设置bat文件所在目录的的上级目录为项目根目录
    - 如果不是系统默认jdk，可将`%JAVA_HOME%`换成对应的路径

- 后台运行bat文件

    ```bat
    @echo off
    if "%1" == "h" goto begin
    mshta vbscript:createobject("wscript.shell").run("%~nx0 h",0)(window.close)&&exit
    :begin
    :: 这是注释，后面运行脚本，如：
    java -jar my.jar
    ```
- 脚本示例
    - 进入到当前目录、设置环境变量
        - `%~dp0` %0代表批处理本身； ~dp是变量扩充， d扩充到分区，p扩充到路径
        
    ```bat
    rem 设置临时环境变量oracle_home为当前bat文件所在目录(%~dp0)下的Oracle64目录
    set oracle_home=%~dp0\Oracle64
    rem 进入到当前目录
    %~d0
    cd %~dp0
    rem 运行exe文件
    start plsqlDev.exe
    ```
        

---
[^1]: [注释](http://blog.csdn.net/wh_19910525/article/details/8125762)
