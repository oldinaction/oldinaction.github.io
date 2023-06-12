---
layout: "post"
title: "Wordpress"
date: "2023-05-11 22:59"
categories: [lang]
tags: [Wordpress, php]
---

## wordpress简介

- [官网](https://cn.wordpress.org/)
- [开发者中心](https://developer.wordpress.org/)
    - [主题开发](https://developer.wordpress.org/themes/)
    - [插件开发](https://developer.wordpress.org/plugins/)
- [WordPress主题开发教程手册](https://www.wpzhiku.com/document/theme-handbook/)
- [WordPress插件开发教程手册](https://www.wpzhiku.com/handbook/plugin/)
- 版本
    - v6.1.1 => php7.4、mysql5.7

## 安装

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
- 基于花生壳内网穿透安装
    - 由于花生壳只支持https，因此安装时访问类似 `https://xxx.xxx.xxx/index.php` 此时会重定向到 `http//xxx.xxx.xxx/wp-admin/setup-config.php`，可手动将http改成https再访问
    - 此时显示的页面会出现样式丢失，不用管，安装完成后，在`wp-config.php`中加入`$_SERVER['HTTPS']='on';`即可正常访问
    - 此时只是后台管理端可以访问，但是主页仍然无法方法

## 基础知识

### 本地化

- 为了翻译插件/主题，需要三种类型的 Localiztion 文件
    - POT 文件：包含所有原始字符串的模板文件，主要有`msgid`和`msgstr`字段。每个译员都会将POT文件中的msgid翻译成对应语言并记录到msgstr中，形成PO文件
    - PO 文件：带有一种语言翻译的可编辑文件（每种语言一个文件）
    - MO 文件：PO 文件的编译版本，实际由应用程序使用
- 使用[WP-CLI](https://make.wordpress.org/cli/handbook/installing/)命令生成POT文件
    - `wp i18n make-pot path/to/your-plugin-directory`
- 可使用`msgfmt -o filename.mo filename.po`等方式将po转换成mo
- 使用：在 wp-config.php 中将 WPLANG 定义为您选择的语言，`define ('WPLANG', 'fr_FR');`
- [polylang插件可将文章设置成多语言](https://polylang.pro/)

## 主题

- [国外免费模板](https://www.jojo-themes.net/category/wordpress-themes/)
- [易搜源码](https://www.esoym.com/?s=wp&cat&v=free&paged=1)

### 主题开发

- [开发者中心](https://developer.wordpress.org/)
    - [主题开发](https://developer.wordpress.org/themes/)
    - [API检索](https://developer.wordpress.org/reference/)
- [WordPress主题开发教程手册](https://www.wpzhiku.com/document/theme-handbook/)
- [WordPress插件开发教程手册](https://www.wpzhiku.com/handbook/plugin/)
- [模板标签完整列表](https://developer.wordpress.org/themes/references/list-of-template-tags/)
    - get_header(): 获取头部片段header.php
        - 也支持 `get_header( 'your_custom_template' );` 获取自定义片段文件 `header-{your_custom_template}.php`
    - get_footer
    - get_sidebar
    - get_template_part: 获取模板片段
        - `get_template_part( 'content-templates/content', 'product' );` 会将 `content-templates/content-product.php` 文件包含进当前文件
    - `get_theme_file_uri('images/logo.png')` 获取主题目录所在文件夹下的文件路径(优先使用子主题，找不到则使用父主题)
    - `get_theme_file_path` 同get_theme_file_uri
    - `get_parent_theme_file_uri`
    - `get_parent_theme_file_path`
- [条件标签is_](https://developer.wordpress.org/themes/basics/conditional-tags/)
- wordpress全局属性
    - `$wpdb` 在 wp-includes/load.php 中定义的数据库连接对象

## 常用插件

- `WPS Hide Login` 隐藏登录，可将/wp-admin/路径修改成任意路径，防止被黑
- `Wenprise Pinyin Slug` 自动转换 WordPress 中的中文文章别名、分类项目别名、图片文件名称为汉语拼音

### All-in-One WP Migration

- All-in-One WP Migration(一站式WP迁移): https://cn.wordpress.org/plugins/all-in-one-wp-migration/
- 支持整站备份还原
- 破解大小限制(需要重启php-fpm等)
    - 修改nginx.conf中的`client_max_body_size`参数限制
    - 修改php.ini的`upload_max_filesize`和`post_max_size`的大小限制
    - 修改插件文件(可能无需修改)`constants.php`中的`define( 'AI1WM_MAX_FILE_SIZE', 2 << 28 );`为`define( 'AI1WM_MAX_FILE_SIZE', 1024*1024*1024 );`为1G

## 常用配置

- 设置Gravatar头像加速 https://zmingcx.com/cravatar-replaces-gravatar.html
- 去除路径中的`index.php`：http://www.imwpweb.com/7208.html

## 文件介绍

- `wp-config.php` 主配置文件
    - DB_HOST: 数据库地址和端口，如`localhost:13306`
    - WP_DEBUG: 是否开启Debug模式(错误信息直接显示在页面)
- `http://www.aezo.cn/wp-admin` 登录管理后台

## 数据库表

- wp_commentmeta
- wp_comments
- wp_links
- wp_options 一般存放程序设置、主题设置和绝大多数插件的设置项
    - `_transient_feed_*` Feed内容，`_transient_feed_mod_*` Feed最后更改时间，`_transient_timeout_feed_*` Feed缓存保存期限。这些是WordPress程序中引入RSS Feed后产生的缓存，可通过`DELETE FROM wp_options WHERE option_name REGEXP "_transient_"`进行清除
- wp_postmeta
- wp_posts
- wp_term_relationships
- wp_term_taxonomy
- wp_termmeta
- wp_terms
- wp_usermeta
- wp_users

