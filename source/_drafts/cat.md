---
layout: "post"
title: "cat"
date: "2019-06-28 12:58"
categories: devops
tags: [arch, monitor]
---

## 简介

- [github](https://github.com/dianping/cat)、[深入详解美团点评CAT跨语言服务监控](https://blog.csdn.net/caohao0591/article/details/80693289)
- CAT服务端不可用时，不会影响客户端执行；待服务端重启成功后客户端会将不可用期间的日志重新发给服务端
- 客户端将监控日志上传到服务端，服务端先存储在内存中，定期会将上一个小时的数据落到数据库中(hourlyreport、hourly_report_content)，天/周/月数据则在凌晨进行计算落库
- 报表类型
    - Transaction报表：**一段代码运行时间**、次数、失败率、QPS，比如URL、Cache、SQL执行次数和响应时间
    - Event报表：**一行代码运行次数**、失败次数，如Exception出现次数。Event报表的整体结构与Transaction报表几乎一样，只缺少响应时间的统计
    - Problem报表：**根据Transaction/Event数据分析**出来系统可能出现的异常，包括访问较慢的程序等
    - Heartbeat报表：JVM内部一些状态信息，比如Memory，Thread等
    - Business报表：使用Metric实现业务监控报表，比如订单指标，支付等业务指标。与Transaction、Event、Problem不同，Business更偏向于宏观上的指标，另外三者偏向于微观代码的执行情况
    - Cross报表：分布式调用统计
- Transaction、Event、Problem都可分成两类：一级分类(Type)、二级分类(Name)
    - Type常见如：URL、SQL、Call、Method、Cache、Task、PigeonCall、PigeonService
- 整体设计

    ![CAT整体设计](/data/images/arch/cat-overall.png)

    - 在实际开发和部署中，cat-consumer和cat-home是部署在一个jvm内部

## 安装

### 基于docker安装服务端

- 参考：https://github.com/dianping/cat/wiki/readme_server
- docker-compose.yml，并启动(docker所在宿主机内网ip为192.168.6.10；数据库sq-mysql和自定义网络sq-net创建此处省略)

```yml
version: '3'
services:
  sq-tomcat:
    container_name: sq-tomcat
    image: tomcat:jdk8
    ports:
      - 8888:8080
      - 2280:2280
    volumes:
      - /home/data/cat/appdatas:/data/appdatas
      - /home/data/cat/applogs:/data/applogs
    environment:
      TZ: Asia/Shanghai
      # CAT服务器本身包含一个名为cat的客户端
      CAT_HOME: /data/appdatas/cat
      # 注意 -Dhost.ip 视情况填写
      CATALINA_OPTS: -server -DCAT_HOME=$$CAT_HOME -Djava.awt.headless=true -Xms512M -Xmx1G -XX:PermSize=256m -XX:MaxPermSize=256m -XX:NewSize=512m -XX:MaxNewSize=512m -XX:SurvivorRatio=10 -XX:+UseParNewGC -XX:ParallelGCThreads=4 -XX:MaxTenuringThreshold=13 -XX:+UseConcMarkSweepGC -XX:+DisableExplicitGC -XX:+UseCMSInitiatingOccupancyOnly -XX:+ScavengeBeforeFullGC -XX:+UseCMSCompactAtFullCollection -XX:+CMSParallelRemarkEnabled -XX:CMSFullGCsBeforeCompaction=9 -XX:CMSInitiatingOccupancyFraction=60 -XX:+CMSClassUnloadingEnabled -XX:SoftRefLRUPolicyMSPerMB=0 -XX:-ReduceInitialCardMarks -XX:+CMSPermGenSweepingEnabled -XX:CMSInitiatingPermOccupancyFraction=70 -XX:+ExplicitGCInvokesConcurrent -Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.EPollSelectorProvider -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.util.logging.config.file="$$CATALINA_HOME\conf\logging.properties" -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCApplicationConcurrentTime -XX:+PrintHeapAtGC -Xloggc:/data/applogs/heap_trace.txt -XX:-HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/applogs/HeapDumpOnOutOfMemoryError -Djava.util.Arrays.useLegacyMergeSort=true -Dhost.ip=192.168.6.10
    # docker-compose restart也会运行此命令，从而导致失败
    #command: /bin/sh -c "sed -i 's/<Connector/<Connector URIEncoding=\"UTF-8\"/' $$CATALINA_HOME/conf/server.xml && catalina.sh run"
networks:
  default:
    external:
      name: sq-net
```
- 将`/home/data/cat`设置为可读写`chmod 777 /home/data/cat`
- 创建`/home/data/cat/appdatas/cat/datasources.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-sources>
	<data-source id="cat">
		<maximum-pool-size>3</maximum-pool-size>
		<connection-timeout>1s</connection-timeout>
		<idle-timeout>10m</idle-timeout>
		<statement-cache-size>1000</statement-cache-size>
		<properties>
			<driver>com.mysql.jdbc.Driver</driver>
			<url><![CDATA[jdbc:mysql://sq-mysql:3306/cat]]></url>
			<user>smalle</user>
			<password>smalle</password>
			<connectionProperties><![CDATA[useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&socketTimeout=120000]]></connectionProperties>
		</properties>
	</data-source>
</data-sources>
```
- 将cat源码的`script/CatApplication.sql`文件导入到mysql的cat数据库中
- 下载[cat-home.war](http://unidal.org/nexus/service/local/repositories/releases/content/com/dianping/cat/cat-home/3.0.0/cat-home-3.0.0.war)，重命名为`cat.war`
- 部署war包`docker cp cat.war sq-tomcat:/usr/local/tomcat/webapps` (每次重新创建了tomcat容器都必须重新部署)
- 访问`http://192.168.6.10:8888/cat`
- 配置
    - 访问`http://192.168.6.10:8888/cat/s/config?op=serverConfigUpdate`进行服务端配置：修改ip为192.168.6.10(视情况修改)，启动hdfs的ip可以不用考虑(默认关闭hdfs)
    - 访问`http://192.168.6.10:8888/cat/s/config?op=routerConfigUpdate`进行客户端路由配置：修改ip为192.168.6.10

### 客户端(Windows下IDEA启动)

- 参考：https://github.com/dianping/cat/blob/master/lib/java/README.zh-CN.md
- 创建文件`D:\data\appdatas\cat\client.xml`(windows环境时，此处D盘和tomcat运行盘符一致，或者设置CAT_HOME；linux系统则为/目录；生成的运行日志文件位于`D:\data\applogs\cat`)
    
```xml
<?xml version="1.0" encoding="utf-8"?>
<config mode="client" xmlns:xsi="http://www.w3.org/2001/XMLSchema" xsi:noNamespaceSchemaLocation="config.xsd">
    <servers>
        <server ip="192.168.6.10" port="2280" http-port="8888" />
    </servers>
</config>
```
- maven

```xml
<dependency>
    <groupId>com.dianping.cat</groupId>
    <artifactId>cat-core</artifactId>
    <version>3.0.0</version>
</dependency>
<dependency>
    <groupId>com.dianping.cat</groupId>
    <artifactId>cat-client</artifactId>
    <version>3.0.0</version>
</dependency>
```
- 创建`src/main/resources/META-INF/app.properties`，并写入`app.name=sq-test`
- 在测试项目中写入埋点代码，即可进行测试

```java
public void test() {
    //  创建一个Transaction，用于Transaction报表
    Transaction t = Cat.newTransaction("URL", "pageName");

    try {
        // 记录一个事件。如果只是统计Event报表，可以不用开启Transaction
        Cat.logEvent("URL.Server", "serverIp", Event.SUCCESS, "ip=${serverIp}");
        // 记录一个业务指标，主要衡量单位时间内的次数总和。用于Business报表(可不用开启Transaction)
        Cat.logMetricForCount("OrderCount");
        // 记录一个time类的业务指标，主要衡量单数时间内的平均值。用于Business报表
        Cat.logMetricForDuration("my.metric.key", 5);

        // 业务代码
        yourBusiness();

        // 设置附加内容
        t.addData("my content");
        // 设置Transaction成功状态，否则Transaction报表中都显示成错误
        t.setStatus(Transaction.SUCCESS);
    } catch (Throwable e) {
        // 设置Transaction错误状态。只要没有设置Transaction.SUCCESS都认为是失败，默认的失败原因为unset，此处Throwable对应的名称
        t.setStatus(e);

        // 记录错误事件。也可集成logback插件(cat)，达到使用logger记录的日志也可以上报给CAT
        Cat.logError(e); // Cat.logError("my msg", e);
        // 如果 e 是一个 Error，type 会被设置为 Error；如果 e 是一个 RuntimeException，type 会被设置为 RuntimeException；其他情况下 type 会被设置为 Exception
        // 对应的 name 默认为 Throwable e 的类名，此API可进行覆盖
        // Cat.logErrorWithCategory("custom-category", e);
    } finally {
        // 结束Transaction
        t.complete();
    }
}
```

### 客户端插件集成

- 参考：https://github.com/dianping/cat/tree/master/integration
- 对所有的URL路径进行拦截。此时后端API暴露的路径都会进行上报统计，也可额外添加对某个路径的自定义拦截

```java
@Bean
public FilterRegistrationBean catFilter() {
    FilterRegistrationBean registration = new FilterRegistrationBean();
    CatFilter filter = new CatFilter();
    registration.setFilter(filter);
    registration.addUrlPatterns("/*");
    registration.setName("cat-filter");
    registration.setOrder(1);
    return registration;
}
```
- 对SQL进行拦截。此时可以对有的SQL语句进行上报统计
    - [mybatis](https://github.com/dianping/cat/tree/master/integration/mybatis)。会自动生成`URL`类型的Transaction、Event日志
    - 从上述链接复制mybatis插件源码`CatMybatisPlugin.java`
        - 修改源码中`switchDataSource`方法，可去掉`DruidDataSource`判断，并加入HikariDataSource判断：`if(dataSource instanceof HikariDataSource) { url = ((HikariDataSource) dataSource).getJdbcUrl(); }`
    - 加入插件`<plugin interceptor="cn.aezo.test.plugin.CatMybatisPlugin"/>`
- 与日志框架整合记录Event。此时可以对`logger.error`/`logger.trace`类型的日志进行上报统计，可以代替`Cat.logError(e);`以减少代码量
    - [logback](https://github.com/dianping/cat/tree/master/integration/logback)
    - 从上述链接复制logback插件源码`CatLogbackAppender.java`
    - 在logback.xml文件中加入对应的Appender和appender-ref
    - 注意：logback记录日志的时候需要传入异常对象，如果不传无法在cat中的problem展示错误信息。如：`logger.error(e.getMessage(), e);`(生成的type如下，name则无法自定义，为e对应的类名)

### 分布式调用链监控

https://www.cnblogs.com/xing901022/p/6237874.html
基于header传递

### 异步/主子线程监控问题

feign+hystrix，在FeignRequestInterceptor中时，已经是在子线程中了，和主线程已经不是同一个messageTree
- `feign.hystrix.enabled: false` 关闭hystrix

### 常见问题

- 基于docker安装，界面显示`出问题CAT的服务端:[192.168.6.10]`，这个显示不影响数据上报和监控，仅仅是IP配置不规范。主要是CAT默认使用获取的内网IP，则此时为docker容器IP，此时可设置`host.ip`
    - 解决办法：在启动参数中加`-Dhost.ip=192.168.6.10`

## 使用

- 项目配置信息
    - 新增：CAT上项目名称-事业部-产品线，如果客户端只是在`app.properties`中配置`app.name`则会归并到`Default-Default`的事业部和产品线



