---
layout: "post"
title: "Junit"
date: "2021-08-19 18:28"
categories: java
tags: test
---

## 使用

### @Rule

- `@Rule`是JUnit4.7加入的新特性，有点类似于拦截器，用于在测试方法执行前后添加额外的处理。实际上是@Before，@After的另一种实现
    - 需要注解在实现了TestRule的public成员变量上或者返回TestRule的方法上
    - 相应Rule会应用于该类每个测试方法
- 允许在测试类中非常灵活的增加或重新定义每个测试方法的行为，简单来说就是提供了测试用例在执行过程中通用功能的共享的能力 [^1]
- 案例参考下文[ErrorCollector](#ErrorCollector类收集错误统一抛出)

### ErrorCollector类收集错误统一抛出

- Junit在遇到一个测试失败时，并会退出，通过ErrorCollector可实现收集所有的错误，等方法运行完后统一抛出
- 案例

```java
public class Example {
    @Rule
    public ErrorCollector collector = new ErrorCollector();

    @Test
    public void example() {					
        errorCollector.addError(new RuntimeException("error 1"));
        System.out.println("==================================");
        // 如果测试值 myVal != true 则将错误添加到collector中
        boolean myVal = false;
        collector.checkThat("error2", myVal, Is.is(true));
        // 代码执行完，此处会统一抛出错误，提示2个异常
    }		
}
```




---

参考

[^1]: https://blog.csdn.net/fanxiaobin577328725/article/details/78407199
