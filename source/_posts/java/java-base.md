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

## 时间

- GMT、UTC、CST [^1]
    - `GMT`：格林尼治平时(Greenwich Mean Time，GMT)是指位于英国伦敦郊区的皇家格林尼治天文台的标准时间。由于地球自转导致存在误差，因此格林尼治时间已经不再被作为标准时间使用。现在的标准时间，是由原子钟报时的协调世界时间(UTC)
        - 当 Timestamp 为 0，就表示时间(GMT)1970年1月1日0时0分0秒。中国使用北京时间，处于东 8 区，相应就是早上 8 点
    - `UTC`：协调世界时，又称世界标准时间或世界协调时间，简称UTC(Universal Time Coordinated)。是最主要的世界时间标准，其以原子时秒长为基础，在时刻上尽量接近于格林尼治标准时间
    - `CST` China Standard Time 中国标准时间(北京时间)。在时区划分上，属东八区，比协调世界时早8小时，记为`UTC+8`(CST=GMT+8)
        - 但是CST的缩写还是其他几个时间的缩写：Central Standard Time (USA) UT-6:00、Central Standard Time (Australia) UT+9:30、China Standard Time UT+8:00、Cuba Standard Time UT-4:00
    - ISO8061和UTC
        - `ISO8601`时间格式如：2018-6-5T11:46:50Z
        - `UTC`时间格式: 2018-06-05T03:46:50+08:00。其中"T"用来分割日期和时间，时间后面跟着的"-07:00"表示西七区，"+08:00"表示东八区。时区默认是0时区，可以用"Z"表示，也可以不写。对于我国，要使用"+08:00"，表示东八区
- `Date`记录的是1970至今的毫秒数，不保存时区信息(因为时间戳和时区没有关系)
- 时间转换

```java
// https://docs.oracle.com/javase/9/docs/api/java/text/SimpleDateFormat.html
// 使用System.out.println来输出一个时间的时候，他会调用Date类的toString方法，而该方法会读取操作系统的默认时区来进行时间的转换
// TimeZone.setDefault(TimeZone.getTimeZone("GMT")); // 先运行此行，再打印new Date(0)，则是 `Thu Jan 01 00:00:00 CST 1970`
System.out.println(new Date(0)); // Thu Jan 01 08:00:00 CST 1970
// (此代码上文没有执行TimeZone.setDefault)此方法无法获取美国洛杉矶时间。getInstance并没有将系统默认时区设置成传入的时区
System.out.println(Calendar.getInstance(TimeZone.getTimeZone("America/Los_Angeles")).getTime()); // Wed Nov 06 16:47:23 CST 2019
// 获取美国洛杉矶时间
TimeZone.setDefault(TimeZone.getTimeZone("America/Los_Angeles")); // 设置系统默认时区(不会真正修改操作系统默认时区)
System.out.println(new Date()); // Wed Nov 06 00:45:19 PST 2000 (上海时间为 2000-11-6 16:45:19)

// Java 8与时区(Asia/Shanghai)
System.out.println(LocalDateTime.now()); // 2000-11-06T16:50:00.375
System.out.println(LocalDateTime.now(ZoneId.of("America/Los_Angeles"))); // 2000-11-06T00:50:00.375 (上海时间为 2000-11-06T16:50:00.375)

// 1.UTC格式时间转java.util.Date
// 当前时间 2000-01-01 10:00:00
new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())); // 2000-01-01 10:00:00
// 其中 T代表后面跟着时间，Z代表UTC统一时间
new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ").format(new Date())); // 2000-01-01T10:00:00+0800
```

## 易错点

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


---

参考文章

[^1]: https://www.hollischuang.com/archives/3082
