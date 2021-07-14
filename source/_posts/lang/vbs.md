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

- `'`表示注释
- 不区分大小写

### 变量

- 变量声明：可以使用 `Dim`、`Public` 或 `Private` 语句来声明变量

```vb
'简单变量
dim name
name=some value

'数组变量：创建了一个包含2个元素的数组
dim names(2)
names(0)="George"
names(1)="John"
father=names(0)

'多维数组
dim table(4, 6)
```

### 程序

```vb
'子程序(无返回值)
Sub mysub(argument1,argument2)
 some statements
End Sub

'函数程序(有返回值)
Function myfunction(argument1,argument2)
 some statements
 myfunction=some value
End Function

'调用子程序或函数的方式
name = MyProc(argument)
Call MyProc(argument)
MyProc argument
```

### 控制语句

- 条件语句参考：https://www.w3school.com.cn/vbscript/vbscript_conditionals.asp
- 循环语句参考：https://www.w3school.com.cn/vbscript/vbscript_looping.asp

## 内置函数

- 参考 https://www.w3school.com.cn/vbscript/vbscript_ref_functions.asp
- SendKeys
    - 模拟键盘操作：https://www.itdaan.com/blog/2011/03/25/e598b7eaed4fd60a1379c1ea8763d167.html

## 异常处理

- VBScript语言提供了两个语句和一个对象来处理运行时错误
    - `On Error Resume Next` 语句：如果此语句后面的程序出现运行时错误时，会继续运行，不中断
    - `On Error Goto 0` 语句：如果此语句后面的程序出现运行时错误时，会显示出错信息并停止程序的执行
    - `Err` 对象：存储了关于运行期错误的信息
        - Description 设置或返回一个描述错误的字符串
        - Number （缺省属性）设置或返回指定一个错误的值
        - Source 设置或返回产生错误的对象的名称
        - Clear	方法：清除当前所有的Err对象设置
        - Raise	方法：产生一个运行期错误

## 与bat结合

- 一个 批处理 .vbs 文件，在前面加一段代码（头），就变成了 .bat 批处理，注意，没有生成临时文件
- test.bat为例
    - bat文件，可解析其中的vbs代码，同时执行了一段批处理和vbs，没有生成临时文件，用了大量的 hack 技巧。根推荐生成临时vbs文件的方式
    - 执行bat脚本后回车会弹出一个确认框(This is vbs)

    ```bat
    :On Error Resume Next
    :Sub bat
    echo off & cls
    echo Batching_codez_here_following_vbs_rules & pause >nul
    echo '>nul & start "" wscript //e:vbscript "%~f0" %*
    Exit Sub : End Sub
    MsgBox "This is vbs"
    for each i in wscript.arguments
    wscript.echo i
    next
    ```
    - 说明

    ```bash
    # cmd.exe 识别成一段注释
    # wscript.exe识别方式: `:`在vbs语法里代表分行，然后 On Error Resume Next，也就是让WSH忽略一些错误
    :On Error Resume Next

    # cmd.exe 识别成：echo一个 ' 到 空设备，也就是什么都不显示。& 的意思是同时执行，那么同时执行了 start "" wscript //e:vbscript "%~f0" %*，也就是启动WSH，用VBS语法解析自身
    echo '>nul & start "" wscript //e:vbscript "%~f0" %*
    ```
