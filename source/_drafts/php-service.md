---
layout: "post"
title: "PHP相关框架"
date: "2022-11-18 19:10"
categories: arch
---

## wordpress

- [官网](https://cn.wordpress.org/)
    - v6.1.1 => php7.4、mysql5.7

### 安装

- php环境安装参考[php.md#安装](/_posts/lang/php.md#安装)
- wordpress安装略

```bash
# 上传后修改文件属性
chmod -R 775 /wwwroot/www/aezo.cn
chmod -R 777 /wwwroot/www/aezo.cn/wp-content
chown -R www: /wwwroot/www/aezo.cn

# 安装时数据地址可为: 127.0.0.1:13306 有可能localhost不行

# 安装完修改wp-config.php, 在末尾增加, 否则安装插件时提示需要配置FTP来访问服务器文件夹
'''
define("FS_METHOD", "direct");
define("FS_CHMOD_DIR", 0777);
define("FS_CHMOD_FILE", 0777);
'''
```

### 模板

- [国外免费模板](https://www.jojo-themes.net/category/wordpress-themes/)
- [易搜源码](https://www.esoym.com/?s=wp&cat&v=free&paged=1)

### 常用插件

- WPS隐藏登录
    - 可将/wp-admin/路径修改成任意路径，防止被黑
- Wenprise Pinyin Slug
    - 自动转换 WordPress 中的中文文章别名、分类项目别名、图片文件名称为汉语拼音。

#### All-in-One WP Migration

- All-in-One WP Migration(一站式WP迁移): https://cn.wordpress.org/plugins/all-in-one-wp-migration/
- 支持整站备份还原
- 破解大小限制(需要重启php-fpm等)
    - 修改nginx.conf中的`client_max_body_size`参数限制
    - 修改php.ini的`upload_max_filesize`和`post_max_size`的大小限制
    - 修改插件文件(可能无需修改)`constants.php`中的`define( 'AI1WM_MAX_FILE_SIZE', 2 << 28 );`为`define( 'AI1WM_MAX_FILE_SIZE', 1024*1024*1024 );`为1G

### 常用配置

- 设置Gravatar头像加速 https://zmingcx.com/cravatar-replaces-gravatar.html

### 文件介绍

- `wp-config.php` 主配置文件
    - DB_HOST: 数据库地址和端口，如`localhost:13306`
    - WP_DEBUG: 是否开启Debug模式(错误信息直接显示在页面)
- `http://www.aezo.cn/wp-admin` 登录管理后台

### 数据库表

wp_commentmeta
wp_comments
wp_links
wp_options
wp_postmeta
wp_posts
wp_term_relationships
wp_term_taxonomy
wp_termmeta
wp_terms
wp_usermeta
wp_users

### 常见业务及问题

- 去除路径中的`index.php`：http://www.imwpweb.com/7208.html

## xunruicms

- 安装

```bash
# http://localhost/test.php

# 设置读写权限: http://help.xunruicms.com/380.html
chmod 777 -R cache
chmod 777 -R public/uploadfile
chmod 777 -R config

# 需支持后台管理界面编辑模板时需要
chmod 777 -R template
chmod 777 -R public/static
# 上传会员头像时需要
chmod 777 -R public/api/member

# php_zip模块安装，参考[php-zip模块安装](/_posts/lang/php.md#php-zip模块安装)
```
- 开发期间(如在管理后台安装插件)

```bash
chmod 777 -R dayrui/App

# 安装时可先查看插件的文件结构，从而设置对应目录权限。如官方内容系统插件，还需设置以下目录
'''
chmod 777 -R dayrui/Fcms
chmod 777 -R dayrui/My
chmod 777 -R public/mobile
'''

# 安装完成(线上环境还原目录权限)
chmod 755 -R dayrui/App
```



