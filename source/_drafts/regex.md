---
layout: "post"
title: "正则(regex)"
date: "2017-12-26 10:29"
categories: [lang]
tags: [regex, javascript, java]
---

## 简介

## javascript正则

### 语法说明

### 匹配说明

> https://zhuanlan.zhihu.com/p/27653434

- 两种模糊匹配

    ```js
    // 横向模糊匹配
    "abc abbc abbbc abbbbc abbbbbc abbbbbbc".match(/ab{2,5}c/g); // ["abbc", "abbbc", "abbbbc", "abbbbbc"]
    // 纵向模糊匹配
    "a0b a1b a2b a3b a4b".match(/a[123]b/g); // ["a1b", "a2b", "a3b"]
    ```
- 字符组

    ```js
    // [abc]表示匹配一个字符，它可以是"a"、"b"、"c"之一
    "abcde".match(/[abc]/g); // ["a", "b", "c"]
    // [^abc]表示排除字符组，除"a"、"b"、"c"之外的任意一个字符
    "abcde".match(/[^abc]/g); // ["d", "e"]
    ```
- 贪婪匹配尽可能多的匹配；惰性匹配尽可能少的匹配。**惰性匹配可以基于`?`实现**

    ```js
    var str = "123 1234 12345 123456";
    // 其中正则/\d{2,5}/，表示数字连续出现2到5次。会匹配2位、3位、4位、5位连续数字
    str.match(/\d{2,5}/g); // ["123", "1234", "12345", "12345"]
    // 其中/\d{2,5}?/表示，虽然2到5次都行，当2个就够的时候，就不在往下尝试了
    str.match(/\d{2,5}?/g); // ["12", "12", "34", "12", "34", "12", "34", "56"]

    var str = 'aaa<div style="font-color:red;">123456</div>bbb';
    str.match(/<.+>/); // <div style="font-color:red;">123456</div>
    str.match(/<.+?>/); // <div style="font-color:red;">

    // 匹配不包含某些字符串，参考：https://www.jb51.net/article/52491.htm
    // 匹配不包含www的cnblog网站
    "www.cnblogs.com".match(/^((?!www).*)\.cnblogs\.com/) // null
    "images2018.cnblogs.com".match(/^((?!www).*)\.cnblogs\.com/) // images2018.cnblogs.com、images2018
    ```
- 多选分支

    ```js
    "good idea, nice try.".match(/good|nice/g); // ["good", "nice"]
    // 分支结构是惰性匹配
    "goodby".match(/good|goodby/g); // ["good"]
    "goodby".match(/goodby|good/g); // ["goodby"]
    ```

### 案例

```js
// 匹配16进制颜色值
"#ffbbad #Fc01DF #FFF #ffE".match(/#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})/g); // ["#ffbbad", "#Fc01DF", "#FFF", "#ffE"]
// window操作系统文件路径
/^[a-zA-Z]:\\([^\\:*<>|"?\r\n/]+\\)*([^\\:*<>|"?\r\n/]+)?$/
// 匹配id
'<div id="container" class="main"></div>'.match(/id="([^"]*)"/); // ['id="container"', 'container']

// 用户名（4-16位）
/^[a-zA-Z0-9_-]{4,16}$/

// JAVA和JS字符串每4个字符添加空格
// https://www.cnblogs.com/eternityz/p/13686419.html
```

## java

- 参考文章
    - https://segmentfault.com/a/1190000009162306
- 模式修饰符

```java
// 在正则的开头指定
// (?i) 使正则忽略大小写
// (?s) 表示单行模式（"single line mode"）使正则的 . 匹配所有字符，包括换行符
// (?m) 表示多行模式（"multi-line mode"），使正则的 ^ 和 $ 匹配字符串中每行的开始和结束

// 案例：匹配 select 类型的 sql 语句。Pattern.CASE_INSENSITIVE忽略大小写，(?s)单行模式(否则无法匹配到\n等字符)，最后的`.*`需要
Pattern.compile("(?s)^[ \t\n\r]*select[ \t\n\r]+.*", Pattern.CASE_INSENSITIVE).matcher(sql.trim()).matches(); // 返回true或false
```

- 惰性匹配

```java
// (.*?) 惰性匹配
Pattern.matches("/api/(.*?)/auth/(.*?)", "/api/ds/v1/auth/login"); // true
Pattern.matches("/api/(.*?)/auth/(.*?)", "/api/ds/v2/auth/login"); // true
Pattern.matches("/api/(.*?)/auth/(.*?)", "/api/ds/v2/xxx/login"); // false
```

- String的matches

```java
"hi, hello world".matches("(.*)hello(.*)"); // true
"hi, hello world".matches("hello"); // false, ***特别注意此时无法匹配***
"hi, hello world".matches("(hi(.*))"); // true
```

- 忽略大小写

```java
// 第一种：直接用正则。(?i)表示整体忽略大小写，如果单个，则可以写成"^d(?i)oc"表示oc忽略大小写，"^d((?i)o)c"表示只有o忽略大小写
"DoC".matches("^(?i)doc$"); // true

// 第二种，采用Patter编译忽略大小写
Pattern p = Pattern.compile("^doc$", Pattern.CASE_INSENSITIVE);
p.matcher(s).matches(); // true
```
- 或

```java
[jpg|png] // 代表匹配 j 或 p 或 g 或 p 或 n 或 g 中的任意一个字符
(jpg|png) // 代表匹配 jpg 或 png
```
- 反斜杠

```bash
# 在匹配 . 或 { 或 [ 或 ( 或 ? 或 $ 或 ^ 或 * 这些特殊字符时，需要在前面加上 \\，比如匹配 . 时，Java 中要写为 \\.，但对于正则表达式来说就是 \.
# 在匹配 \ 时，Java 中要写为 \\\\，但对于正则表达式来说就是 \\
```


## php

```php
// 获取url中某个参数值
function getUrlParams($url, $arg_name) {
    $regx = '/.*[&|\?]'. $arg_name .'=([^&]*)(.*)/';
    preg_match($regx, $url, $match);
    return $match[1];
}
```


