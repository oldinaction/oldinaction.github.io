---
layout: "post"
title: "uni-app"
date: "2017-10-10 21:34"
categories: [web]
tags: [H5, 小程序, App, mobile]
---

## 简介

- [官网](https://uniapp.dcloud.io/)
- [uni-app-x](https://doc.dcloud.net.cn/uni-app-x/)
    - uni-app x，是下一代 uni-app。他没有使用js和webview，它基于 uts 语言。在App端，uts在iOS编译为swift、在Android编译为kotlin、web/小程序平台编译为JavaScript
    - uts替代的是js，而uvue替代的就是html和css。可以理解为uts类似dart，而uvue类似flutter
    - uts和ts很相似，但为了跨端，uts进行了一些约束和特定平台的增补；uvue是一套基于uts的、兼容vue语法的、跨iOS和Android的、原生渲染引擎

### 项目初始化运行及发布

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
- 发布
    - 小程序
        - 发行 - 发行到微信小程序(此时process.env.NODE_ENV才等于production)
        - 配置小程序ID
    - H5
        - 发行 - 网站PC/手机H5
        - 可在manifest.json - Web配置中对路由模式和运行基础路径进行配置(一般留空或者配置成`./`)
        - 打包后可在`unpackage/dist/build/h5`找到打包产物
        - 配置nginx

        ```bash
        # 默认路由模式为history. ** 注意: 此时路由会带#，不能去掉 **
        server {
            listen   80;
            server_name www.aezo.cn;
            # 无需配置 location / 和 try_files
            root   /home/aezocn/h5;
            index index.html;
        }
        ```

### 文件结构

> https://uniapp.dcloud.net.cn/collocation/pages

- `pages.json` 文件用来对 uni-app 进行全局配置，决定页面文件的路径、窗口样式、原生的导航栏、底部的原生tabbar 等
    - 它类似微信小程序中app.json的页面管理部分
- `manifest.json` 文件是应用的配置文件，用于指定应用的名称、图标、权限(如定位)等

    ```json
    // h5模式相关配置(非必须)
    "h5" : {
        // 项目发布在/test-demo1/端点下，只支持发行的时候(开发时运行无效)
        "publicPath" : "/test-demo1/", // 可不用设置
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
		onShow () {
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

## 知识点

### 条件编译

- [条件编译](https://uniapp.dcloud.net.cn/tutorial/platform.html)
- MP为小程序，MP-WEIXIN、MP-ALIPAY
- APP-PLUS基于HTML5+的JS引擎渲染的，APP-NVUE为App nvue 页面，APP-ANDROID为UTS原生编译方式，APP指所有App平台

### 生命周期

- 应用生命周期(仅在App.vue页面生效): https://uniapp.dcloud.io/collocation/frame/lifecycle
    - `onLaunch` 当uni-app 初始化完成时触发（全局只触发一次）
    - `onShow` 当 uni-app 启动，或从后台进入前台显示
- 页面生命周期中: https://uniapp.dcloud.net.cn/tutorial/page.html#lifecycle
    - `onLoad` 页面加载触发一次(如果是vue文件是以组件的形式加载，则不会触发此方法，而会触发created方法)
    - `onShow` 每次展示时触发(后退过来的也会触发)
    - `onHide` 页面影藏时触发，如navigateTo；无法监听到页面返回/后退(H5和微信小程序都不可以)
    - `onUnload` 页面卸载时触发，如redirectTo
    - `onBackPress` 适用于app、H5、支付宝小程序，无法监听到微信小程序返回
- 组件生命周期同Vue: https://uniapp.dcloud.net.cn/tutorial/page.html#componentlifecycle

#### onLaunch等同步写法

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
    // onLaunch onShow 同时调用，会执行多次
    async initData() {
        await login()
    }
}

// 改写 uni.getProvider 等回调函数。uni.getProvider 为回调函数(接收回调，但返回对象不是Promise，无法使用await等特性)
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
- onLaunch的执行和所有页面的onLoad/onShow(App.vue和其他任何页面)执行没有先后顺序，有可能onLaunch没执行完，页面级别的onShow/onLoad就执行了。需要达到 onLaunch 中进行同步执行后，再执行 onShow/onLoad 的需求

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
    // onLoad 和 onShow需要分别设置，会调用完onLoad就调用onShow(此处的调用完并不等于onLoad要执行完成)
    async onLoad(options) {
        // options.jsonStr 可获取url中的参数jsonStr(JSON字符串传递时需要encodeURIComponent，此处读取后需要decodeURIComponent再解析成JSON对象)
        // switchTab时，options无法获取url中的参数，解决参考：https://segmentfault.com/a/1190000038993623
        await this.$ready // 等待释放
        // do somthing

        // 可使用此方式让onShow中的代码优先执行
        // setTimeout(() => {}, 0) // 或者设置成100毫秒
    },
    async onShow() {
        await this.$ready // 等待释放
        // do somthing
    }
}
```

### 路由相关

- 路由相关: https://uniapp.dcloud.net.cn/tutorial/page.html#%E8%B7%AF%E7%94%B1
    - 页面跳转
        - uni.navigateTo 不关闭之前页面(之前页面代码还会继续执行，导航条显示返回按钮)
        - uni.redirectTo 关闭之前页面，打开新页面(**未自定义导航条的情况下，此时首页左上角会显示返回首页按钮，可通过API进行影藏此按钮；没有通过js控制显示返回首页按钮的API**)
        - uni.switchTab 关闭之前页面并显示Tab主页
        - uni.reLaunch 关闭之前页面并打开某个页面
        - uni.navigateBack 关闭当前页面，返回上一页面或多级页面
            - H5模式下，浏览器刷新后无法通过uni.navigateBack返回上一页；可使用history对象解决，参考squni.js
    - 路径问题
        - uni.navigateTo可以使用相对路径或绝对路径，就算最终访问路径增加了publicPath等前缀也可使用/pages/xxx的绝对路径
        - 所有的路由都是基于page.json中的路径，注意如果路径中无.vue后缀，则路由时的路径也不能有.vue后缀
    - navigator标签问题
        - 当登录后，通过uni.switchTab进入到首页，首页此时如果是使用`<navigator url="../hello">`，会导致第一次进入时无法路由
        - 解决方法使用绝对路径`<navigator url="/pages/hello">`，且不能带.vue后缀
    - 路由挂载：需要跳转的页面必须在page.json中注册过。如需采用 Vue Router 方式管理路由，可在uni-app插件市场找Vue-Router相关插件
- 跳转小程序(第三方小程序)：https://uniapp.dcloud.net.cn/api/other/open-miniprogram.html#navigatetominiprogram
    - 参考：https://blog.csdn.net/m0_47791238/article/details/130643962

```js
// 跳转小程序
uni.navigateToMiniProgram({
  appId: '',
  path: 'pages/index/index?id=123',
  extraData: {
    'data1': 'test'
  },
  success(res) {
    // 打开成功
  }
}

// 跳转会上一个小程序: 只有当另一个小程序跳转到当前小程序时才会能调用成功
uni.navigateBackMiniProgram()

// 跳转半屏小程序. 不支持跳转到个人小程序，且绑定的目标小程序最多10个，绑定时需要目标小程序审核
// 官方文档说还需将目标appId配置到 manifest.json -> mp-weixin -> embeddedAppIdList 数组中(跳转兔小巢时没配置也可以)
uni.openEmbeddedMiniProgram({
    appId: '',
    path: 'pages/main/index'
})
```

### easycom组件规范

- [easycom](https://uniapp.dcloud.net.cn/collocation/pages.html#easycom)
- [uni_modules](https://uniapp.dcloud.net.cn/plugin/uni_modules.html)
- 只要组件安装在项目根目录或uni_modules的components目录下，并符合components/组件名称/组件名称.vue或uni_modules/插件ID/components/组件名称/组件名称.vue目录结构。就可以不用引用(import)、注册，直接在页面中使用

### vue/nvue/uvue文件

- uni-app **App 端**内置了一个基于 weex 改进的原生渲染引擎，提供了原生渲染能力
    - 在 App 端，如果使用 vue 页面，则使用 webview 渲染；如果使用 `nvue` 页面(native vue 的缩写)，则使用原生渲染
    - 虽然 nvue 也可以多端编译，输出 H5 和小程序，但 nvue 的 css 写法受限，所以如果你不开发 App，那么不需要使用 nvue
    - [nvue](https://uniapp.dcloud.net.cn/tutorial/nvue-outline.html)
- `uvue`为uni-app-x的渲染引擎，结合uts可实现原生App的编译，类似Flutter，参考：https://doc.dcloud.net.cn/uni-app-x/

### APP

- 官网原生开发支持文档：https://nativesupport.dcloud.net.cn/
    - uni小程序 SDK：支持在原生App上扩展宿主App的小程序能力，或者用小程序替换原生App的部分功能模块
    - App离线sdk：使用场景是你没有原生App，用DCloud的工具来开发App，又不想使用云打包，则可以使用App离线sdk打包发布为原生App，App离线sdk支持5+ App、uni-app
    - 原生插件开发
- 打包App的方式
    - 将uni-app(一般只没使用5+的特性，当然如果最终打包成APP也可使用5+特性)或5+项目通过HBuilderX云端打包
    - 将uni-app或5+项目或者离线打包，此时将uni-app项目打包出H5资源再嵌入到安卓项目的资源中去进行AS本地打包
- [HTML5+或plus](https://uniapp.dcloud.net.cn/tutorial/use-html5plus.html)、[HTML5+](https://www.html5plus.org/doc/h5p.html)
    - plus不能在浏览器环境下使用，它必须在手机APP上才能使用，因为以安卓为例，他是操纵webview的API
    - WebView是android中一个非常重要的控件，它的作用是用来展示一个web页面，4.4版本之后，直接使用chrome作为内置网页浏览器
    - HTML5+是中国HTML5产业联盟的扩展规范，基于HTML5扩展了大量调用设备的能力，使得web语言可以像原生语言一样强大
- 调试模拟器网页
    - `chrome://inspect/devices`可进入设备调试页面，找到对应页面点击inspect进行调试
- App文件结构
    - `/内部存储/Android/data/uni.UNI55836E9`
        - `/apps/__UNI__55836E9`
            - `/doc`
                - `/uniapp_temp` 每次启动应用会清空
                - `/uniapp_temp_1701010313392` 每次启动应用会清空
                    - `/camera` 拍照临时目录
        - `/files`

#### App离线sdk模式

- 官网文档：https://nativesupport.dcloud.net.cn/AppDocs/
    - 支持uni-app、5+ App等项目发行为原生App
    - 提供扩展原生能力
        - uni-app项目扩展原生能力需开发uni原生插件，支持云端打包，有完善的开发者生态插件市场
        - 5+ App项目扩展原生能力需开发5+原生插件，仅支持本地离线打包
        - 5+ 原生插件已不再继续维护，建议开发者升级应用为uni-app项目并使用uni原生插件
    - 官网SDK中的Demo包含了一个集成了uni-app的原生项目(将uni-app打包成h5的模式放到原生项目资源中进行互相调用)
- 可执行自定义的applicaiton与activity
    - 参考：https://blog.csdn.net/weixin_41996632/article/details/106215566

### 组件

#### scroll-view组件

- https://uniapp.dcloud.net.cn/component/scroll-view.html
- 实现横向滚动条(横向导航)点击后元素居中：https://blog.csdn.net/wangongchao/article/details/123353627
- 使用scroll-view可解决滑动页面底部出现默认的背景颜色
- 使用scroll-view，则uniapp自带的onReachBottom上拉加载方法不会进入，只能通过监听scroll-view的@scrolltolower事件来加载下一页

### 样式

- 引入iconfont
    - 参考 https://www.jianshu.com/p/7969e4fb2d4e
    - Symbol模式需要引入js才能显示彩色，建议下载成png图片

## 常见业务

### web-view开发

- 参考[weixin.md#web-view开发](/_posts/mobile/weixin.md#web-view开发)

### 位置

- 使用uni.chooseLocation()打开地图选择位置(无需操作dom)
    - 参考：https://blog.csdn.net/Handsome_gir/article/details/129159563
    - 需手动修改manifest.json源码，设置requiredPrivateInfos字段；并删除之前的编译文件重新编译

### 多媒体处理

- base64和图片互转: https://blog.csdn.net/qq_43299315/article/details/106657815
- 图片路径转base64: https://blog.csdn.net/qq_39410252/article/details/130249332
- 图片上传`uni.uploadFile`
    - uni.uploadFile提交到后台需要使用路径模式(微信小程序为http://tmp/..., App如_doc/...)
    - 不能使用base64或App本地路径file:///storage/emulated/0/...
- 拍照与照片选择
    - APP照片选择返回路径如：file:///storage/emulated/0/Android/data/io.dcloud.HBuilder/apps/HBuilder/doc/uniapp_temp/compressed/1701010324957_1701007865482.png
    - APP拍照返回路径如：_doc/uniapp_temp_1701010313392/camera/1701010368878.jpg
    - 如果将以上路径传到hybrid(APP嵌入的手机本地H5项目)中，则拍照的这种路径无法读取到图片，可使用plus接口获取绝对路径`url = plus.io.convertLocalFileSystemURL('_doc/') + url.substring(4)`
- 图片涂鸦
    - 参考thd-photo-edit：基于H5实现图片编辑，并web-view嵌入到app中
        - APP拍照需进行路径转换，参考上文
        - 如果嵌入到微信小程序中，问题时小程序拍照后图片路径为本地临时路径，不能传递到H5实现编辑
        - 可考虑先将图片传到服务器，或者使用微信JS-SDK实现H5拍照并编辑：https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html#17
- 录像
    - 视频认证(未测试)：https://blog.csdn.net/weixin_43123014/article/details/119136876
    - 基于H5(未测试)：https://blog.csdn.net/just_you_java/article/details/122533089
- 自定义相机
    - 小程序比较好实现，插件较多，App比较难实现(原生或livepush)
    - App基于livepush，插件如(可行)：https://ext.dcloud.net.cn/plugin?id=4892
- 分享文件到微信(uniapp自带的分享只能分享文字、图片、视频等，不支持文件)
    - 参考原生插件：https://ext.dcloud.net.cn/plugin?id=2307
    - 下载原生插件 - 放到项目的`nativeplugins`目录 - 本地调试需要先用HbuilderX生成一个自定义基座(包含了该原生插件)，也可直接使用云打包出APK
    - 原生插件使用参考：https://nativesupport.dcloud.net.cn/NativePlugin/

#### 语音处理

**语音录制**

- 案例参考: `aezo-chat-gpt(sqt-qingxingyigou)/index.vue`
- 可结合后端调用如[ai-soft.md#阿里-语音识别](/_posts/arch/ai-soft.md#语音识别)

```js
async sendAudioMsg() {
    let flag = await this.checkRecordAuth()
    if (!flag) return
    this.recorderManager = wx.getRecorderManager()
    this.recorderManager.start({
        duration: 60000,
        sampleRate: 16000,
        numberOfChannels: 1,
        format: 'wav'
    })
    this.recorderManager.onStop((res) => {
        // 超时或手动停止都会进入此方法
        console.log('recorder stop', res)
        // 上传 tempFilePath 文件到后台. 后端接收文件即可
        const { tempFilePath } = res
    })
},
checkRecordAuth() {
    let that = this
    return new Promise((resolve, reject) => {
        uni.getSetting({
            success(res) {
                if (!res.authSetting['scope.record']) {
                uni.authorize({
                    scope: 'scope.record',
                    success() {
                        that.$squni.toast('授权成功，请重新录音', 'success')
                        resolve(false)
                    },
                    fail(err) {
                        // authorize:fail auth deny
                        // 用户拒绝授权后，一段时间是不会跳授权弹框的
                        console.log(err)
                        uni.openSetting({
                            success(res2) {
                                console.log(res2)
                                resolve(false)
                            },
                            fail(err2) {
                                // openSetting:fail can only be invoked by user TAP gesture.
                                console.log(err2)
                                that.$squni.toast('请在小程序右上角胶囊(···)的设置中开启麦克风权限')
                            }
                        })
                    }
                })
                } else if (res.authSetting['scope.record'] == true) {
                    resolve(true)
                }
            }
        })
    })
},
```

**语音(合成)播放**

- 案例参考: `aezo-chat-gpt(sqt-qingxingyigou)/index.vue`
- 由于小程序无法实现流式播放，可将后端多个ByteBuffer合成为几个大的ByteBuffer传到小程序端，从而小程序端进行多个ByteBuffer依次播放来实现

```js
// 语音处理上下文(如果需要播放多个语音，可一个语音一个上下文)
const webAudioContext = wx.createWebAudioContext()
webAudioContext.suspend() // 暂停上下文(暂停播放)
webAudioContext.resume().then(() => {}) // 开始播放
// (页面关闭前)关闭上下文
webAudioContext.close()

// 此处 msg 即为后端返回的ByteBuffer(多个小的合并后的)
const audioBufferArr = []
webAudioContext.decodeAudioData(msg, buffer => {
    audioBufferArr.push(buffer)
}, err => {
    console.error('decodeAudioData fail', err)
})

// 创建 AudioBufferSourceNode 节点, 可连接到播放节点(播放器)
const audioBufferSource = webAudioContext.createBufferSource()
audioBufferSource.buffer = audioBufferArr[0]
audioBufferSource.onended = (res) => {
    // 当前 audioBufferSource 播放结束后执行
    // 但是暂停重新播放后，特别是多个音频切换播放的时候，小程序真机onended函数会自动被置空(小程序开发工具正常)
    // 解决方案: 记录audioBufferSource播放的位置，下次重新创建audioBufferSource，并结合start offset还原到原播放位置 (由于需要手动计时, 可能会有一点误差)
    // 并且在 webAudioContext.suspend() 的时候需要将原 audioBufferSource 清除(disconnect、stop、buffer = null、onended = null), 否则 webAudioContext.resume 的时候可能会出现语音重叠播放的情况
}
audioBufferSource.connect(webAudioContext.destination)
audioBufferSource.start() // 支持设置播放位置offset(如小音频文件3s, 可设置从1s处开始播放)
```

### 多环境编译问题

- 使用XBuilder开发(一些依赖安装在HBuilder中)
    - 点击运行获取到的`process.env.NODE_ENV = 'development'`，点击发行获取到的是production
        - HBuilder中点击运行或发行便会把此环境对应的API地址编译成微信小程序代码，之后小程序上传的便是此时编译的地址(微信小程序中无法获取process.env.NODE_ENV)。因此发布线上小程序需要点击XBuilder发行
    - 增加编译时的环境变量或使用cross-env定义script，参考上文[文件-package.json](#文件)
- 使用vscode等开发(vue-cli创建项目，依赖全部安装在项目中)
    - 使用cross-env定义script

### 微信小程序联系客服

- 使用button属性: https://uniapp.dcloud.net.cn/component/button.html#button
- `<button open-type="contact">联系客服</button>`
    - 必须使用button组件，样式比较丑，可参考

    ```html
    <button class="cu-btn cuIcon sm" open-type="contact">
        <view class="cuIcon-service text-green button-icon"></view>
        <text>联系客服</text>
    </button>

    <style>
    .cu-btn {
        display: inline-block;
        background: transparent;
        height: 164upx;
        margin-top: 0;
        border-radius: 0;
        .button-icon {
            margin-top: 42upx;
        }
    }

    button.feedback {
        height: 100rpx;
        font-size: 26rpx;
        width: 50%;
        line-height: 100rpx;
        /* 除去边框 */
        &::after {
            border: none;
        }
    }
    </style>
    ```
- 然后在公众平台->功能->客服绑定对应客户人员微信

### 引入微信小程序插件

- 参考：https://uniapp.dcloud.net.cn/tutorial/mp-weixin-plugin.html
- 案例: 添加快递100小程序进行物流详情查看(插件免费接入，只能显示最新物流信息，详细信息会跳转到快递100小程序)，[参考文档](https://fuwu.weixin.qq.com/service/detail/00008caeab84c07c17dcdabf55b815)
    - 需要先在小程序后台添加插件: 第三方设置 - 插件管理 - 添加插件，搜索插件`wx6885acbedba59c14`添加即可（开发者也可操作添加）
    - `manifest.json` 增加声明，可能需要重启小程序才能生效
    
    ```json
    "mp-weixin": {
        "plugins": {
            "kd100Plugin": {
                "version": "1.0.0",
                "provider": "wx6885acbedba59c14"
            }
        }
    }
    ```
    - 调用实例

    ```js
    uni.navigateTo({
      url: "plugin://kd100Plugin/index?num=SF12345678&appName=测试小程序",
    })

    <!-- 组件调用 -->
    <navigator url="plugin://kd100Plugin/index?num=xxx&appName=xxx"></navigator>
    ```
- 案例: [在小程序中加入企业微信群聊](/_posts/mobile/weixin.md#客户联系)

### 其他

- uni.setStorageSync 和 uni.getStorageSync 可直接操作对象(无需序列化成字符串)，但是修改后的对象需要重新持久化才能保存
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
- H5多项目编译(路径前缀)：定义manifest.json中的`publicPath`和`router.base`，参考[manifest.json](#项目文件)
- `web-view`使用参考[weixin.md#web-view开发](/_posts/mobile/weixin.md#web-view开发)
- `rich-text`可以通过vue的v-html进行渲染，但是传入的字符串不能包含body、html等节点(如果使用了不受信任的HTML节点，该节点及其所有子节点将会被移除)
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
- App本地日志记录
    - 基于Java自定义类 https://blog.csdn.net/nicepainkiller/article/details/106315343
    - 基于插件 https://blog.csdn.net/Linxi_001/article/details/130265639

## 常见问题

### 兼容性问题

#### Vue相关语法问题

- [使用Vue.js注意事项](https://uniapp.dcloud.io/use)
    - Vue特性支持表
- **小程序模板中不能直接使用$store和$config等自定义全局属性**
    - $store需要通过computed属性映射一次，如果数据比较多可以使用mapState和mapGetters。参考: https://uniapp.dcloud.net.cn/tutorial/vue-vuex.html
    - $config可重新定义到data，从而模板中可进行使用(可放到mixin中)

    ```js
    import { mapGetters } from 'vuex'

    data() {
        return {
            $config: this.$config,
        }
    },
    computed: {
        ...mapState({
            text: state => state.moduleA.text,
            timestamp: state => state.moduleB.timestamp
        }),
        // 使用 this.timeString
        ...mapGetters([
            'timeString'
        ]),
        // 数组不支持重命名，只能使用map模式重命名. 使用this.len
        mapGetters({
            len: 'childListLen'
       }),
    }
    ```
- 监控路由属性及参数获取
    - uni-app不能watch $route属性，只能通过onShow函数来控制每次显示页面时的动作
    - this.$route.query只能在H5模式下获取到参数，微信小程序无法获取(从onLoad(options)中获取)。**兼容性获取方法参考squni.js**

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
- uniapp编译的微信支持$slots.default的匿名插槽；编译的支付宝不支持，必须定义插槽名称

#### 机型兼容问题

- IOS 和 Android 对时间的解析有区别 [^1]
    - `new Date('2018-03-30 12:00:00')` IOS 中对于中划线无法解析，Android 可正常解析
        - 解决方案：`Date.parse(new Date('2018/03/30 12:00:00')) || Date.parse(new Date('2018-03-30 12:00:00'))`
    - uniapp日期选择器在手机上不能选择日期问题（需要设置 start 和 end的属性值）
        - 参考：https://blog.csdn.net/spring_007_999/article/details/131814741
- IOS 和 Android 对PDF文件预览的区别
    - IOS可直接通过webview渲染；而Android此方式一直加载页面空白，可downloadfile+opendocument方式解决
        - **注意`uni.openDocument`需要增加`fileType: 'pdf'`参数**
    - 参考：https://developers.weixin.qq.com/community/develop/doc/0000eac06448c8fccc693fa8c51000
    - https://blog.csdn.net/weixin_49521721/article/details/114064682
- `uni.setStorageSync` 部分(安卓)机型不能同步生效
    - 当设置后返回到上一个页面onShow中读取此数据拿到的仍然是之前的数据，可设置timeout延迟跳转页面
    - 参考：https://ask.dcloud.net.cn/question/88497
    - 也可试下同步存储异步获取
- 华为输入法输入英文时可能带下划线，导致输入abc结果传到后台只有a
- **input等表单元素的v-model/@input(e.target.value和e.detail.value)都取不到值的问题**
    - 小程序中有时候会出现不开调试模式，或者调试模式开启失败(只有性能按钮，没有vConsole按钮)
    - 有时候开启成功也会遇到，生产环境暂未遇到

#### 支付宝和微信小程序兼容问题

- VUE语法
    - uniapp编译的微信支持$slots.default的匿名插槽；编译的支付宝不支持，必须定义插槽名称
- 样式问题
    - css单位使用`rpx/upx` (rem不兼容)
    - 支付宝在 input 组件设置 disabled:true 后组件会被禁用组件颜色会变灰。解决：可使用view代替
    - 支付宝使用伪元素好像有问题(如colorui的picker样式，但是colorui的图片伪元素正常)。解决：通过其他css样式解决
    - 支付宝不支持css的attr方法(如colorui的cu-steps类)
- colorui插件样式问题
    - 支付宝中picker缺少右侧箭头样式。解决如下

    ```html
    <view class="cu-form-group">
        <view class="title">主体名称</view>
        <!-- 在外层套一个flex -->
        <view class="flex justify-end">
            <picker @change="companyChange" :value="companyIndex" :range="companyList" :range-key="'name'">
                <view class="picker">
                    {{companyIndex > -1 ? companyList[companyIndex].name : '请选择主体名称'}}
                </view>
            </picker>
            <!-- #ifdef MP-ALIPAY -->
            <view class="cuIcon-right"></view>
            <!-- #endif -->
        </view>
    </view>
    ```
    - cu-steps类无效。解决如下

    ```html
    <view class="cu-steps">
        <view class="cu-item" v-for="(item,index) in stepList" :key="index">
            <text class="num" :class="['num-' + (index + 1)]" :data-index="index + 1"></text> {{item.name}}
        </view>
    </view>

    <style>
    /* 增加样式如 */
    .cu-steps .cu-item .num.num-1::before,
    .cu-steps .cu-item .num.num-1::after {
        content: "1";
    }
    </style>
    ```
    

#### 样式常见问题

- 图片显示
    - 参考：https://uniapp.dcloud.net.cn/tutorial/syntax-css.html#%E8%83%8C%E6%99%AF%E5%9B%BE%E7%89%87
    - 如果图片不定义高度，当网络慢的时候加载完后会闪跳

```html
<!-- 支持小尺寸图片 -->
<image class="cu-avatar round" src="/static/logo.png">

<!-- 此方式仅开发环境有效，如果写成js导入的方式小程序真机是可以的 -->
<view class="cu-avatar round" style="background-image:url('/static/logo.png');"></view>
```
- css变量单位
    - css绑定变量：https://blog.csdn.net/zz00008888/article/details/126222530
    - css单位问题：https://www.jianshu.com/p/ff88a9d2a1aa
- 单位换算说明
    - https://uniapp.dcloud.net.cn/tutorial/syntax-css.html#%E5%B0%BA%E5%AF%B8%E5%8D%95%E4%BD%8D
    - `em` 表示相对尺寸，**其相对于当前对象内 (父级元素) 文本的字体尺寸** font-size（如当前对行内文本的字体尺寸未被设置，则相对于浏览器的默认字体尺寸。 任意浏览器的默认字体高都是16px。所有未经调整的浏览器都符合：1em = 16px），如果设置默认尺寸为12px，则1em = 12px
    - `rem` 为css3新增的一个相对单位，使用rem为元素设定字体大小时，仍然是相对大小，但是rem只**相对于HTML根元素的font-size**，因此只需要确定这一个font-size
    - 说明
        - rem: 微信小程序和支付宝小程序不兼容
        - 设计稿使用设备宽度750px比较容易计算750px的话1rpx=1px, 这样的话,设计图上量出来的尺寸是多少px就是多少rpx, 至于在不同的设备上实际上要换算成多少个rem就交给小程序自己换算
        - 为了简化font-size的换算，我们通常将rem与em的换算基准设置为 font-size : 62.5%; ，则此时1rem=1em = 16px * 62.5% = 10px， 这样10px = 1em=1rem，方便于我们使用

```js
ios: pt
android: dp
web: px、rem、em
H5: rpx (建议)
uniapp: upx (动态绑定的 style 不支持直接使用 upx)

单位换算（正常情况下）
1pt = 1dp = 2px
2rpx = 2upx = 1px
1rem = (750/20)rpx = 37.5rpx = 37.5upx 可适当微调
```
- 单位换算案例

```html
<!-- 此处padding为30rpx，在小程序开发工具里面会变成15px(单数从而导致两张图片中间有间隙)，此处改成28rpx就可以了 -->
<view style="padding: 0rpx 30rpx 30rpx 30rpx; width: 100%;">
    <image style="width: 100%;display: block;" mode="widthFix" src="https://ossweb-img.qq.com/images/lol/web201310/skin/big10006.jpg"></image>
    <image style="width: 100%;display: block;" mode="widthFix" src="https://ossweb-img.qq.com/images/lol/web201310/skin/big10006.jpg"></image>
</view>
```
- uni.showToast 被遮盖：全局增加样式`uni-toast {z-index: 999999;}`
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
- 电脑版文字点击问题

```html
<!-- 最外层的view如果改成text则会导致电脑端小程序无法触发点击事件(手机版是可以的) -->
<view class="inline">
    我已阅读并同意
    <text class="text-main" style="cursor: pointer;" @tap="navToDetail('用户协议')">用户协议</text>
    <text class="text-main" style="cursor: pointer;" @tap="navToDetail('隐私政策')">《隐私政策》</text>
</view>
```

### 微信小程序包反编译

```bash
## 参考：https://blog.csdn.net/huagangwang/article/details/135013405
# 先使用windows微信打开小程序，然后通过小程序ID进行解码。提示解密成功，得到 dec.wxapkg
pc_wxapkg_decrypt.exe -wxid wxa04daf3912b3d61e -in "C:\Users\test\Documents\WeChat Files\Applet\wxa04daf3912b3d61e\1\__APP__.wxapkg"
# 反编译
node wuWxapkg.js ../decrypt/dec.wxapkg
```

### 其他

- 小程序图片不显示问题，参考[weixin.md](/_posts/mobile/weixin.md#其他)
- 访问出现Invalid Host header问题(使用反向代理时出现，如使用花生壳)
    - 修改uni-app的manifest.json文件 - 源码视图，增加`"devServer": {"disableHostCheck" : true}`
- 真机调试
    - IOS需要开放微信访问本地网络

## UI框架

### ColorUI插件

- [github仓库](https://github.com/weilanwl/coloruicss)
- [V2使用文档](https://miren.lovemi.ren/colorui-document/pages/base/)、[V2 H5演示版](https://miren.lovemi.ren/colorui-h5/h5/#/)
- 主要是一个样式文件，通过一些CSS类来实现UI效果
- 按钮

```html
<button class="cu-btn round shadow block cuIcon sm line-red lines-red bg-red bg-gradual-red" loading>
    图标: <text class="cuIcon-upload"></text>
    加载: <text class="cuIcon-loading2 cuIconfont-spin"></text>
    默认: cu-btn
    圆角: round
    阴影: shadow
    无效状态: block
    图标按钮: cuIcon(配合图标)
    尺寸: sm/默认/lg
    镂空边框: line-red | lines-red(线条更粗)
    背景: bg-red | bg-gradual-red(渐变色)
    原生加载: loading | 图标(如果要防止重复点击需要结合disabled属性). 或者使用uni.showLoading函数
</button>
```
- 常用布局
    - flex 水平浮动排列
    - flex flex-direction 垂直浮动排列
    - justify- 左右两边浮动
    - align- 中线对齐

```html
<!-- 水平居中 -->
<span class="flex justify-center">
    <div>
        <span>文字1</span><span>文字2</span>
    </div>
</span>

<!-- 左右两边浮动，并中线对齐 -->
<span class="flex justify-between align-center">
    <div>显示在左边</div>   <span>显示在右边</span>
</span>

<!-- 垂直对齐 -->
<span class="flex flex-direction align-center">
    <div>显示在上面</div>
    <span>显示在下面</span>
</span>
```

### uView插件

 - [uView](https://www.uviewui.com/)
- u-cell-item使用slot时标题无法增加空格(使用padding解决)

```html
<u-cell-group>
    <u-cell-item>
        <span slot="title" class="u-p-l-10">退出</span>
        <uni-icons slot="icon" type="close" size="17" style="color: #606266;"></uni-icons>
    </u-cell-item>
</u-cell-group>
```

## 插件

### 自定义插件

- [记一次uniapp插件：zero-markdown-view优化过程](https://juejin.cn/post/7160995270476431373)

### 富文本/markdown解析

- [uParse](https://ext.dcloud.net.cn/plugin?id=183) DCloud前端团队
    - 渲染markdown需额外安装`marked`
- [zero-markdown-view](https://ext.dcloud.net.cn/plugin?id=9437)
    - 基于mp-html，手动编译可减小包体积到1.6M
    - [记一次uniapp插件：zero-markdown-view优化过程](https://juejin.cn/post/7160995270476431373)

## 源码解析

### Vue3-H5案例解析

- 先基于cli创建项目

#### 如何解析pages.json文件

- 根据此流程找到相关原理
    - 如何解析pages.json文件
    - 如何解析manifest.json文件
    - 为啥uniapp cli模板项目中main.ts没有出现`app.mount('#app');`也可以正常挂载
- `npm run dev:h5` 本质执行的是`uni`命令(可改成`uni --debug`查看debug日志)
    - uni为基于vite封装的命令行打包插件，源码位置：https://github.com/dcloudio/uni-app/tree/next/packages/vite-plugin-uni
    - 从`vite.config.ts`可看出只有一个插件`uni()`
- `vite-plugin-uni/src/index.ts`

```ts
export default function uniPlugin(
  rawOptions: VitePluginUniOptions = {}
): Plugin[] {
  // 初始化环境变量，如：process.env.UNI_INPUT_DIR
  initEnv('unknown', { platform: process.env.UNI_PLATFORM || 'h5' })

  const options: VitePluginUniResolvedOptions = {
    ...rawOptions,
    base: '/',
    assetsDir: 'assets',
    inputDir: '',
    outputDir: '',
    command: 'serve',
    platform: 'h5',
  }
  // ...

  // 在vscode中启动h5，因此走 createPlugins(options)
  return process.env.UNI_APP_X === 'true' && process.env.UNI_PLATFORM === 'app'
  ? createUVuePlugins(options)
  : createPlugins(options)
}

function createPlugins(options: VitePluginUniResolvedOptions) {
  const plugins: Plugin[] = []

  // 增加处理 uni-module 目录插件
  const injects = parseUniExtApis(
    true,
    process.env.UNI_UTS_PLATFORM,
    'javascript'
  )
  if (Object.keys(injects).length) {
    plugins.push(
      uniViteInjectPlugin('uni:ext-api-inject', injects as InjectOptions)
    )
  }

  // 检索uni相关扩展插件，参考: vite-plugin-uni/src/util/plugin.ts#initExtraPlugins
  const uniPlugins = initExtraPlugins(
    process.env.UNI_CLI_CONTEXT || process.cwd(),
    (process.env.UNI_PLATFORM as UniApp.PLATFORM) || 'h5',
    options
  )
  // 打印debug日志. debugUni日志以 uni:plugin 开头
  debugUni(uniPlugins)

  // 继续包装插件，处理vueJsxPlugin等
  // ...
  return plugins
}
```
- `vite-plugin-uni/src/util/plugin.ts`

```ts
export function initExtraPlugins(
  cliRoot: string,
  platform: UniApp.PLATFORM,
  options: VitePluginUniResolvedOptions
) {
  // initPlugins 根据检索到的每个插件信息一次调用 initPlugin 方法
  return initPlugins(
    cliRoot,
    // 根据项目package.json的dependencies和devDependencies找到相关依赖列表
    // 检索每个依赖的自身的package.json配置，读取package.json中的uni-app节点信息
    // 如: 主项目依赖 @dcloudio/uni-h5，而 node_modules/@dcloudio/uni-h5/package.json中存在uni-app节点信息
    /*
    "uni-app": {
        "name": "uni-h5",
        "apply": [
            "h5"
        ],
        "main": "dist/uni.compiler.js"
    }
    */
    resolvePlugins(cliRoot, platform, options.uvue),
    options
  )
}

function initPlugin(
  cliRoot: string,
  { id, config: { main } }: PluginConfig,
  options: VitePluginUniResolvedOptions
): Plugin | void {
  // 导入插件，如对应文件为 node_modules/@dcloudio/uni-h5/dist/uni.compiler.js
  // 而此文件引入 @dcloudio/uni-h5-vite 模块
  let plugin = require(require.resolve(
    path.join(id, main || '/lib/uni.plugin.js'),
    { paths: [cliRoot] }
  ))
  plugin = plugin.default || plugin
  if (isFunction(plugin)) {
    plugin = plugin(options)
  }
  return plugin
}
```
- `uni-h5-vite/src/index.ts`，源码位置: https://github.com/dcloudio/uni-app/tree/next/packages/uni-h5-vite

```ts
// ...
import { uniMainJsPlugin } from './plugins/mainJs'
import { uniManifestJsonPlugin } from './plugins/manifestJson'
import { uniPagesJsonPlugin } from './plugins/pagesJson'
// ...

export default [
  // ...
  uniMainJsPlugin(),
  uniManifestJsonPlugin(),
  uniPagesJsonPlugin(),
  // ...
]
```
- `uni-h5-vite/src/plugins/mainJs.ts`

```ts
import {
  defineUniMainJsPlugin,
  isSsr,
  PAGES_JSON_JS, // 定义了pages.json的处理器文件 pages-json-js
} from '@dcloudio/uni-cli-shared' // 另外一个包，一些通用方法
import { isSSR, isSsrManifest } from '../utils'

export function uniMainJsPlugin() {
  // 返回插件定义
  return defineUniMainJsPlugin((opts) => {
    let runSSR = false
    return {
      name: 'uni:h5-main-js', // 插件名称
      enforce: 'pre',
      configResolved(config) {
        runSSR =
          isSsr(config.command, config) || isSsrManifest(config.command, config)
      },
      transform(code, id, options) {
        // 如解析到 <script type="module" src="./main.ts"></script> 此时id就是 index.html所在目录+main.ts
        // 而opts中判断的是 id == 项目目录/src/main.js | main.ts | main.uts
        if (opts.filter(id)) {
          if (!runSSR) {
            code = code.includes('createSSRApp')
              // 如默认模板的main.ts中包含`import { createSSRApp } from "vue";`，因此走的此此方法
              ? createApp(code)
              // 如果自定义成 `import { createApp } from "vue";` 则走此方法
              : createLegacyApp(code)
          } else {
            code = isSSR(options)
              ? createSSRServerApp(code)
              : createSSRClientApp(code)
          }
          // 导入pages.json文件的执行语句
          code = `import './${PAGES_JSON_JS}';${code}`
          return {
            code,
            map: this.getCombinedSourcemap(),
          }
        }
      },
    }
  })
}

function createApp(code: string) {
  // uniapp cli模板项目中main.ts中就是通过createSSRApp进行创建示例的
  // 此处可以看出来本质还是调用的 createVueApp
  // 并通过 createApp 来进行挂载实例
  return `import { plugin as __plugin } from '@dcloudio/uni-h5';${code.replace(
    'createSSRApp',
    'createVueApp as createSSRApp'
  )};createApp().app.use(__plugin).mount("#app");`
}
```

- `uni-h5-vite/src/plugins/pagesJson.ts`

```ts
import {
  API_DEPS_CSS,
  FEATURE_DEFINES,
  H5_FRAMEWORK_STYLE_PATH,
  BASE_COMPONENTS_STYLE_PATH,
  normalizeIdentifier,
  normalizePagesJson,
  defineUniPagesJsonPlugin, // 里面根据 jsonPath = normalizePath(path.join(process.env.UNI_INPUT_DIR, 'pages.json')) 获取文件
  normalizePagesRoute,
  normalizePagePath,
  isEnableTreeShaking,
  parseManifestJsonOnce,
  MANIFEST_JSON_JS,
} from '@dcloudio/uni-cli-shared'

export function uniPagesJsonPlugin(): Plugin {
  return defineUniPagesJsonPlugin((opts) => {
    return {
      name: 'uni:h5-pages-json',
      enforce: 'pre',
      transform(code, id, opt) {
        if (opts.filter(id)) {
          const { resolvedConfig } = opts
          const ssr = isSSR(opt)
          return {
            code:
              registerGlobalCode(resolvedConfig, ssr) +
              // 根据pages.json生成代码，此处code即为对应文件json字符串
              generatePagesJsonCode(ssr, code, resolvedConfig),
            map: { mappings: '' },
          }
        }
      },
    }
  })
}

// 根据pages.json拼接代码
function generatePagesJsonCode(
  ssr: boolean | undefined,
  jsonStr: string,
  config: ResolvedConfig
) {
  const globalName = getGlobal(ssr)
  const pagesJson = normalizePagesJson(jsonStr, process.env.UNI_PLATFORM)
  const { importLayoutComponentsCode, defineLayoutComponentsCode } =
    generateLayoutComponentsCode(globalName, pagesJson)
  const definePagesCode = generatePagesDefineCode(pagesJson, config)
  const uniRoutesCode = generateRoutes(globalName, pagesJson, config)
  const uniConfigCode = generateConfig(globalName, pagesJson, config)
  const cssCode = generateCssCode(config)

  return `
import { defineAsyncComponent, resolveComponent, createVNode, withCtx, openBlock, createBlock } from 'vue'
import { PageComponent, useI18n, setupWindow, setupPage } from '@dcloudio/uni-h5'
import { appId, appName, appVersion, appVersionCode, debug, networkTimeout, router, async, sdkConfigs, qqMapKey, googleMapKey, aMapKey, aMapSecurityJsCode, aMapServiceHost, nvue, locale, fallbackLocale, darkmode, themeConfig } from './${MANIFEST_JSON_JS}'
const locales = import.meta.globEager('./locale/*.json')
${importLayoutComponentsCode}
const extend = Object.assign
${cssCode}
${uniConfigCode}
${defineLayoutComponentsCode}
${definePagesCode}
${uniRoutesCode}
${config.command === 'serve' ? hmrCode : ''}
export {}
`
}

// 设置window.__uniConfig
function generateConfig(globalName, pagesJson, config) {
    delete pagesJson.pages;
    delete pagesJson.subPackages;
    delete pagesJson.subpackages;
    pagesJson.compilerVersion = process.env.UNI_COMPILER_VERSION;
    return `${globalName}.__uniConfig=extend(${JSON.stringify(pagesJson)},{
  appId,
  appName,
  appVersion,
  appVersionCode,
  async,
  debug,
  networkTimeout,
  sdkConfigs,
  qqMapKey,
  googleMapKey,
  aMapKey,
  aMapSecurityJsCode,
  aMapServiceHost,
  nvue,
  locale,
  fallbackLocale,
  locales:Object.keys(locales).reduce((res,name)=>{const locale=name.replace(/\\.\\/locale\\/(uni-app.)?(.*).json/,'$2');extend(res[locale]||(res[locale]={}),locales[name].default);return res},{}),
  router,
  darkmode,
  themeConfig,
})
`;
}
```



---

参考文章

[^1]: https://www.jianshu.com/p/a6b3221807f0
