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

1. 缩略语`<abbr title="attribute">attr</abbr>` <abbr title="省略的话">...</abbr>
2. 缩进 `&emsp;`全角缩进；`&ensp;`半角缩进
3. 引用标记 `<blockquote></blockquote>`

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
