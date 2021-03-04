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

## ES Module/CommonJS/AMD/CMD/UMD

- [JavaScript模块化说明](https://www.jianshu.com/p/da2ac9ad2960)
- UMD 叫做通用模块定义规范（Universal Module Definition），它可以通过运行时或者编译时让同一个代码模块在使用 CommonJs、CMD 甚至是 AMD 的项目中运行
- 常见打包后包名：`.js`(es module)、`cjs`(CommonJS)、`umd`(UMD)
- UMD实现方式

```js
((root, factory) => {
    if (typeof define === 'function' && define.amd) {
        // AMD
        define(['jquery'], factory);
    } else if (typeof exports === 'object') {
        // CommonJS
        var $ = requie('jquery');
        module.exports = factory($);
    } else {
        root.testModule = factory(root.jQuery);
    }
})(this, ($) => {
    //todo
});
```













