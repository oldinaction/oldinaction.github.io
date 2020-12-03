---
layout: "post"
title: "微信开发"
date: "2017-10-10 21:34"
categories: [web]
tags: [H5, App]
---

## 简介

- 此处微信开发包含微信公众号开发，公众号H5开发，微信小程序开发，微信支付等

## 微信小程序限制

### 认证/审核/权限

- 小程序可直接复用同一主体的公众号认证(无需额外费用)
- 管理员可设置运营者/开发者；运营者可直接发布审核后的版本；开发者可添加体验人员(50人)，开发者可设置域名、发布体验版、提交审核版(但发布线上版则需管理审核)
- 审核
    - 发布小程序提交审核，不通过会通知发布人和管理员
    - 线上版本发布每次均需审核，官方称1-7天完成
        - 实际发现不涉及特殊业务时，快的时候1-2小时即可完成
        - 涉及如资质类如餐饮、红包等，一般2-7天
    - 审核人员工作时间
        - 周末也可提交审核
        - 小程序如若需要登录，需要提供正确的账号密码供审核人员使用
    - 加急机制
        - 最快2小时内完成
        - 加急时间段：企业是9:00-24:00，个人是9:00-21:00
        - 非个人主体一年3次机会，个人一年1次机会。如在审核前撤回申请，机会将不会被消耗
        - 选择了加急审核，但审核单被驳回了。开发者可以在12小时内重新整改并在驳回站内信内的【前往反馈页面】重新提交审核，即可获得相应加急的队列。否则将会直接浪费了一次加急机会

### 域名限制

- API地址：**必须是https域名(可以是非443端口)**，且需在微信后台配置(可配置API、ws、文件上传下载、打开网页域名等)
    - 开发环境可在微信编辑器中设置成不校验此限制(可为ip地址)，体验版则需打开调试模式(在胶囊中设置)
- iframe(web-view)地址：必须https域名，且需要在微信后台配置业务域名。开发环境同上
- 图片地址：必须是https域名，且需要在微信后台配置业务域名。开发环境同上

### 其他

- 小程序背景图必须是base64格式或网络图片(http/https，无需绑定域名)，否则不显示(仅开发版显示)
- 开发版真机调试需手机wifi和API地址处于同一网络
- **web-view**组件(类似iframe，小程序本身是不能使用iframe标签的)，如出现"此网页由xxx提供"均为web-view
    - web-view 不支持推送服务通知(即模板消息)
        - 类似下单等页面需要发送通知则需改写成小程序页面
    - 打开的域名没有在小程序管理后台设置业务域名，打开的页面 302 过去的地址也必须设置过业务域名，web-view嵌入的页面可以包含 iframe，但是 iframe 的地址必须为业务域名。且都需要是https
    - 小程序内嵌 web-view 跟微信内置浏览器是一套环境，即Storage等共享
    - 可通过url传递参数进行用户验证
- **小程序不支持多环境编译**，对于API地址完全取决于上传到微信平台时代码中的地址(只能为一个，无法获取环境)。因此通过uni-app开发时，需要点击发行才会对应到生产环境API
- 调试体验版或者正式版：体验版调试直接打开小程序调试模式；正式版调试需要先打开体验版调试模式，再访问正式版

## 微信公众号

- 菜单管理、用户管理、文章管理均通过自定义服务操作，此时需要配置服务器。配置了服务器之后则不能使用微信公众号后台的菜单管理等功能
    - 微信浏览器网页授权(登录)无需绑定此配置(参考下文微信登录)，此配置只是用来管理微信公众号
- 配置服务器地址
    - 配置服务器的URL必须以http://或https://开头，分别支持80端口和443端口
    - EncodingAESKey随机生成一个即可
    - 绑定时会调用后台服务进行验证域名有效性，Java的参考：https://www.cnblogs.com/zhouwen2017/p/10451427.html
    - 验证时提示 **"参数错误，请重新填写"**，可能由于域名被微信屏蔽了。可直接在微信上访问测试，如果屏蔽了会提示"已停止访问该网页"

## 微信H5开发

- 微信网页开发
    - 通过微信浏览器打开网页时的场景。此时可调用JS-SDK获取一些硬件能力
    - 通过使用微信JS-SDK，网页开发者可借助微信高效地使用拍照、选图、语音、位置等手机系统的能力，同时可以直接使用微信分享、扫一扫、卡券、支付等微信特有的能力，为微信用户提供更优质的网页体验
- **JSSDK使用步骤**，[参考](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html)
    - 绑定域名(JS接口安全域名)。**注意是域名**(因此测试也需要使用域名)，不需要http协议头(否则报错：invalid url domain)
    - 引入JS文件(必须)
        - 直接引入`jweixin-1.6.0.js`，则可直接使用wx对象
        - 或者通过`npm install -S weixin-js-sdk`，然后通过`import wx from 'weixin-js-sdk'`导入
    - 通过config接口注入权限验证配置
        - 所有需要使用JS-SDK的页面必须先注入配置信息，否则将无法调用
        - 同一个url仅需调用一次，对于变化url的SPA的web app可在每次url变化时进行调用。即通过Vue Router进行跳转不需要重复注入配置，可在main.js中注入即可
        - 需要配合后台服务进行验签，后台主要需要获取微信公众号access_token和jsapi_ticket，然后将加密串返回到前台进行验证。参考：https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html#62
    - 通过ready接口处理成功验证，通过error接口处理失败验证
    - 通过wx对象调用相关接口
    - **关于测试**
        - 如果确定线上环境上述流程可正常进行，测试时可进行省略。先直接访问`http://demo.open.weixin.qq.com/jssdk`可获取所有接口权限，然后访问测试页面，即可进行接口调用。从而减少了测试时域名绑定等步骤
- **微信开发者工具可模拟微信内置浏览器进行微信H5页面调试**
    - 默认打开是小程序模式，可通过"微信开发者工具-更换模式-公众号网页调试"进行切换
    - 如果在微信内置浏览器打开，则js中可以拿到`wx`对象(只是一个声明)，但是还需引入JS-SDK(实现)。参考上文JSSDK使用步骤
- **微信公众号测试账号申请和使用**
    - 申请：开发者工具 - 公众平台测试帐号
    - 测试帐号接口权限基本都有；一个微信账号对应一个测试号，和登录的公众号无关
    - 设置登录验证时的重定向地址：体验接口权限表 - 网页授权获取用户基本信息 - 修改(只需填域名)
- 参考[微信登录](#微信登录)

### 内网穿透

- http://service.oray.com/question/5570.html

## 微信登录

### 微信浏览器中获取用户信息

- [微信浏览器中获取用户信息](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html)。如微信公众号点击菜单H5连接进入网页时获取用户信息
    - 前提
        - **绑定网页授权域名**(和授权回调地址一致。微信公众号 - 开发 - 接口权限 - 网页服务 - 网页帐号 - 网页授权获取用户基本信息)
            - **无需绑定微信公众号服务器配置**(该配置是用来管理微信公众号的)
            - **一定要是域名，不要加http://等协议头，也不要加子路径**
                - 假设网页运行在/abc目录，此时也要加example.com，而不能是example.com/abc，因此必须是http://example.com/MP_verify_cm2fJ4wmTLQpvkZr.txt来进行验证
                - 业务域名和JS安全域名是否需要加子路径未测试
        - **设置IP白名单**（测试账号无需）
            - 为了防止公众号appid和秘钥泄露，在向微信服务器获取access_token请求时，需要限制开发者服务器所在的外网IP（微信服务器获取的请求者IP）
    - 引导用户访问如`https://open.weixin.qq.com/connect/oauth2/authorize?appid=APPID&redirect_uri=REDIRECT_URI&response_type=code&scope=SCOPE&state=STATE#wechat_redirect`，如让用户打开网站主页，然后再主页加载后自动跳转到此地址。回调地址必须完整，如果动态协议头，可以使用如`window.location.protocol + '//aezo.cn/xxx'`

        ```js
        redirectWechatForCode(appid, redirectUrl, state) {
            // https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html
            let path = "https://open.weixin.qq.com/connect/oauth2/authorize?appid="
                    + appid
                    + "&redirect_uri="
                    + encodeURIComponent(redirectUrl)
                    + "&response_type=code&scope=snsapi_userinfo&state=" + state + "#wechat_redirect";
            window.location.href = path
        }
        ```
    - 访问上述连接，会进行用户授权验证，用户同意授权，获取code。此时code通过上述链接配置的回调地址会当做参数带回(还会原封不动的带回state参数)
    - 后台通过code换取openid、网页授权access_token(用户的access_token，有效期为2h；不同于公众号的access_token)、网页授权refresh_token(有效期为30天)。由于此接口调用次数不限制，可需要获取access_token时重新调用微信接口，也可存储下来
        - **由于后台此时需要调用微信接口，因此需要服务器能访问外网，或开放 api.weixin.qq.com 的白名单(此域名可能对应多个IP，且存在变化的问题)，或使用代理访问(程序中进行代理或nginx代理)**
    - 或者刷新access_token
    - 后台再基于网页授权access_token和openid拉取用户信息










---
