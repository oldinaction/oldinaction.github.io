---
layout: "post"
title: "Kubernetes"
date: "2019-06-01 12:38"
categories: arch
tags: [kubernetes, docker]
---


## 

Docker与K8S
​ Docker本质上是一种虚拟化技术，类似于KVM、XEN、VMWARE，但其更轻量化，且将Docker部署在Linux环境时，其依赖于Linux容器技术（LXC）。Docker较传统KVM等虚拟化技术的一个区别是无内核，即多个Docker虚拟机共享宿主机内核，简而言之，可把Docker看作是无内核的虚拟机，每Docker虚拟机有自己的软件环境，相互独立。

​ K8S与Docker之间的关系，如同Openstack之于KVM、VSphere之于VMWARE。K8S是容器集群管理系统，底层容器虚拟化可使用Docker技术，应用人员无需与底层Docker节点直接打交道，通过K8S统筹管理即可。



