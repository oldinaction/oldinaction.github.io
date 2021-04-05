---
layout: "post"
title: "Maven"
date: "2016-12-29 10:18"
categories: [java]
tags: [build]
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
- 证书问题导致，下载jar包时只返回一个更新文件，且里面报错`unable to find valid certification path to requested target`。需按照下列方式修改jdk证书 [^4]

    ```bash
    # 浏览器访问 https://maven.aliyun.com/nexus/content/groups/public/，查看证书 - 下载证书(复制到文件，Base64) - 如d:D://aliyun.cer
    # 进入jdk目录 jdk1.8.0_111\jre\lib\security 执行命令
    keytool -import -alias aliyun -keystore cacerts -file D://aliyun.cer
    # 输入密码 changeit
    # 输入信任证书 Y
    # 导入成功后可查看证书，密码为 changeit
    keytool -list -keystore cacerts -alias aliyun
    # 稍后重新下载jar包
    ```
- pom.xml指定远程仓库

```xml
<repositories>
    <repository>
        <id>aliyun-repos</id>
        <url>https://maven.aliyun.com/nexus/content/groups/public/</url>
        <snapshots>
            <enabled>false</enabled>
        </snapshots>
    </repository>
</repositories>

<pluginRepositories>
    <pluginRepository>
        <id>aliyun-plugin</id>
        <url>https://maven.aliyun.com/nexus/content/groups/public/</url>
        <snapshots>
            <enabled>false</enabled>
        </snapshots>
    </pluginRepository>
</pluginRepositories>
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
	<!-- 
		1.父项目的依赖会被子项目自动继承
		2.maven父子项目，在被依赖的时候需要使用子项目的groupId、artifactId、version，不能通过引入父项目而引入所有的子项目
	-->
	<dependencies></dependencies>

	<!--
		依赖管理：
		1.该节点下的依赖关系只是为了统一版本号，不会被子项目自动继承，除非子项目主动引用
		2.好处是子项目可以不用写版本号
	-->
	<dependencyManagement>
		<dependencies></dependencies>
	<dependencyManagement>
	```

- child

	```xml
	<!--声明父项目坐标。maven的parent是单继承，如果需要依赖多个父项目可以在dependencyManagement中添加依赖的scope为import。eg:springcloud应用 -->
	<parent>
		<groupId>cn.aezo</groupId>
		<artifactId>smtools</artifactId>
		<version>0.0.1-SNAPSHOT</version>
		<!-- 父项目的pom.xml文件的相对路径。相对路径允许你选择一个不同的路径。 -->
		<!-- <relativePath/>的默认值是../pom.xml。Maven首先在构建当前项目的地方寻找父项目的pom，其次在文件系统的这个位置（relativePath位置），然后在本地仓库，最后在远程仓库寻找父项目的pom -->
		<!-- 建议写上，否则仅打包子项目的时候会出错 -->
		<relativePath>../pom.xml</relativePath>
	</parent>

    <artifactId>demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
	<packaging>jar</packaging>

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
	<!-- 依赖本项目其他模块时，需要先install被依赖的模块，才能打包此模块 -->
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
		<!-- 外部jar包，此处groupId、artifactId、version可随便填写 -->
    	<groupId>cn.aezo</groupId>
    	<artifactId>utils</artifactId>
    	<version>0.0.1-SNAPSHOT</version>
        <scope>system</scope>
    	<systemPath>${basedir}/src/main/resources/lib/smtools-utils-0.0.1-SNAPSHOT.jar</systemPath>
    </dependency>

	<build>
		<plugins>
			<!-- springboot专用. spring-boot-maven-plugin主要是为了打包出可执行的jar，common模块(无需启动服务)则无需此插件 -->
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
				<configuration>
					<!--(直接给springboot的打包插件引入此行-)同时把本地jar包也引入进去(生成到 BOOT-INF/lib/ 目录), 生成的jar包名称为依赖中定义的`artifactId-version`-->
					<includeSystemScope>true</includeSystemScope>
				</configuration>
			</plugin>
		</plugins>

		<!-- 使用includeSystemScope失败时可以使用resource的形式(会直接把jar包复制到 BOOT-INF/lib/ 目录) -->
		<resources>
			<resource>
				<directory>src/main/resources/lib</directory>
				<targetPath>BOOT-INF/lib/</targetPath>
				<includes>
					<include>**/*.jar</include>
				</includes>
			</resource>
			<resource>
				<directory>src/main/resources</directory>
				<targetPath>BOOT-INF/classes/</targetPath>
			</resource>
		</resources>
	</build>
    ```

- 法二：在`build-plugins`节点加以下插件(可获取到目录下所有jar)(未测试通过)

    ```xml
    <plugin>
    	<artifactId>maven-compiler-plugin</artifactId>
    	<configuration>
            <source>1.8</source>
            <target>1.8</target>
            <encoding>UTF-8</encoding>
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

## 打包和安装

- 生命周期：clean、resources、compile、testResources、testCompile、test、jar、install、deploy
	- package 命令完成了项目编译、单元测试、打包功能(执行命令 `mvn package`)
	- install 命令完成了package的功能，同时把打好的可执行jar包（war包或其它形式的包）布署到本地maven仓库
	- deploy 完成了install的功能，同时部署到远程maven私服仓库
	- 常用：`mvn clean package` 清理并打包
    - 报错是可增加`-X`参数显示debug信息
- 跳过测试进行编译
	- 方式一 `mvn package -DskipTests`
    - 方式二

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
- 安装
	- 基于源码安装：`mvn install` (需要进入到源码的pom.xml目录)
	- 基于jar包安装：`mvn install:install-file -Dfile=D:/test-1.0.0.jar -DgroupId=cn.aezo -DartifactId=test -Dversion=1.0.0 -Dpackaging=jar`
		- 如果jar包包含pom信息则可直接安装`mvn install:install-file -Dfile=D:/test-1.0.0.jar`
    - 说明
		- 执行安装命令后，会自动将项目打包后放到maven本地的home目录(.m2)。之后其他项目可进行引用(按照常规方式引用)
		- 如果有pom.xml建议安装到本地再进行引用，(下面两种方式)否则编译的时候不会报错，但是运行时这些本地jar依赖就找不到(如：`nested exception is java.lang.NoClassDefFoundError`)
		- 有些install时则运行单元测试时候会报错，导致安装/打包失败。可尝试跳过测试进行安装(`mvn install -DskipTests`)。如：阿里云SMS服务aliyun-java-sdk-core:3.2.3就是如此
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
			    - WEB-INF
				    - web.xml
		- test
	```

### 标签介绍

- `dependency#scope` 决定依赖的包是否加入本工程的classpath下

	依赖范围(Scope)|	编译classpath|	测试classpath|	运行时classpath| 打包文件是否包含此依赖|	传递性|	说明
	--|---|---|---|---|---|---
	compile	|	Y|	Y|	Y|	Y|	N|	默认，compile范围内的依赖项在所有情况下都是有效的，包括运行、测试和编译时，仅打包无|
	runtime	|	-|	Y|	Y|	Y|	N|	运行和test的类路径下可以访问|
	test	|	-|	Y|	-|	-|	N|	只对测试时有用，包括测试代码的编译和运行|
	provided|	Y|	Y|	-|	-|	N|	该依赖项将由JDK或者运行容器在运行时提供，也就是说由Maven提供的该依赖项我们只有在编译和测试时才会用到，而在运行时将由JDK或者运行容器提供|
	system	|	Y|	Y|	-|	Y|	Y|	该依赖项由本地文件系统提供，不需要Maven到仓库里面去找。指定scope为system需要与另一个属性元素systemPath一起使用，它表示该依赖项在当前系统的位置，使用的是绝对路径|
	import	|	|	|	|	|	-|	maven的`<parent>`只支持单继承，如果还需要继承其他模块的配置，可以如此使用(eg: springboot项目引入springcloud)|

	- import举例

		```xml
		<!-- 只有在dependencyManagement中，且dependency的type=pom时使用import -->
		<dependencyManagement>
			<dependencies>
                <dependency>
                    <groupId>org.springframework</groupId>
                    <artifactId>spring-framework-bom</artifactId>
                    <version>4.3.13.RELEASE</version>
                    <type>pom</type>
                    <scope>import</scope>
                </dependency>
                
                <dependency>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-dependencies</artifactId>
                    <version>2.0.1.RELEASE</version>
                    <type>pom</type>
                    <scope>import</scope>
                </dependency>

				<dependency>
					<groupId>org.springframework.cloud</groupId>
					<artifactId>spring-cloud-dependencies</artifactId>
					<version>Finchley.SR2</version>
					<type>pom</type>
					<scope>import</scope>
				</dependency>
			</dependencies>
		</dependencyManagement>
		```
- `dependency#optional` 仅限制依赖包的传递性，不影响依赖包的classpath
	- 如`<optional>true</optional>`**表示父项目可以使用此依赖进行编码，子项目如果需要父项目此依赖的相关功能，则自行引入。**如smtools中引入了一些jar进行扩展，可正常编译，其他项目使用此jar则需要自行引入
- **optional与scope区别在于：仅限制依赖包的传递性，不影响依赖包的classpath** [^3]
	- `A->B, B->C(scope:compile, optional:true)`
        - B的编译/测试classpath都有C(打包无C)
        - A中的编译/测试classpath都不存在C(尽管C的scope声明为compile)，A调用B的那些依赖C的方法就会出错。此时A只能手动加入C的依赖
	- `A->B, B->C(scope:provided)`
        - B的编译/测试classpath有C(打包无C)
        - A中的编译/测试classpath都不存在C，但是A使用B(需要依赖C)的接口时就会出现找不到C的错误。此时要么是A手动加入C的依赖，即A->C；否则需要容器(如Tomcat等)提供C的依赖包到运行时classpath

### build节点

- 结构

    ```xml
    <build>
        <!-- 重命名打包后的jar包名 -->
        <finalName>${project.artifactId}-${project.version}</finalName>
    <build>
    ```
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
                    <source>1.8</source>
                    <target>1.8</target>
					<encoding>UTF-8</encoding>
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
<project>
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

### 多模块打包

- spring-boot工程打包编译时，可生成两种jar包，一种是普通的jar，另一种是可执行jar。默认情况下，这两种jar的名称相同，在不做配置的情况下，普通的jar先生成，可执行jar后生成。
- **多模块打包时容易出现"找不到符号"、"程序包不存在"，需要注意可执行的模块不能依赖另外一个可执行的模块**
- 无法单独打包其中的某个子模块。可以将顶级父模块打包后(会自动打包每个子模块)，找到某个子模块生成的jar可单独运行

```xml
<!-- 顶级父模块中定义 -->
<build>
	<pluginManagement>
		<plugins>
			<!-- spring-boot-maven-plugin主要是为了打包出可执行的jar，common模块(无需启动服务)则无需此插件 -->
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</pluginManagement>
</build>

<!-- 需要打包成可执行的jar时加入依赖，无需打包成可执行jar的pom中(common模块)不加入此依赖 -->
<build>
	<plugins>
		<plugin>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-maven-plugin</artifactId>
            <!-- 
                1.此插件打包出来的jar文件结构如下，此时如果有个模块需要引用此模块的代码则会在打包时失败(编译可成功，如基于springboot-plugin-framework的项目)
                    BOOT-INF
                        classes
                            cn.aezo.test
                            mapper
                            application.yml
                        lib
                            spring-boot-2.3.7.RELEASE.jar
                    META-INF
                    org.springframework.boot.loader
                2.上述情况可增加下列扩展命令，最终打包出两个jar：一个为demo-1.0.0.jar(普通jar包结构，即上文classes目录下文件)，另外一个为demo-1.0.0-exec.jar(结构为同上文jar)
             -->
            <!--
            <executions>
                <execution>
                    <id>repackage</id>
                    <goals>
                        <goal>repackage</goal>
                    </goals>
                    <configuration>
                        <classifier>exec</classifier>
                    </configuration>
                </execution>
            </executions>
            -->
		</plugin>
	</plugins>
</build>
```

## maven插件

- `maven-compiler-plugin` 编译插件
- `maven-jar-plugin` 默认的打包插件，用来打普通的project JAR包
- `maven-shade-plugin` 用来打可执行JAR包，也就是所谓的fat JAR包
- `maven-assembly-plugin` 支持自定义的打包结构，也可以定制依赖项，设置MANIFEST.MF文件等 [^5]

    ```xml
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-assembly-plugin</artifactId>
        <version>3.1.1</version>
        <!-- 配置执行器 -->
        <executions>
            <execution>
                <id>make-assembly</id>
                <phase>package</phase><!-- 绑定到package生命周期阶段上. 或 mvn package 会触发动作 -->
                <goals>
                    <goal>single</goal><!-- 只运行一次. 即使用 mvn assembly:single 执行动作 -->   
                </goals>
            </execution>
        </executions>
        <configuration>
            <!-- 生成的打包文件名如：aezo-test-0.0.1.jar -->
            <finalName>aezo-${project.artifactId}-${project.version}</finalName>
            <archive>
                <manifest>
                    <addDefaultImplementationEntries>true</addDefaultImplementationEntries>
                    <addDefaultSpecificationEntries>true</addDefaultSpecificationEntries>
                </manifest>
                <!-- 会自动生成到MANIFEST.MF中 -->
                <manifestEntries>
                    <Plugin-Id>${plugin.id}</Plugin-Id>
                    <Plugin-Version>${plugin.version}</Plugin-Version>
                    <Plugin-Class>${plugin.class}</Plugin-Class>
                    <Plugin-Provider>${plugin.provider}</Plugin-Provider>
                </manifestEntries>
            </archive>
            <!--
                1.引用插件内置描述文件，一般和descriptors使用其中一个
                2.maven-assembly-plugin内置了几个可以用的assembly descriptor
                    bin：类似于默认打包，会将bin目录下的文件打到包中
                    jar-with-dependencies：会将所有依赖都解压打包到生成物中
                    src：只将源码目录下的文件打包
                    project：将整个project资源打包
            -->
            <!--<descriptorRefs>
                <descriptorRef>jar-with-dependencies</descriptorRef>
            </descriptorRefs>-->
            <!--配置自定义描述文件-->
            <descriptors>
                <!--描述文件路径-->
                <descriptor>src/assembly/jar-with-dependencies.xml</descriptor>
            </descriptors>
        </configuration>
    </plugin>

    <!-- src/assembly/jar-with-dependencies.xml -->
    <assembly xmlns="http://maven.apache.org/ASSEMBLY/2.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.0.0 http://maven.apache.org/xsd/assembly-2.0.0.xsd">
        <id>dep</id>
        <!--
            id：标识符，添加到生成文件名称的后缀符。如果指定 id 的话，目标文件则类似 ${artifactId}-${id}.tar.gz
            format：指定打包类型，支持的打包格式有zip、tar、tar.gz (or tgz)、tar.bz2 (or tbz2)、jar、dir、war，可以同时指定多个打包格式
            includeBaseDirectory：指定是否包含打包层目录（比如finalName是output，当值为true，所有文件被放在output目录下，否则直接放在包的根目录下） 
            fileSets：指定要包含的文件集，可以定义多个fileSet
            directory：指定要包含的目录
            outputDirectory：指定当前要包含的目录的目的地
            dependencySets：用来定制工程依赖 jar 包的打包方式，核心元素如下表所示
        -->
        <formats>
            <format>jar</format>
        </formats>
        <includeBaseDirectory>false</includeBaseDirectory>
        <dependencySets>
            <dependencySet>
                <!-- 指定包依赖目录，该目录是相对于根目录 -->
                <outputDirectory>/</outputDirectory>
                <useProjectArtifact>true</useProjectArtifact>
                <unpack>true</unpack>
                <scope>runtime</scope>
                <!-- excludes：排除依赖不进行打包；includes：包含的依赖进行打包；不写则全部打包 -->
                <excludes>
                    <exclude>org.projectlombok:lombok</exclude>
                </excludes>
            </dependencySet>
        </dependencySets>
    </assembly>
    ```
- `spring-boot-maven-plugin` 打包SpringBoot项目
- `org.codehaus.mojo#exec-maven-plugin`
    - 可执行shell命令、构建docker镜像、用npm打包等。特别是结合phase使用
- `Maven Enforcer Plugin` 可以在项目validate时，对项目环境进行检查。[使用参考](https://www.cnblogs.com/qyf404/p/4829327.html)
    - [内置规则(亦可基于接口自定义)](http://maven.apache.org/enforcer/enforcer-rules/)
        - `requireMavenVersion` 校验maven版本
        - `requireJavaVersion` 校验java版本
        - `bannedDependencies` 校验依赖关系，检查是否存在或不存在某依赖

## maven私服搭建(nexus)

- **也可使用阿里云私服**：https://packages.aliyun.com/maven
- nexus可对maven、docker等私服进行管理
- 基于docker安装nexus：`docker-compose.yml`

```yml
version: '3'
services:
  nexus:
    container_name: nexus
    # 使用版本2的较多
    image: sonatype/nexus:2.14.13-01
    ports:
      - 2082:8081
    volumes:
      - /data/nexus:/sonatype-work
    environment:
      TZ: Asia/Shanghai
    restart: always
    user: root
```
- 访问`http://192.168.1.100:2082/nexus/`可进入nexus页面，默认账号为`admin/admin123`
- 上传的jar保存在`/sonatype-work/storage/releases`目录(类似`.m2`目录)

### nexus界面管理

- 默认情况下，nexus是提供了四个仓储(如果内部代码可单独创建内部仓库存放)
    - Central 代理中央仓库，从公网下载jar
    - Releases 发布版本内容（即自己公司发行的jar的正式版本）
    - Snapshots 发布版本内容（即自己公司发行的jar的快照版本）
    - Public 以上三个仓库的小组
- 设置maven-central代理位置(默认为maven官网仓库)：Repositories - Central - Configuration - Remote Storage Location填写阿里云镜像 http://maven.aliyun.com/nexus/content/groups/public/
- 允许Releases仓库重复提交：Repositories - Releases - Configuration - Deployment Policy 选择 Allow Redeploy (理论上每次发布都会修改版本，因此应该设置禁止重复推送)

### 上传jar包到nexus

- 在`~/.m2/settings.xml`中设置maven私服(nexus)用户名和密码

```xml
<server>
    <id>mvn-releases</id>
    <username>admin</username>
    <password>admin123</password>
</server>
```
- 在项目的pom.xml中加入

```xml
<distributionManagement>
    <repository>
        <id>mvn-releases</id><!-- 上述server id -->
        <url>http://192.168.1.10:8081/nexus/content/repositories/releases</url><!-- nexus仓库地址 -->
    </repository>
</distributionManagement>
```
- 打包发布 `mvn deploy -DskipTests`(跳过测试)
- 常见错误
    - 400：如Releases仓库默认禁止重复推送，如果重复推送则会报400，可将Releases仓库设置成 Allow Redeploy
    - 401：认证出错
    - 403：无权推送

### 从nexus下载jar

```xml
<repository>
    <id>releases</id><!-- nexus中的repository ID -->
    <url>http://192.168.1.10:8081/nexus/content/repositories/releases</url>
</repository>
```

## 常见问题

- idea自带maven插件
- `pom.xml`检测通过，但是`Maven Projects`中部分依赖显示红色波浪线
    - 将`pom.xml`中此种依赖删除，然后`reimport`刷新一下依赖，再将刚刚的依赖粘贴上去，重新`reimport`刷新一下
    - 将`pom.xml`中repositories的配置删除，然后`reimport`刷新一下依赖
    - 删除`.m2`中此依赖的相关文件夹，重新下载
- 创建示例项目
    - org.apache.maven.archetypes:maven-archetype-quickstart
    - org.apache.maven.archetypes:maven-archetype-site
    - org.apache.maven.archetypes:maven-archetype-webapp

---

参考文章

[^1]: http://blog.csdn.net/hengyunabc/article/details/47308913 (利用github搭建个人maven仓库)
[^2]: https://yulaiz.com/spring-boot-maven-profiles/ (Spring-Boot application.yml 文件拆分，实现 maven 多环境动态启用 Profiles)
[^3]: https://blog.csdn.net/xhyzjiji/article/details/72731276
[^4]: https://blog.csdn.net/frankcheng5143/article/details/52164939
[^5]: https://www.cnblogs.com/sidesky/p/10651266.html

