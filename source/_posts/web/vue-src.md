---
layout: "post"
title: "Vue源码"
date: "2020-05-02 19:49"
categories: web
tags: [vue, src]
---

## 说明

- 源码基于Vue v2.6进行说明。[github](https://github.com/vuejs/vue/tree/2.6)仓库目录结构

```bash
# https://github.com/vuejs/vue/blob/2.6/.github/CONTRIBUTING.md#project-structure
src # 源码目录(基于nodejs)
    core # 核心代码
        index.js #   入口
        config.js # 全局配置，相关说明见：https://cn.vuejs.org/v2/api/#%E5%85%A8%E5%B1%80%E9%85%8D%E7%BD%AE
        instance # 实例化相关
        global-api # 操作全局api
        observer # 观察者相关
dist # 源码打包后代码
```

## Vue原型定义及扩展

### 原型初始化入口

- https://github.com/vuejs/vue/blob/2.6/src/core/index.js

<details>
<summary>src/core/index.js</summary>

```js
// Vue 实例化核心方法，其中定义了Vue类(vue原型)
import Vue from './instance/index'
// 引入全局api，参考：https://cn.vuejs.org/v2/api/#%E5%85%A8%E5%B1%80-API
import { initGlobalAPI } from './global-api/index'
// 获取一个Boolean类型的变量，来判断是不是ssr(服务端渲染)
import { isServerRendering } from 'core/util/env'
import { FunctionalRenderContext } from 'core/vdom/create-functional-component'

// 对原型进行扩展

// 这里开始执行初始化全局变量。https://github.com/vuejs/vue/blob/2.6/src/core/global-api/index.js
initGlobalAPI(Vue)

// 为Vue原型定义属性$isServer
Object.defineProperty(Vue.prototype, '$isServer', {
  get: isServerRendering
})

// 为Vue原型定义属性$ssrContext
Object.defineProperty(Vue.prototype, '$ssrContext', {
  get () {
    /* istanbul ignore next */
    return this.$vnode && this.$vnode.ssrContext
  }
})

// expose FunctionalRenderContext for ssr runtime helper installation
Object.defineProperty(Vue, 'FunctionalRenderContext', {
  value: FunctionalRenderContext
})

Vue.version = '__VERSION__'

export default Vue
```
</details>

### 初始化全局API

- https://github.com/vuejs/vue/blob/2.6/src/core/global-api/index.js

<details>
<summary>src/core/global-api/index.js</summary>

```ts
import config from '../config'
import { initUse } from './use'
import { initMixin } from './mixin'
import { initExtend } from './extend'
import { initAssetRegisters } from './assets'
import { set, del } from '../observer/index'
import { ASSET_TYPES } from 'shared/constants'
import builtInComponents from '../components/index'
import { observe } from 'core/observer/index'

import {
  warn,
  extend,
  nextTick,
  mergeOptions,
  defineReactive
} from '../util/index'

export function initGlobalAPI (Vue: GlobalAPI) {
  // config
  const configDef = {}
  configDef.get = () => config
  if (process.env.NODE_ENV !== 'production') {
    configDef.set = () => {
      warn(
        'Do not replace the Vue.config object, set individual fields instead.'
      )
    }
  }
  Object.defineProperty(Vue, 'config', configDef)

  // exposed util methods.
  // NOTE: these are not considered part of the public API - avoid relying on
  // them unless you are aware of the risk.
  Vue.util = {
    warn,
    extend,
    mergeOptions,
    defineReactive
  }

  Vue.set = set
  Vue.delete = del
  Vue.nextTick = nextTick

  // 2.6 explicit observable API
  Vue.observable = <T>(obj: T): T => {
    observe(obj)
    return obj
  }

  Vue.options = Object.create(null)
  ASSET_TYPES.forEach(type => {
    Vue.options[type + 's'] = Object.create(null)
  })

  // this is used to identify the "base" constructor to extend all plain-object
  // components with in Weex's multi-instance scenarios.
  Vue.options._base = Vue

  extend(Vue.options.components, builtInComponents)

  initUse(Vue)
  // 初始化全局 mixin 属性
  initMixin(Vue)
  initExtend(Vue)
  initAssetRegisters(Vue)
}
```
</details>

- 全局mixin

```js
/* @flow */

import { mergeOptions } from '../util/index'

export function initMixin (Vue: GlobalAPI) {
  Vue.mixin = function (mixin: Object) {
    this.options = mergeOptions(this.options, mixin)
    return this
  }
}
```

## Vue实例化过程

### Vue 实例化 [^1]

- Vue 项目的起源，源于一次Vue的实例化

```js
new Vue({
  el: ...,
  data: ...,
  render() {...},
  ...
})
```

### 实例化入口

<details>
<summary>src/core/instance/index.js</summary>

- https://github.com/vuejs/vue/blob/2.6/src/core/instance/index.js

```js
import { initMixin } from './init'
import { stateMixin } from './state'
import { renderMixin } from './render'
import { eventsMixin } from './events'
import { lifecycleMixin } from './lifecycle'
import { warn } from '../util/index'

// 定义了一个 Vue Class
function Vue (options) {
  if (process.env.NODE_ENV !== 'production' &&
    !(this instanceof Vue)
  ) {
    warn('Vue is a constructor and should be called with the `new` keyword')
  }
  // _init()方法是在 initMixin(Vue) 的时候添加在原型上的
  this._init(options)
}

// 调用了一系列init、mixin的方法来初始化一些功能
initMixin(Vue) // 具体见下文
stateMixin(Vue)
eventsMixin(Vue)
lifecycleMixin(Vue)
renderMixin(Vue)

// 导出了一个 Vue 功能类
export default Vue
```
</details>

### initMixin

- 处理 options 选项 [^2]
    -  options参数的处理：把业务逻辑以及组件的一些特性全都放到vm.$options中，后续的操作都可以从vm.$options拿到可用的信息。框架基本上都是对输入宽松，对输出严格，vue也是如此，不管使用户添加了什么代码，最后都规范的收入vm.$options中

<details>
<summary>src/core/instance/init.js</summary>

```js
import { extend, mergeOptions, formatComponentName } from '../util/index'

let uid = 0

// 对Vue混入一些功能，此处主要是对原型增加 _init()方法
export function initMixin (Vue: Class<Component>) {
  // ************************************
  // ***** 在new Vue()时会调用此方法 *****
  // ************************************
  // 可设置debugger条件 `options._componentTag === 'avue-crud'` 来调试 <avue-crud/> 标签组件的创建
  // 在渲染一个组件时，可能会多次进入此函数
  Vue.prototype._init = function (options?: Object) {
    const vm: Component = this
    // a uid
    vm._uid = uid++

    let startTag, endTag
    /* istanbul ignore if */
    if (process.env.NODE_ENV !== 'production' && config.performance && mark) {
      startTag = `vue-perf-start:${vm._uid}`
      endTag = `vue-perf-end:${vm._uid}`
      mark(startTag)
    }

    // 如果是Vue的实例，则不需要被observe
    vm._isVue = true
    // 1.options参数的处理
    if (options && options._isComponent) {
      // optimize internal component instantiation
      // since dynamic options merging is pretty slow, and none of the
      // internal component options needs special treatment.
      initInternalComponent(vm, options)
    } else {
      // https://github.com/vuejs/vue/blob/2.6/src/core/util/options.js#L388。mergeOptions解析见下文
      // -- 统一props和directives格式，如将驼峰属性名转为连字符
      // -- 如果存在 child.extends 或者 child.mixins，则递归调用 mergeOptions
      // -- 将 child options 的属性值按照一定的策略merge到 parent options(默认策略是子属性值不为undefined则进行覆盖，否则取副属值；options属性merge策略可进行配置)
      vm.$options = mergeOptions(
        // 解析构造函数的options，https://github.com/vuejs/vue/blob/2.6/src/core/instance/init.js#L93
        // -- 定义Vue继承方法，最后返回了一个继承自Super的子类Sub，并添加Sub['super'] = Super等属性。https://github.com/vuejs/vue/blob/2.6/src/core/global-api/extend.js#L19
        // -- Ctor.super 来判断该类是否是Vue的子类
        // -- if (superOptions !== cachedSuperOptions) 来判断父类中的 options 有没有因Vue.mixin(options)等发生变化
        // -- 返回获merge自己的options与父类的options属性
        resolveConstructorOptions(vm.constructor), // parent options
        options || {}, // child options
        vm
      )
    }

    // 2.renderProxy
    if (process.env.NODE_ENV !== 'production') {
      initProxy(vm)
    } else {
      vm._renderProxy = vm
    }
    // expose real self
    vm._self = vm

    // 3.vm的生命周期相关变量初始化
    initLifecycle(vm)

    // 4.vm的事件监听初始化
    initEvents(vm)
    initRender(vm)
    callHook(vm, 'beforeCreate')
    initInjections(vm) // resolve injections before data/props

    // 5.vm的状态初始化，prop/data/computed/method/watch都在这里完成初始化，因此也是Vue实例create的关键
    initState(vm)
    initProvide(vm) // resolve provide after data/props
    callHook(vm, 'created')

    /* istanbul ignore if */
    if (process.env.NODE_ENV !== 'production' && config.performance && mark) {
      vm._name = formatComponentName(vm, false)
      mark(endTag)
      measure(`vue ${vm._name} init`, startTag, endTag)
    }

    // 6.render & mount
    if (vm.$options.el) {
      vm.$mount(vm.$options.el)
    }
  }
}
```
</details>

- https://github.com/vuejs/vue/blob/2.6/src/core/util/options.js#L388

<details>
<summary>mergeOptions</summary>

```js
export function mergeOptions (
  parent: Object,
  child: Object,
  vm?: Component
): Object {
  //...

  // 统一props和directives格式，如将驼峰属性名转为连字符
  normalizeProps(child)
  // 统一directives的格式
  normalizeDirectives(child)

  // 如果组件存在 extends 或者 mixins属性，则递归调用mergeOptions
  // Apply extends and mixins on the child options,
  // but only if it is a raw options object that isn't
  // the result of another mergeOptions call.
  // Only merged options has the _base property.
  if (!child._base) {
    if (child.extends) {
      parent = mergeOptions(parent, child.extends, vm)
    }
    if (child.mixins) {
      for (let i = 0, l = child.mixins.length; i < l; i++) {
        parent = mergeOptions(parent, child.mixins[i], vm)
      }
    }
  }

  // 针对不同的键值，采用不同的merge策略
  const options = {}
  let key
  for (key in parent) {
    mergeField(key)
  }
  for (key in child) {
    if (!hasOwn(parent, key)) {
      mergeField(key)
    }
  }
  function mergeField (key) {
    // 如Vue 的 data 属性则取 strats.data 策略，如果无 strats.data 则取默认策略。具体见下文
    const strat = strats[key] || defaultStrat
    options[key] = strat(parent[key], child[key], vm, key)
  }
  return options
}
```
</details>

<details>
<summary>mergeOptions时采用的策略：对不同的field采取不同的策略，Vue提供了一个strats对象，其本身就是一个hook，如果strats有提供特殊的逻辑，就走strats，否则走默认merge逻辑，用这种hook的方式就能很好的区分对待公共处理逻辑与特殊处理逻辑</summary>
- https://github.com/vuejs/vue/blob/2.6/src/core/util/options.js

```js
const strats = config.optionMergeStrategies // https://github.com/vuejs/vue/blob/2.6/src/core/config.js

...

// strats.data针对Vue data参数的merge策略
strats.data = function (
  parentVal: any,
  childVal: any,
  vm?: Component
): ?Function {
  // Vue.extend 方法里面也会调用mergeOptions进行合并属性的：Sub.options = mergeOptions(Super.options, extendOptions)
  // 而在Vue的组件继承树上的merge是不存在vm的
  if (!vm) {
    // 如果子属性值不是个函数，那么返回父属性的值
    if (childVal && typeof childVal !== 'function') {
      // 但是Vue建议data属性返回一个函数，即：data () { return {} }
      process.env.NODE_ENV !== 'production' && warn(
        'The "data" option should be a function ' +
        'that returns a per-instance value in component ' +
        'definitions.',
        vm
      )

      return parentVal
    }

    // 子属性不存在或是一个函数时
    /*
        // mergeDataOrFn处理：call函数
        return mergeData(
            typeof childVal === 'function' ? childVal.call(this, this) : childVal,
            typeof parentVal === 'function' ? parentVal.call(this, this) : parentVal
        )
    */
    return mergeDataOrFn(parentVal, childVal)
  }

  return mergeDataOrFn(parentVal, childVal, vm)
}

strats.watch = ...
strats.props =
strats.methods =
strats.inject =
strats.computed = ...

// 默认策略
const defaultStrat = function (parentVal: any, childVal: any): any {
  return childVal === undefined
    ? parentVal
    : childVal
}
```
</details>

## 响应式数据原理(订阅-发布) [^3]

- Vue.js的响应式原理依赖于Object.defineProperty，尤大大在Vue.js文档中就已经提到过，这也是Vue.js不支持IE8 以及更低版本浏览器的原因。Vue通过设定对象属性的 setter/getter 方法来监听数据的变化，通过getter进行依赖收集，而每个setter方法就是一个观察者，在数据变更的时候通知订阅者更新视图

<details>
<summary>Observer</summary>

```js
// https://github.com/vuejs/vue/blob/2.6/src/core/observer/index.js#L37
export class Observer {
  value: any;
  dep: Dep; // https://github.com/vuejs/vue/blob/2.6/src/core/observer/dep.js
  vmCount: number; // number of vms that have this object as root $data

  constructor (value: any) {
    this.value = value
    this.dep = new Dep()
    this.vmCount = 0
    def(value, '__ob__', this)
    if (Array.isArray(value)) {
      if (hasProto) {
        protoAugment(value, arrayMethods)
      } else {
        copyAugment(value, arrayMethods, arrayKeys)
      }
      // 数组时(data.list)，循环给每个元素的属性添加观察者
      this.observeArray(value)
    } else {
      // 对应非数组时(data.obj)，遍历value的属性，通过Object.defineProperty方法来添加getter/setter
      this.walk(value)
    }
  }

  walk (obj: Object) {
    const keys = Object.keys(obj)
    for (let i = 0; i < keys.length; i++) {
      // 通过Object.defineProperty方法来给对象(data.obj)每个属性添加getter/setter
      defineReactive(obj, keys[i])
    }
  }

  observeArray (items: Array<any>) {
    for (let i = 0, l = items.length; i < l; i++) {
      // 内部调用new Observer(value)对传入参数进行观测，相当于递归执行 this.walk(value)
      observe(items[i])
    }
  }
}

// https://github.com/vuejs/vue/blob/2.6/src/core/observer/index.js#L135
export function defineReactive (
 obj: Object,
 key: string,
 val: any,
 customSetter?: ?Function,
 shallow?: boolean
) {
  // Dep即订阅器，主要做了2件事情：dep.depend()、dep.notify()
  const dep = new Dep()
  ...
  Object.defineProperty(obj, key, {
      ...
      get: function reactiveGetter () {
        ...
        dep.depend()
        ...
        return value
      },
      set: function reactiveSetter (newVal) {
        ...
        dep.notify()
      }
    })
}
```
</details>


---

参考文章

[^1]: https://github.com/muwoo/blogs/blob/master/src/Vue/1.md
[^2]: https://github.com/muwoo/blogs/blob/master/src/Vue/2.md
[^3]: https://github.com/muwoo/blogs/blob/master/src/Vue/3.md

