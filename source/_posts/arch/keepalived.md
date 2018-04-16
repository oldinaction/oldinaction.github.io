---
layout: "post"
title: "keepalived"
date: "2018-03-03 17:24"
categories: [arch]
tags: [keepalived]
---

## 简介

- [Keepalived](http://www.keepalived.org/)是一个免费开源的，用C编写的类似于layer3, 4 & 7交换机制软件，具备我们平时说的第3层、第4层和第7层交换机的功能。主要提供loadbalancing（负载均衡）和 high-availability（高可用）功能，负载均衡实现需要依赖Linux的虚拟服务内核模块（ipvs），而高可用是通过`VRRP`协议实现多台机器之间的故障转移服务

## 安装使用

- `yum -y install keepalived`
- 源码安装 [^1]
- `systemctl start keepalived` 启动**(需要关闭`SELinux`)**
    - 启动后自动绑定虚拟ip，通过`ip addr`可查看绑定的虚拟ip

## keepalived.conf配置说明

- 文件位置 `/etc/keepalived/keepalived.conf`
- keepalived配置文件主要包含三块：全局定义块、VRRP实例定义块、虚拟服务器定义块（如果keepalived只用来做ha，虚拟服务器是可选的）
- 配置说明 [^1]

```bash
### 全局定义块
global_defs {
    ## 邮件通知配置：用于服务有故障时发送邮件报警，可选项，不建议用。需要系统开启sendmail服务，建议用第三独立监控服务，如用nagios全面监控代替
    notification_email {
        # 一行一个收件人
        email1@aezo.cn
        email2@aezo.cn
    }
    # 发件人
    notification_email_from admin@aezo.cn
    smtp_server XXX.smtp.com
    # 指定smtp连接超时时间
    smtp_connect_timeout 30

    # lvs负载均衡器标识，在一个网络内，它的值应该是唯一的
    lvs_id string
    # 用户标识本节点的名称，通常为hostname
    router_id server1.aezocn
}

### VRRP实例定义块：同步vrrp级，用于确定失败切换（FailOver）包含的路由实例个数。即在有2个负载均衡器的场景，一旦某个负载均衡器失效，需要自动切换到另外一个负载均衡器的实例是哪
vrrp_sync_group string {
    # 至少要包含一个vrrp实例，vrrp实例名称必须和vrrp_instance定义的一致
    group {
        VI_1
    }
}

# vrrp服务检测脚本：keepalived默认是通过检测keepalived进程是否存在判断服务器是否宕机。此时根据脚本判断是否杀死此服务器keepalived进程。参考《nginx》中【结合keepalived实现高可用】
vrrp_script check_nginx.sh {
    #检测nginx的脚本
    script "/etc/keepalived/check_nginx.sh"
    #每2秒检测一次
    interval 2
    #如果某一个nginx宕机 则权重减20                              
    weight -20
}

# vrrp实例名(VI_1)
vrrp_instance VI_1 {
    # 实例状态，只有MASTER（主）和BACKUP（备）两种状态，并且需要全部大写
    # 抢占模式下，其中MASTER为工作状态，BACKUP为备用状态。当MASTER所在的服务器失效时，BACKUP所在的服务会自动把它的状态由BACKUP切换到MASTER状态。当失效的MASTER所在的服务恢复时，BACKUP从MASTER恢复到BACKUP状态
    state MASTER
    # 对外提供服务的网卡接口，即VIP绑定的网卡接口，如：eth0，eth1
    interface eth0
    # 本机IP地址
    mcast_src_ip 192.168.1.1
    # 虚拟路由的ID号，每个节点设置必须一样，可选择IP最后一段使用，相同的 VRID 为一个组，他将决定多播的 MAC 地址。同一实例下virtual_router_id必须相同（主从要一致）
    virtual_router_id 51
    # 节点优先级，取值范围0～254，MASTER要比BACKUP高
    priority 100
    # MASTER与BACKUP节点间同步检查的时间间隔，单位为秒
    advert_int 1
    # 验证类型和验证密码
    authentication {
        # 类型主要有 PASS、AH 两种，通常使用PASS类型
        auth_type PASS
        # 验证密码为明文，同一 vrrp 实例 MASTER 与 BACKUP 使用相同的密码才能正常通信
        auth_pass 1111
    }
    # 虚拟IP地址池，可以有多个IP，每个IP占一行，不需要指定子网掩码。注意：这个IP必须与我们的设定的vip保持一致
    # 启动后自动给MASTER绑定虚拟ip(MASTER宕机后，则虚拟ip会绑定到BACKUP上)
    virtual_ipaddress {  # Block limited to 20 IP addresses @IP
        # 此虚拟ip为web服务对外提供访问的ip
        192.168.200.1
    }

    # 负载均衡器之间的监控接口,类似于 HA HeartBeat 的心跳线。但它的机制优于 Heartbeat，因为它没有"裂脑"这个问题，它是以优先级这个机制来规避这个麻烦的。在 DR 模式中，lvs_sync_daemon_inteface与服务接口interface使用同一个网络接口
    lvs_sync_daemon_interface string 
    # 配置后，有故障时激活邮件通知
    smtp_alert
    # 禁止抢占服务。默认情况，当MASTER服务挂掉之后，BACKUP自动升级为MASTER并接替它的任务，当MASTER服务恢复后，升级为MASTER的BACKUP服务又自动降为BACKUP，把工作权交给原MASTER。当配置了nopreempt，MASTER从挂掉到恢复，不再将服务抢来
    nopreempt
}

### 虚拟服务器定义块：定义一个虚拟服务器，这个ip是virtual_ipaddress中定义的其中一个
virtual_server 192.168.200.1 8110 {
    #　健康检查时间间隔，单位：秒
    delay_loop 6
    # 负载均衡调度算法，互联网应用常用方式为wlc或rr。取值rr|wrr|lc|wlc|sh|dh|lblc 
    lb_algo rr
    # 负载均衡转发规则。包括DR、NAT、TUN，一般使用路由（DR）转发规则。
    lb_kind DR
    # http服务会话保持时间，单位：秒
    persistence_timeout 50
    # 转发协议，分为TCP和UDP两种
    protocol TCP
    # 真实服务器IP和端口，可以定义多个
    real_server 192.168.200.3 1358 {
        # 负载权重，值越大，转发的优先级越高
        weight 1
        # 服务停止后执行的脚本
        notify_down /path/script.sh
        # 服务有效性检测：HTTP_GET|SSL_CHECK
        HTTP_GET {
            url {
                path /testurl1/test.jsp
                digest 640205b7b0fc66c1ea91c463fac6334d
            }
            # 服务连接端口
            connect_port 80
            # 服务连接超时时长，单位：秒
            connect_timeout 3
            # 服务连接失败重试次数
            nb_get_retry 3
            # 重试连接间隔，单位：秒
            delay_before_retry 3
        }
    }
}
```

## 相关应用

### nginx + keepalived实现高可用

参考`《nginx》`的`【结合keepalived实现高可用】`章节

### 其他

- mysql + keepalived






---

[^1]: [Keepalived安装与配置](http://blog.csdn.net/xyang81/article/details/52554398)