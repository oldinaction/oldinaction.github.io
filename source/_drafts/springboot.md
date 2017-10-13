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
- `rabbitmq`(1.5.2)

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

## 请求及响应

- 相关配置

	```
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

	```properties
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

- 引入数据库和jpa

	```xml
	<!--jpa是ORM框架的API(基于hibernate完成), jdbc是java操作数据库的API(执行sql语句)-->
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-data-jpa</artifactId>
	</dependency>
	```
- 数据库添加配置

	```properties
	## spring.jpa.database=MYSQL
	# 自动执行ddl语句(create/create-drop/update).
	spring.jpa.hibernate.ddl-auto=update
	# 打印sql执行语句, 查询和建表
	spring.jpa.show-sql=true
	# 格式化打印语句
	spring.jpa.properties.hibernate.format_sql=true
	# 懒加载配置
	spring.jpa.properties.hibernate.enable_lazy_load_no_trans=true
	```
- `UserDao.java`示例

	```java
	// 继承了JpaRepository(JpaRepository又继承了CrudRepository已经定义好了基本增删查改相关方法)
	public interface UserClassDao extends JpaRepository<UserClass, Long> {
		// spring data 根据属性名和查询关键字自动生成查询方法(spring data会自动实现)
		UserClass findByClassName(String className);
	}
	```
- `UserController.java`示例

	```java
	@Autowired
    UserDao userDao;

	@RequestMapping(value = "/users")
    public List<User> findUsers(User user) {
        // 前台传一个类似的user对象，会把此对象做作为条件进行查询
        Example<User> example = Example.of(user);

        return userDao.findAll(example);
    }
	```
- `@Query`查询示例

		```java
		// UserDao定义的查询语句. org.springframework.data.jpa.repository.Query
		@Query("select u.classId, u.sex, count(u.classId) as count from User u " +
				"   where u.password = :password " +
				"   group by u.classId, u.sex")
		List<Object[]> countUser(@Param("password") String password);

		// 原生sql
		@Query(value = "select u.* from user u, user_class uc where uc.class_id = u.class_id and uc.class_name = 'one'",
				nativeQuery = true)
		List<Object[]> findUsers();


		// @Query自定义sql语句. http://127.0.0.1:9526/api/user-query
		@RequestMapping(value = "/user-query")
		public Map<String, Object> query() {
			Map<String, Object> result = new HashMap<>();

			result.put("count", userDao.countUser("123456"));
			result.put("users", userDao.findUsers());

			return result;
		}
		```

		- 执行结果

			```javascript
			{
				count: [
					[
						1,
						1,
						2
					]
				],
				users: [
					[
						1,
						1,
						"smalle",
						"123456",
						1
					],
					[
						2,
						1,
						"aezo",
						"123456",
						1
					]
				]
			}
			```
- `Pageable`分页查询：Pageable里面常用参数`page`(页码, 0代表第一页)、`size`(页长)、`order`(排序规则) [^4]

	```java
	// 查询UserClass信息, 并获取子表User的前5条数据. http://127.0.0.1:9526/api/classes?className=one
    @RequestMapping(value = "/classes")
    public Map<String, Object> findClasses(UserClass userClass) {
        Map<String, Object> result = new HashMap<>();

        // 前台传一个类似的UserClass对象，会把此对象做作为条件进行查询
        Example<UserClass> example = Example.of(userClass);
        result.put("userClass", userClassDao.findAll(example));

        // 分页获取User数据：如果使用classes.getUsers()获取则需要写实体对应关系(@OneToMany), 且会产生外键. 此时单表查询不需关联关系
        Pageable pageable = new PageRequest(0, 5, new Sort(Sort.Direction.DESC, "id")); // 获取第1页, 每页显示5条, 按照id排序
        result.put("users", userDao.findAll(pageable));

        return result;
    }

	// 分页(page为页码, 0代表第1页; size代表页长). http://127.0.0.1:9526/api/users-page?page=0
    // org.springframework.data.domain.Pageable、org.springframework.data.domain.Example
    @RequestMapping(value = "/users-page")
    public Page<User> findUsersPage(
            @RequestParam(value = "username", defaultValue = "smalle") String username,
            Pageable pageable) {
        // 前台传一个类似的user对象，会把此对象做作为条件进行查询
        Example<User> example = Example.of(new User(username));

        return userDao.findAll(example, pageable);
    }
	```

	- 查询UserClass信息返回数据如下(已经美化去除引号)：

		```javascript
		{
			userClass: [
				{
					classId: 1,
					className: "one"
				}
			],
			users: {
				content: [
					{
						id: 2,
						classId: 1,
						username: "aezo",
						password: "123456",
						sex: 1
					},
					{
						id: 1,
						classId: 1,
						username: "smalle",
						password: "123456",
						sex: 1
					}
				],
				totalElements: 2,
				totalPages: 1,
				last: true,
				number: 0,
				size: 5,
				first: true,
				numberOfElements: 2,
				sort: [
					{
						direction: "DESC",
						property: "id",
						ignoreCase: false,
						nullHandling: "NATIVE",
						ascending: false,
						descending: true
					}
				]
			}
		}
		```

### 整合mybatis [^5]

- 引入依赖(mybatis-spring-boot-starter为mybatis提供的自动配置插件)

	```xml
	<!-- https://github.com/mybatis/spring-boot-starter -->
	<dependency>
		<groupId>org.mybatis.spring.boot</groupId>
		<artifactId>mybatis-spring-boot-starter</artifactId>
		<version>1.3.1</version>
	</dependency>
	```
- 启动类中加：`@MapperScan({"cn.aezo.springboot.mybatis.mapper", "cn.aezo.springboot.mybatis.mapperxml"})` // 声明需要扫描mapper的路径
- 配置

	```properties
	# 基于xml配置时需指明映射文件扫描位置
	mybatis.mapper-locations=classpath:mapper/*.xml
	# mybatis配置文件位置(mybatis.config-location和mybatis.configuration...不能同时使用), 由于自动配置对插件支持不够暂时使用xml配置
	mybatis.config-location=classpath:mybatis-config.xml

	# 字段格式对应关系：数据库字段为下划线, model字段为驼峰标识(不设定则需要通过resultMap进行转换)
	#mybatis.configuration.map-underscore-to-camel-case=true
	# 类型别名定义扫描的包(可结合@Alias使用, 默认是类名首字母小写)
	#mybatis.type-aliases-package=cn.aezo.springboot.mybatis.model
	```
- mybatis配置文件: `mybatis-config.xml`

	```xml
	<?xml version="1.0" encoding="UTF-8" ?>
	<!DOCTYPE configuration PUBLIC "-//mybatis.org//DTD Config 3.0//EN" "http://mybatis.org/dtd/mybatis-3-config.dtd">
	<!--在application.properties中使用了mybatis.configuration进行配置，无需此文件(传统配置)-->
	<configuration>
		<settings>
			<!--字段格式对应关系：数据库字段为下划线, model字段为驼峰标识(不设定则需要通过resultMap进行转换)-->
			<setting name="mapUnderscoreToCamelCase" value="true"/>
		</settings>

		<!--类型别名定义-->
		<typeAliases>
			<!--定义需要扫描的包-->
			<package name="cn.aezo.springboot.mybatis.model"/>

			<!--定义后可在映射文件中间的parameterType等字段中使用userInfo代替cn.aezo.springboot.mybatis.model.UserInfo-->
			<!--<typeAlias alias="userInfo" type="cn.aezo.springboot.mybatis.model.UserInfo" />-->
		</typeAliases>

		<plugins>
			<!-- 分页插件 -->
			<!-- 5.0.0以后使用com.github.pagehelper.PageInterceptor作为拦截器 -->
			<plugin interceptor="com.github.pagehelper.PageInterceptor">
				<!--更多参数配置：https://github.com/pagehelper/Mybatis-PageHelper/blob/master/wikis/zh/HowToUse.md-->
				<!--<property name="pageSizeZero" value="true"/>-->
			</plugin>
		</plugins>
	</configuration>
	```
- Model：UserInfo/ClassInfo等无需任何注解.(其中HobbyEnum是一个枚举类)
- `annotation版本(适合简单业务)`
	- Dao层：UserMapper.java

		```java
		// @Mapper // 在启动类中定义需要扫码mapper的包：@MapperScan("cn.aezo.springboot.mybatis.mapper"), 则此处无需声明@Mapper
		public interface UserMapper {
			// 此处注入变量可以使用#或者$, 区别：# 创建的是一个prepared statement语句, $ 符创建的是一个inlined statement语句
			@Select("select * from user_info where nick_name = #{nickName}")
			// (使用配置<setting name="mapUnderscoreToCamelCase" value="true"/>因此无需转换) 数据库字段名和model字段名或javaType不一致的均需要@Result转换
			// @Results({
			//         @Result(property = "hobby",  column = "hobby", javaType = HobbyEnum.class),
			//         @Result(property = "nickName", column = "nick_name"),
			//         @Result(property = "groupId", column = "group_Id")
			// })
			UserInfo findByNickName(String nickName);

			@Select("select * from user_info")
			List<UserInfo> findAll();

			@Insert("insert into user_info(nick_name, group_id, hobby) values(#{nickName}, #{groupId}, #{hobby})")
			void insert(UserInfo userInfo);

			@Update("update user_info set nick_name = #{nickName}, hobby = #{hobby} where id = #{id}")
			void update(UserInfo userInfo);

			@Delete("delete from user_info where id = #{id}")
			void delete(Long id);
		}
		```
	- 分页

		```java
		// 分页查询：http://localhost:9526/api/users
		@RequestMapping(value = "/users")
		public PageInfo showAllUser(
				@RequestParam(defaultValue = "1") Integer pageNum,
				@RequestParam(defaultValue = "5") Integer pageSize) {
			PageHelper.startPage(pageNum, pageSize); // 默认查询第一页，显示5条数据
			List<UserInfo> users = userMapper.findAll(); // 第一条执行的SQL语句会被分页，实际上输出users是page对象
			PageInfo<UserInfo> pageUser = new PageInfo<UserInfo>(users); // 将users对象绑定到pageInfo

			return pageUser;
		}
		```

		- 分页查询结果

		```javascript
		{
			pageNum: 1,
			pageSize: 5,
			size: 2,
			startRow: 1,
			endRow: 2,
			total: 2,
			pages: 1,
			list: [
				{
					id: 1,
					groupId: 1,
					nickName: "smalle",
					hobby: "GAME"
				},
				{
					id: 2,
					groupId: 1,
					nickName: "aezo",
					hobby: "CODE"
				}
			],
			prePage: 0,
			nextPage: 0,
			isFirstPage: true,
			isLastPage: true,
			hasPreviousPage: false,
			hasNextPage: false,
			navigatePages: 8,
			navigatepageNums: [
				1
			],
			navigateFirstPage: 1,
			navigateLastPage: 1,
			firstPage: 1,
			lastPage: 1
		}
		```
	- 测试

		```java
		@Test
		public void testFindByNickName() {
			UserInfo userInfo = userMapper.findByNickName("smalle");
			System.out.println("userInfo = " + userInfo);
		}

		@Test
		public void testInsert() throws Exception {
			userMapper.insert(new UserInfo("test", 1L, HobbyEnum.READ));
		}
		```
- `xml版本(适合复杂操作)`
	- Dao层：UserMapperXml.java

		```java
		public interface UserMapperXml {
			List<UserInfo> findAll();

			UserInfo getOne(Long id);

			void insert(UserInfo user);

			void update(UserInfo user);

			void delete(Long id);
		}
		```
	- Dao实现(映射文件): UserMapper.xml(放在resources/mapper目录下)

		```xml
		<?xml version="1.0" encoding="UTF-8" ?>
		<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
		<!--http://www.mybatis.org/mybatis-3/zh/sqlmap-xml.html#-->
		<!--sql映射文件: namespace必须为实现接口名；每个sql是一个statement-->
		<mapper namespace="cn.aezo.springboot.mybatis.mapperxml.UserMapperXml">
			<!--resultMap结果集映射定义(用来描述如何从数据库结果集中来加载对象). resultType 与resultMap 不能并用-->
			<resultMap id="UserInfoResultMap" type="cn.aezo.springboot.mybatis.model.UserInfo">
				<!--设置mybatis.configuration.map-underscore-to-camel-case=true则会自动对格式进行转换, 无效下面转换-->
				<!--<result column="group_id" property="groupId" jdbcType="BIGINT"/>-->
				<!--<result column="nick_name" property="nickName" jdbcType="VARCHAR"/>-->
			</resultMap>

			<!--sql:可被其他语句引用的可重用语句块. id:唯一的标识符，可被其它语句引用-->
			<sql id="UserInfoColumns"> id, group_id, nick_name, hobby </sql>

			<!--id对应接口的方法名; resultType 与resultMap 不能并用; -->
			<!-- statementType: STATEMENT(statement)、PREPARED(preparedstatement, 默认)、CALLABLE(callablestatement)-->
			<!-- resultSetType: FORWARD_ONLY(游标向前滑动)，SCROLL_SENSITIVE(滚动敏感)，SCROLL_INSENSITIVE(不区分大小写的滚动)-->
			<select id="findAll" resultMap="UserInfoResultMap">
				select
				<include refid="UserInfoColumns"/>
				from user_info
			</select>

			<!--parameterType传入参数类型. 使用typeAliases进行类型别名映射后可写成resultType="userInfo"(自动扫描包mybatis.type-aliases-package, 默认该包下的类名首字母小写为别名) -->
			<!--如果返回结果使用resultType="cn.aezo.springboot.mybatis.model.UserInfo", 则nickName，groupId则为null. 此处使用resultMap指明字段对应关系-->
			<!-- #{}是实现的是PrepareStatement，${}实现的是普通Statement -->
			<select id="getOne" parameterType="java.lang.Long" resultType="userInfo">
				select
				<include refid="UserInfoColumns"/>
				from user_info
				where id = #{id}
			</select>

			<insert id="insert" parameterType="cn.aezo.springboot.mybatis.model.UserInfo">
				insert into
				user_info
				(nick_name, group_id, hobby)
				values
				(#{nickName}, #{groupId}, #{hobby})
			</insert>

			<update id="update" parameterType="cn.aezo.springboot.mybatis.model.UserInfo">
				update
				user_info
				set
				<!--动态sql, 标签：if、choose (when, otherwise)、trim (where, set)、foreach-->
				<if test="nickName != null">nick_name = #{nickName},</if>
				hobby = #{hobby}
				where
				id = #{id}
			</update>

			<delete id="delete" parameterType="java.lang.Long">
				delete from
				user_info
				where
				id = #{id}
			</delete>
		</mapper>
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

### 使用H2数据库

- h2简介 [^1]：内存数据库（Embedded database或in-momery database）具有配置简单、启动速度快、尤其是其可测试性等优点，使其成为开发过程中非常有用的轻量级数据库。在spring中支持HSQL、H2和Derby三种数据库
- [官网：http://h2database.com/html/main.html](http://h2database.com/html/main.html)
- springboot整合
	- 添加依赖(jpa等省略)

		```
		<dependency>
			<groupId>com.h2database</groupId>
			<artifactId>h2</artifactId>
			<scope>runtime</scope>
		</dependency>
		```
	- 连接配置

		```
		spring:
		  datasource:
			# 用户名密码会根据填写的生成(默认生成的用户名为sa, 密码为空)
			url: jdbc:h2:~/.h2/minions;AUTO_SERVER=true;
			# 用户名密码会根据填写的生成(默认生成的用户名为sa, 密码为空).
			# 如果已经生成了数据库文件(同时也生成了密码), 那么再修改此处用户名密码将无法连接数据库
			username: sa
			password: sa
			driver-class-name: org.h2.Driver
		# h2 web console
		# 登录配置Generic H2 (Server)  jdbc:h2:~/.h2/minions;AUTO_SERVER=true;  sa/sa
		# 推荐使用IDEA的数据库工具
		#  h2:
		#    console:
		#      # 程序开启时就会启动h2 web consloe
		#      enabled: true
		#      # 访问路径: http://localhost:${server.port}/h2-console
		#      path: /h2-console
		#      settings:
		#        # 运行远程访问h2 web consloe
		#        web-allow-others: true
		```
	- 配置说明
		- `jdbc:h2:file:~/.h2/minions;`文件型存储(默认可省略file:). `jdbc:h2:minions;`则代表在当前目录(运行h2 jar的位置)生成数据库文件
		- `jdbc:h2:mem:my_db_name;`内存型存储(在连接的瞬间即可创建数据库)，程序关掉则内存数据丢失
		- `~` 这个符号代表的就是当前登录到操作系统的用户对应的用户目录. `minions`代表数据库名(会在~/.h2目录生成minions.mv.db文件)
		- `AUTO_SERVER=true;`表示以TCP服务形式启动数据库. 否则项目启动(数据库启动)后, idea无法连接数据库(`AUTO_SERVER_PORT=9092;`可指明端口, 不指明会的话自动识别)
	- IDEA数据库工具使用 [^2]
		- Url: `jdbc:h2:~/.h2/minions;AUTO_SERVER=true;`
		- Url类型：`Remote`
		- 用户名/密码：`sa/sa`
		- 其他都不需要填写(url处可能报红可忽略)

## 企业级开发

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
[^4]: [hibernate查询分页](http://www.cnblogs.com/softidea/p/6287788.html)
[^5]: [整合mybatis](http://blog.csdn.net/gebitan505/article/details/54929287)
