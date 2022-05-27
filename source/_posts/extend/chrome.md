---
layout: "post"
title: "Chrome"
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

- `谷歌访问助手`
- `AdBlock` 广告拦截
- `Infinity新标签页` 标签管理
- `有道词典Chrome划词插件`
- `Evernote Web Clipper` 印象笔记·剪藏
- `新浪微博图床`
- `Tampermonkey` 油猴脚本。相关脚本：https://greasyfork.org/zh-CN/scripts
- `IDM Integration Module` IDM下载
- `Secure Shell` ssh客户端
- `Postman` Http请求客户端
- `JSONView` 将Http请求获取的json字符串格式化(可收缩)
- `Selenium IDE` 自动化测试录制
- `Axure RP Extension for Chrome` Axure设计
- `Vue.js devtools` Vue.js调试工具
- `Set Character Encoding` 解决chrome查看源码乱码问题
- Github相关
    - `SourceGraph` 基于目录显示文件，类之间的跳转，代码搜索等功能
    - `Octotree` 展现源码目录
    - `GitHub加速`
    - `Enhanced GitHub` 显示每个文件大小，并提供单独下载链接
    - `GitZip` 下载文件夹：双击文件空白区域选中，点击页面右下角下载图标
    - `Awesome Autocomplete for GitHub` github实时搜索
    - `OctoLinker` 实现类名点击跳转
    - `GitHub Hovercard` 鼠标停留在 GitHub 网站的用户头像或者仓库链接地址上时，会自动弹出一个悬浮框，带你提前预览基本信息
    - `Remu` 收藏项目管理，项目备注/标签管理

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
        - `More tools`
            - `JavaScript profiler` 可分析CPU运行情况（但是对应页面卡死，无法暂停记录的情况暂不知如何解决）。参考：http://t.zoukankan.com/mengfangchao-p-7838808.html
- VM文件查看
    - VM文件是V8引擎计算出的临时代码，VM文件出现情况，如
        - 直接在console控制台运行js代码
        - 使用eval函数计算js代码(如果一些函数通过eval定义)
        - js添加的`<script>`标签产生的
    - 查看VM函数
        - `debugger` 相应代码。如某些函数通过eval定义，在调用此函数的地方debugger，运行到该行后，点击此行数就会出VM文件
- 打开新标签自动debug
    - Setting - DevTools - Auto-open DevTools for popups
- 每次重新打开无痕模式，缓存会清空

## 性能分析(Devtool Performance)

- 参考：https://zhuanlan.zhihu.com/p/29879682

## 生成桌面系统

- `更多工具 - 添加到桌面 - 在窗口中打开`
- 调试模式，更改窗口大小可跳转分辨率。如设置成`1366*715`

## chrome命令

- [chrome命令参数](https://peter.sh/experiments/chromium-command-line-switches/)
- chrome://浏览器命令
    - chrome://about 查看所有列表，常见如下
    - chrome://version 显示当前版本
    - chrome://flags 实验项目，加“#项目名称”锚点可以直接定位到项目
    - chrome://settings 设置，下图是设置定位
    - chrome://extensions 查看扩展程序，“chrome://extensions/程序名称”可快速打开
    - chrome://net-internals 显示网络事件信息
    - chrome://components 查看组件信息
    - chrome://memory-redirect 浏览器内存使用的统计信息，也可以这样进入：工具\任务管理器\详细统计信息
    - chrome://downloads 直接访问 Chrome 浏览器网页下载的文件
    - chrome://history 直接访问 Chrome 浏览器访问的历史记录
    - chrome://apps 访问 Chrome 浏览器中安装的应用的界面，可以对应用进行删除管理
    - chrome://bookmarks 直接访问 Chrome 浏览器中我们收藏的标签
    - chrome://dns 显示浏览器预抓取的主机名列表，让用户随时了解 DNS 状态
    - chrome://devices 查看连接电脑的设备，比如传统打印机中，可设置添加打印机到 Google 云打印的入口

## chrome插件开发

- 中文文档：[http://open.chrome.360.cn/extension_dev/overview.html](http://open.chrome.360.cn/extension_dev/overview.html)
- 参考文章：https://github.com/sxei/chrome-plugin-demo

### 说明

- manifest.json文件介绍

```json
// http://open.chrome.360.cn/extension_dev/manifest.html
{
	// 清单文件的版本，这个必须写，而且必须是2
	"manifest_version": 2,
	"name": "demo",
	"version": "1.0.0",
	"description": "简单的Chrome扩展demo",
	// 插件图标
	"icons":
	{
		"16": "img/icon.png",
		"48": "img/icon.png",
		"128": "img/icon.png"
	},
	// 是一个常驻的页面，它的生命周期是插件中所有类型页面中最长的，它随着浏览器的打开而打开，随着浏览器的关闭而关闭，所以通常把需要一直运行的、启动就运行的、全局的代码放在background里面。background的权限非常高，几乎可以调用所有的Chrome扩展API（除了devtools），而且它可以无限制跨域，也就是可以跨域访问任何网站而无需要求对方设置CORS
	"background":
	{
		// 2种指定方式，如果指定JS，那么会自动生成一个背景页
		"page": "background.html"
		//"scripts": ["js/background.js"]
	},
    // 浏览器右上角图标设置，browser_action、page_action、app必须三选一。一个browser_action可以拥有一个图标，一个tooltip，一个badge和一个popup
    // 点击`browser_action`或者`page_action`图标时，可打开的一个小窗口网页(popup)
	"browser_action": 
	{
		"default_icon": "img/icon.png",
		// 图标悬停时的标题，可选
		"default_title": "这是一个示例Chrome插件",
		"default_popup": "popup.html"
	},
	// 当某些特定页面打开才显示的图标
	/*"page_action":
	{
		"default_icon": "img/icon.png",
		"default_title": "我是pageAction",
		"default_popup": "popup.html"
	},*/
	// 需要直接注入页面的JS。所谓content-scripts，其实就是Chrome插件中向页面注入脚本的一种形式（虽然名为script，其实还可以包括css的），借助content-scripts我们可以实现通过配置的方式轻松向指定页面注入JS和CSS（也可动态注入）
	"content_scripts": 
	[
		{
			//"matches": ["http://*/*", "https://*/*"],
			// "<all_urls>" 表示匹配所有地址
			"matches": ["<all_urls>"],
			// 多个JS按顺序注入
			"js": ["js/jquery-1.8.3.js", "js/content-script.js"],
			// JS的注入可以随便一点，但是CSS的注意就要千万小心了，因为一不小心就可能影响全局样式
			"css": ["css/custom.css"],
			// 代码注入的时间，可选值： "document_start", "document_end", or "document_idle"，最后一个表示页面空闲时，默认document_idle
			"run_at": "document_start"
		},
		// 这里仅仅是为了演示content-script可以配置多个规则
		{
			"matches": ["*://*/*.png", "*://*/*.jpg", "*://*/*.gif", "*://*/*.bmp"],
			"js": ["js/show-image-content-size.js"]
		}
	],
	// 权限申请
	"permissions":
	[
		"contextMenus", // 右键菜单
		"tabs", // 标签
		"notifications", // 通知
		"webRequest", // web请求
		"webRequestBlocking",
		"storage", // 插件本地存储
		"http://*/*", // 可以通过executeScript或者insertCSS访问的网站
		"https://*/*" // 可以通过executeScript或者insertCSS访问的网站
	],
	// 普通页面能够直接访问的插件资源列表，如果不设置是无法直接访问的
	"web_accessible_resources": ["js/inject.js"],
	// 插件主页，这个很重要，不要浪费了这个免费广告位
	"homepage_url": "https://www.baidu.com",
	// 覆盖浏览器默认页面
	"chrome_url_overrides":
	{
		// 覆盖浏览器默认的新标签页
		"newtab": "newtab.html"
	},
	// Chrome40以前的插件配置页写法
	"options_page": "options.html",
	// Chrome40以后的插件配置页写法，如果2个都写，新版Chrome只认后面这一个
	"options_ui":
	{
		"page": "options.html",
		// 添加一些默认的样式，推荐使用
		"chrome_style": true
	},
	// 向地址栏注册一个关键字以提供搜索建议，只能设置一个关键字
	"omnibox": { "keyword" : "go" },
	// 默认语言
	"default_locale": "zh_CN",
	// devtools页面入口，注意只能指向一个HTML文件，不能是JS文件
	"devtools_page": "devtools.html"
}
```

### 案例: 改变网页背景颜色

- chrome官网例子getstarted，下载地址`https://developer.chrome.com/extensions/examples/tutorials/getstarted.zip`
- 效果展示

    ![chrome-plugin-getstarted2](/data/images/2016/09/chrome-plugin-getstarted2.png)

    ![chrome-plugin-getstarted1](/data/images/2016/09/chrome-plugin-getstarted1.png)
- 插件文件结构

    ```bash
    ├─manifest.json     # 必须。主配置文件，必须放在根目录
    ├─icon.png          # 插件在浏览器工具栏中显示的图标
    ├─popup.html        # 点击插件图标显示插件的弹框功能界面，可命名为其他
    ├─popup.js          # 弹框功能界面所需js
    ```
- manifest.json

    ```json
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
- popup.html

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
- popup.js

    ```js
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

    function getSavedBackgroundColor(url, callback) {
        // See https://developer.chrome.com/apps/storage#type-StorageArea. We check
        // for chrome.runtime.lastError to ensure correctness even when the API call
        // fails.
        chrome.storage.sync.get(url, (items) => {
            callback(chrome.runtime.lastError ? null : items[url]);
        });
    }

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

### 安装/打包/发布

- 开启Chrome开发者模式
- 本地测试安装：插件管理页 - 加载已解压的的扩展程序
    - 如果修改了代码需要点击插件刷新按钮，或重新加载
    - popup部分调试：需要右键插件图标 - 审查弹出内容
- 打包为crx文件发布
    - 在chrome安装目录运行 `chrome.exe --pack-extension="D:\chromeplugins\helloword"`
        - `helloword`为插件源码根目录
        - 会生成`helloword.crx`(扩展文件)和`helloword.pem`(密钥)
- 上传zip到chrome发布：https://chrome.google.com/webstore/developer/dashboard
- 本地插件源码查看：`C:/Users/smalle/AppData/Local/Google/Chrome/User Data/Default/Extensions/hjljaklopfcidbbglpbehlgmelokabcp`
