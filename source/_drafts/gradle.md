---
layout: "post"
title: "Gradle"
date: "2020-11-08 17:40"
categories: java
tags: [build]
---

## 简介

- [官网](https://gradle.org/)
- Gradle 是一个通用的构建工具，它能构建任何基于你的构建脚本的东西。如果构建Java项目，引入构建java的插件(添加 task 到 project，如编译、打包、生成javadoc等)即可
- 在 Gradle 中两个顶级概念：project 项目和 task 任务 [^1]

## 安装命令

### 镜像

- 对所有项目有效：创建`用户目录/.gradle/init.gradle`文件

```groovy
allprojects{
    repositories {
        def ALIYUN_REPOSITORY_URL = 'http://maven.aliyun.com/nexus/content/groups/public'
        def ALIYUN_JCENTER_URL = 'http://maven.aliyun.com/nexus/content/repositories/jcenter'
        all { ArtifactRepository repo ->
            if(repo instanceof MavenArtifactRepository){
                def url = repo.url.toString()
                if (url.startsWith('https://repo1.maven.org/maven2')) {
                    project.logger.lifecycle "Repository ${repo.url} replaced by $ALIYUN_REPOSITORY_URL."
                    remove repo
                }
                if (url.startsWith('https://jcenter.bintray.com/')) {
                    project.logger.lifecycle "Repository ${repo.url} replaced by $ALIYUN_JCENTER_URL."
                    remove repo
                }
            }
        }
        maven {
			url ALIYUN_REPOSITORY_URL
            url ALIYUN_JCENTER_URL
        }
    }
}
```
- 对单个项目有效：在项目的build.gradle文件中添加以下内容

```groovy
buildscript {
    repositories {
        maven { url 'http://maven.aliyun.com/nexus/content/groups/public/' }
        maven { url 'http://maven.aliyun.com/nexus/content/repositories/jcenter' }
    }
    dependencies {
    }
}

allprojects {
    repositories {
        maven { url 'http://maven.aliyun.com/nexus/content/groups/public/' }
        maven { url 'http://maven.aliyun.com/nexus/content/repositories/jcenter' }
    }
}
```

### 命令

- 运行 Gradle 是使用 `gradle` 命令行，命令行会寻找项目的根目录下 `build.gradle` 的文件，运行完后会在项目目录创建`.gradle`文件夹保存构建信息

```bash
gradle -v # 查看版本
gradle -h # 帮助

# USAGE: gradle [option...] [task...]
-q      # 安静模式，仅显示错误日志
```

## 脚本

### Hello World

- 创建文件`build.gradle`，然后执行`gradle hello`，命令行会打印`Hello world!`

```groovy
task hello {
	doLast {
		println 'Hello world!'
	}
}
```

### 编译Java项目

```groovy
apply plugin: 'java' // 引入java构建插件
apply plugin: 'eclipse' // 创建 Eclipse 特点的描述文件，比如 .project，需要添加插件

// 自定义 MANIFEST.MF 内容
sourceCompatibility = 1.5 // 源码JDK版本
version = '1.0.0' // 项目版本
jar {
    manifest {
        attributes 'Implementation-Title': 'Gradle Quickstart',
                   'Implementation-Version': version
    }
}

// 增加外部依赖仓库
repositories {
    mavenCentral()
}

// 依赖项
dependencies {
    // compile(编译项目所需依赖) runtime(生产类在运行时所需的依赖) testCompile testRuntime
    compile group: 'commons-collections', name: 'commons-collections', version: '3.2'
    testCompile group: 'junit', name: 'junit', version: '4.+'
}

test {
    // 执行测试时，增加系统参数
    systemProperties 'property': 'value'
}

// 要发布 JAR 的位置，可以是远程或多个位置
uploadArchives {
    repositories {
       flatDir {
           dirs 'repos'
       }
    }
}
```




---

参考文章

[^1]: https://github.com/waylau/Gradle-2-User-Guide
