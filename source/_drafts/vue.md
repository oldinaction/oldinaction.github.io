---
layout: "post"
title: "vue"
date: "2018-04-03 17:14"
categories: [web]
tags: vue
---

## 基本

- 习惯
    - 项目url固定链接不以`/`结尾，使用地方手动加`/`方便全局搜索

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

## 页面渲染

### 父子组件加载

- 加载顺序
    - 创建父组件 `beforeCreate` - `created`
    - 挂载父组件之前 `beforeMount`
    - 创建子组件 `beforeCreate` - `created`
    - 挂载子组件之前 `beforeMount`
    - 挂载子组件 `mounted`
    - 挂载父组件 `mounted`
- 父子组件分别请求各自的数据，且子组件请求中的某些参数需要等父组件获取后台数据后才可初始化，此时最好`watch`对应的参数

    ```js
    watch: {
        id(value) {
            this.init()
        }
    },
    method: {
        init() {
            // ...调用后台

        }
    },
    created(): {
        // this.init() // 此处调用则有可能id为空导致只能获取一次数据，且无法获取有有效数据

    }
    ```

### 路由变化数据无法更新

http://www.cnblogs.com/first-time/p/7067674.html

## 父子组件通信

> [Prop](https://cn.vuejs.org/v2/guide/components.html#Prop)、[自定义事件]()https://cn.vuejs.org/v2/guide/components.html#%E8%87%AA%E5%AE%9A%E4%B9%89%E4%BA%8B%E4%BB%B6

### 通信方式

- 通过`props`从父向子组件传递数据，父组件对应属性改变，子组件也会改变
    - 如果在子组件中修改定义的`props`参数，则会报错：`vue.esm.js:591 [Vue warn]: Avoid mutating a prop directly since the value will be overwritten whenever the parent component re-renders. Instead, use a data or computed property based on the prop's value. Prop being mutated: "customerId"`
- 自定义事件`$emit`，子组件可以向父组件传递数据(参考以下示例)
- 通过`$refs`属性，父组件可直接取得子组件的数据
    - 场景还原：父组件点击按钮，控制显示子组件的弹框(`iview`弹框)，此时当`iview`弹框关闭时会修改`v-model`的值，如果用`props`则违反了`props`单向数据流的原则
    - `ref`可以用于标记一个节点或组件
- 在父组件中使用`sync`修饰符修饰props属性，则实现了父子组件中hello的双向绑定，但是违反了单项数据流，只适合特定业务场景

### 知识点

- `props`定义说明

    ```js
    props: ['count', 'name']

    props: {
        list: Array,
        myFunc: {
            type: Function,
            default: (item) => {
                return true;
            }
        }
    }
    ```

### 示例

```html
<!-- parent.vue -->
<template>
    <div>
        <button v-on:click="clickParent">点击</button>
        <Child ref="child" msg="hello child" @my-event="myEvent"></Child>
        
        <!--使用sync修饰符，则实现了父子组件中hello的双向绑定，但是违反了单项数据流，只适合特定业务场景-->
        <Child ref="child" :msg.sync="hello" @my-event="myEvent"></Child>
    </div>
</template>

<script>
    import Child from './child';
    export default {
        name: "parent",
        components: {
            Child
        },
        data() {
            return {
                hello: ''
            }
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

<!-- child.vue -->
<template>
    <div>${msg}</div>
    <button @click="triggerMyEvent('smalle')">触发子组件事件</button>
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
            triggerMyEvent(name) {
                this.$emit("my-event", this.data); // 事件名称(不要使用驼峰命名)、负载
                this.$emit(`update:${name}`, this.data) // 事件名称包含变量
            }
        }
    }
</script>
```

### 子组件和子组件通信

```js
// 在初始化web app的时候，main.js给data添加一个 名字为eventHub的空vue对象。就可以使用 this.$root.eventHub 获取对象
new Vue({
    el: '#app',
    router,
    render: h => h(App),
    data: {
        eventHub: new Vue()
    }
})

// 在一个组件内调用事件触发。通过this.$root.eventHub获取此对象，调用 $emit 方法
this.$root.eventHub.$emit('eventName', data)

// 在另一个组件调用事件接受，移除事件监听器使用$off方法。
this.$root.eventHub.$on('eventName', (data)=>{
    // 处理数据
})
```