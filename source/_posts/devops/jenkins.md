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

#### 直接 docker 命令启动

- `docker volume create jenkins-data` 创建 jenkins-data 容器卷，专门存放 jenkins 数据
- 启动

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
  # jenkins/jenkins:2.181则必须再挂载此命令；jenkinsci/blueocean无需
  -v /usr/bin/docker:/usr/bin/docker:ro \
  # 映射本地maven仓库(通过jenkins安装maven会使用到)
  -v /root/.m2:/root/.m2 \
  --name jenkins \
  --restart=always \
  #jenkins/jenkins:2.181
  jenkinsci/blueocean:1.18.1 # 对应jenkins版本 Jenkins ver. 2.164.3。默认包含(Blue Ocean)
```

#### 基于 docker-compose

```yml
# 使用docker-compose
version: "3"
services:
  jenkins:
    container_name: jenkins
    image: jenkinsci/blueocean:1.18.1
    # 解决时区问题，重新构建镜像
    #build:
    #  context: .
    ports:
      - 2081:8080
      - 50080:50000
    volumes:
      - jenkins-data:/var/jenkins_home
      # 必须是jenkinsci/blueocean才可在容器中执行docker命令，jenkins/jenkins镜像没有测试成功
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker:ro
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

- 激活：秘钥位置为/var/jenkins_home/secrets/initialAdminPassword，实际存储位置为/data/docker/volumes/jenkins-data/\_data/secrets/initialAdminPassword(其中/data/docker 为 docker 默认存储路径，jenkins-data 为容器卷名)
- jenkinsci/blueocean 容器中时区为 UTC 无法修改问题(jenkins 程序时区正常)，可在`docker-compose.yaml`所在目录创建`Dockerfile`文件用于重新构建镜像

  ```bash
  FROM jenkinsci/blueocean:1.18.1
  # 使用root用户安装tzdata
  USER root
  RUN /bin/sh -c apk --no-cache add tzdata
  # 切回jenkins用户
  USER jenkins
  ```

  - `docker-compose up -d --build` 重新编译

#### k8s-helm 启动

参考[http://blog.aezo.cn/2019/06/22/devops/helm/](/_posts/devops/helm.md#Jenkins)

### 手动编译运行

> 基于 stable-2.164 分支。具体参考：https://wiki.jenkins.io/display/JENKINS/Building+Jenkins

- 安装依赖环境：jdk1.8、maven3.5.4+
  - maven 版本过低时，maven-enforcer-plugin 校验报错
- 下载源码 `git clone https://github.com/jenkinsci/jenkins.git` (可检出 stable-2.164 分支)
- maven 编译并打包
  - 通过命令行编译 **`mvn -Plight-test package -DskipTests`**
  - 或者在 IDEA 上操作：勾选 Maven Projects - Profiles - light-test，执行 Jenkins main module - Lifecyle - package
  - 编译时会生成`cli/target/generated-sources/Messages.java`
    > If your IDE complains that 'Messages' class is not found, they are missing because they are supposed to be generated. Run a Maven build once and you should see them all. If that doesn't fix the problem, make sure your IDE added target/generated-sources to the compile source roots.
  - 打包时会生成 war/node(war/node/yarn)、war/node_modules，并打包静态资源文件
- Run/Debug 中添加 tomcat 配置，Deployment 选择 jenkins-war:war
- debug 启动 tomcat。也可在远程启动 debug 监听 `mvnDebug jenkins-dev:run` 默认监听端口 8000，可通过 remote debug 进行远程调试

## Pipeline

- [官网入门](https://www.jenkins.io/zh/doc/book/pipeline/)
- [pipeline 支持的 steps 及支持的相关插件](https://www.jenkins.io/doc/pipeline/steps/)
- [基本的steps命令](https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/)
- 内置文档
    - 对于插件的使用可以参考 Pipeline 脚本编辑处的**流水线语法**：https://<jenkins-host>/job/<my-job-name>/pipeline-syntax/
    - 全局变量：https://<jenkins-host>/pipeline-syntax/globals
- 遵循 Groovy 语法规则
- 案例参考下文[Pipeline相关](#构建示例)
- 一个 Jenkinsfile 就是一个文本文件，Pipeline 支持两种形式，一种是 Declarative 管道，一个是 Scripted 管道

```groovy
// 1.Declarative风格 比较常用
pipeline {
    agent any

    stages {
        stage('编译阶段') {
            steps {
                echo 'Building..'
            }
        }
        stage('部署阶段') {
            steps {
                echo 'Deploying..'
            }
        }
    }
}

// 2.Scripted风格
node {
    stage('Build') {
        //
    }
    stage('Deploy') {
        //
    }
}

// 3.或者直接调用命令，下文[常用插件命令-调用凭证即可直接运行](#常用插件命令)
```

- [常用关键字](https://www.jenkins.io/doc/book/pipeline/syntax/)

```groovy
// 系统设置中设置global pipeline libraries，名字为jenkins_library，添加git地址共享库
library "jenkins_library"

def context = [:] // 定义一个全局变量(map)，但是不能在自定义函数中使用

// pipeline前面可以有其他代码，例如导入语句，和其他功能代码
pipeline {
    // agent 指令指定整个管道或某个特定的stage的执行环境。它的参数可用使用：
        // any - 任意一个可用的agent
        // none - 如果放在pipeline顶层，那么每一个stage都需要定义自己的agent指令
        // label - 在jenkins环境中指定标签的agent上面执行，比如agent { label 'my-defined-label' }
        // node - agent { node { label 'labelName' } } 和 label一样，但是可用定义更多可选项
        // docker - 指定在docker容器中运行
        // dockerfile - 使用源码根目录下面的Dockerfile构建容器来运行
    agent any
    // agent { label "jnlp-agent" }

    // 定义键值对的环境变量
    environment {
        APP_VERSION = 'v1.0.0'
        BROWSER_NAME = 'chrome'
    }

    // 定义自动安装并自动放入PATH里面的工具集合，工具名称必须预先在Jenkins中配置好了 → Global Tool Configuration
    tools {
        maven 'apache-maven-3.0.1'
    }

    // 由一个或多个stage指令组成，stages块也是核心逻辑的部分. 可进行嵌套
    stages {
        stage('Test') {
            // when指令允许Pipeline根据给定条件确定是否应执行该阶段。该when指令必须至少包含一个条件。如果when指令包含多个条件，则所有子条件必须返回true才能执行该阶段
            when {
                branch 'production'
                // environment name: 'DEPLOY_TO', value: 'production' // 环境变量
                // expression { return true } // 表达式返回true时触发
                // 还有如equals、allOf等
            }
            steps {
                // 基本的steps命令(其他命令不能再steps中，可以使用一个script包裹) https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/
                println 'hello...' // println可以打印对象，echo只能打印字符串
                echo 'Test..'
                echo "Running on ${env.BROWSER_NAME}"

                script {
                    context.flag = false // 给全局变量赋值
                    def browsers = ['chrome', 'firefox']
                    for (int i = 0; i < browsers.size(); ++i) {
                        echo "Testing the ${browsers[i]} browser"
                        if( browsers[i] == env.BROWSER_NAME ) {
                            return
                        }
                    }
                }

                myDir = 'test'
                sh "printenv"
                echo gitlabMergeRequestTitle // 可正常打印
                echo evn.gitlabMergeRequestTitle // 可正常打印
                sh 'echo ${myDir}' // 无法获取变量
                sh "echo ${myDir}" // 可以获取变量
                sh """echo ${myDir}""" // 可换行文本，可以获取变量('''的可换行文本不行)
                sh "echo ${gitlabMergeRequestTitle}" // 无法获取到环境比变量。gitlab hook时会注入gitlabMergeRequestTitle
                sh "echo ${evn.gitlabMergeRequestTitle}" // 无法获取环境比变量
                sh "echo \$gitlabMergeRequestTitle" // 可以打印出环境比变量(获取shell的环境变量，防止被groovy注入的当前脚本变量)
                sh "echo \$evn\\.gitlabMergeRequestTitle" // 可以打印出环境比变量

                result = sh (script: "cat test.txt | grep 123", returnStatus: true) // 返回执行状态。找到了返回0，未找到返回1
                result = sh (script: "cat test.txt", returnStdout: true) // 返回命令的输出
            }
            // stages {}
        }
        stage('steps test') {
            steps {
                // error: 抛出异常，中断整个pipeline
                // timeout闭包内运行的步骤超时时间
                timeout(50) {
                    // 一直循环运行闭包内容，直到return true，经常与timeout同时使用
                    waitUntil {
                        script {
                            def r = sh script: 'curl http://xxx', returnStatus: true
                            return (r == 0)
                        }
                    }
                }
                // 闭包内脚本重复执行次数
                retry(10){
                    script {
                        sh script: 'curl http://xxx', returnStatus: true
                    }
                }
                // 暂停pipeline一段时间，单位为秒
                sleep(20)
            }
        }
        stage("parallel test") {
            parallel {
                stage('Stage1') {
                    agent { label "test1" }
                    steps {
                        echo "在 agent test1 上执行的并行任务 1."
                    }
                }
                stage('Stage2') {
                    agent { label "test2" }
                    steps {
                        echo "在 agent test2 上执行的并行任务 2."
                    }
                }
            }
        }
    }
    // post：管道执行结束后要进行的操作。支持在里面定义很多Conditions块
        // always 不管返回什么状态都会执行
        // changed 如果当前管道返回值和上一次已经完成的管道返回值不同时候执行
        // failure 当前管道返回状态值为failed时候执行，在Web UI界面上面是红色的标志
        // success 返回success时候执行，在Web UI界面上面是绿色的标志
        // unstable 返回状态值为unstable时执行，通常因为测试失败，代码不合法引起的。在Web UI界面上面是黄色的标志
    post {
        always {
            echo 'I will always say Hello again!'
            println context.flag
            script {}
        }
    }
}
```

### 常用插件命令

- 更多可查看下文每个插件的使用或在网站流水线语法中查看

```groovy
// 1.调用凭证(隐藏密码，暂未发现 Pipeline 如何使用全局密码)
withCredentials([usernamePassword(credentialsId: '0c108a09-e321-45c6-bf9c-06626ddd1e4a', passwordVariable: 'MY_PASSWORD', usernameVariable: 'MY_USERNAME')]) {
    // 打印 U: **** P: ****
	sh "echo U: ${MY_USERNAME} P: ${MY_PASSWORD}"
}

// 2.注入环境变量
withEnv(['myparam=hello']) {
    sh "echo ${env.myparam}" // hello
}

// 3.连接远程服务器(传输文件、执行命令)
def projectName = 'test'
sshPublisher(publishers: [sshPublisherDesc(configName: 'node1', transfers: [
    // 连接服务器node1，将jenkins工作目录的文件传输到远程的test目录(相当于SFTP根目录)，如果没有此test目录则会创建(创建的前提是没有此目录且有文件要传输)
    // 注意：此时sourceFiles千万不能用./来表示当前目录，这样是过滤不到文件的
    // removePrefix为复制到目标目录时去掉目录前缀
    // sourceFiles文件格式遵守ant规范，http://ant.apache.org/manual/dirtasks.html#patterns
    sshTransfer(sourceFiles: "module1/target/*.jar", removePrefix: "module1/target", remoteDirectory: "${projectName}", execCommand:
        """
        echo ${projectName}
        """
    )
])])

// 4.发送邮件
emailext body: '$DEFAULT_CONTENT', postsendScript: '$DEFAULT_POSTSEND_SCRIPT', presendScript: '$DEFAULT_PRESEND_SCRIPT', recipientProviders: [developers()], replyTo: '$DEFAULT_REPLYTO', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS;admin@qq.com'
```

## 构建

### 项目构建界面说明

- `Workspace` 为构建任务源码目录(构建配置中的`.`即为此构建源码目录，如`/var/jenkins_home/workspace/xx`)
- `Changes` 可记录 Git 源码提交记录
- `立即构建` 可手动执行此构建任务(一般是通过 Gitlab 触发)
- `Delete 工程`只能删除此构建任务，并不会删除 workspace 目录下的缓存项目源码。可进入容器手动删除`/var/jenkins_home/workspace/xx`

### 自由风格构建说明

#### General

- 限制项目的运行节点
  - 可基于节点标签(参考[节点管理](#节点管理))或名称进行选择，支持`&&`、`||`、`!`等运算符

#### 源码管理(Git)

> 此处的源码管理指在 jenkins 宿主机上管理任务相应源码，比如打包等操作。如 ofbiz 项目直接在服务器上拉取最新代码时可以不用源码管理，直接在构建中发起远程命令即可

- Repositories：git 仓库配置
- Branches to build：需要构建的分支，如`origin/test`
- Additional Behaviours：扩展配置
  - Advanced clone behaviours：配置 git clone，对于较多代码拉取可将其中 Timeout 设置成`30`分钟

#### 构建触发器

- `Build when a change is pushed to GitLab. GitLab webhook URL: http://192.168.1.100/project/test` 代码推送等变更时构建，常用(需安装`GitLab`插件)
  - Enabled GitLab triggers
    - `Push Events` 直接推送到此分支时构建(**去勾选**，如直接在 git 客户端将 develop 推送到 test 则无法触发。勾选会产生问题：当在 gitlab 接受 develop 到 test 的请求会产生 2 次构建)
    - `Opened Merge Request Events` **去勾选**
    - `Accepted Merge Request Events` 接受合并请求时构建(**勾选**)
    - `Closed Merge Request Events` 去勾选
    - `Approved Merge Requests (EE-only)`(勾选，EE-only 表示只有 gitlab 企业版才支持)
    - `Comments`(勾选)
    - `Comment (regex) for triggering a build` 提交备注正则构建(如：`[Jenkins Build]`)
  - Allowed branches 允许触发的分支
    - Filter branches by name - Include 基于名称进行触发，如：`test`(此时不能写成`origin/test`)
    - Secret token - Generate 生成 token 用于 git webhook 触发
  - Gitlab 设置 Webhooks(可设置多个)：URL 和 Secret Token 填上文；Trigger 勾选`Push events`、`Tag push events`、`Merge Request events`(gitlab 提供对配置的 url 进行访问可达测试，需要 jenkins 先保存一遍上述生成的 token)。触发流程如下：
    - 当开发通过 git 提交代码或进行其他操作触发了 gitlab 此时定义的 Trigger
    - 然后 gitlab 会对配置的 URL 进行 post
    - 通过 post 的地址会进入到 jenkins 定义的构建任务中
    - jenkins 对触发进行过滤，判断是否需要进行构建
  - 触发相对比较及时，gitlab 产生后会迅速触发到 jenkins(不用刷新项目页面也自动显示新的构建)。jenkins 产生的构建会备注如
    - `Triggered ​by ​GitLab ​Merge ​Request ​#16: ​my-group-name/develop ​=> test` 此时是接受了 develop 到 test 的请求
    - `Started ​by ​GitLab ​push ​by smalle` 此时是直接在 git 客户端将 develop 推送到 test
- `Gitlab Merge Requests Builder` 定时自动生成构建任务(需安装`GitLab`插件)

#### 构建环境

- Inject passwords to the build as environment variables
  - Global passwords：导入全局密码到环境变量
  - Job passwords：定义当前任务需使用的密码
  - 如`echo ${MY_PASS}`最终是以`***`进行打印

#### 构建(Build)

- `执行 shell` 在 jenkins 运行的机器上执行命令。构建日志中`+`表示用户定义的命令
- `Send files or execute commands over SSH` 执行 ssh 服务器命令进行构建(需安装插件`Publish over SSH`)

  - `Exec command` 执行远程命令(不会记录在 linux 的 history 中)，如

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

    - 其中`source /etc/profile`为了防止报错`java: command not found`(jenkins 不会自动加载环境变量)
    - 当 windows 启动项目 bat 脚本时，一直有输出的话，Dos 窗口会一直处于等待状态，而 jenkins 的构建时会输出 windows 的脚本运行信息，所以 Jenkins 也会一直处于构建状态。此时可考虑 bat 脚本后台运行，如使用`.vbe`脚本对 bat 文件进行包装

- 调用顶层 Maven 目标
  - Maven Version：可选择全局工具配置中配置的 maven，若无此选项可参考下文全局工具配置
  - Goals：如`clean package -Dmaven.test.skip=true`
  - 高级 - POM：可自定义 pom 文件位置，如`my-module-one/pom.xml`

#### 构建后操作

- `E-mail Notification` 邮件通知
  - 勾选`Send e-mail for every unstable build`(每次构建失败都会发送邮件，当从构建失败转为构建成功时也会发邮件，之后构建成功则不发送邮件提醒；测试勾选或不勾选都一样)
  - 多个邮箱使用空格分开
  - 需要先到系统管理中设置邮件发送服务器，其中 SMTP 发件地址需要和系统管理员邮件地址一致

### Pipeline 和 Jenkinsfile 构建

> 本示例 Jenkins 基于 docker 进行安装。参考：https://jenkins.io/zh/doc/tutorials/build-a-java-app-with-maven/#run-jenkins-in-docker

- 创建 Pipeline：新建 Item - 流水线(Pipeline)
- General、构建触发器、高级项目选项此示例可不用填写(实际可按需填写)
- 流水线
  - 定义：`Pipeline script`(在 Jenkins 配置中定义 Pipeline 脚本)、`Pipeline script from SCM`(从软件配置管理系统，如 Git 仓库获取脚本；可配置脚本所在 Git 仓库的文件路径)

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

### Jenkins+Docker+Harbor+Gitlab

- 流程图如下 [^2]

![jenkins-docker-gitlab](/data/images/devops/jenkins-docker-gitlab.png)

- 基于 k8s 示例：http://www.mydlq.club/article/8/#wow10

#### 模式一

- Springboot 项目的 pom.xml 加入打包 docker 插件，并手动推送到镜像仓库(如 Harbor)
- jenkins 任务源码从 gitlab 获取，即设置 Gitlab Webhooks
- jenkins 构建时分别执行 maven 打包、给服务器发送启动 docker 命令

  - 如果是 harbor 构建的镜像，可在 docker 容器中先登录(第一次登录会把认证信息存储起来，下次执行命令无需登录)

  ```bash
  echo "exec command start..."
  source /etc/profile
  cd /home/smalle/compose/nginx

  sudo docker-compose up -d
  echo "exec command end..."
  ```

#### 模式二

- 上述流程需要开发先将镜像打包到镜像仓库，此处也可以通过在 jenkins 所在服务器打包(自动处理版本问题)。如下
- 构建触发器参考[构建触发器-Gitlab](#构建触发器)
- 构建环境 - Inject passwords to the build as environment variables - 勾选 Global passwords(全局密码在系统设置中添加)
- 构建 - Execute Shell(打包镜像并上传到 Harbor)

  ```bash
  # Variables
  JENKINS_PROJECT_HOME='/var/jenkins_home/workspace/demo'
  HARBOR_IP='192.168.1.100:5000' # 也可设置成全局变量
  REPOSITORIES='test/demo'
  HARBOR_USER='test'

  # 尽管jenkins容器中执行的是宿主机docker命令，且宿主机已经认证过，但此处仍需认证. G_PASS_HARBOR_USER为全局密码变量(Global Passwords)
  echo ${G_PASS_HARBOR_USER} | docker login -u ${HARBOR_USER} --password-stdin ${HARBOR_IP}

  # 删除本地历史构建的镜像(镜像历史会保存在镜像仓库不用担心丢失)
  IMAGE_ID=`docker images | grep ${REPOSITORIES} | awk '{print $3}'`
  if [ -n "${IMAGE_ID}" ]; then
      docker rmi ${IMAGE_ID} || true # 执行失败继续执行后续命令。如k8s环境有可能编译节点和运行节点相同导致镜像占用无法删除(未使用的镜像仍然可以删除)
  fi

  # Build image.
  cd ${JENKINS_PROJECT_HOME} # 默认就是项目的工作空间(源码根目录)，此处cd可结合jenkins-agent使用。自定义工作目录可用于k8s-jenkins保存源码目录供下次编译使用，参考下文节点管理
  DOCKER_TAG=`date +%y%m%d-%H%M%S` # 190902-165827
  docker build --rm -t ${HARBOR_IP}/${REPOSITORIES}:${DOCKER_TAG} --build-arg APP_VERSION=v${DOCKER_TAG} -f ./docker/Dockerfile .

  # Push to the harbor registry.
  docker push ${HARBOR_IP}/${REPOSITORIES}:${DOCKER_TAG}

  # 保存环境变量到工作目录文件中供其他shell使用(配合EnvInject Plugin)
  echo "DOCKER_TAG=${DOCKER_TAG}" > ./env_jenkins.sh
  ```

- 构建 - Inject environment variables(注入上一个 shell 的环境变量文件)，参考[本文 Environment Injector 插件](<#Environment%20Injector(注入环境变量)>)
- 构建 - over SSH(执行 helm 部署 Pod)

  ```bash
  HELM_NAME='demo'
  sudo /usr/local/bin/helm upgrade --set image.tag=${DOCKER_TAG} ${HELM_NAME} /root/helm-chart/test/${HELM_NAME}
  ```

### (推荐)Pipeline+K8s+Harbor+Gitlab+Springboot+Maven(可改成Declarative风格)

> http://www.mydlq.club/article/8/

- 创建项目 - 风格选择 Pipeline
- General：(为了安全)勾选不允许并发构建、(为了提升效率)勾选流水线效率、持久保存设置覆盖(Performance-optimized...)
- 构建触发器参考[构建触发器-Gitlab](#构建触发器)
- 流水线 - Pipeline script(另一个选项为 Pipeline script from SCM)
    - 勾选`使用 Groovy 沙盒`
    - Jenkinsfile 脚本

```groovy
// 声明执行Helm的方法
def helmDeploy(Map args) {
    if(args.init) {
        println "Helm 客户端初始化"
        sh "helm init --client-only --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts"
		withCredentials([usernamePassword(credentialsId: '7f3ee3d0-af55-4783-b65d-42cfb22576a8', passwordVariable: 'HELM_REPO_USER_PASS', usernameVariable: 'HELM_REPO_USER')]) {
			sh "helm repo add aezocn ${args.url} --username ${HELM_REPO_USER} --password ${HELM_REPO_USER_PASS}"
		}
    } else if (args.dry_run) {
        println "尝试 Helm 部署，验证是否能正常部署"
        sh "helm upgrade --install ${args.name} --namespace ${args.namespace} ${args.values} --set ${args.sets} aezocn/${args.template} --dry-run --debug"
    } else {
        println "正式 Helm 部署"
        sh "helm upgrade --install ${args.name} --namespace ${args.namespace} ${args.values} --set ${args.sets} aezocn/${args.template}"
    }
}

// jenkins slave 执行流水线任务
// 整个构建超时时间为600s
timeout(time: 600, unit: 'SECONDS') {
    try{
        // 代理名称，填写系统设置中设置的 Cloud 中 Template 模板的 label
		def label = "jnlp-agent"
		
		// 调用Kubernetes提供的方法
        podTemplate(label: label, cloud: 'kubernetes') {
			// 在代理节点上运行脚本
			node (label) {
				// 将源码拉取到当前目录(/home/jenkins/agent/workspace/my-jenkins-project-name/)，即此项目的工作空间
				stage('Git阶段') {
					git credentialsId: '0c108a09-e321-47c6-bf9c-06626ccd1e4a', branch: "master", changelog: true, url: "${G_GIT_HTTP_URL}aezocn/test.git"
				}
				stage('Maven阶段') {
					// 使用pod中的某个容器
					container('maven') {
						// 这里引用上面设置的全局的 settings.xml 文件，根据其ID将其引入并创建该文件
						configFileProvider([configFile(fileId: "15263da5-15d5-4bb5-abb7-5cc604def581", targetLocation: "settings.xml")]) {
							sh 'mvn -f ./oa-dev-center-api/pom.xml clean install -Dmaven.test.skip=true --settings settings.xml'
						}
					}
				}
				stage('Docker阶段') {
					echo "Docker 阶段"
					container('docker') {
						// 读取pom参数
						echo "读取 pom.xml 参数"
						pom = readMavenPom file: './oa-dev-center-api/pom.xml'
						println pom
						// 设置镜像仓库地址
						harbor_host = "${G_DOCKER_REGISTRY}"
						// 设置仓库项目名
						harbor_project_name = "devops"
						echo "编译 Docker 镜像"
						// harbor账号id 
						docker.withRegistry("http://${harbor_host}", "8bbd8356-ff16-4afb-b782-4f253a36d0e1") {
							echo "构建镜像"
							// 指定dockerfile文件目录打包镜像(如果镜像在当前目录则可不需要第二个参数)，pom里面设置的项目名与版本号打标签
							def customImage = docker.build("${harbor_host}/${harbor_project_name}/${pom.artifactId}:${pom.version}", "./oa-dev-center-api")
							echo "推送镜像"
							customImage.push()
							echo "删除镜像"
							sh "docker rmi ${harbor_host}/${harbor_project_name}/${pom.artifactId}:${pom.version}"
						}
					}
				}
				stage('Helm阶段') {
					container('helm-kubectl') {
						// 此处可直接使用Tiller的sa账号，将sa的token秘钥保存到凭证中
						withKubeConfig([credentialsId: "4cd72b9c-c5a0-6e6e-b68a-cc1d3472b694", serverUrl: "https://kubernetes.default.svc.cluster.local"]) {
							name = "${pom.artifactId}"
							namespace = "devops"
							repo_url = "${G_HELM_REPO_URL}"
							template = "springboot --version 1.1.0"
							
							// 检测是否存在yaml文件
							def values = ""
							if (fileExists('oa-dev-center-api/devops/values.yaml')) {
								values = "-f oa-dev-center-api/devops/values.yaml"
							}
							
							image = "image.repository=${harbor_host}/${harbor_project_name}/${pom.artifactId}"
							tag = "image.tag=${pom.version}"
							pullPolicy = "image.pullPolicy=Always"
							now = new Date().format("yyyyMMddHHmmss")
							env = "evn.BUILD_TIME=${now},env.DATABASES_NAME=oa_dev_center,env.DATABASES_HOST=192.168.6.130,env.DATABASES_PORT=3306,env.DATABASES_USER=oa-dev-center,env.DATABASES_PASSWORD=root,env.APP_OPTS='--spring.profiles.active=test'"
							sets = "${image},${tag},${pullPolicy},${env}"
							
							// 执行 Helm 方法
							echo "Helm 初始化"
							helmDeploy(init: true, url: "${repo_url}");
							echo "Helm 执行部署测试"
							helmDeploy(init: false, dry_run: true, name: "${name}", namespace: "${namespace}", template: "${template}", values: "${values}", sets: "${sets}")
							echo "Helm 执行正式部署"
							helmDeploy(init: false, dry_run: false, name: "${name}", namespace: "${namespace}", template: "${template}", values: "${values}", sets: "${sets}")
						}
					}
				}
			}
		}
    } catch(Exception e) {
		echo "失败。。。"
		println e
        currentBuild.result = "FAILURE"
    } finally {
        // 获取执行状态
        def currResult = currentBuild.result ?: 'SUCCESS'
        // 判断执行任务状态，根据不同状态发送邮件
        stage('email') {
            if (currResult == 'SUCCESS') {
                echo "发送成功邮件"
                emailext body: '$DEFAULT_CONTENT', postsendScript: '$DEFAULT_POSTSEND_SCRIPT', presendScript: '$DEFAULT_PRESEND_SCRIPT', attachLog: true, compressLog: true, recipientProviders: [developers()], replyTo: '$DEFAULT_REPLYTO', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS;admin@qq.com'
            } else {
                echo "发送失败邮件"
                emailext body: '$DEFAULT_CONTENT', postsendScript: '$DEFAULT_POSTSEND_SCRIPT', presendScript: '$DEFAULT_PRESEND_SCRIPT', attachLog: true, compressLog: true, recipientProviders: [developers()], replyTo: '$DEFAULT_REPLYTO', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS;admin@qq.com'
            }
        }
    }
}
```

- springboot 项目配置

    ```bash
    # git项目文件结构
    |-- oa-dev-center-web
    |-- oa-dev-center-api
    |---- src
    |---- devops
    |------ runboot.sh
    |------ values.yaml # helm charts values.yaml
    |------ wait-for-it.sh
    |---- Dockerfile
    |---- pom.xml
    ```

- 常见问题
    - 第一次构建可能报错`Scripts not permitted to use method org.apache.maven.model.Model getArtifactId`，是因为在沙箱环境下 getArtifactId 等脚本方法需要管理员通过才可执行
        - 解决：在系统管理 - In-process Script Approval - approved(method org.apache.maven.model.Model getArtifactId)
    - 访问 api server 时，需要对应的 ServiceAccount 账号，此处可直接使用 Tiller 的 sa 账号。获取方式如`kubectl get secret $(kubectl get secret -n kube-system|grep tiller-token|awk '{print $1}') -n kube-system -o jsonpath={.data.token}|base64 -d |xargs echo`，将秘钥保存到 jenkins 凭证中获取凭证 ID 供 Pipeline 脚本使用

### Pipeline(Declarative)+Windows+Gilab

- General
    - 勾选流水线效率、持久保存设置覆盖
    - 去勾选不允许并发构建
        - 多个触发会创建多个agent来进行构建
        - 一个触发构建执行完成后会自动删除agent/workspace/job中从git仓库获取的文件，像脚本中创建的不会自动删除
- 构建触发器(其他配置参考上文)
    - 选择Filter branches by regex
        - Target Branch Regex如 `test|master|fixbug|test-.*` (只要目标分支为其中一个就会触发构建)
- 流水线
    - Pipeline script from SCM - Git
    - Repository URL 为 `${gitlabTargetRepoHttpUrl}` (基于gitlab hook注入到jenkins的环境变量自动获取需要构建的git仓库地址)
    - Branches to build 为 `origin/${gitlabTargetBranch}` (自动获取分支)
    - 脚本路径为`devops/Jenkinsfile`
    - 轻量级检出
- git仓库需要存放`devops/Jenkinsfile`文件
    - 此案例只需要定义一个jenkins job便可构建多个项目。缺点时获取的构建变更不准确

```groovy
/**
 * jenkins slave 执行流水线任务。基于windows power shell(可在windows服务器上安装如windows power server来提供ssh服务)，必须通过gitlab触发
 */
def context = [:]
//==============================================================================================================
// 自定义服务器相关参数(发布的服务器共用一套配置即可)
//==============================================================================================================
// 远程服务器，需要在jenkins中配置过
context.remoteServerName = 'node1'
// 远程服务器SFTP服务根目录，如node1为C:/temp/jenkins
context.remoteSftpRoot = 'C:/temp/jenkins'
// (构建后台API需要) 远程服务器JAVA_HOME目录。如node1为C:/Program Files/Java/jre1.8.0_181
context.remoteJavaHome = 'C:/Program Files/Java/jre1.8.0_181'
// (构建后台API需要) 远程服务器RunHiddenConsole程序路径(windows下使程序后台运行)
context.remoteRunHiddenConsole = 'D:/soft/RunHiddenConsole.exe'

//==============================================================================================================
// ***自定义项目相关参数(每个项目配置不同)***
//==============================================================================================================
// 项目名称(可使用git仓库名或公司唯一项目名)
context.projectName = 'demo'
context.emailToUser = 'admin@example.com;system@example.com'

// **是否需要构建后台API**
context.apiStage = true
// API部署在远程服务器的目录
context.remoteApiDir = 'C:/demo_dir'
// pom.xml文件在git仓库中的相对位置。**相对路径，但不能使用./开头**；pom在git仓库根目录则留空，如果在子目录如 def pomDir = 'my-api/'
context.pomDir = ''
// 启动jar参数
context.startJarArgs = '--spring.profile=test'

// **是否需要构建WEB(不含nginx配置)**
context.webStage = false
// WEB部署在远程服务器的目录
context.remoteWebDir = 'C:/demo_dir'
// package.json文件在git仓库中的相对位置。**相对路径，但不能使用./开头**；pom在git仓库根目录则留空，如果在子目录如 def pomDir = 'my-web/'
context.packageJsonDir = ''
// 编译静态包的命令
context.npmBuildCommand = "npm run test"
// 编译出的静态包后，需要复制到远程服务器的文件或文件夹路径
// (1)如果需要将编译后的dist放到context.remoteWebDir则填dist/**
// (2)如果需要将dist/index.html、dist/static等文件(不包含dist目录)放到context.remoteWebDir则填["dist/index.html","dist/static/**"]
context.distNameArr = ["dist/**"]
// 移动文件时需要移除的目录前缀，默认无需移除，配合context.distNameArr的场景(1)使用，对于场景(2)则需要填写'dist/'
context.removeDistNamePrefix = ''

//==============================================================================================================
// 上传编译文件到服务器并启动和通用参数配置
//==============================================================================================================
// 是否自动发送邮件
context.sendEmailFlag = true

// 上传jar包到服务器并启动
def sshJarUploadAndExec(Map args) {
    now = new Date().format("yyyy-MM-dd HH:mm:ss")
    projectDir = "${args.projectName}-api"
    sshPublisher(publishers: [sshPublisherDesc(configName: "${args.remoteServerName}", transfers: [
		// 将编译好文件上传到服务器的sftp目录。sourceFiles基于ant文件命名规范来的
        sshTransfer(sourceFiles: "${args.pomDir}target/${args.apiJarName}", removePrefix: "${args.pomDir}target", remoteDirectory: "${projectDir}", execCommand:
            """
            echo running...
            # 备份。创建备份目录 C:/demo_dir/demo-bak-10，并将原C:/demo_dir目录下的jar包复制到备份目录
            if(-not (test-path "${args.remoteApiDir}/${args.projectName}-bak-${env.BUILD_NUMBER}")) { mkdir "${args.remoteApiDir}/${args.projectName}-bak-${env.BUILD_NUMBER}" }
            if(test-path "${args.remoteApiDir}/${args.apiJarName}*") { cp "${args.remoteApiDir}/${args.apiJarName}*" "${args.remoteApiDir}/${args.projectName}-bak-${env.BUILD_NUMBER}" }
            # 停止原进程。基于java.exe的包装文件进行停职进程
            if(test-path '${args.remoteApiDir}/java-${projectDir}.exe') { tasklist /fo csv | findstr 'java-${projectDir}.exe' ; if(\$?) { taskkill /f /im java-${projectDir}.exe ; sleep 10 } }
            # 复制文件。1.将java.exe复制到项目录并重命名，之后以此文件启动jar，方便上面停止进程 2.从sftp目录复制编译文件到发布目录
            cp "${args.remoteJavaHome}/bin/java.exe" "${args.remoteApiDir}/java-${projectDir}.exe"
            cp "${args.remoteSftpRoot}/${projectDir}/${args.apiJarName}" "${args.remoteApiDir}/${args.apiJarName}"
            # 启动程序。使用RunHiddenConsole和上述重名的java.exe启动jar
            ${args.remoteRunHiddenConsole} ${args.remoteApiDir}/java-${projectDir}.exe -DBUILD_TIME="${env.BUILD_NUMBER}_${now}" -jar "${args.remoteApiDir}/${args.apiJarName}" ${args.startJarArgs}
            """
        )
    ])])
}

// 上传前台静态文件到服务器
def sshWebUpload(Map args) {
    projectDir = "${args.projectName}-web"
    sourceFileStr = ""
    backupDirStrCommand = ""
    rmDirStrCommand = ""
    moveDirCommand = ""
	// 基于配置的文件或文件夹组装命令
    for (int i=0; i < args.distNameArr.size(); i++) {
        dir = args.distNameArr.get(i)
        sourceFileStr += "${args.packageJsonDir}${dir}"
        if((i+1) != args.distNameArr.size()) {
            sourceFileStr +=","
        }
		// 去掉文件夹的/**，防止复制文件夹中文件时漏复制文件夹本身
        dir = "\$('${dir}' -replace '/\\**\$','')"
        removePrefixDir = "\$(${dir} -replace '^${args.removeDistNamePrefix}','')"

        backupDirStrCommand += "if(test-path \"${args.remoteWebDir}/${removePrefixDir}\") { cp -erroraction 'silentlycontinue' -Recurse \"${args.remoteWebDir}/${removePrefixDir}\" '${args.remoteWebDir}/${args.projectName}-bak-${env.BUILD_NUMBER}' } \n"
        rmDirStrCommand += "if(test-path \"${args.remoteWebDir}/${removePrefixDir}\") { rm -Recurse -Force \"${args.remoteWebDir}/${removePrefixDir}\" } \n"
        moveDirCommand += "if(test-path \"${args.remoteSftpRoot}/${projectDir}/${dir}\") { mv \"${args.remoteSftpRoot}/${projectDir}/${dir}\" '${args.remoteWebDir}/' } \n"
    }

    sshPublisher(publishers: [sshPublisherDesc(configName: "${args.remoteServerName}", transfers: [
        sshTransfer(sourceFiles: "${sourceFileStr}", removePrefix: "${args.packageJsonDir}", remoteDirectory: "${projectDir}", execCommand:
            """
            echo running...
            # 备份
            if(-not (test-path "${args.remoteWebDir}/${args.projectName}-bak-${env.BUILD_NUMBER}")) { mkdir "${args.remoteWebDir}/${args.projectName}-bak-${env.BUILD_NUMBER}" }
            ${backupDirStrCommand}
            # 删除原文件
            ${rmDirStrCommand}
            # 复制文件到www目录(需提前将nginx映射到该目录)
            ${moveDirCommand}
            """
        )
    ])])
}

pipeline {
    agent {
        label "jnlp-agent"
    }
    stages {
        stage('Git阶段') {
            steps {
                script {
					// 如果提交的标题有[ci skip]则跳过此次构建
                    result = sh (script: "echo \$gitlabMergeRequestTitle | grep '\\[ci skip\\]' | wc -l", returnStdout: true)
                    if (result == "1\n") {
                        context.sendEmailFlag = false
                        throw new hudson.AbortException('[ci skip]')
                    }
                }
            }
        }
        stage("构建阶段") {
            parallel {
                stage('API构建阶段') {
                    when {
                        expression {
							// 如果提交的标题有[ci skip api]则跳过API构建
                            result = sh (script: "echo \$gitlabMergeRequestTitle | grep '\\[ci skip api\\]' | wc -l", returnStdout: true)
                            return context.apiStage && result == "0\n"
                        }
                    }
                    options {
                        timeout(time: 600, unit: "SECONDS")
                    }
                    stages {
                        stage('Maven阶段') {
                            steps {
                                script {
                                    container('maven') {
                                        configFileProvider([configFile(fileId: "15263da5-15d5-4bb5-abb7-5dd604def581", targetLocation: "settings.xml")]) {
                                            sh (script: "mvn -f ${context.pomDir}pom.xml clean install -Dmaven.test.skip=true --settings settings.xml")
                                        }
                                    }
                                }
                            }
                        }
                        stage('上传JAR包并启动阶段') {
                            steps {
                                script {
                                    pom = readMavenPom file: "${context.pomDir}pom.xml"
                                    context.apiJarName = "${pom.artifactId}-${pom.version}.jar"
                                    sshJarUploadAndExec(context)
                                }
                            }
                        }
                    }
                }
                stage('WEB构建阶段') {
                    when {
                        expression {
                            result = sh (script: "echo \$gitlabMergeRequestTitle | grep '\\[ci skip web\\]' | wc -l", returnStdout: true)
                            return context.webStage && result == "0\n"
                        }
                    }
                    options {
                        timeout(time: 1200, unit: "SECONDS")
                    }
                    stages {
                        stage('NodeJS编译阶段') {
                            steps {
                                script {
                                    container('nodejs') {
                                        packageJsonDir = context.packageJsonDir
                                        if(packageJsonDir == "") {
                                            packageJsonDir = "./"
                                        }
                                        sh """
                                        cd ${packageJsonDir}
                                        # npm i mirror-config-china --registry=https://registry.npm.taobao.org # electron等应用可能需要
                                        npm install --registry=${G_NPM_REGISTRY}
                                        ${context.npmBuildCommand}
                                        """
                                    }
                                }
                            }
                        }
                        stage('上传前台编译包') {
                            steps {
                                script {
                                    sshWebUpload(context)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                echo "是否发送邮件: ${context.sendEmailFlag}"
                if(context.sendEmailFlag) {
                    def currResult = currentBuild.result ?: 'SUCCESS'

                    if (currResult == 'SUCCESS') {
                        echo "发送成功邮件"
                        emailext body: '$DEFAULT_CONTENT', postsendScript: '$DEFAULT_POSTSEND_SCRIPT', presendScript: '$DEFAULT_PRESEND_SCRIPT', attachLog: true,
                                subject: "\$PROJECT_NAME: \$BUILD_STATUS! (Build: #\$BUILD_NUMBER, Repo: ${gitlabTargetRepoHttpUrl}, Target Branch: origin/${gitlabTargetBranch})",
                                recipientProviders: [developers()], replyTo: '$DEFAULT_REPLYTO', to: "\$DEFAULT_RECIPIENTS;${context.emailToUser}"
                    } else {
                        echo "发送失败邮件"
                        emailext body: '$DEFAULT_CONTENT', postsendScript: '$DEFAULT_POSTSEND_SCRIPT', presendScript: '$DEFAULT_PRESEND_SCRIPT', attachLog: true,
                                subject: "\$PROJECT_NAME: \$BUILD_STATUS! (Build: #\$BUILD_NUMBER, Repo: ${gitlabTargetRepoHttpUrl}, Target Branch: origin/${gitlabTargetBranch})",
                                recipientProviders: [developers()], replyTo: '$DEFAULT_REPLYTO', to: "\$DEFAULT_RECIPIENTS;${context.emailToUser}"
                    }
                }
            }
        }
    }
}
```

## 系统管理(Manage Jenkins)

### 系统设置(Configure System)

- 主目录：基于 docker 安装时一般为`/var/jenkins_home`
- 全局属性
    - 环境变量：自定义全局环境变量，在所有任务中均可使用
- Jenkins Location
    - Jenkins URL：jenkins 的路径，如：`http://192.168.1.100:8080/`。如果此处配置成外网，当通过内网访问时会提示`反向代理设置有误`，但是不影响使用。发送的邮件中一般会用到此地址
    - 系统管理员邮件地址：此地址需要和 SMTP 发件地址一致，如：`aezo-jenkins<test@example.com>`(from 地址可添加昵称：`昵称<from>`)
- Global Passwords：全局密码(Pipeline 无法使用，但可配合 withCredentials 使用凭证功能)
    - 使用：通过【构建环境-Inject passwords to the build as environment variables】导入密码到环境变量
- 邮件通知：配置 smtp 服务器
    - SMTP server 不能带端口
    - 其中 SMTP 发件地址需要和系统管理员邮件地址一致
- Publish over SSH
    - SSH Servers：配置目标服务器，高级功能中可使用 HTTP/SOCKS5 代理(可能存在测试代理连接失败 BUG，但是可以正常使用)

### 全局工具配置(Global Tool Configuration)

- Maven [^1]
    - 安装 Jenkins 默认不含 maven，可通过下列方法解决
        - docker 安装 Jenkins 时，pipeline 风格可在`agant`中运行 maven 镜像
        - 自由风格可使用宿主机 maven 或通过 jenkins 自动安装
    - 使用宿主机 maven 配置：Name`maven3.6`；去勾选自动安装；MAVEN_HOME 填写宿主机目录(如果是 docker 安装的 jenkins 可将本地 maven 安装目录挂载到容器目录如/var/maven_home，然后此处使用/var/maven_home)
    - 通过 jenkins 自动安装
        - 配置：Name`maven3.6`；勾选自动安装；Version`3.6.1`(之后重新进入此配置页面，可能默认不会显示之前的配置)
        - 需要安装`Maven Integration`插件
        - 进行了上述配置和插件安装默认还是不会自动安装 maven，需要`构建一个maven项目`，然后构建此项目才会自动安装(安装成功后，在资源风格项目中也可以使用)
    - 自动安装的 maven 插件位置：`/data/docker/volumes/jenkins-data/_data/tools/hudson.tasks.Maven_MavenInstallation/maven3.6` (基于 docker 安装 jenkins)
        - 可修改`conf/settings.xml`相关配置，如配置阿里云镜像地址
    - maven 仓库默认保存在宿主机的`/root/.m2`目录

### 插件管理

- 修改插件镜像地址
    - 插件管理 - 高级 - 升级站点URL设置成`https://updates.jenkins-zh.cn/update-center.json` - 提交 - 立即获取

#### 默认安装插件

- Git(内置 git 客户端)

#### 其他插件推荐

##### Publish over SSH(执行远程命令)

- [src](https://github.com/jenkinsci/publish-over-ssh-plugin)、[wiki](https://wiki.jenkins.io/display/JENKINS/Publish+Over+SSH+Plugin)
- 利用此插件可以连接远程 Linux 服务器，进行文件的上传或是命令的提交；也可以连接提供 SSH 服务的 windows 服务器，windows 提供 ssh 服务参考[windows.md#ssh 服务器#PowerShell Server](/_posts/extend/windows.md#ssh服务器)
- BapSshHostConfiguration#createClient 进行服务器连接
- 此插件 1.20.1 界面`Test Configuration`测试代理连接存在 bug，实际是支持代理连接的
- Pipeline 使用

```groovy
// configName为系统设置的SSH服务器名
sshPublisher(publishers: [sshPublisherDesc(configName: 'node1', transfers: [
    // 会将匹配到的文件和文件夹(多个用,分割)一起复制到远程目录(会相当于SFTP根目录创建此远程目录)
    sshTransfer(sourceFiles: 'target/*.jar', remoteDirectory: 'demo', execCommand:
        '''
        cd d:/temp
        ls
        '''
    )
])])
```

##### GitLab

- [wiki](https://github.com/jenkinsci/gitlab-plugin)
- 允许 GitLab 触发 Jenkins 构建并在 GitLab UI 中显示结果
- gitlab 触发 webhook 时，会设置一些变量到环境中，如：gitlabTargetRepoHttpUrl、gitlabSourceBranch、gitlabTargetBranch、gitlabMergeRequestTitle、gitlabActionType。详见：https://github.com/jenkinsci/gitlab-plugin#defined-variables

##### Maven Integration

- 使用：新建 Item - 构建一个 maven 项目
- 项目配置：Goals and options `clean install -Dmaven.test.skip=true`

##### Localization: Chinese (Simplified)

- 界面汉化(汉化部分，Local 插件也只能汉化部分)

##### Docker plugin

- 提供使用 jenkins 进行镜像编译、推送到 Harbor 等镜像仓库(也可通过 maven 插件配置 docker 镜像编译和推送)

##### Ant

- 构建 - 增加构建步骤 - Invoke Ant
- 安装的插件不能通过 shell 命令执行 ant

##### Environment Injector(注入环境变量)

- [wiki](https://wiki.jenkins.io/display/JENKINS/EnvInject+Plugin)
- 同一个 Job 不同 shell 参数传递

  - 如果涉及到 over SSH 远程命令调用则必须使用文件进行参数传递

  ```bash
  ## Build - 执行Shell(将环境变量保存到当前工作目录的文件中)
  DOCKER_TAG=`date +%Y%m%d-%H%M%S`
  echo "DOCKER_TAG=${DOCKER_TAG}" > ./env_jenkins.sh

  ## Build - Inject environment variables(从当前工作目录载入文件读取其环境变量并注入到当前环境)
  Properties File Path=./env_jenkins.sh
  # Properties Content中也可以定义参数，但是通过本地shell修改后，在over SSH中不能生效(还是拿到原始Properties Content中定义的参数值)

  ## Build - Send files or execute commands over SSH
  echo ${DOCKER_TAG}
  ```

- 可通过 linux 命令`printenv`打印所有环境变量

##### Email Extension

> https://wiki.jenkins.io/display/JENKINS/Email-ext+plugin

- 邮件发送扩展 [^3]
    - 原本 jenkins 自带邮件发送功能，但是不够强大，参考[系统设置(Configure System)](<#系统设置(Configure%20System)>)
    - 此扩展可自定义何时(成功、失败等)出发邮件发送
- 相应配置在【系统管理-系统配置-Extended E-mail Notification】中
    - 配置 smtp 认证同 jenkins 自带邮件发送
    - Allowed Domains 可配置允许发送邮件的域
    - Default Content Type：HTML (text/html)
    - Default Subject：【jenkins】$PROJECT_NAME: $BUILD_STATUS! (Build #\$BUILD_NUMBER)
    - Default Content：[Email-Extension-Default-Content](#Email-Extension-Default-Content)
    - Default Pre-send Script：可不设置。该脚本将在发送电子邮件之前运行，以允许在发送之前修改电子邮件；也可以通过将布尔变量 cancel 设置为 true 来取消发送电子邮件；在任务设置中可编辑此项或使用\${DEFAULT_PRESEND_SCRIPT}导入此系统配置
- 任务设置：构建后操作-Editable Email Notification
    - Advanced Settings...
        - Triggers - Add Trigger - [Success(构建成功)/Failure - Any(所有失败)/Always(一直)]
            - Send To：默认选中了`Developers`这个组。即给此次合并提交所涉及的开发发送邮件(从 git 信息中提取邮箱)
            - 高级
                - Recipient List：收件人(除了 Send To 中的收件人，此处可额外定义收件人)。如：`a@example.com,cc:b@example.com,bcc:c@example.com`(CC 抄送，BCC 密件抄送)
                - Content Type：HTML (text/html)
                - Attach Build Log：Attach Build Log

##### Kubernetes(连接k8s创建jenkins-agent)

- 在 Kubernetes 集群中运行动态代理节点(agent)的 Jenkins 插件，[参考](https://plugins.jenkins.io/kubernetes)
- 安装此插件增加的扩展配置：系统管理 - 系统配置 - 云
    - 名称：默认`kubernetes`
    - Kubernetes 地址：`https://kubernetes.default.svc.cluster.local`，或者省略`svc.cluster.local`，即https://kubernetes.default
    - Kubernetes 命名空间：留空或 default
    - 凭据：留空(默认使用 jenkins 主 pod 的 ServiceAccount 账号访问 k8 api server)
    - Jenkins 地址：`http://jenkins.devops:8080`，此处 jenkins 基于 k8s 部署，中间表示`服务名称.命名空间`
    - Jenkins 通道：agent 通过 jnlp 和 jenkins 通信通道，此处如`jenkins-agent.devops:50000`(jenkins-agent 为 k8s 服务名，如果 jenkins 普通部署此处填 jenkins 的 hostname 即可)。此处的 50000 需要 k8s 暴露到服务层，对应 jenkins-pod 的端口也是 50000(在系统配置-全局安全配置-代理-TCP port for inbound agents-指定端口 50000)
    - 添加模板，创建 agent 的 Pod 模板(Kubernetes Pod Template)，可以创建多个模板
        - 名称：jnlp-agent
        - 命名空间：agent-pod 运行的命名空间，留空则和 jenkins-pod 运行于同一空间
        - 标签列表(label)：`jnlp-agent` 可用于构建时基于标签选择不同的 Pod Template
        - 卷(如 agent 需要执行 docker 等命令，可挂载 jenkins pod 宿主机的 docker。下文pod中为在 agent pod 中包含 docker 容器，因此此选项可不操作)
            - 增加 Host Path Volume(为了让此 agent 可以调用宿主机的 docker 命令)
                - 主机路径、挂载路径：/var/run/docker.sock
                - 主机路径、挂载路径：/usr/bin/docker
        - Pod 的原始 yaml(具体配置见下文。pod 基础配置，策略为 Override 则表示，上述配置如果和原始 yaml 重复则按照上述配置来)
        - Yaml merge strategy：Override
        - Show raw yaml in console：勾选表示jenkins构建日志中会显示agent的pod-yaml配置，调试的时候可以勾选
- Pod 的原始 yaml

```yaml
# 需要使用空格排版
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-slave
spec:
  securityContext: #容器安全设置
    runAsUser: 0 #以ROOT用户运行容器
    privileged: true #赋予特权执行容器
  # 如果不需要agent执行如下命令则不行配置容器
  containers:
    - name: jnlp #Jenkins Slave镜像
      image: bzyep49h.mirror.aliyuncs.com/jenkins/jnlp-slave:3.27-1
      #设置工作目录
      workingDir: /home/jenkins/agent
      tty: true
    - name: docker #Docker镜像
      image: bzyep49h.mirror.aliyuncs.com/library/docker:18.06.2-dind
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: docker
          mountPath: /usr/bin/docker
        - name: docker-sock
          mountPath: /var/run/docker.sock
        - name: docker-config
          mountPath: /etc/docker
    - name: maven #Maven镜像
      image: bzyep49h.mirror.aliyuncs.com/library/maven:3.6.0-jdk-8-alpine
      command:
        - cat
      tty: true
      volumeMounts:
        - name: maven-m2
          mountPath: /root/.m2
    - name: helm-kubectl #Kubectl & Helm镜像
      image: bzyep49h.mirror.aliyuncs.com/dtzar/helm-kubectl:2.14.3
      command:
        - cat
      tty: true
    - name: nodejs # node镜像
      image: bzyep49h.mirror.aliyuncs.com/library/node:10.23.0
      command:
        - cat
      tty: true
  volumes:
    - name: docker #将宿主机 Docker 文件夹挂进容器，方便存储&拉取本地镜像
      hostPath:
        path: /usr/bin/docker
    - name: docker-sock #将宿主机 Docker.sock 挂进容器
      hostPath:
        path: /var/run/docker.sock
    - name: docker-config #将宿主机 Docker 配置挂在进入容器
      hostPath:
        path: /etc/docker
    - name: maven-m2 #Maven 本地仓库挂在到 NFS 共享存储，方便不同节点能同时访问与存储
      nfs:
        server: 192.168.1.130
        path: "/home/data/nfs/m2"
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchExpressions:
              - {
                  key: "unilog/jenkins-agent",
                  operator: In,
                  values: ["enabled"],
                }
```

##### Kubernetes CLI Plugin

- 可执行 k8s 命令

```groovy
// 提供 kubectl 执行的环境，其中得设置存储了 token 的凭据ID和 kubernetes api 地址(需要此service account token有权限获取nodes)
withKubeConfig([credentialsId: "xxxx-xxxx-xxxx-xxxx", serverUrl: "https://kubernetes.default.svc.cluster.local"]) {
    sh "kubectl get nodes"
}
```

##### Config File Provider

- 配置管理 - Managed files
- 如配置全局 maven 的 setting.xml

  - Add a new Config - Global Maven settings.xml - 修改 maven 镜像为阿里云镜像
  - 会生成一个全局 ID，可在 Pipeline 中使用

    ```groovy
    configFileProvider([configFile(fileId: "15263da5-15d5-4bb5-abb7-5dd604def581", targetLocation: "settings.xml")]) {
        sh "mvn clean install -Dmaven.test.skip=true --settings settings.xml"
    }
    ```

##### Pipeline Utility Steps

- 功能：提取/创建 Zip 文件、生成(yaml)文件、读取 maven 项目的 pom.xml 文件(参数)、读取 properties 文件参数、从工作区中的文件中读取 JSON、在工作区中查找文件
- Pipeline 模式下使用

  ```groovy
  // 读取 pom.xml 文件
  pom = readMavenPom file: "./pom.xml"
  echo "${pom.artifactId}:${pom.version}"
  ```

### 节点管理(Manage Nodes)

- jenkins 支持分布式部署，此处可设置每个节点的构建队列个数
- 基于 k8s-helm 运行 jenkins 可配置成自动根据任务量创建 slave 节点。参考[http://blog.aezo.cn/2019/06/22/devops/helm/](/_posts/devops/helm.md#Jenkins)
- 新建节点(agent)
  - 远程工作目录如 `/var/jenkins_home/jenkins-agent/agent-ofbiz`(最终保存于 jenkins-master 家目录；通过此节点构建的项目，其工作空间保存于此目录)
  - 标签如 `agent-ofbiz`(配合[General](#General)中"限制项目的运行节点"配置使用)
  - 启动方式 Launch command 如 `java -jar /var/jenkins_home/bin/agent.jar`
    - 点击`Launch command`后面的帮助，可下载`agent.jar`
    - 需将`agent.jar`复制到 jenkins-master 家目录的 bin 目录下
  - 可用性，如选择"有需要的时候保持代理在线，当空闲时离线"。对应子配置`In demand delay=0; Idle delay=15`(任务构建延迟 0 分钟，节点如果空闲 15 分钟则停止)
  - **基于 k8s-helm 运行 jenkins 存储问题**：任务的工作目录保存在 slave 节点，每次执行完任务后，slave 节点删除，工作空间丢失。此时可自定义一个 agent，用于构建类似 ofbiz 等需要保存工作空间的项目

### 其他配置

## 常见问题

- 出现`Dependency errors`和`Downstream dependency errors`可根据提示升级对应插件，如果需要升级 jenkins 可以考虑忽略

## jenkins 源码解析

- jenkins 数据全部存储在内存或者文件中，启动 jenkins 前提前设置环境变量`JENKINS_HOME`则会在此目录生成数据文件.
  - JENKINS_HOME/plugins 为插件目录，安装的插件也都存放于此，如果需要 debugger 插件则将对应插件目录中的 jar 添加到 war 模块的依赖中去

### kohsuke

> kohsuke 为 jenkins 使用的 servlet 框架，亦是 jenkins 创始人 kohsuke 名字

- 测试如访问 http://localhost:8080/api/ 、 http://localhost:8080/api/json/ 、http://localhost:8080/newJob/
- jenkins 中 war 模块为最终打包的入口模块，此模块会引用 core、cli 模块。此模块`web.xml`配置如下

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

- Hudson(core)和 Jenkins(core)
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

## 附件

### Email-Extension-Default-Content

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>${ENV, var="JOB_NAME"}-第${BUILD_NUMBER}次构建日志</title>
    <style type="text/css">
      body {
        font-family: "Microsoft YaHei UI", "Microsoft YaHei", Arial,
          "Courier New", sans-serif;
        font-size: 16px;
        line-height: 20px;
      }
    </style>
  </head>
  <body
    leftmargin="8"
    marginwidth="0"
    topmargin="8"
    marginheight="4"
    offset="0"
  >
    (本邮件是程序自动下发，请勿回复！)<br />

    <table width="95%" cellpadding="0" cellspacing="0">
      <tr>
        <td>
          <br />
          <b><font color="#f4a34d">构建信息</font></b>
          <hr size="2" width="100%" align="center" />
        </td>
      </tr>
      <tr>
        <td>
          <ul>
            <li>项目名称 ： ${PROJECT_NAME}</li>
            <li>构建编号 ： 第${BUILD_NUMBER}次构建</li>
            <li>构建状态 ： <b>${BUILD_STATUS}</b></li>
            <li>触发原因： ${CAUSE}</li>
            <li>
              构建日志： <a href="${BUILD_URL}console">${BUILD_URL}console</a>
            </li>
            <li>构建 Url ： <a href="${BUILD_URL}">${BUILD_URL}</a></li>
            <li>工作目录 ： <a href="${PROJECT_URL}ws">${PROJECT_URL}ws</a></li>
            <li>项目 Url ： <a href="${PROJECT_URL}">${PROJECT_URL}</a></li>
          </ul>
        </td>
      </tr>
      <tr>
        <td>
          <b><font color="#f4a34d">变更集</font></b>
          <hr size="2" width="100%" align="center" />
        </td>
      </tr>
      <tr>
        <!--包含构建日志-->
        <td>
          ${JELLY_SCRIPT,template="html"}<br />
          <hr size="2" width="100%" align="center" />
        </td>
      </tr>
      <!--
        <tr>
            <td><b><font color="#f4a34d">构建日志 (最后 100行)</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <tr>
            <td>${BUILD_LOG, maxLines=100}<br/>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        -->
    </table>
  </body>
</html>
```

---

参考文章

[^1]: https://www.jianshu.com/p/7883c251eb09
[^2]: https://www.jianshu.com/p/358bfb64e3a6
[^3]: https://www.jianshu.com/p/ba0b4faba00c
