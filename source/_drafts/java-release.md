---
layout: "post"
title: "Java版本"
date: "2018-04-11 16:51"
categories: [java]
tags: [jdk, jdk8]
---

## java8新特性 [^1]

### Lambda表达式

- 法使用continue/break语句，只能使用return(相当于continue)语句
- Lambda表达式中的异常无法通过外层方法抛出

```java
list.forEach(item -> {
    if(item.equals("hello")) {
        return; // 相当于continue（无法终止循环）
    }
    System.out.println("item = " + item);
});

// Lambda表达式中无法访问外部普通局部变量。解决：可以将变量定义为实例变量或者将变量定义为数组
int[] runStatus = new int[3]; // 此处定义三个普通int类型则存在语法错误 (因为Lambda运行在单独的栈中，此时是将外部变量值的副本拷贝。因为外部变量定义在栈中，当Lambda表达式被执行的时候，外部变量可能已经被释放掉了)
accessDbInfos.forEach(item -> {
    switch (item.getRunStatus()) {
        case "1":
            runStatus[0]++;
        case "2":
            runStatus[2]++;
        default:
            runStatus[3]++;
    }
});
```

### 方法引用

- Class::new
- Class::static_method
- Class::method
- instance::method

### Streams

- Java 8 中的 `Stream` 是对集合(Collection)对象功能的增强。`java.util.stream`
    - Stream 不是集合元素，它不是数据结构并不保存数据，它是有关算法和计算的，它更像一个高级版本的 Iterator。原始版本的 Iterator，用户只能显式地一个一个遍历元素并对其执行某些操作；高级版本的 Stream，用户只要给出需要对其包含的元素执行什么操作，比如"过滤掉长度大于 10 的字符串"、"获取每个字符串的首字母"等，Stream 会隐式地在内部进行遍历，做出相应的数据转换
    - Stream 就如同一个迭代器(Iterator)，单向，不可往复，数据只能遍历一次，遍历过一次后即用尽了，就好比流水从面前流过，一去不复返
    - 而和迭代器又不同的是，Stream 可以并行化操作(依赖于 Java7 中引入的 Fork/Join 框架)，迭代器只能命令式地、串行化操作
- 常用API
    - `Intermediate`(中间操作)
        - 一个流可以后面跟随零个或多个 intermediate 操作 
        - map (mapToInt, flatMap 等)、 filter、 distinct、 sorted、 peek、 limit、 skip、 parallel、 sequential、 unordered
    - `Terminal`(最终遍历)
        - 一个流只能有一个 terminal 操作，当这个操作执行后，流就被使用"光"了，无法再被操作(**此时进行遍历**)
        - forEach、 forEachOrdered、 toArray、 reduce、 collect、 min、 max、 count、 anyMatch、 allMatch、 noneMatch、 findFirst、 findAny、 iterator
    - `Short-circuiting`(分流/过滤)
        - 对于一个无限大的Stream时，需要获取返回一个有限的新Stream或快速计算出值时需要进行过滤
        - anyMatch、 allMatch、 noneMatch、 findFirst、 findAny、 limit
- 简单示例

```java
// ## 构造流
// 1. Individual values
Stream stream = Stream.of("a", "b", "c");
// 2. Arrays
String [] strArray = new String[] {"a", "b", "c"};
stream = Stream.of(strArray);
stream = Arrays.stream(strArray);
// 3. Collections
List<String> list = Arrays.asList(strArray);
stream = list.stream();

// ## 使用流
// stream() 获取myGoods数组的 source；filter 和 mapToInt 为 intermediate 操作，进行数据筛选和转换；最后一个 sum() 为 terminal 操作，对符合条件的数据作重量求和
int sum = myGoods.stream()
                .filter(g -> g.getColor() == "RED")
                .mapToInt(g -> g.getNum()) // g.getNum()必须返回int类型。此时流中只有num的值
                .sum();

List<String> list = myGoods.stream()
                            .map(item -> item.getColor()) // 等同于 `.map(Good::getColor)`
                            // .sorted((a, b) -> {return a.compareTo(b);}) // 升序排列
                            .sorted(String::compareTo)  // 升序排列(根据上面返回的值)
                            // .sorted(Comparator.reverseOrder()) // 降序排列
                            .collect(Collectors.toList());

Goods goods = myGoods.stream().sorted(Comparator.comparing(Goods::getNo).reversed()).findFirst().orElse(null);

myGoods.stream()
        .map(item -> item.getColor())
        .sorted(String::compareTo)
        .forEach(dbNo -> {
            System.out.println("dbNo = " + dbNo);
        });

List<Integer> nos = students
                    .stream()
                    .map(o -> Integer.valueOf(o.getNo())) // 取出学生编号并转成int（不能用mapToInt）
                    .sorted()
                    .collect(Collectors.toList());
```

- parallelStream
    - https://blog.csdn.net/u011001723/article/details/52794455




---

参考文章

[^1]: https://www.cnblogs.com/xingzc/p/6002873.html (JAVA8十大新特性详解)
[^2]: https://www.ibm.com/developerworks/cn/java/j-lo-java8streamapi/ (Java 8 中的 Streams API 详解)