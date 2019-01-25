---
layout: "post"
title: "IntelliJ IDEA"
date: "2016-09-17 15:37"
categories: extend
tags: [IDE]
---

## IntelliJ IDEA简介

## 常用设置

- 新建包文件夹，一定要一层一层的建，或者创建`cn/aezo`的文件夹，不能创建一个`cn.aezo`(不会自动生成两个文件夹)
- for快捷键使用：`list.for`、`arr.for`. **可以在`File`-`Setting`-`Editor`-`General`-`Postfix Completion`中查看**
- 代码注释设置 https://blog.csdn.net/weixin_39591795/article/details/78844428
    - 类注释: Editor - File and Code Templates
    - 方法注释：Editor - Live Templates

### java web项目配置(springmvc) [^1]

1. 进入到Project Structure：`File - Project Structure`
2. 配置步骤
    - `Project` 项目级别
        - 主要是project compiler output的位置(src的编译位置)：如`D:/myproject/classes`(使用默认即可)，为对应WEB-INF下的classes目录
    - `Modules` 模块级别，项目可能包含多个模块，不同的模块可设置对应的编译输入路径和依赖。一般项目就一个模块
        - `Sources` 将src目录标记成Sources目录**（如果是maven项目则标记java、test目录，即包名的上级目录）**
        - `Paths` 使用modules compiler output path，设置路径为`D:/myproject/mymodule/target/classes`。主要解决idea自身编译(使用默认的即可)
        - `Dependencies` 加入jdk、tomcat、其他依赖jar(如`/WEB-INF/lib`中的jar，如果是maven依赖则不需要加入)。主要解决idea自身编译(语法检查)
    - `Libraries` 如将`/WEB-INF/lib`中的所有jar定义一个目录，直接加入到`Dependencies`中
    - `Facets`
        - 点击`+` - `web`
        - `Web Module Deployment Descriptor`为`/myproject/WebRoot/WEB-INF/web.xml`
        - `Web Resource`为`/myproject/WebRoot`
        - 勾选`Source Roots`
    - `Artifacts` 根据上面的配置，最终打包成一个war包部署到tomcat中。(Artifacts是maven中的一个概念，表示项目modules如何打包，比如jar,war,war exploded,ear等打包形式，一个项目或者说module有了artifacts就可以部署到web应用服务器上了，注意artifact的前提是已经配置好module)
        - 点击`+` - `Web Application: Exploded` - `From Modules`
            - `Output directory`为`/testStruts2/WebRoot`
                - WEB-INFO/lib下的jar都要显示在此目录
        - 点击`+` - `Web Application: Archive` - `For "XXX: Exploded"` (主要用于打包)
            - `Output directory`为`D:/myproject/war`
        - `web application exploded` 是以文件夹形式（War Exploded）发布项目，选择这个，发布项目时就会自动生成文件夹在指定的output directory
        - `web application archive` 是war包形式，每次都会重新打包全部的,将项目打成一个war包在指定位置
        - 如果是maven项目：选中Available Elements中的依赖，将需要的依赖加入到WEB-INF/lib中(右键，put into WEB-INF/lib. tomcat相关依赖无需加入，因为最终Artifacts会部署到tomcat容器)。否则像struts2会报错`java.lang.ClassNotFoundException: org.apache.struts2.dispatcher.ng.filter.StrutsPrepareAndExecuteFilter`
3. `Run configuration`启动配置。如使用tomcat启动
    - `+` - `tomcat server` - `local`
    - `Application Server`: 本地tomcat路径
    - `VM`：添加`-Dfile.encoding=UTF-8`防止出现乱码
    - `JRE`填写jdk路径
    - `Deployment`中将刚刚的war配置进入
    - 在`Before launch`中加入Build这个war包
4. 打包：Build - Build Artifacts - xxx:war - build (在上述Output directory中可看到war包)

### maven

- idea自带maven插件
- `pom.xml`检测通过，但是`Maven Projects`中部分依赖显示红色波浪线
    - 法一：先将`pom.xml`中此种依赖删除，然后`reimport`刷新一下依赖，再将刚刚的依赖粘贴上去，重新`reimport`刷新一下
    - 法二：删除`.m2`中此依赖的相关文件夹，重新下载

## 插件使用

- `jrebel` java热部署. **修改代码后使用`Ctrl+Shif+F9`进行热部署**
    - jrebel破解可使用`myJRebel`
- `Lombox` 简化代码工具 [https://projectlombok.org/](https://projectlombok.org/)
- `MybatisX` 可自动识别mybatis的mapper(实现)，Ctrl+Alt可实现相应跳转
- `PlantUML integration` 基于PlantUML语法画UML图

## 快捷键

- 常用快捷键
    - `Ctrl + Shif + F9` 热部署
    - `Ctrl + Shifg + Space` 智能补全
    - `Ctrl + Shif + F/R` 全局查找/替换(jar包只有下载了源码才可检索)
    - `Ctrl + Alt + 左右` 回退(退到上次浏览位置)/前进
    - `Alt + Shift + 上下` 上下移动当前行
    - `Ctrl + Shift + Backspace` 回到上次编辑位置
    - `Ctrl + P` 查看方法参数
    - `Ctrl + Q` 查看方法说明
    - `Ctrl + E` 最近访问文件
    - `Ctrl + W` 语句感知
    - `Ctrl + B` 跳转到声明
    - `Ctrl + N` 跳转到类
    - `Ctrl + Shif + N` 搜索文件(可选中文件路径后再按键)
    - `Ctrl + Shift + Entry` 完成整句
    - `Alt + Insert` 自动生成(Getter/Setter等)
    - `Ctrl + Shift + F7` 高亮所用之处：把光标放在某元素上，类似与快速查找此文件此元素出现处

- 快捷键图片

![idea-keys](/data/images/2016/09/idea-keys.png)

## IDEA开发PHP程序

### 安装php插件 [^2]

1. setting -> plugins -> browse repositories -> 输入php
2. 没看到的话，往下翻几页看看，找到PHP(LANGUAGES)，安装次数较多的那个

### xdebug使用

1. 找到php.ini，搜索xdebug
2. 下载xdebug的dll文件，并在php.ini中设置。wamp已经含有这个功能
3. 替换下面代码

    ```html
    [xdebug]  
    xdebug.remote_enable=on  
    xdebug.remote_host=localhost  
    xdebug.remote_port=9000  
    ;下面两项和Intellij idea里的对应  
    xdebug.idekey=idekey  
    xdebug.remote_handler=dbgp  
    xdebug.remote_mode=req  
    ;下面这句很关键，不设置intellij idea无法调试  
    xdebug.remote_autostart=1  
    ;调试配置，详细的可以参考phpinfo页面进行配置  
    xdebug.auto_trace=on  
    xdebug.collect_params=on  
    xdebug.collect_return=on  
    xdebug.trace_output_dir="../xdebug"  
    xdebug.profiler_enable=on  
    xdebug.profiler_enable_trigger = on
    xdebug.profiler_output_name = cachegrind.out.%t.%p
    xdebug.profiler_output_dir="../xdebug"  
    xdebug.collect_vars=on  
    xdebug.cli_color=on
    ```

4. 在idea中设置php的安装路径

    添加php interpreters指向php的主目录，点击这边的show info按钮，在Loaded extensions里应该可以看到xDebug

    ![php-xdebug](/data/images/2016/09/php-xdebug.png)

5. 启动xdebug调试
    - 点击intellij idea工具栏里的 start listen php debug connections.开启调试模式。
    - 点击工具栏里向下的小三角->edit configuration->add new configuartion->php web Application Server里选aezo.cn

    ![php-xdebug](/data/images/2016/09/php-xdebug2.png)

6. 打断点，运行程序即可进行调试










---

参考文章

[^1]: [java-web项目配置](https://github.com/judasn/IntelliJ-IDEA-Tutorial/blob/newMaster/eclipse-java-web-project-introduce.md)
[^2]: [intellij-idea12-搭建php开发环境](http://blog.csdn.net/ysjjovo/article/details/13292787)
