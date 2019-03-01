---
layout: "post"
title: "jvm"
date: "2017-01-20 13:07"
categories: [java]
tags: [jvm]
---


- http://www.cnblogs.com/duanxz/p/3613947.html
- JDK1.6常量池放在方法区(也即是Perm空间), JDK 1.7 和 1.8 将字符串常量由永久代转移到堆中，并且JDK 1.8中已经不存在永久代的结论
- 元空间的本质和永久代类似，都是对JVM规范中方法区的实现。不过元空间与永久代之间最大的区别在于：元空间并不在虚拟机中，而是使用本地内存。因此，默认情况下，元空间的大小仅受本地内存限制，但可以通过参数来指定元空间的大小

## jvm常用配置

- [oracle推荐jvm配置](http://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html)

 配置参数|	功能
 ---------|----------
-Xms|	**初始堆大小**。如：-Xms256m
-Xmx|	**最大堆大小**。如：-Xmx512m
-Xmn|	新生代大小。通常为 Xmx 的 1/3 或 1/4。新生代 = Eden + 2 个 Survivor 空间。实际可用空间为 = Eden + 1 个 Survivor，即 90%
-Xss|	JDK1.5+ 每个线程堆栈大小为 1M，一般来说如果栈不是很深的话， 1M 是绝对够用了的。
-XX:NewRatio|	新生代与老年代的比例，如 –XX:NewRatio=2，则新生代占整个堆空间的1/3，老年代占2/3
-XX:SurvivorRatio|	新生代中 Eden 与 Survivor 的比值。默认值为 8。即 Eden 占新生代空间的 8/10，另外两个 Survivor 各占 1/10
-XX:PermSize|	永久代/方法区/非堆区的初始大小(默认64M)。如：-XX:PermSize=256m。**JDK8移除了此参数**
-XX:MaxPermSize|	永久代/方法区/非堆区的最大值。如：-XX:MaxPermSize=512m。JDK8移除了此参数
-XX:+PrintGCDetails|	打印 GC 信息
-XX:+HeapDumpOnOutOfMemoryError|    **让虚拟机在发生内存溢出时 Dump 出当前的内存堆转储快照，以便分析用**
-XX:HeapDumpPath=/home/jvmlogs|     **生成堆文件的文件夹（需要先手动创建/home/jvmlogs文件夹）**

- 自定义jvm参数

```java
// 格式
// -D<name>=<value>
// System.getProperty(<name>)

// 示例
java -Dtest.name=aezocn -jar app.jar // 启动添加参数
System.getProperty("test.name") // 程序中取值，无此参数则为null
```

## jvm配置位置

- `tomcat`：修改`%TOMCAT_HOME%/bin/catalina.bat`或`%TOMCAT_HOME%/bin/catalina.sh`中的`JAVA_OPTS`，在`echo "Using CATALINA_BASE:   $CATALINA_BASE"`上面加入以下行：`JAVA_OPTS="-server -Xms256m -Xmx512m`(启动时运行的startup.bat/startup.sh，其内部调用catalina.bat)
- `weblogic`：修改`bea/weblogic/common中CommEnv`中参数
- `springboot`：可直接加在java命令后面，如`java -jar xxx.jar -Xms256`
- `idea`：Run/Debug Configruations中修改VM Options(单独运行tomcat或者springboot项目都如此)
- `eclipse`：修改eclipse中tomcat的配置

## 常用配置推荐

- 启动脚本

```bash
## 1.简单配置
APP_HOME="$( cd -P "$( dirname "$0" )" && pwd )"/..
( cd "$APP_HOME" && java -Xmx512M -jar xxx.jar --spring.profiles.active=prod )

## 2.基于bash的VM参数
APP_HOME="$( cd -P "$( dirname "$0" )" && pwd )"/..
#MEMIF="-Xms3g -Xmx3g -Xmn1g -XX:MaxPermSize=512m -Dfile.encoding=UTF-8"
OOME="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/jvmlogs/"
#IPADDR=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'` #automatic IP address for linux（内网地址）
#RMIIF="-Djava.rmi.server.hostname=$IPADDR"
#JMX="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=33333 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
#DEBUG="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8091"
VMARGS="$MEMIF $OOME $RMIIF $JMX $DEBUG"
( cd "$APP_HOME" && java $VMARGS -jar xxx.jar --spring.profiles.active=prod )

## 3.1G内存机器推荐配置
-Xms128M
-Xmx512M
-XX:PermSize=256M
-XX:MaxPermSize=512M
# 监控内存溢出
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/home/jvmlogs
# 开启JMX远程连接
-Djava.rmi.server.hostname=192.168.1.1
-Dcom.sun.management.jmxremote=true
-Dcom.sun.management.jmxremote.port=8091
-Dcom.sun.management.jmxremote.ssl=false 
-Dcom.sun.management.jmxremote.authenticate=false
# 如果authenticate为true时需要下面的两个配置。在JAVA_HOME/jre/lib/management下有模板。文件权限 chmod 600 jmxremote.password
#-Dcom.sun.management.jmxremote.password.file=/usr/java/default/jre/lib/management/jmxremote.password
#-Dcom.sun.management.jmxremote.access.file=/usr/java/default/jre/lib/management/jmxremote.access
```

- 自定义服务

```bash
[Unit]
Description=ASF
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/var/run/asf.pid
ExecStart=/home/amass/project/java/asf/asf.sh
ExecReload=/home/amass/project/java/asf/asf.sh -s reload
ExecStop=/home/amass/project/java/asf/asf.sh -s stop
[Install]
WantedBy=multi-user.target
```



