---
layout: "post"
title: "php"
date: "2017-08-20 11:39"
categories: [extend]
tags: [php]
---

## php简介

- [官网](http://www.php.net/)、[官方文档](http://php.net/manual/zh/)

### 安装

- 可下载`xampp`集成包(包含apache/mysql/php等服务)
- php安装
    - windows：http://php.net/downloads.php
    - linux：`yum install -y php`
- windows + nginx + fastcgi运行php程序(php5.3版本之后已经有了`php-cgi.exe`的可执行程序，xampp中也包含)
    - nginx配置

        ```bash
        # php文件转给fastcgi处理。linux安装了php后需要额外安装如`php-fpm`来解析(windows安装了php，里面自带php-cgi.exe)
        # 如果访问 http://127.0.0.1:8080/myphp/index.php 此时会到 /project/phphome/myphp 目录寻找/访问 index.php 文件
        location ~ \.php$ {
            # 不存在访问资源是返回404，如果存在还是返回`File not found.`则说明配置有问题
            try_files      $uri = 404;
            root           /project/phphome/myphp;
            fastcgi_pass   127.0.0.1:19000;
            fastcgi_index  index.php;
            # 此处要使用`$document_root`否则报错File not found.`/`no input file specified`
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
        # 如果上述index.php中含有一个静态文件，此时需要加上对应静态文件的解析
        location ~ /myphp/ {
            root /project/phphome/myphp;
        }
        ```
    - 快捷操作脚本

        ```bat
        :: 启动脚本 start_php_cgi.bat(直接执行php-cgi.exe默认监听端口是9000)。此处使用`RunHiddenConsole.exe`需要加入到PATH，下载地址`http://redmine.lighttpd.net/attachments/download/660/RunHiddenConsole.zip`
        @echo off
        echo Starting PHP FastCGI...
        RunHiddenConsole.exe d:\software\xampp\php\php-cgi.exe -b 127.0.0.1:19000 -c d:\software\xampp\php\php.ini

        :: 停止脚本 stop_php_cgi.bat
        @echo off
        echo Stopping nginx...
        taskkill /F /IM nginx.exe > nul
        ```
- linux + nginx + fastcgi运行php程序
    - nginx配置同上
    - 需要安装`php-fpm`来实现fastcgi

## php基本语法

## php扩展

## 易错点

- `$_POST`接受数据 [^1]
    - Coentent-Type仅在取值为`application/x-www-data-urlencoded`和`multipart/form-data`两种情况下，PHP才会将http请求数据包中相应的数据填入全局变量`$_POST`。（jquery会默认转换请求头）
    - Coentent-Type为`application/json`时，可以使用`$input = file_get_contents('php://input')`接受数据，再通过`json_decode($input, TRUE)`转换成json对象
    - 微信小程序wx.request的header设置成`application/x-www-data-urlencoded`时`$_POST`也接受失败(基础库版本1.5.0，仅供个人参考)，使用file_get_contents('php://input')可以获取成功







---

参考文章

[^1]: [微信小程序$_POST无法接受参数](http://blog.csdn.net/qw_xingzhe/article/details/59693782)
