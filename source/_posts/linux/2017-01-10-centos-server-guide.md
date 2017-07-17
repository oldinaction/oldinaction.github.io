---
layout: "post"
title: "CentOS服务器使用指导"
date: "2017-01-10 13:19"
categories: [extend]
tags: [CentOS, server]
---

* 目录
{:toc}

## 基本命令

- `yum install vsftpd` 安装软件vsftpd，一路y下去
- `yum search vsftpd` 查找软件vsftpd源
- Centos 7使用firewalld代替了原来的iptables
- 云服务器一般有进站出站规则，端口开发除了系统的防火墙也要考虑进出站规则
- **如果服务器磁盘未挂载，最好先挂载后再进行软件安装**

## 常用软件安装

### 安装jdk

#### 下载jdk文件

> 默认登录时候在 root 目录，直接下载和解压，软件包和解压目录都默认在 root 目录，可以切换到 hoom 目录进行下载

1. 下载rpm格式
  - 获取rpm链接（下载到本地后上传到服务器）： oracle -> Downloads -> Java SE -> Java Archive -> Java SE 7 -> Java SE Development Kit 7u80 -> Accept License Agreement -> jdk-7u80-linux-x64.rpm
  - 下载jdk，运行命令：`wget http://download.oracle.com/otn/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm`(这个链接会下载成html格式，**不行**)
  - `rmp -ivh jdk-7u80-linux-x64.rpm` 安装rpm文件
2. 下载tar格式（推荐）
  - 下载tar文件 `wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz`
  - 解压tar `tar -zxvf jdk-7u79-linux-x64.tar.gz`
  > 网上有很多深坑，如果报 gzip: stdin: not in gzip format 错请查看：http://www.cnblogs.com/gmq-sh/p/5380078.html

#### 配置环境变量
- `vi /etc/profile` 使用vi打开profile文件
- 在末尾输入并保存（注意JAVA_HOME需要按照实际路径）
  ```linux
    export JAVA_HOME=/root/jdk1.7.0_79
    export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
    export PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin
  ```
  > `vi 文件名`打开某个文件进行编辑
  > - 点击键盘`insert`，进入vi编辑模式，开始编辑；
  > - 点击`esc`退出编辑模式，进入到vi命令行模式；
  > - 输入`:x`/`ZZ`将刚刚修改的文件进行保存，退出编辑页面，回到初始命令行
  > - `Ctrl+z` 退出 vi 编辑器

- 运行命令 `. /etc/profile` 使profile立即生效(注意 . 和 / 之间有空格)
- `java -version` 打印版本号

### 安装vsftpd [^1]

> ftp/sftp是协议，vsftpd是ftp服务器(只支持ftp协议)
> `yum install ftp`安装后可执行ftp命令，此时ftp相当于一个客户端，和window下的xftp类似

1. 安装`yum install vsftpd`
2. 修改默认配置文件`vim /etc/vsftpd/vsftpd.conf`

    ```
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


### git安装

1. 查看是否安装git/查看git是否安装成功：`git --version`
    - `-bash: git: command not found` 表示尚未安装
2. 下载安装：`yum install git`

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
[^2]: [ftp 530 Permission denied](http://www.cnblogs.com/GaZeon/p/5393853.html)
