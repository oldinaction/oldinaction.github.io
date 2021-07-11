---
layout: "post"
title: "Visual Basic Script"
date: "2021-07-11 20:38"
categories: [lang]
tags: [windows, vb]
---

## 简介

- VBScript是 Visual Basic Script 的简称，即 Visual Basic 脚本语言，有时也被缩写为 VBS
- VBScript 是微软开发的一种脚本语言。使用 VBScript，可通过 Windows 脚本宿主调用 COM，所以可以使用 Windows 操作系统中可被使用的程序库
- VBScript 一般被用在以下个方面
    - VBScript 经常被用来完成重复性的Windows 操作系统任务
    - 用来指挥客户方的网页浏览器。在这一方面，VBS 与JavaScript 是竞争者
- VBS相关脚本参考：https://www.jb51.net/list/list_114_1.htm

## 基本语法

### 变量

- 变量声明：可以使用 `Dim`、`Public` 或 `Private` 语句来声明变量

```vb
# 简单变量
dim name
name=some value

# 数组变量：创建了一个包含2个元素的数组
dim names(2)
names(0)="George"
names(1)="John"
father=names(0)

# 多维数组
dim table(4, 6)
```

### 程序

```vb
# 子程序(无返回值)
Sub mysub(argument1,argument2)
 some statements
End Sub

# 函数程序(有返回值)
Function myfunction(argument1,argument2)
 some statements
 myfunction=some value
End Function

# 调用子程序或函数的方式
name = MyProc(argument)
Call MyProc(argument)
MyProc argument
```

### 控制语句

- 条件语句参考：https://www.w3school.com.cn/vbscript/vbscript_conditionals.asp
- 循环语句参考：https://www.w3school.com.cn/vbscript/vbscript_looping.asp

### 内置函数

- 参考 https://www.w3school.com.cn/vbscript/vbscript_ref_functions.asp
