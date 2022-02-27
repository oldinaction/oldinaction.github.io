---
layout: "post"
title: "Web前端开发"
date: "2018-07-21 08:53"
categories: [web]
tags: [pdf, speech]
---

## 《前端小课》

- `《前端小课》` (2018-07)

<embed width="1000" height="800" src="/data/pdf/前端小课2018.pdf" internalinstanceid="7">

## ESModule/CommonJS/AMD/CMD/UMD

- [JavaScript模块化说明](https://www.jianshu.com/p/da2ac9ad2960)
- `CommonJS` 
    - 定义的模块分为：module模块标识、exports模块定义、require模块引用。**Node里面的模块系统遵循的是CommonJS规范**
        - `exports` 返回的是模块函数，`module.exports` 返回的是模块对象本身，返回的是一个类
        - 在一个node执行一个文件时，会给这个文件内生成一个 exports和module对象，而module又有一个exports属性。他们之间的关系如下图，都指向一块{}内存区域。`exports = module.exports = {};``
    - 案例

        ```js
        // test1.js
        var app = {
            name: 'app',
            version: '1.0.0',
            sayName: function(name) {
                console.log(this.name)
            }
        }
        module.exports = app
        // test2.js
        var func = function() {
            console.log("func")
        }
        exports.func = func // exports = module.exports = {} => module.exports.func = func => {func: func}

        // 使用
        var test1 = require("./test1")
        test1.sayName('smalle') // smalle
        var test2 = require("./test2")
        test2.func() // func
        ```
- AMD/CMD
    - **AMD/CMD是CommonJS在浏览器端的解决方案。**CommonJS是同步加载（代码在本地，加载时间基本等于硬盘读取时间）。AMD/CMD是异步加载（浏览器必须这么干，代码在服务端）
    - `AMD` 是 RequireJS 在推广过程中对模块定义的规范化产出。使用AMD，需要在html中引入RequireJS库
        - 定义模块 `define(id?, dependencies?, factory)`
        - 加载模块 `require([module], factory)`
    - `CMD` 是 SeaJS 在推广过程中对模块定义的规范化产出
        - 定义模块 `define(function(require, exports, module) {})`
    - AMD是提前执行（RequireJS2.0开始支持延迟执行，不过只是支持写法，实际上还是会提前执行），CMD是延迟执行
- `UMD` 叫做通用模块定义规范（Universal Module Definition）
    - 它可以通过运行时或者编译时让同一个代码模块在使用 CommonJs、CMD 甚至是 AMD 的项目中运行。导出umd格式，可以支持import、require和script引入
    - UMD实现方式

        ```js
        ((root, factory) => {
            if (typeof define === 'function' && define.amd) {
                // AMD
                define(['jquery'], factory);
            } else if (typeof exports === 'object' && typeof module === 'object') {
                // CommonJS
                var $ = requie('jquery');
                module.exports = factory($);
            } else if (typeof exports === 'object') {
                var $ = requie('jquery');
                exports["jquery"] = factory($);
            } else {
                // window
                root.testModule = factory(root.jQuery);
            }
        })(this, ($) => {
            'use strict';
            //todo
        });
        ```
- ES Module [^1]
    - export 和 export default
        - export与export default均可用于导出常量、函数、文件、模块等
        - 在一个文件或模块中，export、import可以有多个，export default仅有一个
        - 通过export方式导出，在导入时要加{ }，export default则不需要
        - export能直接导出变量表达式，export default不行
    - 案例

        ```js
        // es6模块 导出
        export default { age: 1, a: 'hello', foo:function(){} }

        // es6模块 导入
        import foo from './foo'
        ```



---

参考文章

[^1]: https://blog.csdn.net/qq_31967569/article/details/82461499


