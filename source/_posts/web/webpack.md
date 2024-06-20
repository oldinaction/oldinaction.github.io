---
layout: "post"
title: "webpack"
date: "2019-05-29 18:07"
categories: web
tags: [webpack, node]
---

## 简介

- [webpack中文网](https://www.webpackjs.com/)
- [webpack](https://webpack.js.org/)
- `Chunk`：webpack打包的过程种，生成的JS文件，每一个JS文件我们都把它叫做Chunk。如main.js的chunk Name是main
    - chunks默认值是async，异步代码才进行分割；如果我们想同步和异步的都进行代码分割，需要改为all

## 配置

### webpack.config.js

```js
const path = require('path');

module.exports = {
    mode: 'development',
    // JavaScript 执行入口文件
    entry: './src/main.js',
    // webpack打包后的输出配置
    output: {
        // 把所有依赖的模块合并输出到一个 bundle.js 文件
        filename: 'bundle.js',
        // 输出文件都放到 dist 目录下
        path: path.resolve(__dirname, './dist'),

        // 默认webpack打包出来的js无法被其他模块引用。设置此参数后，入口模块返回的 module.exports 设置到环境中
        // (1) 默认暴露给全局 var myDemo = returned_module_exports (2) commonjs: exports['myDemo'] = returned_module_exports (3) commonjs2: module.exports = returned_module_exports。element-ui 的构建方式采用 commonjs2
        libraryTarget: 'umd', // 把微应用打包成 umd 库格式。常见打包后包名：`js`(es module)、`cjs`(CommonJS)、`umd`(UMD)
        // 保留到全局的变量名称(如window.myDemo)
        library: `myDemo`,
        // libraryExport: 'default',
        // umdNamedDefine: true,

        // jsonpFunction: `webpackJsonpMyDemo`,
    }
}
```

### module配置

- 将代码分解成chunk，并称之为模块。在解析模块的过程中涉及到对不同的语言(es6/ts/commonjs/css/less等)进行解析，以下为解析规则的相关配置
- [module配置文档](https://www.webpackjs.com/configuration/module/)
- [webpack-chain](http://npm.taobao.org/package/webpack-chain) 链式配置

```js
module.exports = {
  module: {
    rules: [
      {
        // => 规则条件：resource(属性 test, include, exclude 和 resource) 或 issuer
        // 一个loader的配置，一般一个test就够了，多的话也就一个test加上include或者exclude
        // 如果exclude、include、test三个在同一个loader的配置中时，优先级：exclude > include > test
        test: /\.css$/, // 第二次(一个文件可处理多次，这是第二次对css文件的处理)
        // => 规则结果(符合条件时的处理方法)：应用的loader(loader, options, use, query, loaders, enforce属性) 或 parser选项
        // loader 从右到左（或从下到上）地取值(evaluate)/执行(execute)
        // sass-loader -> css-loader -> style-loader
        use: [
          { loader: 'style-loader' },
          {
            loader: 'css-loader',
            options: {
              // 开启css模块化
              // modules: true
              modules: {
                // 默认是hash:base64
                localIdentName: "[path][name]__[local]--[hash:base64:5]",
              }
            }
          },
          { loader: 'sass-loader' }
        ]
      },
      {
        test: /\.css$/, // 第一次处理css文件
        use: ["style-loader", "css-loader"],
        include: [
          // src/components/目录下的css是模块化的，其之外的css是全局的
          path.resolve(__dirname, 'src/components')
        ]
      },
    ]
  }
};
```

### 外网访问

```js
// vue3 vue.config.js
module.exports = {
    // 跳过检查host
    allowedHosts: ['www.test.cn', '.vicp.fun'],
    // 跳过检查host 好像没效？
    devServer: {
        disableHostCheck: true
    }
}

// --host 0.0.0.0 指定开发的ip
// --disableHostCheck true 指定不检查Host(好像没效？)，否则容易出现`Invalid Host header`(也可以使用--public)解决
"scripts": {
    "dev": "webpack-dev-server --content-base ./ --open --inline --hot --compress --config build/webpack.dev.config.js --disableHostCheck true --host 0.0.0.0 --port 7710",
},
```

### 环境变量

- [EnvironmentPlugin/DefinePlugin/DotenvPlugin](https://webpack.js.org/plugins/environment-plugin/)
    - 定义环境变量，其他js文件中使用`process.env.API_URL`即可，也可直接使用`API_URL`，环境变量运行时或者打包都会被替换成真实值(如果没定义环境变量，则打包时报错，如果直接引用node_modules里面的由于不会有打包过程，所以就会变成浏览器js报错)
- webpack.dev.config.js

```js
plugins: [
    // 用于定义环境变量
    new webpack.DefinePlugin({
        'process.env': {
            API_URL: JSON.stringify(process.env.API_URL)
        },
        DEBUG: JSON.stringify(false)
    }),
    // EnvironmentPlugin用于定义默认值，可使用process.env.NODE_ENV进行覆盖
    new webpack.EnvironmentPlugin({
        NODE_ENV: 'development', // use 'development' unless process.env.NODE_ENV is defined
        DEBUG: false,
    }),
]
```
- 也可基于cross-env进行操作：`npm i cross-env -D` 安装cross-env插件
    - package.json

    ```json
    "scripts": {
        "cross-env": "cross-env API_URL=http://192.168.17.50:8050/ffs-crm/crm",
        "dev": "webpack-dev-server --content-base ./ --open --inline --hot --compress --config build/webpack.dev.config.js --port 7710",
    },
    ```
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
    - 依赖html-webpack-plugin模块

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

## Loaders

- [script-loader](https://v4.webpack.js.org/loaders/script-loader/)
    - 全局上下文中执行一次 JS 脚本
    - 异步按顺序引入 JS 文件到全局

## 生态

- [webpack-chain](http://npm.taobao.org/package/webpack-chain) 链式配置
    - https://www.jianshu.com/p/2dd631158344
    - `console.log(config.toString())` 打印配置
    - 如果修改需要merge可使用`npm install --save-dev webpack-merge`，然后`const { merge } = require('webpack-merge');`

## Webpack模块打包原理

- [扩展案例Demo](https://github.com/oldinaction/smweb/blob/master/webpack/README.md)

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
  return __webpack_require__(0); // 实际返回的是 module.exports
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
    // 参数1: root
	(typeof self !== 'undefined' ? self : this), 
    // 参数2: factory
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
            // __webpack_require__ 约等于import能力，可以加载某模块
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

### __webpack_require__各属性

- `__webpack_require__()`，约等于import能力，可以加载某模块

```js
// 入口模块的ID
__webpack_require__.s = the module id of the entry point
 
// 模块缓存对象 {} id:{ exports /id/loaded}
__webpack_require__.c = the module cache
 
// 所有构建生成的模块 []
__webpack_require__.m = the module functions
 
// 公共路径，为所有资源指定一个基础路径
__webpack_require__.p = the bundle public path
// 
__webpack_require__.i = the identity function used for harmony imports
 
// 异步模块加载函数，如果没有再缓存模块中 则用 jsonscriptsrc 加载  
__webpack_require__.e = the chunk ensure function
 
// 提供Getter给导出的方法、变量，辅助函数而已
__webpack_require__.d = the exported property define getter function
 
// 辅助函数而已 Object.prototype.hasOwnProperty.call
__webpack_require__.o = Object.prototype.hasOwnProperty.call
 
// 给exports设定attr __esModule，标识该模块为es模块
__webpack_require__.r = define compatibility on export
 
// 用于取值，伪造namespace
__webpack_require__.t = create a fake namespace object
 
// 用于兼容性取值（esmodule 取default， 非esmodule 直接返回module)
__webpack_require__.n = compatibility get default export
 
// hash
__webpack_require__.h = the webpack hash
 
// 
__webpack_require__.w = an object containing all installed WebAssembly.Instance export objects keyed by module id
 
// 异步加载失败处理函数 辅助函数而已
__webpack_require__.oe = the uncaught error handler for the webpack runtime
 
// 表明脚本需要安全加载 CSP策略
__webpack_require__.nc = the script nonce

```

## Webpack转译Typescript现有方案

- 参考[typescript.md#Webpack转译Typescript现有方案](/_posts/web/typescript.md#Webpack转译Typescript现有方案)






---

参考文章

[^1]: https://segmentfault.com/a/1190000012386576
[^2]: https://lq782655835.github.io/blogs/project/webpack4-1.module.html


