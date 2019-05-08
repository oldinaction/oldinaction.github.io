---
layout: "post"
title: "docker"
date: "2017-06-25 14:03"
categories: arch
tags: [docker]
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
    - 通过安装`DockerToolbox`，[安装文档和下载地址](https://docs.docker.com/toolbox/toolbox_install_windows/)
        - 安装完成后桌面快捷方式：`Docker Quickstart Terminal`、`kitematic`、`Oracle VM VirtualBox`
            - `kitematic`是docker推出的GUI界面工具(启动后，会后台运行docker，即自动运行docker虚拟机)
            - `Oracle VM VirtualBox`其实是一个虚拟机，**docker就运行在此虚拟机上**（下载的docker镜像在虚拟硬盘上，虚拟机启动默认用户为`docker/tcuser`）
        - 运行`Docker Quickstart Terminal`，提示找不到`bash.exe`，可以浏览选择git中包含的bash(或者右键修改此快捷方式启动参数。目标：`"D:\software\Git\bin\bash.exe" --login -i "D:\software\Docker Toolbox\start.sh"`)。第一次启动较慢，启动成功会显示docker的图标
        - 如果DockerToolbox运行出错`Looks like something went wrong in step ´Checking status on default..`，可以单独更新安装`VirtualBox`
        - xshell连接docker虚拟机：[http://blog.aezo.cn/2017/06/24/extend/vmware/](/posts/extend/vmware.md#Oracle-VM-VirtualBox)
    - 或者安装[Boot2Docker](https://github.com/boot2docker/windows-installer)
- linux
    - `yum install docker` 安装
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

Commands:
    attach    Attach to a running container                 # 当前 shell 下 attach 连接指定运行镜像
    build     Build an image from a Dockerfile              # 通过 Dockerfile 定制镜像
    commit    Create a new image from a container’s changes # 提交当前容器为新的镜像
    cp        Copy files/folders from the containers filesystem to the host path # 从容器中拷贝指定文件或者目录到宿主机中
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
    kill      Kill a running container                      # kill 指定 docker 容器
    load      Load an image from a tar archive              # 从一个 tar 包中加载一个镜像[对应 save]
    login     Register or Login to the docker registry server    # 注册或者登陆一个 docker 源服务器
    logout    Log out from a Docker registry server         # 从当前 Docker registry 退出
    logs      Fetch the logs of a container                 # 输出当前容器日志信息
    port      Lookup the public-facing port which is NAT-ed to PRIVATE_PORT # 查看映射端口对应的容器内部源端口
    pause     Pause all processes within a container        # 暂停容器
    ps        List containers                               # 列出容器列表
    pull      Pull an image or a repository from the docker registry server # 从docker镜像源服务器拉取指定镜像或者库镜像
    push      Push an image or a repository to the docker registry server # 推送指定镜像或者库镜像至docker源服务器
    restart   Restart a running container                   # 重启运行的容器
    rm        Remove one or more containers                 # 移除一个或者多个容器
    rmi       Remove one or more images                     # 移除一个或多个镜像[无容器使用该镜像才可删除，否则需删除相关容器才可继续或 -f 强制删除]
    run       Run a command in a new container              # 创建一个新的容器(并启动)并运行一个命令
        -i  # 开启标准输出
        -d  # 运行容器并启动守护进程
        -t  # 开启一个伪终端(进入容器命令行，组合建ctrl+p、ctrl+q退出)
        -p  # 绑定本地端口到容器端口，可使用多个 -p 绑定多组端口. eg: -p 8080:80 (本地8080:容器80)
        -v  # 挂在本地目录或文件到容器中去做数据卷，可以使用多个 -v. eg: -v /home/smalle/logs:/temp/app
        -e  # 设置环境变量，eg: -e MYSQL_HOST=localhost -e MYSQL_DATABASE=aezocn
        --name      # 指定启动容器名称
        --network   # 指定使用的网络
        --restart   # 重启模式：always失败永远重启(包括宿主主机开机后自启动)
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
- `docker ps` 列出运行的容器
    - `docker ps -a` 列举所有容器
- `docker exec -it (CONTAINER_ID | CONTAINER_NAME) /bin/bash` 运行容器中的命令，此时会进入容器shell
    - `docker exec -dt (CONTAINER_ID | CONTAINER_NAME) ls` **运行容器中的命令，但是不会进入容器**
    - `docker exec -it (CONTAINER_ID | CONTAINER_NAME) /bin/bash -c 'ls'` 也不会进入容器
- `docker attach (CONTAINER_ID | CONTAINER_NAME)` 进入某运行的容器 **(组合建ctrl+p、ctrl+q退出)**
- `docker inspect a8f590736b62` 查看容器详细
- `docker rm a8f590736b62` 删除容器ID为a8f590736b62的容器
- `docker rename 原容器名 新容器名` 重命名容器名(运行也可重命名)

## docker网络

- 网络类型：host、bridge、none、container. 使用如：`docker run --network=host busybox`
    - `host` 和宿主主机使用相同的网络(包括端口，此时无需-p指定端口映射)
    - `bridge` 桥接模式. 中间通过`docker0`虚拟网卡(docker默认网卡)进行网络传输。此时与外网连通，需要开启ip转发
        - 开启IP转发，此时宿主主机相当于一个NAT，容器的`eth0`通过docker规定的网络接口与`docker0`连接，`docker0`又处于宿主主机。当容器向公网发起请求时 -> 容器的`eth0` -> `docker0` -> (由于开启ip转发)宿主主机`eth0` -> 此时原地址会改成宿主主机向公网发送IP包

        ```bash
        ## 临时开启转发(1是允许转发，0不允许转发)
        echo 1 > /proc/sys/net/ipv4/ip_forward
        ## 永久修改
        # 设置 net.ipv4.ip_forward = 1
        sudo vi /etc/sysctl.conf
        # 是文件生效
        sudo sysctl -p /etc/sysctl.conf
        ```
- docker部署在本地虚拟机上
    - 此时docker的宿主主机为虚拟机，虚拟机和本地机器属于同一网络。然后在docker中启动一个容器，docker会自动在宿主主机上创建一个虚拟网络，用于桥接宿主主机和容器内部网络
    - **容器会继承docker宿主主机的网络**，在容器内部是可以向外访问到宿主主机所在网络，如可以访问到本地机器。
    - 在宿主主机上默认无法访问容器网络(端口)，可以通过给此容器开启port(如：8080:80)端口映射达到宿主主机访问
    - 在本地机器中默认也是无法访问容器内网络，当开启端口映射时，可通过访问宿主主机的映射端口(8080)达到访问容器的内部端口(80)
- docker部署在内网的其他机器上，同上理。需要注意容器内部访问宿主主机内网其他机器时，需要该机器没有开启VPN，虚拟网卡(会产生多个ip)等

### docker与外网连通

## Dockerfile [^4]

- `docker build -f /path/to/a/Dockerfile` 从Dockerfile构建镜像

    ```Dockerfile
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

    # CMD 构建容器后调用，也就是在容器启动时才进行调用
    CMD ["nginx"]
    ```

## docker-compose 多容器控制 [^1]

- `docker-compose` 是用来做docker的多容器控制，默认基于`docker-compose.yml`来进行配置
- `pip install docker-compose` 安装(为python实现)
- 命令

    ```py
    docker-compose up # 创建并启动容器(在docker-compose.yml文件所在目录执行)。docker-compose up -d 后台运行
    docker-compose ps # 查看运行的容器
    docker-compose start my_service_name # 启动某个服务(docker-compose.yml有多个服务时，可以只运行其中一个)
    docker-compose stop my_service_name # 停止某个服务
    docker-compose restart my_service_name # 重启某个服务
    docker-compose -f my_docker-compose.yml up -d
    docker-compose rm my_service_name # 删除老旧的服务
    docker-compose logs my_service_name # 获取日志
    ```
- `docker-compose.yml`示例。具体参考：https://docs.docker.com/compose/compose-file/compose-file-v2
    - 可修改`docker-compose.yml`文件配置，重新启动容器，不会有产生多的镜像或容器

    ````yml
    version: 3 # 表示使用第3代语法来构建
    services:
        nginx: # 服务名
            container_name: smalle-nginx # 创建的容器名(默认是是`服务名_1`)
            image: bitnami/nginx:latest # 镜像名(如果本地没有此镜像，会默认从中央仓库拉取镜像)
            # 网络类型使用host模式(即使用宿主主机的网络，此时不能配置ports信息，端口也全部使用的是主机的端口)
            # network_mode: host
            ports: # 端口映射(本地端口:容器端口的映射。windows的本地端口为运行docker的虚拟机端口。只是监听此端口，并不会占用此端口)
                - 80:80
                - 1443:443
            volumes: # 数据卷映射(本地路径:容器路径。windows的本地路径为运行docker的虚拟机路径。不要把 docker 当做数据容器来使用，数据一定要用 volumes 放在容器外面。如日志文件需要进行映射)
                - /home/smalle/data/nginx/:/bitnami/nginx/
            restart: always # 启动模式，always表示失败永远重启（包括宿主主机开机后自启动）
        sq-mysql:
            container_name: sq-mysql
            image: mysql/mysql-server:5.7 # 如果本地没有此镜像，会默认从中央仓库拉取镜像
            ports:
                - 3306:3306
            volumes:
                # 用于保存数据文件。虚拟机中无此/home/smalle/data/test目录时，会自动创建
                - /home/smalle/data/test:/var/lib/mysql
            environment:
        #      MYSQL_ROOT_HOST: '%'
        #      MYSQL_ROOT_PASSWORD: root
                MYSQL_HOST: localhost
                # 创建容器时会自动创建此数据库和用户
                MYSQL_DATABASE: shengqi
                MYSQL_USER: shengqi
                MYSQL_PASSWORD: shengqi
            restart: always # 启动失败这重复启动（并且当docker虚拟机启动后，会自动启动此容器）
        wordpress:
            image: bitnami/wordpress:latest
            depends_on: # 依赖的服务名。并不能控制等依赖启动完成才启动此服务
                - mariadb
                - nginx
            # links: # 依赖的镜像
            environment: # 当做环境变量传入容器
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
    ```

## 常用docker镜像

> https://hub.docker.com

- 官方提供的centos镜像，无netstat、sshd等服务
    - 安装netstat：`yum install net-tools`
    - 安装sshd：`yum install openssh-server`，启动如下：
        - `mkdir -p /var/run/sshd`
        - `/usr/sbin/sshd -D &`
- `java:8-jre`
- `mysql/mysql-server:5.7`
    - 数据文件路径：`/var/lib/mysql`

    ```yml
    version: 3
    services:
        aezo-mysql:
            container_name: sq-mysql
            image: mysql/mysql-server:5.7 # 如果本地没有此镜像，会默认从中央仓库拉取镜像
            ports:
                - 3306:3306
            volumes:
                # 用于保存数据文件。虚拟机中无此/home/smalle/data/test目录时，会自动创建
                - /home/smalle/data/test:/var/lib/mysql
            environment:
        #      MYSQL_ROOT_PASSWORD: root
                MYSQL_HOST: localhost
                # 创建容器时会自动创建此数据库和用户
                MYSQL_DATABASE: shengqi
                MYSQL_USER: shengqi
                MYSQL_PASSWORD: shengqi
    ```
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

- Registry：docker仓库注册服务器，用于管理镜像仓库，起到的是服务器的作用。
- Repository：docker镜像仓库，用于存储具体的docker镜像，起到的是仓库存储作用。

### 命令安装方式

- docker-server

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
# 永久修改仓库地址
vi /etc/docker/daemon.json # 无则新增
# 并加入下列内容(docker客户端默认使用https访问仓库)
{"insecure-registries": ["192.168.17.196:5000"]} # insecure-registries可使用http访问
# 重启docker-client
## 在docker-client保存镜像(基于镜像7042885a156a打tag)
docker tag 7042885a156a 192.168.17.196:5000/nginx:sm_1 # 192.168.17.196:5000/nginx 很重要，之后可以推送到私有仓库192.168.17.196:5000(ip地址一定要一样)，推送上去的镜像为nginx:sm_1
## 在docker-client上推送镜像到docker-server(推送成功后，在docker-server上通过docker images也是无法看到镜像的)
docker push 192.168.17.196:5000/nginx
# 此时删除docker-client上关于nginx的镜像，再运行下列命令时，会检查本地没有则从私服上获取并运行
docker run -itd -p 8080:80 192.168.17.196:5000/nginx:sm_1
```

### 基于Harbor搭建私有仓库服务器方式 [^3]

- [Harbor](https://goharbor.io/)是一个用于存储和分发Docker镜像的企业级Registry服务器，提供web界面访问，角色控制。其提供镜像复制功能：镜像可以在多个Registry实例中复制（同步），尤其适合于负载均衡，高可用，混合云和多云的场景
- 安装(内部包含一个registry服务器的安装)

```bash
## 安装docker-compose
yum install python-pip
pip install  docker-compose
docker-compose --version

## 在线安装Harbor
wget -P /usr/local/src/ https://github.com/vmware/harbor/releases/download/v1.2.0/harbor-online-installer-v1.2.0.tgz
cd /usr/local/src/
tar zxf harbor-online-installer-v1.2.0.tgz -C /usr/local/
cd /usr/local/harbor/
vi /usr/local/harbor/harbor.cfg # 修改配置。最少修改其中的hostname(如hostname=192.168.17.196:10010)，也可修改admin账户密码(默认Harbor12345)
/usr/local/harbor/install.sh

## 启动
docker-compose up -d # 启动Harbor(/usr/local/harbor/)
docker-compose ps # 查看启动状态(需要都是UP)
docker-compose stop # 停止Harbor
# 访问(默认用户密码：admin/Harbor12345。第一次需要等一会再访问)。可修改docker-compose.yml中的映射端口来配置主页地址
# 此处修改了harbor.cfg中的hostname=192.168.17.196:10010，且修改了docker-compose.yml中80的映射端口为10010
http://192.168.17.196:10010/harbor/sign-in

## 推送（默认含有一个library公共项目，也可自行创建其他项目）
docker tag 7042885a156a 192.168.17.196:10010/library/nginx:sm_1
# 登录(admin/Harbor12345)
# 此处端口应该为10010。harbor内部默认也启动了一个registry，端口为5000，并通过nginx做了转发，因此对外端口只有10010
# 可参看上文修改/etc/docker/daemon.json的配置为：{"insecure-registries": ["192.168.17.196:10010"]}
docker login 192.168.17.196:10010
docker push 192.168.17.196:10010/library/nginx:sm_1

# 也可配置TLS证书
```
- 常见问题
    - harbor日志目录默认在`/var/log/harbor`
    - `harbot.cfg`修改后，需要执行`./prepare`(会在当前目录重新生成common文件夹。主要是配置信息，如nginx.conf，为docker-compose.yml中相关配置文件的映射)
    - registry服务一直处于`restarting`，且日志/var/log/harbor/xxx/registry.log报错`open /etc/registry/root.crt: no such file or directory`。主要是prepare源码有问题导致时没有生成文件/etc/registry/root.crt，具体参考https://www.cnblogs.com/breezey/p/9111894.html

## 启动SpringCloud应用

- 配置如下，需要启动的所有maven子项目都需要加下列配置 [^5]
    - 依赖

        ```xml
        <properties>
            <docker_plugin_version>0.4.13</docker_plugin_version>
            <docker_registry>192.168.17.196:10010</docker_registry>
            <docker_image_prefix>shengqi</docker_image_prefix>
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

                <!-- 镜像名称 -->
                <imageName>${docker_registry}/${docker_image_prefix}/${project.artifactId}:${project.version}</imageName>
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
        java -Xmx500m -jar /app/app.jar
        ```
        - 必须在src/main目录，如果在项目源码目录之外则基于Dockerfile的ADD等命令会出错(Dockerfile中ADD命令写相对路径，会出现找不到文件)
        - 文件需要是linux格式，否则容易报错：`: No such file or directoryv: bash`
    - src/main/docker/Dockerfile

        ```Dockerfile
        FROM java:8-jre
        MAINTAINER smalle <oldinaction@qq.com>
        # 无app文件夹时，会自动创建
        ADD sq-eureka-0.0.1-SNAPSHOT.jar /app/app.jar
        ADD runboot.sh /app/
        RUN bash -c 'touch /app/app.jar'
        WORKDIR /app
        RUN chmod +x runboot.sh
        CMD /app/runboot.sh
        EXPOSE 9800
        ```
- 执行maven的package命令(会触发镜像build指令)，此时本地需要启动docker服务
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
                - /home/data/project/shengqi/logs:/home/data/project/shengqi/logs

        sq-config:
            container_name: sq-config
            image: ${COMPOSE_PROJECT_NAME:-local/shengqi/}sq-config:0.0.1-SNAPSHOT
            ports:
                - 9810:9810
            volumes:
                - /home/data/project/shengqi/logs:/home/data/project/shengqi/logs
            depends_on:
                - sq-eureka
            environment:
                EUREKA_HOST: sq-eureka
                EUREKA_PORT: 9800

        sq-gateway:
            container_name: sq-gateway
            image: ${COMPOSE_PROJECT_NAME:-local/shengqi/}sq-gateway:0.0.1-SNAPSHOT
            ports:
                - 8000:8000
            volumes:
                - /home/data/project/shengqi/logs:/home/data/project/shengqi/logs
            depends_on:
                - sq-eureka
            environment:
                EUREKA_HOST: sq-eureka
                EUREKA_PORT: 9800

        sq-auth:
            container_name: sq-auth
            image: ${COMPOSE_PROJECT_NAME:-local/shengqi/}sq-auth:0.0.1-SNAPSHOT
            volumes:
                - /home/data/project/shengqi/logs:/home/data/project/shengqi/logs
            depends_on:
                - sq-eureka
            environment:
                EUREKA_HOST: sq-eureka
                EUREKA_PORT: 9800
                MYSQL_HOST: sq-mysql
                MYSQL_DATABASE: shengqi
                MYSQL_USER: shengqi
                MYSQL_PASSWORD: shengqi
        #      - REDIS_HOST=redis
        #      - REDIS_PORT=6379
        #      - RABBIT_MQ_HOST=rabbitmq
        #      - RABBIT_MQ_HOST=5672
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
