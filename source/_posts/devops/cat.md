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
    - Type常见如：URL、SQL、Call、Method、Cache、Task、RemoteCall、PigeonCall、PigeonService
- 整体设计

    ![CAT整体设计](/data/images/arch/cat-overall.png)

    - 在实际开发和部署中，cat-consumer和cat-home是部署在一个jvm内部

## 安装及使用

### 基于docker安装服务端

- 基于`cat v3.0.0`进行测试，参考：https://github.com/dianping/cat/wiki/readme_server
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
      #- 8091:8091
    volumes:
      - /home/data/cat/appdatas:/data/appdatas
      - /home/data/cat/applogs:/data/applogs
    environment:
      TZ: Asia/Shanghai
      # CAT服务器本身包含一个名为cat的客户端
      CAT_HOME: /data/appdatas/cat
      # 注意 -Dhost.ip 视情况填写
      CATALINA_OPTS: -server -DCAT_HOME=$$CAT_HOME -Djava.awt.headless=true -Xms512M -Xmx1G -XX:PermSize=256m -XX:MaxPermSize=256m -XX:NewSize=512m -XX:MaxNewSize=512m -XX:SurvivorRatio=10 -XX:+UseParNewGC -XX:ParallelGCThreads=4 -XX:MaxTenuringThreshold=13 -XX:+UseConcMarkSweepGC -XX:+DisableExplicitGC -XX:+UseCMSInitiatingOccupancyOnly -XX:+ScavengeBeforeFullGC -XX:+UseCMSCompactAtFullCollection -XX:+CMSParallelRemarkEnabled -XX:CMSFullGCsBeforeCompaction=9 -XX:CMSInitiatingOccupancyFraction=60 -XX:+CMSClassUnloadingEnabled -XX:SoftRefLRUPolicyMSPerMB=0 -XX:-ReduceInitialCardMarks -XX:+CMSPermGenSweepingEnabled -XX:CMSInitiatingPermOccupancyFraction=70 -XX:+ExplicitGCInvokesConcurrent -Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.EPollSelectorProvider -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.util.logging.config.file="$$CATALINA_HOME\conf\logging.properties" -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCApplicationConcurrentTime -XX:+PrintHeapAtGC -Xloggc:/data/applogs/heap_trace.txt -XX:-HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/applogs/HeapDumpOnOutOfMemoryError -Djava.util.Arrays.useLegacyMergeSort=true -Dhost.ip=192.168.6.10 # -Xdebug -Xrunjdwp:transport=dt_socket,address=8091,server=y,suspend=n # 开启远程调试
    # docker-compose restart也会运行此命令，从而导致失败
    #command: /bin/sh -c "sed -i 's/<Connector/<Connector URIEncoding=\"UTF-8\"/' $$CATALINA_HOME/conf/server.xml && catalina.sh run"
    restart: always
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
- 下载[cat-home.war](http://unidal.org/nexus/service/local/repositories/releases/content/com/dianping/cat/cat-home/3.0.0/cat-home-3.0.0.war)到docker-compose.yml所在目录，重命名为`cat.war`(mv cat-home-3.0.0.war cat.war)
- 启动容器`docker-compose up -d`
- 部署war包`docker cp cat.war sq-tomcat:/usr/local/tomcat/webapps` (每次重新创建了tomcat容器都必须重新部署)
- 访问`http://192.168.6.10:8888/cat`
- 配置(未配置访问Transaction菜单等会报错)，默认用户名密码为`admin/admin`
    - 访问`http://192.168.6.10:8888/cat/s/config?op=serverConfigUpdate`进行服务端配置：修改ip为192.168.6.10(视情况修改)，启动hdfs的ip可以不用考虑(默认关闭hdfs)
    - 访问`http://192.168.6.10:8888/cat/s/config?op=routerConfigUpdate`进行客户端路由配置：修改ip为192.168.6.10
    - 重启tomcat

### 常见问题

- 基于docker安装，服务端界面显示`出问题CAT的服务端:[192.168.6.10]`，这个显示不影响数据上报和监控，仅仅是IP配置不规范。主要是CAT默认使用获取的内网IP，则此时为docker容器IP，此时可设置`host.ip`
    - 解决办法：在启动参数中加`-Dhost.ip=192.168.6.10`
- 加入Cat依赖，客户端启动报错`java.lang.NoClassDefFoundError: org/aspectj/util/PartialOrder$PartialComparable`，表示缺少`aspectjweaver`相关jar包
    - 解决办法：如springboot引入`org.springframework.boot#spring-boot-starter-aop`依赖

### 客户端(Windows下IDEA启动)

- 参考：https://github.com/dianping/cat/blob/master/lib/java/README.zh-CN.md
- 创建文件`D:\data\appdatas\cat\client.xml`
    - windows环境时，此处D盘和tomcat运行盘符一致；linux系统则为/data/appdatas/cat目录；或者设置CAT_HOME环境变量。**如果无此文件，Java应用仍然可以正常启动运行**
    - 生成的运行日志文件位于`D:\data\applogs\cat`
    - 部署了多个客户端时，此配置文件和日志文件可以共用

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
<!-- 
    1.CAT v3.0.0按照下述引用，客户端启动报错 java.lang.NoClassDefFoundError: Could not initialize class com.dianping.cat.message.internal.DefaultMessageProducer
    2.可以下载源码，然后复制手动打包/上传到私有仓库，然后下载生成的cat-client对应jar包
-->
<dependency>
    <groupId>com.dianping.cat</groupId>
    <artifactId>cat-client</artifactId>
    <version>3.0.0</version>
</dependency>

<repositories>
    <repository>
        <id>unidal.releases</id>
        <url>http://unidal.org/nexus/content/repositories/releases/</url>
    </repository>
</repositories>
```
- 创建`src/main/resources/META-INF/app.properties`，并写入`app.name=sq-test`
- 在测试项目中写入埋点代码，即可进行测试

```java
public void test() {
    //  创建一个Transaction，用于Transaction报表
    Transaction t = Cat.newTransaction("URL", "pageName");

    try {
        // 记录一个事件。如果只是统计Event报表，可以不用开启Transaction
        Cat.logEvent("URL.Server", "serverIp", Event.SUCCESS, "ip=127.0.0.1");
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
    CatFilter filter = new CatFilter(); // 会打印所有URL上的参数，如登录密码等敏感参数则需要重新定义此CatFilter
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
- 与日志框架整合记录Event。此时可以对`logger.error`类型的日志进行上报统计，可以代替`Cat.logError(e);`以减少代码量
    - [logback](https://github.com/dianping/cat/tree/master/integration/logback)
    - 从上述链接复制logback插件源码`CatLogbackAppender.java`，并去掉`Cat.logTrace`相关代码(Cat3.0不支持)
    - 在logback.xml文件中加入对应的Appender和appender-ref
    - 注意：logback记录日志的时候需要传入异常对象，如果不传无法在cat中的problem展示错误信息。如：`logger.error(e.getMessage(), e);`(生成的type如下，name则无法自定义，为e对应的类名)

### 分布式调用链监控

- 实现Cat.Context接口用来存储RootId(用于标识唯一的一个调用链)、ParentId(谁在调用我)、ChildId(我在调用谁) [^1]
- 客户端和服务端基于Header传递上述ID
- 在Cat中内置了两个方法`Cat.logRemoteCallClient()`以及`Cat.logRemoteCallServer()`，可以简化处理逻辑

    <details>
    <summary>源码如下</summary>

    ```java
    // 客户端需要创建一个Context，然后初始化三个ID放入到此Context中
    public static void logRemoteCallClient(Context ctx, String domain) {
		try {
			MessageTree tree = Cat.getManager().getThreadLocalMessageTree();
			String messageId = tree.getMessageId();

			if (messageId == null) {
				messageId = Cat.createMessageId();
				tree.setMessageId(messageId);
			}

            // 生成一个 childId，需要将其放置在如Header中传递到服务端，服务端接受后将此ID设置成自己的MessageId
			String childId = Cat.getProducer().createRpcServerId(domain);
            // 如果 Event.type 为 CatConstants.TYPE_REMOTE_CALL="RemoteCall" 时，CAT图表中才会显示 "[:: show ::]"
			Cat.logEvent(CatConstants.TYPE_REMOTE_CALL, "", Event.SUCCESS, childId);

			String root = tree.getRootMessageId();

			if (root == null) {
				root = messageId;
			}

			ctx.addProperty(Context.ROOT, root);
			ctx.addProperty(Context.PARENT, messageId);
			ctx.addProperty(Context.CHILD, childId);
		} catch (Exception e) {
			errorHandler(e);
		}
	}

    // 服务端需要接受这个context，然后设置到自己的Transaction中
    public static void logRemoteCallServer(Context ctx) {
		try {
			MessageTree tree = Cat.getManager().getThreadLocalMessageTree();
			String childId = ctx.getProperty(Context.CHILD);
			String rootId = ctx.getProperty(Context.ROOT);
			String parentId = ctx.getProperty(Context.PARENT);

			if (parentId != null) {
				tree.setParentMessageId(parentId);
			}
			if (rootId != null) {
				tree.setRootMessageId(rootId);
			}
			if (childId != null) {
				tree.setMessageId(childId);
			}
		} catch (Exception e) {
			errorHandler(e);
		}
	}
    ```
    </details>

- RestTemplate调用服务使用示例

<details>
<summary>源码如下</summary>

```java
// ## 客户端：每次发送请求之前将上述3个ID放入到 Header 中
// 自定义 RestTemplate 拦截器
@Component
public class CatClientHttpRequestInterceptor implements ClientHttpRequestInterceptor {
    private Logger logger = LoggerFactory.getLogger(CatClientHttpRequestInterceptor.class);

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body, ClientHttpRequestExecution execution)
            throws IOException {
        HttpHeaders headers = request.getHeaders();

        Transaction t = null;
        ClientHttpResponse retObj = null;
        try {
            t = Cat.newTransaction("ClientHttpRequest", request.getURI().toString());

            CatContext catContext = new CatContext();
            Cat.logRemoteCallClient(catContext);

            headers.add(Cat.Context.ROOT, catContext.getProperty(Cat.Context.ROOT));
            headers.add(Cat.Context.PARENT, catContext.getProperty(Cat.Context.PARENT));
            headers.add(Cat.Context.CHILD, catContext.getProperty(Cat.Context.CHILD));

            retObj = execution.execute(request, body);

            t.setStatus(Transaction.SUCCESS);
        } catch (Throwable e) {
            logger.error("发送HTTP请求出错", e);
            if(t != null) {
                t.setStatus(e);
            }
        } finally {
            if(t != null) {
                t.complete();
            }
        }

        return retObj;
    }

    public static class CatContext implements Cat.Context{
        private Map<String,String> properties = new HashMap<String, String>();

        @Override
        public void addProperty(String key, String value) {
            properties.put(key,value);
        }

        @Override
        public String getProperty(String key) {
            return properties.get(key);
        }
    }
}

// 注入拦截器到 RestTemplate
@Bean
public RestTemplate restTemplate(CatClientHttpRequestInterceptor catClientHttpRequestInterceptor) {
    RestTemplate restTemplate = new RestTemplate();
    restTemplate.setInterceptors(Collections.singletonList(catClientHttpRequestInterceptor));
    return restTemplate;
}

// ## 服务端：从客户端请求的 Header 中获取上述3个ID
@Component
@Order(0)
public class CatRemoteCallServletFilter implements Filter {
    private Logger logger = LoggerFactory.getLogger(CatRemoteCallServletFilter.class.getName());

    public static final String CROSS_SERVER = "PigeonService";

    @Value("${spring.application.name}")
    private String applicationName;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        Transaction t = null;
        try {
            if(StringUtils.isNotBlank(req.getHeader(Cat.Context.PARENT))) {
                // 服务提供者
                t = Cat.newTransaction(CROSS_SERVER, req.getRequestURI());
                Cat.logEvent(CROSS_SERVER + ".applicationName", applicationName);

                CatContext catContext = new CatContext();
                catContext.addProperty(Cat.Context.ROOT, req.getHeader(Cat.Context.ROOT));
                catContext.addProperty(Cat.Context.PARENT, req.getHeader(Cat.Context.PARENT));
                catContext.addProperty(Cat.Context.CHILD, req.getHeader(Cat.Context.CHILD));
                Cat.logRemoteCallServer(catContext);
            }
        } catch (Throwable e) {
            logger.error("start cat transaction error", e);
            if(t != null) {
                t.complete();
            }
        }

        if(t != null) {
            try {
                chain.doFilter(request, response);
                t.setStatus(Transaction.SUCCESS);
            } catch (Throwable e) {
                t.setStatus(e);
                throw e;
            } finally {
                t.complete();
            }
        } else {
            chain.doFilter(request, response);
        }
    }

    @Override
    public void destroy() {}

    private static class CatContext implements Cat.Context {
        private Map<String,String> properties = new HashMap<String, String>();

        @Override
        public void addProperty(String key, String value) {
            properties.put(key,value);
        }

        @Override
        public String getProperty(String key) {
            return properties.get(key);
        }
    }
}
```
</details>

### 异步/主子线程监控问题

- Hystrix处理时会产生子线程，而主子线程中的MessageTree是不同的。主要是Cat将MessageTree存储在ThreadLocal中
- Feign + Hystrix组合使用时，Hystrix调用服务时是在子线程中完成的，单独使用Feign不会产生子线程。`feign.hystrix.enabled: false`关闭feign对hystrix支持
- `Hystrix`主子线程传值解决方案 [^2]

<details>
<summary>源码如下</summary>

```java
@Configuration
public class CatHystrixFeignAspect {
    private Logger logger = LoggerFactory.getLogger(CatHystrixFeignAspect.class);

    static final HystrixRequestVariableDefault<CatContext> hystrixCatContext = new HystrixRequestVariableDefault<>();

    @Value("${spring.application.name}")
    private String applicationName;

    @Aspect
    @Component
    public class HystrixAspect {
        // 定义Feign接口(@FeignClient)对应方法的切面
        @Pointcut(value = "@within(org.springframework.cloud.openfeign.FeignClient)")
        public void point() {
        }

        // 从Tomcat主线程获取MessageTree数据，并设置到Hystrix子线程中
        @Around("point()")
        public Object around(ProceedingJoinPoint pjp) {
            Object retObj = null;
            Transaction t = null;
            boolean proceed = false;
            try {
                if (!HystrixRequestContext.isCurrentThreadInitialized()) {
                    HystrixRequestContext.initializeContext();
                }
                t = Cat.newTransaction("FeignAspect", pjp.getSignature().toString());

                CatContext catContext = new CatContext();
                Cat.logRemoteCallClient(catContext, applicationName);
                hystrixCatContext.set(catContext);

                try {
                    proceed = true;
                    retObj = pjp.proceed();
                } catch (Throwable e) {
                    logger.error("传递 CatContext 出错", e);
                }

                t.setStatus(Transaction.SUCCESS);
            } catch (Throwable e) {
                logger.error("主子线程传递 CatContext 出错", e);
                if(t != null) {
                    t.setStatus(e);
                }
                if(!proceed) {
                    try {
                        retObj = pjp.proceed();
                    } catch (Throwable throwable) {
                        logger.error("", throwable);
                    }
                }
            } finally {
                // 销毁当前线程HystrixRequestContext，同时也会销毁HystrixRequestVariableDefault中的数据
                if (HystrixRequestContext.isCurrentThreadInitialized()) {
                    HystrixRequestContext.getContextForCurrentThread().shutdown();
                }
                if(t != null) {
                    t.complete();
                }
            }

            return retObj;
        }
    }

    @Component
    public class FeignInterceptor implements RequestInterceptor {
        // Hystrix子线程，通过messageTreeLocal可获取主线程数据，但是直接Cat.logEvent是打印到当前子线程的MessageTree中
        @Override
        public void apply(RequestTemplate requestTemplate) {
            CatContext catContext = hystrixCatContext.get();

            requestTemplate.header(Cat.Context.ROOT, catContext.getProperty(Cat.Context.ROOT));
            requestTemplate.header(Cat.Context.PARENT, catContext.getProperty(Cat.Context.PARENT));
            requestTemplate.header(Cat.Context.CHILD, catContext.getProperty(Cat.Context.CHILD));
        }
    }

    private static class CatContext implements Cat.Context{
        private Map<String,String> properties = new HashMap<String, String>();

        @Override
        public void addProperty(String key, String value) {
            properties.put(key,value);
        }

        @Override
        public String getProperty(String key) {
            return properties.get(key);
        }
    }
}
```
</details>

## 管理界面使用

- 项目配置信息
    - 新增：CAT上项目名称-事业部-产品线，如果客户端只是在`app.properties`中配置`app.name`则会归并到`Default-Default`的事业部和产品线
- 修改默认admin账号密码：可修改cat-home源码后重新编译，参考：http://www.bubuko.com/infodetail-3091160.html
- 邮件告警需要自行启动邮件发送服务，参考：https://github.com/dianping/cat/blob/master/integration/cat-alert/README.md

## 源码分析

```java
// ## cat-home
// 内置servlet拦截器，自动完成跟踪。其中会依次执行ENVIRONMENT、ID_SETUP、LOG_SPAN、LOG_CLIENT_PAYLOAD的handle处理方法
public class CatFilter implements Filter {} // com.dianping.cat.servlet.CatFilter

// 处理 /cat/r/m 请求
public class Handler implements PageHandler<Context> { // com.dianping.cat.report.page.logview.Handler
    @Override
    @PayloadMeta(Payload.class)
    @InboundActionMeta(name = "m") // 接受/cat/r/m请求
    public void handleInbound(Context ctx) throws ServletException, IOException {
        // display only, no action here
    }

    @Override
    @OutboundActionMeta(name = "m") // 返回/cat/r/m响应，如http://192.168.6.10:8888/cat/r/m/sq-gateway-c0a83801-434041-15?domain=sq-gateway
    public void handleOutbound(Context ctx) throws ServletException, IOException {
        // ...

        // 获取页面展示数据。内部调用BaseCompositeModelService
        // BaseCompositeModelService会重新发起 /cat/r/model 请求，如直接访问 http://192.168.6.10:8888/cat/r/model/logview/sq-gateway/HISTORICAL?op=xml&messageId=sq-gateway-c0a83801-434041-15&waterfall=false&timestamp=1562547600000 返回的是一个xml字符串
        // 请求 /cat/r/model 对应的处理逻辑位于注解 @OutboundActionMeta(name = "model")
        logView = getLogView(messageId, payload.isWaterfall());

        m_jspViewer.view(ctx, model); // 渲染jsp页面
    }
}

// 处理 /cat/r/model 请求
public class Handler extends ContainerHolder implements Initializable, PageHandler<Context> { // com.dianping.cat.report.page.model.Handler
    // ...

    @Override
    @OutboundActionMeta(name = "model")
    public void handleOutbound(Context ctx) throws ServletException, IOException {

        // 实际调用 LocalMessageService#buildReport -> LocalMessageService#buildNewReport(从 Bucket 中获取数据，如 Bucket 位置文件：LocalBucket[/data/appdatas/cat/bucket/dump/20190708/09/sq-gateway-192.168.6.10.dat])
        xml = service.getReport(request, period, domain, payload);

    }
}

public class LocalMessageService extends LocalModelService<String> implements ModelService<String> { // com.dianping.cat.report.page.logview.service.LocalMessageService
    private String buildNewReport(ModelRequest request, ModelPeriod period, String domain, ApiPayload payload)
							throws Exception {
        // 从 Bucket 中获取数据，如 Bucket 位置文件：LocalBucket[/data/appdatas/cat/bucket/dump/20190708/09/sq-gateway-192.168.6.10.dat]
        Bucket bucket = m_bucketManager.getBucket(id.getDomain(),	NetworkInterfaceManager.INSTANCE.getLocalHostAddress(), id.getHour(), false);

        // 显示成普通 html 或者是瀑布图
        if (tree.getMessage() instanceof Transaction && waterfall) {
            m_waterfall.encode(tree, content);
        } else {
            // HtmlMessageCodec#encode -> HtmlMessageCodec#encodeMessage (包含了对Event的解析显示，如 Event.type 为 CatConstants.TYPE_REMOTE_CALL="RemoteCall" 时，CAT图表中才会显示 "[:: show ::]"，同理还有 RemoteLink)
            m_html.encode(tree, content);
        }
    }
}

// ## cat-client
// 产生 Event、Transaction等日志
public class DefaultMessageProducer implements MessageProducer {
    // 产生Event日志
    @Override
    public void logEvent(String type, String name) {}

    // 产生Transaction日志
    @Override
    public Transaction newTransaction(String type, String name) {}

    // 产生其他日志
}

// 日志管理。将 Cat.LogEvent 等产生的日志放入到消息上下文中(MessageTree消息树中)
public class DefaultMessageManager extends ContainerHolder implements MessageManager, Initializable, LogEnabled { // com.dianping.cat.message.internal.DefaultMessageManager

    // 没一个线程有各自的日志上下文(保存有MessageTree消息树)
    private ThreadLocal<Context> m_context = new ThreadLocal<Context>();
    private Map<String, TaggedTransaction> m_taggedTransactions;

    // 往 Context 中添加一条CAT日志
    @Override
    public void add(Message message) {
        Context ctx = getContext();

        if (ctx != null) {
            ctx.add(message);
        }
    }

    @Override
    public void start(Transaction transaction, boolean forked) {
        Context ctx = getContext();

        if (ctx != null) {
            ctx.start(transaction, forked);

            if (transaction instanceof TaggedTransaction) {
                TaggedTransaction tt = (TaggedTransaction) transaction;

                m_taggedTransactions.put(tt.getTag(), tt);
            }
        } else if (m_firstMessage) {
            m_firstMessage = false;
            m_logger.warn("CAT client is not enabled because it's not initialized yet");
        }
    }

    // CAT日志上下文
    class Context {
        // 当前线程的日志树
        private MessageTree m_tree;

    }
}

```




---

参考文章

[^1]: https://www.cnblogs.com/xing901022/p/6237874.html
[^2]: https://chenyongjun.vip/articles/83

