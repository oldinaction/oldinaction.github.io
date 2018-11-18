---
layout: "post"
title: "iview"
date: "2017-07-23 16:11"
categories: web
tags: [vue, UI]
---

## 简介

- 默认基于`v2.x`版本

## 使用

### 注意点

- `Tree`组件在动态网节点中加入数据后（往一个数组中插入元素），点击新节点时会报错。此时需要重新赋值此数组属性：`this.treeList = JSON.parse(JSON.stringify(this.treeList))` (可能是treeList里面的元素改变并不会触发vue的渲染)
- 使用`:prop`传递数据格式为**数字、布尔值或函数**时，必须带`:`(兼容String除外，具体看组件文档) (1)
- prop参数如果直接初始化则之后不可修改，只有传入变量才开修改 (2)

	```html
	<!-- (1) -->
	<Page :current="1" :total="100"></Page>

	<Select v-model="sex" placeholder="请选择">
		<Option :value="1">男</Option>
		<Option :value="2">女</Option>
	</Select>

	<Radio-group v-model="status">
		<Radio :label="1">是</Radio>
		<Radio :label="0">否</Radio>
	</Radio-group>

	<!-- (2) -->
	<!-- 此时disabled相当于disabled=true；那么无法再修改此下拉的禁用状态，通过refs去修改也会报错；只能绑定相应的属性，如：`:disabled="subResultDisabled"` -->
	<Select v-model="form.subResult" @on-change="subResultChange" disabled placeholder="请选择">
		<Option v-for="(item, index) in subResult" :value="item.id" :key="index">{{ item.nodeName }}</Option>
	</Select>
	```

### 通用方法

- render

```js
// 语法
render: (h, {params | param}) => {
	// 此时params中包含row、column和index; param就是row
	return h("定义元素标签/Vue对象标签", { 元素性质 }, "元素内容"/[元素内容])

	// 2个参数的情况
	return h("定义的元素", "元素的内容"/[元素的内容])
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
		}, function(vm) {
			console.log(vm)
			// 此时this为函数作用域类，拿不到vue对象
			return params.row.CorporateName + '...'
		}(this)),
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
				attrs: {
					// button 标签的其他属性
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

## 样式

### 通用标签属性

- `transfer` 让元素置顶层显示，防止被其他元素遮挡(如果未遮挡慎用)
- 使用空的`Col`完成排版`<Col span="2">&nbsp;</Col>`



