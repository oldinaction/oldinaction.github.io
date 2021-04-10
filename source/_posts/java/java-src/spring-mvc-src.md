---
layout: "post"
title: "Spring MVC源码解析"
date: "2020-09-08 09:25"
categories: [java]
tags: [spring, src]
---

## 请求流程

- SpringMVC 的整个请求流程 [^2]

    ![springmvc-flow](/data/images/java/springmvc-flow.png)
    - 用户请求发送到**前端控制器DispatcherServlet**
    - 前端控制器DispatcherServlet接收到请求后，DispatcherServlet会使用HandlerMapping来处理，**HandlerMapping会查找到具体进行处理请求的Handler对象**
    - HandlerMapping找到对应的Handler之后，返回一个**Handler执行链**，在这个执行链中包括了拦截器和处理请求的Handler
    - DispatcherServlet接收到执行链之后，会**调用Handler适配器**去执行Handler
    - Handler适配器执行完成**Handler（也就是我们写的Controller）**之后会得到一个ModelAndView，并返回给DispatcherServlet
    - DispatcherServlet接收到Handler适配器返回的ModelAndView之后，会根据其中的视图名**调用视图解析器**
    - 视图解析器根据逻辑视图名解析成一个**真正的View视图**，并返回给DispatcherServlet
    - DispatcherServlet接收到视图之后，会根据上面的ModelAndView中的model来进行视图中数据的填充，也就是所谓的**视图渲染**
    - 渲染完成之后，DispatcherServlet就可以将结果返回给用户了
- 说明
    - springboot直接使用Servlet，这种请求是不会进入SpringMVC的流程的

### 请求进入DispatcherServlet

- FrameworkServlet.java

```java
// DispatcherServlet 继承自 FrameworkServlet，请求先进入到 service 方法
public abstract class FrameworkServlet extends HttpServletBean implements ApplicationContextAware {
    protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpMethod httpMethod = HttpMethod.resolve(request.getMethod());
        if (httpMethod != HttpMethod.PATCH && httpMethod != null) {
            super.service(request, response);
        } else {
            // 
            this.processRequest(request, response);
        }
    }
}

protected final void processRequest(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    // ...
    try {
        this.doService(request, response);
    }
    // ...
}

protected abstract void doService(HttpServletRequest var1, HttpServletResponse var2) throws Exception;
```
- **DispatcherServlet.java**

```java
// 实现 FrameworkServlet 的抽象方法
protected void doService(HttpServletRequest request, HttpServletResponse response) throws Exception {
    // ...
    try {
        this.doDispatch(request, response);
    } finally {
        if (!WebAsyncUtils.getAsyncManager(request).isConcurrentHandlingStarted() && attributesSnapshot != null) {
            this.restoreAttributesAfterInclude(request, attributesSnapshot);
        }
    }
}

// 主要处理方法
protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
    HttpServletRequest processedRequest = request;
    HandlerExecutionChain mappedHandler = null;
    boolean multipartRequestParsed = false;
    // SpringMVC中异步请求的相关
    WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);

    try {
        try {
            ModelAndView mv = null;
            Object dispatchException = null;

            try {
                // 先检查是不是Multipart类型的，比如上传等
                // 如果是Multipart类型的，则转换为 MultipartHttpServletRequest 类型
                processedRequest = this.checkMultipart(request);
                multipartRequestParsed = processedRequest != request;

                // **基于HandlerMapping获取当前请求的Handler**，参考下文[查找请求对应的Handler对象](#查找请求对应的Handler对象(Controller))
                mappedHandler = this.getHandler(processedRequest);
                if (mappedHandler == null) {
                    this.noHandlerFound(processedRequest, response);
                    return;
                }

                // **获取当前请求的Handler适配器**，参考下文[获取对应请求的Handler适配器](#获取对应请求的Handler适配器)
                HandlerAdapter ha = this.getHandlerAdapter(mappedHandler.getHandler());

                // 对于header中last-modified的处理
                String method = request.getMethod();
                boolean isGet = "GET".equals(method);
                if (isGet || "HEAD".equals(method)) {
                    long lastModified = ha.getLastModified(request, mappedHandler.getHandler());
                    if ((new ServletWebRequest(request, response)).checkNotModified(lastModified) && isGet) {
                        return;
                    }
                }

                // 拦截器的preHandle方法进行处理
                if (!mappedHandler.applyPreHandle(processedRequest, response)) {
                    return;
                }

                // 真正调用Handler的地方
                mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
                if (asyncManager.isConcurrentHandlingStarted()) {
                    return;
                }

                // 处理成默认视图名，就是添加前缀和后缀等
                this.applyDefaultViewName(processedRequest, mv);

                // 拦截器postHandle方法进行处理
                mappedHandler.applyPostHandle(processedRequest, response, mv);
            } catch (Exception var20) {
                dispatchException = var20;
            } catch (Throwable var21) {
                dispatchException = new NestedServletException("Handler dispatch failed", var21);
            }

            // 处理最后的结果，渲染之类的都在这里
            this.processDispatchResult(processedRequest, response, mappedHandler, mv, (Exception)dispatchException);
        } catch (Exception var22) {
            this.triggerAfterCompletion(processedRequest, response, mappedHandler, var22);
        } catch (Throwable var23) {
            this.triggerAfterCompletion(processedRequest, response, mappedHandler, new NestedServletException("Handler processing failed", var23));
        }
    } finally {
        if (asyncManager.isConcurrentHandlingStarted()) {
            if (mappedHandler != null) {
                mappedHandler.applyAfterConcurrentHandlingStarted(processedRequest, response);
            }
        } else if (multipartRequestParsed) {
            this.cleanupMultipart(processedRequest);
        }

    }
}
```

### 查找请求对应的Handler对象(Controller)

- DispatcherServlet.java

```java
@Nullable
protected HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception {
    if (this.handlerMappings != null) {
        // 遍历所有的handlerMappings进行处理
        // handlerMappings是在启动的时候预先注册好的
        for (HandlerMapping mapping : this.handlerMappings) {
            HandlerExecutionChain handler = mapping.getHandler(request);
            if (handler != null) {
                return handler;
            }
        }
    }
    return null;
}
```
- AbstractHandlerMapping.java

```java
@Override
@Nullable
public final HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception {
    // 根据request获取handler，getHandlerInternal为抽象方法
    Object handler = getHandlerInternal(request);
    if (handler == null) {
        // 如果没有找到就使用默认的handler
        handler = getDefaultHandler();
    }
    if (handler == null) {
        return null;
    }

    // 如果Handler是String，表明是一个bean名称
    if (handler instanceof String) {
        String handlerName = (String) handler;
        handler = obtainApplicationContext().getBean(handlerName);
    }

    // 封装Handler执行链
    HandlerExecutionChain executionChain = getHandlerExecutionChain(handler, request);

    // ...
    return executionChain;
}
```
- 以 AbstractHandlerMethodMapping.java 为例

```java
@Override
protected HandlerMethod getHandlerInternal(HttpServletRequest request) throws Exception {
    // 获取request中的url，用来匹配handler. **如：/test/ping (此时不包含servlet.context)**
    String lookupPath = getUrlPathHelper().getLookupPathForRequest(request);
    request.setAttribute(LOOKUP_PATH, lookupPath);
    this.mappingRegistry.acquireReadLock();
    try {
        // 根据路径寻找Handler，具体见下文
        HandlerMethod handlerMethod = lookupHandlerMethod(lookupPath, request);
        // 根据handlerMethod中的bean来实例化Handler并添加进HandlerMethod
        return (handlerMethod != null ? handlerMethod.createWithResolvedBean() : null);
    }
    finally {
        this.mappingRegistry.releaseReadLock();
    }
}

@Nullable
protected HandlerMethod lookupHandlerMethod(String lookupPath, HttpServletRequest request) throws Exception {
    List<Match> matches = new ArrayList<>();
    // 直接匹配. MappingRegistry在启动时初始化并扫描所有的类，将HTTP URL和方法名进行映射。参考下文[MappingRegistry类说明](#MappingRegistry类说明)
    List<T> directPathMatches = this.mappingRegistry.getMappingsByUrl(lookupPath);
    // 如果有匹配的，就添加进匹配列表中
    if (directPathMatches != null) {
        addMatchingMappings(directPathMatches, matches, request);
    }
    // 还没有匹配的，就遍历所有的处理方法查找
    if (matches.isEmpty()) {
        // No choice but to go through all mappings...
        addMatchingMappings(this.mappingRegistry.getMappings().keySet(), matches, request);
    }

    // 找到了匹配的
    if (!matches.isEmpty()) {
        Match bestMatch = matches.get(0);
        if (matches.size() > 1) {
            Comparator<Match> comparator = new MatchComparator(getMappingComparator(request));
            matches.sort(comparator);
            // 排序之后，获取第一个
            bestMatch = matches.get(0);
            if (logger.isTraceEnabled()) {
                logger.trace(matches.size() + " matching mappings: " + matches);
            }
            if (CorsUtils.isPreFlightRequest(request)) {
                return PREFLIGHT_AMBIGUOUS_MATCH;
            }
            // 如果有多个匹配的，会找到第二个进行比较一下
            Match secondBestMatch = matches.get(1);
            if (comparator.compare(bestMatch, secondBestMatch) == 0) {
                Method m1 = bestMatch.handlerMethod.getMethod();
                Method m2 = secondBestMatch.handlerMethod.getMethod();
                String uri = request.getRequestURI();
                throw new IllegalStateException(
                        "Ambiguous handler methods mapped for '" + uri + "': {" + m1 + ", " + m2 + "}");
            }
        }
        request.setAttribute(BEST_MATCHING_HANDLER_ATTRIBUTE, bestMatch.handlerMethod);
        // 设置request参数
        handleMatch(bestMatch.mapping, lookupPath, request);
        // 返回匹配的url的处理的方法
        return bestMatch.handlerMethod;
    }
    else {
        return handleNoMatch(this.mappingRegistry.getMappings().keySet(), lookupPath, request);
    }
}
```
- 如果是使用@RequestMapping(如SpringBoot中)，则通过RequestMappingInfoHandlerMapping.java可解析出Handle(继承自AbstractHandlerMethodMapping)

```java
@Override
protected HandlerMethod getHandlerInternal(HttpServletRequest request) throws Exception {
    request.removeAttribute(PRODUCIBLE_MEDIA_TYPES_ATTRIBUTE);
    try {
        // AbstractHandlerMethodMapping.java
        return super.getHandlerInternal(request);
    }
    finally {
        ProducesRequestCondition.clearMediaTypesAttribute(request);
    }
}
```
- AbstractHandlerMapping.java

```java
protected HandlerExecutionChain getHandlerExecutionChain(Object handler, HttpServletRequest request) {
    // 如果当前Handler不是执行链类型，就使用一个新的执行链实例封装起来
    HandlerExecutionChain chain = (handler instanceof HandlerExecutionChain ?
            (HandlerExecutionChain) handler : new HandlerExecutionChain(handler));

    // 当前的url
    String lookupPath = this.urlPathHelper.getLookupPathForRequest(request, LOOKUP_PATH);
    // 遍历拦截器，找到跟当前url对应的，添加进执行链中去
    for (HandlerInterceptor interceptor : this.adaptedInterceptors) {
        if (interceptor instanceof MappedInterceptor) {
            MappedInterceptor mappedInterceptor = (MappedInterceptor) interceptor;
            if (mappedInterceptor.matches(lookupPath, this.pathMatcher)) {
                chain.addInterceptor(mappedInterceptor.getInterceptor());
            }
        }
        else {
            chain.addInterceptor(interceptor);
        }
    }
    return chain;
}
```

### 获取对应请求的Handler适配器

```java
protected HandlerAdapter getHandlerAdapter(Object handler) throws ServletException {
    if (this.handlerAdapters != null) {
        // 遍历所有的HandlerAdapter，找到和当前Handler匹配的就返回
        // 我们这里会匹配到RequestMappingHandlerAdapter
        for (HandlerAdapter adapter : this.handlerAdapters) {
            if (adapter.supports(handler)) {
                return adapter;
            }
        }
    }
    throw new ServletException("No adapter for handler [" + handler +
            "]: The DispatcherServlet configuration needs to include a HandlerAdapter that supports this handler");
}
```

## 系统初始化

### mappingRegistry初始化

- mappingRegistry主要记录了URL-HandlerMethod(Controller方法)的映射
- 映射处理器HandlerMapping接口说明，参考[spring.md#映射处理器HandlerMapping](/_posts/java/spring.md#映射处理器HandlerMapping)
    - AbstractHandlerMapping(实现getHandler方法)
    - AbstractHandlerMethodMapping(通过MappingRegistry初始化URL-HandlerMethod映射)
    - 对应的实现类
        - RequestMappingHandlerMapping 处理@RequestMapping
        - SimpleUrlHandlerMapping 简单的urlMap保存了URL到HttpRequestHandler的映射
        - BeanNameUrlHandlerMapping 将bean的name作为url进行查找，需要在配置Handler时指定bean name，且必须以 / 开头
        - 还可自定义

#### MappingRegistry类说明

```java
public abstract class AbstractHandlerMethodMapping<T> extends AbstractHandlerMapping implements InitializingBean {
    // mappingRegistry主要记录了URL-HandlerMethod(Controller方法)的映射
    private final MappingRegistry mappingRegistry = new MappingRegistry();

    // 内部类
    class MappingRegistry {
        // ...
        private final Map<T, HandlerMethod> mappingLookup = new LinkedHashMap<>();
        private final MultiValueMap<String, T> urlLookup = new LinkedMultiValueMap<>();
        private final ReentrantReadWriteLock readWriteLock = new ReentrantReadWriteLock();

        // 获取映射，参考上文[查找请求对应的Handler对象(Controller)](#查找请求对应的Handler对象(Controller))
        public Map<T, HandlerMethod> getMappings() {
			return this.mappingLookup;
		}

        // 直接通过URL获取映射
		@Nullable
		public List<T> getMappingsByUrl(String urlPath) {
			return this.urlLookup.get(urlPath);
		}

        // 注册URL-HandlerMethod映射
        public void register(T mapping, Object handler, Method method) {
            // Assert that the handler method is not a suspending one.
            if (KotlinDetector.isKotlinType(method.getDeclaringClass())) {
                Class<?>[] parameterTypes = method.getParameterTypes();
                if ((parameterTypes.length > 0) && "kotlin.coroutines.Continuation".equals(parameterTypes[parameterTypes.length - 1].getName())) {
                    throw new IllegalStateException("Unsupported suspending handler method detected: " + method);
                }
            }
            // 加锁
            this.readWriteLock.writeLock().lock();
            try {
                HandlerMethod handlerMethod = createHandlerMethod(handler, method);
                validateMethodMapping(handlerMethod, mapping);
                // 将映射关系保存起来
                this.mappingLookup.put(mapping, handlerMethod);

                List<String> directUrls = getDirectUrls(mapping);
                for (String url : directUrls) {
                    this.urlLookup.add(url, mapping);
                }

                String name = null;
                if (getNamingStrategy() != null) {
                    name = getNamingStrategy().getName(handlerMethod, mapping);
                    addMappingName(name, handlerMethod);
                }

                CorsConfiguration corsConfig = initCorsConfiguration(handler, method, mapping);
                if (corsConfig != null) {
                    this.corsLookup.put(handlerMethod, corsConfig);
                }

                this.registry.put(mapping, new MappingRegistration<>(mapping, handlerMethod, directUrls, name));
            }
            finally {
                // 释放锁
                this.readWriteLock.writeLock().unlock();
            }
        }
    }
}
```

## MVC请求参数解析

- `@RequestParam` 可以获取GET请求、POST请求的Param参数(添加到URL中的参数，无法获取Body中的数据)
- `@RequestBody` 仅适用于获取POST请求的Body数据(可以是json/txt等格式)
- 使用参考：[springboot.md#请求参数字段映射](/_posts/java/springboot.md#请求参数字段映射)

### 类关系

- org.springframework.web.method
    - InvocableHandlerMethod 参数处理器
    - HandlerMethodArgumentResolver 参数解析器
        - RequestParamMethodArgumentResolver 处理 @RequestParam 注解, @RequestPart 注解, Multipart 类型的参数
        - ModelAttributeMethodProcessor
            - ServletModelAttributeMethodProcessor 处理无注解的普通Bean
        - RequestResponseBodyMethodProcessor **处理 @RequestBody 注解的参数**(数据在请求body中，常见的会定义body数据格式为application/json，最终通过 AbstractJackson2HttpMessageConverter 解析)
- org.springframework.web.bind
    - WebDataBinder 解析参数时，对request参数绑定到方法参数中
        - ServletRequestDataBinder
- org.springframework.beans
    - TypeConverterDelegate 类型转换代理
- org.springframework.core
    - GenericConverter 转换器模型接口(实际转换一般通过调用 ConversionService 实现)
    - ConversionService 转换器逻辑接口
        - GenericConversionService
            - addConverter 实现了 ConverterRegistry 接口，**如 WebMvcAutoConfiguration#addFormatters 可添加转换器**
            - FormattingConversionService **处理Bean的Format字段注解**，如：`@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")`(最终通过 TemporalAccessorParser 实现转换)
    - ConverterRegistry 转换器注册接口
- org.springframework.http
    - HttpMessageConverter 接口
        - GenericHttpMessageConverter 接口
            - AbstractJackson2HttpMessageConverter **最终通过 ObjectMapper(可进行自定义映射规则)进行转换**
                - MappingJackson2HttpMessageConverter 通过Jackson解析application/json格式数据

### 流程 [^1]

```java
// 测试方法
@RequestMapping("/hello")
public Result hello(MultipartFile file, Person person) {
    return new Result();
}

// A org.springframework.web.method.support.InvocableHandlerMethod 解析参数
@Nullable
public Object invokeForRequest(NativeWebRequest request, @Nullable ModelAndViewContainer mavContainer, Object... providedArgs) throws Exception {
    // 解析controller的方法(hello)参数
    MethodParameter[] parameters = this.getMethodParameters(); // 获取controller的方法参数列表

    // getMethodParameters 流程如下
    {
        Object[] args = this.getMethodArgumentValues(request, mavContainer, providedArgs); // 获取参数值
        // getMethodArgumentValues 流程如下
        {
            /*
                this.argumentResolvers (属于 HandlerMethodArgumentResolverComposite 类，组合模式，包含多个 HandlerMethodArgumentResolver 解析器) 获取当前类的参数解析器。此次Debug场景有26个，具体见下文注释
                每个解析器实现了 HandlerMethodArgumentResolver 接口的 supportsParameter 方法，来判断是否至此此参数的解析。如下文的 RequestParamMethodArgumentResolver 示例
            */
            if (this.argumentResolvers.supportsParameter(parameter)) // 判断是否有支持的解析器，具体参考B、C类的部分源码
                // 如果请求类型是`multipart/form-data`，则数据是在body体中，当通过拦截器拦截body时，不要拦截此类型的请求，否则后面controller将获取不到数据。
                this.resolvers.resolveArgument(parameter, mavContainer, request, this.dataBinderFactory); // 解析参数，即注入参数值
        }
    }

    /* 上文注释
    HandlerMethodArgumentResolver 接口方法： supportsParameter, resolveArgument
    result = {LinkedList@13410}  size = 26
        0 = {RequestParamMethodArgumentResolver@13502}              ==> @RequestParam，可解析 Multipart 类型参数，但是 Bean 属性为 Multipart 则不会走此解析器
        1 = {RequestParamMapMethodArgumentResolver@13503} 
        2 = {PathVariableMethodArgumentResolver@13504}              ==> @PathVariable
        3 = {PathVariableMapMethodArgumentResolver@13505} 
        4 = {MatrixVariableMethodArgumentResolver@13506} 
        5 = {MatrixVariableMapMethodArgumentResolver@13507} 
        6 = {ServletModelAttributeMethodProcessor@13508}            ==> @ModelAttribute 参考25
        7 = {RequestResponseBodyMethodProcessor@13509}              ==> @RequestBody
        8 = {RequestPartMethodArgumentResolver@13510} 
        9 = {RequestHeaderMethodArgumentResolver@13511}             ==> @RequestHeader
        10 = {RequestHeaderMapMethodArgumentResolver@13512} 
        11 = {ServletCookieValueMethodArgumentResolver@13513} 
        12 = {ExpressionValueMethodArgumentResolver@13514} 
        13 = {SessionAttributeMethodArgumentResolver@13515} 
        14 = {RequestAttributeMethodArgumentResolver@13516} 
        15 = {ServletRequestMethodArgumentResolver@13517}           ==> HttpServletRequest?
        16 = {ServletResponseMethodArgumentResolver@13518} 
        17 = {HttpEntityMethodProcessor@13519} 
        18 = {RedirectAttributesMethodArgumentResolver@13520} 
        19 = {ModelMethodProcessor@13521} 
        20 = {MapMethodProcessor@13522}                             ==> Map?
        21 = {ErrorsMethodArgumentResolver@13523} 
        22 = {SessionStatusMethodArgumentResolver@13524} 
        23 = {UriComponentsBuilderMethodArgumentResolver@13525} 
        24 = {RequestParamMethodArgumentResolver@13526}             ==> @RequestParam
        25 = {ServletModelAttributeMethodProcessor@13527}           ==> @ModelAttribute(包含前端视图对象)，也可以解析无注解的Person等简单Bean (第6个不会解析)
    */

    if (this.logger.isTraceEnabled()) {
        this.logger.trace("Arguments: " + Arrays.toString(args));
    }

    // 调用方法
    return this.doInvoke(args);
}

// B web.method.annotation.RequestParamMethodArgumentResolver 处理 @RequestParam注解, @RequestPart注解, Multipart类型的参数
// 判断此解析器是否支持解析传入参数
public boolean supportsParameter(MethodParameter parameter) {
    // 先判断参数是否被 @RequestParam 修饰
    if (parameter.hasParameterAnnotation(RequestParam.class)) {
        if (!Map.class.isAssignableFrom(parameter.nestedIfOptional().getNestedParameterType())) {
            return true;
        } else {
            RequestParam requestParam = (RequestParam)parameter.getParameterAnnotation(RequestParam.class);
            return requestParam != null && StringUtils.hasText(requestParam.name());
        }
    // @RequestPart
    } else if (parameter.hasParameterAnnotation(RequestPart.class)) {
        return false;
    } else {
        parameter = parameter.nestedIfOptional();
        // 是否为 Multipart 类型参数：MultipartFile/Part、isMultipartFileCollection/isPartCollection、isMultipartFileArray/isPartArray
        // 如果 User 对象的属性包含上述 MultipartFile 等类型时，此解析也不会进行处理
        if (MultipartResolutionDelegate.isMultipartArgument(parameter)) {
            return true;
        } else {
            return this.useDefaultResolution ? BeanUtils.isSimpleProperty(parameter.getNestedParameterType()) : false;
        }
    }
}
// 解析方法参数名。主要基于父类 AbstractNamedValueMethodArgumentResolver 实现
@Nullable
protected Object resolveName(String name, MethodParameter parameter, NativeWebRequest request) throws Exception {
    HttpServletRequest servletRequest = (HttpServletRequest)request.getNativeRequest(HttpServletRequest.class);
    Object arg;
    if (servletRequest != null) {
        // 从servletRequest中提取参数值。name为controller中参数名(在父类 AbstractNamedValueMethodArgumentResolver 中解析获取到的，父类还负责空值处理)
        arg = MultipartResolutionDelegate.resolveMultipartArgument(name, parameter, servletRequest);
        if (arg != MultipartResolutionDelegate.UNRESOLVABLE) {
            return arg;
        }
    }

    arg = null;
    MultipartRequest multipartRequest = (MultipartRequest)request.getNativeRequest(MultipartRequest.class);
    if (multipartRequest != null) {
        List<MultipartFile> files = multipartRequest.getFiles(name);
        if (!files.isEmpty()) {
            arg = files.size() == 1 ? files.get(0) : files;
        }
    }

    if (arg == null) {
        String[] paramValues = request.getParameterValues(name);
        if (paramValues != null) {
            arg = paramValues.length == 1 ? paramValues[0] : paramValues;
        }
    }

    return arg;
}

// C web.method.annotation.ModelAttributeMethodProcessor (ServletModelAttributeMethodProcessor, resolveName 解析主要在父类的 ModelAttributeMethodProcessor 中进行)
@Nullable
public final Object resolveArgument(MethodParameter parameter, @Nullable ModelAndViewContainer mavContainer, NativeWebRequest webRequest, @Nullable WebDataBinderFactory binderFactory) throws Exception {
    // ...
    if (mavContainer.containsAttribute(name)) {
        attribute = mavContainer.getModel().get(name);
    } else {
        try {
            // 构建绑定对象(Bean)，获取构造函数方式顺序
            // Constructor<?> ctor = BeanUtils.findPrimaryConstructor(clazz); // 通过BeanUtils获取主要的构造函数
            // Constructor<?>[] ctors = clazz.getConstructors(); // 尝试获取声明为public的无参构造函数
            // ctor = clazz.getDeclaredConstructor(); // 尝试使用getDeclaredConstructor获取所有的无参构造函数
            attribute = this.createAttribute(name, parameter, binderFactory, webRequest);
        }
        // ...
    }

    if (bindingResult == null) {
        WebDataBinder binder = binderFactory.createBinder(webRequest, attribute, name);
        if (binder.getTarget() != null) {
            if (!mavContainer.isBindingDisabled(name)) {
                // 最终调用 web.bind.ServletRequestDataBinder 类进行数据绑定到 Bean
                this.bindRequestParameters(binder, webRequest);
            }
            // ...
        }
        // ...
    }
    // ...
    return attribute;
}

// D web.servlet.mvc.method.annotation.ServletModelAttributeMethodProcessor
protected void bindRequestParameters(WebDataBinder binder, NativeWebRequest request) {
    ServletRequest servletRequest = (ServletRequest)request.getNativeRequest(ServletRequest.class);
    Assert.state(servletRequest != null, "No ServletRequest");
    // 绑定数据
    ServletRequestDataBinder servletBinder = (ServletRequestDataBinder)binder;
    servletBinder.bind(servletRequest);
}
// E web.bind.ServletRequestDataBinder
public void bind(ServletRequest request) {
    // 将request中的参数和值简单的提取出来
    MutablePropertyValues mpvs = new ServletRequestParameterPropertyValues(request);
    MultipartRequest multipartRequest = (MultipartRequest)WebUtils.getNativeRequest(request, MultipartRequest.class);
    if (multipartRequest != null) {
        // 如果存在 Multipart 数据，则先提取 Multipart 数据到 mpvs
        this.bindMultipart(multipartRequest.getMultiFileMap(), mpvs);
    }

    this.addBindValues(mpvs, request);
    // E.1 绑定到 Bean 上
    // this.applyPropertyValues(MutablePropertyValues mpvs)
        // this.getPropertyAccessor().setPropertyValues(mpvs, this.isIgnoreUnknownFields(), this.isIgnoreInvalidFields());
            // beans.AbstractNestablePropertyAccessor#setPropertyValue(PropertyValue pv)
                // this.convertForProperty(tokens.canonicalName, oldValue, originalValue, ph.toTypeDescriptor()); // 基于转换器数据转换
                    // this.typeConverterDelegate.convertIfNecessary() // 参考 beans.TypeConverterDelegate
    this.doBind(mpvs);
}
// E.1 beans.TypeConverterDelegate
public <T> T convertIfNecessary(@Nullable String propertyName, @Nullable Object oldValue, @Nullable Object newValue, @Nullable Class<T> requiredType, @Nullable TypeDescriptor typeDescriptor) throws IllegalArgumentException {
    PropertyEditor editor = this.propertyEditorRegistry.findCustomEditor(requiredType, propertyName);
    ConversionFailedException conversionAttemptEx = null;
    // E.1.1 获取数据类型转换器，此次Debug场景大概100多个
    ConversionService conversionService = this.propertyEditorRegistry.getConversionService();
    if (editor == null && conversionService != null && newValue != null && typeDescriptor != null) {
        TypeDescriptor sourceTypeDesc = TypeDescriptor.forObject(newValue);
        // 判断是否可以进行转换，如 String -> BigDecimal
        if (conversionService.canConvert(sourceTypeDesc, typeDescriptor)) {
            try {
                // 调用转换方法
                // GenericConverter converter = this.getConverter(sourceType, targetType);
                    // converter = this.converters.find(sourceType, targetType); // 查找转换器
                return conversionService.convert(newValue, sourceTypeDesc, typeDescriptor);
            } catch (ConversionFailedException var14) {
                conversionAttemptEx = var14;
            }
        }
    }
    // ...
}

// F web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor 解析 @RequestBody 注解参数 
public Object resolveArgument(MethodParameter parameter, @Nullable ModelAndViewContainer mavContainer, NativeWebRequest webRequest, @Nullable WebDataBinderFactory binderFactory) throws Exception {
    parameter = parameter.nestedIfOptional();
    // 通过转换器读取参数值
    // AbstractMessageConverterMethodArgumentResolver#readWithMessageConverters
        // body = genericConverter != null ? genericConverter.read(targetType, contextClass, msgToUse) : converter.read(targetClass, msgToUse);
            // AbstractJackson2HttpMessageConverter#readJavaType
                // this.objectMapper.readValue(inputMessage.getBody(), javaType); // 最终通过 ObjectMapper(可进行自定义)进行转换
    Object arg = this.readWithMessageConverters(webRequest, parameter, parameter.getNestedGenericParameterType());
    // ...
}
```





---

参考文章

[^1]: https://blog.teble.me/2019/11/05/SpringBoot-LocalDateTime-%E5%90%8E%E7%AB%AF%E6%8E%A5%E6%94%B6%E5%8F%82%E6%95%B0%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5/
[^2]: https://www.jianshu.com/p/3450e3a764aa









