---
layout: "post"
title: "OceanBase数据库"
date: "2024-08-29 19:11"
categories: db
tags: [db, 信创]
---

## 简介

- [开源官网](https://www.oceanbase.com/product/opensource)、[文档](https://www.oceanbase.com/docs/oceanbase-database-cn)
- OceanBase 是蚂蚁集团自研的金融级分布式数据库，2019 年开源，2023 年正式发布 4.0 版本
- 企业版兼容Mysql、Oracle，[开源版](https://github.com/oceanbase/oceanbase)兼容Mysql
- 相关定义
    - OBD (OceanBase Deployer): OceanBase 部署工具，用于部署和管理 OceanBase 集群
    - OCP (OceanBase Cloud Platform): OceanBase 云平台，提供了基础的主机管理、OceanBase 集群和租户运维等能力
        - OCP Express: 提供基础的主机管理、OceanBase 集群和租户运维等能力
    - ODC: OceanBase 开发者中心，对数据库&表进行管理
    - OMS: OceanBase 数据迁移，对数据进行快速迁移

## 启动/停止

```bash
obd cluster list
# 重启demo集群的所有服务(myoceanbase), 预计2-3min
obd cluster restart demo
```

## 安装

```bash
# 参考《OceanBase 数据库社区版部署概述》: https://www.oceanbase.com/docs/common-oceanbase-database-cn-1000000001050084
# 软硬件要求: https://www.oceanbase.com/docs/common-oceanbase-database-cn-1000000001050548
    # 如: CentOS 7.x、KylinOS V10 版本、统信 UOS V20 版本
    # demo单机部署最低2C及6G可用内存；部署 OceanBase 数据库及全部组件，至少需要 4vCPU、10 GB 内存、25 GB 磁盘的可用资源，推荐内存在 16 GB 以上
# 支持: obd白屏(推荐, 类似WordPress一样通过浏览器界面部署)、命令行(obd黑屏)、systemd(不建议用于生产)、容器(不建议用于生产)等几种部署方式
# 社区版只兼容Mysql
# 安装后通过此命令查看数据库版本如: 5.7.25-OceanBase_CE-v4.2.1.8
select version();
```
- (仅演示环境)快速开始

```bash
## 快速开始(部署demo环境, 最低2C及6G可用内存): https://www.oceanbase.com/docs/common-oceanbase-database-cn-1000000000217958 文中方案一
# 下载一键安装脚本(基于最新LTS源仓库, 当前为v4.2.1)
sudo bash -c "$(curl -s https://obbusiness-private.oss-cn-shanghai.aliyuncs.com/download-center/opensource/service/installer.sh)"

# 部署单机demo环境. 如果报错执行对应配置修改参数重新运行安装即可
obd demo # obd web 基于白屏界面部署集群环境(3台机器)

# 安装成功会显示启动的组件: observer(2881和2882)/obproxy(2883和2884)/obagent(8089和8088)/prometheus(9090)/grafana(3000) 及相关端口和账号信息
# 也可通过 obd cluster display demo 查看部署信息
# 默认连接的是sys租户(即用户名为root@sys，如果是连接其他租户如saas1则用户名为root@saas1)；密码默认是空
obclient -h127.0.0.1 -P2881 -uroot -Doceanbase -A # 连接observer(直连数据库)
obclient -h127.0.0.1 -P2883 -uroot -Doceanbase -A # 连接obproxy(通过 ODP 代理访问数据库)

# 支持Mysql客户端(需单独安装) / OBClient(默认安装) / ODC(OceanBase开发者中心,需单独部署,在web界面上操作) / JDBC链接如下
jdbc:mysql://192.168.1.100:2881/test?serverTimezone=Asia/Shanghai&useUnicode=true&useSSL=false&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&allowPublicKeyRetrieval=true
# 其他客户端
Navicat: 直接连接(使用的8.0驱动测试)
DBeaver: 连接的时候Tenant需要填写一个租户名(如: sys)
```
- **(推荐)通过 obd 白屏部署 OceanBase 集群**

```bash
## 需要开放端口: 8680(obd web白屏界面) 2881|2882(observer, 数据库端口) 2883|2884(OBProxy) 8180(OCP Express, 管理端)

## 参考: https://www.oceanbase.com/docs/common-oceanbase-database-cn-1000000001052852
# 部署数据库 - 部署 OceanBase 社区版 - 本地部署 - 通过图形化界面部署 - 通过 obd 白屏部署 OceanBase 集群
# 支持在线部署和离线部署(离线需提前下载 all-in-one 安装包)
# v4.3.3 x86-el7: https://obbusiness-private.oss-cn-shanghai.aliyuncs.com/download-center/opensource/oceanbase-all-in-one/7/x86_64/oceanbase-all-in-one-4.3.3_20241014.el7.x86_64.tar.gz
# v4.3.3 arm-el7: https://obbusiness-private.oss-cn-shanghai.aliyuncs.com/download-center/opensource/oceanbase-all-in-one/7/aarch64/oceanbase-all-in-one-4.3.3_20241014.el7.aarch64.tar.gz
tar -xzf oceanbase-all-in-one-*.tar.gz -C /opt
cd /opt/oceanbase-all-in-one/bin/
./install.sh
source ~/.oceanbase-all-in-one/bin/env.sh

## 启动白屏界面
# 虽然是集群部署，但是也支持只设置一台服务器；安装完成后会显示链接信息
obd web
# 访问 http://127.0.0.1:8680
    # 开启体验之旅 - OceanBase 及配套工具 - 勾选 OBProxy(也可全部勾选)
    # OBServer 节点: 输入节点ip(如当前内网ip)
    # 部署用户配置: 输入服务器SSH对应的用户登录信息
    # 软件路径: 如/opt/oceanbase
# 预检前可执行一下配置, 也可等预检报错再手动执行
echo -e "* soft nofile 20000\n* hard nofile 20000" >> /etc/security/limits.d/nofile.conf
echo -e "* soft nproc 120000\n* hard nproc 120000" >> /etc/security/limits.d/nproc.conf

## 设置开机自动启动
cat > /etc/init.d/oceanbase << EOF
#!/bin/sh
# chkconfig: 2345 50 50
# description: 启动myoceanbase
# processname: common-init

su - root -c '/usr/bin/obd cluster start myoceanbase'
EOF
chmod +x /etc/init.d/oceanbase
chkconfig --add /etc/init.d/oceanbase

## 使用
# 租户管理 - 选择 sys 租户 - 数据库管理 - 新建数据库. 或者通过Navicat连接root@sys(2881)然后创建数据库
```



