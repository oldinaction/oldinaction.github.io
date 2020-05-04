---
layout: "post"
title: "SpringSecurity" 
date: "2017-10-22 11:15"
categories: java
tags: [spring, springsecurity, springboot, oauth2, 安全]
---

## 简介

- 官网：[http://projects.spring.io/spring-security/](http://projects.spring.io/spring-security/)
- 文档：[V4.2.3](https://docs.spring.io/spring-security/site/docs/4.2.3.RELEASE/reference/htmlsingle/)
- 开启日志(yml配置)：`logging.level.org.springframework.security: DEBUG`

### spring security实现方法 [^1]

- 总共有四种用法，从简到深为
    - 不用数据库，全部数据写在配置文件，这个也是官方文档里面的demo
    - 使用数据库，根据spring security默认实现代码设计数据库，也就是说数据库已经固定了，这种方法不灵活，而且那个数据库设计得很简陋，实用性差
    - spring security和Acegi不同，它不能修改默认filter了，但支持插入filter，所以根据这个，我们可以插入自己的filter来灵活使用 **（可基于此数据库结构进行自定义参数认证）**
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
                    .antMatchers("/res/**").permitAll() // idea的resources/static目录下的文件夹对应一个端点，相当于可以访问resources/static/res/下所有文件（还有一些默认的端点：/css/**、/js/**、/images/**、/webjars/**、/**/favicon.ico）
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
    public class SmAccessDeniedHandler implements AccessDeniedHandler {

        private static Logger logger = LoggerFactory.getLogger(SmAccessDeniedHandler.class);

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

        // spring security 4配置认证器
        // @Autowired
        // public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
        //     auth.authenticationProvider(authProvider);
        // }

        // 定义权限规则
        @Override
        protected void configure(HttpSecurity http) throws Exception {
            // 用于基于token的验证，如果基于session的则可去掉 (4)
            http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class); // 所有的请求都会先走此拦截器

            http.headers().frameOptions().disable(); // 解决spring boot项目中出现不能加载iframe
            http.csrf().disable() // 关闭打开的csrf(跨站请求伪造)保护
                .authorizeRequests()
                    .antMatchers("/favicon.ico", "/manage/", "/manage/index", "/manage/404", "/manage/403", "/thymeleaf/**").permitAll() // 这些端点不进行权限验证
                    .antMatchers("/res/**").permitAll() // idea的resources/static目录下的文件夹对应一个端点，相当于可以访问resources/static/res/下所有文件（还有一些默认的端点：/css/**、/js/**、/images/**、/webjars/**、/**/favicon.ico）
                    .antMatchers("/manage/**").hasAnyRole("ADMIN") // 需要有ADMIN角色才可访问/admin（有先后顺序，前面先定义的优先级高，因此比antMatchers("/**").hasAnyRole("USER", "ADMIN")优先级高）
                    .antMatchers("/**").hasAnyRole("USER", "ADMIN") // 有USER/ADMIN角色均可
                    .anyRequest().authenticated() // (除上述忽略请求)所有的请求都需要权限认证
                    .and()
                .authenticationProvider(authProvider) // spring security 5设置认证器
                .formLogin()
                    .loginPage(Login_Uri).permitAll() // 登录界面(Get)
                    // 或者通配符/**/login拦截对"/manage/login"和"/login"等的POST请求(登录请求。具体逻辑不需要写，并且会自动生成此端点的control。不写则和loginPage端点一致). 不包含server.servlet.context-path的路径
                    // .loginProcessingUrl(Login_Uri)
                    .successHandler(authenticationSuccessHandler) // 此处定义登录成功处理方法
                    .failureHandler(authenticationFailureHandler)
                    .authenticationDetailsSource(authenticationDetailsSource)
                    .and()
                .logout().logoutUrl("/manage/logout").logoutSuccessUrl(Login_Uri).permitAll() // 访问"/manage/logout"登出，登出成功后跳转到"/manage/login"
                    .and()
                .exceptionHandling()
                    .accessDeniedHandler(accessDeniedHandler)
                    // 默认未登录的请求会重定向到登录页面。如果项目仅提供API时，需直接返回错误数据
                    .authenticationEntryPoint((request, response, e) -> {
                        BaseController.writeError(response, "尚未认证");
                    });
        }

        // 密码加密器 (5)
        @Bean
        public PasswordEncoder passwordEncoder() {
            return new BCryptPasswordEncoder();
        }

        // spring security 4.1.1.RELEASE 中提供的 SaltSource
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
        * 自定义用户认证Model。此处的User为开发者自定义的User(非Spring Security内置User)
        */
        private final static class CustomUserDetails extends User implements UserDetails {
            private CustomUserDetails(User user) {
                // 初始化父类，需要父类有User(User user){...}的构造方法
                super(user); // BeanUtils.copyProperties(user, this);

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

                httpServletResponse.sendRedirect("/manage/403");

                //BaseController.writeSuccess(httpServletResponse, "登录成功", MiscU.Instance.toMap(
                //    BaseKeys.AccessToken, accessToken,
                //    BaseKeys.RefreshToken, refreshToken,
                //    "user_id", userDetails.getUserId(),
                //    "username", userDetails.getUsername(),
                //    "role_codes", userDetails.getRoleCodes(),
                //));
            }
        }

        @Component
        public class MyAuthenticationFailureHandler extends SimpleUrlAuthenticationFailureHandler {
            @Override
            public void onAuthenticationFailure(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, AuthenticationException e) throws IOException, ServletException {
                logger.info("登录失败：" + e.getMessage());

                httpServletResponse.sendRedirect("/manage/login");
                // BaseController.writeError(httpServletResponse, e.getMessage());
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
                    // throw new ExceptionU.AuthTokenInvalidException(); // 这样会导致SpringSecurity公开路径无法访问。此时不进行获取认证对象，由后面拦截访问私有路径的
                    chain.doFilter(request, response);
                    return;
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
    - 授权码模式(authorization code)：授权码模式使用到了回调地址，是最为复杂的方式，通常网站中经常出现的微博，qq第三方登录，都会采用这个形式
        - 用户访问客户端，后者将前者导向认证服务器
        - 用户选择是否给予客户端授权
        - 假设用户给予授权，认证服务器将用户导向客户端事先指定的"重定向URI"（redirection URI），同时附上一个授权码
        - 客户端收到授权码，附上早先的"重定向URI"，向认证服务器申请令牌。这一步是在客户端的后台的服务器上完成的，对用户不可见
        - 认证服务器核对了授权码和重定向URI，确认无误后，向客户端发送访问令牌（access token）和更新令牌（refresh token）
    - 简化模式(implicit)：不常用
    - 密码模式(resource owner password credentials)：在这种模式中，用户必须把自己的密码(认证服务器的用户)给客户端，但是客户端不得储存密码。这通常用在用户对客户端高度信任的情况下，比如客户端是操作系统的一部分。在认证时客户端需要使用用户提供的用户名、密码，以及客户端的client_id,client_secret向认证服务器请求。此时返回的access_token所包含的权限是用户本身的权限，而不是客户端的权限
        - 用户向客户端提供用户名和密码
        - 客户端将用户名和密码发给认证服务器，向后者请求令牌
        - 认证服务器确认无误后，向客户端提供访问令牌
    - 客户端模式(client credentials)：client模式，没有用户的概念，直接与认证服务器交互，用配置中的客户端信息去申请access_token，客户端有自己的client_id,client_secret对应于用户的username,password，而客户端也拥有自己的authorities，当采取client模式认证时，对应的权限也就是客户端自己的authorities
        - 客户端向认证服务器进行身份认证，并要求一个访问令牌
        - 认证服务器确认无误后，向客户端提供访问令牌
- 相关角色划分
    - 资源(如：用户信息)
    - 资源所有者(最终用户，拥有个人用户信息的人)
    - 用户代理(如：浏览器)
    - 授权服务器
    - 资源服务器(无需在认证服务器上注册。如：服务商托管用户信息)
        - 要访问资源服务器受保护的资源需要携带令牌(从授权服务器获得)
        - 客户端往往同时也是一个资源服务器，各个服务之间的通信(访问需要权限的资源)时需携带访问令牌
        - 资源服务器通过 `@EnableResourceServer` 注解来开启一个 `OAuth2AuthenticationProcessingFilter` 类型的过滤器
        - 通过继承 `ResourceServerConfigurerAdapter` 类来配置资源服务器
    - 客户端(需要在认证服务器上注册。如：第三方应用程序)
        - 可自行编写登录逻辑(获取令牌->获取用户信息)
        - 也可使用 OAuth2 提供的 `@EnableOAuth2Sso` 注解实现单点登录，该注解会添加身份验证过滤器替我们完成所有操作，只需在配置文件里添加授权服务器和资源服务器的配置即可
    - spring cloud结合oauth2网关角色 [^4]
        - `@EnableResourceServer` 网关充当资源服务器拦截请求，下游服务无需开启oauth验证(网关不对认证服务器相关端点验证)。弊端：资源服务器某些端点无需认证则需要统一在网关处配置
        - `@EnableOAuth2Sso` 网关充当客户端，下游服务也以客户端或资源服务器进行认证。(单点登录必须保证客户端和授权服务器的hostname不同或者SESSIONID名称不同)
- 授权服务器
    - 一些默认的端点URL(TokenEndpoint、AuthorizationEndpoint)
        - `/oauth/authorize` 授权端点
        - `/oauth/token` 令牌端点
        - `/oauth/confirm_access` 用户确认授权提交端点
        - `/oauth/error` 授权服务错误信息端点
        - `/oauth/check_token` 用于资源服务访问的令牌解析端点
        - `/oauth/token_key` 提供公有密匙的端点，如果你使用JWT令牌的话
    - 授权类型（Grant Types）：授权是使用 AuthorizationEndpoint 这个端点来进行控制的，使用 `AuthorizationServerEndpointsConfigurer` 这个对象实例来进行配置，默认是支持除了密码授权外所有标准授权类型，它可配置以下属性
        - authenticationManager：认证管理器，当你选择了资源所有者密码（password）授权类型的时候，请设置这个属性注入一个 AuthenticationManager 对象
        - userDetailsService：可定义自己的 UserDetailsService 接口实现
        - authorizationCodeServices：用来设置收取码服务的（即 AuthorizationCodeServices 的实例对象），主要用于 "authorization_code" 授权码类型模式
        - implicitGrantService：这个属性用于设置隐式授权模式，用来管理隐式授权模式的状态
        - tokenGranter：完全自定义授权服务实现（TokenGranter 接口实现），只有当标准的四种授权模式已无法满足需求时
    - 使用jwt令牌
        - 使用 JWT 令牌需要在授权服务中使用 `JWTTokenStore`，资源服务器也需要一个解码 Token 令牌的类 `JwtAccessTokenConverter`，JwtTokenStore 依赖这个类进行编码以及解码，因此授权服务以及资源服务都需要配置这个转换类
        - Token 令牌默认是有签名的，并且资源服务器中需要验证这个签名，因此需要一个对称的 Key 值，用来参与签名计算。这个 Key  值存在于授权服务和资源服务之中，或者使用非对称加密算法加密 Token 进行签名，Public Key 公布在 /oauth/token_key 这个 URL 中
        - 默认 /oauth/token_key 的访问安全规则是 "denyAll()" 即关闭的，可以注入一个标准的 SpingEL 表达式到 AuthorizationServerSecurityConfigurer 配置类中将它开启，例如 permitAll()
        - 需要引入 spring-security-jwt 库
- access_token获取(BearerTokenExtractor#extractToken)
    - 默认从header中获取，传入方式如：`Authorization: Bearer my_access_token_888`(POST时使用)
    - header中获取不到则通过`request.getParameter("access_token")`获取

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
- token存储在redis中时增加配置

```yml
# token保存在redis中需要开启
spring:
  redis:
    host: 127.0.0.1
    database: 0
```

- SpringSecurity Web配置

```java
@Configuration
@EnableWebSecurity
public class SecurityConfiguration extends WebSecurityConfigurerAdapter {
    // 这一步的配置是必不可少的，否则SpringBoot会自动配置一个AuthenticationManager
    // 方法名称不建议为authenticationManager(否则password模式获取token失败). https://github.com/spring-projects/spring-boot/issues/12395
    @Bean
    @Override
    public AuthenticationManager authenticationManager() throws Exception {
        AuthenticationManager manager = super.authenticationManagerBean();
        return manager;
    }

    // ... 其他类似 SpringSecurity Web配置
}
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

    // 认证服务器配置(一般和资源服务器配置处于不同的项目，如 spring-security-oauth2 -> consumer-movie-ribbon)
    @Configuration
    @EnableAuthorizationServer
    protected static class AuthorizationServerConfiguration extends AuthorizationServerConfigurerAdapter {
        @Autowired
        AuthenticationManager authenticationManager;

        @Autowired
        RedisConnectionFactory redisConnectionFactory;

        // 从数据库获取客户端配置
        // @Autowired
        // DataSource dataSource;
        //
        // @Bean
        // public ClientDetailsService clientDetails() {
        //     return new JdbcClientDetailsService(dataSource); // 管理客户端信息(自定创建)
        // }

        @Override
        public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
            // clients.withClientDetails(clientDetails()); // 从数据获取客户端配置

            String finalSecret = "{bcrypt}" + new BCryptPasswordEncoder().encode("my_client_secret"); // 客户端秘钥(必须经过加密)
            // 配置两个客户端,一个用于password认证一个用于client认证
            clients.inMemory()
                    // 基于client认证
                    .withClient("client_1")
                    .resourceIds(DEMO_RESOURCE_ID) // 不定义资源服务器路径(@EnableResourceServer)，则对应则默认为resourceId的值`/[resourceId]/**`
                    .authorizedGrantTypes("client_credentials", "refresh_token")
                    .scopes("select")
                    .authorities("oauth2")
                    .secret(finalSecret)
                    .and()
                    // 基于password认证
                    .withClient("client_2")
                    .resourceIds(DEMO_RESOURCE_ID) // .resourceIds(DEMO_RESOURCE_ID, DEMO_RESOURCE_ID2)
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

            // return new JdbcTokenStore(dataSource); // 存储在数据库
        }

        @Override
        public void configure(AuthorizationServerEndpointsConfigurer endpoints) {
            endpoints
                    .tokenStore(tokenStore())
                    .authenticationManager(authenticationManager)
                    .allowedTokenEndpointRequestMethods(HttpMethod.GET, HttpMethod.POST); // 允许获取token的请求类型
        }

        // 必须
        @Override
        public void configure(AuthorizationServerSecurityConfigurer oauthServer) {
            // 允许表单认证
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
// 请求资源：http://localhost:8080/order/1?access_token=b7236239-7dee-404d-9e7d-14a035052be9 (或者Header中加token，如：`Authorization: Bearer xxx`)

// 密码模式（resource owner password credentials）
// 请求：http://localhost:8080/oauth/token?username=user_1&password=123456&grant_type=password&scope=select&client_id=client_2&client_secret=123456
// 响应：{"access_token":"e3b3083b-2afb-452a-9a5c-7349833c447f","token_type":"bearer","refresh_token":"8faf5956-4113-4192-a660-b62835707a1f","expires_in":43181,"scope":"select"}
// 请求资源：http://localhost:8080/order/1?access_token=e3b3083b-2afb-452a-9a5c-7349833c447f
```

### 授权码模式

#### 授权服务器 [^6]

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
    // 基于内存存储客户端
    // 基于jdbc存储客户端，建表语句参考：https://github.com/spring-projects/spring-security-oauth/blob/master/spring-security-oauth2/src/test/resources/schema.sql(MYSQL:默认建表语句中主键为 Varchar(256)，这超过了最大的主键长度，可改成 128，并用 BLOB 替换语句中的 LONGVARBINARY 类型)
    clients.inMemory()
            .withClient("aiqiyi") // app_id
            .resourceIds(QQ_RESOURCE_ID)
            .authorizedGrantTypes("authorization_code", "refresh_token", "implicit") // 授权码模式
            .authorities("ROLE_CLIENT")
            .scopes("get_user_info", "get_fanslist") // 授权范围，默认为空则拥有全部范围
            .secret("my-secret-888888") // app_secret
            .redirectUris("http://localhost:9090/jump") // 重定向地址
            .autoApprove(true)
            .autoApprove("get_user_info")
            .and()
            .withClient("youku")
            .resourceIds(QQ_RESOURCE_ID)
            .authorizedGrantTypes("authorization_code", "refresh_token", "implicit")
            .authorities("ROLE_CLIENT")
            .scopes("get_user_info", "get_fanslist")
            .secret("secret")
            .redirectUris("http://localhost:9090/youku/jump");
}
```
- 获取资源数据

```java
// ### 1
@Autowired
Oauth2Utils oauth2Utils;

@RequestMapping("/info")
public QQAccount info(@RequestParam("access_token") String accessToken){
    OAuth2Authentication oAuth2Authentication = oauth2Utils.getAuthenticationInOauth2Server(accessToken);
    User user = ((User) oAuth2Authentication.getUserAuthentication().getPrincipal());
    return InMemoryQQDatabase.database.get(user.getUsername());
}

// ### 2
@Component
public class Oauth2Utils {
    @Autowired
    ApplicationContext applicationContext;

    // oauth2 认证服务器直接处理校验请求的逻辑
    public OAuth2AccessToken checkTokenInOauth2Server(String accessToken){
        TokenStore tokenStore = (TokenStore) applicationContext.getBean("tokenStore");
        OAuth2AccessToken oAuth2AccessToken = tokenStore.readAccessToken(accessToken);
        return oAuth2AccessToken;
    }

    // oauth2 认证服务器直接处理校验请求的逻辑
    public OAuth2Authentication getAuthenticationInOauth2Server(String accessToken){
        TokenStore tokenStore = (TokenStore) applicationContext.getBean("tokenStore");
        OAuth2Authentication oAuth2Authentication = tokenStore.readAuthentication(accessToken);
        return oAuth2Authentication;
    }
}
```

#### 客户端

> 源码参考 spring-security-oauth2 -> oauth2-authorization-code -> oauth2-authorization-code-aiqiyi(授权服务器为oauth2-authorization-code-qq)

- 获取token

```java
@Autowired
RestTemplate restTemplate;

@RequestMapping("/get_info")
public String getToken(@RequestParam String code){
    // 1.获取token
    log.info("receive code => {}", code);

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
    MultiValueMap<String, String> params= new LinkedMultiValueMap<>();
    params.add("grant_type","authorization_code");
    params.add("code",code);
    params.add("client_id","aiqiyi");
    params.add("client_secret","my-secret-888888");
    params.add("redirect_uri","http://localhost:9090/jump"); // 此时地址必须和请求认证的回调地址一模一样
    HttpEntity<MultiValueMap<String, String>> requestEntity = new HttpEntity<>(params, headers);
    ResponseEntity<String> response = restTemplate.postForEntity("http://localhost:8080/oauth/token", requestEntity, String.class);
    String token = response.getBody();

    log.info("token => {}", token);

    // 2.获取用户信息
    ObjectMapper objectMapper = new ObjectMapper();
    Map tokenMap = new HashMap<>();
    try {
        tokenMap = objectMapper.readValue(token, Map.class);
    } catch (IOException e) {
        e.printStackTrace();
    }

    String url = "http://localhost:8080/qq/info?access_token=" + tokenMap.get("access_token");
    ResponseEntity<Map> userEntity = restTemplate.getForEntity(url, Map.class);
    Map userMap = userEntity.getBody();
    log.info("userMap => {}", userMap);

    return token + "<=========>" + userMap;
}
```

#### 访问资源

- 访问授权服务器：`http://localhost:8080/oauth/authorize?client_id=aiqiyi&response_type=code&redirect_uri=http://localhost:9090/jump`
- 浏览器跳转到授权服务器登录页面：`http://localhost:8080/login`
- 认证通过，获取到授权码，认证服务器重定向到：`http://localhost:9090/jump?code=TLFxg1` (进入客户端后台服务)
- ajax访问客户端服务：`http://localhost:9090/get_info?code=TLFxg1`
    - 客户端服务请求认证服务器获取token：`http://localhost:8080/oauth/token`
    - 获取token成功：{"access_token":"3b017a2d-3e3d-4536-b978-d3d8e05f4b05","token_type":"bearer","refresh_token":"4593b664-9107-404f-8e77-2073515b42c9","expires_in":43199,"scope":"get_user_info get_fanslist"}
    - 获取用户信息(资源数据)
- 浏览器地址变为：`http://localhost:9090/jump?code=TLFxg1`
- 携带 access_token 访问资源服务器：`http://localhost:8080/qq/info?access_token=3b017a2d-3e3d-4536-b978-d3d8e05f4b05` (根据token可获取到用户信息)

#### 客户端自动配置

> 源码参考 spring-security-oauth2 -> oauth2-authorization-code -> oauth2-authorization-code-youku(授权服务器为oauth2-authorization-code-qq)

- 依赖

```xml
<!-- oauth2 客户端登录需要 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-oauth2-client</artifactId>
</dependency>
```

- 配置

```yml
spring:
  security:
    oauth2:
      client:
        provider:
          qq:
            authorization-uri: http://localhost:8080/oauth/authorize
            token-uri: http://localhost:8080/oauth/token
            user-info-uri: http://localhost:8080/qq/userInfo
            userNameAttribute: qq
        registration:
          youku:
            clientId: youku
            clientSecret: my-secret-999999
            clientName: youku
            provider: qq
            scope: get_user_info
            # http://aezocn.local:8081/login/oauth2/code/youku
            redirect-uri-template: "{baseUrl}/login/oauth2/code/youku"
            authorization-grant-type: authorization_code
```
- 常见错误
    - `authorization_request_not_found` => 测试时客户端和认证服务器不能都使用localhost(会导致SESSIONID对应的cookie被覆盖)。可以修改hosts文件，增加一个域名映射到127.0.0.1

#### 单点登录

> 源码参考 spring-security-oauth2 -> oauth2-authorization-code -> oauth2-authorization-code-sso(授权服务器为oauth2-authorization-code-qq)

- 授权服务器配置

```java
public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
    clients.inMemory()
            .withClient("client1")
            .authorities("USER") // 客户端的权限。Granted Authorities
            .authorizedGrantTypes("authorization_code", "refresh_token", "implicit")
            .scopes("get_user_info", "read")
            .secret("my-secret-999999")
            // 本地hosts文件中加 `127.0.0.1 aezocn.local` 的映射。或者增加配置`session.cookie.name: CLIENT1SESSIONID`
            // 测试时需要访问 http://aezocn.local:8081/client1
            .redirectUris("http://aezocn.local:8081/login")
            .autoApprove(true) // 设置为true则默认授权上面所以的scope，否则需要选择授权scope
            .and()
            .withClient("client2")
            .authorizedGrantTypes("authorization_code", "refresh_token", "implicit")
            .scopes("get_user_info")
            .secret("my-secret-999999")
            .redirectUris("http://smalle.local:8082/login") 
            .autoApprove(true)
            ;
}                 
```
- 依赖(以client1为例，登录client1后可直接访问client2的端点)

```xml
<!-- oauth2 客户端登录需要 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<!-- oauth2 sso 需要. springboot2.x 无@EnableOAuth2Sso注解，需要引入此包才行 -->
<dependency>
    <groupId>org.springframework.security.oauth.boot</groupId>
    <artifactId>spring-security-oauth2-autoconfigure</artifactId>
    <version>2.0.1.RELEASE</version>
</dependency>
```
- 配置

```yml
security:
  oauth2:
    client:
      clientId: client1
      clientSecret: my-secret-999999
      userAuthorizationUri: http://localhost:8080/oauth/authorize
      accessTokenUri: http://localhost:8080/oauth/token
    resource:
      userInfoUri: http://localhost:8080/qq/user/me # 获取用户信息端点(必须)
```
- java配置

```java
// ### 1.客户端配置
@Configuration
@EnableOAuth2Sso // 直接定义在Application上报错
public class Client1SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    public void configure(HttpSecurity http) throws Exception {
        http.antMatcher("/**")
            .authorizeRequests()
            .antMatchers("/", "/login**")
            .permitAll()
            .anyRequest()
            .authenticated();
    }
}

// ### 2.访问受保护的页面(可获取用户信息)
@GetMapping("/client1")
public String client1(Authentication user, Principal principal) {
    System.out.println("user = " + user);
    return "client1";
}

// ### 3.测试访问资源服务器数据
@Autowired
OAuth2RestTemplate oAuth2RestTemplate;

@Bean
OAuth2RestTemplate oAuth2RestTemplate(OAuth2ClientContext oAuth2ClientContext){
    return new OAuth2RestTemplate(new AuthorizationCodeResourceDetails(), oAuth2ClientContext);
}

@RequestMapping("/res/read")
public String read(Authentication authentication) {
    String toke = ((OAuth2AuthenticationDetails) authentication.getDetails()).getTokenValue(); // 获取的是客户端token
    String result = oAuth2RestTemplate.getForObject("http://localhost:8083/api/read?id=1&access_token=" + toke, String.class);
    return result;
}
```

#### 访问资源服务器 [^3]

- 依赖同client1模式
- 配置

```yml
security:
  oauth2:
    resource:
      userInfoUri: http://localhost:8080/qq/user/me
      prefer-token-info: false
```
- java

```java
@Configuration
@EnableResourceServer
@EnableGlobalMethodSecurity(prePostEnabled=true) // 开启在方法上配置@PreAuthorize("#oauth2.hasScope('read')")等
public class ResourceSecurityConfig extends ResourceServerConfigurerAdapter {

    /**
     * 获取权限验证配置
     * 1.对HttpSecurity进行配置时存在先后顺序(LinkedHashMap存储. 底层getAttributes匹配到一个路径就返回)
     * 2.authorizeRequests().anyRequest().authenticated()表示
     * **所有请求**只要认证就通过(对应的的内置配置为#oauth2.throwOnError(authenticated)),
     * 因此最好放在最后, 否则后面的access相关配置将失效
     * 3.如对HttpSecurity配置通过后, 当执行的方法有方法级别的权限控制则还会再调用一次decide检查
     */
    @Override
    public void configure(HttpSecurity http) throws Exception {
        http.csrf().disable()
            .authorizeRequests()
            .antMatchers("/", "/webjars/**").permitAll()
            // 只有GET类型的此路径才匹配
            .antMatchers(HttpMethod.GET, "/api/read/**").access("#oauth2.hasScope('read')")
            // 匹配所有HTTP请求类型
            .antMatchers("/api/write/**").access("hasRole('ROLE_USER') and #oauth2.hasScope('write')")
            // 一般放在最后
            .and().authorizeRequests().anyRequest().authenticated();
    }

    @Override
    public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
        // resources.resourceId("this-app-resource-id"); //  // 配置服务的 resourceId ，当 jwt 中不含符合的 resourceId 则拒绝操作（非jwt可不考虑）
        super.configure(resources);
    }
}
```

### 基于jwt

> 源码参考 spring-security-oauth2 -> oauth2-jwt

- 额外依赖

```xml
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-jwt</artifactId>
    <version>1.0.9.RELEASE</version>
</dependency>
```
- java(以对称加密为例, 非对称加密直接看github源码)

```java
// ### web security(WebSecurityConfigurerAdapter)
/**
* 这一步的配置是必不可少的，否则SpringBoot会自动配置一个AuthenticationManager
* 方法名称不建议为authenticationManager(否则password模式获取token失败). https://github.com/spring-projects/spring-boot/issues/12395
*/
@Bean
@Override
public AuthenticationManager authenticationManagerBean() throws Exception {
    AuthenticationManager manager = super.authenticationManagerBean();
    return manager;
}

// ### 
// 资源服务器配置
@Configuration
@EnableResourceServer
protected static class ResourceServerConfiguration extends ResourceServerConfigurerAdapter {
    // ===============资源服务器和授权服务器要一致 start
    @Bean
    public JwtAccessTokenConverter jwtAccessTokenConverter() {
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setSigningKey("aezocn"); // 对称加密. 授权服务器和资源服务使用相同的密码
        return converter;
    }

    @Bean
    public TokenStore tokenStore() {
        return new JwtTokenStore(jwtAccessTokenConverter());
    }

    @Bean
    @Primary
    public DefaultTokenServices tokenServices() {
        DefaultTokenServices defaultTokenServices = new DefaultTokenServices();
        defaultTokenServices.setTokenStore(tokenStore());
        defaultTokenServices.setSupportRefreshToken(true);
        return defaultTokenServices;
    }
    // ===============资源服务器和授权服务器要一致 end

    @Override
    public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
        super.configure(resources);
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
    UserDetailsService userDetailsService;

    // ===============资源服务器和授权服务器要一致 start
    @Bean
    public JwtAccessTokenConverter jwtAccessTokenConverter() {
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setSigningKey("aezocn"); // 对称加密. 授权服务器和资源服务使用相同的密码
        return converter;
    }

    @Bean
    public TokenStore tokenStore() {
        return new JwtTokenStore(jwtAccessTokenConverter());
    }

    @Bean
    @Primary
    public DefaultTokenServices tokenServices() {
        DefaultTokenServices defaultTokenServices = new DefaultTokenServices();
        defaultTokenServices.setTokenStore(tokenStore());
        defaultTokenServices.setSupportRefreshToken(true);
        // 如果客户端认证基于数据存储，token有效期可在数据库表中配置
        return defaultTokenServices;
    }
    // ===============资源服务器和授权服务器要一致 end

    // 定制token字段
    @Bean
    public TokenEnhancer tokenEnhancer() {
        return (accessToken, authentication) -> {
            final Map<String, Object> additionalInfo = new HashMap<>();
            additionalInfo.put("license", "aezocn");
            ((DefaultOAuth2AccessToken) accessToken).setAdditionalInformation(additionalInfo);
            return accessToken;
        };
    }

    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
        String finalSecret = "{bcrypt}" + new BCryptPasswordEncoder().encode("my_secret");

        // 配置两个客户端,一个用于password认证一个用于client认证
        clients.inMemory()
                .withClient("client_1")
                .secret(finalSecret)
                .authorizedGrantTypes("authorization_code", "password", "client_credentials", "refresh_token")
                .scopes("select")
                .autoApprove(true);
                // .accessTokenValiditySeconds(60 * 60 * 12)
                // .refreshTokenValiditySeconds(60 * 60 * 12 * 30)
    }

    // 告诉Spring Security Token的生成方式
    @Override
    public void configure(AuthorizationServerEndpointsConfigurer endpoints) {
        TokenEnhancerChain tokenEnhancerChain = new TokenEnhancerChain();
        tokenEnhancerChain.setTokenEnhancers(Arrays.asList(tokenEnhancer(), jwtAccessTokenConverter()));

        endpoints.tokenEnhancer(tokenEnhancerChain)
                .tokenStore(tokenStore())
                .authenticationManager(authenticationManager)
                .userDetailsService(userDetailsService) // 通过refresh_token刷新token必须设置userDetailsService
                .allowedTokenEndpointRequestMethods(HttpMethod.GET, HttpMethod.POST); // 允许获取token的请求类型
    }

    @Override
    public void configure(AuthorizationServerSecurityConfigurer oauthServer) {
        oauthServer
                //允许所有资源服务器访问公钥端点（/oauth/token_key）
                //只允许验证用户访问令牌解析端点（/oauth/check_token）
                .tokenKeyAccess("permitAll()").checkTokenAccess("isAuthenticated()")
                // 允许客户端发送表单来进行权限认证来获取令牌
                .allowFormAuthenticationForClients();
    }
}

// ### 获取token信息
@Autowired
DefaultTokenServices tokenServices;

@GetMapping("/order/{id}")
public String getOrder(@PathVariable String id, String access_token, Authentication authentication) {
    System.out.println("authentication = " + authentication);
    Authentication authentication2 = SecurityContextHolder.getContext().getAuthentication();
    System.out.println("authentication2 = " + authentication2);

    // 获取token中额外信息
    OAuth2AccessToken oAuth2AccessToken = tokenServices.readAccessToken(access_token);
    System.out.println("additionalInformation = " + oAuth2AccessToken.getAdditionalInformation()); // my_add_attr
    return "order id : " + id;
}
```
- 测试

```java
/*
 1.访问：http://localhost:8084/oauth/token?grant_type=password&username=user_1&password=123456&client_id=client_1&client_secret=my_secret
    (client_credentials模式无refresh_token返回 http://localhost:8084/oauth/token?grant_type=client_credentials&scope=select&client_id=client_1&client_secret=my_secret)
 2.返回（上述是基于client_1进行的认证，得到的token也可以访问client_2）
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsaWNlbnNlIjoiYWV6b2NuIiwidXNlcl9uYW1lIjoidXNlcl8xIiwic2NvcGUiOlsic2VsZWN0Il0sImV4cCI6MTU0NTQxNTcwOCwiYXV0aG9yaXRpZXMiOlsiVVNFUiJdLCJqdGkiOiI4OTM0MGY0ZC1mMWE4LTQ1ZTMtOTE3Ni1kMzY0ZWE3MmY5ODYiLCJjbGllbnRfaWQiOiJjbGllbnRfMSJ9.A_do_6S1A7FKUWzdE1p7x6pBvPFNNOFL5JuDwUvfJOY",
    "token_type": "bearer",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsaWNlbnNlIjoiYWV6b2NuIiwidXNlcl9uYW1lIjoidXNlcl8xIiwic2NvcGUiOlsic2VsZWN0Il0sImF0aSI6Ijg5MzQwZjRkLWYxYTgtNDVlMy05MTc2LWQzNjRlYTcyZjk4NiIsImV4cCI6MTU0Nzk2NDUwOCwiYXV0aG9yaXRpZXMiOlsiVVNFUiJdLCJqdGkiOiJhNmM5NTQ4NS0yNTUzLTRlZjMtYWUwMi0wY2JjZjg2ZmQ1N2EiLCJjbGllbnRfaWQiOiJjbGllbnRfMSJ9.OoNAbGd62PxKPzzH03ASDUus-aYcWT5ktqaHMkezha0",
    "expires_in": 43200, // 有效秒数(12h)
    "scope": "select",
    "license": "aezocn",
    "jti": "89340f4d-f1a8-45e3-9176-d364ea72f986"
}
3.访问 http://localhost:8084/order/1?access_token=xxxxxx (或者Header中加token，如：`Authorization: Bearer xxx`)
4.刷新token: http://localhost:8084/oauth/token?grant_type=refresh_token&client_id=client_1&client_secret=my_secret&refresh_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsaWNlbnNlIjoiYWV6b2NuIiwidXNlcl9uYW1lIjoidXNlcl8xIiwic2NvcGUiOlsic2VsZWN0Il0sImF0aSI6ImQ0YjFmZjAzLTZmMzMtNGMyNS04MWFiLTQ1YWYwMjg5NmQ4NCIsImV4cCI6MTU0Nzk2NTE2MywiYXV0aG9yaXRpZXMiOlsiVVNFUiJdLCJqdGkiOiJkMDc0MzJiYy1kNDk5LTQ1ZDgtYTY2My1lMWQ0ZDg0NmNhMTQiLCJjbGllbnRfaWQiOiJjbGllbnRfMSJ9.F0ZaPI-pDXm98MFT2gXtet82Pfbc-Woh5yBp_SPbFtk
*/
```

### 常见问题

- sso登录报错`Authentication Failed: Could not obtain access token`
    - 1.use server.context-path to move each App to different paths, note that you need to do this for both(两个应用使用不同的hostname)
    - 2.set the server.session.cookie.name for one App to something different, e.g., APPSESSIONID(两个应用使用不同的SESSIONID名称)
- `.antMatchers("/api/write/**").access("hasRole('ROLE_USER') and #oauth2.hasScope('write')")`配置无效
    - HttpSecurity配置时路径顺序很重要，具体参考【授权码模式-sso单点登陆-资源服务器注释】
    - 验证客户端时, scope会生效。password模式验证用户token时scope测试未生效
- password模式获取token，报错`TokenEndpoint  : Handling error: NestedServletException, Handler dispatch failed; nested exception is java.lang.StackOverflowError`
    - 解决方法`AuthenticationManager authenticationManagerBean()`：https://github.com/spring-projects/spring-boot/issues/12395
- 利用refresh_token无法刷新token
    - 需要设置userDetailsService

#### debug日志

基于OAuth2，客户端携Token获取用户信息为例

```java
// ######### 1.正确访问日志(需开启debug日志配置. logging.level.org.springframework.security: DEBUG)
// ... 省略了一些/logout登出等前置拦截器日志
2019-05-24 10:30:07.444 DEBUG 9400 --- [nio-8095-exec-9] o.s.security.web.FilterChainProxy        : /crm/base/get_result at position 11 of 11 in additional filter chain; firing Filter: 'FilterSecurityInterceptor'
// A./test/main为`public void configure(HttpSecurity http)`中配置的端点，公开访问
2019-05-24 10:30:07.444 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/crm/base/get_result'; against '/test/main'
// B.访问路径，需要校验的权限
2019-05-24 10:30:07.444 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.w.a.i.FilterSecurityInterceptor    : Secure object: FilterInvocation: URL: /crm/base/get_result; Attributes: [#oauth2.throwOnError(authenticated)]
// C.当前获取到的认证对象(用户信息)
2019-05-24 10:30:07.444 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.w.a.i.FilterSecurityInterceptor    : Previously Authenticated: org.springframework.security.oauth2.provider.OAuth2Authentication@d2206165: Principal: smalle; Credentials: [PROTECTED]; Authenticated: true; Details: remoteAddress=192.168.17.237, tokenType=BearertokenValue=<TOKEN>; Granted Authorities: ROLE_USER
// D.认证投票，返回1，此投票员通过
2019-05-24 10:30:07.444 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.access.vote.AffirmativeBased       : Voter: org.springframework.security.web.access.expression.WebExpressionVoter@71bae26, returned: 1
// E.认证成功
2019-05-24 10:30:07.445 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.w.a.i.FilterSecurityInterceptor    : Authorization successful
2019-05-24 10:30:07.445 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.w.a.i.FilterSecurityInterceptor    : RunAsManager did not change Authentication object
// F.处理原始请求，即进入/crm/base/get_result的业务逻辑
2019-05-24 10:30:07.445 DEBUG 9400 --- [nio-8095-exec-9] o.s.security.web.FilterChainProxy        : /crm/base/get_result reached end of additional filter chain; proceeding with original chain
2019-05-24 10:30:07.446 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.w.header.writers.HstsHeaderWriter  : Not injecting HSTS header since it did not match the requestMatcher org.springframework.security.web.header.writers.HstsHeaderWriter$SecureRequestMatcher@70a89018
2019-05-24 10:30:07.447 DEBUG 9400 --- [nio-8095-exec-9] o.s.s.w.a.ExceptionTranslationFilter     : Chain processed normally
2019-05-24 10:30:07.448 DEBUG 9400 --- [nio-8095-exec-9] s.s.w.c.SecurityContextPersistenceFilter : SecurityContextHolder now cleared, as request processing completed

// ######### 2.错误日志示例(springcloud服务消费者，以请求头无Authorization信息为例. 防止文章显示异常，将日志中*/*被改成了*/ *)
// A.访问/user/info/base，进行 `public void configure(HttpSecurity http)` 方法中的Ant路径匹配
2019-05-31 12:43:30.983 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/oauth/token']
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/user/info/base'; against '/oauth/token'
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/oauth/token_key']
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/user/info/base'; against '/oauth/token_key'
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/oauth/check_token']
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/user/info/base'; against '/oauth/check_token'
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : No matches found
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/user/**']
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/user/info/base'; against '/user/**'
2019-05-31 12:43:30.984 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : matched
// B.匹配到路径后，依次执行拦截器流程，包括/logout等路径拦截
2019-05-31 12:43:30.985 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 1 of 12 in additional filter chain; firing Filter: 'WebAsyncManagerIntegrationFilter'
2019-05-31 12:43:30.986 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 2 of 12 in additional filter chain; firing Filter: 'SecurityContextPersistenceFilter'
2019-05-31 12:43:30.987 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 3 of 12 in additional filter chain; firing Filter: 'HeaderWriterFilter'
2019-05-31 12:43:30.988 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 4 of 12 in additional filter chain; firing Filter: 'LogoutFilter'
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', GET]
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/user/info/base'; against '/logout'
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', POST]
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Request 'GET /user/info/base' doesn't match 'POST /logout
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', PUT]
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Request 'GET /user/info/base' doesn't match 'PUT /logout
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', DELETE]
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Request 'GET /user/info/base' doesn't match 'DELETE /logout
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : No matches found
// B1.执行OAuth2AuthenticationProcessingFilter拦截器，基于token获取用户信息
2019-05-31 12:43:30.989 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 5 of 12 in additional filter chain; firing Filter: 'OAuth2AuthenticationProcessingFilter'
// B2.******从Header(Authorization: Bearer xxx)中尚未获取到token，尝试从请求参数中获取
2019-05-31 12:43:35.223 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.o.p.a.BearerTokenExtractor         : Token not found in headers. Trying request parameters.
// B3.从请求参数中也为获取到tonen，得出结论，此请求不是一个有效的OAuth2请求
2019-05-31 12:43:35.223 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.o.p.a.BearerTokenExtractor         : Token not found in request parameters.  Not an OAuth2 request.
// B4.request中无token继续执行拦截器链
2019-05-31 12:43:35.223 DEBUG 27096 --- [nio-8200-exec-3] p.a.OAuth2AuthenticationProcessingFilter : No token in request, will continue chain.
2019-05-31 12:43:35.223 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 6 of 12 in additional filter chain; firing Filter: 'BasicAuthenticationFilter'
2019-05-31 12:43:35.223 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 7 of 12 in additional filter chain; firing Filter: 'RequestCacheAwareFilter'
2019-05-31 12:43:35.223 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 8 of 12 in additional filter chain; firing Filter: 'SecurityContextHolderAwareRequestFilter'
// B5.既然没有获取到认证信息，此时初始化一个认证对象(为游客身份)
2019-05-31 12:43:35.225 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 9 of 12 in additional filter chain; firing Filter: 'AnonymousAuthenticationFilter'
2019-05-31 12:43:35.226 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.a.AnonymousAuthenticationFilter  : Populated SecurityContextHolder with anonymous token: 'org.springframework.security.authentication.AnonymousAuthenticationToken@e6c8d1cb: Principal: anonymousUser; Credentials: [PROTECTED]; Authenticated: true; Details: org.springframework.security.web.authentication.WebAuthenticationDetails@59b2: RemoteIpAddress: 192.168.6.1; SessionId: null; Granted Authorities: ROLE_ANONYMOUS'
2019-05-31 12:43:35.226 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 10 of 12 in additional filter chain; firing Filter: 'SessionManagementFilter'
2019-05-31 12:43:35.226 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 11 of 12 in additional filter chain; firing Filter: 'ExceptionTranslationFilter'
2019-05-31 12:43:35.226 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /user/info/base at position 12 of 12 in additional filter chain; firing Filter: 'FilterSecurityInterceptor'
// C.拦截器执行完成，此时已经获取到了认证对象(用户信息)。需要访问的路径为 /user/info/base，需要判断的权限为 [#oauth2.throwOnError(authenticated)] (需要已登录权限)
2019-05-31 12:43:35.227 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.a.i.FilterSecurityInterceptor    : Secure object: FilterInvocation: URL: /user/info/base; Attributes: [#oauth2.throwOnError(authenticated)]
// D.进行权限认证前，此时获取到的认证对象(基于用户名/session/token获取到的用户信息)为 anonymousUser(用户认证信息ROLE_ANONYMOUS说明用户为游客)
2019-05-31 12:43:35.227 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.a.i.FilterSecurityInterceptor    : Previously Authenticated: org.springframework.security.authentication.AnonymousAuthenticationToken@e6c8d1cb: Principal: anonymousUser; Credentials: [PROTECTED]; Authenticated: true; Details: org.springframework.security.web.authentication.WebAuthenticationDetails@59b2: RemoteIpAddress: 192.168.6.1; SessionId: null; Granted Authorities: ROLE_ANONYMOUS
// E.执行认证投票，-1表示投票不通过，认证失败
2019-05-31 12:43:35.236 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.access.vote.AffirmativeBased       : Voter: org.springframework.security.web.access.expression.WebExpressionVoter@6c422090, returned: -1
// F.认证失败，无权访问资源
2019-05-31 12:43:35.245 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.a.ExceptionTranslationFilter     : Access is denied (user is anonymous); redirecting to authentication entry point

org.springframework.security.access.AccessDeniedException: Access is denied
    at org.springframework.security.access.vote.AffirmativeBased.decide(AffirmativeBased.java:84) ~[spring-security-core-5.0.4.RELEASE.jar:5.0.4.RELEASE]
    at org.springframework.security.access.intercept.AbstractSecurityInterceptor.beforeInvocation(AbstractSecurityInterceptor.java:233) ~[spring-security-core-5.0.4.RELEASE.jar:5.0.4.RELEASE]
    at org.springframework.security.web.access.intercept.FilterSecurityInterceptor.invoke(FilterSecurityInterceptor.java:124) ~[spring-security-web-5.0.4.RELEASE.jar:5.0.4.RELEASE]
    at org.springframework.security.web.access.intercept.FilterSecurityInterceptor.doFilter(FilterSecurityInterceptor.java:91) ~[spring-security-web-5.0.4.RELEASE.jar:5.0.4.RELEASE]
    // ...
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617) [na:1.8.0_111]
    at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61) [tomcat-embed-core-8.5.29.jar:8.5.29]
    at java.lang.Thread.run(Thread.java:745) [na:1.8.0_111]

2019-05-31 12:43:35.256 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.a.ExceptionTranslationFilter     : Calling Authentication entry point.
2019-05-31 12:43:35.257 DEBUG 27096 --- [nio-8200-exec-3] s.w.a.DelegatingAuthenticationEntryPoint : Trying to match using MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[application/atom+xml, application/x-www-form-urlencoded, application/json, application/octet-stream, application/xml, multipart/form-data, text/xml], useEquals=false, ignoredMediaTypes=[*/ *]]
2019-05-31 12:43:35.258 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : httpRequestMediaTypes=[*/ *]
2019-05-31 12:43:35.258 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : Processing */ *
2019-05-31 12:43:35.258 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : Ignoring
2019-05-31 12:43:35.258 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : Did not match any media types
2019-05-31 12:43:35.258 DEBUG 27096 --- [nio-8200-exec-3] s.w.a.DelegatingAuthenticationEntryPoint : Trying to match using OrRequestMatcher [requestMatchers=[RequestHeaderRequestMatcher [expectedHeaderName=X-Requested-With, expectedHeaderValue=XMLHttpRequest], AndRequestMatcher [requestMatchers=[NegatedRequestMatcher [requestMatcher=MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[text/html], useEquals=false, ignoredMediaTypes=[]]], MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[application/atom+xml, application/x-www-form-urlencoded, application/json, application/octet-stream, application/xml, multipart/form-data, text/xml], useEquals=false, ignoredMediaTypes=[*/ *]]]], MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[*/ *], useEquals=true, ignoredMediaTypes=[]]]]
2019-05-31 12:43:35.258 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using RequestHeaderRequestMatcher [expectedHeaderName=X-Requested-With, expectedHeaderValue=XMLHttpRequest]
2019-05-31 12:43:35.258 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using AndRequestMatcher [requestMatchers=[NegatedRequestMatcher [requestMatcher=MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[text/html], useEquals=false, ignoredMediaTypes=[]]], MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[application/atom+xml, application/x-www-form-urlencoded, application/json, application/octet-stream, application/xml, multipart/form-data, text/xml], useEquals=false, ignoredMediaTypes=[*/ *]]]]
2019-05-31 12:43:35.259 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.util.matcher.AndRequestMatcher   : Trying to match using NegatedRequestMatcher [requestMatcher=MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[text/html], useEquals=false, ignoredMediaTypes=[]]]
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : httpRequestMediaTypes=[*/ *]
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : Processing */ *
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : text/html .isCompatibleWith */ * = true
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.NegatedRequestMatcher  : matches = false
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.util.matcher.AndRequestMatcher   : Did not match
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using MediaTypeRequestMatcher [contentNegotiationStrategy=org.springframework.web.accept.ContentNegotiationManager@5037f327, matchingMediaTypes=[*/ *], useEquals=true, ignoredMediaTypes=[]]
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : httpRequestMediaTypes=[*/ *]
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : Processing */ *
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.m.MediaTypeRequestMatcher      : isEqualTo true
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : matched
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] s.w.a.DelegatingAuthenticationEntryPoint : Match found! Executing org.springframework.security.web.authentication.DelegatingAuthenticationEntryPoint@41582899
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] s.w.a.DelegatingAuthenticationEntryPoint : Trying to match using RequestHeaderRequestMatcher [expectedHeaderName=X-Requested-With, expectedHeaderValue=XMLHttpRequest]
2019-05-31 12:43:35.262 DEBUG 27096 --- [nio-8200-exec-3] s.w.a.DelegatingAuthenticationEntryPoint : No match found. Using default entry point org.springframework.security.web.authentication.www.BasicAuthenticationEntryPoint@3e138bb4
2019-05-31 12:43:35.263 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.header.writers.HstsHeaderWriter  : Not injecting HSTS header since it did not match the requestMatcher org.springframework.security.web.header.writers.HstsHeaderWriter$SecureRequestMatcher@34581d9e
// G.Security执行完成，释放SecurityContextHolder
2019-05-31 12:43:35.263 DEBUG 27096 --- [nio-8200-exec-3] s.s.w.c.SecurityContextPersistenceFilter : SecurityContextHolder now cleared, as request processing completed
// A.权限认证失败，此时跳转到 MVC 的 /error 端点（当成一个新请求，继续执行上述 Security）
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/oauth/token']
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/error'; against '/oauth/token'
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/oauth/token_key']
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/error'; against '/oauth/token_key'
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/oauth/check_token']
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/error'; against '/oauth/check_token'
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : No matches found
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/user/**']
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/error'; against '/user/**'
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : No matches found
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 1 of 11 in additional filter chain; firing Filter: 'WebAsyncManagerIntegrationFilter'
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 2 of 11 in additional filter chain; firing Filter: 'SecurityContextPersistenceFilter'
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] w.c.HttpSessionSecurityContextRepository : No HttpSession currently exists
2019-05-31 12:43:35.268 DEBUG 27096 --- [nio-8200-exec-3] w.c.HttpSessionSecurityContextRepository : No SecurityContext was available from the HttpSession: null. A new one will be created.
2019-05-31 12:43:35.270 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 3 of 11 in additional filter chain; firing Filter: 'HeaderWriterFilter'
2019-05-31 12:43:35.270 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 4 of 11 in additional filter chain; firing Filter: 'LogoutFilter'
2019-05-31 12:43:35.270 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', GET]
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Checking match of request : '/error'; against '/logout'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', POST]
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Request 'GET /error' doesn't match 'POST /logout
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', PUT]
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Request 'GET /error' doesn't match 'PUT /logout
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : Trying to match using Ant [pattern='/logout', DELETE]
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Request 'GET /error' doesn't match 'DELETE /logout
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.web.util.matcher.OrRequestMatcher  : No matches found
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 5 of 11 in additional filter chain; firing Filter: 'UsernamePasswordAuthenticationFilter'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.u.matcher.AntPathRequestMatcher  : Request 'GET /error' doesn't match 'POST /login
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 6 of 11 in additional filter chain; firing Filter: 'RequestCacheAwareFilter'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 7 of 11 in additional filter chain; firing Filter: 'SecurityContextHolderAwareRequestFilter'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 8 of 11 in additional filter chain; firing Filter: 'AnonymousAuthenticationFilter'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.a.AnonymousAuthenticationFilter  : Populated SecurityContextHolder with anonymous token: 'org.springframework.security.authentication.AnonymousAuthenticationToken@28256a19: Principal: anonymousUser; Credentials: [PROTECTED]; Authenticated: true; Details: org.springframework.security.web.authentication.WebAuthenticationDetails@59b2: RemoteIpAddress: 192.168.6.1; SessionId: null; Granted Authorities: ROLE_ANONYMOUS'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 9 of 11 in additional filter chain; firing Filter: 'SessionManagementFilter'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 10 of 11 in additional filter chain; firing Filter: 'ExceptionTranslationFilter'
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error at position 11 of 11 in additional filter chain; firing Filter: 'FilterSecurityInterceptor'
// B./error的Security拦截器执行完成
2019-05-31 12:43:35.271 DEBUG 27096 --- [nio-8200-exec-3] o.s.security.web.FilterChainProxy        : /error reached end of additional filter chain; proceeding with original chain
// C.SecurityContext信息未空，不保存session
2019-05-31 12:43:35.314 DEBUG 27096 --- [nio-8200-exec-3] w.c.HttpSessionSecurityContextRepository : SecurityContext is empty or contents are anonymous - context will not be stored in HttpSession.
2019-05-31 12:43:35.319 DEBUG 27096 --- [nio-8200-exec-3] o.s.s.w.a.ExceptionTranslationFilter     : Chain processed normally
// D./error请求完成
2019-05-31 12:43:35.319 DEBUG 27096 --- [nio-8200-exec-3] s.s.w.c.SecurityContextPersistenceFilter : SecurityContextHolder now cleared, as request processing completed
2019-05-31 12:44:27.288  INFO 27096 --- [trap-executor-0] c.n.d.s.r.aws.ConfigClusterResolver      : Resolving eureka endpoints via configuration
````

## 源码解析

- 登录流程(请求权限验证相关拦截器处理过程)

<embed width="1000" height="800" src="/data/pdf/SpringSecurity-Login.pdf" internalinstanceid="7">

- 类图

<embed width="1000" height="800" src="/data/pdf/SpringSecurity-Class.pdf" internalinstanceid="7">

---

参考文章

[^1]: http://www.importnew.com/20612.html (spring-security的原理及教程)
[^2]: https://github.com/lexburner/oauth2-demo (Spring Security Oauth2)
[^3]: https://www.jianshu.com/p/6dd03375224d
[^4]: https://m635674608.iteye.com/blog/2398708
[^5]: https://www.cnblogs.com/jfzhu/p/4020928.html (对称加密和非对称加密)
[^6]: https://www.jianshu.com/p/227f7e7503cb (授权服务器)