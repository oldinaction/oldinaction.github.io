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

### index.html

- 变量替换

```html
<link rel="icon" href="<%= BASE_URL %>favicon.ico">

<% if(VUE_APP_DEBUG_AVUE_URL) { %>
    <script src="<%= BASE_URL %>avue.js" charset="utf-8"></script>
<% } else { %>
    <script src="<%= BASE_URL %>cdn/avue/2.7.3/avue.min.js" charset="utf-8"></script>
<% } %>

<% for(var k in htmlWebpackPlugin.files.chunks) { %>
    <% if(k !== 'main'){ %>
        <script type="text/javascript" src="<%= htmlWebpackPlugin.files.chunks[k].entry %>"></script>
    <% } %>
<% } %>
```

## Webpack模块打包原理

- 模块规范：[^2]


## Webpack转译Typescript现有方案

- 参考[web.md#Webpack转译Typescript现有方案](/_posts/web/web.md#Webpack转译Typescript现有方案)






---

参考文章

[^2]: https://lq782655835.github.io/blogs/project/webpack4-1.module.html


