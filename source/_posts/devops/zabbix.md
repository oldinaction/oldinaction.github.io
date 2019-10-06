---
layout: "post"
title: "Zabbix"
date: "2019-09-30 16:13"
categories: devops
tags: [monitor]
---

## 简介

- `Zabbix` [zæbiks] 是一个高度集成的企业级开源网络监控解决方案，与Cacti、nagios类似，提供分布式监控以及集中的web管理界面。支持主机性能监控，网络设备性能监控，数据库性能监控，ftp等通用协议的监控，能够灵活利用可定制警告机制，允许用户对事件发送基于E-mail的警告
- [官方中文文档 v4.0](https://www.zabbix.com/documentation/4.0/zh/manual)
- Zabbix架构图

    ![zabbix](/data/images/devops/zabbix.png)
- Zabbix实现监控的两种模式(在agent的角度)
    - 主动模式：由Agent主动建立TCP链接并向Server端发送请求
    - 被动模式：由Server建立TCP链接并向Agent端发送请求
- Zabbix proxy 使用场景
    - 监控远程区域设备
    - 当 zabbix 监控上千设备时，使用它来减轻 server 的压力
- zabbix-server和zabbix-proxy默认监听端口10051，zabbix-anget默认监听端口10050
- 告警支持：邮件、Jabber(Linux即时通讯框架)、SMS短信、执行脚本等

## 安装

- 安装
    - 日志位于`/var/log/zabbix/zabbix_server.log`、`/var/log/zabbix/zabbix_proxy.log`、`/var/log/zabbix/zabbix_agentd.log`
    - 配置文件位于`/etc/zabbix/zabbix_server.conf`、`/etc/zabbix/zabbix_proxy.conf`、`/etc/zabbix/zabbix_angetd.conf`

```bash
## 参考：https://www.zabbix.com/documentation/4.0/zh/manual/installation/install_from_packages/rhel_centos
## 添加Zabbix包。https://repo.zabbix.com/
rpm -Uvh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
# yum-config-manager --enable rhel-7-server-optional-rpms

## 安装Zabbix server 和 proxy(均基于mysql，但是并不包含安装mysql服务)
yum install -y zabbix-server-mysql
# zabbix-proxy可选安装
yum install -y zabbix-proxy-mysql
yum install -y zabbix-web-mysql # 会安装httpd、php

## 导入初始数据到数据库
# 对于 Zabbix server 和 proxy 守护进程而言，数据库是必须的。而运行 Zabbix agent 是不需要的。(如果 Zabbix server 和 Zabbix proxy 安装在相同的主机，它们必须创建不同名字的数据库！)
yum install -y mariadb.x86_64 mariadb-libs.x86_64 # 安装mysql客户端
# mysql服务器在另外一台机器上(192.168.6.1)，且已创建用户zabbix/zabbix可访问数据zabbix、zabbix_proxy
# 使用 MySQL 来导入 Zabbix server 和 proxy 的初始数据库 schema 和数据。导入时间较长，可多回车几次看看
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -h 192.168.6.1 -uzabbix -p zabbix
zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz | mysql -h 192.168.6.1 -uzabbix -p zabbix_proxy

## 修改Zabbix server 和 proxy的DBHost、DBName、DBUser、DBPassword
vi /etc/zabbix/zabbix_server.conf
vi /etc/zabbix/zabbix_proxy.conf

## 启动 Zabbix server 和 proxy 进程
systemctl enable zabbix-server && systemctl restart zabbix-server && systemctl status zabbix-server
# zabbix-proxy默认配置的监听端口和zabbix-server是一样都为10051，如果安装在一台机器上则需要修改监听端口
systemctl enable zabbix-proxy && systemctl restart zabbix-proxy && systemctl status zabbix-proxy

## Zabbix web 配置
# 修改`# php_value date.timezone Europe/Riga`为`php_value date.timezone Asia/Shanghai`
vi /etc/httpd/conf.d/zabbix.conf
systemctl enable httpd && systemctl restart httpd && systemctl status httpd
# 浏览器访问 http://192.168.6.131/zabbix 进行配置。Database安装上文配置；Zabbix server配置中hostname填写zabbix server ip，port默认10051，name可选
# 登录：Admin/zabbix
# 稍等片刻可看见`Zabbix agent on Zabbix server is unreachable for 5 minutes`的警告，在Zabbix server也按照zabbix-agent即后可发现此警告一会便会消失

## 在Server所在节点上安装 Agent
yum install -y zabbix-agent
systemctl enable zabbix-agent && systemctl restart zabbix-agent && systemctl status zabbix-agent
```

- **添加一个Agent**(监控另外一台机器)

```bash
# 安装包
rpm -Uvh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-agent-4.0.12-1.el7.x86_64.rpm
# rpm -e zabbix-agent-4.0.12-1.el7.x86_64 # 卸载包
yum install -y zabbix-agent
# 修改 Server=192.168.6.131 和 ServerActive=192.168.6.131:10051 (即配置server/proxy的地址)
vi /etc/zabbix/zabbix_angetd.conf
# 启动
systemctl enable zabbix-agent && systemctl restart zabbix-agent && systemctl status zabbix-agent
```
- 服务器检测连通性(可选)

```bash
# zabbix服务端安装工具
yum install -y zabbix-get
# 在服务端测试。-s、-p要测试的agent对应ip和端口
zabbix_get -s 192.168.6.132 -p 10050 -k "system.cpu.load[all,avg1]"
```

## 使用

### 管理面板使用

- 用户中心
    - 可修改语言
    - 可配置媒介(Media)用来接收警告信息，如接收告警的邮箱。如果通过脚本发送邮件，如下文的SendEmailScript，则需要给用户配置对应类型的媒体介质。如果此用户SendEmailScript配置了多个接收邮箱，则会给所以配置的邮箱发送邮件
- 监控一台主机：配置 - 主机 - 创建主机
    - 主机tab菜单
        - 主机群组选择如`Linux servers`
        - agent代理程序的接口如`192.168.6.132:10050`
        - 勾选`已启用`
    - 模板tab菜单
        - 选择`Template OS Linux`(还可在配置-模板中导入模板)
        - 点击`添加` - 点击`更新`
- 创建仪表盘：监测 - 仪表盘 - 添加仪表盘 - 创建仪表盘 - 然后再添加构件
    - 类型`图表(经典)` - 图形选择`CPU load` - 可修改名称后添加 - 可在某一agent上执行`while true; do echo 1; done`观察CPU load图表的变化(升高)
- 设置报警媒介(Media types)：管理(Administration) - 报警媒介类型 - 创建媒介 [^2]
    - 邮件发送参考 [http://blog.aezo.cn/2017/01/10/linux/CentOS%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E/](/_posts/linux/CentOS服务器使用说明.md#邮件发送服务配置)
    - 基于外部邮件服务
        - 媒体名称`SendEmailScript`
        - 类型选择脚本，`/usr/lib/zabbix/alertscripts/sendmail.sh`脚本文件内容如下(`/usr/lib/zabbix/alertscripts`为zabbix server脚本目录，可在配置文件中查看)

            ```bash
            ## 安装及配置mailx
            # whereis mailx 或者 whereis mail

            ## vi /usr/lib/zabbix/alertscripts/sendmail.sh
            #!/bin/bash
            messages=`echo $3 | tr '\r\n' '\n'`
            subject=`echo $2 | tr '\r\n' '\n'`
            echo "${messages}" | mail -s "${subject}" -c "aezocn@163.com" $1 >> /tmp/sendmail.log 2>&1 # 163邮箱容易出现554检测到垃圾拒发问题，此处使用-c抄送给自己可解决

            ## 参数说明
            #$1 代表收件人，也就是对应参数 {ALERT.SENDTO}
            #$2 代表邮件主题，也就是对应参数 {ALERT.SUBJECT}
            #$3 代表邮件内容，也就是对应参数 {ALERT.MESSAGE}

            ## 设置文件所属
            chown zabbix.zabbix /usr/lib/zabbix/alertscripts/sendmail.sh
            chmod +x /usr/lib/zabbix/alertscripts/sendmail.sh
            # (可选)修改用户登入后所使用的shell，并切换到zabbix用户看脚本是否可以正常发送
            # usermod -s /bin/bash zabbix
            # su - zabbix
            # usermod -s /sbin/nologin zabbix
            ```
        - 脚本名称为`sendmail.sh`
        - 依次添加参数`{ALERT.SENDTO}`、`{ALERT.SUBJECT}`、`{ALERT.MESSAGE}`
    - 基于本地邮件服务(直接配置163邮箱的smtp会报错)
        - 类型选择Email；SMTP server和SMTP helo为`node1.localdomain`；SMTP email为`zabbix@node1.localdomain`；设置无需认证

### 自定义监控(登录用户数)

- 自定义监控key [^1]

```bash
# agent端操作
# 语法：`UserParameter=<key>,<shell command>`。key名字要唯一，多个key以行为分割
cat > /etc/zabbix/zabbix_agentd.d/userparameter_aezo_login.conf <<EOF
UserParameter=login-user,who|wc -l
EOF
systemctl restart zabbix-agent

# 服务端获取
zabbix_get -s 192.168.6.132 -p 10050 -k "login-user"
```
- 在server端注册(web操作)
    - 创建模板(Templates)：配置 - 模板 - 创建模板 - 名称`Template User Login`, 群组`Template`
    - 创建应用集(Applications)
        - 在此模板编辑界面 - 点击应用集 - 创建应用集，如`安全`
        - 应用集类似目录/文件夹，其作用是给监控项分类
    - 创建监控项(Items)
        - 在此模板编辑界面 - 监控项 - 创建监控项
        - 名称`User Login Count`(中文则图表乱码)；键值`login-user`(自定义key直接手动输入，标准key可进行选择)；应用集选择`安全`
        - 一个账号多开几个ssh连接则`who|wc -l`会统计成多个，可如此进行测试
    - 创建触发器(Triggers)
        - 在此模板编辑界面 - 触发器 - 创建触发器
        - 名称`User Login Count Rise`(中文则图表乱码)；表达式`{Template Login User:login-user.last()}>1`
        - 触发器的作用：当监控项获取到的值达到一定条件时就触发报警
    - 创建图形(Graphs)
        - 在此模板编辑界面 - 图形 - 创建图形
        - 名称`登录用户数`；监控项选择`Template User Login: User Login Count`；可进行预览
    - 主机关联模板
        - 配置 - 主机(一个主机可以关联多个模板)
    - 在仪表板盘中添加此构件
        - 可在`图表(经典)`类型的图表中找到`登录用户数`
    - 设置动作(Actions)
        - 配置 - 动作 - 创建动作
        - 动作名称`User Login Count Rise Email`；触发条件如`A 触发器 等于 Aezo node2: User Login Count Rise`；操作如`发送消息给用户: Admin (Zabbix Administrator) 通过 SendEmailScript`(相当于出现问题给administrators群组发警告，通过邮件脚本的方式发送，且需要zabbix用户在个人中心配置接收邮箱)
        - 出现一定现象(触发器生效)可执行命令或发送邮件






---

参考文章

[^1]: https://www.cnblogs.com/clsn/p/7885990.html#auto_id_34
[^2]: https://www.linuxidc.com/Linux/2018-08/153666.htm

