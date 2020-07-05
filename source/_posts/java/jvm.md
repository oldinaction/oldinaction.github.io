---
layout: "post"
title: "JVM"
date: "2017-01-20 13:07"
categories: [java]
tags: [jvm]
---

## 简介

- [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se14/html/index.html)
- [Java Virtual Machine Specification](https://docs.oracle.com/javase/specs/jvms/se14/html/index.html)
- 本文无特殊说明，默认基于JDK1.8
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

## JMM(Java内存模型)

- JMM(Java Memory Model)
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
            - `java -XX:+PrintCommandLineFlags -version` 可查看JVM默认配置
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
    - Heap
    - Method Area(逻辑概念)
        - JVM规范中定义的一个概念，用于存储类信息、常量池(Runtime Constant Pool)、静态变量、JIT编译后的代码等数据
        - 具体放在哪里，不同的实现可以放在不同的地方
            - JDK<1.8时，实际指 Perm Space(在Hotspot中，方法区只是在逻辑上独立，物理上还是包含在堆区中，又称永久代)。此时FGC不会清理，大小在启动的时候指定，不能变
            - JDK>=1.8时，实际指 Meta Space(并不在虚拟机中，而是使用本地内存。会触发FGC清理，不设定的话，最大就是物理内存

## Instruction Set常用指令

> https://docs.oracle.com/javase/specs/jvms/se14/html/jvms-4.html#jvms-4.10.1.9

- 压栈和弹栈(此处栈均指Opreand Stack)
    - 压栈：将值放到栈顶，如store类型指令
    - 弹栈：将栈顶的值从栈中取出(包含从栈中移除)
        - 根据命令特点确定是否需要弹栈和弹出几个操作值。如sub命令，是对两个数进行操作，因此是从栈顶中弹出两个值
- [常用指令](https://www.jianshu.com/p/bc91c6b46d7b)
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
    - `new` 创建一个对象，并将其引用值压入栈顶
    - `dup` 复制栈顶数值并将复制值压入栈顶
    - invoke
        - `invokestatic` 调用静态方法
        - `invokevirtual` 非private的成员方法(自带多态，此指令会根据实际对象的引用调用对应方法)
        - `invokeinterface` 调用接口方法
        - `inovkespecial` 可以直接定位，不需要多态的方法 private 方法、构造方法(<init>)。final修饰的方法是InvokeVirtual
        - `invokedynamic` 如lambda表达式、反射、其他动态语言(scala kotlin等)、CGLib、ASM等动态产生的class，会用到此指令
    - `pop` 将栈顶数值弹出 (数值不能是long或double类型的)
    - pop2 将栈顶的一个(long或double类型的)或两个数值弹
    - inc 
        - `iinc` 如：iinc 0 by 1 表示将本地变量表的第0个位置(int型)值增加1(仅修改了本地变量表的值，并没有修改栈中的值)
    - add 将栈顶两int型数值相加并将结果压入栈顶
    - sub 相减
    - mul 相乘
    - `ifeq` 当栈顶int型数值等于0时跳转，如：ifeq 7 (+5) 如果相等则跳到7号指令(当前指令号+5)
    - `if_icmpne`(if int compare not equel) 比较栈顶两int型数值大小，当结果不等于0时跳转
- 案例一

```java
/**
 * 通过jclasslib观察指令的不同
 *
 * 1.main方法指令
 * 
 * 0 iconst_3                                           // 将int型常量放到栈顶(执行后栈底->栈顶：3)
 * 1 istore_1                                           // 将栈顶元素放到第1个本地变量表(方法的args参数放在第0个本地变量表中)
 * 2 invokestatic #2 <cn/aezo/jvm/c04_instruction_set/T01_IntAddAdd.add1>
 * 5 invokestatic #3 <cn/aezo/jvm/c04_instruction_set/T01_IntAddAdd.add2>
 * 8 return
 *
 * 2.add1的指令
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
 * 3.add2的指令
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
 *
 */
public class T01_IntAddAdd {
    public static void main(String[] args) {
        int i = 3;
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

## 堆分代模型和垃圾回收器

- `GC`(Garbage Collector) 垃圾回收器
- `Minor GC/Yong GC(MGC/YGC)` 年轻代(Eden)空间耗尽时触发
- `Major GC/Full GC` 在老年代无法继续分配空间时触发，新生代老年代同时进行回收(比较慢、重量级)
- `STW`(Stop The World) 所有的工作线程必须停下等垃圾回收完成

### 处理垃圾相关算法

- 垃圾(Garbage)
    - 没有任何引用指向的一个对象或多个对象就是垃圾
    - C内存操：malloc free；C++: new delete
    - C/C++ 手动回收内存，Java自动回收
    - 自动内存回收，编程上简单，系统不容易出错；手动释放内存，容易出两种类型的问题：忘记回收、多次回收
- 垃圾查找算法
    - `reference count` 引用计数，当计数为0时则认为是那就。不能解决循环引用
    - `root searching` **根可达算法**，从根对象开始找到都是有用的对象
        - 根对象：线程栈变量、静态变量、常量池、JNI指针
- **垃圾清除算法**
    - Mark-Sweep 标记清除
    - Copying 拷贝
    - Mark-Compact 标记压缩
- `Mark-Sweep`
    - 算法相对简单，存活对象比较多的情况下效率高
    - 两遍扫描(标记+清除)，效率较低
    - 容易产生碎片

    ![jvm-Mark-Sweep](/data/images/java/jvm-Mark-Sweep.png)
- `Copying`
    - 适用于存活对象较少的情况
    - 一遍扫描
    - 移动复制对象，需要调整对象引用
    - 不会产生碎片
    - 产生内存减半，空间浪费

    ![jvm-Copying](/data/images/java/jvm-Copying.png)
- `Mark-Compact`
    - 扫描两次
    - 移动复制对象，需要调整对象引用
    - 不会产生碎片，方便对象分配
    - 不会产生内存减半

    ![jvm-Mark-Compact](/data/images/java/jvm-Mark-Compact.png)

### JVM内存(堆)分代模型

- 内存分代模型用于分代垃圾回收算法，部分垃圾回收器使用此模型
    - 除Epsilon、ZGC、Shenandoah之外的GC都是使用逻辑分代模型
    - G1是逻辑分代，物理不分代(实际内存分不同的分代区)
    - 除此之外(CMS等)不仅逻辑分代，而且物理分代
- **堆内存逻辑分区**(不适用不分代垃圾回收器)

    ![jvm-heap-area](/data/images/java/jvm-heap-area.png)
    - 堆内存分为两块：新生代new/年轻代young、老年代Old
    - 新生代又分为三块：`Eden`、`Survivor-S1`、`Survivor-S2`(S1和S2一般一起聊，也有人把他俩叫做S0和S1，或者from和to，就是两块Survivor幸存区)
    - Survivor区
        - Survivor的存在意义
            - 就是减少被送到老年代的对象，进而减少Full GC的发生(Full GC耗时相对较长)
            - 如果没有Survivor，Eden区每进行一次Minor GC，存活的对象就会被送到老年代，老年代很快被填满
        - Survivor的预筛选保证，只有经历16次Minor GC(分代年龄为15, CMS为6)还能在新生代中存活的对象，才会被送到老年代。可通过`-XX:MaxTenuringThreshold`配置此处触发的次数
        - 设置两个Survivor区最大的好处就是解决了碎片化
            - **GC过程**
                - 刚刚新建的对象在Eden中(可能也会在栈上分配)
                - 当经历一次Minor GC，Eden中大多数的对象会被回收，Eden中的存活对象就会被移动到第一块survivor space S0。Eden被清空(每经历一次Minor GC，分代年龄+1)
                - 等Eden区再满了，就再触发一次Minor GC，活着的对象eden + s0 -> s1(这个过程非常重要，因为这种复制算法保证了S1中来自S0和Eden两部分的存活对象占用连续的内存空间，避免了碎片化的发生)。S0和Eden被清空
                - 然后下一轮S0与S1交换角色，再次Minor GC时，eden + s1 -> s0，如此循环往复。如果对象的分代年龄达到15(CMS为6)，该对象就会被送到老年代中
                - 如果在某次复制到Survivor区时，要复制的对象大小超过目标Survivor区的一半时，则将其中年龄最大的直接放到老年代中，剩下的保存在目标Survivor区
                - 老年代满了触发Full GC
            - 上述机制最大的好处就是，整个过程中，永远有一个survivor space是空的，另一个非空的survivor space无碎片
            - Survivor分成2块以上，必定每一块的空间就会比较小，很容易导致Survivor区满(从而直接存放到老年代了)

### 对象存放位置变化过程

![jvm-对象存放位置变化过程](/data/images/java/jvm-对象存放位置变化过程.png)

- 对象存放位置变化过程
    - 一个对象产生时，首先尝试在栈上分配，如果符合条件分配在栈了；当方法结束时，栈弹出，对象就终结了
    - 如果没在栈上分配，就判断对象大小，如果特别大直接进入Old区，否则的话就分配至Eden区(TLAB也属于Eden区)
    - 如果进入Eden区：经过一次YGC后，存活对象在S1和S2交替，每换个区对象的年龄+1
    - 多次垃圾回收后，对象的年龄到了，就进入Old区
- 直接分配在Eden区的话，会存在多线程的竞争，效率较低。为了提高效率，减少多线程的竞争，会优先考虑分配在栈上和TLAB上
    - 栈上分配
        - 条件
            - 线程私有小对象
            - 没有逃逸(只在某段代码中使用)
            - 支持标量替换(这个对象可以用几个简单的变量替换)
        - 多线程没有竞争；方法结束，栈弹出，对象消失，不用GC回收
        - 一般无需调整
    - 线程本地分配TLAB(Thread Local Allocation Buffer)
        - 实际也是属于Eden，默认是Eden的1%
        - 如果栈空间不够了，会优先分配在TLAB，主要针对小对象
        - 多线程没有竞争，或者竞争很少
        - 一般也无需调整
- 对象进入老年代的时机
    - age超过`-XX:MaxTenuringThreshold`指定次数(TGC)时进入老年代
        - 对象头markword里面，GC age标识位占用4位，所以对象的年龄最大为15
            - Parallel Scavenge 回收器阈值为 15
            - CMS为6
            - G1为15
    - 动态年龄
        - 假设有次的YGC是Eden&S1->S2，如果S2中的存活对象超过了S2空间的一半，就把S2中年龄最大的对象放入老年代
    - [分配担保](https://cloud.tencent.com/developer/article/1082730)
        - YGC期间Survivor区空间不够了，空间担保直接进入老年代

### 常见的垃圾回收器

- 垃圾回收器历史
    - JDK诞生，便有Serial垃圾回收器
    - 为了提高效率，诞生了PS
    - 为了配合CMS，诞生了PN
    - 后来有了G1、ZGC等
- JDK1.8默认的垃圾回收：PS + ParallelOld
- 常见的垃圾回收器

    ![jvm-gc](/data/images/java/jvm-gc.png)
    - `Serial` 针对年轻代垃圾回收，串行执行(单线程进行回收)，会出现STW，使用Copying算法清理
    - `SerialOld` 针对老年代回收，串行执行(单线程)，会出现STW。一般和Serial结合使用
    - `Parallel Scavenge`(PS) 年轻代，并行回收(多线程进行回收)，会出现STW，使用Copying算法清理
    - `ParallelOld` 老年代，并行回收(多线程)，会出现STW，使用Mark-Compact算法。一般和PS结合使用
    - `ParNew`(PN) 年轻代，并行回收(多线程)，会出现STW，使用Copying算法清理(PS的一个升级版本)。般配合CMS的并行回收
    - `CMS`(ConcurrentMarkSweep) 老年代，并行回收(多线程)，且并发回收(垃圾回收和应用程序同时运行)，使用Mark-Sweep算法
        - CMS是1.4版本后期引入，CMS是里程碑式的GC，它开启了并发回收的过程，但是CMS毛病较多，因此目前任何一个JDK版本默认是CMS，只能手工指定CMS
        - 包含4步

            ![jvm-cms](/data/images/java/jvm-cms.png)
            - initial mark 只标记根对象
            - concurrent mark
            - remark
            - concurrent sweep
        - CMS的缺点
            - Memory Fragmentation(内存碎片化)
                - 使用Mark-Sweep算法会产生很多碎片，这些碎片会占用且镂空老年代内存(可能存在有些未用的空间被碎片占位导致无法使用，见上文Mark-Sweep算法图)，碎片到达一定程度，CMS的老年代分配对象分配不下的时候，此时会使用SerialOld进行老年代回收
                - 如果内存较大(32G及以上不建议使用CMS)，出现SerialOld单线程回收时，会很耗时，因此STW时间会很长(几十个G内存可能几个小时到几天)。因此可能出现硬件升级反而出现卡顿
                - 可使用以下参数优化
                    - `-XX:+UseCMSCompactAtFullCollection` 在FGC时进行压缩从而清理碎片
                    - `-XX:CMSFullGCsBeforeCompaction` 默认为0，指经过多少次FGC才进行压缩
            - Floating Garbage(浮动垃圾，在concurrent sweep并发清理的同时产生的垃圾)
                - -XX:CMSInitiatingOccupancyFraction 92%(JDK1.8默认，当老年代使用到达92%时触发FGC。可适当调小从而给浮动垃圾多留一点空间，下次并发回收便会清理)
        - 算法：三色标记 + Incremental Update
    - `G1` 使用算法：三色标记 + SATB。STW时间为10ms左右
    - `ZGC` 使用PK C++
        - 使用算法：ColoredPointers + LoadBarrier。STW时间为1ms左右
    - `Shenandoah` 使用算法：ColoredPointers + WriteBarrier
    - `Eplison`
- 垃圾收集器适用的内存大小
    - Serial 几十兆
    - PS 上百兆-几个G
    - CMS 20G
    - G1 上百G
    - ZGC 4T-16T(JDK13)
- 常见垃圾回收器组合参数设定
    - `-XX:+UseSerialGC` 使用Serial New (DefNew) + Serial Old。适用于小型程序；默认情况下不会是这种选项，HotSpot会根据计算及配置和JDK版本自动选择收集器
    - `-XX:+UseParNewGC` 使用ParNew + SerialOld。这个组合已经很少用，[在某些版本中已经废弃](https://stackoverflow.com/questions/34962257/why-remove-support-for-parnewserialold-anddefnewcms-in-the-future)
    - `-XX:+UseConcurrentMarkSweepGC`(有点是-XX:+UseConcMarkSweepGC) 使用ParNew + CMS + Serial Old
    - `-XX:+UseParallelGC` 使用Parallel Scavenge + Parallel Old，**1.8默认**
    - `-XX:+UseParallelOldGC` 使用Parallel Scavenge + Parallel Old
    - `-XX:+UseG1GC` 使用G1
    - `java -XX:+PrintCommandLineFlags -version` 查看默认配置，可发现1.8.0_131使用的是PS+PO(-XX:+UseParallelGC)

## JVM调优

- 区分概念
    - 内存泄漏memory leak：指有某块内存永远不会被回收，内存泄漏不一定会产生内存溢出(比如内存足够大)
    - 内存溢出out of memory：内存不够了

### 常用命令

- JVM的命令行参数参考：https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html
    - `java -XX:+PrintFlagsInitial` 打印默认参数值
    - `java -XX:+PrintFlagsFinal` 打印最终参数值
        - `java -XX:+PrintFlagsFinal | grep GC` 找到GC相关参数
- HotSpot参数分类
    - 标准：`-` 开头，所有的HotSpot都支持
    - 非标准：`-X` 开头，特定版本HotSpot支持特定命令。`java -X`查看支持的参数
    - 不稳定：`-XX` 开头，下个版本可能取消

### 简单测试及GC日志

- 测试Demo

```java
/**
 * 1. -XX:+PrintCommandLineFlags 打印启动程序时的JVM参数。结果如下：
 *      -XX:InitialHeapSize=266743424 -XX:MaxHeapSize=4267894784 -XX:+PrintCommandLineFlags -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:-UseLargePagesIndividualAllocation -XX:+UseParallelGC
 *      HelloGC!
 *      Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
 * 2. -XX:+UseConcMarkSweepGC -XX:+PrintCommandLineFlags -XX:+PrintGC 使用CMS垃圾回收器；PrintGC打印GC日志(PrintGCDetails打印详细、PrintGCTimeStamps打印产生时间、PrintGCCause打印GC产生原因)
 * 3. -Xmn10M -Xms40M -Xmx60M -XX:+PrintCommandLineFlags -XX:+PrintGCDetails 设置新生代大小为10M；老年代最小为40M，最大为60M
 *
 * @author smalle
 * @date 2020-07-05 19:12
 */
public class T02_HelloGC {
    public static void main(String[] args) {
        System.out.println("HelloGC!");
        List list = new LinkedList();
        for(;;) {
            byte[] b = new byte[1024*1024]; // 产生1M的数据
            list.add(b); // 有引用指向，b永远不是垃圾对象，最终肯达会出现GC并OOM
        }
    }
}
```
- 上文使用`-Xmn10M -Xms40M -Xmx60M -XX:+PrintGCDetails`产生如下OOM日志

```bash
# GC表示产生了YGC
    # (Allocation Failure)为产生原因
    # PSYoungGen表示使用PS进行年轻代回收(还有如DefNew表示单线程Serial进行年轻代回收)
        # 7278K为回收前年轻代空间大小，872K为回收后年轻代空间大小，39936K为年轻代总空间大小
    # 7278K为GC前堆空间大小，6000K为GC后堆空间大小，39936K为堆总空间大小
    # 0.0020406 secs为此次GC消耗时间
# Times为系统时间记录(如linux执行命令`time ls`会记录ls消耗时间)：user表示用户空间耗时，sys为内核空间耗时；real为总耗时
[GC (Allocation Failure) [PSYoungGen: 7278K->872K(9216K)] 7278K->6000K(39936K), 0.0020406 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[GC (Allocation Failure) [PSYoungGen: 8196K->840K(9216K)] 13324K->13136K(39936K), 0.0018261 secs] [Times: user=0.06 sys=0.05, real=0.00 secs] 
[GC (Allocation Failure) [PSYoungGen: 8322K->808K(9216K)] 20618K->20272K(39936K), 0.0022864 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[GC (Allocation Failure) [PSYoungGen: 8128K->776K(9216K)] 27593K->27408K(39936K), 0.0022397 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
# 表示产生了Full GC
    # PSYoungGen 使用PS进行年轻代回收
    # ParOldGen 使用PO进行老年代回收
        # 26632K->27299K(45056K)分别为老年代回收前、回收后、总大小
    # 27408K->27299K(54272K)为堆信息，同上
# Metaspace空间回收信息
    # 3471K->3471K(1056768K)为Metaspace回收前、回收后、总大小
# Times为系统时间记录
[Full GC (Ergonomics) [PSYoungGen: 776K->0K(9216K)] [ParOldGen: 26632K->27299K(45056K)] 27408K->27299K(54272K), [Metaspace: 3471K->3471K(1056768K)], 0.0113658 secs] [Times: user=0.09 sys=0.00, real=0.01 secs] 
[GC (Allocation Failure) [PSYoungGen: 7323K->192K(8704K)] 34623K->34659K(53760K), 0.0034389 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[GC (Allocation Failure) [PSYoungGen: 7509K->1216K(8704K)] 41977K->41828K(53760K), 0.0022050 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[Full GC (Ergonomics) [PSYoungGen: 1216K->0K(8704K)] [ParOldGen: 40612K->41636K(51200K)] 41828K->41636K(59904K), [Metaspace: 3471K->3471K(1056768K)], 0.0039151 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[GC (Allocation Failure) [PSYoungGen: 6278K->1216K(8704K)] 47914K->47972K(59904K), 0.0018068 secs] [Times: user=0.02 sys=0.00, real=0.00 secs] 
[Full GC (Ergonomics) [PSYoungGen: 1216K->0K(8704K)] [ParOldGen: 46756K->47780K(51200K)] 47972K->47780K(59904K), [Metaspace: 3471K->3471K(1056768K)], 0.0025987 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[Full GC (Ergonomics) [PSYoungGen: 6272K->3072K(8704K)] [ParOldGen: 47780K->50852K(51200K)] 54052K->53924K(59904K), [Metaspace: 3471K->3471K(1056768K)], 0.0028006 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[Full GC (Ergonomics) [PSYoungGen: 6268K->6144K(8704K)] [ParOldGen: 50852K->50852K(51200K)] 57121K->56997K(59904K), [Metaspace: 3471K->3471K(1056768K)], 0.0027381 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[Full GC (Allocation Failure) [PSYoungGen: 6144K->6144K(8704K)] [ParOldGen: 50852K->50834K(51200K)] 56997K->56978K(59904K), [Metaspace: 3471K->3471K(1056768K)], 0.0111997 secs] [Times: user=0.08 sys=0.00, real=0.01 secs] 
# 内存溢出时heap dump部分
Heap
 # 年轻代信息(使用PS回收器)
    # total 8704K 表示存活对象可用的总空间(eden + 一个Survivor区)；used 6393K使用空间；后面的内存地址指的是：起始地址，已使用空间结束地址，整体空间结束地址
 PSYoungGen      total 8704K, used 6393K [0x00000000ff600000, 0x0000000100000000, 0x0000000100000000)
  # eden区空间大小为7168K，使用了89%
  eden space 7168K, 89% used [0x00000000ff600000,0x00000000ffc3e4d8,0x00000000ffd00000)
  from space 1536K, 0% used [0x00000000ffd00000,0x00000000ffd00000,0x00000000ffe80000)
  to   space 1536K, 0% used [0x00000000ffe80000,0x00000000ffe80000,0x0000000100000000)
 # 老年代信息(使用PO回收器)
 ParOldGen       total 51200K, used 50834K [0x00000000fc400000, 0x00000000ff600000, 0x00000000ff600000)
  object space 51200K, 99% used [0x00000000fc400000,0x00000000ff5a4958,0x00000000ff600000)
 # 方法区信息
    # used已使用大小，capacity使用的容量大小，committed占用虚拟内存大小，reserved虚拟内存保留大小
    # 程序启动，系统会保留(reserved)一定的内存(如 100M)，刚开始程序只占(committed)用了部分内存(如 30M)，实际程序分配了一定的容量(capacity，此容量会自动收缩)大小(如 20M)，最终程序运行时实际使用(used)的空间只有一部分(如 5M)
 Metaspace       used 3501K, capacity 4498K, committed 4864K, reserved 1056768K
  class space    used 388K, capacity 390K, committed 512K, reserved 1048576K
# 报错信息
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at cn.aezo.jvm.c05_gc.T02_HelloGC.main(T02_HelloGC.java:23)
```

### 调优前的基础概念

- 吞吐量：用户代码时间 / (用户代码执行时间 + 垃圾回收时间)
- 响应时间：STW越短，响应时间越好
- 所谓调优，首先确定，追求啥？吞吐量优先；还是响应时间优先；还是在满足一定的响应时间的情况下，要求达到多大的吞吐量...
    - 科学计算、数据挖掘等：一般注重吞吐量，因此可使用PS + PO
    - 网站、GUI、API等：一般注重响应时间，因此可使用G1等
- 什么是调优
    - 根据需求进行JVM规划和预调优
    - 优化运行JVM运行环境(慢，卡顿)
    - 解决JVM运行过程中出现的各种问题(OOM)
- JVM规划和预调优
    - 调优一般可先从业务场景开始
    - 无监控(压力测试，能看到结果)不调优。估算一个事务会消耗多少内存，可用压测来确定，看能承受多少TPS
    - 步骤：
        - 熟悉业务场景
            - 响应时间、停顿时间优先 => CMS、G1、ZGC
            - 吞吐量优先 => PS+PO
        - 选择回收器组合
        - 计算内存需求
        - 选定CPU(越高越好)
        - 设定年代大小、升级年龄
        - 设定日志参数
            - `-Xloggc:/var/log/my-test-gc-%t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=20M -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCCause` 使用循环日志，日志个数为5个，每个日志大小为20M
        - 观察日志情况
    - 案例1：垂直电商(只卖一类产品)，最高每日百万订单，处理订单系统需要什么样的服务器配置？
        - **淘宝2019双11最大并发54W；12306春节最大并发100w以上**。电商的并发一般值TPS(每秒能完成的事物数，即每秒成创建多少个订单)，其他性能评判指标如QPS
        - 这个问题比较业余，因为很多不同的服务器配置都能支撑(1.5G、16G)
        - 分析：假设高峰为19-21点成交70w订单，约1小时产生36w，即100个订单/秒。那假设最高峰期为10倍，即1000订单/秒
        - 实际需要按经验值估算需要占用的内存空间
            - 大致估算：一个订单产生需要512K(多一点1-2M)内存 * 1000 = 500M内存
            - 因此只需要保证新生代Eden区占用500M内存空间即可，如果CPU较快也可适当减少(因为回收垃圾很快)
        - 专业一点儿问法：要求响应时间100ms
    - 案例2：12306遭遇春节大规模抢票应该如何支撑？
        - 12306应该是中国并发量最大的秒杀网站：号称并发量100W最高
        - 猜测架构：CDN -> LVS -> NGINX -> 业务系统 -> 每台机器1W并发(C10K问题)，使用100台机器
        - 普通电商订单 -> 下单 -> 订单系统(IO)减库存 -> 等待用户付款
        - 12306的一种可能的模型：下单 -> 减库存(redis，redis可支撑单机1W并发) 和 订单(kafka) 同时(多线程)异步进行 -> 等付款
        - 如果把库存记录在一台机器上，则减库存最后还会把压力压到一台服务器。可以做分布式本地库存 + 单独服务器做库存均衡
        - 大流量的处理方法：分而治之







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

