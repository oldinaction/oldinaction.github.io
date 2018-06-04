---
layout: "post"
title: "Java版本"
date: "2018-04-11 16:51"
categories: [java]
tags: [jdk, jdk8]
---

## java8新特性 [^1]

- Lambda表达式

```java
// (1) 无法使用continue/break语句，只能使用return语句
list.forEach(item -> {
    if(item.equals("hello")) {
        return; // 相当于continue（无法终止循环）
    }
    System.out.println("item = " + item);
});

// (2) Lambda表达式中的异常无法通过外层方法抛出
```


---

参考文章

[^1]: [JAVA8十大新特性详解](https://www.cnblogs.com/xingzc/p/6002873.html)