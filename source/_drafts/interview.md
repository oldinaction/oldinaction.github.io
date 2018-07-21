

- wait()和sleep()的区别
sleep来自Thread类，和wait来自Object类
调用sleep()方法的过程中，线程不会释放对象锁。而 调用 wait 方法线程会释放对象锁
sleep睡眠后不出让系统资源，wait让出系统资源其他线程可以占用CPU
sleep(milliseconds)需要指定一个睡眠时间，时间一到会自动唤醒
wait(): 让线程处于冻结状态，被wait的线程会被存储到线程池中。
notify():唤醒线程池中一个线程(任意)，没有顺序。
notifyAll():唤醒线程池中的所有线程。

- JAVA 中堆和栈的区别，说下java 的内存机制
a.基本数据类型比变量和对象的引用都是在栈分配的
b.堆内存用来存放由new创建的对象和数组
c.类变量（static修饰的变量），程序在一加载的时候就在堆中为类变量分配内存，堆中的内存地址存放在栈中
d.实例变量：当你使用java关键字new的时候，系统在堆中开辟并不一定是连续的空间分配给变量，是根据零散的堆内存地址，通过哈希算法换算为一长串数字以表征这个变量在堆中的”物理位置”,实例变量的生命周期–当实例变量的引用丢失后，将被GC（垃圾回收器）列入可回收“名单”中，但并不是马上就释放堆中内存
e.局部变量: 由声明在某方法，或某代码段里（比如for循环），执行到它的时候在栈中开辟内存，当局部变量一但脱离作用域，内存立即释放（释放的是变量和对象的引用，此时堆内存中new出的对象就丢失了变量的引用，在堆中分配的内存，由Java虚拟机的自动垃圾回收器来管理。）

- JVM调优
    - -Xms256m -Xmx512m -XX:PermSize=256m -XX:MaxPermSize=512m


- jdk动态代理和cglib动态代理实现的区别
Spring的两种代理方式：JDK动态代理和CGLIB动态代理
1、jdk动态代理生成的代理类和委托类实现了相同的接口；
2、cglib动态代理中生成的字节码更加复杂，生成的代理类是委托类的子类，且不能处理被final关键字修饰的方法；
3、jdk采用反射机制调用委托类的方法，cglib采用类似索引的方式直接调用委托类方法；



