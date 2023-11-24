---
layout: "post"
title: "Java日志相关框架"
date: "2021-12-14 21:39"
categories: java
tags: [arch, log]
---

## 日志框架

- 日志框架一般分为编程API和日志打印实现。编程API为应用程序基于此API进行编程，如slf4j；打印实现为实现了上述API的模块进行日志打印到控制台或文件，如logback-classic
- slf4j、jcl、jul、log4j1、log4j2、logback大总结：https://my.oschina.net/pingpangkuangmo/blog/410224
- `logging`: jdk自带logging
- `log4j1`(包org.apache.log4j)
    - log4j: log4j1的全部内容(org.apache.log4j.*)。获取对象如 **`Logger.getLogger(Demo.class)`**
- `log4j2`(包org.apache.logging.log4j)
    - log4j-api: log4j2定义的API。获取对象如 **`LogManager.getLogger(Demo.class)`**
        - log4j-1.2-api: log4j到log4j2的桥接包。具体说明参考log4j
    - log4j-core: log4j2上述API的实现
    - log4j-nosql: 可选,将log4j2输出到mongodb等数据库
- `logback`
    - logback-core: logback的核心包
    - logback-classic: logback实现了slf4j的API
- `commons-logging` 为了实现日志统一
    - commons-logging: commons-logging的原生全部内容
    - log4j-jcl: commons-logging到log4j2的桥梁
    - jcl-over-slf4j: commons-logging到slf4j的桥梁
- `slf4j` 为了实现日志统一
    - slf4j-api: 为日志接口，简称slf4j。获取对象如 **`LoggerFactory.getLogger(Demo.class)`**
    - slf4j转向某个实际的日志框架：如使用slf4j的API进行编程，底层想使用log4j1来进行实际的日志输出，可使用slf4j-log4j12进行桥接
        - logback-classic: slf4j到logback的桥梁
        - log4j-slf4j-impl: slf4j到log4j2的桥梁
        - slf4j-jdk14: slf4j到jdk-logging的桥梁
        - slf4j-jcl: slf4j到commons-logging的桥梁
        - slf4j-log4j12: slf4j到log4j1的桥梁
    - 某个实际的日志框架转向slf4j(主要用来进行实际的日志框架之间的切换, slf4j为中间API)：如使用log4j1的API进行编程，但是想最终通过logback来进行输出，所以就需要先将log4j1的日志输出转交给slf4j来输出，slf4j再交给logback来输出。将log4j1的输出转给slf4j，这就是log4j-over-slf4j做的事
        - log4j-to-slf4j: log4j2到slf4j的桥梁。如springboot
            - springboot包含jar: log4j-api、log4j-to-slf4j、logback-classic、logback-core
            - 此时log4j-api和log4j-to-slf4j等同于slf4j的api
            - 相当于基于log4j2进行编程，最终输出由slf4j实现(即logback实现)
        - jul-to-slf4j: jdk-logging到slf4j的桥梁
        - jcl-over-slf4j: commons-logging到slf4j的桥梁
        - log4j-over-slf4j: log4j1到slf4j的桥梁

## jdk-logging

- 原理分析参考：https://blog.csdn.net/qingkangxu/article/details/7514770
- 案例(/smjava/logging/log4j1-jdklog)

```java
/**
* 打印日志如下，且IDEA显示为红色
* 十二月 10, 2021 9:13:04 下午 cn.aezo.logging.log4j1.App main
* 信息: jdk logging info...
* 十二月 10, 2021 9:13:04 下午 cn.aezo.logging.log4j1.App main
* 警告: jdk logging warning...
* 十二月 10, 2021 9:13:04 下午 cn.aezo.logging.log4j1.App main
* 严重: jdk logging severe...
*/
// java.util.logging.Logger
private static final Logger logger = Logger.getLogger(App.class.getName());
public static void main(String[] args) {
    logger.info("jdk logging info...");
    logger.warning("jdk logging warning...");
    logger.severe("jdk logging severe...");
}
```

## commons-logging

- [commons-logging](https://commons.apache.org/proper/commons-logging/): Jakarta Commons-logging（JCL）是apache最早提供的日志的门面接口。提供简单的日志实现以及日志解耦功能
- JCL能够选择使用Log4j（或其他如slf4j等）还是JDK Logging，但是他不依赖Log4j，JDK Logging的API。如果项目的classpath中包含了log4j的类库，就会使用log4j，否则就使用JDK Logging
- 配置文件`commons-logging.properties`，包`org.apache.commons.logging.*`
- 最后更新为2014年的v1.2
- 使用如

```xml
<dependency>
	<groupId>commons-logging</groupId>
	<artifactId>commons-logging</artifactId>
	<version>1.2</version>
</dependency>
<dependency>
	<groupId>log4j</groupId>
	<artifactId>log4j</artifactId>
	<version>1.2.17</version>
</dependency>
```

## log4j

- [log4j1.x](https://logging.apache.org/log4j/1.2/) 采用同步的方式打印log，当项目中打印log的地方很多的时候，频繁的加锁拆锁会导致性能的明显下降
    - 主要类
        - LogManager: 它的类加载会创建logger仓库Hierarchy，并尝试寻找类路径下的配置文件，如果有则解析
        - Hierarchy: 包含三个重要属性
            - LoggerFactory logger的创建工厂
            - Hashtable 用于存放上述工厂创建的logger
            - Logger root logger 用于承载解析文件的结果，设置级别，同时存放appender
        - PropertyConfigurator: 用于解析log4j.properties文件
        - Logger: 我们用来输出日志的对象
    - log4j.properties配置参考：https://blog.csdn.net/niuch1029291561/article/details/80938095
- [log4j2.x](https://logging.apache.org/log4j/2.x/) 则为异步打印
    - log4j2与log4j1发生了很大的变化，不兼容。log4j1仅仅作为一个实际的日志框架，slf4j、commons-logging作为门面，统一各种日志框架的混乱格局，现在log4j2也想跳出来充当门面了，也想统一大家了
    - log4j2包含
        - log4j-api: 作为日志接口层，用于统一底层日志系统
        - log4j-core: 作为上述日志接口的实现，是一个实际的日志框架
    - 主要类说明
        - LogManager: 它的类加载会去寻找LoggerContextFactory接口的底层实现，会从jar包中的配置文件中寻找
        - LoggerContextFactory: 用于创建LoggerContext，不同的日志实现系统会有不同的实现，如log4j-core中的实现为Log4jContextFactory
        - PropertyConfigurator: 用于解析log4j.properties文件
        - LoggerContext: 它包含了配置信息，并能创建log4j-api定义的Logger接口实例，并缓存这些实例
        - ConfigurationFactory: 上述LoggerContext解析配置文件，需要用到ConfigurationFactory，目前有三个- YamlConfigurationFactory、JsonConfigurationFactory、XmlConfigurationFactory，分别解析yuml json xml形式的配置文件
    - log4j2.xml配置参考：https://www.jianshu.com/p/bfc182ee33db
    - 调试log4j2，增加jvm参数`-Dlog4j2.debug=true`
- log4j1升级到log4j2
    - 删除原来log4j1依赖`log4j:log4j`
    - 增加新的log4j2依赖`org.apache.logging.log4j:log4j-api`和`org.apache.logging.log4j:log4j-core`
    - 增加`org.apache.logging.log4j:log4j-1.2-api`的桥接包，为官方推出的平稳的过度包。此时编程任然是基于log4j1进行编程
        - 桥接包的原理就是复写了log4j-1.2.17相关的类，再输出日志的时候调用的是log4j2中的方法
        - 如：log4j1中使用Logger.getLogger(Test.class)获取日志对象，log4j2的Logger没有此方法，所以升级的时候可能出现需要更改代码。如果引入此包，可以实现不更改代码升级
    - 配置文件还是必须为log4j2.xml，而不能是log4j.properties或log4j.xml
- log4j漏洞
    - 发生版本 log4j 2.x < 2.15.0-rc2
    - 详情：https://help.aliyun.com/noticelist/articleid/1060971232.html
    - 解决方案
        - 简单方案：`-DLog4j22.formatMsgNoLookups=true`
    - 检测工具：https://github.com/webraybtl/Log4j
- log4j1案例(/smjava/logging/log4j1-jdklog)
    - 引入依赖`log4j:log4j:1.2.17`

```java
/**
* 无 log4j.properties 文件时打印如下：
* log4j:WARN No appenders could be found for logger (cn.aezo.logging.log4j1.Log4j1App).
* log4j:WARN Please initialize the log4j system properly.
* log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
* 
* 有 log4j.properties 文件之后打印如下：
* 2021-12-10 21:34:01 log4j debug message
* 2021-12-10 21:34:01 log4j info message
*/
// org.apache.log4j.Logger
private static final Logger logger = Logger.getLogger(Log4j1App.class);
public static void main(String[] args){
    if(logger.isTraceEnabled()){
        logger.debug("log4j trace message");
    }
    if(logger.isDebugEnabled()){
        logger.debug("log4j debug message");
    }
    if(logger.isInfoEnabled()){
        logger.debug("log4j info message");
    }
}

// log4j.properties(也支持log4j.xml)。配置参考：https://blog.csdn.net/niuch1029291561/article/details/80938095
log4j.rootLogger = debug, console
log4j.appender.console = org.apache.log4j.ConsoleAppender
log4j.appender.console.layout = org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern = %-d{yyyy-MM-dd HH:mm:ss} %m%n
```

- log4j2案例(/smjava/logging/log4j2)
    - 引入依赖`org.apache.logging.log4j:log4j-api:2.15.0`和`org.apache.logging.log4j:log4j-core:2.15.0`

```java
/**
* 无 log4j2.xml 文件时无任何信息打印
* 有 log4j2.xml 文件之后打印如下：
* 21:52:05.789 [main] DEBUG cn.aezo.logging.log4j2.Log4j2App - log4j debug message
* 21:52:05.794 [main] DEBUG cn.aezo.logging.log4j2.Log4j2App - log4j info message
*/
// org.apache.logging.log4j.Logger org.apache.logging.log4j.LogManager
// 和log4j1是不同的，此时Logger是log4j-api中定义的接口，而log4j1中的Logger则是类
private static final Logger logger = LogManager.getLogger(Log4j2App.class);
public static void main(String[] args){
    if(logger.isTraceEnabled()){
        logger.debug("log4j trace message");
    }
    if(logger.isDebugEnabled()){
        logger.debug("log4j debug message");
    }
    if(logger.isInfoEnabled()){
        logger.debug("log4j info message");
    }
}
```

## slf4j

- [slf4j](http://www.slf4j.org/)是门面模式的典型应用(门面模式：外部与一个子系统的通信必须通过一个统一的外观对象进行，使得子系统更易于使用)
- slf4j(slf4j-api)、commons-logging均为日志接口，不提供日志的具体实现
- slf4j-simple、logback都是slf4j的具体实现；log4j并不直接实现slf4j，但是有专门的一层桥接slf4j-log4j12来实现slf4j
- 案例
    - 引入`org.slf4j:slf4j-api:1.7.25`(日志实现需额外引入)
    - 使用

    ```java
    // 通过门面方法获取具体得实现，核心逻辑也是从此处开始的(从classpath下去找org/slf4j/impl/StaticLoggerBinder.class)
    Logger logger = LoggerFactory.getLogger(Object.class);
    ```
- 如果不引入日志实现则会提示

```bash
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
```
- 如果引入多个日志实现(如logback-classic等)则会提示

```bash
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/Users/smalle/.m2/repository/ch/qos/logback/logback-classic/1.2.3/logback-classic-1.2.3.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/Users/smalle/.m2/repository/org/apache/logging/log4j/log4j-slf4j-impl/2.10.0/log4j-slf4j-impl-2.10.0.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [ch.qos.logback.classic.util.ContextSelectorStaticBinder]
```

## logback

- [官网](https://logback.qos.ch/)
- logback内置日志颜色：https://logback.qos.ch/manual/layouts.html#coloring
    - 支持的颜色字符编码：%black 黑色、%red 红色、%green 绿色、%yellow 黄色、%blue 蓝色、%magenta 洋红色、%cyan 青色、%white 白色、%gray 灰色
    - 对应加粗的颜色代码：%boldRed、%boldGreen、%boldYellow、%boldBlue、%boldMagenta、%boldCyan、%boldWhite、%highlight 高亮色
    - 使用如：`%d{yyyy-MM-dd HH:mm:ss.SSS} %cyan([%thread]) %yellow(%-5level) %green(%logger{36}).%gray(%M)-%boldMagenta(%line) - %blue(%msg%n)`
    - 但是存在一个问题，控制台打印时info、error等不同级别显示的颜色是一致的，仅仅是%thread和%d这中日志字段的颜色不一致。可使用自定义日志颜色解决：https://blog.csdn.net/qq_31226223/article/details/82559355
        - 如果是springboot项目，springboot提供了其自定义的日志颜色转换类，可以直接使用

## spring-log

- spring-core
    - **`org.springframework:spring-jcl`**
        - `org.apache.logging.log4j:log4j-api[optional]`
        - `org.slf4j:slf4j-api[optional]`
- spring-boot-starter-logging(可看出springboot使用slf4j+logback进行日志输出)
    - `ch.qos.logback:logback-classic`
    - `org.apache.logging.log4j:log4j-to-slf4j` log4j2到slf4j的桥梁
        - log4j-api
        - slf4j-api
    - `org.slf4j:jul-to-slf4j` jdk-logging到slf4j的桥梁
- spring-jcl
    - 包`org.apache.commons.logging.*`，和commons-logging包一样，是因为spring直接将commons-logging拷贝过来进行维护
- spring-jcl入口

```java
// 通过此方法获取日志对象，实际调用 LogAdapter.createLog
private static final Log logger = LogFactory.getLog(App.class); // org.apache.commons.logging.Log

// org.apache.commons.logging.LogAdapter
final class LogAdapter {
    // 默认使用java.util.logging日志框架
    private static LogApi logApi = LogApi.JUL;

    // 根据classpath下拥有的类名来判断具体使用的日志框架
	static {
		ClassLoader cl = LogAdapter.class.getClassLoader();
		try {
			// Try Log4j 2.x API
			Class.forName("org.apache.logging.log4j.spi.ExtendedLogger", false, cl);
			logApi = LogApi.LOG4J;
		}
		catch (ClassNotFoundException ex1) {
			try {
				// Try SLF4J 1.7 SPI
				Class.forName("org.slf4j.spi.LocationAwareLogger", false, cl);
				logApi = LogApi.SLF4J_LAL;
			}
			catch (ClassNotFoundException ex2) {
				try {
					// Try SLF4J 1.7 API
					Class.forName("org.slf4j.Logger", false, cl);
					logApi = LogApi.SLF4J;
				}
				catch (ClassNotFoundException ex3) {
					// Keep java.util.logging as default
				}
			}
		}
	}
    
    public static Log createLog(String name) {
        switch (logApi) {
            case LOG4J:
                return Log4jAdapter.createLog(name);
            case SLF4J_LAL:
                return Slf4jAdapter.createLocationAwareLog(name);
            case SLF4J:
                return Slf4jAdapter.createLog(name);
            default:
                // Defensively use lazy-initializing adapter class here as well since the
                // java.logging module is not present by default on JDK 9. We are requiring
                // its presence if neither Log4j nor SLF4J is available; however, in the
                // case of Log4j or SLF4J, we are trying to prevent early initialization
                // of the JavaUtilLog adapter - e.g. by a JVM in debug mode - when eagerly
                // trying to parse the bytecode for all the cases of this switch clause.
                return JavaUtilAdapter.createLog(name);
        }
    }

    private enum LogApi {LOG4J, SLF4J_LAL, SLF4J, JUL}
}
```
- springboot日志入口

```java
public class SpringApplication {
    // 实例化SpringApplication时，便会实例化Log
    // org.apache.commons.logging.LogFactory(通过spring-jcl获取日志对象)
    private static final Log logger = LogFactory.getLog(SpringApplication.class);
}
```
