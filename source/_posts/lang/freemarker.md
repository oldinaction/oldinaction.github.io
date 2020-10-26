---
layout: "post"
title: "Freemarker"
date: "2017-04-28 11:39"
categories: [lang]
tags: [freemarker, java, template]
---

## 简介

- 官网：[http://freemarker.org/](http://freemarker.org/)、文档：[http://freemarker.org/docs/index.html](http://freemarker.org/docs/index.html)

## 知识点

- 转义字符`${r"..."}`: 如：`${r"${foo}"}`、`${r"C:\foo\bar"}`
- `js_string` 用于JavaScript转义，转换`'`、`"`、换行等特殊字符。如：`alert("${errorMessage?js_string}");`

### 变量

- 参考：https://blog.csdn.net/J080624/article/details/78648786

```html
<!-- 定义变量、ftl提供调用类的静态方法。加?if_exists防止null时报错 -->
<!--
    Static为ofbiz内置ftl获取静态类的，也可类似在controller层添加以下代码达到使用Static获取静态类
    root.put("Static", BeansWrapper.getDefaultInstance().getStaticModels());
-->
<#assign appVersion = Static["java.lang.System"].getProperty("app.version")?if_exists />
<!-- 获取变量 -->
${(appVersion)!}
```

### 运算符

> https://freemarker.apache.org/docs/dgui_template_exp.html#dgui_template_exp_missing_default

- `??` 等同于 `exists`
- `!` 等同于 `?if_exists`。也可接默认值，如：`${(name)!'smalle'}`
- 示例

```html
<!-- ??可用于判断数组是否存在，如果是数组使用!(?if_exists)则报错 -->
<#if searchFields??>#if不能使用?if_exists进行判断，需使用??</#if>
<#list searchFields?if_exists as item>#list可以使用?if_exists进行判断<#list>
```

### 控制语句

```html
<!-- if -->
<#if condition>
    ...
<#elseif condition2>
    ...
<#else>
    ...
</#if>

<!-- list -->
<#list myList?if_exists as item>
    <option value="${item.id}"<#if "${item.code}" == "True">selected="selected"</#if>>${(item.name)!}</option>
</#list>
<#list 0..2 as index>
    <#if "${(snapListReverse[index]['total'])!}" != "">
    <tr>
        <td>${(snapListReverse[index]['time'])!}</td>
        <#-- ftl注释：取默认值 -->
        <td>${(snapListReverse[index]['total'])!'0'}</td>
    </tr>
    </#if>
</#list>
<!-- **变量名加 _index、_has_next**、break -->
<#list searchFields?if_exists as field>
    <!-- 判断第一个 -->
    <#if field_index == 0>[</#if>
    <#if "${(field.fieldNameEn)!}" == ""><#break><#else>${(field.fieldNameEn)!}</#if>
    <!-- 判断是否为最后一个 -->
    <#if field_has_next>,</#if>
    ]
</#list>
```

### 其他指令

```html
<#include "include/foo.ftl"><!-- 导入其他ftl文件（相对路径） -->

<#t> <!-- 去掉左右空白和回车换行 -->
<#lt> <!-- 去掉左边空白和回车换行 --> 
<#rt> <!-- 去掉右边空白和回车换行 -->
<#nt> <!-- 取消上面的效果 -->
```

### 数据类型

- 在模板处理时，会将Java类型包装为对应的TemplateModel实现。比如将一个String包装为`SimpleScalar`(对应接口`TemplateScalarModel`)来存储同样的值。对于每个Java类型，具体选择什么TemplateModel实现去包装，取决于对象包装器（ObjectWrapper）的实现策略

#### 数组

- `?split(",")` 分割字符串获取数组
- `_index` 获取当前循环下标
- `_has_next` 判断当前循环元素后面是否还有元素
- `${list[0].name}` 通过下标取值
- 案例

```html
<!-- 分割字符串获得数组 -->
<#list "张三,李四,王五"?split(",") as name>
    ${name}<#if name_has_next>,</#if>
</#list>
```

#### Map

```html
<!--创建一个map，注意在freemarker中，map的key只能是字符串来作为key-->
<#assign userMap={"1": "刘德华", "2": "张学友"}/>

<!-- 获取map中的值、keys、values -->
${userMap["1"]}
<#assign keys=userMap?keys/>
<#assign values=userMap?values/>

<!-- 遍历map -->
<#list userMap?keys as key>
    key: ${key}, value: ${userMap["${key}"]}
</#list>
<!-- 直接遍历map的values -->
<#list userMap?values as value>
    ${value}
</#list>
```

### 内置函数

> https://freemarker.apache.org/docs/ref_builtins.html

```html
<!-- 判断变量类型（is_...函数）：https://freemarker.apache.org/docs/ref_builtins_expert.html -->
<#if arr?is_enumerable>arr为集合或序列，可被#list变量</#if><!-- 判断是否为集合或序列 -->

<!-- 格式化日期字符串 -->
${(item.inputTm?string("yyyy-MM-dd HH:mm"))!}

<!-- 首字母小写 -->
${'AdminUser'?uncap_first}
<!-- 首字母大写 -->
${'AdminUser'?cap_first}

<!-- 驼峰转下划线，都得到 camel_to_under_score_test -->
${"CamelToUnderScoreTest"?replace("([a-z])([A-Z]+)","$1_$2","r")?lower_case}
${"camelToUnderScoreTest"?replace("([a-z])([A-Z]+)","$1_$2","r")?lower_case}

<!-- 下划线转驼峰 -->
<#function dashedToCamel(s)>
  <#return s
  ?replace('(^_+)|(_+$)', '', 'r')
  ?replace('\\_+(\\w)?', ' $1', 'r')
  ?replace('([A-Z])', ' $1', 'r')
  ?capitalize
  ?replace(' ' , '')
  ?uncap_first
  >
</#function>
${dashedToCamel("camel_to_under_score_test")} <!-- 结果为：camelToUnderScoreTest -->
${dashedToCamel("___caMel___to_under_scOre_teSt____")} <!-- 结果为：caMelToUnderScOreTeSt -->

<!-- 判断包含 -->
<#if "a,b,c,"?contains("a")>包含字符串a</#if>


```

## 配置

- 基本使用

```java
// 1.基本配置
Configuration cfg = new Configuration(Configuration.VERSION_2_3_23); //通过FreeMarker的Configuration对象可以读取ftl文件
cfg.setDefaultEncoding("UTF-8");

// 2.基于Classpath设置模板加载器
cfg.setClassForTemplateLoading(Main.class, "/abc"); // 设置模板文件的目录，classpath:/abc
Template template = cfg.getTemplate("test.ftl"); // classpath:/abc/test.ftl => ${name} => smalle
template.process(MapUtil.builder(new HashMap<String, Object>()).put("name", "smalle").build(),
                new PrintWriter(System.out));

// 3.基于字符串设置模板加载器
StringTemplateLoader stringLoader = new StringTemplateLoader();
stringLoader.putTemplate("template", "${name}");
cfg.setTemplateLoader(stringLoader);
Template template = cfg.getTemplate("template", "utf-8");

// 4.共享变量
    // 共享变量是为所有模板定义的变量(通过配置对象渲染时的所有模板。如a引入了b，此时a和b中均可使用此共享变量)
    // 如果配置对象在多线程环境中使用，不要使用 `TemplateModel` 实现类来作为共享变量，因为它是不是线程安全的
    // 用户自定义指令使用时需要用 @ 来代替 #
cfg.setSharedVariable("company", "Foo Inc.");
cfg.setSharedVariable("sq_repeat", new SqRepeatDirective()); // 自定义指令，参考下文
```

## 自定义指令和自定义函数

- 使用(定义如下文) [^1]

```html
<!-- classpath:/test.ftl模板文件 -->
${name}

<#assign ctx = {"k1": "v1"}>
<@sq_repeat count=5 hr=false ctx=ctx; step>
    ${step}. ${name}
</@>

${sqSum(1, 2, 3, 4)}

<!-- 结果打印 -->
ctx = {"k1": "v1"}
smalle

    1. smalle
    2. smalle
    3. smalle
    4. smalle
    5. smalle

10
```
- 定义如下

```java
public class Main {
    public static void main(String[] args) throws IOException, TemplateException {
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_23);
        cfg.setClassForTemplateLoading(Main.class, "/");
        cfg.setSharedVariable("sq_repeat", new SqRepeatDirective());

        Template template = cfg.getTemplate("test.ftl");
        Map<String, Object> root = MapUtil.builder(new HashMap<String, Object>()).put("name", "smalle").build();
        root.put("sqSum", new SqSumMethod());

        template.process(root, new PrintWriter(System.out));
    }
}

/**
 * 自定义函数
 */
class SqRepeatDirective implements TemplateDirectiveModel {
    protected static BeansWrapper build = new BeansWrapperBuilder(Configuration.DEFAULT_INCOMPATIBLE_IMPROVEMENTS).build();

    // 循环次数
    private static final String COUNT = "count";
    // 是否需要用hr标签间隔
    private static final String HR = "hr";
    // 内置变量名
    private static final String VARIABLE_NAME = "item";

    @SuppressWarnings("rawtypes")
    @Override
    public void execute(Environment env, Map params, TemplateModel[] loopVars,
                        TemplateDirectiveBody body) throws TemplateException, IOException {
        // 扩展说明1：params中可以拿到ftl中定义的参数，如此处的ctx(map)
        System.out.println("ctx = " + params.get("ctx")); // ctx = {"k1": "v1"}
        // 扩展说明2：本类可接受SqlSession等访问数据库对象，然后数据库中保存好sql语句模板(基于ftl写的sql语句拼接)，此时根据接受的参数(如对应sql的查询条件)，从而执行sql获取数据。然后将数据在body中渲染

        // 获取count参数，并校验是否合法
        TemplateModel countModel = (TemplateModel) params.get(COUNT); // 获取标签参数值的包装
        if (countModel == null) {
            throw new TemplateModelException("缺少必须参数count！");
        }
        if (!(countModel instanceof TemplateNumberModel)) {
            throw new TemplateModelException("count参数必须为数值型！");
        }
        int count = ((TemplateNumberModel) countModel).getAsNumber().intValue();
        if (count < 0) {
            throw new TemplateModelException("count参数值必须为正整数！");
        }

        // 获取hr参数，并校验是否合法
        boolean hr = false;
        TemplateModel hrModel = (TemplateModel) params.get(HR);
        if (hrModel != null) {
            if (!(hrModel instanceof TemplateBooleanModel)) {
                throw new TemplateModelException("hr参数值必须为布尔型！");
            }
            hr = ((TemplateBooleanModel) hrModel).getAsBoolean();
        }

        // 检验内嵌内容是否为空
        if (body == null) {
            throw new RuntimeException("内嵌内容不能为空！");
        }

        // 最多只允许一个循环变量
        if (loopVars.length > 1) {
            throw new TemplateModelException("最多只允许一个循环变量！");
        }

        // 循环渲染内嵌内容
        TemplateModel oldVar = env.getVariable(VARIABLE_NAME);
        for (int i = 0; i < count; i++) {
            // 用第一个循环变量记录循环次数
            if (loopVars.length == 1) {
                loopVars[0] = new SimpleNumber(i + 1);
            }

            // 将i进行封装，并设置成此标签内置变量
            TemplateModel itemModel = build.wrap(i);
            env.setVariable(VARIABLE_NAME, itemModel);

            // 上面设置循环变量的操作必须在该render前面，因为内嵌内容中使用到了该循环变量
            body.render(env.getOut());
            if (hr) {
                env.getOut().write("<hr>");
            }

            // 还原此名称的变量
            env.setVariable(VARIABLE_NAME, oldVar);
        }
    }
}

/**
 * 自定义函数
 */
class SqSumMethod implements TemplateMethodModelEx {

    @SuppressWarnings("rawtypes")
    @Override
    public Object exec(List arg0) throws TemplateModelException {
        if (arg0 == null || arg0.size() == 0) {
            return new SimpleNumber(0);
        }

        double sum = 0d;
        double tmp;
        for (int i = 0; i < arg0.size(); i++) {
            tmp = Double.valueOf(arg0.get(i).toString());
            sum += tmp;
        }
        return new SimpleNumber(sum);
    }
}
```

## 工具类

```java
public class FtlU {
    /**
     * 根据模板文件输出内容到指定的输出流中(文件中)
     * @param name 模板文件的名称
     * @param path 模板文件的目录: 如ftl与此java文件同目录, 则此处为 ""
     * @param rootMap 模板的数据模型
     * @param outputStream 输出流
     */
    public static void rendToStream(String name, String path, Map<String, Object> rootMap, OutputStream outputStream) throws TemplateException, IOException {
        Writer out = new BufferedWriter(new OutputStreamWriter(outputStream, "UTF-8"));
        getTemplate(name, path).process(rootMap, out); // 将模板文件内容以UTF-8编码输出到相应的流中
        if (null != out) {
            out.close();
        }
    }

    public static void rendToStream(String sourceCode, Map<String, Object> rootMap, OutputStream outputStream) throws
            TemplateException, IOException {
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_23);
        cfg.setDefaultEncoding("UTF-8");

        Template template = new Template("", sourceCode, cfg);

        Writer out = new BufferedWriter(new OutputStreamWriter(outputStream, "UTF-8"));
        template.process(rootMap, out);
        if (null != out) {
            out.close();
        }
    }

    /**
     * 根据模板文件输出内容到控制台
     * @param name       模板文件的名称
     * @param pathPrefix 模板文件的目录
     * @param rootMap    模板的数据模型
     */
    public static void rendToConsole(String name, String pathPrefix, Map<String, Object> rootMap) throws
            TemplateException, IOException {
        getTemplate(name, pathPrefix).process(rootMap, new PrintWriter(System.out));
    }

    public static void rendToConsole(String sourceCode, Map<String, Object> rootMap) throws
            TemplateException, IOException {
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_23);
        cfg.setDefaultEncoding("UTF-8");
        Template template = new Template("", sourceCode, cfg);
        template.process(rootMap, new PrintWriter(System.out));
    }

    public static String rendToString(String sourceCode, Map<String, Object> rootMap) throws
            TemplateException, IOException {
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_23);
        cfg.setDefaultEncoding("UTF-8");

        Template template = new Template("", sourceCode, cfg);
        StringWriter sw = new StringWriter();
        template.process(rootMap, sw);
        return sw.getBuffer().toString();
    }

    /**
     * 获取指定目录下的Ftl模板文件
     * @param name 模板文件的名称
     * @param path 模板文件的目录
     */
    public static Template getTemplate(String name, String path) throws IOException {
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_23); //通过FreeMarker的Configuration对象可以读取ftl文件
        cfg.setClassForTemplateLoading(FtlU.class, path); // 设置模板文件的目录
        cfg.setDefaultEncoding("UTF-8");       //Set the default charset of the template files
        Template temp = cfg.getTemplate(name); //在模板文件目录中寻找名为"name"的模板文件
        return temp; //此时FreeMarker就会到类路径下的"path"文件夹中寻找名为"name"的模板文件
    }

    /**
     * 测试程序
     * @param args
     */
    public static void main(String[] args) throws IOException, TemplateException {
        rendToConsole("Hello ${name}", MiscU.Instance.toMap("name", "smalle1"));

        // rendToStream("Hello ${name}", MiscU.Instance.toMap("name", "smalle2"), new FileOutputStream(new File("D://temp/target0.ftl")));
        // rendToConsole("test.ftl", "/mytpl", MiscU.Instance.toMap("name", "smalle3")); // mytpl为classpath根目录下文件夹
        // rendToStream("test.ftl", "/mytpl", MiscU.Instance.toMap("name", "smalle4"), new FileOutputStream(new File("D://temp/target.ftl")));
    }
}
```

## 工具方法

```html
<#-- freemarker 的一些工具方法 -->

<#-- 驼峰转其他字符 -->
<#-- @param str       待转换的文本 -->
<#-- @param character 要转换成的字符 -->
<#-- @param case      转换大小写（normal 不转换，lower 小写，upper 大写） -->
<#function camelToChar(str, character, case='normal')>
  <#assign text=str?replace("([a-z])([A-Z]+)","$1${character}$2","r")/>
  <#if case=="upper">
    <#return text?upper_case>
  <#elseif case=="lower">
    <#return text?lower_case>
  <#else>
    <#return text>
  </#if>
</#function>

<#-- 驼峰转下划线 -->
<#function camelToDashed(str, case='normal')>
  <#return camelToChar(str, "_", case)>
</#function>

<#-- 驼峰转横线 -->
<#function camelToHorizontal(str, case='normal')>
  <#return camelToChar(str, "-", case)>
</#function>
```



---

参考文章

[^1]: https://www.cnblogs.com/genein/p/5271113.html


