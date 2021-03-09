---
layout: "post"
title: "powerdesigner"
date: "2017-12-05 19:41"
categories: extend
tags: [model, mysql, oracle, design]
---

## 简介

- Powerdesigner v16.6 x64(连接oracle最好使用64位)

## 使用 [^3]

### 工具箱介绍(Toolbox)

- Standard
    - `Link/Traceablility Link` 可追溯的连接(可用来建立虚拟关联关系)，不会产生外键，显示为虚线箭头(箭头指向为父表)
    - `Note` 备注
- Physical Diagram
    - `Table` 表
    - `View` 视图
    - `Reference` 外键关联，会产生外键
- Architecture Areas(架构模块)：创建Areas - 将关联的表加入到其Attached Objects中 - Areas名称会自动显示在区域最上方 - 最后在进行排版

### 表字段编辑

- 表信息字段说明：`Name` 显示的中文名、`Code` 表名、`Comment` 表说明
- 字段信息字段说明：
    - `Name` 显示的中文名(最终为该字段的说明)
    - `Code` 字段名
    - `Comment` 字段备注(不会生成到数据库中)
    - `D`(Displayed) 是否展示在类图上
    - `I`：自增序列(mysql可以勾选)
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
- 表显示表名和表备注：General - Display - Code显示表名；Table - Content - Comments显示表备注
- 显示commets：执行脚本把name的替换成commet的值(comment为空则取code，否则截取`。：（(`前的字符串)，脚本如下(Tools>Execute Commands>Edit/Run Script运行)

    ```vb
    Option   Explicit   
    ValidationMode   =   True   
    InteractiveMode   =   im_Batch
    Dim blankStr
    blankStr   =   Space(1)
    Dim   mdl   '   the   current   model  
    '   get   the   current   active   model   
    Set   mdl   =   ActiveModel   
    If   (mdl   Is   Nothing)   Then   
          MsgBox   "There   is   no   current   Model "   
    ElseIf   Not   mdl.IsKindOf(PdPDM.cls_Model)   Then   
          MsgBox   "The   current   model   is   not   an   Physical   Data   model. "   
    Else   
          ProcessFolder   mdl   
    End   If  
      
    Private   sub   ProcessFolder(folder)   
    On Error Resume Next  
          Dim   Tab   'running     table   
          for   each   Tab   in   folder.tables   
                if   not   tab.isShortcut   then   
                      tab.name   =   tab.comment  
                      Dim   col   '   running   column   
                      for   each   col   in   tab.columns   
                      'comment为空则取code。否则截取。：（(前的字符串
                      if col.comment = "" or replace(col.comment," ", "") = "" Then
                            col.name = col.code
                      ElseIf InStr(1, col.comment, "。") >= 1 Then
                        col.name = Left(col.comment, InStr(1, col.comment, "。")-1)
                      ElseIf InStr(1, col.comment, "：") >= 1 Then
                        col.name = Left(col.comment, InStr(1, col.comment, "：")-1)
                      ElseIf InStr(1, col.comment, "（") >= 1 Then
                        col.name = Left(col.comment, InStr(1, col.comment, "（")-1)
                      ElseIf InStr(1, col.comment, "(") >= 1 Then
                        col.name = Left(col.comment, InStr(1, col.comment, "(")-1)
                      else  
                            col.name = col.comment
                      end if
                      next  
                end   if   
          next  
      
          Dim   view   'running   view   
          for   each   view   in   folder.Views   
                if   not   view.isShortcut   then   
                      view.name   =   view.comment   
                end   if   
          next  
      
          '   go   into   the   sub-packages   
          Dim   f   '   running   folder   
          For   Each   f   In   folder.Packages   
                if   not   f.IsShortcut   then   
                      ProcessFolder   f   
                end   if   
          Next   
    end   sub
    ```

### 根据模型生成表结构

- 配置数据源
    - mysql数据源 [^2]：下载32位mysql odbc安装 -> （选择控制面板 -> 所有控制面板项 -> 管理工具 -> 数据源ODBC -> 添加mysql） -> powerdisigner中的database -> connet
- **生成sql语句**：database -> Generate Database
- mysql相关设置
    - 生成sql语句带有comment字段 [^5]
        - database -> edit current dbms -> Script -> Objects -> Column -> Add -> 设置value为`%20:COLUMN% [%National%?national ]%DATATYPE%[%Unsigned%? unsigned][%ZeroFill%? zerofill][ [.O:[character set][charset]] %CharSet%][.Z:[ %NOTNULL%][%IDENTITY%? auto_increment:[ default %DEFAULT%]][ comment %.q:COMMENT%]]`(修改后报错)
        - database -> Generate Database -> Options -> 勾选Column下的Comment
        - database -> Generate Database -> Format -> 勾选Generate name in empty comment(将注释为空的字段用name代替注释)
- oracle相关设置
    - 生成sql语句字段大写 [^6]
        - Database -> edit current dbms -> Script -> Sql -> Format -> UpperCaseOnly设为Yes
        - Database -> edit current dbms -> Script -> Sql -> Format -> CaseSensitivityUsingQuote设为No
    - Database -> edit current dbms -> Script -> Objects -> Table/Sequence -> Drop的value设为`-- drop table [%QUALIFIER%]%TABLE% [cascade constraints]`(oracle drop时，如果表不存在会报错)
    - sql语句的生成还和Table Properties -> More -> Pyhsical Options -> 右边窗口中的物理结果配置相关

### 反向生成/更新模型

- 连接数据步骤参考[根据模型生成表结构](#根据模型生成表结构)
- 创建一个空的PDM模型
- 选择 **Database - Update Model from Database** - 确定Useing DataSource - 输入连接账号密码 - 进入Table选择 - 点击右上角Deselect All先去掉勾选 - 再选择需要更新的表
    - 更新模型也可以，不会打乱现有排版
    - 更新后如果Code和数据库字段名相同，则不会覆盖name；其他属性会全部覆盖掉。如果模型中的字段Code数据库中没有也不会删除

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
    id | number(18) | Long | 
    name| varchar(60) | String | 
    notes | varchar(255) | String | 描述(**description是oracle的保留字**)
    valid_status | number(5) | Integer | 默认值1
    create_time | Date | Date | 默认值SYSDATE
    money | Number(20, 6) | BigDecimal | 
    
    - 表名不要命名为`USER`等，`USER`为关键字导入到数据库后，plsql无法drop此表(可以通过navicat删除)
    - oracle表名命名为`T_USER`，在`mybatis generator`生成的时候就算model转换成`User`，也会生成出错
    

---

参考文章

[^1]: http://blog.csdn.net/nw_ningwang/article/details/77586602 (数据字典生成)
[^2]: http://blog.csdn.net/winy_lm/article/details/70598378 (配置mysql数据源)
[^3]: http://www.cnblogs.com/huangcong/archive/2010/06/14/1757957.html (PowerDesigner的使用安装和数据库创建)
[^4]: https://www.cnblogs.com/ShaYeBlog/p/4067884.html (PowerDesigner中如何生成主键和自增列)
[^5]: https://blog.csdn.net/yh88356656/article/details/49148061 (PowerDesigner生成mysql字段comment注释)
[^6]: https://www.cnblogs.com/liuhaixu/p/3659126.html (为什么在powerdesigner成功将表生成到oracle，用sql操作提示表或视图不存在)
