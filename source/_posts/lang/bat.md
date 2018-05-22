---
layout: "post"
title: "windows"
date: "2017-05-10 15:26"
categories: [extend]
tags: [bat]
---

## bat脚本

### 语法

- 注释：`::`、`rem`等 [^1]
- `title`: 设置cmd窗口标题(乱码时，需要将文件记事本打开另保存为ANSI)

### 常用脚本

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
    if "%1" == "h" goto begin
    mshta vbscript:createobject("wscript.shell").run("%~nx0 h",0)(window.close)&&exit
    :begin
    :: 这是注释，后面运行脚本，如：
    java -jar my.jar
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

## 草稿

常用命令 

echo、@、call、pause、rem(小技巧：用::代替rem)是批处理文件最常用的几个命令，我们就从他们开始学起。 

==== 注 =========== 
首先, @ 不是一个命令, 而是DOS 批处理的一个特殊标记符, 仅用于屏蔽命令行回显. 下面是DOS命令行或批处理中可能会见到的一些特殊标记符: 
CR(0D) 命令行结束符 
Escape(1B) ANSI转义字符引导符 
Space(20) 常用的参数界定符 
Tab(09) ; = 不常用的参数界定符 
+ COPY命令文件连接符 
* ? 文件通配符 
"" 字符串界定符 
| 命令管道符 
< > >> 文件重定向符 
@ 命令行回显屏蔽符 
/ 参数开关引导符 
: 批处理标签引导符 
% 批处理变量引导符 

其次, :: 确实可以起到rem 的注释作用, 而且更简洁有效; 但有两点需要注意: 
第一, 除了 :: 之外, 任何以 :开头的字符行, 在批处理中都被视作标号, 而直接忽略其后的所有内容, 只是为了与正常的标号相区别, 建议使用 goto 所无法识别的标号, 即在 :后紧跟一个非字母数字的一个特殊符号. 
第二, 与rem 不同的是, ::后的字符行在执行时不会回显, 无论是否用echo on打开命令行回显状态, 因为命令解释器不认为他是一个有效的命令行, 就此点来看, rem 在某些场合下将比 :: 更为适用; 另外, rem 可以用于 config.sys 文件中. 
===================== 

echo 表示显示此命令后的字符 
echo off 表示在此语句后所有运行的命令都不显示命令行本身 
@与echo off相象，但它是加在每个命令行的最前面，表示运行时不显示这一行的命令行（只能影响当前行）。 
call 调用另一个批处理文件（如果不用call而直接调用别的批处理文件，那么执行完那个批处理文件后将无法返回当前文件并执行当前文件的后续命令）。 
pause 运行此句会暂停批处理的执行并在屏幕上显示Press any key to continue...的提示，等待用户按任意键后继续 
rem 表示此命令后的字符为解释行（注释），不执行，只是给自己今后参考用的（相当于程序中的注释）。 
==== 注 ===== 
此处的描述较为混乱, 不如直接引用个命令的命令行帮助更为条理 

------------------------- 
ECHO 

当程序运行时，显示或隐藏批处理程序中的正文。也可用于允许或禁止命令的回显。 

在运行批处理程序时，MS-DOS一般在屏幕上显示（回显）批处理程序中的命令。 
使用ECHO命令可关闭此功能。 

语法 

ECHO [ON|OFF] 

若要用echo命令显示一条命令，可用下述语法： 

echo [message] 

参数 

ON|OFF 
指定是否允许命令的回显。若要显示当前的ECHO的设置，可使用不带参数的ECHO 
命令。 

message 
指定让MS-DOS在屏幕上显示的正文。 

------------------- 

CALL 

从一个批处理程序中调用另一个批处理程序，而不会引起第一个批处理的中止。 

语法 

CALL [drive:][path]filename [batch-parameters] 

参数 

[drive:][path]filename 
指定要调用的批处理程序的名字及其存放处。文件名必须用.BAT作扩展名。 


batch-parameters 
指定批处理程序所需的命令行信息。 

------------------------------- 

PAUSE 

暂停批处理程序的执行并显示一条消息，提示用户按任意键继续执行。只能在批处 
理程序中使用该命令。 

语法 

PAUSE 


REM 

在批处理文件或CONFIG.SYS中加入注解。也可用REM命令来屏蔽命令（在CONFIG.SYS 
中也可以用分号 ; 代替REM命令，但在批处理文件中则不能替代）。 

语法 

REM [string] 

参数 

string 
指定要屏蔽的命令或要包含的注解。 
======================= 

例1：用edit编辑a.bat文件，输入下列内容后存盘为c:\a.bat，执行该批处理文件后可实现：将根目录中所有文件写入 a.txt中，启动UCDOS，进入WPS等功能。 

　　批处理文件的内容为: 　　　　　　　 命令注释： 

　　　　@echo off　　　　　　　　　　　不显示后续命令行及当前命令行 
　　　　dir c:\*.* >a.txt　　　　　　　将c盘文件列表写入a.txt 
　　　　call c:\ucdos\ucdos.bat　　　　调用ucdos 
　　　　echo 你好 　　　　　　　　　　 显示"你好" 
　　　　pause 　　　　　　　　　　　　 暂停,等待按键继续 
　　　　rem 准备运行wps 　　　　　　　 注释：准备运行wps 
　　　　cd ucdos　　　　　　　　　　　 进入ucdos目录 
　　　　wps 　　　　　　　　　　　　　 运行wps　　 

批处理文件的参数 

批处理文件还可以像C语言的函数一样使用参数（相当于DOS命令的命令行参数），这需要用到一个参数表示符"%"。 

%[1-9]表示参数，参数是指在运行批处理文件时在文件名后加的以空格（或者Tab）分隔的字符串。变量可以从%0到%9，%0表示批处理命令本身，其它参数字符串用%1到%9顺序表示。 

例2：C:根目录下有一批处理文件名为f.bat，内容为： 
@echo off 
format %1 

如果执行C:\>f a: 
那么在执行f.bat时，%1就表示a:，这样format %1就相当于format a:，于是上面的命令运行时实际执行的是format a: 

例3：C:根目录下一批处理文件名为t.bat，内容为: 
@echo off 
type %1 
type %2 

那么运行C:\>t a.txt b.txt 
%1 : 表示a.txt 
%2 : 表示b.txt 
于是上面的命令将顺序地显示a.txt和b.txt文件的内容。 

==== 注 =============== 
参数在批处理中也作为变量处理, 所以同样使用百分号作为引导符, 其后跟0-9中的一个数字构成参数引用符. 引用符和参数之间 (例如上文中的 %1 与 a: ) 的关系类似于变量指针与变量值的关系. 当我们要引用第十一个或更多个参数时, 就必须移动DOS 的参数起始指针. shift 命令正充当了这个移动指针的角色, 它将参数的起始指针移动到下一个参数, 类似C 语言中的指针操作. 图示如下: 

初始状态, cmd 为命令名, 可以用 %0 引用 
cmd arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10 
^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
| | | | | | | | | | 
%0 %1 %2 %3 %4 %5 %6 %7 %8 %9 

经过1次shift后, cmd 将无法被引用 
cmd arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10 
^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
| | | | | | | | | | 
%0 %1 %2 %3 %4 %5 %6 %7 %8 %9 

经过2次shift后, arg1也被废弃, %9指向为空, 没有引用意义 
cmd arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10 
^ ^ ^ ^ ^ ^ ^ ^ ^ 
| | | | | | | | | 
%0 %1 %2 %3 %4 %5 %6 %7 %8 

遗憾的是, win9x 和DOS下均不支持 shift 的逆操作. 只有在 nt 内核命令行环境下, shift 才支持 /n 参数, 可以以第一参数为基准返复移动起始指针. 
================= 

特殊命令 


if goto choice for是批处理文件中比较高级的命令，如果这几个你用得很熟练，你就是批处理文件的专家啦。 


一、if 是条件语句，用来判断是否符合规定的条件，从而决定执行不同的命令。 有三种格式: 

1、if [not] "参数" == "字符串" 待执行的命令 

参数如果等于(not表示不等，下同)指定的字符串，则条件成立，运行命令，否则运行下一句。 

例：if "%1"=="a" format a: 

==== 

if 的命令行帮助中关于此点的描述为: 
IF [NOT] string1==string2 command 
在此有以下几点需要注意: 
1. 包含字符串的双引号不是语法所必须的, 而只是习惯上使用的一种"防空"字符 
2. string1 未必是参数, 它也可以是环境变量, 循环变量以及其他字符串常量或变量 
3. command 不是语法所必须的, string2 后跟一个空格就可以构成一个有效的命令行 
============================= 

2、if [not] exist [路径\]文件名 待执行的命令 
如果有指定的文件，则条件成立，运行命令，否则运行下一句。 

如: if exist c:\config.sys type c:\config.sys 
表示如果存在c:\config.sys文件，则显示它的内容。 

****** 注 ******** 
也可以使用以下的用法: 
if exist command 
device 是指DOS系统中已加载的设备, 在win98下通常有: 
AUX, PRN, CON, NUL 
COM1, COM2, COM3, COM4 
LPT1, LPT2, LPT3, LPT4 
XMSXXXX0, EMMXXXX0 
A: B: C: ..., 
CLOCK$, CONFIG$, DblBuff$, IFS$HLP$ 
具体的内容会因硬软件环境的不同而略有差异, 使用这些设备名称时, 需要保证以下三点: 
1. 该设备确实存在(由软件虚拟的设备除外) 
2. 该设备驱动程序已加载(aux, prn等标准设备由系统缺省定义) 
3. 该设备已准备好(主要是指a: b: ..., com1..., lpt1...等) 
可通过命令 mem/d | find "device" /i 来检阅你的系统中所加载的设备 
另外, 在DOS系统中, 设备也被认为是一种特殊的文件, 而文件也可以称作字符设备; 因为设备(device)与文件都是使用句柄(handle)来管理的, 句柄就是名字, 类似于文件名, 只不过句柄不是应用于磁盘管理, 而是应用于内存管理而已, 所谓设备加载也即指在内存中为其分配可引用的句柄. 
================================== 

3、if errorlevel <数字> 待执行的命令 

很多DOS程序在运行结束后会返回一个数字值用来表示程序运行的结果(或者状态)，通过if errorlevel命令可以判断程序的返回值，根据不同的返回值来决定执行不同的命令(返回值必须按照从大到小的顺序排列)。如果返回值等于指定的数字，则条件成立，运行命令，否则运行下一句。 

如if errorlevel 2 goto x2 

==== 注 =========== 
返回值从大到小的顺序排列不是必须的, 而只是执行命令为 goto 时的习惯用法, 当使用 set 作为执行命令时, 通常会从小到大顺序排列, 比如需将返回码置入环境变量, 就需使用以下的顺序形式: 

if errorlevel 1 set el=1 
if errorlevel 2 set el=2 
if errorlevel 3 set el=3 
if errorlevel 4 set el=4 
if errorlevel 5 set el=5 
... 

当然, 也可以使用以下循环来替代, 原理是一致的: 
for %%e in (1 2 3 4 5 6 7 8...) do if errorlevel %%e set el=%%e 

更高效简洁的用法, 可以参考我写的另一篇关于获取 errorlevel 的文章 

出现此种现象的原因是, if errorlevel 比较返回码的判断条件并非等于, 而是大于等于. 由于 goto 的跳转特性, 由小到大排序会导致在较小的返回码处就跳出; 而由于 set命令的 "重复" 赋值特性, 由大到小排序会导致较小的返回码 "覆盖" 较大的返回码. 

另外, 虽然 if errorlevel=<数字> command 也是有效的命令行, 但也只是 command.com 解释命令行时将 = 作为命令行切分符而忽略掉罢了 
=========================== 
二、goto 批处理文件运行到这里将跳到goto所指定的标号(标号即label，标号用:后跟标准字符串来定义)处，goto语句一般与if配合使用，根据不同的条件来执行不同的命令组。 

如: 

goto end 

:end 
echo this is the end 

标号用":字符串"来定义，标号所在行不被执行。 

====  编注 

label 常被译为 "标签" , 但是这并不具有广泛的约定性. 

goto 与 : 联用可实现执行中途的跳转, 再结合 if 可实现执行过程的条件分支, 多个 if 即可实现命令的分组, 类似 C 中 switch case 结构或者 Basic 中的 select case 结构, 大规模且结构化的命令分组即可实现高级语言中的函数功能. 以下是批处理和C/Basic在语法结构上的对照: 

Batch C / Basic 
goto&: goto&: 
goto&:&if if{}&else{} / if&elseif&endif 
goto&:&if... switch&case / select case 
goto&:&if&set&envar... function() / function(),sub() 
================================== 
三、choice 使用此命令可以让用户输入一个字符（用于选择），从而根据用户的选择返回不同的errorlevel，然后于if errorlevel配合，根据用户的选择运行不同的命令。 

注意：choice命令为DOS或者Windows系统提供的外部命令，不同版本的choice命令语法会稍有不同，请用choice /?查看用法。 

choice的命令语法（该语法为Windows 2003中choice命令的语法，其它版本的choice的命令语法与此大同小异）： 

CHOICE [/C choices] [/N] [/CS] [/T timeout /D choice] [/M text] 

描述: 
该工具允许用户从选择列表选择一个项目并返回所选项目的索引。 

参数列表: 
/C choices 指定要创建的选项列表。默认列表是 "YN"。 

/N 在提示符中隐藏选项列表。提示前面的消息得到显示， 
选项依旧处于启用状态。 

/CS 允许选择分大小写的选项。在默认情况下，这个工具 
是不分大小写的。 

/T timeout 做出默认选择之前，暂停的秒数。可接受的值是从 0 
到 9999。如果指定了 0，就不会有暂停，默认选项 
会得到选择。 

/D choice 在 nnnn 秒之后指定默认选项。字符必须在用 /C 选 
项指定的一组选择中; 同时，必须用 /T 指定 nnnn。 

/M text 指定提示之前要显示的消息。如果没有指定，工具只 
显示提示。 

/? 显示帮助消息。 

注意: 
ERRORLEVEL 环境变量被设置为从选择集选择的键索引。列出的第一个选 
择返回 1，第二个选择返回 2，等等。如果用户按的键不是有效的选择， 
该工具会发出警告响声。如果该工具检测到错误状态，它会返回 255 的 
ERRORLEVEL 值。如果用户按 Ctrl+Break 或 Ctrl+C 键，该工具会返回 0 
的 ERRORLEVEL 值。在一个批程序中使用 ERRORLEVEL 参数时，将参数降 
序排列。 

示例: 
CHOICE /? 
CHOICE /C YNC /M "确认请按 Y，否请按 N，或者取消请按 C。" 
CHOICE /T 10 /C ync /CS /D y 
CHOICE /C ab /M "选项 1 请选择 a，选项 2 请选择 b。" 
CHOICE /C ab /N /M "选项 1 请选择 a，选项 2 请选择 b。" 

==== 编注 =============================== 
我列出win98下choice的用法帮助, 已资区分 

Waits for the user to choose one of a set of choices. 
等待用户选择一组待选字符中的一个 


CHOICE [/C[:]choices] [/N] [/S] [/T[:]c,nn] [text] 

/C[:]choices Specifies allowable keys. Default is YN 
指定允许的按键(待选字符), 默认为YN 
/N Do not display choices and ? at end of prompt string. 
不显示提示字符串中的问号和待选字符 
/S Treat choice keys as case sensitive. 
处理待选字符时大小写敏感 
/T[:]c,nn Default choice to c after nn seconds 
在 nn 秒后默认选择 c 
text Prompt string to display 
要显示的提示字符串 
ERRORLEVEL is set to offset of key user presses in choices. 
ERRORLEVEL 被设置为用户键入的字符在待选字符中的偏移值 
如果我运行命令：CHOICE /C YNC /M "确认请按 Y，否请按 N，或者取消请按 C。" 
屏幕上会显示： 
确认请按 Y，否请按 N，或者取消请按 C。 [Y,N,C]? 


例：test.bat的内容如下（注意，用if errorlevel判断返回值时，要按返回值从高到低排列）: 

@echo off 
choice /C dme /M "defrag,mem,end" 
if errorlevel 3 goto end 
if errorlevel 2 goto mem 
if errorlevel 1 goto defrag 

:defrag 
c:\dos\defrag 
goto end 

:mem 
mem 
goto end 

:end 
echo good bye

此批处理运行后，将显示"defrag,mem,end[D,M,E]?" ，用户可选择d m e ，然后if语句根据用户的选择作出判断，d表示执行标号为defrag的程序段，m表示执行标号为mem的程序段，e表示执行标号为end的程序段，每个程序段最后都以goto end将程序跳到end标号处，然后程序将显示good bye，批处理运行结束。 

四、for 循环命令，只要条件符合，它将多次执行同一命令。 

语法： 
对一组文件中的每一个文件执行某个特定命令。 

FOR %%variable IN (set) DO command [command-parameters] 

%%variable 指定一个单一字母可替换的参数。 
(set) 指定一个或一组文件。可以使用通配符。 
command 指定对每个文件执行的命令。 
command-parameters 
为特定命令指定参数或命令行开关。 

例如一个批处理文件中有一行: 
for %%c in (*.bat *.txt) do type %%c 

则该命令行会显示当前目录下所有以bat和txt为扩展名的文件的内容。 

==== 编注 ===========================================
需要指出的是, 当()中的字符串并非单个或多个文件名时, 它将单纯被当作字符串替换, 这个特性再加上()中可以嵌入多个字符串的特性, 很明显 for 可以被看作一种遍历型循环. 
当然, 在 nt/2000/xp/2003 系列的命令行环境中, for 被赋予了更多的特性, 使之可以分析命令输出或者文件中的字符串, 也有很多开关被用于扩展了文件替换功能. 
=======================================================
批处理示例 

1. IF-EXIST 

1) 首先用记事本在C:\建立一个test1.bat批处理文件，文件内容如下： 

@echo off 
IF EXIST \AUTOEXEC.BAT TYPE \AUTOEXEC.BAT 
IF NOT EXIST \AUTOEXEC.BAT ECHO \AUTOEXEC.BAT does not exist
 

然后运行它： 
C:\>TEST1.BAT 

如果C:\存在AUTOEXEC.BAT文件，那么它的内容就会被显示出来，如果不存在，批处理就会提示你该文件不存在。 

2) 接着再建立一个test2.bat文件，内容如下： 

@ECHO OFF 
IF EXIST \%1 TYPE \%1 
IF NOT EXIST \%1 ECHO \%1 does not exist
 
执行: 
C:\>TEST2 AUTOEXEC.BAT 
该命令运行结果同上。 

说明： 
(1) IF EXIST 是用来测试文件是否存在的，格式为 
IF EXIST [路径+文件名] 命令 
(2) test2.bat文件中的%1是参数，DOS允许传递9个批参数信息给批处理文件，分别为%1~%9(%0表示test2命令本身) ，这有点象编程中的实参和形参的关系，%1是形参，AUTOEXEC.BAT是实参。 

==== willsort 编注 ===========================================
DOS没有 "允许传递9个批参数信息" 的限制, 参数的个数只会受到命令行长度和所调用命令处理能力的限制. 但是, 我们在批处理程序中, 在同一时刻只能同时引用10个参数, 因为 DOS只给出了 %0~%9这十个参数引用符. 
=======================================================
3) 更进一步的，建立一个名为TEST3.BAT的文件，内容如下： 

@echo off 
IF "%1" == "A" ECHO XIAO 
IF "%2" == "B" ECHO TIAN 
IF "%3" == "C" ECHO XIN 

如果运行： 
C:\>TEST3 A B C 
屏幕上会显示: 
XIAO 
TIAN 
XIN 

如果运行： 
C:\>TEST3 A B 
屏幕上会显示 
XIAO 
TIAN 

在这个命令执行过程中，DOS会将一个空字符串指定给参数%3。 

2、IF-ERRORLEVEL 
建立TEST4.BAT，内容如下： 

@ECHO OFF 
XCOPY C:\AUTOEXEC.BAT D:\ 
IF ERRORLEVEL 1 ECHO 文件拷贝失败 
IF ERRORLEVEL 0 ECHO 成功拷贝文件
 
然后执行文件: 
C:\>TEST4 

如果文件拷贝成功，屏幕就会显示"成功拷贝文件"，否则就会显示"文件拷贝失败"。 

IF ERRORLEVEL 是用来测试它的上一个DOS命令的返回值的，注意只是上一个命令的返回值，而且返回值必须依照从大到小次序顺序判断。 
因此下面的批处理文件是错误的： 

@ECHO OFF 
XCOPY C:\AUTOEXEC.BAT D:\ 
IF ERRORLEVEL 0 ECHO 成功拷贝文件 
IF ERRORLEVEL 1 ECHO 未找到拷贝文件 
IF ERRORLEVEL 2 ECHO 用户通过ctrl-c中止拷贝操作 
IF ERRORLEVEL 3 ECHO 预置错误阻止文件拷贝操作 
IF ERRORLEVEL 4 ECHO 拷贝过程中写盘错误 

无论拷贝是否成功，后面的： 

未找到拷贝文件 
用户通过ctrl-c中止拷贝操作 
预置错误阻止文件拷贝操作 
拷贝过程中写盘错误 

都将显示出来。 

以下就是几个常用命令的返回值及其代表的意义： 

backup 
0 备份成功 
1 未找到备份文件 
2 文件共享冲突阻止备份完成 
3 用户用ctrl-c中止备份 
4 由于致命的错误使备份操作中止 

diskcomp 
0 盘比较相同 
1 盘比较不同 
2 用户通过ctrl-c中止比较操作 
3 由于致命的错误使比较操作中止 
4 预置错误中止比较 

diskcopy 
0 盘拷贝操作成功 
1 非致命盘读/写错 
2 用户通过ctrl-c结束拷贝操作 
3 因致命的处理错误使盘拷贝中止 
4 预置错误阻止拷贝操作 

format 
0 格式化成功 
3 用户通过ctrl-c中止格式化处理 
4 因致命的处理错误使格式化中止 
5 在提示"proceed with format（y/n）?"下用户键入n结束 

xcopy 
0 成功拷贝文件 
1 未找到拷贝文件 
2 用户通过ctrl-c中止拷贝操作 
4 预置错误阻止文件拷贝操作 
5 拷贝过程中写盘错误 

chkdsk 
0 未找到错误 
255 找到一个或多个错误 

choice 
0 用户按下ctrl+c/break 
1 用户按下第一个键 
255 检测到命令行中的错误条件 
其它 用户按下的有效字符在列表中的位置 

defrag 
0 碎片压缩成功 
1 出现内部错误 
2 磁盘上没有空簇。要运行DEFRAG，至少要有一个空簇 
3 用户用Ctrl+C退出了DEFRAG 
4 出现一般性错误 
5 DEFRAG在读簇时遇到错误 
6 DEFRAG在写簇时遇到错误 
7 分配空间有错 
8 内存错 
9 没有足够空间来压缩磁盘碎片 

deltree 
0 成功地删除一个目录 

diskcomp 
0 两盘相同 
1 发现不同 
2 按CTRL+C 终止了比较 
3 出现严重错误 
4 出现初始化错误 

find 
0 查找成功且至少找到了一个匹配的字符串 
1 查找成功但没找到匹配的字符串 
2 查找中出现了错误 

keyb 
0 键盘定义文件装入成功 
1 使用了非法的键盘代码，字符集或语法 
2 键盘定义文件坏或未找到 
4 键盘、监视器通讯时出错 
5 要求的字符集未准备好 

move 
0 成功地移动了指定的文件 
1 发生了错误 

msav /N 
86 检查到了病毒 

replace 
0 REPLACE成功地替换或加入了文件 
1 MS-DOS版本和REPLACE不兼容 
2 REPLACE找不到源文件 
3 REPLACE找不到源路径或目标路径 
5 不能存取要替换的文件 
8 内存不够无法执行REPLACE 
11 命令行句法错误 

restore 
0 RESTORE成功地恢复了文件 
1 RESTORE找不到要恢复的文件 
3 用户按CTRL+C终止恢复过程 
4 RESTORE因错误而终止 

scandisk 
0 ScanDisk在它检查的驱动器上未检测到任何错误 
1 由于命令行的语法不对，不能运行ScanDisk 
2 由于内存用尽或发生内部错误，ScanDisk意外终止 
3 用户让ScanDisk中途退出 
4 进行盘面扫描时，用户决定提前退出 
254 ScanDisk找到磁盘故障并已全部校正 
255 ScanDisk找到磁盘故障，但未能全部校正 

setver 
0 SETVER成功地完成了任务 
1 用户指定了一个无效的命令开关 
2 用户指定了一个非法的文件名 
3 没有足够的系统内存来运行命令 
4 用户指定了一个非法的版本号格式 
5 SETVER在版本表中未找到指定的项 
6 SETVER未找到SETVER.EXE文件 
7 用户指定了一个非法的驱动器 
8 用户指定了太多的命令行参数 
9 SETVER检测到丢失了命令行参数 
10 在读SETVER.EXE文件时，SETVER检测到发生错误 
11 SETVER.EXE文件损坏 
12 指定的SETVER.EXE文件不支持版本表 
13 版本表中没有足够的空间存放新的项 
14 在写SETVER.EXE文件时SETVER检测到发生错误 
=======================================================
3、IF STRING1 == STRING2 

建立TEST5.BAT，文件内容如下： 

@echo off 
IF "%1" == "A" FORMAT A:
 
执行： 
C:\>TEST5 A 
屏幕上就出现是否将A:盘格式化的内容。 

注意：为了防止参数为空的情况，一般会将字符串用双引号（或者其它符号，注意不能使用保留符号）括起来。 
如：if [%1]==[A] 或者 if %1*==A* 
5、GOTO 
建立TEST6.BAT，文件内容如下： 

@ECHO OFF 
IF EXIST C:\AUTOEXEC.BAT GOTO _COPY 
GOTO _DONE 
:_COPY 
COPY C:\AUTOEXEC.BAT D:\ 
:_DONE
 

注意： 
(1) 标号前是ASCII字符的冒号":"，冒号与标号之间不能有空格。 
(2) 标号的命名规则与文件名的命名规则相同。 
(3) DOS支持最长八位字符的标号，当无法区别两个标号时，将跳转至最近的一个标号。 
==== willsort 编注 ===========================================
1)标号也称作标签(label) 
2)标签不能以大多数的非字母数字字符开始, 而文件名中则可以使用很多 
3)当无法区别两个标签时, 将跳转至位置最靠前的标签 
=======================================================
6、FOR 

建立C:\TEST7.BAT，文件内容如下： 

@ECHO OFF 
FOR %%C IN (*.BAT *.TXT *.SYS) DO TYPE %%C
 
运行： 
C:\>TEST7 
执行以后，屏幕上会将C:盘根目录下所有以BAT、TXT、SYS为扩展名的文件内容显示出来（不包括隐藏文件）。   




---

参考文章

[^1]: [注释](http://blog.csdn.net/wh_19910525/article/details/8125762)

