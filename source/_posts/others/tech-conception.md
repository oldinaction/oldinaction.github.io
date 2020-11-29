---
layout: "post"
title: "技术概念(名词)汇总"
date: "2016-09-01 09:19"
categories: others
tags: [java, conception]
---

## 架构

- `SOA`
    - 面向服务的架构，主要流行于零几年，基于XML的Webservice进行不同服务间调用
    - 主要针对业务层面进行服务拆分。而微服务则是粒度更细的服务拆分，更倾向于功能级别
- `SOAP` 简单对象访问协议(Simple Object Access Protocol)。webService三要素：SOAP、WSDL、UDDI
    - SOAP封装
    - SOAP编码规则：定义了一种序列化的机制
    - SOAP RPC：定义了用于表示远程过程调用和应答的协定
    - SOAP绑定
- `RPC` 远程过程调用(Remote Procedure Call)
    - 相关框架
        - 应用级的服务框架：阿里的 Dubbo/Dubbox、Google gRPC、Facebook 的 Thrift、Twitter 的 Finagle
        - 远程通信协议：RMI、Socket、SOAP(HTTP XML)
-  `gRPC` 是一个高性能、开源和通用的 RPC 框架，目前提供 C、Java 和 Go 语言版本
- `CAP`理论 [^2]
    - 一个分布式系统最多只能同时满足一致性（Consistency）、可用性（Availability）和分区容错性（Partition tolerance）这三项中的两项
    - 一致性：所有节点在同一时间的数据完全一致；可用性：服务一直可用，而且是正常响应时间；分区容错性：即分布式系统在遇到某节点或网络分区故障的时候，仍然能够对外提供满足一致性和可用性的服务
- `BASE`理论
    - BASE理论是对CAP理论的延伸，核心思想是即使无法做到强一致性（Strong Consistency，CAP的一致性就是强一致性），但应用可以采用适合的方式达到最终一致性（Eventual Consitency）
    - BASE是指基本可用（Basically Available）、软状态（Soft State）、最终一致性（Eventual Consistency）
    - 基本可用：是指分布式系统在出现故障的时候，允许损失部分可用性，即保证核心可用。电商大促时，为了应对访问量激增，部分用户可能会被引导到降级页面，服务层也可能只提供降级服务。这就是损失部分可用性的体现
    - 软状态：是指允许系统存在中间状态，而该中间状态不会影响系统整体可用性。分布式存储中一般一份数据至少会有三个副本，允许不同节点间副本同步的延时就是软状态的体现。mysql replication的异步复制也是一种体现
    - 最终一致性：是指系统中的所有数据副本经过一定时间后，最终能够达到一致的状态。弱一致性和强一致性相反，最终一致性是弱一致性的一种特殊情况
    - ACID(刚性事务)是传统数据库常用的设计理念，追求强一致性模型。BASE(柔性事务)支持的是大型分布式系统，提出通过牺牲强一致性获得高可用性
- [^3]
- `垂直扩展`和`水平扩展`
    - 垂直扩展就是升级原有的服务器或更换为更强大的硬件。这是比较直接的方法，比如说内存不足时就增加更多的内容。或者，花费一大笔钱为一个大型主机服务器增加存储吞吐量和/或计算能力。 
    - 水平(Horizontal)扩展指的是通过增加更多的服务器来分散负载，从而实现存储能力和计算能力的扩展。这可以通过增加本地的刀片服务器（虽然有些人认为增加刀片服务器是一种垂直扩展形式），或者增加云端的虚拟机和服务器
- `QPS` 每秒查询率。QPS是对一个特定的查询服务器在规定时间内所处理流量多少的衡量标准
    - QPS = 并发量 / 平均响应时间
    - 并发量 = QPS * 平均响应时间
    - 如优化程序10QPS -> 200QPS
- `TPS` 每秒处理事务数
- `FastCGI` 快速通用网关接口，是一种让交互程序与Web服务器通信的协议，相比早起CGI更快
    - 主要优点是把动态语言和 HTTP 服务器分离开来。多数流行的 HTTP 服务器都支持 FastCGI，包括 Apache 、 Nginx 和 Lighttpd 等
    - 同时，FastCGI也被许多脚本语言所支持，例如当前比较流行的脚本语言PHP
    - FastCGI 接口采用的是C/S架构，它可以将 HTTP 服务器和脚本服务器分开，同时还能在脚本解析服务器上启动一个或多个脚本来解析守护进程。当 HTTP 服务器遇到动态程序时，可以将其直接交付给 FastCGI 进程来执行，然后将得到结果返回给浏览器

## 网络

- `OSI`(Open System Interconnection)开放式系统互联。国际标准化组织（ISO）制定了OSI模型，该模型定义了不同计算机互联的标准，是设计和描述计算机网络通信的基本框架。OSI模型把网络通信的工作分为7层，分别是物理层、数据链路层、网络层、传输层、会话层、表示层和应用层。
- `RPC`(Remote Procedure Call Protocol)远程过程调用协议。它是一种通过网络从远程计算机程序上请求服务，而不需要了解底层网络技术的协议。RPC协议假定某些传输协议的存在，如TCP或UDP，为通信程序之间携带信息数据。在OSI网络通信模型中，RPC跨越了传输层和应用层。RPC使得开发包括网络分布式多程序在内的应用程序更加容易。
- `同步`、`异步`、`阻塞`、`非阻塞`
    - 在进行网络编程时，我们常常见到同步、异步、阻塞和非阻塞四种调用方式。
    - 同步(sync)就是在发出一个功能调用时，在没有得到结果之前，该调用就不返回。
    - 异步(async)的概念和同步相对。当一个异步过程调用发出后，调用者不能立刻得到结果。
    - 阻塞调用是指调用结果返回之前，当前线程会被挂起，函数只有在得到结果之后才会返回。对于同步调用来说，很多时候当前线程还是激活的，只是从逻辑上当前函数没有返回而已。
    - 非阻塞和阻塞的概念相对应，指在不能立刻得到结果之前，该函数不会阻塞当前线程，而会立刻返回。简单的说：阻塞就是干不完不准回来，非阻塞就是你先干，我看看有其他事没有，完了告诉我一声
- `LDAP`、`JNDI`
    - `LDAP`(Light Directory Access Portocol)：它是基于X.500标准的轻量级目录访问协议。它成树状结构组织数据，类似文件目录一样。目录数据库和关系数据库不同，它有优异的读性能，但写性能差，并且没有事务处理、回滚等复杂功能。OpenLDAP为Opensource的开源项目，基于LDAP协议来存储数据（数据库）
    - `JNDI`(Java Naming and Directory Interface)：Java命名和目录接口。是为了Java程序访问命名服务和目录服务而提供的统一API。
        - 命名服务，说白了就是提供一个名称键值对的管理，即Key-Value对，Key代表一个资源的名称，Value代表资源的真实地址，命名服务允许大家通过唯一的名称找到对应的对象或资源。这样程序只需要知道某种资源的名称，就可以通过JNDI来访问到它，而不需要知道这个资源真实的物理地址。这有点类似于DNS服务，DNS服务将域名解析成IP地址，这样大家只需要在浏览器中输入网站的唯一名称（即域名）就可以访问到该网站，而不需要记住这个网站真实的IP地址。
    - JNDI则是Java中用于访问LDAP的API，开发人员使用JNDI完成与LDAP服务器之间的通信，即用JNDI来访问LDAP，而不需要和具体的目录服务产品特性打交道
- `Netty` 是由JBOSS提供的一个java开源框架。Netty提供异步的、事件驱动的网络应用程序框架和工具，用以快速开发高性能、高可靠性的网络服务器和客户端程序。Netty相当简化和流线化了网络应用的编程开发过程，例如，TCP和UDP的socket服务开发。
- `Mina` Apache Mina。是一个能够帮助用户开发高性能和高伸缩性网络应用程序的框架。它通过Java nio技术基于TCP/IP和UDP/IP协议提供了抽象的、事件驱动的、异步的API。
- `NIO`(non-blocking，New IO)。jdk1.4中引入的新输入输出 (NIO) 库在标准 Java 代码中提供了高速的、面向块的 I/O。Sun 官方标榜的特性如下： 为所有的原始类型提供(Buffer)缓存支持。字符集编码解码解决方案。Channel为一个新的原始I/O抽象。支持锁和内存映射文件的文件访问接口。 提供多路(non-bloking) 非阻塞式的高伸缩性网络I/O
    - IO：面向流、阻塞IO
    - NIO：面向缓冲、非阻塞IO、有选择器
- `TLS` 传输层安全性协议(Transport Layer Security)，及其前身`SSL`是一种安全协议，目的是为互联网通信提供安全及数据完整性保障。网景公司(Netscape)在1994年推出首版网页浏览器，网景导航者时，推出HTTPS协议，以SSL进行加密，这是SSL的起源
- `SSL` 安全套接层(Secure Sockets Layer)
- `HSTS`(HTTP Strict Transport Security)
    - 背景：由于用户习惯，通常准备访问某个网站时，在浏览器中只会输入一个域名，而不会在域名前面加上 http:// 或者 https://，而是由浏览器自动填充，当前所有浏览器默认填充的都是http://。一般情况网站管理员会采用了 301/302 跳转的方式由 HTTP 跳转到 HTTPS，但是这个过程总使用到 HTTP 因此容易发生劫持，受到第三方的攻击
    - 网站采用 HSTS 后，用户访问时无需手动在地址栏中输入 HTTPS，浏览器会自动采用 HTTPS 访问网站地址。当用户下次使用 HTTP 访问，客户端就会进行内部跳转，并且能够看到 307 Redirect Internel 的响应码
    - 使用HSTS：在HTTPS响应头添加`Strict-Transport-Security: max-age=expireTime [; includeSubDomains] [; preload]`
        - 如max-age=31536000则表示：在一年中浏览器必须采用HTTPS来发起连接(浏览器应当自动将 http 转写成 https)，如果该服务器发送的TLS证书无效，用户不能忽略浏览器警告继续访问网站。此时只能续期证书或更换域名
- 上行、下行带宽
    - `上行带宽`：指服务器将数据传送给用户的带宽，如20M
    - `下行带宽`：指用户从服务器下载的带宽，如100M
    - 上行带宽较下行要贵

## 数据库

- `OLTP/OLAP` 数据处理大致可以分成两大类：联机事务处理OLTP(On-Line Transaction Processing)、联机分析处理OLAP(（On-Line Analytical Processing)。OLTP是传统的关系型数据库的主要应用，主要是基本的、日常的事务处理，例如银行交易。OLAP是数据仓库系统的主要应用，支持复杂的分析操作，侧重决策支持，并且提供直观易懂的查询结果。
- `CAP`理论、`ACID`、`BASE`
    - `CAP`理论。Web服务无法同时满足以下3个属性
        - Consistency(一致性)，数据一致更新，所有数据变动都是同步的
        - Availability(可用性)，每个操作都必须以可预期的响应结束
        - Partition tolerance(分区容错性)，即使出现单个组件无法可用,操作依然可以完成。在任何数据库设计中,一个Web应用至多只能同时支持上面的两个属性，不可能三者兼顾。对于分布式系统来说，分区容错是基本要求，所以必然要放弃一致性。对于大型网站来说， 分区容错和可用性的要求更高，所以一般都会选择适当放弃一致性。对应CAP理论，NoSQL追求的是AP，而传统数据库追求的是CA，这也可以解释为什么 传统数据库的扩展能力有限的原因。
    - `ACID`解决方案。ACID数据库事务极大地简化了应用开发人员的工作.正如其缩写标识所示,ACID事务提供以下几种保证:
        - Atomicity（原子性），事务中的所有操作,要么全部成功,要么全部不做.
        - Consistency（一致性）在事务开始与结束时,数据库处于一致状态.
        - Isolation（隔离性） 事务如同只有这一个操作在被数据库所执行一样.
        - Durability（持久性）. 在事务结束时,此操作将不可逆转.(也就是只要事务提交,系统将保证数据不会丢失,即使出现系统Crash).
        - 数据库厂商在很久以前就认识到数据库分区的必要性,并引入了一种称为2PC(两阶段提交)的技术来提供跨越多个数据库实例的ACID保证
    - `BASE`解决方案
        - Basically Available（基本可用）
        - Soft-state（ 软状态/柔性事务）
        - Eventual Consistency（最终一致性）
        - BASE模型是传统ACID模型的反面，不同与ACID，BASE强调牺牲高一致性，从而获得可用性，数据允许在一段时间内的不一致，只要保证最终一致就可以了。
- `DBCP` 数据库连接池(DataBase Connection Pool)

## 产品/框架

- 服务器：`tomcat`、`jboss`、`weblogic`
- Web Service框架：`CXF`、`Axis2`、`Axis`
    - CXF对Spring的友好支持，对于那些使用了Spring的既有项目来说，CXF应该是首选，因为CXF是基于注解的
    - Axis2的优势是支持C平台和比较全的WS-*协议族
- 云计算
    - `GCP`(Google Cloud Platform)
    - `GKE`(Google Kubernetes Engine)、`AKS`(Azure Kubernetes Service)、`Amazon EKS`(Amazon Elastic Container Service for Kubernetes)

## 开发

- 命令常用符号 `命令 <必选参数1|必选参数2> [-option {必选参数1|必选参数2|必选参数3}] [可选参数...] {(默认参数)|参数|参数}`
    - 命令符号
        - 尖括号< >：必选参数
        - 方括号[ ]：可选参数
        - 大括号{ }：必选参数，内部使用，包含此处允许使用的参数
        - 小括号( )：指明参数的默认值，只用于{ }中
        - 竖线|："或"，使用时只能选择一个
        - 省略号...：任意多个参数
    - 一般小写字母为参数或命令，大写字母为动态变化的参数值
- `API`(Application Programming Interface)应用程序编程接口。是一些预先定义的函数，目的是提供应用程序与开发人员基于某软件或硬件得以访问一组例程的能力，而又无需访问源码，或理解内部工作机制的细节
- `PR`(Pull Request) 指GitHub中提交合并请求或同步原始仓库代码
- `CLI` 命令行界面(command-line interface)

## Web

- `CORS` 跨站资源共享(Cross Origin Resourse-Sharing)
- `XSS` 跨站脚本攻击(Cross Site Scripting)
- `CSRF` 跨站请求伪造(Cross-Site Request Forgery)
    - CSRF 主流防御方式是在后端生成表单的时候生成一串随机 token ，内置到表单里成为一个字段，同时，将此串 token 置入 session 中。每次表单提交到后端时都会检查这两个值是否一致，以此来判断此次表单提交是否是可信的。

## 后端

- PO、BO、VO、DTO、POJO。具体参考https://www.zhihu.com/question/39651928
    - `POJO` 为PO/DTO/VO/BO的统称，就是个简单的java对象
    - `PO` 持久对象，数据
    - `BO` 业务对象，封装对象、复杂对象 ，里面可能包含多个类
    - `DTO` 传输对象，前端调用时传输
    - `VO` 表现对象，前端界面展示
- `贫血模型`、`充血模型`
    - 贫血模型是指领域对象里只有get和set方法，所有的业务逻辑都不包含在内而是放在Business Logic层；充血模型则在领域对象中包含业务逻辑方法(行为)
    - 在使用Spring的时候，通常暗示着使用了贫血模型，把Domain类用来单纯地存储数据
- `EJB`(Enterprise JavaBean)是sun的JavaEE服务器端组件模型。设计目标与核心应用是部署分布式应用程序。简单来说就是把已经编写好的程序（即：类）打包放在服务器上执行。 在J2EE里，EJB 称为Java 企业Bean，是Java的核心代码，分别是会话Bean（Session Bean），实体Bean（Entity Bean）和消息驱动Bean（MessageDriven Bean）
    - SessionBean用于实现业务逻辑，它可以是有状态的，也可以是无状态的。每当客户端请求时，容器就会选择一个SessionBean来为客户端服务。Session Bean可以直接访问数据库，但更多时候，它会通过Entity Bean实现数据访问
    - Entity Bean是域模型对象，用于实现O/R映射，负责将数据库中的表记录映射为内存中的Entity对象，事实上，创建一个Entity Bean对象相当于新建一条记录。
    - MessageDriven Bean是EJB2.0中引入的新的企业Bean，它基于JMS消息，只能接收客户端发送的JMS消息然后处理。MDB实际上是一个异步的无状态SessionBean，客户端调用MDB后无需等待，立刻返回，MDB将异步处理客户请求。这适合于需要异步处理请求的场合，比如订单处理，这样就能避免客户端长时间的等待一个方法调用直到返回结果。
- `ORM`(Object Relational Mapping)对象关系映射。是一种程序技术，用于实现面向对象编程语言里不同类型系统的数据之间的转换
    - O/R映射层是持久层的一个特例，它的数据模型是对象模型（Object），存储模型是关系模型（Relational）
- `JMS`(Java Message Service) Java消息服务应用程序接口。是一个Java平台中关于面向消息中间件（MOM）的API，用于在两个应用程序之间，或分布式系统中发送消息，进行异步通信
- `JDBC`(Java Data Base Connectivity) java数据库连接。是一种用于执行SQL语句的Java API，可以为多种关系数据库提供统一访问，它由一组用Java语言编写的类和接口组成
- EL、OGNL、JSTL
    - `EL`(Expression Language)：是为了使JSP写起来更加简单，语法如${expression}
    - `OGNL`(Object-Graph Navigation Language)，主要有#%$三种符号，常与Struts2结合使用
    - `JSTL` JSP标准标签库。如：`<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>`，`<c:if>`
- `JSR` Java规范提案(Java Specification Requests)。是指向`JCP`(Java Community Process)提出新增一个标准化技术规范的正式请求。任何人都可以提交JSR，以向Java平台增添新的API和服务

## 运维

- `IDC` 互联网数据中心(Internet Data Center)

## 安全

- `DDoS` 全称是 Distributed Denial of Service，分布式拒绝服务。一般来说是指攻击者利用“肉鸡”对目标网站在较短的时间内发起大量请求，大规模消耗目标网站的主机资源，让它无法正常服务
    - 全球DDoS流量展示：https://cybermap.kaspersky.com/cn、https://threatmap.checkpoint.com/
- `CSRF` 跨站点请求伪造(Cross—Site Request Forgery)。攻击者盗用了你的身份，以你的名义发送恶意请求，对服务器来说这个请求是完全合法的。常见的如第三方Cookie传递导致信息泄露，因此像银行类网站使用完建议退出，这样可清除Cookie
- `XSS` 跨站脚本攻击是指恶意攻击者往Web页面里插入恶意Script代码，当用户浏览该页之时，嵌入其中Web里面的Script代码会被执行，从而达到恶意攻击用户的目的

## 项目管理

- `UAT` 用户验收测试(User Acceptance Test)
- `RFC` 意见征集/请求评论(Request For Comments)
- 版本命名规范
    - [语义化版本](https://semver.org/lang/zh-CN/)：`主版本号.次版本号.修订号-先行版本号+编译元数据`，如：`1.0.0-alpha+001`、`0.1.0`(内部开发版)
        - 版本号：做了不兼容的 API(公共API) 修改时递增
        - 次版本号：做了向下兼容的功能新增时递增
        - 修订号：做了向下兼容的问题修正时递增
    - 软件版本号由四部分组成，第一个为主版本号(模块/架构)，第二个为子版本号(功能)，第三个为阶段版本号(Bug/优化)，第四部分为日期版本号加希腊字母版本号，希腊字母版本号共有5种，分别为：`base`、`alpha`(内部开发)、`beta`(内测)、`RC`(预发布版)、`release`。例如：`1.1.1.051021_beta`
    - `LTS` 长期支持(Long Term Support)，一般为软件的重要版本
- 开源协议/许可证 [1^] [^4]

    ![开源协议](/data/images/others/许可证.png)
    - `MIT` **无需开源**，随便使用
    - `Apache` **无需开源**，仅需文件头放置Apache协议
    - `BSD` **无需开源**，需在文件头放置BSD协议，且不能使用原作者/产品信息做推广
    - `LGPL` 修改后必须开源
    - `Mozilla` 修改后必须开源，且需提供相关文档
    - `GPL` 修改后必须使用GPL协议开源
    - `AGPL` GPL的前提下，如果提供网络服务也必须开源
        - GPL的约束生效的前提是"发布"软件，发布至软件通过互联网或光盘release软件
        - 由于现在网络服务公司兴起（如：google）产生了一定的漏洞，比如使用GPL的自由软件，但是并不发布与网络之中。如使用GPL组件编写一个Web后端系统，不发布这个系统，但是用这个系统在线提供服务，同时不开源系统代码。AGPL则增加了对此做法的约束
- `Git`提交说明规范参考：http://www.ruanyifeng.com/blog/2016/01/commit_message_change_log.html


## 硬件

- `MBR`和`GPT`(`GUID`) 磁盘分区
    - `MBR`(Master Boot Record) 即硬盘主引导记录分区表，只支持容量在 2.1TB 以下的硬盘，超过2.1TB的硬盘只能管理2.1TB，最多只支持4个主分区或三个主分区和一个扩展分区，扩展分区下可以有多个逻辑分区。基于`Legacy`启动模式即可
    - `GPT` 全局唯一标识分区表(GUID Partition Table)，与MBR最大4个分区表项的限制相比，GPT对分区数量没有限制，但Windows最大仅支持128个GPT分区，GPT可管理硬盘大小达到了18EB。只有基于`UEFI`平台的主板才支持GPT分区引导启动
    - `sudo fdisk -l` linux 查看磁盘分区类型
- `UEFI`和`Legacy` 引导方式
    - UEFI是新式的BIOS，Legacy是传统BIOS。在UEFI模式下安装的系统，只能用UEFI模式引导；Legacy同理。
    - UEFI只支持64为系统且磁盘分区必须为GPT模式。传统BIOS使用Intel 13中断读取磁盘，每次只能读64KB，非常低效；而UEFI每次可以读1MB，载入更快
    - UEFI启动是一种新的主板引导项，它被看做是BIOS的继任者。UEFI最主要的特点是图形界面，更利于用户对象图形化的操作选择(BIOS是命令界面)

## 计算机界

- CPU架构
    - `x86` 泛指一系列由英特尔公司开发的处理器的架构，最早为1978年面世的"Intel 8086"CPU
        - 基于`x86`的32位架构常被称为`i386`、`x86`，而基于`x86`的64位架构常称为`AMD64`或`Intel64`
    - `ARM`(英文为Advanced RISC Machine，或Acorn RISC Machine)也是一个架构，非常适用于移动通信这种低成本，高性能，低耗电的领域
- `AMD` 中文名(超威)超微半导体，是除了`英特尔`以外最大的`x86`架构微处理供应商，也是除了`英伟达`以外仅有的独立图形处理供应商


---

参考文章

[^1]: http://www.ruanyifeng.com/blog/2011/05/how_to_choose_free_software_licenses.html
[^2]: https://my.oschina.net/foodon/blog/372703
[^3]: https://www.jianshu.com/p/d70df89665b9 (分布式事务：从刚性事务到柔性事务)
[^4]: https://blog.csdn.net/chengkaizone/article/details/51504239

