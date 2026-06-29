---
layout: "post"
title: "backone.js & underscore.js"
date: "2020-11-15 22:20"
categories: web
tags: [js, lib]
---

## 简介

- `underscore.js` [官网](https://underscorejs.org/)、[中文网](https://underscorejs.net/)
    - 提供了一整套函数式编程的实用功能，但是没有扩展任何JavaScript内置对象
    - Underscore提供了100多个函数，包括常用的: map, filter, invoke — 当然还有更多专业的辅助函数，如：函数绑定，JavaScript模板功能
- `backone.js` [官网](https://backbonejs.org/)、[中文网](https://www.backbonejs.com.cn/)
    - 引用了`underscore.js`库
    - 为复杂WEB应用程序提供模型(models)、集合(collections)、视图(views)的结构

## backone

```js
(function(factory) {

  // Establish the root object, `window` (`self`) in the browser, or `global` on the server.
  // We use `self` instead of `window` for `WebWorker` support.
  var root = (typeof self == 'object' && self.self === self && self) ||
            (typeof global == 'object' && global.global === global && global);

  // 如果是 AMD 环境
  if (typeof define === 'function' && define.amd) {
    define(['underscore', 'jquery', 'exports'], function(_, $, exports) {
      // Export global even in AMD case in case this script is loaded with
      // others that may still expect a global Backbone.
      root.Backbone = factory(root, exports, _, $);
    });

  // 如果是 Node.js 或者 CommonJS 环境。操作dom可以使用 jQuery/Zepto/ender/$
  } else if (typeof exports !== 'undefined') {
    // 引入 underscore 库
    var _ = require('underscore'), $;
    try { $ = require('jquery'); } catch (e) {}
    factory(root, exports, _, $);

  // 如果是浏览器环境
  } else {
    root.Backbone = factory(root, {}, root._, (root.jQuery || root.Zepto || root.ender || root.$));
  }

})(function(root, Backbone, _, $) { // 当引入此包时，则会执行上述函数，并传入工厂函数 factory

  // ====================
  // Model(Backbone.Model) 类(必包函数)。new Model()时，相当于执行了此函数
  // ====================
  var Model = Backbone.Model = function(attributes, options) {
    var attrs = attributes || {};
    options || (options = {});
    this.cid = _.uniqueId(this.cidPrefix);
    this.attributes = {};
    if (options.collection) this.collection = options.collection;
    if (options.parse) attrs = this.parse(attrs, options) || {};
    var defaults = _.result(this, 'defaults');
    attrs = _.defaults(_.extend({}, defaults, attrs), defaults);
    this.set(attrs, options);
    this.changed = {};
    // 调用初始化方法，子类和重写 initialize 方法，则在new对象时会被调用
    this.initialize.apply(this, arguments);
  };

  // 调用 underscore 的 extend 方法（类似 Object.assign，只不过此方法会将 source 的父类方法拷贝到 target 对象上）。在 Model 的原型上扩展属性 Events 和 {...}
  // Attach all inheritable methods to the Model prototype.
  _.extend(Model.prototype, Events, {
    // ...
    // 从 attributes 中获取属性
	get: function(attr) {
      return this.attributes[attr];
    },
    // 将属性设置到 attributes 中
	set: function(key, val, options) {
		// ...
	}
  }

  // ====================
  // View(Backbone.View) 类(必包函数)。new View()时，相当于执行了此函数
  // ====================
  var View = Backbone.View = function(options) {
    this.cid = _.uniqueId('view');
    // 从 options 中提取 model、collection 等属性设值到对象上
    _.extend(this, _.pick(options, viewOptions));
    // 确保有 dom 节点，没有则创建
    this._ensureElement();
    // 调用初始化方法，子类和重写 initialize 方法，则在new对象时会被调用
    this.initialize.apply(this, arguments);
  };

  // View 对象可额外设置的属性名称
  // List of view options to be set as properties.
  var viewOptions = ['model', 'collection', 'el', 'id', 'attributes', 'className', 'tagName', 'events'];

  // 调用 underscore 的 extend 方法。在 View 的原型上扩展属性 Events 和 {...}
  // Set up all inheritable **Backbone.View** properties and methods.
  _.extend(View.prototype, Events, {

    // 默认的 dom 节点标签为 div
    tagName: 'div',

    // 确保 View 有一个dom节点进行渲染，如果 this.el 是一个字符串，则通过 ${} 转换；如果不存在 dom 节点，则根据 id、className、tarName 进行创建 dom 节点
    // Ensure that the View has a DOM element to render into.
    // If `this.el` is a string, pass it through `$()`, take the first
    // matching element, and re-assign it to `el`. Otherwise, create
    // an element from the `id`, `className` and `tagName` properties.
    _ensureElement: function() {
      if (!this.el) {
        var attrs = _.extend({}, _.result(this, 'attributes'));
        if (this.id) attrs.id = _.result(this, 'id');
        if (this.className) attrs['class'] = _.result(this, 'className');
        // 无 dom 节点，则创建dom节点
        this.setElement(this._createElement(_.result(this, 'tagName')));
        this._setAttributes(attrs);
      } else {
        // 有dom节点则进行 ${} 转换
        this.setElement(_.result(this, 'el'));
      }
    },

    // Produces a DOM element to be assigned to your view. Exposed for
    // subclasses using an alternative DOM manipulation API.
    _createElement: function(tagName) {
      return document.createElement(tagName);
    },

    // Change the view's element (`this.el` property) and re-delegate the
    // view's events on the new element.
    setElement: function(element) {
      this.undelegateEvents();
      this._setElement(element);
      this.delegateEvents();
      return this;
    },

    // Creates the `this.el` and `this.$el` references for this view using the
    // given `el`. `el` can be a CSS selector or an HTML string, a jQuery
    // context or an element. Subclasses can override this to utilize an
    // alternative DOM manipulation API and are only required to set the
    // `this.el` property.
    _setElement: function(el) {
      this.$el = el instanceof Backbone.$ ? el : Backbone.$(el);
      this.el = this.$el[0];
    },

    // ...
  }
}
```
