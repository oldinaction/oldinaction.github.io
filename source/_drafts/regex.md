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

> https://juejin.cn/post/6844903487155732494

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

### 匹配符/元字符/限定符

```bash
## 或
[jpg|png] # 代表匹配 j 或 p 或 g 或 p 或 n 或 g 中的任意一个字符
(jpg|png) # 代表匹配 jpg 或 png

## 反斜杠
# 在匹配 . 或 { 或 [ 或 ( 或 ? 或 $ 或 ^ 或 * 这些特殊字符时，需要在前面加上 \\，比如匹配 . 时，Java 中要写为 \\.，但对于正则表达式来说就是 \.
# 在匹配 \ 时，Java 中要写为 \\\\，但对于正则表达式来说就是 \\

### 元字符
\d	# 匹配一个数字，是 [0-9] 的简写
\D	# 匹配一个非数字，是 [^0-9] 的简写
\s	# 匹配一个空格，是 [ \t\n\x0b\r\f] 的简写
\S	# 匹配一个非空格
\w	# 匹配一个单词字符（大小写字母、数字、下划线），是 [a-zA-Z_0-9] 的简写
\W	# 匹配一个非单词字符（除了大小写字母、数字、下划线之外的字符），等同于 [^\w]

### 限定符
*	    # 匹配 >=0 个，是 {0,} 的简写
+	    # 匹配 >=1 个，是 {1,} 的简写
?	    # 匹配 1 个或 0 个，是 {0,1} 的简写
{X}	    # 只匹配 X 个字符. \d{3} 表示匹配 3 个数字
{X,Y}	# 匹配 >=X 且 <=Y 个. \d{1,4} 表示匹配至少 1 个最多 4 个数字
*?      # 如果 ? 是限定符 * 或 + 或 ? 或 {} 后面的第一个字符，那么表示非贪婪模式（尽可能少的匹配字符），而不是默认的贪婪模式	
+?
??
{}?
```

### 模式修饰符

- 在正则的开头指定
    - `(?i)` 使正则忽略大小写
    - `(?s)` 表示单行模式（"single line mode"）使正则的 `.` 匹配所有字符，包括换行符
    - `(?m)` 表示多行模式（"multi-line mode"），使正则的 `^` 和 `$` 匹配字符串中每行的开始和结束
- 案例

```java
// 忽略大小写
// 第一种：直接用正则。(?i)表示整体忽略大小写，如果单个，则可以写成"^d(?i)oc"表示oc忽略大小写，"^d((?i)o)c"表示只有o忽略大小写
"DoC".matches("^(?i)doc$"); // true

// 第二种，采用Patter编译忽略大小写
Pattern p = Pattern.compile("^doc$", Pattern.CASE_INSENSITIVE);
p.matcher(s).matches(); // true

// 匹配 select 类型的 sql 语句。Pattern.CASE_INSENSITIVE忽略大小写，(?s)单行模式(否则无法匹配到\n等字符)，最后的`.*`需要
Pattern.compile("(?s)^[ \t\n\r]*select[ \t\n\r]+.*", Pattern.CASE_INSENSITIVE).matcher(sql.trim()).matches(); // 返回true或false
```

### 惰性匹配

```java
// (.*?) 惰性匹配
Pattern.matches("/api/(.*?)/auth/(.*?)", "/api/ds/v1/auth/login"); // true
Pattern.matches("/api/(.*?)/auth/(.*?)", "/api/ds/v2/auth/login"); // true
Pattern.matches("/api/(.*?)/auth/(.*?)", "/api/ds/v2/xxx/login"); // false
```

### 分组和反向引用

- 分组：使用`()`进行分组
- 反向引用：`$0`代表整个正则表达式，`$1`代表第一个括号正则表达式，`$2`代表第二个括号正则表达式，依次类推
    - `matcher.group()`表示整个正则匹配到的内容，`matcher.group(1)`表示第一个括号匹配到的内容，依次类推
- 当我们在小括号 `()` 内的模式开头加入 `?:`，那么表示这个模式仅分组，但不创建反向引用。不创建反向应用将不能使用group(x)

```java
// (1) 去除单词与 , 和 . 之间的空格
String str = "Hello , World .";
String pattern = "(\\w)(\\s+)([.,])";
// $0 匹配 `(\w)(\s+)([.,])` 结果为 `o ,` 和 `d .`
// $1 匹配 `(\w)` 结果为 `o` 和 `d`
// $2 匹配 `(\s+)` 结果为 ` ` 和 ` `
// $3 匹配 `([.,])` 结果为 `,` 和 `.`
System.out.println(str.replaceAll(pattern, "$1$3")); // Hello, World.

// (2) 使用反向引用
String str = "img.jpg";
Pattern pattern = Pattern.compile("(jpg|png)"); // 分组且创建反向引用
// Pattern pattern = Pattern.compile("(?:jpg|png)"); // 仅分组，但不创建反向引用。此时下面 matcher.group(1) 会报错 IndexOutOfBoundsException
Matcher matcher = pattern.matcher(str);
while (matcher.find()) {
    System.out.println(matcher.group()); // jpg
    System.out.println(matcher.group(1)); // jpg
}
```

### Matcher

- matches() 是全部匹配
- find() 是部分匹配。如果匹配成功，还可使用下列方法
    - start() 匹配的子串在输入字符串中的索引位置
    - end() 匹配的子串的最后一个字符在输入字符串中的索引位置
    - group() 返回匹配到的子字符串

```java
Pattern pattern = Pattern .compile ("\\d{4,6}");
Matcher matcher = pattern.matcher("1234-56789-11");
System.out.println(matcher.find()); // true. 搜索至第一个"-"
System.out.println(matcher.find()); // true. 如果前一个匹配成功，则从上一次匹配的字符串的下一个字符开始搜索。此时从第一个"-"开始匹配，匹配失败，接着直接匹配5，然后56789就匹配成功
System.out.println(matcher.find()); // false. 此时从第二个"-"开始匹配，匹配失败，接着直接匹配11，然后失败；之后继续匹配会一直失败

// 注意结束表达式
Pattern pattern = Pattern.compile("(?s)([A-Z0-9]*)(.*)(xls|xlsx)", Pattern.CASE_INSENSITIVE);
// Pattern pattern = Pattern.compile("(?s)([A-Z0-9]*)(.*)", Pattern.CASE_INSENSITIVE); // 会循环两次，且第二次返回的都是空字符串(即未匹配到)
Matcher matcher = pattern.matcher("ABC_DE_测试.xls");
while (matcher.find()) {
    System.out.println(matcher.group()); // ABC_DE_测试.xls
    System.out.println(matcher.group(1)); // ABC
    System.out.println(matcher.group(2)); // _DE_测试.
    System.out.println(matcher.group(3)); // xls
}
```

### String的matches

```java
"hi, hello world".matches("(.*)hello(.*)"); // true
"hi, hello world".matches("hello"); // false, ***特别注意此时无法匹配***
"hi, hello world".matches("(hi(.*))"); // true
```

### 常见案例

- 匹配中文

```java
String str = "hello world 你好"
Pattern pattern = Pattern.compile("(?s)([\\w& ./]+)([\\u4E00-\\u9FA5]+)", Pattern.CASE_INSENSITIVE);
Matcher matcher = pattern.matcher(str);
while (matcher.find()) {
    System.out.println(matcher.group(1)); // hello world 
    System.out.println(matcher.group(2)); // 你好
}
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


