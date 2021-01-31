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
    #end

    ## 关键字、符号可以连写，如`#else$string#end`。但是写成`#elseString#end`又无法识别，写成`#else String#end`会多出一个空格
    #set($string = $!{field.format} + "String") ## 仅演示语法
    private #if("$!{field.format}" == "number")Integer#else$string#end$!{field.name};
#end
#end
```

