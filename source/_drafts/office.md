---
layout: "post"
title: "Office常用技巧"
date: "2021-11-18 08:58"
categories: lang
tags: [vb]
---

## Excel

### 公式

- 案例参考 https://www.lanrenexcel.com/excel-formulas/

#### 文本处理

- &字符串拼接
    - 案例 `=B3&"："&CHAR(10)&C3&"（"&D3&"）"`
        - 其中`CHAR(10)`是换行符，需要该单元格开启自动换行。参考：https://www.lanrenexcel.com/excel-cell-line-break/
- 分列拆分单元格数据
    - 案例：将A-B-123拆分成3列A、B、123 (参考：https://www.lanrenexcel.com/excel-formula-text-to-column/)

### 函数

- 案例参考 https://www.lanrenexcel.com/excel-functions-list/

#### VLookup查找(含某值的区域)

- 参考：https://www.zhihu.com/question/34419318
- 语法：`=VLOOKUP(查找值, 查找区域, 返回区域中的第几列, 是否近似匹配-可选)`
    - 近似匹配TRUE/1, 精确匹配FALSE/0
- 案例：`=VLOOKUP(A7, A2:B5, 2, 0)`

#### 读取XML/调用网页(如翻译)

- `_xlfn.FILTERXML` 读取XML内容
- `_xlfn.WEBSERVICE` 调用网页内容
- 如`=_xlfn.FILTERXML(_xlfn.WEBSERVICE("http://fanyi.youdao.com/translate?&i="&I15&"&doctype=xml&version"),"//translation")`
    - 将`I15`列的内容进行翻译
    - 如有道翻译: `http://fanyi.youdao.com/translate?&i="hello world, my name is smalle"&doctype=xml&version`
        - doctype=json也支持

### 业务场景

#### 查找两列的重复项

- https://zh-cn.extendoffice.com/documents/excel/774-excel-find-duplicates-in-two-columns.html

#### 将科学计数法转换为文本或数字

- https://zh-cn.extendoffice.com/documents/excel/1725-excel-convert-scientific-notation-to-text.html

#### 横向纵向值字典转成数据库行结构

- https://www.seotcs.com/excel/3595.html
    - 打开“数据透视表和数据透视图向导”对话框
    - 选择“多重合并计算数据区域”
    - 生成透视表之后，右击数据透视表行总计和列总计交叉的单元格，选择“显示详细信息”

## Word

### 快捷键

- Ctrl+Enter 换页

### 常用案例

#### 打印图片黑色背景问题

- word: 右键图片-格式
- wps: 编辑图片-滤镜
- ps: 调整-亮度和对比图
- 然后调整如：亮度20，对比度50，word可适当调整清晰度

### 图表

- 图表中当数值为0时不显示标签
    - 设置标签格式为自定义`0;-0;;@`
    - 另外如需要自定义百分比前缀格式: `百分比: 0.00%`
