---
layout: "post"
title: "Shell编程"
date: "2017-01-10 13:19"
categories: linux
tags: [shell, linux]
---

## 简介

- shell是解释性语言，解释器为`bash`

## 基本语法

### 基本概念

-  linux 引号
  - 反引号：**``** 命令替换
  - 单引号：**''** 字符串
  - 双引号: **""** 变量替换
- 命令替换：使用 **\`\`**(反引号)包裹或**`$(cmd)`**
  - `wall `date`` 所有人都收到当前时间
  - `wall date` 所有人都收到date这个字符串
- 管道：将一个命令的输出传送给另外一个命令，作为另外一个命令的输入。如：`命令1|命令2|...|命令n`
  - `ls -Rl /etc | more` 分页显示/etc目录
  - `cat /etc/passwd | grep root` 查询root用户帐号信息
  - `ls -l * | grep "^_" | wc -l` 统计当前目录有多少个文件
- 重定向：将命令的结果重定向到某个地方
  - `>`、`>>`　输出重定向(`>`覆盖，`>>`追加)
    - `ls　> ls.txt` 将ls的输出保存到ls.txt中
    - `>` 如果文件不存在，就创建文件；如果文件存在，就将其清空。`>>` 如果文件不存在，就创建文件；如果文件存在，则将新的内容追加到那个文件的末尾
  - `2>` 错误重定向，如：`lsss　2> ls.txt`
  - `&>` 全部重定向：`ls &> /dev/null` 将结果全部传给数据黑洞
  - `<`、`<<` 输入重定向
    - `wall < notice.txt` 将notice.txt中的数据发送给所有登录人
  - 标准输入(stdin) 代码为 0 ，实际映射关系：/dev/stdin -> /proc/self/fd/0 
  - 标准输出(stdout)代码为 1 ， 实际映射关系：/dev/stdout -> /proc/self/fd/1
    - `echo` 将输出放到标准输出中
  - 标准错误输出(stderr)代码为 2 ，实际映射关系： /dev/stderr ->/pro/self/fd/2
- 程序有两类返回值：执行结果、执行状态(即`$?`的值，`0` 表示正确，`1-255` 错误)

#### 变量

- 变量类型
  - 环境变量(作用于可跨bash)：`export <var_name>=<var_value>`
  - 本地变量(作用于当前bash)：`<var_name>=<var_value>`
  - 局部变量(作用于当前代码段)：`local <var_name>=<var_value>`
  - 位置变量(作用于脚本执行的参数)：`$1` 表示第一个参数，以次类推`$2`、`$3`
  - 特殊变量
    - **`$?`** 上一个命令的执行状态返回值(`0` 表示正确，其他为错误)
    - `$#` 传递到脚本的参数个数
    - `$*` 传递到脚本的参数，与位置变量不同，此选项参数可超过9个
    - `$$` 脚本运行时当前进程的ID号，常用作临时变量的后缀，如 haison.$$
    - `$!` 后台运行的（&）最后一个进程的ID号
    - `$@` 与$#相同，使用时加引号，并在引号中返回参数个数
    - `$-` 上一个命令的最后一个参数
- `set` 查看shell中变量
- `printenv`/`env` 查看shell中环境变量
- `unset <var_name>` 撤销变量
- 引用变量 `${var_name}`，一般可以省略{}

### 脚本

- 注意文件格式必须是Unix格式(否则执行报错：`: No such file or directory`)
  - 解决办法：`vim my.sh` - `:set ff=unix` - `:x`
- 执行`./my.sh`或`sh my.sh`或`bash my.sh`(有时需要添加可执行权限：`chmod +x my.sh`)
  - `bash -n shell文件` 检查文件是否有语法错误
  - `bash -x shell 文件` debug 执行文件
- `#!/bin/bash` 脚本第一行必须以此开头
- `#` 表示注释
- `exit` 退出脚本
  - 退出脚本可以指定脚本执行的状态：`exit 0` 成功退出，`exit 1`/`exit 2`/... 失败退出

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

#### 条件判断

- 条件表达式 `[ expression ]` **注意其中的空格**
- 整数比较
  - `-eq` 相等，比如：[ $A –eq  $B ]
  - `-ne` 不等
  - `-gt` 大于
  - `-lt` 小于
  - `-ge` 大于等于
  - `-le` 小于等于
- 文件测试(需要中括号)
  - `-e <file>` 测试文件是否存在
  - `-f <file>` 测试文件是否为普通文件
  - `-d <file>` 测试文件(linux是基于文件进行编程的)是否为目录
  - `-r` 权限判断
  - `-w`   
  - `-x`
- 字符串测试
  - `==` 或 `=` **等号两端需要空格**
  - `!=`
  - `-n <string>` 判断字符串是否为空
  - `-s <string>` 判非空
- 条件表达式的逻辑关系
  - **在linux中命令执行状态：0 为真，其他为假**
  - `&&`(第一个表达式为true才会运行第二个)、`||`、`!`
- 控制结构

  ```shell
  if 条件表达式 ; then
    语句
  elif 条件表达式 ; then
    语句
  else
    语句
  fi
  ```
- 控制结构中的逻辑关系
  - `-a` 逻辑与，如：`if  [ $# -gt 1 –a $# -lt 3 –o $# -eq 2 ] ; then`
  - `-o` 或
- 算术运算(其中任意一种即可)
  - `let C=$A+$B` **(=、+附近不能有空格，下同。此时C不能有$，使用变量的使用才需要加$)**
  - `C=$[$A+$B]`
  - `C=$(($A+$B))`
  - C=\`expr $A + $B\` (表达式中各操作数及运算符之间要有空格，而且要使用命令引用)

#### 循环

- 控制结构

  ```shell
  # for
  for 变量 in 列表 ; do
    语句
  done

  # while
  while 条件 ; do
    语句
    [break]
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

### linux命令

- `basename <file>` 返回一个字符串参数的基本文件名称。如：basename /home/smalle/test.txt返回test.txt

## functions模块

- 位于`/etc/rc.d/init.d/functions`文件中
- 在shell脚本中引用只需加入`. /etc/rc.d/init.d/functions`即可

### 方法介绍

- `killproc` 杀死进程

## jar包运行/停止示例 [^1]

- 参考`/etc/init.d`目录下的文件，如`network`

```shell
#!/bin/sh
#
#警告!!!：该脚本stop部分使用系统kill命令来强制终止指定的java程序进程。
#在杀死进程前，未作任何条件检查。在某些情况下，如程序正在进行文件或数据库写操作，
#可能会造成数据丢失或数据不完整。如果必须要考虑到这类情况，则需要改写此脚本，
#增加在执行kill命令前的一系列检查。
#
###################################
# 以下这些注释设置可以被chkconfig命令读取
# chkconfig: - 99 50
# description: Java程序启动脚本
# processname: test
# config: 如果需要的话，可以配置
###################################
#
#JDK所在路径(需要配置好$JAVA_HOME环境变量)
# $JAVA_HOME=也可不使用系统jdk
# JAVA_HOME=
if [ -f "$JAVA_HOME/bin/java" ]; then
  JAVA="$JAVA_HOME/bin/java"
else
  JAVA=java
fi

#执行程序启动所使用的系统用户，考虑到安全，推荐不使用root帐号
RUNNING_USER=root

#Java程序所在的目录（将此文件和jar放在统一目录）
APP_HOME="$( cd -P "$( dirname "$0" )" && pwd )"

#需要启动的Java主程序（main方法类）
APP_JAR="grouphelp-0.0.1-SNAPSHOT.jar"

# springboot参数
PROFILES="--spring.profiles.active=prod"
JAR_ARGS="$PROFILES"

#java虚拟机启动参数
#MEMIF="-Xms3g -Xmx3g -Xmn1g -XX:MaxPermSize=512m -Dfile.encoding=UTF-8"
#OOME="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/jvmlogs/"
#IPADDR=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'` # automatic IP address for linux（内网地址）
#RMIIF="-Djava.rmi.server.hostname=$IPADDR"
#JMX="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=33333 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
#DEBUG="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8091"
VM_ARGS="$MEMIF $OOME $RMIIF $JMX $DEBUG"

#初始化psid变量（全局）
psid=0

#(函数)判断程序是否已启动
checkpid() {
    ps_pid=`ps -ef | grep $APP_JAR | grep -v grep`

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
      JAVA_CMD="nohup $JAVA -jar $APP_HOME/$APP_JAR $JAR_ARGS > /dev/null 2>&1 &"
      su - $RUNNING_USER -c "$JAVA_CMD"
      checkpid
      if [ $psid -ne 0 ]; then
          echo "[info] OK (pid=$psid)"
      else
          echo "[warn] Failed"
      fi
    fi
}

#(函数)停止程序
stop() {
    # 首先调用checkpid函数，刷新$psid全局变量
    checkpid

    # 如果程序已经启动（$psid不等于0），则开始执行停止，否则，提示程序未运行
    if [ $psid -ne 0 ]; then
      # echo -n 表示打印字符后，不换行
      echo -n "[info] Stopping $APP_HOME/$APP_JAR ...(pid=$psid) "
      # 使用kill -9 pid命令进行强制杀死进程
      su - $RUNNING_USER -c "kill -9 $psid"
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


---

参考文章

[^1]: http://blog.csdn.net/clerk0324/article/details/50593882
