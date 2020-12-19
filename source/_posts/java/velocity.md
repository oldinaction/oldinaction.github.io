---
layout: "post"
title: "Velocity"
date: "2020-12-16 20:03"
categories: [java]
tags: [template]
---

## 简介

- [官网](http://velocity.apache.org/)、[Doc](http://velocity.apache.org/engine/devel/user-guide.html)
- 依赖

```xml
<dependency>
    <groupId>org.apache.velocity</groupId>
    <artifactId>velocity-engine-core</artifactId>
    <version>2.2</version>
</dependency>
```

## 控制语句

```html
## 这是注释
#*
  这是多行注释
*#

#foreach($field in $!{table.fields})
#if($!{field.name})
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
    ## 关键字、符号可以连写，如`#else$string#end`。但是写成`#elseString#end`又无法识别，写成`#else String#end`会多出一个空格
    #set($string = "String")
    private #if("$!{field.format}" == "number")Integer#else$string#end$!{field.name};
#end
#end
```

