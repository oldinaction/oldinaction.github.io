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
    - `""` 字符串界定符，其中的变量可正常解析
    - `|` 命令管道符
    - `< > >>` 文件重定向符
    - `@` **命令行回显屏蔽符**，如脚本中`@echo 1`会隐藏命令不显示与屏幕上
    - `/` 参数开关引导符
    - `:` 批处理标签引导符
    - `%` 批处理变量引导符
    - `^` 转义字符 eg: `if 1=1 (echo hello^(你好^)) else (echo bye)`
- `setlocal enabledelayedexpansion` 启用变量延迟模式，变量通过`!myVar!`获取，使用`!xx!`必须开启变量延迟 [^3]
    - 批处理读取命令时是按行读取的（另外例如for命令等，其后用一对圆括号闭合的所有语句也当作一行），在处理之前要完成必要的预处理工作，这其中就包括对该行命令中的变量赋值
        - 如下文案例，批处理在运行到这句“set a=5&echo %a%”之前，先把这一句整句读取并做了预处理——对变量a赋了值，那么%a%当然就是4了
    - 而为了能够感知环境变量的动态变化，批处理设计了变量延迟。简单来说，在读取了一条完整的语句之后，不立即对该行的变量赋值，而会在某个单条语句执行之前再进行赋值，也就是说“延迟”了对变量的赋值

    ```bat
    :: 不开启变量延迟，结果为4，开启之后结果为5
    :: setlocal enabledelayedexpansion
    set a=4 
    set a=5&echo %a%
    ```

### 变量 [^2]

- 设置变量：`set 变量名=变量值`
- 取消变量：`set 变量名=`
- 展示变量：`set 变量名`
- 列出所有可用的变量：`set`
- 计算器：`set /a 表达式`，如`set /a 1+2*3`输出7

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
rem ======================= 示例1 =======================
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


rem ======================= 示例2 =======================
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


rem ======================= 示例3 =======================
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


rem ======================= 示例4 =======================
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
set /p str="请输入数值:"
if !str!@ == @ (set str=我是默认值) else (set str=!str!)
echo !str!
```

#### for语句 [^4]

- `FOR %variable IN (set) DO command [command-parameters]` **在cmd窗口中，for之后的形式变量 i 必须使用单百分号引用，即 %i**；而在批处理文件中，引用形式变量i必须使用双百分号，即 %%i
- for /f (delims、tokens、skip、eol、userbackq、变量延迟)
    - tokens 提取列 
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

### 字符串操作

```bash
# 拼接
echo %a%%b%

# 替换(:=)，可用于去除空格
set str=ab c
echo 替换后为(abc): %str: =%

# 截取(:~,)
set str=123456789
echo 头两个字符为(12): %str:~0,2%
echo 第4个及其之后的3个字符为(4567): %str:~3,4%
echo 去掉最后一个字符后的字符串为(12345678): %str:~0,-1%
```

### 文件和文件夹操作

```bash
# 输出123456至0.txt并覆盖原先文字
echo 123456>0.txt
# 输出123456至0.txt追加至末尾
echo 123456>>0.txt

# 删除文件
del 0.txt
# /F 强制删除. **注意如果带参数，必须是右斜杠，左斜杠会找到不文件**
del /F D:\test\test.txt

# 创建文件夹plugins，需要保证存在目录dist。路径必须使用\斜杠，因为/后面接的参数
mkdir dist\plugins
# 删除文件夹下文件
rmdir dist /s /q

# 复制文件到目录. echo d：防止提示 (F = 文件，D = 目录)?
echo d | xcopy target\sqbiz-plugin\*-ark-biz.jar dist\plugins /s
```

## 常用命令

- 命令参数使用`/`标注，如`help /?`
    - **如果命令参数后是路径，则必须是是右斜杠**(使用左斜杠会找不到路径)，和参数标识符区分
- `help` 查看帮助
- `help /?` 查看help命令的帮助
- `tasklist` 列举进程(进程名太长则可能显示不全)
    - `/fo <table|csv|list>` 显示结果格式。`tasklist /fo csv` 以cvs格式显示结果，可以将进程名显示完全
- `taskkill`
    - `taskkill /pid -f 10021`
    - `-t` 结束该进程 
    - `-f` 强制结束该进程以及所有子进程
    - `/im` 指定要终止的进程的图像名，如`taskkill /F /IM notepad.exe`

## 结合VBS

- 参考[vbs.md](/_posts/lang/vbs.md)
- bat优缺点
    - 如本身没有延时函数，无法执行telnet等命令到达期望效果，此时可使用vbs
    - 但是如移动、删除文件、复制文件夹、修改注册表等只用vbs就很容易出错，用bat却不怕出错
- bat和vbs互相调用举例

```bash
# bat文件中调用vbs
start c:\test.vbs

# vbs文件中调用bat. 第一个0代表隐藏运行, 第二个true代表执行完dos命令后再执行下一条vbs代码
set wshshell=createobject("script.shell")
wshshell.run "cmd.exe /c echo 1",0,true
wshshell.run "c:\test.bat",0,true
```
- bat传递参数到vbs
    - bat中应该打印1、2、3、4、5，此时传入到vbs后会将3替换成test
    - 参考：http://www.bathome.net/thread-27675-1-1.html

```bat
' 2>nul 3>nul&cls&@echo off
'&for /f %%a in ('cscript -nologo -e:vbscript "%~fs0" 1 2 3 4 5') do echo;%%a
'&pause&exit

for i=0 to WSH.Arguments.Count-1
    s=s&replace(WSH.Arguments(i),"3","test")&vbCrLf
Next
WSH.Echo s
```

## 执行telnet命令案例

```bat
title=install-plugins
echo off
%~d0
set SQBIZ_PROJECT_HOME=%~p0
set HOST=localhost
set PORT=1234
set install_jxc=biz -i file:///%SQBIZ_PROJECT_HOME%/plugins/sqbiz-sqbiz-jxc-0.0.1-ark-biz.jar
cd %SQBIZ_PROJECT_HOME%
echo on
@del %SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
rem 产生临时文件 install-plugins-temp.vbs，下面都是往临时文件中写代码
@echo on error resume next >>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo dim WshShell>>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo Set WshShell = WScript.CreateObject("WScript.Shell")>>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WshShell.run "cmd">>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
rem vbs代码：激活此窗口
@echo WshShell.AppActivate "c:\windows\system32\cmd.exe">>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WScript.Sleep 200>>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
rem vbs代码：在当前窗口模拟键盘操作，存在中英文输入法无法切换的问题
@echo WshShell.SendKeys "telnet %HOST% %PORT%">>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
rem vbs代码：在当前窗口模拟键盘操作，回车
@echo WshShell.SendKeys "{ENTER}">>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WScript.Sleep 100>>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WshShell.AppActivate "telnet.exe">>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WScript.Sleep 2000>>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WshShell.SendKeys "%install_jxc%">>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WshShell.SendKeys "{ENTER}">>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
@echo WScript.Sleep 1000>>%SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
rem 执行 vbs
@call %SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
rem 删除临时文件
@del %SQBIZ_PROJECT_HOME%\install-plugins-temp.vbs
echo off
```

## 常用脚本

### 零散(如java程序控制)

- 运行java

    ```bat
    title=cmd窗口的标题
    @echo off
    rem 我的注释：`%~d0`挂载项目到第一个驱动器，并设置当前目录为项目根目录
    %~d0
    set MY_PROJECT_HOME=%~p0
    cd %MY_PROJECT_HOME%
    "%JAVA_HOME%\bin\java" -DLog4j22.formatMsgNoLookups=true -jar my.jar
    @pause
    ```

    - 此时配置文件应和jar包位于同一目录
    - 如果`set MY_PROJECT_HOME=%~p0..\`则表示设置bat文件所在目录的的上级目录为项目根目录
    - 如果不是系统默认jdk，可将`%JAVA_HOME%`换成对应的路径
- 停止进程(此脚本停止java等进程不是很友好，netstat查询出的端口可能很多)

    ```bat
    @echo off
    ::chcp 65001
    set port=8080
    for /f "tokens=5" %%i in ('netstat -aon ^| findstr ":%port%"') do (set n=%%i)
    if "%n%" neq "" (
        taskkill /pid %n% -F
    ) else (echo proc not running...)
    ```
- 停止java进程

    ```bat
    REM 复制一个java.exe到项目jar包目录，并重名为java-test.exe，每个启动的jar必须拥有唯一的名称
    REM 启动jar则使用 java-test.exe -jar test.jar
    REM 停止进程
    taskkill /f /im java-test.exe
    ```
- 后台运行bat文件
    - bat语法运行。缺点：执行`start xxx.exe`后，bat脚本窗口关闭了，但是exe执行程序弹框无法关闭（可使用RunHiddenConsole.exe）
        
        ```bat
        @echo off
        if "%1" == "h" goto begin
        mshta vbscript:createobject("wscript.shell").run("%~nx0 h",0)(window.close)&&exit 
        :begin
        :: 这是注释，后面运行脚本，如：
        java -jar my.jar
        ```
    - 使用`RunHiddenConsole.exe`。需要将其加入到PATH或放在bat的同级目录，如下示例。[RunHiddenConsole下载地址](http://redmine.lighttpd.net/attachments/download/660/RunHiddenConsole.zip)
        ```bat
        :: 启动脚本 start_php_cgi.bat(直接执行php-cgi.exe默认监听端口是9000)
        @echo off
        echo Starting PHP FastCGI...
        RunHiddenConsole.exe d:\software\xampp\php\php-cgi.exe -b 127.0.0.1:19000 -c d:\software\xampp\php\php.ini
        ```
    - 启动示例

        ```bat
        @echo off

        setlocal

        if exist start.bat goto ok
        echo start.bat must be run from its folder
        goto end

        :ok

        :: start /b 启动应用程序时不必打开新的命令提示符窗口。除非应用程序启用 CTRL+C，否则将忽略 CTRL+C 操作。使用 CTRL+BREAK 中断应用程序
        :: CTRL+BREAK按键. 键位标识PS：PrtSc SysRq，SL：Scroll Lock，PB：Pause Break
        start /b bin\test.exe >> log\console.log 2>&1 &

        echo start successfully

        :end
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

    ```bash
    # :: %date% => 2022/09/25 周日 %time% => 10:05:55.19
    # set YYYYMMDD=%date:~0,4%%date:~5,2%%date:~8,2%
    # :: 如果小于10点，小时是一个空格+点数，后面通过字符串替换掉空格
    # set hhmmss=%time:~0,2%%time:~3,2%%time:~6,2%
    set DATETIME=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
    set DATETIME=%DATETIME: =0%
    set "filename=bak_%DATETIME%.zip"
    # :: bak_20181016170530.zip
    echo %filename%
    ```
- 脚本示例
    - 进入到当前目录、设置环境变量
        - `%~dp0` %0代表批处理本身；~dp是变量扩充，d扩充到分区，p扩充到路径
        
        ```bat
        rem 设置临时环境变量oracle_home为当前bat文件所在目录(%~dp0)下的Oracle64目录
        set oracle_home=%~dp0\Oracle64
        rem 进入到当前目录
        %~d0
        cd %~dp0
        rem 运行exe文件
        start plsqlDev.exe
        ```

### oracle工具箱脚本

```bat
:: ========================================
:: 创建表空间、创建用户、导入导出dmp数据
:: author: smalle
:: time: 2018-6-29
:: ========================================
:: 关闭命令显示,否则所有命令都会显示执行结果
@echo off
title=Oracle工具箱

:: 测试代码START(最终需要注释掉)
:test
set serverip=192.168.17.50
set database=orcl
set user=CRMADM rem 管理员用户
set password=CRMADM
:: 测试代码END


:: main方法
:main
set tmpFile=__oracle_data_imp__.sql

:: 开启变量延迟模式(变量通过`!myVar!`获取. bat是一行一行读取命令的，if的括号算做一行，所有容易出现变量赋值获取不到的情况)
setlocal enabledelayedexpansion
:: %tmpFile%是普通获取变量值的方式
if exist %tmpFile% echo Error: 已存在文件%tmpFile% & goto end

:: 死循环，等待用户输入功能菜单，执行相应方法
for /l %%a in () do call:menu

:: 跳转到exit标签(退出程序前处理)
goto exit

::=====================方法=====================
:: 函数以`:函数名`开头，以`goto:eof`结尾
:: 功能菜单
:menu
set menuCode=
echo ### 请选择需执行的命令：
echo 	1.创建表空间和新用户
echo 	2.数据导出(exp)
echo 	3.数据导入(imp)
echo 	4.重设oracle连接(conninfo)
echo 	5.连接oracle(connection)
echo 	6.打印oracle连接信息(info)
echo 	0.退出(exit)
:: 获取用户输入并设值给变量
set /p menuCode=请输入上述功能序号(eg: 6):
:: 给用户输入设置默认值
if !menuCode!@ == @ (
	echo 请选择执行命令...
	:: 提前返回
	goto:eof
	:: 设置默认值
	::set menuCode=6
) else (set menuCode=!menuCode!)

:: 根据输入的编号，调用menuCode_*方法
call:menuCode_!menuCode!
:: 防止方法穿透(防止继续执行下面的代码)
goto:eof

:: 定义获取连接数据信息函数connectInfo
:connectInfo
:: 判断是否存在此变量
if DEFINED serverip (
	echo ---------当前数据库连接信息: serverip=%serverip% database=!database! user=%user% password=%password%
) else (
	set /p serverip="请输入oracle服务器IP(eg: 192.168.17.50):"
	set /p database="请输入实例名(eg: orcl):"
	set /p user="请输入用户名(eg: SCOTT):"
	set /p password="请输入密码(eg: tiger):"
	
	:: 变量延迟获取变量!serverip!, else()算作一行进行命令读取的
	echo ---------当前数据库连接信息: serverip=!serverip! database=!database! user=!user! password=!password!
)
goto:eof

:: 创建表空间和用户(保存sql命令到临时文件, 然后命令行执行sql文件)
:menuCode_1
call:connectInfo

set /p datafile="表空间数据完整存储路径(数据库服务器路径. eg: d:/tablespace/aezocn):"
rem if exist %datafile% echo Error: 不存在文件%datafile% & goto createTablespace
set /p tablespaceName="表空间名称(eg: aezocn):"
echo create tablespace %tablespaceName% datafile '%datafile%' size 200m extent management local segment space management auto; > %tmpFile%

set /p newUser="新用户用户名(大写. eg: SMALLE):"
set /p newPass="新用户密码(区分大小写. eg: smalle):"
echo create user %newUser% identified by %newPass% default tablespace %tablespaceName%; >> %tmpFile%
echo grant create session to %newUser%; >> %tmpFile%
echo grant unlimited tablespace to %newUser%; >> %tmpFile%
echo grant dba to %newUser%; >> %tmpFile%

sqlplus !user!/!password!@!serverip!/!database! @ %tmpFile%
goto:eof

:: 导出数据
:menuCode_2
call:connectInfo

set YYYYmmdd=%date:~0,4%%date:~5,2%%date:~8,2%
set /p expDataFile="导出数据文件保存完整路径(本地路径. eg: d:/exp.dmp):"
if !expDataFile!@ == @ (
	set expDataFile=d:/%YYYYmmdd%.dmp
) else (set expDataFile=!expDataFile!)

set /p owner="导出哪个用户的数据？(大写. eg: SCOTT):"

exp !user!/!password!@!serverip!/!database! file=!expDataFile! owner=!owner!
goto:eof

:: 导入数据
:menuCode_3
set serverip=
call:connectInfo

set /p impDataFile="导入数据文件完整路径(运行此脚本文件机器路径. eg: d:/exp.dmp):"
if !impDataFile!@ == @ (
	set impDataFile=!expDataFile!
) else (set impDataFile=!impDataFile!)

set /p fromuser="从哪个用户导出数据(一般为上述dmp数据中所属用户)？(大写. eg: SCOTT):"
if !fromuser!@ == @ (
	set fromuser=!owner!
) else (set fromuser=!fromuser!)

set /p touser="数据导入给哪用户(如新表空间用户)？(大写. eg: SMALLE):"
if !touser!@ == @ (
	set touser=!touser!
) else (set touser=!newUser!)

if !serverip!@ == @ (
	imp !newUser!/!newPass! file=!impDataFile! fromuser=!fromuser! touser=!touser! ignore=y
) else (
	imp !newUser!/!newPass!@!serverip!/!database! file=!impDataFile! fromuser=!fromuser! touser=!touser! ignore=y
)
goto:eof

:: 重设oracle连接信息
:menuCode_4
set serverip=
call:connectInfo
goto:eof

:: 连接oracle
:menuCode_5
call:connectInfo
sqlplus !user!/!password!@!serverip!/!database!
goto:eof

:: 打印oracle连接信息
:menuCode_6
call:connectInfo
goto:eof

:: 退出
:menuCode_0
if exist %tmpFile% (del %tmpFile%)
@echo on

::退出程序
@cmd /k
::pause
```

### mysql数据库备份

- 设置定时任务参考[windows.md#任务计划(定时任务)](/_posts/extend/windows.md#任务计划定时任务)

```bat
@echo off
set db_user=root
set db_passwd=root
set db_name=db_test
set db_host=127.0.0.1
set db_port=3306
set backup_dir=D:\backup\mysql

:: set BACKUPDATE=%date:~0,4%%date:~5,2%%date:~8,2%0%time:~1,1%%time:~3,2%%time:~6,2%
set BACKUPDATE=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
set BACKUPDATE=%BACKUPDATE: =0%

:: 执行备份(mysqldump命令路径有空格，必须加双引号)
"C:/Program Files/MySQL/MySQL Server 5.7/bin/mysqldump" -h %db_host% -P %db_port% -u%db_user% -p%db_passwd% %db_name% > %backup_dir%/backup_%db_name%_%BACKUPDATE%.sql
:: 压缩
"C:/software/7-Zip/7z.exe" a "%backup_dir%/backup_%db_name%_%BACKUPDATE%.sql.zip" "%backup_dir%/backup_%db_name%_%BACKUPDATE%.sql"
:: 删除当前备份临时文件
del /F "%backup_dir%\backup_%db_name%_%BACKUPDATE%.sql"
:: 删除最后将7天前的文件
forfiles /p %backup_dir% /s /m *.zip /d -7 /c "cmd /c del @path && echo %BACKUPDATE% delete @file success!" > %backup_dir%\mysql_delete_backup_%date:~0,4%.log
@echo on
```

### oracle数据库备份

- 设置定时任务参考[windows.md#任务计划(定时任务)](/_posts/extend/windows.md#任务计划定时任务)

```bat
@echo off
set USER=admin
set PASSWORD=admin123
set BACK_USER=test
set BACK_USER2=demo
set DATABASE=localhost:1521/orcl
set BACKUP_DIR=D:\backup\oracle

set BACKUPDATE=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
set BACKUPDATE=%BACKUPDATE: =0%
if not exist %BACKUP_DIR% mkdir %BACKUP_DIR%

:: 备份
exp %USER%/%PASSWORD%@%DATABASE% file=%BACKUP_DIR%/backup_%BACK_USER%_%BACKUPDATE%.dmp owner=(%BACK_USER%) log=%backup_dir%/backup_%BACK_USER%_%BACKUPDATE%.log compress=y grants=y
"C:/software/7-Zip/7z.exe" a "%BACKUP_DIR%/backup_%BACK_USER%_%BACKUPDATE%.dmp.zip" "%BACKUP_DIR%/backup_%BACK_USER%_%BACKUPDATE%.dmp"
del /F "%BACKUP_DIR%\backup_%BACK_USER%_%BACKUPDATE%.dmp"

exp %USER%/%PASSWORD%@%DATABASE% file=%BACKUP_DIR%/backup_%BACK_USER2%_%BACKUPDATE%.dmp owner=(%BACK_USER2%) log=%backup_dir%/backup_%BACK_USER2%_%BACKUPDATE%.log compress=y grants=y
"C:/software/7-Zip/7z.exe" a "%BACKUP_DIR%/backup_%BACK_USER2%_%BACKUPDATE%.dmp.zip" "%BACKUP_DIR%/backup_%BACK_USER2%_%BACKUPDATE%.dmp"
del /F "%BACKUP_DIR%\backup_%BACK_USER2%_%BACKUPDATE%.dmp"

:: 删除超过7天的备份文件
forfiles /p "%BACKUP_DIR%" /s /m *.dmp.zip /d -7 /c "cmd /c del @path && echo %BACKUPDATE% delete @file success!" > %backup_dir%\oracle_delete_backup_%date:~0,4%.log
forfiles /p "%BACKUP_DIR%" /s /m backup_*.log /d -7 /c "cmd /c del @path && echo %BACKUPDATE% delete @file success!" > %backup_dir%\oracle_delete_backup_%date:~0,4%.log
@echo on
```







---

参考文章

[^1]: http://blog.csdn.net/wh_19910525/article/details/8125762 (注释)
[^2]: https://blog.csdn.net/fw0124/article/details/39996265 (变量)
[^3]: http://www.360doc.com/content/15/0123/16/44521_443121050.shtml (变量延迟)
[^4]: https://www.cnblogs.com/DswCnblog/p/5435300.html (批处理-For详解)
