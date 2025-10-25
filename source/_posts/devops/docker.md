---
layout: "post"
title: "Docker"
date: "2017-06-25 14:03"
categories: devops
tags: [docker, arch]
---

## 镜像

- 华为开源镜像站: https://mirrors.huaweicloud.com/
- 清华大学开源软件镜像站: https://mirror.tuna.tsinghua.edu.cn/

## Docker介绍

- 支持Linux、Windows、Mac等系统
- 传统虚拟化(虚拟机)是在硬件层面实现虚拟化，需要额外的虚拟机管理应用和虚拟机操作系统层。Docker容器是在操作系统层面实现虚拟化，直接复用本地本机的操作系统，因此更加轻量级。
- Docker镜像存在版本和仓库的概念，类似Git。docker官方仓库为[Docker Hub](https://hub.docker.com/)
- [官方文档](https://docs.docker.com)
- [在线docker测试地址](https://labs.play-with-docker.com/)
- docker基础镜像包含`alpine`(apk)、`centos`(yum)、`ubuntu`(apt-get)三种
- 本文基于docker版本`Server Version: 1.13.1`
- 国内镜像

```bash
## 设置镜像，docker-compose拉取镜像时可生效
vi /etc/docker/daemon.json # 加入下文配置 (windows在用户目录下.docker/daemon.json)
{"registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"]}
# 重启
sudo systemctl daemon-reload
sudo systemctl restart docker

## docker.io镜像加速。参考：https://juejin.im/post/5cd2cf01f265da0374189441
# 阿里云 registry.cn-hangzhou.aliyuncs.com 阿里云私有加速器(只有部分镜像) bzyep49h.mirror.aliyuncs.com
# 华为 swr.cn-north-4.myhuaweicloud.com
# 网易 hub-mirror.c.163.com
docker pull xxx:yyy "可替换为" docker pull registry.cn-hangzhou.aliyuncs.com/library/xxx:yyy
docker pull xxx/yyy:zz "可替换为" docker pull registry.cn-hangzhou.aliyuncs.com/xxx/yyy:zz
# Azure中国镜像 `dockerhub.azk8s.cn`

## gcr.io镜像加速
# 中科大 `gcr.mirrors.ustc.edu.cn`
docker pull gcr.io/xxx/yyy:zzz "可替换为" docker pull gcr.mirrors.ustc.edu.cn/xxx/yyy:zzz
# Azure中国镜像 `gcr.azk8s.cn`

## k8s.gcr.io镜像加速。k8s.gcr.io等价于gcr.io/google-containers
# 中科大 `gcr.mirrors.ustc.edu.cn/google-containers`
docker pull k8s.gcr.io/xxx:yyy "可替换为" docker pull gcr.mirrors.ustc.edu.cn/google-containers/xxx:yyy
# Azure中国镜像 `gcr.azk8s.cn/google-containers`
# 阿里云 `registry.aliyuncs.com/google_containers`

## quay.io镜像加速
# 中科大 `quay.mirrors.ustc.edu.cn`
# Azure中国镜像 `quay.azk8s.cn`
# 七牛镜像 `quay-mirror.qiniu.com`
docker pull quay.io/xxx/yyy:zzz "可替换为" docker pull quay.mirrors.ustc.edu.cn/xxx/yyy:zzz
```
- 目前docker必须登录才能拉取镜像
- 清理docker
    - mac本地测试环境想要完全重置docker虚拟磁盘文件，可删除 /Users/demo/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw (注意会删除所有数据；重新打开docker会自动构建此文件)

## 安装

- Windows
    - 方案一: **Windows 10直接使用Docker Desktop Installer安装包** https://hub.docker.com/editions/community/docker-ce-desktop-windows
        - 基于WSL实现，安装可能报错`wsl update failed: update failed: updating wsl`，由于执行了`wsl.exe --update`更新失败导致，重新启动几下触发wsl更新
        - 执行docker命令时提示`docker for windows could not read CA certificate`，解决https://blog.csdn.net/qq_35852248/article/details/80925154
        - 使用的网卡为`Hyper-V`，会导致VMware和DockerToolbox无法运行。可在控制面板 - 程序和功能 - 关闭windows的Hyper-V功能
        - Docker Desktop打不开问题: 基于 WSL 安装的一般会后台运行，此时需要先关闭后台才能成功打开
    - 方案二: 通过安装`DockerToolbox`，[安装文档和下载地址](https://docs.docker.com/toolbox/toolbox_install_windows/)
        - 安装完成后桌面快捷方式：`Docker Quickstart Terminal`、`kitematic`、`Oracle VM VirtualBox`
            - `Docker Quickstart Terminal` 可快速启动docker虚拟机，并进入到bash命令行
            - `kitematic`是docker推出的GUI界面工具(启动后，会后台运行docker，即自动运行docker虚拟机)
            - `Oracle VM VirtualBox`其实是一个虚拟机管理程序，**docker就运行在此default虚拟机上**
                - 下载的docker镜像在虚拟硬盘上，**default虚拟机内存默认是1G**，很容易内存溢出导致容器无法运行，可以在VirtualBox中进行调整
                - 虚拟机启动默认用户为 **`docker/tcuser`**，可通过`ssh docker@192.168.99.100`进入此虚拟机
        - 运行`Docker Quickstart Terminal`，提示找不到`bash.exe`，可以浏览选择git中包含的bash(或者右键修改此快捷方式启动参数。目标：`"D:\software\Git\bin\bash.exe" --login -i "D:\software\Docker Toolbox\start.sh"`)。第一次启动较慢，启动成功会显示docker的图标
        - 如果DockerToolbox运行出错`Looks like something went wrong in step ´Checking status on default..`，可以单独更新安装`VirtualBox`
        - xshell连接docker虚拟机：[http://blog.aezo.cn/2017/06/24/extend/vmware/](/posts/extend/vmware.md#Oracle-VM-VirtualBox)
    - 方案三: 安装[Boot2Docker](https://github.com/boot2docker/windows-installer)
    - 如果设置了C盘搬家到D盘，容易出现磁盘占满问题。可将虚拟机的disk.vmdk直接移动到D盘，步骤如下
        - 复制`C:\Users\smalle\.docker\machine\machines\default\disk.vmdk`到`D:/data/docker/disk.vmdk`
        - 进入VirtualBox(4.0.4以上)安装目录，执行`VBoxManage internalcommands sethduuid D:/data/docker/vdisk.vmdk`重设磁盘UUID
        - 打开VirtualBox，删除default原有的磁盘，然后添加新磁盘指向D:/data/docker/disk.vmdk
    - windows命令行运行docker命令提示无此命令，可将`D:\software\Docker Toolbox`加入到Path中
- linux

```bash
yum install docker # 安装

# 启动
systemctl start docker

# 数据文件默认保存在`/var/lib/docker`下，建议先进行修改，修改后此目录可不用保存
vi /etc/docker/daemon.json
{"registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"], "graph": "/data/docker", "dns" : ["114.114.114.114", "8.8.8.8"]}
# 重启
sudo systemctl daemon-reload && sudo systemctl restart docker
```
- ubuntu安装

```bash
sudo apt-get install docker.io
sudo gpasswd -a ${USER} docker # 把当前用户加入到docker组
cat /etc/group | grep ^docker # 查看是否添加成功
```

## 命令

### docker

```bash
docker   # docker 命令帮助

Management Commands:
  container   Manage containers
  image       Manage images     # 展示所有镜像
  network     Manage networks
    ls			# docker network ls # 列举网络(使用docker-compose启动，容器默认会加入到一个xxx_default的网络中)
	  rm			# sudo docker network rm my_net1 my_net2 # 移除网络
    connect		# docker network connect my_net my_new_app # 可将启动后的容器my_new_app手动加入到已存在的网络my_net中
  node        Manage Swarm nodes
  plugin      Manage plugins
  secret      Manage Docker secrets
  service     Manage services
  stack       Manage Docker stacks
  swarm       Manage Swarm
  system      Manage Docker
    prune # docker system prune # 清理资源：停止的容器、未被任何容器所使用的卷、未被任何容器所关联的网络、所有悬空镜像
    df # docker system df # 查看所占的硬盘大小
    info
    events
  volume      Manage volumes # 管理容器卷(可理解成就是一个目录)。https://docs.docker.com/storage/volumes/
    # volume绕过container的文件系统，直接将数据写到host机器上(默认存放路径 /var/lib/docker/volumes)
    # 修改默认存储位置，参考：https://blog.51cto.com/nanfeibobo/2091960
        # docker是1.12或以上的版本，可修改`vi /etc/docker/daemon.json`文件（如：`{"graph": "/data/docker"}`），会自动创建此目录，修改后会立即生效，不需重启docker服务。
    # 映射了容器卷之后，实际数据存放再docker默认存储位置下对应的容器卷名下，如：/data/docker/volumes/jenkins-data/_data (/data/docker为docker默认存储路径，jenkins-data为某一个容器卷名)
    create  # docker volume create my-vol # 创建数据卷
    ls      # docker volume ls # 列举数据卷
    rm      # docker volume rm my-vol # 移除数据卷

Commands:
    attach    Attach to a running container                 # 当前 shell 下 attach 连接指定运行镜像
    build     Build an image from a Dockerfile              # 通过 Dockerfile 定制镜像
        -t      # 定义标签(name:tag)，eg: -t demo:v1、-t demo(此时tag为latest)
        -f      # 指定 Dockerfile 文件路径。默认根目录下Dockerfile文件(此时可省略)
        --rm    # 编译成功后移除中间临时镜像
        --build-arg # 传递外部参数到Dockerfile中(使用ARG接受)
        # docker build --rm -t demo . # 根据当前目录(.)上下文环境编译
    commit    Create a new image from a container’s changes # 提交当前容器为新的镜像
    cp        Copy files/folders from the containers filesystem to the host path # 从容器中拷贝指定文件或者目录到宿主机中
        # docker cp demo.war sq-tomcat:/usr/local/tomcat/webapps    # 向sq-tomcat容器中部署war包
        # docker cp sq-tomcat:/usr/local/tomcat/webapps/demo.war .  # 从sq-tomcat容器中复制文件到宿主机
    create    Create a new container                        # 创建一个新的容器，同 run，但不启动容器
    diff      Inspect changes on a container’s filesystem   # 查看 docker 容器变化
    events    Get real time events from the server          # 从 docker 服务获取容器实时事件
    exec      Run a command in an existing container        # 在已存在的容器上运行命令
    export    Stream the contents of a container as a tar archive    # 导出容器的内容流作为一个 tar 归档文件[对应 import ]
    history   Show the history of an image                  # 展示一个镜像形成历史
        # docker history 5bb181d76b0d --no-trunc # 查看镜像构建历史，相当于Dockerfile步骤
    images    List images                                   # 列出系统当前镜像
    import    Create a new filesystem image from the contents of a tarball   # 从tar包中的内容创建一个新的文件系统映像[对应 export]
    info      Display system-wide information               # 显示系统相关信息
        # "Server Version" 即为docker版本信息
    inspect   Return low-level information on a container   # 查看容器详细信息
		# 下文查看 --format语法
        # docker inspect test:v1 # 查看镜像信息
    kill      Kill a running container                      # kill 指定 docker 容器
    load      Load an image from a tar archive              # 从一个 tar 包中加载一个镜像[对应 save]
    login     Register or Login to the docker registry server    # 注册或者登陆一个 docker 源服务器
    logout    Log out from a Docker registry server         # 从当前 Docker registry 退出
    logs      Fetch the logs of a container                 # 输出当前容器日志信息
        # 如容器异常退出可通过此命令查询，`docker logs <container_id | container_name>`
        # 或者`docker inspect <container_id | container_name>`获取 LogPath 位置。登录docker宿主机查了对应路径下的日志
		# 或者 docker start my_container sleep 1h # 表示让容器启动进入睡眠，然后exec进入容器查看原因
    port      Lookup the public-facing port which is NAT-ed to PRIVATE_PORT # 查看映射端口对应的容器内部源端口
    pause     Pause all processes within a container        # 暂停容器
    ps        List containers                               # 列出容器列表
    pull      Pull an image or a repository from the docker registry server # 不管registry有没有更新，都会重新拉取相应镜像
    push      Push an image or a repository to the docker registry server # 推送指定镜像或者库镜像至docker源服务器
    restart   Restart a running container                   # 重启运行的容器
    rm        Remove one or more containers                 # 移除一个或者多个容器
        # 删除主机上所有容器：docker ps -a | awk '{print $1}' | xargs docker rm -f
    rmi       Remove one or more images                     # 移除一个或多个镜像[无容器使用该镜像才可删除，否则需删除相关容器才可继续或 -f 强制删除]
    run       Run a command in a new container              # 创建一个新的容器(并启动)并运行一个命令
        -i  # 开启标准输出
        -d  # 运行容器并启动守护进程
        -t  # 开启一个伪终端(进入容器命令行，组合建ctrl+p、ctrl+q退出)
        -p  # 绑定本地端口到容器端口，可使用多个 -p 绑定多组端口. eg: -p 8080:80 (本地8080:容器80)
        -v  # 挂在本地目录或文件到容器中去做数据卷，可以使用多个 -v. eg: -v /home/smalle/logs:/temp/app，也可以使用volume数据卷
            # 目录或者文件映射，需要先在宿主机创建此文件或目录。如果要映射出来的目录中存在文件，则需要新创建对应的文件，docker不会进行初始化这些文件
            # windows的目录则使用 /c/Users/smalle 格式代替 c:
        -e  # 设置环境变量，eg: -e MYSQL_HOST=localhost -e MYSQL_DATABASE=aezocn
        -h  # 指定容器的hostname。eg：-h aezocn
        --name          # 指定启动容器名称(从Docker 1.10 版本开始，docker daemon 实现了一个内嵌的DNS server，使容器可以直接通过"容器名"通信)
        --network/--net # 指定使用的网络（windows的help中并没有说明可简写为--net）
        --restart       # 重启模式：--restart=always失败永远重启(包括宿主主机开机后自启动)
        --link          # 链接其他容器。eg：docker run --link my_nginx my_db -d wordpress # 表示在wordpress中可以放访问被链接容器
        --privileged    # 使用该参数，container内的root拥有真正的root权限。否则container内的root只是外部的一个普通用户权限。privileged启动的容器，可以看到很多host上的设备，并且可以执行mount，甚至允许你在docker容器中启动docker容器
    save      Save an image to a tar archive                # 保存一个镜像为一个 tar 包[对应 load]
    search    Search for an image on the Docker Hub         # 在 docker hub 中搜索镜像
    start     Start a stopped containers                    # 启动容器
    stop      Stop a running containers                     # 停止容器
    tag       Tag an image into a repository                # 给源中镜像打标签
    top       Lookup the running processes of a container   # 查看容器中运行的进程信息
    unpause   Unpause a paused container                    # 取消暂停容器
    version   Show the docker version information           # 查看 docker 版本号
    wait      Block until a container stops, then print its exit code    # 截取容器停止时的退出状态值
Run 'docker COMMAND --help' for more information on a command.
```

### 镜像

- 获取镜像
    - `docker pull NAME[:TAG]` 拉取镜像。如：`docker pull nginx:latest`(同：`docker pull nginx`，省略TAG则默认为`latest`)
        - `docker pull www.aezo.cn/aezocn/smtools:latest` 从私有镜像站下载镜像(www.aezo.cn/aezocn/smtools为repository，latest为tag)
    - `docker images` 列出所有本地镜像
        - `docker inspect c28687f7c6c8` 获取某个image ID的详细信息
    - `docker search mysql` 搜索远程仓库镜像
        - 查看某个Name的所有TAG：如centos访问`https://hub.docker.com/r/library/centos/tags/`查看
- 运行镜像
    - **`docker run -it busybox`** 运行busybox镜像，并进入容器(本地无此镜像时，会自动pull)。**BusyBox 是一个集成了三百多个最常用Linux命令和工具的软件**
    - `docker run -dt -p 8080:80 nginx` **后台运行nginx镜像**(包含创建一个容器)
- 提交镜像
    - `docker commit -m 'commit message' -a 'author info' c28687f7c6c8 my_repositor_name` 基于某容器ID创建镜像(对该容器进行了改动后的提交)
    - `docker tag 7042885a156a 192.168.17.196:5000/nginx` 给某镜像打一个标签，此时不会生成一个新镜像(镜像ID还是原来的). **192.168.17.196:5000/nginx 很重要，之后可以推送到私有仓库192.168.17.196:5000(ip地址一定要一样)，推送上去的镜像为nginx:latest**
- 构建镜像
    - `docker build --rm -f /path/to/a/Dockerfile .` 从Dockerfile构建镜像
- 删除镜像
    - `docker image rm c28687f7c6c8` 删除镜像(-f 强制删除)
    - `docker rmi $(docker images -f "dangling=true" -q)` **清除坏的`<none>:<none>`镜像**
        - `docker images -a|grep none|awk '{print $3 }'|xargs docker rmi`

### 容器

- `docker run -it image_id_c28687f7c6c8 /bin/echo 'hello world'` 创建并启动容器(如果没有则会从远程仓库下载)
- `docker create -it c28687f7c6c8` 基于镜像创建容器，但不启动
- `docker start a8f590736b62` **启动容器** (不会进入容器，启动后回到shell)
- `docker stop a8f590736b62` 停止容器
- `docker update --restart=always a8f590736b62` 更新运行中的容器配置(包括还可以更新CPU/MEM分配等，此处更新其重启类型restart为always)
    - 启动后的容器需要添加新端口可以走端口映射，或者先提交成镜像然后再运行一个容器
- `docker ps` 列出运行的容器
    - `docker ps -a` 列举所有容器
- `docker exec -it <container_id | container_name> bash` **运行容器中的命令，此时会进入容器shell**；此时容器必须处于启动状态；`exit`可退出容器命令行(并不会关闭容器)
    - `docker exec -dt <container_id | container_name> ls` 运行容器中的命令，但是不会进入容器
    - `docker exec -it <container_id | container_name> /bin/bash -c 'ls'` 也不会进入容器
- `docker attach <container_id | container_name>` 进入某运行的容器 **(组合建ctrl+p+q退出)**，部分容器无法使用ctrl+p+q退出
- `docker inspect a8f590736b62` 查看容器详细(存储、网络等)。详细`--format`语法如下(Go模板语法) [^8]
	
	```bash
	## 查看nginx绑定的端口
	# {{println}}为打印换行
	# range相当于循环，需要和{{end}}配合
	# $k,$v为自定义变量，用来接收.NetworkSettings.Ports的map
	# (index $v 0)表示基于索引获取$v的属性为0的数值，如果是数组则是取$v[0]的值；也可用于map取键含特殊字符的值，如：(index $map "my.key.com.test")
	sudo docker inspect --format '{{/*注释：通过变量组合展示容器绑定端口列表*/}}已绑定端口列表：{{println}}{{range $k,$v := .NetworkSettings.Ports}}{{$k}} -> {{(index $v 0).HostPort}}{{println}}{{end}}' nginx
	# 已绑定端口列表：
	# 443/tcp -> 443
	# 4443/tcp -> 4443
	# 80/tcp -> 2080

	## 查看所有容器使用的网卡信息
	sudo docker inspect --format='{{.Name}} => {{range $k,$v := .NetworkSettings.Networks}}{{$k}}->{{.IPAddress}}{{end}}' $(sudo docker ps -aq)
	# /nginx => harbor_harbor->172.18.0.8
	# /jenkins => bridge->172.17.0.2
	```
- `docker rm a8f590736b62` 删除容器ID为a8f590736b62的容器
- `docker rename 原容器名 新容器名` 重命名容器名(运行也可重命名)

## docker网络

- 网络类型：host、bridge(默认)、container、none. 使用如：`docker run --network=host busybox`
    - `host` 和宿主主机使用相同的网络(包括端口，此时无需-p指定端口映射)
    - `bridge` 桥接模式。中间通过`docker0`虚拟网卡(docker默认网卡)进行网络传输。此时与外网连通，需要开启ip转发
        - 从docker0子网中分配一个IP给容器使用，并设置docker0的IP地址为容器的默认网关。在主机上创建一对虚拟网卡veth pair设备，Docker将veth pair设备的一端放在新创建的容器中，并命名为eth0（容器的网卡），另一端放在主机中，以vethx这样类似的名字命名，并将这个网络设备加入到docker0网桥中。可以通过`brctl show`命令查看
        - 需开启宿主机IP转发，此时宿主主机相当于一个NAT，容器的`eth0`通过docker规定的网络接口与`docker0`连接，`docker0`又处于宿主主机
            - 当容器向公网发起请求时 -> 容器的`eth0` -> `docker0` -> (由于开启ip转发)宿主主机`eth0` -> 此时原地址会改成宿主主机向公网发送IP包

            ```bash
            ## 临时开启转发(1是允许转发，0不允许转发)
            echo 1 > /proc/sys/net/ipv4/ip_forward
            ## 永久修改，加入配置
            # net.ipv4.ip_forward=1
            # net.ipv6.conf.all.forwarding=1
            sudo vi /etc/sysctl.conf
            # 使文件生效
            sudo sysctl -p /etc/sysctl.conf
            ```
        - 无法连接外网分析：[http://blog.aezo.cn/2019/06/20/linux/network/](/_posts/linux/network.md#TTL=1导致虚拟机/docker无法访问外网)
    - `container` 容器和另外一个容器共享Network namespace。 kubernetes中的pod就是多个容器共享一个Network namespace
        - `--network=container:web1` 指定 jointed 容器为 web1
    - `none` Docker容器拥有自己的Network Namespace，但是，并不为Docker容器进行任何网络配置。也就是说，这个Docker容器没有网卡、IP、路由等信息。需要我们自己为Docker容器添加网卡、配置IP等。这种网络模式下容器只有lo回环网络，没有其他网卡
- docker部署在本地虚拟机上
    - 此时docker的宿主主机为虚拟机，虚拟机和本地机器属于同一网络。然后在docker中启动一个容器，docker会自动在宿主主机上创建一个虚拟网络，用于桥接宿主主机和容器内部网络
    - **容器会继承docker宿主主机的网络**，在容器内部是可以向外访问到宿主主机所在网络，如本地物理机
    - 在本地物理机中默认是无法访问容器内网络，当开启端口映射8080:80时，可通过访问宿主主机的映射端口(8080)达到访问容器的内部端口(80)
- docker部署在内网的其他机器上，同上理。需要注意容器内部访问宿主主机内网其他机器时，需要该机器没有开启VPN，虚拟网卡(会产生多个ip)等
- Docker操纵`iptables`规则以提供网络隔离(会定时重置iptables规则)。如果需要添加在Docker规则之前加载的规则，需将添加到`DOCKER-USER`(filter表)链中。也可通过参数关闭docker对iptables的操作

### docker跨容器通信

- host、bridge、container、none解决了单个 Docker Host 内容器通信的问题
- 跨(宿主机)容器通信解决方案
    - 可通过直接路由方式(NAT)
    - 桥接方式(如pipework)完成跨容器通信(二层VLAN网络，大二层方式，只适合小于4096节点集群，且存在广播风暴问题)
    - docker 内置的 Overlay 和 macvlan 则解决了跨容器通信，第三方方案常用的包括 flannel、weave、calico
- Overlay网络
    - Overlay网络是指在不改变现有网络基础设施的前提下，通过某种约定通信协议，把二层报文封装在IP报文之上的新的数据格式。这样不但能够充分利用成熟的IP路由协议进程数据分发，而且能够突破VLAN的4096数量限制，支持高达16M的用户，并在必要时可将广播流量转化为组播流量，避免广播数据泛滥
    - 三种Overlay的实现标准，分别是：虚拟可扩展LAN(VxLAN)、采用通用路由封装的网络虚拟化(NVGRE)和无状态传输协议(SST)，其中以VxLAN的支持厂商最为雄厚，VxLan数据包格式

        ![network-vxlan](/data/images/linux/network-vxlan.png)
- 为支持容器跨主机通信，Docker 提供了 overlay driver。Docerk overlay 网络需要一个 key-value 数据库用于保存网络状态信息，包括 Network、Endpoint、IP 等。Consul、Etcd 和 ZooKeeper 都是 Docker 支持的 key-vlaue 软件
- Overlay方案实践(Host0: 192.168.6.10, Host1: 192.168.6.131, Host2: 192.168.6.132) [^11] [^12]

```bash
## 准备 overlay 环境(Linux 3.10.0-957.el7.x86_64 可成功部署)
# Host0 部署 Consul 数据库容器(也可下载tar安装包进行安装，见下文；也可创建集群)。容器启动后，可以通过 http://192.168.6.10:8500 访问 Consul
docker run -d -p 8500:8500 -h consul --name consul --restart=always progrium/consul -server -bootstrap
# 修改各个节点(Host1、Host2) docker daemon 的配置文件 /usr/lib/systemd/system/docker.service，在 ExecStart 最后添加下列配置
# -H 开启本地和远程监听；--cluster-store 指定 consul 的地址；--cluster-advertise 告知 consul 自己的连接地址，ens33为当前节点的ip地址对应的网卡，也可以直接填写ip地址
-H unix:///var/run/docker.sock -H 0.0.0.0:6376 --cluster-store=consul://192.168.6.10:8500 --cluster-advertise=ens33:6376
# 重启docker(必须保证consul是正常运行的，因此Host0通过容器启动consul后则无法加入到跨主机通信中)。host1 和 host2 将自动注册到 Consul 数据库中(Key/Values - docker - nodes)
systemctl daemon-reload
systemctl restart docker

## 创建 overlay 网络
# 在 Host1创建网络overlay网络。-d 网络驱动driver使用overlay
docker network create -d overlay ov_net1 # docker network create -d overlay --subnet 10.10.0.0/24 ov_net1 # 指定子网范围(默认为10.0.0.0/24)
# 查看 Host1 和 Host2 网络：此时发现两个节点都有网络 ov_net1，且其 SCOPE 为 global
# 因为创建 ov_net1 时 host1 将 overlay 网络信息存入了 consul，host2 从 consul 读取到了新网络的数据。之后 ov_net 的任何变化都会同步到 host1 和 host2
docker network ls
# 查看详细信息：IPAM 是指 IP Address Management，docker 自动为 ov_net1 分配的 IP 空间为 10.0.0.0/24
docker network inspect ov_net1

## 在 overlay 中运行容器
# 在 Host1 创建一个 busybox1
# **--name为hostname，此时使用overlay，相当于容器在一个局域网中，应该尽量保证hostname不重复**
docker run -itd --name busybox1 --network ov_net1 busybox
# 查看busybox的网络配置：busybox1 有两个网络接口 eth0 和 eth1
# eth0 IP 为 10.0.0.2，连接的是 overlay 网络 ov_net1
# eth1 IP 为 172.18.0.2，容器的默认路由是走 eth1。其实，docker 会在宿主机上创建一个 bridge 网络"docker_gwbridge"，为所有连接到 overlay 网络的容器提供访问外网的能力
docker exec busybox1 ip a
# Host1 上查看网桥网络信息：docker_gwbridge 的 IP 地址范围是 172.18.0.0/16，当前连接的容器就是 busybox1（172.18.0.2）
docker network inspect docker_gwbridge
# Host1 宿主机上查看：而且此网络的网关就是网桥 docker_gwbridge 的 IP 172.18.0.1；这样容器 busybox1 就可以通过 docker_gwbridge 访问外网
ifconfig docker_gwbridge

## overlay 网络连通性
# Host2 中运行 busybox
docker run -itd --name busybox2 --network ov_net1 busybox
# 互通测试：Host2上容器 ping Host1上容器
docker exec busybox2 ping -c 2 busybox1

## Overlay 网络默认隔离
# 不同overlay网络进行访问。此时busybox3位于Host1的ov_net2网络上
docker network connect ov_net1 busybox3
```

- 原理说明

    ![docker-overlay-1](/data/images/devops/docker-overlay-1.png)

    - network namespace
        - docker 会为每个 overlay 网络创建一个独立的 network namespace(1-da3d1b5fcb)，其中包含一个 linux bridge br0设备。 veth pair 一端连接到容器中(即 容器eth0)，另一端连接到 namespace 的 br0 上(vethx)
        - br0 除了连接所有的 veth pair，还会连接一个 vxlan 设备，用于与其他 host 建立 vxlan tunnel，容器之间的数据就是通过这个 tunnel 通信的。vxlan是个特殊设备，收到包后，由vxlan设备创建时注册的设备处理程序对包进行处理，即进行VXLAN封包(这期间会查询consul中存储的net1信息)，将ICMP包整体作为UDP包的payload封装起来，并将UDP包通过宿主机的eth0发送出去
        - 查看 overlay 网络的 namespace(测试为1-e5c4953846)
             
            ````bash
            # 查看 overlay 网络的 namespace
            ln -s /var/run/docker/netns /var/run/netns
            # 如显示的`1-e5c4953846`标识会在 `docker network ls` 找到类似的NETWORK ID(开头一致，可能最后几个字母没有显示)
            ip netns
            # 查看此命名空间网络接口，包含有：lo、br0、vxlan1、veth2@if455(veth2)
                # vxlan1 为 overlay network的一个 VTEP，即VXLAN Tunnel End Point – VXLAN隧道端点。VXLAN的相关处理都在VTEP上进行，例如识别以太网数据帧所属的VXLAN、基于 VXLAN对数据帧进行二层转发、封装/解封装报文等
                # 同一个overlay网络中，每个docker对应一个vethx(`docker exec -it centos1 ethtool -S eth0` 显示的网卡序号和此时查询到的vethx的序号会相互对应)
            # ip netns exec 1-e5c4953846 xxx 相当于基于此 network namespace 运行相关网络命令。也可进行抓包：ip netns exec 1-e5c4953846 tcpdump -i veth2 -n icmp
            ip netns exec 1-e5c4953846 ip a
            # 查看此命名空间网桥接口
            ip netns exec 1-e5c4953846 brctl show
            ```
    - 数据流向
        - 同一个Overlay网络(net1)不同宿主机(蓝色为宿主机，白色虚框为容器)
            - 数据包从容器eth0发出
            - 经过vxlan1时进行VxLAN封包处理(这期间会查询consul中存储的overlay信息)，将ICMP包(ping)整体作为UDP包的payload封装起来，并将UDP包通过宿主机的eth0发送出去
            - 宿主机收到UDP包后，发现是VXLAN包，根据VXLAN包中的相关信息(比如Vxlan Network Identifier，VNI=256)找到vxlan设备，并转给该vxlan设备处理
            - vxlan设备的处理程序进行解包，并将UDP中的payload取出，整体通过br0转给vethx接口
        - 不同Overlay网络相同宿主机
            - 数据包从容器eth1发出，经过docker_gwbrige进行传输。普通网络默认是桥接在docker0网卡上，而所有Overlay网络则桥接在docker_gwbrige网卡上进行通讯

- 手动安装[Consul](https://www.consul.io/)
    - Consul是一个分布式高可用的系统，可用于服务发现、Key/Value存储等

```bash
wget https://releases.hashicorp.com/consul/1.5.2/consul_1.5.2_linux_amd64.zip
# 只有一个consul二进制文件
unzip consul_1.5.2_linux_amd64.zip
sudo mv consul /bin
# 启动server(无ui界面，需要单独下载consul_ui文件，然后使用参数指定界面路径)
nohup sudo consul agent -server -bootstrap -data-dir /home/data/consul -bind=192.168.6.10 -client 0.0.0.0 > ./nohup.out 2>&1 &

## HA(可以启动一个server和多个agent，然后让agent节点join到consul集群中)
# 在另一台机器上启动agent进行HA部署
nohup sudo consul agent -data-dir /home/data/consul -bind=192.168.6.11 > ./nohup.out 2>&1 &
# 如果脚本运行，则需要先启动客户端后暂停几秒再执行join命令
consul join 192.168.6.10

## 其他命令
# 查看个节点状态
consul members
```

## Dockerfile

- 在大部分情况下，Dockerfile 会和构建所需的文件放在同一个目录中，为了提高构建的性能，应该使用 `.dockerignore` 来过滤掉不需要的文件和目录
- `docker build --rm -t my-nginx:latest -f /home/smalle/Dockerfile .` 从Dockerfile构建镜像 [^4] [^10]

    ```bash
    # This my first nginx Dockerfile
    # Version 1.0

    # FROM 基础镜像
    FROM bzyep49h.mirror.aliyuncs.com/library/centos

    # MAINTAINER 维护者信息
    MAINTAINER smalle

    # ARG获取外部环境变量，也可以定义默认值，ARG可以在Dockerfile文件第一行接受外部参数
    # docker build --build-arg SQ_DOCKER_REGISTRY=192.168.6.131:5000 --build-arg APP_VERSION=v1.1.1 .
    ARG APP_VERSION=v1.0.0

    # ENV 设置环境变量。可读取ARG参数内容
    ENV APP_VERSION=${APP_VERSION}
    ENV PATH /usr/local/nginx/sbin:$PATH

    # ADD 从本地当前目录复制文件到容器. 文件放在当前目录下，拷过去会自动解压
    # COPY 功能类似ADD，但是是不会自动解压文件，也不能访问网络资源
    # 具体说明见下文
    ADD nginx-1.8.0.tar.gz /usr/local/
    ADD epel-release-latest-7.noarch.rpm /usr/local/

    # 指定运行容器时的用户名或 UID，后续的 RUN 也会使用指定用户。可在不同位置进行切换
    USER root
    # USER user:group
    # USER uid:gid

    # RUN 构建镜像时执行的命令。每运行一条RUN，容器会添加一层，并提交
    RUN rpm -ivh /usr/local/epel-release-latest-7.noarch.rpm
    RUN yum install -y wget lftp gcc gcc-c++ make openssl-devel pcre-devel pcre && yum clean all
    RUN useradd -s /sbin/nologin -M www

    # WORKDIR 相当于cd
    WORKDIR /usr/local/nginx-1.8.0 

    RUN ./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module --with-pcre && make && make install
    RUN echo "daemon off;" >> /etc/nginx.conf

    # EXPOSE 映射端口
    EXPOSE 80
    
    ## ENTRYPOINT和CMD
        # 共同点：都可以指定shell或exec函数调用的方式执行命令；当存在多个时，都是只有最后一个生效
        # 不同点：CMD指令指定的容器启动时命令可以被docker run指定的命令覆盖，而ENTRYPOINT指令指定的命令不能被覆盖，而是将docker run指定的参数当做ENTRYPOINT指定命令的参数；CMD指令可以为ENTRYPOINT指令设置默认参数，而且可以被docker run指定的参数覆盖
    # ENTRYPOINT ["executable", "param1", "param2"] # 如果需要执行shell命令，可为：ENTRYPOINT ["sh", "-c", "echo $PATH"]
    # ENTRYPOINT command param1 param2 # 执行shell命令
    # CMD ["executable","param1","param2"] # 使用 exec 执行，推荐方式
    # CMD command param1 param2 # 在 /bin/sh 中执行，提供给需要交互的应用
    # CMD ["param1","param2"] # 提供给 ENTRYPOINT 的默认参数

    # CMD 构建容器后调用，也就是在容器启动时才进行调用
    # CMD ["/bin/bash", "-c", "npm start && node ./server/server.js"]
    CMD ["nginx"]
    ```

### ADD/COPY

- 语法：`ADD <src>… <dest>` 或者 `ADD ["<src>",… "<dest>"]`
- 每个`<src>`可以包含通配符并且使用Go的`filepath.Match`规则匹配
    
    ```bash
    ADD hom* /mydir/        # adds all files starting with "hom"
    ADD hom?.txt /mydir/    # ? is replaced with any single character, e.g., "home.txt"
    ```
- ADD遵守如下规则
    - `<src>`路径必须在构建上下文内。**不能`ADD ../something /something`，因为docker build的第一步已经把上下文目录和子目录发送到docker daemon了**
    - 如果`<src>`是一个目录，目录的所有内容都将复制，包括文件系统元数据，但是不包括目录本身
    - `ADD http://example.com/foobar /test` 将创建文件 `/test/foobar`
    - 如果`<src>`是一个本地的可识别的tar压缩文件(如gzip、bzip2或xz)，那么将在容器内解压为目录。远程URL的压缩文件将不会解压
    - 如果`<src>`是多个资源，不管是直接指定或使用通配符，那么`<dest>`必须是一个目录，并且要以斜杠/结尾
    - 如果`<dest>`不以斜杠/结尾，将视其为一个普通文件，`<src>`的内容将写到这个文件
    - 如果`<dest>`不存在，则会与其路径中的所有缺少的目录一起创建
- COPY 功能类似ADD，但是是不会自动解压文件，也不能访问网络资源

## docker-compose 多容器控制 [^1]

- [docker-compose](https://docs.docker.com/compose/compose-file/) 是用来做docker的多容器控制，默认基于`docker-compose.yml`来进行配置
- `pip install docker-compose` 安装(为python实现)，可能需要提前安装pip：`yum install python-pip`
- 命令

    ```bash
    # 非管理员运行docker-compose命令(sudo执行)，可能会提示ERROR: Couldn't connect to Docker daemon at http+docker://localhost - is it running?
    Usage:
      docker-compose [-f <arg>...] [options] [COMMAND] [ARGS...]
      docker-compose -h|--help

    Options:
      -f, --file FILE             Specify an alternate compose file (default: docker-compose.yml)
          # eg: docker-compose -f my_docker-compose.yml up -d # 指定配置文件启动
      -p, --project-name NAME     Specify an alternate project name (default: directory name)
      --verbose                   Show more output
      --no-ansi                   Do not print ANSI control characters
      -v, --version               Print version and exit
      -H, --host HOST             Daemon socket to connect to

      --tls                       Use TLS; implied by --tlsverify
      --tlscacert CA_PATH         Trust certs signed only by this CA
      --tlscert CLIENT_CERT_PATH  Path to TLS certificate file
      --tlskey TLS_KEY_PATH       Path to TLS key file
      --tlsverify                 Use TLS and verify the remote
      --skip-hostname-check       Don't check the daemon's hostname against the name specified
                                  in the client certificate (for example if your docker host
                                  is an IP address)
      --project-directory PATH    Specify an alternate working directory (default: the path of the Compose file)

    Commands:
      build              Build or rebuild services
      bundle             Generate a Docker bundle from the Compose file
      config             Validate and view the Compose file # 校验配置文件语法格式
      create             Create services
        # 创建容器，之后执行start启动容器(docker-compose up -d则会自动创建和启动)
      down               Stop and remove containers, networks, images, and volumes
      events             Receive real time events from containers
      exec               Execute a command in a running container
      help               Get help on a command
      images             List images # 查看使用的镜像信息
      kill               Kill containers
      logs               View output from containers
        # 获取日志（docker-compose logs [my_service_name]）. **比docker logs的日志多一些，包含compose解析相关日志。只有容器重新创建日志才会清除**
      pause              Pause services
      port               Print the public port for a port binding
      ps                 List containers  # 查看运行的容器
      pull               Pull service images # 不管registry有没有更新，都会重新拉取此compose中镜像，历史镜像标签将会变成<none>，下次up启动则是使用新镜像
      push               Push service images
      restart            Restart services  # 重启服务。**不管compose配置文件是否修改，重启都不会重新创建容器**
      rm                 Remove stopped containers # 删除老旧的服务（docker-compose rm my_service_name）
      run                Run a one-off command
        # docker-compose run my_service_name bash # 可进入到容器中，对于一些启动失败的可以通过此方式调试
      scale              Set number of containers for a service
      start              Start services # 启动服务(如docker-compose.yml有多个服务时，可以只运行其中一个，docker-compose start my_service_name)
      stop               Stop services # 停止服务，类似启动
      top                Display the running processes
      unpause            Unpause services
      up                 Create and start containers
          # 创建并启动容器(在docker-compose.yml文件所在目录执行)。-d 表示后台运行。当前用户需要在docker组或者使用root用户启动(如sudo)
          # 多次执行up启动只会启动services中未运行的服务。如果修改了compose配置重新执行则会重新创建容器
          # 重新启动容器不会有产生多的镜像或容器
          -d
          # docker-compose pull && docker-compose up -d # 强制更新镜像并重启
      version            Show the Docker-Compose version information
    ```

### 案例

- `docker-compose.yml`示例

```yml
version: '3' # 表示使用第3代语法来构建
services:
  my_nginx: # 服务名（可当成hostname进行网络访问）
    container_name: sq-nginx # 创建的容器名(默认是是`服务名_1`)。**可在其他compose文件中直接当hostname使用(并且对应的端口需要为容器中的端口)**
    image: bitnami/nginx:latest # 镜像名(如果本地没有此镜像，会默认从中央仓库拉取镜像)
    # 网络类型使用host模式(即使用宿主主机的网络，此时不能配置ports信息，端口也全部使用的是主机的端口)
    # network_mode: host
    ports: # 端口映射(本地端口:容器端口的映射。windows的本地端口为运行docker的虚拟机端口。只是监听此端口，并不会占用此端口)
      - 80:80
      - 1443:443
    volumes: # 数据卷映射(本地路径:容器路径。windows的本地路径为运行docker的虚拟机路径。不要把 docker 当做数据容器来使用，数据一定要用 volumes 放在容器外面。如日志文件需要进行映射)
      # 官方nginx镜像为 /usr/share/nginx/html
      - /home/smalle/data/nginx/:/bitnami/nginx/
      # 共享主机时区和时间
      - /etc/timezone:/etc/timezone:ro # echo 'Asia/Shanghai' > /etc/timezone
      - /etc/localtime:/etc/localtime:ro
	environment:
	  TZ: Asia/Shanghai # 设置容器时区。参考：https://www.jianshu.com/p/004ddf941aac
    restart: always # 启动模式，always表示失败永远重启（包括宿主主机开机后自启动）
  sq-mysql:
    container_name: sq-mysql
    image: mysql/mysql-server:5.7 # 如果本地没有此镜像，会默认从中央仓库拉取镜像
    ports:
      - 13307:3306
    volumes:
      # 用于保存数据文件。虚拟机中无此/home/smalle/data/test目录时，会自动创建
	  - /home/smalle/data/test:/var/lib/mysql
    # entrypoint会覆盖Dockerfile中的ENTRYPOINT(可为字符串或数组)，command会覆盖CMD(可为字符串或数组)。参考Dockerfile中的ENTRYPOINT和CMD比较。docker-compose restart也会执行此命令
    # entrypoint: ["/my-script.sh","/entrypoint.sh"] # 如果想在容器启动前执行命令，可覆盖此参数
	command: 
	  --character-set-server=utf8mb4            # 设置数据库表的数据集
	  --collation-server=utf8mb4_unicode_ci     # 设置数据库表的数据集
	  --lower_case_table_names=1				# 表名不区分大小写
      --max_allowed_packet=1000M
	  --default-time-zone=+8:00                 # 设置mysql数据库的时区，而不是设置容器的时区
    environment:
      TZ: Asia/Shanghai
      # MYSQL_ROOT_HOST: '%'
      # MYSQL_ROOT_PASSWORD: root
      MYSQL_HOST: localhost
      # 创建容器时会自动创建此数据库和用户
      MYSQL_DATABASE: shengqi
      MYSQL_USER: shengqi
	  MYSQL_PASSWORD: shengqi
    restart: always # 启动失败这重复启动（并且当docker虚拟机启动后，会自动启动此容器）
  wordpress:
    image: bitnami/wordpress:latest
    depends_on: # **依赖的服务名(compose文件中的services名)**。并不能控制等依赖启动完成才启动此服务
      - mariadb
      - my_nginx
    # links: # 依赖的镜像
    environment: # 当做环境变量传入容器（Dockerfile中无需定义/接收此环境变量）
      TZ: Asia/Shanghai
      WORDPRESS_USERNAME: smalle # 自定义属性
      WORDPRESS_PASSWORD: aezocn
      # 或者使用列表
      # - WORDPRESS_USERNAME=smalle
      # - WORDPRESS_PASSWORD=aezocn
    ports:
      - 8080:80
      - 8081:443
    volumes:
      - /home/smalle/data/wordpress:/bitnami/wordpress
      - /home/smalle/data/apache:/bitnami/apache
	  - /home/smalle/data/php:/bitnami/php
  my_app:
    # 基于Dockerfile文件构建镜像时使用的属性。可以基于某镜像进行扩展，如ENV,CMD,ENTRYPOINT都可以进行覆盖，不定义则使用FROM基础镜像
    build:
      # Dockerfile文件目录，此时为当前目录，也可以指定绝对路径[/path/test/Dockerfile]或相对路径[../test/Dockerfile]
      context: .
      # 指定Dockerfile文件名，如果context指定了文件名，这里就不用本属性了。默认是`Dockerfile`
      dockerfile: Dockerfile-swapping
      #env_file:
      #  - ./env # 如果是当前目录存在.env文件则默认可省略
      # environment:
      #   MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      # secrets: # secrets 存储敏感数据，例如 mysql 服务密码
      #   - db_root_password
      #   - my_other_secret
      # 控制容器连接
      environment:
        TZ: Asia/Shanghai
        MYSQL_HOST: my_mysql #使用links进来的别名，或者可直接使用容器名(使用容器名时，该容器可以在另外一个compose文件中)
        # MYSQL_PORT: 3306 # 如果MYSQL_HOST使用了容器名/别名，则此处需要使用对应容器中的端口，而不是映射到宿主机的端口
      links:
        # 值可以是 `- 服务名`，也可以是`- "服务名:别名"`
        - sq-mysql:my_mysql
```
- `$VARIABLE`和`${VARIABLE}`两种写法都支持，**可以使用双美元符号(`$$`)来转义美元符号**。如果使用的是2.1文件格式，还可以在一行中设置默认的值：
    - `${VARIABLE:-default}` 当VARIABLE没有设置或为空值时使用default值
    - `${VARIABLE-default}` 仅当VARIABLE没有设置时使用default值
- 容器启动先后顺序问题 [^7]
    - `depends_on`表示再启动容器时会先启动依赖的服务，但并不能控制等依赖启动完成才启动此服务
    - 基于`wait-for-it.sh`解决先后启动。[脚本代码](https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh)
        - 需要将`wait-for-it.sh`打包到容器中，即在Dockerfile中将文件从本地目录复制到容器目录，如/app目录
        - docker-compose.yml中基于command命令配置启动命令，command会覆盖Dockerfile文件中的默认启动命令(CMD)。如：`command: ["/app/wait-for-it.sh", "sq-eureka:9810", "--", "/app/runboot.sh"]`
### 容器网络

- 同一 docker-compose 配置文件中的多个容器默认处于统一网络，不同 docker-compose 配置文件处于不同网络
- 每个 docker-compose 配置文件会产生一个xxx_default的网络(查看网络：docker network ls)
- 如果 docker-compose 配置文件(假如所在目录为mydir)中只有一个服务则默认生成`mydir_服务名_default`，如果有多个服务则会生成一个`123456789_default`的网络
- 自定义网络、共用一个网络

```yml
# 如果此yml文件所在目录为mydir
## 示例1
version: '3'
services:
  test1:
    container_name: sq_test1
    networks:
      - sq-net
networks:
  sq-net:
    # 使用已存在的网络sq-net。系统不会自动创建网络，需要先手动创建网络：`docker network create sq-net`。这样多个 docker-compose 配置文件可以共用一个网络
    external: true
    # 不使用已存在的网络。最终会生成一个mydir_sq-net的网络
    # external: false

## 示例2
version: '3'
services:
  test1:
	# ... 无需定义networks，即使用默认(default)网络 -> 使用自定义网络(sq-net)

networks:
  default:
	  # 默认使用已存在的网络，需要先创建此网络`docker network create sq-net`
	  # 如果加入了sq-net，则可以ping同sq-net所有的服务和容器名。如ping test1、ping sq_test1都是可以访问到的
    external:
      name: sq-net
```
- volumes使用同networks

```yml
version: '3'
services:
  test1:
    volumes:
      # 基于容器卷映射
      - jenkins-data:/var/jenkins_home
      # 基于普通目录映射。映射主机的docker到容器里面，这样在容器里面就可以使用主机安装的 docker了(如可以在Jenkins容器里操作宿主机的其他容器)
      - /var/run/docker.sock:/var/run/docker.sock
    user: root # 定义启动用户
    # ...
volumes:
  jenkins-data:
    # 需提前创建此容器卷，如果无external: true则会自动创建容器卷
    external: true
```

### 配置参数

- Compose和Docker兼容性：Compose 文件格式有3个版本,分别为1, 2.x 和 3.x，目前主流的为 3.x 其支持 docker 1.13.0 及其以上的版本

```yml
version: '3'           # 指定 compose 文件的版本
services          # 定义所有的 service 信息, services 下面的第一级别的 key 既是一个 service 的名称
    build                 # 指定包含构建上下文的路径, 或作为一个对象，该对象具有 context 和指定的 dockerfile 文件以及 args 参数值
        context               # context: 指定 Dockerfile 文件所在的路径
        dockerfile            # dockerfile: 指定 context 指定的目录下面的 Dockerfile 的名称(默认为 Dockerfile)
        args                  # args: Dockerfile 在 build 过程中需要的参数 (等同于 docker container build --build-arg 的作用)
        cache_from            # v3.2中新增的参数, 指定缓存的镜像列表 (等同于 docker container build --cache_from 的作用)
        labels                # v3.3中新增的参数, 设置镜像的元数据 (等同于 docker container build --labels 的作用)
        shm_size              # v3.5中新增的参数, 设置容器 /dev/shm 分区的大小 (等同于 docker container build --shm-size 的作用)
    command               # 覆盖容器启动后默认执行的命令, 支持 shell 格式和 [] 格式
    configs               # 不知道怎么用
    cgroup_parent         # 不知道怎么用
    container_name        # 指定容器的名称 (等同于 docker run --name 的作用)
    credential_spec       # 不知道怎么用
    deploy                # v3 版本以上, 指定与部署和运行服务相关的配置, deploy 部分是 docker stack 使用的, docker stack 依赖 docker swarm
        endpoint_mode         # v3.3 版本中新增的功能, 指定服务暴露的方式
            vip                   # Docker 为该服务分配了一个虚拟 IP(VIP), 作为客户端的访问服务的地址
            dnsrr                 # DNS轮询, Docker 为该服务设置 DNS 条目, 使得服务名称的 DNS 查询返回一个 IP 地址列表, 客户端直接访问其中的一个地址
        labels                # 指定服务的标签，这些标签仅在服务上设置
        mode                  # 指定 deploy 的模式
            global                # 每个集群节点都只有一个容器
            replicated            # 用户可以指定集群中容器的数量(默认)
        placement             # 不知道怎么用
        replicas              # deploy 的 mode 为 replicated 时, 指定容器副本的数量
        resources             # 资源限制
            limits                # 设置容器的资源限制
                cpus: "0.5"           # 设置该容器最多只能使用 50% 的 CPU 
                memory: 50M           # 设置该容器最多只能使用 50M 的内存空间 
            reservations          # 设置为容器预留的系统资源(随时可用)
                cpus: "0.2"           # 为该容器保留 20% 的 CPU
                memory: 20M           # 为该容器保留 20M 的内存空间
        restart_policy        # 定义容器重启策略, 用于代替 restart 参数
            condition             # 定义容器重启策略(接受三个参数)
                none                  # 不尝试重启
                on-failure            # 只有当容器内部应用程序出现问题才会重启
                any                   # 无论如何都会尝试重启(默认)
            delay                 # 尝试重启的间隔时间(默认为 0s)
            max_attempts          # 尝试重启次数(默认一直尝试重启)
            window                # 检查重启是否成功之前的等待时间(即如果容器启动了, 隔多少秒之后去检测容器是否正常, 默认 0s)
        update_config         # 用于配置滚动更新配置
            parallelism           # 一次性更新的容器数量
            delay                 # 更新一组容器之间的间隔时间
            failure_action        # 定义更新失败的策略
                continue              # 继续更新
                rollback              # 回滚更新
                pause                 # 暂停更新(默认)
            monitor               # 每次更新后的持续时间以监视更新是否失败(单位: ns|us|ms|s|m|h) (默认为0)
            max_failure_ratio     # 回滚期间容忍的失败率(默认值为0)
            order                 # v3.4 版本中新增的参数, 回滚期间的操作顺序
                stop-first            #旧任务在启动新任务之前停止(默认)
                start-first           #首先启动新任务, 并且正在运行的任务暂时重叠
        rollback_config       # v3.7 版本中新增的参数, 用于定义在 update_config 更新失败的回滚策略
            parallelism           # 一次回滚的容器数, 如果设置为0, 则所有容器同时回滚
            delay                 # 每个组回滚之间的时间间隔(默认为0)
            failure_action        # 定义回滚失败的策略
                continue              # 继续回滚
                pause                 # 暂停回滚
            monitor               # 每次回滚任务后的持续时间以监视失败(单位: ns|us|ms|s|m|h) (默认为0)
            max_failure_ratio     # 回滚期间容忍的失败率(默认值0)
            order                 # 回滚期间的操作顺序
                stop-first            # 旧任务在启动新任务之前停止(默认)
                start-first           # 首先启动新任务, 并且正在运行的任务暂时重叠

        # 注意：
            # 支持 docker-compose up 和 docker-compose run 但不支持 docker stack deploy 的子选项
            # security_opt  container_name  devices  tmpfs  stop_signal  links    cgroup_parent
            # network_mode  external_links  restart  build  userns_mode  sysctls

    devices               # 指定设备映射列表 (等同于 docker run --device 的作用)

    depends_on            # 定义容器启动顺序 (此选项解决了容器之间的依赖关系， 此选项在 v3 版本中 使用 swarm 部署时将忽略该选项)
        # docker-compose up 以依赖顺序启动服务，下面例子中 redis 和 db 服务在 web 启动前启动
        # 默认情况下使用 docker-compose up web 这样的方式启动 web 服务时，也会启动 redis 和 db 两个服务，因为在配置文件中定义了依赖关系
    dns                   # 设置 DNS 地址(等同于 docker run --dns 的作用)
    dns_search            # 设置 DNS 搜索域(等同于 docker run --dns-search 的作用)
    tmpfs                 # v2 版本以上, 挂载目录到容器中, 作为容器的临时文件系统(等同于 docker run --tmpfs 的作用, 在使用 swarm 部署时将忽略该选项)
    entrypoint            # 覆盖容器的默认 entrypoint 指令 (等同于 docker run --entrypoint 的作用)
    env_file              # 从指定文件中读取变量设置为容器中的环境变量, 可以是单个值或者一个文件列表, 如果多个文件中的变量重名则后面的变量覆盖前面的变量, environment 的值覆盖 env_file 的值. 文件格式：RACK_ENV=development 
    environment           # 设置环境变量， environment 的值可以覆盖 env_file 的值 (等同于 docker run --env 的作用)
    expose                # 暴露端口, 但是不能和宿主机建立映射关系, 类似于 Dockerfile 的 EXPOSE 指令
    external_links        # 连接不在 docker-compose.yml 中定义的容器或者不在 compose 管理的容器(docker run 启动的容器, 在 v3 版本中使用 swarm 部署时将忽略该选项)
    extra_hosts           # 添加 host 记录到容器中的 /etc/hosts 中 (等同于 docker run --add-host 的作用)
    healthcheck           # v2.1 以上版本, 定义容器健康状态检查, 类似于 Dockerfile 的 HEALTHCHECK 指令
        test                  # 检查容器检查状态的命令, 该选项必须是一个字符串或者列表, 第一项必须是 NONE, CMD 或 CMD-SHELL, 如果其是一个字符串则相当于 CMD-SHELL 加该字符串
            # NONE                  # 禁用容器的健康状态检测
            # CMD                   # test: ["CMD", "curl", "-f", "http://localhost"]
            # CMD-SHELL             # test: ["CMD-SHELL", "curl -f http://localhost || exit 1"] 或者　test: curl -f https://localhost || exit 1
        interval: 1m30s       # 每次检查之间的间隔时间
        timeout: 10s          # 运行命令的超时时间
        retries: 3            # 重试次数
        start_period: 40s     # v3.4 以上新增的选项, 定义容器启动时间间隔
        disable: true         # true 或 false, 表示是否禁用健康状态检测和　test: NONE 相同

    image                 # 指定 docker 镜像, 可以是远程仓库镜像、本地镜像
    init                  # v3.7 中新增的参数, true 或 false 表示是否在容器中运行一个 init, 它接收信号并传递给进程
    isolation             # 隔离容器技术, 在 Linux 中仅支持 default 值
    labels                # 使用 Docker 标签将元数据添加到容器, 与 Dockerfile 中的 LABELS 类似
    links                 # 链接到其它服务中的容器, 该选项是 docker 历史遗留的选项, 目前已被用户自定义网络名称空间取代, 最终有可能被废弃 (在使用 swarm 部署时将忽略该选项)
    logging               # 设置容器日志服务
        driver                # 指定日志记录驱动程序, 默认 json-file (等同于 docker run --log-driver 的作用)
        options               # 指定日志的相关参数 (等同于 docker run --log-opt 的作用)
            max-size              # 设置单个日志文件的大小, 当到达这个值后会进行日志滚动操作
            max-file              # 日志文件保留的数量
    network_mode          # 指定网络模式 (等同于 docker run --net 的作用, 在使用 swarm 部署时将忽略该选项)         
    networks              # 将容器加入指定网络 (等同于 docker network connect 的作用), networks 可以位于 compose 文件顶级键和 services 键的二级键
        aliases               # 同一网络上的容器可以使用服务名称或别名连接到其中一个服务的容器
        ipv4_address      # IP V4 格式
        ipv6_address      # IP V6 格式
    pid: 'host'           # 共享宿主机的 进程空间(PID)
    ports                 # 建立宿主机和容器之间的端口映射关系, ports 支持两种语法格式
        # SHORT 语法格式示例:
            - "3000"                            # 暴露容器的 3000 端口, 宿主机的端口由 docker 随机映射一个没有被占用的端口
            - "3000-3005"                       # 暴露容器的 3000 到 3005 端口, 宿主机的端口由 docker 随机映射没有被占用的端口
            - "8000:8000"                       # 容器的 8000 端口和宿主机的 8000 端口建立映射关系
            - "9090-9091:8080-8081"
            - "127.0.0.1:8001:8001"             # 指定映射宿主机的指定地址的
            - "127.0.0.1:5000-5010:5000-5010"   
            - "6060:6060/udp"                   # 指定协议
        # LONG 语法格式示例:(v3.2 新增的语法格式)
            - target: 80                      # 容器端口
                published: 8080               # 宿主机端口
                protocol: tcp                 # 协议类型
                mode: host                    # host 在每个节点上发布主机端口,  ingress 对于群模式端口进行负载均衡
    secrets               # 不知道怎么用
    security_opt          # 为每个容器覆盖默认的标签 (在使用 swarm 部署时将忽略该选项)
    stop_grace_period     # 指定在发送了 SIGTERM 信号之后, 容器等待多少秒之后退出(默认 10s)
    stop_signal           # 指定停止容器发送的信号 (默认为 SIGTERM 相当于 kill PID; SIGKILL 相当于 kill -9 PID; 在使用 swarm 部署时将忽略该选项)
    sysctls               # 设置容器中的内核参数 (在使用 swarm 部署时将忽略该选项)
    ulimits               # 设置容器的 limit
    userns_mode           # 如果Docker守护程序配置了用户名称空间, 则禁用此服务的用户名称空间 (在使用 swarm 部署时将忽略该选项)
    volumes               # 定义容器和宿主机的卷映射关系, 其和 networks 一样可以位于 services 键的二级键和 compose 顶级键, 如果需要跨服务间使用则在顶级键定义, 在 services 中引用
        # 语法格式示例:
        - /var/lib/mysql                # 映射容器内的 /var/lib/mysql 到宿主机的一个随机目录中
        - /opt/data:/var/lib/mysql      # 映射容器内的 /var/lib/mysql 到宿主机的 /opt/data
        - ./cache:/tmp/cache            # 映射容器内的 /var/lib/mysql 到宿主机 compose 文件所在的位置
        - ~/configs:/etc/configs/:ro    # 映射容器宿主机的目录到容器中去, 权限只读
        - datavolume:/var/lib/mysql     # datavolume 为 volumes 顶级键定义的目录, 在此处直接调用
    restart               # 定义容器重启策略(在使用 swarm 部署时将忽略该选项, 在 swarm 使用 restart_policy 代替 restart)
        no                    # 禁止自动重启容器(默认)
        always                # 无论如何容器都会重启
        on-failure            # 当出现 on-failure 报错时, 容器重新启动
    # 其他选项：
        domainname, hostname, ipc, mac_address, privileged, read_only, shm_size, stdin_open, tty, user, working_dir
        上面这些选项都只接受单个值和 docker run 的对应参数类似
    # 对于值为时间的可接受的值：
        2.5s
        10s
        1m30s
        2h32m
        5h34m56s
        时间单位: us, ms, s, m， h
    # 对于值为大小的可接受的值：
        2b
        1024kb
        2048k
        300m
        1gb
        单位: b, k, m, g 或者 kb, mb, gb
networks          # 定义 networks 信息
    driver                # 指定网络模式, 大多数情况下, 它 bridge 于单个主机和 overlay Swarm 上
        bridge                # Docker 默认使用 bridge 连接单个主机上的网络
        overlay               # overlay 驱动程序创建一个跨多个节点命名的网络
        host                  # 共享主机网络名称空间(等同于 docker run --net=host)
        none                  # 等同于 docker run --net=none
    driver_opts           # v3.2以上版本, 传递给驱动程序的参数, 这些参数取决于驱动程序
    attachable            # driver 为 overlay 时使用, 如果设置为 true 则除了服务之外，独立容器也可以附加到该网络; 如果独立容器连接到该网络，则它可以与其他 Docker 守护进程连接到的该网络的服务和独立容器进行通信
    ipam                  # 自定义 IPAM 配置. 这是一个具有多个属性的对象, 每个属性都是可选的
        driver                # IPAM 驱动程序, bridge 或者 default
        config                # 配置项
            subnet                # CIDR格式的子网，表示该网络的网段
    external              # 外部网络, 如果设置为 true 则 docker-compose up 不会尝试创建它, 如果它不存在则引发错误
    name                  # v3.5 以上版本, 为此网络设置名称
```

## 常用docker镜像

### docker hub

> https://hub.docker.com

- `centos`
    - `docker run -itd --name centos centos:7` 官方提供的centos镜像，无netstat、sshd等服务，测试可进行安装
    - 安装netstat：`yum install net-tools`
    - 安装sshd：`yum install openssh-server`，启动如下：
        - `mkdir -p /var/run/sshd`
        - `/usr/sbin/sshd -D &`
- `ubuntu`
    - `docker run -itd --name ubuntu ubuntu:14.04`
- `java:8-jre` 一般是docker-compose中引入
- `python:3.6`
- `busybox`
- `maven:3.6.0-jdk-8-alpine`
- `docker:18.06.2-dind`

### 自行编译jdk

- 如ofbiz等项目容器化，需要在容器中编译运行，自行编译jdk作为基础容器
- 在文件夹test下创建文件`Dockerfile`，并将`jdk-7u80-linux-x64.tar.gz`复制进去

```Dockerfile
FROM bzyep49h.mirror.aliyuncs.com/library/centos:7
MAINTAINER smalle
# ADD https://github.com/frekele/oracle-java/releases/download/7u80-b15/jdk-7u80-linux-x64.tar.gz /usr/local
ADD jdk-7u80-linux-x64.tar.gz /usr/local
ENV JAVA_HOME /usr/local/jdk1.7.0_80
ENV JRE_HOME /usr/local/jdk1.7.0_80/jre
ENV CLASSPATH .:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
ENV PATH $PATH:$JAVA_HOME/bin:$JRE_HOME/bin
```
- 打包及推送

```bash
# 打包生成镜像(大概508M)
docker build --rm -t jdk:1.7 -f ./Dockerfile .
# docker run ae4c031a5cb6 java -version # 本地运行镜像，查看java版本

## 推送
# 输入registry(harbor)账号密码登录。[https证书配置参考上文Harbor](#Harbor)
docker login 192.168.17.196:10010
docker tag ae4c031a5cb6 192.168.17.196:10010/library/jdk:1.7
docker push 192.168.17.196:10010/library/jdk:1.7
```

### nginx

```yml
version: '3'
services:
  sq-nginx:
    container_name: sq-nginx
    image: nginx:1.17.0
    ports:
      - 7000:80
      - 7443:443
    volumes:
      # $PWD表示当前目录
      - /home/smalle/html:/usr/share/nginx/html
      # 需要在当前目录创建conf.d目录。nginx.conf的http模块中引入了conf.d目录，只需要在此目录添加xxx.conf的配置文件对server进行配置即可（或覆盖http模块配置）
      - ./conf.d:/etc/nginx/conf.d
      # - ./nginx.conf:/etc/nginx/nginx.conf # 将主配置文件也放在宿主机中进行维护，需要向在宿主机中放入此配置文件才能启动容器
      - ./log:/var/log/nginx
    environment:
      TZ: Asia/Shanghai
    restart: always
networks:
  default:
    # 默认使用已存在的网网络，需要先创建此网络`docker network create sq-net`
    external:
      name: sq-net
```
- docker默认的nginx.conf配置为[nginx.conf](/data/src/arch/nginx.conf.docker)
- 宿主机上配置`$PWD/conf.d/test.conf`

```bash
server {
    listen       80; # 此处必须是容器中的端口
    listen  [::]:80;
    # server_name  localhost;

    # **启用后响应头中会包含`Content-Encoding: gzip`**
    gzip on; #开启gzip压缩输出
    # 压缩类型，默认就已经包含text/html(但是vue打包出来的js需要下列定义才会压缩)
    gzip_types text/plain application/x-javascript application/javascript text/javascript text/css application/xml text/xml;

    access_log /var/log/nginx/test.access.log main;

    location = /index.html {
        root   /usr/share/nginx/html;
        add_header Cache-Control "no-cache, no-store";
    }

    location ^~ /oa-dev-center/ {
		root /usr/share/nginx/html;
		try_files $uri $uri/ /oa-dev-center/index.html;
		if ($request_filename ~* .*\.(?:htm|html)$) {
			add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
		}
	}

    location / {
        # $PWD/html/test 目录下添加一个index.html文件，即可通过 `宿主机IP:7000` 访问
        root   /usr/share/nginx/html/test; # 此处必须是容器中的目录
        # 出现过再部分机器上运行docker无法访问index.html文件(报错：/etc/nginx/html/index.html" failed (2: No such file or directory))？但是可以访问index.htm等其他文件，可以考虑将打包主页文件生成为index.html
        index  index.html index.htm;
    }
}
```
- 更新配置说明
    - 如果仅更新配置文件需要执行nginx加载命令重新加载配置文件
        - `docker exec -it sq-nginx /usr/sbin/nginx -t`
        - `docker exec -it sq-nginx /usr/sbin/nginx -s reload`(未测试成功，但是进入到容器中重启可成功)
    - 如果修改了compose配置文件执行上述命令会重新创建容器(不会拉取新的镜像)

### mysql/mysql-server:5.7

- 容器中默认数据文件路径：`/var/lib/mysql`(下面配置已进行修改)
- 下列配置产生的root用户为root@localhost，修改MYSQL_HOST/MYSQL_ROOT_HOST也无效。可进入容器后执行`mysql -hlocalhost -uroot -p`再进行修改
- 下列配置 [^9]
	- 需要先在docker-compose.yml所在目录创建好配置文件`my.cnf`
	- 如需执行初始化sql语句需先在docker-compose.yml所在目录创建好`init/init.sql`
	- 第一次初始化容器，会先启动mysql进行初始化，然后重新启动mysql。稍等片刻可通过`sudo docker logs sq-mysql`查看日志
	- 第一次初始化容器完成后，可删掉容器重新初始化一次(无需清除mysql数据卷)，防止MYSQL_ROOT_PASSWORD等敏感信息显示在容器信息中

```yml
# docker-compose.yml
version: '3'
services:
  sq-mysql:
    container_name: sq-mysql
    image: mysql/mysql-server:5.7 # 如果本地没有此镜像，会默认从中央仓库拉取镜像
	ports:
	  # 映射宿主机端口13307，**但是和mysql处于相同网络中的容器配置的数据库端口仍然需要是3306**
      - 13307:3306
    volumes:
      # 外部数据卷。docker宿主机中无此/home/data/mysql目录时，会自动创建
      - /home/data/mysql:/var/lib/mysql
      # 外部配置文件
      - ./my.cnf:/etc/my.cnf
      # 外部初始化文件（文件名必须以.sh或者.sql结尾）
      - ./init:/docker-entrypoint-initdb.d/
	environment:
	  TZ: Asia/Shanghai
      # MYSQL_ROOT_PASSWORD: root # 不定义root密码则会自动生成密码，稍等片刻可查看生成密码：sudo docker logs sq-mysql
      MYSQL_HOST: localhost
      # 创建容器时会自动创建此数据库和用户
      MYSQL_DATABASE: shengqi
      MYSQL_USER: shengqi
	  MYSQL_PASSWORD: shengqi
    restart: always
networks:
  default:
    # 默认使用已存在的网网络，需要先创建此网络`docker network create sq-net`
    external:
      name: sq-net
```

```ini
# /home/data/etc/mysql/my.cnf
[client]
default-character-set=utf8mb4

[mysqld]
## copy的docker镜像中的默认配置
# 防止连接缓慢问题
skip-host-cache
skip-name-resolve
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
secure-file-priv=/var/lib/mysql-files
# 防止报错：[ERROR] Fatal error: Please read "Security" section of the manual to find out how to run mysqld as root!
user=mysql
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

## 添加的额外配置
# 表名大小写：0是大小写敏感，1是大小写不敏感. linux默认是0，windows默认是1(建议设置成1)
lower_case_table_names=1
character-set-server=utf8mb4
collation-server=utf8mb4_bin
init-connect='SET NAMES utf8mb4'
# 防止导入数据时数据太大报错
max_allowed_packet=1000M
```

```sql
-- /home/data/etc/mysql/init/init.sql
use mysql;
grant all privileges on *.* to 'root'@'%' identified by 'Hello1234!' with grant option;
flush privileges;
```

### tomcat

```yml
# docker-compose.yml
version: '3'
services:
  sq-tomcat:
    container_name: sq-tomcat
    image: tomcat:jdk8
    ports:
      - 8888:8080
    environment:
      TZ: Asia/Shanghai
    # command: /bin/sh -c "sed -i 's/<Connector/<Connector URIEncoding=\"UTF-8\"/' $$CATALINA_HOME/conf/server.xml && $$CATALINA_HOME/bin/catalina.sh run"
    restart: always
```

- 部署war `docker cp demo.war sq-tomcat:/usr/local/tomcat/webapps`
- 重启容器 `docker restart sq-tomcat`

### ftp服务器

- [stilliard/pure-ftpd](https://hub.docker.com/r/stilliard/pure-ftpd) ftp服务器 [^6]

    ```bash
    ## 安装启动
    # 创建容器。默认数据端口30000-30009，只能满足5个用户同时FTP登陆。计算方式为"(最大端口号-最小端口号) / 2"。里修改为可以满足100个用户同时连接登陆
    # /home/ftpusers为默认的用户数据目录；/etc/pure-ftpd为配置数据，包括用户登录信息(/etc/pure-ftpd/pureftpd.passwd)；增加环境变量`-e "ADDED_FLAGS ..."`表示生成日志(未测试成功)
    docker run -dt --name ftpd_server \
        -p 21:21 -p 30000-30209:30000-30209 \
        -v /home/data/docker/pure-ftpd/ftpusers:/home/ftpusers \
        -v /home/data/docker/pure-ftpd/etc:/etc/pure-ftpd \
        -e "ADDED_FLAGS=-d -d" \
        stilliard/pure-ftpd:hardened bash
    # 进入容器(exec在运行的容器中执行一条命令)
    docker exec -it ftpd_server bash
    # 创建用户输入密码并保存（会自动创建用户目录test，用户默认可在此目录增删改文件或文件夹）。ftpd运行时，可以进入容器添加用户，无需再重新启动
    pure-pw useradd test -u ftpuser -d /home/ftpusers/test
    pure-pw mkdb # 可添加完所有用户一次性保存
    # 在容器中运行FTP。`-c 100`为允许同时连接的客户端数列100, `-C 100`为同一IP最大的连接数100, 这两个数值与端口号30000:30209对应上
    /usr/sbin/pure-ftpd -c 100 -C 100 -l puredb:/etc/pure-ftpd/pureftpd.pdb -E -j -R -P $PUBLICHOST -p 30000:30209 &

    ## 管理相关
    # 查看用户
    cat /etc/pure-ftpd/pureftpd.passwd
    # 更改test户名密码(pure-pw需要在容器中运行)
    pure-pw passwd test
    pure-pw mkdb # 保存
    # 删除用户
    pure-pw userdel test -f /etc/pure-ftpd/pureftpd.passwd
    pure-pw mkdb

    ## 添加用户sh脚本
    #!/bin/bash
    USER=$1
    docker exec -dt ftpd_server pure-pw useradd $USER -u ftpuser -d /home/ftpusers/$USER
    docker exec -dt ftpd_server pure-pw mkdb
    ```

    - 需要使用主动模式连接
    - 常见问题
        - 在文件管理其中连接服务器是，提示`打开ftp服务器上的文件夹时发生错误，请检查是否有权限访问该文件夹`：IE浏览器 - Internet选项 - 高级 - 去勾选"使用被动 FTP"
        - xftp 提示无法显示远程文件夹：点击属性->选项->将使用被动模式选项去掉即可

## 安装私有仓库服务器 [^2]

- Registry：docker仓库注册服务器，用于管理镜像仓库，起到的是服务器的作用
- Repository：docker镜像仓库，用于存储具体的docker镜像，起到的是仓库存储作用

### 命令安装方式

- docker-server(也可使用Harbor代替)

```bash
## 在docker-server上安装私有仓库
docker run -d -p 5000:5000 -v /data/aezo:/var/lib/registry --restart=always --name registry-aezocn registry # 初始化并启动私有仓库（会自动创建/data/aezo，且在此文件下创建docker目录）
# crul -X GET http://192.168.17.196:5000/v2/_catalog # 返回json格式数据(私有仓库镜像信息)表示启动成功
# http://192.168.17.196:5000/v2/nginx/tags/list 显示某镜像标签

# 关闭私有仓库
docker stop registry
```
- docker-client

```bash
## 修改docker-client仓库地址
# docker pull registry.docker-cn.com/myname/myrepo:mytag # 执行命令时指定
# 永久修改仓库地址(修改后可能需要重启docker服务)
vi /etc/docker/daemon.json # 无则新增
# 并加入下列内容(docker客户端默认使用https访问仓库)
{"insecure-registries": ["192.168.17.196:5000"]} # insecure-registries可使用http访问
# 重启docker-client
## 在docker-client保存镜像(基于镜像7042885a156a打tag)。如果是基于harbor则应该为harbor的主端口(站点访问端口)
# 192.168.17.196:5000/nginx 很重要，之后可以推送到私有仓库192.168.17.196:5000(ip地址一定要一样)，推送上去的镜像为nginx:sm_1
docker tag 7042885a156a 192.168.17.196:5000/nginx:sm_1 
## 在docker-client上推送镜像到docker-server(推送成功后，在docker-server上通过docker images也是无法看到镜像的)
docker push 192.168.17.196:5000/nginx
# 此时删除docker-client上关于nginx的镜像，再运行下列命令时，会检查本地没有则从私服上获取并运行
docker run -itd -p 8080:80 192.168.17.196:5000/nginx:sm_1
```

### Harbor

- [Harbor](https://goharbor.io/)、[github](https://github.com/goharbor/harbor)
- Harbor是基于GO开发的一个用于存储和分发Docker镜像的企业级Registry服务器(私有仓库)，提供web界面访问，角色控制。其提供镜像复制功能：镜像可以在多个Registry实例中复制（同步），尤其适合于负载均衡，高可用，混合云和多云的场景 [^3]
- 安装(内部包含一个registry服务器的安装)。基于helm安装参考[helm.md#Harbor](/_posts/devops/helm.md#Harbor)

```bash
## 安装docker-compose
yum install python-pip
pip install docker-compose
docker-compose --version

## 在线安装Harbor
# https://storage.googleapis.com/harbor-releases/release-1.8.0/harbor-online-installer-v1.8.0.tgz
wget -P /opt/src/ https://github.com/vmware/harbor/releases/download/v1.2.0/harbor-online-installer-v1.2.0.tgz
cd /opt/src/
tar zxf harbor-online-installer-v1.2.0.tgz -C /opt/
cd /opt/harbor/
# 修改配置文件。如修改harbor默认使用的数据存储位置/data目录
# 备份
cp /opt/harbor/harbor.cfg /opt/harbor/harbor.cfg.bak
cp /opt/harbor/docker-compose.yml /opt/harbor/docker-compose.yml.bak
# 修改存储位置(sed命令修改下列文件中所有的/data为/data/barbor)
sed -i 's#/data#/data/harbor#g' harbor.cfg
sed -i 's#/data#/data/harbor#g' docker-compose.yml
# 修改配置。最少修改其中的hostname(如hostname=192.168.17.196:10010)，也可修改admin账户密码(默认Harbor12345)
vi /opt/harbor/harbor.cfg
# 修改了docker-compose.yml中80的映射端口为10010:80
vi docker-compose.yml
/opt/harbor/install.sh

## 启动
docker-compose up -d # 启动Harbor(/opt/harbor/)
docker-compose ps # 查看启动状态(需要都是UP)
docker-compose stop # 停止Harbor
# 访问(默认用户密码：admin/Harbor12345。第一次需要等一会再访问)。可修改docker-compose.yml中的映射端口来配置主页地址
# 此处修改了harbor.cfg中的hostname=192.168.17.196:10010
http://192.168.17.196:10010/harbor/sign-in

## 将镜像7042885a156a推送数据到私有仓库（默认含有一个library公共项目，也可自行创建其他项目）
docker tag 7042885a156a 192.168.17.196:10010/library/nginx:sm_1
# 登录(admin/Harbor12345)。登录成功后会保存秘钥到`~/.docker/config.json`，**下次则无需登录**
# 此处端口应该为10010。harbor内部默认也启动了一个registry，端口为5000，并通过nginx做了转发，因此对外端口只有10010。可参看上文修改/etc/docker/daemon.json的配置为：{"insecure-registries": ["192.168.17.196:10010"]}
# docker login 192.168.17.196:10010 -u $HARBOR_U -p $HARBOR_P
docker login 192.168.17.196:10010
docker push 192.168.17.196:10010/library/nginx:sm_1
# 如果是私有仓库pull也需要登录
docker pull 192.168.17.196:10010/sq-eureka/sq-eureka:0.0.1-SNAPSHOT

## harbor为https时，也可配置TLS证书进行登录(docker命令的--tls的参数是docker客户端和服务器通信的加密配置，此处无法使用)
# 首先新建 `/etc/docker/certs.d/192.168.17.196:10010`目录
# 然后将ca.crt拷贝到该目录(如基于k8s运行的harbor v1.9.1，其ca.cert可在配置管理-系统设置中下载)
# 最后再docker login
```
- harbor日志目录默认在`/var/log/harbor`，默认数据存储路径为`/data`
- `harbor.cfg`修改后，需要执行`./prepare`(会在当前目录重新生成common文件夹。主要是配置信息，如nginx.conf，为docker-compose.yml中相关配置文件的映射)
- 常见问题
    - registry服务一直处于`restarting`，且日志/var/log/harbor/xxx/registry.log报错`open /etc/registry/root.crt: no such file or directory`。主要是prepare源码有问题导致时没有生成文件/etc/registry/root.crt，具体参考https://www.cnblogs.com/breezey/p/9111894.html

## Docker集群管理

- 轻量级的开源 docker 管理工具有 `portainer`，重量级的有 `rancher`。如果服务不多，集群节点不多的话一般 portainer 足以胜任；如果是大型集群的话可以考虑 rancher

### Docker远程TLS管理

- docker进程
    - docker 容器进程：就是运行在 docker 容器中的应用进程，比如你用 docker 启动的 web 应用，数据库等
    - docker 守护进程：docker 的设计是 C/S 模式，docker 守护进程运行在宿主机上，它默认监听`/var/run.docker.sock`(unix 域套接字)文件，本机的 docker 客户端是默认通过 /var/run.docker.sock 来与 docker 守护进程进行通信的
- 直接开启远程访问，无安全措施
    - `dockerd -H 0.0.0.0` 监听所有tcp连接，默认端口是6375。在systemd下，则需要修改docker.service的ExecStart
    - 在当前容器上可以执行另一容器的命令 `docker -H tcp://192.168.6.131:6375 ps`
- 安全的Docker访问(TLS)


## 启动SpringCloud应用

- 配置如下，需要启动的所有maven子项目都需要加下列配置 [^5]
    - 依赖

        ```xml
        <properties>
            <docker_plugin_version>0.4.13</docker_plugin_version>
            <!-- 此路径为如Harbor站点路径 -->
            <docker_registry>192.168.17.196:10010</docker_registry>
            <registry_project_name>shengqi</registry_project_name>
        </properties>

        <!--利用maven插件构建docker镜像-->
        <plugin>
            <groupId>com.spotify</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>${docker_plugin_version}</version>

            <executions>
                <!--设置在执行maven的package时构建镜像-->
                <execution>
                    <id>build-image</id>
                    <phase>package</phase>
                    <goals>
                        <!--执行此插件的build指令，进行docker镜像构建-->
                        <goal>build</goal>
                    </goals>
                </execution>
            </executions>
            <configuration>
                <!--私有仓库配置，默认使用localhost:2375-->
                <serverId>my-docker-registry</serverId><!-- 对应maven/setting.xml中的server，用于登录私有服务器 -->
                <registryUrl>${docker_registry}</registryUrl>
                <!--build完成后进行推送-->
                <pushImage>true</pushImage>

                <!-- 镜像名称。必须要先(在Harbor中)创建此项目且有对应项目的权限 -->
                <imageName>${docker_registry}/${registry_project_name}/${project.artifactId}:${project.version}</imageName>
                <imageTags>
                    <imageTag>latest</imageTag>
                    <imageTag>${project.version}</imageTag>
                </imageTags>
                <!-- 基于Dockerfile进行编译镜像(Dockerfile放在对应/src/main/docker目录下，如果放在父项目根目录则无法编译成功) -->
                <dockerDirectory>${project.basedir}/src/main/docker</dockerDirectory>
                <resources>
                    <resource>
                        <targetPath>/</targetPath>
                        <directory>${project.build.directory}</directory>
                        <include>${project.build.finalName}.jar</include>
                    </resource>
                </resources>
            </configuration>
        </plugin>
        ```
    - 使用私有仓库时，需要配置登录私有仓库信息。配置maven的setting.xml文件

        ```xml
        <servers>
            <server>
                <id>my-docker-registry</id>
                <username>admin</username>
                <password>Harbor12345</password>
                <configuration>
                    <email>test@aezo.cn</email>
                </configuration>
            </server>
        </servers>
        ```
    - src/main/docker/runboot.sh

        ```bash
        #!/usr/bin/env bash

        sleep 15 # 按照先后顺序进行适当睡眠
        # 此处不能通过 nohup 命令执行。nohup执行完成后会退出命令，此时容器会自动关闭掉
        java -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs/jvmlogs/ -XX:+CrashOnOutOfMemoryError -Xmx512m -jar /app/app.jar
        ```
        - 必须在src/main目录，如果在项目源码目录之外则基于Dockerfile的ADD等命令会出错(Dockerfile中ADD命令写相对路径，会出现找不到文件)
        - **sh等文件需要是linux格式，否则容易报类似错误：`: No such file or directory: bash`**
    - src/main/docker/Dockerfile

        ```bash
        FROM java:8-jre
        MAINTAINER smalle <oldinaction@qq.com>
        # 无app文件夹时，会自动创建
        ADD sq-eureka-0.0.1-SNAPSHOT.jar /app/app.jar
        # ADD wait-for-it.sh /app/
        ADD runboot.sh /app/
        # RUN chmod +x /app/wait-for-it.sh
        RUN chmod +x /app/runboot.sh
        CMD /app/runboot.sh
        # EXPOSE 9800 # 基于docker-compose则不需要
        ```
- 执行maven的package命令(会触发镜像build指令)。
    - **需要本地(打包镜像的机器)启动docker服务**，否则报错：`Exception caught: Timeout: GET https://192.168.99.100:2376/version`(此地址为windows环境变量`DOCKER_HOST`配置的docker虚拟机地址)
    - **需要本地(打包镜像的机器)docker配置insecure-registries中加入registry路径**，编辑文件`vi /etc/docker/daemon.json`。docker默认是基于https进行验证的，如果是http服务则需要配置此参数
- `docker-compose.yml`镜像管理文件
    - 其中`EUREKA_HOST=sq-eureka`是因为服务运行在不同的容器中(尽管在一台docker虚拟机上)，此处不能使用localhost，必须使用服务名进行通信。(docker-compose.yml写入中文会报错)
    - `${COMPOSE_PROJECT_NAME:-local/shengqi/}`表示取环境变量COMPOSE_PROJECT_NAME的值，无则使用默认值`local/shengqi/`(注意前面的`-`)，且默认值只适用于`version: '3'`
        - 或者在`docker-compose.yml`文件所在目录创建`.env`文件，里面定义环境变量如`COMPOSE_PROJECT_NAME=192.168.17.196:10010/shengqi/`(.env文件适用于`version: '2'`设置默认值。命令行中的环境变量 > .env文件中的环境变量 > Dockerfile文件)
        - 此时`COMPOSE_PROJECT_NAME`正好是docker-compose内置的环境变量，也可以通过`docker-compose up -p my_project_name`的方式传入COMPOSE_PROJECT_NAME值

```yml
version: '3'
services:
  sq-eureka:
    container_name: sq-eureka
    image: local/shengqi/sq-eureka:0.0.1-SNAPSHOT
    ports:
      - 9800:9800
    volumes:
      # 测试发现如果数据保存在容器的/tmp/app/logs目录则日志映射失败
      - ./logs/sq-eureka:/app/logs
    environment:
      TZ: Asia/Shanghai # 设置时区
      SPRING_PROFILES_ACTIVE: test # springboot内置环境变量
      LOG_PATH: /app/logs # logback.xml中定义的环境变量LOG_PATH

  sq-config:
    container_name: sq-config
    image: ${COMPOSE_PROJECT_NAME:-local/shengqi/}sq-config:0.0.1-SNAPSHOT
    ports:
      - 9810:9810
    volumes:
      - ./logs/sq-config:/app/logs
    depends_on:
      - sq-eureka
    # command会覆盖Dockerfile文件中的默认启动命令(CMD)
    # command: ["/app/wait-for-it.sh", "sq-eureka:9810", "--", "/app/runboot.sh"]
    # command: ["sleep", "1h"] # 调试容器启动
    environment:
      TZ: Asia/Shanghai
      SPRING_PROFILES_ACTIVE: test
      EUREKA_HOST: sq-eureka
      LOG_PATH: /app/logs

  sq-gateway:
    container_name: sq-gateway
    image: ${COMPOSE_PROJECT_NAME:-local/shengqi/}sq-gateway:0.0.1-SNAPSHOT
    ports:
      - 8000:8000
    volumes:
      - ./logs/sq-gateway:/app/logs
    depends_on:
      - sq-config
    # command: ["/app/wait-for-it.sh", "sq-config:9810", "--", "/app/runboot.sh"]
    environment:
      TZ: Asia/Shanghai
      SPRING_PROFILES_ACTIVE: test
      EUREKA_HOST: sq-eureka
      LOG_PATH: /app/logs

  sq-auth:
    container_name: sq-auth
    image: ${COMPOSE_PROJECT_NAME:-local/shengqi/}sq-auth:0.0.1-SNAPSHOT
    volumes:
      - ./logs/sq-auth:/app/logs
    depends_on:
      - sq-config
    # command: ["/app/wait-for-it.sh", "sq-config:9810", "--", "/app/runboot.sh"]
    environment:
      TZ: Asia/Shanghai
      SPRING_PROFILES_ACTIVE: test
      EUREKA_HOST: sq-eureka
      MYSQL_HOST: sq-mysql
      MYSQL_DATABASE: shengqi
      MYSQL_USER: shengqi
      MYSQL_PASSWORD: shengqi
      LOG_PATH: /app/logs
```
- 启动：在`docker-compose.yml`目录下执行`docker-compose up -d`
- 访问：http://docker-host:9800





---

参考文章

[^1]: https://www.cnblogs.com/neptunemoon/p/6512121.html
[^2]: https://blog.csdn.net/boling_cavalry/article/details/78818462 (docker私有仓库搭建与使用实战)
[^3]: https://www.cnblogs.com/pangguoping/p/7650014.html (搭建Harbor企业级docker仓库)
[^4]: https://www.cnblogs.com/panwenbin-logs/p/8007348.html
[^5]: https://blog.csdn.net/aixiaoyang168/article/details/77453974
[^6]: https://blog.csdn.net/gc889900/article/details/80319050
[^7]: https://blog.csdn.net/wuzhong8809/article/details/82500722
[^8]: https://yq.aliyun.com/articles/230067 (Docker --format 格式化输出概要操作说明)
[^9]: https://blog.csdn.net/hjxzb/article/details/84927567
[^10]: https://www.cnblogs.com/lienhua34/p/5170335.html
[^11]: https://blog.51cto.com/wzlinux/2112061
[^12]: https://tonybai.com/2016/02/15/understanding-docker-multi-host-networking/

