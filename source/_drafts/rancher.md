---
layout: "post"
title: "Rancher"
date: "2020-01-07 19:15"
categories: devops
tags: [k8s, docker, cncf]
---

## 简介

- [rancher](https://www.rancher.cn/) 对所有环境进行集成的. [github](https://github.com/rancher/rancher)、[中文文档](https://docs.rancher.cn/)
- [k3s](https://www.rancher.cn/k3s/) 适用于物联网/树莓派的轻量级Kubernetes版本
- `Rancher Server`：是用于管理和配置 Kubernetes 集群。您可以通过 Rancher Server 的 UI 与下游 Kubernetes 集群进行交互
- `RKE（Rancher Kubernetes Engine)`：是经过认证的 Kubernetes 发行版，它拥有对应的 CLI 工具可用于创建和管理 Kubernetes 集群。在 Rancher UI 中创建集群时，它将调用 RKE 来配置 Rancher 启动的 Kubernetes 集群
- `K3s (轻量级 Kubernetes)`：和 RKE 类似，也是经过认证的 Kubernetes 发行版

## rancher安装

- rancher可通过docker安装(rancher-server)，属于单节点安装。启动成功rancher后，可通过他创建多个k8s集群
- rancher集群安装(高可用)，官方推荐通过k8s集群的heml安装。安装成功后，再创建新的k8s集群
- rancher还推出了k3s，功能同k8s，因此可先安装k3s，再安装rancher，从而实现rancher集群安装

### 单节点安装

- [单节点安装](https://docs.rancher.cn/docs/rancher2/installation_new/other-installation-methods/single-node-docker/_index)

```bash
## v2.5.3 硬件要求：4GB内存、Centos 7.5
docker run -d --privileged --restart=unless-stopped --name rancher-server \
    -p 80:80 -p 443:443 \
    -v /data/rancher_home/rancher:/var/lib/rancher \
    -v /data/rancher_home/auditlog:/var/log/auditlog \
    docker.mirrors.ustc.edu.cn/rancher/rancher:v2.5.3 \
    --acme-domain test.aezo.cn # 使用 Let's Encrypt 证书

# 安装成功后访问：https://test.aezo.cn 即可显示管理界面
## 注意：安装成功后此rancher-server容器不能删除，否则集群配置丢失(应该可以通过etcd进行备份)
```
- 创建集群(安装完成有一个默认的轻量集群k3s)
    - 添加集群 - 创建新的 Kubernetes 集群 - 自定义 - Kubernetes 版本：v1.18(v1.19在centos7上安装kubelet失败)
    - 下一步 - 添加主机选项：Etcd、Control、Worker(工作节点)，主节点可勾选3个，从节点可仅勾选Worker - 复制docker命令 - 在相应主机上执行(rancher-agent)
- 加入agent节点
    - 选中集群扩展选项 - 升级
    - 或者主机管理 - 编辑


### rancher集群安装(基于k3s)

- [k3s安装](#k3s安装)
- rancher安装

```

```

### 常见问题

- `[controlPlane] Failed to upgrade Control Plane: [[host node1 not ready]]`
    - 可能选择的Kubernetes版本太高，如centos7建议选择v1.18
- Cluster health check failed: cluster agent is not ready
    - 可能为rancher服务器域名无法访问，参考：https://github.com/rancher/rancher/issues/29895，`docker ps -a -q --filter "label=io.kubernetes.container.name=cluster-register" | while read container; do echo "=> $container"; docker logs $container; done`查看日志
    - 测试时在宿主机配置了一个假域名导致容器中无法识别此域名
    - 解决：使用IP访问或将域名映射到rancher-server开放的80和443端口

## k3s

- [k3s官方文档](https://docs.rancher.cn/docs/k3s/_index)

### k3s安装

```bash
## 前提
# 关闭防火墙、SELinux、Master可免密登录Agent

## Master节点(192.168.1.130)安装合适的最新稳定版K3s并启动（如centos7-3.10.0
会安装 v1.20.2+k3s1）。其他环境变量(如：INSTALL_K3S_MIRROR)设置参考官网文档：https://docs.rancher.cn/docs/k3s/installation/install-options/_index
curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn sh -
# kubeconfig文件 对应 /etc/rancher/k3s/k3s.yaml
# 查看k3s命令：`k3s -h`
# kubectl get nodes # 执行 kubectl 命令

## Agent节点安装k3s
# 查看token：K1049bba49733eaddced84be865b0f79fce2c1a2ac12373ded91464e0d2c644c8e8::server:28a6e8ca5cb5722f833127800bd0f0f5
cat /var/lib/rancher/k3s/server/node-token
# 安装k3s，安装后可在Master上通过kubectl get nodes查看节点
curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=https://192.168.1.130:6443 K3S_TOKEN=K1049bba49733eaddced84be865b0f79fce2c1a2ac12373ded91464e0d2c644c8e8::server:28a6e8ca5cb5722f833127800bd0f0f5 sh -
```
- 卸载方式

```bash
/usr/local/bin/k3s-uninstall.sh # server
/usr/local/bin/k3s-agent-uninstall.sh # agent
```





https://blog.csdn.net/ory001/article/details/109046761
