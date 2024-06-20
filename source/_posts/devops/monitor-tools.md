---
layout: "post"
title: "监控工具"
date: "2019-09-30 16:13"
categories: devops
tags: [monitor]
---

## prometheus

- 参考[prometheus.md](/_posts/devops/prometheus.md)

## zabbix

- 参考[zabbix.md](/_posts/devops/zabbix.md)

## Monit

- 官网：https://mmonit.com/monit
- 文档：https://mmonit.com/monit/documentation/monit.html
- [Monit](https://mmonit.com/monit/)是一个开源工具(单机)，[M/Monit](https://mmonit.com/download/)(集中管理)是基于其的收费企业版
    - `yum install monit`
    - mac端可下载安装包，安装在`/usr/local/monit`，可访问`http://localhost:2812/`查看可视化监控页面(admin/monit)
- 相关文章
    - Monit与Supervisor对比 https://www.jianshu.com/p/4180374e1a34
    - Monit使用
        - https://github.com/freeaquar/notebook/blob/master/%E8%BF%90%E7%BB%B4%E7%9B%B8%E5%85%B3/Monit-%E7%AC%94%E8%AE%B0.md
        - https://blog.csdn.net/qin_weilong/article/details/90639769
- 命令

```bash
# 重启
systemctl restart monit
# 日志
cat /var/log/monit.log

monit -V # 查看版本
monit # 启动monit
monit status # 查看所有监控状态
monit status nginx # 查看nginx服务状态
monit stop all # 停止所有服务
monit stop nginx # 停止nginx服务
monit start all # 启动所有服务
monit start nginx # 启动nginx服务
monit reload # 重载配置文件
monit -t # 配置命令检测

# 主配置文件
/etc/monitrc
# 配置文件说明 START
set daemon 120 # 默认是每120秒检查一下被监视的程序状态
include /etc/monit.d/* # 去掉包含子配置的注释
# 配置文件说明 EDN

# 单独配置各项服务
/etc/monit.d/
```
- `/etc/monit.d/ofbiz` 案例

```bash
check host mydemo with address localhost
if failed
   port 80
   protocol http
   request /test/control/monit-check
   and status = 200 # 默认超时时间5s(NETWORKTIMEOUT)
   for 3 cycles # 连续3个周期符合条件
then exec "/root/script/monit-ofbiz.sh yard restart"
repeat every 20 cycles # 每20个周期循环1次
alert admin@example.com
```
- `/root/script/monit-ofbiz.sh`

```bash
#!/bin/bash

TMP_FILE=/root/script/tmp-monit-ofbiz-$1
psid=0

checkpid() {
  echo 0 > $TMP_FILE
  jps | grep -v Jps | while read -r pid name
  do
    dir=$(pwdx $pid)
    reg="/home/$1$"
    if [[ "$dir" =~ $reg ]]; then
      echo $pid > $TMP_FILE
    fi
  done
  read psid < $TMP_FILE
}

start() {
    checkpid $1
    if [ $psid -eq 0 ]; then
      nohup bash /home/$1/tools/startofbiz.sh > /dev/null 2>&1 &
    fi

    rm -f $TMP_FILE
}

stop() {
    checkpid $1

    if [ $psid -ne 0 ]; then
        bash /home/$1/tools/stopofbiz.sh
        sleep 5

        if [ $psid -ne 0 ]; then
          kill -s 9 $psid
          sleep 1
        fi

        checkpid $1
        if [ $psid -ne 0 ]; then
            stop $1
        fi
    fi

    rm -f $TMP_FILE
}

case "$2" in
    'start')
                start $1
                ;;
    'stop')
                stop $1
                ;;
    'restart')
                stop $1
                start $1
                ;;
        *)
                echo "[info] Usage: $0 <app-name> {start|stop|restart}"
                exit 1
esac

exit $?
```

## Supervisor进程管理

- `Supervisor` 是用Python开发的一个client/server服务，是Linux/Unix系统下的一个进程管理工具。可以很方便的监听、启动、停止、重启一个或多个进程。用supervisor管理的进程，**当一个进程意外被杀死，supervisor监听到进程死后，会自动将它重启**，很方便的做到进程自动恢复的功能，不再需要自己写shell脚本来控制
- 使用

```bash
## 安装
yum install -y supervisor
systemctl enable supervisord --now && systemctl status supervisord

## 创建守护进程配置文件
cat > /etc/supervisord.d/node_exporter.ini << EOF
[program:node_exporter]
# 执行 command 之前，先切换到工作目录
# directory=/opt/test
# 执行(启动)命令
command=/usr/sbin/node_exporter
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/node_exporter.log
log_stderr=true
user=root
EOF
supervisorctl update && supervisorctl status

## 命令
supervisorctl status        # 查看监控程序状态
supervisorctl update        # 根据最新的配置文件，启动新配置或有改动的进程，配置没有改动的进程不会受影响而重启
supervisorctl reload        # 载入最新的配置文件，停止原有进程并按新的配置启动、管理所有进程
supervisorctl restart all   # 手动重启所有
supervisorctl stop node_exporter # 停止进程node_exporter(尽管设置了supervisor自动重启，此时也不会重启；supervisor自动重启只针对意外退出)
supervisorctl start node_exporter # 启动进程node_exporter
```

## nssm(windows守护进程工具)

- https://www.xjx100.cn/news/282761.html
