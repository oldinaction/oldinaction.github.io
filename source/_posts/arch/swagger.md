---
layout: "post"
title: "swagger"
date: "2018-09-23 18:41"
categories: arch
tags: [doc, api, springboot]
---

## 简介

swagger是一个前后端api统一文档和测试框架。不仅是一个api文档，还可以测试API(可直接访问UI界面)

## springboot中使用

> TODO https://www.baeldung.com/swagger-2-documentation-for-spring-rest-api 权限认证

- 添加依赖

```xml
<!--Swagger API文档：https://github.com/springfox/springfox -->
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>2.9.2</version>
</dependency>
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>2.9.2</version>
</dependency>
```

- 配置

```yml
# Swagger文档界面信息配置
swagger:
  title: API接口文档标题
  description: API接口文档描述
  version: 1.0.0
  termsOfServiceUrl: http://blog.aezo.cn
  contact:
    name: smalle
    url: http://blog.aezo.cn
    email: admin@aezo.cn
```

```java
@Configuration
@EnableSwagger2
public class Swagger2Config {
    @Value("${swagger.title}")
    private String title;

    @Value("${swagger.description}")
    private String description;

    @Value("${swagger.version}")
    private String version;

    @Value("${swagger.termsOfServiceUrl}")
    private String termsOfServiceUrl;

    @Value("${swagger.contact.name}")
    private String name;

    @Value("${swagger.contact.url}")
    private String url;

    @Value("${swagger.contact.email}")
    private String email;

    @Bean
    public Docket api() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo()).select()
                //扫描所有有注解的api
                .apis(RequestHandlerSelectors.withMethodAnnotation(ApiOperation.class))
                // .apis(RequestHandlerSelectors.basePackage("cn.aezo.controller")) // 基于包名扫描
                .paths(PathSelectors.any())
                .build();
                // .pathMapping("/v2"); // 在这里可以设置请求的统一前缀
    }

    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
                .title(title)
                .description(description)
                .termsOfServiceUrl(termsOfServiceUrl)
                .contact(new Contact(name, url, email))
                .version(version)
                .build();
    }
}
```
- 注解

```java
// 查看接口文档及在线测试：http://localhost:8080/swagger-ui.html
@RestController
@RequestMapping("/users")
@Api(description = "用户管理") // 可选参数tags=""(默认类名转中划线)
public class UserController {

    private static final Logger log = LoggerFactory.getLogger(UserController.class);

    @RequestMapping(value = "/test", method = RequestMethod.GET) // 如果此处不写method = RequestMethod.GET则会生成每种类型的api文档
    @ApiOperation(value = "最简配置文档注释（DONE）")
    public String test(String param) {
        return "hello swagger";
    }

    // 多个参数用 @ApiImplicitParams
    @GetMapping
    @ApiOperation(value = "条件查询（DONE）")
    @ApiImplicitParams({
            @ApiImplicitParam(name = "username", value = "用户名"),
            @ApiImplicitParam(name = "password", value = "密码"),
    })
    public User query(String username, String password) {
        return new User(1L, username, password);
    }

    // 单个参数用 ApiImplicitParam
    @DeleteMapping("/{id}")
    @ApiOperation(value = "删除用户（DONE）")
    @ApiImplicitParam(name = "id", value = "用户编号")
    public void delete(@PathVariable Long id) {}

    // 如果是 POST PUT 这种带 @RequestBody 的可以不用写 @ApiImplicitParam
    @PostMapping
    @ApiOperation(value = "添加用户（DONE）")
    public User post(@RequestBody User user) {
        return user;
    }

    // 省略 @ApiImplicitParam，那么 swagger 也会使用默认的参数名作为描述信息
    @PutMapping("/{id}")
    @ApiOperation(value = "修改用户（DONE）")
    public void put(@PathVariable Long id, @RequestBody User user) { }
}

// 注解实体（实体属性必须有getter/sertter方法）
// @ApiModel	用在返回对象类上
// @ApiModelProperty	用在出入参数对象的字段上
@ApiModel
public class User implements Serializable {
    private Long id;

    @ApiModelProperty("用户名")
    private String username;

    private String password;

    // ...省略get/set方法
}

```
- 访问`http://localhost:8080/swagger-ui.html` 查看接口文档

---

参考文章

[^1]: http://www.voidcn.com/article/p-oxjfzsib-brq.html
[^2]: https://www.cnblogs.com/softidea/p/6251249.html
[^3]: https://www.baeldung.com/swagger-2-documentation-for-spring-rest-api (Setting Up Swagger 2 with a Spring REST API)