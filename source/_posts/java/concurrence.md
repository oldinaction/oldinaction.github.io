---
layout: "post"
title: "并发编程"
date: "2018-12-05 14:28"
categories: java
tags: [concurrence, collection, juc, 线程池]
---

## 简介

- Java 的并行 API 演变历程
    - 1.0-1.4 中的 java.lang.Thread 
    - 5.0 中的 java.util.concurrent(JUC)
    - 6.0 中的 Phasers 等
    - 7.0 中的 Fork/Join 框架
    - 8.0 中的 Lambda(如Stream)
- https://www.cnblogs.com/dolphin0520/category/1426288.html
- 源码阅读技巧
    - 跑不起来不读
    - 解决问题即可
    - 理解别人的思路
    - 一条线索到底
    - 无关细节略过
    - 一般不读静态
    - 数据结构基础，设计模式基础
- 串行、并发、并行
    - **串行**是完成了A任务之后才能开始B任务
    - **并发**的关键是你有处理多个任务的能力，**不一定要同时**
    - **并行**的关键是你有**同时**处理多个任务的能力

## 多线程与高并发

> https://github.com/bjmashibing/JUC

### 线程基础

#### 线程基础

- 创建线程
    - new (T1 extends Thread).start()
    - new Thread(new MyRunnable()).start()，或者JDK8：new Thread(()->{...}).start();
- 线程的相关方法(sleep/yield/join)
    - `Thread.sleep()` [^4]
        - sleep是Thread类的本地final方法，无法被重写
        - sleep和wait都会暂停当前的线程，**都会让出CPU**
            - 对于CPU资源来说，不管是哪种方式暂停的线程，都表示它暂时不再需要CPU的执行时间，OS会将执行时间分配给其它线程。区别是，sleep到达一定时间则会继续执行；而调用wait后，需要别的线程执行notify/notifyAll才能够重新获得CPU执行时间
        - **sleep不会导致锁行为的改变**
            - 所谓sleep是指让线程暂停被调度一段时间，或者挂起一段时间。整个sleep过程除了修改挂起状态之外，不会动任何其他的资源，这些资源包括任何持有的任何形式的锁。至于认为sleep消耗资源的情况如下：如果A线程抢到一把锁，然后sleep，B线程无论如何也无法获取该锁，从而B的执行被卡住，浪费了CPU
    - `wait/notify/notifyAll`
        - wait/notify/notifyAll方法是Object的本地final方法，无法被重写
        - wait会暂停当前的线程，会让出CPU
        - **wait/notify/notifyAll使用，前提是必须先获得锁，即一般在 synchronized 同步代码块里使用**
            - 只有当 notify/notifyAll 被执行时候，才会唤醒一个或多个正处于等待状态的线程，然后继续往下执行，直到执行完synchronized代码块的代码或是中途遇到wait再次释放锁
        - **wait会释放锁，notify/notifyAll不会释放锁**（wait不用退出同步代码块就会释放锁，而notify/notifyAll必须退出同步代码块才会释放）
            - **wait醒来继续执行时，仍然需要获得锁才能继续执行**（因为wait下面的代码块一般也在同步块中，此时需要对应notify释放锁，即notify退出同步代码块）
            - notify/notifyAll 的执行只是唤醒沉睡的线程，而不会立即释放锁，锁的释放要看代码块的具体执行情况。所以在编程中，**尽量在使用了notify/notifyAll后立即退出同步代码块，以让唤醒的线程获得锁**
        - **wait 需要被try catch包围**，以便发生异常中断也可以使wait等待的线程唤醒
        - **notify 和 wait 的顺序不能错**，否则报错IllegalMonitorStateException。如果A线程先执行notify方法，B线程再执行wait方法，那么B线程是无法被唤醒的(不会报错，LockSupport得unpark可在park之前运行)
        - notify方法只唤醒一个等待(对象的)线程并使该线程开始执行。所以如果有多个线程等待一个对象，这个方法只会唤醒其中一个线程，选择哪个线程取决于操作系统对多线程管理的实现。notifyAll 会唤醒所有等待(对象的)线程，尽管哪一个线程将会第一个处理取决于操作系统的实现
        - **在多线程中要测试某个条件的变化，使用if还是while来包裹wait？** (while)
            - 要注意，notify唤醒沉睡的线程A后，A线程会接着上次的执行继续往下执行(需要重新获取锁)。所以在进行条件判断时候，可以先把 wait 语句忽略不计来进行考虑
    - `LockSupport.park`
        - **阻塞当前线程的执行，且不会释放当前线程占有的锁资源**
        - 无需在同步块中执行，可以在任意地方执行
        - 不需要捕获中断异常
        - `Condition.await()` 需要在lock块中执行，底层调用的是LockSupport.park
    - `Thread.yield()`
        - 当前线程让出CPU一小会调度其他线程，并进入等待队列等待CPU的下次调度，也可能存在让出CPU之后仍然调度的是此线程
    - `join()`
        - CPU执行A线程一段时间，当在A线程的代码中遇到b.join()，此时CPU会到B线程中去执行，等B执行完后再回到A线程继续执行。感觉像把B线程加入到A线程；类似于方法调用，只不过方法调用是同一个线程
- 线程的6种状态： Thread.State.NEW、RUNNABLE、TERMINATED、TIMED_WAITING、WAITING、BLOCKED

    ![thread-state](/data/images/java/thread-state.png)

#### 锁

- [不可不说的Java“锁”事](https://mp.weixin.qq.com/s?__biz=MjM5NjQ5MTI5OA==&mid=2651749434&idx=3&sn=5ffa63ad47fe166f2f1a9f604ed10091&chksm=bd12a5778a652c61509d9e718ab086ff27ad8768586ea9b38c3dcf9e017a8e49bcae3df9bcc8&scene=38#wechat_redirect)
- 乐观锁和悲观锁 [^5]
    - 乐观锁：假设不会发生并发冲突，直接不加锁去完成某项更新，如果冲突就返回失败(认为读多写少)
    - 悲观锁：假设一定会发生并发冲突，通过阻塞其他所有线程来保证数据的完整性(认为写多读少)
    - java中的乐观锁基本都是通过`CAS`(Compare And Swap，比较并替换)操作实现的，CAS是一种更新的原子操作，比较当前值跟传入值是否一样，一样则更新，否则失败
    - 如Synchronized就是悲观锁；`AQS`框架下的锁则是先尝试cas乐观锁去获取锁，获取不到，才会转换为悲观锁，如`ReentrantLock`
- 共享锁和排他锁
    - 共享锁(读锁)：就是允许多个线程同时获取一个锁，一个锁可以同时被多个线程拥有
    - 排它锁(写锁)：也称作独占锁，一个锁在某一时刻只能被一个线程占有，其它线程必须等待锁被释放之后才可能获取到锁
    - 如ReadWriteLock可分别获得读锁和写锁
- 公平锁和非公平锁
    - 公平锁：锁前先查看是否有排队等待的线程，有的话优先处理排在前面的线程，先来先得
    - 非公平锁：线程需要加锁时直接尝试获取锁，获取不到就自动到队尾等待
    - 更多的是直接使用非公平锁：非公平锁比公平锁性能高5-10倍，因为公平锁需要在多核情况下维护一个队列，如果当前线程不是队列的第一个无法获取锁，增加了线程切换次数
- 可重入锁和非可重入锁
    - 可重入锁：一个线程中的多个流程可以获取同一把锁。就是一个加锁的代码片段调用了另外一个加锁的代码片段，如果是同一个线程被调用的第二个代码片段是可以获得第一个代码片段的锁的
    - 非可重入锁：反之
- 分段锁(一种锁的设计模式)
    - 容器里有多把锁，每一把锁用于锁容器其中一部分数据，那么当多线程访问容器里不同数据段的数据时，线程间就不会存在锁竞争，从而可以有效的提高并发访问效率
    - 对于ConcurrentHashMap(之前使用的是分段锁，后面直接使用ReentrantLock)而言，其并发的实现就是通过分段锁的形式来实现高效的并发操作。首先将数据分成一段一段的存储，然后给每一段数据配一把锁，当一个线程占用锁访问其中一个段数据的时候，其他段的数据也能被其他线程访问

#### synchronized线程同步

- **加锁方式**
    - 锁定对象(把任意一个非NULL的对象当作锁，不能使用String常量、Integer、Long等包装数据类型)
        - public synchronized void test() {...}
        - ... synchronized(this) {} ...
        - ... synchronized(o) {} ...，其中o可以为private Object o = new Object();
    - 锁定类
        - public synchronized static void test() {...}
        - ... synchronized(MyTest.class) {} ...
- 注意点
    - 锁的是对象不是代码块
    - 锁定方法和非锁定方法可同时执行
- java线程阻塞的代价
    - java的线程是映射到操作系统原生线程之上的，如果要阻塞或唤醒一个线程就需要操作系统介入，需要在户态与核心态之间切换，这种切换会消耗大量的系统资源
    - synchronized会导致争用不到锁的线程进入阻塞状态，所以说它是java语言中一个重量级的同步操纵，被称为重量级锁。为了缓解上述性能问题，JVM从1.5开始，引入了轻量锁与偏向锁，默认启用了自旋锁，他们都属于乐观锁
    - JDK早期是重量级的基于OS的锁；后来引入了锁升级的概念，synchronized通过锁升级技术达到和Atomic等类(使用自旋锁)效率差不多
- java对象markword数据部分
    - 在HotSpot虚拟机中，对象在内存中存储的布局可以分为4块区域：对象头（Header）、实例数据（Instance Data）和对齐填充（Padding）
    - HotSpot虚拟机的对象头包括两部分信息
        - markword：用于存储对象自身的运行时数据，如哈希码（HashCode）、GC分代年龄、**锁状态标志**(最后2bit)、线程持有的锁、**偏向线程ID**、偏向时间戳等，这部分数据的长度在32位和64位的虚拟机（未开启压缩指针）中分别为32bit和64bit
        - klass（也称ClassPointer?）：对象头的另外一部分是klass类型指针，即对象指向它的类元数据的指针，虚拟机通过这个指针来确定这个对象是哪个类的实例
    - **32bit操作系统markword数据结构**
        
        ![jvm-32-markword](/data/images/java/jvm-32-markword.png)
- 底层实现
    - **synchronized锁升级流程：无锁 - 偏向锁 - 轻量级锁 - 重量级**(锁是没法降级的)
        - 偏向锁：Biased Locking，是Java6引入的一项多线程优化
            - 顾名思义，它会偏向于第一个访问锁的线程，如果在运行过程中，同步锁只有一个线程访问，不存在多线程争用的情况，则线程是不需要触发同步的，这种情况下，就会给线程加一个偏向锁。如果在运行过程中，遇到了其他线程抢占锁，则持有偏向锁的线程会被挂起，JVM会消除它身上的偏向锁，将锁恢复到标准的轻量级锁
            - 偏向锁获取流程
                - 1.访问Mark Word中偏向锁的标识是否设置成1，锁标志位是否为01，确认为可偏向状态
                - 2.如果为可偏向状态，则测试线程ID是否指向当前线程，如果是，进入步骤5，否则进入步骤3
                - 3.如果线程ID并未指向当前线程，则通过CAS操作竞争锁。如果竞争成功，则将Mark Word中线程ID设置为当前线程ID，然后执行5；如果竞争失败，执行4
                - 4.如果CAS获取偏向锁失败，则表示有竞争。当到达全局安全点（safepoint，会导致stop the word，时间很短）时获得偏向锁的线程被挂起，偏向锁升级为轻量级锁，然后被阻塞在安全点的线程继续往下执行同步代码。（撤销偏向锁的时候会导致stop the word）
                - 5.执行同步代码
            - 偏向锁的释放：偏向锁只有遇到其他线程尝试竞争偏向锁时，持有偏向锁的线程才会释放锁，线程不会主动去释放偏向锁
        - 轻量级锁：如果线程争用，则升级为轻量级锁
            - 拷贝Mark Word到锁记录栈帧：在代码进入同步块的时候，如果同步对象锁状态为无锁状态（锁标志位为“01”，为偏向锁标志位为“0”），虚拟机首先将在当前线程的栈帧中建立一个名为锁记录（Lock Record）的空间，然后拷贝对象头中的Mark Word到锁记录中
            - 设置Mark Word和锁记录的Owner：拷贝成功后，虚拟机将使用CAS操作尝试将对象的Mark Word（前30位）更新为指向Lock Record的指针，并将Lock Record里的owner指针指向对象的Mark Word
            - 设置轻量级锁状态：如果这个更新动作成功了，那么这个线程就拥有了该对象的锁，并且对象Mark Word的锁标志位设置为“00”，表示此对象处于轻量级锁定状态
            - 如果轻量级锁的更新操作失败了，虚拟机首先会检查对象的Mark Word是否指向当前线程的栈帧，如果是就说明当前线程已经拥有了这个对象的锁，那就可以直接进入同步块继续执行，否则说明多个线程竞争锁
            - 若当前只有一个等待线程，则该线程通过自旋进行等待。但是当自旋超过一定的次数，或者一个线程在持有锁，一个在自旋，又有第三个来访时，轻量级锁升级为重量级锁
        - 重量级锁：JDK6之前自旋10次之后，仍然没有获取到锁，则升级为重量级锁(从OS获取锁)；JDK6开始引入自适应自旋（次数动态变化）
    - 自旋锁和系统锁(OS锁/重量级锁)
        - 自旋锁时，线程不会进入等待队列，而是定时while循环尝试获取锁，此时会占用CPU，但是加锁解锁不经过内核态因此加解锁效率高
        - 系统锁，会进入到等待队列，等待CPU调用，不占用CPU资源。CAS属于自旋锁，有的认为CAS是无锁
        - 执行时间短、线程数比较少时使用自旋锁较好；执行时间长、线程数多时用系统锁较好
- synchronized 实现细节
    - 字节码层面：修饰方法时，编译为ACC_SYNCHRONIZED；代码块中，编译为monitorenter、monitorexit(指令)
    - JVM层面：基于 C/C++ 调用了操作系统提供的同步机制
    - OS和硬件层面(X86)：lock cmpxchg(比较并交换指令)。参考 https://blog.csdn.net/21aspnet/article/details/88571740

#### volatile

- volatile作用
    - 保证线程可见性。只能观测到简单数据类型和引用的变化，如果引用指向的对象属性值(包括数组)变化了是监测不到的
    - 防止指令重排
- volatile不能替代synchronized来保证线程安全
- volatile基于**内存屏障**实现
    - 内存屏障基本概念
        - 就是一个CPU指令，包括读屏障和写屏障，主要功能：(1)确保一些特定操作执行的顺序；(2)影响一些数据的可见性(可能是某些指令执行后的结果)
        - 编译器和CPU可以在保证输出结果一样的情况下对指令重排序，使性能得到优化。插入一个内存屏障，相当于告诉CPU和编译器先于这个命令的必须先执行，后于这个命令的必须后执行
        - 内存屏障另一个作用是强制更新一次不同CPU的缓存。例如，一个写屏障会把这个屏障前写入的数据刷新到缓存，这样任何试图读取该数据的线程将得到最新值，而不用考虑到底是被哪个CPU核心或者哪颗CPU执行的。参考下文[CPU缓存一致性协议MESI](#Disruptor)
    - 如果字段是volatile，Java内存模型将在写操作后插入一个写屏障指令(storefence)，在读操作前插入一个读屏障指令(loadfence)
    - 对性能的影响主要在刷新缓存的开销上。如[Disruptor](#Disruptor)提供Batch操作实现对序列号的读写频率降到最低
- volatile 实现细节
    - 字节层面：编译后是ACC_VOLATILE
    - JVM层面：读写操作都加了内存屏障
        - StoreStoreBarrier;volatile写操作;StoreLoadBarrier;
        - LoadLoadBarrier;volatile读操作;LoadStoreBarrier;
    - OS层面：https://blog.csdn.net/qq_26222859/article/details/52235930
        - linux 基于MESI实现，windows 基于 lock 指令实现
        - hsdis(HotSpot Dis Assembler)工具可记录实际执行的汇编代码
- volatile 修饰一个对象时，只要对象任何属性有变化则会有禁止指令重排
- DLC(Double Check Lock)单例中对volatile的应用 (一#46#0:35:54)

<details>
<summary>DLC示例</summary>

```java
public class T02_DLC_Singleton {
    private static volatile T02_DLC_Singleton INSTANCE;

    private T02_DLC_Singleton() {
    }

    public static T02_DLC_Singleton getInstance() {
        // do something...
        if (INSTANCE == null) {
            // synchronized不锁定在方法上是为了减少锁定代码量
            synchronized (T02_DLC_Singleton.class) {
                // 双重检查。如果不进行双重检查，有可能出现两个线程同时进行第一次判断发现INSTANCE为空，进入到synchronized，此时会先后执行两次实例初始化
                if(INSTANCE == null) {
                    try {
                        Thread.sleep(1);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }

                    /*
                     * Object o = new Object(); 可分为4步(此处同理)
                     * 1.new #11 <java/lang/Object>：申请内存(并设置默认值，如设置此o对象的某属性为int a = 0)
                     * 2.dup
                     * 3.invokespecial #1 <java/lang/Object.<init>>：实例化对象(设置属性的初始值，a = 1)
                     * 4.astore_1：将此对象的引用赋值给变量o
                     *
                     * 如果INSTANCE不加volatile则可能出现指令重排，可能出现1-2-4-3的执行顺序(就是将没有初始化完全的对象引用提前赋值给了变量)
                     * 如果第一个线程执行按照此方式执行到第4(还未执行3)，第二个线程判断发现INSTANCE不为空(已经被赋值了引用地址)
                     * 则第二个线程可能会使用第一个线程创建的对象，此时可能使用到对象中的一些未初始化好的属性产生意想不到的结果
                     */
                    INSTANCE = new T02_DLC_Singleton();
                }
            }
        }
        return INSTANCE;
    }

    public static void main(String[] args) {
        for(int i=0; i<100; i++) {
            new Thread(()->{
                System.out.println(T02_DLC_Singleton.getInstance().hashCode());
            }).start();
        }
    }
}
```
</details>

### JUC(java.util.concurrent)同步工具

#### CAS

- CAS(Compare And Swap)
    - 进行无锁操作(有认为是无锁，也有认为是自旋锁)，本质属于乐观锁。当期望值(原值)等于要更新的值时，再进行修改；如果值不相等则循环等待
    - 最终基于`sun.misc.Unsafe`实现
        - Unsafe提供了访问底层的机制，这种机制主要供java核心类库使用。可通过反射获取Unsafe实例
        - CompareAndSwap操作：CAS基于此类操作完成
        - LockSupport.park()/unpark()：它们底层都是调用的Unsafe的这两个方法
        - 可以直接操作堆外内存：如对于方法allocateMemory(分配堆外内存，对应C中的malloc，C++中的new)和freeMemory(释放内存，对应C中的free，C++中的delete)
        - 可进行对象实例化：`User user = (User) unsafe.allocateInstance(User.class);`(只会给对象分配内存，并不会调用构造方法)
        - 修改私有字段的值：`Field age = user.getClass().getDeclaredField("age"); unsafe.putInt(user, unsafe.objectFieldOffset(age), 20);`
- **AtomicXXX、AQS 类底层都是基于CAS实现**
- ABA问题 (一#46#1:37:00)
    - 指某个对象的子引用可能在中途已经发生了变化(如果是普通数据类型则无所谓)。通俗的，如路人A的女朋友和他复合之后，中间经历了其他男人
    - 解决办法增加版本号，如AtomicStampedReference

#### AQS底层原理

- [从ReentrantLock的实现看AQS的原理及应用](https://tech.meituan.com/2019/12/05/aqs-theory-and-apply.html)
- `AQS`(AbstractQueuedSynchronizer) 
    - **基于volatile、CAS、LockSupport实现**
    - 如ReentrantLock、CountDownLatch、CyclicBarrier、ReentrantReadWriteLock、Semaphore都是基于AQS实现
    - AQS.ConditionObject实现了Condition接口，reentrantLock.newCondition()实例化此对象
- AQS数据结构

    ![aqs-structure](/data/images/java/aqs-structure.png)
    - **AQS使用一个 volatile int state 的成员变量来表示同步状态，通过内置的FIFO队列来完成资源获取的排队工作，通过CAS完成对state值的修改**
    - CLH(Craig、Landin and Hagersten，人名)队列，是单向链表，AQS中的队列是CLH变体的虚拟双向队列(FIFO)，AQS是通过将每条请求共享资源的线程封装成一个节点来实现锁的分配
- 以 ReentrantLock 为例说明AQS执行过程 [^9]

    ![aqs-reentrantlock-uml](/data/images/java/aqs-reentrantlock-uml.jpg)
    - **加入队列里是cas操作tail(尾部节点)；获取锁时先判断前一个元素是否是head(头部节点，即当前节点是第二个节点)，是则尝试获取锁，不是则等待**
    - setExclusiveOwnerThread 主要是为了记录当前获取锁的线程，对于可重入锁可以此进行判断
    - Node#waitStatus
        - 0：新结点入队时的默认状态
        - CANCELLED(1)：表示当前结点已取消调度。当timeout或被中断（响应中断的情况下），会触发变更为此状态，进入该状态后的结点将不会再变化
        - SIGNAL(-1)：表示后继结点在等待当前结点唤醒。后继结点入队时，会将前继结点的状态更新为SIGNAL
        - CONDITION(-2)：表示结点等待在Condition上，当其他线程调用了Condition的signal()方法后，CONDITION状态的结点将从等待队列转移到同步队列中，等待获取同步锁
        - PROPAGATE(-3)：共享模式下，前继结点不仅会唤醒其后继结点，同时也可能会唤醒后继的后继结点
        - 注意：负值表示结点处于有效等待状态，而正值表示结点已被取消。所以源码中很多地方用>0、<0来判断结点的状态是否正常
- 为什么 AQS 需要一个虚拟 head 节点
    - Node 类的 waitStatus 变量用于表名当前节点状态。其中SIGNAL表示当当前节点释放锁的时候，需要唤醒下一个节点，所有每个节点在休眠前，都需要将前置节点的 waitStatus 设置成 SIGNAL，否则自己永远无法被唤醒
        - 初始状态是 0
        - CANCELLED 被取消了，为1
        - SIGNAL 释放锁时，唤醒下一个节点，为-1
        - CONDITION 线程处于等待状态，为-2
        - PROPAGATE
    - AbstractQueuedSynchronizer.enq中可查看代码
- `VarHandle`类 (JDK9才有) 指向引用的变量(引用句柄)，一般开发中不会用到
    - 可对普通属性进行原子性操作
    - 比反射快，直接操纵二进制码

<details>
<summary>VarHandle示例</summary>

```java
public class T1_VarHandle {
    int x = 10;

    public static void main(String[] args) {
        T1_VarHandle t = new T1_VarHandle();

        VarHandle varHandle = null;
        try {
            // 获取T1_VarHandle.x的引用，此时相当于varHandle指向了x指向的内存
            varHandle = MethodHandles.lookup().findVarHandle(T1_VarHandle.class, "x", int.class);
        } catch (NoSuchFieldException | IllegalAccessException e) {
            e.printStackTrace();
        }

        if(varHandle != null) {
            // 取值设置
            System.out.println(varHandle.get(t)); // 10
            varHandle.set(t, 11);
            System.out.println(t.x); // 11

            // 原子性操作
            varHandle.compareAndSet(t, 11, 12); // 原子性操作，期望原值为11，需要改成12
            System.out.println(t.x); // 12

            varHandle.getAndAdd(t, 3);
            System.out.println(t.x); // 15
        }
    }
}
```
</details>

#### ReentrantLock可重入锁

- ReentrantLock可重入锁
    - ReentrantLock可替代synchronized(也是属于可重入的)
    - synchronized也是属于可重入锁，否则子类调用父类无法实现
- ReentrantLock需手动加锁lock.lock()和解锁lock.unlock()。**一般在try中加锁，finally中进行解锁(否则可能异常导致解锁失败产生死锁)**。lock.unlock()在未获得锁时执行会报异常IllegalMonitorStateException
- 与synchronized对比

    ![reentrantlock-synchronized对比](/data/images/java/reentrantlock-synchronized.png)
    - 可使用lock.tryLock(5, TimeUnit.SECONDS)进行尝试锁定，如果5秒钟之类拿到了锁则返回true
    - 可使用lock.lockInterruptibly()指定此锁为可被打断锁，之后可通过thread.interrupt()打断线程释放锁。实际测试lock.lock()也可以被打断
    - 可使用new ReentrantLock(true)创建一个公平锁(此时的true，默认为非公平锁)，synchronized是非公平锁
    - 可使用lock.newCondition()创建不同的等待队列，批量等待或唤醒某一个等待队列里面的线程
        - 返回AQS.ConditionObject对象(实现了Condition接口)
        - condition.await() 会先释放锁资源再阻塞(释放锁是await实现，阻塞线程基于LockSupport.park实现。源码中：await -> fullyRelease -> LockSupport.park)
        - condition.await() 需要在lock块中执行
- 简单使用

```java
Lock lock = new ReentrantLock();
lock.lock();
lock.unlock(); // 当前线程释放锁资源。如果当前线程没有加锁，执行会报错
lock.tryLock(5, TimeUnit.SECONDS); // 进行尝试锁定
lock.lockInterruptibly(); // 指定此锁为可被打断锁
new ReentrantLock(true); // 创建一个公平锁

Condition condition1 = lock.newCondition(); // 相当于一个等待队列。可以定义多个等待队列，来获取同一把锁，此时等待或唤醒可以基于不同的等待队列进行操作
Condition condition2 = lock.newCondition();
condition1.await(); // 让condition1队列中的线程进行等待，并且释放锁资源
condition2.signalAll(); // 唤醒condition2队列中的线程。注意不是condition2.notifyAll()
```

#### 相关类

##### Atomic相关类

- AtomicXXX相关类底层都是基于[CAS](#CAS)实现
- 当线程很大的时候(如10000个)，数递增效率：`LongAdder` > `AtomicLong` > `Synchronized`
    - LongAdder使用了分段锁，AtomicLong使用了CAS操作，而Synchronized可能会申请重量级锁

##### CountDownLatch倒数门栓

- CountDown倒数，Latch门栓，当倒数结束后，打开门栓。**和线程数无关，可在一个线程中countDown多次**
- 使用

```java
CountDownLatch latch = new CountDownLatch(10); // 初始化一个计数器

latch.countDown(); // 如当一个线程结束，则倒数一下(也可在一个线程countDown多次)
latch.await(); // 当latch倒数到0则往下执行，否则会阻塞此处
```
- 底层基于AQS实现，AQS.state此时表示计数器未完成的数量

```java
latch.countDown() 
  -> AQS.tryReleaseShared(arg)
    -> CountDownLatch.Sync.tryReleaseShared
	  -> compareAndSetState
  ->(true) doReleaseShared
	-> (AQS) LockSupport.unpark // 尝试唤醒下一个节点

latch.await()
  -> AQS.acquireSharedInterruptibly
	-> CountDownLatch.Sync.tryAcquireShared
	-> AQS.shouldParkAfterFailedAcquire
```

##### CyclicBarrier列车栅栏

- 基于ReentrantLock(基于AQS实现)实现

```java
CyclicBarrier barrier = new CyclicBarrier(10); // 计数器
...
barrier.await(); // 某个线程在等待，计数器+1；当计数器满后则释放所有线程等待。基于ReentrantLock实现
```

##### Phaser分段栅栏

- 适用一个大任务可以分为多个阶段完成，且每个阶段的任务可以多个线程并发执行，但是必须上一个阶段的任务都完成了才可以执行下一个阶段的任务
- Phaser（/'feɪzə/）相对于CyclicBarrier和CountDownLatch的优势
    - Phaser可以完成多阶段，且阶段数可以控制；而CyclicBarrier或者CountDownLatch对多阶段的控制不是很方便
    - Phaser每个阶段的任务数量可以控制，而一个CyclicBarrier或者CountDownLatch任务数量一旦确定不可修改
    - Phaser支持分层(Tiering，一种树形结构)，因为当一个Phaser有大量参与者(parties)的时候，内部的同步操作会使性能急剧下降，而分层可以降低竞争，从而减小因同步导致的额外开销
        - 如两层结构时：某个子phaser参与者全部准备就绪 -> 该子phaser通知根phaser -> 所有子phaser都就绪 -> 根phaser放行(才会释放"无锁栈"中等待着的线程，并将阶段数phase增加1)

- 使用

```java
Phaser phaser = new Phaser(); // 也可继承Phaser，重写其onAdvance方法(所有人到达栅栏时会自动调用此方法)
...
phaser.register(); // 加入一个选手
phaser.bulkRegister(10); // 批量加入选手
...
phaser.arriveAndAwaitAdvance(); // 到达此阶段，并等待其他参与者(线程)到达后进入下一个阶段
phaser.arriveAndDeregister(); // 到达此阶段并退出Phaser
```
- 结构上，主要属性有：state、evenQ、oddQ、parent、root [^8]
    - state：volatile long修饰的状态变量，long型变量总占8个字节(共有64位)。高32位存储当前阶段phase，中间16位存储参与者的数量，低16位存储未完成参与者的数量
        
        ![state存储空间分配](/data/images/java/phaser-long-state.png)  
    - evenQ(偶)和oddQ(奇)：已完成的参与者存储的队列，当最后一个参与者完成任务后唤醒队列中的参与者继续执行下一个阶段的任务，或者结束任务
        - 树的根结点root链接着两个无锁栈(Treiber Stack)，用于保存等待线程(比如当线程等待Phaser进入下一阶段时，会根据当前阶段的奇偶性，把自己挂到某个栈中)，所有Phaser对象都共享这两个栈
        - 释放线程和添加线程可能会同时进行，两个队列为了减少争用
    - parent和root(Phaser)
        - 当首次将某个Phaser结点链接到树中时，会同时向该结点的父结点注册一个参与者
- 基于volatile、CAS、LockSupport完成

##### ReadWriteLock读写锁(共享锁和排他锁)

- 读锁(共享锁，多个线程可同时获得锁)，写锁(独占锁/排他锁，同一个时刻只能一个线程拥有锁)
- ReadWriteLock为接口，其实现如ReentrantReadWriteLock，原理类似ReentrantLock都是基于AQS实现

```java
ReadWriteLock readWriteLock = new ReentrantReadWriteLock();
Lock readLock = readWriteLock.readLock(); // 读锁
Lock writeLock = readWriteLock.writeLock(); // 写锁
readLock.lock(); // 当前线程获取读锁。如果读的时候不加锁，其他线程可能会写入，导致脏读
```

##### Semaphore信号量

- Semaphore获取到信号灯(同时信号灯数量-1)的线程才可运行，释放信号灯(同时信号灯数量+1)了之后可供其他行程使用。如用在限流上
- 基于AQS实现，原理类似ReadWriteLock的共享锁

```java
Semaphore s = new Semaphore(10); // 信号灯数量，此处允许10个线程同时执行
s.acquire(); // 阻塞方法，直到获得一个信号灯(锁)才可继续执行
s.release(); // 释放得到的信号灯

Semaphore s = new Semaphore(10, true); // true表示公平锁，默认是非公平的
```

##### Exchanger交换器

```java
Exchanger<String> exchanger = new Exchanger<>();

// 对两个线程的数据进行交换，最终str1给到线程2，str2给到了线程1
ret1 = exchanger.exchange(str1); // 在线程1中执行
ret2 = exchanger.exchange(str2); // 在线程2中执行

exchanger.exchange(V x, long timeout, TimeUnit unit) // 设置超时时间
```

##### LockSupport

- **unpark可以在park之前调用，此时park执行也不会阻塞**
- 它们底层都是调用的Unsafe的这两个方法

```java
LockSupport.park(); // 阻塞当前线程，线程进入到WAITING状态，并不是锁
LockSupport.unpark(thread); // 将thread线程解除阻塞。unpark可以基于park之前调用，且等到park后执行时也不会阻塞
```

#### 面试题

- t1线程负责打印1-10，t2线程负责监控；当t1打印到5时，t2进行提示并结束。可通过如下方式实现
    - wait，notify、volatile
    - LockSupport、volatile
- t1、t2两个线程，t1线程负责打印A-Z，t2线程负责打印1-26，如何交替打印A1B2...Z26
    - wait，notify、volatile
    - LockSupport、volatile
- 写一个固定容量同步容器，拥有put和get方法，能够支持2个生产者线程以及10个消费者线程的阻塞调用
    - synchronized，wait，notiyAll
    - ReentrantLock，Condition

#### ThreadLocal

- Java引用类型：**强软弱虚**(一#62#1:15:34)
    - 强引用：又称普通引用，当每有强引用指向该对象时，该对象才会被垃圾回收。即Object o = new Object();为强引用，当 o = null 时，上述对象才会(此对象没有其他引用)被GC回收
    - 软引用(SoftReference)：一个对象如果只被软引用对象指向时，当内存不足时(可指定IDEA的VM参数如-Xms20M -Xmx20M)才会回收该对象(且没有其他强引用)，否则不会回收。主要用在缓存
    - **弱引用**(WeakReference)
        - 只要遭遇到GC就会被回收
        - 如果一个对象除了被弱引用指向，还被一个强引用指向时，当强引用消失后，这个对象也会被回收，**如ThreadLocal中使用了这个特性**
        - 弱引用一般还用在Java容器中，**如WeakHashMap**
    - 虚引用(PhantomReference, /ˈfæntəm/)，如：`new PhantomReference<>(new Z(), referenceQueue)`
        - 遇到GC时，虚引用肯定被回收。当虚引用被回收时，只会将此引用放入到相应队列，从而可监测队列来获取垃圾回收虚引用的通知
        - 主要管理堆外内存，如当虚引用被回收时，通过监控ReferenceQueue来获取通知，从而进行堆外内存清理。使用场景如底层在实现JVM时会使用，Netty也会使用
        - 无法通过虚引用获取指向的对象的值
- set()方法最终将数据放到当前Thread的Map对象(ThreadLocal.ThreadLocalMap)中；get()方法则从中取数据；remove()从溢ThreadLocalMap中移除此ThreadLocal对象，防止内存泄露
- ThreadLocal用途
    - 如声明式事务，保证同一个Connection。不同的方法拿Connection时先从ThreadLocal中获取连接，防止拿到的Connection不是同一个对象
- 源码

    ```java
    // ThreadLocal.java
    public void set(T value) {
        Thread t = Thread.currentThread(); // 获取当前线程对象
        ThreadLocalMap map = getMap(t); // Thread中保存的ThreadLocal.ThreadLocalMap threadLocals属性值
        if (map != null) {
            map.set(this, value); // 设值
        } else {
            createMap(t, value);
        }
    }

    static class ThreadLocalMap {
        // 继承WeakReference弱引用
        static class Entry extends WeakReference<ThreadLocal<?>> {
            /** The value associated with this ThreadLocal. */
            Object value;

            Entry(ThreadLocal<?> k, Object v) {
                super(k); // 将key(this thread)保存为弱引用
                value = v;
            }
        }

        private Entry[] table;

        // ...
    }
    ```
- 原理图

    ![threadlocal-weakreference](/data/images/java/threadlocal-weakreference.png)
    - 当线程创建后，此Thread对象则会包含一个属性threadLocals(ThreadLocal.ThreadLocalMap)，则会在线程栈中创建此引用变量
    - 创建ThreadLocal对象时，会有一个强引用tl1指向此对象
    - 执行tl1.set时，会将数据对象保存到obj1，且value1指向此对象。**由于ThreadLocal.ThreadLocalMap的Entry对象继承了WeakReference，且将Key保存在此需引用对象中，因此会有一个虚引用key1也指向此ThreadLocal**(上文源码中`map.set(this, value);`)
    - 如果key1为强引用，当tl1 = null时，则仍然由一个强引用key1执行该ThreadLocal对象，从而导致ThreadLocal无法被回收；如果此线程结束，则threadLocals执行的Map被回收，此时ThreadLocal也被回收；但是有一些线程是守护线程，或者执行时间很长的线程，则很难回收ThreadLocal对象，从而导致内存泄露(指有块内存永远无法被回收；不同于OOM内存溢出，OOM指内存不足)；**因此key1需要使用虚引用**
    - 当key1为虚引用时，tl1 = null，从而ThreadLocal对象被回收，此时key1也会变为null，那么value1指向的对象将无法被访问到，从而也容易出现内存泄露；**因此使用完ThreadLocal需要执行tl1.remove()清理**

### 容器

- 发展历史
    - 最早的容器(1.0)：Vector，Hashtable
        - 其中Vector实现了List接口，Hashtable实现了Map接口，他们的缺点是所有的方法都加了synchronized了(有些场景不需要加锁，所有此场景效率低)
        - 现在基本不用
    - 后来增加了HashMap，此类的方法全部无锁。Map map = Collections.synchronizedMap(new HashMap()); 返回一个加锁的HashMap(仍然基于synchronized实现)，通过此方式使HashMap可以适用加锁和无锁的场景
    - 直到现在的ConcurrentHashMap、Queue等
- 有界队列和无界队列
    - 有界队列：就是有固定大小的队列。比如设定固定大小的 LinkedBlockingQueue
    - 无界队列：指的是没有设置固定大小的队列。这些队列的特点是可以直接入列，直到溢出。当然现实几乎不会有到这么大的容量(超过 Integer.MAX_VALUE)，所以从使用者的体验上，就相当于"无界"。比如没有设定固定大小的 LinkedBlockingQueue
    - 一般情况下要配置一下队列大小，设置成有界队列，否则JVM内存会被撑爆

#### 容器分类

- Collection 主要用来放单个对象，其子接口
    - List
        - Vector 线程安全(使用synchronized)
            - Stack 栈，为LIFO(后进先出)
        - **ArrayList**
        - **LinkedList** 链表插入快，遍历慢
        - **CopyOnWriteArrayList** 写入时通过synchronized加锁，取出不会(也不用)加锁，因此读快写慢；每次add是通过Arrays.copyOf复制出一个新数组
    - Set
        - **HashSet** 类
            - **LinkedHashSet** 类
        - SortedSet 接口
            - **TreeSet** 为有序Set，默认找元素大小排序，可定义比较器；TreeSet 中的元素必须实现Comparable接口并重写compareTo()方法；线程不安全
        - EnumSet
        - **CopyOnWriteArraySet** 线程安全，具体参考[Copy-On-Write写时复制](/_posts/linux/计算机底层知识.md#Copy-On-Write写时复制)
        - CopyOnWriteSkipListSet
    - Queue 高并发较常用
        - 相关方法(ABQ为例)
            - `add` 添加，超过集合容量会报错：java.lang.IllegalStateException: Queue full
            - `offer` 添加，超过集合容量则不再放入，**也不报错，线程不会阻塞，返回是否放入成功**
            - `remove` 移除头部元素并返回此元素，如果没有则抛出异常java.util.NoSuchElementException
            - `poll` 移除头部元素并返回此元素，如果没有则返回null
            - `element` 获取头部元素，如果没有则抛出异常
            - `peek` 获取头部元素，如果没有则返回null
        - **BlockingQueue**(接口) 天然的生产者消费者模型，线程池中会使用到
            - 相关方法(ABQ为例)
                - `put` (设计上)放入元素，**满了会阻塞等待**
                - `take` (设计上)移除头部元素并返回此元素，没有则阻塞等待
            - **ArrayBlockingQueue(ABQ)** 基于ReentrantLock加锁
                - put入队阻塞，take出队阻塞
            - LinkedBlockingQueue
            - PriorityBlockingQueue 基于优先级的队列，内部有一个排序器(放入的元素必须实现Comparable接口)
                - **put入队不阻塞(调用offer)，take出队阻塞**
                - heap结构(堆，用数组实现的完全二叉树)，无界队列
            - DelayQueue 延迟队列(类)
                - **put入队不阻塞，take出队阻塞**
                - 队列中的元素必须是实现Delayed接口，队列中的元素不但会按照延迟时间delay进行排序，且只有等待元素的延迟时间delay到期后才能出队
                - 常用于基于时间的任务调度，等待时间段的先执行
                - heap结构，无界队列
            - TransferQueue(接口)
                - `transfer` 方法相比put的区别是，**放入元素后，直到被取走，否则一直阻塞等待**
                - LinkedTransferQueue **无锁(cas)**
            - SynchronousQueue 同步Queue(类)
                - 当调用put放入元素后，如果没有被取走(take)，则put后会一致等待直到take拿走元素
                - 底层基于TransferQueue实现，类似于Exchanger可作线程间数据交换
                - 队列的容量为0，不能往里面直接add元素，会报错
        - **ConcurrentLinkedQueue** 类，**无锁(cas)**，线程安全，无界队列。JDK中没有ConcurrentArrayQueue
        - Deque 是double ended queue的简称，习惯上称之为**双端队列**(头尾均可加入取出元素)。发音为/dek/
            - 当作为队列使用时，为FIFO(先进先出)模型，对应使用方法
                - addLast
                - offerLast
                - removeFirst
                - pollFirst
                - getFirst
                - peekFirst
                - removeLast
                - ...
            - 当作为栈使用时，为LIFO(后进先出)模型，此接口优于传统的Stack类，对应使用方法
                - addFirst(push调用的addFirst)
                - offerFirst
                - removeFirst(同上)
                - pollFirst
                - ...
            - ArrayDeque 数组类型的双端队列，线程不安全
            - BlockingDeque 接口
                - LinkedBlockingDeque 线程安全
        - 其他
            - PriorityQueue 并未实现Queue接口，为java.util.PriorityQueue类，线程不安全(线程安全考虑可使用PriorityBlockingQueue)；最小的先执行，内部是一个堆排序的二叉树
- Map 用来放Key-Value型数据
    - Hashtable 线程安全，put方法上加synchronized
    - **HashMap** 线程不安全，put后最终map.size()可能大于实际值
        - **LinkedHashMap**
    - **TreeMap**
    - **ConcurrentHashMap** 线程安全，put过程中使用synchronized
    - WeakHashMap 使用弱引用保存Key对象。当使用 WeakHashMap 时，即使没有删除任何元素，它的size、get方法返回值也可能不一样
    - IdentityHashMap 基于地址来的判断key值是否相同的(==判断的是地址，equals判断的是hashcode)；HashMap的key值是否相同是基于key的hashcode值来的
    - ConcurrentSkipListMap

#### ArryaList和LinkedList

- 查询：ArrayList可直接通过下标查找数据(并且数据组对处理的缓存机制较友好，缓存行每次会读取相邻数据以撑满)，而LinkedList的链表需要遍历每个元素直到找到为止，因此查询时ArrayList性能高
- 插入：ArrayList是单向链表，底层是数组存储形式，如果在List中添加完元素之后，导致超过底层数组的长度，就会垃圾回收原来的数组，并且用System.copyArray赋值到新的数组当中，这开销就会变大(复制和实例化新数组)。而LikedList在插入时候，明显高于ArrayList，因为LinkedList是双向链表，只需要修改指针即可完成添加和删除元素
- 删除：ArrayList 整体的会向前移动一格，然后再要删除的index位置置空操作，ArrayList的remove要比add的时候更快，因为不用再复制到新的数组当中了。LikedList 的remove操作相对于ArrayList remove更快
- 使用与场景：如果查询较多可以使用ArrayList；但是如果是经常进行插入，删除操作可使用LinkedList

#### HashMap和HashTable

- 添加元素流程 [^10]
    - 判断 `table[]` 是否为空，为空则进行初始化(resize)
    - 根据键值key计算hash值得到插入的数组索引 i，判断`table[i]`是否有值，无则直接添加
    - 判断`table[i]`的首个元素是否和key一样，如果相同直接覆盖value 
    - 判断`table[i]`是否为treeNode，即`table[i]`是否是红黑树，如果是红黑树，则直接在树中插入键值对
    - 不为红黑树时，判断链表长度是否大于8，大于8的话把链表转换为红黑树，在红黑树中执行插入操作；否则进行链表的插入操作（插入在头部），若发现key已经存在直接覆盖value即可
    - 添加完成，判断元素个数是否超过集合阈值，超过则进行扩容
- HashMap 容量起始值为16，负载因子为0.75，扩容时增加2n个元素
- 为什么哈希表的容量一定要是2的整数次幂 [^11]
    - 首先，length为2的整数次幂的话，**`h&(length-1)`就相当于对length取模**，这样便保证了散列的均匀，同时也提升了效率
    - 其次，length为2的整数次幂的话，为偶数，这样length-1为奇数，奇数的最后一位是1，**这样便保证了h&(length-1)的最后一位可能为0，也可能为1（这取决于h的值）**，即与后的结果可能为偶数，也可能为奇数，这样便可以保证散列的均匀性。而如果length为奇数的话，很明显length-1为偶数，它的最后一位是0，这样 h&(length-1) 的最后一位肯定为0，即只能为偶数，这样任何hash值都只会被散列到数组的偶数下标位置上，这便浪费了近一半的空间。因此，length取2的整数次幂，是为了使不同hash值发生碰撞的概率较小，这样就能使元素在哈希表中均匀地散列
- HashMap源码（JDK1.8）

```java
public V put(K key, V value) {
    // hash(key) 内部为 return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
    return putVal(hash(key), key, value, false, true);
}

final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
    else {
        Node<K,V> e; K k;
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) {
                    p.next = newNode(hash, key, value, null);
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;
                }
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    break;
                p = e;
            }
        }
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

#### 线程安全队列说明

- 具体见上文容器分类中Queue
- Queue和List的区别
    - Queue主要加入了一些线程友好的API，如offer、poll、peek
    - Queue的子类BlockingQueue又加入了put、take
- 常用的线程安全队列

    ![juc-queue](/data/images/java/juc-queue.png)
    - 队列的底层一般分成三种：数组、链表和堆。其中，堆一般情况下是为了实现带有优先级特性的队列
    - ConcurrentLinkedQueue 和 LinkedTransferQueue 都是通过原子变量compare and swap(CAS)这种不加锁的方式来实现的
    - 通过不加锁的方式实现的队列都是无界的(无法保证队列的长度在确定的范围内)；而加锁的方式，可以实现有界队列。在稳定性要求特别高的系统中，为了防止生产者速度过快，导致内存溢出，只能选择有界队列；同时，为了减少Java的垃圾回收对系统性能的影响，会尽量选择array/heap格式的数据结构
    - 下文提到的[Disruptor](#Disruptor)中使用的是环形队列+cas，性能极高

### 线程池

- Executor 接口(java.util.concurrent.Executor)
    - execute
    - ExecutorService 接口
        - `submit` 异步执行线程，返回Future。如 Future future = executorService.submit(callable);
        - shutdown 停止，不再接受新的任务，但是会把队列中的任务执行完成才停止。如果不执行shutdown则主线程会一直处于阻塞状态
        - shutdownNow 立即停止，会给未执行完的任务发送一个interrupted指令
        - AbstractExecutorService
            - **ThreadPoolExecutor**
            - **ForkJoinPool**
        - ScheduledExecutorService 接口
            - **ScheduledThreadPoolExecutor**
            - `schedule` 方法，类似submit异步提交任务，返回ScheduledFuture
- Callable
    - call 类似于run，call有返回值，而run没有
    - 类似于Runnable。区别是Callable有返回值，而Runnable没有；且不能通过new Thread执行，可通过ExecutorService调用，如executorService.submit(callable)
- Future
    - get 获取返回结果，阻塞方法
    - **FutureTask** 实现了RunnableFuture接口，是Runnable和Future接口的合体
    - CompletableFuture 可方便管理多个Future结果
        - CompletableFuture.supplyAsync(Runnable) 返回CompletableFuture对象
        - CompletableFuture.allOf 所有任务完成了之后
- Executors 线程池工具类，见下文
- 线程池主要分为ThreadPoolExecutor和ForkJoinPool两种类型

#### ThreadPoolExecutor

- 继承自AbstractExecutorService(实现了ExecutorService接口 ==> 实现了Executor接口)
- **7个参数**
    - corePoolSize 核心线程数，一般即使不使用也不归还给系统
    - maximumPoolSize 最大线程数
    - keepAliveTime 生存时间，超过此时间没有使用则归还给系统
    - 生存时间单位
    - 线程队列
        - 如：ArrayBlockingQueue
    - 线程工厂
        - 可使用Executors.defaultThreadFactory()获取默认提供的DefaultThreadFactory，也可自己实现ThreadFactory
    - 拒绝策略
        - 线程数忙，且线程队列忙，则执行拒绝策略
        - 默认类型(也可自定义)
            - Abort 抛异常。new ThreadPoolExecutor.AbortPolcy()
            - Discard 丢弃，不抛异常
            - DiscardOldest 丢弃排队时间最久的
            - CallerRuns 调用者(调用execute方法的线程)处理任务
- 线程池调度过程
    - 线程池实例化后创建核心线程
    - 核心线程使用完后，新线程则放入到任务队列(此时是放到队列而不是启动新线程)
    - 如果还有新线程，则启动新线程来处理
    - 如果还有新线程，线程数也达到指定的最大值，且线程队列满了，则执行拒绝策略
    - 线程不使用了则归还线程数，最终保留核心线程数
- Executors可调用以下方法获得ExecutorService对象
    - newSingleThreadExecutor 只有一个线程(核心和最大线程数都为1)的线程池，**其队列为LinkedBlockingQueue无界队列**(容易内存溢出)
    - newFixedThreadPool 固定线程数的线程池(核心和最大线程数都为指定值)，且队列为LinkedBlockingQueue无界队列，如用于线程数比较平稳的常见
    - newCachedTreadPoll 核心线程数为0，**最大线程数为Integer.MAX_VALUE**，线程队列为SynchronousQueue(只有元素被取走了才能继续放元素)，如用于线程数波动比较大的场景
    - newScheduledThreadPool 用于执行定时任务的线程池，实际用定时任务中间件较多。最大线程数为Integer.MAX_VALUE，线程队列为 DelayedWorkQueue
    - newWorkStealingPool 创建一个具有抢占式操作的线程池，JDK1.8新增，基于ForkJoinPool实现。适合使用在很耗时的操作
- 阿里开发者手册不建议使用JDK自带线程池，主要原因是自带线程池的线程队列最大为Integer.MAX_VALUE，容易出现OOM，而且线程数太多，会竞争CPU，浪费时间在上下文切换上；且一般也建议自定义拒绝策略？
- 完整示例

```java
@Bean
public ExecutorService myExecutorService() {
    ThreadFactory threadFactory = new ThreadFactoryBuilder().setNameFormat("my-pool-%d").build();
    return new ThreadPoolExecutor(5, 200, 0, TimeUnit.MILLISECONDS,
            new LinkedBlockingQueue<Runnable>(1024), threadFactory, new ThreadPoolExecutor.AbortPolicy());
}
```
- ThreadPoolExecutor源码解析

#### ScheduledThreadPoolExecutor

- 继承了 ScheduledExecutorService 和 ThreadPoolExecutor，也就是说其拥有schedule()、execute()和submit()提交任务的基础功能
- 能够延时执行任务和周期执行任务的功能
- 两个重要的内部类：DelayedWorkQueue 和 ScheduledFutureTask
    - DelayedWorkQueue 实现了BlockingQueue接口，也就是一个阻塞队列
    - ScheduledFutureTask 则是继承了FutureTask类，也表示该类用于返回异步任务的结果

#### ForkJoinPool

- ForkJoin思想：将大任务分解成小任务(Fork)，最后进行汇总(Join)
    - ForkJoinPool 类，中放的Task为ForkJoinTask
    - ForkJoinTask 抽象类(implements Future)，一般使用时手动继承RecursiveAction或RecursiveTask两个抽象类
        - RecursiveAction 抽象类(Recursive递归，当任务不够时可一直切分)，无返回值
        - RecursiveTask 抽象类，有返回值
- Executors中基于ForkJoinPool实现线程池的方法
    - newWorkStealingPool 每个线程有自己单独的队列，当某个线程的队列消耗完后则从其他线程队列中拿任务(任务窃取算法)
    - 方法
        - push 将任务放到线程队列
        - pop 从线程队列拿任务
        - poll 从其他线程队列拿任务，需要加锁
- ParallelStream API [^7]
    - Stream(流)是JDK8中引入的一种类似与迭代器(Iterator)的单向迭代访问数据的工具。ParallelStream则是并行的流，它通过Fork/Join 框架(JSR166y)来拆分任务(本质是基于ForkJoinPool实现)，加速流的处理过程。如list.parallelStream()，普通的流式是list.stream()
    - ParallelStream使用了线程名为ForkJoinPool.commonPool-worker-*的线程，而这些线程来自于 ForkJoinPool#makeCommonPool (由此也可说明底层使用了ForkJoinPool)。也可能将main线程作为执行线程
    - **ParallelStream是阻塞的**
    - **ParallelStream是多线程，因此注意线程安全，如内部使用ArrayList容易出现线程安全问题**
    - 其性能测试可参看[下文JMH测试工具的示例](#JMH测试工具)

<details>
<summary>ParallelStream示例</summary>

```java
public class T01_ParallelStream {
    public static void main(String[] args) {
        // ParallelStream的执行线程来自于ForkJoinPool#makeCommonPool中的线程或main线程
        testPrintParallelStreamThreadName();

        // ParallelStream是多线程，注意线程安全
        testThreadSafe();
    }

    public static void testPrintParallelStreamThreadName() {
        List<Integer> lists = Lists.newArrayList();
        for (int i = 0; i < 10000; i++) {
            lists.add(i);
        }

        // 普通的循环
        // [main]
        Set<String> sequenceThreadNameSet = Sets.newHashSet();
        lists.forEach(e -> sequenceThreadNameSet.add(Thread.currentThread().getName()));
        System.out.println(sequenceThreadNameSet);

        // ParallelStream使用了线程名为ForkJoinPool.commonPool-worker-*的线程，而这些线程来自于 ForkJoinPool#makeCommonPool (由此也可说明底层使用了ForkJoinPool)。也可能将main线程作为执行线程
        // [ForkJoinPool.commonPool-worker-1, ForkJoinPool.commonPool-worker-2, main, ForkJoinPool.commonPool-worker-3, ForkJoinPool.commonPool-worker-4]
        Set<String> parallelThreadNameSet = Sets.newHashSet();
        lists.parallelStream().forEach(e -> parallelThreadNameSet.add(Thread.currentThread().getName()));
        System.out.println(parallelThreadNameSet);
    }

    // 此方法执行可能会报错，或者parallelStorage可能产生null
    public static void testThreadSafe() {
        List<Integer> nums = new ArrayList<>();
        for (int i = 0; i <100; i++) {
            nums.add(i);
        }

        // parallelStorage可能产生null，因为在ArrayList中存储数据的过程不是一个线程安全的过程导致的
        List<Integer> parallelStorage = new ArrayList<>();
        nums
            .parallelStream()
            .filter(i->i%2==0)
            .forEach(i->parallelStorage.add(i));

        // 此处为了将null打印在前面。如：null null 0 2 4 6 8 10 12 ...
        parallelStorage
            .stream()
            .sorted((o1, o2) -> {
                if (o1 == null) {
                    return -1;
                } else if (o2 == null) {
                    return 1;
                } else {
                    return o1 > o2 ? 1 : o1.equals(o2) ? 0 : -1;
                }
            })
            .forEach(e -> System.out.print(e + " "));
    }
}
```
</details>

### JMH测试工具

- JMH(Java Microbenchmark Harness)，为Java微基准测工具，[官网](http://openjdk.java.net/projects/code-tools/jmh/) [^6]
- 依赖

```xml
<!-- https://mvnrepository.com/artifact/org.openjdk.jmh/jmh-core -->
<dependency>
    <groupId>org.openjdk.jmh</groupId>
    <artifactId>jmh-core</artifactId>
    <version>1.21</version>
</dependency>

<!-- https://mvnrepository.com/artifact/org.openjdk.jmh/jmh-generator-annprocess -->
<dependency>
    <groupId>org.openjdk.jmh</groupId>
    <artifactId>jmh-generator-annprocess</artifactId>
    <version>1.21</version>
    <scope>test</scope>
</dependency>
```
- 安装IDEA插件：JMH plugin
- 由于JMH用到了注解，需要打开IDEA运行程序注解配置：Build - compiler -> Annotation Processors -> Enable Annotation Processing
- 注解
    - `@Benchmark ` 方法注解，表示该方法是需要进行 benchmark 的对象
    - `@BenchmarkMode(Mode.Throughput)` 不同的测量的维度或测量方式
        - Throughput 整体吞吐量
        - AverageTime 调用的平均时间
        - SampleTime 随机取样，最后输出取样结果的分布，例如"99%的调用在xxx毫秒以内，99.99%的调用在xxx毫秒以内"
        - SingleShotTime 以上模式都是默认一次 iteration 是 1s，唯有 SingleShotTime 是只运行一次。往往同时把 warmup 次数设为0，用于测试冷启动时的性能
    - `@Warmup(iterations = 1, time = 3)` 进行预热1次，执行3秒。因为 JVM 的 JIT 机制的存在，如果某个函数被调用多次之后，JVM 会尝试将其编译成为机器码从而提高执行速度。为了让 benchmark 的结果更加接近真实情况就需要进行预热
    - `@Measurement(iterations = 10, time = 3)` 执行10次测试，执行3秒
    - `@Fork(5)` 进行 fork 的次数，可用于类或者方法上。如此时 JMH 会 fork 出5个进程来进行测试
- [官方样例](http://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/)

<details>
<summary>JMH示例</summary>

```java
// 被测试类方法
public class T01_PS {
    private static List<Integer> nums = new ArrayList<>();

    static {
        Random r = new Random();
        for (int i = 0; i < 1000; i++) {
            nums.add(1000000 + r.nextInt(1000000));
        }
    }

    static void foreach() {
        nums.forEach(T01_PS::isPrime);
    }

    // 内部使用了ForkJoinPool
    static void parallelStreamForeach() {
        nums.parallelStream().forEach(T01_PS::isPrime);
    }

    // 判断是否为质数
    static boolean isPrime(Integer num) {
        for (int i=2; i<=num/2; i++) {
            if(num % i == 0) {
                return false;
            }
        }
        return true;
    }
}

// 测试类，放在maven的test文件夹下
/**
 * Benchmark                              Mode  Cnt  Score   Error  Units
 * T01_PSTest.testForeach                thrpt    5  0.289 ± 0.099  ops/s
 * T01_PSTest.testParallelStreamForeach  thrpt    5  0.968 ± 1.460  ops/s
 */
@Warmup(iterations = 1, time = 3)
@Fork(5)
@BenchmarkMode(Mode.Throughput)
@Measurement(iterations = 1, time = 3) // 此处只执行1此，实际iterations可设置大些
public class T01_PSTest {

    @Benchmark
    public void testForeach() {
        T01_PS.foreach();
    }

    @Benchmark
    public void testParallelStreamForeach() {
        T01_PS.parallelStreamForeach();
    }
}
```
</details>

### Disruptor

- [官网](http://lmax-exchange.github.io/disruptor/)、[github](https://github.com/LMAX-Exchange/disruptor)、[原理相关](https://ifeve.com/disruptor/)
- Disruptor
    - 是英国外汇交易公司LMAX开发的一个高性能队列，研发的初衷是解决内存队列(Kafka等为分布式队列)的延迟问题，为目前单机最快MQ，基于事件驱动
    - 使用无锁(cas获取游标)，环形数组(RingBuffer)，直接覆盖(不用清除)旧数据，降低GC频率，实现了基于事件的生产者消费者模式(观察者模式)
    - 目前，包括Apache Storm、Camel、Log4j2在内的很多知名项目都应用了Disruptor以获取高性能
- ArrayBlockingQueue相比Disruptor的缺陷
    - 加锁：多线程情况下，加锁通常会严重地影响性能，通常加锁比CAS性能要差
    - [伪共享](https://www.cnblogs.com/cyfonly/p/5800758.html)
        - 参考[计算机底层知识.md#三级缓存和伪共享](/_posts/linux/计算机底层知识.md#三级缓存和伪共享)
        - ArrayBlockingQueue有三个成员变量：takeIndex需要被取走的元素下标，putIndex可被元素插入的位置的下标，count队列中元素的数量。这三个变量很可能放到一个缓存行中，但是之间修改没有太多的关联。所以每次修改，都会使之前(一级)缓存的数据失效，从而不能完全达到共享的效果
        - 解决伪共享：采用缓存行填充(空间换时间)，JDK8开始可以使用@Contended注解(需加JVM参数：-XX:-RestrictContended)来避免伪共享。Disruptor就是通过缓存行填充实现，如其[Sequence](https://github.com/LMAX-Exchange/disruptor/blob/46f57d94a188c2d9347e2aa0975e20332b0ae39a/src/main/java/com/lmax/disruptor/Sequence.java#L28)
- Disruptor提供Batch操作实现对序列号的读写频率降到最低，主要考虑到sequence.value为volatile修饰，批量操作可以减少volatile产生的内存屏障，从而减少同步缓存
- 依赖

```xml
<dependency>
    <groupId>com.lmax</groupId>
    <artifactId>disruptor</artifactId>
    <version>3.4.2</version>
</dependency>
```

<details>
<summary>Disruptor示例</summary>

```java
/**
 * 打印：
 * 0
 * 1
 * 2
 * ...
 */
public class Main {
    public static void handleEvent(MyEvent event, long sequence, boolean endOfBatch) {
        System.out.println(event.get());
    }

    public static void translate(MyEvent event, long sequence, ByteBuffer buffer) {
        event.set(buffer.getLong(0));
    }

    public static void main(String[] args) throws InterruptedException {
        // Specify the size of the ring buffer, must be power of 2. (长度为2的n次幂，利于二进制计算)
        int bufferSize = 1024;
        // 使用Lambda传入EventFactory，也可手动实现EventFactory接口再传入
        Disruptor<MyEvent> disruptor = new Disruptor<>(MyEvent::new, bufferSize, DaemonThreadFactory.INSTANCE);
        disruptor.handleEventsWith(Main::handleEvent);
        disruptor.start();

        // 获取环形队列并往其中放值(产生事件)
        // Get the ring buffer from the Disruptor to be used for publishing.
        RingBuffer<MyEvent> ringBuffer = disruptor.getRingBuffer();
        ByteBuffer bb = ByteBuffer.allocate(8);
        for (long l = 0; true; l++) {
            bb.putLong(0, l);
            // 不推荐。原因是这是一个capturing lambda, 每一个lambda会产生一个对象来承接bb，这样会产生大量的小对象
            // ringBuffer.publishEvent((event, sequence) -> event.set(bb.getLong(0)));
            
            // 推荐
            ringBuffer.publishEvent(Main::translate, bb);
            Thread.sleep(1000);
        }
    }
}

public class MyEvent {
    private long value;

    public long get() {
        return value;
    }

    public void set(long value) {
        this.value = value;
    }
}
```
</details>

- ProducerType生产者线程模式
    - 包括Producer.MULTI(会加锁)和Producer.SINGLE(不会加锁)
    - 默认是MULTI，表示在多线程模式下产生sequence；如果确认是单线程生产者，那么可以指定SINGLE，效率会提升
    - 如果是多个生产者(多线程)，但模式指定为SINGLE，则会出现线程不安全问题
- (消费者)等待策略
    - BlockingWaitStrategy(常用)：通过线程阻塞的方式，等待生产者唤醒，被唤醒后，再循环检查依赖的sequence是否已经消费
    - SleepingWaitStrategy(常用): sleep
    - YieldingWaitStrategy(常用)：尝试100次，然后Thread.yield()让出cpu
    - BusySpinWaitStrategy：线程一直自旋等待，可能比较耗cpu
    - LiteBlockingWaitStrategy：线程阻塞等待生产者唤醒。与BlockingWaitStrategy相比，区别在signalNeeded.getAndSet，如果两个线程同时访问，一个访问waitfor，一个访问signalAll时，可以减少lock加锁次数
    - LiteTimeoutBlockingWaitStrategy：与LiteBlockingWaitStrategy相比，设置了阻塞时间，超过时间后抛异常
    - TimeoutBlockingWaitStrategy：相对于BlockingWaitStrategy来说，设置了等待时间，超过后抛异常
    - PhasedBackoffWaitStrategy：根据时间参数和传入的等待策略来决定使用哪种等待策略
- 消费者异常处理
    - disruptor.setDefaultExceptionHandler()
    - disruptor.handleExceptionFor().with()

### 线程不安全常见问题

- SimpleDateFormat为线程不安全，《阿里巴巴 Java 开发手册》也明确了此类的使用
    - 例如在Filter中使用SimpleDateFormat静态变量进行数据日期格式化时，会产生问题。Filter中会出现多线程访问
    - 原因：多个线程之间共享变量calendar，并修改calendar。如调用format方法时，多个线程会同时调用calender.setTime方法
    - 解决
        - 将SimpleDateFormat定义成局部变量。尽量不要定义为static属性，非static属性时不要在多个线程中共用
        - 或者加锁
        - 使用ThreadLocal
        - 使用LocalDateTime代替Date，从而使用DateTimeFormatter进行格式化(JDK8)
            - String dateNow = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss"));

## 常用类

### ExecutorService [^1]

- `java.util.concurrent.ExecutorService` **接口**表述了异步执行的机制，并且可以让任务在后台执行。一个 ExecutorService 实例因此特别像一个线程池。事实上，在 java.util.concurrent 包中的 ExecutorService 的实现就是一个线程池的实现
- ExecutorService接口继承了`Executor`接口，其实现类如下
    - `ThreadPoolExecutor`(见下文)
    - `ScheduledThreadPoolExecutor`
- ExecutorService有如下方法
    - `execute(Runnable)` **以异步方式执行**，参数接收的Runnable实例任务线程，主线程中无法获取任务结果。可能出现主线提前结束导致JVM退出，致使子线程未运行完成。可结合`CountDownLatch`类实现阻塞主线程直到子线程完成
    - `submit(Runnable)` 与execute不同的是submit会返回一个 `Future` 对象(可以用于判断 Runnable 是否结束执行)。调用`Future.get()`则等价于同步执行
    - `submit(Callable)` 接收的 Callable 的实例与 Runnable 的实例很类似，但是 Callable.call() 方法可以返回一个结果，Runnable.run() 则不能返回结果；其返回的结果可以被 Future 对象接收。**调用`Future.get()`后，主线程会等待结果返回才会继续执行，此时等价于同步执行；如果不调用`Future.get()`则主线程不会阻塞**
    - `invokeAny(...)` 收一个包含 Callable 对象的集合作为参数，不会返回 Future 对象，而是**随机**返回集合中某一个 Callable 对象的结果；**如果一个任务运行完毕或者抛出异常，方法会取消其它的 Callable 的执行**
    - `invokeAll(...)` 会调用存在于参数集合中的所有 Callable 对象，并且返回一个包含 Future 对象的集合；可以通过这个返回的集合来得知每个 Callable 的是否执行完成(无法得知是出错提前完成还是执行成功)。**主线程会阻塞在invokeAll调用后等待所有子线程结束**
- ExecuteService服务的关闭
    - 当使用 ExecutorService 完毕之后应该关闭它，这样才能保证线程不会继续保持运行状态
    - 如果程序通过 main() 方法启动，并且主线程退出了，如果你还有一个活动的 ExecutorService 存在于程序中，那么程序将会继续保持运行状态。存在于 ExecutorService 中的活动线程会阻止Java虚拟机关闭。对于`execute(Runnable)`中的子线程不能阻止JVM退出
    - 为了关闭在 ExecutorService 中的线程，需要调用 `shutdown()` 方法。ExecutorService 并不会马上关闭，而是不再接收新的任务，一但所有执行当前任务的线程结束，ExecutorServie 才会真的关闭。**所有在调用 shutdown() 方法之前提交到 ExecutorService 的任务都会执行**
    - 立即关闭 ExecutorService，可以调用 `shutdownNow()` 方法。这个方法会尝试马上关闭所有正在执行的任务，并且跳过所有已经提交但是还没有运行的任务。但是对于正在执行的任务，是否能够成功关闭它是无法保证的，有可能他们真的被关闭掉了，也有可能它会一直执行到任务结束
- 简单案例

```java
/**
 * 结果：
 * End...
 * Asynchronous task...(是否打印是不确定的)
 */
@Test
public void execute() {
    ExecutorService executorService = Executors.newFixedThreadPool(10);

    executorService.execute(new Runnable() {
        @Override
        public void run() {
            // 睡眠后则不会打印"Asynchronous task..."
            // try {
            //     Thread.sleep(1000);
            // } catch (InterruptedException e) {
            //     e.printStackTrace();
            // }

            System.out.println("Asynchronous task...");
        }
    });

    System.out.println("End...");
    
    executorService.shutdown();
}

/**
 * 结果：
 * run...
 * future.get()=null
 * call...
 * future2.get() = my result...
 * end...
 */
@Test
public void submit() throws ExecutionException, InterruptedException {
    ExecutorService executorService = Executors.newFixedThreadPool(10);

    // #1
    Future future = executorService.submit(new Runnable() {
        public void run() {
            try {
                Thread.sleep(3000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            System.out.println("run...");
        }
    });
    // 如果任务结束执行则返回 null。注意：只有调用了`future.get()`才会阻塞主线程
    System.out.println("future.get()=" + future.get());

    // #2
    Future future2 = executorService.submit(new Callable<Object>() {
        @Override
        public Object call() throws Exception {
            System.out.println("call...");
            return "my result...";
        }
    });
    // 注意：只有调用了`future.get()`才会阻塞主线程
    System.out.println("future2.get() = " + future2.get()); // 如果省略此行，可能会先打印 end... ，再打印 call...

    System.out.println("end...");
}
```

### ScheduledThreadPoolExecutor

### Semaphore

- https://www.cnblogs.com/skywang12345/category/455711.html


### Fork/Join

- Fork/Join 框架是 Java7 提供了的一个用于并行执行任务的框架， 是一个把大任务分割成若干个小任务，最终汇总每个小任务结果后得到大任务结果的框架 [^3]
- 工作窃取算法：工作窃取(work-stealing)算法是指某个线程从其他队列里窃取任务来执行
    - 假如我们需要做一个比较大的任务，我们可以把这个任务分割为若干互不依赖的子任务，为了减少线程间的竞争，于是把这些子任务分别放到不同的队列里，并为每个队列创建一个单独的线程来执行队列里的任务，线程和队列一一对应
    - 当某个一个队列执行完成后，空闲的线程回去执行其他为完成队列的任务。通常使用`双端队列`，正常线程从头部获取任务，窃取线程从尾部获取任务
- Fork/Join 使用两个类来完成以上两件事情
    - `ForkJoinTask`：它提供在任务中执行 `fork()` 和 `join()` 操作的机制，通常情况下只需要继承下列子类
        - **`RecursiveAction`**：用于没有返回结果的任务
        - **`RecursiveTask`**：用于有返回结果的任务
    - **`ForkJoinPool`**：ForkJoinTask 需要通过 ForkJoinPool 来执行
- 简单案例

```java
public class Simple {
    public static void main(String ... args) throws ExecutionException, InterruptedException, TimeoutException {
        int[] array = {100,400,200,90,80,300,600,10,20,-10,30,2000,1000};

        // 默认取计算机核心数，也可自定义线程数
        ForkJoinPool pool = new ForkJoinPool();
        // 注意此处结束取的数组的最后一个下标值
        MaxNumberTask task = new MaxNumberTask(array, 0, array.length - 1);
        Future<Integer> future = pool.submit(task);

        // 注意：只有调用了`future.get()`才会阻塞主线程。表示1秒钟为获取到就放弃阻塞，直接报错TimeoutException
        System.out.println("Result:" + future.get(1, TimeUnit.SECONDS));
        System.out.println("end...");
    }

    // RecursiveAction：用于没有返回结果的任务
    /// RecursiveTask ：用于有返回结果的任务
    private static class MaxNumberTask extends RecursiveTask<Integer> {
        // 当任务大小大于此值是才进行任务分割
        private static final int THRESHOLD = 5;

        // the data array
        private int[] array;

        private int start = 0;
        private int end = 0;

        public MaxNumberTask(int[] array, int start, int end) {
            this.array = array;
            this.start = start;
            this.end = end;
        }

        @Override
        protected Integer compute() {
            int max = Integer.MIN_VALUE;

            // 注意：此处是数值相减进行判断
            if ((end - start) <= THRESHOLD) {
                // 注意：此处是取下标值
                for (int i = start;i <= end; i ++) {
                    // try {
                    //     Thread.sleep(1000);
                    // } catch (InterruptedException e) {
                    //     e.printStackTrace();
                    // }

                    max = Math.max(max, array[i]);
                }
            } else {
                // fork/join
                int mid = start + (end - start) / 2;
                MaxNumberTask lMax = new MaxNumberTask(array, start, mid);
                MaxNumberTask rMax = new MaxNumberTask(array, mid + 1, end);

                // 执行任务
                lMax.fork();
                rMax.fork();

                // 等待子任务结束并得到子结果
                int lm = lMax.join();
                int rm = rMax.join();

                // 合并子结果
                max = Math.max(lm, rm);
            }

            return max;
        }
    }
}
```

## 多线程测试

### 测试模板

```java
public abstract class AbstractMultiThreadTestSimpleTemplate {
    // 测试案例=========================================================================================
    static class DemoTest extends AbstractMultiThreadTestSimpleTemplate {
        public static void main(String[] args) {
            // 总共测试执行10000遍，100个并发
            new DemoTest().run(10000, 100);
        }

        @Override
        public void beforeExec() {}

        @Override
        public void exec() {
            System.out.println(Thread.currentThread().getName() + "测试内容...");
        }

        @Override
        public void afterExec() {}
    }

    // 测试模板=========================================================================================
    // 总访问量是totalNum，并发量是threadNum
    private static int totalNum = 100;
    private static int threadNum = 5;

    private static int count = 0;
    private float sumExecTime = 0;
    private long firstExecTime = Long.MAX_VALUE;
    private long lastDoneTime = Long.MIN_VALUE;

    public abstract void beforeExec();
    public abstract void exec();
    public abstract void afterExec();

    public void run(int totalNum, int threadNum) {
        AbstractMultiThreadTestSimpleTemplate.totalNum = totalNum;
        AbstractMultiThreadTestSimpleTemplate.threadNum = threadNum;
        this.run();
    }

    public void run() {
        beforeExec();

        final ConcurrentHashMap<Integer, ThreadRecord> records = new ConcurrentHashMap<Integer, ThreadRecord>();

        // 建立ExecutorService线程池，threadNum个线程可以同时访问
        ExecutorService es = Executors.newFixedThreadPool(threadNum);
        final CountDownLatch doneSignal = new CountDownLatch(totalNum); // 此数值和循环的大小必须一致

        for (int i = 0; i < totalNum; i++) {
            Runnable run = new Runnable() {
                public void run() {
                    try {
                        int index = ++count;
                        long systemCurrentTimeMillis = System.currentTimeMillis();

                        exec();

                        records.put(index, new ThreadRecord(systemCurrentTimeMillis, System.currentTimeMillis()));
                    } catch (Exception e) {
                        e.printStackTrace();
                    } finally {
                        // 每调用一次countDown()方法，计数器减1
                        doneSignal.countDown();
                    }  
                }
            };
            es.execute(run);
        }

        try {
            // 计数器大于0时，await()方法会阻塞程序继续执行。直到所有子线程完成(每完成一个子线程，计数器-1)
            doneSignal.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        // 获取每个线程的开始时间和结束时间
        for (int i : records.keySet()) {
            ThreadRecord r = records.get(i);
            sumExecTime += ((double) (r.endTime - r.startTime)) / 1000;

            if (r.startTime < firstExecTime) {
                firstExecTime = r.startTime;
            }
            if (r.endTime > lastDoneTime) {
                this.lastDoneTime = r.endTime;
            }
        }

        float avgExecTime = this.sumExecTime / records.size();
        float totalExecTime = ((float) (this.lastDoneTime - this.firstExecTime)) / 1000;
        NumberFormat nf = NumberFormat.getNumberInstance();
        nf.setMaximumFractionDigits(4);

        // 需要关闭，否则JVM不会退出。(如在Springboot项目的Job中切勿关闭)
        es.shutdown();

        System.out.println("======================================================");
        System.out.println("线程数量:\t\t" + threadNum);
        System.out.println("客户端数量:\t" + totalNum);
        System.out.println("平均执行时间:\t" + nf.format(avgExecTime) + "秒");
        System.out.println("总执行时间:\t" + nf.format(totalExecTime) + "秒");
        System.out.println("吞吐量:\t\t" + nf.format(totalNum / totalExecTime) + "次每秒");

        afterExec();
    }

    class ThreadRecord {
        long startTime;
        long endTime;

        ThreadRecord(long st, long et) {
            this.startTime = st;
            this.endTime = et;
        }
    }
}
```






---

参考文章

[^1]: https://my.oschina.net/bairrfhoinn/blog/177639 (ExecutorService 的理解与使用)
[^3]: https://www.infoq.cn/article/fork-join-introduction
[^4]: https://www.cnblogs.com/tong-yuan/p/11768904.html
[^5]: https://www.cnblogs.com/linghu-java/p/8944784.html (Java锁---偏向锁、轻量级锁、自旋锁、重量级锁)
[^6]: https://www.jianshu.com/p/ad34c4c8a2a3
[^7]: https://blog.liexing.me/2018/11/03/parallelstream-trap/
[^8]: https://juejin.im/post/5d929b475188250f782ab84d
[^9]: https://www.cnblogs.com/waterystone/p/4920797.html
[^10]: https://tech.meituan.com/2016/06/24/java-hashmap.html (Java 8系列之重新认识HashMap)
[^11]: https://www.cnblogs.com/peizhe123/p/5790252.html

