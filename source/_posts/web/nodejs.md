---
layout: "post"
title: "Nodejs"
date: "2020-04-19 01:18"
categories: lang
tags: [nodejs]
---

## 安装使用

### 安装

- [nodejs官网](https://nodejs.org/zh-cn/)
- 多版本管理参考: [nvm Node版本管理工具](/_posts/web/node-dev-tools.md#nvm-node版本管理工具)
- centos

```bash
wget https://npm.taobao.org/mirrors/node/v10.23.0/node-v10.23.0-linux-x64.tar.gz
tar -zxvf node-v10.23.0-linux-x64.tar.gz -C /opt
ln -s /opt/node-v10.23.0-linux-x64/bin/node /usr/local/bin/
ln -s /opt/node-v10.23.0-linux-x64/bin/npm /usr/local/bin/
ln -s /opt/node-v10.23.0-linux-x64/bin/npx /usr/local/bin/
chown -R root:root /opt/node-v10.23.0-linux-x64 # 文件夹权限默认是500:500
node -v

# 提供node、npm可通过sudo执行
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/node /usr/bin/node
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/node /usr/lib/node
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/npm /usr/bin/npm
sudo ln -s /opt/node-v10.23.0-linux-x64/bin/node-waf /usr/bin/node-waf
```

## package.json

```json
{
    // 模块名称，如果name以@xxx/开头则其中xxx为scope，如@sqbiz/test
    "name": "test",
    // 此项目版本
    // NPM版本规范参考[版本命名规范](/_posts/others/tech-conception.md#项目管理)
    // 通过npm自动递增版本参考[基于package.json说明](/_posts/web/node-dev-tools.md#npm-包管理工具)
    "version": "1.0.0",
    // 如果导出了多个模块，可以在引入的时候写全路径，如`import ReportTable from 'report-table'`引入默认模块，而通过类似`import ReportTableDemo from 'report-table/lib-demo/report-table-demo.umd.min.js`引入另外一个模块
    "main": "./lib/report-table.umd.min.js",

    // 依赖和对应版本
    "dependencies": {
        // 波浪符号（~）：固定大、中版本，只升级小版本到最新版本
        "vue": "~2.5.13",
        // 插入符号（^）：固定大版本，升级中、小版本到最新版本。当前npm安装包默认符号
        "iview": "^2.8.0",
    },
    // 开发环境依赖, 不会编译到最终产物
    "devDependencies": {},
    // peerDependencies 类似maven的provider。目的是提示宿主环境去安装满足插件peerDependencies所指定依赖的包，然后在插件import或者require所依赖的包的时候，永远都是引用宿主环境统一安装的npm包，最终解决插件与所依赖包不一致的问题
    // A 依赖 B 包，当 B 的 peerDependency 中包含 C 时，C就不会被自动安装
    // 此时 A 必须将对应的依赖项 C 包含为其依赖；否则安装时会警告(运行时会报醋)，且 A 要安装符合对应版本的 C；在开发 B 的时候可以将 C 添加到 devDependencies 中，之后 A 将 C 设置成依赖即可
    // 一般加入引用方一定会依赖的包，如果不常用的包加到此处，则引用方安装较麻烦(全部写到dependencies只是安装时可能和其他模块重复安装，导致效率差点)
    "peerDependencies": {
        "vue": "^2.6.12"
    },

    // Vue相关参考[vue.md#vue-cli-service](/_posts/web/vue.md#vue-cli-service)
    // 打包Vue插件相关参考[vue.md#开发组件库](/_posts/web/vue.md#开发组件库)
    "script": {
        // 钩子: npm 脚本有pre和post两个钩子
        // 用户执行npm run build的时候, 相当于执行 npm run prebuild && npm run build && npm run postbuild
        // process.env.npm_lifecycle_event 可获取当前运行的脚本名称
        "prebuild": "echo I run before the build script",
        "build": "cross-env NODE_ENV=production webpack",
        "postbuild": "echo I run after the build script",

        // 变量
        // 通过`npm_package_`前缀，npm 脚本可以拿到package.json里面的字段。如: npm_package_scripts_prebuild 可以拿到上文属性值
        // 通过`npm_config_`前缀，拿到 npm 的配置变量，即`npm config get xxx`命令返回的值。注意，package.json里面的config对象，可以被环境变量覆盖
        "view": "echo $npm_config_tag",
        // `env`命令可以列出所有环境变量

        // [vue常用配置参考](/_posts/web/vue.md#vue-cli)
        "dev": "vue-cli-service serve",
        // 基于cross-env插件设置环境变量
        "cross-env": "cross-env API_URL=http://192.168.17.50:8050/ffs-crm/crm",
        // 基于webpack启动服务
        "dev-webpack": "webpack-dev-server --content-base ./ --open --inline --hot --compress --config build/webpack.dev.config.js --port 7710",
    },

    // 私有项目，防止发布到NPM仓库中
    "private": true,
    // 如果是scope类型模块(name以@xxx/开头)，则npm默认为发布私有包，如果需要发布成公开则需要定义下面配置
    "publishConfig": {
        "access": "public"
    },
    // 当上传NPM仓库时，允许上传的文件夹
    "files": [
        "lib",
        "types"
    ],
    // typescript类型文件入口
    "typings": "types/index.d.ts",
}
```

## 常用依赖包

### PM2

- PM2是node进程管理工具，可以利用它来简化很多node应用管理的繁琐任务，如性能监控、自动重启、负载均衡等，而且使用非常简单
- 使用

```bash
# 全局安装
npm install -g pm2

pm2 -h # 查看帮助
pm2 l # 列举所有进程
```

## 零散

### 获取命令行参数

```bash
node arg.js arg1 arg2 arg3 # 执行命令
#  process是一个全局对象，argv返回的是一组包含命令行参数的数组
process.argv # ["D:\\software\\nodejs\\node.exe", "D:\\test\\arg.js", "arg1", "arg2", "arg3"]
var args = process.argv.splice(2) # ["arg1", "arg2", "arg3"]
```
