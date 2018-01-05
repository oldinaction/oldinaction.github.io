---
layout: "post"
title: "Mysql DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [mysql, dba]
---

## 基本

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

- 创建用户并设置权限 `grant all privileges on *.* to 'admin'@'localhost' identified by 'pass' with grant option;`(创建了一个admin/pass只能本地连接的超级用户)
- 删除用户：`delete from user where user = '用户名';`(删除系统mysql表中的记录)
- 修改用户名和密码
	- `update user set user='smalle' where user='root';`
	- `SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root');`
- 创建数据库：`create database 库名;`

## 权限

- `grant select,insert,update,delete on mydb.* to my_admin@localhost identified by "aezocn"` 创建一个用户my_admin/aezocn，让他只可以在localhost上登录，并对数据库mydb有查询、插入、修改、删除的权限(如果有此用户？如果密码不对？)
- `grant all on *.* to my_admin@"%" identified by "aezocn"` 创建一个用户my_admin/aezocn，让他可以在任何主机上登录，并对所有数据库有所有权限

## 数据备份/导入

- 导入数据：`登陆用户->选择数据库->source h:/demo/sqltest.sql`

### 其他

- 命令行执行sql
	- Mysql通过上下左右按键修改语句
	- 或者新建一个文本文件h:/demo/test.sql，将sql语句放在文件中，再在命令行输入`\. h:/demo/test.sql` 其中`\.`相当于`source`，末尾不要分号
	- Oracle输入ed则打开记事本可进行修改修改DOS中的数据