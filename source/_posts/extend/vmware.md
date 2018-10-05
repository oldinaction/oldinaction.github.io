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

### 远程连接虚拟机

- `ip addr`查看虚拟机地址(`ens33`/`eth0`)，`ipconfig`查看windows主机地址，并看能否双向`ping`通
- `systemctl status sshd` 查看ssh服务是否启动(如果未安装，可手动安装sshd)
- 使用`xshell`/`xftp`以ssh/sftp的方式连接，端口`22`，用户名要使用`smalle/smalle`（root连接失败）
- **局域网访问**：`A`、`B`机器在同一局域网，再A机器上安装虚拟机`C`，则`A-C`访问如下
    - `C`可直接访问`A`(可通过两个网段访问)、`B`
    - `B`访问`C`可在`A`上运行`nginx`进行路由(参考[http://blog.aezo.cn/2017/01/16/arch/nginx/](/_posts/arch/nginx))

## 常见问题

- `ip addr`不显示ip：查看NAT是否连接，宿主机VMware相关的网络适配器是否启用，`/etc/sysconfig/network-scripts/ifcfg-ens33`中`ONBOOT=yes`(修改后，`systemctl restart network`重启)
- ping的同宿主机，ping不通百度
    - 查询以太网属性是否共享，共享选择`VMware Network Adapter VMnet8`
    - 启动服务`VMware NAT service`和`VMware DHCP service`
    - 配置

        ```bash
        # resolv.conf中加入
        $ vi /etc/resolv.conf
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        # nameserver 114.114.114.114

        # /etc/sysconfig/network-scripts/ifcfg-ens33 并重启network
        ONBOOT=yes
        BOOTPROTO=static  #启用静态IP地址
        IPADDR=192.168.6.10
        NETMASK=255.255.255.0
        # VMware Virtual Ethernet Adapter for VMnet8的地址
        GATEWAY=192.168.6.1
        ```

## windows安装

> 基于U盘安装windows可使用U大侠

- 下载iso镜像
- 新建虚拟机 - 典型 - 安装程序光盘映像文件(iso) - Microsoft Windows - ...
- 点击开启此与虚拟下拉箭头 - 打开电源是进入固件(Bois) - 设置CD-ROM Driver为首先启动
- 重启此虚拟进入系统安装界面
- 再次进入Bois将虚拟机启动盘改为`Hard driver`

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

---

参考文章

[^1]: https://jingyan.baidu.com/article/a24b33cd12daf919ff002b58.html (VMware12.5虚拟机安装MacOS10)
