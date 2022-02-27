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

## 安装和命令

### 安装

```bash
# mac
brew install gradle
```

### 镜像

- 对所有项目有效：创建`用户目录/.gradle/init.gradle`文件

```groovy
allprojects{
    repositories {
        def ALIYUN_REPOSITORY_URL = 'http://maven.aliyun.com/nexus/content/groups/public'
        def ALIYUN_JCENTER_URL = 'http://maven.aliyun.com/nexus/content/repositories/jcenter' // 已废弃: 停止更新
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
- 对单个项目有效：在项目的`build.gradle`文件中添加以下内容，配置好后使用Sync同步依赖

```groovy
buildscript {
    // https://docs.gradle.org/7.0.2/dsl/org.gradle.api.artifacts.dsl.RepositoryHandler.html
    repositories {
        // gradle内置中心仓库
        // google()
        // jcenter()
        // mavenCentral()
        // mavenLocal()

        // 使用镜像
        maven { url 'https://maven.aliyun.com/repository/google' } // Android项目需要
        maven { url 'https://maven.aliyun.com/repository/jcenter' } // 已经不再更新
        maven { url 'http://maven.aliyun.com/nexus/content/groups/public' }
    }
    // 依赖写法
    dependencies {
        // Android项目为例。最终会把包下载到：C:\Users\smalle\.gradle\caches\modules-2\files-2.1\com.android.tools.build\gradle目录
        classpath 'com.android.tools.build:gradle:4.2.0' // 和Android Studio版本没有关系
        classpath group: 'commons-codec', name: 'commons-codec', version: '1.2'
    }
}

// 建议也配置一下。否则像Android项目可能会报错Could not resolve all files for configuration ':_internal_aapt2_binary'.(在启动时内部模块才会下载aapt2依赖)
allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        maven { url 'http://maven.aliyun.com/nexus/content/groups/public' }
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
// build.gradle 基于 groovy 语法
// task为gradle关键字，hello为Task名，doLast为gradle关键字(表示最后执行)
task hello {
	doLast {
		println 'Hello World!'
	}
}

// 或者使用 build.gradle.kts 基于 Kotlin 语法
tasks.register("hello") {
    doLast {
        println("Hello World!")
    }
}
```

### Task

- 创建文件`build.gradle`(见下文)，然后执行`gradle -q run`

```bash
# 案例一打印结果如下
gradle -q # 或者执行 `gradle -q run`(仅不会调用clean任务)、`gradle -q run clean`

<< EOF
run...                                                      
hello...                                                    
Hello World! myHelloProperty: myValue                       
Hi~! myHelloProperty: myValue                               
此任务名为：hello                                                 
Hello Ink                                                   
 * a.txt *                                 
aaa                                                         
a.txt Checksum: 47bce5c74f589f4867dbd57e9ca9f808            
 * b.txt *                                           
bbb                                                         
b.txt Checksum: 08f8e0260c64418510cefb2b06eee5cd            
I'm task number 2                                           
I'm task number 3                                           
I'm task number 0                                           
原始值: my_name                                                
转成大写: MY_NAME                                               
0 1 2 3 Run doLast! myHelloProperty: myValue               
Cleaning...                                                 
EOF

# 案例二
gradle -q release

<< EOF
run...
hello...
We build the zip with version=1.0
We release now
EOF

# 案例三
gradle -q release

<< EOF
run...
hello...
hello world encode: aGVsbG8gd29ybGQ=
EOF
```
- build.gradle

```groovy
// https://docs.gradle.org/current/userguide/tutorial_using_tasks.html

import org.apache.commons.codec.binary.Base64; // 案例三需要

buildscript { // 案例三需要
    // 依赖仓库地址
    repositories {
        mavenCentral()
    }
    // 引入依赖。此时脚本中可以使用 org.apache.commons.codec.binary.Base64 类
    dependencies {
        classpath group: 'commons-codec', name: 'commons-codec', version: '1.2'
    }
}

// 案例一
// 执行命令`gradle`时，则会依次执行默认Task
defaultTasks 'run', 'clean'

println 'run...'

task hello {
    // 添加额外参数
    ext.myHelloProperty = "myValue"
    // 任务最先执行
    doFirst {
        println "Hello World! myHelloProperty: ${hello.myHelloProperty}" // 变量必须在双引号中使用
    }
    // 任务最后执行
	doLast {
		println "Hi~! myHelloProperty: ${hello.myHelloProperty}"
	}
    // 先于 doFirst, doLast 运行
	println 'hello...'
}
task run {
    // 依赖其他任务(此时会把hello整个任务执行完成，尽管部分逻辑再下文才指定，如hello.doLast)
    dependsOn hello
    // 懒加载依赖(可加载未定义的Task，如定义在此Task的下方，或定义在其他子project中)，此时不能通过 shortcut notations(见下文) 访问任务信息
    dependsOn 'varTest'
    dependsOn 'task0' // 下文的动态Task
    dependsOn 'loadfile' // 下文Task
	doLast {
		println "Run doLast! myHelloProperty: ${hello.myHelloProperty}"
	}
}
task varTest {
    doLast {
        String someString = 'my_name'
        println "原始值: $someString"
        println "转成大写: ${someString.toUpperCase()}"
        4.times { print "$it " }
    }
}
// Dynamic tasks 动态Task
4.times { counter ->
    task "task$counter" {
        doLast {
            println "I'm task number $counter"
        }
    }
}
// 基于API操作Task
task0.dependsOn task2, task3
// 可以往任务上添加多个doFirst和doLast，会按照顺序执行
hello.doLast {
    println "此任务名为：$hello.name" // shortcut notations(每个任务可作为构建脚本的属性来访问)
}
hello.configure {
    doLast {
        println 'Hello Ink'
    }
}
// Ant Tasks：在 Gradle 中使用 Ant 参考 https://docs.gradle.org/current/userguide/ant.html#ant
task loadfile {
    doLast {
		// 调用自定义函数。需要在当前文件目录创建antLoadfileResources目录，并创建a.txt(aaa)、b.txt(bbb)
		fileList('./antLoadfileResources').each { File file ->
			// 基于 AntBuilder 执行 ant.loadfile 等目标(ant target)
			ant.loadfile(srcFile: file, property: file.name) // 将文件内容进行加载，保存到属性 file.name 中
            ant.checksum(file: file, property: "cs_$file.name") // 对文件进行 Checksum，将值保存在属性 "cs_$file.name" 中
			println " * $file.name *"
			println "${ant.properties[file.name]}" // 提出属性值(此时为文件内容)
            println "$file.name Checksum: ${ant.properties["cs_$file.name"]}"
        }
    }
}
// 自定义函数
File[] fileList(String dir) {
    file(dir).listFiles({file -> file.isFile()} as FileFilter).sort()
}

task clean {
    doLast {
        println 'Cleaning...'
    }
}

// 案例二
task distribution {
    doLast {
        println "We build the zip with version=$version"
    }
}
task release {
    dependsOn 'distribution'
    doLast {
        println 'We release now'
    }
}
gradle.taskGraph.whenReady { taskGraph ->
    if (taskGraph.hasTask(":release")) {
        // 不能改成其他变量
        version = '1.0'
    } else {
        version = '1.0-SNAPSHOT'
    }
}

// 案例三
task encode {
    doLast {
        def byte[] encodedString = new Base64().encode('hello world'.getBytes())
        println "hello world encode: " + new String(encodedString)
    }
}
```

### 多项目构建

- https://docs.gradle.org/current/userguide/multi_project_builds.html

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
