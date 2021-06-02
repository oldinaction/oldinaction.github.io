---
layout: "post"
title: "SOFAStack"
date: "2021-04-11 12:40"
categories: java
tags: [springboot, plugin, 微服务]
---

## 简介

- [官网](https://www.sofastack.tech/)
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
- SOFABoot
    - 基于 Spring 上下文隔离的模块化，主模块(web)需要组织其他模块依赖(**即主模块的maven需要依赖其他模块**)
    - **模块不支持Controller层**
        - SOFABoot 模块一般用于封装对外发布服务接口的具体实现，属于业务层，Controller 属于展现层内容，官方不建议也不支持在 SOFABoot 模块中定义 Controller 组件，Controller 组件相关定义建议直接放在 Root Application Context
    - **可使用SOFAArk达到类隔离的目的，且SOFAArk支持运行时动态发布模块服务(Ark Biz)**
- OSGI
    - 支持类隔离
    - 支持动态模块化
- pf4j
    - 基于java特性SPI进行开发，参考[java-release.md#SPI](/_posts/java/java-release.md#SPI)
    - 支持类隔离，基于 ClassLoader 隔离的模块化
    - 支持动态模块化
    - Gitblit 项目使用的就是 PF4J 进行插件管理
- [springboot-plugin-framework](/_posts/java/springboot-plugin-framework.md)
    - 基于pf4j，且目标是整合springboot
    - **模块支持简单的Controller层**
- Java9 模块化
    - 基于 Jigsaw
    - 不允许运行时动态发布模块服务
    - 没有解决同一个类多版本的问题

## 模块简介

- `isle-sofa-boot-starter` SOFABoot模块隔离
- `sofa-ark-springboot-starter` SOFAArk类隔离
- `runtime-sofa-boot-plugin` 用于提供 SOFA JVM 服务通信能力，参考[Ark 服务通信(Biz 之间的通信问题)](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-ark-jvm/)
- `web-ark-plugin` 用于提供多 web 应用合并部署能力等
- `sofa-ark-container` Ark容器
- `healthcheck-sofa-boot-starter` SOFABoot监控检测
- `runtime-sofa-boot-starter` SOFABoot 在 v2.6.0 开始提供异步初始化 Spring Bean 能力

## SAFOBoot

- 使用参考: https://github.com/sofastack-guides/sofa-boot-guides

### 简单使用

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
- 使用SOFABoot的模块化开发打包插件变更

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

## SOFAArk

### 说明

- [SOFAArk 介绍](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-readme/)
- 架构图
    
    ![sofaark-arch.png](/data/images/java/sofaark-arch.png)
    - 如果 Ark 包只打包了一个 Biz，则该 Biz 默认成为宿主应用；如果 Ark 包打包了多个 Biz 包，需要配置指定宿主应用
    - 宿主应用不允许被卸载，一般而言，宿主应用会作为流量入口的中台系统，具体的服务实现会放在不同的动态 Biz 中，供宿主应用调用
    - 宿主应用可以使用 SOFAArk 提供的客户端 API 实现动态应用的部署和卸载
- **`Ark 包`是可执行 Fat Jar**，一般由 Ark Container、Ark Plugin(0个或多个)、Ark Biz(至少一个)
    - `Ark Container`
        - SOFAArk 容器(由sofa-ark-container模块提供)，负责 Ark 包启动运行时的管理；Ark Plugin 和 Ark Biz 运行在 SOFAArk 容器之上；容器具备管理插件和应用的功能
        - 容器启动成功后，会自动解析 classpath 包含的 Ark Plugin 和 Ark Biz 依赖，完成隔离加载并按优先级依次启动之
    - `Ark Plugin`
        - Ark 插件，满足特定目录格式要求的 Fat Jar，可以将一个或多个普通的 Java jar 打包成一个标准格式的 Ark Plugin。使用官方提供的 Maven 插件 `sofa-ark-plugin-maven-plugin`打包
        - 运行时由独立的 PluginClassLoader 加载，根据打包时配置的导出导入资源、类，构建运行时类加载模型。一般是Service包，不包含Controller层
    - Ark Biz
        - Ark 应用(配置、源码、依赖)被打包成 Biz 包组织在一起，但是特殊的依赖（Ark Plugin 和其他应用 Biz 包）不会被打入 Biz 包中，**`Ark Biz` 包是不可执行的 Fat Jar**。使用官方提供的 Maven 插件 `sofa-ark-maven-plugin`打包成上述Fat Jar
        - Ark Biz 是工程应用以及其依赖包的组织单元，包含应用启动所需的所有依赖和配置；一个 Ark 包中可以包含多个 Ark Biz 包，按优先级依次启动，Biz 之间通过 JVM 服务交互
        - 可以包含Controller层(引入web依赖即可)
        - [Ark Biz 生命周期](https://www.sofastack.tech/projects/sofa-boot/sofa-ark-biz-lifecycle/)
    - 启动顺序：Ark Container > Ark Plugin > Ark Biz
    - 类索引关系说明
        - Ark Biz 之间通过 JVM 服务(Ark概念)交互，即使用@SofaService/@SofaReference进行交互
            - 每个Biz有自己的Controller层，原本是部署在不同的JVM，因此需要通过网络交互(如RPC)；而Ark架构，支持合并部署Biz，此时使用JVM服务交互，减少网络传输层
        - Ark Biz 和 Ark Plugin 是单向类索引关系，即只允许 Ark Biz 索引 Ark Plugin 加载的类和资源，反之则不允许(只能Ark Biz调用Ark Plugin)
        - Ark Plugin 之间是双向类索引关系，即可以相互委托对方加载所需的类和资源(Ark Plugin可相互调用)
- 动态Ark Biz包安装
    - telnet：Ark容器默认会启动一个监听在1234端口的telnet服务
    - API：使用`ArkClient`类
    - zookeeper方式
- Ark 容器启动流程：https://www.sofastack.tech/projects/sofa-boot/sofa-ark-startup/

### 使用

- 参考 https://github.com/sofastack-guides/sofa-ark-dynamic-guides
- 命令

```bash
# 连接container，成功会显示命令行`sofa-ark>`
telnet localhost 1234
help # 查看帮助
biz -a # 查看所有安装的biz包
```


- 错误： https://github.com/sofastack/sofa-boot/issues/327
- 相关文章
    - https://zhuanlan.zhihu.com/p/114647271
