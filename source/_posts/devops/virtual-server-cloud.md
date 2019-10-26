---
layout: "post"
title: "虚拟化服务器搭建 | 私有云"
date: "2019-05-30 16:11"
categories: [linux]
tags: [linux, cloud, server]
---

## 简介

### Hypervisor、KVM

- `Hypervisor` 是一种将操作系统与硬件抽象分离的一种技术实现方法，一种运行在物理服务器和操作系统之间的中间软件层(可以是软件程序，也可以是固件程序)。Hypervisor是所有虚拟化技术的核心，也叫虚拟机监视器VMM(Virtual Machine Monitor)[^1]
- `KVM`(Kernel-base-virtual machine)实际上是类Linux发行版内核中提供的虚拟化技术(内核级虚拟化)，可将内核直接充当Hypervisor来使用，在内核中独立存在可动态加载。注意其处理器(CPU)自身必须支持虚拟化扩展
    - QEMU 是一个主机上的VMM，通过动态二进制转换来模拟CPU，并提供一系列的硬件模型，使guest os认为自己和硬件直接打交道，其实是同QEMU模拟出来的硬件打交道，QEMU再将这些指令翻译给真正硬件进行操作。通过这种模式，guest os可以和主机上的硬盘，网卡，CPU，CD-ROM，音频设备和USB设备进行交互。但由于所有指令都需要经过QEMU来翻译，因而性能会比较差
    - QEMU-KVM：KVM负责cpu虚拟化+内存虚拟化，实现了cpu和内存的虚拟化，但kvm并不能模拟其他设备，还必须有个运行在用户空间的工具才行。KVM的开发者选择了比较成熟的开源虚拟化软件QEMU来作为这个工具，QEMU模拟IO设备（网卡，磁盘等），组成了QEMU-KVM [^5]
    - Qemu和KVM的最大区别就是：KVM模式如果一台物理机内存直接4G，创建一个vm虚拟机分配内存分4G，在创建一个还可以分4G，支持超配，但是qemu不支持
- `Libvirt` 是RedHat开始支持KVM后搞的一个用户空间虚拟机管理工具，其包括：KVM/QEMU，Xen，LXC，OpenVZ 或 VirtualBox hypervisors等
- 虚拟化类型
    - 全虚拟化：代表有`KVM`
    - 半虚拟化：代表有`Hypervisor`

### OpenStack和Kubernetes

- `OpenStack`虚拟化 [^2] [^3]
    - OpenStack 既是一个社区，也是一个项目和一个开源软件，提供开放源码软件，建立公共和私有云，它提供了一个部署云的操作平台或工具集
    - 虚拟化使得在一台物理的服务器上可以跑多台虚拟机，虚拟机共享物理机的CPU、内存、IO硬件资源，但逻辑上虚拟机之间是相互隔离的。宿主机一般使用hypervisor/KVM程序实现硬件资源虚拟化，并提供给客户机使用
    - 虚拟化优点隔离性强；缺点资源占用多，虚拟化技术本身占用资源，宿主机性能有10%左右的消耗
- `Kubernetes`容器(docker)编排
    - Kubernetes是容器管理编排引擎，那么底层实现自然是容器技术。容器是一种轻量级、可移植、自包含的软件打包技术，打包的应用程序可以在几乎任何地方以相同的方式运行
    - K8S与Docker之间的关系，如同Openstack之于KVM、VSphere之于VMWARE
    - 容器优点启动快，资源占用小，移植性好；容器缺点隔离性不好，共用宿主机的内核，底层能够相互访问，依赖宿主机内核，所以容器的系统选择有限制

### 虚拟化管理工具

- `WebVirtMgr` 基于libvirt开发的用来管理虚拟机的Web接口(可通过浏览器管理创建销毁虚拟机)，可创建和配置新的域，并调整域的资源分配，可通过 SSH 隧道的 VNC 浏览器提供完整的图形控制台来访问 guest 域(即可通过浏览器操作虚拟机)，支持 KVM 
- `Proxmox VE`(Proxmox VirtualEnvironment) 基本debian定制的，是一个非常棒的集成OPENVZ支持KVM应用的环境。有方面易用的WEB界面，基于JAVA的UI和内核接口，可以登录到VM客户方便的操作，还有易用的模板功能，基本跟老外的商业VPS环境差不多了 [^4]
- `oVirt` 其目标就是瞄准vCenter，而且oVirt和RHEV的关系，有点像Fedora和RHEL。CentOS7+Ovirt+GlusterFS是比较简单的私有云搭建模式，Ovirt社区比较小
- 更多参考 http://www.linux-kvm.org/page/Management_Tools

## Centos7 + KVM + WebVirtMgr搭建小型私有云

- 此处是使用两台Centos7虚拟机进行默认安装私有云搭建，WebVirtMgr则是通过web界面管理虚拟机创建和销毁等操作。也可通过桌面图形化管理私有云 [^7]
- 此处是使用两台Centos7虚拟机进行默认安装私有云搭建，Centos7图形化创建KVM
- 使用VMware虚拟化出两台虚拟机，并启用CPU虚拟化(虚拟机设置 - 处理器 - 虚拟化Inter VT-x/EPT...，如果是物理机需要进入BIOS启动CPU虚拟化)
    - 节点1 `192.168.6.10   centos`(安装kvm、WebVirtMgr)，4核2G，磁盘40G
    - 节点2 `192.168.6.131  node1`(安装kvm)，1核1G，磁盘20G

### 安装KVM

- 环境说明 [^6]

```bash
cat /etc/redhat-release # CentOS Linux release 7.3.1611 (Core)
uname -r # 3.10.0-514.el7.x86_64

# 关闭防火墙 & Selinux
systemctl stop firewalld
systemctl disable firewalld
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
cat /etc/selinux/config

# 设置Yum源

curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum makecache

# 查看是否支持虚拟化
cat /proc/cpuinfo | grep -E 'vmx|svm'
# flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts nopl xtopology tsc_reliable nonstop_tsc aperfmperf eagerfpu pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch ida arat epb pln pts dtherm hwp hwp_noitfy hwp_act_window hwp_epp tpr_shadow vnmi ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 invpcid rdseed adx smap xsaveopt

# 查看KVM 驱动是否加载
lsmod | grep kvm
    # lsmod | grep kvm显示结果
    # kvm_intel             170181  0 
    # kvm                   554609  1 kvm_intel
    # irqbypass              13503  1 kvm
    
    # 如果没有加载kvm驱动，利用命令加载驱动
    # modprobe -a kvm
    # modprobe -a kvm_intel

python -V # Python 2.7.5

# vi /etc/hosts 相互做host
192.168.6.10   centos
192.168.6.131   node1

# KVM管理端生成公钥（centos），并复制到node1
ssh-keygen
ssh-copy-id -i .ssh/id_rsa.pub root@centos
ssh-copy-id -i .ssh/id_rsa.pub root@node1
```
- 安装KVM相关管理工具

```bash
# 其中qemu-kvm是使I/O设备支持虚拟化；libvirt是管理kvm虚拟机的工具；virt-manager为桌面可视化管理虚拟机(需要主机必须安装图形库)；
# qemu-kvm          #KVM在用户运行的程序(使I/O设备支持虚拟化)
# libvirt           #用于管理虚拟机，它提供了一套虚拟机操作API，可以管理KVM、VMware等，像openstack就是通过libvirt API来管理虚拟机。像virt-install等命令底层都是通过libvirt来完成的
# virt-install      #是一种命令行安装kvm虚拟机的方式(基于libvirt完成)
# libvirt-client    #Libvirt的客户端，最重要的功能之一就是在宿主机关机时可以通过虚拟机也关机，使虚拟机系统正常关机，而不是被强制关机，造成数据丢失
# qemu-kvm-tool     #包含了如`qemu-img`包，可管理磁盘和光盘
# python-virtinst   #一套Python的虚拟机安装工具

# libvirt-python    #libvirt的图形化虚拟机管理软件，需要图形界面操作系统
# virt-manager      #基于Libvirt的图像化虚拟机管理软件，需要图形界面操作系统
yum install -y qemu-kvm libvirt virt-install libvirt-client qemu-kvm-tool python-virtinst libvirt-python virt-manager libguestfs-tools virt-viewer

# 启动librirt
systemctl start libvirtd
systemctl enable libvirtd
```

### 基于命令行管理KVM虚拟机

- 关于libvirt
    - libvirt用于管理虚拟机，会其一个libvirtd的进程，它提供了一套虚拟机操作API。可以管理KVM、VMware等，像openstack就是通过libvirt API来管理虚拟机，像virt-install等命令底层都是通过libvirt来完成的
    - 启动后libvirtd会默认安装了一个桥接网卡(`virbr0`)，还会启动了一个dnsmasqp进程，这个主要是dhcp给的虚拟机分配IP地址(`ps -ef|grep dns`)
    - kvm虚拟机都是靠libvirt xml来定义的，我们是无法对他进行修改的，可以使用`virsh edit xxx`进行编辑
    - https://i4t.com/1627.html
- 相关命令

```bash
## 创建磁盘(镜像)
# -f 制定虚拟机格式，raw是裸磁盘
# /data/centos-test.raw 存放路径，10G为镜像大小
qemu-img create -f raw /data/centos-test.raw 10GFormatting '/data/centos-test.raw', fmt=raw size=10737418240 

## 创建虚拟机(不含安装虚拟机操作系统)
# --name = 给虚拟机起个名字
# --ram = 内存大小
# --cdrom = 镜像位置，就是上传iso镜像的位置，我放在/tmp下了
# --disk path = 指定磁盘
# --network network = 网络配置 default 就会用我们刚刚ifconfig里面桥接的网卡
# --noautoconsosle 虚拟机创建完毕后不会自动切换tty
# --vnc 监听vnc
virt-install --name centos-test --virt-type kvm --ram 1024 --cdrom=/opt/CentOS-7-x86_64-Minimal-1810.iso --disk path=/data/centos-test.raw --network network=default --noautoconsole --vnc --vncport=5910 --vnclisten=0.0.0.0
```
- 使用VNC客户端连接虚拟机安装系统(VNC默认监听5900，使用`宿主IP:5900`连接)

### WebVirtMgr安装(基于WEB界面管理KVM虚拟机)

- [WebVirtMgr](https://github.com/retspen/webvirtmgr)基于Django开发，只需在管理端安装(192.168.6.10)
- 安装WebVirtMgr

```bash
# 安装pip、git、supervisor
yum -y install git python-pip libvirt-python libxml2-python python-websockify supervisor gcc python-devel
# 可提前修改pip镜像
pip install numpy

# 克隆项目(WebVirtMgr panel - v4.8.9)
mkdir -pv /data/www
cd /data/www
git clone git://github.com/retspen/webvirtmgr.git
cd webvirtmgr
pip install -r requirements.txt

# 初始化环境
./manage.py syncdb

# 配置Django静态页面
./manage.py collectstatic
# 还可继续添加管理
# ./manage.py createsuperuser

# 启动WebVirtMgr
./manage.py runserver 0:8000
```
- 访问`http://192.168.6.10:8000/`，输入用户名密码进入系统后显示Connections无连接

- 创建supervisor配置文件(非必须)。参考[Supervisor](/_posts/linux/CentOS服务器使用说明.md#Supervisor%20进程管理)

```bash
cd /data/www/webvirtmgr/
# 如果没有安装nginx进行端口转发，需要修改自动启动配置项
vi /data/www/webvirtmgr/conf/gunicorn.conf.py # 修改 `bind = '127.0.0.1:8000'` 为 `bind = '0:8000'`
# 直接复制执行下列语句
cat > /etc/supervisord.d/webvirtmgr.ini << EOF
[program:webvirtmgr]
command=/usr/bin/python /data/www/webvirtmgr/manage.py run_gunicorn -c /data/www/webvirtmgr/conf/gunicorn.conf.py
directory=/data/www/webvirtmgr
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/webvirtmgr.log
log_stderr=true
user=root

[program:webvirtmgr-console]
command=/usr/bin/python /data/www/webvirtmgr/console/webvirtmgr-console
directory=/data/www/webvirtmgr
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/webvirtmgr-console.log
redirect_stderr=true
user=root
EOF

# 启动supervisor，并设置开机重启
systemctl restart supervisord
systemctl enable supervisord
# 查看监控程序状态
supervisorctl status
# supervisorctl restart all # 手动重启所有
```

### Web界面配置WebVirtMgr

- 添加主机设置存储(安装了KVM的宿主机)
    - Add Connection 添加宿主机(即KVM主机)
    - 点击SSH连接
    - Label为主机名，必须为主机名做免密登录
    - IP为宿主机IP
    - 用户名为服务器用户名
    - 添加完后点击主机名激活
- 存储池。创建存储KVM镜像目录，KVM中的虚拟机都是以镜像的方式进行存储
    - 宿主机创建KVM镜像目录`mkdir -pv /data/vmdisk`
    - 创建存储KVM镜像目录(虚拟硬盘)
        - New Storage - 目录类型卷 - 名称为显示的名称(如：dev-storage) - 路径为宿主机路径(如：/data/vmdisk，kvm虚拟硬盘会在此目录创建*.img的存储文件，此Storage的容量为宿主机该目录挂载分区的容量)
        - 在dev-storage中添加镜像，即创建虚拟机的硬盘空间 - 名称如vmdisk - 格式qcow2 - **输入将被挂载的虚拟磁盘容量大小(最大999G，设置后无法修改)** - 去掉Metadata勾选 - 最终会在对应的宿主机上产生一个`/data/vmdisk/vmdisk.img`文件
    - 创建ISO镜像目录
        - New Storage - ISO镜像卷 - 路径如：/data/os(宿主机需要先创建此目录)
        - 上传ISO镜像
            - 直接页面上传，使用nginx的话需要修改client_max_body_size参数
            - 进入到宿主机下载阿里云镜像，`wget -P /data/os https://mirrors.aliyun.com/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-1810.iso`
            - 或者xftp上传到宿主机/data/os目录
    - 删除虚拟磁盘步骤
        - 在虚拟机/etc/fstab中去掉对应磁盘的挂载
        - 在存储池中删除对应磁盘镜像文件
        - 在虚拟机设置XML中删除对应磁盘disk配置
- Interfaces。显示此宿主机虚拟的网络接口，默认是ens33和lo。默认KVM虚拟机的网络为NAT，只可以宿主机访问，宿主机之外就无法访问，因此采用桥接网卡
    - 登录宿主机，查看是否有br0的桥接网卡，没有可以创建一个 `cp /etc/sysconfig/network-scripts/ifcfg-ens33 /etc/sysconfig/network-scripts/ifcfg-br0`

        ```bash
        # vi ifcfg-ens33。修改`ifcfg-ens33`为基于网桥连接
        DEVICE=ens33
        ONBOOT=yes
        BOOTPROTO=none
        BRIDGE=br0

        # vi ifcfg-br0。修改`ifcfg-br0`网络参数
        DEVICE=br0
        BOOTPROTO=static
        ONBOOT=yes
        TYPE=Bridge
        IPADDR=192.168.6.10
        NETMASK=255.255.255.0
        # 此为宿主机网关。如果手动设置虚拟机网络，则虚拟机网段需要和宿主机网段一直，且网关需要和宿主机一致；如果虚拟机基于DHCP获取亦可
        GATEWAY=192.168.6.2
        # DNS1=114.114.114.114
        # DNS2=114.114.115.115
        ```
    - 此时网页`Interfaces`中会显示br0和lo
- 网络池。虚拟机可使用的网络环境，默认是名称default的NAT类型网络接口，此时采用桥接网卡(上述Interfaces中已显示宿主机桥接网卡)
    - New Network - 网络类型BRIDGE - 名称如：br0 - 桥接名称br0(宿主机的桥接网卡) - 去掉Open vSwitch勾选(vSwitch即Virtual Switch，指虚拟交换机或虚拟网络交换机，工作在二层数据网络，通过软件方式实现物理交换机的二层和部分三层网络功能)
    - 配置完成后需要在网络池里面禁用default网络接口
    - **如果重启了宿主机网络，会导致虚拟机网络失效(进出都失效)，必须从WebVirtMgr管理界面重启虚拟机(reboot重启无效)**
- 虚机实例
    - 创建虚拟机 - New Instance - Custome Instance - 磁盘镜像选择vmdisk.img，网络池选择br0(此时创建的虚拟机则和宿主机处在同一个网段)，其他按需配置
    - 进入创建的虚拟机详细配置界面 - 设置 - Media - 连接CDROM1的iso镜像(安装系统时会基于此镜像安装到vmdisk.img镜像中，安装完成后则无需连接此iso镜像)
    - Power启动虚拟机
    - Access控制台可进入虚拟机命令行，进行系统安装。界面的Send Key中Ctrl+Ale+Del为重启虚拟机

#### 虚拟机其他设置

- 设置-XML中可对虚拟机配置进行修改，如修改网络接口等
    - 新增磁盘

        ```xml
        <disk type='file' device='disk'>
            <!-- 添加改行代码找到新增磁盘格式 -->
            <driver name='qemu' type='qcow2' cache='none'/>
            <!-- 指定新增磁盘路径 -->
            <source file='/data/vmdisk/vmdisk2.img'/>
            <!-- 指定磁盘设备名称，和传输总线类型。增加多块，默认是vda -->
            <target dev='vdb' bus='virtio'/>
            <!-- address可以省略，让系统自动生成，否则容易冲突 -->
            <!--<address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>-->
        </disk>
        ```
        - 进入到虚拟机进行磁盘分区和挂载(`fdisk -l`查看磁盘)，参考[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux-system/](/_posts/linux/linux-system.md#磁盘)
    - 网络接口配置

        ```xml
        <!-- 使用NAT网络：宿主机需要开启 net.ipv4.ip_forward 时，虚机才可上网 -->
        <interface type='network'>
            <mac address='52:54:00:bf:18:9b'/>
            <source network='default'/>
            <model type='virtio'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
        </interface>

        <!-- 使用宿主机br0网桥 -->
        <interface type='bridge'>
            <mac address='52:54:00:bf:18:9b'/>
            <source bridge='br0'/>
            <model type='virtio'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
        </interface>
        ```
    - 修VNC相关配置

        ```xml
        <graphics type='vnc' port='5900' autoport='yes' listen='0.0.0.0' passwd='smalle'>
            <listen type='address' address='0.0.0.0'/>
        </graphics>
        ```
- 设置-克隆可迅速克隆出一台虚拟机，无需重新安装系统
    - 被克隆机需要停止运行
    - 重新生成一个mac地址
    - vda (centos-storage)中填写的`vmdisk-clone.img`最终会生成`/data/vmdisk/vmdisk-clone.img`的镜像文件（克隆出的文件存储/镜像存储位置和大小同被克隆机器配置）
- Migrate虚拟机迁移
    - 被迁移虚拟机需要启动状态(否则报错Requested operation is not valid: domain is not running)
    - 勾选Unsafe migration(否则报错Unsafe migration: Migration without shared storage is unsafe)
    - 迁移时两台虚拟机会进入到暂停状态，修改完成后，原虚拟机自动停止，新虚拟机自动运行
    - 报错`internal error Attempt to migrate guest to the same host 03000200-0400-0500-0006-000700080009`，修改方式如下 [^8] [^9]

        ```bash
        # 获取一个uuid
        uuidgen
        # 修改配置文件，将uuidgen生成的数据填入到host_uuid
        vi /etc/libvirt/libvirtd.conf
        # host_uuid = "00000000-0000-0000-0000-000000000000"
        systemctl restart libvirtd
        ```
    - 待解决：迁移的新虚拟机仍然需要重新安装系统问题？？？
- Destroy删除只会删除虚拟机配置，默认并不会删除对应的磁盘，也可勾选删除对应磁盘数据
- 也可通过VNC桌面客户端进行连接，如使用`VNC View`，地址输入`192.168.6.10:5900`，此时ip为宿主机地址，端口可在虚拟机设置XML中查看

### 常见问题

- 克隆机器无法启动
    - 进入网页控制台 - Send Keys - 点击(Ctrl + Alt + Del)重启
    - 仍然无法启动则在重启时按`Esc`进入到启动实时日志界面
    - 如提示`Timed out waiting for device dev-home-main.device` 表示磁盘dev-home-main.device挂载失败，检查`/etc/fstab`是否书写正确，参考[http://blog.aezo.cn/2016/11/20/linux/ubuntu/](/_posts/linux/ubuntu.md#Centos7系统启动失败排查)





---

参考文章

[^1]: https://blog.51cto.com/51eat/2360346?source=dra
[^2]: https://www.cnblogs.com/goldsunshine/p/9872142.html
[^3]: https://blog.csdn.net/enweitech/article/details/51668952
[^4]: https://blog.51cto.com/kerry/2287648
[^5]: https://www.cnblogs.com/echo1937/p/7138294.html
[^6]: https://i4t.com/3732.html (KVM WEB管理工具 WebVirtMgr)
[^7]: https://i4t.com/3374.html (Centos7图形化创建KVM)
[^8]: http://bbs.linuxtone.org/thread-22673-1-1.html
[^9]: https://tanthalas.iteye.com/blog/1866693


