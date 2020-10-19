---
layout: "post"
title: "Mysql DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [mysql, dba]
---

## 基本

- mysql 安装：[http://blog.aezo.cn/2017/01/10/linux/CentOS%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E/](/_posts/linux/CentOS服务器使用说明.md#mysql安装)
- windows 安装 mysql，千万不要用通过记事本编辑`my.ini`，容易让文件变成 BOM 格式导致服务无法启动.
- 查看系统版本：命令行登录后欢迎信息中有版本信息，或者登录仅命令行执行`status`查看

### 登录

- Mysql 进入系统 - `mysql -uroot -p` 用户名登陆，输入回车后再输入 root 密码即可登陆（在 cmd 中定位到 mysql.exe 所在目录） - `mysql -h 192.168.1.1 -P 3307 -uroot -p my_db_name` 登录并选择数据库 - `exit`、`quit` 退出
- 忘记 root 密码 - `my.ini`配置文件的`[mysqld]`下增加`skip-grant-tables`参数，重启数据库 - 修改`mysql.user`中该用户的密码 - 去掉启动参数重新启动

### 创建删除用户

```sql
-- 创建用户基本操作（对于项目级别用户可对每个数据库进行控制，并去掉Grant权限，即去掉查看当前数据库用户列表权限）
grant all privileges on *.* to 'admin'@'localhost' identified by 'pass' with grant option; -- 创建了一个admin/pass只能本地连接的超级用户

use mysql
update user set user='smalle' where user='root';
set password for 'root'@'localhost' = password('root'); -- 5.6版本更新用户
update user set authentication_string = password("root") where user='root'; -- 5.7版本更新用户
-- 或者 alter user user() identified by "123456";
update user set host='%' where user='root';
delete from user where user = '用户名'; -- 删除用户。删除系统mysql表中的记录
-- 刷新数据
flush privileges;

create database my_test; -- 创建数据库
```

## 权限

```sql
-- 创建用户并授权
create user username identified by 'password'; -- 默认创建一个'username'@'%'的用户

-- 给此'username'@'%'用户授所有数据库所有表权限。但是不包含grant权限
grant all privileges on *.* to 'username'@'%';
grant all privileges on *.* to 'username'@'localhost' identified by 'password'; -- 对'username'@'localhost'操作(无此用户则创建，有则修改密码)，并授本地登录时所有权限（localhost/127.0.0.1则只能本地登录；'username'@'192.168.1.%'表示只能这个网段的机器可以访问；'username'@'%'则可以在任何机器上登录）
grant all privileges on wordpress.* to 'username'@'localhost' identified by 'password'; -- 授予wordpress数据库下所有权限（相当于Navicat上面管理用户：服务器权限Tab不勾选；权限Tab中数据填wordpress，权限类型都勾选）
-- 创建一个用户my_admin/aezocn，让他只可以在localhost上登录，并对数据库mydb有查询、插入、修改、删除的权限
grant select,insert,update,delete on mydb.* to my_admin@localhost identified by "aezocn";
-- test可以查询 testdb 中的表
grant select on testdb.* to test@localhost;
-- 作用在单个数据表上
grant select, insert, update, delete on testdb.orders to test@localhost;

revoke all privileges on *.* from 'username'@'localhost'; -- 撤销用户授权
revoke select on testdb.* from 'username'@'%';

flush privileges; -- 刷新权限(grant之后必须执行)

select user, host from user; -- 查询用户可登录host
```

## 数据备份/恢复

- `mysqldump` 是一款 mysql 逻辑备份的工具，它将数据库里面的对象(表)导出作为 SQL 脚本文件。对于导出几个 G 的数据库，还是不错的；一旦数据量达到几十上百 G，无论是对原库的压力还是导出的性能都存在问题 [^2]
- `Xtrabackup` 是由 percona 开源的免费数据库热备份软件，它能对 InnoDB 数据库和 XtraDB 存储引擎的数据库非阻塞地备份。对于较大数据的数据库可以选择`Percona-Xtrabackup`备份工具，可进行全量、增量、单表备份和还原
- `mariadb10.3.x`及以上的版本用 Percona XtraBackup 工具会有问题，此时可以使用`mariabackup`，它是 MariaDB 提供的一个开源工具

### 导出导入

- 使用`mysqldump/source`方法进行导出导入：15 分钟导出 1.6 亿条记录，导出的文件中平均 7070 条记录拼成一个 insert 语句；通过 source 进行批量插入，导入 1.6 亿条数据耗时将近 5 小时，平均速度 3200W 条/h（网测）
- **导出整个数据库** `%MYSQL_HOME%/bin/mysqldump -h 192.168.1.1 -P 3306 -uroot -p my_db_name > d:/exp.sql` (回车后输入密码) - 默认导出表结构和数据，text 格式数据也能被导出。测试样例：36M 数据导出耗时 15s - 只导出数据库表结构 `mysqldump -h localhost -P 3306 -uroot -p -d --add-drop-table my_db_name > d:/exp.sql` (-d 没有数据 --add-drop-table 在每个 create 语句之前增加一个 drop table) - 导出一张表 `mysqldump -h localhost -P 3306 -uroot -p my_db_name my_table_name > d:/exp.sql` - 压缩备份 `mysqldump -h localhost -P 3306 -uroot -p my_db_name | gzip > d:/mysql_bak.$(date +%F).sql.gz` - 参数 - `-h`默认为本地 - `-P`默认为 3306
- 导入数据 - `mysql -h localhost -P 3306 -uroot -p my_db_name < d:/exp.sql` 直接 CMD 命令行导入 - source 方式. Navicat 命令行使用 source 报错，且通过界面 UI 界面导入数据也容易出错。建议到 mysql 服务器命令行导入 - 命令行登陆用户 `mysql -uroot -p` - 选择数据库 `use my_db_name` - 执行导入 `source d:/exp.sql`

#### 导出表结构

- MySQL-Front：可导出 html 格式(样式和字段比较人性化)，直接复制到 word 中
- SQLyong(数据库-在创建数据库架构 HTML)：可导出很完整的字段结构(太过完整，无法自定义)
- DBExportDoc V1.0 For MySQL：基于提供的 word 模板(包含宏命令)和 ODBC 导出结构到模板 word 中(表格无线框)

### linux 脚本备份(mysqldump)

- 备份 mysql 和删除备份文件脚本`backup_mysql.sh`(加可执行权限先进行测试)

      	```bash
      	db_user="root"
      	db_passwd="root"
      	db_name="db_test"
      	db_host="127.0.0.1"
      	db_port="3306"
      	# the directory for story your backup file.you shall change this dir
      	backup_dir="/home/data/backup/mysqlbackup"
      	# date format for backup file (eg: 20190407214357)
      	time="$(date +"%Y%m%d%H%M%S")"
      	# 需要确保当前linux用户有执行mysqldump权限
      	/opt/soft/mysql57/bin/mysqldump -h $db_host -P $db_port -u$db_user -p$db_passwd $db_name | gzip > "$backup_dir/$db_name"_"$time.sql.gz"

      	# 删除30天之前的备份
      	find $backup_dir -name $db_name"*.sql.gz" -type f -mtime +30 -exec rm -rf {} \; > /dev/null 2>&1
      	```
      	- 说明
      		- 删除一分钟之前的备份 `find $backup_dir -name $db_name"*.sql.gz" -type f -mmin +1 -exec rm -rf {} \; > /dev/null 2>&1`
      		- `-type f` 表示查找普通类型的文件，f 表示普通文件，可不写
      		- `-mtime +7` 按照文件的更改时间来查找文件，+7表示文件更改时间距现在7天以前;如果是-mmin +7表示文件更改时间距现在7分钟以前
      		- `-exec rm {} ;` 表示执行一段shell命令，exec选项后面跟随着所要执行的命令或脚本，然后是一对{ }，一个空格和一个\，最后是一个分号;

- 将上述脚本加入到`crond`定时任务中 - `sudo crontab -e` 编辑定时任务，加入`00 02 * * * /home/smalle/script/backup_mysql.sh` - `systemctl restart crond` 重启 crond 服务

### 主从同步

- 从库

change master to master_host='127.0.0.1', master_port=3306, master_user='rep', master_password='Hello1234!', master_log_file='shipbill-log-bin.000001', master_log_pos=154;

show slave status \G;
stop slave;
start slave;

## 管理员

### 配置

- mysql 在 windows 系统下安装好后，默认是对表名大小写不敏感的。但是在 linux 下，一些系统需要手动设置：打开并修改`/etc/my.cnf`在`[mysqld]`节点下，加入一行： `lower_case_table_names=1`(表名大小写：0 是大小写敏感，1 是大小写不敏感)。重启 mysql 服务`systemctl restart mysqld`
- mysql 服务器编码问题 - 保存到数据库编码错误：1.编辑器编码(复制的代码要注意原始代码格式) 2.数据库/表/字段编码 3.服务器编码 - 查看服务器编码`show variables like '%char%';`，如果`character_set_server=latin1`就说明有问题(曾经因为这个问题遇到这么个场景：此数据库下大部分表可以正常插入中文，但是有一张表的一个字段死活插入乱码，当尝试修改 java 代码中此 sql 语句的另外几个传入参数并连续插入两次可以正常插入，不产生乱码。此情景简直可以怀疑人生，最终修改 character_set_server 后一切正常) - 修改 character_set_server 编码：linux 修改`/etc/my.cnf`，在`[mysqld]`节点下加入一行`character-set-server=utf8`，重启 mysqld 服务

### 查询

- `show variables like '%dir%';` 查看 mysql 相关文件(数据/日志)存放位置 - 数据文件(datadir)默认位置：`/var/lib/mysql`
- `show variables like 'autocommit';` - MySQL 默认操作模式就是 autocommit 自动提交模式(ON/1) - 这就表示除非显式地开始一个事务(mysql> `set autocommit=0;`)，否则每个查询都被当做一个单独的事务自动执行。当 mysql> `commit;`之后则又回到自动提交模式
- 查看数据库大小 - InnoDB 存储引擎将表保存在一个表空间内，该表空间可由数个文件创建。表空间的最大容量为 64TB - MySQL 单表大约在 2 千万条记录(4G)下能够良好运行，经过数据库的优化后 5 千万条记录(10G)下运行良好

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

      	-- 查看所有数据库各表数据大小(比较耗时)
      	select
      	table_schema as '数据库',
      	table_name as '表名',
      	table_rows as '记录数',
      	truncate(data_length/1024/1024, 2) as '数据容量(MB)',
      	truncate(index_length/1024/1024, 2) as '索引容量(MB)'
      	from information_schema.tables
      	order by data_length desc, index_length desc;
      	```

### 数据库 CPU 飙高问题

参考：[http://blog.aezo.cn/2018/03/13/java/Java%E5%BA%94%E7%94%A8CPU%E5%92%8C%E5%86%85%E5%AD%98%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90/](/_posts/devops/Java应用CPU和内存异常分析.md#Mysql)

## 测试

### 快速创建数据

```sql
-- 1.创建一个临时内存表
drop table if exists `t_test_vote_memory`;
create table `t_test_vote_memory` (
    `id` int(10) unsigned not null auto_increment,
    `user_id` varchar(20) not null default '',
    `vote_num` int(10) unsigned not null default '0',
    `group_id` int(10) unsigned not null default '0',
    `status` tinyint(2) unsigned not null default '1',
    `create_time` datetime,
    primary key (`id`),
    key `index_user_id` (`user_id`) using hash
) engine=innodb auto_increment=1 default charset=utf8;

-- 2.创建一个测试表
drop table if exists `t_test_vote`;
create table `t_test_vote` (
    `id` int(10) unsigned not null auto_increment,
    `user_id` varchar(20) not null default '' comment '用户id',
    `vote_num` int(10) unsigned not null default '0' comment '投票数',
    `group_id` int(10) unsigned not null default '0' comment '用户组id 0-未激活用户 1-普通用户 2-vip用户 3-管理员用户',
    `status` tinyint(2) unsigned not null default '1' comment '状态 1-正常 2-已删除',
    `create_time` datetime comment '创建时间',
    primary key (`id`),
    key `index_user_id` (`user_id`) using hash comment '用户id哈希索引'
) engine=innodb default charset=utf8 comment='投票记录表';

-- 3.创建生成长度为n的随机字符串的函数
delimiter // -- 修改mysql delimiter：'//'
drop function if exists `rand_string` //
set names utf8 //
create function `rand_string` (n int) returns varchar(255) charset 'utf8'
begin
    declare char_str varchar(100) default 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789';
    declare return_str varchar(255) default '';
    declare i int default 0;
    while i < n do
        set return_str = concat(return_str, substring(char_str, floor(1 + rand()*62), 1));
        set i = i+1;
    end while;
    return return_str;
end //

-- 4.创建插入数据的存储过程
delimiter //
drop procedure if exists `add_t_test_vote_memory` //
create procedure `add_t_test_vote_memory`(in n int)
begin
    declare i int default 1;
    declare vote_num int default 0;
    declare group_id int default 0;
    declare status tinyint default 1;
    while i < n do
        set vote_num = floor(1 + rand() * 10000);
        set group_id = floor(0 + rand()*3);
        set status = floor(1 + rand()*2);
        insert into `t_test_vote_memory` values (null, rand_string(20), vote_num, group_id, status, now());
        set i = i + 1;
    end while;
end //
delimiter ;  -- 改回默认的 mysql delimiter：';'

-- 5.调用存储过程 生成100w条数据
call add_t_test_vote_memory(1000000);

-- 6.查看临时表数据
select count(*) from `t_test_vote_memory`;

-- 7.复制数据
insert into t_test_vote select * from `t_test_vote_memory`;

-- 8.查看数据
select count(*) from `t_test_vote`;
```

## 其他

- 命令行执行 sql 
  -  Mysql 通过上下左右按键修改语句 - 或者新建一个文本文件 h:/demo/test.sql，将 sql 语句放在文件中，再在命令行输入`\. h:/demo/test.sql` 其中`\.`相当于`source`，末尾不要分号
  - Oracle 输入 ed 则打开记事本可进行修改修改 DOS 中的数据
- Oracle 表结构与 Mysql 表结构转换
  - 使用 navicat 转换 - 点击`工具 -> 数据转换`
    - 左边选择 oracle 数据库和对应的用户，右边转成 sql 文件(直接转换会出现 Date 转换精度错误) 
    - 将 sql 文件中的数据进行转换：`datetime(7)` -> `datetime(6)`，`decimal(20,0)` -> `bigint(20)`(原本在 oracle 中是 Number(20))，`decimal(1,0)` -> `int(1)`，`decimal(10,0)` -> `int(10)`
    - 以此类推 - 默认值丢失 - 导入 sql 文件到 mysql 数据库中

## 常见问题

### 锁相关

- Mysql造成锁的情况有很多，下面我们就列举一些情况
    - 执行DML操作没有commit，再执行删除操作就会锁表
    - 在同一事务内先后对同一条数据进行插入和更新操作
    - 长事物（如期间进行了HTTP请求且等待时间太长），阻塞DDL，继而阻塞所有同表的后续操作
    - 表索引设计不当，导致数据库出现死锁
- 更新数据时报错 `Lock wait timeout exceeded; try restarting transaction` 数据结构ddl操作的锁的等待时间 [^3]
    
    ```bash
    # 事物等待锁超时，如：一个事物还没有提交（对某些表加锁了还没释放），另外一个线程需要获取锁，从而等待超时

    show variables like 'autocommit'; # 查看事物是否为自动提交，NO 为自动提交
    # set global autocommit=1; # 如果不是自动提交可进行设置
    
    show processlist; # 查看是否有执行慢的sql
    # 相关的表：innodb_locks 当前出现的锁，innodb_lock_waits 锁等待的对应关系
    # 字段：trx_mysql_thread_id 事务线程 ID；trx_tables_locked 当前执行 SQL 的行锁数量
    select * from information_schema.innodb_trx; # 查看当前运行的所有事务，应该会发现有一个事物开始时间很早，但是一直存在此表中（因为还未提交）
    kill <trx_mysql_thread_id> # 可临时杀掉卡死的这个事物线程，从而释放锁

    show variables like 'innodb_lock_wait_timeout'; # 查看锁等待超时时间（默认为50s）
    set global innodb_lock_wait_timeout=100; # 设置超时时间（global的修改对当前线程是不生效的，只有建立新的连接才生效）
    # 或者修改参数文件/etc/my.cnf 中 innodb_lock_wait_timeout = 100
    ```
    - 情景：information_schema.innodb_trx 中有一条事物线程一直存在，且锁定了两行记录（innodb_locks 和 innodb_lock_waits 中并未锁/锁等待记录）；最后发现为卡死的事物中进行了HTTP请求，正好HTTP请求一直卡死不返回，导致其他地方修改这个表记录时报错


---

参考文章

[^1]: https://www.cnblogs.com/digdeep/p/4892953.html
[^2]: https://segmentfault.com/a/1190000019305858#item-2-5
[^3]: https://juejin.im/post/6844904078749728782


