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
<!-- `layui-form`类下的select等才会被渲染成layui样式，且必须引入 form 模块 -->
<div class="layui-form" lay-filter="selFilter">
    <!-- class="layui-form-label" 则文字右对齐 -->
    <label class="layui-inline">状态</label>
    <div class="layui-inline">
        <select id="checkStatus" name="checkStatus" lay-filter="checkStatusFilter">
            <option value="">全部</option>
            <option value="1">通过</option>
            <option value="2">未通过</option>
            <!-- <option th:value="${item.TEMPLATE_ID}" th:text="${item.TEMPLATE_NAME}"></option> -->
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
            doSomething(data.value);
        });
        $(function() {
            // 加载完后就触发下拉事假
            $("#checkStatus").change(function() {
                doSomething({value: $("#checkStatus").val()})
            });
            $("#checkStatus").trigger('change');
        });
        function doSomething(data) {
            console.log(data);
        }
    });
</script>
``` 

## 组件

### 上传组件

```html
<div class="layui-form">
    <div class="layui-form-item">
        <label class="layui-form-label">模板名称</label>
        <div class="layui-input-block">
            <input type="text" name="templateName" placeholder="请输入模板名称" autocomplete="off" class="layui-input">
        </div>
    </div>
    <div class="layui-form-item">
        <label class="layui-form-label">模板文件</label>
        <div class="layui-input-block">
            <button type="button" class="layui-btn" id="upload">
                <i class="layui-icon">&#xe67c;</i>上传zip压缩包
            </button>
            <!--
            <div style="width:200px;height:200px;border:3px solid #0099CC;border-radius: 5px;padding: 3px;">
                <img style="max-width: 200px;max-height:200px;" id="preview">
            </div>-->
        </div>
    </div>
    <div class="layui-form-item">
        <div class="layui-input-block">
            <button class="layui-btn" id="commit">立即提交</button>
        </div>
    </div>
</div>

<script>
    layui.use(['form', 'upload', 'layer'], function(){
        var form = layui.form,
            layer = layui.layer,
            upload = layui.upload,
            $ = layui.jquery;

        upload.render({
            elem: '#upload',
            url: '/api/editTemplate',
            auto: false, // 选择文件后不自动上传
            accept: 'file',
            bindAction: '#commit',
            // 上传前的回调
            before: function () {
                // 携带其他参数。springboot接受如：public Object editTemplate(@RequestParam("file") MultipartFile file, String templateName) {}
                this.data = {
                    templateName: $('input[name="templateName"]').val()
                }
            },
            // 选择文件后的回调
            // choose: function (obj) {
            //     obj.preview(function (index, file, result) {
            //         $('#preview').attr('src', result);
            //     })
            // },
            // 操作成功的回调
            done: function (res, index, upload) {
                var code = res.metaStatus === "success" ? 1 : 2;
                layer.alert(res.metaMessage, {icon: code}, function () {
                    parent.window.location.reload();
                })
            },
            // 上传错误回调
            error: function (index, upload) {
                layer.alert('上传失败！' + index);
            }
        });
    });
</script>
```
