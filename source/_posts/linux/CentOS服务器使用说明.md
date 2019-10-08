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
- 查看磁盘分区和挂载，项目建议放到数据盘(阿里云单独购买的数据盘需要格式化才可使用)。[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux-system/](/_posts/linux/linux-system.md#磁盘)
- 校验系统时间(多个服务器时间同步可以通过xshell发送到所有会话)
    - 校验时区：如`Tue Jul  2 21:26:09 CST 2019`和`Tue Jul  2 21:26:09 EDT 2019`，其中北京时间的时区为`CST`
        - `mv /etc/localtime /etc/localtime.bak`
        - `ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime` 修改成功后之前的日志是无法同步修改的
        - `date`
    - 校验时间
        - `date` 查看时间
        - `date -s "2019-04-07 10:00:00"` 设置时间
        - `hwclock -w` 将时间写入bios避免重启失效
- 添加用户、修改密码、设置sudo权限、su免密码：[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux-system/](/_posts/linux/linux-system.md#权限系统)
- 设置用户umask值为0022(包括root用户)：[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux-system/](/_posts/linux/linux-system.md#文件权限)
- 证书登录、禁用root及密码登录：[linux系统：http://blog.aezo.cn/2016/07/21/linux/linux-system/](/_posts/linux/linux-system.md#ssh)
- 修改hostname：`hostnamectl --static set-hostname aezocn` 修改主机名并重启
- 更换镜像，见下文
- `yum update` 更新软件版本和内核次版本。初始化机器可执行，生成环境不建议重复更新内核版本
    - `yum upgrade` 只更新软件版本，不更新内核版本

### 新服务器常见问题

- centos7无法使用`ifconfig`命令解决方案
    - 确保有`/sbin/ifconfg`文件，否则安装net-tools(`yum -y install net-tools`)，即可使用netstat、ifconfig等命令
    - 有则此文件则在`vi /etc/profile`中加`export PATH=$PATH:/usr/sbin`，并执行`source /etc/profile`使之生效
- xshell卡死在`To escape to local shell, press 'Ctrl+Alt+]'.`
    - 关闭防火墙
    - `vi /etc/ssh/sshd_config` 修改 `# UseDNS yes` 为 `UseDNS no`，并重启sshd

## 内核升级 [^7]

- **Centos7 默认使用内核版本为`3.10`**，目前内核长期支持版为`4.4`，主线稳定版为`5.2`
- 内核版本的定义
    - 版本性质：主分支ml(mainline)，稳定版(stable)，长期维护版lt(longterm)
    - 版本命名格式为 "A.B.C"
        - A 是内核版本号：第一次是1994年的 1.0 版，第二次是1996年的 2.0 版，第三次是2011年的 3.0 版发布
        - B 是内核主版本号：奇数为开发版，偶数为稳定版
        - C 是内核次版本号
- Centos7升级内核步骤

```bash
## 查看版本
# uname -r
3.10.0-514.el7.x86_64
# cat /etc/redhat-release 
CentOS Linux release 7.3.1611 (Core)

## 需要先导入elrepo的key，然后安装elrepo的yum源
rpm -import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

## 安装(也可以把kernel image的rpm包下载下来手动安装)
# 查看可用稳定版本
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
# 安装长期支持版
yum -y --enablerepo=elrepo-kernel install kernel-lt.x86_64 kernel-lt-devel.x86_64

## 修改grub中默认的内核版本
# 查看所有内核版本，第一行则内核索引为0，以此类推
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg
# 修改默认启动内核版本。将 `GRUB_DEFAULT=saved` 改成 `GRUB_DEFAULT=0`(此处0表示新安装的内核索引)
vi /etc/default/grub
# 重新创建内核配置
grub2-mkconfig -o /boot/grub2/grub.cfg
# 重启
reboot
```

## 常用软件安装

- 自定义服务参考[http://blog.aezo.cn/2017/01/16/arch/nginx/](/_posts/arch/nginx.md#基于编译安装tengine)

### 安装方式说明 [^2]

#### 镜像管理

- 更换镜像源

    ```bash
    # 查看yum的配置文件，其中`CentOS-Base.repo`为镜像列表配置。**可更换镜像列表** [^3]
    cd /etc/yum.repos.d
    # 需要确保已经安装`wget`(也可使用curl下载)
    yum -y install wget
    # 备份
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    # 基础源，下载阿里云镜像
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    # 安装EPEL源(新增镜像源)
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    # 生成缓存
    yum makecache
    ```
- 新增镜像源

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
- 安装`EPEL`(Extra Packages for Enterprise Linux)。epel它是RHEL 的 Fedora 软件仓库，为 RHEL 及衍生发行版如 CentOS、Scientific Linux 等提供高质量软件包的项目。如nginx可通过epel安装
    - 下载epel源(可使用上述阿里云镜像) `wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm` (http://fedoraproject.org/wiki/EPEL)
    - 安装epel `rpm -ivh epel-release-latest-7.noarch.rpm`

#### rpm安装(软件包管理器)

- `rpm`格式文件安装(redhat package manage。有依赖关系，安装和卸载也有先后顺序)
    - RPM包的命名规范：`name-version-release.os.arch.rpm`
        - os：即说明RPM包支持的操作系统版本。如el6(即rhel6)、centos6、el5、suse11
        - arch：主机平台。如i686、x86_64、amd64、ppc(power-pc)、noarch(即不依赖平台)
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

- `yum`安装：`yum install xxx`(基于包管理工具安装，可以更好的解决包依赖关系)
- yum常用命令
    - `yum -y install nginx` 安装时回答全部问题为是
    - `yum remove nginx` **卸载**
    - `yum search vsftpd` 查找软件vsftpd源

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

### 安装jdk

#### 下载/上传jdk文件

> 默认登录时候在 root 目录，直接下载和解压，软件包和解压目录都默认在 root 目录，可以切换到 hoom 目录进行下载

- 通过ftp上传jdk对应tar压缩包到对应目录并进行解压
- 下载tar格式（推荐）
  - 下载tar文件并上传到服务器
  - 解压tar **`tar -zxvf jdk-7u80-linux-x64.tar.gz -C /opt/soft`** （需要先创建好/opt/soft目录）
- 下载rpm格式
  - 获取rpm链接（下载到本地后上传到服务器）： oracle -> Downloads -> Java SE -> Java Archive -> Java SE 7 -> Java SE Development Kit 7u80 -> Accept License Agreement -> jdk-7u80-linux-x64.rpm
  - `rmp -ivh jdk-7u80-linux-x64.rpm` 安装rpm文件

#### 配置环境变量

- `vi /etc/profile` 使用vi打开profile文件(也可在`.bash_profile`中设置单个用户的环境变量)
- 在末尾输入并保存（注意JAVA_HOME需要按照实际路径）

```bash
export JAVA_HOME=/opt/soft/jdk1.7.0_80
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

- yum安装(安装时无法自定义文件存储路径，但是安装完成后可手动移动数据文件到新目录。`yum install mysql`无法选定版本)

    ```bash
    # 下载mysql源安装包
    wget http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
    # 安装mysql源
    yum localinstall mysql57-community-release-el7-8.noarch.rpm
    # 检查mysql源是否安装成功
    yum repolist enabled | grep "mysql.*-community.*"
    # 安装mysql
    yum install mysql-community-server
    # 启动
    systemctl start mysqld
    # 查看临时密码
    grep 'temporary password' /var/log/mysqld.log
    # 登录
    mysql -uroot -p
    # 修改密码(mysql5.7密码必须包含大小写字母、数字和特殊符号，并且长度不能少于8位)
    alter user 'root'@'localhost' identified by 'mynewpass4!';
    # 添加smalle用户，并赋权，且允许远程登录
    grant all privileges on *.* to 'smalle'@'%' identified by 'Hello1234!' with grant option;
    flush privileges;
    # 设置开机启动
    systemctl enable mysqld
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
- 其他
    - 卸载yum方式安装
        - `yum remove mysql` 卸载
        - `find / -name mysql` 查看和mysql相关文件/文件夹
            - `rm -rf xxx` 删除
        - `rpm -qa | grep -i mysql` 查看mysql的依赖
            - `yum remove mysql-xxx` 依次卸载
        - 删除mysql相关用户和组。`userdel -rf mysql`(包括删除家目录)，`groupdel mysql`
    - `show variables like '%dir%';` sql命令查看mysql相关文件(数据/日志)存放位置
        - 数据文件默认位置：`/var/lib/mysql`
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
    - 下载`Python-3.6.4.tar.xz`(`curl -O https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tar.xz`)
    - `tar xvf  Python-3.6.4.tar.xz -C /opt`
    - `cd Python-3.6.4`
    - `su root` 切换root用户
    - `./configure`
    - `make && make install` 第一次需要大概15分钟。需要使用root运行。使用sudo运行也会报错`cannot create regular file ‘/usr/local/bin/python3.6m’: Permission denied`
    - `python3` 查看是否安装成功
    - `pip3` 为对应的pip命令
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
set from=aezocn@163.com
set smtp=smtp.163.com
set smtp-auth-user=aezocn@163.com
# 授权密码，不是登录密码
set smtp-auth-password=xxx
set smtp-auth=login
EOF
# 测试发送(163邮箱容易出现554检测到垃圾拒发问题，此处使用-c抄送给自己可解决)
echo "test mail..." | mail -s "hello subject" -c aezocn@163.com oldinaction@163.com
```
- 安装**postfix(centos7已内置安装并启动)**或者sendmail等邮件发送服务(此方法发送的邮件容易进入垃圾箱)

```bash
# yum install -y postfix
# systemctl enable postfix && systemctl restart postfix && systemctl status postfix
# 安装mailx。此方式无需设置smtp等也可发送邮件(如果mail.rc设置了smtp则优先使用配置的smtp)
echo "zabbix test mail" | mail -s "zabbix" oldinaction@163.com
# 可以看到手动一封来自 `root<root@node1.localdomain>`的邮件，其中node1为服务器名
```

### yum直接安装

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

