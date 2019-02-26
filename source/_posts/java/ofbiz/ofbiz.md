---
layout: "post"
title: "OFBiz"
date: "2017-12-09 10:17"
categories: java
tags: [ofbiz]
---

## 简介

## 安装编译启动

### 安装

#### 下载

- 下载：http://ofbiz.apache.org （http://www.apache.org/dyn/closer.lua/ofbiz/apache-ofbiz-13.07.02.zip）
- 解压：apache-ofbiz-13.07.02.zip到D:\java\apache-ofbiz-13.07.02（路径可自己更改）
- 使用版本apache-ofbiz-13.07.02的要求是JDK版本至少1.7以上（ofbiz已经封装好了tomcat，在framework-catalina-lib下）

#### 启动

- 命令行启动
    - 先cmd进入到命令行模式下，cd到你当前的OFBiz的工作环境(D:\java\apache-ofbiz-13.07.02)，也就是你的解压环境。
    - 然后运行 ant load-demo。第一次编译大概需要10分钟。提示“BUILD SUCCESSFUL”即表示部署成功
    - 再运行ant start 。出现类似“finished in [1328] milliseconds”就表示启动服务器成功
    - 访问前台http://localhost:8080/ecommerce 可设置语言为中文，现点击几个链接体验一下。
    - 访问后台https://localhost:8443/ordermgr
        - 提示：此网站的安全证书存在问题。点击“继续浏览此网站(不推荐)。”
        - 默认用户名密码：admin/ofbiz
    
    - 管理员工具页面：https://localhost:8443/webtools
    - 停止服务：定位到OFBiz启动的shell，按下Ctrl+C。我们将看到shell显示提示： 终止批处理操作吗(Y/N)? 输入Y来终止服务
    - 还有一种就是重新打开shell，并定位到该文件夹，使用命名：ant stop
    - 获取可用命令列表：ant –p
    - 启动乱码
        - Windows：修改tools/startofbiz.bat文件中的代码为（主要设置了UTF-8）"%JAVA_HOME%\bin\java" -Xms128M -Xmx512M -XX:MaxPermSize=512m -Dfile.encoding=UTF-8 -jar ofbiz.jar
        - Linux：修改tools/startofbiz.sh文件中代码MEMIF="-Xms128M -Xmx512M -XX:MaxPermSize=512m" 为 MEMIF="-Xms128M -Xmx512M -XX:MaxPermSize=512m -Dfile.encoding=UTF-8"
- 部署到eclipse
    - 从svn检出（速度可能有点慢）：在页面http://ofbiz.apache.org/source-repositories.html 找到相应的svn地址，如“release13.07: $ svn co http://svn.apache.org/repos/asf/ofbiz/branches/release13.07 ofbiz.13.07”
    表示版本ofbiz.13.07的svn地址为http://svn.apache.org/repos/asf/ofbiz/branches/release13.07 ，检出的项目命名为testOFBiz13.07
    - 直接从svn上检出的代码会有错误，这是因为有的代码是编译后才生成的，所以我们需要运行ant.bat进行编译，编译完毕后刷新工程即可清除错误
    - 在ant窗口-add buildfiles-找到项目testOFBiz13.07-选择根目录下的build.xml-完成
    - 第一次访问，要先在ant窗口双击load-demo，显示BUILD SUCCESSFUL则表示项目安装成功(第一次部署时间很长且有很多警告)。以后在ant窗口双击build[default]部署一下项目即可
    - 然后双击build目录下的start启动服务（控制台显示No crashed jobs to re-schedule则启动成功）。使用stop终止服务
    - 在浏览器访问http://localhost:8080/ecommerce 和 https://localhost:8443/ordermgr 用户名/密码 admin/ofbiz 
    - 第二种部署到eclipse中的方法是先将压缩包下载下来，再导入到eclipse中

### OFBiz目录结构
 
![ofbiz目录结构](/data/images/java/ofbiz-note1.png)

- Applications目录
    - Applications目录包含了OFBiz核心的应用程序组件，如订单管理，电子商务存储等。
    - component-load.xml文件配置需要载入哪几个应用程序组件。这里的每一个组件，都是一个基于OFBIZ构建的Web应用程序。
- framework目录
    - Framework框架目录，包含OFBiz框架的组件，例如实体引擎和服务引擎。这是OFBiz框架的核心，其他应用程序都是基于它来构建的。
    - component-load.xml文件配置需要载入哪几个框架组件。
- specialpurpose目录
    - specialpurpose专门目录，包含一些其他的应用程序，不是OFBiz核心的一部分。包含更多的OFBiz打包的应用程序和组件。
- hot-deploy热部署目录，以后创建的项目，都需要在这个目录下进行部署。结构如下：

    ![hot-deploy目录结构](/data/images/java/ofbiz-note2.png)

    - build.xml：Ant编译使用，不需要修改
    - ofbiz-component.xml：加载当前组件中所有的内容和文件使用
    - config目录：该文件夹内主要是配置文件(.properties)及国际化标签信息(.xml)
    - data目录：该文件夹内主要是存放下拉/字典类数据；Demo数据；权限数据；操作帮助数据在ofbiz-component.xml中引用
    - document目录：该文件夹内主要是存放文档数据，比如调用data中的helpdata下的帮助文档数据
    - dtd目录：dtd文件用于定义合法的XML文档构建模块，如上图中引用的dtd中xsd规范 
    - entitydef目录：包含两种文件实体定义文件和eca文件
    - lib目录：存放jar包 
    - script目录：存放基于minilang编写的方法，调用方式如下；可以传入和输出参数
    - servicedef目录：存放业务系统所需要执行的所有服务，而服务可以通过各种方式实现（java，webservice，minilang等等）同时这个文件夹和entity一样会存放服务对应的eca文件，实现也是同样，用作捆绑服务操作的行为
    - src目录：存放系统所需要执行的java方法，而服务可以调用java实现（java，webservice，minilang等等）
    - testdef目录：存放单元测试方法的地方，详细见ofbiz单元测试
    - webapp目录：如同其他web项目
        - 存放web.xml
        - 前端页面（ftl为主，被widget中的screen.xml调用）
        - action内存放groovy方法
        - controller.xml 控制请求
    - widget目录：存放XXXscreen.xml，被controller调用，XXXscreen.xml做两件事，一个是拼接html页面，通过嵌套，等方式最终引用webapp中的ftl或者jsp或者XXXscreen.xml中直接编写页面；另外一个就是赋值，通过action方法对前端的model或者参数赋值。

### build.xml命令

- `load-demo` 加载所有组件中的data数据(data文件夹中xml配置文件, 以`<entity-engine-xml>`开头), 每次load时不会删除原来的数据，只会新增(针对derby数据库)
- `clean-all` 删除所有runtime 文件夹中下的logs、data文件夹中的数据。(derby数据库在data文件夹中)

### 编译扩展

- 设置hot-deploy下组件(component)编译顺序
    - `hot-deploy/build.xml`
        
        ```xml
        <?xml version="1.0" encoding="UTF-8"?>
        <project name="OFBiz hot-deploy Build" default="build" basedir=".">
            <filelist id="hot-deploy-builds" dir="."
                files="ubase/build.xml,
                aplcodecenter/build.xml"/>
            <!--运行build命令时-->
            <target name="build">
                <iterate target="jar" filelist="hot-deploy-builds"/>
                <!--除去不需编译的组件-->
                <!--
                <externalsubant target="jar">
                    <filelist refid="hot-deploy-builds"/>
                </externalsubant>
                -->
                <externalsubant target="build">
                    <filelist dir=".">
                        <file name="umetro/build.xml"/>
                    </filelist>
                </externalsubant>
            </target>
            <!--运行clean命令时执行-->
            <target name="clean">
                <iterate target="clean" filelist="hot-deploy-builds"/>
                <!--除去不需clean的组件-->
                <externalsubant target="clean">
                    <filelist dir=".">
                        <file name="umetro/build.xml"/>
                    </filelist>
                </externalsubant>
            </target>
        </project>
        ```
    - 
- 设置hot-deloy下组件单独clean：在项目根目录下的`build.xml`中加入

    ```xml
    <target name="_clean-hot-deploy" description="clean hot-deploy jar">
		<hotdeployant target="clean"/>
    </target>
    ```

## 相关配置

### 端口配置

一台机器上运行两个ofbiz项目（主要是设置不同的端口）。修改以下端口，不和现有的重复即可。使用netstat –ano查看使用中的端口

- `OFBIZ_HOME/framework/catalina/ofbiz-component.xml`中的ajp默认端口8009，http默认端口8080，https默认端口8443
- `OFBIZ_HOME\framework\webapp\config\url.properties`中port.https和port.http的值
- `/framework/start/src/org/ofbiz/base/start/start.properties`（会生成ofbiz.jar）ofbiz.admin.port默认为10523
- `/framework/base/ofbiz-component.xml`中默认的端口是1099

    ```xml
    <container name="naming-container" loaders="rmi" class="org.ofbiz.base.container.NamingServiceContainer">
            <property name="host" value="0.0.0.0"/>
            <property name="port" value="1099"/>
    </container>
    ```
- `framework/service/ofbiz-component.xml`：`<container name="rmi-dispatcher" loaders="rmi" class="org.ofbiz.service.rmi.RmiServiceContainer">`下的`<property name="bound-port" value="1099"/>`默认为1099

## 其他

### 日志

- 默认日志生成策略
    - 访问日志每天生成一个文件，堆场项目每天会生成一个大小为300M的文件
    - 普通日志每天最多生成10个文件，每个文件大小为1M（超过文件数量会覆盖当天较早的日志）
    - 错误日志每天最多生成3个文件，每个文件大小为1M
- 日志生成策略配置：`framework/base/config/log4j2.xml`
- 日志生成级别配置：`framework/base/config/debug.properties`

### 常见问题

- 同样的代码部分机器出现启动成功但是页面无法显示。出现场景：使用ofbiz-13.07，windows安装jdk1.8，访问地址是可以进入到event，如果渲染的视图中包含ftl或者多个汉字则无法显示(很简短的一段html代码可正常显示)，通过curl可以返回html代码，火狐浏览器提示编码格式不正确，此时降低jdk版本为jdk1.7(ofbiz-13.07官方提交jdk1.7)可正常访问.(部分机器jdk1.8也可正常运行)
