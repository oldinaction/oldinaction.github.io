---
layout: "post"
title: "NodeJS相关资源"
date: "2020-04-18 18:28"
categories: [service]
tags: [nodejs]
---

## strapi (CMS后台框架)

- [strapi](https://strapi.io/)、[github](https://github.com/strapi/strapi/)
- strapi是一个非常方便创建CMS(内容管理系统)的后台框架
- 使用流程
    - 使用strapi生成项目，默认使用SQLite数据库(也可设置成Mysql等数据库)
    - 通过管理后台设置用户、权限，创建内容表及其字段，字段支持多种类型，还可设置一对一、一对多的关联关系
    - 创建内容表数据，也支持文件上传
    - 通过api访问/操作资源。系统只有一个默认的前台(http://localhost:1337/)，前台一般通过其他方式实现
- 安装

```bash
# 要求
nodejs v12.x
npm v6.x

# 创建项目
npx create-strapi-app my-project --quickstart # npx为npm中的工具
# cnpm install # 可手动安装依赖。在管理后台安装插件有时候会失败，从而导致安装的依赖被删除，所有需要手动重新安装依赖
# 启动项目
npm run develop
# 访问后台 http://localhost:1337/admin
```
- 使用
    - 在后台创建COLLECTION TYPES的表名和字段名，如表名`article`。默认Public无访问资源权限，需设置相应权限
    - 在角色权限中设置Public的权限：设置对article资源有查询权限(find)，从而可访问端点 http://localhost:1337/articles




