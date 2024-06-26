---
layout: "post"
title: "设计模式"
date: "2017-08-12 09:47"
categories: [arch]
tags: [设计模式, java, design]
---

## 简介

- 文档
    - [Java设计模式](https://www.weixueyuan.net/java/shejimoshi/)
    - [设计模式](https://www.runoob.com/design-pattern/design-pattern-tutorial.html)
- `OOA` Object-Oriented Analysis(面向对象分析方法)
- `OOD` Object-Oriented Design(面向对象设计)
- [UML中的类图及类图之间的关系](http://c.biancheng.net/view/1319.html)，参考：[uml.md#关系](/_posts/design/uml.md#关系)
    - 依赖关系(持有对方引用)、关联关系(你中有我，我中有你)、聚合关系、组合关系、泛化关系(继承)和实现关系
    - 目标为高内聚，低耦合。耦合度：继承 > 聚合(属性为另外一个对象的引用) > 关联(方法参数或返回值是另外一个对象)
- GRASP模式、JBPM工作流
- 类可以是提取需求中的名词；抽象类和接口的区别：一般是脑子里有一个概念但是没有具体的东西可以设计为抽象类，如交通工具(车、飞机)，他有一个方法go()；如果只是考虑一类事物和几类事物共同的特征一般设计为接口，如会跑的(Movable)，他有一个方法go()

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

- 顺口溜
    - 抽工 建 单原【抽工建单元(原)】
    - 代桥外 享适 组装【在(代)桥外想试组装】
    - 迭解 策观 状命中，责备 模访【蝶姐侧观撞(到了)命中(钟),责备(其)模仿】
- 创建型模式（5种）
    - **单例**（Singleton）模式：某个类只能生成一个实例，且提供一个方法供外部获取该实例
    - 原型（Prototype）模式：将一个对象作为原型，通过对其进行复制而克隆出多个和原型类似的新实例
    - **工厂方法**（FactoryMethod）模式：定义一个用于创建产品的接口，由子类决定生产什么产品
    - **抽象工厂**（AbstractFactory）模式：提供一个创建产品族的接口，其每个子类可以生产一系列相关的产品
    - **建造者**（Builder）模式：将一个复杂对象分解成多个相对简单的部分，然后根据不同需要分别创建它们，最后构建成该复杂对象
- 结构型模式（7种）
    - **代理**（Proxy）模式：为某对象提供一种代理以控制对该对象的访问。即客户端通过代理间接地访问该对象，从而限制、增强或修改该对象的一些特性
    - **适配器**（Adapter）模式：将一个类的接口转换成客户希望的另外一个接口，使得原本由于接口不兼容而不能一起工作的那些类能一起工作
    - **装饰**（Decorator）模式：动态的给对象增加一些职责，即增加其额外的功能
    - **外观**（Facade）模式：为多个复杂的子系统提供一个一致的接口，使这些子系统更加容易被访问
    - 桥接（Bridge）模式：将抽象与实现分离，使它们可以独立变化
    - 享元（Flyweight）模式：运用共享技术来有效地支持大量细粒度对象的复用
    - 组合（Composite）模式：将对象组合成树状层次结构，使用户对单个对象和组合对象具有一致的访问性
- 行为型模式（11种）
    - **模板方法**（TemplateMethod）模式：定义一个操作中的算法骨架，而将算法的一些步骤延迟到子类中，使得子类可以不改变该算法结构的情况下重定义该算法的某些特定步骤
    - **策略**（Strategy）模式：定义了一系列算法，并将每个算法封装起来，使它们可以相互替换，且算法的改变不会影响使用算法的客户
    - 命令（Command）模式：将一个请求封装为一个对象，使发出请求的责任和执行请求的责任分割开
    - **职责链**（Chain of Responsibility）模式：把请求从链中的一个对象传到下一个对象，直到请求被响应为止。通过这种方式去除对象之间的耦合
    - 状态（State）模式：允许一个对象在其内部状态发生改变时改变其行为能力
    - **观察者**（Observer）模式：多个对象间存在一对多关系，当一个对象发生改变时，把这种改变通知给其他多个对象，从而影响其他对象的行为
    - **中介者**（Mediator）模式：定义一个中介对象来简化原有对象之间的交互关系，降低系统中对象间的耦合度，使原有对象之间不必相互了解
    - 迭代器（Iterator）模式：提供一种方法来顺序访问聚合对象中的一系列数据，而不暴露聚合对象的内部结构
    - **访问者**（Visitor）模式：在不改变集合元素的前提下，为一个集合中的每个元素提供多种访问方式，即每个元素有多个访问者对象访问
    - 备忘录（Memento）模式：在不破坏封装性的前提下，获取并保存一个对象的内部状态，以便以后恢复它
    - 解释器（Interpreter）模式：提供如何定义语言的文法，以及对语言句子的解释方法，即解释器

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
- 代理模式(11)
- 迭代器模式(12.1-12.2#16:00)
- 访问者(12.2#16:00)

## 尝试

- 访问者模式
    - 当解析多个Excel记录(记录了某个人的简历，但是格式可能存在差异)到实体，如果使用访问者模式可以多个访问者同时都有机会读取到某一行记录，但是不好决定用哪一个访问者的姓名解析方法为准来进行姓名解析

## 创建型模式

- 创建型模式的主要关注点是"怎样创建对象？"，它的主要特点是将对象的创建与使用分离

### 单例模式(Singleton)

> http://c.biancheng.net/view/1338.html

- 单例模式定义
    - **某个类只能生成一个实例，且提供一个方法供外部获取该实例**
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
- 单例模式可扩展为有限的**多例模式(Multitcm)**，这种模式可生成有限个实例并保存在 List 中，客户需要时可随机获取

<details>
<summary>单例模式示例代码</summary>

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
    - **将一个对象作为原型，通过对其进行复制而克隆出多个和原型类似的新实例**
    - 原型实例指定了要创建的对象的种类
    - 用这种方式创建对象非常高效，根本无须知道对象创建的细节
    - 例如：Windows 操作系统的安装通常较耗时，如果复制就快了很多
- 由于 Java 提供了对象的 clone() 方法，所以用 Java 实现原型模式很简单，需要实现Cloneable接口，并重写clone()方法
- 原型模式的克隆分为浅克隆和深克隆，Java 中的 Object 类提供了浅克隆的 clone() 方法。具体原型类只要实现Cloneable接口就可实现对象的浅克隆，实现深克隆则需要对象属性也实现Cloneable接口

<details>
<summary>原型模式示例代码</summary>

```java
/*
具体原型创建成功！
具体原型复制成功！
o1.name equals o2.name? true
o1.o equals o2.o? true
o1.o == o2.o? true
o1.data == o2.data? false
*/
public class SimpleClone implements Cloneable {
    private String name;
    private Object o;
    private Data data;

    public SimpleClone(String name, Object o, Data data) {
        this.name = name;
        this.o = o;
        this.data = data;
        System.out.println("具体原型创建成功！");
    }

    @Override
    protected Object clone() throws CloneNotSupportedException {
        System.out.println("具体原型复制成功！");
        // 实现Data的深克隆
        SimpleClone o = (SimpleClone) super.clone();
        o.data = (Data) data.clone();
        return o;
    }

    public static void main(String[] args) throws CloneNotSupportedException {
        Object o = new Object();
        Data data = new Data("V1");
        SimpleClone o1 = new SimpleClone("o1", o, data);
        SimpleClone o2 = (SimpleClone) o1.clone();

        System.out.println("o1.name equals o2.name? " + (o1.name.equals(o2.name)));
        System.out.println("o1.o equals o2.o? " + (o1.o.equals(o2.o)));
        System.out.println("o1.o == o2.o? " + (o1.o == o2.o));
        System.out.println("o1.data == o2.data? " + (o1.data == o2.data));
    }
}

class Data implements Cloneable {
    String data;

    public Data(String data) {
        this.data = data;
    }

    @Override
    protected Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
}
```
</details>

### 工厂方法模式(FactoryMethod)

> http://c.biancheng.net/view/1348.html

- 工厂方法模式定义
    - **定义一个用于创建产品的接口，由子类决定生产什么产品**
    - 有一个工厂接口定义了生产抽象产品，并且有一个具体的工厂实现了此工厂接口来生产具体的产品
- 简单工厂模式和静态工厂
    - **简单工厂模式**：如果要创建的产品不多，只要一个工厂类就可以完成(可以创建不同类型的产品)。它不属于 GoF 的 23 种经典设计模式，它的缺点是增加新产品时会违背开闭原则
        - 工厂方法模式是对简单工厂模式的进一步抽象化，其好处是可以使系统在不修改原来代码的情况下引进新的产品，即满足开闭原则
    - **静态工厂**：静态方法产生的类，如单例可认为是一种静态工厂
- 工厂方法模式由工厂接口类、具体工厂、产品接口类和具体产品等4个要素构成
- 类图

![DP-FactoryMethod](/data/images/design/DP-FactoryMethod.png)

### 抽象工厂模式(AbstractFactory)

> http://c.biancheng.net/view/1351.html

- 抽象工厂模式定义
    - **提供一个创建产品族的接口，其每个子类可以生产一系列相关的产品**
    - 抽象工厂模式是工厂方法模式的升级，工厂方法模式只生产一个类型的产品，而抽象工厂模式可生产一系列产品
    - 如 java 的 AWT 中的 Button 和 Text 等构件在 Windows 和 UNIX 中的本地实现是不同的
- 系统一次只可能消费其中某一系列产品，即同族的产品一起使用
- 其缺点是：当产品族中需要增加一个新的产品时，所有的工厂类都需要进行修改
- 类图

![DP-AbstractFactory](/data/images/design/DP-AbstractFactory.png)

### 建造者模式(Bulider)

> http://c.biancheng.net/view/1354.html

- 建造者模式定义
    - **将一个复杂对象分解成多个相对简单的部分，然后根据不同需要分别创建它们，最后构建成该复杂对象**
    - 它将变与不变相分离，即产品的组成部分是不变的，但每一部分是可以灵活选择的
- 建造者模式和工厂模式的关注点不同：建造者模式注重零部件的组装过程，而工厂方法模式更注重零部件的创建过程，但两者可以结合使用

<details>
<summary>建造者模式示例代码</summary>

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

- 结构型模式描述如何将类或对象按某种布局组成更大的结构。它分为类结构型模式和对象结构型模式，前者采用继承机制来组织接口和类，后者釆用组合或聚合来组合对象

### 代理模式(Proxy)

> http://c.biancheng.net/view/1359.html

- 代理模式定义
    - **为某对象提供一种代理以控制对该对象的访问。即客户端通过代理间接地访问该对象，从而限制、增强或修改该对象的一些特性**
    - **个人理解，对象适配器和装饰器模式类似代理模式：实现目标接口；代理对象/适配器/装饰器构造时传入目标对象(可嵌套)**，当然也可不传入目标对象，而是传入一些配置，从而动态获取目标对象
    - 适配器模式主要解决接口转换的问题，代理模式主要解决对象无法直接访问的问题，装饰者模式主要用来增强功能
- 代理分为静态代理和动态代理，其中动态代理主要有JDK动态代理和Cglib动态代理，最终都是基于[ASM](https://asm.ow2.io/)操纵字节码
    - JDK动态代理和静态代理类似，代理类和被代理需要实现相同的接口
    - Cglib动态代理是生成被代理类的子类，因此被代理类不能被final修饰
- Spring AOP基于动态代理完成，参考[spring.md#AOP](/_posts/java/spring.md#AOP)
- (静态代理)类图

![DP-Proxy](/data/images/design/DP-Proxy.png)

<details>
<summary>静态代理示例代码</summary>

```java
/*结果如：
pre...
move...
move time: 446
post...
*/
public class Main {

    public static void main(String[] args) {
        // 此处可嵌套，类似装饰器。此处也可不传入目标对象，而是传入一些配置，从而动态获取目标对象
        MovableLogProxy proxy = new MovableLogProxy(new MovableTimeProxy(new Dog()));
        proxy.move();
    }
}

public interface Movable {
    void move();
}

// 被代理者
public class Dog implements Movable {
    @Override
    public void move() {
        System.out.println("move...");
        try {
            Thread.sleep(new Random().nextInt(1000));
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}

// 代理者
public class MovableLogProxy implements Movable {
    private Movable movable;

    // 此处也可不传入目标对象，而是传入一些配置(如字符串dog)，从而动态获取目标对象
    public MovableLogProxy(Movable movable) {
        this.movable = movable;
    }

    @Override
    public void move() {
        this.preMove();
        movable.move();
        this.postMove();
    }

    private void preMove() {
        System.out.println("pre...");
    }

    private void postMove() {
        System.out.println("post...");
    }
}

// 代理者
public class MovableTimeProxy implements Movable {
    private Movable movable;

    public MovableTimeProxy(Movable movable) {
        this.movable = movable;
    }

    @Override
    public void move() {
        long start = System.currentTimeMillis();
        movable.move();
        long end = System.currentTimeMillis();
        System.out.println("move time: " + (end - start));
    }
}
```
</details>

<details>
<summary>动态代理示例代码</summary>

```java
// 1.JDK动态代理。还是Dog 和 Movable，同上文
public static void main(String[] args) {
    Dog dog = new Dog();
    Movable movable = (Movable) Proxy.newProxyInstance(Dog.class.getClassLoader(), new Class[]{Movable.class}, new InvocationHandler() {
        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            System.out.println("pre...");
            Object o = method.invoke(dog, args);
            System.out.println("post...");
            return o;
        }
    });
    movable.move();
}

// 2.Cglib动态代理(maven依赖为：cglib#cglib#3.3.0)。只需要Dog，同上文
public static void main(String[] args) {
    Enhancer enhancer = new Enhancer();
    enhancer.setSuperclass(Dog.class);
    enhancer.setCallback(new MethodInterceptor() {
        @Override
        public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
            System.out.println("pre...");
            Object result = methodProxy.invokeSuper(o, objects);
            System.out.println("post...");
            return result;
        }
    });
    Dog dog = (Dog) enhancer.create();
    dog.move();
}
```
</details>

### 适配器模式(Adapter)

> http://c.biancheng.net/view/1361.html

- 适配器模式定义
    - **将一个类的接口转换成客户希望的另外一个接口，使得原本由于接口不兼容而不能一起工作的那些类能一起工作**
    - 如`InputStreamReader`就是Adapter模式。FileInputStream默认只能一个字节一个字节的读，此时通过InputStreamReader适配，最后可使用BufferedReader进行一行一行的读，如`new BufferedReader(new InputStreamReader(new FileInputStream("c:/test.text")));`
    - **常见的以Adapter命名的反而不是基于适配器模式，如WindowAdapter**(主要为了方便编程，对接口的方法有默认的实现，只需要去继承重写关心的方法)；**常见以Bridge命名却有可能是Adapter模式**
    - **个人理解，对象适配器和装饰器模式类似代理模式：实现目标接口；代理对象/适配器/装饰器构造时传入目标对象(可嵌套)**
- 适配器模式分为类适配器和对象适配器两种
    - 类适配器基于继承
    - 对象适配器基于依赖
    - 对象适配器相对类适配器耦合度更低，更常用
- 类图

![DP-Adapter](/data/images/design/DP-Adapter.png)

<details>
<summary>适配器模示例代码</summary>

```java
public static void main(String[] args) {
    Adaptee adaptee = new Adaptee();
    Target target = new ObjectAdapter(adaptee);
    String data = target.request();
    System.out.println(data);
}

// 期待的接口
public interface Target {
    String request();
}

// 被适配者(一般为由于特殊原因不能进行代码修改的类)
public class Adaptee {
    public String specialRequest() {
        return "data...";
    }
}

// 适配器(提供一个对外统一接口，内部实现对被适配者的调用)
public class ObjectAdapter implements Target {
    private Adaptee adaptee;

    public ObjectAdapter(Adaptee adaptee) {
        this.adaptee = adaptee;
    }

    @Override
    public String request() {
        System.out.println("do somthing...");
        return adaptee.specialRequest();
    }
}
```
</details>

### 装饰模式(Decorator)

> http://c.biancheng.net/view/1366.html

- 装饰模式定义
    - **动态的给对象增加一些职责，即增加其额外的功能**
    - 装饰器可混合使用，装饰器接口和被装饰物实现了同一个接口。如InputStream相关的类
    - **个人理解，对象适配器和装饰器模式类似代理模式：实现目标接口；代理对象/适配器/装饰器构造时传入目标对象(可嵌套)**
- 如：房子框架搭建完成 - 房子墙面刷白完成 - 房子周围花园建造完成

### 外观模式(Facade)

> http://c.biancheng.net/view/1369.html

- 外观模式(又称**门面模式**)定义(Facade读音：/fəˈsɑːd/)
    - **为多个复杂的子系统提供一个一致的接口，使这些子系统更加容易被访问**
    - 将复杂的关系封装到一起，再对外提供服务。如政务服务的统一窗口，用户只需给该窗口提交资料，至于政务内部涉及到多个部门审核由统一窗口协调，对用户不可见
    - 此时对外认为是外观(或门面)，对内认为是调停者模式/中介者模式(有了调停者，当内部有新加入成员时，只需要给调停者打交道，不需要和其他成员打交道)
- 类图

![DP-Facade](/data/images/design/DP-Facade.png)    

<details>
<summary>外观模式示例代码</summary>

```java
public static void main(String[] args) {
    Facade facade = new Facade();
    facade.service();
}

// 外观。当增加或移除子系统时需要修改外观类，这违背了"开闭原则"。也可以引入抽象外观类，则在一定程度上解决了该问题
public class Facade {
    // 外观必须自己实例化子系统(即客户不需要关心子系统 )
    private SubSystemA subSystemA = new SubSystemA();
    private SubSystemB subSystemB = new SubSystemB();
    private SubSystemC subSystemC = new SubSystemC();

    public void service() {
        System.out.println("接受到客户请求...");

        subSystemA.serviceA();
        subSystemB.serviceB();
        subSystemC.serviceC();

        System.out.println("向客户反馈结果...");
    }
}

public class SubSystemA {
    public void serviceA() {
        System.out.println("子系统 SubSystemA 执行了一系列操作...");
    }
}
public class SubSystemB {
    public void serviceB() {
        System.out.println("子系统 SubSystemB 执行了一系列操作...");
    }
}
public class SubSystemC {
    public void serviceC() {
        System.out.println("子系统 SubSystemC 执行了一系列操作...");
    }
}
```
</details>

### 桥接模式(Bridge)

> http://c.biancheng.net/view/1364.html

- 桥接模式定义
    - 将抽象与实现分离，使它们可以独立变化
    - **如Controller持有Service引用**

### 享元模式(Flyweight)

> https://www.runoob.com/design-pattern/flyweight-pattern.html

- 享元模式定义
    - **运用共享技术来有效地支持大量细粒度对象的复用**
    - 如java中的常量字符串，有一个常量池，如果下次需要的常量字符串在这个里面有则直接使用

<details>
<summary>享元模式示例代码</summary>

```java
public static void main(String[] args) {
    String[] colors = new String[]{"red", "blue", "yellow", "black", "white"};
    Random random = new Random();

    for (int i = 0; i < 10; i++) {
        int index = random.nextInt(5);
        Shape shape = ShapeFactory.getShape(colors[index]);
        shape.draw();
    }
}

public interface Shape {
    void draw();
}

public class Circle implements Shape {
    private String color;

    public Circle(String color){
        this.color = color;
    }

    @Override
    public void draw() {
        System.out.println("color:" + color);
    }
}

public class ShapeFactory {
    private static final HashMap<String, Shape> map = new HashMap<>();

    public static Shape getShape(String color) {
        Shape shape = map.get(color);
        if(shape == null) {
            shape = new Circle(color);
            System.out.println("create Circle, color:" + color);
            map.put(color, shape);
        }
        return shape;
    }
}
```
</details>

### 组合模式(Composite)

- 组合模式定义
    - 将对象组合成树状层次结构，使用户对单个对象和组合对象具有一致的访问性
- 透明方式和安全模式
    - 透明方式
        - 在该方式中，由于抽象构件声明了所有子类中的全部方法，所以客户端无须区别树叶对象和树枝对象，对客户端来说是透明的
        - 其缺点是：树叶构件本来没有 add()、remove() 方法，却要实现它们（空实现或抛异常），这样会带来一些安全性问题
    - 安全方式
        - 将管理子构件的方法移到树枝构件中，抽象构件和树叶构件没有对子对象的管理方法，这样就避免了透明方式的安全性问题
        - 但由于叶子和分支有不同的接口，客户端在调用时要知道树叶对象和树枝对象的存在，所以失去了透明性

<details>
<summary>组合模式(透明方式)示例代码</summary>

```java
/*
枝干节点1
    叶子1
    枝干节点2
        叶子2
        叶子3
*/
public static void main(String[] args) {
    Component composite1 = new Composite("枝干节点1");
    Component composite2 = new Composite("枝干节点2");
    Component leaf1 = new Leaf("叶子1");
    Component leaf2 = new Leaf("叶子2");
    Component leaf3 = new Leaf("叶子3");

    composite1.add(leaf1);
    composite1.add(composite2);
    composite2.add(leaf2);
    composite2.add(leaf3);

    composite1.operation(0);
}

public interface Component {
    void add(Component c);
    void remove(Component c);
    void operation(int level);
}

public class Composite implements Component {
    private final List<Component> children = new ArrayList<>();

    private String name;

    public Composite(String name) {
        this.name = name;
    }

    @Override
    public void add(Component c) {
        children.add(c);
    }

    @Override
    public void remove(Component c) {
        children.remove(c);
    }

    @Override
    public void operation(int level) {
        String space = "";
        for (int i = 0; i < level; i++) {
            space += "    ";
        }
        System.out.println(space + name);

        level++;
        for(Component obj: children) {
            obj.operation(level);
        }
    }
}

public class Leaf implements Component {
    private String name;

    public Leaf(String name) {
        this.name = name;
    }

    @Override
    public void add(Component c) {

    }

    @Override
    public void remove(Component c) {

    }

    @Override
    public void operation(int level) {
        String space = "";
        for (int i = 0; i < level; i++) {
            space += "    ";
        }
        System.out.println(space + name);
    }
}
```
</details>

## 行为型模式

- 行为型模式用于描述程序在运行时复杂的流程控制，即描述多个类或对象之间怎样相互协作共同完成单个对象都无法单独完成的任务，它涉及算法与对象间职责的分配
- 行为型模式分为类行为模式和对象行为模式，前者采用继承机制来在类间分派行为，后者采用组合或聚合在对象间分配行为

### 模板方法模式(TemplateMethod)

- 模板方法模式定义
    - **定义一个操作中的算法骨架，而将算法的一些步骤延迟到子类中，使得子类可以不改变该算法结构的情况下重定义该算法的某些特定步骤**
    - 如自定义ClassLoader时，需要继承ClassLoader并重写其findClass这个抽象方法

![DP-TemplateMethod](/data/images/design/DP-TemplateMethod.png)

<details>
<summary>模板方法模式示例代码</summary>

```java
public static void main(String[] args) {
    AbstractClass abstractClass = new ConcreteClass();
    abstractClass.templateMethod();
}

public abstract class AbstractClass {

    public void templateMethod() {
        abstractMethod1();
        specificMethod();
        abstractMethod2();
    }

    private void specificMethod() {
        System.out.println("specificMethod...");
    }

    public abstract void abstractMethod1();
    public abstract void abstractMethod2();
}

public class ConcreteClass extends AbstractClass {
    @Override
    public void abstractMethod1() {
        System.out.println("abstractMethod1...");
    }

    @Override
    public void abstractMethod2() {
        System.out.println("abstractMethod2...");
    }
}
```
</details>

### 策略模式(Strategy)

- 策略模式定义
    - **定义了一系列算法，并将每个算法封装起来，使它们可以相互替换，且算法的改变不会影响使用算法的客户**
    - **`java.util.Comparator`** 比较策略，需要实现compare方法，使用了策略模式。如：Collections.sort(list, Comparator); 需传入被排序集合和排序策略
    - `java.lang.Comparable` 可排序的，需实现compareTo方法

![DP-Strategy](/data/images/design/DP-Strategy.png)

<details>
<summary>策略模式示例代码(基于Comparator使用)</summary>

```java
public static void main(String[] args) {
    List<Person> list = new ArrayList<>();
    list.add(new Person("c", 30));
    list.add(new Person("b", 18));
    list.add(new Person("a", 50));

    // 传入被排序集合和排序策略
    Collections.sort(list, new PersonAgeComparator());
    System.out.println(list);

    // Comparator使用了策略模式，因此此处可以很方便的改变排序策略
    Collections.sort(list, (Person o1, Person o2) -> {
        return o1.getName().compareTo(o2.getName());
    });
    System.out.println(list);
}

// 对于java.util.Comparator可以有不同的实现。一般自己写策略模式需要定义一个类似Comparator的接口
public class PersonAgeComparator implements Comparator<Person> {
    @Override
    public int compare(Person o1, Person o2) {
        if(o1.getAge() > o2.getAge()) return 1;
        else if(o1.getAge() < o2.getAge()) return -1;
        else return 0;
    }
}
```
</details>

### 命令模式(Command)

- 命令模式定义
    - **将一个请求封装为一个对象，使发出请求的责任和执行请求的责任分割开**

![DP-Command](/data/images/design/DP-Command.png)

<details>
<summary>命令模式示例代码</summary>

```java
public static void main(String[] args) {
    Command command = new ConcreteCommand();
    command.execute();
}

public interface Command {
    void execute();
}
public class ConcreteCommand implements Command {
    Receiver receiver = new Receiver();

    @Override
    public void execute() {
        receiver.action();
    }
}

public class Receiver {
    public void action() {
        System.out.println("执行命令...");
    }
}
```
</details>

### 职责链模式(Chain of Responsibility)

- 职责链模式定义
    - **把请求从链中的一个对象传到下一个对象，直到请求被响应为止。通过这种方式去除对象之间的耦合**
    - servelet中的Filter和FilterChain就是使用了责任链模式

![DP-Chain-of-Responsibility](/data/images/design/DP-Chain-of-Responsibility.png)

<details>
<summary>职责链模式示例代码</summary>

```java
public static void main(String[] args) {
    // 组装责任链
    Handler handler1 = new ConcreteHandler();
    Handler handler2 = new ConcreteHandler();
    handler1.setNext(handler2);

    // 提交请求
    handler1.handleRequest();
}

public abstract class Handler {
    protected Handler next; // 持有后继的责任对象

    // 示意处理请求的方法，虽然这个示意方法是没有传入参数的。但实际是可以传入参数的，根据具体需要来选择是否传递参数
    // 也可以通过boolean判断是否继续执行
    public abstract boolean handleRequest();

    public Handler getNext() {
        return next;
    }

    public void setNext(Handler next) {
        this.next = next;
    }
}

public class ConcreteHandler extends Handler {
    @Override
    public boolean handleRequest() {
        // 判断是否有后继的责任对象。如果有，就转发请求给后继的责任对象；如果没有，则处理请求
        if(getNext() != null) {
            System.out.println("放过请求");

            // before do somthing...
            boolean flag = getNext().handleRequest();
            // after do somthing...
            
            return flag;
        } else {
            System.out.println("处理请求");
            return true;
        }
    }
}
```
</details>

### 状态模式(State)

- 状态模式定义
    - **允许一个对象在其内部状态发生改变时改变其行为能力**
    - 此时将状态抽象出来，并让state对象去执行行为，此时传入不同的state对象。如果state的类型不会增加，其实switch case即可

<details>
<summary>状态模式示例代码</summary>

```java
/*
Player is in start state
Start State
Player is in stop state
Stop State
*/
public static void main(String[] args) {
    Context context = new Context();

    StartState startState = new StartState();
    startState.doAction(context);
    System.out.println(context.getState());

    StopState stopState = new StopState();
    stopState.doAction(context);
    System.out.println(context.getState());
}

public class Context {
    private State state;

    public Context(){
        state = null;
    }

    public void setState(State state){
        this.state = state;
    }

    public State getState(){
        return state;
    }
}

public interface State {
    void doAction(Context context);
}
public class StartState implements State {
    public void doAction(Context context) {
        System.out.println("Player is in start state");
        context.setState(this);
    }

    public String toString(){
        return "Start State";
    }
}
public class StopState implements State {
    public void doAction(Context context) {
        System.out.println("Player is in stop state");
        context.setState(this);
    }

    public String toString(){
        return "Stop State";
    }
}
```
</details>

### 观察者模式(Observer)

- 观察者模式定义
    - **多个对象间存在一对多关系，当一个对象发生改变时，把这种改变通知给其他多个对象，从而影响其他对象的行为**
    - **Observer、Listener、Hook、Callback都属于观察者模式**

<details>
<summary>观察者模式示例代码</summary>

```java
/*
具体目标发生改变...
ConcreteObserver1 response...
ConcreteObserver2 response...
*/
public static void main(String[] args) {
    IObserver observer1 = new ConcreteObserver1();
    IObserver observer2 = new ConcreteObserver2();

    Subject subject = new ConcreteSubject();
    subject.add(observer1);
    subject.add(observer2);

    subject.notifyObserver();
}

public interface IObserver {
    void response();
}
public class ConcreteObserver1 implements IObserver {
    @Override
    public void response() {
        System.out.println("ConcreteObserver1 response...");
    }
}
public class ConcreteObserver2 implements IObserver {
    @Override
    public void response() {
        System.out.println("ConcreteObserver2 response...");
    }
}

public abstract class Subject {
    protected List<IObserver> observers = new ArrayList<IObserver>();

    public void add(IObserver observer) {
        observers.add(observer);
    }

    public void remove(IObserver observer) {
        observers.remove(observer);
    }

    public abstract void notifyObserver(); // 通知观察者方法
}
public class ConcreteSubject extends Subject {
    @Override
    public void notifyObserver() {
        System.out.println("具体目标发生改变...");

        for(Object obs : observers) {
            ((IObserver)obs).response();
        }
    }
}
```
</details>

### 中介者模式(Mediator)

- 中介者模式(又称**调停者模式**)定义
    - **定义一个中介对象来简化原有对象之间的交互关系，降低系统中对象间的耦合度，使原有对象之间不必相互了解**

![DP-Mediator](/data/images/design/DP-Mediator.png)

<details>
<summary>中介者模式(简单实现)示例代码</summary>

```java
/*
具体同事类A'发出请求...
具体同事类B'收到请求...
---------------
具体同事类B'发出请求...
具体同事类A'收到请求...
*/
public static void main(String[] args) {
    Colleague colleague1 = new ConcreteColleagueA();
    Colleague colleague2 = new ConcreteColleagueB();

    colleague1.send();
    System.out.println("---------------");
    colleague2.send();
}

public interface Colleague {
    void receive();
    void send();
}
public class ConcreteColleagueA implements Colleague {
    public ConcreteColleagueA() {
        SimpleMediator.register(this);
    }

    @Override
    public void receive() {
        System.out.println("具体同事类A'收到请求...");
    }

    @Override
    public void send() {
        System.out.println("具体同事类A'发出请求...");
        SimpleMediator.relay(this); // 请中介者转发
    }
}
public class ConcreteColleagueB implements Colleague {
    public ConcreteColleagueB() {
        SimpleMediator.register(this);
    }

    @Override
    public void receive() {
        System.out.println("具体同事类B'收到请求...");
    }

    @Override
    public void send() {
        System.out.println("具体同事类B'发出请求...");
        SimpleMediator.relay(this); // 请中介者转发
    }
}

public class SimpleMediator {
    private static final List<Colleague> colleagues = new ArrayList<>();

    public static void register(Colleague c) {
        if(!colleagues.contains(c)) {
            colleagues.add(c);
        }
    }

    public static void relay(Colleague c) {
        for(Colleague obj : colleagues) {
            if(!obj.equals(c)) {
                obj.receive();
            }
        }
    }
}
```
</details>

### 迭代器模式(Iterator)

- 迭代器模式定义
    - **提供一种方法来顺序访问聚合对象中的一系列数据，而不暴露聚合对象的内部结构**
    - 参考集合的Iterator实现

![DP-Iterator](/data/images/design/DP-Iterator.png)

### 访问者模式(Visitor)

- 访问者模式定义
    - **在不改变集合元素的前提下，为一个集合中的每个元素提供多种访问方式，即每个元素有多个访问者对象访问**
    - 访问者模式能把处理方法从数据结构中分离出来，并可以根据需要增加新的处理方法，且不用修改原来的程序代码与数据结构，这提高了程序的扩展性和灵活性
    - 如：顾客在商场购物时放在购物车中的商品，顾客主要关心所选商品的性价比，而收银员关心的是商品的价格和数量，并且不同的顾客评价不一
    - `某对象.accept(访问者)` => 某对象接受访问者的访问 => 某对象会调用访问者的visit方法
- 优点
    - 扩展性好。能够在不修改对象结构的情况下，为对象结构中的元素添加新的功能
    - 符合单一职责原则。访问者模式把相关的行为封装在一起，构成一个访问者，使每一个访问者的功能都比较单一
- 缺点
    - 增加新的元素类很困难。在访问者模式中，每增加一个新的元素类，都要在每一个具体访问者类中增加相应的具体操作，这违背了开闭原则
    - 破坏封装。具体方法被从类中抽离出来了
    - 违反了依赖倒置原则。访问者模式依赖了具体类，而没有依赖抽象类

![DP-Visitor](/data/images/design/DP-Visitor.png)

<details>
<summary>访问者模式示例代码</summary>

```java
/*
BoyCustomerVisitor喜欢酒
------------
GirlCustomerVisitor不喜欢酒
*/
public static void main(String[] args) {
    Goods wine = new Wine();
    BoyCustomerVisitor boyCustomerVisitor = new BoyCustomerVisitor();
    GirlCustomerVisitor girlCustomerVisitor = new GirlCustomerVisitor();
    
    wine.accept(boyCustomerVisitor);
    System.out.println("------------");
    wine.accept(girlCustomerVisitor);
}

// 被访问着
public interface Goods {
    void accept(CustomerVisitor customerVisitor);
}
public class Wine implements Goods {
    @Override
    public void accept(CustomerVisitor customerVisitor) {
        customerVisitor.visit(this);
    }
}

// 访问着
public interface CustomerVisitor {
    void visit(Goods goods);
}
public class BoyCustomerVisitor implements CustomerVisitor {
    @Override
    public void visit(Goods goods) {
        System.out.println("BoyCustomerVisitor喜欢酒");
    }
}
public class GirlCustomerVisitor implements CustomerVisitor {
    @Override
    public void visit(Goods goods) {
        System.out.println("GirlCustomerVisitor不喜欢酒");
    }
}
```
</details>

### 备忘录模式(Memento)

- 备忘录模式定义
    - **在不破坏封装性的前提下，获取并保存一个对象的内部状态，以便以后恢复它**
    - 类似的可以将所有的类和属性实现Serializable接口，则可进行序列化存盘
    - 主要用在存盘，如游戏存档

![DP-Memento](/data/images/design/DP-Memento.png)

<details>
<summary>备忘录模式示例代码</summary>

```java
/*
原始状态:S0
新的状态:S1
恢复状态:S0
*/
public static void main(String[] args) {
    Originator originator = new Originator(); // 创造者
    Caretaker caretaker = new Caretaker(); // 守护者

    originator.setState("S0");
    System.out.println("原始状态:" + originator.getState());
    caretaker.setMemento(originator.createMemento()); // 保存状态

    originator.setState("S1");
    System.out.println("新的状态:" + originator.getState());

    originator.restoreMemento(caretaker.getMemento()); // 恢复状态
    System.out.println("恢复状态:" + originator.getState());
}

public class Memento {
    private String state;

    public Memento(String state) {
        this.state = state;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }
}

// 也可省略，直接把 Memento 保存在 Originator 中
public class Caretaker {
    private Memento memento;

    public Memento getMemento() {
        return memento;
    }

    public void setMemento(Memento memento) {
        this.memento = memento;
    }
}

public class Originator {
    private String state;

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public Memento createMemento() {
        return new Memento(state);
    }

    public void restoreMemento(Memento memento) {
        this.setState(memento.getState());
    }
}
```
</details>


### 解释器模式(Interpreter)

- 解释器模式定义
    - **提供如何定义语言的文法，以及对语言句子的解释方法，即解释器**

![DP-Interpreter](/data/images/design/DP-Interpreter.png)

<details>
<summary>解释器模式示例代码</summary>

```java
/*
文法规则：
<expression> ::= <city>的<person>
<city> ::= 上海|广州
<person> ::= 老人|妇女|儿童

结果：
您是上海的老人，您本次乘车免费！
上海的年轻人，您不是免费人员，本次乘车扣费2元！
您是广州的妇女，您本次乘车免费！
您是广州的儿童，您本次乘车免费！
山东的儿童，您不是免费人员，本次乘车扣费2元！
*/
public static void main(String[] args) {
    Context bus = new Context();
    bus.freeRide("上海的老人");
    bus.freeRide("上海的年轻人");
    bus.freeRide("广州的妇女");
    bus.freeRide("广州的儿童");
    bus.freeRide("山东的儿童");
}

public class Context {
    private Expression cityPerson;

    public Context() {
        String[] citys = {"上海", "广州"};
        String[] persons = {"老人", "妇女", "儿童"};
        Expression city = new TerminalExpression(citys);
        Expression person = new TerminalExpression(persons);
        cityPerson = new AndExpression(city, person);
    }

    public void freeRide(String info) {
        boolean ok = cityPerson.interpret(info);
        if(ok) System.out.println("您是" + info + "，您本次乘车免费！");
        else System.out.println(info + "，您不是免费人员，本次乘车扣费2元！");
    }
}

public interface Expression {
    boolean interpret(String info); // 解释方法
}

public class AndExpression implements Expression {
    private Expression city = null;
    private Expression person = null;

    public AndExpression(Expression city, Expression person) {
        this.city = city;
        this.person = person;
    }

    public boolean interpret(String info) {
        String s[] = info.split("的");
        return city.interpret(s[0]) && person.interpret(s[1]);
    }
}

public class TerminalExpression implements Expression {
    private Set<String> set= new HashSet<>();

    public TerminalExpression(String[] data) {
        set.addAll(Arrays.asList(data));
    }

    public boolean interpret(String info) {
        return set.contains(info);
    }
}
```
</details>

## 结合Spring案例

### 工厂模式、模板模式和策略模式的混合使用

- 在实际开发的过程当中，最常用的还是设计模式还是 工厂+模板+策略模式，通过模板抽象出业务流程的通用逻辑固化下来，再使用简单工厂模式生成对应的策略逻辑
- 参考
    - https://www.cnblogs.com/EthanWong/p/16045901.html
    - https://zhuanlan.zhihu.com/p/536830120
- 实例化方式
    - 结合Spring可使用继承`InitializingBean`将Bean实例化后自动注册到工厂中，但是这样存在问题服务中不能使用自定义属性
    - 通过工厂if-else进行实例化，每个请求都调用工厂实例化方法，在子类中使用Spring Bean时使用SpringU进行获取
        - 优化方案: 在工厂初始化时，基于org.reflections#reflections包自动获取接口的实现类，进行一次类信息注册(不足: 需要反射一次调用注册方法)；之后调用每次获取此类进行反射实例化




---

参考文章

[^1]: https://www.cnblogs.com/java-my-life/archive/2012/05/28/2516865.html
