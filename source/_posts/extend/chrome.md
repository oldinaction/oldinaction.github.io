---
layout: "post"
title: "chrome"
date: "2017-09-13 12:56"
categories: [extend]
tags: [plugins, debug]
---

## 浏览器版本介绍

- 浏览器控制台执行`navigator`，或者访问`http://www.w3school.com.cn/tiy/t.asp?f=jseg_browserdetails`可查看浏览器版本信息(js获取示例)
- `Windows NT 10.0; WOW64` win10 64位系统； `Windows NT 6.3` 为win8； `Windows NT 5.1` 为win xp
- `Chrome/67.0.3396.10`为谷歌浏览器版本；`Firefox/60.0` 为火狐版本；`rv:11.0`为IE更新版本
- 常见浏览器版本举例
    - 谷歌 `Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.10 Safari/537.36`
    - 火狐 `Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:60.0) Gecko/20100101 Firefox/60.0`
    - IE `Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; .NET4.0C; .NET4.0E; .NET CLR 2.0.50727; .NET CLR 3.0.30729; .NET CLR 3.5.30729; rv:11.0) like Gecko`

## chrome插件收集

- `Postman` Http请求客户端
- `JSONView` 将Http请求获取的json字符串格式化(可收缩)
- `Secure Shell` ssh客户端
- `Axure RP Extension for Chrome` Axure设计
- `Set Character Encoding` 解决chrome查看源码乱码问题
- `Vue.js devtools` Vue.js调试工具
- `AdBlock` 广告拦截
- `有道词典Chrome划词插件`
- `印象笔记·剪藏`
- `Infinity新标签页` 标签管理

- `Octo Mate` github单文件下载(也可右键github按钮raw另存为)

## 调试技巧

- `ctrl + shift + i`/`F12` 打开开发者工具
- 主面板介绍
    - `Elements` html文件显示，Css样式调试
    - `Console` js代码打印面板
    - `Sources` 静态文件(html、css、js、images等)
        -  `{}`/`Pretty Print`可对压缩文件进行格式化
    - `NetWork` 网络显示面板：记录所有请求加载(XHR/JS/CSS/Img等)
        - `Initiator` 可查看此执行此请求的运行栈(如：某按钮被点击 - 发起XHR请求)
        - 点击某个请求可查看请求头(Headers)、响应结果等
    - `Application` 查看网址的Cookies、Storage等
    - `更多按钮`
        - `Search all files` 基于此url地址请求的所有静态文件进行查询。多用于js函数搜索
- VM文件查看
    - VM文件是V8引擎计算出的临时代码，VM文件出现情况，如：（1）直接在console控制台运行js代码 （2）使用eval函数计算js代码(如果一些函数通过eval定义)（3）js添加的`<script>`标签产生的
    - 查看VM函数
        - `debugger` 相应代码。如某些函数通过eval定义，在调用此函数的地方debugger，运行到该行后，点击此行数就会出VM文件

## 生成桌面系统

- `更多工具 - 添加到桌面 - 在窗口中打开`
- 调试模式，更改窗口大小可跳转分辨率。如设置成`1366*715`

## chrome命令

> 参考：[chrome命令](https://peter.sh/experiments/chromium-command-line-switches/)

## chrome插件开发

- 中文文档：[http://open.chrome.360.cn/extension_dev/overview.html](http://open.chrome.360.cn/extension_dev/overview.html)

### helloword：改变网页背景颜色

- chrome官网例子getstarted，下载地址`https://developer.chrome.com/extensions/examples/tutorials/getstarted.zip`
- 效果展示

    ![chrome-plugin-helloword](/data/images/2016/09/chrome-plugin-helloword.png)

- `icon.png` 显示
- `manifest.json`
    ```js
    {
        "manifest_version": 2,

        "name": "Getting started example",
        "description": "This extension allows the user to change the background color of the current page.",
        "version": "1.0",

        "browser_action": {
            "default_icon": "icon.png",
            "default_popup": "popup.html"
        },
        "permissions": [
            "activeTab",
            "storage"
        ]
    }
    ```
- `popup.html`

    ```html
    <!doctype html>
    <html>
    <head>
        <title>Getting Started Extension's Popup</title>
        <style type="text/css">
        body {
            margin: 10px;
            white-space: nowrap;
        }

        h1 {
            font-size: 15px;
        }

        #container {
            align-items: center;
            display: flex;
            justify-content: space-between;
        }
        </style>
        <script src="popup.js"></script>
    </head>

    <body>
        <h1>Background Color Changer</h1>
        <div id="container">
        <span>Choose a color</span>
        <select id="dropdown">
            <option selected disabled hidden value=''></option>
            <option value="white">White</option>
            <option value="pink">Pink</option>
            <option value="green">Green</option>
            <option value="yellow">Yellow</option>
        </select>
        </div>
    </body>
    </html>
    ```
- `popup.js`

    ```js
    /**
    * Get the current URL.
    *
    * @param {function(string)} callback called when the URL of the current tab
    *   is found.
    */
    function getCurrentTabUrl(callback) {
        // Query filter to be passed to chrome.tabs.query - see
        // https://developer.chrome.com/extensions/tabs#method-query
        var queryInfo = {
            active: true,
            currentWindow: true
        };

        chrome.tabs.query(queryInfo, (tabs) => {
            // chrome.tabs.query invokes the callback with a list of tabs that match the
            // query. When the popup is opened, there is certainly a window and at least
            // one tab, so we can safely assume that |tabs| is a non-empty array.
            // A window can only have one active tab at a time, so the array consists of
            // exactly one tab.
            var tab = tabs[0];

            // A tab is a plain object that provides information about the tab.
            // See https://developer.chrome.com/extensions/tabs#type-Tab
            var url = tab.url;

            // tab.url is only available if the "activeTab" permission is declared.
            // If you want to see the URL of other tabs (e.g. after removing active:true
            // from |queryInfo|), then the "tabs" permission is required to see their
            // "url" properties.
            console.assert(typeof url == 'string', 'tab.url should be a string');

            callback(url);
        });

        // Most methods of the Chrome extension APIs are asynchronous. This means that
        // you CANNOT do something like this:
        //
        // var url;
        // chrome.tabs.query(queryInfo, (tabs) => {
        //   url = tabs[0].url;
        // });
        // alert(url); // Shows "undefined", because chrome.tabs.query is async.
        }

        /**
        * Change the background color of the current page.
        *
        * @param {string} color The new background color.
        */
        function changeBackgroundColor(color) {
        var script = 'document.body.style.backgroundColor="' + color + '";';
        // See https://developer.chrome.com/extensions/tabs#method-executeScript.
        // chrome.tabs.executeScript allows us to programmatically inject JavaScript
        // into a page. Since we omit the optional first argument "tabId", the script
        // is inserted into the active tab of the current window, which serves as the
        // default.
        chrome.tabs.executeScript({
            code: script
        });
        }

        /**
        * Gets the saved background color for url.
        *
        * @param {string} url URL whose background color is to be retrieved.
        * @param {function(string)} callback called with the saved background color for
        *     the given url on success, or a falsy value if no color is retrieved.
        */
        function getSavedBackgroundColor(url, callback) {
        // See https://developer.chrome.com/apps/storage#type-StorageArea. We check
        // for chrome.runtime.lastError to ensure correctness even when the API call
        // fails.
        chrome.storage.sync.get(url, (items) => {
            callback(chrome.runtime.lastError ? null : items[url]);
        });
        }

        /**
        * Sets the given background color for url.
        *
        * @param {string} url URL for which background color is to be saved.
        * @param {string} color The background color to be saved.
        */
        function saveBackgroundColor(url, color) {
        var items = {};
        items[url] = color;
        // See https://developer.chrome.com/apps/storage#type-StorageArea. We omit the
        // optional callback since we don't need to perform any action once the
        // background color is saved.
        chrome.storage.sync.set(items);
        }

        // This extension loads the saved background color for the current tab if one
        // exists. The user can select a new background color from the dropdown for the
        // current page, and it will be saved as part of the extension's isolated
        // storage. The chrome.storage API is used for this purpose. This is different
        // from the window.localStorage API, which is synchronous and stores data bound
        // to a document's origin. Also, using chrome.storage.sync instead of
        // chrome.storage.local allows the extension data to be synced across multiple
        // user devices.
        document.addEventListener('DOMContentLoaded', () => {
        getCurrentTabUrl((url) => {
            var dropdown = document.getElementById('dropdown');

            // Load the saved background color for this page and modify the dropdown
            // value, if needed.
            getSavedBackgroundColor(url, (savedColor) => {
            if (savedColor) {
                changeBackgroundColor(savedColor);
                dropdown.value = savedColor;
            }
            });

            // Ensure the background color is changed and saved when the dropdown
            // selection changes.
            dropdown.addEventListener('change', () => {
            changeBackgroundColor(dropdown.value);
            saveBackgroundColor(url, dropdown.value);
            });
        });
    });
    ```

### 打包发布

1. 打包为crx文件发布
    - 在chrome安装目录运行 `chrome.exe --pack-extension="D:\chromeplugins\helloword"`
        - `helloword`为插件源码根目录
        - 会生成`helloword.crx`(扩展文件)和`helloword.pem`(密钥)
2. 上传zip到chrome：https://chrome.google.com/webstore/developer/dashboard