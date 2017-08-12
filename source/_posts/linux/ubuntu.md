---
layout: "post"
title: "Ubuntu"
date: "2016-11-20 13:16"
categories: [linux]
tags: [system, install, disk, bois]
---

## Ubuntu介绍

1. `Ubuntu`（乌班图）是一个以桌面应用为主的`Linux`操作系统，是比较流行的一款linux桌面系统，还有如：`Ubuntu`是属于`Debian`系列、`CentOS`则是属于`Redhat`系列
2. Ubuntu下载地址：[http://releases.ubuntu.com/](http://releases.ubuntu.com/)
3. 本文以`Ubuntu 16.04.1 LTS`为例记录U盘、硬盘安装方法(windows安装类似)

## Bios、分区、MBR

1. 设置电脑U盘启动
    - 我在电脑启动时按F12即可进入Bios界面（进入Bios的快捷键一般为ESC/F1/F11/F12等，可以网上查询电脑型号对应的启动Bios快捷键）
    - 找到`Boot`选项(或者`启动选项`等字眼)，调整`USB`相关的选项到顶部(即优先U盘或者移动硬盘启动)
2. 电脑分区 [^1]
    - windows进入分区界面：右键我的电脑 -> 管理 -> 存储 -> 磁盘管理
        - 扩展卷：将未使用的磁盘扩展到当前卷
        - 压缩卷：将当前卷未使用的空间压缩一定大小为未使用磁盘
    - 硬盘分区一般只能有4个主分区，其他都为逻辑分区，打开磁盘管理，根据图示，一般可从做到右获取到分区的表达方式
        - `(hd0, 1)` 表示第一块硬盘第二主分区; `(hd1, 4)` 表示第二块硬盘的第一逻辑分区(如移动硬盘，不论硬盘是否达到了4个主分区，逻辑分区都是从4开始计算)
    - linux上对磁盘和分区的命名
        - `hda` 一般是指IDE接口的硬盘，hda一般指第一块硬盘，类似的有hdb,hdc等
        - `sda` 一般是指SATA接口的硬盘，sda一般指第一块硬盘，类似的有sdb,sdc等
        - 现在的内核都会把硬盘，移动硬盘，U盘之类的识别为sdX的形式
        - 分区同上，4个主分区，其他为逻辑分区。但是linux上`sda1`才表示为第一主分区，以此类推
3. `MBR`: Master Boot Record. 即主引导记录，常被叫做引导程序 [^2]
    - 操作系统启动过程中有 一个很重要的引导程序——MBR。MBR是由三段组成的其中最重要的两段：是由446个字节组成的boot locader（引导加载器），和64个字节的分区表。在MBR的446字节也就是boot locader这段程序对于引导操作系统很重要。Linux中有两种boot locader可选，一种是LILO,一种就是GRUB。LILO现在已不用了。现在主要是使用GRUB来引导
    - GRUB是两段式的引导，第一阶段称为stage1,是存放在MBR中，主要来引导第二阶段stage2 这段主要放在/boot/grub/中的执行程序，主要是grub.conf这个文件
4. 文件系统
    - `NTFS` 为windows专用文件，具有良好的加密性，由于`FAT`、`FAT32`(linux可以失败)
    - `EXT4` 为Linux系统下的日志文件系统，是ext2、ext3的后续版本

## Ubuntu安装

Ubuntu安装方式分为两种：物理安装和虚拟安装。
- 物理安装：LiveCD、U盘、硬盘(包括移动硬盘)
- 虚拟安装：WUBI、虚拟机。缺点：需要依赖于主系统，如windows

### U盘安装 [^3]

1. 首先下载好ubuntu64位镜像文件`ubuntu-16.04.1-desktop-amd64.iso`（进入[http://releases.ubuntu.com/16.04/](http://releases.ubuntu.com/16.04/)，找到`64-bit PC (AMD64) desktop image`）
2. MD5校验：防止下载文件损坏（找到上述网址中的`MD5SUMS`文件，即可看到`17643c29e3c4609818f26becf76d29a3 *ubuntu-16.04.1-desktop-amd64.iso`）
2. 下载安装`UltraISO`，无需注册可以一直试用
3. 打开`UltraISO` -> 文件 -> 打开 -> 选择ubuntu的iso镜像文件 -> 启动 -> 写入硬盘映像(硬盘驱动器选择U盘，写入方式USB-HDD+) -> 写入(2分钟左右)。此时U盘已经刻录好系统
4. 将硬盘腾出一个未使用的空间，大小自己定义
4. Bios启动 -> 进入到刻录的U盘系统 -> `Install Ubuntu`（或者选择使用而不安装，进入之后还是可以安装） -> 点击桌面的`安装Ubuntu 16.04.1 LTS`进行安装 -> 前面一直下一步，到安装类型选择“其他选项”（可以自己创建调整分区）
5. 选择“空闲”的磁盘，双击进行分区，主要分3个区`/`、`swap`、`/home`（还有其他分区方案）
    - `/`：根据磁盘大小，我500G的磁盘 / 设置成200G。主分区，文件类型为EXT4，挂载点`/`
    - `swap`：大小<2G。逻辑分区，文件类型为交换空间，挂载点无
    - `/home`：大小为剩余磁盘。逻辑分区，文件类型为EXT4，挂载点`/home`
6. 安装启动引导的设备：选择`/`分区，如果有`/boot`分区则选择`/boot`分区
7. 一路下一步即可安装完成，重新启动即可。

### 硬盘安装 [^4] [^5]

1. 下载`EasyBCD` -> 安装后打开 -> 添加新条目 -> NeoGrub -> 安装 -> 配置 -> 在打开的配置文件（C:/NST/menu.lst）中写入如下代码。其中ro只读，splash显示启动画面；reboot重启；halt关机；[^6] (hd0,0) 一般会是表示C盘，实际按照上述知识自行配置

    ```
    title Install Ubuntu
    root (hd0,0)
    kernel (hd0,0)/vmlinuz.efi boot=casper iso-scan/filename=/ubuntu-16.04.1-desktop-amd64.iso ro splash  locale=zh_CN.UTF-8
    initrd (hd0,0)/initrd.lz
    title reboot
    reboot
    title halt
    halt
    ```
2. 将`ubuntu-16.04.1-desktop-amd64.iso`中casper文件夹下的initrd.lz和vmlinuz.efi复制到C盘根目录，并将镜像也复制进去。
3. 重启电脑，启动界面选择`NeoGrub`
4. 如果成功则会进入到buntu的桌面，首先`Ctrl+Alt+T`打开终端打开终端，运行`sudo umount -l /isodevice`去掉挂载的镜像文件
5. 安装U盘安装进行后续操作

### 移动硬盘安装 [^7]

实况记录
1. 可用U盘中刻录的系统进行移动硬盘安装
2. 移动硬盘如果已经分区了，则最后留出前面一段装Ubuntu系统，防止启动时引导不成功，
3. 如第一段500G未分配，第二段1500G为NTFS文件系统，且电脑只有一块内置硬盘，分区按照上述分区
    - 分好区后，`/`显示为`/dev/sdb2`；`swap`显示为`/dev/sdb5`；`/home`显示为`/dev/sdb6`
    - 于是将安装启动引导的设备选择为`/dev/sdb2`。如果选择内置硬盘，则标识通过Grub来启动Ubuntu或者windows，当拔掉移动硬盘可以windows无法启动。选择`/dev/sdb2`则需要按照通过EasyBCD等程序进行引导启动Ubuntu
    - 此时使用电脑`compac 14`启动无法直接进入Ubuntu系统，需要按`F9`选择启动项(已经在Bios中设置了启动优先级也无效)
        - 选择Efi启动可以（Efi -> ubuntu -> grubx64.efi）
        - 此时启动项中还会多出一个ubuntu(TS.....)，直接选择即可启动
        - 选择移动硬盘无法启动，按照文章 [^7] 可以解决此问题，但是仍然需要按`ESC -> F9`进行选择 (结合文章 [^8] )。测试时必须将`grldr`放在`NTFS`那个分区，`menu.lst`可放在`NTFS`分区或者`sdb2`即根分区
    - 按照文章 [^7] `三、为移动使用做准备` 操作失败，且附加中的`grldr`文件不适用，可下载此文件 [http://download.csdn.net/detail/hcx25909/5464025](http://download.csdn.net/detail/hcx25909/5464025)
4. (2017-02-16已解决，见下文) 使用电脑`Tinkpad E425`都未安装成功，U盘安装卡在logo页面；硬盘安装则报错`Error 13 invalid or unsupported executable format`；对于已经安装好的移动硬盘也是无法启动，于是利用U盘镜像进入到`Grub`命令行(也连接了移动硬盘)，运行一下命令仍然卡在命令行启动的最后一步。其中进入命令行后可输入`root (hd`，按`Tab`键进行提示磁盘

    ```
    root (hd1,1)
    kernel (hd1,1)/vmlinuz root=/dev/sdb2 ro splash
    initrd (hd1,1)/initrd.img
    boot
    ```

### 常见问题

1. 2017-02-16解决ThinkPad E425在安装Ubuntu卡在安装界面的问题 [^9]
    - 原因：主板BIOS设置中设置为双显卡切换的模式的时候，会出现这个问题
    - 解决方案：开机长按F1，进入BIOS设置。在config->Display->Graphics Device 设置显卡的模式为集成显卡 Integrated Graphics
2. 2017-04-24解决ubuntu启动长时间黑屏问题
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

[^1]: [https://zhidao.baidu.com/question/512380327.html](https://zhidao.baidu.com/question/512380327.html)
[^2]: [http://www.2cto.com/os/201202/120564.html](http://www.2cto.com/os/201202/120564.html)
[^3]: [http://www.linuxidc.com/Linux/2014-10/108402.htm](http://www.linuxidc.com/Linux/2014-10/108402.htm)
[^4]: [http://jingyan.baidu.com/article/e4d08ffdace06e0fd2f60d39.html](http://jingyan.baidu.com/article/e4d08ffdace06e0fd2f60d39.html)
[^5]: [http://v.youku.com/v_show/id_XMzEwODg2Njk2.html?f=16157628&from=y1.2-3.2](http://v.youku.com/v_show/id_XMzEwODg2Njk2.html?f=16157628&from=y1.2-3.2)
[^6]: [http://www.njliaohua.com/lhd_01ng13y9qv7k6x46aj4e_11.html](http://www.njliaohua.com/lhd_01ng13y9qv7k6x46aj4e_11.html)
[^7]: [http://forum.ubuntu.org.cn/viewtopic.php?p=149124#149124](http://forum.ubuntu.org.cn/viewtopic.php?p=149124#149124)
[^8]: [http://www.educity.cn/linux.1589874.html](http://www.educity.cn/linux.1589874.html)
[^9]: [ThinkPad E425在安装Ubuntu卡在安装界面](http://blog.csdn.net/u014466412/article/details/53666122)
