---
layout: "post"
title: "powerdesigner"
date: "2017-12-05 19:41"
categories: [design]
tags: [model, mysql, oracle]
---

## 简介

## 使用 [^3]

### 工具箱介绍(Toolbox)

- Standard
    - `Link/Traceablility Link` 可追溯的连接(可用来建立虚拟关联关系)，不会产生外键，显示为虚线箭头(箭头指向为父表)
    - `Note` 备注
- Physical Diagram
    - `Table` 表
    - `View` 视图
    - `Reference` 外键关联，会产生外键

### 表字段编辑

- 表信息字段说明：`Name` 显示的中文名、`Code` 表名、`Comment` 表说明
- 字段信息字段说明：
    - `Name` 显示的中文名(最终为该字段的说明)
    - `Code` 字段名
    - `Comment` 字段备注(不会生成到数据库中)
    - `I`：自增序列
    - `P`：PirmaryKey 主键
    - `F`：ForeignKey 外键
    - `M`：Mandatory 强制要求（不能为空）
- 字段编辑时显示`Comment`字段
    - 表编辑视图 - Columns - Customize Columns and Filter - 勾选Comment的`D`栏
- 显示自增列(mysql, 其他版本参考 [^4]) 
    - 表编辑视图 - Columns - Customize Columns and Filter - 勾选Identity的`D`栏

### 显示设置

- 设置入口：右键 - Display Preference
- 设置表显示字体：Table - Format - Modify - Font - Symbol全选 - 调整字体
- 不显示`<pk>`标识：Table - Columns - 去掉Key indicator勾选

### 根据模型生成表结构

- 配置数据源
    - mysql数据源 [^2]：下载32位mysql odbc安装 - （选择控制面板 - 所有控制面板项 - 管理工具 - 数据源ODBC - 添加mysql） - powerdisigner中的database - connet
- 生成sql语句：database - Generate Database

### 数据字典 [^1]

根据模型生成文档：html、word等

- 常用显示
    - `Table` - `List of Table Columns` 每张表的所有字段
- 右键编辑说明
    - `raise level` 提高级别(目录层级)
    - `layout` 调整表格显示字段和字段占的宽度（如：List of Table Columns中默认显示Name和Code，可以修改此处增加显示Comment）
















---
[^1]: [数据字典生成](http://blog.csdn.net/nw_ningwang/article/details/77586602)
[^2]: [配置mysql数据源](http://blog.csdn.net/winy_lm/article/details/70598378)
[^3]: [PowerDesigner的使用安装和数据库创建](http://www.cnblogs.com/huangcong/archive/2010/06/14/1757957.html)
[^4]: [PowerDesigner中如何生成主键和自增列](https://www.cnblogs.com/ShaYeBlog/p/4067884.html)

