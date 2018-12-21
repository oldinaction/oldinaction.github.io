---
layout: "post"
title: "thymeleaf"
date: "2017-10-22 11:41"
categories: [lang]
tags: [thymeleaf, java, springboot, template]
---

## 简介

## 上下文数据获取

- 常用上下文获取

```html
<!-- html页面取值. [[1, 2, 3]]再js中容易导致渲染出错，可在中间加空格，如 [ [1, 2, 3] ] -->
[[${myVar}]]

<!-- 获取url参数 -->
<span th:text="${#httpServletRequest.getParameter('roleCode')}">这里的文字会被替换</span>

<!-- 定义变量并取值 -->
<div th:with="curPage=${#httpServletRequest.getParameter('page')}">
    <h3>当前页码：<span th:text="${curPage}"></span></h3>
</div>

<!-- 被|包裹的变量会转换后和字符串进行拼接。@{...}为链接表达式 -->
<a href="" th:href="@{|/user/${user.id}|}">链接地址</a> 

<!-- map取值 -->
<span th:text="${myMap['key']}"></span>
```
- 自定义全局静态对象

```java
@Resource(name="thymeleafViewResolver")
ThymeleafViewResolver thymeleafViewResolver;

// 注入数据
Map<String, Object> context = new HashMap();
context.put("username", "smalle");
thymeleafViewResolver.setStaticVariables(context);

// 取值
[[${username}]]
```

- 内置对象

    ```html
    <!-- 获取集合myList大小，lists为内置对象 -->
    <span th:text="${#lists.size(myList)}"></span>
    <!-- 日期格式化，dates为内置对象 -->
    <span th:text="${#dates.format(curDate, 'yyyy-MM-dd HH:mm:ss')}"></span>
    <!-- 数字格式化，保留两位小数位 -->
    <span th:text="${#numbers.formatDecimal(money, 0, 2)}"></span>
    ```
    - `dates`：日期格式化内置对象，具体方法可以参照java.util.Date
    - `calendars`：类似于#dates，但是是java.util.Calendar类的方法
    - `numbers`： 数字格式化
    - `strings`：字符串格式化，具体方法可以参照java.lang.String，如startsWith、contains等
    - `objects`：参照java.lang.Object
    - `bools`：判断boolean类型的工具
    - `arrays`：数组操作的工具
    - `lists`：列表操作的工具，参照java.util.List
    - `sets`：Set操作工具，参照java.util.Set
    - `maps`：Map操作工具，参照java.util.Map
    - `aggregates`：操作数组或集合的工具
    - `messages`：操作消息的工具
    - 上述变量设值如下

        ```java
        @Controller
        public class IndexController {

            @GetMapping(value = "index")
            public String index(Model model, HttpServletRequest request) {
                List<String> myList = new ArrayList<String>();
                myList.add("smalle");
                myList.add("18");

                model.addAttribute("myList", myList);
                model.addAttribute("curDate", new Date());
                model.addAttribute("money", Math.random()*100);
                return "index";
            }
        }
        ```
- html/js/css取值

```html
<script th:inline="javascript">
    var size = [[${list.size()}]];
    console.info(size);
</script>

<style th:inline="css">
.[[${classname}]] {
    text-align: [[${align}]];
}
</style>
```

## 流程控制

```html
<!-- gt lt eq ne ge le > < == != -->
<input th:if="${#httpServletRequest.getParameter('roleCode')} eq 'ADMIN'" 
    type="radio" name="bannerType" value="IndexBanner"/>

<!-- 逻辑控制 -->
<td th:if="${user.name} == 'smalle' and ${user.age} == 18">hello</td>

<!-- 循环 -->
<tr th:each="user:${users}">
    <td th:switch="${user.male}">
        <span th:case="1">男</span>
        <span th:case="2">女</span>
        <!--其他情况-->
        <span th:case="*">未知</span>
    </td>
</tr>
<!-- 判断循环下标。th:block是一个空标签不会影响样式 -->
<th:block th:each="item,iterStat:${list}">
    <th:block th:if="${iterStat.index le 1}">
        <!--显示集合前两个元素-->
        <span th:text="${item}"></span>
    </th:block>
</th:block>

<!-- 循环，自定义变量，三元运算符，字符串可直接==比较 -->
<div class="layui-row">
    <!-- 数组为空也不报错 -->
    <div th:each="item:${accessDbInfos}"
            th:with="runStatusClass=${item.getRunStatus() == '1' ? 'layui-green' : (item.getRunStatus() == '2' ? 'layui-orange' : 'layui-red')}"
            class="layui-col-md2 computer">
        <i th:classappend="${runStatusClass}" class="layui-icon layui-icon-chart-screen"></i>
        <div>
            <i th:classappend="${runStatusClass}" class="layui-icon layui-icon-circle-dot"></i>
            <span>IPxxx: <span th:text="${item.getIp()}"></span></span>
        </div>
    </div>
</div>
```

## 页面布局

- layout.hmtl(如路径为：templates/includes/layout.hmtl)

```html
<!DOCTYPE html>
<!-- thymeleaf模板必须引用xmlns:th -->
<html lang="zh-CN" xmlns:th="http://www.thymeleaf.org"
    xmlns:layout="http://www.ultraq.net.nz/web/thymeleaf/layout">

<head>
    <meta charset="utf-8">
    <title>AEZO.CN</title>
</head>

<body>
    <div layout:fragment="content"></div>
</body>
</html>
```
- 引用

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org"
    xmlns:layout="http://www.ultraq.net.nz/web/thymeleaf/layout"
    layout:decorate="includes/layout">

<div layout:fragment="content">
    hello
</div>
</html>
```