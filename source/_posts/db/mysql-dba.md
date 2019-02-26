---
layout: "post"
title: "Mysql DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [mysql, dba]
---

## 基本

- mysql在windows系统下安装好后，默认是对表名大小写不敏感的。但是在linux下，一些系统需要手动设置：打开并修改`/etc/my.cnf`在`[mysqld]`节点下，加入一行： `lower_case_table_names=1`(0是大小写敏感，1是大小写不敏感)。重启mysql服务`systemctl restart mysqld`
- mysql服务器编码问题
	- 保存到数据库编码错误：1.编辑器编码(复制的代码要注意原始代码格式) 2.数据库/表/字段编码 3.服务器编码
	- 查看服务器编码`show VARIABLES like '%char%';`，如果`character_set_server=latin1`就说明有问题(曾经因为这个问题遇到这么个场景：此数据库下大部分表可以正常插入中文，但是有一张表的一个字段死活插入乱码，当尝试修改java代码中此sql语句的另外几个传入参数并连续插入两次可以正常插入，不产生乱码。此情景简直可以怀疑人生，最终修改character_set_server后一切正常)
	- 修改character_set_server编码：linux修改`/etc/my.cnf`，在`[mysqld]`节点下加入一行`character-set-server=utf8`，重启mysqld服务

### 登录

- Mysql进入系统
	- 普通登陆法一：将mysql.exe所在的目录放在path的环境变量中，再打开cmd，输入mysql回车即可
	- 普通登陆法二：在cmd中定位到mysql.exe所在目录，再输入mysql回车如果出现"Welcome to the MySQL monitor."和"mysql->"的字样，即表示登陆成功。
	- 用户名登陆：将mysql.exe所在的目录放在path的环境变量中，再打开cmd，输入mysql -h 127.0.0.1 -u root -p回车后再输入密码root即可登陆
	- 用户名登陆并选择数据库简写：mysql -h服务器地址 -u用户名 -p密码 数据库名（-p和密码之间不能有空格；-h和-u有无空格均可；如果在本地-h可以省略；此时也可以不选择数据库(登陆进去后用 use 数据库名;选择)；末尾不能有分号）
	- 退出：quit或者exit(后面加不加分号都行)
- Oracle进入系统(scott/tigger)
	- 将用户当成超级管理员登陆到服务器：`sqlplus 用户名/密码 as sysdba`(或者`sqlplus / as sysbda`以管理员登录)
	- 解锁用户：`alter user 用户名 account unlock;`
	- 可切换用户登陆：`conn 用户名/密码 <as sysdba>`
	- 退出：`exit`、`quit`（或者`Ctrl+C`）
	- 利用sqlplus登陆，直接输入sqlplus回车，再输入用户名、密码
	- 给予用户授权创建表和视图：先以超级管理员登陆。再`grant creat table, creat view to 用户名;`回车。在重新登陆用户
	- 进入系统后，输入`ed`，将DOS中的数据展示到记事本上

### 创建删除用户

```sql
-- 创建用户基本操作
grant all privileges on *.* to 'admin'@'localhost' identified by 'pass' with grant option; -- 创建了一个admin/pass只能本地连接的超级用户

use mysql
update user set user='smalle' where user='root';
set password for 'root'@'localhost' = password('root'); -- 5.6版本更新用户
update user set authentication_string = password("root") where user='root'; -- 5.7版本更新用户
update user set host='%' where user='root';
delete from user where user = '用户名'; -- 删除用户。删除系统mysql表中的记录
-- 修改完成后需要重启数据库

create database my_test; -- 创建数据库
```

## 权限

```sql
-- 创建用户并授权
create user username identified by 'password'; -- 默认创建一个'username'@'%'的用户
grant all privileges on *.* to 'username'@'%'; -- 给此'username'@'%'用户授权
grant all privileges on *.* to 'username'@'localhost' identified by 'password'; -- 对'username'@'localhost'操作(无此用户则创建，有则修改密码)，并授本地登录时所有权限（localhost/127.0.0.1则只能本地登录；'username'@'192.168.1.1'表示只能这个ip访问；%则可以再任何机器上登录）
grant all privileges on wordpress.* to 'username'@'localhost' identified by 'password'; -- 授予wordpress数据库下所有权限（相当于Navicat上面管理用户：服务器权限Tab不勾选；权限Tab中数据填wordpress，权限类型都勾选）
grant select,insert,update,delete on mydb.* to my_admin@localhost identified by "aezocn" -- 创建一个用户my_admin/aezocn，让他只可以在localhost上登录，并对数据库mydb有查询、插入、修改、删除的权限
flush privileges; -- 刷新权限(grant之后必须执行)

evoke all privileges on *.* from 'username'@'localhost'; -- 撤销用户授权
select user, host from user; -- 查询用户可登录host
```

## 数据备份/导入

- 导入数据：`命令行登陆用户 -> 选择数据库 -> source h:/demo/sqltest.sql`

## 其他

- 命令行执行sql
	- Mysql通过上下左右按键修改语句
	- 或者新建一个文本文件h:/demo/test.sql，将sql语句放在文件中，再在命令行输入`\. h:/demo/test.sql` 其中`\.`相当于`source`，末尾不要分号
	- Oracle输入ed则打开记事本可进行修改修改DOS中的数据
- Oracle表结构与Mysql表结构转换：使用navicat转换
	- 点击`工具 -> 数据转换`。左边选择oracle数据库和对应的用户，右边转成sql文件(直接转换会出现Date转换精度错误)
	- 将sql文件中的数据进行转换
		- `datetime(7)` -> `datetime(6)`
		- `decimal(20,0)` -> `bigint(20)`(原本在oracle中是Number(20))
		- `decimal(1,0)` -> `int(1)`
		- `decimal(10,0)` -> `int(10)` 以此类推
		- 默认值丢失
	- 导入sql文件到mysql数据库中


