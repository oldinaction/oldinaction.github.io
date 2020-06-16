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
    - Http通用代理和SSH -D原理
        
        ![firewall-http-proxy](/data/images/extend/firewall-http-proxy.png)
        ![firewall-ssh-d](/data/images/extend/firewall-ssh-d.png)
- 建立本地SSH隧道：可从内部绕过防火访问外部资源(FanQiang)

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
- 通过SSH隧道建立SOCKS服务器(一台中间机映射一次即可访问指定网络所有服务器的资源。**建议**)

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
- [Shadowsocks](https://github.com/shadowsocks/shadowsocks) 简称SS，是一款出色的安全 socks5 代理解决方案。github上代码库已被屏蔽，wiki可以使用，代码可查看其他用户fork仓库
- Shadowsocks原理 [^8]

    ![firewall-ss-flow](/data/images/extend/firewall-ss-flow.png)
    - 为了解决上述加密需求，SS提供很多加密方式，较安全的如`chacha20-poly1305`等，但仍然有可能被破解的可能导致被Ban
- 安装及使用

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

## v2ray + CDN

> 此方式必须条件：VPS + 顶级域名 + CDN

- 背景
    - 使用`HTTP 代理`、`SSH -D`、`SOCKS`、`SS(Shadowsocks)`均无法正常上网
    - `PAC` 实现了自动代理，即只代理需要代理的，不代理不需要代理的，而且还可以提供多个代理服务器，在某个失效时自动切换至另一个。其核心是 PAC 脚本，它实质上是一个 JS 文件(也被称为 PAC 文件)
    - [免费正常上网，没进行测试，稳定性待商榷](https://github.com/Alvin9999/new-pac/wiki)，有经济条件可按下文自行搭建
- 原理 [^8] [^9]

    ![firewall-v2ray-cdn-vps](/data/images/extend/firewall-v2ray-cdn-vps.png)
    - 先请求境外CDN，再由境外CND负责请求，而境外CDN有许多正规网站使用不容易被Ban
    - v2ray一款优秀的开源网络工具，目前仍处于活跃更新中，其在混淆上有着独到的建树，可以做到伪装成正常的HTTPS网站，避开第三方的干扰
    - V2Ray和Shadowsocks代理，最终都要通过代理
    - ws模式比tcp模式速度稍差一点，tls需要握手时间，cdn有绕路问题
- vps选用
    - [vultr官网地址](https://www.vultr.com/?ref=8284883)：费用差不多`$3.5/mon`(纽约)，实际按照小时计费，不使用不计费，可通过支付宝支付
        - 通过 https://www.vultr.com/?ref=8284883 此连接注册且支付可赠送$50，直接注册无此(我就是直接注册，惨痛经历~~)
        - 如`$3.5/mon`(vps在纽约)包含总带宽500G，用完为止，但是基本够用
        - 不使用是指不创建vps，关机的vps也会计费
        - 创建后可安装`Centos8`可直接通过ssh客户端连接
        - 命令行`reboot`不会导致ip/密码等修改。删除vps重新创建不足1小时按1小时计费，重装系统正常计费(不同于删除vps)
    - 搬瓦工
- **v2ray单独使用**(可不使用CDN，比直接使用SS等安全。测试Youtube的Connection Speed=7000左右，看1080P妥妥的)
    - v2ray服务端(vps端)

        ```bash
        ### 安装
        sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
        systemctl stop firewalld && systemctl disable firewalld

        ## 直接安装v2ray服务
        # 安装v2ray服务端(vps上安装)。安装成功会显示PORT(端口)和UUID(用户ID)，也可在`/etc/v2ray/config.json`中查看，v2ray客户端需求使用
        # 也可使用[v2-ui](https://blog.sprov.xyz/2019/08/03/v2-ui/)，基于web管理v2ray服务(不可同时使用)
        bash <(curl -L -s https://install.direct/go.sh)
        systemctl enable v2ray && systemctl start v2ray && systemctl status v2ray

        ## 基于v2-ui安装(web控制面板)。支持多用户多协议，支持账号流量统计。[github](https://github.com/sprov065/v2-ui)
        # 更新安装都是此命令，升级不会造成数据丢失
        bash <(curl -Ls https://blog.sprov.xyz/v2-ui.sh)
        v2-ui # 查看命令
        # http://<服务器IP>:65432 默认用户名密码 admin/admin
        ```
    - v2ray客户端
        - 以windows为例，[如v2.41下载地址](https://github.com/2dust/v2rayN/releases/download/2.41/v2rayN-Core.zip)。其他参考下文
        - v2ray客户端直接使用tcp/ip配置v2ray(默认tcp，容易被Ban)
            - 安装成功 - 管理员启动 - 服务器 - 添加VMess服务器(地址为VPS地址，端口和用户ID填v2ray服务器的，额外ID默认64，加密方式chacha20-poly1305，传输协议tcp)
            - 开启代理 - v2ray状态栏的图标点右键 - 勾选启用http代理 - 在http代理模式中选择PAC模式
            - 保存后会自动启动，控制台显示`started`。且在界面底部会显示`SOCKS5/HTTP/PAC`代理对应的地址，且会自动将PAC加入到windows的系统代理中(每次重启PAC地址会改变)。默认的代理ip为127.0.0.1只需本地使用，可在 **`参数设置-v2rayN设置-运行来自局域网的连接`**，重启后局域网都可以使用此代理正常上文
            - **访问外网测试**。通过`IE`、`IE Edge`、`Opera`浏览器可直接访问(默认使用了系统代理)；`Google`需要关闭所有代理插件；`Firefox`需要使用上述代理地址进行配置
        - 使用ws(websocket)模式

            ```json
            // 在 inbounds 里添加一个 inbound(默认包含一个tcp类型的inbound)，id 部分请使用 /usr/bin/v2ray/v2ctl uuid 命令随机生成一个。如果基于域名则端口必须设置为 80；如果基于IP，端口可设置成其他
            // vi /etc/v2ray/config.json
            {
                "settings": {
                    "clients": [{
                        "id": "使用`/usr/bin/v2ray/v2ctl uuid`自行生成",
                        "alterId":64
                    }]
                },
                "protocol": "vmess",
                "port": 80,
                "streamSettings": {
                    "wsSettings": {
                        "path": "/",
                        "headers": {}
                    },
                    "network": "ws"
                }
            }

            // 修改后重启v2ray服务：systemctl restart v2ray
            ```
            - 客户端配置修改：端口使用80(后面如果使用CDN则此处端口必须使用80，否则可以使用其他)，传输协议使用ws，路径使用/，其他同tcp模式配置
- v2ray + CDN(相对直接使用v2ray安全，测试Youtube的Connection Speed=2000左右，延迟较高)
    - [CloudFlare](https://www.cloudflare.com/zh-cn/)为一款国外CDN，可免费支持一个域名
        - 添加域名 - 修改DNS - 解析子域名如`v2ray`到vps对应ip
    - v2ray客户端配置：使用域名如`v2ray.aezo.cn`，其他同ws模式的配置。注意v2ray服务器一定要监听在80端口，或者通过访问`ws://v2ray.aezo.cn/`到的vps对应的ws服务
- v2ray + CDN + TLS(相对更安全)
    - 参考：https://blog.sprov.xyz/2019/04/27/v2ray-wstls-or-http2tls-tutorial/
- 谷歌BBR(TCP加速，可选，测试效果不明显)
    
    ```bash
    # 在vps中安装。相当于vps访问目标网站会快一些
    wget --no-check-certificate https://github.com/sprov065/blog/raw/master/bbr.sh && bash bbr.sh
    reboot
    lsmod | grep bbr # 出现了tcp_bbr字样
    ```
- v2ray客户端(ios的app store境内都无法下载)
    - [V2RayN (Windows)](https://github.com/2dust/v2rayN/releases)
    - [v2rayW (Windows)](https://github.com/Cenmrev/V2RayW/releases)
    - [V2RayU (macOS)](https://github.com/yanue/V2rayU/releases)
    - [v2rayX (macOS)](https://github.com/Cenmrev/V2RayX/releases)
    - Shadowrocket (iOS, $2.99)
    - i2Ray (iOS, $3.99)
    - Quantumult (iOS, $4.99)
    - Kitsunebi (iOS, $4.99)
    - BifrostV (Android)
    - [V2RayNG (Android)](https://github.com/2dust/v2rayNG/releases)
- ios的app store境内无法下载问题
    - 解决：下载对应ipa文件，然后通过`爱思助手`通过电脑导入安装到手机，免费，相对安全。如：[Shadowrocket v2.1.12](https://files.flyzy2005.cn/%E5%AE%A2%E6%88%B7%E7%AB%AF/%E4%B8%8D%E5%8F%AF%E6%8F%8F%E8%BF%B0%E7%9A%84%E5%AE%A2%E6%88%B7%E7%AB%AF/IOS_Shadowrocket_2.1.12%28%E6%97%A0%E9%9C%80%E9%AA%8C%E8%AF%81appleId%29.ipa)
    - [ios神秘商店，收取小额费用](https://aneeo.com/ios)



---

参考文章

[^1]: https://blog.itnmg.net/2013/05/19/vps-pptp-vpn/ (CentOS-VPS建立PPTP-VPN服务)
[^2]: https://blog.csdn.net/ithomer/article/details/52138961 (阿里云CentOS7搭建VPN)
[^3]: https://help.aliyun.com/knowledge_detail/40697.html (ECS-Windows服务器VPN连接报错:错误628解决方法)
[^4]: https://blog.itnmg.net/2015/04/03/centos7-ipsec-vpn/ (CentOS7配置IPSec-IKEv2-VPN)
[^5]: https://www.cnblogs.com/fbwfbi/p/3702896.html (SSH隧道技术----端口转发，socket代理)
[^6]: http://zsaber.com/blog/p/126 (远程登录那些事儿)
[^7]: http://blog.zxh.site/2018/07/08/%E5%AE%89%E5%85%A8%E7%9A%84socks5%E5%8D%8F%E8%AE%AE/
[^8]: https://wsxq2.55555.io/blog/2019/07/07/%E7%A7%91%E5%AD%A6%E4%B8%8A%E7%BD%91/ (科学上网[AAA])
[^9]: https://blog.sprov.xyz/2019/03/11/cdn-v2ray-safe-proxy/comment-page-7/
[^10]: https://blog.sprov.xyz/2019/02/04/v2ray-simple-use/
