---
layout: "post"
title: "Electron —— 基于前端构建跨平台桌面应用程序"
date: "2020-09-11 15:43"
categories: web
tags: [desctop]
---

## 简介

- [官网](http://www.electronjs.org/)、[w3cschool文档](https://www.w3cschool.cn/electronmanual/)
- `Electron`
  - 使用 JavaScript，HTML 和 CSS 构建跨平台（Mac、Windows 和 Linux）的桌面应用程序
  - Electron 结合了 Chromium、Node.js 和用于调用操作系统本地功能的 API（如打开文件窗口、通知、图标等）
- 案例：VS Code、Slack、Facebook Messenger等
- 相关文章
  - [Electron 与 Vue 的性能优化](https://aotu.io/notes/2016/11/15/xcel/index.html)

## 简单使用

```bash
# 运行官方示例
git clone https://github.com.cnpmjs.org/electron/electron-quick-start.git
cd electron-quick-start
cnpm install
npm start
```

## VUE项目基于Electron打包

- 将VUE项目集成Electron有两种方式
  - 在自己的 vue 的项目中引入插件，然后打包（本文案例）
  - 将自己的 vue 项目打包，放到官方的 demo 文件中，改变打包路径
  - 通过`simulatedgreg/electron-vue`等插件创建vue项目，则包含了Electron
- 案例（本案例基于electron-packager打包，不过更推荐electron-builder，具体见下文）

```bash
# 之前已经基于vue-cli的项目，如基于iview-admin实现的。现在基于Electron官方demo进行集成

# 1.添加依赖
cnpm install electron --save-dev
cnpm install electron-packager --save-dev # 这个是打成exe文件的插件。如果是node v8.x可使用版本v14.2.1，而v15.x需要node v10.x。还可使用electron-builder进行打包

# 参考上文简单使用下载electron-quick-start项目
# 2.把electron-quick-start项目中的main.js和preload.js（老的示例可能没有）复制到vue的public文件中(vue打包的模板目录)，并将main.js重命名为index.js

# 3.package.json文件增加如下脚本代码
"scripts": {
    "electron_dev": "npm run build && electron dist/index.js",
    "electron_test": "vue-cli-service build --mode test && electron-packager ./dist/ --arch=x64 --overwrite"
}

# 4.vue-cli3时，修改vue.config.js的 `publicPath: './'`，如果是vue-cli2或webpack打包的修改对应的 `assetsPublicPath: './'`
# 改完之后通过vue server启动，在浏览器里面访问可能有问题，因此可以通过变量动态设置publicPath
# 原来一般为 /，是通过url访问的，此时需要修改为相对路径，是基于目录访问的
# 如果改错了很容易出现白屏情况，可在public/index.js(electron的main.js)文件中打开`mainWindow.webContents.openDevTools()`，从而窗口可以显示出chrome dev tools进行调试

# 5.如果使用vue-router，需要使用hash模式，如果使用history模式容易出现跳转页面失败情况

# 6.运行项目
npm run electron_dev

# 7.打包
# 7.1 在 public 目录创建文件 package.json，并写入 `{}`
# 7.2 执行打包
npm i -g mirror-config-china --registry=https://registry.npm.taobao.org # 安装相关镜像。包含了 npm config set ELECTRON_MIRROR https://npm.taobao.org/mirrors/electron/ # 打包时会下载electron压缩包，此时设置镜像进行加速
npm run electron_build # 打包，会生成 xxx-win32-x64 文件夹

# 8.通过Inno Setup将文件再次打包成安装包后分发给客户，如皋使用electron-builder则自带打包成安装包
```
- 打包说明
    - vue项目文件目录结构

        ```bash
        dist # vue打包的目标目录
            index.html
            package.json
            index.js # 可`electron dist/index.js`运行electron应用
            preload.js
        demo-win32-x64 # 打包生成文件目录
            locales
            resources # 资源文件目录
                app # 项目打包后文件目录。会把上文命令`electron-packager ./dist/ --arch=x64 --overwrite`中的./dist/目录下文件全部复制到app目录
                    main.js
                    index.html
                    package.json
                    index.js
                    preload.js
            demo.exe # 可执行文件
        node_modules
        public # vue打包模板文件夹，最终会打包到dist目录
            index.html
            package.json
            index.js
            preload.js
        src
            main.js
        package.json
        vue.config.js
        ```
    - 启动过程
      - 点击可执行文件demo.exe 
      - 从resources/app/package.json文件中获取入口文件
        - 如package.json定义属性：`"main": "my_dir/my_index.js"`，那么入口文件则是此处指定的，如果没有指定main属性，则入口文件为package.json同目录下的index.js文件
        - 无package.json文件，则点击demo.exe无任何反应
      - 为了方便上文案例中package.json内容只有`{}`，因此public/index.js即为入口文件
      - 而index.js中通过`mainWindow.loadFile('index.html')`引入vue打包生成的index.html文件（原public/index.html文件），从而启动了vue应用
- [electron-builder（参考下文）](#基于electron-builder进行打包) 和 electron-packager 均可用于打包。electron-builder配置根灵活清晰

## 基于electron-builder进行打包

### 简单打包

```bash
# 参考：https://github.com/QDMarkMan/CodeBlog/tree/master/Electron
npm i -g mirror-config-china --registry=https://registry.npm.taobao.org # 安装相关镜像
npm install electron-builder -D # node 8.x 需要安装 20.44.4以下版本

# 修改public/index.js(上文electron-quick-start/main.js)中的 `mainWindow.loadFile('index.html')` 为 `mainWindow.loadURL('file://' + __dirname + '/index.html')`

# 修改package.json配置文件，见下文
```
- package.json配置文件

```json
{
  "scripts": {
    "e_dev": "vue-cli-service build --mode electron_dev && electron dist/index.js",
    "e_test": "vue-cli-service build --mode electron_test && electron-builder --dir",
    "e_prod": "vue-cli-service build --mode electron_prod && electron-builder", // 默认64位
    "e_prod_x32": "vue-cli-service build --mode electron_prod && electron-builder --ia32" // 打包32位
  },
  "main": "./dist/index.js",
  // electron-builder配置
  "build": {
    "productName": "Flight", // 项目名，这也是生成的exe文件的前缀名
    "appId": "com.unilog.flight",
    "copyright": "UNILOG",
    // 需要打包的文件
    "files": [
      "dist/**"
    ],
    // output编译后输出文件目录
    "directories": {
        "output": "electron-out"
    },
    // "asar": true, // 进行asar打包，默认为true
    // windows相关的配置
    "win": {
      "icon": "electron-build/icons/icon.ico", // (安装包和可执行程序的)图标路径，需要256*256以上
      // 当执行 electron-builder 打包时，生成nsis安装包和zip压缩包。如皋执行 electron-builder --dir 进行测试打包时，则不会生成
      "target": [
        "nsis"
        // ,"zip"
      ]
    },
    // mac打包选项
    "dmg": {
      //窗口左上角起始坐标和窗口大小
      "window": {
        "x": 100,
        "y": 100,
        "width": 1366,
        "height": 768
      }
    },
    // mac
    "mac": {
      "icon": "electron-build/icons/icon.icns"
    },
    // linux
    "linux": {
      "icon": "electron-build/icons"
    },
    "nsis": {
        "oneClick": false, // 是否一键安装，默认为true（会自动安装到 C:\Users\xxx\AppData\Local\Programs\）
        "allowElevation": true, // 允许请求提升。如果为false，则用户必须使用提升的权限重新启动安装程序
        "allowToChangeInstallationDirectory": true, // 允许修改安装目录，非一键安装时
        "installerIcon": "electron-build/icons/icon.ico", // 安装图标
        "uninstallerIcon": "electron-build/icons/icon.ico", //卸载图标
        "installerHeaderIcon": "electron-build/icons/icon.ico", // 安装时头部图标
        "createDesktopShortcut": true, // 创建桌面图标
        "createStartMenuShortcut": true, // 创建开始菜单图标
        "shortcutName": "xxxx", // 图标名称
        "include": "electron-build/script/installer.nsh" // 包含的自定义nsis脚本，这个对于构建需求严格得安装过程相当有用
    }
  }
}
```
- 常见问题
  - 报错：`Unresolved node modules: vue`。解决：此问题为cnpm安装依赖导致，**需要使用npm安装**，然后配合mirror-config-china进行安装 [^1]

### 自动更新

- 更新方式
    - 替换html文件更新，这个比较节约资源，但是并不适用于builder打包出来的程序
    - 替换asar文件，这个比较小众
    - **electron-builder + electron-updater 实现全量更新**
- 安装`npm i electron-updater -S`
- package.json增加publish配置

```json
{
    "build": {
        // 这个配置会生成latest.yml文件，用于自动更新的配置信息
        "publish": [{
            "provider": "generic", // 服务器提供商，也可以是GitHub等等
            "url": "" // 更新服务器地址，可为空，在代码中会再次设定
        }]
    }
}
```

https://www.electronjs.org/docs/api

https://segmentfault.com/a/1190000012904543

autoUpdater借助Squirrel实现自动升级



---

参考文章

[^1]: https://blog.csdn.net/g_soledad/article/details/105053322
