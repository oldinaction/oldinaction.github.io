---
layout: "post"
title: "jquery"
date: "2019-08-05 10:13"
---

## 简介

- 在线文档：https://tool.oschina.net/apidocs/apidoc?api=jquery

## 选择器

- `parents()`将查找所有祖辈元素，而`children()`只考虑子元素而不考虑所有后代元素

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


