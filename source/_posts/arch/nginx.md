---
layout: "post"
title: "nginx"
date: "2017-01-16 16:54"
categories: arch
tags: LB, HA
---

## nginx介绍

- nginx("engine x") 是一个高性能的 HTTP 和 反向代理 服务器，也是一个 IMAP/POP3/SMTP 代理服务器
- 轻量级，同样起web服务，比`apache`占用更少的内存及资源，抗并发，nginx 处理请求是异步非阻塞的，而apache则是阻塞型的。最核心的区别在于apache是同步多进程模型，一个连接对应一个进程；nginx是异步的，多个连接（万级别）可以对应一个进程(nginx是多进程的)
- 作用：作为前端服务器拥有响应静态页面功能；作为集群构建者拥有反向代理功能
- 单个tomcat支持最高并发，测试结果：150人响应时间1s、**250人响应1.8s(理想情况下最大并发数)**、280人出现连接丢失、600人系统异常
- `Tengine`是nginx的加强版，封装版，淘宝开源。
    - [官网](http://tengine.taobao.org/)
    - [中文文档](http://tengine.taobao.org/nginx_docs/cn/docs/)
    - [Nginx开发从入门到精通](http://tengine.taobao.org/book/)
- nginx在整体架构中的作用

    ![nginx-arch](/data/images/arch/nginx-arch.png)

## nginx使用

- 安装**(详细参考下文`基于编译安装tengine`)**
    - `yum install nginx` 基于源安装(傻瓜式安装)
        - 默认可执行文件路径`/usr/sbin/nginx`(已加入到系统服务); 配置文件路径`/etc/nginx/nginx.conf`
        - 安装时提示"No package nginx available."。问题原因：nginx位于第三方的yum源里面，而不在centos官方yum源里面，解决办法为安装epel(Extra Packages for Enterprise Linux)
            - 下载epel源 `wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm` (http://fedoraproject.org/wiki/EPEL)
            - 安装epel `rpm -ivh epel-release-latest-7.noarch.rpm`
            - 再下载 `yum install nginx`
    - 程序包解压安装
- 启动
    - `systemctl start nginx` 启动
    - 进入到`nginx`执行文件目录，运行`sudo ./nginx`
- 停止
    - `systemctl stop nginx`
        - 有时候启动失败可能是端口占用，`listen`对应的端口必须是空闲状态
    - `sudo ./nginx -s stop`
- 相关命令
    - `ps -ef | grep nginx` 查看nginx安装位置(nginx的配置文件.conf在此目录下)
    - `sudo find / -name nginx.conf` 查看配置文件位置
    - **校验配置**：`/usr/sbin/nginx -t` 检查配置文件的配置是否合法(也会返回配置文件位置)，适用windows
    - **重载配置文件**： `/usr/sbin/nginx -s reload`，适用windows
    - 重启：`/usr/sbin/nginx -s restart` 有的配置文件改了必须重启

## nginx配置(nginx.conf)

- 查找配置文件 `sudo find / -name nginx.conf`

- 配置示例

```bash
server {
    # 监听的端口，注意要在服务器后台开启80端口外网访问权限
    listen   80;
    # 服务器的地址              
    server_name www.aezo.cn;

    # 当直接访问www.aezo.cn时, 重定向到http://www.aezo.cn/hello(地址栏url会发生改变)
    location = / {
        rewrite / http://$server_name/hello break;
    }

    # 用于暴露静态文件，访问http://www.aezo.cn/static/logo.png，且无法访问到http://www.aezo.cn/static
    # 文件实际路径为/home/aezocn/www/static/logo.png
    location ^~ /static/ {
        root /home/aezocn/www;
    }

    # 当直接访问www.aezo.cn下的任何地址时，都会转发到http://127.0.0.1:8080下对应的地址(内部重定向，地址栏url不改变)。如http://www.aezo.cn/admin等，会转发到http://127.0.0.1:8080/admin
    # location后的地址可正则，如 `location ^~ /api/ {...}` 表示访问 http://www.aezo.cn/api/xxx 会转到 http://127.0.0.1:8080/api/xxx 上
    location / {
        proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        if (!-f $request_filename) {
            # 不能包含/等uri地址, 如果匹配到上面的uri则转向http://127.0.0.1:8080/xxxUri
            proxy_pass http://127.0.0.1:8080;
            break;
        }
    }

    # nginx 配置，让index.html不缓存
    location = /index.html {
        add_header Cache-Control "no-cache, no-store";
    }

    # php文件转给fastcgi处理，但是需要安装如`php-fpm`来解析
    # 如果访问 http://127.0.0.1:8080/myphp/index.php 此时会到 /project/phphome/myphp 目录寻找/访问 index.php 文件
    location ~ \.php$ {
        try_files $uri = 404; # 不存在访问资源是返回404，如果存在还是返回`File not found.`则说明配置有问题
        root           /project/phphome/myphp;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name; # 此处要使用`$document_root`否则报错File not found.`
        include        fastcgi_params;
    }
    # 如果上述index.php中含有一个静态文件，此时需要加上对应静态文件的解析
    location ~ /myphp/ {
        root /project/phphome/myphp;
    }
}

# 开启第二个站点监听
server {
    listen 80;
    server_name hello.aezo.cn;

    location = / {
        #判断是否为手机移动端
        if ($http_user_agent ~* '(iPhone|ipod|iPad|Android|Windows Phone|Mobile|Nokia)') {
            rewrite . http://$server_name/wap break;
        }
        rewrite . http://$server_name/pc break;
    }

    location / {
        proxy_pass http://127.0.0.1:8090;
    }
}
```
- 配置详细说明

```bash
#定义Nginx运行的用户和用户组。如果出现403 forbidden (13: Permission denied)错误可将此处设置成启动用户，如root
#user nginx nginx;

#Nginx进程数，建议设置为等于CPU总核心数。
worker_processes 8; #（*）

# 全局错误日志定义类型，[ debug | info | notice | warn | error | crit ]。默认日志路径为/var/log/nginx
#error_log /var/log/nginx/error.log info;

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
}

# load modules compiled as Dynamic Shared Object (DSO)
#
#dso {
#    load ngx_http_fastcgi_module.so; 
#    load ngx_http_rewrite_module.so; # 加载重写模块
#}

# 直接根据流转换（可进行oracle数据映射）。不能使用http模块转换，否则连接时报错ORA-12569包解析出错
stream {
    upstream oracledb {
       hash $remote_addr consistent;
       # oracle数据内网ip（此处还可以通过VPN拨号到此nginx服务器，然后此处填写VPN拨号后的内网ip也可以进行访问）
       server 192.168.0.201:1521;
    }
    server {
        #公网机器监听端口，连接oracle的tns中填公网ip和端口即可
        listen 1521;
        proxy_pass oracledb;
    }
}

# 设定http服务(也支持smtp邮件服务)
http {
    include mime.types; #文件扩展名与文件类型映射表(对应当前目录下文件mime.types)
    default_type application/octet-stream; #默认文件类型
    
    # 日志格式。main为日志格式名称，$remote_addr等都是nginx内置变量
    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';
    
    #charset utf-8; #默认编码
    #server_names_hash_bucket_size 128; #服务器名字的hash表大小
    #client_header_buffer_size 32k; #上传文件大小限制
    #large_client_header_buffers 4 64k; #设定请求缓
    #client_max_body_size 8m; #设定请求缓
    # 开启高效文件传输模式，sendfile指令指定nginx是否调用sendfile函数来输出文件，对于普通应用设为 on，如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。注意：如果图片显示不正常把这个改 成off。
    sendfile on;
    #autoindex on; #开启目录列表访问，合适下载服务器，默认关闭。
    #tcp_nopush on; #防止网络阻塞
    #tcp_nodelay on; #防止网络阻塞
    keepalive_timeout 65; #长连接超时时间，单位是秒

    #FastCGI相关参数是为了改善网站的性能：减少资源占用，提高访问速度。
    #fastcgi_connect_timeout 300;
    #fastcgi_send_timeout 300;
    #fastcgi_read_timeout 300;
    #fastcgi_buffer_size 64k;
    #fastcgi_buffers 4 64k;
    #fastcgi_busy_buffers_size 128k;
    #fastcgi_temp_file_write_size 128k;

    #gzip模块设置
    #gzip on; #开启gzip压缩输出
    #gzip_min_length 1k; #最小压缩文件大小
    #gzip_buffers 4 16k; #压缩缓冲区
    #gzip_http_version 1.0; #压缩版本（默认1.1，前端如果是squid2.5请使用1.0）
    #gzip_comp_level 2; #压缩等级
    # 压缩类型，默认就已经包含text/html，所以下面就不用再写了，写上去也不会有问题，但是会有一个warn。
    #gzip_types text/plain application/x-javascript text/css application/xml;
    #gzip_vary on;
    #limit_zone crawler $binary_remote_addr 10m; #开启限制IP连接数的时候需要使用

    upstream backend {
        #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大。
        server 192.168.80.121:80 weight=3;
        server 192.168.80.122:80 weight=2;
        server 192.168.80.123:80 weight=3;
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

        #日志格式设定
        #log_format access '$remote_addr – $remote_user [$time_local] "d$request" '
        #                  '$status $body_bytes_sent "$http_referer" '
        #                  '"$http_user_agent" $http_x_forwarded_for';
        #定义本虚拟主机的访问日志
        #access_log /var/log/nginx/aezo.cn.access.log main;

        # include /etc/nginx/default.d/*.conf;

        #对 "/" 启用反向代理
        location / {
            proxy_pass http://127.0.0.1:88;
            proxy_redirect off;
            proxy_set_header Host $host;
            #后端的Web服务器可以通过X-Real-IP获取用户真实IP
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            ##以下是一些反向代理的配置，可选
            #client_max_body_size 10m; #允许客户端请求的最大单文件字节数
            #client_body_buffer_size 128k; #缓冲区代理缓冲用户端请求的最大字节数
            # 也可设置到http范围
            #proxy_connect_timeout 90; #nginx跟后端服务器连接超时时间(代理连接超时)
            #proxy_send_timeout 90; #后端服务器数据回传时间(代理发送超时)
            #proxy_read_timeout 90; #连接成功后，后端服务器响应时间(代理接收超时)
            #proxy_buffer_size 4k; #设置代理服务器（nginx）保存用户头信息的缓冲区大小
            #proxy_buffers 4 32k; #proxy_buffers缓冲区，网页平均在32k以下的设置
            #proxy_busy_buffers_size 64k; #高负荷下缓冲大小（proxy_buffers*2）
            #proxy_temp_file_write_size 64k; #设定缓存文件夹大小，大于这个值，将从upstream服务器传
        }

        location ~ .*.(php|php5)?$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi.conf;
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

        #设定查看Nginx状态的地址
        location /nginxStatus {
            stub_status on;
            access_log on;
            # 需要认证
            auth_basic "Hello Nginx";
            auth_basic_user_file conf/htpasswd; #htpasswd文件的内容可以用apache提供的htpasswd工具来产生。
        }

        # 伪静态：用户访问 http://aezo.cn/post1.html，实际访问的是 http://aezo.cn/index.php?p=1
        location / {
            root   D:/wamp/www/aezo;
            index  index.php index.html index.htm;
            rewrite ^(.*)/post(\d+)\.html$ $1/index.php?p=$2 last;
        }

        # 防盗链
        location ~* \.(gif|jpg|jpeg|png|bmp|swf)$ {
            valid_referers none blocked www.aezo.cn blog.aezo.cn;
            if ($invalid_referer) {
                rewrite ^/ http://$host/logo.png;
            }
        }
    }
}
```

## 配置

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
    - `=` 开头表示精确匹配
    - `^~` 开头表示uri以某个常规字符串开头，理解为匹配url路径即可（如果路径匹配那么不测试正则表达式）。nginx不对url做编码，因此请求为`/static/20%/aa`，可以被规则`^~ /static/ /aa`匹配到（注意是空格）
    - 正则匹配
        - `~` 开头表示区分大小写的正则匹配
        - `~*` 开头表示不区分大小写的正则匹配
        - `!~` 开头为区分大小写不匹配的正则
        - `!~*` 开头为不区分大小写不匹配的正则
    - `/` 通用匹配，任何请求都会匹配到
- 多个location配置的情况下匹配顺序为:首先匹配`=`，其次匹配`^~`, 其次是按文件中location的顺序进行正则匹配，最后是交给 / 通用匹配。当有匹配成功时候，停止匹配，按当前匹配规则处理请求。

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

#### proxy缓存功能(`ngx_http_proxy_module`)

- 反向代理时先从nginx缓存中寻找资源，如果缓存中没有则向tomcat请求

```bash
http {
    # 省略其他配置 ...

    ## 配置缓存：缓存的基本上都是静态的东西，动态的插了java代码之类数据缓存后是无法更新的（即如果是jsp等页面会将最终渲染出来的数据进行缓存）
    # 代理临时目录(需要先创建目录`mkdir -p /var/temp/nginx`且nginx用户拥有权限)
    proxy_temp_path /var/temp/nginx/proxy;
    # 代理缓存目录(/var/temp/nginx/proxy_cache)，和proxy_temp_path必须在同一个分区
    # levels指定该缓存空间有两层hash目录，第一层目录名是1个字母或数字长度，第二层目录名为2个字母或数字长度
    # keys_zone=cache_one:50m缓存区名称为cache_one，在内存中的空间是50M，inactive=1d表示1天未被访问的数据将从缓存中删除，max_size指定磁盘空间大小为500M
    proxy_cache_path /var/temp/nginx/proxy_cache levels=1:2 keys_zone=cache_one:50m inactive=1d max_size=500m;
}

server {
    # 给请求响应增加一个头部信息，表示从服务器上返回的cache状态(upstream_cache_status):HIT(命中) | MISS(未命中)
    add_header Nginx-Cache "$upstream_cache_status from $server_addr";

    # 配置缓存内容和缓存的条件（请求static时先从nginx缓存中寻找资源，如果缓存中没有则向tomcat请求）
    location ~ /static(/.*) {
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        # 代理访问后端tomcat(此处如果类似 http://backend$1 则缓存失败)
        proxy_pass http://backend; # backend为upstream服务器集群名

        #指定缓存区域名称，这里的proxy_cache一定是上面的keys_zone（*）
        proxy_cache cache_one;
        #以域名、URI、参数组合成Web缓存的Key值，Nginx根据Key值哈希
        proxy_cache_key $host$uri$is_args$args;
        # 设置状态码为200和304的响应可以进行缓存，并且缓存时间为1天
        proxy_cache_valid 200 304 1d;
        expires 30d;
    }
}
```

#### 清除指定url缓存(`ngx_cache_purge`)

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
# upstream和server平级配置，backend为定义的服务器集群名称
upstream backend {
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
    - tengine的会话保持功能：同一个客户端会话有效期间永远访问的是同一个服务器([ngx_http_upstream_session_sticky_module](http://tengine.taobao.org/document_cn/http_upstream_session_sticky_cn.html))
        - 基于cookies实现
        - 在`upstream`中加入`session_sticky;`

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

- 好处：更方便的插拔模块(yum安装只能使用源默认的模块，nginx同理安装)
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
        --add-module=./ngx_cache_purge-2.3 ## --add-module=./ngx_cache_purge-2.3 # 添加清楚缓存模块
        ```
    - `make && make install`

### 自定义服务

- 方法一 [^3]
    - nginx安装一般会自动注册到服务中取，有些手动安装可能需要自己注册，以nginx手动注册成服务为例
    - 方法：在**`/usr/lib/systemd/system`**路径下创建`755`的文件nginx.service：`sudo vim /usr/lib/systemd/system/nginx.service`，文件内容如下：

        ```bash
        # 服务的说明
        [Unit]
        # 描述服务
        Description=nginx - high performance web server
        # 依赖，当依赖的服务启动之后再启动自定义的服务
        After=network.target remote-fs.target nss-lookup.target

        # 服务运行参数的设置
        [Service]
        # forking是后台运行的形式; oneshot适用于只执行一项任务，随后立即退出的服务
        Type=forking
        # pid存放文件
        # PIDFile=/var/run/nginx.pid
        # 指定当前服务的环境参数文件。该文件内部的key=value键值对
        # EnvironmentFile=-/etc/sysconfig/xxx
        # 为服务的具体运行命令(注意：启动、重启、停止命令全部要求使用绝对路径)
        ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
        # 重启命令
        ExecReload=/usr/local/nginx/sbin/nginx -s reload
        # 停止命令
        ExecStop=/usr/local/nginx/sbin/nginx -s stop
        # 表示给服务分配独立的临时空间
        # PrivateTmp=True

        # 服务安装的相关设置
        [Install]
        # 表示该服务所在的Target，此时为多用户模式下
        WantedBy=multi-user.target
        ```
        - `systemctl daemon-reload` 修改服务配置文件后重新加载
    - 设置开机启动：`systemctl enable nginx`
- 方法二
    - 新建755权限文件`/etc/rc.d/init.d/nginx`，文件内容参考[/data/images/arch/nginx](/data/images/arch/nginx)
        - 注意修改其中`nginx="/opt/soft/tengine-2.1.0/sbin/nginx"`和`NGINX_CONF_FILE="/opt/soft/tengine-2.1.0/conf/nginx.conf"`的配置
    - `chkconfig --add nginx` 将nginx加入到服务列表
    - `chkconfig nginx on` 设置nginx服务开机自启动
    - `systemctl start nginx` 手动启动

## 版本更新变化

- v1.12.1
    - 当访问`http://www.aezo.cn/index.html`不进入对应的页面，而是显示默认的`/usr/share/nginx/html/index.html`。解决办法：注释掉此文件即可



---

参考文章

[^1]: [location配置规则](http://outofmemory.cn/code-snippet/742/nginx-location-configuration-xiangxi-explain)
[^2]: [location配置正则](http://blog.csdn.net/gzh0222/article/details/7845981)
[^3]: [自定义服务](http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-part-two.html)
[^4]: [Nginx的两种认证方式](https://www.cnblogs.com/wangxiaoqiangs/p/6184181.html)