---
layout: "post"
title: "Layui"
date: "2017-11-30 20:19"
categories: [web]
tags: [UI, jquery]
---

## 简介

- 基于jquery的前端 UI 框架
- 官网：[http://www.layui.com/](http://www.layui.com/)

## 表单

- select渲染：`layui-form`类下的select才会被渲染

    ```html
    <div class="layui-form">
        <label class="layui-form-label">状态</label>
        <div class="layui-input-inline">
            <select id="checkStatus" name="checkStatus">
                <option value="">全部</option>
                <option value="1">通过</option>
                <option value="2">未通过</option>
            </select>
        </div>
    </div>
    ```
