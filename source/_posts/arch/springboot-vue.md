---
layout: "post"
title: "基于springboot和vue前后分离"
date: "2017-12-25 21:16"
categories: [arch]
tags: [springboot, vue]
---

## 简介


## 跨域和session/token

### 同源政策

- 网络协议、ip、端口三者都相同就是同一个域(同源)
    - 如`http://localhsot`和`http://localhsot:8080`之间进行数据交互就存在跨域问题
- 浏览器"同源政策"限制(针对不同源情况) [^2]
    - `Cookie、LocalStorage 和 IndexDB 无法读取`
    - `DOM 无法获得`
    - `AJAX 请求不能发送`
- AJAX请求受到同源政策限制的解决办法
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
                root   D:\demo\vue\dist;
                index  index.html index.htm;
            }
        }
        ```
    - `JSONP`(只能发送GET请求)
    - `WebSocket`
    - `CORS`

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
        configuration.setAllowedOrigins(Arrays.asList("*"));
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
- `axios`使用post方式传递参数后端接受不到 [^4]
    - `axios`使用`x-www-form-urlencoded`请求，参数应该写到`param`中
    
        ```js
        axios({
            method: 'post',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            url: 'http://localhost:8080/api/login',
            params: {
                username:'smalle',
                password:'smalle'
            }
        }).then((res)=>{

        })
        ```

        - axios的params和data两者关系：params是添加到url的请求字符串中的，用于get请求；而data是添加到请求体body中的， 用于post请求(如果写在`data`中，加`headers: {'Content-Type': 'application/x-www-form-urlencoded'}`也不行)
        - jquery在执行post请求时，会设置Content-Type为application/x-www-form-urlencoded，且会把data中的数据添加到url中，所以服务器能够正确解析
        - 使用原生ajax(axios请求)时，如果不显示的设置Content-Type，那么默认是text/plain，这时服务器就不知道怎么解析数据了，所以才只能通过获取原始数据流的方式来进行解析请求数据
    - 使用`qs`插件，未测试，具体参考：https://segmentfault.com/a/1190000012635783














---

参考文章

[^1]: [跨域资源共享CORS详解](http://www.ruanyifeng.com/blog/2016/04/cors.html)
[^2]: [浏览器同源政策及其规避方法](http://www.ruanyifeng.com/blog/2016/04/same-origin-policy.html)
[^3]: [spring-security-cors](https://docs.spring.io/spring-security/site/docs/4.2.x/reference/html/cors.html)
[^4]: [axios使用post方式传递参数后端接受不到](https://segmentfault.com/a/1190000012635783)