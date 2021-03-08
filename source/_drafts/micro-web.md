---
layout: "post"
title: "微前端"
date: "2021-03-03 20:35"
categories: web
tags: [vue]
---

## 简介

- 微前端: 由微服务衍生而来
- 微前端架构中一般会有个容器应用（container application）将各子应用(Bundle)集成起来 [^1]
- 多 Bundle 集成方式
    - 服务端集成：如服务端渲染SSR
    - 构建时集成：如Code Splitting
        - 常见的构建时集成方式是将子应用发布成独立的 npm 包，共同作为主应用的依赖项，构建生成一个供部署的 JS Bundle。然而，构建时集成最大的问题是会在发布阶段造成耦合，任何一个子应用有变更，都要整个重新编译
    - 运行时集成：如通过 iframe、JS、Web Components 等方式
        - iframe实现缺点：https://www.yuque.com/kuitos/gky7yw/gesexv
- SPA(SinglePage Web Application)单页应用和MPA(MultiPage Application)多页应用区别参考：https://juejin.cn/post/6844903512107663368
- 相关资源
    - [vue动态组件和异步组件说明](https://cn.vuejs.org/v2/guide/components-dynamic-async.html)
    - [使用http-vue-loader可在非单页应用中引入.vue组件](https://github.com/FranckFreiburger/http-vue-loader)
    - [可插拔式系统讨论](https://v2ex.com/t/581581)
- TODO
    - https://blog.csdn.net/weixin_42234168/article/details/112180703
- 相关框架
    - [qiankun](#qiankun)
    - [飞冰icestark](#飞冰icestark)
    - [Alfa](https://github.com/aliyun/alibabacloud-alfa)


## qiankun

- [蚂蚁金服qiankun(乾坤)](https://github.com/umijs/qiankun)
- 基于[single-spa](https://github.com/single-spa/single-spa)实现
    - 参考：[每日优鲜供应链前端基于single-spa改造介绍](https://juejin.cn/post/6844903943873675271)
    - [基于 vue 示例](https://github.com/joeldenning/coexisting-vue-microfrontends)
    - [子项目为 vue & react & angular 结合示例](https://gitee.com/Janlaywss/vue-single-spa/tree/master)
- 主应用通过`history.pushState(state, title[, url])`跳转到微应用
- 基于Fetch(类似ajax)获取微应用页面，并将其加入到相应DOM(此时是同一个域)，因此微应用可以获取到主应用的所有状态(Cookies/Storeage) [^2]
- 由于主应用和微应用最终输入同源页面，因此所有状态(Cookies/Storeage)共享，对于不想共享的数据可增加key前缀区分
- 相关文章
    - ["巨石应用"的诞生](https://juejin.cn/post/6889956096501350408)
    - [从qiankun看子应用加载](https://juejin.cn/post/6891888458919641096)
    - [从qiankun看沙箱隔离](https://juejin.cn/post/6896643767353212935)

### 沙箱隔离

- qiankun 做沙箱隔离主要分为三种：legacySandBox、proxySandBox、snapshotSandBox
- 其中 legacySandBox、proxySandBox 是基于 Proxy API 来实现的，在不支持 Proxy API 的低版本浏览器中，会降级为 snapshotSandBox。在现版本中，legacySandBox 仅用于 singular 单实例模式，而多实例模式会使用 proxySandBox
- [proxySandbox]()

```js
function createFakeWindow(global: Window) {
    // 对于getter类型的参数单独放置在Map中，读取时效率更高(其实fakeWindow中也存在)
    const propertiesWithGetter = new Map<PropertyKey, boolean>();
    // 模拟一个window对象，如进入子应用则是使用的此对象
    const fakeWindow = {} as FakeWindow;

    // make top/self/window property configurable and writable, otherwise it will cause TypeError while get trap return.
    // 将 top/self/window 设置成 configurable 和 writable，否则通过 Proxy 进行 getOwnPropertyDescriptor 代理时会报错
    Object.getOwnPropertyNames(global).filter(...).forEach(...)

    return {
        fakeWindow,
        propertiesWithGetter,
    };
}

export default class ProxySandbox implements SandBox {
    active() {
        if (!this.sandboxRunning) activeSandboxCount++;
        this.sandboxRunning = true;
    }
}
```



## 飞冰icestark

- [飞冰icestark](https://github.com/ice-lab/icestark)，为飞冰(ice生态的一个微前端解决方案
- 主应用和微应用皆支持 React/Vue/Angular... 等不同框架
- 支持VSCode拖拽组件







---

参考文章

[^1]: https://zhuanlan.zhihu.com/p/96464401
[^2]: (https://developer.mozilla.org/zh-CN/docs/Web/API/Fetch_API/Using_Fetch)


