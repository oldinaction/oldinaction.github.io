---
layout: "post"
title: "vmware"
date: "2017-06-24 11:19"
categories: [linux]
tags: [vmware, linux, centos]
---

## 虚拟机安装

- 下载安装VMware
- 下载centos7镜像文件 [https://www.centos.org/download/](https://www.centos.org/download/). `DVD ISO`安装包含有桌面系统，`Minimal ISO`是最小安装包，不含桌面系统
- 虚拟机的安装位置选择在较空闲的磁盘，也可使用移动硬盘
- 除了安装位置，其他使用默认配置，点击安装（下面以`Minimal ISO`为例）
- 进入到Centos7安装界面，点击`Install Linux Centos7`。进入到安装图形化界面，选择中文
- 设置安装位置(之前推荐设置的20G磁盘)。**设置网络和主机名，点击开启以太网**，可酌情修改主机名 
    - 连接后显示`ens33已连接`，安装成功后使用`ip addr`查看ip地址也是看`ens33`那一栏
    - 使用`DVD ISO`可不关注
- 开始安装，安装期间设置Root密码(root)，创建用户(smalle/smalle)并设置为管理员
- **开启windows下和VMware相关的两块虚拟网卡**

## vmware使用

- `VMware Tools` 可以实现虚拟机和本机直接文本复制和文件传输
    - 打开虚拟机，点击虚拟机-安装VMware Tools
- **快照**：可对保留虚拟主机当前的配置状态
- **克隆虚拟主机**：基于某个虚拟主机进行克隆出一台主机。克隆后需要进行以下修改
    - `hostnamectl set-hostname aezocn` 修改主机名
    - `vi /etc/sysconfig/network-scripts/ifcfg-ens33`，修改`IPADDR`的值从而修改机器ip
    - vmware克隆时会自动改变mac地址，如果没有改变可在vmware控制台中重新生成一个mac地址：设置-网络适配器-高级-生成
- 移动虚拟机文件：可将xxx.vmx文件所在目录(如Virtual Machines)移动到其他磁盘，然后通过vmware打开虚拟机，选择xxx.vmx后，再选择已复制此虚拟即可

### VMware虚拟机的网络模式

- 桥接模式 [^3]
    - 默认使用VMnet0，不提供DHCP服务（DHCP是指由服务器控制一段IP地址范围，客户机登录服务器时就可以自动获得服务器分配的IP地址和子网掩码）。虚拟机和物理主机处于同等地位，像对待真实计算机一样手动配置IP、网关、子网掩码等
    - 主机和虚拟机需要在同一个网段上，类似存在于局域网。例如：主机IP为192.168.3.12，则虚拟机IP为192.168.3.10，网络中其他机器可以访问虚拟机，虚拟机也可以访问网络内其他机器
    - 主机需要有网络或接入到路由器，才能与虚拟机通信，虚拟机才可访问外网
- 仅主机模式
    - 默认使用VMnet1，提供DHCP服务
    - 虚拟机可以和物理主机互相访问，但虚拟机无法访问外部网络，若需要虚拟机上网，则需要主机联网并且共享其网
- NAT模式
    - 默认使用VMnet8，提供DHCP服务，可自动分配IP地址，也可手动设置IP
    - 虚拟机可以和物理主机互相访问，可以访问物理主机所在局域网，但是 局域网不能访问虚拟机。如：`A`、`B`机器在同一局域网，再A机器上安装虚拟机`C`，则`A-C`访问如下
        - `C`可直接访问`A`(可通过两个网段访问)、`B`
        - `B`访问`C`可以做路由分发。或在`A`上运行`nginx`进行路由(参考[http://blog.aezo.cn/2017/01/16/arch/nginx/](/_posts/arch/nginx))

### 远程连接虚拟机

- `ip addr`查看虚拟机地址(`ens33`/`eth0`)，`ipconfig`查看windows主机地址，并看能否双向`ping`通
- `systemctl status sshd` 查看ssh服务是否启动(如果未安装，可手动安装sshd)
- 使用`xshell`/`xftp`以ssh/sftp的方式连接，端口`22`，用户名要使用`smalle/smalle`（root连接失败）

## 常见问题

- `ip addr`不显示ip：查看NAT是否连接，宿主机VMware相关的网络适配器是否启用，`/etc/sysconfig/network-scripts/ifcfg-ens33`中`ONBOOT=yes`(修改后，`systemctl restart network`重启)
- ping的通宿主机，ping不通百度
    - 启用`VMware Network Adapter VMnet8`网卡，并在VMware中查看网段(编辑 - 虚拟网络编辑)
        - 网段：192.168.6.0
        - 网卡IP：192.168.6.1
        - 网关IP：192.168.6.2 (在VMware中设置 - NAT模式 - 网关IP，不能设置成网卡的IP)
    - 启动服务`VMware NAT service`、`VMware DHCP service`、`VMware Authorization Service`
    - 配置

        ```bash
        # resolv.conf中加入
        $ vi /etc/resolv.conf
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        # nameserver 114.114.114.114
        # nameserver 192.168.6.2 # 或者配置虚拟网关地址

        # vi /etc/sysconfig/network-scripts/ifcfg-ens33 并重启network。配置参数说明参考：https://blog.51cto.com/xtbao/1671739
        ONBOOT=yes
        BOOTPROTO=static  #启用静态IP地址
        IPADDR=192.168.6.10
        NETMASK=255.255.255.0
        # 网关IP的地址，不可写成网卡IP
        GATEWAY=192.168.6.2
        # 固定网卡DNS，此时每次重启network都会讲此DNS自动写到`/etc/resolv.conf`
        # DNS1=114.114.114.114
        # DNS2=114.114.115.115
        ```
- xshell卡在`To escape to local shell, press 'Ctrl+Alt+]'.`
    - 关闭防火墙
    - `vi /etc/ssh/sshd_config` 修改 `# UseDNS yes` 为 `UseDNS no`，并重启sshd

## windows安装

> 基于U盘安装windows可使用U大侠

- 下载iso镜像
- 新建虚拟机 - 典型 - 安装程序光盘映像文件(iso) - Microsoft Windows - ...
- 点击开启此与虚拟下拉箭头 - 打开电源是进入固件(Bois) - 设置CD-ROM Driver为首先启动 - 保存设置后进入安装系统
- 进入winPE系统，找到手动启动Ghost(备份程序，将备份镜像系统从CD盘复制到本地磁盘，之后运行此镜像。有的iso系统，Ghost程序在桌面的快捷方式是D盘，而iso挂载到CD上去一般默认是C盘，因此需要修改此快捷方式为对应iso所有在盘符) - 运行成功后找到Local-Disk-From Image-然后选择顶层的`*.gho`(文件大小最大的那个) - 然后进行镜像复制
- 再次进入Bois将虚拟机启动盘改为`Hard driver`
- 重启此虚拟进入系统安装界面

## mac os安装

- VMware 12.5.6
- VMware默认无法安装mac类型的系统，需要下载`VMware unlocker208`补丁
    - 将此补丁文件放在vmware安装目录(其他目录也行)
    - 管理员命令运行`win-install.cmd`
- 文件 - 新建虚拟主机 - 典型 - 稍后安装操作系统 - 版本MAC OS 10.12 - 创建一个虚拟机(名称为macos)根目录(如：C:\soft\vmware_server\macos)
- 修改新建虚拟机根目录中的`macos.vmx`文件：在`smc.present = "TRUE"`后添加`smc.version= 0`
- 根据虚拟机设置：添加硬盘 - SATA - 使用现有虚拟硬盘 - 选中`Mac.vmdk`(下载的mac系统硬盘文件，[谷歌硬盘下载地址](https://drive.google.com/drive/folders/1YneaDNMhveiByjo5iE3jNKLPHNYG6s0a)) - 并移除之前的硬盘
- 此硬盘文件`Mac.vmdk`安装过一次后，下次则无需安装，会保存之前使用的数据
- 可优化虚拟机设置为8G内存，2个处理器且每个4核
- 调整屏幕分辨率为全屏：虚拟机 - 安装VMware Tools - 此时mac系统会提示安装，安装完成后重启即可

### mac使用

- `command`按键即`win`按键
- 安装`Homebrew`包管理器
    - `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"` 安装
    - `brew install git` 使用brew安装git

### Ubuntu安装

参考《Ubuntu安装》[http://blog.aezo.cn/2016/11/20/linux/ubuntu-install/](/_posts/linux/ubuntu-install.md)

## Oracle VM VirtualBox

- 类似VMware的虚拟机。windows使用docker时，进行DockerToolbox安装则会安装此虚拟机
- 使用xshell连接：虚拟机设置 - 网络 - 网卡1 - 高级 - 端口转发 - 主机ip为本机ip地址(或127.0.0.1)，主机端口为虚拟机映射出来的端口(对应虚拟机的22端口) [^2]
- `右边Ctrl`可以切换虚拟机命令行鼠标状态
- 安装DockerToolbox运行的虚拟机默认用户为`docker/tcuser`

---

参考文章

[^1]: https://jingyan.baidu.com/article/a24b33cd12daf919ff002b58.html (VMware12.5虚拟机安装MacOS10)
[^2]: https://blog.csdn.net/ltyzsd/article/details/79041616 (Xshell连接docker)
[^3]: https://www.jianshu.com/p/85d41c49fdcd (VMware虚拟机的网络模式 — 桥接模式、仅主机模式、NAT模式的特点和配置)
