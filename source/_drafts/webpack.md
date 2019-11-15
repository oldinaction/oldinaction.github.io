---
layout: "post"
title: "webpack"
date: "2019-05-29 18:07"
categories: web
tags: [webpack, node]
---

## 简介

## 设置

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





