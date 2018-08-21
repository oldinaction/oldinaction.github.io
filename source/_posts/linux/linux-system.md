---
layout: "post"
title: "linux系统命令"
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
- 查看CentOS版本 `cat /etc/redhat-release`/`cat /etc/system-release` 如：CentOS Linux release 7.2.1511 (Core)
- `hostname` 查看hostname
    - `hostnamectl set-hostname aezocn` 修改主机名并重启
- `grep MemTotal /proc/meminfo` 查看内存
- `df -hl` 查看磁盘使用情况

### 查看网络信息

- `ip addr`或`ifconfig` 查看内网ip
    - 显示说明
        - `lo`为内部网卡接口，不对外进行广播。`eth0`/`ens33`网卡接口会对外广播
        - `link/ether 00:0c:29:bb:ea:e2`中link/ether后为`mac`地址
        - `inet 192.168.6.130/24 brd 192.168.6.255 scope global ens33`中192.168.6.130/24为内网ip和子网掩码(24代表32位中有24个1其他都是0，即255.255.255.0) `brd`(broadcast)后为广播地址
    - `ifconfig`命令(centos7无法使用解决方案参考《CentOS服务器使用指导》)
        - `ifconfig ens33:1 192.168.6.10` 给网络接口ens33绑定一个虚拟ip
        - `ifconfig ens33:1 down` 删除此虚拟ip
        - 添加虚拟ip方式二
            - 编辑类似文件`vi /etc/sysconfig/network-scripts/ifcfg-ens33`
            - 加入代码`IPADDR=192.168.6.130`(本机ip)和`IPADDR1=192.168.6.135`(添加的虚拟ip，可添加多个。删除虚拟ip则去掉IPADDR1)，可永久生效
            - 重启网卡`systemctl restart network`
            - 修改ip即修改上述`IPADDR`
- `ping 192.168.1.1`(或者`ping www.baidu.com`) 检查网络连接
- `telnet 192.168.1.1 8080` 检查端口
- `curl http://www.baidu.com`或`wget http://www.baidu.com` 检查是否可以上网，成功会显示或下载一个对应的网页
    - wget爬取网站：`wget -o /tmp/wget.log -P /home/data --no-parent --no-verbose -m -D www.qq.com -N --convert-links --random-wait -A html,HTML http://www.qq.com`
- `netstat -lnp` 查看端口占用情况(端口、PID)
    - `ss -ant` CentOS 7 查看所有监听端口
    - root运行：`sudo netstat -lnp` 可查看使用root权限运行的进程PID(否则PID隐藏)
    - `netstat -tnl` 查看开放的端口
    - `netstat -lnp | grep tomcat` 查看含有tomcat相关的进程
    - **`yum install net-tools`** 安装net-tools即可使用netstat、ifconfig等命令

## 查看进程信息

- **`ps -ef | grep java`**(其中java可换成run.py等)
    - 结果如：`root   23672 22596  0 20:36 pts/1    00:00:02 python -u main.py`. 运行用户、进程id、...
- `ls -al /proc/进程id` 查看此进程信息
    - `cwd`符号链接的是进程运行目录 **`ls -al /proc/8888 | grep cwd`**
    - `exe`符号连接就是执行程序的绝对路径
    - `cmdline`就是程序运行时输入的命令行命令
    - `environ`记录了进程运行时的环境变量
    - `fd`目录下是进程打开或使用的文件的符号连接
- 自带程序`top`查看, 推荐安装功能更强大的`htop`
  
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
        - `&` 最后面的&表示放在后台执行
        - `startofbiz.sh > my.log` 表示startofbiz.sh的输出重定向到my.log
        - `2>&1` 表示将错误输出重定向到标准输出
            - `0`：标准输入；`1`：标准输出；`2`：错误输出
- 设置环境变量
    - `/etc/profile` 记录系统环境变量，在此文件末尾加入`export JAVA_HOME=/usr/java/jdk1.8` 将`JAVA_HOME`设置成所有用户可访问
    - `/home/smalle/.bash_profile` 每个用户登录的环境变量(/home/smalle为用户家目录)
        - `.bash_profile` 登录后的环境变量
        - `.bashrc` 登录后自动运行(类似rc.local)
    - `echo $JAVA_HOME` 查看其值
    - 设置临时环境变量：在命令行运行`export JAVA_HOME=/usr/java/jdk1.8`(重新打开命令行则失效)
    
### 服务相关命令

- **自定义服务参考[《nginx.md》(基于编译安装tengine)](/_posts/arch/nginx.md#基于编译安装tengine)**
- systemctl：主要负责控制systemd系统和服务管理器，是`chkconfig`和`service`的合并(systemctl管理的脚本文件目录为**`/usr/lib/systemd/system`**或**/etc/systemd/system**)
    - `systemctl start|status|restart|stop nginx.service` 启动|状态|重启|停止服务(.service可省略，active (running)标识正在运行)
    - `systemctl list-units --type=service` 查看所有服务
        - `systemctl list-unit-files` 查看所有可用单元
    - `systemctl enable nginx` 设置开机启动
    - `systemctl disable nginx` 停止开机启动
    - `systemctl cat sshd` 查看服务的配置文件
    - **`tail -f /var/log/messages`** 查看服务启动日志
- chkconfig：提供了一个维护`/etc/rc[0~6]d/init.d`文件夹的命令行工具
    - `chkconfig --list <nginx>` 查看(nginx)服务列表
    - `chkconfig --add nginx` 将nginx加入到服务列表(需要**`/etc/rc.d/init.d`**下有相关文件nginx.service)
    - `chkconfig --del nginx` 关闭指定的服务程序
    - `chkconfig nginx on` 设置nginx服务开机自启动
- service：`service nginx start|stop|reload` 服务启动等命令

### 常用语法参考《shell.md》

### 常用命令

- `ls --help` 查看ls的命令说明(或`help ls`)
- `man ls` 查看ls的详细命令说明
- `clear` 清屏
- `\` 回车后可将命令分多行运行
- `date` 显示当前时间; `cal` 显示日历
- `last` 查看最近登录用户
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

- `df -h` 查看磁盘使用情况、分区、挂载点
    - `df -h /home/smalle` 查询目录使用情况、分区、挂载点
    - `df -Th` 查询文件系统格式
- `du -sh /home/smalle | sort -n` 查看目录下文件大小，并按大小排列
- 查看数据盘 `fdisk -l`(如：Disk：/dev/vda ... Disk：/dev/vdb表示有两块磁盘)
- 格式化磁盘 `mkfs.ext4 /dev/vdb` (一般云服务器买的磁盘未进行格式化文件系统和挂载)
- 挂载磁盘 `mount /dev/vdb /home/` 挂载磁盘到`/home`目录
- 修改fstab以便系统启动时自动挂载磁盘 `echo '/dev/vdb  /home ext4    defaults    0  0' >> /etc/fstab` 重新挂载了磁盘需要重启(`reboot`)

### 文件

- `cat <fileName>` 查看文件
    - `more` 分页显示文件内容(按空格分页)
        - 向后翻一屏：`SPACE`；向前翻一屏：`b`；向后翻一行：`ENTER`；向前翻一行：`k`
    - `less` 查看文件前几行(一行行的显示)
    - `tac` 从文末开始显示文件内容(cat反正写)
    - `head -3` 显示文件头部的3行
    - `tail -3` 显示文件末尾的3行
        - `tail -f /var/log/messages` -f 表示它将会以一定的时间实时追踪该档的所有更新（查看服务启动日志）
- `pwd` 查看当前目录完整路径
- `sudo find / -name nginx.conf` 查询文件位置(查看`nginx.conf`文件所在位置)
- `whereis <binName>` 查询可执行文件位置
    - `which <exeName>` 查询可执行文件位置 (在PATH路径中寻找)
    - `echo $PATH` 打印环境变量
- `stat <file>` 查看文件的详细信息
- `file <fileName>` 查看文件属性
- `wc <file>` 统计指定文本文件的行数、字数、字节数 
    - `wc -l <file>` 查看行数
- `ln my.txt my` 创建连接(硬链接，在当前目录为my.txt创建一个my的文件并将这两个文件关联起来)
    - `ln -s my.txt mys` 创建软链接(相当于快捷方式)
    - 修改原文件，硬链接对应的文件也会改变。删除原文件，硬链接对应的文件不会删除
- 下载文件到本地(windows): `sz 文件名` （需要安装`yum install lrzsz`）
- `ls` 列举文件 [^3]
    - `ll` 列举文件详细
        - **`ll test*`**/`ls *.txt` 模糊查询文件
        - **`ll -rt *.txt`** 按时间排序 (`-r`表示逆序、`-t`按时间排序)
        - **`ll -Sh`** 按文件大小排序 (`-S`按文件大小排序、`-h`将文件大小按1024进行转换显示M/G等)
    - `ls -al` 列举所有文件详细(`-a`全部、`-l`纵向显示. linux中`.`开头的文件默认为隐藏文件)
    > 文件详细如下图
    >
    > ![文件详细](/data/images/2017/02/文件详细.gif)
    >
    > 类型与权限如下图
    >
    > ![类型与权限](/data/images/2017/02/类型与权限.gif)
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
    - 复制文件到远程服务器：`scp /home/test root@192.168.1.1:/home` 将本地linux系统的test文件或者文件夹复制到远程的home目录下
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

#### rar

- 解压：**`tar -xzvf archive.tar -C /tmp`** 解压tar包，将gzip压缩包释放到 /tmp目录下(tar不存在乱码问题)
- 压缩：**`tar -czvf aezocn.tar.gz file1 file2 *.jpg dir1`** 将此目录所有jpg文件和dir1目录打包成aezocn.tar后，并且将其用gzip压缩，生成一个gzip压缩过的包，命名为aezocn.tar.gz(体积会小很多：1/10). windows可使用7-zip
- 参数说明
    - 独立命令，压缩解压都要用到其中一个，可以和别的命令连用但只能用其中一个
        - **`-c`**: 建立压缩档案
        - **`-x`**：解压
        - `-t`：查看 tarfile 里面的文件
        - `-r`：向压缩归档文件末尾追加文件
        - `-u`：更新原压缩包中的文件
    - 必须
        - **`-f`**：使用档案名字，**切记这个参数是最后一个参数，后面只能接档案名**
    - 解/压缩类型(可选)
        - `-z`：有gzip属性的(archive.tar.gz)
        - `-j`：有bz2属性的(archive.tar.bz2)
        - `-Z`：有compress属性的(archive.tar.Z)
    - 其他可选
        - **`-v`**：显示所有过程
        - `-O`：将文件解开到标准输出    
        - `-p` 使用原文件的原来属性（属性不会依据使用者而变）
        - `-P` 可以使用绝对路径来压缩

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

- `vi/vim my.txt` 打开编辑界面(总共两种模式，默认是命令模式；无此文件最终保存后会自动新建此文件)
    - `insert` 进入编辑模式；`esc`退出编辑模式(进入命令模式)
- 打开文件
    - `vi +5 <file>` 打开文件，并定位于第5行 
    - `vi + <file>` 打开文件，定位至最后一行
    - `vi +/<pattern> <file>` 打开文件，定位至第一次被pattern匹配到的行的行，按字母`n`查找下一个

### vi命令
    
- 关闭文件
    - `:wq`/`:x` 保存并退出
    - `:q!` 不保存退出
    - 编辑模式下输入大写`ZZ`保存退出
- 关标移动
    - `h` 左
    - `j` 下
    - `k` 上
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
    - `dd` 删除光标所在行
    - `#dd` 删除光标以下#行
    - `dw` 删除一个单词
    - `.,.+2d` 删除从之前关标所在行到关标所在行的下两行(`.` 表示当前行；`$` 最后一行；`+#` 向下的#行；`-#` 向上的#行)
    - `x` 删除光标所在处的单个字符
    - `#x` 删除光标所在处及向后的共#个字符
- 新加一行 `o`
- 复制命令 `y`(用法同`d`命令，和粘贴命令`p`组合使用)
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
    - `u` 撤销上一步操作
    - `Ctrl+r` 恢复上一步被撤销的操作
    - `Ctrl+v` 进入列编辑模式
- 行号
    - `set number`/`set nu` 显示行号
    - `set nonu` 不显示行号
    - 永久显示行号：在`/etc/virc`或`/etc/vimrc`中加入一行`set nu`
- 批量注释
    - `Ctrl+v` 进入列编辑模式，在需要注释处移动光标选中需要注释的行
    - `Shift+i`
    - 再插入注释符，比如按`//`或者`#`
    - 按`Esc`即可全部注释
- 批量删除注释：`ctrl+v`进入列编辑模式，横向选中列的个数(如"//"注释符号需要选中两列)，然后按`d`就会删除注释符号
- 根shell交互：`:! COMMAND` 在命令模式下执行外部命令，如mkdir

## linux三剑客grep、sed、awk语法

### grep过滤器

- 在多个文件中查找数据(查询文件内容)
    - `grep "search content" filename1 filename2.... filenamen`
    - `grep "search content" *.sql`

### sed行编辑器

- 文本处理，默认不编辑原文件，仅对模式空间中的数据做处理；而后处理结束后将模式空间打印至屏幕
- 语法 `sed [options] '内部命令表达式' file ...`
- 参数
    - `-n` 静默模式，不再默认显示模式空间中的内容
	- `-i` 直接修改原文件
	- `-e SCRIPT -e SCRIPT` 可以同时执行多个脚本
	- `-f` /PATH/TO/SED_SCRIPT
	    - sed -f /path/to/scripts  file
	- `-r` 表示使用扩展正则表达式
	
- 内部命令
	- `d` 删除符合条件的行
	- `p` 显示符合条件的行
	- `a \string`: 在指定的行后面追加新行，内容为string
		- `\n` 可以用于换行
	- `i \string`: 在指定的行前面添加新行，内容为string
	- `r FILE` 将指定的文件的内容添加至符合条件的行处
	- `w FILE` 将地址指定的范围内的行另存至指定的文件中
	- `s/pattern/string/修饰符`  查找并替换，默认只替换每行中第一次被模式匹配到的字符串。修饰符`g` 全局替换；`i` 忽略字符大小写	
	- `&` 引用模式匹配整个串
- 示例
    - 删除/etc/grub.conf文件中行首的空白符：`sed -r 's@^[[:space:]]+@@g' /etc/grub.conf`
    - 替换/etc/inittab文件中"id:3:initdefault:"一行中的数字为5：`sed 's@\(id:\)[0-9]\(:initdefault:\)@\15\2@g' /etc/inittab`
    - 删除/etc/inittab文件中的空白行：`sed '/^$/d' /etc/inittab`

### awk文本分析工具

- 相对于grep的查找，sed的编辑，awk在其对数据分析并生成报告时，显得尤为强大。简单来说awk就是把文件逐行的读入，**以空格为默认分隔符将每行切片**，切开的部分再进行各种分析处理
- 语法 `awk '{pattern + action}' {commands}`
	- 其中 pattern 表示 AWK 在数据中查找的内容，而 action 是在找到匹配内容时所执行的一系列命令
	- 花括号（{}）不需要在程序中始终出现，但它们用于根据特定的模式对一系列指令进行分组
	- pattern就是要表示的正则表达式，用斜杠括起来
- 案例
    - 显示最近登录的5个帐号：`last -n 5 | awk  '{print $1}'`
        - 读入有'\n'换行符分割的一条记录，然后将记录按指定的域分隔符划分域，填充域。$0则表示所有域,$1表示第一个域,$n表示第n个域。默认域分隔符是"空白键" 或 "[tab]键",所以$1表示登录用户，$3表示登录用户ip,以此类推。
    - 只是显示/etc/passwd中的账户：`cat /etc/passwd |awk  -F ':'  '{print $1}'`(-F指定域分隔符为':')
    - 查找root开头的用户记录: `awk -F: '/^root/' /etc/passwd`
- `$0`变量是指整条记录，`$1`表示当前行的第一个域，`$2`表示当前行的第二个域，以此类推
- awk中同时提供了print和printf两种打印输出的函数：
    - print函数的参数可以是变量、数值或者字符串。字符串必须用双引号引用，参数用逗号分隔。如果没有逗号，参数就串联在一起而无法区分。
    - printf函数，其用法和c语言中printf基本相似，可以格式化字符串，输出复杂时。
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
    - 下面统计/etc/passwd的账户人数：`awk '{count++;print $0;} END{print "user count is ", count /etc/passwd`

        ```txt
        root:x:0:0:root:/root:/bin/bash
        ......
        user count is  40
        ```
    - count是自定义变量。之前的action{}里都是只有一个print，其实print只是一个语句，而action{}可以有多个语句，以;号隔开。这里没有初始化count，虽然默认是0，但是妥当的做法还是初始化为0。
- 提供`BEGIN/END`语句
    - 统计某个文件夹下的文件占用的字节数，过滤4096大小的文件(一般都是文件夹):`ls -l |awk 'BEGIN {size=0;print "[start]size is ", size} {if($5!=4096){size=size+$5;}} END{print "[end]size is ", size/1024/1024,"M"}'` (打印如[end]size is  8.22339 M)
- 支持if判断、循环等语句

## 权限系统

### 用户 [^6]

- `useradd test` 新建test用户(默认在/home目录新建test对应的家目录test)
    - `useradd -d /home/aezo -m aezo` 添加用户(和设置宿主目录)
    - `usermod -d /home/home_dir -U aezo` 修改用户宿主目录
- `userdel -rf aezo` 删除用户(不会删除对应的家目录)
- `passwd aezo` 设置密码
- `id smalle` 查看smalle用户信息
- `cat /etc/passwd` 查看用户
    - 如`smalle:x:1000:1000:aezocn:/home/smalle:/bin/bash`
- `who` 显示当前登录用户
- `su test` 切换到test用户
- `groupadd aezocn` 新建组
- `groupdel aezocn` 删除组

### 文件

- 文件属性`chgrp`、`chown`、`chmod`、`umask` [^3]
- `chgrp` 改变文件所属群组。`chgrp [-R] 组名 文件或目录`
    - `-R` 递归设置子目录下所有文件和目录
- `chown` 改变文件/目录拥有者。如：`chown [-R] aezo /home/aezo`
- `chmod` 改变文件的权限(文件权限说明参考上述`ls -al`)
    - 数字类型改变文件权限 **`chmod [-R] xyzw 文件或目录`** 如：`chmod -R 755 /home/ftproot`
        - `x`：可有可无，代表的是特殊权限,即 SUID/SGID/SBIT。`yzw`：就是刚刚提到的数字类型的权限属性，为 rwx 属性数值的相加
        - 各权限的分数对照表为：`r:4、w:2、x:1、SUID:4、SGID:2、SBIT:1`。如rwx = 4+2+1 = 7，r-s = 4+1 = 5
    - 符号类型改变文件权限 `chmod 对象 操作符 文件/目录`
        - 对象取值为`ugoa`：u=user, g=group, o=others, a=all
        - 操作符取值为：`+-=`：+ 为增加，- 为除去，= 为设定
        - 如：`chmod u=rwx,go=rx test`、`chmod g+s,o+t test`
- `umask` 创建文件时的默认权限
    - `umask` 查看umask分数值。如0022(一般umask分数值指后面三个数字)
        - `umask -S` 查看umask。如u=rwx,g=rx,o=rx
    - 系统默认新建文件的权限为666(3个rw)，文件夹为777(3个rwx)。最终新建文件的默认权限为系统默认权限减去umask分数值。如umask为002，新建的文件为-rw-r--r--，文件夹为drw-r-xr-x
- 常用命令
    - `find . -type d -exec chmod 755 {} \;` 修改当前目录的所有目录为775
    - `find . -type f -exec chmod 644 {} \;` 修改当前目录的所有文件为644

## ssh [^2]

### ssh介绍

1. SSH是建立在传输层和应用层上面的一种安全的传输协议。SSH目前较为可靠，专为远程登录和其他网络提供的安全协议。在主机远程登录的过程中有两种认证方式：
    - `基于口令认证`：只要你知道自己帐号和口令，就可以登录到远程主机。所有传输的数据都会被加密，但是不能保证你正在连接的服务器就是你想连接的服务器。可能会有别的服务器在冒充真正的服务器，也就是受到“中间人”这种方式的攻击。
    - `基于秘钥认证`：需要依靠秘钥，也就是你必须为自己创建一对秘钥，并把公用的秘钥放到你要访问的服务器上，客户端软件就会向服务器发出请求，请求用你的秘钥进行安全验证。服务器收到请求之后，现在该服务器你的主目录下寻找你的公用秘钥，然后吧它和你发送过来的公用秘钥进行比较。弱两个秘钥一致服务器就用公用秘钥加密“质询”并把它发送给客户端软件，客户端软件收到质询之后，就可以用你的私人秘钥进行解密再把它发送给服务器。
2. 用基于秘钥认证，你必须要知道自己的秘钥口令。但是与第一种级别相比，这种不需要再网络上传输口令。第二种级别不仅加密所有传送的数据，而且“中间人”这种攻击方式也是不可能的（因为他没有你的私人密匙）。但是整个登录的过程可能需要10秒。

### 查看SSH服务

CentOS 7.1安装完之后默认已经启动了ssh服务我们可以通过以下命令来查看ssh服务是否启动

1. 查看开放的端口 `netstat -tnl` ssh默认端口为22
2. 查看服务是否启动 `systemctl status sshd.service` 查看ssh服务是否启动

### SSH客户端连接服务器（口令认证）

1. 直接连接到对方的主机，这样登录服务器的默认用户
    - `ssh 192.168.1.1` 回车输入密码即可
    - `exit` 退出登录
2. 使用账号登录对方主机aezocn用户
    - `ssh aezocn@192.168.1.1`

### SSH客户端连接服务器（秘钥认证）

**客户端(可能也是一台服务器)需要连接服务器，则需要将某个公钥`id_rsa.pub`写入到服务器的`~/.ssh/authorized_keys`文件中**
    - 此公钥可以是客户端、服务器端或其他地方生成的公钥数据
    - 如果命令行连接服务器，则需要此公钥无需再客户端保存
    - 客户端登录成功后会将服务器ip及登录的公钥加入到`known_hosts`文件中(没有此文件时会自动新建)

1. 命令行生成
    - 生成公钥(.pub)和私钥(.ppk)
        - **`ssh-keygen`** 运行命令后再按三次回车会看到`RSA`（生成的秘钥文件默认路径为家目录下的`.ssh`，如`/home/smalle/.ssh/`，会包括`id_rsa`(密钥)、`id_rsa.pub`(公钥)、`known_hosts` 3 个文件）
            - `ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa`
    - 把生成的公钥发送到对方的主机上去（在本地为服务器生成公钥）
        - `ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.1.1` （自动保存在对方主机的`/root/.ssh/authorized_keys`文件中去）
        - 输入该服务器密码实现发送
    - 登录该服务器：`ssh 192.168.1.1` 此时不需要输入密码（默认生成密钥的服务器已经有了私钥）
    - **注：** 如果是为了让root用户登录则将公钥放入到/root/.ssh目录；如果密钥提供给其他用户登录，可将公钥放在对应的家目录，如/home/aezo/.ssh/下。`.ssh`目录默认已经存在（可通过`ll -al`查看）
	- 阿里云服务器root用户的authorized_keys和普通用户的不能一致 [^5]
2. Putty/WinSCP 和 xshell/xftp
    - Putty是一个Telnet、SSH、rlogin、纯TCP以及串行接口连接软件。它包含Puttygen等工具，Puttygen可用于生成公钥和密钥（还可以将如AWS亚马逊云的密钥文件.pem转换为.ppk的通用密钥文件）
        - 在知道密钥文件时，可以通过Putty连接到服务器(命令行)，通过WinSCP连接到服务器的文件系统(FTP形式显示)
        - Puttygen使用：`类型选择RSA，大小2048` - `点击生成` - `鼠标在空白处滑动` - `保存公钥和密钥`
        - Putty使用：`Session的Host Name输入username@ip，端口22` - `Connection-SSH-Auth选择密钥文件` - `回到Session，在save session输入一个会话名称` - `点击保存会话` - `点击open登录服务器` - `下次可直接点击会话名称登录`
    - xshell/xftp是一个连接ssh的客户端
        - 登录方法：连接 - 用户身份验证 - 方法选择"public key"公钥 - 用户名填入需要登录的用户 - 用户密钥可点击浏览生成(需要将生成的公钥保存到对应用户的.ssh目录`cat /home/aezo/.ssh/id_rsa.pub >> /home/aezo/.ssh/authorized_keys`)。必须使用自己生成的公钥和密钥，如果AWS亚马逊云转换后的ppk文件无法直接登录。
	- `cat /var/log/secure`查看登录日志
3. ssh配置 [^7]
    - `cat /etc/ssh/sshd_config` 查看配置
        - `PermitRootLogin no` 是否允许root用户登陆(no不允许)
        - `PasswordAuthentication no` 是否允许使用用户名密码登录(no不允许，此时只能使用证书登录)


## 定时任务 [^4]

### corn表达式

- 常用符号
    - `*` 表示所有值 
    - `?` 表示未说明的值，即不关心它为何值
    - `-` 表示一个指定的范围
    - `,` 表示附加一个可能值
    - `/` 符号前表示开始时间，符号后表示每次递增的值

### 配置说明

- 配置式
    - 添加定时配置：`sudo vim /etc/crontab`，配置说明如下，如：`30 2 1 * * root /sbin/reboot`表示每月第一天的第2个小时的第30分钟，使用root执行命令/sbin/reboot(重启)

        ```shell
        # Example of job definition:
        # .---------------- minute (0 - 59)，如 10 表示没第10分钟运行
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
    - `systemctl reload crond` 重新加载配置
    - `systemctl restart crond` 重启crond
- 命令式
    - `sudo crontab -e` 编辑当前用户的定时任务，默认在`/var/spool/`目录

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
        - `/init.d` 服务启动文件目录(脚本文件书写参考此目录下network文件)。是`/etc/rc.d/init.d`的symbolic link
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
        - `/local` 一般为安装软件目录，源码编译安装一般在`/usr/local/lib`目录下。用户级的程序目录，可以理解为C:/Progrem Files/，用户自己编译的软件默认会安装到这个目录下
        - `src` 系统级的源码目录
        - `/local/src`：用户级的源码目录
    - `/opt` 标识可选择的意思，一些软件包也会安装在这里，也就是自定义软件包。用户级的程序目录，可以理解为D:/Software，opt有可选的意思，这里可以用于放置第三方大型软件（或游戏），当不需要时，直接rm -rf掉即可。在硬盘容量不够时，也可将/opt单独挂载到其他磁盘上使用

### 系统启动顺序boot sequence

1. load bios(hardware information) 加电后检查hardware information
2. read MBR's cofing to find out the OS
3. load the kernel of the OS
4. init process starts...
5. execute /etc/rc.d/sysinit (rc.d为runlevel control directory)
6. start other modulers(etc/modules.conf) (启动内核外挂模块)
7. execute the run level scripts(如rc0.d、rc1.d等。启动只能配置成某一个级别)
    - 0 停机（千万不要把initdefault 设置为0）
    - 1 单用户模式
    - 2 多用户，但是没有 NFS
    - **3** 完全多用户模式(服务器常用)
    - 4 系统保留的
    - **5** X11(x window 桌面版)
    - 6 重新启动（千万不要把initdefault 设置为6）
8. execute `/etc/rc.d/rc.local` 自动启动某些程序，可基于此文件配置(或者`/etc/rc.local`，直接在里面添加启动命令)
9. execute /bin/login
10. shell started...



---

参考文章

[^1]: [文件压缩与解压](http://www.jb51.net/LINUXjishu/43356.html)
[^2]: [ssh登录](http://www.linuxidc.com/Linux/2016-03/129204.htm)
[^3]: [Linux文件属性](http://www.cnblogs.com/kzloser/articles/2673790.html)
[^4]: [定时任务](http://www.360doc.com/content/16/1013/10/15398874_598063092.shtml)
[^5]: [阿里云服务器ssh设置](https://www.douban.com/doulist/44111547/)
[^6]: [用户配置](http://www.cnblogs.com/zutbaz/p/4248845.html)
[^7]: [服务器安全ssh配置](https://www.xiaohui.com/dev/server/linux-centos-ssh-security.htm)
