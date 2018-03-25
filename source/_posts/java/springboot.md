---
layout: "post"
title: "springboot"
date: "2017-07-23 15:05"
categories: [java]
tags: [springboot, hibernate, mybatis, rabbitmq]
---

## 目录

- `helloworld`(1.5.6)
- 数据访问
	- `hibernate`(1.5.6, mysql)
	- `mybatis`(1.5.6)
- `thymeleaf-spring-security`(1.5.6)
- `rabbitmq`(1.5.6)

## hello world

- 引入依赖

	```xml
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>1.4.3.RELEASE</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>

	<dependencies>
		<!--包含spring-boot-starter、hibernate-validator、jackson-databind、spring-web、spring-webmvc-->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
	</dependencies>
	```
- 启动类 `SpringbootApplication.java`

	```java
	@RestController // @Controller
	@EnableAutoConfiguration // 开启自动配置
	public class SpringbootApplication {
		// 访问 http://localhost:8080/
		@RequestMapping("/")
		String home() {
			return "Hello World!";
		}

		public static void main(String[] args) {
			SpringApplication.run(SpringbootApplication.class, args);
		}
	}
	```
- 至此，无需其他任何配置。浏览器访问：http://localhost:8080/

## 配置文件(properties/yml)

- profile配置：可新建`application.properties`(默认)、`application-dev.properties`(会继承默认中的配置)、`application-prod.properties`、`application-test.properties`来针对不同的运行环境(`application-{profile}.properties`)
- 使用配置文件(优先级从高到低)
	- 外部配置：`java -jar aezocn.jar --spring.profiles.active=prod`
	- 配置文件：`spring.profiles.active=dev` 代表使用application-dev.properties的配置文件(在application.properties中添加此配置)
- 可以idea中修改默认profiles或者某些配置达到运行多个实例的目的


## 常用配置

- 随应用启动而运行(实现`CommandLineRunner`接口)

	```
	@Component
	@Order(value = 1) // @Order值越小越优先
	public class HelpStartupRunner implements CommandLineRunner {
		@Value("${help.imageUploadRoot}")
		String imageUploadRoot;

		@Override
		public void run(String... args) throws Exception {
			initImageUploadRoot();
		}

		private void initImageUploadRoot() {
			System.out.println("help.imageUploadRoot = " + imageUploadRoot);

			File dicFile = new File(imageUploadRoot);
			if(!dicFile.exists() && !dicFile.isDirectory()) {
				dicFile.mkdir();
			}
		}
	}
	```

- 拦截器
	- 定义拦截器

		```java
		@Component
		public class MyInterceptor implements HandlerInterceptor {

			@Override
			public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
					throws Exception {
				System.out.println(">>>>>>>>>>在请求处理之前进行调用（Controller方法调用之前）");
				return true; // 只有返回true才会继续向下执行，返回false取消当前请求
			}

			/**
			* 这个方法只会在当前这个Interceptor的preHandle方法返回值为true的时候才会执行。
			* postHandle是进行处理器拦截用的，它的执行时间是在处理器进行处理之后，也就是在Controller的方法调用之后执行，但是它会在DispatcherServlet进行视图的渲染之前执行，也就是说在这个方法中你可以对ModelAndView进行操作。
			* 这个方法的链式结构跟正常访问的方向是相反的，也就是说先声明的Interceptor拦截器，该方法反而会后调用
			*/
			@Override
			public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
								ModelAndView modelAndView) throws Exception {
				System.out.println(">>>>>>>>>>请求处理之后进行调用（Controller方法调用之后），但是在视图被渲染之前");

				if(response.getStatus() == 500) {
					modelAndView.setViewName("/error/500");
				} else if(response.getStatus() == 404) {
					modelAndView.setViewName("/error/404");
				} else if(response.getStatus() == 403) {
					modelAndView.setViewName("/error/403");
				}
			}

			/**
			* 该方法也是需要当前对应的Interceptor的preHandle方法的返回值为true时才会执行。
			* 该方法将在整个请求完成之后，也就是DispatcherServlet渲染了视图执行
			* 这个方法的主要作用是用于清理资源的，当然这个方法也只能在当前这个Interceptor的preHandle方法的返回值为true时才会执行。
			*/
			@Override
			public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex)
					throws Exception {
				System.out.println(">>>>>>>>>>在整个请求结束之后被调用，也就是在DispatcherServlet 渲染了对应的视图之后执行（主要是用于进行资源清理工作）");
			}
		}
		```
	- 注册拦截器

		```java
		@Configuration
		public class InterceptorConfig extends WebMvcConfigurerAdapter {
			@Override
			public void addInterceptors(InterceptorRegistry registry) {
				// 多个拦截器组成一个拦截器链
				// addPathPatterns 用于添加拦截规则
				// excludePathPatterns 用于排除拦截
				registry.addInterceptor(new MyInterceptor()).addPathPatterns("/**");

				super.addInterceptors(registry);
			}
		}
		```
- 获取Bean：此处选择实现`ApplicationContextAware`接口 [^7]

	```java
	@Component("springContextU")
	public class SpringContextU implements ApplicationContextAware {

		private static ApplicationContext applicationContext;

		@Override
		public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
			if(SpringContextU.applicationContext == null) {
				SpringContextU.applicationContext = applicationContext;
			}
		}

		/**
		* 获取applicationContext
		* @return
		*/
		public static ApplicationContext getApplicationContext() {
			return applicationContext;
		}

		/**
		* 通过name获取 Bean.
		* @param name
		* @return
		*/
		public static Object getBean(String name){
			return getApplicationContext().getBean(name);
		}

		/**
		* 通过class获取Bean.
		* @param clazz
		* @param <T>
		* @return
		*/
		public static <T> T getBean(Class<T> clazz){
			return getApplicationContext().getBean(clazz);
		}

		/**
		* 通过name以及Clazz返回指定的Bean
		* @param name
		* @param clazz
		* @param <T>
		* @return
		*/
		public static <T> T getBean(String name,Class<T> clazz){
			return getApplicationContext().getBean(name, clazz);
		}

	}
	```

- 异步执行服务 [^8]
	- 启动类加注解`@EnableAsync`
	- 服务类方法加注解`@Async`

- `@Value`给静态成员设值

	```java
	// 定义
	@ConfigurationProperties(prefix = "myValue")
	public class MyValue {
		// ...Model：字段、get、set方法
	}

	// 设值：在application.properties中设置`myValue.val`的值

	// 取值
	@Value("${myValue.val}")
	private String val;

	private static String hello;

	@Value("${myValue.hello}")
	public setHello(String hello) {
		this.hello = hello;
	}
	```
- 跨域资源共享（CORS）[^9]

	```java
	@Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurerAdapter() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedHeaders("*")
                        .allowedMethods("*")
                        .allowedOrigins("*")
                        .allowCredentials(true);
            }
        };
    }
	```
	- 使用spring security的CORS配置可参考相应文章

- 国际化
	- 在resources目录增加两个properties文件：`messages.properties`(默认)、`messages_zh_CN.properties`(中文)
		- 可通过`spring.messages.basename=i18n/messages`定义配置文件路径，此时应该将`messages.*`放在`resources/i18n`目录
	- 在其中加入类似配置`error.unknowexception=未知错误`
	- 调用

		```java
		@Autowired
    	private MessageSource messageSource;

		private String getLocalMessage(String code) {
			String localMessage = null;
			Locale locale = null;
			try {
				locale = LocaleContextHolder.getLocale();
				localMessage = messageSource.getMessage(code, null, locale);
			} catch (NoSuchMessageException e1) {
				logger.warn("invalid i18n! code: " + code + ", local: " + locale);
			}

			return localMessage;
		}
		```

## 请求及响应

- 相关配置

	```bash
	# 端口
	server.port=9090
	# context-path路径
	server.context-path=/myapp
	```
- 请求协议

|request-method |content-type   |postman   |springboot   |说明
--|---|---|---|---
post |application/json   |row-json   |(@RequestBody User user)   |如果后台使用了@RequestBody，此时row-text等都无法请求到
post |multipart/form-data  |form-data   |(HttpServletRequest request, User user, @RequestParam("hello") String hello)   |参考实例1。可进行文件上传(包含参数)


1. `'content-type': 'multipart/form-data;`(postman对应form-data)：可进行文件上传(包含参数), 响应代码如：
	- `javascript XHR`需要使用`new FormData()`进行数据传输(可查看postman代码)
	- 还可使用`MultipartFile`来接受单个文件, 使用`List<MultipartFile> files = ((MultipartHttpServletRequest) request).getFiles("file");`获取多个文件 [^3]

	```java
	// 此时User会根据前台参数和User类的set方法自动填充(调用的是User类的set方法)
	@RequestMapping(path = "/edit-user", method = RequestMethod.POST)
	public Map<String, Object> editEvent(HttpServletRequest request, User user, @RequestParam("hello") String hello) {
		Map<String, Object> result = new HashMap<>();

		System.out.println("hello = " + hello); // hello world
		System.out.println("user.getName() = " + user.getName()); // smalle

		try {
			// 为了获取文件项
			Collection<Part> parts = request.getParts();

			// part中包含了所有数据(参数和文件)
			for (Part part: parts) {
				String originName = part.getSubmittedFileName(); // 上传文件对应的文件名
				System.out.println("originName = " + originName);

				if(null != originName) {
					// 此part为文件
					InputStream inputStream = part.getInputStream();
					// ...
				}
			}
		}  catch (Exception e) {
			e.printStackTrace();
		}

		return result;
	}
	```


## 数据访问

- 数据库驱动

	```xml
	<!--数据库驱动-->
	<dependency>
		<groupId>mysql</groupId>
		<artifactId>mysql-connector-java</artifactId>
		<scope>runtime</scope>
	</dependency>
	```
- 配置

	```bash
		## spring.datasource.driver-class-name=com.mysql.jdbc.Driver
		spring.datasource.url=jdbc:mysql://localhost/springboot?useUnicode=true&characterEncoding=utf-8
		spring.datasource.username=root
		spring.datasource.password=root

		# 每次启动都会执行, 且在hibernate建表语句之前执行
		# 若无此定义, springboot也会默认执行resources下的schema.sql(先)和data.sql(后)文件(如果存在)
		# 执行建表语句(也会执行插入等语句)
		spring.datasource.schema=classpath:schema.sql
		# 执行数据添加语句
		spring.datasource.data=classpath:data.sql
	```

### 对hibernate的默认支持(JPA)

参考AEZO：《hibernate》：[http://blog.aezo.cn#java@hibernate](http://blog.aezo.cn/2017/05/21/java/hibernate/)

### 整合mybatis

参考AEZO：《mybatis》：[http://blog.aezo.cn#java@mybatis](http://blog.aezo.cn/2017/05/22/java/mybatis/)

### JdbcTemplate访问数据

- 示例

	```java
	@Autowired
	private JdbcTemplate jdbcTemplate;

	String sql = "SELECT h.*, e.name as event_name from th_help h, th_event e where h.event_id = e.event_id";
	List<Map<String, Object>> object = jdbcTemplate.queryForList(sql);
	```

- jdbc批量执行sql语句

	```java
	// Message message = new Message(...);

	final String sql = "insert into th_message(user_id, message_type, content, is_read, is_valid, create_time) values(?, ?, ?, ?, ?, ?)";

	jdbcTemplate.batchUpdate(sql, new BatchPreparedStatementSetter() {
		@Override
		public void setValues(PreparedStatement preparedStatement, int i) throws SQLException {
			User user = users.get(i);
			preparedStatement.setLong(1, user.getUserId());
			preparedStatement.setObject(2, message.getMessageType());
			preparedStatement.setString(3, message.getContent());
			preparedStatement.setObject(4, 0);
			preparedStatement.setObject(5, 1);
			preparedStatement.setObject(6, DateU.nowTimestamp());
		}

		@Override
		public int getBatchSize() {
			return users.size();
		}
	});
	```

### 数据库相关配置

- 数据库/表新建时命名策略(JPA) [doc](https://docs.spring.io/spring-boot/docs/1.5.6.RELEASE/reference/htmlsingle/#howto-configure-hibernate-naming-strategy)

	- `org.springframework.boot.orm.jpa.hibernate.SpringPhysicalNamingStrategy`为springboot默认提供命令策略(实体驼峰转成数据库下划线)
	- 示例：给表名加前缀
		- 配置：`spring.jpa.hibernate.naming.physical-strategy=cn.aezo.springboot.CustomPhysicalNamingStrategy`

		```java
		public class CustomPhysicalNamingStrategy extends SpringPhysicalNamingStrategy {
			// 重写父类方法
			public Identifier toPhysicalTableName(Identifier name, JdbcEnvironment jdbcEnvironment) {
				// System.out.println("name = " + name);
				// System.out.println("jdbcEnvironment = " + jdbcEnvironment);
				// System.out.println("name.getCanonicalName() = " + name.getCanonicalName());
				// System.out.println("name.getText() = " + name.getText());

				return this.apply(Identifier.toIdentifier("th_" + name.getText()), jdbcEnvironment);
			}

			// copy父类方法
			private Identifier apply(Identifier name, JdbcEnvironment jdbcEnvironment) {
				if(name == null) {
					return null;
				} else {
					StringBuilder builder = new StringBuilder(name.getText().replace('.', '_'));

					for(int i = 1; i < builder.length() - 1; ++i) {
						if(this.isUnderscoreRequired(builder.charAt(i - 1), builder.charAt(i), builder.charAt(i + 1))) {
							builder.insert(i++, '_');
						}
					}

					return this.getIdentifier(builder.toString(), name.isQuoted(), jdbcEnvironment);
				}
			}

			// copy父类方法
			private boolean isUnderscoreRequired(char before, char current, char after) {
				return Character.isLowerCase(before) && Character.isUpperCase(current) && Character.isLowerCase(after);
			}
		}

		```

### 使用H2数据库 [^1] [^2]

- h2简介：内存数据库（Embedded database或in-momery database）具有配置简单、启动速度快、尤其是其可测试性等优点，使其成为开发过程中非常有用的轻量级数据库。在spring中支持HSQL、H2和Derby三种数据库
- [官网：http://h2database.com/html/main.html](http://h2database.com/html/main.html)
- springboot整合：[文章：《h2》](../db/h2.md)

## thymeleaf模板引擎

- 引入依赖

	```xml
	<!--thymeleaf模板引擎, 包含spring-boot-starter-web-->
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-thymeleaf</artifactId>
	</dependency>

	<!-- 可选：thymeleaf和springsecurity结合在页面级别进行权限控制 -->
	<!--<dependency>
		<groupId>org.thymeleaf.extras</groupId>
		<artifactId>thymeleaf-extras-springsecurity4</artifactId>
	</dependency>-->
	```
- properties配置

	```yml
	#spring:
	#  thymeleaf:
	#	# 将thymeleaf文件放在resources/templates/目录
    #	prefix: classpath:/templates/
    #	suffix: .html
	```
- 示例
	- Controller：类的注解必须是`@Controller`

		```java
		@Controller // 此时不能是@RestController
		public class ThymeleafController {

			// 页面显示resources/templates/hello.html的内容
			@RequestMapping("/hello")
			public String hello(Map<String, Object> model) {
				// 无需注入参数值时，则方法可不接收model参数
				model.put("hello", "UserController.thymeleaf");

				return "/hello";
			}
		}
		```
	- hello.html文件

		```html
		<!DOCTYPE html>
		<!-- xmlns:th="http://www.thymeleaf.org"声明后方可使用 th:* -->
		<html xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
			<head>
				<title>Hello World!</title>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
			</head>
			<body>
				<p th:text="${hello}">smalle</p>
				<p>${hello}</p>
			</body>
		</html>
		```
	- 显示结果(第二个${hello}并不能解析)

		```txt
		UserController.thymeleaf
		${hello}
		```
- 启用thymeleaf的html非严格模式
	- 添加配置`spring.thymeleaf.mode = LEGACYHTML5`
	- 添加依赖

		```xml
		<!-- 启用thymeleaf的html非严格模式 -->
		<dependency>
			<groupId>net.sourceforge.nekohtml</groupId>
			<artifactId>nekohtml</artifactId>
			<version>1.9.22</version>
		</dependency>
		```
- thymeleaf缓存(热部署)
	- 推荐使用`JRebel`(idea需要Ctrl+Shift+F9刷新)
	- 使用`devtools`(也适用于java文件热部署)
		- 增加maven配置
			
			```xml
			<dependency>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-devtools</artifactId>
				<optional>true</optional>
			</dependency>

			<build>
				<plugins>
					<plugin>
						<groupId>org.springframework.boot</groupId>
						<artifactId>spring-boot-maven-plugin</artifactId>
						<configuration>
							<fork>true</fork>
						</configuration>
					</plugin>
				</plugins>
			</build>
			```
		- idea需要Ctrl+Shift+F9刷新，相当于重启项目，较普通项目重启快
	- 配置中加`spring.thymeleaf.cache=false`
		- 需要使用maven启动
- thymeleaf语法：[文章：《thymeleaf》](../lang/thymeleaf.md)

## 企业级开发

### Nosql

#### 整合Mongodb

- 引入依赖

	```xml
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-data-mongodb</artifactId>
	</dependency>
	```
- application.properties配置添加：`spring.data.mongodb.uri=mongodb://name:pass@localhost:27017/test`、
- 查询方式
	- 使用基本查询

		```java
		DBCollection collection = mongoTemplate.getCollection("hscode"); // 获取集合(类似与key)

        DBObject query = new BasicDBObject();
        query.put("hsCode", hscode);

        DBObject dbObject = collection.findOne(query); // 打印直接就是json数据
		```
	- 创建实体，书写Dao(使用MongoTemplate完成) [^6]

### rabbitmq

- RabbitMQ是实现了高级消息队列协议(AMQP)的开源消息代理软件，也称为面向消息的中间件。后续操作需要先安装RabbitMQ服务

- 引入对amqp协议支持依赖

    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-amqp</artifactId>
    </dependency>
    ```
- 配置rabbitmq服务器链接

    ```yml
    spring:
      rabbitmq:
        host: localhost
        port: 5672
        username: guest
        password: guest
    ```
- 配置队列、生产者、消费者

    ```java
    // 配置队列 hello
    @Bean
    public Queue helloQueue() {
        return new Queue("hello");
    }

    // 生产者
    @Component
    public class Provider {

        @Autowired
        private AmqpTemplate rabbitTemplate;

        // 发送消息
        public void send() {
            String context = "hello " + new Date();
            System.out.println("Provider: " + context);
            this.rabbitTemplate.convertAndSend("hello", context);
        }
    }

    // 消费者
    @Component
    @RabbitListener(queues = "hello")
    public class Consumer {

        @RabbitHandler
        public void process(String msg) {
            System.out.println("Consumer: " + msg);
        }
    }
    ```
### session共享

- 基于redis实现session共享. 多个项目需要都引入此依赖，并连接相同的redis
- 引入依赖

	```xml
	<dependency>
		<groupId>org.springframework.session</groupId>
		<artifactId>spring-session-data-redis</artifactId>
	</dependency>

	<!-- redis依赖 -->
	<!-- <dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-data-redis</artifactId>
	</dependency> -->
	```
- 启动类加`@EnableRedisHttpSession(maxInactiveIntervalInSeconds = 7200)` (maxInactiveIntervalInSeconds即session检测的最大时间间隔)
- 可将一个项目启动两个端口进行测试

## 其他

### 替换项目运行时springboot的logo

- 在`resources`添加`banner.txt`文件. 内容自定义(文字转字符：http://patorjk.com/software/taag/)，如：

	```html


	 .oooo.    .ooooo.    oooooooo  .ooooo.   .ooooo.  ooo. .oo.   
	`P  )88b  d88' `88b  d'""7d8P  d88' `88b d88' `"Y8 `888P"Y88b  
	 .oP"888  888ooo888    .d8P'   888   888 888        888   888  
	d8(  888  888    .o  .d8P'  .P 888   888 888   .o8  888   888  
	`Y888""8o `Y8bod8P' d8888888P  `Y8bod8P' `Y8bod8P' o888o o888o



	```





---
[^1]: [h2介绍](http://412887952-qq-com.iteye.com/blog/2322756)
[^2]: [idea连接h2](https://stackoverflow.com/questions/31498682/spring-boot-intellij-embedded-database-headache)
[^3]: [spring-boot文件上传](http://blog.csdn.net/coding13/article/details/54577076)
[^6]: [Springboot中mongodb的使用](http://www.cnblogs.com/ityouknow/p/6828919.html)
[^7]: [Spring在代码中获取bean的几种方式](http://www.cnblogs.com/yjbjingcha/p/6752265.html)
[^8]: [异步调用Async](http://blog.csdn.net/v2sking/article/details/72795742)
[^9]: [Spring对CORS的支持](https://spring.io/blog/2015/06/08/cors-support-in-spring-framework)