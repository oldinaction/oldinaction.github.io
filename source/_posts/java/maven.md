---
layout: "post"
title: "Maven"
date: "2016-12-29 10:18"
categories: [java]
tags: [build]
---

## maven简介

- [maven教程](https://www.runoob.com/maven/maven-tutorial.html)
- [《Maven官方文档》目录指南](http://ifeve.com/maven-index-2/)
- FatJar：将应用程序及其依赖jar一起打包到一个独立的jar中，就叫fat jar，它也叫uberJar，如springboot应用
- 安装

```bash
# 3.8.8 要求JDK1.7及以上
wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
tar -zxvf apache-maven-3.8.8-bin.tar.gz -C /opt
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
- mvn打包优先以本地依赖为准：IDEA>Setting>Build,Execution,Deployment>Build Tools>Maven>Runner>设置VM Options为`-DarchetypeCatalog=internal`

### maven命令

```bash
# 会创建一个名为myapp的Maven项目，并自动添加必要的文件和文件夹
mvn archetype:generate -DgroupId=com.example -DartifactId=myapp -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

# 下载依赖（有时候通过idea刷新依赖失败，可使用此命令下载试试）
# mvn -f pom.xml dependency:resolve
mvn dependency:resolve
# 将依赖的jar复制到target/dependency目录
mvn dependency:copy-dependencies
# -U强制更新所有 SNAPSHOT 依赖项，package|install同理
mvn dependency:resolve -U
mvn clean package|install -U
# 清除本地依赖，或手动删除
mvn dependency:purge-local-repository
mvn dependency:purge-local-repository -Dinclude:cn.aezo.test

# 下载依赖到本地仓库(不会自动加入到pom.xml). remoteRepositories可省略
mvn dependency:get -DremoteRepositories=https://mvnrepository.com/artifact/commons-logging/commons-logging -DgroupId=commons-logging -DartifactId=commons-logging -Dversion=1.1.1

# 安装依赖(安装jar包到本地)
mvn install:install-file -Dfile=test-1.0.0.jar -DgroupId=cn.aezo -DartifactId=test -Dversion=1.0.0 -Dpackaging=jar
# -DlocalRepositoryPath=/Users/smalle/gitwork/github/aezo-maven-repo/ # 可增加参数指定安装位置

# 推送到远程
mvn deploy:deploy-file -Dmaven.test.skip=true -Dfile=D:/test-1.0.0.jar -DgroupId=cn.aezo -DartifactId=test -Dversion=1.0.0 -Dpackaging=jar -DrepositoryId=my-server-id -Durl=http://192.168.0.1:8080/nexus/content/repositories/releases
```

### mvnw

- mvnw是Maven Wrapper的缩写。Maven Wrapper就是给一个项目提供一个独立的，指定版本的Maven
- 使用

```bash
# 会自动使用最新版本的Maven
mvn wrapper:wrapper
# 指定使用的Maven版本: https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.zip
mvn wrapper:wrapper -Dmaven=3.6.3
# 查看版本
./mvnw -version

# 项目/模块根目录会有一个mvnw和mvnw.cmd的文件
# 执行mvnw命令时，会自动下载对应版本maven到./m2/wrapper中(第一次由于下载可能会卡一下)
./mvnw compile
```
- `.mvn/wrapper/maven-wrapper.properties`
    - distributionUrl 下载对应版本maven的地址(一般为中央仓库: repo.maven.apache.org，如需使用镜像可进行修改)
    - wrapperUrl 指定maven-wrapper.jar的下载地址(一般为中央仓库: repo.maven.apache.org)
- 使用idea - maven - reimport功能时，需要设置idea的maven home path为Use Maven wrapper

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
		<!-- 打包类型可以是jar(默认)、war、pom等 -->
		<packaging>jar</packaging>

        <!-- 会显示到idea maven窗口中 -->
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

### dependency节点

- `dependency#scope` 决定依赖的包是否加入本工程的classpath下

	依赖范围(Scope)|	编译classpath|	测试classpath|	运行时classpath| 打包文件是否包含此依赖|	传递性|	说明
	--|---|---|---|---|---|---
	compile	|	Y|	Y|	Y|	Y|	N|	默认，compile范围内的依赖项在所有情况下都是有效的，包括运行、测试和编译时，仅打包无；可通过反射调用此级别的依赖，防止打包后未映入相关依赖而报错|
	runtime	|	-|	Y|	Y|	Y|	N|	运行和test的类路径下可以访问| 如编译时只需要JDBC API的jar，而只有运行时才需要JDBC驱动实现
	test	|	-|	Y|	-|	-|	N|	只对测试时有用，包括测试代码的编译和运行|
	provided|	Y|	Y|	-|	-|	N|	该依赖项将由JDK或者运行容器在运行时提供，也就是说由Maven提供的该依赖项我们只有在编译和测试时才会用到，而在运行时将由JDK、运行容器、或主应用提供|
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
- `optional`属性：仅限制依赖包的传递性，不影响依赖包的classpath
	- 如`<optional>true</optional>`**表示工具包可以使用此依赖进行编码，主项目如果需要工具包此依赖的相关功能，则自行引入。**如smtools中引入了一些jar进行扩展，可正常编译，其他项目使用此jar则需要自行引入
- **optional与scope区别在于** [^3]
	- `A->B, B->C(scope=compile|runtime)`，此时A依赖C，相当于A引入了C的依赖
	- `A->B, B->C(scope=provided)`，此时A不依赖C
        - 但是A使用B(需要依赖C)的接口时就会出现找不到C的错误，此时要么是A手动加入C的依赖；否则需要容器(如Tomcat等)提供C的依赖包到运行时classpath
    - `A->B, B->C(scope=test)`，此时A仅在测试时依赖C
- `classifier`属性
    - 可以是任意的字符串，用于拼接在GAV之后来确定指定的文件
    - 需要注意classifier的位置

```xml
<!-- json-lib-2.2.2-jdk15-javadoc.jar -->
<dependency>  
    <groupId>net.sf.json-lib</groupId>   
    <artifactId>json-lib</artifactId>   
    <version>2.2.2</version>  
    <classifier>jdk15-javadoc</classifier>    
</dependency>

<!-- json-lib-jdk15-javadoc-2.2.2.jar -->
<dependency>  
    <groupId>net.sf.json-lib</groupId>   
    <artifactId>json-lib</artifactId>   
    <classifier>jdk15-javadoc</classifier>  
    <version>2.2.2</version>   
</dependency> 
```

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
                <!--在构建生命周期中执行一组目标的配置。每个目标可能有不同的配置。-->
                <executions>
                    <!--execution元素包含了插件执行需要的信息--> 
                    <execution>
                        <!--执行目标的标识符，用于标识构建过程中的目标，或者匹配继承过程中需要合并的执行目标-->    
                        <id/>
                        <!--绑定了目标的构建生命周期阶段，如果省略，目标会被绑定到源数据里配置的默认阶段。如果是绑定到相同阶段则按照plugin先后顺序进行执行 -->
                        <phase/>
                        <!--配置的执行目标-->
                        <goals/>
                        <!--配置是否被传播到子POM-->
                        <inherited/>
                        <!--作为DOM对象的配置-->
                        <configuration/>
                    </execution>
                </executions>
            </plugin>
        </plugins>

        <!-- 使用了resources，则必须对所有需要编译的文件作出配置 -->
		<resources>
			<!--案例：java目录下除了.java文件，其他格式的文件全部打包到jar中-->
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
                案例
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

            <!-- 案例：Mapper对应的XML写到src目录了，需要使之生效且打包到jar中 -->
            <resource>
				<directory>src/main/java</directory>
				<includes>
					<include>**/*.xml</include>
				</includes>
			</resource>
			<resource>
                <!-- 定义了src/main/java；则还需定义此目录，否则此目录下文件不会被编译和打包 -->
				<directory>src/main/resources</directory>
			</resource>
		</resources>
	</build>
	```

### 仓库的优先级

- 依赖优先级关系由近(本地仓库)及远(中央仓库)
    - 仓库类型
        - 本地仓库(.m2)
        - 自定义第三方仓库
            - 项目profile仓库，通过 pom.xml 中的 project.profiles.profile.repositories.repository 配置
            - 全局-用户profile仓库，通过 settings.xml 中的 settings.repositories.repository 配置
            - 项目仓库，通过 pom.xml 中的 project.repositories.repository 配置
        - 中央仓库，这是默认的仓库(仓库ID=central)
    - 仓库和镜像
        - jar都是从仓库下载的，如果对应仓库ID设置了镜像，则会从镜像获取(相当于走了代理，但是如果此镜像代理地址没有代理此仓库就会导致包拉取不下来)
            - 如设置`<mirrorOf>central</mirrorOf>`表示代理中央仓库
            - 如设置`<mirrorOf>*</mirrorOf>`表示代理所有的仓库，包括自己设置的第三方仓库
            - 阿里云可代理的仓库ID类型：https://developer.aliyun.com/mvn/guide
        - 仓库级别按照repository顺序依次判断是否存在此依赖
        - 用户-全局镜像仓库，通过 sttings.xml 中的 settings.mirrors.mirror 配置

## maven实战

- 设置.m2路径位置: 修改settings.xml文件，增加`<localRepository>D:/data/.m2/repository</localRepository>`

### maven镜像修改

- 在~/.m2目录下的settings.xml文件中，（如果该文件不存在，则需要从maven/conf目录下拷贝一份），找到`<mirrors>`标签，添加如下子标签(windows/linux均可)
    - 参考：https://zhuanlan.zhihu.com/p/71998219

	```xml
    <!--
        <mirrorOf>*</mirrorOf> 匹配所有仓库请求，即将所有的仓库请求都转到该镜像上(包括项目中设置的第三方仓库)
        <mirrorOf>repo1,repo2</mirrorOf> 将仓库repo1和repo2的请求转到该镜像上，使用逗号分隔多个远程仓库
        <mirrorOf>*,!repo1</miiroOf> 匹配所有仓库请求，repo1除外，使用感叹号将仓库从匹配中排除
    -->
    <mirror>
        <id>nexus-aliyun</id>
        <name>Nexus aliyun</name>
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

### 父子项目

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
        <!-- 子模块的groupId可以和当前父模块groupId不一致；此处定义的子模块在父模块打包时会一同打包 -->
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

### 依赖本地jar包

- 法一(**推荐下文优化写法**)：依赖写法(只能一个jar一个jar的添加)

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

    <!-- 这部分也需要，否则只能开发环境通过，编译的springboot jar中则无此依赖 -->
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

		<!-- 使用includeSystemScope失败时可以使用resource的形式(会直接把jar包复制到 BOOT-INF/lib/ 目录) => 会导致开发环境有问题 -->
		<!-- <resources>
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
		</resources> -->
	</build>
    ```
- 法一优化写法
    - 法一存在问题：且A->B->C的项目依赖关系中，在A项目中编译提示B存在上述问题，从而导致C无法导入

```xml
<dependency>
    <groupId>com.aspose</groupId>
    <artifactId>aspose-cells</artifactId>
    <version>21.11-fix</version>
</dependency>

<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-install-plugin</artifactId>
            <version>2.5.2</version>
            <executions>
                <!-- 在mvn clean阶段安装本地jar包到本地maven仓库，从而可正常引入；也可通过命令直接按钮，参考下文maven-install-plugin插件 -->
                <execution>
                    <id>install-aspose-cells</id>
                    <phase>clean</phase>
                    <configuration>
                        <file>${project.parent.basedir}/docs/lib/aspose-cells-21.11-fix.jar</file>
                        <repositoryLayout>default</repositoryLayout>
                        <groupId>com.aspose</groupId>
                        <artifactId>aspose-cells</artifactId>
                        <version>21.11-fix</version>
                        <packaging>jar</packaging>
                        <generatePom>true</generatePom>
                        <!-- 可指定本地仓库位置 -->
                        <!-- <localRepositoryPath>/Users/smalle/gitwork/github/aezo-maven-repo/</localRepositoryPath> -->
                    </configuration>
                    <goals>
                        <goal>install-file</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

- 法二
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

- 法三
    - 在`build/plugins`节点加以下插件(可获取到目录下所有jar)，此方法会将lib目录下的包全部打包到classes目录的lib目录下
    - 本地开发需要将lib目录添加到idea的Libaray中，则开发编译走idea配置，maven打包编译时走此插件配置
    - springboot项目时，此插件放在`spring-boot-maven-plugin`插件上面
    - 由于springboot的classes和lib是平级，所以运行生产环境时，还需将此lib包作为外置包进行运行，参考[分离lib包](/_posts/java/springboot.md#分离lib包)

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

### 多环境编译

- 添加多环境配置(会在idea的maven project菜单中显示) [^2]

```xml
<project>
	<profiles>
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
            <!-- 需要额外引入的依赖 -->
            <dependencies></dependencies>
        </profile>
        <profile>
            <id>test</id>
            <properties>
                <profiles.active>test</profiles.active>
            </properties>
        </profile>
        <profile>
            <id>prod</id>
            <properties>
				<!--传递的参数-->
                <profiles.active>prod</profiles.active>
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

### 多模块打包(结合springboot)

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
                <version>2.1.0</version>
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

- **Maven官方插件文档地址**: https://maven.apache.org/plugins/ (后面加插件名称)
- `maven-compiler-plugin` 编译插件
- `maven-jar-plugin` 默认的打包插件，用来打**普通的Project jar包(不包含依赖)**

    ```xml
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        <version>3.2.0</version>
    </plugin>
    ```
- `maven-shade-plugin` 用来打**Fat jar包(包含依赖，一般为可执行jar包)**

    ```xml
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.4</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <mainClass>org.example.App</mainClass>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
    </plugin>
    ```
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
                <!-- 指定包依赖目录，该目录是相对于根目录。如果值为/dir，则打包出来的jar的根目录为dir -->
                <outputDirectory>/</outputDirectory>
                <!-- 将所有依赖的jar(所有版本)打包到jar包的lib目录
                <outputDirectory>lib</outputDirectory>
                <includes>
                    <include>*:jar:*</include>
                </includes> 
                -->

                <useProjectArtifact>true</useProjectArtifact>
                <unpack>true</unpack>
                <scope>runtime</scope>
                <!-- excludes：排除依赖不进行打包；includes：包含的依赖进行打包；不写则全部打包 -->
                <excludes>
                    <exclude>org.projectlombok:lombok</exclude>
                </excludes>
            </dependencySet>
        </dependencySets>

        <!-- 将项目的target/classes目录下文件打包到jar包的classes目录
        <fileSets>
            <fileSet>
                <directory>target/classes</directory>
                <outputDirectory>classes</outputDirectory>
            </fileSet>
        </fileSets> 
        -->
    </assembly>
    ```
- [maven-install-plugin](https://maven.apache.org/plugins/maven-install-plugin/index.html) 将jar安装到本地仓库，配置类似maven-deploy-plugin

```bash
# 安装依赖(安装jar包到本地仓库，可指定仓库位置)
mvn install:install-file -Dfile=test-1.0.0.jar -DgroupId=cn.aezo -DartifactId=test -Dversion=1.0.0 -Dpackaging=jar
# -DlocalRepositoryPath=/Users/smalle/gitwork/github/aezo-maven-repo/ # 可增加参数指定安装位置
```

- [maven-deploy-plugin](https://maven.apache.org/plugins/maven-deploy-plugin/index.html) 发布jar到远程仓库
    ```xml
    <!-- 如用于proguard打包时，生成了原始包和classifier混淆包，此时只需classifier混淆包 -->
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-deploy-plugin</artifactId>
        <configuration>
            <!-- 表示当前模块不发布仓库 -->
            <!-- <skip>true</skip> -->
        </configuration>
        <executions>
            <!-- 阻止默认的部署 -->
            <execution>
                <id>default-deploy</id>
                <phase>none</phase>
            </execution>
            <!-- 自定义部署 -->
            <execution>
                <id>deploy-essential</id>
                <phase>deploy</phase>
                <goals>
                    <goal>deploy-file</goal>
                </goals>
                <configuration>
                    <groupId>${project.groupId}</groupId>
                    <artifactId>${project.artifactId}</artifactId>
                    <version>${project.version}</version>
                    <classifier>pg</classifier>
                    <packaging>jar</packaging>
                    <!-- 使用固定的pom文件安装到本地仓库，否则会自动生成(可能会丢失依赖从而导致依赖传递失败) -->
                    <pomFile>${basedir}/pom.xml</pomFile>
                    <file>${basedir}/target/${project.name}-${project.version}-pg.jar</file>
                    <repositoryId>aezocn-maven-repo</repositoryId>
                    <url>file:///Users/smalle/gitwork/github/aezo-maven-repo</url>
                </configuration>
            </execution>
        </executions>
    </plugin>
    ```
- `spring-boot-maven-plugin` 打包SpringBoot项目
- `org.codehaus.mojo#exec-maven-plugin`
    - 可执行shell命令、构建docker镜像、用npm打包等。特别是结合phase使用
- `maven-dependency-plugin` 操作项目依赖文件，如将依赖jar全部复制到lib目录
    - https://blog.csdn.net/u011781521/article/details/79055605
    - https://my.oschina.net/LucasZhu/blog/1539468
- `Maven Enforcer Plugin` 可以在项目validate时，对项目环境进行检查。[使用参考](https://www.cnblogs.com/qyf404/p/4829327.html)
    - [内置规则(亦可基于接口自定义)](http://maven.apache.org/enforcer/enforcer-rules/)
        - `requireMavenVersion` 校验maven版本
        - `requireJavaVersion` 校验java版本
        - `bannedDependencies` 校验依赖关系，检查是否存在或不存在某依赖
- `license-maven-plugin` 为项目源文件顶部添加许可证
    - https://www.pingfangushi.com/posts/57675/
- `maven-site-plugin` 基于src/site目录下的配置生成静态站点
    - https://blog.csdn.net/taiyangdao/article/details/53933168
    - 参考项目：https://github.com/wvengen/proguard-maven-plugin
- `maven-dbdeploy-plugin` 记录数据库开发修改历史
    - https://blog.csdn.net/weixin_42289842/article/details/126033190

## 自定义插件

- pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>cn.aezo.sqbiz.maven.plugin</groupId>
    <artifactId>sqbiz-sofa-maven-plugin</artifactId>
    <name>sqbiz-sofa-maven-plugin</name>
    <version>0.0.1</version>
    <!-- 打包方式 -->
    <packaging>maven-plugin</packaging>

    <dependencies>
        <dependency>
            <groupId>org.apache.maven</groupId>
            <artifactId>maven-plugin-api</artifactId>
            <version>3.8.1</version>
        </dependency>

        <dependency>
            <groupId>org.apache.maven.plugin-tools</groupId>
            <artifactId>maven-plugin-annotations</artifactId>
            <version>3.6.2</version>
            <scope>provided</scope>
        </dependency>

        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-plugin-plugin</artifactId>
                <version>3.5.2</version>
            </plugin>
        </plugins>
    </build>

</project>
```
- Mojo入口

```java
package cn.aezo.sqbiz.maven.plugin.sofa;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;

@Mojo(name = "biz")
public class BizMojo extends AbstractMojo {

    /**
     * 自定义参数<br/>
     *
     * maven提供三个隐式变量，用来访问系统环境变量、POM信息和maven的setting<br/>
     * ${basedir} 项目根目录<br/>
     * ${project.build.directory} 构建目录，缺省为target<br/>
     * ${project.build.outputDirectory} 构建过程输出目录，缺省为target/classes<br/>
     * ${project.build.finalName} 产出物名称，缺省为 ${project.artifactId}- ${project.version}<br/>
     * ${project.packaging} 打包类型，缺省为jar<br/>
     * ${project.parent.version}
     * ${project.xxx} 当前pom文件的任意节点的内容<br/>
     *
     * @author smalle
     * @since 2022/2/19
     */
    @Parameter(property = "name", defaultValue = "sqbiz")
    private String name;

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        System.out.println("hello world..." + name);
    }
}
```
- 在需要的项目中引入此插件

```xml
<plugin>
  <groupId>cn.aezo.sqbiz.maven.plugin</groupId>
  <artifactId>sqbiz-sofa-maven-plugin</artifactId>
  <version>0.0.1</version>
  <executions>
    <execution>
      <phase>compile</phase>
      <goals>
        <goal>biz-dep</goal>
      </goals>
    </execution>
  </executions>
  <!--
    可以自定义配置，此处只能通过idea的maven工具进行编译才会生效
    也可以通过命令行传入参数`mvn cn.aezo.sqbiz.maven.plugin:sqbiz-sofa-maven-plugin:0.0.1:biz-dep -Dname=test`
  -->
  <configuration>
    <name>smalle</name>
  </configuration>
</plugin>
```
- 执行goal
  - 命令行执行格式`mvn groupId:artifactId:version:goal`，即`mvn cn.aezo.sqbiz.maven.plugin:sqbiz-sofa-maven-plugin:0.0.1:biz-dep -Dname=test`
  - Idea Run Maven配置可省略groupId和`-maven-plugin`和版本号，如`sqbiz-sofa:biz-dep -Dname=test`
- debug执行
  - 先在主应用项目中运行`mvnDebug cn.aezo.sqbiz.maven.plugin:sqbiz-sofa-maven-plugin:0.0.1:biz-dep -Dname=test`会在本地监听一个端口，如8000. 此时命令会阻塞住等待attach
  - 然后再maven插件中添加remote debug配置attach到对应端口，启动后主应用打包程序继续执行，并进入到maven插件项目端点中

## maven私服搭建

### GitHub Packages私有仓库

- 参考：https://www.liaoxuefeng.com/wiki/1252599548343744/1347981037010977

### 阿里云私服

- **也可使用阿里云私服**：https://packages.aliyun.com/maven
    - 支持maven, npm
    - 免费不限容量，只支持自己可见和企业内可见
    - 可开一个上传账号和一个下载只读账号

### 使用Jitpack发布开源Java库

- 官网：https://jitpack.io/
- 参考：https://www.cnblogs.com/stars-one/p/15871077.html
- 需要开放源代码，Jitpack会基于源代码中的pom.xml等文件进行编译打包

### 利用github创建仓库

- 私有maven建议使用阿里云私有仓库，参考下文[maven私服搭建(nexus)](#maven私服搭建(nexus))
- 其他
    - 基于github搭建私有maven仓库
        - https://www.cnblogs.com/liufarui/p/14019206.html
    - 基于gitee搭建maven仓库
        - https://blog.csdn.net/lidelin10/article/details/105787168
        - 使用gitee链接(需要仓库为public, 私有仓库看是否可以通过设置server密码实现)
    - 基于gitlab搭建maven仓库(仓库可私有)
        - https://www.bookstack.cn/read/gitlab-doc-zh/docs-280.md#aqpu74
- github新建项目[maven-repo](https://github.com/aezocn/maven-repo)，并下载到本地目录，如`/Users/smalle/gitwork/github/aezo-maven-repo` [^1]
- 进入到项目pom.xml所在目录，运行命令
	- `mvn deploy -DaltDeploymentRepository=aezocn-maven-repo::default::file:/Users/smalle/gitwork/github/aezo-maven-repo -DskipTests`(此仓库永远是master分支即可，其他项目以不同的分支和版本往此目录提交)
	    - 将项目部署到`/Users/smalle/gitwork/github/aezo-maven-repo`目录，项目id为`aezocn-maven-repo`，`-DskipTests`跳过测试进行部署
    - 也可配置成如下，然后在idea中执行deploy命令
    
    ```xml
    <distributionManagement>
        <repository>
            <id>aezocn-maven-repo</id>
            <url>file:/Users/smalle/gitwork/github/aezo-maven-repo</url>
        </repository>
    </distributionManagement>

    <!-- settings.xml中需要增加server配置 -->
    <server>
		<id>aezocn-maven-repo</id>
        <!-- <username>可基于访问命令或者基于账号密码</username> -->
		<password>ghp_your_token_xxxx</password>
	</server>
    ```
- 提交到github(**注意jar包不要习惯性的ignore**)
- 使用时配置maven远程仓库

	```xml
	<!-- 优先级：读取本地库 > 按照项目中repositories依次下载 > 最后按照本地maven配置文件中设置的镜像源进行下载 -->
	<repositories>
        <!-- 如果使用github仓库，可在前面加一个阿里云仓库；否则所有的包会先检查一下github仓库，没有再走本地镜像 -->
        <repository>
			<id>aliyun-repos</id>
			<url>https://maven.aliyun.com/nexus/content/groups/public/</url>
			<snapshots>
				<enabled>false</enabled>
			</snapshots>
		</repository>

        <!--
            如果包拉取失败：请检查~/.m2/settings.xml中配置的maven镜像是否是否设置了<mirrorOf>*</mirrorOf>
            如果是则需要改成<mirrorOf>central</mirrorOf>
            (*表示代理所有的仓库，包括此处设置本仓库；出现过本地仓库存在此包，但是设置了*导致提示此包不存在)
        -->
        <repository>
            <!-- 如果相关包拉取失败，可切换以下地址试试，并重新刷新maven -->
            <!-- 如果仍然失败，进入到当前pom.xml所在目录，并打开命令行，执行命令`mvn dependency:resolve`，如果提示"BUILD SUCCESS"说明成功，直接启动项目即可 -->
            <!-- 如果仍然失败删除.m2目录对应文件，重复以上步骤，多试几次 -->
            <id>aezocn-maven-repo</id>
            <url>https://gitee.com/aezocn/maven-repo/raw/master/</url>
            <!-- <url>https://raw.github.com/aezocn/maven-repo/master/</url> -->

			<!--或者访问本地-->
			<!-- <url>file:/Users/smalle/gitwork/github/aezo-maven-repo/</url> -->
        </repository>
    </repositories>
	```
	- maven的repository并没有优先级的配置，也不能单独为某些依赖配置repository。所以如果项目配置了多个repository，在首次编绎时会依次尝试下载依赖，如果没有找到，尝试下一个
	- 其中`<url>https://raw.github.com/{github-username}/{github-repository}/{github-branch}/</url>`，https://raw.github.com 是github的raw站点，浏览器不能访问目录只能访问单个文件
- 使用时配置项目依赖(会自动将仓库中的数据再下载到本地仓库`.m2`目录)

	```xml
	<dependency>
		<groupId>cn.aezo</groupId>
		<artifactId>utils</artifactId>
		<version>sm-minions-1.0</version>
	</dependency>
	```

### 基于nexus搭建私服

#### 安装nexus

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
- 其他配置
    - 使用nginx代理

    ```bash
    # 且需要在 nexus 中设置 Base URL 和 Force Base URL
    server {
        listen 2082;
        # 防止出现 413 Request Entity Too Large
        client_max_body_size 1G;
        # proxy_max_temp_file_size 1G;
        location / {
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://localhost:8081;
        }
    }
    ```

#### nexus界面管理

- 默认情况下，nexus是提供了四个仓储(如果内部代码可单独创建内部仓库存放)
    - Central 代理中央仓库，从公网下载jar
    - Releases 发布版本内容（即自己公司发行的jar的正式版本）
    - Snapshots 发布版本内容（即自己公司发行的jar的快照版本）
    - Public 以上三个仓库的小组
- 设置maven-central代理位置
    - Repositories - Central - Configuration - Remote Storage Location填写阿里云镜像 http://maven.aliyun.com/nexus/content/groups/public/ (默认为maven官网仓库https://repo1.maven.org/maven2/)
- 允许Releases仓库重复提交
    - Repositories - Releases - Configuration - Deployment Policy 选择 Allow Redeploy (理论上每次发布都会修改版本，因此应该设置禁止重复推送)
- 禁止匿名用户访问
    - Security - Users - anonymous - Status设置成Disabled；或者将移除仓库的读权限
- 用户权限
    - `Repo: All Repositories (Read)` 允许下载所有仓库(如maven+npm)
    - `UI: Base UI Privileges` 允许通过web登录nexus(可通过url路径浏览仓库)
    - `UI: Repository Browser` 允许登录nexus后通过页面查看仓库(多出一个Repositories选项卡)

#### maven私服配置

#### 上传jar包到nexus

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
        <!-- 上述server id -->
        <id>mvn-releases</id>
        <!-- nexus仓库地址 -->
        <url>http://192.168.1.10:8081/nexus/content/repositories/releases</url>
    </repository>
</distributionManagement>
```
- 打包发布 `mvn deploy -DskipTests`(跳过测试)
- 常见错误
    - 400：如Releases仓库默认禁止重复推送，如果重复推送则会报400，可将Releases仓库设置成 Allow Redeploy
    - 401：认证出错
    - 403：无权推送

#### 从nexus下载jar

```xml
<repositories>
    <repository>
        <!-- nexus中的repository ID -->
        <id>releases</id>
        <name>my releases</name>
        <url>http://192.168.1.10:8081/nexus/content/repositories/releases</url>
    </repository>
</repositories>
```
- 常见错误
    - `maven-default-http-blocker (http://0.0.0.0/): Blocked mirror for repositories`
        - 在3.8.1后面的版本中block掉了所有HTTP协议的repositories，仅支持https
        - 可以通过设置setting.xml的mirror中mirrorOf和blocked属性的值为false来解决，更推荐把maven版本降低到了3.6.3及以下maven(可使用mvnw)；IDEA 2021最新版本内置的maven是3.6.3，可以支持http

#### 基于nexus实现npm私有仓库

- [官方文档](https://help.sonatype.com/repomanager2/node-packaged-modules-and-npm-registries)
- 参考: https://blog.csdn.net/weixin_39999684/article/details/106763560
    - 需要创建一个npm组、一个npm代理仓库(用于代理其他公共包到淘宝等镜像)、一个npm hosted仓库(实际上传包的仓库，也只能下载本仓库存在的包)
    - 上传包需要上传到npm hosted仓库(tarballs数据以tgz格式存储，然后记录版本等元信息)
    - 下载包需要从npm组对应仓库下载
    - 必须在项目的.npmrc或用户目录的.npmrc中增加`always-auth=true`和`_auth="用户名:密码"的base64编码`(echo -n 'admin:admin123' | openssl base64)，或者使用npm token进行认证
        - E401 E500参考：https://blog.csdn.net/lqh4188/article/details/107384465
- 一方面，nexus2版本不支持unpublish包，另一方面，npm官网并不建议unpublish包。所以除非特殊情况，不建议对已上传的包进行撤销，可以版本迭代。包要删除，可直接在nexus上手动删除(如删除`/data/nexus/storage/npm-release`目录下对应包文件，只能删除tgz包，打包的元信息貌似删除不掉)
    - 参考: https://stackoverflow.com/questions/26358449/how-to-unpublish-npm-packages-in-nexus-oss
    - nexus2不支持unpublish和deprecate，nexus3支持deprecate
    - 手动删除包
        - cd `nexus/storage/<your_npm_repo>/<your_package>/-/`进行删除 (注意不要到your_package目录后执行`cd ./-`，此时-是特殊字符)
        - 然后手动对npm hosted仓库执行nexus的schedules: `Delete npm metadata`(会删除所有npm元数据)和`Rebuild hosted npm metadata`(根据tarballs获取元数据并重建)
        - 此时如果重新推送同样的版本，本地再安装可能存在缓存，需要先清除缓存(**`npm cache clean -f`**清除所有缓存，yarn可以基于某个模块单独清理)，然后删除`package-lock.json`(每次重新安装会校验此文件中的integrity sha512值和远程仓库中的integrity，不一致会报错，所以要先清除)，再重新安装

## 其他

### eclipse-aether解析下载依赖

- [eclipse-aether](http://wiki.eclipse.org/Aether)
    - 可通过提供的groupId和artifactId以及version到指定maven库中解析依赖，并下载jar
- 使用参考
    - https://www.cnblogs.com/xiaosiyuan/articles/5887642.html
    - https://wusandi.github.io/2018/10/29/equinox-aether-usage/
- 案例参考(smjava/maven/eclipse-aether)

### maven-invoker通过API方式执行Maven命令

- pom

```xml
<dependency>
    <groupId>org.apache.maven.shared</groupId>
    <artifactId>maven-invoker</artifactId>
    <version>2.2</version>
</dependency>
```
- 解析pom.xml获取对应依赖案例(smjava/maven/maven-invoker)

```java
/**
 * dependencies.txt 内容为
 *
 * The following files have been resolved:
 *    org.codehaus.plexus:plexus-utils:jar:3.0.20:compile:/Users/smalle/.m2/repository/org/codehaus/plexus/plexus-utils/3.0.20/plexus-utils-3.0.20.jar
 *    org.codehaus.plexus:plexus-component-annotations:jar:1.6:compile:/Users/smalle/.m2/repository/org/codehaus/plexus/plexus-component-annotations/1.6/plexus-component-annotations-1.6.jar
 *    org.apache.maven.shared:maven-invoker:jar:2.2:compile:/Users/smalle/.m2/repository/org/apache/maven/shared/maven-invoker/2.2/maven-invoker-2.2.jar
 */
public static void main(String[] args) throws Exception {
    String destFile = "/Users/smalle/gitwork/github/smjava/maven/maven-invoker/dependencies.txt";
    InvocationRequest request = new DefaultInvocationRequest();
    request.setPomFile(new File("/Users/smalle/gitwork/github/smjava/maven/maven-invoker/pom.xml"));
    request.setGoals(Arrays.asList("dependency:list"));
    Properties properties = new Properties();
    properties.setProperty("outputFile", destFile); // 将输出重定向到此文件(如果只写成dependencies.txt，则会创建到pom文件所在目录)
    properties.setProperty("outputAbsoluteArtifactFilename", "true"); // 输出包含jar包路径
    properties.setProperty("includeScope", "runtime"); // only runtime (scope compile + runtime)
    // if only interested in scope runtime, you may replace with excludeScope = compile
    request.setProperties(properties);

    Invoker invoker = new DefaultInvoker();
    // the Maven home can be omitted if the "maven.home" system property is set
    invoker.setMavenHome(new File("/Users/smalle/software/apache-maven-3.8.4"));
    //invoker.setOutputHandler(null); // not interested in Maven output itself
    invoker.setOutputHandler(s -> System.out.println(s)); // 打印编译过程(重定向到此文件中的内容不会打印)
    InvocationResult result = invoker.execute(request);
    if (result.getExitCode() != 0) {
        throw new IllegalStateException("Build failed.");
    }

    // 读取上述文件打印依赖
    Pattern pattern = Pattern.compile("(?:compile|runtime):(.*)");
    try (BufferedReader reader = Files.newBufferedReader(Paths.get(destFile))) {
        System.out.println("read file...");
        // 文件写入可能有间隔，在此处等待
        while (!"The following files have been resolved:".equals(reader.readLine()));
        String line;
        while ((line = reader.readLine()) != null && !line.isEmpty()) {
            Matcher matcher = pattern.matcher(line);
            if (matcher.find()) {
                // group 1 contains the path to the file
                // /Users/smalle/.m2/repository/org/codehaus/plexus/plexus-utils/3.0.20/plexus-utils-3.0.20.jar
                // ...
                System.out.println(matcher.group(1));
            }
        }
    }
}
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
- 警告`The POM for <name> is invalid, transitive dependencies (if any) will not be available`，且A->B->C的项目依赖关系中，在A项目中编译提示B存在上述问题，从而导致C无法导入
    - 一般是B项目中存在问题：(1)如B模块使用父pom管理version，但是父pom模块没有安装从而出错 (2)B模块中使用了systemPath本地文件夹依赖包(解决方法参考上文[maven项目依赖本地jar包](#maven项目依赖本地jar包))
- Fatal error compiling: 无效的目标发行版
    - 检查`mvn -v`出来的JDK版本是否符合当前项目版本，如果版本不符合可进行设置JAVA_HOME
    - 设置JAVA_HOME
    - 或在`~/.mavenrc`中设置JAVA_HOME
    - 或在%MAVA_HOME%/bin/mvm.cmd中设置JAVA_HOME，参考：https://blog.csdn.net/weixin_42976232/article/details/103246822

## 多模块思考

- 模块组织方式如下
    - 门面
        - 配置类/常量等类有可能其他扩展需要使用，放到门面还是简单实现模块？
    - 简单实现
    - 其他扩展


---

参考文章

[^1]: http://blog.csdn.net/hengyunabc/article/details/47308913 (利用github搭建个人maven仓库)
[^2]: https://yulaiz.com/spring-boot-maven-profiles/ (Spring-Boot application.yml 文件拆分，实现 maven 多环境动态启用 Profiles)
[^3]: https://blog.csdn.net/xhyzjiji/article/details/72731276
[^4]: https://blog.csdn.net/frankcheng5143/article/details/52164939
[^5]: https://www.cnblogs.com/sidesky/p/10651266.html

