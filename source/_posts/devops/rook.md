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

### 常见问题

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




---

参考文章

[^1]: https://www.cnblogs.com/yangxiaoyi/p/7795274.html
[^2]: https://blog.fleeto.us/post/kubernetes-storage-performance-comparison/ (Kubernetes 存储性能对比)
[^3]: https://blog.51cto.com/bigboss/2320016
[^4]: https://sealyun.com/post/rook

