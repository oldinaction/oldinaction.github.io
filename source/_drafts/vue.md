---
layout: "post"
title: "vue"
date: "2018-04-03 17:14"
categories: [web]
tags: vue
---

## 基本

- 文件引入
    
    ```html
    <!-- css -->
    <style lang="less">
        @import '../styles/common.less';
    </style>

    <script>
    // (1)引入
    import MyModule1 from "./../common/MyModule1.vue";
    // @表示项目源码根目录(src)
    import MyModule1 from "@/common/MyModule1.vue";

    // (2) 封装组件库 sm-util.js 
    // ==> 示例一
    export default {} // 导入：import SmUtil from './libs/sm-util.js'

    // ==> 示例二
    import axios from 'axios'; // 导入其他组件
    const SmUtil = {}
    export default SmUtil

    // ==> 示例三
    export const SmUtil = {}
    </script>
    ```

## 父子组件通信

> [Prop](https://cn.vuejs.org/v2/guide/components.html#Prop)、[自定义事件]()https://cn.vuejs.org/v2/guide/components.html#%E8%87%AA%E5%AE%9A%E4%B9%89%E4%BA%8B%E4%BB%B6

- 自定义事件`$emit`(参考以下示例)
- 父调用子的参数或方法，可使用 `$refs`
    - 场景还原：父组件点击按钮，控制显示子组件的弹框(`iview`弹框)，此时当`iview`弹框关闭时会修改`v-model`的值，如果用`props`则违反了`props`单向数据流的原则
    - **`ref`可以用于标记一个节点或组件**

```html
<!-- child.vue -->
<template>
    <div>${msg}</div>
    <button @click="triggerMyEvent">触发子组件事件</button>
</template>

<script>
    export default {
        name: "child",
        // 组件定义好组件属性名称
        props: ["count"],
        data: () {
            return {
                show: false
            }
        },
        methods: {
            handleParentClick(e) {
                console.info(e)
            },
            triggerMyEvent() {
                this.$emit("my-event", this.data); // 事件名称、负载
            }
        }
    }
</script>

<!-- parent.vue -->
<template>
    <div>
        <button v-on:click="clickParent">点击</button>
        <Child ref="child" msg="hello child" @my-event="myEvent"></Child>
    </div>
</template>

<script>
    import Child from './child';
    export default {
        name: "parent",
        components: {
            Child
        },
        methods: {
            clickParent() {
                // this.$refs.child.$emit('click-child', "high");
                this.$refs.child.handleParentClick("hello");
                this.$refs.child.show = true; // 不能写成@click="this.$refs.child.show = true"，此时this不是vue
            },
            myEvent(params) {
                // 捕获事件
                console.log(params)
            }
        }
    }
</script>
```