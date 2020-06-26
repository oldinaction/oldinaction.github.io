---
layout: "post"
title: "PowerShell"
date: "2020-06-24 22:21"
categories: [lang]
tags: [windows, .NET]
---

## 简介

- [github](https://github.com/PowerShell/PowerShell)、[Doc(其中Reference为所有命令)](https://docs.microsoft.com/zh-cn/powershell/scripting/overview?view=powershell-7)
- PowerShell 是一个跨平台的 (Windows, Linux 和 OS X) 自动化和配置工具（框架），基于.NET开发。特别优化用于处理结构化数据 (如 JSON, CSV, XML 等), REST APIs 以及对象模型。它包含一个命令行 Shell、一个关联的脚本语言以及一个用于处理 cmdlets 的框架
- 启动(需要安装了powershell)
    - 直接在cmd中执行`powershell`，切换为powershell，命令行会变成`PS C:\Users\smalle>`
    - 开始菜单-附件-powershell启动

## 常见命令

- 命令不区分大小写

```bash
get-help [command] # 获取某命令帮助
man [command] # 获取某命令帮助
get-command get-* # 列出了所有get开头的命令。Alias是别名、Cmdlet是powershell格式的命令、Function是函数

test-path my-file # 判断文件是否存在，返回True|False
wirte-host abc # 打印abc. 将自定义输出写入主机，即打印在控制台
```
- 通用参数

```bash
-erroraction # -Erroraction是所有cmdlet的通用参数. silentlycontinue(静默运行，忽略错误)

# 示例
cp -erroraction 'silentlycontinue' -Recurse dir1 dir2 # 原本dir2中有dir1则会报错，此时则不会报错，会静默运行
```

## 常见语句

```bash
$b=2; echo $b # 设置变量. 打印2
echo 1; echo 2 # 打印1、2
try { echo 1; mycommand } catch { echo 2 } # 打印1、2(此时执行mycommand会报错的)
try { echo 1; mycommand } catch { write-error $_ } # 捕获异常并打印异常
if (test-path my-exist-file) { echo 1; echo 2 } # 文件存在则打印1/2
if (-not (test-path 'my-exist-file')) { echo 1; echo 2 } # -not 取反，此时不会打印；文件可以使用单引号或双引号包裹
```

## 运算

```bash
## 比较运算符号
-eq ：等于(不能使用==)
-ne ：不等于
-gt ：大于
-ge ：大于等于
-lt ：小于
-le ：小于等于
-contains ：包含
-notcontains ：不包含
-cmatch ：正则匹配
# 案例
1,2,3 -contains 2 # True
1,2,3 -ne 2 # 1、3(换行)
'this is NOT all lower-case' -cmatch '^[a-z\s-]*$' # False

## 逻辑(True|False)和位操作
-and ：和
-or ：或
-xor ：异或
-not ：逆
–band ：按位与
-bor ：按位或

## 其他运算符号
<待处理字符串> -replace <查找字符(可正则)>,<替换字符>
# 案例(去掉/、/*、/**等)
'abc/**' -replace '/\**$','' # abc
```

## 控制语句

```bash
if(1 -eq 2) { echo 1 ; if($?) { echo 11 } } elseif("") { echo 2 } else { echo 3 } # 打印3

# 可配合break、continue
for($i=1; $i -le 10; $i++) { write-host $i } # 打印1-10(带有换行)

$letterArray = "a","b","c","d"
foreach($letter in $letterarray) { write-host $letter } # 打印a-d(带有换行)

while($val -ne 3) { write-host $val; $val++ } # 打印：空(换行)、1(换行)、2(换行)
```
