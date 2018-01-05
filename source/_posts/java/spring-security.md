---
layout: "post"
title: "spring-security"
date: "2017-10-22 11:15"
categories: java
tags: [spring, springsecurity, springboot]
---

## 简介

- 官网：[http://projects.spring.io/spring-security/](http://projects.spring.io/spring-security/)
- 文档：[V4.2.3](https://docs.spring.io/spring-security/site/docs/4.2.3.RELEASE/reference/htmlsingle/)
- 引入spring security后便有了session机制

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
        public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
            auth.authenticationProvider(authProvider);
        }

        // 定义权限规则
        @Override
        protected void configure(HttpSecurity http) throws Exception {
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
                    .loginPage("/manage/login").permitAll() // 登录界面(Get)
                    .loginProcessingUrl("/manage/login") // 或者通配符/**/login拦截对"/manage/login"和"/login"等的POST请求(登录请求。具体逻辑不需要写，并且会自动生成此端点的control，否则和loginPage一致)
                    .successHandler(authenticationSuccessHandler) // 此处定义登录成功处理方法
                    .failureHandler(authenticationFailureHandler)
                    .authenticationDetailsSource(authenticationDetailsSource)
                    .and()
                .logout().logoutUrl("/manage/logout").logoutSuccessUrl("/manage/login").permitAll() // 访问"/manage/logout"登出，登出成功后跳转到"/manage/login"
                    .and()
                .exceptionHandling().accessDeniedHandler(accessDeniedHandler);
        }

        // 密码加密器 (4)
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
                return AuthorityUtils.createAuthorityList("ROLE_" + this.getRoleCode()); // 组成如：ROLE_ADMIN/ROLE_USER，在资源权限定义时写法如：hasRole('ADMIN')。createAuthorityList接受一个数组，说明支持一个用户拥有多个角色
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
- (2)登录校验完成拦截：登录成功/失败处理

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
- (3)AccessDeniedHandler访问受限拦截同上例
- (4)密码保存
    
    ```java
    // BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(16);
    // 保存密码：$2a$16$YcrLwsfqGoKzkmAB9WwORulggKVCrpR7ZPfDCF4CsEoG0o75Nb3Xm
    String password = passwordEncoder.encode("123456");
    assertTrue(encoder.matches("123456", password));
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








---

[^1]: [spring security的原理及教程](http://www.importnew.com/20612.html)