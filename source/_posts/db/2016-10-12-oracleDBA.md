---
layout: "post"
title: "oracleDBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [oracle, dba]
---

* 目录
{:toc}

## 简介

> 注：本文中 aezo/aezo 一般指用户名/密码，local_orcl指配置的本地数据库服务名，remote_orcl指配置的远程数据库服务名。以11g为例

1. 下载
    - 数据库安装包：[oracle](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)

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

### 网络配置

1. Net Manager的使用
    - `本地-监听程序-LISTENER`中的主机要为计算机全名(如：ST-008)。对应文件`listener.ora`
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

- pl/sql提供dmp、sql、pde(pl/sql提供)格式的数据导入导出
- 方法：`Tools - Export Tables/Import Tablse - 选择表导出`
- 其中Executable路径为 `%ORACLE_HOME%/BIN/exp.exe` 和 `%ORACLE_HOME%/BIN/imp.exe` 如：`D:/java/oracle/product/11.2.0/dbhome_1/BIN/exp.exe`

## 常用命令

### 操作相关

1. 系统
    - `lsnrctl start` 启动监听程序(shell命令行运行)。`lsnrctl status` 查看服务状态
    - `sqlplus /nolog` 以nolog身份登录，进入sql命令行
    - `startup;` 正常启动（1启动实例，2打开控制文件，3打开数据文件）
    - `shutdown immediate` 大多数情况下使用。迫使每个用户执行完当前SQL语句后断开连接
        - `shutdown;` 有用户连接就不关闭，直到所有用户断开连接
    - `exit;` 退出sqlplus
2. 管理员登录
    - sqlplus本地登录：`sqlplus / as sysdba`，以sys登录。sys为系统管理员，拥有最高权限；system为本地管理员，次高权限
    - sqlplus远程登录：`sqlplus aezo/aezo@192.168.1.1:1521/orcl` (orcl为远程服务名)，失败可尝试如下命令：
        - `sqlplus /nolog`
        - `connect aezo/aezo@192.168.1.1:1521/orcl;`，或者使用配置好的服务名连接`conn aezo/aezo@remote_orcl`
    - pl/slq管理员登录：用户名密码留空，Connect as 选择 SYSDBA 则默认以sys登录。登录远程只需要在tnsnames.ora进行网络配置即可
3. 用户相关
    - 创建用户：`create user aezo identified by aezo;`
        - 默认使用的表空间是`USERS`，使用`create user aezo identified by aezo default tablespace aezocn;`可设定默认表空间
        - 删除用户：`drop user aezo cascade;`
    - 修改用户密码：`alter user scott identified by tiger;`
    - 修改用户表空间：`alter user aezo default tablespace aezocn;`
    - 解锁用户：`alter user scott account unlock;` (新建数据库scott默认未解锁)
4. 授权
    - `grant create session to aezo;` 授予aezo用户创建session的权限，即登陆权限
    - `grant unlimited tablespace to aezo;` 授予aezo用户使用表空间的权限
    - `grant dba to aezo;` 授予管理权限(有dba角色就有建表等权限)

5. 连接数
    - 查询数据库最大连接数：`select value from v$parameter where name = 'processes;'`、`show parameter processes`
    - 查询数据库当前连接数：`select count(*) from v$session;`
    - 修改数据库最大连接数：`alter system set processes = 500 scope = spfile;` 需要重启数据库

### 查询相关

1. 系统
    - 查看服务是否启动：`tnsping local_orcl` cmd直接运行
        - 远程查看(cmd运行)：`tnsping 192.168.1.1:1521/orcl`、或者`tnsping remote_orcl`(其中remote_orcl已经在本地建立好了监听映射，如配置在tnsnames.ora)
        - 如果能够ping通，则说明客户端能解析listener的机器名，而且lister也已经启动，但是并不能说明数据库已经打开，而且tsnping的过程与真正客户端连接的过程也不一致。但是如果不能用tnsping通，则肯定连接不到数据库
    - 查看表空间数据文件位置：`select file_name, tablespace_name from dba_data_files;`
2. 用户相关查询
    - 查看当前用户默认表空间：`select username, default_tablespace from user_users;`(以dba登录则结果为SYS和SYSTEM)
    - 查看当前用户角色：`select * from user_role_privs;`
    - 查看当前用户系统权限：`select * from user_sys_privs;`
    - 查看当前用户表级权限：`select * from user_tab_privs;`
    - 查看用户下所有表：`select * from user_tables;`
    - DBA相关查询见数据库字典
4. 数据字典 [^5]
    - `user_`：记录用户对象的信息，如user_tables包含用户创建的所有表，user_views，user_constraints等
    - `all_`：记录用户对象的信息及被授权访问的对象信息
    - `DBA_`：记录数据库实例的所有对象的信息，如DBA_USERS包含数据库实例中所有用户的信息。DBA的信息包含USER和ALL的信息。大部分是视图
    - `V$`：当前实例的动态视图，包含系统管理和优化使用的视图
    - `GV_`：分布环境下所有实例的动态视图，包含系统管理和优化使用的视图，这里的GV表示 Global v$的意思
5. 基本数据字典
    - 常用
        - `DICT` 构成数据字典的所有表的信息
        - `DBA_USERS` 所有的用户信息（oracle密码是加密的，忘记密码只能修改）
        - `DBA_TABLES` 所有用户的所有表的信息
        - `DBA_TABLESPACES` 记录系统表空间的基本信息；
        - `DBA_DATA_FILES` 记录系统数据文件及表空间的基本信息；
        - `DBA_FREE_SPACE` 记录系统表空间的剩余空间的信息；
    - 其他
        - `CAT` 当前用户可以访问的所有的基表
        - `TAB` 当前用户创建的所有基表，视图，同义词等
        - `DBA_VIEWS` 所有用户的所有视图信息
        - `DBA_CONSTRAINTS` 所有用户的表约束信息
        - `DBA_INDEXES` 所有用户索引的简要信息
        - `DBA_IND_COLUMNS` 所有用户索引的列信息
        - `DBA_TRIGGERS` 所有用户触发器信息
        - `DBA_SOURCE` 所有用户存储过程源代码信息
        - `DBA_PROCEDUS` 所有用户存储过程
        - `DBA_SEGMENTS` 所有用户段（表，索引，Cluster）使用空间信息
        - `DBA_TAB_COLUMNS` 所有用户的表的列（字段）信息
        - `DBA_SYNONYMS` 所有用户同义词信息
        - `DBA_SEQUENCES` 所有用户序列信息
        - `DBA_EXTENTS` 所有用户段的扩展段信息
        - `DBA_OBJECTS` 所有用户对象的基本信息（包括素引，表，视图，序列等）
6. 数据库组件相关的数据字典(`v$`代表视图)
    - 数据库：
        - `V$DATABASE` 同义词V_$DATABASE，记录系统的运行情况
    - 控制文件：
        - `V$CONTROLFILE` 记录系统控制文件的路径信息
        - `v$parameter` 记录系统各参数的基本信息
        - `V$CONTROLFILE_RECORD_SECTION` 记录系统控制运行的基本信息
    - 数据文件：
        - `V$DATAFILE` 记录来自控制文件的数据文件信息
        - `V$FILESTAT` 记录数据文件读写的基本信息

### 常见错误

1. 常用技巧
    - 常看日志文件目录 `show parameter background_dump_dest`
    - 在ORACLE 11g 以及ORACLE 12c中，告警日志文件的位置有了变化。主要是因为引入了ADR(Automatic Diagnostic Repository:一个存放数据库诊断日志、跟踪文件的目录)，关于ADR对应的目录位置可以通过查看v$diag_info系统视图。`select * from v$diag_info;`
    - `alert_orcl.log` 该目录下的日志文件
    - 在日志文件目录列举文件：`ll -rt *.trc`
        - `*.trc`：Sql Trace Collection file，`*.trm`：Trace map (.trm) file.Trace files(.trc) are sometimes accompanied by corresponding trace map (.trm) files, which contain structural information about trace files and are used for searching and navigation.（**主要看*.trc文件**）
        - 如：`dbcloud_cjq0_22515.trc` dbcloud为实例名，cjq0_22515为自动生成的索引

2. 表空间数据文件丢失，删除表空间报错ORA-02449、ORA-01115 [^6]
    - oracle数据文件(datafile)被误删除后，只能把该数据文件offline后drop掉
    - `sqlplus / as sysdba`
    - `shutdown abort` 强制关闭oracle
    - `startup mount` 启动挂载
    - `alter database datafile '/home/oracle/xxx' offline drop;` 从数据库删除该表空间的数据文件
        - `select file_name, tablespace_name from dba_data_files;` 查看表空间数据文件位置
    - `alter database open;`
    - `drop tablespace 表空间名`



[^1]: http://www.cnblogs.com/advocate/archive/2010/08/20/1804063.html
[^2]: http://blog.csdn.net/starnight_cbj/article/details/6792364
[^3]: http://www.cnblogs.com/yzy-lengzhu/archive/2013/03/11/2953500.html
[^4]: http://blog.csdn.net/studyvcmfc/article/details/5679235
[^5]: http://blog.csdn.net/yitian20000/article/details/6256716
[^6]: [强制删除表空间](http://blog.chinaunix.net/uid-11570547-id-59108.html)
