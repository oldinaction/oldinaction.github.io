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
        // `vm.b` 是非响应的(添加新属性)
        vm.user.name = 'smalle' // 是响应的
        vm.user.password = '123456' // 是非响应的(添加新属性)
        ```
- **vue无法检测数组的元素变化(包括元素的添加或删除)；可以检测子对象的属性值变化，但是无法检测未在data中定义的属性或子属性的变化**
    - 解决上述数组和未定义属性不响应的方法：**`this.user = JSON.parse(JSON.stringify(this.user));`**(部分场景可使用`this.user = Object.assign({}, this.user);`)
    - 对于select，必须定义key值(只需要当前select的key值唯一，无需整个页面的key值唯一)保证唯一性。否则容易出现无法选择/无法修改该select的值，导致数据响应不触发
    - 大多数情况下不建议使用index作为key。当第一条记录被删除后，第二条记录的key的索引号会从1变为0，这样导致oldVNode和newNNode两者的key相同。而key相同时，Virtual DOM diff算法会认为它们是相同的VNode，那么旧的VNode指向的Vue实例(如果VNode是一个组件)会被复用，导致显示出错 [^3]
        - `key="&#123;{Date.now() + Math.random()}&#123;"` (此处双括号使用了转义符)
- 扩展说明

```html
<!-- 示例使用iveiw库 -->
<!-- (1) 产品可以选择多个，选择产品后，产品单位需要联动变化 -->
<div>
<!--  -->
<div v-for="(item, index) in customer.customerProducts">
    产品：<!-- 此处要通过v-model="customer.customerProducts[index].id"进行绑定，不要使用 item.id -->
    <Select v-model="customer.customerProducts[index].id" @on-change="productChange(index)">
        <Option v-for="(item, index) in products" :value="item.id" :key="item.id">{{ item.productName }}</Option>
    </Select>
    产品单位：{{ customer.customerProducts[index].productUnit }}
</div>

<!-- (2) 省市级联 -->
<!-- @on-change="provinceChange" 使用change时，改变customer.province的值无法触发change事件（this.$set也不行） -->
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
    　　},
        products: {
            immediate: true, // 代表如果在 wacth 里声明了之后，就会立即先去执行里面的handler方法。(可解决 list 变更后无法watch到变化的问题)
            handler(n, o) {
    　　　　　　console.log(n)
    　　　　},
    　　　　// deep: true
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

### render 函数(iview)

- 语法

```js
// 语法
render: (h, {params | param}) => {
	// 此时params中包含row、column和index; param就是row
	return h("定义元素标签/Vue对象标签", { 元素性质 }, "元素内容"/[元素内容])

    // 2个参数的情况
    return h("定义的元素", { 元素性质 })
	return h("定义的元素", "元素的内容"/[元素的内容])
}

// 示例
render: (h, params) => {
	// 如果在表格的列中使用，此时params中包含row、column和index，分别指当前单元格数据，当前列数据，当前是第几行。
	return h('div', {
		style:{width:'100px', height:'100px', background:'#ccc'}
	}, '用户名：smalle')
}

// 写法优化1
{
	title:'操作',
	align: 'center',
	render: (h, params) => {
        let row = params.row
        let that = this

        let editButtonAttr = {
            on: {
                click: () => {
                    that.edit(row)
                }
            }
        }
        let editButton = h('Button', editButtonAttr, '编辑')

        return h('div', [editButton])
    }
}
// 写法优化2
{
	title:'操作',
	align: 'center',
    render: (h, params) =>{
        let that = this
        return h('div', that.getEditButton(h, params.row)) // getEditButton定义省略
    }
}
```

- iview示例：此时Poptip和Tag都是Vue对象，因此要设置参数props

```js
// 调用组件并监听事件
<MyComponent @my-event="myEvent"/>

// 组件内部渲染
render: (h, params) => {
    // 也 render 一个自定义的组件
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
			// 此时this为函数作用域类，拿不到vue对象，通过vm传递
			console.log(vm)
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
                class: 'class-name'
				style: {
                    marginRight: "8px",
                    // 控制此按钮是否可见
                    display: params.row.statsu == 'Y' ? 'inline-block' : 'none'
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
        <el-option v-for="(item, index) in list" :key="index" :label="name" :value="item"></el-option>
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
                // 此处保证了子组件发送的数据会被父组件的v-model="myValue"接受，再被value="myValue"传回
                // 如果上面没有定义model.event="change"，则此处的事件必须是'input'
                // el-select中也有change事件，但是该事件传回的值只能到此组件的v-model中，无法再往外面传输，因此此处必须触发新的事件(本组件中定义的事件)
                // ***.自定义组件中也可以不用有类似的input表单元素，自定义一个model字段名，并指定其model.event，并在此处emit即可修改model
                this.$emit('change', this.model) // 不能直接修改this.value的值，需要通过修改此处的model属性然后传递到外部组件
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

##### props定义说明

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
        // default() {} // 亦可
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
                this.$emit('input', {}, {}) // 此处可以传递多个参数，并可用多参方法捕获
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

- `$route`和`$router`区别：`$route`为当前路由，`$router`为路由管理器(全局的)

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
// 此处的router-view是用于渲染顶级组件，即此时的Mobile组件
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

### hash和history路由模式

- 为了构建 SPA(单页面应用)，需要引入前端路由系统，这也就是 Vue-Router 存在的意义。前端路由的核心，就在于改变视图的同时不会向后端发出请求。为了达到这种目的，浏览器当前提供了hash和history两种支持模式，Vue-Router是基于此两者特性完成 [^4]
    - `hash`：即地址栏 URL 中的 `#` 符号(此 hash 不是密码学里的散列运算)。比如这个 URL：http://www.abc.com/#/hello，hash 的值为 #/hello。它的特点在于：hash 虽然出现在 URL 中，但不会被包括在 HTTP 请求中，对后端完全没有影响，因此改变 hash 不会重新加载页面
    - `history`：利用了 HTML5 History Interface 中新增的 `pushState()` 和 `replaceState()` 方法。[支持的浏览器(IE=10)](https://developer.mozilla.org/zh-CN/docs/Web/API/History)。这两个方法应用于浏览器的历史记录栈，在当前已有的 back、forward、go 的基础之上，它们提供了对历史记录进行修改的功能。只是当它们执行修改时，虽然改变了当前的 URL，但浏览器不会立即向后端发送请求
- Vue-Router使用对比
    - hash模式
        - 前进、后退、刷新均不会请求后端，仅刷新路由
        - 缺点：Url中带有`#`号，nginx同域名多项目配置不支持
    - history模式
        - 前进、后退不会请求后端，**但是刷新、f5会请求后端**(nginx)，如果后端无浏览器地址栏中的路径则会404
        - 缺点：需要浏览器支持(IE=10)，刷新可能会出404

## 样式

### lang 和 scoped

```html
<!-- lang：可选。默认是以css的方式解析样式；也可指定如 less/sass/stylus 等预处理器(需要提前安装对应依赖，如less需安装 `npm install -D less-loader less`) -->
<!-- scoped：可选。不写scoped时，本身写在vue组件内的样式只会对当前组件和引入此文件的另一组件产生影响，不会影响全局样式；写scoped时，表示该样式只对此组件产生影响，最终会生成样式如 `.example[data-v-5558831a] {color: blue;}` -->
<style scoped lang="less">
@import './assets/globle-varables.less'; /* 引入外部文件。@default-color: red; */
@default-color: blue; /* 覆盖外部文件变量或自定义变量 */

.example {
    color: @default-color; /* 使用变量 */
}

/* scoped穿透问题：需要在局部组件中修改第三方组件库(如 iview)的样式，而又不想去除scoped属性造成组件之间的样式覆盖，这时可以通过特殊的方式穿透scoped */
/* less/sass格式如：`外层 /deep/ 第三方组件 {样式}`(外层也可省略)，stylus则是将 /deep/  换成 >>> */
.wrapper /deep/ .ivu-table th {
    background-color: #eef8ff;
}
</style>
```

### 全局样式/自动化导入

> https://cli.vuejs.org/zh/guide/css.html#%E8%87%AA%E5%8A%A8%E5%8C%96%E5%AF%BC%E5%85%A5

- 以vue-cli为例

```js
// 需要提前安装依赖：npm i style-resources-loader -D

// vue.config.js
const path = require('path')

module.exports = {
  chainWebpack: config => {
    // 设置缩写
    config.resolve.alias
      .set('@', resolve('src')) 
      .set('_c', resolve('src/components'))
    
    // 设置全局样式自动导入
    const types = ['vue-modules', 'vue', 'normal-modules', 'normal']
    types.forEach(type => addStyleResource(config.module.rule('stylus').oneOf(type)))
  },
}

function addStyleResource (rule) {
  rule.use('style-resource')
    .loader('style-resources-loader')
    .options({
      patterns: [
        // index.less 文件中可以定义全局变量或者全局样式，或者导入其他样式文件
        path.resolve(__dirname, './src/assets/theme/default/index.less'),
      ],
    })
}
```
- main.js引入样式文件、全局样式自动化导入、vue文件中样式关系
    - 优先级：vue文件样式 > 全局样式自动化导入 > main.js引入样式文件
    - 全局样式自动化导入中使用`/deep/`有效；main.js引入样式文件中`/deep/`无效，直接写即可修改第三方组件样式
    - main.js引入文件作用域
        - 引入的 css 都是全局生效的
        - 引入的 js 文件只在 main.js 中生效。是因为 main.js 在webpack中是一个模块，引入的 js 文件也是一个模块，在其他地方是访问不到的，这就是ES6的模块化。所以如果想 main.js 引入的 js 全局可用，就需要绑定到全局对象上，比如绑定 Vue 上

### 样式使用举例

```less
// src/assets/theme/default/index.less
@import "main.less";

@default-color: #ff6633;
@default-color__change: #ff8d66;

// src/assets/theme/default/main.less
.sq-color {
    color: @default-color;
    &:active,&.active,&:hover {
        color: @default-color__change;
    }
}
.ivu-btn.sq-btn__primary {
    color: #fff;
    background-color: @default-color;
    border-color: @default-color;
    &:active,&.active,&:hover {
        color: #f2f2f2;
        background-color: @default-color__change;
        border-color: @default-color__change;
    }
    /*空心按钮*/
    &.sq-btn__empty{
        color: @default-color;
        background-color: #fff;
        border-color: @default-color;
        &:active,&.active,&:hover {
            color: @default-color__change;
            background-color: #f2f2f2;
            border-color: @default-color__change;
        }
    }
}
```




---

参考文章

[^1]: https://www.cnblogs.com/-ding/p/6339740.html (动态组件)
[^2]: https://segmentfault.com/a/1190000008879966#articleHeader14 (vue生命周期)
[^3]: https://asyncoder.com/2018/07/20/%E8%AE%B0%E4%B8%80%E6%AC%A1Vue%E4%B8%AD%E7%9A%84v-for%E8%B8%A9%E5%9D%91%E4%B9%8B%E6%97%85/
[^4]: https://juejin.im/post/5b4ca076f265da0f900e0a7d


