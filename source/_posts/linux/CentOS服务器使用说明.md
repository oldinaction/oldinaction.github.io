---
layout: "post"
title: "CentOS服务器使用说明"
date: "2017-01-10 13:19"
categories: [linux]
tags: [CentOS, linux]
---

## 介绍

- 基于centos7介绍
- **如果服务器磁盘未挂载，最好先挂载后再进行软件安装**

### 基本配置

- 关闭防火墙
    - 决定能否访问到服务器，或服务器能否访问其他服务，取决于`服务器防火墙`和`云服务器后台管理的安全组`
    - Centos 7使用firewalld代替了原来的iptables
        - 查看状态：`systemctl status firewalld`
        - 开放端口：`firewall-cmd --zone=public --add-port=80/tcp --permanent`（--permanent永久生效，没有此参数重启后失效）
        - 重新载入：`firewall-cmd --reload`
        - 查看端口：`firewall-cmd --zone= public --query-port=80/tcp`
        - 删除端口：`firewall-cmd --zone= public --remove-port=80/tcp --permanent`
    - 云服务器一般有进站出站规则，端口开发除了系统的防火墙也要考虑进出站规则
- 永久关闭SELinux
    - `vi /etc/selinux/config` 将SELINUX=enforcing改为SELINUX=disabled后reboot重启（如：yum安装keepalived通过systemctl启动无法绑定虚拟ip，但是直接脚本启动可以绑定。关闭可systemctl启动正常绑定）
- centos7无法使用`ifconfig`命令解决方案
    - 确保有`/sbin/ifconfg`文件，否则安装net-tools(`yum -y install net-tools`)，即可使用netstat、ifconfig等命令
    - 有则此文件则在`vi /etc/profile`中加`export PATH=$PATH:/usr/sbin`，并执行`source /etc/profile`使之生效

## 常用软件安装

### 安装技巧

- `yum`安装：`yum install xxx`(基于包管理工具安装，可以更好的解决包依赖关系)
    - `yum -y install nginx` 安装时回答全部问题为是
    - `yum remove nginx` **卸载**
    - `yum search vsftpd` 查找软件vsftpd源
    - `cd /etc/yum.repos.d` 查看yum的配置文件，其中`CentOS-Base.repo`为镜像列表配置。可更换镜像列表 [^3]
- `tar.gz`等绿色安装包：解压**`tar -xvf xxx_0.0.1_linux_amd64.tar.gz`**, 会在当前目录生成一个`xxx_0.0.1_linux_amd64`的文件夹
    - 部分直接是绿色文件，解压后可运行
    - 部分需要在运行一些安装程序，进入文件加运行相应的二进制文件即可
- `.bin`等可执行文件安装：`./xxx.bin`(可能需要设置权限成可执行，本质是rpm安装)
- `rpm`格式文件安装(redhat package manage)
    - **`rpm -ivh jdk-7u80-linux-x64.rpm`** 安装程序包(jdk)
        - `--force` 强行安装，可以实现重装或降级
        - `rpm -Uvh nginx` 如果装有老版本则升级，否则安装
        - `rpm -Fvh nginx` 如果装有老版本则升级，否则退出
    - `rpm -qa` 查看安装的程序包(`rpm -qa | grep nginx` 查看是否安装nginx)
    - `rpm -ql jdk | more` 查询指定包安装后生成的文件列表
    - **`rpm -qc nginx`** 查询指定包安装的配置文件
    - `rpm -qi jdk` 查看jdk安装信息
    - `rpm -e rpm包名` 卸载某个包(程序)，其中的rpm包名可通过上述命令查看
- `源码安装`：`make`编译、`make install`
    - 前提：准备开发环境(编译环境)，安装"Development Tools"和"Development Libraries" 
        - `yum groupinstall Development Tools Development Libraries`
    - `make test` 测试编译
    - 示例如

        ```shell
        # 解压源码包
        tar -zxvf tengine-1.4.2.tar.gz
        cd tegnine-1.4.2
        # configure配置
        ./configure --prefix=/usr/local/tengine --conf-path=/etc/tengine/tengine.conf
        # 编译安装
        make && make install
        ```

### 安装jdk

#### 下载/上传jdk文件

> 默认登录时候在 root 目录，直接下载和解压，软件包和解压目录都默认在 root 目录，可以切换到 hoom 目录进行下载

- 通过ftp上传jdk对应tar压缩包到对应目录并进行解压
- 下载tar格式（推荐）
  - 下载tar文件 `wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz`**（或者先下载到本地后上传到服务器）**
  - 解压tar `tar -zxvf jdk-7u79-linux-x64.tar.gz`
  > 网上有很多深坑，如果报 gzip: stdin: not in gzip format 错请查看：http://www.cnblogs.com/gmq-sh/p/5380078.html
- 下载rpm格式
  - 获取rpm链接（下载到本地后上传到服务器）： oracle -> Downloads -> Java SE -> Java Archive -> Java SE 7 -> Java SE Development Kit 7u80 -> Accept License Agreement -> jdk-7u80-linux-x64.rpm
  - 下载jdk，运行命令：`wget http://download.oracle.com/otn/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm`(这个链接会下载成html格式，**不行**)
  - `rmp -ivh jdk-7u80-linux-x64.rpm` 安装rpm文件

#### 配置环境变量

- `vi /etc/profile` 使用vi打开profile文件
- 在末尾输入并保存（注意JAVA_HOME需要按照实际路径）

```bash
export JAVA_HOME=/root/jdk1.7.0_79
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
```
- 运行命令 `. /etc/profile` 使profile立即生效(注意 . 和 / 之间有空格)
- `java -version` 打印版本号

### 安装vsftpd [^1]

- 安装vsftp服务器后方便上传软件安装包
- ftp/sftp是协议，vsftpd是ftp服务器(只支持ftp协议)
- `yum install ftp`安装后可执行ftp命令，此时ftp相当于一个客户端，和window下的xftp类似（ftp登录`ftp localhost`；ftp命令行退出`bye`）
- `sftp localhost` 输入密码后登录ftp；exit退出(无需安装vsftp，一般服务器都默认支持，相当于windows用xftp以sftp形式登录ftp服务器)
- **vsftp需要关闭防火墙才可访问**

#### 安装步骤

1. 安装`yum install vsftpd`
    - ftp协议登录`ftp localhost`；ftp命令行退出`bye`(需要安装ftp)
2. 修改默认配置文件`vim /etc/vsftpd/vsftpd.conf`

```bash
    #不允许匿名登录(NO)
    anonymous_enable=NO
    #禁止匿名用户上传
    anon_upload_enable=NO

    #禁止用户登出自己的FTP主目录(YES表示禁止登出主目录，NO表示不做限制)
    chroot_list_enable=YES
    #如果chroot_list_enable=YES，那么凡是加在文件chroot_list中的用户都是受限止的用户，即不可浏览其主目录的上级目录
    chroot_list_file=/etc/vsftpd/chroot_list

    #设定20端口进行通信，对外默认是21端口。防火墙要开放20、21端口
    #connect_from_port_20=YES
    #监听端口
    #listen_port=2121

    ##加在最后
    #开启pam模式，/etc/vsftpd/ftpusers中为禁止登录的用户 [^2]
    pam_service_name=vsftpd
    #对vsftpd有用，否则因home目录权限为root权限而无法登录
    allow_writeable_chroot=YES
    #开启pasv模式，否则有些客户端登录会有问题，同时在防火墙中必须开启设定的端口，防火墙要开放30000-30999的端口
    #pasv_enable=YES
    pasv_min_port=30000
    pasv_max_port=30999
    #限定可登录用户列表
    userlist_enable=YES
    userlist_file=/etc/vsftpd/user_list
    #表示默认所有用户都不能登录，只有列表中用户才可以；如果userlist_deny=YES，则user_list中的用户就不允许登录ftp服务器
    userlist_deny=NO
```

3. 设置用户
    - 法一(应用程序内部使用推荐)：设置vsftpd服务的宿主用户 `useradd ftpadmin -d /home/ftproot -s /sbin/nologin`
        - `passwd ftpadmin` 给ftpadmin设置密码
        - 默认的vsftpd的服务宿主用户是root，但是这不符合安全性的需要。这里建立名字为ftpadmin的用户，用他来作为支持vsftpd的服务宿主用户。由于该用户仅用来支持vsftpd服务用，因此没有许可他登陆系统的必要，并设定他为不能登陆系统的用户（-s /sbin/nologin）。并设置ftpadmin的家目录为/home/ftproot(做为ftp服务器的根目录)
        - 将ftpadmin加到/etc/vsftpd/user_list中
        - 将ftpadmin加到/etc/vsftpd/chroot_list中
        - 文件/home/ftproot的所有者是ftpadmin，设置权限为755，包含子目录
            - `chown -R ftpadmin /home/ftproot`
            - `chmod -R 755 /home/ftproot`
    - 法二：设置vsftpd虚拟宿主用户 `useradd aezo -s /sbin/nologin`
        - `-d /home/nowhere` 使用-d参数指定用户的主目录，用户主目录并不是必须存在的。如果不设置会在`home`目录下建一个aezo的文件夹
        - `guest_username=aezo` 指定虚拟用户的宿主用户
        - `virtual_use_local_privs=YES` 设定虚拟用户的权限符合他们的宿主用户
        - `user_config_dir=/etc/vsftpd/vconf` 设定虚拟用户个人vsftp的配置文件存放路径
4. 启动服务`systemctl start vsftpd`
5. 命令行ftp可以登录，但是xftp可以登录确无法获取目录列表，IE浏览器访问`ftp://192.168.1.1`失败。谷歌浏览器正常访问并使用，或者ftp客户端登录

### tomcat安装

- `tar -zxvf apache-tomcat-7.0.61.tar.gz` 解压
- `./opt/soft/apache-tomcat-7.0.61/bin/startup.sh` 运行(需要先安装好JDK)
- 访问http://192.168.6.133:8080/

### nginx安装

参考`《nginx.md》(基于编译安装tengine)`(nginx同理)

## yum安装

- `yum -y install memcached` 安装memcached(默认端口11211)
- `yum -y install git` 安装git

## 管理软件安装

### htop安装

1. htop是比top功能更多的进程管理工具
2. `yum install htop` 安装
3. `htop`查看进程信息(命令行上显示的界面可直接鼠标点击操作)
4. 小技巧
    - 点击Tree/Sorted可切换视图
    - 选中一行，按下键可查看更多进程
    - Nice：指的是nice值，这样就可以提高/降低对应进程的优先级





---

参考文章

[^1]: [vsftpd](http://www.cnblogs.com/hhuai/archive/2011/02/12/1952647.html)
[^2]: [ftp-530-Permission-denied](http://www.cnblogs.com/GaZeon/p/5393853.html)
[^3]: [更换yum镜像](http://blog.csdn.net/inslow/article/details/54177191)
