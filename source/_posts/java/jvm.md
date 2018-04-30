---
layout: "post"
title: "jvm"
date: "2017-01-20 13:07"
categories: [java]
tags: [jvm]
---


## jvm常用配置

- [oracle推荐jvm配置](http://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html)

 配置参数|	功能
 ---------|----------
-Xms|	初始堆大小。如：-Xms256m
-Xmx|	最大堆大小。如：-Xmx512m
-Xmn|	新生代大小。通常为 Xmx 的 1/3 或 1/4。新生代 = Eden + 2 个 Survivor 空间。实际可用空间为 = Eden + 1 个 Survivor，即 90%
-Xss|	JDK1.5+ 每个线程堆栈大小为 1M，一般来说如果栈不是很深的话， 1M 是绝对够用了的。
-XX:NewRatio|	新生代与老年代的比例，如 –XX:NewRatio=2，则新生代占整个堆空间的1/3，老年代占2/3
-XX:SurvivorRatio|	新生代中 Eden 与 Survivor 的比值。默认值为 8。即 Eden 占新生代空间的 8/10，另外两个 Survivor 各占 1/10
-XX:PermSize|	永久代(方法区)的初始大小
-XX:MaxPermSize|	永久代(方法区)的最大值
-XX:+PrintGCDetails|	打印 GC 信息
-XX:+HeapDumpOnOutOfMemoryError|	让虚拟机在发生内存溢出时 Dump 出当前的内存堆转储快照，以便分析用