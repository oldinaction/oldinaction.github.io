---
layout: "post"
title: "mybatis"
date: "2017-05-22 15:05"
categories: [java]
tags: [mybatis, springboot]
---

## 简介

- [MyBatis3中文文档](http://www.mybatis.org/mybatis-3/zh/index.html)
- `MyBatis Generator`：mybatis代码生成(model/dao/mapper)，[文档](http://www.mybatis.org/generator/)

## SpringBoot整合mybatis [^1]

### 基本配置

- 引入依赖(mybatis-spring-boot-starter为mybatis提供的自动配置插件)

	```xml
	<!-- 自动配置 https://github.com/mybatis/spring-boot-starter -->
	<dependency>
		<groupId>org.mybatis.spring.boot</groupId>
		<artifactId>mybatis-spring-boot-starter</artifactId>
		<version>1.3.1</version>
	</dependency>

	<!--mybatis分页插件: https://github.com/pagehelper/Mybatis-PageHelper-->
	<dependency>
		<groupId>com.github.pagehelper</groupId>
		<artifactId>pagehelper</artifactId>
		<version>5.0.4</version>
	</dependency>
	```
- 启动类中加：`@MapperScan({"cn.aezo.springboot.mybatis.mapper", "cn.aezo.springboot.mybatis.mapperxml"})` // 声明需要扫描mapper接口的路径
- 配置

	```bash
	# 基于xml配置时需指明映射文件扫描位置；设置多个路径可用","分割，如："classpath:mapper/*.xml, classpath:mapper2/*.xml"
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

			<!--打印mybatis运行的sql语句到控制台。STDOUT表示调用System.out。-->
			<!-- 打印到日志，则需要在如logback.xml中加 <logger name="cn.aezo.video.dao" level="debug"/> 定义打印级别 -->
			<setting name="logImpl" value="STDOUT_LOGGING" />
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

### annotation版本(适合简单业务)

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
			UserInfo findByNickName(String nickName); // 一个参数可以省略@Param，多个需要进行指定(反射机制)

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
			PageHelper.startPage(pageNum, pageSize); // 默认查询第一页，显示5条数据（必须在实例化PageInfo之前）
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

- 基于注解的sql示例(**推荐**) [^2]

    - 用script标签包围，然后像xml语法一样书写
        
        ```java
        // Dao层，mybatis会基于此注解完成对应的实现
        // 可以理解为查询sql语句返回的是一个List<Map<String, Object>>(List里面必须为Map或其子类)。如果用Map<String, Object>接受返回值则默认取第一条数据
        @Select({ "<script>",
            "select h.help_id, h.apply_money, h.create_time, h.creator, h.description, h.is_comfort, h.is_valid, h.title, h.update_time, h.updater ",
            "   , e.name",
            " from th_help as h ",
            "   left join th_event e on e.event_id = h.event_id",
			"   left join th_group g on g.group_id = h.group_id ",
            " where 1=1 ",
			" <when test='plans != null and plans.size() > 0'>", // 其中大于号也可以使用`&gt;`来表示
            "   and g.plan_id in ",
			// in 的使用。item为当前元素，index为下标变量
            "   <foreach item='plan' index='index' collection='plans' open='(' separator=',' close=')'>",
            "       #{plan.planId}",
            "   </foreach>",
            " </when>",
			// like 的使用。此处必须使用concat进行字符串连接. oracle则需要使用 concat(concat('%',#{roleName}),'%')
            " <when test='help.title != null and help.title != '''> AND h.title like concat('%', #{help.title}, '%')</when>",
            " <when test='event.name != null'> AND e.name = #{event.name}", "</when>",
			// or 的使用(1 != 1 or .. or ..)
			" <when test='help.title != null and help.desc != null or help.start != null and help.end != null'> and (",
			"  <when test='help.title != null and help.desc != null>",
			"    help.title = #{help.title}",
			"  </when>",
			"  <when test='help.start != null and help.end != null>",
			"    or help.start = #{help.start} and help.end = #{help.end}",
			"  </when>",
			" ) </when>",
            "</script>" })
        List<Map<String, Object>> findHelps(@Param("help") Help help, @Param("event") Event event, @Param("plans") List<Plan> plans);
        
        // 配合分页插件使用
        public Object findHelps(Help help, Event event,
                @RequestParam(defaultValue = "1") Integer pageNum,
                @RequestParam(defaultValue = "10") Integer pageSize) {
            PageHelper.startPage(pageNum, pageSize);
            List users = helpMapper.findHelps(help, event);
            PageInfo pageUser = new PageInfo(users);

            return pageUser;
        }
	    ```

		- `<when>` 可进行嵌套使用
		- 双引号转义：`<when test='help.title != null and type = \"MY_TYPE\"'>`
		- **大于小于号需要转义**（>：`&gt;`, <：`&lt;`）
		- mysql当前时间获取`now()`，数据库日期型可和前台时间字符串进行比较
		- 数据库字段类型根据mybatis映射转换，`count(*)`转换成`Long`
		- mybatis会对Integer转换成字符串时，如果Integer类型值为0，则转换为空字符串。
			
			```xml
			<!-- 此时Integer status = 0;时，下列语句返回false. 所有Integer类型的不要加status != '' -->
			<if test="status != null and status != ''">
			    and status = #{status}   
			</if>  
			```

    - 用Provider去实现SQL拼接(适用于复杂sql)

        ```java
        public class OrderProvider {
            private final String TBL_ORDER = "tbl_order";

            public String queryOrderByParam(OrderPara param) {
                SQL sql = new SQL().SELECT("*").FROM(TBL_ORDER);
                String room = param.getRoom();
                if (StringUtils.hasText(room)) {
                    sql.WHERE("room LIKE #{room}");
                }
                Date myDate = param.getMyDate();
                if (myDate != null) {
                    sql.WHERE("mydate LIKE #{mydate}");
                }
                return sql.toString();
            }
        }

        public interface OrderDAO {
            @SelectProvider(type = OrderProvider.class, method = "queryOrderByParam")
            List<Order> queryOrderByParam(OrderParam param);
        }
        ```

### xml版本(适合复杂操作)

- `xml版本(适合复杂操作)`
	- Dao层：UserMapperXml.java

		```java
		public interface UserMapperXml {
			List<UserInfo> findAll();

			UserInfo getOne(Long id);

			int insert(UserInfo user); // 成功返回1

			int update(UserInfo user);

			int delete(Long id);
		}
		```
	- Dao实现(映射文件): UserMapper.xml(放在resources/mapper目录下)

		```xml
		<?xml version="1.0" encoding="UTF-8" ?>
		<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
		<!--http://www.mybatis.org/mybatis-3/zh/sqlmap-xml.html#-->
		<!--sql映射文件: namespace必须为实现接口名；每个sql是一个statement-->
		<mapper namespace="cn.aezo.springboot.mybatis.mapperxml.UserMapperXml">
			<!--resultMap结果集映射定义(用来描述如何从数据库结果集中来加载对象). resultType 与 resultMap 不能并用-->
			<resultMap id="UserInfoResultMap" type="cn.aezo.springboot.mybatis.model.UserInfo">
				<!--设置mybatis.configuration.map-underscore-to-camel-case=true则会自动对格式进行转换, 无效下面转换-->
				<!--<result column="group_id" property="groupId" jdbcType="BIGINT"/>-->
				<!--<result column="nick_name" property="nickName" jdbcType="VARCHAR"/>-->
			</resultMap>

			<!--sql:可被其他语句引用的可重用语句块. id:唯一的标识符，可被其它语句引用-->
			<sql id="UserInfoColumns"> id, group_id, nick_name, hobby </sql>

			<!--id对应接口的方法名; resultType(类全称或别名) 与 resultMap(自定义数据库字段与实体字段转换关系map) 不能并用; -->
			<!-- statementType: STATEMENT(statement)、PREPARED(preparedstatement, 默认)、CALLABLE(callablestatement)-->
			<!-- resultSetType: FORWARD_ONLY(游标向前滑动)，SCROLL_SENSITIVE(滚动敏感)，SCROLL_INSENSITIVE(不区分大小写的滚动)-->
			<select id="findAll" resultMap="UserInfoResultMap">
				select
				<include refid="UserInfoColumns"/>
				from user_info
			</select>

			<!--parameterType传入参数类型. 使用typeAliases进行类型别名映射后可写成resultType="userInfo"(自动扫描包mybatis.type-aliases-package, 默认该包下的类名首字母小写为别名) -->
			<!--如果返回结果使用resultType="cn.aezo.springboot.mybatis.model.UserInfo", 则nickName，groupId则为null(数据库中下划线对应实体驼峰转换失败，解决办法：设置mybatis.configuration.map-underscore-to-camel-case=true). 此处使用resultMap指明字段对应关系-->
			<!-- #{}是实现的是PrepareStatement，${}实现的是普通Statement -->
			<select id="getOne" parameterType="java.lang.Long" resultType="userInfo">
				select
				<include refid="UserInfoColumns"/>
				from user_info
				where id = #{id}
			</select>

			<!-- 获取自增主键：mysql为例 -->
			<!-- 方式一：keyProperty(主键对应Model的属性名)和useGeneratedKeys(是否使用JDBC来获取内部自增主键，默认false)联合使用返回自增的主键(可用于insert和update语句) -->
			<!-- 方式二：<selectKey keyProperty="id" resultType="long">select LAST_INSERT_ID()</selectKey> -->
			<!-- 获取方式：userMapper.insert(userInfo); userInfo.getUserId(); -->
			<insert id="insert" keyProperty="userId" useGeneratedKeys="true" parameterType="cn.aezo.springboot.mybatis.model.UserInfo">
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

- xml联表查询举例

	```xml
    <select id="getClass" parameterType="int" resultMap="ClassResultMap">
        select * from class c, teacher t,student s where c.teacher_id = t.t_id and c.C_id = s.class_id and  c.c_id = #{id}
    </select>

	<!--此处Classes类中仍然需要保存一个Teacher的引用和一个List<Student>的引用-->
    <resultMap type="cn.aezo.demo.Classes" id="ClassResultMap">
		<!--一个 ID 结果;标记结果作为 ID 可以帮助提高整体效能-->
        <id property="id" column="c_id"/>
		<!--注入到字段或 JavaBean 属性的普通结果-->
        <result property="name" column="c_name"/>
		<!-- association字面意思关联，这里只专门做一对一关联； property表示是cn.aezo.demo.Classes中的属性名称； javaType表示该属性是什么类型对象 -->
        <association property="teacher" column="teacher_id" javaType="cn.aezo.demo.Teacher">
            <id property="id" column="t_id"/>
            <result property="name" column="t_name"/>
        </association>
        <!-- ofType指定students集合中的对象类型 -->
        <collection property="students" ofType="cn.aezo.demo.Student">
            <id property="id" column="s_id"/>
            <result property="name" column="s_name"/>
        </collection>
    </resultMap>
	```

- 查询sql举例

	```xml
	<select id="selectInsuranceListByCreator" resultType="cn.aezo.demo.ThMyInsuranceListView" parameterType="java.lang.Long" >
		SELECT
			t2.insurance_compay insuranceCompany,
			t2.insurance_name insurancePlan,
			t1.is_valid insuranceStatus,
			t1.order_id orderId
		FROM
			th_insurance_order t1,
			th_insurance t2
		WHERE
			t1.creator = #{creator, jdbcType=BIGINT}
		AND t1.insurance_id = t2.insurance_id
	</select>
	```
	- `insuranceCompany`会对应ThMyInsuranceListView中的字段

- xml文件修改无需重新部署，立即生效
- 关于`<`、`>`转义字符
	- `<` 转成 `&lt;`，`>=` 转成 `&gt;=`等
	- 使用`<![CDATA[ when min(starttime) <= '12:00' and max(endtime) <= '12:00' ]]>`

### 控制主键自增和获取自增主键值

- 获取自增主键(mysql为例，需要数据库设置主键自增) [^3]
	- 方式一：keyProperty(主键对应Model的属性名)和useGeneratedKeys(是否使用JDBC来获取内部自增主键，默认false)联合使用返回自增的主键(可用于insert和update语句)
	- 方式二：`<selectKey keyProperty="id" resultType="long">select LAST_INSERT_ID()</selectKey>`
	- 获取方式：`userMapper.insert(userInfo); userInfo.getUserId();`

### MyBatis、Java、Oracle、MySql数据类型对应关系

- Mybatis的数据类型用JDBC的数据类型
- JDBC数据类型转换


JDBC | Java | Mysql | Oracle
---------|----------|---------|---------
Integer | Integer | Int | 
Bigint  | Long | Bigint | Number
Numeric  | Long |  | Number
Timestamp| Date | Datetime | Date
Date | Date | Date | Date
Decimal | BigDecimal | Decimal | Number(20, 6) 
Char |  | Char | Char
 Blob |  | Blob | Blob
 Clob |  | Text | Clob

## MyBatis Generator

- 使用`MyBatis Generator`自动生成model/dao/mapper
- 官方文档：[http://www.mybatis.org/generator/index.html](http://www.mybatis.org/generator/index.html)
- 生成方式有多种(此处介绍maven插件的方式)
	- maven配置

		```xml
		<build>
			<plugins>
				<!-- mybatis(mapper等)自动生成 -->
				<plugin>
					<groupId>org.mybatis.generator</groupId>
					<artifactId>mybatis-generator-maven-plugin</artifactId>
					<version>1.3.5</version>
					<!--maven可执行命令-->
					<executions>
						<execution>
							<id>Generate MyBatis Artifacts</id>
							<goals>
								<goal>generate</goal>
							</goals>
						</execution>
					</executions>
				</plugin>
			</plugins>
		</build>
		```
	- resources目录添加文件：`generatorConfig.xml`

		```xml
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE generatorConfiguration
				PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
				"http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">
		<generatorConfiguration>
			<!--数据库驱动 -->
			<classPathEntry location="C:\Users\smalle\.m2\repository\mysql\mysql-connector-java\5.1.43\mysql-connector-java-5.1.43.jar" />
			<context id="MySQLTables" targetRuntime="MyBatis3" defaultModelType="flat">
				
				<!-- 为了防止生成的代码中有很多注释，比较难看 -->
				<commentGenerator>
					<property name="suppressDate" value="true" />
					<property name="suppressAllComments" value="true" />
				</commentGenerator>

				<!--数据库链接地址账号密码 -->
				<jdbcConnection
						driverClass="com.mysql.jdbc.Driver"
						connectionURL="jdbc:mysql://localhost:3306/springboot"
						userId="root"
						password="root">
				</jdbcConnection>

				<javaTypeResolver>
					<property name="forceBigDecimals" value="false" />
				</javaTypeResolver>

				<!--生成Model类存放位置：targetPackage为model对应的包名；targetProject为项目根目录，此处相对当前项目，还可写成D:/mydemo/src/main/java -->
				<javaModelGenerator
						targetPackage="cn.aezo.springboot.mybatis.generator.model"
						targetProject="src/main/java">
					<property name="enableSubPackages" value="true" />
					<!-- 是否对类CHAR类型的列的数据进行trim操作 -->  
					<property name="trimStrings" value="true" />
				</javaModelGenerator>

				<!--生成映射文件存放位置，会存放在src/main/resources/mapper目录下(自动创建mapper目录) -->
				<sqlMapGenerator
						targetPackage="mapper"
						targetProject="src/main/resources">
					<property name="enableSubPackages" value="true" />
				</sqlMapGenerator>

				<!--生成Dao类存放位置 -->
				<javaClientGenerator
						type="XMLMAPPER"
						targetPackage="cn.aezo.springboot.mybatis.generator.dao"
						targetProject="src/main/java">
					<property name="enableSubPackages" value="true" />
				</javaClientGenerator>

				<!-- 读取所有的table标签，有几个table标签就解析几个 -->
				<!-- %标识根据表名生成，tableName="t_%"表示只生成t_开头的表名 -->
				<table tableName="%">
					<!-- 
						1、生成selectKey语句，为mybatis生成获取自增主键值语句(必须数据库字段设置成自增)
						2、column表的字段名(不支持通配符，因此为了方便可将所有表的主键名设置为id)
						3、sqlStatement="MySql/DB2/SqlServer等"
						4、identity：true表示column代表的是主键，会在插入记录之后获取自增值替换对应model的id值(自增需要由数据库提供)，实际的insert语句将不含有主键字段; false表示非主键，会在插入记录获取自增值并替换model的id(如从序列中获取), 此时insert语句含有主键字段
						5、最终生成的语句如
						<selectKey keyProperty="userId" order="AFTER" resultType="java.lang.Long">
						SELECT LAST_INSERT_ID()
						</selectKey>
					-->
					<generatedKey column="id" sqlStatement="MySql" identity="true" />
				</table>

				<!-- 去掉表前缀：生成之后的文件名字User.java等。enableCountByExample标识是否使用Example -->
				<table tableName="t_user" domainObjectName="User"
					enableCountByExample="false" enableDeleteByExample="false"
					enableSelectByExample="false" enableUpdateByExample="false">
					<!-- 去掉字段前缀 `t_` -->
					<property name="useActualColumnNames" value="false"/>
					<columnRenamingRule searchString="^t_" replaceString=""/>
				</table>
			</context>
		</generatorConfiguration>
		```
	- 进入到pom.xml目录，cmd执行命令生成文件：`mvn mybatis-generator:generate`
	- 生成Mapper中Example的使用：http://www.mybatis.org/generator/generatedobjects/exampleClassUsage.html

		```java
		UserExample userExample = new UserExample();
        userExample.createCriteria().andUsernameEqualTo("smalle")
					.andSexEqualTo(1);
		userExample.setOrderByClause("username asc");

        List<User> users =  userMapper.selectByExample(userExample);
		```
- 通过java代码调用mybatis-generator生成
	- 引入依赖

		```xml
		<dependency>
			<groupId>org.mybatis.generator</groupId>
			<artifactId>mybatis-generator-core</artifactId>
			<version>1.3.5</version>
		</dependency>
		```
	- 关键代码

		```java
		List<String> warnings = new ArrayList<>();
        boolean overwrite = true;
        File configFile = new File("generatorConfig.xml");
        ConfigurationParser cp = new ConfigurationParser(warnings);
        try {
            Configuration config = cp.parseConfiguration(configFile);
            DefaultShellCallback callback = new DefaultShellCallback(overwrite);
            MyBatisGenerator myBatisGenerator = new MyBatisGenerator(config, callback, warnings);
            myBatisGenerator.generate(null);
        } catch (Exception e) {
            e.printStackTrace();
        }
		```
- 生成oracle项目：先将oracle表转成mysql数据表，参考《mysql-db.md》，再生成项目
	- 配置文件设置成`<generatedKey column="id" sqlStatement="MySql" identity="false" />`中identity="false"为了生成id的insert语句（oracle需要通过序列来完成）
	- 修改生成的`<selectKey>`语句为根据序列获取主键

---

参考文章

[^1]: [整合mybatis](http://blog.csdn.net/gebitan505/article/details/54929287)
[^2]: [@Select注解中当参数为空则不添加该参数的判断](https://segmentfault.com/q/1010000006875476)
[^3]: [Mybatis操作数据库的主键自增长](https://www.cnblogs.com/panie2015/p/5807683.html)

TODO

- Mybatis Generator添加注释：https://www.cnblogs.com/NieXiaoHui/p/6094144.html