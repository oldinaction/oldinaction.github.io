---
layout: "post"
title: "Oracle DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [oracle, dba]
---

## 简介

> 注：本文中 aezo/aezo 一般指用户名/密码，local_orcl指配置的本地数据库服务名，remote_orcl指配置的远程数据库服务名。以11g为例

### oracle相关名词和原理

1. 数据库名(DB_NAME)、实例名(INSTANCE_NAME)、以及操作系统环境变量(ORACLE_SID) [^1]
    - `DB_NAME`: 在每一个运行的oracle数据库中都有一个数据库名(如: orcl)，如果一个服务器程序中创建了两个数据库，则有两个数据库名。
    - `INSTANCE_NAME`: 数据库实例名则用于和操作系统之间的联系，用于对外部连接时使用。在操作系统中要取得与数据库之间的交互，必须使用数据库实例名(如: orcl)。与数据库名不同，在数据安装或创建数据库之后，实例名可以被修改。例如，要和某一个数据库server连接，就必须知道其数据库实例名，只知道数据库名是没有用的。用户和实例相连接。
    - `ORACLE_SID`: 有时候简称为SID。在实际中，对于数据库实例名的描述有时使用实例名(instance_name)参数，有时使用ORACLE_SID参数。这两个都是数据库实例名。instance_name参数是ORACLE数据库的参数，此参数可以在参数文件中查询到，而ORACLE_SID参数则是操作系统环境变量，用于和操作系统交互，也就是说在操作系统中要想得到实例名就必须使用ORACLE_SID。此参数与ORACLE_BASE、`ORACLE_HOME`等用法相同。在数据库安装之后，ORACLE_SID被用于定义数据库参数文件的名称。如：$ORACLE_BASE/admin/DB_NAME/pfile/init$ORACLE_SID.ora。
2. `SERVICE_NAME`：是网络服务名(如：local_orcl)，可以随意设置。相当于某个数据库实例的别名方便记忆和访问。`tnsnames.ora`文件中设置的名称（如：`local_orcl=(...)`），也是登录pl/sql是填写的Database。

## oracle及pl/sql安装和使用

- ORACLE_HOME为`D:/java/oracle/product/11.2.0/dbhome_1`，`%ORACLE_HOME%/bin`中为一些可执行程序（如：导入imp.exe、导出exp.exe）
- 这个只是服务器端才会使用的到

### pl/sql安装

Oracle需要装client才能让第三方工具(如pl/sql)通过OCI(Oracle Call Interface)来连接，安装包可以去oracle官网下载Instant Client。
- 将`instantclient_10_2`(oracle的客户端)，复制到oracle安装目录
- 安装`pl/sql developer`
- 配置`pl/sql developer`首选项中连接项。设置oracle_home为instantclient_10_2的路径，oci为instantclient_10_2下的oci.dll
- 环境变量中设置`TNS_ADMIN=D:\java\oracle\product\instantclient_10_2`，并在path末尾加入`%TNS_ADMIN%;`(否则容易报`TNS-12541`)

#### 相关错误

- instantclient_10_2匹配11.2.0的oracle可能会报错（如OCI: not initialized、请确认安装了32位oracle client）
    - 可到[Instant Client Downloads for Microsoft Windows (32-bit)](http://www.oracle.com/technetwork/topics/winsoft-085727.html)下载对应pl/sql的版本(instantclient-basic-nt-11.2.0.4.0.zip)，压缩包中没有`tnsnames.ora`和`listener.ora`可到`$ORACLE_HOME/NETWORK/ADMIN`中复制（64位机器可安装32位pl/sql，此时Instant Client也应该是32位）

### 网络配置

1. Net Manager的使用
    - `本地-监听程序-LISTENER`中的主机要为计算机全名(如：ST-008)，对应文件`listener.ora`
        - 使用pl/sql也需要配置，且第一个地址需要类似配置为`TCP/IP，ST-008，1521`
    - `本地-服务命名`下的都为`网络服务名`。对应文件`tnsnames.ora`
3. 文本操作
    - 使用sqlplus登录时，可直接修改`$ORACLE_HOME/NETWORK/ADMIN/tnsnames.ora`
    - 安装了pl/sql，可能需要修改tnsnames.ora的文件路径类似与`D:\java\oracle\product\instantclient_10_2\tnsnames.ora`。此时oracle自带的tnsnames.ora将会失效
    - 配置实例：HOST/PORT分别为远程ip地址和端口，SERVICE_NAME为远程服务名，aezocn为远程服务名别名(本地服务名)

        ```html
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
3. 如果oracle服务在远程机器上，本地通过plsql连接，则不需要在本地启动任何和oracle相关的服务。如果本地机器作为oracle服务器，则需要启动OracleServiceORCL，此时只能在命令行连接数据库，如果需要通过plsql连接则需要启动类似"OracleOraDb11g_home1TNSListener"的TNS远程监听服务。

## 创建表空间 [^2]

oracle和mysql不同，此处的创建表空间相当于mysql的创建数据库。创建了表空间并没有创建数据库实例

1. 登录：`sqlplus / as sysdba`
2. 创建表空间：`create tablespace aezocn datafile 'd:/tablespace/aezo' size 800m extent management local segment space management auto;` ，要先建好路径 d:/tablespace ，最终会在该目录下建一个 AEZO 的文件(表空间之后可以修改)
    - 删除表空间：`drop tablespace aezocn including contents and datafiles;`
3. 创建用户：`create user aezo identified by aezo default tablespace aezocn;`
4. 授权
    - `grant create session to aezo;`
    - `grant unlimited tablespace to aezo;`
    - `grant dba to aezo;`

## 导入导出

`.dmp`适合大数据导出，`.sql`适合小数据导出(表中含有CLOB类型字段则不能导出)

### 命令行 [^4]

> - 输入 `imp/exp 用户名/密码` 可根据提示导入导出。**直接cmd运行**。
> - 成功提示 `Export terminated successfully [with/without warnings]`；失败提示 `Export terminated unsuccessfully [with/without warnings]`

1. 导出
    - **用户模式**：`exp system/manager file=d:/exp.dmp owner=scott` 导出scott用户的所有对象，前提是system有相关权限
        - **远程导出**：此时system/manager默认连接的是本地数据库。如果使用`exp system/manager@remote_orcl file=d:/exp.dmp owner=scott`(remote_orcl为在本地建立的远程数据库网络服务名)则可导出远程数据库的相关数据，下同。
        - 加上 `compress=y` 表示压缩数据
        - 加上 `rows=n` 表示不导出数据行，只导出结构
    - 表模式：`exp scott/tiger file=d:/exp.dmp tables=emp` 导出scott的emp表
        - 导出其他用户的表：`exp system/manager file=d:/exp.dmp tables=scott.emp, scott.dept` 导出scott的emp、dept表，用户system需要相关权限
        - 导出部分表数据：`exp scott/tiger file=d:/exp.dmp tables=emp query=\" where ename like '%AR%'\"`
        - 常见错误(EXP-00011)：原因为11g默认创建一个表时不分配segment，只有在插入数据时才会产生。 [^3]
    - 导出全部：`exp system/manager file=d:/exp.dmp full=y`
        - 用户 system/manager 必须具有相关权限
        - 导出的是整个数据库，包括所有的表空间

2. 导入
    - **用户模式**：`imp system/manager file=d:/exp.dmp fromuser=scott touser=aezo ignore=y`
        - `ignore=y`忽略创建错误
        - 不少情况下要先将表彻底删除，然后导入
    - 表模式：`imp system/manager file=d:/exp.dmp fromuser=scott tables=emp, dept touser=aezo ignore=y`
        - 将scott的表emp、dept导入到用户aezo
        - 此处 file/fromuser/touser 都可以指定多个
    - 导入全部：`imp system/manager file=d:/exp.dmp full=y ignore=y`
        - 用户 system/manager 必须具有相关权限
        - 导入的是整个数据库，包括所有的表空间

### pl/sql

- pl/sql提供dmp、sql(不支持CLOB类型字段)、pde(pl/sql提供)格式的数据导入导出
- 方法：`Tools - Export Tables/Import Tablse - 选择表导出`
- 其中Executable路径为 `%ORACLE_HOME%/BIN/exp.exe` 和 `%ORACLE_HOME%/BIN/imp.exe` 如：`D:/java/oracle/product/11.2.0/dbhome_1/BIN/exp.exe`

### Oracle表结构与Mysql表结构转换

参考 [mysql-dba.md#Oracle表结构与Mysql表结构转换](/_posts/db/mysql-dba.md#Oracle表结构与Mysql表结构转换)

## 常用操作

### 系统相关

#### 启动/停止

- `lsnrctl start` 启动监听程序(shell命令行运行)。
    - `lsnrctl status` 查看服务状态（见下图"lsnrctl-status显示图片"）
- `sqlplus /nolog`、`sqlplus / as sysdba` 以nolog、sysdba身份登录，进入sql命令行
- **`shutdown immediate`** 大多数情况下使用。迫使每个用户执行完当前SQL语句后断开连接 (sql下运行，无需分号)
    - `shutdown;` 有用户连接就不关闭，直到所有用户断开连接
- **`startup;`** 正常启动（1启动实例，2打开控制文件，3打开数据文件）(sql下运行) 
- `exit;` 退出sqlplus

#### 管理员登录

- sqlplus本地登录：`sqlplus / as sysdba`，以sys登录。sys为系统管理员，拥有最高权限；system为本地管理员，次高权限
- sqlplus远程登录：`sqlplus aezo/aezo@192.168.1.1:1521/orcl` (orcl为远程服务名)，失败可尝试如下命令：
    - `sqlplus /nolog`
    - `connect aezo/aezo@192.168.1.1:1521/orcl;`，或者使用配置好的服务名连接`conn aezo/aezo@remote_orcl`
- pl/slq管理员登录：用户名密码留空，Connect as 选择 SYSDBA 则默认以sys登录。登录远程只需要在tnsnames.ora进行网络配置即可

### 数据库相关

#### 连接数

- 查询数据库最大连接数：`select value from v$parameter where name = 'processes'`、`show parameter processes`
- 查询数据库当前连接数：`select count(*) from v$session;`
- 修改数据库最大连接数：`alter system set processes = 500 scope = spfile;` 需要重启数据库

#### 表空间

- 表空间不足/扩容参考下文常见错误

#### 锁表

```sql
-- 查询被锁表的信息（多刷新几次，应用可能会临时锁表）
select s.sid, s.serial#, l.*, o.*, s.* FROM gv$locked_object l, dba_objects o, gv$session s 
    where l.object_id　= o.object_id and l.session_id = s.sid; 
-- 关闭锁表的连接
alter system kill session '某个sid, 某个serial#';
```

#### 索引

- 分析并重建索引

```sql
-- 1.分析索引
analyze index SERVER_HIT_TXSTMP validate structure;
-- 2.查看索引分析结果
select height,DEL_LF_ROWS/LF_ROWS from index_stats;
-- 3.查询出来的 height>=4 或者 DEL_LF_ROWS/LF_ROWS>0.2 的场合, 该索引考虑重建
alter index SERVER_HIT_TXSTMP rebuild online;
```

### 用户相关

- 创建用户：`create user aezo identified by aezo;`
    - 默认使用的表空间是`USERS`，使用`create user aezo identified by aezo default tablespace aezocn;`可设定默认表空间
    - 删除用户：`drop user aezo cascade;`
- 修改用户密码：`alter user scott identified by tiger;`
- 修改用户表空间：`alter user aezo default tablespace aezocn;`
- 解锁用户：`alter user scott account unlock;` (新建数据库scott默认未解锁)
- 密码过期：(1) 重新设置密码即可`alter user aezo identified by aezo;` (2)设置永久不过期`alter profile default limit password_life_time unlimited;`
- 授权
    - `grant create session to aezo;` 授予aezo用户创建session的权限，即登陆权限
    - `grant unlimited tablespace to aezo;` 授予aezo用户使用表空间的权限
    - `grant dba to aezo;` 授予管理权限(有dba角色就有建表等权限)

### 查询相关

- 系统
    - 查看服务是否启动：`tnsping local_orcl` cmd直接运行
        - 远程查看(cmd运行)：`tnsping 192.168.1.1:1521/orcl`、或者`tnsping remote_orcl`(其中remote_orcl已经在本地建立好了监听映射，如配置在tnsnames.ora)
        - 如果能够ping通，则说明客户端能解析listener的机器名，而且lister也已经启动，但是并不能说明数据库已经打开，而且tsnping的过程与真正客户端连接的过程也不一致。但是如果不能用tnsping通，则肯定连接不到数据库
    - 查看表空间数据文件位置：`select file_name, tablespace_name from dba_data_files;`
- 用户相关查询
    - 查看当前用户默认表空间：`select username, default_tablespace from user_users;`(以dba登录则结果为SYS和SYSTEM)
    - 查看当前用户角色：`select * from user_role_privs;`
    - 查看当前用户系统权限：`select * from user_sys_privs;`
    - 查看当前用户表级权限：`select * from user_tab_privs;`
    - 查看用户下所有表：`select * from user_tables;`
    - DBA相关查询见数据库字典
- 数据字典 [^5]
    - `user_`：记录用户对象的信息，如user_tables包含用户创建的所有表，user_views，user_constraints等
    - `all_`：记录用户对象的信息及被授权访问的对象信息
    - `dba_`：记录数据库实例的所有对象的信息，如dba_users包含数据库实例中所有用户的信息。dba的信息包含user和all的信息。大部分是视图
    - `v$`：当前实例的动态视图，包含系统管理和优化使用的视图
    - `gv_`：分布环境下所有实例的动态视图，包含系统管理和优化使用的视图，这里的gv表示 global v$的意思
- 基本数据字典
    - 常用
        - `dict` 构成数据字典的所有表的信息
        - `dba_users` 所有的用户信息（oracle密码是加密的，忘记密码只能修改）
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
- 数据库组件相关的数据字典(`v$`代表视图)
    - 数据库：
        - `v$database` 同义词v_$database，记录系统的运行情况
    - 控制文件：
        - `v$controlfile` 记录系统控制文件的路径信息
        - `v$parameter` 记录系统各参数的基本信息
        - `v$controlfile_record_section` 记录系统控制运行的基本信息
    - 数据文件：
        - `v$datafile` 记录来自控制文件的数据文件信息
        - `v$filestat` 记录数据文件读写的基本信息

### 常见错误

- 常用技巧
    - 常看日志文件目录 `show parameter background_dump_dest`
    - 在ORACLE 11g 以及ORACLE 12c中，告警日志文件的位置有了变化。主要是因为引入了ADR(Automatic Diagnostic Repository:一个存放数据库诊断日志、跟踪文件的目录)，关于ADR对应的目录位置可以通过查看v$diag_info系统视图。`select * from v$diag_info;`
    - `alert_orcl.log` 该目录下的日志文件
    - 在日志文件目录列举文件：`ll -rt *.trc`
        - `*.trc`：Sql Trace Collection file，`*.trm`：Trace map (.trm) file.Trace files(.trc) are sometimes accompanied by corresponding trace map (.trm) files, which contain structural information about trace files and are used for searching and navigation.（**主要看*.trc文件**）
        - 如：`dbcloud_cjq0_22515.trc` dbcloud为实例名，cjq0_22515为自动生成的索引
- 数据库服务器CPU飙高，参考《Java应用服务器及数据库服务器的CPU和内存异常分析》【数据库服务器故障】
- 表空间数据文件丢失，删除表空间报错`ORA-02449`、`ORA-01115` [^6]
    - oracle数据文件(datafile)被误删除后，只能把该数据文件offline后drop掉
    - `sqlplus / as sysdba`
    - `shutdown abort` 强制关闭oracle
    - `startup mount` 启动挂载
    - `alter database datafile '/home/oracle/xxx' offline drop;` 从数据库删除该表空间的数据文件
        - `select file_name, tablespace_name from dba_data_files;` 查看表空间数据文件位置
    - `alter database open;`
    - `drop tablespace 表空间名`
- 表空间不足
    - 报错`ORA-01653: unable to extend table` [^7]
        - 重设(不是基于原大小增加)表空间文件大小：`alter database datafile '数据库文件路径' resize 2000M;` (表空间单文件默认最大为32G=32768M，与db_blok_size大小有关，默认db_blok_size=8K，在初始化表空间后不能再次修改)
        - 开启表空间自动扩展，每次递增50M `alter database datafile '/home/oracle/data/users01.dbf' autoextend on next 50M;`
        - 为此表空间新增数据文件 `ALTER TABLESPACE USERS ADD DATAFILE '/home/oracle/data/users02.dbf' SIZE 1024M;`
        - 增加数据文件和表空间大小可适当重启数据库。查看表空间状态

            ```sql
            select a.tablespace_name "表空间名",
                a.bytes / 1024 / 1024 "表空间大小(m)",
                (a.bytes - b.bytes) / 1024 / 1024 "已使用空间(m)",
                b.bytes / 1024 / 1024 "空闲空间(m)",
                round(((a.bytes - b.bytes) / a.bytes) * 100, 2) "使用比",
                a.file_name "全路径的数据文件名称",
                autoextensible "表空间自动扩展", 
                increment_by "自增块(默认1blocks=8k)"
            from (select tablespace_name, file_name, autoextensible, increment_by, sum(bytes) bytes
                    from dba_data_files
                group by tablespace_name, file_name, autoextensible, increment_by) a,
                (select tablespace_name, sum(bytes) bytes, max(bytes) largest
                    from dba_free_space
                group by tablespace_name) b
            where a.tablespace_name = b.tablespace_name
            ```
    - `ORA-01654:unable to extend index`，解决步骤 [^8]
        - 情况一表空间已满：通过查看表空间`USERS`对应的数据文件`users01.dbf`文件大小已经32G(表空间单文件默认最大为32G=32768M，与db_blok_size大小有关，默认db_blok_size=8K，在初始化表空间后不能再次修改)
            - 解决方案：通过上述方法增加数据文件解决
        - 情况二表空间未满：查询的表空间剩余400M，且该索引的next_extent=700MB，即给该索引分配空间时不足
            - 解决方案：重建该索引`alter index index_name rebuild tablespace indexes storage(initial 256K next 256K pctincrease 0)`(还为测试)

## 安装

- 数据库安装包：[oracle](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
- oracle静默安装, 关闭客户端后再次以oracle用户登录无法运行sql命名, 需要执行`source ~/.bash_profile`


---

图片说明

- lsnrctl-status显示图片

    ![lsnrctl-status](/data/images/db/lsnrctl-status.png)

---

参考文章

[^1]: http://www.cnblogs.com/advocate/archive/2010/08/20/1804063.html
[^2]: http://blog.csdn.net/starnight_cbj/article/details/6792364
[^3]: http://www.cnblogs.com/yzy-lengzhu/archive/2013/03/11/2953500.html
[^4]: http://blog.csdn.net/studyvcmfc/article/details/5679235
[^5]: http://blog.csdn.net/yitian20000/article/details/6256716
[^6]: [强制删除表空间](http://blog.chinaunix.net/uid-11570547-id-59108.html)
[^7]: [表空间不足解决办法](http://blog.sina.com.cn/s/blog_9d4799c701017pw1.html)
[^8]: [ORA-01654索引无法通过表空间扩展](https://www.cnblogs.com/langtianya/p/6567881.html)
