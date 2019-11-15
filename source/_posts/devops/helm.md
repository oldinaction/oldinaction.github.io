---
layout: "post"
title: "Helm | K8s包管理器"
date: "2019-06-22 12:38"
categories: devops
tags: [k8s]
---

## 简介

- [Helm](https://github.com/helm/helm) 、[Helm Docs](https://helm.sh/docs/)
    - 是 Kubernetes 上的包管理器
    - Helm组成：`Helm`客户端、`Tiller`服务器、`Charts`仓库
    - 原理：Helm客户端从远程Charts仓库(Repository)拉取Chart(应用程序配置模板)，并添加Chart安装运行时所需要的Config(配置信息)，然后将此Chart和Config提交到Tiller服务器，Tiller服务器则在k8s生成`Release`，并完成部署
- [官方Charts仓库](https://github.com/helm/charts)、[官方Charts仓库展示](https://hub.helm.sh/)、[Kubeapps Charts仓库(速度较快)](https://hub.kubeapps.com/charts)

## 安装Helm客户端及服务

- 安装Helm客户端

    ```bash
    # 下载helm命令行工具到master节点
    curl -O https://get.helm.sh/helm-v2.14.2-linux-amd64.tar.gz
    tar -zxvf helm-v2.14.2-linux-amd64.tar.gz
    mv linux-amd64/helm /usr/local/bin/
    # 查看帮助
    helm
    rm -rf linux-amd64 # 删除下载文件
    ```
- 安装Tiller服务器(安装在k8s集群中) [^1]

    ```bash
    # 为了安装服务端tiller，还需要在这台机器上配置好kubectl工具和kubeconfig文件，确保kubectl工具可以在这台机器上访问apiserver且正常使用。一般安装在master
    # 因为Kubernetes APIServer开启了RBAC访问控制，所以需要创建tiller使用的`service account: tiller`，并分配合适的角色给它
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    # 使用helm部署tiller。-i指定自己的镜像，因为官方的镜像因为某些原因无法拉取，官方镜像地址是：gcr.io/kubernetes-helm/tiller:v2.14.2
    helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.14.2 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
    # 为应用程序设置serviceAccount
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    # 检查是否安装成功
    kubectl -n kube-system get pods|grep tiller
    # 显示版本即表示 Client 和 Server 均正常
    helm version
    # (可选)查看并修改远程仓库地址。上文默认使用了阿里的镜像
    helm repo add stable http://mirror.azure.cn/kubernetes/charts
    helm repo update
    helm repo list

    # 卸载tiller
    heml reset
    ```

## Helm命令 [^2]

```bash
# helm
completion  # 为指定的shell生成自动补全脚本（bash或zsh）
create      # 创建一个新的charts
delete      # 删除指定版本的release
    # helm delete --purge my-dev # **删除 release，也会删除相应k8s资源**
dependency  # 管理charts的依赖
fetch       # 下载charts到当前目录
get         # 下载一个release
history     # release历史信息
home        # 显示helm的家目录
init        # 在客户端和服务端初始化helm
inspect     # 查看charts的详细配置信息(values.yaml)
    # helm inspect stable/nginx-ingress # 查看此chart说明信息
    # helm inspect values stable/nginx-ingress # 查看此chart的values.yaml信息
install     # 安装charts
    # helm install stable/nginx
    # helm install ./nginx-1.2.3.tgz
    # helm install ./nginx
    # helm install https://example.com/charts/nginx-1.2.3.tgz
    # helm install --dry-run --debug mychart # **模拟执行**
lint        # 检测包的存在问题
list        # 列出release(结果中CHART字段一般带了CHART的版本，APP VERSION则为相关镜像如nginx-ingress版本)
    # helm list --all
package     # 将chart目录进行打包
plugin      # add(增加), list（列出）, or remove（移除） Helm 插件
repo        # add(增加), list（列出）, remove（移除）, update（更新）, and index（索引） chart仓库
    # helm repo add stable http://mirror.azure.cn/kubernetes/charts # 替换原有 stable(使用微软镜像，阿里镜像有中断更新)
    # helm repo add incubator http://mirror.azure.cn/kubernetes/charts-incubator/
    # helm repo add fabric8 https://fabric8.io/helm
reset       # 卸载tiller
rollback    # release版本回滚
search      # 关键字搜索chart。eg: helm search mysql
serve       # 启动一个本地的http server用于展示本地charts和提供下载
    # helm serve --address=192.168.6.131:8879
status      # 查看release状态信息
    # helm status grafana # 安装完chart也会自动执行一次
template    # 本地模板
test        # release测试
upgrade     # 更新release
            # **如nginx示例**
                # 初始化时会自动创建一个 Deployment、ReplicaSet、Pod、Service
                # 每次更新仅会产生一个新的ReplicaSet，而后此ReplicaSet会创建一个新的Pod，如果使用RollingUpdate滚动更新模式，在新Pod进入到readiness就绪状态之前，仍然由旧Pod提供服务，当新Pod就绪后，则移除旧Pod
                # 对于旧的ReplicaSet是不会删除的，当系统自动移除旧Pod后，哪些旧的ReplicaSet控制的容器组就为0/0，并且也不会还原旧的Pod
verify      # 验证chart的签名和有效期
version     # 打印客户端和服务端的版本信息
```
- Helm传递参数
    - 通过 `--set` 直接传入参数值，如：`helm install stable/mysql --set mysqlRootPassword=Hello1234! -n my-dev`
    - 生成自定义 values 文件

        ```bash
        # 生成 values 文件
        helm inspect values stable/mysql > myvalues.yaml
        # 修改参数值
        vi myvalues.yaml
        # 基于某个 values 文件进行安装，此文件和默认文件会进行值合并覆盖
        helm install stable/mysql -f myvalues.yaml
        helm install --values=myvalues.yaml stable/mysql
        ```

## 使用案例

### MySQL

> https://hub.kubeapps.com/charts/stable/mysql

```bash
cat > mysql-values.yaml << 'EOF'
persistence:
  storageClass: 'nfs-client'
timezone: Asia/Shanghai
# 需要登录到服务器手动给此用户设置权限
mysqlUser: devops
mysqlPassword: devops1234!
# 此时k8s看到的是Init1234!的密码，但是实际是被下文init.sql中修改后的密码
# mysqlRootPassword: Init1234!
service:
  type: NodePort
  nodePort: 30000
configurationFiles:
  mysql_custom.cnf: |-
    [mysqld]
    skip-host-cache
    skip-name-resolve
    symbolic-links=0
    lower_case_table_names=1
    character-set-server=utf8mb4
    collation-server=utf8mb4_bin
    init-connect='SET NAMES utf8mb4'
    max_allowed_packet=1000M
initializationFiles:
  init.sql: |-
    use mysql;
    grant all privileges on *.* to 'root'@'%' identified by 'Hello1234!' with grant option;
    flush privileges;
EOF
helm install --name mysql-devops --namespace devops stable/mysql --version 1.4.0 -f mysql-values.yaml

# 更新报错
helm upgrade mysql-devops stable/mysql --version 1.4.0 -f mysql-values.yaml
helm del --purge mysql-devops
```

#### 练手Helm

```bash
## 准备
helm repo update
# 查询 mysql 对应 Charts
helm search mysql
# 查看charts的详细信息
helm inspect values stable/mysql
# 创建PV. chart 定义了一个 PersistentVolumeClaim，申请 8G 的 PersistentVolume。如果不支持动态供给，可预先创建好相应的 PV。配置文件 mysql-pv.yaml 见下文
kubectl create -f mysql-pv.yaml

## 安装
# 基于Charts安装k8s pods等。回显中说明如下
    # NAME：release 的名字，此时为 -n 参数指定，否则 Helm 随机生成一个
    # NAMESPACE：release 部署的 namespace(k8s的namespace)，**默认是 default，也可以通过 --namespace 指定**
    # STATUS：为 DEPLOYED 时，表示已经将 chart 部署到集群
    # RESOURCES：当前 release 包含的资源，命名的格式为 ReleasName-ChartName
    # NOTES：部分显示的是 release 的使用方法
helm install stable/mysql -n my-dev --version 1.3.0 --set mysqlRootPassword=Hello1234!
# 查看mysql信息资源信息(ReleasName-ChartName)，如下(此时可能没有PV导致pod处于Pending状态)
kubectl get service my-dev-mysql
kubectl get deployment my-dev-mysql
kubectl get pvc my-dev-mysql
# 查看root密码
kubectl get secret --namespace default my-dev-mysql -o jsonpath="{.data.mysql-root-password}" | base64 --decode; echo
# 显示已经部署的 release
helm list --all

## 删除 release，也会删除相应k8s资源
helm delete --purge my-dev

## 升级和回滚release
# 通过 --values 或 --set 应用新的配置
helm upgrade --set imageTag=5.7.15 my-dev stable/mysql
helm upgrade --set mysqlRootPassword=Hello1234! my-dev stable/mysql
# 查看 release 所有的版本
helm history my-dev
# 回滚到任何版本
helm rollback my-dev 1
```
- mysql-pv.yaml

```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv1
  labels:
    name: mysql-pv1
spec:
  nfs:
    server: 192.168.6.10
    path: /data/volumes/v1
  accessModes: ["ReadWriteOnce"]
  capacity:
    storage: 8Gi
  persistentVolumeReclaimPolicy: Retain
```

### cert-manager

```bash
## 安装
# 0.5.2安装成功后一直无法自动创建secret
# 0.6.7需要提前创建自定义资源，且在创建ClusterIssuer时还会报错 `Error creating ClusterIssuer: the server is currently unable to handle the request`
helm repo add jetstack https://charts.jetstack.io
helm repo update
# 创建自定义资源(issuer、clusterissuer、certificate等)
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
kubectl get crd # 查看Cert manager还提供的一些Kubernetes custom resources
# 且配置一个缺省的cluster issuer，当部署Cert manager的时候，用于支持 `kubernetes.io/tls-acme: "true"` 的 annotation 来自动化 TLS
helm install --name cert-manager --namespace kube-system --set ingressShim.defaultIssuerName=letsencrypt-staging --set ingressShim.defaultIssuerKind=ClusterIssuer jetstack/cert-manager --version v0.9.0
# 标记cert-Manager命名空间以禁用资源验证
kubectl label namespace kube-system certmanager.k8s.io/disable-validation=true
# 查看
kubectl get pod -n kube-system --selector=app=cert-manager

## 创建证书签发机构。cert-manager 提供了 Issuer 和 ClusterIssuer 这两种用于创建签发机构的自定义资源对象，Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书
# 创建 letsencrypt-staging(测试) 、letsencrypt-prod(正式，有频率限制，https://letsencrypt.org/docs/rate-limits/) 签发机构。必须修改里面的邮箱
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/docs/tutorials/acme/quick-start/example/staging-issuer.yaml
# 自定义此 Issuer 对应的命名空间
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/docs/tutorials/acme/quick-start/example/production-issuer.yaml --namespace=aezocn-prod
# 或者如下述文件进行创建
#vi cluster-issuer.yaml
#kubectl create -f cluster-issuer.yaml
kubectl get <issuer | clusterissuer>

## 测试
# 在ingress配置的annotation上加 `kubernetes.io/tls-acme: "true"`，则会自动创建 ingress.tls.secretName 对应的证书，且将此证书生成到secret中
kubectl get certificate -o wide -n kube-system #  Certificate 为cert-manager自定义资源对象
kubectl get secret -n kube-system

## 卸载
helm del --purge cert-manager
# 上述删除不会删除自定义资源，需手动删除。否则再次安装报错：Error: customresourcedefinitions.apiextensions.k8s.io "certificates.certmanager.k8s.io" already exists
kubectl delete -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
# 删除对应的issuer，kubectl get <issuer | clusterissuer>

## 常见问题
# 查看cert-manager容器日志，提示`server misbehaving`，通过busybox测试pod发现容器无法访问外网
# 提示`dial tcp: lookup dashboard.k8s.aezo on 10.96.0.10:53: no such host`，将自定义域名的解析加入到corndns对应的configmap
```

- cluster-issuer.yaml

```yml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  # 签发机构的名称，创建证书的时候会引用它
  name: letsencrypt-staging
  #namespace: default # 上面kind为Issuer时可定义
spec:
  # 使用acme协议。acme 协议的目的是证明这台机器和域名都是属于你的，然后才准许给你颁发证书
  acme:
    # acme 协议的服务端，这里用 Let’s Encrypt
    server: https://acme-staging-v02.api.letsencrypt.org/directory # letsencrypt-prod 对应的服务地址为 https://acme-v02.api.letsencrypt.org/directory
    # 证书快过期的时候会有邮件提醒。不过 cert-manager 会利用 acme 协议自动重新颁发证书来续期
    email: admin@aezo.cn
    privateKeySecretRef:
      # 指示此签发机构的私钥将要存储到哪个 Secret 对象中
      name: letsencrypt-staging
    # 指示签发机构使用 HTTP-01 的方式进行 acme 协议(还可以用 DNS 方式)
    http01: {}
```
- Certificate自定义资源对象参数说明
```bash
spec.secretName # 指示证书最终存到哪个 Secret 中
spec.issuerRef.kind # 值为 ClusterIssuer 说明签发机构不在本 namespace 下，而是在全局
spec.issuerRef.name # 我们创建的签发机构的名称 (ClusterIssuer.metadata.name)
spec.dnsNames # 指示该证书的可以用于哪些域名
spec.acme.config.http01.ingressClass # 使用 HTTP-01 方式校验该域名和机器时，cert-manager 会尝试创建Ingress 对象来实现该校验，如果指定该值，会给创建的 Ingress 加上 kubernetes.io/ingress.class 这个 annotation，如果我们的 Ingress Controller 是 Nginx Ingress Controller，指定这个字段可以让创建的 Ingress 被 Nginx Ingress Controller 处理。
spec.acme.config.http01.domains # 指示该证书的可以用于哪些域名
```

### ingress-nginx

```bash
helm repo update
# https://kubernetes.github.io/ingress-nginx
helm inspect values stable/nginx-ingress --version 1.15.1
# (可选，如有单独的机器作为边缘节点) 选择边缘节点，并打上自定义标签(node-role.kubernetes.io/edge='')
kubectl label node node1 node-role.kubernetes.io/edge=
# 修改参数启用RBAC. 否则报错：`User "system:serviceaccount:ingress-nginx:default" cannot get resource "services"`
cat > ingress-nginx.yaml << EOF
controller:
  replicaCount: 1
  # 使用VIP地址达到负载均衡的效果?
  #service:
  #  externalIPs:
  #  - 192.168.6.129
  # 临时可使用宿主机网络测试
  hostNetwork: true
  # 取消HSTS配置
  config:
    hsts: "false"
  # 选择含边缘标签的节点(上文有边缘节点才需要)
  nodeSelector:
    node-role.kubernetes.io/edge: ''
defaultBackend:
  nodeSelector:
    node-role.kubernetes.io/edge: ''
defaultBackend:
  image:
    repository: registry.aliyuncs.com/google_containers/defaultbackend
    tag: 1.3
## Enable RBAC
rbac:
  create: true
EOF
# 安装
helm install stable/nginx-ingress --version 1.15.1 -n nginx-ingress --namespace ingress-nginx -f ingress-nginx.yaml
kubectl get pod -n ingress-nginx -o wide
# 访问 curl https://192.168.6.131/ ，显示 `default backend - 404`/`404 page not found` 则正常

# 更新部署的release
# 修改配置文件后执行
helm upgrade nginx-ingress stable/nginx-ingress --version 1.15.1 -f ingress-nginx.yaml
```

### Dashboard

```bash
## 提前创建tls类型的secret，名称为k8s-aezo-cn-tls。否则无法访问，会显示`default backend - 404`。下文 kubernetes-dashboard.yaml 配置中使用 certmanager 自动创建证书
# 手动创建证书
#openssl genrsa -out aezocn.key 2048
#openssl req -new -x509 -key aezocn.key -out aezocn.crt -subj /C=CN/ST=Beijing/L=Beijing/O=DevOps/CN=k8s.aezo.cn # 此处CN=k8s.aezo.cn一定要对应
#kubectl create secret tls k8s-aezo-cn-tls --cert=aezocn.crt --key=aezocn.key

## 如下文创建配置文件
vi kubernetes-dashboard.yaml
## 安装
helm repo update
helm install stable/kubernetes-dashboard --version 1.8.0 -n kubernetes-dashboard --namespace kube-system -f kubernetes-dashboard.yaml

## 查看状态和登录token
kubectl -n kube-system get pods
kubectl get secret $(kubectl get secret -n kube-system|grep kubernetes-dashboard-token|awk '{print $1}') -n kube-system -o jsonpath={.data.token}|base64 -d |xargs echo

## 更新删除
helm upgrade kubernetes-dashboard stable/kubernetes-dashboard --version 1.8.0 -f kubernetes-dashboard.yaml
helm del --purge kubernetes-dashboard

## 其他
# 修改token过期时间(session过期时间)，默认是15分钟(900秒)：在 `- --auto-generate-certificates` 下加一行参数 `- --token-ttl=31536000‬` (1年有效)
kubectl edit deployment kubernetes-dashboard -n kube-system
# 创建只能访问某命名空间的sa账户参考[kubernetes](/_posts/devops/kubernetes.md)
```
- kubernetes-dashboard.yaml

```yml
image:
  repository: registry.aliyuncs.com/google_containers/kubernetes-dashboard-amd64 
  tag: v1.10.1
ingress:
  enabled: true
  annotations:
    # 是否强制跳转https
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # 如kubernetes-dashboard需要实现tls访问，则需要加入此注解。否则提示"无法访问此网页"，且ingress-nginx容器日志报错"ingress dashboard upstream sent no valid HTTP/1.0 header while reading response header from upstream". 
        # This annotation was deprecated in 0.18.0 and removed after the release of 0.20.0，之前为 `nginx.ingress.kubernetes.io/secure-backends: "true"`
        # 参考：http://bbs.bugcode.cn/t/18544 、https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#backend-protocol
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    # certmanager 对应的 cluster-issuer
    certmanager.k8s.io/cluster-issuer: letsencrypt-staging
    # 加上此注解cert-manager会自动生成k8s-aezo-cn-tls对应的证书和secret。如果未安装cert-manager，则需要提前手动创建好证书和secret。如果无证书则使用默认证书
    kubernetes.io/tls-acme: "true"
  hosts: 
  - k8s.aezo.cn
  tls:
  - hosts:
    - k8s.aezo.cn
    secretName: k8s-aezo-cn-tls
# 选择运行在master节点上
nodeSelector:
  node-role.kubernetes.io/master: ''
tolerations:
- key: node-role.kubernetes.io/master
  operator: Exists
  effect: NoSchedule
- key: node-role.kubernetes.io/master
  operator: Exists
  effect: PreferNoSchedule
rbac:
  clusterAdminRole: true
```

### nfs-client-provisioner

> https://hub.kubeapps.com/charts/stable/nfs-client-provisioner

- nfs默认无法自动申请PV；在对应命名空间安装nfs-client-provisioner，则会自动申请并创建PV
- nfs服务器设置如`rw,sync,no_subtree_check,no_root_squash`，如果不设置成no_root_squash会导致像基于Chart安装mysql会失败(无法修改文件所属者)

```bash
## 安装
helm install --name nfs-client-provisioner --namespace test stable/nfs-client-provisioner --version=1.2.6 \
--set image.repository=quay.mirrors.ustc.edu.cn/external_storage/nfs-client-provisioner \
--set nfs.server=192.168.6.130 \
--set nfs.path=/home/data/nfs 
# --set storageClass.reclaimPolicy=Retain
# 安装成功后，会创建StorageClass为nfs-client

# helm upgrade nfs-client-provisioner stable/nfs-client-provisioner --version=1.2.6
helm del --purge nfs-client-provisioner

## 使用
# 在PVC中定义 storageClassName 为 nfs-client，则会自动申请并创建PV
# 会在NFS服务器对应目录生成 `${namespace}-${pvcName}-${pvName}`的子目录；如果该PV解绑了，则改目录会重命名为 `archived-${namespace}-${pvcName}-${pvName}`
```

### Prometheus

> 参考：https://hub.kubeapps.com/charts/stable/prometheus

```bash
helm repo update
# helm inspect values stable/prometheus --version 9.0.0
# helm fetch stable/prometheus --version 9.0.0 && tar -zxvf prometheus-9.0.0.tgz

cat > prometheus-values.yaml << 'EOF'
server:
  persistentVolume:
    # 如通过rook创建的sc，会自动创建pvc和pv
    storageClass: "monitoring-sc-01"
  ingress:
    enabled: true
    hosts:
    - prometheus.k8s.aezo.cn
pushgateway:
  persistentVolume:
    enabled: true
    storageClass: "monitoring-sc-01"
  # ingress: # 将pushgateway暴露出去
# 扩展监控的node_export。如果使用 serverFiles.prometheus.yml.scrape_configs 参数则会覆盖value.yaml所有的scrape_configs
# extraScrapeConfigs后面必须跟字符串，此处必须使用 | 进行转换；且此时`- job_name`前必须保留2个空格
extraScrapeConfigs: |
  - job_name: 'node-test'
    # metrics_path: /metrics
    scrape_interval: 5s
    static_configs:
    - targets: ['192.168.6.130:9100']
alertmanager:
  persistentVolume:
    storageClass: "monitoring-sc-01"
alertmanagerFiles:
  alertmanager.yml:
    global:
      resolve_timeout: 5m
      smtp_smarthost: 'smtp.163.com:25'
      smtp_from: 'aezocn@163.com'
      smtp_auth_username: 'aezocn@163.com'
      smtp_auth_password: 'XXX'
    route:
      receiver: 'email-receiver'
      group_wait: 30s
      group_interval: 1m
      repeat_interval: 60m
      routes:
      - match:
          severity: critical
        receiver: email-receiver
    receivers:
    - name: 'email-receiver'
      email_configs:
      - to: 'aezocn@163.com'
    - name: 'slack-receiver'
      slack_configs:
      - send_resolved: true
        api_url: https://hooks.slack.com/services/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
        channel: 'monitor'
        text: "{{ .CommonAnnotations.description }}"
serverFiles:
  # 常用报警规则，可选
  alerts:
    groups:
    - name: NodeAlerts
      rules:
      - alert: 节点CPU使用率告警
        expr: (100 - avg (irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100) > 85
        for: 2m
        labels:
          severity: critical
        annotations:
          description: '详细信息：{{$labels.instance}} 在 2 分钟内，CPU使用率一直超过 85% (当前值为: {{ $value }})'
          summary: '{{$labels.instance}}: CPU使用过高'
      - alert: 节点内存使用率告警
        expr: (node_memory_MemTotal_bytes - (node_memory_MemFree_bytes+node_memory_Buffers_bytes+node_memory_Cached_bytes )) / node_memory_MemTotal_bytes * 100 > 90
        for: 2m
        labels:
          severity: critical
        annotations:
          description: '详细信息：{{$labels.instance}} 在 2 分钟内，内存使用率一直超过 90% (当前值为: {{ $value }})'
          summary: '{{$labels.instance}}: 内存使用过高'
      - alert: 节点磁盘空间告警
        expr: ((node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100) > 85
        for: 1m
        labels:
          severity: critical
        annotations:
          description: '详细信息：{{$labels.instance}} 磁盘 {{ $labels.device }} 使用率超过 85% (当前值为: {{ $value }})'
          summary: '{{$labels.instance}}: 磁盘空间不足'
      - alert: NodeExport运行状态告警
        expr: up{job="my-job"} != 1
        for: 5m
        labels:
          severity: critical
        annotations:
          description: '详细信息：{{$labels.instance}} 在 5 分钟内, NodeExport未正常运行'
          summary: '{{$labels.instance}}: NodeExport运行异常'
EOF
helm install --name prometheus --namespace monitoring stable/prometheus --version 9.0.0 -f prometheus-values.yaml

helm upgrade prometheus stable/prometheus --version 9.0.0 -f prometheus-values.yaml
helm del --purge prometheus

# k8s内部server地址(Grafana添加数据源需要)：prometheus-server.monitoring.svc.cluster.local
# k8s内部重新创建 prometheus-server-pod 绑定的 PV 并不会丢失
```

### Grafana

> 参考：https://hub.kubeapps.com/charts/stable/grafana

- 安装

```bash
# kubectl create secret generic grafana-secret -n monitoring --from-literal=admin-user=admin --from-literal=admin-password=Hello1234
cat > grafana-values.yaml << 'EOF'
#admin:
#  existingSecret: "" # 可自定义admin Secret(参考上文)。默认会自动生成名为grafana的Secret(包含admin账号和密码)
#  userKey: 'admin-user' # 指定admin Secret(map)文件中获取admin账号对应的key，默认key为admin-user。passwordKey同理
persistence:
  enabled: true
  type: 'pvc'
  storageClassName: 'nfs-client'
# tls类型连接测试未成功
ingress:
  enabled: true
  hosts:
  - grafana.k8s.aezo.cn
# https://grafana.com/docs/installation/configuration/
grafana.ini:
  smtp:
    enabled: true
    host: "smtp.gmail.com:587"
    user: "test@gmail.com"
    password: "pass"
# 使用NFS存储时，初始化容器chown运行出错，此处禁用初始化过程。另可参考：https://github.com/helm/charts/issues/1071
initChownData:
  enabled: false
EOF
helm install --name grafana --namespace monitoring stable/grafana --version 3.10.2 -f grafana-values.yaml
helm upgrade grafana stable/grafana --version 3.10.2 -f grafana-values.yaml
helm del --purge grafana
```
- 使用
    - 增加数据源，数据源地址如`http://prometheus-server.monitoring.svc.cluster.local`
    - 具体参考[Grafana](/_posts/devops/prometheus.md#Grafana)

### Postgresql

> https://hub.kubeapps.com/charts/stable/postgresql

```bash
cat > postgresql-values.yaml << 'EOF'
global:
  postgresql:
    # postgres 账户密码
    postgresqlPassword: Hello1234!
persistence:
  storageClass: 'nfs-client'
service:
  type: NodePort
  nodePort: 30004
EOF
helm install --name postgresql-devops --namespace devops stable/postgresql --version=6.5.3 -f postgresql-values.yaml

helm upgrade postgresql-devops stable/postgresql --version=6.5.3 -f postgresql-values.yaml
helm del --purge postgresql-devops
```

### Redis

> https://hub.kubeapps.com/charts/stable/redis

```bash
cat > redis-values.yaml << 'EOF'
password: Hello1234!
master:
  persistence:
    storageClass: 'nfs-client'
  service:
    type: NodePort
    nodePort: 30002
slave:
  persistence:
    storageClass: 'nfs-client'
  service:
    type: NodePort
    nodePort: 30003
EOF
helm install --name redis-devops --namespace devops stable/redis --version=9.5.0 -f redis-values.yaml

helm upgrade redis-devops stable/redis --version=9.5.0 -f redis-values.yaml
helm del --purge redis-devops
```

### Harbor

> https://hub.kubeapps.com/charts/harbor/harbor 、 https://www.qikqiak.com/post/harbor-quick-install/

```bash
## 安装
helm repo add harbor https://helm.goharbor.io

cat > harbor-values.yaml << 'EOF'
expose:
  type: ingress
  tls:
    enabled: true
  ingress:
    hosts:
      core: registry.harbor.k8s.aezo.cn
      notary: notary.harbor.k8s.aezo.cn
    annotations:
      kubernetes.io/ingress.class: "nginx"
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      # certmanager自动证书
      certmanager.k8s.io/cluster-issuer: letsencrypt-staging
      kubernetes.io/tls-acme: "true"
externalURL: https://registry.harbor.k8s.aezo.cn
# 用户名默认为 admin
harborAdminPassword: Hello1234
# 使用外部mysql数据库(需提前创建数据库，见下文sql语句)
database:
  type: external
  external:
    host: postgresql-devops
    port: 5432
    username: postgres
    password: Hello1234!
    coreDatabase: harbor_registry
    clairDatabase: harbor_clair
    notaryServerDatabase: harbor_notary_server
    notarySignerDatabase: harbor_notary_signer
# 使用外部redis数据库(默认使用0-3下标的数据库)
redis:
  type: external
  external: 
    host: redis-devops-master
    port: 6379
    password: Hello1234!
persistence:
  enabled: true
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      storageClass: "nfs-client"
    chartmuseum:
      storageClass: "nfs-client"
    jobservice:
      storageClass: "nfs-client"
    database:
      storageClass: "nfs-client"
EOF
# 大概需要3分钟所有的Pod才会全部运行正常
helm install --name harbor --namespace devops harbor/harbor --version=1.2.1 -f harbor-values.yaml
# 访问 https://registry.harbor.k8s.aezo.cn

helm upgrade harbor harbor/harbor --version=1.2.1 -f harbor-values.yaml
helm del --purge harbor
# 然后删除对应的PVC(会顺带自动删除PV，但是对于实际的存储文件需要到存储服务中删除)，否则下次安装会提示存储对应PVC
```
- 数据库初始化语句如

```sql
create database harbor_registry;
create database harbor_clair;
create database harbor_notary_server;
create database harbor_notary_signer;
```

### Jenkins

> https://hub.kubeapps.com/charts/stable/jenkins

```bash
## 安装
cat > jenkins-values.yaml << 'EOF'
master:
  adminUser: admin
  adminPassword: Hello1234
  ingress:
    enabled: true
    hostName: jenkins.k8s.aezo.cn
  # installPlugins: [] # 设置默认安装的插件，如果为[]则一个插件都不会安装
persistence:
  enabled: true
  storageClass: 'nfs-client'
EOF
helm install --name jenkins --namespace devops stable/jenkins --version=1.7.8 -f jenkins-values.yaml

helm upgrade jenkins stable/jenkins --version=1.7.8 -f jenkins-values.yaml
helm del --purge jenkins
```

## Chart说明 [^1]

- 安装某个 Chart 后，可在 `~/.helm/cache/archive` 中找到 Chart 的 tar 包，可解压查看 Chart 文件信息(`tar -zxvf nginx-ingress-0.9.5.tgz`)
- 创建 Chart 案例

    ```bash
    # 创建名为 mychart 的 Chart. 此时会创建一个包含nginx相关配置的的模板包
    helm create mychart
    # tree mychart
    # 检测 chart 的语法
    helm lint mychart
    # 模拟安装 chart，并输出每个模板生成的 YAML 内容(--dry-run 实际没有部署到k8s)
    helm install --dry-run --debug mychart
    # 部署到k8s
    helm install mychart -n test-chart
    
    # 测试
    export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=mychart,app.kubernetes.io/instance=test-chart" -o jsonpath="{.items[0].metadata.name}")
    kubectl port-forward --address 0.0.0.0 $POD_NAME 8080:80
    # 在本地访问http://127.0.0.1:8080即可访问到nginx

    # 修改配置文件(也可同时配合--set修改配置)后更新部署。如果直接修改value.yaml里面的image.tag提交更新后k8s无反应
    # 此处image.tag不能使用过长的数字(yyyyMMddHHmmss生成的数字)，过长传递到k8s则变成了科学计数导致出错
    helm upgrade --set image.tag=20190902 mychart ./mychart
    helm history mychart # 查看更新历史
    ```
- `tree mychart` 显示目录信息如下

    ```bash
    # 其中 Chart.yaml 和 values.yaml 必须，其他可选
    mychart
    ├── charts                          # 依赖的chart
    ├── requirements.yaml               # 该chart的依赖配置(create创建的无此文件)
    ├── Chart.yaml                      # Chart本身的版本和配置信息
    ├── templates                       # 配置模板目录，下是yaml文件的模板，遵循Go template语法
    │   ├── deployment.yaml             # kubernetes Deployment object
    │   ├── _helpers.tpl                # 用于修改kubernetes objcet配置的模板
    │   ├── ingress.yaml                # kubernetes Ingress(默认未启用)
    │   ├── NOTES.txt
    │   ├── service.yaml                # kubernetes Serivce
    │   └── tests
    │       └── test-connection.yaml
    └── values.yaml                     # kubernetes object configuration
    ```
    - 比如在`deployment.yaml`中定义的容器镜像
        
        ```bash
        # 其中`.Values`代表后面属性获取`values.yaml`文件中的数据，如`.Values.image.repository`就是`nginx`，`.Values.image.tag`就是`stable`
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ```
- 打包分享
    - chart 通过测试后可以将其添加到仓库，团队其他成员就能够使用。任何 HTTP Server 都可以用作 chart 仓库

    ```bash
    ## 在node2启动一个 HTTP Server，如果已有可忽略。此处node2服务地址为 http://192.168.6.132:8080/
    docker run -d -p 8080:80 -v /var/www/:/usr/local/apache2/htdocs/ httpd

    ## 在node1操作
    # 生成压缩包 mychart-0.1.0.tgz，并同步到 local 的仓库
    helm package mychart
    # 生成仓库的 index 文件
    mkdir myrepo
    mv mychart-0.1.0.tgz myrepo/
    # Helm 会扫描 myrepo 目录中的所有 tgz 包并生成 index.yaml
    helm repo index myrepo/ --url http://192.168.6.132:8080/charts
    cat myrepo/index.yaml
    # 需要提前在node2创建 /var/www/charts/
    scp myrepo/* root@node2:/var/www/charts/
    helm repo add newrepo http://192.168.6.132:8080/charts
    helm repo list
    helm search mychart
    # 如果以后仓库添加了新的 chart，需要用 helm repo update 更新本地的 index
    helm repo update
    ```
- chart语法参考[Go template语法](#Go%20template语法)
    - 参考文章[chart_template_guide](https://whmzsu.github.io/helm-doc-zh-cn/chart_template_guide/index-zh_cn.html)

## Go template语法

### 简介

- [Go template语法](https://golang.org/pkg/text/template/)
- 相关函数：https://blog.gmem.cc/gotpl

### 基本

- 基本

```go
{{/* comment */}}
{{- xxxx -}} // -去除前后的空白(包括换行符、制表符、空格等)，可只去其中一个
```
- 数据类型

```go
{{ $how_long := (len "output") }} // 定义变量
{{ println $how_long }} // 输出6

{{ $name := default .Chart.Name .Values.nameOverride }} // 赋值多个值，此时$name相当于一个数组
{{ if contains $name .Release.Name }} ... {{ end }} // $name为上文定义，判断$name中是否包含.Release.Name的值

{{.}} // 表示当前对象，如user对象
{{.Username}} // 表示对象的Username字段值
```

### 控制语句

- **if**

```go
{{if exp}} T1 {{end}}

{{if exp}} T1 {{else}} T0 {{end}}

// 控制语句块在渲染后生成模板会多出空行。可使用{{- if ...}}的方式消除此空行
{{- if and .Values.fooString (eq .Values.fooString "foo") }}
    {{ ... }}
{{- end }}
```
- **with**

```go
// 当exp不为0值时，点"."设置为exp运算的值，并执行T1；否则跳过
{{with exp}} T1 {{end}}
// {{with "xx"}}{{println .}}{{end}} // 打印"xx"(此时 . 设置成了 xx)

// 当exp不为0值时，则"."设置为exp运算的值，并执行T1；否则执行else语句块
{{with exp}} T1 {{else}} T0 {{end}}
```
- **range**

```go
// range循环来遍历map(将所有k-v依次展示)
{{ range $k, $v := .Map }}
    {{ $k }}:{{ $v }}
{{end}}

// grafana chart configmap.yaml示例
data:
    grafana.ini: |
{{- range $key, $value := index .Values "grafana.ini" }}
    [{{ $key }}]
    {{- range $elem, $elemVal := $value }}
    {{ $elem }} = {{ $elemVal }}
    {{- end }}
{{- end }}
`
# value.yaml中配置
grafana.ini:
  smtp:
    enabled: true
    host: "smtp.gmail.com:587"
    user: "test@gmail.com"
    password: "pass"
`
```
- **管道符 `|`** (类似unix)
```go
{{ .Values | quote }} // 等价于 `quote .Values`
{{ .Values | upper | quote }}
```

### 其他

- 模板嵌套

```go
{{define "module_name"}}content{{end}} //声明
{{template "module_name"}} //调用
```
- 内置函数




---

参考文章

[^1]: https://jimmysong.io/kubernetes-handbook/practice/helm.html
[^2]: https://www.cnblogs.com/linuxk/p/10607805.html
