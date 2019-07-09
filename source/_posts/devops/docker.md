---
layout: "post"
title: "docker"
date: "2017-06-25 14:03"
categories: devops
tags: [docker, arch]
---

## Docker介绍

- 支持Linux、Windows、Mac等系统
- 传统虚拟化(虚拟机)是在硬件层面实现虚拟化，需要额外的虚拟机管理应用和虚拟机操作系统层。Docker容器是在操作系统层面实现虚拟化，直接复用本地本机的操作系统，因此更加轻量级。
- Docker镜像存在版本和仓库的概念，类似Git。docker官方仓库为[Docker Hub](https://hub.docker.com/)
- [官方文档](https://docs.docker.com)
- [在线docker测试地址](https://labs.play-with-docker.com/)
- 本文基于docker版本`Server Version: 18.05.0-ce`

## 安装

- Windows
    - Windows 10直接使用windows安装包 https://hub.docker.com/editions/community/docker-ce-desktop-windows
        - 执行docker命令时提示`docker for windows could not read CA certificate`，解决https://blog.csdn.net/qq_35852248/article/details/80925154
        - 使用的网卡为`Hyper-V`，会导致VMware和DockerToolbox无法运行。可在控制面板 - 程序和功能 - 关闭windows的Hyper-V功能
    - 通过安装`DockerToolbox`，[安装文档和下载地址](https://docs.docker.com/toolbox/toolbox_install_windows/)
        - 安装完成后桌面快捷方式：`Docker Quickstart Terminal`、`kitematic`、`Oracle VM VirtualBox`
            - `Docker Quickstart Terminal` 可快速启动docker虚拟机，并进入到bash命令行
            - `kitematic`是docker推出的GUI界面工具(启动后，会后台运行docker，即自动运行docker虚拟机)
            - `Oracle VM VirtualBox`其实是一个虚拟机管理程序，**docker就运行在此default虚拟机上**
                - 下载的docker镜像在虚拟硬盘上，**default虚拟机内存默认是1G**，很容易内存溢出导致容器无法运行，可以在VirtualBox中进行调整
                - 虚拟机启动默认用户为`docker/tcuser`，可通过`ssh docker@192.168.99.100`进入此虚拟机
        - 运行`Docker Quickstart Terminal`，提示找不到`bash.exe`，可以浏览选择git中包含的bash(或者右键修改此快捷方式启动参数。目标：`"D:\software\Git\bin\bash.exe" --login -i "D:\software\Docker Toolbox\start.sh"`)。第一次启动较慢，启动成功会显示docker的图标
        - 如果DockerToolbox运行出错`Looks like something went wrong in step ´Checking status on default..`，可以单独更新安装`VirtualBox`
        - xshell连接docker虚拟机：[http://blog.aezo.cn/2017/06/24/extend/vmware/](/posts/extend/vmware.md#Oracle-VM-VirtualBox)
    - 或者安装[Boot2Docker](https://github.com/boot2docker/windows-installer)
- linux
    - `yum install docker` 安装
        - 数据文件默认保存在`/var/lib/docker`下，建议先进行修改，修改后此目录可不用保存
    - ubuntu安装
        
        ```bash
        sudo apt-get install docker.io
        sudo gpasswd -a ${USER} docker # 把当前用户加入到docker组
        cat /etc/group | grep ^docker # 查看是否添加成功
        ```
    - 启动 `systemctl start docker`

## 命令

### docker

```bash
docker   # docker 命令帮助

Management Commands:
  container   Manage containers
  image       Manage images
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
  volume      Manage volumes # 管理容器卷(可理解成就是一个目录)。https://docs.docker.com/storage/volumes/
    # volume绕过container的文件系统，直接将数据写到host机器上(默认存放路径 /var/lib/docker/volumes)
    # 修改默认存储位置，参考：https://blog.51cto.com/nanfeibobo/2091960
        # docker是1.12或以上的版本，可修改`vi /etc/docker/daemon.json`文件（如：`{"graph": "/data/docker"}`），修改后会立即生效，不需重启docker服务。
    # 映射了容器卷之后，实际数据存放再docker默认存储位置下对应的容器卷名下，如：/data/docker/volumes/jenkins-data/_data (/data/docker为docker默认存储路径，jenkins-data为某一个容器卷名)
    create  # docker volume create my-vol # 创建数据卷
    ls      # docker volume ls # 列举数据卷
    rm      # docker volume rm my-vol # 移除数据卷

Commands:
    attach    Attach to a running container                 # 当前 shell 下 attach 连接指定运行镜像
    build     Build an image from a Dockerfile              # 通过 Dockerfile 定制镜像
    commit    Create a new image from a container’s changes # 提交当前容器为新的镜像
    cp        Copy files/folders from the containers filesystem to the host path # 从容器中拷贝指定文件或者目录到宿主机中
        # docker cp demo.war sq-tomcat:/usr/local/tomcat/webapps # 向sq-tomcat容器中部署war包
    create    Create a new container                        # 创建一个新的容器，同 run，但不启动容器
    diff      Inspect changes on a container’s filesystem   # 查看 docker 容器变化
    events    Get real time events from the server          # 从 docker 服务获取容器实时事件
    exec      Run a command in an existing container        # 在已存在的容器上运行命令
    export    Stream the contents of a container as a tar archive    # 导出容器的内容流作为一个 tar 归档文件[对应 import ]
    history   Show the history of an image                  # 展示一个镜像形成历史
    images    List images                                   # 列出系统当前镜像
    import    Create a new filesystem image from the contents of a tarball   # 从tar包中的内容创建一个新的文件系统映像[对应 export]
    info      Display system-wide information               # 显示系统相关信息
        # "Server Version" 即为docker版本信息
    inspect   Return low-level information on a container   # 查看容器详细信息
		# 下文查看 --format语法
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
    rmi       Remove one or more images                     # 移除一个或多个镜像[无容器使用该镜像才可删除，否则需删除相关容器才可继续或 -f 强制删除]
    run       Run a command in a new container              # 创建一个新的容器(并启动)并运行一个命令
        -i  # 开启标准输出
        -d  # 运行容器并启动守护进程
        -t  # 开启一个伪终端(进入容器命令行，组合建ctrl+p、ctrl+q退出)
        -p  # 绑定本地端口到容器端口，可使用多个 -p 绑定多组端口. eg: -p 8080:80 (本地8080:容器80)
        -v  # 挂在本地目录或文件到容器中去做数据卷，可以使用多个 -v. eg: -v /home/smalle/logs:/temp/app，也可以使用volume数据卷
            # 目录或者文件映射，需要先在宿主机创建此文件或目录。如果要映射出来的目录中存在文件，则需要新创建对应的文件，docker不会进行初始化这些文件
        -e  # 设置环境变量，eg: -e MYSQL_HOST=localhost -e MYSQL_DATABASE=aezocn
        --name      # 指定启动容器名称
        --network   # 指定使用的网络
        --restart   # 重启模式：--restart=always失败永远重启(包括宿主主机开机后自启动)
        --link      # 链接其他容器。eg：docker run --link my_nginx my_db -d wordpress # 表示在wordpress中可以放访问被链接容器
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
    - `docker build -f /path/to/a/Dockerfile` 从Dockerfile构建镜像
- 删除镜像
    - `docker image rm c28687f7c6c8` 删除镜像(-f 强制删除)
    - `docker rmi $(docker images -f "dangling=true" -q)` **清除坏的`<none>:<none>`镜像**

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
- `docker inspect a8f590736b62` 查看容器详细(存储、网络等)。详细`--format`语法如下 [^8]
	
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

- https://www.cnblogs.com/gispathfinder/p/5871043.html
- 网络类型：host、bridge(默认)、none、container. 使用如：`docker run --network=host busybox`
    - `host` 和宿主主机使用相同的网络(包括端口，此时无需-p指定端口映射)
    - `bridge` 桥接模式。中间通过`docker0`虚拟网卡(docker默认网卡)进行网络传输。此时与外网连通，需要开启ip转发
        - 开启IP转发，此时宿主主机相当于一个NAT，容器的`eth0`通过docker规定的网络接口与`docker0`连接，`docker0`又处于宿主主机。当容器向公网发起请求时 -> 容器的`eth0` -> `docker0` -> (由于开启ip转发)宿主主机`eth0` -> 此时原地址会改成宿主主机向公网发送IP包

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
- docker部署在本地虚拟机上
    - 此时docker的宿主主机为虚拟机，虚拟机和本地机器属于同一网络。然后在docker中启动一个容器，docker会自动在宿主主机上创建一个虚拟网络，用于桥接宿主主机和容器内部网络
    - **容器会继承docker宿主主机的网络**，在容器内部是可以向外访问到宿主主机所在网络，如可以访问到本地机器。
    - 在宿主主机上默认无法访问容器网络(端口)，可以通过给此容器开启port(如：8080:80)端口映射达到宿主主机访问
    - 在本地机器中默认也是无法访问容器内网络，当开启端口映射时，可通过访问宿主主机的映射端口(8080)达到访问容器的内部端口(80)
- docker部署在内网的其他机器上，同上理。需要注意容器内部访问宿主主机内网其他机器时，需要该机器没有开启VPN，虚拟网卡(会产生多个ip)等

### docker与外网连通

## Dockerfile

- `docker build -f /home/smalle/Dockerfile` 从Dockerfile构建镜像 [^4] [^10]

    ```bash
    # This my first nginx Dockerfile
    # Version 1.0

    # FROM 基础镜像
    FROM centos

    # MAINTAINER 维护者信息
    MAINTAINER smalle 

    # ENV 设置环境变量
    ENV PATH /usr/local/nginx/sbin:$PATH

    # ADD 从本地当前目录复制文件到容器. 文件放在当前目录下，拷过去会自动解压
    ADD nginx-1.8.0.tar.gz /usr/local/
    ADD epel-release-latest-7.noarch.rpm /usr/local/
    # COPY 功能类似ADD，但是是不会自动解压文件，也不能访问网络资源

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
    CMD ["nginx"]
    ```

## docker-compose 多容器控制 [^1]

- [docker-compose](https://docs.docker.com/compose/compose-file/) 是用来做docker的多容器控制，默认基于`docker-compose.yml`来进行配置
- `pip install docker-compose` 安装(为python实现)
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
      --project-directory PATH    Specify an alternate working directory
                                  (default: the path of the Compose file)

    Commands:
      build              Build or rebuild services
      bundle             Generate a Docker bundle from the Compose file
      config             Validate and view the Compose file # 校验配置文件语法格式
      create             Create services
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
      version            Show the Docker-Compose version information
    ```
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
      - /home/smalle/data/nginx/:/bitnami/nginx/
	environment:
	  TZ: Asia/Shanghai # 设置容器时区
    restart: always # 启动模式，always表示失败永远重启（包括宿主主机开机后自启动）
  sq-mysql:
    container_name: sq-mysql
    image: mysql/mysql-server:5.7 # 如果本地没有此镜像，会默认从中央仓库拉取镜像
    ports:
      - 13307:3306
    volumes:
      # 用于保存数据文件。虚拟机中无此/home/smalle/data/test目录时，会自动创建
	    - /home/smalle/data/test:/var/lib/mysql
    # entrypoint会覆盖Dockerfile中的ENTRYPOINT，command会覆盖CMD。参考Dockerfile中的ENTRYPOINT和CMD比较。docker-compose restart也会执行此命令
    # entrypoint:
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
    environment: # 当做环境变量传入容器
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
    # 基于Dockerfile文件构建镜像时使用的属性
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
- `$VARIABLE`和`${VARIABLE}`两种写法都支持，可以使用双美元符号(`$$`)来转义美元符号。如果使用的是2.1文件格式，还可以在一行中设置默认的值：
    - `${VARIABLE:-default}` 当VARIABLE没有设置或为空值时使用default值
    - `${VARIABLE-default}` 仅当VARIABLE没有设置时使用default值
- 容器启动先后顺序问题 [^7]
    - `depends_on`表示再启动容器时会先启动依赖的服务，但并不能控制等依赖启动完成才启动此服务
    - 基于`wait-for-it.sh`解决先后启动。[脚本代码](https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh)
        - 需要将`wait-for-it.sh`打包到容器中，即在Dockerfile中将文件从本地目录复制到容器目录，如/app目录
        - docker-compose.yml中基于command命令配置启动命令，command会覆盖Dockerfile文件中的默认启动命令(CMD)。如：`command: ["/app/wait-for-it.sh", "sq-eureka:9810", "--", "/app/runboot.sh"]`
- 容器网络
	- 同一 docker-compose 配置文件中的多个容器默认处于统一网络，不同 docker-compose 配置文件处于不同网络。每个 docker-compose 配置文件会产生一个xxx_default的网络(查看网络：docker network ls)；如果 docker-compose 配置文件(假如所在目录为mydir)中只有一个服务则默认生成`mydir_服务名_default`，如果有多个服务则会生成一个`123456789_default`的网络
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
      # 基于普通目录映射
      - /var/run/docker.sock:/var/run/docker.sock
    user: root # 定义启动用户
    # ...
volumes:
  jenkins-data:
    # 需提前创建此容器卷，如果无external: true则会自动创建容器卷
    external: true
```

## 常用docker镜像

> https://hub.docker.com

- 官方提供的centos镜像，无netstat、sshd等服务，测试可进行安装
    - 安装netstat：`yum install net-tools`
    - 安装sshd：`yum install openssh-server`，启动如下：
        - `mkdir -p /var/run/sshd`
        - `/usr/sbin/sshd -D &`
- `java:8-jre` 一般是docker-compose中引入

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
  listen  80; # 此处必须是容器中的端口
  # server_name  localhost;

  # **启用后响应头中会包含`Content-Encoding: gzip`**
  gzip on; #开启gzip压缩输出
  # 压缩类型，默认就已经包含text/html(但是vue打包出来的js需要下列定义才会压缩)
  gzip_types text/plain application/x-javascript application/javascript text/javascript text/css application/xml text/xml;
  
  access_log /var/log/nginx/test.access.log main;

  location = /index.html {
    add_header Cache-Control "no-cache, no-store";
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
    # command: /bin/sh -c "sed -i 's/<Connector/<Connector URIEncoding=\"UTF-8\"/' $$CATALINA_HOME/conf/server.xml && catalina.sh run"
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
docker tag 7042885a156a 192.168.17.196:5000/nginx:sm_1 # 192.168.17.196:5000/nginx 很重要，之后可以推送到私有仓库192.168.17.196:5000(ip地址一定要一样)，推送上去的镜像为nginx:sm_1
## 在docker-client上推送镜像到docker-server(推送成功后，在docker-server上通过docker images也是无法看到镜像的)
docker push 192.168.17.196:5000/nginx
# 此时删除docker-client上关于nginx的镜像，再运行下列命令时，会检查本地没有则从私服上获取并运行
docker run -itd -p 8080:80 192.168.17.196:5000/nginx:sm_1
```

### 基于Harbor搭建私有仓库服务器方式 [^3]

- [Harbor](https://goharbor.io/)、[github](https://github.com/goharbor/harbor)
- Harbor是基于GO开发的一个用于存储和分发Docker镜像的企业级Registry服务器(私有仓库)，提供web界面访问，角色控制。其提供镜像复制功能：镜像可以在多个Registry实例中复制（同步），尤其适合于负载均衡，高可用，混合云和多云的场景
- 安装(内部包含一个registry服务器的安装)

```bash
## 安装docker-compose
yum install python-pip
pip install  docker-compose
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

## 推送数据到私有仓库（默认含有一个library公共项目，也可自行创建其他项目）
docker tag 7042885a156a 192.168.17.196:10010/library/nginx:sm_1
# 登录(admin/Harbor12345)。登录成功后会保存秘钥到`~/.docker/config.json`，下次则无需登录
# 此处端口应该为10010。harbor内部默认也启动了一个registry，端口为5000，并通过nginx做了转发，因此对外端口只有10010
# 可参看上文修改/etc/docker/daemon.json的配置为：{"insecure-registries": ["192.168.17.196:10010"]}
docker login 192.168.17.196:10010
docker push 192.168.17.196:10010/library/nginx:sm_1
# 如果是私有仓库pull也需要登录
docker pull 192.168.17.196:10010/sq-eureka/sq-eureka:0.0.1-SNAPSHOT

# 也可配置TLS证书
```
- harbor日志目录默认在`/var/log/harbor`，默认数据存储路径为`/data`
- `harbor.cfg`修改后，需要执行`./prepare`(会在当前目录重新生成common文件夹。主要是配置信息，如nginx.conf，为docker-compose.yml中相关配置文件的映射)
- 常见问题
    - registry服务一直处于`restarting`，且日志/var/log/harbor/xxx/registry.log报错`open /etc/registry/root.crt: no such file or directory`。主要是prepare源码有问题导致时没有生成文件/etc/registry/root.crt，具体参考https://www.cnblogs.com/breezey/p/9111894.html

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
        java -Xmx512m -jar /app/app.jar
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
      SPRING_PROFILES_ACTIVE: test # 内置环境变量
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


