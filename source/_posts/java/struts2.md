---
layout: "post"
title: "struts2"
date: "2017-05-06 18:06"
categories: [java]
tags: [ssh, mvc]
---

## 介绍

1. struts2是 struts1和WebWork的结合
2. **struts2的本质就是将请求与视图分开** (struts2原理：**视频09**)
3. 官网：[http://struts.apache.org/](http://struts.apache.org/), 下文基于版本2.3.24(当前更新到2.5.10)
4. 所需jar包：struts2/lib下的jar包

    ```html
    commons-fileupload-1.3.1.jar
    commons-io-2.2.jar
    commons-lang3-3.2.jar
    freemarker-2.3.22.jar
    javassist-3.11.0.GA.jar
    ognl-3.0.6.jar
    struts2-core-2.3.24.1.jar
    xwork-core-2.3.24.1.jar
    ```
5. struts知识点
    - Action
    	- a)namespace（掌握）
    	- b)path（掌握）
    	- c)DMI（掌握）
    	- d)wildcard（掌握）
    	- e)接收参数（掌握前两种）
    	- f)访问request等（掌握Map IOC方式）
    	- g)简单数据验证（掌握addFieldError和`<s:fieldError>`）
    - Result
    	- a)结果类型（掌握四种，重点两种）
    	- b)全局结果（掌握）
    	- c)动态结果（了解）
    - **OGNL表达式**（精通）
    	- a)# % $
    - Struts标签
    	- a)掌握常用的
    - 声明式异常处理（了解）
    - I18N（了解）
    - CRUD的过程（最重要是设计与规划）（精通）
    - Interceptor的原理（掌握）***视频中分析了Struts2源码***
    - 类型转换（掌握默认，了解自定义）

## Hello World

- web.xml中加入

    ```xml
    <!-- struts2的核心拦截器 -->
    <filter>
        <filter-name>struts2</filter-name>
        <filter-class>org.apache.struts2.dispatcher.ng.filter.StrutsPrepareAndExecuteFilter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>struts2</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
    ```
- 在src目录新建struts.xml(注意路径为src, 名称为struts.xml)

    ```xml
    <struts>
        <constant name="struts.devMode" value="true" />

        <package name="default" namespace="/" extends="struts-default">
            <action name="index"><!-- 省略class, 则自动调用xwork的一个ActionSupport类 -->
                <result>/index.jsp</result>
            </action>
        </package>

    </struts>
    ```
- 扩展
    - 给jar包导入源码和doc文档

        > - （1）给jar包导入源码(给struts2-core-2.3.24.1.jar导入源码)：右键相应jar包->properties->Java Source Attachment->External location->External Folder->D:/Java/struts-2.3.24.1/src/core/src/main/java
        > - （2）给此jar包导入doc文档：右键相应jar包->properties->Javadoc Location->javadoc URL->D:/Java/struts-2.3.24.1/docs/struts2-core/apidocs(定位到相应类，按F1，点击javadoc查看相应文档)

    - 添加XML文件自动提示功能

        > - （1）解压struts-2.3.24.1\lib\struts2-core-2.3.24.1.jar
        > - （2）记录struts.xml内DOCTYPE的一个值http://struts.apache.org/dtds/struts-2.3.dtd
        > - （3）Windows->搜索catalog->XML catalog->add->{Location:struts-2.3.24.1\lib\struts2-core-2.3.24.1\struts-2.3.dtd, Key type:URL, Key:http://struts.apache.org/dtds/struts-2.3.dtd}

    - 本地拷贝项目

        > - 需要修改Web Context-root(项目右键->properties->MyEclipse->Project Facets->Web)


## 知识点

### struts.xml

1. package
- `package`(是为了区分重名的action，类似于java中的包)
    - name:包名
    - namespace:命名空间，此namespace和action中name的值的组合不能重复
        - （1）namespace决定了action的访问路径，默认为""，可以接受所有路径的action
        - （2）namespace可以写为/，或者/xxx，或者/xxx/yyy，对应的action访问路径如/index.action，/xxx/index.action，或者/xxx/yyy/index.action(其中index为action的属性name值，后面的.action可省略)
        - （3）package和namespace最好用模块来进行命名
    - extends:继承了那个包，所有的包都继承了`struts-default`，来自struts2-core-2.3.24.1.jar->struts-default.xml
- `package`>`action`
    - name:此action名称(在浏览器的url中要访问此action就要输入此名称)
    - class:当访问此action时，就会调用相应的java类(如果没有就默认访问ActionSupport，ActionSupport是xwork的一个类，他实现了Action接口；**实际中一般使用类继承ActionSupport**)
        - **每一个访问请求都会重新new一个对象**
    - method:当访问此action时，要调用相应class类的相应的方法。默认调用`execute()`方法
        - 动态方法调用：添加配置`<constant name="struts.enable.DynamicMethodInvocation" value="true" />`，使用myAction!myMethod方式调用
        - 注：除了用method属性指定相应的action调用方法(缺点是产生太多action)；还可以在url地址中动态指定(动态方法调用DMI，使用!，视频13还没测试成功)；实际中多使用通配符
- `package`>`action`>`result`
    - name:此result名称
    - 原理：访问时，先获取实现了Action接口的类或者其子类的execute()方法的返回值，然后匹配name属性为此返回值的result，再显示此result标签中的页面
    - 注：属性为successs时可省略此name属性，因为Action接口execute()方法默认返回的是success字符串
    - 注：默认有`SUCCESS`/`ERROR`/`INPUT`/`LOGIN`等常量，有时候使用SUCCESS可以解决，但仍用INPUT是为了作区分

2. **struts2中的路径问题**（jsp文件中的href路径）
    - struts2是根据action的路径而不是jsp路径来确定，所有尽量不要使用相对路径，虽然可以用redirect方式解决，但redirect方式并非必要
    - 解决办法
        - 统一使用绝对路径(JSP页面的绝对路径中第一个"/"指的是服务器的根路径，而不是项目的根路径)
        - 在jsp中用request.getContextPath()方式来拿到webapp的路径,或者使用myeclipse常用的指定basePath
        - 参考源码：`WebRoot/others/testPath.jsp`

3. 通配符，可以将配置量降到最低

    ```xml
    <!-- 如果namespace="/" -->
    <action name="*_*" class="cn.aezo.wildcard.{1}" method="{2}">
    	<result>/wildcard/{1}_{2}.jsp</result>
    </action>
    ```
    - 注释：{1}表示第一个*，{2}表示第二个*；如果访问http://localhost:8080/Student_add，则{1}为Student，{2}为add；匹配是以最佳匹配优先
    - 建议使用到`*_*`，如果*太多程序可读性降低

### 接收用户传入参数

- （1）用Action属性接收url中的参数
- （2）使用域模型DomainModel接收参数,一般使用的方法(可以同时使用vo/do/dto来对数据进行处理)
    - 使用Domain Model时，在url地址中传**user.username**=smalle的话，Struts2会自动根据User类中无参构造方法帮忙new一个对象
    - 所以此时如果我们有自己的构造方法，则系统不会帮我们自动生成无参构造方法，则一定要自己写上这个无参构造方法供Struts2调用
- （3）使用模型驱动ModelDriven接收参数，此方式不常用，但涉及了MVC的概念
Struts2中的MVC概念：M是各种类似User的类，V是各种jsp页面，C是各种Action；通过Action控制请求的处理和请求的展现；因此将请求的发生、处理、展现进行了分离

### strtus常量（乱码问题）

- （1）struts2默认的常量都在struts2-core-2.3.24.1.jar->org.apache.struts2->default.properties中
- （2）struts2默认编码是UTF-8，设置方法<constant name="struts.i18n.encoding" value="UTF-8" />
- （3）internationalization(i18n，指的是i和n之间有18个字母)
- （4）还可以在web.xml中定义一个编码拦截器，在struts2拦截之前做一次编码处理

### 数据校验和strtus2标签初步

- （1）在Action中使用`this.addFieldError("errname", "errmsg");`设定字段错误信息，在JSP页面使用struts2标签`<s:fielderror fieldName="errname"/>`获取errmsg
- （2）`<%@ taglib uri="/struts-tags" prefix="s" %>`在jsp页面导入struts2标签；
    - 其中uri是文件(struts2-core-2.3.24.1.jar->META-INF->struts-tags.tld)中"<uri>/struts-tags</uri>"的值，prefix指标签前缀为s
- （3）`<s:debug></s:debug>`<!-- 使用debug模式可查看很多可以获取的值 -->
- （4）`<s:property value="..."/>`<!-- 获取debug模式中的Value Stack(直接在value填写Property Name)和Stack Context(又称ActionContext，在value中填写"#key")中的值 -->

### action中访问web元素(request、session、application)**
- （1）context就是上下文，也可以认为是运行环境，如servletContext就只servlet运行的环境
- （2）使用DI/IoC解决，即实现接口`RequestAware`、`SessionAware`、`ApplicationAware`（**视频21-22**）
    - `DI`: dependency injection依赖注入
    - `IoC`: inverse of control控制反转

### 包含模块配置文件

- `<include file="/cn/aezo/others/xxx.xml" />` xxx.xml相当于一个普通的struts.xml文件

### 默认action

```xml
<default-action-ref name="def"></default-action-ref><!-- 要写在此package的所有action之前 -->
<action name="def">
    <result>/default.jsp</result>
</action>
```

### result相关

- `package>action>result>type`(Result类型)
    - `dispatcher`	服务器端跳转，只能跳转到页面(jsp/html)，不能是action
    - `redirect`	客户端跳转，只能跳转到页面(jsp/html)，不能是action
    - `chain`		服务器端跳转，指forward到action,result中的action不要加/
    - `redirectAction`	客户端跳转，可跳转到action,result中的action不要加/
    - freemarker
    - httpheader
    - stream
    - xslt
    - plaintext
    - tiles
- 一次request只有一个值栈valueStack；以forward的形式跳转(dispatcher/chain)时，request没变，因此valueStack不变。而客户端跳转则值栈改变
- 全局结果集global-results

    ```xml
    <global-results><!-- 相当于该包和该包的子包所有的action中都包含这条result -->
    	<result name="mainPage">/global/mainPage.jsp</result>
    </global-results>
    ```
- 动态结果集
    - 在action中使用属性定义结果集并动态赋值，在struts.xml中使用ognl表达式，如${属性}来获取valueStack中的这个属性(也是在action中定义的属性)
- 带参数的结果集(request值栈：**视频32**)
    - 一次request只有一个值栈valueStack；以forward的形式跳转(dispatcher/chain)时，request没变，因此valueStack不变。而客户端跳转则值栈改变
    - valueStack是request对象中的相关信息，如果是客户端跳转到jsp页面，则url上的带的参数在request域对象中是取不到到，只能在上下文中通过parameters获取

### OGNL 表达式

> OGNL表达式是通常要结合Struts2的标志一起使用，如<s:property value="#xx" />，el表达式可以单独使用${sessionScope.username}。详细区别如：http://www.cnblogs.com/ycxyyzw/p/3493513.html

- ognl表达式：如果标签对应的value的属性类型是Object时，且value中的值可以从值栈中获取就视为ognl表达式
    - 如<s:property value="name" />中s:property是struts2标签，而value中的字符串才是ognl表达式
- ognl访问值栈中action的普通属性 `<s:property value="user.age" />`
- ognl访问值栈中对象的普通属性 `<s:property value="user.age" />`
- ognl访问静态成员
    - （1）格式为："@类名@属性/方法"，而"@@方法"只适用于调用Math类中的方法
    - （2）访问静态方法需要设置常量struts.ognl.allowStaticMethodAccess=true
- ognl访问集合
    - （1）访问集合<s:property value="users" />
    - （2）访问集合中某个元素：List<s:property value="users[1]" />，Map<s:property value="userMaps.userm1" />(Set访问不到)
    - （3）访问List、Set中元素的所有属性的集合<s:property value="users.{age}" />
    - （4）访问Map的所有Key和Value<s:property value="userMaps.keys" /><s:property value="userMaps.values" />
    - （5）访问容器大小<s:property value="users.size()" />或者value="users.size"
- ognl投影(过滤)
    - （1）获取user集合中age>1的子集合中的第一个元素<s:property value="users.{?#this.age==1}[1]" />
    - （2）^表示获取开头的元素，$表示获取结尾的元素，如：<s:property value="users.{^#this.age>1}.{age}" />、<s:property value="users.{$#this.age>1}.{age}" />
- ognl中的`[0]`
    - 使用[0]访问所有action和DefaultTextProvider组成集合的对象(只有服务器端跳转是才会有多个action),如：<s:property value="[0]" />

### 标签

jsp中引入 `<%@ taglib uri="/struts-tags" prefix="s" %>`。其中uri是文件(struts2-core-2.3.24.1.jar->META-INF->struts-tags.tld)中"<uri>/struts-tags</uri>"的值，prefix指标签前缀为s

- `<s:debug></debug>` 查看值栈，但是debug这行代码的位置可能会影响查看到的结果。如定义set、bean等的属性var，则会把这个var的值当做是键，和真正的值放到Stack Context中
- `<s:property value=""/>` 获取Value Stack中的值，其中的value前不需加#，获取Stack Context中的值，前面可加#也可不加#；但是当和Value Stack有重名时，不加#表示访问Value Stack，加#表示访问Stack Context；且获取Stack Context中的request必须加#。
- `<s:set var="adminName" value="username"/>` 设置变量，默认是设在request和actionContext/StackContext中
- 定义bean

    ```xml
    <s:bean name="cn.aezo.tags.model.Dog" var="myDog">
        <s:param name="name" value="'myDogName'"></s:param>
    </s:bean>
    ```
- `<s:include value="include.html"/>` 导入外部文件(尽量不要使用，可使用jsp的include)
- if elseif else

    ```xml
    <s:set var="age" value="#parameters.age[0]"></s:set><!-- 此处要带上[0],即取第一个 -->

    <s:if test="#age < 0">wrong age!</s:if>
    <s:elseif test="#age < 20">too yong!</s:elseif>
    <s:else>yeah!</s:else>
    ```
- iterator遍历

    ```xml
    <s:iterator value="{1, 2, 3}" var="item" status="status"><!--status保存这循环的相关信息，如status.index表示下标-->
        <s:property value="#status.index"/>: <s:property value="#item"/>,
    </s:iterator>
    ```
- `%{}`，其中%可以将{}中的内容强制转换为ognl表达式
- <constant name="struts.ui.theme" value="simple"/>使用UI标签的主题（使用较少），默认是xhtml,还可以为simple等,也可自己定义,可通过查看源码得知他定义的一些html元素。自己定义的主题要在src目录下，最终才会被编译到classes下，且起名为"template.你的主题名",其中的template是默认参数

### struts2拦截器interceptor

- （1）自定义的拦截器实现xwork2的`Interceptor`接口
- （2）在struts.xml中进行配置

    ```xml
    <interceptors>
    	<interceptor name="myInterceptor" class="cn.aezo.others.MyInterceptor"></interceptor>
    </interceptors>
    ```
- （3）在action中进行添加拦截器

    ```xml
    <action name="interceptor" class="cn.aezo.others.MyInterceptorAction">
        <result>/others/interceptor.jsp</result>

        <interceptor-ref name="myInterceptor"/>
        <interceptor-ref name="defaultStack"/><!-- 要加上默认的拦截器 -->
    </action>
    ```
- （4）token拦截器：可以产生一个随机字符串，可防止重复提交
    - jsp页面使用`<s:token></s:token>`生成随机数
    - action的配置中加入struts2提供的拦截器`<interceptor-ref name="token"/>`
- （5）类型转换：实际上市struts2内置拦截器起的作用。只要在URL传参设参数值为约定的格式即可

### 异常处理

- strut2的声明式异常是使用拦截器来实现的
- 声明式异常：在所有的action中都throws Exception，拦截到struts.xml文件中，寻找全局异常映射和结果集进行页面显示

### i18n国际化

- （1）原理：使用java.util包中的ResourceBundle和Locale类，如ResourceBundle rb = ResourceBundle.getBundle("app", Locale.CHINA);
- （2）struts2资源文件(properties)级别
    - Action级别的国际化，properties文件前缀要是此Action的类名
    - 包级别的，properties文件前缀要是package
    - 全局级别的，前缀随便取。比较常用
- （3）全局级别时，要设置properties的前缀，即常量<constant name="struts.custom.i18n.resources" value="testStruts2"></constant>
- （4）在JSP页面可通过标签取值。<s:property value="getText('welcome.string')"/><!-- 调用的Action的方法，实际中是ActionSupport的方法 -->
- （5）处理资源文件中带参数的问题：properties文件中写成如：param.string=欢迎：{0} ，然后在页面用	<s:text name="param.string"><s:param value="username"></s:param></s:text>获取url中的参数值(或者post表单)
- （6）点击链接国际化：在链接后加参数request_locale=en_US或者request_locale=zh_CN，这样之后
