---
layout: "post"
title: "Velocity"
date: "2020-12-16 20:03"
categories: [java]
tags: [template]
---

## 简介

- [官网](http://velocity.apache.org/)、[Doc-user](http://velocity.apache.org/engine/devel/user-guide.html)、[Doc-developer](http://velocity.apache.org/engine/devel/developer-guide.html)
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

## 变量取值

```html
<!-- 根据变量从map中取值 -->
$!{myMap.key}
$!{myMap['key']}
$!{myMap.get($!{relate.toEntityId})}

<!-- 根据变量从list中取值和获取数组大小 -->
$!{myList.get(0)}
$!{myList.size()}

<!-- 默认值 -->
${name|'John Doe'}
```

## 控制语句

### 循环

```html
## 循环map
#foreach($item in $!softTypeMap.entrySet())
<option value="$!{item.key}">$!{item.value}</option>
#end

## 判断循环最后一个。如果不是最后一个元素，则添加逗号
#foreach($column in $columns)
    ${column.columnName}#if($foreach.hasNext),#end

    $foreach.index //下标
    $foreach.count //数组长度
    $foreach.first 
    $foreach.last
    $foreach.hasNext //是否是最后一个
    $velocityCount // 用作循环计数，初始值是1。这个变量的名字和初始值是在velocity.properties文件里配置的。最新版本已作废
#end
```

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

## 其他

- 导入外部文件

```html
<!-- #parse 支持 velocity 标签. tpl为resources目录下文件夹 -->
#parse("/tpl/layout.vm")
<!-- #include 不支持 velocity标签 -->
#include("/tpl/layout.vm")
```
- 调用静态方法，如`context.put("Math", Math.class);`：http://velocity.apache.org/engine/devel/developer-guide.html#support-for-static-classes

## 案例

### 邮件模板

```html
<!DOCTYPE html>
<html lang="zh">

<head>
  <meta charset="UTF-8" />
  <title>$!{subject}</title>
  <style>
    html {
      font-family: sans-serif;
      -ms-text-size-adjust: 100%;
      -webkit-text-size-adjust: 100%;
    }

    body {
      padding: 20px;
      font-size: 14px;
      margin: 0;
    }

    table {
      border-top: 1px solid #000000;
      border-left: 1px solid #000000;
      border-collapse: collapse;
      /* table-layout: fixed;
      word-wrap: break-word; */
      /*列表会自动撑开，超过此宽度则会缩小字体从而完全显示(实际邮件中一般可点击放大查看)*/
      width: 1000px;
    }

    th,
    td {
      border-bottom: 1px solid #000000;
      border-right: 1px solid #000000;
    }

    table tr:nth-child(odd) {
      background: #F4F4F4;
    }

    table tr:hover{
      background:#abdcff;
    }
  </style>
</head>

<body>

此邮件为系统自动发出，请勿直接回复！

<h4>$!{subject}（数据抓取时间：$!{date}）</h4>
#if("$!{dataList}" != "")
<table>
  <tr style="background-color: #666; color: white;">
    #foreach($col in $!{tableCols})
      <th>$!{col}</th>
    #end
  </tr>
  #foreach($item in $!{dataList})
    <tr>
      #foreach($col in $!{tableCols})
        <td>$!{item.get($!{col})}</td>
      #end
    </tr>
  #end
</table>
#end
</body>
</html>
```

