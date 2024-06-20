---
layout: "post"
title: "SOFAStack"
date: "2021-04-11 12:40"
categories: java
tags: [springboot, plugin, 微服务]
---

## 简介

- [官网](https://www.sofastack.tech/)、[蚂蚁产品说明](https://tech.antfin.com/products/SOFA)
- SOFAStack技术栈
    - 包含SOFABoot、SOFAArk、SOFARPC等子项目
    - 其中SOFABoot是基于Springboot开发，可和SOFAArk结合使用
- SOFABoot模块隔离
    - maven模块隔离的基础上，增加对Spring 上下文隔离
- SOFAArk类隔离
    - 每个模块都有独立的 ClassLoader，消除不同类版本冲突问题

## Java模块化开发对比

- 参考文章 https://www.sofastack.tech/projects/sofa-boot/modular-development/
    - 基于代码组织上的模块化，如使用Maven
        - 这是最常见的形式，在开发期，将不同功能的代码放在不同 Java 工程下，在编译期被打进不同 jar 包，**在运行期，所有 Java 类都在一个 classpath 下，没做任何隔离**
    - 基于 Spring 上下文隔离的模块化，SOFABoot使用此方式
        - 借用 Spring 上下文来做不同功能模块的隔离，在开发期和编译期，代码和配置也会分在不同 Java 工程中，但在运行期，**不同模块间的 Spring Bean 相互不可见**
        - **但是所有的 Java 类还是在同一个 ClassLoader 下**
    - 类隔离，基于 ClassLoader 隔离的模块化，SOFAArk使用此方式
        - 借用 ClassLoader 来做隔离，**每个模块都有独立的 ClassLoader，模块与模块之间的 classpath 不同**
- 对比 SOFABoot、OSGi、SOFAArk、Java9 模块化
    - https://www.sofastack.tech/blog/sofastack-modular-isolation/
    - https://www.sofastack.tech/projects/sofa-boot/faq/
    - SOFABoot各模块基于Maven组织(通过导入class类实现class共用)，各模块Spring上下文隔离
    - SOFAArk各Biz/Plugin间class类隔离，Spring上下文也隔离
- SOFABoot
    - 基于 Spring 上下文隔离的模块化，主模块(web)需要组织其他模块依赖(**即主模块的maven需要依赖其他模块**)
    - **模块不支持Controller层**
        - SOFABoot 模块一般用于封装对外发布服务接口的具体实现，属于业务层，Controller 属于展现层内容，官方不建议也不支持在 SOFABoot 模块中定义 Controller 组件，Controller 组件相关定义建议直接放在 Root Application Context
    - **可使用SOFAArk达到类隔离的目的，且SOFAArk支持运行时动态发布模块服务(Ark Biz)**
    - 阿里还有一套Pandora、Pandora Boot的类隔离中间件
- OSGI
    - 支持类隔离
    - 支持动态模块化
- pf4j
    - 基于java特性SPI进行开发，参考[java-release.md#SPI](/_posts/java/java-release.md#SPI)
    - 支持类隔离，基于 ClassLoader 隔离的模块化
    - 支持动态模块化
    - Gitblit 项目使用的就是 PF4J 进行插件管理
- [springboot-plugin-framework](/_posts/java/archive/springboot-plugin-framework.md)
    - 基于pf4j，且目标是整合springboot
    - **模块支持简单的Controller层**
- Java9 模块化
    - 基于 Jigsaw
    - 不允许运行时动态发布模块服务
    - 没有解决同一个类多版本的问题

## SOFA技术栈模块简介

- `isle-sofa-boot-starter` SOFABoot模块隔离
- `sofa-ark-springboot-starter` SOFAArk类隔离
- `sofa-ark-container` Ark容器
- `healthcheck-sofa-boot-starter` SOFABoot监控检测
- `runtime-sofa-boot-starter` SOFABoot 在 v2.6.0 开始提供异步初始化 Spring Bean 能力
- 插件
    - `runtime-sofa-boot-plugin` 用于提供 SOFA JVM 服务通信能力，参考[Ark 服务通信(Biz 之间的通信问题)](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-ark-jvm/)
    - `web-ark-plugin` 用于提供多 web 应用合并部署能力等

## 通信/调用

- SofaBoot中各模块相互调用
    - 使用JVM服务通信
        - 支持以下实现方式
            - XML 方式
            - Annotation 方式：可使用@SofaService/@SofaReference进行注入
            - 编程 API 方式：基于 ServiceClient 和 ReferenceClient进行调用和声明
                - 方式1：实现 ClientFactoryAware 接口
                - 方式2：基于 @SofaClientFactory 注解获取编程 API。参考：SqBiz下的`SqSofaServiceHelper.java`
                - JVM服务通信说明参考下文
                - 不同ArkBiz/Plugin下调用说明参考下文
        - **JVM服务通信注意点**
            - 整个通信在同一线程下，会找到加载对应服务/模块的ClassLoader(如ArkBiz的方式)，进行当前线程的ClassLoader切换(参考ServiceProxy)。由于切换了ClassLoader，尽管类名相同，对应的class对象可能是不同的(同一class的前提是由同一个类加载)，从而静态成员的数据也不能共享，如ThreadLocal无法在两个模块见共享的问题，解决方案如下
                - 可将相关类封装成Plugin，这样不同Biz直接的使用同一个类时，都是由同一Plugin类加载器加载的，因此静态成员数据即可共享
                - 通过Root Application Context中转(未测试)
                - 通过SOFABoot扩展点(未测试)
            - 传入参数和返回结果会被序列化
                - 数据传输都会被序列化(被调用中修改参数对象并不会反映到调用者传入的参数上)，被调用函数的全部结果需要通过返回值进行反映。参考：SqBiz下的`SofaAuthProviderDelegate.java`
        - **不同ArkBiz/Plugin下调用**
            - 所有的@SofaService/@SofaReference/Extension等都是基于ComponentManager(实现类ComponentManagerImpl)在初始化时进行注册，且都是缓存在ComponentManagerImpl#registry集合中供调用时使用
            - 由于ArkBiz/Plugin的类加载器不同，所以ComponentManagerImpl在各类加载器中对应不同类，从而ComponentManagerImpl#registry保存的数据也不是共享的，从而导致无法跨Ark调用
            - 解决：参考：SqBiz下的`SqSofaServiceHelper.java`(跨模块可以通过uniqueId+ISqSofaService接口获取到对应服务，再通过SpringU反射调用服务)
    - 基于RPC进行调用
        - RPC基于TCP协议时(gRPC是基于HTTP2进行通信的)是建立的长链接，不需要像HTTP一样每次请求(HTTP为无状态)都进行TCP的三次握手，减少了网络开销
- (SofaArk)Biz-Biz通信: 同 SofaBoot使用JVM服务通信
    - 参考 https://www.sofastack.tech/projects/sofa-boot/sofa-ark-ark-jvm/
    - **目前仅sofa v3.1.4支持**，sofa v3.2.2~v3.7.0报错
- (SofaArk)Biz-Plugin通信: 参考 https://www.sofastack.tech/projects/sofa-boot/sofa-ark-ark-service/
    - PluginContext 中提供了发布服务和引用服务的接口
    - PluginActivator 插件只需要实现此接口，并在 MANIFEST.MF 中配置 activator 属性，就会在启动时执行 start 方法，停止时执行 stop 方法
    - @ArkInject

## SAFOBoot

- 使用参考: https://github.com/sofastack-guides/sofa-boot-guides

### 简单使用(不使用其模块隔离功能)

- 依赖和打包

```xml
<!-- 将springboot项目的parent换行sofaboot(内嵌springboot) -->
<parent>
    <groupId>com.alipay.sofa</groupId>
    <artifactId>sofaboot-dependencies</artifactId>
    <version>3.2.0</version>
</parent>

<!-- 如果不使用SOFABoot的模块隔离，则只需要springboot打包插件即可 -->
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
</plugin>
```
- 如果需要使用高版本的sofaboot(当前最高v3.6.0)，需要增加snapshot仓库配置

```xml
<profiles>
    <profile>
        <id>default</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <repositories>
            <repository>
                <snapshots>
                    <enabled>true</enabled>
                </snapshots>
                <id>maven-snapshot</id>
                <url>https://oss.sonatype.org/content/repositories/snapshots</url>
            </repository>
        </repositories>
        <pluginRepositories>
            <pluginRepository>
                <snapshots>
                    <enabled>true</enabled>
                </snapshots>
                <id>maven-snapshot</id>
                <url>https://oss.sonatype.org/content/repositories/snapshots</url>
            </pluginRepository>
        </pluginRepositories>
    </profile>
</profiles>
```

### 模块化开发

- 如果需要使用SOFABoot的模块化开发还需增加依赖

```xml
<!-- 主模块需要加模块隔离依赖 -->
<dependency>
    <groupId>com.alipay.sofa</groupId>
    <artifactId>isle-sofa-boot-starter</artifactId>
</dependency>
<!-- 可选，主模块中增加健康检查。启动后可访问 http://localhost:8088/actuator 查看信息 -->
<dependency>
    <groupId>com.alipay.sofa</groupId>
    <artifactId>healthcheck-sofa-boot-starter</artifactId>
</dependency>
<!-- 主模块中还需增加对其他模块的依赖（此处省略） -->
<!-- 主模块中增加springboot-web、db等依赖（此处省略） -->

<!-- 子模块需要增加SOFA运行时依赖 -->
<dependency>
    <groupId>com.alipay.sofa</groupId>
    <artifactId>runtime-sofa-boot-starter</artifactId>
</dependency>
```
- 使用SOFABoot的模块化开发时，打包插件变更

```xml
<!-- 主模块打包 -->
<plugin>
    <!-- http://docs.spring.io/spring-boot/docs/current/maven-plugin/usage.html -->
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <version>1.4.2.RELEASE</version>
    <configuration>
        <!-- executable fat jar -->
        <outputDirectory>../target/boot</outputDirectory>
        <classifier>executable</classifier>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>repackage</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```
- Annotation方式发布和引用服务，还支持XML和API的方式

```java
// 服务端使用 @SofaService 注解来发布服务
// 一般将接口(此处的SampleJvmService)放到一个门面(Facade)子工程中，这样服务提供者和消费者可同时引入此接口工程依赖
@SofaService // @SofaService(uniqueId = "annotationImpl")
public class SampleJvmServiceAnnotationImpl implements SampleJvmService {
    @Override
    public String message() {
        return "Hello, jvm service annotation implementation.";
    }
}

// 客户端使用 @SofaReference 开引用服务
public class JvmServiceConsumer implements ClientFactoryAware {
    @SofaReference // @SofaReference(uniqueId = "annotationImpl")
    private SampleJvmService sampleJvmServiceAnnotationImpl;
}
```
- 定义 SOFABoot 模块（类似模块的导入导出）

```ini
# resources/sofa-module.properties
# 当前模块名，模块名只需要保证全局唯一即可(一般可使用pom包名)
Module-Name=com.alipay.sofa.service-consumer
# 需要引入的模块
Require-Module=com.alipay.sofa.service-provider
```

### 扩展点

- SOFABoot 支持模块化隔离，在实际的使用场景中，一个模块中的 bean 有时候需要开放一些入口，供另外一个模块扩展
- SOFABoot 借鉴和使用了 Nuxeo Runtime 项目 以及 [nuxeo](https://github.com/nuxeo) 项目(较早的一款企业模块化项目)，并在上面扩展，与 Spring 融合，提供扩展点的能力
- 案例：https://github.com/glmapper/glmapper-sofa-extension
    - 说明文档：https://blog.csdn.net/weixin_33810006/article/details/89534212
- 使用流程
    - 定义一个需要被扩展的 bean 接口
    - 实现上述 bean 接口，并增加函数registerExtension用来接受扩展传递过来的扩展值(普通扩展值/扩展bean名)，通过接受此扩展值来覆盖当前实现类的属性值
    - 定义扩展点(可以理解为上述bean的哪个属性)
    - 注册扩展点
    - 实现扩展(实现上述bean接口)
    - 定义扩展值(如果基于客户端进行注册时，需要单独写到xml文件中)
    - 注册扩展
- 缺陷：不支持  跨Ark Biz进行扩展
- **SqBiz扩展(支持跨Ark Biz的扩展)**
    - 背景：由于SOFABoot拓展点跨Ark则无法使用(扩展点和扩展注册时均保存在ComponentManagerImpl#registry中，而此类并未暴露成Ark Plugin，从而类属性数据不共享)；且SOFAArk自定义扩展点只适用于 Ark Plugin 之间
    - 原理：跨模块可以通过uniqueId+ISqSofaService接口获取到对应服务，再通过SpringU反射调用服务
    - 使用
        - (1) 注册扩展：`SqSofaExtensionHelper.register(TaokeConst.SofaUniqueId, UserInfoExtension.class, "createUserInfoEnd");` (注意主类需加@EnableSqU)
        - (2) 调用扩展：`SqSofaExtensionHelper.invoke(UserInfoExtension.class, "createUserInfoEnd", "123456");`

## SOFAArk

### 说明

- [SOFAArk 介绍](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-readme/)
- SOFAArk 类隔离框架设计实现主要基于 OSGi 规范及蚂蚁金服的 CloudEngine 容器；同时也参考了 Spring Boot 及阿里的 PandoraBoot
- **相关框架解读**
    - https://blog.csdn.net/maoyeqiu/article/details/108994304
    - https://blog.hufeifei.cn/2020/05/Alibaba/Pandora/
- 架构图
    
    ![sofaark-arch.png](/data/images/java/sofaark-arch.png)
    - 如果 Ark 包只打包了一个 Biz，则该 Biz 默认成为宿主应用；如果 Ark 包打包了多个 Biz 包，需要配置指定宿主应用
    - 宿主应用不允许被卸载，一般而言，宿主应用会作为流量入口的中台系统，具体的服务实现会放在不同的动态 Biz 中，供宿主应用调用
    - 宿主应用可以使用 SOFAArk 提供的客户端 API 实现动态应用的部署和卸载
- **`Ark 包`**是可执行 Fat Jar，一般由 Ark Container、Ark Plugin(0个或多个)、Ark Biz(至少一个)
    - `Ark Container`
        - SOFAArk 容器(由sofa-ark-container模块提供)，负责 Ark 包启动运行时的管理；Ark Plugin 和 Ark Biz 运行在 SOFAArk 容器之上；容器具备管理插件和应用的功能
        - 运行 Ark 包，Ark Container 优先启动，容器自动解析 Ark 包中含有的 Ark Plugin 和 Ark Biz，并读取他们的配置信息，构建类和资源的加载索引表
        - 然后使用独立的 ClassLoader 加载并按优先级配置依次启动
    - `Ark Plugin`
        - Ark 插件，满足特定目录格式要求的 Fat Jar，可以将一个或多个普通的 Java jar 打包成一个标准格式的 Ark Plugin。使用官方提供的 Maven 插件 `sofa-ark-plugin-maven-plugin`打包。[参考文档](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-ark-plugin/)
        - 运行时由独立的 PluginClassLoader 加载，根据打包时配置的导出导入资源、类，构建运行时类加载模型。一般是Service包，不包含Controller层
        - **需要在pom中设置依赖关系**
        - **更多的用处是类隔离**：假设项目依赖A、B两个jar包，而A、B又分别依赖C1和C2，从而可能导致包依赖冲突，而假设A、B是打包出来的Ark Plugin(只暴露服务类，C相关的内可不用导出)则不会存在问题，可同时引用到项目中，其他用法同普通jar包引用。参考：https://juejin.cn/post/6844903653828984845
        - **还可抽离依赖**：将相同的依赖打成插件包到基座中，从而其他Biz包只需要引入相关包或类即可，减少Biz包的体积
    - Ark Biz
        - Ark 应用(配置、源码、依赖)被打包成 Biz 包组织在一起，但是特殊的依赖（Ark Plugin 和其他应用 Biz 包）不会被打入 Biz 包中，**`Ark Biz` 包是不可执行的 Fat Jar**。使用官方提供的 Maven 插件 `sofa-ark-maven-plugin`打包成上述Fat Jar。[参考文档同Ark包](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-ark-jar/)
        - Ark Biz 是工程应用以及其依赖包的组织单元，包含应用启动所需的所有依赖和配置；一个 Ark 包中可以包含多个 Ark Biz 包，按优先级依次启动，Biz 之间通过 JVM 服务交互
        - 可以包含Controller层(引入web依赖即可)
        - [Ark Biz 生命周期](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-biz-lifecycle/)
    - 启动顺序：Ark Container > Ark Plugin > Ark Biz
    - **类索引关系说明**
        - Ark Biz 之间通过 JVM 服务(Ark概念)交互，即使用@SofaService/@SofaReference进行交互
            - 每个Biz有自己的Controller层，原本是部署在不同的JVM，因此需要通过网络交互(如RPC)；而Ark架构，支持合并部署Biz，此时使用JVM服务交互，减少网络传输层
        - Ark Biz 和 Ark Plugin 是单向类索引关系，即只允许 Ark Biz 索引 Ark Plugin 加载的类和资源，反之则不允许(只能Ark Biz调用Ark Plugin)。Ark Biz无需打包Ark Plugin，会自动优先查找Ark Plugin，也可定义禁止优先查找Ark Plugin的类(加入Plugin封装了第三方jar，Biz对第三方jar的依赖可维持不变，仅在打包时配置剔除此第三方jar从而减小打包体积)
        - Ark Plugin 之间是双向类索引关系，即可以相互委托对方加载所需的类和资源(Ark Plugin可相互调用)。Ark Plugin只会优先从其他Ark Plugin中查找导入的类，未导入的则从当前Ark Plugin查找
- SofaArk相关常量参考`com.alipay.sofa.ark.spi.constant.Constants`

### 生命周期

- 参考：https://www.sofastack.tech/projects/sofa-boot/sofa-ark-biz-lifecycle/
- Ark 容器启动流程：https://www.sofastack.tech/projects/sofa-boot/sofa-ark-startup/
- Biz生命周期
    - unresolved: 未注册，此时 Biz 包未被运行时解析
    - resolved: Biz 包解析完成，且已注册，此时 Biz 包还没有安装或者安装中
    - activated: Biz 包启动完成，且处于激活状态，可以对外提供服务
    - deactivated: Biz 包启动完成，但出于未激活状态，模块多个版本时，只有一个版本出于激活状态(注意这个状态只对 JVM 服务生效，对 RPC 等其他中间件无效)
    - broken: Biz 包启动失败后状态
- 安装 Biz
    - 解析模块
    - 注册模块
    - 启动模块
    - 健康检查
    - 切换状态

### 事件

- 官方文档目前是v1.0的(但是升级v1.0存在其他问题)
- v0.6暂不知道如果发送事件，通过`ArkServiceContainerHolder.getContainer().getService(EventAdminService.class).sendEvent(...)`会报空指针，因为ArkServiceContainerHolder.getContainer()只有在container所在Ark才有值，连主Biz也无法获取到(和Ark container使用得是不同的类加载器)

### 使用

- 参考 https://github.com/sofastack-guides/sofa-ark-dynamic-guides
- 命令

```bash
## 连接container，成功会显示命令行`sofa-ark>`
telnet localhost 1234
## 退出
Ctrl+] # 退出到telnet命令行
quit # 退出到命令行


## 查看帮助
help
## biz
# 安装biz包
biz -i file:///C:/Users/smalle/Desktop/sofa-ark-dynamic-guides-master/target/ark-dynamic-module-1.0.0-ark-biz.jar
# 卸载biz包
biz -u ark-dynamic-module:0.0.1
# 查看所有安装的biz包
biz -a

# plugin
# 查看所有plugin列表
plugin -a
```

#### 动态引入Biz

- 动态Ark Biz包安装方式
    - telnet：Ark容器默认会启动一个监听在1234端口的telnet服务
    - API：使用`ArkClient`类
    - zookeeper方式
- sofa v3.1.4
    - 必须要main方法
    - 必须要定义spring.application.name配置
    - 不能有sofa-module.properties配置
    - 引入依赖：runtime-sofa-boot-plugin、sofa-ark-springboot-starter、web-ark-plugin
    - 一般可设置 com.alipay.sofa.boot.skipJvmReferenceHealthCheck=true, 即配置为不检查组件的健康状态（如有些组件实现是通过ark动态安装进来的，就会出现Biz启动不成功的问题）

#### 多Biz启动

- 开发环境(sofa v3.6.0, 此版本不支持Biz间服务调用)
    - 在启动类所在模块根目录增加`conf/ark/bootstrap.properties`
    - 并设置master biz: `com.alipay.sofa.ark.master.biz=Startup In IDE`
    - 然后将其他biz-jar放到某个文件夹下，并将此文件夹添加到此模块的依赖包中(ark会扫码classpath下所有jar看是否为plugin或biz)

### 插件

- com.alipay.sofa.runtime.spi.log.SofaLogger 日志
    - `SofaLogger.info("SofaRuntime is activating.", new Object[0]);`

### 记录

- 引入sofa-ark-plugin-maven后，说明此模块为Biz模块，可以为Ark包(包含主Ark Biz + ArK Container + Plugins)或Ark Biz(普通Biz)
- 引入sofa-ark-plugin-maven-plugin后，说明此模块为plugin模块，最终打包出来的是ark plugin
    - 一般是引入到主Biz中打包到Ark包中，其他Biz包只需依赖scope=provided引入，最终Biz包也不会包含此插件jar
- sofa ark shade

```xml
<!--the specify dependency would not be contained in lib directory, but shaded in ark plugin-->
<shades>
    <shade>com.alipay.sofa:sample-ark-plugin-common:1.0-SNAPSHOT</shade>
</shades>
```


## 错误

- IDE启动报错：`javax.management.InstanceAlreadyExistsException: org.springframework.boot:type=Admin,name=SpringApplication`
    - 参考：https://github.com/sofastack/sofa-boot/issues/327
    - IDEA启动时会自动增加一些参数，如`-Dcom.sun.management.jmxremote ... -Dspring.application.admin.enabled=true`等。此时可通过设置IDEA启动配置的参数覆盖，**如增加`spring.application.json={"spring.application.admin.enabled": false}`**

