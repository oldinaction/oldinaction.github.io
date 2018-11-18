---
layout: "post"
title: "springboot"
date: "2017-07-23 15:05"
categories: java
tags: springboot
---

## TODO

[+] Lombok使用 https://www.cnblogs.com/qnight/p/8997493.html
[+] 分布式限流 http://blog.battcn.com/2018/08/08/springboot/v2-cache-redislimter/
[+] Quartz实现动态配置定时任务 https://yq.aliyun.com/articles/626199

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

	<build>
		<plugins>
			<!-- springboot打成jar包可直接运行。会在MANIFEST.MF文件中添加Main-Class信息，否则报错：没有主清单属性 -->
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>
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

### 日志策略

- `application.properties`配置`logging.file=./logs/info.log`（所以配置可在application配置文件中完成，且此方法会在运行目录生成一个`LOG_PATH_IS_UNDEFINED`的文件，并存同时储日志文件，不推荐）
- `application.properties`配置`logging.config=classpath:logback.xml`，然后再`resource`目录加文件`（此时日志策略按照此配置文件）。参考配置文件[/data/src/java/logback.xml](/data/src/java/logback.xml)和表结构文件[/data/src/java/logback.xml](/data/src/java/logback.sql)
- logback默认会创建一个`/tmp/spring.log`的文件，而且只有使用root用户运行项目才可以创建此目录

### 随应用启动而运行(实现`CommandLineRunner`接口)

- 读取resources目录下配置文件

	```java
	@Component
	@Order(value = 1) // @Order值越小越优先
	public class HelpStartupRunner implements CommandLineRunner {
		@Value("${help.imageUploadRoot}")
		String imageUploadRoot;

		@Override
		public void run(String... args) throws Exception {
			// 读取失败
			// this.getClass().getResource("/service.json").getPath()
			// Resources[] resources = applicationContext.getResources("classpath*:**/test/*.json");
			// Resource resources = applicationContext.getResource("classpath:service.json");
			// 读取resources目录下配置文件
			InputStream in = this.getClass().getResourceAsStream("/service.json");

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

### 拦截器

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

### 获取Bean：此处选择实现`ApplicationContextAware`接口 [^7]

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

	// 获取applicationContext
	public static ApplicationContext getApplicationContext() {
		return applicationContext;
	}

	// 通过name获取 Bean
	public static Object getBean(String name){
		return getApplicationContext().getBean(name);
	}

	// 通过class获取Bean
	public static <T> T getBean(Class<T> clazz){
		return getApplicationContext().getBean(clazz);
	}

	// 通过name以及Clazz返回指定的Bean
	public static <T> T getBean(String name,Class<T> clazz){
		return getApplicationContext().getBean(name, clazz);
	}
}
```

### 异步执行服务 [^8]

- 启动类加注解`@EnableAsync`
- 服务类方法加注解`@Async`

### `@Value`给静态成员设值

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
public void setHello(String hello) {
	this.hello = hello;
}
```

### `@Autowired`注入给静态属性

```java
@Component
public class BaseController {
	private static Logger logger = LoggerFactory.getLogger(BaseController.class);

	private static CustomObjectMapper customObjectMapper;

	public BaseController() {}

	@Autowired // 类加载时调用此构造方法并赋值给静态属性
	public BaseController(CustomObjectMapper customObjectMapper) {
		BaseController.customObjectMapper = customObjectMapper;
	}
}
```

### 跨域资源共享（CORS）[^9]

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

### 国际化

- 在resources目录增加两个properties文件：`messages.properties`(默认)、`messages_zh_CN.properties`(中文)
- 配置文件中添加`spring.messages.basename=i18n/messages`
	- 可通过`spring.messages.basename=i18n/messages`定义配置文件路径，此时应该将`messages.*`放在`resources/i18n`目录
- 在其中加入类似配置`error.unknown_exception=未知错误`
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

### 全局错误处理

```java
@RestController // 包含@ResponseBody
@ControllerAdvice // 和@ExceptionHandler联用进行control层错误处理
// 继承BasicErrorControllers是处理进入control层之前发生的异常，需要重写error、errorHtml两个方法
public class GlobalExceptionHandlerController extends BasicErrorController {
    private Logger logger = LoggerFactory.getLogger(GlobalExceptionHandlerController.class);

    @Autowired
    private MessageSource messageSource;

    @Autowired
    private Environment env;

	// 自定义的com.fasterxml.jackson.databind.ObjectMapper用于返回数据格式化
    @Autowired
    private CustomObjectMapper customObjectMapper;

    public GlobalExceptionHandlerController() {
        super(new DefaultErrorAttributes(), new ErrorProperties());
    }

    // 错误映射为json，Accept-Type为application/json的
    @RequestMapping(produces = {MediaType.APPLICATION_JSON_VALUE})
    public ResponseEntity<Map<String, Object>> error(HttpServletRequest request) {
        Map<String, Object> body = MiscU.Instance.toMap();
        HttpStatus status = getStatus(request);

        try {
            ServletRequestAttributes requestAttributes = new ServletRequestAttributes(request);
            Throwable throwable = getError(requestAttributes);
            if(throwable == null) {
                throwable = new ExceptionU.UnknownException("Throwable Capture Failed");
                status = HttpStatus.INTERNAL_SERVER_ERROR;
            }

            Result result = this.unknownException(throwable);
            String str = customObjectMapper.writeValueAsString(result);
            body = JsonU.json2map(str);
        } catch (Exception e) {
            logger.error("Failed to return error message", e);
        }

        return new ResponseEntity<>(body, status);
    }

    // 错误映射到Html，Accept-Type为text/html的
    @RequestMapping(produces = {"text/html"})
    public ModelAndView errorHtml(HttpServletRequest request, HttpServletResponse response) {
        return super.errorHtml(request, response);
    }

    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    @ExceptionHandler(Exception.class)
    public Result exception(Throwable e) {
        return getExceptionResponse(ErrorType.EXCEPTION_ERROR, e);
    }

    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    @ExceptionHandler(ExceptionU.UnknownException.class) // 捕获ExceptionU.UnknownException异常
    public Result unknownException(Throwable e) {
        return getExceptionResponse(ErrorType.UNKNOWN_EXCEPTION_ERROR, e);
    }

    private Result getExceptionResponse(ErrorType errorType, Throwable e) {
        ExceptionInfo exceptionInfo = new ExceptionInfo();

		// 获取i18n错误信息
        String localMessage = getLocalMessage(errorType);
        String exceptionMessage = e.getMessage();
        StackTraceElement[] stackTrace = e.getStackTrace();
		
		// 正式环境则不显示错误堆栈信息
        String[] actives = env.getActiveProfiles();
        if (actives == null || actives.length <= 0 || !"prod".equals(actives[0])) {
            if (StringUtils.isNotEmpty(localMessage)) {
                exceptionInfo.setLocalMessage(localMessage);
            }
            if (StringUtils.isNotEmpty(exceptionMessage)) {
                exceptionInfo.setExceptionMessage(exceptionMessage);
            }
            if (stackTrace != null) {
                exceptionInfo.setStackTrace(stackTrace);
            }
        } else if (e instanceof ExceptionU) {
            if (StringUtils.isNotEmpty(exceptionMessage)) {
                exceptionInfo.setExceptionMessage(exceptionMessage);
            }
        }

        logger.error(StringU.buffer(", ", errorType.getErrorCode(), errorType.getMessage(), localMessage), e);

		// Result是定义的一个通用错误信息bean
        return new Result().failure(errorType.getMessage(), exceptionInfo);
    }

	// 获取i18n错误信息
    private String getLocalMessage(ErrorType errorType) {
        String localMessage = null;
        Locale locale = null;
        try {
            locale = LocaleContextHolder.getLocale();
            localMessage = messageSource.getMessage(errorType.getErrorCode(), null, locale);
        } catch (NoSuchMessageException e1) {
            logger.warn("invalid i18n! errorCode: " + errorType.getErrorCode() + ", local: " + locale);
        }

        return localMessage;
    }

	// 获取错误对象
    public Throwable getError(RequestAttributes requestAttributes) {
        Throwable exception = (Throwable) requestAttributes.getAttribute(DefaultErrorAttributes.class.getName() + ".ERROR", 0);
        if(exception == null) {
            exception = (Throwable) requestAttributes.getAttribute("javax.servlet.error.exception", 0);
        }

        return exception;
    }

    public class ExceptionInfo {
        private String localMessage;

        private String exceptionMessage;

        private StackTraceElement[] stackTrace;

		// getter/setter ...
    }
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

request-method |content-type   |postman   |springboot   |说明
--|---|---|---|---
post |application/json   |row-json   |(@RequestBody User user)   |如果后台使用了@RequestBody，此时row-text等都无法请求到
post |multipart/form-data  |form-data   |(HttpServletRequest request, User user, @RequestParam("hello") String hello)   |参考实例1。可进行文件上传(包含参数)

- `'content-type': 'multipart/form-data;`(postman对应form-data)：可进行文件上传(包含参数), 响应代码如：
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

### 请求参数

```java
// 如果所在类加注解@RequestMapping("/user")，则请求url全部要拼上`/user`，如`/user/getUser`

@RequestMapping(value = "/hello") // 前台post请求也可以请求的到
public String hello() {
	return "hello world";
}

// 前台请求 Body/Url 中含参数 userId和username（Spring可以自动注入java基础数据类型和对应的数组，集合无法注入）
@RequestMapping(value="/getUserByUserIdOrUsername")
public Result getUserByUserIdOrUsername(Long userId, String username) {
	// ...
	return new Result().success(); // 自己封装的Result对象
}
// 前台请求 Body/Url 中含参数 username
@RequestMapping(value="/getUserByName")
public Result getUserByName(@RequestParam("username") String name) {
	// ...
	return new Result().success();
}
@RequestMapping(value = "/getUser")
public Result getUser(User user) {// 此时User对象必须声明getter/setter方法
	// ...
	return new Result().success(); // 自己封装的Result对象
}

// @PathVariable 获取 url 中的参数
@RequestMapping(value="/hello/{id}")
public String user(@PathVariable("id") Integer id) {
	return "id:" + id;
}

@RequestMapping(value = "/addUser", method = RequestMethod.POST)
public Result hello(User user) {
	// ...
	return new Result().success();
}
```

### 前端数组/对象处理

- json字符串传输：前端通过`JSON.stringify`转成json字符串，然后后台JSONObject等转成Bean/Map等
- Spring的Bean自动注入
	- 请求类型 `POST`、`Content-Type: application/x-www-form-urlencoded`
	- chrome开发模式看到的`FormData`(格式化后的。实际请求是将每一项通过`URL encoded`进行转义之后再已`&`连接组装成url参数，此时POST参数是没有长度限制的)如：
		
		```js
		id: 766706
		customerNameCn: 客户名称
		updateTm: 2018/08/17 13:02:36
		customerLines[0]: AustraliaLine
		customerLines[1]: MediterraneanLine
		customerLines[2]: SoutheastAsianLine
		customerRisk.id: 9906
		customerRisk.customerId: 766706
		customerRisk.note: 客户风险备注
		customerContacts[0].id: 767001
		customerContacts[0].customerId: 766706
		customerContacts[0].lastName: 客户联系人1
		customerContacts[0].customerId: 766706
		customerContacts[0].lastName: 客户联系人2
		```
	- 后端写好对应的Bean(CustomerInfo)
		- CustomerInfo中的属性customerLines可以是List<String>或者String[]
		- CustomerInfo中的updateTm属性可以是Date(会自动转换)
		- CustomerInfo中包含CustomerRisk和List<CustomerContacts>

### 响应

- `@ResponseBody`
	- 表示以json返回数据
	- 定义在类名上，表示所有的方法都是`@ResponseBody`的，也可单独定义在方法上
- `@RestController`中包含`@ResponseBody`

### restTemplate

```java
@Autowired
RestTemplate restTemplate; // 无需手动引入

// （1） getForEntity
ResponseEntity<Map> responseEntity = restTemplate.getForEntity("http://localhost/list", Map.class);
HttpHeaders headers = responseEntity.getHeaders();
HttpStatus statusCode = responseEntity.getStatusCode();
int code = statusCode.value();
Map map = responseEntity.getBody();

// （2） getForObject
Video video = restTemplate.getForObject("http://localhost/video", Video.class);

// （3） postForEntity
Video video = new Video();
ResponseEntity<Video> responseEntity = restTemplate.postForEntity("http://localhost/video", video, Video.class);
video = responseEntity.getBody();
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
		# 默认驱动是mysql，但是如果使用oracle需要指明驱动(oracle.jdbc.driver.OracleDriver)，否则打包后运行出错
		spring.datasource.driver-class-name=com.mysql.jdbc.Driver
		spring.datasource.url=jdbc:mysql://localhost/springboot?useUnicode=true&characterEncoding=utf-8
		spring.datasource.username=root
		spring.datasource.password=root
		# springboot连接池默认使用的是tomcat-jdbc-pool，在处理utf8mb4类型数据(Emoji表情、生僻汉字。uft8默认只能存储1-3个字节的汉字，上述是4个字节)的时候，需要大致两步
			# 1.设置数据库、表、字段的编码类型为utf8mb4
			# 2.在创建数据库连接之后，要执行一条sql语句 "SET NAMES utf8mb4 COLLATE utf8mb4_general_ci"，这样的数据库连接才可以操作utf8mb4类型的数据的存取
		spring.datasource.tomcat.initSQL=SET NAMES utf8mb4 COLLATE utf8mb4_general_ci

		# 每次启动都会执行, 且在hibernate建表语句之前执行
		# 若无此定义, springboot也会默认执行resources下的schema.sql(先)和data.sql(后)文件(如果存在)
		# 执行建表语句(也会执行插入等语句)
		spring.datasource.schema=classpath:schema.sql
		# 执行数据添加语句
		spring.datasource.data=classpath:data.sql
	```

### 对hibernate的默认支持(JPA)

参考：[http://blog.aezo.cn/2017/05/21/java/hibernate/](/_posts/java/hibernate)

### 整合mybatis

参考：[http://blog.aezo.cn/2017/05/22/java/mybatis/](/_posts/java/mybatis)

### 事物支持 [^10]

- `@Transactional` 注解对应的public类型函数. 一个带事物的方法调用了另外一个事物方法，第二个方法的事物默认无效(Propagation.REQUIRED)
- 如果事物比较复杂，如当涉及到多个数据源，可使用`@Transactional(value="transactionManagerPrimary")`定义个事物管理器transactionManagerPrimary
- 由于Spring事务管理是基于接口代理或动态字节码技术，通过AOP实施事务增强的。`@Transactional`注解只被应用到 public 可见度的方法上
- 默认遇到运行期异常(RuntimeException)会回滚，遇到捕获异常(Exception)时不回滚 
	- `@Transactional(rollbackFor=Exception.class)` 指定回滚，遇到异常Exception时回滚
	- `@Transactional(noRollbackFor = RuntimeException.class)` 指定不回滚
	- 基于服务的统一结果返回，无法回滚事物(类似ofbiz的服务引擎返回)：服务内部捕获了异常(Exception)，返回的是统一的对象(如自定义`Result`)
		- `TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();` 程序内部手动回滚。或者基于自定义注解统一回滚。或者手动抛出RuntimeException
- Spring的@Transactional自我调用问题：同一个类中的方法相互调用，被调用的方法`@Transactional`无效 [^12]
	- 通过BeanPostProcessor 在目标对象中注入代理对象
- 隔离级别`@Transactional(isolation = Isolation.DEFAULT)`：`org.springframework.transaction.annotation.Isolation`枚举类中定义了五个表示隔离级别的值。脏读取、重复读、幻读
	- `DEFAULT`：这是默认值，表示使用底层数据库的默认隔离级别。对大部分数据库而言，通常这值就是：READ_COMMITTED。
	- `READ_UNCOMMITTED`：该隔离级别表示一个事务可以读取另一个事务修改但还没有提交的数据。该级别不能防止脏读和不可重复读，因此很少使用该隔离级别。
	- `READ_COMMITTED`：该隔离级别表示一个事务只能读取另一个事务已经提交的数据。该级别可以防止脏读，这也是大多数情况下的推荐值。
	- `REPEATABLE_READ`：该隔离级别表示一个事务在整个过程中可以多次重复执行某个查询，并且每次返回的记录都相同。即使在多次查询之间有新增的数据满足该查询，这些新增的记录也会被忽略。该级别可以防止脏读和不可重复读。
	- `SERIALIZABLE`：所有的事务依次逐个执行，这样事务之间就完全不可能产生干扰，也就是说，该级别可以防止脏读、不可重复读以及幻读。但是这将严重影响程序的性能。通常情况下也不会用到该级别。
- 传播行为`@Transactional(propagation = Propagation.REQUIRED)`：所谓事务的传播行为是指，如果在开始当前事务之前，一个事务上下文已经存在，此时有若干选项可以指定一个事务性方法的执行行为。`org.springframework.transaction.annotation.Propagation`枚举类中定义了6个表示传播行为的枚举值
	- `REQUIRED`：如果当前存在事务，则加入该事务；如果当前没有事务，则创建一个新的事务。
	- `SUPPORTS`：如果当前存在事务，则加入该事务；如果当前没有事务，则以非事务的方式继续运行。
	- `MANDATORY`：如果当前存在事务，则加入该事务；如果当前没有事务，则抛出异常。
	- `REQUIRES_NEW`：创建一个新的事务，如果当前存在事务，则把当前事务挂起。
	- `NOT_SUPPORTED`：以非事务方式运行，如果当前存在事务，则把当前事务挂起。
	- `NEVER`：以非事务方式运行，如果当前存在事务，则抛出异常。
	- `NESTED`：如果当前存在事务，则创建一个事务作为当前事务的嵌套事务来运行；如果当前没有事务，则该取值等价于REQUIRED。

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

### Spring Data Rest

> - 参考文档：https://springcloud.cc/spring-data-rest-zhcn.html 、 https://docs.spring.io/spring-data/rest/docs/3.1.0.RELEASE/reference/html/

> - 如何在返回数据的根节点插入一个属性(如code)？？？
> - 如何和swagger整合(整合2.9.2不显示方法)？？？

- Spring Data JPA是基于Spring Data的repository之上，可以将repository自动输出为REST资源。目前支持将Spring Data JPA、Spring Data MongoDB、Spring Data Neo4j等自动转换成REST服务
- 引入依赖(基于Spring JPA项目测试)

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-data-rest</artifactId>
</dependency>
<!-- 可选(不太好用)。HAL Browser：可直接测试API接口。访问 http://localhost:8080/api/ 即可看到 UI 界面(此时配置了rest根节点为 /api)。可使用POSTMAN代替 -->
<dependency>
	<groupId>org.springframework.data</groupId>
	<artifactId>spring-data-rest-hal-browser</artifactId>
</dependency>
```
- Repository `public interface PersonRepository extends JpaRepository<Person, Long> {}`
- 引入依赖后访问 `http://localhost:8080/persons` 即可看到返回(启动项目时也可以看到相应端点)

```js
// HAL（Hypertxt Application Language）风格REST。Spring Hateoas
// http://localhost:8080/persons
{
	_embedded: {
		persons: [{
				name: "smalle",
				age: 18,
				address: "上海",
				_links: {
					self: {
						href: "http://localhost:8080/persons/1"
					},
					person: {
						href: "http://localhost:8080/persons/1"
					}
				}
			},
			{
				name: "aezo",
				age: 20,
				address: "北京",
				_links: {
					self: {
						href: "http://localhost:8080/persons/2"
					},
					person: {
						href: "http://localhost:8080/persons/2"
					}
				}
			}
		]
	},
	_links: {
		self: {
			href: "http://localhost:8080/persons{?page,size,sort}",
			templated: true
		},
		profile: {
			href: "http://localhost:8080/profile/persons"
		}
	},
	page: {
		size: 20,
		totalElements: 2,
		totalPages: 1,
		number: 0
	}
}

// http://localhost:8080/persons/1
{
	name: "smalle",
	age: 18,
	address: "上海",
	_links: {
		self: {
			href: "http://localhost:8080/api/people/1"
		},
		person: {
			href: "http://localhost:8080/api/people/1"
		}
	}
}
```
- 扩展配置

```yml
spring:
  data:
	rest:
	  # 自定义根路径. 此时访问 http://localhost:8080/api/xxx
      base-path: /api
```

```java
@RepositoryRestResource(path = "people") // 修改默认的节点路径(实体名加s)。此时访问 http://localhost:8080/api/people
public interface PersonRepository extends JpaRepository<Person, Long> {
	@RestResource(path = "nameStartsWith") // 自定义服务暴露为REST资源，访问 http://localhost:8080/api/people/search/nameStartsWith?name=sma
	Person findByNameStartsWith(@Param("name") String name);
}
```
- 访问
	- 获取列表(GET) `http://localhost:8080/api/people`
	- 获取某个资源(GET) `http://localhost:8080/api/people/1`
	- 查询(GET) `http://localhost:8080/api/people/search/nameStartsWith?name=sma`
	- 分页排序(GET) `http://localhost:8080/api/people?page=1&size=2&sort=age,desc`
	- 保存(POST) `http://localhost:8080/api/people`
	- 更新(PUT) `http://localhost:8080/api/people/1`
	- 删除(DELETE) `http://localhost:8080/api/people/1`
- 在model的字段上加`@JsonIgnore`注解，Spring Data Rest会忽略此字段(结果中无此字段)
- 在model的字段上加`@JsonProperty("newName")`注解，可修改字段输出的名称
- `Projection`使用
```java
// (1) @Projection使用
// @Projection必须在domain(model)包或者自包才会被扫描到
@Projection(name="list", types=Person.class) // 基于Person实现一个投射(可以定义多个)，http://localhost:8080/api/people?projection=list
public interface ListPeople {
    // 此时只会返回id、name属性
    Long getId();

    String getName();

	// 自定义一个字段
    @Value("#{target.name}---#{target.age}") // 这里把Person中的name和age合并成一列，这里需要注意String getFullInfo();方法名前面一定要加get，不然无法序列化为JSON数据
    String getFullInfo();
}

// (2) @Projection定义的数据格式还可以直接配置到Repository之上，配置之后返回的JSON数据会按照 ListPeople 定义的数据格式进行输出
@RepositoryRestResource(path="people", excerptProjection=ListPeople.class)
public interface UserRepository extends JpaRepository<User, Long>{}

// (3) 获取关联实体信息
// # 1
@Entity
public class Card {
    @Id
    @GeneratedValue
    private Long id;

    private String cardNo;

    private Date expirationDate;

    @OneToOne // 必须有关联关系才可以获取到关联对象
    private Person person;

	// ... 省略get/set
}
// # 2
@Projection(name="list", types=Card.class)
public interface ListCard {
    String getCardNo();
    Person getPerson();
}
// # 3
@RepositoryRestResource(excerptProjection = ListCard.class) // http://localhost:8080/api/cards 此时可以获取到Person信息，无此注解默认无法获取
public interface CardRepository extends JpaRepository<Card, Long>  {}
```
- Spring Data Rest Events 提供了AOP方式的开发，定义了10种不同事件
	- 资源保存前 @HandleBeforeCreate
	- 资源保存后 @HandleAfterCreate
	- 资源更新前 @HandleBeforeSave
	- 资源更新后 @HandleAfterSave
	- 资源删除前 @HandleBeforeDelete
	- 资源删除后 @HandleAfterDelete
	- 关系创建前 @HandleBeforeLinkSave
	- 关系创建后 @HandleAfterLinkSave
	- 关系删除前 @HandleBeforeLinkDelete
	- 关系删除后 @HandleAfterLinkDelete
- 结合Spring Security

```java
@PreAuthorize("hasRole('ROLE_USER')") 
public interface PreAuthorizedOrderRepository extends CrudRepository<Order, UUID> {

	@PreAuthorize("hasRole('ROLE_ADMIN')") 
	@Override
	void deleteById(UUID aLong);
}
```

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
	#	# 将thymeleaf的html格式文件放在resources/templates/目录，则不需要配置下列两行
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

				// return "/hello"; // 加上/后，打成jar包路径找不到。可以去掉/或者使用return new ModelAndView("hello");
				return "hello";
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
- thymeleaf语法：[http://blog.aezo.cn/2017/10/22/lang/thymeleaf/](/_posts/lang/thymeleaf.md)

### 文件上传下载

- 上传文件临时目录
	- 项目启动默认会产生一个tomcat上传文件临时目录，如：`/tmp/tomcat.4234211497561321585.8080/work/Tomcat/localhost/ROOT`
	- 而linux会定期清除tmp目录下文件，尽管项目仍然处于启动状态。从而会导致错误`Caused by: java.io.IOException: The temporary upload location [/tmp/tomcat.4234211497561321585.8080/work/Tomcat/localhost/ROOT] is not valid`

```java
// 自定义上传文件临时目录
@Bean 
public MultipartConfigElement multipartConfigElement() {
	MultipartConfigFactory factory = new MultipartConfigFactory();  
	factory.setLocation("/app/tmp");
	return factory.createMultipartConfig();
}
```

## 企业级开发

### Nosql

#### 整合redis

参考《redis》[http://blog.aezo.cn/2016/07/02/db/redis/](/_posts/db/redis)

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

### WebSocket [^11]

- 引入依赖

    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-websocket</artifactId>
    </dependency>
    ```
- 后端代码

```java
// 1.WebSocketConfig.java 配置文件
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig extends AbstractWebSocketMessageBrokerConfigurer {
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/user"); // 表示客户端订阅地址的前缀信息，也就是客户端接收服务端消息的地址的前缀信息
        config.setApplicationDestinationPrefixes("/app"); // 定义websocket前缀，指服务端接收地址的前缀，意思就是说客户端给服务端发消息的地址的前缀
        config.setUserDestinationPrefix("/user"); // 定义一对一(点对点)推送前缀，默认是`/user`，可省略此配置
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/aezo") // 定义stomp端点，供客户端使用
                .setAllowedOrigins("*")
                .withSockJS(); // 开启SockJS支持
    }
}

// 2.@Controller
@Autowired
private SimpMessagingTemplate simpMessagingTemplate; // Spring-WebSocket内置的一个消息发送工具，可以将消息发送到指定的客户端或所有客户端

@GetMapping("/")
public String index() {
    return "index";
}

// 功能类似@RequestMapping，定义消息的基本请求(客户端发送消息)。拼上定义的客户端请求的前缀/app，最终客户端请求为/app/send
@MessageMapping("/send")
// @SendTo发送消息给所有人，@SendToUser只能推送给请求消息的那个人
@SendTo("/topic/send")
public Message send(Message message) throws Exception { // Message为一个VO(不写getter/setter也行)
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    message.date = df.format(new Date());
    if(message.toUser != null && !"".equals(message.toUser)) {
        // 给某个人发送消息，此时@SendTo被忽略
        // convertAndSend(destination, payload); //将消息广播到特定订阅路径中，类似@SendTo
        // convertAndSendToUser(user, destination, payload); //将消息推送到固定的用户订阅路径中，类似@SendToUser
        simpMessagingTemplate.convertAndSendToUser(message.toUser, "/private", message); // 发送到/user/${message.toUser}/private通道
        return null;
    } else {
        return message;
    }
}

// 定时1秒执行执行一次，向/topic/callback通道发送信息
@Scheduled(fixedRate = 1000) // 加@EnableScheduling开启定时
@SendTo("/topic/callback")
public Object callback() throws Exception {
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    simpMessagingTemplate.convertAndSend("/topic/callback", df.format(new Date()));
    return "callback"; // 此处返回什么不重要
}
```
- 前端代码(基于angular.js)

```html
<!-- 基于angular.js -->
<script src="//cdn.bootcss.com/angular.js/1.5.6/angular.min.js"></script>

<!-- websocket所需js库 -->
<script src="https://cdn.bootcss.com/sockjs-client/1.1.4/sockjs.min.js"></script>
<script src="https://cdn.bootcss.com/stomp.js/2.3.3/stomp.min.js"></script>
<script type="text/javascript">
var stompClient = null;
var app = angular.module('app', []);
app.controller('MainController', function($rootScope, $scope, $http) {
	$scope.data = {
		username: '', // 用户名
		toUser: '',
		connected : false, //连接状态
		message : '', //消息
		rows : [] // 消息历史
	};

	//连接
	$scope.connect = function() {
		var socket = new SockJS('/ws/aezo'); // websocket后台定义的stomp端点
		stompClient = Stomp.over(socket);
		stompClient.connect({}, function(frame) {
			// 注册发送消息
			stompClient.subscribe('/topic/send', function(msg) {
				$scope.data.rows.push(JSON.parse(msg.body));
				$scope.data.connected = true;
				$scope.$apply();
			});
			// 注册推送时间回调
			stompClient.subscribe('/topic/callback', function(r) {
				$scope.data.time = '当前服务器时间：' + r.body;
				$scope.data.connected = true;
				$scope.$apply();
			});
			// 注册接受私信
			stompClient.subscribe('/user/'+ $scope.data.username +'/private', function(msg) {
				$scope.data.rows.push(JSON.parse(msg.body));
				$scope.data.connected = true;
				$scope.$apply();
			});

			$scope.data.connected = true;
			$scope.$apply();
		});
	};

	// 断开连接
	$scope.disconnect = function() {
		if (stompClient != null) {
			stompClient.disconnect();
		}
		$scope.data.connected = false;
	}

	// 发送消息
	$scope.send = function() {
		stompClient.send("/app/send", {}, JSON.stringify({
			'toUser': $scope.data.toUser,
			'message': $scope.data.message
		}));
	}
});
</script>
```

### 多数据源

http://blog.didispace.com/springbootmultidatasource/

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

### 整合swagger

参考[/_posts/arch/swagger.md#springboot中使用](/_posts/arch/swagger.md#springboot中使用)

## 其他

### 测试

- 多线程测试(基于Junit+[GroboUtils](http://groboutils.sourceforge.net/))
	- 安装依赖

		```xml
		<!-- 第三方库 -->
		<repositories>
			<repository>
				<id>opensymphony-releases</id>
				<name>Repository Opensymphony Releases</name>
				<url>https://oss.sonatype.org/content/repositories/opensymphony-releases</url>
			</repository> 
		</repositories>
		
		<dependency> 
			<groupId>net.sourceforge.groboutils</groupId> 
			<artifactId>groboutils-core</artifactId> 
			<version>5</version> 
		</dependency>
		```
	- 使用

		```java
		@Test 
		public void multiRequestsTest() { 
			// 构造一个Runner 
			TestRunnable runner = new TestRunnable() { 
				@Override 
				public void runTest() throws Throwable { 
					// TODO 测试内容
				} 
			};

			int runnerCount = 100; 
			// Runner数组，想当于并发多少个。 
			TestRunnable[] arrTestRunner = new TestRunnable[runnerCount]; 
			for (int i = 0; i < runnerCount; i++) { 
				arrTestRunner[i] = runner; 
			} 

			// 用于执行多线程测试用例的Runner，将前面定义的单个Runner组成的数组传入 
			MultiThreadedTestRunner mttr = new MultiThreadedTestRunner(arrTestRunner); 
			try { 
				// 开发并发执行数组里定义的内容 
				mttr.runTestRunnables(); 
			} catch (Throwable e) { 
				e.printStackTrace(); 
			} 
		}
		```


### 替换项目运行时springboot的logo

- 在`resources`添加`banner.txt`文件. 内容自定义(文字转字符：http://patorjk.com/software/taag/)，如：

	```html
	 .oooo.    .ooooo.    oooooooo  .ooooo.   .ooooo.  ooo. .oo.   
	`P  )88b  d88' `88b  d'""7d8P  d88' `88b d88' `"Y8 `888P"Y88b  
	 .oP"888  888ooo888    .d8P'   888   888 888        888   888  
	d8(  888  888    .o  .d8P'  .P 888   888 888   .o8  888   888  
	`Y888""8o `Y8bod8P' d8888888P  `Y8bod8P' `Y8bod8P' o888o o888o
	```

### 打包成exe

- 使用`exe4j`打包成exe，常用配置选择 [^13]
	- `2.Project Type`：jar in exe mode
	- `4.Executable info - 32-bit or 64-bit`：生成exe的版本
	- `5.Java invocation`：class path中添加springboot生成的jar(可通过java -jar正常运行)的相对路径(基于.exe4j配置文件; exe4j v6.0此处无法选择，只能手输)；main class from填写`org.springframework.boot.loader.JarLauncher`
	- `6.JRE`：添加Directory目录为jre的路径，最好为相对路径，如`./jre`，此步骤并不会吧jre打包到exe中，只会设置exe寻找jre的路径。之后需要将jre和exe文件放在一起打包给用户
	- 给用户提供配置文件，如可执行文件为`myexe.exe`，则在此可执行文件目录创建`myexe.exe.vmoptions`文件，里面加入JVM参数(如：`-Xms256m`)或自定义参数(如：`-DmyValue.val=123456`，其中`myValue.val`是通过`@ConfigurationProperties`定义的参数)，一行一个参数，参数值如果为路径也支持`\`
- 使用[InnoSetup](http://www.jrsoftware.org/isdl.php)打成可安装程序(打包后大概80M)
	- File - New - 跟随提示进行配置。
		- Application Files配置：Application main executable file选择exe4j生成的exe文件；
		- other application files(添加其他依赖文件)
			- add folder：选择jre目录(如果上面exe4j第6步填写的是`./jre`，则此处还需要给jre外面包裹一层文件夹如jre-home，然后此处选择jre-home路径即可。最终会jre目录和exe4j生成的exe文件仍然处于同级目录。因此可以将exe4j第6步设置成`.`，则最终可以去掉`jre`这层目录)
			- add files：选择上述`*.vmoptions`

## 常见错误

- `nested exception is java.lang.IllegalArgumentException: Could not resolve placeholder 'crm.tempFolder' in value "${crm.tempFolder}"`
	- 原因分析：一般由于存在多个`application`配置文件，然后并没有指定。则使用默认配置，运行时出现`No active profile set, falling back to default profiles: default`，从而缺少部分配置。实践时发现application.properties中已经配置了`spring.profiles.active=dev`，再idea中通过main方法启动时不报错，但是通过maven打包是测试不通过
	- 解决办法参考：[《maven.md#结合springboot》](/_posts/arch/maven.md#结合springboot)。实际中主要是没有将`src/main/resources`目录添加到maven的resource中

## springboot 2.0.1 改动

- jpa

```java
// 获取单条记录
// spring boot 1.4.3
// User user = this.userRepositroy.findOne(id);
// spring boot 2.0.1
User user = this.userRepositroy.findById(id).get();
```



---

参考文章

[^1]: http://412887952-qq-com.iteye.com/blog/2322756 (h2介绍)
[^2]: https://stackoverflow.com/questions/31498682/spring-boot-intellij-embedded-database-headache (idea连接h2)
[^3]: http://blog.csdn.net/coding13/article/details/54577076 (spring-boot文件上传)
[^6]: http://www.cnblogs.com/ityouknow/p/6828919.html (Springboot中mongodb的使用)
[^7]: http://www.cnblogs.com/yjbjingcha/p/6752265.html (Spring在代码中获取bean的几种方式)
[^8]: http://blog.csdn.net/v2sking/article/details/72795742 (异步调用Async)
[^9]: https://spring.io/blog/2015/06/08/cors-support-in-spring-framework (Spring对CORS的支持)
[^10]: http://blog.didispace.com/springboottransactional/ (@Transactional)
[^11]: http://www.cnblogs.com/GoodHelper/p/7078381.html (WebSocket)
[^12]: http://tech.lede.com/2017/02/06/rd/server/SpringTransactional/ (Spring @Transactional原理及使用)
[^13]: https://blog.csdn.net/qq_35542689/article/details/81205472 (springboot在Windows(无jre)下打包并运行exe)