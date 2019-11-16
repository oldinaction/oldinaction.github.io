---
layout: "post"
title: "Rook | K8s存储协调器"
date: "2019-09-23 09:38"
categories: devops
tags: [k8s, storage, cncf]
--- 

## 简介

- TODO rook v1.1.2 测试使用不是很流畅，会出现一些诡异的问题，待rook毕业
- [Rook](https://rook.io) 是Kubernetes的开源云本地存储协调器，为各种存储解决方案提供平台，框架和支持，以便与云原生环境本地集成。是云原生计算基金会(CNCF)的孵化级项目。Rook 目前支持 `Ceph`、`NFS`、`Minio Object Store`、`Edegefs`、`Cassandra`、`CockroachDB` 存储的搭建，使用 Rook 可以轻松实现在 Kubernetes 上部署并运行 Ceph 存储系统

## Rook-Ceph

- [Ceph](https://ceph.com/) 是一个分布式存储系统，目前提供`对象存储(RADOSGW)`、`块存储RDB`以及`CephFS文件系统`这3种功能，并且提供Ceph REST API。具体见[http://blog.aezo.cn/2019/11/14/devops/ceph/](/_posts/devops/ceph.md) [^1]
- k8s存储选型：`Rook`/`Ceph` [^2]

### 安装 Rook-Ceph

- 参考 https://rook.io/docs/rook/v1.1/ceph-quickstart.html [^3] [^4]

```bash
### 所有节点开启ip_forward，k8s的node节点一般都已经开启过
cat > /etc/sysctl.d/ceph.conf << EOF
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
## 安装并查看operator是否成功(会创建命名空间rook-ceph)
kubectl apply -f common.yaml
# 修改镜像配置
# 如默认使用CSI驱动，需修改相关插件镜像，见下文说明。CSI驱动程序，它是K8s 1.13及更高版本以后的首选驱动程序，较早的Flex驱动默认是关闭的
sed -i 's#quay.io#quay.mirrors.ustc.edu.cn#g' operator.yaml # 修改镜像后，启用此镜像
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

```bash
## operator.yaml
# ...
xxx: 
- name: ROOK_CSI_CEPH_IMAGE
  value: "quay.mirrors.ustc.edu.cn/cephcsi/cephcsi:v1.2.1"
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

