---
layout: "post"
title: "nwjs"
date: "2018-11-18 19:30"
categories: [web]
tags: [node, desktop]
---

## 介绍

- [官网](https://nwjs.io/)。其他教程：https://nwjs.org.cn/ 、 https://wizardforcel.gitbooks.io/nwjs-doc/content/wiki/index.html
- `NW.js`，之前为`node-webkit`，是一个结合了 Chromium 和 node.js 的应用运行时，通过它可以用 HTML 和 JavaScript 编写原生应用程序。可基于html、css、js写桌面系统。打包后可运行的环境包括32位和64位的Window(windows xp及以上)、Linux和Mac OS
- 建议下载SDK，开发时才可进行debug，[nwjs-sdk-v0.34.4-win-x64.zip下载](https://dl.nwjs.io/v0.34.4/nwjs-sdk-v0.34.4-win-x64.zip)。[支持windows xp最终版本为v0.14.7](https://dl.nwjs.io/v0.14.7)。下载完成后解压SDK，可将SDK目录加入到path环境变量中，从此可直接执行`nw`
- 可使用`nw-builder`进行打包。打包后大概200M，再压成安装包大概80M
- **相同的框架如Electron**

## 案例

### helloworld

- package.json

```js
{
  "name": "helloworld",
  "main": "index.html"
}
```

- index.html

```html
<html>
<head>
  <meta charset="utf-8"/>
  <title>操作nwjs和nodejs API</title>
</head>
<body style="width: 100%; height: 100%;">

<p>右键显示菜单</p>
<p id="os"></p>

</body>
</html>
<script>
// 调用nwjs api
// Create an empty context menu
var menu = new nw.Menu();

// Add some items with label
menu.append(new nw.MenuItem({
  label: 'Item A',
  click: function(){
    alert('You have clicked at "Item A"');
  }
}));
menu.append(new nw.MenuItem({ label: 'Item B' }));
menu.append(new nw.MenuItem({ type: 'separator' }));
menu.append(new nw.MenuItem({ label: 'Item C' }));

// Hooks the "contextmenu" event
document.body.addEventListener('contextmenu', function(ev) {
  // Prevent showing default context menu
  ev.preventDefault();
  // Popup the native context menu at place you click
  menu.popup(ev.x, ev.y);

  return false;
}, false);

// 调用node.js api
// get the system platform using node.js
var os = require('os');
document.getElementById("os").innerText = '项目运行环境：' + os.platform();
</script>  
</body>
</html>
```

- 运行：在此项目目录执行`nw .`即可。编译请看下文

### 访问access数据库

- package.json

```
{
  "name": "helloworld",
  "version": "0.1.0",
  "main": "index.html",
  "scripts": {
      "build": "node build"
  },
  "dependencies": {
    "node-adodb": "^4.2.2"
  },
  "devDependencies": {
    "nw-builder": "^3.5.4"
  }
}
```

- index.html

```html
<html>
<head>
  <meta charset="utf-8"/>
  <title>访问access数据库</title>
</head>
<body style="width: 100%; height: 100%;">
<!-- D:/vscodework/nwjs-demo/demo3-accessdb/node-adodb.accdb -->
请输入access数据库路径：<input id="path" style="width:500px;" type="text"/>
<button onclick="conn()">连接数据库</button>
<button onclick="query()">获取数据</button>
<button onclick="insert()">插入数据</button>
<button onclick="clearText()">清空显示</button>

<p id="query"></p>
<br/>
<p id="insert"></p>

</body>
</html>
<script>
'use strict';
// 调用node.js api
var ADODB = require('node-adodb');
ADODB.debug = true; // 全局调试开关，默认关闭
var connection;

// conn();
// query();

function conn() {
  var path = document.getElementById("path").value;
  // path = "‪D:/vscodework/nwjs-demo/demo3-accessdb/node-adodb.accdb"; // 这一行字符串看着和下一行一样，但是编码有问题，无法正常连接
  // path = "D:/vscodework/nwjs-demo/demo3-accessdb/node-adodb.accdb"; // node-adodb.mdb
  // connection = ADODB.open('Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+ path +';');
  connection = ADODB.open('Provider=Microsoft.ACE.OLEDB.16.0;Data Source='+ path +';Persist Security Info=False;');
}

// 带返回的查询
function query() {
  connection
    .query('SELECT * FROM Users')
    .then(data => {
      var str = JSON.stringify(data, null, 2);
      console.log(str);
      document.getElementById("query").innerText = str;
    })
    .catch(error => {
      console.log(error);
      document.getElementById("query").innerText = JSON.stringify(error, null, 2);
    });
}

function insert() {
  connection.execute('INSERT INTO Users(UserName, UserSex, UserBirthday, UserMarried) VALUES ("Smalle", "Male", "1991/3/9", 0)')
    .then(data => {
      var str = JSON.stringify(data, null, 2)
      console.log(str);
      document.getElementById("insert").innerText = str;
      alert("执行成功")
    })
    .catch(error => {
      console.log(error);
      document.getElementById("insert").innerText = JSON.stringify(error, null, 2);
    });
}

function clearText() {
  document.getElementById("query").innerText = "";
  document.getElementById("insert").innerText = "";
}

</script>
</body>
</html>
```

- build.js编译入口

```js
var NwBuilder = require('nw-builder');
var nw = new NwBuilder({
    files: './**', // use the glob format
    platforms: ['osx64', 'win32', 'win64'],
    version: '0.14.7'
});

// Log stuff you want
nw.on('log', console.log);

nw.build().then(function () {
    console.log('all done!');
}).catch(function (error) {
    console.error(error);
});

// 运行
// nw.run().then(function () {
//     console.log('all done!');
// }).catch(function (error) {
//     console.error(error);
// });
```

#### 说明

- `nw-builder` 打包
    - 管理员Cmd执行`npm run build`(node运行此项目build.js)
    - Enigma Virtual Box 再次打包，或者通过`Inno Setup`打成安装包
- `node-adodb`连接`access`数据库。参考[http://blog.aezo.cn/2018/11/20/db/access/](/_posts/db/access.md). 无需通过nw-gpy重新构建



