---
layout: "post"
title: "webpack"
date: "2019-05-29 18:07"
categories: web
tags: [webpack, node]
---

## 简介

- [webpack](https://webpack.js.org/)
- `Chunk`：webpack打包的过程种，生成的JS文件，每一个JS文件我们都把它叫做Chunk。如main.js的chunk Name是main
    - chunks默认值是async，异步代码才进行分割；如果我们想同步和异步的都进行代码分割，需要改为all

## 设置

### webpack.config.js

```js
const path = require('path');

module.exports = {
    mode: 'development',
    // JavaScript 执行入口文件
    entry: './src/main.js',
    output: {
        // 把所有依赖的模块合并输出到一个 bundle.js 文件
        filename: 'bundle.js',
        // 输出文件都放到 dist 目录下
        path: path.resolve(__dirname, './dist'),

        // 默认webpack打包出来的js无法被其他模块引用。设置此参数后，入口模块返回的 module.exports 设置到环境中
        // (1) 默认暴露给全局 var myDemo = returned_module_exports (2) commonjs: exports['myDemo'] = returned_module_exports (3) commonjs2: module.exports = returned_module_exports。element-ui 的构建方式采用 commonjs2
        libraryTarget: 'umd', // 把微应用打包成 umd 库格式。常见打包后包名：`js`(es module)、`cjs`(CommonJS)、`umd`(UMD)
        library: `myDemo`,
        // libraryExport: 'default',
        // umdNamedDefine: true,

        // jsonpFunction: `webpackJsonpMyDemo`,
    }
}
```

### 外网访问

```json
// --host 0.0.0.0 指定开发的ip
// --disableHostCheck true 指定不检查Host，否则容易出现`Invalid Host header`(也可以使用--public)解决
"scripts": {
    "dev": "webpack-dev-server --content-base ./ --open --inline --hot --compress --config build/webpack.dev.config.js --disableHostCheck true --host 0.0.0.0 --port 7710",
},
```

### 环境变量

- 基于cross-env进行操作：`npm i cross-env -D` 安装cross-env插件
- package.json

```json
"scripts": {
    "cross-env": "cross-env API_URL=http://192.168.17.50:8050/ffs-crm/crm",
    "dev": "webpack-dev-server --content-base ./ --open --inline --hot --compress --config build/webpack.dev.config.js --port 7710",
},
```
- webpack.dev.config.js

```js
plugins: [  
    new webpack.DefinePlugin({
        'process.env': {
            API_URL: JSON.stringify(process.env.API_URL)
        }
    })
]
```
- 其他js文件中使用`process.env.API_URL`即可
- 启动时可以覆盖此参数`npm run cross-env API_URL=http://localhost:8050/ffs-crm/crm npm run dev`

### 配置API代理解决跨域问题

- 一般配置在`build/webpack.dev.conf.js`文件中，也可直接在`config/index.js`中的`dev.proxyTable`中修改

```js
// 参考：https://github.com/chimurai/http-proxy-middleware
module.exports = {
  //...
  devServer: {
    proxy: {
      '/api': {
        target: 'http://www.baidu.com', // 代理的API地址
        pathRewrite: {'^/api' : ''},
        changeOrigin: true, // target是域名的话，需要这个参数
        secure: false, // 设置支持https协议的代理
      },
      '/api2': {
          ...
      }
    }
  }
};
```

### index.html

- 变量替换

```html
<link rel="icon" href="<%= BASE_URL %>favicon.ico">

<% if(VUE_APP_DEBUG_AVUE_URL) { %>
    <script src="<%= BASE_URL %>avue.js" charset="utf-8"></script>
<% } else { %>
    <script src="<%= BASE_URL %>cdn/avue/2.7.3/avue.min.js" charset="utf-8"></script>
<% } %>

<% for(var k in htmlWebpackPlugin.files.chunks) { %>
    <% if(k !== 'main'){ %>
        <script type="text/javascript" src="<%= htmlWebpackPlugin.files.chunks[k].entry %>"></script>
    <% } %>
<% } %>
```

## Webpack模块打包原理

- [github扩展案例](https://github.com/oldinaction/smweb/blob/master/webpack/README.md)

### Chrome调试说明

- 在chrome调试工具 - Sources 中查看源码
    - `sqbiz-plugin-minions-[name]` 模块源码，此名称为output.library配置值
    - `webpack-internal://` 模块编译后代码。调试时默认是调试此文件夹下代码，如果设置了sourceMapping，则会自定映射到源码上，从而可直接调试源码

### 打包案例

- 案例 [^1] [^2]

```js
// a.js (entry js)
import b from './b';
export default 'a.js'; // 默认导出的模块名
console.log(b);
// b.js
export default 123;

// 打包后bundle.js：本质为一个只执行函数 (function(modules) {})([]);
(function(modules) {
  function __webpack_require__(moduleId) {
    var module =  {
      i: moduleId,
      l: false,
      exports: {}
    };
    modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
    return module.exports;
  }

  // 调用上述定义 __webpack_require__ 函数，这个函数就是 require 或者是 import 的替代。这里会传入一个 moduleId，这个例子中是0，也就是我们的入口模块 a.js 的内容
  return __webpack_require__(0); // 时间返回的是 module.exports
})/* <==入口文件函数体.参数==> */([
  // 编译 a.js
  (function (module, __webpack_exports__, __webpack_require__) {
    "use strict";
    Object.defineProperty(__webpack_exports__, "__esModule", { value: true });
    /* harmony import */ var __WEBPACK_IMPORTED_MODULE_0__b__ = __webpack_require__(1); // 引用模块1(模块数组下标1的模块)
    /* harmony default export */ __webpack_exports__["default"] = ('a.js');
    console.log(__WEBPACK_IMPORTED_MODULE_0__b__["b" /* default */]);
  }),
  // 编译 b.js
  (function (module, __webpack_exports__, __webpack_require__) {
    // 输出本模块的数据
    "use strict";
    /* harmony default export */ __webpack_exports__["b"] = (123);
  })
]);
```

### 结合babel

- **babel 会将 es6 语法转换成 commonjs 语法。**即将所有输出都赋值给 commonjs 的 exports，并带上一个标志 __esModule 表明这是个由 es6 转换来的 commonjs 格式，然后采用 require 去引用模块

```js
// (1) 解决 default 问题
import a from './a.js';
// 打包后
// 上述代码如babel直接转换成 `var a = require(./a.js);`，则有问题（本意是导出default默认模块，并赋值给a；此时则成了导出a.js所有内容到a对象），因此增加了 _interopRequireDefault 函数
function _interopRequireDefault(obj) {
    return obj && obj.__esModule
        ? obj
        : { 'default': obj };
}
var _a = require('./a.js');
var _a2 = _interopRequireDefault(_a);
var a = _a2['default'];

// (2) 解决 * 通配符问题
import * as a from './a.js' // es6语法的本意是想将 es6 模块的所有命名输出以及defalut输出打包成一个对象赋值给a变量
// 打包后
// 打包出的 var a = require('./a.js') 符合目的
if (obj && obj.__esModule) {
   return obj;
}
// 如果本来就是 commonjs 规范的模块，导出时没有default属性，需要添加一个default属性，因此增加了 _interopRequireWildcard 函数
function _interopRequireWildcard(obj) {}

// (3) 导入 {} 情况
import { a } from './a.js'
// 打包后
require('./a.js').a

// (4) 按需加载
import { Button, Select } from 'element-ui'
// 默认打包后
var a = require('element-ui'); // import 会先转换为 commonjs，此行代码就会将所有组件都引入进来了
var Button = a.Button;
var Select = a.Select;
// 引入 babel-plugin-component 插件后，上文打包后为。所有大部分UI组件库的目录形式如下文注释
import Button from 'element-ui/lib/button'
import Select from 'element-ui/lib/select'
/*
|-lib               // lib 下的各组件用于按需引用
||--component1
||--component2
||--component3
|-index.common.js   // 给 import element from 'element-ui' 这种形式调用全部组件
*/
```

### 复杂案例

<details>
<summary>打包复杂案例</summary>

```js
// my-app 打包成 app.js
(function webpackUniversalModuleDefinition(root, factory) {
    // Vue、axios等都是通过external方式引入的依赖
    if (typeof exports === 'object' && typeof module === 'object')
        // CommonJS
        module.exports = factory(require("Vue"), require("axios"), require("Vuex"), require("VueRouter"), require("ELEMENT"));
    else if (typeof define === 'function' && define.amd)
        // AMD
        define(["Vue", "axios", "Vuex", "VueRouter", "ELEMENT"], factory);
    else if (typeof exports === 'object')
        // ES6
        exports["my-app"] = factory(require("Vue"), require("axios"), require("Vuex"), require("VueRouter"), require("ELEMENT"));
    else
        // window
        root["my-app"] = factory(root["Vue"], root["axios"], root["Vuex"], root["VueRouter"], root["ELEMENT"]);
})/* <==入口文件函数体.参数==> */(
    // 参数1
	(typeof self !== 'undefined' ? self : this), 
    // 参数2
	function (__WEBPACK_EXTERNAL_MODULE_vue__, 
		__WEBPACK_EXTERNAL_MODULE_axios__, __WEBPACK_EXTERNAL_MODULE_vuex__, 
		__WEBPACK_EXTERNAL_MODULE_vue_router__, __WEBPACK_EXTERNAL_MODULE_element_ui__) 
	{
		return /******/
        // 返回一个自执行函数
		(function (modules) { // webpackBootstrap
			/******/// install a JSONP callback for chunk loading
			/******/
			function webpackJsonpCallback(data) {
				// ...
			};
			/******/
			function checkDeferredModules() {
				// ...
			}
			// ... 省略, 如热部署相关代码
			/******/// The require function
			/******/
			function __webpack_require__(moduleId) {
				/******/
				/******/// Check if module is in cache
				/******/
				if (installedModules[moduleId]) {
					/******/
					return installedModules[moduleId].exports;
					/******/
				}
				/******/// Create a new module (and put it into the cache)
				/******/
				var module = installedModules[moduleId] = {
					/******/
					i: moduleId,
					/******/
					l: false,
					/******/
					exports: {},
					/******/
					hot: hotCreateModule(moduleId),
					/******/
					parents: (hotCurrentParentsTemp = hotCurrentParents, hotCurrentParents = [], hotCurrentParentsTemp),
					/******/
					children: []
					/******/
				};
				/******/
				/******/// Execute the module function
				/******/
				modules[moduleId].call(module.exports, module, module.exports, hotCreateRequire(moduleId));
				/******/
				/******/// Flag the module as loaded
				/******/
				module.l = true;
				/******/
				/******/// Return the exports of the module
				/******/
				return module.exports;
				/******/
			}
			/******/
			/******/// This file contains only the entry chunk.
			/******/// The chunk loading function for additional chunks
			/******/
			__webpack_require__.e = function requireEnsure(chunkId) {
				// ...
			};
			/******/
			/******/// expose the modules object (__webpack_modules__)
			/******/
			__webpack_require__.m = modules;
			/******/
			/******/// expose the module cache
			/******/
			__webpack_require__.c = installedModules;
			/******/
			/******/// define getter function for harmony exports
			/******/
			__webpack_require__.d = function (exports, name, getter) {
				// ...
			};
			/******/
			/******/// define __esModule on exports
			/******/
			__webpack_require__.r = function (exports) {
				/******/
				if (typeof Symbol !== 'undefined' && Symbol.toStringTag) {
					/******/
					Object.defineProperty(exports, Symbol.toStringTag, {
						value: 'Module'
					});
					/******/
				}
				/******/
				Object.defineProperty(exports, '__esModule', {
					value: true
				});
				/******/
			};
			/******/
			/******/// create a fake namespace object
			/******/// mode & 1: value is a module id, require it
			/******/// mode & 2: merge all properties of value into the ns
			/******/// mode & 4: return value when already ns object
			/******/// mode & 8|1: behave like require
			/******/
			__webpack_require__.t = function (value, mode) {
				// ...
			};
			/******/
			/******/// getDefaultExport function for compatibility with non-harmony modules
			/******/
			__webpack_require__.n = function (module) {
				// ...
			};
			/******/
			/******/// Object.prototype.hasOwnProperty.call
			/******/
			__webpack_require__.o = function (object, property) {
				return Object.prototype.hasOwnProperty.call(object, property);
			};
			/******/
			/******/// __webpack_public_path__
			/******/
			__webpack_require__.p = "/";
			/******/
			/******/// on error function for async loading
			/******/
			__webpack_require__.oe = function (err) {
				console.error(err);
				throw err;
			};
			/******/
			/******/// __webpack_hash__
			/******/
			__webpack_require__.h = function () {
				return hotCurrentHash;
			};
			/******/
			/******/
			var jsonpArray = (typeof self !== 'undefined' ? self : this)["webpackJsonp_sqbiz-plugin-minions"] = (typeof self !== 'undefined' ? self : this)["webpackJsonp_sqbiz-plugin-minions"] || [];
			/******/
			var oldJsonpFunction = jsonpArray.push.bind(jsonpArray);
			/******/
			jsonpArray.push = webpackJsonpCallback;
			/******/
			jsonpArray = jsonpArray.slice();
			/******/
			for (var i = 0; i < jsonpArray.length; i++)
				webpackJsonpCallback(jsonpArray[i]);
			/******/
			var parentJsonpFunction = oldJsonpFunction;
			/******/
			/******/
			/******/// add entry module to deferred list
			/******/
			deferredModules.push([1, "chunk-vendors"]);
			/******/// run deferred modules when ready
			/******/
			return checkDeferredModules();
			/******/
		})
		/************************************************************************/
		/******/
        // 自执行函数参数
		({
            // 顺序按照打包的文件名排序

			/***/
			"./node_modules/cache-loader/dist/cjs.js?!./node_modules/babel-loader/lib/index.js!./node_modules/cache-loader/dist/cjs.js?!./node_modules/vue-loader/lib/index.js?!./src/App.vue?vue&type=script&lang=js&":
			/*!*************************************************************************************************************************************************************************************************************************************!*\
			!*** ./node_modules/cache-loader/dist/cjs.js??ref--12-0!./node_modules/babel-loader/lib!./node_modules/cache-loader/dist/cjs.js??ref--0-0!./node_modules/vue-loader/lib??vue-loader-options!./src/App.vue?vue&type=script&lang=js& ***!
			\*************************************************************************************************************************************************************************************************************************************/
			/*! no static exports found */
			/***/
			(function (module, exports, __webpack_require__) {

				"use strict";
				eval("\n\nObject.defineProperty(exports, \"__esModule\", {\n  value: true\n});\nexports.default = void 0;\n//\n//\n//\n//\n//\n//\nvar _default = {\n  name: 'app',\n  data: function data() {\n    return {};\n  },\n  created: function created() {},\n  methods: {},\n  computed: {}\n};\nexports.default = _default;//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ...\n//# sourceURL=webpack-internal:///./node_modules/cache-loader/dist/cjs.js?!./node_modules/babel-loader/lib/index.js!./node_modules/cache-loader/dist/cjs.js?!./node_modules/vue-loader/lib/index.js?!./src/App.vue?vue&type=script&lang=js&\n");

				/***/
			}),

			// 省略 ............................

			/***/
			"./src/App.vue":
			/*!*********************!*\
			!*** ./src/App.vue ***!
			\*********************/
			/*! no static exports found */
			/***/
			(function (module, __webpack_exports__, __webpack_require__) {

				"use strict";
				eval("__webpack_require__.r(__webpack_exports__);\n/* harmony import */ var _App_vue_vue_type_template_id_7ba5bd90___WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./App.vue?vue&type=template&id=7ba5bd90& */ \"./src/App.vue?vue&type=template&id=7ba5bd90&\");...\n//# sourceURL=webpack-internal:///./src/App.vue\n");

				/***/
			}),

			// 省略 .............................

			/***/
			"./src/main.js":
			/*!*********************!*\
			!*** ./src/main.js ***!
			\*********************/
			/*! no static exports found */
			/***/
			(function (module, exports, __webpack_require__) {

				"use strict";
				eval(
					"\n\nvar _interopRequireWildcard = __webpack_require__(/*! ./node_modules/@babel/runtime/helpers/interopRequireWildcard */ \"./node_modules/@babel/runtime/helpers/interopRequireWildcard.js\").default;" + 
					"\n\nvar _interopRequireDefault = __webpack_require__(/*! ./node_modules/@babel/runtime/helpers/interopRequireDefault */ \"./node_modules/@babel/runtime/helpers/interopRequireDefault.js\").default;"+
					"\n\nObject.defineProperty(exports, \"__esModule\", {\n  value: true\n});\nexports.bootstrap = bootstrap;\nexports.mount = mount;\nexports.unmount = unmount;\nexports.update = update;\nexports.testKey = void 0;...//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIj...//# sourceURL=webpack-internal:///./src/main.js\n");

				/***/
			}),

			// 省略 .............................

            // 当通过 (webpack)-dev-server 启动项目时，会把入口函数当做参数(./src/main.js @/mock)传递进去
			/***/
			1:
			/*!*****************************************************************************************************************************************!*\
			!*** multi (webpack)/hot/dev-server.js (webpack)-dev-server/client?http://192.168.1.10:9701&sockPath=/sockjs-node ./src/main.js @/mock ***!
			\*****************************************************************************************************************************************/
			/*! no static exports found */
			/***/
			(function (module, exports, __webpack_require__) {
                /*
                    1.依次引入相关文件，并将最后一个文件(一般时自定义库的入口函数)暴露的数据暴露出来
                    2.此时由于vue.config.js配置如下，因此./mock.js被作为自定义库的入口函数
                        const entry = config.entry('app')
                        entry.add('./mock').end()
                    3.当使用qiankun进行微前端改造时，子项目需要在mian.js(子项目的入口函数)中将bootstrap/mount/unmount等函数暴露出来，而此时由于./mock.js作为入口函数被暴露出来，从而导致报错：Application died in status LOADING_SOURCE_CODE: You need to export the functional lifecycles in xxx entry
                    4.qiankun对应改造方法
                        // let entryArr = ['babel-polyfill', 'classlist-polyfill', './src/main.js']
                        let entryArr = ['./src/main.js']
                        if (process.env.NODE_ENV === 'development') {
                            entryArr.splice(entryArr.length - 1, 0, './mock/index.js')
                        }
                        config.entryPoints.clear()
                        let entry = config.entry('app')
                        entryArr.forEach(x => {
                            entry.add(x)
                        })
                        entry.end()
                        // 最终生成的app.js为：module.exports = __webpack_require__("./src/main.js");
                */
				__webpack_require__(/*! D:\test\node_modules\webpack\hot\dev-server.js */ "./node_modules/webpack/hot/dev-server.js");
				__webpack_require__(/*! D:\test\node_modules\webpack-dev-server\client\index.js?http://192.168.1.10:9701&sockPath=/sockjs-node */ "./node_modules/webpack-dev-server/client/index.js?http://192.168.1.10:9701&sockPath=/sockjs-node");
				__webpack_require__(/*! ./src/main.js */ "./src/main.js");
				module.exports = __webpack_require__(/*! @/mock */ "./src/mock/index.js");

				/***/
			}),
			
			// 下面则是 external 的依赖(会传入__WEBPACK_EXTERNAL_MODULE_axios__参数)
			/***/
			"axios":
			/*!************************!*\
			!*** external "axios" ***!
			\************************/
			/*! no static exports found */
			/***/
			(function (module, exports) {

				eval("module.exports = __WEBPACK_EXTERNAL_MODULE_axios__;//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,...\n//# sourceURL=webpack-internal:///axios\n");

				/***/
			}),

			// 省略 .............................

			/******/
		});
	}
);
```
</details>

## Webpack转译Typescript现有方案

- 参考[web.md#Webpack转译Typescript现有方案](/_posts/web/web.md#Webpack转译Typescript现有方案)






---

参考文章

[^1]: https://segmentfault.com/a/1190000012386576
[^2]: https://lq782655835.github.io/blogs/project/webpack4-1.module.html


