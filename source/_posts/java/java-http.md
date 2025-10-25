---
layout: "post"
title: "Java之HTTP请求"
date: "2020-08-26 17:24"
categories: [java]
tags: [http]
---

## SpringBoot请求及响应

- 相关配置

```bash
# 端口
server.port=9090
# context-path路径
server.context-path=/myapp
```

### 请求协议

- 参考文章
    - 原理参考：[spring-mvc-src.md#MVC请求参数解析](/_posts/java/java-src/spring-mvc-src.md#MVC请求参数解析)
    - https://www.hangge.com/blog/cache/detail_2485.html (POST请求示例)
    - https://www.hangge.com/blog/cache/detail_2484.html (GET请求示例)
- 常见请求方式

| request-method | Content-Type                          | postman               | springboot                                                                                       | 说明                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| -------------- |---------------------------------------| --------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| post           | `application/json`                    | row-json              | (@RequestBody List<Map<String, Object>> items)                                                   | 使用了`@RequestBody`可以接受 body 中的参数(最终转成 User/Map/List 对象                                                                                                                                                        |
| post           | `application/json`                    | row-json              | (String userIdUrlParam, @RequestBody User user)                                                  | `String userIdUrlParam`可以接受 url 中的参数，此时 body 中的数据不能直接通过 String 等接受)，而 idea 的 http 文件中 url 参数拼在地址上无法获取(请求机制不同)；对于同时支持 GET/POST 方法的情况，可使用 @RequestBody **(required = false)** Map<String, Object> data 来适配 GET 请求没有请求体的情况                                                                                                                                                             |
| (x)post        | `application/json`                    | row-json              | (@RequestParam username)                                                                         | 如果前台为 application/json + {username: smale}或者 application/json + username=smalle 均报 400；此时需要 application/x-www-form-urlencoded + username=smalle 才可请求成功                                                                                                                                                                                                                                                                            |
| post           | `application/x-www-form-urlencoded`   | x-www-form-urlencoded | (String name, User user, @RequestBody body)                                                      | `String name`可以接受 url 中的参数，postmant 的 x-www-form-urlencoded 中的参数会和 url 中参数合并后注入到 springboot 的参数中；`@RequestBody`会接受 url 整体的数据，(由于 Content-Type)此时不会转换，body 接受的参数如`name=hello&name=test&pass=1234`。**对于 application/x-www-form-urlencoded 类型的数据，可无需 @RequestBody 接受参数**                                                                                                           |
| post           | `multipart/form-data`                 | form-data             | (HttpServletRequest request, MultipartFile file, User user, @RequestParam("hello") String hello) | 参考[文件上传下载](#文件上传下载)，文件上传必须使用此类型(包含参数)；javascript XHR(包括 axios 等插件)需要使用 new FormData()进行数据传输；此时参数映射到 User 对象，如果字段为 null 则会转换成'null'进行映射，如果改字段为数值类型，会导致字符串转数值出错；**如果接受参数是 Map 则无法映射，可通过传入JSON字符串再反序列化**；表单数据都保存在 http 的正文部分，各个表单项之间用 boundary 隔开，用 request.getParameter 是取不到数据的，这时需要通过 request.getInputStream 来取数据 |
| get            | -                                     | -                     | (User user, Page page)                                                                           | 前台传输参数为{username: 'smalle', pageSize: 10}时，可正确分别映射到两个对象；如果此时为 post 请求则无法映射；get 请求时，请求参数会拼接到 url 上，Google 浏览器 URL 最大长度限制为 8182 个字符，中文是以 urlencode 后的编码形式进行传递，如果浏览器的编码为 UTF8 的话，一个汉字最终编码后的字符长度为 9 个字符(中=%E4%B8%AD)。如果用 Map 接受，则数字类型的值也会映射成字符串                                                                     |
| all            | 如`application/x-www-form-urlencoded` | all                   | (Map<String, Object> param)                                                                      | 前台传输参数为?age=&count=10000时，得到的字段数据类型均为字符串。(必须)加@RequestParam注解才能获取到Map(值也全部是字符串)；除了url上的参数，form-data的时候可将其值也放到map中(x-www-form-urlencoded中的不会放到map)                                                                |

- content-type传入"MIME类型"(多用途因特网邮件扩展 Multipurpose Internet Mail Extensions)只是一个描述，决定文件的打开方式
	- 请求的header中加入content-type标明数据MIME类型。如POST时，application/json表示数据存放在body中，且数据格式为json
	- 服务器response设置content-type标明返回的数据类型。接口开发时，设置请求参数是无法改变服务器数据返回类型的。部分工具提供专门的设置，通过工具内部转换的方式实现设定返回数据类型

### 请求参数

- 如果所在类加注解`@RequestMapping("/user")`，则请求url全部要拼上`/user`，如`/user/hello`

```java
@RequestMapping(value = "/hello") // 前台post请求也可以请求的到
public String hello() {
	return "hello world";
}
```

- GET请求

```java
// 前台GET请求 Body/Url 中含参数 userId和username（Spring可以自动注入java基础数据类型和对应的数组，Map/List无法注入）
// 只能自动注入userId=1&username=smalle格式的数据，如果请求体中是json数据则无法解析(如果参数为json数据，一般可定义请求头为`'Content-Type': 'application/x-www-form-urlencoded'`，从而让qs等插件自动转成url格式参数请求后台)
@RequestMapping(value="/getUserByUserIdOrUsername")
public Result getUserByUserIdOrUsername(Long userId, String username, HttpServletRequest request) {
	// ...
	return Result.success(); // 自己封装的Result对象(前台可接受到此object对象)
}
// 前台请求 Body/Url 中含参数 username
@RequestMapping(value="/getUserByName")
public String getUserByName(@RequestParam("username") String name) {}
@RequestMapping(value = "/getUser")
public String getUser(User user) {} // 此时User对象必须声明getter/setter方法
// @PathVariable 获取 url 中的参数
@RequestMapping(value="/hello/{id}")
public String user(@PathVariable("id") Long id) {} // 100可转成Long
```

- POST请求

```java
// 请求头为application/x-www-form-urlencoded(不能是application/json，否则无法注入)
@RequestMapping(value = "/addUser", method = RequestMethod.POST)
public String hello(User user) {}
public String hello(Map<String, Object> map) {}

// 如请求头为`application/json`，此body中为一个json对象(请求时无需加 data={} 等key，直接为 {} 对象)。
// 直接通过 `@RequestBody User user` 获取body中的参数(springboot会自动映射)，或者`@RequestBody String body`接收了之后再转换，但是不能同时使用两个。如果body可以成功转成Map/List，此处也可以用 `@RequestBody Map<String, Object>`接受
@RequestMapping(value = "/addUser", method = RequestMethod.POST)
public String addUser(@RequestBody List<User> user) {} // body数据可以成功转成Map/List时
public String addUser(@RequestBody Map<String, Object> map) {}

// 请求数据http://localhost/?name=smalle&pass=123
@RequestMapping(value = "/addUser", method = RequestMethod.POST)
public String addUser(@RequestBody String param) {} // 此时param拿到的值为 name=smalle&pass=123
```
- 参数映射

```java
// 1.如果user对象中有字段如 uFullName (驼峰，首字母只有一个字符的情况)
// 如果接受参数为普通对象，则前台需要传入字段为 ufullName；如果接受参数为 Map，则前台需要传入字段为 uFullName
public String addUser(@RequestBody User user) {}
public String addUser(@RequestBody Map<String, Object> map) {
    // BeanUtil.copyProperties
}
```

### 响应

- `@ResponseBody`
	- 表示以json返回数据
	- 定义在类名上，表示所有的方法都是`@ResponseBody`的，也可单独定义在方法上
- `@RestController`中包含`@ResponseBody`
- 重定向

```java
@SneakyThrows
@RequestMapping("/download/{id}/{fileName}")
public void download(@PathVariable("id") Integer id, HttpServletRequest request, HttpServletResponse response) {
    EdiHead info = ediHeadService.info(id);
    String ediPath = info.getEdiPath();
    // 内部重定向，/files不以/开头，则会加上原始请求路径
    request.getRequestDispatcher("/files" + ediPath).forward(request, response);

    // 重定向
    // response.sendRedirect("/files");
}
```

### 前端数组/对象处理

- json字符串传输方式一(不推荐)
    - 前端通过`JSON.stringify`转成json字符串，然后后台JSONObject等转成Bean/Map等
- Spring的Bean自动注入
    - 请求类型 `POST`、`Content-Type: application/json`，后端方法为`public Result edit(@RequestBody CustomerInfo customerInfo)`接受，chrome开发者模式看到的为json对象
    - 请求类型 `POST`、`Content-Type: multipart/form-data`、使用FormData传输参数，后端可使用`public Result edit(Multipart myFile, CustomerInfo customerInfo)`接受，chrome开发者模式看到的同上文FormData。传输文件必须格式
	- 请求类型 `POST`、`Content-Type: application/x-www-form-urlencoded`
	    - chrome开发模式看到的`FormData`(格式化后的。实际请求是将每一项通过`URL encoded`进行转义之后再已`&`连接组装成url参数，此时POST参数是没有长度限制的)如：
        - 后端写好对应的Bean，且后端方法如`public Result edit(CustomerInfo customerInfo)`
            - 后端代码`public Result edit(Map<String, Object> params)`报错
            - 后端代码`public Result edit(String customerNameCn, List customerLines)`报错

		```js
		id: 766706
        customerNameCn: 客户名称
        // CustomerInfo中的updateTm属性可以是Date(会自动转换)
        updateTm: 2018/08/17 13:02:36
        // CustomerInfo中的属性customerLines(属性名/setter方法必须和前端参数名保持一致)可以是List<String>或者String[]
		customerLines[0]: AustraliaLine
		customerLines[1]: MediterraneanLine
        customerLines[2]: SoutheastAsianLine
        // CustomerInfo中包含CustomerRisk和List<CustomerContacts>
		customerRisk.id: 9906
		customerRisk.customerId: 766706
		customerRisk.note: 客户风险备注
		customerContacts[0].id: 767001
		customerContacts[0].customerId: 766706
		customerContacts[0].lastName: 客户联系人1
		```

### 拦截request的body数据/拦截response的数据

参考[spring.md#拦截response的数据](/_posts/java/spring.md#拦截response的数据)

### SpringBoot中使用Servlet

- 使用方法

```java
// 方式一: 访问 http://localhost:8080/api/test/* 都可以进入到此servlet
@Bean
public ServletRegistrationBean testServlet() {
    return new ServletRegistrationBean(new TestServlet(), "/test/*");
}

// 方式二：启动类加 @ServletComponentScan + @WebServlet(urlPatterns = "/test/*")
// @WebServlet(urlPatterns = "/test/*") // 方式二需要
public class TestServlet extends HttpServlet{
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().append("TestServlet");
    }
}
```

## RestTemplate

### 简单使用

```java
@Autowired
RestTemplate restTemplate;

// 1.getForEntity
ResponseEntity<Map> responseEntity = restTemplate.getForEntity(
	"http://localhost/list?username={name}", // ***此处一定需要占位符{name}***
	Map.class, // 返回的数据转换的类型(需确保可以转换成此类型)
	new HashMap<String, Object>() {{put("name", "smalle");}});
// 获取返回信息
HttpHeaders headers = responseEntity.getHeaders();
HttpStatus statusCode = responseEntity.getStatusCode();
int code = statusCode.value();
Map map = responseEntity.getBody();

// 2.getForObject
Video video = restTemplate.getForObject("http://localhost/video", Video.class);
Map retInfo = restTemplate.getForObject("http://localhost/test", Map.class); // 此时需要接口返回的数据类型为`application/json`，如果为`text/plain`则会报错(此时只能通过String.class来接收，然后转成json)

// 3.postForEntity
Video video = new Video();
ResponseEntity<Video> responseEntity = restTemplate.postForEntity("http://localhost/video", video, Video.class);
video = responseEntity.getBody();

// 4.postForObject
Map retInfo = restTemplate.postForObject("http://localhost/test", params, Map.class); // params 为 Map 类型请求参数，目标服务需要通过 @RequestBody 接收

// 5.定义Header
HttpHeaders headers = new HttpHeaders(); // org.springframework.http.HttpHeaders impl MultiValueMap
headers.add("X-Auth-Token", "123456789");
Map<String, Object> postParameters = MiscU.toMap("username", "smalle", "age", "18");
HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(postParameters, headers);
Map retInfo = restTemplate.postForObject("http://localhost/test", requestEntity, Map.class);
// GET请求带Header
if(ValidU.isNotEmpty(params)) {
    UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(url);
    for (Map.Entry<String, Object> e : params.entrySet()) {
        builder.queryParam(e.getKey(), e.getValue());
    }
    url = builder.build().toString();
}
HttpEntity<Map<String, Object>> getHttpEntity = new HttpEntity<>(null, headers);
ResponseEntity<String> exchange = restTemplate.exchange(url, HttpMethod.GET, getHttpEntity, String.class, params); // 此处params无用仅作为占位符，参数需要通过上文url拼接
String response = exchange.getBody();

// 6.MultiValue
MultiValueMap<String, Object> postData = new LinkedMultiValueMap<String, Object>();
postData.add("name", "123");
HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(postData);
HttpEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, requestEntity, String.class);
```

### Bean配置

- **增加超时机制**、自定义拦截器、忽略证书、处理中文乱码

```java
// Spring Boot 3.0+ 推荐使用 WebClient 替代 RestTemplate
@Bean
public WebClient webClient() {
    return WebClient.builder().build();
}

@Autowired
private WebClient webClient;

public void fetchData() {
    String result = webClient.get()
        .uri("https://api.example.com/data")
        .retrieve()
        .bodyToMono(String.class)
        .block();
}

// ------ RestTemplateBuilder 可能无法注入, 使用
@Bean
public RestTemplate restTemplateForReportTableJob() {
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory(); // 可做成Bean, 参考下文
    factory.setConnectTimeout(1000 * 60 * 5);
    factory.setReadTimeout(1000 * 60 * 5);
    RestTemplate restTemplate = new RestTemplate(factory);
    restTemplate.getMessageConverters().add(getMappingJackson2HttpMessageConverter());
    //restTemplate.getMessageConverters().set(1, new StringHttpMessageConverter(StandardCharsets.UTF_8));
    return restTemplate;
}
private MappingJackson2HttpMessageConverter getMappingJackson2HttpMessageConverter() {
    MappingJackson2HttpMessageConverter converter = new MappingJackson2HttpMessageConverter();
    List<MediaType> mediaTypes = new ArrayList<>();
    mediaTypes.add(MediaType.APPLICATION_OCTET_STREAM);
    converter.setSupportedMediaTypes(mediaTypes);
    return converter;
}

// ------
// 如果不设置 RestTemplate 相关属性，则无需手动引入
@Bean // spirngboot > 1.4 无需其他依赖
public RestTemplate customRestTemplate(RestTemplateBuilder restTemplateBuilder) {
	// 1.服务器内存溢出，还未宕机时，是可以请求服务，但是一直获取不到返回。需要超时机制
    RestTemplate restTemplate = restTemplateBuilder
            // 连接主机的超时时间（单位：毫秒）
			.setConnectTimeout(5000)
            // 从主机读取数据的超时时间（单位：毫秒）
			.setReadTimeout(5000)
			.build();
    
    // 2.自定义拦截器restTrackInterceptor(implements org.springframework.http.client.ClientHttpRequestInterceptor)。必须通过此拦截器才可以修改如Header中的值，AOP无法修改
    restTemplate.setInterceptors(Collections.singletonList(restTrackInterceptor));

    // 3.忽略证书(绕过证书)
    try {
        SSLContext sslContext = org.apache.http.ssl.SSLContexts.custom()
                .loadTrustMaterial(null, new org.apache.http.ssl.TrustStrategy() {
                    @Override
                    public boolean isTrusted(java.security.cert.X509Certificate[] x509Certificates, String s) throws CertificateException {
                        return true;
                    }
                })
                .build();
        SSLConnectionSocketFactory csf = new SSLConnectionSocketFactory(sslContext);
        CloseableHttpClient httpClient = HttpClients.custom()
                .setSSLSocketFactory(csf)
                .build();
        HttpComponentsClientHttpRequestFactory requestFactory = new HttpComponentsClientHttpRequestFactory();
        requestFactory.setHttpClient(httpClient);
        restTemplate = new RestTemplate(requestFactory);
    } catch (Exception e) {
        log.error("RestTemplate 忽略证书调用错误：", e);
    }

    // 4.处理中文乱码
    restTemplate.getMessageConverters().set(1, new StringHttpMessageConverter(StandardCharsets.UTF_8));

    // 处理 application/octet-stream 格式返回结果
    // https://blog.csdn.net/k_young1997/article/details/122858104

	return restTemplate;
}

// @Bean // springboot < 1.3 需要httpclient依赖
// public RestTemplate customRestTemplate(){
//     HttpComponentsClientHttpRequestFactory httpRequestFactory = new HttpComponentsClientHttpRequestFactory();
//     httpRequestFactory.setConnectionRequestTimeout(3000);
//     httpRequestFactory.setConnectTimeout(3000);
//     httpRequestFactory.setReadTimeout(3000);
//
//     return new RestTemplate(httpRequestFactory);
// }

@Primary // 默认的Bean
@Bean
public RestTemplate restTemplate() {
	return new RestTemplate();
}

// 超时机制写法二
@Bean
public RestTemplate restTemplate(ClientHttpRequestFactory factory){
    return new RestTemplate(factory);
}
@Bean
public ClientHttpRequestFactory simpleClientHttpRequestFactory(){
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(15000);
    factory.setReadTimeout(15000);
    return factory;
}
```

#### 客户端端口限制

- 在对服务器进行连接时，会自动获取一个随机端口用于连接。（假设此客户端也对外提供服务，那么假设此时监听的为端口8080，当此客户端请求其他服务器时，是不会用8080作为连接端口的）
    - linux可设置`/etc/system.config`中的`net.ipv4.ip_local_port_range`来修改随机端口范围
    - windows可用`netsh`命令设置
- 固定TCP连接时的客户端端口。使用场景如：**部分应用因安全考虑，只能指定端口访问外网** [^1]
    - 存在问题：只适用于对某个服务器的连接，或者多个服务器的少量连接（如果对多个服务器有大量并发连接可能会出现端口被占用问题）

```java
public static void main(String[] args) {
    HttpClientBuilder builder = HttpClientBuilder.create();
    RegistryBuilder<ConnectionSocketFactory> registryBuilder = RegistryBuilder.create();
    Registry<ConnectionSocketFactory> socketFactoryRegistry = registryBuilder
            .register("http", new PlainConnectionSocketFactory() {
                public Socket createSocket(HttpContext context) throws IOException {
                    Socket socket = new Socket();
                    // 绑定客户端端口
                    socket.bind(new InetSocketAddress(10011));
                    System.out.println("http-port = [" + socket.getLocalPort() + "]");
                    return socket;
                }
            })
            // 对于只有HTTPS请求的，可以直接设置builder.setSSLSocketFactory即可
            .register("https", new SSLConnectionSocketFactory(SSLContexts.createDefault()) {
                public Socket createSocket(HttpContext context) throws IOException {
                    Socket socket = SocketFactory.getDefault().createSocket();
                    // 绑定客户端端口
                    socket.bind(new InetSocketAddress(10012));
                    System.out.println("https-port = [" + socket.getLocalPort() + "]");
                    return socket;
                }
            }).build();
    builder.setConnectionManager(new PoolingHttpClientConnectionManager(socketFactoryRegistry));
    HttpClient httpClient = builder.build(); // org.apache.http.client.HttpClient 基于
    HttpComponentsClientHttpRequestFactory factory = new HttpComponentsClientHttpRequestFactory(httpClient);
    factory.setReadTimeout(5000);
    factory.setConnectTimeout(5000);

    RestTemplate restTemplate = new RestTemplate();
    restTemplate.setRequestFactory(factory);

    // 测试(可通过抓包查看)
    try {
        String url = "http://www.baidu.com";
        // String url = "https://api.weixin.qq.com/cgi-bin/token";
        for (int i = 1 ; i <= 10; i++) {
            String s = restTemplate.getForObject(url, String.class);
            System.out.println(s);
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

### 文件上传下载(调用接口形式)

```java
// 参考：https://www.cnblogs.com/zimug/archive/2020/08/12/13488517.html

// 上传
public void upload() {
    // 文件上传接口地址
    String url = "http://localhost:8888/upload";
    // 待上传的文件（存在客户端本地磁盘）
    String filePath = "D:/test.png";
    FileSystemResource resource = new FileSystemResource(new File(filePath));
    MultiValueMap<String, Object> param = new LinkedMultiValueMap<>();
    params.add("file", resource);  // 服务端 MultipartFile file
    // params.add("name", "test"); // 服务端如果接受额外参数，可以传递
    // 发送请求并输出结果
    String result = restTemplate.postForObject(url, params, String.class);
}

// 下载(大文件可进行流式下载)。前台使用参考：[springboot-vue.md#文件下载案例](/_posts/arch/springboot-vue.md#文件下载案例)
@SneakyThrows
@RequestMapping("/download/{id}/{fileName}")
public void download(@PathVariable("id") Integer id, @PathVariable("fileName") String fileName, HttpServletResponse response){
    String url = ediHeadList + "/" + id + "/" + fileName;
    ResponseEntity<byte[]> rsp = restTemplate.getForEntity(url, byte[].class);
    byte[] body = rsp.getBody();
    OutputStream os = null;
    try {
        os = response.getOutputStream();
        os.write(body);
        os.flush();
    } finally {
        if(os != null) {
            os.close();
        }
    }
}

// 大文件下载
// 设置了请求头APPLICATION_OCTET_STREAM，表示以流的形式进行数据加载
// RequestCallback 结合File.copy保证了接收到一部分文件内容，就向磁盘写入一部分内容。而不是全部加载到内存，最后再写入磁盘文件
public void bigDownload() {
    // 待下载的文件地址
    String url = "http://localhost:8888/big.png";
    // 文件保存的本地路径
    String targetPath = "D:/big.png";
    // 定义请求头的接收类型
    RequestCallback requestCallback = request -> request.getHeaders()
        .setAccept(Arrays.asList(MediaType.APPLICATION_OCTET_STREAM, MediaType.ALL));
    // 对响应进行流式处理而不是将其全部加载到内存中
    restTemplate.execute(url, HttpMethod.GET, requestCallback, clientHttpResponse -> {
        Files.copy(clientHttpResponse.getBody(), Paths.get(targetPath));
        return null;
    });
}
```

## 文件上传下载

- 案例参考[springboot-vue.md#文件上传案例](/_posts/arch/springboot-vue.md#文件上传案例)
- 常用配置

```yml
spring:
  http:
    multipart:
      # Linux下会自动清除tmp目录下10天没有使用过的文件，SpringBoot启动的时候会在/tmp目录下生成一个Tomcat.*的文件目录，用于"java.io.tmpdir"文件流操作，因为放假期间无人操作，导致Linux系统自动删除了临时文件，所以导致上传报错。另一种配置方式参考下文 MultipartConfigElement
      # spirngboot 2.1无效，有说配置 `server.tomcat.basedir=/var/tmp/tomcat`，未测试
      location: /var/tmp
  servlet:
    multipart:
      # 允许的最大文件大小
      max-file-size: 50MB
      max-request-size: 50MB
  mvc:
    # 静态资源映射，通过后台访问文件的路径(一般需要排除对此路径的权限验证)。相当于一个映射，映射的本地路径为 spring.resources.static-locations
    # 默认值为 /files/** 或 /** (取决于版本), 如果定义了其他则只有此路径才会到对应静态目录去寻找文件
    # 实际访问还需要增加servlet.context路径(/api)，如访问 /api/files/test/test.js -> test/test.js(此时test目录会自动识别属于哪个目录)
    static-path-pattern: /files/** # 此路径尽量不要和classpath目录下文件夹重名
  resources:
    # 默认为: classpath:/META-INF/resources/,classpath:/resources/,classpath:/public/,classpath:/static/
    # 后台可访问的本地文件路径. **最终的URL路径不需要携带此前缀，即应该保存各目录下的顶级子目录不会重复。如果重复了，static-locations值中排在前面的优先**
    # 如果只配置成了 file:/data, 则 classpath:/static/ 路径下的就会失效
    static-locations: file:/data/app,classpath:/META-INF/resources/,classpath:/resources/
```
- 使用JavaBean进行静态文件映射

```java
@Configuration
public class InterceptorConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 可添加多条，优先级先添加的高于后添加的
        // 通过此方式添加的映射优先级高于上文static-path-pattern配置的
        registry.addResourceHandler("/image/**").addResourceLocations("file:D:/image/"); // file:/D:/image/ 亦可. 实际访问还需要增加servlet.context路径
    }
}
```
- 上传文件临时目录问题
	- 项目启动默认会产生一个tomcat上传文件临时目录，如：`/tmp/tomcat.4234211497561321585.8080/work/Tomcat/localhost/ROOT`
	- 而linux会定期清除tmp目录下文件，尽管项目仍然处于启动状态。从而会导致错误`Caused by: java.io.IOException: The temporary upload location [/tmp/tomcat.4234211497561321585.8080/work/Tomcat/localhost/ROOT] is not valid`

```java
// 自定义上传文件临时目录
@Bean 
public MultipartConfigElement multipartConfigElement() {
	MultipartConfigFactory factory = new MultipartConfigFactory();  
	factory.setLocation("/app/tmp");
	return factory.createMultipartConfig();
}
```
- 后台会报错：no multipart boundary was found。此问题本身不是后台的原因，解决方法如下 [^21]
    - 通过`axios.create`重新定义一个axios实例，并挂载到Vue原型上。此处重新定义是防止使用项目中默认的axios实例(一般会通过axios.interceptors.request.use进行处理，而处理后的实例在上传时后台会报错)。具体见上文案例
    - 不严谨的处理

        ```js
        // $axios为上文提到的被处理过的axios实例
        this.$axios.post('http://localhost:8080/upload', formData, {
            headers: {
                'Content-Type': 'multipart/form-data;boundary = ' + new Date().getTime()
            }
        }).then(response => {})
        ```

## Apache-HttpClient

- maven

```xml
<dependency>
    <groupId>org.apache.httpcomponents.client5</groupId>
    <artifactId>httpclient5</artifactId>
    <version>5.3</version>
</dependency>
```

```java
public static void main(String[] args) {
    // 发送GET请求
    String getResponse = sendGetRequest("https://api.example.com/data");
    System.out.println("GET响应: " + getResponse);
    
    // 发送POST请求
    String jsonBody = "{\"name\":\"test\",\"value\":\"example\"}";
    String postResponse = sendPostRequest("https://api.example.com/submit", jsonBody);
    System.out.println("POST响应: " + postResponse);
}

// 发送GET请求
private static String sendGetRequest(String url) {
    try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
        HttpGet httpGet = new HttpGet(url);
        httpGet.setHeader("Content-Type", "application/json");
        
        try (CloseableHttpResponse response = httpClient.execute(httpGet)) {
            return EntityUtils.toString(response.getEntity());
        }
    } catch (Exception e) {
        e.printStackTrace();
        return null;
    }
}

// 发送POST请求
private static String sendPostRequest(String url, String jsonBody) {
    try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
        HttpPost httpPost = new HttpPost(url);
        httpPost.setHeader("Content-Type", "application/json");
        
        // 设置请求体
        StringEntity entity = new StringEntity(jsonBody);
        httpPost.setEntity(entity);
        
        try (CloseableHttpResponse response = httpClient.execute(httpPost)) {
            return EntityUtils.toString(response.getEntity());
        }
    } catch (Exception e) {
        e.printStackTrace();
        return null;
    }
}
```

## Java自带HttpURLConnection

```java
public static void main(String[] args) {
    String urlString = "https://api.example.com/data";
    
    try {
        URL url = new URL(urlString);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        
        // 设置请求方法
        connection.setRequestMethod("GET");
        
        // 设置请求头
        connection.setRequestProperty("Content-Type", "application/json");
        connection.setRequestProperty("User-Agent", "Java HTTP Client");
        
        // 获取响应码
        int responseCode = connection.getResponseCode();
        System.out.println("响应码: " + responseCode);
        
        // 读取响应内容
        BufferedReader in = new BufferedReader(
            new InputStreamReader(connection.getInputStream()));
        String inputLine;
        StringBuffer response = new StringBuffer();
        
        while ((inputLine = in.readLine()) != null) {
            response.append(inputLine);
        }
        in.close();
        
        // 打印响应结果
        System.out.println("响应内容: " + response.toString());
        
        // 关闭连接
        connection.disconnect();
        
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```




---

参考文章

[^1]: https://www.pianshen.com/article/1995338084/
