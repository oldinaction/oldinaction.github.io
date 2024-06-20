---
layout: "post"
title: "Java各版本新特性"
date: "2018-04-11 16:51"
categories: [java]
tags: [jdk]
---

## 简介

- [Java SE Specifications各版本规范](https://docs.oracle.com/javase/specs/index.html)

## JDK9新特性 [^3]

### 模块系统(Jigsaw)

- 在引入了模块系统之后，JDK 被重新组织成 94 个模块。Java 应用可以通过新增的 jlink 工具，创建出只包含所依赖的 JDK 模块的自定义运行时镜像。这样可以极大的减少 Java 运行时环境的大小
- Java 9 模块的重要特征是在其工件（artifact）的根目录中包含了一个描述模块的 module-info.class 文 件。 工件的格式可以是传统的 JAR 文件或是 Java 9 新增的 JMOD 文件。这个文件由根目录中的源代码文件 module-info.java 编译而来
- 示例

```java
// jdk9_module1 下 module-info.java
// module-info.java文件必须位于项目的根目录中（源码根目录，如此时和cn目录同级）。该文件用于定义模块需要什么依赖，以及那些包被外部使用
module cn.aezo.javase.jdk.jdk9_module1 {
    exports cn.aezo.javase.jdk.jdk9_module1;
}

// jdk9_module2 下 module-info.java
module cn.aezo.javase.jdk.jdk9_module2 {
    // idea的模块dependency中需要引入jdk9_module1使编译不报错
    // 如果此不通过requires导入jdk9_module1，则jdk9_module2中使用jdk9_module1的包会编译不通过
    requires cn.aezo.javase.jdk.jdk9_module1;
}
```

### JShell交互式编程环境

- 增加了REPL（Read-Eval-Print Loop）工具`jshell`，在%JAVA_HOME%/lib目录

### 接口私有方法

```java
interface Logging {
   String Database = "Mysql";
 
   private void log(String message, String prefix) {
      getConnection();
      System.out.println("Log Message : " + prefix);
      closeConnection();
   }

   default void logInfo(String message) {
      log(message, "INFO");
   }

   private static void getConnection() {
      System.out.println("Open Database connection");
   }
}
```

### VarHandle变量句柄

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

## JDK8新特性 [^1]

### Lambda表达式

- 原理 [^4]
  - 在类编译时，会生成一个私有静态方法+一个内部类
  - 在内部类中实现了函数式接口，在实现接口的方法中，会调用上述编译器生成的静态方法
  - 在使用lambda表达式的地方，通过传递内部类实例，来调用函数式接口方法
- 无法使用continue/break语句，只能使用return(相当于continue)语句
- 作用域：可以直接访问标记了final的外层局部变量，或者成员变量以及静态变量
- 变量捕获和非捕获
- Lambda表达式中的异常无法通过外层方法抛出

```java
list.forEach(item -> {
    if(item.equals("hello")) {
        return; // 相当于continue（无法终止循环）
    }
    System.out.println("item = " + item);
});

// 作用域
// Lambda表达式中无法访问外部普通局部变量（引用类型）。解决：可以将变量定义为实例变量或者将变量定义为数组
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

// 变量捕获和非捕获
list.forEach(i -> System.out.println(i)); // 非变量捕获

int origin = 10;
list.forEach(i -> System.out.println(origin + i)); // 变量捕获(内部使用非传入参数)
```

### 方法引用(::)

- `方法引用`或者说`双冒号运算`对应的参数类型是 `Function<T, R>`，T表示传入类型，R表示返回类型。基于Lambda表达式实现
- 比如表达式`person -> person.getAge();` 传入参数是person，返回值是person.getAge()，那么方法引用`Person::getAge`就对应着`Function<Person,Integer>`类型
- 示例
    - Class::new
    - Class::static_method
    - Class::method
    - instance::method
- 使用案例

    ```java
    private String getUserInfo(User user, Function<User, Object> func) {
        Object value = func.apply(user); // 如果参数为 Function<User, String> 则返回类型为 String
        return value;
    }

    // 调用
    Object username = getUserInfo(user, User::getUsername);
    Object password = getUserInfo(user, User::getPassword);
    ```

### 接口默认方法

```java
interface Formula {
    double calculate(int a);

    default double sqrt(int a) {
        return Math.sqrt(a);
    }
}
```

### 函数式接口(方法回调)

- **可以是内部类**
- 每一个lambda表达式都对应一个类型，通常是接口类型。而“函数式接口”是指仅仅只包含一个抽象方法的接口，每一个该类型的lambda表达式都会被匹配到这个抽象方法。默认方法不算抽象方法，所以可以给函数式接口添加默认方法
- 增加`@FunctionalInterface`注解是为了告诉编译器此接口只能有一个抽象方法

```java
@FunctionalInterface // 如果没有指定，下面的代码也是对的，只不过编译器不会检查
interface MyConverter<F, T> { // 如果用到了翻新，则必须定义在类上
    T convert(F from);
}

// 调用
MyConverter<String, Integer> converter = (from) -> Integer.valueOf(from);
Integer converted = converter.convert("123"); // 123

// 包装成方法回调
public static T test(F val, MyConverter<F, T> convert) {
    return convert.convert(val);
}
test("123", (from) -> Integer.valueOf(from)); // 123
```

### Streams

- Java 8 中的 `Stream` 是对集合(Collection)对象功能的增强。`java.util.stream`
    - Stream 不是集合元素，它不是数据结构并不保存数据，它是有关算法和计算的，它更像一个高级版本的 Iterator。原始版本的 Iterator，用户只能显式地一个一个遍历元素并对其执行某些操作；高级版本的 Stream，用户只要给出需要对其包含的元素执行什么操作，比如"过滤掉长度大于 10 的字符串"、"获取每个字符串的首字母"等，Stream 会隐式地在内部进行遍历，做出相应的数据转换
    - Stream 就如同一个迭代器(Iterator)，单向，不可往复，数据只能遍历一次，遍历过一次后即用尽了，就好比流水从面前流过，一去不复返
    - 而和迭代器又不同的是，Stream 可以并行化操作(依赖于 Java7 中引入的 Fork/Join 框架)，迭代器只能命令式地、串行化操作
- 常用API
    - `Intermediate`(中间操作)
        - 一个流可以后面跟随零个或多个 intermediate 操作 
        - **`filter`**(子句需返回true|false)、**`map`**(字句返回值作为后续条目)、**`peek`**(全部循环，无需返回值，可用于打印和修改条目)、distinct、sorted、limit、skip、parallel、sequential unordered
        - mapToInt、flatMap 等
    - `Terminal`(最终遍历)
        - 一个流只能有一个 terminal 操作，当这个操作执行后，流就被使用"光"了，无法再被操作(**此时进行遍历**)
        - collect、forEach、reduce、anyMatch(循环判断每一条目，只有有一个符合就整体返回true)、allMatch、findFirst
        - toArray、forEachOrdered、noneMatch、findAny、iterator、min、max、count
    - `Short-circuiting`(分流/过滤)
        - 对于一个无限大的Stream时，需要获取返回一个有限的新Stream或快速计算出值时需要进行过滤
        - anyMatch、allMatch、noneMatch、findFirst、findAny、limit
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

// 排序
Goods goods = myGoods.stream().sorted(Comparator.comparing(Goods::getNo).reversed()).findFirst().orElse(null);
// 基于List<Map>的排序
List<Map<String, Object>> collect = list.stream().sorted(Comparator.comparing(TestClass::comparingByName).collect(Collectors.toList());
Map<String, Object> recordLatest = list.stream()
                    // 过滤数据RECORD_TIM > inputTm的时间
                    .filter(x -> {
                        Date recordTim = (Date) x.get("RECORD_TIM"); // Oracle查询返回的 java.sql.Timestamp
                        return recordTim.compareTo(inputTm) > 0;
                    })
                    .sorted(Comparator.comparing(TransRecvServiceImpl::comparingByName).reversed()) // 默认升序，reversed反转(降序)
                    .findFirst().orElse(null);
private static String comparingByName(Map<String, Object> map) { // TestClass.java
    return (String) map.get("name");
}

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

// 1st argument, init value = 0
int[] numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
int sum = Arrays.stream(numbers).reduce(0, (a, b) -> a + b); // 55
int sum = Arrays.stream(numbers).reduce(0, Integer::sum);

// Map & Reduce
BigDecimal sum = invoices.stream()
                // 如果是普通对应，不是数值类型，需要先转成数值再进入reduce环节
                .map(x -> x.getNum().multiply(x.getPrice()))    // map，对集合中的元素进行操作
                // .reduce((i, j) -> i + j)                     // reduce表达式(i + j)执行完后仍然需要返回相同类型的结果
                .reduce(BigDecimal.ZERO, BigDecimal::add)       // reduce，将上一步得到的结果进行合并得到最终的结果
                .setScale(2, RoundingMode.HALF_UP);         // 四舍五入，保留2位小数

// 结合 Collectors.groupingBy (相当于MiscU.groupBy)、Collectors.reducing、Collectors.summingInt等
Product prod1 = new Product(1L, 3, "面包", "零食");
Product prod2 = new Product(2L, 4, "饼干", "零食");
Product prod3 = new Product(3L, 8, "青岛啤酒", "啤酒");
// 按照类目分组(伪代码): {"零食": [prod1, prod2], "啤酒": [prod3]}
Map<String, List<Product>> prodMap= prodList.stream().collect(Collectors.groupingBy(Product::getCategory));
// 按照多个属性分组: {"零食_面包": [prod1], "零食_饼干": [prod2], "啤酒_青岛啤酒": [prod3]}
// 也可Collectors.groupingBy嵌套使用生成多级分组(Map<String, Map<String, List<Product>>>)
Map<String, List<Product>> prodMap = prodList.stream().collect(Collectors.groupingBy(item -> item.getCategory() + "_" + item.getName()));
// 求和: {"零食": 7, "啤酒": 8}
// IntSummaryStatistics{count, sum, min, max}为某个分类的统计信息; 其他如Collectors.summarizingDouble(如果统计金额还需再进行手动取整)
Map<String, IntSummaryStatistics> prodMap = prodList.stream().collect(Collectors.groupingBy(Product::getCategory, Collectors.summingInt(Product::getNum)));

// ifPresent判断是否存在
Optional<User> firstOpt= list.stream().filter(a -> "admin".equals(a.getUserName())).findFirst();
if (firstOpt.isPresent()) {
    User admin = firstOpt.get();
} else {
    // 没有查到的逻辑，如果直接get()会得到空
}
```
- parallelStream
    - https://blog.csdn.net/u011001723/article/details/52794455

### Date/Time API(JSR 310)

- 参考[java-base.md#时间](/_posts/java/java-base.md#时间)

```java
// Clock 类。可以替代System.currentTimeMillis()和TimeZone.getDefault()
Clock clock = Clock.systemUTC();
System.out.println(clock.instant()); // 2014-04-12T15:19:29.282Z
System.out.println(clock.millis()); // 1397315969360

// LocalDate 和 LocalTime 类。包含ISO-8601日历系统中的日期和时间
LocalDate date = LocalDate.now(); // 2014-04-12
LocalTime time = LocalTime.now(); // 11:25:54.568
LocalDate dateFromClock = LocalDate.now(clock); // 通过 Clock 对象获取
LocalTime timeFromClock = LocalTime.now(clock);

// LocalDateTime类。包含了LocalDate和LocalTime的信息，但是不包含ISO-8601日历系统中的时区信息
LocalDateTime datetime = LocalDateTime.now(); // 2014-04-12T11:37:52.309
LocalDateTime datetimeFromClock = LocalDateTime.now(clock);

// ZoneDateTime类。包含了ISO-8601日期系统的日期和时间，而且有时区信息
ZonedDateTime zonedDatetime = ZonedDateTime.now(); // 2014-04-12T11:47:01.017-04:00[America/New_York]
ZonedDateTime zonedDatetimeFromClock = ZonedDateTime.now(clock); // 2014-04-12T15:47:01.017Z
ZonedDateTime zonedDatetimeFromZone = ZonedDateTime.now(ZoneId.of("America/Los_Angeles")); // 2014-04-12T08:47:01.017-07:00[America/Los_Angeles]

// Duration 类。持有的时间精确到秒和纳秒
LocalDateTime from = LocalDateTime.of(2014, Month.APRIL, 16, 0, 0, 0);
LocalDateTime to = LocalDateTime.of(2015, Month.APRIL, 16, 23, 59, 59);
Duration duration = Duration.between(from, to);
System.out.println("Duration in days: " + duration.toDays()); // Duration in days: 365
System.out.println("Duration in hours: " + duration.toHours()); // Duration in hours: 8783
```

### Nashorn JavaScript引擎

- Java 8提供了新的Nashorn JavaScript引擎，使得我们可以在JVM上开发和运行JS应用。Nashorn JavaScript引擎是javax.script.ScriptEngine的另一个实现版本，这类Script引擎遵循相同的规则，允许Java和JavaScript交互使用
- Nashorn引擎命令行工具：`jjs`，可以接受js源码并执行，如`jjs func.js`

```java
ScriptEngineManager manager = new ScriptEngineManager();
ScriptEngine engine = manager.getEngineByName("JavaScript");

System.out.println(engine.getClass().getName()); // jdk.nashorn.api.scripting.NashornScriptEngine
System.out.println("Result:" + engine.eval("function f() { return 1; }; f() + 1;")); // Result: 2
```

### Base64

- 对Base64编码的支持已经被加入到Java 8官方库中，这样不需要使用第三方库就可以进行Base64编码

```java
Base64.getEncoder().encodeToString(str); // 编码
new String(Base64.getDecoder().decode(encoded), StandardCharsets.UTF_8); // 解码

// 支持URL和MINE的编码解码
Base64.getUrlEncoder(), Base64.getUrlDecoder()
Base64.getMimeEncoder(), Base64.getMimeDecoder()
```

### @Repeatable重复注解

- 可让在一个类上重复使用同一注解（此注解被@Repeatable注解过）

### 并行数组

- 最重要的方法是`Arrays.parallelSort()`，可以显著加快多核机器上的数组排序

### 并发性

- LongAdder 使用了分段锁
- DoubleAdder

### Metaspace代替持久代PermGen space

### 其他

```java
// 类似get，区别在于如果map中没有对应key则返回执行函数，将此函数返回值put到此key上，并返回
map.computeIfAbsent(str, k -> new ArrayList<>()); // 默认有一个参数来接受 key(此处的str)
clazzMap.computeIfAbsent(clazz, Reflector::new); // public Reflector(Class<?> clazz) {} 此时 key(clazz) 会自动注入到构造函数的参数中
```

## JDK7新特性

### try-with-resources

## JDK6

### javax.script(js-java)

- 从 JDK 1.8 开始，**Nashorn**取代Rhino(JDK 1.6, JDK1.7) 成为 Java 的嵌入式 JavaScript 引擎。Nashorn 完全支持 ECMAScript 5.1 规范以及一些扩展
- Nashorn JavaScript Engine 在 Java 11 标记为forRemoval，在 Java 15 已经不可用了(manager.getEngineByName("javascript")返回值为null)。**可同引入依赖解决**
- 参考文章
    - Java 8 Nashorn 指南：https://zhuanlan.zhihu.com/p/33257346
    - Java和Js之间相互调用，无需安装依赖，相似的如[JEXL执行字符串JAVA代码](/_posts/java/java-tools.md#JEXL执行字符串JAVA代码)

```xml
<dependency>
    <groupId>org.openjdk.nashorn</groupId>
    <artifactId>nashorn-core</artifactId>
    <version>15.3</version>
</dependency>
```
- 案例

```java
@SneakyThrows
@Test
public void test() {
    // ==> 使用hutool工具简单执行
    ScriptUtil.eval("print('Script test!');"); // Script test!

    // ==> invokeFunction
    ScriptEngineManager manager = new ScriptEngineManager();
    ScriptEngine engine = manager.getEngineByName("javascript");
    // engine.eval(new java.io.FileReader(new File("/home/test/test.js")));
    engine.eval("function add(a,b) { return a+b; }");
    Invocable in = (Invocable) engine;
    System.out.println(in.invokeFunction("add",1, 1)); // 2.0

    // ==> invokeMethod
    String script = "var obj = new Object();"  + "obj.hello = function(name) {print('hello, '+name);}";
    engine.eval(script);
    Object obj = engine.get("obj");
    System.out.println("obj1 = " + obj); // obj1 = [object Object]
    Invocable inv = (Invocable) engine;
    obj = inv.invokeMethod(obj, "hello", "Script Method !!" ); // hello, Script Method !!
    System.out.println("obj2 = " + obj); // obj2 = null

    // ==> 脚本变量，和脚本引擎的多个scope
    engine.put("x", "hello word!!"); // 将变量放入到默认上下文
    // 新的上下文
    ScriptContext context = new SimpleScriptContext();
    Bindings bindings = context.getBindings(ScriptContext.ENGINE_SCOPE);
    bindings.put("x", new File("/home/test/test.js"));
    obj = engine.eval("print(x.getName());", bindings); // test.js
    System.out.println("obj3 = " + obj); // obj3 = null
    obj = engine.eval("print(x);"); // hello word!!
    System.out.println("obj4 = " + obj); // obj4 = null

    // ==> 使用Script实现java接口
    script = "function run() { print('run called'); }";
    engine.eval(script);
    Invocable invocable = (Invocable) engine;
    Runnable runnable = invocable.getInterface(Runnable.class);
    Thread thread = new Thread(runnable);
    thread.start(); // run called
}
```
- Nashorn案例

```java
// 进行Debug(js必须是文件才能在idea中进行调试): https://www.cnblogs.com/shirui/p/9430804.html

// JavaScript 中调用 Java 类参考：https://www.runoob.com/java/java8-nashorn-javascript.html
// 调用Java方法也支持事物
// JS代码
var BigDecimal = Java.type('java.math.BigDecimal');
function calculate(amount, percentage) {
    // 如果返回的是一个新的类对象，不用声明，直接使用其方法即可
    var result = new BigDecimal(amount).multiply(
    new BigDecimal(percentage)).divide(new BigDecimal("100"), 2, BigDecimal.ROUND_HALF_EVEN);
    return result.toPlainString();
}
function test() {}
var result = calculate(568000000000000000023,13.9);
print(result);
```

## 未知

### package-info.java

- 是一个Java文件，可以放到任意Java源码包执行。不过里面的内容有特定的要求，其主要目的是为了提供包级别相关的操作，比如包级别的注解、注释及公共变量
- 提供包级别的注解

```java
// 创建包注解
@Target(ElementType.PACKAGE)
@Retention(RetentionPolicy.RUNTIME)
public @interface TestPkg {}

// package-info.java文件内容
@TestPkg
package cn.aezo.test;

// 获取包注解
Package pkg = Package.getPackage("cn.aezo.test");
Annotation[] annotations = pkg.getAnnotations(); // 可获取到 TestPkg
Class test = Class.forName("cn.aezo.test.Test");
Annotation[] annotations2 = test.getAnnotations(); // Test类上并没有注解，但可获取到 TestPkg
```
- 提供包级别的变量

```java
// package-info.java文件内容
// 包类
class PACKAGE_CLASS{
    public void test(){
    }
}
// 包常量
class PACKAGE_CONST{
    public static final String TEST_01="TEST";
}

// 在包内的任意类中可使用此变量，其他包不能使用
```
- 提供包级别的注释
    - 使用JavaDoc的时候，通过在package-info.java添加注释，生成JavaDoc实现对应包的注释说明

### SPI

- `SPI`(Service Provider Interface) 是调用方来制定接口规范，提供给外部来实现，调用方在调用时则选择自己需要的外部实现。从使用人员上来说，SPI 被框架扩展人员使用 [^5]
- 核心类`java.util.ServiceLoader`
- 使用
    - 主项目中定义接口/抽象类`cn.aezo.test.IService`
    - 插件开发者，在插件项目resources目录下新建`META-INF/services`目录，然后在这个目录下新建`cn.aezo.test.IService`文件(此文件最终以jar包等形式放到classpath下)，并在这个文件中写入实现的类名`cn.aezo.test.IServiceImpl`(多个可换行写入)
    - 将插件jar放到主项目的classpath目录，**主项目通过`ServiceLoader<IService> service = ServiceLoader.load(IService.class);`**就可以加载实现类了
- dubbo作为一个高度可扩展的rpc框架，也依赖于java的SPI，并且dubbo对java原生的spi机制作出了一定的扩展，使得其功能更加强大
- Pf4j插件框架也是基于java的SPI实现





---

参考文章

[^1]: https://www.cnblogs.com/xingzc/p/6002873.html (JAVA8十大新特性详解)
[^2]: https://www.ibm.com/developerworks/cn/java/j-lo-java8streamapi/ (Java 8 中的 Streams API 详解)
[^3]: https://www.runoob.com/java/java9-new-features.html
[^4]: https://blog.csdn.net/jiankunking/article/details/79825928
[^5]: https://www.cnblogs.com/jy107600/p/11464985.html

