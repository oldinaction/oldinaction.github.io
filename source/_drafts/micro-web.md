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
    - 父子应用数据同步：https://blog.csdn.net/weixin_42234168/article/details/112180703
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

### 多应用部署及路由流程

```bash
## 整体流程
# 主应用端点 /sqbiz
# 主应用点击菜单(从后台获取或从本地读取的菜单路径)，如：/sqbiz/module/jxc/xxx(需要加上主应用端点)
# 主应用配置好如果以 /sqbiz/module/ 开头的路径，则跳转到子应用，此时可执行 history.pushState 推送路由
# 主应用执行 router.beforeEach, to.path=/module/jxc/xxx (打印的vue-router的值会自动刨去主应用端点 /sqbiz)
# 此时浏览器路径为 http://localhost/sqbiz/module/jxc/xxx 则触发activeRule路径，从而通过fetch(ajax)请求地址 http://localhost/sqbiz/jxc/xxx (entry路径)
# 主应用执行 qiankun.beforeLoad
# 此时由 nginx 访问到子应用 http://localhost/sqbiz/jxc/xxx
# 子应用执行 main.bootstrap(qiankun)
# 主应用执行 qiankun.beforeMount
# 子应用执行 main.mount(qiankun)
# 子应用执行 router.beforeEach, to.path=/xxx (打印的vue-router的值会自动刨去子应用端点 /sqbiz/module/jxc/，注意此处是基于浏览器地址来的)

## qiankun路由配置
registerMicroApps(
    [{
        name: 'sqbiz-module-jxc',
        entry: '/sqbiz/jxc/',
        container: '#subapp-viewport',
        activeRule: '/sqbiz/module/jxc'
    }, {
        name: 'sqbiz-plugin-minions-app',
        entry: '//localhost/sqbiz/minions/',
        container: '#subapp-viewport',
        activeRule: '/sqbiz/plugin/minions'
    }],
    callback
);

## 主应用配置
# VUE_APP_PUBLIC_PATH=sqbiz 主应用端点
# vue.config配置
let publicPath = process.env.VUE_APP_PUBLIC_PATH ? ('/' + process.env.VUE_APP_PUBLIC_PATH + '/') : '/'
module.exports = {
  publicPath: publicPath,
  outputDir: process.env.VUE_APP_PUBLIC_PATH || 'dist', // 会在项目目录创建 sqbiz 产出文件夹
}
# 路由配置
const prefix = process.env.VUE_APP_PUBLIC_PATH ? ('/' + process.env.VUE_APP_PUBLIC_PATH + '/') : '/'
new VueRouter({
    base: prefix,
    mode: 'history',
    routes: []
})

## 子应用配置
# VUE_APP_PUBLIC_PATH=sqbiz/jxc 子应用端点
# VUE_APP_QIANKUN_MAIN_BASE=/sqbiz 为主应用的端点，如果在根目录下，留空即可
# vue.config配置
let publicPath = process.env.VUE_APP_PUBLIC_PATH ? ('/' + process.env.VUE_APP_PUBLIC_PATH + '/') : '/'
module.exports = {
  publicPath: publicPath,
  outputDir: process.env.VUE_APP_PUBLIC_PATH || 'dist', // 会在项目目录创建 sqbiz/jxc 产出文件夹
}
# 路由配置，注意此处前面需要加主应用的端点
const prefix = process.env.VUE_APP_PUBLIC_PATH ? ('/' + process.env.VUE_APP_PUBLIC_PATH + '/') : '/'
new VueRouter({
    base: window.__POWERED_BY_QIANKUN__ ? process.env.VUE_APP_QIANKUN_MAIN_BASE +  '/module/jxc/' : prefix,
    mode: 'history',
    routes: []
})

# nginx配置
server {
	listen       80;
	server_name  localhost;
	
	gzip on;
	gzip_types text/plain application/x-javascript application/javascript text/javascript text/css application/xml text/xml;
	
	location /sqbiz/api/ {
		proxy_pass http://127.0.0.1:8800/api/;
	}
	
	location = /sqbiz/index.html {
		add_header Cache-Control "no-cache, no-store";
		root   D:/gitwork/oschina/sqbiz/sqbiz-web/sqbiz-main;
		index  index.html index.htm;
	}
	
	location = /sqbiz/jxc/index.html {
		add_header Cache-Control "no-cache, no-store";
		root   D:/gitwork/oschina/sqbiz/sqbiz-web/sqbiz-module/sqbiz-jxc;
		index  index.html index.htm;
	}
	
	location ^~ /sqbiz/jxc/ {
		root   D:/gitwork/oschina/sqbiz/sqbiz-web/sqbiz-module/sqbiz-jxc; # 子模块 sqbiz-jxc 根目录
		try_files $uri $uri/ /sqbiz/jxc/index.html;
		if ($request_filename ~* .*\.(?:htm|html)$) {
			add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
		}
	}
	
	location ^~ /sqbiz/ {
		root   D:/gitwork/oschina/sqbiz/sqbiz-web/sqbiz-main; # 主模块根目录
		try_files $uri $uri/ /sqbiz/index.html;
		if ($request_filename ~* .*\.(?:htm|html)$) {
			add_header Cache-Control "private, no-store, no-cache, must-revalidate, proxy-revalidate";
		}
	}

    location = / {
        # rewrite / http://192.168.1.100/sqbiz/ break;
        rewrite / http://$server_name/sqbiz/ break;
    }
}
```

### 沙箱隔离

- 由于主应用和子应用在同一个窗口，因此不进行沙箱隔离，则主子应用访问到同一个window，可能导致数据混乱
- qiankun 做沙箱隔离主要分为三种：legacySandBox、proxySandBox、snapshotSandBox
- 其中 legacySandBox、proxySandBox 是基于 Proxy API 来实现的，在不支持 Proxy API 的低版本浏览器中，会降级为 snapshotSandBox。在现版本中，legacySandBox 仅用于 singular 单实例模式，而多实例模式会使用 proxySandBox
- [proxySandbox](https://github.com/umijs/qiankun/blob/v2.4.0/src/sandbox/proxySandbox.ts)

```js
function createFakeWindow(global: Window) {
    // 对于non-configurable且有getter类型的参数单独放置在Map中，读取时效率更高(其实fakeWindow中也存在)，如document(父子应用共享)
    const propertiesWithGetter = new Map<PropertyKey, boolean>();
    // 虚拟一个window对象，如进入子应用则是使用的此对象
    const fakeWindow = {} as FakeWindow;

    // copy the non-configurable property of global to fakeWindow
    // 如 top/self/window/document 等是全局共享的
    // make top/self/window property configurable and writable, otherwise it will cause TypeError while get trap return.
    // 将 top/self/window 设置成 configurable 和 writable，否则通过 Proxy 进行 getOwnPropertyDescriptor 代理时会报错
    Object.getOwnPropertyNames(global).filter(...).forEach(...)

    return {
        fakeWindow,
        propertiesWithGetter,
    };
}

// 每次进入微应用会实例化 ProxySandbox, 重新创建虚拟window
export default class ProxySandbox implements SandBox {
    // window 值变更记录
    private updatedValueSet = new Set<PropertyKey>();

    // 激活沙箱
    active() {
        if (!this.sandboxRunning) activeSandboxCount++;
        this.sandboxRunning = true;
    }

    // 注销沙箱
    inactive() {
        if (process.env.NODE_ENV === 'development') {
            console.info(`[qiankun:sandbox] ${this.name} modified global properties restore...`, [
                ...this.updatedValueSet.keys(),
            ]);
        }
        // ...
    }

    constructor(name: string) {
        // 原始window，即主应用window
        const rawWindow = window;
        // 创建虚拟window
        const { fakeWindow, propertiesWithGetter } = createFakeWindow(rawWindow);

        const proxy = new Proxy(fakeWindow, {
            set: (target: FakeWindow, p: PropertyKey, value: any): boolean => {
                if (this.sandboxRunning) {
                    // We must kept its description while the property existed in rawWindow before
                    if (!target.hasOwnProperty(p) && rawWindow.hasOwnProperty(p)) {
                        // 原window中有的，且虚拟window中不存在的。此时如果修改，则是直接修改的原window，需要判断是否为 writable
                        const descriptor = Object.getOwnPropertyDescriptor(rawWindow, p);
                        const { writable, configurable, enumerable } = descriptor!;
                        if (writable) {
                            Object.defineProperty(target, p, {
                                configurable,
                                enumerable,
                                writable,
                                value,
                            });
                        }
                    } else {
                        // 虚拟window中存在的，或原window不存在的，全部保存到虚拟window中
                        target[p] = value;
                    }

                    // 对于白名单中的全局变量，可直接修改原window的值
                    if (variableWhiteList.indexOf(p) !== -1) {
                        rawWindow[p] = value;
                    }

                    // 将修改过的全局变量保存，注销时会打印出来
                    updatedValueSet.add(p);

                    this.latestSetProp = p;

                    return true;
                }
            },

            // 取值：propertiesWithGetter > 模拟window > 原始window
            get(target: FakeWindow, p: PropertyKey): any {}
        })
    }
}
```

### 常见问题

- 报错：Application died in status LOADING_SOURCE_CODE: You need to export the functional lifecycles in xxx entry
    - 参考：https://qiankun.umijs.org/zh/faq
    - 有可能vue.config.js配置的入口函数存在问题，没有将main.js写成入口函数的最后一个文件，参考[webpack.md#复杂案例](/_posts/web/webpack.md#复杂案例)
- 子项目不支持动态路由(动态从服务端获取路由配置，通过addRoutes加入路由)，基于vue暂未找到方案。https://www.yuque.com/blueju/blog/uxlrlr

## icestark飞冰

- [飞冰icestark](https://github.com/ice-lab/icestark)，为飞冰(ice生态的一个微前端解决方案
- 主应用和微应用皆支持 React/Vue/Angular... 等不同框架
- 支持VSCode拖拽组件







---

参考文章

[^1]: https://zhuanlan.zhihu.com/p/96464401
[^2]: (https://developer.mozilla.org/zh-CN/docs/Web/API/Fetch_API/Using_Fetch)


