---
layout: "post"
title: "javacodestyle - Java开发规范"
date: "2016-07-06 08:39"
categories: java
tags: [rule]
---

## 源文件基础
1. 文件名：源文件以其最顶层的类名来命名，大小写敏感，文件扩展名为 .java
2. 文件编码：UTF-8
3. 特殊字符：注释明确

## 源文件结构
1. 一个源文件包含(按顺序地，以下每个部分之间用一个空行隔开)：
  - 许可证或版权信息(如有需要)
  - package语句：package语句不换行
  - import语句
  - 一个顶级类(只有一个)

2. import语句
  - import不要使用通配符，即，不要出现类似这样的import语句：`import java.util.*;`
  - 每个import语句独立成行
  - 文件中不能含有无用的import语句

3. 类声明
  - 只有一个顶级类声明：每个顶级类都在一个与它同名的源文件中
  - 类成员顺序
    - 成员属性
    - 构造方法
    - 普通方法（按照某中逻辑顺序而非时间顺序）
  - 重载永不分离：当一个类有多个构造函数，或是多个同名方法，这些函数/方法应该按顺序出现在一起，中间不要放进其它函数/方法。

## 格式
1. 大括号
  - 使用大括号(即使是可选的)：大括号与if, else, for, do, while语句一起使用，即使只有一条语句(或是空)，也应该把大括号写上。
  - 非空块：遵循Kernighan和Ritchie风格
    - 左大括号前不换行
    - 左大括号后换行
    - 右大括号前换行
    - 如果右大括号是一个语句、函数体或类的终止，则右大括号后换行; 否则不换行。例如，如果右大括号后面是else或逗号，则不换行。
  - 空块：一个空的块状结构里什么也不包含，大括号可以简洁地写成{}，不需要换行。例外：如果它是一个多块语句的一部分(if/else 或 try/catch/finally) ，即使大括号内没内容，右大括号也要换行。Eg: void doNothing() {}
2. 缩进：一个Tab为一次缩进
3. 一行一个语句
4. 具体结构
  - 枚举类：枚举常量间用逗号隔开，换行可选。
  - 变量声明：
    - 每次只声明一个变量，不要使用组合声明，比如int a, b;。
    - 需要时才声明，并尽快进行初始化：不要在一个代码块的开头把局部变量一次性都声明了(这是c语言的做法)，而是在第一次需要使用它时才声明。
  - 注解(Annotations)：注解紧跟在文档块后面，应用于类、方法和构造函数，一个注解独占一行。单个的注解可以和签名的第一行出现在同一行。应用于字段的多个注解允许与字段出现在同一行。Eg：@Partial @Mock DataLoader loader;
  - modifiers：类和成员的modifiers如果存在，则按Java语言规范中推荐的顺序出现：
    - public protected private abstract static final transient volatile synchronized native strictfp

## 注释
1. 注释尽可能详细
2. 成员变量和成员方法要有javadoc注释
3. 前台获取的变量最好写上注释
4. 方法中逻辑比较复杂的，应该写相应的业务注释
5. javadoc注释：统一格式（方法说明、参数、返回值、作者、时间）

## 命名约定
1. 标识符只能使用ASCII字母和数字，并以字母开头。
2. 包名：包名全部小写，连续的单词只是简单地连接起来，不使用下划线。
3. 类名：首字母大写，使用驼峰命名
4. 方法名：首字母小写，使用驼峰命名
5. 常量名：全部字母大写，用下划线分隔单词

## 编程实践
1. 只要是合法的，就把@Override注解给用上。
2. 捕获的异常：不能忽视
3. 静态成员：使用类进行调用

## 代码注释模版
新增一个xml文件，将以下代码复制进去。Eclipse -> Window -> Preference -> Java -> Code Style -> Code Template –> Import 导入模版文件并保存。

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?><templates><template autoinsert="false" context="typecomment_context" deleted="false" description="创建的类型的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.typecomment" name="typecomment">/**
 * @ClassName: ${type_name}
 * @Description: ${todo}
 * @author ${user}
 * @date ${date} ${time}
 * ${tags}
 */</template><template autoinsert="false" context="filecomment_context" deleted="false" description="已创建的 Java 文件的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.filecomment" name="filecomment">/**  
 * @Title ${file_name}
 * @Package ${package_name}
 * @Description ${todo}
 * @author ${user}
 * @date ${date} ${time}
 * @version v1.0
 */</template><template autoinsert="false" context="fieldcomment_context" deleted="false" description="字段的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.fieldcomment" name="fieldcomment">/**
 * @Description ${todo}
 * ${field}
 */  
</template><template autoinsert="false" context="settercomment_context" deleted="false" description="setter 方法的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.settercomment" name="settercomment">/**    
 * 设置 ${bare_field_name} 的值    
 * @param ${param}  
 */</template><template autoinsert="false" context="delegatecomment_context" deleted="false" description="代表方法的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.delegatecomment" name="delegatecomment">/**
 * ${tags}
 * ${see_to_target}
 */
</template><template autoinsert="false" context="constructorcomment_context" deleted="false" description="创建的构造函数的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.constructorcomment" name="constructorcomment">/**
 * &lt;p&gt;Title: &lt;/p&gt;
 * &lt;p&gt;Description: &lt;/p&gt;
 * ${tags}
 */</template><template autoinsert="false" context="methodcomment_context" deleted="false" description="非覆盖方法的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.methodcomment" name="methodcomment">/**
 * @Description ${todo}
 * ${tags}
 * @author ${user}
 * @date ${date} ${time}
 */</template><template autoinsert="false" context="gettercomment_context" deleted="false" description="getter 方法的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.gettercomment" name="gettercomment">/**
 * 返回 ${bare_field_name} 的值     
 * @return ${bare_field_name}
 */   
</template><template autoinsert="false" context="overridecomment_context" deleted="false" description="覆盖方法的注释" enabled="true" id="org.eclipse.jdt.ui.text.codetemplates.overridecomment" name="overridecomment">/* (非 Javadoc)
 * 覆盖方法
 * &lt;p&gt;Title: ${enclosing_method}&lt;/p&gt;
 * &lt;p&gt;Description: &lt;/p&gt;
 * ${tags}
 * ${see_to_overridden}
 */</template></templates>
```


> 参考文章：
>
> [1] https://github.com/google/styleguide
>
> [2] http://www.hawstein.com/posts/google-java-style.html#Practice
