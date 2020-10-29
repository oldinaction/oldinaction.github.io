---
layout: "post"
title: "webpack"
date: "2019-05-29 18:07"
categories: web
tags: [webpack, node]
---

## 简介

## 设置

### 外网访问

```json
// --host 0.0.0.0 指定开发的ip
// --disableHostCheck true 指定不检查Host，否则容易出现`Invalid Host header`(也可以使用--public)解决
"scripts": {
    "dev": "webpack-dev-server --content-base ./ --open --inline --hot --compress --config build/webpack.dev.config.js --disableHostCheck true --host 0.0.0.0 --port 7710",
},
```

### 环境变量

- 基于cross-env进行操作：`npm i cross-env -D` 安装cross-env插件
- package.json

```json
"scripts": {
    "cross-env": "cross-env API_URL=http://192.168.17.50:8050/ffs-crm/crm",
    "dev": "webpack-dev-server --content-base ./ --open --inline --hot --compress --config build/webpack.dev.config.js --port 7710",
},
```
- webpack.dev.config.js

```js
plugins: [  
    new webpack.DefinePlugin({
        'process.env': {
            API_URL: JSON.stringify(process.env.API_URL)
        }
    })
]
```
- 其他js文件中使用`process.env.API_URL`即可
- 启动时可以覆盖此参数`npm run cross-env API_URL=http://localhost:8050/ffs-crm/crm npm run dev`

### 配置API代理解决跨域问题

- 一般配置在`build/webpack.dev.conf.js`文件中，也可直接在`config/index.js`中的`dev.proxyTable`中修改

```js
// 参考：https://github.com/chimurai/http-proxy-middleware
module.exports = {
  //...
  devServer: {
    proxy: {
      '/api': {
        target: 'http://www.baidu.com', // 代理的API地址
        pathRewrite: {'^/api' : ''},
        changeOrigin: true, // target是域名的话，需要这个参数
        secure: false, // 设置支持https协议的代理
      },
      '/api2': {
          .....
      }
    }
  }
};
```

## Webpack 模块打包原理

- 模块规范：[^2]


## Webpack 转译 Typescript 现有方案

- awesome-typescript-loader（停止更新）[^1]
- ts-loader + babel-loader + fork-ts-checker-webpack-plugin
    - 当 webpack 编译的时候，ts-loader 会调用 typescript（所以本地项目需要安装 typescript），然后 typescript 运行的时候会去读取本地的 tsconfig.json 文件。
    - 默认情况下，ts-loader 会进行 转译 和 类型检查，每当文件改动时，都会重新去 转译 和 类型检查，当文件很多的时候，就会特别慢，影响开发速度。所以需要使用 fork-ts-checker-webpack-plugin ，开辟一个单独的线程去执行类型检查的任务，这样就不会影响 webpack 重新编译的速度
    - 并行构建不再适合新版本的 webpack 了
        - 并行化构建有两种方式： happypack 和 thread-loader
        - 并行化构建对于 webpack 2/3 的性能有明显的提升，使用 webpack 4+时，速度提升的收益似乎要少得多
- babel-loader + @babel/preset-typescript
    - 当 webpack 编译的时候，babel-loader 会读取 .babelrc 里的配置，不会调用 typescript（所以本地项目无需安装 typescript），不会去检查类型。但是 tsconfig.json 是需要配置的，因为需要在开发代码时，让 idea 提示错误信息
- 问题说明
    - 使用了 TypeScript，为什么还需要 Babel
        - 大部分已存项目依赖了 babel，有些需求/功能需要 babel 的插件去实现（如：按需加载）
        - babel 有非常丰富的插件，它的生态发展得很好；babel 7 之前，需要前面两种方案来转译 TS；babel 7 之后，babel 直接移除 TS，转为 JS，这使得它的编译速度飞快
    - 为什么用了 ts-loader 后，还要使用 babel-loader
        - ts-loader 是不会读取 .babelrc 里的配置，即无法使用 babel 系列的插件，所以直接使用 ts-loader 将 ts/tsx 转成 js ，就会出现垫片无法按需加载、antd 无法按需引入的问题。所以需要用 ts-loader 把 ts/tsx 转成 js/jsx，然后再用 babel-loader 去调用 babel 系列插件，编译成最终的 js
    - 如果在使用 babel-loader + @babel/preset-typescript 这种方案时，也想要类型检查
        - 再开一个 npm 脚本自动检查类型：`"type-check": "tsc --watch"`，tsconfig.json中配置compilerOptions.noEmit=true
    - 使用 @babel/preset-typescript 需要注意有四种语法在 babel 中是无法编译的
        - namespace（已过世）
        - 类型断言：`let p1 = {age: 18} as Person;`
        - 常量枚举：`const enum Sex {man, woman}`
        - 历史遗留风格的 import/export 语法：`import xxx= require(…) 和 export = xxx`
    - Typescript 官方转向 ESLint 的原因
        - TSLint 执行规则的方式存在一些架构问题，从而影响了性能，而修复这些问题会破坏现有规则；
        - ESLint 的性能更好并且使用者较多
    - 使用了 TypeScript，为什么还需要 ESLint
        - TS 主要是用来做类型检查和语言转换的，顺带一小部分的语法检查
        - ESLint 主要是用来检查代码风格和语法错误的







---

参考文章

[^1]: https://juejin.im/post/6844904052094926855#heading-0 (Webpack 转译 Typescript 现有方案)
[^2]: https://lq782655835.github.io/blogs/project/webpack4-1.module.html


