---
layout: "post"
title: "SpringBoot"
date: "2017-07-23 15:05"
categories: java
tags: spring
---

## TODO

[+] Lombok使用 https://www.cnblogs.com/qnight/p/8997493.html
[+] 分布式限流 http://blog.battcn.com/2018/08/08/springboot/v2-cache-redislimter/
[+] Quartz实现动态配置定时任务 https://yq.aliyun.com/articles/626199

## 简介

- [Docs](https://docs.spring.io/spring-boot/docs/)
- IDEA使用Spring initializr 创建SpringBoot项目超时，可以使用`https://start.aliyun.com`的镜像

## 版本说明

- https://docs.spring.io/spring-boot/docs/{verion}/reference/htmlsingle/ 文档中 `System Requirements`描述了对环境的要求
- `Spring Boot 1.2.1-`，使用`Spring Framework 4.1.3`，要求`Java 6` 和 `maven 3.2+`
- `Spring Boot 1.5.x`，使用`Spring Framework 4.3.12.RELEASE`，要求 `Java 7` 和 `maven 3.2+`
- `Spring Boot 2.0.x`，使用`Spring Framework 5.0.x.RELEASE`，要求 `Java 8 or 9` 和 `maven 3.2+`

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
	- 外部配置：`java -jar aezocn.jar --spring.profiles.active=prod` (profile 也可以激活多个)
	- 配置文件：`spring.profiles.active=dev` 代表使用application-dev.properties的配置文件(在application.properties中添加此配置)
- 可以idea中修改默认profiles或者某些配置达到运行多个实例的目的
- 配置示例

	```yml
	server:
		port: 9000
	spring:
		# 存放授权客户端信息
		datasource:
			# MYSQL_HOST为环境变量，如果无则取默认值localhost
			url: jdbc:mysql://${MYSQL_HOST:localhost}:${MYSQL_TCP_PORT:3306}/${MYSQL_DATABASE:test}?useUnicode=true&characterEncoding=utf-8
	logging:
		level: # 设置日志级别
			- org.springframework.security: DEBUG
	```
- `application.yml`单文件中配置多环境

	```yml
	# 默认
	server:
		port: 9000
	
	---
	spring:
		# 设置启动参数spring.profiles.active=dev即可覆盖上面默认配置
		profiles: dev
	server:
		port: 9001
	
	---
	spring:
		profiles: prod
	server:
		port: 9002
	```

## 常用配置

### 日志策略

- application.yml配置

```yml
# 最简单的日志打印只需再resource目录加入logback.xml/logback-spring.xml即可，无需下列logging节点配置。其他说明：
# 1. 文件的命名和加载顺序有关：logback.xml早于application.yml加载，logback-spring.xml晚于application.yml加载；如果logback配置需要使用application.yml中的属性，需要命名为logback-spring.xml
# 2. logback使用application.yml中的属性：必须通过springProperty才可引入application.yml中的值，可以设置默认值
logging:
	# 日志文件保存位置(会自动创建目录). 如果未找到path则不生成日志文件(linux默认是/tem/spring.log)，path有值时后自动在目录生成spring.log的文件(日志级别全部在一起)。如果使用默认路径则无需此配置
	path: ${LOG_PATH:D:/temp/logs/test/module}
	# 基于xml文件可以将日志级别不同的生成到不同的文件中。如果日志配置文件为：resource/logback.xml；resource/logback-spring.xml；也可以自动识别环境，如logback-dev.xml，则无需此配置
    config: classpath:logback-test.xml

# 将mybatis的DEBUG日志记录在文件的前提是：(1)有对应的文件appender-ref (2)对应mapper设置的级别高于此处的默认级别
# 打印mybatis的sql语句，会覆盖logback.xml中的配置。logging.level 不支持通配符
logging.level.cn.aezo.test.mapper: DEBUG
logging:
    level:
        cn.aezo.test.mapper: DEBUG

# 打印mybatis的sql语句时需要，或者加在mybatis-config.xml中
mybatis:
  configuration:
    log-impl: org.apache.ibatis.logging.slf4j.Slf4jImpl
```
- 文件的命名和加载顺序有关：logback.xml早于application.yml加载，logback-spring.xml晚于application.yml加载；如果logback配置需要使用application.yml中的属性，需要命名为logback-spring.xml
- 参考配置文件[/data/src/java/logback-spring.xml](/data/src/java/logback-spring.xml)。如果保存在数据库中时，表结构文件[/data/src/java/logback.sql](/data/src/java/logback.sql)
- springboot的日志配置文件`<include resource="org/springframework/boot/logging/logback/base.xml"/>`。里面包含一下参数，表示为配置LOG_PATH等环境变量时，在linux环境下会自动创建`/tmp/spring.log`文件作为日志输出文件，而/tmp目录一般只有使用root用户运行项目才可以创建此文件
    
    ```xml
    <property name="LOG_FILE" value="${LOG_FILE:-${LOG_PATH:-${LOG_TEMP:-${java.io.tmpdir:-/tmp}}}/spring.log}"/>
    ```
- `System.getproperty("java.io.tmpdir")`可获取操作系统缓存的临时目录。不同操作系统的缓存临时目录不一样，Linux：`/tmp`，Windows如：`C:\Users\smalle\AppData\Local\Temp\`

### 随应用启动而运行(实现`CommandLineRunner`接口)

- 读取resources目录下配置文件

	```java
	@Component
	@Order(value = 1) // @Order值越小越优先
	public class StartupRunner implements CommandLineRunner {
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

- 参考[spring.md#拦截器](/_posts/java/spring.md#拦截器)
    - 实现 Filter 或继承 OncePerRequestFilter，并增加注解@Component
    - 实现 WebMvcConfigurer 并暴露Bean，可指定拦截某路径和设定Order顺序
    - 往 FilterRegistrationBean 中注册并暴露Bean，可指定拦截某路径
    - 拦截request的body数据
    - 拦截response的数据

### 获取Bean [^7]

- 自动注入

```java
@Autowired
private ApplicationContext applicationContext;

public void test() {
	Mytest mytest = applicationContext.getBean(Mytest.class);
}
```
- 实现`ApplicationContextAware`接口
    - 下列工具相当于把`ApplicationContext`存储在属性中，其他类对象可通过此对象属性获取ApplicationContext
    - 上述其他类对象，如自行new的对象中需要注入其他Bean，此时当前类没有被Spring托管，则可通过SpringContextU中间缓存获取

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

- 启动类加注解`@EnableAsync`，服务类方法加注解`@Async`即可
- 可额外通过实现`AsyncConfigurer`配置`Executor`，参考[http://blog.aezo.cn/2017/07/01/java/spring/](/_posts/java/spring.md)

### @Value给静态成员设值

- 参考[属性赋值(@Value)](/_posts/java/spring.md#属性赋值(@Value))
- springboot v2.0.1之后，定义自定义参数(MyValue.java)要么写到Application.java同目录，要么加下列依赖。这个依赖会把配置文件的值注入到@Value里面，也可以通过@PropertySource("classpath:application.yml")注入

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-configuration-processor</artifactId>
	<optional>true</optional>
</dependency>
```
- 定义/调用
	- 命令行参数 > application.properties > JavaBean
	- 命令行参数设置了此属性配置，但属性的值为空。此时可以覆盖`application.properties`的初始值，但是不会覆盖JavaBean的初始值

```java
// ### 方法一
// 设值：在application.properties中设置`myValue.val`的值

// 取值
@Value("${myValue.val")
private String val = "smalle"; // 默认值。在命令行参数给此属性传入空时，此初始值不会被覆盖

private static String hello;

@Value("${myValue.hello}")
public void setHello(String h) {
	hello = h;
}

// 方法二：定义JavaBean
@Configuration
@ConfigurationProperties(prefix = "myValue")
public class MyValue {
	// ...Model：所有的属性、get、set方法
    private String val;

    private String hello;

    private Map<String, Object> extMap; // 如 myValue.extMap.a=1 和 myValue.extMap.b=2 可注入进来
}

// 取值
@Autowired
private MyValue myValue;
```

### @Autowired注入给静态属性

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

### 跨域资源共享(CORS) [^9]

- 参考[springboot解决跨域](/_posts/arch/springboot-vue.md#springboot解决跨域)
- 使用spring security时，需要同时在spring mvc 和 spring security中配置CORS

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

- 继承BasicErrorControllers是处理进入control层之前发生的异常(且需要有对应handler)，需要重写error、errorHtml两个方法
- @ControllerAdvice/@RestControllerAdvice和@ExceptionHandler联用进行control层错误处理
- Interceptor层异常
	- 方法@ExceptionHandler会处理所有Controller层抛出的Exception及其子类的异常，Controller层就不需要单独处理异常了。但如上代码只能处理 Controller 层的异常，对于未进入Controller的异常，如Interceptor（拦截器）层的异常，Spring 框架层的异常无效，还是会将错误直接返回给用户
	- SpringMVC是可以通过增加/error的handler来处理异常的，而REST却不行。因为在Spring REST中，当用户访问了一个不存在的链接时，Spring 默认会将页面重定向到`/error` 上，而不会抛出异常(error对应的视图就是常见的Whitelabel Error Page)
	- 处理方法是，在application.properties文件中，增加下面两项设置

		```yml
        spring.mvc.throw-exception-if-no-handler-found=true
        # 会导致后台映射的静态资源无效
		spring.resources.add-mappings=false
		```
- 继承BasicErrorControllers示例

```java
@RestControllerAdvice // 包含@RestController(包含@ResponseBody)和@ControllerAdvice
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
        return getExceptionResponse(ErrorType.EXCEPTION_ERROR, e); // 自定义异常类 ErrorType
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

### 请求参数字段映射

- 注意点
    - 原理参考：[spring-src.md#MVC请求参数解析](/_posts/java/spring-src.md#MVC请求参数解析)
    - **LocalDateTime 等类型日期时间格式转换** [^19] [^20]
        - Controller 接受参数加注解如 `@RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime date`。不适合参数通过 @RequestBody 修饰
        - Bean字段增加注解`@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")`。适用于 @RequestBody 接收(如 application/json 请求类型)；且适用于@RequestParam、直接通过Bean类型接收等方式(如 multipart/form-data 请求类型)
        - 如下文方案一自定义 ObjectMapper。只适用于 application/json(@RequestBody 接收) 请求方式
        - 如下文方案二注入Converter转换器。适用于@RequestParam、直接通过Bean类型接收等方式(如 multipart/form-data 请求类型)；不支持 @RequestBody
    - **在映射时对应第二个字母大写的驼峰容易出错**，如将xPoint映射成了xpoint。此为jackson的一个bug(v2.9.9) [^18]
    - 返回前端Long型丢失精度，JS支持的数字长度有限，示例参考下文 MappingJackson2HttpMessageConverter [^22]
- yaml配置方式`spring.jackson` [^17]
    - 同下文方案一，只适用于 @RequestBody
- JavaBean 方式

```java
// 情景一：只支持 POST application/json方式（请求参数通过 @RequestBody 修饰）
// 暴露自定义映射规则类
@Configuration
public class CustomObjectMapper extends ObjectMapper {
    private static final long serialVersionUID = 1L;
    private static final Locale CHINA = Locale.CHINA;

    public CustomObjectMapper() {
        super();

        // 设置地点为中国
        this.setLocale(CHINA);

        // 去掉默认的时间戳格式
        this.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);

        // 设置为中国上海时区
        this.setTimeZone(TimeZone.getTimeZone(ZoneId.systemDefault()));

        // 日期的统一格式，针对Bean字段类型为 Date 的格式化(如果是LocalDateTime等则参考下文)
        this.setDateFormat(new SimpleDateFormat(BaseConst.DATE_TIME_FORMAT, Locale.CHINA));

        // 日期格式化
        this.registerModule(new SqJavaTimeModule());
        this.findAndRegisterModules();

        // 忽略无法转换的对象
        this.configure(SerializationFeature.FAIL_ON_EMPTY_BEANS, false);
        // 对于非实体字段名的参数进行忽略，否则报错：Jackson with JSON: Unrecognized field
        this.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        // 反序列化时，属性不存在的兼容处理
        this.getDeserializationConfig().withoutFeatures(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);

        // 单引号处理
        this.configure(JsonParser.Feature.ALLOW_SINGLE_QUOTES, true);

        // 进行缩进输出
        this.configure(SerializationFeature.INDENT_OUTPUT, true);

        // 将驼峰转为下划线
        // this.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
        // 排除属性名为空(""/null)的字段
        // this.getSerializerProvider().setNullKeySerializer(new NullKeySerializer());
        // 排除值为空属性. [sq] 前端框架 avue 表单重新赋值时，无法用NULL KEY覆盖有值的属性，因此需要返回所有KEY
        // this.setSerializationInclusion(JsonInclude.Include.NON_NULL);
    }

    /**
     * LocalDateTime 转换参考<br/>
     * (1) Controller 接受参数加注解如 `@RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime date`<br/>
     * (2) 返回数据时，使用 MappingJackson2HttpMessageConverter 转换时，对于 LocalDateTime 等类型转换则必须如下配置。<br/>
     * 如果不使用 MappingJackson2HttpMessageConverter 可直接在DTO的字段上加如 @JsonFormat(pattern = "yyyy/MM/dd HH:mm:ss", timezone="GMT+8")<br/>
     *
     * @author smalle
     * @since 2020/12/15 21:07
     */
    private class SqJavaTimeModule extends SimpleModule {
        public SqJavaTimeModule () {
            // 返回数据格式化
            this.addSerializer(LocalDateTime.class, new LocalDateTimeSerializer(DateTimeFormatter.ofPattern(BaseConst.DATE_TIME_FORMAT)));
            this.addSerializer(LocalDate.class, new LocalDateSerializer(DateTimeFormatter.ofPattern(BaseConst.DATE_FORMAT)));
            this.addSerializer(LocalTime.class, new LocalTimeSerializer(DateTimeFormatter.ofPattern(BaseConst.TIME_FORMAT)));

            // 解析post请求的body体
            // ***iview的日前选择建议使用 :value 绑定(不要使用v-model)***，如 `<DatePicker type="date" :value="workLevelItem.startTm" @on-change="v => workLevelItem.startTm = v"></DatePicker>` 此时传入到后台的startTm格式即为日期字符串(v-model传入的为日期格式)
            this.addDeserializer(LocalDateTime.class, new LocalDateTimeDeserializer(DateTimeFormatter.ofPattern(BaseConst.DATE_TIME_FORMAT)));
            this.addDeserializer(LocalDate.class, new LocalDateDeserializer(DateTimeFormatter.ofPattern(BaseConst.DATE_FORMAT)));
            this.addDeserializer(LocalTime.class, new LocalTimeDeserializer(DateTimeFormatter.ofPattern(BaseConst.TIME_FORMAT)));
        }
    }

    private class NullKeySerializer extends JsonSerializer<Object> {
        @Override
        public void serialize(Object nullKey, JsonGenerator jsonGenerator, SerializerProvider unused) throws IOException {
            jsonGenerator.writeFieldName("");
        }
    }
}

@Bean
public MappingJackson2HttpMessageConverter mappingJackson2HttpMessageConverter(CustomObjectMapper customObjectMapper) {
    MappingJackson2HttpMessageConverter converter = new MappingJackson2HttpMessageConverter();
    // 可选。由于 MappingJackson2HttpMessageConverter 默认只支持 application/json(请求参数通过 @RequestBody 修饰)，如果浏览器请求时为application/json;charset=UTF-8则会转换问题，可增加支持的媒体类型进行解决。参考：https://blog.csdn.net/zw3413/article/details/85257270
    MediaType[] mediaTypes = new MediaType[]{MediaType.APPLICATION_JSON, MediaType.APPLICATION_JSON_UTF8};
    converter.setSupportedMediaTypes(Arrays.asList(mediaTypes));

    // 解决返回前端Long型丢失精度(js不支持Long型)
    SimpleModule simpleModule = new SimpleModule();
    simpleModule.addSerializer(BigInteger.class, ToStringSerializer.instance);
    simpleModule.addSerializer(Long.class, ToStringSerializer.instance);
    simpleModule.addSerializer(Long.TYPE, ToStringSerializer.instance);
    customObjectMapper.registerModule(simpleModule);

    converter.setObjectMapper(customObjectMapper);
    return converter;
}

// 情景二：注入Converter转换器。适用于@RequestParam、直接通过Bean类型接收等方式(如 multipart/form-data 请求类型)；不支持 @RequestBody
// StringToLocalDateTimeConverter 为手动转换类，实现 org.springframework.core.convert.converter.Converter<S,T> 接口
// 注入转换器方式一
@ControllerAdvice
public class ControllerHandler {
    @InitBinder
    public void initBinder(WebDataBinder binder) {
        GenericConversionService genericConversionService = (GenericConversionService) binder.getConversionService();
        genericConversionService.addConverter(new StringToLocalDateTimeConverter());
    }
}
// 如果需要转换成 LocalDate/LocalTime/Timestamp 需要另写
public static class StringToLocalDateTimeConverter implements Converter<String, LocalDateTime> {
    @Override
    public LocalDateTime convert(String source) {
        if (StringUtils.isEmpty(source)) {
            return null;
        }
        return DateUtil.parseLocalDateTime(source.trim());
        // return LocalDateTimeUtils.convert(source.trim()); // 或使用下文转换类
    }
}
// 注入转换器方式二
@Autowired
private RequestMappingHandlerAdapter handlerAdapter; // 如果程序中有注入 WebMvcConfigurer 则会报错(如上文跨域资源共享配置方式二)
@PostConstruct
public void initEditableAvlidation() {
    ConfigurableWebBindingInitializer initializer = (ConfigurableWebBindingInitializer) handlerAdapter.getWebBindingInitializer();
    if(initializer.getConversionService() != null) {
        GenericConversionService genericConversionService = (GenericConversionService)initializer.getConversionService();
        genericConversionService.addConverter(new StringToLocalDateTimeConverter());
    }
}
// 注入转换器方式三
@Configuration
public class MvcConfig implements WebMvcConfigurer {
    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addConverter(new StringToLocalDateTimeConverter());
    }
}
// 转换工具类（可使用 Hutool 的）。支持秒时间戳，毫秒时间戳，自定义时间格式yyyy-MM-dd HH:mm[:ss][.sss]，ISO标准时间yyyy-MM-ddTHH:mm[:ss][.sss]，UTC标准时间yyyy-MM-ddTHH:mm:ss[.sss]Z
public class LocalDateTimeUtils {
    private final static String REGEX_TIME = "^(\\d{10,13}|\\d{4}-\\d{2}-\\d{2}.\\d{2}:\\d{2}.*)$";

    public static LocalDateTime convert(String resolver) {
        if (Pattern.matches(REGEX_TIME, resolver)) {
            Instant instant;
            switch (resolver.length()) {
                case 10:
                    instant = Instant.ofEpochSecond(Long.parseLong(resolver));
                    return LocalDateTime.ofInstant(instant, ZoneId.of("GMT+8"));
                case 13:
                    instant = Instant.ofEpochMilli(Long.parseLong(resolver));
                    return LocalDateTime.ofInstant(instant, ZoneId.of("GMT+8"));
                default:
                    break;
            }

            if (resolver.endsWith("Z")) {
                return LocalDateTime.ofInstant(Instant.parse(resolver), ZoneId.of("GMT+8"));
            } else if (resolver.charAt(10) == 'T') {
                return LocalDateTime.parse(resolver, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            } else if (resolver.charAt(10) == ' ') {
                return LocalDateTime.parse(resolver, new DateTimeFormatterBuilder()
                    .parseCaseInsensitive()
                    .append(DateTimeFormatter.ISO_LOCAL_DATE)
                    .appendLiteral(' ')
                    .append(DateTimeFormatter.ISO_LOCAL_TIME)
                    .toFormatter());
            }
        }
        return null;
    }
}
```

### 文件上传下载配置

- 参考下文[文件上传下载](#文件上传下载)

### AOP

- 添加依赖

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```
- 示例参考【多数据源/动态数据源/运行时增加数据源】章节中的【动态数据源】

### spring.factories文件

- `spring.factories`主要为让Spring容器扫描配置文件中定义的类，默认只会扫描SpringBoot的启动类所在根目录及子目录，此方式主要加载第三方类库
- 案例

```bash
main
    java
        cn.aezo.test1
            test11
            # 启动类。启动后默认值只能扫描`cn.aezo.test1`包下的Bean
            TestApplication.java
        cn.aezo.test2
            # @Configuration配置类，默认无法被扫描到，因此也不会被Spring容器管理
            Test2Config.java
    resources
        META-INF
            # 方式一：定义额外需要扫码的类，从而让Test2Config也可以被扫描到，并加入到Spring容器
            # org.springframework.boot.autoconfigure.EnableAutoConfiguration=cn.aezo.test2.Test2Config
            # 方式二：在TestApplication类上加入`@Import(value={Test2Config.class})`，从而进行导入
            spring.factories
```
- `spring.factories`配置说明

```ini
# 导入第三方Bean
org.springframework.boot.autoconfigure.EnableAutoConfiguration=cn.aezo.test2.Test2Config
# 用于加载自定义配置路径文件[参考](#EnvironmentPostProcessor加载自定义配置路径文件)
org.springframework.boot.env.EnvironmentPostProcessor=cn.aezo.test.ConfEnvironmentPostProcessor
```

### EnvironmentPostProcessor加载自定义配置路径文件

- 通常spring boot项目的配置文件都是配置在classpath环境变量下面，系统会默认使用ConfigFileApplicationListener去加载；但是如果项目打成war、jar包并且已经升级过了或者在项目之外有自定义的配置文件，这时候想改配置，文件这时候就需要重新打包了，这样很麻烦，而Spring boot也给我们提供了扩展的接口`EnvironmentPostProcessor`
- 参考：https://blog.csdn.net/yaomingyang/article/details/99463212
    - 实现EnvironmentPostProcessor接口
    - 并将相应类设置到`spring.factories`文件中
    - 在配置`spring.profiles.*`等参数

### 其他

- 获取资源文件

```java
// 获取编译后classes目录下的`images/tray-running.png`文件，resources目录下的文件默认会放在classes根目录(上层无resources这层目录)
MyTest.class.getClassLoader().getResource("images/tray-running.png")
```
- classpath使用

```yml
myConfig:
  # classpath为编译后classes目录的路径
  path: classpath:../db/default.accdb
```
- [获取Maven版本号](https://blog.yeskery.com/articles/382195730)

```yml
# 再通过@Value注入，返回如：1.0.0-SNAPSHOT
version:
  @project.version@
```
- yml配置

```yml
# https://blog.csdn.net/Mrqiang9001/article/details/83002988
# 结果为：hello wor\nld
str1: |
  hello wor
  ld
# 结果为：hello wor ld
str2: >
  hello wor
  ld
# 结果为：hello world。注意必须加双引号
str3: "hello wor\
  ld"
```

## 请求及响应

- 相关配置

```bash
# 端口
server.port=9090
# context-path路径
server.context-path=/myapp
```

### 请求协议

- 参考文章
    - 原理参考：[spring-src.md#MVC请求参数解析](/_posts/java/spring-src.md#MVC请求参数解析)
    - https://www.hangge.com/blog/cache/detail_2485.html (POST请求示例)
    - https://www.hangge.com/blog/cache/detail_2484.html  (GET请求示例)
- 常见请求方式

request-method |Content-Type   |postman   |springboot   |说明
--|---|---|---|---
post |`application/json`   |row-json   |(String userIdUrlParam, @RequestBody User user) |`String userIdUrlParam`可以接受url中的参数，使用了`@RequestBody`可以接受body中的参数(最终转成User/Map/List对象，**如`@RequestBody List<Map<String, Object>> items`**，此时body中的数据不能直接通过String等接受)，而idea的http文件中url参数拼在地址上无法获取(请求机制不同)
(x)post |`application/json`   |row-json   |(@RequestParam username) |如果前台为application/json + {username: smale}或者application/json + username=smalle均报400；此时需要application/x-www-form-urlencoded + username=smalle才可请求成功
post |`application/x-www-form-urlencoded`   |x-www-form-urlencoded   |(String name, User user, @RequestBody body)   |`String name`可以接受url中的参数，postmant的x-www-form-urlencoded中的参数会和url中参数合并后注入到springboot的参数中；`@RequestBody`会接受url整体的数据，(由于Content-Type)此时不会转换，body接受的参数如`name=hello&name=test&pass=1234`。**对于application/x-www-form-urlencoded类型的数据，可无需 @RequestBody 接受参数**
post |`multipart/form-data`  |form-data   |(HttpServletRequest request, MultipartFile file, User user, @RequestParam("hello") String hello)   |参考[文件上传下载](#文件上传下载)，文件上传必须使用此类型(包含参数)；javascript XHR(包括axios等插件)需要使用new FormData()进行数据传输；此时参数映射到User对象，如果字段为null则会转换成'null'进行映射，如果改字段为数值类型，会导致字符串转数值出错；**如果接受参数是Map则无法映射**；表单数据都保存在http的正文部分，各个表单项之间用boundary隔开，用request.getParameter是取不到数据的，这时需要通过request.getInputStream来取数据
get |-  |-  |(User user, Page page) |前台传输参数为{username: 'smalle', pageSize: 10}时，可正确分别映射到两个对象；如果此时为post请求则无法映射；get请求时，请求参数会拼接到url上，Google浏览器URL最大长度限制为8182个字符，中文是以urlencode后的编码形式进行传递，如果浏览器的编码为UTF8的话，一个汉字最终编码后的字符长度为9个字符(中dui%E4%B8%AD)。如果用Map接受，则数字类型的值也会映射成字符串

- content-type传入"MIME类型"(多用途因特网邮件扩展 Multipurpose Internet Mail Extensions)只是一个描述，决定文件的打开方式
	- 请求的header中加入content-type标明数据MIME类型。如POST时，application/json表示数据存放再body中，且数据格式为json
	- 服务器response设置content-type标明返回的数据类型。接口开发时，设置请求参数是无法改变服务器数据返回类型的。部分工具提供专门的设置，通过工具内部转换的方式实现设定返回数据类型

### 请求参数

- 如果所在类加注解`@RequestMapping("/user")`，则请求url全部要拼上`/user`，如`/user/hello`

```java
@RequestMapping(value = "/hello") // 前台post请求也可以请求的到
public String hello() {
	return "hello world";
}
```

- GET请求

```java
// 前台GET请求 Body/Url 中含参数 userId和username（Spring可以自动注入java基础数据类型和对应的数组，Map/List无法注入）
// 只能自动注入userId=1&username=smalle格式的数据，如果请求体中是json数据则无法解析(如果参数为json数据，一般可定义请求头为`'Content-Type': 'application/x-www-form-urlencoded'`，从而让qs等插件自动转成url格式参数请求后台)
@RequestMapping(value="/getUserByUserIdOrUsername")
public Result getUserByUserIdOrUsername(Long userId, String username, HttpServletRequest request) {
	// ...
	return Result.success(); // 自己封装的Result对象(前台可接受到此object对象)
}
// 前台请求 Body/Url 中含参数 username
@RequestMapping(value="/getUserByName")
public String getUserByName(@RequestParam("username") String name) {}
@RequestMapping(value = "/getUser")
public String getUser(User user) {} // 此时User对象必须声明getter/setter方法
// @PathVariable 获取 url 中的参数
@RequestMapping(value="/hello/{id}")
public String user(@PathVariable("id") Long id) {} // 100可转成Long
```

- POST请求

```java
// 请求头为application/x-www-form-urlencoded(不能是application/json，否则无法注入)
@RequestMapping(value = "/addUser", method = RequestMethod.POST)
public String hello(User user) {}
public String hello(Map<String, Object> map) {}

// 如请求头为`application/json`，此body中为一个json对象(请求时无需加 data={} 等key，直接为 {} 对象)。
// 直接通过 `@RequestBody User user` 获取body中的参数(springboot会自动映射)，或者`@RequestBody String body`接收了之后再转换，但是不能同时使用两个。如果body可以成功转成Map/List，此处也可以用 `@RequestBody Map<String, Object>`接受
@RequestMapping(value = "/addUser", method = RequestMethod.POST)
public String addUser(@RequestBody List<User> user) {} // body数据可以成功转成Map/List时
public String addUser(@RequestBody Map<String, Object> map) {}

// 请求数据http://localhost/?name=smalle&pass=123
@RequestMapping(value = "/addUser", method = RequestMethod.POST)
public String addUser(@RequestBody String param) {} // 此时param拿到的值为 name=smalle&pass=123
```

### 文件上传下载

- 案例参考[springboot-vue.md#文件上传案例](/_posts/arch/springboot-vue.md#文件上传案例)
- 常用配置

```yml
spring:
  http:
    multipart:
      # Linux下会自动清除tmp目录下10天没有使用过的文件，SpringBoot启动的时候会在/tmp目录下生成一个Tomcat.*的文件目录，用于"java.io.tmpdir"文件流操作，因为放假期间无人操作，导致Linux系统自动删除了临时文件，所以导致上传报错。另一种配置方式参考下文 MultipartConfigElement
      location: /var/tmp
  servlet:
    multipart:
      # 允许的最大文件大小
      max-file-size: 50MB
      max-request-size: 50MB
  mvc:
    # 静态资源映射，通过后台访问文件的路径(一般需要排除对此路径的权限验证)。相当于一个映射，映射的本地路径为 spring.resources.static-locations
    # 实际访问还需要增加servlet.context路径(/api)，如访问 /api/static/test/test.js -> test/test.js(此时test目录会自动识别属于哪个目录)
    static-path-pattern: /static/** # 此路径尽量不要和classpath目录下文件夹重名
  resources:
    # 默认为：classpath:/META-INF/resources/,classpath:/resources/,classpath:/static/,classpath:/public/
    # 后台可访问的本地文件路径. **最终的URL路径不需要携带此前缀，其应该保存各目录下的顶级子目录不会重复。如果重复了，static-locations值中排在前面的优先**
    static-locations: classpath:/META-INF/resources/,classpath:/resources/,file:/data/app
```
- 使用JavaBean进行静态文件映射

```java
@Configuration
public class InterceptorConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 可添加多条，优先级先添加的高于后添加的
        // 通过此方式添加的映射优先级高于上文static-path-pattern配置的
        registry.addResourceHandler("/image/**").addResourceLocations("file:D:/image/"); // file:/D:/image/ 亦可. 实际访问还需要增加servlet.context路径
    }
}
```
- 上传文件临时目录问题
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
- 后台会报错：no multipart boundary was found。此问题本身不是后台的原因，解决方法如下 [^21]
    - 通过`axios.create`重新定义一个axios实例，并挂载到Vue原型上。此处重新定义是防止使用项目中默认的axios实例(一般会通过axios.interceptors.request.use进行处理，而处理后的实例在上传时后台会报错)。具体见上文案例
    - 不严谨的处理

        ```js
        // $axios为上文提到的被处理过的axios实例
        this.$axios.post('http://localhost:8080/upload', formData, {
            headers: {
                'Content-Type': 'multipart/form-data;boundary = ' + new Date().getTime()
            }
        }).then(response => {})
        ```

### 响应

- `@ResponseBody`
	- 表示以json返回数据
	- 定义在类名上，表示所有的方法都是`@ResponseBody`的，也可单独定义在方法上
- `@RestController`中包含`@ResponseBody`
- 重定向

```java
@SneakyThrows
@RequestMapping("/download/{id}/{fileName}")
public void download(@PathVariable("id") Integer id, HttpServletRequest request, HttpServletResponse response) {
    EdiHead info = ediHeadService.info(id);
    String ediPath = info.getEdiPath();
    // 内部重定向，/files不以/开头，则会加上原始请求路径
    request.getRequestDispatcher("/files" + ediPath).forward(request, response);

    // 重定向
    // response.sendRedirect("/files");
}
```

### RestTemplate

- 具体参考[RestTemplate](/_posts/java/java-http.md#RestTemplate)

### 前端数组/对象处理

- json字符串传输方式一(不推荐)
    - 前端通过`JSON.stringify`转成json字符串，然后后台JSONObject等转成Bean/Map等
- Spring的Bean自动注入
    - 请求类型 `POST`、`Content-Type: application/json`，后端方法为`public Result edit(@RequestBody CustomerInfo customerInfo)`接受，chrome开发者模式看到的为json对象
    - 请求类型 `POST`、`Content-Type: multipart/form-data`、使用FormData传输参数，后端可使用`public Result edit(Multipart myFile, CustomerInfo customerInfo)`接受，chrome开发者模式看到的同上文FormData。传输文件必须格式
	- 请求类型 `POST`、`Content-Type: application/x-www-form-urlencoded`
	    - chrome开发模式看到的`FormData`(格式化后的。实际请求是将每一项通过`URL encoded`进行转义之后再已`&`连接组装成url参数，此时POST参数是没有长度限制的)如：
        - 后端写好对应的Bean，且后端方法如`public Result edit(CustomerInfo customerInfo)`
            - 后端代码`public Result edit(Map<String, Object> params)`报错
            - 后端代码`public Result edit(String customerNameCn, List customerLines)`报错

		```js
		id: 766706
        customerNameCn: 客户名称
        // CustomerInfo中的updateTm属性可以是Date(会自动转换)
        updateTm: 2018/08/17 13:02:36
        // CustomerInfo中的属性customerLines(属性名/setter方法必须和前端参数名保持一致)可以是List<String>或者String[]
		customerLines[0]: AustraliaLine
		customerLines[1]: MediterraneanLine
        customerLines[2]: SoutheastAsianLine
        // CustomerInfo中包含CustomerRisk和List<CustomerContacts>
		customerRisk.id: 9906
		customerRisk.customerId: 766706
		customerRisk.note: 客户风险备注
		customerContacts[0].id: 767001
		customerContacts[0].customerId: 766706
		customerContacts[0].lastName: 客户联系人1
		```

#### 拦截request的body数据/拦截response的数据

参考[spring.md#拦截response的数据](/_posts/java/spring.md#拦截response的数据)

## 数据访问

- 数据库驱动

	```xml
	<!--mysql数据库驱动-->
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
	# 端口默认3306可以省略
    # 使用mysql-connector-java v8.0.0以上则必须加serverTimezone; zeroDateTimeBehavior解决日期值为0000-00-00 00:00:00的数据(mysql最小日期为1900-01-01 00:00:00，全部为0会报错)
	spring.datasource.url=jdbc:mysql://localhost:3306/springboot?serverTimezone=Asia/Shanghai&useUnicode=true&useSSL=false&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull
	spring.datasource.username=root
	spring.datasource.password=root
	# springboot连接池默认使用的是tomcat-jdbc-pool，在处理utf8mb4类型数据(Emoji表情、生僻汉字。uft8默认只能存储1-3个字节的汉字，上述是4个字节)的时候，需要大致两步
		# 1.设置数据库、表、字段的编码类型为utf8mb4
		# 2.在创建数据库连接之后，要执行一条sql语句 "SET NAMES utf8mb4 COLLATE utf8mb4_general_ci"，这样的数据库连接才可以操作utf8mb4类型的数据的存取
	spring.datasource.tomcat.initSQL=SET NAMES utf8mb4 COLLATE utf8mb4_general_ci

	# 执行初始化库语句
	initialization-mode: always # springboot 2.0需要开启初始化模式。embedded(默认值, 当使用内嵌数据库时可使用, 如 h2), always使用外部数据库时需要开启
	# 每次启动都会执行, 且在hibernate建表语句之前执行（如果要执行需要sql脚本先关闭hibernate建表 spring.jpa.hibernate.ddl-auto=none）
	# 若无此定义, springboot也会默认执行resources下的schema.sql(先)和data.sql(后)文件(如果存在)
	# 执行建表语句(也会执行插入等语句)
	spring.datasource.schema=classpath:schema.sql
	# 执行数据添加语句
	spring.datasource.data=classpath:data.sql
	```

### 对hibernate的默认支持(JPA)

参考：[http://blog.aezo.cn/2017/05/21/java/hibernate/](/_posts/java/hibernate)

### 整合mybatis

参考：[http://blog.aezo.cn/2017/05/22/java/mybatis/](/_posts/java/mybatis#mybatis-plus)

### 事物支持

参考：[http://blog.aezo.cn/2017/07/01/java/spring/](/_posts/java/spring.md#事物支持)

### JdbcTemplate访问数据

- 示例

	```java
	@Autowired
	private JdbcTemplate jdbcTemplate; // 单数据源时，springboot默认会注入JdbcTemplate的Bean

	// 1.查询一行数据并返回int型结果
	jdbcTemplate.queryForInt("select count(*) from test");
	// 2.查询一行数据并将该行数据转换为Map返回(key大小写按照select的字段名大小写)。**如果不存在会返回null**
	jdbcTemplate.queryForMap("select * from test where id=1");
	// 3.查询一行任何类型的数据，最后一个参数指定返回结果类型
    try {
	    jdbcTemplate.queryForObject("select valid_status from test where id = 1", Integer.class); 
    } catch(EmptyResultDataAccessException e) {
        // 为空会报错
    }
	try {
		String username = jdbcTemplate.queryForObject("select t.username from t_test t where t.id=?", String.class, 10000L);
	} catch (DataAccessException e) {
	}
	// 4.**基于实体查询**，也可查询集合(同查询8)
	// 注意：如果直接按照下面注释的写法会查询失败，仅有警告信息(IncorrectResultSetColumnCountException: Incorrect column count: expected 1, actual 10)，不会报错
	// UserVo userVo = uscUmcJdbcTemplate.queryForObject(
	//         "select * from u_user_login ul where ul.username = ? and ul.valid_status = 1 limit 1", UserVo.class, username);
	UserVo userVo = uscUmcJdbcTemplate.queryForObject(
			"select * from u_user_login ul where ul.username = ? and ul.valid_status = 1 limit 1",
			new Object[]{username},
			new BeanPropertyRowMapper<>(UserVo.class));

	// 5.查询一批数据，默认将每行数据转换为Map(key大小写按照select的字段名大小写)。**如果不存在会返回无任何元素的集合**
	List<Map<String, Object>> list = jdbcTemplate.queryForList("select * from test");
	// 6.只查询一列数据列表，列类型是String类型
	List<String> names = jdbcTemplate.queryForList("select name from test where name=?", new Object[]{"smalle"}, String.class);
	// 7.查询一批数据，返回为SqlRowSet，类似于ResultSet，但不再绑定到连接上
	SqlRowSet rs = jdbcTemplate.queryForRowSet("select * from test");

	// 8.基于实体查询
	String sql = "select id, name, age from student";
	List<Student> students = (List<Student>) jdbcTemplate.query(sql, new RowMapper<Student>() {
		@Override
		public Student mapRow(ResultSet rs, int rowNum) throws SQLException {
			Student stu = new Student();
			stu.setId(rs.getInt("ID"));
			stu.setAge(rs.getInt("AGE"));
			stu.setName(rs.getString("NAME"));
			return stu;
		}
	});

    // 9.插入/更新
    int count = jdbcTemplate.update("insert into t_user(username, password) values('smalle', '123456')");  
    int count = jdbcTemplate.update("update t_user set username = 'smalle' where username = 'hello'");  
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

### 数据库连接池(Druid)

- [Druid](https://github.com/alibaba/druid)
- 使用参考：https://programtip.com/zh/art-70468
- 依赖

    ```xml
    <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>druid-spring-boot-starter</artifactId>
        <version>1.2.3</version>
    </dependency>
    ```
- 配置：https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter

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

### ldap操作

- 引入依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-ldap</artifactId>
</dependency>
```
- 配置

```yml
spring.ldap.urls=ldap://192.168.1.100:1389
spring.ldap.base=dc=demo,dc=com
spring.ldap.username=cn=admin,dc=demo,dc=com # 或者ldap用户dn(此用户的权限决定springboot连接此服务后可进行的操作)
spring.ldap.password=123456
```
- 使用

```java
// 实体类
@Data
@Entry(base = "ou=People,dc=demo,dc=com", objectClasses = "inetOrgPerson") // org.springframework.ldap.odm.annotations.Entry;
public class Person {
    @Id // org.springframework.ldap.odm.annotations.Id;
    private Name id; // javax.naming.Name;
    
    @Attribute(name = "uid")
    private String uid;
    
    @Attribute(name = "cn")
    private String commonName;
    
    @Attribute(name = "sn")
    private String suerName;

    @Attribute(name = "userPassword", type = Attribute.Type.BINARY) // org.springframework.ldap.odm.annotations.Attribute;
    private byte[] userPassword;

    @Attribute(name = "displayName")
    private String displayName;

    public void setUserPassword(String userPassword) {
        this.userPassword = userPassword.getBytes(Charset.forName("UTF-8"));
    }
}

// dao
public interface PersonRepository extends CrudRepository<Person, Name> {}

// test
@Test
public void findAll() throws Exception {
    // 查询
    personRepository.findAll().forEach(p -> {
        System.out.println("p = " + p);
    });

    // 编辑
    LdapName ldapName = new LdapName("cn=tester,ou=测试组,ou=研发部门,ou=People");
    Person p = personRepository.findById(ldapName).get();
    p.setSuerName("tester123");
    personRepository.save(p);

    // LdapTemplate
    List<Person> list = ldapTemplate.find(query().where("uid").is("10002"), Person.class);
    System.out.println("list = " + list);

    Person p2 = list.get(0);
    p2.setDisplayName("displayName...");
    p2.setUserPassword(sha1("123456"));
    ldapTemplate.update(p2);

    // 验证密码
    boolean flag = ldapTemplate.authenticate("cn=someone,ou=后台组,ou=研发部门,ou=People", "(objectclass=Person)", "abc123");
    System.out.println("flag = " + flag);

    // 删除条目
    ldapTemplate.unbind("uid=testhr,ou=HR,ou=People");
}

public static String sha1(String str) throws NoSuchAlgorithmException, UnsupportedEncodingException {
    if (null == str || str.length() == 0) {
        return null;
    }
    MessageDigest mdTemp = MessageDigest.getInstance("SHA1");
    mdTemp.update(str.getBytes("UTF-8"));
    byte[] md = mdTemp.digest();

    return "{SHA}" + Utf8.decode(java.util.Base64.getEncoder().encode(md));
}
```

## 视图展示

### thymeleaf模板引擎

- 引入依赖

	```xml
	<!--thymeleaf模板引擎, 包含spring-boot-starter-web-->
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-thymeleaf</artifactId>
	</dependency>
	<!--可选：使用layout布局时需要用到（Springboot2.0.1必须，Springboot1.5.6无需）-->
	<dependency>
		<groupId>nz.net.ultraq.thymeleaf</groupId>
		<artifactId>thymeleaf-layout-dialect</artifactId>
	</dependency>

    <!-- 可选：启用thymeleaf的html非严格模式 -->
    <dependency>
        <groupId>net.sourceforge.nekohtml</groupId>
        <artifactId>nekohtml</artifactId>
        <version>1.9.22</version>
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
				return "hello"; // 不能加后缀名
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
	- 推荐使用`JRebel`(idea需要Ctrl+Shift+F9刷新部分静态文件，java文件会自动刷新)
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

### ftl模板

- 引入依赖，其他同thymeleaf

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-freemarker</artifactId>
</dependency>
```

## 企业级开发

### Nosql

#### 整合redis

参考 [http://blog.aezo.cn/2016/07/02/db/redis/](/_posts/db/redis.md#SpringBoot使用Redis)

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

参考[rabbitmq.md#整合SpringBoot](/_posts/arch/rabbitmq.md#整合SpringBoot)

### WebSocket

- 引入依赖 [^11]

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

### 多数据源/动态数据源/运行时增加数据源

> springboot/dynamic-datasource

- 尚未找到启动程序后再初始化数据源简单解决方案。目前可以使用运行时增加数据源的方法，但是必须启动项目的时候设置一个默认的数据源(可以不使用，但是需要能初始化，比如一个H2数据源)，然后启动后动态修改此默认数据源

#### 多数据源 [^14]

- springboot v2.0.1配置文件中需要为`spring.datasource.xxx.jdbc-url`(之前为`spring.datasource.xxx.url`)
- 配置

```yml
spring:
  datasource:
	# 直接写在datasource下的jdbc-url数据源无法充当默认数据源，默认数据源需要通过`@Primary`定义
    access-one: # 不能使用下划线
      driver-class-name: net.ucanaccess.jdbc.UcanaccessDriver
      jdbc-url: jdbc:ucanaccess://D:/gitwork/springboot/dynamic-datasource/src/main/resources/test.accdb;memory=true
    mysql-one:
      driver-class-name: com.mysql.jdbc.Driver
      jdbc-url: jdbc:mysql://localhost:3306/test?useUnicode=true&characterEncoding=utf-8
      username: root
      password: root
    sqlserver-one:
      driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
      jdbc-url: jdbc:sqlserver://192.168.17.237:1433;DatabaseName=fedex
      username: sa
      password: root
```
- JavaBean配置

```java
// 多数据源配置
@Configuration
public class MultiDataSourceConfig {
    // access数据源
    @Bean(name = "accessDataSource")
    // @Qualifier("accessDataSource")
    @ConfigurationProperties(prefix="spring.datasource.access-one")
    public DataSource accessDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean(name = "accessJdbcTemplate")
    public JdbcTemplate accessJdbcTemplate(
            @Qualifier("accessDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }

    // mysql数据源
	@Primary // 默认数据源，全局只能有一个
    @Bean(name = "mysqlDataSource")
    // @Qualifier("mysqlDataSource")
    @ConfigurationProperties(prefix="spring.datasource.mysql-one")
    public DataSource mysqlDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean(name = "mysqlJdbcTemplate")
    public JdbcTemplate mysqlJdbcTemplate(
            @Qualifier("mysqlDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }

    // sqlserver数据源
    @Bean(name = "sqlserverDataSource")
    // @Qualifier("sqlserverDataSource")
    @ConfigurationProperties(prefix="spring.datasource.sqlserver-one")
    public DataSource sqlserverDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean(name = "sqlserverJdbcTemplate")
    public JdbcTemplate sqlserverJdbcTemplate(
            @Qualifier("sqlserverDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}
```
- JdbcTemplate使用

```java
@Autowired
@Qualifier("accessJdbcTemplate")
JdbcTemplate accessJdbcTemplate;

@Autowired
@Qualifier("mysqlJdbcTemplate")
JdbcTemplate mysqlJdbcTemplate;

@Autowired
@Qualifier("sqlserverJdbcTemplate")
JdbcTemplate sqlserverTemplate;

@Test
public void test() {
	List<Map<String, Object>> accessData = accessJdbcTemplate.queryForList("select * from Users");
	System.out.println("accessData = " + accessData); // accessData = [{UserId=1, UserName=test07, UserSex=1, UserBirthday=2018-11-15 00:00:00.0, UserMarried=true}, {UserId=2, UserName=access2007, UserSex=1, UserBirthday=2018-11-14 00:00:00.0, UserMarried=true}, {UserId=3, UserName=123, UserSex=1, UserBirthday=2018-11-16 00:00:00.0, UserMarried=false}]

	List<Map<String, Object>> mysqlData = mysqlJdbcTemplate.queryForList("select * from test");
	System.out.println("mysqlData = " + mysqlData); // mysqlData = [{id=1, username=smalle, password=123456}]

	List<Map<String, Object>> sqlserverData = sqlserverTemplate.queryForList("select * from t_test"); // sqlserverData = [{id=1001, name=阿婆, gender=女, age=125, note=null}, {id=1002, name=阿公, gender=男, age=130, note=null}, {id=1003, name=大爷, gender=男, age=90, note=null}, {id=1004, name=大妈, gender=女, age=88, note=null}, {id=1005, name=你, gender=嘿嘿, age=3, note=null}]
	System.out.println("sqlserverData = " + sqlserverData);
}
```
- mybatis使用 [^15]

```java
// ### 1.Mysql数据源配置如下，Sqlserver配置同理(或者其他Mysql数据源)创建一个对应的配置类
@Configuration
// cn.aezo.springboot.datasource.mapper.mysql下的Mapper接口，都会使用mysql-one数据源
@MapperScan(basePackages = {"cn.aezo.springboot.datasource.mapper.mysql"}, sqlSessionFactoryRef = "sqlSessionFactoryMysql")
public class MysqlMybatisConfig {
    @Autowired
    @Qualifier("mysqlDataSource")
    private DataSource ds1;

    // 此处生成的Bean的名字(sqlSessionFactoryMysql)必须和sqlSessionFactoryRef中指定的一致
    @Bean
    public SqlSessionFactory sqlSessionFactoryMysql() throws Exception {
        SqlSessionFactoryBean factoryBean = new SqlSessionFactoryBean();
        factoryBean.setDataSource(ds1);
        return factoryBean.getObject();
    }

    @Bean
    public SqlSessionTemplate sqlSessionTemplate1() throws Exception {
        SqlSessionTemplate template = new SqlSessionTemplate(sqlSessionFactoryMysql()); // 使用上面配置的Factory
        return template;
    }
}

// ### 2.测试mybatis使用不同数据源
@Autowired
MysqlTestDao mysqlTestDao;

@Autowired
SqlserverTestDao sqlserverTestDao;

@Test
public void testMybatis() {
	List<Map<String, Object>> mysqlData = mysqlTestDao.findTest();
	System.out.println("mysqlData = " + mysqlData); // mysqlData = [{id=1, username=smalle, password=123456}]

	List<Map<String, Object>> sqlserverData = sqlserverTestDao.findTest();
	System.out.println("sqlserverData = " + sqlserverData); // sqlserverData = [{id=1001, name=阿婆, gender=女, age=125, note=null}, {id=1002, name=阿公, gender=男, age=130, note=null}, {id=1003, name=大爷, gender=男, age=90, note=null}, {id=1004, name=大妈, gender=女, age=88, note=null}, {id=1005, name=你, gender=嘿嘿, age=3, note=null}]
}
```

#### 动态数据源

- 使用动态数据源的初衷，是能在应用层做到读写分离，即在程序代码中控制不同的查询方法去连接不同的库。除了这种方法以外，数据库中间件也是个不错的选择，它的优点是数据库集群对应用来说只暴露为单库，不需要切换数据源的代码逻辑。
- 继承`AbstractRoutingDataSource`；通过`setDefaultTargetDataSource`和`setTargetDataSources`设置默认和可切换的数据源；基于自定义注解设置每个方法需要使用的数据源
- 主要代码

```java
// ### 1
// AbstractRoutingDataSource 只支持单库事务，也就是说切换数据源要在开启事务之前执行
public class DynamicDataSource extends AbstractRoutingDataSource {
    // 预备一份用于存储targetDataSource，否则之前的设置的数据源会丢失。(此处无法获取AbstractRoutingDataSource的targetDataSources值)
    private ConcurrentHashMap<String, DataSource> backupTargetDataSources = new ConcurrentHashMap<>();
    public Map<String, DataSource> getBackupTargetDataSources() {
        return backupTargetDataSources;
    }
    // 添加数据源配置关系
    public void addDataSourceToTargetDataSource(String dsKey, DataSource ds){
        this.backupTargetDataSources.put(dsKey, ds);
    }
    // 重设多数据源配置
    public void reSetTargetDataSource() {
        Map targetDataSources = this.backupTargetDataSources;
        super.setTargetDataSources(targetDataSources);
        this.afterPropertiesSet();
    }
    // 决定了当前操作选择哪个数据源. 第一次使用才会初始化，之后切换数据源则不需重复初始化
    @Override
    protected Object determineCurrentLookupKey() {
        return ThreadLocalDSKey.getDS();
    }
}

// ### 2
@Configuration
public class DynamicDataSourceConfig {
    // mysql-one数据源
    @Bean(name = "mysqlDataSourceDynamic")
    @Qualifier("mysqlDataSourceDynamic")
    @ConfigurationProperties(prefix="spring.datasource.mysql-one")
    public DataSource mysqlDataSourceDynamic() {
        return DataSourceBuilder.create().build();
    }

    // mysql-two数据源
    @Bean(name = "mysqlTwoDataSourceDynamic")
    @Qualifier("mysqlTwoDataSourceDynamic")
    @ConfigurationProperties(prefix="spring.datasource.mysql-two")
    public DataSource mysqlTwoDataSourceDynamic() {
        return DataSourceBuilder.create().build();
    }

    /**
     * 动态数据源(池)：将所有数据加入到动态数据源管理中
     */
    @Bean(name = "dynamicDataSource")
    public DataSource dataSource() {
        DynamicDataSource dynamicDataSource = new DynamicDataSource();

        // 默认数据源
        dynamicDataSource.setDefaultTargetDataSource(mysqlDataSourceDynamic());

        // 配置多数据源
        dynamicDataSource.addDataSourceToTargetDataSource("mysql-one-dynamic", mysqlDataSourceDynamic());
        dynamicDataSource.addDataSourceToTargetDataSource("mysql-two-dynamic", mysqlTwoDataSourceDynamic());
        Map targetDataSources = dynamicDataSource.getBackupTargetDataSources();
        dynamicDataSource.setTargetDataSources(targetDataSources);

        return dynamicDataSource;
    }
}

// ### 3 cn.aezo.springboot.datasource.mapper.dynamic包下的接口Mybatis会使用sqlSessionFactoryMysqlDynamic的数据源工厂
@Configuration
@MapperScan(basePackages = {"cn.aezo.springboot.datasource.mapper.dynamic"}, sqlSessionFactoryRef = "sqlSessionFactoryMysqlDynamic")
public class DynamicMybatisConfig {
    @Autowired
    @Qualifier("dynamicDataSource") // 此处注入动态数据源
    private DataSource dataSource;

    // 此处生成的Bean的名字, 必须和sqlSessionFactoryRef中指定的一致
    @Bean
    public SqlSessionFactory sqlSessionFactoryMysqlDynamic() throws Exception {
        SqlSessionFactoryBean factoryBean = new SqlSessionFactoryBean();
        factoryBean.setDataSource(dataSource);
        return factoryBean.getObject();
    }

    @Bean
    public SqlSessionTemplate sqlSessionTemplateMysqlDynamic() throws Exception {
        SqlSessionTemplate template = new SqlSessionTemplate(sqlSessionFactoryMysqlDynamic()); // 使用上面配置的Factory
        return template;
    }
}

// ### 4
// ThreadLocal存储数据，解决线程安全问题
public class ThreadLocalDSKey {
    // 默认数据源标识
    public static final String DEFAULT_DS_KEY = "mysql-one-dynamic";
    private static final ThreadLocal<String> dsKeyHolder = new ThreadLocal<>();
    // 设置数据源名
    public static void setDS(String dbKey) {
        dsKeyHolder.set(dbKey);
    }
    // 获取数据源名
    public static String getDS() {
        return (dsKeyHolder.get());
    }
    // 清除数据源名
    public static void clearDS() {
        dsKeyHolder.remove();
    }
}

// ### 5
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD})
public @interface DS {
    String value() default "mysql-one-dynamic";
}

// ### 6 需要添加AOP相关依赖
@Aspect
@Component
// @Order(-1) // 保证该AOP在@Transactional之前执行
public class DynamicDataSourceAspect {

    // AbstractRoutingDataSource 只支持单库事务，也就是说切换数据源要在开启事务之前执行
    @Before("@annotation(DS)")
    public void beforeSwitchDS(JoinPoint point){
        //获得当前访问的class
        Class<?> className = point.getTarget().getClass();

        //获得访问的方法名
        String methodName = point.getSignature().getName();
        //得到方法的参数的类型
        Class[] argClass = ((MethodSignature)point.getSignature()).getParameterTypes();
        String dsKey = ThreadLocalDSKey.DEFAULT_DS_KEY;
        try {
            // 得到访问的方法对象
            Method method = className.getMethod(methodName, argClass);

            // 判断是否存在@DS注解
            if (method.isAnnotationPresent(DS.class)) {
                DS annotation = method.getAnnotation(DS.class);
                // 取出注解中的数据源名
                dsKey = annotation.value();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 切换数据源
        ThreadLocalDSKey.setDS(dsKey);
    }

    @After("@annotation(DS)")
    public void afterSwitchDS(JoinPoint point) {
        // ThreadLocalDSKey.clearDS();
    }
}

// ### 7
@Service
public class TestService {
    @Autowired
    TestDao testDao;

    @DS("mysql-one-dynamic")
    public void testMysqlOne() {
        List<Map<String, Object>> data = testDao.findTest();
        System.out.println("data = " + data); // data = [{password=123456, id=1, username=smalle}]
    }

    @DS("mysql-two-dynamic")
    public void testMysqlTwo() {
        List<Map<String, Object>> data = testDao.findTest();
        System.out.println("data = " + data); // data = [{password=ABC123, id=1, username=test_two}]
    }

	// ###### 运行时增加数据源相关代码
    // 此数据源默认没有，需要手动添加后，才可使用。否则使用的默认数据源
    @DS("mysql-three-dynamic")
    public void testMysqlThree() {
        List<Map<String, Object>> data = testDao.findTest();
        System.out.println("data = " + data); // data = [{password=EFG456, id=1, username=test_three}]
    }
	
	// 在controller中通过传入参数进行数据源切换
    public List<Map<String, Object>> testMysql() {
        return testDao.findTest();
    }
	// ###### 运行时增加数据源相关代码
}
```

#### 运行时增加数据源 [^16]

```java
// ### 1 添加数据源
@RequestMapping("/add-dynamic")
public String AddDynamic(String dsKey, String dbName) {
	if(null == dsKey && dbName == null) return "dsKey,dbName不能为空";

	// 获取 DynamicDataSource。之前注册给spring 容器，这里可以通过ctx直接拿.
	ApplicationContext ctx = springContextU.getApplicationContext(); // springContextU参考【常用配置-获取Bean】
	DynamicDataSource dynamicDataSource = ctx.getBean(DynamicDataSource.class);

	// 构建新数据源. 第一次使用才会初始化，之后切换数据源则不需重复初始化
	DataSource ds = DataSourceBuilder.create()
			.driverClassName("com.mysql.jdbc.Driver")
			.url("jdbc:mysql://localhost:3306/"+ dbName +"?useUnicode=true&characterEncoding=utf-8")
			.username("root")
			.password("root")
			.type(com.zaxxer.hikari.HikariDataSource.class)
			.build();

	// 增加并重设TargetDataSource
	dynamicDataSource.addDataSourceToTargetDataSource(dsKey, ds);
	dynamicDataSource.reSetTargetDataSource();

	return "success";
}

// ### 2 服务参考上文`TestService`相关代码
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

### 使用lombok工具

- idea可安装lombok插件
- 依赖

```xml
<dependency>
	<groupId>org.projectlombok</groupId>
	<artifactId>lombok</artifactId>
	<optional>true</optional>
</dependency>
```

- 使用
```java
// 枚举使用 @Getter @Setter
public interface ISubscribeService extends IService<Subscribe> {
    enum FlowStatus {
        SUBSCRIBE("已订阅", 1), SEARCHING("查询中", 2), SEARCH_SUCCESS("已返回", 3), SEARCH_FAILED("返回失败", 4);
        private @Getter @Setter String name;
        private @Getter @Setter int status;

        FlowStatus(String name, int status) {
            this.name = name;
            this.status = status;
        }
    }
}
```

### 整合swagger

参考[/_posts/arch/swagger.md#springboot中使用](/_posts/arch/swagger.md#springboot中使用)

### 邮件操作

- 依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-mail</artifactId>
</dependency>
```
- application.yml

```yml
# email
spring:
  mail:
    host: smtp.exmail.qq.com # qq企业邮箱
    port: 465 # 使用SSL协议需要
    username: test@qq.com
    password: 4ZfWRqjXzhdxxyhW
    properties: # map格式
      from: 自定义昵称<${spring.mail.username}> # 发件人显示名
      mail.smtp.socketFactory.class: javax.net.ssl.SSLSocketFactory # 使用SSL协议需要
```
- 发送

```java
@Autowired
private JavaMailSender javaMailSender;

// 简单邮件
SimpleMailMessage mailMessage = new SimpleMailMessage();
mailMessage.setFrom(mailFrom); // 发件人显示名：xxx<${spring.mail.username}>
mailMessage.setTo(toStr.split(";"));
mailMessage.setSubject(subject);
mailMessage.setText(content);
// mailMessage.setText(content, true); // 内容为html，可通过FTL等模板进行页面美化
javaMailSender.send(mailMessage);

// 复杂邮件
MimeMessage mimeMessage = javaMailSender.createMimeMessage();
MimeMessageHelper messageHelper = new MimeMessageHelper(mimeMessage);
// MimeMessageHelper messageHelper = new MimeMessageHelper(mimeMessage, true);
messageHelper.setFrom(mailFrom);
messageHelper.setTo(toStr.split(";"));
messageHelper.setSubject(subject);
messageHelper.setText(content);
// messageHelper.setText(content, true);
messageHelper.addInline("hello.png", new File("/data/hello.png"));
messageHelper.addAttachment("hello.docx", new File("/data/hello.docx"));
mailSender.send(mimeMessage);
```

## 其他

### 测试

- 普通测试

```java
@RunWith(SpringRunner.class)
@SpringBootTest
@AutoConfigureMockMvc // 可以自动的注册所有添加@Controller或者@RestController的路由的MockMvc了
public class DynamicAddTests {
    @Autowired
    private MockMvc mockMvc;

    @Test
    public void login(){
        try {
			MvcResult mvcResult = mockMvc.perform(MockMvcRequestBuilders.get("/test3?dsKey=mysql-two-dynamic"))
                    .andExpect(MockMvcResultMatchers.status().isOk())
                    .andReturn();
            String content = mvcResult.getResponse().getContentAsString();
            Assert.assertEquals("success", "hello world!", content);

            mockMvc.perform(MockMvcRequestBuilders.post("/api/login/auth")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"name\": \"smalle\"}")
            ).andExpect(MockMvcResultMatchers.status().isOk())
                    .andDo(MockMvcResultHandlers.print()); // 打印请求过程
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

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
			int runnerCount = 100; // 并发数
			// 构造一个Runner
			TestRunnable runner = new TestRunnable() {
				@Override
				public void runTest() throws Throwable {
					// TODO 测试内容
					// Thread.sleep(1000); // 结合sleep表示业务处理过程，测试效果更加明显
					System.out.println("===>" + Thread.currentThread().getId());
				}
			};

			TestRunnable[] arrTestRunner = new TestRunnable[runnerCount];
			for (int i = 0; i < runnerCount; i++) {
				arrTestRunner[i] = runner; 
			}
			MultiThreadedTestRunner mttr = new MultiThreadedTestRunner(arrTestRunner);
			try {
				mttr.runTestRunnables();
			} catch (Throwable e) {
				e.printStackTrace();
			}
		}
		```


### 替换项目运行时springboot的logo

- 在`resources`添加`banner.txt`文件. 内容自定义(文字转字符：http://patorjk.com/software/taag/)，如（font=Doom）：

	```html
    ${AnsiColor.BRIGHT_CYAN} _____               _                 ${AnsiColor.YELLOW} _____        ______  _
    ${AnsiColor.BRIGHT_CYAN}/  ___|             (_)                ${AnsiColor.YELLOW}/  ___|       | ___ \(_)
    ${AnsiColor.BRIGHT_CYAN}\ `--.  _ __   _ __  _  _ __    __ _   ${AnsiColor.YELLOW}\ `--.   __ _ | |_/ / _  ____
    ${AnsiColor.BRIGHT_CYAN} `--. \| '_ \ | '__|| || '_ \  / _` |  ${AnsiColor.YELLOW} `--. \ / _` || ___ \| ||_  /
    ${AnsiColor.BRIGHT_CYAN}/\__/ /| |_) || |   | || | | || (_| |  ${AnsiColor.YELLOW}/\__/ /| (_| || |_/ /| | / /
    ${AnsiColor.BRIGHT_CYAN}\____/ | .__/ |_|   |_||_| |_| \__, |  ${AnsiColor.YELLOW}\____/  \__, |\____/ |_|/___|
    ${AnsiColor.BRIGHT_CYAN}       | |                      __/ |  ${AnsiColor.YELLOW}           | |
    ${AnsiColor.BRIGHT_CYAN}       |_|                     |___/   ${AnsiColor.YELLOW}           |_|

    ${AnsiColor.BLUE}:: SqBiz :: ${spring.application.name:sqbiz}:${AnsiColor.RED}${spring.profiles.active}${AnsiColor.BLUE} :: Running SpringBoot ${spring-boot.version} :: ${AnsiColor.BRIGHT_BLACK}
	```

### 打包成exe

- 使用`exe4j`打包成exe，常用配置选择 [^13]
	- `2.Project Type`：jar in exe mode
	- `4.Executable info - 32-bit or 64-bit`：生成exe的版本
		- Redirection: 勾选Redirect stderr、Redirect stdout可生成日志信息(如果安装在C盘受保护目录则需要以管理员运行程序才会生成日志，如果安装在D盘则不需要管理员启动。日志生成在可执行文件的相对目录)。如果springboot本身配置了日志策略，则也会生成日志
		- Manifast options: `As invoker`以普通程序执行，`Require administrator`需要管理员权限执行
	- `5.Java invocation`：class path中添加springboot生成的jar(可通过java -jar正常运行)的相对路径(基于.exe4j配置文件; exe4j v6.0此处无法选择，只能手输)；main class from填写`org.springframework.boot.loader.JarLauncher`
	- `6.JRE`：添加Directory目录为jre的路径，最好为相对路径，如`./jre`，此步骤并不会吧jre打包到exe中，只会设置exe寻找jre的路径。之后需要将jre和exe文件放在一起打包给用户
	- 给用户提供配置文件，如可执行文件为`myexe.exe`，则在此可执行文件目录创建`myexe.exe.vmoptions`文件，里面加入JVM参数(如：`-Xms256m`)或自定义参数(如：`-DmyValue.val=123456`，其中`myValue.val`是通过`@ConfigurationProperties`定义的参数)，一行一个参数，参数值如果为路径也支持`\`
	- 程序的classpath为exe可执行文件所在目录，如果需要创建文件，则需要可创建文件的权限(如以管理员启动)。程序生成的文件，在卸卸载的时候不会删除(卸载只会删除初始安装的所有文件和文件夹)
- 使用[Inno Setup](http://www.jrsoftware.org/isdl.php)打成可安装程序(打包后大概80M)。具体参考[electron.md#Inno Setup生成安装包](/_posts/web/electron.md#Inno%20Setup生成安装包)
	- File - New - 跟随提示进行配置。
		- Application Files配置：Application main executable file选择exe4j生成的exe文件；
		- other application files(添加其他依赖文件)
			- add folder：选择jre目录(如果上面exe4j第6步填写的是`./jre`，则此处还需要给jre外面包裹一层文件夹如jre-home，然后此处选择jre-home路径即可。最终会jre目录和exe4j生成的exe文件仍然处于同级目录。因此可以将exe4j第6步设置成`.`，则最终可以去掉`jre`这层目录)
			- add files：选择上述`*.vmoptions`
- iss文件（Inno Setup配置文件）如

```ini
; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Myexe"
#define MyAppVersion "1.0"
#define MyAppPublisher "AEZOCN, Inc."
#define MyAppURL "http://www.aezo.cn/"
#define MyAppExeName "myexe.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{C13A07CE-BDF9-44A9-926B-543D19434CB1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=./inno_setup_out ; 可以使用绝对路径或相对路径，下同
OutputBaseFilename=myexe_setup_x64
SetupIconFile=./aezocn.ico
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files] ; 依赖文件或文件夹
Source: "..\demo-win32-x64\myexe.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\demo-win32-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
```

### 注册成windows服务

参考：https://github.com/winsw/winsw

### 设置开机启动

- linux设置到chkconfg
- windows参考 [开机启动java等程序](/_posts/extend/windows.md#开机启动java等程序)

## 常见错误

- `nested exception is java.lang.IllegalArgumentException: Could not resolve placeholder 'crm.tempFolder' in value "${crm.tempFolder}"`
	- 原因分析：一般由于存在多个`application`配置文件，然后并没有指定。则使用默认配置，运行时出现`No active profile set, falling back to default profiles: default`，从而缺少部分配置。实践时发现application.properties中已经配置了`spring.profiles.active=dev`，再idea中通过main方法启动时不报错，但是通过maven打包是测试不通过
	- 解决办法参考
		- [《maven.md#结合springboot》](/_posts/arch/maven.md#结合springboot)。实际中主要是没有将`src/main/resources`目录添加到maven的resource中
		- 或者在每中环境配置文件中都定义`crm.tempFolder`参数值

## springboot 2.0.1 改动及相关问题

- jpa

```java
// 获取单条记录
// spring boot 1.4.3
// User user = this.userRepositroy.findOne(id);
// User user = this.userRepositroy.getOne(id); // getOne获取的是代理对象；jpa1时，和findOne类似；jpa2时，getOne在jackjson转换时会报错，推荐使用findById
// spring boot 2.0.1
User user = this.userRepositroy.findById(id).get();
```
- 数据库循环引用，报错如下。参考：https://blog.csdn.net/Small_StarOne/article/details/106018215

```java
   org.springframework.boot.actuate.autoconfigure.jdbc.DataSourceHealthIndicatorAutoConfiguration
┌─────┐
|  dataSource
↑     ↓
|  scopedTarget.dataSource defined in class path resource [org/springframework/boot/autoconfigure/jdbc/DataSourceConfiguration$Hikari.class]
↑     ↓
|  org.springframework.boot.autoconfigure.jdbc.DataSourceInitializerInvoker
└─────┘
```



---

参考文章

[^1]: http://412887952-qq-com.iteye.com/blog/2322756 (h2介绍)
[^2]: https://stackoverflow.com/questions/31498682/spring-boot-intellij-embedded-database-headache (idea连接h2)
[^6]: http://www.cnblogs.com/ityouknow/p/6828919.html (Springboot中mongodb的使用)
[^7]: http://www.cnblogs.com/yjbjingcha/p/6752265.html (Spring在代码中获取bean的几种方式)
[^8]: http://blog.csdn.net/v2sking/article/details/72795742 (异步调用Async)
[^9]: https://spring.io/blog/2015/06/08/cors-support-in-spring-framework (Spring对CORS的支持)
[^11]: http://www.cnblogs.com/GoodHelper/p/7078381.html (WebSocket)
[^13]: https://blog.csdn.net/qq_35542689/article/details/81205472 (springboot在Windows(无jre)下打包并运行exe)
[^14]: http://blog.didispace.com/springbootmultidatasource/
[^15]: https://blog.csdn.net/neosmith/article/details/61202084
[^16]: https://ifengkou.github.io/spring_boot%E5%8A%A8%E6%80%81%E6%95%B0%E6%8D%AE%E6%BA%90%E9%85%8D%E7%BD%AE&%E8%BF%90%E8%A1%8C%E6%97%B6%E6%96%B0%E5%A2%9E%E6%95%B0%E6%8D%AE%E6%BA%90.html
[^17]: https://www.cnblogs.com/liaojie970/p/9396334.html
[^18]: https://zhuanlan.zhihu.com/p/81854008
[^19]: https://segmentfault.com/a/1190000021906586
[^20]: https://blog.teble.me/2019/11/05/SpringBoot-LocalDateTime-%E5%90%8E%E7%AB%AF%E6%8E%A5%E6%94%B6%E5%8F%82%E6%95%B0%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5/
[^21]: https://www.cnblogs.com/czy960731/p/11105166.html
[^22]: https://www.jianshu.com/p/f46699ea331a
