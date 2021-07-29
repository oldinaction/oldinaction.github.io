---
layout: "post"
title: "Java基础"
date: "2017-12-12 10:07"
categories: [java]
---

## 运算

- `<<` 左移，乘以2^x。如：3 << 4 = 3 * 2^4 = 48
- `>>` 右移，除以2^x，被除数比除数小则为0。如：32 >> 3 = 32 / 2^3 = 4; 4 >> 3 = 4 / 2^3 = 0

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
            // 有时会看到Class.this的使用，这个用法多用于在nested class(内部类)中，当inner class(内部类)必顺使用到outer class(外部类)的this instance(实例)时
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
        // test.list = [1]
        Test test = new TestChild();
        // TestChild test = new TestChild(); // 则打印 // test.list = [2]
        test.print();
        System.out.println("test.list = " + test.list);
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
    - `UTC`：协调世界时，又称世界标准时间或世界协调时间，简称`UTC(Universal Time Coordinated)`。是最主要的世界时间标准，其以原子时秒长为基础，在时刻上尽量接近于格林尼治标准时间
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
// 其中 T代表后面跟着时间，Z代表UTC时区
new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ").format(new Date())); // 2000-01-01T10:00:00+0800
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
        Statement stmt = null;
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
            // PreparedStatement preparedStatement = conn.prepareStatement(sql, {"id"}); // oracle(也适用于mysql)
            PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS); // 常用，如mysql
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

## 易错点

- Null问题

```java
Boolean a = null;
if(a) { // NullPointerException
    System.out.println("hello");
}
```
- 引用问题

```java
public static void main(String[] args) {
    Map<String, Object> map = new HashMap<>();
    List<String> list = new ArrayList<>();
    list.add("abc");
    map.put("list", list);
    System.out.println("map = " + map); // map = {list=[abc]}
    list.clear();
    // 注意此处map中存的还是list引用值
    System.out.println("map = " + map); // map = {list=[]}
}
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
