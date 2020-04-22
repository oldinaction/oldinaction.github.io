---
layout: "post"
title: "vue"
date: "2018-04-03 17:14"
categories: [web]
tags: vue
---

## 基本

### 约定俗成

- 习惯
    - 项目url固定链接不以`/`结尾，使用地方手动加`/`方便全局搜索
- 注意
    - **vue单文件组件，每个文件里面只能含有一个script标签；如果含有多个，默认只解析最后一个**

### 文件引入
 
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

### vue组件

```html
<template>

</template>

<script>
import { myUtil } from '@/libs/util'

export default {
  name: 'component_name',
  data () {
    return {
    }
  },
  created () {
    this.init()
  },
  methods: {
    myUtil: myUtil, // 这样才可以在模板中使用：{{ myUtil }}
    init () {
      this.fetchData ()
    },
    fetchData () {
    }
  }
}
</script>

<style lang="less" scoped>
</style>
```

### vue生命周期(含路由)

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
- 浏览器地址栏刷新/回车/F5
    - 所有页面组件重新创建，重头调用`beforeCreate`；且在某页面刷新时，改页面的`beforeDestroy`等钩子不会被执行

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
    - **由于 JavaScript 的限制，Vue 不能检测以下变动的数组**
        - 当你利用索引直接设置一个项时，例如：`vm.items[indexOfItem] = newValue`。如v-for循环想动态给item增加属性，此时只能先定义一个List，动态在方法中设置此List值，并通过JSON进行转换赋值
        - 当你修改数组的长度时，例如：`vm.items.length = newLength`
    - **由于 JavaScript 的限制，Vue 不能检测对象属性的添加或删除**

        ```js
        var vm = new Vue({
            data:{
                a: 1,
                user: {
                    name: null
                }
            }
        })
        // `vm.a` 是响应的，`vm.b` 是非响应的(添加新属性)
        vm.b = 2
        vm.user.name = 'smalle' // 是响应的
        vm.user.password = '123456' // 是非响应的(添加新属性)
        ```
- **vue无法检测数组的元素变化(包括元素的添加或删除)；可以检测子对象的属性值变化，但是无法检测未在data中定义的属性或子属性的变化**
    - 解决上述数组和未定义属性不响应的方法：**`this.user = JSON.parse(JSON.stringify(this.user));`**(部分场景可使用`this.user = Object.assign({}, this.user);`)
    - **对于v-for，最好定义key值**，否则容易出现无法选择/无法修改该select的值，导致数据响应不触发
        - 如结合select的option循环时，只需要当前select的option的key值唯一，无需整个页面的key值唯一)保证唯一性
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
- vue的data对象对应属性

```json
{
  // 其他特殊顶层属性
  key: 'myKey',
  ref: 'myRef',
  // 和`v-bind:class`一样的 API
  // class: 'class-name'
  'class': {
    foo: true,
    bar: false
  },
  // 和`v-bind:style`一样的 API
  style: {
    color: 'red',
    fontSize: '14px',
    paddingRight: '10px'
  },
  // 正常的 HTML 特性
  attrs: {
    id: 'foo'
  },
  // 组件 props
  props: {
    myProp: 'bar'
  },
  // DOM 属性
  domProps: {
    innerHTML: 'baz'
  },
  // 事件监听器基于 `on`
  // 所以不再支持如 `v-on:keyup.enter` 修饰器
  // 需要手动匹配 keyCode。
  on: {
    click: this.clickHandler
  },
  // 仅对于组件，用于监听原生事件，而不是组件内部使用 `vm.$emit` 触发的事件。
  nativeOn: {
    click: this.nativeClickHandler
  },
  // 自定义指令。注意事项：不能对绑定的旧值设值
  // Vue 会为您持续追踪
  directives: [
    {
      name: 'my-custom-directive',
      value: '2',
      expression: '1 + 1',
      arg: 'foo',
      modifiers: {
        bar: true
      }
    }
  ],
  // Scoped slots in the form of
  // { name: props => VNode | Array<VNode> }
  scopedSlots: {
    default: props => createElement('span', props.text)
  },
  // 如果组件是其他组件的子组件，需为插槽指定名称
  slot: 'name-of-slot'
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
        // Poptip-Tag
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

        // Poptip-xxx
        (function(vm) {
            return params.row.content
        }(this)),
        
        // Poptip-div
		h('div', {
			slot: 'content'
		}, [
			h('p', {
				style: {
					padding: '4px'
				}
			}, '用户名：' + params.row.name)
        ]),
        
        // Poptip-div
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

### transition 动画

- 参考：[API](https://cn.vuejs.org/v2/api/#transition)、[guide](https://cn.vuejs.org/v2/guide/transitions.html)

```html
<!-- 
    name：用于自动生成 CSS 过渡类名。例如：name: 'fade' 将自动拓展为.fade-enter，.fade-enter-active等，只需要提前定义好对应的css即可
    mode：控制离开/进入的过渡时间序列。有效的模式有 "out-in" 和 "in-out"；默认同时生效
    tag：<transition> 它会以一个真实元素呈现：默认为一个 <span>，可以通过 tag 属性更换为其他元素
    @after-enter：绑定进入后的事件，还有其他事件可以监听
-->
<transition name="fade" mode="out-in">
    <!-- transition 只能包含一个根节点，两个可以使用 v-if/v-else 或动态组件 -->
    <span v-if="true"></span>
    <span v-else></span>
</transition>

<!-- 只能用于列表过渡(v-for)，列表需要有唯一key -->
<transition-group name="list" tag="p">
    <span v-for="item in items" :key="item">{{ item }}</span>
</transition-group>
```

### 报错 You may have an infinite update loop in a component render function

- 参考：https://www.itread01.com/content/1541599683.html
- `render method is triggered whenever any state changes` vue组件中任何属性改变致使render函数重新执行。如果在模板中直接修改vue属性或调用的方法中修改了属性(如双括号中，而@click等事件中是可以修改vue属性的)，就会导致重新render。从而产生**render - 属性改变 - render**无限循环

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
            event: 'change' // 只能代表本组件中的事件，默认是input
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
                if (n !== o) this.model = this.value // 此处保证了父组件(调用MyEleSelect的组件)可以将最近的值更新到model中(从而传递到<el-select>中)
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
- **通过`$refs`属性，父组件可直接取得、修改、调用子组件的数据**
    - 场景还原：父组件点击按钮，控制显示子组件的弹框(`iview`弹框)，此时当`iview`弹框关闭时会修改`v-model`的值，如果用`props`则违反了`props`单向数据流的原则
    - `ref`可以用于标记一个普通元素或组件
    - `$refs`只有`mounted`了之后才能获取到数据
- 在子组件中可以通过`$parent`调用父组件属性和方法，**修改父组件的属性也不会报错**。注意：像被iview的TabPane包裹的组件，其父组件就是TabPane
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
        default: () => [] // 或者 default: () => {}
        // default: function() {
        //     return [];
        // }
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

### keep-alive [^5]

- 默认被切换掉（非当前显示）的组件，是直接被移除了。假如需要子组件在切换后，依然需要他保留在内存中，避免下次出现的时候重新渲染，可使用`keep-alive`
- 用法

    ```html
    <!-- 缓存动态组件 -->
    <keep-alive>
        <component :is="view"></component>
    </keep-alive>

    <!-- 多个条件判断的子组件 -->
    <keep-alive>
        <comp-a v-if="a > 1"></comp-a>
        <comp-b v-else></comp-b>
    </keep-alive>

    <!-- 缓存路由组件，可以将所有路径匹配到的路由组件都缓存起来，包括路由组件里面的组件。如果使用include属性则可有条件的缓存 -->
    <keep-alive>
        <router-view></router-view>
    </keep-alive>
    ```
- 生命周期钩子：在被keep-alive包含的组件/路由中，会多出两个生命周期的钩子 `activated` 与 `deactivated`(写在匹配到的组件中)
    - activated：在第一次渲染时和之后激活都会被调用
    - deactivated：组件被停用(离开路由)时调用，使用了keep-alive就不会调用beforeDestroy(组件销毁前钩子)和destroyed(组件销毁)，因为组件没被销毁，被缓存起来了
- `include` 和 `exclude`(Vue2.1.0新增，之前版本可通过其他方式代替)

    ```html
    <!-- 缓存路由 -->
    <!-- 逗号分隔字符串 -->
    <keep-alive include="a,b">
        <component :is="view"></component>
    </keep-alive>

    <!-- 正则表达式 (使用 `v-bind`) -->
    <keep-alive :include="/a|b/">
        <component :is="view"></component>
    </keep-alive>

    <!-- 数组 (使用 `v-bind`) -->
    <keep-alive :include="['a', 'b']">
        <component :is="view"></component>
    </keep-alive>

    <!-- 缓存路由，仍然可以使用数组 -->
    <keep-alive include='a'>
        <router-view></router-view>
    </keep-alive>
    ```
    - 匹配规则
        - 首先匹配组件的name选项，如果name选项不可用
        - 则匹配它的局部注册名称(父组件 components 选项的键值)
        - 匿名组件，不可匹配(比如路由组件没有name选项时，并且没有注册的组件名)
        - 只能匹配当前被包裹的组件，不能匹配更下面嵌套的子组件(比如用在路由上，只能匹配路由组件的name选项，不能匹配路由组件里面的嵌套组件的name选项)
        - `<keep-alive>`不会在函数式组件中正常工作，因为它们没有缓存实例
        - exclude的优先级大于include

## 事件

### 示例

```html
<!-- stop阻止冒泡，prevent阻止原生事件(如表单提交页面刷新) -->
<a v-on:click.stop.prevent="doThis"></a>
<!-- 只当事件在该元素本身点击时触发事件，子元素点击则不执行 -->
<div @click.self="doThat"></div>

<!-- 关于click事件不生效，以iview的Drawer组件为例 -->
<template>
  <!-- 点击后不会执行a函数，因为Drawer实际渲染dom并不在此div中 -->
  <div @click.native="a">
    <!-- 点击后会执行c函数，此处表示使用原生click事件 -->
    <Drawer @click.native="c"></Drawer>

    <!-- ** 点击后不会执行b函数 **，因为Drawer组件并没有定义click事件 -->
    <Drawer @click="b"></Drawer>
  </div>
<template>
```

### 鼠标点击其他区域事件

- 基于指令
    - 简易版本参考：https://www.jianshu.com/p/9e1c241d8edb
    - iview版本参考：iview/src/directives/v-click-outside-x.js

### 监控全局点击事件(不推荐)

```js
// 1. main.js
// 定义全局点击函数
Vue.prototype.globalClick = function (callback) {
  document.getElementById('app').onclick = function (e) {
      callback(e)
  }
}

// 2. 组件中使用
mounted () {
    this.globalClick(this.handleGlobalClick)
},
methods: {
    handleGlobalClick (e) {
        // 修改data数据不会更新到dom，可以watch到
    }
}
```

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
/* less/sass格式如：`外层 /deep/ 第三方组件 {样式}`(外层也可省略)，stylus则是将 /deep/ 换成 >>> */
.wrapper /deep/ .ivu-table th {
    background-color: #eef8ff;
}
</style>
```

### 全局样式/自动化导入

> https://cli.vuejs.org/zh/guide/css.html#%E8%87%AA%E5%8A%A8%E5%8C%96%E5%AF%BC%E5%85%A5

- 以vue-cli自动导入stylus为例

```js
npm i style-resources-loader -D // 需要提前安装依赖
// npm i sass-resources-loader -D // sass/less 

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
        // index.less 文件中可以定义全局变量或者全局样式，或者导入其他样式文件 (不能使用别名路径)
        path.resolve(__dirname, './src/assets/theme/default/index.less'),
      ],
    })
}
```
- less/sass为例(stylus亦可)

```bash
# 更新vue cli到3.0以上
vue --version # @vue/cli 4.3.0
npm install -g @vue/cli

# 增加依赖(会将相应依赖添加到package.json)
vue add style-resources-loader

# vue.config.js 配置
module.exports = {
    pluginOptions: {
        'style-resources-loader': {
            preProcessor: 'less',
            patterns: [path.resolve(__dirname, 'src/styles/theme/index.less')]
        }
    }
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

## 路由

> https://yuchengkai.cn/blog/2018-07-27.html 源码解析

### 基本概念

- 路由生命周期见上文
- `query`和`params`的区别
    - query参数会拼接到url上面，param不会
    - param的参数值可以赋值给路由路径中的动态参数。因此使用param时路由跳转后再次刷新页面会导致参数丢失

```js
this.$router.push({
    name: "VisitInfo",
    query: Object.assign({}, contact, {
        visitId: this.visitId
    })
});
```
- `$route`和`$router`区别
    - `$route`为当前路由，为vue内置
    - `$router`为路由管理器(全局的)，一般在main.js中new Vue()时挂载

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
- push和replace的区别
    - 编程式`router.push(...)`和声明式`<router-link :to="...">`类似，都是往 history 栈添加一个新的记录，所以，当用户点击浏览器后退按钮时，则回到之前的 URL
    - `router.replace(...)`和`<router-link :to="..." replace>`类似，它们不会向 history 添加新记录，而是替换掉当前的 history 记录
    - `router.go(n)`类似`window.history.go(n)`
- 动态路由、嵌套路由、`<router-view />`
    - 实现嵌套路由有两个要点：在组件内部使用`<router-view />`标签、VueRouter 的参数中使用 children 配置

> 嵌套路由（https://router.vuejs.org/zh/guide/essentials/nested-routes.html）

```js
<div id="app">
  <router-view></router-view>
</div>

// 此时由于visit_info基于Mobile的，因此Mobile中必须要有一个路由出口(<router-view />)来展示visit_info。即表示含有children属性的组件(Mobile)的template中必须要有一个<router-view />
const routers = [{
  // 访问 /m 时，会将Mobile渲染到app的router-view中，相当于渲染顶级组件
  path: "/m",
  name: "mobile",
  component: Mobile,
  children: [{
    // 当访问 /m/visit/info/1 时，会将visit_info.vue渲染到其父组件(Mobile)的router-view中，因此此时Mobile需要有一个<router-view />的出口
    // 如果父组件中没有router-view路由出口，则此子组件将无妨成功created；且只有当路由到此子路径时，才会开始创建此子组件(仅访问父路径不会创建子组件)
    path: "visit/info/:info_id", // path带/表示绝对路径。此时不带/。要通过name=visit_info路由(且路由params参数中info_id=1)进来时，url会自动变成/m/visit/info/1
    name: "visit_info",
    meta: {
      title: "拜访编辑"
    },
    component: () => import("@/views/mobile/visit_info.vue")
  }]
}]
```
- 路由懒加载(当打包构建应用时，Javascript 包会变得非常大，影响页面加载速度)
    - https://router.vuejs.org/zh/guide/advanced/lazy-loading.html
    - https://panjiachen.github.io/vue-element-admin-site/zh/guide/advanced/lazy-loading.html

### 路由变化页面数据不刷新

- 参考上文【父子组件加载】中的示例，监控`$route`变化

> 官方说明 https://router.vuejs.org/zh/guide/essentials/dynamic-matching.html#%E5%93%8D%E5%BA%94%E8%B7%AF%E7%94%B1%E5%8F%82%E6%95%B0%E7%9A%84%E5%8F%98%E5%8C%96

- 当使用路由参数时，例如参数 `/user/:username`，且从 /user/foo 导航到 /user/bar，原来的组件实例会被复用
    - 因为两个路由都渲染同个组件(User)，比起销毁再创建，复用则显得更加高效
    - 不过这也意味着组件的生命周期钩子(如created)不会再被调用
    - 但是两个路径显示的data数据是缓存两份，不会覆盖

```js
const router = new VueRouter({
  routes: [
    // 动态路径参数，以冒号开头，通过route.params.userId传递参数。从路由中获取的参数均为字符串，Id一般需要通过Number()转换一下，防止后面 === 比较不正确
    { path: '/user/:userId', component: User }
  ]
})

// 解决办法(都会看到之前的数据突然刷新成了新的数据)。根据路由获取数据：https://router.vuejs.org/zh/guide/advanced/data-fetching.html
const User = {
    template: '...',
    watch: {
        // 观测 $route 时组件第一次创建和挂载都不会监测(触发)到，因此需要和created/mounted等结合使用
        // 只要此组件在声明周期中就会，此方法就会一致监测到变化并执行逻辑(尽管此组件的元素没有显示在浏览器中也会如此)
        // 单引号可以省略
        '$route' (to, from) {
            if (to.name == "XXX") {
                // 对路由变化作出响应...
                this.init();
            }
        }
    },
    // 页面路由钩子(还有全局路由钩子)：https://router.vuejs.org/guide/advanced/navigation-guards.html
    beforeRouteEnter (to, from, next) {
        // 在渲染该组件的对应路由被 confirm 前调用，不！能！获取组件实例 `this`，因为当守卫执行前，组件实例还没被创建
        // don't forget to call next()，下同
        next(vm => {
            // vm === this; mounted了之后才会调用next
        })
    },
    beforeRouteUpdate (to, from, next) {
        // 在当前路由改变，但是该组件被复用时调用
        // 举例来说，对于一个带有动态参数的路径 /foo/:id，在 /foo/1 和 /foo/2 之间跳转的时候，由于会渲染同样的 Foo 组件，因此组件实例会被复用。而这个钩子就会在这个情况下被调用。
        // 可以访问组件实例 `this`
    },
    beforeRouteLeave (to, from, next) {
        // 导航离开该组件的对应路由时调用
        // 可以访问组件实例 `this`
    },
    created() {
        this.init()
    },
    methods: {
        init() {
            this.userId = Number(this.$route.params.userId)
            this.fetchData()
        },
        fetchData() {}
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
        - router.beforeEach 中执行 next({..from}) 跳转后，不会执行afterEach()；而history模式会在执行一次beforeEach后执行afterEach。参考 https://www.okcode.net/article/70038
    - history模式
        - 前进、后退不会请求后端，**但是刷新、f5会请求后端**(nginx)，如果后端无浏览器地址栏中的路径则会404
        - 缺点：需要浏览器支持(IE=10)，刷新可能会出404
    - 两种模式对于router.push、replace、go的效果一致
- history模式使用(https://router.vuejs.org/zh/guide/essentials/history-mode.html)

```js
// 开启history模式
const router = new Router({
  routes,
  mode: 'history' // 默认为hash模式
})

// 如后端nginx服务器配置
location / {
  try_files $uri $uri/ /index.html;
}
```

## Vuex

- [Vuex](https://vuex.vuejs.org/zh/)
- 刷新浏览器地址会导致vuex的state状态丢失，一般是默认给state的相应属性赋值Cookie的值或者在使用的地方通过Cookie重新获

```js
import Cookies from 'js-cookie'

const user = {
  // 开启严格模式，仅需在创建 store 的时候传入 strict: true。在严格模式下，无论何时发生了状态变更且不是由 mutation 函数引起的，将会抛出错误
  strict: process.env.NODE_ENV !== 'production'
  // 状态
  // this.$store.state.name 或 this.$store.user.state.name(被嵌入到modules)
  state: {
    token: Cookies.get('X-Token'), // 刷新浏览器后，初始化时数据线从Cookies中获取
    name: '' // 刷新浏览器数据会丢失
  },
  // 更改 Vuex 的 store 中的状态的唯一方法是提交 mutation。它会接受 state 作为第一个参数
  // 调用：this.$store.commit('SET_TOKEN', 'my-token-xxx') 
  mutations: {
    SET_TOKEN: (state, token) => {
      state.token = token
    },
    SET_NAME: (state, name) => {
      state.name = name
    }
  },
  // Action 类似于 mutation，不同在于：Action 提交的是 mutation，而不是直接变更状态；Action 可以包含任意异步操作
  // 调用：this.$store.dispatch('Login')
  actions: {
    Login({ commit }, userInfo) {
      const username = userInfo.username.trim()
      return new Promise((resolve, reject) => {
        login(username, userInfo.password).then(data => {
          setToken(data.token) // 存储在 Cookies
          commit('SET_TOKEN', data.token)
          resolve()
        }).catch(error => {
          reject(error)
        })
      })
    }
  },
  // 引入其他模块
  // 调用：this.$store.permission.state.access
  modules: {
    permission // Vuex对象
  }
}

export default user
```

## JSX使用

- vue的jsx语法是基于[babel-plugin-transform-vue-jsx](https://github.com/vuejs/babel-plugin-transform-vue-jsx)插件实现的 [^7]

    ![vue-jsx](/data/images/web/vue-jsx.png)
- 使用vue-cli3则不需要手动安装上述babel插件即可使用（否则会报错Duplicate declaration "h"）。其他方式需要手动安装

```bash
npm install babel-plugin-syntax-jsx babel-plugin-transform-vue-jsx babel-helper-vue-jsx-merge-props babel-preset-env --save-dev

# .babelrc文件中增加配置
"plugins": ["transform-vue-jsx"]
```
- 使用 [^6] [^7]
    - babel插件会通过正则匹配的方式在编译阶段将书写在组件上属性进行分类
        - onXXX的均被认为是事件，nativeOnXXX是原生事件，domPropsXXX是Dom属性，class、staticClass、style、key、ref、refInFor、slot、scopedSlots这些被认为是顶级属性，至于组件声明的props，以及html属性attrs，不需要加前缀，插件会将其统一分类到attrs属性下，然后在运行阶段根据是否在props声明来决定属性归属
        - 不建议声明onXXX的属性
    - 对于原生指令，只有v-show是支持的。v-if可用(&& 或 ?:)代替；v-for代替array.map；v-model使用事件触发；自定义指令使用...解构
    - 对于事件
        - 使用 `on-[eventName]` 格式, 比如 on-click-two, on-click, on-camelCaseEvent
        - 使用 `on[eventName]` 格式，比如 onClick, onCamelCaseEvent。click-two 需要这样写 onClick-two，onClickTwo 是不对的
        - 使用 spread 语法，即 `{...{on: {event: handlerFunction}}}`
- 示例

```js
// v-if使用 && 代替，v-if 和 v-else 使用 ?: 代替
render() {
    return (
        <div class='wrapper'>
        {
            this.hello && (<div class='content'>hello</div>)
        }
        </div>
    )
}

// v-for使用 array.map 代替
render() {
    return (
      <div class='wrapper'>
        <ul>
          {
            this.items.map(item => (
              <li>{ item.name }</li>
            ))
          }
        </ul>
      </div>
    )
}

// v-model
render() {
    return (
        <component
            // 保证value会随着this.test进行变化
            value={ this.test }
            // 保证组件的值可以传递给this.test
            onInput={ val => { this.test = val } }
        >
        </component>
    )
}

// iview的部分组件，此时只能使用下划线，如：Button需要是i-button。更多见官网
{
    title: '计划日期',
    key: 'planTm',
    render: (h, params) => {
        return (
            <date-picker type="date" value={ params.row.planTm } on-on-change={ v => { this.planTm = v } } />
        )
    }
}
```

## vue-cli v3

- 安装

```bash
npm install -g @vue/cli
vue --version # @vue/cli 4.3.0
```



---

参考文章

[^1]: https://www.cnblogs.com/-ding/p/6339740.html (动态组件)
[^2]: https://segmentfault.com/a/1190000008879966#articleHeader14 (vue生命周期)
[^3]: https://asyncoder.com/2018/07/20/%E8%AE%B0%E4%B8%80%E6%AC%A1Vue%E4%B8%AD%E7%9A%84v-for%E8%B8%A9%E5%9D%91%E4%B9%8B%E6%97%85/
[^4]: https://juejin.im/post/5b4ca076f265da0f900e0a7d
[^5]: https://juejin.im/post/5b41bdef6fb9a04fe63765f1
[^6]: https://www.yuque.com/zeka/vue/vu60wg
[^7]: https://www.njleonzhang.com/2018/08/21/vue-jsx.html


