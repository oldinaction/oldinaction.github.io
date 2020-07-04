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

- [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se14/html/index.html)
- [Java Virtual Machine Specification](https://docs.oracle.com/javase/specs/jvms/se14/html/index.html)
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
        u2             access_flags; // 描述符，如ACC_PUBLIC(0x0001)、ACC_INTERFACE等
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
- access_flags描述符
    - ACC_PUBLIC(0x0001)、ACC_INTERFACE、ACC_SYNCHRONIZED、ACC_VOLATILE
- 字段描述符解释
    - Ljava.lang.String(引用)、[(数组)、[[(二位数组)、J(Long)、Z(boolean)、B(byte)，其他同B基本以首字母开头
- 常量池标识
    - 1 CONSTANT_Utf8(1为Tag类型)
    - 3 CONSTANT_Integer
    - 7 CONSTANT_Class
    - 8 CONSTANT_String
    - ...
- [语句/指令](https://docs.oracle.com/javase/specs/jvms/se14/html/jvms-4.html#jvms-4.10.1.9)，如
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
        - `Preparation` 依次给静态变量赋默认值(如0/false)
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

            // Resolution阶段
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

- 对象在内存中的存储布局
- 对象头

### 面试题：关于对象

- 请解释一下对象的创建过程
    - class加载
        - class loading
        - class linking(verification、preparation、resolution)
        - class initialization
    - 申请对象内存
    - 成员变量赋默认值
    - 调用构造方法
        - 成员变量依次赋初始值
        - 执行构造方法语句
- 对象在内存中的存储布局
    - 普通对象
        - 对象头：markword 占8个字节
        - ClassPointer指针：增加 -XX:+UseCompressedClassPointers(开启ClassPointer指针压缩) 参数时为4字节，不开启(换成减号，-XX:-UseCompressedClassPointers)则为8字节
            - `java -XX:+PrintCommandLineFlags -version` 可查看JVM配置
            - Hotspot开启内存压缩的规则(64位机)：4G以下直接砍掉高32位；4G-32G默认开启内存压缩(ClassPointers、Oops)；32G以上压缩无效，使用64位，内存并不是越大越好
        - 实例数据
            - 主要是成员变量，基础数据类型、引用类型
            - 引用类型：开启 -XX:+UseCompressedOops(开启普通对象指针压缩) 配置时为4字节，不开启(换成减号)则为8字节。Oops：Ordinary Object Pointers
        - Padding对齐：对象总大小保证为8的倍数
    - 数组对象(多了一个数组长度)
        - 对象头：markword，同上
        - ClassPointer指针，同上
        - 数组长度为4字节
        - 数组数据，同上
        - Padding对齐，同上
- 对象头具体包括什么
    - 32位操作系统markword如下

        ![jvm-32-markword](/data/images/java/jvm-32-markword.png)
        - markword包含的内容和对象的状态有关。最后两位是锁标志位；无锁和偏向锁时，倒数第三位记录了偏向锁状态；分代年龄占4位(2^4=0->15)，因此GC年龄最大为15
        - 无锁状态时可能存储了hashCode，占25bit
            - 只有未重写hashCode方法且调用了hashCode方法/System.identityHashCode时才会将hashCode存放在markword中(重写了hashCode方法的计算结果不会存放在此处)
            - 未重写hashCode方法的，那么默认调用os::random产生hashcode，一旦生成便会记录在markword中，可以通过System.identityHashCode获取
        - 当一个对象计算过identityHashCode之后，不能进入偏向锁状态(因为记录偏向锁线程的位置被hashCode占用了)
    - 64位操作系统markword如下

        ![jvm-64-markword](/data/images/java/jvm-64-markword.png)
- [对象怎么定位](https://blog.csdn.net/clover_lily/article/details/80095580)
    - 句柄池、直接指针
    - 不同的JVM实现可能不同，HotSpot使用的直接指针(寻找对象快，GC相对慢)
- 对象怎么分配
- Object o = new Object()在内存中占用多少字节(64位系统)
    - 基于jvm agent完成：在将class加载到内存是，会先执行指定的agent，此时可拦截class进行操作(如获取大小)。参考[ObjectSizeAgent.java.bak](https://github.com/oldinaction/smjava/blob/master/jvm/src/main/java/cn/aezo/jvm/c03_object_size/ObjectSizeAgent.java.bak)
    - 开启ClassLoader压缩：8(markword) + 4(ClassPointer指针) + 0(无实例数据/属性) + 4(Padding对齐) = 16字节
    - 未开ClassLoader压缩：8(markword) + 8(ClassPointer指针) + 0(无实例数据/属性) + 0(Padding对齐) = 16字节

## Runtime Data Area运行时数据区

- [Runtime Data Area](https://docs.oracle.com/javase/specs/jvms/se14/html/jvms-2.html#jvms-2.5)

![jvm-runtime-data-area](/data/images/java/jvm-runtime-data-area.png)
- java线程有各自的PC(Program Counter程序计数器，记录指令的执行位置)、VMS(Virtual Machine Stack)、NMS(Native Method Stack)；但是他们共用Heap、Method Area [^1]
    - PC 程序计数器：存放指令位置
    - JVM Stack
        - 一个线程会有一个Stack，一个Stack有多个Frame栈帧组成，每个方法对应一个Frame栈帧
        - Frame栈帧组成
            - 局部变量表(`Local Variables`)
            - 操作数栈(`Opreand Stack`) 或表达式栈
            - 动态链接 (`Dynamic Linking`) 或指向运行时常量的方法引用
                - 在Java源文件被编译到字节码文件中时，所有的变量和方法引用都作为符号引用(Symbolic Reference )保存在class文件的常量池里。比如，描述一个方法调用其他方法时，就是通过常量池中指向方法的符号引用来表示的，那么动态链接的作用就是为了将这些符号引用转换为调用方法的直接引用
                - 加载类的Resolution阶段就是将符号应用转换为直接引用
            - 返回地址(Return Address) 或方法退出的引用的定义(a方法调用b方法，b方法返回的值保存的位置)
    - Native Method Stack
    - Method Area
        - JDK<1.8时，实际是保存在 Perm Space。字符串常量位于PermSpace，此时FGC不会清理，大小在启动的时候指定，不能变
        - JDK>=1.8时，实际是保存在 Meta Space。字符串常量位于堆，会触发FGC清理，不设定的话，最大就是物理内存
    - Runtime Constant Pool

## Instruction Set常用指令

> https://docs.oracle.com/javase/specs/jvms/se14/html/jvms-4.html#jvms-4.10.1.9

- 压栈和弹栈(此处栈均指Opreand Stack)
    - 压栈：将值放到栈顶，如store类型指令
    - 弹栈：将栈顶的值从栈中取出(包含从栈中移除)
        - 根据命令特点确定是否需要弹栈和弹出几个操作值。如sub命令，是对两个数进行操作，因此是从栈顶中弹出两个值
- 常用指令
    - load 从本地变量表中取值并放到栈顶(压栈)
        - `iload_<n>` 从第n个本地变量表中的int型值取出并放到栈顶。如果是short等则会转换为int
        - `lload_<n>` 从第n个本地变量表中的long型值取出并放到栈顶
        - `fstore_<n>` float型
        - `dstore_<n>` double型
        - `astore_<n>` 引用型
    - const 将常量值放到栈顶(压栈)
        - `iconst_<i>` 将int型常量值i放到栈顶。其他数据类型同load
    - store 存表
        - `istore_<n>` 将栈顶int型数值存入第n个本地变量。其他数据类型同load
    - new 创建一个对象，并将其引用值压入栈顶
    - dup 复制栈顶数值并将复制值压入栈顶
    - invoke
        - invokestatic 调用静态方法
        - invokevirtual 非private的成员方法(自带多态，此指令会根据实际对象的引用调用对应方法)
        - invokeinterface
        - inovkespecial 可以直接定位，不需要多态的方法 private 方法、构造方法(<init>)。final修饰的方法是InvokeVirtual
        - invokedynamic 如lambda表达式、反射、其他动态语言(scala kotlin等)、CGLib、ASM等动态产生的class，会用到此指令
    - pop 将栈顶数值弹出 (数值不能是long或double类型的)
    - pop2 将栈顶的一个(long或double类型的)或两个数值弹
    - inc 
        - `iinc` 如：iinc 0 by 1 表示将本地变量表的第0个位置(int型)值增加1(仅修改了本地变量表的值，并没有修改栈中的值)
    - add 将栈顶两int型数值相加并将结果压入栈顶
    - sub 相减
    - mul 相乘
- 案例一

```java
/**
 * 通过jclasslib观察指令的不同
 *
 * 1.add1的指令
 *
 *  0 iconst_3                                          // 将int型常量放到栈顶(执行后栈底->栈顶：3)
 *  1 istore_0                                          // 将int型值保存到第0个本地变量表(执行后栈底->栈顶：空)
 *  2 iload_0                                           // 将第0个本地变量表的int型值放到栈顶(执行后栈底->栈顶：3)
 *  3 iinc 0 by 1                                       // 将本地变量表的第0个位置(int型)值增加1(仅修改了本地变量表的值，此时为1，并没有修改栈中的值；执行后栈底->栈顶：0)
 *  6 istore_0                                          // 将栈顶的值(0)保存在本地变量表的第0个位置(此时本地变量第0个位置值为0；执行后栈底->栈顶：空)
 *  7 getstatic #4 <java/lang/System.out>
 * 10 iload_0                                           // 加载本地变量表的第0个位置值到栈顶(执行后栈底->栈顶：3)
 * 11 invokevirtual #5 <java/io/PrintStream.println>    // 打印栈顶的值(执行后栈底->栈顶：空)
 * 14 return
 *
 * 2.add2的指令
 *
 *  0 iconst_3
 *  1 istore_0
 *  2 iinc 0 by 1
 *  5 iload_0
 *  6 istore_0
 *  7 getstatic #4 <java/lang/System.out>
 * 10 iload_0
 * 11 invokevirtual #5 <java/io/PrintStream.println>
 * 14 return
 */
public class T01_IntAddAdd {
    public static void main(String[] args) {
        add1(); // 3

        add2(); // 4
    }

    public static void add1() {
        int i = 3;
        i = i++;
        System.out.println(i);
    }

    public static void add2() {
        int i = 3;
        i = ++i;
        System.out.println(i);
    }
}
```
- 案例二

    ![jvm-runtime-stacks-example](/data/images/java/jvm-runtime-stacks-example.png)
    - main方法第0号指令：创建一个对象，并将其引用值压入栈顶(执行后栈为：对象引用h)
    - main方法第3号指令：dup复制一个栈顶值(执行后栈为：对象引用h、对象引用h)
    - main方法第4号指令：调用Hello_02的构造方法，此时会弹出一个栈顶值(因此需要先dup一次；执行后栈为：对象引用h)
    - main方法第7号指令：将栈顶值赋值到本地变量表第1个位置(即赋值引用地址给h；执行后栈为：空)





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



---

参考文章

[^1]: https://www.cnblogs.com/ding-dang/p/13051143.html

