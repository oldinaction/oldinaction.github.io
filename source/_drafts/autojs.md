---
layout: "post"
title: "Auto.js"
date: "2023-08-12 08:18"
categories: [linux]
tags: [android,js]
---

## 简介

- Auto.js
    - 不需要Root权限的JavaScript自动化软件
    - 通过在安卓手机上安装对应APP，即可使用脚本通过安卓手机的无障碍API进行自动化控制
- [github](https://github.com/hyb1996/Auto.js)，安卓商店叫AutoJsPro(部分功能收费)，Auto.js v4.1之后停止维护
- 社区二开项目
    - [AutoJs6](https://github.com/SuperMonster003/AutoJs6)、[AutoJs6文档](https://docs.autojs6.com/)
    - (2503停止维护) [Autox.js](https://github.com/kkevsekk1/AutoX) Auto.js v4.1之后闭源，此版本为基于4.1之后的第三方开源版，[AutoX文档](http://doc.autoxjs.com/#/)
    - [robot](https://github.com/yooge/robot)、[文档](https://yooge.github.io/robot-docs)
        - uni-app ColorUI写UI，将AutoJS封装成APK底座实现调用AutoJS，支持代码加密
        - 测试运行报错
- [autojs案例](https://blog.csdn.net/snailuncle2/article/details/115278704)
    - [autojs各种签到脚本](https://github.com/bjc5233/autojs)
- 相关文章
    - [autojs常用代码介绍](https://www.jianshu.com/p/3b24656b22c9)
    - [自动化脚本工具:autojs/easyclick](https://juejin.cn/post/7286787235360931852)

## 工程化使用

- [autojs工程化](https://github.com/kkevsekk1/webpack-autojs) 在电脑上开发脚本并实时在手机上调试和部署到手机
- 使用

```bash
# 安装vscode插件Auto.js-Autox.js-VSCodeExt v1.109.0
# Cmd+Shift+P启动插件服务(会放出一个端口，手机通过此端口和电脑连接)
# 手机连接到电脑(基于内网连接，有时候会自动断，需要手动重新连接下)

# 编译(由于是编译后的js项目，可直接通过vscode的按钮运行到手机)
npm run build
# 再运行项目，之后脚本运行后可实时修改编译运行到手机(由于是node项目，不能直接通过vscode的按钮运行到手机)
npm run start
# 然后右键 dist/xxx 保存项目到设备
# 在手机上面执行脚本. 此时console.log等输出可以在vscode的输出中查看；如果修改了代码，需要重新build保存到手机
# 如果手机上的脚本关闭后，需要重新build保存到手机
```

### 工程化脚本案例

- 可通过autojs app 悬浮窗获取元素(控件)信息(如text/desc/bounds/id/className等)
- 闲鱼签到案例()

```js
// 自定义函数
var common = require("../../common/common.js");

/**
 * 定义主函数，入口函数
 * @param {*} options 服务器端穿过来的参数，在本地测试的是 options 是没有值的。
 */
function main(options) {
  common.resetConsole();

  // common.init(options);
  options = options || {};
  console.log('options-->', options);
  
  start();
}

function start() {
  common.openApp('闲鱼');
  common.waitTime(3, '等待闲鱼启动');

  common.consoleWrap('我的闲鱼币', openWdxyb, true);

  common.closeApp('闲鱼');
}

function openWdxyb() {
  click('我的');
  common.waitTime(1, '我的');

  descStartsWith('我的闲鱼币').findOne(1000).click();
  common.waitTime(2, '打开我的闲鱼币');

  common.consoleWrap('领取昨日奖励', startLqjl, true);
  common.consoleWrap('打开签到页', openQd);
}

function openQd() {
  let btn = desc('签到').findOne(1000)
  if (btn == null) {
    btn = desc('待领取').findOne(1000)
  }
  if (btn != null) {
    btn.click();
  } else if(descStartsWith('我的经验').findOne(1000) != null) {
    // 安卓7.0以上触摸模拟
    click(900, 1200);
  } else {
    console.warn('打开签到页失败')
    return
  }
  common.waitTime(1, '打开签到页');
  // 有奖励就领取
  common.clickDescAll('领取奖励');
}

function startLqjl() {
  let item = desc('点击领取').findOne(1000);
  if (item != null) {
    item.click();
    common.waitTime(2, '点击领取按钮');

    item = desc('知道了').findOne(1000);
    if (item != null) {
      item.click();
      common.waitTime(2, '点击知道了按钮');
    }
  }
}

main();
```

## 知识点

### 控件定位

```js
// textMatches使用: http://doc.autoxjs.com/#/widgetsBasedAutomation?id=uiselectortextmatchesreg
// 官网说字符串正则前后不用加//，实测需要加
// 子字符串匹配前后需要加.*，参考: https://github.com/kkevsekk1/AutoX/issues/430
// 匹配子孙控件包含26或28文字的
dateArr.filter(x => x.findOne(textMatches('/.*(26|28).*/')))

// 用className、depth、drawingOrder、indexInParent等参数定位。depth=14...
className('android.widget.TextView').depth(14).drawingOrder(1).indexInParent(0).id('tv_left_main_text').findOnce()
```

### 事件

- 监听系统消息：如复制验证码

```js
const SMSCodeRegex = /.*验证码[\s:：是]*(\d{4,6}).*/;

events.observeNotification(); // 启动通知监测

events.onNotification((n) => {
  const message = n.getText();
  if (!message || !message.includes('验证码')) {
    return;
  }

  const match = SMSCodeRegex.exec(message);
  if (!match) {
    console.log(`无法匹配验证码，消息内容：${message}`);
    return;
  }

  // the match result is array, so index 1 to fetch code.
  const code = match[1];

  setClip(code); // 设置到剪贴板命令
  toast(`验证码已发送至剪切板`);
});
```

## 技巧

- 可打印对象，然后根据对象的boundsInScreen参数和通过autojs工具拾取的元素bounds参数进行比对来确定当前是否为选中对象
- 关于点击无效
    - 使用`UiObject.click()` 支持控件`clickable: true`的情况
    - 使用坐标`click(x, y)`
    - 使用`longClick(x, y)`
    - 使用`press(x, y, duration)` 如闲鱼点击"等待卖家发货"文案，如果`clickable: true`的情况可能点击无效(如闲鱼我的 - 我卖出的 - 代发货点击无效，需要使用clikc函数)
    - click前使用sleep防止点击过快
    - 使用点击区块 click(left, top, bottom, right) 如大麦立即购票按钮
    - 使用自定义函数 common.swipeRandom 进行曲线滑动

