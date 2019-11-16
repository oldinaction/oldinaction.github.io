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

```yml
## cluster.yaml
# ...
spec:
    # 存储rook节点配置信息、日志信息。dataDirHostPath数据存储在k8s节点(宿主机)目录，会自动在rook选择的k8s节点上创建此目录。如果osd目录(directories)没指定或不可用，则默认在此目录创建osd
    # rook对应pod删除后此目录会保留，重新安装rook集群时，此目录必须无文件
    dataDirHostPath: /var/lib/rook # 默认值即可
```

