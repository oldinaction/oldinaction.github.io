---
layout: "post"
title: "Layui"
date: "2017-11-30 20:19"
categories: web
tags: [UI, jquery]
---

## 简介

- 基于jquery的前端 UI 框架
- 官网：[http://www.layui.com/](http://www.layui.com/)

## 全局

- 引入核心css和js

```html
<link rel="stylesheet" href="layui.css" media="all" />
<script type="text/javascript" src="layui.js"></script>
```

## 表单元素

- `layui-form`类下的select等才会被渲染成layui下拉样式

```html
<!-- `layui-form`类下的select等才会被渲染成layui样式 -->
<div class="layui-form" lay-filter="selFilter">
    <label class="layui-form-label">状态</label>
    <div class="layui-input-inline">
        <select id="checkStatus" name="checkStatus" lay-filter="checkStatusFilter">
            <option value="">全部</option>
            <option value="1">通过</option>
            <option value="2">未通过</option>
        </select>
    </div>
</div>

<script type="text/javascript">
    layui.use(['form', 'jquery'], function() {
        var form = layui.form
            $ = layui.jquery;

        // 对下拉赋值
        $("#checkStatus").val('123');
        
        // 对单选赋值
        $("input[name='sex'][value = '" + user.sex + "']").prop("checked", true);

        // 对多选赋值
        $("select[name='roleCode']").val(user.roleCode);

        // radio/checkbox/select值改变后，必须要重新渲染 (文本input无需)
        form.render();
        // 局部刷新需要使用`lay-filter`
        // form.render('select', 'selFilter');

        // 事件监听
        form.on('select(checkStatusFilter)', function (data) {
            console.log(data.value); // 下拉当前值
        })
    });
</script>
``` 
