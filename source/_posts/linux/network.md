---
layout: "post"
title: "网络"
date: "2019-06-20 09:58"
categories: linux
tags: [network, linux, docker]
---

## Linux网络

### brctl网桥操作

- 集线器、网桥、交换机、路由器、网关等术语参考 [^12]
- `brctl` 网桥操作
    
    ```bash
    # 显示所有网桥
    brctl show
    ```

### ip信息

- ip信息
    - `ip a` 查看ip、mac地址、网卡等信息。ipconfig也可查看
- route路由信息
    - 查看路由信息 `ip r`/`ip route`；
    - `route`也可显示路由信息

    ```bash
    ip r # 显示如下

    # 表示去任何地方，都发送给网卡eth0，并经过网关192.168.17.103发出；metric 100表示路由距离，到达指定网络所需的中转数
    default via 192.168.17.103 dev eth0 proto static metric 100
    # 表示发往 172.16.0.0/16 这个网段的包，都由网卡docker0发出，src 172.17.0.1为网卡docker0的ip
    172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 
    172.18.0.0/16 dev br-190a4d9330bd proto kernel scope link src 172.18.0.1 
    192.168.17.0/24 dev eth0 proto kernel scope link src 192.168.17.73 metric 100
    ```
- 路由策略信息 [^5]
    - `ip rule`

### curl/wget测试

```bash
# GET请求
curl localhost:8080
# POST请求，-v显示日志信息，-d传递普通参数
curl -X POST -v -d "username=smalle&password=aezocn" localhost:8080/login
# POST请求，-H指定header，此时指定Content-Type:application/json，-d中的数据会放到body中
curl -H "Content-Type:application/json" -H "Authorization: aezocn" -X POST -d '{"orderId": "1"}' http://localhost:8000/order/
```

### ping

```bash
# 只向192.168.1.1发送1个包
ping -c 1 192.168.1.1
```

### tcpdump

```bash
# yum -y install tcpdump
# 观察流经 docker0 网卡的 icmp 类型(ping/telnet)流量
tcpdump -i docker0 -n icmp
# -e可显示ttl信息
tcpdump -i docker0 -n icmp -vv -e
```

### traceroute

- traceroute 程序的主要目的是获取从当前主机到目的主机所经过的路由 [^11]
- 官方方案（TCP/IP详解里提供的基于 UDP 的方案）
    - 通过封装一份 UDP 数据报（指定一个不可能使用的端口，30000以上），依次将数据报的 TTL 值置为 1、2、3...，并发送给目的主机
    - **当路径上第一个路由器收到 TTL 值为 1 的数据报时，首先将该数据报的 TTL 值减 1，发现 TTL 值为 0，而自己并非该数据报的目的主机，就会向源主机发送一个 ICMP 超时报文**，traceroute 收到该超时报文，就得到了路径上第一台路由器的地址
    - 然后照此原理，traceroute 发送 TTL 为 2 的数据报时，会收到路径上第二台路由器返回的 ICMP 超时报文，记录第二台路由器的地址
    - 直到报文到达目的主机，目的主机不会返回 ICMP 超时，但由于端口无法使用(但是存在正好该端口可使用的情况，只是可能性较小)，就会返回一份端口不可达报文给源主机，源主机收到端口不可达报文，证明数据报已经到达了目的地，停止后续的 UDP 数据报发送，将记录的路径依次打印出来，结束任务
        - 目的主机端口号最开始设置为 33435，且每发送一个数据报加 1，可以通过命令行选项来改变开始的端口号
- TTL说明
    - **TTL是数据包的发送主机设置的**，发送主机指的是ping后面IP对应的主机(ping返回的TTL是指接收到响应数据包的TTL)。一般linux服务器为64，windows服务器为128，一般设置为255以下数值
    - TTL每经过一个路由器或代理服务器都会减1，如果TTL=0则中间路由设备或目的主机都会扔掉此包

### iptables

- 相关文章：[洞悉linux下的Netfilter&iptables](http://blog.chinaunix.net/uid-23069658-id-3160506.html)
- iptables其实不是真正的防火墙，我们可以把它理解成一个客户端代理，用户通过iptables这个代理，将用户的安全设定执行到对应的安全框架(如：netfilter)中，这个安全框架才是直正的防火墙。netfilter位于内核空间，iptables位于用户空间
- iptables的规则存储在内核空间的信息包过滤表中，这些规则分别指定了源地址、目的地址、传输协议（如TCP、UDP、ICMP）和服务类型（如HTTP、FTP和SMTP）等。当数据包与规则匹配时，iptables就根据规则所定义的方法来处理这些数据包，如放行（accept）、拒绝（reject）和丢弃（drop）等。配置防火墙的主要工作就是添加、修改和删除这些规则
- 链(规则)类型：`PREROUTING`、`INPUT`、`FORWARD`、`OUTPUT`、`POSTROUTING`。每种链类型上可能会有多个规则 [^1]
    
    ![报文流向](/data/images/linux/报文流向.png)

    - 流入本机：PREROUTING --> INPUT--> 用户空间进程(本地套接字)
    - 转发：PREROUTING --> FORWARD --> POSTROUTING
    - 流出本机（通常为响应报文）：用户空间进程 --> OUTPUT--> POSTROUTING
- 表：把具有相同功能的规则的集合叫做"表"，不同功能的规则可以放置在不同的表中进行管理。当他们处于同一条"链"时，执行的优先级为：**raw > mangle > nat > filter**
    - `raw`表：关闭nat表上启用的连接追踪机制；iptable_raw。可能被PREROUTING，OUTPUT使用
    - `mangle`表：拆解报文，做出修改，并重新封装的功能；iptable_mangle。可能被PREROUTING，INPUT，FORWARD，OUTPUT，POSTROUTING使用
    - `nat`表：network address translation，网络地址转换功能；内核模块：iptable_nat。可能被PREROUTING，INPUT，OUTPUT，POSTROUTING（centos6中无INPUT）使用
    - `filter`表：负责过滤功能，防火墙；内核模块：iptables_filter。可能被INPUT，FORWARD，OUTPUT使用
- 规则由匹配条件和处理动作组成
    - 匹配条件：源地址Source IP，目标地址 Destination IP，和一些扩展匹配条件
    - 处理动作(target)
        - `ACCEPT`：允许数据包通过（后续规则继续执行。此时会继续校验此链上的其他规则和剩余其他链规则）
        - `DROP`：直接丢弃数据包，不给任何回应信息，过了超时时间才会有反应。或者出现ping永远无返回信息即卡死（后续不执行）
        - `REJECT`：拒绝数据包通过，必要时会给数据发送端一个响应的信息，客户端刚请求就会收到拒绝的信息（后续不执行）
        - `SNAT`：源地址转换，解决内网用户用同一个公网地址上网的问题（后续规则继续执行）
        - `MASQUERADE`：是SNAT的一种特殊形式，适用于动态的、临时会变的ip上
        - `PNAT`：源端口转换
        - `DNAT`：目标地址转换
        - `REDIRECT`：在本机做端口映射
        - `LOG`：在/var/log/messages文件中记录日志信息，然后将数据包传递给下一条规则，也就是说除了记录以外不对数据包做任何其他操作，仍然让下一条规则去匹配
        - `RETURN`：结束在目前规则链中的过滤程序，返回主规则链继续过滤。如果把自定义链看成是一个子程序，那么这个动作就相当于提早结束子程序并返回到主程序中（此自定义链后续规则不执行，主链继续执行）
        - `QUEUE`：防火墙将数据包移交到用户空间
- 列出iptables表规则 [^2]

```bash
## 列出iptables表规则
iptables [-t tables] [-L] [-nv]
    # 选项与参数：
    # -t ：后面接 table ，例如 nat 或 filter ，若省略此项目，则使用默认的 filter
    # -n ：仅显示IP，不进行 IP 与 HOSTNAME 的反查。(否则显示HOSTNAME)
    # -v ：列出更多的信息，包括通过该规则的封包总位数、相关的网络接口等
    # -x ：显示详细数据，不进行单位换算
    # -L ：列出目前的 table 的规则

# 列出 filter table 相关链的规则明细，包含数据包大小等
iptables -nvxL
    # pkts        对应规则匹配到的报文的个数
    # bytes       对应匹配到的报文包的大小总和
    # target      规则对应的traget，表示对应的动作，即规则匹配成功后需要采取的措施
    # prot        表示规则对应的协议，是否只针对某些协议应用此规则
    # opt         表示规则对应的选项
    # in          表示数据包由哪个接口流入，可以设置哪块网卡流入的报文需要匹配当前规则
    # out         表示数据包由哪个接口流出，可以设置哪块网卡流出的报文需要匹配当前规则
    # source      表示规则对应的源头地址，可以是一个ip，也可以是一个网段
    # destination 表示规则对应的目标地址，可以是一个ip，也可以是一个网段
# 查看filter表的FORWARD链规则
iptables -nvxL FORWARD
# 列出 nat table 相关链的规则（--line显示行编号）
iptables -nvxL --line -t nat
# 基于链的顺序显示nat表中的规则
iptables -t nat -S

# 示例：iptables -nvxL 部分显示如下
Chain INPUT (policy ACCEPT 937 packets, 77099 bytes) # INPUT链中无任何规则；policy ACCEPT为默认处理动作
 pkts bytes target     prot opt in     out     source               destination      

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes) # FORWARD链中引入了自定义链DOCKER-ISOLATION-STAGE-1和DOCKER内容，当符合后面的规则就执行自定义链，相当于执行子函数；prot代表使用的封包协议（tcp, udp 及 icmp）；opt额外的选项说明；source/destination为源/目标地址
 pkts bytes target     prot opt in     out     source               destination         
   30 10743 DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
   30 10743 DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
   15  9681 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    0     0 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0           # 此时虽然符合执行DOCKER子链，但是DOCKER子链中并无规则，所以此规则记录的pkts和bytes为0
   15  1062 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0           
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0           
    0     0 ACCEPT     all  --  *      br-92de1a13d5ca  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
   ...

Chain OUTPUT (policy ACCEPT 723 packets, 123K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain DOCKER (3 references)
 pkts bytes target     prot opt in     out     source               destination

...

Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination         
   30 10743 RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0     
```
- 操作iptables规则 [^3] [^4]

```bash
## 参考：https://blog.csdn.net/qq_38892883/article/details/79709023
## 语法
iptables [-t table] COMMAND [chain] CRETIRIA -j ACTION
    -t table    # filter/nat/mangle
    COMMAND     # 定义如何对规则进行管理
    chain       # 定义规则作用的链；当定义策略的时可省略的
    CRETIRIA    # 指定匹配标准
    -j ACTION   # 指定如何进行处理。参考处理动作(target)：ACCEPT、DROP、SNAT、DNAT等


## COMMAND参数解释
# 链管理命令
-P  # 设置默认策略(DROP|ACCEPT)
        # eg: iptables -P INPUT DROP # 进入到INPUT链时，如果没有匹配到任何规则，则默认DROP拒绝此数据包
-F  # FLASH，清空规则链的
        # eg: iptables -t nat -F            # 清空nat表的所有链
        # eg: iptables -t nat -F PREROUTING # 清空nat表的PREROUTING链
-N  # NEW，支持用户新建一个链
        # eg: iptables -N inbound_tcp_web # 逻辑意义为附在tcp表上用于检查web
-X  # 用于删除用户自定义的空链；使用方法跟-N相同，但是在删除之前必须要将里面的链给清空
-E  # 用来Rename chain主要是用来给用户自定义的链重命名
        # eg: iptables -E oldname newname
-Z  # 清空链及链中默认规则的计数器的（有两个计数器：数据包个数、数据包字节大小）

# 规则管理命令
-A  # 追加，在当前链的最后新增一个规则
-I  # 插入，把当前规则插入为第几条
    # eg: iptables -I 3 ... # 插入为第3条
-R  # 替换/修改第几条规则
    # eg: iptables -R 3 ... # 修改第3条规则
-D  # 删除第几条规则
    # eg: sudo iptables -t mangle -D PREROUTING 1 # 删除 mangle表PREROUTING链的第1条规则

# 查看管理命令
-L  # 查看表中的规则
    # 子命令：-n、-v、-vv、-vvv、-x、--line/--line-numbers、-t
-S  # 基于链的顺序显示表中规则。eg：iptables -t nat -S

## CRETIRIA匹配标准参数解释
# 通用匹配：源地址目标地址的匹配
-s          # 指定作为源地址匹配，这里不能指定主机名称，必须是IP（IP | IP/MASK | 0.0.0.0/0.0.0.0），而且地址可以取反，加一个"!"表示除了哪个IP之外.
    # eg：-s 192.168.1.10   # 源地址为192.168.1.10的数据包
    # eg: ! -s 127.0.0.0/8   # 源地址不为127.0.0.0/8的数据包
-d          # 表示匹配目标地址
-p          # 用于匹配协议的（这里的协议通常有3种，TCP/UDP/ICMP，见下文）
-i  eth0    # 匹配数据经这块网卡流入，流入一般用在INPUT和PREROUTING上
-o  eth0    # 匹配数据经这块网卡流出，流出一般在OUTPUT和POSTROUTING上
# 扩展匹配
# 隐含扩展：对协议的扩展
-p tcp  # TCP协议的扩展
    --dport XX-XX   # 指定目标端口，不能指定多个非连续端口，只能指定单个端口
        # eg: --dport 21  或者 --dport 21-23(此时表示21,22,23)
    --sport # 指定源端口
    --tcp-fiags # 一般跟的参数：检查标志位、必须为1的标志位。TCP的标志位（SYN、ACK、FIN、PSH、RST、URG）
        # eg: --tcpflags syn,ack,fin,rst syn # 用于检测三次握手的第一次数据包，对于这种专门匹配第一包的SYN为1的包
            # 检查标志位：syn,ack,fin,rst，必须为1的标志位：syn(其他必须为0)
            # --tcpflags syn,ack,fin,rst syn <=等同于=> --syn
-p udp  # UDP协议的扩展
    --dport
    --sport
-p icmp # icmp数据报文的扩展
    --icmp-type # 匹配icmp类型
        # eg: --icmp-type 8 # 匹配请求回显数据包。echo-request(请求回显)，一般用8来表示；echo-reply(响应数据包)一般用0来表示
# 显式扩展（-m），扩展各种模块
-m multiport    # 表示启用多端口扩展，之后就可以使用比如：--dports 21,23,80


## 示例
# 如果数据包经 eth0 网卡流入，则对其TTL值加3 (有效解决主网TTL被运营线篡改导致TTL异常，如TTL=1，此时无法做子网路由)
iptables -t mangle -A PREROUTING -i eth0 -j TTL --ttl-inc 3
```
- 暂存和恢复iptables规则
    - `iptables-save > /etc/sysconfig/iptables` 暂存所有规则到文件中
    - `iptables-restore < /etc/sysconfig/iptables` 将文件中暂存的规则恢复到规则表中

### ebtables

- ebtables和iptables都是linux系统下，netfilter的配置工具，可以在链路层和网络层的几个关键节点配置报文过滤和修改规则。ebtables更侧重vlan，mac和报文流量；iptables侧重ip层信息，4层的端口信息 [^13]
- Netfilter-Packet-Flow

![Netfilter-Packet-Flow](/data/images/linux/Netfilter-Packet-Flow.png)

## SSH隧道技术及SOCKET代理

- 背景说明 [^15]
    - 可解决问题：想在家里访问公司的机器(写程序，查数据，下电影)；公司为了防止逛淘宝，封锁了它的端口或者服务器地址(同理如ZF封锁了外网导致无法上油管等)
    - 解决上述问题条件：有一台机器可以访问公司的机器(如处于公司的笔记本)、可以访问淘宝的服务器、可以访问外网的香港主机等；且此服务器有一个公网(IP)端口
    - 机器说明：A为本机、B(234.234.234.234)为目标机(国外服务器或公司内网机器)、C(123.123.123.123)为中间机器(香港服务器或另外一台公司服务器)
    - SSH隧道技术缺点：只能代理TCP数据，不能代理UDP数据
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
- 建立远程SSH隧道：可从外网放到到内网资源(远程办公)
    
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
    # 在中间机C上执行。bindaddress：指定绑定ip地址、port：指定侦听端口、name：ssh服务器登录名、server：ssh服务器地址
    ssh -f -N -D bindaddress:port name@server
    ssh -f -N -D 0.0.0.0:1080 123.123.123.123   # 将端口绑定在0.0.0.0上，SOCKS配置123.123.123.123:1080，默认使用root用户连接C
    ssh -f -N -D 0.0.0.0:1080 192.167.1.27      # SOCKS配置192.167.1.27:1080，如果将1080映射成外网端口，则SOCKS可配置使用外网IP和端口
    ssh -D 0.0.0.0:1080 smalle@127.0.0.1:22 "vmstat 30" # 直接在中间机上运行此命令，并将1080对应到外网，则SOCKS可配置使用对应外网IP和端口

    # 在A机器上将sockert配置成192.167.1.27:1080即可，在A上可访问C能访问的任何网络
    # 常用此方式将C作为跳板机访问生成安全网络：在C(网段1)上挂VPN则可访问生产网络(网段2)，此时又在C上启动SOCKS代理，则其他机器配置此SOCKS代理即可访同C一样访问生产网络(直接访问网段2的地址即可)
    
    # 如果出现timeout，或open failed: connect failed: Network is unreachable
    ssh -oConnectTimeout=60 -oServerAliveInterval=120 ... # 在请求发起60秒钟后未收到响应则超时，120秒内无数据通过则发送一个请求避免断开
    ```
    - SSH建立的SOCKS服务器使用的是SOCKS5协议
    - 配置SOCKS：IE/Chrome/Firefox/xshell等都可配置SOCKS5；某些程序如windows的远程桌面程序无法配置，此时可以使用`SocksCap`(SocksCap配置好SOCKS，然后通过SocksCap启动目标程序)
- 远程登录 [^16]
    - 使用花生壳创建二级域名将本地网络映射到公网
    - 跨网络连接远程，可使用蒲公英VPN
    - 图形界面登录可使用RealVNC，各大操作系统都支持，使用 VNC 协议，并且对键盘处理很好用，还可以传文件和共享剪贴板。其他如Teamview、Anydesk等
    - 远程SSH登录：Linux一般自带SSH server，window可使用cygwin(可配合apt-cyg使用)

## 网络异常排查案例

### TTL=1导致虚拟机/docker无法访问外网

- 前言：公司选择了便宜的网络运营商，导致无论ping那个地址，总是返回TTL=1。直接在公司路由器上测试亦是如此，说明公司内部网络没有问题
- 环境介绍：物理机A(192.168.1.72)安装Centos7系统；然后在物理机基于KVM虚拟化出一台虚拟机A1(192.168.122.86)，并且基于NAT的方式联网。之前在A上测试过使用桥接模式时，虚拟机A1是可以访问外网的，此测试在之前测试之上完成。因此物理机A上存在一个虚拟网桥br0，其网卡enp6s0是桥接与br0上的；而KVM使用NAT模式时会自动创建一个虚拟网桥virbr0和创建一个虚拟网卡vnet0
- 产生现象
    - Linux物理机可正常上网，ping百度返回TTL=1。基于NAT模式，KVM虚拟机无法上网；基于网桥模式创建的docker容器，在docker容器内无法上网。(docker的网桥模式本质是基于iptables进行的NAT转发)
    - windows物理机上使用VMware创建Centos7虚拟机B当做上述的宿主机，且在VMware中设置为NAT网络模式，在A中创建KVM虚拟机B1。此时B和B1均可以访问外网；且在B中ping百度返回TTL=128
- 现象分析
    - 基于NAT模式的KVM虚拟机无法上网
        
        ```bash
        ### tcpdump监控上述A的几个网卡的icmp包，并在虚拟机A1上ping外网(只发一个包：ping -c 1 114.114.114.114)
        ## 数据包发送流向：eth0(A1) -> vnet0(A) -> virbr0 -> br0 -> enps60 -> Internet
        ## 数据包返回流向：eth0(A1) <-- vnet0(A) <-- virbr0 <- br0 <- enps60 <- Internet
        
        # virbr0(tcpdump -i virbr0 -n icmp -vv -e)
        # 数据包经过virbr0，之前没有进行过路由转发，因此virbr0受到的数据包TTL=64；此时发现需要转发到br0，因此virbr0会对TTL减1，然后发给br0，因此br0受到的TTL=63
        12:58:34.595496 52:54:00:38:ba:c7 > 52:54:00:7f:f7:c3, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 25917, offset 0, flags [DF], proto ICMP (1), length 84)
            192.168.122.86 > 114.114.114.114: ICMP echo request, id 14135, seq 1, length 64
        
        # br0(tcpdump -i br0 -n icmp -vv -e)
        12:58:34.595557 00:e0:8a:68:01:42 > 00:f1:f5:14:cf:ab, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 25917, offset 0, flags [DF], proto ICMP (1), length 84)
            192.168.1.72 > 114.114.114.114: ICMP echo request, id 14135, seq 1, length 64
        # 此时TTL=1表示：Internet数据包(返回数据包)到此网卡时，数据包中TTL=1；此时会先将TTL减1后发现TTL值为0，而自己并非该数据报的目的主机，就会向源主机发送一个 ICMP 超时报文
        # docker容器从docker0向eth0转发时，到达eth0的TTL也会减少1
        12:58:34.804159 00:f1:f5:14:cf:ab > 00:e0:8a:68:01:42, ethertype IPv4 (0x0800), length 98: (tos 0x28, ttl 1, id 16493, offset 0, flags [none], proto ICMP (1), length 84)
            114.114.114.114 > 192.168.1.72: ICMP echo reply, id 14135, seq 1, length 64
        # 发送 ICMP time exceeded in-transit 超时报文，对应ICMP错误码：TYPE=11，CODE=0/1。并将此错误告知源主机(Internet)
        12:58:34.804208 00:e0:8a:68:01:42 > 00:f1:f5:14:cf:ab, ethertype IPv4 (0x0800), length 126: (tos 0xc8, ttl 64, id 18352, offset 0, flags [none], proto ICMP (1), length 112)
            192.168.1.72 > 114.114.114.114: ICMP time exceeded in-transit, length 92
            (tos 0x28, ttl 1, id 16493, offset 0, flags [none], proto ICMP (1), length 84)
            114.114.114.114 > 192.168.1.72: ICMP echo reply, id 14135, seq 1, length 64
        
        # enp6s0(tcpdump -i enp6s0 -n icmp -vv -e)
        12:58:34.595571 00:e0:8a:68:01:42 > 00:f1:f5:14:cf:ab, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 25917, offset 0, flags [DF], proto ICMP (1), length 84)
            192.168.1.72 > 114.114.114.114: ICMP echo request, id 14135, seq 1, length 64
        12:58:34.804159 00:f1:f5:14:cf:ab > 00:e0:8a:68:01:42, ethertype IPv4 (0x0800), length 98: (tos 0x28, ttl 1, id 16493, offset 0, flags [none], proto ICMP (1), length 84)
            114.114.114.114 > 192.168.1.72: ICMP echo reply, id 14135, seq 1, length 64
        12:58:34.804213 00:e0:8a:68:01:42 > 00:f1:f5:14:cf:ab, ethertype IPv4 (0x0800), length 126: (tos 0xc8, ttl 64, id 18352, offset 0, flags [none], proto ICMP (1), length 112)
            192.168.1.72 > 114.114.114.114: ICMP time exceeded in-transit, length 92
            (tos 0x28, ttl 1, id 16493, offset 0, flags [none], proto ICMP (1), length 84)
            114.114.114.114 > 192.168.1.72: ICMP echo reply, id 14135, seq 1, length 64
        
        ## 在本地windows上使用VMware创建Centos7虚拟机B作为宿主机，并使用NAT网络；在B中创建的KVM虚机上ping外网正常。如下为监听宿主机B的br0网卡信息
        10:58:15.103187 00:50:56:20:1d:3a > 00:50:56:e2:64:56, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 46399, offset 0, flags [DF], proto ICMP (1), length 84)
            192.168.6.10 > 114.114.114.114: ICMP echo request, id 11275, seq 1, length 64
        # 此时TTL=128。由此可知同样的环境，只不过是宿主机B的外层还套了一个VMware的控制，右侧可猜想是VMware的NAT模式篡改了此处TTL的值
        10:58:15.346226 00:50:56:e2:64:56 > 00:50:56:20:1d:3a, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 128, id 36174, offset 0, flags [none], proto ICMP (1), length 84)
            114.114.114.114 > 192.168.6.10: ICMP echo reply, id 11275, seq 1, length 64
        ```
    - docker容器内无法上网原因同上，相关分析如下
        
        ``html
        <!-- eth0`为容器网卡，docker0和eth0为宿主机网卡；eth0`和docker0中间基于veth pair进行交互此处省略 -->
        1.eth0` -> docker0 触发PREROUTING
        2.docker0路由判断：to 114 => docker0 -> !docker0(out) 触发FORWARD
        3.访问114：MASQUERADE * -> !docker0  172.17.0.0/16 -> 0.0.0.0/0 触发POSTROUTING
        4.路由判断(ip r)，访问114：使用eth0访问，192.168.6.10 -> 114
        5.114返回处理包：114 -> 192.168.6.10 回执数据从eth0进入(返回)
        6.进入PREROUTING阶段，根据连接跟踪系统记录源发送IP为172，114 -> 172.17.0.x
        7.路由判断，访问172则基于docker0流入，触发FORWARD
        8.之后报文经过POSTROUTING阶段进入容器
        ```
        - Docker网络参考 [^6] [^7] [^9]
            - Docker容器通过独立IP暴露给局域网的方法：基于路由完成(不常用) [^8]
        - 关于连接跟踪系统记录的源IP参考 [^10]
- 解决方案：在宿主机A加添加iptables规则，对数据包的TTL进行操作 `iptables -t mangle -A PREROUTING -i br0 -j TTL --ttl-inc 10`表示数据包从eth0流入则对TTL加10
- 扩展问题：在宿主机A上安装KVM虚拟机A1，使用桥接网络，然后在虚拟机A1上安装docker，此时A和A1均可访问外网且返回TTL=1，且在容器中无法访问外网
    - 按照上述操作当数据包经过A1的eth0网卡时操作TTL值是可以成功让容器上网；但是每当容器重启或者A1重启时，docker都会重写iptables规则，从而导致自定义规则被覆盖；因此想到一种解决方法是在宿主机A的网卡上操作TTL，但实际失败的
    - 具体原因是默认iptables不对bridge的数据进行处理，即在网桥上进行转发的并不会触发TTL值的变化，具体参考上文`ebtables#Netfilter-Packet-Flow`
    - 解决方案一(操作宿主机A) [^14]

        ```bash
        vi /etc/sysctl.conf
        # 加入下列内容：开启iptables对bridge的数据，会出现数据包每经过一个网卡转发则会TTL减一
        net.bridge.bridge-nf-call-iptables=0
        #net.bridge.bridge-nf-call-ip6tables=0
        #net.bridge.bridge-nf-call-arptables=0
        
        # 刷新
        # 载入指定模块。防止刷新可能报错：sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file
        # modprobe br_netfilter
        sysctl -p

        # 操作宿主机
        iptables -t mangle -A PREROUTING -i br0 -j TTL --ttl-inc 10
        ```
    - 解决方案二(操作虚拟机A1)
        - 保存iptables规则 `iptables-save > /etc/sysconfig/iptables` (直接保存可能存在其他数据，此处可以手动保存到/etc/sysconfig/iptables)
            ```bash
            # Generated by iptables-save v1.4.21 on Thu Jun 20 16:05:03 2019
            *mangle
            :PREROUTING ACCEPT [0:0]
            :INPUT ACCEPT [0:0]
            :FORWARD ACCEPT [0:0]
            :OUTPUT ACCEPT [0:0]
            :POSTROUTING ACCEPT [0:0]
            -A PREROUTING -i eth0 -j TTL --ttl-inc 10
            COMMIT
            # Completed on Thu Jun 20 16:05:03 2019
            ```
        - 将下列脚本加入到开机启动

            ```bash
            #!/bin/sh
            # chkconfig: 2345 50 50
            # description: 初始化自定义iptables规则(防止docker覆盖)
            # processname: iptables-init

            # 基于文件中保存的iptables规则，提交到规则表中
            iptables-restore < /etc/sysconfig/iptables
            ```

---

参考文章

[^1]: http://www.zsythink.net/archives/1199/ (iptables概念)
[^2]: http://cn.linux.vbird.org/linux_server/0250simple_firewall.php#netfilter (防火墙与 NAT 服务器)
[^3]: https://blog.csdn.net/qq_38892883/article/details/79709023 (iptables命令详解和举例)
[^4]: https://blog.51cto.com/yijiu/1356254 (iptables详解)
[^5]: https://www.cnblogs.com/sammyliu/p/4713562.html (ip rule，ip route，iptables 三者之间的关系)
[^6]: http://blog.daocloud.io/docker-bridge/ (探索 Docker bridge 的正确姿势)
[^7]: https://www.cnblogs.com/lkun/p/7747459.html (容器如何与外部进行通信）)
[^8]: https://blog.csdn.net/lvshaorong/article/details/69950694
[^9]: https://blog.csdn.net/light_jiang2016/article/details/79029661
[^10]: http://blog.chinaunix.net/uid-23069658-id-3211992.html (洞悉linux下的Netfilter&iptables：网络地址转换原理之SNAT)
[^11]: https://www.cnblogs.com/iiiiher/p/8513748.html (完全理解icmp协议)
[^12]: https://www.tianmaying.com/tutorial/NetWorkInstrument (集线器、网桥、交换机、路由器、网关大解析)
[^13]: https://blog.csdn.net/gongjun12345/article/details/83788087
[^14]: https://blog.csdn.net/tycoon1988/article/details/40826235
[^15]: https://www.cnblogs.com/fbwfbi/p/3702896.html (SSH隧道技术----端口转发，socket代理)
[^16]: http://zsaber.com/blog/p/126 (远程登录那些事儿)

