---
layout: "post"
title: "VPN搭建"
date: "2018-04-04 10:34"
categories: extend
tags: [vpn, linux]
---

## centos7安装vpn

### pptp

- `sudo modprobe ppp-compress-18 && echo MPPE is ok` 验证内核是否加载了MPPE模块
- `sudo yum -y install ppp pptpd iptables-services` 安装ppp、pptpd、iptables(安装前确保添加了epel源)
    - `iptables`主要用来NAT规则
- `sudo vi /etc/ppp/options.pptpd` 配置PPP和PPTP的配置文件。查找`ms-dns`，添加两行

    ```bash
    # Google DNS
    ms-dns 8.8.8.8
    ms-dns 8.8.4.4
    # 或者使用 Aliyun DNS
    # ms-dns 223.5.5.5
    # ms-dns 223.6.6.6
    ```
- `sudo vi /etc/ppp/chap-secrets` 配置登录用户/协议/密码/ip地址段

    ```bash
    username1    pptpd    passwd1    *
    test    pptpd    ok123456    *
    ```
- `sudo vi /etc/pptpd.conf` 配置pptpd。localip是服务端的虚拟地址, remoteip是客户端的虚拟地址。只要不和本机IP不冲突即可(在末尾添加)

    ```bash
    localip 192.168.0.2-20
    remoteip 192.168.0.200-250
    ```
- `sudo vi /etc/sysctl.conf` 改为`net.ipv4.ip_forward = 1`
- `sudo sysctl -p` 使sysctl配置生效
- `sudo systemctl start pptpd` 启动pptpd服务
- 配置iptables防火墙放行和转发规则
    - **`sudo iptables -L -n -t nat`** 查看 iptables 配置规则
    - 清空防火墙配置
        
        ```bash
        sudo iptables -P INPUT ACCEPT        # 改成 ACCEPT 标示接收一切请求
        sudo iptables -F                     # 清空默认所有规则
        sudo iptables -X                     # 清空自定义所有规则
        sudo iptables -Z                     # 计数器置0
        ```
    - 可以不用开启防火墙的端口拦截，其主要用iptables来进行nat网关配置，因此下面的配置只需要运行 `sudo iptables -t nat -A POSTROUTING -o eth0 -s 192.168.0.0/24 -j SNAT --to 114.55.1.1` (eth0为网卡。表示在postrouting链上，将源地址为192.168.0.0/24网段的数据包的源地址都转换为114.55.1.1)
    - 配置规则(可省略)

        ```bash
        sudo iptables -A INPUT -p gre -j ACCEPT
        # 放行 PPTP 服务的1723 端口 (服务器后台安全组策略需要开发1723的入站规则)
        sudo iptables -A INPUT -p tcp -m tcp --dport 1723 -j ACCEPT
        sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
        # 阿里云是双网卡，内网eth0 + 外网eth1，所以此出为eth1
        sudo iptables -A FORWARD -s 192.168.0.0/24 -o eth1 -j ACCEPT
        sudo iptables -A FORWARD -d 192.168.0.0/24 -i eth1 -j ACCEPT
        sudo iptables -I FORWARD -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1356
        # nat规则，如果没有外网网卡，可设置外网IP。如：iptables -t nat -A POSTROUTING -o eth0 -s 192.168.0.0/24 -j SNAT --to 114.55.1.1
        sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE
        # 开启几个常用端口，其他端口同理
        sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        ```
    - 启动iptables
        
        ```bash
        sudo service iptables save
        sudo systemctl start iptables
        ```
- 设置随系统启动(`chkconfig --level 3 pptpd on`)
    - `sudo systemctl enable pptpd`
    - `sudo systemctl enable iptables`
- windows连接VPN
    - VPN类型 `PPTP`
    - 勾选允许使用 `Microsoft CHAP 版本 2 （MS-CHAP v2）（M）`

### IPSec/L2TP

- https://teddysun.com/448.html
- https://github.com/kitten/setup-strong-strongswan   

---

参考文章

[^1]: https://blog.itnmg.net/2013/05/19/vps-pptp-vpn/ (CentOS-VPS建立PPTP-VPN服务)
[^2]: https://blog.csdn.net/ithomer/article/details/52138961 (阿里云CentOS7搭建VPN)
[^3]: https://help.aliyun.com/knowledge_detail/40697.html (ECS-Windows服务器VPN连接报错:错误628解决方法)
[^4]: https://blog.itnmg.net/2015/04/03/centos7-ipsec-vpn/ (CentOS7配置IPSec-IKEv2-VPN)

