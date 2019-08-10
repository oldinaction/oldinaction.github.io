---
layout: "post"
title: "设计模式"
date: "2017-08-12 09:47"
---

## 简介

- `OOA` Object-Oriented Analysis(面向对象分析方法)
- `OOD` Object-Oriented Design(面向对象设计)

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


