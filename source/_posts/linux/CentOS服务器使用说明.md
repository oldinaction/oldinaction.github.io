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
- 软件安装和项目代码最好不要放到home的用户目录，项目迁移时可能出现目录不一致问题
- [CentOS7安装：http://blog.aezo.cn/2016/11/20/linux/ubuntu/](/_posts/linux/ubuntu.md#CentOS7安装)

### 新服务器初始化

- 关闭防火墙
    - `systemctl stop firewalld && systemctl disable firewalld`
    - 决定能否访问到服务器，或服务器能否访问其他服务，取决于`服务器防火墙`和`云服务器后台管理的安全组`
    - Centos 7使用`firewalld`代替了原来的`iptables`
        - 查看状态：`systemctl status firewalld`
        - 开放端口：`firewall-cmd --zone=public --add-port=80/tcp --permanent`（--permanent永久生效，没有此参数重启后失效）
        - 重新载入：`firewall-cmd --reload`
        - 查看端口：`firewall-cmd --zone= public --query-port=80/tcp`
        - 删除端口：`firewall-cmd --zone= public --remove-port=80/tcp --permanent`
    - 云服务器一般有进站出站规则，端口开发除了系统的防火墙也要考虑进出站规则
- 永久关闭`SELinux`
    - `sudo vi /etc/selinux/config` 将`SELINUX=enforcing`改为`SELINUX=disabled`后reboot重启（如：yum安装keepalived通过systemctl启动无法绑定虚拟ip，但是直接脚本启动可以绑定。关闭可systemctl启动正常绑定）
    - 快速修改命令 **`sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config`**，并重启
- 查看磁盘分区和挂载，项目建议放到数据盘(阿里云单独购买的数据盘需要格式化才可使用)。[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux/](/_posts/linux/linux.md#磁盘)
- 校验系统时间，参考[时间同步](#时间同步)，或使用下文配置脚本
- 添加用户、修改密码、设置sudo权限、su免密码：[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux/](/_posts/linux/linux.md#权限系统)
- 设置用户umask值为0022(包括root用户)：[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux/](/_posts/linux/linux.md#文件权限)
- 证书登录、禁用root(内部集群一般不建议，因为经常需要ssh远程登录)及密码登录、修改ssh的22端口：[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux/](/_posts/linux/linux.md#ssh)
- 修改hostname：`hostnamectl --static set-hostname aezocn` 修改主机名并重启
- [更换镜像，见下文](#镜像管理)
- 内核升级(Centos7 默认使用内核版本为`3.10`，目前内核长期支持版为`4.4`)
- `yum update -y` 更新软件版本和内核次版本。初始化机器可执行，生成环境不建议重复更新内核版本
    - `yum upgrade` 只更新软件版本，不更新内核版本
- [常用软件安装](#常用软件安装)

### 内核升级 [^7]

- **Centos7 默认使用内核版本为`3.10`**，目前内核长期支持版为`4.4`，主线稳定版为`5.2`
- 内核版本的定义
    - 版本性质：主分支ml(mainline)，稳定版(stable)，长期维护版lt(longterm)
    - 版本命名格式为 "A.B.C"
        - A 是内核版本号：第一次是1994年的 1.0 版，第二次是1996年的 2.0 版，第三次是2011年的 3.0 版发布
        - B 是内核主版本号：奇数为开发版，偶数为稳定版
        - C 是内核次版本号
- 查看内核版本
    - `uname -a` 查看当前内核版本
    - `rpm -qa | grep kernel` 查看安装的内核版本（或者查看启动器：`awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg`）
    - `yum remove 3.10.0-1062.1.2.el7.x86_64` 删除内核版本
- Centos7升级内核
    - `bash <(curl -L https://raw.githubusercontent.com/oldinaction/scripts/master/shell/prod/centos7-update-kernel.sh) 2>&1 | tee kernel.log`
    - 会直接升级成目前最新的稳定版，如`5.4`(ThinkPadE480 也可正常升级到5.4)
    - 需使用root用户执行，如果下载rpm失败，可尝试重新执行

### 常用配置脚本

```bash
# 升级内核(root用户执行)，见上文。无法下载脚本时，可参考下文使用sourcegraph
bash <(curl -L https://raw.githubusercontent.com/oldinaction/scripts/master/shell/prod/centos7-update-kernel.sh) 2>&1 | tee kernel.log

# 记录系统日志(root用户执行)
bash <(curl -L https://sourcegraph.com/github.com/oldinaction/scripts@master/-/raw/shell/prod/conf-recode-cmd-history.sh) 2>&1 | tee conf-recode-cmd-history.log

# 设置时间自动同步
bash <(curl -L https://sourcegraph.com/github.com/oldinaction/scripts@master/-/raw/shell/prod/conf-ntp-sync.sh) 2>&1 | tee conf-ntp-sync.log
```

### 新服务器常见问题

- centos7无法使用`ifconfig`命令解决方案
    - 确保有`/sbin/ifconfg`文件，否则安装net-tools(`yum -y install net-tools`)，即可使用netstat、ifconfig等命令
    - 有则此文件则在`vi /etc/profile`中加`export PATH=$PATH:/usr/sbin`，并执行`source /etc/profile`使之生效
- xshell卡死在`To escape to local shell, press 'Ctrl+Alt+]'.`
    - 关闭防火墙
    - `vi /etc/ssh/sshd_config` 修改 `# UseDNS yes` 为 `UseDNS no`，并重启sshd

## 常用软件安装

- 自定义服务参考[http://blog.aezo.cn/2017/01/16/arch/nginx/](/_posts/arch/nginx.md#基于编译安装tengine)
- 常用表安装

```bash
yum -y install net-tools # netstat、ifconfig命令
yum -y install htop
yum -y install gcc # 编译c
# yum -y install tcpdump
# yum -y install psmisc # pstree命令
# yum -y install lsof # 查看进程使用的文件描述符
# yum -y install strace # 用于记录系统调用
# yum -y install nc # Ncat
```

### 安装方式说明 [^2]

#### 镜像管理

- **更换镜像源**

```bash
# 查看yum的配置文件，其中`CentOS-Base.repo`为镜像列表配置。**可更换镜像列表** [^3]
cd /etc/yum.repos.d
# 备份
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# 基础源，下载阿里云镜像
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# 安装EPEL源(新增镜像源)
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# 生成缓存
yum makecache
```
- 安装`EPEL`(Extra Packages for Enterprise Linux)。epel它是RHEL 的 Fedora 软件仓库，为 RHEL 及衍生发行版如 CentOS、Scientific Linux 等提供高质量软件包的项目。如nginx可通过epel安装
    - 方式一：使用上述阿里云镜像
    - 方式二：
        - 下载epel源 `wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm` (http://fedoraproject.org/wiki/EPEL)
        - 安装epel `rpm -ivh epel-release-latest-7.noarch.rpm`
- 手动新增镜像源

```bash
## 直接下载镜像源文件新增
# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

## 自行创建镜像源文件，如创建kubernetes镜像
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
# 列举镜像
yum repolist
```

#### rpm安装(软件包管理器)

- `rpm`格式文件安装(redhat package manage。有依赖关系，安装和卸载也有先后顺序)
- rpm包的命名规范：`name-version-release.os.arch.rpm`
    - os：即说明RPM包支持的操作系统版本。如el6(即rhel6)、centos6、el5、suse11
    - arch：主机平台。如i686、x86_64、amd64、ppc(power-pc)、noarch(即不依赖平台)
- 有的rpm包需要.asc的秘钥。镜像源可认为是rpm包的公有仓库，一般也会配置.gpg秘钥
- 命令

```bash
rpm <option> xxx
# -i：表示安装
# -v, -vv, -vvv：表示详细信息
# -h：以"#"号显示安装进度
# -q：查询某一个RPM包是否已安装
    # -qi：查询某一个RPM包的详细信息
    # -ql：列出某RPM包中所包含的文件
    # -qf：查询某文件是哪个RPM包生成的
    # -qa：列出当前系统所有已安装的包
# -e：卸载指定包名
# -U：升级软件，若未软件尚未安装，则安装软件
# -F：升级软件
# -V：对RPM包进行验证
# --force：强行安装，可以实现重装或降级

## 举例
rpm -ivh jdk-7u80-linux-x64.rpm # 安装程序包(jdk)
rpm -qa # 查看安装的程序包(`rpm -qa | grep nginx` 查看是否安装nginx)
rpm -qc nginx # 查询指定包安装的配置文件
rpm -ql jdk | more # 查询指定包安装后生成的文件列表
rpm -e nginx # 卸载某个包(程序)，其中的rpm包名可通过上述命令查看
rpm -Uvh nginx # 如果装有老版本则升级，否则安装
rpm -Fvh nginx # 如果装有老版本则升级，否则退出
```

#### yum安装(软件包管理器的前端工具)

```bash
# 基于包管理工具安装，可以更好的解决包依赖关系。-y 安装时回答全部问题为是
yum install -y nginx
# 卸载
yum remove nginx
# 查看版本。`yum install -y ceph-common-14.2.4-0.el7.x86_64` 安装指定版本
yum list | grep ceph-common # ceph-common.x86_64                        2:14.2.4-0.el7                 @Ceph
yum list installed # 查看已安装的
# 查找软件vsftpd源
yum search vsftpd
```

#### tar.gz安装包安装

- `tar.gz`等绿色安装包：解压**`tar -xvf xxx_0.0.1_linux_amd64.tar.gz`**, 会在当前目录生成一个`xxx_0.0.1_linux_amd64`的文件夹
- 部分直接是绿色文件，解压后可运行
- 部分需要在运行一些安装程序，进入文件加运行相应的二进制文件即可

#### .bin安装

- `.bin`等可执行文件安装：`./xxx.bin`(可能需要设置权限成可执行，本质是rpm安装)

#### 源码安装

- 前提：准备开发环境(编译环境)，安装"Development Tools"和"Development Libraries" 
    - `yum groupinstall Development Tools Development Libraries`
- 源码安装完成后可删除源码文件夹
- 示例如

    ```shell
    # 解压源码包
    tar -zxvf tengine-1.4.2.tar.gz
    cd tegnine-1.4.2
    # configure配置，`--prefix`为安装位置
    ./configure --prefix=/usr/local/tengine --conf-path=/etc/tengine/tengine.conf
    # make test 测试编译
    # 编译安装
    make && make install
    ```

### 宝塔面板

- [宝塔](https://www.bt.cn/)Linux面板是提升运维效率的服务器管理软件，支持一键LAMP/LNMP/集群/监控/网站/FTP/数据库/JAVA等100多项服务器管理功能

```bash
## 安装. 确保是干净的操作系统，没有安装过其它环境带的Apache/Nginx/php/MySQL/pgsql/gitlab/java（已有环境不可安装）
# 默认只能安装在 /www 目录，因此可提前创建好软连接
mkdir /home/bt
ln -s /home/bt /www
# 安装
yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh
# 安装成功后会显示安全的登录入口和账号密码
# ***可通过执行命令查看登录入口和账号密码***
sudo /etc/init.d/bt default

## 卸载
wget http://download.bt.cn/install/bt-uninstall.sh && sh bt-uninstall.sh
```
- 目录说明
    - 软件安装目录 /www/server
        - data 数据目录(mysql)
    - 备份目录 /www/backup
    - 网站根目录 /www/wwwroot

### 安装jdk

#### 下载/上传jdk文件

> 默认登录时候在 root 目录，直接下载和解压，软件包和解压目录都默认在 root 目录，可以切换到 hoom 目录进行下载

- 通过ftp上传jdk对应tar压缩包到对应目录并进行解压
- 下载tar格式（推荐）
    - 下载tar文件并上传到服务器
    - 解压tar **`tar -zxvf jdk-8u161-linux-x64.tar.gz -C /opt/soft`** （需要先创建好/opt/soft目录）
- 下载rpm格式
    - 获取rpm链接（下载到本地后上传到服务器）： oracle -> Downloads -> Java SE -> Java Archive -> Java SE 8 -> Java SE Development Kit 8u161 -> Accept License Agreement -> jdk-8u161-linux-x64.rpm
    - `rmp -ivh jdk-8u161-linux-x64.rpm` 安装rpm文件，可执行文件保存在`/usr/java/jdk1.8.0_161-amd64/jre/bin/java`
    - 设置环境变量。可设置`JAVA_HOME=/usr/java/default`

#### 配置环境变量

- `vi /etc/profile` 使用vi打开profile文件(也可在`.bash_profile`中设置单个用户的环境变量)
- 在末尾输入并保存（注意JAVA_HOME需要按照实际路径）

```bash
export JAVA_HOME=/opt/soft/jdk1.8.0_161
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
```
- 运行命令 `. /etc/profile` 使profile立即生效(注意 . 和 / 之间有空格)
- `java -version` 打印版本号

### ftp服务器安装

参考：[http://blog.aezo.cn/2019/03/19/arch/ftp/](/_posts/devops/ftp.md#FTP服务器)

### mysql安装

- tar安装(推荐) [^5]

    ```bash
    ## **使用root用户安装即可**
    # 安装mysql之前需要确保系统中有libaio依赖
    yum search libaio
    # yum install libaio

    # 下载tar并上传到服务器：http://ftp.ntu.edu.tw/MySQL/Downloads/MySQL-5.7/mysql-5.7.25-el7-x86_64.tar.gz
    tar -zxvf mysql-5.7.25-el7-x86_64.tar.gz -C /opt/soft
    mv mysql-5.7.25-el7-x86_64 mysql57
    
    # 添加用户组
    groupadd mysql
    # 添加用户mysql，并加入到mysql用户组(使用-r参数表示mysql用户是一个系统用户，不能登录)
    useradd -r -g mysql mysql
    id mysql # 查看mysql用户信息

    # 创建数据文件存储目录(一般放在数据盘，此时为root用户创建)
    mkdir -p /home/data/mysql
    # 修改mysql安装根目录权限
    chown -R mysql:mysql /opt/soft/mysql57

    # 修改配置文件。可安装下文修改(设置basedir和datadir等)
    vi /etc/my.cnf

    # 初始化mysql. mysqld --initialize-insecure初始化后的mysql是没有密码的
    /opt/soft/mysql57/bin/mysqld --initialize-insecure --user=mysql --basedir=/opt/soft/mysql57 --datadir=/home/data/mysql

    # 重新修改下各个目录的权限
    chown -R root:root /opt/soft/mysql57 # 把安装目录的目录的权限所有者改为root
    chown -R mysql:mysql /home/data/mysql # 把data目录的权限所有者改为mysql(/home/data权限可以不是mysql)
    
    # 启动mysql(此时可能会卡在启动命令行。可以再起一个命令行进行密码修改，注册成服务后可以关闭)
    /opt/soft/mysql57/bin/mysqld_safe --user=mysql &

    ## 修改root密码（第一次无需输入密码，直接回车即可进入进行root密码修改）
    /opt/soft/mysql57/bin/mysql -u root -p
    # mysql命令
    use mysql;
    update user set authentication_string=password('Hello1234!') where user='root'; # mysql5.7及以后密码必须包含字母、数字、特殊字符
    grant all privileges on *.* to 'smalle'@'localhost' identified by 'Hello1234!' with grant option; # 创建用户
    flush privileges;
    exit;
    # 测试登录略

    ## copy启动脚本并将其添加到服务且设置为开机启动
    cp /opt/soft/mysql57/support-files/mysql.server /etc/init.d/mysqld # **此脚本中定义的是基于mysql用户启动，且会通过mysqld_safe启动mysqld**
    vi /etc/init.d/mysqld # 修改其中的`/usr/local/mysql`和`/usr/local/mysql/data`为对应的basedir和datadir。具体如下文
    chkconfig --add mysqld # 加入服务(之后systemctl可操作的服务名)
    chkconfig --level 345 mysqld on # 设置开机启动
    systemctl status mysqld # 查看状态(root用户只需服务启动，最终还是通过mysql用户启动的)。`active (running)`表示启动正常。也可查看`ps -ef | grep mysqld`，会出现`mysqld_safe`(守护进程)和`mysqld`(服务进程)两个进程
    # 此时如果需要重新启动需要Ctrl+c关掉上面开启的mysqld_safe程序
    systemctl restart mysqld # 安装成功检查重启程序是否正常（或者 /etc/init.d/mysqld restart）

    # 创建mysql软链接到bin目录
    ln -s /opt/soft/mysql57/bin/mysql /usr/bin
    ln -s /opt/soft/mysql57/bin/mysqldump /usr/bin
    ```
    - **修改`/etc/init.d/mysqld`文件**
    
    ```bash
    # 修改
    if test -z "$basedir"
    then
    basedir=/usr/local/mysql
    bindir=/usr/local/mysql/bin
    if test -z "$datadir"
    then
        datadir=/usr/local/mysql/data
    fi
    sbindir=/usr/local/mysql/bin
    libexecdir=/usr/local/mysql/bin
    else

    # 为
    if test -z "$basedir"
    then
    basedir=/opt/soft/mysql57
    bindir=/opt/soft/mysql57/bin
    if test -z "$datadir"
    then
        datadir=/home/data/mysql
    fi
    sbindir=/opt/soft/mysql57/bin
    libexecdir=/opt/soft/mysql57/bin
    else
    ```

- yum安装(安装时无法自定义文件存储路径，但是安装完成后可手动移动数据文件到新目录)

    ```bash
    # 下载mysql源安装包
    wget http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
    # 安装mysql源
    rpm -ivh mysql57-community-release-el7-8.noarch.rpm
    # 检查mysql源是否安装成功
    yum repolist enabled | grep "mysql.*-community.*"
    # 安装mysql服务端和客户端(速度较慢)。`yum install mysql`仅仅安装了客户端
    yum -y install mysql-server
    # 设置开机启动，并启动
    systemctl enable mysqld && systemctl start mysqld
    # 查看临时密码
    grep 'temporary password' /var/log/mysqld.log
    # 登录
    mysql -uroot -p
    # 修改密码(mysql5.7密码必须包含大小写字母、数字和特殊符号，并且长度不能少于8位)。必须修改密码才能执行sql语句
    alter user 'root'@'localhost' identified by 'Hello1234!';
    # 添加 'root'@'%' 用户，并赋权，且允许远程登录
    grant all privileges on *.* to 'root'@'%' identified by 'Hello1234!' with grant option;
    flush privileges;
    quit # 退出使用新密码重新登录
    ```
- 配置文件默认路径 `/etc/my.cnf`(修改配置后需要重启服务)

    ```ini
    [client] # 客户端连接时的默认配置(可省略)
    port=13306
    socket=/home/data/mysql/mysql.sock
    default-character-set=utf8mb4

    [mysqld] # 服务端配置
    # skip-grant-tables # skip-grant-tables作为启动参数的作用，MYSQL服务器不加载权限判断，任何用户都能访问数据库，忘记密码时可使用
    port=13306
    # 表名大小写：0是大小写敏感，1是大小写不敏感. linux默认是0，windows默认是1(建议设置成1)
    lower_case_table_names=1
    character-set-server=utf8mb4
    collation-server=utf8mb4_bin
    init-connect='SET NAMES utf8mb4'
    # 防止导入数据时数据太大报错
    max_allowed_packet=512M

    ## 手动安装时设置
    # 手动安装时填写mysql根目录
    basedir=/opt/soft/mysql57
    # 手动安装时填写mysql数据目录。默认目录为/var/lib/mysql
    datadir=/home/data/mysql
    socket=/home/data/mysql/mysql.sock
    #pid-file = /home/data/mysql/mysql.pid # pid文件，默认为 %datadir%/aezocn-1.pid
    #log_error=/home/data/mysql/mysqld_error.log # 服务错误日志文件，默认为 %datadir%/aezocn-1.err，其中aezocn-1为服务名
    slow_query_log_file=/home/data/mysql/slow.log

    # Disabling symbolic-links is recommended to prevent assorted security risks
    symbolic-links=0
    ```
- 卸载

    ```bash
    yum remove mysql # 卸载

    rpm -qa | grep -i mysql # 查看mysql的依赖
    yum remove mysql-xxx # 依次卸载

    find / -name mysql # 查看和mysql相关文件/文件夹
    # 删除
    rm -rf /var/lib/mysql
    rm -rf /var/lib/mysql/mysql
    rm -rf /etc/logrotate.d/mysql
    rm -rf /usr/share/mysql
    rm -rf /usr/bin/mysql
    rm -rf /usr/lib64/mysql

    rpm -qa | grep -i mysql # 如果没有显式则表示卸载完成

    # 删除mysql相关用户和组
    userdel -rf mysql # 包括删除家目录
    groupdel mysql
    ```
- 其他
    - `show variables like '%dir%';` sql命令查看mysql相关文件(数据/日志)存放位置
        - 数据文件默认位置：`/var/lib/mysql`
    - mysql-jdbc驱动下载
        - 5.7对应5.1的驱动 `wget https://downloads.mysql.com/archives/get/p/3/file/mysql-connector-java-5.1.49.tar.gz`(mysql-connector-java-5.1.49.jar)
- 常见问题
    - 报错`cd: /usr/local/mysql: No such file or directory`。建议检查是否修改了`/etc/init.d/mysqld`文件中的basedir和datadir。[^6]
    - 重新启动服务会报错`ERROR! The server quit without updating PID file .`。同上

### 安装oracle客户端 [^4]

- 下载`rpm`(地址：http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html，此地址为64位包下载)
- 如安装`oracle11.2.0.4客户端`，下载`oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm`和`oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm`，并上传到服务器
- 安装运行 `rpm -ivh oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm`、`rpm -ivh oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm`
- 环境变量配置`vi ~/.bash_profile`

    ```bash
    export ORACLE_BASE=/usr/lib/oracle/11.2
    export ORACLE_HOME=$ORACLE_BASE/client64 #尤其注意这里要正确
    export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
    export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
    ```
    - `source ~/.bash_profile` 使配置生效
- sqlplus连接：`sqlplus smalle/smalle@192.168.1.1:1521/orcl`
    - 配置了环境变量仍然不生效，报错`bash: sqlplus: command not found`。解决办法创建符号链接：`ln -s $ORACLE_HOME/bin/sqlplus /usr/bin`
- 配置TNS，在`/usr/lib/oracle/11.2/client64/network/admin/tnsnames.ora`中加入TNS配置(可能需要自行创建`network/admin/tnsnames.ora`的目录和文件)
    - `sqlplus smalle/smalle@my_dbtest`

### tomcat安装

- `tar -zxvf apache-tomcat-7.0.61.tar.gz` 解压
- `./opt/soft/apache-tomcat-7.0.61/bin/startup.sh` 运行(需要先安装好JDK)
- 访问http://192.168.6.133:8080/

### nginx安装

参考[《nginx.md》(基于编译安装tengine)](/_posts/arch/nginx.md) (nginx同理)

### python3安装

> linux一般都是python2，如果要使用python3最好不要动之前python2的环境

- 安装步骤
    
    ```bash
    # 下载 Python-3.6.4.tar.xz
    curl -O https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tar.xz
    tar xvf Python-3.6.4.tar.xz -C /opt
    cd Python-3.6.4
    # 切换root用户
    su - root
    ## 编译和安装(可重复执行)
    # --enable-optimizations性能优化；--with-ssl开启ssl模块，否则pip3某些包无法安装；--enable-loadable-sqlite-extensions表示开启sqlite3
    ./configure --enable-optimizations  --with-ssl --enable-loadable-sqlite-extensions
    # 第一次需要大概15分钟。需要使用root运行。使用sudo运行也会报错`cannot create regular file ‘/usr/local/bin/python3.6m’: Permission denied`
    make && make install
    ## 查看
    python3
    pip3
    ```
- `No module named '_sqlite3'` 无法使用sqlite3模块问题
    - `yum -y install sqlite-devel`
    - `./configure --enable-loadable-sqlite-extensions` 进入python3安装目录
    - `make && make install` 重新编译python，如果之前编译成功，这次编译会很快
    - `python3` - `import sqlite3` 不报错则表示成功

### php安装

- `yum install -y php`

#### php-fpm

nginx本身不能处理PHP，它只是个web服务器，当接收到请求后，如果是php请求，则发给php解释器处理，并把结果返回给客户端。nginx一般是把请求发fastcgi管理进程处理，fascgi管理进程选择cgi子进程处理结果并返回被nginx。而使用php-fpm则可以使nginx支持PHP

- `yum install -y php-fpm`
- `systemctl start php-fpm` 默认监听`9000`端口
    - 编辑`/etc/php-fpm.d/www.conf`中的`listen = 127.0.0.1:9000`可修改监听端口
- nginx配置

    ```bash
    location ~ \.php$ {
        # 不存在访问资源是返回404，如果存在还是返回`File not found.`则说明配置有问题
        try_files      $uri = 404;
        root           html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        # 此处要使用`$document_root`否则报错File not found.`/`no input file specified`
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
    ```

### htop安装

- htop是比top功能更多的进程管理工具
- `yum install htop` 安装
- `htop`查看进程信息(命令行上显示的界面可直接鼠标点击操作)
- 小技巧
    - 点击Tree/Sorted可切换视图
    - 选中一行，按下键可查看更多进程
    - Nice：指的是nice值，这样就可以提高/降低对应进程的优先级

### 邮件发送服务配置

- 使用外部邮件发送服务

```bash
yum install -y mailx

# 邮件发送服务配置
cat >> /etc/mail.rc <<EOF
set from=test@163.com
set smtp=smtp.163.com
set smtp-auth-user=test@163.com
# 授权密码，不是登录密码
set smtp-auth-password=xxx
set smtp-auth=login
EOF
# 测试发送(163邮箱容易出现554检测到垃圾拒发问题，此处使用-c抄送给自己可解决)
echo "test mail..." | mail -s "hello subject" -c test1@163.com test2@163.com
```
- 安装**postfix(centos7已内置安装并启动)**或者sendmail等邮件发送服务(此方法发送的邮件容易进入垃圾箱)

```bash
# yum install -y postfix
# systemctl enable postfix && systemctl restart postfix && systemctl status postfix
# 安装mailx。此方式无需设置smtp等也可发送邮件(如果mail.rc设置了smtp则优先使用配置的smtp)
echo "zabbix test mail" | mail -s "zabbix" test@163.com
# 可以看到手动一封来自 `root<root@node1.localdomain>`的邮件，其中node1为服务器名
```

### 时间同步

- 校验时区：如`Tue Jul  2 21:26:09 CST 2019`和`Tue Jul  2 21:26:09 EDT 2019`，其中北京时间的时区为`CST`
    - `cp /etc/localtime /etc/localtime.bak`
    - `ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime` 修改成功后之前的日志是无法同步修改的
    - `date` 获取当前时间(精确到秒)

        ```bash
        # 获取毫秒
        echo `expr \`date +%s%N\` / 1000000`
        ```
- 校验时间
    - `date` 查看时间
    - `date -s "2019-04-07 10:00:00"` 设置时间
    - `hwclock -w` 将时间写入bios固件避免重启失效

#### NTP网络时间同步

- NTP(Network Time Protocol)
- **使用脚本自动配置时间同步** `bash <(curl -L https://sourcegraph.com/github.com/oldinaction/scripts@master/-/raw/shell/prod/conf-ntp-sync.sh) 2>&1 | tee conf-ntp-sync.log`
- 使用 [^8]

```bash
## ntpd是步进式的逐渐调整时间(慢慢调整到正确时间)，而ntpdate是断点更新(直接重写时间为正确时间)
sudo yum install -y ntp ntpdate ntp-doc

## 立即与国家授时中心同步
# systemctl stop ntpd 同步时可关闭ntpd(防止被慢慢同步成错误时间)
sudo ntpdate 0.cn.pool.ntp.org

## 开启ntpd服务之后自动同步
cat > /etc/ntp.conf << 'EOF'
# 可以保证ntpd在时间差较大时依然工作。如果本地时间和目标服务器差别太大，ntpd不会进行时间同步，且会自动退出
tinker panic 0

# restrict default ignore # 设置默认策略为允许任何主机进行时间同步
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery  # `restrict -6` 表示针对ipv6设置

# 允许本地所有操作
restrict 127.0.0.1
restrict -6 ::1

# 允许的局域网络段或单独ip
# restrict 192.168.6.0 mask 255.255.255.0 nomodify motrap # 此时表示限制向从192.168.0.1-192.168.0.254这些IP段的服务器提供NTP服务

# 设定NTP主机来源(上层的internet ntp服务器). 其中prefer表示优先主机(如局域网NTP服务器)
# server 192.168.6.131 prefer
server cn.pool.ntp.org prefer
server 0.asia.pool.ntp.org
server 3.asia.pool.ntp.org
server 0.centos.pool.ntp.org iburst

# 如果无法与上层ntp server通信以本地时间为标准时间
server   127.127.1.0    # local clock
fudge    127.127.1.0 stratum 10

# 计算本ntp server与上层ntpserver的频率误差
driftfile /var/lib/ntp/drift

# Key file containing the keys and key identifiers used when operating with symmetric key cryptography.
keys /etc/ntp/keys

# 日志文件
logfile /var/log/ntp.log
EOF

# ntp只能同步系统时间，此配置可将系统时间同步到硬件
cat > /etc/sysconfig/ntpd << EOF
# Drop root to id 'ntp:ntp' by default.
OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid"
# Set to 'yes' to sync hw clock after successful ntpdate
# BIOS的时间也会跟着修改
SYNC_HWCLOCK=yes
# Additional options for ntpdate
NTPDATE_OPTIONS=""
EOF

systemctl enable ntpd --now # 设置开机重启并此时立即启动
systemctl status ntpd
```
- 配置文件说明
    - restrict控制权限，参数如下
        - ignore：关闭所有的 NTP 联机服务
        - nomodify：客户端不能更改服务端的时间参数，但是客户端可以通过服务端进行网络校时
        - notrust：客户端除非通过认证，否则该客户端来源将被视为不信任子网
        - noquery：不提供客户端的时间查询。用户端不能使用ntpq，ntpc等命令来查询ntp服务器
        - notrap：不提供trap远端登陆。拒绝为匹配的主机提供模式 6 控制消息陷阱服务。陷阱服务是 ntpdq 控制消息协议的子系统，用于远程事件日志记录程序
        - nopeer：用于阻止主机尝试与服务器对等，并允许欺诈性服务器控制时钟
        - kod：访问违规时发送 KoD 包
- ntp服务默认使用`udp:123`进行传输
- 相关命令

```bash
# 查看ntp服务器有无和上层ntp连通
ntpstat
# 查看ntp服务器与上层ntp的状态。显示结果参数说明
    # remote   - 本机/上层ntp的ip或主机名，"+"表示优先，"*"表示次优先
    # refid    - 参考上一层ntp主机地址
    # st       - stratum阶层
    # when     - 多少秒前曾经同步过时间
    # poll     - 下次更新在多少秒后
    # reach    - 已经向上层ntp服务器要求更新的次数
    # delay    - 网络延迟
    # offset   - 时间补偿
    # jitter   - 系统时间与bios时间差

# ntpq用来监视ntpd操作
ntpq -p
```

### Supervisor 进程管理

- `Supervisor` 是用Python开发的一个client/server服务，是Linux/Unix系统下的一个进程管理工具。可以很方便的监听、启动、停止、重启一个或多个进程。用supervisor管理的进程，**当一个进程意外被杀死，supervisor监听到进程死后，会自动将它重启**，很方便的做到进程自动恢复的功能，不再需要自己写shell脚本来控制
- 使用

```bash
## 安装
yum install -y supervisor
systemctl enable supervisord --now && systemctl status supervisord

## 创建守护进程配置文件
cat > /etc/supervisord.d/node_exporter.ini << EOF
[program:node_exporter]
# 执行 command 之前，先切换到工作目录
# directory=/opt/test
# 执行(启动)命令
command=/usr/sbin/node_exporter
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/node_exporter.log
log_stderr=true
user=root
EOF
supervisorctl update && supervisorctl status

## 命令
supervisorctl status        # 查看监控程序状态
supervisorctl update        # 根据最新的配置文件，启动新配置或有改动的进程，配置没有改动的进程不会受影响而重启
supervisorctl reload        # 载入最新的配置文件，停止原有进程并按新的配置启动、管理所有进程
supervisorctl restart all   # 手动重启所有
supervisorctl stop node_exporter # 停止进程node_exporter(尽管设置了supervisor自动重启，此时也不会重启；supervisor自动重启只针对意外退出)
supervisorctl start node_exporter # 启动进程node_exporter
```

### NFS

> http://linux.vbird.org/linux_server/0330nfs.php

```bash
## 服务端
# 安装nfs
yum install -y nfs-utils
# 启动nfs服务。启动后NFS的服务状态为`Active: active (exited)`是正常的
systemctl enable nfs --now && systemctl status nfs

# 创建两个目录(v1,v2)并设置为任何人可读写
mkdir /data/volumes/v{1,2} -pv && chmod 777 /data/volumes/v{1,2}
# 编辑暴露配置
cat >> /etc/exports << EOF
/data/volumes/v1 192.168.6.0/24(rw,sync,no_subtree_check,no_root_squash)
/data/volumes/v2 192.168.6.0/24(rw,all_squash)
EOF
# 执行暴露目录(修改配置后可重新执行)
exportfs -arv
# 查看配置
showmount -e

## 在其他机器测试挂载nfs存储卷
# mount -t nfs 192.168.6.10:/data/volumes/v1 /mnt
# mount -t nfs 192.168.6.10:/data/volumes/v1/subpath /mnt # 挂载子路径，需要提前创建好子路径
```
- 配置说明
    - `ro`：只读权限
    - `rw`：读写权限
    - `root_squash`(默认)：登入NFS主机，使用该共享目录时相当于该目录的拥有者。但是如果是以root身份使用这个共享目录的时候，那么这个使用者(root)的权限将被压缩成为匿名使用者，即通常他的UID与GID都会变成nobody那个身份
    - `no_root_squash`：登入NFS主机，使用该共享目录时相当于该目录的拥有者。如果是root的话，那么对于这个共享的目录来说，他就具有root的权限。这个参数极不安全，**k8s集群使用建议设置此参数，否则如基于Chart安装mysql会失败(无法修改文件所属者)**
    - `all_squash`：不论登入NFS的使用者身份为何，他的身份都会被压缩成为匿名使用者，通常也就是nobody
    - `no_all_squash`(默认)：访问用户先与本机用户匹配，匹配失败后再映射为匿名用户或用户组
    - `sync`(默认)：同步模式，内存中数据时时写入磁盘
    - `async`：不同步模式
    - `subtree_check`(默认)：若输出目录是一个子目录，则nfs服务器将检查其父目录的权限
    - `no_subtree_check`：即使输出目录是一个子目录，nfs服务器也不检查其父目录的权限，这样可以提高效率

## yum直接安装

- `yum -y install memcached` 安装memcached(默认端口11211)
- `yum -y install git` 安装git
- `yum install jq` shell读取json数据
    - `jq .subjects[0].casts[0] douban.json`
    - `curl -s https://douban.uieee.com/v2/movie/top250?count=1 | jq .subjects[0].casts[0]`




---

参考文章

[^2]: https://www.cnblogs.com/LiuChunfu/p/8052890.html
[^3]: http://blog.csdn.net/inslow/article/details/54177191 (更换yum镜像)
[^4]: https://www.cnblogs.com/taosim/articles/2649098.html (安装oracle客户端)
[^5]: https://www.cnblogs.com/zeng1994/p/f883e0a2832808455039ff83735d6579.html (Linux下安装解压版（tar.gz）MySQL5.7)
[^6]: https://www.cnblogs.com/shizhongyang/p/8464876.html (cd: /usr/local/mysql: No such file or directory)
[^7]: https://www.cnblogs.com/sexiaoshuai/p/8399599.html
[^8]: http://xstarcd.github.io/wiki/sysadmin/ntpd.html
