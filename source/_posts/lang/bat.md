---
layout: "post"
title: "bat脚本"
date: "2017-05-10 15:26"
categories: [lang]
tags: [windows]
---

## 语法

> https://www.cnblogs.com/DswCnblog/category/820715.html

### 关键字

- `::`、`rem`等为注释 [^1]
- `title=我的标题` 设置cmd窗口标题(乱码时，需要将文件记事本打开另保存为ANSI)
- `echo [message]` 表示显示此命令后的字符
- `echo on/off` 表示在此语句后所有运行的命令都是否显示命令行本身(`@echo off`关闭命令显示)
- `pause` 运行此句会暂停批处理的执行并在屏幕上显示Press any key to continue...的提示，等待用户按任意键后继续
- `call [drive:][path]filename [batch-parameters]` 调用另一个批处理文件（如果不用call而直接调用别的批处理文件，那么执行完那个批处理文件后将无法返回当前文件并执行当前文件的后续命令）
- `%[1-9]` 表示参数，`%0`表示批处理命令本身
- `exit` 关闭窗口
- 符号
    - `+` COPY命令文件连接符 
    - `* ?` 文件通配符 
    - `""` 字符串界定符 
    - `|` 命令管道符 
    - `< > >>` 文件重定向符 
    - `@` 命令行回显屏蔽符 
    - `/` 参数开关引导符 
    - `:` 批处理标签引导符 
    - `%` 批处理变量引导符 
    - `^` 转义字符 eg: `if 1=1 (echo hello^(你好^)) else (echo bye)`
- `setlocal enabledelayedexpansion` 启用变量延迟模式，变量通过`!myVar!`获取 (bat是一行一行读取命令的，if的括号算做一行，所有容易出现变量赋值获取不到的情况) [^3]

### 变量 [^2]

设置变量：`set 变量名=变量值`
取消变量：`set 变量名=`
展示变量：`set 变量名`
列出所有可用的变量：`set`
计算器：`set /a 表达式`，如`set /a 1+2*3`输出7

### 控制语句

#### if语句
    - `if [not] string1 == string2` 
    - `if [not] %errorlevel% == 0` 如果最后运行的程序返回一个等于或大于指定数字的退出编码则返回true
        - `%errorlevel%` 这是个系统变量，返回上条命令的执行结果代码。`0`表示成功，`1-255`表示失败
    - `if [not] exist filename` 如果指定的文件名存在
    - `if [/i] string1 compare-op string2`
        - 参数`/i`表示不区分大小写
        - compare-op
            - `equ` 等于
            - `neq` 不等于
            - `lss` 小于
            - `leq` 小于或等于
            - `gtr` 大于
            - `geq` 大于或等于
    - `if defined variable` 判断变量是否存在

```bat
rem 示例1

@echo off
if 1==1 goto myEnd

:myEnd
echo AAA
pause

set /p var1="请输入一个字符串："
set /p var2="请输入一个字符串："
if "%var1%" == "Y" (echo yes) else (echo please input Y) ::此处%var1%需要用引号包裹
if %var1% == %var2% (echo var1 eque var2) else (echo var1 not eque var2)
if NOT %var1% == %var2% (echo var1 not eque var2) else (echo var1 eque var2)

set a=10
if DEFINED a (echo l hava define) else (echo l don't define)
:: 注销变量a(变量值为空，则为未定义；变量值不为空，则为已定义)
set a=
if DEFINED a (echo l hava define) else (echo l don't define)

set /p var=请输入一个数字:
if %var% LEQ  4 (echo 我小于等于4) else echo 我不小于等于4
pause


rem 示例2

@echo off
copy C:\abc.bat E:\
if %ERRORLEVEl% == 0 (
    echo operation succ %ERRORLEVEl%
) else (
    echo operation fail %ERRORLEVEl%
)
pause
@echo off
set /p var=随便输入一个命令
%var%
echo errorlevel is %ERRORLEVEL%
if NOT %ERRORLEVEL% == 0 (
　　echo !var!执行失败
) else (
　　echo !var!执行成功
)
pause

rem 示例3

@echo off
set file="C:\abc.bat"
if exist %file% (　　　　　　　　
　　echo file is exists
) else if exist b.txt (
    echo b.txt is exists
) else ( 　　　　　　　　　　	　　 
　　echo file is not exists
)
pause

rem 示例4

:: 开启延迟变量
setlocal enabledelayedexpansion
set var=before
if "%var%" == "before" (
    :: before
    echo %var%
    set var=after
    :: before
    echo %var%
    :: after
    echo !var!
    if "!var!" == "after" @echo 可以打印
)

:: 给用户输入设置默认值
set /p str="请输入盘符:"
if !str!@ == @ (set str=d) else (set str=!str!)
echo !str!
```

#### for语句 [^4]

- `FOR %variable IN (set) DO command [command-parameters]` 在cmd窗口中，for之后的形式变量 i 必须使用单百分号引用，即 %i；而在批处理文件中，引用形式变量i必须使用双百分号，即 %%i
- for /f (delims、tokens、skip、eol、userbackq、变量延迟)
- for /r (递归遍历)
- for /d (遍历目录)
- for /l (计数循环)

```bat
:: 显示C盘根目录下所有非隐藏、非系统属性文件
:: cmd窗口
for %i in (c:\*.*) do echo %i
:: 批处理
for %%i in (c:\*.*) do echo %%i

:: 循环创建名称为1-5的文件夹
rem in后面的三项参数从左至右的三位分别是初始值、步数、终止点，当用户给定的数量不足时，将按从右至左的顺序把不足的一项赋为0
for /l %%a in (1,1,5) do md %%a
```

### 函数 

- 定义：函数以`:函数名`开头，以`goto:eof`结尾
- 调用：`call:函数名 [参数1,参数2,…]`

```bat
:myFuncName
echo ...

SETLOCAL  
set a="这是局部变量作用域(SETLOCAL-ENDLOCAL)"
ENDLOCAL
goto:eof

call:myFuncName
```

### 文件和文件夹操作

- `echo 123456>0.txt` 输出123456至0.txt并覆盖原先文字
- `echo 123456>>0.txt` 输出123456至0.txt追加至末尾
- `del 0.txt` 删除文件

## 常用脚本

- 运行java

    ```bat
    title=cmd窗口的标题
    echo off
    rem 我的注释：`%~d0`挂载项目到第一个驱动器，并设置当前目录为项目根目录
    %~d0
    set MY_PROJECT_HOME=%~p0
    cd %MY_PROJECT_HOME%
    echo on
    "%JAVA_HOME%\bin\java" -jar my.jar
    echo off
    ```

    - 此时配置文件应和jar包位于同一目录
    - 如果`set MY_PROJECT_HOME=%~p0..\`则表示设置bat文件所在目录的的上级目录为项目根目录
    - 如果不是系统默认jdk，可将`%JAVA_HOME%`换成对应的路径

- 后台运行bat文件

```bat
@echo off
if "%1" == "back" goto begin
mshta vbscript:createobject("wscript.shell").run("%~nx0 h",0)(window.close)&&exit
:begin
:: 这是注释，后面运行脚本，如：
java -jar my.jar
```
- 获取脚本参数。`test.bat`内容如下。运行`test a.txt b.txt`则%1表示a.txt，%2表示b.txt 

```bat
@echo off
type %1
type %2
```
- 获取键盘输入

```bat
@echo off
:: 后面的语句也可不加双引号
set /p QQ="Input you QQ number ......"
echo Your QQ number is %QQ%.
:: 取消变量QQ的定义
set QQ=
pause
````
- 获取当前时间

```bat
set YYYYmmdd=%date:~0,4%%date:~5,2%%date:~8,2%
set hhmiss=%time:~0,2%%time:~3,2%%time:~6,2%
set "filename=bak_%YYYYmmdd%_%hhmiss%.zip"
:: bak_20181016_170530.zip
echo %filename%
```
- 脚本示例
    - 进入到当前目录、设置环境变量
        - `%~dp0` %0代表批处理本身； ~dp是变量扩充， d扩充到分区，p扩充到路径
        
    ```bat
    rem 设置临时环境变量oracle_home为当前bat文件所在目录(%~dp0)下的Oracle64目录
    set oracle_home=%~dp0\Oracle64
    rem 进入到当前目录
    %~d0
    cd %~dp0
    rem 运行exe文件
    start plsqlDev.exe
    ```


---

参考文章

[^1]: http://blog.csdn.net/wh_19910525/article/details/8125762 (注释)
[^2]: https://blog.csdn.net/fw0124/article/details/39996265 (变量)
[^3]: http://www.360doc.com/content/15/0123/16/44521_443121050.shtml (变量延迟)
[^4]: https://www.cnblogs.com/DswCnblog/p/5435300.html (批处理-For详解)