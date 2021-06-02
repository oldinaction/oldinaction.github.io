---
layout: "post"
title: "linux系统"
date: "2016-07-21 19:19"
categories: linux
tags: [linux, shell]
---

## 基础知识

- `Linux` 和 `BSD` 都是类 `UNIX` 操作系统
    - 二者均开源
        - Linux 使用 GNU 通用公共许可证，即 GPL。修改Linux核心源码后必须开源
        - BSD(Berkeley Software Distribution，伯克利软件套件) 使用 BSD 许可证。修改源码后不需开源
    - BSD分支
        - `FreeBSD`：是最受欢迎的 BSD。支持英特尔和 AMD 的32位和64位处理器
        - `NetBSD`：被设计运行在几乎任何架构上，支持更多的体系结构
        - `OpenBSD`：为最大化的安全性设计的
        - `DragonFly BSD`：设计目标是提供一个运行在多线程环境中的操作系统。如计算机集群
        - `Darwin / Mac OS X`：Mac OS X 实际上基于 Darwin 操作系统，而 Darwin 系统基于 BSD
- Linux发行版：一类是商业公司维护的发行版本，另一类是社区组织维护的发行版本。前者以著名的Redhat(RHEL)为代表，后者以Debian为代表
    - `Redhat系列` Redhat是`yum`包管理方式
        - `RHEL` (Redhat Enterprise Linux)
        - `Fedora Core` (由原来的Redhat桌面版本发展而来，免费版本)
        - [CentOS](https://www.centos.org/) (RHEL的社区克隆版本，免费)
    - `Debian系列` 使用`apt-get / dpkg`包管理方式
        - [Debian](https://www.debian.org/)、[Man Docs](https://manpages.debian.org/)
        - [Ubuntu](https://cn.ubuntu.com/)
    - `SUSE Linux`
        - [openSUSE](https://www.opensuse.org/) 开源
    - [Arch Linux](https://www.archlinux.org/) 开源

### 基础操作

- 强制关闭重启
    - `shutdown -r now` root登录可立刻重启
    - `reboot` 重启
    - 关闭某个PID进程 `kill PID`
        - `netstat -lnp` 查看所有进场信息(端口、PID)
        - 强制杀进程 `kill -s 9 PID`
        - `yum install psmisc` centos7精简版无`killall`命令，需要安装此包
            - `killall -s 9 java` 杀死所有java进程
- 程序安装：参考[《http://blog.aezo.cn/2017/01/10/linux/CentOS%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E/》](/_posts/linux/CentOS服务器使用说明.md#常用软件安装)
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
        - `startofbiz.sh > my.log` 表示startofbiz.sh的输出重定向到my.log(如果存在交互场景则会一致卡死，且无法交互，需使用tee)
        - `2>&1` 表示将错误输出重定向到标准输出
            - `0`：标准输入；`1`：标准输出；`2`：错误输出
        - `./myscript.sh 2>&1 | tee mylog.log` **tee实时重定向日志(同时也会在控制台打印，并且可进行交互)**
    - `Ctrl+c` 关闭程序，回到终端
    - `Ctrl+z` 后台运行程序，回到终端
    - 也可使用`screen/tmux`等命令实现脱机运行
        - 会话的一个重要特点是，窗口与其中启动的进程是连在一起的。打开窗口，会话开始；关闭窗口，会话结束，会话内部的进程也会随之终止，不管有没有运行完，一个典型的例子就是，SSH 登录远程计算机。screen/tmux可使会话与窗口"解绑"

        ```bash
        yum -y install screen
        screen # 进入screen终端
        ./test # 执行程序。此时关闭SSH，此程序不会终止
        screen -ls # 查看所有screen终端: 4680.pts-2.dev2-1 (Attached|Detached)。Attached表示有人看守状态，Detached表示无人看守
        screen -r 4680 # 重新连接 screen_id 为 4680 的 screen终端(此时4680必须为Detached)
        Ctrl+A+D # 保持会话并退出
        exit # 完全退出
        ```
- 设置环境变量
    - `/etc/profile` 记录系统环境变量，在此文件末尾加入`export JAVA_HOME=/usr/java/jdk1.8` 将`JAVA_HOME`设置成所有用户可访问
    - `/home/smalle/.bash_profile` 每个用户登录的环境变量(/home/smalle为用户家目录)
        - `.bash_profile` 登录后的环境变量
        - `.bashrc` 登录后自动运行(类似rc.local)
    - `echo $JAVA_HOME` 查看其值
    - 设置临时环境变量：在命令行运行`export JAVA_HOME=/usr/java/jdk1.8`(重新打开命令行则失效)
    
### 服务相关命令

- `journalctl` 查看所有日志，默认显示本次启动的所有(服务)日志
    - `-f` 持续监控日志输出
    - `-u` 基于服务筛选(`journalctl -f -u kubelet` 持续监控kubelet日志)
    - `-n` 显示最近n行日志 `journalctl -n20`
    - `-k` 查看内容日志
    - `--since`/`--until` 查询某段时间的日志
- **自定义服务参考[http://blog.aezo.cn/2017/01/16/arch/nginx/](/_posts/arch/nginx.md#基于编译安装tengine)**
- `systemctl`：主要负责控制systemd系统和服务管理器，是`chkconfig`和`service`的合并(systemctl管理的脚本文件目录为`/usr/lib/systemd/system` 或 `/etc/systemd/system`)
    - `systemctl start|status|restart|stop nginx.service` 启动|状态|重启|停止服务，此处`.service`可省略，status状态说明
        - `Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)`中`docker.service`为daemon配置文件，第一个`disabled` 表示服务不是开机启动
        - `Active: active (running)` 表示正在运行；`Active: inactive (dead)` 表示尚未运行；`Active: active (exited)` 表示服务有效中，但是程序已执行完成(NFS服务正常情况下就是此状态)
    - `systemctl list-units --type=service` 查看所有服务
        - `systemctl list-unit-files` 查看所有可用单元
    - `systemctl enable nginx` 设置开机启动
    - `systemctl disable nginx` 停止开机启动
    - `systemctl cat sshd` 查看服务的配置文件
    - **`tail -f /var/log/messages`** 查看服务启动日志
- `chkconfig`：提供了一个维护`/etc/rc[0~6]d/init.d`文件夹的命令行工具
    - `chkconfig --list [nginx]` 查看(nginx)服务列表
    - `chkconfig --add nginx` 将nginx加入到服务列表(需要 **`/etc/rc.d/init.d/`** 软路径`/etc/init.d` 下有相关文件`nginx.service`或`nginx`脚本)
        - 用户文件保存在`/etc/rc.d/init.d/`(用户工作空间)；当执行`--add`命令后，该目录下的相应脚本会按照运行级别复制到对应级别目录，如`/etc/rc.d/rc3.d`
    - `chkconfig --del nginx` 关闭指定的服务程序
    - `chkconfig nginx on` 设置nginx服务开机自启动（对于 on 和 off 开关，系统默认只对运行级345有效，但是 reset 可以对所有运行级有效）
    - 设置开机自启动
        - 在`/etc/init.d`目录创建脚本文件，并设置成可执行`chmod +x my_script`
            ```bash
            # 自启动脚本的注释中必须有chkconfig、description两行注释(chkconfig会查看所有注释行)
            # chkconfig参数一表示在运行级别2345时默认代开(一般服务器的运行级别为3多用户启动)，使用`-`表示默认关闭(不自动启动)；参数2表示启动顺序(越小越优先)；参数3表示停止顺序(停止并不会重新执行脚本，而是停止此进程)
            
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
        - **将启动脚本添加到chkconfig列表**：`chkconfig --add my_script`
        - 之后可在`/var/log/messages`中查看启动日志信息；也可通过`systemctl status my_script`查看服务状态，如`active (exited)`表示服务有效中，但是程序已执行完成
- `service`：`service nginx start|stop|reload` 服务启动等命令

### 开机启动设置

- 参考[centos.md#启动原理及设置](/_posts/linux/centos.md#启动原理及设置)

### bash使用

- `Tab` 自动补全
- `ctrl-w` 删除键入的最后一个单词
- `ctrl-u`/`ctrl-k` 删除行内光标所在位置之前/之后的所有内容
- `ctrl-a`/`ctrl-e` 可以将光标移至行首/行尾
- `alt-b`/`alt-f` 以单词为单位移动光标
- `ctrl-r` 搜索命令行历史记录(重复按下 ctrl-r 会向后查找匹配项)
- `ctrl-l` 可以清屏

### shell脚本

参考 [《Shell编程》http://blog.aezo.cn/2017/01/10/linux/shell/](/_posts/linux/shell.md)

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
    - 统计指定文本文件的行数(`-l`)、字数(-w)、字节数(-c)
    - `sudo docker ps | wc -l`

## 文件系统

### 磁盘

- `df -h` 查看磁盘使用情况、分区、挂载点(**只会显示成功挂载的分区，新磁盘需要进行分区和挂载**)
    - `df -h /home/smalle` 查询目录使用情况、分区、挂载点（一般/dev/vda1为系统挂载点，重装系统数据无法保留；/dev/vab或/dev/mapper/centos-root等用来存储数据）
    - `df -Th` 查询文件系统格式
- `du -ahm --max-depth=1 | sort -nr | head -10` **查看当前目录以及一级子目录磁盘使用情况。二级子目录可改成2，并按从大倒小排列**(查看大目录)
    - `du` 它的数据是基于文件获取，可以跨多个分区操作。`df`它的数据基于分区元数据，只能针对整个分区
    - 参数说明
        - `-a` 所有文件，包括目录和普通文件，默认只统计目录
        - `-h` 显示人类可读的文件大小
        - `-m` 已MB大小为单位
    - `du -hsx * | sort -rh | head -10` 查看最大的10个文件
    - `du -sh /home/smalle | sort -h` 查看某个目录
    - `find . -type f -size +500M  -print0 | xargs -0 du -hm | sort -nr` 查看大于500M的前10个文件(查看大文件)
- `lsblk` **树形显示磁盘即分区**
    - `fdisk -l` 查看磁盘设备
    - `ll /dev | grep disk`查看磁盘设备
- `findmnt` 查看所有挂载的目录
- `dmesg -T | grep CD` 显示光盘信息，`-T`时间格式化。**其中dmesg为显示硬件信息，可用于硬件故障诊断**
- `alias ll='ls -latr'` 定义一个命令别名(仅当前会话生效)，也可将别名保存在`~/.bashrc`(所有会话)


### 文件

- `touch <fileName>` 新建文件(linux下文件后缀名无实际意义)
- `vi <fileName>` 编辑文件
    - `vim <fileName>` 编辑文件，有的可能默认没有安装vim
- `> <file>` 清空文件内容
- `rm <file>` 删除文件
    - `rm -rf` 强制删除某个文件或文件夹(recursion递归、force强制)
    - 提示 `rm: remove regular file 'test'?` 时，在后面输入 `yes或y` 回车
    - `rm -f *2019-04*` 正则删除，可删除如access-2019-04-01.log、error-2019-04-02.log
- `cp xxx.txt /usr/local/xxx` 复制文件(将xxx.txt移动到/usr/local/xxx)
    - `cp -r /dir1 /dir2` 将dir1的数据复制到dir2中（`-r`递归复制，如果dir1下还有目录则需要）
    - `/bin/cp -f /dir1/test /dir2` **强制覆盖文件**
        - 此处使用`cp -f`可能失效，由于cp命令被系统默认设置了别名`alias cp=cp -i`(-i, --interactive表示需要交互进行确认，同样的如mv)
        - `alias` 查看被重写的命令，`unalias cp`取消cp的别名(不建议取消)
- `scp` 跨机器文件传输
    - scp免密登录需要将客户端的公钥放到服务器
    - 复制文件到远程服务器
        - `scp -r /home/test root@192.168.1.1:/home/dir` 将本地linux系统的/home/test文件或目录(及其子目录)复制到远程的home目录下(本地和远程目录要么都以/结尾，要么都不要/)。**需要提前创建目标目录的父目录**
    - 从远程服务器传输文件到本地
        - `scp -r root@192.168.1.1:/opt/soft/test /opt/soft/` 下载远程 /opt/soft/test 文件或目录(及其子目录)到本地的 /opt/soft/ 目录来
        - `scp -r root@192.168.1.1:/home/test/2018* .` 将远程目录的2018开头的文件夹及其子文件复制到本地当前目录(备份)
        - "scp jdk-8u202-linux-x64.rpm root@node02:`pwd`"(pwd用锐音符包裹) 将文件复制到另一台机器的相同目录
- `mv a.txt /home` 移动a.txt到/home目录
    - `mv a.txt b.txt` 将a.txt重命名为b.txt
    - `mv a.txt /home/b.txt` 移动并重名名
- `ln my.txt my_link` 创建硬链接(在当前目录为my.txt创建一个my_link的文件并将这两个文件关联起来)
    - `ln -s /home/dir /home/my_link_soft` 对某一目录所有文件创建软链接(相当于快捷方式)，无需提前创建目录`/home/my_link_soft`(如果/home/dir存则则软连接显示绿色，如果不存在，软连接显示红色)
        - `rm -f /home/my_link_soft` **删除软链接**(源目录的文件不会被删除)
        - `rm -f /home/my_link_soft/` **删除软链接下的文件**(源目录的文件全部被删除；软链接仍然存在)
    - 修改原文件，硬链接对应的文件也会改变；删除原文件，硬链接对应的文件不会删除，软连接对应的文件会被删除
    - 目录无法创建硬链接，可以创建软链接
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
- `whereis <binName>` 查询可执行文件位置
    - `which <exeName>` 查询可执行文件位置 (在PATH路径中寻找)
    - `echo $PATH` 打印环境变量
- `stat <file>` **查看文件的详细信息**
- `file <fileName>` 查看文件属性
- `basename <file>` 返回一个字符串参数的基本文件名称。如：`basename /home/smalle/test.txt`返回test.txt
- `wc <file>` 统计指定文本文件的行数、字数、字节数 
    - `wc -l <file>` 查看行数
- `lsof | grep deleted`列举删除的文件(可能会造成du/df统计的值不一致)
    - `lsof -op $$` 查看当前进程的文件描述符
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
- `sudo find / -name nginx.conf` 全局查询文件位置(查看`nginx.conf`文件所在位置)
    - `find ./ -mtime +30 -name "*.gz" | xargs ls -lh` 查询当前目录或子目录(./可省略)中30天之前的gz压缩包文件
    - `find ./ -mtime +30 -name "*.gz" | [sudo] xargs rm -rf` 删除30天之前的gz压缩文件
- lrzsz上传下载文件，小型文件可通过此工具完成。需要安装`yum install lrzsz`
    - `rz` 跳出窗口进行上传
    - `sz 文件名` 下载文件

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
- `pwd` 查看当前目录完整路径
    - `pwdx $$` 查看当前进程启动文件所在目录，返回如`36240: /root`；`pwdx 10000`查看某个进程
    - `echo ${PWD}` 查看当前目录绝对路径，如`/root/test`
    - `echo ${PWD##*/}` 查看当前目录名，如`test`
- `tree mydir` 树形展示目录

### 磁盘分区和挂载

- 参考《阿里云服务器 ECS > 块存储 > 云盘 > 分区格式化数据盘 > Linux 格式化数据盘》 [^10]
- 一般阿里云服务器买的磁盘未进行格式化文件系统和挂载，`df -h`无法查询到磁盘设备，只能通过`fdisk -l`查看磁盘设备
- 阿里云`/dev/vda`表示系统盘，`/dev/vdb-z`表示数据盘，`dev/xvd?`表示非I/O优化实例。`/dev/vda1`/`/dev/vdb1`表示对应磁盘上的分区
- 无法卸载，提示`umount.nfs: /data: device is busy`时，可使用`fuser`(`yum install -y psmisc`安装)查看占用资源用户和进程信息(`fuser -m -v /data/`)，并退出相关进程

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
# 第一个扇区一般都使用默认的，直接回车即可；最后一个扇区大小根据你自己需要指定，但是一定要在给定范围内，这里是2048-20971519(10G的磁盘，=1024*1024*2*10G，此处需要多乘以2)，如果整个磁盘就分一个分区则继续回车(默认即为最大)，如根需要此分区设置大小为200M，则输入`+200M`（单位可为K/M/G/T/P）
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

### LVM使用

- centos安装时如果使用分区类型为LVM则会出现时/dev/mapper/centos-root等
- LVM使用参考 https://blog.51cto.com/13438667/2084924

    ![lvm](/data/images/lang/lvm.png)
    
    ```bash
    # **先 fdisk 创建分区 /dev/vdb1 和 /dev/vdb2，无需格式化(略)**
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
- 调整同VG下不同LV的大小，如调整home和root容量大小如下

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
- 调整磁盘大小(慎用)

    ```bash
    ### vg
    ## 扩展vg
    pvcreate /dev/sdc1 # 将新的磁盘分区创建为pv
    vgextend centos /dev/sdc1 # 将pv添加大vg组
    ## 缩小vg
    vgreduce centos /dev/sdc1 # 将一个PV从指定卷组中移除
    pvremove /dev/sdc1 # 移除对应pv

    ### pv
    ## 重设物理分区为120g。调整PV大小(进而缩小了VG的大小)
    pvresize --setphysicalvolumesize 120g /dev/sdb1

    ### lv (xfs分区是不支持减小操作的)
    ## 直接调整大小
    lvresize -L 500M -r /dev/mapper/centos-home # -r 相当于 resize2fs
    ## 缩小lv大小到10g
    umount /dev/mapper/centos-home
    # e2fsck -f /dev/mapper/centos-home
    resize2fs /dev/mapper/centos-home 10G # 缩小文件系统
    lvreduce -L -10G /dev/mapper/centos-home # 缩小lv
    ## 扩展lv
    lvextend -L +2G /dev/mapper/centos-home
    # resize2fs /dev/mapper/centos-home # 更新文件系统。resize2fs 针对的是ext2、ext3、ext4文件系统；xfs_growfs 针对的是xfs文件系统
    xfs_growfs /dev/mapper/centos-home
    ```
- 重命名VG、LV(无需umount和备份，数据也不会丢失)
    
    ```bash
    # 查看并记录基本信息。需要将/dev/hdd/hdd1改成/dev/vdisk/main
    vgs/lvs
    vgrename hdd vdisk
    lvrename /dev/vdisk/hdd1 main # 修改lv，注意此时vg为新的
    vi /etc/fstab # 修改之前的挂载信息
    ```
- 删除lvm磁盘挂载，直接删除/etc/fstab中对应条目，lvm相关配置会自动去掉

### 压缩包(推荐tar) [^1]

#### tar

- 解压：**`tar -zxvf archive.tar.gz -C /tmp`** 解压tar包，将gzip压缩包释放到/tmp目录下(tar不存在乱码问题)
    - `tar -xvf archive.tar` 表示解压到当前目录
- 压缩：**`tar -zcvf aezocn.tar.gz file1 file2 *.jpg dir1`** 将此目录所有jpg文件和dir1目录打包成aezocn.tar后，并且将其用gzip压缩，生成一个gzip压缩过的包，命名为aezocn.tar.gz(体积会小很多：1/10). windows可使用7-zip
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
        - `-C` 解压到指定目录(默认是当前目录)

#### gz

- `zcat test.sql.gz > test.sql` 解压。如果不输出到文件，则直接打印

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

```bash
## 安装
wget https://www.rarlab.com/rar/rarlinux-x64-5.9.1.tar.gz
tar -xzvf rarlinux-x64-5.9.1.tar.gz -C /usr/local
ln -s /usr/local/rar/rar /usr/local/bin/rar
ln -s /usr/local/rar/unrar /usr/local/bin/unrar

# 解压rar。e: 解压文件到当前目录
unrar e archive.rar
# 压缩成rar格式
rar a aezocn.rar *.jpg
```

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
    - `shift+g/G` 最后一行
- 翻屏
    - `Ctrl+f` 向下翻一屏
    - `Ctrl+b` 向上翻一屏
- 删除命令 `d`
    - `dd` **删除光标所在行**
    - `ndd` **删除光标以下#行(含光标行)**，如`2dd`删除2行(光标行和光标下一行)
    - `dw` 删除一个单词
    - `:.,$-1d` **删除从之前关标所在行到倒数第二行**(`.` 表示当前行；`$` 最后一行；`+n` 向下的n行；`-n` 向上的n行)
        - `dG` 删除当前行到下面所有行
        - `:.,$y` 复制当前行到最后一行
        - `:.,$s/#//` 将当期行到最后一行的#替换为空
    - `x` 删除光标所在处的单个字符
    - `nx` 删除光标所在处及向后的共n个字符
- **新加一行** `o`
- 复制命令 `y`命令，用法同`d`命令。**和粘贴命令`p`组合使用**
    - `yy` 复制一行：把光标移动到要复制的行上 - yy - 把光标移动到要复制的位置 - p
    - `nyy` 复制n行
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
    - `set number`/`set nu` 显示行号(命令模式执行该命令)
    - `set nonu` 不显示行号
    - 永久显示行号：在`/etc/virc`或`/etc/vimrc`中加入一行`set nu`
- 批量注释
    - `Ctrl+v` 进入列编辑模式，在需要注释处移动光标选中需要注释的行
    - `Shift+i`
    - 再插入注释符，比如按`#`或者`//`
    - 按`Esc`即可全部注释
- 批量删除注释：`ctrl+v`进入列编辑模式，横向选中列的个数(如"//"注释符号需要选中两列)，然后按`d`就会删除注释符号
- **跟shell交互**：`:! COMMAND` 在命令模式下执行外部命令，如mkdir

## 权限系统

### 用户管理 [^6]

- `useradd test` 新建test用户(默认在/home目录新建test对应的家目录test)
    - `useradd -d /home/aezo -m aezo` 添加用户(和设置宿主目录)
    - `usermod -d /home/home_dir -U aezo` 修改用户宿主目录
    - `useradd -r -g mysql mysql` 添加用户mysql，并加入到mysql用户组
        - `-r` 表示mysql用户是一个系统用户，不能登录
    - 修改用户名

        ```bash
        # 将old修改为new
        sudo pkill -9 -u old # 关闭旧用户session
        sudo usermod -l new old
        sudo usermod -d /home/new -m new # 修改用户目录(之前目录数据不会丢失)
        sudo groupmod -n new old # 修改用户组
        # 其他配置文件中保存的用户名和用户目录并不会被修改
        ```
- `passwd aezo` 修改密码
    - centos7忘记root用户密码找回可在启动时设置进入`sysroot/bin/sh`进行修改，参考：https://blog.51cto.com/scorpions/2059912
- 添加用户sudo权限
    - 使用sudo执行的命令都是基于root启动，创建的文件也是所属root

    ```bash
    # 添加写权限
    chmod u+w /etc/sudoers
    vi /etc/sudoers

    # (位置说明)文件内容修改
    root	ALL=(ALL) 	ALL
    # 新加的sudo用户
    # smalle  ALL=(ALL)   ALL
    # (加这一行)设置执行sudo不需要输入密码(否则sudo输入密码，有效期只有5分钟)。
    smalle  ALL=(ALL)   NOPASSWD: ALL
    # (需要去掉此行的注释)只要是wheel组不需要密码
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
- 用户组(一个用户可以属于多个组，但是只能有一个默认组)
    - `cat /etc/group` 查看组
    - `groupadd aezocn` 新建组
    - `groupdel aezocn` 删除组
    - `groups` 查看当前登录用户所属组
        - `groups smalle` 查看smalle用户所属组，如返回`smalle : test root`表示smalle属于test和root组，默认组为test
    - `usermod -g test smalle` 修改用户smalle的默认组为test
    - `usermod -G wheel smalle` 将用户smalle加入到组wheel，并去除之前的非默认组
    - `usermod -a -G wheel smalle` 保留之前的非默认组
    - `gpasswd -d smalle test` 将smalle从test组移除
- 查看用户
    - `cat /etc/passwd` 查看用户
        - 如`smalle(账号名称):x(密码):1000(账号UID):1000(账号GID):aezocn(用户说明):/home/smalle(家目录):/bin/bash(shell环境)`
    - `id smalle` 查看smalle用户信息。
        - 如`uid=1000(smalle) gid=1000(smalle) groups=1000(smalle),10(wheel)` gid表示用户默认组，groups表示用户属于smalle、wheel两个组
    - `who` 显示当前登录用户
    - `w` 查看当前登录用户操作信息
    - `whoami` 查看当前登录用户名
    - `last`/`last smalle` 查看用户登录历史

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
        - **方式一**：修改`sudo vi /etc/profile`，加入一行`umask 022`
        - 方式二：修改每个用户`sudo vi ~/.bashrc`文件，加入一行`umask 022`
- 常用命令
    - `find . -type d -exec chmod 755 {} \;` 修改当前目录及其子目录为775
    - `find . -type f -exec chmod 644 {} \;` 修改当前目录及其子目录的所有文件为644

### 系统资源权限

- `ulimit` 用来限制系统用户对shell资源的访问
    - `ulimit -a` 查看对单一用户资源限制情况
        - 如`open files`为能打开的文件(包括网络连接产生的文件描述符)个数限制
        - -H(hard) 设定资源的硬性限制，即不允许超过这个限制
        - -S(soft) 设定资源的弹性限制，可在资源不足的情况下修改此设置，但是不能超过hard
    - `ulimit -SHn 50000` 设定打开文件个数上限为50000(一般1G内存可以打开10W个文件，可通过`cat /proc/sys/fs/file-max`查看硬件最大能打开的文件)
        - 这个设置只是针对普通用户，root用户可能会超过这个设置
    - `vi /etc/security/limits.conf` 也可通过修改配置文件设置资源限制
- Linux core文件：https://blog.csdn.net/arau_sh/article/details/8182744

## ssh

### ssh介绍 [^2]

- SSH是建立在传输层和应用层上面的一种安全的传输协议。SSH目前较为可靠，专为远程登录和其他网络提供的安全协议。在主机远程登录的过程中有两种认证方式：
    - `基于口令认证`：只要你知道自己帐号和口令，就可以登录到远程主机。所有传输的数据都会被加密，但是不能保证你正在连接的服务器就是你想连接的服务器。可能会有别的服务器在冒充真正的服务器，也就是受到“中间人”这种方式的攻击。
    - `基于秘钥认证`：需要依靠秘钥，也就是你必须为自己创建一对秘钥，并把公用的秘钥放到你要访问的服务器上，客户端软件就会向服务器发出请求，请求用你的秘钥进行安全验证。服务器收到请求之后，现在该服务器你的主目录下寻找你的公用秘钥，然后吧它和你发送过来的公用秘钥进行比较。弱两个秘钥一致服务器就用公用秘钥加密“质询”并把它发送给客户端软件，客户端软件收到质询之后，就可以用你的私人秘钥进行解密再把它发送给服务器。
- 用基于秘钥认证，你必须要知道自己的秘钥口令。但是与第一种级别相比，这种不需要再网络上传输口令。第二种级别不仅加密所有传送的数据，而且“中间人”这种攻击方式也是不可能的（因为他没有你的私人密匙）。但是整个登录的过程可能需要10秒

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

- SSH连接
    - **`ssh-keygen` 生成秘钥对**。可以在服务器、客户端、开发机上生成
    - **将公钥 `id_rsa.pub` 内容追加到服务器的 `~/.ssh/authorized_keys` 文件中**。如登录服务器root账号则是`/root/.ssh/authorized_keys`，如登录aezo账号则是`/home/aezo/.ssh/authorized_keys`
    - **将私钥 `id_rsa` 保存在客户端的`~/.ssh/`目录**
- `ssh-keygen` 命令生成秘钥对
    - 运行 `ssh-keygen` 命令后再按三次回车会看到`RSA`，生成的秘钥文件默认路径为家目录下的`.ssh`，如`/home/smalle/.ssh/`。包含文件
        - `id_rsa` 密钥，保存在客户端。**客户端在通过ssh登录时，默认查找 id_rsa 文件，那么如果想让此客户端登录多个服务器，一般需要将此秘钥对应的公钥保存在多个服务器上，因此还需保管好相应公钥备用**
        - `id_rsa.pub` 公钥，保存服务端。
        - `known_hosts`(此机器作为客户端进行ssh连接时，认证过的服务器信息) 3 个文件。如：此客户端ip为`192.168.1.2`
    - `ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa` 以dsa模式生成
    - `ssh-keygen -t rsa -C "xxx@qq.com"` -C起到一个密码备注的作用，可以为任何内容
- **公钥保存到服务器**
    - **`ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.1.1`** 输入192.168.1.1密码，则会自动将公钥保存在服务器的`/root/.ssh/authorized_keys`文件中去此时。需要保证192.168.1.1服务器的root用户没有被禁用
    - 手动追加到authorized_keys文件中，`cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys`
    - **注意`authorized_keys`权限必须是600**。如果没有此文件，上述两种方式会自动创建，其中ssh-copy-id创建的是600，而通过cat追加创建的可能不是600权限导致无法使用
- **秘钥保存在客户端**
    - 如果是为了让客户端root用户登录服务器，则将公钥放入到/root/.ssh目录；如果提供给其他用户登录，可将公钥放在对应的家目录，如/home/aezo/.ssh/下
    - `.ssh`目录不存在可手动新建（可通过`ll -al`查看） [^5]
- 服务器说明
    - 把生成的公钥保存到服务器`authorized_keys`文件中(文件名有s)
- 客户端说明
    - 客户端可能是windos、linux，在某种业务场景可能也被当做一台服务器
    - 客户端公钥需要写入到服务端的`authorized_keys`文件
    - 客户端登录成功后会将服务器ip等信息加入到客户端`known_hosts`文件中(没有此文件时会自动新建)
- 免密登录服务器
    - `ssh 192.168.1.1` 此时不需要输入密码
    - 如果需要在`192.168.1.1`(客户机)上通过ssh登录`192.168.1.1`(服务器)，需要按照上述命令把公钥保存到服务器的`authorized_keys`
    - 如果是使用服务器的aezo账号登录服务器，则将公钥追加到/home/aezo/.ssh/authorized_keys文件中，并通过 `ssh aezo@192.168.1.1`进行登录
- 其他说明
    - 如何客户端登录失败，可在服务器查看访问日志`cat /var/log/secure`
        - 客户端登录提示`Permission denied (publickey,gssapi-keyex,gssapi-with-mic).`。说明秘钥验证失败，检查服务端是否有公钥，客户端是否有正确秘钥
    - **阿里云服务器使用**
        - 方式一：如上文所述方式，此时无需重启阿里云服务器
        - 方式二
            - 在阿里云管理后台生成秘钥或手动导入秘钥对，并关联到对应ECS上。阿里云生成的只能下载到秘钥，公钥可通过xshell连接后进行查看或连接后到服务器的authorized_keys文件中查看
            - 关联阿里云服务器秘钥后，需要到阿里云管理后进行服务器重启(不能在终端重启)。*重启后会自动禁用密码登录*
    - **AWS服务器(EC2)使用**
        - 使用PuTTY连接时：PuTTY 本身不支持 Amazon EC2 生成的私有密钥格式 (.pem)，PuTTY 有一个名为 PuTTYgen 的工具，可将密钥转换成所需的 PuTTY 格式 (.ppk)
- Putty/WinSCP 和 xshell/xftp
    - Putty是一个Telnet、SSH、rlogin、纯TCP以及串行接口连接软件。它包含Puttygen等工具，Puttygen可用于生成公钥和密钥（还可以将如AWS亚马逊云的密钥文件.pem转换为.ppk的通用密钥文件）
        - 在知道密钥文件时，可以通过Putty连接到服务器(命令行)，通过WinSCP连接到服务器的文件系统(FTP形式显示)
        - Puttygen使用：`类型选择RSA，大小2048` - `点击生成` - `鼠标在空白处滑动` - `保存公钥和密钥`
        - Putty使用：`Session的Host Name输入username@ip，端口22` - `Connection-SSH-Auth选择密钥文件` - `回到Session，在save session输入一个会话名称` - `点击保存会话` - `点击open登录服务器` - `下次可直接点击会话名称登录`
    - 通过PuttyGen将id_rsa转为.ppk(PuTTY format private key file)，将.ppk转成.pem(OpenSSH) [^13]
      - 将id_rsa转为.ppk：PuttyGen - Conversions - Import key - Save private Key
      - 将.ppk转成.pem：PuttyGen - Load - Conversions - Export OpenSSH Key - 保存为.pem文件
    - xshell/xftp是一个连接ssh的客户端
        - 使用xshell生成的秘钥进行连接：连接 - 用户身份验证 - 方法选择"public key"公钥 - 用户名填入需要登录的用户 - 用户密钥可点击浏览生成(需要将生成的公钥保存到对应用户的.ssh目录`cat /home/aezo/.ssh/id_rsa.pub >> /home/aezo/.ssh/authorized_keys`)。(必须使用自己生成的公钥和密钥，如果AWS亚马逊云转换后的ppk文件无法直接登录)
        - 使用服务器生成的秘钥文件连接：连接 - 用户身份验证 - 方法选择"public key"公钥 - 用户名填入需要登录的用户 - 用户密钥可点击浏览导入(**导入服务器生成的秘钥文件id_rsa，不是公钥文件**)
        - xshell提示"用户秘钥导入失败"：centos上生成的秘钥类型在xshell中不支持，**可以使用xshell进行秘钥生成** [^9]
            - 工具 - 用户秘钥管理 - 生成 - 保存公钥 - 选择生成的秘钥 - 导出秘钥
            - 将公钥追加到到服务器的`authorized_keys`文件：`cat my_key.pub >> authorized_keys`
	- Unix终端：`ssh -i my_private_file root@10.10.10.10`
        - `-i` 登录时指定私钥文件。ssh登录服务器默认使用的私有文件为`~/.ssh/id_dsa`、`~/.ssh/id_ecdsa`、`~/.ssh/id_ed25519`、`~/.ssh/id_rsa`，其他则需要使用`-i`指定
    - `cat /var/log/secure`查看登录日志
- **当支持证书登录后，可修改ssh配置禁用密码登录** [^7]

    ```bash
    vi /etc/ssh/sshd_config

    ## 修改文件内容
    Port 222 # 修改原22端口为222端口
    # (可选)是否允许root用户登陆(no不允许)，**如果要基于root证书登录则还是需要设置为yes**
    PermitRootLogin no
    # 是否允许使用用户名密码登录(no不允许，此时只能使用证书登录。在没有生成好Key，并且成功使用之前，不要设置为no)
    PasswordAuthentication no

    # 使配置生效
    systemctl restart sshd
    ```

## corn定时任务

- crontab命令语法：`crontab [ -u user ] { -e | -l | -r }` [^4]
    - `-u` 指定某用户任务(**默认是当前用户**，最终目标命令会已此用户身份运行)
        - `sudo crontab -e` 此时未指定`-u`，sudo则相当于`-u root`
    - `-e` 编辑当前用户的定时任务，默认在`/var/spool/`目录。或者 `sudo vi /etc/crontab`
    - `-l` 列出目前的时程表(`crontab -u root -l`)
    - `-r` 删除目前的时程表
- `systemctl reload crond` 重新加载配置
- `systemctl restart crond` 重启crond(**添加配置后需要重启**)
- 使用

    ```bash
    ## root用户定时执行脚本
    # 1.编辑脚本
    crontab -u root -e

    # 2.加入每分钟执行脚本配置(对应用户必须有执行此脚本权限，且此脚本文件有+x可执行属性)
    # 01 * * * * /home/smalle/script/test.sh

    # 3.重新加载
    systemctl reload crond
    
    # 4.查看日志
    tail -f /var/log/cron

    # 如果执行的任务脚本中有echo输出，则会给对应用户发系统邮件
    cat /var/spool/mail/root
    ```

### cron配置

- 相关命令

    ```bash
    crontab -l # 查看当前用户定时器
    sudo crontab -l # 查看root用户
    crontab -e # 编辑当前用户定时器
    sudo crontab -e # 编辑root用户定时器，加入`00 02 * * * /home/smalle/script/backup_mysql.sh`
	systemctl restart crond # 重启crond服务
    ```
- 配置举例(需要将此配置加入到crontab)
    - `30 2 1 * * /sbin/reboot` 表示每月第一天的第2个小时的第30分钟，执行命令/sbin/reboot(重启)
    - `00 02 * * * /home/smalle/script/backup_mysql.sh` 每天执行mysql备份脚本。脚本具体参考：[http://blog.aezo.cn/2016/10/12/db/mysql-dba/](/_posts/db/mysql-dba.md#linux脚本备份(mysqldump))
    - `*/3 * * * * /home/smalle/script/test.sh` 每3分钟执行一次脚本

- 配置说明如下

    ```shell
    # Example of job definition:
    # .---------------- minute (0 - 59)，如 10 表示没第10分钟运行。每分钟用 * 或者*/1表示，整点分钟数为00或0
    # |  .------------- hour (0 - 23)
    # |  |  .---------- day of month (1 - 31)
    # |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
    # |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
    # |  |  |  |  |
    # *  *  *  *  * [user] my-command
    # (1) 其中用户名一般可以省略
    # (2) 精确到秒解决方案, 以下3行表示每20秒执行一次
    # * * * * * my-command
    # * * * * * sleep 20; my-command
    # * * * * * sleep 40; my-command
    ```
- 常用符号
    - `*` 表示所有值 
    - `?` 表示未说明的值，即不关心它为何值
    - `-` 表示一个指定的范围
    - `,` 表示附加一个可能值
    - `/` 符号前表示开始时间，符号后表示每次递增的值

## linux命令

- [man-pages](https://man7.org/linux/man-pages/dir_all_alphabetic.html)、[Linux命令大全](https://man.linuxde.net/)
- linux三剑客grep、sed、awk语法

### grep过滤器

- 语法

    ```bash
    grep [-acinv] [--color=auto] '搜寻字符串' filename
    # filename不能缺失

    # 选项与参数：
    # -v **反向选择**，亦即显示出没有 '搜寻字符串' 内容的那一行
    # -R/-r 递归查询子目录
    # -i 忽略大小写的不同，所以大小写视为相同
    # -l 显示文件名
    # -E 以 egrep 模式匹配
    # -P 应用正则表达式
    # -n 顺便输出行号
    # -c 计算找到 '搜寻字符串' 的次数
    # --color=auto 可以将找到的关键词部分加上颜色的显示喔；--color=none去掉颜色显示
    # -a 将 binary 文件以 text 文件的方式搜寻数据
    # -A <n> 打印匹配行的后几行
    # -B <n> 打印匹配行的前几行
    ```
- [grep正则表达式](https://www.cnblogs.com/terryjin/p/5167789.html)
- 常见用法

    ```bash
    grep "search content" filename1 filename2.... filenamen # 在多个文件中查找数据(查询文件内容)
    grep 'search content' *.sql # 查找已`.sql`结尾的文件
    grep -R 'test' /data/* # 在/data目录及子目录查询
    grep hello -rl * # 查询当前目录极其子目录文件(-r)，并只输出文件名(-l)

    grep -5 'parttern' filename # 打印匹配行的前后5行。或 `grep -C 5 'parttern' filename`
    grep -A 5 'parttern' filename # 打印匹配行的后5行
    grep -B 5 'parttern' filename # 打印匹配行的前5行

    grep -E 'A|B|C.*' filename # 打印匹配 A 或 B 或 C* 的数据
    echo office365 | grep -P '\d+' -o # 返回 365
    grep 'A' filename | grep 'B' # 打印匹配 A 且 B 的数据
    grep -v 'A' filename # 打印不包含 A 的数据

    # 根据日志查询最近执行命令时间(结合tail -1)
    grep 'cmd-hostory' /var/log/local1-info.log | tail -1 | awk '{print $1,$2}'

    # 查看20号的oracle trc日志，并找出日志中出现ORA-的情况
    ll -hrt *.trc | grep ' 20 ' | awk '{print $9}' | xargs grep 'ORA-'
    ```
- grep结果单独处理

    ```bash
    # 方式一
    ps -ewo pid,etime,cmd | grep ofbiz.jar | grep -v grep | while read -r pid etime cmd ; do echo "===>$pid $cmd $etime"; done;

    # 方式二
    while read -r proc; do
        echo '====>' $proc
    done <<< "$(ps -ef | grep ofbiz.jar | grep -v grep)"
    ```

### sed行编辑器

- 文本处理，默认不编辑原文件，仅对模式空间中的数据做处理；而后处理结束后将模式空间打印至屏幕
- 语法 `sed [options] '内部命令表达式' file ...`
- 参数
    - `-n` 静默模式，不再默认显示模式空间中的内容
	- `-i` **直接修改原文件**(默认只输出结果。可以先不加此参数进行修改预览)
	- `-e script -e script` 可以同时执行多个脚本
	- `-f` 如`sed -f /path/to/scripts file`
	- `-r` 表示使用扩展正则表达式
- 内部命令
    - 内部命令表达式如果含有变量可以使用双引号，单引号无法解析变量
    - 前缀修饰符
        - `s` 查找并替换，**`s/pattern/string/修饰符`**
            - 默认只替换每行中第一次被模式匹配到的字符串；**其中/可为其他分割符，如`#`、`@`等，也可通过右斜杠转义分隔符**
            - `sed "s/foo/bar/g" test.md` 替换每一行中的"foo"都换成"bar"(加-i直接修改源文件)
            - `sed 's#/data#/data/harbor#g' docker-compose.yml` 修改所有"/data"为"/data/harbor"
    - 后缀修饰符
        - `g` 全局查找
        - `i` 忽略字符大小写
        - `p` 显示符合条件的行
        - `d` 删除符合条件的行
    - `a \string`: 在指定的行后面追加新行，内容为string
		- `\n` 可以用于换行
	- `i \string`: 在指定的行前面添加新行，内容为string
	- `r <file>` 将指定的文件的内容添加至符合条件的行处
	- `w <file>` 将地址指定的范围内的行另存至指定的文件中
	- `&` 引用模式匹配整个串
- 示例

    ```bash
    # （未加-i参数不会真正修改数据）修改当前目录极其子目录下所有文件，将zhangsan改成lisi。grep -rl 递归显示文件名
    sed "s/zhangsan/lisi/g" `grep zhangsan -rl *`
    # 加上参数`-i`会直接修改原文件(去掉文件中所有空行)
    sed -i -e '/^$/d' /home/smalle/test.txt
    # 删除/etc/grub.conf文件中行首的空白符
    sed -r 's@^[[:space:]]+@@g' /etc/grub.conf
    # 替换/etc/inittab文件中"id:3:initdefault:"一行中的数字为5
    sed 's@\(id:\)[0-9]\(:initdefault:\)@\15\2@g' /etc/inittab
    # 删除/etc/inittab文件中的空白行(此时会返回修改后的数据，但是原始文件中的内容并不会被修改)
    sed '/^$/d' /etc/inittab
    
    # s表示替换，\1表示用第一个括号里面的内容替换整个字符串。sed支持*，不支持?、+，不能用\d之类，正则支持有限
    echo here365test | sed 's/.*ere\([0-9]*\).*/\1/g' # 365

    # 查找一段时间的日志（此处查询2020-12-03 02到2020-12-03 04的日志，此处使用*表示模糊查询）。注意：开始时间和结束时间必须要是日志里面有的，否则查询不到结果
    cat access.log | sed -n '/03\/Dec\/2020:02*/,/03\/Dec\/2020:04*/p' | more
    ```
    - [其他示例](https://github.com/lutaoact/script/blob/master/sed%E5%8D%95%E8%A1%8C%E8%84%9A%E6%9C%AC.txt)

### awk文本分析工具

- 相对于grep的查找，sed的编辑，awk在其对数据分析并生成报告时，显得尤为强大。**简单来说awk就是把文件逐行的读入，以空格/tab为默认分隔符将每行切片，切开的部分再进行各种分析处理(每一行都会执行一次awk主命令)**
- 语法

    ```bash
    awk '[BEGIN {}] {pattern + action} [END {}]' {filenames}
    # pattern 表示AWK在文件中查找的内容。pattern就是要表示的正则表达式，用斜杠(`'/xxx/'`)括起来
    # action 是在找到匹配内容时所执行的一系列命令(awk主命令)
    # 花括号(`{}`)不需要在程序中始终出现，但它们用于根据特定的模式对一系列指令进行分组

    ## awk --help
    Usage: awk [POSIX or GNU style options] -f progfile [--] file ...
    Usage: awk [POSIX or GNU style options] [--] 'program' file ...
    POSIX options:		GNU long options: (standard)
    -f progfile		--file=progfile         # 指定程序文件
    -F fs			--field-separator=fs    # 指定域分割符(可使用正则，如 `-F '[\t \\\\]'`)
    -v var=val		--assign=var=val
    # ...
    ```
- awk中同时提供了`print`和`printf`两种打印输出的函数
    - `print` 参数可以是变量、数值或者字符串。**字符串必须用双引号引用，参数用逗号分隔。**如果没有逗号，参数就串联在一起而无法区分。
    - `printf` 其用法和c语言中printf基本相似，可以格式化字符串，输出复杂时
- 案例

```bash
# 显示最近登录的5个帐号。读入有'\n'换行符分割的一条记录，然后将记录按指定的域分隔符划分域(填充域)。**$0则表示所有域, $1表示第一个域**，$n表示第n个域。默认域分隔符是空格/tab，所以$1表示登录用户，$3表示登录用户ip，以此类推
last -n 5 | awk '{print $1}'
last -n 5 | awk '{print $1,$2}' # print多个变量用逗号分割，显示默认带有空格

# 只是显示/etc/passwd中的账户。`-F`指定域分隔符为`:`，默认是空格/tab
cat /etc/passwd | awk -F ':' '{print $1}'

# 查找root开头的用户记录
awk -F : '/^root/' /etc/passwd
```

#### 变量

- `$0`变量是指整条记录，`$1`表示当前行的第一个域，`$2`表示当前行的第二个域，以此类推
- awk内置变量：awk有许多内置变量用来设置环境信息，这些变量可以被改变，下面给出了最常用的一些变量
    - `ARGC` 命令行参数个数
    - `ARGV` 命令行参数排列
    - `ENVIRON` 支持队列中系统环境变量的使用
    - `FILENAME` awk浏览的文件名
    - `FNR` 浏览文件的记录数
    - `FS` 设置输入域分隔符，等价于命令行-F选项
    - `NF` 浏览记录的域的个数
    - `NR` 已读的记录数
    - `OFS` 输出域分隔符
    - `ORS` 输出记录分隔符(`\n`)
    - `RS` 控制记录分隔符
- 自定义变量
    - 下面统计/etc/passwd的账户人数

        ```bash
        awk '{count++;print $0;} END {print "user count is ", count}' /etc/passwd
        # 打印如下
        # root:x:0:0:root:/root:/bin/bash
        # ......
        # user count is 40
        ```
        - count是自定义变量。之前的action{}里都是只有一个print，其实print只是一个语句，而action{}可以有多个语句，以;号隔开。这里没有初始化count，虽然默认是0，但是妥当的做法还是初始化为0
- awk与shell之间的变量传递方法
    - awk中使用shell中的变量

        ```bash
        # 获取普通变量(第一个双引号为了转义单引号，第二个双引号为了转义变量中的空格)
        var="hello world" && awk 'BEGIN{print "'"$var"'"}'
        # 把系统变量var传递给了awk变量awk_var
        var="hello world" && awk -v awk_var="$var" 'BEGIN {print awk_var}'

        # 获取环境变量(ENVIRON)
        var="hello world" && export var && awk 'BEGIN{print ENVIRON["var"]}'
        ```
    - awk向shell变量传递值

        ```bash
        eval $(awk 'BEGIN{print "var1='"'str 1'"';var2='"'str 2'"'"}') && echo "var1=$var1 ----- var2=$var2" # var1=str1 ----- var2=str2
        # 读取temp_file中数据设置到变量中(temp_file中输入`hello world:test`，如果文件中有多行，则最后一行会覆盖原来的赋值)
        eval $(awk '{printf("var3=%s; var4=%s;",$1,$2)}' temp_file) && echo "var3=$var3 ----- var4=$var4" # var3=hello ----- var4=world:test
        ```

#### BEGIN/END

- 提供`BEGIN/END`语句(必须大写)
    - BEGIN和END，这两者都可用于pattern中，**提供BEGIN的作用是扫描输入之前赋予程序初始状态，END是扫描输入结束且在程序结束之后执行一些扫尾工作**。任何在BEGIN之后列出的操作(紧接BEGIN后的{}内)将在awk开始扫描输入之前执行，而END之后列出的操作将在扫描完全部的输入之后执行。通常使用BEGIN来显示变量和预置(初始化)变量，使用END来输出最终结果。
    - 统计某个文件夹下的文件占用的字节数，过滤4096大小的文件(一般都是文件夹):

        ```bash
        ls -l | awk 'BEGIN {size=0;print "[start]size is", size} {if($5!=4096){size=size+$5;}} END {print "[end]size is", size/1024/1024, "M"}'
        # 打印如下
        # [start]size is 0
        # [end]size is 30038.8 M
        ```
- 支持if判断、循环等语句

### date

```bash
date -d 'yesterday' # 获取昨天。或 date -d 'last day' 
date -d 'tomorrow' # 获取明天。或 date -d 'next day' 
date -d 'last month' # 获取上个月 
date -d 'next month' # 获取下个月 
date -d 'last year' # 获取上一年 
date -d 'next year' # 获取下一年 
date -d '1 minute ago' # 获取1分钟前
date -d '3 year ago' # 三年前 
date -d '-5 year ago' # 五年后 
date -d '-2 day ago' # 两天后 
date -d '1 month ago' # 一个月前 

time=$(date "+%Y-%m-%d %H:%M:%S")
```

### find

- 语法

```bash
# default path is the current directory; default expression is -print
# expression由options、tests、actions组成
find [-H] [-L] [-P] [-Olevel] [-D help|tree|search|stat|rates|opt|exec] [path...] [expression]

## expression#options
-mindepth n # 目录进入最小深度
    # eg: -mindepth 1 # 意味着处理所有的文件，除了命令行参数指定的目录中的文件
-maxdepth n # 目录进入最大深度
    # eg: -maxdepth 0 # 只处理当前目录的文件(.)

## expression#tests
-name <patten> # 基本的文件名与shell模式pattern相匹配。**正则建议使用""或''包裹**
    # eg: -name "*.log" # `.log`开头的文件。如果不用双引号包裹，*可能展开为当前目录下所有的文件；或者使用\转义
-type <c> # 文件类型，c取值
    f # 普通文件(regular file)
    d # 目录(directory)
    s # socket

-atime <n> # 针对文件的访问时间，判断 "其访问时间" < "当前时间-(n*24小时)" 是否为真。对应stat命令获取的 Access 时间，读取文件或者执行文件时更改的
-mtime <n> # 针对文件的修改时间(天)。对应stat命令获取的 Modify 时间，是在写入文件时随文件内容的更改而更改的
    # eg: -mtime +30 # 30天之前的修改过的文件
    # eg：-mtime -30 # 过去30天之内修改过的文件
-ctime <n> # 针对文件的改变时间(天)。对应stat命令获取的 Change 时间，是在写入文件，更改所有者，权限或链接设置是随inode(存放文件基本信息)内容的更改而更改的
-amin <n> # 类似-atime，只不过此参数是基于分钟计算
-mmin <n>
-cmin <n>
-newerXY <reference> # 比较文件的时间戳，其中XY的取值为：a(访问时间)、c(改变时间,移动目录时间也会变)、m(修改时间)、t(绝对时间)、B(文件引用的出现时间)；参数值时间必须精确到天或者秒，且为前闭后开区间
    # find . -type f -newermt '2020-01-17 13:40' ! -newermt '2020-01-17 13:45' -exec cp {} ./bak \; # 将当前目录下 [2020-01-17 13:40,2020-01-17 13:45) 时间段内修改或生成的文件拷贝到bak目录下。同理：-newerat、-newerct

## expression#actions
-exec command # 执行命令。命令的参数中，字符串`{}`将以正在处理的文件名替换；这些参数可能需要用 `\`来escape，或者用括号括住，防止它们被shell展开；其余的命令行参数将作为提供给此命令的参数，直到遇到一个由`;`组成的参数为止
    # eg: -exec cp {} {}.bak \; # 复制查询到的文件
```
- 示例

```bash
sudo find / -name nginx.conf # 全局查询文件位置(查看`nginx.conf`文件所在位置)
find /home/smalle/s_*/in -maxdepth 1 -type f # 查询s_开头目录下，in目录的文件（不包含in的子目录）。或者 find /home/smalle/s_*/in/* -type f
find path_A -name '*AAA*' -exec mv -t path_B {} + # 批量移动，下同
find path_A -name "*AAA*" -print0 | xargs -0 -I {} mv {} path_B
find . -mtime +15 | wc -l # 统计15天前修改过的文件的个数

find . -type d -exec chmod 755 {} \; # 修改当前目录及其子目录为775
find . -type f -exec chmod 644 {} \; # 修改当前目录及其子目录的所有文件为644

find -name '*.TXT' -type f -mtime +15 -exec mv {} ./bak \; # 将15天前修改过的文件移动到备份目录
# **将当前目录下的去年修改过的文件移动到备份目录**. (1) 需先创建好备份目录 (2) 时间精确到秒且为前闭后开区间
find . -name '*.log' -newermt "$(($(date +%Y)-1))-01-01 00:00:00" ! -newermt "$(($(date +%Y)))-01-01 00:00:00" | xargs -i mv {} ./backup/backup_log_$(($(date +%Y)-1))

find -type f | xargs # xargs会在一行中打印出所有值
for item in $(find -type f | xargs) ; do # 循环打印每个文件
    file $item
done
```

### sh

```bash
sh [options] [file] # 同 bash，从标准输入中读取命令，命令在子shell中执行
    -c # 命令从-c后的字符串读取
    -s # 后面跟的参数，从第一个非 - 开头的参数，就被赋值为子shell的$1,$2,$3....
        # echo 'ls $2' | sh -s '' '-l' # 类似 ls -l
```

### xrags

- xargs 可以将管道或标准输入(stdin)数据转换成命令行参数，也能够从文件的输出中读取数据。它能够捕获一个命令的输出，然后传递给另外一个命令
- xargs 默认的命令是 echo
- xargs 也可以将单行或多行文本输入转换为其他格式，例如多行变单行，单行变多行
- 示例

```bash
-n<num> # 后面加次数，表示命令在执行的时候一次用的argument的个数，默认是用所有的。eg：`cat test.txt | xargs` 多行转单行
-i/-I # 这得看linux支持了，将xargs的每项名称，一般是一行一行赋值给 {}
-d delim # 分隔符，默认的xargs分隔符是回车，argument的分隔符是空格，这里修改的是xargs的分隔符

## 示例
cat test.txt | xargs # 多行转单行
cat test.txt | xargs -n3 # 多行输出，每此使用3个参数
echo "nameXnameXnameXname" | xargs -dX # 定义分割符：name name name name
ls *.jpg | xargs -n1 -I {} cp {} /data/images # 复制所有图片文件到 /data/images 目录下

# 配合自定义函数使用
echo 'echo $*' > my.sh
cat > arg.txt << EOF
aaa
bbb
EOF
cat arg.txt | xargs -I {} ./my.sh {} ...
# 打印
aaa ...
bbb ...
```

### logger

- `rsyslog`是一个C/S架构的服务，可监听于某套接字，帮其它主机记录日志信息。rsyslog是CentOS 6以后的系统使用的日志系统，之前为syslog
- `logger` 是用于往系统中写入日志，他提供一个shell命令接口到rsyslog系统模块。默认记录到系统日志文件`/var/log/messages`
- Linux系统日志信息分为两个部分内核信息和设备信息。共用配置文件`/etc/rsyslog.conf`(CentOS 6之前为`/etc/syslog.conf`)
    - 内核信息 -> klogd -> syslogd -> /var/log/messages等文件
    - 设备信息 -> syslogd -> /var/log/dmesg、/var/log/messages等文件
        - 设备可以使用自定义的设备local0-local7，使用自定义的设备照样可以将设备信息(日志)发送给rsyslog
- 查看linux相关日志
    - `/var/log/messages` 查看系统日志
    - `dmesg` 查看设备日志，如引导时的日志
    - `last` 查看登录成功记录
    - `lastb -10` 查看最近10条登录失败记录
    - `history` 执行命令历史
- CentOS 7 修改日志时间戳格式 [^8]

```bash
# Jul 14 13:30:01 localhost systemd: Starting Session 38 of user root.
# 2018-07-14 13:32:57 desktop0 systemd: Starting System Logging Service...

## 修改 /etc/rsyslog.conf 
# Use default timestamp format
#$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat # 这行是原来的将它注释，添加下面两行
$template CustomFormat,"%$NOW% %TIMESTAMP:8:15% %HOSTNAME% %syslogtag% %msg%\n"
$ActionFileDefaultTemplate CustomFormat

## 重启
systemctl restart rsyslog.service
```
- logger使用案例 [^6]

```bash
## 简单使用
# 默认记录到系统日志文件 /var/log/messages
logger hello world  # 记录如 `Dec  5 15:34:58 localhost root: hello world`
# -i 记录进程id
logger -i test1...  # `Dec  5 15:34:58 localhost root[23162]: test1`
# -s 输出标准错误(命令行会显示此错误)，并且将信息打印到系统日志中
logger -i -s test2  # `Dec  5 15:34:58 localhost root[23162]: test2`
# -t 日志标记，默认是root
logger -i -t test test3 # `Dec  5 15:34:58 localhost test[23162]: test2`
# -p 指定输入消息日志级别，优先级可以是数字或者指定为 "facility(设施、信道).level(优先级)" 的格式(默认级别为 "user.notice")，日志会根据配置文件/etc/rsyslog.conf将日志输出到对应日志文件，默认为/var/log/messages
# 固定的 facility 和 level 的类型参考：https://www.cnblogs.com/xingmuxin/p/8656498.html
logger -it test -p syslog.info "test4..." # `Dec  5 15:34:58 localhost test[23162]: test4...`

## 基于日志级别自定义日志输出文件
# 修改日志配置文件。增加配置`local1.info /var/log/local1-info.log`
vi /etc/rsyslog.conf
systemctl restart rsyslog # 重启使配置文件生效
logger -it test -p local1.info "test5..." # 此时在 /var/log/local1-info.log 中可看到 `Dec  5 15:34:58 localhost test[23162]: test5...`
```
- `/etc/rsyslog.conf` 配置说明
    - 会自动根据日志文件大小切割日志，生成 xxx-YYYYMMDD 的日志历史
    - 修改日志文件后需要重启服务 `systemctl restart rsyslog` (重启后新配置生效会有一点延迟)

```bash
#### RULES ####
# 如果日志级别为 local1.info，则将日志输出到文件 /var/log/local1-info.log
local1.info /var/log/local1-info.log

# ### begin forwarding rule ###
# 可配置同步日志到远程机器
```

#### 记录命令执行历史到日志文件

```bash
# 注：此脚本无法记录清除日志的的命令`history -c`
# root用户执行
su - root
source <(curl -L https://raw.githubusercontent.com/oldinaction/scripts/master/shell/prod/conf-recode-cmd-history.sh)
# 查看日志
tail -f /var/log/local1-info.log

# 日志格式如下
2019-01-01 07:55:42 localhost [pybiz_monitor][1594]: [pybiz_monitor.run_script][success]程序启动成功 # python监控脚本日志
2019-01-01 15:17:20 localhost cmd-hostory[root][14479]: [/root]  3001  2020-12-15 15:17:20 10.10.10.10 root cd /home # 执行命令日志
```

### dd 磁盘读写测试

- 磁盘性能
    - 固态硬盘，在SATA 2.0接口上平均读取速度在`225MB/S`，平均写入速度在`71MB/S`。在SATA 3.0接口上，平均读取速度骤然提升至`311MB/S`

- 用于复制文件并对原文件的内容进行转换和格式化处理
    
```bash
## 参数说明
if      # 代表输入文件。如果不指定if，默认就会从stdin中读取输入
of      # 代表输出文件。如果不指定of，默认就会将stdout作为默认输出
bs      # 代表字节为单位的块大小，如64k
count   # 代表被复制的块数，如4k/4000
# 大多数文件系统的默认I/O操作都是缓存I/O，数据会先被拷贝到操作系统内核的缓冲区中，然后才会从操作系统内核的缓冲区拷贝到应用程序的地址空间。dd命令不指定oflag或conv参数时默认使用缓存I/O
oflag=direct    # 指定采用直接I/O操作。直接I/O的优点是通过减少操作系统内核缓冲区和应用程序地址空间的数据拷贝次数，降低了对文件读取和写入时所带来的CPU的使用以及内存带宽的占用
oflag=dsync     # dd在执行时每次都会进行同步写入操作，可能是最慢的一种方式了，因为基本上没有用到写缓存(write cache)。每次读取64k后就要先把这64k写入磁盘(每次都同步)，然后再读取下面这64k，一共重复4k次(4000)。可能听到磁盘啪啪的响，比较伤磁盘
oflag=syns      # 与上者dsyns类似，但同时也对元数据（描述一个文件特征的系统数据，如访问权限、文件拥有者及文件数据块的分布信息等。）生效，dd在执行时每次都会进行数据和元数据的同步写入操作
conv=fdatasync  # dd命令执行到最后会执行一次"同步(sync)"操作，这时候得到的速度是读取这286M数据到内存并写入到磁盘上所需的时间
conv=fsync      # 与上者fdatasync类似，但同时元数据也一同写入

/dev/null # 伪设备，回收站，写该文件不会产生IO
/dev/zero # 伪设备，会产生空字符流，但不会产生IO
```
- `dd if=/dev/zero of=test bs=64k count=4k oflag=dsync` 在当前目录创建文件test，并每次以64k的大小往文件中读写数据，总共执行4000次，最终产生test文件大小为268M。以此测试磁盘操作速度
- 测试案例

```bash
# dd if=/dev/zero of=test bs=64k count=4k oflag=dsync # 测试结果如下
268435456 bytes (268 MB) copied, 26.3299 s, 10.2 MB/s               # 本地 SSD 磁盘直接操作
268435456 bytes (268 MB) copied, 261.475 s, 1.0 MB/s                # 本地 HDD 磁盘直接操作
268435456 bytes (268 MB) copied, 14.8903 s, 18.0 MB/s               # 阿里云 SSD 磁盘直接操作
268435456 bytes (268 MB, 256 MiB) copied, 1637.61 s, 164 kB/s       # 本地ceph集群(1 ssd + 2 hdd)
268435456 bytes (268 MB, 256 MiB) copied, 90.0906 s, 3.0 MB/s       # 本地ceph集群(3 ssd)
```

### sgdisk 磁盘操作工具

```bash
# 安装
yum install -y gdisk

# 查看所有GPT分区
sgdisk -p /dev/sdb
# 查看第一个分区
sgdisk -i 1 /dev/sdb
# 创建了一个不指定大小、不指定分区号的分区
sgdisk -n 0:0:0 /dev/sdb # -n 分区号:起始地址:结束地址
# 创建分区1，从默认起始地址开始的10G的分区
sgdisk -n 1:0:+10G /dev/sdb
# 将分区方案写入文件进行备份
sgdisk --backup=/root/sdb.partitiontable /dev/sdb
# 删除第一分区
sgdisk -d 1 /dev/sdb
# 删除所有分区(提示：GPT data structures destroyed!)
sgdisk --zap-all --clear --mbrtogpt /dev/sdb
```

### 其他命令

- 帮助
    - `ls --help` 查看ls的命令说明
    - `curl -h` 查看curl命令帮助
    - `help ulimit` 查看ulimit命令帮助
    - `info ls`
    - `man ls` 查看ls的详细命令说明
        - `yum install -y man man-pages`
        - 安装中文man手册
            
            ```bash
            wget https://src.fedoraproject.org/repo/pkgs/man-pages-zh-CN/manpages-zh-1.5.2.tar.bz2/cab232c7bb49b214c2f7ee44f7f35900/manpages-zh-1.5.2.tar.bz2
            
            yum install bzip2
            tar jxvf  manpages-zh-1.5.2.tar.bz2

            cd manpages-zh-1.5.2
            sudo ./configure --disable-zhtw #默认安装 
            sudo make && sudo make install

            vi ~/.bash_profile
            alias cman='man -M /usr/local/share/man/zh_CN' # 为了不抵消man，创建cman命令
            source ~/.bash_profile
            ```
- 系统
    - `date` 显示当前时间; `cal` 显示日历
    - `history` 查看历史执行命令
        - 默认记录1000条命令，编号越大表示越近执行。用户所键入的命令都会记录在用户家目录下的`.bash_history`文件中
            - `!n` 再次执行此命令(n 是命令编号)
            - `!$` 它用于指代上次键入的参数
            - `!!` 可以指代上次键入的命令
        - `history -c` 清除历史。其他人登录也将看不到，历史中不会显示清除的命令
    - `last` 查看最近登录用户
    - `w` 查看计算机运行时间，当前登录用户信息
    - `wall <msg>` 通知所有人登录人一些信息 
- 技巧
    - `clear` 清屏
    - `yes y` 一直输出字符串y
        - `yes y | cp -i new old` `cp` 用文件覆盖就文件(`-i`存在old文件需进行提示，否则无需提示；`-f`始终不进行提示)，而此时前面会一致输出`y`，相当于自动输入了y进行确认cp操作
    - `\` 回车后可将命令分多行运行(后面不能带空格)

## 运维&工具

### 系统信息查询

- 查看内核版本 `uname -r`
- 查看操作系统版本 `cat /proc/version`
    - 如腾讯云服务器 `Linux version 3.10.0-327.36.3.el7.x86_64 (builder@kbuilder.dev.centos.org) (gcc version 4.8.5 20150623 (Red Hat 4.8.5-4) (GCC) ) #1 SMP Mon Oct 24 16:09:20 UTC 2016` 中的 `3.10.0` 表示内核版本 `x86_64` 表示是64位系统
- 查看CentOS版本 **`cat /etc/redhat-release`/`cat /etc/system-release`** 如：CentOS Linux release 7.2.1511 (Core)
- `cat /proc/meminfo && free` 查看内存使用情况
    - `/proc/meminfo`为内存详细信息
        - `MemTotal` 内存总数
        - `MemFree` 系统尚未使用的内存
        - `MemAvailable` 应用程序可用内存数。系统中有些内存虽然已被使用但是可以回收的，比如cache/buffer、slab都有一部分可以回收，所以MemFree不能代表全部可用的内存，这部分可回收的内存加上MemFree才是系统可用的内存，即：**MemAvailable ≈ MemFree + Buffers + Cached**。MemFree是说的系统层面，MemAvailable是说的应用程序层面
    - `free` 为内存概要信息
- `lscpu` 列举cpu信息
    - `cat /proc/cpuinfo` 查看CPU使用情况

    ```bash
    # 查看CPU信息(型号): Intel(R) Xeon(R) CPU E5-2630 0 @ 2.30GHz
    cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
    # 查看物理CPU个数，eg: 1
    cat /proc/cpuinfo | grep "physical id"| sort| uniq| wc -l
    # 查看每个物理CPU中core的个数(即核数)，eg：6
    cat /proc/cpuinfo | grep "cpu cores"| uniq
    # 查看逻辑CPU的个数，eg：12
    cat /proc/cpuinfo | grep "processor"| wc -l
    ```
- 磁盘使用查看
    - `df -h` 查看磁盘使用情况和挂载点信息
        - `df /root -h` **查看/root目录所在挂载点**(一般/dev/vda1为系统挂载点，重装系统数据无法保留；/dev/vab或/dev/mapper/centos-root等用来存储数据)
    - `du -h --max-depth=1` 查看当前目录以及一级子目录磁盘使用情况；二级子目录可改成2；`du -h` 查看当前目录及其子目录大小
- `hostname` 查看hostname
    - `hostnamectl --static set-hostname aezocn` 修改主机名并重启
- `env` 查看环境变量

### 查看网络信息

- 更多网络知识参考：[《网络》http://blog.aezo.cn/2019/06/20/linux/network/](/_posts/linux/network.md)
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
- `curl http://www.baidu.com` 获取网页内容。参考：http://www.ruanyifeng.com/blog/2019/09/curl-reference.html

    ```bash
    -d              # 发送 POST 请求的数据体    # curl -d'login=emma＆password=123'-X POST https://google.com/login
    -H              # 添加 HTTP 请求的标头      # curl -H 'Accept-Language: en-US' https://google.com
    -L              # 会让 HTTP 请求跟随服务器的重定向。curl 默认不跟随重定向
    -O              # 将服务器回应保存成文件，并将 URL 的最后部分当作文件名。等同于wget # curl -O https://www.example.com/foo/bar.html (文件名bar.html)
    -o              # 将服务器的回应保存成文件并重命名 # curl -o my.html https://www.example.com (文件名my.html)
    -v              # 输出通信的整个过程，用于调试
    -b              # 向服务器发送 Cookie       # curl -b 'foo1=bar' -b 'foo2=baz' https://google.com # -b也可接cookie文件
    -c              # 将服务器设置的 Cookie 写入一个文件
    --limit-rate    # 用来限制 HTTP 请求和回应的带宽，模拟慢网速的环境  # curl --limit-rate 200k https://google.com
    --socks5        # 使用socks5协议            # curl --socks5 127.0.0.1:1080 http://www.qq.com
    ```
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
    - `ps axo pid,ppid,comm,pmem,lstart,etime,cmd | grep java` lstart启动时间，etime运行时间
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

    - **PID：包含了该进程ID和线程ID**
    - VIRT 值最高的进程就是内存使用最多的进程
    - S列进程状态：一般 I 代表空闲，R 代表运行，S 代表休眠，D 代表不可中断的睡眠状态，Z 代表(zombie)僵尸进程，T 或 t 代表停止
- 快捷键

    ```bash
    # h 进入帮助；Exc/q 退出帮助
    Help for Interactive Commands - procps-ng version 3.3.10
    Window 3:Mem: Cumulative mode On.  System: Delay 3.0 secs; Secure mode Off.
        # 全局配置：Z 颜色，B 背景
        Z,B,E,e   Global: 'Z' colors; 'B' bold; 'E'/'e' summary/task memory scale
        # 总的统计：l 显示负载(默认显示)；t 显示CPU使用图示（重复按键可切换显示模式）；m 显示内存使用图示（重复按键可切换显示模式）
        l,t,m     Toggle Summary: 'l' load avg; 't' task/cpu stats; 'm' memory info
        0,1,2,3,I Toggle: '0' zeros; '1/2/3' cpus or numa node views; 'I' Irix mode
        # 字段配置：f 进入字段操作界面（d 增加/删除字段，s 切换排序字段）；F 进入字段列显示顺序排序界面(选中一行上下切换即可)
        f,F,X     Fields: 'f'/'F' add/remove/order/sort; 'X' increase fixed-width

        # 定位配置：L 查找字符串, & 查找下一个; <,> 切换排序列
        L,&,<,> . Locate: 'L'/'&' find/again; Move sort column: '<'/'>' left/right
        # 切换配置：R切换排序； H 显示线程视图；V 显示父子进程树
        R,H,V,J . Toggle: 'R' Sort; 'H' Threads; 'V' Forest view; 'J' Num justify
        # c 显示Command详细命令
        c,i,S,j . Toggle: 'c' Cmd name/line; 'i' Idle; 'S' Time; 'j' Str justify
        # x,y 高亮显示排序列和运行行
        x,y     . Toggle highlights: 'x' sort field; 'y' running tasks
        # 当使用x,y时，同z改变字体颜色，b改变背景
        z,b     . Toggle: 'z' color/mono; 'b' bold/reverse (only if 'x' or 'y')
        # 过滤：o/O 增加过滤项（其中O区分大小写。如输入 COMMAND=java 表示COMMAND含java字符串的，或 !PID=100 表示PID不含100的，或 %CPU>5.0，回车即可应用过滤条件）
        u,U,o,O . Filter by: 'u'/'U' effective/any user; 'o'/'O' other criteria
        # Ctrl+O 展示过滤条件；top界面输入 = 即可清除所有过滤条件
        n,\#,^O  . Set: 'n'/'#' max tasks displayed; Show: Ctrl+'O' other filter(s)
        # 显示成滚动窗口，在通过上下左右键/home/end移动
        C,...   . Toggle scroll coordinates msg for: up,down,left,right,home,end
        
        # 管理进程：k 杀死某个进程；r 重设优先级
        k,r       Manipulate tasks: 'k' kill; 'r' renice
        # 设置数据更新频率，默认3秒
        d or s    Set update interval
        W,Y       Write configuration file 'W'; Inspect other output 'Y'
        q         Quit
                ( commands shown with '.' require a visible task display window ) 
    Press 'h' or '?' for help with Windows,
    Type 'q' or <Esc> to continue

    # 其他快捷键
    M # 按照内存排序
    N # 按照PID排序
    V # 排序反转
    0 # 隐藏Time为0的数据
    1 # 显示CPU所有核心的信息
    2 # 显示NUMA信息
    ```

### 查看IO信息(磁盘读写情况)

- 参考：https://www.cnblogs.com/quixotic/p/3258730.html [^12]

#### 系统级IO监控

- 基于`top`查看
    - top面板的`%Cpu`展示栏中的 wa 的百分比数值可以大致的体现出当前的磁盘io请求是否频繁。如果 wa 较大，说明等待输入输出的的io比较多，如 75 wa表示75%的IO等待
- 基于`vmstat`
    - vmstat是Virtual Meomory Statistics(虚拟内存统计，Swap Space)的缩写，可对操作系统的虚拟内存、进程、CPU活动进行监控。是对系统的整体情况进行统计，不足之处是无法对某个进程进行深入分析
    - `vmstat 5 5` 在5秒时间内进行5次采样
    - 字段说明
        - Procs(进程)：r:运行队列中进程数量，b:等待IO的进程数量
        - Memory(内存)：swpd:使用虚拟内存大小，free:可用内存大小，buff:用作缓冲的内存大小，cache:用作缓存的内存大小
        - Swap：si:每秒从交换区写到内存的大小，so:每秒写入交换区的内存大小
        - IO(单位1kb)：bi:每秒读取的块数，bo:每秒写入的块数
        - System：in: 每秒中断数(包括时钟中断)，cs: 每秒上下文切换数
        - CPU(%)： us:用户进程执行时间(user time)；sy:系统进程执行时间(system time)；id:空闲时间(包括IO等待时间)，中央处理器的空闲时间，以百分比表示；wa:等待IO时间
    - 状态说明
        - 如果r经常大于4，id经常少于40，表示cpu的负荷很重
        - 如果bi，bo长期不等于0，表示内存不足
        - 如果disk经常不等于0，且在b中的队列大于3，表示io性能不好
- 基于iostat查看
    - 安装iostat `yum install sysstat`(iostat属于sysstat软件包)
    - `iostat -xdm 1`
        - -x输出扩展信息；-d仅显示磁盘统计信息(与-c仅显示CPU信息互斥)；-m显示磁盘读写速度单位为MB(默认为KB，影响rMB/s、wMB/s选项)；1秒统计一次
        - 显示结果含义如下
            - `r/s`、`w/s` 每秒的读操作和写操作，磁盘读写速度
            - `rKB/s`、`wKB/s` 每秒读和写的数据量(KB为单位)，对应的有rMB/s、wMB/s
                - 如果r/s、w/s，rKB/s、wKB/s这两对数据值都很高的话说明磁盘io操作是很频繁
            - `avgrq-sz` 提交给驱动层的IO请求大小，一般不小于4K，不大于max(readahead_kb, max_sectors_kb)。可用于判断尤其是磁盘繁忙时，越大代表顺序读，越小代表随机读
            - **`%util`** 代表磁盘繁忙程度。100% 表示磁盘繁忙，0%表示磁盘空闲。但是磁盘繁忙不代表磁盘利用率高(重要指标)
            - **`svctm`** 一次IO请求的服务时间，对于单块盘，完全随机读时基本在7ms左右，既寻道+旋转延迟时间(重要指标)

#### 进程级IO监控

- 安装iotop `yum install iotop`(io版的top)
- `iotop` 命令可直接运行，界面操作快捷键如下
    - 左右箭头：改变排序方式，默认是按IO排序
    - r：改变排序顺序
    - o：只显示有IO输出的进程
    - p：进程/线程的显示方式的切换
    - a：显示累积使用量
    - q：退出
- `iotop -p <pid>` 单独监控此进程

#### 业务级IO监控

- `pt-ioprofile` **不建议在生产环境使用**

### 其他

- https://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/index.html
- `pstack` 跟踪进程栈
- `strace` 跟踪进程中的系统调用(软中断)
    - `yum -y install strace`
    - `strace -ff -o out java HelloWorld` 将跟踪日志写入到out文件中
- `top` linux下的任务管理器

## 内核

### sysctl

- `sysctl`命令被用于在内核运行时动态地修改内核的运行参数，可用的内核参数在目录`/proc/sys`中
- 命令

```bash
sysctl [options] [variable[=value] ...]
# sysctl变量的设置通常是字符串、数字或者布尔型(1/0)

# 打印当前所有可用的内核参数变量和值
sysctl -a

# 修改参数值(临时修改)
sysctl -w vm.dirty_background_ratio=5
# 执行一次或多次`-w`后需要通过`-p`持久化(使生效)
sysctl -p
```
- 配置sysctl(永久修改)

```bash
vi /etc/sysctl.conf
# 使生效
/sbin/sysctl -p
```
- 参数说明

```bash
## sysctl -a | grep dirty # 缓存相关
# vm.dirty_background_ratio 是内存可以填充“脏数据”的百分比。这些“脏数据”在稍后是会写入磁盘的，pdflush/flush/kdmflush这些后台进程会稍后清理脏数据。举一个例子，我有32G内存，那么有3.2G的内存可以待着内存里，超过3.2G的话就会有后来进程来清理它
vm.dirty_background_ratio = 10
vm.dirty_background_bytes = 0
# vm.dirty_ratio 是绝对的脏数据限制，内存里的脏数据百分比不能超过这个值。如果脏数据超过这个数量，新的IO请求将会被阻挡，直到脏数据被写进磁盘。这是造成IO卡顿的重要原因，但这也是保证内存中不会存在过量脏数据的保护机制。对于将这些数据刷新到磁盘，默认时间限制为120秒，如果超时可能会报错 `INFO: task xxx blocked for more than 120 seconds`，进而导致系统不可用(https://www.blackmoreops.com/2014/09/22/linux-kernel-panic-issue-fix-hung_task_timeout_secs-blocked-120-seconds-problem/)
vm.dirty_ratio = 20
vm.dirty_bytes = 0
# vm.dirty_expire_centisecs 指定脏数据能存活的时间。在这里它的值是30秒。当 pdflush/flush/kdmflush 进行起来时，它会检查是否有数据超过这个时限，如果有则会把它异步地写到磁盘中。毕竟数据在内存里待太久也会有丢失风险
vm.dirty_expire_centisecs = 3000
# vm.dirty_writeback_centisecs 指定多长时间 pdflush/flush/kdmflush 这些进程会起来一次
vm.dirty_writeback_centisecs = 500
```

## Linux基础

### 基本

- Linux是基于Unix的，其内核是开源的。redhat、centos、ubuntu都是基于linux内核将一些小程序组装到一起的linux发行套件
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
        - `/var/log`目录下其他日志文件，详细参考：https://www.cnblogs.com/kaishirenshi/p/7724963.html
            - `dmesg` 包含内核缓冲信息（kernel ringbuffer）。在系统启动时，会在屏幕上显示许多与硬件有关的信息。可以用dmesg查看
            - `auth.log` 包含系统授权信息，包括用户登录和使用的权限机制等
            - `daemon.log` 包含各种系统后台守护进程日志信息
            - `kern.log` 包含内核产生的日志，有助于在定制内核时解决问题
            - `yum.log` 包含使用yum安装的软件包信息
            - `cron` 每当cron进程开始一个工作时，就会将相关信息记录在这个文件中
            - `secure` 包含验证和授权方面信息。例如，sshd会将所有信息记录（其中包括失败登录）在这里
            - `btmp` 记录所有失败登录信息。使用last命令可以查看btmp文件（centos7）
            - `faillog` 包含用户登录失败信息。此外，错误登录命令也会记录在本文件中
            - `wtmp`或`utmp` 包含登录信息。使用wtmp可以找出谁正在登陆进入系统，谁使用命令显示这个文件或信息等
            - `maillog`和`mail.log` 包含来着系统运行电子邮件服务器的日志信息。例如，sendmail日志信息就全部送到这个文件
            - `anaconda/` 在安装Linux时，所有安装信息都储存在这个文件中
            - `mail/` 这个子目录包含邮件服务器的额外日志
    - `/usr` 用户目录。系统级的目录，可以理解为C:/Windows/，/usr/lib理解为C:/Windows/System32
        - `/local` **一般为安装软件目录**，源码编译安装一般在`/usr/local/lib`目录下。用户级的程序目录，可以理解为C:/Progrem Files/，用户自己编译的软件默认会安装到这个目录下
        - `src` 系统级的源码目录
        - `/local/src`：用户级的源码目录
    - `/opt` **标识可选择的意思，一些软件包也会安装在这里，也就是自定义软件包**。用户级的程序目录，可以理解为D:/Software，opt有可选的意思，这里可以用于放置第三方大型软件（或游戏），当不需要时，直接rm -rf掉即可。在硬盘容量不够时，也可将/opt单独挂载到其他磁盘上使用

### 相关文件

- `/etc/profile` 系统环境信息，如环境变量，对所有用户生效；当用户第一次登录时，该文件被执行。并从 `/etc/profile.d` 目录的配置文件中收集 shell 的设置。对 /etc/profile 有修改的话必须得 source 一下修改才会生效(如果第二次登录仍然不生效可考虑重启一下系统，当系统不能重启时，可考虑将设置添加到`/etc/bashrc`)
- `/etc/bashrc` 当 bash shell 被打开时，该文件被读取执行，对所有用户生效。修改文件后，重新打开一个 bash 即可生效
- `~/.bash_profile` 当用户登录时，文件仅仅执行一次，对当前用户生效(有时候修改了此文件，不想重新登录，可通过source执行一下此文件使其生效)。默认情况下，为了设置一些环境变量，和**执行用户的 `~/.bashrc` 文件**
- `~/.bashrc` 对当前登录用户生效，每次打开 bash shell 时生效，**默认调用了`/etc/bashrc`**
- `~/.bash_logout` 当每次退出系统(退出 bash shell)时，执行该文件
- `/etc/environment` 设置环境变量。/etc/profile > /etc/environment > ~/.bash_profile

### 网络

参考 [《网络》http://blog.aezo.cn/2019/06/20/linux/network/](/_posts/linux/network.md#Linux网络)

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
[^12]: https://www.cnblogs.com/quixotic/p/3258730.html (Linux下的IO监控与分析)
[^13]: https://www.cnblogs.com/cidgur/p/9447847.html

