---
layout: "post"
title: "Kubernetes"
date: "2019-06-01 12:38"
categories: devops
tags: [k8s]
---

## 简介

- [Helm](https://github.com/helm/helm) 
    - 是 Kubernetes 上的包管理器
    - Helm组成：`Helm`客户端、`Tiller`服务器、`Charts`仓库
    - 原理：Helm客户端从远程Charts仓库(Repository)拉取Chart(应用程序配置模板)，并添加Chart安装运行时所需要的Config(配置信息)，然后将此Chart和Config提交到Tiller服务器，Tiller服务器则在k8s生成`Release`，并完成部署
- [官方Charts仓库](https://hub.helm.sh/)

## 安装Helm客户端及服务

- 安装Helm客户端

    ```bash
    # 下载helm命令行工具到master节点
    curl -O https://get.helm.sh/helm-v2.14.2-linux-amd64.tar.gz
    tar -zxvf helm-v2.14.2-linux-amd64.tar.gz
    cd linux-amd64/
    cp helm /usr/local/bin/
    # 查看帮助
    helm
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
    helm version # 显示 Client 和 Server 均正常

    # (可选)查看并修改远程仓库地址
    helm repo list
    helm repo add stable http://mirror.azure.cn/kubernetes/charts

    # 卸载tiller
    heml reset
    ```

## Helm命令 [^2]

```bash
# helm
completion  # 为指定的shell生成自动补全脚本（bash或zsh）
create      # 创建一个新的charts
delete      # 删除指定版本的release
    # helm delete --purge my-dev # 删除 release，也会删除相应k8s资源
dependency  # 管理charts的依赖
fetch       # 下载charts并解压到本地目录
get         # 下载一个release
history     # release历史信息
home        # 显示helm的家目录
init        # 在客户端和服务端初始化helm
inspect     # 查看charts的详细信息
    # helm inspect values stable/mysql # 查看此chart说明信息
install     # 安装charts
    # helm install stable/nginx
    # helm install ./nginx-1.2.3.tgz
    # helm install ./nginx
    # helm install https://example.com/charts/nginx-1.2.3.tgz
lint        # 检测包的存在问题
list        # 列出release
    # helm list --all
package     # 将chart目录进行打包
plugin      # add(增加), list（列出）, or remove（移除） Helm 插件
repo        # add(增加), list（列出）, remove（移除）, update（更新）, and index（索引） chart仓库
    # helm repo add stable http://mirror.azure.cn/kubernetes/charts # 替换原有 stable
    # helm repo add fabric8 https://fabric8.io/helm
reset       # 卸载tiller
rollback    # release版本回滚
search      # 关键字搜索chart。eg: helm search mysql
serve       # 启动一个本地的http server用于展示本地charts和提供下载
    # helm serve --address=192.168.6.131:8879
status      # 查看release状态信息
template    # 本地模板
test        # release测试
upgrade     # release更新
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
        # 基于某个 values 文件进行安装
        helm install stable/mysql -f myvalues.yaml
        helm install --values=myvalues.yaml stable/mysql
        ```

### 使用案例(mysql安装)

```bash
## 准备
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

## Chart说明 [^1]

- 安装某个 Chart 后，可在 `~/.helm/cache/archive` 中找到 Chart 的 tar 包，可解压查看 Chart 文件信息
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
    │   ├── ingress.yaml                # kubernetes Ingress
    │   ├── NOTES.txt
    │   ├── service.yaml                # kubernetes Serivce
    │   └── tests
    │       └── test-connection.yaml
    └── values.yaml                     # kubernetes object configuration
    ```
    - 比如在`deployment.yaml`中定义的容器镜像`image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"`，其中`.Values`代表后面属性获取`values.yaml`文件中的数据，如`.Values.image.repository`就是`nginx`，`.Values.image.tag`就是`stable`
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



---

参考文章

[^1]: https://jimmysong.io/kubernetes-handbook/practice/helm.html
[^2]: https://www.cnblogs.com/linuxk/p/10607805.html

