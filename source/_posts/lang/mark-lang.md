---
layout: "post"
title: "标记语言"
date: "2020-10-21 14:11"
categories: lang
tags: [yaml, json]
---

## yaml

- 参考 [Yaml解析(基于jyaml)](/_posts/java/java-tools.md#Yaml解析(基于jyaml))
- json-yaml互转工具：https://www.bejson.com/json/json2yaml
- yaml多行配置规则参考：https://www.cnblogs.com/didispace/p/12524194.html

```yml
# 配置与显示，都严格按段落展示
## 直接使用\n来换行
string: "Hello,\n\
         World."
## 使用｜(文中自动换行 + 文末新增一空行。测试可行)、｜+(文中自动换行 + 文末新增两个空行)、|-(文中自动换行 + 文末不新增空行)
string: |
  Hello,
  World.

# 配置按段落，显示不需要按段落
string: 'Hello,
         World.'
# 使用>(文中不自动换行 + 文末新增一空行)、>+、>-
string: >
  Hello,
  World.
```

## json

- json格式校验工具：https://qqe2.com/
- [json-path](https://github.com/json-path/JsonPath)：类似xpath获取json值
- 正确的json字符串

```json
{
    "name": "smalle",
    "age": 18,
    "hobbys": ["a", "b", 1]
}

[
    {
        "name": "smalle"
    }, 
    2
]
```
- 错误的json字符串

```js
{
    name: "smalle" // key必须要双引号。且json字符串不能有注释
}

{
    "name": "smalle", // 此处不该有逗号
}
```

## xpath




