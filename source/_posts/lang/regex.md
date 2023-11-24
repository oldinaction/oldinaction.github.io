---
layout: "post"
title: "正则(Regex)"
date: "2017-12-26 10:29"
categories: [lang]
tags: [regex, js, java]
---

## 简介

- [regexr](https://regexr.com/)
- [JS正则表达式测试](https://c.runoob.com/front-end/854)
- [Java正则表达式测试](https://www.lddgo.net/string/regex)

## javascript正则

- [JS正则表达式测试](https://c.runoob.com/front-end/854)
- 参考文章：https://juejin.cn/post/6844903487155732494

### 语法说明

- 修饰符
    - `g` 全局匹配
    - `i` 忽略大小写
    - `m` 多行匹配

### 匹配说明

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

// 如果匹配到全部为字母(含大小写)和数字则返回true, 否则返回false
/^[\da-z]+$/i.test(str)

// JAVA和JS字符串每4个字符添加空格
// https://www.cnblogs.com/eternityz/p/13686419.html
```
- 提取数据

```js
// 提取百度网盘数据
var content="链接：https://pan.baidu.com/s/14Ohd4jLuMWLRtqIt6eUNKg\n提取码：5dlw\n复制这段内容后打开百度网盘手机App，操作更方便哦";
var reg = /链接：(.*)/;
console.log(reg.exec(content)[1].trim()); // https://pan.baidu.com/s/14Ohd4jLuMWLRtqIt6eUNKg
var reg1 = /提取码：(.*)/;
console.log(reg1.exec(content)[1].trim()); // 5dlw

// 提取工资
var str = "张三：1000，李四：5000，王五：8000。";
var array = str.match(/\d+/g);
console.log(array); // ['1000', '5000', '8000']

// 提取email地址
var str = "123123@xx.com,abc@test.cn 123@qq.com 2、test@test.test.com 456@qq.com...";
var array = str.match(/\w+@\w+\.\w+(\.\w+)?/g);
console.log(array); // ['123123@xx.com', 'abc@test.cn', '123@qq.com', 'test@test.test.com', '456@qq.com']

// 分组提取  
// 提取日期中的年部分  2015-5-10
var dateStr = '2016-1-5';
// 正则表达式中的()作为分组来使用，获取分组匹配到的结果用Regex.$1 $2 $3....来获取
var reg = /(\d{4})-\d{1,2}-\d{1,2}/;
if (reg.test(dateStr)) {
  console.log(RegExp.$1); // 2016
}

// 匹配变量
"@a@@1abc@@@ccc$12_a@".match(/@[_\\$a-zA-Z]+[_\\$a-zA-Z0-9]*?@/g); // ['@a@', '@ccc$12_a@']
```
- vscode正则替换

```js
// 可以将如"title: 'abc'"换成"title: '{{ abc }}'"
// 查找
title: '([a-zA-Z0-9-_]*?)'
// 替换为
title: '{{ $1 }}}'
```

## java

- [Java正则表达式测试](https://www.lddgo.net/string/regex)
- 参考文章
    - https://segmentfault.com/a/1190000009162306

### 匹配符/元字符/限定符

```bash
## 或
[jpg|png] # 代表匹配 j 或 p 或 g 或 p 或 n 或 g 中的任意一个字符
(jpg|png) # 代表匹配 jpg 或 png

## 反斜杠 \
# 在匹配 . 或 { 或 [ 或 ( 或 ? 或 $ 或 ^ 或 * 这些特殊字符时，需要在前面加上 \\，比如匹配 . 时，Java 中要写为 \\.，但对于正则表达式来说就是 \.
# 在匹配 \ 时，Java 中要写为 \\\\，但对于正则表达式来说就是 \\

### 元字符
\d	# 匹配一个数字，是 [0-9] 的简写
\D	# 匹配一个非数字，是 [^0-9] 的简写
\s	# 匹配一个空格，是 [ \t\n\x0b\r\f] 的简写。java字符串中一般要写成\\s
\S	# 匹配一个非空格
\w	# 匹配一个单词字符（大小写字母、数字、下划线），是 [a-zA-Z_0-9] 的简写
\W	# 匹配一个非单词字符（除了大小写字母、数字、下划线之外的字符），等同于 [^\w]

### 限定符
.       # ***** 匹配除换行符（\n、\r）之外的任何单个字符，相等于 [^\n\r]；使用 \s\S 相当于所有字符
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
    - `(?s)` **表示单行模式**（"single line mode"）使正则的 `.` 匹配所有字符，包括换行符
    - `(?m)` 默认为多行模式。表示多行模式（"multi-line mode"），使正则的 `^` 和 `$` 匹配字符串中每行的开始和结束
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

// 对比
str="123-456A888A"
str.replaceAll("^[0-9\\-]*", ""); // A888A
str.replaceAll("^[0-9\\-].", ""); // 3-456A888A
str.replaceAll("^[0-9\\-].*", ""); // 
str.replaceAll("^[0-9\\-].*?", ""); // 23-456A888A
str.replaceAll("^[0-9\\-]?", ""); // 23-456A888A


// 去掉注释，不能使用 .*? (.不包含换行符)
"/* 多行注释 */select 1 from dual".replaceFirst("/\\*[\\s\\S]*?\\*/", "");


// 提取注释文本，如
1
/* RT_START REPLACE(select 1 where 1=1) */
2
/* RT_END */
3
// https://www.lddgo.net/string/regex 上面测试的正则表达式为 (?i)/\*\s*?RT_START\s+(.*?)\s\*/[\s\S]*?/\*\s*?RT_END\s*?\*/
Pattern RTPattern = Pattern.compile("(?i)/\\*\\s*?RT_START\\s+(.*?)\\s\\*/[\\s\\S]*?/\\*\\s*?RT_END\\s*?\\*/");
Matcher matcher = RTPattern.matcher(sql);
while (matcher.find()) {
    System.out.println(matcher.group()); // /* RT_START ... 2 ... /* RT_END */
    System.out.println(matcher.group(1)); // REPLACE(select 2 where 1=1)
}
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
str.replaceAll(pattern, "$1$3"); // Hello, World.
// 将一个以上的字母数字替换成|
"abbc11abcc".replaceAll("(\\w)\\1+", "|"); // a|c|ab|

// (2) 使用反向引用
String str = "img.jpg";
Pattern pattern = Pattern.compile("(jpg|png)"); // 分组且创建反向引用
// Pattern pattern = Pattern.compile("(?:jpg|png)"); // 有?:表示仅分组，但不创建反向引用。此时下面 matcher.group(1) 会报错 IndexOutOfBoundsException
Matcher matcher = pattern.matcher(str);
// 可能会匹配到多次; 如果只需要匹配第一个，也需要执行一次 matcher.find()
while (matcher.find()) {
    System.out.println(matcher.group()); // jpg
    System.out.println(matcher.group(1)); // jpg 取第一个括号的值
}

// 匹配html中 <input type="hidden" name="__value" id="__value" value="123" /> 的value值
Pattern pattern = Pattern.compile("<input\\s+type=\"hidden\"\\s+name=\"__value\"\\s+id=\"__value\"\\s+value=\"([^\"]+)\"\\s*/>");
Matcher matcher = pattern.matcher(body);
if(matcher.find()) {
    System.out.println(matcher.group(1)); // 123
}
```

### 正反前瞻后瞻

- https://blog.csdn.net/xys_777/article/details/8642566
    https://www.iteye.com/blog/xixian-1323630
    https://www.iteye.com/blog/xixian-721147
    https://blog.csdn.net/iterzebra/article/details/6795857

- 正向前瞻 `string(?=pattern)`
    - 在任何匹配 pattern 的字符串开始处匹配查找字符串。这是一个非获取匹配，也就是说，该匹配不需要获取供以后使用
    - 例如 'Windows (?=95|98|NT|2000)' 能匹配 "Windows 2000" 中的 "Windows" ，但不能匹配 "Windows 3.1" 中的 "Windows"
- 反向前瞻 `string(?!pattern)`
    - 例如 'Windows (?!95|98|NT|2000)' 能匹配 "Windows 3.1" 中的 "Windows"，但不能匹配 "Windows 2000" 中的 "Windows"
- 正向后瞻 `(?<=pattern)string`
- 反向后瞻 `(?<!pattern)string`
- 案例

```java
// 匹配非某字符开头的，匹配非CN开头的字符串
^(?!CN).*
// 匹配CN开头的字符串，且不以CNSHA和CNKUS开头的字符串
^CN(?!SHA|KUS).* // pass=["CN", "CNABC"] nopass=["CNSHA", "CNKUS", "ABC"]
```

### Matcher

- matches() 是全部匹配
- find() 是部分匹配。如果匹配成功，还可使用下列方法
    - start() 匹配的子串在输入字符串中的索引位置
    - end() 匹配的子串的最后一个字符在输入字符串中的索引位置
    - group() 返回匹配到的子字符串

```java
Pattern pattern = Pattern.compile ("\\d{4,6}");
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

// 易错点
"ABCTEL ".matches("(TEL|MOBILE)([\\s:：])*$"); // false
Matcher matcher = Pattern.compile("(TEL|MOBILE)([\\s:：])*$")   ;
matcher.matches(); // false
matcher.find(); // true 通过 matcher.group() 可获取匹配结果
```

### 常见案例

- 校验

```java
// 正在表达式变量拼接
str.matches(String.format("^[-]{0,1}\\d{1,%d}$", 3)); // [-][0-999]
// 校验汉字
str.matches("^[\u4e00-\u9fa5]{0,}$");
// 匹配变量名
str.matches("^[_$a-zA-Z][\\w$]*$");
```

- 正则替换
    - replace 普通字符串替换所有
    - replaceFirst 正则替换第一个匹配的
    - replaceAll 正则替换所有的

```java
// 去掉非字母数字
"GP151971-GP151974-GP".replaceAll("[^A-Za-z0-9]", ""); // GP151971GP151974GP

// 去掉非ASCII。下例中notepad++中显示STX(start of text character)，https://en.wikipedia.org/wiki/Control_character
"UT25PHW(I1)".replaceAll("[^\\x0A\\x0D\\x20-\\x7E]", ""); // UT25PHW(I1)

String p = "\\{" + "\\$\\$\\$" + "\\}";
System.out.println(a); // \{\$\$\$\}
String s = "C{$$$}-{$$$}".replaceFirst(p, "123"); // C123-{$$$}

// 正则替换结合反向引用
"left-right".replaceAll("(.*)-(.*)", "$2-$1"); // right-left
"You want million dollar?!?".replaceAll("(\\w*) dollar", "US\\$ $1"); // You want US$ million?!?
// 将重叠的字符换成|
"abbc11abccc".replaceAll("(\\w)\\1+", "|"); // a|c|ab|

// 将02后面的?'替换成'
String str = "01:START'\n02:AA?'\n03:11'\n02:BB?'\n03:22'\n04:EDN'";
// matches是否匹配判断时需要完全匹配文本，正则表达式需要把正文本填上
str.matches("(?s)(02:.*?)(\\?')([\r\n]*?03:)"); // false
if(str.matches("(?s).*?(02:.*?)(\\?')([\r\n]*?03:).*")) {
    // 只能替换第一个02
    // str.replaceAll("(?s)(.*?02:.*?)(\\?')([\r\n]*?03:.*)", "$1'$3");
    // 可全部替换. 替换只需将目标子串的正则写出来
    str.replaceAll("(?s)(02:.*?)(\\?')([\r\n]*?03:)", "$1'$3");
}
```
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
- 匹配括号对

```java
String dakuohao = "{a+b}={c+d}>{d}";
Pattern compile = Pattern.compile("\\{([^}]*)\\}"); // "\\(([^}]*)\\)" 匹配小括号
Matcher matcher = compile.matcher(dakuohao);
// {a+b};{c+d};{d};
while(matcher.find()) {
    String group = matcher.group();
    System.out.print(group+";");
}
```

### IDEA正则

- 正则表达式替换 https://blog.csdn.net/u011615002/article/details/117621582
- IDEA正则表达式 https://blog.csdn.net/qq_41296917/article/details/111530450
- 如wm_concat增加to_char语句包裹
    - 搜索`wm_concat\((.*?)\)`替换为`to_char(wm_concat($1))`
    - 上述方法只能解决部分简单SQL，对于一些复杂的SQL反括号位置可能会有问题

## php

```php
// 获取url中某个参数值
function getUrlParams($url, $arg_name) {
    $regx = '/.*[&|\?]'. $arg_name .'=([^&]*)(.*)/';
    preg_match($regx, $url, $match);
    return $match[1];
}
```


