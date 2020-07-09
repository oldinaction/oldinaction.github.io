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
- `package.json` 使用HBuilder编辑创建的项目默认无此文件，可手动创建或npm init创建
    - uni-app在文件中增加uni-app扩展节点，可实现自定义条件编译平台
    - 增加编译时的环境变量，可在package.json文件中增加以下节点，然后再发行-自定义发行菜单中可看到此标题

        ```json
        "uni-app": {  
            "scripts": { 
                // 自定义脚本(启动方式)，对于内置启动方式可修改 manifest.json
                "build-h5-api1": {   
                    "title":"生产环境API地址一(H5)",   
                    "env": {
                        "UNI_PLATFORM": "h5",
                        "NODE_ENV": "production",
                        "APP_ENV": "api1" // 自定义环境变量，可和process.env.NODE_ENV配合使用
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

## 小技巧

- 可使用HBuilder创建项目或vue-cli创建项目，参考：https://uniapp.dcloud.net.cn/quickstart
    - 发布app必须通过HBuilder，vue-cli可以发布h5/小程序。基于vue-cli创建项目时默认安装了cross-env插件，基于此插件在启动命令前增加了NODE_ENV等参数的配置
    - HBuilder创建的项目默认无package.json，可手动创建或npm init创建，之后可通过npm安装插件
    - HBuilder创建的项目代码对应vue-cli创建项目的src代码
    - vue-cli创建的项目还需手动安装sass-loader(`cnpm install sass-loader node-sass -D`)
- uni.navigateTo 不关闭之前页面，uni.redirectTo 关闭之前页面
- onLoad触发一次，onShow每次触发
- 路由挂载：需要跳转的页面必须在page.json中注册过。如需采用 Vue Router 方式管理路由，可在uni-app插件市场找Vue-Router相关插件
- uni.setStorageSync 和 uni.getStorageSync 可直接操作对象(无需虚拟化成字符串)
- uni.showToastr 无Error图片(微信也没有)
- 需使用web-view组件代替iframe，嵌套页才会在微信小程序中显示
    - 且web-view会撑满全屏，即无视非web-view中的元素
    - uni-app本身可使用iframe，可在h5下显示，但是微信小程序中不会显示
- **多环境编译问题**
    - 点击运行获取到的`process.env.NODE_ENV = 'development'`，点击发行获取到的是production
    - HBuilder中点击运行或发行便会把此环境对应的API地址编译成微信小程序代码，之后小程序上传的便是此时编译的地址(微信小程序中无法获取process.env.NODE_ENV)。因此发布线上小程序需要点击发行
    - 增加编译时的环境变量，参考上文[文件](#文件)
- 判断平台
    - 编译期判断，使用`// #ifdef H5`，`// #endif`
    - 运行期判断，`uni.getSystemInfoSync().platform = android|ios|devtools` 判断客户端环境是 Android、iOS 还是小程序开发工具
- 扫码功能参考[uni.scanCode](https://uniapp.dcloud.net.cn/api/system/barcode?id=scancode)、[springboot-vue.md#扫码](/_posts/arch/springboot-vue.md#扫码)


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








---
