---
layout: "post"
title: "Mysql数据备份与恢复"
date: "2022-09-17 21:48"
categories: [db]
tags: [mysql, dba]
---

## 数据备份/恢复

- 参考[MySQL的数据备份与恢复](https://cloud.tencent.com/developer/article/1894635)
- `mysqldump` 是一款 mysql **逻辑备份**的工具(备份文件为SQL文件，CLOB字段需要设置参数转为二进制)，它将数据库里面的对象(表)导出作为 SQL 脚本文件
    - 对于导出几个 G 的数据库，还是不错的；一旦数据量达到几十上百 G，无论是对原库的压力还是导出的性能都存在问题 [^1]
    - 支持基于innodb的热备份(加参数`--single-transaction`)；对myisam存储引擎的表，需加`--lock-all-tables`锁，防止数据写入
    - Mysqldump完全备份+二进制日志可以实现基于时间点的恢复。恢复的时候可关闭二进制日志，缩短恢复时间
- `XtraBackup` 是由 [percona](https://www.percona.com/) 开源的免费数据库热备份软件，它能对 InnoDB 数据库和 XtraDB 存储引擎的数据库非阻塞地备份。对于较大数据的数据库可以选择`Percona-XtraBackup`备份工具，可进行全量、增量、单表备份和还原，percona早起提供的工具是 innobackupex
    - xtrabackup：支持innodb存储引擎表，xtradb存储引擎表。支持innodb的物理热备份，支持完全备份，增量备份，而且速度非常快
    - innobackupex：支持innodb存储引擎表、xtradb存储引擎表、myisam存储引擎表
- `mariadb10.3.x`及以上的版本用 Percona XtraBackup 工具会有问题，此时可以使用`mariabackup`，它是 MariaDB 提供的一个开源工具

## Mysql相关语法

### as和like复制表结构和数据

```sql
-- like创建出来的新表包含源表的完整表结构和索引信息
-- mysql适用; oracle不支持(as方式参考下文)
create table test_new like test;

-- 复制表结构(不含默认值等)、索引及数据到新表
-- oracle不会复制到表结构的备注和默认值；mysql可以复制备注，但是主键会丢失，可使用like
-- 200w 的数据 3s 复制完成
create table test_new as select * from test;
create table test_new as select * from test where 1=2; -- 只复制表结构到新表
create table test_new as select row_id, name, age from test where 1<>1; -- 复制部分字段
```

### 复制数据

```sql
-- 复制旧表的数据到新表(假设两个表结构一样)
-- 此时会边复制边创建索引，速度可能会慢，可先临时关闭索引，参考下文
-- 执行时是会把test表给锁住的，在锁期间是不允许任何操作，保证数据一致性
insert into test_new select * from test;
-- 复制旧表的数据到新表(假设两个表结构不一样)
insert into test_new(字段1,字段2,.......) select 字段1,字段2,...... from test;

-- 优化一: 批量插入大量数据，临时关闭索引加快复制速度
alter table test_new disable keys; -- 临时关闭索引
insert into test_new select * from test; -- 复制数据 (由于没有索引，速度有很大提升)
alter table test_new enable keys; -- 开启索引 (开启时会自动优化索引)

-- 优化二: 增加索引防止锁表
-- test_new 是表锁；order_today逐步锁(扫描一个锁一个)，如果没有where条件或者查询没有走索引则相当于全表扫描，即等同于锁表
insert into test_new select * from test where create_time > '2000-01-01';
insert into test_new select * from test force index (idx_create_time) where create_time > '2000-01-01';
```

### delete/truncate/drop

- delete
    - 执行数据较慢，较多删除可进行批量删除(单也不能太大)
    - 会记录事务日志，可进行回滚
    - 不会减少表或索引所占用的空间
- truncate
    - 执行速度快，会删除表所有数据，但表结构不会影响
    - 不会记录日志，删除行是不能恢复的，并且在删除的过程中不会激活与表有关的删除触发器
    - 这个表和索引所占用的空间会恢复到初始大小
- drop
    - 会直接删除表结构。且会删除constrain/trigger/index，依赖于该表的存储过程/函数将被保留，但其状态会变为invalid
    - 将表所占用的空间全释放掉
- 其他异同
    - truncate 只能对table；delete可以是table和view
    - delete语句为DML；truncate、drop是DLL
- delete 删除数据时，其实对应的数据行并不是真正的删除，仅仅是将其标记成可复用的状态，所以表空间不会变小。可以重建表的方式，快速将delete数据后的表变小（optimize table 或alter table）

### rename

```sql
-- mysql中对大表进行rename的操作很快，rename命令会直接修改底层的.frm文件，常用于数据备份和恢复
rename table user to user_old;

-- 有时需要对数据库中的表进行原子性rename，可以使用
rename table user to user_old, user_bak to user;
```

## XtraBackup

- XtraBackup(PXB) 工具是 Percona 公司用 perl 语言开发的一个用于 MySQL 数据库物理热备的备份工具，支持 MySQl（Oracle）、Percona Server 和 MariaDB，并且全部开源
    - 阿里的 RDS MySQL 物理备份就是基于这个工具做的
    - 由于是采取物理拷贝的方式来做的备份，所以速度非常快，**几十G数据几分钟就搞定了**
    - 而它巧妙的利用了mysql 特性做到了**在线热备份**，不用像以前做物理备份那样必须关闭数据库才行，直接在线就能完成整库或者是部分库的全量备份和增量备份
- 其中最主要的命令是 innobackupex 和 xtrabackup
    - 前者是一个 perl 脚本，后者是 C/C++ 编译的二进制。Percona 在2.3 版本用C重写了 innobackupex，innobackupex 功能全部集成到 xtrabackup 里面，只有一个 binary，另外为了使用上的兼容考虑，innobackupex 作为 xtrabackup 的一个软链接
    - 更多参考：https://www.cnblogs.com/piperck/p/9757068.html
- 数据迁移案例

```bash
## 安装(新老服务器均需安装)
yum -y install perl perl-devel libaio libaio-devel perl-Time-HiRes perl-DBD-MySQL perl-Digest-MD5
wget http://mirror.centos.org/centos/7/extras/x86_64/Packages/libev-4.15-7.el7.x86_64.rpm # https://pkgs.org/download/libev(x86-64)
rpm -ivh libev-4.15-7.el7.x86_64.rpm
wget https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.24/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.24-1.el7.x86_64.rpm
rpm -ivh percona-xtrabackup-24-2.4.24-1.el7.x86_64.rpm
xtrabackup -version # xtrabackup version 2.4.24 based on MySQL server 5.7.35 Linux (x86_64) (revision id: b4ee263)
# https://www.percona.com/doc/percona-xtrabackup/2.4/manual.html

## 备份(原服务器上进行)
# 先全量备份(热备，物理备)，提示 completed OK! 则成功
mkdir –p /home/xtrabackup/
# 40G 2.5min 将mysql-data目录下文件全部进行全量备份
# --compress 表数据会进行压缩(压缩后为原来25%大小)，文件以.qp结尾，对应文件如`my_table.ibd.qp`
# --decompress 解压缩时，系统必须提前安装qpress . 数据库必须运行中
innobackupex --defaults-file=/etc/my.cnf --user=root --password=root --use-memory=2G --kill-long-queries-timeout=10 --ftwrl-wait-timeout=20 --compress --compress-threads=4 /home/xtrabackup/`date +%F`

# 再进行增量备份(热备，物理备)，提示 completed OK! 则成功
# 一般可停服增备份，防止数据写入
# 40G+ 晚上 2.5min 将datadir目录下文件全部进行增量备份，表的物理文件大小只有增加的数据大小
innobackupex --defaults-file=/etc/my.cnf --user=root --password=root --incremental /home/xtrabackup/2021-09-22/ --incremental-basedir=/home/xtrabackup/2021-09-22/2021-09-22_22-19-32/

## 执行恢复
# --decompress 解压缩，系统必须提前安装qpress。提示 completed OK!
# 解压出来后，原压缩文件还存在？
innobackupex --decompress /home/xtrabackup/2021-09-22/2021-09-22_22-19-32
# 准备恢复：所谓准备恢复，就是要为恢复做准备。就是说备份集没办法直接拿来用，因为这中间可能存在未提交或未回滚的事务，数据文件不一致，所以需要一个队备份集的准备过程
# completed OK!
innobackupex --defaults-file=/etc/my.cnf --apply-log --redo-only /home/xtrabackup/2021-09-22/2021-09-22_22-19-32

# 合并全量和增量备份 completed OK!
innobackupex --defaults-file=/etc/my.cnf --apply-log --redo-only --incremental /home/xtrabackup/2021-09-22/2021-09-22_22-19-32/ --incremental-dir=/home/xtrabackup/2021-09-22/2021-09-23_08-50-05

## 恢复数据(在新服务器上执行)
# 迁移数据库时，拷贝数据到另外一台服务器
systemctl stop mysqld
mv /home/data/mysql /home/data/mysql_bak
mkdir -p /home/data/mysql
# 将原服务器备份的数据拷贝到新服务器。rsync命令参考: http://www.ruanyifeng.com/blog/2020/08/rsync.html
rsync -av root@192.168.1.100:/home/xtrabackup/2021-09-22/2021-09-22_22-19-32/ /home/data/mysql_2021-09-22
# 进行恢复
innobackupex --defaults-file=/etc/my.cnf --copy-back /home/data/mysql_2021-09-22
chown -R mysql:mysql /home/data/mysql
systemctl start mysqld
```

## 导出导入

- 参数说明：https://www.cnblogs.com/qq78292959/p/3637135.html
- 使用`mysqldump/source`方法进行导出导入
    - 15 分钟导出 1.6 亿条记录，导出的文件中平均 7070 条记录拼成一个 insert 语句
    - 通过 source 进行批量插入，导入 1.6 亿条数据耗时将近 5 小时，平均速度 3200W 条/h（网测）
- 导出数据

```bash
# 默认导出表结构和数据。回车后输入密码，text 格式数据也能被导出；测试样例：36M 数据导出耗时 15s
%MYSQL_HOME%/bin/mysqldump -h 192.168.1.1 -P 3306 -uroot -p my_db_name > d:/exp.sql

# 压缩备份(linux)
mysqldump -h localhost -P 3306 -uroot -p my_db_name | gzip > d:/mysql_bak.$(date +%F).sql.gz

# 只导出数据库表结构
# -d 没有数据 --add-drop-table 在每个 create 语句之前增加一个 drop table
mysqldump -h localhost -P 3306 -uroot -p -d --add-drop-table my_db_name > d:/exp.sql

# 导出一张表
mysqldump -h localhost -P 3306 -uroot -p my_db_name my_table_name > d:/exp.sql
```
- 导入数据

```bash
# 直接 CMD 命令行导入
mysql -h localhost -P 3306 -uroot -p my_db_name < d:/exp.sql

# source 方式
mysql -uroot -p
use my_db_name
source d:/exp.sql

# Navicat 命令行使用 source 报错，且通过界面 UI 界面导入数据也容易出错。建议到 mysql 服务器命令行导入
```

## linux脚本备份(mysqldump)

- 备份 mysql 和删除备份文件脚本`backup-mysql.sh`(加可执行权限先进行测试)

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
/opt/mysql57/bin/mysqldump -h $db_host -P $db_port -u$db_user -p$db_passwd $db_name | gzip > "$backup_dir/$db_name"_"$time.sql.gz"

# 删除3天之前的备份
find $backup_dir -name $db_name"*.sql.gz" -type f -mtime +3 -exec rm -rf {} \; > /dev/null 2>&1
```
- 说明
    - 删除一分钟之前的备份 `find $backup_dir -name $db_name"*.sql.gz" -type f -mmin +1 -exec rm -rf {} \; > /dev/null 2>&1`
    - `-type f` 表示查找普通类型的文件，f 表示普通文件，可不写
    - `-mtime +7` 按照文件的更改时间来查找文件，+7表示文件更改时间距现在7天以前;如果是-mmin +7表示文件更改时间距现在7分钟以前
    - `-exec rm {} ;` 表示执行一段shell命令，exec选项后面跟随着所要执行的命令或脚本，然后是一对{ }，一个空格和一个\，最后是一个分号;
- 将上述脚本加入到`crond`定时任务中
    - `sudo crontab -e` 编辑定时任务，加入`00 02 * * * /home/smalle/script/backup-mysql.sh`
    - `systemctl restart crond` 重启 crond 服务

## 主从同步

- 从库

change master to master_host='127.0.0.1', master_port=3306, master_user='rep', master_password='Hello1234!', master_log_file='shipbill-log-bin.000001', master_log_pos=154;

show slave status \G;
stop slave;
start slave;

## flashback闪回

- binlog2sq：https://github.com/danfengcao/binlog2sql
- 参考 https://www.cnblogs.com/waynechou/p/mysql_flashback_intro.html

## 案例

### 历史数据归档

```sql
-- 总数据条数 11443852, 大小 2299888KB, 17个字段, 9个索引
-- 查询 7 天的数据(select *)耗时 90s (走了用户名索引, 如果查询设置强制索引只需要 3s)
select count(1) from ship_bill_charge t where t.update_tm >= '2022-01-01'; -- 2289714

-- 创建热数据临时表(之后会重命名为新的ship_bill_charge表), 会复制字段、默认值、索引(mysql不同表的索引可重名)等
create table ship_bill_charge_2022 like ship_bill_charge;

-- 复制今年的数据到临时表 (可考虑暂时停止数据写入). 2289714 条数据耗时 1072.781s
insert into ship_bill_charge_2022 select * from ship_bill_charge force index(idx_update_tm) where t.update_tm >= '2022-01-01';

-- 数据表切换(原子性, 执行速度非常快)
rename table ship_bill_charge to ship_bill_charge_2021, ship_bill_charge_2022 to ship_bill_charge;
```




---

参考文章

[^1]: https://segmentfault.com/a/1190000019305858#item-2-5
