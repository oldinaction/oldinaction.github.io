---
layout: "post"
title: "css"
date: "2018-08-22 15:13"
categories: web
tags: [css]
---

## 简介

- [MDN CSS 参考](https://developer.mozilla.org/zh-CN/docs/Web/CSS/Reference)
- TODO
    - [12 个好用的 CSS 的开源项目](https://wuyaogexing.com/70/829272.html)

## CSS 知识点

### CSS3说明

- CSS3使用时一般带有私有前缀，对应关系如下
    - `-webkit-` 对应 `Safari and Chrome`
    - `-moz-` 对应 `Firefox`
    - `-o-` 对应 `Opera`
    - `-ms-` 对应 `Internet Explorer`

### BFC

- https://www.cnblogs.com/heimanba/p/3774086.html

### 字体

- 导出Excel使用`Arial Unicode MS`字体，打印出来较美观

### table样式

```css
/* 设置表格第一列无边框 */
table tbody tr td:first-child {border: none;}
/* 设置表格第三列无边框 */
table tbody tr td:first-child+td+td {border: none;}
```

## 响应式

### 弹性盒子模型(Flexible Box Model)

> http://www.zhangxinxu.com/wordpress/?p=1338

- `display: box;`
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

### Flex布局

- 参考
    - https://www.zhangxinxu.com/wordpress/?p=8063
    - https://www.cnblogs.com/qingchunshiguang/p/8011103.html
- `display: flex;` 开启flex布局
- 作用在flex容器上
    - flex-direction: row(默认从左到右)/column(默认从上到下)/row-reverse/column-reverse
    - flex-wrap
    - flex-flow
    - `justify-content` 决定了水平方向子项的对齐和分布方式
        - 取值：`flex-start` | `flex-end` | `center` | `space-between`(两端对齐) | `space-around` | `space-evenly`
        - CSS的text-align有个属性值为justify，可实现两端对齐，可联合记忆
    - `align-items` 决定了垂直方向子项的对齐和分布方式
        - 取值：`stretch`(类似于flex-start) | `flex-start`(顶部对齐) | `flex-end`(底部对齐) | `center` | `baseline`(类似于flex-end)
    - align-content
- 作用在flex子项上
    - order 改变某一个flex子项的排序位置
    - flex-grow 扩展比例：默认值是0，表示不占用剩余的空白间隙；0-1表示占据的百分比(大于等于1表示全部占据)；如果多个子元素设置了此属性则其和表示占据空隙的比例，然后按照各自的比例进行分配占据的空隙
    - flex-shrink 收缩比例：主要处理当flex容器空间不足时候，单个元素的收缩比例；类似grow，0-1表示收缩比例(大于等于1表示收缩完全，正好填满flex容器)
    - flex-basis 定义了在分配剩余空间之前元素的默认大小，默认是auto，其值可以是像素或百分比
    - flex: flex-grow flex-shrink flex-basis 的组合；`flex: 1;`等价于`flex: 1 1 0%;`
    - align-self

### @media

- 用`min-width`时，小的放上面大的在下面，同理如果是用`max-width`那么就是大的在上面

```css
@media (min-width: 768px) {
    /* >=768的设备 */
    body { font-size: 12px; }
}
@media (min-width: 992px) { /* >=992的设备 */ }
@media (min-width: 1200) { /* >=1200的设备 */ }

@media (max-width: 1199) { /* <=1200的设备 */ }
@media (max-width: 991px) { /* <=992的设备 */ }
@media (max-width: 767px) { /* <=768的设备 */ }
```

### cacl计算

- 需要注意的是，运算符前后都需要保留一个空格
- 支持+、-、*、/

```css
.box {
    width: calc(100% - 10px);
    height: calc(100vh - 120px); /* 高度用可视高度，而不能用 100% */
}
```

### vm/rpx/rem

- https://www.cnblogs.com/tu-0718/p/10826846.html
- https://imgcook.taobao.org/docs?slug=rem-adapter

## SVG

- [SVG文档](https://developer.mozilla.org/zh-CN/docs/Web/SVG)
- loading图片案例(最终是一个灰色的圆环加载图片)

```xml
<!-- svg根节点
    viewBox: 定义了画布上可以显示的区域(0,0坐标在左上角，X轴向右，Y轴向下)
    width/height: 画布的整体宽高
    fill: 颜色 
-->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32" fill="#646568">
    <!-- path路径 
        d: 
            M = moveto(M X,Y) ：将画笔移动到指定的坐标位置
            L = lineto(L X,Y) ：画直线到指定的坐标位置
            H = horizontal lineto(H X)：画水平线到指定的X坐标位置
            V = vertical lineto(V Y)：画垂直线到指定的Y坐标位置
            C = curveto(C X1,Y1,X2,Y2,ENDX,ENDY)：三次贝赛曲线
            S = smooth curveto(S X2,Y2,ENDX,ENDY)：平滑曲率
            Q = quadratic Belzier curve(Q X,Y,ENDX,ENDY)：二次贝赛曲线
            T = smooth quadratic Belzier curveto(T ENDX,ENDY)：映射
            A = elliptical Arc(A RX,RY,XROTATION,FLAG1,FLAG2,X,Y)：弧线
            Z = closepath()：关闭路径
    -->
    <path opacity=".25" d="M16 0 A16 16 0 0 0 16 32 A16 16 0 0 0 16 0 M16 4 A12 12 0 0 1 16 28 A12 12 0 0 1 16 4"/>
    <path d="M16 0 A16 16 0 0 1 32 16 L28 16 A12 12 0 0 0 16 4z">
        <animateTransform attributeName="transform" type="rotate" from="0 16 16" to="360 16 16" dur="0.8s" repeatCount="indefinite" />
    </path>
</svg>
```

## 常用CSS

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

### 文字省略/换行/缩放

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

/* 自动换行 */
span {
    word-wrap: break-word;
}

/* 缩放 */
span {
    font-size: 12px; /* 谷歌浏览器最小字体 */
    transform: scale(0.75); /*缩小字体*/
}
```

### 滚动条样式

- 样例参考：http://www.xuanfengge.com/demo/201311/scroll/css3-scroll.html [^1]

```css
.box::-webkit-scrollbar {
    /* 单独修改此div的滚动条 */
}

/* 如果只定义::-webkit-scrollbar-thumb和::-webkit-scrollbar-track，而不定义::-webkit-scrollbar则会无效 */
::-webkit-scrollbar {
    width: 6px; /* 针对纵向滚动条 */
    height: 8px; /* 针对横向滚动条 */
}
/* 滚动条 */
::-webkit-scrollbar-thumb {
    border-radius: 10px;
    background-color: tint(#adb0b8, 50%); /* 滚动条颜色，50%为半透明，100%为完全透明 */
}
/* 滚动槽 */
::-webkit-scrollbar-track {
    border-radius: 10px;
    background-color: red;
}
::-webkit-scrollbar-thumb:hover {
    background: tint(#adb0b8, 20%);
}
```
- 隐藏滚动条(但是可以滚动)

```css
#box {
  height: 300px;
  overflow-y: scroll;
}
#box::-webkit-scrollbar {
  display: none;
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

### 图片

- 图片阴影

```css
-webkit-filter: drop-shadow(10px 20px 20px rgba(0, 0, 0, 0.5));
filter: drop-shadow(10px 20px 20px rgba(0, 0, 0, 0.5)); /*考虑浏览器兼容性：兼容 Chrome, Safari, Opera */
```
- 显示原型图片(需要原图为正方形)

```css
border-radius: 50%;
```

### 箭头动画(纯css)

```less
/* 箭头特效。向上箭头使用：<div class="sq-arrow sq-arrow_top"></div> */
.sq-arrow {
    cursor: pointer;
    width: 20px;
    height: 20px;
    border-bottom: 4px solid #fff;
    border-right: 4px solid #fff;
    position: absolute;
    top: 0px;
    left: 0px;
    cursor: pointer;
    opacity: 0.8;
    
    -webkit-transition: opacity .2s ease-in-out, transform .5s ease-in-out .2s;
    transition: opacity .2s ease-in-out, transform .5s ease-in-out .2s;

    &.sq-arrow_left {
        /* 设置帧名称sq-arrow-x，帧时间0.5s，ease-in-out缓慢进入退出，infinite继承父容器特效 */
        -webkit-animation: sq-arrow-x .5s ease-in-out alternate infinite;
        animation: sq-arrow-x .5s ease-in-out alternate infinite;

        /* 对元素进行变换，旋转135度 */
        -webkit-transform: rotate(135deg);
        -ms-transform: rotate(135deg);
        transform: rotate(135deg);
    }
    &.sq-arrow_right {
        -webkit-animation: sq-arrow-x .5s ease-in-out alternate infinite;
        animation: sq-arrow-x .5s ease-in-out alternate infinite;

        -webkit-transform: rotate(-45deg);
        -ms-transform: rotate(-45deg);
        transform: rotate(-45deg);
    }
    &.sq-arrow_top {
        -webkit-animation: sq-arrow-y .5s ease-in-out alternate infinite;
        animation: sq-arrow-y .5s ease-in-out alternate infinite;

        -webkit-transform: rotate(-135deg);
        -ms-transform: rotate(-135deg);
        transform: rotate(-135deg);
    }
    &.sq-arrow_bottom {
        -webkit-animation: sq-arrow-y .5s ease-in-out alternate infinite;
        animation: sq-arrow-y .5s ease-in-out alternate infinite;

        -webkit-transform: rotate(45deg);
        -ms-transform: rotate(45deg);
        transform: rotate(45deg);
    }
}
.sq-arrow:hover {
    -webkit-transition-delay: 0;
    transition-delay: 0;
    opacity: 1;
}

/* 左右箭头动画帧设置 */
@-webkit-keyframes sq-arrow-x {
    100% {
        left: 20px
    }
}
@keyframes sq-arrow-x {
    100% {
        left: 20px
    }
}
/* 上下箭头动画帧设置 */
@-webkit-keyframes sq-arrow-y {
    100% {
        top: 20px
    }
}
@keyframes sq-arrow-y {
    100% {
        top: 20px
    }
}
```

### 吸附效果(头部/底部导航)

- position: sticky

```css
.sticky {
    position: sticky;
    position: -webkit-sticky;
    top: 0;
}
```

- position: fixed

```css
.top {
    position: fixed;
    left: 0;
    top: 0;
}
.bottom {
    position: fixed;
    left: 0;
    bottom: 0;
}
```

### body背景图片平铺

```css
body{
    /*设置背景图片*/
    background-image: url("../images/background/back.jpg") ;
    background-size: 100% 100%;
    background-size: cover;
    background-repeat: no-repeat;
    background-attachment: fixed;  /*关键*/
    background-position: center;
    top:0;
    left: 0;
    width: 100%;
    height: 100%;
    min-width: 1600px;
    z-index: -10;
    zoom:1;
}
```

### 通过HTML转义字符完成部分简单图标

- https://www.cnblogs.com/zfc2201/archive/2012/12/18/2824112.html

### CSS实现文字横向滚动

- https://juejin.cn/post/6844904165446156302

## 常见问题

### height: 100%; 无效 [^2]

**width和height属性，基于%设定宽高时，实际是根据父元素的宽高来的**(父元素要设置数值或者%高度，对祖父元素设置是无效的)

- 当你让一个元素的高度设定为百分比高度时，是相对于父元素的高度根据百分比来计算高度。当没有给父元素设置高度（height）时或设置的高度值百分比不生效时，浏览器会根据其子元素来确定父元素的高度，所以当无法根据获取父元素的高度，也就无法计算自己高度
- 要想使%高度有效，我们需要设置父元素的height(数值或者%)
    - 要特别注意的一点是，在`<body>`之中的元素的父元素并不仅仅只是`<body>`，还包括了`<html>`。所以要同时设置这两者的height，只设置其中一个是不行的

### overflow: auto; 无效

盒子内容溢出将在满足下列条件之一时出现

- 一个不换行的行元素宽度超出了容器盒子宽度
- 一个宽度固定的块元素放在了比它窄的容器盒子内
- 一个元素的高度超出了容器盒子的高度
- 一个子孙元素，由负边距值引起的部分内容在盒子外部
- text-indent属性引起的行内元素在盒子的左右边界外
- 一个绝对定位的子孙元素，部分内容在盒子外，但超出的部分不会被剪裁(overflow: hidden;)

### 子元素使用float导致父元素没有高度

```css
/* 参考 https://www.jianshu.com/p/a1724eeb07a6 */
.container:after {
    clear: both;
    content:" ";
    display: block;
    width:0;
    height: 0;
    visibility: hidden;
}
```

### z-index 失效

- 使用
    - z-index元素的position属性要是relative，absolute或是fixed
    - z-index值越大就越是在上层
- z-index在一定的情况下会失效
    - 父元素position为relative时，子元素的z-index失效
        - 将父元素position改为absolute或static
    - 该标签在设置z-index的同时还设置了float浮动
        - float去除，改为display：inline-block

### 父元素的高度无缘无故增加

- 在父元素上使用 flex 布局可解决：`display: flex;`
    - https://blog.csdn.net/qq_43886365/article/details/127230526

### 绝对定位水平对齐

```css
div {
    position: absolute;
    top: 90px; /* 高度一般不会伸缩 */
    transform: translate(50%, 0); /* 水平对齐 */
}
```

### 最后一个元素撑满当前行

```css
.parent {
    display: flex;
    .last-box {

    }
}
```

## CSS框架

### 30-seconds-of-css

- https://github.com/30-seconds/30-seconds-of-css
- **CSS 片段集合**
    - 包含 CSS3 的实用程序和交互式示例
    - 它包括用于创建常用布局、样式和动画元素的现代技术，以及用于处理用户交互的片段

### TailwindCSS

- [Github 69.2k](https://tailwindcss.com/)
- [中文站](https://www.tailwindcss.cn/)
- 原子风格：所有样式都基于 class，只需为 HTML 元素指定class，样式立刻生效
- 它集成了诸如 flex, pt-4, text-center 和 rotate-90 这样的的类

### bulma

- [Github 47.2k](https://github.com/jgthms/bulma)
- 原子风格

### daisyui

- [Github 21.9k](https://daisyui.com/)
- 原子风格
- 内涵21种主题配色

### animate.css

- https://github.com/animate-css/animate.css
- 跨平台的CSS3动画库

### postcss

- https://github.com/postcss/postcss
- 用 JavaScript 工具和插件转换 CSS 代码的工具

### emotion

- https://github.com/emotion-js/emotion
- 用 JavaScript 编写 css 样式的库，CSS-in-JS

### styled-components

- https://github.com/styled-components/styled-components
- 贯彻 React 的 everything in JS 理念，降低 js 对 css 文件的依赖

## 性能优化

- 使用`img`图片比元素使用`background(url)`快




---

[^1]: https://segmentfault.com/a/1190000012800450
[^2]: https://segmentfault.com/a/1190000012707337
