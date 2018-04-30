---
layout: "post"
title: "iview"
date: "2017-07-23 16:11"
categories: web
tags: [web, vue, UI]
---

## 简介

## 使用

### 通用标签属性

- `transfer` 让元素置顶层显示，防止被其他元素遮挡(如果未遮挡慎用)

### 通用方法

- render

```js
// 语法
render: (h, params) => {
  return h("定义元素标签/Vue对象标签", { 元素性质 }, "元素内容"/[元素内容])
  // return h("定义的元素", "元素的内容"/[元素的内容]) // 2个参数的情况
}

// 示例
render: (h, params) => {
  // 如果在表格的列中使用，此时params中包含row、column和index，分别指当前单元格数据，当前列数据，当前是第几行。
  return h('div', {
    style:{width:'100px', height:'100px', background:'#ccc'}
  }, '用户名：smalle')
}

// 示例二：此时Poptip和Tag都是Vue对象，因此要设置参数props
// 调用组件并监听事件
<MyComponent @my-event="myEvent"/>

// 组件内部渲染
render: (h, params) => {
  return h('Poptip', {
    props: {
      trigger: 'hover',
      title: params.row.name + '的信息',
      placement: 'bottom',
      transfer: true
    }
  }, [
    h('Tag', {
      // 此处必须写在props里面，不能直接将组件属性放在元素性质里面
      props: function() {
          const color = params.index == 1 ? 'red' : params.index == 3 ? 'green' : '';
          const props = {
              type: "dot",
              color: color
          }
          return color == '' ? {} : props
      }()
    }, function() {
      return params.row.CorporateName + '...'
    }()),
    h('div', {
      slot: 'content'
    }, [
      h('p', {
          style: {
              padding: '4px'
          }
      }, '用户名：' + params.row.name)
    ]),
    return h("div", [
      h("Button", {
        props: {
          type: "info",
          size: "small"
        },
        style: {
          marginRight: "8px"
        },
        on: {
          click: ok => {
            // 触发事件
            this.$emit("my-event", params);
          }
        }
      },
      "重登")
    ])
  ])
}
```