---
layout: "post"
title: "Mysql DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [mysql, dba]
---

## 简介

- pt-osc(Online Schema Change) 对于大表进行DDL操作工具

## Mysql安装与配置

### Mysql安装

- 软件下载：[服务器安装包 mysql-installer-community-5.7.32.0.msi (或云盘)](https://downloads.mysql.com/archives/installer/)、[Community Server压缩包 mysql-5.7.32-winx64.zip](https://downloads.mysql.com/archives/community/)。installer安装备注如下
    - installer默认安装在`C:\Program Files (x86)\MySQL\MySQL Installer for Windows`目录，打开上述msi则会自动安装在此目录，之后可进行配置Server的安装，安装完server之后，仍然可打开此Installer重新安装、增加安装或卸载，尽管下载的是5.7的Installer，但是包含了5.7、8个版本的安装配置
    - 启动安装，选择Setup Type：Developer Default默认安装了Server和一些连接器和文档，且安装在C盘，如需定义安装目录，需选择Custom
    - 自定义安装时，选择Mysql Servers - Mysql Server 5.7 x64 - 添加到安装列表，其他的连接器和文档(包括示例数据库)可在安装完Server之后进行增加安装
    - Windows 10安装Server 5.7可能提示无Visual C++ 2013，此时可去MS官网下载安装后再安装Mysql Server
- CentOS-mysql安装：[http://blog.aezo.cn/2017/01/10/linux/CentOS%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E/](/_posts/linux/CentOS服务器使用说明.md#mysql安装)
- windows 安装 mysql，千万不要用通过记事本编辑`my.ini`，容易让文件变成 BOM 格式导致服务无法启动
- 查看系统版本：命令行登录后欢迎信息中有版本信息，或者登录仅命令行执行`status`查看

### 相关配置

- 大小写敏感问题
    - mysql 在 windows 系统下安装好后，默认是对表名大小写不敏感的。但是在 linux 下，一些系统需要手动设置
    - linux设置：打开并修改`/etc/my.cnf`在`[mysqld]`节点下，加入一行： `lower_case_table_names=1`(表名大小写：0 是大小写敏感，1 是大小写不敏感)。重启 mysql 服务`systemctl restart mysqld`
- mysql 服务器编码问题
    - 保存到数据库编码错误：1.编辑器编码(复制的代码要注意原始代码格式) 2.数据库/表/字段编码 3.服务器编码
    - 查看服务器编码`show variables like '%char%';`，如果`character_set_server=latin1`就说明有问题(曾经因为这个问题遇到这么个场景：此数据库下大部分表可以正常插入中文，但是有一张表的一个字段死活插入乱码，当尝试修改 java 代码中此 sql 语句的另外几个传入参数并连续插入两次可以正常插入，不产生乱码。此情景简直可以怀疑人生，最终修改 character_set_server 后一切正常)
    - 修改 character_set_server 编码：linux 修改`/etc/my.cnf`，在`[mysqld]`节点下加入一行`character-set-server=utf8`，重启 mysqld 服务

## 基本

### 登录

- Mysql 进入系统
    - `mysql -uroot -p` 用户名登陆，输入回车后再输入 root 密码即可登陆（在 cmd 中定位到 mysql.exe 所在目录）
    - `mysql -h 192.168.1.1 -P 3307 -uroot -p my_db_name` 登录并选择数据库
    - `exit`、`quit` 退出
- 忘记 root 密码
    - `my.ini`配置文件的`[mysqld]`下增加`skip-grant-tables`参数，重启数据库
    - 修改`mysql.user`中该用户的密码
    - 去掉启动参数重新启动

### 创建/删除用户

```sql
-- 创建超级用户（对于项目级别用户可对每个数据库进行控制，并去掉Grant权限，即去掉查看当前数据库用户列表权限）
grant all privileges on *.* to 'root'@'%' identified by 'fC9(oD4=dP2>' with grant option; -- 创建了一个admin/pass只能本地连接的超级用户

-- 更新用户信息
use mysql
-- update user set user='smalle' where user='root'; -- 更改用户名
-- set password for 'root'@'localhost' = password('root'); -- 5.6版本更新用户
alter user 'root'@'localhost' identified by 'fC9(oD4=dP2>'; -- 5.7版本更新用户密码
-- update user set authentication_string = password("root") where user='root'; -- 5.7版本更新用户密码
update user set host='%' where user='root'; -- 更新host
-- delete from user where user = '用户名'; -- 删除用户。删除系统mysql表中的记录

-- 刷新数据
flush privileges;

create database my_test; -- 创建数据库
```

### 权限

```sql
-- 创建用户并授权
create user smalle identified by 'fC9(oD4=dP2>'; -- 默认创建一个'smalle'@'%'的用户

-- 给此'smalle'@'%'用户授所有数据库所有表权限。但是不包含grant权限
grant all privileges on *.* to 'smalle'@'%';
grant all privileges on *.* to 'smalle'@'localhost' identified by 'password'; -- 对'smalle'@'localhost'操作(无此用户则创建，有则修改密码)，并授本地登录时所有权限（localhost/127.0.0.1则只能本地登录；'smalle'@'192.168.1.%'表示只能这个网段的机器可以访问；'smalle'@'%'则可以在任何机器上登录）
grant all privileges on `wordpress`.* to `smalle`@`localhost` identified by 'password'; -- 授予wordpress数据库下所有权限（相当于Navicat上面管理用户：服务器权限Tab不勾选；权限Tab中数据填wordpress，权限类型都勾选）
-- 创建一个用户my_admin/aezocn，让他只可以在localhost上登录，并对数据库mydb有查询、插入、修改、删除的权限
grant select,insert,update,delete on mydb.* to my_admin@localhost identified by "aezocn";
-- test可以查询 testdb 中的表
grant select on testdb.* to test@localhost;
-- 作用在单个数据表上
grant select, insert, update, delete on testdb.orders to test@localhost;

-- mysql5.7添加 'root'@'%' 用户，并赋权，且允许远程登录
grant all privileges on *.* to 'root'@'%' identified by 'Hello1234!' with grant option;
-- mysql 8.0需要这样添加用户并赋权
create user 'root'@'%' identified by 'Hello1234!';
grant all privileges on *.* to 'root'@'%' with grant option;

-- 撤销用户授权
revoke all privileges on *.* from 'username'@'localhost';
revoke select on testdb.* from 'username'@'%';

-- 刷新权限(grant之后必须执行)
flush privileges;

-- 查询用户可登录host
select user, host from user;
update user set host = '%' where user = 'root';
```

## 管理员

### 查询相关

- `show variables like '%dir%';` 或使用 `select @@basedir, @@datadir`
    - 查看 mysql 相关文件(数据/日志)存放位置，一般也可用于查看my.cfg位置(一般在@@datadir上级目录)
    - 数据文件(datadir)默认位置：`/var/lib/mysql`
- `show variables like 'autocommit';`
    - MySQL 默认操作模式就是 autocommit 自动提交模式(ON/1)
    - 这就表示除非显式地开始一个事务(mysql> `set autocommit=0;`)，否则每个查询都被当做一个单独的事务自动执行。当 mysql> `commit;`之后则又回到自动提交模式
- 查看数据库大小
    - InnoDB 存储引擎将表保存在一个表空间内，该表空间可由数个文件创建。表空间的最大容量为 64TB
    - MySQL 单表大约在 2 千万条记录(4G)下能够良好运行，经过数据库的优化后 5 千万条记录(10G)下运行良好

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

### 索引维护

- Mysql索引
    - 在没有外键约束的情况下，MySql的不同表的索引可以重名，索引文件一表一个，不会出现冲突

```sql
-- ALTER TABLE用来创建普通索引、UNIQUE索引或PRIMARY KEY索引
alter table d_user add index idx_name (name); -- 默认NORMAL BTREE
alter table d_user add unique (card_no);
alter table d_user add primary key (id);

-- CREATE INDEX可对表增加普通索引或UNIQUE索引
create index idx_name_age on d_user (name, age);
create unique index idx_card_no on d_user (card_no);

-- 删除索引
drop index d_user on talbe_name;
alter table d_user drop index index_name;
alter table table_name drop primary key; -- 删除主键索引，一个表只能有一个主键，因此无需指定主键索引名

-- 查看索引
show index from d_user;
show keys from d_user;

-- force index、use index 或者 ignore index
-- 指定索引。如果优化器认为全表扫描更快，会使用全表扫描，而非指定的索引
select * from user use index(idx_name_sex) where id > 10000;
-- 强制指定索引。即使优化器认为全表扫描更快，也不会使用全表扫描，而是用指定的索引
select *
from t_user u force index(idx_create_time)
join t_class c on c.id = u.cid
where u.create_time > '2000-01-01';

-- 重建索引
-- 方式一: alter table 其实等价于rebuild(重建)表(表的创建时间会变化)，所以索引也等价于重新创建了（数据不会变化）
alter table t_test engine=innodb;

-- 方式二: optimize table
-- OPTIMIZE TABLE操作使用Online DDL模式修改Innodb普通表和分区表，
-- 该方式会在prepare阶段和commit阶段持有表级锁：在prepare阶段修改表的元数据并且创建一个中间表，在commit阶段提交元数据的修改
-- 由于prepare阶段和commit阶段在整个事务中的时间比例非常小，可以认为该OPTIMIZE TABLE的过程中不影响表的其他并发操作
optimize table t_test;

-- 方式三 (只支持MyISAM, ARCHIVE, CSV)
-- repair table t_test quick;
```

### 慢SQL/数据库CPU飙高问题

参考：[http://blog.aezo.cn/2018/03/13/java/Java%E5%BA%94%E7%94%A8CPU%E5%92%8C%E5%86%85%E5%AD%98%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90/](/_posts/devops/Java应用CPU和内存异常分析.md#Mysql)

### 锁相关

- Mysql造成锁的情况有很多，下面我们就列举一些情况
    - 执行DML操作没有commit，再执行删除操作就会锁表
    - 在同一事务内先后对同一条数据进行插入和更新操作
    - 长事物（如期间进行了HTTP请求且等待时间太长），阻塞DDL，继而阻塞所有同表的后续操作
    - 表索引设计不当，导致数据库出现死锁
- 更新数据时报错 `Lock wait timeout exceeded; try restarting transaction` 数据结构ddl操作的锁的等待时间 [^3]
    
```bash
# 事物等待锁超时，如：一个事物还没有提交（对某些表加锁了还没释放），另外一个线程需要获取锁，从而等待超时

show variables like 'autocommit'; # 查看事物是否为自动提交，ON 为自动提交
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
- 执行DDL时报错`Waiting for table metadata lock`
    - 参考上文，查询`innodb_trx`表中是否有DDL操作或长事物没有提交
- 死锁
    - mysql5.6的jdbc连接参数useServerPrepStmts=true是个官方bug，所以建议不要用这个，可能会导致select死锁
    - 更新/删除死锁，可能两个session操作到了同一行数据
        - mysql默认是行级锁，如果操作到不同行数据则不会产生
- 降低死锁
    - 选择合理的事务大小，小事务发生锁冲突的概率一般也更小
    - 在不同线程中去访问一组DB的数据表时，尽量约定以相同的顺序进行访问；对于同一个单表而言，尽可能以固定的顺序存取表中的行

### 其他

- **命令行执行sql**
    -  Mysql 通过上下左右按键修改语句
        - 或者新建一个文本文件 h:/demo/test.sql，将 sql 语句放在文件中，再在命令行输入`\. h:/demo/test.sql` 其中`\.`相当于`source`，末尾不要分号
    - Oracle 输入 ed 则打开记事本可进行修改修改 DOS 中的数据
- (增删改数据时)可考虑关闭外键校验
    - `SET foreign_key_checks = 0;` 0关闭外键校验，1开启校验

## 业务场景

### 数据备份/恢复

- 参考[mysql-backup-recover.md](/_posts/db/mysql/mysql-backup-recover.md)

### 导出表结构

- MySQL-Front：可导出 html 格式(样式和字段比较人性化)，直接复制到 word 中
- SQLyong(数据库-在创建数据库架构 HTML)：可导出很完整的字段结构(太过完整，无法自定义)
- DBExportDoc V1.0 For MySQL：基于提供的 word 模板(包含宏命令)和 ODBC 导出结构到模板 word 中(表格无线框)

### Oracle表结构与Mysql表结构转换

- 使用 navicat 转换
    - 点击`工具 -> 数据传输 - 左边选择源数据库 - 右边选择文件 - 去勾选与原服务器相同`
    - 其他选项
        - 去勾选创建记录
        - 去勾选创建前删除表(如果目标库中无次表则会报错)
        - 勾选转换对象名为大写/小写(创建oracle表时不会自动将小写转大写，mysql也不会自动转小写)
    - 存在问题：小数点精度丢失(如手动替换 `Number` 为 `Number(10,2)`)、默认值丢失
- [Oracle迁移MySQL注意事项](https://z.itpub.net/article/detail/981AEFD121E9C508F063228A878ED6E0)

### 内存参数优化(适用小内存VPS)

- 适用mysql 5.6/5.7/8.0内存参数，优化内存占用为40MB左右。参考: http://www.manongjc.com/detail/56-vqenqmbjvqxtfmr.html
- 修改`/etc/my.cnf`并重启

```ini
[mysqld]
# 5.6默认为12500(检测的表对象的最大数目) 1400 2000(缓存frm文件), 一般会占用400MB以上，降低此参数后降低至40MB左右
performance_schema_max_table_instances = 200
table_definition_cache = 100
table_open_cache = 100
# 5.5新增参数(性能优化引擎)，5.6以后默认是开启的; 这个功能在 cpu 资源比较充足的情况下，是可以考虑开启
performance_schema = off
innodb_buffer_pool_size = 2M
```

## 测试

### 执行耗时案例

```sql
-- 复制1000w条数据用时205秒，大概3分钟25秒，粗略估算，5000万数据如果通过此种方式将全表数据备份，也只需要18分钟左右
insert into test_new select * from test where id <= 10000000;

-- 200w 的数据 3s 复制完成
create table test_new as select * from test;

-- Navicat导出 5000w 的数据，耗时 1h 22min，导出SQL语句磁盘空间占用 38.5G
```

- 使用`mysqldump/source`方法进行导出导入
    - 15 分钟导出 1.6 亿条记录，导出的文件中平均 7070 条记录拼成一个 insert 语句
    - 通过 source 进行批量插入，导入 1.6 亿条数据耗时将近 5 小时，平均速度 3200W 条/h（网测）

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


---

参考文章

[^1]: https://www.cnblogs.com/digdeep/p/4892953.html
[^3]: https://juejin.im/post/6844904078749728782


