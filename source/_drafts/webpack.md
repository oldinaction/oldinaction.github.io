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

基于cross-env进行安装

- `npm i cross-env -D` 安装cross-env插件
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






