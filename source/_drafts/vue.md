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
- 注意
    - vue单文件组件，每个文件里面只能还有一个script标签；如果含有多个，默认只解析最后一个

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

- 加载顺序：先创建父组件，先挂载子组件
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
    },
    $route(to, from) {
        if (to.name == "XXX") {
            // 监控路由变化，进行数据重新获取
            this.init()
        }
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

### list元素改变/子对象属性改变数据不刷新问题

```html
<!-- 示例使用iveiw库 -->
<!-- (1) 产品可以选择多个，选择产品后，产品单位需要联动变化 -->
<div>
<!--  -->
<div v-for="(item, index) in customer.customerProducts">
    产品：
    <Select v-model="customer.customerProducts[index].id" @on-change="productChange(index)">
        <Option v-for="(optItem, optIndex) in products" :value="optItem.id" :key="optIndex">{{ optItem.productName }}</Option>
    </Select>
    产品单位：{{ customer.customerProducts[index].productUnit }}
</div>

<!-- (2) 省市级联 -->
<!-- @on-change="provinceChange" 使用change时，改变customer.province的值（this.$set也不行）无法触发change事件 -->
<Select v-model="customer.province" placeholder="请选择省份" clearable>
    <Option v-for="item in provinceList" :value="item.value" :key="item.value">{{ item.label }}</Option>
</Select>
<Select v-model="customer.city" clearable>
    <Option v-for="item in cityList" :value="item.value" :key="item.value">{{ item.label }}</Option>
</Select>
</div>
    
<script>
export default {
    data() {
        return {
            customer: {
                customerProducts: [{ // 客户所有的产品
                    id: null,
                    productUnit: '',
                }],
                province: null,
                city: null,
            },
            products: [], // 所有的产品
            provinceList: [],
            cityList: []
        }
    },
    computed: {
        province() {
    　　　　return this.customer.province
    　　}
    },
    watch: {
        // 利用computed观测子对象具体属性的变化
        province(newValue, oldValue) {
    　　　　this.provinceChange()
    　　},
        // 扩展：观测整个子对象的变化
        customer: {
    　　　　handler(newValue, oldValue) {
    　　　　　　console.log(newValue)
    　　　　},
    　　　　deep: true
    　　}
    },
    methods: {
        productChange(index) {
            let vm = this
            let product = {}
            this.products.some(function(item) {
                // 函数内部不能使用this拿到vue实例。 item => {} 中可以通过this拿到
                if(item.id == vm.customer.customerProducts[index].id) {
                    product = Object.assign({}, item) // 此处一定要重新赋值成一个新对象。product = item 会导致产品单位永远是第一次选中的值
                    return true;
                }
            })

            this.$set(this.customer.customerProducts, index, product); // 从新设值强行刷新此属性. this.$set(Object/Array, string/number, any)
        },
        provinceChange() {
            // 
            // ... 请求后台获取省份下的城市
        }
    },
    mounted() {
        this.customer.province = 1000; // 手动改省份
    }
}
</script>
```

## 组件

### 自定义组件中使用 v-model

- [官方说明](https://cn.vuejs.org/v2/guide/components-custom-events.html#%E8%87%AA%E5%AE%9A%E4%B9%89%E7%BB%84%E4%BB%B6%E7%9A%84-v-model)
- 双向数据绑定主要需要解决表单元素值改变后对应的变量值同时变化(变量值变化表单元素的值变化是肯定的)
- 在原生表单元素中 `<input v-model="inputValue">` 相当于 `<input v-bind:value="inputValue" v-on:input="inputValue = $event.target.value">`

```html
<script>
// 本质是表单元素原生事件，并将值放入其中。$emit('change', 'smalle')"
Vue.component('base-checkbox', {
  model: {
    prop: 'checked', // value
    event: 'change'
  },
  props: {
    checked: Boolean
  },
  template: `
    <input
      type="checkbox"
      v-bind:checked="checked"
      v-on:change="$emit('change', $event.target.checked)"
    >
  `
})
</script>

<!-- 调用组件 -->
<base-checkbox v-model="lovingVue"></base-checkbox>
```

### 父子组件通信

> [Prop](https://cn.vuejs.org/v2/guide/components.html#Prop)、[自定义事件]()https://cn.vuejs.org/v2/guide/components.html#%E8%87%AA%E5%AE%9A%E4%B9%89%E4%BA%8B%E4%BB%B6

#### 通信方式

- 通过`props`从父向子组件传递数据，父组件对应属性改变，子组件也会改变
    - 如果在子组件中修改定义的`props`参数，则会报错：`vue.esm.js:591 [Vue warn]: Avoid mutating a prop directly since the value will be overwritten whenever the parent component re-renders. Instead, use a data or computed property based on the prop's value. Prop being mutated: "customerId"`
- 自定义事件`$emit`，子组件可以向父组件传递数据(参考以下示例)
- 通过`$refs`属性，父组件可直接取得子组件的数据
    - 场景还原：父组件点击按钮，控制显示子组件的弹框(`iview`弹框)，此时当`iview`弹框关闭时会修改`v-model`的值，如果用`props`则违反了`props`单向数据流的原则
    - `ref`可以用于标记一个节点或组件
- 在父组件中使用`sync`修饰符修饰props属性，则实现了父子组件中hello的双向绑定，但是违反了单项数据流，只适合特定业务场景

#### 知识点

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

#### 示例

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

#### 子组件和子组件通信(Bus)

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
this.$root.eventHub.$on('eventName', (data) => {
    // 处理数据
})
```

### 动态组件 [^1]

- `v-bind:is="组件名"`：就是几个组件放在一个挂载点下，然后根据父组件的某个变量来决定显示哪个，或者都不显示
- `keep-alive`：默认被切换掉（非当前显示）的组件，是直接被移除了。假如需要子组件在切换后，依然需要他保留在内存中，避免下次出现的时候重新渲染，那么就应该在component标签中添加`keep-alive`属性
- `activate`：钩子，延迟加载
- `transition-mode`过渡模式

```js
<div id="app">  
    <button @click="toshow">点击让子组件显示</button>
    <component v-bind:is="which_to_show" keep-alive></component>  
</div>

<script>  
    var vm = new Vue({  
        el: '#app',  
        data: {  
            which_to_show: "first"  
        },  
        methods: {  
            toshow: function () {   //切换组件显示  
                var arr = ["first", "second", "third", ""];  
                var index = arr.indexOf(this.which_to_show);  
                if (index < 3) {  
                    this.which_to_show = arr[index + 1];  
                } else {  
                    this.which_to_show = arr[0];  
                }  
            }  
        },  
        components: {  
            first: { //第一个子组件  
                template: "<div>这里是子组件1</div>"  
            },  
            second: { //第二个子组件  
                template: "<div>这里是子组件2</div>"  
            },  
            third: { //第三个子组件  
                template: "<div>这里是子组件3</div>"  
            },  
        }  
    });  
</script>

```

### Vue.use

- https://segmentfault.com/q/1010000013184129?sort=created

## 路由

- query和params的区别：query参数会拼接到url上面，param不会。因此路由跳转后再次刷新页面会导致参数丢失

```js
this.$router.push({
    name: "VisitInfo",
    query: Object.assign({}, contact, {
        visitId: this.visitId
    })
});
```

### 路由变化数据无法更新

- 参考上文【父子组件加载】中的示例，监控`$route`变化


---

参考文章

[^1]: https://www.cnblogs.com/-ding/p/6339740.html (动态组件)