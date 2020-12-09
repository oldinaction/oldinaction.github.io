---
layout: "post"
title: "JS Tools"
date: "2020-10-9 15:18"
categories: js
tags: tools
---

## 库说明

- `babel` 是一个转码器，可以将es6，es7转为es5代码。Babel默认只转换新的JavaScript句法（syntax），而不转换新的API，比如Iterator、Generator、Set、Maps、Proxy、Reflect、Symbol、Promise等全局对象，以及一些定义在全局对象上的方法（比如Object.assign）都不会转码，所以为了使用完整的 ES6 的API，我们需要另外安装：babel-polyfill 或者 babel-runtime [^1]
    - `babel-polyfill` 会把全局对象统统覆盖一遍，不管你是否用得到。缺点：包会比较大100k左右。如果是移动端应用，要衡量一下。一般保存在dependencies中
    - `babel-runtime` 可以按照需求引入。缺点：覆盖不全。一般在写库的时候使用。建议不要直接使用babel-runtime，因为transform-runtime依赖babel-runtime，大部分情况下都可以用`transform-runtime`来达成目的
        - 在babel的配置文件 `.babelrc` 中配置了`"plugins": ["transform-runtime"]`后，就不用再手动单独引入某个 `core-js/*` 特性，如 core-js/features/promise，因为转换时会自动加上而且是根据需要只抽离代码里需要的部分
    - `babel-cli` 在命令行中使用babel命令对js文件进行转换。如`babel entry.js --out-file out.js`进行语法转换
- [core-js](https://github.com/zloirock/core-js) 是 babel-polyfill、babel-runtime 的核心包，他们都只是对 core-js 和 regenerator 进行的封装。core-js 通过各种奇技淫巧，用 ES3 实现了大部分的 ES2017 原生标准库，同时还要严格遵循规范。支持IE6+
    - core-js 组织结构非常清晰，高度的模块化。比如 `core-js/es6` 里包含了 es6 里所有的特性。而如果只想实现 promise 可以单独引入 `core-js/features/promise`

## 基础库

### cross-env 启动时增加环境变量

### 数学计算mathjs

- mathjs

```js
npm install mathjs -S

import * as math from 'mathjs'

math.add(0.1, 0.2)     //  0.30000000000000004
math.number(math.add(math.bignumber(0.1), math.bignumber(0.2))) // 0.3 math.number转换BigNumber类型为number类型
math.number(math.chain(math.bignumber(0.1)).add(math.bignumber(0.2)).add(math.bignumber(0.3)).done()) // 0.6
```

### 省市区级联

- [vue-area-linkage](https://github.com/dwqs/vue-area-linkage) 省市区选择器(需结合省市区数据)
- [area-puppeteer](https://github.com/dwqs/area-puppeteer) 省市区数据

## UI库

### vxe-table

- 一款基于Vue的表格插件，支持大量数据渲染，编辑表格等功能
- [github](https://github.com/x-extends/vxe-table)、[doc](https://xuliangzhan_admin.gitee.io/vxe-table/#/table/start/install)

#### 案例

- 表格显示/隐藏后样式丢失问题
  - `sync-resize` 绑定指定的变量来触发重新计算表格。参考：https://xuliangzhan_admin.gitee.io/vxe-table/#/table/advanced/tabs
- 多选 + 修改页面表格数据(仅修改页面数据)

```js
// 获取行记录
let checkboxRow = this.tableRef.getCheckboxRecords();
const selectRecords = checkboxRow.map((item) => item.id); // 如果返回数据中没有id字段，则在渲染时会自动生成一个row_xxx的唯一id
if (!selectRecords || selectRecords.length === 0) {
    alert("请先选择记录");
    return;
}
// 调用修改数据api略...
// 修改页面行记录数据
checkboxRow.forEach((row) => {
    row.validStatus = 0;
    this.$refs.tableRef.reloadRow(row, null, 'validStatus'); // 仅修改单个字段
    // this.$refs.tableRef.reloadRow(currentRow, rowNewData, null); // 基于rowNewData修改一整行的数据(如果rowNewData无表格列定义的字段将会置空)
});

// 从列表中移除数据行
// 1.修改页面显示缓存，this.allData数据并没有删除
this.$refs.tableRef.remove(row)
this.$refs.tableRef.removeCheckboxRow() // 移除选中行
// 2.修改页面数据，this.allData数据删除了
this.allData = this.allData.filter((item) => item.id != row.id)
this.$refs.tableRef.loadData(this.allData)

// 重新加载整个表格数据
this.$refs.tableRef.loadData(this.allData);
```
- 监听行的选中事件

```js
// <vxe-table @checkbox-change="checkboxChange">
checkboxChange(table, event) {
    // table对应key如下
    // "row"(当前选中或取消选中行), "checked"(操作完当前行后的选中状态), "items"(所有行数据), "data"(所有行数据), "records"(目前选中的所有行数据), "selection"(目前选中的所有行数据)
    // "$table", "$grid", "$event", "reserves", "indeterminates", "$seq", "seq", "rowid", "rowIndex", "$rowIndex", "column", "columnIndex", "$columnIndex", "_columnIndex", "fixed", "type", "isHidden", "level", "visibleData", "cell"
}
```

## 底层硬件库

### Clipboard 复制内容到剪贴板

- 必须要绑定Dom
- 必须要触发点击事件（触发其他Dom的点击事件，然后js触发目的dom的点击事件也可）

### 扫码/条码生成

#### H5页面扫码

- 在微信浏览器打开H5页面，可引入微信的js SDK解决（需域名和微信公众号绑定）
- 在系统浏览器打开H5页面
    - 基于[jsQR](https://github.com/cozmo/jsQR)、[vue-qrcode-reader(本质基于jsQR)](https://github.com/gruhn/vue-qrcode-reader)
        - 调取摄像头(进行录像)识别二维码，每个页面需要同意调用摄像头(网页可设置永久同意)
        - 优点是无需拍照确认识别(会自动识别，出错率低)，**但是必须要https才行**
    - 基于[jsqrcode](https://github.com/LazarSoft/jsqrcode)库，可进行二维码/条形码解析，可生成条形码
        - 参考：https://www.cnblogs.com/yisuowushinian/p/5145262.html，此方案在前端 js 解析二维码，依赖`jsqrcode`
        - 这个库已经支持在浏览器端呼起摄像头的操作了，但是依赖一个叫`getUserMedia`的属性，该属性移动端的浏览器支持的都不是很好，低版本只能间接的上传图片的方式解析二维码
        - 此插件需要配合 zepto.js 或者 jQuery.js 使用(主要用来拍照的，如果使用uni-app则不需要此依赖，可使用uni.chooseImage拍照)；webpack打包需要canvas
            - 安装 `cnpm install jsqrcode -S`、`cnpm install canvas -S`
        - 扫码时无扫码框，需要点击拍照 - 确定识别（iphone7扫二维码成功，条形码不成功）
        - 缺点需要确认拍照进行识别，拍照需要清晰，出错率高
    - 基于`quagga.js`库，可进行条形码解析
        - 如uni-app插件：https://ext.dcloud.net.cn/plugin?id=1619

#### H5页面扫码案例（基于uni-app）

- 扫码流程
    - 通过微信浏览器访问的，默认调用微信扫码。需要引入`weixin-js-sdk`
    - 通过手机普通浏览器访问的，如果是https模式访问，则调用摄像头录像扫码，需引入`vue-qrcode-reader`
    - 如果是普通浏览器访问，且以http默认访问，则调用拍照扫码，需引入`jsqrcode`和`canvas`
- scan.vue

```vue
<template>
  <div>
	<text class="lg cuIcon-scan margin-right" @click="handleScan" style="font-size: 40upx;"></text>
	
    <span v-if="showQrcode">
		<view class="cu-modal show" v-show="showQrcodeDialog">
			<view class="cu-dialog">
				<view class="cu-bar bg-white justify-end scan-close">
					<view class="action" @tap="closeDialog">
						<text class="cuIcon-close text-red"></text>
					</view>
				</view>
				<view class="bg-white">
					<qrcode-stream @decode="onDecode" @init="onInit" />
				</view>
			</view>
		</view>
	</span>
  </div>
</template>

<script>
import wechat from '@/utils/wechat.js' 
import { QrcodeStream } from 'vue-qrcode-reader' // "vue-qrcode-reader": "^2.3.9"
let Canvas = require('canvas') // "canvas": "^2.6.1"
let jsqrcode = require('jsqrcode')(Canvas) // "jsqrcode": "^0.0.7"

export default {
  components: { QrcodeStream },
  props: {
	  callback: {
		  type: Function,
		  default: () => {}
	  }
  },
  data () {
    return {
	  showQrcode: false,
	  showQrcodeDialog: false
    }
  },
  methods: {
    onInit(promise) {
      promise.then(() => {
		this.showQrcodeDialog = true
      }).catch(error => {
		console.log(error);
		this.showQrcode = false
		
		let errorMessage = ""
		if (error.name === 'NotAllowedError') {
		  errorMessage = '请允许访问摄像头'
		} else if (error.name === 'NotFoundError') {
		  errorMessage = '此设备无摄像头'
		} else if (error.name === 'NotSupportedError') {
		  errorMessage = 'Seems like this page is served in non-secure context (HTTPS, localhost or file://)'
		} else if (error.name === 'NotReadableError') {
		  errorMessage = '无法访问摄像头，请确认摄像头是否正常工作'
		} else if (error.name === 'OverconstrainedError') {
		  errorMessage = '摄像头不兼容'
		} else {
		  errorMessage = 'UNKNOWN ERROR: ' + error.message
		}
		
		// 尝试使用jsqrcode
		uni.chooseImage({
			sourceType: ['camera'],
			sizeType: 'original',
			count: 1,
			success: (res) => {
				let image = new Image()
				let that = this
				image.onload = function() {
				  let result
				  try {
				    result = jsqrcode.decode(image)
				    that.callback(result)
				  } catch(e) {
					console.error(e);
					
					errorMessage += '；请确认是否为有效二维码或机器不兼容'
					uni.showToast({
						title: errorMessage,
						icon: 'none',
						duration: 4000
					})
				  }
				}
				image.src = res.tempFilePaths
			},
			fail: (err) => {
				console.log(err);
			}
		})
      })
    },
	onDecode (result) {
		this.closeDialog()
		this.callback(result)
	},
	handleScan () {
		if(uni.getStorageSync("apsm-h5-wx")) {
			wechat.scan((res) => {
				this.callback(res)
			})
		} else {
			this.showQrcode = true
		}
	},
	closeDialog() {
		this.showQrcodeDialog = false
		this.showQrcode = false
	}
  }
}
</script>
<style>
.scan-close {
	position: absolute;
	top: 0;
	right: 0;
	z-index: 1;
	background: transparent;
}
</style>
```
- wechat.js

```js
// #ifdef H5
import wx from 'weixin-js-sdk';
// #endif

const wechat = {
    scan(callback) {
        if(uni.getStorageSync("apsm-h5-wx")) {
            wx.scanQRCode({
                needResult: 1, // 默认为0，扫描结果由微信处理，1则直接返回扫描结果
                scanType: ["qrCode","barCode"], // 可以指定扫二维码还是一维码，默认二者都有
                success: function (res) {
                    callback(res.resultStr)
                },
                error: function(res) {
                    uni.showToast({
                        title: res,
                        icon: 'none'
                    });
                }
            });
        } else {
            uni.showToast({
                title: '仅支持在微信中进行扫码',
                icon: 'none'
            });
        }
    }
}
export default wechat
```
- 调用

```vue
<template>
    <div>
        <Scan :callback="handleScan"></Scan>
    </div>
</template>

<script>
export default {
    methods: {
        handleScan (res) {
            if(res) {
                uni.navigateTo({
                    url: './person?id=' + res
                });
            } else {
                uni.showToast({
                    title: "未知二维码",
                    icon: 'none'
                });
            }
        }
    }
}
</script>
```

#### 条码生成

- 相关插件
    - `jsqrcode` 可生成二维码
    - `jsbarcode` 可生成条形码
    - 对应的vue插件
        - [vue-barcode](https://github.com/lindell/vue-barcode)
        - [vue-qr](https://github.com/Binaryify/vue-qr)
        - 使用相对简单，参考：https://blog.csdn.net/qq_44833743/article/details/108773476

### 打印


### 生成PDF

#### jsPDF

- [github](https://github.com/MrRio/jsPDF)、[doc](https://rawgit.com/MrRio/jsPDF/master/docs/index.html)
- 使用

### 生成ZIP文件

npm install jszip -S
npm install file-saver -S

### 网页保存为图片

https://github.com/niklasvh/html2canvas

https://segmentfault.com/a/1190000011478657


- html2canvas操作隐藏元素

    <div style="position: absolute; opacity: 0.0;">
    Failed to execute 'createPattern' on 'CanvasRenderingContext2D': The image argument is a canvas element with a width or height of 0.
    https://stackoverflow.com/questions/20605269/screenshot-of-hidden-div-using-html2canvas





---

参考文章

[^1]: https://www.dazhuanlan.com/2019/12/31/5e0b08829f823/
