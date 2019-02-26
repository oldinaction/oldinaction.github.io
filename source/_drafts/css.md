---
layout: "post"
title: "css"
date: "2018-08-22 15:13"
categories: web
tags: [css]
---

## 知识点

### flex布局

https://www.cnblogs.com/qingchunshiguang/p/8011103.html

## 常用css

- 响应式布局，head中加`<meta name="viewport" content="width=device-width,initialscale=1.0,maximum-scale=1.0,user-scalable=0">`
- 解决iPhone中overflow:scroll;滑动速度慢或者卡的问题：`-webkit-overflow-scrolling : touch;`

### 虚线

```css
/* 水平虚线 */
.split-x {
  display: inline-block;
  width: 85%;
  position: absolute;
  left: 15%;
  top: 10px;
  border-top: 1px dashed #cccccc;
  height: 1px;
  overflow: hidden;
}

/* 垂直虚线 */
.split-y {
    display: inline-block;
    position: absolute;
    top: 0;
    bottom: 80%; /* bottom: 0; */
    left: 50%;
    border: 1px dashed #eee;
}
```
