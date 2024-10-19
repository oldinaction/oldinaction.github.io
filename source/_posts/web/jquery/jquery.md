---
layout: "post"
title: "JQuery"
date: "2019-08-05 10:13"
tags: [jquery]
---

## 简介

- 在线文档：https://tool.oschina.net/apidocs/apidoc?api=jquery

## 选择器

- `parents()`将查找所有祖辈元素，而`children()`只考虑子元素而不考虑所有后代元素

## 事件

```js
$(function() {
    // 等待页面加载完后，通过body代理监听元素点击事件，并获取点击元素的data-href属性值，在新标签页显示
    $("body").delegate(".cat-list-items>.row>.col-md-4", 'click', function() {
        var href = $(this).data('href')
        if(href) {
            window.open(href, '_blank');
        }
    })

    // 表单提交
    $('#submitBtn').click(function(e) {
        let data = {};
        let value = $('#form').serializeArray();
        $.each(value, function (index, item) {
            data[item.name] = item.value;
        });

        let json = $('#form').serialize(); // 输出：name=asd&type=1

        // 组装原生表单提交
        return false;
    });
})
```

## ajax

```js
$.ajax({
    type: "POST", // GET(默认)、POST
    url: "/api/getWeather",
    timeout: 1000*60,
    // async: false, // 是否异步调用，默认true
    // 默认数据格式为 application/x-www-form-urlencoded
    data: {
        zipcode: 97201
    },
    success: function( result ) {
        $( "#weather-temp" ).html( "<strong>" + result + "</strong> degrees" );
    }
});

// 以 application/json 传递数据
jQuery.ajax({
    url: "http://localhost:8080/api/test",
    type: "post",
    async: false,
    contentType: 'application/json',
    data: JSON.stringify({"pageCurrent":1, "pageSize":100}),
    success: function(data) {
        console.log(data);
    }
});
```

## 常见案例

### 防止重复点击

- https://www.yisu.com/zixun/476111.html

### 简单loading效果

- https://blog.csdn.net/m0_57217156/article/details/123916128
    - loading图片可直接下载文章中的
