---
layout: "post"
title: "LVS"
date: "2018-03-04 17:45"
categories: arch
tags: [LB, HA]
---

## 简介

- `LVS`是`Linux Virtual Server`的简称，也就是Linux虚拟服务器
- 负载均衡解决方案主要分为硬件层面和软件层面
    - 硬件如：F5等(一台一般15万)
    - **软件可分为第四层和第七层协议**
        - 第四层如：`lvs`
            -  LVS 在实现上，介于网络层（IP）和传输层（TCP）之间；只能操作ip和端口，在操作系统内核中
        - 第七层(应用层：http/ajp/https)如：`nginx`、`httpd`(apache)、`haproxy`
- Lvs的组成包括 `ipvs` 和 `ipvsadm`
    - ipvs(ip virtual server)：一段代码工作在内核空间，叫ipvs(所有的linux都有此功能)
    - ipvsadm：另外一段是工作在用户空间，叫ipvsadm，负责为ipvs内核框架编写规则，定义谁是集群服务，而谁是后端真实的服务器(Real Server)。安装`yum install ipvsadm -y`
- lvs默认是用的`wlc`调度算法：会根据后端 RS 的连接数来决定把请求分发给谁，比如 RS1 连接数比 RS2 连接数少，那么请求就优先发给 RS1。并考虑权重
- 相关术语
    - `DS`：Director Server。指的是前端负载均衡器节点
    - `RS`：Real Server。后端真实的工作服务器
    - `VIP`：向外部直接面向用户请求，作为用户请求的目标的IP地址
    - `DIP`：Director Server IP，主要用于和内部主机通讯的IP地址
    - `RIP`：Real Server IP，后端服务器的IP地址
    - `CIP`：Client IP，访问客户端的IP地址

## LVS的DR模式原理 [^1]

![LVS/NAT](/data/images/arch/lvs-nat.png)

- 当用户请求到达Director Server，此时请求的数据报文会先到内核空间的PREROUTING链。 此时报文的源IP为CIP，目标IP为VIP 
- PREROUTING检查发现数据包的目标IP是本机，将数据包送至INPUT链
- IPVS比对数据包请求的服务是否为集群服务，若是，修改数据包的目标IP地址为后端服务器IP，然后将数据包发至POSTROUTING链。 此时报文的源IP为CIP，目标IP为RIP 
- POSTROUTING链通过选路，将数据包发送给Real Server
- Real Server比对发现目标为自己的IP，开始构建响应报文发回给Director Server。 此时报文的源IP为RIP，目标IP为CIP 
- Director Server在响应客户端前，此时会将源IP地址修改为自己的VIP地址，然后响应给客户端。 此时报文的源IP为VIP，目标IP为CIP

## LVS的DR模式实践

### 基本说明

- 请求流程
    - CIP-VIP的请求数据包发送到DS**(所以此时DS必须绑定可访问的VIP)**RIP-CIP的返回
    - CIP-RIP的请求数据包发送到RS(通过DS转发)
        - RIP-CIP的响应数据包可从RS发送，但是客户端不会接受，因为CIP请求的是VIP。所有必须是RS响应VIP-CIP的数据包(相当于IP欺骗)
    - VIP-CIP的响应数据包由RS返回到客户端**(所以此时RS必须绑定隐藏的VIP)**
- 上述流程中DS和RS都绑定的VIP，但是一个网络中不能有两台机器同时绑定一个IP。但是RS是隐藏的VIP，**隐藏VIP的前提是：不对外广播和不对外响应**
- 通过修改以下内核参数来隐藏RS的VIP
    - `arp_ignore`：定义接收到ARP请求时的**响应级别**
        - 0：只要在本地配置的有相应地址，就给予响应(默认)
        - 1：仅在请求的目标MAC地址与请求的网络接口匹配时，才给予响应(mac地址和ip地址匹配时才响应；lvs设置此级别)
    - `arp_announce`：定义将自己地址向外**通告级别**
        - 0：将本地任何接口上的任何地址向外通过(默认)
        - 1：试图仅向目标网络通告与其网络匹配的地址
        - 2：仅向与本地接口MAC地址匹配的网络进行通告(mac地址和ip地址匹配时才通告；lvs设置此级别)
- 步骤(可将以下步骤封装成脚本)
    - 对DS创建网络接口并绑定VIP
    - 对所有RS隐藏VIP(进行网络配置)
    - 对所有RS绑定VIP(必须先隐藏在进行绑定，因为绑定的一瞬间就会对外通告)
    - 对所有RS修改其VIP路由
    - 通过ipvsadm进行相关配置
- `ip addr` 查看网络接口(其中`lo`不对外进行通信，`ens33`/`eth0`会对外通信)
- 所需服务器列表(需要在同一网段)
    - Director节点：(ens33 192.168.6.134 vip ens33:0 192.168.6.120)
    - Real server1：(ens33 192.168.6.131 vip lo:0 192.168.6.120)
    - Real server2：(ens33 192.168.6.132 vip lo:0 192.168.6.120)
- **重启服务器后RS的配置都丢失？？？**

### 步骤

- 对DS(192.168.6.134)创建网络接口并绑定VIP：`ifconfig ens33:1 192.168.6.120`
- 对RS(`192.168.6.131`、`192.168.6.132`)隐藏VIP

    ```bash
    # 修改arp_ignore的值为1(proc目录为内核映射文件，修改此目录的文件就会修改内存数据)
    # ens33为对应网卡接口名称(也可能为eth0等)
    echo "1" > /proc/sys/net/ipv4/conf/ens33/arp_ignore
    echo "1" > /proc/sys/net/ipv4/conf/all/arp_ignore
    echo "2" > /proc/sys/net/ipv4/conf/ens33/arp_announce
    echo "2" > /proc/sys/net/ipv4/conf/all/arp_announce
    ```
- 对所有RS绑定VIP：`ifconfig lo:1 192.168.6.120 netmask 255.255.255.255 broadcast 192.168.6.120`(所有RS命令一致)
    - 此处故意输入一个错误的子网掩码`255.255.255.255`，防止此ip对外通信
    - 前后输入`ifconfig`进行查看对比
- 对所有RS修改其VIP路由：`route add -host 192.168.6.120 lo:1`(所有RS命令一致)
    - 前后输入`route`进行查看对比
- 通过ipvsadm进行相关配置
    - 在DS(192.168.6.134)上安装`yum install ipvsadm -y`
    - 在DS上进行如下配置

        ```bash
        # -A：Add a virtual service; -t：tcp协议; -s rr：调度算法为wlc
        ipvsadm -A -t 192.168.6.120:80 -s wlc
        # -a：Add a real server to a virtual service; -r：real server配置; -g：使用DR模式
        ipvsadm -a -t 192.168.6.120:80 -r 192.168.6.131 -g
        ipvsadm -a -t 192.168.6.120:80 -r 192.168.6.132 -g
        ```
    - ipvsadm其他命令
        - `ipvsadm -ln` 查看lvs配置
        - `ipvsadm -lnc` 查看lvs分发记录

### 测试

- 修改RS(`192.168.6.131`、`192.168.6.132`)的nginx安装目录下`html/50x.html`文件，分别加入`<h1>server1</h1>`和`<h1>server2</h1>`(前提是通过 http://192.168.6.131/50x.html 可访问到对应的文件)
- 访问`http://192.168.6.120/50x.html`观察显示页面

## LVS结合keepalive

- **LVS可以实现负载均衡，但是不能够进行健康检查**，比如一个rs出现故障，LVS 仍然会把请求转发给故障的rs服务器，这样就会导致请求的无效性。**keepalive 软件可以进行健康检查，而且能同时实现 LVS 的高可用性，解决 LVS 单点故障的问题**。其实 keepalive 就是为 LVS 而生的。



---

参考文章

[^1]: [使用LVS实现负载均衡原理及安装配置详解](https://www.cnblogs.com/liwei0526vip/p/6370103.html)