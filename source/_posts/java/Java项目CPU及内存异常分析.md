---
layout: "post"
title: "Java项目CPU及内存异常分析"
date: "2018-03-13 13:35"
categories: java
tags: [CPU, 内存, 运维, ofbiz]
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

## 相关命令介绍

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
# （1）jmap命令获取：执行时JVM是暂停服务的，所以对线上的运行会产生影响（生成文件大小和程序占用内存差不多；2G大概暂停10秒钟）
jmap -dump:live,format=b,file=/home/dump.hprof <pid>
# （2）项目启动添加参数获取(不能实时获取)
-XX:+HeapDumpOnOutOfMemoryError # 出现 OOME 时生成堆 dump:
-XX:HeapDumpPath=/home/jvmlogs/ # 生成堆文件地址
```

## MAT工具使用

- MAT(Memory Analyzer Tool)：根据分析dump文件从而分析堆内存使用情况，[下载](http://www.eclipse.org/mat/downloads.php)

- https://www.cnblogs.com/moonandstar08/p/5625164.html
- http://blog.csdn.net/aaa2832/article/details/19419679

## OFBiz项目案例分析

> 案例介绍：此问题主要是ofbiz在清理历史任务时，任务数据过大导致内存溢出，从而CPU飙升，最终服务器时常宕机。

- `htop`查看情况如下

可以看到其中PID=2273的进程CPU占用到达710%(服务器为8核)，内存占用22%(服务器为16G*0.22=3.52G，jvm参数设置的内存大小为3G)，其中线程运行时间达到5h29m。以上数据说明程序运行存在问题

![htop](/data/images/java/ofbiz-cpu.png)

- `ps -mp 2273 -o THREAD,tid,time,rss,size,%mem` 查看此进程下线程运行情况：实际中发现有7个进场运行时间达到几十分钟，且CPU和内存占用均非常高。(其中2个是ofbiz拉取历史任务进行清理的进程，5个为GC进行垃圾回收的进程)
- `jstack 2273 | grep `printf "%x\n" 2413` -A 40` 查看2273进程下2413线程的堆栈信息如下(或者输出到文件进行查看)

可以看到线程有以下调用信息`org.ofbiz.service.job.PurgeJob.exec(PurgeJob.java:55)`，如是可以去查看PurgeJob的源码。(当然应该多次查看此线程的堆栈，查看一次可能存在偶发性)

![jstack](/data/images/java/ofbiz-purgejob-jstack.png)

- ofbiz的PurgeJob相关源码。详细可参考《ofbiz任务机制》

ofbiz任务机制有如下逻辑：当拉取任务线程为获取到需要执行的任务时，则进行历史任务数据(JobSandbox等表数据)清理工作，即获取当前时间4天(默认的purge-job-days)前完成或者取消的任务数据进行删除。

而此处是根据ofbiz实体引擎查询的历史数据放到一个EntityListIterator中进行遍历(查看源码可知本质并没有分页获取数据，而是将所有查询的数据放到ResultSet进行遍历)

由于本项目前期并没有太多的关注任务调用周期，从而导致大量任务堆积，并且不能及时清理。一定数量后，再次触发任务数据清理时就会从数据库获取大量数据到内存，从而内存移除，GC频繁清理，CPU飙升，服务器宕机。

![ofbiz-purgejob-src](/data/images/java/ofbiz-purgejob-src.png)

- MAT分析：从服务器下载dump文件使用MAT进行分析，发现也可发现上述情况

- 解决方案

由于个人觉得ofbiz任务机制不太好用，决定不去清理历史数据，而是手动定时清理(或绕过ofbiz定时去清理)。因此可以修改`/framework/service/config/serviceengine.xml`中`purge-job-days`的值。重新启动服务器(之前占用的内存无法及时清除，必须重启服务器)和项目一切正常



---

参考文章

[^1]: [线上应用故障排查系列](http://www.blogjava.net/hankchen/archive/2012/05/09/377738.html)
[^2]: [线上应用故障排查之二：高内存占用](http://www.blogjava.net/hankchen/archive/2012/05/09/377736.html)

