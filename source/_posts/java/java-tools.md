---
layout: "post"
title: "Java Tools"
date: "2020-10-9 15:18"
categories: java
tags: tools
---

## Hutool

> https://hutool.cn/docs/

### Bean/JSON操作

- Bean/Map/JSON相互转化

```java
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
// ## 做减法，如：[1, 2] - [2, 3] = [1]
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
// ## List转成数组
List<String> oldCodes = new ArrayList<>();
Object[] objArr = oldCodes.toArray;
String[] strArr = Convert.toStrArray(list.toArray); // 将list转成 String[]

// List中元素类型转换
Long id = Convert.toLong(params.get("id"));
List<Long> ids = Convert.toList(Long.class, params.get("ids")); // 痛点：controller中通过map接受参数时(@RequestBody Map<String, Object> params)，小值数据会被转成Integer，而ID一般设置成了Long
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

### Easypoi

- [Easypoi](https://gitee.com/lemur/easypoi)、[文档](http://doc.wupaas.com/docs/easypoi)
- 优点
    - 基础变量模板导出
    - excel和html互转
- 缺点
    - excel转html不灵活，无法设置转出的页面样式，如宽度
    - pdf导出文档不详
    - 测试demo运行不完整

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
    - 使用Builder构造器模式，添加`@Builder`，需要额外添加以下注解`@NoArgsConstructor`、`@AllArgsConstructor`，缺一不可。否则子类继承报错"无法将类中的构造器应用到给定类型"
    - `@Accessors(fluent = true, chain = true, prefix = "p")`
        - 此时fluent表示生产getId/setId方法均省略前缀，最终为方法名为id；chain表示setter方法返回当前对象；prefix表示生成的get/set方法会忽略前缀，即pId，会生成为getId
        - 如果作用在entity上，会导致mybatis的xml中resultMap字段无法识别
    - `@SneakyThrows` 修饰方法，捕获方法中的Throwable异常，并抛出一个RuntimeException
        - @SneakyThrows(UnsupportedEncodingException.class) 捕获方法中的UnsupportedEncodingException异常，并抛出RuntimeException

## pf4j

- [PF4J](https://github.com/pf4j/pf4j) 是一个 Java 的插件框架，为第三方提供应用扩展的渠道。PF4J 本身非常轻量级，只有 50KB 左右，目前只依赖了 slf4j。Gitblit 项目使用的就是 PF4J 进行插件管理
- 组件
    - `Plugin` 是所有插件类型的基类。为了避免冲突，每个插件都被加载到一个单独的类加载器中
    - `PluginManager` 用于插件管理的所有方面（加载、启动、停止）
    - `PluginLoader` 加载插件所需的所有信息（类）
    - 可以将任何接口或抽象类标记为扩展点（即继承`ExtensionPoint`接口），并使用`@Extension`标记扩展点的实现类
- 相关生态
    - pf4j-update（PF4J的更新机制）
    - pf4j-spring（PF4J-Spring框架集成）
    - pf4j-wicket（PF4J-Wicket集成）
    - pf4j-web（web应用程序中的PF4J）
    - springboot-plugin-framework（见下文）
- 案例

```java
// 参考：https://www.cnblogs.com/fengyun2050/p/12809204.html
// 主程序定义扩展点
public interface Greeting extends ExtensionPoint {
    String getGreeting();
}

// 插件定义实现类
@Extension
public class WelcomeGreeting implements Greeting {
    public String getGreeting() {
        return "Welcome";
    }
}
// 插件maven打包（参考下文maven配置），会在MANIFEST.MF文件生成如下(可以将插件作为jar文件分发)
// 插件id为welcome-plugin（强制属性）、版本为0.0.1（强制属性）、类为cn.aezo.test.pf4j.welcome.WelcomePlugin（可选属性）作者为Smalle的插件；以及与插件x, y, z（可选属性）的依赖关系
Plugin-Id: welcome-plugin
Plugin-Version: 0.0.1
Plugin-Class: cn.aezo.test.pf4j.welcome.WelcomePlugin
Plugin-Provider: Smalle
Plugin-Dependencies: x, y, z

// 主程序中使用插件
public static void main(String[] args) {
    // jar插件管理器
    PluginManager pluginManager = new JarPluginManager();// or "new ZipPluginManager() / new DefaultPluginManager()"

    // 加载指定路径插件
    pluginManager.loadPlugin(Paths.get("plugins-0.0.1-SNAPSHOT.jar")); // 或 pluginManager.loadPlugins(); 加载所有

    // 启动指定插件(也可以加载所有插件)
    pluginManager.startPlugin("welcome-plugin"); // 或 pluginManager.startPlugins(); 启动所有

    // 执行插件
    List<Greeting> greetings = pluginManager.getExtensions(Greeting.class);
    for (Greeting greeting : greetings) {
        System.out.println(">>> " + greeting.getGreeting()); // Welcome
    }
}
```
- 插件maven打包

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-jar-plugin</artifactId>
  <version>2.3.1</version>
  <configuration>
    <archive>
      <manifestEntries>
        <Plugin-Id>welcome-plugin</Plugin-Id>
        <Plugin-Version>0.0.1</Plugin-Version>
      </manifestEntries>
    </archive>
  </configuration>
</plugin>
```

## springboot-plugin-framework

- [springboot-plugin-framework](https://gitee.com/starblues/springboot-plugin-framework-parent)、[文档](http://www.starblues.cn/)
- 基于[pf4j](https://github.com/pf4j/pf4j)
- 插件相互调用
    - 插件1调用插件2方法，插件1的POM中无需引入插件2。主程序也无需引入插件的POM
    - 插件1调用插件2方法，插件1中需要重新定义一次插件2中需要调用的方法
- 说明
    - 新建插件时，需要继承`BasePlugin`类，并将其放在插件src根目录(否则插件中的controller等将无法扫描到)。因为会基于此类进行扫码插件其他类，并进行分组，分组相关类参考包`com.gitee.starblues.factory.process.pipe.classs.group`
    - 插件controller层路径：server.servlet.context-path + DefaultIntegrationConfiguration.pluginRestPathPrefix + (enablePluginIdRestPathPrefix=true时还需加入插件ID) + Controller#RequestMapping + Method#RequestMapping

