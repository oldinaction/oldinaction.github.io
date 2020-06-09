---
layout: "post"
title: "设计模式"
date: "2017-08-12 09:47"
categories: [arch]
tags: [设计模式, java]
---

## 简介

- [Java设计模式](http://c.biancheng.net/design_pattern/)
- `OOA` Object-Oriented Analysis(面向对象分析方法)
- `OOD` Object-Oriented Design(面向对象设计)
- [UML中的类图及类图之间的关系](http://c.biancheng.net/view/1319.html)，参考：[uml.md#关系](/_posts/design/uml.md#关系)
    - 依赖关系(持有对方引用)、关联关系(你中有我，我中有你)、聚合关系、组合关系、泛化关系(继承)和实现关系
    - 目标为高内聚，低耦合。耦合度：继承 > 聚合(属性为另外一个对象的引用) > 关联(方法参数或返回值是另外一个对象)

### 面向对象设计原则

- 开闭原则(Open Closed Principle，OCP)
    - 对他人关闭，对自己开放
- 里氏替换原则(Liskov Substitution Principle，LSP)
    - 子类继承父类时，除添加新的方法完成新增功能外，尽量不要重写父类的方法
- 依赖倒置原则(Dependence Inversion Principle，DIP)
    - 高层模块不应该依赖低层模块，两者都应该依赖其抽象；抽象不应该依赖细节，细节应该依赖抽象
    - 其核心思想是：要面向接口编程，不要面向实现编程，从而降低类间的耦合性
- 单一职责原则(Single Responsibility Principle，SRP)
    - 这里的职责是指类变化的原因，单一职责原则规定一个类应该有且仅有一个引起它变化的原因，否则类应该被拆分
- 接口隔离原则(Interface Segregation Principle，ISP)
    - 尽量将臃肿庞大的接口拆分成更小的和更具体的接口，让接口中只包含客户感兴趣的方法。一个类对另一个类的依赖应该建立在最小的接口上
    - 与单一职责的区别
        - 单一职责原则注重的是职责，而接口隔离原则注重的是对接口依赖的隔离
        - 单一职责原则主要是约束类，它针对的是程序中的实现和细节；接口隔离原则主要约束接口，主要针对抽象和程序整体框架的构建
- 迪米特法则(Law of Demeter，LoD), 又叫作最少知识原则(Least Knowledge Principle，LKP)
    - 只与你的直接朋友交谈，不跟"陌生人"说话。其含义是：如果两个软件实体无须直接通信，那么就不应当发生直接的相互调用，可以通过第三方转发该调用。其目的是降低类之间的耦合度，提高模块的相对独立性。如：明星与经纪人的关系实例
- 合成复用原则(Composite Reuse Principle，CRP), 又叫组合/聚合复用原则(Composition/Aggregate Reuse Principle，CARP)
    - 它要求在软件复用时，要尽量先使用组合或者聚合等关联关系来实现，其次才考虑使用继承关系来实现

### GoF的23种设计模式分类

- 创建型模式
    - 单例（Singleton）模式：某个类只能生成一个实例，且提供一个方法供外部获取该实例。其拓展是有限多例模式
    - 原型（Prototype）模式：将一个对象作为原型，通过对其进行复制而克隆出多个和原型类似的新实例
    - 工厂方法（FactoryMethod）模式：定义一个用于创建产品的接口，由子类决定生产什么产品
    - 抽象工厂（AbstractFactory）模式：提供一个创建产品族的接口，其每个子类可以生产一系列相关的产品
    - 建造者（Builder）模式：将一个复杂对象分解成多个相对简单的部分，然后根据不同需要分别创建它们，最后构建成该复杂对象


### MSB

- 封装(2.1#0:29:23)
- 持有对方引用(2.3#0:17:45)
- 单例模式(5.1#0:10:30-5.3#0:14:30)
- 策略模式(5.3)
- 工厂模式(6.2#0:8:55-6.3#0:53:46)
- 外观模式、中介者模式(7.3#0:55:0)
- 责任链模式(8.2#0:18:40)
- 装饰器模式(9.330:17:30)
- 观察者模式(10.1)
- 组合模式(10.3#0:34:16)
- 享元模式(10.3#0:57:25)

## 创建型模式

### 单例模式(Singleton)

> http://c.biancheng.net/view/1338.html

- 单例模式定义
    - 指一个类只有一个实例，且该类能自行创建这个实例的一种模式
    - 例如，Windows 中只能打开一个任务管理器
- 方式
    - 饿汉式(`private static final Mgr01_1 INSTANCE = new Mgr01_1();`)
        - 类加载到内存就实例化一个单例，JVM保证线程安全
        - 唯一缺点：不管用到与否，类装载时就完成实例化
        - 简单实用，推荐使用
    - 懒汉式(synchronized + volatile + 双重检查)
        - 用到时再初始化
    - 基于内部类(懒汉式)
        - 内部类只有在用到时才会加载到内存
    - 基于枚举
        - 不仅可以线程同步，还可以防止反序列化(其他方法可通过class反序列化获取新的实例)
- 单例模式可扩展为有限的多例(Multitcm)模式，这种模式可生成有限个实例并保存在 List 中，客户需要时可随机获取

<details>
<summary>主要代码</summary>

```java
// 饿汉式
private static final Mgr01_1 INSTANCE = new Mgr01_1();

// 懒汉式：参考[concurrence.md#volatile](/_posts/java/concurrence.md#volatile)

// 基于内部类
private static class Mgr03Instance {
    private static final Mgr03 INSTANCE = new Mgr03();
}

public static Mgr03 getInstance() {
    return Mgr03Instance.INSTANCE;
}

// 基于枚举
public enum Mgr04 {
    INSTANCE;

    public void test() {
        System.out.println("test...");
    }
}
```
</details>

### 原型模式(Prototype)

> http://c.biancheng.net/view/1343.html

- 原型模式定义
    - 用一个已经创建的实例作为原型，通过复制该原型对象来创建一个和原型相同或相似的新对象
    - 原型实例指定了要创建的对象的种类
    - 用这种方式创建对象非常高效，根本无须知道对象创建的细节
    - 例如：Windows 操作系统的安装通常较耗时，如果复制就快了很多
- 由于 Java 提供了对象的 clone() 方法，所以用 Java 实现原型模式很简单，需要实现Cloneable接口
- 原型模式的克隆分为浅克隆和深克隆，Java 中的 Object 类提供了浅克隆的 clone() 方法，**具体原型类只要实现Cloneable接口**就可实现对象的浅克隆，这里的 Cloneable 接口就是抽象原型类

<details>
<summary>主要代码</summary>

```java
/*
具体原型创建成功！
具体原型复制成功！
o1.name equals o2.name? true
o1.o equals o2.o? true
o1.o == o2.o? true
*/
public class SimpleClone implements Cloneable {
    private String name;
    private Object o;

    public SimpleClone(String name, Object o) {
        this.name = name;
        this.o = o;
        System.out.println("具体原型创建成功！");
    }

    @Override
    protected Object clone() throws CloneNotSupportedException {
        System.out.println("具体原型复制成功！");
        return super.clone();
    }

    public static void main(String[] args) throws CloneNotSupportedException {
        Object o = new Object();
        SimpleClone o1 = new SimpleClone("o1", o);
        SimpleClone o2 = (SimpleClone) o1.clone();

        System.out.println("o1.name equals o2.name? " + (o1.name.equals(o2.name)));
        System.out.println("o1.o equals o2.o? " + (o1.o.equals(o2.o)));
        System.out.println("o1.o == o2.o? " + (o1.o == o2.o));
    }
}
```
</details>

### 工厂方法模式(FactoryMethod)

> http://c.biancheng.net/view/1348.html

- 工厂方法模式定义
    - 定义一个创建产品对象的工厂接口，将产品对象的实际创建工作推迟到具体子工厂类当中
    - **有一个抽象工厂定义了生产抽象产品，并且有一个具体的工厂实现了抽象工厂来生产具体的产品**
- 简单工厂模式和静态工厂
    - **简单工厂模式**：如果要创建的产品不多，只要一个工厂类就可以完成(可以创建不同类型的产品)。它不属于 GoF 的 23 种经典设计模式，它的缺点是增加新产品时会违背开闭原则
        - 工厂方法模式是对简单工厂模式的进一步抽象化，其好处是可以使系统在不修改原来代码的情况下引进新的产品，即满足开闭原则
    - **静态工厂**：静态方法产生的类，如单例可认为是一种静态工厂
- 工厂方法模式由抽象工厂、具体工厂、抽象产品和具体产品等4个要素构成
- 类图

![DP-FactoryMethod](/data/images/arch/DP-FactoryMethod.png)

### 抽象工厂模式(AbstractFactory)

> http://c.biancheng.net/view/1351.html

- 抽象工厂模式定义
    - 抽象工厂模式是工厂方法模式的升级，工厂方法模式只生产一个类型的产品，而抽象工厂模式可生产一系列产品
    - 如 java 的 AWT 中的 Button 和 Text 等构件在 Windows 和 UNIX 中的本地实现是不同的
- 系统一次只可能消费其中某一系列产品，即同族的产品一起使用
- 其缺点是：当产品族中需要增加一个新的产品时，所有的工厂类都需要进行修改
- 类图

![DP-AbstractFactory](/data/images/arch/DP-AbstractFactory.png)

### 建造者模式(Bulider)

> http://c.biancheng.net/view/1354.html

- 建造者模式定义
    - 将一个复杂的对象分解为多个简单的对象，然后一步一步构建而成。它将变与不变相分离，即产品的组成部分是不变的，但每一部分是可以灵活选择的
- 建造者模式和工厂模式的关注点不同：建造者模式注重零部件的组装过程，而工厂方法模式更注重零部件的创建过程，但两者可以结合使用

<details>
<summary>主要代码</summary>

```java
// 简单的Person Model省略
public static void main(String[] args) {
    PersonBuilder builder = new PersonBuilder();
    Person person = builder.buildName("smalle").buildAge(18).buildSex(1).build();
    System.out.println(person); // Person{name='smalle', age=18, sex=1}
}

public class PersonBuilder {
    protected Person person = new Person();

    public PersonBuilder buildName(String name) {
        person.setName(name);
        return this;
    }

    public PersonBuilder buildAge(Integer age) {
        person.setAge(age);
        return this;
    }

    public PersonBuilder buildSex(Integer sex) {
        person.setSex(sex);
        return this;
    }

    public Person build() {
        return person;
    }
}
```
</details>

## 结构型模式

### 代理模式(Proxy)

> http://c.biancheng.net/view/1359.html

- 代理模式定义
    - 为某对象提供一种代理来进行访问此对象。即客户端通过代理间接地访问该对象，从而限制、增强或修改该对象的一些特性
- 类图

![DP-Proxy](/data/images/arch/DP-Proxy.png)

<details>
<summary>主要代码</summary>

```java
/*
pre...
smalle...
post...
*/
public static void main(String[] args) {
    NameResourceProxy proxy = new NameResourceProxy();
    proxy.showResource();
}

public class NameResourceProxy implements Resource {
    private NameResource nameResource;

    @Override
    public void showResource() {
        if (nameResource == null) {
            nameResource = new NameResource();
        }

        this.preShowResource();
        nameResource.showResource();
        this.postShowResource();
    }

    private void preShowResource() {
        System.out.println("pre...");
    }

    private void postShowResource() {
        System.out.println("post...");
    }
}

public class NameResource implements Resource {
    @Override
    public void showResource() {
        System.out.println("smalle...");
    }
}

public interface Resource {
    void showResource();
}
```
</details>

### 适配器模式(Adapter)

> http://c.biancheng.net/view/1361.html

- 适配器模式定义
    - 将一个类的接口转换成客户希望的另外一个接口，使得原本由于接口不兼容而不能一起工作的那些类能一起工作
- 适配器模式分为类适配器和对象适配器两种，前者类之间的耦合度比后者高，且要求程序员了解现有组件库中的相关组件的内部结构，所以应用相对较少些
- 



## 策略模式(Strategy)

- `java.lang.Comparable` 可排序的，需实现compareTo方法
- `java.util.Comparator` 比较策略，需要实现compare方法，使用了策略模式。如：Collections.sort(list, Comparator); 需传入被排序集合和排序策略

<details>
<summary>Comparator使用-理解Strategy</summary>

```java
/**
 * Comparator比较策略，需要实现compare方法
 *
 * 结果：
 *
 * [T1_Comparator{name='b', age=18}, T1_Comparator{name='c', age=30}, T1_Comparator{name='a', age=50}]
 * [T1_Comparator{name='a', age=50}, T1_Comparator{name='b', age=18}, T1_Comparator{name='c', age=30}]
 *
 * @author smalle
 * @date 2020-06-07 22:22
 */
public class T2_Comparator {
    private String name;
    private Integer age;

    public T2_Comparator(String name, Integer age) {
        this.name = name;
        this.age = age;
    }

    @Override
    public String toString() {
        return "T1_Comparator{" +
                "name='" + name + '\'' +
                ", age=" + age +
                '}';
    }

    static class C1 implements Comparator<T2_Comparator> {
        @Override
        public int compare(T2_Comparator o1, T2_Comparator o2) {
            if(o1.age > o2.age) return 1;
            else if(o1.age < o2.age) return -1;
            else return 0;
        }
    }

    static class C2 implements Comparator<T2_Comparator> {
        @Override
        public int compare(T2_Comparator o1, T2_Comparator o2) {
            return o1.name.compareTo(o2.name);
        }
    }


    public static void main(String[] args) {
        List<T2_Comparator> list = new ArrayList<>();
        list.add(new T2_Comparator("c", 30));
        list.add(new T2_Comparator("b", 18));
        list.add(new T2_Comparator("a", 50));

        // 传入被排序集合和排序策略
        Collections.sort(list, new C1());
        System.out.println(list);

        // Comparator使用了策略模式，因此此处可以很方便的改变排序策略
        Collections.sort(list, (T2_Comparator o1, T2_Comparator o2) -> {
            return o1.name.compareTo(o2.name);
        });
        System.out.println(list);
    }
}
```
</details>

## 工厂模式

- 工厂方法
    - 生成一个产品
- 抽象工厂
    - 有一个抽象工厂可以生产一系列抽象产品
    - 对应的具体产品继承抽象产品
    - 可自定义不同的具体工厂实现此抽象工厂，来生成这一系列(抽象产品对应的)具体产品
- 简单工厂
- 静态工厂(静态方法产生的类)
- bean工厂

- 任何可以产生对象的方法或类，都可以称之为工厂。单例也可认为是一种工厂(有称为静态工厂)，不可死抠概念
- 为什么有了new之后，还要工厂？灵活控制生成过程，如权限、修饰、日志



## 外观模式(Facade)和中介者模式(Mediator)

- 将复杂的关系封装到一起，再对外提供服务。此时对外认为是外观(或门面)，对内认为是调停者(有了调停者，当内部有新加入成员时，只需要给调停者打交道，不需要和其他成员打交道)

## 责任链模式

- 责任链实现责任接口
- 责任接口返回boolean控制责任链是否继续执行

## 观察者模式(Observer)

- Observer、Listener、Hook、Callback都属于观察者模式

## 装饰器模式(Decorator)

- 装饰器可混合使用，装饰器接口和被装饰物实现了同一个接口。如InputStream相关的类

## 组合模式(Composite)

- 主要用于树状结构

## 享元模式(Flyweight)

- 如java中的常量字符串，有一个常量池，如果下次需要的常量字符串在这个里面有则直接使用


11



## 责任链模式

- Tomcat中的Filter就是使用了责任链模式，创建一个Filter除了要在web.xml文件中做相应配置外，还需要实现javax.servlet.Filter接口
- 参与者
    - `Handler`(抽象处理者)：定义出一个处理请求的接口。可选实现后继链(可返回下一个责任对象的)
    - `ConcreteHandler`(具体处理者)：处理他所负责的请求；可访问他的后继者；如果可处理该请求，就处理之，否则将该请求转发给它的后继者
- 可插拔编程/插件开发常用
- 案例 [^1]

```java
// Handler.java
public abstract class Handler {
    // 持有后继的责任对象
    protected Handler successor;

    // 示意后继的责任对象处理请求的方法。根据具体需要来选择是否传递参数
    public abstract void handleRequest();

    public Handler getSuccessor() {
        return successor;
    }

    public void setSuccessor(Handler successor) {
        this.successor = successor;
    }
}

// ConcreteHandler.java
public class ConcreteHandler extends Handler {
    // 处理方法，调用此方法处理请求
    @Override
    public void handleRequest() {
        // 具体处理逻辑
        if(getSuccessor() != null) {
            System.out.println("放过请求");

            // 调用后续责任对象处理
            getSuccessor().handleRequest();
        } else {
            System.out.println("处理请求");
        }
    }
}

// Client.java
public class Client {
    public static void main(String[] args) {
        // 组装责任链。实际可将所有的责任对象放到集合中
        Handler handler1 = new ConcreteHandler();
        Handler handler2 = new ConcreteHandler();
        handler1.setSuccessor(handler2);

        // 提交请求，先交由第一个处理
        handler1.handleRequest();
    }
}

// 打印结果：
// 放过请求
// 处理请求
```


### 马士兵谈设计模式

> - GRASP模式、JBPM工作流
> - 类可以是提取需求中的名词；
> - 抽象类和接口的区别：一般是脑子里有一个概念但是没有具体的东西可以设计为抽象类，如交通工具(车、飞机)，他有一个方法go()；如果只是考虑一类事物和几类事物共同的特征一般设计为接口，如会跑的(Movable)，他有一个方法go().

- Observer案例：小孩醒了，爸爸需要喂奶
    - 本来是爸爸需要一直观察小孩是否醒了，那么需要爸爸启动线程监听。但此处让小孩启动线程，醒来后就调用爸爸的方法(或者发出一个事件)
    - 本身是需要喂奶，如果需求复杂就可能是小孩不同时间醒了需要做不同的事情(早上喂奶, 中午看电视, 晚上散步)。此时则新加一个事件对象，小孩醒了就发出一个事件，有爸爸去监听做出响应
    - 可能小孩醒了不仅爸爸需要喂奶，爷爷/奶奶也要做出响应，则此时应该基于接口编程。有一个小孩醒来的事件监听接口，小孩只需要调用此接口的事件响应方法，爷爷/奶奶只需要实现此接口即可
    - 可将接口的实现从配置文件中读取，读取出对应的类名，并通过`Class.forName(myClassName).newInstance()`进行实例化

- ThinkingInOO案例





























---

参考文章

[^1]: https://www.cnblogs.com/java-my-life/archive/2012/05/28/2516865.html


