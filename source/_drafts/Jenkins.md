---
layout: "post"
title: "Jenkins"
date: "2018-10-09 16:35"
categories: devops
tags: hook
---

## TODO

- 添加应用服务器
    - linux：密码/秘钥连接
    - windows：安装ssh server连接
- git服务器交互
    - 连接git服务器：密码/秘钥
    - 拉取项目到Jenkins工作目录
    - git提交后，通过git hook调用Jenkins服务
        - 根据某特定分支进行构建 **TODO**
        - 可检查git commit中的内容来判断是否需要构建发布 **TODO**
- 与应用服务器交互
    - 执行不同服务器命令：bat、sh
        - 执行成功发送邮件 **TODO**
        - 执行失败停止构建并发送邮件 **TODO**
- 工作流
    - 基于Jenkins项目运行工作流
    - 构建时按照一定顺序执行脚本
        - 依次调用不同服务器脚本
- 代码检查
    - 代码重复率等检查(sonal)
    - maven build
- 构建版本记录，类似git日志、


## 安装编译及运行

### 直接安装运行

### 手动编译运行

> 基于stable-2.164分支。具体参考：https://wiki.jenkins.io/display/JENKINS/Building+Jenkins

- 安装依赖环境：jdk1.8、maven3.5.4+
    - maven版本过低时，maven-enforcer-plugin校验报错
- 下载源码 `git clone https://github.com/jenkinsci/jenkins.git` (可检出stable-2.164分支)
- maven编译并打包
    - 通过命令行编译 **`mvn -Plight-test package -DskipTests`**
    - 或者在IDEA上操作：勾选Maven Projects - Profiles - light-test，执行Jenkins main module - Lifecyle - package
    - 编译时会生成`cli/target/generated-sources/Messages.java`
    
        > If your IDE complains that 'Messages' class is not found, they are missing because they are supposed to be generated. Run a Maven build once and you should see them all. If that doesn't fix the problem, make sure your IDE added target/generated-sources to the compile source roots.
    - 打包时会生成war/node(war/node/yarn)、war/node_modules，并打包静态资源文件
- Run/Debug中添加tomcat配置，Deployment选择jenkins-war:war
- debug启动tomcat。也可在远程启动debug监听 `mvnDebug jenkins-dev:run` 默认监听端口8000，可通过remote debug进行远程调试

## 插件

### Publish over SSH

- [src](https://github.com/jenkinsci/publish-over-ssh-plugin)、[wiki](https://wiki.jenkins.io/display/JENKINS/Publish+Over+SSH+Plugin)
- 利用此插件可以连接远程Linux服务器，进行文件的上传或是命令的提交，也可以连接提供SSH服务的windows服务器
- BapSshHostConfiguration#createClient 进行服务器连接
- 此插件1.20.1界面`Test Configuration`测试代理连接存在bug，实际是支持代理连接的

### GitLab

- [wiki](https://github.com/jenkinsci/gitlab-plugin)
- 构建触发器 - Build when a change is pushed to GitLab.

## jenkins源码解析

- jenkins数据全部存储在内存或者文件中，启动jenkins前提前设置环境变量`JENKINS_HOME`则会在此目录生成数据文件.
    - JENKINS_HOME/plugins 为插件目录，安装的插件也都存放于此，如果需要debugger插件则将对应插件目录中的jar添加到war模块的依赖中去

### kohsuke

> kohsuke为jenkins使用的 servlet 框架，亦是jenkins创始人kohsuke名字

- 测试如访问 http://localhost:8080/api/ 、 http://localhost:8080/api/json/ 、http://localhost:8080/newJob/
- jenkins中war模块为最终打包的入口模块，此模块会引用core、cli模块。此模块`web.xml`配置如下

```xml
<servlet>
    <servlet-name>Stapler</servlet-name>
    <servlet-class>org.kohsuke.stapler.Stapler</servlet-class>
    <init-param>
        <param-name>default-encodings</param-name>
        <param-value>text/html=UTF-8</param-value>
    </init-param>
    <init-param>
        <param-name>diagnosticThreadName</param-name>
        <param-value>false</param-value>
    </init-param>
    <async-supported>true</async-supported>
</servlet>

<servlet-mapping>
    <servlet-name>Stapler</servlet-name>
    <url-pattern>/*</url-pattern>
</servlet-mapping>
```
- Hudson(core)和Jenkins(core)
    - hudson.model.Hudson extends hudson.model.Jenkins
    - hudson.model.Jenkins implements org.kohsuke.stapler.StaplerProxy, org.kohsuke.stapler.StaplerFallback
- `Stapler`内中主要的处理方法在`tryInvoke`中

```java
boolean tryInvoke(RequestImpl req, ResponseImpl rsp, Object node) throws IOException, ServletException {
    // 刚进入servlet时，此处node初始化为Hudson对象

    // 判断是否为Stapler代理对象
    if (node instanceof StaplerProxy) {}

    if (node instanceof StaplerOverridable) {}

    // 获取 org.kohsuke.stapler.MetaClass 信息
    // WebApp中会缓存一个Map存放MetaClass，无对应缓存则通过 mc = new MetaClass(this, c); 进行初始化
    // MetaClass 初始化时主要执行了 MetaClass#buildDispatchers() 进行初始化(本质是获取node对象信息组装dispatchers集合，方便后面进行url-method路由)
    // 组织dispatchers顺序(不同的类型使用Dispatcher子类进行添加)
    //      DirectoryishDispatcher
    //      HttpDeletableDispatcher
    //      this.registerDoToken(node) // 注册do开头的函数
    //      node.methods.name("doIndex").iterator()
    //      node.methods.prefix("js").iterator()
    //      node.methods.annotated(JavaScriptMethod.class).iterator()
    //      this.webApp.facets.iterator() // facets里面为模板渲染路由，如 jelly、groovy
    //      node.fields.iterator()
    //      node.methods.prefix("get") // 注册get开头的函数
    //      node.methods.name("doDynamic").iterator()
    //      this.klass.isArray() // klass为node对应的包装对象
    //      this.klass.isMap()
    MetaClass metaClass = this.webApp.getMetaClass(node);

    // 基于MetaClass进行url匹配。大部分在此处进行匹配
    Iterator var16 = metaClass.dispatchers.iterator();
    while(var16.hasNext()) {
        Dispatcher d = (Dispatcher)var16.next();
        // 参考下午 NameBasedDispatcher 源码解析
        if (d.dispatch(req, rsp, node)) {
            // 可在此处打断点，追踪执行的堆栈信息。由于后台会自动刷新，可设置断点条件：`!"/jen/ajaxBuildQueue".equals(req.getOriginalRequestURI()) && !"/jen/ajaxExecutors".equals(req.getOriginalRequestURI())`
            if (LOGGER.isLoggable(Level.FINER)) {
                LOGGER.finer("Handled by " + d);
            }

            // 返回，response已经完成数据输出
            return true;
        }
    }

    // 最后，当基于方法提取的url未匹配到，则进入到此判断，一些ajax页面是这样生成的 (如访问 http://localhost:8080/newJob/)
    if (node instanceof StaplerFallback) {
        // 获取此node的StaplerFallback对象，如 hudson.model.AllView，此类会生成一个头尾dom，中间的dom可通过ajax添加进去
        Object n = ((StaplerFallback)node).getStaplerFallback();
        
        if (n != node && n != null) {
            this.invoke(req, rsp, n); // 最终仍然进入 tryInvoke 进行匹配
            return true;
        }
        // 果然仍然未匹配到则404
    }
}
```
- `org.kohsuke.stapler.NameBasedDispatcher extends Dispatcher`。如`node.methods.prefix("get")`提出的都是通过`NameBasedDispatcher`进行包装的

```java
public final boolean dispatch(RequestImpl req, ResponseImpl rsp, Object node) throws IOException, ServletException, IllegalAccessException, InvocationTargetException {
    // req.tokens为基于url进行切片。如/api会生成一个["api"]，/api/json会生成一个["api", "json"]
    // req.tokens.peek()提取一个，如访问：http://localhost:8080/api/json/. Stapler首先会进行/api路由，执行Jenkins#getApi；处理完成后通过 req.getStapler().invoke(req, rsp, ff.invoke(req, rsp, node, new Object[0])); 进入到/json路由，此时执行hudson.model.Api#doJson
    if (req.tokens.hasMore() && req.tokens.peek().equals(this.name)) {
        if (req.tokens.countRemainingTokens() <= this.argCount) {
            return false;
        } else {
            req.tokens.next();
            // 执行路由。内部执行 req.getStapler().invoke(req, rsp, ff.invoke(req, rsp, node, new Object[0])); 跳转到下一个路由
            boolean b = this.doDispatch(req, rsp, node);
            if (!b) {
                req.tokens.prev();
            }

            return b;
        }
    } else {
        return false;
    }
}
```





