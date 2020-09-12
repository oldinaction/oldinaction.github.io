---
layout: "post"
title: "Electron —— 基于前端构建跨平台桌面应用程序"
date: "2020-09-11 15:43"
categories: web
tags: [desctop]
---

## 简介

- [官网](http://www.electronjs.org/)
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
- 案例

```bash
# 之前已经基于vue-cli的项目，如基于iview-admin实现的。现在基于Electron官方demo进行集成

# 1.添加依赖
cnpm install electron --save-dev
cnpm install electron-packager --save-dev # 这个是打成exe文件的插件。如果是node v8.x可使用版本v14.2.1，而v15.x需要node v10.x。还可使用electron-builder进行打包

# 参考上文简单使用下载electron-quick-start项目
# 2.把electron-quick-start项目中的main.js和preload.js（老的示例可能没有）复制到vue的build文件中(没有可以新建)，并将main.js重命名为electron.js
# 3.修改build/electron.js(electron)文件中代码为 `mainWindow.loadFile('../dist/index.html')` 此时dist是vue打包后生成文件的路径

# 4.package.json文件增加如下脚本代码
"scripts": {
    "electron_dev": "npm run build && electron build/electron.js",
    "electron_test": "vue-cli-service build --mode test && electron-packager ./dist/ --arch=x64 --overwrite"
}

# 5.vue-cli3时，修改vue.config.js的 `publicPath: './'`，如果是vue-cli2或webpack打包的修改对应的 `assetsPublicPath: './'`
# 改完之后通过vue server启动，在浏览器里面访问可能有问题，因此可以通过变量动态设置publicPath
# 原来一般为 /，是通过url访问的，此时需要修改为相对路径，是基于目录访问的
# 如果改错了很容易出现白屏情况，可在build/electron.js(electron)文件中打开`mainWindow.webContents.openDevTools()`，从而窗口可以显示出chrome dev tools进行调试

# 6.如果使用vue-router，需要使用hash模式，如果使用history模式容易出现跳转页面失败情况

# 7.运行项目
npm run electron_dev

# 8.打包
# 8.1 复制 build/electron.js 和 build/preload.js 文件到 public 目录（vue打包的模板文件夹，里面有index.html文件）下，并重命名electron.js为index.js（后面解释原因）
# 8.2 修改此index.js文件中的 mainWindow.loadFile('../dist/index.html') 为 mainWindow.loadFile('index.html')
# 8.3 在 public 目录创建文件 package.json，并写入 `{}` 
# 8.4 执行打包
npm config set ELECTRON_MIRROR https://npm.taobao.org/mirrors/electron/ # 打包时会下载electron压缩包，此时设置镜像进行加速
npm run electron_build # 打包，会生成 xxx-win32-x64 文件夹

# 9.通过Inno Setup将文件再次打包成安装包后分发给客户
```
- 打包说明
    - vue项目文件目录结构

        ```bash
        build # electron运行目录，可`electron build/electron.js`运行electron应用
            electron.js # electron入口文件
            preload.js
        dist # vue打包的目标目录
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
    - 点击可执行文件demo.exe 
      - 从resources/app/package.json文件中获取入口文件（如package.json定义属性：`"main": "my_dir/my_index.js"`，那么入口文件则是此处指定的，如果没有指定main属性，则入口文件为package.json同目录下的index.js文件）。为了方便上文案例中package.json内容只有`{}`，因此对electron.js重命名为index.js
      - 而index.js中通过`mainWindow.loadFile('index.html')`引入vue打包生成的index.html文件，从而启动了vue应用
- electron-builder 和 electron-packager 均可用于打包。electron-builder配置根灵活清晰
