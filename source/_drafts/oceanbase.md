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
    - ODC: OceanBase开发者中心，对数据库&表进行管理
    - OMS: OceanBase 数据迁移，对数据进行快速迁移

## 启动/停止

```bash
obd cluster list
# 重启demo集群的所有服务
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
```
- **(推荐)通过 obd 白屏部署 OceanBase 集群**

```bash
# 参考: https://www.oceanbase.com/docs/common-oceanbase-database-cn-1000000001052852
# 支持在线部署和离线部署(提前下载 all-in-one 安装包)
tar -xzf oceanbase-all-in-one-*.tar.gz -C /opt
cd /opt/oceanbase-all-in-one/bin/
./install.sh
source ~/.oceanbase-all-in-one/bin/env.sh

# 启动白屏界面
obd web
# 虽然是集群部署，但是也支持只设置一台服务器；安装完成后会显示链接信息
```



