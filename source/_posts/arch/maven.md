---
layout: "post"
title: "maven"
date: "2016-12-29 10:18"
categories: [arch]
tags: [maven]
---

## maven简介

## maven实战

### maven镜像修改

- 在~/.m2目录下的settings.xml文件中，（如果该文件不存在，则需要从maven/conf目录下拷贝一份），找到<mirrors>标签，添加如下子标签(windows/linux均可)

	```xml
		<mirror> 
			<id>alimaven</id>  
			<name>aliyun maven</name>  
			<url>http://maven.aliyun.com/nexus/content/groups/public/</url>
			<mirrorOf>central</mirrorOf>          
		</mirror>  
	```

### maven父子项目

- parents主要配置如下：`pom.xml`

	```xml
	<groupId>cn.aezo</groupId>
	<artifactId>smtools</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<!-- 打包类型必须为pom -->
	<packaging>pom</packaging>

	<name>smtools</name>
	<description>smtools</description>

	<modules>
		<module>utils</module>
		<module>demo</module>
	</modules>

	<properties></properties>
	<!--依赖形式一：父项目的依赖会被子项目自动继承-->
	<dependencies></dependencies>

	<!--依赖形式二：该节点下的依赖关系只是为了统一版本号，不会被子项目自动继承，除非子项目主动引用-->
	<!--好处是子项目可以不用写版本号 -->
	<dependencyManagement>
		<dependencies></dependencies>
	<dependencyManagement>
	```

- child

	```xml
	<groupId>cn.aezo</groupId>
	<artifactId>demo</artifactId>
	<packaging>jar</packaging>

	<!--声明父项目坐标-->
	<parent>
		<groupId>cn.aezo</groupId>
		<artifactId>smtools</artifactId>
		<version>0.0.1-SNAPSHOT</version>
		<!-- 父项目的pom.xml文件的相对路径。相对路径允许你选择一个不同的路径。 -->
		<!-- <relativePath/>的默认值是../pom.xml。Maven首先在构建当前项目的地方寻找父项目的pom，其次在文件系统的这个位置（relativePath位置），然后在本地仓库，最后在远程仓库寻找父项目的pom -->
		<!-- 建议写上，否则仅打包子项目的时候会出错 -->
		<relativePath>../pom.xml</relativePath>
	</parent>

	<properties></properties>
	<!--如果父项目使用了dependencyManagement, 如果此处添加的因子在其中则不用写版本号-->
	<dependencies>
		<!--依赖于此项目的其他模块:此时idea的Dependencies可看到相应的依赖关系-->
		<dependency>
			<groupId>cn.aezo</groupId>
			<artifactId>utils</artifactId>
			<!--project.version表示当前项目(此pom文件所在的模块/项目)的版本-->
			<version>${project.version}</version>
		</dependency>
	</dependencies>
	```

- 子项目打包：进入到子项目目录，运行`mvn package`(注意要指明`relativePath`)

### maven项目依赖本地jar包

- 安装jar包(test-1.0.0.jar)到本地：`mvn install:install-file -Dfile=D:/test-1.0.0.jar -DgroupId=cn.aezo -DartifactId=test -Dversion=1.0.0 -Dpackaging=jar`
	- 如果jar包包含pom信息则可直接安装`mvn install:install-file -Dfile=D:/test-1.0.0.jar`
- 再按照常规的方式应用
	
	```xml
	<dependency>
    	<groupId>cn.aezo</groupId>
    	<artifactId>test</artifactId>
    	<version>1.0.0</version>
    </dependency>
	```

> 以下两种方法不推荐：这样添加之后，编译是可以通过的，但是打包还会会从本地maven库里取相应的jar（如果你本地maven库里没有，则不会打包到工程里），而不是把你配置的jar文件打包进去，所以需要打包完成后将对应的jar添加到项目jar的lib目录中

- 法一：依赖写法(只能一个jar一个jar的添加)

    ```xml
    <!--groupId等是从jar包的META-INF中获得; 其中scope必须加; ${basedir}为maven内置参数，标识项目根目录-->
    <dependency>
    	<groupId>cn.aezo</groupId>
    	<artifactId>utils</artifactId>
    	<version>0.0.1-SNAPSHOT</version>
        <scope>system</scope>
    	<systemPath>${basedir}/src/main/resources/lib/smtools-utils-0.0.1-SNAPSHOT.jar</systemPath>
    </dependency>

	<!-- springboot专用 -->
	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
				<configuration>
					<!--把项目打成jar，同时把本地jar包也引入进去：直接给springboot的打包插件引入此行-->
					<includeSystemScope>true</includeSystemScope>
				</configuration>
			</plugin>
		</plugins>
	</build>
    ```

- 法二：在`build-plugins`节点加以下插件(可获取到目录下所有jar)(未测试通过)

    ```xml
    <plugin>
    	<artifactId>maven-compiler-plugin</artifactId>
    	<configuration>
            <!--
            <source>1.8</source>
            <target>1.8</target>
            <encoding>UTF-8</encoding>
            -->
    		<compilerArguments>
    			<extdirs>src/main/resources/lib</extdirs>
    		</compilerArguments>
    	</configuration>
    </plugin>
    ```

### 利用github创建仓库 [^1]

- github新建项目maven-repo，并下载到本地目录，如`D:/GitRepositories/maven-repo`
- 进入到项目pom.xml所在目录，运行命令：
	- `mvn deploy -DaltDeploymentRepository=oldinaction-maven-repo::default::file:D:/GitRepositories/maven-repo -DskipTests`(此仓库永远是master分支即可，其他项目以不同的分支和版本往此目录提交)
	- 将项目部署到`D:/GitRepositories/maven-repo`目录，项目id为`oldinaction-maven-repo`，`-DskipTests`跳过测试进行部署
- 提交到github(**注意jar包不要习惯性的ignore**)
- 配置maven远程仓库

	```xml
	<!-- 优先读取本地库 -->
	<repositories>
        <repository>
            <id>oldinaction-maven-repo</id>
            <url>https://raw.github.com/oldinaction/maven-repo/master/</url>
			<!--或者访问本地-->
			<!--<url>file:D:/GitRepositories/maven-repo/</url>-->
        </repository>
    </repositories>
	```
	- maven的repository并没有优先级的配置，也不能单独为某些依赖配置repository。所以如果项目配置了多个repository，在首次编绎时会依次尝试下载依赖，如果没有找到，尝试下一个
	- 其中`<url>https://raw.github.com/{github-username}/{github-repository}/{github-branch}/</url>`，https://raw.github.com 是github的raw站点，浏览器不能访问目录只能访问单个文件
- 配置依赖(会自动将仓库中的数据再下载到本地仓库`.m2`目录)

	```xml
	<dependency>
		<groupId>cn.aezo</groupId>
		<artifactId>utils</artifactId>
		<version>sm-minions-1.0</version>
	</dependency>
	```

## 安装和打包

- 安装：
	- 基于源码安装：`mvn install` (需要进入到源码的pom.xml目录)
	- 基于jar包安装：`mvn install:install-file -Dfile=D:/test-1.0.0.jar -DgroupId=cn.aezo -DartifactId=test -Dversion=1.0.0 -Dpackaging=jar`
		- 如果jar包包含pom信息则可直接安装`mvn install:install-file -Dfile=D:/test-1.0.0.jar`
    - 说明
		- 执行安装命令后，会自动将项目打包后放到maven本地的home目录(.m2)。之后其他项目可进行引用(按照常规方式引用)
		- 如果有pom.xml建议安装到本地再进行引用，(下面两种方式)否则编译的时候不会报错，但是运行时这些本地jar依赖就找不到(如：`nested exception is java.lang.NoClassDefFoundError`)
		- 有些install时则运行单元测试时候会报错，导致安装/打包失败。可尝试跳过测试进行安装(`mvn install -DskipTests`)。如：阿里云SMS服务aliyun-java-sdk-core:3.2.3就是如此
- 打包命令：`mvn package` (`mvn clean package` 清理并打包)
- 跳过测试进行打包：`mvn install -DskipTests` / `mvn package -DskipTests`.
    - 方式二:

		```xml
		<build>
			<plugins>
				<plugin>
					<groupId>org.apache.maven.plugins</groupId>
					<artifactId>maven-surefire-plugin</artifactId>
					<version>2.18.1</version>
					<configuration>
						<skipTests>true</skipTests>
					</configuration>
				</plugin>
			</plugins>
		</build>
		```
- 在idea中使用`Terminal`进行项目打包(`mvn package`)需要注意环境变量的java版本. 版本过低容易报错如：`maven Unsupported major.minor version 52.0`. 修改版本后可进行重启idea. (修改idea配置中的maven编译版本不能影响命令行)
- mvn编译是根据pom.xml配置来的. 而idea的编译/语法校验等, 是根据Libraries中的jar包来的. **idea默认会根据pom.xml中的依赖找到对应的jar(.m2路径下)并应用到Libraries中(只会加本地maven库中的).** 如果手动加入了一些jar包, 有可能出现本地可正常编译, maven却编译打包失败, 具体参考上述"maven项目依赖本地jar包".

## maven语法

### maven项目基本结构

- pom.xml

	```xml
	<?xml version="1.0" encoding="UTF-8"?>
	<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
		<modelVersion>4.0.0</modelVersion>

		<groupId>cn.aezo</groupId>
		<artifactId>minions</artifactId>
		<version>0.0.1-SNAPSHOT</version>
		<!-- 打包类型可以是jar、war、pom等 -->
		<packaging>jar</packaging>

		<name>minions</name>
		<description>Delegated the code to all minions</description>

		<properties>
			<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
			<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
			<java.version>1.8</java.version>
		</properties>

		<dependencies>
			<dependency>
				<groupId>junit</groupId>
				<artifactId>junit</artifactId>
				<version>4.12</version>
				<!--父项目可以使用此依赖进行编码，子项目如果需要父项目此依赖的相关功能，则自行引入-->
				<optional>true</optional>
			</dependency>
		</dependencies>
	</project>
	```

- maven文件结构

	```xml
	- src
		- main
			- java
				- xxx
			- resources
			- WEB-INFO
				- web.xml
		- test
	```

### 标签介绍

- `dependency#scope`：取值有compile、runtime、test、provided、system和import。
    - `compile`：这是依赖项的默认作用范围，即当没有指定依赖项的scope时默认使用compile。compile范围内的依赖项在所有情况下都是有效的，包括运行、测试和编译时。
    - `runtime`：表示该依赖项只有在运行时才是需要的，在编译的时候不需要。这种类型的依赖项将在运行和test的类路径下可以访问。
    - `test`：表示该依赖项只对测试时有用，包括测试代码的编译和运行，对于正常的项目运行是没有影响的。
    - `provided`：表示该依赖项将由JDK或者运行容器在运行时提供，也就是说由Maven提供的该依赖项我们只有在编译和测试时才会用到，而在运行时将由JDK或者运行容器提供。(如smtools工具类中引入某jjwt的jar包并设置provided，且只有JwtU.java中使用了此jar。当其他项目使用此smtools，如果开发过程中并未使用JwtU，即类加载器没有加载JwtU则此项目pom中不需要引入jjwt的jar；否则需要引入)
    - `system`：当scope为system时，表示该依赖项是我们自己提供的，不需要Maven到仓库里面去找。指定scope为system需要与另一个属性元素systemPath一起使用，它表示该依赖项在当前系统的位置，使用的是绝对路径。
- `dependency#<optional>true</optional>` 父项目可以使用此依赖进行编码，子项目如果需要父项目此依赖的相关功能，则自行引入

### build节点

- 解决打包编译时，默认只编译resource下的xml等资源文件

	```xml
	<build>
        <plugins>
			<!-- 控制代码编译成字节码的java语言版本，对应idea里面的language level -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.3</version>
                <configuration>
                    <source>1.7</source>
                    <target>1.7</target>
                </configuration>
            </plugin>
        </plugins>

		<resources>
			<!--java目录下除了.java文件，其他格式的文件全部打包到jar中-->
			<resource>
				<directory>src/main/java</directory>
				<includes>
					<include>**/*.*</include>
				</includes>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</resource>
			
			<!--
				1.filtering表示是否进行属性替换(默认替换占位符为${myVar.name}的变量)，可通过`mvn clean compile -DmyVar.name=smalle`或properties中加`<myVar.name>`标签进行定义属性值
				2.使用profiles时，过滤resources目录中的占位符号，maven默认占位符是${...}, springboot也是此占位符，因此可再properties标签中加<resource.delimiter>@</resource.delimiter>重写成了@...@。即读取profiles中的properties参数进行填充
			-->
			<!--
				1.springboot一定要加，否则maven打包会漏配置文件，打包运行测试时无法读取配置文件
				<resource>
					<directory>src/main/resources</directory>
					<filtering>true</filtering>
				</resource>
				2.防止resources中的字体文件打包出错导致图标不显示，需要使用下列配置(出去woff、ttf其他都filtering替换)
			-->
			<resource>
				<directory>${project.basedir}/src/main/resources</directory>
				<filtering>true</filtering>
				<excludes>
					<exclude>**/*.woff</exclude>
					<exclude>**/*.ttf</exclude>
				</excludes>
			</resource>
			<resource>
				<directory>${project.basedir}/src/main/resources</directory>
				<filtering>false</filtering>
				<includes>
					<include>**/*.woff</include>
					<include>**/*.ttf</include>
				</includes>
			</resource>
		</resources>
	</build>
	```

## 结合springboot

### 多环境编译 [^2]

- 添加多环境配置(会在idea的maven project菜单中显示)

```xml
</project>
	<profiles>
        <profile>
            <id>prod</id>
            <properties>
				<!--传递的参数-->
                <profiles.active>prod</profiles.active>
            </properties>
        </profile>
        <profile>
            <id>dev</id>
            <properties>
                <profiles.active>dev</profiles.active>
            </properties>
			<!--默认dev-->
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
			<build>
				<plugins>...</plugins>
			</build>
			<!-- 需要引入的子模块 -->
			<modules>
				<module>xxx</module>
			</modules>
        </profile>
        <profile>
            <id>test</id>
            <properties>
                <profiles.active>test</profiles.active>
            </properties>
        </profile>
    </profiles>
</project>
```
- 添加resource文件过滤

```xml
<build>
	<resources>
		<!--使用profiles时，过滤resources目录中的占位符号，maven默认占位符是${...}, springboot也是此占位符，因此使用<resource.delimiter>@</resource.delimiter>重写成了@...@。即读取profiles中的properties参数进行填充-->
		<resource>
			<directory>src/main/resources</directory>
			<filtering>true</filtering>
		</resource>
	</resources>
</build>
```
- springboot配置文件`application.properties`添加`spring.profiles.active=@profiles.active@`(参数名profiles.active为上述profiles中定义)
- maven打包：`mvn clean package -Pdev` 其中`-P`后面即为参数值，后面可有空格。`@profiles.active@`定义之后则只能通过maven打包，不能再idea中直接main方法运行


---

参考文章

[^1]: http://blog.csdn.net/hengyunabc/article/details/47308913 (利用github搭建个人maven仓库)
[^2]: https://yulaiz.com/spring-boot-maven-profiles/ (Spring-Boot application.yml 文件拆分，实现 maven 多环境动态启用 Profiles)



