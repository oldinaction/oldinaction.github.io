---
layout: "post"
title: "OSGi —— Java动态模块化规范"
date: "2021-02-09 19:10"
categories: java
---

## 简介

- **Java其他插件化开发(OSGi文档较少，2021-02弃用)**
    - [sofastack](https://www.sofastack.tech/)
    - [pf4j](https://github.com/pf4j/pf4j)
    - [springboot-plugin-framework, 基于pf4j](https://gitee.com/starblues/springboot-plugin-framework-parent)
- OSGi：`Open Service Gateway Initiative` 是一个Java模块化规范
- [官网：https://www.osgi.org/](https://www.osgi.org/)
- Eclipse的插件机制就是基于OSGI规范实现
- 相关实现(运行时容器)
    - [Felix](https://felix.apache.org/) 是一个 OSGi 版本 4 规范的 Apache 实现
        - [Apache Karaf](https://karaf.apache.org/)：基于Felix实现，是一个运行基于OSGi的应用程序的平台，提供了如命令行界面将使我们能够与平台进行交互
        - [ServiceMix](http://servicemix.apache.org/)：它将Apache ActiveMQ，[Camel](https://camel.apache.org/)，CXF和Karaf的特性和功能统一到一个功能强大的运行时平台中，可用于构建自己的集成解决方案，它提供了由OSGi独家提供的完整的企业级ESB。最近更新2017年
    - [Equinox](http://www.eclipse.org/equinox/) 是 Eclipse对应的OSGi框架(容器)，是AppFuse的一个轻量级版本。对web的默认支持Spring MVC、Hibernat等组件
- [Gemimi Blueprint](http://www.eclipse.org/gemini/) 由Eclipse维护，部分代码由SpringSource捐献的`Spring DM`(Spring Dynamic Modules，前身为Spring OSGi)项目代码 [^3]
    - SpringDM并不是OSGi的标准实现，它的运行必须依赖OSGi的标准容器，比如Equinox、Felix或是Knopflerfish等
    - SpringDM完成了OSGi服务的注册、查询、使用和监听，我们也可以将这些OSGi服务称之为Bean
- 基于[springboot osgi demo](https://github.com/klebeer/karaf-springboot.git)未测试成功

### 相关文档

- [OSGi中文社区](http://osgi.com.cn/)
- [OSGi入门教程](https://course.tianmaying.com/osgi-toturial)
- [理解OSGi](https://course.tianmaying.com/osgi)
- [一种基于OSGi和Docker的SaaS平台热插拔系统设计方案](https://www.tianmaying.com/tutorial/plugin)

### OSGi与微服务区别

- OSGi [^2]
    - 各模块是基于同一个JVM，服务(模块)直接调用是基于方法级别的，不会有网络开销。各服务也叫µServices或纳米服务
    - 可基于单体部署
- 微服务(Micro Services)
    - 各模块基于不同JVM，甚至可基于不同语言实现。服务见调用存在网络开销，协调许多远程服务之间的通信通常需要异步编程模型并发送消息
    - 部署基于微服务的系统需要在DevOps方面进行大量工作
- 也可以选择将两种方法混合使用

### OSGi概念

- OSGI规范提供了`Bundle`、`Event`、配置管理（`ConfigAdmin`）、声明式服务（`Delarative Service`）、`Service Tracker`、`Blueprint`等等运行时机制，方便我们构建模块化的应用系统

#### Bundle
    
- bundle其表现就是一个jar包，如eclipse的一个插件
- OSGI 类加载器并不遵循 Java 的双亲委派模型，OSGi 为每个 bundle 提供一个类加载器，该加载器能够加载 bundle 内部的类和资源，bundle 之间的交互是从一个 bundle 类加载器委托到另一个 bundle 类加载器，所有 bundle 都有一个父类加载器 [^1]
    - Fragment bundle 是一种特殊的 bundle，不是独立的 bundle，必须依附于其他 bundle 来使用
    - 由于基于不同的类加载器，如果其中一个模块无法正常运行，不会影响其他模块运行
- bundle生命周期 [^4]

    ![osgi-bundle](/data/images/java/osgi-bundle.png)
- bundle解析优先级
    - 已解析的(resolved) > 未解析的(installed)
    - 相同优先级，有多个匹配时，版本高者优先，版本相同则选最先安装的
- OSGi类查找顺序
    - 如果类所在包以`java.`开头，则委托给父类加载
    - 如果类所在包在导入包中，则委托给导出该包的Bundle
    - 最后在Bundle自身的类路径上查找

#### 处理模块耦合(依赖)

- osgi通过import/export package的机制来控制bundle间有限地藕合
    - 其他bundle包只能使用明确导出的软件包，**模块化的这一层确保在bundle包之间仅共享API类，并且严格隐藏实现类**，不能使用 `new ServiceImpl()` 等类似基于实现的代码
    - Export/Import package是通过bundle里的`META-INF/MANIFEST.MF`文件里指定的。如可使用`Maven-jar-plugin`等插件实现MANIFEST.MF文件的构建
- 还可以通过osgi service的方式实现藕合 [^4]
    - osgi service是osgi规范中定义的一种本地服务的机制，“本地”意味着它只是在osgi framework内有效，不可跨osgi framework调用，更不可跨JVM调用
    - osgi framework有一个service registry,bundle可以把一个实现某种接口的bean实例作为osgi service注册（register）到service registry上，其它bundle就可以从service registry上发现并引用它，所以，本质上osgi service就是一个bean。
    - 实用案例：我们会把接口定义在一个bundle A里，接口的实现则在另一个bundle B里，并将接口实现实例化后注册成osgi service，而第三个bundle C则引用这个osgi service。因为bundle B和C都需要用到bundle A的接口定义，所以bundle A需export接口定义所在的package，而bundle B和C则需import这个package。这样bundle B和C之间就不需用export/import package来藕合了，实现B和C之间的解藕

#### MANIFEST.MF文件(Import/Export package使用)

- MANIFEST.MF 文件(一般通过Maven自动生成)

```bash
# bundle命名空间、名称、版本
Bundle-SymbolicName: cn.aezo.osgi-intro-sample-client
Bundle-Name: osgi-intro-sample-client
Bundle-Version: 1.0.0.SNAPSHOT
# 激活bundle入口类
Bundle-Activator: com.baeldung.osgi.sample.client.Client
# 显示指定Bundle内部类路径, 默认为`.`
Bundle-ClassPath: .,other-classes/,embeded.jar

# 导出. 从而这个package里的类就可以被其它bundle引用了
Export-Package：cn.aezo.osgi.demo1
# 导出指定版本
Export-Package：cn.aezo.osgi.demo1;version="1.0"

# 导入. 从其它bundle导入包之后才能在当前包引用，否则就会出现“ClassNotFound"这样的异常
Import-Package：cn.aezo.osgi.demo1
# 指定导入版本或版本区间. 可实现导入不同版本Jar下的同一个类
Import-Package：cn.aezo.osgi.demo1;version="1.0"
Import-Package：cn.aezo.osgi.demo1;vendor="Sun";version="[1.0,2.0)"

# 使用uses子句解决类空间不一致。https://course.tianmaying.com/osgi-toturial+osgi-module-layer#22
# 场景：导出包中的类，其方法签名中包含了其Import-Package中的类；导出包中的类，继承了其Import-Package中的类
# uses约束是可以传递的，工具可自动生成uses
Export-Package：org.osgi.service.http;uses:="javax.servlet";version="1.0.0"
# 多个包名之间用逗号隔开","同时，包名可以用";"隔开并加上限定的Attribute
Import-Package：javax.servlet;version="2.3.0"

# 一行不能超过72个字符，超过部分需要换行，并以一个空格开头
Import-Package: com.baeldung.osgi.sample.service.definition;version="[1.
 0,2)",org.osgi.framework;version="[1.8,2)"

# Dynamic imports和Import-Package的区别是，Import-Package是在Bundle解析时检查的，如果找不到会解析失败。Dynamic imports是在Bundle启动后，代码运行期间，执行到需要加载类的代码时才去检查，如果找不到是一个运行时异常或者错误。可结合`Class.forName("com.mysql.jdbc.Driver").getInstance();`使用
# DynamicImport-Package
```

[osgi-uses](/data/images/java/osgi-uses.png)

#### osgi服务

- `BundleActivator` 定义组件被启动或停止时的动作
    - start
    - stop
- `ServiceListener` 监听服务状态
    - serviceChanged(ServiceEvent), ServiceEvent包含有REGISTERED(注册)、MODIFIED、UNREGISTERING(注销)、MODIFIED_ENDMATCH
- `ServiceTracker` 类

##### osgi service registry

- 发布服务 [^4]

```java
public class ActivatorA implements BundleActivator {

    @Override
    public void start(BundleContext context) throws Exception {
        // 定义一个Hashtable（Dictionary的子类） props，这个称为“服务属性”，服务属性是一组键值对，每个服务都可以根据需要设置0到n个服务属性
        Dictionary<String, String> props = new Hashtable<String, String>();
        props.put("ServiceName", "MyService");
        // 用接口名、实现的实例（instance）和服务属性作为参数，通过BundleContext的registerService的方法将这个实现 注册到OSGI service registry上
        // 之后将项目编译打包成bundle后部署到Karaf，使用如`ls 212`查看，会发现此bundle提供了一个osgi服务（服务接口为cn.aezo.osgi.MyService），服务ID为361，而且还列出了服务属性：ServiceName = MyService
        context.registerService(MyService.class.getName(), new Calculation(), props);
        System.out.println("Service registered!");
    }
}
```
- 引用服务

```java
public class ActivatorB implements BundleActivator {

    @Override
    public void start(BundleContext context) throws Exception {
        // 获得实现服务接口MyService的服务引用，可能有多个
        // 参数1：是服务的接口名
        // 参数2：是一个表达式，它是和服务属性相关的，用于过滤服务。参数2可以如以下的形式："(ServiceName=MyService)"、"&((ServiceName=MyService)(ServiceType=Math))"(符合两个条件)
        ServiceReference[] refs = context.getServiceReferences(MyService.class.getName(), "(ServiceName=MyService)");
        if(refs != null && refs.length > 0) {
            MyService service = (MyService) context.getService(refs[0]);
        }
    }
}
```

##### osgi服务动态性

#### Blueprint

- Blueprint [^4]
    - 为了适应OSGI的动态环境，spring发展出spring dynamic modules（SpringDM），Blueprint的规范则是来源于SpringDM的进一步发展
    - 目前，Blueprint规范主要有两个实现：Aries blueprint和Gemini blueprint，它们分别来自Apache和Eclipse两个开源组织
    - Blueprint可以象Spring那样，通过XML的方式构建应用，当然也可以通过Blueprint annotation的方式实现同样的目的。由于XML可以和bundle分离，单独部署到servicemix上，所以比annotation的方式更具灵活性，所以我们推荐使用XML的方式
    - 除了Blueprint之外，OSGI还可以支持Delerative Service（DS）、iPojo等方式，达到类似的功能。但是由于blueprint还可以集成很多功能，例如：Camel。所以推荐使用Blueprint
- blueprint是在bundle启动之后（即bundle状态成为ACTIVE）才开始被解析、构建应用，所以，要成功构建bundle的blueprint应用，必须先确保bundle本身能正常启动
- blueprint容器的状态
    - `GracePeriod` blueprint正在等待所需的依赖条件
    - `Creating` blueprint已满足了依赖条件，并开始构建blueprint应用
    - `Failure` blueprint没法满足所需的依赖条件，或者无法根据xml文档构建相应的应用（可能是xml在语法上有错误）
    - `Created` blueprint应用已成功构建
- 在bundle里，blueprint的xml文档是默认放在jar包里的`OSGI-INF/blueprint`文件夹里，如果你将它放在其它位置，则需要在manifest.mf里添加一个Bundle-Blueprint的项，例如：`Bundle-Blueprint：OSGI-INF/myapplication/*.xml`
- 案例
    - 服务端新建`resources/OSGI-INF/blueprint/my-service-bp.xml`，这个文档就起和spring的ApplicationContext.xml类似的作用

        ```xml
        <?xml version="1.0" encoding="UTF-8"?>
        <blueprint xmlns="http://www.osgi.org/xmlns/blueprint/v1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://www.osgi.org/xmlns/blueprint/v1.0.0 http://www.osgi.org/xmlns/blueprint/v1.0.0/blueprint.xsd">
            <!-- 实例化MyService -->
            <bean id="MyServiceImpl" class="cn.aezo.osgi.impl.MyServiceImpl"/>
            <!-- 发布成OSGI服务。因此就不用在Activator中发布服务了 -->
            <service id="MyService" ref="MyServiceImpl" interface="cn.aezo.osgi.MyService">
                <service-properties>
                    <entry key="ServiceName" value="MyService"/>
                </service-properties>
            </service>
        </blueprint>
        ```
    - 客户端新建`resources/OSGI-INF/blueprint/my-client-bp.xml`

        ```xml
        <?xml version="1.0" encoding="UTF-8"?>
        <blueprint xmlns="http://www.osgi.org/xmlns/blueprint/v1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://www.osgi.org/xmlns/blueprint/v1.0.0 http://www.osgi.org/xmlns/blueprint/v1.0.0/blueprint.xsd">
            <!--引用服务-->
            <reference id="MyService" interface="cn.aezo.osgi.MyService" filter="(ServiceName=MyService)"/>
            <!-- 实例化 -->
            <bean id="MyBean" class="cn.aezo.osgi.impl.DIWithBlueprint">
                <!--注入服务引用-->
                <property name="myService" ref="MyService"/>
            </bean>
        </blueprint>
        ```
    - 客户端`DIWithBlueprint.java`接受注入

        ```java
        public class DIWithBlueprint {
            private MyService myService;

            public void setMyService(MyService myService) {
                this.myService = myService;
            }
        }
        ```

#### 动态配置

- OSGI里面用于操作配置文件(cfg)的接口有2个
    - `org.osgi.service.cm.ManagedService` 用于操作单个配置文件
    - `org.osgi.service.cm.ManagedServiceFactory` 用于操作一组相关的配置文件

        ```java
        // ManagedServiceFactory 参考 https://blog.csdn.net/mn960mn/article/details/50450494
        public class ConfigManagedExample implements ManagedService {
            // Dictionary 是一个Java抽象类，用来存储键/值对，作用和Map类相似
            public void updated(Dictionary<String, ?> properties) throws ConfigurationException {
                System.out.println("--------properties被修改，会触发此方法---------");
            }
        }
        ```
- 基于Blueprint实现动态配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- 新增命名空间cm -->
<blueprint xmlns="http://www.osgi.org/xmlns/blueprint/v1.0.0"
           xmlns:cm="http://aries.apache.org/blueprint/xmlns/blueprint-cm/v1.1.0"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:schemaLocation="http://www.osgi.org/xmlns/blueprint/v1.0.0 http://www.osgi.org/xmlns/blueprint/v1.0.0/blueprint.xsd
http://aries.apache.org/blueprint/xmlns/blueprint-cm/v1.1.0 http://aries.apache.org/schemas/blueprint-cm/blueprint-cm-1.1.0.xsd">

    <!-- persistent-id指定了ConfigAdmin对应的service.pid -->
    <!-- 可以尝试将配置文件 cn.aezo.osgi.cm.cfg 编辑好，放到karaf/etc文件夹下，可以看到配置值被重新注入 -->
    <cm:property-placeholder persistent-id="cn.aezo.osgi.cm" update-strategy="reload">
        <cm:default-properties>
            <cm:property name="package" value="cn.aezo.osgi.cm"/>
            <cm:property name="version" value="1.0"/>
            <cm:property name="author" value="smalle"/>
        </cm:default-properties>
    </cm:property-placeholder>

    <bean id="somebean" class="cn.aezo.osgi.cm.SomeBean">
        <property name="packageVal" value="${package}"/>
        <property name="versionVal" value="${version}"/>
        <property name="author" value="${author}"/>
    </bean>
</blueprint>
```

## OSGi示例

- 参考：https://www.baeldung.com/osgi
- 示例源码：https://github.com/oldinaction/smjava/tree/master/osgi
- 常见的OSGi容器Apache Felix和Eclipse's Equinox。而Eclipse's Equinox很久没有更新，因此基于Felix容器测试
- 下载Felix容器，或者直接下载Apache Karaf容器(推荐，Karaf是基于Felix的OSGi管理平台，包含命令界面)

```bash
# https://karaf.apache.org/get-started.html
# 启动Karaf可测试是否可正常运行. 会进入`karaf@root()>`命令界面
bin/karaf.bat start

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
                    <!-- 此Bundle的命名空间 cn.aezo.osgi -->
                    <Bundle-SymbolicName>${project.groupId}.${project.artifactId}</Bundle-SymbolicName>
                    <!-- 此Bundle名称 osgi-intro-sample-service -->
                    <Bundle-Name>${project.artifactId}</Bundle-Name>
                    <!-- 此Bundle版本 1.0-SNAPSHOT -->
                    <Bundle-Version>${project.version}</Bundle-Version>

                    <!-- 激活模块入口 -->
                    <Bundle-Activator>com.baeldung.osgi.sample.service.implementation.GreeterImpl</Bundle-Activator>
                    <Private-Package>com.baeldung.osgi.sample.service.implementation</Private-Package>
                    <!-- 服务导出的包，client只需要应用服务的pom即可使用服务；client无需导出包则不需要此配置 -->
                    <Export-Package>com.baeldung.osgi.sample.service.definition</Export-Package>

                    <!-- 导入包 -->
                    <Import-Package>
                        cn.aezo.core.*,
                        cn.aezo.test.service,
                    </Import-Package>
                    <!-- 动态导入包 -->
                    <DynamicImport-Package>
                        javax.*,
                        org.osgi.*,
                        org.xml.*,
                        org.w3c.*
                    </DynamicImport-Package>
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

## idea使用

- 配置. 参考：https://www.jb51.net/article/160461.htm
    - 下载Felix
    - File - Settings - Languages & Frameworks - OSGi Framework Instances - 导入Felix
    - File - Settings - Languages & Frameworks - OSGi
    - 启动配置：Edit configuration - 新建一个OSGi启动配置

## karaf容器

### karaf命令

```bash
ls      # 列举bundle
    # ls 100 # 列举某个bundle
start   # 启动bundle(调用bundle的BundleActivator.start方法)
```






---

参考文章

[^1]: https://developer.ibm.com/zh/languages/java/articles/j-springboot-application-integrated-osgi-framework-development/
[^2]: http://paulonjava.blogspot.com/2014/04/micro-services-vs-osgi-services.html
[^3]: https://blog.csdn.net/wdvceafvcsrgfv/article/details/78868508
[^4]: https://course.tianmaying.com/osgi (理解OSGi)

