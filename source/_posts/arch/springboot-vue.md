---
layout: "post"
title: "基于springboot和vue前后分离"
date: "2017-12-25 21:16"
categories: [arch]
tags: [springboot, vue]
---

## TODO

- ASF
    - IS/BS的拜访基于同一张表保存是否需要分开
    - IS/BS拜访的父子关系(祖宗关系)导致逻辑复杂

## 默认配置

- 后端返回数据字段驼峰(如果通过ObjectMapper字段名转成下划线，前台做好下划线命名的字段映射后传回给后台，此时后台pojo都是驼峰，导致无法转换)
- 前后台url都以`/`开头方便全局搜索

## Spring

- 表单操作的dto应该基于业务模式进行解耦，不要耦合到一个dto中
    - 出错场景：使用dto(数据传输对象)接受前端数据后，并`BeanUtils.copyProperties`将dto复制到po(持久化对象)中，且前端有清除数据库部分字段的需求(此时dto中该字段传入的值为null，并使用mybatis生成的`updateByPrimaryKey`进行更新)。但是内部字段(一般不会让用户直接修改的)初始化后不应该置空。后来在修改某些需求时(如基于客户直接创建拜访)，不小心简单将内部字段(创建拜访时会从客户中查询到CRM_ID并创建拜访记录)加入到dto中加入了部分其他字段导致，此时普通修改时前端并没有传入CRM_ID，导致将内部字段置空

## Mybatis

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
- 浏览器"同源政策"限制(针对不同源情况) [^2]
    - `Cookie、LocalStorage 和 IndexDB 无法读取`
    - `DOM 无法获得`
    - `AJAX 请求不能发送`
- 解决方案
    - `JSONP`(只能发送GET请求)
    - `CORS`(服务器端进行设置即可)
    - `WebSocket`
    - `postMessage`
    - 架设服务器代理（浏览器请求同源服务器，再由后者请求外部服务）
        - 基于`nginx`做中转

        ```shell
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
    CorsConfigurationSource corsConfigurationSource() {
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
            method: 'post',
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

## 用户浏览器缓存问题 [^5]

- 使用vue框架开发，版本更新，用户浏览器会存在缓存问题
- vue-cli里的默认配置，css和js的名字都加了哈希值，所以新版本css、js和就旧版本的名字是不同的，不会有缓存问题。
- 不过值得注意的是，把打包好的index.html放到服务器里去的时候，index.html在服务器端可能是有缓存的，这需要在服务器配置不让缓存index.html
- nginx 配置，让index.html不缓存

```bash
# nginx 配置，让index.html不缓存
location = /index.html {
    add_header Cache-Control "no-cache, no-store";
    # ...
}
```

## 其他

- 使用nginx导致部分地址直接浏览器访问报404(如基于`quasar`的项目)。可修改nginx配置如下

```bash
# 本地查找，如果没有就跳转到index.html(实际访问的还是源地址)
location / {
	try_files $uri $uri/ /index.html;
}
```

## 常用插件

### Clipboard 复制内容到剪贴板

- 必须要绑定Dom
- 必须要触发点击事件（触发其他Dom的点击事件，然后js触发目的dom的点击事件也可）







---

参考文章

[^1]: http://www.ruanyifeng.com/blog/2016/04/cors.html (跨域资源共享CORS详解)
[^2]: http://www.ruanyifeng.com/blog/2016/04/same-origin-policy.html (浏览器同源政策及其规避方法)
[^3]: https://docs.spring.io/spring-security/site/docs/4.2.x/reference/html/cors.html (spring-security-cors)
[^4]: https://segmentfault.com/a/1190000013312233 (springBoot与axios表单提交)
[^5]: https://blog.csdn.net/qq_32340877/article/details/80338271 (使用vue框架开发，版本更新，解决用户浏览器缓存问题)