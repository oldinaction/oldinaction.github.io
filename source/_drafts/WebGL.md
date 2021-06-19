---
layout: "post"
title: "WebGL"
date: "2021-06-18 21:51"
categories: web
tags: [3d]
---

## 简介

- WebGL（全写Web Graphics Library）是一种3D绘图协议，这种绘图技术标准允许把JavaScript和 OpenGL ES 2.0 结合在一起，通过增加 OpenGL ES 2. 0的一个 JavaScript 绑定，WebGL 可以为HTML5 Canvas 提供硬件 3D 加速渲染，这样Web开发人员就可以借助系统显卡来在浏览器里更流畅地展示3D场景和模型了，还能创建复杂的导航和数据视觉化。显然，WebGL 技术标准免去了开发网页专用渲染插件的麻烦，可被用于创建具有复杂3D结构的网站页面，甚至可以用来设计 3D 网页游戏等等。
- 基于 WebGL 实现的 3D 引擎
    - `Three.js` 是纯渲染引擎，而且代码易读，容易作为学习WebGL、3D图形、3D数学应用的平台，也可以做中小型的重表现的Web项目。但如果要做中大型项目，尤其是多种媒体混杂的或者是游戏项目VR体验项目，Three.js必须要配合更多扩展库才能完成
    - `Babylon.js` 是微软发布的开源的 Web 3D 引擎。最初设计作为一个Silverlight游戏引擎，Babylon.js 的维护倾向于基于 Web 的游戏开发与碰撞检测和抗锯齿等特性。在其官网上可以看到很多例子：http://www.babylonjs.com/


