---
layout: "post"
title: "java相关Shell脚本"
date: "2017-01-10 13:19"
categories: [linux]
tags: [shell, java]
---

- 注意文件格式必须是Unix格式
- 执行`sh ./my.sh`

## jar包运行/停止

    ```shell
    #!/bin/sh
    #
    #该脚本为Linux下启动java程序的通用脚本。即可以作为开机自启动service脚本被调用，
    #也可以作为启动java程序的独立脚本来使用。
    #
    #Author: tudaxia.com, Date: 2011/6/7
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
    ###################################
    #环境变量及程序执行参数
    #需要根据实际环境以及Java程序名称来修改这些参数
    ###################################
    #JDK所在路径(需要配置好$JAVA_HOME环境变量)
    # $JAVA_HOME=也可不使用系统jdk
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
    #DEBUG="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8091"
    #MEMIF="-Xms128M -Xmx512M -XX:MaxPermSize=512m -Dfile.encoding=UTF-8"
    VM_ARGS="$MEMIF $DEBUG"

    ###################################
    #(函数)判断程序是否已启动
    #
    #说明：
    #使用JDK自带的JPS命令及grep命令组合，准确查找pid
    #jps 加 l 参数，表示显示java的完整包路径
    #使用awk，分割出pid ($1部分)，及Java程序名称($2部分)
    ###################################
    #初始化psid变量（全局）
    psid=0

    checkpid() {
       javaps=`$JAVA_HOME/bin/jps -l | grep $APP_JAR`

       if [ -n "$javaps" ]; then
          psid=`echo $javaps | awk '{print $1}'`
       else
          psid=0
       fi
    }

    ###################################
    #(函数)启动程序
    #
    #说明：
    #1. 首先调用checkpid函数，刷新$psid全局变量
    #2. 如果程序已经启动（$psid不等于0），则提示程序已启动
    #3. 如果程序没有被启动，则执行启动命令行
    #4. 启动命令执行后，再次调用checkpid函数
    #5. 如果步骤4的结果能够确认程序的pid,则打印[OK]，否则打印[Failed]
    #注意：echo -n 表示打印字符后，不换行
    #注意: "nohup 某命令 >/dev/null 2>&1 &" 的用法
    ###################################
    start() {
       checkpid

       if [ $psid -ne 0 ]; then
          echo "================================"
          echo "warn: $APP_JAR already started! (pid=$psid)"
          echo "================================"
       else
          echo -n "Starting $APP_JAR ..."
          JAVA_CMD="nohup $JAVA_HOME/bin/java -jar $APP_HOME/$APP_JAR $JAR_ARGS > console.log 2>&1 &"
          su - $RUNNING_USER -c "$JAVA_CMD"
          checkpid
          if [ $psid -ne 0 ]; then
             echo "(pid=$psid) [OK]"
          else
             echo "[Failed]"
          fi
       fi
    }

    ###################################
    #(函数)停止程序
    #
    #说明：
    #1. 首先调用checkpid函数，刷新$psid全局变量
    #2. 如果程序已经启动（$psid不等于0），则开始执行停止，否则，提示程序未运行
    #3. 使用kill -9 pid命令进行强制杀死进程
    #4. 执行kill命令行紧接其后，马上查看上一句命令的返回值: $?
    #5. 如果步骤4的结果$?等于0,则打印[OK]，否则打印[Failed]
    #6. 为了防止java程序被启动多次，这里增加反复检查进程，反复杀死的处理（递归调用stop）。
    #注意：echo -n 表示打印字符后，不换行
    #注意: 在shell编程中，"$?" 表示上一句命令或者一个函数的返回值
    ###################################
    stop() {
       checkpid

       if [ $psid -ne 0 ]; then
          echo -n "Stopping $APP_JAR ...(pid=$psid) "
          su - $RUNNING_USER -c "kill -9 $psid"
          if [ $? -eq 0 ]; then
             echo "[OK]"
          else
             echo "[Failed]"
          fi

          checkpid
          if [ $psid -ne 0 ]; then
             stop
          fi
       else
          echo "================================"
          echo "warn: $APP_JAR is not running"
          echo "================================"
       fi
    }

    ###################################
    #(函数)检查程序运行状态
    #
    #说明：
    #1. 首先调用checkpid函数，刷新$psid全局变量
    #2. 如果程序已经启动（$psid不等于0），则提示正在运行并表示出pid
    #3. 否则，提示程序未运行
    ###################################
    status() {
       checkpid

       if [ $psid -ne 0 ];  then
          echo "$APP_JAR is running! (pid=$psid)"
       else
          echo "$APP_JAR is not running"
       fi
    }

    ###################################
    #(函数)打印系统环境参数
    ###################################
    info() {
       echo "System Information:"
       echo "****************************"
       echo `head -n 1 /etc/issue`
       echo `uname -a`
       echo
       echo "JAVA_HOME=$JAVA_HOME"
       echo `$JAVA_HOME/bin/java -version`
       echo
       echo "APP_HOME=$APP_HOME"
       echo "APP_JAR=$APP_JAR"
       echo "****************************"
    }

    ###################################
    #读取脚本的第一个参数($1)，进行判断
    #参数取值范围：{start|stop|restart|status|info}
    #如参数不在指定范围之内，则打印帮助信息
    ###################################
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
         echo "Usage: $0 {start|stop|restart|status|info}"
         exit 1
    esac
    exit 0
    ```


---
http://blog.csdn.net/clerk0324/article/details/50593882
