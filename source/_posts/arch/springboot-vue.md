---
layout: "post"
title: "基于Springboot和Vue前后分离"
date: "2017-12-25 21:16"
categories: [arch]
tags: [springboot, vue]
---

## 默认配置

- 后端返回数据字段驼峰(如果通过ObjectMapper字段名转成下划线，前台做好下划线命名的字段映射后传回给后台，此时后台pojo都是驼峰，导致无法转换)
- 前后台url都以`/`开头方便全局搜索
- url地址和linux文件路径`/`和`//`效果是一样的；windows路径则必须是`/`或者`\`

## Spring

- 表单操作的dto应该基于业务模式进行解耦，不要耦合到一个dto中
    - 出错场景：使用dto(数据传输对象)接受前端数据后，并`BeanUtils.copyProperties`将dto复制到po(持久化对象)中，且前端有清除数据库部分字段的需求(此时dto中该字段传入的值为null，并使用mybatis生成的`updateByPrimaryKey`进行更新)。但是内部字段(一般不会让用户直接修改的)初始化后不应该置空。后来在修改某些需求时(如基于客户直接创建拜访)，不小心简单将内部字段(创建拜访时会从客户中查询到CRM_ID并创建拜访记录)加入到dto中加入了部分其他字段导致，此时普通修改时前端并没有传入CRM_ID，导致将内部字段置空

## Mybatis

- 使用`mybatis plus`进行通用代码生成
- `Mybatis Generator`生成通用代码
    - 可通过自定义Mapper继承生成的Mapper。(如UserMapperExt extend UserMapper, 可防止因修改生成代码导致无法再次生成)
    - 生成接口中`selective`含义：表示根据字段值判断，如果为空则不插入或更新
        - `insert`(不会考虑数据库默认值)、`insertSelective`(考虑数据库默认值)
        - `updateByPrimaryKey`(根据对象查询出来后全部按照传入对象更新，如果传入对象的值为空则会将数据库该字段置空)、`updateByPrimaryKeySelective`(如果出入对象值为空则不修改数据库该字段值)
- 接口中使用`@Select`定义实现中，使用`<if>`代替`<when>`

## 跨域和session/token

### 同源政策

- 网络协议、ip、端口三者都相同就是同一个域(同源)
    - 如`http://localhsot`和`http://localhsot:8080`之间进行数据交互就存在跨域问题（localhost 和 127.0.0.1 不一样）
- 浏览器"同源政策"限制(针对不同源情况) [^2] [^8]
    - `Cookie、LocalStorage 和 IndexDB 无法读取`
    - `DOM 无法获得`
    - `AJAX 请求不能发送`

### 跨域通信 

- `JSONP`(只能发送GET请求)
- `CORS`(服务器端进行设置即可)
- `WebSocket`
- `postMessage`
    - 可以实现页面和里面iframe页面之间的通讯
    - 可以实现窗口和通过window.open的窗口间的通讯
    - 可以实现窗口和通过a标签(`<a href="B页面" target="_blank">新打开B页面</a>`)新打开的窗口间的通讯
    - 示例：将b页面嵌入在a页面中

    ```html
    <!-- ======a给b发送消息send-from-a，然后b给a回复消息send-from-b======= -->
    <!-- a.html 其中onload表示iframe加载(iframe项目代码已经加载到浏览器)后执行，如果将iframe隐藏也不会影响其加载 -->
    <iframe src="http://localhost:4000/b.html" frameborder="0" id="iframe" onload="load()"></iframe>
    <script>
        /*
        someWindow.postMessage(message, targetOrigin, [transfer]);
            message: 将要发送到其他 window 的数据
            targetOrigin: 通过窗口的 origin 属性来指定哪些窗口能接收到消息事件，其值可以是字符串"*"(表示无限制)或者一个 URI。在发送消息的时候，如果目标窗口的协议、主机地址或端口这三者的任意一项不匹配 targetOrigin 提供的值，那么消息就不会被发送；只有三者完全匹配，消息才会被发送
            transfer(可选): 是一串和 message 同时传递的 Transferable 对象. 这些对象的所有权将被转移给消息的接收方，而发送一方将不再保有所有权
        */
        function load() {
            // 给子页面(嵌入的iframe)发送消息。此时targetOrigin为'http://localhost:4000'或者'*'均可，http://localhost:4000/ 也可以
            document.getElementById('iframe').contentWindow.postMessage({from: 'send-from-a', request: 'get-name'}, 'http://localhost:4000')

            // 接受数据
            window.onmessage = function(e) {
                console.log(e.data) // send-from-b
            }
        }
    </script>

    <!-- b.html -->
    <script>
        window.onmessage = function(e) {
            console.log(e.data) // send-from-a
            e.source.postMessage({from: 'send-from-b', response: 'get-name', name: 'smalle'}, e.origin) // 使用e.origin表示回复源窗口消息
        }
        // 或者监听事件
        /*
        e.data: 指的是从其他窗口发送过来的消息对象
        e.type: 指的是发送消息的类型
        e.source: 指的是发送消息的窗口对象
        e.origin 指的是发送消息的窗口的源
        */
        window.addEventListener("message",  function(e) {
            console.log(e)
        }, false)

        // 主动给父页面发送消息
        window.parent.postMessage('hello...', '*')
    </script>
    ```

- 架设服务器代理(浏览器请求同源服务器，再由后者请求外部服务)。如基于`nginx`做中转

```bash
server {
    listen   80;               
    server_name localhost;

    # 后端服务根端点
    location /api/ {
        proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        if (!-f $request_filename) {
            proxy_pass http://127.0.0.1:8080;
            break;
        }
    }

    # 前端
    location / {
        root   D:/demo/vue/dist;
        index  index.html index.htm;
    }
}
```

### 跨域资源共享(CORS, Cross-origin resource sharing) [^1]

- **`CORS`需要浏览器和服务器同时支持。**目前，所有浏览器都支持该功能，IE浏览器不能低于IE10。**浏览器会自动完成CORS通信过程，开发只需配置服务器同源限制**
- 如果CORS通信过程中，响应的头信息没有包含`Access-Control-Allow-Origin`字段，浏览器则认为无法请求，便会抛出异常被XHR的onerror捕获
- `Spring`对CORS的支持[https://spring.io/blog/2015/06/08/cors-support-in-spring-framework](https://spring.io/blog/2015/06/08/cors-support-in-spring-framework)
    - 可在方法级别进行控制，使用注解`@CrossOrigin`
    - 全局CORS配置，声明一个`WebMvcConfigurer`的bean
    - 基于`Filter`，声明一个`CorsFilter`的bean

#### springboot可基于Filter实现

```java
// 如果加了此配置仍然提示跨域，可检查是否有其他Filter已经返回了此请求
@Bean
public Filter corsFilter() {
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    CorsConfiguration config = new CorsConfiguration();
    config.addAllowedOrigin("*");
    config.addAllowedMethod("*");
    config.addAllowedHeader("*");
    source.registerCorsConfiguration("/**", config);
    return new CorsFilter(source);
}
```

#### spring security的cors配置 [^3]

- 开启cosr

    ```java
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable(); // 开启cors需要关闭csrf
        http.cors();
        // ...
    }

    // 配置cors
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // configuration.setAllowedOrigins(Arrays.asList("*"));
        configuration.setAllowedOrigins(Arrays.asList("http://192.168.1.1:8088", "http://www.aezo.cn:80", "https://www.aezo.cn:80"));
        configuration.setAllowedMethods(Arrays.asList("*"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
    ```
    - `CSRF` 跨站请求伪造(Cross-Site Request Forgery). [csrf](https://docs.spring.io/spring-security/site/docs/4.2.x/reference/html/csrf.html)

### iframe页面获取父页面地址

- 如果iframe与父页面遵循同源策略(属于同一个域名)，可通过`parent.location`或`top.location`获取父页面url；如果不遵循同源策略，则无法获取
- 不同源可使用`document.referrer`获取

```js
function getParentUrl() {
    var url = null; if (parent !== window) {
        try {
            url = parent.location.href;
        } catch (e) {
            url = document.referrer;
        }
    }
    return url;
}
```

## Http请求及响应

- spring-security登录只能接受`x-www-form-urlencoded`(简单键值对)类型的数据，`form-data`(表单类型，可以含有文件)类型的请求获取不到参数值

### axios实现ajax

- axios基本使用

```js
axios.get("/hello?id=1").then(response => {
    console.log(response.data)
});

// 如果将params换成this.$qs.stringify，后台也无法获取到数据
axios.get("/hello", {
    params: {
        userId: 1,
    }
}).then(response => {
    console.log(response.data)
});
```

### qs插件使用

```js
// 安装：npm install qs -S -D
import qs from 'qs'
Vue.prototype.$qs = qs;

this.$axios.post(this.$domain + "/base/type_code_list", this.$qs.stringify({
    name: 'smalle'
})).then(response => {

});

// (1) qs格式化日期
// qs格式化时间时，默认格式化成如`1970-01-01T00:00:00.007Z`，可使用serializeDate进行自定义格式化
// 或者后台通过java转换：new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").setTimeZone(TimeZone.getTimeZone("UTC"));
this.$qs.stringify(this.formModel, {
    serializeDate: function(d) {
        // 转换成时间戳
        return d.getTime();
    }
});

// (2) qs序列化对象属性
// 下列对象userInfo默认渲染成 `name=smalle&bobby[0][name]=game&hobby[0][level]=1`(未进行url转码)，此时springboot写好对应的POJO是无法进行转换的，报错`is neither an array nor a List nor a Map`
// 可以使用`allowDots`解决，最终返回 `name=smalle&bobby[0].name=game&hobby[0].level=1`
var userInfo = {
    name: 'smalle',
    hobby: [{
        name: 'game',
        level: 1
    }]
};
console.log(this.$qs.stringify(this.mainInfo, {allowDots: true}))
```

### axios参数后端接受不到 [^4]

- get请求传递数组

    ```js
    let vm = this
    this.$axios.get("/hello", {
        params: {
            typeCodes: ["CustomerSource", "VisitLevelCode"]
        },
        paramsSerializer: function(params) {
            return vm.$qs.stringify(params, {arrayFormat: 'repeat'}) // 此时this并不是vue对象
        }
    }).then(response => {
        console.log(response.data)
    });
    ```
- post请求无法接收
    - 使用`qs`插件(推荐，会自动设置请求头为`application/x-www-form-urlencoded`)
    - `axios`使用`x-www-form-urlencoded`请求，参数应该写到`param`中

        ```js
        axios({
            method: 'post', // 同jquery中的type
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            url: 'http://localhost:8080/api/login',
            params: {
                username: 'smalle',
                password: 'smalle'
            }
        }).then((res)=>{
            
        })
        ```

        - axios的params和data两者关系
            - params是添加到url的请求字符串中的，一般用于GET请求
            - data是添加到请求体body中的， 用于POST请求。Spring中可在通过`getUser(@RequestBody User user)`获取body中的数据，从request对象中只能以流的形式获取
            - 如果POST请求参数写在`data`中，加`headers: {'Content-Type': 'application/x-www-form-urlencoded'}`也无法直接获取，必须通过@RequestBody)
        - jquery在执行post请求时，会设置Content-Type为application/x-www-form-urlencoded，且会把data中的数据以url序列化的方式进行传递，所以服务器能够正确解析
        - 使用原生ajax(axios请求)时，如果不显示的设置Content-Type，那么默认是text/plain，这时服务器就不知道怎么解析数据了，所以才只能通过获取原始数据流的方式来进行解析请求数据
        - SpringSecurity登录必须使用POST

### 带参数文件上传

```html
<Upload
    :max-size="10*1024"
    :on-remove="handleRemove"
    multiple
    :before-upload="handleUpload"
    :action = this.action
>
<Button icon="ios-cloud-upload-outline">上传附件</Button>
</Upload>

<script>
handleUpload (file) {
    var falg = true
    var maxSize = 10 * (1024 * 1000)
    if (file.size > maxSize) {
        alert('当前文件超过10MB，不允许上传')
        return
    }
    for (var i = 0; i < this.fileList.length; i++ ) { // lastModified是文件的唯一值，如果当前文件集合存在文件就不存了
        if (this.fileList[i].lastModified == file.lastModified) {
            falg = false
        }
    }
    if (falg) {
        this.fileList[this.fileindex] = file
        this.file += file.name + '&nbsp;&nbsp;&nbsp;&nbsp;'
        this.fileindex++
    }
    return true;
},
handleRemove (file) {
    for (var i = 0;i<this.fileList.length;i++) {
        if(this.fileList[i].name == file.name) {
            this.fileList.splice(i, 1)
            this.fileindex--
        }
    }
},
submit () {
    var formData = new FormData()
    formData.append('title', "标题")
    formData.append('desc', "描述")
    for( var i = 0; i < that.fileList.length; i++ ) {
        formData.append('files', that.fileList[i])
    }
    this.$ajax.post('http://localhost:8080/upload', formData, {
        headers: {
            'Content-Type': 'multipart/form-data;boundary = ' + new Date().getTime()
        }
    }).then(response => {})
}

// java
@RequestMapping("/submit")
public Object addNotice(MultipartFile[] files, @Param("title") String title, @Param("desc") String desc) {}
</script>
```

## 性能优化

### 用户浏览器缓存问题 [^5]

- 浏览器缓存包括强制缓存、协商缓存
- 浏览器在请求某一资源时，会先获取该资源缓存的header信息，判断是否命中强缓存(`Cache-control`和`expires`信息)
    - 若命中直接从缓存中获取资源信息，包括缓存header信息。本次请求根本就不会与服务器进行通信(显示`200 OK (from disk/memory cache)`)
    - 若没有命中强缓存
        - 浏览器会发送请求到服务器，请求会携带第一次请求返回的有关缓存的header字段信息(`Last-Modified/If-Modified-Since`和`Etag/If-None-Match`)，由服务器根据请求中的相关header信息来比对结果是否协商缓存命中
            - 若命中，则服务器返回新的响应header信息更新缓存中的对应header信息，但是并不返回资源内容，它会告知浏览器可以直接从缓存获取(状态码`304`)
            - 否则返回最新的资源内容(状态码`200`)
- 强制缓存由`Expires`和`Cache-Control`控制
    - `Pragma和Expires`(HTTP 1.0) 控制缓存开关的字段有两个
        - Pragma的值为no-cache时，表示禁用缓存
        - Expires：response header里的过期时间，浏览器再次加载资源时，如果在这个过期时间内，则命中强缓存
    - `Cache-Control`(HTTP 1.1)
        - 当值设为max-age=300时，则代表在这个请求正确返回时间的5分钟内再次加载资源，就会命中强缓存
        - Cache-control其他常用的设置值(haeder中可包含多个Cache-control)
            - `no-cache`：**不使用本地缓存，但是需要使用协商缓存**
            - `no-store`：直接禁止浏览器缓存数据，每次用户请求该资源，都会向服务器发送一个请求，每次都会下载完整的资源
            - `public`：可以被所有的用户缓存，包括终端用户和CDN等中间代理服务器
            - `private`：只能被终端用户的浏览器缓存，不允许CDN等中继缓存服务器对其缓存
    - `Expires`和`max-age`
        - `Expires = 时间`，HTTP 1.0 版本，缓存的载止时间，允许客户端在这个时间之前不去检查(发请求)
        - `Cache-Control: max-age = 秒`，HTTP 1.1版本，资源在本地缓存多少秒，此时`Expires = max-age + "每次下载时的当前的request时间"`。主要解决Expires表示的是时间，但是服务器和客户端之前的时间可能相差很大
        - 如果max-age和Expires同时存在，则Expires被Cache-Control的max-age覆盖
- 协商缓存由`Etag/If-None-Match`、`Last-Modified/If-Modified-Since`控制，流程及相关字段说明如下 [^9]

    ![web-cache](/data/images/arch/web-cache.png)
    - `Last-Modified/If-Modified-Since`
        - 当浏览器第一次请求一个url时，服务器端的返回状态码为200，同时HTTP响应头会有一个Last-Modified标记着文件在服务器端最后被修改的时间
        - 浏览器第二次请求上次请求过的url时，浏览器会在HTTP请求头添加一个If-Modified-Since的标记，用来询问服务器该时间之后文件是否被修改过
    - `Etag/If-None-Match`
        - 当浏览器第一次请求一个url时，服务器端的返回状态码为200，同时HTTP响应头会有一个Etag，存放着服务器端生成的一个序列值
        - 浏览器第二次请求上次请求过的url时，浏览器会在HTTP请求头添加一个If-None-Match的标记
    - Etag 主要为了解决 Last-Modified 无法解决的一些问题
        - Etag的值通常为文件内容的哈希值；而Last-Modified为最后修改的时间
        - Last-Modified只能精确到秒，秒之内的内容更新Etag才能检测
        - Etag每次服务端生成都需要进行读写操作，而Last-Modified只需要读取操作，Etag的消耗是更大的
- 缓存特殊值说明
    - `response no-cahce`并不是表示无缓存，而是指使用缓存一定要先经过验证
    - `response header`的`no-cache`、`max-age=0`和`request header`的`max-age=0`的作用是一样的：都要求在使用缓存之前进行验证
    - `request header`的`no-cache`，则表示要重新获取请求，其作用类似于`no-store`
- 用户操作与缓存
    - 地址栏回车、页面链接跳转、新窗口打开、前进后退：Expires/Cache-Control、Last-Modified/Etag均可正常缓存
    - `F5`刷新：仅Expires/Cache-Control无法正常缓存
    - `Ctrl+F5`强制刷新：Expires/Cache-Control、Last-Modified/Etag均无法正常缓存
- nginx 配置，让vue项目的index.html不缓存
    - vue-cli里的默认配置，css和js的名字都加了哈希值，所以新版本css、js和就旧版本的名字是不同的，只要index.html不被缓存，则css、js不会有缓存问题

    ```bash
    # nginx 配置，让index.html不缓存。此处的路径不一定要是index.html，只要某路径A返回的是index.html文件，则此处匹配A路径即可
    location = /index.html {
        #- nginx的expires指令：`expires [time|epoch|max|off(默认)]`。可以控制 HTTP 应答中的Expires和Cache-Control的值
        #   - time控制Cache-Control：负数表示no-cache，正数或零表示max-age=time
        #   - epoch指定Expires的值为`1 January,1970,00:00:01 GMT`
        expires -1s; # 对于不支持http1.1的浏览器，还是需要expires来控制
        add_header Cache-Control "no-cache, no-store"; # 会加在 response headers
        # ...
    }
    ```
- 设置页面A不进行缓存，直接浏览器访问页面A不会缓存；但是把此页面A以iframe方式嵌入到其他页面B时，A会进行缓存，且Request Header提示`Provisional headers are shown`

    ```html
    <!-- 在A页面增加meta标签：可正常使用。但是如果之前无此标签，加上此标签后仍然无法让已经缓存的页面(无此meta标签)刷新。只会影响此html的缓存效果，不会影响页面js的 -->
    <head>
        <meta http-Equiv="Cache-Control" Content="no-cache" />
        <meta http-Equiv="Pragma" Content="no-cache" />
        <meta http-Equiv="Expires" Content="0" />
    </head>

    <!-- 解决方案：未测试成功 -->
    <script type="text/javascript">
        var _time = Math.floor(Math.random()*100000)
        document.write('<iframe src="http://localhost:8080/test.php?_time='+ _time +'"><iframe>')
    </script>
    ```
    - 出现`Provisional headers are shown`的常见情况
        - 跨域，请求被浏览器拦截
        - 请求被浏览器插件拦截
        - 服务器出错或者超时，没有真正的返回
        - 强缓存from disk cache或者from memory cache，此时也不会显示

### 压缩

- 如果前端放在nginx上则需要开启nginx的压缩；如果中间通过了多个nginx，必需开启离用户最近(对外服务器)的服务器的压缩(后面的nginx无所谓)；前后不分离时一般可通过tomcat进行页面压缩

```bash
server {
    ...

    # **启用后响应头中会包含`Content-Encoding: gzip`**
    gzip on; #开启gzip压缩输出
    # 压缩类型，默认就已经包含text/html(但是vue打包出来的js需要下列定义才会压缩)
    gzip_types text/plain application/x-javascript application/javascript text/javascript text/css application/xml text/xml;

    ...
}
```
- Vue首页加载慢问题，一般为`main.js`打包出来的体积太大，可以考虑减少main.js中的import包

## 其他

- 使用nginx导致部分地址直接浏览器访问报404(如基于`quasar`的项目)。可修改nginx配置如下

```bash
# 本地查找，如果没有就跳转到index.html(实际访问的还是源地址)
location / {
	try_files $uri $uri/ /index.html;
}
```

### 去掉#号

- 路由使用history模式。参考[hash和history路由模式](/_posts/web/vue.md#hash和history路由模式)

```js
new Router({
    mode: 'history', // H5新特性，需要浏览器支持：https://developer.mozilla.org/zh-CN/docs/Web/API/History
    routes: []
})
```
- 可配合nginx(后端)，开发vue时的静态服务器默认支持去掉`#`号

```bash
location / {
    try_files $uri $uri/ /index.html;
}
```

### 多项目配置

- **路由使用hash模式和history模式均可**，参考 [hash和history路由模式](/_posts/web/vue.md#hash和history路由模式)
- vue.config.js，参考[vue-cli v3](/_posts/web/vue.md#vue-cli%20v3) [^7]

```js
module.exports = {
    // 表示index.html中引入的静态文件地址。如生成 `/my-app/js/app.28dc7003.js`
    publicPath: '/my-app/', // 多环境配置时可自定义变量(VUE_APP_BASE_URL = /my-app/)到 .env.xxx 文件中，如：publicPath: process.env.VUE_APP_VUE_ROUTER_BASE
    // 打包后的文件生成在此项目的my-app根文件夹。一般是把此文件夹下的文件(index.html和一些静态文件)放到服务器 www 目录，此时多项目需要放到 /www/my-app 目录下
    outputDir: 'my-app', // 也可以是其他命名，但是最终要把index.html放在服务器的 /www/my-app 目录下
    // ...
}
```
- router/index.js (非必须)

```js
new Router({
    // 路由的基础路径，类似publicPath。只不过publicPath是针对静态文件，而此处是将<router-link>中的路径添加此基础路径
    base: '/my-app/', // 多环境配置时可自定义变量(VUE_APP_BASE_URL = /my-app/)到 .env.xxx 文件中，如：publicPath: process.env.VUE_APP_VUE_ROUTER_BASE
    // mode: 'history', // H5新特性，需要浏览器支持；***hash模式也支持多项目***
    routes: []
})
```
- nginx

```bash
# 此处的两个my-app需要和上文的base、publicPath保持一致
location ^~ /my-app/ {
    root /www; # 在/www目录放项目文件夹my-app(index.html在此文件夹根目录)
    try_files $uri $uri/ /my-app/index.html;
    # index  index.html index.htm; # hash模式
    # 禁止缓存index.html文件
    if ($request_filename ~* .*\.(?:htm|html)$) {
        add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
    }
}
```
- 浏览器访问`http://localhost/my-app/`

### https

- 浏览器使用的协议(http/https)必须和请求后台的协议一致，否则Chrome进行拦截掉了
- 静态资源使用`//aezo.cn/xxx`，它会判断当前的页面协议是http还是https来决定资源请求url的协议，可用于处理网站使用的协议和网页中请求的外网资源不一致的问题

```html
<script src="//aezo.cn/images/jquery/jquery-1.10.2.min.js" type="text/javascript"></script>
<!-- <script src="/images/jquery/jquery-1.10.2.min.js" type="text/javascript"></script> -->
<link rel="stylesheet" href="//aezo.cn/umetro/maincss.css" type="text/css"/>
<!-- <link rel="stylesheet" href="/umetro/maincss.css" type="text/css"/> -->

<style>
.my-img { 
    background: url(//aezo.cn/images/smalle.jpg);
    /* background: url(/images/smalle.jpg); */
}
</style>
```
- js中使用`//aezo.cn/api`进行动态请求后端地址，会动态获取document的协议
- 或者使用 `window.location.protocol + '//aezo.cn/api'` 得到完整地址，如微信网页授权需要将重定向地址当成参数传递，则应该传入完整地址

## 常用插件

- 参考[js-tools.md](/_posts/web/js-tools.md)

## 常见文件

```json
.babelrc
.env.dev
.env.test
.postcssrc.js
tsconfig.json       // 参考[typescript.md#tsconfig.json](/_posts/web/typescript.md#tsconfig.json)
vue.config.js       // 参考[vue.md#vue-cli](/_posts/web/vue.md#vue-cli)
.eslintrc.js        // 参考[node-dev-tools.md#eslint格式化](/_posts/web/node-dev-tools.md#eslint格式化)
.eslintignore       // 参考[node-dev-tools.md#eslint格式化](/_posts/web/node-dev-tools.md#eslint格式化)
```

## 浏览器

### 常见兼容性问题

- Chrome和Firefox查看请求结果时preview和response显示数据不一致问题 [^6]
    - 原因可能是因为数据为Long型，返回给浏览器以后，浏览器转换数据格式的时候出现问题。解决方案：在返回数据之前就将数据转换为字符串
- Chrome 84默认启用了SameSite=Lax属性 [^11] [^12]
    - SameSite 可取值：Strict（所有情况都不发送Cookies给第三方）、Lax（少部分情况发送）、None（发送，但是需要为HTTPS访问）
    - 如果A网页嵌入B网页时，用户打开A网页。如A与B属于同一域名，则B网站可在（前后端）对Cookies进行操作，也可传递Cookies给B；如果不是，则认为B网站为第三方页面，只对其开发部分情况（如a标签跳转、get类型的form提交）的Cookies传递


---

参考文章

[^1]: http://www.ruanyifeng.com/blog/2016/04/cors.html (跨域资源共享CORS详解)
[^2]: http://www.ruanyifeng.com/blog/2016/04/same-origin-policy.html (浏览器同源政策及其规避方法)
[^3]: https://docs.spring.io/spring-security/site/docs/4.2.x/reference/html/cors.html (spring-security-cors)
[^4]: https://segmentfault.com/a/1190000013312233 (springBoot与axios表单提交)
[^5]: https://blog.csdn.net/qq_32340877/article/details/80338271 (使用vue框架开发，版本更新，解决用户浏览器缓存问题)
[^6]: https://www.oschina.net/question/2405524_2154029?sort=time
[^7]: https://juejin.im/post/5cfe23b3e51d4556f76e8073
[^8]: https://mp.weixin.qq.com/s/LV7qziMyrMt0_EJWo05qkA (九种跨域方式实现原理)
[^9]: https://juejin.im/post/5c09cbb1f265da617006ee83
[^10]: https://juejin.im/post/5ceb480cf265da1b614fd537
[^11]: http://www.ruanyifeng.com/blog/2019/09/cookie-samesite.html
[^12]: https://web.dev/samesite-cookies-explained/

