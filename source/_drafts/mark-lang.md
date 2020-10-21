---
layout: "post"
title: "标记语言"
date: "2020-10-21 14:11"
categories: lang
tags: [yaml, json]
---

## yaml

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




