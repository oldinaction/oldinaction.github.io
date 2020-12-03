---
layout: "post"
title: "IntelliJ IDEA"
date: "2016-09-17 15:37"
categories: extend
tags: [IDE]
---

## 说明

- IDEA使用久了比较占磁盘，可把`C:\Users\smalle\.IntelliJIdea2018.1\system\index`目录下的索引文件全部删掉释放磁盘空间；如果做了C盘搬家，也可删除目标存储目录，如`D:\FileHistory\smalle\AEZO-E480\Data\C\Users\smalle\.IntelliJIdea2018.1\system\index`

## jetbrains相关编辑器破解

- 在 hosts 文件里面添加如下配置`0.0.0.0 account.jetbrains.com`、`0.0.0.0 www.jetbrains.com``
- 基于激活码破解：http://idea.lanyus.com/getkey
- 基于破解补丁进行破解
    - 下载破解补丁：http://idea.lanyus.com/jar/JetbrainsIdesCrack-4.2-release-sha1-3323d5d0b82e716609808090d3dc7cb3198b8c4b.jar
    - 在`bin/idea64.exe.vmoptions`和`bin/idea64.exe.vmoptions`文件中加入`-javaagent:D:\software\JetbrainsIdesCrack-4.2-release-sha1-3323d5d0b82e716609808090d3dc7cb3198b8c4b.jar`，两个都需要加入
    - 启动idea输入以下注册码

```js
ThisCrackLicenseId-{
"licenseId":"ThisCrackLicenseId",
"licenseeName":"Rover12421",
"assigneeName":"",
"assigneeEmail":"rover12421@163.com",
"licenseRestriction":"For Rover12421 Crack, Only Test! Please support genuine!!!",
"checkConcurrentUse":false,
"products":[
{"code":"II","paidUpTo":"2099-12-31"},
{"code":"DM","paidUpTo":"2099-12-31"},
{"code":"AC","paidUpTo":"2099-12-31"},
{"code":"RS0","paidUpTo":"2099-12-31"},
{"code":"WS","paidUpTo":"2099-12-31"},
{"code":"DPN","paidUpTo":"2099-12-31"},
{"code":"RC","paidUpTo":"2099-12-31"},
{"code":"PS","paidUpTo":"2099-12-31"},
{"code":"DC","paidUpTo":"2099-12-31"},
{"code":"RM","paidUpTo":"2099-12-31"},
{"code":"CL","paidUpTo":"2099-12-31"},
{"code":"PC","paidUpTo":"2099-12-31"}
],
"hash":"2911276/0",
"gracePeriodDays":7,
"autoProlongated":false}
```

## 常用设置

- 新建包文件夹，一定要一层一层的建，或者创建`cn/aezo`的文件夹，不能创建一个`cn.aezo`(不会自动生成两个文件夹)
- for快捷键使用：`list.for`、`arr.for`. **可以在`File`-`Setting`-`Editor`-`General`-`Postfix Completion`中查看**

### java web项目配置(springmvc) [^1]

- 进入到Project Structure：`File - Project Structure`
- 配置步骤
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
- `Run configuration`启动配置。如使用tomcat启动
    - `+` - `tomcat server` - `local`
    - `Application Server`: 本地tomcat路径
    - `VM`：添加`-Dfile.encoding=UTF-8`防止出现乱码
    - `JRE`填写jdk路径
    - `Deployment`中将刚刚的war配置进入
    - 在`Before launch`中加入Build这个war包
- 打包：Build - Build Artifacts - xxx:war - build (在上述Output directory中可看到war包)
- idea报错：Error：java不支持发行版本5的解决方法：https://www.cnblogs.com/wqy0314/p/11726107.html

### maven

- idea自带maven插件
- `pom.xml`检测通过，但是`Maven Projects`中部分依赖显示红色波浪线
    - 法一：先将`pom.xml`中此种依赖删除，然后`reimport`刷新一下依赖，再将刚刚的依赖粘贴上去，重新`reimport`刷新一下
    - 法二：删除`.m2`中此依赖的相关文件夹，重新下载
- 创建示例项目
    - org.apache.maven.archetypes:maven-archetype-quickstart
    - org.apache.maven.archetypes:maven-archetype-site
    - org.apache.maven.archetypes:maven-archetype-webapp

### 其他

- 配置同步到远程
    - File - Settings Repository - 输入远程地址，如保存到github(输入ssh验证的项目地址) - Overwrite Remote同步到远程
- 自动收缩空包文件夹
    - Project浏览Tab - 设置 - Hide Empty Middle Packages

## 插件使用

### 实用

- `jrebel` java热部署(会自动热部署新代码。如果不使用jrebel，springboot-devtools可修改代码后使用`Ctrl+Shif+F9`进行热部署)
    - jrebel破解参考：http://www.cicoding.cn/other/jrebel-activation/
    - 无法热部署场景
        - 修改了Entity，涉及到mybatis的操作无法生效(mybatis缓存了数据类型?)
        - 修改了mybatis mapper和对应文件一般无法生效
        - 修改了方法声明
- `Lombox` 简化代码工具(maven项目中需要加入对应的依赖) [https://projectlombok.org/](https://projectlombok.org/)
    - 使用Builder构造器模式，添加`@Builder`，需要额外添加以下注解`@NoArgsConstructor`、`@AllArgsConstructor`，缺一不可。否则子类继承报错"无法将类中的构造器应用到给定类型"
- `MybatisX` [mybatis-plus提供](https://mybatis.plus/guide/mybatisx-idea-plugin.html)，可自动识别mapper实现(mybatis标识)，集成了MyBatis Generator GUI(未测试成功)，JPA方法命名提示(未测试成功)。Ctrl+Alt可实现相应跳转
    - 类似插件：`Free MyBatis plugin` 可自动识别mapper实现(mybatis标识)，集成了MyBatis Generator GUI
- `MyBatis Log Plugin` 将mybatis日志中的?转换为真实值。在Tools菜单中可打开对应面板
- `CamelCase` 使用`Alt + Shift + U`将字符串在下划线/中划线/大小驼峰中切换，可重复按快捷键进行切换
    - `String Manipulation` 字符串转换(包括下划线/中划线/驼峰等)。鼠标右键会有对应的选项，缺点：无快捷键
- `CodeGlance` 显示代码地图
- `Codota` Codota AI Autocomplete 代码示例，基于类或方法查找网上流行的使用方式。类似的如Aixcode
- `Alibaba Java Coding Guidelines` 阿里巴巴代码规范

### 部分场景

- `RestfulToolkit` 使用`Ctrl + Alt + N`基于路径搜索controller对应的位置
- `Maven Helper` 可显示冲突的maven依赖
    - 此插件依赖`Maven Intergration`，在安装后也要启用
    - 点击pom.xml文件，右下角会出现`Dependency Analyzer`
    - `Dependency Analyzer` - `Conflicts`中显示的即为冲突的依赖
        - 点击其中任何一个依赖，会在右侧显示重复引用的来源(基于版本降序) 
        - 点击右侧某个引用来源，右键可查看引用源码，也可以将低版本从pom中exclude掉来解决冲突
- `PlantUML integration` 基于PlantUML语法画UML图
- `SequenceDiagram` 根据源码生成时序图
- `jclasslib Bytecode viewer` 查看java class字节代码。安装后在View - Show Bytecode With jclasslib(打开一个类可进行查看)

### 其他

- `JMH plugin` Java基准测插件
- `JMeter plugin`
- `leetcode` 算法刷题，参考：https://github.com/shuzijun/leetcode-editor/blob/master/doc/CustomCode_ZH.md
- `Jindent-Source Code Formatter` 自定义javadoc注释(收费，无法破解)
- `Key Promoter X` 快捷键提示和统计快捷使用频率
- `Translation` 翻译插件(可使用系统有道词典代替)
- `Rainbow Brackets` 彩虹圆/尖括号颜色，会把代码中所有括号变色，有点花里胡哨
- `HighlightBracketPair` 彩虹大括号，选中高亮，有点花里胡哨

### 未使用

- `FindBugs-IDEA` 检测代码中可能的bug及不规范的位置，检测的模式相比P3GC更多
- `GsonFormat` 一键根据json文本生成java类
- `MyBatisCodeHelperPro` mybatis代码自动生成插件，大部分单表操作的代码可自动生成

## 快捷键

- 待记忆
    - `F8` 断点调试下一步
    - `Double Shift` 全局文件名查找
    - `Alt + Shift + 上下` 上下移动当前行
    - `Ctrl + Shift + Space` 智能补全(可多次按键扩大搜索范围)
    - `Ctrl + P` 查看方法参数
    - `Ctrl + Q` 查看方法说明
    - `Ctrl + Shift + N` 搜索文件(可选中文件路径后再按键)
    - `Alt + Insert` 自动生成(Getter/Setter等)
    - `Ctrl + Alt + T` 对选中代码生成try...catch/if等包裹语句
    - `Alt + F7` 查询方法的使用关系
    - `Ctrl + ALT + H` 查询方法的调用关系（可以选择引用和被引用）
    - `Ctrl + B` 跳转到声明
    - `Ctrl + E` 最近访问文件
    - `Ctrl + W` 语句感知
    - `Ctrl + Shift + Entry` 完成整句
    - `Ctrl + Shift + F7` 高亮所用之处：把光标放在某元素上，类似与快速查找此文件此元素出现处
    - `Ctrl + H` 类似Navigate - Call Hierarchy 命令查看一个Java类的继承管理
    - `Ctrl + D` 复制行
    - `Ctrl + Y` 删除行
    - `Ctrl shift +` 展开所有方法
    - `Ctrl shift -` 收缩所有方法
- 特殊场景
    - SQL控制台界面
        - `Ctrl + Enter` 执行SQL
        - `Ctrl + Alt + E` 查看最近执行SQL
        - `Ctrl + F12` 查看列定义；选择某一列再点击时，会跳到指定列定义
- 常用快捷键
    - `Ctrl + N` 跳转到类
    - `Ctrl + Shift + F9` 热部署
    - `Ctrl + Shift + F/R` 全局查找/替换(jar包只有下载了源码才可检索)。搜狗输入法快捷键简繁体切换可能会占用`Ctrl+Shift+F`
    - `Ctrl + Shift + Backspace` 回到上次编辑位置
    - `Ctrl + Alt + 左右` 回退(退到上次浏览位置)/前进
- 快捷键图片

![idea-keys](/data/images/2016/09/idea-keys.png)

## javadoc配置与生成

### 配置

- 方式一：使用`Jindent`插件(收费，无法破解)
- 方式二 [^4]
    - 类注释: Editor - File and Code Templates
    - 方法注释：Editor - Live Templates。无法解决 @return 和 @throws

### 生成

- https://blog.csdn.net/vbirdbest/article/details/80296136
- Tools - Generate Javadoc
    - Locale：`zh_CN`
    - other command line arguments：`-encoding UTF-8 -charset UTF-8`
    - 如果有自定义的javadoc标签，则需要在other command line arguments框中增加输入定义`-tag XX:a:YY`，例如：`-tag date:a:日期 -tag description:a:"功能描述"`

### javadoc标签

| 标签          | 描述                                                   | 示例                                                         |
| ------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| @author       | 标识一个类的作者                                       | @author description                                          |
| @deprecated   | 指名一个过期的类或成员                                 | @deprecated description                                      |
| {@docRoot}    | 指明当前文档根目录的路径                               | Directory Path                                               |
| @exception    | 标志一个类抛出的异常                                   | @exception exception-name explanation                        |
| {@inheritDoc} | 从直接父类继承的注释                                   | Inherits a comment from the immediate surperclass.           |
| {@link}       | 插入一个到另一个主题的链接                             | {@link name text}                                            |
| {@linkplain}  | 插入一个到另一个主题的链接，但是该链接显示纯文本字体   | Inserts an in-line link to another topic.                    |
| @param        | 说明一个方法的参数                                     | @param parameter-name explanation                            |
| @return       | 说明返回值类型                                         | @return explanation                                          |
| @see          | 指定一个到另一个主题的链接                             | @see anchor                                                  |
| @serial       | 说明一个序列化属性                                     | @serial description                                          |
| @serialData   | 说明通过writeObject( ) 和 writeExternal( )方法写的数据 | @serialData description                                      |
| @serialField  | 说明一个ObjectStreamField组件                          | @serialField name type description                           |
| @since        | 标记当引入一个特定的变化时                             | @since release                                               |
| @throws       | 和 @exception标签一样.                                 | The @throws tag has the same meaning as the @exception tag.  |
| {@value}      | 显示常量的值，该常量必须是static属性。                 | Displays the value of a constant, which must be a static field. |
| @version      | 指定类的版本                                           | @version info                                                |

## 常用技巧

### Debug调试技巧

- 回退断点：删除掉某个Frame即可，Frame显示的是执行过的和当前执行的帧，如果删除了，则会从上一帧重新调用 [^3]
- 中断Debug/强制返回：右键帧 - Force Return - 填写返回值

### 查看并搜索/调试/编辑jar包源码

- 点击maven视图 - Dependencies - 右键需要下载源码的依赖 - 下载源码 - 之后点击该依赖的类会自动显示源码文件(无源码则显示class反编译文件)。此方法的源码无法修改
- **下载源码并支持全局搜索。**如打印日志，在class文件中是无法全局搜索的，只有下载源码才能进行全局搜索
- 下载源码并调试：class文件是可以通过idea反编译进行调试，但是部分场景很麻烦，如

    ```java
    // 源码如下
    this.foo();
    return this.bar();

    // class文件反编译如下。假设this.bar()执行报错，则在debug class文件时，行显示直接跳过了`var1 = this.bar();`便报错了
    this.foo();
    var1 = this.bar();
    return var1;
    ```
- 下载源码并支持修改
    - 先下载对应源码到某目录，如dir
    - 点击项目管理视图 - Libraries - 点击相关依赖 - 选择Sources - Add添加源码文件 - 选择刚刚目录下的源码(如果源码为maven结构，则选择改源码的src目录)
    - 点击该依赖类 - 编辑 - idea提示此文件不为本项目文件，是否需要修改 - 选择是即可

### 开启Run DashBoard配置

- 当项目存在多个可执行模块时，Run DashBoard配置会自动跳出，如果不跳出可以手动配置，在项目的`.idea/workspace.xml`中找到`<component name="RunDashboard">`节点，在此节点中加入下列配置

```xml
<option name="configurationTypes">
    <set>
        <option value="SpringBootApplicationConfigurationType" />
    </set>
</option>
```

## IDEA开发PHP程序

### 安装php插件 [^2]

- setting -> plugins -> browse repositories -> 输入php
- 没看到的话，往下翻几页看看，找到PHP(LANGUAGES)，安装次数较多的那个

### xdebug使用

- 找到php.ini，搜索xdebug
- 下载xdebug的dll文件，并在php.ini中设置。wamp已经含有这个功能
- 替换下面代码

    ```conf
    [xdebug]
    zend_extension=D:\software\wamp\php\ext\php_xdebug.dll
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

- 在idea中设置php的安装路径

    添加php interpreters指向php的主目录，点击这边的show info按钮，在Loaded extensions里应该可以看到xDebug

    ![php-xdebug](/data/images/2016/09/php-xdebug.png)

- 启动xdebug调试
    - 点击intellij idea工具栏里的 start listen php debug connections.开启调试模式。
    - 点击工具栏里向下的小三角->edit configuration->add new configuartion->php web Application Server里选aezo.cn

    ![php-xdebug](/data/images/2016/09/php-xdebug2.png)

- 打断点，运行程序即可进行调试

## jetbrains相关IDE

### PhpStorm

- 使用前需配置php可执行程序路径(Languages - PHP). 如果使用xampp，则可使用xampp中配置的xdebug
- 进行debug时，创建一个`PHP Web Page`启动配置，此时host和port需要填Apache服务器的host和port（PhpStorm中的启动配置并不会启动服务器，因此需要另外启动Apache等服务器）
- PHPStorm使用Xdebug进行调试时，没打断点也一直进入到代码第一行：去掉勾选Run - Break at first line in PHP Scripts




---

参考文章

[^1]: [java-web项目配置](https://github.com/judasn/IntelliJ-IDEA-Tutorial/blob/newMaster/eclipse-java-web-project-introduce.md)
[^2]: [intellij-idea12-搭建php开发环境](http://blog.csdn.net/ysjjovo/article/details/13292787)
[^3]: https://blog.csdn.net/boss2967/article/details/82864044
[^4]: https://nanyiniu.github.io/2020/09/01/%E4%BB%A3%E7%A0%81%E6%B3%A8%E9%87%8A%E8%A7%84%E8%8C%83/

