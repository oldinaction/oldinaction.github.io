---
layout: "post"
title: "uni-app"
date: "2017-10-10 21:34"
categories: [web]
tags: [H5, 小程序, App]
---

## 简介

- [官网](https://uniapp.dcloud.io/)
- 组件插件
    - [uviewui](https://www.uviewui.com/)

### 文件

> https://uniapp.dcloud.net.cn/collocation/pages

- `pages.json` 文件用来对 uni-app 进行全局配置，决定页面文件的路径、窗口样式、原生的导航栏、底部的原生tabbar 等
    - 它类似微信小程序中app.json的页面管理部分
- `manifest.json` 文件是应用的配置文件，用于指定应用的名称、图标、权限(如定位)等

    ```json
    // h5模式相关配置
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

## API兼容问题

- [使用Vue.js注意事项](https://uniapp.dcloud.io/use)
    - Vue特性支持表

## 生命周期

> https://uniapp.dcloud.io/collocation/frame/lifecycle

- 应用生命周期
    - `onLaunch` 当uni-app 初始化完成时触发（全局只触发一次）
    - `onShow` 当 uni-app 启动，或从后台进入前台显示
- 页面生命周期中
    - `onLoad` 触发一次
    - `onShow` 每次展示时触发
- onLaunch中进行同步执行后再执行onShow的解决方式

```js
// main.js
Vue.prototype.$onResolve = new Promise(resolve => {
    Vue.prototype.$emitResolve = resolve
})

// App.vue
export default {
    onLaunch: function() {
        // #ifdef H5
        if(this.$utils.isWeiXinH5()) {
            wechat.weChatJsSdkSignature('/m/auth/weChatJsSdkSignature').then(() => {
                this.$emitResolve() // 释放
            })
        } else {
            this.$emitResolve() // else的情况一定也要释放，否则页面可能会卡在await
        }
        // #endif
    },
    onShow: function() {
        // #ifdef H5
        this.h5Login()
        // #endif
    },
    methods: {
        // onLaunch、onShow不能定义为async
        async h5Login() {
            await this.$onResolve
            // do somthing
        }
    }
}
```

## 小技巧

### 环境问题

- 可使用HBuilder创建项目或vue-cli创建项目，[参考文档](https://uniapp.dcloud.net.cn/quickstart)
    - 发布app必须通过HBuilder，vue-cli可以发布h5/小程序。基于vue-cli创建项目时默认安装了cross-env插件，基于此插件在启动命令前增加了NODE_ENV等参数的配置
    - HBuilder创建的项目默认无package.json，可手动创建或npm init创建，之后可通过npm安装插件
    - HBuilder创建的项目代码对应vue-cli创建项目的src代码
    - vue-cli创建的项目还需手动安装less相关依赖(`cnpm install less less-loader -D`)或sass(`cnpm install sass-loader node-sass -D`)
- **多环境编译问题**
    - 使用XBuilder开发(一些依赖安装在HBuilder中)
        - 点击运行获取到的`process.env.NODE_ENV = 'development'`，点击发行获取到的是production
            - HBuilder中点击运行或发行便会把此环境对应的API地址编译成微信小程序代码，之后小程序上传的便是此时编译的地址(微信小程序中无法获取process.env.NODE_ENV)。因此发布线上小程序需要点击发行
        - 增加编译时的环境变量或使用cross-env定义script，参考上文[文件-package.json](#文件)
    - 使用vscode等开发(vue-cli创建项目，依赖全部安装在项目中)
        - 使用cross-env定义script

### 其他

- uni.navigateTo 不关闭之前页面，uni.redirectTo 关闭之前页面，uni.switchTab 关闭之前页面并显示Tab主页
    - 所有的路由都是基于page.json中的路径，注意如果路径中无.vue后缀，则路由时的路径也不能有.vue后缀
- navigator标签问题：当登录后，通过uni.switchTab进入到首页，首页此时如果是使用`<navigator url="../hello">`，会导致第一次进入时无法路由。解决方法使用绝对路径`<navigator url="/pages/hello">`，且不能带.vue后缀
- 路由挂载：需要跳转的页面必须在page.json中注册过。如需采用 Vue Router 方式管理路由，可在uni-app插件市场找Vue-Router相关插件
- uni.setStorageSync 和 uni.getStorageSync 可直接操作对象(无需虚拟化成字符串)
- uni.showToastr 无Error图片(微信也没有)
- 需使用web-view组件代替iframe，嵌套页才会在微信小程序中显示
    - 且web-view会撑满全屏，即无视非web-view中的元素
    - uni-app本身可使用iframe，可在h5下显示，但是微信小程序中不会显示
- 判断平台
    - 编译期判断，使用`// #ifdef H5`，`// #endif`
    - 运行期判断，`uni.getSystemInfoSync().platform = android|ios|devtools` 判断客户端环境是 Android、iOS 还是小程序开发工具
- 扫码功能参考[uni.scanCode](https://uniapp.dcloud.net.cn/api/system/barcode?id=scancode)、[springboot-vue.md#扫码](/_posts/arch/springboot-vue.md#扫码)
- 路径问题
    - uni.navigateTo可以使用相对路径或绝对路径，就算最终访问路径增加了publicPath等前缀也可使用/pages/xxx的绝对路径
- H5多项目编译(路径前缀)：定义manifest.json中的`publicPath`和`router.base`，参考[manifest.json](#文件)

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

## 常见问题

- 访问出现Invalid Host header问题(使用反向代理时出现，如使用花生壳)
    - 修改uni-app的manifest.json文件 - 源码视图，增加`"devServer": {"disableHostCheck" : true}`

## 兼容问题

- 华为输入法输入英文时可能带下划线，导致输入abc结果传到后台只有a
- IOS 和 Android 对时间的解析有区别 [^1]
    - `new Date('2018-03-30 12:00:00')` IOS 中对于中划线无法解析，Android 可正常解析
    - 解决方案：`Date.parse(new Date('2018/03/30 12:00:00')) || Date.parse(new Date('2018-03-30 12:00:00'))`





---

参考文章

[^1]: https://www.jianshu.com/p/a6b3221807f0
