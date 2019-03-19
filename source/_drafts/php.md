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
- windows + nginx + fastcgi运行php程序(php5.3版本之后已经有了`php-cgi.exe`的可执行程序，经测试本地开发就很容易挂)
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

> 未特殊说明，都是基于 php7

### 数据类型

```php
// ### map
// compact 创建一个包含变量与其值的数组
$meta_status = 'error';
$meta_message = '执行失败';
compact('meta_status', 'meta_message');

// ### json
$json = json_decode($json_str); // 格式化json字符串为对象。返回的是stdClass
if(isset($json -> username)) {
    // 判断 $json 对象中是否有username属性. ($json -> username == null)、(is_null(($json -> username))) 都会报错。特别当$json可能为空时
}
```

## thinkphp

> 未特殊说明，都是基于 ThinkPHP v5.0.24 进行记录

### 入门常见问题

- 入口文件默认是 `/public/index.php`，如果修改该成 `index.php` 可参考：https://www.kancloud.cn/manual/thinkphp5/125729
- 控制器及子目录访问
    - 访问`http://localhost/myproject/index.php`，由于thinkphp设置了默认模块/控制器/方法，因此等同于访问 `http://localhost/myproject/index.php/index/index/index.html`。访问的是`application/index/controller/Index.php`文件的`index`方法。原则`index.php/模块名/控制器/方法名`(默认不区分大小写)
    - 访问`http://localhost/myproject/index.php/wap/login.index/test.html`实际是访问的`application/wap/controller/login/Index.php`文件的`index`方法。此时`wap`为模块名，在`wap/controller`有文件`login/Index.php`为控制器(路径为login.index，注意Index.php中的命名空间`namespace app\wap\controller\login;`)，访问的此文件中的test方法
- 控制器的方法中，`return`只能返回字符串，如果需要返回对象或数组需要使用`return json($obj)`

## 易错点

- `$_POST`接受数据 [^1]
    - Coentent-Type仅在取值为`application/x-www-data-urlencoded`和`multipart/form-data`两种情况下，PHP才会将http请求数据包中相应的数据填入全局变量`$_POST`。（jquery会默认转换请求头）
    - Coentent-Type为`application/json`时，可以使用`$input = file_get_contents('php://input')`接受数据，再通过`json_decode($input, TRUE)`转换成json对象
    - 微信小程序wx.request的header设置成`application/x-www-data-urlencoded`时`$_POST`也接受失败(基础库版本1.5.0，仅供个人参考)，使用file_get_contents('php://input')可以获取成功

## 其他

### php测试

- 使用`apache`自带的`bin/ab.exe`工具
    - `ab.exe-n 10000 -c 100 http://localhost/index.php` 表示100个人访问该地址10000次
        - 如果并发调到500，则会提示`apr_socket_connect()` 原因是因为apache在windows下默认的最大并发访问量为150。我们可以设置conf\extra下的httpd-mpm.conf文件来修改它的最大并发数





---

参考文章

[^1]: [微信小程序$_POST无法接受参数](http://blog.csdn.net/qw_xingzhe/article/details/59693782)
