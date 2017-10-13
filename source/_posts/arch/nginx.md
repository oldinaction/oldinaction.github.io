---
layout: "post"
title: "nginx"
date: "2017-01-16 16:54"
categories: [arch]
tags: [nginx]
---

## nginx使用

- 安装
    - `yum install nginx` 安装
        - 默认可执行文件路径`/usr/sbin/nginx`(已加入到系统服务); 配置文件路径`/etc/nginx/nginx.conf`
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
    - `/usr/sbin/nginx -t` 检查配置文件的配置是否合法(也会返回配置文件位置)

## nginx配置(nginx.conf)

- 文件默认是只读的，需要root权限编辑。`sudo vim nginx.conf`
- 配置如下

    ```js
        server {
            # 监听的端口，注意要在服务器后台开启80端口外网访问权限
            listen   80;
            # 服务器的地址              
            server_name www.aezo.cn;

            # 当直接访问www.aezo.cn时, 重定向到http://www.aezo.cn/hello(地址栏url会发生改变)
    		location = / {
    			rewrite / http://$server_name/hello break;
            }

            # 当直接访问www.aezo.cn下的任何地址时，都会转发到http://127.0.0.1:8080下对应的地址(内部重定向，地址栏url不改变)。如http://www.aezo.cn/admin等，会转发到http://127.0.0.1:8080/admin
            # location后的地址可正则
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

## 配置

- 多个server_name
    - `server_name www.aezo.cn baidu.com;`
    - 正则`server_name ~^.+-api-dev\.aezo\.cn$;` 匹配`xxx-api-dev.aezo.cn`

## 匹配规则

- 语法规则： `location [=|~|~*|^~] /uri/ { … }`
    - `=` 开头表示精确匹配
    - `^~` 开头表示uri以某个常规字符串开头，理解为匹配 url路径即可。nginx不对url做编码，因此请求为`/static/20%/aa`，可以被规则`^~ /static/ /aa`匹配到（注意是空格）。
    - `~` 开头表示区分大小写的正则匹配
    - `~*` 开头表示不区分大小写的正则匹配
    - `!~`和`!~*`分别为区分大小写不匹配及不区分大小写不匹配的正则
    - `/` 通用匹配，任何请求都会匹配到。
- 多个location配置的情况下匹配顺序为:首先匹配 =，其次匹配^~, 其次是按文件中顺序的正则匹配，最后是交给 / 通用匹配。当有匹配成功时候，停止匹配，按当前匹配规则处理请求。
- 常用配置
    - 防盗链

        ```txt
        location ~* \.(gif|jpg|swf)$ {
            valid_referers none blocked www.aezo.cn blog.aezo.cn;
            if ($invalid_referer) {
                rewrite ^/ http://$host/logo.png;
            }
        }
        ```
    - 根据文件类型设置过期时间

        ```txt
        location ~* \.(js|css|jpg|jpeg|gif|png|swf)$ {
            if (-f $request_filename) {
            expires 12h;
                break;
            }
        }
        ```
    - 禁止访问某个目录

        ```txt
        location ~* \.(txt|doc)${
            root /home/aezocn/www/doc;
            deny all;
        }
        ```

## 版本更新变化

- v1.12.1
    - 当访问`http://www.aezo.cn/index.html`不进入对应的页面，而是显示默认的`/usr/share/nginx/html/index.html`。解决办法：注释掉此文件即可





---
