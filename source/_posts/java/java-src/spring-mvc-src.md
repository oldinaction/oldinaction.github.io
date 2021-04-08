---
layout: "post"
title: "Spring MVC源码解析"
date: "2020-09-08 09:25"
categories: [java]
tags: [spring, src]
---

## MVC请求参数解析

- `@RequestParam` 可以获取GET请求、POST请求的Param参数(添加到URL中的参数，无法获取Body中的数据)
- `@RequestBody` 仅适用于获取POST请求的Body数据(可以是json/txt等格式)
- 使用参考：[springboot.md#请求参数字段映射](/_posts/java/springboot.md#请求参数字段映射)
- 关键类：**`DispatcherServlet#doDispatch`**
- SpringMVC 的整个请求流程

![springmvc-flow](/data/images/java/springmvc-flow.png)

## 类关系

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

## 流程 [^1]

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










