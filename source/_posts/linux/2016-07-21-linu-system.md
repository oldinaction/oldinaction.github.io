---
layout: "post"
title: "linux系统命令"
date: "2016-07-21 19:19"
categories: linux
tags: [linux, shell]
---

* 目录
{:toc}

## 系统命令

- 查看系统信息
  - 查看操作系统版本 `cat /proc/version`
  > 如腾讯云服务器 `Linux version 3.10.0-327.36.3.el7.x86_64 (builder@kbuilder.dev.centos.org) (gcc version 4.8.5 20150623 (Red Hat 4.8.5-4) (GCC) ) #1 SMP Mon Oct 24 16:09:20 UTC 2016` 中的 `3.10.0` 表示内核版本 `x86_64` 表示是64位系统

  - 查看CentOS版本 `cat /etc/redhat-release` 如：CentOS Linux release 7.2.1511 (Core)
  - 查看内存 `grep MemTotal /proc/meminfo`

- 查看启动的服务(不包括系统的)：`chkconfig --list`
- `shutdown -r now` root登录可立刻重启
- `df -hl` 查看磁盘使用情况
- `netstat -lnp` 查看所有进场信息(端口、PID)
    - `ss -ant` CentOS 7 查看所有监听端口
    - `netstat -tnl` 查看开放的端口
    - `netstat -lnp | grep tomcat` 查看含有tomcat相关的进程
- 安装程序包 `rpm -ivh 安装包名`
- 查看安装程序(支持模糊查询) `rpm -qa | grep vsftpd` 查看是否安装vsftpd(一款ftp服务器软件)
- 检查网络连接 `ping 192.168.1.1`(或者`ping www.baidu.com`)，检查端口：`telnet 192.168.1.1 8080`
- 查看进程信息 `top`, 推荐安装功能更强大的htop
- 关闭某个PID进程 `kill PID`
    - `netstat -lnp` 查看所有进场信息(端口、PID)
    - 强制杀进程 `kill -s 9 PID`
- 运行sh文件：进入到该文件目录，运行`./xxx.sh`
- 脱机后台运行sh文件：`nohup bash startofbiz.sh > my.log 2>&1 &`
    - 可解决利用客户端连接服务器，执行的程序当客户端退出后，服务器的程序也停止了
    - `nohup`这个表示脱机执行，默认在当前目录生成一个`nohup.out`的日志文件
    - `&` 最后面的&表示放在后台执行
    - `startofbiz.sh > my.log` 表示startofbiz.sh的输出重定向到my.log
    - `2>&1` 表示将错误输出重定向到标准输出
        - `0`：键盘输入；`1`：标准输入；`2`：错误输出
- 查看内网ip `ip addr`

## 文件系统

### 磁盘

1. 查看磁盘使用情况 `df -hl`
2. 查看数据盘 `fdisk -l`(如：Disk：/dev/vda ... Disk：/dev/vdb表示有两块磁盘)
3. 格式化磁盘 `mkfs.ext4 /dev/vdb` (一般云服务器买的磁盘未进行格式化文件系统和挂载)
4. 挂载磁盘 `mount /dev/vdb /home/` 挂载磁盘到`/home`目录
5. 修改fstab以便系统启动时自动挂载磁盘 `echo '/dev/vdb  /home ext4    defaults    0  0' >> /etc/fstab` 重新挂载了磁盘需要重启(`reboot`)

### 文件

- `cat <fileName>` 查看文件
- `touch <fileName>` 新建文件
- `vi <fileName>` 编辑文件
    - `vim <fireName>` 编辑文件，有的可能默认没有安装vim
- `rm <file>` 删除文件
    - 提示 `rm: remove regular file 'test'?` 时，在后面输入 `yes` 回车
- `cp xxx.txt /usr/local/xxx` 复制文件(将xxx.txt移动到/usr/local/xxx)
    - 复制文件到远程服务器：`scp /home/test root@192.168.1.1:/home` 将本地linux系统的test文件或者文件夹复制到远程的home目录下
- 重命名文件或目录、将文件由一个目录移入另一个目录中
    - `mv a.txt b.txt` (将a.txt重命名为b.txt)
    - `mv a.txt /home/b.txt` 移动并重名名
- `ls` 列举文件 [^3]
    - `ll` 列举文件详细
        - `ls *.txt`、`ll test*` 模糊查询
        - `ll -rt *.txt` 按时间排序 (`-r`表示逆序、`-t`按时间排序)
        - `ll -Sh` 按文件大小排序 (`-S`按文件大小排序、`-h`将文件大小按1024进行转换显示)
    - `ls -al` 列举所有文件详细
    > 文件详细如下图
    >
    > ![文件详细](/data/images/2017/02/文件详细.gif)
    >
    > 类型与权限如下图
    >
    > ![类型与权限](//data/images/2017/02/类型与权限.gif)
    > - 第一个字符代表这个文件的类型(如目录、文件或链接文件等等)：
    >   - [ d ]则是目录、[ - ]则是文件、[ l ]则表示为连结档(link file)、[ b ]则表示为装置文件里面的可供储存的接口设备(可随机存取装置)、[ c ]则表示为装置文件里面的串行端口设备,例如键盘、鼠标(一次性读取装置)
    > - 接下来的字符中,以三个为一组,且均为『rwx』 的三个参数的组合< [ r ]代表可读(read)、[ w ]代表可写(write)、[ x ]代表可执行(execute) 要注意的是,这三个权限的位置不会改变,如果没有权限,就会出现减号[ - ]而已>
    >   - 第一组为『文件拥有者的权限』、第二组为『同群组的权限』、第三组为『其他非本群组的权限』
    >   - 当 s 标志出现在文件拥有者的 x 权限上时即为特殊权限。特殊权限如 SUID, SGID, SBIT

- `file <fileName>` 查看文件属性
- `whereis <fileName>` 查询文件
    - `which <exeName>` 查询可执行文件位置 (在PATH路径中寻找)
- `find / -name nginx.conf` 查询文件位置(查看`nginx.conf`文件所在位置)

### 文件夹/目录

1. 新建文件夹 **`mkdir [DirName]`** (或者用绝对路径 `mkdir /usr/local/DirName`)
2. 删除文件夹
  - 删除文件夹 `rmdir [DirName]` (如果文件夹不为空则无法删除)
  - 强制删除文件夹和其子文件夹 **`rm -rf [DirName]`**
  > -r 就是向下递归，不管有多少级目录，一并删除
  > -f 就是直接强行删除，不作任何提示的意思

3. 切换目录
  - 进入目录 **`cd` DirName**
  - 返回上一级目录 `cd ..`
  - 返回某一级目录 **`cd` /usr/local/xxx**
  - 返回根目录 `cd ~` 或者 `cd $HOME`

4. 查看当前目录绝对路径 `pwd`
5. 查看目录结构 `ls`
  - 查看目录结构包括隐藏文件 `ls -a`

### 压缩包(推荐tar) [^1]

1. 解压
    - `tar -xvf archive.tar` 解压tar包(tar不存在乱码问题)
        - 参数说明
            - 独立命令，压缩解压都要用到其中一个，可以和别的命令连用但只能用其中一个
                - `-c`: 建立压缩档案
                - `-x`：解压
                - `-t`：查看 tarfile 里面的文件
                - `-r`：向压缩归档文件末尾追加文件
                - `-u`：更新原压缩包中的文件
            - 必须
                - `-f`：使用档案名字，切记，这个参数是最后一个参数，后面只能接档案名
            - 可选
                - `-z`：有gzip属性的
                - `-j`：有bz2属性的
                - `-Z`：有compress属性的
                - `-v`：显示所有过程
                - `-O`：将文件解开到标准输出    
                - `-p` 使用原文件的原来属性（属性不会依据使用者而变）
                - `-P` 可以使用绝对路径来压缩        

        - 常用命令
            - `tar -xvf archive.tar -C /tmp` 将压缩包释放到 /tmp目录下
            - `tar -xzvf archive.tar.gz` 解压tar.gz
            - `tar -xjvf archive.tar.bz2` 解压tar.bz2
            - `tar -xZvf archive.tar.Z` 解压tar.Z
    - `unzip file.zip` 解压zip
    - `unrar e archive.rar` 解压rar
2. 压缩
    - **`tar -czf aezocn.tar.gz *.jpg dir1`** 将此目录所有jpg文件和dir1目录打包成aezocn.tar后，并且将其用gzip压缩，生成一个gzip压缩过的包，命名为aezocn.tar.gz(体积会小很多：1/10)
    - `tar -cvf aezocn.tar file1 file2 dir1` 同时压缩 file1, file2 以及目录 dir1。windows可使用7-zip
    - `tar -cvf aezocn.tar *.jpg` 将目录里所有jpg文件打包成aezocn.jpg
    - `tar -cjf aezocn.tar.bz2 *.jpg` 将目录里所有jpg文件打包成aezocn.tar后，并且将其用bzip2压缩，生成一个bzip2压缩过的包，命名为jpg.tar.bz2
    - `tar -cZf aezocn.tar.Z *.jpg` 将目录里所有jpg文件打包成aezocn.tar后，并且将其用compress压缩，生成一个umcompress压缩过的包，命名为jpg.tar.Z
    - `rar a aezocn.rar *.jpg` rar格式的压缩，需要先下载rar for linux
    - `zip aezocn.zip *.jpg` zip格式的压缩，需要先下载zip for linux
3. unzip乱码
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

4. rar安装问题，unzip乱码问题



## 权限系统

### 用户

1. 添加用户`useradd aezo –d /home/aezo/`
    - 修改用户宿主目录`usermod -d /home/home_dir -U aezo`
2. 设置密码`passwd aezo`
3. 查看用户`vi /etc/passwd`

### 文件

- 文件属性`chgrp`、`chown`、`chmod`、`umask` [^3]
    - `chgrp` 改变文件所属群组。`chgrp [-R] 组名 文件或目录`
        - `-R` 递归设置子目录下所有文件和目录
    - `chown` 改变文件/目录拥有者。如：`chown [-R] aezo /home/aezo`
    - `chmod` 改变文件的权限。
        - 数字类型改变文件权限 `chmod [-R] xyzw 文件或目录` 如：`chmod -R 755 /home/ftproot`
            - x : 可有可无,代表的是特殊权限,即 SUID/SGID/SBIT。yzw : 就是刚刚提到的数字类型的权限属性，为 rwx 属性数值的相加
            - 各权限的分数对照表为：r:4、w:2、x:1、SUID:4、SGID:2、SBIT:1。如rwx = 4+2+1 = 7，r-s = 4+1 = 5
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

1. 命令行生成
    - 生成公钥(.pub)和私钥(.ppk)
        - `ssh-keygen` 运行命令后再按三次回车会看到`RSA`（生成的秘钥默认路径为`/root/.ssh/`，会包括`id_rsa`(密钥)、`id_rsa.pub`(公钥)、`known_hosts` 3 个文件）
    - 把生成的公钥发送到对方的主机上去（在本地为服务器生成公钥）
        - `ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.1.1` （自动保存在对方主机的`/root/.ssh/authorized_keys`文件中去）
        - 输入该服务器密码实现发送
    - 登录该服务器：`ssh 192.168.1.1` 此时不需要输入密码（默认生成密钥的服务器已经有了私钥）
    - **注：** 如果是为了让root用户登录则将公钥放入到/root/.ssh目录；如果密钥提供给其他用户登录，可将公钥放在对应的家目录，如/home/aezo/.ssh/下。`.ssh`目录默认已经存在（可通过`ll -al`查看）
2. Putty/WinSCP 和 xshell/xftp
    - Putty是一个Telnet、SSH、rlogin、纯TCP以及串行接口连接软件。它包含Puttygen等工具，Puttygen可用于生成公钥和密钥（还可以将如AWS亚马逊云的密钥文件.pem转换为.ppk的通用密钥文件）
        - 在知道密钥文件时，可以通过Putty连接到服务器(命令行)，通过WinSCP连接到服务器的文件系统(FTP形式显示)
        - Puttygen使用：`类型选择RSA，大小2048` - `点击生成` - `鼠标在空白处滑动` - `保存公钥和密钥`
        - Putty使用：`Session的Host Name输入username@ip，端口22` - `Connection-SSH-Auth选择密钥文件` - `回到Session，在save session输入一个会话名称` - `点击保存会话` - `点击open登录服务器` - `下次可直接点击会话名称登录`
    - xshell/xftp是一个连接ssh的客户端
        - 登录方法：连接 - 用户身份验证 - 方法选择"public key" 公钥 - 用户名填入需要登录的用户 - 用户密钥可点击浏览生成(需要将生成的公钥保存到对应用户的.ssh目录`mv /home/aezo/id_rsa.pub /home/aezo/.ssh/authorized_keys`)。必须使用自己生成的公钥和密钥，如果AWS亚马逊云转换后的ppk文件无法直接登录。

## 定时任务 [^4]

1. 配置式
    - 添加定时配置：`sudo vim /etc/crontab`，配置说明如下，如：`30 2 1 * * root /sbin/reboot`表示每月第一天的第2个小时的第30分钟，使用root执行命令/sbin/reboot(重启)

        ```shell
        # Example of job definition:
        # .---------------- minute (0 - 59)
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




---

参考文章

[^1]: [文件压缩与解压](http://www.jb51.net/LINUXjishu/43356.html)
[^2]: [ssh登录](http://www.linuxidc.com/Linux/2016-03/129204.htm)
[^3]: [Linux文件属性](http://www.cnblogs.com/kzloser/articles/2673790.html)
[^4]: [定时任务](http://www.360doc.com/content/16/1013/10/15398874_598063092.shtml)
