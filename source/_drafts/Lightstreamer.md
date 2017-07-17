## Lightstreamer简介

- Lightstreamer可用于即时通讯(web聊天室、客服聊天)、实时新闻推送、实时股价行情等需要服务器一致给用户推送消息的场景。支持多平台(windows/unix/mac等)，支持多种语言(java、.NET、nodejs等)，支持多种设备(web端、移动端等)。提供免费版和商业版。
- 官网：[lightstreamer](http://www.lightstreamer.com/)

### Ajax推送与拉取方式

使用Ajax可以开发出基于浏览器的具有高用户交互性和几乎不易觉察到延迟的web应用。实时的动态数据比如新闻标题、证券报价和拍卖行情都需要尽快地发送给用户。然而，AJAX仍然受限于web请求/响应架构的弱点，使得服务器不能推送实时动态的web数据。

1. 可以实现基于web的实时事件通知的方法有：
  - `HTTP拉取方式`：在这种传统的方法中，客户端以用户可定义的时间间隔去检查服务器上的最新数据。
  - `HTTP流`：这种方法由存在于不间断的HTTP连接响应中或某个XMLHttpRequest连接中的服务器数据流所组成。
  - `反转AJAX`：服务流应用到AJAX，就是所谓的反转AJAX 或者[`COMET`](https://en.wikipedia.org/wiki/Comet_%28programming%29) 。它使得服务器在某事件发生时可以发送消息给客户端，而不需要客户端显式的请求。目标在于达到状态变化的实时更新。COMET使用了HTTP/1.1中的持续连接的特性。通过HTTP/1.1，除非另作说明，服务器和浏览器之间的TCP连接会一直保持连接状态，直到其中一方发送了一条明显的“关闭连接”的消息，或者有超时以及网络错误发生。
  - `长时间轮询`：也就是所谓的异步轮询，这种方式是纯服务器端推送方式和客户端拉取方式的混合。它是基于BAYEUX协议的。 这个协议遵循基于主题的发布——订阅机制。在订阅了某个频道后，客户端和服务器间的连接会保持打开状态，并保持一段事先定义好的时间。如果服务器端没有事 件发生，而发生了超时，服务器端就会请求客户端进行异步重新连接。如果有事件发生，服务器端会发送数据到客户端，然后客户端重新连接。
2. 一些其他Comet Ajax服务器推送模型的实现：
  - Orbited ：一种开源的分布式Comet服务器
  - AjaxMessaging ：Ruby on Rails的Comet插件
  - Pushlets ：一个开源框架，可以让服务器端java对象推送事件到浏览器端javascript，java applet，或者flash应用程序
  - Lightstreamer ：提供基于AJAX-COMET模式的HTTP流的商业实现
  - Pjax ：Ajax的推送技术

## Lightstreamer之HelloWorld

### 官方实例

参考官方文章：[http://www.lightstreamer.com/docs/baseparent/GETTING_STARTED.TXT](http://www.lightstreamer.com/docs/baseparent/GETTING_STARTED.TXT)

- 下载Lightstreamer并解压：[Lightstreamer Allegro/Presto/Vivace Editions或者Lightstreamer Moderato Edition的ZIP](http://www.lightstreamer.com/download/)
- 设置TCP端口
  - 默认使用的TCP端口有：8080 和 8888
  - 可修改 `conf/lightstreamer_conf.xml`的<port> (在<http_server>代码块处) 和 <port> (在<rmi_connector> 代码块处)
- 配置JAVA_HOME
  - Windows系统中：编辑`bin/windows/LS.bat`（第10行附近）
  - 在Linux, Mac, or Unix系统中，编辑`bin/unix-like/LS.sh`
- 运行服务
  - Windows系统中，运行`Start_LS_as_Application.bat`（本质是运行了LS.bat）
  - 在Linux, Mac, or Unix系统中，运行`start.sh`
- 访问应用
  - 访问：`http://localhost:8080`（可以看到股票浮动，也可尝试开多个网页聊天和踢球）
  - 仪表盘监控：`http://localhost:8080/dashboard`

### HelloWorld

[**GIT源码**](https://github.com/oldinaction/Git/tree/master/src/demo/Lightstreamer)

前台使用Web Client (Web端)，后台使用Java Data Adapter (java数据适配器)
- 下载官方源码：[Web Client](https://github.com/Lightstreamer/Lightstreamer-example-HelloWorld-client-javascript)、[Java Data Adapter](https://github.com/Lightstreamer/Lightstreamer-example-HelloWorld-adapter-java)
- Web Client
  - 在Lightstreamer的pages目录下新建HelloWorld文件夹（html页面来自Web Client的源码，注意引入`require.js`和`lightstreamer.js`）
-  Java Data Adapter
  - 在Lightstreamer的adapters目录下新建HelloWorld文件夹，在此目录新建src、lib、classes三个文件夹，和一个adapters.xml文件
  - 将Java Data Adapter中的源码HelloWorldDataAdapter.java放在src目录下；将Lightstreamer/DOCS-SDKs/sdk_adapter_java_inprocess/lib中的ls-adapter-interface.jar复制到lib目录。
  - 编译
    - 命令行进到adapters/HelloWorld目录
    - 运行`javac -classpath lib/ls-adapter-interface.jar -d classes -sourcepath src src/HelloWorldDataAdapter.java`
    - 运行`jar cvf HelloWorldDataAdapter.jar -C tmp_classes .`
    - 将生成的HelloWorldDataAdapter.jar复制到adapters/HelloWorld/lib目录
  - 在adapters.xml写入
    ```xml
    <?xml version="1.0"?>
    <adapters_conf id="HELLOWORLD">
       <metadata_provider>
          <adapter_class>com.lightstreamer.adapters.metadata.LiteralBasedProvider</adapter_class>
       </metadata_provider>
       <data_provider>
          <adapter_class>HelloWorldDataAdapter</adapter_class>
       </data_provider>
    </adapters_conf>
    ```

- 运行`Start_LS_as_Application.bat`
  - 也可在eclipse中启动项目，参考：[官方论坛文章](http://forums.lightstreamer.com/showthread.php?4875-Developing-amp-Running-an-Adapter-Set-Using-Eclipse-Java)（文章中的${LS_HOME}指的是Lightstreamer安装目录）
- 访问：`http://localhost:8080/HelloWorld`即可看到Hello、World交替显示

### 一台机器运行多个Lightstreamer

修改两个默认使用的TCP端口：8080 和 8888



> 参考文章
>
> - http://www.lightstreamer.com/doc
> - http://www.infoq.com/cn/news/2007/07/pushvspull
