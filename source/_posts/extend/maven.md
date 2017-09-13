---
layout: "post"
title: "maven"
date: "2016-12-29 10:18"
categories: [extend, tools]
tags: [maven]
---

## maven简介


## maven实战

### maven镜像修改
    - 在~/.m2目录下的settings.xml文件中，（如果该文件不存在，则需要从maven/conf目录下拷贝一份），找到<mirrors>标签，添加如下子标签

        ```xml
            <mirror>  
                <id>alimaven</id>  
                <name>aliyun maven</name>  
                <url>http://maven.aliyun.com/nexus/content/groups/public/</url>  <mirrorOf>central</mirrorOf>          
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

## 打包

- 打包命令：`mvn install`、`mvn package`
	- 跳过测试进行打包：`mvn install -DskipTests`. 方式二
	
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