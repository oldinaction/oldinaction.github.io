---
layout: "post"
title: "Rook & Ceph"
date: "2019-09-23 09:38"
categories: devops
tags: [k8s, storage, cncf]
---

## 简介

- [Ceph](https://ceph.com/) 是一个分布式存储系统，目前提供`对象存储(RADOSGW)`、`块存储RDB`以及`CephFS文件系统`这3种功能，并且提供Ceph REST API。具体见下文 [^1]
- [Rook](https://rook.io) 是Kubernetes的开源云本地存储协调器，为各种存储解决方案提供平台，框架和支持，以便与云原生环境本地集成。是云原生计算基金会(CNCF)的孵化级项目。Rook 目前支持 Ceph、NFS、Minio Object Store、Edegefs、Cassandra、CockroachDB 存储的搭建，使用 Rook 可以轻松实现在 Kubernetes 上部署并运行 Ceph 存储系统
- k8s存储选型：`Rook`/`Ceph` [^2]

## Rook-Ceph安装与使用

### 安装 Rook-Ceph

- 参考 https://rook.io/docs/rook/v1.1/ceph-quickstart.html [^3] [^4]

```bash
### 所有节点开启ip_forward，k8s的node节点一般都已经开启过
cat <<EOF >  /etc/sysctl.d/ceph.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

### 开始部署Operator
cd /home/smalle/k8s
wget https://github.com/rook/rook/archive/v1.1.2.tar.gz
tar -zxvf v1.1.2.tar.gz
cd rook-1.1.2/cluster/examples/kubernetes/ceph
## 安装并查看operator是否成功
kubectl apply -f common.yaml
# 修改镜像配置
# 如默认使用CSI驱动，需修改相关插件镜像，见下文说明。CSI驱动程序，它是K8s 1.13及更高版本以后的首选驱动程序，较早的Flex驱动默认是关闭的
vi operator.yaml
kubectl apply -f operator.yaml
# 需要等几分钟，确保 rook-ceph-operator 处于 `Running` 状态，`rook-discover` 会在无污点(k8s-master有污点)的所有节点上运行。`rook-ceph-agent` 在Flex模式才会产生(默认是CSI模式)
kubectl -n rook-ceph get pod -o wide

### 设置节点标签。(测试环境 node1 为k8s-master节点，所有默认无法被调度)
kubectl label nodes {node2,node3} storage-node=enable

### 部署集群
## 修改集群配置 cluster.yaml，见下文说明。官方说明 https://rook.io/docs/rook/v1.1/ceph-cluster-crd.html
vi cluster.yaml
# 创建并查看ceph集群
kubectl apply -f cluster.yaml
# 此时会在无污点的k8s节点上运行csi-pod等pod。然后在相应的rook节点运行rook-ceph-mgr(需要mon选举成功，mgr才会正常运行)、rook-ceph-mon(生成的mon-pod会自动加上Node-Selectors=当前运行节点)、rook-ceph-osd-prepare(进行osd分区等)、rook-ceph-osd对应的pod(也会自动加上Node-Selectors=当前运行节点)。如：rook-ceph-osd-0-5c45f86b4f-nhwzt 则对应 osd0 所在pod(此pod所在节点即为osd0所在节点)
kubectl -n rook-ceph get pod -o wide

### 配置ceph dashboard
# 创建NodePort服务
kubectl apply -f dashboard-external-http.yaml
# 查看dashboard监听的NodePort端口
kubectl -n rook-ceph get service
# 查看密码(x8sn2X4MPp)，用户名为 admin。如果无法获取密码，可将rook-ceph-mgr删除后重试(或者mgr报错了)
kubectl -n rook-ceph logs $(kubectl get pod -n rook-ceph | grep mgr | awk '{print $1}') | grep password
# 如访问 http://192.168.6.131:30811/
```

- 上文配置文件修改说明

```yml
## operator.yaml
# ...
- name: ROOK_CSI_CEPH_IMAGE
    value: "quay.mirrors.ustc.edu.cn/cephcsi/cephcsi:v1.2.1
- name: ROOK_CSI_REGISTRAR_IMAGE
    value: "quay.mirrors.ustc.edu.cn/k8scsi/csi-node-driver-registrar:v1.1.0"
- name: ROOK_CSI_PROVISIONER_IMAGE
    value: "quay.mirrors.ustc.edu.cn/k8scsi/csi-provisioner:v1.3.0"
- name: ROOK_CSI_SNAPSHOTTER_IMAGE
    value: "quay.mirrors.ustc.edu.cn/k8scsi/csi-snapshotter:v1.2.0"
- name: ROOK_CSI_ATTACHER_IMAGE
    value: "quay.mirrors.ustc.edu.cn/k8scsi/csi-attacher:v1.2.0"
# ...

## cluster.yaml
# ...
spec:
  # 存储rook节点配置信息、日志信息。dataDirHostPath数据存储在k8s节点(宿主机)目录，会自动在rook选择的k8s节点上创建此目录。如果osd目录(directories)没指定或不可用，则默认在此目录创建osd
  # rook对应pod删除后此目录会保留，重新安装rook集群时，此目录必须无文件
  dataDirHostPath: /var/lib/rook # 默认值即可
  mon:
    # 1-9中的奇数(需要选举)
    count: 3
    # 测试环境可设置成true(一个节点可运行多个mon实例)，否则rook-ceph-mgr、rook-ceph-mon、rook-ceph-osd可能无法创建成功(pod不进行调度也不显示错误信息)
    allowMultiplePerNode: false
  network:
    # true表示共享宿主机网络，这样外面可直接连接ceph集群，默认false
    hostNetwork: false
  # 设置节点亲和性：只能影响rook-ceph-mgr、rook-ceph-mon、rook-ceph-osd；csi相关插件(在operator.yaml中配置的)还是会在除k8s-master的其他各节点上运行
  placement:
    all:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: storage-node
              operator: In
              values:
              - enable
  storage:
    # true表示所有k8s节点都可用来部署ceph
    useAllNodes: false
    # true会把宿主机所有可用的磁盘都用来存储
    useAllDevices: false
    deviceFilter: ^sd[b-z] # 选择k8s节点的sdb、sdc、sdd等开头的设备当做OSD节点。会自动覆盖 `useAllDevices: true`为false。且deviceFilter会被nodes[].devices.name覆盖
    # rook(ceph)数据存放位置，如果无此目录会自动创建
    directories:
    - path: /data/rook
    config:
      # 设备默认是bluestore类型存储，目录默认是filestore存储 (The default and recommended storeType is dynamically set to bluestore for devices and filestore for directories)。如果是bluestore，虽然节点明确定义了devices，还是会在系统目录，如/dev/sda1(dm-0)中创建osd存储
      # storeType: bluestore
    # 选择k8s节点用来存储
    nodes:
    - name: "node2"
      # 选择k8s节点磁盘设置为OSD节点
      devices:
      # 将/dev/sda2设置为osd。此时sda2进行过分区或挂载也可提供给ceph使用
      # 指定磁盘必须有GPT header，不支持指定分区
      - name: "sda2"
      directories:
      # rook(ceph)数据存放位置(根据节点自定义，覆盖默认位置)。会自动创建此目录，并创建osd0/osd1...子目录
      - path: "/home/data"
    # 未定义path则使用父属性定义的/data/rook
    - name: "node3"
      # deviceFilter: "^vd." # 选择所有以 vd 开头的设备
      devices:
      # 如果sdb没有进行过分区和挂载，只是物理连接的裸磁盘，rook也会自动进行分区(分区类型为lvm)
      # 尽管定义了devices(和deviceFilter)，rook也会检测到sda的磁盘并创建/var/lib/rook/osd*文件夹，只是无法初始化(且此osd也会注册到ceph)
      - name: "sdb"
      # 较大存储空间的磁盘上可创建多个osd节点
        #config:
        #  osdsPerDevice: "3"
# ...
```

### 简单使用

- 块存储案例，参考：https://rook.io/docs/rook/v1.1/ceph-block.html
- 实例

```bash
# 创建 CephBlockPool 和 StorageClass
vi sq-rdb.yaml
kubectl apply -f sq-rdb.yaml
kubectl get sc

# 使用
cd /home/smalle/k8s/rook-1.1.2/cluster/examples/kubernetes # 上文rook源码所在目录
kubectl apply -f mysql.yaml # PVC和Deploy配置参考：https://raw.githubusercontent.com/rook/rook/v1.1.2/cluster/examples/kubernetes/mysql.yaml
kubectl get pvc
# 稍等片刻，临时主机暴露端口。使用 192.168.6.131:13306 root/changeme 访问 mysql
kubectl port-forward --address 0.0.0.0 $(kubectl get pods --namespace default -l "app=wordpress,tier=mysql" -o jsonpath="{.items[0].metadata.name}") 13306:3306

## **解析RBD存储**：当PVC申请PV，PV挂载到POD上后，可在rook节点(OSD所在k8s节点)中看到rbd挂载信息
# 在rook节点上运行，可以看到 rbd0(/dev/rbd0) 磁盘被挂载到了 /var/lib/kubelet/pods/bd1de507...目录上
lsblk
# 进入此目录，可以看到完整的文件信息。如mysql完整的数据文件
cd /var/lib/kubelet/pods/bd1de507-39ac-47fa-b1e2-a19a1107ef01/volumes/kubernetes.io~csi/pvc-6f9dce55-3203-4a4d-8ea1-0d75e6563d77/mount
# 也可在对应节点运行查看挂载 (**还可看到pvc对应磁盘使用情况**)
df -h | grep csi/pvc
```
- sq-rdb.yaml

```yml
# CephBlockPool 设置参考 https://rook.io/docs/rook/v1.1/ceph-pool-crd.html
# 存储集群运行中时，也可修改下列参数
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool-test
  # CephBlockPool定义在rook-ceph命名空间接口；其他各个命名空间的StorageClass可通过parameters进行制定CephBlockPool所在的命名空间来进行连接
  namespace: rook-ceph
spec:
  # 取值：host、osd
  # host：所有块都将放置在唯一的主机上；osd：所有块都将放置在唯一的OSD上(一个主机可能存在多个osd)
  failureDomain: host
  # 复制池设置(简单的文件数据复制，和erasureCoded不能同时设置)
  replicated:
    # 要在复制池中制作数据的所需副本数(副本数为3时，如果其中2个几点宕机，还是可以正常提供服务)
    # 如果池中没有足够的主机或OSD来放置唯一位置，也可以创建此k8s池(ceph集群中不会进行创建对应pool)，但是该池的PUT会挂起，PVC也一直处于Pending状态
    size: 3 # 测试环境可设置成1
  # 擦除编码池设置(将数据分成数据块数和编码块，总存储一般高于原始数据的1.5倍左右。如果损失其中任意一块，仍然能够重建原始对象)。仅仅在Flex驱动中可用
  # erasureCoded:
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-block # 在PVC中会使用到
# CSI驱动。如果rook-ceph集群所在k8s命名空间为`xxx`，则此处为`xxx.rbd.csi.ceph.com`
provisioner: rook-ceph.rbd.csi.ceph.com
# Flex驱动(parameters也要做相应修改，K8 1.13已经不推荐)
# provisioner: ceph.rook.io/block
parameters:
  clusterID: rook-ceph
  # 上文定义的pool名称
  pool: replicapool-test
  imageFormat: "2"
  imageFeatures: layering
  # 安装集群时，operator自动产生的相关秘钥，可在rook-ceph对应命名空间中查看
  csi.storage.k8s.io/provisioner-secret-name: rook-ceph-csi
  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
  csi.storage.k8s.io/node-stage-secret-name: rook-ceph-csi
  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
  # 指定申请的卷的文件系统类型，默认是`ext4`
  csi.storage.k8s.io/fstype: xfs
# 删除PVC时删除RBD卷。Delete(只会删除PV和PVC，不会删除rbd)、Retain(生成环境可使用)、Recycle
reclaimPolicy: Delete
```

### 使用扩展

### 增加/减少OSD节点

```bash
### 增加节点。不会影响其他运行中的ceph节点
# 增加节点亲和性相关的标签(需要先加标签后应用cluster配置)
kubectl label nodes node4 storage-node=enable

# 修改集群配置：设置 spec.storage.nodes
# kubectl edit cephcluster rook-ceph -n rook-ceph # 或者直接修改资源
cd /home/smalle/k8s/rook-1.1.2/cluster/examples/kubernetes/ceph/
vi cluster.yaml
kubectl apply -f cluster.yaml

# 实时查看pod调度情况(需要等1分钟左右)，会多一个 rook-ceph-osd-prepare-node4、rook-ceph-osd(其中rook-ceph-osd运行正常后prepare-pod会自动进入完成状态)
kubectl -n rook-ceph get pod -o wide -w
# 如果osd-pod一直不产生，可删除对应节点的prepare-pod重新创建。如果prepare-pod一直处于CrashLoopBackOff之后会被k8s清除，大概要等15min才会重新创建
# kubectl -n rook-ceph delete pods rook-ceph-detect-version-ps5g9

### 删除节点
# 去掉节点标签
kubectl label nodes node4 storage-node-
# 删除集群配置中的 spec.storage.nodes
# 如果pod一直无法成功删除，可重启此节点机器，有时删除确实很慢(15min)。**如果只有一个osd节点或者集群空间不足，则该节点无法被自动删除**
kubectl edit cephcluster rook-ceph -n rook-ceph
kubectl -n rook-ceph get pod -o wide -w # 对应节点的osd-pod会被移除
# 等pod移除成功后，再删除宿主机的/var/lib/rook/osd*文件夹(如果osd数据目录为其他自定义目录可相应删除)，方便下次将此节点再加入集群
# 注意：/var/lib/rook目录还可能有mon等pod的配置，不能删除
rm -rf /var/lib/rook/osd*
# (可选)还原磁盘供下次安装osd使用
# yum install -y gdisk
sgdisk --zap-all --clear --mbrtogpt /dev/sdb
/usr/sbin/wipefs --all /dev/sdb
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
rm -rf /dev/mapper/ceph-*
rm -rf /dev/ceph-*
```

### 删除整个集群

```bash
## 备份数据后再操作
cd /home/smalle/k8s/rook-1.1.2/cluster/examples/kubernetes/ceph/
## 删除测试案例相关资源(可选)
# kubectl delete -n rook-ceph cephblockpool replicapool-test

## 删除rook-ceph集群并检查
kubectl -n rook-ceph delete cephcluster rook-ceph # 如果删除失败可以先执行下述命令
# (可选)如果无法删除可运行此命令
# kubectl -n rook-ceph patch crd cephclusters.ceph.rook.io --type merge -p '{"metadata":{"finalizers": [null]}}'
kubectl -n rook-ceph get cephcluster
## 删除operator及相关资源
kubectl delete -f operator.yaml
kubectl delete -f common.yaml
# 所有rook节点运行，删除rook集群数据
rm -rf /var/lib/rook

## 在rook集群使用到的k8s节点上，**备份数据后删除**
# 删除所有分区，需要对所有用到的磁盘进行操作。sgdisk是Linux下操作GPT分区的工具，就像fdisk是操作MBR分区的工具
# yum install -y gdisk # 安装sgdisk工具。参考[shell](/_posts/linux/shell.md#linux命令)
sgdisk --zap-all /dev/sdb
/usr/sbin/wipefs --all /dev/sdb
# 在每个节点上删除映射
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
rm -rf /dev/mapper/ceph-*
rm -rf /dev/ceph-*
# 删除osd节点的数据目录
rm -rf /data/rook
```

### Ceph工具箱

- 安装相应pod

```bash
cd /root/k8s/rook-1.1.2/cluster/examples/kubernetes/ceph # 上文安装目录
# 可修改 `spec.template.spec.nodeSelector: kubernetes.io/hostname: node3` 让此pod运行在某个节点上(此工具部署在哪个节点就只能操作哪个节点)
kubectl apply -f toolbox.yaml
kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o wide
# 连接此pod。如果pod运行在node3，则连接后命令行显示成node3(类似ssh连接node3)，然后运行ceph相关命令(不能直接在node3上运行)
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
# 连接pod后运行ceph命令
ceph status
# 使用完工具箱后，可以删除部署
kubectl -n rook-ceph delete deployment rook-ceph-tools
```

### 常见错误

- 排错技巧

```bash
# 查看Rook pod状态
kubectl get pod -n rook-ceph -o wide
# 查看Rook pods日志
kubectl logs -n rook-ceph -l app=rook-ceph-operator # **查看operator日志**：operator会负责连接mon服务，只有mon选举成功，才会启动osd服务
kubectl logs -n rook-ceph -l mon=a
# 登录特定k8s节点以查找PVC挂载失败的原因
journalctl -u kubelet -f -n 100 # 查看kubelet日志
# 有多个容器的pods
kubectl -n rook-ceph logs <pod-name> --all-containers # 对于所有容器
kubectl -n rook-ceph logs <pod-name> -c <container-name> # 对于单个容器
kubectl -n rook-ceph logs --previous <pod-name> # 不再运行的Pod的日志
```
- 常见问题

```bash
### 问题日志 
## 1.存储消费者(Pod)报错："Unable to mount volumes for pod "sq-rook-ceph-ftp_default(829ca564-9f3b-4017-8eb2-feac02c0fbe1)": timeout expired waiting for volumes to attach or mount for pod "default"/"sq-rook-ceph-ftp". list of unmounted volumes=[ftp-data]. list of unattached volumes=[ftp-data default-token-bmlnx]"
# 检查rook-ceph是否正常运行
# `kubectl get pv`、`kubectl get pvc`确保都处于Bound状态，否则查看 rook-ceph-operator 日志
kubectl -n rook-ceph logs `kubectl -n rook-ceph -l app=rook-ceph-operator get pods -o jsonpath='{.items[*].metadata.name}'`

## 2.operator-pod报错："ceph mon_status exec: timed out"。且此时只有operator-pod运行，osd-pod未运行，且只有一个mon-a-pod处于运行状态，dashboard也无法访问
# 参考 https://rook.io/docs/rook/v1.1/ceph-common-issues.html#Monitors are the only pods running
# 可能原因：operator-pod与mon-pod网络不通；mon-pod无法启动；一个或多个mon-pod处于运行状态，但无法选举成功

## 3.mon-abd-pod运行中，osd-prepare-pod-node3运行中，osd-pod一直未运行，dashboard可以访问。查看osd-prepare-pod日志显示cephosd: skipping device sda that is in use (not by rook). fs: , ownPartitions: false；cephosd: no more devices to configure。且此之前node3处于rook集群中，被rook进行了分区和挂载
# cluster.yaml中的spec.storage.nodes使用无分区的裸磁盘

## 4.prepare-pod日志显示："ceph-volume lvm batch: error: GPT headers found, they must be removed on: /dev/sdb"。且osd-pod也不会创建，prepare-pod一直处于CrashLoopBackOff状态，之后被k8s清除，大概要等15min才会重新创建
# 需要重新清空磁盘分区，参考上文"删除整个集群"
sgdisk --zap-all /dev/sdb # 格式化
/usr/sbin/wipefs --all /dev/sdb # 擦除磁盘
# (解决)测试时操作上述命令情况也无法成功，然后通过ceph-toolbox(需要运行在此问题节点上)手动运行命令分区后，osd-pod成功创建。参考：https://forum.proxmox.com/threads/recommended-way-of-creating-multiple-osds-per-nvme-disk.52252/
# 上述错误实际是运行`stdbuf -oL ceph-volume lvm batch --prepare --bluestore --yes --osds-per-device 1 /dev/sdb --report`此命令导致的
ceph-volume lvm zap --destroy /dev/sdb # ceph-volume格式化命令
# 主要是通过ceph-volume执行zap，此命令也可交由prepare-pod自动完成
ceph-volume lvm batch --osds-per-device 1 /dev/sdb # 参考下文ceph-volume部分，batch表示基于已有的OSDs进行修改

## 5.集群在初始化后，operator会自动给mon-pod添加`Node-Selectors:  kubernetes.io/hostname=xxx`
# mon-pod 是有状态服务，rook将其状态写入dataDirHostPath。自动加上Node-Selectors以备重新创建mon也在改机器上，从而可以获取之前mon的配置数据
# 设计参考：https://github.com/rook/rook/blob/master/design/mon-health.md
# osd-pod也是如此会自动添加Node-Selectors

## 6.osd-pod提示"PostStartHookError: command 'chown --recursive ceph:ceph /var/log/ceph /home/data/osd1' exited with 126"
# 测试是改osd1无法成功移除，可删除对应osd-deploy

## 7.operator-pod一直提示"op-k8sutil: batch job rook-ceph-detect-version still exists"
# 可强制删除rook-ceph-detect-version重新创建pod
```

### 说明

#### 测试案例

- Ceph OSD 存储空间不足，会导致Pod调度失败，一直处于Pending状态
- PVC申请100M
    - 上传一个大于100M的文件，在差不多100M处卡死，然后提示出错(文件没有上传上去)。重新上传一个小文件是可正常上传的
    - 使用ceph工具 `rbd du replicapool-test/csi-vol-0f73ed14-df67-11e9-8202-1294917b9bfd` 显示的PROVISIONED和USED都是100M(实际只用了几M)
- rdb数据位置和可用性
    - `lsblk` 可查看pvc申请创建的rdb存储块，此处/dev/rbd0类似一个虚拟磁盘
    - rdb存储块创建后，即使删除整个ceph集群，rdb数据也会保留；删除osd0等目录，rdb存储块上的数据也不会丢失
    - `rook-ceph-osd-osd-0-xxx` 对应的所有pod停止运行也不会影响之前创建的rdb磁盘的使用；但是如果`rook-ceph-mon-pod`无法正常运行或选举则rdb磁盘无法读写

#### 备注

- 原理说明
    - `rook-ceph-operator-pod` 是整个集群的管理者
    - `rook-discover-pod`是运行在每个k8s节点上的守护进程，用来探测改节点是否有可用磁盘(如刚进行连接的空磁盘)
    - 如果发现则将参数传递给对应节点的osd创建器，如`rook-ceph-osd-prepare-node3-pod`。会接受到参数如 <i>rookcmd: flag values: --cluster-id=85e086d5-6017-4c52-85d7-e266a82ae382, --data-device-filter=, --data-devices=sdb:1:::, --data-directories=/data/rook, --encrypted-device=false, --force-format=false, --help=false, --location=, --log-flush-frequency=5s, --log-level=INFO, --metadata-device=, --node-name=node3, --operator-image=, --osd-database-size=0, --osd-journal-size=5120, --osd-store=, --osd-wal-size=576, --osds-per-device=1, --pvc-backed-osd=false, --service-account=, --topology-aware=false</i>
    - `rook-ceph-osd-prepare-node3-pod`主要负责创建osd，包括在/data/rook创建类似osd0的子目录。此pod由job控制器`rook-ceph-osd-prepare-node3`进行控制，可describe查看此job的任务描述

## Ceph

### 简介

- [Ceph官网](https://ceph.com/)、[官方文档 v14.2.4 Nautilus](https://docs.ceph.com/docs/nautilus/start/intro/)、[github源码](https://github.com/ceph/ceph)
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
- Ceph 组件 [^1]

    ![ceph组件](/data/images/devops/ceph.png)
    - `Monitor`：负责监视整个集群的运行状况，信息由维护集群成员的守护程序来提供。不存储任何数据，主要包含以下Map
        - `Monitor map`：包括有关monitor 节点端到端的信息，其中包括 Ceph 集群ID，监控主机名和IP以及端口。并且存储当前版本信息以及最新更改信息，通过 `ceph mon dump` 查看 monitor map
        - `OSD map`：包括一些常用的信息，如集群ID、创建OSD map的 版本信息和最后修改信息，以及pool相关信息，主要包括pool 名字、pool的ID、类型，副本数目以及PGP等，还包括数量、状态、权重、最新的清洁间隔和OSD主机信息。通过命令 `ceph osd dump` 查看
        - `PG map`：包括当前PG版本、时间戳、最新的OSD Map的版本信息、空间使用比例，以及接近占满比例信息，同时包括每个PG ID、对象数目、状态、OSD 的状态以及深度清理的详细信息。通过命令 `ceph pg dump` 可以查看相关状态
        - `CRUSH map`： 包括集群存储设备信息，故障域层次结构和存储数据时定义失败域规则信息。通过 命令 `ceph osd crush map` 查看
        - `MDS map`：包括存储当前 MDS map 的版本信息、创建当前的Map的信息、修改时间、数据和元数据POOL ID、集群MDS数目和MDS状态，可通过 `ceph mds dump` 查看
    - `OSD`(Object Storage Device/Daemon)：是由物理磁盘驱动器、在其之上的 Linux 文件系统以及 Ceph OSD 服务组成。Ceph OSD 将数据以对象的形式存储到集群中的每个节点的物理磁盘上，完成存储数据的工作绝大多数是由 OSD daemon 进程实现。在构建 Ceph OSD的时候，建议采用SSD 磁盘以及xfs文件系统来格式化分区
    - `MDS`(Ceph Metadata Server)：Ceph 元数据，ceph 块设备和RDB并不需要MDS，MDS只为 CephFS服务
    - `RADOS`(Reliable Autonomic Distributed Object Store)：RADOS是ceph存储集群的基础。在ceph中，所有数据都以对象的形式存储，并且无论什么数据类型，RADOS对象存储都将负责保存这些对象。RADOS层可以确保数据始终保持一致
    - `librados` 和 RADOS 交互的基本库，为应用程度提供访问接口。同时也为块存储、对象存储、文件系统提供原生的接口。Ceph 通过原生协议和 RADOS 交互，Ceph 把这种功能封装进了 librados 库，这样也能定制自己的客户端
    - `ADOS块设备`：能够自动精简配置并可调整大小，而且将数据分散存储在多个OSD上
    - `RADOSGW`(RGW)：对象网关守护进程，提供对象存储服务
    - `CephFS`：Ceph文件系统，与POSIX兼容的文件系统，基于librados封装原生接口
- `PG`(Placement Grouops)，是一个逻辑的概念，一个PG包含多个OSD

### 相关命令

#### 常用

```bash
# 查看集群状态
ceph -s

# 列举已映射块设备(pool、image等信息)
rbd showmapped
```

#### ceph

```bash
ceph -h
ceph -v # ceph version 14.2.4 (75f4de193b3ea58512f204623e6c5a16e6c1e1ba) nautilus (stable)
# 查看集群状态
ceph -s
# 获取法定节点信息
ceph quorum_status --format json-pretty
```

#### rbd 块存储

```bash
usage: rbd <command> ...

Command-line interface for managing Ceph RBD images.

Positional arguments:
  <command>
    bench                             Simple benchmark.
    children                          Display children of an image or its snapshot.
    clone                             Clone a snapshot into a CoW child image.
    config global get                 Get a global-level configuration override.
    config global list (... ls)       List global-level configuration overrides.
    config global remove (... rm)     Remove a global-level configuration override.
    config global set                 Set a global-level configuration override.
    config image get                  Get an image-level configuration override.
    config image list (... ls)        List image-level configuration overrides.
    config image remove (... rm)      Remove an image-level configuration override.
    config image set                  Set an image-level configuration override.
    config pool get                   Get a pool-level configuration override.
    config pool list (... ls)         List pool-level configuration overrides.
    config pool remove (... rm)       Remove a pool-level configuration override.
    config pool set                   Set a pool-level configuration override.
    copy (cp)                         Copy src image to dest.
    create                            Create an empty image.
        # rbd create myrbd --size 4096 --image-feature layering -p mypool # 在mypool存储池中，创建块设备镜像myrbd，大小为4096M
    deep copy (deep cp)               Deep copy src image to dest.
    device list (showmapped)          List mapped rbd images.
        # rbd showmapped    # **列举已映射块设备(pool、image等信息)**
    device map (map)                  Map an image to a block device. # 映射块设备
        # sudo rbd map myrbd --name client.admin -p mypool # 执行成功打印`/dev/rbd0`
    device unmap (unmap)              Unmap a rbd device. # 取消块设备映射
        # sudo rbd unmap /dev/rbd0 # 取消块设备映射
    diff                              Print extents that differ since a previous snap, or image creation.
    disk-usage (du)                   Show disk usage stats for pool, image or snapshot.
        # rbd du pool-test/csi-image    # 显示 pool-test/csi-image 镜像使用情况
    export                            Export image to file.
    export-diff                       Export incremental diff to file.
    feature disable                   Disable the specified image feature.
    feature enable                    Enable the specified image feature.
    flatten                           Fill clone with parent data (make it independent).
    group create                      Create a group.
    group image add                   Add an image to a group.
    group image list (... ls)         List images in a group.
    group image remove (... rm)       Remove an image from a group.
    group list (group ls)             List rbd groups.
    group remove (group rm)           Delete a group.
    group rename                      Rename a group within pool.
    group snap create                 Make a snapshot of a group.
    group snap list (... ls)          List snapshots of a group.
    group snap remove (... rm)        Remove a snapshot from a group.
    group snap rename                 Rename group''s snapshot.
    group snap rollback               Rollback group to snapshot.
    image-meta get                    Image metadata get the value associated with the key.
    image-meta list (image-meta ls)   Image metadata list keys with values.
    image-meta remove (image-meta rm) Image metadata remove the key and value associated.
    image-meta set                    Image metadata set key with value.
    import                            Import image from file.
    import-diff                       Import an incremental diff.
    info                              Show information about image size, striping, etc.
        # rbd info replicapool-test/csi-vol-436aafe9-df4b-11e9-854c-1ae38aa085c6    # 查看某个存储块信息
    journal client disconnect         Flag image journal client as disconnected.
    journal export                    Export image journal.
    journal import                    Import image journal.
    journal info                      Show information about image journal.
    journal inspect                   Inspect image journal for structural errors.
    journal reset                     Reset image journal.
    journal status                    Show status of image journal.
    list (ls)                         List rbd images.
        # rbd ls replicapool-test   # 列举 replicapool-test 存储块池中的存储块
    lock add                          Take a lock on an image.
    lock list (lock ls)               Show locks held on an image.
        # rbd lock list pool-test/csi-image     # 显示 pool-test/csi-image 镜像被锁定列表
    lock remove (lock rm)             Release a lock on an image.
        # 解除锁定
    merge-diff                        Merge two diff exports together.
    migration abort                   Cancel interrupted image migration.
    migration commit                  Commit image migration.
    migration execute                 Execute image migration.
    migration prepare                 Prepare image migration.
    mirror image demote               Demote an image to non-primary for RBD mirroring.
    mirror image disable              Disable RBD mirroring for an image.
    mirror image enable               Enable RBD mirroring for an image.
    mirror image promote              Promote an image to primary for RBD mirroring.
    mirror image resync               Force resync to primary image for RBD mirroring.
    mirror image status               Show RBD mirroring status for an image.
    mirror pool demote                Demote all primary images in the pool.
    mirror pool disable               Disable RBD mirroring by default within a pool.
    mirror pool enable                Enable RBD mirroring by default within a pool.
    mirror pool info                  Show information about the pool mirroring configuration.
    mirror pool peer add              Add a mirroring peer to a pool.
    mirror pool peer remove           Remove a mirroring peer from a pool.
    mirror pool peer set              Update mirroring peer settings.
    mirror pool promote               Promote all non-primary images in the pool.
    mirror pool status                Show status for all mirrored images in the pool.
    namespace create                  Create an RBD image namespace.
    namespace list (namespace ls)     List RBD image namespaces.
    namespace remove (namespace rm)   Remove an RBD image namespace.
    object-map check                  Verify the object map is correct.
    object-map rebuild                Rebuild an invalid object map.
    perf image iostat                 Display image IO statistics.
    perf image iotop                  Display a top-like IO monitor.
    pool init                         Initialize pool for use by RBD.
    pool stats                        Display pool statistics.
    remove (rm)                       Delete an image. # 删除块设备映像
        # rbd rm {pool-name}/{image-name}
    rename (mv)                       Rename image within pool.
    resize                            Resize (expand or shrink) image. # 调整块设备映像大小
        # rbd resize --size 2048 myrbd # 增大myrbd存储块。最终大小为2048M，下同
        # rbd resize --size 2048 myrbd --allow-shrink # 缩小myrbd存储块
    snap create (snap add)            Create a snapshot.
    snap limit clear                  Remove snapshot limit.
    snap limit set                    Limit the number of snapshots.
    snap list (snap ls)               Dump list of image snapshots.
    snap protect                      Prevent a snapshot from being deleted.
    snap purge                        Delete all unprotected snapshots.
    snap remove (snap rm)             Delete a snapshot.
    snap rename                       Rename a snapshot.
    snap rollback (snap revert)       Rollback image to snapshot.
    snap unprotect                    Allow a snapshot to be deleted.
    sparsify                          Reclaim space for zeroed image extents.
    status                            Show the status of this image.
    trash list (trash ls)             List trash images.
    trash move (trash mv)             Move an image to the trash.
    trash purge                       Remove all expired images from trash.
    trash remove (trash rm)           Remove an image from trash.
    trash restore                     Restore an image from trash.
    watch                             Watch events on image.

Optional arguments:
  -c [ --conf ] arg     path to cluster configuration
  --cluster arg         cluster name
  --id arg              client id (without 'client.' prefix)
  --user arg            client id (without 'client.' prefix)
  -n [ --name ] arg     client name
  -m [ --mon_host ] arg monitor host
  --secret arg          path to secret key (deprecated)
  -K [ --keyfile ] arg  path to secret key
  -k [ --keyring ] arg  path to keyring

See 'rbd help <command>' for help on a specific command.
```

#### ceph-volume

- 作用：使用物理磁盘或lvm创建Ceph OSDs
- [Doc](https://docs.ceph.com/docs/nautilus/ceph-volume/)

```bash
ceph-volume -h

Available subcommands:

lvm                      Use LVM and LVM-based technologies like dmcache to deploy OSDs
    activate                 Discover and mount the LVM device associated with an OSD ID and start the Ceph OSD
    prepare                  Format an LVM device and associate it with an OSD
    create                   Create a new OSD from an LVM device
    list                     list logical volumes and devices associated with Ceph # 列举和ceph相关的逻辑卷和设备
    batch                    Automatically size devices for multi-OSD provisioning with minimal interaction
        --osds-per-device       # 此osd节点的每个设备可创建介个osd介质(分区，如osd0和osd1目录)，默认1
        # ceph-volume lvm batch --osds-per-device 2 /dev/sdb # 将/dev/sdb分成2个分区，运行命令后会显示预览，输入yes后正式进行分区(实际是使用系统lvm进行分区)
    trigger                  systemd helper to activate an OSD
    zap                      Removes all data and filesystems from a logical volume or partition.
simple                   Manage already deployed OSDs with ceph-volume
inventory                Get this nodes available disk inventory # 查看节点的存储设备(如连接的物理磁盘)

optional arguments:
  -h, --help            show this help message and exit
  --cluster CLUSTER     Cluster name (defaults to "ceph")
  --log-level LOG_LEVEL
                        Change the file log level (defaults to debug)
  --log-path LOG_PATH   Change the log path (defaults to /var/log/ceph)
```

### 手动安装(基于ceph-deploy安装)

1. 准备工作(所有节点运行)

```bash
# node1(192.168.6.131)  mon osd deploy
# node2(192.168.6.132)  mon osd
# node3(192.168.6.133)  mon osd

## 所有节点运行
yum update -y
sudo yum install -y ntp ntpdate ntp-doc # 保证各节点时间基本一致
sudo ntpdate 0.cn.pool.ntp.org # 与国家授时中心同步
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
3. 安装STORAGE CLUSTER(deploy节点运行)

```bash
# 参考：https://docs.ceph.com/docs/nautilus/start/quick-ceph-deploy/#create-a-cluster
# 初始化monitor
ceph-deploy new node1 node2 node3 # 在/opt/ceph-cluster目录创建配置文件
# 安装ceph(会创建/var/lib/ceph/目录)。有可能其中某个节点因为下载rpm Timeout导致安装失败可重新install该节点，安装成功的可执行`ceph --version`查看版本()
ceph-deploy install node1 node2 node3
# ceph-deploy install --release luminous node1 # 安装指定版本

# 开始部署monitor(会自动启动ceph-mon，监听在6789端口)
ceph-deploy mon create-initial
ceph -s # 查看集群状态(ceph)。mon: 3 daemons, quorum node1,node2,node3 (age 7m)
# (可选)拷贝配置文件和admin的秘钥到其他节点，从而该节点可使用ceph CLI
ceph-deploy admin node1 node3

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

# 创建OSD。此处/dev/sdb为刚物理连接上去的空磁盘，ceph会自动进行分区
ceph-deploy osd create --data /dev/sdb node1
ceph-deploy osd create --data /dev/sdb node2
ceph-deploy osd create --data /dev/sdb node3
# 如果在LVM卷上创建OSD，那么--data的参数必须是volume_group/lv_name，而不是卷块设备的路径
ceph -s # osd: 3 osds: 3 up (since 20s), 3 in (since 20s)
lsblk # 在OSD节点上运行查看磁盘分区，会发现有一个`ceph--a3202c2d-xxx`的lvm分区
```
- 安装失败可进行清理环境后重新安装

```bash
ceph-deploy purge node1 node2 node3 # 如果执行purge，则需要重新安装ceph
ceph-deploy purgedata node1 node2 node3 # 删除/var/lib/ceph、/etc/ceph目录
ceph-deploy forgetkeys
rm -f ceph.* # 移除/opt/ceph-cluster目录配置文件
```

### 简单使用

#### 块设备使用(rbd)

```bash
# 块设备使用。参考：https://docs.ceph.com/docs/nautilus/start/quick-rbd/#create-a-block-device-pool
## **(deploy节点运行)**创建并初始化pool
# 创建pool。参考：https://docs.ceph.com/docs/nautilus/rados/operations/pools/#create-a-pool
# PG数量的预估。集群中单个池的PG数计算公式如下：PG 总数 = (OSD 数 * 100) / 最大副本数 / 池数 (结果必须舍入到最接近2的N次幂的值)
ceph osd pool create mypool 128 # pool 'mypool' created。创建名为mypool的存储池
# 初始化pool
rbd pool init mypool

## **(在某个osd节点)**配置块设备
# 在mypool存储池中，创建块设备镜像myrbd，大小为4096M
rbd create myrbd --size 4096 --image-feature layering -p mypool
# 映射块设备
sudo rbd map myrbd --name client.admin -p mypool # /dev/rbd0
# 给此块设备创建文件系统，期间需要回车几次
sudo mkfs.ext4 -m0 /dev/rbd/mypool/myrbd # 或者 `sudo mkfs.xfs /dev/rbd0`
# 挂载
sudo mkdir /mnt/ceph-myrbd
sudo mount /dev/rbd/mypool/myrbd /mnt/ceph-myrbd
df -h /mnt/ceph-myrbd
# 将数据写入块设备来进行检测
sudo dd if=/dev/zero of=/mnt/ceph-myrbd/test count=100 bs=1M # 104857600 bytes (105 MB) copied, 11.3 s, 9.3 MB/s
sudo ls -lh /mnt/ceph-myrbd
```

#### 文件存储使用(CephFS)

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
# dmesg | grep ceph # 出错可通过此命令查看mount错误。如报错：`libceph: mon0 192.168.6.131:6789 missing required protocol features`，最终选用ceph-fuse进行挂载
# sudo mount -t ceph {ip-address-of-monitor1,ip-address-of-monitor2}:6789:/ /mnt/mycephfs -o name=admin,secret=xxx
sudo mount -t ceph 192.168.6.131:6789:/ /mnt/mycephfs -o name=admin,secret=AQA9BZ9dMUA7BBAAYCTiaV1cTACP7GSLDxDmBg== # 提示`ceph-fuse[14371]: starting fuse`则正确
df -h
sudo dd if=/dev/zero of=/mnt/mycephfs/test count=1024 bs=1M # 测试。1073741824 bytes (1.1 GB) copied, 156.862 s, 6.8 MB/s
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

#### 对象存储

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




---

参考文章

[^1]: https://www.cnblogs.com/yangxiaoyi/p/7795274.html
[^2]: https://blog.fleeto.us/post/kubernetes-storage-performance-comparison/ (Kubernetes 存储性能对比)
[^3]: https://blog.51cto.com/bigboss/2320016
[^4]: https://sealyun.com/post/rook
[^5]: http://manjusri.ucsc.edu/2017/09/25/ceph-fuse/


