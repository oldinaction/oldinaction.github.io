---
layout: "post"
title: "linux系统"
date: "2016-07-21 19:19"
categories: linux
tags: [linux, shell]
---

## 基础知识

### 发行版

- Linux的发行版本可以大体分为两类，一类是商业公司维护的发行版本，一类是社区组织维护的发行版本，前者以著名的Redhat（RHEL）为代表，后者以Debian为代表
- `Redhat系列`：包括`RHEL`(Redhat Enterprise Linux)、`Fedora Core`(由原来的Redhat桌面版本发展而来，免费版本)、`CentOS`(RHEL的社区克隆版本，免费)
- `Debian系列`：包括`Debian`和`Ubuntu`等
- Debian最具特色的是`apt-get / dpkg`包管理方式; Redhat是`yum`包管理方式

### 系统信息查询

- 查看操作系统版本 `cat /proc/version`
    - 如腾讯云服务器 `Linux version 3.10.0-327.36.3.el7.x86_64 (builder@kbuilder.dev.centos.org) (gcc version 4.8.5 20150623 (Red Hat 4.8.5-4) (GCC) ) #1 SMP Mon Oct 24 16:09:20 UTC 2016` 中的 `3.10.0` 表示内核版本 `x86_64` 表示是64位系统
- 查看CentOS版本 **`cat /etc/redhat-release`/`cat /etc/system-release`** 如：CentOS Linux release 7.2.1511 (Core)
- `cat /proc/meminfo && free` 查看内存使用情况
    - `/proc/meminfo`为内存详细信息
        - `MemTotal` 内存总数
        - `MemFree` 系统尚未使用的内存
        - `MemAvailable` 应用程序可用内存数。系统中有些内存虽然已被使用但是可以回收的，比如cache/buffer、slab都有一部分可以回收，所以MemFree不能代表全部可用的内存，这部分可回收的内存加上MemFree才是系统可用的内存，即：**MemAvailable ≈ MemFree + Buffers + Cached**。MemFree是说的系统层面，MemAvailable是说的应用程序层面
    - `free` 为内存概要信息
- `cat /proc/cpuinfo` 查看CPU使用情况
- 磁盘使用查看
    - `df -h` 查看磁盘使用情况和挂载点信息
        - `df /root` **查看/root目录所在挂载点**（一般/dev/vda1为系统挂载点，重装系统数据无法保留；/dev/vab或/dev/mapper/centos-root等用来存储数据）
    - `du -h --max-depth=1` 查看当前目录以及一级子目录磁盘使用情况。二级子目录可改成2
- `hostname` 查看hostname
    - `hostnamectl set-hostname aezocn` 修改主机名并重启

### 查看网络信息

- `ip addr` 查看机器ip，显示说明
    - `lo`为内部网卡接口，不对外进行广播；`eth0`/`ens33`网卡接口会对外广播
    - `link/ether 00:0c:29:bb:ea:e2`中link/ether后为`mac`地址
    - `inet 192.168.6.130/24 brd 192.168.6.255 scope global ens33`中192.168.6.130/24为内网ip和子网掩码(24代表32位中有24个1其他都是0，即255.255.255.0) `brd`(broadcast)后为广播地址
- `ifconfig`命令(centos7无法使用可安装工具`yum install net-tools`)
    - `ifconfig ens33:1 192.168.6.10` 给网络接口ens33绑定一个虚拟ip
    - `ifconfig ens33:1 down` 删除此虚拟ip
    - 添加虚拟ip方式二
        - 编辑类似文件`vi /etc/sysconfig/network-scripts/ifcfg-ens33`
        - 加入代码`IPADDR=192.168.6.130`(本机ip)和`IPADDR1=192.168.6.135`(添加的虚拟ip，可添加多个。删除虚拟ip则去掉IPADDR1)，可永久生效
        - 重启网卡`systemctl restart network`
        - 修改ip即修改上述`IPADDR`
- `ping 192.168.1.1`(或者`ping www.baidu.com`) 检查网络连接
- `telnet 192.168.1.1 8080` 检查端口(`yum -y install telnet`)
- `curl http://www.baidu.com` 获取网页内容
    - `curl --socks5 127.0.0.1:1080 http://www.qq.com` 使用socks5协议
- `wget http://www.baidu.com` 检查是否可以上网，成功会显示或下载一个对应的网页
    - `wget -o /tmp/wget.log -P /home/data --no-parent --no-verbose -m -D www.qq.com -N --convert-links --random-wait -A html,HTML http://www.qq.com` wget爬取网站
- `netstat -lnp` 查看端口占用情况(端口、PID)
    - `ss -ant` CentOS 7 查看所有监听端口
    - root运行：`sudo netstat -lnp` 可查看使用root权限运行的进程PID(否则PID隐藏)
    - `netstat -tnl` 查看开放的端口
    - `netstat -lnp | grep tomcat` 查看含有tomcat相关的进程
    - **`yum install net-tools`** 安装net-tools即可使用netstat、ifconfig等命令
- `ss -lnt` 查看端口

### 查看进程信息

- **`ps -ef | grep java`**(其中java可换成run.py等)
    - 结果如：`root   23672 22596  0 20:36 pts/1    00:00:02 python -u main.py`. 运行用户、进程id、...
- `pwdx <pid>` **查看进程执行目录**(同`ls -al /proc/8888 | grep cwd`)
- `ls -al /proc/进程id` 查看此进程信息
    - `cwd`符号链接的是进程运行目录 **`ls -al /proc/8888 | grep cwd`**
    - `exe`符号连接就是执行程序的绝对路径
    - `cmdline`就是程序运行时输入的命令行命令
    - `environ`记录了进程运行时的环境变量
    - `fd`目录下是进程打开或使用的文件的符号连接

#### top命令

- 自带程序`top`查看，推荐安装功能更强大的`htop`
- 面板介绍 [^11]
    - `Load Average`: 负载均值。对应的三个数分别代表不同时间段的系统平均负载（一分钟、五 分钟、以及十五分钟），它们的数字当然是越小越好；数字越高说明服务器的负载越大。如果是单核，load=1表示CPU所有的资源都在处理请求，一般维持0.7以下，如果长期在1左右建议进行监测，维持在2左右则说明负载很高。多核情况，**即负载最好要小于`CPU个数 * 核数 * 0.7`**

    ![top面板介绍](/data/images/linux/top-view.jpg)

    - VIRT 值最高的进程就是内存使用最多的进程
    - S列进程状态：一般 I 代表空闲，R 代表运行，S 代表休眠，D 代表不可中断的睡眠状态，Z 代表(zombie)僵尸进程，T 或 t 代表停止
- 快捷键

    ```bash
    # h 进入帮助；Exc/q 退出帮助
    Help for Interactive Commands - procps-ng version 3.3.10
    Window 3:Mem: Cumulative mode On.  System: Delay 3.0 secs; Secure mode Off.

        Z,B,E,e   Global: 'Z' colors; 'B' bold; 'E'/'e' summary/task memory scale
        # l 显示负载(默认显示)；t 显示CPU使用图示；m 显示内存使用图示
        l,t,m     Toggle Summary: 'l' load avg; 't' task/cpu stats; 'm' memory info
        0,1,2,3,I Toggle: '0' zeros; '1/2/3' cpus or numa node views; 'I' Irix mode
        f,F,X     Fields: 'f'/'F' add/remove/order/sort; 'X' increase fixed-width

        # <,> 切换排序列
        L,&,<,> . Locate: 'L'/'&' find/again; Move sort column: '<'/'>' left/right
        R,H,V,J . Toggle: 'R' Sort; 'H' Threads; 'V' Forest view; 'J' Num justify
        # c 显示Command详细命令
        c,i,S,j . Toggle: 'c' Cmd name/line; 'i' Idle; 'S' Time; 'j' Str justify
        # x,y 高亮显示排序列和运行行
        x,y     . Toggle highlights: 'x' sort field; 'y' running tasks
        z,b     . Toggle: 'z' color/mono; 'b' bold/reverse (only if 'x' or 'y')
        u,U,o,O . Filter by: 'u'/'U' effective/any user; 'o'/'O' other criteria
        n,\#,^O  . Set: 'n'/'#' max tasks displayed; Show: Ctrl+'O' other filter(s)
        C,...   . Toggle scroll coordinates msg for: up,down,left,right,home,end

        k,r       Manipulate tasks: 'k' kill; 'r' renice
        d or s    Set update interval
        W,Y       Write configuration file 'W'; Inspect other output 'Y'
        q         Quit
                ( commands shown with '.' require a visible task display window ) 
    Press 'h' or '?' for help with Windows,
    Type 'q' or <Esc> to continue 
    ```
  
### 基础操作

- 强制关闭重启
    - `shutdown -r now` root登录可立刻重启
    - `reboot` 重启
    - 关闭某个PID进程 `kill PID`
        - `netstat -lnp` 查看所有进场信息(端口、PID)
        - 强制杀进程 `kill -s 9 PID`
        - `yum install psmisc` centos7精简版无`killall`命令，需要安装此包
            - `killall -s 9 java` 杀死所有java进程
- 程序安装
    - `yum`安装(还有其他类型的安装参考`《centos-server-guide》`)
    - `rpm`格式文件安装(rpm: redhat package manage)
        - `rpm -ivh 安装包名` 安装程序包
        - `rpm -qa` 查看安装的程序包(`rpm -qa | grep vsftpd` 查看是否安装vsftpd)
        - `rpm -e rpm包名` 卸载某个包(程序)，其中的rpm包名可通过上述命令查看
- 程序运行
    - 运行sh文件：进入到该文件目录，运行`./xxx.sh`
    - 脱机后台运行sh文件：**`nohup bash startofbiz.sh > /dev/null 2>&1 &`**
        - 打印日志后台运行`nohup java -jar /xxx/xxx.jar > my.log 2>&1 &`
        - 运行二进制文件：`nohup ./mybash > my.log 2>&1 &` 其中mybash为可执行的二进制文件
        - **sudo形式运行**：`nohup sudo -b ./mybash > my.log 2>&1 &`（`nohup sudo ./mongod > /dev/null 2>&1 &`）
        - 可解决利用客户端连接服务器，执行的程序当客户端退出后，服务器的程序也停止了
        - `nohup`这个表示脱机执行，默认在当前目录生成一个`nohup.out`的日志文件
        - `&` 最后面的&表示放在后台执行 [^8]
            - `exit` 或 `logout` 正常登出并不会终止 & 的后台任务，此时的 SIGHUP 信号只会发给前台任务
            - 关闭窗口或断网，前后台任务都会收到 SIGHUP 信号，但如果我们试用了 nohup 则可以屏蔽此信号，让任务仍不被中断。(遇到一次使用nohup也无法解决关闭窗口程序停止，最终只能后台运行并通过exit退出)
            - 进程收到 SIGHUP 信号时默认的操作是退出执行。但我们可以在代码里使用信号捕捉的方法，捕捉或忽略 SIGHUP 信号的处理，这样进程就不会退出了
        - `startofbiz.sh > my.log` 表示startofbiz.sh的输出重定向到my.log
        - `2>&1` 表示将错误输出重定向到标准输出
            - `0`：标准输入；`1`：标准输出；`2`：错误输出
    - `Ctrl+c` 关闭程序，回到终端
    - `Ctrl+z` 后台运行程序，回到终端
- 设置环境变量
    - `/etc/profile` 记录系统环境变量，在此文件末尾加入`export JAVA_HOME=/usr/java/jdk1.8` 将`JAVA_HOME`设置成所有用户可访问
    - `/home/smalle/.bash_profile` 每个用户登录的环境变量(/home/smalle为用户家目录)
        - `.bash_profile` 登录后的环境变量
        - `.bashrc` 登录后自动运行(类似rc.local)
    - `echo $JAVA_HOME` 查看其值
    - 设置临时环境变量：在命令行运行`export JAVA_HOME=/usr/java/jdk1.8`(重新打开命令行则失效)
    
### 服务相关命令

- **自定义服务参考[《nginx.md》(基于编译安装tengine)](/_posts/arch/nginx.md#基于编译安装tengine)**
- systemctl：主要负责控制systemd系统和服务管理器，是`chkconfig`和`service`的合并(systemctl管理的脚本文件目录为`/usr/lib/systemd/system` 或 `/etc/systemd/system`)
    - `systemctl start|status|restart|stop nginx.service` 启动|状态|重启|停止服务(.service可省略，active (running)标识正在运行)
    - `systemctl list-units --type=service` 查看所有服务
        - `systemctl list-unit-files` 查看所有可用单元
    - `systemctl enable nginx` 设置开机启动
    - `systemctl disable nginx` 停止开机启动
    - `systemctl cat sshd` 查看服务的配置文件
    - **`tail -f /var/log/messages`** 查看服务启动日志
- chkconfig：提供了一个维护`/etc/rc[0~6]d/init.d`文件夹的命令行工具
    - `chkconfig --list <nginx>` 查看(nginx)服务列表
    - `chkconfig --add nginx` 将nginx加入到服务列表(需要 **`/etc/rc.d/init.d`**/软路径`/etc/init.d` 下有相关文件`nginx.service`或`nginx`脚本)
    - `chkconfig --del nginx` 关闭指定的服务程序
    - `chkconfig nginx on` 设置nginx服务开机自启动（对于 on 和 off 开关，系统默认只对运行级345有效，但是 reset 可以对所有运行级有效）
    - 设置开机自启动
        - 在`/etc/init.d`目录创建脚本文件，并设置成可执行`chmod +x my_script`
            ```bash
            # 自启动脚本的注释中必须有chkconfig、description两行注释(chkconfig会查看所有注释行)
            # chkconfig参数一表示在运行级别2345时默认代开(一般服务器的启动级别为3多用户启动)，使用`-`表示默认关闭(不自动启动)；参数2表示启动顺序(越小越优先)；参数3表示停止顺序(停止并不会重新执行脚本，而是停止此进程)
            
            #!/bin/sh
            # chkconfig: 2345 50 50
            # description: 通用自动启动脚本
            # processname: common-init
            # config: 如果需要的话，可以配置

            # echo日志会记录到 /var/log/messages 中(系统本身会记录此服务的启动开始和结束状态)
            echo iptables-init start...
            iptables-restore < /etc/sysconfig/iptables
            echo iptables-init end...
            ```
        - 将启动脚本添加到chkconfig列表：`chkconfig --add my_script`
        - 之后可在`/var/log/messages`中查看启动日志信息；也可通过`systemctl status my_script`查看服务状态，如`active (exited)`表示服务有效中，但是程序已执行完成
- service：`service nginx start|stop|reload` 服务启动等命令

### 常用语法参考《shell.md》

### 常用命令

- `ls --help` 查看ls的命令说明(或`help ls`)
- `man ls` 查看ls的详细命令说明
- `clear` 清屏
- `\` 回车后可将命令分多行运行(后面不能带空格)
- `date` 显示当前时间; `cal` 显示日历
- `last` 查看最近登录用户
- `history` 查看历史执行命令
    - 默认记录1000条命令，编号越大表示越近执行。用户所键入的命令都会记录在用户家目录下的`.bash_history`文件中
    - 如果在服务器中干了不好的事情，可以通过`history -c`命令进行清除，那么其他人登录终端时就无法查看历史操作命令了。但此命令并不会清除保存在文件中的记录，因此需要手动删除.bash_profile文件中的记录
- `wall <msg>` 通知所有人登录人一些信息

### 文本处理

- 文本处理命令：`cut`、`sort`、`join`、`sed`、`awk`
- `cut` 文本剪切(必须基于文件进行操作)，如查看用户数：`wc -l /etc/passwd | cut -d' ' -f1`
    - `-d` 指定字段分隔符，默认是空格
    - `-f` 指定要显示的字段(`-f 1,3`、`-f 1-3`)
- `sort` 文本排序
    - `-n` 数值排序
    - `-r` 降序
    - `-t` 字段分隔符
    - `-k` 以哪个字段为关键字进行排序
    - `-u` 排序后相同的行只显示一次
    - `-f` 排序时忽略字符大小写	
- `wc` 文本统计
    - 统计指定文本文件的行数(`-l`)、字数、字节数 
    - 参数-l、-w、-c、-L

## 文件系统

### 磁盘

- `df -h` 查看磁盘使用情况、分区、挂载点(**只会显示成功挂载的分区，新磁盘需要进行分区和挂载**)
    - `df -h /home/smalle` 查询目录使用情况、分区、挂载点（一般/dev/vda1为系统挂载点，重装系统数据无法保留；/dev/vab或/dev/mapper/centos-root等用来存储数据）
    - `df -Th` 查询文件系统格式
- `du -h --max-depth=1 | sort -h` **查看当前目录以及一级子目录磁盘使用情况。二级子目录可改成2，并按从大倒小排列**
    - `du -sh /home/smalle | sort -h` 查看某个目录
    - `du`它的数据是基于文件获取，可以跨多个分区操作。`df`它的数据基于分区元数据，只能针对整个分区
    - `lsof | grep deleted`列举删除的文件(可能会造成du/df统计的值不一致)
- `lsblk` 树形显示
- `dmesg | grep CD` 显示光盘信息。启动dmesg为显示硬件信息，可用于硬件故障诊断
- 磁盘分区和挂载
    - 参考《阿里云服务器 ECS > 块存储 > 云盘 > 分区格式化数据盘 > Linux 格式化数据盘》 [^10]
    - 一般阿里云服务器买的磁盘未进行格式化文件系统和挂载，`df -h`无法查询到磁盘设备，只能通过`fdisk -l`查看磁盘设备
    - 阿里云`/dev/vda`表示系统盘，`/dev/vdb-z`表示数据盘，`dev/xvd?`表示非I/O优化实例。`/dev/vda1`/`/dev/vdb1`表示对应磁盘上的分区

    ```bash
    # **最好使用root用户进行操作，`fdisk -l`一般用户查询不到**
    # 查看磁盘设备。包括系统盘和数据盘，如：Disk：/dev/vda ... Disk：/dev/vdb表示有两块磁盘
    fdisk -l

    # 查看/dev/vdb磁盘设备的分区情况(/dev/vdb1表示此磁盘的第一个分区)
    fdisk -l /dev/vdb

    # 1.进行磁盘分区
    fdisk /dev/vdb
    # 输入`p`：查看数据盘的分区情况(输入m获取帮助)
    # 再次输入`n`：创建一个新分区
    # 分区类型选择（p主分区, e扩展分区），新磁盘第一次分区可选择主分区，输入p; 分区号码从1-4，可以输入最小可用分区号
    # 第一个扇区一般都使用默认的，直接回车即可；最后一个扇区大小根据你自己需要指定，但是一定要在给定范围内，这里是2048-20971519(10G的磁盘)，如果整个磁盘就分一个分区则继续回车(默认即为最大)，如根需要此分区设置大小为200M，则输入`+200M`（单位可为K/M/G/T/P）
    # 再次输入`p`查看将要到达的分区情况
    # 确认后输入`w`写入分区表，并在写入后退出；输入`q`放弃分区并退出
    # 到这里分区就完成了，但是新的分区还是不能使用的，要对新分区进行格式化，然后将它挂载到某个可访问目录下才能进行操作
        # 如果w后提示 WARNING: Re-reading the partition table failed with error 16: Device or resource busy. The kernel still uses the old table. The new table will be used at the next reboot or after you run partprobe(8) or kpartx(8)
        # 为了不reboot就能生效，强制内核重新读取分区表，执行命令`partprobe`后继续后续命令
        # partprobe

    # 查看分区(未挂载的分区也会显示)
    cat /proc/partitions

    # 2.为此分区创建一个ext4文件系统，此时会格式化磁盘. 如果需要在 Linux、Windows 和 Mac 系统之间共享文件，可以使用 mkfs.vfat 创建 VFAT 文件系统
    mkfs.ext4 /dev/vdb1 # centos7默认xfs文件格式，此时可使用 mkfs.xfs /dev/vdb1

    # 如果使用LVM功能，则需先执行LVM相关命令创建LV分区后再挂载
    # 3.挂载分区到/home目录(需要确保此目录存在，并不会影响父目录的挂载。如此时只会改变 /home，不会影响 /)，**如果/home目录之前有数据会被清除，建议先备份**
    mount /dev/vdb1 /home

    # 4.备份 /etc/fstab（建议）
    cp /etc/fstab /etc/fstab.bak
    # 向 /etc/fstab 写入新分区信息(注意目录和上面对应)，防止下次开机挂载丢失（不执行此步骤只是临时挂载到相应目录，下次开机则会丢失挂载）
    echo /dev/vdb1 /home ext4 defaults 0 0 >> /etc/fstab

    # 查看目前磁盘空间和使用情(只会显示成功挂载的分区)
    df -h

    # 重新挂载了磁盘需要重启
    # reboot
    ```
- LVM使用(centos安装时如果使用分区类型为LVM则会出现时/dev/mapper/centos-root等)
    - LVM使用参考 https://blog.51cto.com/13438667/2084924

        ![lvm](/data/images/lang/lvm.png)
        
        ```bash
        # **先fdisk创建分区/dev/vdb1和/dev/vdb2，无需格式化(略)**
        # pvcreate命令在新建的分区上创建PV
        pvcreate /dev/vdb1 /dev/vdb2
        # 查看pv详细信息
        pvs/pvdisplay
        # vgcreate命令创建一个VG组，并将创建的两个PV加入VG组
        vgcreate vg1 /dev/vdb1 /dev/vdb2 # 组名vg1
        # 查看卷组信息
        vgs/vgdisplay
        # 在vg1卷组下创建一个逻辑卷lv1，对应路径为/dev/vg1/lv1
        # 此时lv1可能会同时使用/dev/vdb1 /dev/vdb2这两个PV，这也是LVM一个PV损毁会导致整个卷组数据损毁
        # **可通过VG来分区(如取home、data两个卷组分别挂载到/home、/data；初始化时可初始化名为/dev/home/main的LV)，之后对该分区扩容只需往相应VG中加PV即可**
        lvcreate -L 199G -n lv1 vg1 # 如果200G的卷组，此时无法正好创建出一个200G的LV，需稍微少一点。最终显示成 /dev/vg1/lv1
        # 查看逻辑卷详细
        lvs/lvsdisplay
        # 格式化卷组
        mkfs.xfs /dev/vg1/lv1
        # 挂载
        mount /dev/vg1/lv1 /home/data # df -h显示/dev/mapper/vg1-lv1
        # 写入fstab
        echo /dev/vg1/lv1 /home/data xfs defaults 0 0 >> /etc/fstab
        ```
    - 调整home和root容量大小如下

        ```bash
        # 如果centos卷组有额外的空间，如加入了物理卷，则无需减少home分区容量
        cp -r /home/ homebak/ # 备份/home(建议打成tar)
        umount /home # 卸载​ /home
        # 删除某LVM分区(需要先备份数据，并取消挂载)
        lvremove /dev/mapper/centos-home

        ### =========扩展分区
        # 只要/dev/mapper/centos-root(LV)对应的卷组(VG)有额外的空间即可扩展
        lvextend -L +20G /dev/mapper/centos-root # 扩展/root所在的lv
        # resize2fs 针对的是ext2、ext3、ext4文件系统；xfs_growfs 针对的是xfs文件系统
        xfs_growfs /dev/mapper/centos-root # 激活修改的配置
        ### =========扩展分区

        # 恢复原来的home分区
        vgdisplay # 其中的Free PE表示LVM分区剩余的可用磁盘
        lvcreate -L 100G -n home centos # 重新创建home lv 分区的大小
        mkfs.xfs /dev/centos/home # 创建文件系统
        mount /dev/centos/home /home # 挂载 home
        # 使永久有效，写入 etc/fstab 见上文
        ```
    - 重命名vg、lv(无需umount和备份，数据也不会丢失)
        
        ```bash
        # 查看并记录基本信息。需要将/dev/hdd/hdd1改成/dev/vdisk/main
        vgs/lvs
        vgrename hdd vdisk
        lvrename /dev/vdisk/hdd1 main # 修改lv，注意此时vg为新的
        vi /etc/fstab # 修改之前的挂载信息
        ```

### 文件

- `cat <fileName>` 输出文件内容
    - `more` 分页显示文件内容(按空格分页)
        - 向后翻一屏：`SPACE`；向前翻一屏：`b`；向后翻一行：`ENTER`；向前翻一行：`k`
    - `less` 查看文件前几行(一行行的显示)
    - `tac` 从文末开始显示文件内容(cat反正写)
    - `head -3` 显示文件头部的3行
    - `tail -3` 显示文件末尾的3行
        - `tail -f /var/log/messages` -f 表示它将会以一定的时间实时追踪该档的所有更新（查看服务启动日志）
    - `cat -n <fileName>` **输出文件内容，并显示行号**
    - `cat > fileName` 创建文件并书写内容，此时会进入书写模式，Ctrl+C保存书写内容
- `pwd` 查看当前目录完整路径
- `sudo find / -name nginx.conf` 查询文件位置(查看`nginx.conf`文件所在位置)
    - `find ./ -mtime +30 -name "*.gz" | xargs ls -lh` 查询30天之前的gz压缩包文件
    - `find ./ -mtime +30 -name "*.gz" | [sudo] xargs rm -rf` 删除30天之前的gz压缩文件
- `whereis <binName>` 查询可执行文件位置
    - `which <exeName>` 查询可执行文件位置 (在PATH路径中寻找)
    - `echo $PATH` 打印环境变量
- `stat <file>` **查看文件的详细信息**
- `file <fileName>` 查看文件属性
- `wc <file>` 统计指定文本文件的行数、字数、字节数 
    - `wc -l <file>` 查看行数
- `ln my.txt my_link` 创建硬链接(在当前目录为my.txt创建一个my_link的文件并将这两个文件关联起来)
    - `ln -s /home/dir /home/my_link_soft` 对某一目录所有文件创建软链接(相当于快捷方式)，无需提前创建目录`/home/my_link_soft`
        - `rm -f /home/my_link_soft` **删除软链接**(源目录的文件不会被删除)
        - `rm -f /home/my_link_soft/` **删除软链接下的文件**(源目录的文件全部被删除；软链接仍然存在)
    - 修改原文件，硬链接对应的文件也会改变；删除原文件，硬链接对应的文件不会删除，软连接对应的文件会被删除
    - 目录无法创建硬链接，可以创建软链接
- lrzsz上传下载文件，小型文件可通过此工具完成。需要安装`yum install lrzsz`
    - `rz` 跳出窗口进行上传
    - `sz 文件名` 下载文件
- `ls` 列举文件 [^3]
    - `ll` 列举文件详细
        - **`ll test*`**/`ls *.txt` 模糊查询文件
        - **`ll -rt *.txt`** 按时间排序 (`-r`表示逆序、`-t`按时间排序)
        - **`ll -Sh`** 按文件大小排序 (`-S`按文件大小排序、`-h`将文件大小按1024进行转换显示M/G等)
    - `ls -al` 列举所有文件详细(`-a`全部、`-l`纵向显示. linux中`.`开头的文件默认为隐藏文件)
    > 文件详细如下图
    >
    > ![文件详细](/data/images/2017/02/文件详细.jpg)
    >
    > 类型与权限如下图
    >
    > ![类型与权限](/data/images/2017/02/类型与权限.png)
    > - 第一个字符代表这个文件的类型(如目录、文件或链接文件等等)：
    >   - [ d ]则是目录、[ - ]则是文件、[ l ]则表示为链接档(link file)、[ b ]则表示为装置文件里面的可供储存的接口设备(可随机存取装置)、[ c ]则表示为装置文件里面的串行端口设备,例如键盘、鼠标(一次性读取装置)
    > - 接下来的字符中,以三个为一组,且均为『rwx』 的三个参数的组合< [ r ]代表可读(read)、[ w ]代表可写(write)、[ x ]代表可执行(execute) 要注意的是,这三个权限的位置不会改变,如果没有权限,就会出现减号[ - ]而已>
    >   - 第一组为『文件拥有者的权限』、第二组为『同群组的权限』、第三组为『其他非本群组的权限』
    >   - 当 s 标志出现在文件拥有者的 x 权限上时即为特殊权限。特殊权限如 SUID, SGID, SBIT
- `touch <fileName>` 新建文件(linux下文件后缀名无实际意义)
- `vi <fileName>` 编辑文件
    - `vim <fileName>` 编辑文件，有的可能默认没有安装vim
- `> <file>` 清空文件内容
- `rm <file>` 删除文件
    - 提示 `rm: remove regular file 'test'?` 时，在后面输入 `yes或y` 回车
- `rm -rf` 强制删除某个文件或文件夹
    - r：recursion递归
    - f：force强制
- `cp xxx.txt /usr/local/xxx` 复制文件(将xxx.txt移动到/usr/local/xxx)
    - `cp -r /dir1 /dir2` 将dir1的数据复制到dir2中（`-r`递归复制，如果dir1下还有目录则需要）
    - 复制文件到远程服务器：`scp /home/test root@192.168.1.1:/home` 将本地linux系统的test文件复制到远程的home目录下
        - `scp -r /home/smalle/dir root@192.168.1.1:/home` 复制文件夹到远程机器
- `mv a.txt /home` 移动a.txt到/home目录
    - `mv a.txt b.txt` 将a.txt重命名为b.txt
    - `mv a.txt /home/b.txt` 移动并重名名

### 文件夹/目录

- `mkdir <dirName>` 新建文件夹(或者用绝对路径 `mkdir /usr/local/DirName`)
    - `mkdir -p <dirName>` 会创建此目录需要的父目录
- `rmdir <dirName>` 删除文件夹 (如果文件夹不为空则无法删除)
    - `rm -rf <dirName>` 强制删除文件夹和其子文件夹
        - `-r` 就是向下递归，不管有多少级目录，一并删除
        - `-f` 就是直接强行删除，不作任何提示的意思
- `cd <dirName>` 进入到某目录
    - `cd ..` 返回上一级目录
    - `cd /usr/local/xxx` 返回某一级目录
    - `cd ~`或`cd回车` 返回家目录

### 压缩包(推荐tar) [^1]

#### tar

- 解压：**`tar -xvzf archive.tar -C /tmp`** 解压tar包，将gzip压缩包释放到/tmp目录下(tar不存在乱码问题)
- 压缩：**`tar -cvzf aezocn.tar.gz file1 file2 *.jpg dir1`** 将此目录所有jpg文件和dir1目录打包成aezocn.tar后，并且将其用gzip压缩，生成一个gzip压缩过的包，命名为aezocn.tar.gz(体积会小很多：1/10). windows可使用7-zip
- 参数说明
    - 独立命令，压缩解压都要用到其中一个，可以和别的命令连用但只能用其中一个
        - **`-x`**：解压
        - **`-c`**: 建立压缩档案
        - `-t`：查看 tarfile 里面的文件
        - `-r`：向压缩归档文件末尾追加文件
        - `-u`：更新原压缩包中的文件
    - 必须
        - **`-f`**：使用档案名字，**切记这个参数一般放在后面，后面只能接档案名**
    - 解/压缩类型(可选)
        - `-z`：有gzip属性的(archive.tar.gz)，**文件必须是以.gz/.gzip结尾**
        - `-J`：有xz属性的(archive.tar.xz)
        - `-j`：有bz2属性的(archive.tar.bz2)
        - `-Z`：有compress属性的(archive.tar.Z)
    - 其他可选
        - **`-v`**：显示所有过程
        - `-O`：将文件解开到标准输出    
        - `-p` 使用原文件的原来属性（属性不会依据使用者而变）
        - `-P` 可以使用绝对路径来压缩
        - `-C` 解压到指定目录

#### gz

- 解压：`zcat test.sql.gz > test.sql`

#### unzip

- `unzip file.zip` 解压zip
- `zip aezocn.zip *.jpg` zip格式的压缩，需要先下载`zip for linux`
- unzip乱码
    - 使用python解决(只能解决部分问题)
        - `vi pyzip` 新建文件pyzip
        - 加入代码

        ```python
        #!/usr/bin/env python
        # -*- coding: utf-8 -*-
        # pyzip.py

        import os
        import sys
        import zipfile

        print "Processing File " + sys.argv[1]

        file=zipfile.ZipFile(sys.argv[1],"r");
        for name in file.namelist():
            utf8name=name.decode('gbk')
            print "Extracting " + utf8name
            pathname = os.path.dirname(utf8name)
            if not os.path.exists(pathname) and pathname!= "":
                os.makedirs(pathname)
            data = file.read(name)
            if not os.path.exists(utf8name):
                fo = open(utf8name, "w")
                fo.write(data)
                fo.close
        file.close()
        ```

        - `chmod +x pyzip` 将pyzip设置成可执行文件
        - `./uzip /home/xxxx.zip`

#### rar

- `unrar e archive.rar` 解压rar
- `rar a aezocn.rar *.jpg` rar格式的压缩，需要先下载rar for linux

### 文件误删恢复

- `debugfs` https://www.cnblogs.com/lidm/p/5833273.html (不支持xfs文件格式的恢复)

## vi/vim编辑器

- 设置：vi/vim对应启动脚本`vi ~/.vimrc`或`vi ~/.exrc`(`sudo vi xxx`，需要设置root家目录的此配置文件)

    ```bash
    set tabstop=4 # 设置tab键为4个空格
    set nu # 显示行号(复制时容易复制到行号)
    set nonu # 不显示行号
    ```
    - vim粘贴带注释的数据格式混乱，使用vi无此问题
- `vi/vim my.txt` 打开编辑界面(总共两种模式，默认是命令模式；无此文件最终保存后会自动新建此文件)
    - `insert` 进入编辑模式
    - `esc` 退出编辑模式(进入命令模式)
    - `shift+:` 命令模式下开启命令输入
- 打开文件
    - `vi +5 <file>` 打开文件，并定位于第5行 
    - `vi + <file>` 打开文件，定位至最后一行
    - `vi +/<pattern> <file>` 打开文件，定位至第一次被pattern匹配到的行的行，按字母`n`查找下一个

### vi命令
    
- 关闭文件
    - `:wq`/`:x` 保存并退出
    - `:q!` **不保存退出（可用于readonly文件的关闭）**，`:q` 普通退出
    - `:x!` **强制保存退出**
    - `:w !sudo tee %` **对一个没有权限的文件强制修改保存的命令**
    - 编辑模式下输入大写`ZZ`保存退出
- 光标移动
    - `j` 下
    - `k` 上
    - `h` 左
    - `l` 右
    - `w` 移至下一个单词的词
- 行内跳转
    - `:0` 绝对行首(`:10` 跳转至第10行)
    - `:$` 绝对行尾
    - `shift+g` 最后一行
- 翻屏
    - `Ctrl+f` 向下翻一屏
    - `Ctrl+b` 向上翻一屏
- 删除命令 `d`
    - `dd` **删除光标所在行**
    - `#dd` 删除光标以下#行
    - `dw` 删除一个单词
    - `.,.+2d` 删除从之前关标所在行到关标所在行的下两行(`.` 表示当前行；`$` 最后一行；`+#` 向下的#行；`-#` 向上的#行)
    - `x` 删除光标所在处的单个字符
    - `#x` 删除光标所在处及向后的共#个字符
- 新加一行 `o`
- 复制命令 `y`命令，用法同`d`命令。**和粘贴命令`p`组合使用**
- 粘贴命令 `p`/`P`
    - `p`：粘贴到下、后。如果删除或复制为整行内容，则粘贴至光标所在行的下方，如果复制或删除的内容为非整行，则粘贴至光标所在字符的后面；
    - `P`：粘贴到上、前。
- 查找
    - `/<pattern>` 查找pattern匹配表达式
    - `n` 基于以上表达式向下查询
    - `N` 向上查询
- 查找替换 `s`
    - `<row1>,<row2>s@<pattern>@<string>@gi` 从第row1行到第row2行根据pattern匹配到后全局(g)忽略大小写(i)并替换成string
    - `$`标识末行，`%`全文(`<row1>,<row2>`用`%`代替)
- 撤销
    - `u` **撤销上一步操作**
    - `Ctrl+r` **恢复上一步被撤销的操作**
    - `Ctrl+v` 进入列编辑模式
- 行号
    - `set number`/`set nu` 显示行号
    - `set nonu` 不显示行号
    - 永久显示行号：在`/etc/virc`或`/etc/vimrc`中加入一行`set nu`
- 批量注释
    - `Ctrl+v` 进入列编辑模式，在需要注释处移动光标选中需要注释的行
    - `Shift+i`
    - 再插入注释符，比如按`#`或者`//`
    - 按`Esc`即可全部注释
- 批量删除注释：`ctrl+v`进入列编辑模式，横向选中列的个数(如"//"注释符号需要选中两列)，然后按`d`就会删除注释符号
- **跟shell交互**：`:! COMMAND` 在命令模式下执行外部命令，如mkdir

## linux三剑客grep、sed、awk语法

### grep过滤器

- 语法

    ```bash
    # grep [-acinv] [--color=auto] '搜寻字符串' filename
    # 选项与参数：
    # -v **反向选择**，亦即显示出没有 '搜寻字符串' 内容的那一行
    # -i 忽略大小写的不同，所以大小写视为相同
    # -E 以egrep模式匹配
    # -n 顺便输出行号
    # -c 计算找到 '搜寻字符串' 的次数
    # --color=auto 可以将找到的关键词部分加上颜色的显示喔；--color=none去掉颜色显示
    # -a 将 binary 文件以 text 文件的方式搜寻数据
    ```
- [grep正则表达式](https://www.cnblogs.com/terryjin/p/5167789.html)
- 常见用法

    ```bash
    grep "search content" filename1 filename2.... filenamen # 在多个文件中查找数据(查询文件内容)
    grep 'search content' *.sql # 查找已`.sql`结尾的文件

    grep -5 'parttern' filename # 打印匹配行的前后5行。或 `grep -C 5 'parttern' filename`
    grep -A 5 'parttern' filename # 打印匹配行的后5行
    grep -B 5 'parttern' filename # 打印匹配行的前5行

    grep -E 'A|B' filename # 打印匹配 A 或 B 的数据
    grep 'A' filename | grep 'B' # 打印匹配 A 且 B 的数据
    grep -v 'A' filename # 打印不包含 A 的数据
    ```

### sed行编辑器

- 文本处理，默认不编辑原文件，仅对模式空间中的数据做处理；而后处理结束后将模式空间打印至屏幕
- 语法 `sed [options] '内部命令表达式' file ...`
- 参数
    - `-n` 静默模式，不再默认显示模式空间中的内容
	- `-i` **直接修改原文件**(默认只输出结果。可以先不加此参数进行修改预览)
	- `-e script -e script` 可以同时执行多个脚本
	- `-f`：如`sed -f /path/to/scripts file`
	- `-r` 表示使用扩展正则表达式
- 内部命令
    - 内部命令表达式如果含有变量可以使用双引号，单引号无法解析变量
	- **`s/pattern/string/修饰符`** 查找并替换
        - 默认只替换每行中第一次被模式匹配到的字符串；修饰符`g`全局替换；`i`忽略字符大小写；**其中/可为其他分割符如`#`、`@`等**
        - `sed "s/foo/bar/g" test.md` 替换每一行中的"foo"都换成"bar"
        - `sed 's#/data#/data/harbor#g' docker-compose.yml` 修改所有"/data"为"/data/harbor" 
	- `d` 删除符合条件的行
	- `p` 显示符合条件的行
	- `a \string`: 在指定的行后面追加新行，内容为string
		- `\n` 可以用于换行
	- `i \string`: 在指定的行前面添加新行，内容为string
	- `r <file>` 将指定的文件的内容添加至符合条件的行处
	- `w <file>` 将地址指定的范围内的行另存至指定的文件中
	- `&` 引用模式匹配整个串
- 示例
    - 删除/etc/grub.conf文件中行首的空白符：`sed -r 's@^[[:space:]]+@@g' /etc/grub.conf`
    - 替换/etc/inittab文件中"id:3:initdefault:"一行中的数字为5：`sed 's@\(id:\)[0-9]\(:initdefault:\)@\15\2@g' /etc/inittab`
    - 删除/etc/inittab文件中的空白行：`sed '/^$/d' /etc/inittab` (此时会返回修改后的数据，但是原始文件中的内容并不会被修改)
        - `sed -i -e '/^$/d' /home/smalle/test.txt` 加上参数`-i`会直接修改原文件(去掉文件中所有空行)
    - [其他示例](https://github.com/lutaoact/script/blob/master/sed%E5%8D%95%E8%A1%8C%E8%84%9A%E6%9C%AC.txt)

### awk文本分析工具

- 相对于grep的查找，sed的编辑，awk在其对数据分析并生成报告时，显得尤为强大。**简单来说awk就是把文件逐行的读入，以空格为默认分隔符将每行切片，切开的部分再进行各种分析处理(每一行都会执行一次awk主命令)**
- 语法 **`awk '[BEGIN {}] {pattern + action} [END {}]' {commands}`**
	- 其中 pattern 表示 AWK 在数据中查找的内容，而 action 是在找到匹配内容时所执行的一系列命令(awk主命令)
	- 花括号（{}）不需要在程序中始终出现，但它们用于根据特定的模式对一系列指令进行分组
	- pattern就是要表示的正则表达式，用斜杠括起来
- 案例
    - 显示最近登录的5个帐号：`last -n 5 | awk '{print $1}'`
        - 读入有'\n'换行符分割的一条记, 然后将记录按指定的域分隔符划分域(填充域)。**$0则表示所有域, $1表示第一个域**, $n表示第n个域。默认域分隔符是"空白键"或 "tab键", 所以$1表示登录用户, $3表示登录用户ip, 以此类推。
    - 只是显示/etc/passwd中的账户：`cat /etc/passwd | awk -F ':' '{print $1}'`(-F指定域分隔符为':')
    - 查找root开头的用户记录: `awk -F : '/^root/' /etc/passwd`
- `$0`变量是指整条记录，`$1`表示当前行的第一个域，`$2`表示当前行的第二个域，以此类推
- awk中同时提供了print和printf两种打印输出的函数：
    - `print` 参数可以是变量、数值或者字符串。**字符串必须用双引号引用，参数用逗号分隔。**如果没有逗号，参数就串联在一起而无法区分。
    - `printf` 其用法和c语言中printf基本相似，可以格式化字符串，输出复杂时。
- awk内置变量：awk有许多内置变量用来设置环境信息，这些变量可以被改变，下面给出了最常用的一些变量
    - `ARGC` 命令行参数个数
    - `ARGV` 命令行参数排列
    - `ENVIRON` 支持队列中系统环境变量的使用
    - `FILENAME` awk浏览的文件名
    - `FNR` 浏览文件的记录数
    - `FS` 设置输入域分隔符，等价于命令行 -F选项
    - `NF` 浏览记录的域的个数
    - `NR` 已读的记录数
    - `OFS` 输出域分隔符
    - `ORS` 输出记录分隔符
    - `RS` 控制记录分隔符
- 自定义变量
    - 下面统计/etc/passwd的账户人数

        ```bash
        awk '
        {count++;print $0;} 
        END {print "user count is ", count}
        ' /etc/passwd
        # 打印.
        # root:x:0:0:root:/root:/bin/bash
        # ......
        # user count is 40
        ```
        - count是自定义变量。之前的action{}里都是只有一个print，其实print只是一个语句，而action{}可以有多个语句，以;号隔开。这里没有初始化count，虽然默认是0，但是妥当的做法还是初始化为0。
- 提供`BEGIN/END`语句(必须大写)
    - BEGIN和END，这两者都可用于pattern中, 提供BEGIN和END的作用是给程序赋予初始状态和在程序结束之后执行一些扫尾的工作。任何在BEGIN之后列出的操作（紧接BEGIN后的{}内）将在awk开始扫描输入之前执行，而END之后列出的操作将在扫描完全部的输入之后执行。通常使用BEGIN来显示变量和预置（初始化）变量，使用END来输出最终结果。
    - 统计某个文件夹下的文件占用的字节数，过滤4096大小的文件(一般都是文件夹):

        ```bash
        ls -l | awk '
        BEGIN {size=0;print "[start]size is", size}
        {if($5!=4096){size=size+$5;}} 
        END {print "[end]size is", size/1024/1024, "M"}
        '
        # 打印
        # [start]size is 0
        # [end]size is 30038.8 M
        ```
- 支持if判断、循环等语句

## 权限系统

### 用户管理 [^6]

- `useradd test` 新建test用户(默认在/home目录新建test对应的家目录test)
    - `useradd -d /home/aezo -m aezo` 添加用户(和设置宿主目录)
    - `usermod -d /home/home_dir -U aezo` 修改用户宿主目录
    - `useradd -r -g mysql mysql` 添加用户mysql，并加入到mysql用户组
        - `-r` 表示mysql用户是一个系统用户，不能登录
- `passwd aezo` 设置密码
    - centos7忘记root用户密码找回可在启动时设置进入`sysroot/bin/sh`进行修改，参考：https://blog.51cto.com/scorpions/2059912
- 添加用户sudo权限
    - 使用sudo执行的命令都是基于root启动，创建的文件也是所属root

    ```bash
    # 添加写权限
    chmod u+w /etc/sudoers
    vi /etc/sudoers

    # 文件内容修改
    root	ALL=(ALL) 	ALL
    # 新加的sudo用户
    # smalle  ALL=(ALL)   ALL
    # 设置执行sudo不需要输入密码(否则sudo输入密码，有效期只有5分钟)。
    smalle  ALL=(ALL)   NOPASSWD: ALL
    # 只要是wheel组不需要密码. 有可能把smalle加入到了wheel组开启su权限时，导致wheel组的权限会覆盖上面用户权限(注释wheel组需要密码的配置)
    %wheel  ALL=(ALL)       NOPASSWD: ALL

    # 恢复文件只读
    chmod u-w /etc/sudoers
    ```
- `su test` 切换到test用户，但是当前目录和shell环境不会改变
    - **`su - test`** 变更帐号为test，并改变工作目录至test的家目录，且shell环境也变成test用户的
    - `su - smalle -c 'ls'` 切换到smalle用户环境，且执行ls命令(就算当前登录的是smalle，此时也需要输入密码)
    - 设置su命令不需要密码

        ```bash
        # 将smalle加入到组wheel(一个用户可以属于多个组)
        usermod -G wheel smalle

        # 修改配置
        vi /etc/pam.d/su
        # 取消下面两行的注释
        auth       required   pam_wheel.so group=wheel 
        auth       sufficient pam_wheel.so trust use_uid

        # 测试
        su - smalle -c 'ls'
        ```
- `userdel -rf aezo` 删除用户(会删除对应的家目录)
- 用户组
    - `cat /etc/group` 查看组
    - `groupadd aezocn` 新建组
    - `groupdel aezocn` 删除组
    - `groups` 查看当前登录用户所属组
        - `groups test` 查看test用户所属组
    - `usermod -g test smalle` 修改用户smalle的默认组为test
    - `usermod -G wheel smalle` 将smalle加入到组wheel(一个用户可以属于多个组)
- 查看用户
    - `cat /etc/passwd` 查看用户
        - 如`smalle(账号名称):x(密码):1000(账号UID):1000(账号GID):aezocn(用户说明):/home/smalle(家目录):/bin/bash(shell环境)`
    - `id smalle` 查看smalle用户信息。
        - 如`uid=1000(smalle) gid=1000(smalle) groups=1000(smalle),10(wheel)` gid表示用户默认组，groups表示用户属于smalle、wheel两个组
    - `who` 显示当前登录用户
    - `whoami` 查看当前登录用户名

### 文件权限

- 文件属性`chgrp`、`chown`、`chmod`、`umask` [^3]
- `chgrp` 改变文件所属群组。`chgrp [-R] 组名 文件或目录`
    - `-R` 递归设置子目录下所有文件和目录
- `chown` 改变文件/目录拥有者
    - `chown [-R] aezo /home/aezo`
    - `chown -R mysql:mysql /home/data/mysql` 改变此目录及其子目录的所属组为mysql和所属用户为mysql
    - 用户可以操作(查看/修改)自己的文件/文件夹，无需上层目录有权限。如`/home/data/mysql`目录属于mysql，但是`/home/data`是属于root用户，此时mysql用户也可以操作`/home/data/mysql`目录
- `chmod` 改变文件的权限(文件权限说明参考上述`ls -al`)
    - 数字类型改变文件权限 **`chmod [-R] xyzw 文件或目录`** 如：`chmod -R 755 /home/ftproot`
        - `x`：可有可无，代表的是特殊权限,即 SUID/SGID/SBIT。`yzw`：就是刚刚提到的数字类型的权限属性，为 rwx 属性数值的相加
        - 各权限的分数对照表为：`r:4、w:2、x:1、SUID:4、SGID:2、SBIT:1`。如rwx = 4+2+1 = 7，r-s = 4+1 = 5
    - 符号类型改变文件权限 `chmod 对象 操作符 文件/目录`
        - 对象取值为`ugoa`：u=user, g=group, o=others, a=all
        - 操作符取值为：`+-=`：+ 为增加，- 为除去，= 为设定
        - 如：`chmod u=rwx,go=rx test`、`chmod g+s,o+t test`
- `umask` 创建文件时的默认权限
    - `umask` 查看umask分数值。如0022(一般umask分数值指后面三个数字022; umask值相当于基于666做减法，022=>644，002=>664)
        - `umask -S` 查看umask。如u=rwx,g=rx,o=rx
        - 系统默认新建文件的权限为666(3个rw)，文件夹为777(3个rwx)。最终新建文件的默认权限为系统默认权限减去umask分数值。如umask为002，新建的文件为-rw-r--r--，文件夹为drw-r-xr-x
        - centos7中root用户默认为022，其他新创建的用户默认为002
    - 命令行运行`umask 022`只能临时改变
    - 永久修改umask值
        - 方式一：修改`sudo vi /etc/profile`，加入一行`umask 022`
        - 方式二：修改每个用户`sudo vi ~/.bashrc`文件，加入一行`umask 022`
- 常用命令
    - `find . -type d -exec chmod 755 {} \;` 修改当前目录的所有目录为775
    - `find . -type f -exec chmod 644 {} \;` 修改当前目录的所有文件为644

## ssh

### ssh介绍 [^2]

- SSH是建立在传输层和应用层上面的一种安全的传输协议。SSH目前较为可靠，专为远程登录和其他网络提供的安全协议。在主机远程登录的过程中有两种认证方式：
    - `基于口令认证`：只要你知道自己帐号和口令，就可以登录到远程主机。所有传输的数据都会被加密，但是不能保证你正在连接的服务器就是你想连接的服务器。可能会有别的服务器在冒充真正的服务器，也就是受到“中间人”这种方式的攻击。
    - `基于秘钥认证`：需要依靠秘钥，也就是你必须为自己创建一对秘钥，并把公用的秘钥放到你要访问的服务器上，客户端软件就会向服务器发出请求，请求用你的秘钥进行安全验证。服务器收到请求之后，现在该服务器你的主目录下寻找你的公用秘钥，然后吧它和你发送过来的公用秘钥进行比较。弱两个秘钥一致服务器就用公用秘钥加密“质询”并把它发送给客户端软件，客户端软件收到质询之后，就可以用你的私人秘钥进行解密再把它发送给服务器。
- 用基于秘钥认证，你必须要知道自己的秘钥口令。但是与第一种级别相比，这种不需要再网络上传输口令。第二种级别不仅加密所有传送的数据，而且“中间人”这种攻击方式也是不可能的（因为他没有你的私人密匙）。但是整个登录的过程可能需要10秒。

### 查看SSH服务

- CentOS 7.1安装完之后默认已经启动了ssh服务我们可以通过以下命令来查看ssh服务是否启动
- 查看开放的端口 `netstat -lnt` ssh默认端口为22
- 查看服务是否启动 `systemctl status sshd.service` 查看ssh服务是否启动

### SSH客户端连接服务器（口令认证）

- 直接连接到对方的主机，这样登录服务器的默认用户
    - `ssh 192.168.1.1` 回车输入密码即可
    - `exit` 退出登录
- 使用账号登录对方主机aezocn用户
    - `ssh aezocn@192.168.1.1`

### SSH客户端连接服务器（秘钥认证）

- **客户端(可能也是一台服务器)需要连接服务器，则需要将客户端上的公钥如`id_rsa.pub`内容追加到服务器的`~/.ssh/authorized_keys`文件中，且客户端需要在.ssh文件夹保留上述公钥对应的秘钥如`~/.ssh/id_rsa`**
    - 公钥需要写入到服务端的`authorized_keys`文件(文件名有s)，客户端/服务端`known_hosts`会保存已认证的客户端信息。(生成的公钥/私钥无需保存在服务端，自行备份即可)
    - "公钥/私钥对"可以是客户端、服务器端或其他地方生成的秘钥对数据
    - 客户端登录成功后会将服务器ip等信息加入到客户端/服务端`known_hosts`文件中(没有此文件时会自动新建)
- 秘钥对生成和使用
    - 生成公钥(.pub)和私钥(.ppk)。运行 **`ssh-keygen`** 命令后再按三次回车会看到`RSA`。生成的秘钥文件默认路径为家目录下的`.ssh`，如`/home/smalle/.ssh/`
        - 会包括`id_rsa`(密钥)、`id_rsa.pub`(公钥)、`known_hosts`(此机器作为客户端进行ssh连接时，认证过的服务器信息) 3 个文件。如：此客户端ip为`192.168.1.2`
        - `ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa` 以dsa模式生成
        - `ssh-keygen -t rsa -C "xxx@qq.com"` -C起到一个密码备注的作用，可以为任何内容
    - 把生成的公钥保存到服务器`authorized_keys`文件中
        - **`ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.1.1`** 输入192.168.1.1密码实现发送，自动保存在服务器的`/root/.ssh/authorized_keys`文件中去(或者手动追加到authorized_keys文件中)。此时需要保证192.168.1.1服务器的root用户没有被禁用
    - 在`192.168.1.2`客户端上登录上述服务器
        - `ssh 192.168.1.1` 此时不需要输入密码
        - 如果需要在`192.168.1.1`(客户机)上通过ssh登录`192.168.1.1`(服务器)，需要按照上述命令把公钥保存到服务器的`authorized_keys`
    - 其他说明
        - 如果是为了让root用户登录则将公钥放入到/root/.ssh目录；如果密钥提供给其他用户登录，可将公钥放在对应的家目录，如/home/aezo/.ssh/下。`.ssh`目录不存在可手动新建（可通过`ll -al`查看） [^5]
        - **阿里云服务器使用**
            - 阿里云服务器需要将密钥对保存到阿里云管理后台，并关联到对应的服务器上
            - 关联阿里云服务器秘钥后，需要到阿里云管理后进行服务器重启(不能再终端重启)。重启后会自动禁用密码登录
            - 可以使用阿里云进行秘钥生成(只能下载到秘钥，公钥可通过xshell连接后进行查看或连接后到服务器的authorized_keys文件中查看)，也可自行导入公钥
        - **AWS服务器(EC2)使用**
            - 使用PuTTY连接时：PuTTY 本身不支持 Amazon EC2 生成的私有密钥格式 (.pem)，PuTTY 有一个名为 PuTTYgen 的工具，可将密钥转换成所需的 PuTTY 格式 (.ppk)
        - 如何客户端登录失败，可在服务器查看访问日志`cat /var/log/secure`
- ssh配置 [^7]

    ```bash
    vi /etc/ssh/sshd_config

    ## 修改文件内容
    # 是否允许root用户登陆(no不允许)
    PermitRootLogin no
    # 是否允许使用用户名密码登录(no不允许，此时只能使用证书登录。在没有生成好Key，并且成功使用之前，不要设置为no)
    PasswordAuthentication no

    # 使配置生效
    systemctl restart sshd
    ```
- Putty/WinSCP 和 xshell/xftp
    - Putty是一个Telnet、SSH、rlogin、纯TCP以及串行接口连接软件。它包含Puttygen等工具，Puttygen可用于生成公钥和密钥（还可以将如AWS亚马逊云的密钥文件.pem转换为.ppk的通用密钥文件）
        - 在知道密钥文件时，可以通过Putty连接到服务器(命令行)，通过WinSCP连接到服务器的文件系统(FTP形式显示)
        - Puttygen使用：`类型选择RSA，大小2048` - `点击生成` - `鼠标在空白处滑动` - `保存公钥和密钥`
        - Putty使用：`Session的Host Name输入username@ip，端口22` - `Connection-SSH-Auth选择密钥文件` - `回到Session，在save session输入一个会话名称` - `点击保存会话` - `点击open登录服务器` - `下次可直接点击会话名称登录`
    - xshell/xftp是一个连接ssh的客户端
        - 使用xshell生成的秘钥进行连接：连接 - 用户身份验证 - 方法选择"public key"公钥 - 用户名填入需要登录的用户 - 用户密钥可点击浏览生成(需要将生成的公钥保存到对应用户的.ssh目录`cat /home/aezo/.ssh/id_rsa.pub >> /home/aezo/.ssh/authorized_keys`)。(必须使用自己生成的公钥和密钥，如果AWS亚马逊云转换后的ppk文件无法直接登录)
        - 使用服务器生成的秘钥文件连接：连接 - 用户身份验证 - 方法选择"public key"公钥 - 用户名填入需要登录的用户 - 用户密钥可点击浏览导入(**导入服务器生成的秘钥文件id_rsa，不是公钥文件**)
        - xshell提示"用户秘钥导入失败"：centos上生成的秘钥类型在xshell中不支持，**可以使用xshell进行秘钥生成** [^9]
            - 工具 - 用户秘钥管理 - 生成 - 保存公钥 - 选择生成的秘钥 - 导出秘钥
            - 将公钥追加到到服务器的`authorized_keys`文件：`cat my_key.pub >> authorized_keys`
	- Unix终端：`ssh -i my_private_file root@10.10.10.10`
        - `-i` 登录时指定私钥文件。ssh登录服务器默认使用的私有文件为`~/.ssh/id_dsa`、`~/.ssh/id_ecdsa`、`~/.ssh/id_ed25519`、`~/.ssh/id_rsa`，其他则需要使用`-i`指定
    - `cat /var/log/secure`查看登录日志

## 定时任务 [^4]

### corn表达式

- `systemctl reload crond` 重新加载配置
- `systemctl restart crond` 重启crond
- 如执行"删除30天之前的mysql备份"脚本`find /home/smalle/backup -name test"*.sql.gz" -type f -mtime +30 -exec rm -rf {} \; > /dev/null 2>&1`

### 配置说明

- 配置式
    - 添加定时配置：`sudo vim /etc/crontab`，配置说明如下，如：`30 2 1 * * root /sbin/reboot`表示每月第一天的第2个小时的第30分钟，使用root执行命令/sbin/reboot(重启)

        ```shell
        # Example of job definition:
        # .---------------- minute (0 - 59)，如 10 表示没第10分钟运行。每分钟用 * 或者*/1表示，整点分钟数为00或0
        # |  .------------- hour (0 - 23)
        # |  |  .---------- day of month (1 - 31)
        # |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
        # |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
        # |  |  |  |  |
        # *  *  *  *  * user-name  command to be executed
        # (1) 其中用户名一般可以省略
        # (2) 精确到秒解决方案, 以下3行表示每20秒执行一次
        # * * * * * user-name my-command
        # * * * * * sleep 20; user-name my-command
        # * * * * * sleep 40; user-name my-command
        ```
- 命令式
    - `crontab -e` 编辑当前用户的定时任务，默认在`/var/spool/`目录
    - `crontab –l` 列举当前用户的定时任务
- 常用符号
    - `*` 表示所有值 
    - `?` 表示未说明的值，即不关心它为何值
    - `-` 表示一个指定的范围
    - `,` 表示附加一个可能值
    - `/` 符号前表示开始时间，符号后表示每次递增的值

## 网络



## 工具

- https://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/index.html
- pstack 跟踪进程栈
- strace 跟踪进程中的系统调用
- top linux下的任务管理器

## linux概念

### 基本

- Linux是基于Unix的，其内核是开源的。redhat、centos、ubuntu都是基于linux内核将一些小程序组装到一起的linux发行套件。
- linux的库为`.so`共享对象，windows的库为`.dll`动态链接库
- `#`为root命令提示符，`$`普通用户提示符
- 命令格式：`命令 选项 参数`

### 磁盘

- linux分区命名(/dev/xxyN)
    - linux将所有的硬件也看作是文件，全部在`/dev`目录
        - `/dev/cdrom` 光驱
    - xx：分区名的前两个字母表明设备类型，hd(IDE磁盘)或sd(SCSI磁盘)
    - y：标明分区所在设备，`/dev/hda`(第一个IDE磁盘)或`/dev/sdb`(第二个SCSI磁盘)
    - N：最后的数字代表分区。前四个分区(主分区或扩展分区)是用数字从1-4表示，逻辑分区从5开始。`/dev/sdb6`(第二个SCSI磁盘上的第二个逻辑分区)
- 磁盘分区和挂载点
    - 挂载是将分区关联到某一目录(通常称为挂载点)的过程。
    - 一般在`/mnt`目录创建对应的挂载目录，如cdrom直接访问不了，通过挂载实现访问：
        - 在`/mnt`下新建目录`cdr`
        - 挂载分区`mount /dev/cdrom /mnt/cdr`
            - 访问`/mnt/cdr`即是访问`/dev/cdrom`的数据
        - 卸载分区`umount /dev/cdrom`
- 手动分区
    - `/` 根分区(硬盘上分一个区挂载到'/'上)
    - `/usr` 应用软件存放位置
    - `/home` 用户宿主目录
    - `/var` 存放临时文件
    - `/boot` 存放启动文件(128M足够了)
    - `SWAP` 交换分区(一般是内存的两倍)
- 目录结构
    - `/bin` 基础系统所需命令位于此目录，如`ls`、`mkdir`，普通用户都可以使用的命令。和`/usr/bin`类似
    - `/dev` 设备文件存储目录，如声卡(eth0)、磁盘、光驱(cdrom)
    - **`/etc`** 系统配置文件所在地，一些服务器的配置文件也在此处
        - `rc.local` 文件，是`/etc/rc.d/rc.local`的symbolic link（系统启动会执行此文件）
        - `/init.d` 服务启动文件目录(脚本文件书写参考此目录下network文件)。是`/etc/rc.d/init.d`的symbolic link。(ubuntu启动目录是/etc/init.d)
        - `hosts`
    - `/home` 用户家目录
    - `/lib` 库文件存放目录
    - `/lost+found` 在ext2或ext3文件系统中，当系统意外崩溃或意外关机，而产生的一些文件碎片存放在此处。当再次启动时会进行检查修复。
    - `/media` 即插即用型存储设备挂载点自动在这个目录下创建，如USB盘系统
    - `/mnt` 用于存放挂载存储设备的挂载目录
    - **`/proc`** 操作系统运行时，进场信息及内核信息(cpu，内存)存放在这里
        - proc目录为内核映射文件，修改此目录的文件就会修改内存数据
    - `/root` 超级权限用户root的家目录
    - `/sbin` 大多设计系统管理的命令存放，是超级权限用户root的可执行命令存放地，普通用户无法执行。和`/usr/sbin`、`/usr/local/sbin`目录类似
    - `/tmp` 临时文件目录。和`/var/tmp`目录类似
    - `/var`
        - **`cat /var/log/messages`** 服务运行的日志文件
    - `/usr` 用户目录。系统级的目录，可以理解为C:/Windows/，/usr/lib理解为C:/Windows/System32
        - `/local` **一般为安装软件目录**，源码编译安装一般在`/usr/local/lib`目录下。用户级的程序目录，可以理解为C:/Progrem Files/，用户自己编译的软件默认会安装到这个目录下
        - `src` 系统级的源码目录
        - `/local/src`：用户级的源码目录
    - `/opt` **标识可选择的意思，一些软件包也会安装在这里，也就是自定义软件包**。用户级的程序目录，可以理解为D:/Software，opt有可选的意思，这里可以用于放置第三方大型软件（或游戏），当不需要时，直接rm -rf掉即可。在硬盘容量不够时，也可将/opt单独挂载到其他磁盘上使用

### 系统启动顺序boot sequence

1. load bios(hardware information) 加电后检查hardware information
2. read MBR's cofing to find out the OS
3. load the kernel of the OS
4. init process starts...
5. execute /etc/rc.d/sysinit (rc.d为runlevel control directory)
6. start other modulers(etc/modules.conf) (启动内核外挂模块)
7. execute the run level scripts(如rc0.d、rc1.d等。启动只能配置成某一个级别，查看`systemctl get-default`，配置目录`cat /etc/inittab`)
    - 0 停机（千万不要把initdefault 设置为0）
    - 1 单用户模式
    - 2 多用户，但是没有 NFS
    - **3** 完全多用户模式(服务器常用，一般centos7即默认此级别)
    - 4 系统保留的
    - **5** X11(x window 桌面版)
    - 6 重新启动（千万不要把initdefault 设置为6）
8. execute `/etc/rc.d/rc.local` 自动启动某些程序，可基于此文件配置(或者`/etc/rc.local`，直接在里面添加启动命令)
9. execute /bin/login
10. shell started...

## xshell使用

- 工具->选项->键盘和鼠标-将选定的文本自动复制到剪贴板
- 数字小键盘输入，如果不设置的话，会显示乱码：连接配置 - 终端 - VT模式 - 设置为普通
- 复制屏幕内容到记事本：鼠标右键 - 选择"To Notepad"(记事本)
- 快速切换打开的Tab：快捷键：Alt+1~9 或者Shift+Tab


---

参考文章

[^1]: http://www.jb51.net/LINUXjishu/43356.html (文件压缩与解压)
[^2]: http://www.linuxidc.com/Linux/2016-03/129204.htm (ssh登录)
[^3]: http://www.cnblogs.com/kzloser/articles/2673790.html (Linux文件属性)
[^4]: http://www.360doc.com/content/16/1013/10/15398874_598063092.shtml (定时任务)
[^5]: https://www.douban.com/doulist/44111547/ (阿里云服务器ssh设置)
[^6]: http://www.cnblogs.com/zutbaz/p/4248845.html (用户配置)
[^7]: https://www.xiaohui.com/dev/server/linux-centos-ssh-security.htm (服务器安全ssh配置)
[^8]: https://my.oschina.net/sallency/blog/827737 (nohup 命令实现守护进程)
[^9]: https://www.cnblogs.com/tintin1926/archive/2012/07/23/2605039.html (秘钥类型)
[^10]: https://help.aliyun.com/document_detail/108501.html (云服务器 ECS > 块存储 > 云盘 > 分区格式化数据盘 > Linux 格式化数据盘)
[^11]: https://zhuanlan.zhihu.com/p/24464526

