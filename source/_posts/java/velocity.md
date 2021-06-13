---
layout: "post"
title: "Velocity"
date: "2020-12-16 20:03"
categories: [java]
tags: [template]
---

## 简介

- [官网](http://velocity.apache.org/)、[Doc-1](http://velocity.apache.org/engine/devel/user-guide.html)、[Doc-2](http://velocity.apache.org/engine/devel/developer-guide.html)
- 依赖

```xml
<dependency>
    <groupId>org.apache.velocity</groupId>
    <artifactId>velocity-engine-core</artifactId>
    <version>2.2</version>
</dependency>
```

## 使用

```java

```

## 控制语句

### 举例

```html
## 这是注释
#*
  这是多行注释
*#

#foreach($field in $!{table.fields})
#if($!{field.name})
    #if($velocityCount==3 && !$!{field.keyFlag}) ## Velocity中有一个变量 $velocityCount 用作循环计数，初始值是1。这个变量的名字和初始值是在velocity.properties文件里配置的
        #break      ## 会跳出循环，类似break。continue功能只能通过if实现
        #stop       ## 退出程序(跳出循环，也不会执行循环之后的程序)，类似exit
    #end

    ## 语句解析后不会出现空行，如下写法生成的注释排版不会乱；replaceAll为直接调用对象方法
    /** 
    #if($!{field.desc})
     * 说明：$!{field.desc.replaceAll("\n","；").replaceAll("\r","；")}<br/>
    #elseif($!{field.comment} != "")
     * $!{field.comment}
    #else
     * ...
    #end
     */

    ## 转义字符"."后进行分割字符串
    #if("$!{field.comment}" != "")
        #set($commentName = $!{field.comment.replace("(x)", "").replace("（x）", "").split("\.").get(0).trim()})
        // \$message ## 转义 $, 渲染出来为: // $message; 如果无此变量则无需转义
    #end

    #if($!{field.comment} && $!{field.comment} != "")
        ## 判空
    #end

    ## 关键字、符号可以连写，如`#else$string#end`。但是写成`#elseString#end`又无法识别，写成`#else String#end`会多出一个空格
    #set($string = $!{field.format} + "String") ## 仅演示语法
    private #if("$!{field.format}" == "number")Integer#else$string#end$!{field.name};
#end
#end
```

### 取值

```html
<!-- 根据变量从map中取值 -->
$!{cfg.mpContext.mpTableRelateMap.get($!{relate.toEntityId})}
```

### 循环

```html
## 循环map
#foreach($item in $!softTypeMap.entrySet())
<option value="$!{item.key}">$!{item.value}</option>
#end

## 判断循环最后一个。如果不是最后一个元素，则添加逗号
#foreach($column in $columns)
    ${column.columnName}#if($foreach.hasNext),#end
#end
```

## 其他

- 导入外部文件

```html
<!-- #parse 支持 velocity 标签. tpl为resources目录下文件夹 -->
#parse("/tpl/layout.vm")
<!-- #include 不支持 velocity标签 -->
#include("/tpl/layout.vm")
```
- 调用静态方法，如`context.put("Math", Math.class);`：http://velocity.apache.org/engine/devel/developer-guide.html#support-for-static-classes

