---
layout: "post"
title: "powerdesigner"
date: "2017-12-05 19:41"
categories: extend
tags: [model, mysql, oracle]
---

## 简介

- Powerdesigner v16.5

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
    - 表编辑视图 - Columns -> Customize Columns and Filter -> 勾选Comment的`D`栏
- 显示自增列(mysql, 其他版本参考 [^4]) 
    - 表编辑视图 -> Columns -> Customize Columns and Filter -> 勾选Identity的`D`栏

### 显示设置

- 设置入口：右键 -> Display Preference
- 设置表显示字体：Table -> Format -> Modify -> Font -> Symbol全选 -> 调整字体
- 不显示`<pk>`标识：Table -> Columns -> 去掉Key indicator勾选
- 显示code栏：Table -> Contents -> Advanced -> Columns -> List Columns -> Select图标 -> 勾选code的D栏

### 根据模型生成表结构

- 配置数据源
    - mysql数据源 [^2]：下载32位mysql odbc安装 -> （选择控制面板 -> 所有控制面板项 -> 管理工具 -> 数据源ODBC -> 添加mysql） -> powerdisigner中的database -> connet
- **生成sql语句**：database -> Generate Database
- mysql相关设置
    - 生成sql语句带有comment字段 [^5]
        - database -> edit current dbms -> Script -> Objects -> Column -> Add -> 设置value为`%20:COLUMN% [%National%?national ]%DATATYPE%[%Unsigned%? unsigned][%ZeroFill%? zerofill][ [.O:[character set][charset]] %CharSet%][.Z:[ %NOTNULL%][%IDENTITY%? auto_increment:[ default %DEFAULT%]][ comment %.q:COMMENT%]]`
        - database -> Generate Database -> Options -> 勾选Column下的Comment
        - database -> Generate Database -> Format -> 勾选Generate name in empty comment(将注释为空的字段用name代替注释)
- oracle相关设置
    - 生成sql语句字段大写 [^6]
        - Database -> edit current dbms -> Script -> Sql -> Format -> UpperCaseOnly设为Yes
        - Database -> edit current dbms -> Script -> Sql -> Format -> CaseSensitivityUsingQuote设为No
    - database -> Generate Database -> Objects -> Table/Sequence -> Drop的value设为`-- drop table [%QUALIFIER%]%TABLE% [cascade constraints]`(oracle drop时，如果表不存在会报错)
    - sql语句的生成还和Table Properties -> More -> Pyhsical Options -> 右边窗口中的物理结果配置相关
    
### 数据字典 [^1]

根据模型生成文档：html、word等

- 常用显示
    - `Table` - `List of Table Columns` 每张表的所有字段
- 右键编辑说明
    - `raise level` 提高级别(目录层级)
    - `layout` 调整表格显示字段和字段占的宽度（如：List of Table Columns中默认显示Name和Code，可以修改此处增加显示Comment）

## 建表说明

- 需要定义完整的Code/Data Type/Length/Default Value等字段
- 表名小写下划线命名，以`t_`等开头，可通过`MyBatis Generator`生成实体时去掉前缀
- Mysql字段名主键最好使用`id`，在通过`MyBatis Generator`生成Mapper时可统一生成主键自增语句(且最好将数据库中此字段设为自增)
- Oracle为每张表创建序列完成主键自增。在`Model-Sequence`中，第一次保存后再在视图中打开可设置起始值1，递增值1，缓存100个，最大9999999999999999999999999999等参数。再配合触发器或mybatis的获取序列值语句进行id赋值
- Mysql
    - 常用字段类型

    字段名 | 类型 | Java类型 | 说明
    ---------|----------|----------|---------
    id | bigint(20) | Long | **主键统一设成id, 方便`MyBatis Generator`生成自增语句**
    name| varchar(60) | String | 
    notes | varchar(255) | String | 描述(description是oracle的保留字)
    valid_status | int(1) | Integer | 默认值1
    create_time | datetime | Date | 默认值CURRENT_TIMESTAMP
    money | decimal(20, 6) | BigDecimal | 

- Oracle
    - 常用字段类型

    字段名 | 类型 | Java类型 | 说明
    ---------|----------|----------|---------
    id | number(20) | Long | 
    name| varchar(60) | String | 
    notes | varchar(255) | String | 描述(**description是oracle的保留字**)
    valid_status | int(1) | Integer | 默认值1
    create_time | Date | Date | 默认值SYSDATE
    money | Number(20, 6) | BigDecimal | 
    
    - 表名不要命名为`USER`等，`USER`为关键字导入到数据库后，plsql无法drop此表(可以通过navicat删除)
    - oracle表名命名为`T_USER`，在`mybatis generator`生成的时候就算model转换成`User`，也会生成出错
    

---

参考文章

[^1]: [数据字典生成](http://blog.csdn.net/nw_ningwang/article/details/77586602)
[^2]: [配置mysql数据源](http://blog.csdn.net/winy_lm/article/details/70598378)
[^3]: [PowerDesigner的使用安装和数据库创建](http://www.cnblogs.com/huangcong/archive/2010/06/14/1757957.html)
[^4]: [PowerDesigner中如何生成主键和自增列](https://www.cnblogs.com/ShaYeBlog/p/4067884.html)
[^5]: [PowerDesigner生成mysql字段comment注释](https://blog.csdn.net/yh88356656/article/details/49148061)
[^6]: [为什么在powerdesigner成功将表生成到oracle，用sql操作提示表或视图不存在](https://www.cnblogs.com/liuhaixu/p/3659126.html)
