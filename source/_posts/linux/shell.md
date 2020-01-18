---
layout: "post"
title: "Shell编程"
date: "2017-01-10 13:19"
categories: linux
tags: [shell, linux, lang]
---

## 简介

- shell是解释性语言，解释器如`bash`、`sh`
- [Shell教程](http://c.biancheng.net/cpp/shell/)

## 基本语法

### 基本概念

- 程序有两类返回值：执行结果、执行状态(即 **`$?`** 的值，`0` 表示正确，`1-255` 错误)

### 特殊符号

-  linux 引号
    - 反引号：**\`cmd\`** 命令替换，类似`$(cmd)`
    - 双引号: **""** 变量替换
    - 单引号：**''** 字符串
- 命令替换：使用 **\`cmd\`**(反引号)包裹或 **$(cmd)**(美元括号)
    - `wall `date`` 所有人都收到当前时间
    - `wall date` 所有人都收到date这个字符串
- 管道符`|`
    - 将一个命令的输出传送给另外一个命令，作为另外一个命令的输入。如：`命令1|命令2|...|命令n`
    - 使用管道符连接的左右两边的命令都是运行在子shell中，存在变量无法传递的问题
    - 示例
        - `ls -Rl /etc | more` 分页显示/etc目录
        - `cat /etc/passwd | grep root` 查询root用户帐号信息
        - `ls -l * | grep "^_" | wc -l` 统计当前目录有多少个文件
- 重定向：将命令的结果重定向到某个地方
    - `>`、`>>`　输出重定向(`>`覆盖，`>>`追加)
        - `ls > ls.txt` 将ls的输出保存到ls.txt中
        - `>` 如果文件不存在，就创建文件；如果文件存在，就将其清空。`>>` 如果文件不存在，就创建文件；如果文件存在，则将新的内容追加到那个文件的末尾
        - `2>` 错误重定向，如：`lsss　2> ls.txt`
        - `&>` 全部重定向：`ls &> /dev/null` 将结果全部传给数据黑洞
    - `<`、`<<` 输入重定向
        - `wall < notice.txt` 将notice.txt中的数据发送给所有登录人
    - 标准输入(stdin)代码为 `0`，实际映射关系：/dev/stdin -> /proc/self/fd/0 
    - 标准输出(stdout)代码为 `1`，实际映射关系：/dev/stdout -> /proc/self/fd/1
        - `echo xxx` 将输出放到标准输出中
    - 标准错误输出(stderr)代码为 2 ，实际映射关系： /dev/stderr ->/pro/self/fd/2
- 转义符`\`，或者使用引号

```bash
# 一般特殊符号要出现必须用转义字符：' " * ? \ ~ ` ! # $ & | { } ; < > ^
## 对于特殊字符可使用转义符`\`，或者使用引号
echo 9 * 9 = 81 # 报错
echo 9 '*' 9 = 81 # 9 * 9 = 81
echo '9 * 9 = 81' # 9 * 9 = 81
echo "9 * 9 = 81" # 9 * 9 = 81
echo 9 \* 9 = 81  # 9 * 9 = 81

## 在一对引号中不允许出现单引号，转义字符也不行
# 以下因为第一个引号和第二个引号自动配成一对，最后一个单引号在没得配的情况下，bash认为输入尚未完成，出现>等待命令继续输入
echo 'it is wolf's book' # 进入待输入 > ^C '
echo 'it is wolf\'s book' # 进入待输入 > ^C '
# 解决如下
echo "it is wolf's book"
echo it is wolf\'s book
echo 'it is wolf'\''s book'
```

### 变量

- 变量类型
    - 环境变量(作用于可跨bash)：`export <var_name>=<var_value>`
    - 本地变量(作用于当前bash)：`<var_name>=<var_value>` (**注意：=前后不要有空格**)
    - 局部变量(作用于当前代码段)：`local <var_name>=<var_value>`
    - 位置变量(作用于脚本执行的参数)：`$1` 表示第一个参数，以次类推`$2`、`$3`
    - 特殊变量
        - **`$?`** 上一个命令的执行状态返回值(`0` 表示正确，其他为错误)
        - `$#` 传递到脚本的参数个数
        - `$*` 传递到脚本的参数，与位置变量不同，此选项参数可超过9个
        - `$$` 脚本运行时当前进程的ID号，常用作临时变量的后缀，如 haison.$$
        - `$!` 后台运行的(&)最后一个进程的ID号
        - `$@` 与`$#`相同，使用时加引号，并在引号中返回参数个数
        - `$-` 上一个命令的最后一个参数
        - `$0` 当前Shell程序的文件名(只在脚本文件里才有作用)
            
            ```bash
            # 返回这个脚本文件放置的目录，这个命令写在脚本文件里才有作用。如`dirname /usr/local/bin` 结果为`/usr/local`
            dirname $0
            # 进入当前Shell程序的目录
            cd `dirname $0`
            # 定义当前脚本目录，并执行jar。cd -P表示基于物理路径
            APP_HOME="$(cd -P "$(dirname "$0")" && pwd)"/..
            (cd "$APP_HOME" && java -jar app.jar)
            ```
- `set` 查看shell中变量
- `printenv`/`env` 查看shell中环境变量
- `unset <var_name>` 撤销变量
- 引用变量 `${var_name}`，一般可以省略{}

### 字符串

```bash
## 字符串替换
string=123.abc.234 # 必须基于变量进行替换
echo ${string/12/ab} # 替换一次：ab3.abc.234
echo ${string//23/bc} # 双斜杠替换所有匹配：1bc.abc.bc4
echo ${string/#ab/} # 以什么开头来匹配：123.abc.234(匹配是吧)
echo ${string/%34/df} # %以什么结尾来匹配：123.abc.2df

## 统计单词个数
s='one two three four five'
echo $s | tr ' ' '\n' | wc -l
```

### 运算

```bash
# 使用 $(( ))
echo $(($(date +%Y)-1)) # 获取去年的年份
# 使用expr
expr 4 + 5 # +中间需要有空格
expr 4 \* 5
# 使用 $[]
echo $[ 4 + 5 ]
```

### 函数

- 函数定义、调用、返回

```bash
## test.sh
# 定义函数
func() {
    echo "start"
    echo "hello$1" # $1 获取的是此函数的第一个参数，而不是脚本参数
    return 0 # 函数中使用return返回时，返回值的数据类型必须是数字
}

func ", your name is $1" # 调用函数。$1 获取的是脚本的第一个参数
if [ $? == 0 ] ; then
    echo "func return=$?" # 函数中使用return返回函数值时，通过 echo $? 来捕获函数返回值
    echo $(func $1) # 函数中使用echo返回函数值时，通过 $(func_name arg1 arg2 …) 来捕获函数返回值
fi

## 执行结果
./test.sh smalle # 当传递参数也不会报错，脚本中通过$1获取到一个空字符串
# 打印
start
hello, your name is smalle
func return=0
start hello smalle
```
- 函数结合`xargs`(参考下文)

```bash
## test.sh
exec 2>&1 # 设置重定向
function c() {
    wc -c $1 # 统计文件字节数
}
export -f c
ls | xargs -I{} bash -c 'c {}'
echo ret_code is $?

## 执行
./test.sh
```

### 控制语句

- 控制语句也可在命令行中需要使用

    ```bash
    # if
    [[ "2005 03.01" > "2004 05.23.00" ]] && echo gt || echo lt
    if [ 1 = 2 ]; then echo true; else echo false; fi

    # for
    for file in a.yaml b.yaml ; do wget http://xxx/$file; done
    ```

#### 条件判断

- 条件表达式 `[ expression ]` **注意其中的空格**
    - `[ -z "$pid" ]` 单对中括号变量必须要加双引号，`[[ -z $pid ]]` 双对括号，变量不用加双引号
    - `[[ ]]`内是不能使用 -a 或者 -o 进行比较，`[ ]`内可以
- 条件表达式的逻辑关系
    - **在linux中命令执行状态：0 为真，其他为假**
    - `&&`(第一个表达式为true才会运行第二个)、`||`、`!`
    - `-a` 逻辑与，如：`[ $# -gt 1 –a $# -lt 3 –o $# -eq 2 ]`
    - `-o` 或
- 整数比较
    - `-eq`、`==`   相等，比如：`[ $A -eq  $B ]`
    - `-ne`、`!=`   不等
    - `-gt`、`>`    大于
    - `-lt`、`<`    小于
    - `-ge`         大于等于
    - `-le`         小于等于
- 文件测试(需要中括号)
    - `-e <file>` 测试文件是否存在
    - `-f <file>` 测试文件是否为普通文件
    - `-d <file>` 测试文件(linux是基于文件进行编程的)是否为目录
    - `-r` 权限判断
    - `-w`
    - `-x`
- 字符串测试
    - `==` 或 `=` **等号两端需要空格**
        - 如：`[[ $res == *"yes"* ]]`(通配符判断是否包含)
    - `=~` 正则比较
        - 如：`[[ /bin/bash =~ sh$ ]]`、`[[ "$var" =~ $reg ]]`(`reg='^hello'`其中$reg不能加双引号)
    - `!=`
    - `>`、`<` 字符串大小比较，字符串有空格则不能使用`-gt`
        - 如：`[[ "2005 03.01" > "2004 05.23.00" ]] && echo gt || echo lt` 
    - `-z` 判断变量的值是否为空。为空，返回0，即true
    - `-n` 判断变量的值是否不为空。非空，返回0，即true
    - `-s <string>` 判非空
    - `[[ $str != h* ]]` 判断字符串是否不是以h开头
    - `[[ "$str" =~ ^he.* ]]` 判断字符串是否以he开头
    - `[ "$item" \< /home/smalle/demo/$lastMon ]` 判断字符串小于(需要转义)
- 常用判断
    - `[[ $JAVA_HOME ]]` 判断是否存在此变量/环境变量
    - `[[ -z $JAVA_HOME ]]` 判断此变量是否为空
- 算术运算(其中任意一种即可)
    - `let C=$A+$B` **(=、+附近不能有空格，下同。此时C不能有$，使用变量的使用才需要加$)**
    - `C=$[$A+$B]`
    - `C=$(($A+$B))`
    - C=\`expr $A + $B\` (表达式中各操作数及运算符之间要有空格，而且要使用命令引用)
- 控制结构

```shell
## 控制结构
if 条件表达式 ; then
    语句
elif 条件表达式 ; then
    语句
else
    语句
fi

## 案例
# 判断字符串是否为空
STRING=
if [ -z "$STRING" ]; then
    echo "STRING is empty"
fi
if [ -n "$STRING" ]; then
    echo "STRING is not empty"
fi
```

#### 循环

- 控制结构

    ```shell
    ## for
    for 变量 in 列表 ; do
        语句
    done
    ## 多行时，do后面需要加分号
    for file in a.yaml b.yaml c.yaml  ; do wget https://github.com/test/test/raw/test/$file; done

    ## 计次循环
    for ((i=1; i<=100; i++))
    # for i in {1..100}
    do
        echo $i
    done

    ## while(注意此处和下列的 ; 对比)
    while 条件 ; do
        语句
        [break|continue]
    done

    # while死循环(true可以替换为[ 0 ]或[ 1 ])
    while true
    do
        语句
    done
    ```
- 如何生成列表
	- `{1..100}`
	- `seq [起始数] [跨度数] 结束数` 如：`seq 10`、`seq 1 2 10`
	- `ls /etc 文件列表`

#### case语句

- 控制结构

```shell
case 变量 in
	value1)
		语句
		;;
	value2)
		语句
		;;
	*)
		语句
		;;
esac
```

### 脚本说明

#### 脚本基本使用

- 注意文件格式必须是Unix格式(否则执行报错：`: No such file or directory`)
    - 解决办法：`vim my.sh` - `:set ff=unix` - `:x`
- `#!/bin/bash` 脚本第一行建议以此开头
- `exit` 退出脚本
	- 退出脚本可以指定脚本执行的状态：`exit 0` 成功退出，`exit 1`/`exit 2`/... 失败退出
    - 退出码
        - `0` 成功
        - `2` shell内建命令使用错误
        - `124` 执行命令超时，如`timeout 10 sleep 30`
        - `126` 程序或命令的权限是不可执行的
        - `127` 命令不存在command not found(估计是$PATH不对)
        - `128` exit的参数错误(exit只能以整数作为参数，范围是0-255)
        - `128+n` 信号n的致命错误(kill -9 $PPID，$? 返回137=128 + 9)
        - `130` 用Control-C来结束脚本
        - `255*` 超出范围的退出状态(exit -1)
- 脚本中使用`set -x` 是开启代码执行显示，`set +x`是关闭，`set -o`是查看(xtrace)。执行`set -x`后，对整个脚本有效
- 执行脚本方式

```bash
## 执行命令
# 在当前shell内去读取、执行a.sh，而a.sh不需要有"执行权限"。`source/./exec/eval`命令执行脚本都不会产生子进程
source a.sh
. a.sh # source命令可以简写为"."
# (注意)如果脚本中有`source`命令，则需要使用 source/. 来执行脚本，否则脚本中source命令不会生效

# 都是打开一个subshell去读取、执行a.sh，而a.sh不需要有"执行权限"。通常在subshell里运行的脚本里设置变量，不会影响到父shell的
source /etc/profile # 在一个脚本中使用sh、bash、nohup等运行其他命令或脚本，会开启子shell，因此需要加载一下环境变量，否则可能会出现127找不到命令的问题
sh a.sh
bash a.sh
# 打开一个subshell去读取、执行a.sh，但a.sh需要有"执行权限"(chmod +x a.sh)
./a.sh

## 调试
# 检查文件是否有语法错误(`sh -n`亦可)
bash -n a.sh
# debug 执行文件
bash -x a.sh
```
- 脚本中使用nohup命令

```bash
!#/bin/bash
nohup echo "hello world" # nohup执行命令不生效，原因是找不到环境变量，所以要先source一下

source /etc/profile
nohup echo "hello world"
```
- 远程执行脚本 [^4]
	- 简单执行远程命令：`ssh user@remoteNode "cd /home ; ls"` 双引号必须有，两个命令直接用分号分割
	- 脚本内执行远程命令

```bash
#!/bin/bash
# `> /dev/null 2>&1` 表示远程命令不在本地显示，如果需要显示可以省略
# `<< eeooff`和最后的`eeooff`需要对应，可以换成其他任何标识符，如`<< remotessh`
# 在远程命令的脚本最后需要exit退出远程服务器

set -x
ssh user@remoteNode > /dev/null 2>&1 << eeooff
cd /home
touch abcdefg.txt
exit
eeooff
set +x

echo done!
```

#### 简单示例

- 添加用户：`./test1.sh user1`

```shell
#!/bin/bash
#
# 判断是否有且只有一个传入参数，否则退出(linux返回状态不为0都认为出错)
[ ! $# -eq 1 ] && echo "Args is error." && exit 3
# 判断是否存在某个用户
id $1 &>/dev/null && echo "User $1 exist" && exit 2
# 添加用户
id $1 &>/dev/null || useradd $1
# 如果用户添加成功，将此用户名当作密码传递给标准输出，passwd通过--stdin从标准输出中读取密码进行密码修改
id $1 &>/dev/null &&  echo "$1" | passwd --stdin  $1 &>/dev/null
echo "Add user $1 success."
# 统计系统用户数(或者`wc -l /etc/passwd | cut -d' ' -f1`)
COUNT=`wc -l /etc/passwd | awk '{print $1}'`
echo "Total Users is $COUNT"
```

- 获取某目录下最大的文件：`./test2.sh /home/smalle`

```shell
#!/bin/bash

# 必须传入一个参数，其值为目录
if [ -f $1 ];then
  echo "Arg is error."
  exit 2
fi

if [ -d $1 ];then
  # 查看目录下所有文件大小，并降序排列，再统计个数
  c=`du -a $1 | sort -nr | wc -l`
  # seq $c为一个序列 
  for I in `seq $c`;do
    # 降序排列，并显示前几行(head -$I)，再过滤出最后一行(tail -1)
    f_size=`du -a $1 | sort -nr | head -$I | tail -1 | awk '{print $1}'`
    f_path=`du -a $1 | sort -nr | head -$I | tail -1 | awk '{print $2}'`
    if [ -f $f_path ];then
      # 如果是文件则停止循环(du也会统计根目录)
      echo -e "the biggest file is $f_path \t $f_size"
      break
    fi
  done
fi
```

#### 接受参数

##### POSIX 和 GUN 规范

- POSIX(可移植操作系统接口)
    - 以一个横杠开头的为选项，选项名是单字符的英文字母或者数字
    - 如果不带参数的话，多个选项可以写在一个横杠后面，如 `-abc` 与 `-a -b -c` 的含义相同
    - 如果带参数的话，选项和它的参数既可以分开写也可以在一起，grep选项中的 `-A 10` 与 `-A10` 都是合乎规范的
        - 如果选项接受的参数有多个值，那么程序应该将参数作为一个字符串接收进来，字符串中的这些值用逗号或空白符分隔开
    - 选项参数写在非选项参数之前
    - 特殊参数 `--` 指明所有参数都结束了。命令行中后面的任何参数都被认为是操作数，即使它们以 `-` 开始
    - 同一参数可以重复出现，一般程序应该这么却解析：当一个选项覆盖其他选项的设置时，那么最后一个选项起作用。如果带参数的选项出现重复，那么程序应该按顺序处理这些选项参数。例如 `myprog -u arnold -u jane` 和 `myprog -u "arnold,jane"` 应该被解释为相同
- GNU(自由的操作系统)
    - GNU鼓励使用`--help`、`--verbose`等形式的长选项。这些选项不仅不与POSIX约定冲突，而且容易记忆
    - 选项参数与长选项之间或通过空白字符或通过一个`=`来分隔

##### 常见参数如

```bash
# [-?hvVtTq] 表示接受 -? -h -v等参数
# -s signal表示 -s 后面需要再接一个参数
Usage: nginx [-?hvVtTq] [-s signal] [-c filename] [-p prefix] [-g directives]

Options:
  -?,-h         : this help
  -v            : show version and exit
  -V            : show version and configure options then exit
  -t            : test configuration and exit
  -T            : test configuration, dump it and exit
  -q            : suppress non-error messages during configuration testing
  -s signal     : send signal to a master process: stop, quit, reopen, reload
  -p prefix     : set prefix path (default: /etc/nginx/)
  -c filename   : set configuration file (default: /etc/nginx/nginx.conf)
  -g directives : set global directives out of configuration file
```

##### 顺序参数

- 如`./test.sh 1 2` 执行下面脚本

	```bash
	#!/bin/bash

	# test.sh
	echo "脚本$0" # test.sh
	echo "第一个参数$1" # 1
	echo "第二个参数$2" # 2
	# 超过10个的参数需要使用${10}, ${11}来接收
	```
	- 示例
	
		```bash
		start() {
			echo 'start...'
		}

		stop() {
			echo 'stop...'
		}

		case "$1" in
			'start')
			  	start
				;;
			'stop')
			  	stop
				;;
			*)
        echo "[info] Usage: $0 {start|stop}"
        exit 1
		esac
		exit $?
		```

##### getopt 与 getopts 

- getopts 接收命令行选项和参数。语法：`getopts OptionString Name [ Argument ...]`
- OptionString 选项名称，Name选项值变量
- 一个字符是一个选项，如个某字符`:`表示选项后面有传值。当getopts命令发现冒号后，会从命令行该选项后读取该值。如该值存在，将保存在特殊的变量OPTARG中
- 每次调用 getopts 命令时，它将下一个选项的值放置在 Name 内，并将下一个要处理的参数的索引置于 shell 变量 OPTIND 中。每当调用 shell 时，都会将 OPTIND 初始化为 1
- 当OptionString用`:`开头，getopts会区分invalid option错误(Name值会被设成`?`)和miss option argument错误(Name会被设成`:`)；否则出现错误，Name都会被设成`?`
- getopts示例(b.sh) [^3]

```bash
#!/bin/bash
echo 初始 OPTIND: $OPTIND
    
while getopts "a:b:c" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        a)
            echo "a's arg:$OPTARG" #参数存在$OPTARG中
            ;;
        b)
            echo "b's arg:$OPTARG"
            ;;
        c)
            echo "c's arg:$OPTARG"
            ;;
        ?)  #当有不认识的选项的时候arg为?
            echo "unkonw argument"
            exit 1
        ;;
    esac
done
    
echo 处理完参数后的 OPTIND：$OPTIND
echo 移除已处理参数个数：$((OPTIND-1))
shift $((OPTIND-1)) # 上一条命令 $((OPTIND-1)) 对参数位置进行了修改，此时shift可以回置参数位置
echo 参数索引位置：$OPTIND
echo 准备处理余下的参数：
echo "Other Params: $@"
```
- getopts示例结果

```html
<!-- bash b.sh -a 1 -b 2 -c 3 test -oo xx -test -->
初始 OPTIND: 1
a's arg:1
b's arg:2
c's arg:
<!-- 处理`-a 1 -b 2 -c 3 test -oo xx -test`，可以解析到`-c`，相当于移动5次，此时OPTIND=5+1 -->
处理完参数后的 OPTIND：6
移除已处理参数个数：5
参数索引位置：6
准备处理余下的参数：
Other Params: 3 test -oo xx -test

<!-- bash b.sh -a 1 -c 3 -b 2 test -oo xx -test # 非参数选项注意顺序与值，不要多传 -->
初始 OPTIND: 1
a's arg:1
c's arg:
<!-- 处理`-a 1 -c 3 -b 2 test -oo xx -test`，可以解析到`-c`，相当于移动3次，此时OPTIND=3+1. 当解析到3的时候发现无法解析，则不再往后解析，全部归到其他参数 -->
处理完参数后的 OPTIND：4
移除已处理参数个数：3
参数索引位置：4
准备处理余下的参数：
Other Params: 3 -b 2 test -oo xx -test

<!-- bash b.sh -a 1 -c -b 2 test -oo xx -test -->
初始 OPTIND: 1
a's arg:1
c's arg:
b's arg:2
处理完参数后的 OPTIND：6
移除已处理参数个数：5
参数索引位置：6
准备处理余下的参数：
Other Params: test -oo xx -test
```
- getopt示例

```bash
#!/bin/bash

# -o: 表示短选项，一个冒号表示该选项有一个参数；两个冒号表示该选项有一个可选参数，可选参数必须紧贴选项，如-carg 而不能是-c arg
# --long: 表示长选项
# -n: 出错时的信息
# --: 用途举例，创建一个名字为 "-f"的目录，当`mkdir -f`时不成功，因为-f会被mkdir当作选项来解析; 这时就可以使用 `mkdir -- -f` 这样-f就不会被作为选项。
# $@: 从命令行取出参数列表(不能用用 $* 代替，因为 $* 将所有的参数解释成一个字符串，而 $@ 是一个参数数组)
TEMP=`getopt -o ab:c:: --long a-long,b-long:,c-long:: \
    -n "$0" -- "$@"`
    
# 上面一条命令执行出错则退出程序
if [ $? != 0 ] ; then echo "Error..." >&2 ; usage ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
#set 会重新排列参数的顺序，也就是改变$1,$2...$n的值，这些值在getopt中重新排列过了。所有不包含选项的命令行参数都排到最后
eval set -- "$TEMP"
    
function usage() {
    echo "Usage: $0 {-a|--a-long} {-b|--b-long} {-c|--c-long}" ; 
    exit 1 ;
}

# 如果一个参数都没有则则执行
if [ -z $2 ] ; then echo "None-argument..." ; usage ; exit 1 ; fi

#经过getopt的处理，下面处理具体选项。
while true ; do
case "$1" in
# `shift ;` 相当于 `shift 1 ;`，即将OPTIND回置1位
# 如 `run.sh -a -b 2`
# 第一次循环：$1=-a $2=-b $3=2, 匹配到`-a`，此时`shift ;`回置1位
# 第二次循环：$1=-b $2=2，匹配到`-b`
-a|--a-long) echo "Option a" ; shift ;;
# 将OPTIND回置2位，因为b参数名和b的参数值占命令行2位。-b为必填项，如果不填写则执行getopt命令时会报错
-b|--b-long) echo "Option b, argument \`$2\`" ; shift 2 ;;
-c|--c-long)
    # c has an optional argument. As we are in quoted mode,
    # an empty parameter will be generated if its optional
    # argument is not found.
    case "$2" in
    "") echo "Option c, no argument"; shift 2 ;;
    *)  echo "Option c, argument \`$2\`" ; shift 2 ;;
    esac ;;
# break 停止循环
--) shift ; break ;;
*) echo "Internal error!" ; exit 1 ;;
esac
done

# $@为getopt表达式解析提取后剩余的其他参数数组
echo "Remaining arguments:"
for arg in $@ 
do
echo '--> '"\`$arg\`" ;
done

exit $?
```
- getopt示例结果

```bash
# ./run.sh
None-argument...
Usage: ./run.sh {-a|--a-long} {-b|--b-long} {-c|--c-long}

# ./run.sh 123
Remaining arguments:
--> `123`

# ./run.sh --
None-argument...
Usage: ./run.sh {-a|--a-long} {-b|--b-long} {-c|--c-long}

# ./run.sh -- 123 456
Remaining arguments:
--> `123`
--> `456`

# ./run.sh -a --b-long 2
Option a
Option b, argument `2`
Remaining arguments:

# ./run.sh -a -b 2 -c3 # 可选参数必须紧跟选项
Option a
Option b, argument `2`
Option c, argument `3`
Remaining arguments:

# ./run.sh -a -b 2 -c 3
Option a
Option b, argument `2`
Option c, no argument
Remaining arguments:
--> `3`

# ./run.sh -a 1 --b-long 2
Option a
Option b, argument `2`
Remaining arguments:
--> `1`

# ./run.sh -a -b 2 -c3 -- 4 5
Option a
Option b, argument `2`
Option c, argument `3`
Remaining arguments:
--> `4`
--> `5`
```

#### 多行输入

```bash
# EOF之间的数据覆盖/home/smalle/test文件；如果需要追加则为 `cat >> /home/smalle/test << EOF...EOF`
cat > /home/smalle/test << EOF
# 注释
sleep 1
ehco hello...
EOF

# EOF中有特殊符号，使用 "EOF" 进行转义
cat > /home/smalle/test << "EOF"
echo $test
# echo \$test # 此方法也可转义
EOF
```

### functions模块

- 位于`/etc/rc.d/init.d/functions`文件中
- 在shell脚本中引用只需加入`. /etc/rc.d/init.d/functions`即可

#### 方法介绍

- `killproc` 杀死进程

## linux命令

- linux三剑客grep、sed、awk语法

### grep过滤器

- 语法

    ```bash
    grep [-acinv] [--color=auto] '搜寻字符串' filename
    # filename不能缺失

    # 选项与参数：
    # -v **反向选择**，亦即显示出没有 '搜寻字符串' 内容的那一行
    # -R/-r 递归查询子目录
    # -i 忽略大小写的不同，所以大小写视为相同
    # -l 显示文件名
    # -E 以 egrep 模式匹配
    # -P 应用正则表达式
    # -n 顺便输出行号
    # -c 计算找到 '搜寻字符串' 的次数
    # --color=auto 可以将找到的关键词部分加上颜色的显示喔；--color=none去掉颜色显示
    # -a 将 binary 文件以 text 文件的方式搜寻数据
    ```
- [grep正则表达式](https://www.cnblogs.com/terryjin/p/5167789.html)
- 常见用法

    ```bash
    grep "search content" filename1 filename2.... filenamen # 在多个文件中查找数据(查询文件内容)
    grep 'search content' *.sql # 查找已`.sql`结尾的文件
    grep -R 'test' /data/* # 在/data目录及其字母查询
    grep hello -rl * # 查询当前目录极其子目录文件(-r)，并只输出文件名(-l)

    grep -5 'parttern' filename # 打印匹配行的前后5行。或 `grep -C 5 'parttern' filename`
    grep -A 5 'parttern' filename # 打印匹配行的后5行
    grep -B 5 'parttern' filename # 打印匹配行的前5行

    grep -E 'A|B' filename # 打印匹配 A 或 B 的数据
    echo office365 | grep -P '\d+' -o # 返回 365
    grep 'A' filename | grep 'B' # 打印匹配 A 且 B 的数据
    grep -v 'A' filename # 打印不包含 A 的数据

    # 根据日志查询最近执行命令时间(结合tail -1)
    grep 'cmd-hostory' /var/log/local1-info.log | tail -1 | awk '{print $1,$2}'
    ```
- grep结果单独处理

    ```bash
    # 方式一
    ps -ewo pid,etime,cmd | grep ofbiz.jar | grep -v grep | while read -r pid etime cmd ; do echo "===>$pid $cmd $etime"; done;

    # 方式二
    while read -r proc; do
        echo '====>' $proc
    done <<< "$(ps -ef | grep ofbiz.jar | grep -v grep)"
    ```

### sed行编辑器

- 文本处理，默认不编辑原文件，仅对模式空间中的数据做处理；而后处理结束后将模式空间打印至屏幕
- 语法 `sed [options] '内部命令表达式' file ...`
- 参数
    - `-n` 静默模式，不再默认显示模式空间中的内容
	- `-i` **直接修改原文件**(默认只输出结果。可以先不加此参数进行修改预览)
	- `-e script -e script` 可以同时执行多个脚本
	- `-f`：如`sed -f /path/to/scripts file`
	- `-r` 表示使用扩展正则表达式
- 内部命令
    - 内部命令表达式如果含有变量可以使用双引号，单引号无法解析变量
	- **`s/pattern/string/修饰符`** 查找并替换
        - 默认只替换每行中第一次被模式匹配到的字符串；修饰符`g`全局替换；`i`忽略字符大小写；**其中/可为其他分割符，如`#`、`@`等，也可通过右斜杠转义分隔符**
        - `sed "s/foo/bar/g" test.md` 替换每一行中的"foo"都换成"bar"(加-i直接修改源文件)
        - `sed 's#/data#/data/harbor#g' docker-compose.yml` 修改所有"/data"为"/data/harbor"
	- `d` 删除符合条件的行
	- `p` 显示符合条件的行
	- `a \string`: 在指定的行后面追加新行，内容为string
		- `\n` 可以用于换行
	- `i \string`: 在指定的行前面添加新行，内容为string
	- `r <file>` 将指定的文件的内容添加至符合条件的行处
	- `w <file>` 将地址指定的范围内的行另存至指定的文件中
	- `&` 引用模式匹配整个串
- 示例

    ```bash
    # 删除/etc/grub.conf文件中行首的空白符
    sed -r 's@^[[:space:]]+@@g' /etc/grub.conf
    # 替换/etc/inittab文件中"id:3:initdefault:"一行中的数字为5
    sed 's@\(id:\)[0-9]\(:initdefault:\)@\15\2@g' /etc/inittab
    # 删除/etc/inittab文件中的空白行(此时会返回修改后的数据，但是原始文件中的内容并不会被修改)
    sed '/^$/d' /etc/inittab
    # 加上参数`-i`会直接修改原文件(去掉文件中所有空行)
    sed -i -e '/^$/d' /home/smalle/test.txt
    # 修改当前目录极其子目录下所有文件
    sed "s/zhangsan/lisi/g" `grep zhangsan -rl *`

    # s表示替换，\1表示用第一个括号里面的内容替换整个字符串。sed支持*，不支持?、+，不能用\d之类，正则支持有限
    echo here365test | sed 's/.*ere\([0-9]*\).*/\1/g' # 365
    ```
    - [其他示例](https://github.com/lutaoact/script/blob/master/sed%E5%8D%95%E8%A1%8C%E8%84%9A%E6%9C%AC.txt)

### awk文本分析工具

- 相对于grep的查找，sed的编辑，awk在其对数据分析并生成报告时，显得尤为强大。**简单来说awk就是把文件逐行的读入，以空格/tab为默认分隔符将每行切片，切开的部分再进行各种分析处理(每一行都会执行一次awk主命令)**
- 语法 

    ```bash
    awk '[BEGIN {}] {pattern + action} [END {}]' {filenames}
    # pattern 表示AWK在文件中查找的内容。pattern就是要表示的正则表达式，用斜杠(`'/xxx/'`)括起来
    # action 是在找到匹配内容时所执行的一系列命令(awk主命令)
    # 花括号(`{}`)不需要在程序中始终出现，但它们用于根据特定的模式对一系列指令进行分组

    ## awk --help
    Usage: awk [POSIX or GNU style options] -f progfile [--] file ...
    Usage: awk [POSIX or GNU style options] [--] 'program' file ...
    POSIX options:		GNU long options: (standard)
    -f progfile		--file=progfile         # 指定程序文件
    -F fs			--field-separator=fs    # 指定域分割符(可使用正则，如 `-F '[\t \\\\]'`)
    -v var=val		--assign=var=val
    # ...
    ```
- awk中同时提供了`print`和`printf`两种打印输出的函数
    - `print` 参数可以是变量、数值或者字符串。**字符串必须用双引号引用，参数用逗号分隔。**如果没有逗号，参数就串联在一起而无法区分。
    - `printf` 其用法和c语言中printf基本相似，可以格式化字符串，输出复杂时
- 案例

```bash
# 显示最近登录的5个帐号。读入有'\n'换行符分割的一条记录，然后将记录按指定的域分隔符划分域(填充域)。**$0则表示所有域, $1表示第一个域**，$n表示第n个域。默认域分隔符是空格/tab，所以$1表示登录用户，$3表示登录用户ip，以此类推
last -n 5 | awk '{print $1}'
last -n 5 | awk '{print $1,$2}' # print多个变量用逗号分割，显示默认带有空格

# 只是显示/etc/passwd中的账户。`-F`指定域分隔符为`:`，默认是空格/tab
cat /etc/passwd | awk -F ':' '{print $1}'

# 查找root开头的用户记录
awk -F : '/^root/' /etc/passwd
```

#### 变量

- `$0`变量是指整条记录，`$1`表示当前行的第一个域，`$2`表示当前行的第二个域，以此类推
- awk内置变量：awk有许多内置变量用来设置环境信息，这些变量可以被改变，下面给出了最常用的一些变量
    - `ARGC` 命令行参数个数
    - `ARGV` 命令行参数排列
    - `ENVIRON` 支持队列中系统环境变量的使用
    - `FILENAME` awk浏览的文件名
    - `FNR` 浏览文件的记录数
    - `FS` 设置输入域分隔符，等价于命令行-F选项
    - `NF` 浏览记录的域的个数
    - `NR` 已读的记录数
    - `OFS` 输出域分隔符
    - `ORS` 输出记录分隔符(`\n`)
    - `RS` 控制记录分隔符
- 自定义变量
    - 下面统计/etc/passwd的账户人数

        ```bash
        awk '{count++;print $0;} END {print "user count is ", count}' /etc/passwd
        # 打印如下
        # root:x:0:0:root:/root:/bin/bash
        # ......
        # user count is 40
        ```
        - count是自定义变量。之前的action{}里都是只有一个print，其实print只是一个语句，而action{}可以有多个语句，以;号隔开。这里没有初始化count，虽然默认是0，但是妥当的做法还是初始化为0
- awk与shell之间的变量传递方法
    - awk中使用shell中的变量

        ```bash
        # 获取普通变量(第一个双引号为了转义单引号，第二个双引号为了转义变量中的空格)
        var="hello world" && awk 'BEGIN{print "'"$var"'"}'
        # 把系统变量var传递给了awk变量awk_var
        var="hello world" && awk -v awk_var="$var" 'BEGIN {print awk_var}'

        # 获取环境变量(ENVIRON)
        var="hello world" && export var && awk 'BEGIN{print ENVIRON["var"]}'
        ```
    - awk向shell变量传递值

        ```bash
        eval $(awk 'BEGIN{print "var1='"'str 1'"';var2='"'str 2'"'"}') && echo "var1=$var1 ----- var2=$var2" # var1=str1 ----- var2=str2
        # 读取temp_file中数据设置到变量中(temp_file中输入`hello world:test`，如果文件中有多行，则最后一行会覆盖原来的赋值)
        eval $(awk '{printf("var3=%s; var4=%s;",$1,$2)}' temp_file) && echo "var3=$var3 ----- var4=$var4" # var3=hello ----- var4=world:test
        ```

#### BEGIN/END

- 提供`BEGIN/END`语句(必须大写)
    - BEGIN和END，这两者都可用于pattern中，**提供BEGIN的作用是扫描输入之前赋予程序初始状态，END是扫描输入结束且在程序结束之后执行一些扫尾工作**。任何在BEGIN之后列出的操作(紧接BEGIN后的{}内)将在awk开始扫描输入之前执行，而END之后列出的操作将在扫描完全部的输入之后执行。通常使用BEGIN来显示变量和预置(初始化)变量，使用END来输出最终结果。
    - 统计某个文件夹下的文件占用的字节数，过滤4096大小的文件(一般都是文件夹):

        ```bash
        ls -l | awk 'BEGIN {size=0;print "[start]size is", size} {if($5!=4096){size=size+$5;}} END {print "[end]size is", size/1024/1024, "M"}'
        # 打印如下
        # [start]size is 0
        # [end]size is 30038.8 M
        ```
- 支持if判断、循环等语句

### date

```bash
date -d 'yesterday' # 获取昨天。或 date -d 'last day' 
date -d 'tomorrow' # 获取明天。或 date -d 'next day' 
date -d 'last month' # 获取上个月 
date -d 'next month' # 获取下个月 
date -d 'last year' # 获取上一年 
date -d 'next year' # 获取下一年 
date -d '1 minute ago' # 获取1分钟前
date -d '3 year ago' # 三年前 
date -d '-5 year ago' # 五年后 
date -d '-2 day ago' # 两天后 
date -d '1 month ago' # 一个月前 

time=$(date "+%Y-%m-%d %H:%M:%S")
```

### find

- 语法

```bash
# default path is the current directory; default expression is -print
# expression由options、tests、actions组成
find [-H] [-L] [-P] [-Olevel] [-D help|tree|search|stat|rates|opt|exec] [path...] [expression]

## expression#options
-mindepth n # 目录进入最小深度
    # eg: -mindepth 1 # 意味着处理所有的文件，除了命令行参数指定的目录中的文件
-maxdepth n # 目录进入最大深度
    # eg: -maxdepth 0 # 只处理当前目录的文件(.)

## expression#tests
-name <patten> # 基本的文件名与shell模式pattern相匹配。正则建议使用""包裹
    # eg: -name "*.log" # `.log`开头的文件
-type <c> # 文件类型，c取值
    f # 普通文件(regular file)
    d # 目录(directory)
    s # socket

-atime <n> # 针对文件的访问时间，判断 "其访问时间" < "当前时间-(n*24小时)" 是否为真。对应stat命令获取的 Access 时间，读取文件或者执行文件时更改的
-mtime <n> # 针对文件的修改时间(天)。对应stat命令获取的 Modify 时间，是在写入文件时随文件内容的更改而更改的
    # eg: -mtime +30 # 30天之前的修改过的文件
    # eg：-mtime -30 # 过去30天之内修改过的文件
-ctime <n> # 针对文件的改变时间(天)。对应stat命令获取的 Change 时间，是在写入文件，更改所有者，权限或链接设置是随inode(存放文件基本信息)内容的更改而更改的
-amin <n> # 类似-atime，只不过此参数是基于分钟计算
-mmin <n>
-cmin <n>
-newerXY <reference> # 比较文件的时间戳，其中XY的取值为：a(访问时间)、c、m、t(绝对时间)、B(文件引用的出现时间)
    # find . -type f -newermt '2020-01-17 13:40' ! -newermt '2020-01-17 13:45' -exec cp {} ./bak \; # 将当前目录下2020-01-17 13:40到2020-01-17 13:45时间段内修改或生成的文件拷贝到bak目录下。同理：-newerat、-newerct

## expression#actions
-exec command # 执行命令。命令的参数中，字符串`{}`将以正在处理的文件名替换；这些参数可能需要用 `\`来escape，或者用括号括住，防止它们被shell展开；其余的命令行参数将作为提供给此命令的参数，直到遇到一个由`;`组成的参数为止
    # eg: -exec cp {} {}.bak \; # 删除查询到的文件
```
- 示例

```bash
sudo find / -name nginx.conf # 全局查询文件位置(查看`nginx.conf`文件所在位置)
find . -mtime +15 | wc -l # 统计15天前修改过的文件的个数

find . -type d -exec chmod 755 {} \; # 修改当前目录及其子目录为775
find . -type f -exec chmod 644 {} \; # 修改当前目录及其子目录的所有文件为644

find -name '*.TXT' -type f -mtime +15 -exec mv {} ./bak \; # 将15天前修改过的文件移动到备份目录
find . -name '*.log' -newermt "$(($(date +%Y)-1))-01-01" ! -newermt "$(($(date +%Y)-1))-12-31" | xargs -i mv {} ./backup/backup_log_$(($(date +%Y)-1)) # 将当前目录下的去年修改过的文件移动到备份目录

find -type f | xargs # xargs会在一行中打印出所有值
for item in $(find -type f | xargs) ; do # 循环打印每个文件
    file $item
done

```

### xrags

- xargs 可以将管道或标准输入(stdin)数据转换成命令行参数，也能够从文件的输出中读取数据。它能够捕获一个命令的输出，然后传递给另外一个命令
- xargs 默认的命令是 echo
- xargs 也可以将单行或多行文本输入转换为其他格式，例如多行变单行，单行变多行
- 示例

```bash
-n num # 后面加次数，表示命令在执行的时候一次用的argument的个数，默认是用所有的。eg：`cat test.txt | xargs` 多行转单行
-i/-I # 这得看linux支持了，将xargs的每项名称，一般是一行一行赋值给 {}
-d delim # 分隔符，默认的xargs分隔符是回车，argument的分隔符是空格，这里修改的是xargs的分隔符

## 示例
cat test.txt | xargs # 多行转单行
cat test.txt | xargs -n3 # 多行输出，没此使用3个参数
echo "nameXnameXnameXname" | xargs -dX # 定义分割符：name name name name
ls *.jpg | xargs -n1 -I {} cp {} /data/images # 复制所有图片文件到 /data/images 目录下

# 配合自定义函数使用
echo 'echo $*' > my.sh
cat > arg.txt << EOF
aaa
bbb
EOF
cat arg.txt | xargs -I {} ./my.sh {} ...
# 打印
aaa ...
bbb ...
```

### logger

- `rsyslog`是一个C/S架构的服务，可监听于某套接字，帮其它主机记录日志信息。rsyslog是CentOS 6以后的系统使用的日志系统，之前为syslog
- `logger` 是用于往系统中写入日志，他提供一个shell命令接口到rsyslog系统模块。默认记录到系统日志文件`/var/log/messages`
- Linux系统日志信息分为两个部分内核信息和设备信息。共用配置文件`/etc/rsyslog.conf`(CentOS 6之前为`/etc/syslog.conf`)
    - 内核信息 -> klogd -> syslogd -> /var/log/messages等文件
    - 设备信息 -> syslogd -> /var/log/dmesg、/var/log/messages等文件
        - 设备可以使用自定义的设备local0-local7，使用自定义的设备照样可以将设备信息(日志)发送给rsyslog
- 查看linux相关日志
    - `/var/log/messages` 查看系统日志
    - `dmesg` 查看设备日志，如引导时的日志
    - `last` 查看登录成功记录
    - `lastb -10` 查看最近10条登录失败记录
    - `history` 执行命令历史
- CentOS 7 修改日志时间戳格式 [^8]

```bash
# Jul 14 13:30:01 localhost systemd: Starting Session 38 of user root.
# 2018-07-14 13:32:57 desktop0 systemd: Starting System Logging Service...

## 修改 /etc/rsyslog.conf 
# Use default timestamp format
#$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat # 这行是原来的将它注释，添加下面两行
$template CustomFormat,"%$NOW% %TIMESTAMP:8:15% %HOSTNAME% %syslogtag% %msg%\n"
$ActionFileDefaultTemplate CustomFormat

## 重启
systemctl restart rsyslog.service
```
- logger使用案例 [^6]

```bash
## 简单使用
# 默认记录到系统日志文件 /var/log/messages
logger hello world  # 记录如 `Dec  5 15:34:58 localhost root: hello world`
# -i 记录进程id
logger -i test1...  # `Dec  5 15:34:58 localhost root[23162]: test1`
# -s 输出标准错误(命令行会显示此错误)，并且将信息打印到系统日志中
logger -i -s test2  # `Dec  5 15:34:58 localhost root[23162]: test2`
# -t 日志标记，默认是root
logger -i -t test test3 # `Dec  5 15:34:58 localhost test[23162]: test2`
# -p 指定输入消息日志级别，优先级可以是数字或者指定为 "facility(设施、信道).level(优先级)" 的格式(默认级别为 "user.notice")，日志会根据配置文件/etc/rsyslog.conf将日志输出到对应日志文件，默认为/var/log/messages
# 固定的 facility 和 level 的类型参考：https://www.cnblogs.com/xingmuxin/p/8656498.html
logger -it test -p syslog.info "test4..." # `Dec  5 15:34:58 localhost test[23162]: test4...`

## 基于日志级别自定义日志输出文件
# 修改日志配置文件。增加配置`local1.info /var/log/local1-info.log`
vi /etc/rsyslog.conf
systemctl restart rsyslog # 重启使配置文件生效
logger -it test -p local1.info "test5..." # 此时在 /var/log/local1-info.log 中可看到 `Dec  5 15:34:58 localhost test[23162]: test5...`
```
- `/etc/rsyslog.conf` 配置说明
    - 会自动根据日志文件大小切割日志，生成 xxx-YYYYMMDD 的日志历史
    - 修改日志文件后需要重启服务 `systemctl restart rsyslog` (重启后新配置生效会有一点延迟)

```bash
#### RULES ####
# 如果日志级别为 local1.info，则将日志输出到文件 /var/log/local1-info.log
local1.info /var/log/local1-info.log

# ### begin forwarding rule ###
# 可配置同步日志到远程机器
```

#### 记录命令执行历史到日志文件

```bash
# root用户执行
su - root
source <(curl -L https://raw.githubusercontent.com/oldinaction/scripts/master/shell/prod/conf-recode-cmd-history.sh)
# 查看日志
tail -f /var/log/local1-info.log
```

### dd 磁盘读写测试

- 磁盘性能
    - 固态硬盘，在SATA 2.0接口上平均读取速度在`225MB/S`，平均写入速度在`71MB/S`。在SATA 3.0接口上，平均读取速度骤然提升至`311MB/S`

- 用于复制文件并对原文件的内容进行转换和格式化处理
    
```bash
## 参数说明
if      # 代表输入文件。如果不指定if，默认就会从stdin中读取输入
of      # 代表输出文件。如果不指定of，默认就会将stdout作为默认输出
bs      # 代表字节为单位的块大小，如64k
count   # 代表被复制的块数，如4k/4000
# 大多数文件系统的默认I/O操作都是缓存I/O，数据会先被拷贝到操作系统内核的缓冲区中，然后才会从操作系统内核的缓冲区拷贝到应用程序的地址空间。dd命令不指定oflag或conv参数时默认使用缓存I/O
oflag=direct    # 指定采用直接I/O操作。直接I/O的优点是通过减少操作系统内核缓冲区和应用程序地址空间的数据拷贝次数，降低了对文件读取和写入时所带来的CPU的使用以及内存带宽的占用
oflag=dsync     # dd在执行时每次都会进行同步写入操作，可能是最慢的一种方式了，因为基本上没有用到写缓存(write cache)。每次读取64k后就要先把这64k写入磁盘(每次都同步)，然后再读取下面这64k，一共重复4k次(4000)。可能听到磁盘啪啪的响，比较伤磁盘
oflag=syns      # 与上者dsyns类似，但同时也对元数据（描述一个文件特征的系统数据，如访问权限、文件拥有者及文件数据块的分布信息等。）生效，dd在执行时每次都会进行数据和元数据的同步写入操作
conv=fdatasync  # dd命令执行到最后会执行一次"同步(sync)"操作，这时候得到的速度是读取这286M数据到内存并写入到磁盘上所需的时间
conv=fsync      # 与上者fdatasync类似，但同时元数据也一同写入

/dev/null # 伪设备，回收站，写该文件不会产生IO
/dev/zero # 伪设备，会产生空字符流，但不会产生IO
```
- `dd if=/dev/zero of=test bs=64k count=4k oflag=dsync` 在当前目录创建文件test，并每次以64k的大小往文件中读写数据，总共执行4000次，最终产生test文件大小为268M。以此测试磁盘操作速度
- 测试案例

```bash
# dd if=/dev/zero of=test bs=64k count=4k oflag=dsync # 测试结果如下
268435456 bytes (268 MB) copied, 26.3299 s, 10.2 MB/s               # 本地 SSD 磁盘直接操作
268435456 bytes (268 MB) copied, 261.475 s, 1.0 MB/s                # 本地 HDD 磁盘直接操作
268435456 bytes (268 MB) copied, 14.8903 s, 18.0 MB/s               # 阿里云 SSD 磁盘直接操作
268435456 bytes (268 MB, 256 MiB) copied, 1637.61 s, 164 kB/s       # 本地ceph集群(1 ssd + 2 hdd)
268435456 bytes (268 MB, 256 MiB) copied, 90.0906 s, 3.0 MB/s       # 本地ceph集群(3 ssd)
```

### sgdisk 磁盘操作工具

```bash
# 安装
yum install -y gdisk

# 查看所有GPT分区
sgdisk -p /dev/sdb
# 查看第一个分区
sgdisk -i 1 /dev/sdb
# 创建了一个不指定大小、不指定分区号的分区
sgdisk -n 0:0:0 /dev/sdb # -n 分区号:起始地址:结束地址
# 创建分区1，从默认起始地址开始的10G的分区
sgdisk -n 1:0:+10G /dev/sdb
# 将分区方案写入文件进行备份
sgdisk --backup=/root/sdb.partitiontable /dev/sdb
# 删除第一分区
sgdisk -d 1 /dev/sdb
# 删除所有分区(提示：GPT data structures destroyed!)
sgdisk --zap-all --clear --mbrtogpt /dev/sdb
```

### 其他

- `basename <file>` 返回一个字符串参数的基本文件名称。如：`basename /home/smalle/test.txt`返回test.txt
- `yes y` 一直输出字符串y
    - `yes y | cp -i new old` `cp` 用文件覆盖就文件(`-i`存在old文件需进行提示，否则无需提示；`-f`始终不进行提示)，而此时前面会一致输出`y`，相当于自动输入了y进行确认cp操作

## Tips

### 零散

- 如果脚本中有`vi`等操作，当用户保存该文件后会继续执行脚本
- 直接执行github等网站脚本

    ```bash
    # 法1(需要是raw类型的连接)。tee 实时重定向日志(同时也会在控制台打印，并且可进行交互)
    bash <(curl -L https://raw.githubusercontent.com/sprov065/v2-ui/master/install.sh) 2>&1 | tee my.log # 此处 bash 也可改成 source
    # 法2(需要是raw类型的连接)
    wget --no-check-certificate https://github.com/sprov065/blog/raw/master/bbr.sh && bash bbr.sh 2>&1 | tee my.log
    ```
- 命令执行失败后，是否执行后续命令

    ```bash
    command || true     # 此command执行失败后继续执行后续命令
    command || exit 0   # 此command执行失败后不执行后续命令
    ```
- `cp`命令强制覆盖不提示 `\cp test test.bak`
- 为shell命令设置超时时间

    ```bash
    timeout 10 ./test.sh # 设置执行脚本超时时间为10s
    echo $? # 如果超时则返回 124
    ```
- 脚本中执行nohup命令不生效(主要是找不到环境变量)

    ```bash
    source /etc/profile
    nohup echo "hello world"
    ```

### json处理

- 使用内置的 awk/sed 来获取指定的 JSON 键值，缺点需要根据实际情况写对于的正则表达式 [^7]
- 使用`jq`软件获取
    - `yum install jq` 安装jq
    - `jq .subjects[0].genres[0] douban.json`
    - `curl -s https://douban.uieee.com/v2/movie/top250?count=1 | jq .subjects[0].genres[0]`
- 调用其他脚本解释器(python/php/js)，**推荐**
    
    ```py
    ## python2(服务器一般会安装)
    export PYTHONIOENCODING=utf8 && curl -s 'https://douban.uieee.com/v2/movie/top250?count=1' | python -c "import sys, json; print json.load(sys.stdin)['subjects'][0]['genres'][0]"
    
    echo '{"instance": "smalle'\''aezo"}' | python -c "import sys, json; print json.load(sys.stdin)['instance']"

    ## python3
    curl -s 'https://douban.uieee.com/v2/movie/top250?count=1' | \
    python3 -c "import sys, json; print(json.load(sys.stdin)['subjects'][0]['genres'][0])"
    ```

## 示例

### jar包运行/停止示例 [^1]

- 自启动脚本可参考`/etc/init.d`目录下的文件如`network`，加下下列脚本文件名为`my_script`
- 将脚本加入到开机启动`chkconfig --add my_script`

```shell
#!/bin/bash
#
#警告!!!：该脚本stop部分使用系统kill命令来强制终止指定的java程序进程。
#在杀死进程前，未作任何条件检查。在某些情况下，如程序正在进行文件或数据库写操作，
#可能会造成数据丢失或数据不完整。如果必须要考虑到这类情况，则需要改写此脚本，
#增加在执行kill命令前的一系列检查。
#
###################################
# 以下这些注释设置可以被chkconfig命令读取
# chkconfig: 2345 50 50
# description: Java程序启动脚本
# processname: my_script_name
# config: 如果需要的话，可以配置
###################################
### 一般需要修改的配置
#需要启动的Java主程序（main方法类）
APP_JAR="app-0.0.1-SNAPSHOT.jar"
# springboot参数
SPRING_PROFILES="--spring.profiles.active=test"
# 查找到此APP的grep字符串(基于APP_JAR的基础上继续查找，可用于多实例启动)
APP_GREP_STR=$APP_JAR
# 内存溢出后dump文件存放位置，需要先创建此文件夹
JVM_LOG_PATH="/home/"
#执行程序启动所使用的系统用户，考虑到安全，推荐不使用root帐号
RUNNING_USER=root

#JDK所在路径(需要配置好$JAVA_HOME环境变量)，$JAVA_HOME=也可不使用系统jdk
#JAVA_HOME=
if [ -f "$JAVA_HOME/bin/java" ]; then
  JAVA="$JAVA_HOME/bin/java"
else
  JAVA=java
fi

#Java程序所在的目录（将此文件和jar放在统一目录）
APP_HOME="$( cd -P "$( dirname "$0" )" && pwd )"

#java虚拟机启动参数
#MEMIF="-Xms3g -Xmx3g -Xmn1g -XX:MaxPermSize=512m"
OOME="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$JVM_LOG_PATH"
#IPADDR=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'` # automatic IP address for linux（内网地址）
#RMIIF="-Djava.rmi.server.hostname=$IPADDR"
#JMX="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=33333 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
#DEBUG="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8091"
VM_ARGS="$MEMIF $OOME $RMIIF $JMX $DEBUG -Dfile.encoding=UTF-8"

JAR_ARGS="$SPRING_PROFILES"

#初始化psid变量（全局）
psid=0

#(函数)判断程序是否已启动
checkpid() {
    ps_pid=`ps -ef | grep $APP_JAR | grep $APP_GREP_STR | grep -v grep`

    if [ -n "$ps_pid" ]; then
        psid=`echo $ps_pid | awk '{print $2}'`
    else
        psid=0
    fi
}

#(函数)启动程序
start() {
    checkpid

    if [ $psid -ne 0 ]; then
        echo "[warn] $APP_JAR already started! (pid=$psid)"
    else
        echo -n "[info] Starting $APP_HOME/$APP_JAR ..."
        JAVA_CMD="( cd $APP_HOME && nohup $JAVA $VM_ARGS -jar $APP_JAR $JAR_ARGS > /dev/null 2>&1 & )"
        su - $RUNNING_USER -c "$JAVA_CMD"
        checkpid
        if [ $psid -ne 0 ]; then
            echo "[info] OK (pid=$psid)"
        else
            echo "[warn] Failed"
        fi
    fi
}

#(函数)停止程序。以下为强制kill，可配合timeout前软性停止服务
stop() {
    # 首先调用checkpid函数，刷新$psid全局变量
    checkpid

    # 如果程序已经启动（$psid不等于0），则开始执行停止，否则，提示程序未运行
    if [ $psid -ne 0 ]; then
        # echo -n 表示打印字符后，不换行
        echo -n "[info] Stopping $APP_HOME/$APP_JAR ...(pid=$psid) "
        # 使用kill -s 9 pid命令进行强制杀死进程
        su - $RUNNING_USER -c "kill -s 9 $psid"
        # 执行kill命令行紧接其后，马上查看上一句命令的返回值: $? 。在shell编程中，"$?" 表示上一句命令或者一个函数的返回值
        if [ $? -eq 0 ]; then
            echo "[info] OK"
        else
            echo "[warn] Failed"
        fi

        # 为了防止java程序被启动多次，这里增加反复检查进程，反复杀死的处理（递归调用stop）
        checkpid
        if [ $psid -ne 0 ]; then
            stop
        fi
    else
        echo "[warn] $APP_HOME/$APP_JAR is not running"
    fi
}

#(函数)检查程序运行状态
status() {
    checkpid

    if [ $psid -ne 0 ];  then
        echo "[info] $APP_HOME/$APP_JAR is running! (pid=$psid)"
    else
        echo "[warn] $APP_HOME/$APP_JAR is not running"
    fi
}

#(函数)打印系统环境参数
info() {
    echo "System Information:"
    echo "****************************"
    echo `head -n 1 /etc/issue`
    echo `uname -a`
    echo
    echo "JAVA_HOME=$JAVA_HOME"
    echo `$JAVA -version`
    echo
    echo "APP_HOME=$APP_HOME"
    echo "APP_JAR=$APP_JAR"
    echo "****************************"
}

#读取脚本的第一个参数($1)，进行判断. 参数取值范围：{start|stop|restart|status|info}. 如参数不在指定范围之内，则打印帮助信息
case "$1" in
    'start')
		start
		;;
    'stop')
		stop
		;;
    'restart')
		stop
		start
		;;
    'status')
		status
		;;
    'info')
		info
		;;
  	*)
		echo "[info] Usage: $0 {start|stop|restart|status|info}"
		exit 1
esac
exit $?
```

### 实现交互

```bash
read -p "you are sure you wang to xxxxxx?[y/n]" input
echo "you input [$input]"
if [ $input = "y" ];then
    echo "ok "
fi
```

### 定时判断

```bash
# this is a function to find whether the docker is run.
$proc_name='docker'
has_started() {
    ionum=`ps -ef | grep $proc_name | grep -v grep | wc -l`
    return $ionum 
}
while true
do
    has_started
    processnum=$?
    if [ $processnum -eq 0 ]
    then 
        echo "$proc_name has not been started!"
    else
        echo "$proc_name has been started"
        break 
    fi
    sleep 5
done
echo 'to do what...'
```

### 删除日志文件

- 定时删除
    - `crontab -e` 编辑定时任务配置
    - `00 02 * * * root /home/smalle/script/clear-log.sh` 添加配置
    - `systemctl restart crond` 重启定时任务
- clear-log.sh

```bash
# clear-log.sh
LOG_FILE=~/script/clear-log.log
LOG_SAVE_DAYS=30 # 日志保留天数
NOW=$(date +'%y/%m/%d %H:%M:%S')
echo "===============START $NOW==================" >> $LOG_FILE

# 删除数据库日志(主备库会产生my_db_name-log-bin.0的日志)
rm -rfv /home/data/mysql/my_db_name-log-bin.0* >> $LOG_FILE # 待考虑？

# 删除日志文件
find /home/smalle/demo/ -name *.log -type f -mtime +$LOG_SAVE_DAYS -exec rm -fv {} \; >> $LOG_FILE
# 删除日志目录(日志文件基于日期分类)
lastMon=$(date -d"-$LOG_SAVE_DAYS day" +'%Y%m%d') # 获取30天前的日期
for dir in module1 module2 ; do 
  for item in $(find /home/smalle/demo/$dir/ -mindepth 1 -type d | xargs) ; do # -mindepth 1 查询的最小深度为1(相当于去掉当前目录)
    # 字符串比较，\< 进行转义
    if [ "$item" \< /home/smalle/demo/$dir/$lastMon ]; then
      rmdir -v $item >> $LOG_FILE
    fi
  done
done

# 删除jvm日志(保留近3天的)
find /home/smalle/jvmlogs/ -type f -mtime +3 -exec rm -rfv {} \; >> $LOG_FILE
echo "===============END $NOW==================" >> $LOG_FILE
```

### 生成随机数和字符串

```bash
## $RANDOM 的范围是 [0, 32767]
echo $RANDOM
## 获取uuid: 3ebbdb15-7ee6-4e30-97ac-643d41bbf9d6
cat /proc/sys/kernel/random/uuid
date +%s%N

## 生成随机字符串，`head -c 10`表示取前10位
cat /dev/urandom | head -n 10 | md5sum | head -c 10
date +%s%N | md5sum | head -c 10
```
- 或者创建shell文件

```bash
#!/bin/bash

function rand() {
    min=$1
    max=$(($2-$min+1))
    # num=$(($RANDOM+1000000000)) #增加一个10位的数再求余
    # num=$(date +%s%N)
    # num=$(cat /proc/sys/kernel/random/uuid | cksum | awk -F ' ' '{print $1}')
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))
}
# 生成1~50的随机数
rnd=$(rand 1 50)
echo $rnd

exit 0
```

### 使用表格显示结果

```bash
local line="+-------------------------------------------+\n"
local string=%20s
printf "${line}|${string} |${string} |\n${line}" Username Password
grep -v "^#" /etc/ppp/chap-secrets | awk '{printf "|'${string}' |'${string}' |\n", $1,$3}'
printf ${line}

## /etc/ppp/chap-secrets文件数据如下
# Secrets for authentication using CHAP
# client    server    secret    IP addresses
test    l2tpd    ok123456       *
test2    pptpd    ok123456    *

## 上述脚本打印结果如下
+-------------------------------------------+
|            Username |            Password |
+-------------------------------------------+
|                test |            ok123456 |
|               test2 |            ok123456 |
+-------------------------------------------+
```

### 创建vsftpd虚拟账号

- vsftpd虚拟账号设置见 [http://blog.aezo.cn/2019/03/19/arch/ftp/](/_posts/arch/ftp.md#vsftpd)
- 脚本使用如：`sudo ./vsftp_user.sh -u s_test1,s_test2`，以sudo执行脚本，则脚本中的命令都为sudo权限执行

```bash
#!/bin/bash

# getopt表达式
TEMP=`getopt -o u: -n "$0" -- "$@"`
if [ $? != 0 ] ; then echo "Error..." >&2 ; usage ; exit 1 ; fi
eval set -- "$TEMP"

function usage() {
	echo "usage: $0 -u <ftp_user_name>" ;
	echo "eg: $0 -u s_test1,s_test2" ;
	exit 1 ;
}

# 判断脚本是否未传任何参数
if [ -z "$2" ] ; then echo "(error) None-argument..." ; usage ; exit 1 ; fi

function create_user() {
	u=$1
  # 判断字符串不以xxx开头; 双引号中的变量可以识别，单引号中的变量无法识别; `return 1` 为函数返回值
	if [[ $u != s_* ]] ; then echo "(warn) 用户名 $user 不以 s_ 开头, 不进行操作." ; return 1; fi
	
	pass=$(sed -n "/$u/{n;p;}" $vuser_file)
  # -n 判断文本是否不为空; [ ] 中的变量必须加双引号，[[ ]] 中的变量可以不使用双引号
	if [ -n "$pass" ] ; then
		echo "(warn) 存在登录名: $u, 密码: $pass" ;
	else
		# 去掉文末空行
		sed -i -e '/^$/d' $vuser_file ;
		
		echo $u >> $vuser_file ;
		pass=$(cat /dev/urandom | head -n 8 | md5sum | head -c 8)
		echo $pass >> $vuser_file ;
	fi
	
	touch $etc_dir/$u ;
  # 添加多行文本到文件 `<< EOF`表示遇到 `EOF` 则停止. 此时可以识别变量 $u
	cat > $etc_dir/$u << EOF
local_root=/home/vsftp/$u
anon_umask=022
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=NO
anon_other_write_enable=YES
EOF
	
	mkdir -p $vuser_dir/$u ;
	chown -R vsftp.vsftp $vuser_dir/$u ;
	
  # 打印的字符串不加单双引号亦可，且字符串连接无需任何符号
	echo "(info)" 登录名: $u, 密码: $pass ;
}

user_array=
vuser_dir=/home/vsftp
etc_dir=/etc/vsftpd/vuser_conf.d
vuser_file=/etc/vsftpd/vuser
while true ; do
	case "$1" in
		-u) 
			user_str=$2
      # 以 , 进行分割字符串为数组
			user_array=(${user_str//,/ })
			shift 2 ;;
		--) shift ; break ;;
		*) echo "(error) Internal error!" ; exit 1 ;;
	esac
done

cp $vuser_file $vuser_file'_bak_'$(cat /dev/urandom | head -n 8 | md5sum | head -c 8) ; # 备份文件

for user in ${user_array[@]}
do
  # 调用函数并传参数
	create_user $user ;
	echo ---------------------------------- ;
done 

db_load -T -t hash -f $vuser_file $vuser_file'.db' ; # 重新生成vsftpd虚拟用户数据库

exit $?
```

### 日期

```bash
## 带日期的日志输出
date_echo() {
    echo `date "+%Y-%m-%d %H:%M:%S"` $1
    logger -it my_script -p local1.info $1
}
date_echo "Starting ..." # 输出：2019-12-05 11:46:43 Starting ...
```

## C 源码脚本

### 简单示例

```bash
# 编写源码
vi test.c
# 编译源码
# yum -y install gcc # 安装编译器
gcc test.c -o test -std=c99 # 源码中的for需要在C99 mode中才可使用，因此需要加`-std=c99`
# 运行，结果为：连续输出10次hello world后，等待30s程序结束，回到命令行
./test

# 缓冲流测试
./test > out # 启动
tail -f out # 另起一个shell观察out文件数据变化：此时out文件刚开始无数据，30s后输出所有的hello world。如果希望启动后每打印一次则out文件中立刻出现则需要通过下列方式实现
# 第一种方式：修改源码，使用setvbuf函数
# 第二种方式：使用stdbuf函数运行。o表示输出流，L表示行缓冲。这样只要遇到换行符，就会将缓冲输出到指定对象
stdbuf -oL ./test > out
```

- test.c (参考：Linux 输出流重定向缓冲设置 [^5])

```c
#include <stdio.h>
#include <unistd.h>
int main()
{
    // setvbuf(stdout, NULL, _IOLBF, 0); // 设置stdout的缓冲类型为行缓冲
    for(int i = 0; i < 10; i++)
        printf("hello world\n");

     sleep(30); // 睡眠30秒
     return 0;
}
```




---

参考文章

[^1]: http://blog.csdn.net/clerk0324/article/details/50593882
[^2]: https://blog.csdn.net/fdipzone/article/details/24329523
[^3]: https://www.cnblogs.com/yxzfscg/p/5338775.html
[^4]: https://www.cnblogs.com/softidea/p/6855045.html
[^5]: https://blog.csdn.net/frank_liuxing/article/details/54017813
[^6]: https://www.cnblogs.com/xingmuxin/p/8656498.html
[^7]: https://www.tomczhen.com/2017/10/15/parsing-json-with-shell-script/
[^8]: http://www.voidcn.com/article/p-okvvyica-bsd.html


