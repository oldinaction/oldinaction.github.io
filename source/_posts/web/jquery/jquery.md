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
})
```

## ajax

```js
$.ajax({
    type: "POST", // GET(默认)、POST
    url: "/api/getWeather",
    // async: false, // 是否异步调用，默认true
    data: {
        zipcode: 97201
    },
    success: function( result ) {
        $( "#weather-temp" ).html( "<strong>" + result + "</strong> degrees" );
    }
});
```


