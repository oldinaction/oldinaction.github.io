---
layout: "post"
title: "Oracle DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [oracle, dba]
---

## 简介

- [在线演示环境](https://livesql.oracle.com/)
- 注：本文中 aezo/aezo 一般指用户名/密码，local_orcl 指配置的本地数据库服务名，remote_orcl 指配置的远程数据库服务名。以 11g 为例
- 安装oracle 11.2g参考印象笔记(测试通过)
    - **需要注意数据文件目录(/u01/app/oracle/oradata)挂载的磁盘，建议将`/u01`目录挂载到单独的数据盘上**
- [Oracle线上异常处理](/_posts/devops/Java应用CPU和内存异常分析.md#Oracle)

### Oracle相关名词和原理

- 数据库名(db_name)、实例名(instance_name)、以及操作系统环境变量(oracle_sid) [^1]
    - `db_name`: 在每一个运行的 oracle 数据库中都有一个数据库名(如: orcl)，如果一个服务器程序中创建了两个数据库，则有两个数据库名。
    - `instance_name`: 数据库实例名则用于和操作系统之间的联系，用于对外部连接时使用。在操作系统中要取得与数据库之间的交互，必须使用数据库实例名(如: orcl)。与数据库名不同，在数据安装或创建数据库之后，实例名可以被修改。例如，要和某一个数据库 server 连接，就必须知道其数据库实例名，只知道数据库名是没有用的。用户和实例相连接。
    - `oracle_sid`: 有时候简称为 SID。在实际中，对于数据库实例名的描述有时使用实例名(instance_name)参数，有时使用 ORACLE_SID 参数。这两个都是数据库实例名。instance_name 参数是 ORACLE 数据库的参数，此参数可以在参数文件中查询到，而 ORACLE_SID 参数则是操作系统环境变量，用于和操作系统交互，也就是说在操作系统中要想得到实例名就必须使用 ORACLE_SID。此参数与 ORACLE_BASE、`ORACLE_HOME`等用法相同。在数据库安装之后，ORACLE_SID 被用于定义数据库参数文件的名称。如：$ORACLE_BASE/admin/DB_NAME/pfile/init$ORACLE_SID.ora。
- `service_name`
    - 是网络服务名(如：local_orcl)，可以随意设置，相当于某个数据库实例的别名方便记忆和访问。`tnsnames.ora`文件中设置的名称(如：`local_orcl=(...)`)，也是登录 pl/sql 是填写的 Database
- `schema`
    - schema 为数据库对象的集合，为了区分各个集合，需要给这个集合起个名字，这些名字就是我们看到的许多类似用户名的节点，这些类似用户名的节点其实就是一个 schema。schema 里面包含了各种对象如 tables, views, sequences, stored procedures, synonyms, indexes, clusters, and database links。一个用户一般对应一个 schema，该用户的 schema 名等于用户名，并作为该用户缺省 schema
- `listener.ora` 服务端监听实例列表和端口(1521)配置
- `tnsnames.ora` 连接监听的别名test_orcl(127.0.0.1 1521 orcl)
- `pfile`和`spfile`参数文件
    - 参考：https://www.cnblogs.com/xqzt/p/4832597.html
    - pfile：初始化参数文件（Initialization Parameters Files）
        - 默认路径为：/u01/app/oracle/product/11.2.0/dbs/<init+例程名.ora>
        - ASCII文本文件，可vi修改
    - spfile：服务器参数文件（Server Parameter Files）
        - 默认路径为：/u01/app/oracle/product/11.2.0/dbs/<spfile+例程名.ora>
        - 二进制文件，只能连接数据库后通过命令修改
        - 查看spfile未知`show parameter spfile`
    - startup 启动次序 spfile优先于pfile。查找文件的顺序是 spfileSID.ora-〉spfile.ora-〉initSID.ora-〉init.ora（spfile优先于pfile）
        - 判断实例是pfile还是spfile启动`select decode(count(*),1,'spfile','pfile') from v$spparameter where rownum=1 and isspecified ='TRUE';`
        - 以pfile启动如 `startup pfile='/u01/app/oracle/product/11.2.0/dbs/initorcl.ora'` (一般位于 $ORACLE_HOME/dbs/init{SID}.ora)
            - 安装数据库时的初始化模板文件 `/u01/app/oracle/admin/orcl/pfile/init.ora.2172017164927`
    - pfile和spfile的互相创建
        - create spfile[='xxxxx'] from pfile[='xxxx'];
        - create pfile[='xxxxx'] from spfile[='xxxx'];
    - spfile参数的三种scope
        - scope=spfile: 对参数的修改记录在服务器初始化参数文件中，修改后的参数在下次启动DB时生效。适用于动态和静态初始化参数
        - scope=memory: 对参数的修改记录在內存中，对于动态初始化参数的修改立即生效。在重启DB后会丟失
        - scope=both: 对参数的修改会同时记录在服务器参数文件和內存中，对于动态参数立即生效，对静态参数不能用这个选项

## 启动/停止

- 监听程序(重启数据库可不用重启监听程序)

```bash
## 重新启动监听程序(shell命令行运行即可), 或者重启Windows服务如: OracleOraDb11g_home1TNSListener
# 重启(关闭)监听不会导致原来的连接失效, 只是新的连接暂时无法连上
lsnrctl stop
lsnrctl start # 启动后会自动执行 lsnrctl status

# 查看服务状态(见下图"lsnrctl-status显示图片")。如：Instance "orcl", status READY, has 1 handler(s) for this service...
lsnrctl status
```

- **重启数据库**

```bash
## 重启服务
# su - oracle && source ~/.bash_profile
# 以nolog、sysdba身份登录，进入sql命令行
# sqlplus /nolog
sqlplus / as sysdba

# `shutdown;` 则是有用户连接就不关闭，直到所有用户断开连接
# 大多数情况下使用。迫使每个用户执行完当前SQL语句后断开连接 (sql下运行，可无需分号)
shutdown immediate;
# 当数据库出现故障时，可能以上方式都无法正常关闭数据库，则使用这种方法。强制结束当前正在执行的SQL语句，任何未递交的事务都不被回退！这种方法基本上不会对控制文件或者参数文件造成破坏，这比强制关机要好一点，启动时自动进行实例恢复
# shutdown abort;

# 正常启动，其他启动方式参考下文（sql下运行；1启动实例，2打开控制文件，3打开数据文件）。提示`Database opened.`则表示数据库启动成功
startup
# 查看示例状态为OPEN
select status from v$instance;
# 退出sqlplus
exit;

# 查看oracle相关进程
ps -ef | grep ora_ | grep -v grep
```

- startup 说明

```sql
-- 非安装启动，这种方式启动下可执行：重建控制文件、重建数据库。读取init.ora文件，启动instance，即启动SGA和后台进程，这种启动只需要init.ora文件
startup nomount
-- 安装启动，这种方式启动下可执行：数据库日志归档、数据库介质恢复、使数据文件联机或脱机、重新定位数据文件、重做日志文件。执行"nomount"，然后打开控制文件，确认数据文件和联机日志文件的位置，但此时不对数据文件和日志文件进行校验检查
startup mount
-- 先执行"nomount"，然后执行"mount"，再打开包括Redo log文件在内的所有数据库文件，这种方式下才可访问数据库中的数据
startup open
-- 等于三个命令：startup nomount、alter database mount、alter database open
startup

-- 以FILENAME为初始化文件启动数据库，不是采用默认初始化文件
startup pfile=<FILENAME>
```

## 常见错误

### 数据库服务器CPU飙高

- 参考[数据库服务器故障](/_posts/devops/Java应用CPU和内存异常分析.md#数据库服务器故障)

### 数据库无法连接

- 查看数据库连接设置

```sql
-- 查看当前数据库建立的会话情况
select sid,serial#,username,program,machine,status from v$session;
-- 查询数据库允许的最大连接数，一般如300
select value from v$parameter where name = 'processes';
```
- 查看应用连接池设置的大小
- 查看监听状态, 报TNS-12541一般是监听服务有问题
    - 检查 1521 端口连通情况是否正常，服务是否正常
    - 检查如`listener.log`(/u01/oracle/diag/tnslsnr/oracle/listener)日志文件是否过大(达到 4G 会出问题)，可直接重新创建一个此日志文件，或修改listener.ora进行自动分割(参考[Oracle安装](#Oracle安装))
        - lsnrctl status 卡死, lsnrctl start 卡死在"正在连接到"
        - 如实例 tnsping 突然高达 1w 多毫秒
        - `netstat -ano | findstr 1521` 显示很多 FIN_WAIT_2 CLOSE_WAIT 的状态

```bash
## 重新启动监听程序(shell命令行运行即可), 或者重启Windows服务如: OracleOraDb11g_home1TNSListener
# 重启(关闭)监听不会导致原来的连接失效, 只是新的连接暂时无法连上
lsnrctl stop
lsnrctl start # 启动后会自动执行 lsnrctl status
```

### 表空间不足

- 报错`ORA-01653: unable to extend table` [^7]
    - 重设(不是基于原大小增加)表空间文件大小：`alter database datafile '数据库文件路径' resize 2000M;` (表空间单文件默认最大为 32G=32768M，与 db_blok_size 大小有关，默认 db_blok_size=8K，在初始化表空间后不能再次修改)
    - 开启表空间自动扩展，每次递增 50M `alter database datafile '/home/oracle/data/users01.dbf' autoextend on next 50m;`
    - 为 USERS 表空间新增 1G 的数据文件 **`alter tablespace users add datafile '/home/oracle/data/users02.dbf' size 1024m;`**
        - 此时增加的数据文件还需要再次运行上述自动扩展语句从而达到自动扩展
            - **`alter database datafile '/home/oracle/data/users0.dbf' autoextend on next 50m;`**
        - 此处定义的 1G 会立即占用物理磁盘的 1G 空间，当开启自动扩展后，最多可扩展到 32G
        - 增加完数据文件后，数据会自动迁移，最终达到相同表空间的数据文件可用空间大概一致
    - 增加数据文件和表空间大小可适当重启数据库。查看表空间状态

    ```sql
    -- 查看表空间
    -- 如果表空间不足，此sql语句可能无法显示出来该表空间，可单独查询其中的a表空间
    select a.tablespace_name "表空间名",
        a.bytes / 1024 / 1024 "表空间大小(m)", -- 此文件对应空间不够则会自动递增，一直增加到最大文件大小 32G
        (a.bytes - nvl(b.bytes, 0)) / 1024 / 1024 "已使用空间(m)",
        case when b.bytes is null then 0 else b.bytes / 1024 / 1024 end "空闲空间(m)",
        case when b.bytes is null then 0 else round(((a.bytes - b.bytes) / a.bytes) * 100, 2) end "使用比",
        a.file_name "全路径的数据文件名称",
        autoextensible "表空间自动扩展",
        increment_by "自增块(默认1blocks=8k)",
        a.online_status "表空间文件状态"
    from (select tablespace_name, file_name, autoextensible, increment_by, sum(bytes) bytes, online_status
            from dba_data_files
        group by tablespace_name, file_name, autoextensible, increment_by, online_status) a
    left join
        (select tablespace_name, sum(bytes) bytes, max(bytes) largest
            from dba_free_space
        group by tablespace_name) b
    on a.tablespace_name = b.tablespace_name;

    -- 查看oracle临时表空间
    select tablespace_name "表空间名", file_name "全路径的数据文件名称", sum(bytes) / 1024 / 1024 "表空间大小(m)", autoextensible "表空间自动扩展", increment_by "自增块(默认1blocks=8k)"
    from dba_temp_files
    group by tablespace_name, file_name, autoextensible, increment_by;

    -- 列出数据库里每张表分配的物理空间(基本就是每张表使用的物理空间)
    select segment_name, segment_type, tablespace_name, sum(bytes)/1024/1024/1024 as "GB" 
        from user_extents 
        group by segment_name, segment_type, tablespace_name order by sum(bytes) desc;
    -- dba
    select segment_name, segment_type, tablespace_name, sum(bytes)/1024/1024/1024 as "GB"
        from dba_extents where owner = 'SMALLE' 
        group by segment_name, segment_type, tablespace_name order by sum(bytes) desc;
    -- 上面结果返回中如果存在SYS_LOBxxx的数据(oracle会将[C/B]LOB类型字段单独存储)，则可通过下面语句查看属于哪张表
    select * from dba_lobs where segment_name like 'SYS_LOB0000109849C00008$$';
    -- 查看所有LOB块信息
    select * from dba_lobs where segment_name in 
        (select segment_name from user_extents group by segment_name having segment_name like 'SYS_LOB%');

    -- 列出数据库里每张表的记录条数
    select t.table_name,t.num_rows from user_tables t order by num_rows desc;

    -- 查看表占用的空间情况(浪费的空间可通过shrink或move等方式清理，清理后表空间统计值会变小)
    -- 如果对表做了数据清理，需要先重新统计下表信息，再查看表占用空间。或者通过存储过程批量更新：https://deepinout.com/oracle/oracle-questions/321_oracle_oracle_manually_update_statistics_on_all_tables.html
    exec dbms_stats.gather_table_stats(ownname=>'SCOTT', tabname=> 'MY_TABLE_XX'); -- command窗口执行(会卡一会)
    -- select table_name,last_analyzed from dba_tables where owner = 'SCOTT'; -- 查看上次一次统计时间
    -- 查看表占用的空间情况(查看高水位线)
    select table_name,
        round(((blocks) * 8 / 1024), 2) "高水位空间M",
        round((num_rows * avg_row_len / 1024 /1024), 2) "真实使用空间M",
        round((blocks * 10 / 100) *8 /1024, 2) "预留空间(pctfree)M",
        round((blocks) * 8 / 1024 - (num_rows * avg_row_len / 1024 / 1024) - blocks * 8 * 10 / 100 / 1024, 2) "浪费空间M"
    from dba_tables -- user_tables
    where temporary = 'N'
    and owner = 'MY_OWNER_XXX'
    -- and table_name = 'MY_TABLE_XXX'
    order by 5 desc; -- 按照第5个字段排序
    ```
- 报错`ORA-01654:unable to extend index`，解决步骤 [^8]
  - 情况一表空间已满：通过查看表空间`USERS`对应的数据文件`users01.dbf`文件大小已经 32G(表空间单文件默认最大为 32G=32768M，与 db_blok_size 大小有关，默认 db_blok_size=8K，在初始化表空间后不能再次修改)
    - 解决方案：通过上述方法增加数据文件解决
  - 情况二表空间未满：查询的表空间剩余 400M，且该索引的 next_extent=700MB，即给该索引分配空间时不足
    - 解决方案：重建该索引`alter index index_name_xxx rebuild tablespace tablespace_name_xxx storage(initial 256K next 256K pctincrease 0)`(还未测试)

### No more data to read from socket

- 方向
    - 是否连接不足，参考[数据库无法连接](#数据库无法连接)
    - 是否连接失效
        - 一般由数据库连接池管理，问题不大；但是如果重启了数据库，应用的连接池创建的连接就回失效
        - 分布式数据库中间件，比如 cobar 会定时的将空闲链接异常关闭，客户端会出现半开的空闲链接
    - 是否为内存不足导致
    - 是否为网络原因，路由交换机重启等
- 查询数据库发现报错`ORA-03137`
    - 参考文章
        - [oracle 11.2.0.1告警日志报错ORA-03137与绑定变量窥探BUG](https://developer.aliyun.com/article/314732)
        - [一次关闭绑定变量窥探_optim_peek_user_binds导致的存储过程缓慢故障](https://blog.csdn.net/su377486/article/details/106784943)
        - http://www.oracleops-support.com/2017/12/troubleshooting-ora-3137.html
        - http://blog.chinaunix.net/uid-116213-id-81735.html
    - 临时解决
        - 客户端报错`No more data to read from socket`，数据库发现报错`ORA-03137`，且在产生大量incident日志文件；但是此问题是最近才偶尔出现此问题，一般不会是客户端连接池问题，初步诊断为数据库问题，暂时不好升级Oracle和关闭_optim_peek_user_binds参数
        - 选择先升级ojdbc.jar驱动程序为11.2.0.2，并优化此SQL语句
            - JDBC 下载地址: https://www.oracle.com/database/technologies/appdev/jdbc-drivers-archive.html
            - JDBC 11.2下载地址: https://www.oracle.com/jp/technical-resources/articles/features/jdbc/jdbc.html

```bash
Dump continued from file: /u01/app/oracle/diag/rdbms/orcl/orcl/trace/orcl_ora_20306.trc
ORA-03137: TTC protocol internal error : [12333] [23] [115] [101] [] [] [] []

========= Dump for incident 136947 (ORA 3137 [12333]) ========

*** 2023-06-25 10:05:00.301
dbkedDefDump(): Starting incident default dumps (flags=0x2, level=3, mask=0x0)
----- Current SQL Statement for this session (sql_id=03745jpg6vak1) -----
SELECT ID, SERVICE_NAME, NODE_NAME, PARAMETER, YES_STATUS, ERROR_MSG, SEND_TYPE, INVOKE_TYPE, INPUTER, INPUT_TM, UPDATER, UPDATE_TM FROM MY_TEST WHERE ((SERVICE_NAME IN (:1 ) AND YES_STATUS = :2 )) ORDER BY INPUT_TM ASC



Dump continued from file: /u01/app/oracle/diag/rdbms/orcl/orcl/trace/orcl_ora_888.trc
ORA-03137: TTC protocol internal error : [12333] [23] [115] [101] [] [] [] []

========= Dump for incident 137083 (ORA 3137 [12333]) ========

*** 2023-06-25 10:02:00.541
dbkedDefDump(): Starting incident default dumps (flags=0x2, level=3, mask=0x0)
----- Current SQL Statement for this session (sql_id=03745jpg6vak1) -----
SELECT ID, SERVICE_NAME, NODE_NAME, PARAMETER, YES_STATUS, ERROR_MSG, SEND_TYPE, INVOKE_TYPE, INPUTER, INPUT_TM, UPDATER, UPDATE_TM FROM MY_TEST WHERE ((SERVICE_NAME IN (:1 ) AND YES_STATUS = :2 )) ORDER BY INPUT_TM ASC



Dump continued from file: /u01/app/oracle/diag/rdbms/orcl/orcl/trace/orcl_ora_26687.trc
ORA-03137: TTC protocol internal error : [3120] [] [] [] [] [] [] []

========= Dump for incident 137131 (ORA 3137 [3120]) ========

*** 2023-06-25 10:06:27.571
dbkedDefDump(): Starting incident default dumps (flags=0x2, level=3, mask=0x0)
----- Current SQL Statement for this session (sql_id=03745jpg6vak1) -----
SELECT ID, SERVICE_NAME, NODE_NAME, PARAMETER, YES_STATUS, ERROR_MSG, SEND_TYPE, INVOKE_TYPE, INPUTER, INPUT_TM, UPDATER, UPDATE_TM FROM MY_TEST WHERE ((SERVICE_NAME IN (:1 ) AND YES_STATUS = :2 )) ORDER BY INPUT_TM ASC
```

## 常用操作

- sql 命令行中执行 bash 命令加`!`，如`!ls`查看目录

### 系统相关

#### 管理员登录

- sqlplus 本地登录：`sqlplus / as sysdba`，以 sys 登录。sys 为系统管理员，拥有最高权限；system 为本地管理员，次高权限
- sqlplus 远程登录：`sqlplus aezo/aezo@192.168.1.1:1521/orcl` (orcl 为远程服务名)，失败可尝试如下命令：
  - `sqlplus /nolog`
  - `connect aezo/aezo@192.168.1.1:1521/orcl;`，或者使用配置好的服务名连接`conn aezo/aezo@remote_orcl`
- pl/slq 管理员登录：用户名密码留空，Connect as 选择 SYSDBA 则默认以 sys 登录。登录远程只需要在 tnsnames.ora 进行网络配置即可

#### 常用文件路径

```txt
监听配置文件: C:\software\oracle\product\11.2.0\dbhome_1\NETWORK\ADMIN\listener.ora
PLSQL TNS配置: C:\software\oracle\product\11.2.0\dbhome_1\NETWORK\ADMIN\tnsnames.ora

监听日志: C:\software\oracle\diag\tnslsnr\iZkfy11io8che2Z\listener\alert\log.xml
监听跟踪日志: C:\software\oracle\diag\tnslsnr\iZkfy11io8che2Z\listener\trace\listener.log 日志文件到达4G会导致数据库无法创建新的连接
Trace日志: C:\software\oracle\diag\rdbms\orcl\orcl\trace
Alter日志: C:\software\oracle\diag\rdbms\orcl\orcl\alert
```

#### 执行脚本

- plsql 打开命令行窗口，执行 sql 文件：**`start D:\sql\my.sql`** 或 `@ D:/sql/my.sql`（部分语句需要执行`commit`提交，建议 start）
    - `ALTER SESSION SET CURRENT_SCHEMA = SCOTT;` 切换 schema
    - sqlplus 执行 PL/SQL 语句或执行SQL文件时，在输入完语句后回车一行输入`/`(或者出现了数字行也可输入/再回车)
- bat 脚本(data.bat)：`sqlplus user/password@serverip/database @"%cd%\data.sql"` (data.sql 和 data.bat 同级，此处只能用@)
- 后台运行脚本 `nohup bash run.sh > run.log 2>&1 &`

```bash
# 下面的文件都不要加空行
# run.sh
sqlplus smalle/123456@ASF_PROD <<EOF
@ ./run.sql
EOF

# run.sql
call p_customer_exists_sync();
```

#### sqlplus使用技巧

- **sqlplus 执行 PL/SQL 语句或执行SQL文件时，在输入完语句后回车一行输入`/`**(或者出现了数字行也可输入/再回车)
- `set line 1000;` **可适当调整没行显示的宽度(适当美化)**
  - 永久修改显示行跨度，修改`glogin.sql`文件，如`/usr/lib/oracle/11.2/client64/lib/glogin.sql`，末尾添加`set line 1000;`
  - `set linesize 10000;` -- 设置整行长度，linesize 说明 https://blog.csdn.net/u012127798/article/details/34146143
  - `col username for a20` -- 设置username这个字段的列宽为20个字符
- `set serverout on;` 开启输出
  - 否则执行`begin dbms_output.put_line('hello world!'); end;` 无法输出
- `set autotrace on` 后面运行的 sql 会自动进跟踪统计
- 删除字符变成`^H`解决办法：添加`stty erase ^H`到`~/.bash_profile`，或者按住Shift进行删除   
- `show errors;` 查看编译错误
- 导入sql文件等，创建存储过程需要输入`/`进行执行；如果文件中有多个存储过程应该在文件的每个存储过程结束后增加`/`

### 数据库相关

#### 连接/进程数

```sql
-- 查询数据库当前连接数
select count(*) from v$session;
-- 查询当前数据库不同用户的连接数 (username为空的一般为系统进程，有20个ACTIVE左右)
-- select username,count(username) from v$session where username is not null group by username;

-- 查询数据库最大连接数(默认150, 如果java客户端比较多应该设置大一些)
select value from v$parameter where name = 'processes'; -- show parameter processes
alter system set processes = 500 scope = spfile; -- 修改后需要重启数据库

-- 查询连接信息(sid 为 session, spid 为此会话对应的系统进程 id)
-- java客户端连接的一般 TERMINAL=unknown, PROGRAM=JDBC Thin Client (PLSQL一般为plsqldev.exe)
select * from v$session a,v$process b where a.PADDR=b.ADDR and a.USERNAME = 'SCOTT';
```

#### 表空间

- [表空间不足/扩容参考下文](#表空间不足)
- oracle 和 mysql 不同，创建表空间相当于 mysql 的创建数据库。创建了表空间并没有创建数据库实例 [^2]
- oracle自带表空间：SYSTEM、SYSAUX、TEMP、UNDO、USERS

```sql
sqlplus / as sysdba

-- 创建表空间，要先创建好`/u01/app/oracle/oradata/orcl`目录，最终会产生一个DEMO01文件(Windows上位大写)，表空间之后可以修改
-- 此处是创建一个初始大小为 500m 的表空间，当空间不足时每次自动扩展 10m，无限扩展(oracle 有限制，最大扩展到 32G，仍然不足则需要添加表空间数据文件)
create tablespace demo datafile '/u01/app/oracle/oradata/orcl/DEMO01' size 500m autoextend on next 10m maxsize unlimited extent management local autoallocate segment space management auto;

-- 删除表空间(包含数据和数据文件，可先删除用户)
-- drop tablespace demo; -- 只删除表空间引用，数据文件还在
drop tablespace demo including contents and datafiles;

-- 扩展：创建用户并赋权(新创建项目时一般新建表空间和用户)
-- 12c开始，在CDB容器中创建用户，用户名需要以`c##`前缀开头
create user test identified by test_pass default tablespace demo;
grant create session to test;
grant unlimited tablespace to test;
grant dba to test; -- 导入导出时，只有 dba 权限的账户才能导入由 dba 账户导出的数据，因此不建议直接设置用户为 dba

-- 删除用户
drop user test cascade;
```

#### 锁表

```sql
-- 查询被锁表的信息（多刷新几次，应用可能会临时锁表）
select s.sid, s.serial#, o.woner, o.object_name, l.*, o.*, s.* FROM gv$locked_object l, dba_objects o, gv$session s
    where l.object_id = o.object_id and l.session_id = s.sid;
-- 关闭锁表的连接：alter system kill session '200, 50791';
alter system kill session '某个sid, 某个serial#';
```

#### 索引

- 索引在逻辑上和物理上都与相关的表和数据无关，当创建或者删除一个索引时，不会影响基本的表 [^4]
- 进行索引操作建议在无其他链接的情况下，或无响应写操作的情况下，数据量越大创建索引越耗时
- Oracle 在创建时会做相应操作，因此创建后就会看到效果，无需重启服务
- 索引是全局唯一的
- 索引Hint: 参考[Oracle-Hint](/_posts/db/sql-optimization.md#oracle-hint)
- 创建索引语法

  ```sql
  CREATE [UNIQUE] | [BITMAP] INDEX index_name  --unique表示唯一索引（index_name全局唯一）
  ON table_name([column1 [ASC|DESC],column2    --bitmap，创建位图索引
  [ASC|DESC],…] | [express])
  [TABLESPACE tablespace_name]
  [PCTFREE n1]                                 --指定索引在数据块中空闲空间
  [STORAGE (INITIAL n2)]
  [NOLOGGING]                                  --表示创建和重建索引时允许对表做DML操作，默认情况下不应该使用
  [NOLINE]
  [NOSORT];                                    --表示创建索引时不进行排序，默认不适用，如果数据已经是按照该索引顺序排列的可以使用
  ```

- **create、rebuild 对大表进行索引操作时切记加上`online`参数，此时 DDL 与 DML 语句可以并行运行，防止阻塞(online则不会锁表，仍然可执行DML语句).** [^11]

```sql
-- 创建索引
create index index_test_id on t_test(id) online;
-- 重命名索引
alter index index_test_id rename to index_test_id2 online;
-- 重建索引
alter index index_test_id rebuild online;
-- 删除索引
drop index index_test_id online;
-- 查看索引
select * from all_indexes where table_name='t_test';

-- 1.分析索引
analyze index index_test_id validate structure;
-- 2.查看索引分析结果
select height,DEL_LF_ROWS/LF_ROWS from index_stats;
-- 3.查询出来的 height>=4 或者 DEL_LF_ROWS/LF_ROWS>0.2 的场合, 该索引考虑重建
alter index index_test_id rebuild online;
```

### 用户相关

#### 用户基本操作

- 基本操作

```sql
-- 查看所有用户
select username from dba_users;

-- 创建用户，默认使用的表空间是`USERS`(用户名不区分大小写，密码区分)
create user smalle identified by smalle;
-- 创建用户并指定默认表空间
create user smalle identified by smalle default tablespace aezocn;

-- 删除用户(cascade连带用户数据)
drop user smalle cascade;

-- 修改用户密码
alter user scott identified by tiger;
-- 修改用户表空间
alter user smalle default tablespace aezocn;
```
- 授权

```sql
-- 授予 samlle 用户创建 session 的权限，即登陆权限
grant create session to samlle;
-- 授予 samlle 用户使用表空间的权限
grant unlimited tablespace to samlle;
-- 授予管理权限(有 dba 角色就有建表等权限)
grant dba to samlle;
-- 赋予 smalle 用户查询 TEST 用户的 ZIP_SALES_TAX_LOOKUP 表权限
grant select on TEST.ZIP_SALES_TAX_LOOKUP to smalle;

-- 赋予创建别名权限
grant create synonym to smalle;
-- 添加别名，否则 smalle 用户查询 test 用户的表必须加`test.`，添加别名后省略`test.`
create or replace SYNONYM SMALLE.ZIP_SALES_TAX_LOOKUP FOR TEST.ZIP_SALES_TAX_LOOKUP;
```
- 创建 dba 账户

```sql
create user smalle identified by smalle default tablespace aezocn;
grant create session to smalle; -- 授予smalle用户创建session的权限，即登陆权限
grant unlimited tablespace to smalle; -- 授予smalle用户使用表空间的权限
grant dba to smalle; -- 授予管理权限(有dba角色就有建表等权限)

-- dba权限
select * from dba_role_privs where granted_role='DBA'; -- 查看具有dba权限的用户
grant dba to samlle; -- 授予dba权限
revoke dba from samlle; -- 取消dba权限
```
- 密码过期(ORA-28001)
    - 重新设置密码即可 `alter user aezo identified by aezo;`
    - 设置永久不过期 `alter profile default limit password_life_time unlimited;`
- 解锁用户(无需重启 oracle 服务)

```sql
alter user scott account unlock; -- 新建数据库scott默认未解锁
-- alter profile default limit failed_login_attempts unlimited; -- 有时候解锁失败，是因为登录失败此处还没重置，可先设置为不限制失败登录次数
commit;
```

#### 创建只读用户

```sql
-- 12c开始，在CDB容器中创建用户，用户名需要以`c##`前缀开头
create user smalle identified by smalle default tablespace aezo; -- 创建用户
grant create session to smalle; -- 赋予登录权限
grant select on AEZO.ZIP_SALES_TAX_LOOKUP to smalle; -- 赋予smalle查询AEZO用户的ZIP_SALES_TAX_LOOKUP表权限（可使用下列批量赋权语句）
grant create synonym to smalle; -- 赋予创建别名权限
create or replace SYNONYM smalle.yothers_advice_collection FOR AEZO.yothers_advice_collection; -- 创建表别名（同义词），之后smalle查询AEZO的这张表可直接使用表名（可使用下列语句进行批量设置）

-- 批量赋值表查询权限
-- （1） 使用游标将AEZO用户所有的表的查询权限赋给smalle用户（推荐）
declare
  table_owenr_user    VARCHAR2(200) := 'AEZO'; -- TODO 修改表所属用户名(注意要大写)
  table_grant_user    VARCHAR2(200) := 'smalle'; -- TODO 修改表授权用户名(此处大小写无所谓)
  cursor c_tabname is select table_name from dba_tables where owner = table_owenr_user;
  v_tabname dba_tables.table_name%TYPE;
  sqlstr    VARCHAR2(200);
begin
  open c_tabname;
  loop
    begin -- loop...end loop;语句捕获异常需要begin...end包裹
    fetch c_tabname into v_tabname;
    exit when c_tabname%NOTFOUND;
    sqlstr := 'grant select on ' || table_owenr_user || '.' || v_tabname || ' to ' || table_grant_user;
    -- sqlstr := 'create or replace SYNONYM ' || table_grant_user || '.' || v_tabname || ' for ' || table_owenr_user || '.' || v_tabname; -- 设置表别名
    execute immediate sqlstr;
    exception
      when others then dbms_output.put_line(sqlstr); -- 捕获异常继续下一次循环
    end;
  end loop;
  close c_tabname;
end;
-- （2） 通过查询获取赋值语句，然后运行每一行赋值语句
select 'grant select on ' || owner || '.' || object_name || ' to smalle;'
  from dba_objects
 where owner in ('AEZO')
   and object_type = 'TABLE';

-- 批量设置表别名（同义词） => **将 AEZO 的表赋给 SMALLE(需要通过SMALLE账号执行)**
-- （1）通过存储过程，参考上述代码（取消注释：sqlstr := 'create or replace SYNONYM ' || [table_grant_user] || '.' || [v_tabname] || ' for ' || [table_owenr_user] || '.' || [v_tabname];）
-- （2）获取添加表别名语句
select 'create or replace synonym SMALLE.' || object_name || ' for ' || owner || '.' || object_name || ';'
   from dba_objects
   where owner in ('AEZO') and object_type in ('TABLE', 'SEQUENCE', 'VIEW', 'FUNCTION', 'PROCEDURE');

-- 存储过程中无法使用同义词,提示无权限解决办法
-- 批量查询出授权语句到PUBLIC: 如果需要对同义词对象新增修改等操作则select all, 如果只需要查询可grant all
-- 可在SMALLE用户中执行，将AEZO.TEST赋给PUBLIC(前提是SMALLE之前已经得到过同义词授权)，之后可以在SMALLE存储过程中使用AEZO的表
select 'grant all on ' || TABLE_OWNER || '.' || TABLE_NAME || ' to PUBLIC;' from dba_synonyms WHERE OWNER='SMALLE';
-- select 'grant select on '||SYNONYM_NAME || ' to PUBLIC; ' from dba_synonyms WHERE OWNER='TEST'
```

#### 权限其他

- 同一DB，USER1使用USER2的表创建视图，容易报无权限（尽管将USER1设置成功了DBA，且将相关表设置了别名）
    - 解决办法：通过USER2执行`GRANT SELECT ANY TABLE TO USER1;`之后再创建视图

### 查询相关

- 系统
  - 查看服务是否启动：`tnsping local_orcl` cmd 直接运行
    - 远程查看(cmd 运行)：`tnsping 192.168.1.1:1521/orcl`、或者`tnsping remote_orcl`(其中 remote_orcl 已经在本地建立好了监听映射，如配置在 tnsnames.ora)
    - 如果能够 ping 通，则说明客户端能解析 listener 的机器名，而且 lister 也已经启动，但是并不能说明数据库已经打开，而且 tsnping 的过程与真正客户端连接的过程也不一致。但是如果不能用 tnsping 通，则肯定连接不到数据库
    - **实例 tnsping 突然高达 1w 多毫秒**，如`listener.log`(/u01/oracle/diag/tnslsnr/oracle/listener)日志文件过大，可重新创建一个此日志文件，或修改listener.ora进行自动分割(参考[Oracle安装](#Oracle安装)). [^10]
  - 查看表空间数据文件位置：`select file_name, tablespace_name from dba_data_files;`
  - 查询数据库字符集 
    - 查看oracle服务端编码：select * from sys.nls_database_parameters;
        - `select * from nls_database_parameters where parameter='NLS_CHARACTERSET';`(如`AL32UTF8`)
        - 查看服务器语言和字符集 `select userenv('language') from dual;` 如：`AMERICAN_AMERICA.AL32UTF8`、`SIMPLIFIED CHINESE_CHINA.ZHS16GBK`
            - 格式为`language_territory.charset`：Language 指定服务器消息的语言，territory 指定服务器的日期和数字格式，charset 指定字符集
            - 出现过linux运行是AMERICAN_AMERICA.AL32UTF8，windows运行是SIMPLIFIED CHINESE_CHINA.AL32UTF8
    - 查看client编码：select * from sys.nls_session_parameters;
        - 在windows平台下，就是注册表里面`HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE\KEY_OraDb11g_home1\NLS_LANG`
        - PL/SQL则看环境变量`NLS_LANG`
    - 查询dmp文件的字符集
        - 用oracle的exp工具导出的dmp文件也包含了字符集信息，dmp文件的第2和第3个字节记录了dmp文件的字符集。如果dmp文件不大，比如只有几M或几十M，可以用UltraEdit打开(16进制方式)，看第2第3个字节的内容，如0354，然后用以下SQL查出它对应的字符集
        - `select nls_charset_name(to_number('0354','xxxx')) from dual;` 结果是ZHS16GBK
    - 参考(修改字符集)：http://blog.itpub.net/29863023/viewspace-1331078/
        - 修改服务端编码(在oracle 11g上通过测试)

            ```bash
            SQL> sqlplus / as sysdba;
            SQL> shutdown immediate;
            SQL> startup mount;
            SQL> alter system enable restricted session;
            SQL> alter system set job_queue_processes=0;
            SQL> alter database open;
            SQL> alter database character set internal_use ZHS16GBK; # 这里为你所要转换成的字符集，跳过超子集检测
            SQL> shutdown immediate;
            SQL> startup
            ```
        - 修改客户端编码
            - 运行regedit命令，在注册表中找到这个下的键HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE\HOME0\NLS_LANG，将其值改为上述服务器端你所修改的字符编码值
            - 点击我的电脑右键》属性》高级》环境变量》新建一个用户变量：NLS_LANG=SIMPLIFIED CHINESE_CHINA.ZHS16GBK
- 用户相关查询
  - **查看当前用户默认表空间**：`select username, default_tablespace from user_users;`(以 dba 登录则结果为 SYS 和 SYSTEM)。**user_users 换成 dba_users 则是查询所有用户默认表空间**
  - 查看当前用户角色：`select * from user_role_privs;`
  - 查看当前用户系统权限：`select * from user_sys_privs;`
  - 查看当前用户表级权限：`select * from user_tab_privs;`
  - 查看用户下所有表：`select * from user_tables;`
  - DBA 相关查询见数据库字典
- 数据字典 [^5]
  - `user_`：记录用户对象的信息，如 user_tables 包含用户创建的所有表，user_views，user_constraints 等
  - `all_`：记录用户对象的信息及被授权访问的对象信息
  - `dba_`：记录数据库实例的所有对象的信息，如 dba_users 包含数据库实例中所有用户的信息。dba 的信息包含 user 和 all 的信息。大部分是视图
  - `v$`：当前实例的动态视图，包含系统管理和优化使用的视图。等价于`v_$`
  - `gv_`：分布环境下所有实例的动态视图，包含系统管理和优化使用的视图，这里的 gv 表示 global v\$的意思
- 基本数据字典
  - 常用
    - `dict` 构成数据字典的所有表的信息
    - `dba_users` 所有的用户信息（oracle 密码是加密的，忘记密码只能修改）
    - `dba_tables` 所有用户的所有表的信息
    - `dba_tablespaces` 记录系统表空间的基本信息；
    - `dba_data_files` 记录系统数据文件及表空间的基本信息；
    - `dba_free_space` 记录系统表空间的剩余空间的信息；
  - 其他
    - `cat` 当前用户可以访问的所有的基表
    - `tab` 当前用户创建的所有基表，视图，同义词等
    - `dba_views` 所有用户的所有视图信息
    - `dba_constraints` 所有用户的表约束信息
    - `dba_indexes` 所有用户索引的简要信息
    - `dba_ind_columns` 所有用户索引的列信息
    - `dba_triggers` 所有用户触发器信息
    - `dba_source` 所有用户存储过程源代码信息
    - `dba_procedus` 所有用户存储过程
    - `dba_segments` 所有用户段（表，索引，cluster）使用空间信息
    - `dba_tab_columns` 所有用户的表的列（字段）信息
    - `dba_synonyms` 所有用户同义词信息
    - `dba_sequences` 所有用户序列信息
    - `dba_extents` 所有用户段的扩展段信息
    - `dba_objects` 所有用户对象的基本信息（包括素引，表，视图，序列等）
- 数据库组件相关的数据字典(`v$`代表视图，等价于`v_$`)
  - 基本
    - `v$database` 同义词 v\_\$database，记录系统的运行情况
    - `v$instance` 实例信息
    - `v$parameter` **记录系统各参数的基本信息**
    - `v$sql` 列举了共享 SQL 区(Shared SQL Area)中的 SQL 统计信息，这个视图中的信息未经分组，每个 SQL 指针都包含一条独立的记录
    - `v$sqlarea` 列出了共享 SQL 区(Shared SQL Area)中的 SQL 统计信息，根据 SQL_TEXT 进行的一次汇总统计(对 SQL_TEXT 进行 group by)
    - `v$sqltext`
  - 相关文件
    - `v$controlfile` 控制文件信息
    - `v$datafile` 数据文件信息
    - `v$logfile` 日志文件(redo)
    - `v$tempfile` 临时文件
    - `v$diag_info` 日志目录(alert/trace)
    - `v$controlfile_record_section` 记录系统控制运行的基本信息
    - `v$filestat` 记录数据文件读写的基本信息
  - 举例

    ```sql
    -- 以下4种文件默认都在安装目录的oradata下，如C:/soft/oracle/oradata/orcl
    select name from v$datafile; -- 数据文件信息
    select name from v$controlfile; -- 控制文件
    select * from v$logfile; -- (redo)日志文件
    select * from v$tempfile; -- 临时文件
    -- (alert/trace) 日志目录
    select * from v$diag_info;

    -- v$sql 和 v$sqlarea 的区别：https://blog.51cto.com/gldbhome/1166576。字段详细说明：http://blog.itpub.net/31397003/viewspace-2142838/
    -- v$sql的hash_value：基于(sql)语句实际的物理对象来计算，如两个用户的同一表名，查询sql语句一样，物理对象却是两个，因此在v$sql中有两条记录，但是两个用户多次查询，只会在各自的记录上进行统计executions
    -- v$sqlarea的hash_value：仅仅基于sql_text进行合并计算，上述情况将只有一条记录，两个用户多次查询只会在这条记录上进行累计
    /*
        sql_id          缓存在高速缓冲区（library cache）中的SQL父游标的唯一标识ID
        sql_text        当前sql指针的前1000个字符
        sql_fulltext    完整的sql(clob)
        executions      执行次数
        disk_reads      这个子指针disk read(物理读)的次数
        buffer_gets     这个子指针的buffer gets(缓存读)数量
        optimizer_mode  sql执行的优化器模式：ALL_ROWS、CHOOSE
        optimizer_cost  sql执行成本
        cpu_time        消耗CPU时间(us微秒=1/1000000s)
        elapsed_time    公式：elapsed_time(响应时间) = cpu_time(服务计算时间)  + wait_time(等待时间)，如果是多线程，有可能 cpu_time > elapsed_time
        last_load_time  最近执行时间点(24h制)
        hash_value      在library cache中父指针的hash value值
    */
    select sql_text,executions,disk_reads,optimizer_mode,buffer_gets,hash_value from v$sql where sql_text='select count(*) from emp';
    /*
        sql_text        当前指针的前1000个字符
        version_count   在cache中这个父指针下存在的子指针的数量
        executions      总的执行次数，包含所有子指针执行次数的汇总
        disk_reads      所有子指针的disk reads总和
        buffer_gets     所有子指针的buffer gets总和
        optimizer_mode  sql执行的优化器模
        hash_value      父指针的hash value
    */
    select sql_text,executions,disk_reads,buffer_gets,hash_value,version_count from v$sqlarea where sql_text='select count(*) from emp';
    ```
- 表信息和字段信息

```sql
-- 查询所有数据库(需要一定权限)：由于Oralce没有库名,只有表空间,所以Oracle没有提供数据库名称查询支持，只提供了表空间名称查询。
select * from v$tablespace;

-- 查询当前数据库中所有表名
select * from user_tables; -- 用户表
select table_name from all_tables; -- 所有用户表
select * from dba_tables; -- 所有用户表和系统表
-- 获取表注释/备注，对应还有 user_tab_comments
select t.TABLE_NAME, s.comments from dba_tables t 
join dba_tab_comments s on s.owner = t.OWNER and s.table_name = t.TABLE_NAME
where t.OWNER = 'USERS'
order by t.TABLE_NAME;

-- 查询指定表中的所有字段名和字段类型，表名要全大写。对应的还有 user_tab_columns 表
select t.table_name, s.comments, tc.column_name, tc.data_type, cc.comments as col_comments
from dba_tables t 
join dba_tab_comments s on s.owner = t.owner and s.table_name = t.table_name
left join dba_tab_columns tc on tc.owner = 'TEST' and tc.table_name = t.table_name
left join dba_col_comments cc on cc.owner = 'TEST' and cc.table_name = t.table_name and cc.column_name = tc.column_name
where t.owner = 'TEST' and t.table_name = 'T_TEST'
order by t.table_name, tc.column_name;
```

### 日志文件

- oracle 的日志文件有几种
  - `alert警告日志`
    - 在 10g 版本系统初始化参数文件设置的`show parameter background_dump_dest`对应的就是它的位置
    - 在 11g 以及 ORACLE 12c 中告警日志文件目录 **`select * from v$diag_info;`** (11g 以上主要是因为引入了 ADR：Automatic Diagnostic Repository 一个存放数据库 alert 日志、trace 日志目录)
  - `trace日志`：**追踪文件**，记录各种 sql 操作及所消耗的时间等，根据 trace 文件就可以了解哪些 sql 导致了系统的性能瓶颈，进而采取恰当的方式调优
    - 10g 对应系统初始化参数文件参数`show parameter user_dump_dest`
    - 11g 同 alert 日志可通过`select * from v$diag_info;`查看日志文件位置(ADR Home)
    - 日志会一直保留，不会自动删除
  - `audit日志`：审计的信息
    - 10g 对应系统初始化参数文件参数`audit_file_dest`
  - `redo日志`：存放数据库的更改信息
    - `select member from v$logfile;` member 就代表它的位置
  - `归档日志`：redo 日志的历史备份
    - `select * from v$parameter where name like 'log_archive_dest%';`
- 日志分析

> `*.trc`：Sql Trace Collection file，`*.trm`：Trace map (.trm) file.Trace files(.trc) are sometimes accompanied by corresponding trace map (.trm) files, which contain structural information about trace files and are used for searching and navigation.

```bash
## 如ADR Home日志文件目录为=/u01/app/oracle/diag/rdbms/orcl/orcl, 下面再分子目录
# alert 警告日志，如报错ORA-04030，详细日志会记录在trace目录
# trace(日志主要看这个目录)
    # alert_orcl.log 为警告日志(一般只有一个)
    # *.trc 为日志追踪文件. 如 orcl_ora_18723.trc 当前的Trace文件(Default Trace File)
    # *.trm 为追踪文件映射信息
    # cdmp_20191212101335 当一个进程崩溃或遇到异常时，ADR 会自动创建cdmp_<date-time>目录保存诊断跟踪日志和核心转储文件
# incident 每当发生错误时，oracle会分配一个INCIDENT_ID号，并创建incdir_<INCIDENT_ID>目录(好像是从trace目录dump过来的日志)。清理参考(也可直接删除目录下文件)：https://blog.csdn.net/royzhang7/article/details/78957817
# cdump
# hm
# 清理7天前日志脚本如: find ./ -mtime +3 -name "*.trc" | xargs rm -rf (.trm文件同理)
select * from v$diag_info; # 查看日志目录(ADR Home)

# 列举23号日期的trc文件。如`dbcloud_cjq0_22515.trc` dbcloud为实例名，cjq0_22515为自动生成的索引
ll -rt *.trc | grep ' 23 '
# 查看23号的oracle trc日志，并找出日志中出现ORA-的情况
ll -hrt *.trc | grep ' 23 ' | awk '{print $9}' | xargs grep 'ORA-'
# 使用oracle自带工具tkprof(/u01/app/oracle/product/11.2.0/bin)分析trc文件。参考：http://www.51testing.com/html/34/60434-225024.html
tkprof /u01/app/oracle/diag/rdbms/orcl/orcl/trace/orcl_dbrm_18576.trc orcl_dbrm_18576.txt sys=no sort=prsela,exeela,fchela
cat orcl_dbrm_18576.txt # 查看分析结果
```

#### 宕机分析

- ORA-27157 ORA-27300 ORA-27301 ORA-27302 错误，这些错误表明共享内存/信号灯在操作系统级别发生了某些情况，信号集可以手动删除，或者由于某种原因由于硬件错误而濒临死亡
    - 参考文章
        - https://ora4all.blogspot.com/2017/10/ora-27300-ora-27301-ora-27302-ora-27157.html
        - https://blog.csdn.net/turk/article/details/53373510
    - 操作过程

```bash
# 进入日志文件目录，方式参考上文
# 查看20号的oracle trc日志，并找出日志中出现ORA-的情况
ll -hrt *.trc | grep ' 20 ' | awk '{print $9}' | xargs grep 'ORA-'
# 结果如下(出现多次)
orcl_gen0_16692.trc:ORA-27157: OS post/wait facility removed
orcl_gen0_16692.trc:ORA-27300: OS system dependent operation:semop failed with status: 43
orcl_gen0_16692.trc:ORA-27301: OS failure message: Identifier removed
orcl_gen0_16692.trc:ORA-27302: failure occurred at: sskgpwwait1
...
# 后来查找操作历史(history)，发现有国外IP登录操作服务器，还清除了操作历史，幸好之前增加了[记录命令执行历史到日志文件](/_posts/linux/linux.md#记录命令执行历史到日志文件)功能才发现

# 解决办法：事先已重新重启过服务器，事后增加安全措施
```

## 业务场景

### 数据恢复

- 基于`of timestamp`恢复，用于少量数据被误删除
    - 如果报错`ORA-01555: 快照过旧: 回退段号...过小`(说明快照数据已经被Oracle清理了，差不多可以保留1个小时的快照)

```sql
-- 查询某个时间点my_table表的数据
select * from my_table as of timestamp to_timestamp('2000-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') where sex = 1;
-- 手动恢复
```

### 表空间相关

#### 表空间数据文件物理位置迁移

- 可以移动任何表空间的数据文件，包括 system 表空间(windows oracle 11g 测试通过)

```sql
sqlplus / as sysdba
shutdown immediate;
cp c:/oracle/oradata/orcl/test.dbf d:/oradata/orcl/test.dbf
startup mount;
alter database rename file 'c:/oracle/oradata/orcl/test.dbf' to 'd:/oradata/orcl/test.dbf';
alter database open; -- 运行后即可正常访问数据库数据

-- 重启验证
shutdown immediate;
startup
rm c:/oracle/oradata/orcl/test.dbf -- 可正常使用后，删除历史文件
```

#### 对象所在表空间迁移

- 查询表空间使用对象信息，及对象迁移(在进行表或索引移动时，可能会导致一些性能下降或锁定表)

```sql
-- 查询表空间使用对象信息
select owner, tablespace_name, segment_type, segment_name, sum(bytes)/1024/1024  as "对象大小(M)"
from dba_segments
where tablespace_name = 'users'
group by owner, tablespace_name, segment_type, segment_name
order by sum(bytes) desc;

-- 修改表所在表空间
alter table user1.tb_test move tablespace new_tablespace_xxx;
-- select 'alter table user1.'|| table_name ||' move tablespace new_tablespace_xxx;' from user_tables;

-- 修改索引所在表空间
alter index user1.idx_test rebuild tablespace new_tablespace_xxx;
-- select 'alter index user1.'|| index_name ||' rebuild tablespace new_tablespace_xxx;' from user_indexes;
-- (可选)迁移后有可能索引对象状态异常，可进行再次重建
-- select 'alter index user1.'|| INDEX_NAME ||' rebuild;' from dba_indexes where owner = 'user1' and status = 'UNUSABLE';
alter index user1.idx_test rebuild;

-- 修改LOB对象所在表空间
-- lob括号内填写字段名，而不是LOB名(SYS_LOB0000083064C00016$$等)
-- 且会同时迁移对应索引，即包含: LOBSEGMENT/LOBINDEX
alter table user1.tb_test move lob(col_xxx) store as (tablespace new_tablespace_xxx);
-- 基于查询dba_lobs获取所有LOB对象信息
select 'alter table user1.'|| table_name ||' move lob('|| column_name ||') store as (tablespace new_tablespace_xxx);'
from dba_lobs 
where segment_name in
    (select segment_name from dba_extents
    where dba_lobs.owner = 'user1'
    group by segment_name having segment_name like 'SYS_LOB%');
```

#### 删除表空间的某个文件

```sql
-- 未验证数据是否会丢失
-- 操作前需确保删除文件后剩下的文件足够存储原本数据，直接删除某个数据文件(也会在磁盘级别删除)
alter tablespace tablespace_xxx drop datafile '/home/oracle/xxx02.dbf';

-- 扩展(忽略)
-- 将该数据文件从逻辑上下线和删除(此时文件仍然可以查到，且为recover状态)
alter database datafile '/home/oracle/xxx02.dbf' offline drop;
-- 逆操作: 恢复 file#=25 的文件并上线
select file_id, file_name, status, online_status, tablespace_name from dba_data_files;
recover datafile 25;
alter database datafile '/home/oracle/xxx02.dbf' online;
```

#### 删除表空间

- 表空间数据文件丢失时，删除表空间报错`ORA-02449`、`ORA-01115` [^6]

```sql
-- 慎用
-- oracle 数据文件(datafile)被误删除后，只能把该数据文件 offline 后 drop 掉

sqlplus / as sysdba
shutdown abort -- 强制关闭 oracle
startup mount -- 启动挂载
-- 从数据库删除该表空间的数据文件
    -- select file_id, file_name, tablespace_name, status, online_status from dba_data_files; -- 查看表空间数据文件位置及状态
alter database datafile '/home/oracle/xxx.dbf' offline drop;
alter database open;
drop tablespace tablespace_xxx;
```

### 清理存储空间

- [定时清理数据库日志表](/_posts/db/sql-procedure.md#定时清理数据库业务日志表)
- 清理说明
    - delete
        - 删除的表数据减少了，但是表空间占用量不会变。可使用move/shrink进行清理
    - move和shrink的区别：https://www.modb.pro/db/26483
    - lob对象
        - 占用空间可以使用alert、move、truncate直接释放。使用delete、update不直接释放，所占用空间会被后续lob对象使用
- 查看表占用的空间情况SQL参考[表空间不足](#表空间不足)

#### 备份历史数据

- 参考：https://blog.csdn.net/Hehuyi_In/article/details/107775528
- 方法
    - `create table as` 备份老数据
    - `delete` 函数/存储过程/JOB分批提交
    - `shrink` 收缩表空间
- 案例

```sql
-- 将2000年前的数据移到备份表(此处额外创建了一个备份用户方便数据归档：之后只需要备份demo用户下的数据)
-- 此处需要确保create_time为真实时间，防止出现业务上进行复制数据但是create_time没有变的情况导致删除了最近新复制出来的数据
create table demobak.t_table_bak as select * from demo.t_table t where t.create_time < to_date('2000-01-01', 'yyyy-mm-dd'); -- 新表没有字段备注、索引、触发器等

-- 时间案例：总记录900w 待删除记录600w 耗时20m(备份耗时6s)
-- 时间案例：总记录760w 待删除记录450w 耗时10m
-- 时间案例：总记录240w 待删除记录134w 耗时8m(备份耗时20s)
-- 时间案例：总记录100w 待删除记录70w 耗时50s
declare
     cursor del_cur is
        -- t_table需改成被备份表, 及备份条件需修改 (rowid为oracle内置字段)
        select t.rowid row_id from t_table t
        where t.create_time < to_date('2000-01-01', 'yyyy-mm-dd')
        order by t.rowid;
begin
     for v_cusor in del_cur loop
        -- t_table需改成被备份表
        delete from t_table where rowid = v_cusor.row_id;
        if mod(del_cur%rowcount,5000)=0 then
            commit;
        end if;
     end loop;
     commit;
end;
-- 如果误删除，可以通过备份快速恢复
-- insert into t_table select * from demobak.t_table_bak;

-- 重建索引(包括主键索引)
alter index IDX_NAME1 rebuild online;

-- 可考虑是否shrink收缩降低水位(参考下文)
```

#### truncate清理

- `truncate table emp;` oracle清空无用表数据，适用于表中含有大量数据，且全部无用(或者将有用的先备份，然后truncate，最后将数据移动回来)
    - truncate与drop是DDL语句，执行后无法回滚（无法通过binlog回滚）；delete是DML语句，可回滚
    - truncate不会激活与表有关的删除触发器；delete可以
    - **truncate后会使表和索引所占用的空间会恢复到初始大小**；delete操作不会减少表或索引所占用的空间，drop语句将表所占用的空间全释放掉
    - truncate不能对有外键约束引用的表使用
    - 执行truncate需要drop权限
    - 清除后统计user_extents可能暂时没有变化，但是expdp导出数据量明显减少。可手动释放，参考下文
- 外键约束导致无法清理

```sql
-- 查看使用某个表作为外键的表信息
select t1.table_name,
       t2.table_name as "table_name(r)",
       t1.constraint_name,
       t1.r_constraint_name as "constraint_name(r)",
       a1.column_name,
       a2.column_name as "column_name(r)"
from user_constraints t1
join user_constraints t2 on t1.r_constraint_name = t2.constraint_name
join user_cons_columns a1 on t1.constraint_name = a1.constraint_name
join user_cons_columns a2 on t1.r_constraint_name = a2.constraint_name
where t2.table_name = 'my_main_table_xxx';

-- 禁用约束。存在问题，如这个表已经有数据使用了此外键，则清空主表后，启用约束会失败
alter table my_sub_table_xxx disable constraint fk_id;
-- 清空数据
truncate table my_main_table_xxx;
-- 启用约束
alter table my_sub_table_xxx enable constraint fk_id;


-- truncate后还需释放extent，从而统计dba_extents的数值才会正常
alter table server_hit deallocate unused keep 1k;
alter index pk_server_hit deallocate unused keep 1k;
-- 也可生成语句(不会影响表的数据，只是优化存储空间，不过保险起见进行备份数据或只更新truncate相关对象)
select owner, decode(partition_name,
                     null,
                     segment_name,
                     segment_name || ':' || partition_name) objectname ,
       'alter ' || segment_type || ' C##YSS.' ||
       decode(partition_name,
              null,
              segment_name,
              segment_name || ':' || partition_name) ||
       ' deallocate unused keep 1k;  ' scripts,
       segment_type objecttype,
       nvl(bytes, 0) "SIZE",
       nvl(initial_extent, 0) INITIALEXT,
       nvl(next_extent, 0) NEXTEXT,
       nvl(extents, 0) NUMEXTENTS,
       nvl(max_extents, 0) "MAXEXTENTS"
from dba_segments s
where tablespace_name  in ('YSS')
  and owner = 'C##YSS'
  and s.segment_type in ('TABLE','INDEX')
order by nvl(bytes, 0) desc;
```

#### shrink清理

- 特点
    - 可以起到清理存储碎片的功能，类似的如move
    - **只有在HWM调整(cascade)阶段会锁表(只能查询)**，数据重组(compact)阶段可正常增删改
    - 实质上构造一个新表(在内部表现为一系列的DML操作,即将副本插入新位置，删除原来位置的记录)，**因此会产生大量的REDO日志**(`select log_mode from v$database;` 归档模式下一定要注意磁盘空间，NOARCHIVELOG非归档模式则无需考虑)
    - 索引不会损坏，会随着一起收缩
    - lob字段不会级联shrink，需要单独处理
    - **可降低dba_extents表占用空间、dba_tables表水位线、dba_data_files表空间占用统计值**
- 压缩分两个阶段
    - 数据重组(compact)：这个过程是通过一系列的insert delete操作，将数据尽量排在列的前面进行重新组合；**执行时对相关行持有行锁，对业务影响较小**
    - HWM调整(cascade)：这个过程是对HWM的调整，释放空闲数据库；**表上会持有X锁，阻塞DML增删改操作，对业务影响较大，需要在业务空闲时再执行（实际测试过程虽然有锁，但仍然可插入数据）**
- 参考：https://www.cnblogs.com/klb561/p/10995016.html
- **时间记录**
    - 某表540w条记录，HWM高水位线为19.5G，浪费空间18.5G(实际使用空间只有1G，由于表中一个CLOB字段存储了接口请求日志，后期将此字段置空，从而导致空间浪费)。耗时记录：compact阶段耗时105min，cascade阶段耗时10min
- 案例

```sql
-- (可选)需先执行重新统计后，再查看dba_extents表占用空间、dba_tables表水位线、dba_data_files表空间占用才会准确
exec dbms_stats.gather_table_stats(ownname=>'owner_xxx',tabname=> 'table_name_xxx'); -- command窗口执行(会卡一会)
-- 统计表的水位线
select table_name,
        round(((blocks) * 8 / 1024), 2) "高水位空间M",
        round((num_rows * avg_row_len / 1024 /1024), 2) "真实使用空间M",
        round((blocks * 10 / 100) *8 /1024, 2) "预留空间(pctfree)M",
        round((blocks) * 8 / 1024 - (num_rows * avg_row_len / 1024 / 1024) - blocks * 8 * 10 / 100 / 1024, 2) "浪费空间M"
    from dba_tables -- user_tables
    where temporary = 'N' and owner = 'owner_xxx' and table_name = 'table_name_xxx';

-- 基本语法: alter table table_name_xxx shrink space [ <null> | cascade | compact  ];

-- shrink必须开启对象的row movement功能（shrink index 不需要）
-- 但是要注意，该语句会造成引用table_name的对象（如存储过程、包、试图等）变为无效，~执行完最好由utlrp.sql来编译无效对象~
alter table table_name_xxx enable row movement;

-- cascade会产生X锁(阻塞DML，对业务影响较大)；建议可分compact+cascade两步进行，cascade在业务不繁忙的时候进行
alter table table_name_xxx shrink space compact; -- 只收缩表，HWM保持不变；此阶段可正常增删改数据
alter table table_name_xxx shrink space cascade; -- 收缩表并且相关索引也会被收缩，HWM会降低；实际测试过程虽然有锁但仍然可插入数据；包含执行了 alter index index_name_xxx shrink space; -- 收缩索引
-- alter table table_name_xxx shrink space; -- 上述两个命令之和：收缩表，并降低HWM(High Water Mark)
-- (可选)收缩LOB
alter table index_name_xxx modify lob(lob_column_xxx) (shrink space);

-- 迁移完后关闭行移动
alter table table_name_xxx disable row movement;
```

#### move清理

- 特点
    - 可以起到清理存储碎片的功能，类似的如shrink。可解决delete删除数据后占用的表空间不会释放
    - **会锁表(只能查询)，大表谨慎在线操作**
    - **需要保证有足够大的空闲表空间**，迁移5G数据，需要额外空闲5G的表空间来用于存储
    - move一个表到另外一个表空间时，**索引不会跟着一起move，而且会失效(一般需要重建索引)**
        - move过的普通表，在不用到失效的索引的操作语句中，语句执行正常；但如果操作的语句用到了索引（主键当做唯一索引），则此时报告用到的索引失效，语句执行失败；其他如外键，非空约束，缺省值等不会失效
    - **LONG类型不能通过move来传输，尽量不要用LONG类型**
    - LOB类型在建立含有lob字段的表时，oracle会自动为lob字段建立两个单独的segment，一个用来存放数据（segment_type=LOBSEGMENT），另一个用来存放索引（segment_type=LOBINDEX），默认它们会存储在和表一起的表空间。**我们对表move时，LOG类型字段和该字段的索引不会跟着move，必须要单独来进行move**
- 案例

```sql
-- 移动表到当前空间(需要当前表空间有足够的空闲空间来存储当前的数据)，即重建此表数据(清理存储碎片功能)：可解决delete删除的表数据减少了，但是表空间占用量不会变
alter table my_table_xx move;
-- 移动表到users表空间
alter table my_table_xx move tablespace users;
-- 移动LOB类型(CLOB/BLOB)字段my_lob_xx到另外一个表空间(users表空间)。(测试执行完之后plsql卡主，但是最终是成功移动了的，表空间也释放了)
-- 如果已经delete对应表，但是lob字段对应的表空间还没释放，此时可先将此字段移动到临时空间(如TMP，由于数据已经删除了，TMP临时保存此块信息不会耗费太多空间)，再移动回USERS空间
alter table my_table_xx move lob(my_lob_xx) store as (tablespace users);

-- 重建索引(仅移动LOB字段也需要重建索引，索引太多可通过查询生成sql语句)
-- 查询表所具有的索引，可以使用user_indexes视图（索引和主键都在这个视图里可找到）
alter index index_name rebuild online;
alter index pk_name rebuild online;
```

#### UNDOTBS1占用较大表空间

- 主要暂时存储DML操作的数据，主要作用有回滚、恢复实例、读一致性，闪回。

```bash
# 参考：https://blog.csdn.net/wxlbrxhb/article/details/14448777
# 对用户无感，无需重启数据库

# 本视图自启动即保持并记录各回滚段统计项
# USN：回滚段标识; XACTS：活动事务数; RSSIZE：回滚段默认大小; SHRINKS：回滚段收缩次数
select usn, xacts, rssize/1024/1024/1024, hwmsize/1024/10244/1024, shrinks from v$rollstat order by rssize;
# 创建新的 UNDOTBS 表空间并设置自动递增。路径和原表空间保持一致
create undo tablespace undotbs2 datafile '/home/oracle/data/undotbs02.dbf' size 100m autoextend on;
alter database datafile '/home/oracle/data/undotbs02.dbf' autoextend on next 5m;
# 设置系统默认 UNDOTBS 表空间为 undotbs2
alter system set undo_tablespace=undotbs2 scope=both;
# 等待所有的 UNDOTBS1 全部记录从 ONLINE 变成 OFFLINE
select t.segment_name, t.tablespace_name, t.segment_id, t.status
from dba_rollback_segs t 
where t.status = 'ONLINE' and t.tablespace_name = 'UNDOTBS1';
# 确保上面变成 OFFLINE 后，将 tablespace 和对应文件都会 OFFLINE
alter tablespace undotbs1 offline normal;
# (可稳定一段时间后再)删除表空间和对应文件
drop tablespace undotbs1 including contents and datafiles;
# 如果删除表空间文件后磁盘没有变化可查看是否进程还占用。如果还占用有说可杀掉相关进程，但还是建议重启数据库；如果无此问题则无需重启数据库
lsof | grep deleted
```

### 清理数据库日志

- 清理listener.log日志，参考[日常维护](#日常维护)
- 清理trace日志，参考[日志文件](#日志文件)
- 清理redo日志

```sql
-- 删除非活动状态的 redo logfile (STATUS=INACTIVE)
select * from v$logfile;
-- 这只是在数据库中删除了redo logfile，还需手动将磁盘中将redo logfile删除，即彻底删除
alter database drop logfile member 'redo logfile路径名';

-- 删除redo log
select group#, sequence#, members, bytes, status, archived from v$log;
-- 在redo log处于不活跃的状态时(archived=INACTIVE)使用下面命令删除
alter database drop logfile group 1; -- 删除(系统最终至少保留两个文件)
```

### 定时清理数据库业务日志表

- 参考[定时清理数据库业务日志表](/_posts/db/sql-procedure.md#定时清理数据库业务日志表)

### 导入导出

- 导出表结构：使用pl/sql的导出用户对象(不要使用导出表)
- `.dmp`适合大数据导出；`.sql`适合小数据导出(表中含有 CLOB 类型字段则不能导出)
- expdp速度比exp快很多，但是不支持增量备份，适用于全量数据导出导入的场景

#### dmp格式导出导入

- **时间参考**
    - 优化exp/imp导入导出速度 https://www.cnblogs.com/keanuyaoo/p/3275766.html
```bash
# exp/imp：表空间30G，导出dmp文件大小20G(导出时已经使用过压缩模式，可再压缩成zip包为2G)，导出耗时30min；导入耗时1h

# 耗时22min导出16G tar压缩后只有2.5G耗时几分钟
exp sys/manager@orcl file=exp_test_2023101001.dmp log=exp_test_2023101001.log owner=test grants=y direct=y recordlength=65535
# 耗时40min导出16G (加不加compress=y是一样的; 建议加, 有时不加tar包打包还是很大)
exp sys/manager@orcl file=exp_test_2023101002.dmp log=exp_test_2023101002.log owner=test grants=y buffer=409600000
```

##### exp/imp导出
  
- exp/imp备份
    - 参考：https://www.cnblogs.com/songdavid/articles/2435439.html
    - 全量备份脚本参考[shell.md#备份oracle](/_posts/linux/shell.md#备份oracle)、[bat.md#oracle数据库备份](/_posts/lang/bat.md#oracle数据库备份)
    - 输入 `imp/exp 用户名/密码` 可根据提示导入导出。**直接 cmd 运行** [^4]
        - 成功提示 `Export terminated successfully [with/without warnings]`
        - 失败提示 `Export terminated unsuccessfully [with/without warnings]`
    - 导入导出均分为全量模式、用户模式、表模式
    - 支持增量备份，但是增量备份的最小单位是表，只要表一条数据发生变化，就会对全表进行备份(用处不大)
- 注意事项
    - 一定要注意服务器、客户端字符集`NSL_LANG`，否则可能出现数据、字段备注、存储过程等乱码
        - 查询字符集参考本文[查询相关(查询数据库字符集)](#查询相关)
        - **在导入DMP文件前，在客户端导入与服务器一致的环境变量，例如：`set NLS_LANG=AMERICAN_AMERICA.AL32UTF8`**，或者在/etc/profile、oracle用户的`.bash_profile`文件中导出NLS_LANG
    - 如果是基于用户模式进行导入，需要先创建用户和该用户默认表空间，且要保证表空间容量足够
        - 如果容量不够，导入数据会卡主，报错ORA-1659
        - 此时不关闭导入窗口，新增数据空间文件后，程序会自动继续导入，但是可能会出现索引创建失败而丢失
    - 导出时会漏表
        - 参考：https://www.cnblogs.com/abclife/p/10006815.html
        - 在11gR2之前，oracle数据表被创建时就分配空间；
        - 从11gR2(11.2.0.1)中引入了一个新特性：deferred segment creation。11gR2之后，参数deferred_segment_creation默认是true，表示表中插入第一条数据才会分配磁盘空间。**空表还没有在磁盘上分配空间，不能被exp导出**
        - 解决方法
            - 最简单的解决方案是使用expdp代替exp(expdp的参数和exp稍有不同，导入需要使用impdp)
            - 或者 `select 'alter table '||table_name||' allocate extent;' from user_tables where segment_created = 'NO';` 生成语句并执行(手动分配空间)
                - `select 'alter table '||table_name||' allocate extent;' from dba_tables where segment_created = 'NO' AND owner = 'SMALLE';`
    - dmp文件压缩与传输
        - dmp导出时使用了压缩模式，之后仍然可以打包成zip/tar压缩包，体积会小很多
        - dmp文件直接传输到服务器，可能会被拦截，可打成压缩包
        - dmp文件过大时(1G以上)，直接传输服务器中途容易断掉；**可通过FTP进行断点续传**
- **导出**

```bash
# 可将导出的dmp文件再tar压缩后通过scp传输到另外一台服务器上

# bash命令行设置字符集，防止乱码. 否则可能报错如`EXP-00091: Exporting questionable statistics`
select userenv('language') from dual; # 查看oracle服务端编码(导出导入的服务器应该保持一样的编码)
echo $NLS_LANG # 查看客户端编码
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
# export NLS_LANG=SIMPLIFIED CHINESE_CHINA.ZHS16GBK # ZHS16GBK字符集
# set NLS_LANG=AMERICAN_AMERICA.AL32UTF8 # windows

******防止漏表. 生成语句并执行(为空表手动分配空间，类似初始化，解决空表不导出问题，只需执行一次即可)；参考上文：导出时会漏表 ******
# select 'alter table '||table_name||' allocate extent;' from user_tables where segment_created = 'NO';
# select 'alter table '||table_name||' allocate extent;' from dba_tables where segment_created = 'NO' AND owner = 'USER1';

## **用户模式**：导出 scott 用户的所有对象(表、序列、函数、存储过程、索引等；包括各对应对应的表空间名，如果原对象不是用户默认的表空间，在导入时也是导入到其他表空间下)，前提是 system 用户有相关权限
    # system/"manager"@remote_orcl: 使用远程模式(remote_orcl 为在本地建立的远程数据库网络服务名，即 tnsnames.ora 里面的配置项名称。或者 system/"manager"@192.168.1.1:1521/orcl)。密码可以用双引号转义
    # rows=n: 不导出数据行，只导出结构
    # grants=y: A用户中有表 test，并且把这个表的查询权限给了用户B，那么当导出A用户的数据时候，GRANTS=Y就是把用户B对test表的查询权限导出；如果将这个数据导入到C用户时(GRANTS=Y)就是说导入到C用户的test表的查询权限也会被赋给用户B
    # compress=y: 压缩数据(默认y)。尽管使用压缩模式，但是导出的数据仍然可以进行zip压缩，体积只有原来的1/10；打成zip压缩包传输也安全，否则容易被防火墙拦截
    # buffer=10240000: 缓冲区(单位字节，只对常规路径有效)；或者如数据库60G，设置更大为 409600000
    # direct=y: 使用直接路径(默认是n传统路径)，可提供2-3倍的导出速度。限制：(1)不支持QUERY查询方式 (2)不支持表空间传输模式(即TRANSPORT_TABLESPACES=Y参数不被支持)，支持的是FULL,OWNER,TABLES导出方式 (3) 如果exp版本小于8.1.5，不能使用exp导入有lob字段的表，本案例为11.2
    # recordlength=65535: 最大为64K(direct=y才能使用)
    # tablespaces 如果用户有多个表空间，指定导出某个表空间的数据
exp demo/demo_pass@orcl file=/home/oracle/exp.dmp log=/home/oracle/exp.log owner=scott compress=y grants=y buffer=10240000
# exp demo/demo_pass@orcl file=/home/oracle/exp.dmp log=/home/oracle/exp.log owner=scott compress=y grants=y direct=y recordlength=65535 # 使用直接路径导出
# nohup exp demo/demo_pass@orcl file=/home/oracle/exp.dmp log=/home/oracle/exp.log owner=scott compress=y grants=y buffer=10240000 > /dev/null 2>&1 & # 后台执行导出
md5sum exp.dmp
tar -zcvf exp.tar.gz exp.*

## 表模式：导出 scott 的 emp,dept 表（导出其他用户表时，demo用户需要有相关权限）
# 常见错误(EXP-00011)：原因为 11g 默认创建一个表时不分配 segment，只有在插入数据时才会产生。 [^3]
exp demo/demo_pass file=/home/oracle/exp.dmp log=/home/oracle/exp.log tables=scott.emp,scott.dept compress=y grants=y
# exp scott/tiger file=/home/oracle/exp.dmp tables=emp
# 导出表部分数据
exp scott/tiger file=/home/oracle/exp.dmp tables=emp query=\" where ename like '%AR%'\"

## 全量模式：导出的是整个数据库，包括所有的表空间、用户/密码
exp demo/demo_pass file=/home/oracle/exp.dmp log=/home/oracle/exp.log full=y buffer=10240000
```
- **导入**

```bash
echo $NLS_LANG # 查看客户端编码
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
# set NLS_LANG=SIMPLIFIED CHINESE_CHINA.ZHS16GBK # ZHS16GB格式
# set NLS_LANG=AMERICAN_AMERICA.AL32UTF8 # windows
# tar -zxvf exp.tar.gz

## **用户模式**：一般需要先将用户对象全部删掉，如可删除用户对应的表空间重新创建。**[必须要先有对应的用户和表空间](#表空间)**
# SEQUENCE/SYNONYM 如果存在不会覆盖(索引重复导入时注意清理序列)，不存在会新增；FUNCTION/PRODUCE会覆盖
# 导入成功一般会提示`成功终止导入, 但出现警告。`，期间可以看到表空间文件大小一直在增长
# ignore=y：忽略错误，继续导入
# grants=y：包含权限
# indexes=n：不导入索引，之后可找到所有索引进行手动创建
# buffer=40960000 一秒至少应该是10w记录
# recordlength=65535: 最大为64K(如果是direct=y模式导出时可加上)
imp demo/demo_pass@orcl file=/home/oracle/exp.dmp log=/home/oracle/imp.log fromuser=scott touser=user2 tablespaces=ts2 ignore=y grants=y 
# 导入后查看对象数是否一致
# select OBJECT_TYPE,STATUS,count(1) from dba_objects where owner = 'OFBIZ' group by OBJECT_TYPE,STATUS order by 1 desc,2;

## 表模式：将 scott 的表 emp、dept 导入到用户 user2
# 此处 file/fromuser/touser 都可以指定多个
imp demo/demo_pass file=/home/oracle/exp.dmp log=/home/oracle/imp.log fromuser=scott tables=emp,dept touser=user2 tablespaces=ts2 ignore=y grants=y 

## 全量模式：导入的是整个数据库，包括所有的表空间(要求导出dmp也是全量的)
# 一般需要设置ignore=y，导入过程中会报一些错误需忽略，如导入系统相关数据时，由于目标数据库已经存在相关对象，从而报错
imp demo/demo_pass file=/home/oracle/exp.dmp log=/home/oracle/imp.log full=y ignore=y
```
- 常见错误
    - 导出报错`EXP-00008 ORA-01455`
        - 查看该用户下是否有物化视图日志，如果不需要可删除。参考：http://bbs.cqsztech.com/forum.php?mod=viewthread&tid=1678
            - `DROP MATERIALIZED VIEW LOG ON AEZOCN.TEST` 参考：https://www.modb.pro/db/224544
        - 也有说需要为空表手动分配段(测试无效)，参考：https://www.jianshu.com/p/08a338bfc3f6

##### expdp/impdp导出

- expdp/impdp成对使用 **(不支持增量导出)**。支持11.2/19c
- 使用参考：https://www.cnblogs.com/Jingkunliu/p/13705626.html
    - compression压缩说明(可不使用此参数，导出后再通过tar压缩)：https://blog.csdn.net/yifeng0504/article/details/77748719

```bash
## sql: 创建目录并赋权
sqlplus / as sysdba
create or replace directory dmp as '/tmp/dmp'; # 需提前创建好目录
grant read,write on directory dmp to demo_user;

## bash命令导出
# parallel为3个线程，最少产生3个dmp文件，无需压缩参数(建议手动压缩)
# filesize为单个文件不要超过5G，如果数据量较大则会以5G分割成多个文件
# schemas为(用户名)
# 导出测试案例：显示67G，导出只有28G，导出耗时47min，压缩后只有4.3G(压缩时间未计)
expdp demo_user/demo123@orcl directory=dmp parallel=3 filesize=5G dumpfile=expdp_aezo_20200101_%u.dmp logfile=expdp_aezo_20200101.log schemas=test_user1
tar -zcvf expdp_aezo_20200101.tar.gz expdp_aezo_20200101*

## bash命令导入
# 参考上文同样创建dmp目录，并将dmp文件放到改dmp目录下
# remap_schema为(原用户名:新用户名)，remap_tablespace为(原表空间名:新表空间名)
impdp demo_user/demo123@orcl parallel=3 cluster=no directory=dmp dumpfile=expdp_aezo_20200101_%u.dmp logfile=impdp_aezo_20200101.log remap_schema=test_user1:test_user2 remap_tablespace=tablespace01:tablespace02 
# 可选. 导入时查看导入情况
select * from dba_datapump_jobs; # 查询所有的任务
impdp \'\/ as sysdba\' attach=SYS_IMPORT_FULL_01 # attach到当前任务，如SYS_IMPORT_FULL_01
# 如果导入时一直卡主不动，查看的导入情况数据也没变，可查看trace下的alter日志
```

##### 增量备份参考

- Oracle数据库有三种标准的备份方法，它们分别是导出／导入（EXP/IMP、EXPDP/IMPDP）、热备份和冷备份。导出备件是一种逻辑备份，冷备份和热备份是物理备份
    - exp增量备份的最小单位是表，只要表一条数据发生变化，就会对全表进行备份
    - expdp/impdp不支持增量备份
    - RMAN备份为物理备份，需要保证导出和导入的数据库版本和相关配置一致
- 基于exp/imp的增量备份参考
    - https://www.cnblogs.com/gongyu/p/4276962.html
    - https://blog.csdn.net/zcb_data/article/details/80280892
- 基于RMAN增量备份
    - https://www.topunix.com/post-937.html

#### pl/sql方式

- pl/sql 提供 dmp、sql(SQL Inserts, 不支持 CLOB 类型字段)、pde(pl/sql 提供)格式的数据导入导出
    - dmp格式导入导出
        - 其中 Executable 路径为 `%ORACLE_HOME%/BIN/exp.exe` 和 `%ORACLE_HOME%/BIN/imp.exe` 如：`D:/java/oracle/product/11.2.0/dbhome_1/BIN/exp.exe`
    - sql格式导入导出
        - 导入时SQL*Plus Executable选择`%ORACLE_HOME%/BIN/sqlplus.exe`文件，或者勾选基于命令行导入
    - pde格式导入导出，**慎用**
        - 使用PL/SQL绿色版导出pde，直接会将被导出的表数据删掉
    - 当`View`按钮可点击时，即表示导出完成
- **导出导入对象结构**
    - `Tools - Export User Objects - 选择表/序列/存储过程等` 导出结构
- 导出导入表数据
    - `Tools - Export Tables - 选择表导出` 导出数据
    - `Tools - Import Tablse - 选择导入文件` 导入数据
- 命令窗口执行SQL文件(plsql 执行 sql 文件)
    - `start D:/sql/my.sql` 或 `@D:/sql/my.sql`（部分语句需要执行`commit`提交，文件不要放在C盘）

#### sql导出导入(sqlplus)

- 导出查询结果
    - 基于SPOLL
    - 对于CLOB等字段比较麻烦

```sql
-- 运行时去掉备注
set echo off; -- 不显示执行的SQL命令
set heading off; -- 去掉select结果的字段名，只显示数据
set feedback off; -- 关闭“已选择XX行”的提示
set termout off; -- 关闭屏幕上的SQL执行结果显示
set trimspool on; -- 去除重定向（Spool）输出时每行的拖尾空格
set pagesize 0; -- 输出每页行数，缺省为24，为了避免分页，可设定为0
spool /home/myout.csv -- 指定导出文件，导出开始
select name || ',' || text from user_source; -- 查询所有的存储过程(实际是把查询结果导出到文件, 此处逗号分割可用csv接收)
spool off; -- 导出结束

-- 如果要导出insert语句, select如: SELECT 'INSERT INTO table_name (column1, column2, ...) VALUES (' || column1 || ', ' || column2 || ', ...);' FROM table_name;
-- 待优化: 还需考虑数据类型, 如字符串需要加引号, 日志转换等
select 'select ''insert into T_TEST('
|| LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_id)
|| ') values('' || '
|| LISTAGG(column_name, ' || '','' || ') WITHIN GROUP (ORDER BY column_id)
|| ' || '');'' from T_TEST'
from dba_tab_columns where table_name = 'T_TEST';
```
- 导入：`@/home/imp.sql`，或者命令行运行`sqlplus root/root@127.0.0.1:1521/orcl @imp.sql`

#### Oracle表结构与Mysql表结构转换

- 参考 [mysql-dba.md:Oracle 表结构与 Mysql 表结构转换](/_posts/db/mysql-dba.md#其他)

### 数据库内存调整

```sql
-- 模拟操作系统内存从2G增加为8G, 一般设置shmmax不超过物理内存的75%(8*0.75*1024*1024*1024=6442450944)
-- MAX(SGA+PGA)<= memory_target, 且 sga_max_size 不能超过 shmmax

-- 查看内存和sga. mem=sga+pga
sqlplus / as sysdba
show parameter sga;
show parameter pga;
show parameter mem;
-- 查看系统shm设置
cat /etc/sysctl.conf | grep shmmax
-- 内存对应到tmpfs, /dev/shm
df -ThP

-- 停止数据库，关机后增加物理内存

-- 此处将kernel.shmmax设置为物理内存的75% (也有直接设置成物理内存的)
-- 将memory_target设置为物理内存的70%
-- 将sga_max_size设置为memory_target的75%
echo "kernel.shmmax = 6442450944" >> /etc/sysctl.conf
sysctl -p
-- 需要设置大小: tmpfs /dev/shm tmpfs  defaults,size=6G      0 0
cat /etc/fstab
mount -o remount tmpfs
-- /dev/shm 增加了则说明是对的
df -ThP

-- 修改数据库配置 (memory不能大于kernel.shmmax)；注意不能只改max，且sga_max_size要比memory_target小(不要设置成等于)
alter system set memory_max_target=5734M scope=spfile;
alter system set memory_target=5734M scope=spfile;
alter system set sga_max_size=4300M scope=spfile;
alter system set sga_target=4300M scope=spfile;
-- 重启
shutdown immediate
startup
-- 登录后重新查询数据库相关内存
show parameter sga
```
- 遇到的问题

```sql
-- 实践中遇到一下问题
-- 由于在设置sga的时候只设置了memory_max_target和sga_max_size，且设置的相等；然后重启数据库的时候后失败，报错
ORA-00844: Parameter not taking MEMORY_TARGET into account
ORA-00851: SGA_MAX_SIZE 20669530112 cannot be set to more than MEMORY_TARGET 13958643712.

-- 此时由于spfile已经发生了修改(且存在错误)，如果直接 startup 启动，默认会读取 spfile 配置进行启动数据库，从而会启动失败(pfile和spfile参考上文Oracle相关名词和原理)
-- 因此尝试通过pfile启动，可指定系统默认的pfile，或者使用安装数据库时产生的pfile(此处使用)
startup pfile='/u01/app/oracle/admin/orcl/pfile/init.ora.2172017164927'
-- 执行后，仍然报错
ORA-01092: ORACLE instance terminated. Disconnection forced
ORA-30012: undo tablespace 'UNDOTBS1' does not exist or of wrong type

-- 报错说undo表空间(用于数据回滚的系统表空间)存在问题，导致系统无法启动
-- 遂百度此错误解决方法。网上大部分说法需要通过`startup mount`先只挂载数据库，然后通过重新创建undo表空间等方式来解决
-- 此时由于我spfile文件配置错误，如果直接`startup mount`仍然会报ORA-00851的错误，此处可以指定pfile挂载
startup mount pfile='/u01/app/oracle/admin/orcl/pfile/init.ora.2172017164927'
-- 执行后，仍然报错
Receiving Error 'ORA-01041: internal error. hostdef extension doesn't exist. on re-establishing

-- Fuck. 
-- 继续百度. 找到如下文章: https://support.quest.com/zh-cn/erwin-data-modeler/kb/4284269/receiving-error-ora-01041-internal-error-hostdef-extension-doesn-t-exist-on-re-establishing
-- 表示可以临时设置sqlnet.ora文件增加如下配置(这个文件默认是空的，此时相当于设置成空，即不进行校验)，文件目录: /u01/app/oracle/product/11.2.0/network/admin/sqlnet.ora
SQLNET.AUTHENTICATION_SERVICES=

-- 然后重复. 发现竟然挂载成功了
startup mount pfile='/u01/app/oracle/admin/orcl/pfile/init.ora.2172017164927'
-- 进去之后我执行了一下，结果发现确实没有 UNDOTBS1 这个表空间，而是存在一个 UNDOTBS2 的表空间(原来是因为之前由于UNDOTBS1过大，做过清理，参考上文清理存储空间)
select * from v$tablespace;
-- 此时修改init.ora.2172017164927中的配置为
undo_tablespace=UNDOTBS2

-- 然后重新启动. 发现竟然又成功了
startup pfile='/u01/app/oracle/admin/orcl/pfile/init.ora.2172017164927'

-- 然后重启监听，发现报错：TNS-12560 TNS-00583
-- 百度发现可能是由于listener.ora tnsnames.ora sqlnet.ora三个文件或其中的一个文件内容配置错误导致的. 恍然大悟
-- 恢复 sqlnet.ora 原来的配置
-- 再次重启监听. 成功!
lsnrctl start

-- 此方式为临时指定pfile启动，还需将sga等参数设置正确，并修复spfile，并已spfile方式启动
-- 参考: https://blog.csdn.net/z924139546/article/details/87888643
startup pfile='/u01/app/oracle/admin/orcl/pfile/init.ora.2172017164927'
-- 备份原来的pfile和spfile
cp /u01/app/oracle/product/11.2.0/dbs/initorcl.ora /u01/app/oracle/product/11.2.0/dbs/initorcl.ora.bak
cp /u01/app/oracle/product/11.2.0/dbs/spfileorcl.ora /u01/app/oracle/product/11.2.0/dbs/spfileorcl.ora.bak
-- 重新创建pfile，此时会重新生成initorcl.ora
create pfile from spfile;
-- 修改pfile
vi initorcl.ora
/*
orcl.__sga_target=4508876800
*.memory_target=6012534784
*.memory_max_target=6012534784
*.sga_max_size=4508876800
*/
-- 重新创建spfile
create spfile from pfile;
shutdown immediate;
startup
-- 启动仍然报错
ORA-00214: control file '/u01/app/oracle/oradata/orcl/control01.ctl' version
2147285 inconsistent with file '/home/oracle/data/control03.ctl' version
2147135

-- ...
-- 参考，无尝试: https://logic.edchen.org/how-to-resolve-ora-00214-control-file/
```

### 创建数据库实例

- 一般新建数据库实例名为orcl，此时需要再创建一个实例orcl2(这样可以创建和orcl一样的表空间)
    - windows参考：https://blog.csdn.net/qq_43222869/article/details/107067357
    - `Database Configuration Assistant` - 创建数据库 - 设置数据库名称和SID(两者最好保持一致，并且一定要记住) - 其他步骤保持不变。如果需要使用sqlplus登录，还需配置
    - `lsnrctl status` 可查看到listener.ora监听配置文件位置，需将新实例配置到SID_LIST_LISTENER中

        ```bash
        SID_LIST_LISTENER =
            (SID_LIST =
                (SID_DESC =
                    (SID_NAME = orcl)
                    (ORACLE_HOME = G:\app\Administrator\product\11.2.0\dbhome_1)
                    (ENVS = "EXTPROC_DLLS=ONLY:G:\app\Administrator\product\11.2.0\dbhome_1\bin\oraclr11.dll")
                )
                (SID_DESC =
                    (SID_NAME = orcl2)
                    (ORACLE_HOME = G:\app\Administrator\product\11.2.0\dbhome_1)
                    (ENVS = "EXTPROC_DLLS=ONLY:G:\app\Administrator\product\11.2.0\dbhome_1\bin\oraclr11.dll")
                )
            )
        ```
    - 由于sqlplus指定实例时使用的是listener.ora同级目录下的tnsnames.ora文件，需要将orcl2的配置加上才能使用
    - 创建完之后，原来的数据库实例会正常运行。新实例会在服务中创建OracleServiceORCL2(TNS Listener是共用的，不会创建新的)
    - 指定实例登录`sqlplus system/root@orcl2 as sysdba`

### 记录数据变动日志

- 基于数据库触发器+sys_context实现用户信息通过数据库会话传递
    - client_identifier使用: https://juejin.cn/post/7126934623023530015
    - V$SESSION的CLIENT_INFO列和CLIENT_IDENTIFIER列往往为空，所以需要写登录触发器，然后在触发器中使用如下的存储过程记录这2列的值
    - sys_context使用: https://blog.csdn.net/db_murphy/article/details/115186884
    - DBMS_SESSION包详解: https://www.cnblogs.com/shujk/p/13983202.html
    - 核心代码
        - 还有一思路是通过AOP监听getConnection()方法的执行，进行注入参数(测试了下AOP进不去)

        ```java
        @Bean
        public DataSource dataSource(DataSourceProperties properties) {
            return new IdentifierDataSource(properties.initializeDataSourceBuilder().build());
        }

        public static String SET_IDENTIFIER_SQL = "{ call DBMS_SESSION.SET_IDENTIFIER(?) }";

        public static class IdentifierDataSource extends DelegatingDataSource {
            public IdentifierDataSource(DataSource delegate) {
                super(delegate);
            }

            @Override
            public Connection getConnection() throws SQLException {
                Connection connection = super.getConnection();
                try {
                    CallableStatement cs = connection.prepareCall(SET_IDENTIFIER_SQL);
                    cs.setString(1, ShiroUtils.getOperNam() == null ? "" : ShiroUtils.getOperNam());
                    cs.execute();
                    cs.close();
                } catch (Exception e) {
                    log.error("设置用户会话信息出错", e);
                }
                return connection;
            }
        }
        ```
        - 触发器

        ```sql
        CREATE OR REPLACE TRIGGER tub_ship_log
            BEFORE UPDATE OF ETA_TIM,REMARK_TXT
            ON ship
            FOR EACH ROW
            DECLARE
            up_str           VARCHAR2(1000);
        begin
            -- 获取应用登录用户信息
            select sys_context('userenv','client_identifier') from dual;
        END;
        ```
- SpringBoot+Mybatis-Plus+ThreadLocal利用AOP+mybatis插件实现数据操作记录及更新对比: https://www.cnblogs.com/top-sky-hua/p/13321754.html

### 密码策略修改

```sql
-- 查询user是否锁定、及时间
SELECT USERNAME,ACCOUNT_STATUS,LOCK_DATE,CREATED,PROFILE FROM DBA_USERS WHERE USERNAME = 'TEST_USER';
-- 修改密码（oracle可以修改为原密码）
alter user TEST_USER account unlock identified by "Hello1234!";

-- 查询用户默认profile
select profile from dba_users where username = 'TEST_USER';
-- 修改用户默认profile
alter user TEST_USER profile default;

-- (sqlplus)查看用户密码策略profile
-- 也可以直接 select * from dba_profiles where profile='DEFAULT' and resource_type='PASSWORD';
set linesize 350            -- 设置整行长度，linesize 说明 https://blog.csdn.net/u012127798/article/details/34146143
col profile for a20         -- 设置profile这个字段的列宽为20个字符
col resource_name for a25
col resource for a15
col limit for a20
select * from dba_profiles where profile='DEFAULT' and resource_type='PASSWORD';
-- FAILED_LOGIN_ATTEMPTS 密码出错次数（超过次数后账号将锁定）
-- PASSWORD_LIFE_TIME 密码有效期
-- PASSWORD_REUSE_TIME 密码不能重新用的天数
-- PASSWORD_REUSE_MAX 密码重用之前修改的最少次数
-- PASSWORD_VERIFY_FUNCTION 密码复杂度校验函数(一般要自己定义)
-- PASSWORD_LOCK_TIME 默认超过了1天后，帐号自动解锁
-- PASSWORD_GRACE_TIME 默认密码到期提前7天提醒

-- 密码出错次数（超过次数后账号将锁定）
alter profile default limit FAILED_LOGIN_ATTEMPTS 5;
alter profile default limit FAILED_LOGIN_ATTEMPTS UNLIMITED;

-- 密码有效期
alter profile default limit PASSWORD_LIFE_TIME 180; -- 密码有效期(天）
alter profile default limit PASSWORD_LIFE_TIME UNLIMITED; -- 密码有效期不限制

-- sqlplus执行密码策略语句(里面有一个默认的密码策略，参考：https://blog.csdn.net/xqf222/article/details/50263181)
-- 会创建一个默认的密码策略验证函数 VERIFY_FUNCTION_11G，并修改默认的密码profile
@ $ORACLE_HOME/rdbms/admin/utlpwdmg.sql

-- 修改资源限制状态(默认未开启)。用户所有拥有的PROFILE中有关资源的限制与resource_limit参数的设置有关，当为TRUE时生效；当为FALSE时（默认值）设置任何值都无效
-- Oracle 11g启动参数resource_limit无论设置为false还是true，上述策略都是生效的
show parameter resource_limit;
alter system set resource_limit=true; -- 开启resource_limit=true
```

### 审计

```sql
-- 查看有效账号(account_status='OPEN')和账号(NAME)最近密码修改日期(PTIME)
select USER#, NAME, PTIME from user$ where NAME in (select username from dba_users t where t.account_status = 'OPEN');
```

## 日常维护

- 检查`listener.log`是否过大
    - 可能产生异常场景：实例 tnsping 突然高达 1w 多毫秒，发现listener.log达到4G
    - 解决：日志文件过大，可重新创建一个此日志文件（或者直接删掉，重启TNS会自动创建此文件）
    - listener.log目录如`g:\app\administrator\diag\tnslsnr\主机名\listener\trace\listener.log`
        - 查看文件位置`show parameter dump;`得到如`user_dump_dest => g:\app\administrator\diag\rdbms\orcl\orcl\trace`
        - 从而得知日志目录为：`g:\app\administrator\diag`
        - 然后在此目录查找`tnslsnr/主机名/listener/trace/listener.log`文件

## Oracle安装

- 数据库安装包：[oracle](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
- oracle 静默安装, 关闭客户端后再次以 oracle 用户登录无法运行 sql 命名, 需要执行`source ~/.bash_profile`
- oracle目录
    - Oracle基目录为`D:/java/oracle`，基目录只是把不同版本的oracle放在一起
    - ORACLE_HOME 为`D:/java/oracle/product/11.2.0/dbhome_1`，`%ORACLE_HOME%/bin`中为一些可执行程序（如：导入 imp.exe、导出 exp.exe）
- listener.ora 案例
    - 直接修改如 C:\software\oracle\product\11.2.0\dbhome_1\network\admin\listener.ora 或者通过Windows的Net Manager进行可视化修改, 修改后重启监听

```bash
# listener.ora Network Configuration File: C:\software\oracle\product\11.2.0\dbhome_1\network\admin\listener.ora
# Generated by Oracle configuration tools.

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = orcl)
      (ORACLE_HOME = C:\software\oracle\product\11.2.0\dbhome_1)
      (ENVS = "EXTPROC_DLLS=ONLY:C:\software\oracle\product\11.2.0\dbhome_1\bin\oraclr11.dll")
    )
  )
  
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = iZkfy11io8che2Z)(PORT = 1521))
    )
  )

ADR_BASE_LISTENER = C:\software\oracle

# 防止 listener.log 日志文件到达4G
LOG_FILE_SIZE_LISTENER = 10485760  # 单个日志文件大小限制（单位：字节，这里设为10MB）
LOG_ARCHIVE_START_LISTENER = ON  # 启用自动归档（分割）
LOG_ARCHIVE_MAX_LISTENER = 100  # 保留的归档文件数量（超过则覆盖旧文件）
```
- tnsnames.ora 配置参考下文

## PL/SQL安装和使用

- **PL/SQL绿色版安装**
    - 直接解压，修改Oracle64/tnsnames.ora文件，然后点击qidong.bat即可（如果是本地数据库则直接启动exe文件）。无需配置任何环境变量或oci.dll路径
    - 修改配置项
        - 配置 - User Interface - Fonts - Browser/Grid/Main Font(Segoe UI,常规,小五); Editor(Courier New,常规,10)
        - 配置 - User Interface - Appearance - Language(选择英文), Switch to Menu(菜单以下拉菜单方式显示)

### PL/SQL完整版安装

- Oracle 需要装 client 才能让第三方工具(如 pl/sql)通过 OCI(Oracle Call Interface)来连接，安装包可以去 oracle 官网下载 Instant Client
- 安装`pl/sql developer`
- 将`instantclient_10_2`(oracle 的客户端)，复制到 oracle 安装目录(D:\java\oracle\product，其他目录也可以)
- 配置`pl/sql developer`首选项中连接项。设置 oracle_home 为 instantclient_10_2 的路径，oci 为 instantclient_10_2 下的 oci.dll
- 环境变量配置(必须)
    - ORACLE_HOME
        - 安装 oracle 则需要配置 oracle 目录(`ORACLE_HOME=D:\java\oracle\product\11.2.0\dbhome_1`)
        - 不安装 oracle 也可使用 pl/sql. 需要配置环境变量指向客户端目录(`ORACLE_HOME=D:\java\oracle\product\instantclient_10_2`)
    - `TNS_ADMIN=D:\java\oracle\product\instantclient_10_2`(`tnsnames.ora`的上级目录)，并在 path 末尾加入`%TNS_ADMIN%;`(否则容易报`TNS-12541`)
- 其他配置(可忽略)
    - 环境变量设置`NLS_LANG=AMERICAN_AMERICA.AL32UTF8`、`nls_timestamp_format=yyyy/mm/dd hh24:mi:ssxff`(PLSQL 查询中可直接使用时间字符串，代码中最好通过 to_date 转换)

#### 相关错误

- instantclient_10_2 匹配 11.2.0 的 oracle 可能会报错（如 OCI: not initialized、请确认安装了 32 位 oracle client）
  - 可到[Instant Client Downloads for Microsoft Windows (32-bit)](http://www.oracle.com/technetwork/topics/winsoft-085727.html)下载对应 pl/sql 的版本(instantclient-basic-nt-11.2.0.4.0.zip)，压缩包中没有`tnsnames.ora`和`listener.ora`可到`$ORACLE_HOME/NETWORK/ADMIN`中复制（64 位机器可安装 32 位 pl/sql，此时 Instant Client 也应该是 32 位）

### 网络配置

- Net Manager 的使用(`$ORACLE_HOME/BIN/launch.exe`)
  - 打开网络配置文件时，则打开`$ORACLE_HOME/NETWORK/ADMIN`目录
  - `本地-监听程序-LISTENER`中的主机要为计算机全名(如：ST-008)，对应文件 **`$ORACLE_HOME/NETWORK/ADMIN/listener.ora`**
    - 使用 pl/sql 也需要配置，且第一个 ADDRESS 需要类似配置为`TCP/IP，ST-008，1521`
  - `本地-服务命名`下的都为`网络服务名`，对应文件`tnsnames.ora`
  - 有的需参考 https://blog.csdn.net/pengpengpeng85/article/details/78757484 创建监听程序配置和本地网络服务名配置
- 文本操作
  - 使用 sqlplus 登录时，可直接修改`$ORACLE_HOME/NETWORK/ADMIN/tnsnames.ora`
  - 安装了 pl/sql，可能需要修改 tnsnames.ora 的文件路径类似与`D:\java\oracle\product\instantclient_10_2\tnsnames.ora`。此时 oracle 自带的 tnsnames.ora 将会失效
  - 配置实例：HOST/PORT 分别为远程 ip 地址(或127.0.0.1)和端口，SERVICE_NAME 为远程服务名，aezocn 为远程服务名别名(本地服务名)

    ```bash
    aezocn = 
        (DESCRIPTION = 
            (ADDRESS_LIST =
                (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.1.1)(PORT = 1521))
            )
            (CONNECT_DATA = 
                (SERVER = DEDICATED)
                (SERVICE_NAME = orcl)
            )
        )
    ```
- 如果 oracle 服务在远程机器上，本地通过 plsql 连接，则不需要在本地启动任何和 oracle 相关的服务。如果本地机器作为 oracle 服务器，则需要启动 OracleServiceORCL，此时只能在命令行连接数据库，如果需要通过 plsql 连接则需要启动类似"OracleOraDb11g_home1TNSListener"的 TNS 远程监听服务

## ODAC/ODBC/JDBC

- ODAC全称：oracle Date Access Components，为oracle数据访问组件，[32位的安装包](http://pan.baidu.com/s/1ntZf92p)在32位，64位的都可以采用的
    - 执行安装程序 - 下一步 - Oracle Client 11.2.0.3 - Oracle基目录=D:\java\oracle，软件位置名称=OraClient11g_home2，路径=D:\java\oracle\product\11.2.0\dbhome_2 - 下一步 - 安装
	- 如果提示“服务OracleMTSRecoveryService已经存在” - 忽略
    - 或者下载ODAC112030Xcopy_64bit.zip等压缩包进行安装，推荐
- ODBC：Windows上通过配置不同数据库（SQL Server、Oracle等）的驱动进行访问数据库。找到控制面板-管理工具-数据源ODBC
- JDBC连接
    - 支持负载均衡模式

    ```bash
    jdbc:oracle:thin:@(DESCRIPTION = 
        (failover = on)
        (LOAD_BALANCE = off) 
        (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.1.100)(PORT = 1521)) 
            (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.1.100)(PORT = 1521))
        )
        (CONNECT_DATA =
            (SERVER = DEDICATED)
            (SERVICE_NAME = ORCL)
            (failover_mode = (type = select) (method = basic))
        )
    )
    ```

## Oracle-19c

### 常见问题

- 启动项目报错`Caused by: java.nio.file.InvalidPathException: Illegal char <:> at index 59: D:\software\oracle\product\11.2.0\dbhome_1\NETWORK\ADMI;C:\Program Files\Java\jdk1.8.0_31\ojdbc.properties`
    - 背景：项目使用oracle 19c，引入ojdbc8，服务器部署了oracle 11g服务，之前使用ojdbc6的项目能正常启动，使用ojdbc8则报错
    - 解决：在项目启动脚本前增加`set TNS_ADMIN=`去掉服务器原来的TNS_ADMIN环境变量
    - 原因：ojdbc8中会优先取读取`oracle.net.tns_admin`属性（对应的是TNS_ADMIN环境变量）
- 执行SQL时, Oracle内部会自动增加列`__Oracle_JDBC_internal_ROWID__`导致报错
    - 可修改 ResultSet.TYPE_SCROLL_SENSITIVE 为 ResultSet.TYPE_SCROLL_INSENSITIVE
    - (可能还需)修改 ResultSet.CONCUR_UPDATABLE 为 ResultSet.CONCUR_READ_ONLY ?
    - 或者使用 TYPE_FORWARD_ONLY ?, 或者升级JDBC 驱动 ?




---

图片说明

- lsnrctl-status 显示图片
    - 服务正常如下图有`Service "orcl" has 1 instance(s).`
    - 服务异常如`The listener supports no services`表示无服务启动
    
    ![lsnrctl-status](/data/images/db/lsnrctl-status.png)

---

参考文章

[^1]: http://www.cnblogs.com/advocate/archive/2010/08/20/1804063.html
[^2]: http://blog.csdn.net/starnight_cbj/article/details/6792364
[^3]: http://www.cnblogs.com/yzy-lengzhu/archive/2013/03/11/2953500.html
[^4]: http://blog.csdn.net/studyvcmfc/article/details/5679235
[^5]: http://blog.csdn.net/yitian20000/article/details/6256716
[^6]: http://blog.chinaunix.net/uid-11570547-id-59108.html (强制删除表空间)
[^7]: http://blog.sina.com.cn/s/blog_9d4799c701017pw1.html (表空间不足解决办法)
[^8]: https://www.cnblogs.com/langtianya/p/6567881.html (ORA-01654 索引无法通过表空间扩展)
[^9]: http://www.zhengdazhi.com/archives/1344 (sqlplus 导出 oracle 查询结果)
[^10]: https://blog.csdn.net/huoyin/article/details/40679877 (tnsping 延时过高解决办法)
[^11]: https://blog.csdn.net/robinjwong/article/details/42104831
