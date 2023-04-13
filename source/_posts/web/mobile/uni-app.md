---
layout: "post"
title: "uni-app"
date: "2017-10-10 21:34"
categories: [web]
tags: [H5, 小程序, App, mobile]
---

## 简介

- [官网](https://uniapp.dcloud.io/)
- 组件插件
    - [uviewui](https://www.uviewui.com/)

### 项目初始化

- 可使用HBuilder创建项目或[vue-cli](https://uniapp.dcloud.net.cn/quickstart-cli)创建项目
    - **发布app必须通过HBuilder，vue-cli可以发布h5/小程序。**基于vue-cli创建项目时默认安装了cross-env插件，基于此插件在启动命令前增加了NODE_ENV等参数的配置
    - HBuilder创建的项目默认无package.json，可手动创建或npm init创建，之后可通过npm安装插件
    - HBuilder创建的项目代码对应vue-cli创建项目的src代码
    - vue-cli创建的项目还需手动安装less相关依赖(`cnpm install less less-loader -D`)或sass(`cnpm install sass-loader node-sass -D`)
- 使用vscode进行开发
    - `vue create -p dcloudio/uni-preset-vue my-project` 创建临时项目(迁移原HBuilder项目也建议先创建一个临时项目进行操作)
    - 选择 Hello uni-app
    - 生成后删除/src下的文件，复制原先项目的文件到/src下
    - 其他参考：https://ask.dcloud.net.cn/article/36286
- **多环境编译问题**
    - 使用XBuilder开发(一些依赖安装在HBuilder中)
        - 点击运行获取到的`process.env.NODE_ENV = 'development'`，点击发行获取到的是production
            - HBuilder中点击运行或发行便会把此环境对应的API地址编译成微信小程序代码，之后小程序上传的便是此时编译的地址(微信小程序中无法获取process.env.NODE_ENV)。因此发布线上小程序需要点击XBuilder发行
        - 增加编译时的环境变量或使用cross-env定义script，参考上文[文件-package.json](#文件)
    - 使用vscode等开发(vue-cli创建项目，依赖全部安装在项目中)
        - 使用cross-env定义script

### 文件结构

> https://uniapp.dcloud.net.cn/collocation/pages

- `pages.json` 文件用来对 uni-app 进行全局配置，决定页面文件的路径、窗口样式、原生的导航栏、底部的原生tabbar 等
    - 它类似微信小程序中app.json的页面管理部分
- `manifest.json` 文件是应用的配置文件，用于指定应用的名称、图标、权限(如定位)等

    ```json
    // h5模式相关配置(非必须)
    "h5" : {
        // 项目发布在/test-demo1/端点下，只支持发行的时候(开发时运行无效)
        "publicPath" : "/test-demo1/",
        "router" : {
            "base" : "/test-demo1/"
        },
        // 本地开发配置
        "devServer" : {
            // 防止出现Invalid Host header问题(使用反向代理时出现)
            "disableHostCheck" : true,
            "port" : 80,
            "publicPath": "/test-demo1/", // 本地访问http://localhost/test-demo1/#/
            "proxy" : {
                // 匹配/api-sq/xxx开头的请求，并将其转发到8080/xxx上(pathRewrite去掉了前缀)。可解决跨域问题
                "/api-sq/" : {
                    "target" : "http://127.0.0.1:8080/", // 请求的目标地址
                    "changeOrigin" : true,
                    "secure" : false,
                    "pathRewrite" : {
                        "^/api-sq" : ""
                    }
                }
            }
        },
        "optimization" : {
            "treeShaking" : {
                "enable" : true
            }
        },
        "uniStatistics" : {
            "enable" : false
        }
    }
    ```
- `package.json` 使用HBuilder编辑创建的项目默认无此文件，可手动创建或npm init创建
    - uni-app在文件中增加uni-app扩展节点，可实现自定义条件编译平台
    - 增加编译时的环境变量，可在package.json文件中增加以下节点，然后再发行-自定义发行菜单中可看到此标题

        ```json
        // 方式一
        "scripts": {
            // 使用VUE_APP_开头定义环境类型；此处UNI_PLATFORM等环境变量在代码中无法获取，但是uni-app可以获取进行判断；NODE_ENV不同编译方式不同(production才会进行代码压缩)
            "h5-test": "D: && cd D:/software/HBuilderX/plugins/uniapp-cli && cross-env UNI_INPUT_DIR=$INIT_CWD/ UNI_OUTPUT_DIR=$INIT_CWD/unpackage/dist/build/h5 UNI_PLATFORM=h5 NODE_ENV=testing VUE_APP_NODE_ENV=testing node bin/uniapp-cli.js",
            "h5-prod": "D: && cd D:/software/HBuilderX/plugins/uniapp-cli && cross-env UNI_INPUT_DIR=$INIT_CWD/ UNI_OUTPUT_DIR=$INIT_CWD/unpackage/dist/build/h5 UNI_PLATFORM=h5 NODE_ENV=production VUE_APP_NODE_ENV=production node bin/uniapp-cli.js"
        },
        // 方式二(实测无效)
        "uni-app": {
            "scripts": { 
                // 自定义脚本(启动方式)，对于内置启动方式可修改 manifest.json
                "build-h5-api1": {
                    "title":"生产环境API地址一(H5)",   
                    "env": {
                        "UNI_PLATFORM": "h5",
                        "NODE_ENV": "production",
                        "APP_ENV": "api1" // 自定义环境变量，实测无效
                    } 
                }  
            }  
        }
        ```
- `App.vue` 是uni-app的主组件，所有页面都是在App.vue下进行切换的，是页面入口文件
    - 作用包括：调用应用生命周期函数、配置全局样式、配置全局的存储globalData。如根据不同访问模式，跳转不同入口页

    ```js
    <script>  
    export default {  
        onLaunch: function() {
			console.log('App Launch. 当uni-app 初始化完成时触发，全局只触发一次');
		},
		onShow: function() {
			console.log('App Show. 当 uni-app 启动，或从后台进入前台显示')

			// #ifdef MP-WEIXIN
			// 微信方式访问，判断是否绑定，若未绑定，跳转欢迎页(进行账号绑定)
			login().then(res => {
				if (res == 'loginUnBind') {
					uni.navigateTo({
						url: '../index/index'
					})
				}
			});
			// #endif

			// #ifdef H5
            // H5模式访问，没有登录则条登录页面
			let token = uni.getStorageSync('token');
			if(token == null || token == "") {
				uni.navigateTo({
					url: './pages/h5Login'
				})
			}
			// #endif
		}  
    }  
    </script>
    ```

## 生命周期

- 应用生命周期: https://uniapp.dcloud.io/collocation/frame/lifecycle
    - `onLaunch` 当uni-app 初始化完成时触发（全局只触发一次）
    - `onShow` 当 uni-app 启动，或从后台进入前台显示
- 页面生命周期中: https://uniapp.dcloud.net.cn/tutorial/page.html#lifecycle
    - `onLoad` 触发一次
    - `onShow` 每次展示时触发
    - `onHide` 无法监听到页面返回(H5和微信小程序都不可以)
    - `onBackPress` 可以监听到H5返回，无法监听到微信小程序返回
- 组件生命周期同Vue: https://uniapp.dcloud.net.cn/tutorial/page.html#componentlifecycle

### onLaunch等同步写法

- Promise/async/await使用参考：[js-release.md#Promise/async/await](/_posts/web/js-release.md#Promise/async/await)
- 基本使用

```js
// onLaunch: function() {} // 这种写法不能在onLaunch前面使用async, 需写成 onLaunch: async function() {}
async onLaunch() {
    await this.initData();
},
async onShow() {
    await this.initData();
},
methods: {
    async initData() {
        await login()
    }
}

// 改写 uni.getProvider 等异步函数。uni.getProvider 为异步函数(接收回调，但返回对象不是Promise，无法使用await等特性)
export const login = () => {
    // 返回 Promise 对象，从而外部可使用 await login()
	return new Promise(resolve => {
		uni.getProvider({
			service: 'oauth',
			success: function(res) {
				if (~res.provider.indexOf('weixin')) {
					uni.login({
                        provider: 'weixin',
                        success: async function(loginRes) {
							let code = loginRes.code;
                            let res = await wxLogin(code)
                            // 释放，标识执行完成
                            resolve(res)
                        }
                        // 或在then中释放
						// success: function(loginRes) {
						// 	let code = loginRes.code;
						// 	wxLogin(code).then(res => {
						// 		resolve(res)
						// 	});
						// }
					});
				}
			}
		});
	})
}
```
- onLaunch的执行和所有页面的onShow/onLoad(App.vue和其他任何页面)执行没有先后顺序，有可能onLaunch没执行完，页面级别的onShow/onLoad就执行了。需要达到 onLaunch 中进行同步执行后，再执行 onShow/onLoad 的需求

```js
// 参考：https://www.lervor.com/archives/128/
// main.js
Vue.prototype.$ready = new Promise(resolve => {
    Vue.prototype.$emitReady = resolve
})

// App.vue
const login = () => {
    postRequest('/m/auth/wxLogin').then(response => {
        console.log(response)
    })
}

export default {
    async onLaunch() {
        // #ifdef H5
        if(this.$utils.isWeiXinH5()) {
            wechat.weChatJsSdkSignature('/m/auth/weChatJsSdkSignature').then(() => {
                // await this.h5Login() // 错误写法. 由于 h5Login 并没有返回 Promise 对象，且内部 login 方法并没有同步执行
                // this.h5Login2() // 错误写法. 此时 h5Login2 内部 login 方法是同步执行了，但是 async h5Login2 表示 h5Login2 为一个异步函数，返回 Promise，导致当前行和之后代码并没有同步执行
                await this.h5Login2() // 正确写法
                this.$emitReady() // 释放
            })
        } else {
            this.$emitReady() // else的情况一定也要释放，否则页面可能会卡在await
        }
        // #endif
    },
    methods: {
        h5Login() {
            console.log(1.1)
            login()
            console.log(1.2) // 不会等login执行完之后再执行
        },
        async h5Login2() {
            console.log(2.1)
            await login()
            console.log(2.2) // 会等login执行完之后再执行
        }
    }
}

// Index.vue
export default {
    // onLoad 和 onShow需要分别设置
    async onLoad() {
        await this.$ready // 等待释放
        // do somthing
    },
    async onShow() {
        await this.$ready // 等待释放
        // do somthing
    }
}
```

## web-view开发

- 参考[weixin.md#web-view开发](/_posts/web/mobile/weixin.md#web-view开发)

## 与Vue写法异同

- 页面上不能直接使用$store，需要通过computed属性映射一次，如果数据比较多可以使用mapState和mapGetters。参考: https://uniapp.dcloud.net.cn/tutorial/vue-vuex.html

    ```js
    computed: {
        ...mapState({
            text: state => state.moduleA.text,
            timestamp: state => state.moduleB.timestamp
        }),
        ...mapGetters([
            'timeString'
        ])
    }
    ```
- 监控路由属性及参数获取
    - uni-app不能watch $route属性，只能通过onShow函数来控制每次显示页面时的动作
    - this.$route.query只能在H5模式下获取到参数，微信小程序无法获取

    ```js
    /**
     * 获取当前页面请求路径
    */
    export const getCurPage = () => {
        // uni-app内置函数
        const pages = getCurrentPages()
        return (pages && pages.length > 0) ? pages[pages.length - 1] : {}
    }
    /**
    * 获取当前页面请求路径所有参数
    */
    export const getCurQueryAll = () => {
        const curPage = getCurPage()
        // 在微信小程序或是app中，通过curPage.options；如果是H5，则需要curPage.$route.query
        return curPage.options || (curPage.$route && curPage.$route.query)
    }

    export const getUrQuery = (name) => {
        return (
            decodeURIComponent(
                (new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.href) || [, ''])[1].replace(
                    /\+/g, '%20')
            ) || null
        )
    }
    ```
- 不支持`<br/>`换行

    ```html
    <!-- 使用\n的时候，一定是在<text>标签内，如果在<view>标签中，\n并没有折行左右，只是显示一个空格 -->
    <text>欢迎\n使用</text>
    <!-- 会按照当前看到的排版 -->
    <text>
        欢迎

        使用
    </text>
    ```
- 空格问题: https://uniapp.dcloud.net.cn/component/text.html

    ```html
    <!-- 不能直接写成 {{ '&ensp;' }} -->
    <text decode>{{ blank }}</text>

    {
        blank: '&ensp;'
    }
    ```

## 常见业务

- 多环境编译问题：参考[项目初始化](#项目初始化)

### 其他

- uni.navigateTo 不关闭之前页面，uni.redirectTo 关闭之前页面，uni.switchTab 关闭之前页面并显示Tab主页
    - 所有的路由都是基于page.json中的路径，注意如果路径中无.vue后缀，则路由时的路径也不能有.vue后缀
- navigator标签问题：当登录后，通过uni.switchTab进入到首页，首页此时如果是使用`<navigator url="../hello">`，会导致第一次进入时无法路由。解决方法使用绝对路径`<navigator url="/pages/hello">`，且不能带.vue后缀
- 路由挂载：需要跳转的页面必须在page.json中注册过。如需采用 Vue Router 方式管理路由，可在uni-app插件市场找Vue-Router相关插件
- uni.setStorageSync 和 uni.getStorageSync 可直接操作对象(无需序列化成字符串)
- [uni.showToast](https://uniapp.dcloud.io/api/ui/prompt?id=showtoast) 无Error图片(微信也没有)

    ```js
    // 默认是对钩的成功图标
    uni.showToast({
        title: '请输入需要生成的内容'
    })

    // 无图标，可作为错误消息
    uni.showToast({
        title: '请输入需要生成的内容',
        icon: 'none'
    })
    ```
- 需使用web-view组件代替iframe，嵌套页才会在微信小程序中显示
    - 且web-view会撑满全屏，即无视非web-view中的元素
    - uni-app本身可使用iframe，可在h5下显示，但是微信小程序中不会显示
- 判断平台
    - 编译期判断，使用`// #ifdef H5`，`// #endif`
    - 运行期判断，`uni.getSystemInfoSync().platform = android|ios|devtools` 判断客户端环境是 Android、iOS 还是小程序开发工具
- 扫码功能参考[uni.scanCode](https://uniapp.dcloud.net.cn/api/system/barcode?id=scancode)、[js-tools.md#扫码/条码生成](/_posts/web/js-tools.md#扫码/条码生成)
- 路径问题
    - uni.navigateTo可以使用相对路径或绝对路径，就算最终访问路径增加了publicPath等前缀也可使用/pages/xxx的绝对路径
- H5多项目编译(路径前缀)：定义manifest.json中的`publicPath`和`router.base`，参考[manifest.json](#项目文件)
- `web-view`使用参考[weixin.md#web-view开发](/_posts/web/mobile/weixin.md#web-view开发)
- `rich-text`可以通过vue的v-html进行渲染，但是传入的字符串不能包含body、html等节点(如果使用了不受信任的HTML节点，该节点及其所有子节点将会被移除)
- css绑定变量：https://blog.csdn.net/zz00008888/article/details/126222530
- css单位问题：https://www.jianshu.com/p/ff88a9d2a1aa

    ```bash
    ios：pt
    android：dp
    web：px、rem、em
    微信小程序：rpx
    uniapp：upx

    单位换算（正常情况下）
    1pt = 1dp = 2px
    2rpx = 2upx = 1px
    ```
- 小程序保存图片到相册：https://blog.csdn.net/weixin_64493170/article/details/127408730
- uniapp中websocket的使用
    - 官方API：https://uniapp.dcloud.net.cn/api/request/websocket.html
    - 适用页面存在多个长连接 https://www.jianshu.com/p/7ecd36afea02
    - 适用页面只会存在单个长连接 https://www.jianshu.com/p/d7dfe4bbf82b
    - 感觉还要更好的方法，参考[SpringBoot整合WebSocket](/_posts/linux/websocket.md#整合SpringBoot)
- 小程序分享及分享后无法返回的问题
    - 无法返回问题: https://www.crmeb.com/ask/thread/11593.html
        - 如果使用ColorUI，需修改`cu-custom`导航组件的返回事件
- 敏感词检测：https://zhuanlan.zhihu.com/p/363463142?utm_id=0

### 样式

- uni.showToast 被遮盖：全局增加样式`uni-toast {z-index: 999999;}`

## uView插件

- u-cell-item使用slot时标题无法增加空格(使用padding解决)

```html
<u-cell-group>
    <u-cell-item>
        <span slot="title" class="u-p-l-10">退出</span>
        <uni-icons slot="icon" type="close" size="17" style="color: #606266;"></uni-icons>
    </u-cell-item>
</u-cell-group>
```

## 兼容问题

### API兼容问题

- [使用Vue.js注意事项](https://uniapp.dcloud.io/use)
    - Vue特性支持表

### 其他兼容问题

- 华为输入法输入英文时可能带下划线，导致输入abc结果传到后台只有a
- IOS 和 Android 对时间的解析有区别 [^1]
    - `new Date('2018-03-30 12:00:00')` IOS 中对于中划线无法解析，Android 可正常解析
    - 解决方案：`Date.parse(new Date('2018/03/30 12:00:00')) || Date.parse(new Date('2018-03-30 12:00:00'))`

## 常见问题

- 访问出现Invalid Host header问题(使用反向代理时出现，如使用花生壳)
    - 修改uni-app的manifest.json文件 - 源码视图，增加`"devServer": {"disableHostCheck" : true}`
- 真机调试
    - IOS需要开放微信访问本地网络




---

参考文章

[^1]: https://www.jianshu.com/p/a6b3221807f0
