---
layout: "post"
title: "css"
date: "2018-08-22 15:13"
categories: web
tags: [css]
---

## 简介

- [MDN CSS 参考](https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference)

## CSS 知识点

## CSS3 知识点

- CSS3使用时一般带有私有前缀，对应关系如下
    - `-webkit-` 对应 `Safari and Chrome`
    - `-moz-` 对应 `Firefox`
    - `-o-` 对应 `Opera`
    - `-ms-` 对应 `Internet Explorer`

### display: box; 弹性盒子模型(Flexible Box Model)

> http://www.zhangxinxu.com/wordpress/?p=1338

- 作用于父元素上
    - `display: box;` 只有父元素声明了使用box模型，子元素才能使用box-flex属性
    - `box-orient` 用来确定子元素的方向，是横着排还是竖着排。horizontal | inline-axis | inherit：横排；vertical | block-axis：竖排
    - `box-direction` 用来确定子元素的排列顺序。normal | inherit：普通；reverse：反转(原本dom应该从左到右是1-2-3的，此时结果显示为3-2-1)
    - `box-align` 用来决定盒子垂直方向上的空间利用(同vertical-align一起记忆)。start(垂直方式则是向顶部对齐) | end | center | baseline(基线对齐，文字底边线) | stretch(默认值，拉伸)
    - `box-pack` 用来决定盒子水平方向上的空间利用。start(水平方向则是向左对齐) | end | center | justify(两端对齐)
    - `box-lines` 貌似暂不支持
    - `box-flex-group` 貌似暂不支持
    - `box-ordinal-group` 定义一个数字级别的，决定了显示位置，越小显示越靠前。也可基于此属性实现 box-direction: reverse 的效果
- 作用于子元素上
    - `box-flex: 2;` 子元素占用宽度比例，此时只占用2份。如果其他子元素有定义width、margin值，则优先分配width、margin宽度
- 示例

```less
/* 只有父元素声明了使用box模型，子元素才能使用 box-flex 属性 */
.father { 
    display: box;
    display: -webkit-box; /* 支持其他浏览器也可以依次加上 */
    
    .child-a {
        box-flex: 1;
        -webkit-box-flex: 1;
        box-ordinal-group: 2; /* child-a 类型的元素将显示在 child-b 类型元素后面 */
        -webkit-box-ordinal-group: 2;
    }
    .child-b {
        box-flex: 1;
        -webkit-box-flex: 1;
        box-ordinal-group: 1;
        -webkit-box-ordinal-group: 1;
    }
}
```

### display: flex; Flex布局

https://www.zhangxinxu.com/wordpress/?p=8063
https://www.cnblogs.com/qingchunshiguang/p/8011103.html


- 作用在flex容器上
    - flex-direction
    - flex-wrap
    - flex-flow
    - `justify-content` 决定了水平方向子项的对齐和分布方式
        - 取值：flex-start | flex-end | center | space-between(两端对齐) | space-around | space-evenly
        - CSS的text-align有个属性值为justify，可实现两端对齐，可联合记忆
    - align-items
    - align-content
- 作用在flex子项上
    - order
    - flex-grow
    - flex-shrink
    - flex-basis
    - flex
    - align-self

## 常用css

- 响应式布局，head中加`<meta name="viewport" content="width=device-width,initialscale=1.0,maximum-scale=1.0,user-scalable=0">`
- 解决iPhone中 overflow:scroll; 滑动速度慢或者卡的问题：`-webkit-overflow-scrolling : touch;`

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
    display: inline-block;
    width: 100px;
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
    width: 6px; /* 针对纵向滚动条 */
    height: 8px; /* 针对横向滚动条 */
}
::-webkit-scrollbar-thumb {
    border-radius: 10px;
    background-color: #D62929; /* 滚动条颜色 */
}
::-webkit-scrollbar-track {
    border-radius: 10px;
}
```

### 渐变色

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

