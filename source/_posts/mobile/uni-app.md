---
layout: "post"
title: "uni-app"
date: "2017-10-10 21:34"
categories: [web]
tags: [H5, 小程序, App, mobile]
---

## 简介

- [官网](https://uniapp.dcloud.io/)

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

### 生命周期

- 应用生命周期: https://uniapp.dcloud.io/collocation/frame/lifecycle
    - `onLaunch` 当uni-app 初始化完成时触发（全局只触发一次）
    - `onShow` 当 uni-app 启动，或从后台进入前台显示
- 页面生命周期中: https://uniapp.dcloud.net.cn/tutorial/page.html#lifecycle
    - `onLoad` 触发一次
    - `onShow` 每次展示时触发
    - `onHide` 无法监听到页面返回(H5和微信小程序都不可以)
    - `onBackPress` 可以监听到H5返回，无法监听到微信小程序返回
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

### 路由相关

- 路由相关: https://uniapp.dcloud.net.cn/tutorial/page.html#%E8%B7%AF%E7%94%B1
    - 页面跳转
        - uni.navigateTo 不关闭之前页面(之前页面代码还会继续执行)
        - uni.redirectTo 关闭之前页面
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
- 跳转小程序：https://uniapp.dcloud.net.cn/api/other/open-miniprogram.html#navigatetominiprogram

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

### scroll-view组件

- https://uniapp.dcloud.net.cn/component/scroll-view.html
- 实现横向滚动条(横向导航)点击后元素居中：https://blog.csdn.net/wangongchao/article/details/123353627

### web-view开发

- 参考[weixin.md#web-view开发](/_posts/mobile/weixin.md#web-view开发)

### 样式

- 引入iconfont
    - 参考 https://www.jianshu.com/p/7969e4fb2d4e
    - Symbol模式需要引入js才能显示彩色，建议下载成png图片

## 兼容性问题

### Vue相关语法问题

- [使用Vue.js注意事项](https://uniapp.dcloud.io/use)
    - Vue特性支持表
- **小程序模板中不能直接使用$store和$config等自定义全局属性**
    - $store需要通过computed属性映射一次，如果数据比较多可以使用mapState和mapGetters。参考: https://uniapp.dcloud.net.cn/tutorial/vue-vuex.html
    - $config可重新定义到data/computed/methods中进行获取

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

### 其他兼容问题

- 华为输入法输入英文时可能带下划线，导致输入abc结果传到后台只有a
- IOS 和 Android 对时间的解析有区别 [^1]
    - `new Date('2018-03-30 12:00:00')` IOS 中对于中划线无法解析，Android 可正常解析
    - 解决方案：`Date.parse(new Date('2018/03/30 12:00:00')) || Date.parse(new Date('2018-03-30 12:00:00'))`
- **input等表单元素的v-model/@input(e.target.value和e.detail.value)都取不到值**
    - 小程序中有时候会出现不开调试模式，或者调试模式开启失败(只有性能按钮，没有vConsole按钮)
    - 有时候开启成功也会遇到，生产环境暂未遇到

### 样式问题

- 图片显示
    - 参考：https://uniapp.dcloud.net.cn/tutorial/syntax-css.html#%E8%83%8C%E6%99%AF%E5%9B%BE%E7%89%87

```html
<!-- 支持 -->
<image class="cu-avatar round" src="/static/logo.png">

<!-- 此方式仅开发环境有效，如果写成js导入的方式小程序真机是可以的 -->
<view class="cu-avatar round" style="background-image:url('/static/logo.png');"></view>
```
- css变量单位
    - css绑定变量：https://blog.csdn.net/zz00008888/article/details/126222530
    - css单位问题：https://www.jianshu.com/p/ff88a9d2a1aa

```html
ios：pt
android：dp
web：px、rem、em
微信小程序：rpx
uniapp：upx

单位换算（正常情况下）
1pt = 1dp = 2px
2rpx = 2upx = 1px

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

## 常见业务

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
    </style>
    ```
- 然后在公众平台->功能->客服绑定对应客户人员微信

### 其他

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

## 自定义插件

- [记一次uniapp插件：zero-markdown-view优化过程](https://juejin.cn/post/7160995270476431373)

## ColorUI插件

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
        <span>文字1</span>
        <span>文字2</span>
    </div>
</span>

<!-- 左右两边浮动，并中线对齐 -->
<span class="flex justify-between align-center">
    <div>显示在左边</div>
    <span>显示在右边</span>
</span>

<!-- 垂直对齐 -->
<span class="flex flex-direction align-center">
    <div>显示在上面</div>
    <span>显示在下面</span>
</span>
```

## uView插件

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

## 零散插件

### 富文本/markdown解析

- [uParse](https://ext.dcloud.net.cn/plugin?id=183) DCloud前端团队
    - 渲染markdown需额外安装`marked`
- [zero-markdown-view](https://ext.dcloud.net.cn/plugin?id=9437)
    - 基于mp-html，手动编译可减小包体积到1.6M
    - [记一次uniapp插件：zero-markdown-view优化过程](https://juejin.cn/post/7160995270476431373)

## 常见问题

- 小程序图片不显示问题，参考[weixin.md](/_posts/mobile/weixin.md#其他)
- 访问出现Invalid Host header问题(使用反向代理时出现，如使用花生壳)
    - 修改uni-app的manifest.json文件 - 源码视图，增加`"devServer": {"disableHostCheck" : true}`
- 真机调试
    - IOS需要开放微信访问本地网络




---

参考文章

[^1]: https://www.jianshu.com/p/a6b3221807f0
