---
layout: "post"
title: "JVM"
date: "2017-01-20 13:07"
categories: [java]
tags: [jvm]
---

- http://www.cnblogs.com/duanxz/p/3613947.html
- JDK1.6常量池放在方法区(也即是Perm空间), JDK 1.7 和 1.8 将字符串常量由永久代转移到堆中，并且JDK 1.8中已经不存在永久代的结论
- 元空间的本质和永久代类似，都是对JVM规范中方法区的实现。不过元空间与永久代之间最大的区别在于：元空间并不在虚拟机中，而是使用本地内存。因此，默认情况下，元空间的大小仅受本地内存限制，但可以通过参数来指定元空间的大小


## 简介

- [JVM Specification](https://docs.oracle.com/javase/specs/jvms/se14/html/index.html)
- Java执行
    - x.java - javac - x.class
    - 将x.class加载到ClassLoader，并将一些java类库加载进来
    - 再通过字节码解释器或JIT即时编译器(一些常用的代码会自动编译成本地代码)
    - 调用执行引擎
- 只要是能编译成class文件的便可以在JVM上执行，如java、groovy、scale等100多种；而不同的操作系统Unix/Linux/Windows/Android会有不同的JVM实现
- JVM是一种规范，有不同的实现，如HostSpot(oracle官方)、OpenJDK(HostSpot的开源版本)、JcrocKit(被Oracle收购，合并到hostspot)、J9(IBM)、Microsoft VM、TaobaoVM、[azul zing](www.azul.com)

## Class File Format

- [The class File Format](https://docs.oracle.com/javase/specs/jvms/se14/html/jvms-4.html)
- class文件分析
    - 通过文本文件打开则是0101
        - 一般是通过16进制编辑器打开二进制文件进行观察，如使用notepad(HEX-Editor插件或Converter插件，选中文件ASCII->HEX)打开或idea安装BinEd插件查看16进制
    - 查看ByteCode字节码
        - `javap -v D:\smjava\jvm\classes\cn\aezo\jvm\c01_class\T1_HelloWorld.class` -v查看详细信息
        - 或使用idea字段功能 View - Show ByteCode(基于javap)
        - 或使用idea插件jclasslib查看(选中java类，在View菜单下会显示此工具)
- ClassFile结构

    ```java
    // 1个16进制数(0x1或0xC)对应4位二进制数，1个字节是8位(二进制数)，因此2个16进制数代表一个字节
    ClassFile {
        u4             magic; // 文件头信息 0xCAFEBABE，u4表示无符号的4个字节，下同
        u2             minor_version; // 此版本号
        u2             major_version; // 主版本号，JDK8为52
        u2             constant_pool_count; // 常量池个数
        cp_info        constant_pool[constant_pool_count-1]; // 常量池
        u2             access_flags; // 描述符，如ACC_PUBLIC(0x0001)/ACC_INTERFACE等
        u2             this_class;
        u2             super_class;
        u2             interfaces_count;
        u2             interfaces[interfaces_count];
        u2             fields_count;
        field_info     fields[fields_count];
        u2             methods_count;
        method_info    methods[methods_count];
        u2             attributes_count;
        attribute_info attributes[attributes_count];
    }
    ```
- 字段描述符解释
    - Ljava.lang.String(引用)、[(数组)、[[(二位数组)、J(Long)、Z(boolean)、B(byte)，其他同B基本以首字母开头
- 常量池标识
    - 1 CONSTANT_Utf8(1为Tag类型)
    - 3 CONSTANT_Integer
    - 7 CONSTANT_Class
    - 8 CONSTANT_String
    - ...
- [语句](https://docs.oracle.com/javase/specs/jvms/se14/html/jvms-4.html#jvms-4.10.1.9)，如
    - `aload, aload_<n>`
    - `invokespecial` 调用实例方法，对父类实例化的特殊处理
    - `return` 返回void

## 类加载过程

- 类加载过程
    - `Loading`
        - 将class加载到内存(一方面创建一个内存区域保存字节码，另一方面会创建一个Class对象指向此区域，之后使用此类需要通过此Class对象进行访问)
        - 双亲委派机制，见下文
        - [LazyLoading 五种情况](https://github.com/oldinaction/smjava/blob/master/jvm/src/main/java/cn/aezo/jvm/c02_classloader/T06_LazyLoading.java)
            - new getstatic putstatic invokestatic指令，访问final变量除外
            - java.lang.reflect对类进行反射调用时
            - 初始化子类的时候，父类首先初始化
            - 虚拟机启动时，被执行的主类必须初始化
            - 动态语言支持java.lang.invoke.MethodHandle解析的结果为REF_getstatic REF_putstatic REF_invokestatic的方法句柄时，该类必须初始化
        - 混合执行(默认)、编译执行、解释执行
            - 解释器(Bytecode Intepreter)、`JIT`(Just In-Time compiler) 编译执行
            - `-Xmixed` 设置混合模式，启动速度较快，对热点代码实行检测和编译。认为热点代码条件：`-XX:CompileThreshold=10000`
            - `-Xint` 使用解释执行模式，启动很快，执行相对慢
            - `-Xcomp` 使用编译执行模式，启动相对较慢，执行快
    - `Linking`
        - `Verification` 验证格式
        - `Preparation` 给静态变量赋默认值(如0/false)
            - 类加载：赋默认值 -> 赋初始值. [示例](https://github.com/oldinaction/smjava/blob/master/jvm/src/main/java/cn/aezo/jvm/c02_classloader/T08_ClassLoadingProcedure.java)
            - new对象(类似类加载)：申请内存 -> 赋默认值 -> 赋初始值
        - `Resolution` 解析
            - 将类、方法、属性等符号引用解析为直接引用，常量池中的各种符号引用解析为指针、偏移量等内存地址的直接引用
    - `Initializing` 给静态变量赋初始值
- 双亲委派机制(Loading时)

    ![jvm-类加载器](/data/images/java/jvm-类加载器.png)
    - 先从子到父查找缓存，再从父到子超找class文件并加载
    - 主要为了安全考虑。如不用双亲委派，则可能自己定义一个java.lang.String进行自定义加载
    - 加载过程(参考sun.misc.Launcher)
        - .class文件通过(自定义)ClassLoader#loadClass加载，先在(自定义)ClassLoader的缓存中查找是否有此类，有则返回结果，没有则让父加载器App进行缓存加载
        - 以此类推直到Bootstrap，如果Bootstrap在内存中找打了则返回，否则回过头让ExtClassLoader查找class文件并加载，找到则加载后返回结果，没找到则让下级Loader查找class文件并加载
        - 直到最后的(自定义)ClassLoader，如果还找到不class文件则返回Class Not Found
    - 自定义ClassLoader：继承自ClassLoader，并重写findClass方法
    - 打破双亲委派
        - 重写loadClass()。JDK1.2之前，自定义ClassLoader都必须重写loadClass()
        - 使用范畴
            - 热启动，热部署
            - osgi tomcat 都有自己的模块指定classloader(可以加载同一类库的不同版本)
    - ClassLoader相关代码：findInCache -> parent.loadClass -> findClass

    ```java
    // ClassLoader.java#loadClass
    protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
        synchronized (getClassLoadingLock(name)) {
            // First, check if the class has already been loaded
            // 由于下面执行了parent.loadClass，所以是先从子->父执行findLoadedClass(判断是否已经加载了)
            Class<?> c = findLoadedClass(name);
            if (c == null) {
                long t0 = System.nanoTime();
                try {
                    if (parent != null) {
                        c = parent.loadClass(name, false); // parent为final修饰的
                    } else {
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // ClassNotFoundException thrown if class not found
                    // from the non-null parent class loader
                }

                // 由于上面执行了parent.loadClass，所以是先从父->子执行findClass(查找class文件并加载)
                if (c == null) {
                    // If still not found, then invoke findClass in order
                    // to find the class.
                    long t1 = System.nanoTime();
                    c = findClass(name); // ClasssLoader中直接throw Excption了，需要子类自己实现(在各自负责的目录进行查找)。使用了模板方法的设计模式

                    // this is the defining class loader; record the stats
                    sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                    sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                    sun.misc.PerfCounter.getFindClasses().increment();
                }
            }
            if (resolve) {
                resolveClass(c);
            }
            return c;
        }
    }

    // URLClassLoader.java#findClass
    String path = name.replace('.', '/').concat(".class");
    Resource res = ucp.getResource(path, false);
    if (res != null) {
        try {
            return defineClass(name, res); // 通过defineClass进行加载
        } catch (IOException e) {
            throw new ClassNotFoundException(name, e);
        }
    } else {
        return null;
    }    
    ```


## Java内存模型







93 Java内存模型 地址

97 内存屏障与JVM指令 地址

102 Java运行时数据区和常用指令 地址

110 JVM调优必备理论知识-GC Collector-三色标记 地址

114 JVM调优实战 地址

119 JVM实战调优 地址

124 JVM实战调优 地址

128 垃圾回收算法串讲 地址

132 JVM常见参数总结 地址




## jvm常用配置

- [oracle推荐jvm配置(含默认值)](http://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html)

 配置参数|	版本|功能
 ---------| ---------|----------
-Xms||	**初始堆大小**。如：`-Xms512m`(如果资源充足也可把初始堆和最大堆设置成一致)
-Xmx||	**最大堆大小**。如：`-Xmx1g`
-XX:+PrintGCDetails||	打印 GC 信息
-XX:+HeapDumpOnOutOfMemoryError||    **让虚拟机在发生内存溢出时 Dump 出当前的内存堆转储快照，以便分析用**
-XX:HeapDumpPath=/home/jvmlogs| |    **生成堆文件的文件夹（需要先手动创建/home/jvmlogs文件夹）**
-XX:MaxMetaspaceSize=128m|  JDK8+| 元空间最大大小(类似-XX:MaxPermSize)
-XX:MetaspaceSize=128m| JDK8+| 元空间默认大小(类似-XX:PermSize)
-XX:MaxPermSize=64m|    JDK8-|	永久代/方法区/非堆区的最大值(默认64M)，太小容易出现`java.lang.OutOfMemoryError: PermGen space`。如：`-XX:MaxPermSize=512m`
-XX:PermSize64m|   JDK8-|	永久代/方法区/非堆区的初始大小(默认64M)。如：`-XX:PermSize=256m`
-Xmn||	新生代大小。通常为 Xmx 的 1/3 或 1/4。`新生代 = Eden + 2 个 Survivor 空间`。实际可用空间为 = Eden + 1 个 Survivor，即 90%
-Xss|	JDK1.5+ | 每个线程堆栈大小为 1M，一般来说如果栈不是很深的话， 1M 是绝对够用了的
-XX:NewRatio||	新生代与老年代的比例，如 –XX:NewRatio=2，则新生代占整个堆空间的1/3，老年代占2/3
-XX:SurvivorRatio||	新生代中 Eden 与 Survivor 的比值。默认值为 8。即 Eden 占新生代空间的 8/10，另外两个 Survivor 各占 1/10
-XX:+UseConcMarkSweepGC||    指定使用的垃圾收集器，这里使用CMS收集器
-XX:ErrorFile||    设置jvm致命错误日志文件生成位置(默认生成在工作目录下)，如：`-XX:ErrorFile=/var/log/hs_err_pid<pid>.log`

- 自定义jvm参数

```java
// 格式
// -D<name>=<value>
// System.getProperty(<name>)

// 示例
java -Dtest.name=aezocn -jar app.jar // 启动添加参数。值如果有空格可以使用""
System.getProperty("test.name") // 程序中取值，无此参数则为null
```

## jvm配置位置

- `tomcat`：修改`%TOMCAT_HOME%/bin/catalina.bat`或`%TOMCAT_HOME%/bin/catalina.sh`中的`JAVA_OPTS`，在`echo "Using CATALINA_BASE:   $CATALINA_BASE"`上面加入以下行：`JAVA_OPTS="-server -Xms256m -Xmx512m`(启动时运行的startup.bat/startup.sh，其内部调用catalina.bat)
- `weblogic`：修改`bea/weblogic/common中CommEnv`中参数
- `springboot`：可直接加在java命令后面，如`java -Xms256 -jar xxx.jar`
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



