---
layout: "post"
title: "Mysql DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [mysql, dba]
---

## 基本

- mysql安装：[http://blog.aezo.cn/2017/01/10/linux/CentOS%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E/](/_posts/linux/CentOS服务器使用说明.md#mysql安装)
- windows安装mysql，千万不要用通过记事本编辑`my.ini`，容易让文件变成BOM格式导致服务无法启动.

### 登录

- Mysql进入系统
	- `mysql -uroot -p` 用户名登陆，输入回车后再输入root密码即可登陆（在cmd中定位到mysql.exe所在目录）
	- `mysql -h 192.168.1.1 -P 3307 -uroot -p my_db_name` 登录并选择数据库
	- `exit`、`quit` 退出

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
grant all privileges on *.* to 'username'@'localhost' identified by 'password'; -- 对'username'@'localhost'操作(无此用户则创建，有则修改密码)，并授本地登录时所有权限（localhost/127.0.0.1则只能本地登录；'username'@'192.168.1.%'表示只能这个网段的机器可以访问；'username'@'%'则可以在任何机器上登录）
grant all privileges on wordpress.* to 'username'@'localhost' identified by 'password'; -- 授予wordpress数据库下所有权限（相当于Navicat上面管理用户：服务器权限Tab不勾选；权限Tab中数据填wordpress，权限类型都勾选）
grant select,insert,update,delete on mydb.* to my_admin@localhost identified by "aezocn" -- 创建一个用户my_admin/aezocn，让他只可以在localhost上登录，并对数据库mydb有查询、插入、修改、删除的权限
flush privileges; -- 刷新权限(grant之后必须执行)

evoke all privileges on *.* from 'username'@'localhost'; -- 撤销用户授权
select user, host from user; -- 查询用户可登录host
```

## 数据备份/恢复

### 导出导入

- 使用`mysqldump/source`方法进行导出导入：15分钟导出1.6亿条记录，导出的文件中平均7070条记录拼成一个insert语句；通过source进行批量插入，导入1.6亿条数据耗时将近5小时，平均速度3200W条/h（网测）
- **导出整个数据库** `%MYSQL_HOME%/bin/mysqldump -h 192.168.1.1 -P 3306 -uroot -p my_db_name > d:/exp.sql` (回车后输入密码)
	- 默认导出表结构和数据，text格式数据也能被导出。测试样例：36M数据导出耗时15s
	- 只导出数据库表结构 `mysqldump -h localhost -P 3306 -uroot -p -d --add-drop-table my_db_name > d:/exp.sql` (-d 没有数据 --add-drop-table 在每个create语句之前增加一个drop table)
	- 导出一张表 `mysqldump -h localhost -P 3306 -uroot -p my_db_name my_table_name > d:/exp.sql`
	- 压缩备份 `mysqldump -h localhost -P 3306 -uroot -p my_db_name | gzip > d:/mysql_bak.$(date +%F).sql.gz`
	- 参数
		- `-h`默认为本地
		- `-P`默认为3306
- 导入数据
	- `mysql -h localhost -P 3306 -uroot -p my_db_name < d:/exp.sql` 直接CMD命令行导入
	- source方式. Navicat命令行使用source报错，且通过界面UI界面导入数据也容易出错。建议到mysql服务器命令行导入
		- 命令行登陆用户 `mysql -uroot -p`
		- 选择数据库 `use my_db_name`
		- 执行导入 `source d:/exp.sql`

### 主从同步

change master to master_host='127.0.0.1', master_port=3306, master_user='rep', master_password='Hello1234!', master_log_file='shipbill-log-bin.000001', master_log_pos=154;



## 管理员

### 配置

- mysql在windows系统下安装好后，默认是对表名大小写不敏感的。但是在linux下，一些系统需要手动设置：打开并修改`/etc/my.cnf`在`[mysqld]`节点下，加入一行： 		`lower_case_table_names=1`(表名大小写：0是大小写敏感，1是大小写不敏感)。重启mysql服务`systemctl restart mysqld`
- mysql服务器编码问题
	- 保存到数据库编码错误：1.编辑器编码(复制的代码要注意原始代码格式) 2.数据库/表/字段编码 3.服务器编码
	- 查看服务器编码`show variables like '%char%';`，如果`character_set_server=latin1`就说明有问题(曾经因为这个问题遇到这么个场景：此数据库下大部分表可以正常插入中文，但是有一张表的一个字段死活插入乱码，当尝试修改java代码中此sql语句的另外几个传入参数并连续插入两次可以正常插入，不产生乱码。此情景简直可以怀疑人生，最终修改character_set_server后一切正常)
	- 修改character_set_server编码：linux修改`/etc/my.cnf`，在`[mysqld]`节点下加入一行`character-set-server=utf8`，重启mysqld服务

### 查询

- `show variables like '%dir%';` 查看mysql相关文件(数据/日志)存放位置
	- 数据文件(datadir)默认位置：`/var/lib/mysql`
- `show variables like 'autocommit';`
	- MySQL默认操作模式就是autocommit自动提交模式(ON/1)
	- 这就表示除非显式地开始一个事务(mysql> `set autocommit=0;`)，否则每个查询都被当做一个单独的事务自动执行。当mysql> `commit;`之后则又回到自动提交模式
- 查看数据库大小
	- InnoDB存储引擎将表保存在一个表空间内，该表空间可由数个文件创建。表空间的最大容量为64TB
	- MySQL单表大约在2千万条记录(4G)下能够良好运行，经过数据库的优化后5千万条记录(10G)下运行良好

	```sql
	use information_schema;
	-- 查询所有数据大小
	select concat(round(sum(data_length/1024/1024),2),'MB') as data from tables;
	-- 查看指定数据库大小
	select concat(round(sum(data_length/1024/1024),2),'MB') as data from tables where table_schema='my_db_name';
	-- 查看表数据大小
	select concat(round(sum(data_length/1024/1024),2),'MB') as data from tables where table_schema='my_db_name' and table_name='my_table_name';

	-- 查看指定数据库数据大小
	select 
	table_schema as '数据库',
	sum(table_rows) as '记录数',
	sum(truncate(data_length/1024/1024, 2)) as '数据容量(MB)',
	sum(truncate(index_length/1024/1024, 2)) as '索引容量(MB)'
	from information_schema.tables
	where table_schema='mysql';

	-- 查看指定数据库各表容量大小
	select 
	table_schema as '数据库',
	table_name as '表名',
	table_rows as '记录数',
	truncate(data_length/1024/1024, 2) as '数据容量(MB)',
	truncate(index_length/1024/1024, 2) as '索引容量(MB)'
	from information_schema.tables
	where table_schema='mysql'
	order by data_length desc, index_length desc;


	-- 查看所有数据库数据大小(比较耗时)
	select 
	table_schema as '数据库',
	sum(table_rows) as '记录数',
	sum(truncate(data_length/1024/1024, 2)) as '数据容量(MB)',
	sum(truncate(index_length/1024/1024, 2)) as '索引容量(MB)'
	from information_schema.tables
	group by table_schema
	order by sum(data_length) desc, sum(index_length) desc;

	-- 查看所有数据库各表数据大小
	select 
	table_schema as '数据库',
	table_name as '表名',
	table_rows as '记录数',
	truncate(data_length/1024/1024, 2) as '数据容量(MB)',
	truncate(index_length/1024/1024, 2) as '索引容量(MB)'
	from information_schema.tables
	order by data_length desc, index_length desc;
	```

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


