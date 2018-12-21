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
    - **vue单文件组件，每个文件里面只能含有一个script标签；如果含有多个，默认只解析最后一个**

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

### vue生命周期

- 生命周期钩子
    - 根组件实例：8个 (beforeCreate、created、beforeMount、mounted、beforeUpdate、updated、beforeDestroy、destroyed)
    - 组件实例：8个 (beforeCreate、created、beforeMount、mounted、beforeUpdate、updated、beforeDestroy、destroyed)
    - 全局路由钩子：2个 (beforeEach、afterEach)
    - 组件路由钩子：3个 (beforeRouteEnter、beforeRouteUpdate、beforeRouteLeave)
    - 指令的周期： 5个 (bind、inserted、update、componentUpdated、unbind)
    - beforeRouteEnter的next所对应的周期
    - nextTick所对应的周期
    - `<keep-alive>` 组件 `activated` 和 `deactivated`
- 钩子执行顺序
    - 路由勾子 (beforeEach、beforeRouteEnter、afterEach)
    - 根组件 (beforeCreate、created、beforeMount)
    - 组件 (beforeCreate、created、beforeMount)
    - 指令 (bind、inserted)
    - 组件 mounted
    - 根组件 mounted
    - beforeRouteEnter的next的回调
    - nextTick

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

### 数组/对象改变数据不刷新问题

- 官方说明
    - https://cn.vuejs.org/v2/guide/list.html#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9
    - https://cn.vuejs.org/v2/guide/reactivity.html#%E6%A3%80%E6%B5%8B%E5%8F%98%E5%8C%96%E7%9A%84%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9
    - 由于 JavaScript 的限制，Vue 不能检测以下变动的数组：
        - 当你利用索引直接设置一个项时，例如：`vm.items[indexOfItem] = newValue`
        - 当你修改数组的长度时，例如：`vm.items.length = newLength`
    - 还是由于 JavaScript 的限制，Vue 不能检测对象属性的添加或删除

        ```js
        var vm = new Vue({
            data:{
                a: 1,
                user: {
                    name: null
                }
            }
        })
        // `vm.a` 是响应的
        vm.b = 2
        // `vm.b` 是非响应的
        vm.user.name = 'smalle' // 是响应的
        vm.user.password = '123456' // 是非响应的
        ```
- **vue无法检测数组的元素变化(包括元素的添加或删除)；可以检测子对象的属性值变化，但是无法检测未在data中定义的属性或子属性的变化**
    - 解决上述数组和未定义属性不响应的方法：`this.user = Object.assign({}, this.user);` 或 `this.user = JSON.parse(JSON.stringify(this.user));`
    - 对于select，必须定义key值(只需要当前select的key值唯一，无需整个页面的key值唯一)保证唯一性。否则容易出现无法选择/无法修改该select的值，导致数据响应不触发
- 扩展说明

```html
<!-- 示例使用iveiw库 -->
<!-- (1) 产品可以选择多个，选择产品后，产品单位需要联动变化 -->
<div>
<!--  -->
<div v-for="(item, index) in customer.customerProducts">
    产品：<!-- 此处要通过v-model="customer.customerProducts[index].id"进行绑定，不要使用 item.id -->
    <Select v-model="customer.customerProducts[index].id" @on-change="productChange(index)">
        <Option v-for="(item, index) in products" :value="item.id" :key="index">{{ item.productName }}</Option>
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

            // list元素改变需要重新赋值。或者通过 this.customer.customerProducts = JSON.parse(JSON.stringify(this.customer.customerProducts))
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
<!-- 示例一 -->
<script>
// 本质是表单元素原生事件，并将值放入其中。$emit('change', 'smalle')
Vue.component('base-checkbox', {
    // model: 允许一个自定义组件在使用 v-model 时定制 prop(组件会将v-model和此prop绑定，调用者将值传到v-model中，最终相当于传入到了此prop上) 和 event
    model: {
        prop: 'checked', // props中的key。默认取pops中的value
        event: 'change' // 默认为input事件 
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

<!-- 调用组件：相当于将 lovingVue 的值和 model.prop => props.checked 进行绑定 (此时调用此组件则不需要传checked这个参数) -->
<base-checkbox v-model="lovingVue"></base-checkbox>

<!-- 实例二：基于element-ui组装一个v-model -->
<!-- MyEleSelect.vue -->
<template>
    <!-- 此处不能直接使用v-model="value"，因为当element的el-select发生改变时则会修改v-model="value"中value的属性，违背了子组件不建议修改porps参数的值(v-model的$emit修改除外) -->
    <el-select v-model="model" multiple :remote-method="findList" @change="change">
        <el-option v-for="(item, index) in list" :key="index" :label="name" :value="code"></el-option>
    </el-select>
</template>

<script>
    export default {
        name: 'MyEleSelect',
        model: {
            event: 'change' // 只能代表本组件中的事件
        },
        props: {
            // 取得是 v-model="myValue" 中 myValue 的值
            value: {
                type: Array,
                default: function () {
                    return []
                }
            },
        },
        data() {
            return {
                list: [],
                model: this.value // v-model="model" 保证了此组件(MyEleSelect)与<el-select>组件的数据绑定
            }
        },
        computed: {
            // model() {return this.value} // computed属性一般没有setter方法，不建议使用
        },
        watch: {
            value(n, o) {
                this.model = this.value // 此处保证了父组件(调用MyEleSelect的组件)可以将最近的值更新到model中(从而传递到<el-select>中)
            }
        },
        methods: {
            findList(query) {
                // this.list = ...
            },
            change() {
                // 此处保证了子组件发送的数据会被父组件的v-model="myValue"接受，再被value="myValue"传回。
                // 如果上面没有定义model.event="change"，则此处的时间必须是'input'
                // el-select中也有change事件，但是该事件传回的值只能到此组件的v-model中，无法再往外面传输，因此此处必须触发新的事件(本组件中定义的事件)
                this.$emit('change', this.model) 
            }
        },
    };
</script>

<!-- 调用 -->
<MyEleSelect v-model="myValue"/>
```

### 父子组件通信

> [Prop](https://cn.vuejs.org/v2/guide/components.html#Prop)、[自定义事件]()https://cn.vuejs.org/v2/guide/components.html#%E8%87%AA%E5%AE%9A%E4%B9%89%E4%BA%8B%E4%BB%B6

#### 通信方式

- 通过`props`从父向子组件传递数据，父组件对应属性改变，子组件也会改变。**子组件中不建议修改`props`中的属性**
    - 在Vue2中组件的props的数据流动改为了只能单向流动，即只能由组件外（调用组件方）通过组件的DOM属性attribute传递props给组件内，组件内只能被动接收组件外传递过来的数据，并且在组件内，不能修改由外层传来的props数据
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
    obj: [Array, Object],
    list: {
        type: Array,
        // Props with type Object/Array must use a factory function to return the default value.
        default: function() {
            return []; // 或者return {};
        }
    },
    age: {
        type: Number,
        default: 18,
        validator (value) {
            return value > 0 && value < 150;
        }
    },
    myFunc: {
        type: Function,
        /*如果是Object/Function/Array，default需要通过函数表示*/
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
                this.$refs.child.childMethod("hello"); // 父组件调用子组件方法

                // 不能写成 @click="this.$refs.child.show = true"，此时this不是vue。
                // 但是可以写成 @click="() => {this.$refs.child.show = true}"
                this.$refs.child.show = true;
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
        props: ["count", "msg"],
        data: () {
            return {
                show: false
            }
        },
        methods: {
            childMethod(e) {
                console.info(e)
            },
            triggerMyEvent(name) {
                this.$emit("my-event", this.data); // 参数一为事件名称(不要使用驼峰命名)、参数二负载
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

### 基本概念

- `query`和`params`的区别：query参数会拼接到url上面，param不会。因此使用param时路由跳转后再次刷新页面会导致参数丢失

```js
this.$router.push({
    name: "VisitInfo",
    query: Object.assign({}, contact, {
        visitId: this.visitId
    })
});
```

- `$route`和`$router`区别：$route为当前路由。$router为路由管理器(全局的)

```js
export default {
  computed: {
    username () {
      return this.$route.params.username
    }
  },
  methods: {
    goBack () {
      window.history.length > 1 ? this.$router.go(-1) : this.$router.push('/')
    }
  }
}
```

- `<router-view></router-view>` 嵌套路由

> 嵌套路由（https://router.vuejs.org/zh/guide/essentials/nested-routes.html）

```js
// 此处的router-view是用于渲染顶级组件，及此时的Mobile组件
<div id="app">
  <router-view></router-view>
</div>

// 此时由于mVisitInfo基于Mobile的，因此Mobile中必须要有一个路由出口(<router-view>)来展示mVisitInfo
const routers = [{
  path: "/m",
  name: "mobile",
  component: Mobile,
  children: [{
    path: "mVisitInfo", // path带/表示绝对路径。此时不带/，到通过name=mVisitInfo路由进来时，url会自动变成/m/mVisitInfo
    name: "mVisitInfo",
    meta: {
      title: "拜访录入"
    },
    component: () => import("@/views/mobile/mVisitInfo.vue")
  }]
}]
```

### 路由变化页面数据不刷新

- 参考上文【父子组件加载】中的示例，监控`$route`变化

> 官方说明 https://router.vuejs.org/zh/guide/essentials/dynamic-matching.html#%E5%93%8D%E5%BA%94%E8%B7%AF%E7%94%B1%E5%8F%82%E6%95%B0%E7%9A%84%E5%8F%98%E5%8C%96

- 当使用路由参数时，例如从 /user/foo 导航到 /user/bar，原来的组件实例会被复用。因为两个路由都渲染同个组件(User)，比起销毁再创建，复用则显得更加高效。不过，这也意味着组件的生命周期钩子不会再被调用

```js
const router = new VueRouter({
  routes: [
    // 动态路径参数 以冒号开头
    { path: '/user/:id', component: User }
  ]
})

// 解决办法(都会看到之前的数据突然刷新成了新的数据)
const User = {
    template: '...',
    watch: {
        // 观测 $route 时组件第一次创建和挂载都不会监测(触发)到，因此需要和created/mounted等结合使用
        // 只要此组件在声明周期中就会，此方法就会一致监测到变化并执行逻辑(尽管此组件的元素没有显示在浏览器中也会如此)
        // 单引号可以省略
        '$route' (to, from) {
            if (to.name == "XXX") {
                // 对路由变化作出响应...
                // this.init();
            }
        }
    },
    beforeRouteEnter (to, from, next) {
    // beforeRouteUpdate (to, from, next) {
        // react to route changes...
        // don't forget to call next()
        next(vm => {
            // vm === this; mounted了之后才会调用next
        })
    }
}
```


---

参考文章

[^1]: https://www.cnblogs.com/-ding/p/6339740.html (动态组件)
[^2]: https://segmentfault.com/a/1190000008879966#articleHeader14 (vue生命周期)

