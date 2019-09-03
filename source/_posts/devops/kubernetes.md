---
layout: "post"
title: "Kubernetes"
date: "2019-06-01 12:38"
categories: devops
tags: [k8s, docker]
---

## 简介

- [官网](https://kubernetes.io/zh)、[github](https://github.com/kubernetes/kubernetes)、[Doc](https://kubernetes.io/zh/docs/)
- 相关文章：https://github.com/rootsongjc/kubernetes-handbook/ 、 https://www.cnblogs.com/linuxk/category/1248289.html (视频相关) 、 https://feisky.gitbooks.io/kubernetes/content/
- 镜像: `k8s.gcr.io`一般对应`registry.aliyuncs.com/google_containers`

### 背景

- `Kubernetes`是Google基于`Borg`开源的容器编排调度引擎，作为`CNCF`(Cloud Native Computing Foundation)最重要的组件之一，它的目标不仅仅是一个编排系统，而是提供一个规范，可以让你来描述集群的架构，定义服务的最终状态，Kubernetes可以帮你将系统自动地达到和维持在这个状态。Kubernetes作为云原生应用的基石
- 自动化运维演进
    - `Ansible`是一种自动化运维工具，基于paramiko开发的，并且基于模块化工作，Ansible是一种集成IT系统的配置管理、应用部署、执行特定任务的开源平台，它是基于python语言，由Paramiko和PyYAML两个关键模块构建。同类型的如`Puppet`
    - Docker容器编排
        - Docker三剑客：docker compose(面向单击编排)、docker swarm(面向多机编排)、docker machine(将一个主机初始化为swarm节点)
        - mesos(资源分配工具)、marathon(面向容器的编排框架)
        - kubernetes(市场占据80%份额)
- `Docker`与`K8s`(kubernetes)
    - Docker本质上是一种虚拟化技术，类似于KVM、XEN、VMWARE，但其更轻量化，且将Docker部署在Linux环境时，其依赖于Linux容器技术(LXC)。Docker较传统KVM等虚拟化技术的一个区别是无内核，即多个Docker虚拟机共享宿主机内核，简而言之，可把Docker看作是无内核的虚拟机，每Docker虚拟机有自己的软件环境，相互独立
    - K8s与Docker之间的关系，如同Openstack之于KVM、VSphere之于VMWARE。K8S是容器集群管理系统，底层容器虚拟化可使用Docker技术，应用人员无需与底层Docker节点直接打交道，通过K8s统筹管理即可
- 相关概念
    - `DevOps` 是开发与运维之间沟通的过程。透过自动化"软件交付"和"架构变更"的流程，来使得构建、测试、发布软件能够更加地快捷、频繁和可靠
    - `CI` 持续集成
    - `CD` 持续交付，Delivery
    - `CD` 持续部署，Deployment
    - `Service Mesh`
- `kubefed`(`Kubernetes Federation V2`) K8s 的设计定位是单一集群在同一个地域内，因为同一个地区的网络性能才能满足 K8s 的调度和计算存储连接要求。而集群联邦(Federation)就是为提供跨 Region 跨服务商 K8s 集群服务而设计的

### 概念

- 整体架构

    ![kubernetes-arch](/data/images/devops/kubernetes-arch.png)
- Kubernetes主要由以下几个核心组件组成
    - `etcd` 保存了整个集群的状态
    - `API Server` 提供了资源操作的唯一入口(CLI/GUI)，并提供认证、授权、访问控制、API注册和发现等机制
    - `Controller Manager` 负责维护集群的状态，比如故障检测、自动扩展、滚动更新等
    - `Scheduler` 负责资源的调度，按照预定的调度策略将Pod调度到相应的机器上
    - `Kubelet` 负责维护容器的生命周期，同时也负责Volume(CSI)和网络(CNI)的管理
    - `Container Runtime` 负责镜像管理以及Pod和容器的真正运行(CRI)
    - `Kube-proxy` 负责为Service提供cluster内部的服务发现和负载均衡
- 其他附件(AddOns)，推荐额外插件
    - `CoreDNS` 负责为整个集群提供DNS服务
    - `Dashboard` 提供GUI
    - `Ingress Controller` 为服务提供外网入口
    - `Prometheus` 提供资源监控
    - `Federation` 提供跨可用区的集群
- 名词概念
    - `Master` 包含etcd、API Server、Scheduler、Controller Manager；Kubernetes由`Master`和`Node`节点组成；Master至少一个，也可部署多个实现HA
    - `Node` 包含Kubelet、Container Runtime、Kube-proxy；Node节点一般为多个，运行容器的物理节点
    - `Pod` 每个Node可以理解为一个docker宿主机；一个Node中可以包含多个`Pod`(Kubernetes的最小可执行单元)；一个Pod上可以运行多个容器(一般只有一个)，K8s不直接操作容器而是操作Pod，此时Pod中运行的多个容器共用一些物理参数(如hostname)，此时Pod类似于虚拟机
        - `Label` 为了区分Pod，可以给每个Pod加一些元数据标签Label(Key-Value)。可通过`Label Selector`挑选出对应的Label
    - **控制器`Controller Manager`**(自动管理Pod的生命周期)
        - `ReplicationController`(RC，每个Pod保存一个副本，早先K8s版本)
        - `ReplicaSet`(RS，副本集)：`Deployment`(管理无状态)、`StatefulSet`(管理有状态，如mysql节点)、`DaemonSet`(每个Node运行一个特定Pod)、`Job`(运行一次任务)、`Cronjob`(周期运行任务)
        - `HorizontalPodAutoscaler`(`HPA`，自动水平伸缩控制器)
    - `Service` 服务
        - RC、RS和Deployment只是保证了支撑服务的微服务Pod的数量，但是没有解决如何访问这些服务的问题，一个Pod的IP和端口随时可能发生变化，要稳定地提供服务需要服务发现和负载均衡能力
        - 客户端需要访问的服务就是Service对象，每个Service会对应一个集群内部有效的虚拟IP，集群内部通过虚拟IP访问一个服务
        - 在Kubernetes集群中微服务的负载均衡是由Kube-proxy实现的
        - Service是手动创建的，可以创建成供K8s外部访问或只能内部访问的

        ![k8s-service](/data/images/devops/k8s-service.png)
    - Cluster(集群) 和 Namespace(命名空间) 
        - Cluster 是计算、存储和网络资源的集合，Kubernetes 利用这些资源运行各种基于容器的应用，最简单的 Cluster 可以只有一台主机(它既是 Mater 也是 Node)，安装的默认集群为`kubernetes`
        - Namespace 可以将一个物理的 Cluster 逻辑上划分成多个虚拟 Cluster，每个 Cluster 就是一个 Namespace。不同 Namespace 里的资源是完全隔离的
            - Kubernetes 默认创建了两个 Namespace：kube-system 和 default

## K8s集群安装

### 基于kubeadm安装k8s

- 环境介绍
    - 基于Centos7.3(3.10.0-514.el7.x86_64)安装`kubernetes-1.15.0`
    - node1(192.168.6.131，2C2G勉强可测试)、node2(192.168.6.132，2C2G)、node3(192.168.6.133，2C2G)；node1为Master节点，node2和node3为Node节点
    - 默认使用root用户操作
- 安装步骤 [^1] [^2]

```bash
### (所有节点)环境配置
# 更新软件版本和内核次版本。初始化机器可执行，生成环境不建议重复更新内核版本
yum update

## A.关闭防火墙等
systemctl stop firewalld && systemctl disable firewalld && setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# 开启bridge转发
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
# 关闭系统的Swap，如果不关闭，默认配置下kubelet将无法启动；亦可通过参数设置不关闭Swap。特别是已经运行了其他应用的服务器，可通过参数忽略Swap校验，此时则无需关闭
# vm.swappiness=0
EOF
# 关闭交换分区。也可将/etc/fstab中swap的挂载注释掉
swapoff -a && sysctl -w vm.swappiness=0
# 使生效
modprobe br_netfilter # 加载内核br_netfilter模块
sysctl -p /etc/sysctl.d/k8s.conf

## B.配置hostname(需要保证唯一)
hostnamectl --static set-hostname node1 # 可考虑取名成 k8s-main-master-1 等
hostnamectl --static set-hotname node2
hostnamectl --static set-hostname node3
cat >> /etc/hosts <<EOF
192.168.6.131 node1
192.168.6.132 node2
192.168.6.133 node3
EOF

## C.(可选配置)关于ipvs：如果以下前提条件不满足，则即使kube-proxy的配置开启了ipvs模式，也会退回到iptables模式
# 由于ipvs已经加入到了内核的主干，所以为kube-proxy开启ipvs的前提需要加载以下的内核模块。以下文件保证在节点重启后能自动加载所需模块
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
yum install ipset # 需要确保各个节点上已经安装了ipset软件
# yum install ipvsadm # 便于查看ipvs的代理规则

## D.安装Docker(下列1-3步骤网上部分案例未执行)
yum install -y yum-utils device-mapper-persistent-data lvm2
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum list docker-ce.x86_64 --showduplicates | sort -r # 查看docker版本
yum makecache fast # 更新缓存
yum install -y --setopt=obsoletes=0 docker-ce-18.09.7-3.el7 # 安装docker
systemctl start docker && systemctl enable docker
# 1.确认一下iptables filter表中FOWARD链的默认策略(pllicy)为ACCEPT
iptables -nvL
# 2.修改docker cgroup driver为systemd
# cat > /etc/docker/daemon.json <<EOF
# {
#   "exec-opts": ["native.cgroupdriver=systemd"]
# }
# EOF
# 3.重启docker，并确认cgroup driver生效
# systemctl restart docker
# docker info | grep Cgroup # 显示Cgroup Driver: systemd
# 4.如果registry为http可修改`vi /etc/docker/daemon.json`，并且提前进行harbor认证

### 使用kubeadm部署Kubernetes
## E.(所有节点安装)添加kubernetes yum源
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
# 刷新缓存
yum makecache fast
# 安装kubelet(运行Pod)、kubeadm(初始化节点)、kubectl(操作集群/API Server入口)。此时，kubelet也需要安装在Master机器上，因为API Server等也是基于Pod运行的(相当于自己运行自己)；kubectl一般安装在Master节点，都安装也行
yum install -y kubeadm-1.15.0 kubelet-1.15.0 kubectl-1.15.0
# (可选配置)如果不希望禁用swap
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS=--fail-swap-on=false
EOF
# 注意：kubelet无需手动启动，在kubeadm init初始化时会自动启动
systemctl daemon-reload && systemctl enable kubelet

## F.(**仅Master节点执行**，此处的node1机器需要执行) 启动(初始化)一个 Kubernetes主节点。如果不希望禁用swap，则需要加上`--ignore-preflight-errors=swap`；也可基于config.yml进行初始化，但是测试失败
# 安装成功显示`Your Kubernetes control-plane has initialized successfully!`，具体日志见下文`kubeadm init执行成功日志`；安装失败见常见错误处理。其中`10.244.0.0/16`为pod的网络，启动pod后会在Node上产生一个`cni0`的网桥
kubeadm init --kubernetes-version=v1.15.0 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=Swap --image-repository=registry.aliyuncs.com/google_containers
# 配置常规用户如何使用kubectl访问集群(使用非root用户操作，root用户也可如此操作)，即需要使用kubectl命令的机器进行配置(一般在Master上操作)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# 查看一下集群状态，确认个组件都处于healthy状态
kubectl get cs
kubectl get node # 此时只有一个主节点，状态为NotReady(由于还没有部署网络插件)

## G.(仅Master节点执行)安装网络插件(Pod Network插件flannel/canal。此处使用canal，canal内部会安装flannel镜像)。
mkdir -p ~/k8s/ && cd ~/k8s
#wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#kubectl apply -f kube-flannel.yml # 需要注意保证docker register私有仓库中已经有flannel镜像
wget https://docs.projectcalico.org/v3.8/manifests/canal.yaml
kubectl apply -f canal.yaml
# 查看集群状态(稍等一会全部进入Running状态)
kubectl get pods -o wide --all-namespaces # 其中kube-flannel-xxx/canal-xxx为Running状态
kubectl get node # 此时节点状态为Ready

## I.（仅所有Node节点执行）向Kubernetes集群中添加Node节点
# 在Master节点打印获取加入集群的命令
kubeadm token create --print-join-command
# Node节点运行加入集群命令，注意后面新加了swap参数。安装成功显示`This node has joined the cluster`
kubeadm join 192.168.6.131:6443 --token 3v4bja.hw4mwq5uknl3ruqn --discovery-token-ca-cert-hash sha256:3f315f28918e58cb5cdb1c4fbf47db8d1d3ab6169146079a7f8f60197ae17c12 --ignore-preflight-errors=Swap
# (在Master节点)查看节点是否成功加入
kubectl get node -o wide # ROLES显示`<none>`为正常，如果STATUS显示`NotReady`则表示节点还没有加入到集群
# (在Master节点)查看Pod运行情况，此时可以发现 flannel 对应的Pod在node1-node3都运行了。
# 至此，集群正常运行，安装完毕
kubectl get pods -o wide --all-namespaces

### (可选配置)Kube-proxy开启ipvs
## J.(**Master节点执行**)Kube-proxy开启ipvs
# 此命令即可打开配置文件，修改文件中config.conf的mode配置为 `mode: "ipvs"`
kubectl edit cm kube-proxy -n kube-system # 或者修改`/etc/sysconfig/kubelet`加入`KUBE_PROXY_MODE=ipvs`
# 打印 kube-proxy
kubectl get pods -n kube-system | grep kube-proxy
# 下列命令可重启各个节点上的kube-proxy pod。可能会卡死，可适当终止进程查看是否有变化
kubectl get pods -n kube-system | grep kube-proxy | awk '{system("kubectl delete pod "$1" -n kube-system")}'
# 再次打印 kube-proxy(编号会变化)
kubectl get pods -n kube-system | grep kube-proxy
# 选择其中某个 kube-proxy 执行下列命令，提示`Using ipvs Proxier`表示ipvs模式已经开启(默认是`Using iptables Proxier`)
kubectl logs kube-proxy-xxxxx -n kube-system
```

- kubeadm init执行成功日志

```bash
[root@node1 ~]# kubeadm init --kubernetes-version=v1.15.0 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=swap --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers --ignore-preflight-errors=SystemVerification
[init] Using Kubernetes version: v1.15.0
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [node1 localhost] and IPs [192.168.6.131 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [node1 localhost] and IPs [192.168.6.131 127.0.0.1 ::1]
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [node1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.6.131]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 17.502337 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.15" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node node1 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node node1 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: rxqii4.ov3v99x5bk2qi4ia
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.6.131:6443 --token rxqii4.ov3v99x5bk2qi4ia \
    --discovery-token-ca-cert-hash sha256:7a9a8a910ae2cad21a032afd289a00097ebfbc6d361fd9673644db0e264a4fd1
```
- **常用扩展安装**：`Helm`、`Ingress Control`、`Dashboard`、`metrics-server` 可手动安装或通过Helm安装
- 集群初始化(kubeadm init/kubeadm join)如果遇到问题，可以使用下面的命令进行清理

```bash
kubeadm reset
rm -rf /var/lib/etcd 
rm -rf /var/lib/cni/
ifconfig cni0 down
ip link delete cni0
ifconfig flannel.1 down
ip link delete flannel.1
```
- **从集群中移除Node**(以移除node3为例)

```bash
# 1.在master节点上执行
kubectl drain node3 --delete-local-data --force --ignore-daemonsets
kubectl delete node node3
# 2.在node3上执行上述清理命令
```

### 常见问题

- 镜像：k8s-rpm源和docker镜像的k8s仓库(image-repository)都需要使用国内镜像地址
- kubelet启动报错，`journalctl -xe`查看日志如下

    ```bash
    Failed to create ["kubepods"] cgroup
    Failed to start ContainerManager Cannot set property TasksAccounting, or unknown property
    ```
    - 解决方法：先执行`yum update`(https://github.com/kubernetes/kubernetes/issues/76820)
- kubelet启动报错`failed to load Kubelet config file /var/lib/kubelet/config.yaml`，此时是重置kubeadm导致
    - 解决方法：`systemctl stop kubelet && systemctl enable kubelet`，然后重新kubeadm init(会自动启动kubelet)
- kubeadm reset报错`[ERROR DirAvailable--var-lib-etcd]: /var/lib/etcd is not empty`
    - 解决办法：手动删除/var/lib/etcd目录
- kubeadm join执行报错`kubeadm join [ERROR DirAvailable--etc-kubernetes-manifests]: /etc/kubernetes/manifests is not empty`
    - 情况一：在master节点(已经执行了kubeadm init)上执行kubeadm join会出现。kubeadm应该在node节点上执行(如果在master上执行也不会对master产生影响)
    - 情况二：在node节点上执行出现，可能是之前已经初始化过此node节点。如果需要重新初始化，需要先执行`kubeadm reset`

## 命令使用

> https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.15/

### kubectl

- 命令说明

```bash
# kubectl
# kubectl set --help
# kubectl set image --help
kubectl controls the Kubernetes cluster manager.

 Find more information at: https://kubernetes.io/docs/reference/kubectl/overview/

# 基础命令
Basic Commands (Beginner):
  create         Create a resource from a file or from stdin.
    configmap           # 创建ConfigMap资源。语法：kubectl create configmap NAME [--from-file=[key=]source] [--from-literal=key1=value1] [--dry-run] [options]
    secret              # 创建Secret资源
      docker-registry       # 创建docker-registry类型Secret资源
      generic               # 普通Secret资源(加密方式为base64)。语法：kubectl create secret generic NAME [--type=string] [--from-file=[key=]source] [--from-literal=key1=value1] [--dry-run] [options]
      tsl                   # TSL秘钥、证书Secret资源
    serviceaccount      # 创建serviceaccount用户(用于pod访问API Server)
    role                # 角色(namespace)
    clusterrole         # 集群角色
    rolebinding         # 角色绑定
    namespace           # 命名空间
    -f                  # 根据yaml文件创建资源
    --dry-run           # 仅仅运行测试，不进行实际操作。可通过此生成创建模板
    -o                  # 取值：yaml
    # kubectl create -f sq-pod.yaml
    # kubectl create role my-pods-reader --verb=get,list,watch --resource=pods --dry-run -o yaml # 干跑模式生成创建role配置文件，不会进行实际操作
    # kubectl create rolebinding aezo-read-pods --role=my-pods-reader --user=aezo --dry-run -o yaml > rolebinding-demo.yaml
  expose         Take a replication controller, service, deployment or pod and expose it as a new Kubernetes Service # 暴露Pod/RS/RS为一个服务
    --name              # 暴露的服务名称
    --port              # 暴露的服务端口
    --target-port       # 被暴露pod的端口
    --protocol          # 协议(TCP)
    --type              # 暴露的类型。ClusterIP(默认，仅在进群访问)、NodePort(提供外网访问，随机生成Node端口)、LoadBalancer、ExternalName
    # kubectl expose deployment sq-nginx --name=nginx --port=80 --target-port=80 --protocol=TCP # 将名为sq-nginx的pod暴露成服务
  run            Run a particular image on the cluster # 基于某个镜像创建Pod
    --image         # 指定容器的镜像，和docker镜像一致
    --replicas      # 部署的节点数量
    --restart       # 重启方式，取值：Never(表示不自动启动)
    -it             # 进入pod容器
    # kubectl run nginx --image=nginx # 启动单实例
    # kubectl run sq-nginx --image=nginx:1.14-alpine --replicas=3 # 启动3个实例
    # kubectl run busybox1 -it --image=busybox --restart=Never --overrides='{ "apiVersion": "v1", "spec": { "nodeName": "node1" } }' # 启动busybox并进入容器，此时添加了额外参数 --overrides 来覆盖资源配置
  set            Set specific features on objects # 重设对象配置
    image       # 更新容器镜像
    # kubectl set image deployment sq-nginx sq-nginx=nginx:1.14-alpine # 更新sq-nginx部署资源中容器sq-nginx的镜像

Basic Commands (Intermediate):
  explain        Documentation of resources # 资源描述文档
    pods        # 显示描述pods资源的字段说明文档
    # kubectl explain pods.metadata # 显示pods资源的matedata字段说明(可一直通过.字符进行描述子字段)
  get            Display one or many resources # 展示资源列表
    all             # 获取所有资源
    deployment      # 获取部署列表。READY：1/3表示期望部署3个副本，目前只有1副本就绪
        -w                  # 一致观测部署变化(pods等也可使用)
    pods/pod/po     # 获取pod列表。READY：1/3表示此Pod期望部署3个容器，目前只有1个容器就绪
        -o                  # 取值：wide(显示详细信息)、yaml(显示yaml配置信息)、json、jsonpath(如 jsonpath={.data.token} 仅显示此字段数据)
        -l                  # 基于标签过滤，如：-l app,tier(获取同时有此标签key的pods)；-l run!=busybox1；
        -n                  # 指定命名空间namespace，默认为default，如 `-n kube-system`
        --show-labels       # 展示标签
        --all-namespaces    # 显示所有命名空间下的资源
    services/svc    # 获取服务列表。PORTS：80:30435/TCP 表示80为所有Pod网络端口，30435为Node网络端口(只有部署有此pod的所有Node都是这个端口)
    configmap/cm    # ConfigMap资源
    # kubectl get pods # 获取pods列表
    # kubectl get pods -o wide # 获取pods详细列表
    # kubectl get --raw /apis/apps/v1 # 获取 /apps/v1 可用资源类型
  edit           Edit a resource on the server # 编辑一个资源配置（保存配置后立即生效）
    svc         # 编辑服务配置
    # kubectl edit svc nginx # 编辑nginx服务配置
  delete         Delete resources by filenames, stdin, resources and names, or by resources and label selector # 删除资源
    pods        # 删除pods。速度会较慢
    svc         # 删除服务
    # kubectl delete pods sq-nginx-75875cf46f-829nm # 删除某个pod
    # kubectl delete -f sq-pod.yaml # 基于配置文件删除资源(kind标识)

# 部署相关
Deploy Commands:
  rollout        Manage the rollout of a resource # 滚动执行
    status      # 滚动显示某资源状态
    undo        # 默认撤销上一次资源操作
        --to-revision       # 设置回滚资源到某个历史版本
    history     # 滚动显示资源历史
    pause       # 暂停
    # kubectl rollout status depolyment sq-nginx # 滚动显示sq-nginx的部署状态
    # kubectl rollout history depolyment sq-nginx # 查看部署版本状态
    # kubectl set image deployment sq-nginx sq-nginx=nginx:1.14-alpine && kubectl rollout pause deployment sq-nginx
  scale          Set a new size for a Deployment, ReplicaSet, Replication Controller, or Job # 重新设置资源数量(伸缩扩展)
    # kubectl scale [--resource-version=version] [--current-replicas=count] --replicas=COUNT (-f FILENAME | TYPE NAME) [options]
    # kubectl scale --replicas=2 deployment sq-nginx
  autoscale      Auto-scale a Deployment, ReplicaSet, or ReplicationController

# 集群管理相关
Cluster Management Commands:
  certificate    Modify certificate resources.
  cluster-info   Display cluster info # 打印集群信息
  top            Display Resource (CPU/Memory/Storage) usage.
   # kubectl top pods/nodes # 查看监控指标信息，必须启动 metrics-server 才能正常获取
  cordon         Mark node as unschedulable # 给节点加不可用标记
  uncordon       Mark node as schedulable # 给节点加可用标记
  drain          Drain node in preparation for maintenance
  taint          Update the taints on one or more nodes # 给节点增加污点。如Master默认就存在污点，其他Pod默认不能容忍此污点，因此普通Pod不会运行在Master节点上

# Debug命令
Troubleshooting and Debugging Commands:
  describe       Show details of a specific resource or group of resources # 描述某资源详细信息
    node        # 描述节点信息
    deployment  # 描述部署信息
    svc         # 描述服务信息(默认描述全部服务，后面可接某个服务名)
    --export    # 导出关键配置信息(去除了一些status信息)
    # kubectl describe node node1 # 描述节点node1的详细信息
  logs           Print the logs for a container in a pod # 打印pod中容器的日志
    -f          # 实时打印日志
    # kubectl logs sq-pod sq-busybox # 打印 sq-pod 中 sq-busybox 容器的日志
  attach         Attach to a running container
  exec           Execute a command in a container # 在容器中执行命令
    # kubectl exec -it sq-pod -c sq-busybox -- sh # -it同docker表示进入容器
  port-forward   Forward one or more local ports to a pod # 通过端口转发映射本地端口到指定的应用端口
    # 一般是为了测试将集群中的某个服务的端口映射到节点的端口上，此时命令行一直处于监听状态
    # 语法：kubectl port-forward TYPE/NAME [options] [LOCAL_PORT:]REMOTE_PORT [...[LOCAL_PORT_N:]REMOTE_PORT_N]
    # eg:
        # kubectl port-forward --address 0.0.0.0 sq-pod-8696c98b6f-j2stv 8080:80 # 此时访问 http://192.168.6.131:8080/ 即可
        # export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=mychart,app.kubernetes.io/instance=test-chart" -o jsonpath="{.items[0].metadata.name}")
        # kubectl port-forward --address 0.0.0.0 $POD_NAME 8080:80
  proxy          Run a proxy to the Kubernetes API server
    # kubectl proxy 8080 # 将 API server 暴露到一个8080端口上，则可查看api信息 `curl http://localhost:8080/`
  cp             Copy files and directories to and from containers.
  auth           Inspect authorization

# 高级命令
Advanced Commands:
  diff           Diff live version against would-be applied version
  apply          Apply a configuration to a resource by filename or stdin # 基于文件创建/更新资源，建议将资源的原始yaml保留备份，以备快速删除此资源
    # kubectl apply -f sq-pod.yaml # 应用一个文件，当通过vi命令修改配置文件后需要手动使配置生效。备注：假设原pod只有一个容器，如果修改yaml文件中镜像配置，最终可能pod中老容器也不会去除，总共会运行2个容器
  patch          Update field(s) of a resource using strategic merge patch
    # kubectl patch deployment sq-deploy -p '{"spec":{"replicas":5}}' # 给配置打补丁，配置会自动生效
    # kubectl patch svc my-dev-mysql -p '{"spec":{"type":"NodePort"}}' # 将服务修改成边界服务
  replace        Replace a resource by filename or stdin
  wait           Experimental: Wait for a specific condition on one or many resources.
  convert        Convert config files between different API versions
  kustomize      Build a kustomization target from a directory or a remote url.

Settings Commands:
  label          Update the labels on a resource # 给资源(Pod、Node等)添加一个Label标签
    # kubectl label pods sq-pod version=v1 [--overwrite] # 给pod添加标签，加`--overwrite`则表示修改标签
  annotate       Update the annotations on a resource # 给资源添加描述
  completion     Output shell completion code for the specified shell (bash or zsh)

Other Commands:
  api-resources  Print the supported API resources on the server
  api-versions   Print the supported API versions on the server, in the form of "group/version"
  config         Modify kubeconfig files
    view                # 查看集群k8s集群配置
    set-credentials     # 创建用户证书
    set-context         # 设置用户可访问的集群
    set-cluster         # 创建集群
    --kubeconfig        # 配置文件目录，默认为 `${HOME}/.kube/config`
  plugin         Provides utilities for interacting with plugins.
  version        Print the client and server version information # 打印版本信息

Usage:
  kubectl [flags] [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).
```
- 入门命令

```bash
# 查看run命令的帮助信息
kubectl run --help

# 启动nginx的Pod
kubectl run nginx --image=nginx # 启动单实例
kubectl run sq-nginx --image=nginx:1.14-alpine --replicas=3 # 启动3个实例
kubectl run busybox1 -it --image=busybox --restart=Never # 启动busybox，并进入容器，--restart=Never表示不自动启动。**测试常用**

# 获取部署列表
kubectl get deployment
# 获取pod详细列表，可显示pod的ip地址，此时可以在K8s上访问此ip
kubectl get pod -o wide

# 删除某pod
kubectl delete pods sq-nginx-75875cf46f-829nm

# 暴露pod为服务。如进入某pod容器可测试直接通过服务名访问：`wget nginx` 或 `wget -O - -q http://nginx:80`
kubectl expose deployment sq-nginx --name=nginx --port=80 --target-port=80 --protocol=TCP

kubectl logs sq-pod sq-busybox # 打印 sq-pod 中 sq-busybox 容器的日志
kubectl exec -it sq-pod -c sq-busybox -- /bin/sh # 执行容器中命令，-it同docker表示进入容器
```

## 进阶知识

### 资源

- 资源(对象)
    - 工作负载(workload)：Pod、RelicaSet、Deployment、StatefulSet、DaemonSet、Job、Cronjob
    - 服务发现及负载均衡：Service、Ingress
    - 配置与存储：Volume、CSI
        - PersistentVolume、PersistentVolumeClaim、ConfigMap、Secret
        - StorageClass
        - DownwardAPI
    - 集群级资源：Namespace、Node、Role、ClusterRole、RoleBinding、ClusterRoleBinding、ServiceAccount(sa)、NetworkPolicy(netpol)、APIService
    - 元数据型资源：HPA、PodTemplate、LimitRange
    - CustomResourceDefinition(crd)
        - 是 v1.7 + 新增的无需改变代码就可以扩展 Kubernetes API 的机制，用来管理自定义对象(新资源类型)。它实际上是 ThirdPartyResources(TPR) 的升级版本，而 TPR 已经在 v1.8 中删除
- 创建资源的方法
    - apiserver仅接受json格式的资源定义
    - yaml格式提供的配置清单，apiserver可自动将其转为json格式，而后再提交
        - k8s组件相关yaml配置文件位置`/etc/kubernetes/manifests`
- 资源配置文件查看命令举例
    - `kubectl explain pods` 查看说明
    - `kubectl explain pods.metadata` 查看某个字段说明(可一直通过.字符进行描述)
    - `kubectl get pods nginx-deploy-75875cf46f-kbjck -o yaml` 查看使用案例
- `ServiceAccount`(sa) k8s包括用户账号和服务账号，此时服务账号是附加某个pod上供其访问apiserver
    - 当创建 pod 的时候，如果没有指定一个 service account，系统会自动在与该 pod 相同的 namespace 下为其指派一个default service account。而pod和apiserver之间进行通信的账号，称为serviceAccountName
    - 每一个命名空间下都有一个`default-token-xxxx`(查看`kubectl get secret`)用于该空间下pod的默认secret
    - 每创建一个ServiceAccount就会自动创建一个Secret与之关联。如`kubectl create serviceaccount sa-admin`会产生一个`sa-admin-token-xxxx`的Secret(如此Secret中保存的token信息可用于登录Dashboard)
    - 如将拉取容器镜像的Secret附加到ServiceAccount(sa)上，然后将sa定义到此容器上即可访问私有镜像(也可直接将Secret附加在容器上)

#### 资源配置文件字段说明

- `apiVersion` 查看支持API资源列表`kubectl api-versions`。查看某个一个资源对应API版本`kubectl explain pods`中的VERSION字段：创建Pod/Service使用v1，创建RS用apps/v1
- `kind` 资源类别：Pod、ReplicaSet、Deployment、DaemonSet等
- `metadata` 元数据
    - `name` 同以类别下名称需要唯一
    - `namespace` 命名空间。基于文件apply时，会将资源创建到此处定义的命名空间中；如果不定义可以通过`--namespace=dev`传入；如果定义了，则--namespace参数无法对其进行覆盖
    - `labels` 标签(限制长度)
        - 常见的标签键名：app、tier(frontend/backend)、version、profile
    - `annotations` 资源注解(不限长度)，与lables不同的是不能用于挑选资源对象。一般是提供一些配置表示，如`nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"`
    - `selfLink` 每个资源引用PATH格式：`/apo/GROUP/VERSION/namespaces/NAMESPACE/TYPE/NAME`
- `spec` 期望状态(disired state)
    - `containers` 描述容器(<[]Object>)
        - name、image
        - imagePullPolicy：Always(永远重新拉取镜像，镜像latest默认), Never, IfNotPresent(如果本地有则不拉取镜像，其他默认)。创建Pod后无法修改此字段
        - `ports`(<[]Object>)
            - `containerPort` 将此容器中的某个端口暴露到pod中
            - `name` 如：http/https
        - `command` 对应ENTRYPOINT，可类似docker-compose使用`[]`
            - command/args不能强依赖于`lifecycle.postStart`的执行结果。此处command是在lifecycle.postStart之前执行的
        - `args` 对应CMD(`<[]Object>`)。[与command对应关系](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell)
        - `env` 环境变量信息
            - `name` 变量名
            - `value` 变量值
            - `valueFrom` 从其他地方获取环境变量。第一次创建然容器时读取了数据后就不会再同步新数据，如果需要同步；可以挂载ConfigMap/Secret存储卷到pod上
                - `configMapKeyRef` 从ConfigMap中获取环境变量
                    - `name` ConfigMap资源名称
                    - `key` 变量名
                - `secretKeyRef` 从SecretKey中获取(类似ConfigMap)
        - `serviceAccountName` pod内部访问其他资源的账号名称
        - `livenessProbe` 存活性探测(如果多次存活探测失败，则会重启此pod)
            - `exec` 基于执行命令探测
                - `command` 执行的探测命令
            - `tcpSocket` 基于tcpSocket探测
            - `httpGet` 基于httpGet探测
                - `scheme` 连接使用的 schema，默认HTTP
                - `host` 连接的主机名，默认连接到 pod 的 IP
                - `port`
                - `path` eg: /index.html
                - `httpHeaders` 自定义请求的 header
            - `initialDelaySeconds` 初始化探测延时时间(修改Deployment有效，修改ReplicaSet无效)
            - `periodSeconds` 探测周期(默认为10s)
            - `timeoutSeconds` 探测超时时间。默认1秒，最小1秒
            - `successThreshold` 探测失败后，最少连续探测成功多少次才被认定为成功。默认是 1，对于 liveness 必须是 1。最小值是 1。
            - `failureThreshold` 探测成功后，最少连续探测失败多少次才被认定为失败。默认是 3。最小值是 1
        - `readinessProbe` 就绪性探测(子标签类似livenessProbe)。在readiness探测失败之后，Pod和容器并不会被删除，而是会被标记成特殊状态，进入这个状态之后，如果这个POD是在某个serice的endpoint列表里面的话，则会被从这个列表里面清除，以保证外部请求不会被转发到这个POD上；等POD恢复成正常状态，则会被加回到endpoint的列表里面，继续对外服务
    - `nodeSelector` 节点标签选择器，如果定义则pod只会运行在有此标签的节点上
    - `nodeName` 直接运行在此节点上
    - `restartPolicy` 重启策略：Always(默认)、OnFailure、Never
    - `lifecycle` 生命周期
        - `postStart` 主pod容器被创建后调用(子标签类似livenessProbe)
        - `preStop` 主pod容器被退出前调用(子标签类似livenessProbe)
    - `hostIPC` pod共享节点的ipc namespace
    - `hostNetwork` pod共享节点的network namespace(此时则无需暴露端口，一般用于DaemonSet中)
    - `hostPID` pod共享节点的pid namespace
    - `volumes` 存储设置，见下文
    - `imagePullSecrets` 拉取镜像使用的Secret资源
    ---
    - `replicas` ReplicaSet 维持pod数量
    - `selector` ReplicaSet 选择pod的选择器
    - `template` ReplicaSet 创建pod的模板
        - `metadata` 类似kind=Pod的
        - `spec` 类似kind=Pod的
    - `strategy` Deployment创建pod的策略(如更新pod配置时)
        - `type` 取值：Recreate、RollingUpdate(默认)
        - `rollingUpdate`
            - `maxSurge` 操作pod时，可控制的最大数量，如修改配置后可能创建新版本pod和依次删除历史pod同时进行。(DaemonSet无)
            - `maxUnavailable` 更新配置时，不可用的最大数量
    - `updateStrategy` DaemonSet更新pod策略(类似strategy)
    ---
    - `selector`
    - `type` Service类型：ClusterIP(默认，k8s集群内访问)、NodePort(k8s集群外可访问)、LoadBalancer、ExternalName(将k8s外部服务映射到集群)
    - `clusterIP` Service服务集群IP(ExternalName类型无需)。eg：10.66.66.66、None(无头服务)
    - `ports` 服务端口(暴露pod的服务端口)
        - `port` 暴露的服务端口
        - `targetPort` 被暴露的容器端口
        - `nodePort` 仅type=NodePort时，使用Node的端口映射服务端口(确保Node端口可用)，不指定则随机
    - `externalName` 仅用于type=ExternalName，取值应该是一个外部域名，CNAME记录。CNAME -> FQDN
    - `externalIPs` 可配合`IPVS`实现将外部流量引入到集群内部，同时实现负载均衡，即用来定义VIP(直接填写一个和节点同一个段没使用过的IP即可，无需创建VIP)；可以和任一类型的Service一起使用
    - `sessionAffinity` 是否session感知的：ClientIP(同一个客户永远访问的是同一个pod)、None(默认)
    - `externalTrafficPolicy` 取值：Cluster(默认。隐藏源IP，可能会导致第二跳，负载较好)、Local(保留客户端源 IP 地址)。如果服务需要将外部流量路由到 本地节点或者集群级别的端点，即service type 为LoadBalancer或NodePort，那么需要指明该参数
- `status` 当前状态(current state)。由K8s进行维护，用户无需修改

#### 资源配置文件简单示例

```yaml
# sq-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sq-pod
  namespace: default
  labels:
    app: sq-test1
    tier: frontend
spec:
  containers:
  - name: sq-nginx
    image: nginx:1.14-alpine
  - name: sq-busybox
    image: busybox
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 1h"

# sq-dploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  # 生成的pod名称会随机加一个字符串，如：sq-dploy-bjrgc
  name: sq-dploy
  namespace: default
spec:
  # 维持pod数量
  replicas: 2
  # 控制器选择pod的选择器。有可能选择的pod不是来自一个控制器，主要根据选择器来的
  selector:
    matchLabels:
      app: sq-test2
      tier: frontend
  # 创建pod的模板
  template:
    metadata:
      # 此name不会作为pod的名称，最终pod的名称为`RS名-xxxx`，如：sq-dploy-bjrgc
      name: sq-dploy-pod
      labels:
        app: sq-test2
        tier: frontend
        profile: test
    spec:
      containers:
      - name: sq-nginx
        image: nginx:1.14-alpine
        ports:
        - name: http
          containerPort: 80
```

- 基于yaml资源文件操作资源

```bash
# 基于配置文件创建pod
kubectl create -f sq-pod.yaml
kubectl get pods
# 基于配置文件删除资源
kubectl delete -f sq-pod.yaml
```

### Pod

- Pod生命周期

    ![k8s-pod-lifecycle](/data/images/devops/k8s-pod-lifecycle.png)
    - 还有一个`Unknown`状态
- Pod生命周期中的重要行为
    - 运行主容器之前可以运行初始化容器
    - 主容器运行成功后和退出前可以执行钩子：`post start`、`pre stop`
    - 主容器运行过程中可进行探测：`liveness`(存活状态检测)、`readiness`(就绪状态检测)
        - 探针类型：exec、tcpSocket、httpGet
    
    ![k8s-pod-action](/data/images/devops/k8s-pod-action.png)
- Pod状态(STATUS)
    - `Pending` 准备中，可能为：正在处理、没有合适的运行节点
    - `Running` 正常运行
    - `Terminating` 中断中
    - `CrashLoopBackOff` 容器退出，kubelet正在将它重启
    - `InvalidImageName` 无法解析镜像名称
    - `ImageInspectError` 无法校验镜像
    - `ErrImageNeverPull` 策略禁止拉取镜像
    - `ImagePullBackOff` 正在重试拉取
    - `RegistryUnavailable` 连接不到镜像中心
    - `ErrImagePull` 通用的拉取镜像出错
    - `CreateContainerConfigError` 不能创建kubelet使用的容器配置
    - `CreateContainerError` 创建容器失败
    - `ContainerCreating` 容器创建中
    - `ContainersNotReady` 容器没有准备完毕
    - `ContainersNotInitialized` 容器没有初始化完毕
    - `RunContainerError` 启动容器失败
    - `m.internalLifecycle.PreStartContainer` 执行hook报错
    - `PostStartHookError` 执行hook报错
    - `PodInitializing` pod初始化中
    - `DockerDaemonNotReady` docker还没有完全启动
    - `NetworkPluginNotReady` 网络插件还没有完全启动
- Pod条件(Conditions)
    - Pod有一个PodStatus，它有一个PodConditions 数组。PodCondition数组的每个元素都有六个可能的字段
        - `type` 一个包含以下可能值的字符串
            - `PodScheduled` Pod已被安排到一个节点
            - `Read` Pod能够提供请求，应该添加到所有匹配服务的负载平衡池中
            - `Initialized` 所有init容器都已成功启动
            - `Unschedulable` 调度程序现在无法调度Pod，例如由于缺少资源或其他限制
            - `ContainersReady` Pod中的所有容器都已准备就绪
        - `status` 一个字符串，可能的值为True/False/Unknown
        - `lastProbeTime` 提供上次探测Pod条件的时间戳
        - `lastTransitionTime` 提供Pod最后从一个状态转换到另一个状态的时间戳
        - `reason` 该条件最后一次转换的唯一，CamelCase原因
        - `message` 指示有关转换的详细信息
- Deployment是构建于RS之上的，可能出现一类Pod由不同的RS控制
- 重启Pod：直接删掉该Pod，会自动重新创建一个新的Pod
- 容器
    - 拉取私有仓库镜像
        
        ```bash
        # 配置所有节点，加入下列内容(docker客户端默认使用https访问仓库)
        vi /etc/docker/daemon.json
        {"insecure-registries": ["192.168.17.196:5000"]}
        
        # 创建docker-registry类型的secret(k8s必须创建secret才可拉取镜像，在节点机器上提前login也无法拉取)
        kubectl create secret docker-registry harbor-secret --docker-server=192.168.17.196:5000 --docker-username=smalle --docker-password=Hello666
        # 并给对应Pod配置以下伪代码：imagePullSecrets[0].name=harbor-secret
        ```

### 控制器

#### Deployment

- Deployment 与 ReplicaSet
    - Deployment是构建于RS之上的，可能出现一类Pod由不同的RS控制
    - 当创建了 Deployment 之后，实际上也创建了 ReplicaSet，所以说 Deployment 管理着 ReplicaSet
    - 如果直接伸缩 ReplicaSet，但 Deployment 不会相应发生伸缩。如果ReplicaSet全部删除了，Deployment会自动创建一个新的副本集

#### StatefulSet(管理有状态副本集)

- 三个组件：headless service、StatefulSet、volumeClaimTemplate
- 会有序的创建pod，并逆序的移除pod

### Service

- Service网络工作模式：userspace(1.1之前)、iptables(1.1默认)、ipvs(1.1之后)
    - userspace：较慢，每次请求都需要kube-proxy转发

        ![k8s-userspace](/data/images/devops/k8s-userspace.png)
        - apiserver提交修改(pod变更等) -> kube-proxy -> 修改iptables规则
        - client-pod -> iptables -> kube-proxy -> server-pod
    - iptablse/ipvs
        - iptablse和ipvs工作流程一直，如下图。k8s配置成ipvs时，如果内核不支持，则会自动使用iptables
        - ipvs(IP Virtual Server)实现了传输层负载均衡，也就是常说的4层LAN交换，作为 Linux 内核的一部分。是运行在LVS(Linux Virtual Server)下的提供负载平衡功能的一种技术。[^6]

        ![k8s-ipvs](/data/images/devops/k8s-ipvs.png)
        - apiserver提交修改(pod变更等) -> kube-proxy -> 修改ipvs规则
            - API Server修改了配置，被kube-proxy监视(watch)到，然后转换成iptables/ipvs规则(有延迟)
        - client-pod -> ipvs -> server-pod
- 服务类型(type)
    - ClusterIP(默认，仅k8s集群内访问)
    - NodePort(k8s集群外可访问，k8s边界服务)
        - client -> NodeIP:NodePort -> ClusterIP:ServicePort -> PodIP:containerPort
    - LoadBalancer(负载均衡器，实现了流量经过前端负载均衡器分发到各个Node节点暴露出的端口，再通过ipvs/iptables进行一次负载均衡，最终分发到实际的Pod上这个过程。可通过`externalIPs`配合`IPVS`实现将外部流量引入到集群内部，同时实现负载均衡)
    - ExternalName(将k8s外部服务映射到集群)
        - CNAME -> FQDN(将外部服务映射到内部，通过内部DNS服务进行访问)
    - 特殊服务：无头服务(headless services)
        - ServiceName -> PodIP
        - 此时`clusterIP=None`，且未定义type
        - kube-proxy 不会处理它们，而且平台也不会为它们进行负载均衡和路由。DNS 如何实现自动配置，依赖于 Service 是否定义了 selector
- Service通过观测(watch) API Server，每当Pod变化，API Server就会通知Service进行变更选择的Pod
- 集群内部源Pod通过Service地址访问目标Pod时，可使用Service的ip/hostname:port，其中hostname格式为`service_name.namespace_name.svc`，如访问：http://prometheus-k8s.monitoring.svc:9090

### Ingress & Ingress Control [^3]

- Ingress Control背景
    - 特殊的控制器，不同于普通Control Manager，**主要是提供集群访问入口(边界节点)，外部请求至Ingress Control(对应的NodePort/LoadBalancer类型的Service)，然后Ingress Control调用最终的Pod**
        - 集群提供外网访问：Pod直接定义hostNetwork共享节点网络；定义NodePort/LoadBalancer类型的Service代理访问到相应Pod
    - 如果使用https访问，则只需要在Ingress Control进行配置证书(否则所有的Pod都需要配置证书)，k8s内部Pod无需处理，内部仍然使用http明文调用(此时相当于再进行一次反向代理)
        - 客户域名进行访问，此时是访问到NodePort Service，而Service调度到Pod是第四层转换，而Https是工作在第七层。要建立Https连接必须要和最终主机(Pod)完成，因此就需要所有Pod配置https证书(K8s最终选择Ingress解决Https问题)
- `Ingress` 简单的理解就是你原来需要改 Nginx 配置，然后配置各种域名对应哪个 Service，现在把这个动作抽象出来，变成一个 Ingress 对象，可以用 yaml 创建，每次不要去改 Nginx 了，直接改 yaml 然后创建/更新就行了；那么问题来了："nginx 该怎么处理？"
- `Ingress Controller` 就是解决 "Nginx 的处理方式"的，Ingress Controoler 通过与 Kubernetes API 交互，动态的去感知集群中 Ingress 规则变化，然后读取他，按照他自己模板生成一段 Nginx 配置，再写到 Nginx Pod 里，最后 reload 一下，工作流程如下图

    ![k8s-ingress](/data/images/devops/k8s-ingress.png)

    - **Pod变化，会反映到对应的Service；Ingress通过管理这些Service和应用Host的关系，得知某个Host最终可以访问那些Pod，并将相关配置注入到Ingress Controller；Client客户端请求Host到达Ingress Controller后，便可直接代理到最终的Pod**
    - 实际上Ingress也是Kubernetes API的标准资源类型之一，它其实就是一组基于DNS名称（host）或URL路径把请求转发到指定的Service资源的规则，用于将集群外部的请求流量转发到集群内部完成的服务发布。Ingress资源自身不能进行"流量穿透"，仅仅是一组规则的集合，这些集合规则还需要其他功能的辅助，比如监听某套接字，然后根据这些规则的匹配进行路由转发，这些能够为Ingress资源监听套接字并将流量转发的组件就是Ingress Controller
    - 此时使用NodePort暴露Ingress Controller；也可以(使Node)直接访问到Ingress Controller，不经过前面的Service(NodePort)。需要将Ingress Controller设置成DaemonSet，且共享Node的IP和端口
- Ingress的资源类型：单Service资源型Ingress、基于URL路径进行流量转发、基于主机名称的虚拟主机、TLS类型的Ingress资源
- K8s创建HAProxy可使用插件：Nginx、Traefik(为微服务而生)、Envoy(常用于微服务/服务网格)

#### Ingress Nginx部署

- Ingress Control不直接运行为kube-controller-manager的一部分，它仅仅是Kubernetes集群的一个附件，类似于CoreDNS，需要在集群上单独部署
- 部署Ingress Controller
    - Ingress Controller可基于Nginx、Traefik、Envoy等来进行部署，此处使用[ingress-nginx](https://github.com/kubernetes/ingress-nginx)

```bash
## 部署Ingress Controller，此时是Ingress Controller部署为Deployment。如果只执行此部署，则只能在集群内部访问
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.25.1/deploy/static/mandatory.yaml
# 修改镜像地址(quay.io有时候会很慢)
sed -i 's#quay.io/kubernetes-ingress-controller#registry.cn-hangzhou.aliyuncs.com/google_containers#g' mandatory.yaml
kubectl apply -f mandatory.yaml
kubectl get deployment -n ingress-nginx
## (生产环境一般使用 LoadBalancer) 使用Nodeport暴露Ingress Controller，如需修改暴露的节点端口，可添加 nodePort: 30080 和 nodePort: 30443 来指定
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.25.1/deploy/static/provider/baremetal/service-nodeport.yaml
kubectl apply -f service-nodeport.yaml
# kubectl expose deployment nginx-ingress-controller --port 80 --external-ip 192.168.6.132 # 或者基于 LoadBalancer + externalIPs 来暴露服务
kubectl get svc -n ingress-nginx
## 取消HSTS配置：https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/
# 修改配置，伪代码：添加 `data.hsts="false"`。取消成功后查看nginx配置时则无`Strict-Transport-Security`相关配置
kubectl edit configmap nginx-configuration -n ingress-nginx
## 查看 ingress-controller 对应pod的nginx配置
kubectl exec -it nginx-ingress-controller-74c6b9c45c-9qm54 -n ingress-nginx cat /etc/nginx/nginx.conf
# 查看日志(cat /var/log/nginx/access.log 卡死)
kubectl logs nginx-ingress-controller-74c6b9c45c-9qm54 -n ingress-nginx
```

#### 创建Ingress示例

- 查看定义`kubectl explain ingress`，此处以`ingress.aezocn.local`(外部测试需要在hosts中加入对应节点IP)为例
- 先创建一个测试服务

```yml
# sq-ingress.yaml
# 创建测试service为sq-ingress
apiVersion: v1
kind: Service
metadata:
  # service名称
  name: sq-ingress
  namespace: default
spec:
  selector:
    app: sq-ingress
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: ajp
    port: 8009
    targetPort: 8009
---
# 创建后端服务的pod
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sq-ingress-backend-pod
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sq-ingress
  template:
    metadata:
      labels:
        app: sq-ingress
    spec:
      containers:
      - name: tomcat
        image: tomcat:8.5.43-jdk8
        ports:
        - name: http
          containerPort: 8080
        - name: ajp
          containerPort: 8009
```
- 编写ingress的配置清单。如果有多个应用，可以创建多个Ingress

```yml
# ingress-sq-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-sq-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
    # 如kubernetes-dashboard需要实现tls访问，则需要加入此注解。否则提示"无法访问此网页"，且ingress-nginx容器日志报错"ingress dashboard upstream sent no valid HTTP/1.0 header while reading response header from upstream"
        # This annotation was deprecated in 0.18.0 and removed after the release of 0.20.0，之前为 `nginx.ingress.kubernetes.io/secure-backends: "true"`
        # 参考：http://bbs.bugcode.cn/t/18544 、https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#backend-protocol
    #nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  # 定义后端转发的规则
  rules:
  - host: ingress.aezocn.local
    http:
      paths:
      # 配置后端服务
      - backend:
          serviceName: sq-ingress
          servicePort: 8080
        # 配置访问路径，如果通过url进行转发，需要修改；空默认为访问的路径为"/"
        path: "/"
  # 配置TLS站点才需要(结合下文)
  tls:
  - hosts:
    - ingress.aezocn.local
    # 指定 secret 名称(可通过TLS证书创建，见下文)
    secretName: sq-ingress-secret
```
- `kubectl get ingress` 查看ingress配置
- 可在集群外访问 `http://ingress.aezocn.local` 会显示tomcat主页
    - 下文TSL站点则访问`https://ingress.aezocn.local`。如果配置了TSL，则访问http时，默认会跳转到https(443)
    - 如果修改ingress-nginx的service-nodeport.yaml中节点端口，此处测试访问的域名应该加上相应端口
- 常见问题
    - 访问https地址时，点击高级不显示`继续前往ingress.aezocn.local（不安全）`，而是显示`您目前无法访问 ingress.aezocn.local，因为此网站使用了 HSTS。网络错误和攻击通常是暂时的，因此，此网页稍后可能会恢复正常`
        - 原因：ingress-nginx默认模式是以HSTS访问，如果证书有问题，可能直接导致浏览器无法忽略警告继续访问
        - 可访问`chrome://net-internals/#hsts`进行清除当前域名的hsts设置(测试没有清除成功)
        - 或者去掉HSTS后，重新更换域名

#### 构建TLS站点示例

- 手动创建证书

```bash
## 创建证书
cd ~/.certs/
openssl genrsa -out aezocn.key 2048
# 注意签名中的域名(表示只有此域名以https访问证书才有效)
openssl req -new -x509 -key aezocn.key -out aezocn.crt -subj /C=CN/ST=Beijing/L=Beijing/O=DevOps/CN=ingress.aezocn.local
## 生成secret(类型为tls，名称为sq-ingress-secret)
kubectl create secret tls sq-ingress-secret --cert=aezocn.crt --key=aezocn.key
## 启动ingress-nginx后，可通过容器日志看到证书加载日志 Adding Secret "default/sq-ingress-secret" to the local store；如果secret无效，则会使用系统默认证书Kubernetes Ingress Controller Fake Certificate
```
- 安装Let's Encrypt免费SSL证书(Let's Encrypt提供90天的证书有效期，可安装自动续期服务)

### 存储卷

- 常用分类
    - `emptyDir` 临时目录。pod删除，数据也会被清除，这种存储成为emptyDir，用于数据的临时存储
    - `hostPath` 宿主机目录映射
    - PVC持久化存储
        - 本地存储 `SAN`(`iSCSI`、`FC`)、`NAS`(`nfs`、`cifs`、`http`)
        - 分布式存储 `glusterfs`、`rbd`、`cephfs`
        - 云存储 `EBS`、`Azure Disk`
- `kubectl explain pod.spec.volumes` 查看k8s支持的存储类型及配置
    - `emptyDir` 临时目录存储，Pod删除，数据也会丢失。取值`{}`时，则子字段为默认值
    - `hostPath` 宿主机目录存储，重新创建Pod后数据还在，但各节点目录不共享
        - `type` 存储类型。取值：`DirectoryOrCreate`(可自动创建存储目录)
        - `path` 数据存储在Node节点上存储目录
    - `nfs` 基于nfs的网络存储，各节点可共享。注：此时各Node节点需要可驱动nfs，可在各节点安装`nfs-utils`
        - `server` nfs服务器地址，IP或者hostname
        - `path`
    - `persistentVolumeClaim` PVC(存储卷创建申请)
        `claimName` 对应PVC资源名称
    - `configMap`
        - `name` ConfigMap资源名
    - `secret`
        - `secretName`
- `kubectl explain pv.spec` 查看PersistentVolume(pv)配置
    - `accessModes` 定义访问模型，可定义多个。取值：ReadWriteOnce(RWO，单节点读写)、ReadWriteMany(RWX，多节点读写)、ReadOnlyMany(ROX，多节点只读)
    - `capacity` 定义PV空间的大小
        - `storage` eg：5G(1000换算)、5Gi(1024换算)、T/Ti等
    - `nfs` 基于nfs配置pv。还可通过其他方式如分布式存储、云存在进行配置
    - `persistentVolumeReclaimPolicy` 回收pv策略。取值：Retain(保留，需手动删除，默认值)、Recycle(回收，只有 NFS 和 HostPath 支持)、Delete(关联的存储资产如EBS、Azure Disk等将被删除)
- `kubectl explain pvc.spec` 查看PersistentVolumeClaim(pvc)配置
    - `accessModes` 定义访问模式，必须是PV的访问模式的子集
    - `resources` 定义申请资源的大小
        - `requests`
            - `storage` 定义大小，eg：3Gi
- PVC、PV、StorageClass
    - 存储管理员提前创建不同存储服务(nfs、glusterfs等)，K8s集群管理根据不同的持久化卷类型配置存储卷映射(PV，集群公共资源)，用户基于存储卷创建定义PVC
    - `PV`状态：`Available`(可用) -> `Bound`(绑定) -> `Released`(释放) -> Failed(失败。该卷的自动回收失败)
        - Released说明：声明被删除，但是资源还未被集群重新声明。当pv回收策略为Retain时，删除了此pv之前绑定的pvc后，此时pod中数据得到了保留，但其 PV 状态会一直处于 Released，不能被其他 PVC 申请。为了重新使用存储资源，可以删除PV并重新创建该PV(**删除 PV 操作只是删除了 PV 对象，存储空间中的数据并不会被删除**)
    - `PVC`状态：`Pending`(准备中) -> `Bound`(绑定)
        - PVC一直处于Pending状态，而PV却处于Bound状态，可能情况：如使用的NFS服务器关闭了；定义的PV大小、读写类型不符合PVC的要求
        - PV一直处于Released状态：如果确认此PV不再使用(对应的数据文件目录)，可删除此PV重新创建PV
    - `StorageClass`资源配置
        - 在pvc申请存储空间时，未必就有现成的pv符合pvc申请的需求。当用户突然需要使用PVC时，可通过restful发送请求StorageClass，继而让存储空间创建相应的存储image，之后在集群中定义对应的PV供给当前的PVC作为挂载使用。因此存储系统必须支持restful接口，比如ceph分布式存储，而glusterfs则需要借助第三方接口完成这样的请求
    - PV和PVC创建无需先后顺序
- `ConfigMap`和`Secret`为一种特殊的存储卷

#### emptyDir案例

- 此时busybox与nginx使用的存储卷相同，因此可看成是同一个目录
    - busybox修改容器中/data/index.hmtl文件 -> 相当于busybox挂载的存储卷html下index.html被修改 -> 相当于nginx容器/usr/share/nginx/html目录下的index.html文件被修改。实际是同一个文件
    - `kubectl get pods -o wide`查看pod对应IP，再使用`curl 10.244.1.22`访问即可看到网页变化
- 测试案例配置

```yml
apiVersion: v1
kind: Pod
metadata:
  name: sq-volumes
  namespace: default
  labels:
    app: sq-volumes
spec:
  containers:
  - name: sq-nginx
    image: nginx:1.14-alpine
    volumeMounts:
    # 对应此pod定义的存储卷名
    - name: html
      # 挂载容器的目录
      mountPath: /usr/share/nginx/html
  - name: sq-busybox
    image: busybox
    # pod中多个容器必须都要挂载才能访问存储券
    volumeMounts:
    # 对应此pod定义的存储卷名
    - name: html
      mountPath: /data/
    # 此时busybox容器会定时往index.hmtl中加数据
    command: ['/bin/sh', '-c', 'while true; do echo $(date) >> /data/index.html; sleep 2; done']
  volumes:
  - name: html
    # 使用默认配置
    emptyDir: {}
```

#### PVC、PV、NFS配合使用案例

- 配置NFS：此处使用192.168.6.10(store1)作为NFS存储服务器，此服务器和所有的Node节点必须安装NFS

```bash
## store1 进行如下配置
# 安装nfs
yum -y install nfs-utils
# 启动nfs服务
systemctl start nfs && systemctl enable nfs # 启动后NFS的服务状态为`Active: active (exited)`是正常的
# 创建两个目录并设置为任何人可读写
mkdir /data/volumes/v{1,2} -pv && chmod 777 /data/volumes/v{1,2}
# 编辑暴露配置
cat > /etc/exports << EOF
/data/volumes/v1 192.168.6.0/24(rw,all_squash)
/data/volumes/v2 192.168.6.0/24(rw,all_squash)
EOF
# 执行暴露目录
exportfs -arv
# 查看配置
showmount -e
# 在其他机器测试挂载nfs存储卷
# mount -t nfs 192.168.6.10:/data/volumes/v1 /mnt
```
- 创建pv、pvc、pod

```yml
## sq-pv.yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
  labels:
    name: pv001
spec:
  nfs:
    server: 192.168.6.10
    path: /data/volumes/v1
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 1Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
  labels:
    name: pv002
spec:
  nfs:
    server: store1
    path: /data/volumes/v2
  accessModes: ["ReadWriteMany"]
  capacity:
    storage: 2Gi

## sq-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sq-pvc
  namespace: default
spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: sq-volumes-pvc
  namespace: default
spec:
  containers:
  - name: sq-nginx
    image: nginx:1.14-alpine
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  volumes:
    - name: html
      persistentVolumeClaim:
        claimName: sq-pvc
```
- 测试
    - 找到pod绑定的pv(`kubectl get pvc`)，从而得知pv对应的nfs目录
    - 进入到store1对应目录创建主页 `echo "welcome smalle!" > index.html`
    - 访问此pod，如`curl 10.244.1.22`

### 网络

- K8s网络类型：节点网络、Service网络(10.xx，生成虚拟的IP)、Pod网络(默认10.244.0.0/16)
    - 节点一：cni0(10.244.0.1/24)、flannel.1(10.244.0.1/32)
    - 其他节点：10.244.1.x, ... , 10.244.x.x
    - `--pod-network-cidr=10.244.0.0/16` 初始master节点参数，则规定pod网络为此参数设定的。运行pod后会产生一个`cni0`的网桥，pod网络只能在K8s集群内部使用
- 通信方式 [^7]

    ![k8s-network](/data/images/devops/k8s-network.png)

    ![k8s-network2](/data/images/devops/k8s-network2.webp)

    - 同一个Pod内多个容器之间通信：Pod本地
        - 一个Pod内多个容器共享同一个网络命名空间，每个Docker容器拥有与Pod相同的IP和port地址空间，可以通过localhost相互访问。本质是是使用Docker的`-net=container`网络模型
    - 各Pod之间通信：物理网桥、Overlay叠加网络
        - 同一Node上的两个Pod通过veth对链接到root网络命名空间(宿主机)，并且通过网桥(宿主机的docker0)进行通信
        - 不同Node上的Pod通信(如上图k8s-network2：Node-vm1上的Pod1与Node-vm2上Pod4之间进行交互)
            - 首先pod1通过自己的以太网设备eth0把数据包发送到关联到root命名空间的veth0上，然后数据包被Node1上的网桥设备cbr0(docker0)接受到，网桥查找转发表发现找不到pod4的Mac地址，则会把包转发到默认路由(root命名空间的eth0设备)，然后数据包经过eth0就离开了Node1，被发送到网络
            - 数据包到达Node2后，首先会被root命名空间的eth0设备，然后通过网桥cbr0把数据路由到虚拟设备veth1,最终数据表会被流转到与veth1配对的另外一端(pod4的eth0)
        - Overlay网络(VxLan)参考：[http://blog.aezo.cn/2017/06/25/devops/docker/](/_posts/devops/docker.md#docker网络)
        - Flannel(见下文CNI插件)致力于给k8s集群中的nodes提供一个3层网络，他并不控制node中的容器是如何进行组网的，仅仅关心流量如何在node之间流转
            - 上例中流量从Node1上的网桥设备cbr0到达宿主机eth0时，中间会经过flannel0，并有flanneld进程进行封包才到达eth0；相反从Node2的eth0到达网桥前也会经过flannel0由flanneld进程解包
    - Pod与Service之间通信：Kube-proxy(运行在Node上的守护进程)，参考上文Service
- 集群内部通信是点对点通信(Https通信)，需CA证书的S/C类型
    - `etcd - etcd`
    - `etcd - API Server`
    - `API Server - CLI`
    - `API Server - Node(Kublet)`
    - `API Server - Node(Kube-proxy)`
- `CNI` K8s基于CNI网络接口进行通信，只要实现了CNI接口都可用于K8s上的通信
    - 解决方案：虚拟网桥、多路复用(MacVLAN)、硬件交换(SR-IOV)
- 常用CNI插件(/etc/cni/net.d)
    - `flannel` 支持网络配置
        - 会运行在所有的`kubelet`上，每个节点会运行一个相应的pod(DaemonSet守护进程)
        - 对应ConfigMap参数(`kubectl get configmap kube-flannel-cfg -o yaml -n kube-system`)
            - `Network` flannel使用的CIDR格式的网络地址，用于为Pod配置网络功能
                - 示例一：`10.244.0.0/16`(可容纳256个节点，默认)：master(此节点上的pod网络为10.244.0.0/24)、node01(10.244.1.0/24)、...、node255(10.244.255.0/24)
                    - 此时可容纳256个节点，每个节点还可以部署256个容器。理论上一个节点不会部署太多容器，因此可适当调节子网掩码从而扩大节点个数
                - 示例二：`10.0.0.0/8`(可容纳2^16=65536个节点)：10.0.0.0/24、...、10.255.255.0/24(默认第2-3段为子网，第4段为节点内部使用)
            - `SubnetLen` 把Network切分子网供各节点使用时，使用的掩码切分长度节点网络，默认24位(则剩余8位可为主机号，即一个节点上可运行的pod数量为256)掩码
            - `SubnetMin` 最小的子网地址。eg：10.244.0.0/24
            - `SubnetMax` eg：10.244.255.0/24
            - `Backend` 支持后端类型`Type`取值：`vxlan`、`host-gw`、`udp`
                - `VxLAN`
                    - Node处于同一网段可使用Directouting，处于不同网段则必须使用VxLAN。VxLAN使用叠加网络，损耗会比Directouting高
                    - 默认没有开启`Directouting`，需要编辑配置文件添加`Directouting: true`
                    - VxLan模式流量走向：cn0 -> flannel.1 -> ens33；Directouting则为：cn0 -> ens33(中间通过路由转换了)
                - `Host Gateway` 要求各节点必须在一个网段
    - `calico` 支持网络配置、网络策略(功能强大，但较flannel复杂)
    - `canel` 上述二者合并
        - Calico可以独立地为Kubernetes提供网络解决方案和网络策略，也可以和flannel相结合，由flannel提供网络解决方案，Calico仅用于提供网络策略，此时将Calico称为Canal
        - 安装(安装canel则无需单独再安装flannel)

            ```bash
            # https://docs.projectcalico.org/v3.8/getting-started/kubernetes/installation/flannel
            # canal内部会安装flannel镜像
            kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/canal.yaml
            kubectl get pods -n kube-system -o wide | grep canal
            ```
- 网络策略(NetworkPolicy，netpol)资源配置

```yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-sq-demo-ingress
  namespace: dev
spec:
  ## 表示所有pod
  #podSelector: {}
  podSelector:
    matchLabels:
      app: sq-demo
  # NetworkPolicy类型，可以是Ingress，Egress，或者两者共存
  policyTypes: ["Ingress"]
  ## 允许所有网络可访问 
  #ingress:
  #- {}
  ## 不定义ingress，则禁止所有网络访问(入站)
  ## 定义入站详细规则
  ingress:
  # 如果不写from则表示所有网段可访问
  - from:
    # 定义可以访问的网段
    - ipBlock:
        cidr: 10.244.0.0/16
        # 排除的网段
        except:
        - 10.244.3.0/24
    - podSelector:
        # 选定当前dev名称空间下标签为app:sq-demo的pod可以被访问
        matchLabels:
          app: sq-demo
    # 开放的协议和端口定义
    ports:
    - protocol: TCP
      port: 80
   # 定义出站规则，与入站类似。不定义则为禁止访问外部网络
   #engress:
```

#### DNS

- ks8常见DNS插件：kube-dns 和 CoreDNS(k8s 1.11默认)
- `kubectl edit configmap coredns -n kube-system` 编辑coredns对应的配置

```bash
.:53 {
    errors
    health
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       upstream                             # upstream 用于解析指向外部主机的服务
       # upstream 172.16.0.1
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    # 自定义域名解析
    # hosts {
    #   192.168.6.131  k8s.aezocn.1.com
    #   192.168.6.132  k8s.aezocn.1.com
    #   fallthrough
    # }
    prometheus :9153            # CoreDNS的度量标准
    forward . /etc/resolv.conf
    # proxy . /etc/resolv.conf  # 任何不在Kubernetes集群域内的查询都将转发到预定义的解析器(/etc/resolv.conf)
    # proxy . 172.16.0.1
    cache 30                    # 这将启用前端缓存
    loop                        # 检测简单的转发循环，如果找到循环则停止CoreDNS进程
    reload                      # 允许自动重新加载已更改的Corefile。编辑ConfigMap配置后，请等待两分钟以使更改生效
    loadbalance                 # 这是一个循环DNS负载均衡器，可以随机化A，AAAA和MX记录的顺序
}
```
- 查看pod容器dns解析配置

```bash
## 在某pod容器中运行 `cat /etc/resolv.conf` 打印如下
nameserver 10.96.0.10 # dns服务器地址(CoreDNS运行在pod中，此ip为pod暴露成服务的ip)
search default.svc.cluster.local svc.cluster.local cluster.local # svc.cluster.local为service在k8s集群中的名称；default为命名空间，此时为默认命令空间
options ndots:5

## 向10.96.0.10的DNS服务器，查询default空间下nginx服务的ip(可以在Node节点上运行)
dig -t A nginx.default.svc.cluster.local @10.96.0.10
# 格式：pod_name.service_name.namespace_name.svc.cluster.local
dig -t A sq-nginx-75875cf46f-829nm.sq-nginx.default.svc.cluster.local @10.96.0.10
```
- 其他说明
    - 服务重新创建后，服务会重新生成虚拟IP，且会反馈到CoreDNS中。其他pod仍然可以使用此服务名称进行访问

### 访问API Server认证

- `RBAC` 基于角色的访问控制
    - k8s基于RBAC进行权限控制
    - `Role` 对象的作用范围是命名空间(namespace)内，`ClusterRole` 对象的作用范围是k8s集群范围
        - `Role`(`kubectl explain Role`)
            - `rules`
                - `apiGroups` 限定的api列表，不限定则可以加一个`- ""`子元素
                - `resources` 资源列表，如：`["nodes", "pods", "deployments", "namespaces"]`
                - `verbs` 可执行动作列表，如：`["get", "list", "watch", "create", "update", "patch", "delete"]` 或者 `['*']`
        - `ClusterRole` 集群角色(无namespace概念)
    - `RoleBinding` 和 `ClusterRoleBinding` 则是(普通/集群)角色和用户的绑定关系
- 创建访问API Server账号
    - 如果是创建Dashboard访问账号，则是创建ServiceAccount，参考下文手动安装Dashboard

```bash
# 创建证书
cd /root/.certs
(umask 077; openssl genrsa -out aezo.key 2048) # 生成证书
openssl req -new -key aezo.key -out aezo.csr -subj "/CN=aezo" # 证书签署请求
openssl x509 -req -in aezo.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out aezo.crt -days 365 # 添加到用户认证，有效期365天
openssl x509 -in aezo.crt -text -noout # 查看

# 添加用户到当前证书
kubectl config set-credentials aezo --client-certificate=./aezo.crt --client-key=./aezo.key --embed-certs=true # 创建用户（如何删除？？？）
kubectl config set-context aezo@kubernetes --cluster=kubernetes --user=aezo # 创建上下文
# kubectl config delete-context aezo@kubernetes

# 查看用户配置：会多出一个context(定义用户可以访问的集群)和user
kubectl config view
# 切换用户context，以aezo用户权限访问集群API Server(view中current-context会变成当前用户context)
kubectl config use-context aezo@kubernetes
# 提示：Error from server (Forbidden): pods is forbidden: User "aezo" cannot list resource "pods" in API group "" in the namespace "default"。由于aezo用户无管理集群的权限，所以在获取pods资源信息时，会提示Forrbidden
# 对此用户赋予权限参考下文
# kubectl get pods --context=aezo@kubernetes # 或者通过设定context查询
kubectl get pods
```
- 创建角色和绑定关系示例

```bash
## 创建角色
# 干跑模式查看role的定义，不会产生实际操作，创建clusterrole同理。--verb操作权限定义，--resource资源定义
kubectl create role my-pods-reader --verb=get,list,watch --resource=pods --dry-run -o yaml
# 干跑模式生成创建role配置文件
kubectl create role my-pods-reader --verb=get,list,watch --resource=pods --dry-run -o yaml > role-demo.yaml
kubectl apply -f role-demo.yaml
kubectl describe role my-pods-reader

## 创建角色绑定
kubectl create rolebinding aezo-read-pods --role=my-pods-reader --user=aezo --dry-run -o yaml > rolebinding-demo.yaml
kubectl apply -f rolebinding-demo.yaml
kubectl describe rolebinding aezo-read-pods

## 使用上述创建的aezo账号测试
kubectl config use-context aezo@kubernetes
kubectl get pods # 此时不会显示Forrbidden
```
- 创建新集群示例

```bash
# --kubeconfig 设置集群配置文件，默认文件为 `${HOME}/.kube/config`(默认集群文件)
kubectl config set-cluster my-cluster --kubeconfig=/tmp/test.conf --server="https://192.168.6.131:6443" --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true
# 查看集群
kubectl config view --kubeconfig=/tmp/test.conf
```
- 创建某命名空间的SA管理用户用于登录Dashboard

```bash
kubectl create namespace aezo-test
kubectl create serviceaccount sa-aezo-admin -n aezo-test
# --serviceaccount=SA命名空间:SA。此处-n aezo-test则代表rolebinding属于此命名空间，则相当于赋予此SA账户clusterrole=admin所拥有的aezo-test命名空间的部分权限
kubectl create rolebinding test:sa-aezo-admin --clusterrole=admin --serviceaccount=aezo-test:sa-aezo-admin -n aezo-test
kubectl get secret $(kubectl get secret -n aezo-test|grep sa-aezo-admin-token|awk '{print $1}') -n aezo-test -o jsonpath={.data.token}|base64 -d |xargs echo
# 问题：登录后页面默认显示的是default命名空间，需要手动输入或者访问带上命名空间：https://192.168.6.131:30000/#!/overview?namespace=java-test
```

### 调度器

- API Server在接受客户端提交Pod对象创建请求后，然后是通过调度器（kube-schedule）从集群中选择一个可用的最佳节点来创建并运行Pod。而这一个创建Pod对象，在调度的过程当中有3个阶段：节点预选(过滤不符合条件的节点)、节点优选(对预选出的节点进行优先级排序)、节点选定(符合条件且优选级相同的则随机选择需要的数量)，从而筛选出最佳的节点
- 常用的预选策略(https://github.com/kubernetes/kubernetes/blob/master/pkg/scheduler/algorithm/predicates/predicates.go)
    - CheckNodeCondition：检查是否可以在节点报告磁盘、网络不可用或未准备好的情况下将Pod对象调度其上
    - GeneralPredicates
        - HostName：如果Pod对象拥有spec.hostname属性，则检查节点名称字符串是否和该属性值匹配
        - PodFitsHostPorts：如果Pod对象定义了ports.hostPort属性，则检查Pod指定的端口是否已经被节点上的其他容器或服务占用
        - MatchNodeSelector：如果Pod对象定义了spec.nodeSelector属性，则检查节点标签是否和该属性匹配
        - PodFitsResources：检查节点上的资源(CPU、内存)可用性是否满足Pod对象的运行需求
    - NoDiskConflict：检查Pod对象请求的存储卷在该节点上可用
    - PodToleratesNodeTaints：如果Pod对象中定义了spec.tolerations属性，则需要检查该属性值是否可以接纳节点定义的污点(taints)
    - PodToleratesNodeNoExecuteTaints：如果Pod对象定义了spec.tolerations属性，检查该属性是否接纳节点的NoExecute类型的污点
    - CheckNodeLabelPresence：仅检查节点上指定的所有标签的存在性，要检查的标签以及其可否存在取决于用户的定义
    - CheckServiceAffinity：根据当前Pod对象所属的Service已有其他Pod对象所运行的节点调度，目前是将相同的Service的Pod对象放在同一个或同一类节点上
    - CheckVolumeBinding：检查节点上已绑定和未绑定的PVC是否满足Pod对象的存储卷需求
    - NoVolumeZoneConflct：在给定了区域限制的前提下，检查在该节点上部署Pod对象是否存在存储卷冲突
    - CheckNodeMemoryPressure：在给定了节点已经上报了存在内存资源压力过大的状态，则需要检查该Pod是否可以调度到该节点上
    - CheckNodePIDPressure：如果给定的节点已经报告了存在PID资源压力过大的状态，则需要检查该Pod是否可以调度到该节点上
    - CheckNodeDiskPressure：如果给定的节点存在磁盘资源压力过大，则检查该Pod对象是否可以调度到该节点上
    - MatchInterPodAffinity：检查给定的节点能否可以满足Pod对象的亲和性和反亲和性条件，用来实现Pod亲和性调度或反亲和性调度
    - MaxEBSVolumeCount/MaxGCEPDVolumeCount/MaxAzureDiskVolumeCount：云计算存储卷检查
- 优选算法(https://github.com/kubernetes/kubernetes/tree/master/pkg/scheduler/algorithm/priorities)
- 亲和性(`kubectl explain pods.spec.affinity`)
    - 在出于高效通信的需求，有时需要将一些Pod调度到相近甚至是同一区域位置(比如同一节点、机房、区域)等等，比如业务的前端Pod和后端Pod，此时这些Pod对象之间的关系可以叫做亲和性；同时出于安全性的考虑，也会把一些Pod之间进行隔离，此时这些Pod对象之间的关系叫做反亲和性(anti-affinity)

```yml
apiVersion: v1
kind: Pod
metadata:
  name: sq-affinity
spec:
  affinity:
    # 节点亲和性
    nodeAffinity:
      # 硬亲和性(必须满足)
      requiredDuringSchedulingIngnoreDuringExecution:
        nodeSelectorTerms: # 只需满足一个nodeSelectorTerms
        - matchExpressions: # 必须满足所有matchExpressions(此时匹配节点labels)
          - {key: zone, operator: In, values: ["sh"]}
      # 节点软亲和性
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
        preference:
          matchExpressions:
          - {key: zone, operator: In, values: ["cn"]}
    # Pod亲和性
    podAffinity:
      # 硬亲和性
      requiredDuringSchedulingIngnoreDuringExecution:
      - labelSelector:
          matchExpression:
          - {key: app, operator: In, values: ["tomcat"]}
        # 使用哪个键来判断pod的位置信息。此时pods labels key=kubernetes.io/hostname则会按照节点的hostname去判定是否在同一位置区域
        topologyKey: kubernetes.io/hostname
      # 软亲和性
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 80
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - {key: app, operator: In, values: ["cache"]}
        topologyKey: zone
      - weight: 20
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - {key: app, operator: In, values: ["db"]}
        topologyKey: zone
    # Pod反亲和性(同上)
    #podAntiAffinity:
  containers:
  - name: sq-nginx
    image: nginx:1.14-alpine
```
- 污点(作用于节点上)
    - 污点类型
        - NoSchedule：不能容忍此类污点的新Pod对象不能调度到该节点上。强制约束，节点历史存在的Pod对象不受影响
        - PreferNoSchedule：即不能容忍此污点的Pod对象尽量不要调度到该节点，不过无其他节点可以调度时也可以允许接受调度。柔性约束，节点历史存在的Pod对象不受影响
        - NoExecute：不能容忍此类污点的新Pod对象不能调度该节点上。强制约束，会影响历史存在的Pod
    - 命令

        ```bash
        ## 查看示例
        kubectl describe node node1 # 查看node1节点污点(Taints)
        kubectl describe pods kubernetes-dashboard-5dc4c54b55-ft4xh -n kube-system # 查看pod容忍污点(Tolerations)

        ## 添加污点语法：kubectl taint nodes <nodename> <key>=<value>:<effect>
        # 给node1添加污点
        kubectl taint nodes node1 profile=prod:NoSchedule
        # 查看污点
        kubectl get nodes node1 -o go-template={{.spec.taints}}

        ## 删除语法：kubectl taint nodes <node-name> <key>[: <effect>]-
        kubectl taint nodes node1 profile:NoSchedule- # 删除profile键名的NoSchedule类型污点
        kubectl taint nodes node1 profile- # 删除指定键名的所有污点
        ```
    - 常见污点

        ```bash
        # 安装的master节点对应污点
        node-role.kubernetes.io/master:NoSchedule
        ```
- pod的容忍度(查看`kubectl explain pods.spec.tolerations`)
    - `operator` 包含`Equal`和`Exists`两种类型。如果操作符为Exists，那么value属性可省略，如果不指定operator，则默认为Equal
    - `effect` 为上述污点类型
    - 添加容忍度配置的pod表示此pod可以接受节点上的相应污点

```yml
# Equal
tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoExecute"
# Exists：表示此pod可以容忍存在NoExecute类型的node.kubernetes.io/not-ready污点
# 显示成 Tolerations: node.kubernetes.io/not-ready:NoExecute for 300s
- effect: NoExecute
  key: node.kubernetes.io/not-ready
  operator: Exists
  # 如果运行此Pod的Node，被设置了具有NoExecute效果的污点，这个Pod将在存活300s后才被驱逐；如果没有设置tolerationSeconds字段，将永久运行
  tolerationSeconds: 300
```
- 相关调度失败显示

```bash
# eg: kubectl describe pods my-dev-mysql-6fc6466d86-v5mxd
# 此时调度失败，pod处于 Pending 状态：总共3个有效节点，1个节点存在不可容忍污点，另外2个几点内存不足
Warning  FailedScheduling  4m (x145 over 174m)  default-scheduler  0/3 nodes are available: 1 node(s) had taints that the pod didn't tolerate, 2 Insufficient memory
```

### 资源限制及监控

- 资源需求及限制配置

```yml
# 此时 Pod 的服务质量等级是 Burstable
spec:
  containers:
    resources:
      # 此容器的资源需求
      requests:
        # 1逻辑CPU=1000millicores，500m=0.5CPU
        cpu: "500m"
        # E/P/T/G/M/K(1000); Ei/Pi/...(1024换算)
        memory: "256Mi"
      # 对此容器的资源限制
      limits:
        cpu: "1"
        memory: "512Mi"
```
- QoS(服务质量等级，`kubectl describe pods sq-test`中的QoS Class自动归类显示)
    - `Guranteed` 所有容器同时设置了CPU和内存的requests和limits，且请求和限制相同，高优先级
    - `Burstable` 至少有一个容器设置了CPU或内存的requests属性或limits，中优先级
    - `BestEffort` 没有任何容器设置了requests和limits，低优先级(有可能会吞掉太多资源，因此当资源不足时优先关闭此类Pod)
- 基于HeapSter监控(弃用)
    - Heapster作为kubernetes安装过程中默认安装的一个插件，同时在Horizontal Pod Autoscaling中也用到了，HPA将Heapster作为Resource Metrics API
    - Heapster可以收集Node节点上的cAdvisor数据，还可以按照kubernetes的资源类型来集合资源，比如Pod、Namespace域，可以分别获取它们的CPU、内存、网络和磁盘的metric。默认的metric数据聚合时间间隔是1分钟；也可将这些信息存储到InfluxDB，然后结合Grafana进行显示
    - Kubernetes 1.11 不建议使用 Heapster，推荐使用metrics-server
- 推荐监控
    - 核心指标流水线：由kubelet、metrics-server以及API server提供的api组成；CPU累计使用率、内存实时占用率、Pod资源占用率、容器磁盘占用率
    - 监控流水线：用于从系统(Prometheus)收集各种指标数据并提供终端用户、存储系统以及HPA，包含核心指标及许多非核心指标(不能被k8s所解析)
- metrics-server
    - API Server提供了一套api资源，而Mertrics Server也通过了一套api(/apis/metrics.k8s.io/v1beta1)，此时需要将这两套api聚合成一个即kube-aggregator提供用户统一访问
    - 安装metrics-server

        ```bash
        mkdir metrics-server
        # 下载配置文件
        for file in auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml ; do wget https://github.com/kubernetes/kubernetes/raw/release-1.15/cluster/addons/metrics-server/$file; done

        # 查看并更换无法访问镜像地址
        grep 'image: k8s.gcr.io' *
        sed -i 's/image: k8s.gcr.io/image: registry.aliyuncs.com\/google_containers/g' *
        # 修改 metrics-server-deployment.yaml 中{{}}信息
        sed -i 's/--cpu={{ base_metrics_server_cpu }}/--cpu=80m/g' metrics-server-deployment.yaml
        sed -i 's/--memory={{ base_metrics_server_memory }}/--memory=80Mi/g' metrics-server-deployment.yaml
        sed -i 's/--extra-memory={{ metrics_server_memory_per_node }}Mi/--extra-memory=8Mi/g' metrics-server-deployment.yaml
        sed -i 's/- --minClusterSize={{ metrics_server_min_cluster_size }}/#- --minClusterSize={{ metrics_server_min_cluster_size }}/g' metrics-server-deployment.yaml
        sed -i 's/- --kubelet-port=10255/#- --kubelet-port=10255/g' metrics-server-deployment.yaml # 关闭http的访问，使用tls
        sed -i 's/- --deprecated-kubelet-completely-insecure=true/#- --deprecated-kubelet-completely-insecure=true/g' metrics-server-deployment.yaml
        # 在 `- --metric-resolution=30s` 后加一行 `- --kubelet-insecure-tls`
        # 修改 resource-reader.yaml，在 `- namespaces` 后加一行 `- nodes/stats`
        # 修改 resource-reader.yaml，加入 subjectaccessreviews 资源的操作. 参考：https://github.com/kubernetes-incubator/metrics-server/issues/277#issuecomment-514961241

        # 应用所有的配置文件
        kubectl apply -f .
        # 查看状态
        kubectl get pods -n kube-system # metrics-server-v0.3.3-867b87bf58-2thdd
        kubectl api-versions # 查看API列表，会增加一个 metrics.k8s.io/v1beta1

        # 基于top命令查看监控指标
        kubectl top pods
        kubectl top nodes
        ```

#### Prometheus

- 基于[Prometheus](https://prometheus.io/)监控
- Prometheus可基于如node_exporter进行监控，并提供PromQL查询语句来展示监控状态，但是PromQL不支持API server，因此中间可使用插件k8s-prometheus-adpater来执行API server的命令，并转成PromQL语句执行
- 架构 [^4]

    ![Prometheus](/data/images/devops/Prometheus.png)
    - `Prometheus Server` 主要用于抓取数据和存储时序数据，另外还提供查询和 Alert Rule 配置管理
    - `client libraries` 用于对接 Prometheus Server，可以查询和上报数据
    - `push gateway` 用于批量，短期的监控数据的汇总节点，主要用于业务数据汇报等
    - `exporters` 进行各种数据汇报，例如汇报机器数据的 node_exporter，汇报 MongoDB 信息的 MongoDB exporter 等等
    - `alertmanager` 告警通知管理
- Prometheus工作说明
    - Prometheus需要的metrics要么程序定义输出(模块或者自定义开发)；要么用官方的各种exporter(node-exporter，mysqld-exporter，memcached_exporter…)采集要监控的信息，占用一个web端口然后输出成metrics格式的信息
    - prometheus server去收集各个target的metrics存储起来(tsdb)
    - 用户可以在prometheus的http页面上用promQL(prometheus的查询语言)或者(grafana数据来源就是用)api去查询一些信息，也可以利用pushgateway去统一采集，然后prometheus从pushgateway采集(所以pushgateway类似于zabbix的proxy)
- [prometheus-operator](https://github.com/coreos/prometheus-operator) [^5]
    - `Prometheus-operator`的本职就是一组用户自定义的CRD资源以及Controller的实现，Prometheus Operator这个controller有BRAC权限下去负责监听这些自定义资源的变化。相关CRD说明
        - `Prometheus`：由 Operator 依据一个自定义资源kind: Prometheus类型中，所描述的内容而部署的 Prometheus Server 集群，可以将这个自定义资源看作是一种特别用来管理Prometheus Server的StatefulSets资源
        - `ServiceMonitor`：一个Kubernetes自定义资源(和kind: Prometheus一样是CRD)，该资源描述了Prometheus Server的Target列表，Operator 会监听这个资源的变化来动态的更新Prometheus Server的Scrape targets并让prometheus server去reload配置(prometheus有对应reload的http接口/-/reload)。而该资源主要通过Selector来依据 Labels 选取对应的Service的endpoints，并让 Prometheus Server 通过 Service 进行拉取（拉）指标资料(也就是metrics信息)，metrics信息要在http的url输出符合metrics格式的信息，ServiceMonitor也可以定义目标的metrics的url
        - `Alertmanager`：Prometheus Operator 不只是提供 Prometheus Server 管理与部署，也包含了 AlertManager，并且一样通过一个 kind: Alertmanager 自定义资源来描述信息，再由 Operator 依据描述内容部署 Alertmanager 集群
        - `PrometheusRule`：对于Prometheus而言，在原生的管理方式上，我们需要手动创建Prometheus的告警文件，并且通过在Prometheus配置中声明式的加载。而在Prometheus Operator模式中，告警规则也编程一个通过Kubernetes API 声明式创建的一个资源.告警规则创建成功后，通过在Prometheus中使用想servicemonitor那样用ruleSelector通过label匹配选择需要关联的PrometheusRule即可
        - 注：安装下文安装完成后可通过`kubectl get APIService | grep monitor`看到新增了`v1.monitoring.coreos.com`的APIService，通过`kubectl get crd`查看相应的CRD
- 基于prometheus-operator安装Prometheus

```bash
# 下载 https://github.com/coreos/kube-prometheus/releases/tag/v0.1.0，将 manifests 目录下所有文件拷贝到 master 的 prometheus 目录
cd ~/k8s/prometheus
# 修改镜像
grep 'image: k8s.gcr.io' *
sed -i 's/image: k8s.gcr.io/image: registry.aliyuncs.com\/google_containers/g' *
# 安装所有CRD
kubectl create -f .

# 检测是否创建
until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
# 有时可能需要多执行几次
kubectl apply -f . # This command sometimes may need to be done twice (to workaround a race condition).
# 查看状态
kubectl -n monitoring get all
```
- 基于下列Ingress配置暴露服务到Ingress Controller。访问`http://grafana.aezocn.local/`，默认用户密码`admin/admin`即可进入Grafana界面
    - 可从[Grafana模板中心](https://grafana.com/grafana/dashboards)下载模板对应的json文件，并导入到Grafana的模板中

```yml
# prometheus-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prometheus-ing
  namespace: monitoring
spec:
  rules:
  - host: prometheus.aezocn.local
    http:
      paths:
      - backend:
          serviceName: prometheus-k8s
          servicePort: 9090
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana-ing
  namespace: monitoring
spec:
  rules:
  - host: grafana.aezocn.local
    http:
      paths:
      - backend:
          serviceName: grafana
          servicePort: 3000
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: alertmanager-ing
  namespace: monitoring
spec:
  rules:
  - host: alertmanager.aezocn.local
    http:
      paths:
      - backend:
          serviceName: alertmanager-main
          servicePort: 9093
```

### HPA

- HPA(HorizontalPodAutoscaler，弹性伸缩)目前有`v1`和`v2`版。`v1`版只支持核心指标的缩放，核心指标包括CPU和内存(不可压缩性资源，因此不支持弹性伸缩)
- 测试案例

    ```bash
    # 创建deployment
    kubectl run sq-hpa --image=nginx:1.14-alpine --replicas=1 --requests='cpu=50m,memory=256Mi' --limits='cpu=50m,memory=256Mi' --labels='app=sq-hpa' --expose --port=80
    # 设置deployment伸缩(hpa)。此处当cpu使用率达到20%则进行扩展
    kubectl autoscale deployment sq-hpa --min=1 --max=8 --cpu-percent=20
    # 查看hpa设置
    kubectl get hpa -w

    # 压力测试
    kubectl get svc -o wide
    yum install httpd-tools
    ab -c 100 -n 50000 http://10.106.200.196/
    # 会看到pods个数会增加
    kubectl describe hpa sq-hpa
    kubectl get pods
    ```
    - 出现问题 `subjectaccessreviews.authorization.k8s.io is forbidden: User \"system:serviceaccount:kube-system:metrics-server\" cannot create resource \"subjectaccessreviews\" in API group \"authorization.k8s.io\" at the cluster scope"`
        - 解决方案：上文`metrics-server`安装时需要在`resource-reader.yaml`中加入`subjectaccessreviews`资源的操作

## 辅助组件使用

- `Helm` 参考：[《http://blog.aezo.cn/2019/06/22/devops/k8s-helm/》](/_posts/devops/helm.md)

### 手动安装Dashboard

- [github](https://github.com/kubernetes/dashboard)
- 安装

```bash
## 安装
wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
# 修改Dashboard Service配置为NodePort，伪代码如：添加spec.ports[0].nodePort=30000，添加spec.type=NodePort。一般可通过Ingress暴露出来
# 修改容器镜像 `k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1` 为 `registry.aliyuncs.com/google_containers/kubernetes-dashboard-amd64:v1.10.1`
# 修改token过期时间，默认是15分钟(900秒)：在 `- --auto-generate-certificates` 下加一行参数 `- --token-ttl=31536000‬` (1年有效)
vi kubernetes-dashboard.yaml
# 创建资源(pod运行在master节点上)
kubectl apply -f kubernetes-dashboard.yaml
# 查看
kubectl get pods -n kube-system
# 访问 https://192.168.6.131:30000/ 可显示登录页面(仅火狐浏览器支持，下文可解决)，登录秘钥获取见下文

## 配置https证书
# 生成私钥和证书签名
openssl genrsa -des3 -passout pass:x -out dashboard.pass.key 2048
openssl rsa -passin pass:x -in dashboard.pass.key -out dashboard.key
rm dashboard.pass.key
openssl req -new -key dashboard.key -out dashboard.csr # 一路回车即可
openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt # 生成SSL证书
# mkdir /var/share/certs/ -p && cp dashboard.key dashboard.crt /var/share/certs/ # 可对私钥和密码进行保存

## 重新创建dashboard默认证书(默认证书导致只能通过火狐浏览器访问，此步骤可解决此问题)
kubectl delete secret kubernetes-dashboard-certs -n kube-system # 删除原有的证书secret
kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key=./dashboard.key --from-file=./dashboard.crt -n kube-system # 创建新的证书secret
kubectl get pod -n kube-system # 查看pod
kubectl delete pod kubernetes-dashboard-5dc4c54b55-ft4xh -n kube-system # 按情况删除pod(会自动重新创建)

## 创建 ServiceAccount 和 ClusterRoleBinding
# 创建serviceaccount
kubectl create serviceaccount sa-admin -n kube-system
# service account账户绑定到集群角色admin
kubectl create clusterrolebinding dev:cluster-sa-admin --clusterrole=cluster-admin --serviceaccount=kube-system:sa-admin

## 法一：基于token登录
# 查看 ServiceAccount 对应的 Secret token。复制此token以令牌形式登录 https://192.168.6.131:30000/ 即可
kubectl get secret $(kubectl get secret -n kube-system|grep sa-admin-token|awk '{print $1}') -n kube-system -o jsonpath={.data.token}|base64 -d |xargs echo
## 法二：基于kubeconfig文件登录
kubectl config set-cluster kubernetes --certificate-authority=/etc/kubernetes/pki/ca.crt --server="https://192.168.6.131:6443" --embed-certs=true --kubeconfig=./cluster-sa-admin.conf
kubectl config set-credentials sa-admin --token=$(kubectl get secret $(kubectl get secret -n kube-system|grep sa-admin-token|awk '{print $1}') -n kube-system -o jsonpath={.data.token}|base64 -d |xargs echo) --kubeconfig=./cluster-sa-admin.conf
kubectl config set-context sa-admin@kubernetes --cluster=kubernetes --user=sa-admin --kubeconfig=./cluster-sa-admin.conf
kubectl config use-context sa-admin@kubernetes --kubeconfig=./cluster-sa-admin.conf
# 下载 ./cluster-sa-admin.conf 文件到宿主机，登录选择此文件即可
```

## 常见问题

- `kubectl get nodes` 显示Node状态为NotReady
    - 查看对应节点的网络插件(Pod)是否正常启动
    - 查看对应节点服务状态`systemctl status kubelet/docker`
    - `journalctl -f -u kubelet` 查看对应节点kubelet启动日志


---

参考文章

[^1]: https://www.kubernetes.org.cn/5551.html (使用kubeadm安装Kubernetes 1.15)
[^2]: https://webcache.googleusercontent.com/search?q=cache:63AJZgZ4YK4J:https://ciweigg2.github.io/2019/06/01/kubernetes-1.15.0-ji-qun-an-zhuang-he-dashbaord-mian-ban/+&cd=10&hl=zh-CN&ct=clnk&gl=hk
[^3]: https://www.cnblogs.com/linuxk/p/9706720.html (Ingress和Ingress Controller)
[^4]: https://jimmysong.io/kubernetes-handbook/practice/prometheus.html
[^5]: https://www.servicemesher.com/blog/prometheus-operator-manual/
[^6]: https://www.qikqiak.com/post/how-to-use-ipvs-in-kubernetes/
[^7]: https://www.jianshu.com/p/3f2401d14c78 (K8s网络模型)



