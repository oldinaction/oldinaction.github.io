---
layout: "post"
title: "ftp"
date: "2019-03-19 10:40"
categories: devops
tags: [server]
---

## FTP简介

- ftp/sftp是协议
- vsftpd/pure-ftpd是ftp服务器(只支持ftp协议)
- xftp/ftp(yum install ftp)是ftp客户端
- `sftp localhost` 输入密码后登录ftp
    - exit退出(无需安装vsftp，一般服务器都默认支持，相当于windows用xftp以sftp形式登录ftp服务器)

## FTP客户端

- Centos下的ftp客户端(和window下的xftp类似)

```bash
## 安装ftp客户端
yum install ftp
ftp -h # 查看帮助 
## 连接(默认是被动模式)
ftp localhost
ftp -A localhost 21 # 主动模式连接
## 连接后相关命令
# 显示帮助
help
# ftp命令行退出
bye
# 列举文件
ls
# 目录切换
cd
# 引入被动模式。可用于重启被动模式
quote pasv
# 开启/关闭被动模式，再次输入此命令可回到上一模式
passive
```

## FTP服务器

- 主动模式(`PORT`)和被动模式(`PASV`)
    - 主动模式(**服务器只需要开发21、20端口，需要客户端允许>1024的端口被访问。**服务器管理方便，对客户端不友好，客户端必须放开相应防火墙)
        - 命令连接：客户端 >1024 端口 → 服务器 21 端口
        - 数据连接：客户端 >1024 端口 ← 服务器 20 端口(服务器通过20端口向客户端发起连接)
    - 被动模式(**服务器需要开放21、大于1024的一批端口**，客户端无需开放端口。对客户端友好)
        - 命令连接：客户端 >1024 端口 → 服务器 21 端口
        - 数据连接：客户端 >1024 端口 → 服务器 >1024 端口(服务器开发端口，告诉客户端主动来连接FTP服务器的某个端口，相对服务器是被动。此时每个连接服务器需要开放一个端口)
- 客户端超时未发送命令，服务器会自动关闭连接

### vsftpd

- 即使使用被动模式，客户端也可以通过切换成主动模式进行连接. 此时服务器无需额外开发20的数据端口。谷歌浏览器/文件管理器会自动切换模式，而xftp客户端需要进行设置成主动模式连接。(如：服务器设置了被动模式，但是没有设置pasv_address导致客户端只能通过主动模式连接)

#### 安装 [^1]

- 安装`yum install vsftpd`
- 启动服务`systemctl start vsftpd`(修改主配置需要重启服务)
- IE浏览器访问`ftp://192.168.1.1`失败(部分浏览器只支持主动模式)。谷歌浏览器正常访问并使用，或者ftp客户端登录

#### 配置

- `cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.back`
- `vim /etc/vsftpd/vsftpd.conf`
- 常用配置(直接清空原配置)

    ```bash
    #允许执行FTP命令，如果禁用，将不能进行上传、下载、删除、重命名等操作
    write_enable=YES
    #本地用户umask值
    local_umask=022
    dirmessage_enable=YES
    #启用日志
    dirmessage_enable=YES
    xferlog_enable=YES # 默认的日志文件位置为/var/log/xferlog
    xferlog_std_format=YES
    #使用ipv4进行监听
    listen=YES
    listen_ipv6=NO

    # ***.使用本地时区
    use_localtime=yes
    #pam认证文件名称，位于/etc/pam.d/目录
    #`/etc/vsftpd/ftpusers`中为禁止登录ftp的用户(黑名单) [^2]
    pam_service_name=vsftpd
    #启用tcp封装
    tcp_wrappers=YES
    #对vsftpd有用，否则因home目录权限为root权限而无法登录
    allow_writeable_chroot=YES

    # ***.不允许匿名登录(NO, YES允许)
    anonymous_enable=NO
    # ***.禁止匿名用户上传
    anon_upload_enable=NO
    #启用本地系统用户，包括虚拟用户. 基于虚拟用户的访问必须加上次配置，使用真实用户(宿主用户)访问可进行关闭
    local_enable=YES

    # chroot_local_user=YES限制用户不能离开FTP主目录，chroot_list_enable=YES启用并设置例外用户，此时chroot_list_file为例外的用户名(即可以登出主目录的)
    # chroot_local_user=NO允许用户浏览主目录的上级目录，chroot_list_enable=YES启用并设置例外用户，chroot_list_file为例外的用户名(即不可登出主目录)
    chroot_local_user=YES
    chroot_list_enable=YES
    chroot_list_file=/etc/vsftpd/chroot_list

    #限定可登录用户列表
    userlist_enable=YES
    # userlist_deny=NO 表示默认所有用户都不能登录，userlist_file列表中用户名为例外列表(可登录白名单)
    # userlist_deny=YES 表示所有用户都能登录，userlist_file列表中用户名为例外列表(不可登录黑名单)
    userlist_deny=YES
    userlist_file=/etc/vsftpd/user_list

    # ***.vsftpd服务器的外网IP（否则卡死在`227 Entering Passive Mode`，但是可以通过主动模式连接）
    pasv_address=192.168.1.1
    # ***.监听端口21，需要开放对应端口防火墙
    #listen_port=21
    # ***.NO表示关闭ftp-data端口，相当于不使用主动模式. 如果是主动模式则需要开启，且防火墙需要开放20端口
    connect_from_port_20=NO
    # ***.开启pasv模式，否则有些客户端登录会有问题，同时在防火墙中必须开启设定的端口，防火墙要开放30000-30999的端口
    pasv_enable=YES
    pasv_min_port=30000
    pasv_max_port=30999

    ### 使用虚拟用户才需要
    #虚拟用户权限是否与本地用户相同。为NO时表示将与匿名用户的权限相同，可在每个虚拟用户配置文件里设置此虚拟用户的权限(相当于在相应用户配置中针对匿名用户权限进行配置，即是对虚拟用户权限进行配置)
    virtual_use_local_privs=NO
    #启用guest后，所有非匿名用户将映射到guest_username进行访问。此时宿主用户时无法直接登录的
    guest_enable=YES
    guest_username=vsftp
    #设定虚拟用户个人vsftp的配置文件存放路径
    user_config_dir=/etc/vsftpd/vuser_conf.d
    ```

#### 设置用户

- 法一：使用系统用户(应用程序内部使用推荐))

    ```bash
    # 默认的vsftpd的服务宿主用户是root，但是这不符合安全性的需要。这里建立名字为ftpadmin的用户，用他来作为支持vsftpd的服务宿主用户。由于该用户仅用来支持vsftpd服务用，因此没有许可他登陆系统的必要，并设定他为不能登陆系统的用户（-s /sbin/nologin）。并设置ftpadmin的家目录为/home/ftproot(做为ftp服务器的根目录)
    useradd ftpadmin -d /home/ftproot -s /sbin/nologin
    # 给ftpadmin设置密码
    passwd ftpadmin
    # 文件/home/ftproot的所有者是ftpadmin，设置权限为755，包含子目录。755当前用户有读写权限，当前组和其他组只有读权限；555当前用户有读权限。不能设置成444，必须要读权限和执行权限
    chmod -R 755 /home/ftproot
    # 默认用户家目录就属于此用户
    # chown -R ftpadmin /home/ftproot
    ```
- 法二：设置虚拟用户(每个虚拟用户独立一个用户配置. 推荐) [^3] [^4]

    ```bash
    # 创建vsftpd虚拟宿主用户(vsFTPd出于安全考虑，是不准让ftp用户的家目录的权限是完全没有限制的，一般默认即可，可设置成755)
    useradd vsftp -d /home/vsftp -s /sbin/nologin
    passwd vsftp

    # 设置虚拟用户列表并编译
    vi /etc/vsftpd/vuser # 奇行为用户名，偶行为密码。如虚拟用户名为`v_test`
    db_load -T -t hash -f /etc/vsftpd/vuser /etc/vsftpd/vuser.db # 编译vuser文件为数据库文件。CentOS7是libdb-utils(默认已安装)：`yum -y install libdb-utils`
    chmod 600 /etc/vsftpd/vuser.db
    
    # 虚拟用户认证配置
    cp /etc/pam.d/vsftpd{,.bak} # 相当于备份vsftpd为vsftpd.bak
    vi /etc/pam.d/vsftpd # 清空之前配置，只加入下列配置. 此处/etc/pam.d/vsftpd文件名对应主配置中的pam_service_name=vsftpd
    `
    auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser
    account required /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser
    `

    # 虚拟用户配置文件
    mkdir /etc/vsftpd/vuser_conf.d/
    vi /etc/vsftpd/vuser_conf.d/v_test #文件名与对应FTP虚拟用户一致
    # local_root为虚拟用户主目录，此目录的用户和组必须指定为宿主用户vsftp
    # vsftpd主配置文件中已规定虚拟用户权限与匿名用户一致(virtual_use_local_privs=NO)，且全局配置已定义匿名用户无法登录和上次，因此以下针对匿名用户的权限配置即为此虚拟用户的权限
    `
    local_root=/home/vsftp/v_test
    anon_umask=022
    anon_upload_enable=YES
    anon_world_readable_only=NO
    anon_mkdir_write_enable=YES
    anon_other_write_enable=YES
    `
    # 虚拟用户主目录和权限
    # 为了安全考虑设置，去掉宿主目录w权限
    chmod -R 555 /home/vsftp
    # 用户目录赋予700权限，所有上传、下载、删除、重命名等操作只能在此虚拟用户目录进行
    mkdir -p /home/vsftp/v_test
    chown -R vsftp.vsftp /home/vsftp/v_test
    chmod 700 /home/vsftp/v_test
    ```
    - 添加新用户。添加用户脚本参考 [http://blog.aezo.cn/2017/01/10/linux/shell/](/_posts/linux/shell.md#创建vsftpd虚拟账号)

        ```bash
        vi /etc/vsftpd/vuser # 奇行为用户名，偶行为密码。如虚拟用户名为`v_test`。注意：经过测试，此用户文本中可能任意两行都可以当成用户名，且直接可以查看vsftp根目录文件，尚未找到具体原因
        
        # ***.设置虚拟用户配置(不设置即为宿主用户配置，上述配置宿主用户时无法登录的)
        # 如果需要基于虚拟用户创建一个管理用户。可创建此虚拟用户配置文件夹，但是不配置其local_root，则此用户的根目录即为宿主用户目录
        vi /etc/vsftpd/vuser_conf.d/v_test

        # 设置虚拟用户目录
        mkdir -p /home/vsftp/v_test
        chown -R vsftp.vsftp /home/vsftp/v_test
        # chmod 755 /home/vsftp/v_test

        sudo db_load -T -t hash -f /etc/vsftpd/vuser /etc/vsftpd/vuser.db
        ```
    - 虚拟用户详细配置说明（vsftpd主配置文件中已规定虚拟用户权限与匿名用户一致virtual_use_local_privs=NO，且全局配置已定义匿名用户无法登录和上次，因此以下针对匿名用户的权限配置即为此虚拟用户的权限）。部分配置修改后需要重启服务

        ```bash
        # 指定虚拟用户的具体主路径
        local_root=/var/www/html
        # 设定上传文件权限掩码，默认077
        anon_umask=022
        # 下面这四个主要语句控制这文件和文件夹的上传、下载、创建、删除和重命名。修改下面的配置需要重启
        # 控制匿名用户对文件（非目录）上传权限
        anon_upload_enable=YES
        # 控制匿名用户对文件的下载权限(YES表示此文件的u+o都有读权限才可下载，NO表示此文件的u有读权限就可下载)
        anon_world_readable_only=NO
        # 控制匿名用户对文件夹的创建权限(NO不允许创建文件夹)
        anon_mkdir_write_enable=NO
        # 控制匿名用户对文件和文件夹的删除和重命名。NO则用户无法移动文件
        anon_other_write_enable=YES
        # cmds_allowed=... # 还可通过此参数来配置，不太好用
        
        ## 未测试
        # 设定并发客户端访问个数. 0时表示不限制
        max_clients=10
        # 设定单个客户端的最大线程数，这个配置主要来照顾Flashget、迅雷等多线程下载软件
        max_per_ip=5
        # 设定该用户的最大传输速率，单位b/s
        local_max_rate=500000 # 500kb/s
        ```
- 也可基于MYSQL验证的vsftpd虚拟用户 [^4]

#### 单用户多目录配置

- vsftpd不支持软连接，硬链接又不允许将硬链接指向目录。可以通过`mount –bind`解决(默认存于内存，需要写到`/etc/rc.local`，否则开启需要重新执行命令)
- `vim /etc/rc.local`

    ```bash
    # 可读写挂载：将/home/test1/(真实目录)的目录映射到/data/www/virtual/test1/(映射目录)。需要先创建好目录 /data/www/virtual/test1/
    mount --bind /home/test1/ /data/www/virtual/test1/

    # 只读挂载
    mount --bind /home/test2/ /data/www/virtual/test2/
    mount -o remount,ro /data/www/virtual/test2/
    ```
- `source /etc/rc.local` 使生效(可能会报`mount: / is busy`，但是应该挂载上了)

#### 基于docker安装

> https://github.com/fauria/docker-vsftpd

```bash
## 如果要设置配置文件目录较麻烦
## 主动模式
docker run -d -p 21:21 -v /my/data/directory:/home/vsftpd -e FTP_USER=test -e FTP_PASS=test --name vsftpd fauria/vsftpd
## 被动模式
# PASV_ADDRESS：默认Docker host IP / Hostname
# PASV_MIN_PORT~PASV_MAX_PORT：给客服端提供下载服务随机端口号范围，默认 21100~21110，与前面的 docker 端口映射设置成一样
docker run -d -v /my/data/directory:/home/vsftpd \
-p 20:20 -p 21:21 -p 21100-21110:21100-21110 \
-e FTP_USER=test -e FTP_PASS=test \
--name vsftpd --restart=always fauria/vsftpd
# 启动后访问：ftp://test:test@192.168.6.131:21
```
- 基于k8s
    - 共享主机网络主被动模式都可正常使用，可临时测试。不使用共享主机网络主被动均未测试成功
    - 测试步骤
        - 配置文件如`sq-ftp.yaml`，使用了rook-ceph进行存储，具体参考[rook-ceph](/_posts/devops/rook-ceph.md简单使用)
        - `kubectl get pods -o wide` 查看pod被调度到那个k8s-node节点(如：192.168.6.133)，然后使用`ftp 192.168.6.133`连接

```yml
# sq-ftp.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sq-rook-ceph-pvc
  namespace: default
spec:
  storageClassName: rook-ceph-block-ftp
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sq-ftp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sq-ftp
  template:
    metadata:
      labels:
        app: sq-ftp
    spec:
      volumes:
      - name: ftp-data
        persistentVolumeClaim:
          claimName: sq-rook-ceph-pvc
      containers:
      - name: sq-ftp
        image: fauria/vsftpd
        volumeMounts:
        - mountPath: "/home/vsftpd"
          name: ftp-data
        env:
        - name: FTP_USER
          value: "test"
        - name: FTP_PASS
          value: "test"
      hostNetwork: true
```

---

参考文章

[^1]: http://www.cnblogs.com/hhuai/archive/2011/02/12/1952647.html (vsftpd)
[^2]: http://www.cnblogs.com/GaZeon/p/5393853.html (ftp-530-Permission-denied)
[^3]: https://www.cnblogs.com/st-jun/p/7743255.html
[^4]: https://www.cnblogs.com/xsuid/p/9537235.html