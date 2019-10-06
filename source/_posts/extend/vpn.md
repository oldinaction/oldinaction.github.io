---
layout: "post"
title: "VPN搭建"
date: "2018-04-04 10:34"
categories: extend
tags: [vpn, linux, network]
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
    - 可以不用开启防火墙的端口拦截，其主要用iptables来进行nat网关配置，因此下面的配置只需要运行 `sudo iptables -t nat -A POSTROUTING -o eth0 -s 192.168.0.0/24 -j SNAT --to 114.55.1.100` (eth0为网卡。表示在postrouting链上，将源地址为192.168.0.0/24网段的数据包的源地址都转换为114.55.1.100)
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
        # nat规则，如果没有外网网卡，可设置外网IP。如：iptables -t nat -A POSTROUTING -o eth0 -s 192.168.0.0/24 -j SNAT --to 114.55.1.100
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

### IPSec/L2TP [^4]

- https://teddysun.com/448.html
- https://github.com/kitten/setup-strong-strongswan


## SSH隧道(Tunnel)技术及SOCKET代理

- 背景说明 [^5]
    - 可解决问题：想在家里访问公司的机器(写程序，查数据，下电影)；公司为了防止逛淘宝，封锁了它的端口或者服务器地址(同理如ZF封锁了外网导致无法上油管等)
    - 解决上述问题条件：有一台机器可以访问公司的机器(如处于公司的笔记本)、可以访问淘宝的服务器、可以访问外网的香港主机等；且此服务器有一个公网(IP)端口
    - 机器说明：A为本机、B(234.234.234.234)为目标机(国外服务器或公司内网机器)、C(123.123.123.123)为中间机器(香港服务器或另外一台公司服务器)
- 建立本地SSH隧道：可从内部绕过防火访问外部资源(翻墙)

    ```bash
    # 在C上运行ssh命令
    ssh -N -f -L 2121:234.234.234.234:21 123.123.123.123
        #-N：告诉SSH客户端，这个连接不需要执行任何命令，仅仅做端口转发
        #-f：告诉SSH客户端在后台运行
        #-L：做本地映射端口，被冒号分割的三个部分含义分别是：A端口号、需要访问的目标机器B的IP地址、需要访问的目标机器B的某端口；最后一个参数是用来建立隧道的中间机器C的IP地址
    
    # 访问本地机器A的2121端口，就能连接目标机B的21端口了
    ftp localhost:2121
    ```
- 建立远程SSH隧道：可从外网访问到内网资源(远程办公)
    
    ```bash
    # 在C上运行ssh命令
    ssh -Nf -R 2222:192.168.1.200:22 123.123.123.123 # 把和C处于统一网络的B(192.168.1.200)映射出去，也可以为C自身
        # -R：远程机器A使用的端口（2222）、需要映射的内部机器B的IP地址、需要映射的内部机器B的端口(22)
        # -R X:Y:Z 就是把内部的Y机器的Z端口映射到远程机器的X端口上(Y机器和中间机C处于同一内网，此处填写Y对应的内网)
    
    # 访问本地机器A的2222端口，就能连接目标机B的22端口了
    ssh -p 2222 localhost

    # vmstat 30会定期打印数据，防止某些路由器把长时间没有通信的连接断开；-b 0.0.0.0为绑定本机的2222端口，此时提供本机A所有局域网的其他机器访问A:2222端口
    ssh -b 0.0.0.0 -R 2222:192.168.1.200:22 123.123.123.123 "vmstat 30"
    ```
- 通过SSH隧道建立SOCKS服务器(一台中间机映射一次即可访问指定网络所有服务器的资源。建议)

    ```bash
    # 在中间机C上执行。bindaddress：指定绑定ip地址；port：指定侦听端口；name：ssh服务器登录名；server：ssh服务器地址
    ssh -f -N -D bindaddress:port name@server
    # 将端口绑定在0.0.0.0上，默认使用root用户连接C。SOCKS配置192.167.1.27:1080，如果将1080映射成外网端口，则SOCKS可配置使用外网IP和端口
    # 在A机器上将sockert配置成192.167.1.27:1080即可，在A上可访问C能访问的任何网络
    # 常用此方式将C作为跳板机访问生成安全网络：在C(网段1)上挂VPN则可访问生产网络(网段2)，此时又在C上启动SOCKS代理，则其他机器配置此SOCKS代理即可访同C一样访问生产网络(直接访问网段2的地址即可)
    ssh -f -N -D 0.0.0.0:1080 192.167.1.27      
    ssh -D 0.0.0.0:1080 smalle@127.0.0.1:22 "vmstat 30" # 直接在中间机上运行此命令，并将1080对应到外网，则SOCKS可配置使用对应外网IP和端口
    # -i 使用私钥登录，起到加密作用
    # 在请求发起60秒钟后未收到响应则超时，120秒内无数据通过则发送一个请求避免断开，-o添加ssh参数(覆盖sshd_conf)
    sudo ssh -i /home/smalle/.ssh/warehouse.pem -oConnectTimeout=60 -oServerAliveInterval=120 -o 'GatewayPorts yes' -D 0.0.0.0:3386 ec2-user@52.56.100.100 "vmstat 30"
    ```
    - SSH建立的SOCKS服务器使用的是SOCKS5协议
    - 配置SOCKS：IE/Chrome/Firefox/xshell等都可配置SOCKS5；某些程序如windows的远程桌面程序无法配置，此时可以使用`SocksCap`(SocksCap配置好SOCKS，然后通过SocksCap启动目标程序)
- 远程登录 [^6]
    - 使用花生壳创建二级域名将本地网络映射到公网
    - 跨网络连接远程，可使用蒲公英VPN
    - 图形界面登录可使用RealVNC，各大操作系统都支持，使用 VNC 协议，并且对键盘处理很好用，还可以传文件和共享剪贴板。其他如Teamview、Anydesk等
    - 远程SSH登录：Linux一般自带SSH server，window可使用cygwin(可配合apt-cyg使用)
- 常见问题
    - 没有开启端口转发
        - 修改`/etc/ssh/sshd_config`中配置为`AllowTcpForwarding yes`
        - 修改`cat /etc/sysctl.conf`中配置为`net.ipv4.ip_forward = 1`

### SOCKS5安全问题(Shadowsocks使用) [^7]

- SOCKS5只是对数据做中转传输，无法起到加密的作用，不太安全
- 安全的 socks 代理不应向防火墙公开以下信息：任何表明它被用作代理的特征、任何真实传输的数据
- 在HTTP/HTTPS的世界里，TCP/IP数据包的源和目标是公开的，解决恶意攻击可以利用强加密算法的 SOCKS5 协议
- 可以把SOCKS5拆分成两部分，socks5-local和socks5-remote：客户端通过SOCKS5协议向本地代理发送请求，本地代理通过HTTP协议发送加密后的请求数据，因为 HTTP 协议没有明显的特征，并且远程代理服务器尚未被识别为代理，因此请求可以穿透防火墙
- [Shadowsocks](https://github.com/shadowsocks/shadowsocks) 是一款出色的安全 socks5 代理解决方案。github上代码库已被屏蔽，wiki可以使用，代码可查看其他用户fork仓库

```bash
# https://github.com/shadowsocks/shadowsocks/wiki/Ports-and-Clients
## 服务端(支持linux、windows等多平台)
pip install shadowsocks # 会安装 ssserver 服务端和 sslocal 客户端
# 后台启动服务端，服务端端口为 10010(需要开放此端口)
sudo ssserver -p 10010 -k Hello1234! -d start

## 客户端(支持windows、Android、iOS)
# windows下载 https://github.com/shadowsocks/shadowsocks-windows/releases
pip install shadowsocks # 会安装 ssserver 服务端和 sslocal 客户端
# 后台启动客户端
sudo sslocal -s 100.100.100.100 -p 10010 -k Hello1234! -d start
```


---

参考文章

[^1]: https://blog.itnmg.net/2013/05/19/vps-pptp-vpn/ (CentOS-VPS建立PPTP-VPN服务)
[^2]: https://blog.csdn.net/ithomer/article/details/52138961 (阿里云CentOS7搭建VPN)
[^3]: https://help.aliyun.com/knowledge_detail/40697.html (ECS-Windows服务器VPN连接报错:错误628解决方法)
[^4]: https://blog.itnmg.net/2015/04/03/centos7-ipsec-vpn/ (CentOS7配置IPSec-IKEv2-VPN)
[^5]: https://www.cnblogs.com/fbwfbi/p/3702896.html (SSH隧道技术----端口转发，socket代理)
[^6]: http://zsaber.com/blog/p/126 (远程登录那些事儿)
[^7]: http://blog.zxh.site/2018/07/08/%E5%AE%89%E5%85%A8%E7%9A%84socks5%E5%8D%8F%E8%AE%AE/
