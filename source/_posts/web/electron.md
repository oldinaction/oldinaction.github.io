---
layout: "post"
title: "Electron —— 基于前端构建跨平台桌面应用程序"
date: "2020-09-11 15:43"
categories: web
tags: [desktop]
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
npm install
npm start
```

## 与VUE项目结合

- 将VUE项目集成Electron有两种方式
    - 在自己的 vue 的项目中引入插件，然后打包（本文案例）
    - 将自己的 vue 项目打包，放到官方的 demo 文件中，改变打包路径
    - 通过`simulatedgreg/electron-vue`等插件创建vue项目，则包含了Electron
- **大部分组件通过npm设置为淘宝镜像即可加速，但是像electron-mirror、node-sass等组件需要额外设置镜像地址配置到`~/.npmrc`才能成功下载**。可使用mirror-config-china插件将常用组件的镜像地址全部加入到了上述文件夹。**electron项目用cnpm可能会出现一些奇怪的现象**

### 基于electron-builder打包(推荐)

- [electron-builder文档](https://www.electron.build/)
- [electron-builder打包时会下载的一些依赖](https://github.com/electron-userland/electron-builder-binaries)，下载保存的目录为
    - macOS: `~/Library/Caches/electron-builder`
    - Linux: `~/.cache/electron-builder`
    - windows: `%LOCALAPPDATA%\electron-builder\cache` 依赖包存放路径如
        - nsis
            - nsis-3.0.3.2
            - nsis-resources-3.3.0
        - winCodeSign
            - winCodeSign-2.4.0

#### 参数说明

```bash
electron-builder

--dir   # 打包成文件夹，不生成exe文件(不要此参数，默认会生成exe文件)
--win   # 打包出 windows 可执行的程序。省略此参数，在windows可正常打包，但是在centos上打包出错，具体见下文[centos上打包说明]
```

#### 使用案例

```bash
# 参考：https://github.com/QDMarkMan/CodeBlog/tree/master/Electron

# 测试环境：node v12.16.3（node v10亦可）、vue-cli3、electron v10.1
# 之前已经基于vue-cli的项目，如基于iview-admin实现的。现在基于Electron官方demo进行集成

# 1.添加依赖
npm i -g mirror-config-china --registry=https://registry.npm.taobao.org # 安装相关镜像。包含了 npm config set ELECTRON_MIRROR https://npm.taobao.org/mirrors/electron/ # 打包时会下载electron压缩包，此时设置镜像进行加速
npm install electron -S
npm install electron-builder -D # node 8.x 需要安装 20.44.4以下版本

# 参考上文简单使用下载electron-quick-start项目
# 2.把electron-quick-start项目中的main.js和preload.js（老的示例可能没有）复制到vue的public文件中(vue打包的模板目录)，并将main.js重命名为index.js（最终会打包到./dist/index.js，即electron的入口文件）
# 修改public/index.js(上文electron-quick-start/main.js)中的 `mainWindow.loadFile('index.html')` 为 `mainWindow.loadURL('file://' + __dirname + '/index.html')`

# 3.package.json文件（包括自定义的 electron-build.js）增加如下文代码

# 4.vue-cli3时，修改vue.config.js的 `publicPath: './'`，如果是vue-cli2或webpack打包的修改对应的 `assetsPublicPath: './'`
# 改完之后通过vue server启动，在浏览器里面访问可能有问题，因此可以通过环境变量文件动态设置publicPath
# 原来一般为 /，是通过url访问的（一般情况使用 ./ 亦可访问），此时需要修改为相对路径，是基于目录访问的
# 如果改错了很容易出现白屏情况，可在public/index.js(electron的main.js)文件中打开`mainWindow.webContents.openDevTools()`，从而窗口可以显示出chrome dev tools进行调试
module.exports.publicPath: process.env.VUE_APP_PUBLIC_PATH ? process.env.VUE_APP_PUBLIC_PATH : '/'

# 5.如果使用vue-router，需要使用hash模式，如果使用history模式容易出现跳转页面失败情况

npm run e_dev # 运行
npm run e_prod # 打包，会生成 xxx-win32-x64 文件夹
```
- package.json配置文件

```json
{
  "scripts": {
        "dev": "vue-cli-service serve --mode dev",
        "test": "vue-cli-service build --mode test",
        "build": "vue-cli-service build --mode prod",
        // 启动 electron 开发环境，会弹出一个 electron 客户端
        "e_dev": "vue-cli-service build --mode electron_dev && electron dist/index.js",
        // 打包 electron 测试环境，electron-build.js 打包脚本见下文
        "e_test": "node ./electron-build.js electron_test",
        "e_test_hot": "node ./electron-build.js electron_test hot",
        // 打包 64位
        "e_test_x64": "vue-cli-service build --mode electron_test && electron-builder --dir",
        "e_test_x32": "vue-cli-service build --mode electron_test && electron-builder --dir --ia32",
        // 打包 electron 生产环境
        "e_prod": "node ./electron-build.js electron_prod",
        "e_prod_x64": "vue-cli-service build --mode electron_prod && electron-builder",
        "e_prod_x32": "vue-cli-service build --mode electron_prod && electron-builder --ia32"
    },
    // electron 入口函数。对应 public/index.js 文件
    "main": "./dist/index.js",
    // electron-builder配置
    "build": {
        // 项目名，这也是生成的exe文件的前缀名
        "productName": "ShengQi",
        "appId": "cn.aezo.test",
        "copyright": "ShengQi",
        // 需要打包的文件，即 vue 打包出来的文件
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
<details>
<summary>electron-build.js 打包文件</summary>

```js
var exec = require('child_process').exec;
var fs = require('fs');
var path = require('path');
const pkg = require('./package.json')

var args = process.argv.splice(2)
if (!args || args.length === 0) {
  args[0] = 'electron_test'
}
var hot = null
if(args.length == 2) {
  hot = args[1]
}

const runExec = function (cmd) {
  return new Promise(function (resolve, reject) {
    // 设置maxBuffer(默认1024 * 1024字节)，防止报错Error: stderr maxBuffer exceeded
    exec(cmd, { maxBuffer: 1024 * 1024 * 10 }, function (error, stdout, stderr) {
      if (error) {
        console.error('error: ' + error);
        reject('error: ' + error);
        return;
      }
      console.log('stdout: ' + stdout);
      console.log('stderr: ' + typeof stderr);
      resolve();
    });
  })
}

const moveFile = function (sourceFile, destFile, parentDir) {
  return new Promise(function (resolve, reject) {
    if(!parentDir) parentDir = ''
    var sourcePath = path.join(__dirname, parentDir, sourceFile);
    var destPath = path.join(__dirname, parentDir, destFile);
    let file_exists = fs.existsSync(sourcePath);
    if (file_exists) {
      fs.rename(sourcePath, destPath, function (error) {
        if (error) {
          reject('error: ' + error);
        }
        resolve();
      });
    } else {
      console.warn('no such file or directory: ' + sourcePath);
      resolve();
    }
  })
}

const mkdirSync = function (dirname) {
  if (fs.existsSync(dirname)) {
    return true;
  } else {
    if (mkdirSync(path.dirname(dirname))) {
      fs.mkdirSync(dirname);
      return true;
    }
  }
}

const deleteFiles = function (folderPath) {
  return new Promise(function (resolve, reject) {
    try {
      var abs_path = path.join(__dirname, folderPath);
      let forlder_exists = fs.existsSync(abs_path);
      if (forlder_exists) {
        let fileList = fs.readdirSync(abs_path);
        fileList.forEach(function (fileName) {
          fs.unlinkSync(path.join(abs_path, fileName));
        });
      } else {
        mkdirSync(folderPath)
      }
      resolve();
    } catch (e) {
      reject('error: ' + e);
    }
  })
}

async function run () {
  await runExec('vue-cli-service build --mode ' + args[0])

  if (args[0] === 'electron_test') {
    await moveFile('default.test.json', 'default.json', 'dist/config/')
  } else if (args[0] === 'electron_prod') {
    await moveFile('default.prod.json', 'default.json', 'dist/config/')
  }

  // 生成64位安装包
  await runExec('electron-builder')
  await deleteFiles('electron-out/release/win32_x64')
  // --dir生成的测试程序不会打包
  if (args[0] === 'electron_prod') {
    await moveFile('latest.yml', 'release/win32_x64/latest.yml', 'electron-out/')
    const name = `${pkg.build.productName} Setup ${pkg.version}.exe`
    await moveFile(name, `release/win32_x64/${name}`, 'electron-out/')
  }

  // 生成32位安装包
  await runExec('electron-builder --ia32')
  await deleteFiles('electron-out/release/win32_x32')
  if (args[0] === 'electron_prod') {
    await moveFile('latest.yml', 'release/win32_x32/latest.yml', 'electron-out/')
    const name = `${pkg.build.productName} Setup ${pkg.version}.exe`
    await moveFile(name, `release/win32_x32/${name}`, 'electron-out/')
  }
}

async function run_hot () {
  await runExec('vue-cli-service build --mode ' + args[0])

  if (args[0] === 'electron_test') {
    await moveFile('default.test.json', 'default.json', 'dist/config/')
  } else if (args[0] === 'electron_prod') {
    await moveFile('default.prod.json', 'default.json', 'dist/config/')
  }

  // 生成 asar
  await runExec('asar p ./dist app.asar')
  await deleteFiles('electron-out/release/asar')
  await moveFile('app.asar', 'electron-out/release/asar/app.asar', './')
  fs.copyFile('package.json', 'electron-out/release/asar/package.json', function(err) {
    if(err) console.error('复制文件失败')
  })
}

!hot ? run() : run_hot()
```
</details>

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
            # 如果是electron-builder打包，app目录被打包成了 app.asar，可通过asar命令解压查看
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
- **启动过程说明**
    - 点击可执行文件 ShengQi.exe 
    - 从 resources/app/package.json 文件中获取入口文件
    - 如 package.json 定义属性：`"main": "my_dir/my_index.js"`，那么入口文件则是此处指定的，如果没有指定main属性，则入口文件为package.json同目录下的index.js文件
    - 无package.json文件，则点击 ShengQi.exe 无任何反应
    - 而index.js中通过`mainWindow.loadURL('file://' + __dirname + '/index.html')`引入vue打包生成的index.html文件（原public/index.html文件），从而启动了vue应用

#### 常见问题

- 报错：`Unresolved node modules: vue`。解决：此问题为cnpm安装依赖导致，**需要使用npm安装**，然后配合mirror-config-china进行安装 [^1]
- [centos上打包说明](https://www.electron.build/multi-platform-build#linux)
    - 需要安装 Wine，部分场景需要安装 Mono等
    - 获取通过提供的Docker镜像进行编译

### 自动更新

- 更新方式
    - 替换html文件更新，这个比较节约资源，但是并不适用于builder打包出来的程序
    - 替换asar文件，这个比较小众
    - **electron-builder + electron-updater 实现全量更新**(推荐) [^2]
    - 基于[autoUpdater](https://www.electronjs.org/docs/api/auto-updater)，借助 Squirrel 实现自动升级

#### electron-updater 实现全量更新

- 安装`npm i electron-updater -S`
- 安装`npm i config -S` 主要用于读取客户端配置文件，用于获取不同环境的更新链接。解决打包后区分测试和生产环境，预置配置到用户端 [^4]
- 使用 electron-updater 更新，只需要每次把打包好的文件(latest.yml和xxx.exe)复制到更新目录即可。**注意每次打包需要升级版本号**
- package.json增加publish配置

```json
{
    "build": {
        // 这个配置会生成在latest.yml文件(必须要配置publish，否则不生成latest.yml)，用于自动更新的配置信息(此处可省略，最终在js文件中配置)
        "publish": [{
            "provider": "generic", // 服务器提供商，也可以是GitHub等等
            "url": "" // 更新服务器地址，可为空，在代码中会再次设定
        }]
    }
}
```
- 创建 `public/config` 文件夹，并创建 `default.json`(如下)、`default.prod.json`

```json
{
  "System": {
    // 将安装包和latest.yml放在此路径的 win32_x32 和 win32_x64 目录下
    "updateUrl": "http://192.168.1.100/release_repo/dev"
  }
}
```
- 创建update.js

<details>
<summary>update.js文件</summary>

```js
const autoUpdater = require('electron-updater').autoUpdater
const { ipcMain, dialog } = require('electron')
let log = require('electron-log') // 日志插件，可在命令行或客户端日志文件中查看项目运行日志

const config = require('config');
const updateUrl = config.get('System.updateUrl');

log.info('process.argv: ' + process.argv)
// const updateUrl = 'http://127.0.0.1:800'
// const feedUrl = `${updateUrl}/${process.platform + '_' + process.arch}` // 基于不同系统架构进行下载
const feedUrl = `${updateUrl}`
log.info('feedUrl: ' + feedUrl)

let yesManualFlag = false
const checkVersion = function (yesManual) {
    yesManualFlag = yesManual
    autoUpdater.checkForUpdates()
}

let mainWindow
const updateHandle = function (mw) {
    mainWindow = mw
    let message = {
        error: '检查更新出错',
        checking: '正在检查更新......',
        updateAva: '检测到新版本，正在下载......',
        updateNotAva: '现在使用的就是最新版本，不用更新',
    };

    autoUpdater.setFeedURL(feedUrl);
    autoUpdater.on('error', function (error) {
        log.error('error...')
        log.error(error)
        sendUpdateMessage(message.error)
    });
    autoUpdater.on('checking-for-update', function () {
        log.info('checking-for-update...')
        sendUpdateMessage(message.checking)
    });
    autoUpdater.on('update-available', function (info) {
        // 有可更新版本
        log.info('update-available...')
        sendUpdateMessage(message.updateAva)
    });
    autoUpdater.on('update-not-available', function (info) {
        // 无可更新版本
        log.info('update-not-available...')
        sendUpdateMessage(message.updateNotAva)
        if(yesManualFlag) {
            dialog.showMessageBox(mainWindow, {
                type: 'info',
                title: '提示',
                buttons: ['确定'],
                message: '当前已是最新版本'
            })
        }
    });

    // 更新下载进度事件
    autoUpdater.on('download-progress', function (progressObj) {
        log.info('download-progress...')
        log.info(progressObj)
        mainWindow.webContents.send('downloadProgress', progressObj)
    })
    autoUpdater.on('update-downloaded', function (event, releaseNotes, releaseName, releaseDate, updateUrl, quitAndUpdate) {
        // 下载最新安装包完成
        log.info('update-downloaded...')
        // 通知渲染进程并监听其回复，从而判断是否需要立即更新
        ipcMain.on('isUpdateNow', (e, arg) => {
            // 执行新版本安装
            log.info("isUpdateNow...");
            autoUpdater.quitAndInstall();
        })
        mainWindow.webContents.send('isUpdateNow')
        
        // 弹出系统提示框（如果使用上述web弹框，和渲染进程交互则可省略此处），取消则是退出程序时更新
        dialog.showMessageBox(mainWindow, {
            type: 'info',
            title: '确认',
            buttons: ['确定', '取消'],
            message: '有新版本，请问是否进行更新？'
        }).then((response) => {
            // { response: 0, checkboxChecked: false }
            log.info(response)
            if(response.response == 0) {
                log.info("isUpdateNow...");
                autoUpdater.quitAndInstall();
            }
        })
    });

    ipcMain.on("checkForUpdate", () => {
        //执行自动更新检查
        autoUpdater.checkForUpdates();
    })
}

// 通过main进程发送事件给renderer进程，提示更新信息
function sendUpdateMessage (text) {
    mainWindow.webContents.send('message', text)
}

exports.updateHandle = updateHandle
exports.checkVersion = checkVersion
```
</details>

- 修改 public/index.js 项目入口文件，部分代码如下

```js
// 修改config查看的配置文件目录
process.env["NODE_CONFIG_DIR"] = __dirname + "/config/";

require('./application-menu') // 菜单栏。可在此文件中导入 update.js，进行手动更新，此处略
require('./context-menu') // 页面右键菜单，略
const { updateHandle, checkVersion } = require('./update')

let mainWindow;
function createWindow () {
    mainWindow = new BrowserWindow({
        width: 1280,
        height: 960,
        webPreferences: {
            nodeIntegration: false,
            preload: path.join(__dirname, 'preload.js')
        }
    })

    mainWindow.loadURL('file://' + __dirname + '/index.html')

    // 自动打开 DevTools 工具
    // mainWindow.webContents.openDevTools()

    mainWindow.webContents.on('did-finish-load', () => {
        checkVersion(false)
    })
}

app.whenReady().then(() => {
    createWindow()

    // 更新
    updateHandle(mainWindow)

    app.on('activate', function () {
        if (BrowserWindow.getAllWindows().length === 0) createWindow()
    })
})
```
- 渲染进程显示更新进度

<details>
<summary>electron-update.vue文件</summary>

```html
<!-- electron-update.vue，将其引入到 Main.vue中 -->
<template>
  <div v-if="show" style="width: 400px;margin: 0 auto;">
    <Progress :percent="downloadPercent" :stroke-color="['#108ee9', '#87d068']">更新中...</Progress>
  </div>
</template>

<script>
import isElectron from 'is-electron';

export default {
  name: 'ElectronUpdate',
  data () {
    return {
      show: false,
      downloadPercent: 0,
      tips: ''
    }
  },
  created () {
    this.init()
  },
  beforeDestroy () {
    // ipcRenderer.removeAll(["message", "downloadProgress", "isUpdateNow"])
    ipcRenderer.remove("message")
    ipcRenderer.remove("downloadProgress")
    ipcRenderer.remove("isUpdateNow")
  },
  methods: {
    init () {
      if (isElectron()) {
        this.ipcRendererOn()
        console.log(ipcRenderer.removeAll)
      }

      this.fetchData()
    },
    fetchData () {
    },
    ipcRendererOn () {
      ipcRenderer.on("message", (event, text) => {
        console.log(text);
        this.tips = text;
      })
      //注意：downloadProgress 事件可能存在无法触发的问题，只需要限制一下下载网速就可进行测试了
      ipcRenderer.on("downloadProgress", (event, progressObj) => {
        console.log(progressObj);
        this.show = true
        this.downloadPercent = progressObj.percent || 0;
      })
      ipcRenderer.on("isUpdateNow", () => {
        ipcRenderer.send("isUpdateNow");
      })
    }
  }
}
</script>

<style lang="less" scoped>
</style>
```
</details>

### 基于 electron-packager 插件打包(不推荐)

```bash
npm install electron-packager -S # 这个是打成exe文件的插件。如果是node v8.x可使用版本v14.2.1，而v15.x需要node v10.x。还可使用electron-builder进行打包

# 1.package.json文件增加如下脚本代码。配置只能通过命令参数完成，没有builder灵活
"scripts": {
    "electron_dev": "npm run build && electron dist/index.js",
    "electron_test": "vue-cli-service build --mode test && electron-packager ./dist/ --arch=x64 --overwrite"
}

# 2.运行项目
npm run electron_dev

# 3.打包
# 3.1 在 public 目录创建文件 package.json，并写入 `{}`，因此public/index.js即为入口文件，而index.js中通过`mainWindow.loadFile('index.html')`引入vue打包生成的index.html文件（原public/index.html文件），从而启动了vue应用
# 3.2 执行打包
npm run electron_build # 打包，会生成 xxx-win32-x64 文件夹

# 4.通过Inno Setup将文件再次打包成安装包后分发给客户，如皋使用electron-builder则自带打包成安装包
```

### 常见问题

- 通过访问链接下载Excel，不能自动打开。可考虑调用命令打开文件

```js
// public/index.js
const { app, BrowserWindow, ipcMain } = require('electron');
const child_process = require('child_process');

app.setPath('downloads', 'C:/mytmp/'); // 可以找到系统的临时目录
child_process.exec('mkdir mytmp', {cwd: 'C:/'}); // 创建临时目录

app.whenReady().then(() => {
    // 监听 electron 提供的 will-download 事件
    mainWindow.webContents.session.on('will-download', (event, item, webContents) => {
        // event.preventDefault(); // 阻止调用系统的默认下载，之后调用自己的下载函数，如实现断点下载

        // 保存文件到指定目录并执行start打开命令
        const filePath = path.join(app.getPath('downloads'), item.getFilename());
        item.setSavePath(filePath);
        child_process.exec('start ' + filePath);
    });
})
```

## electron-vue

## 常用插件

### electron-log日志插件

- `npm install electron-log -S` 安装 [^3]
- 使用

```js
import log from 'electron-log';

```
- 日志文件位置，参考：https://www.npmjs.com/package/electron-log
    - on Windows: `%USERPROFILE%\AppData\Roaming\{app name}\logs\{process type}.log`

### electron-store本地存储文件

- window.localStorage 仅在浏览器进程（渲染进程）中起作用，错误退出可能丢数据 [^5]
- vuex存储在内存，localstorage则以文件的方式存储在本地，electron-store数据存储卸载应用之后依然存在
    - 应用场景：vuex用于组件之间的传值，localstorage则主要用于不同页面之间的传值
    - 永久性：当刷新页面时vuex存储的值会丢失，localstorage不会

## 常见问题

- TypeError: fs.existsSync is not a function | import { ipcRenderer } from 'electron'
    - https://blog.csdn.net/weixin_41217541/article/details/106496186 无效
    - https://blog.csdn.net/qq_38333496/article/details/102474532 **方案二成功**






---

参考文章

[^1]: https://blog.csdn.net/g_soledad/article/details/105053322
[^2]: https://segmentfault.com/a/1190000012904543
[^3]: https://blog.csdn.net/qq_32596527/article/details/106415532
[^4]: https://www.thinbug.com/q/40146701
[^5]: https://xushanxiang.com/2019/12/electron-store.html
