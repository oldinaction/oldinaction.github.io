---
layout: "post"
title: "css"
date: "2018-08-22 15:13"
categories: web
tags: [css]
---

## 简介

- 参考：[MDN CSS 参考](https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference)

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

### 文字省略

```css
/* 单行缩略（部分浏览器需要设置宽度） */
span {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* 多行省略 */
p {
    overflow : hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2; /* 对2行文字进行省略 */
    -webkit-box-orient: vertical;
}
```

### 滚动条样式

- 样例参考：http://www.xuanfengge.com/demo/201311/scroll/css3-scroll.html [^1]

```css
::-webkit-scrollbar {
    width: 12px;
}
::-webkit-scrollbar-thumb {
    border-radius: 10px;
    background-color: #D62929; /* 滚动条颜色 */
}
::-webkit-scrollbar-track {
    border-radius: 10px;
}
```

## 色彩

- 渐变色

```css
div {
    /* 渐变轴为45度，从蓝色渐变到红色 */
    background: linear-gradient(45deg, blue, red);

    /* 从右下到左上、从蓝色渐变到红色 */
    background: linear-gradient(to left top, blue, red);

    /* 从下到上，从蓝色开始渐变、到高度40%位置是绿色渐变开始、最后以红色结束 */
    background: linear-gradient(0deg, blue, green 40%, red);
    background: -webkit-linear-gradient(0deg, rgb(251, 176, 30), rgb(229, 2, 18), rgb(192, 6, 156));
}
```




---

[^1]: https://segmentfault.com/a/1190000012800450

