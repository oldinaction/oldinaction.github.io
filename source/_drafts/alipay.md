---
layout: "post"
title: "支付宝开发"
date: "2024-06-03 21:34"
categories: [web]
tags: [H5, 小程序, mobile]
---

## 简介

- 支付宝支付、小程序对应后台SDK均为一个，如`com.alipay.sdk:alipay-sdk-java:4.39.52.ALL`，参考：https://opendocs.alipay.com/open/02np94

## 支付宝支付

### 手机网站支付(H5)

- 前提：开通"手机网站支付"产品

### 小程序支付

- 前提：开通"JSAPI支付"产品，并绑定小程序AppId
- 小程序支付使用[JSAPI](https://opendocs.alipay.com/mini/053llc)支付进行接入
    - 在服务端调用 [alipay.trade.create](https://opendocs.alipay.com/mini/05x9kv)（统一收单交易创建接口）创建交易订单trade_no
        - 可通过设置notify_url来进行接口异步回调通知，参考：https://opendocs.alipay.com/mini/080p65
    - 在小程序端调用 [my.tradePay](https://opendocs.alipay.com/mini/05xhsr)（发起支付）上传 tradeNO(trade_no)，唤起支付宝收银台，引导用户完成支付
- 小程序退款参考: https://opendocs.alipay.com/mini/05xskz
    - 退款成功判断说明：接口返回fund_change=Y为退款成功，fund_change=N或无此字段值返回时需通过退款查询接口进一步确认退款状态
    - 部分结果需要通过查询退款接口来进行判断退款状态，支付宝无退款回调通知（只有退款到银行卡时有对应通知）

## 小程序开发

### 用户信息

- 获取用户支付宝ID
    - 此时也需要用户弹框授权
    - 参考: https://opendocs.alipay.com/mini/api/openapi-authorize

```js
// 1.支付宝小程序调用API: my.getAuthCode; 此时会底部弹框提示用户需要获取昵称和头像信息，等待用户确认后进入success
my.getAuthCode({
    scopes: 'auth_user',
    success: (res) => {
        console.log('success', res)
        const code = res.authCode
        // TODO 拿到此授权code，请求后台
    },
    fail: (res) => {
        console.log('fail', res)
    },
})

// 2.服务端使用 authCode，调用 alipay.system.oauth.token 取得 user_id（open_id） 和 token（授权令牌）
// 参考：https://opendocs.alipay.com/open/84bc7352_alipay.system.oauth.token （需要使用支付宝公钥、应用私钥）
// 如果应用开启了open_id则返回的是open_id，否则返回的是user_id；支付宝更推荐使用open_id

// 3.(可选) 如果需要获取用户昵称和头像信息，则调用 alipay.user.info.share 获取（需要上文获取的授权令牌）
// 参考：https://opendocs.alipay.com/open/a74a7068_alipay.user.info.share
// 前提：需要在开放平台——控制台——隐私申请中的申请获取会员信息(申请此接口权限)
// 部分文档还是显示此接口可以返回手机号，目前已经无法返回了，如果需要获取用户手机号参考下文
```
- 获取用户手机号信息
    - 参考: https://opendocs.alipay.com/mini/api/getphonenumber

```js
// 1.开放平台-开发设置，配置加密、加签
// 2.开放平台-控制台-隐私申请-获取会员手机号；填写申请表单：使用场景、使用场景说明、页面流程说明、上传Demo(页面截图：授权前页面、授权弹框页面、用户拒绝后页面、用户同意授权后页面)

// 3.小程序通过button引导用户完成授权（点击后会底部弹框确认）
<button open-type="getAuthorize" scope="phoneNumber" onGetAuthorize="onGetAuthorize" onError="onError">授权手机号(原生支付宝小程序)</button>
<button open-type="getAuthorize" scope="phoneNumber"
		@getAuthorize="onGetAuthorize" @error="e => $squni.toast(e.detail.errorMessage)">授权手机号(基于uniapp开发支付宝小程序)</button>

// 4.用户点击确认后进入到onGetAuthorize事件：小程序中调用API；用户拒绝后进入到onError事件
my.getPhoneNumber({
    success: (res) => {
        console.log('success', res)
        let encryptedData = res.response
        // TODO 将获取到的加密信息传到后台进行解密
    },
    fail: (res) => {
        console.log('fail', res)
    },
})

// 5.后台解密
// 参考: https://opendocs.alipay.com/common/02mse3 （需要使用支付宝公钥、接口内容加密方式中设置的秘钥）
```

### 在线客服

- 参考
    - 小程序开通配置 https://opendocs.alipay.com/b/03al9b
    - 小程序contact-button组件使用 https://opendocs.alipay.com/mini/component/contact-button
    - 智能客服文档 https://www.yuque.com/em8gt4/qw1tt1
- 企业用户可在小程序信息 - 在线客服中开通智能客服
- 小程序用户入口
    - 小程序三点按钮基本信息中默认有(也可配置关掉)
    - 通过contact-button进行业务自定义入口
    - 首页悬浮按钮(只需配置即可)
- 服务模式: 设置 - 在线设置 - 支付宝服务 - 接待配置
    - 轻聊模式：直接在支付宝消息中进行接待客户(消息 - 客户咨询)
        - 选择客服：此处的顺序比较重要，优先发送给第一个客服，测试时把账号设置在前面或者只设置一个账号
        - 可能需要先开启下专业模式 - 首页入口打开，才能显示首页悬浮按钮
    - 专业模式：通过WEB端进行接待客户（首页入口打开后则有首页悬浮按钮）
- 新增人员：人员 - 员工管理 - 新增员工 - 填写手机号，打开"推送提醒"（轻聊模式下接受客户消息）
- 使用contact-button组件
    - 电脑端调试点击无效，真机调试点击可以

```html
<!-- 可以使用长方形图片，从而按钮呈现长方形，定义size此时按照图片长宽进行缩放 -->
<contact-button tnt-inst-id="S1I_xxxx" scene="SCE01110222" icon="/static/contact-full.png" size="690rpx" />
```

### 小程序短链

- 短链生成地址：诊断工具 - 小程序 - 跳转链接生成器：https://opensupport.alipay.com/support/diagnostic-tools/6630ae22-5336-4d67-a9b6-dbd987102fec
- 然后写一个域名伪静态从而进行推广

```bash
location = / {
  if ($host = 'm.example.com') {
    return 302 http://$server_name/api/short/wechat;
  }
  # 访问 http://a.example.com (如果手机浏览器访问可能会提示https证书问题，如果通过短信推广后从短信进入则不会提示？) 进入调用后台并进行重定向
  if ($host = 'a.example.com') {
    return 302 http://$server_name/api/short/alipay;
}
```

```java
@RequestMapping(value="/short/alipay" , method = RequestMethod.GET)
public String alipay() {
    String shortLink = 'https://ur.alipay.com/_27lcRxpqdGXPHADfTz1oRZ';
    return "redirect:" + shortLink;
}
```
