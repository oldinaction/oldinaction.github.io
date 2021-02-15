---
layout: "post"
title: "OSGi —— Java动态化模块化规范"
date: "2021-02-09 19:10"
categories: [arch, java]
---

## 简介

- OSGi：Open Service Gateway Initiative
- [官网：https://www.osgi.org/](https://www.osgi.org/)
- Eclipse的插件机制就是基于OSGI规范实现
- 相关实现
    - [Felix](https://felix.apache.org/) 是一个 OSGi 版本 4 规范的 Apache 实现
        - [Apache Karaf](https://karaf.apache.org/)：基于Felix实现，是一个运行基于OSGi的应用程序的平台，提供了如命令行界面将使我们能够与平台进行交互
        - [ServiceMix](http://servicemix.apache.org/)：它将Apache ActiveMQ，Camel，CXF和Karaf的特性和功能统一到一个功能强大的运行时平台中，可用于构建自己的集成解决方案，它提供了由OSGi独家提供的完整的企业级ESB。最近更新2017年
    - [Equinox](http://www.eclipse.org/equinox/) 是 Eclipse对应的OSGi框架(容器)，是AppFuse的一个轻量级版本。对web的默认支持Spring MVC、Hibernat等组件
- [Gemimi Blueprint](http://www.eclipse.org/gemini/) 由Eclipse维护，部分代码由SpringSource捐献的`Spring DM`(Spring Dynamic Modules，前身为Spring OSGi)项目代码 [^3]
    - SpringDM并不是OSGi的标准实现，它的运行必须依赖OSGi的标准容器，比如Equinox、Felix或是Knopflerfish等
    - SpringDM完成了OSGi服务的注册、查询、使用和监听，我们也可以将这些OSGi服务称之为Bean

### OSGi概念

- bundle
    - bundle其表现就是一个jar包，如eclipse的一个插件
    - OSGI 类加载器并不遵循 Java 的双亲委派模型，OSGi 为每个 bundle 提供一个类加载器，该加载器能够加载 bundle 内部的类和资源，bundle 之间的交互是从一个 bundle 类加载器委托到另一个 bundle 类加载器，所有 bundle 都有一个父类加载器 [^1]
        - Fragment bundle 是一种特殊的 bundle，不是独立的 bundle，必须依附于其他 bundle 来使用
        - 由于基于不同的类加载器，如果其中一个模块无法正常运行，不会影响其他模块运行
    - 每个模块（bundle）都有自己的类加载器。bundle包使用导入包定义了外部依赖关系。其他bundle包只能使用明确导出的软件包。**模块化的这一层确保在捆绑包之间仅共享API类，并且严格隐藏实现类**，不能使用 `new ServiceImpl()` 类似基于实现的代码

### OSGi与微服务区别

- OSGi [^2]
    - 各模块是基于同一个JVM，服务(模块)直接调用是基于方法级别的，不会有网络开销。各服务也叫µServices或纳米服务
    - 可基于单体部署
- 微服务(Micro Services)
    - 各模块基于不同JVM，甚至可基于不同语言实现。服务见调用存在网络开销，协调许多远程服务之间的通信通常需要异步编程模型并发送消息
    - 部署基于微服务的系统需要在DevOps方面进行大量工作
- 也可以选择将两种方法混合使用

### OSGi相关接口

- `BundleActivator` 定义组件被启动或停止时的动作
    - start
    - stop
- `ServiceListener` 监听服务状态
    - serviceChanged(ServiceEvent), ServiceEvent包含有REGISTERED(注册)、MODIFIED、UNREGISTERING(注销)、MODIFIED_ENDMATCH

## OSGi示例

- 参考：https://www.baeldung.com/osgi
- 示例源码：https://github.com/oldinaction/smjava/tree/master/osgi
- 常见的OSGi容器Apache Felix和Eclipse's Equinox。而Eclipse's Equinox很久没有更新，因此基于Felix容器测试
- 下载Felix容器，或者直接下载Apache Karaf容器(推荐，Karaf是基于Felix的OSGi管理平台，包含命令界面)

```bash
# https://karaf.apache.org/get-started.html
# 启动Karaf可测试是否可正常运行. 会进入`karaf@root()>`命令界面
bin\karaf.bat start

# 设置 KARAF_HOME 环境变量，变把相应bin目录加入到Path下

# 相关目录
data/log # 日志目录
```
- 引入依赖

```xml
<dependency>
    <groupId>org.osgi</groupId>
    <artifactId>org.osgi.core</artifactId>
    <version>6.0.0</version>
</dependency>

<!-- 打包插件，打出来的jar包，MANIFEST.MF中包含了OSGi相关信息 -->
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.felix</groupId>
            <artifactId>maven-bundle-plugin</artifactId>
            <extensions>true</extensions>
            <configuration>
                <instructions>
                    <!-- cn.aezo.osgi -->
                    <Bundle-SymbolicName>${project.groupId}.${project.artifactId}</Bundle-SymbolicName>
                    <!-- osgi-intro-sample-service -->
                    <Bundle-Name>${project.artifactId}</Bundle-Name>
                    <!-- 1.0-SNAPSHOT -->
                    <Bundle-Version>${project.version}</Bundle-Version>

                    <!-- 激活模块入口 -->
                    <Bundle-Activator>com.baeldung.osgi.sample.service.implementation.GreeterImpl</Bundle-Activator>
                    <Private-Package>com.baeldung.osgi.sample.service.implementation</Private-Package>
                    <!-- 服务导出的包，client只需要应用服务的pom即可使用服务；client无需导出包则不需要此配置 -->
                    <Export-Package>com.baeldung.osgi.sample.service.definition</Export-Package>
                </instructions>
            </configuration>
        </plugin>
    </plugins>
</build>
```
- 上述打包出来的MANIFEST.MF文件如下

```java
Manifest-Version: 1.0
Bnd-LastModified: 1612846013882
Build-Jdk: 1.8.0_111
Built-By: smalle
Bundle-Activator: com.baeldung.osgi.sample.service.implementation.Greete
 rImpl
Bundle-ManifestVersion: 2
Bundle-Name: osgi-intro-sample-service
Bundle-SymbolicName: cn.aezo.osgi-intro-sample-service
Bundle-Version: 1.0.0.SNAPSHOT
Created-By: Apache Maven Bundle Plugin
Export-Package: com.baeldung.osgi.sample.service.definition;version="1.0
 .0.SNAPSHOT"
Import-Package: com.baeldung.osgi.sample.service.definition,org.osgi.fra
 mework;version="[1.8,2)"
Require-Capability: osgi.ee;filter:="(&(osgi.ee=JavaSE)(version=1.8))"
Tool: Bnd-3.3.0.201609221906
```

- 测试

```bash
# 在本项目目录启动
karaf

## 简单使用
# 打包项目
mvn clean install

# 安装组件. 显示如 Bundle ID: 59，说明Karaf从本地Maven存储库加载到组件
bundle:install mvn:cn.aezo/osgi-intro-sample-activator/1.0-SNAPSHOT

# 启动上述组件. 显示 Hello World.
bundle:start 59

# 停止上述组件. 显示 Goodbye World.
bundle:stop 59

# 卸载上述组件
bundle:uninstall 59

## 基于服务调用
# 安装服务端和客户端
install mvn:cn.aezo/osgi-intro-sample-service/1.0-SNAPSHOT  # Bundle ID: 60
install mvn:cn.aezo/osgi-intro-sample-client/1.0-SNAPSHOT   # Bundle ID: 61

# 启动客户端(什么都不会发生，因为客户端启动后正在等待服务)
start 61

# 启动服务端. 返回如下信息
# Registering service.
# Notification of service registered.
# Hello John
start 60
```







---

参考文章

[^1]: https://developer.ibm.com/zh/languages/java/articles/j-springboot-application-integrated-osgi-framework-development/
[^2]: http://paulonjava.blogspot.com/2014/04/micro-services-vs-osgi-services.html
[^3]: https://blog.csdn.net/wdvceafvcsrgfv/article/details/78868508

