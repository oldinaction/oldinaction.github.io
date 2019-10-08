---
layout: "post"
title: "Java基础"
date: "2017-12-12 10:07"
categories: [java]
tags: [javase]
---

## 类

### 内部类
    
- `Class.this`使用

```java
class Outer{
    String data = "外部类別";

    public class Inner{
        String data = "內部类別";
        public String getOuterData() {
            // 有时会看到Class.this的使用，这个用法多用于在nested class(内部类)中，当inner class(内部类)必顺使用到outer class(外部类)的this instance(实例)时
            return Outer.this.data;
        }
    }
}
```

### 枚举

```java
// ## 简单使用：Color.BLUE当成常量，亦可以在switch case中使用
public enum Color {
    // 当定义一个枚举类型(Color)时，每一个枚举类型成员(BLUE)都可以看作是 Enum 类的实例，这些枚举成员默认都被 public static final 修饰
    RED, BLUE, GREEN, BLACK;
}

// ## 枚举类型自定义属性
enum FlowStatus {
    // 实例化 SUBSCRIBE 等枚举成员
    SUBSCRIBE("已订阅", 1), SEARCHING("查询中", 2), SEARCH_SUCCESS("已返回", 3), SEARCH_FAILED("返回失败", 4);

    // 必须要定义枚举类型的属性和构造方法，实例化时会调用
    private @Getter @Setter String name; // @Getter为Lombok插件
    private @Getter @Setter int status;
    FlowStatus(String name, int status) {
        this.name = name;
        this.status = status;
    }
    // 覆盖toString方法，可省略
    @Override
    public String toString() {
        return this.name + "-" + this.status; // System.out.println(FlowStatus.SUBSCRIBE.toString()); // 输出：已订阅-1
    }
}

// ## EnumMap 与 EnumSet。使用EnumMap保存枚举类型成员比HashMap高效
public enum DataBaseType {
    MYSQL, ORACLE, DB2, SQLSERVER
}

private EnumMap<DataBaseType, String> urls = new EnumMap<DataBaseType, String>(DataBaseType.class);
urls.put(DataBaseType.MYSQL, "jdbc:mysql://localhost:3306/test");
urls.put(DataBaseType.ORACLE, "jdbc:oracle:thin:@localhost:1521:test");
urls.put(DataBaseType.DB2, "jdbc:db2://localhost:5000/test");
urls.put(DataBaseType.SQLSERVER, "jdbc:microsoft:sqlserver://sql:1433;Database=test");

for(Operation op : EnumSet.range(DataBaseType.MYSQL, DataBaseType.MYSQL)) {
    doSomeThing(op);
}

// ## 枚举类型继承某接口
private static enum YellEnum implements Yell {
    DOG {
        @Override
        public void yell() {
            System.out.println("哇哇~");
        }
    },
    CAT {
        @Override
        public void yell() {
            System.out.println("喵喵~");
        }
    };
}
```


## 集合

## 易错点

- 时间转换

```java
// https://bbs.csdn.net/topics/390666151
// https://docs.oracle.com/javase/9/docs/api/java/text/SimpleDateFormat.html
// 2013-11-17T11:59:22+08:00 UTC(世界协调时间格式)
formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX"); // 2013-11-17 11:59:22
// 2013-11-17T11:59:22+0800
formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssX"); // 2013-11-17 11:59:22

// 1970-01-01T00:00:00.007Z
formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
```

- final

```java
// final Integer i = 1;
// i = 2;// 语法错误

// final Map map = new HashMap();
// map.put("a", 1); // 运行正常
// map = new HashMap(); // 语法错误

for (int i = 0; i < list.size(); i++) {
    final Map map = list.get(i); // 赋值正常，后面同样不能变更map引用
}
```
- mkdir和mkdirs

```java
// 创建此抽象路径名指定的目录。如果父目录不存在不会自动创建，也不会报错，返回false
boolean mkdir()
// 创建此抽象路径名指定的目录，包括创建必需但不存在的父目录 
boolean mkdirs()
```
