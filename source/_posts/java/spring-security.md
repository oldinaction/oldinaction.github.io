---
layout: "post"
title: "spring-security"
date: "2017-10-22 11:15"
categories: java
tags: [spring, springsecurity, springboot, oauth2]
---

## 简介

- 官网：[http://projects.spring.io/spring-security/](http://projects.spring.io/spring-security/)
- 文档：[V4.2.3](https://docs.spring.io/spring-security/site/docs/4.2.3.RELEASE/reference/htmlsingle/)

### spring security实现方法 [^1]

- 总共有四种用法，从简到深为
    - 不用数据库，全部数据写在配置文件，这个也是官方文档里面的demo
    - 使用数据库，根据spring security默认实现代码设计数据库，也就是说数据库已经固定了，这种方法不灵活，而且那个数据库设计得很简陋，实用性差
    - spring security和Acegi不同，它不能修改默认filter了，但支持插入filter，所以根据这个，我们可以插入自己的filter来灵活使用**（可基于此数据库结构进行自定义参数认证）**
    - 暴力手段，修改源码，前面说的修改默认filter只是修改配置文件以替换filter而已，这种是直接改了里面的源码，但是这种不符合OO设计原则，而且不实际，不可用

### 注意

- spring-security登录只能接受`x-www-form-urlencoded`(简单键值对)类型的数据，`form-data`(表单类型，可以含有文件)类型的请求获取不到参数值
- `axios`实现`x-www-form-urlencoded`请求：参数应该写到`param`中。如果写在`data`中则不行，加`headers: {'Content-Type': 'application/x-www-form-urlencoded'}`也不行

## springboot整合

- 引入依赖
    
    ```xml
    <!-- Spring-Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    ```

### 示例

- SpringSecurityConfig 访问权限规则设置

    ```java
    @Configuration
    public class SpringSecurityConfig extends WebSecurityConfigurerAdapter {

        @Autowired
        private AccessDeniedHandler accessDeniedHandler;

        @Autowired
        public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
            auth.inMemoryAuthentication()
                .withUser("admin").password("admin").roles("ADMIN") // 在内存中定义用户名密码为admin/admin, 角色为ADMIN的用户(用于登录和权限判断)
                .and()
                .withUser("user").password("user").roles("USER");
        }

        // 定义权限规则
        @Override
        protected void configure(HttpSecurity http) throws Exception {
            http.headers().frameOptions().disable(); // 解决spring boot项目中出现不能加载iframe
            http.csrf().disable() // 关闭打开的csrf(跨站请求伪造)保护
                .authorizeRequests()
                    .antMatchers("/manage/", "/manage/home", "/manage/about", "/manage/404", "/manage/403", "/thymeleaf/**").permitAll() // 这些端点不进行权限验证
                    .antMatchers("/resources/**").permitAll() // idea的resources/static目录下的文件夹对应一个端点，相当于可以访问resources/static/resources/下所有文件（还有一些默认的端点：/css/**、/js/**、/images/**、/webjars/**、/**/favicon.ico）
                    .antMatchers("/manage/**").hasAnyRole("ADMIN") // 需要有ADMIN角色才可访问/admin
                    .antMatchers("/user/**").hasAnyRole("USER", "ADMIN") // 有USER/ADMIN角色均可
                    .anyRequest().authenticated() // (除上述忽略请求)所有的请求都需要权限认证
                    .and()
                .formLogin()
                    .loginPage("/manage/login").permitAll() // 登录界面(Get)和登录处理方法(Post。具体逻辑不需要写，并且会自动生成此端点的control). 登录成功后，如果从登录界面登录则跳到项目主页(http://localhost:9526)，如果从其他页面跳转到登录页面进行登录则成功后跳转到原始页面
                    .and()
                .logout().permitAll() // 默认访问/logout(Get)即可登出
                    .and()
                .exceptionHandling().accessDeniedHandler(accessDeniedHandler);
        }
    }
    ```
- AccessDeniedHandler访问受限拦截

    ```java
    @Component
    public class MyAccessDeniedHandler implements AccessDeniedHandler {

        private static Logger logger = LoggerFactory.getLogger(MyAccessDeniedHandler.class);

        @Override
        public void handle(HttpServletRequest httpServletRequest,
                        HttpServletResponse httpServletResponse,
                        AccessDeniedException e) throws IOException, ServletException {

            Authentication auth = SecurityContextHolder.getContext().getAuthentication();

            if (auth != null) {
                logger.info("用户 '" + auth.getName() + "' 试图访问受保护的 URL: " + httpServletRequest.getRequestURI());
            }

            System.out.println("auth = " + auth);
            httpServletResponse.sendRedirect("/manage/403"); // 跳转到403页面
        }
    }
    ```
### 示例扩展

- 此示例使用数据库用户名/密码(或扩展验证)进行用户登录验证，并且对登录成功做处理，资源权限控制
- SpringSecurityConfig 访问权限规则设置

    ```java
    @EnableGlobalMethodSecurity(prePostEnabled=true) // 开启方法级别权限控制
    public class SpringSecurityConfig extends WebSecurityConfigurerAdapter {
        public static final String Login_Uri = "/manage/login";

        @Autowired
        private CustomAuthenticationProvider authProvider; // 提供认证算法(判断是否登录成功)(1)

        @Autowired
        private AuthenticationDetailsSource<HttpServletRequest, WebAuthenticationDetails> authenticationDetailsSource; // 认证信息

        @Autowired
        private AuthenticationSuccessHandler authenticationSuccessHandler; // 用于处理登录成功(2)

        @Autowired
        private AuthenticationFailureHandler authenticationFailureHandler; // 用于处理登录失败(2)

        @Autowired
        private AccessDeniedHandler accessDeniedHandler; // 用于处理无权访问 (3)

        @Autowired
        private JwtAuthenticationFilter jwtAuthenticationFilter; // 用于基于token的验证，如果基于session的则可去掉 (4)

        @Autowired
        public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
            auth.authenticationProvider(authProvider);
        }

        // 定义权限规则
        @Override
        protected void configure(HttpSecurity http) throws Exception {
            // 用于基于token的验证，如果基于session的则可去掉 (4)
            http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class); // 所有的请求都会先走此拦截器

            http.headers().frameOptions().disable(); // 解决spring boot项目中出现不能加载iframe
            http.csrf().disable() // 关闭打开的csrf(跨站请求伪造)保护
                .authorizeRequests()
                    .antMatchers("/manage/", "/manage/home", "/manage/about", "/manage/404", "/manage/403", "/thymeleaf/**").permitAll() // 这些端点不进行权限验证
                    .antMatchers("/resources/**").permitAll() // idea的resources/static目录下的文件夹对应一个端点，相当于可以访问resources/static/resources/下所有文件（还有一些默认的端点：/css/**、/js/**、/images/**、/webjars/**、/**/favicon.ico）
                    .antMatchers("/manage/**").hasAnyRole("ADMIN") // 需要有ADMIN角色才可访问/admin（有先后顺序，前面先定义的优先级高，因此比antMatchers("/**").hasAnyRole("USER", "ADMIN")优先级高）
                    .antMatchers("/**").hasAnyRole("USER", "ADMIN") // 有USER/ADMIN角色均可
                    .anyRequest().authenticated() // (除上述忽略请求)所有的请求都需要权限认证
                    .and()
                .formLogin()
                    .loginPage(Login_Uri).permitAll() // 登录界面(Get)
                    // .loginProcessingUrl(Login_Uri) // 或者通配符/**/login拦截对"/manage/login"和"/login"等的POST请求(登录请求。具体逻辑不需要写，并且会自动生成此端点的control。不写则和loginPage端点一致)
                    .successHandler(authenticationSuccessHandler) // 此处定义登录成功处理方法
                    .failureHandler(authenticationFailureHandler)
                    .authenticationDetailsSource(authenticationDetailsSource)
                    .and()
                .logout().logoutUrl("/manage/logout").logoutSuccessUrl(Login_Uri).permitAll() // 访问"/manage/logout"登出，登出成功后跳转到"/manage/login"
                    .and()
                .exceptionHandling().accessDeniedHandler(accessDeniedHandler);
        }

        // 密码加密器 (5)
        @Bean
        public PasswordEncoder passwordEncoder() {
            return new BCryptPasswordEncoder();
        }

        // 加密混淆器
        @Bean
        public SaltSource saltSource() {
            return new CustomSaltSource();
        }

        // 混淆器实现
        private class CustomSaltSource implements SaltSource {
            @Override
            public Object getSalt(UserDetails userDetails) {
                return "aezocn";
            }
        }
    }
    ```
- 自定义登录认证字段(spring security默认基于username/password完成)

    ```java
    public class CustomWebAuthenticationDetails extends WebAuthenticationDetails {
        private static final long serialVersionUID = 1L;
        private final String wxCode; // 此处为微信公众号使用微信code进行认证，也可扩展邮箱/手机号等

        public CustomWebAuthenticationDetails(HttpServletRequest request) {
            super(request);
            wxCode = request.getParameter("wxCode");
        }

        public String getWxCode() {
            return wxCode;
        }

        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append(super.toString()).append("; wxCode: ").append(this.getWxCode());
            return sb.toString();
        }
    }
    ```
- 将自定义登录认证字段加入到认证数据源

    ```java
    @Component
    public class CustomAuthenticationDetailsSource implements AuthenticationDetailsSource<HttpServletRequest, WebAuthenticationDetails> {

        @Override
        public WebAuthenticationDetails buildDetails(HttpServletRequest context) {
            return new CustomWebAuthenticationDetails(context);
        }
    }
    ```
- 根据用户唯一字段(如username、wxCode)获取用户信息

    ```java
    @Component
    public class CustomUserDetailsService implements UserDetailsService {
        private final UserDao userDao;

        @Autowired
        public CustomUserDetailsService(UserDao userDao) {
            this.userDao = userDao;
        }

        // 根据自定义登录认证字段获取用户信息。此处简化微信公众号认证(原本需要先拿到openid)
        public UserDetails loadUserByWxCode(String wxCode)
                throws UsernameNotFoundException {
            if(wxCode == null || "".equals(wxCode)) {
                throw new UsernameNotFoundException("invalid wxCode " + wxCode);
            }

            User user = userDao.findByWxCode(wxCode);
            if(user == null) {
                throw new UsernameNotFoundException("Could not find user, user wxCode " + wxCode);
            }
            return new CustomUserDetails(user);
        }

        // 默认根据username(唯一)获取用户信息
        @Override
        public UserDetails loadUserByUsername(String username)
                throws UsernameNotFoundException {
            if(username == null || "".equals(username)) {
                throw new UsernameNotFoundException("invalid username " + username);
            }

            User user = userDao.findByUsername(username);
            if(user == null) {
                throw new UsernameNotFoundException("Could not find user " + username);
            }
            return new CustomUserDetails(user);
        }

        /**
        * 自定义用户认证Model
        */
        private final static class CustomUserDetails extends User implements UserDetails {
            private CustomUserDetails(User user) {
                // 初始化父类，需要父类有User(User user){...}的构造方法
                super(user);

                // 或者在此处初始化
                // this.setUsername(user.getUsername());
                // this.setPassword(user.getPassword());
                // ...
            }

            @Override
            public Collection<? extends GrantedAuthority> getAuthorities() {
                // 组成如：ROLE_ADMIN/ROLE_USER，在资源权限定义时写法如：hasRole('ADMIN')。createAuthorityList接受一个数组，说明支持一个用户拥有多个角色
                // 此处使用直接在User表中加了一个字段roleCode，实际项目中可以新建一个 user_role 和 role_permission 表，此处去权限的code即可（用户和角色多对多，角色和权限多对多）
                return AuthorityUtils.createAuthorityList("ROLE_" + this.getRoleCode());
            }

            @Override
            public boolean isAccountNonExpired() {
                return true;
            }

            @Override
            public boolean isAccountNonLocked() {
                return true;
            }

            @Override
            public boolean isCredentialsNonExpired() {
                return true;
            }

            @Override
            public boolean isEnabled() {
                return true;
            }

            private static final long serialVersionUID = 5639683223516504866L;
        }
    }
    ```
- (1) 基于自定义登录认证字段，提供登录算法(返回认证对象Authentication)

    ```java
    @Component
    public class CustomAuthenticationProvider implements AuthenticationProvider {
        @Autowired
        private CustomUserDetailsService customUserDetailsService;

        @Autowired
        private PasswordEncoder passwordEncoder;

        public CustomAuthenticationProvider() {
            super();
        }

        @Override
        public Authentication authenticate(final Authentication authentication) throws AuthenticationException {
            CustomWebAuthenticationDetails details = (CustomWebAuthenticationDetails) authentication.getDetails();

            final String wxCode = details.getWxCode();

            final String username = authentication.getName();
            final String password = authentication.getCredentials().toString();

            UserDetails userDetails = null;
            if(!StringUtils.isEmpty(username) && !StringUtils.isEmpty(password)) {
                userDetails = customUserDetailsService.loadUserByUsername(username);
                    
                // 验证密码
                if(userDetails == null || userDetails.getPassword() == null) {
                    throw new BadCredentialsException("invalid password");
                }
                if(!passwordEncoder.matches(password, userDetails.getPassword())) {
                    throw new BadCredentialsException("wrong password");
                }
            } else if(!StringUtils.isEmpty(wxCode)) {
                userDetails = customUserDetailsService.loadUserByWxCode(wxCode);
            } else {
                throw new BadCredentialsException("invalid params: username,password and wxCode are invalid");
            }

            if(userDetails != null) {
                // 授权
                final List<GrantedAuthority> grantedAuths = (List<GrantedAuthority>) userDetails.getAuthorities();
                final Authentication auth = new UsernamePasswordAuthenticationToken(userDetails, password, grantedAuths);
                return auth;
            }

            return null;
        }

        @Override
        public boolean supports(final Class<?> authentication) {
            return authentication.equals(UsernamePasswordAuthenticationToken.class);
        }
    }
    ```
    - 上述抛出异常AuthenticationException会被下面的MyAuthenticationFailureHandler类捕获。提供的AuthenticationException有：
        - `UsernameNotFoundException` 用户找不到
        - `BadCredentialsException` 无效的凭据
        - `AccountStatusException` 用户状态异常它包含如下子类
            - `AccountExpiredException` 账户过期
            - `LockedException` 账户锁定
            - `DisabledException` 账户不可用
            - `CredentialsExpiredException` 证书过期
- (2) 登录校验完成拦截：登录成功/失败处理

    ```java
    @Component
    public class LoginFinishHandler {
        private Logger logger = LoggerFactory.getLogger(LoginFinishHandler.class);

        @Component
        public class MyAuthenticationSuccessHandler implements AuthenticationSuccessHandler {
            @Override
            public void onAuthenticationSuccess(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, Authentication authentication) throws IOException, ServletException {
                CustomWebAuthenticationDetails details = (CustomWebAuthenticationDetails) authentication.getDetails();
                String wxCode = details.getWxCode();

                HttpSession session = httpServletRequest.getSession();
                User user = (User) authentication.getPrincipal();
                session.setAttribute("SESSION_USER_INFO", user);

                logger.info("{} 登录成功", user.getUsername());
            }
        }

        @Component
        public class MyAuthenticationFailureHandler extends SimpleUrlAuthenticationFailureHandler {
            @Override
            public void onAuthenticationFailure(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, AuthenticationException e) throws IOException, ServletException {
                logger.info("登录失败：" + e.getMessage());
            }
        }
    }
    ```
- (3) AccessDeniedHandler访问受限拦截同上例
- (4) token验证(基于session的验证可以不加此拦截器，基于无状态的Restful则需要拦截token并解析获得用户名和相关权限。配置文件加`security.sessions=stateless`时spring security才不会使用session)

    ```java
    @Component
    public class JwtAuthenticationFilter extends OncePerRequestFilter {

        private String token_header = "X-Token";

        @Resource
        private SecurityJwtTokenUtils securityJwtTokenUtils; // 基于JWT的工具类：用于生成和解析JWT机制的token

        @Override
        protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
            // TODO
            if(!SpringSecurityConfig.Login_Uri.equals(request.getRequestURI())) {
                String authToken = request.getHeader(this.token_header);
                if(StringUtils.isEmpty(authToken)) {
                    throw new ExceptionU.AuthTokenInvalidException();
                }

                try {
                    String username = securityJwtTokenUtils.getUsernameFromToken(authToken);
                    if(username == null)
                        throw new ExceptionU.AuthTokenInvalidException();
                    logger.info(String.format("Checking authentication for user %s.", username));

                    if (SecurityContextHolder.getContext().getAuthentication() == null) {
                        // It is not compelling necessary to load the use details from the database. You could also store the information
                        // in the token and read it from it. It's up to you ;)
                        // UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);
                        UserDetails userDetails = securityJwtTokenUtils.getUserFromToken(authToken);

                        // For simple validation it is completely sufficient to just check the token integrity. You don't have to call
                        // the database compellingly. Again it's up to you ;)
                        if (securityJwtTokenUtils.validateToken(authToken, userDetails)) {
                            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                            logger.info(String.format("Authenticated user %s, setting security context", username));
                            SecurityContextHolder.getContext().setAuthentication(authentication);
                        }
                    }
                } catch (SignatureException e) {
                    throw new ExceptionU.AuthTokenInvalidException();
                }
            }

            chain.doFilter(request, response);
        }
    }
    ```
- (5) 密码保存
    
    ```java
    // PasswordEncoder passwordEncoder = new BCryptPasswordEncoder(16);
    PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // 保存密码(smalle)：$2a$10$j5daLww7/c4Qdj1U30Djt.Mzh0pDdYtOrlJ3zQ91u4IC/no2bcViG
    String password = passwordEncoder.encode("smalle");
    System.out.println("password = " + password);

    Assert.assertTrue(passwordEncoder.matches("smalle", password));
    ```

### 在方法(资源)上加权限控制

- 需要权限配置类上加注解`@EnableGlobalMethodSecurity(prePostEnabled=true)`，标识开启方法级别prePostEnabled权限控制，还可以开启其他控制
- 使用

    ```java
    // Controller.java
    // @PreAuthorize("hasRole('ADMIN')") // 可使用自定义注解@HasAdminRole进行封装(可组合更复杂的权限注解)
    @HasAdminRole
    @GetMapping("/adminRole")
    public String adminRole() {
        return "/adminRole";
    }

    // HasAdminRole.java
    // 自定义权限注解，被@HasAdminRole注解的方法需要有ADMIN角色
    @Retention(RetentionPolicy.RUNTIME)
    @PreAuthorize("hasRole('ADMIN')")
    public @interface HasAdminRole {
    }
    ```
- 更多权限控制说明：https://docs.spring.io/spring-security/site/docs/4.2.3.RELEASE/reference/htmlsingle/#jc-authentication

### CSRF、CORS

- `CSRF` 跨站请求伪造(Cross-Site Request Forgery). [csrf](https://docs.spring.io/spring-security/site/docs/4.2.x/reference/html/csrf.html)
- `CORS` 跨站资源共享(Cross Origin Resourse-Sharing).

- 开启cosr [cors](https://docs.spring.io/spring-security/site/docs/4.2.x/reference/html/cors.html)

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

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
    ```

## spring security oauth2 [^2]

- [理解Oauth 2.0-阮一峰](http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)
- oauth2根据使用场景不同，分成了4种模式
    - 授权码模式（authorization code）：授权码模式使用到了回调地址，是最为复杂的方式，通常网站中经常出现的微博，qq第三方登录，都会采用这个形式
    - 简化模式（implicit）：不常用
    - 密码模式（resource owner password credentials）：password模式，自己本身有一套用户体系，在认证时需要带上自己的用户名和密码，以及客户端的client_id,client_secret。此时，access_token所包含的权限是用户本身的权限，而不是客户端的权限。
    - 客户端模式（client credentials）：client模式，没有用户的概念，直接与认证服务器交互，用配置中的客户端信息去申请access_token，客户端有自己的client_id,client_secret对应于用户的username,password，而客户端也拥有自己的authorities，当采取client模式认证时，对应的权限也就是客户端自己的authorities。

### 客户端模式和密码模式

> 源码参考 spring-security-oauth2 -> oauth2-client-password

- 依赖

```xml
<!-- 不是starter,手动配置 -->
<dependency>
    <groupId>org.springframework.security.oauth</groupId>
    <artifactId>spring-security-oauth2</artifactId>
    <version>2.3.2.RELEASE</version>
</dependency>

<!-- 将token存储在redis中(存储在内存中则不需要) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

- 认证服务器和资源服务器配置（认证服务器基于Spring Security验证用户名/密码的配置省略）

```java
@Configuration
public class OAuth2ServerConfig {

    private static final String DEMO_RESOURCE_ID = "order";

    // 资源服务器配置
    @Configuration
    @EnableResourceServer
    protected static class ResourceServerConfiguration extends ResourceServerConfigurerAdapter {
        @Override
        public void configure(ResourceServerSecurityConfigurer resources) {
            resources.resourceId(DEMO_RESOURCE_ID).stateless(true);
        }

        // 将路径为/order/**的资源标识为order资源(资源ID)
        @Override
        public void configure(HttpSecurity http) throws Exception {
            http.authorizeRequests()
                .antMatchers("/order/**").authenticated(); // 配置order访问控制，必须认证过后才可以访问
        }
    }

    // 认证服务器配置(一般和资源服务器配置处于不同的项目)
    @Configuration
    @EnableAuthorizationServer
    protected static class AuthorizationServerConfiguration extends AuthorizationServerConfigurerAdapter {
        @Autowired
        AuthenticationManager authenticationManager;

        @Autowired
        RedisConnectionFactory redisConnectionFactory;

        @Override
        public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
            String finalSecret = "{bcrypt}" + new BCryptPasswordEncoder().encode("123456"); // 测试用户的密码
            // 配置两个客户端,一个用于password认证一个用于client认证
            clients.inMemory()
                    // 基于client认证
                    .withClient("client_1")
                    .resourceIds(DEMO_RESOURCE_ID)
                    .authorizedGrantTypes("client_credentials", "refresh_token")
                    .scopes("select")
                    .authorities("oauth2")
                    .secret(finalSecret)
                    .and()
                    // 基于password认证
                    .withClient("client_2")
                    .resourceIds(DEMO_RESOURCE_ID)
                    .authorizedGrantTypes("password", "refresh_token")
                    .scopes("select")
                    .authorities("oauth2")
                    .secret(finalSecret);
        }

        @Bean
        public TokenStore tokenStore() {
            // token保存在内存
            return new InMemoryTokenStore();

            // 需要使用 redis 的话，放开这里
            // return new RedisTokenStore(redisConnectionFactory);
        }

        @Override
        public void configure(AuthorizationServerEndpointsConfigurer endpoints) {
            endpoints
                    .tokenStore(tokenStore())
                    .authenticationManager(authenticationManager)
                    .allowedTokenEndpointRequestMethods(HttpMethod.GET, HttpMethod.POST); // 允许的请求类型
        }

        @Override
        public void configure(AuthorizationServerSecurityConfigurer oauthServer) {
            //允许表单认证
            oauthServer.allowFormAuthenticationForClients();
        }

    }
}
```
- 资源`@GetMapping("/product/{id}")`和`@GetMapping("/order/{id}")`的定义省略
- 访问

```java
// 客户端模式（client credentials）
// 请求：http://localhost:8080/oauth/token?grant_type=client_credentials&scope=select&client_id=client_1&client_secret=123456
// 响应：{"access_token":"b7236239-7dee-404d-9e7d-14a035052be9","token_type":"bearer","expires_in":43196,"scope":"select"}
// 请求资源：http://localhost:8080/order/1?access_token=b7236239-7dee-404d-9e7d-14a035052be9

// 密码模式（resource owner password credentials）
// 请求：http://localhost:8080/oauth/token?username=user_1&password=123456&grant_type=password&scope=select&client_id=client_2&client_secret=123456
// 响应：{"access_token":"e3b3083b-2afb-452a-9a5c-7349833c447f","token_type":"bearer","refresh_token":"8faf5956-4113-4192-a660-b62835707a1f","expires_in":43181,"scope":"select"}
// 请求资源：http://localhost:8080/order/1?access_token=e3b3083b-2afb-452a-9a5c-7349833c447f
```

### 授权码模式

#### 授权服务器

> 源码参考 spring-security-oauth2 -> oauth2-authorization-code -> oauth2-authorization-code-qq

- 依赖

```xml
<dependency>
    <groupId>org.springframework.security.oauth</groupId>
    <artifactId>spring-security-oauth2</artifactId>
    <version>2.3.2.RELEASE</version>
</dependency>

<!-- 将token存储在redis中(存储在内存中则不需要) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```
- 认证服务器配置（其他和基本类似）

```java
@Override
public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
    clients.inMemory()
            .withClient("aiqiyi") // app_id
            .resourceIds(QQ_RESOURCE_ID)
            .authorizedGrantTypes("authorization_code", "refresh_token", "implicit") // 授权码模式
            .authorities("ROLE_CLIENT")
            .scopes("get_user_info", "get_fanslist") // 授权范围
            .secret("my-secret-888888") // app_secret
            .redirectUris("http://localhost:9090/aiqiyi/qq/redirect") // 重定向地址
            .autoApprove(true)
            .autoApprove("get_user_info")
            .and()
            .withClient("youku")
            .resourceIds(QQ_RESOURCE_ID)
            .authorizedGrantTypes("authorization_code", "refresh_token", "implicit")
            .authorities("ROLE_CLIENT")
            .scopes("get_user_info", "get_fanslist")
            .secret("secret")
            .redirectUris("http://localhost:9090/youku/qq/redirect");
}
```

#### 客户端

> 源码参考 spring-security-oauth2 -> oauth2-authorization-code -> oauth2-authorization-code-aiqiyi

- 获取token

```java
@Autowired
RestTemplate restTemplate;

@RequestMapping("/aiqiyi/qq/redirect")
public String getToken(@RequestParam String code){
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
    MultiValueMap<String, String> params= new LinkedMultiValueMap<>();
    params.add("grant_type","authorization_code");
    params.add("code",code);
    params.add("client_id","aiqiyi");
    params.add("client_secret","my-secret-888888");
    params.add("redirect_uri","http://localhost:9090/aiqiyi/qq/redirect"); // 此时地址必须和请求认证的回调地址一模一样
    HttpEntity<MultiValueMap<String, String>> requestEntity = new HttpEntity<>(params, headers);
    
    ResponseEntity<String> response = restTemplate.postForEntity("http://localhost:8080/oauth/token", requestEntity, String.class);
    String token = response.getBody();

    return token;
}
```

#### 访问资源

- 访问授权服务器：`http://localhost:8080/oauth/authorize?client_id=aiqiyi&response_type=code&redirect_uri=http://localhost:9090/aiqiyi/qq/redirect`
- 浏览器跳转到授权服务器登录页面：`http://localhost:8080/login`
- 认证通过，获取到授权码，认证服务器重定向到：`http://localhost:9090/aiqiyi/qq/redirect?code=TLFxg1` (进入客户端后台服务)
- 客户端服务请求认证服务器获取token：`http://localhost:8080/oauth/token`
- 获取token成功：{"access_token":"3b017a2d-3e3d-4536-b978-d3d8e05f4b05","token_type":"bearer","refresh_token":"4593b664-9107-404f-8e77-2073515b42c9","expires_in":43199,"scope":"get_user_info get_fanslist"}
- 浏览器地址变为：`http://localhost:9090/aiqiyi/qq/redirect?code=TLFxg1`
- 携带 access_token 访问资源服务器：`http://localhost:8080/qq/info/123456?access_token=3b017a2d-3e3d-4536-b978-d3d8e05f4b05`

#### 第三方登录自动配置

> 源码参考 spring-security-oauth2 -> oauth2-authorization-code -> oauth2-authorization-code-qq oauth2-authorization-code-aiqiyi客户端)


---

参考文章

[^1]: http://www.importnew.com/20612.html (spring-security的原理及教程)
[^2]: https://github.com/lexburner/oauth2-demo (Spring Security Oauth2)