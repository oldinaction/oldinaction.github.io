---
layout: "post"
title: "freemarker"
date: "2017-04-28 11:39"
categories: [lang]
tags: [freemarker, java, template]
---

## 简介

- 官网：[http://freemarker.org/](http://freemarker.org/)、文档：[http://freemarker.org/docs/index.html](http://freemarker.org/docs/index.html)


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

        rendToStream("Hello ${name}", MiscU.Instance.toMap("name", "smalle2"), new FileOutputStream(new File("D://temp/target0.ftl")));

        rendToConsole("test.ftl", "/mytpl", MiscU.Instance.toMap("name", "smalle3")); // mytpl为classpath根目录下文件夹

        rendToStream("test.ftl", "/mytpl", MiscU.Instance.toMap("name", "smalle4"), new FileOutputStream(new File("D://temp/target.ftl")));
    }
}
```

## 知识点

- 转义字符`${r"..."}`: 如：`${r"${foo}"}`、`${r"C:\foo\bar"}`
- `js_string` 用于JavaScript转义，转换`'`、`"`、换行等特殊字符。如：`alert("${errorMessage?js_string}");`

