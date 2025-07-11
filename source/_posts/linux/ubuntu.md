---
layout: "post"
title: "Ubuntu"
date: "2016-11-20 13:16"
categories: [linux]
tags: [system]
---

## Ubuntu介绍

- `Ubuntu`（乌班图）是一个以桌面应用为主的`Linux`操作系统，是比较流行的一款linux桌面系统，还有如：`Ubuntu`是属于`Debian`系列、`CentOS`则是属于`Redhat`系列
- Ubuntu下载地址：[http://releases.ubuntu.com/](http://releases.ubuntu.com/)
- 本文以`Ubuntu 16.04.1 LTS`为例记录U盘、硬盘安装方法(windows安装类似)

## Ubuntu使用

### 使用ssh连接

- 默认没有安装sshd服务：`udo apt-get install openssh-server`，可通过`systemctl status sshd`查看状态
- 此时安装的openssh默认没有开启root用户登录权限，可修改sshd配置文件

### windows远程桌面连接Ubuntu [^10]

- Xmanager、VNC登录远程桌面
    - https://www.tightvnc.com/
- 基于xrdp配置远程桌面

    ```bash
    # 安装xrdp
    sudo apt-get install xrdp
    # 安装vnc4server
    sudo apt-get install vnc4server
    # 安装xubuntu-desktop
    sudo apt-get install xubuntu-desktop
    # 向xsession中写入xfce4-session(每个用户自己运行此行)
    echo "xfce4-session" > ~/.xsession
    # 查看xrdp服务状态(默认安装就已经开启了)
    systemctl status xrdp
    # 查看ip
    ipconfig
    ```
    - windows远程桌面连接登录
        - ip输入`192.168.17.196:3389`点击连接，3389为默认端口，外网也只需开通TCP的此端口映射
        - 在跳出的登录界面中选择`session: Xorg; username/password: root/root(ubuntu用户即可)`

### 常用设置

- 用户目录文件名显示英文

    ```bash
    export LANG=en_US
    xdg-user-dirs-gtk-update # 确认时，选择同意
    export LANG=zh_CN
    # 重启后系统会提示是否把转化好的目录改回中文。选择不再提示，并取消修改
    ```
- 设置locale为英文(修改系统语言为英文)
    - 法一：`export LC_ALL="en_US.UTF-8"` 重启
    - 法二
        - `sudo locale-gen en_US en_US.UTF-8`
        - `sudo dpkg-reconfigure locales`
- 将sh文件发送到桌面快捷方式
    - 在桌面创建`文件名.desktop`文件，内容如为 

        ```bash
        [Desktop Entry]
        Encoding=UTF-8
        Name=pycharm
        Exec=sh /home/smalle/soft/pycharm-2018.3/bin/pycharm.sh
        Icon=/home/smalle/soft/pycharm-2018.3/bin/pycharm.png
        Terminal=false
        Type=Application
        ```
    - 右键查看文件属性–权限–勾选可执行，执行
- Ubuntu16.04 笔记本合上盖子时不进入休眠

```bash
sudo vim /etc/systemd/logind.conf

# 修改如下
# HandleLidSwitch=suspend
HandleLidSwitch=ignore

sudo systemctl restart systemd-logind
```

### 安装程序

- 安装命令 `apt-get install xxx`
- 卸载命令 `apt-get remove xx` (会保留配置文件)
    - 完全卸载 `apt-get --purge xx`
- 查看包列表 `dpkg --list`
- 更新源 `apt-get update`
- 安装deb格式文件
    - `dpkg -i file.deb` deb是debian linus的安装格式，跟red hat的rpm非常相似

#### 常用软件

- 安装[wine](https://wiki.winehq.org/Ubuntu_zhcn)，即可在ubuntu上运行exe程序
    - `sudo apt-get install winetricks` 
    - 执行`winetricks`即可管理wine环境进行扩展管理
- 安装docker

    ```bash
    sudo apt-get install docker.io
    sudo gpasswd -a ${USER} docker # 把当前用户加入到docker组
    cat /etc/group | grep ^docker # 查看是否添加成功
    systemctl restart docker # 重启。如果仍然无法执行docker命令，可以退出当前用户再登录尝试
    ```

### 文件

- 显示/隐藏隐藏文件和文件夹：`Ctrl + H`

### 其他问题

- ubuntu-18.04.1基于pycharm创建python项目报错`No module named 'distutils.core'`. 解决办法`sudo apt-get install python3-distutils`

## Ubuntu安装

### Bios、分区、MBR

- 设置电脑U盘启动
    - 我在电脑启动时按F12即可进入Bios界面（进入Bios的快捷键一般为ESC/F1/F11/F12等，可以网上查询电脑型号对应的启动Bios快捷键）
    - 找到`Boot`选项(或者`启动选项`等字眼)，调整`USB`相关的选项到顶部(即优先U盘或者移动硬盘启动)
- 电脑分区 [^1]
    - windows进入分区界面：右键我的电脑 -> 管理 -> 存储 -> 磁盘管理
        - 扩展卷：将未使用的磁盘扩展到当前卷
        - 压缩卷：将当前卷未使用的空间压缩一定大小为未使用磁盘
    - 硬盘分区一般只能有4个主分区，其他都为逻辑分区，打开磁盘管理，根据图示，一般可从做到右获取到分区的表达方式
        - `(hd0, 1)` 表示第一块硬盘第二主分区; `(hd1, 4)` 表示第二块硬盘的第一逻辑分区(如移动硬盘，不论硬盘是否达到了4个主分区，逻辑分区都是从4开始计算)
    - **linux上对磁盘和分区的命名**
        - `hda` 一般是指IDE接口的硬盘，hda一般指第一块硬盘，类似的有hdb,hdc等
        - `sda` 一般是指SATA接口的硬盘，sda一般指第一块硬盘，类似的有sdb,sdc等
        - 现在的内核都会把硬盘，移动硬盘，U盘之类的识别为sdX的形式
        - 分区同上，4个主分区，其他为逻辑分区。但是linux上`sda1`才表示为第一主分区，以此类推
- `MBR`: Master Boot Record. 即主引导记录，常被叫做引导程序 [^2]
    - 操作系统启动过程中有 一个很重要的引导程序——MBR。MBR是由三段组成的其中最重要的两段：是由446个字节组成的boot locader（引导加载器），和64个字节的分区表。在MBR的446字节也就是boot locader这段程序对于引导操作系统很重要。Linux中有两种boot locader可选，一种是LILO,一种就是GRUB。LILO现在已不用了。现在主要是使用GRUB来引导
    - GRUB是两段式的引导，第一阶段称为stage1,是存放在MBR中，主要来引导第二阶段stage2 这段主要放在/boot/grub/中的执行程序，主要是grub.conf这个文件
- 文件系统
    - `NTFS` 为windows专用文件，具有良好的加密性，由于`FAT`、`FAT32`(linux可以失败)
    - `EXT4` 为Linux系统下的日志文件系统，是ext2、ext3的后续版本

### 安装

Ubuntu安装方式分为两种：物理安装和虚拟安装。
- 物理安装：LiveCD、U盘、硬盘(包括移动硬盘)
- 虚拟安装：WUBI、虚拟机。缺点：需要依赖于主系统，如windows

#### U盘安装 [^3]

> windows系统可以使用[U大侠](http://www.udaxia.com/)等工具快速制作U盘启动盘，之后只需要将系统iso镜像拷贝到U盘GHO文件夹，在新机器上U盘启动安装即可。如果之前装过Linux，则需要重新将硬盘分区，然后重启。（如果不成功可尝试重新制造U盘启动盘）

- 首先下载好ubuntu64位镜像文件`ubuntu-16.04.1-desktop-amd64.iso`（进入[http://releases.ubuntu.com/16.04/](http://releases.ubuntu.com/16.04/)，找到`64-bit PC (AMD64) desktop image`）
- MD5校验：防止下载文件损坏（找到上述网址中的`MD5SUMS`文件，即可看到`17643c29e3c4609818f26becf76d29a3 *ubuntu-16.04.1-desktop-amd64.iso`）
- 下载安装[UltraISO](https://ultraiso.net/)，无需注册可以一直试用
- **打开`UltraISO` -> 文件 -> 打开 -> 选择ubuntu的iso镜像文件 => 启动 -> 写入硬盘映像(硬盘驱动器选择U盘，写入方式USB-HDD+) -> 写入(几分钟)。**此时U盘已经刻录好系统
- 将硬盘(需要安装Ubuntu的机器)腾出一个未使用的空间，大小自己定义
- Bios启动 -> 进入到刻录的U盘系统 -> `Install Ubuntu`（或者选择使用而不安装，进入之后还是可以安装） -> 点击桌面的`安装Ubuntu 16.04.1 LTS`进行安装 -> 前面一直下一步，到安装类型选择"其他选项"（可以自己创建调整分区）
- 选择"空闲"的磁盘，双击进行分区，主要分3个区`/`、`swap`、`/home`（还有其他分区方案）
    - `/`：根据磁盘大小，我500G的磁盘 / 设置成200G。主分区，文件类型为EXT4，挂载点`/`
    - `swap`：大小2G/4G(8G/16G内存可分配4G，再按内存适当调高，如32G分6G)。逻辑分区，文件类型为交换空间，挂载点无。最终显示如`tmpfs`
    - `/home`：大小为剩余磁盘。逻辑分区，文件类型为EXT4，挂载点`/home`
- 安装启动引导的设备：选择`/`分区，如果有`/boot`分区则选择`/boot`分区
- 一路下一步即可安装完成，重新启动即可。
- ubuntu-18.04.1-desktop-amd64.ios安装报错`无法将grub-efi-amd64-signed 安装到`，解决方案(分区调整)
    - `/boot`：根据磁盘大小，我500G的磁盘 / 设置成500G。主分区，文件类型为EXT4，挂载点`/boot`
    - (省略)`efi`：500M。主分区，文件类型为EFI，挂载点无
    - `swap`：大小4G(8G/16G内存可分配4G，再按内存适当调高，如32G分6G)。主分区，文件类型为交换空间，挂载点无。最终显示如`tmpfs`
    - `/`：根据磁盘大小，我500G的磁盘 / 设置成200G。主分区，文件类型为EXT4，挂载点`/`
    - `/home`：大小为剩余磁盘。逻辑分区，文件类型为EXT4，挂载点`/home`

#### 硬盘安装 [^4] [^5]

- 下载`EasyBCD` -> 安装后打开 -> 添加新条目 -> NeoGrub -> 安装 -> 配置 -> 在打开的配置文件（C:/NST/menu.lst）中写入如下代码。其中ro只读，splash显示启动画面；reboot重启；halt关机；[^6] (hd0,0) 一般会是表示C盘，实际按照上述知识自行配置

    ```bash
    title Install Ubuntu
    root (hd0,0)
    kernel (hd0,0)/vmlinuz.efi boot=casper iso-scan/filename=/ubuntu-16.04.1-desktop-amd64.iso ro splash  locale=zh_CN.UTF-8
    initrd (hd0,0)/initrd.lz
    title reboot
    reboot
    title halt
    halt
    ```
- 将`ubuntu-16.04.1-desktop-amd64.iso`中casper文件夹下的initrd.lz和vmlinuz.efi复制到C盘根目录，并将镜像也复制进去。
- 重启电脑，启动界面选择`NeoGrub`
- 如果成功则会进入到buntu的桌面，首先`Ctrl+Alt+T`打开终端打开终端，运行`sudo umount -l /isodevice`去掉挂载的镜像文件
- 类似U盘安装进行后续操作

#### 移动硬盘安装 [^7]

实况记录
- 可用U盘中刻录的系统进行移动硬盘安装
- 移动硬盘如果已经分区了，则最后留出前面一段装Ubuntu系统，防止启动时引导不成功，
- 如第一段500G未分配，第二段1500G为NTFS文件系统，且电脑只有一块内置硬盘，分区按照上述分区
    - 分好区后，`/`显示为`/dev/sdb2`；`swap`显示为`/dev/sdb5`；`/home`显示为`/dev/sdb6`
    - 于是将安装启动引导的设备选择为`/dev/sdb2`。如果选择内置硬盘，则标识通过Grub来启动Ubuntu或者windows，当拔掉移动硬盘可以windows无法启动。选择`/dev/sdb2`则需要按照通过EasyBCD等程序进行引导启动Ubuntu
    - 此时使用电脑`compac 14`启动无法直接进入Ubuntu系统，需要按`F9`选择启动项(已经在Bios中设置了启动优先级也无效)
        - 选择Efi启动可以（Efi -> ubuntu -> grubx64.efi）
        - 此时启动项中还会多出一个ubuntu(TS.....)，直接选择即可启动
        - 选择移动硬盘无法启动，按照文章 [^7] 可以解决此问题，但是仍然需要按`ESC -> F9`进行选择 (结合文章 [^8] )。测试时必须将`grldr`放在`NTFS`那个分区，`menu.lst`可放在`NTFS`分区或者`sdb2`即根分区
    - 按照文章 [^7] `三、为移动使用做准备` 操作失败，且附加中的`grldr`文件不适用，可下载此文件 [http://download.csdn.net/detail/hcx25909/5464025](http://download.csdn.net/detail/hcx25909/5464025)
- (2017-02-16已解决，见下文) 使用电脑`Tinkpad E425`都未安装成功，U盘安装卡在logo页面；硬盘安装则报错`Error 13 invalid or unsupported executable format`；对于已经安装好的移动硬盘也是无法启动，于是利用U盘镜像进入到`Grub`命令行(也连接了移动硬盘)，运行一下命令仍然卡在命令行启动的最后一步。其中进入命令行后可输入`root (hd`，按`Tab`键进行提示磁盘

    ```bash
    root (hd1,1)
    kernel (hd1,1)/vmlinuz root=/dev/sdb2 ro splash
    initrd (hd1,1)/initrd.img
    boot
    ```

#### 常见问题

- 2017-02-16解决ThinkPad E425在安装Ubuntu卡在安装界面的问题 [^9]
    - 原因：主板BIOS设置中设置为双显卡切换的模式的时候，会出现这个问题
    - 解决方案：开机长按F1，进入BIOS设置。在config->Display->Graphics Device 设置显卡的模式为集成显卡 Integrated Graphics
- 2017-04-24解决ubuntu启动长时间黑屏问题
    - 自己的笔记本是thinkpad e425，双显卡，装ubuntu一直卡在启动页面上，后来在bios中关闭了独显，所以成功将ubuntu装上
之后，开机时候直至显示用户登陆的页面时，屏幕都是黑屏
    - 安装 v86d 和 hwinfo，然后查看显卡支持的分辨率
        - `sudo apt-get install v86d hwinfo`
        - `sudo hwinfo --framebuffer`
    - 编辑`/etc/default/grub`，添加`GRUB_GFXPAYLOAD_LINUX=1024×768x24`
    - 启用framebuffer：`echo FRAMEBUFFER=y | sudo tee /etc/initramfs-tools/conf.d/splash`
    - 更新设置
        - `sudo update-grub`
        - `sudo update-grub2`
        - `sudo update-initramfs -u`
    - 重启


---

参考文章

[^1]: https://zhidao.baidu.com/question/512380327.html
[^2]: http://www.2cto.com/os/201202/120564.html
[^3]: http://www.linuxidc.com/Linux/2014-10/108402.htm
[^4]: http://jingyan.baidu.com/article/e4d08ffdace06e0fd2f60d39.html
[^5]: http://v.youku.com/v_show/id_XMzEwODg2Njk2.html?f=16157628&from=y1.2-3.2
[^6]: http://www.njliaohua.com/lhd_01ng13y9qv7k6x46aj4e_11.html
[^7]: http://forum.ubuntu.org.cn/viewtopic.php?p=149124#149124
[^8]: http://www.educity.cn/linux.1589874.html
[^9]: http://blog.csdn.net/u014466412/article/details/53666122 (ThinkPad-E425在安装Ubuntu卡在安装界面)
[^10]: https://blog.csdn.net/woodcorpse/article/details/80503232


