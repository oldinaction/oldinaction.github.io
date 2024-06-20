---
layout: "post"
title: "Java基础"
date: "2017-12-12 10:07"
categories: [java]
---

## 安装

```bash
# JDK 下载镜像网站
https://repo.huaweicloud.com/java/jdk/
http://www.codebaoku.com/jdk/jdk-index.html
```

## 命令

- 打包jar

```bash
# 将当前目录下所有目录/文件及子目录打包成jar
jar cvf demo.jar *
jar cvf demo.war *
```

## 运算/控制语句

- 常用

```java
// 取余
int c = 10 % 3; // 1
// 取整
int c = 10 / 3; // 3
// 精度
double c = 10 / 3; // 3.0
double c = (double) 10 / 3; // 3.3333333333333335
// 向上取整
int c = (int) Math.ceil((double) 10 / 3); // 4
int c = NumberUtil.ceilDiv(10, 3); // 4  cn.hutool.core.util.NumberUtil
```
- `<<` 左移，乘以2^x。如：3 << 4 = 3 * 2^4 = 48
- `>>` 右移，除以2^x，被除数比除数小则为0。如：32 >> 3 = 32 / 2^3 = 4; 4 >> 3 = 4 / 2^3 = 0
- goto写法

```java
breakFor : for (int i = 0; i < 100; i++) {
    for (int j = 0; j < 100; j++) {
        if (j % 15 == i) {
            break breakFor;
        }
    }
}
```

## 字符串

```java
MessageFormat.format("hello {0}, date {1}", "bob", new Date());
```

## 类

### 内部类
    
- `Class.this`使用

```java
class Outer {
    String data = "外部类別";

    // 必须先实例化外部类，才能实例化内部类。否则报错 is not an enclosing class
    /*
        Outer outer = new Outer();
        Outer.Inner inner = outer.new Inner();
    */
    public class Inner {
        String data = "內部类別";
        public String getOuterData() {
            // 有时会看到ClassXXX.this的使用，这个用法多用于在nested class(内部类)中，当inner class(内部类)必顺使用到outer class(外部类)的this instance(实例)时
            return Outer.this.data;
        }
    }

    // 无需实例化外部类
    public static class Inner2 {

    }
}
```

### 匿名类及其构造函数

```java
// 此时传入hello是因为父类构造函数需要
Child c = new Father("hello") {
    {
        // 相当于构造函数
        System.out.println("匿名类虽然没有名字，但可以有一个初始化块来充当构造函数");
    }
};
// 实现接口
MyInterfaceImpl o = new MyInterface() {
    void hello() {
        // 实现接口方法
    }
};
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

### 继承

- 属性覆盖问题

```java
@Data
public class Test {
    public final List list = MiscU.Instance.toList("1");

    public void print() {
        // 父类中的方法，直接 . 获取属性，多态情况下也是取的父类数据
        System.out.println("list = " + list);
        // 父类中的方法，执行get方法获取属性时，会通过多态去读取子类的
        System.out.println("this.getList = " + this.getList());
    }

    public static void main(String[] args) {
        // list = [1]
        // this.getList = [2]
        TestChild child = new TestChild();
        child.print();
    }
}

@Data
class TestChild extends Test {
    public final List list = MiscU.Instance.toList("2");
}

class TestMain {
    public static void main(String[] args) {
        // list = [1]
        // this.getList = [2]
        Test test = new TestChild();
        // TestChild test = new TestChild(); // 则打印 // test.list = [2]
        test.print();
        System.out.println("test.list = " + test.list); // test.list = [1]
    }
}
```

### 泛型

- 获取`T.class`示例，但是前提条件时必须有继承

```java
public class BaseEntityWrapper<E, V> {
    Class<V> targetClass;

    public BaseEntityWrapper() {
        targetClass = (Class<V>) ((ParameterizedType) getClass().getGenericSuperclass()).getActualTypeArguments()[1];
    }

    public Class<V> getTargetClass() {
        return this.targetClass;
    }

    public static void main(String[] args) {
        // 可正常打印：cn.aezo.sqbiz.application.module.system.vo.MenuVo
        MenuWrapper menuWrapper = new MenuWrapper();
        System.out.println("getTargetClass = " + menuWrapper.getTargetClass());

        // 实例化时报错：java.lang.ClassCastException: java.lang.Class cannot be cast to java.lang.reflect.ParameterizedType
        BaseEntityWrapper<Menu, MenuVo> baseEntityWrapper = new BaseEntityWrapper<>();
        System.out.println("getTargetClass = " + baseEntityWrapper.getTargetClass());
    }
}

public class MenuWrapper extends BaseEntityWrapper<Menu, MenuVo>  {

}
```
- 方法级别泛型

```java
// 调用者
public static RuntimeException sneakyThrow(Throwable t) {
    if (t == null) throw new NullPointerException("t");
    return Lombok.<RuntimeException>sneakyThrow0(t); // 调用有泛型的方法
}
// 泛型方法
private static <T extends Throwable> T sneakyThrow0(Throwable t) throws T {
    throw (T)t;
}

// 调用者
public Result test() {
    return Util.foo(); // 此时不会编译报错
}
// 泛型方法，对应的Util类无需增加泛型标识
public static <T> T foo() {}
```
- 泛型传参

```java
List<EnvironmentPostProcessor> loadPostProcessors() {
    // 传入泛型 T 的类
    return SpringFactoriesLoader.loadFactories(EnvironmentPostProcessor.class, getClass().getClassLoader());
}

public static <T> List<T> loadFactories(Class<T> factoryClass, @Nullable ClassLoader classLoader) {
    Class<?> instanceClass = ClassUtils.forName("cn.aezo.test.EnvironmentPostProcessor", classLoader);
    // 父类.class.isAssignableFrom(子类.class) 判断是否为类继承
    if (!factoryClass.isAssignableFrom(instanceClass)) {
        throw new IllegalArgumentException(
                "Class [" + instanceClassName + "] is not assignable to [" + factoryClass.getName() + "]");
    }
    T t = (T) ReflectionUtils.accessibleConstructor(instanceClass).newInstance();
    // ...
}
```

### 注解

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface SysLog {
    String type() default "";
    String[] paramPath() default {};
}
```

### 序列化

```java
import java.io.*;

public class SerializationExample {
    public static void main(String[] args) {
        // 创建一个对象并设置值
        Person person = new Person("John", 30);

        // 将对象序列化到文件
        try {
            FileOutputStream fileOut = new FileOutputStream("person.ser");
            ObjectOutputStream out = new ObjectOutputStream(fileOut);
            out.writeObject(person);
            out.close();
            fileOut.close();
            System.out.println("对象已序列化到person.ser文件");
        } catch (IOException e) {
            e.printStackTrace();
        }

        // 将文件中的对象反序列化
        try {
            FileInputStream fileIn = new FileInputStream("person.ser");
            ObjectInputStream in = new ObjectInputStream(fileIn);
            Person serializedPerson = (Person) in.readObject();
            in.close();
            fileIn.close();

            System.out.println("反序列化得到的对象：");
            System.out.println("姓名：" + serializedPerson.getName());
            System.out.println("年龄：" + serializedPerson.getAge());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

// 条件1：只要实现了 Serializable 接口的类才能被序列化
class Person implements Serializable {
    // 条件2：该类的所有属性必须是可序列化的。如果有一个属性不需要可序列化的，则该属性必须注明是瞬态的，使用transient 关键字修饰，使用static关键字修饰的属性同样不可被序列化，因为序列化保存的是对象的状态而不是类的状态
    private String name;
    private int age;
    private transient cardNo; // 不会被序列化

    // Serializable 接口给需要序列化的类，提供了一个序列版本号
    // serialVersionUID 该版本号的目的在于验证序列化的对象和对应类是否版本匹配
    // 如果没有定义 serialVersionUID，编译器会自动声明一个，这样有当增删对象属性就会出现不一样的情况导致原来序列化的数据无法被反序列化
    private static final Long serialVersionUID = 1L;

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public int getAge() {
        return age;
    }
}

// 序列化对象
public static byte[] serialize(Object obj) throws Exception {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    ObjectOutputStream oos = new ObjectOutputStream(baos);
    oos.writeObject(obj);
    return baos.toByteArray();
}

// 反序列化对象
public static Object deserialize(byte[] bytes) throws Exception {
    ByteArrayInputStream bais = new ByteArrayInputStream(bytes);
    ObjectInputStream ois = new ObjectInputStream(bais);
    return ois.readObject();
}
```
- 其他说明
    - 对象只要实现Serializable接口，即可被序列化，包含可序列化父类的属性（尽管父类实现了Map即可也能序列化父类的其他属性）
    - 像fastjson、jackson等工具类，将对象转成json字符串时，如果继承了Map即可，则默认会忽略其他属性，仅会序列化Map的值，貌似可以显示指定
    - 如果一个对象集成了Map接口，则在IDEA中debugger的时候只会显示Map中的属性，如果需要类的其他属性，可右键对象 - View as - Object(此处默认选中的是Map)

## 集合

- 参考[容器](/_posts/java/concurrence.md#容器)
- ConcurrentModificationException问题
    - 用for循环遍历List删除元素时，需要注意索引会左移(i--)的问题
    - 使用foreach遍历List删除元素，不能直接调用list.remove。主要是foreach本质是调用iterator，则只能用iterator.remove移除元素
    - 可直接通过list.iterator()获取iterator对象，再遍历时通过iterator.remove移除元素
- 集合的for循环必须判空(NULL)，如`for(Object o : list)`和`list.forEach(o -> {})`均需要判空

## 流

- 字节字符流 [^2]

    ![字节字符流](/data/images/java/java-io1.png)
- 处理流

    ![处理流](/data/images/java/java-io2.png)

    - `BufferedReader#readLine`
        - `new BufferedReader(new InputStreamReader(new FileInputStream("c:/test.text"))).readLine()` InputStreamReader起到把字节流转换成字符流
- java之从命令行获取数据的三种方式: https://www.cnblogs.com/myhomepages/p/16513807.html

## 文件

- 获取src和classpath下文件路径 [^3]

```java
/**
* 基于流从classpath获取文件内容(一般用于读取文本文件)
* @param srcXpath 如：data.json，/spring/config.xml
* @throws Exception 如找不到相关文件时会报错
* @return java.lang.String
*/
@SneakyThrows
public static String getFileContentByClasspath(String srcXpath) {
    if (!srcXpath.startsWith("/")) {
        srcXpath = "/" + srcXpath;
    }

    String content;
    InputStream inputStream = FileU.class.getResourceAsStream(srcXpath);
    BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, "utf-8"));
    StringBuilder builder = new StringBuilder();
    char[] charArray = new char[200];
    int number;
    while ((number = reader.read(charArray)) != -1) {
        builder.append(charArray, 0, number);
    }
    content = builder.toString();
    return content;
}

/**
* 基于流读取classpath文件并生成临时文件返回(一般用于读取二进制文件)<br/>
* 1.SpringBoot打包成jar后无法直接返回File，此方式是生成一个临时文件，使用完之后建议删除临时文件<br/>
* 2.下列方式在IDEA中可获取，打包成(SpringBoot)JAR后无法获取<br/>
*
* ResourceUtils.getFile(ResourceUtils.CLASSPATH_URL_PREFIX + "data.json"); // spring<br/>
* FileUtil.file(getClass().getClassLoader().getResource("data.json")); // hutool<br/>
* FileUtil.file(ResourceUtil.getResource("data.json")); // hutool<br/>
* FileU.getFileByClasspath("data.json"); // 同 getClass().getClassLoader().getResource("data.json")<br/>
*
* @param relativePath
* @throws Exception 如找不到相关文件时会报错
* @return java.io.File
*/
@SneakyThrows
public static File getFileTempByClasspath(String relativePath) {
    File tempFile = null;
    InputStream in = null;
    try {
        ClassPathResource classPathResource = new ClassPathResource(relativePath);
        in = classPathResource.getStream();
        tempFile = File.createTempFile(UUID.randomUUID().toString(), "");
        FileUtil.writeFromStream(in, tempFile);
    } finally {
        if(in != null) {
            IoUtil.close(in);
        }
    }
    return tempFile;
}

/**
* 根据classpath获取文件(SpringBoot打包成jar后，此方法无效) {@link FileU#getFileTempByClasspath}
* @param relativePath 相对classpath的路径, 开头不需要/ (如：cn/aezo/utils/data.json)
* @return
*/
public static File getFileByClasspath(String relativePath) {
    URL url = FileU.class.getClassLoader().getResource(relativePath);
    if(url == null) {
        return null;
    }
    return new File(url.getFile());
}

// 使用本地路径获取(仍然无法获取springboot jar中的文件)
new File(System.getProperty("user.dir") + "/src/main/data.json")
```

## 时间

- GMT、**UTC**、CST [^1]
    - `GMT`：格林尼治平时(Greenwich Mean Time，GMT)是指位于英国伦敦郊区的皇家格林尼治天文台的标准时间。由于地球自转导致存在误差，因此格林尼治时间已经不再被作为标准时间使用。现在的标准时间，是由原子钟报时的协调世界时间(UTC)
        - 当 Timestamp 为 0，就表示时间(GMT)1970年1月1日0时0分0秒。中国使用北京时间，处于东 8 区，相应就是早上 8 点
    - `UTC`：协调世界时间，又称世界标准时间或世界协调时间，简称`UTC(Universal Time Coordinated)`。是最主要的世界时间标准，其以原子时秒长为基础，在时刻上尽量接近于格林尼治标准时间
    - `CST` China Standard Time 中国标准时间(北京时间)。在时区划分上，属东八区，比协调世界时早8小时，记为`UTC+8`(`CST=GMT+8`)
        - 但是CST的缩写还是其他几个时间的缩写：`Central Standard Time (USA) UT-6:00`、`Central Standard Time (Australia) UT+9:30`、`China Standard Time UT+8:00、Cuba Standard Time UT-4:00`
- 时间字符串
    - `ISO-8061`格式
        - ISO-8601的标准格式是：`YYYY-MM-DDTHH:mm:ss.sssZ`
            - T仅仅为分隔日期和时间
            - Z为时区，指定Z时表示UTC时间，不指定时表示的是本地时间，可以取值：`Z`(UFC)、`Z+HH:mm`、`Z-HH:mm`("-07:00"表示西七区，"+08:00"表示东八区，时区默认是0时区，可以用Z表示)
            - UTC时间 2000-01-01T16:00:00.000Z 等同于本地时间（东八区） 2000-01-02 00:00:00
    - `RFC-2822` 格式
        - 如：`Thu Jan 01 1970 00:00:00 GMT+0800`、`Thu Jan 01 1970 00:00:00 GMT+0800 (CST)`
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
System.out.println(new Date()); // Wed Nov 06 00:00:00 PST 2000 (上海时间为 2000-11-6 16:00:00)

// Java 8与时区(Asia/Shanghai)
System.out.println(LocalDateTime.now()); // 2000-11-06T16:00:00.000
System.out.println(LocalDateTime.now(ZoneId.of("America/Los_Angeles"))); // 2000-11-06T00:00:00.000 (上海时间为 2000-11-06T16:00:00.000)

// 1.UTC格式时间转java.util.Date
// 当前时间 2000-01-01 10:00:00
new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date())); // 2000-01-01 10:00:00
// 其中 T代表后面跟着时间，Z(+0800)/z(CST)/X(+08)代表UTC时区
new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ").format(new Date())); // 2000-01-01T10:00:00+0800

// SimpleDateFormat说明
SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
// 打印结果分别为: 设置为GMT,不设置为GMT
dateFormat.setTimeZone(TimeZone.getTimeZone("GMT"));
try {
    Date dateTmp = dateFormat.parse("1970-01-01 00:00:00");
    // Thu Jan 01 08:00:00 CST 1970,Thu Jan 01 00:00:00 CST 1970
    System.out.println(dateTmp);
} catch (ParseException e) {
    e.printStackTrace();
}
// 1970-01-01 00:00:00,1970-01-01 08:00:00
String dateStrTmp = dateFormat.format(new Date(0));
System.out.println(dateStrTmp);
```
- 时间相关方法

```java
LocalDate startTm = LocalDate.now().with(TemporalAdjusters.firstDayOfMonth()); // 获取本月开始
LocalDate endTm = LocalDate.now().with(TemporalAdjusters.lastDayOfMonth()); // 获取本月结束
// 字符串转LocalDate
LocalDate startTm2 = LocalDate.parse((CharSequence) params.get("startTm"), DateTimeFormatter.ofPattern("yyyy-MM-dd"));
```

## 数字计算

- BigDecimal计算绩效基数

```java
LocalDate startTm = LocalDate.now().with(TemporalAdjusters.firstDayOfMonth());
LocalDate endTm = LocalDate.now().with(TemporalAdjusters.lastDayOfMonth());
Period diff = Period.between(startTm, endTm);
Float baseTime = new BigDecimal(diff.getDays() + 1)
                .divide(new BigDecimal(365), 4, BigDecimal.ROUND_HALF_UP) // 保留4位小数，四舍五入
                .multiply(new BigDecimal(261)) // 月平均计薪天数 = (365天-104天休息日) ÷ 12月 = 21.75天
                .multiply(new BigDecimal(7)) // 一天按照7小时计算
                .setScale(2, BigDecimal.ROUND_HALF_UP)
                .floatValue();
```

## 反射

- 简单使用

```java
Class clazz = Class.forName("cn.aezo.test.MyService"); // obj.getClass();
Method method = clazz.getMethod("test", String.class, int.class);
Object ret = method.invoke(clazz.newInstance(), "hello", 1);
```
- 和spring结合

```java
@RequestMapping("/doPost/{serviceName}/{methodName}")
public Result doPost(@PathVariable("serviceName") String serviceName, @PathVariable("methodName") String methodName,
                        @RequestBody Map<String, Object> paramsMap) {
    // 或者使用 ReflectU.invoke 来解决 ReflectUtil 反射获取不到最终异常
    Object object = SpringU.getObject(serviceName);
    return (Result) ReflectUtil.invoke(object, methodName, args);
}
```
- 可通过反射获取运行时对象，减少依赖；如java库依赖的包为编译级别，由用户决定是否引入此依赖，此时在java库中可通过反射调用此依赖对应方法(或抽象成接口，此时只要客户引入了就不会报错找不到方法)

## 类加载器

- 获取资源
    - 获取class资源
        - Enumeration<URL> paths = ClassLoader.getSystemResources("org/slf4j/impl/StaticLoggerBinder.class");
        - Enumeration<URL> paths = classLoader.getResources("org/slf4j/impl/StaticLoggerBinder.class");

## JDBC

- Mysql连接JDBC为例
- 先在Mysql官网下载驱动JDBC(Mysql Drivers提供了很多语言的驱动)：mysql-connector-java-5.0.8
- 导包：在项目上右键->Build Path->Add External archives->mysql-connector-java-5.0.8-bin.jar
- 示例如下

```java
package cn.aezo.mysql;

import java.sql.*;

public class ConnectionMySQL {
    public static final String URL = "jdbc:mysql://127.0.0.1:3306/test";//或者jdbc:mysql://127.0.0.1:3306/test?user=用户名&password=密码
    public static final String USERNAME = "root";
    public static final String PASSWORD = "root";
    
    public static void main(String[] args) throws SQLException {
        Connection conn = null;
        // 执行conn.createStatement()和conn.prepareStatement()的时候，实际上都是相当与在数据库中打开了一个cursor
        // 如果createStatement和prepareStatement是在一个循环里面的话，就会非常容易出现ORA-01000: 超出打开游标的最大数。因为游标一直在不停的打开，而且没有关闭
        // createStatement和prepareStatement都应该要放在循环外面，而且使用了这些Statment后，及时关闭。最好是在执行了一次executeQuery、executeUpdate等之后，如果不需要使用结果集（ResultSet）的数据，就马上将Statment关闭，调用close()方法
        Statement stmt = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            // 实例化驱动，注册驱动(实例化时自动向DriverManager注册，不需显示调用DriverManager.registerDriver方法)
            Class.forName("com.mysql.jdbc.Driver");//或者new com.mysql.jdbc.Driver();
            // 获取数据库的连接
            conn = DriverManager.getConnection(URL, USERNAME, PASSWORD);  
            
            // ====== Statement方式
            stmt = conn.createStatement();
            rs = stmt.executeQuery("select * from user where id = 1");
            while(rs.next()) {
                System.out.println(rs.getInt("id"));  
                System.out.println(rs.getString("username"));  
                System.out.println(rs.getString("password"));  
            }

            // ====== PreparedStatement方式
            String sql = "INSERT INTO user(name) VALUES (?)";
            // 返回插入后生成的主键
            // ps = conn.prepareStatement(sql, {"id"}); // oracle(也适用于mysql)
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS); // 常用，如mysql
            ps.setString(1, "smalle");
            ps.executeUpdate();
            ResultSet generatedKeys = ps.getGeneratedKeys();
            while (generatedKeys.next()) {
                long generateKey = generatedKeys.getLong(1); // 返回的主键
            }

            // ====== PreparedStatement批量执行sql
            conn.setAutoCommit(false); // 关闭自动提交
			ps = conn.prepareStatement("insert into user(name,passwd) values(?,?)");

            ps.setString(1, "zhangsan");
            ps.setString(2, "123");
            ps.addBatch();

            ps.setString(1, "lisi");
            ps.setString(2, "456");
            ps.addBatch();

            ps.executeBatch(); // 批量执行sql
            ps.commit(); // 手动提交
        } catch (ClassNotFoundException e) {
            System.out.println("驱动类没有找到！");
            e.printStackTrace();  
        } catch (SQLException e) {  
            e.printStackTrace();  
        } finally {
            // 释放资源
            try {
                if(rs != null) {
                    rs.close();
                    rs = null;
                }
                if(stmt != null) {
                    stmt.close();
                    stmt = null;
                }
                if(ps != null) {
                    ps.close();
                    ps = null;
                }
                if(conn != null) {
                    conn.close();
                    conn = null;
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }	
        } 
    }  
}
```

## JNI和JNA

- JNI: Java Native Interface
- JNA: Java Native Access, 提供一组Java工具类用于在运行期间动态访问系统本地库（native library：如Window的dll）而不需要编写任何Native/JNI代码
- 参考文章
    - 基于JNI
        - https://blog.csdn.net/u011720560/article/details/77689168
        - IntelliJ IDEA 平台下 JNI 编程: https://juejin.cn/post/6844903458844213262
    - 基于JNA
        - https://www.mdnice.com/writing/9a66c7f4a37548a79aece51e0ffb50ba
- 说明JDK的版本和DLL的版本要对应(和操作系统版本没有关系，主机只需要能运行JDK即可)，如JDK 64位只能调用64位的DLL

## 易错点

- 基础语法

```java
// ==> Null问题
Boolean a = null;
if(a) { // NullPointerException
    System.out.println("hello");
}

// ==> Int转换
Integer.valueOf("2.0"); // NumberFormatException
NumberUtil.parseInt("2.0"); // 使用hutool工具转换会自动去掉小数点及之后字符
```
- 引用问题

```java
public static void main(String[] args) {
    Map<String, Object> map = new HashMap<>();
    List<String> list = MiscU.toList("abc")
    map.put("list", list);
    System.out.println("map = " + map); // map = {list=[abc]}
    list.clear();
    // 注意此处map中存的还是list引用值
    System.out.println("map = " + map); // map = {list=[]}
}
```
- split

```java
"1,2,,".split(","); // ["1", "2"]
",1,2".split(","); // ["", "1", "2"]
"1,2,,".split(",", -1); // ["1", "2", "", ""]
```
- final

```java
// final Integer i = 1;
// i = 2; // 语法错误

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

## AWT

- [swing皮肤](https://blog.csdn.net/starcrm/article/details/52576379)
    - https://github.com/JackJiang2011/beautyeye
    - http://www.jtattoo.net/index.html




---

参考文章

[^1]: https://segmentfault.com/a/1190000004292140
[^2]: https://juejin.im/post/6844903910348603405
[^3]: https://www.sohu.com/a/283165575_120047208
