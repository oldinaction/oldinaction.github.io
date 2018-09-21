---
layout: "post"
title: "Java应用CPU和内存异常分析"
date: "2018-03-13 13:35"
categories: java
tags: [CPU, 内存, 运维, oracle, ofbiz]
---

## 简介

- java应用常见故障：**高CPU占用**、**高内存占用**、**高I/O占用**(包括磁盘I/O、网络I/O、数据库I/O等)
- 高CPU常见场景：死循环(如while导致的较多)、高内存导致
    - 高内存占用也会引起高CPU占用：内存溢出后，java的GC便会运行非常频繁，从而导致高CPU
- 高内存常见场景：List集合数据量过大(常见从数据库获取大量数据，而没有进行分页获取) [^2]
    - `java.lang.OutOfMemoryError: PermGen space`，原因可能为
        - 程序启动需要加载大量的第三方jar包。例如：在一个Tomcat下部署了太多的应用
    - `java.lang.OutOfMemoryError: Java heap space`，原因可能为
        - Java虚拟机的堆内存设置不够，可以通过参数-Xms、-Xmx来调整。
        - 代码中创建了大量大对象，并且长时间不能被垃圾收集器收集（存在被引用）
    - 在Java虚拟机中，内存分为三个代
        - 新生代New：新建的对象都存放这里
        - 老生代Old：存放从新生代New中迁移过来的生命周期较久的对象。新生代New和老生代Old共同组成了堆内存
        - 永久代Perm：是非堆内存的组成部分。主要存放加载的Class类级对象如class本身，method，field等等

## 应用服务器故障

### 相关命令介绍

```bash
## 1.查看linux运行状态(htop工具显示更强大)：如8核则CPU可能达到800%
# Windows可以使用ProcessExplorer.exe查看进程和线程信息
top

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
jstack <pid> | grep `printf "%x\n" <tid>` -A 30
# 获取thread dump到文件
jstack <pid> > jstack.out

## 4.Java的jmap命令：显示一个进程下具体线程的内存占用情况
# 可以查看当前Java进程创建的活跃对象数目和占用内存大小（此处按照大小查询前100个对象）；或者保存到文件（jmap -histo:live <pid> > /home/jmap.out）
jmap -histo:live <pid> | head -n 100
# 获取heap dump，方便用专门的内存分析工具（例如：MAT）来分析
# （1）jmap命令获取：执行时JVM是暂停服务的，所以对线上的运行会产生影响（生成文件大小和程序占用内存差不多；2G大概暂停10秒钟，实际测试系统可能会暂停无法访问）
jmap -F -dump:live,format=b,file=/home/dump.hprof <pid>

## 5.项目启动添加jvm参数获取(不能实时获取)
-XX:+HeapDumpOnOutOfMemoryError # 出现 OOME 时生成堆 dump
-XX:HeapDumpPath=/home/jvmlogs # 生成堆文件的文件夹（需要先手动创建此文件夹）
```

### MAT工具使用/实例分析

- MAT(Memory Analyzer Tool)：根据分析dump文件从而分析堆内存使用情况，[下载](http://www.eclipse.org/mat/downloads.php)
- 运行jar包时加参数如：`java -jar test.jar -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/jvmlogs`，/home/jvmlogs为程序出现内存溢出时保存堆栈信息的文件（需要提前建好）
- MAT打开类似于`java_pid11457.hprof`的堆栈文件（File - Open Heap Dump），需要设置MAT运行的最大内存足够大(设置`MemoryAnalyzer.ini`)，打开效果如下(`Leak Suspects Report`泄漏疑点报告)

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

- 内存占用达到3G，下载的dump文件确只有400M左右(生成dump文件耗时1分钟，生成dump文件时应用无法访问)，并未发现内存溢出现象

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

- jvisualvm.exe、jconsole.exe类似，下面以jvisualvm.exe为例
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
- 查看数据库sql运行占用CPU时间较长的会话信息，并kill此会话

    ```sql
    select sid, serial#, cpu_time, executions, round(cpu_time/executions/1000, 2) peer_secondes, sql_text, sql_fulltext
    from v$sql
    join v$session on v$sql.sql_id = v$session.sql_id
    where cpu_time > 20000
    order by round(cpu_time/executions/1000, 2) desc;

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
        (select decode(sql_hash_value, 0, prev_hash_value, sql_hash_value),
                decode(sql_hash_value, 0, prev_sql_addr, sql_address)
            from v$session b
            where b.paddr =
                (select addr from v$process c where c.spid = '&pid'))
    order by piece asc
    ```
- 查看数据库sql运行占用时间较长的sql语句

    ```sql
    select *
    from (select sql_text, sql_fulltext, sql_id, cpu_time from v$sql order by cpu_time desc)
    where rownum <= 10
    order by rownum asc;
    ```
- 常用查询

    ```sql
    -- 列出数据库里每张表的记录条数
    select t.table_name,t.num_rows from user_tables t ORDER BY NUM_ROWS DESC;

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




---

参考文章

[^1]: http://www.blogjava.net/hankchen/archive/2012/05/09/377738.html (线上应用故障排查系列)
[^2]: http://www.blogjava.net/hankchen/archive/2012/05/09/377736.html (线上应用故障排查之二：高内存占用)
[^3]: https://www.jianshu.com/p/3667157d63bb (记一次线上Java程序导致服务器CPU占用率过高的问题排除过程)
[^4]: https://blog.csdn.net/xuexiaodong009/article/details/74451412 (oracle数据库CPU特别高的解决方法)
