---
layout: "post"
title: "Ant"
date: "2019-08-23 14:27"
categories: java
tags: [build]
---

## 简介

- Ant 是一个 Apache 基金会下的跨平台的基于 Java 语言开发的构件工具
- [官网](https://ant.apache.org/)
- 下载及安装：下载压缩包解压后，设置环境变量`ANT_HOME=项目根目录`，并将`%ANT_HOME%\bin`加入到Path环境变量中。`ant -version` 查看安装版本
- 参考文章 [^1]

## 使用

- Ant 构建文件
    - 一般来说，Ant 的构建文件默认为 build.xml，放在项目顶层目录中
- Ant内置属性
    - `ant.file` 该构建文件的完整地址
    - `ant.version` 安装的 Apache Ant 的版本
    - `basedir` 构建文件的基目录的绝对路径，并不一定是整个项目的目录，而是看此命令所在构建文件中`project.basedir`的属性
    - `ant.java.version` Ant 使用的 JAVA 语言的软件开发工具包的版本
    - `ant.project.name` 项目的名字
    - `ant.project.default-target` 当前项目的默认目标
    - `ant.project.invoked-targets` 在当前项目中被调用的目标的逗号分隔列表
    - `ant.core.lib` Ant 的 jar 文件的完整的地址
    - `ant.home` Ant 安装的主目录
    - `ant.library.dir` Ant 库文件的主目录，特别是 ANT_HOME/lib 文件夹
- Ant 属性文件
    - 可将设置属性的信息存储在一个独立的文件中以便更好维护
    - 一般情况下，属性文件都被命名为 build.properties，并且与 build.xml 存放在同一目录层。可以基于部署环境创建，如：build.properties.dev 和 build.properties.test
    - build.properties格式如

        ```bash
        # version propertie
        current.version=1.0.0
        profile=dev
        ```
- Ant 数据类型
    - 文件集
    - 模式集合
    - 文件列表
    - 过滤器集合
    - 路径

## 示例

### build.xml示例

- build.xml文件
    - 在此文件所在目录执行`ant`将打印`Hello World - Welcome to Apache Ant 1.9.14 - You are at www.aezo.cn`

```xml
<?xml version="1.0"?>
<!-- name表示项目的名称，default表示构建脚本默认运行的目标，即指定默认的 target。一个项目 (project) 可以包含多个目标 (target) -->
<project name="Hello World Project" default="info" basedir=".">
    <!-- 导入一个配置文件 macros.xml -->
    <import file="macros.xml"/>
    
    <!-- 自定义ant属性，Ant内置属性见下文。可被命令行参数覆盖，如 `ant info -Dsitename="my sitename..."` -->
    <property name="sitename" value="www.aezo.cn"/>
    <!-- 自定义ant属性文件 -->
    <property file="build.properties"/>
    <!-- 获取当前时间并存入到 nowTm 参数中。也可通过命令行参数-D进行覆盖 -->
    <tstamp>
        <format property="nowTm" pattern="yyyyMMddHHmmss"/>
    </tstamp>
    <!-- 指定环境变量参数为 env，如果存在env.WELCOME则放入到welcome参数中，否则welcome取默认值hell world ... -->
    <property environment="env" />
	<condition property="welcome" value="${env.WELCOME}" else="hell world ...">  
        <isset property="env.WELCOME" />
	</condition>

    <!-- 
        name: 表示目标的名称
        depends: 用于描述目标直接的依赖关系
        if: 用于验证指定的属性是否存在，若不存在，所在 target 将不会被执行
        unless: 除非。该属性的功能与 if 属性的功能正好相反
     -->
    <target name="info">
        <echo>Hello World - Welcome to Apache Ant ${ant.version} - You are at ${sitename}. ${nowTm} </echo>
    </target>
    <!-- 执行命令 `ant package` 后，会先调用info，然后执行package -->
    <target name="package" depends="info">
        <echo>1.build.properties 中 profile 属性值为：${profile}</echo><!-- dev -->
        <!-- 调用自定宏 -->
        <macrodefTest tarName="math" srcPath="./src"/>
    </target>

    <!-- 文件集：文件集的数据类型代表了一个文件集合。它被当作一个过滤器，用来包括或移除匹配某种模式的文件
        此时表示在此构建文件所在目录，文件集选择源文件夹中所有的 .java 文件，除了那些包含有 'Test' 单词的文件，且区分大小写 -->
    <fileset dir="${basedir}" casesensitive="yes">
        <include name="/.java"/>
        <exclude name="/Test"/>
    </fileset>

    <!-- 模式集合。上述文件集类似写法 -->
    <fileset dir="${src}" casesensitive="yes">  
        <patternset refid="java.files.without.tests"/>
    </fileset>
    <patternset id="java.files.without.tests">
        <include name="src//.java"/>
        <exclude name="src//Test"/>
    </patternset>

    <!-- 文件列表：同时其不支持通配符 -->
    <filelist id="config.files" dir="${basedir}">
        <file name="applicationConfig.xml"/>
        <file name="web.xml"/>
    </filelist>
    <filelist id="config.files2" dir="." files="applicationConfig.xml,web.xml"/>

    <!-- 拷贝任务示例：将文件从一个地址拷贝到另一个地址 -->
    <copy todir="${output.dir}">
        <fileset dir="${basedir}/releasenotes" includes="/.txt"/>
        <!-- 过滤器集合 -->
        <filterset>
            <filter token="VERSION" value="${current.version}"/>
        </filterset>
    </copy>

    <!-- 路径：path 数据类型通常被用来表示一个类路径。各个路径之间用分号或者冒号隔开。然而，这些字符在运行时被替代为执行系统的路径分隔符 -->
    <path id="build.classpath.jar">
        <pathelement path="${build.dir}/classes"/>
        <fileset dir="lib">
            <include name="*/.jar"/>
        </fileset>
    </path>

    <!-- 交互 -->
    <target name="get-data">
        <input addproperty="user.username" message="Enter username: "/>
        <input addproperty="user.sex" message="Select your sex, B = Boy,G = Girl" validargs="B,G"/>
        <condition property="isBoy">
            <equals arg1="${user.sex}" arg2="B"/>
        </condition>
        <condition property="isGirl">
            <equals arg1="${user.sex}" arg2="G"/>
        </condition>
        <!-- 调用其他target -->
        <antcall target="show-data-confirm"/>
    </target>
    <target name="show-data-confirm">
        <echo>------------------------------------</echo>
        <echo message="user.username = ${user.username}"/>
        <echo>user.sex = ${user.sex}</echo>
        <echo>------------------------------------</echo>
        <input addproperty="user.continueYN" message="Continue Y or N" validargs="N,n,Y,y"/>
    </target>

    <!-- 执行shell命令 -->
    <target name="exec-shell" description="exec shell">  
        <exec executable="/bin/sh">  
            <arg line="-c echo hello world"/>  
        </exec>  
    </target>
    <!-- 执行windows命令 -->
    <target name="exec-exe" description="Copy files from  project1 to project2">
        <!-- cmd.exe /c " cd D:/demo/ && docker build -t test:v1 . " -->
        <exec executable="cmd.exe">
            <arg line="/c &quot; cd ${basedir}/ &amp;&amp; docker build -t test:v1 . &quot; "/>
        </exec>
    </target> 
</project>
```
- 被引入配置macros.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="Ant - Macros">
    <condition property="antatleast171">
        <antversion atleast="1.7.1"/>
    </condition>

    <!-- 宏名称 -->
    <macrodef name="macrodefTest">
        <!-- 定义参数 -->
        <attribute name="tarName" />
        <attribute name="srcPath" />
        <!-- 执行内容 -->
        <sequential>
            <echo message="... building now ...."/>  
            <javac debug="false" destdir="bin" source="1.7" target="1.7" includeantruntime="on">  
                <src path="${src.dir}"/>
                <classpath refid="master-classpath"/>
                <excludesfile name="exclude.@{tarName}"/>
            </javac>
            <echo message="... make @{tarName} jar ..."></echo>  
            <jar jarfile="@{tarName}.jar" basedir="./bin"/>  
            <move file="./@{tarName}.jar" tofile="./demo/@{tarName}.jar" overwrite="true"/>  
        </sequential>
    </macrodef>
</project>
```

### 编译项目

- 项目目录结构为(根目录D:/test/demo)

```html
+---db
+---src
.  +---dao
.  +---entity
.  +---util
.  +---web
+---war
   +---images
   +---js
   +---META-INF
   +---styles
   +---WEB-INF
      +---classes
      +---jsp
      +---lib
```
- D:/test/build.xml

```xml
<?xml version="1.0"?>
<project name="demo" basedir="." default="build">
    <property name="src.dir" value="src"/>
    <property name="web.dir" value="war"/>
    <property name="build.dir" value="${web.dir}/WEB-INF/classes"/>
    <property name="name" value="demo"/>

    <path id="master-classpath">
        <fileset dir="${web.dir}/WEB-INF/lib">
            <include name="*.jar"/>
        </fileset>
        <pathelement path="${build.dir}"/>
    </path>

    <target name="build" description="Compile source tree java files">
        <mkdir dir="${build.dir}"/>
        <!-- 编译命令，并给javac命令提供参数 -->
        <javac destdir="${build.dir}" source="1.7" target="1.7">
            <src path="${src.dir}"/>
            <classpath refid="master-classpath"/>
        </javac>
    </target>

    <target name="clean" description="Clean output directories">
        <delete>
            <fileset dir="${build.dir}">
            <include name="**/*.class"/>
            </fileset>
        </delete>
    </target>
    
    <!-- 生成jar包：
        basedir	表示输出 JAR 文件的基目录。默认情况下，为项目的基目录。
        compress	表示告知 Ant 对于创建的 JAR 文件进行压缩。
        keepcompression	表示 project 基目录的绝对路径。
        destfile	表示输出 JAR 文件的名字。
        duplicate	表示发现重复文件时 Ant 执行的操作。可以是添加、保存、或者是使该重复文件失效。
        excludes	表示移除的文件列表，列表中使用逗号分隔多个文件。
        excludesfile	与上同，但是使用模式匹配的方式排除文件。
        inlcudes	与 excludes 正好相反。
        includesfile	表示在被归档的文件模式下，打包文件中已有的文件。与 excludesfile 相反。
        update	表示告知 Ant 重写已经建立的 JAR 文件。
     -->
    <target name="build-jar">
        <jar destfile="${web.dir}/lib/util.jar"
            basedir="${build.dir}/classes"
            includes="demo/util/**"
            excludes="**/Test.class">

            <manifest>
                <attribute name="Main-Class" value="cn.aezo.demo.util.Test"/>
            </manifest>
        </jar>
    </target>

    <!--生成war
        webxml	web.xml 文件的路径
        lib	指定什么文件可以进入 WEB-INF\lib 文件夹的一个组
        classes	指定什么文件可以进入 WEB-INF\classes 文件夹的一个组
        metainf	指定生成 MANIFEST.MF 文件的指令
    -->
    <target name="build-war">
        <war destfile="demo.war" webxml="${web.dir}/web.xml">
            <fileset dir="${web.dir}/WebContent">
                <include name="**/*.*"/>
            </fileset>

            <lib dir="thirdpartyjars">
                <exclude name="portlet.jar"/>
            </lib>
            <classes dir="${build.dir}/web"/>
        </war>
    </target>

    <!-- 生成文档。可执行命令 `ant generate-javadoc` -->
    <target name = "generate-javadoc">
        <javadoc packagenames="demo.*" sourcepath="${src.dir}" 
            destdir = "doc" version = "true" windowtitle = "Demo Application">

            <doctitle><![CDATA[= Demo Application =]]></doctitle>

            <bottom>
                <![CDATA[Copyright © 2011. All Rights Reserved.]]>
            </bottom>

            <group title = "util packages" packages = "demo.util.*"/>
            <group title = "web packages" packages = "demo.web.*"/>
            <group title = "data packages" packages = "demo.entity.*:demo.dao.*"/>
        </javadoc>

        <echo message = "java doc has been generated!" />
    </target>

    <!-- Ant 执行 Java 代码 -->
    <target name="run-java">
        <java fork="true" failonerror="yes" classname="RunJavaTest">
            <arg line="hello..."/>
        </java>
    </target>

    <!-- Junit集成 -->
    <target name="junit-test">
        <junit haltonfailure="true" printsummary="true">
            <test name="cn.aezo.demo.UtilsTest"/>
        </junit>
    </target>

    <!-- 扩展 Ant -->
    <target name="custom-test">
        <taskdef name="custom" classname="cn.aezo.demo.ant.MyTask" />
        <custom message="Hello World!"/>
    </target>
</project>
```
- 上述脚本使用到的相关测试类

```java
// RunJavaTest.java
public class RunJavaTest {
   public static void main(String[] args) {
      String hello = args[0];
      System.out.println(hello);
   }
}

// MyTask.java
public class MyTask extends Task {
    String message;

    public void execute() throws BuildException {
        log("Message: " + message, Project.MSG_INFO); // [custom-test] Message : Hello World!
    }

    public void setMessage(String message) {
        this.message= message;
    }
}
```

---

参考文章

[^1]: https://www.w3cschool.cn/ant/
