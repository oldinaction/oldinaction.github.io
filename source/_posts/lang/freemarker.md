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

## 解析模板字符串

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

## 自定义工具方法

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
