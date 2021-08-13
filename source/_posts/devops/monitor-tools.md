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

- Monit与Supervisor对比 https://www.jianshu.com/p/4180374e1a34
- Monit使用 https://github.com/freeaquar/notebook/blob/master/%E8%BF%90%E7%BB%B4%E7%9B%B8%E5%85%B3/Monit-%E7%AC%94%E8%AE%B0.md
- https://blog.csdn.net/qin_weilong/article/details/90639769

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

