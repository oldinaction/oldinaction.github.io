---
layout: "post"
title: "Nginx"
date: "2017-01-16 16:54"
categories: arch
tags: LB, HA
---

## nginx介绍

- nginx("engine x") 是一个高性能的 HTTP 和 反向代理 服务器，也是一个 IMAP/POP3/SMTP 代理服务器
- 轻量级，同样起web服务，比`apache`占用更少的内存及资源，抗并发，nginx 处理请求是异步非阻塞的，而apache则是阻塞型的。最核心的区别在于apache是同步多进程模型，一个连接对应一个进程；nginx是异步的，多个连接（万级别）可以对应一个进程(nginx是多进程的)
- 作用：作为前端服务器拥有响应静态页面功能；作为集群构建者拥有反向代理功能
- 单个tomcat支持最高并发，测试结果：150人响应时间1s、**250人响应1.8s(理想情况下最大并发数)**、280人出现连接丢失、600人系统异常
- [Nginx中文文档](https://www.weixueyuan.net/nginx/)
- `Tengine`是nginx的加强版，封装版，淘宝开源
    - [官网](http://tengine.taobao.org/)
    - [中文文档](http://tengine.taobao.org/nginx_docs/cn/docs/)
    - [Nginx开发从入门到精通](http://tengine.taobao.org/book/)
- nginx日志分析goaccess: https://goaccess.io/ 对linux友好
- nginx在整体架构中的作用

    ![nginx-arch](/data/images/arch/nginx-arch.png)

## nginx安装

- 安装
    - `yum install -y nginx` 基于源安装(傻瓜式安装). **有的服务器可能需要先安装`yum install -y epel-release`**
        - 默认可执行文件路径`/usr/sbin/nginx`(已加入到系统服务); 配置文件路径`/etc/nginx/nginx.conf`
        - 安装时提示"No package nginx available."。问题原因：nginx位于第三方的yum源里面，而不在centos官方yum源里面，解决办法为安装epel(Extra Packages for Enterprise Linux)
            - 下载epel源 `wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm` (http://fedoraproject.org/wiki/EPEL)
            - 安装epel `rpm -ivh epel-release-latest-7.noarch.rpm`
            - 再下载 `yum install nginx`
    - 程序包解压安装
        - 安装多个版本的nginx(未测试): https://www.cnblogs.com/weibanggang/p/11487339.html
    - 卸载

        ```bash
        yum remove nginx
        rm -rf /etc/nginx
        rm -rf /var/log/nginx
        rm -rf /usr/share/nginx
        ```
- 编译安装: **(详细参考下文`基于编译安装tengine`)**

```bash
## 参考: https://blog.csdn.net/L66666xiaoliu/article/details/138197698
## 下载 [https://nginx.org/download/nginx-1.26.2.tar.gz](https://nginx.org/en/download.html)
# 解压
tar -zxvf nginx-1.26.2.tar.gz -C /opt
cd /opt/nginx-1.26.2
## 编译安装(之后添加模块可重新执行编译安装)
# 编译
./configure --prefix=/usr/local/nginx \
--group=nginx \
--user=nginx \
--sbin-path=/usr/local/nginx/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/usr/local/nginx/client_body_tmp \
--http-proxy-temp-path=/usr/local/nginx/proxy_tmp \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/lock/nginx \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_gzip_static_module \
--with-pcre \
--with-http_realip_module \
--with-stream
# 安装
make && make install

## 添加服务
cat > /usr/lib/systemd/system/nginx.service << EOF
[Unit]
Description=nginx
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf
ExecStop=/usr/local/nginx/sbin/nginx -s stop
ExecReload=/usr/local/nginx/sbin/nginx -s reload

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl status nginx
```

## nginx使用

- 查看nginx版本
    - `nginx -v` 简单查看
    - `nginx -V` **查看安装时的配置信息，包含模块信息**
    - `2>&1 nginx -V | tr ' '  '\n'` 查看安装时的配置信息并美化
- 启动
    - `systemctl start nginx` 启动
    - 进入到`nginx`执行文件目录，运行`sudo ./nginx`
- 停止
    - `systemctl stop nginx`
        - 有时候启动失败可能是端口占用，`listen`对应的端口必须是空闲状态
    - `sudo ./nginx -s stop`
    - windows停止脚本

        ```bat
        @echo off
        echo Stopping nginx...
        taskkill /F /IM nginx.exe > nul
        ```
- 相关命令
    - `ps -ef | grep nginx` 查看nginx安装位置(nginx的配置文件.conf在此目录下)
    - `sudo find / -name nginx.conf` 查看配置文件位置
    - **校验配置**：`/usr/sbin/nginx -t` 检查配置文件的配置是否合法(也会返回配置文件位置)，适用windows
    - **重载配置文件**： `/usr/sbin/nginx -s reload`，适用windows
    - 重启：`/usr/sbin/nginx -s restart` 有的配置文件改了必须重启
- nginx两种进程
    - master进程，root用户打开，接收信号，管理worker进程
    - worker进程，nginx用户打开，工作进程，负责处理http请求
- 日志分析


```bash
# 根据访问IP统计UV
awk '{print $1}'  access.log|sort | uniq -c |wc -l
# 根据访问URL统计PV
awk '{print $7}' access.log|wc -l
# 查询访问最频繁的URL
awk '{print $7}' access.log|sort | uniq -c |sort -n -k 1 -r|more
# 查询访问最频繁的IP
awk '{print $1}' access.log|sort | uniq -c |sort -n -k 1 -r|more

# 查找一段时间的日志（此处查询2020-12-03 02到2020-12-03 04的日志，此处使用*表示模糊查询）
# 注意
    # 1.开始时间和结束时间必须要是日志里面有的，否则查询不到结果
    # 2.只会包含一条2020-12-03 04之后的日志
cat access.log | sed -n '/03\/Dec\/2020:02*/,/03\/Dec\/2020:04*/p' | more
```

## nginx配置(nginx.conf)

- 查找配置文件 `sudo find / -name nginx.conf`

#### 常见问题

- 代理端口时，访问提示`Permission denied`。检查配置文件中启动用户是否为root(`user root;`)
- 代理端口时，**Header中数据丢失。nginx中默认不支持带`_`的key**
    - Header名不要带`_`
    - 解除nginx的限制：配置文件的http部分增加`underscores_in_headers on;`
- 参数调试

```bash
# 增加类似自定义响应头，通过观察响应信息进行调试
add_header X-debug-message "A static file was served" always;
add_header X-uri "$request_uri";
```

#### 配置示例

```bash
# 备案专用(直接映射nginx即可通过备案)
server {
    listen   80;
    server_name www.aezo.cn;
}

# http {} 模块下
server {
    # 监听的端口，注意要在服务器后台开启80端口外网访问权限
    # [Windows上80端口占用问题解决](/_posts/lang/C%23.md#IIS) Windows上80端口被占用一般为IIS
    listen   80;
    # 服务器的地址
    server_name www.aezo.cn;

    # #开启gzip压缩输出。**启用后响应头中会包含`Content-Encoding: gzip`；且chrome-network-size可以看到黑色的为传输大小，灰色的为实际大小，如果比黑色小则压缩生效**
    gzip on;
    # 压缩类型，默认就已经包含text/html(但是vue打包出来的js需要下列定义才会压缩)
    gzip_types text/plain application/x-javascript application/javascript text/javascript text/css application/xml text/xml;
    # Nginx的动态压缩是对每个请求先压缩再输出，这样造成虚拟机浪费了很多cpu，解决这个问题可以利用nginx模块Gzip Precompression，这个模块的作用是对于需要压缩的文件，直接读取已经压缩好的文件(文件名为加.gz)，而不是动态压缩，对于不支持gzip的请求则读取原文件（无 .gz 静态文件则在服务器动态压缩）。其优先级高于动态的gzip。可通过webapck插件 compression-webpack-plugin 提前将dist文件打包成 .gz 格式，从而减少服务器压缩
    gzip_static on;

    access_log /var/log/nginx/test.access.log main;

    # VUE类型应用
    # vue history简单配置，只需要root+index，无需location /
    root   /home/aezocn/www;
    index index.html;
    # 防止缓存index.html。此处的路径不一定要是index.html，只要某路径A返回的是index.html文件，则此处匹配A路径即可。且index.html中应用的js、css编译的文件名是hash过的，因此也不会缓存
    location = /index.html {
        root   /home/aezocn/www;
        expires -1s; # 对于不支持http1.1的浏览器，还是需要expires来控制
        add_header Cache-Control "no-cache, no-store"; # 会加在 response headers
    }
    # 所有*.html的文件均不缓存，但是其优先级低于 ^~ 的匹配方式
    location ~ .*.(htm|html)?$ {
		add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
		access_log on;
	}
    # 如vue子项目index.html缓存设置. 更多参考 [springboot-vue.md#多项目配置](/_posts/arch/springboot-vue.md#多项目配置)
    location = /demo1 {
        rewrite . http://$server_name/demo1/ break;
    }
    location ^~ /demo1/ {
        root   /home/www/demo1;
        # index  index.html index.htm;
        # 当请求 http://localhost/demo1/test 时，$uri 为 /demo1/test，注意/路径
        try_files $uri $uri/ /demo1/index.html;
        
        if ($request_filename ~* .*\.(?:htm|html)$) {
            add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
        }
        if ($request_filename ~* .*\.(?:js|css)$) {
            expires      7d;
        }
        if ($request_filename ~* .*\.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm)$) {
            expires      7d;
        }
    }

    # 当直接访问www.aezo.cn时, 重定向到 http://www.aezo.cn/hello (地址栏url会发生改变)。内部重定向使用proxy_pass
    location = / {
        rewrite / http://$server_name/hello break;
    }
    location = /proxy {
        # 返回 http://$server_name/hello 的数据
        proxy_pass http://$server_name/hello;
        break;
    }
    location / {
        # 跨域支持
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods *;
        add_header Access-Control-Allow-Headers *;
        if ($request_method = 'OPTIONS') {
            return 204;
        }

        # 尽管windows下支持\的路径，但是仍然尽量使用/的路径。因为如果路径带有\n和\t则会被转义导致报CreateFile错
        root   /home/aezocn/www;
        index  index.html index.htm;
    }

    ## root 和 alias 区别和联系
        # 都是用于暴露静态文件。均只能根据文件完整路径访问，无法通过目录列举文件(即无法访问目录)
        # alias只能位于location块中，而root的权限不限于location块中
        # 区别：root: 真实的路径是root指定的值加上location指定的值; alias: 真实路径都是 alias 指定的路径
        # 路径拼接区别：************alias文件路径为url路径减去location路径，root文件路径为直接拼接location路径************。具体见下文
        # 同级别的注意location顺序
    # === alias基于路径(^~，**推荐：vue代码和静态资源单独部署时**)。案例：文件实际路径为 /www/logo.png，需实现 http://www.aezo.cn/res/img/logo.png
    location ^~ /res/img/ {
        # ************基于alias指定目录 + (url路径 - location路径)************
        alias /www/;
    }
    # 和上面的区别是location和alias都不以/结尾，效果一样。location和alias要么都以/结尾，要么都不以/结尾
    location ^~ /res/img {
        alias /www;
    }
    # === alias基于正则(~)。案例：文件实际路径为 /www/xxx_upload/a/b.txt，需实现 http://www.aezo.cn/res/xxx_upload/a/b.txt 访问该文件
    location ~ ^/res/(.+?)_upload/(.+\..*)$ {
        # 此时$2指正则中的第二个括号，即文件名(a/b.txt)
        alias /www/$1_upload/$2;
    }
    # === root基于路径。案例：文件实际路径为 /www/res/img2/logo.png，需实现 http://www.aezo.cn/res/img2/logo.png 访问该文件
    location ^~ /res/img2/ { # ^~ /res/img2/ 和 /res/img2/ 效果差不多
        # ************基于root指定目录(加不加/都一样) + location路径************
        root /www; # windows路径分隔符可使用/或\(尽量少使用，容易出现\n等转义)，linux不能使用\
        access_log off; # 关闭访问日志
    }

    # 阿里云证书申请时服务器认证: http://exmaple.com/.well-known/pki-validation/fileauth.txt 可能需要重启nginx
    location /.well-known/pki-validation/ {
        root C:/software/nginx/cert/exmaple.com/;
        # alias C:/software/nginx/cert/exmaple.com/.well-known/pki-validation/;
    }

    # 测试地址
    location = /ping {
        add_header Content-Type text/plain;
        return 200 "Hello world!";  
    }

    # 当直接访问www.aezo.cn下的任何地址时，都会转发到http://127.0.0.1:8080下对应的地址(内部重定向，地址栏url不改变)。如http://www.aezo.cn/admin等，会转发到http://127.0.0.1:8080/admin
    # location后的地址可正则，如 `location ^~ /api/ {...}` 表示访问 http://www.aezo.cn/api/xxx 会转到 http://127.0.0.1:8080/api/xxx 上
    location / {
        # 还有如果存在302重定向的情况，反向代理需要增加Host头，否则客户浏览器地址会被重定向到被代理地址(此地址可能是内网导致访问失败)，参考下文proxy_redirect
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # proxy_redirect 该指令用来修改被代理服务器返回的响应头中的Location头域和“refresh”头域. 参考：https://blog.csdn.net/u011066470/article/details/118901373
        # proxy_redirect off;

        if (!-f $request_filename) {
            # proxy_pass http://127.0.0.1:8080/xxx; 会报错。proxy_pass在以下情况下，指令中不能有URI：正则表达式location、if块、命名的地点
            proxy_pass http://127.0.0.1:8080;
            break;
        }
        # if中不能使用URI，但是使用变量$request_uri(其值是以/开头)则可以
        if ($request_uri ~ "^/\w+\.xml$") {
            proxy_pass http://127.0.0.1:8080/xxx$request_uri;
            break;
        }

        #proxy_pass http://127.0.0.1/;
        #break;
    }

    ## proxy_pass详解
        # 访问 http://192.168.1.1/proxy/test.html 以下不同的配置代理结果不一致. （多站点配置参考下文）
        # 如果访问 http://192.168.1.1/proxy 则无法进入到下面代理，必须访问 http://192.168.1.1/proxy/
        # location /proxy/ 不能写成 location /proxy (此时 http://192.168.1.1/proxy/xxx 无法代理)
    # 第一种代理到URL：http://127.0.0.1/test.html
    location /proxy/ {
        proxy_pass http://127.0.0.1/;
        break;
    }
    # 第二种代理到URL：http://127.0.0.1/proxy/test.html
    location /proxy/ {
        # 后台api和前台暴露到同一域下常用方式
        proxy_pass http://127.0.0.1;
        break;
    }
    # 第三种代理到URL：http://127.0.0.1/pre/test.html
    location /proxy/ {
        proxy_pass http://127.0.0.1/pre/;
        break;
    }
    # 第四种代理到URL：http://127.0.0.1/pretest.html
    location /proxy/ {
        proxy_pass http://127.0.0.1/pre;
        break;
    }

    # http://s.aezo.cn 此固定短链接解析到小程序页面
    location = / {
        # aezo.cn的主页则走其他逻辑
        if ($host = 's.aezo.cn') {
            return 302 http://$server_name/api/mini;
        }
    }

    # 宝塔配置案例
    #PROXY-START/
    location ^~ / {
        proxy_pass http://www.baidu.com/; # 目标URL
        proxy_set_header Host www.baidu.com; # 发送域名
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header REMOTE-HOST $remote_addr;
        
        add_header X-Cache $upstream_cache_status;
        
        # # Set Nginx Cache
        # if ( $uri ~* "\.(gif|png|jpg|css|js|woff|woff2)$" ) {
        #     expires 12h;
        # }
        # proxy_ignore_headers Set-Cookie Cache-Control expires;
        # proxy_cache cache_one;
        # proxy_cache_key $host$uri$is_args$args;
        # proxy_cache_valid 200 304 301 302 1m;
    }
    #PROXY-END/
}
```

#### 配置详细说明

```bash
# ***.定义Nginx访问资源的用户和用户组.
# 一般是定义成www，然后nginx通过root用户启动(保存的日志都是root权限的)
# 此处定义的www用户只是表示nging去访问server.root项目中的代码文件时是通过www这个用户去读取
# 因此www用户必须要有权限读取到对应项目目录，项目父目录无所谓。如设置为`chown -R www:www my_project`
user www www; # 默认是nginx用户
# 如果一直出现403 forbidden (13: Permission denied)错误可将此处设置成root来进行测试
# user root;

#Nginx进程数，建议设置为等于CPU总核心数。
worker_processes 8; #（*）

# 全局错误日志定义类型，[ debug | info | notice | warn | error | crit ]。默认日志路径为/var/log/nginx
#error_log /var/log/nginx/error.log info; # 默认值。`error_log off;` 表示关闭error日志

#进程文件
pid /run/nginx.pid;

# 一个nginx进程打开的最多文件描述符数目，理论值应该是最多打开文件数（系统的值ulimit -n）与nginx进程数相除，但是nginx分配请求并不均匀，所以建议与ulimit -n的值保持一致。
#worker_rlimit_nofile 65535;

# 导入其他配置文件
# include /usr/share/nginx/modules/*.conf;

#工作模式与连接数上限
events {
    # 参考事件模型，use [ kqueue | rtsig | epoll | /dev/poll | select | poll ]; epoll模型是Linux 2.6以上版本内核中的高性能网络I/O模型，如果跑在FreeBSD上面，就用kqueue模型。
    #use epoll;
    
    #单个进程最大连接数（最大并发数/连接数 = 单个进程最大连接数 * 进程数）
    worker_connections 65535; #（*）

    # accept_mutex的意义：当一个新连接到达时，如果accept_mutex=on，那么多个Worker将以串行方式来处理，其中有一个Worker会被唤醒，其他的Worker继续保持休眠状态；如果accept_mutex=off，那么所有的Worker都会被唤醒，不过只有一个Worker能获取新连接，其它的Worker会重新进入休眠状态，这就是「惊群问题」
    # 默认是on(接受互斥)。对Nginx而言，一般来说， worker_processes 会设置成CPU个数，所以最多也就几十个，即便发生惊群问题的话，影响相对也较小(Apache动辄就会启动成百上千的进程，如果发生惊群问题的话，影响相对较大)。如果网站访问量比较大，为了系统的吞吐量，可关闭accept_mutex
    accept_mutex off;
}

# load modules compiled as Dynamic Shared Object (DSO)
#
#dso {
#    load ngx_http_fastcgi_module.so; 
#    load ngx_http_rewrite_module.so; # 加载重写模块
#}

## **代理TCP/UDP协议**。如：oracle数据库映射外网、sshd转换、ws转换
stream {
    # 进行oracle数据映射。不能使用http模块转换，否则连接时报错ORA-12569包解析出错
    upstream oracledb {
       hash $remote_addr consistent;
       # oracle数据内网ip（此处还可以通过VPN拨号到此nginx服务器，然后此处填写VPN拨号后的内网ip也可以进行访问）
       server 192.168.0.201:1521;
    }
    server {
        #公网机器监听端口，连接oracle的tns中填公网ip和端口即可
        listen 1521;
        proxy_pass oracledb;

        # 也支持socket
        # proxy_pass unix:/var/lib/mysql/mysql.socket;

        # 对公网传输的数据进行加密(未测试成功). [内部证书生成参考](/_posts/linux/加密解密.md#证书生成示例)
        # proxy_ssl  on;
        # proxy_ssl_certificate     /etc/ssl/certs/backend.crt;
        # proxy_ssl_certificate_key /etc/ssl/certs/backend.key;
    }

    # 进行sshd转换(局域网某台机器的虚拟上安装了Linux，暴露这些虚拟机给局域网)，每暴露一台需要监听一个端口
    upstream sshd128 {
	    server 192.168.112.128:22;
    }
    server {
        listen 22128;
        proxy_pass sshd128;
    }

    # upstream负载均衡，自动剔除宕机节点
    # https://blog.csdn.net/zsycsnd/article/details/81436759、https://blog.csdn.net/wy0123/article/details/88551915、https://blog.csdn.net/lxb15959168136/article/details/53113996/
}

## **代理HTTP协议**。如：springmvc应用
# 设定http服务(也支持smtp邮件服务)。全局只能有一个http节点
http {
    include mime.types; #文件扩展名与文件类型映射表(对应当前目录下文件mime.types)
    default_type application/octet-stream; #默认文件类型
    
    # 定义日志格式，log_forma上下文只能为http。main为默认日志格式名称(可定义多个)。$remote_addr等都是nginx内置变量，值为空时默认用`-`代替。可以定义多个log_format
    # 参考：http://tengine.taobao.org/nginx_docs/cn/docs/http/ngx_http_log_module.html
    # 内置变量参考：http://tengine.taobao.org/nginx_docs/cn/docs/http/ngx_http_core_module.html#variables
    
    ## ======== main日志样例 START (后面3条http_user_agent明细不是浏览器的情况，一般为爬虫或者攻击者)
    # 222.61.14.125 - - [31/Oct/2020:11:50:18 +0800] "GET /favicon.ico HTTP/1.1" 404 0 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3314.0 Safari/537.36 SE 2.X MetaSr 1.0" "-"
    # 222.61.14.125 - - [31/Oct/2020:11:56:29 +0800] "POST /demo/test HTTP/1.1" 200 10 "https://example.com/demo/index" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" "-"
    # 180.159.47.17 - - [31/Oct/2020:12:00:33 +0800] "POST /demo/test HTTP/1.1" 200 287 "-" "python-requests/2.32.3" "-"
    # 128.14.129.10 - - [31/Oct/2020:11:50:01 +0800] "POST /demo/test HTTP/1.1" 404 0 "-" "Custom-AsyncHttpClient" "-"
    # 128.14.129.10 - - [31/Oct/2020:11:50:01 +0800] "POST /demo/test HTTP/1.1" 404 0 "-" "-" "-"
    ## ======== main日志样例 EDN
    
    # log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                   '$status $body_bytes_sent "$http_referer" '
    #                   '"$http_user_agent" "$http_x_forwarded_for"';

    #log_format aezocn '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for" '
    #                  '$upstream_addr $request_time $upstream_response_time';

    # 默认配置。使用main格式进行输出访问日志
    # access_log  /var/log/nginx/access.log  main;
    # ***按照天对access.log进行分割***(否则时间长了日志文件会很大)
    # map只能定义在http模块中
    map $time_iso8601 $logdate {
		'~^(?<ymd>\d{4}-\d{2}-\d{2})' $ymd;
		default                       'date-not-found';
	}
	access_log logs/access-$logdate.log main; # 需将上述log_format  main开启
    
    #charset utf-8; #默认编码
    #server_names_hash_bucket_size 128; #服务器名字的hash表大小
    client_header_buffer_size 10m; #上传文件大小限制（必须设置在http模块）
    #large_client_header_buffers 4 64k; #设定请求头大小
    #client_max_body_size 8m; #允许客户端请求的最大单文件字节数
    # 开启高效文件传输模式，sendfile指令指定nginx是否调用sendfile函数来输出文件，对于普通应用设为 on，如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。注意：如果图片显示不正常把这个改 成off。
    sendfile on;
    #autoindex on; #开启目录列表访问，合适下载服务器，默认关闭。
    #tcp_nopush on; #防止网络阻塞
    #tcp_nodelay on; #防止网络阻塞
    keepalive_timeout 60; #长连接超时时间，单位是秒

    # 防止域名太长报错。nginx: [emerg] could not build server_names_hash, you should increase server_nam
    server_names_hash_bucket_size 64; # 上升值
    # server_names_hash_max_size # 域名长度总和

    #FastCGI相关参数是为了改善网站的性能：减少资源占用，提高访问速度。
    #fastcgi_connect_timeout 300;
    #fastcgi_send_timeout 300;
    #fastcgi_read_timeout 300;
    #fastcgi_buffer_size 64k;
    #fastcgi_buffers 4 64k;
    #fastcgi_busy_buffers_size 128k;
    #fastcgi_temp_file_write_size 128k;

    ##gzip模块设置(http://nginx.org/en/docs/http/ngx_http_gzip_module.html)
    # **启用后响应头中会包含`Content-Encoding: gzip`**
    gzip on; #开启gzip压缩输出
    # 压缩类型，默认就已经包含text/html(但是vue打包出来的js需要下列定义才会压缩)
    gzip_types
        application/atom+xml
        application/x-javascript
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/xml
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/javascript
        application/octet-stream
        text/x-cross-domain-policy;
    #gzip_min_length 1k; #最小压缩文件大小
    #gzip_buffers 4 16k; #压缩缓冲区
    ##gzip_http_version 1.0; #压缩版本（默认1.1，前端如果是squid2.5请使用1.0）
    #gzip_comp_level 4; #压缩等级[1-9] 越高CPU占用越大
    #gzip_vary on;
    #gzip_disable "MSIE [1-6]\."; # IE6以下不启用

    #开启限制IP连接数的时候需要使用
    #limit_zone crawler $binary_remote_addr 10m;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    upstream backend {
        #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大，可以省略。
        server 192.168.80.121:80 weight=3;
        server 192.168.80.122:80 weight=2;
        server 192.168.80.123:80 weight=3;
    }

    # 禁止通过IP访问80端口(将此server写在最上面即可)
    server {
        listen   80;
		listen 443 ssl;
		server_name example.com;
		
		ssl_certificate C:/example.com.pem;
		ssl_certificate_key C:/example.com.key;
		
		return 403;
	}

    # 强制跳转HTTPS, 参考: https://www.cnblogs.com/willLin/p/11928382.html. 此时80端口和443端口分开监听
    server {
        listen 80;
        #填写绑定证书的域名
        server_name www.xxx.com;

        #（第一种）把http的域名请求转成https
        return 301 https://$host$request_uri;
        #（第二种）强制将http的URL重写成https
        rewrite ^(.*) https://$server_name$1 permanent;

        # 如果在一个server中同时监听了两个端口，则需要判断
        listen 443;
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }
    }

    # 开启多个站点监听(花生壳指向 127.0.0.1:80 根据域名转发)
    server {
        listen 80;
        server_name hello.aezo.cn;
        
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        # 打印日志
        add_header X-debug-message "hello world" always;
        add_header X-debug-uri "$request_uri";

        # location = / {...} 和 location / {...} 联合使用，可以达到访问 hello.aezo.cn/xxx/ 转到 /pc/xxx/。而访问 test.aezo.cn/xxx/ 可同理转到如 /test/xxx/
        location = / {
            #判断是否为手机移动端
            if ($http_user_agent ~* '(iPhone|ipod|iPad|Android|Windows Phone|Mobile|Nokia)') {
                rewrite . http://$server_name/wap/ break;
            }
            # proxy_pass http://127.0.0.1:8090/pc/;
            rewrite . http://$server_name/pc/ break;
        }
        location / {
            # 如果无此if则出现如下问题：访问 hello.aezo.cn/index.php 则无法转发到 127.0.0.1:8090/pc/index.php（实际是转到 127.0.0.1:8090/index.php）
            if ($request_uri !~ "^/pc/") { # 不是以pc开头的转发到 /pc/，其他(已pc开头)的通过下面转发到本身的路径(/pc/xxx)
				proxy_pass http://127.0.0.1:8090/pc$request_uri;
				break;
			}
            proxy_pass http://127.0.0.1:8090;
        }
    }

    #虚拟主机的配置（可配置多个server，每个server为一个虚拟主机）
    server {
        #监听端口
        listen 80;
        #域名可以有多个，用空格隔开
        server_name www.aezo.cn aezo.cn;
        # 默认主页
        #index index.html index.htm index.php;
        #root /data/www/aezo;

        #定义本虚拟主机的访问日志，是main格式进行记录
        #access_log /var/log/nginx/aezo.cn.access.log main; # `access_log off;` 表示关闭http访问日志

        # include /etc/nginx/default.d/*.conf;

        #对 "/" 启用反向代理
        location / {
            proxy_pass http://127.0.0.1:88;
            proxy_redirect off;
            
            # 有些服务设置了Host检查；还有如果存在302重定向的情况，反向代理需要增加Host头，否则客户浏览器地址会被重定向到被代理地址(此地址可能是内网导致访问失败)
            proxy_set_header Host $host;
            #后端的Web服务器可以通过X-Real-IP获取用户真实IP
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            # 后端服务器超时时间(默认60s)
            proxy_connect_timeout 180; #nginx跟后端服务器连接超时时间(代理连接超时)
            proxy_send_timeout 180; #后端服务器数据回传时间(代理发送超时)
            proxy_read_timeout 180; #连接成功后，后端服务器响应时间(代理接收超时)
            ## 其他配置
            #client_max_body_size 10m; #允许客户端请求的最大单文件字节数
            #client_body_buffer_size 128k; #缓冲区代理缓冲用户端请求的最大字节数
            #proxy_buffer_size 4k; #设置代理服务器（nginx）保存用户头信息的缓冲区大小
            #proxy_buffers 4 32k; #proxy_buffers缓冲区，网页平均在32k以下的设置
            #proxy_busy_buffers_size 64k; #高负荷下缓冲大小（proxy_buffers*2）
            #proxy_temp_file_write_size 64k; #设定缓存文件夹大小，大于这个值，将从upstream服务器传
        }

        # 伪静态：用户访问 http://aezo.cn/post1.html，实际访问的是 http://aezo.cn/index.php?p=1
        location / {
            root   D:/wamp/www/aezo;
            index  index.php index.html index.htm;
            # try_files $uri $uri/ /index.php?$args;
            # 重定向：第一个参数路径匹配成功后跳转到第二个参数路径
            # 第3个参数为. last: 继续向下匹配规则; break: 停止向下匹配; redirect: 返回302临时重定向; permanent: 返回301永久重定向
            rewrite ^(.*)/post(\d+)\.html$ $1/index.php?p=$2 last;
        }
        # 临时将网站地址全部重定向二维码图片连接地址(重定向后地址栏路径会改变)
        location / {
            rewrite .* https://example.com/qrcode.jpg redirect;
        }

        #本地动静分离反向代理配置
        #所有jsp的页面均交由tomcat处理
        location ~ .(jsp|jspx|do)?$ {
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://127.0.0.1:8080;
        }
        #所有静态文件由nginx直接读取不经过tomcat(nginx读取不到也不访问tomcat)
        location ~ .*.(htm|html|gif|jpg|jpeg|png|bmp|swf|ioc|rar|zip|txt|flv|mid|doc|ppt|pdf|xls|mp3|wma)$ {
            # 图片过期时间设置
            expires 15d;
        }
        location ~ .*.(js|css)?$ { 
            if (-f $request_filename) {
                expires 1h; 
                break;
            }
        }

        # 自定义变量. 不能用于server_name及root等属性值
        location /myvar {
            set $foo hello;
            echo "foo: $foo";
        }

        #设定查看Nginx状态的地址
        location /nginxStatus {
            stub_status on;
            access_log on;

            # satisfy指令主要在有多个访问控制机制（如访问权限限制和身份验证）时使用
            # any(满足一个) | all(满足所有)
            satisfy any;

            # 通过白名单访问
			allow 192.168.1.0/24;
			allow 127.0.0.1;
			deny  all;

            # 通过基本身份验证访问
            # .htpasswd 文件的内容可以用apache提供的htpasswd工具来产生 (windows和linux生成的密码不通用)
            # Linux安装: yum install httpd-tools -y
            # Linux生成admin账号密码(回车后会要求输入密码): htpasswd -c -d /etc/nginx/.htpasswd admin
            # Windows安装: 下载Apache, 如: https://de.apachehaus.com/downloads/httpd-2.4.55-o111s-x64-vs17.zip
            # Windows生成admin账号密码: htpasswd.exe -bc htpasswd.db <user> <pwd>
            # 登录：浏览器会弹出登录框
            # 或 wget --http-user=admin --http-passwd=123456 http://example.com/test 或 curl -u admin:123456 -O http://example.com/test
            auth_basic "Restricted Access"; # 提示语(Chrome登录弹框不会显示，在响应头里面)
            auth_basic_user_file /etc/nginx/.htpasswd;
        }

        # 防盗链
        location ~* \.(gif|jpg|jpeg|png|bmp|swf)$ {
            valid_referers none blocked www.aezo.cn blog.aezo.cn;
            if ($invalid_referer) {
                rewrite ^/ http://$host/logo.png;
            }
        }
        
        ## php配置参考[php.md#安装](/_posts/lang/php.md#安装)
    }
}
```

#### HTTPS证书配置

- 检查证书配置: https://www.myssl.cn/tools/check-server-cert.html
    - 需要全部通过，一般为三项: 服务器证书、中间证书、根证书
    - 如果提示`错误： 服务器缺少中间证书`，解决如下
        - 使用完整的证书`fullchain.pem`
        - 如果中间证书(ca_bundle.crt)和网站证书(test.aezo.cn.crt)分开了，则可手动将两个.crt证书合并成一个文件，并配置到nginx。如果有多个中间证书也都合并到一起
        - apache也可尝试通过SSLCertficateChianFile来配置中间证书
    - 如果只配置服务器证书，漏掉中间证书，浏览器一般会通过，但是微信小程序无法正常使用
- 证书分析工具(测试连接): https://www.ssllabs.com/ssltest/index.html

```bash
# 开启 HTTPS
server {
    # 一定需要对外开放443端口
    # listen 80;
    listen 443 ssl;
    server_name test.aezo.cn;

    # 使用完整证书(服务器证书+中间证书合并)
    ssl_certificate /etc/letsencrypt/live/test.aezo.cn/fullchain.pem; # 对应阿里证书*.pem(CERTIFICATE)
    ssl_certificate_key /etc/letsencrypt/live/test.aezo.cn/privkey.pem; # 对应阿里证书*.key(PRIVATE KEY)
    # 可选。参考：https://www.cnblogs.com/linuxshare/p/16521904.html
    # 设置支持的TLS协议，默认(建议只)支持TSLv1.2以上
    # ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    # ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE:!3DES;

    root /home/www;
    index  index.html index.htm;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # 如果需要支持WSS协议则需加上，还需定义下面两个变量map，参考下文
        # proxy_set_header Upgrade $http_upgrade;
        # proxy_set_header Connection $connection_upgrade;
	}
}
# 将 HTTP 强制重定向到 HTTPS
server {
    listen 80;
    server_name test.aezo.cn;

    return 301 https://$host$request_uri;
}
```

#### WSS协议配置(加密WebSocket)

- WS/WSS测试工具：http://wstool.js.org/

```bash
# WSS配置
map $http_upgrade $connection_upgrade { 
	default upgrade; 
	'' close; 
}

server {
    location / {
        # HTTPS配置（WSS配置是基于WS+HTTPS实现的）
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # WSS配置
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
	}
}
```

#### Nginx访问日志过大自动清理

- 参考上文自动分割方案
- 自动清理方案https://www.chinastor.com/nginx/11143LK2017.html

#### 更安全的配置

```bash
http {
    ## http响应头不显示nginx版本(隐藏版本)，但还是会显示“nginx”(去掉此文字相对麻烦)
    server_tokens  off;

    ## 开启 HTTPS
    # 将 HTTP 强制重定向到 HTTPS
    server {
        listen 80;
        server_name test.aezo.cn;

        ## 防爬(防攻击)
        if ($http_user_agent ~* (python|HttpClient)) {
            return 403;
        }
        if ($http_user_agent = "-") {
            return 403;
        }

        return 301 https://$host$request_uri;
    }
    server {
        listen 443 ssl;
        server_name test.aezo.cn;

        # 参考：https://www.cnblogs.com/linuxshare/p/16521904.html
        # 使用完整证书(服务器证书+中间证书合并)
        ssl_certificate /etc/letsencrypt/live/test.aezo.cn/fullchain.pem; # 对应阿里证书*.pem(CERTIFICATE)
        ssl_certificate_key /etc/letsencrypt/live/test.aezo.cn/privkey.pem; # 对应阿里证书*.key(PRIVATE KEY)
        # 支持开启TLSv1.2协议
        ssl_protocols TLSv1.2;
        # 禁用3DES等脆弱算法. cve: SSL/TLS协议信息泄露漏洞CVE-2016-2183
        ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4:!3DES;
        ssl_session_timeout 10m;
        ssl_session_cache shared:SSL:1m;
        ssl_prefer_server_ciphers on;

        root /home/www;
        index  index.html index.htm;

        add_header Access-Control-Allow-Methods POST,GET,HEAD;
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        # 内容安全策略 (CSP) 是一个额外的安全层，用于检测并削弱某些特定类型的攻击，包括跨站脚本 (XSS (en-US)) 和数据注入攻击等
        # 类似可以在html的头中加 <meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests"> 此时就算页面的请求路径为http,静态资源也会改成https发起请求
        add_header Content-Security-Policy "script-src * 'unsafe-inline' 'unsafe-eval'";
        #（通常简称为 HSTS）响应标头用来通知浏览器应该只通过 HTTPS 访问该站点，并且以后使用 HTTP 访问该站点的所有尝试都应自动转换为 HTTPS
        # max-age=<expire-time>: 设置在浏览器收到这个请求后的<expire-time>秒的时间内凡是访问这个域名下的请求都使用 HTTPS 请求。
        # includeSubDomains: 如果这个可选的参数被指定，那么说明此规则也适用于该网站的所有子域名
        # preload: 查看 预加载 HSTS 获得详情。不是标准的一部分
        add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
        # 用于指定IE 8以上版本的用户不打开文件而直接保存文件
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment= ()";
        # 是否发送 Referrer 信息. https://blog.csdn.net/m0_54434140/article/details/125517407
        add_header Referrer-Policy "origin";

        # 只开启部分协议
        if ($request_method !~* GET|POST|HEAD) {
            return 403;
        }

        # cve: 静止访问文件后缀
        location ~ \.(txt|md|git|svn|env|ini|htaccess|conf|project)$ {
            deny all;
        }

        location / {
            proxy_pass http://127.0.0.1:8080;
            # 用于传递用户真实IP
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    ## cve: Http头Hostname攻击
    server {
        listen 443 ssl http2 default_server; # default_server 对于没有找到server_name的请求默认进入到此server
        server_name _; # _ 也可写成 __ 等，相当于localhost
        ssl on;
        ssl_certificate "/etc/nginx/my_nginx.cer";
        ssl_certificate_key "/etc/nginx/my_nginx.pem";
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout 10m;
        ssl_ciphers HIGH:!aNULL:!MD5:!3DES;
        ssl_protocols TLSv1.2;
        ssl_prefer_server_ciphers on;

        location / {
            return 403;
        }
    }
}
```

## 语法说明

### server_name和listen

- 多个server_name
    - `server_name www.aezo.cn baidu.com;`
    - 正则`server_name ~^.+-api-dev\.aezo\.cn$;` 匹配`xxx-api-dev.aezo.cn`
- nginx支持三种类型的虚拟主机配置
    - 基于域名的虚拟主机(server_name不同；listen相同，如80)
    - 基于端口的虚拟主机(server_name相同；listen不同)
    - 基于ip的虚拟主机(如listen 192.168.6.131:80; server_name 192.168.1.1/www.aezo.cn)

### location匹配规则

- 语法规则： `location [=|^~|~|~*|!~|!~*] /uri/ { … }` [^1] [^2]
    - `=` 表示精确匹配
    - `^~` 表示uri以某个常规字符串开头，理解为匹配url路径即可（如果路径匹配那么不测试正则表达式）
        - nginx不对url做编码，因此请求为`/res/20%/aa`，可以被规则`^~ /res/ /aa`匹配到（注意是空格）
    - 正则匹配
        - `~` 区分大小写的正则匹配
        - `~*` 不区分大小写的正则匹配
        - `!~` 区分大小写不匹配的正则
        - `!~*` 不区分大小写不匹配的正则
        - location的正则仅匹配路径，不考虑url中的参数(相当于把?后的参数去掉后进行匹配)
    - `/` 通用匹配，任何请求都会匹配到
- **多个location配置的情况下匹配顺序如下**，当有匹配成功时候，停止匹配，按当前匹配规则处理请求
    - 首先匹配路径相等 `=`
    - 其次匹配路径开头 `^~`
        - `location /test/`等同于`location ^~ /test/`
        - `location ^~ /test/`和`location ~ ^/test/`为不同优先级的location
    - 再是按文件中location的顺序进行正则匹配
    - 最后是交给 / 通用匹配
- 正则表达式

```bash
* #重复前面的字符0次或者多次
? #重复前面的字符0次或者1次
*? #重复前面的字符0次或者多次，但尽可能少重复
+? #重复前面的字符1次或者多次，但尽可能少重复
?? #重复前面的字符0次或1次，但尽可能少重复
{n,m}? #重复前面的字符n次到m次，但尽可能少重复
{n,}? #重复前面的字符n次以上，但尽可能少重复
[^a] #匹配除了a以外的任意字符
[^abc] #匹配除了abc这几个字母以外的任意字符
```

### 全局变量

- Nginx 获取自定义请求header头和URL参数：https://blog.csdn.net/JineD/article/details/125434338
    - 如使用`$http_x_test`获取Header的X-Test值
- 可以用作if判断的全局变量

```bash
$args #这个变量等于请求行中的参数，同$query_string
$content_length #请求头中的Content-length字段
$content_type #请求头中的Content-Type字段
$document_root #当前请求在root指令中指定的值
$host #请求主机头字段，否则为服务器名称
$http_user_agent #客户端agent信息
$http_cookie #客户端cookie信息
$limit_rate #这个变量可以限制连接速率
$request_method #客户端请求的动作，通常为GET或POST
$remote_addr #客户端的IP地址(***)
$remote_port #客户端的端口
$remote_user #已经经过Auth Basic Module验证的用户名
$request_filename #当前请求的文件路径，由root或alias指令与URI请求生成
$scheme #HTTP方法（如http，https）
$server_protocol #请求使用的协议，通常是HTTP/1.0或HTTP/1.1
$server_addr #服务器地址，在完成一次系统调用后可以确定这个值
$server_name #服务器名称
$server_port #请求到达服务器的端口号
$request_uri #包含请求参数的原始URI，不包含主机名，如："/foo/bar.php?arg=baz"
$uri #不带请求参数的当前URI，$uri不包含主机名，如"/foo/bar.html"
$document_uri #与$uri相同
```

- 可用在log_format的全局变量

```bash
$remote_addr #客户端地址。211.28.65.253
$remote_user #客户端用户名称
$time_local #访问时间和时区。18/Jul/2012:17:00:01 +0800
$request #请求的URI和HTTP协议。"GET /article-10000.html HTTP/1.1"
$status #HTTP请求状态。200
$http_host #请求地址，即浏览器中输入的地址（IP或域名）。www.aezo.cn、192.168.1.1
$body_bytes_sent #发送给客户端文件内容大小。1547
$upstream_status #upstream状态。200
$upstream_addr #后台upstream的地址，即真正提供服务的主机地址；当ngnix做负载均衡时，可以查看后台提供真实服务的设备。10.10.10.100:80
$request_time #整个请求的总时间。0.205
$upstream_response_time #请求过程中，upstream响应时间。0.002
$http_referer #url跳转来源。https://www.baidu.com/
$http_user_agent #用户终端浏览器等信息。Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; SV1; GTB7.0; .NET4.0C;
$ssl_protocol #SSL协议版本。TLSv1
$ssl_cipher #交换数据中的算法。RC4-SHA
```

### if语句

```bash
## 常见案例(if可以在server/location节点使用)
if ($scheme = http) {
	return 301 https://$server_name$request_uri;
}
# 正则匹配(~*)
if ($request_filename ~* .*\.(?:htm|html)$) {
	add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
}
if (!-f $request_filename) {
	proxy_pass http://127.0.0.1:8080;
	break;
}
if ($http_user_agent ~* (python|HttpClient)) {
    return 403;
}

## nginx不支持逻辑与和或，也不支持嵌套：解决方案如下
# 伪代码(即不被nginx支持)
if ($remote_addr ~ "^(12.34|56.78)" && $http_user_agent ~* "spider") {
    return 403;
}
# 等效代码(被nginx支持)
set $flag 0;
if ($remote_addr ~ "^(12.34|56.78)") {
    set $flag "${flag}1";
}
if ($http_user_agent ~* "spider") {
    set $flag "${flag}2";
}
if ($flag = "012") {
    return 403;
}
```

## 模块说明

### 访问控制

- 禁止允许规则(`ngx_http_access_module`)：按照顺序依次检测，直到匹配到第一条规则

```bash
location / {
    deny  192.168.1.1; # 阻止
    allow 192.168.1.0/24; # 允许以下ip段
    allow 10.1.1.0/16;
    allow 2001:0db8::/32; # ipv6
    deny  all; # 阻止所有，和allow配合使用

    # ...
}
```
- 用户认证(`ngx_http_auth_basic_module`) [^4]
    - 需要使用htpasswd等工具生成密码文件，不能直接写明文密码
    - `auth_basic <string | off>;`
        - 默认值: auth_basic off; (默认表示不开启认证，后面如果跟上字符，这些字符会在弹窗中显示。)
        - 配置段: http, server, location, limit_except
    - `auth_basic_user_file <密码文件>;`
        - 配置段: http, server, location, limit_except

### nginx缓存

- 参考文章
    - https://juejin.cn/post/7079601613135937550
- nginx可配置的缓存有2种
    - 客户端的缓存(一般指浏览器的缓存)
    - 服务端的缓存(使用proxy-cache实现的)

#### 结合浏览器缓存

- HTTP缓存：https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Caching
- 参考：https://blog.csdn.net/qq_43271330/article/details/108335974
- 缓存机制
    - 强缓存：直接从浏览器缓存中取，但会判断浏览器缓存的文件是否过期
    - 协商缓存：先发送请求到服务器判断文件是否改动，服务器返回未改动状态，则从浏览器中取
        - 即第一次请求的响应头带上某个字段（ETag或Last-Modified），则后续请求会带上对应的请求字段(If-None-Match或If-Modified-Since)；若响应头没有 ETag或Last-Modified字段，则请求头也不会有对应的字段
        - 这两组字段都是成对出现的，Last-Modified与ETag可以一起使用，服务器会优先验证ETag，一致的情况下才会比对Last-Modifed
- 强缓存相关参数
    - Expires(Http1.0) 响应头过期时间
        - 如果cache-control与expires同时存在的话，cache-control的优先级高于expires
    - Cache-Control(Http1.1) 该字段的优先级要比Expires优先级高
        - `no-store` **不使用缓存(无此参数就表示可以使用缓存，此时需要看其他参数是否对缓存有限制)**。禁止将响应存储在任何缓存中(但不会删除相同 URL 的任何已存储响应，已经缓存的仍然能使用)
        - `no-cache` **强制重新验证(也可用max-age=0代替)**，一般不和max-age同时使用。每次请求都会验证本地缓存和服务器是否一致(更新时间Last-Modified和文件内容Hash值ETag)，一致则返回304并使用本地缓存(不下载服务器资源)
        - `max-age` 缓存的内容将在多少秒后失效，相对于请求时间来说的
            - max-age=0便是无论服务端如何设置，在重新获取资源之前，先检验ETag/Last-Modified。在设置max-age=no-cache或0后，在资源无更新的情况下访问都会返回304
            - 只设置`expires 7d;`会转换成`Cache-Control max-age=604800`设置到返回头中
            - 设置对jsp等页面设置了如`Cache-Control max-age=36000`，则浏览器地址栏回车/F5刷新/路径增加了参数都会重新获取数据，只有在通过`<a>`标签进行跳转到此页面时才会出现被缓存的问题(js/css等静态文件一般都是页面引用的，不会出现刷新情况，所有此参数会进行缓存静态资源)
        - `private` 客户端可以缓存
        - `public` 客户端和代理服务器都可缓存
        - `must-revalidate` 告诉浏览器/缓存服务器；在本地文件过期之前可以使用本地文件；本地文件一旦过期需要去源服务器进行有效性校验；如果有缓存服务器且该资源未过有效期则命中缓存服务器并返回200；如果过期且源服务器未发生更改；则校验后返回304
- 协商缓存相关参数
    - Etag/If-None-Match
    - Last-Modified/If-Modified-Since
- 其他参数
    - Pragma(Http1.0) 它用来向后兼容只支持 HTTP/1.0 协议的缓存服务器，那时候 HTTP/1.1 协议中的 Cache-Control 还没有出来
- 判断请求是否使用了浏览器缓存：F12 - Network - 观察Size和Status列
    - Size为(memory cache)和(disk cache)，此时Status为200：表示使用了浏览器缓存或磁盘缓存(当关闭浏览器后重新打开，那默认会到本地磁盘上获取此数据)
    - Size有值，Status为304：表示通过max-age判断文件已经超过了设置的缓存时间，但是服务端返回此文件未被更新，则返回304，数据仍然从本地缓存读取
- Chrome浏览器本身控制缓存机制。参考：https://blog.csdn.net/andy_csdn007/article/details/115210818
    - `Ctrl + Shift + R` / `Ctrl + F5` 强制刷新不走缓存
    - `Ctrl + Shift + Delete` 弹出删除缓存和Cookie的确认框
    - F12 - Network - Disable cache 关闭缓存
    - F12 - Setting - Network - Disable cache(当打开F12时关闭缓存)
    - 浏览器启动命令增加相关参数
- HTML设置相关参数

```html
<!-- 不缓存此HTML文件中的JS/CSS等资源 -->
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache,max-age=0,must-revalidate,no-store">
<meta http-equiv="Expires" content="0" />
<meta http-equiv="Cache" content="no-cache">
```
- Nginx相关配置

```bash
server {
    # 防止缓存index.html。且index.html中应用的js、css编译的文件名是hash过的，因此也不会缓存
        # index.html里面加meta标签是为了不缓存index.html里面的css/js；另外vue-cli等打包插件支持对css/js的名字加哈希值(如：main.0926594267d262000533.js)，因此不加meta标签页不会缓存
        #<meta http-equiv="Pragma" content="no-cache">
        #<meta http-equiv="Cache-Control" content="no-cache,max-age=0,must-revalidate,no-store">
    location = /index.html {
        root   /home/aezocn/www;
        #- nginx的expires指令：`expires [time|epoch|max|off(默认)]`。可以控制 HTTP 应答中的Expires和Cache-Control的值
        #   - time控制Cache-Control：负数表示no-cache，正数或零表示max-age=time
        #   - epoch指定Expires的值为`1 January,1970,00:00:01 GMT`
        expires -1s; # 对于不支持http1.1的浏览器，还是需要expires来控制
        add_header Cache-Control "no-cache, no-store"; # 会加在 response headers
    }
    # 所有*.html的文件均不缓存，但是其优先级低于 ^~ 的匹配方式
    location ~ .*.(htm|html)?$ {
		add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
		access_log on;
	}

    # 相当于只缓存 /static/assets/ 路径下的文件
    add_header Cache-Control "no-cache, no-store"; # 先声明整个server不要缓存(包含了一些如JSP页面)；location中再申明可缓存对应静态文件，但是每次需校验ETag/Last-Modified值
    location /static/assets/ {
        add_header  Cache-Control max-age=no-cache;
        proxy_pass http://127.0.0.1:8080/static/assets/;
        break;
    }

    location / {
        if ($request_filename ~* .*\.(?:htm|html)$) {
            add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
        }
        if ($request_filename ~* .*\.(?:js|css)$) {
            expires      7d; # 会转换成`Cache-Control max-age=604800`设置到返回头中
        }
        if ($request_filename ~* .*\.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm)$) {
            expires      7d;
        }
        # ...
    }
}
```

#### proxy缓存功能

- 参考
    - https://blog.csdn.net/shark_chili3007/article/details/104009742
- 对应模块`ngx_http_proxy_module`
- 反向代理时先从nginx缓存中寻找资源，如果缓存中没有则向tomcat请求

```bash
http {
    # 省略其他配置 ...

    ## 配置缓存：缓存的基本上都是静态的东西，动态的插了java代码之类数据缓存后是无法更新的（即如果是jsp等页面会将最终渲染出来的数据进行缓存）
    # 代理临时目录(需要先创建目录`mkdir -p /var/temp/nginx`且nginx用户拥有权限)
    proxy_temp_path /var/temp/nginx/proxy;
    # 代理缓存目录(/var/temp/nginx/proxy_cache)，和proxy_temp_path必须在同一个分区
    # levels指定该缓存空间有两层hash目录，第一层目录名是1个字母或数字长度，第二层目录名为2个字母或数字长度
    # keys_zone=cache_one:50m, 缓存区名称为cache_one，在内存中的空间是50M，inactive=1d表示1天未被访问的数据将从缓存中删除，max_size指定磁盘空间大小为500M
    proxy_cache_path /var/temp/nginx/proxy_cache levels=1:2 keys_zone=cache_one:50m inactive=1d max_size=500m;
}

server {
    # 给请求响应增加一个头部信息，表示从服务器上返回的cache状态(upstream_cache_status):HIT(命中) | MISS(未命中)
    add_header Nginx-Cache "$upstream_cache_status from $server_addr";

    # 配置缓存内容和缓存的条件（请求static时先从nginx缓存中寻找资源，如果缓存中没有则向tomcat请求）
    location ~ /res(/.*) {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # 代理访问后端tomcat(此处如果类似 http://backend$1 则缓存失败)
        proxy_pass http://backend; # backend为upstream服务器集群名

        #指定缓存区域名称，这里的proxy_cache的值一定是上面的 keys_zone (*)
        proxy_cache cache_one;
        #以域名、URI、参数组合成Web缓存的Key值，Nginx根据Key值哈希
        proxy_cache_key $host$uri$is_args$args;
        # 设置状态码为200和304的响应可以进行缓存，并且缓存时间为1天
        proxy_cache_valid 200 304 1d;
        expires 30d;
    }
}
```

#### 清除指定url缓存

- 对应模块`ngx_cache_purge`
- 添加安装清除缓存模块(基于下文【基于编译安装tengine】安装状态进行说明)
    - 下载ngx_cache_purge模块 `http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz`
    - 将ngx_cache_purge-2.3.tar.gz解压到tengine源码目录
    - 在上述安装的`./configure`命令后加上`--add-module=./ngx_cache_purge-2.3`(ngx_cache_purge源码路径)
    - `make` 进行编译(不用执行`make install`)
    - `cp /opt/soft/tengine-2.1.0/sbin/nginx /opt/soft/tengine-2.1.0/sbin/nginx.bak` 备份
    - `cp ./objs/nginx /opt/soft/tengine-2.1.0/sbin/` 将新编译出来的nginx执行文件复制到原始安装目录
- 添加清除缓存配置

```bash
location ~ /purge(/.*) {
    # 指定清空缓存的区域名称cache_one，要和上边proxy_cache_path缓存配置中指定的缓存区域名称一致（*）
    # 指定缓存的key规则$host$1$is_args$args，要和上边设置缓存的key一致$host$uri$is_args$args。注意$host$1$is_args$args中的$1表示当前请求的uri，$host$1$is_args$args=$host$uri$is_args$args
    proxy_cache_purge cache_one $host$1$is_args$args;

    #安全设置，指定请求客户端的IP或IP段才可以清除URL缓存
    #allow          127.0.0.1;
}
```
- 访问`http://192.168.6.132/purge/tomcat.png`(提示`Successful purge`)，即可清除 `http://192.168.6.132/tomcat.png`的缓存

### 反向代理和负载均衡

- 代理一般指客户端代理(比如Google agent代理翻墙)，反向代理则指服务器代理
- 反向代理配置`proxy_pass`(`ngx_http_proxy_module`)：访问http://127.0.0.1，nginx会将请求转给 http://127.0.0.1:8080

```bash
location / {
    proxy_pass http://127.0.0.1:8080;
}
```
- 负载均衡`upstream`([ngx_http_upstream_module](http://tengine.taobao.org/nginx_docs/cn/docs/http/ngx_http_upstream_module.html))

```bash
# 参考：https://www.cnblogs.com/kevingrace/p/8185218.html
# upstream和server平级配置，backend为定义的服务器集群名称
upstream backend {
    # 负载均衡方式: rr(默认，轮询模式)、ip_hash、fair(按后端服务器的响应时间来分配请求，响应时间短的优先分配)、url_hash(和ip_hash算法类似，是对每个请求按url的hash结果分配，比较适用于后端为缓存服务器)
    # ip_hash;

    # weight标识转发给此server的权重，默认是1
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;
    server unix:/tmp/backend3;

    # 标记为备用服务器。当主服务器不可用以后，请求会被传给这些服务器
    server backup1.example.com:8080   backup;
    server backup2.example.com:8080   backup;
}

server {
    location / {
        # 和上面定义的服务器集群名对应
        proxy_pass http://backend;
    }

    location ~ /link(/.*) {
        # $1表示取出正则表达式(/.*)所匹配的内容，使用$1的效果例如请求 http://192.168.6.132/link/tomcat.png 则请求tomcat服务器 http://ip:port/tomcat.png。 如果不使用$1则会将/link/...加在tomcat服务地址之后访问，即 http://ip:port/link/tomcat.png（*）
        proxy_pass http://backend$1;
    }
}
```
- **nginx自带健康检查的缺陷**
    - Nginx只有当有访问时，才发起对后端节点请求
    - 如果本次请求中，节点正好出现故障，Nginx依然将请求转交给故障的节点，然后再转交给健康的节点处理(之后每次都有可能出现部分静态文件先请求到错误节点)。所以不会影响到这次请求的正常进行，但是会影响效率，因为多了一次转发
    - 自带模块无法做到预警，属于被动健康检查
    - 解决：使用第三方模块[nginx_upstream_check_module](https://github.com/yaoweibin/nginx_upstream_check_module/tree/master/)，为tengine模块，可用于nginx，参考：https://juejin.cn/post/7121879473158373406
- tengine主动健康检查([ngx_http_upstream_check_module](http://tengine.taobao.org/document_cn/http_upstream_check_cn.html))
    - tengine特有。如果集群中有某个服务器挂掉则检查面板中会标记成红色

```bash
upstream backend {
    # 省略其他配置
    # ...

    # fall=5 连续失败次数达到5次则认为服务器down，面板中会显示红色。
    # rise=2 连续成功次数达到2次则认为服务器up，面板中会显示白色。
    check interval=3000 rise=2 fall=5 timeout=1000 type=http;
    check_http_send "HEAD / HTTP/1.0\r\n\r\n";
    check_http_expect_alive http_2xx http_3xx;
}

server {
    # 健康检查访问端点。如访问：http://192.168.6.131/status 显示检查面板
    location /status {
        check_status;
    }
}
```
- session一致性问题解决方案：`memcached`或`redis`等缓存数据库保存所有的session(以tomcat-7.0.61为例)
    - tengine的会话保持功能：同一个客户端会话有效期间永远访问的是同一个服务器([ngx_http_upstream_session_sticky_module](http://tengine.taobao.org/document_cn/http_upstream_session_sticky_cn.html))
        - 基于cookies实现
        - 在`upstream`中加入`session_sticky;`
    - redis方式
        - 安装redis缓存数据库(参考《redis》)
        - 修改配置文件`vi /etc/redis.conf`将bind的127.0.0.1修改为本机地址，否则只能本机访问了
        - 将web服务器连接redis的jar包拷贝到tomcat的lib[针对tomcat-7.0.61相关jar下载地址](http://download.csdn.net/download/oldinaction/10267668)
        - 配置tomcat的`conf/context.xml`

            ```xml
            <Valve className="com.orangefunction.tomcat.redissessions.RedisSessionHandlerValve" />
            <Manager className="com.orangefunction.tomcat.redissessions.RedisSessionManager"
                host="192.168.1.1"
                port="6379"
                database="0"
                maxInactiveInterval="60" />
            ```
    - redis方式也可使用[tomcat-cluster-redis-session-manager](https://github.com/ran-jit/tomcat-cluster-redis-session-manager)插件，参考[集群配置Session共享(基于redis)](/_posts/java/ofbiz/ofbiz.md#集群配置Session共享(基于redis))
    - memcached方式（安装查看：《memcached缓存数据库》）
        - 将web服务器连接memcached的jar包拷贝到tomcat的lib[针对tomcat-7.0.61相关jar下载地址](http://download.csdn.net/download/oldinaction/10267668)
        - 配置tomcat的`conf/context.xml` 配置memcachedNodes属性，配置memcached数据库的ip和端口(默认11211)，多个的话用空格隔开。主要是让tomcat服务器从memcached缓存里面拿session或者是放session

            ```xml
            <Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager"
                memcachedNodes="n1:192.168.1.1:11211 n2:192.168.1.2:11211"
                sticky="false"
                lockingMode="auto"
                sessionBackupAsync="false"
                requestUriIgnorePattern=".*\.(ico|png|gif|jpg|css|js)$"
                sessionBackupTimeout="1000" transcoderFactoryClass="de.javakaffee.web.msm.serializer.kryo.KryoTranscoderFactory" />
            ```
        - 修改tomcat中`conf/server.xml`里面修改`Engine`标签，添加`jvmRoute`属性，目的是让sessionid里面带有tomcat的名字`<Engine name="Catalina" defaultHost="localhost" jvmRoute="tomcat1">`
        - 修改tomcat的`webapps/ROOT/index.jsp`
            
            ```jsp
            <%@ page language="java" contentType="text/html; charset=UTF-8"  pageEncoding="UTF-8"%>
            <html lang="en">
                SessionID:<%=session.getId()%></br>   
                SessionIP:<%=request.getServerName()%></br>
                <h1>tomcat1</h1>
            </html>
            ```
        - memcached集群需要多台服务器时间一致(30s以内)

### nginx-sticky-module-ng(cookie负载均衡)

- Sticky就是基于cookie的一种负载均衡解决方案，它是通过基于cookie实现客户端与后端服务器的会话保持，在一定条件下可以保证同一个客户端访问的都是同一个后端服务器(要求浏览器必须支持cookie)
- **粘性会话/会话保持**
    - 负载均衡器
        - 使用nginx自带cookie_jessionid
        - 使用nginx模块sticky
    - 客户端负载均衡
        - 基于Ribbon，根据用户的某些标识（如用户 ID）来选择实例
    - 在网关（如 Zuul、Spring Cloud Gateway）层面实现
        - https://blog.csdn.net/scruffybear/article/details/132977281
- 会话保持案例，参考: https://cloud.tencent.com/developer/article/2331129

```bash
upstream myserver {
    # 详细参数: sticky [name=route] [domain=.foo.bar] [path=/] [expires=1h] [hash=index|md5|sha1] [no_fallback] [secure] [httponly];
    # [name=route]　　　　　　　设置用来记录会话的cookie名称
    # [domain=.foo.bar]　　　　设置cookie作用的域名
    # [path=/]　　　　　　　　  设置cookie作用的URL路径，默认根目录
    # [expires=1h] 　　　　　　 设置cookie的生存期，默认不设置，浏览器关闭即失效，需要是大于1秒的值
    # [hash=index|md5|sha1]   设置cookie中服务器的标识是用明文还是使用md5值，默认使用md5
    # [no_fallback]　　　　　　 设置该项，当sticky的后端机器挂了以后，nginx返回502 (Bad Gateway or Proxy Error) ，而不转发到其他服务器，不建议设置
    # [secure]　　　　　　　　  设置启用安全的cookie，需要HTTPS支持
    # [httponly]　　　　　　　  允许cookie不通过JS泄漏，没用过
    sticky;

    # 另外一种会话保持方式是指定为 cookie_jessionid(nginx自带的方式，无需额外安装模块，但是要求服务端需要返回cookie)
    # hash $cookie_jsessionid;

    server www.test.com:8001;
    server www.test.com:8002;
}
```

### ngx-http-map-module(变量转换)

- `ngx-http-map-module` 可以基于其他变量及变量值进行变量创建，其允许分类，或者映射多个变量到不同值并存储在一个变量中。(nginx默认已存在，除非由人为移除--without-http_map_module)
- `map $var1 $var2 {...}`
    - 配置段位http
    - $var1 为源变量，$var2 是自定义变量。$var2 的值取决于 $var1 在对应表达式的匹配情况。如果一个都匹配不到则 $var2 就是 default 对应的值
    - 部分参数
        - default： 指定源变量匹配不到任何表达式时将使用的默认值。当没有设置 default，将会用一个空的字符串作为默认的结果
- 示例

```bash
# 如果 $http_user_agent 为 curl 则 $agent=curl，如果 $http_user_agent 为 apachebench 则 $agent=ab，否则为 ""
map $http_user_agent $agent {
    default "";
    # 可以使用正则(~表示大小写敏感，~*表示大小写不敏感)
    ~curl curl;
    ~*apachebench ab;
}
```

### ngx-http-geo-module(客户端IP-变量)

- `ngx-http-geo-module` 可以用来创建变量，变量值依赖于客户端 ip 地址(nginx默认已存在)
- `geo [$address] $variable { ... }` 配置段位http
- 示例：限速白名单的配置实例

```bash
http{
    # geo指令，定义变量是否为白名单$whiteiplist(默认1；1表示限制速度，0表示不限制)。如果客户端IP与白名单列出的IP相匹配，则$whiteiplist值为0也就是不受限制
    geo $whiteiplist {
        default 1;
        127.0.0.1 0;
        192.168.0.0/16 0;
    }
    
    # map指令，将$whiteiplist值为1的，也就是受限制的IP，映射为客户端IP。将$whiteiplist值为0的，也就是白名单IP，映射为空的字符串。并赋值给 $limit
    map $whiteiplist $limit {
        1 $binary_remote_addr;
        0 "";
    }

    # limit_conn_zone和limit_req_zone指令对于键为空值的将会被忽略，从而实现对于列出来的IP不做限制
    limit_conn_zone $limit zone=limit:10m;

    server {
        listen 80;
        server_name test.example.com;

        location ~ / {
            root /var/www/test/;         
            index index.html index.php index.htm;
        }

        location ^~ /download/ {
            limit_conn limit 4; # 最大的并发连接数
            limit_rate 200k; # 每个连接的带宽
            alias /data/download/;
        }
    }
}
```

## 结合keepalived实现高可用

- 示意图

    ![keepalived-nginx](/data/images/arch/keepalived-nginx.jpg)

- 到达高可用需要配置nginx集群。主nginx宕机后，备用nginx可正常使用。判断nginx是否可用通过keepalived来判断：每台nginx服务器上需安装一个keepalived，配置如下
- 两台nginx均进行安装：`yum -y install keepalived`
- 新建文件`/etc/keepalived/check_nginx.sh`，内容如下（并设置可执行权限）
    - keepalived是通过检测keepalived进程是否存在判断服务器是否宕机，如果keepalived进程在但是nginx进程不在了那么keepalived是不会做主备切换，所以我们需要写个脚本来监控nginx进程是否存在，如果nginx不存在就将keepalived进程杀掉。在主nginx上需要编写nginx进程检测脚本（check_nginx.sh），判断nginx进程是否存在，如果nginx不存在就将keepalived进程杀掉

```bash
#!/bin/bash
A=`ps -C nginx --no-header | wc -l` # 查看是否有nginx进程，把进场数赋给变量A 
if [ $A -eq 0 ];then
    /opt/nginx/sbin/nginx # 如果没有进程，尝试重新启动nginx（systemctl restart nginx）
    sleep 2  # 睡眠2秒
    if [ `ps -C nginx --no-header | wc -l` -eq 0 ];then
        systemctl stop keepalived #启动失败，将keepalived服务停止。将vip漂移到其它备份节点
    fi
fi
```
- 配置Keepalived(抢占模式配置) 增加VIP 启动服务
    - MASTER（192.168.6.131）配置信息

        ```bash
        global_defs {
            # 用户标识本节点的名称，通常为hostname
            router_id server1.aezocn
        }

        vrrp_script check_nginx {
            #检测nginx的脚本
            script "/etc/keepalived/check_nginx.sh"
            #每2秒检测一次
            interval 2
            #如果某一个nginx宕机 则权重减20
            weight -20
        }

        vrrp_instance VI_1 {
            #状态 MASTER或BACKUP
            state MASTER
            #绑定的网卡(如：eth0、ens33等)
            interface eth0
            #虚拟路由的ID号,两个节点设置必须一样(*)
            virtual_router_id 51
            #本机的IP
            mcast_src_ip 192.168.6.131
            # 节点优先级，取值范围0～254，MASTER要比BACKUP高(*)
            priority 100
            advert_int 1
            # 设置验证信息，两个节点必须一致(*)
            authentication {
                auth_type PASS
                auth_pass 1111
            }
            # 虚拟IP，两个节点设置必须一样(*)
            virtual_ipaddress {
                # 此虚拟ip为web服务对外提供访问的ip
                192.168.6.100
            }
            # nginx存活状态检测脚本
            track_script {
                check_nginx
            }
        }
        ```
    - BACKUP（192.168.6.132）配置信息

        ```bash
        global_defs {
            router_id server2.aezocn
        }

        vrrp_script check_nginx {
            script "/etc/keepalived/check_nginx.sh"
            interval 2                              
            weight -20								
        }

        vrrp_instance VI_1 {
            state BACKUP
            interface eth0
            virtual_router_id 51
            mcast_src_ip 192.168.6.132
            priority 99
            advert_int 1
            authentication {
                auth_type PASS
                auth_pass 1111
            }
            virtual_ipaddress {
                192.168.6.110
            }
            track_script {
                check_nginx
            }
        }
        ```

## 基于编译安装tengine

- tengine功能特点
    - 主动健康检查。nginx则需使用第三方模块(nginx_upstream_check_module)，参考上文[反向代理和负载均衡](#反向代理和负载均衡)
- 编译安装好处：更方便的插拔模块(yum安装只能使用源默认的模块，nginx同理安装)
- 安装依赖 **`yum install gcc openssl-devel pcre-devel zlib-devel`**(否则configure时报错)
- 创建用户和用户组，为了方便nginx运行而不影响linux安全(也可省略)
    - `groupadd -r nginx` 创建组
    - `useradd -r -g nginx -M nginx` 创建用户(`-M`表示不创建用户的家目录)
- 上传tar并解压 `tar -zxvf tengine-2.1.0.tar.gz`(解压出的tengine-2.1.0为源码目录)
- 安装(进入到解压目录tengine-2.1.0)
    - `./configure` configure详细参数介绍如下
        - **`--prefix` 安装位置**
        - `--sbin-path` 执行文件路径
        - `--conf-path` 配置文件路径(启动和配置路径用默认)
        - `--http-log-path` http请求日志路径
        - `--lock-path` 锁文件位置
        - `--pid-path` pid路径
        - `--group`、`--user` 限制某个组下某用户有权运行(如果未创建对应的用户可省略)
        - `--with-xxx` 加入相关模块
        - `--http-xxx-temp-path` 临时文件路径(**下例中需要手动创建`mkdir -p /var/tmp/nginx/client/`目录**)
        
        ```bash
        ./configure \
        --prefix=/opt/soft/tengine-2.1.0/ \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --with-http_ssl_module \
        --with-http_flv_module \
        --with-http_stub_status_module \
        --with-http_gzip_static_module \
        --with-pcre \
        --http-client-body-temp-path=/var/tmp/nginx/client/ \
        --http-proxy-temp-path=/var/tmp/nginx/proxy/ \
        --http-fastcgi-temp-path=/var/tmp/nginx/fcgi/ \
        --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
        --http-scgi-temp-path=/var/tmp/nginx/scgi \
        --add-module=./ngx_cache_purge-2.3 ## --add-module=./ngx_cache_purge-2.3 # 添加清除缓存模块
        ```
    - `make && make install`

### 自定义服务

- 方法一 [^3]
    - nginx安装一般会自动注册到服务中取，有些手动安装可能需要自己注册，以nginx手动注册成服务为例
    - 方法：在 **`/usr/lib/systemd/system`**(或`/etc/systemd/system`) 路径下创建`755`的文件nginx.service：`sudo vi /usr/lib/systemd/system/nginx.service`，文件内容如下：
    
        ```bash
        ## 服务的说明
        [Unit]
        # 描述服务
        Description=nginx
        # 依赖，当依赖的服务启动之后再启动自定义的服务
        After=network.target remote-fs.target nss-lookup.target

        ## 服务运行参数的设置
        [Service]
        # forking是后台运行的形式; oneshot适用于只执行一项任务，随后立即退出的服务; simple
        Type=forking
        # pid存放文件
        # PIDFile=/var/run/nginx.pid
        # 指定当前服务的环境参数文件。该文件内部的 KEY=VALUE 键值对，指定的KEY可当前变量在此文件中使用$KEY
        # EnvironmentFile=-/etc/sysconfig/xxx
        # 为服务的具体运行命令(注意：启动、重启、停止命令全部要求使用绝对路径) /usr/local/nginx/conf/nginx.conf
        ExecStart=/usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf
        # 停止命令
        ExecStop=/usr/local/nginx/sbin/nginx -s stop
        # 重启命令(其他软件也适用)
        ExecReload=/usr/local/nginx/sbin/nginx -s reload
        # 表示给服务分配独立的临时空间
        # PrivateTmp=True

        ## 服务安装的相关设置
        [Install]
        # 表示该服务所在的Target，此时为多用户模式下
        WantedBy=multi-user.target
        ```
        - `systemctl daemon-reload` 修改服务配置文件后重新加载
    - 设置开机启动：`systemctl enable nginx`
    - 自定义服务文件模板(如`/usr/lib/systemd/system/test@.service`)
        - 大多数情况下，包含 `@` 标记都意味着这个文件是模板。模板单元中的 `%i`(会转义，如空格转义成`\x20`)或`%I`(不会转义，但是传入`-`会替换成`/`) 会被@之后的字符串替换，如果一个模板单元没有实例化就调用，该调用会返回失败。调用如`systemctl start test@argument.service`
        - 关于转义字符，如模板文件为`ExecStart=/bin/echo %i === %I`，当执行`systemctl start echo@'\x2da -a \x2db b'`，则打印`\x2da\x20-a\x20\x2db\x20b === -a /a -b b`。参考：https://www.freedesktop.org/software/systemd/man/systemd-escape.html
        - 参考：https://www.freedesktop.org/software/systemd/man/systemd.unit.html、https://superuser.com/questions/393423/the-symbol-and-systemctl-and-vsftpd
- 方法二
    - 新建755权限文件`/etc/rc.d/init.d/nginx`，文件内容参考[/data/images/arch/nginx](/data/images/arch/nginx)
        - 注意修改其中`nginx="/opt/soft/tengine-2.1.0/sbin/nginx"`和`NGINX_CONF_FILE="/opt/soft/tengine-2.1.0/conf/nginx.conf"`的配置
    - `chkconfig --add nginx` 将nginx加入到服务列表
    - `chkconfig nginx on` 设置nginx服务开机自启动
    - `systemctl start nginx` 手动启动

## 版本更新变化

- v1.12.1
    - 当访问`http://www.aezo.cn/index.html`不进入对应的页面，而是显示默认的`/usr/share/nginx/html/index.html`。解决办法：注释掉此文件即可

## 常见错误

- 错误代码`10060`。某次：windows server 2012，无并发，某天开始出现此错误，最终通过修改注册表解决(需重启，将localhost优先按ipv4解析)，参考：https://blog.csdn.net/u010267491/article/details/52775115




---

参考文章

[^1]: [location配置规则](http://outofmemory.cn/code-snippet/742/nginx-location-configuration-xiangxi-explain)
[^2]: [location配置正则](http://blog.csdn.net/gzh0222/article/details/7845981)
[^3]: [自定义服务](http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-part-two.html)
[^4]: [Nginx的两种认证方式](https://www.cnblogs.com/wangxiaoqiangs/p/6184181.html)
