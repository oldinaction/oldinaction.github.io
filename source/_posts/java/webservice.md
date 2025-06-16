---
layout: "post"
title: "Webservice"
date: "2018-08-15 20:34"
categories: java
tags: [http]
---

## springboot使用webservice

- 基于`Apache CXF(3.1.8)`、`Springboot(1.5.6.RELEASE)`测试
- 引入依赖

```xml
<dependency>
    <groupId>org.apache.cxf</groupId>
    <artifactId>cxf-rt-frontend-jaxws</artifactId>
    <version>3.1.8</version>
</dependency>
<dependency>
    <groupId>org.apache.cxf</groupId>
    <artifactId>cxf-rt-transports-http</artifactId>
    <version>3.1.8</version>
</dependency>
```

### 服务端

- 接口地址：`http://localhost:8080/services/user?wsdl`，服务描述如下

    ![webservice](/data/images/java/webservice.png)
- 主要代码如下

```java
// 1.Model, 省略getter/setter
public class User implements Serializable {
    private static final long serialVersionUID = -5939599230753662529L;
    private String userId;
    private String username;
    private String age;
    private Date updateTime;
    // ... 省略getter/setter
}

// 2.服务接口
@WebService // import javax.jws.WebService;
public interface UserService {
    @WebMethod
    String getName(@WebParam(name = "userId") String userId);

    @WebMethod
    User getUser(String userId);

    @WebMethod
    ArrayList<User> getAllUser();
}

// 3.服务实现
@WebService(
    serviceName = "UserServiceWeb", // 服务名(默认UserServiceImplService)
    targetNamespace = "http://service.cxf.webservice.springboot.aezo.cn/", // 实现类包名倒写 (默认，可省略，基于JAX-WS调用服务会用到)
    endpointInterface = "cn.aezo.springboot.webservice.cxf.service.UserService" // 接口的全路径
)
@Service
public class UserServiceImpl implements UserService {
    private Map<String, User> userMap = new HashMap<>();

    public UserServiceImpl() {
        User user = new User();
        user.setUserId("1");
        user.setUsername("zhansan");
        user.setAge("20");
        user.setUpdateTime(new Date());
        userMap.put(user.getUserId(), user);

        user = new User();
        user.setUserId("2");
        user.setUsername("lisi");
        user.setAge("30");
        user.setUpdateTime(new Date());
        userMap.put(user.getUserId(), user);

        user = new User();
        user.setUserId("3");
        user.setUsername("wangwu");
        user.setAge("40");
        user.setUpdateTime(new Date());
        userMap.put(user.getUserId(), user);
    }

    @Override
    public String getName(String userId) {
        return "id-" + userId;
    }
    @Override
    public User getUser(String userId) {
        User user = userMap.get(userId);
        return user;
    }

    @Override
    public ArrayList<User> getAllUser() {
        ArrayList<User> users = new ArrayList<>();
        userMap.forEach((key,value) -> {
            users.add(value);
        });
        return users;
    }
}

// 4.配置
@Configuration
public class WebServiceConfig {
    @Bean
    public ServletRegistrationBean dispatcherServlet() {
        return new ServletRegistrationBean(new CXFServlet(),"/services/*"); // 发布服务名称
    }

    @Bean(name = Bus.DEFAULT_BUS_ID)
    public Bus springBus() { // import org.apache.cxf.Bus;
        return new SpringBus(); // import org.apache.cxf.bus.spring.SpringBus;
    }

    @Bean
    public UserService userService() {
        return new UserServiceImpl();
    }

    @Bean
    public Endpoint endpoint() {
        EndpointImpl endpoint = new EndpointImpl(springBus(), userService()); // 绑定要发布的服务
        endpoint.publish("/user"); // 显示要发布的名称
        return endpoint;
    }
}
```

### 客户端

- 方式一: 生成客户端代码

```bash
## cxf(wsdl2java) 和 jdk(wsimport)都可生成，且调用方式一致
# jdk: -p指定包名
wsimport -s . -p com.example.service http://example.com/service?wsdl

# cxf
cd D:\java\apache-cxf-3.1.8\bin
wsdl2java -p cn.aezo.springboot.webservice.cxf.client.cxf -d D:\gitwork\springboot\webservice\src\main\java -encoding utf-8 -client http://localhost:8080/services/user?wsdl
```
- 调用

```java
// 注意: 如基于wsimport生成类进行调用时，实际请求的服务地址是根据wsdl的地址读取xml文件的地址，因此对于有代理或白名单的场景需要自定义服务端点地址(不读取wsdl中的原地址)
// cn.aezo.springboot.webservice.cxf.client.cxf
// 创建服务客户端
    // new UserServiceWeb(
    //     new URL("http://localhost:8080/services/user?wsdl"), // wsdlURL
    //     new QName("http://service.cxf.webservice.springboot.aezo.cn/", "UserServiceWeb") // SERVICE_NAME
    // );
UserServiceWeb service = new UserServiceWeb();
UserService port = service.getUserServiceImplPort();

// 调用 Web 服务方法
String username = port.getName("1");
System.out.println("====================>username = " + username); // id-1
```
- 方式二: 直接调用

```java
Service service = new Service(); // org.apache.axis.client.Service
Call call = (Call) service.createCall();
call.setTargetEndpointAddress("http://localhost:8080/services/user"); // 不需要?wsdl
AxisProperties.setProperty("axis.socketSecureFactory", "org.apache.axis.components.net.SunFakeTrustSocketFactory");// 跳过https证书校验
call.setOperationName("UserServiceWeb2");// WSDL里面描述的接口名称
call.addParameter("username", org.apache.axis.encoding.XMLType.XSD_DATE, javax.xml.rpc.ParameterMode.IN);// 接口的参数
call.addParameter("password", org.apache.axis.encoding.XMLType.XSD_DATE, javax.xml.rpc.ParameterMode.IN);// 接口的参数
call.setReturnType(org.apache.axis.encoding.XMLType.XSD_STRING);// 设置返回类型
call.setUseSOAPAction(true);
Object ret = call.invoke(new Object[] { eirbarcode, eirepEirId });
```


## OFBiz使用webservice

- 参考[ofbiz.md#webservice](/_posts/java/ofbiz/ofbiz.md#webservice)
