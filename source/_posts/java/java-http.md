---
layout: "post"
title: "Java之HTTP请求"
date: "2020-08-26 17:24"
categories: [java]
tags: [http]
---

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
// 定义Header
HttpHeaders headers = new HttpHeaders(); // org.springframework.http.HttpHeaders impl MultiValueMap
headers.add("X-Auth-Token", "123456789");
Map<String, Object> postParameters = new HashMap<>();
postParameters.add("username", "smalle");
postParameters.add("age", "18");
HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(postParameters, headers);
Map retInfo = restTemplate.postForObject("http://localhost/test", requestEntity, Map.class);
```

### 上传下载

```java
// 参考：https://www.cnblogs.com/zimug/archive/2020/08/12/13488517.html
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
```

### Bean配置

- **增加超时机制**、自定义拦截器、忽略证书、处理中文乱码

```java
// 如果不设置 RestTemplate 相关属性，则无需手动引入
@Bean // spirngboot > 1.4 无需其他依赖
public RestTemplate customRestTemplate(RestTemplateBuilder restTemplateBuilder) {
	// 1.服务器内存溢出，还未宕机时，是可以请求服务，但是一直获取不到返回。需要超时机制
    RestTemplate restTemplate = restTemplateBuilder
			.setConnectTimeout(3000) // 连接主机的超时时间（单位：毫秒），3s
			.setReadTimeout(3000) // 从主机读取数据的超时时间（单位：毫秒），3s
			.build();
    
    // 2.自定义拦截器restTrackInterceptor(implements org.springframework.http.client.ClientHttpRequestInterceptor)。必须通过此拦截器才可以修改如Header中的值，AOP无法修改
    restTemplate.setInterceptors(Collections.singletonList(restTrackInterceptor));

    // 3.忽略证书
    try {
        SSLContext sslContext = org.apache.http.ssl.SSLContexts.custom()
                .loadTrustMaterial(null, new TrustStrategy() {
                    @Override
                    public boolean isTrusted(X509Certificate[] x509Certificates, String s) throws CertificateException {
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
```

#### 客户端端口限制

- 在对服务器进行连接时，会自动获取一个随机端口用于连接。（假设此客户端也对外提供服务，那么假设此时监听的为端口8080，当此客户端请求其他服务器时，是不会用8080作为连接端口的）
    - linux可设置`/etc/system.config`中的`net.ipv4.ip_local_port_range`来修改随机端口范围
    - windows可用`netsh`命令设置
- 固定TCP连接时的客户端端口。使用场景如：部分应用因安全考虑，只能指定端口访问外网 [^1]
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










---

参考文章

[^1]: https://www.pianshen.com/article/1995338084/
