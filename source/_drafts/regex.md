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
    - 横向模糊匹配: `"abc abbc abbbc abbbbc abbbbbc abbbbbbc".match(/ab{2,5}c/g); // ["abbc", "abbbc", "abbbbc", "abbbbbc"]`
    - 纵向模糊匹配：`"a0b a1b a2b a3b a4b".match(/a[123]b/g); // ["a1b", "a2b", "a3b"]`
- 字符组
    - `[abc]` 表示匹配一个字符，它可以是"a"、"b"、"c"之一
    - `[^abc]` 排除字符组. 表示是一个除"a"、"b"、"c"之外的任意一个字符
- 量词
    - 贪婪匹配(尽可能多的匹配)：`"123 1234 12345 123456".match(/\d{2,5}/g); // ["123", "1234", "12345", "12345"]` 其中正则/\d{2,5}/，表示数字连续出现2到5次。会匹配2位、3位、4位、5位连续数字。
    - 惰性匹配(尽可能少的匹配)：`"123 1234 12345 123456".match(/\d{2,5}?/g); // ["12", "12", "34", "12", "34", "12", "34", "56"]` 其中/\d{2,5}?/表示，虽然2到5次都行，当2个就够的时候，就不在往下尝试了
- 多选分支
    - `"good idea, nice try.".match(/good|nice/g); // ["good", "nice"]`
    - 分支结构是惰性匹配
        - `"goodby".match(/good|goodby/g); // ["good"]`
        - `"goodby".match(/goodby|good/g); // ["goodby"]`

### 案例

- 匹配16进制颜色值 `"#ffbbad #Fc01DF #FFF #ffE".match(/#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})/g); // ["#ffbbad", "#Fc01DF", "#FFF", "#ffE"]`
- window操作系统文件路径：`/^[a-zA-Z]:\\([^\\:*<>|"?\r\n/]+\\)*([^\\:*<>|"?\r\n/]+)?$/`
- 匹配id：`'<div id="container" class="main"></div>'.match(/id="([^"]*)"/); // ['id="container"', 'container']`
