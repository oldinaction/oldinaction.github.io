---
layout: "post"
title: "html"
date: "2016-04-16 15:37"
categories: [web]
tags: [html]
---

## HTML5新特性

### 表单验证

```html
<form id="forms" action="" method="post" enctype="multipart/form-data">
    <div class="form-group">
        <label class="control-label" for="input-email">店铺名称</label>
        <input type="text" required="required" class="form-control" />
    </div>
    <div class="form-group">
        <label class="control-label" for="input-email">店铺介绍</label>
        <input type="text" required="required" class="form-control" />
    </div>
</form>
<script>
$(function () {
    var form = document.getElementById("forms");
    var submitBtn = document.getElementById("submitBtn");
    submitBtn.addEventListener("click", function() {
        var invalidFields = form.querySelectorAll(":invalid");
        if(invalidFields.length == 0) {
            alert('必填项已全部填写')
        }
    });
})
</script>
```

## HTML实用标签

1. 缩略语: `<abbr title="attribute">attr</abbr>` <abbr title="省略的话">...</abbr>
2. 缩进: `&emsp;`全角缩进；`&ensp;`半角缩进
3. 引用标记: `<blockquote></blockquote>`

<blockquote>这是引用标记的示例</blockquote>

4. 带描述的无序列表

```html
<dl>
    <dt>ABC</dt>
    <dd>123</dd>
    <dd>456</dd>
    <dt>DEF</dt>
    <dd>789</dd>
</dl>
```
- 效果

<dl>
    <dt>ABC</dt>
    <dd>123</dd>
    <dd>456</dd>
    <dt>DEF</dt>
    <dd>789</dd>
</dl>

5. 键盘输入效果`<kbd><kbd>ctrl</kbd> + <kbd>,</kbd></kbd>` 效果：<kbd><kbd>ctrl</kbd> + <kbd>S</kbd></kbd>
6. `<code></code>`和`<pre></pre>`的区别，效果如下

<code>&lt;code...&gt;</code>
<pre>&lt;pre...&gt;</pre>

7.title属性换行

```html
<!-- 排版不好看 -->
<span title="第一行
第二行">内容</span>

<!-- vue -->
<span :title="`第一行\n第二行`">内容</span> 

<!-- 使用 &#10; 或 &#13;, 测试无效 -->
<span title="第一行&#10;第二行">内容</span> 
```

## HTML模板

```html
<!doctype html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<title>html模板</title>
		<meta name="keywords" content="关键词,关键词">
		<meta name="description" content="">

		<!--css,js-->
		<style type="text/css">
			*{margin:0;padding:0;}
		</style>
	</head>
<body>


<script type="text/javascript">
	
</script>
</body>
</html>
```

## 案例

### 横向文字公告效果

```html
<!-- 公告 START -->
<style>
    #scroll_div {
        height: 28px;
        overflow: hidden;
        white-space: nowrap;
        width: 800px;
        top: 4px;
        background-color: #fff;
        color: red;
        margin: 1rem 0rem;
        text-align: center;
        position: absolute;
        left: calc(50% - 370px);
        font-size: 20px;
    }
    #scroll_div .item {
        padding-right: 20px;
    }
    #scroll_div .item a {
        text-decoration: underline;
        font-size: 20px !important;
        color: red !important;
    }
    #scroll_begin,#scroll_end {
        display: inline;
    }
</style>
<div id="scroll_div" class="fl">
    <div id="scroll_begin">
        <span class="item">
            <a href="https://www.baidu.com/" target="_blank">1.点击我进入百度</a>
        </span>
        <span class="item">2.这是公告2哦，会横向滚动</span>
    </div>
    <div id="scroll_end"></div>
</div>
<script type="text/javascript">
    //文字横向滚动
    function ScrollImgLeft(){
    var speed=50;//初始化速度 也就是字体的整体滚动速度
    var MyMar = null;//初始化一个变量为空 用来存放获取到的文本内容
    var scroll_begin = document.getElementById("scroll_begin");//获取滚动的开头id
    var scroll_end = document.getElementById("scroll_end");//获取滚动的结束id
    var scroll_div = document.getElementById("scroll_div");//获取整体的开头id
    scroll_end.innerHTML=scroll_begin.innerHTML;//滚动的是html内部的内容,原生知识!
    //定义一个方法
    function Marquee(){
        if(scroll_end.offsetWidth-scroll_div.scrollLeft<=0)
        scroll_div.scrollLeft-=scroll_begin.offsetWidth;
        else
        scroll_div.scrollLeft++;
    }
    MyMar=setInterval(Marquee,speed);//给上面的方法设置时间  setInterval
    //鼠标点击这条公告栏的时候,清除上面的方法,让公告栏暂停
    scroll_div.onmouseover = function(){
        clearInterval(MyMar);
    }
    //鼠标点击其他地方的时候,公告栏继续运动
    scroll_div.onmouseout = function(){
        MyMar = setInterval(Marquee,speed);
    }
    }
    ScrollImgLeft();
</script>
<!-- 公告 END -->
```
