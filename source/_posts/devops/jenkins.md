---
layout: "post"
title: "Jenkins"
date: "2018-10-09 16:35"
categories: devops
tags: [jenkins]
---

## 简介

- [jenkins](https://jenkins.io/zh/)

## 安装编译及运行

- 本文基于`Jenkins ver. 2.181`、Jenkins ver. 2.164.3

### 直接安装运行

#### 基于Docker安装

- `docker volume create jenkins-data` 创建jenkins-data容器卷，专门存放jenkins数据
- 直接docker命令启动

```bash
# 创建镜像并运行(\后不能有空格)
docker run \
  -u root \
  -d \
  -p 2081:8080 \
  -p 50080:50000 \
  -v jenkins-data:/var/jenkins_home \
  # 映射主机的docker到容器里面，这样在容器里面就可以使用主机安装的 docker了(可以在Jenkins容器里操作宿主机的其他容器)
  -v /var/run/docker.sock:/var/run/docker.sock \
  # 映射本地maven仓库(通过jenkins安装maven会使用到)
  -v /root/.m2:/root/.m2 \
  --name jenkins \
  --restart=always \
  #jenkins/jenkins:2.181 # 在容器中无法执行docker命令
  jenkinsci/blueocean:1.18.1 # 对应jenkins版本 Jenkins ver. 2.164.3
```
- 或使用docker-compose

```yml
# 使用docker-compose
version: '3'
services:
  jenkins:
    container_name: jenkins
    image: jenkinsci/blueocean:1.18.1
    ports:
      - 2081:8080
      - 50080:50000
    volumes:
      - jenkins-data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/.m2:/root/.m2
    restart: always
    # 必须使用root用户启动
    user: root
    environment:
	  TZ: Asia/Shanghai
volumes:
  jenkins-data:
    external: true
```
- 激活：秘钥位置为/var/jenkins_home/secrets/initialAdminPassword，实际存储位置为/data/docker/volumes/jenkins-data/_data/secrets/initialAdminPassword(其中/data/docker为docker默认存储路径，jenkins-data为容器卷名)

### 手动编译运行

> 基于stable-2.164分支。具体参考：https://wiki.jenkins.io/display/JENKINS/Building+Jenkins

- 安装依赖环境：jdk1.8、maven3.5.4+
    - maven版本过低时，maven-enforcer-plugin校验报错
- 下载源码 `git clone https://github.com/jenkinsci/jenkins.git` (可检出stable-2.164分支)
- maven编译并打包
    - 通过命令行编译 **`mvn -Plight-test package -DskipTests`**
    - 或者在IDEA上操作：勾选Maven Projects - Profiles - light-test，执行Jenkins main module - Lifecyle - package
    - 编译时会生成`cli/target/generated-sources/Messages.java`
        > If your IDE complains that 'Messages' class is not found, they are missing because they are supposed to be generated. Run a Maven build once and you should see them all. If that doesn't fix the problem, make sure your IDE added target/generated-sources to the compile source roots.
    - 打包时会生成war/node(war/node/yarn)、war/node_modules，并打包静态资源文件
- Run/Debug中添加tomcat配置，Deployment选择jenkins-war:war
- debug启动tomcat。也可在远程启动debug监听 `mvnDebug jenkins-dev:run` 默认监听端口8000，可通过remote debug进行远程调试

## 构建

### 自由风格构建说明

#### 源码管理(Git)

> 此处的源码管理指在jenkins宿主机上管理任务相应源码，比如打包等操作。如ofbiz项目直接在服务器上拉取最新代码时可以不用源码管理，直接在构建中发起远程命令即可

- Repositories：git仓库配置
- Branches to build：需要构建的分支，如`origin/test`
- Additional Behaviours：扩展配置
    - Advanced clone behaviours：配置git clone，对于较多代码拉取可将其中Timeout设置成`30`分钟

#### 构建触发器

- `Build when a change is pushed to GitLab. GitLab webhook URL: http://10.10.10.10/project/test` 代码推送等变更时构建，常用(需安装`GitLab`插件)
    - Enabled GitLab triggers
        - `Push Events` 直接推送到此分支时构建(**去勾选**，如直接在git客户端将develop推送到test则无法触发。勾选会产生问题：当在gitlab接受develop到test的请求会产生2次构建)
        - `Opened Merge Request Events` 去勾选
        - `Accepted Merge Request Events` 接受合并请求时构建(**勾选**)
        - `Closed Merge Request Events` 去勾选
        - `Approved Merge Requests (EE-only)`(勾选，EE-only表示只有gitlab企业版才支持)
        - `Comments`(勾选)
        - `Comment (regex) for triggering a build` 提交备注正则构建(如：`[Jenkins Build]`)
    - Allowed branches 允许触发的分支
        - Filter branches by name - Include 基于名称进行触发，如：`test`(此时不能写成`origin/test`)
        - Secret token - Generate 生成token用于git webhook触发
    - Gitlab设置Webhooks(可设置多个)：URL和Secret Token填上文；Trigger勾选`Push events`、`Tag push events`、`Merge Request events`(gitlab提供对配置的url进行访问可达测试)。触发流程如下：
        - 当开发通过git提交代码或进行其他操作触发了gitlab此时定义的Trigger
        - 然后gitlab会对配置的URL进行post
        - 通过post的地址会进入到jenkins定义的构建任务中
        - jenkins对触发进行过滤，判断是否需要进行构建
    - 触发相对比较及时，gitlab产生后会迅速触发到jenkins(不用刷新项目页面也自动显示新的构建)。jenkins产生的构建会备注如
        - `Triggered ​by ​GitLab ​Merge ​Request ​#16: ​my-group-name/develop ​=> test` 此时是接受了develop到test的请求
        - `Started ​by ​GitLab ​push ​by smalle` 此时是直接在git客户端将develop推送到test
- `Gitlab Merge Requests Builder` 定时自动生成构建任务(需安装`GitLab`插件)

#### 构建(Build)

- `Send files or execute commands over SSH` 执行ssh服务器命令进行构建(需安装插件`Publish over SSH`)
    - `Exec command` 执行远程命令(不会记录在linux的history中)，如

        ```bash
        echo "build ofbiz start..."
        # echo $PATH # 此时打印出的是jenkins本地环境的PATH，而不是远程服务器的
        # export PATH=/opt/soft/jdk1.7.0_80/bin:/opt/soft/jdk1.7.0_80/jre/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin # 临时设置PATH为远程服务器PATH，解决java: command not found
        # 加载全局配置文件，解决java: command not found
        source /etc/profile
        cd /home/ofbiz/tools
        ./stopofbiz.sh
        cd ..
        git pull
        ./ant
        nohup bash /home/ofbiz/tools/startofbiz.sh > /dev/null 2>&1 &
        echo "build ofbiz end..."
        ```
        - 其中`source /etc/profile`为了防止报错`java: command not found`(jenkins不会自动加载环境变量)
        - 当windows启动项目bat脚本时，一直有输出的话，Dos窗口会一直处于等待状态，而jenkins的构建时会输出windows的脚本运行信息，所有Jenkins也会一直处于构建状态。此时可考虑bat脚本后台运行，如使用`.vbe`脚本对bat文件进行包装
- 调用顶层Maven目标
    - Maven Version：可选择全局工具配置中配置的maven，若无此选项可参考下文全局工具配置
    - Goals：如`clean package -Dmaven.test.skip=true`
    - 高级 - POM：可自定义pom文件位置，如`my-module-one/pom.xml`

#### 构建后操作

- `E-mail Notification` 邮件通知，其中SMTP发件地址需要和系统管理员邮件地址一致

### Pipline和Jenkinsfile构建

> 本示例Jenkins基于docker进行安装。参考：https://jenkins.io/zh/doc/tutorials/build-a-java-app-with-maven/#run-jenkins-in-docker

- 创建Pipline：新建Item - 流水线(Pipline)
- General、构建触发器、高级项目选项此示例可不用填写(实际可按需填写)
- 流水线
    - 定义：`Pipeline script`(在Jenkins配置中定义Pipeline脚本)、`Pipeline script from SCM`(从软件配置管理系统，如Git仓库获取脚本；可配置脚本所在Git仓库的文件路径)

#### Jenkinsfile

```bash
## Jenkinsfile(保存在Git仓库的jenkins目录)
# 此时是基于Git仓库进行Jenkins配置的：jenkins会先将源码获取到workspace目录，然后基于当前项目目录执行Jenkinsfile中的指令
pipeline {
    agent {
        docker {
            # 基于maven容器进行构建
            # 此示例Jenkins基于docker进行安装，由于绑定了/var/run/docker.sock，所有在Jenkins容器中可以(在宿主机上)创建启动容器
            # 构建时会在宿主机创建maven的容器(数据保存在宿主机的/root/.m2目录下)
            image 'maven:3-alpine'
            args '-v /root/.m2:/root/.m2'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn -B -DskipTests clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        # 执行交付/发布步骤
        stage('Deliver') {
            steps {
                # 此时当前目录为Git仓库根目录。此处为执行sh命令，如果命令较为复杂一般是保存在sh脚本中
                sh './jenkins/scripts/deliver.sh'
            }
        }
    }
}

## scripts/deliver.sh
mvn jar:jar install:install help:evaluate -Dexpression=project.name
VERSION=`mvn help:evaluate -Dexpression=project.version | grep "^[^\[]"`
NAME=`mvn help:evaluate -Dexpression=project.name | grep "^[^\[]"`
java -jar target/${NAME}-${VERSION}.jar
```

## 构建示例

### Jenkins+Docker+Gitlab

- 流程图如下 [^2]

![jenkins-docker-gitlab](/data/images/devops/jenkins-docker-gitlab.png)

- Springboot项目的pom.xml加入打包docker插件，并手动推送到镜像仓库(如Harbor)
- jenkins源码从gitlab拉取，并设置Gitlab Webhooks
- jenkins构建时分别执行maven打包、给服务器发送启动docker命令
    - 如果是harbor构建的镜像，可在docker容器中先登录(第一次登录会把认证信息存储起来，下次执行命令无需登录)

    ```bash
    echo "exec command start..."
    source /etc/profile
    cd /home/smalle/compose/nginx

    sudo docker-compose up -d
    echo "exec command end..."
    ```
- 上述流程需要开发先将镜像打包到镜像仓库，此处也可以通过在jenkins所在服务器打包(自动处理版本问题)
    - 构建 - Execute Shell(打包镜像)
        
        ```bash
        # Variables
        JENKINS_PROJECT_HOME='/var/jenkins_home/workspace/demo'
        HARBOR_IP='192.168.1.100:5000'
        REPOSITORIES='test/demo'
        HARBOR_USER='test'
        HARBOR_USER_PASSWD='Hello666'
        
        # 删除本地镜像(镜像历史会保存在镜像仓库)
        #docker login -u ${HARBOR_USER} -p ${HARBOR_USER_PASSWD} ${HARBOR_IP}
        IMAGE_ID=`sudo docker images | grep ${REPOSITORIES} | awk '{print $3}'`
        if [ -n "${IMAGE_ID}" ]; then
            docker rmi ${IMAGE_ID}
        fi

        # Build image.
        cd ${JENKINS_PROJECT_HOME}
        TAG=`date +%Y%m%d-%H%M%S` # 20190902-165827
        docker build --rm -t ${HARBOR_IP}/${REPOSITORIES}:${TAG} .

        # Push to the harbor registry.
        docker push ${HARBOR_IP}/${REPOSITORIES}:${TAG}
        ```
    - 构建 - over SSH

        ```bash
        HARBOR_IP='192.168.1.100:5000'
        REPOSITORIES='test/demo'
        HELM_NAME='demo'

        TAG=`curl -s http://${HARBOR_IP}/api/repositories/${REPOSITORIES}/tags | jq '.[-1]' | sed 's/\"//g'`
        sudo helm upgrade --set image.tag=${TAG} ${HELM_NAME} /root/helm-chart/test/${HELM_NAME}
        ```

## 系统管理(Manage Jenkins)

### 系统设置(Configure System)

- Jenkins Location
    - Jenkins URL：jenkins的路径，如：`http://192.168.1.100:8080/`。如果此处配置成外网，当通过内网访问时会提示`反向代理设置有误`，但是不影响使用
    - 系统管理员邮件地址：此地址需要和SMTP发件地址一致
- 邮件通知：配置smtp服务器
- Publish over SSH
    - SSH Servers：配置目标服务器，高级功能中可使用HTTP/SOCKS5代理(可能存在测试代理连接失败BUG，但是可以正常使用)

### 全局工具配置(Global Tool Configuration)

- Maven [^1]
    - 安装Jenkins默认不含maven，可通过下列方法解决
        - docker安装Jenkins时，pipeline风格可在`agant`中运行maven镜像
        - 自由风格可使用宿主机maven或通过jenkins自动安装
    - 使用宿主机maven配置：Name`maven3.6`；去勾选自动安装；MAVEN_HOME填写宿主机目录(如果是docker安装的jenkins可将本地maven安装目录挂载到容器目录如/var/maven_home，然后此处使用/var/maven_home)
    - 通过jenkins自动安装
        - 配置：Name`maven3.6`；勾选自动安装；Version`3.6.1`(之后重新进入此配置页面，可能默认不会显示之前的配置)
        - 需要安装`Maven Integration`插件
        - 进行了上述配置和插件安装默认还是不会自动安装maven，需要`构建一个maven项目`，然后构建此项目才会自动安装(安装成功后，在资源风格项目中也可以使用)
    - 自动安装的maven插件位置：`/data/docker/volumes/jenkins-data/_data/tools/hudson.tasks.Maven_MavenInstallation/maven3.6` (基于docker安装jenkins)
        - 可修改`conf/settings.xml`相关配置，如配置阿里云镜像地址
    - maven仓库默认保存在宿主机的`/root/.m2`目录

### 插件管理

#### 默认安装插件

- Git(内置git客户端)

#### 其他插件推荐

- Publish over SSH
    - [src](https://github.com/jenkinsci/publish-over-ssh-plugin)、[wiki](https://wiki.jenkins.io/display/JENKINS/Publish+Over+SSH+Plugin)
    - 利用此插件可以连接远程Linux服务器，进行文件的上传或是命令的提交，也可以连接提供SSH服务的windows服务器
    - BapSshHostConfiguration#createClient 进行服务器连接
    - 此插件1.20.1界面`Test Configuration`测试代理连接存在bug，实际是支持代理连接的
- GitLab
    - [wiki](https://github.com/jenkinsci/gitlab-plugin)
    - 允许GitLab触发Jenkins构建并在GitLab UI中显示结果
- Maven Integration
    - 使用：新建Item - 构建一个maven项目
    - 项目配置：Goals and options `clean install -Dmaven.test.skip=true`
- Localization: Chinese (Simplified)：界面汉化(汉化部分，Local插件也只能汉化部分)
- Docker plugin
    - 提供使用jenkins进行镜像编译、推送到Harbor等镜像仓库(也可通过maven插件配置docker镜像编译和推送)
- Ant(安装的插件不能通过shell命令执行)
    - 构建 - 增加构建步骤 - Invoke Ant
- Environment Injector

### 其他配置

- Manage Nodes节点管理
    - jenkins支持分布式部署，此处可设置每个节点的构建队列个数

## jenkins源码解析

- jenkins数据全部存储在内存或者文件中，启动jenkins前提前设置环境变量`JENKINS_HOME`则会在此目录生成数据文件.
    - JENKINS_HOME/plugins 为插件目录，安装的插件也都存放于此，如果需要debugger插件则将对应插件目录中的jar添加到war模块的依赖中去

### kohsuke

> kohsuke为jenkins使用的 servlet 框架，亦是jenkins创始人kohsuke名字

- 测试如访问 http://localhost:8080/api/ 、 http://localhost:8080/api/json/ 、http://localhost:8080/newJob/
- jenkins中war模块为最终打包的入口模块，此模块会引用core、cli模块。此模块`web.xml`配置如下

```xml
<servlet>
    <servlet-name>Stapler</servlet-name>
    <servlet-class>org.kohsuke.stapler.Stapler</servlet-class>
    <init-param>
        <param-name>default-encodings</param-name>
        <param-value>text/html=UTF-8</param-value>
    </init-param>
    <init-param>
        <param-name>diagnosticThreadName</param-name>
        <param-value>false</param-value>
    </init-param>
    <async-supported>true</async-supported>
</servlet>

<servlet-mapping>
    <servlet-name>Stapler</servlet-name>
    <url-pattern>/*</url-pattern>
</servlet-mapping>
```
- Hudson(core)和Jenkins(core)
    - hudson.model.Hudson extends hudson.model.Jenkins
    - hudson.model.Jenkins implements org.kohsuke.stapler.StaplerProxy, org.kohsuke.stapler.StaplerFallback
- `Stapler`内中主要的处理方法在`tryInvoke`中

```java
boolean tryInvoke(RequestImpl req, ResponseImpl rsp, Object node) throws IOException, ServletException {
    // 刚进入servlet时，此处node初始化为Hudson对象

    // 判断是否为Stapler代理对象
    if (node instanceof StaplerProxy) {}

    if (node instanceof StaplerOverridable) {}

    // 获取 org.kohsuke.stapler.MetaClass 信息
    // WebApp中会缓存一个Map存放MetaClass，无对应缓存则通过 mc = new MetaClass(this, c); 进行初始化
    // MetaClass 初始化时主要执行了 MetaClass#buildDispatchers() 进行初始化(本质是获取node对象信息组装dispatchers集合，方便后面进行url-method路由)
    // 组织dispatchers顺序(不同的类型使用Dispatcher子类进行添加)
    //      DirectoryishDispatcher
    //      HttpDeletableDispatcher
    //      this.registerDoToken(node) // 注册do开头的函数
    //      node.methods.name("doIndex").iterator()
    //      node.methods.prefix("js").iterator()
    //      node.methods.annotated(JavaScriptMethod.class).iterator()
    //      this.webApp.facets.iterator() // facets里面为模板渲染路由，如 jelly、groovy
    //      node.fields.iterator()
    //      node.methods.prefix("get") // 注册get开头的函数
    //      node.methods.name("doDynamic").iterator()
    //      this.klass.isArray() // klass为node对应的包装对象
    //      this.klass.isMap()
    MetaClass metaClass = this.webApp.getMetaClass(node);

    // 基于MetaClass进行url匹配。大部分在此处进行匹配
    Iterator var16 = metaClass.dispatchers.iterator();
    while(var16.hasNext()) {
        Dispatcher d = (Dispatcher)var16.next();
        // 参考下午 NameBasedDispatcher 源码解析
        if (d.dispatch(req, rsp, node)) {
            // 可在此处打断点，追踪执行的堆栈信息。由于后台会自动刷新，可设置断点条件：`!"/jen/ajaxBuildQueue".equals(req.getOriginalRequestURI()) && !"/jen/ajaxExecutors".equals(req.getOriginalRequestURI())`
            if (LOGGER.isLoggable(Level.FINER)) {
                LOGGER.finer("Handled by " + d);
            }

            // 返回，response已经完成数据输出
            return true;
        }
    }

    // 最后，当基于方法提取的url未匹配到，则进入到此判断，一些ajax页面是这样生成的 (如访问 http://localhost:8080/newJob/)
    if (node instanceof StaplerFallback) {
        // 获取此node的StaplerFallback对象，如 hudson.model.AllView，此类会生成一个头尾dom，中间的dom可通过ajax添加进去
        Object n = ((StaplerFallback)node).getStaplerFallback();
        
        if (n != node && n != null) {
            this.invoke(req, rsp, n); // 最终仍然进入 tryInvoke 进行匹配
            return true;
        }
        // 果然仍然未匹配到则404
    }
}
```
- `org.kohsuke.stapler.NameBasedDispatcher extends Dispatcher`。如`node.methods.prefix("get")`提出的都是通过`NameBasedDispatcher`进行包装的

```java
public final boolean dispatch(RequestImpl req, ResponseImpl rsp, Object node) throws IOException, ServletException, IllegalAccessException, InvocationTargetException {
    // req.tokens为基于url进行切片。如/api会生成一个["api"]，/api/json会生成一个["api", "json"]
    // req.tokens.peek()提取一个，如访问：http://localhost:8080/api/json/. Stapler首先会进行/api路由，执行Jenkins#getApi；处理完成后通过 req.getStapler().invoke(req, rsp, ff.invoke(req, rsp, node, new Object[0])); 进入到/json路由，此时执行hudson.model.Api#doJson
    if (req.tokens.hasMore() && req.tokens.peek().equals(this.name)) {
        if (req.tokens.countRemainingTokens() <= this.argCount) {
            return false;
        } else {
            req.tokens.next();
            // 执行路由。内部执行 req.getStapler().invoke(req, rsp, ff.invoke(req, rsp, node, new Object[0])); 跳转到下一个路由
            boolean b = this.doDispatch(req, rsp, node);
            if (!b) {
                req.tokens.prev();
            }

            return b;
        }
    } else {
        return false;
    }
}
```


---

参考文章

[^1]: https://www.jianshu.com/p/7883c251eb09
[^2]: https://www.jianshu.com/p/358bfb64e3a6


