---
layout: "post"
title: "Java Tools"
date: "2020-10-9 15:18"
categories: java
tags: tools
---

## 在线工具

- https://nowjava.com/jar/ 更具jar包名称，查看jar包中文件名信息，如查看druid-1.1.17.jar

## Hutool

> https://hutool.cn/docs/

### Bean/JSON操作

- Bean/Map/JSON相互转化

```java
// 注意：Hutool在处理JSON时对Null做了处理
JSONNull jsonNull = new JSONNull(); // null会包装成JSONNull
System.out.println(jsonNull == null); // false
System.out.println(jsonNull.equals(null)); // true

// ### Bean/Map <==> JSON; 深度拷贝
String str = JSONUtil.toJsonStr(person); // Bean => JSON字符串
Person person = JSONUtil.toBean(str, Person.class); // JSON字符串 => Bean
Person newPerson = JSONUtil.toBean(JSONUtil.toJsonStr(person), Person.class); // 实现深度拷贝。使用 BeanUtil.copyProperties 为浅拷贝
Map map = JSONUtil.toBean(str, Map.class);

// ### Bean <==> Map。具体参考[类型转换](#类型转换)
BeanUtil.copyProperties(map, person); // Map => Bean(会过滤掉map中多余的参数。从而可将controller接受参数设为@RequestBody Map<String, Object> params，保存时再进行转换)
```

- 复制Bean

```java
// 忽略NULL值(即NULL值不会覆盖目标对象，但不会忽略空值)，和忽略部分属性。痛点：像 org.springframework.beans.BeanUtils.copyProperties 则无法忽略NULL值
BeanUtil.copyProperties(source, target, CopyOptions.create().ignoreNullValue().setIgnoreProperties("id", "inputer", "inputTm"));
BeanUtil.copyProperties(source, Map.class); // 会直接返回一个新Map，传入Bean的class亦可。有写场景不行，需要先new HashMap

// 仅拷贝部分属性，暂未找到相应方法，可重新定义一个仅有部分字段的Bean进行接收
```
- JSON

```java
// 根据路径获取值. 更强大的工具类：https://github.com/json-path/JsonPath 类似xpath获取json值
JSONUtil.getByPath(JSONUtil.parse(map), "users[0].classInfo.name");
```

### 集合

- 快速组装Map

```java
Dict dict = Dict.create().set("key1", 1).set("key2", 1000L); // Dict继承HashMap，其key为String类型，value为Object类型
Long v2 = dict.getLong("key2");
```
- 交/并/差等

```java
// ## 做减法，如：[1, 2] - [2, 3] = [1]。不建议使用 CollUtil.subtract(偶尔会报Null)
List<String> oldCodes = new ArrayList<>();
List<String> newCodes = new ArrayList<>(Arrays.asList(menuIds)); // 类型为 ArrayList。如果 List<String> newCodes = Arrays.asList(menuIds); // 类型为 Array$ArrayList
List<String> codes = CollUtil.subtractToList(newCodes, oldCodes); // 返回新对象。此时两个对象类型必须一致，如其中一个为Array$ArrayList，则会报错

// 去重、去空字符串(此时传入集合元素必须是字符串，如果去NULL则元素可为任意对象)
List<String> list = CollUtil.distinct(CollUtil.removeBlank(Convert.toList(String.class, this.row))); // 对Excel中读取的数据进行处理
```

- 分组
    - **暂未找到基于字段值分组成数组的方法，可参考MiscU.groupByMapKey和MiscU.groupByBeanKey**

```java
// 基于id字段进行分组成Map。但是被分组的集合只能是对象集合，不能是Map集合，可使用 MiscU.fieldValueMap 代替
Map<Long, Person> feeRuleMap = CollUtil.fieldValueMap(personList, "id");
```

### 类型转化

```java
// ==> List转成数组
List<String> oldCodes = new ArrayList<>();
Object[] objArr = oldCodes.toArray;
String[] strArr = Convert.toStrArray(list.toArray); // 将list转成 String[]

// ==> List中元素类型转换
Long id = Convert.toLong(params.get("id"));
List<Long> ids = Convert.toList(Long.class, params.get("ids")); // 痛点：controller中通过map接受参数时(@RequestBody Map<String, Object> params)，小值数据会被转成Integer，而ID一般设置成了Long

// ==> 转Int
Integer.valueOf("2.0"); // NumberFormatException
NumberUtil.parseInt("2.0"); // 会自动去掉小数点及之后字符
```

### 验证

- 断言

```java
// 不满足会抛出 IllegalArgumentException 异常
Assert.notNull(a); // 是否不为NULL
Assert.notEmpty(a); // 是否非空
Assert.notBlank(a); // 是否非空白符
Assert.assertEquals("value", val);
// 不满足会抛出IllegalStateException异常
Assert.state
```
- 字段验证器

```java
// 判断验证
boolean flag = Validator.isEmpty(str); // **不好用，只能验证null和空字符串，不能验证集合为空**
boolean flag = Validator.isNotEmpty(str);
boolean flag = Validator.isEmail("demo@example.com");
// 异常验证，失败会抛出 ValidateException 异常
Validator.validateChinese("我是一段zhongwen", "内容中包含非中文");
```

### 字符串

```java
// （成对）剥掉前后字符
StrUtil.strip("'abc'", "'"); // abc
StrUtil.strip("[abc]", "[", "]"); // abc
System.out.println(StrUtil.strip(StrUtil.strip("'1''2\"3'", "\""), "'")); // '1''2"3' => (去掉前后的 ") '1''2"3'  => (去掉前后的 ') 1''2"3

// 连接字符串
StrUtil.join(":", 1, "2", null, "4", 5.00); // 1:2:null:4:5.0
```

### 构建树结构

```java
List<SysRouter> sysRouters = queryAll();

TreeNodeConfig treeNodeConfig = new TreeNodeConfig();
// 自定义参数，也可全部使用默认
treeNodeConfig.setIdKey("id");
treeNodeConfig.setChildrenKey("children");
treeNodeConfig.setWeightKey("orderNum"); // 设置排序字段
treeNodeConfig.setDeep(10); // 配置树深度

//转换器
List<Tree<String>> treeList = TreeUtil.build(sysRouters, "0", treeNodeConfig, (treeNode, tree) -> {
    tree.setId(treeNode.getId().toString());
    tree.setParentId(treeNode.getParentId().toString());
    tree.setWeight(treeNode.getOrderNum());
    tree.setName(treeNode.getName());

    // 扩展属性
    tree.putExtra("path", treeNode.getPath());
    tree.putExtra("hasClassify", treeNode.getHasClassify());
});
```

### 数字操作

```java
// NumberUtil会将double转为BigDecimal后计算，解决float和double类型无法进行精确计算的问题；BigDecimal并不能解决小数点问题
/* 痛点：
new BigDecimal(0.1).add(new BigDecimal(1)); // 1.1000000000000000055511151231257827021181583404541015625
new BigDecimal("0.1").add(new BigDecimal("1")); // 1.1
*/
NumberUtil.add(0.1, 1); // 1.1
NumberUtil.div(10, 1, 2); // 7
NumberUtil.mul(0.55, 1.27); // 0.6985 返回类型为double
NumberUtil.round(NumberUtil.mul(0.55, 1.27), 2); // 0.70 返回类型为BigDecimal，默认为四舍五入
NumberUtil.div(12, 2, 3); // 6.0
```

### 日期操作

```java
DateUtil.isIn(thisDate, DateUtil.offsetDay(new Date(), -10), new Date()); // 判断 thisDate 是否为最近10天的时间
```

### 加解密

```java
// ################# AES 对称加密
AES aes = new AES(Mode.CBC, Padding.PKCS5Padding, "ShengQiTech@AEZO".getBytes(), "ShengQiTech@AEZO".getBytes());
String username = aes.decryptStr(HexUtil.decodeHex("ec251f39e74c3fa672edd6208c74efa7".toCharArray())); // admin
// 这种默认的解密方式会报错 v5.5.1
SymmetricCrypto sc = SecureUtil
    .aes(sqAuthConfig.getTransEncKey().getBytes())
    .setIv(sqAuthConfig.getTransEncKey().getBytes())
    .decryptStr(HexUtil.decodeHex("ec251f39e74c3fa672edd6208c74efa7".toCharArray()));
```

### FileUtil文件操作

```java
// 获取类同级目录下文件
File file = new ClassPathResource("templates").getFile(); // 在当前类所在目录获取文件，cn/aezo/test/templates，如果运行在idea中则可以放在resource目录即可
// 获取classpath下文件
// File file = ResourceUtils.getFile("classpath:templates"); // org.springframework.util. 如果是maven多模块，可能获取失败
File file = new File(FileU.class.getClassLoader().getResource("templates")); // 也可传入 cn/test 等路径

ResourceUtil.getResource("templates"); // 返回 URL

// 如果路径不存在则创建路径
if (!FileUtil.exist(path)) {
    FileUtil.mkdir(path);
}
```

### Excel操作

```java
// 读取Excel
ExcelReader reader = ExcelUtil.getReader("D:/temp/test.xls");
List<List<Object>> readAll = reader.read(); // 读取所有数据
List<Object> row = readAll.get(0); // 获取一行数据。合并单元格的会复制合并组的第一列数据
List<String> list = CollUtil.distinct(CollUtil.removeBlank(Convert.toList(String.class, this.row))); // 去重、去空字符串

// 写出Excel. 此时基于Bean/Map写出，还可以基于数组写出
ExcelWriter writer = ExcelUtil.getWriter("D:/temp/test.xls");
writer.addHeaderAlias("no", "编号"); // 设置字段顺序
writer.addHeaderAlias("name", "姓名");
writer.write(userList, true);
writer.close();
```

### FTP操作

```java
// 一次定时操作：创建新的FTP客户端 - 获取文件 - 关闭客户端
Ftp ftp = null;
try {
    ftp = new Ftp(...);

    FTPFile[] ftpFiles = ftp.lsFiles("/in");
    if(ValidU.isNotEmpty(ftpFiles)) {
        for (FTPFile ftpFile : ftpFiles) {
            if(!ftpFile.isFile()) {
                continue;
            }

            parseEdi(...);
        }
    }
} finally {
    if(ftp != null) {
        ftp.close();
    }
}

// 上传
ftp.upload("/tmp/", file);
// 移动文件
FTPClient client = ftp.getClient();
client.rename("/tmp/" + file.getName(), "/dest/" + file.getName());
```

### TemplateUtil模板引擎

- 可以操作Beetl、Enjoy、Rythm、FreeMarker、Velocity、Thymeleaf，只需引入相应的jar包
- 模板规则参考[Velocity](/_posts/java/velocity.md)、[FreeMarker](/_posts/java/freemarker.md)、[Thymeleaf](/_posts/java/thymeleaf.md)
- 使用

```java
// 此处从classpath查找模板渲染（也可通过字符串模板、本地文件等方式渲染内容）
TemplateConfig templateConfig = new TemplateConfig("/templates/email", TemplateConfig.ResourceMode.CLASSPATH);
if(customEngine != null) {
    templateConfig.setCustomEngine(customEngine); // 默认为第一个可用的引擎，即导入对应引擎包即可；此处可进行自定义引擎类，如 VelocityEngine.class
}
TemplateEngine engine = TemplateUtil.createEngine(templateConfig);
Template template = engine.getTemplate("velocity_test.vtl"); // 会在模板前面拼上 /templates/email 路径
String result = template.render(Dict.create().set("name", "Hutool"));
```

## Excel/Word/Pdf操作

### poi

- 其他基本都是基于此衍生而来
- 基本使用

```java
// 合并单元格：将第2行的第1-2列合并
sheet.addMergedRegion(new CellRangeAddress(1, 1, 0, 1));
sheet.getRow(1).getCell(0).setCellValue('合并单元格设值，只需要针对左上角的单元格设值');

// 移动行
// startRow 要移动的开始行
// endRow 要移动的结束行, 必须 >= startRow
// n 要移动的行数，n为负数代表向上移动
// copyRowHeight 是否复制行高
// resetOriginalRowHeight 是否重置行高
sheet.shiftRows(int startRow, int endRow, int n, boolean copyRowHeight, boolean resetOriginalRowHeight)
```

### Easypoi(不推荐)

- [Easypoi](https://gitee.com/lemur/easypoi)、[文档](http://doc.wupaas.com/docs/easypoi)
- 优点
    - 基础变量模板导出
    - excel和html互转。html转excel需要导入org.jsoup#jsoup包，支持将多个table生成到多个sheet中，每个table标签设置一个sheetName属性
- 缺点
    - **BUG较多**
    - pdf导出文档不详
    - 测试demo运行不完整
    - excel转html不灵活，无法设置转出的页面样式，如宽度
    - html转excel不完善，仅支持table转换，其他html标签不支持，且有些样式会丢失
- 说明
    - 常量在Excel中为`'常量值'`，由于可能存在转义，所有需要设置成`''常量值'`

## Yaml解析(基于jyaml)

- json-yaml互转工具：https://www.bejson.com/json/json2yaml
- 依赖

```xml
<dependency>
    <groupId>org.jyaml</groupId>
    <artifactId>jyaml</artifactId>
    <version>1.3</version>
</dependency>
```
- yaml

```yml
name: smale
age: 18
child:
  # 需要有空格，否则解析报错
  - name: aezo
    age: 10
```
- 代码

```java
// model
@Data
public class Person {
    private String name;
    private String age;
    private Person[] child; // 不能使用数组接受，否则解析失败
}

// 解析
File dataFile = new File(System.getProperty("user.dir") + "/src/gen/data.yaml");
Person person = (Person) Yaml.loadType(dataFile, Person.class);

// 生成Map
Map map = (Map) Yaml.load(yamlStr);
```

## Lombok

- [Lombox](https://projectlombok.org/) 简化代码工具
- 引入
    - maven项目中需要加入对应的依赖，从而打包时生成相应代码
    - idea需要安装Lombox插件，从而编译时生成相应代码，不会报错
- 使用
    - 使用Builder构造器模式
        - **添加`@Builder`，需要额外添加以下注解`@NoArgsConstructor`、`@AllArgsConstructor`，缺一不可**。否则子类继承报错"无法将类中的构造器应用到给定类型"
        - 使用`@SuperBuilder`(v1.18.4)解决子类在链式赋值时无法设置父类的字段问题 [^1]
        - `@Builder(toBuilder = true)`表示相应对象会附带`toBuilder`方法，将其转换成功Builder对象继续进行链式赋值。默认只能通过MyClass.builder()获取链式调用入口
        - **无法设置默认值，如实体类属性设置的值无效**
    - `@Accessors(fluent = true, chain = true, prefix = "p")`
        - 此时fluent表示生产getId/setId方法均省略前缀，最终为方法名为id；chain表示setter方法返回当前对象；prefix表示生成的get/set方法会忽略前缀，即pId，会生成为getId
        - 如果作用在entity上，会导致mybatis的xml中resultMap字段无法识别
    - `@SneakyThrows` 修饰方法，捕获方法中的Throwable异常，并抛出一个RuntimeException
        - @SneakyThrows(UnsupportedEncodingException.class) 捕获方法中的UnsupportedEncodingException异常，并抛出RuntimeException

## JEXL执行字符串JAVA代码

- Java Expression Language (JEXL)：是一个表达式语音解析引擎
    - 旨在促进在用Java编写的应用程序和框架中，实现动态和脚本功能
    - JEXL实现了 JSTL 中 EL 的延伸版本，不过也采用了一些 Velocity 的概念
    - 支持shell脚本或ECMAScript(js)中的大多数构造
- **更推荐使用ScriptEngineManager进行java-js的交互**，参考[javax.script](/_posts/java/java-release.md#javax.script)
- [commons-jexl官网](https://commons.apache.org/proper/commons-jexl/)
- [语法文档](https://commons.apache.org/proper/commons-jexl/reference/syntax.html)
- [案例](https://commons.apache.org/proper/commons-jexl/apidocs/org/apache/commons/jexl3/package-summary.html#usage)
- 依赖

```xml
<!-- https://mvnrepository.com/artifact/org.apache.commons/commons-jexl3 -->
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-jexl3</artifactId>
    <version>3.2.1</version>
</dependency>
```
- 简单案例

```java
//创建或者取回一个引擎。线程安全，虽然每次create的对象不一样(但是内部创建对象时会进行copy)
JexlEngine jexl = new JexlBuilder().create();

// 创建一个表达式。必须 innerFoo 和 bar 必须是可被访问到的(public)的才能得出结果，否则返回null
String jexlExp = "foo.innerFoo.bar()";
JexlExpression e = jexl.createExpression(jexlExp);

//创建上下文并添加数据
JexlContext jc = new MapContext();
jc.set("foo", new Foo());

//现在评估表达式，得到结果，结果为最后一个表达式的运算值
Object o = e.evaluate(jc);
```
- 其他案例

```java
// ==> Jexl引擎能够创建两种解析器：脚本和表达式，其中JexlExpression不能使用 if、for、while 语句块。
JexlScript jexlScript = jexlEngine.createScript("if(age>=25){good=1;}else{good=0;}"); // 正确
JexlExpression jexlExpression = jexlEngine.createExpression("if(age>=25){good=1;}else{good=0;}"); // 错误

// ==> 可以从字符串、文件或 URL 中读取脚本
// ==> 函数定义：var fun = function(x, y) { x + y } 还支持以下语法 var fun = (x, y) -> { x + y } 如果函数只有一个参数，则可以省略括号 var fun = x -> { x * x }
String exp = "var t = 2; var s = function(x, y) {x + y + t}; t = 3; s(1, 1)"; 
JexlScript script = jexl.createScript("var t = 2; var s = function(x, y) {x + y + t}; t = 3; s(1, 1)");
Object evaluate = script.execute(null); // 4

// JxltEngine 中的 Expression 类似 JSP-EL 的基本模板功能。如果多行也可使用 JxltEngine.Template
JexlEngine jexl = new JexlBuilder().create();
JxltEngine jxlt = jexl.createJxltEngine();
JxltEngine.Expression expr = jxlt.createExpression("Hello ${user}");
String hello = expr.evaluate(context).toString();

// ==> 上下文命名空间
Map<String, Object> funcNamespace = new HashMap<>();
funcNamespace.put("math", Math.class);
JexlEngine jexl = new JexlBuilder().namespaces(funcNamespace).create();
JexlExpression je = jexl.createExpression("math:max(1, 2)");
Object evaluate = je.evaluate(null); // 此处没有传入任何上下文，但是可以使用math引用
System.out.println("evaluate = " + evaluate); // evaluate = 2
```

## 字节码操作

- ASM、Javassist、Byte-buddy以及JavaAgent
- javassist
- https://blog.csdn.net/luanlouis/article/details/24589193
- https://www.cnblogs.com/rickiyang/p/11336268.html
- https://blog.csdn.net/chosen0ne/article/details/50790372

## 日志框架

- 日志框架一般分为编程API和日志打印实现。编程API为应用程序基于此API进行编程，如slf4j；打印实现为实现了上述API的模块进行日志打印到控制台或文件，如logback-classic
- slf4j、jcl、jul、log4j1、log4j2、logback大总结：https://my.oschina.net/pingpangkuangmo/blog/410224
- logging: jdk自带logging
- log4j1(log4j)
    - log4j: log4j1的全部内容(org.apache.log4j.*)
- log4j2(org.apache.logging.log4j)
    - log4j-api: log4j2定义的API
    - log4j-core: log4j2上述API的实现
    - log4j-1.2-api: log4j到log4j2的桥接包。具体说明参考log4j
- logback
    - logback-core: logback的核心包
    - logback-classic: logback实现了slf4j的API
- commons-logging 为了实现日志统一
    - commons-logging: commons-logging的原生全部内容
    - log4j-jcl: commons-logging到log4j2的桥梁
    - jcl-over-slf4j: commons-logging到slf4j的桥梁
- slf4j 为了实现日志统一
    - slf4j-api: 为日志接口，简称slf4j
    - slf4j转向某个实际的日志框架：如使用slf4j的API进行编程，底层想使用log4j1来进行实际的日志输出，可使用slf4j-log4j12进行桥接
        - logback-classic: slf4j到logback的桥梁
        - log4j-slf4j-impl: slf4j到log4j2的桥梁(此时只需要log4j-api)
        - slf4j-jdk14: slf4j到jdk-logging的桥梁
        - slf4j-jcl: slf4j到commons-logging的桥梁
        - slf4j-log4j12: slf4j到log4j1的桥梁
    - 某个实际的日志框架转向slf4j(主要用来进行实际的日志框架之间的切换, slf4j为中间API)：如使用log4j1的API进行编程，但是想最终通过logback来进行输出，所以就需要先将log4j1的日志输出转交给slf4j来输出，slf4j再交给logback来输出。将log4j1的输出转给slf4j，这就是log4j-over-slf4j做的事
        - log4j-to-slf4j: log4j2到slf4j的桥梁
        - jul-to-slf4j: jdk-logging到slf4j的桥梁
        - jcl-over-slf4j: commons-logging到slf4j的桥梁
        - log4j-over-slf4j: log4j1到slf4j的桥梁

### jdk-logging

- 原理分析参考：https://blog.csdn.net/qingkangxu/article/details/7514770
- 案例(/smjava/logging/log4j1-jdklog)

```java
/**
* 打印日志如下，且IDEA显示为红色
* 十二月 10, 2021 9:13:04 下午 cn.aezo.logging.log4j1.App main
* 信息: jdk logging info...
* 十二月 10, 2021 9:13:04 下午 cn.aezo.logging.log4j1.App main
* 警告: jdk logging warning...
* 十二月 10, 2021 9:13:04 下午 cn.aezo.logging.log4j1.App main
* 严重: jdk logging severe...
*/
// java.util.logging.Logger
private static final Logger logger = Logger.getLogger(App.class.getName());
public static void main(String[] args) {
    logger.info("jdk logging info...");
    logger.warning("jdk logging warning...");
    logger.severe("jdk logging severe...");
}
```

### log4j

- [log4j1.x](https://logging.apache.org/log4j/1.2/) 采用同步的方式打印log，当项目中打印log的地方很多的时候，频繁的加锁拆锁会导致性能的明显下降
    - 主要类
        - LogManager: 它的类加载会创建logger仓库Hierarchy，并尝试寻找类路径下的配置文件，如果有则解析
        - Hierarchy: 包含三个重要属性
            - LoggerFactory logger的创建工厂
            - Hashtable 用于存放上述工厂创建的logger
            - Logger root logger 用于承载解析文件的结果，设置级别，同时存放appender
        - PropertyConfigurator: 用于解析log4j.properties文件
        - Logger: 我们用来输出日志的对象
    - log4j.properties配置参考：https://blog.csdn.net/niuch1029291561/article/details/80938095
- [log4j2.x](https://logging.apache.org/log4j/2.x/) 则为异步打印
    - log4j2与log4j1发生了很大的变化，不兼容。log4j1仅仅作为一个实际的日志框架，slf4j、commons-logging作为门面，统一各种日志框架的混乱格局，现在log4j2也想跳出来充当门面了，也想统一大家了
    - log4j2包含
        - log4j-api: 作为日志接口层，用于统一底层日志系统
        - log4j-core: 作为上述日志接口的实现，是一个实际的日志框架
    - 主要类说明
        - LogManager: 它的类加载会去寻找LoggerContextFactory接口的底层实现，会从jar包中的配置文件中寻找
        - LoggerContextFactory: 用于创建LoggerContext，不同的日志实现系统会有不同的实现，如log4j-core中的实现为Log4jContextFactory
        - PropertyConfigurator: 用于解析log4j.properties文件
        - LoggerContext: 它包含了配置信息，并能创建log4j-api定义的Logger接口实例，并缓存这些实例
        - ConfigurationFactory: 上述LoggerContext解析配置文件，需要用到ConfigurationFactory，目前有三个- YamlConfigurationFactory、JsonConfigurationFactory、XmlConfigurationFactory，分别解析yuml json xml形式的配置文件
    - log4j2.xml配置参考：https://www.jianshu.com/p/bfc182ee33db
    - 调试log4j2，增加jvm参数`-Dlog4j2.debug=true`
- log4j1升级到log4j2
    - 删除原来log4j1依赖`log4j:log4j`
    - 增加新的log4j2依赖`org.apache.logging.log4j:log4j-api`和`org.apache.logging.log4j:log4j-core`
    - 增加`org.apache.logging.log4j:log4j-1.2-api`的桥接包，为官方推出的平稳的过度包。此时编程任然是基于log4j1进行编程
        - 桥接包的原理就是复写了log4j-1.2.17相关的类，再输出日志的时候调用的是log4j2中的方法
        - 如：log4j1中使用Logger.getLogger(Test.class)获取日志对象，log4j2的Logger没有此方法，所以升级的时候可能出现需要更改代码。如果引入此包，可以实现不更改代码升级
    - 配置文件还是必须为log4j2.xml，而不能是log4j.properties或log4j.xml
- log4j 2.x < 2.15.0-rc2 漏洞：https://help.aliyun.com/noticelist/articleid/1060971232.html
- log4j1案例(/smjava/logging/log4j1-jdklog)
    - 引入依赖`log4j:log4j:1.2.17`

```java
/**
* 无 log4j.properties 文件时打印如下：
* log4j:WARN No appenders could be found for logger (cn.aezo.logging.log4j1.Log4j1App).
* log4j:WARN Please initialize the log4j system properly.
* log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
* 
* 有 log4j.properties 文件之后打印如下：
* 2021-12-10 21:34:01 log4j debug message
* 2021-12-10 21:34:01 log4j info message
*/
// org.apache.log4j.Logger
private static final Logger logger = Logger.getLogger(Log4j1App.class);
public static void main(String[] args){
    if(logger.isTraceEnabled()){
        logger.debug("log4j trace message");
    }
    if(logger.isDebugEnabled()){
        logger.debug("log4j debug message");
    }
    if(logger.isInfoEnabled()){
        logger.debug("log4j info message");
    }
}

// log4j.properties(也支持log4j.xml)。配置参考：https://blog.csdn.net/niuch1029291561/article/details/80938095
log4j.rootLogger = debug, console
log4j.appender.console = org.apache.log4j.ConsoleAppender
log4j.appender.console.layout = org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern = %-d{yyyy-MM-dd HH:mm:ss} %m%n
```

- log4j2案例(/smjava/logging/log4j2)
    - 引入依赖`org.apache.logging.log4j:log4j-api:2.15.0`和`org.apache.logging.log4j:log4j-core:2.15.0`

```java
/**
* 无 log4j2.xml 文件时无任何信息打印
* 有 log4j2.xml 文件之后打印如下：
* 21:52:05.789 [main] DEBUG cn.aezo.logging.log4j2.Log4j2App - log4j debug message
* 21:52:05.794 [main] DEBUG cn.aezo.logging.log4j2.Log4j2App - log4j info message
*/
// org.apache.logging.log4j.Logger org.apache.logging.log4j.LogManager
// 和log4j1是不同的，此时Logger是log4j-api中定义的接口，而log4j1中的Logger则是类
private static final Logger logger = LogManager.getLogger(Log4j2App.class);
public static void main(String[] args){
    if(logger.isTraceEnabled()){
        logger.debug("log4j trace message");
    }
    if(logger.isDebugEnabled()){
        logger.debug("log4j debug message");
    }
    if(logger.isInfoEnabled()){
        logger.debug("log4j info message");
    }
}
```

### slf4j

- [slf4j](http://www.slf4j.org/)是门面模式的典型应用(门面模式：外部与一个子系统的通信必须通过一个统一的外观对象进行，使得子系统更易于使用)
- slf4j(slf4j-api)、commons-logging均为日志接口，不提供日志的具体实现
- slf4j-simple、logback都是slf4j的具体实现；log4j并不直接实现slf4j，但是有专门的一层桥接slf4j-log4j12来实现slf4j
- 案例
    - 引入`org.slf4j:slf4j-api:1.7.25`
    - 使用

    ```java
    // 通过门面方法获取具体得实现，核心逻辑也是从此处开始的(从classpath下去找org/slf4j/impl/StaticLoggerBinder.class)
    Logger logger = LoggerFactory.getLogger(Object.class);
    ```
- 如果不引入日志实现则会提示

```bash
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
```
- 如果引入多个日志实现则会提示

```bash
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/Users/smalle/.m2/repository/ch/qos/logback/logback-classic/1.2.3/logback-classic-1.2.3.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/Users/smalle/.m2/repository/org/apache/logging/log4j/log4j-slf4j-impl/2.10.0/log4j-slf4j-impl-2.10.0.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [ch.qos.logback.classic.util.ContextSelectorStaticBinder]
```

### commons-logging

- [commons-logging](https://commons.apache.org/proper/commons-logging/): Jakarta Commons-logging（JCL）是apache最早提供的日志的门面接口。提供简单的日志实现以及日志解耦功能
- JCL能够选择使用Log4j（或其他如slf4j等）还是JDK Logging，但是他不依赖Log4j，JDK Logging的API。如果项目的classpath中包含了log4j的类库，就会使用log4j，否则就使用JDK Logging
- 配置文件`commons-logging.properties`，包`org.apache.commons.logging.*`
- 最后更新为2014年的v1.2
- 使用如

```xml
<dependency>
	<groupId>commons-logging</groupId>
	<artifactId>commons-logging</artifactId>
	<version>1.2</version>
</dependency>
<dependency>
	<groupId>log4j</groupId>
	<artifactId>log4j</artifactId>
	<version>1.2.17</version>
</dependency>
```

### spring-log

- spring-core
    - **`org.springframework:spring-jcl`**
        - `org.apache.logging.log4j:log4j-api[optional]`
        - `org.slf4j:slf4j-api[optional]`
- spring-boot-starter-logging(可看出springboot使用slf4j+logback进行日志输出)
    - `ch.qos.logback:logback-classic`
    - `org.apache.logging.log4j:log4j-to-slf4j` log4j2到slf4j的桥梁
        - log4j-api
        - slf4j-api
    - `org.slf4j:jul-to-slf4j` jdk-logging到slf4j的桥梁
- spring-jcl
    - 包`org.apache.commons.logging.*`，和commons-logging包一样，是因为spring直接将commons-logging拷贝过来进行维护
- 入口

```java
// 实际调用 LogAdapter.createLog
private static final Log logger = LogFactory.getLog(App.class);

final class LogAdapter {
    // 默认使用java.util.logging日志框架
    private static LogApi logApi = LogApi.JUL;

    // 根据classpath下拥有的类名来判断具体使用的日志框架
	static {
		ClassLoader cl = LogAdapter.class.getClassLoader();
		try {
			// Try Log4j 2.x API
			Class.forName("org.apache.logging.log4j.spi.ExtendedLogger", false, cl);
			logApi = LogApi.LOG4J;
		}
		catch (ClassNotFoundException ex1) {
			try {
				// Try SLF4J 1.7 SPI
				Class.forName("org.slf4j.spi.LocationAwareLogger", false, cl);
				logApi = LogApi.SLF4J_LAL;
			}
			catch (ClassNotFoundException ex2) {
				try {
					// Try SLF4J 1.7 API
					Class.forName("org.slf4j.Logger", false, cl);
					logApi = LogApi.SLF4J;
				}
				catch (ClassNotFoundException ex3) {
					// Keep java.util.logging as default
				}
			}
		}
	}
    
    public static Log createLog(String name) {
        switch (logApi) {
            case LOG4J:
                return Log4jAdapter.createLog(name);
            case SLF4J_LAL:
                return Slf4jAdapter.createLocationAwareLog(name);
            case SLF4J:
                return Slf4jAdapter.createLog(name);
            default:
                // Defensively use lazy-initializing adapter class here as well since the
                // java.logging module is not present by default on JDK 9. We are requiring
                // its presence if neither Log4j nor SLF4J is available; however, in the
                // case of Log4j or SLF4J, we are trying to prevent early initialization
                // of the JavaUtilLog adapter - e.g. by a JVM in debug mode - when eagerly
                // trying to parse the bytecode for all the cases of this switch clause.
                return JavaUtilAdapter.createLog(name);
        }
    }

    private enum LogApi {LOG4J, SLF4J_LAL, SLF4J, JUL}
}
```
- springboot

```java
import org.apache.commons.logging.LogFactory;

public class SpringApplication {
    // 实例化SpringApplication时，便会实例化Log
    private static final Log logger = LogFactory.getLog(SpringApplication.class);
}
```


---

参考文章

[^1]: https://blog.csdn.net/qq_20021569/article/details/102471373
