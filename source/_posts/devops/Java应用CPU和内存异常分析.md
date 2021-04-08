---
layout: "post"
title: "Java应用CPU和内存异常分析"
date: "2018-03-13 13:35"
categories: devops
tags: [CPU, 内存, 运维, oracle, ofbiz]
---

## 简介

- TODO
    - https://my.oschina.net/xionghui/blog/498785
- java应用常见故障：**高CPU占用**、**高内存占用**、**高I/O占用**(包括磁盘I/O、网络I/O、数据库I/O等)
- 高CPU常见场景：死循环(如while导致的较多)、高内存导致
    - 高内存占用也会引起高CPU占用：**内存溢出后，java的GC便会运行非常频繁，从而导致高CPU(此时可能已经产生了dump文件，但是应用还能访问，只是速度较慢。临时可考虑先重启服务)**
    - 相关命令参考[常用命令介绍：1-4](#常用命令介绍)
- 高内存常见场景：List集合数据量过大(常见从数据库获取大量数据，而没有进行分页获取) [^2]
    - `java.lang.OutOfMemoryError: PermGen space`，原因可能为
        - 程序启动需要加载大量的第三方jar包。例如：在一个Tomcat下部署了太多的应用
    - `java.lang.OutOfMemoryError: Java heap space`，原因可能为
        - Java虚拟机的堆内存设置不够，可以通过参数-Xms、-Xmx来调整
        - 代码中创建了大量大对象，并且长时间不能被垃圾收集器收集（存在被引用）
    - 在Java虚拟机中，内存分为三个代
        - 新生代New：新建的对象都存放这里
        - 老生代Old：存放从新生代New中迁移过来的生命周期较久的对象。新生代New和老生代Old共同组成了堆内存
        - 永久代Perm：是非堆内存的组成部分。主要存放加载的Class类级对象如class本身，method，field等等
- `grep 'OutOfM' * -5`

## 应用服务器故障

### 常用命令介绍

```bash
## 1.查看linux运行状态(htop工具显示更强大)：如8核则CPU可能达到800%
# Windows可以使用ProcessExplorer.exe查看进程和线程信息
top
jps -l # 由于PID里面也包含了该进程ID和线程ID，可结合jps快速找到进程ID
# 快捷键：x,y 高亮显示行和列；<,> 切换排序列；R 切换排序；H查看进程。更多参考[top命令](/_posts/linux/linux.md#top命令)
top -Hp <pid> # 查看某个进程的所有线程信息(-Hp顺序不能改变)。PID里面也包含了该进程ID和线程ID

## 2.显示某进程的线程列表。pid：进程id;
# 结果说明：（1）第一行为统计（2）%CPU为此线程CPU占用率（3）TIME为线程运行时间（4）%MEM为内存占用率
ps -mp <pid> -o THREAD,tid,time,rss,size,%mem

## 3.Java的jstack命令：打印线程的堆栈信息
# pid：进程id; tid线程id; -A 30表示显示30行; `printf "%x\n" <tid>`获取线程ID的16进制格式
# 如"OFBiz-JobQueue-0"为线程名，prio=10为优先级，tid为线程id，RUNNABLE为运行中
# "OFBiz-JobQueue-0" prio=10 tid=0x00007f2c60007800 nid=0x96d runnable [0x00007f2cfe187000]
#    java.lang.Thread.State: RUNNABLE
#       at java.net.SocketInputStream.socketRead0(Native Method)
#       ......
# 如果提示`20279: Unable to open socket file: target process not responding or HotSpot VM not loaded`，有可能是PID找错了，比如把线程ID当成了PID
jstack <pid> | grep `printf "%x\n" <tid>` -A 30
# 获取thread dump到文件。如果失败了可使用-F强制打印
jstack <pid> > jstack.out

## 4.Java的jmap命令(**生产环境会有一定影响**)：显示一个进程下具体线程的内存占用情况
# 可以查看当前Java进程创建的活跃对象数目和占用内存大小（此处按照大小查询前10个对象）；或者保存到文件（jmap -histo:live <pid> > /home/jmap.out）
jmap -histo:live <pid> | head -n 10
# 获取heap dump，方便用专门的内存分析工具（例如：MAT）来分析
# jmap命令获取：***执行时JVM是暂停服务的，所以对线上的运行会产生较大影响***（生成文件大小和程序占用内存差不多；2G大概暂停10秒钟，实际测试系统可能会暂停无法访问）
jmap -F -dump:live,format=b,file=/home/dump.hprof <pid>

## 5.项目启动添加jvm参数获取(不能实时获取)
-XX:+HeapDumpOnOutOfMemoryError # 出现 OOME 时生成堆 dump
-XX:HeapDumpPath=/home/jvmlogs # 生成堆文件的文件夹（需要先手动创建此文件夹）
```

#### java检测相关命令工具

> https://zheng12tian.iteye.com/blog/1420508

```bash
# 显示java进程，-l显示完整包名，-m显示传递给main方法的参数，-v显示传递给JVM的参数，
jps -lmv
# 查看运行时进程参数与JVM参数
jinfo -flags <PID>
# 查看当前虚拟机默认JVM参数
java -XX:+PrintFlagsFinal -version
```

### MAT工具使用/实例分析

- MAT(Memory Analyzer Tool)：根据分析dump文件从而分析堆内存使用情况，[下载](http://www.eclipse.org/mat/downloads.php)
- 运行jar包时加参数如：`java -jar test.jar -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/jvmlogs`，/home/jvmlogs为程序出现内存溢出时保存堆栈信息的文件（需要提前建好）
- MAT打开类似于`java_pid11457.hprof`的堆栈文件(File - Open Heap Dump。右键文件打开可能会失败)，需要设置MAT运行的最大内存足够大(设置`MemoryAnalyzer.ini`)，打开效果如下(`Leak Suspects Report`泄漏疑点报告)

    ![默认报告](/data/images/java/mat-leak-suspects.png)

    - 从上图的报告中可以看到`bio-0.0.0.0-6080-exec-16`有大量的`java.util.LinkedList`对象(此图片是和下面截图的hprof文件不是同一个)

#### 界面说明

- `Overview` 此dump文件分析的控制面板
    - Details：统计dump大小、类个数(ofbiz-yard正常12k左右)、对象个数、Class Loader个数(ofbiz-yard正常400个左右)
- `Biggest Objects by Retained Size` 大对象所占空间分析(饼图)
    - 白色为未使用
    - 其他颜色鼠标悬浮可查看相应的线程主要信息
    - `左键某扇形` - `Java Basics` - `Thread Details` 查看此大对象所在线程信息
- `Actions` 常用功能菜单
    - `Histogram` 列举每个class对应实例的数量
    - `Dominator Tree` 列举大对象组成树
    - `Top Consumers` 按照包和类列举大对象
    - `Duplicate Classes` 列举重复的class(多个类加载器加载的同一类文件导致类重复)
- `Reports` 报告类型
    - `Leak Suspects Report` 泄漏疑点报告(常用)
    - `Top Components` 列出大于总堆1%的组件的报告
- `Step By Step`
    - `Component Report` 分析属于一个公共根包或类加载器的对象

#### 具体分析

- MAT预览界面

    ![mat-overview](/data/images/java/mat-overview.png)
- `Dominator Tree`点击如下

    ![mat-dominator-tree](/data/images/java/mat-dominator-tree.png)

    ![mat-dominator-tree2](/data/images/java/mat-dominator-tree2.png)

    - 从图`mat-dominator-tree`中可以发现是存在大量的`LinkedList`；继续查看此List，结果如`mat-dominator-tree2`；从中可以发现是查询表`YyardVenueMovePlan`导致
- 查看堆栈信息(上图中`http-bio-0.0.0.0-6080-exec-76`和`http-bio-0.0.0.0-6080-exec-79`)，结果如下图。说明是调用了`MovePlan.java`中的`deleteMovePlan`导致出现大量的`LinkedList`

    ![mat-thread-details](/data/images/java/mat-thread-details.png)
- 查看对应代码，如下图。由于`YyardVenueMovePlan`数据非常大，如果`shortBoardId`为空（只有短驳计划才会有此字段，因此相当于查询所有非短驳计划），则出现内存溢出。返回去查看`LinkedList`中的对象，发现`shortBoardId`字段都为空，验证了上述假设

    ![oom_ofbiz_code](/data/images/java/oom_ofbiz_code.jpg)

#### 内存飙高，但是下载的dump文件却很小

- 现象：内存占用达到3G，下载的dump文件确只有400M左右(生成dump文件耗时1分钟，生成dump文件时应用无法访问)，并未发现内存溢出现象
- 可能原因
    - `-Xmx` 设置太小

### OFBiz项目案例分析

> 案例介绍：此问题主要是ofbiz在清理历史任务时，任务数据过大导致内存溢出，从而CPU飙升，最终服务器时常宕机。

- `htop`查看情况如下

可以看到其中PID=2273的进程CPU占用到达710%(服务器为8核)，内存占用22%(服务器为16G*0.22=3.52G，jvm参数设置的内存大小为3G)，其中线程运行时间达到5h29m。以上数据说明程序运行存在问题

![htop](/data/images/java/ofbiz-cpu.png)

- `ps -mp 2273 -o THREAD,tid,time,rss,size,%mem` 查看此进程下线程运行情况：实际中发现有7个进程占用CPU均达到几十分钟，且CPU和内存占用均非常高。(其中2个是ofbiz拉取历史任务进行清理的进程，5个为GC进行垃圾回收的进程)
- `jstack 2273 | grep `printf "%x\n" 2413` -A 40` 查看2273进程下2413线程的堆栈信息如下(或者输出到文件进行查看)

可以看到线程有以下调用信息`org.ofbiz.service.job.PurgeJob.exec(PurgeJob.java:55)`，如是可以去查看PurgeJob的源码。(当然应该多次查看此线程的堆栈，查看一次可能存在偶发性)

![jstack](/data/images/java/ofbiz-purgejob-jstack.png)

- ofbiz的PurgeJob相关源码。详细可参考《OFBiz服务和任务机制》

ofbiz任务机制有如下逻辑：当拉取任务线程为获取到需要执行的任务时，则进行历史任务数据(JobSandbox等表数据)清理工作，即获取当前时间4天(默认的purge-job-days)前完成或者取消的任务数据进行删除。

而此处是根据ofbiz实体引擎查询的历史数据放到一个EntityListIterator中进行遍历(查看源码可知本质并没有分页获取数据，而是将所有查询的数据放到ResultSet进行遍历)

由于本项目前期并没有太多的关注任务调用周期，从而导致大量任务堆积，并且不能及时清理。一定数量后，再次触发任务数据清理时就会从数据库获取大量数据到内存，从而内存移除，GC频繁清理，CPU飙升，服务器宕机。

![ofbiz-purgejob-src](/data/images/java/ofbiz-purgejob-src.png)

- MAT分析：从服务器下载dump文件使用MAT进行分析，发现也可发现上述情况

- 解决方案

由于个人觉得ofbiz任务机制不太好用，决定不去清理历史数据，而是手动定时清理(或绕过ofbiz定时去清理)。因此可以修改`/framework/service/config/serviceengine.xml`中`purge-job-days`的值。重新启动服务器(之前占用的内存无法及时清除，必须重启服务器)和项目一切正常


### 内存溢出

#### java.lang.OutOfMemoryError: PermGen space

https://wenku.baidu.com/view/0ae2586b7e21af45b307a8ac.html
关于cglib缓存问题 http://touchmm.iteye.com/blog/1155694 、 https://blog.csdn.net/englishma/article/details/42610545
https://blog.csdn.net/Aviciie/article/details/79281080

### 相关监测工具

> MAT上文已介绍、Jprofile 需要注册

#### JDK自带

- `jvisualvm.exe`、`jconsole.exe`类似，下面以`jvisualvm.exe`为例
- 本地连接：直接运行即可选择本地java项目进行监测
- 远程连接(最好关闭防火墙和安全组设置1-65535的入栈。除了JMX server指定的监听端口号外，JMXserver还会监听一到两个随机端口号，这些端口都必须允许连接)
    - 运行jstatd(可省略)
        - 在JAVA_HOME/bin目录下创建jstatd.all.policy文件，内容如下

            ```bash
            grant codebase "file:${java.home}/../lib/tools.jar" {
                permission java.security.AllPermission;
            };
            ```
        - `$JAVA_HOME/bin/jstatd -J-Djava.security.policy=jstatd.all.policy` 运行jstatd
    - 运行项目时添加JMX参数，如：`java -Djava.rmi.server.hostname=101.1.1.1 -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=8091 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -jar video-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod`
    - 添加JMX连接 - 输入`101.1.1.1:8091`即可

## 数据库服务器故障

- CPU故障展现 [^4]
    - 数据库服务器CPU飙高
    - oracle相关进程CPU占用高
    - 应用服务器响应很慢

### Oracle

- 查看数据库sql运行占用CPU时间较长的会话信息，并kill此会话

    ```sql
    -- 获取cpu总消耗时间过长的sql
    select sid, serial#, cpu_time, executions, round(cpu_time/executions/1000, 2) peer_secondes, sql_text, sql_fulltext
    from v$sql
    join v$session on v$sql.sql_id = v$session.sql_id
    where cpu_time > 20000
    order by round(cpu_time/executions/1000, 2) desc;

    -- 获取每次消耗cpu > 3s的sql. cpu_time为微秒
    select sid, serial#, sql_text, sql_fulltext, executions, round(cpu_time/executions/1000000, 2) peer_secondes_cpu_time, round(elapsed_time/executions/1000000, 2) peer_secondes_elapsed_time, last_load_time, disk_reads, optimizer_mode, buffer_gets
    from v$sql
    join v$session on v$sql.sql_id = v$session.sql_id
    where cpu_time/executions/1000000 > 3 --每次执行消耗cpu>3s的
    order by peer_secondes_cpu_time desc;

    -- kill相应会话（此时可能sql已经运行完成，或者timeout了，但是会话还在），此时CPU会得到一定缓解
    -- 从根源上解决问题需要对对应的sql_fulltext进行sql优化
    alter system kill session 'sid, serial#';
    ```
- 查看服务器CPU占用高较高的进程运行的sql语句(v$sqltext中的sql语句是被分割存储)，运行下列sql后输入进程pid
    - `top`查看占用CPU较高的进程，Commad中可以看到连接数据的命令信息，如`oracleorcl (LOCAL=NO)`为OFBiz的连接信息

    ```sql
    -- 其中&pid是使用top查看系统中进程占用CPU极高的PID (pl/sql中执行运行，会弹框输入pid)
    select sql_text
    from v$sqltext a
    where (a.hash_value, a.address) in
        (
            select decode(sql_hash_value, 0, prev_hash_value, sql_hash_value),
                decode(sql_hash_value, 0, prev_sql_addr, sql_address)
            from v$session b
            where b.paddr = (select addr from v$process c where c.spid = '&pid')
        )
    order by piece asc
    ```
- 查看占用CPU时间较长、每次每秒耗时较长的10条sql语句

    ```sql
    -- 查询耗时sql
    select *
    from (
        select sql_id, sql_text, round(cpu_time/executions/1000000, 2) peer_secondes_cpu_time, round(elapsed_time/executions/1000000, 2) peer_secondes_elapsed_time, last_load_time, disk_reads, optimizer_mode, buffer_gets
        from v$sql 
        where executions > 0 and PARSING_SCHEMA_NAME='OFBIZ'
        -- and last_load_time > to_char(sysdate-12/24, 'YYYY-MM-DD/HH24:MI:SS') -- 统计过去12小时到当前时间执行的sql性能情况
        -- order by cpu_time desc -- 占用CPU时间较长
        order by cpu_time/executions desc -- 每次每秒耗时较长
    )
    where rownum <= 10
    order by rownum asc
    
    -- 根据sql_id查询详细的sql语句(sql_fulltext)
    select sql_id, sql_text, sql_fulltext, round(cpu_time/executions/1000000, 2) peer_secondes_cpu_time, round(elapsed_time/executions/1000000, 2) peer_secondes_elapsed_time, last_load_time, disk_reads, optimizer_mode, buffer_gets
    from v$sql
    where sql_id = '6dwr4tmjt1txc'
    ```
- 常用查询

    ```sql
    -- 列出数据库里每张表的记录条数
    select t.table_name,t.num_rows from user_tables t ORDER BY NUM_ROWS DESC;
    -- 列出数据库里每张表分配的物理空间(基本就是每张表使用的物理空间)
    select segment_name, sum(bytes)/1024/1024 as "mb" from user_extents group by segment_name order by sum(bytes) desc;
    -- 查看表空间大小参考[oracle-dba.md#表空间不足](/_posts/db/oracle-dba.md#表空间不足)

    -- 列出消耗磁盘读取最多的5个sql
    select b.username username,
        a.disk_reads reads,
        a.executions exec,
        a.disk_reads / decode(a.executions, 0, 1, a.executions) peer_exec_reads,
        a.sql_text,
        a.sql_fulltext
    from v$sqlarea a, dba_users b
    where a.parsing_user_id = b.user_id
    and a.disk_reads > 100000
    order by a.disk_reads / decode(a.executions, 0, 1, a.executions) desc;

    -- 列出使用频率最高的5个sql
    select sql_text, sql_fulltext, executions
    from (select sql_text, sql_fulltext, executions,
                rank() over(order by executions desc) exec_rank
            from v$sql)
    where exec_rank <= 5;

    -- 列出需要大量缓冲读取（逻辑读）操作的5个sql
    select buffer_gets, sql_text, sql_fulltext
    from (select sql_text, sql_fulltext, buffer_gets,
                dense_rank() over(order by buffer_gets desc) buffer_gets_rank
            from v$sql)
    where buffer_gets_rank <= 5;
    ```

### Mysql

- `show full processlist;` 查看进程(**Time的单位是秒**)
	- `show processlist;` 查看进程快照
	- 查看进程详细

		```sql
		-- command: 显示当前连接的执行的命令，一般就是休眠或空闲（sleep），查询（query），连接（connect）
		-- time：线程处在当前状态的时间，单位是秒
		-- state：显示使用当前连接的sql语句的状态，很重要的列。state只是语句执行中的某一个状态，一个 sql语句，以查询为例，可能需要经过copying to tmp table，Sorting result，Sending data等状态才可以完成
		-- 查询正在执行，且基于耗时时间降序
		select id, user, host, db, command, time, state, info
		from information_schema.processlist
		where command != 'Sleep'
		order by time desc;
		```
	- 查询执行时间超过2分钟的线程，然后拼接成 kill 语句。复制出来手动运行

		```sql
        -- kill 15667;
        -- 生成查杀sql
		select concat('kill ', id, ';')
		from information_schema.processlist
		where command != 'Sleep' and info like 'SELECT%'
		and time > 2*60
		order by time desc;
		```
- MySQL出现`Waiting for table metadata lock`的原因以及解决方法。**常出现在执行alter table的语句，如修改表结构的过程中(线上风险较高)** [^1]
	- `show processlist;` 长事物运行，阻塞DDL，继而阻塞所有同表的后续操作。(`kill #id`)
	- `select * from information_schema.innodb_trx;` 未提交事物，阻塞DDL (`kill #trx_mysql_thread_id`)
	- 查询到上述情况线程ID进行查杀
- `show open tables where in_use > 0;` 查看正在使用的表(锁表)

### Sqlserver

```sql
-- 查看sql耗时情况，根据平均耗时降序排列
SELECT creation_time  N'语句编译时间'
        ,last_execution_time  N'上次执行时间'
        ,total_physical_reads N'物理读取总次数'
        ,total_logical_reads/execution_count N'每次逻辑读次数'
        ,total_logical_reads  N'逻辑读取总次数'
        ,total_logical_writes N'逻辑写入总次数'
        ,execution_count  N'执行次数'
        ,total_worker_time/1000 N'所用的CPU总时间ms'
        ,total_elapsed_time/1000  N'总花费时间ms'
        ,(total_elapsed_time / execution_count)/1000  N'平均时间ms'
        ,SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
         ((CASE statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
          ELSE qs.statement_end_offset END
            - qs.statement_start_offset)/2) + 1) N'执行语句'
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
where SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
         ((CASE statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
          ELSE qs.statement_end_offset END
            - qs.statement_start_offset)/2) + 1) not like '%fetch%'
ORDER BY  total_elapsed_time / execution_count DESC;

-- 查看运行中的sql，根据耗时降序排列
SELECT DISTINCT
    SUBSTRING(qt.TEXT, (er.statement_start_offset/2)+1, ((CASE er.statement_end_offset WHEN -1 THEN DATALENGTH(qt.TEXT) ELSE er.statement_end_offset END - er.statement_start_offset)/2)+1) AS query_sql,
    er.session_id AS pid,
    er.status AS status,
    er.command AS command,
    sp.hostname AS hostname,
    DB_NAME(sp.dbid) AS db_name,
    sp.program_name AS program_name,
    er.cpu_time AS cpu_time,
    er.total_elapsed_time AS cost_time
FROM sys.sysprocesses AS sp LEFT JOIN sys.dm_exec_requests AS er ON sp.spid = er.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
WHERE 1 = CASE WHEN er.status IN ('RUNNABLE', 'SUSPENDED', 'RUNNING') THEN 1 WHEN er.status = 'SLEEPING' AND sp.open_tran  > 0 THEN 1 ELSE 0 END
AND er.command = 'SELECT'
ORDER BY er.total_elapsed_time DESC;

-- kill pid 杀掉对应查询session
kill <pid>
```

## JVM调优实践及相关案例

- 参考[jvm.md#调优实践](/_posts/java/jvm.md#调优实践)

## JVM致命错误日志(hs_err_xxx-pid.log)

- 当JVM发生致命错误导致崩溃时，会生成一个hs_err_pid_xxx.log这样的文件，该文件包含了导致 JVM crash 的重要信息
- 该文件默认生成在工作目录下的，可通过JVM参数指定`-XX:ErrorFile=/var/log/hs_err_pid<pid>.log`
- 日志分析 [^5]
    - 此处由于java的Java_java_util_zip_Deflater_deflateBytes(相关的还有Java_java_util_zip-xxx等方法)调用了系统libzip的相关方导致。由java堆栈可以看出在渲染FTL时，tomcat会进行文件压缩再返回给用户，从而调用了系统的libzip相关方法
    - 此案例解决办法：关闭tomcat压缩，使用nginx压缩。ofbiz关闭压缩方法：设置`framework/catalina/ofbiz-component.xml`文件参数`catalina-container.http-connector.compression=off`

```bash
# ##################### 日志头文件
# ### 这段内容主要简述了导致 JVM Crash 的原因。常见的原因有 JVM 自身的 bug，应用程序错误，JVM 参数，服务器资源不足，JNI 调用错误等
# A fatal error has been detected by the Java Runtime Environment:

# ### SIGSEGV 信号量；0x7 信号码；pc=0x00007f83d7bd6982 程序计数器的值；pid=8946 进程号；tid=140203658778368 线程号
# ### SIGBUS (0x7) 问题：https://confluence.atlassian.com/confkb/java-vm-dies-with-sigbus-0x7-when-temp-directory-is-full-on-linux-815584538.html
#  SIGBUS (0x7) at pc=0x00007f83d7bd6982, pid=8946, tid=140203658778368

# ### JRE 和 JVM 的版本信息
# JRE version: Java(TM) SE Runtime Environment (7.0_79-b15) (build 1.7.0_79-b15)
# Java VM: Java HotSpot(TM) 64-Bit Server VM (24.79-b02 mixed mode linux-amd64 compressed oops)

# ### 问题帧信息
    # C 表示帧类型为本地帧；j 解释的Java帧；V 虚拟机帧；v 虚拟机生成的存根栈帧；J 其他帧类型，包括编译后的Java帧
    # [libzip.so+0x4982]  newEntry+0x62 和程序计数器(pc)表达的含义一样，但是用的是本地so库+偏移量的方式
# Problematic frame:
# C  [libzip.so+0x4982]  newEntry+0x62

# ### **问题描述及建议**
# Failed to write core dump. Core dumps have been disabled. To enable core dumping, try "ulimit -c unlimited" before starting Java again
#
# If you would like to submit a bug report, please visit:
#   http://bugreport.java.com/bugreport/crash.jsp
# The crash happened outside the Java Virtual Machine in native code.
# See problematic frame for where to report the bug.
#

# ##################### 导致 crash 的线程信息
---------------  T H R E A D  ---------------
# ### 这部分内容包含出发 JVM 致命错误的线程详细信息和线程栈
    # 0x00007f83d8245800：出错的线程指针
    # JavaThread：**线程类型**，此时为Java线程，其他还有
        # JavaThread：Java线程
        # VMThread：JVM 的内部线程
        # CompilerThread：用来调用JITing，实时编译装卸class。通常，jvm会启动多个线程来处理这部分工作，线程名称后面的数字也会累加，例如：CompilerThread1
        # GCTaskThread：执行gc的线程
        # WatcherThread：JVM 周期性任务调度的线程，是一个单例对象
        # ConcurrentMarkSweepThread：jvm在进行CMS GC的时候，会创建一个该线程去进行GC，该线程被创建的同时会创建一个SurrogateLockerThread（简称SLT）线程并且启动它，SLT启动之后，处于等待阶段。CMST开始GC时，会发一个消息给SLT让它去获取Java层Reference对象的全局锁：Lock
    # http-bio-0.0.0.0-7100-exec-4：线程名称
    # _thread_in_native：**当前线程状态**，此时为在运行native代码。该描述还包含有： 
        # _thread_in_native：在运行native代码
        # _thread_uninitialized：线程还没有创建，它只在内存原因崩溃的时候才出现
        # _thread_new：线程已经被创建，但是还没有启动
        # _thread_in_native：线程正在执行本地代码，一般这种情况很可能是本地代码有问题
        # _thread_in_vm：线程正在执行虚拟机代码
        # _thread_in_Java：线程正在执行解释或者编译后的Java代码
        # _thread_blocked：线程处于阻塞状态
        # …_trans：以_trans结尾，线程正处于要切换到其它状态的中间状态
    # id=8964：线程ID
    # stack(0x00007f83b5371000,0x00007f83b5472000)：栈区间
Current thread (0x00007f83d8245800):  JavaThread "http-bio-0.0.0.0-7100-exec-4" [_thread_in_native, id=8964, stack(0x00007f83b5371000,0x00007f83b5472000)]

# ### 表示导致虚拟机终止的非预期的信号信息
siginfo:si_signo=SIGBUS: si_errno=0, si_code=2 (BUS_ADRERR), si_addr=0x00007f83de55e6e7

Registers:
RAX=0x00007f8380000bb0, RBX=0x00007f83d81fd6f0, RCX=0x00007f8380000ba0, RDX=0x00007f8380000bb0
RSP=0x00007f83b546e560, RBP=0x00007f83b546e5b0, RSI=0x00007f8380000038, RDI=0x0000000000000000
R8 =0x0000000000000003, R9 =0x0000000000000048, R10=0x00007f83d4c463b8, R11=0x00007f83ddaca710
R12=0x00007f83de55e6ca, R13=0x00007f8380000bb0, R14=0x00000000700eb698, R15=0x00007f83d81fd450
RIP=0x00007f83d7bd6982, EFLAGS=0x0000000000010206, CSGSFS=0x0000000000000033, ERR=0x0000000000000004
  TRAPNO=0x000000000000000e

# ### 栈顶程序计数器旁的操作码，它们可以被反汇编成系统崩溃前执行的指令
Top of Stack: (sp=0x00007f83b546e560)
0x00007f83b546e560:   0000000720000c90 00007f8300000000
0x00007f83b546e570:   00007f83b546e5f0 00007f83dd2b138c
0x00007f83b546e580:   00007f8380000bb0 00007f83d81fd6f0
0x00007f83b546e590:   00007f83d81fd450 00007f83d87502f0
# ...

Instructions: (pc=0x00007f83d7bd6982)
0x00007f83d7bd6962:   00 48 c7 40 28 00 00 00 00 41 80 7f 30 00 0f 84
0x00007f83d7bd6972:   8a 02 00 00 4c 8b 63 08 4d 2b 67 28 4d 03 67 18
0x00007f83d7bd6982:   41 0f b6 5c 24 1d 41 0f b6 44 24 1c c1 e3 08 09
0x00007f83d7bd6992:   c3 41 0f b6 44 24 1e 88 45 bd 41 0f b6 54 24 20 

Register to memory mapping:

RAX=0x00007f8380000bb0 is an unknown value
RBX=0x00007f83d81fd6f0 is an unknown value
RCX=0x00007f8380000ba0 is an unknown value
RDX=0x00007f8380000bb0 is an unknown value
RSP=0x00007f83b546e560 is pointing into the stack for thread: 0x00007f83d8245800
# ...

# ### 线程栈信息。包含了地址、栈顶、栈计数器和线程尚未使用的栈信息。到这里就基本上已经确定了问题所在原因了
# 此处由于java的Java_java_util_zip_Deflater_deflateBytes(相关的还有Java_java_util_zip-xxx等方法)调用了系统libzip的相关方导致。由java堆栈可以看出在渲染FTL时，tomcat会进行文件压缩再返回给用户，从而调用了系统的libzip相关方法。解决办法：关闭tomcat压缩，使用nginx压缩
# 额外参考：https://bugs.openjdk.java.net/browse/JDK-8175970
Stack: [0x00007f83b5371000,0x00007f83b5472000],  sp=0x00007f83b546e560,  free space=1013k
Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
C  [libzip.so+0x1001f]  _tr_stored_block+0x14f
C  [libzip.so+0x10b37]  _tr_flush_block+0x117
C  [libzip.so+0x8b90]  deflate_stored+0x1a0
C  [libzip.so+0x7433]  deflate+0x163
C  [libzip.so+0x3049]  Java_java_util_zip_Deflater_deflateBytes+0x269
J 2783  java.util.zip.Deflater.deflateBytes(J[BIII)I (0 bytes) @ 0x00007fc3e991586d [0x00007fc3e99157a0+0xcd]

Java frames: (J=compiled Java code, j=interpreted, Vv=VM code)
J 2783  java.util.zip.Deflater.deflateBytes(J[BIII)I (0 bytes) @ 0x00007fc3e99157f3 [0x00007fc3e99157a0+0x53]
J 2784 C2 java.util.zip.Deflater.deflate([BII)I (9 bytes) @ 0x00007fc3e99ad56c [0x00007fc3e99ad480+0xec]
J 2877 C2 org.apache.coyote.http11.filters.FlushableGZIPOutputStream.deflate()V (40 bytes) @ 0x00007fc3e99f29b0 [0x00007fc3e99f2920+0x90]
J 2902 C2 java.util.zip.DeflaterOutputStream.write([BII)V (88 bytes) @ 0x00007fc3e9a2ee78 [0x00007fc3e9a2ec20+0x258]
J 4548 C2 org.apache.coyote.http11.filters.FlushableGZIPOutputStream.flushLastByte()V (27 bytes) @ 0x00007fc3ea07fc50 [0x00007fc3ea07fba0+0xb0]
j  org.apache.coyote.http11.filters.FlushableGZIPOutputStream.flush()V+26
J 4521 C2 org.apache.coyote.http11.AbstractOutputBuffer.flush()V (105 bytes) @ 0x00007fc3ea06b5d4 [0x00007fc3ea06b3c0+0x214]
J 2837 C2 org.apache.coyote.http11.AbstractHttp11Processor.action(Lorg/apache/coyote/ActionCode;Ljava/lang/Object;)V (602 bytes) @ 0x00007fc3e981a3e8 [0x00007fc3e981a160+0x288]
J 4951 C2 org.apache.catalina.connector.OutputBuffer.doFlush(Z)V (123 bytes) @ 0x00007fc3ea1b9e24 [0x00007fc3ea1b9be0+0x244]
j  org.apache.catalina.connector.OutputBuffer.flush()V+2
j  org.apache.catalina.connector.CoyoteWriter.flush()V+12
j  freemarker.core.Environment.process()V+45
j  org.ofbiz.base.util.template.FreeMarkerWorker.renderTemplate(Lfreemarker/template/Template;Ljava/util/Map;Ljava/lang/Appendable;)Lfreemarker/core/Environment;+25
j  org.ofbiz.widget.screen.HtmlWidget.renderHtmlTemplate(Ljava/lang/Appendable;Lorg/ofbiz/base/util/string/FlexibleStringExpander;Ljava/util/Map;)V+109
# ...
J 5676 C2 org.apache.tomcat.util.net.JIoEndpoint$SocketProcessor.run()V (608 bytes) @ 0x00007fc3ea590864 [0x00007fc3ea590740+0x124]
J 5126 C2 java.util.concurrent.ThreadPoolExecutor.runWorker(Ljava/util/concurrent/ThreadPoolExecutor$Worker;)V (225 bytes) @ 0x00007fc3ea2d12a8 [0x00007fc3ea2d1000+0x2a8]
j  java.util.concurrent.ThreadPoolExecutor$Worker.run()V+5
j  org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run()V+4
j  java.lang.Thread.run()V+11
v  ~StubRoutines::call_stub

# ##################### 所有线程信息
---------------  P R O C E S S  ---------------

Java Threads: ( => current thread )
# ...
  0x00007f83d865c800 JavaThread "AsyncAppender-async" daemon [_thread_blocked, id=8968, stack(0x00007f83b4bd8000,0x00007f83b4cd9000)]
=>0x00007f83d8245800 JavaThread "OFBiz-AdminPortThread" [_thread_in_native, id=8964, stack(0x00007f83b5371000,0x00007f83b5472000)]
  0x00007f83d81ef000 JavaThread "Service Thread" daemon [_thread_blocked, id=8962, stack(0x00007f83b5c1e000,0x00007f83b5d1f000)]
  0x00007f83d81ec800 JavaThread "C2 CompilerThread1" daemon [_thread_blocked, id=8961, stack(0x00007f83b5d1f000,0x00007f83b5e20000)]
  0x00007f83d81e9800 JavaThread "C2 CompilerThread0" daemon [_thread_blocked, id=8960, stack(0x00007f83b5e20000,0x00007f83b5f21000)]
  0x00007f83d81e7000 JavaThread "Signal Dispatcher" daemon [_thread_blocked, id=8959, stack(0x00007f83b5f21000,0x00007f83b6022000)]
  0x00007f83d81bf000 JavaThread "Finalizer" daemon [_thread_blocked, id=8958, stack(0x00007f83b6022000,0x00007f83b6123000)]
  0x00007f83d81bd000 JavaThread "Reference Handler" daemon [_thread_blocked, id=8957, stack(0x00007f83b6123000,0x00007f83b6224000)]
  0x00007f1fdc002000 JavaThread "http-bio-0.0.0.0-7100-exec-2" daemon [_thread_blocked, id=3346, stack(0x00007f20b19dc000,0x00007f20b1add000)]

Other Threads:
  0x00007f83d81b8800 VMThread [stack: 0x00007f83b6224000,0x00007f83b6325000] [id=8956]
  0x00007f83d81f9800 WatcherThread [stack: 0x00007f83b5b1d000,0x00007f83b5c1e000] [id=8963]

# ##################### 安全点和锁信息
# ### 虚拟机状态
    # not at safepoint：表示正常运行 
    # at safepoint：所有线程都因为虚拟机等待状态而阻塞，等待一个虚拟机操作完成； 
    # synchronizing：一个特殊的虚拟机操作，要求虚拟机内的其它线程保持等待状态。
VM state:not at safepoint (normal execution)

# ### 虚拟机的 Mutex 和 Monitor目前没有被线程持有。Mutex 是虚拟机内部的锁，而 Monitor 则关联到了 Java 对象
VM Mutex/Monitor currently owned by a thread: None

# ##################### 堆信息
# ### 新生代、老年代、元空间
Heap
 PSYoungGen      total 1037824K, used 49661K [0x00000007c0000000, 0x0000000800000000, 0x0000000800000000)
  eden space 1026560K, 4% used [0x00000007c0000000,0x00000007c307f5d8,0x00000007fea80000)
  from space 11264K, 0% used [0x00000007ff500000,0x00000007ff500000,0x0000000800000000)
  to   space 10752K, 0% used [0x00000007fea80000,0x00000007fea80000,0x00000007ff500000)
 ParOldGen       total 2097152K, used 85879K [0x0000000740000000, 0x00000007c0000000, 0x00000007c0000000)
  object space 2097152K, 4% used [0x0000000740000000,0x00000007453dde60,0x00000007c0000000)
 PSPermGen       total 57856K, used 57438K [0x0000000720000000, 0x0000000723880000, 0x0000000740000000)
  object space 57856K, 99% used [0x0000000720000000,0x0000000723817828,0x0000000723880000)

# ### Card table表示一种卡表，是 jvm 维护的一种数据结构，用于记录更改对象时的引用，以便 gc 时遍历更少的 table 和 root
Card table byte_map: [0x00007f83d44d1000,0x00007f83d4bd2000] byte_map_base: 0x00007f83d0bd1000

Polling page: 0x00007f83de560000

# ##################### 本地代码缓存
Code Cache  [0x00007f83d4bd2000, 0x00007f83d5b92000, 0x00007f83d7bd2000)
 total_blobs=4442 nmethods=3636 adapters=757 free_code_cache=33218Kb largest_free_block=33837056

# ##################### 编译事件(记录10次编译事件)
Compilation events (10 events):
Event: 524935.243 Thread 0x00007f83d81e9800 4136   !         unilog.yard.base.maintain.MaintainService::getPersonCardMap (141 bytes)
Event: 524935.281 Thread 0x00007f83d81e9800 nmethod 4136 0x00007f83d5b5fe10 code [0x00007f83d5b60160, 0x00007f83d5b61aa0]
Event: 524975.808 Thread 0x00007f83d81ec800 4137             com.sun.crypto.provider.CipherCore::doFinal (609 bytes)
# ...

# ##################### GC日志(记录10次)
GC Heap History (10 events):
Event: 586892.067 GC heap before
{Heap before GC invocations=358 (full 164):
 PSYoungGen      total 1037312K, used 6382K [0x00000007c0000000, 0x0000000800000000, 0x0000000800000000)
  eden space 1025536K, 0% used [0x00000007c0000000,0x00000007c0000000,0x00000007fe980000)
  from space 11776K, 54% used [0x00000007ff480000,0x00000007ffabbb10,0x0000000800000000)
  to   space 11264K, 0% used [0x00000007fe980000,0x00000007fe980000,0x00000007ff480000)
 ParOldGen       total 2097152K, used 85865K [0x0000000740000000, 0x00000007c0000000, 0x00000007c0000000)
  object space 2097152K, 4% used [0x0000000740000000,0x00000007453da4c0,0x00000007c0000000)
 PSPermGen       total 57856K, used 57462K [0x0000000720000000, 0x0000000723880000, 0x0000000740000000)
  object space 57856K, 99% used [0x0000000720000000,0x000000072381dba8,0x0000000723880000)
Event: 586892.180 GC heap after
Heap after GC invocations=358 (full 164):
 PSYoungGen      total 1037312K, used 0K [0x00000007c0000000, 0x0000000800000000, 0x0000000800000000)
  eden space 1025536K, 0% used [0x00000007c0000000,0x00000007c0000000,0x00000007fe980000)
  from space 11776K, 0% used [0x00000007ff480000,0x00000007ff480000,0x0000000800000000)
  to   space 11264K, 0% used [0x00000007fe980000,0x00000007fe980000,0x00000007ff480000)
 ParOldGen       total 2097152K, used 85875K [0x0000000740000000, 0x00000007c0000000, 0x00000007c0000000)
  object space 2097152K, 4% used [0x0000000740000000,0x00000007453dcfe8,0x00000007c0000000)
 PSPermGen       total 57856K, used 57398K [0x0000000720000000, 0x0000000723880000, 0x0000000740000000)
  object space 57856K, 99% used [0x0000000720000000,0x000000072380da38,0x0000000723880000)
}
# ...

Deoptimization events (10 events):
Event: 362767.698 Thread 0x00007f82f8015000 Uncommon trap: reason=array_check action=maybe_recompile pc=0x00007f83d5a23df4 method=java.util.ComparableTimSort.mergeHi(IIII)V @ 91
Event: 373412.087 Thread 0x00007f82f800b800 Uncommon trap: reason=class_check action=maybe_recompile pc=0x00007f83d564745c method=java.util.regex.Pattern$BnM.match(Ljava/util/regex/Matcher;ILjava/lang/CharSequence;)Z @ 111
# ...

Internal exceptions (10 events):
Event: 589300.208 Thread 0x00007f832800b000 Threw 0x00000007ca5f9668 at /HUDSON/workspace/7u-2-build-linux-amd64/jdk7u79/2331/hotspot/src/share/vm/prims/jvm.cpp:1304
Event: 590774.327 Thread 0x00007f830c009000 Threw 0x00000007c0646ca8 at /HUDSON/workspace/7u-2-build-linux-amd64/jdk7u79/2331/hotspot/src/share/vm/prims/jni.cpp:1632
# ...

Events (10 events):
Event: 595874.342 Thread 0x00007f8320009800 Thread added: 0x00007f8320009800
Event: 595874.342 Executing VM operation: RevokeBias
# ...

# ##################### jvm 内存映射
# 这些信息是虚拟机崩溃时的虚拟内存列表区域。它可以告诉你崩溃原因时哪些类库正在被使用，位置在哪里，还有堆栈和守护页信息。
    # 00400000-00401000：内存区域
    # r-xp：权限，r/w/x/p/s分别表示读/写/执行/私有/共享
    # 00000000：文件内的偏移量
    # fd:01：文件位置的majorID和minorID
    # 133127：索引节点号
    # /root/jdk1.7.0_79/bin/java：文件位置
Dynamic libraries:
00400000-00401000 r-xp 00000000 fd:01 133127                             /root/jdk1.7.0_79/bin/java
00600000-00601000 rw-p 00000000 fd:01 133127                             /root/jdk1.7.0_79/bin/java
00efb000-00f81000 rw-p 00000000 00:00 0                                  [heap]
720000000-723880000 rw-p 00000000 00:00 0 
# ...
7f83de55c000-7f83de55e000 r--s 00005000 fd:10 4984387                    /home/test/jvminspect.jar
7f83de55e000-7f83de55f000 r--s 00015000 fd:10 4984388                    /home/test/ofbiz.jar
# ...
ffffffffff600000-ffffffffff601000 r-xp 00000000 00:00 0                  [vsyscall]

# ##################### jvm 启动参数
VM Arguments:
jvm_args: -Xms3g -Xmx3g -Xmn1g -XX:MaxPermSize=512m -Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/jvmlogs/ -Dyard.profiles=prod 
java_command: ofbiz.jar
Launcher Type: SUN_STANDARD

Environment Variables:
JAVA_HOME=/root/jdk1.7.0_79
CLASSPATH=.:/root/jdk1.7.0_79/lib:/root/jdk1.7.0_79/jre/lib
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/jdk1.7.0_79/bin:/root/jdk1.7.0_79/jre/bin:/root/bin
SHELL=/bin/bash

Signal Handlers:
SIGSEGV: [libjvm.so+0x9a3bf0], sa_mask[0]=0x7ffbfeff, sa_flags=0x10000004
SIGBUS: [libjvm.so+0x9a3bf0], sa_mask[0]=0x7ffbfeff, sa_flags=0x10000004
# ...

# ##################### 系统信息
---------------  S Y S T E M  ---------------

OS:CentOS Linux release 7.2.1511 (Core) 

uname:Linux 3.10.0-327.36.3.el7.x86_64 #1 SMP Mon Oct 24 16:09:20 UTC 2016 x86_64
libc:glibc 2.17 NPTL 2.17 
rlimit: STACK 8192k, CORE 0k, NPROC 63475, NOFILE 100002, AS infinity
load average:0.16 0.09 0.08

/proc/meminfo:
MemTotal:       16267884 kB
MemFree:          977764 kB
# ...

CPU:total 8 (6 cores per cpu, 1 threads per core) family 6 model 63 stepping 2, cmov, cx8, fxsr, mmx, sse, sse2, sse3, ssse3, sse4.1, sse4.2, popcnt, avx, aes, tsc

/proc/cpuinfo:
processor	: 0
vendor_id	: GenuineIntel
# ...


Memory: 4k page, physical 16267884k(977764k free), swap 0k(0k free)

vm_info: Java HotSpot(TM) 64-Bit Server VM (24.79-b02) for linux-amd64 JRE (1.7.0_79-b15), built on Apr 10 2015 11:34:48 by "java_re" with gcc 4.3.0 20080428 (Red Hat 4.3.0-8)

time: Thu Sep  5 12:53:10 2019
elapsed time: 596066 seconds
```



---

参考文章

[^1]: http://www.blogjava.net/hankchen/archive/2012/05/09/377738.html (线上应用故障排查系列)
[^2]: http://www.blogjava.net/hankchen/archive/2012/05/09/377736.html (线上应用故障排查之二：高内存占用)
[^3]: https://www.jianshu.com/p/3667157d63bb (记一次线上Java程序导致服务器CPU占用率过高的问题排除过程)
[^4]: https://blog.csdn.net/xuexiaodong009/article/details/74451412 (oracle数据库CPU特别高的解决方法)
[^5]: https://blog.csdn.net/chenssy/article/details/78271744
