---
layout: "post"
title: "IntelliJ IDEA"
date: "2016-09-17 15:37"
categories: [extend, tools]
tags: [IDE]
---

* 目录
{:toc}

## IntelliJ IDEA简介

## 常用设置

### java web项目配置 [^1]

1. 进入到Project Structure：`File - Project Structure`
2. 配置步骤
    - `Project` 项目级别
        - 主要是project compiler output的位置(src的编译位置)：如`\myproject\WebRoot\WEB-INF\classes`，为对应WEB-INF下的classes目录
    - `Modules` 模块级别，项目可能包含多个模块，不同的模块可设置对应的编译输入路径和依赖。一般项目就一个模块
        - `Sources` 将src目录标记成Sources目录
        - `Paths` 使用modules compiler output path，设置路径为`\myproject\WebRoot\WEB-INF\classes`
        - `Dependencies` 加入jdk、tomcat、其他依赖jar(如`\WEB-INF\lib`中的jar)
    - `Libraries` 如将`\WEB-INF\lib`中的所有jar定义一个目录，直接加入到`Dependencies`中
    - `Facets`
        - 点击`+` - `web`
        - `Web Module Deployment Descriptor`为`\myproject\WebRoot\WEB-INF\web.xml`
        - `Web Resource`为`\myproject\WebRoot`
        - 勾选`Source Roots`
    - `Artifacts` 根据上面的配置，最终打包成一个war包部署到tomcat中
        - 点击`+` - `Web Application: Exploded` - `From Modules`
        - `Output directory`为`\testStruts2\WebRoot`
3. `Run configuration`配置tomcat
    - `JRE`填写jdk路径
    - `Deployment`中将刚刚的war配置进入
    - 在`Before launch`中加入Build这个war包

## IDEA开发PHP程序

### 安装php插件 [^2]

1. setting -> plugins -> browse repositories -> 输入php
2. 没看到的话，往下翻几页看看，找到PHP(LANGUAGES)，安装次数较多的那个

### xdebug使用

1. 找到php.ini，搜索xdebug
2. 下载xdebug的dll文件，并在php.ini中设置。wamp已经含有这个功能
3. 替换下面代码

    ```html
        [xdebug]  
        xdebug.remote_enable=on  
        xdebug.remote_host=localhost  
        xdebug.remote_port=9000  
        ;下面两项和Intellij idea里的对应  
        xdebug.idekey=idekey  
        xdebug.remote_handler=dbgp  
        xdebug.remote_mode=req  
        ;下面这句很关键，不设置intellij idea无法调试  
        xdebug.remote_autostart=1  
        ;调试配置，详细的可以参考phpinfo页面进行配置  
        xdebug.auto_trace=on  
        xdebug.collect_params=on  
        xdebug.collect_return=on  
        xdebug.trace_output_dir="../xdebug"  
        xdebug.profiler_enable=on  
        xdebug.profiler_enable_trigger = on
        xdebug.profiler_output_name = cachegrind.out.%t.%p
        xdebug.profiler_output_dir="../xdebug"  
        xdebug.collect_vars=on  
        xdebug.cli_color=on
    ```

4. 在idea中设置php的安装路径

    添加php interpreters指向php的主目录，点击这边的show info按钮，在Loaded extensions里应该可以看到xDebug

    ![php-xdebug](/data/images/2016/09/php-xdebug.png)

5. 启动xdebug调试
    - 点击intellij idea工具栏里的 start listen php debug connections.开启调试模式。
    - 点击工具栏里向下的小三角->edit configuration->add new configuartion->php web Application Server里选aezo.cn

    ![php-xdebug](/data/images/2016/09/php-xdebug2.png)

6. 打断点，运行程序即可进行调试










---

参考文章

[^1]: [java web项目配置](https://github.com/judasn/IntelliJ-IDEA-Tutorial/blob/newMaster/eclipse-java-web-project-introduce.md)
[^2]: [intellij idea12 搭建php开发环境](http://blog.csdn.net/ysjjovo/article/details/13292787)
