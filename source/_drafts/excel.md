---
layout: "post"
title: "Excel常用技巧"
date: "2021-11-18 08:58"
categories: lang
tags: [vb]
---

## 公式

- 案例参考 https://www.lanrenexcel.com/excel-formulas/

### 文本处理

- &字符串拼接
    - 案例 `=B3&"："&CHAR(10)&C3&"（"&D3&"）"`
        - 其中`CHAR(10)`是换行符，需要该单元格开启自动换行。参考：https://www.lanrenexcel.com/excel-cell-line-break/
- 分列拆分单元格数据
    - 案例：将A-B-123拆分成3列A、B、123 (参考：https://www.lanrenexcel.com/excel-formula-text-to-column/)

## 函数

- 案例参考 https://www.lanrenexcel.com/excel-functions-list/

### VLookup查找(含某值的区域)

- 参考：https://www.zhihu.com/question/34419318
- 语法：`=VLOOKUP(查找值, 查找区域, 返回区域中的第几列, 是否近似匹配-可选)`
    - 近似匹配TRUE/1, 精确匹配FALSE/0
- 案例：`=VLOOKUP(A7, A2:B5, 2, 0)`

### 读取XML/调用网页(如翻译)

- `_xlfn.FILTERXML` 读取XML内容
- `_xlfn.WEBSERVICE` 调用网页内容
- 如`=_xlfn.FILTERXML(_xlfn.WEBSERVICE("http://fanyi.youdao.com/translate?&i="&I15&"&doctype=xml&version"),"//translation")`
    - 将`I15`列的内容进行翻译
    - 如有道翻译: `http://fanyi.youdao.com/translate?&i="hello world, my name is smalle"&doctype=xml&version`
        - doctype=json也支持

