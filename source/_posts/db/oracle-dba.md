---
layout: "post"
title: "Oracle DBA"
date: "2016-10-12 21:06"
categories: [db]
tags: [oracle, dba]
---

## 简介

- 注：本文中 aezo/aezo 一般指用户名/密码，local_orcl 指配置的本地数据库服务名，remote_orcl 指配置的远程数据库服务名。以 11g 为例
- 安装oracle 11.2g参考印象笔记(测试通过)
    - **需要注意数据文件目录(/u01/app/oracle/oradata)挂载的磁盘，建议将`/u01`目录挂载到单独的数据盘上**

### oracle 相关名词和原理

- 数据库名(db_name)、实例名(instance_name)、以及操作系统环境变量(oracle_sid) [^1]
  - `db_name`: 在每一个运行的 oracle 数据库中都有一个数据库名(如: orcl)，如果一个服务器程序中创建了两个数据库，则有两个数据库名。
  - `instance_name`: 数据库实例名则用于和操作系统之间的联系，用于对外部连接时使用。在操作系统中要取得与数据库之间的交互，必须使用数据库实例名(如: orcl)。与数据库名不同，在数据安装或创建数据库之后，实例名可以被修改。例如，要和某一个数据库 server 连接，就必须知道其数据库实例名，只知道数据库名是没有用的。用户和实例相连接。
  - `oracle_sid`: 有时候简称为 SID。在实际中，对于数据库实例名的描述有时使用实例名(instance_name)参数，有时使用 ORACLE_SID 参数。这两个都是数据库实例名。instance_name 参数是 ORACLE 数据库的参数，此参数可以在参数文件中查询到，而 ORACLE_SID 参数则是操作系统环境变量，用于和操作系统交互，也就是说在操作系统中要想得到实例名就必须使用 ORACLE_SID。此参数与 ORACLE_BASE、`ORACLE_HOME`等用法相同。在数据库安装之后，ORACLE_SID 被用于定义数据库参数文件的名称。如：$ORACLE_BASE/admin/DB_NAME/pfile/init$ORACLE_SID.ora。
- `service_name`：是网络服务名(如：local_orcl)，可以随意设置，相当于某个数据库实例的别名方便记忆和访问。`tnsnames.ora`文件中设置的名称(如：`local_orcl=(...)`)，也是登录 pl/sql 是填写的 Database
- `schema` schema 为数据库对象的集合，为了区分各个集合，需要给这个集合起个名字，这些名字就是我们看到的许多类似用户名的节点，这些类似用户名的节点其实就是一个 schema。schema 里面包含了各种对象如 tables, views, sequences, stored procedures, synonyms, indexes, clusters, and database links。一个用户一般对应一个 schema，该用户的 schema 名等于用户名，并作为该用户缺省 schema

## 启动/停止

- 监听程序(重启数据库可不用重启监听程序)

```bash
## 启动监听程序(shell命令行运行即可)
lsnrctl start
# 查看服务状态(见下图"lsnrctl-status显示图片")。如：Instance "orcl", status READY, has 1 handler(s) for this service...
lsnrctl status
```

- **重启数据库**

```bash
## 重启服务
# su - oracle && source ~/.bash_profile
# 以nolog、sysdba身份登录，进入sql命令行
sqlplus / as sysdba # sqlplus /nolog
# 大多数情况下使用。迫使每个用户执行完当前SQL语句后断开连接 (sql下运行，可无需分号)
shutdown immediate;
# `shutdown;` 则是有用户连接就不关闭，直到所有用户断开连接
# 正常启动（sql下运行；1启动实例，2打开控制文件，3打开数据文件）。提示`Database opened.`则表示数据库启动成功
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
startup mount dbname
-- 先执行"nomount"，然后执行"mount"，再打开包括Redo log文件在内的所有数据库文件，这种方式下才可访问数据库中的数据
startup open dbname
-- 等于三个命令：startup nomount、alter database mount、alter database open
startup
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

#### 执行脚本

- plsql 打开命令行窗口，执行 sql 文件：**`start D:\sql\my.sql`** 或 `@ D:/sql/my.sql`（部分语句需要执行`commit`提交，建议 start）
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

### 数据库相关

#### 连接

- 查询数据库当前连接数 `select count(*) from v$session;`
  - 查询当前数据库不同用户的连接数：`select username,count(username) from v$session where username is not null group by username;`
- 查询数据库最大连接数 `select value from v$parameter where name = 'processes'`、`show parameter processes`
  - 修改数据库最大连接数：`alter system set processes = 500 scope = spfile;` 需要重启数据库
- 查询连接信息 `select * from v$session a,v$process b where a.PADDR=b.ADDR`
  - sid 为 session, spid 为此会话对应的系统进程 id

#### 表空间

- [表空间不足/扩容参考下文](#表空间不足)
- oracle 和 mysql 不同，创建表空间相当于 mysql 的创建数据库。创建了表空间并没有创建数据库实例 [^2]
- oracle自带表空间：SYSTEM、SYSAUX、TEMP、UNDO、USERS

```sql
sqlplus / as sysdba

-- 创建表空间，要先创建好`/u01/app/oracle/oradata/orcl`目录，最终会产生一个aezocn_file文件(Windows上位大写)，表空间之后可以修改
-- 此处是创建一个初始大小为 500m 的表空间，当空间不足时每次自动扩展 10m，无限扩展(oracle 有限制，最大扩展到 32G，仍然不足则需要添加表空间数据文件)
create tablespace aezocn datafile '/u01/app/oracle/oradata/orcl/aezocn_file' size 500m autoextend on next 10m maxsize unlimited extent management local autoallocate segment space management auto;

-- 删除表空间(包含数据和数据文件)
-- drop tablespace aezocn;
drop tablespace aezocn including contents and datafiles;

-- 扩展：创建用户并赋权(新创建项目时一般新建表空间和用户)
create user smalle identified by smalle default tablespace aezocn;
grant create session to aezo;
grant unlimited tablespace to aezo;
grant dba to aezo; -- 导入导出时，只有 dba 权限的账户才能导入由 dba 账户导出的数据，因此不建议直接设置用户为 dba
```

#### 锁表

```sql
-- 查询被锁表的信息（多刷新几次，应用可能会临时锁表）
select s.sid, s.serial#, l.*, o.*, s.* FROM gv$locked_object l, dba_objects o, gv$session s
    where l.object_id = o.object_id and l.session_id = s.sid;
-- 关闭锁表的连接：alter system kill session '200, 50791';
alter system kill session '某个sid, 某个serial#';
```

#### 索引

- 索引在逻辑上和物理上都与相关的表和数据无关，当创建或者删除一个索引时，不会影响基本的表 [^4]
- 进行索引操作建议在无其他链接的情况下，或无响应写操作的情况下，数据量越大创建索引越耗时
- Oracle 在创建时会做相应操作，因此创建后就会看到效果，无需重启服务
- 索引是全局唯一的
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

- create、rebuild 对大表进行索引操作时切记加上`online`参数，此时 DDL 与 DML 语句可以并行运行，防止阻塞. [^11]

```sql
-- 创建索引
create index index_in_out_regist_id on ycross_storage(in_out_regist_id) online;
-- 重命名索引
alter index index_in_out_regist_id rename to in_out_regist_id_index online;
-- 重建索引
alter index index_in_out_regist_id rebuild online;
-- 删除索引
drop index index_in_out_regist_id online;
-- 查看索引
select * from all_indexes where table_name='ycross_storage';

-- 1.分析索引
analyze index index_in_out_regist_id validate structure;
-- 2.查看索引分析结果
select height,DEL_LF_ROWS/LF_ROWS from index_stats;
-- 3.查询出来的 height>=4 或者 DEL_LF_ROWS/LF_ROWS>0.2 的场合, 该索引考虑重建
alter index index_in_out_regist_id rebuild online;
```

### 用户相关

#### 用户基本操作

- 基本操作

```sql
-- 创建用户，默认使用的表空间是`USERS`(用户名不区分大小写，密码区分)
create user smalle identified by smalle;
-- 创建用户并指定默认表空间
create user smalle identified by smalle default tablespace aezocn;

-- 删除用户
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

#### 新建用户并赋予表查询权限

```sql
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

-- 批量设置表别名（同义词）
-- （1）通过存储过程，参考上述代码（取消注释：sqlstr := 'create or replace SYNONYM ' || [table_grant_user] || '.' || [v_tabname] || ' for ' || [table_owenr_user] || '.' || [v_tabname];）
-- （2）获取添加表别名语句
select 'create or replace synonym SMALLE.' || object_name || ' for ' || owner || '.' || object_name || ';'
   from dba_objects
   where owner in ('AEZO') and object_type = 'TABLE';
```

### sqlplus 使用技巧

- sqlplus 执行 PL/SQL 语句，再输入完语句后回车一行输入`/`
- `set line 1000;` 可适当调整没行显示的宽度
  - 永久修改显示行跨度，修改`glogin.sql`文件，如`/usr/lib/oracle/11.2/client64/lib/glogin.sql`，末尾添加`set line 1000;`
- `set serverout on;` 开启输出
  - 否则执行`begin dbms_output.put_line('hello world!'); end;` 无法输出
- `set autotrace on` 后面运行的 sql 会自动进跟踪统计
- 删除字符变成`^H`解决办法：添加`stty erase ^H`到`~/.bash_profile`

### 查询相关

- 系统
  - 查看服务是否启动：`tnsping local_orcl` cmd 直接运行
    - 远程查看(cmd 运行)：`tnsping 192.168.1.1:1521/orcl`、或者`tnsping remote_orcl`(其中 remote_orcl 已经在本地建立好了监听映射，如配置在 tnsnames.ora)
    - 如果能够 ping 通，则说明客户端能解析 listener 的机器名，而且 lister 也已经启动，但是并不能说明数据库已经打开，而且 tsnping 的过程与真正客户端连接的过程也不一致。但是如果不能用 tnsping 通，则肯定连接不到数据库
    - **实例 tnsping 突然高达 1w 多毫秒**，如`listener.log`(/u01/oracle/diag/tnslsnr/oracle/listener)日志文件过大，可重新创建一个此日志文件. [^10]
  - 查看表空间数据文件位置：`select file_name, tablespace_name from dba_data_files;`
  - 查询数据库字符集 
    - 查看oracle服务端编码：select * from sys.nls_database_parameters;
        - 查看服务器语言和字符集 `select userenv('language') from dual;` 如：`AMERICAN_AMERICA.AL32UTF8`、`SIMPLIFIED CHINESE_CHINA.ZHS16GBK`
            - 格式为`language_territory.charset`：Language 指定服务器消息的语言，territory 指定服务器的日期和数字格式，charset 指定字符集
        - `select * from nls_database_parameters where parameter='NLS_CHARACTERSET';`(如`AL32UTF8`)
    - 查看client编码：select * from sys.nls_session_parameters;
        - 在windows平台下，就是注册表里面`HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE\HOME0\NLS_LANG`
        - PL/SQL则看环境变量`NLS_LANG`
    - 查询dmp文件的字符集
        - 用oracle的exp工具导出的dmp文件也包含了字符集信息，dmp文件的第2和第3个字节记录了dmp文件的字符集。如果dmp文件不大，比如只有几M或几十M，可以用UltraEdit打开(16进制方式)，看第2第3个字节的内容，如0354，然后用以下SQL查出它对应的字符集
        - `select nls_charset_name(to_number('0354','xxxx')) from dual;` 结果是ZHS16GBK
    - 参考(修改字符集)：http://blog.itpub.net/29863023/viewspace-1331078/
        - 修改数据库编码(在oracle 11g上通过测试)

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
-- 获取表注释，对应还有 user_tab_comments
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
  # alert_orcl.log为警告日志(一般只有一个)；*.trc为日志追踪文件；*.trm为追踪文件映射信息；cdmp_20191212101335为备份？
  select * from v$diag_info; # 查看日志目录(ADR Home)
  ll -rt *.trc | grep ' 23 ' # 列举23号日期的trc文件。如`dbcloud_cjq0_22515.trc` dbcloud为实例名，cjq0_22515为自动生成的索引
  ll -hrt *.trc | grep ' 23 ' | awk '{print $9}' | xargs grep 'ORA-' # 查看23号的oracle trc日志，并找出日志中出现ORA-的情况
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

### 表空间数据文件位置迁移

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

### 清理存储空间

- `truncate table emp;` oracle清空无用表数据，适用于表中含有大量数据
    - truncate与drop是DDL语句，执行后无法回滚（无法通过binlog回滚）；delete是DML语句，可回滚
    - truncate不会激活与表有关的删除触发器；delete可以
    - truncate后会使表和索引所占用的空间会恢复到初始大小；delete操作不会减少表或索引所占用的空间，drop语句将表所占用的空间全释放掉
    - truncate不能对有外键约束引用的表使用
    - 执行truncate需要drop权限
- 使用move移动数据所在表空间
    - 可以起到清理存储碎片的功能。类似的有`shrink space`，但是清理效果没move好
    - move一个表到另外一个表空间时，索引不会跟着一起move，而且会失效(一般需要重建索引)
        - move过的普通表，在不用到失效的索引的操作语句中，语句执行正常，但如果操作的语句用到了索引（主键当做唯一索引），则此时报告用到的索引失效，语句执行失败，其他如外键，非空约束，缺省值等不会失效
    - LONG类型不能通过MOVE来传输特别提示，尽量不要用LONG类型
    - LOB类型在建立含有lob字段的表时，oracle会自动为lob字段建立两个单独的segment,一个用来存放数据（segment_type=LOBSEGMENT），另一个用来存放索引（segment_type=LOBINDEX），默认它们会存储在和表一起的表空间。我们对表MOVE时，LOG类型字段和该字段的索引不会跟着MOVE，必须要单独来进行MOVE

    ```sql
    -- 移动表到当前空间，即重建此表数据(清理存储碎片功能)：可解决delete删除的表数据减少了，但是表空间占用量不会变
    alter table emp move;
    -- 移动表到users表空间
    alter table emp move tablespace users;
    -- 移动LOB类型(CLOB/BLOB)字段en到另外一个表空间(未测试)
    alter table emp move lob(en) store as (tablespace users);
    
    -- 重建索引
    alter index index_name rebuild;
    alter index pk_name rebuild;
    ```
- delete删除的表数据减少了，但是表空间占用量不会变。可使用move移动数据所在表空间
- `UNDOTBS1`占用较大表空间

```bash
# 参考：https://blog.csdn.net/wxlbrxhb/article/details/14448777
# 对用户无感，无需重启数据库

# 本视图自启动即保持并记录各回滚段统计项
# USN：回滚段标识; XACTS：活动事务数; RSSIZE：回滚段默认大小; SHRINKS：回滚段收缩次数
select usn, xacts, rssize/1024/1024/1024, hwmsize/1024/10244/1024, shrinks from v$rollstat order by rssize;
# 创建新的 UNDOTBS 表空间。路径和原表空间保持一致
create undo tablespace undotbs2 datafile '/home/oracle/data/undotbs02.dbf' size 100m autoextend on;
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
# 如果删除表空间文件后磁盘没有变化可查看是否进程还占用。如果还占用有说可杀掉相关进程，单还是建议重启数据库；如果无此问题则无需重启数据库
lsof | grep deleted
```

### 导入导出

- `.dmp`适合大数据导出，`.sql`适合小数据导出(表中含有 CLOB 类型字段则不能导出)

#### dmp格式导出导入

- 输入 `imp/exp 用户名/密码` 可根据提示导入导出。**直接 cmd 运行** [^4]
    - 成功提示 `Export terminated successfully [with/without warnings]`
    - 失败提示 `Export terminated unsuccessfully [with/without warnings]`
- 导入导出均分为全量模式、用户模式、表模式
    - 参考：https://www.cnblogs.com/songdavid/articles/2435439.html
- 导入导出一定要注意服务器、客户端字符集`NSL_LANG`，否则可能出现数据、字段备注、存储过程等乱码
    - 查询字符集参考本文[查询相关(查询数据库字符集)](#查询相关)
    - **在导入DMP文件前，在客户端导入与服务器一致的环境变量，例如：`set NLS_LANG=AMERICAN_AMERICA.AL32UTF8`**，或者在/etc/profile、oracle用户的`.bash_profile`文件中导出NLS_LANG
- 导出

```bash
# 可将导出的dmp文件再tar压缩后通过scp传输到另外一台服务器上
# 设置字符集，防止乱码
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8

## 用户模式：导出 scott 用户的所有对象，前提是 system 用户有相关权限
# system/manager@remote_orcl：使用远程模式(remote_orcl 为在本地建立的远程数据库网络服务名，即 tnsnames.ora 里面的配置项名称。或者 system/manager@192.168.1.1:1521/orcl)
# compress=y：压缩数据
# rows=n：不导出数据行，只导出结构
# buffer=10241024：缓冲区，数据量大时可使用
exp smalle/smalle_pass file=/home/oracle/exp.dmp log=/home/oracle/exp.log compress=y owner=scott

## 表模式：导出 scott 的 emp,dept 表（导出其他用户表时，smalle用户需要有相关权限）
# 常见错误(EXP-00011)：原因为 11g 默认创建一个表时不分配 segment，只有在插入数据时才会产生。 [^3]
exp smalle/smalle_pass file=/home/oracle/exp.dmp log=/home/oracle/exp.log tables=scott.emp,scott.dept
# exp scott/tiger file=/home/oracle/exp.dmp tables=emp
# 导出表部分数据
exp scott/tiger file=/home/oracle/exp.dmp tables=emp query=\" where ename like '%AR%'\"

## 全量模式：导出的是整个数据库，包括所有的表空间、用户/密码
exp smalle/smalle_pass file=/home/oracle/exp.dmp log=/home/oracle/exp.log compress=y full=y buffer=10241024
```
- 导入

```bash
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8

## 用户模式：一般需要先将用户对象全部删掉，如可删除用户对应的表空间重新创建
# ignore=y：忽略错误，继续导入
imp smalle/smalle_pass file=/home/oracle/exp.dmp log=/home/oracle/imp.log ignore=y fromuser=scott touser=smalle

## 表模式：将 scott 的表 emp、dept 导入到用户 aezo
# 此处 file/fromuser/touser 都可以指定多个
imp smalle/smalle_pass file=/home/oracle/exp.dmp log=/home/oracle/imp.log ignore=y fromuser=scott tables=emp,dept touser=smalle

## 全量模式：导入的是整个数据库，包括所有的表空间
# 一般需要设置ignore=y，导入过程中会报一些错误需忽略，如导入系统相关数据时，由于目标数据库已经存在相关对象，从而报错
imp smalle/smalle_pass file=/home/oracle/exp.dmp log=/home/oracle/imp.log full=y ignore=y
```

#### pl/sql

- pl/sql 提供 dmp、sql(SQL Inserts, 不支持 CLOB 类型字段)、pde(pl/sql 提供)格式的数据导入导出
    - dmp格式导入导出
        - 其中 Executable 路径为 `%ORACLE_HOME%/BIN/exp.exe` 和 `%ORACLE_HOME%/BIN/imp.exe` 如：`D:/java/oracle/product/11.2.0/dbhome_1/BIN/exp.exe`
    - sql格式导入导出
        - 导入时SQL*Plus Executable选择`%ORACLE_HOME%/BIN/sqlplus.exe`文件，或者勾选基于命令行导入
    - pde格式导入导出，**慎用**
        - 使用PL/SQL绿色版导出pde，直接会将被导出的表数据删掉
    - 当`View`按钮可点击时，即表示导出完成
- 导出导入对象结构
    - `Tools - Export User Objects - 选择表/序列/存储过程等` 导出结构
- 导出导入表数据
    - `Tools - Export Tables - 选择表导出` 导出数据
    - `Tools - Import Tablse - 选择导入文件` 导入数据
- 命令窗口执行SQL文件(plsql 执行 sql 文件)
    - `start D:/sql/my.sql` 或 `@D:/sql/my.sql`（部分语句需要执行`commit`提交，文件不要放在C盘）

#### sql导出导入(sqlplus)

- 导出查询结果

```sql
set echo off;
set heading off;
set feedback off;
spool /home/myout.sql
select text from user_source;-- 查询所有的存储过程(运行时去掉此备注)
spool off;
```
- 导入：`@/home/my.sql`，或者命令行运行`sqlplus root/root@127.0.0.1:1521/orcl @my.sql`

#### Oracle表结构与Mysql表结构转换

- 参考 [mysql-dba.md:Oracle 表结构与 Mysql 表结构转换](/_posts/db/mysql-dba.md#其他)

### 密码策略修改

```sql
-- 查询user是否锁定、及时间
SELECT USERNAME,ACCOUNT_STATUS,LOCK_DATE,CREATED,PROFILE FROM DBA_USERS WHERE USERNAME = 'TEST_USER';
-- 修改密码
alter user TEST_USER account unlock identified by Hello1234!;

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

### 数据恢复

- 基于`of timestamp`恢复，用于少量数据被误删除

```sql
-- 查询某个时间点my_table表的所有数据
select * from my_table as of timestamp to_timestamp('2000-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS');
-- 查询某个时间点my_table表的数据
select id, name, '' from my_table as of timestamp to_timestamp('2000-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') where sex = 1;

```

## 常见错误

### 数据库服务器 CPU 飙高

- 参考[数据库服务器故障](/_posts/devops/Java应用CPU和内存异常分析.md#数据库服务器故障)

### 表空间不足

- 报错`ORA-01653: unable to extend table` [^7]
    - 重设(不是基于原大小增加)表空间文件大小：`alter database datafile '数据库文件路径' resize 2000M;` (表空间单文件默认最大为 32G=32768M，与 db_blok_size 大小有关，默认 db_blok_size=8K，在初始化表空间后不能再次修改)
    - 开启表空间自动扩展，每次递增 50M `alter database datafile '/home/oracle/data/users01.dbf' autoextend on next 50m;`
    - 为 USERS 表空间新增 1G 的数据文件 `alter tablespace users add datafile '/home/oracle/data/users02.dbf' size 1024m;`
        - 此时增加的数据文件还需要再次运行上述自动扩展语句从而达到自动扩展
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
    select segment_name, sum(bytes)/1024/1024/1024 as "GB" from user_extents group by segment_name order by sum(bytes) desc;
    -- 上面结果返回中如果存在SYS_LOBxxx的数据(oracle会将[C/B]LOB类型字段单独存储)，则可通过下面语句查看属于哪张表
    select * from dba_lobs where segment_name like 'SYS_LOB0000109849C00008$$';

    -- 列出数据库里每张表的记录条数
    select t.table_name,t.num_rows from user_tables t order by num_rows desc;
    ```
- 报错`ORA-01654:unable to extend index`，解决步骤 [^8]
  - 情况一表空间已满：通过查看表空间`USERS`对应的数据文件`users01.dbf`文件大小已经 32G(表空间单文件默认最大为 32G=32768M，与 db_blok_size 大小有关，默认 db_blok_size=8K，在初始化表空间后不能再次修改)
    - 解决方案：通过上述方法增加数据文件解决
  - 情况二表空间未满：查询的表空间剩余 400M，且该索引的 next_extent=700MB，即给该索引分配空间时不足
    - 解决方案：重建该索引`alter index index_name rebuild tablespace indexes storage(initial 256K next 256K pctincrease 0)`(还未测试)

### 数据库无法连接

```sql
-- 查看当前数据库建立的会话情况
select sid,serial#,username,program,machine,status from v$session;
-- 查询数据库允许的最大连接数，一般如300
select value from v$parameter where name = 'processes';
```

### 其他

- 表空间数据文件丢失时，删除表空间报错`ORA-02449`、`ORA-01115` [^6]
    - oracle 数据文件(datafile)被误删除后，只能把该数据文件 offline 后 drop 掉
    - `sqlplus / as sysdba`
    - `shutdown abort` 强制关闭 oracle
    - `startup mount` 启动挂载
    - `alter database datafile '/home/oracle/xxx' offline drop;` 从数据库删除该表空间的数据文件
        - `select file_name, tablespace_name from dba_data_files;` 查看表空间数据文件位置
    - `alter database open;`
    - `drop tablespace 表空间名`

## oracle 安装

- 数据库安装包：[oracle](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
- oracle 静默安装, 关闭客户端后再次以 oracle 用户登录无法运行 sql 命名, 需要执行`source ~/.bash_profile`
- oracle目录
    - Oracle基目录为`D:/java/oracle`，基目录只是把不同版本的oracle放在一起
    - ORACLE_HOME 为`D:/java/oracle/product/11.2.0/dbhome_1`，`%ORACLE_HOME%/bin`中为一些可执行程序（如：导入 imp.exe、导出 exp.exe）

## pl/sql 安装和使用

- PL/SQL绿色版安装，修改配置项
    - 配置 - User Interface - Fonts - Browser/Grid/Main Font(Segoe UI,常规,小五); Editor(Courier New,常规,10)
    - 配置 - User Interface - Appearance - Language(选择英文), Switch to Menu(菜单以下拉菜单方式显示)

### pl/sql 安装

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
  - `本地-监听程序-LISTENER`中的主机要为计算机全名(如：ST-008)，对应文件`$ORACLE_HOME/NETWORK/ADMIN/listener.ora`
    - 使用 pl/sql 也需要配置，且第一个 ADDRESS 需要类似配置为`TCP/IP，ST-008，1521`
  - `本地-服务命名`下的都为`网络服务名`，对应文件`tnsnames.ora`
  - 有的需参考 https://blog.csdn.net/pengpengpeng85/article/details/78757484 创建监听程序配置和本地网络服务名配置
- 文本操作

  - 使用 sqlplus 登录时，可直接修改`$ORACLE_HOME/NETWORK/ADMIN/tnsnames.ora`
  - 安装了 pl/sql，可能需要修改 tnsnames.ora 的文件路径类似与`D:\java\oracle\product\instantclient_10_2\tnsnames.ora`。此时 oracle 自带的 tnsnames.ora 将会失效
  - 配置实例：HOST/PORT 分别为远程 ip 地址和端口，SERVICE_NAME 为远程服务名，aezocn 为远程服务名别名(本地服务名)

    ```html
    aezocn = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST =
    192.168.1.1)(PORT = 1521)) ) (CONNECT_DATA = (SERVER = DEDICATED)
    (SERVICE_NAME = orcl) ) )
    ```

- 如果 oracle 服务在远程机器上，本地通过 plsql 连接，则不需要在本地启动任何和 oracle 相关的服务。如果本地机器作为 oracle 服务器，则需要启动 OracleServiceORCL，此时只能在命令行连接数据库，如果需要通过 plsql 连接则需要启动类似"OracleOraDb11g_home1TNSListener"的 TNS 远程监听服务

## ODAC和ODBC

- ODAC全称：oracle Date Access Components，为oracle数据访问组件，[32位的安装包](http://pan.baidu.com/s/1ntZf92p)在32位，64位的都可以采用的
    - 执行安装程序 - 下一步 - Oracle Client 11.2.0.3 - Oracle基目录=D:\java\oracle，软件位置名称=OraClient11g_home2，路径=D:\java\oracle\product\11.2.0\dbhome_2 - 下一步 - 安装
	- 如果提示“服务OracleMTSRecoveryService已经存在” - 忽略
    - 或者下载ODAC112030Xcopy_64bit.zip等压缩包进行安装，推荐
- ODBC：Windows上通过配置不同数据库（SQL Server、Oracle等）的驱动进行访问数据库。找到控制面板-管理工具-数据源ODBC

## 日常维护

- 检查`listener.log`是否过大
    - 可能产生异常场景：实例 tnsping 突然高达 1w 多毫秒，发现listener.log达到4G
    - 解决：日志文件过大，可重新创建一个此日志文件
    - 查看文件位置`show parameter dump;`得到如`user_dump_dest => g:\app\administrator\diag\rdbms\orcl\orcl\trace`，得知日志目录为：`g:\app\administrator\diag`，然后在此目录查找`tnslsnr/主机名/listener/trace/listener.log`文件



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
