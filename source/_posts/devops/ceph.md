---
layout: "post"
title: "Ceph"
date: "2019-11-14 09:38"
categories: devops
tags: [k8s, storage]
---

## 简介

- [Ceph官网](https://ceph.com/)、[官方文档 v14.2.4 Nautilus](https://docs.ceph.com/docs/nautilus/start/intro/)、[官方中文文档](http://docs.ceph.org.cn/)、[github源码](https://github.com/ceph/ceph)
- Ceph 提供3种存储类型 [^1]
    - 块存储(`RBD`)
        - 典型设备： 磁盘阵列，硬盘。主要是将裸磁盘空间映射给主机使用的
        - 优点：多块廉价的硬盘组合起来提高容量；缺点：主机之间无法共享数据
        - 使用场景：docker容器、日志、文件
        - RBD是Ceph面向块存储的接口。这种接口通常以 QEMU Driver 或者 Kernel Module 的方式存在，这种接口需要实现 Linux 的 Block Device 的接口或者 QEMU 提供的 Block Driver 接口
        - 相关块存储：Ceph 的 RBD、AWS 的 EBS、阿里云的盘古系统。在常见的存储中 DAS、SAN 提供的也是块存储
        - `GlusterFS` 只提供对象存储和文件系统存储，而 `Ceph` 则提供对象存储、块存储以及文件系统存储
    - 文件存储
        - 典型设备：FTP、NFS服务器。为了克服块存储文件无法共享的问题，所以有了文件存储
        - 优点：方便文件共享；缺点：读写速率低
        - 使用场景：日志、有目录结构的文件存储
        - 通常意义是支持 POSIX 接口，它跟传统的文件系统如 Ext4 是一个类型的，但区别在于分布式存储提供了并行化的能力。如 Ceph 的 CephFS(CephFS是Ceph面向文件存储的接口)，但是有时候又会把 GlusterFS、HDFS 这种非POSIX接口的类文件存储接口归入此类。当然 NFS、NAS也是属于文件系统存储
    - 对象存储
        - 典型设备：内置大容量硬盘的分布式服务器(Swift 、S3 以及 Gluster)
        - 优点：具备块存储的读写高速，具备文件存储的共享等特性
        - 使用场景：适合更新变动较少的数据，如：图片存储、视频存储
        - 也就是通常意义的键值存储，其接口就是简单的GET、PUT、DEL 和其他扩展
- Ceph 组件及概念 [^1]
    - Ceph核心组件包括：Ceph OSDs、Monitors、Managers、MDSs。Ceph存储集群至少需要一个Ceph Monitor，Ceph Manager和Ceph OSD。使用Ceph Filesystem文件存储时也需要Ceph元数据服务器(Metadata Server)；使用对象存储则另需要部署rgw(Gateway)

    ![ceph组件](/data/images/devops/ceph.png)
    - **`Monitor`**：负责监视整个集群的运行状况，信息由维护集群成员的守护程序来提供
        - Ceph Monitor(ceph-mon)维护着展示集群状态的各种图表，包括监视器图、OSD 图、归置组(PG)图、和 CRUSH 图。 Ceph 保存着发生在Monitors、OSD 和 PG上的每一次状态变更的历史信息(称为 epoch)。监视器还负责管理守护进程和客户端之间的身份验证。冗余和高可用性通常至少需要3个监视器
        - 不存储任何数据，主要包含以下Map
            - `Monitor map`：包括有关monitor 节点端到端的信息，其中包括 Ceph 集群ID，监控主机名和IP以及端口。并且存储当前版本信息以及最新更改信息，通过 `ceph mon dump` 查看 monitor map
            - `OSD map`：包括一些常用的信息，如集群ID、创建OSD map的 版本信息和最后修改信息，以及pool相关信息，主要包括pool 名字、pool的ID、类型，副本数目以及PGP等，还包括数量、状态、权重、最新的清洁间隔和OSD主机信息。通过命令 `ceph osd dump` 查看
            - `PG map`：包括当前PG版本、时间戳、最新的OSD Map的版本信息、空间使用比例，以及接近占满比例信息，同时包括每个PG ID、对象数目、状态、OSD 的状态以及深度清理的详细信息。通过命令 `ceph pg dump` 可以查看相关状态
            - `CRUSH map`： 包括集群存储设备信息，故障域层次结构和存储数据时定义失败域规则信息。相关命令`ceph osd crush xxx`
            - `MDS map`：包括存储当前 MDS map 的版本信息、创建当前的Map的信息、修改时间、数据和元数据POOL ID、集群MDS数目和MDS状态，可通过 `ceph mds dump` 查看
    - **`OSDs`**(Object Storage Device/Daemon)
        - Ceph OSD 守护进程(ceph-osd)的功能是存储数据，处理数据的复制、恢复、回填、再均衡，并通过检查其他 OSD 守护进程的心跳来向 Ceph Monitors 提供一些监控信息。冗余和高可用性通常至少需要3个Ceph OSD。当 Ceph 存储集群设定为有2个副本时，至少需要2个 OSD 守护进程，集群才能达到 active+clean 状态(Ceph 默认有3个副本)
        - 是由物理磁盘驱动器、在其之上的 Linux 文件系统以及 Ceph OSD 服务组成。Ceph OSD 将数据以对象的形式存储到集群中的每个节点的物理磁盘上，完成存储数据的工作绝大多数是由 OSD daemon 进程实现。在构建 Ceph OSD的时候，建议采用SSD 磁盘以及xfs文件系统来格式化分区
    - **`Managers`**: Ceph Manager守护进程(ceph-mgr)负责跟踪运行时指标和Ceph集群的当前状态，包括存储利用率，当前性能指标和系统负载。Ceph Manager守护进程还托管基于python的插件来管理和公开Ceph集群信息，包括基于Web的Ceph Manager Dashboard和 REST API。高可用性通常至少需要2个管理器
    - **`MDS`**(Ceph Metadata Server)：Ceph 元数据服务器(MDS)为 Ceph 文件系统存储元数据(也就是说，Ceph 块设备和 Ceph 对象存储不使用MDS)。元数据服务器使得 POSIX 文件系统的用户们，可以在不对 Ceph 存储集群造成负担的前提下，执行诸如 ls、find 等基本命令
    - **`RADOSGW`(`rgw`)**：对象网关(Gateway)守护进程，提供对象存储服务。使用对象存储则另需要部署
    - `RADOS`(Reliable Autonomic Distributed Object Store)：RADOS是ceph存储集群的基础。在ceph中，所有数据都以对象的形式存储，并且无论什么数据类型，RADOS对象存储都将负责保存这些对象。RADOS层可以确保数据始终保持一致
    - `librados` 和 RADOS 交互的基本库，为应用程度提供访问接口。同时也为块存储、对象存储、文件系统提供原生的接口。Ceph 通过原生协议和 RADOS 交互，Ceph 把这种功能封装进了 librados 库，这样也能定制自己的客户端
    - `ADOS块设备`：能够自动精简配置并可调整大小，而且将数据分散存储在多个OSD上
    - `CephFS`：Ceph文件系统，与POSIX兼容的文件系统，基于librados封装原生接口
    - `Pool` 是存储空间的逻辑划分，一个集群可以分成多个Pool。Pool与数据安全策略相联系，定义池就要同时定义出Pool的pg数量和数据冗余策略(副本数和纠删码，以及使用的crush规则)
    - `PG`(Placement Grouops)：是ceph的逻辑存储单元

## 手动安装(基于ceph-deploy安装)

> https://github.com/ceph/ceph-deploy/tree/v2.0.1

1. 准备工作(所有节点运行)

```bash
# node1(192.168.6.131)  mon osd mgr deploy(部署节点)
# node2(192.168.6.132)  mon osd
# node3(192.168.6.133)  mon osd

## 所有节点运行
yum update -y
# 时间同步。建议参考 [NTP](/_posts/linux/CentOS服务器使用说明.md#NTP(Network%20Time%20Protocol))
sudo yum install -y ntp ntpdate ntp-doc
sudo ntpdate 0.cn.pool.ntp.org
```
2. 安装ceph-deploy(deploy节点运行)

```bash
# 添加 Ceph 源。baseurl中的`rpm-nautilus`可换成`rpm-其他ceph版本`
cat > /etc/yum.repos.d/ceph.repo << EOM
[Ceph]
name=Ceph packages for x86_64
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/x86_64/
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

[Ceph-noarch]
name=Ceph noarch packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/noarch/
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/SRPMS/
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
EOM
yum clean all && yum makecache
# 安装ceph-deploy
mkdir /opt/ceph-cluster && cd /opt/ceph-cluster
yum -y install ceph-deploy
ceph-deploy --version # 2.0.1
# 配置deploy节点免密钥登录其他节点
```
3. 安装Storage Cluster(deploy节点运行)

```bash
# 参考：https://docs.ceph.com/docs/nautilus/start/quick-ceph-deploy/#create-a-cluster
# 初始化一个集群(会在当前目录创建ceph.conf，即将以下节点做为mon节点；还会创建keyring文件)
ceph-deploy new node1 node2 node3
# 安装ceph(会创建/var/lib/ceph/目录)。有可能其中某个节点因为下载rpm Timeout导致安装失败可重新install该节点，安装成功的可执行`ceph --version`查看版本
# 如果出现错误`No data was received after 300 seconds`，可检查yum源是否正确，如果确认为阿里云可重试几次
ceph-deploy install --release nautilus node1 node2 node3
# ceph-deploy install --release nautilus node4 # 新增Ceph Node直接执行此命令即可（无需new）

# 开始部署monitor(会自动启动ceph-mon，监听在6789端口)
ceph-deploy mon create-initial
# 拷贝配置文件和admin的秘钥到相应节点(会复制keying到/etc/ceph目录，可多次运行)，从而该节点可使用ceph CLI
ceph-deploy admin node1 node3
ceph -s # 查看集群状态(ceph)。mon: 3 daemons, quorum node1,node2,node3 (age 7m)

# 部署mgr
ceph-deploy mgr create node1
ceph -s # mgr: node1(active, since 47s)

# (可选)部署mds。如果使用CephFS才需要
ceph-deploy mds create node1 # {0=node1=up:creating}

# (可选)部署rgw(Gateway)。如果使用对象存储才需要
ceph-deploy install --rgw node1

# (可选)扩展mon、mgr。测试可跳过
ceph-deploy mon add node2
ceph-deploy mgr create node3

# 创建OSD(本质是基于ceph-volume进行创建，也可到各个节点上直接运行ceph-volume相关命令)。此处/dev/sdb为物理连接上去的空磁盘，ceph会自动进行分区
ceph-deploy osd create --data /dev/sdb node1
ceph-deploy osd create --data /dev/sdb node2
ceph-deploy osd create --data /dev/sdb node3
# 如果在LVM卷上创建OSD，那么--data的参数必须是volume_group/lv_name，而不是块设备的路径

ceph -s # osd: 3 osds: 3 up (since 20s), 3 in (since 20s)
lsblk # 在OSD节点上运行查看磁盘分区，会发现有一个`ceph--a3202c2d-xxx`的lvm分区
# 在各节点执行可查看ceph相关服务状态
systemctl status ceph*
```
4. (可选)启用Dashboard(mgr节点运行)

```bash
yum install ceph-mgr-dashboard
# 启用模块
ceph mgr module enable dashboard
# 安装证书
ceph dashboard create-self-signed-cert
# 创建具有管理员角色的用户和密码
ceph dashboard set-login-credentials admin admin
# 查看ceph-mgr服务
ceph mgr services
# 访问 https://192.168.6.131:8443 使用 admin/admin 登录
```

- 安装失败可进行清理环境后重新安装

```bash
ceph-deploy purge node1 node2 node3 # 如果执行purge，则需要重新对该节点安装ceph
ceph-deploy purgedata node1 node2 node3 # 删除各节点的/var/lib/ceph、/etc/ceph目录
# 删除deploy节点集群数据
ceph-deploy forgetkeys
rm -f ceph.* # 移除/opt/ceph-cluster目录配置文件
```

## 简单使用

### 块设备使用(rbd)

- ceph集群外机器(客户端)使用ceph的rbd存储
    - `yum install -y ceph-common` 安装rbd操作工具(参考上文增加rpm源配置)
    - 将ceph服务器的`/etc/ceph/`目录下的集群配置文件`ceph.conf`和客户端秘钥文件`ceph.client.admin.keyring`复制到客户端机器的`/etc/ceph`目录

- 以集群内机器为例

```bash
# 块设备使用。参考：https://docs.ceph.com/docs/nautilus/start/quick-rbd/#create-a-block-device-pool
## **(mon节点运行)**创建并初始化pool
# 创建pool。参考：https://docs.ceph.com/docs/nautilus/rados/operations/pools/#create-a-pool
# PG数量的预估。集群中单个池的PG数计算公式如下：PG 总数 = (OSD 数 * 100) / 最大副本数 / 池数 (结果必须舍入到最接近2的N次幂的值)
ceph osd pool create mypool 128 # pool 'mypool' created。创建名为mypool的存储池
# 初始化pool
rbd pool init mypool

## **(在某个osd节点)**配置块设备
# 在mypool存储池中，创建块设备镜像myrbd，大小为4096M
rbd create myrbd --size 4096 --image-feature layering -p mypool
# 映射块设备
sudo rbd map myrbd --name client.admin -p mypool # 打印如`/dev/rbd2`
# 给此块设备创建文件系统，期间需要回车几次
sudo mkfs.ext4 -m2 /dev/rbd/mypool/myrbd # 或者 `sudo mkfs.xfs /dev/rbd2
# 挂载
sudo mount /dev/rbd2 /mnt
df -h /mnt
# 将数据写入块设备来进行检测
sudo dd if=/dev/zero of=/mnt/test count=100 bs=1M oflag=dsync # 104857600 bytes (105 MB) copied, 11.3 s, 9.3 MB/s
sudo ls -lh /mnt
```

### 文件存储使用(CephFS)

- 文件存储使用的是OSD剩余空间，和rbd没有关系
- 测试过程

```bash
# 文件存储使用(CephFS)。参考：https://docs.ceph.com/docs/nautilus/start/quick-cephfs/#create-a-filesystem
# 必须已经部署mds服务
# ceph-deploy mds create node1

### deploy节点运行
ceph osd pool create cephfs_data 128
ceph osd pool create cephfs_metadata 32
# 创建文件系统
ceph fs new myfs cephfs_metadata cephfs_data
ceph fs ls # name: myfs, metadata pool: cephfs_metadata, data pools: [cephfs_data ]

### 客户端测试(测试IP为192.168.6.130。在需要使用文件存储的普通客户端机器上操作)
mkdir /mnt/mycephfs

## 法一：使用内核驱动进行挂载，但是对内核版本等有一定要求
# 在 /opt/ceph-cluster/ceph.client.admin.keyring 中可查看secret秘钥(获通过`ceph auth get-key client.admin`命令读取)。更安全的方法是把密码保存在文件中，通过secretfile参数指定
# dmesg -T | grep ceph # 出错可通过此命令查看mount错误。如报错：`libceph: mon0 192.168.6.131:6789 missing required protocol features`，最终选用ceph-fuse进行挂载
# sudo mount -t ceph {ip-address-of-monitor1,ip-address-of-monitor2}:6789:/ /mnt/mycephfs -o name=admin,secret=xxx
sudo mount -t ceph 192.168.6.131:6789:/ /mnt/mycephfs -o name=admin,secret=AQA9BZ9dMUA7BBAAYCTiaV1cTACP7GSLDxDmBg== # 提示`ceph-fuse[14371]: starting fuse`则正确
df -h
sudo dd if=/dev/zero of=/mnt/mycephfs/test count=1024 bs=1M oflag=dsync # 测试。1073741824 bytes (1.1 GB) copied, 156.862 s, 6.8 MB/s
# 设置开机启动。此处使用秘钥文件，则需要将`AQA9BZ9dMUA7BBAAYCTiaV1cTACP7GSLDxDmBg==`保存到/etc/ceph/cephfskey
echo "192.168.6.131:6789:/ /mnt/mycephfs ceph name=admin,secretfile=/etc/ceph/cephfskey,_netdev,noatime 0 2" >> /etc/fstab

## 法二：使用ceph-fuse进行挂载
yum install ceph-fuse -y # 在客户端安装ceph-fuse程序。需要同上文一样配置Ceph源(/etc/yum.repos.d/ceph.repo)
# 将某mgr节点的ceph配置和秘钥复制到客户端
mkdir /etc/ceph
scp root@192.168.6.131:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
scp root@192.168.6.131:/etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring # chmod 600
# 在客户端运行ceph-fuse挂载
ceph-fuse --keyring /etc/ceph/ceph.client.admin.keyring --name client.admin -m 192.168.6.131:6789 /mnt/mycephfs
# 设置开机启动。需要设置ceph-fuse@/mnt/mycephfs服务自启动(设置时/mnt/mycephfs可能需要先卸载)
echo "id=admin,conf=/etc/ceph/ceph.conf /mnt/mycephfs fuse.ceph defaults 0 0" >> /etc/fstab
systemctl enable ceph-fuse.target # 必须(因为ceph-fuse服务的配置中[Install]要求ceph-fuse.target)
# 使用`ceph-fuse@/mnt/mycephfs`会报错`Failed to execute operation: Invalid argument` [^5]。会在`/etc/systemd/system/ceph-fuse.target.wants`目录创建链接文件
systemctl enable ceph-fuse@-mnt-mycephfs
systemctl start ceph-fuse@/mnt/mycephfs # 可以使用-或者/
```
- 创建不同用户和子目录来使用CephFS(上文`192.168.6.131:6789:/`使用的是根目录) [^5]

    ```bash
    ## mgr节点运行
    # 创建用户(客户端)
    ceph auth add client.aezo mon 'allow r' mgr 'allow r' osd 'allow rw pool=cephfs_data' mds 'allow rw path=/aezo'
    # 获取用户秘钥(保存在当前运行目录，如：~)
    ceph auth get-or-create client.aezo -o ceph.client.aezo.keyring
    cat ceph.client.aezo.keyring
    ceph auth get client.aezo # 获取用户权限
    # 更新用户权限
    # ceph auth caps client.aezo mon 'allow r' mgr 'allow r' osd 'allow rw pool=cephfs_data' mds 'allow rw path=/test'
    # 约束用户只能在 myfs 存储池(上文创建)的/aezo目录读写
    ceph fs authorize myfs client.aezo /aezo rw

    ## 客户端节点运行
    scp root@192.168.6.131:~/ceph.client.aezo.keyring /etc/ceph/ceph.client.aezo.keyring
    chmod 600 /etc/ceph/ceph.client.aezo.keyring
    # 创建数据目录并挂载
    mkdir /mnt/cephaezo
    chmod 1777 /mnt/cephaezo
    ceph-fuse -n client.aezo -m 192.168.6.131:6789 /mnt/cephaezo --keyring /etc/ceph/ceph.client.aezo.keyring -r /aezo # -r/--client_mountpoint指定子路径
    # 设置开机启动。可和上文的/mnt/mycephfs同时成功挂载
    echo "none /mnt/cephaezo fuse.ceph ceph.id=aezo,ceph.client_mountpoint=/aezo,defaults,_netdev 0 0" >> /etc/fstab # 上文是老板写法，这是新版本写法
    vi /usr/lib/systemd/system/ceph-fuse@.service
    systemctl enable ceph-fuse@\x2dn\x20client.aezo\x20\x2dr\x20-aezo\x20-mnt-cephaezo --now # --now立即启动。转义符(\x2d为-; \x20为空格; -为/)参考[http://blog.aezo.cn/2017/01/16/arch/nginx/](/_posts/arch/nginx.md#自定义服务)
    ```
    - 常见错误
        - 执行`ceph-fuse`时提示`failed to fetch mon config (--no-mon-config to skip)`
            - 可能由于--keyring秘钥错误
        - 执行`ceph-fuse`时提示`ceph-fuse[12595]: ceph mount failed with (2) No such file or directory`
            - 本案例是因为`/aezo`目录没有创建。可在上文myfs绑定的客户端目录(/mnt/mycephfs)下创建aezo目录
            - 貌似还可以使用`cephfs-shell`创建目录。关于cephfs-shell(目前处于alpha阶段)安装和使用可参考 https://docs.ceph.com/docs/master/cephfs/cephfs-shell/ 。其中cephfs-shell源码位于 https://raw.githubusercontent.com/ceph/ceph/v14.2.4/src/tools/cephfs/cephfs-shell
- 也可将CephFS导出为NFS服务器、在Hadoop中使用

### 对象存储

```bash
# 对象存储使用。参考：https://docs.ceph.com/docs/nautilus/start/quick-rgw/
# 必须已经部署Object Gateway服务
# ceph-deploy install --rgw node1 node3

## 创建网关实例
# 创建一个网关实例。会在此节点启动一个 radosgw 服务，默认监听在7480端口
ceph-deploy rgw create node1
# 修改端口。在网关实例节点修改配置
cat >> /etc/ceph/ceph.conf << EOM
[client.rgw.node1]
rgw_frontends = "civetweb port=80"
EOM
# 在网关实例节点启动
systemctl restart ceph-radosgw@rgw.node1
wget http://192.168.6.131:80 # 默认监听在7480端口。显示`<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">`

## 使用
# 可使用第三方软件访问，如亚马逊 s3 客户端
```

## k8s使用ceph存储

### 直接使用

```bash
## 在Kubernetes(v1.15)集群的所有Node上安装Ceph-common包
# yum install -y ceph-common
yum install -y ceph-common-14.2.4-0.el7.x86_64

## 在mon节点，获取账号秘钥并进行base64
grep key /etc/ceph/ceph.client.admin.keyring |awk '{printf "%s", $NF}'|base64 # ceph auth get-key client.admin | base64
kubectl apply -f ceph-secret.yaml

## 静态PV
# ceph-mon节点上，创建ceph存储池rbd，且在此池中创建10G大小的ceph-image镜像(也可使用原有的)
ceph osd pool create rbd 128
rbd pool init rbd
rbd create ceph-image -s 10240 -p rbd
# CentOS的3.10及以下内核需执行
# rbd feature disable ceph-image object-map fast-diff deep-flatten
# 当pv被使用时，会自动执行 rbd map 对镜像进行映射和创建文件系统

# 创建并查看PV的状态是否正常，如果获取的状态是Available则说明该PV处于可用状态，并且没有被PVC绑定
kubectl apply -f ceph-pv.yaml
kubectl get pv
# 创建pvc
kubectl apply -f ceph-pvc.yaml
# 测试pod(pod被分派到的k8s节点只需要安装ceph-common即可，认证用到的key)
kubectl apply -f ceph-pod.yaml

## 动态PV(只适用于手动安装kubernetes，如果基于kubeadm安装请见下文rbd-provisioner使用)
kubectl apply -f ceph-sc.yaml
kubectl apply -f ceph-pvc.yaml # 开启storageClassName配置
# 此时会发现 pvc 一直处于pending状态。`kubectl describe pvc ceph-pvc`时提示 `Failed to provision volume with StorageClass "ceph-sc": failed to create rbd image: executable file not found in $PATH, command output`。解决方法见下文使用rbd-provisioner提供rbd持久化存储
```
- yaml文件

```yaml
## ceph-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
  namespace: default
type: "kubernetes.io/rbd"
data:
  key: QVFCcldjdGRwNndMS1JBQU9IZHVZdG83SHZwOU96Q01oc255emc11Q==

## ceph-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ceph-pv
spec:
  capacity:
    storage: 2Gi
  accessModes: ["ReadWriteOnce"]
  rbd:
    monitors: 
    - 192.168.6.131:6789
    - 192.168.6.132:6789
    - 192.168.6.133:6789
    pool: rbd
    image: ceph-image
    user: admin
    secretRef:
      name: ceph-secret
    fsType: ext4
    readOnly: false
  persistentVolumeReclaimPolicy: Retain

## ceph-pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ceph-pvc
  namespace: default
spec:
  # storageClassName: ceph-sc # 使用动态PV时需要开启
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi

## ceph-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ceph-pod
  namespace: default
spec:
  containers:
  - name: ceph-busybox
    image: busybox
    command: ["sleep", "60000"]
    volumeMounts:
    - name: ceph-vol1
      mountPath: /usr/share/busybox 
      readOnly: false
  volumes:
  - name: ceph-vol1
    persistentVolumeClaim:
      claimName: ceph-pvc

## ceph-sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-sc
provisioner: kubernetes.io/rbd
parameters:
  monitors: 192.168.6.131:6789,192.168.6.132:6789,192.168.6.133:6789
  adminId: admin
  adminSecretName: ceph-secret
  adminSecretNamespace: default
  pool: rbd
  # 正式建议使用特定的ceph用户
  userId: admin
  userSecretName: ceph-secret
allowVolumeExpansion: true
```

### 使用rbd-provisioner(推荐)

- `rbd-provisioner`为kubernetes 1.5+版本提供了类似于`kubernetes.io/rbd`的ceph rbd持久化存储动态配置实现 [^2]
- 如果使用kubeadm来部署集群，或者将`kube-controller-manager`以容器的方式运行。这种方式下，kubernetes在创建使用ceph rbd pv/pvc时没任何问题，但使用dynamic provisioning自动管理存储生命周期时会报错，提示"rbd: create volume failed, err: failed to create rbd image: executable file not found in $PATH:"。问题来自gcr.io提供的kube-controller-manager容器镜像未打包`ceph-common`组件，缺少了rbd命令，因此无法通过rbd命令为pod创建rbd image
- 安装及使用

```bash
cd /root/k8s/ceph/rbd-provisioner

## 部署rbd-provisioner
for file in clusterrole.yaml clusterrolebinding.yaml deployment.yaml role.yaml rolebinding.yaml serviceaccount.yaml ; do wget https://github.com/kubernetes-incubator/external-storage/raw/v5.5.0/ceph/rbd/deploy/rbac/$file; done
sed -r -i "s/namespace: [^ ]+/namespace: kube-system/g" ./clusterrolebinding.yaml ./rolebinding.yaml
sed -r -i "s/quay.io/quay.mirrors.ustc.edu.cn/g" *.yaml
kubectl -n kube-system apply -f ./
kubectl describe deployments.apps -n kube-system rbd-provisioner

# (可选)创建kube存储池，和创建客户端(用户)kube并授权。也可使用已有的
ceph osd pool create kube 128
# 创建kube客户端
ceph auth get-or-create client.kube mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=kube' -o ceph.client.kube.keyring

## 创建(最终会创建StorageClass)。当PVC创建后StorageClass就会自动创建PV、rbd镜像(eg：`rbd ls -p kube` 显示 `kubernetes-dynamic-pvc-**`)
kubectl create -f ceph-rbd-pool-default.yaml
# 此方式创建的 PV 名称和ceph镜像名称并不对应，但是可在 PV 详情中查看对应的镜像名称
# kubectl get pv pvc-41fea0ae-f8aa-422a-a5b3-84fab3a0a9e3 -o go-template='{{.spec.rbd.image}}' # 查看pv对应哪个rbd image

# 基于helm部署，如果删除helm-release则会与原PV关联断开，即使重新部署也会产生新的PV；如果仅仅删除pod，则原PV是继续使用的(RS会重新创建)
```
- ceph-rbd-pool-default.yaml

```yaml
## ceph-rbd-pvc-test.yaml (可选，测试自动创建PVC配置)
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ceph-rbd-pvc-test
  namespace: default
spec:
  # 尽管定义了默认SC，但此时不定义 StorageClass 会失败
  storageClassName: ceph-rbd-sc-default
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
---
## ceph-kube-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-kube-secret
  namespace: default
type: "kubernetes.io/rbd"
data:
  # ceph auth get-key client.kube | base64
  key: QVFCcldjdGRwNndMS1JBQU9IZHVZdG83SHZwOU96Q01oc255e65321==
---
## ceph-admin-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-admin-secret
  namespace: kube-system
type: "kubernetes.io/rbd"
data:
  # ceph auth get-key client.admin | base64
  key: QVFCcldjdGRwNndMS1JBQU9IZHVZdG83SHZwOU96Q01oc255emc11Q==
---
## ceph-rbd-sc.yaml
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: ceph-rbd-sc-default
  annotations:
    # 默认StorageClass，当PVC不定义 storageClassName 时则模式使用此 StorageClass
    storageclass.beta.kubernetes.io/is-default-class: "true"
# provisioner需要设置为ceph.com/rbd，不是默认的kubernetes.io/rbd，这样rbd的请求将由rbd-provisioner来处理
provisioner: ceph.com/rbd
parameters:
  monitors: 192.168.6.131:6789,192.168.6.132:6789,192.168.6.133:6789
  adminId: admin
  adminSecretName: ceph-admin-secret
  adminSecretNamespace: kube-system
  pool: kube
  # pod需要使用此sc提供的pv时，该pod所在命名空间必须要有客户端 kube 对应的秘钥 ceph-kube-secret
  userId: kube
  userSecretName: ceph-kube-secret
  fsType: ext4
  imageFormat: "2"
  imageFeatures: "layering"
reclaimPolicy: Retain
allowVolumeExpansion: true
```

## 运维案例

### 增加Ceph Node/添加OSD

```bash
## 增加Ceph Node相关操作(略)：yum 源，免秘钥配置，ceph的版本，主机名，防火墙，selinux，ntp
# deploy节点运行
ceph-deploy install --release nautilus node4
ceph -s # 此时集群无任何变化

## 在node4上添加OSD(本质是先ceph-deploy config push推送ceph.conf配置到远程，再远程执行ceph-volume命令)
ceph-deploy osd create --data /dev/sdb --zap-disk node4
```

### 更换Ceph Node(更换osd、更换mon)

- 说明 [^3] [^4]
    - 原先有3个ceph节点(1个ssd+2个hhd)，现需要将其中2个hhd节点(node2、node3)换成新的2个ssd节点(node4、node5)。且总共3个OSD，pool副本数设置为3
    - 整个迁移过程将会消耗很长时间，此处由于涉及的osd较少，大概几个小时即可。如果数据较多，有可能迁移几天
    - 实际测试过程中ceph状态为HEALTH_WARN(此时128个PG并非全部处于active状态)时，客户端无法使用存储；当ceph状态变为HEALTH_OK(128个PG都有active状态。如：1 active+recovering+remapped, 110 active+clean, 17 active+remapped+backfill_wait)时，客户端可正常使用
- 更换osd

```bash
## 以node4为例，node5同理
## 增加Ceph Node相关操作(略)：yum 源，免秘钥配置，ceph的版本，主机名，防火墙，selinux，ntp
# deploy节点运行，在node4上安装ceph
ceph-deploy install --release nautilus node4
ceph -w # 此时集群无任何变化

# (视情况执行)由于osd个数=副本数，当out出一个osd后，pool状态一直会停留在active+clean+remapped(因为此时剩余的osd不够创建副本数)。此处先将kube池的副本设置成2
ceph osd pool set kube size 2

## 销毁老的OSD
# 将osd out。如：ceph osd out 2
ceph osd out {osd-num}
# 关闭原来node3上的osd进程
ssh node3 && systemctl stop ceph-osd@{osd-num} && exit
# 将osd标记为已销毁(此时tree中还存在此osd)。保持ID完整（允许重复使用此ID），但删除cephx密钥，使数据永久不可读
ceph osd destroy {osd-num} --yes-i-really-mean-it

## 复制ceph.conf集群配置文件和ceph.bootstrap-osd.keyring秘钥文件到新节点
ceph-deploy config push node4
scp ceph.bootstrap-osd.keyring root@node4:/var/lib/ceph/bootstrap-osd/ceph.keyring
## (在新节点node4上执行)使用原来的osd编号(在新节点上)创建新的osd
ssh node4
ceph-volume lvm zap /dev/sdX # 此时{osd-num}状态仍然为node3 destroy
# prepare + activate = create
ceph-volume lvm prepare --osd-id {osd-num} --data /dev/sdX # 此时{osd-num}状态仍然为node3 down
ceph-volume lvm activate {osd-num} # 此时{osd-num}状态仍然为node4 up。此时会产生PG迁移

# (视情况执行)将kube池设置回3个副本
ceph osd pool set kube size 3
```
- 更换mon等

```bash
## 更新所有ceph节点的ceph.conf配置文件
# 编辑配置文件。对文件中的`mon_host`参数添加新的节点ip；增加参数`public_network=192.168.1.0/24`
vi /opt/ceph-cluster/ceph.conf
ceph-deploy --overwrite-conf config push node1 node2 node3 node4 node5 # 用上述ceph.conf文件覆盖所有ceph节点的ceph.conf配置文件

## 待node4操作完后，node5同样操作
# 添加一个mon节点
ceph-deploy mon add node4 # 会启动该节点的system mon进程
# 观察ceph状态，直到新mon节点重新进入，并且处于HEALTH_OK状态再继续后续操作
ceph -w
# 当集群状态处于HEALTH_OK状态后，再移除历史mon节点(建议等待1-3min再执行)
ceph-deploy mon destroy node2 # 会停止该节点的system mon进程，并将备份原mon数据到/var/lib/ceph/mon-removed目录

## 再操作node5

## 再次更新所有ceph节点的ceph.conf配置文件
# 编辑配置文件。对文件中的`mon_host`参数，去掉旧的节点ip；修改`mon_initial_members`参数，去掉历史旧的mon节点名称，增加新的mon节点名称
vi /opt/ceph-cluster/ceph.conf
ceph-deploy --overwrite-conf config push node1 node4 node5 # 用上述ceph.conf文件覆盖所有ceph节点的ceph.conf配置文件
```

### 删除OSD

```bash
## 将osd移出集群(此时osd状态由in up变为out up)
# ceph osd crush reweight osd.{osd-num} 0 # 此命令类似out，都会导致该osd上的所有PG迁出
ceph osd out {osd-num} 
# 观察集群状态，等到重新变为active+clean再进行后续操作
ceph -w

## 停止osd进程(此时osd状态由out up变为out down)
ssh {osd-host}
sudo systemctl stop ceph-osd@{osd-num}
# 退出osd-host，进入admin-node执行后续命令

## 删除
# 从CRUSH映射中删除OSD，并删除其身份验证密钥
ceph osd purge {osd-num} --yes-i-really-mean-it # purge命令为Luminous版本增加，类似于以下3个命令
# ceph osd crush remove osd.{osd-num} # 从CRUSH映射中删除OSD，使其不再接收数据
# ceph auth del osd.{osd-num} # 删除OSD身份验证密钥
# ceph osd rm {osd-num} # 卸下OSD

## 清理磁盘
/usr/sbin/wipefs --all /dev/sdX
ls /dev/mapper/ceph--9f84f55e--6baa--4ac2--a721--4dfd97f9a8f1-osd--block--cf4926bd--96c4--4787--a1fc--af3078ba3d0c | xargs -I% -- dmsetup remove % # 此处可通过 `lsblk` 查看对应映射名称
```

### 镜像扩容缩容(rbd-images)

```bash
## 管理界面操作
Block - images - xxx - 编辑 - Size

## 管理端操作
rbd ls -p kube # 列举所有镜像
rbd du kube/kubernetes-dynamic-pvc-8286cda0-09d1-11ea-89b1-5aa8347da671 # 查看此镜像空间使用情况
# 调整大小为20G(1024换算)
rbd resize kube/kubernetes-dynamic-pvc-8286cda0-09d1-11ea-89b1-5aa8347da671 --size 20480
rbd du kube/kubernetes-dynamic-pvc-8286cda0-09d1-11ea-89b1-5aa8347da671 # 重新查看镜像空间使用情况
# 然后修改k8s pvc对应大小为指定大小

## 客户端扩容方式略
```

## 常见问题

- 调试说明
    - 日志目录`/var/log/ceph`
- 安装deploy时，提示`No module named pkg_resources`
    - 解决：在deploy节点安装`wget https://bootstrap.pypa.io/ez_setup.py -O - | python`(osd等节点可视情况安装)
- rbd map映射镜像时，提示`rbd: image ceph-image: image uses unsupported features: 0x38`
    - 原因：CentOS的3.10内核仅支持layering、exclusive-lock，其他feature概不支持
    - 解决
        - 升级内核
        - 或者手动disable镜像feature`rbd feature disable ceph-image object-map fast-diff deep-flatten exclusive-lock`
        - 或者在各osd节点修改配置文件`/etc/ceph/ceph.conf`，添加配置`rbd_default_features = 1`。在创建镜像时指定--image-format参数如：`rbd create ceph-image --size 10G --image-format 1 --image-feature layering`
- 创建存储池时提示`pg_num 128 size 3 would mean 768 total pgs, which exceeds max 750 (mon_max_pg_per_osd 250 * num_in_osds 3)`
    - 原因：测试环境只有3个osd，设置复制个数为3，且每个osd默认最大pg数为250(mon_max_pg_per_osd)。而且已经创建过一个pood(128个pg)，因此创建第二个pool(128个pg)则报错，超过osd最大pg限制
    - 解决：增加osd数，或临时提高osd最大pg数(正式环境不建议太高)，或者将pool的pg设置的小一些。参考[PG](#PG和PGP)
- k8s pod创建时提示`MountVolume.WaitForAttach failed for volume "ceph-pv" : rbd image rbd/ceph-image is still being used`
    - 原因：强制删除了pod，导致重新创建此pod时，改镜像被旧pod锁定
    - 解决

        ```bash
        # 查看锁定
        rbd lock ls ceph-image
        # 解除锁定
        rbd lock rm rbd/ceph-image "auto 18446462598732840961" client.4259
        ```
- k8s pod创建时提示`MountVolume.WaitForAttach failed for volume "ceph-pv" : rbd: map failed exit status 110...unable to find a keyring on /etc/ceph/ceph.client.admin.keyring...Connection timed out`，调度到对应的k8s节点上提示`missing required protocol features`(dmesg -T | grep ceph)
    - 原因：由于内核版本不够高导致一些 Ceph 需要的特性没有得到支持(此问题出现的版本为`Centos7 Linux 4.4.196-1`) [^6]
    - 解决

        ```bash
        # mgr节点运行。修改 CRUSH MAP 的配置，将 chooseleaf_vary_r 与 chooseleaf_stable 设为 0
        ceph osd getcrushmap -o crush # 产生crush临时文件
        crushtool -i crush --set-chooseleaf_vary_r 0  --set-chooseleaf_stable 0 -o crush.new # 产生crush.new临时文件
        ceph osd setcrushmap -i crush.new
        ```
- ceph警告 `HEALTH_WARN application not enabled on 1 pool(s)`，且通过k8s storageClass创建的镜像无法查询到
    - 原因：新创建的pool没有开启rbd application
    - 解决：`ceph osd pool application enable kube rbd` (此处存储池为kube)
- `rbd: error: image still has watchers` **无法删除镜像**，参考：https://www.cnblogs.com/sisimi/p/7776633.html
    - 原因：镜像无法删除的原因一般为存在快照或者watcher(此情况)
    - 解决

        ```bash
        ## 存在watcher的情况
        rbd status kube/img # 获取kube/img镜像的watcher
        ceph osd blacklist add 192.168.6.131:0/1135656048 # 添加watcher到黑名单1h(1小时候会自动移除)
        # rbd rm kube/img # 可选，删除镜像
        # ceph osd blacklist rm 192.168.6.131:0/1135656048 # 手动移除黑名单
        ceph osd blacklist ls
        ```
- 更换mon时，执行`ceph-deploy mon add node4`报错`admin_socket: exception getting command descriptions: [Errno 2] No such file or directory`
    - 解决：修改`ceph.conf`文件中的`mon_host`、`public_network`并推送到所有节点 [^7]

## 相关命令

### 常用

```bash
ceph -s/-w          # 查看集群状态(-w实时状态查看)
ceph osd tree       # 查看所有osd

rbd ls kube         # 列举kube存储池所有存储块
rbd showmapped      # 列举本机已映射的块设备(pool、image等信息)。存储块必须映射后才能挂载
rbd du kube/image-xxx # 查看镜像空间使用情况
```

### ceph

- 概要

```bash
ceph -h # 查看帮助(非常多命令)。查看某个命令帮助：`ceph -h osd pool`
ceph -v # ceph version 14.2.4 (75f4de193b3ea58512f204623e6c5a16e6c1e1ba) nautilus (stable)
ceph -s/-w # 查看集群状态(-w实时状态查看)
ceph    # 进入ceph命令行(exit退出)

# 获取法定节点信息
ceph quorum_status --format json-pretty
# 列举pool
ceph osd pool ls
```

#### ceph config

```bash
### ceph config <xxx>. eg: `ceph config ls`
ls      # 列举所有配置项名称
help <key>  # 查看某个配置帮助。eg：`ceph config help mon_max_pg_per_osd -f json-pretty`(-f 以json格式输出)
get <who> {<key>} # 获取某个角色(如：osd.0、osd.1等)的配置。eg：`ceph config get osd.0 mon_max_pg_per_osd` 获取osd.0的mon_max_pg_per_osd(默认250)
set <who> <name> <value> {--force}
rm <who> <name>
show <who> {<key>}  # 类似get
show-with-defaults <who>
log {<int>}
assimilate-conf
dump
```

#### ceph osd

##### ceph osd pool

```bash
### ceph osd pool <xxx>。eg: `ceph osd pool ls`
ls      # 列举 pool
get <poolname> <var> # 获取存储池参数
destroy # 将osd标记为已销毁。保持ID完整（允许重复使用此ID），但删除cephx密钥，使数据永久不可读
rm      # 删除存储池(会物理删除所有数据)
        # ceph osd pool rm rbd rbd --yes-i-really-really-mean-it # (警告)删除"rbd"存储池(会物理删除所有数据)，需重复输入存储池名称
            # 默认未开启mon删除存储池功能，如动态增加配置 `ceph tell mon.\* injectargs '--mon-allow-pool-delete=true'` 后再执行删除方可。具体参考：https://stackoverflow.com/questions/45012905/removing-pool-mon-allow-pool-delete-config-option-to-true-before-you-can-destro
```

##### ceph osd crush

```bash
## ceph osd crush -h
ceph osd crush remove osd.2         # 从 crush 里面删除此OSD(会触发PG迁移)
ceph osd crush reweight osd.2 0     # reweight取值[0,1]的浮点数据；reweight值越小，从此OSD迁出的数据越多。此时将此OSD的权重设置为0(会触发PG迁移，会全部移走)
```

##### ceph osd <xxx>

```bash
### ceph osd <xxx>
df      # 查看集群中每个osd上的分布情况(空间大小、使用空间、存放的PG数、状态信息)
out <ids> [<ids>...] # out某个编号的osd，或者使用 [any|all] 移除所有。此时会触发PG迁移，如果某个osd的进程停止并不会触发迁移(顶多主副PG角色变化)

### ceph osd blacklist <xxx>。黑名单
ls
add|rm <EntityAddr> {<float[0.0-]>}
    # ceph osd blacklist add 192.168.6.131:0/1135656048 # 添加watcher到黑名单(`rbd status kube/img` 获取镜像的watcher)
clear
```

#### ceph xxx

```bash
### ceph tell
tell <name (type.id)> <args> [<args>...] # 发送一个命令到特定的守护进程
    # ceph tell mon.* injectargs '--mon_osd_report_timeout 400' # 正在匹配所有mon守护进程，分别注入参数(动态修改配置)。对比`ceph daemon`

### ceph health
ceph health [detail]    # 查看集群健康状态
```

#### Local commands

- Local commands表示只能在角色所在的主机上进行设置，其他一般为Monitor commands(在mon节点上设置即可)

```bash
ceph daemon {type.id|path} <cmd> # 基于某个角色的守护进程执行相关命令
    # ceph daemon osd.0 config get mon_max_pg_per_osd # 获取osd.0的mon_max_pg_per_osd配置值(如果此时osd.1不在该主机上则获取不到)
    # 注意使用daemon可以修改(set)临时修改配置，但是重启进程后配置会恢复到默认参数，在ceph.conf中修改可永久有效
```

### ceph-volume

- 作用：使用物理磁盘或lvm创建Ceph OSDs(各Storage Node均可运行)
- [Doc](https://docs.ceph.com/docs/nautilus/ceph-volume/)
- https://www.dovefi.com/post/ceph-volume%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90osd%E5%88%9B%E5%BB%BA%E5%92%8C%E5%BC%80%E6%9C%BA%E8%87%AA%E5%90%AF/

```bash
ceph-volume -h

#Available subcommands:
lvm                      #Use LVM and LVM-based technologies like dmcache to deploy OSDs
    prepare                  # 准备OSD，一般和activate联合使用。Format an LVM device and associate it with an OSD
    activate                 # 启动systemd中osd进程。Discover and mount the LVM device associated with an OSD ID and start the Ceph OSD
    create                   # 创建OSD。效果同 prepare + activate(分别使这两个命令可以避免数据立即均衡)
    list                     # 列举和ceph相关的逻辑卷和设备
    batch                    # Automatically size devices for multi-OSD provisioning with minimal interaction
        --osds-per-device       # 此osd节点的每个设备可创建介个osd介质(分区，如osd0和osd1目录)，默认1
        # ceph-volume lvm batch --osds-per-device 2 /dev/sdb # 将/dev/sdb分成2个分区，运行命令后会显示预览，输入yes后正式进行分区(实际是使用系统lvm进行分区)
    trigger                  # systemd helper to activate an OSD
    zap                      # 格式化磁盘
        # ceph-volume lvm zap /dev/sdb  # 格式化。如果遇到逻辑卷无法删除可执行 `dmsetup remove {lv-name}`
        # ceph-volume lvm zap /dev/sdb --destroy
simple                   # 用于接管用ceph-disk创建的osd(ceph-disk为基于块设备创建，ceph-volume为基于lvm创建)
inventory                #Get this nodes available disk inventory # 查看节点的存储设备(如连接的物理磁盘)
#optional arguments:
  -h, --help            #show this help message and exit
  --cluster CLUSTER     #Cluster name (defaults to "ceph")
  --log-level LOG_LEVEL #Change the file log level (defaults to debug)
  --log-path LOG_PATH   #Change the log path (defaults to /var/log/ceph)
```

### rbd 块存储

- `ceph-common`包中含有此命令

```bash
See 'rbd help <command>' for help on a specific command.
# 全局可选项
--name/-n arg # client name

### rbd <xxx> <pool-name>/<image-name>  # pool-name不填则为rbd
info        # 查看镜像信息 Show information about image size, striping, etc.
    # rbd info my-image         # 查看存储块信息
        # 如：features: layering(支持分层), exclusive-lock(支持独占锁), object-map(支持对象映射，依赖 exclusive-lock), fast-diff(快速计算差异，依赖 object-map), deep-flatten(支持快照扁平化操作), striping(支持条带化 v2), journaling(支持记录 IO 操作，依赖exclusive-lock)
    # rbd info replicapool-test/csi-vol-436aafe9-df4b-11e9-854c-1ae38aa085c6    # 查看某个存储块信息
status      # 查看状态，如watcher
list (ls)   # 列举所有存储块 List rbd images.
    # rbd ls 列举所有存储块
    # rbd ls [-p/--pool] replicapool-test   # 列举 replicapool-test 存储块池中的存储块
remove (rm) # 删除块设备映像
    # rbd rm {pool-name}/{image-name}
resize      # 调整块设备映像大小 Resize (expand or shrink) image.
    # rbd resize --size 2048 myrbd # 增大myrbd存储块。最终大小为2048M，下同
    # rbd resize --size 2048 myrbd --allow-shrink # 缩小myrbd存储块
copy (cp)                         # Copy src image to dest.
create                            # Create an empty image.
    # rbd create myrbd --size 10G --image-feature layering -p mypool # 在mypool存储池中，创建块设备镜像myrbd，大小为10G
deep copy (deep cp)               # Deep copy src image to dest.
device list (showmapped)          # List mapped rbd images.
    # rbd showmapped    # 列举已映射块设备(pool、image等信息)，存储块必须映射后才能挂载
device map (map)                  # 映射块设备
    # rbd map --name client.admin mypool/myrbd # 执行成功打印设备名称，如`/dev/rbd2`
device unmap (unmap)              # 取消块设备映射
    # rbd unmap /dev/rbd2 # 取消块设备映射
disk-usage (du)                   # Show disk usage stats for pool, image or snapshot.
    # rbd du pool-test/csi-image    # 显示 pool-test/csi-image 镜像已使用空间大小
diff                              # Print extents that differ since a previous snap, or image creation.
    # rbd diff kube/img | awk '{ SUM += $2 } END { print SUM/1024/1024 " MB" }' # 计算 kube/img 镜像已使用空间大小(可在对应客户端通过`df -h`查看)
lock list (lock ls)               # Show locks held on an image.
    # rbd lock list pool-test/csi-image     # 显示 pool-test/csi-image 镜像被锁定列表
lock remove (lock rm)             # Release a lock on an image.
    # rbd lock rm rbd/ceph-image "auto 18446462598732840961" client.4259 # 解除锁定(image id locker)
```

### rados

- `ceph-common`包中含有此命令

```bash
rados -h
rados -v # ceph version 14.2.4 (75f4de193b3ea58512f204623e6c5a16e6c1e1ba) nautilus (stable)

### rados <xxx>
## POOL COMMANDS
lspools         # 列举存储池

## OBJECT COMMANDS
listwatchers <obj-name>   # 列举对象的watchers。eg: `rados -p kube listwatchers rbd_header.1041643c9869` (ID可在`rbd info kube/img`中查看此image的header对象block_name_prefix)
```

## ceph.conf 配置文件

- `ceph-deploy new`初始化出来的文件

```ini
[global]
fsid = 29f2b08c-ba52-4ed8-be0e-b593739da912
mon_initial_members = node1, node2, node3
mon_host = 192.168.1.131,192.168.1.132,192.168.1.133
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
```
- 字段说明

```ini
## monitors：https://docs.ceph.com/docs/nautilus/rados/configuration/common/#monitors
## 全局配置
[global]
# 集群 ID
fsid = 29f2b08c-ba52-4ed8-be0e-b593739da912
# 可以使用下划线或空格，如 `mon initial members = ...`
# 集群启动期间，群集中初始监视器的ID。如果指定，则Ceph需要奇数个监视器来形成初始仲裁
mon_initial_members = node1, node2, node3
# 所有mon节点的ip列表
mon_host = 192.168.1.131,192.168.1.132,192.168.1.133
# 所有集群的前端公共网络
public_network = 192.168.1.0/24
# 各服务认证方式使用cephx
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
```

## 进阶知识

### PG和PGP

- `PG`(Placement Groups) 它是ceph的逻辑存储单元。在数据存储到ceph时，先打散成一系列对象，再结合基于对象名的哈希操作、复制级别、PG数量，产生目标PG号。根据复制级别的不同，每个PG在不同的OSD上进行复制和分发。可以把PG想象成存储了多个对象的逻辑容器，这个容器映射到多个具体的OSD

    ![ceph-pg](/data/images/devops/ceph-pg.png)
    - PG存在的意义是提高ceph存储系统的性能和扩展性。如果没有PG，就难以管理和跟踪数以亿计的对象，它们分布在数百个OSD上。对ceph来说，管理PG比直接管理每个对象要简单得多
    - 每个PG需要消耗一定的系统资源包括CPU、内存等。通常来说，增加PG的数量可以减少OSD的负载，一个推荐配置是每OSD对应50-100个PG。如果数据规模增大，在集群扩容的同时PG数量也需要调整。CRUSH会管理PG的重新分配
    - Pool由PG构成，对象存到Pool是存到特定的PG中，可以理解为对象的虚拟目录。在创建Pool的时候就要把pg数量规划好，PG数量只可以增大不可以缩小
    - 在架构层次上，PG 位于 RADOS 层的中间。往上负责接收和处理来自客户端的请求，往下负责将这些数据请求翻译为能够被本地对象存储所能理解的事务
    - 正常的 PG 状态是 `100% active + clean`，这表示所有的 PG 是可访问的，所有副本都对全部 PG 都可用。[PG 状态详解](https://www.infoq.cn/article/4N2whf1y1lH_Hd5QYOkW)
- `PGP`(Placement Group for Placement)
- 对应Pool的PG和PGP个数调整
    - PG是指定存储池存储对象的目录有多少个，PGP是存储池PG的OSD分布组合个数
    - PG的增加会引起PG内的数据进行分裂，分裂到相同的OSD上新生成的PG当中
    - PGP的增加会引起部分PG的分布进行变化，但是不会引起PG内对象的变动
    - 相关命令

    ```bash
    ceph osd pool get rbd pg_num # 获取rbd池的pg数
    ceph osd pool get rbd pgp_num # 获取rbd池的pgp数

    # 调整PG数量
        # 调整pg时，原则上每次增加一倍
        # 此命令本质是当前pg的分裂(1个pg分裂成2个)。mon会首先更新自身的osd map中的pg数量，然后将osd map同步给osd；osd根据新的pg数量进行计算，进行本地分裂；分裂过程就是创建新目录，然后数据移动过去
        # 分裂期间CPU和IO会打满，负载非常高，影响时间看数据量而定(30s-10min)
    ceph osd pool set <pool_name> pg_num <pg_num>
    # 调整PGP数量
        # pg数量大于pgp数量时，heath状态显示warning。需要扩充pgp数量
        # 调整pgp数量会使pg在集群内重新分布
        # 该操作会影响一半的数据进行迁移，对集群影响非常大
    ceph osd pool set <pool_name> pgp_num <pg_num>
    ```
- 每个Pool分配PG建议个数计算公式 `Total PGs = ((Total_number_of_OSD * 100) / max_replication_count) / pool_count`(结果往上取靠近2的N次方的值)
- OSD最大PG数默认为`mon_max_pg_per_osd=250`

    ```bash
    ceph config get osd.0 mon_max_pg_per_osd # 获取osd.0的最大pg数
    ```
- PG迁移
    - 由于CRUSH算法的伪随机性，对于一个PG来说，如果 OSD tree 结构不变的话，它所分布在的 OSD 集合总是固定的(同一棵tree下的OSD结构不变/不增减)，即此PG不会进行迁移。反之 OSD tree 变化则会触发PG迁移



---

参考文章

[^1]: https://www.cnblogs.com/yangxiaoyi/p/7795274.html
[^2]: https://jimmysong.io/kubernetes-handbook/practice/rbd-provisioner.html
[^3]: https://blog.csdn.net/Tencent_TEG/article/details/79767484
[^4]: https://blog.csdn.net/xiongwenwu/article/details/53120415
[^5]: http://manjusri.ucsc.edu/2017/09/25/ceph-fuse/
[^6]: https://github.com/grzhan/keng/issues/2
[^7]: https://www.zybuluo.com/dyj2017/note/920621

