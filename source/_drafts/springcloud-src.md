---
layout: "post"
title: "SpringCloud源码分析"
date: "2019-07-04 11:20"
categories: [java]
tags: [SpringCloud, src]
---

## Zuul(Gateway网关)

```java
// ## Core Zuul servlet which intializes and orchestrates zuulFilter execution（核心Zuul servlet，用于初始化和编排zuulFilter的执行）
public class ZuulServlet extends HttpServlet {} // com.netflix.zuul.http.ZuulServlet

// ## This the the core class to execute filters（执行所有定义的Zuul Filter）. 单例
public class FilterProcessor { // com.netflix.zuul.FilterProcessor
    // 基于类型获取Zuul Filter
    public Object runFilters(String sType) throws Throwable {}
    // 执行
    public Object processZuulFilter(ZuulFilter filter) throws ZuulException {}
}

// ## Spring Cloud Ribbon路由（重定向到目标服务逻辑）
public class RibbonRoutingFilter extends ZuulFilter { // org.springframework.cloud.netflix.zuul.filters.route.RibbonRoutingFilter
    public boolean shouldFilter() {
        RequestContext ctx = RequestContext.getCurrentContext();
        return ctx.getRouteHost() == null && ctx.get("serviceId") != null && ctx.sendZuulResponse();
    }
    public String filterType() {return "route";}
    // 级别为10之前的Filter的会在重定向之前执行（相当于pre filter），级别为10之后的则相当于post filter
    public int filterOrder() {return 10;}

    public Object run() {
        RequestContext context = RequestContext.getCurrentContext();
        this.helper.addIgnoredHeaders(new String[0]);

        try {
            RibbonCommandContext commandContext = this.buildCommandContext(context);
            // 重定向(路由)到某个服务。内部执行的为 RibbonCommand#execute
            ClientHttpResponse response = this.forward(commandContext);
            // 将结果保存在 com.netflix.zuul.context.RequestContext 的 ThreadLocal 对象中
            this.setResponse(response);
            return response; // 此返回的结果Zuul暂时未处理
        }
    }
}
```


