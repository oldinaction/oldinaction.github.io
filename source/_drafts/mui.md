---
layout: "post"
title: "MUI"
date: "2017-11-24 20:30"
categories: [web]
tags: [UI, H5, App]
---

## mui简介


## mui零散知识

- H5底部导航跳转

```html
<nav class="mui-bar mui-bar-tab">
	<a data-href="index.html" class="mui-tab-item" href="javascript:;">
		<span class="mui-icon mui-icon-home"></span>
		<span class="mui-tab-label">首页</span>
	</a>
	<a data-href="#" class="mui-tab-item" href="javascript:;">
		<span class="mui-icon mui-icon-contact"></span>
		<span class="mui-tab-label">活动</span>
	</a>
	<a data-href="home.html" class="mui-tab-item mui-active" href="javascript:;">
		<span class="mui-icon mui-icon-contact"></span>
		<span class="mui-tab-label">我的</span>
	</a>
</nav>
```

```js
// 菜单点击
var pageTabs = document.getElementsByClassName("mui-tab-item");
for(var i=0; i < pageTabs.length; i++) {
	pageTabs[i].addEventListener('tap', function(event) {
		window.location.href = this.getAttribute("data-href");
	}, false);
}
```

- popover弹框、scroll滚动
    - popover参数二为锚点元素(`anchorElement`)，标识弹框是基于某个元素的。如果

```html
<div id="popover" class="mui-popover"><!--默认隐藏, dom在body下即可-->
    <div class="mui-scroll-wrapper">
        <div class="mui-scroll">
            <div style="padding: 10px;"><!--mui-scroll下是真实dom，需要里面元素有padding则需要调解此div-->
                这里是内容
            </div>
        </div>
    </div>
</div>
```

```js
(function(mui, window, document, undefined) {
    mui.init();

    // 初始化滚动条
    mui('.mui-scroll-wrapper').scroll({});

    // 当mybtn按钮被点击时，弹框显示隐藏切换
    document.getElementById("mybtn").addEventListener('tap', function(event) {
        mui("#popover").popover("toggle", document.getElementById("popoverRef")); // 如果弹框居中，则只需要参考popoverRef元素为居中
    });
})(mui, window, document, undefined);
```

```css
#popover {
	height: 500px;
	width: 85%;
	/*
    display: block;
    top: 0px;
    left: 5%;
    overflow: auto;
	*/
}
```

- 图片上传，下列方法可解决mui示例中h5页面拍照无法上传问题(缺点：上传到后台无法记录文件类型，无文件后缀)
    - 利用canvas将图片转成base64并压缩 -> 将base64的dataUrl转成Blob -> 将Blob放入到FormData -> xhr

```js
// =======
// 图片上传: 利用canvas将图片转成base64并压缩 -> 将base64的dataUrl转成Blob -> 将Blob放入到FormData -> xhr
// =======
/*
	var smImg = new SmUploadImg();
	smImg.init({
		inputs: document.getElementById(".sm-input__img"),
		callback: function(base64, target) {
			// formData.append(target.id, this.dataUrltoBlob(base64));
		}
	});
 */
SmUploadImg = function() {
    this.sw = 0;   
    this.sh = 0;   
    this.tw = 0;   
    this.th = 0;   
    this.scale = 0;   
    this.maxWidth = 0;   
    this.maxHeight = 0;   
    this.maxSize = 0;   
    this.fileSize = 0;   
    this.fileDate = null;   
    this.fileType = '';   
    this.fileName = '';   
    this.inputs = null;
    this.canvas = null;   
    this.mime = {};   
    this.type = '';
    this.target = null;
    this.toastr = null;
    this.callback = function () {};
    this.loading = function () {};
};

/**   
 * @description 初始化对象
 */
SmUploadImg.prototype.init = function(options) {
	this.maxWidth = options.maxWidth || 800;
	this.maxHeight = options.maxHeight || 600;
	this.maxSize = options.maxSize || 5 * 1024 * 1024; // 图最大大小(5M)
	this.inputs = options.inputs; // 文件输入框(可多个)
	this.mime = {
		'png': 'image/png',
		'jpg': 'image/jpeg',
		'jpeg': 'image/jpeg',
		'bmp': 'image/bmp'
	};
	// 提示函数
	this.toastr = options.toastr || null;
	// 图片加载完后返回base64
	this.callback = options.callback || function() {};
	// 读取图片时调用
	this.loading = options.loading || function() {
		// console.log("loading...");
	};

	this._addEvent();
};

/**   
 * @description 将base64的dataUrl转换成Blob对象
 */
SmUploadImg.prototype.dataUrltoBlob = function(dataurl) {	
    var arr = dataurl.split(','), mime = arr[0].match(/:(.*?);/)[1],
        bstr = atob(arr[1]), n = bstr.length, u8arr = new Uint8Array(n);
    while(n--){
        u8arr[n] = bstr.charCodeAt(n);
    }
    return new Blob([u8arr], {type:mime});
};

/**
 * 为新加入Dom的元素绑定事件
 * @param {Object} inputs
 */
SmUploadImg.prototype.addInputs = function(inputs) {
    this._addEvent(inputs);
};

/**   
 * @description 绑定事件   
 * @param {Object} elm 元素   
 * @param {Function} fn 绑定函数   
 */
SmUploadImg.prototype._addEvent = function(inputs) {
	var _this = this;

	function tmpSelectFile(ev) {
		_this._handelSelectFile(ev);
	}

	if(!inputs) 
		inputs = _this.inputs;
	if(inputs.length || inputs.length == 0) {
		for(var i=0; i < inputs.length; i++) {
			inputs[i].addEventListener('change', tmpSelectFile, false);
		}
	} else if(inputs) {
		inputs.addEventListener('change', tmpSelectFile, false);
	}
};

/**  
 * @description 绑定事件  
 * @param {Object} elm 元素  
 * @param {Function} fn 绑定函数  
 */
SmUploadImg.prototype._handelSelectFile = function(ev) {
	var file = ev.target.files[0];

	this.type = file.type;
	this.target = ev.target;

	// 如果没有文件类型，则通过后缀名判断（解决微信及360浏览器无法获取图片类型问题）   
	if(!this.type) {
		this.type = this.mime[file.name.match(/\.([^\.]+)$/i)[1]];
	}

	if(!/image.(png|jpg|jpeg|bmp)/.test(this.type)) {
		var msg = '不支持此文件类型';
		this.toastr ? this.toastr(msg) : alert(msg);
		this.target.value = "";
		return;
	}

	if(file.size > this.maxSize) {
		var msg = '选择文件大于' + this.maxSize / 1024 / 1024 + 'M，请重新选择';
		this.toastr ? this.toastr(msg) : alert(msg);
		this.target.value = "";
		return;
	}

	this.fileName = file.name;
	this.fileSize = file.size;
	this.fileType = this.type;
	this.fileDate = file.lastModifiedDate;

	this._readImage(file);
};

/**  
 * @description 读取图片文件  
 * @param {Object} image 图片文件  
 */
SmUploadImg.prototype._readImage = function(file) {
	var _this = this;

	function tmpCreateImage(uri) {
		_this._createImage(uri);
	}

	this.loading();

	this._getURI(file, tmpCreateImage);
};

/**  
 * @description 通过文件获得URI  
 * @param {Object} file 文件  
 * @param {Function} callback 回调函数，返回文件对应URI  
 * return {Bool} 返回false  
 */
SmUploadImg.prototype._getURI = function(file, callback) {
	var reader = new FileReader();
	var _this = this;

	function tmpLoad() {
		// 头不带图片格式，需填写格式   
		var re = /^data:base64,/;
		var ret = this.result + '';

		if(re.test(ret))
			ret = ret.replace(re, 'data:' + _this.mime[_this.fileType] + ';base64,');

		callback && callback(ret, this.target);
	}

	reader.onload = tmpLoad;

	reader.readAsDataURL(file);

	return false;
};

/**  
 * @description 创建图片  
 * @param {Object} image 图片文件  
 */
SmUploadImg.prototype._createImage = function(uri) {
	var img = new Image();
	var _this = this;

	function tmpLoad() {
		_this._drawImage(this);
	}

	img.onload = tmpLoad;

	img.src = uri;
};

/**  
 * @description 创建Canvas将图片画至其中，并获得压缩后的文件  
 * @param {Object} img 图片文件  
 * @param {Number} width 图片最大宽度  
 * @param {Number} height 图片最大高度  
 * @param {Function} callback 回调函数，参数为图片base64编码  
 * return {Object} 返回压缩后的图片  
 */
SmUploadImg.prototype._drawImage = function(img, callback) {
	this.sw = img.width;
	this.sh = img.height;
	this.tw = img.width;
	this.th = img.height;

	this.scale = (this.tw / this.th).toFixed(2);

	if(this.sw > this.maxWidth) {
		this.sw = this.maxWidth;
		this.sh = Math.round(this.sw / this.scale);
	}

	if(this.sh > this.maxHeight) {
		this.sh = this.maxHeight;
		this.sw = Math.round(this.sh * this.scale);
	}

	this.canvas = document.createElement('canvas');
	var ctx = this.canvas.getContext('2d');

	this.canvas.width = this.sw;
	this.canvas.height = this.sh;

	ctx.drawImage(img, 0, 0, img.width, img.height, 0, 0, this.sw, this.sh);

	this.callback(this.canvas.toDataURL(this.type), this.target);

	ctx.clearRect(0, 0, this.tw, this.th);
	this.canvas.width = 0;
	this.canvas.height = 0;
	this.canvas = null;
};
```