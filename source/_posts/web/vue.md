---
layout: "post"
title: "vue"
date: "2018-04-03 17:14"
categories: [web]
tags: vue
---

## 基本

- 参考文章
    - https://juejin.cn/post/6844903476661583880
- vue异常代码开发环境正常报错，编译之后不报错且页面卡死问题。参考: https://github.com/PanJiaChen/vue-element-admin/issues/2212

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

- 文件名建议大写开头驼峰或者小写下划线分割。windows下组件文件名对大小写不敏感，linux下组件文件名对大小写敏感

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
        - 先执行created同步代码, 执行mounted同步代码, 无法控制created中的异步代码执行完后再执行mounted
    - 全局路由钩子：2个 (beforeEach、afterEach)
    - 组件路由钩子：3个 (beforeRouteEnter、beforeRouteUpdate、beforeRouteLeave)
    - 指令的周期： 5个 (bind、inserted、update、componentUpdated、unbind)
    - beforeRouteEnter的next所对应的周期
    - nextTick所对应的周期
    - `<keep-alive>` 组件 `activated` 和 `deactivated`
- 钩子执行顺序
    - 路由勾子 (beforeEach、beforeRouteEnter、afterEach)
    - App根组件 (beforeCreate、created、beforeMount)
    - 父组件-mixins (beforeCreate、created、beforeMount): 父组件 beforeCreate -> mixins beforeCreate -> 父组件 created -> ...
    - 组件 (beforeCreate、created、beforeMount)
    - 指令 (bind、inserted)
    - 组件 mounted
    - 父组件-mixins (mounted)
    - App根组件 (mounted)
    - beforeRouteEnter的next的回调
    - nextTick
- 销毁顺序
    - mixins (beforeDestroy)
    - 父组件 (beforeDestroy)
    - 组件 (beforeDestroy)
    - 组件 (destroyed)
    - mixins (destroyed)
    - 父组件 (destroyed)
- 浏览器地址栏刷新/回车/F5
    - 所有页面组件重新创建，重头调用`beforeCreate`；且在某页面刷新时，该页面的`beforeDestroy`等钩子不会被执行

### 后端模板中使用VUE

- 主页面

```html
<head>
    <!-- 引入vue.js等通用js -->
    <#include "./common/resource.ftl">
    <!-- 引入所有需要使用的组件 -->
    <#include "./components/my-widget.ftl">
    <style>
        [v-cloak]{
            display: none;
        }
    </style>
</head>
<body>
    <!-- 当网络较慢，网页还在加载 Vue.js ，而导致 Vue 来不及渲染，这时页面就会显示出 Vue 源代码。我们可以使用 v-cloak 指令来解决这一问题 -->
    <div id="app" v-cloak>
        {{name}}
        <my-widget-test ref="test"></my-widget-test>
    </div>
</body>
```
- 组件页面

```html
<!-- 模板的一部分 my-widget.ftl -->
<script type="text/x-template" id="widget">
    <div>content</div>
</script>
<script>
    Vue.component('my-widget-test', {
        template: '#widget',
        data() {
            return {}
        }
    })
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

### 数组/对象改变数据不刷新问题

- [官方说明](https://cn.vuejs.org/v2/guide/reactivity.html#%E6%A3%80%E6%B5%8B%E5%8F%98%E5%8C%96%E7%9A%84%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9)
    - **由于 JavaScript 的限制，Vue 不能检测以下变动的数组**
        - 当你利用索引直接设置一个项时，例如：`vm.items[indexOfItem] = newValue`。如v-for循环想动态给item增加属性，此时只能先定义一个List，动态在方法中设置此List值，并通过JSON进行转换赋值
        - 当你修改数组的长度时，例如：`vm.items.length = newLength`
        - [下列方法可触发视图更新](https://cn.vuejs.org/v2/guide/list.html#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9)
            - push()、pop()、shift()、unshift()、splice()、sort()、reverse()
    - **由于 JavaScript 的限制，Vue 不能检测对象属性的添加或删除**

        ```js
        var vm = new Vue({
            data:{
                a: 1,
                user: {
                    name: null
                },
                list: []
            }
        })

        // `vm.a` 是响应的，`vm.b` 是非响应的(添加新属性)
        vm.b = 2
        vm.user.name = 'smalle' // 是响应的
        vm.user.password = '123456' // 是非响应的(添加新属性)

        vm.list = [{name: 'hello'}] // 响应的
        vm.list[0].name = 'smalle' // 响应的

        // 假设有一个按钮需要动态添加loading，可写成<Button :loading="myLoading[i]"></Button>，然后created之后对myLoading[i]赋初始值并重新设置myLoading(两次JSON转换)，之后myLoading[i]就可以动态监听了
        ```
    - Vue.set和Vue.delete的作用
        - `Vue.set` 向响应式对象中添加一个 property，并可确保这个新 property 同样是响应式的. eg: Vue.set(this.dictMap, key, list)
        - **也可使用如`this.$set(row, '_editLoading', true)`，常用于表格单行按钮loading效果**
    - Vue3.X新版本开始将采用ES6的Proxy来进行双向绑定。可解决上述问题(可以直接监听对象而非属性，可以直接监听数组下标的变化)
- **vue无法检测数组的元素变化(包括元素的添加或删除)；可以检测子对象的属性值变化，但是无法检测未在data中定义的属性或子属性的变化**
    - 解决上述数组和未定义属性不响应的方法：**`this.user = JSON.parse(JSON.stringify(this.user));`**(部分场景可使用`this.user = Object.assign({}, this.user);`)
    - **对于v-for，最好定义key值(且不能使用index作为key)**，否则容易出现无法选择/无法修改该select的值
        - 如结合select的option循环时，只需要当前select的option的key值唯一，无需整个页面的key值保证唯一性
        - 大多数情况下不建议使用index作为key。当第一条记录被删除后，第二条记录的key的索引号会从1变为0，这样导致oldVNode和newNNode两者的key相同。而key相同时，Virtual DOM diff算法会认为它们是相同的VNode，那么旧的VNode指向的Vue实例(如果VNode是一个组件)会被复用，导致显示出错 [^3]
- provide和inject无法实时响应解决办法
    - https://www.jianshu.com/p/2f210939cc4e
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
        // 监控某个子属性，在部分场景可取代 deep: true 的全监控(效率更高)
        'customer.province.name': {
            handler(n, o) {
            },
            immediate: true
        },
        // 扩展：观测整个对象的变化
        customer: {
            handler(newValue, oldValue) {
                console.log(newValue)
            },
            deep: true // 包括子对象(默认只能监控一个普通值，设置deep则可监控整个对象，否则只能监测到一次对象值改变)
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

### render函数

- [参考vue render属性](https://cn.vuejs.org/v2/guide/render-function.html)

```js
Vue.component('anchored-heading', {
  // render 可代替 template 的 dom 节点
  // template: '#div',
  render: function (createElement) {
    return createElement(
      'h' + this.level,   // 标签名称
      this.$slots.default // 子节点数组
    )
  },
  props: {
    level: {
      type: Number,
      required: true
    }
  }
})
```
- render 语法(iview案例)

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
  // 自定义指令。注意事项：必须是全局指令；不能对绑定的旧值设值
  directives: [
    {
      // 如果在标签上使用是 v-permission，此时需要省略 v-
      name: 'permission',
      value: ['Button_Report_Manage']
    },
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
            // confirm: true
        },
        // on: {
        //     'on-ok': () => {
        //         this.confirm()
        //     }
        // }
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

#### 报错 You may have an infinite update loop in a component render function

- 参考：https://www.itread01.com/content/1541599683.html
- `render method is triggered whenever any state changes` vue组件中任何属性改变致使render函数重新执行。如果在模板中直接修改vue属性或调用的方法中修改了属性(如双括号中，而@click等事件中是可以修改vue属性的)，就会导致重新render。从而产生**render - 属性改变 - render**无限循环

### 页面渲染优化(性能优化)

- 参考文章 [^9] [^12]
- vue渲染流程

![vue-render](/data/images/web/vue-render.png)

- [Chrome Devtool  Performance使用](https://developers.google.com/web/tools/chrome-devtools/evaluate-performance/)

#### 打包优化

- 采用懒加载 [^13]
    - 将 `import Hello from '@/components/Hello'` 改成 `const Hello = () => import('@/components/Hello')`。本质上，它是利用了Promise
    - 如使用动态加载的路由配置方式

        ```js
        // 未使用：打包后代码在一个 chunk-vendors 文件中
        import Hello from '@/pages/Hello'
        {
            path: 'hello1',
            name: 'hello1',
            component: Hello
        }

        // 使用动态加载的路由配置方式：打包后代码被分散到多个 chunk-* 文件中，之后客户端可按需加载
        {
            path: 'hello2',
            name: 'hello2',
            component: () => import('@/pages/Hello')
        }
        ```
- 启用 Gzip 压缩（以下两种方式建议同时进行）
    - 开启nginx等服务器gzip。参考[nginx.md#配置示例](/_posts/arch/nginx.md#配置示例)
    - 使用 [compression-webpack-plugin](https://www.webpackjs.com/plugins/compression-webpack-plugin/) 将静态资源提前压缩成 gz 格式，且nginx开启`gzip_static on;`，就不用在服务器进行压缩。参考[nginx.md#配置示例](/_posts/arch/nginx.md#配置示例)。速度比服务器压缩要更快，且传输资源更少

        ```js
        npm install compression-webpack-plugin --save-dev

        // vue-cli为例。开发环境不进行压缩，否则页面无法显示
        chainWebpack: config => {
            if(process.env.NODE_ENV === 'production') {
                const CompressionPlugin = require('compression-webpack-plugin');
                config.plugin('compressionPlugin')
                .use(new CompressionPlugin({
                    algorithm: 'gzip',
                    test: /\.(js|css|json|txt|html|ico|svg)(\?.*)?$/i,
                    threshold: 10240,
                    minRatio: 0.8
                    // ,deleteOriginalAssets: true // 是否删除原资源，即只保留 .gz 文件。Electron打包需要保留原资源，否则安装包找不到相应js文件
                }));
            }
        }
        ```
- 将依赖库挂到 CDN 上。可以提高首屏响应速度
    - 常用CDN服务商
        - [bootcdn](https://www.bootcdn.cn/)
        - [七牛云](http://staticfile.org/)
        - [又拍云](http://jscdn.upai.com/)
        - [unpkg](https://unpkg.com/)
        - [jsdelivr](https://www.jsdelivr.com/)
        - [cdnjs](https://cdnjs.net/)
    - 在 `public/index.html` 中引入库，部分代码如下

        ```html
        <body>
            <div id="app"></div>
            <!-- built files will be auto injected -->
            <!-- 方式一：引入相应版本的库文件 -->
            <script src="https://cdn.bootcss.com/vue/2.6.10/vue.min.js"></script>
            <script src="https://cdn.bootcss.com/vue-router/3.0.7/vue-router.min.js"></script>
            <script src="https://cdn.bootcss.com/vuex/3.1.1/vuex.min.js"></script>
            <script src="https://cdn.bootcss.com/axios/0.19.0/axios.min.js"></script>
            <script src="https://cdn.bootcss.com/element-ui/2.10.1/index.js"></script>

            <!-- 方式二： -->
            <% for (var i in htmlWebpackPlugin.options.cdn && htmlWebpackPlugin.options.cdn.js) { %>
            <script src="<%= htmlWebpackPlugin.options.cdn.js[i] %>" defer></script>
            <% } %>
        </body>
        ```
    - 配置

        ```js
        // 然后在 webpack(vue-cli为例) 中配置额外依赖(两种方式都需要)
        configureWebpack: {
            externals: {
                'vue': 'Vue',
                'vue-router': 'VueRouter',
                'vuex': 'Vuex',
                'element-ui': 'elementUI',
                'axios': 'axios',
            }
        },
        // 方式二：注入cdn参数到htmlWebpackPlugin
        chainWebpack: config => {
            let cdn = {
                js: ['https://cdn.bootcss.com/vue/2.6.10/vue.min.js']
            }
            cdn = process.env.NODE_ENV === 'production' ? cdn : {css:[],js:[]};
            config.plugin('html').tap(args => {
                args[0].cdn = cdn
                return args
            })
        }

        // 删除 package.json 的 dependencies 中此插件的依赖

        // vue 页面可正常使用，无需修改
        import Vue from 'vue'
        ```
- 减少不必要的库依赖

    ```js
    // 方式一(不推荐)：手动增加webpack-bundle-analyzer分析插件(vue-cli自带无需安装，参考方式二)
    // 包依赖分析工具
    npm install webpack-bundle-analyzer --save-dev
    // vue-cli为例。执行 npm run build 后会自动打开 http://127.0.0.1:8888/ 显示包依赖信息。**使用完之后可注释此行代码，否则命令行一直不会退出，给人一种没打包完成的错觉**
    chainWebpack: config => {
        if(process.env.NODE_ENV === 'production') {
            const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
            config.plugin('bundleAnalyzerPlugin').use(new BundleAnalyzerPlugin({}))
        }
    }

    // 方式二(推荐)：vue-cli 自带分析插件
    "scripts": {
    	"report": "vue-cli-service build --report --mode pord"
 	}
    // 打包之后在dist文件夹里面会生成report.html文件
    npm run report
    ```
- 去掉 .map 文件：vue-cli设置`productionSourceMap: false`，参考下文[vue-cli](#vue-cli)
- 使用 UglifyJsPlugin 丑化js，去掉debugger/console等信息
- 使用`cnpm i -save-dev image-webpack-loader`对图片进行压缩
- 测试环境和生产环境出来的包不一致问题
    - 测试环境 js 文件在 dist 根目录下，且存在很大的 main.js 和 app.js；build 打包之后 js 文件在 dist/js 目录下，main和app也被分割成几个小文件了
    - `NODE_ENV` 为webpack内置参数，可通过`process.env.NODE_ENV`获取，当其值是`production`(固定值)时，会进行压缩混淆等操作。所以测试环境和生产环境打包都应该设置`NODE_ENV=production`，然后通过`.env.test`和`.env.prod`环境变量文件(vue-cli功能)区分不同环境的API地址，如created

        ```js
        // .env.test
        NODE_ENV = production
        VUE_APP_ENV = testenv

        // .env.prod
        NODE_ENV = production
        VUE_APP_ENV = production
        ```
- 公共代码抽离

#### 指令等语法优化

- `v-if` & `v-show` [^8]
    - 生命周期
        - v-if 控制着绑定元素或者子组件实例 重新挂载（条件为真）/销毁（条件为假） 到DOM上，并且包含其元素绑定的事件监听器，会重新开启监听。
        - v-show 控制CSS的切换，元素永远挂载在DOM上
    - 权限问题
        - 涉及到权限相关的UI展示无疑用的是v-if
    - UI操作
        - 初始化渲染，如果要加快首屏渲染，建议用v-if
        - 频次选择，如果是频繁切换使用，建议使用v-show
- `v-key`使用
    - v-for需要配合v-key使用，且不能使用index作为key
- computed 和 watch 区分使用场景
    - 需要进行数值计算，并且依赖于其它数据时，应该使用 computed，因为可以利用 computed 的缓存特性，避免每次获取值时，都要重新计算
    - 需要在数据变化时执行异步或开销较大的操作时，应该使用 watch，使用 watch 选项允许我们执行异步操作(访问一个 API)，限制我们执行该操作的频率

#### Vuex使用及优化

- 参考[Vuex的使用场景](#Vuex的使用场景)
    - 扁平化 Store 数据结构
    - 避免持久化 Store 数据带来的性能问题：对必要数据进行写入；多次写入操作合并为一次
    - 避免持久化存储的容量持续增长

#### 使用Object.freeze()进行优化

- `Object.freeze()`是ES5新增的特性，可以冻结一个对象，防止对象被修改 [^10]
    - const定义的对象不能被重新赋值引用，但是对象属性可进行修改
    - Object.freeze()定义的对象可以重新赋值引用，但是对象属性不能修改
- 当把一个普通的 JavaScript 对象传给 Vue 实例的 data 选项，Vue 将遍历此对象所有的属性，并使用 Object.defineProperty 把这些属性全部转为 getter/setter，以便 Vue 追踪依赖，在属性被访问和修改时通知变化，进行页面重新渲染。但 Vue 在遇到像 Object.freeze() 这样被设置为不可配置之后的对象属性时，不会为对象加上 setter getter 等数据劫持的方法
- 示例

```js
new Vue({
    data: {
        list: []
    },
    mounted () {
        this.fetchData()
    },
    methods: {
        fetchData () {
            // vue不会对list里的object做getter、setter绑定
            this.list = Object.freeze([{ value: 100 },{ value: 200 }])
        },
        changeData () {
            // 界面不会有响应
            this.list[0].value = 200;

            // 下面两种做法，界面都会响应
            this.list = [{ value: 200 },{ value: 200 }]
            this.list = Object.freeze([{ value: 200 },{ value: 200 }])
        }
    }
})
```

#### 优化无限列表性能

- 如果应用存在非常长或者无限滚动的列表，那么采用窗口化的技术来优化性能，只需要渲染少部分区域的内容，减少重新渲染组件和创建 dom 节点的时间
- 开源工具如：[vue-virtual-scroller](https://github.com/Akryum/vue-virtual-scroller) 和 [vue-virtual-scroll-list](https://github.com/tangbc/vue-virtual-scroll-list)

#### 图片资源懒加载

- [vue-lazyload](https://github.com/hilongjw/vue-lazyload) 插件使用

#### 组件懒加载

- 使用组件懒加载在不可见时只需要渲染一个骨架屏，不需要渲染一些隐藏组件
- [插件vue-lazy-component](https://github.com/xunleif2e/vue-lazy-component)

#### 第三方插件的按需引入

- 基于babel-plugin-component插件

#### 服务端渲染/预渲染

- [服务端渲染](https://ssr.vuejs.org/zh/)
- [预渲染插件prerender-spa-plugin](https://github.com/chrisvfritz/prerender-spa-plugin)

## 组件

- [组件原理](http://www.yanfadi.com/vue/#%E5%8D%81-%E7%BB%84%E4%BB%B6%E5%8E%9F%E7%90%86)

### v-model使用

- [官方说明](https://cn.vuejs.org/v2/guide/components-custom-events.html#%E8%87%AA%E5%AE%9A%E4%B9%89%E7%BB%84%E4%BB%B6%E7%9A%84-v-model)
- 双向数据绑定主要需要解决表单元素值改变后对应的变量值同时变化(变量值变化表单元素的值变化是肯定的)
- 在原生表单元素中 `<input v-model="inputValue">` 相当于 `<input v-bind:value="inputValue" v-on:input="inputValue = $event.target.value">`
- 简单弹框案例

```js
<script>
	export default {
		props: {
			value: {
				type: Boolean,
				default: false
			}
		},
		data() {
			return {
				show: this.value
			};
		},
		watch: {
			value (n, o) {
				this.show = this.value
			}
		},
		methods: {
			open() {
				this.show = true;
				this.$emit('input', this.show)
			},
			close() {
				this.show = false;
				this.$emit('input', this.show)
			}
		}
	};
</script>
```
- 扩展案例说明

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
            event: 'change' // ***只能代表本组件中的事件，默认是input***
        },
        props: {
            // ***取得是 v-model="myValue" 中 myValue 的值***
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
                // 如果上面没有定义model.event="change"，则此处的事件必须是'input' (this.$emit('input', this.model))，this.model可为实际值
                // el-select中也有change事件，但是该事件传回的值只能到此组件的v-model中，无法再往外面传输，因此此处必须触发新的事件(本组件中定义的事件)
                // *** 自定义组件中也可以不用有类似的input表单元素，自定义一个model字段名，并指定其model.event，并在此处emit即可修改model ***
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
- **全量绑定props参数**

```html
<!-- 假设子组件接受参数：name, age, sex; dataBind/eventBind中指定的优先级高于dom上指定的属性 -->
<child-component v-bind="dataBind" v-on="eventBind"></child-component>
<!-- 重新包装el-pagination成组件，在使用此组件时将参数全部绑定到el-pagination中 -->
 <el-pagination
    v-bind="$attrs"
/>

<script>
    // 此时子组件参数全部使用默认值
    dataBind = null;
    // 指定部分参数
    dataBind = {
        name: 'smalle',
        // age: 18, // 不传递age则使用默认值
        sex: true,
        xxx: '不接受此参数，传递也不报错'
    }
    // 或者通过 $props 将父组件的 props 一起传给子组件
    dataBind = this.$props;
    eventBind = {
        test: () => {}
    }
</script>
```

#### props定义说明

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
        type: Function, // default省略亦可
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
        <Child ref="child" :show.sync="show" @my-event="myEvent"></Child>
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
                hello: '',
                show: false
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
    <Modal v-model="showView">
        <div>${msg}</div>
        <button @click="triggerMyEvent('msg')">触发子组件事件</button>
    </Modal>
</template>

<script>
    export default {
        name: "child",
        // 组件定义好组件属性名称
        props: ["count", "msg", "show"],
        data: () {
            return {
                showView: false
            }
        },
        watch: {
            show (val) {
                this.showView = val
            },
            showView (val) {
                if (this.show != val) {
                    this.$emit('update:show', val) // 必须触发 update:xxx 才能实现子组件中修改props(双向绑定)
                }
                if (val) {
                    this.childMethod()
                }
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
// 在初始化web app的时候，main.js给data添加一个 名字为eventBus的空vue对象。就可以使用 this.$root.eventBus 获取对象
new Vue({
    el: '#app',
    router,
    render: h => h(App),
    data: {
        eventBus: new Vue()
    }
})

// 在一个组件内调用事件触发。通过this.$root.eventBus获取此对象，调用 $emit 方法
this.$root.eventBus.$emit('eventName', data)

// 在另一个组件调用事件接受(如created)，移除事件监听器使用$off方法(如destroyed)
this.$root.eventBus.$on('eventName', (data) => {
    // 处理数据
})
this.$root.eventBus.$off('eventName')
```

### slot插槽

```html
<!-- 组件comp.vue -->
<div>
    <div v-for="item in list">
        <!-- name为插槽名称，如果只有一个可省略(即为默认插槽)；v-bind:item="item"将item传递到子组件(此处两个item必须一致) -->
        <slot name="content" v-bind:item="item"></slot>
    </div>
</div>

<!-- 组件调用者 -->
<comp>
    <!--插槽实际内容
        1.content为上述插槽名称，如果组件只有一个默认插槽，则此处可将:content换成:default或省略；v2.6开始，具名插槽可缩写为 <template #content="{ item }">
        2.使用了解构获取item；还可使用v-slot:content="props"获取作用域，并通过props.item获取值>
    -->
    <!-- v2.6后：带上指令名，或者缩写成#content，如果是默认的则为#default；需要使用template来渲染 -->
    <!-- <template v-slot:content="{ item }"> -->
    <template #content="{ item }">
        {{ item }}
    </template>

    <!-- v2.6之前(兼容) -->
    <!-- <template slot="content" slot-scope="slotProps"> -->
    <div slot="content"></div>
</comp>
```

### 动态组件/异步组件

- 基本说明 [^1]
    - `v-bind:is="组件名"`：就是几个组件放在一个挂载点下，然后根据父组件的某个变量来决定显示哪个，或者都不显示
    - `keep-alive`：默认被切换掉（非当前显示）的组件，是直接被移除了。假如需要子组件在切换后，依然需要他保留在内存中，避免下次出现的时候重新渲染，那么就应该在component标签中添加`keep-alive`属性
    - `activate`：钩子，延迟加载
    - `transition-mode`过渡模式
- 动态加载外部组件
    - [组件库中使用动态组件 - 参考下文开发组件库](#开发组件库)
    - [httpVueLoader - 从URL加载vue文件](https://blog.csdn.net/cbaili/article/details/122726149)
    - [运行时渲染 - 可以做组件在线编辑器](https://github.com/merfais/vue-demo/blob/main/doc)
    - [动态组件 - 广告弹框案例](https://juejin.cn/post/6992483283187531789)
- 简单案例

```html
<div id="app">
    <button @click="toshow">点击让子组件显示</button>
    <component v-bind:is="which_to_show" keep-alive></component>
    <MyComp ref="comp" v-if="show"></MyComp>
    <Tinymce v-model="fieldModel"></Tinymce>
</div>

<script>
    import { LoadAssets } from '@sqbiz/sqbiz-vue'
    import { NPM_CDN_URL, MODULE_VERSION } from '@/utils/config'

    var vm = new Vue({
        el: '#app',
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
            // 异步导入组件，router中一般使用此方式导入
            // 假设 MainComp 和 MyComp 相互依赖，则其中一个需要是异步组件
            MyComp: () => import('./MyComp.vue').then(comp => {
                console.log(comp, this) // comp.default为当前组件，this此时为undefined
            }),
            // 异步基于CDN加载组件. NPM_CDN_URL=https://npm.elemecdn.com MODULE_VERSION=1.0.2-biz-minions
            Tinymce: (resolve) => {
                LoadAssets.loadScript(
                    `${NPM_CDN_URL}/@sqbiz/wplugin-tinymce-vue@${MODULE_VERSION['@sqbiz/wplugin-tinymce-vue']}/lib/WpluginTinymceVue.umd.min.js`,
                    'WpluginTinymceVue'
                ).then(() => {
                    resolve(window.WpluginTinymceVue)
                })
            },
        },
        data: {
            which_to_show: "first",
            show: false
        },
        created() {
            LoadAssets.loadCss(`${NPM_CDN_URL}/@sqbiz/wplugin-tinymce-vue@${MODULE_VERSION['@sqbiz/wplugin-tinymce-vue']}/lib/WpluginTinymceVue.css`, 'WpluginTinymceVue')
        },
        mounted () {
            this.show = true
            this.$nextTick(() => {
                console.log(this.$refs.comp) // 可能为undefined，因为组件可能还没加载进来
            })
        }
        methods: {
            toshow () {
                //切换组件显示
                var arr = ["first", "second", "third", ""];
                var index = arr.indexOf(this.which_to_show);
                if (index < 3) {
                    this.which_to_show = arr[index + 1];
                } else {
                    this.which_to_show = arr[0];
                }

                // 或者动态导入组件(更多用法参考官网)
                Vue.component('first', () => import('./first.vue'))
                let second = 'second.vue'
                Vue.component('first',
                    () => ({
                        // 参考: https://jishuin.proginn.com/p/763bfbd56d1b
                        // 1.require + component实现: 实现了动态加载功能，并未实现按需加载。require是CommonJS规范，在同路径下的vue文件，都会被打包进去
                        // component: require('./component/demo.vue').default
                        // 2.import + component实现：该方法不同于import A from B，这种属于纯静态编译；import()方法，该方法属于动态编译，webpack在打包时，碰到import()方法，会单独生存一个独立文件，用于按需加载。但不能实现完全动态，例如下面编译时会编译所有@/components下的模块，运行时才会加载second的值从而实现懒加载
                        // 3.require + Vue.extend实现
                        // *** 组件库中使用动态组件 - 参考下文开发组件库
                        component: import(`@/components/${second}`),
                        error: MyDefaultComp // 加载失败可显示默认组件
                    })
                )
            }
        }
    });
</script>
```

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
- 生命周期钩子
    - 在被keep-alive包含的组件/路由中，会多出两个生命周期的钩子 `activated` 与 `deactivated`(写在匹配到的组件中)
    - 不使用keep-alive: beforeRouteEnter -> created -> mounted -> destroyed
    - 使用keep-alive
        - 初次进入页面: beforeRouteEnter -> created -> mounted -> activated -> deactivated
        - 再次进入缓存的页面: beforeRouteEnter -> activated -> deactivated (created和mounted不会再执行)
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
- 路由和keep-alive
    - 如果发现未缓存，可看看是否有子孙路由也用到了router-view，此时要将最近的router-view进行缓存
    - https://www.lmlphp.com/user/16603/article/item/552232/
    - 案例

        ```html
        <template>
            <div>
                <keep-alive :include="includedComponents">
                    <router-view v-if="keepAlive" :key="key" />
                </keep-alive>
                <router-view v-if="!keepAlive" />
            </div>
        </template>

        <script>
        import Vue from 'vue'
        
        const CACHE_INCLUDED_ROUTES = 'cache_included_routes'

        export default {
            name: 'ParentView',
            data() {
                return {}
            },
            computed: {
                key() {
                    return this.$route.path
                },
                includedComponents() {
                    const includedRouters = Vue.ls.get(CACHE_INCLUDED_ROUTES)

                    if (this.$route.name && !(this.$route.meta && this.$route.meta.notCache)) {
                        let cacheRouterArray = Vue.ls.get(CACHE_INCLUDED_ROUTES) || []
                        if (!cacheRouterArray.includes(this.$route.name)) {
                            cacheRouterArray.push(this.$route.name)
                            Vue.ls.set(CACHE_INCLUDED_ROUTES, cacheRouterArray)
                            return cacheRouterArray
                        }
                    }
                    return includedRouters
                },
                keepAlive() {
                    return !(this.$route.meta && this.$route.meta.notCache)
                },
            },
        }
        </script>

        <!-- 删除标签时清除缓存 -->
        <script>
            handleCloseTag(remailTag) {
                // 关闭缓存
                const CACHE_INCLUDED_ROUTES = 'cache_included_routes'
                const cacheRouterArray = remailTag.map(x => x.name)
                Vue.ls.set(CACHE_INCLUDED_ROUTES, cacheRouterArray)
            }
        </script>
        ```

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

### 点击按钮后下载

```html
<!-- click方法中不能直接使用window对象 -->
<a @click="linkDownload('https://www.baidu.com')">百度</a>

<script>
linkDownload (url) {
    window.open(url, '_blank') // 新窗口打开外链接
}
</script>
```

### 插入字符串

```html
<Select v-model="editForm.alertField">
    <Option v-for="item in alertFieldList" :value="item.code" :key="item.code">{{ item.name }}</Option>
</Select>
<Button @click="insertStr()" style="margin-left: 15px;">插入</Button>
<textarea ref="content" v-model="editForm.content" class="ivu-input" type="text" rows="3"required></textarea>

<script>
insertStr() {
    if(this.editForm.content) {
        const start = this.that.$refs.content.selectionStart // 获取光标位置
        const a = this.editForm.content.substring(0, start)
        const b = this.editForm.content.substring(start, this.editForm.content.length)
        this.editForm.content = a + this.editForm.alertField + b
    } else {
        this.editForm.content = this.editForm.alertField
    }
    this.editForm = JSON.parse(JSON.stringify(this.editForm))
}
</script>
```

### 自动转大写

```html
<Input size="small" placeholder="编号" v-model="form.orderNo" clearable
    @keyup.native="$upper(form, 'orderNo')"></Input>

Vue.prototype.$upper = function (map, key) {
  if (!map || !key || !map[key]) return
  map[key] = map[key].toUpperCase()
}
```

## 样式

### lang 和 scoped

```html
<script>
// js中也可以引入样式
import './index.css'
</script>

<!-- lang：可选。默认是以css的方式解析样式；也可指定如 less/sass/stylus 等预处理器(需要提前安装对应依赖，如less需安装 `npm install -D less-loader less`) -->
<!-- scoped：可选。不写scoped时，本身写在vue组件内的样式只会对当前组件和引入此文件的另一组件产生影响，不会影响全局样式；写scoped时，表示该样式只对此组件产生影响，最终会生成样式如 `.example[data-v-5558831a] {color: blue;}` -->
<style scoped lang="less">
/* @import '~view-design/src/styles/index.less'; 使用iview的变量需要导入 */
@import './assets/globle-varables.less'; /* 引入外部文件。@default-color: red; */
@default-color: blue; /* 覆盖外部文件变量或自定义变量 */

.example {
    color: @default-color; /* 使用变量 */
}

/* scoped穿透问题：需要在局部组件中修改第三方组件库(如 iview)的样式，而又不想去除scoped属性造成组件之间的样式覆盖，这时可以通过特殊的方式穿透scoped */
/* less/sass格式如：`外层 ::v-deep 或 /deep/ 第三方组件 {样式}`(外层也可省略)，stylus则是将 /deep/ 换成 >>> */
.wrapper /deep/ .ivu-table th {
    background-color: #eef8ff;
}

.box {
    /* 解决直接使用 height: calc(100% - 60px); 不生效的问题 */ 
    height: calc(~"96vh - 100px"); 
    height: e("calc(100% - 60px)");
}
</style>

<!-- 也可在组件中额外定义全局样式 -->
<style>
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

- 使用案例

```less
// 通过~导入node_module目录下模块样式(也可写成相对路径), 从而可进行变量覆盖
@import '~view-design/src/styles/index.less';
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
- vue组件中给body设置样式

```html
<!-- 法一：通过生命周期直接修改body样式 -->
<script>
export default {
  beforeCreate () {
    document.querySelector('body').setAttribute('style', 'background: transparent !important')
  },
  beforeDestroy () {
    document.querySelector('body').removeAttribute('style')
  }
}
</script>

<!-- 法二：给template中的第一个div设置如下样式。只是加了一个遮住，如果是想把此页面通过iframe嵌套在其他页面进行透明则无此方法无效  -->
<style>
.body-bg {
  position: absolute;
  width: 100%;
  height: 100%;
  top: 0;
  left: 0;
  overflow-y: auto;
  background-color: #000;
}
</style>
```

### transition 动画

- 参考：[API](https://cn.vuejs.org/v2/api/#transition)、[guide](https://cn.vuejs.org/v2/guide/transitions.html)

```html
<!--
    name：用于自动生成 CSS 过渡类名。例如：name: 'fade' 将自动拓展为.fade-enter，.fade-enter-active等class，只需要提前定义好对应的css即可
    mode：控制离开/进入的过渡时间序列。有效的模式有 "out-in" 和 "in-out"；默认同时生效
    tag：<transition> 它会以一个真实元素呈现：默认为一个 <span>，可以通过 tag 属性更换为其他元素
    @after-enter：绑定进入后的事件，还有其他事件可以监听
-->
<transition name="fade" mode="out-in">
    <!-- transition 只能包含一个根节点，两个可以使用 v-if/v-else 或动态组件 -->
    <span v-if="true"></span>
    <span v-else></span>
</transition>
<style>
.fade-enter-active, .fade-leave-active {
  transition: opacity .5s;
}
.fade-enter, .fade-leave-to {
  opacity: 0;
}
</style>

<!-- 只能用于列表过渡(v-for)，列表需要有唯一key -->
<transition-group name="list" tag="p">
    <span v-for="item in items" :key="item">{{ item }}</span>
</transition-group>
```
- 结合[Velocity.js](https://github.com/julianshapiro/velocity)，Velocity 和 jQuery.animate 的工作方式类似，也是用来实现 JavaScript 动画

## mixins混入

- mixins
    - 值为对象的选项，例如 data()、methods、components 和 directives，将被合并为同一个对象。两个对象键名冲突时，取组件对象的键值对
    - created 等方法，会先执行混入created方法，再执行组件created方法
- 全局混入
    - `Vue.mixin({...})`
- 案例

```html
<!-- 被导入通用功能组件 -->
<template>
  <!-- b()为导入的bem函数，在create()函数中混入，对组件名进行class命名 -->
  <div :class="b()"></div>
</template>

<script>
import create from "core/create";
import locale from "./locale";
import hello from './hello'

export default create({
  name: "upload",
  mixins: [hello(), locale],
  data () {
    return {
      name: 'smalle',
    };
  },
  // 打印结果为: 111-333-222-444
  mounted: function () {
    console.log(333)
    this.$nextTick(function () {
      console.log(444)
    })
  },
});
</script>
```
- 通用代码

```js
// create.js
import bem from 'utils/bem'; // 对css进行bem命名，参考 https://gitee.com/smallweigit/avue/blob/v2.7.6/src/utils/bem.js
import { KEY_COMPONENT_NAME } from 'global/variable';
export default function(options) {
  // 再次封装，options为原始组件配置
  options.name = KEY_COMPONENT_NAME + (options.name || ''); // 给组件名加上统一前缀
  options.mixins = options.mixins || [];
  options.mixins.push(bem); // 在原混入基础上加入bem功能
  return options;
}

// hello.js
export default function () {
  return {
    data () {
      return {
        hello: null,
        safe: this,
        // 所有的对象，只有组件定义了，则全部按照组件定义的为准。**组件的属性不会和mixins的属性进行合并**
        map: {
         num: 1
        }
      }
    },
    computed: {
      helloName () {
        // this.safe.name => undefined; this['name'] => smalle; this.name => smalle; // ts使用this.name编辑器报红
        return this['name'] + ' smalle' // this 指当前函数对象，被混入后，也可获取到功能组件(导入此混入的组件)属性
      }
    },
    mounted: function () {
      console.log(111)
      this.$nextTick(function () {
        console.log(222)
      })
    },
    methods: {
      hello () {
        console.log('mixins methods')
      }
    }
  }
}

// locale.js
import { t } from 'locale'
export default {
  methods: {
    t(...args) {
      return t.apply(this, args);
    }
  }
};
```

## 指令

### 自定义指令

- [文档](https://cn.vuejs.org/v2/guide/custom-directive.html)
- 钩子函数
    - `bind` 只调用一次，指令第一次绑定到元素时调用
    - `inserted` 被绑定元素插入父节点时调用 (仅保证父节点存在，但不一定已被插入文档中)
    - `update` 所在组件的 VNode 更新时调用，但是可能发生在其子 VNode 更新之前
    - ·componentUpdated` 指令所在组件的 VNode 及其子 VNode 全部更新后调用
    - `unbind` 只调用一次，指令与元素解绑时调用
- 钩子函数参数
    - `el` 指令所绑定的元素，可以用来直接操作 DOM
    - `binding` 包含name, value, expression, arg, modifiers. 案例`v-demo:foo.a.b="message"`(message=hello!)
        - name: demo
        - arg: foo (也支持变量 `v-pin:[direction]="200"`)
        - modifiers: {"a": true, "b": true}
        - expression: message
        - value: hello! (如果指令需要多个值，可以传入一个 JavaScript 对象字面量, `v-demo="{ color: 'white', text: 'hello!'}"`)
    - `vnode`
    - `oldVnode`

### 自定义指令案例

#### input输入自动转大写

```js
<Input v-uppercase v-model="form.orderNo" placeholder="编号" clearable></Input>

Vue.directive("uppercase", {
  inserted: function (el) {
    const input = el.querySelector('input') // iview为例，找到实际的input输入框
    input.onkeyup = function (e) {
      input.value = input.value.toUpperCase()
    }
    input.onblur = function (e) {
      input.value = input.value.toUpperCase()
    }
  }
}
```

#### 多环境配置用户权限

- permission.js

```js
// v-permission="['admin','editor']"
// v-permission:[`Prod`, `Test`]="['admin','editor']"
import store from '@/store'

export default {
  inserted (el, binding, vnode) {
    const { value, arg } = binding
    const roles = store.getters && store.getters.roles

    if (arg && arg.split(',').indexOf(process.env.VUE_APP_SAAS_USER) < 0) {
      return
    }

    if (value && value instanceof Array && value.length > 0) {
      const permissionRoles = value

      const hasPermission = roles.some(role => {
        return permissionRoles.includes(role)
      })

      if (!hasPermission) {
        el.parentNode && el.parentNode.removeChild(el)
      }
    } else {
      throw new Error(`need roles! Like v-permission="['admin','editor']"`)
    }
  }
}
```

## API说明

- `Vue.use(demo, opts)` **注册插件**
    - 自定义插件参考[开发组件库](#开发组件库)
    - 如果插件是一个对象，必须提供 install 方法。如果插件是一个函数，它会被作为 install 方法。install 方法调用时，会将 Vue 作为参数传入
    - 实际是调用了demo的install(Vue, opts)方法，相当于传入了Vue对象到demo中

    ```js
    // config.js
    import Vue from 'vue'
    let config = {
        name: 'hello world'
    }
    export default {
        install(Vue) {
            // 之后在组件中可使用this.$config
            Vue.prototype.$config = config
        }
    }
    /*
    // 等同于
    const install = Vue => {
        Vue.prototype.$config = config
    }
    export default { install }
    */

    // main.js
    import config from './config/index.js'
    Vue.use(config)
    ```
- `Vue.extend(options)` 使用基础 Vue 构造器，创建一个子类. Vue.component 是基于此函数的
- `Vue.component(name, component)` 通过js手动**注册全局组件**，此时无需在components属性中定义。如果在main.js执行了此函数，则全局.vue文件均可使用此主键。使用是可使用name或其下划线形式名称
    - Vue.component注册全局组件时，内部会调用`Vue.extend`方法，将定义挂载到Vue.options.components上
    - `components: { Demo }` components属性是用于注册局部组件

    ```js
    // {string} id
    // {Function | Object} [definition]
    Vue.component('demo', {
        // render: function (createElement) {},
        template: `
            <div class="demo">
                hello world
            </div>
        `
    })

    // 基于函数(动态组件)
    Vue.component('demo', 
        () => ({
            component: import('@/view/components/demo.vue'),
            error: MyErrorComp
        })
    )

    // 全局异步组件
    Vue.component('demo', resolve => {
        // require会告诉webpack将构建的代码分割成多个包，这些包通过Ajax请求
        require(['./Demo'], resolve)
    })
    ```
- `Vue.mixin({...})` 全局混入
- `Vue.directive`

    ```js
    // 注册
    Vue.directive('my-directive', {
        bind: function () {},
        inserted: function () {},
        update: function () {},
        componentUpdated: function () {},
        unbind: function () {}
    })
    // 或指令函数
    Vue.directive('my-directive', function () {
        // 这里将会被 `bind` 和 `update` 调用
    })
    ```

## 开发组件库

- 说明
    - 当基于element-ui等进行二次开发时
        - 在案例入口文件中可以引入element-ui(案例不打包到库文件中)，可将element-ui加到dependences和externals(对应public/index.html需引入element-ui的CDN文件)中，这样打包案例时体积会减少
        - **在组件库模板中可以使用element-ui的标签，组件库无需在入口js中导入element-ui进行use**(前提是主应用全局use安装了element-ui插件)
        - **如果在库入口js文件及引申文件中引入了vue/element-ui，则不管包依赖是在dependences还是devDependences，都会将element-ui打包到组件库的输出文件中(如果只是使用element-ui的标签则不会)**
            - 在产物中搜索`ElInput`或`el-input`如果有则说明插件库中包含了element-ui包
            - 如果此时将vue/element-ui设置成了externals，则将此插件在另外一个vue项目中引用时会出现插件模块缺少Vue对象。可动态判断是否需要设置成externals

                ```js
                const IS_PROD = process.env.NODE_ENV === 'production'
                // script中增加`"lib": "vue-cli-service build --target lib ......"`
                // 此时通过 npm run lib 进行打包库文件，则 process.env.npm_config_argv(original) 的值为['run', 'lib']
                const IS_BUILD = JSON.parse(process.env.npm_config_argv).original.filter(x => x === 'build').length > 0

                module.exports = {
                    configureWebpack(config) {
                        if (IS_PROD && IS_BUILD) {
                            config.externals = {
                                vue: 'Vue',
                                'vue-router': 'VueRouter',
                                'element-ui': 'ELEMENT'
                            }
                        }
                    },
                }
                ```
        - 如果一定需要使用vue/element-ui的方法，可在插件的install方法(Vue插件安装的入口方法)中接收外部应用(主应用)传入进来的vue/element-ui对象并缓存到全局属性中(**如在插件内部调用Vue.component动态注册组件，此时必须使用同一个Vue对象，因此必须接收外部传入进来的**，参考下文[组件库中使用动态组件](#组件库中使用动态组件))
- 异步加载插件
    - 使用 externals
    - [vue2异步加载插件/组件/指令等](https://github.com/jiangshanmeta/vue-async-assets) vue2自带异步加载组件
    - vue3支持异步加载插件
- 案例
    - https://gitee.com/sqbiz/wplugin-variant-form 基于vue-cli打包
    - https://github.com/sscfaith/avue-form-design 基于vue-cli打包(packages文件为实际包, src为案例)
    - https://gitee.com/smallweigit/avue-plugin-ueditor 无需打包(直接将packages目录下文件暴露成包)

### 打包与导入

- 打包方式
    - 通过vue-cli打包
        - 参考: https://blog.csdn.net/qq_41887214/article/details/120619211

        ```json
        {
            // 导入模块时的入口函数(如果需要调试可去掉min，这样主应用导入后可直接在浏览器打断点。修改package.json后需要重启主应用)
            // 如果导出了多个模块，可以在引入的时候写全路径，如`import ReportTable from 'report-table'`引入默认模块，而通过类似`import ReportTableDemo from 'report-table/lib-demo/report-table-demo.umd.min.js`引入另外一个模块
            "main": "./lib/report-table.umd.min.js",
            // 如果是scope类型模块(name以@xxx/开头)，则npm默认为发布私有包，如果需要发布成公开则需要定义下面配置
            "publishConfig": {
                "access": "public"
            },
            // 上传到npm仓库的文件夹
            "files": [
                "lib",
                "types"
            ],
            "typings": "types/index.d.ts",
            "scripts": {
                // 参考: https://gitee.com/gitee-frontend/
                // 实时监控打包(修改代码编译较快，可实时反映到主应用，且调试时显示的是源码；可增加如`lib/*.hot-update.*`让git忽略热更新产生的文件)
                // 其他如npm link引用本地模块的方法参考：https://blog.csdn.net/zhangxin09/article/details/119344515
                // 配合 npm link(通过本地路径直接安装模块即可，偶尔还是需要npm link) 就可以做本地调试了。(1)现在模块目录执行<sudo> npm link将当前模块关联到全局 (2) 在到项目目录执行`npm link my-module`关联模块到项目中(执行后会将本地开发包关联到node_modules中；如果项目目录中配置的是远程包，当重新npm i就会重新下载远程包，即npm link失效)
                // 注意：--watch模式下，打包的lib中不会出现.css文件(样式和图片等资源无法实时监控)，因为css样式已经内联了，可通过在模块的 vue.config.js 中设置 css: { extract: true } 取消内联
                "start": "vue-cli-service build --target lib --name report-table --dest lib ./src/index.js --watch",
                // 打包命令，打出来的包在lib文件夹中
                // --formats umd-min # 产物包类型，默认包含common.js、.umd.js、.umd.min.js，此时表示只打包umd.min
                "lib": "vue-cli-service build --target lib --name report-table --dest lib --formats umd-min ./src/index.js",
                "lint": "vue-cli-service lint",
                // 分析的是以 vue.config.js 中的 pages.index.entry 为入口
                "report": "vue-cli-service build --report --mode prod"
            }
        }
        ```
    - 通过rolljs打包
        - 参考https://segmentfault.com/a/1190000038827540，[demo](https://github.com/Zack921/zui-demo)
    - 通过webpack打包
        - 参考https://www.cnblogs.com/zdf-xue/articles/13062357.html
- 主应用导入本地环境组件库
    - 参考：https://qastack.cn/programming/8088795/installing-a-local-module-using-npm
    - `npm install /path/to/component/project/dir`此时会在package.json中创建对应的依赖，值为`file:..`的相对路径
        - 模块更新不会直接热部署到应用，必须重新build
    - `npm link`(或对应的`yarn link`同理使用)
        - 在模块目录执行`npm link`会将当前模块链接到全局模块中
        - 在应用目录执行`npm link package-name`引用该模块
        - 也可直接使用相对/绝对路径，相当于上面两步
        - 此方式不会在package.json中增加依赖
        - 模块更新不会直接热部署到应用，必须重新build
    - 解决使用 npm link 时, eslint 提示对应包存在错误的问题
        - 在vue.coonfig.js的configureWebpack属性中加 `resolve: { symlinks: false }`，参考: https://stackoverflow.com/questions/48410203/webpack-gives-eslint-errors-while-using-npm-link
- 主应用导入远程环境组件库(均需先上传包)
    - 通过github安装，参考[基于git仓库进行安装](/_posts/web/node-dev-tools.md#基于git仓库进行安装)
    - 通过npm镜像安装

### 组件库中使用动态组件

- 把主应用的组件通过在组件库中import/require动态引入，会出现找不到组件文件；且通过Vue.component注册时并没有注册到主应用Vue对象中，而是注册到组件的Vue对象中
- 解决方法：在通过Vue.use组件库的时候，将主应用的Vue构造函数传递到组件库中，并且把需要动态引入主应用组件添加到Vue原型中(当然也可以注册成全局Vue组件)
- 组件库主要代码

```js
// =============> 组件库入口函数
import GlobalConfig from './config'
import helper, { install as HelperInstall } from './common/helper.js'
// 如Vue组件
import Demo from './packages/demo/index.js'
// 如果需要使用src下面的js必须在此文件导出
// 主引用中不能使用`import tools from 'my-comp/src/utils/tools'`导入对象，必须使用 import { tools } from 'my-comp'导入
// 但是主应用可以使用`@import '~my-comp/src/styles/theme-default.less'`导入样式文件到`index.less`(模块打包后默认将组件中css生成到一个css文件中，main.js中也只能引入css样式)
import * as tools from './utils/tools' // 此文件中导出了很多小函数

const install = function (Vue, options = {}) {
  _.merge(GlobalConfig, options)
  
  // 此Vue为主应用传入的Vue构造函数(_base)，缓存起来用于动态注册组件
  Vue.use(HelperInstall, options)

  Vue.prototype.$sqrt = helper
  // ...
}

// 这样导出后，可使用 import MyComp from 'my-comp' 导入全部对象
const MyComp = {
  install,
  Demo,
  tools
}
export default ReportTable

// 这样导出后，可使用 import { Demo } from 'my-comp' 导入部分对象
export {
  install,
  Demo,
  tools
}

// =============> 组件其他文件
// common/helper.js
import GlobalConfig from './config'
const Helper = {
  // 主应用 Vue 构造函数，用于组件库中动态注册组件
  Vue: null,
  // 主应用 vm 对象(可省略)
  get main() {
    return GlobalConfig.main || GlobalConfig.refreshMain()
  },
  get exportComp () {
    return Helper.Vue.prototype[GlobalConfig.exportCompKey] || {}
  }
}
const install = function (Vue, options = {}) {
  Helper.Vue = Vue
}
export default Helper

// ./config.js
const GlobalConfig = {
  exportCompKey: 'exportComp',
  // 主应用 vm
  main: null,
  refreshMain: () => {},
}
export default GlobalConfig

// 动态导入组件
<component :is="mainComp" />
this.mainComp = 'mainComp'
// 必须使用主应用的Vue构造函数注册主应用的组件
// this.$sqrt.Vue.component(this.mainComp, this.$sqrt.Vue.options.components['mainComp']) // 从注册到Vue全局组件中获取
this.$sqrt.Vue.component(this.mainComp, this.exportComp['mainComp']) // 从Vue原型中获取
/*
// 此方式存在问题：组件库中通过from vue导入的Vue对象，最终都是组件库的webpack加载vue.js中的Vue对象(vue__WEBPACK_IMPORTED_MODULE_13___default.a)到当前组件库上下文，因此后面通过Vue.component注册的组件是注册到组件库的Vue对象中了，并没有添加到主应用的Vue对象中

// 会打包出下面的代码
// vue__WEBPACK_IMPORTED_MODULE_13___default.a.component(mainComp, (function() {
//     return {
//         component: __webpack_require__("0f13")("./" + mainComp + ".vue")
//     }
// }

// import('@/components/'...) 会转成 __webpack_require__("0f13"), 相当于再当前组件库webpack上下文查找组件源文件(业务上实际需要把主应用的组件通过在组件库中import/require动态引入)

import Vue from 'vue'
Vue.component(mainComp, () => {
  component: import('@/components/' + x.extMap.component + '.vue')
})
*/
```
- 主应用主要代码

```js
// main.js
// 注册需要动态导入的组件
import Packages from './packages'
Vue.use(Packages)

let vm
Vue.use(ReportTable, {
  refreshMain: () => vm
})

vm = new Vue({
  el: '#app',
  render: h => h(App)
})

// packages.js
import mainComp from './components/mainComp.vue'
const install = function (Vue) {
  // Vue.component(mainComp.name, mainComp) // 注册成Vue全局组件
  Vue.prototype.exportComp = { mainComp } // 添加到Vue原型上
}
export default install
```

### 相关问题

- 部分插件引用的模块用到了PostCSS，当`npm link`后，在主项目中启动后报错`Error: No PostCSS Config found`
    - 在当前项目根目录下创建`postcss.config.js`，并加入配置

    ```js
    module.exports = {
        plugins: {
            autoprefixer: {
                browsers: 'last 5 version'
            }
        }
    }
    ```

## JSX使用

- 类似的可参考[render函数](#render函数(iview))
- vue的jsx语法是基于[babel-plugin-transform-vue-jsx](https://github.com/vuejs/babel-plugin-transform-vue-jsx)插件实现的 [^7]

    ![vue-jsx](/data/images/web/vue-jsx.png)
- **使用vue-cli3则不需要手动安装下述babel插件即可使用**(如果重复安装会报错Duplicate declaration "h")。其他方式需要手动安装

```bash
# 非vue-cli3需要手动安装
npm install babel-plugin-syntax-jsx babel-plugin-transform-vue-jsx babel-helper-vue-jsx-merge-props babel-preset-env --save-dev
# .babelrc文件中增加配置
"plugins": ["transform-vue-jsx"]
```
- 使用 [^6] [^7]
    - babel插件会通过正则匹配的方式在编译阶段将书写在组件上属性进行分类
        - onXXX的均被认为是事件，nativeOnXXX是原生事件，domPropsXXX是Dom属性，class、staticClass、style、key、ref、refInFor、slot、scopedSlots这些被认为是顶级属性，至于组件声明的props，以及html属性attrs，不需要加前缀，插件会将其统一分类到attrs属性下，然后在运行阶段根据是否在props声明来决定属性归属
        - 不建议声明onXXX的属性
    - 对于原生指令，只有v-show是支持的。v-if可用(&& 或 ?:)代替；v-for可用array.map代替；v-model使用事件触发；自定义指令使用...解构
        - `<el-input value={this.value} onInput={$event => this.value = $event} {...{ directives }}></el-input>` (其中`let directives = [{ name: 'rt-permission', value: ['manager'] }]`)
    - 对于事件
        - 使用 `on-[eventName]` 格式, 比如 on-on-change, on-click, on-camelCaseEvent
        - 使用 `on[eventName]` 格式，比如 onClick, onCamelCaseEvent。click-two 需要这样写 onClick-two，onClickTwo 是不对的
        - 使用 spread 语法，即 `{...{on: {event: handlerFunction}}}`
    - 对于样式
        - 如果组件中使用了scoped，则对该组件的JSX标签中的css类进行样式编写时必须添加`/deep/`等作用于穿透标识
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

// iview 列
columns: [{
    title: '处理人',
    key: 'workerName',
    width: 95,
    // render (h, params) {
    //     此作用域的this和param类似
    // },
    render: (h, params) => {
        // 此组件可以拿到vue组件 this
        return (
            <FieldEdit type="select" value={params.row.worker} dataList={this.projectUserList} dataKey="uid" dataLabel="uname"
            on-on-change={v => this.editWork('worker', v, params.row)} />
        )
    }
}]

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

// iview的部分组件，此时只能使用下划线，如：Button需要是i-button，Tag=>tag。更多见官网
{
    title: '计划日期',
    key: 'planTm',
    render: (h, params) => {
        return (
            <date-picker type="date" value={ params.row.planTm } on-on-change={ v => { this.planTm = v } } />
        )
    }
}

// 属性
return (
    <span {...{
        style: { color: color },
        // HTML其他属性
        attrs: {
            title: '鼠标悬停标题'
        }
    }}>{ msg }</span>
)
```

## Vue对Typescript的支持

- 参考[typescript.md#Vue结合Typescript](/_posts/web/typescript.md#Vue结合Typescript)

## VueRouter路由

> https://yuchengkai.cn/blog/2018-07-27.html 源码解析

### 基本概念

- 路由生命周期见上文
- `query`和`params`的区别
    - query参数会拼接到url上面，param不会
    - params的参数值可以赋值给路由路径中的动态参数。因此使用params时路由跳转后再次刷新页面会导致参数丢失($router.go也会丢失params参数)

```js
this.$router.push({
    name: "VisitInfo",
    query: Object.assign({}, contact, {
        visitId: this.visitId
    })
});
```
- redirect

```js
{
    path: '/base_info/*',
    name: '基础信息',
    // 可以接受函数
    redirect: to => {
        console.log(to.path)
    }
},
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
    - 嵌套路由（https://router.vuejs.org/zh/guide/essentials/nested-routes.html）

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
- `router.addRoute` 动态添加路由，如果该路由规则有 name，并且已经存在一个与之相同的名字，则会覆盖它

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
    // 动态路径参数，以冒号开头，通过route.params.userId传递参数。从路由中获取的参数均为字符串，Id一般需要通过Number()转换一下，防止后面 === 比较不正确，新增可用0
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
  // 路由的基础路径，类似publicPath。只不过publicPath是针对静态文件，而此处是将<router-link>中的路径添加此基础路径
  // base: '/my-app/', // 多环境配置时可自定义变量(VUE_APP_BASE_URL = /my-app/)到 .env.xxx 文件中，如：publicPath: process.env.VUE_APP_VUE_ROUTER_BASE
  routes,
  mode: 'history' // 默认为hash模式
})

// 如后端nginx服务器配置
location / {
  try_files $uri $uri/ /index.html;
}
```

### 刷新页面

- 参考：https://segmentfault.com/a/1190000019635080

```vue
<!-- 添加组件src/views/redirect.vue -->
<script>
export default {
  created () {
    const { params, query } = this.$route
    const { path } = params
    this.$router.replace({
      path: '/' + path,
      query
    })
  },
  render: function (h) {
    return h()
  }
}
</script>

<!-- 添加路由 -->
{
    path: '/redirect/:path*',
    name: 'redirect',
    component: () => import('@/views/redirect'),
    hidden: true
}

<!-- 自定义刷新方法 -->
refresh () {
    const { fullPath } = this.$route
    this.$router.replace({
        path: '/redirect' + fullPath
    })
}
```

### 打开新页面

```js
// 可结合下文vue-contextmenujs插件实现右键打开新标签
open() {
    let route = this.$router.resolve({
        path: "/open", // 也可使用name或传入整个route
        query: {id: 96}
    })
    window.open(route.href, '_blank')
},
// 通过提示框渲染一个链接处理打开新标签页
getInfo() {
    this.$Modal.info({
        title: '提示',
        render: (h) => {
            return h('a', {
                on: {
                    click: () => {
                        let route = this.$router.resolve({
                        path: '/test/new',
                            query: {
                                name: 'test'
                            }
                        })
                        window.open(route.href, '_blank')
                    }
                }
            }, '打开新标签页')
        }
    })
}
```

### 子模块路由案例(iview-admin为例)

- 隐藏菜单

```js
// 路由
{
    path: '/base',
    name: 'base',
    component: Main,
    meta: {
      access: [],
      icon: 'md-people',
      showAlways: true,
      title: '客户管理'
    },
    icon: 'md-home',
    children: [
      { name: 'customer', path: 'customer', meta: { title: '客户管理' }, component: () => import('@/views/customer/CustomerList') },
      {
        name: 'customerInfo',
        path: 'customer/customerInfo/:customerId',
        meta: { title: '客户信息', hideInMenu: true }, // iview-admin中hideInMenu为隐藏菜单
        component: () => import('@/views/customer/CustomerInfo.vue')
      }
    ]
}

// 路由跳转
this.$router.push({
    name: 'customerInfo',
    params: {
        customerId: 1
    }
})
```
- 子组件路由(嵌套路由，参考上文)

```js
// 路由
{
    path: '/workspace',
    name: '',
    component: Main, // Main为iview-admin的基础组件，组件内包含一个router-view出口来展示下面的children
    children: [
      {
        path: 'project/:projectId',
        name: 'project',
        component: () => import('@/view/workspace/project/project-index.vue'), // 组件内必须包含一个router-view出口来展示下面的children
        children: [
          {
            path: 'workbench/:levelId',
            name: 'workbench',
            component: () => import('@/view/workspace/project/workbench/workbench-index.vue'), // 组件内必须包含一个router-view出口来展示下面的children
            children: [
              {
                path: 'work-level/:workLevelId',
                name: 'work-edit',
                component: () => import('@/view/workspace/project/workbench/work/work-edit.vue')
              }
            ]
          },
          {
            path: 'document',
            name: 'document',
            meta: {
              title: route => `${route.params.name}`
            },
            component: () => import('@/view/workspace/project/document/document-index.vue')
          }
        ]
      }
    ]
}

// project-index.vue包含下列代码。workbench-index.vue同理
<div class="project-info">
    <keep-alive>
        <router-view />
    </keep-alive>
</div>

// 路由跳转
this.$router.push({
    name: 'work-edit',
    params: {
        projectId: 1,
        levelId: 1,
        workLevelId: 1
    }
})
```

### 数据库动态路由

- 数据库以路由格式存储json
- 前端初始化时，默认路由设置成空，或者添加几个静态路由(如403/404等页面)
- 用户登录后，通过`addRoutes`动态将路由项添加到路由对象中，并存储路由数组到Vuex防止重复添加
- 用户退出登录后，重置路由对象(重新new一个路由对象)

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
    name: '', // 刷新浏览器数据会丢失
    info: Cookies.get('info') ? JSON.parse(Cookies.get('info')) : {} // Cookies获取的是字符串，需要转换
  },
  // this.$store.getters.username 即可访问
  getters: {
    username: state => {
      return state.info.username
    }
  },
  // 更改 Vuex 的 store 中的状态的唯一方法是提交 mutation。它会接受 state 作为第一个参数
  // 同步调用：this.$store.commit('SET_TOKEN', 'my-token-xxx')
  mutations: {
    SET_TOKEN: (state, token) => {
      state.token = token
      // this.commit('SET_NAME', 'hello') // 内部调用
      // this.dispatch('Login', {}) // 内部调用
    },
    SET_NAME: (state, name) => {
      state.name = name
    }
  },
  // Action 类似于 mutation，不同在于：Action 提交的是 mutation，而不是直接变更状态；Action 可以包含任意异步操作
  // 异步调用：this.$store.dispatch('Login')
  actions: {
    // actions只能接受一个参数
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

### Vuex的使用场景

- 采用单向数据流的模式，子组件修改数据必须通过事件触发回调。如果当组件的层级越来越深，会造成父组件可能会与很远的组件之间共享同份数据，如果此时很远的组件需要修改数据时，就会造成事件回调需要层层返回。因此可通过Vuex这个状态管理库来统一维护 [^8]
    - 实践：父组件负责渲染Store的数据状态(初始化)且通过computed监听状态变化，然后通过props传递数据到子组件中，子组件触发事件提交更改状态的action, Store可以在Dispatcher上监听到Action并做出相应的操作，当数据模型发生变化时，就触发刷新整个父组件界面
- 利用computed的特性，用get和set来获取和设值

    ```js
    computed: {
        message: {
            get () {
                return this.$store.state.message
            },
            set (value) {
                this.$store.commit('updateMessage', value)
            }
        },
        // 对于一些需要动态转换的属性较为实用
        curList: {
            get () {
                return this[`${this.searchForm.dataType}List`]
            },
            set (newValue) {
                this[`${this.searchForm.dataType}List`] = newValue
            }
        },
    }
    ```
- 持久化工具[vuex-persistedstate]。可将store数据写入到localStorage中
- 扁平化 Store 数据结构
    - 可基于JSON数据规范化(normalize)，使用如 [Normalizr](https://github.com/paularmstrong/normalizr) 等开源的工具，可以将深层嵌套的 JSON 对象通过定义好的 schema 转变成使用 id 作为字典的实体表示的对象
    - 分离渲染UI数据量大的属性，以免其他不必要的状态改变而影响它

    ```js
    // 假设某组件A会通过商铺名获取商铺信息。如果A商铺loading状态变更，则state1.shops属性变化，这时Getter监听到变化后，会通知绑定的组件（商铺A，商铺B，...），然后UI响应变化。像fruits本没有变化也会触发水果组件重新渲染，而其数据量大会导致性能变差
    const state1 = {
        shops: {
            // 对应商铺组件
            商铺A: {
                startDate: "2018-11-01",
                endDate: "2018-11-30",
                loading: false,
                diplayMoreFruitsLink: true,
                fruits: [{},{},{}...], // 水果，对应水果组件
            },
            商铺B:{...},
            ...
        }
    }
    // 改进后。此时商铺信息变化并不会影响"商铺A_fruits"属性变化，水果组件不会重新渲染
    const state2 = {
        shops: {
            商铺A: {
                startDate: "2018-11-01",
                endDate: "2018-11-30",
                loading: false,
                diplayMoreFruitsLink: true,
                fruits: [{},{},{}...], // 水果
            },
            商铺B:{...},
            ...
        },
        商铺A_fruits: [{},{},{}...],
        商铺B_fruits: [{},{},{}...],
        ...
    }
    ```

## vue-cli

- [官网](https://cli.vuejs.org/zh/)
- 安装

```bash
# Vue CLI 4.x 需要 Node.js v8.9 或更高版本 (推荐 v10 以上)
# Vue CLI 5.x 需要 Node.js v12 以上
npm install -g @vue/cli # 指定版本 @vue/cli@4.5.19
vue --version # @vue/cli 4.5.19

# 创建一个demo项目
vue create demo
'''json
"devDependencies": {
    // 默认创建的
    "@vue/cli-plugin-babel": "~4.5.19",
    "@vue/cli-plugin-eslint": "~4.5.19",
    "@vue/cli-service": "~4.5.19",
    "babel-eslint": "^10.1.0",
    "eslint": "^6.7.2",
    "eslint-plugin-vue": "^6.2.2",
    "vue-template-compiler": "^2.6.11",
    // 手动添加
    "@types/lodash": "^4.14.168",
    "node-sass": "^4.9.0",
    "sass-loader": "^7.0.1",
    "prettier": "^2.2.1",
    "webpack-bundle-analyzer": "^3.0.3"
}
'''

# [审查项目的-webpack-配置](https://cli.vuejs.org/zh/guide/webpack.html#%E5%AE%A1%E6%9F%A5%E9%A1%B9%E7%9B%AE%E7%9A%84-webpack-%E9%85%8D%E7%BD%AE)
# 将 vue-cli 中（vue.config.js）对 webpack 的配置信息导出到 output.js 文件
vue inspect > output.js
# 如可以看到如下内容，因此在js中可以使用 `process.env.NODE_ENV`，在 public/index.html 中可使用 href="<%= BASE_URL %>favicon.ico" 进行变量替换
'''
new DefinePlugin(
    {
        'process.env': {
            NODE_ENV: '"development"',
            VUE_APP_BASE_URL: '"http://localhost:8800/api/v1"',
            VUE_APP_ENV: '"development"',
            BASE_URL: '"/"'
        }
    }
)
'''
```

### vue-cli-service

- 命令说明

```bash
# 查看帮助
npx vue-cli-service -h

vue-cli-service
    build
        --mode test-sq # 指定环境变量配置文件为.env-test-sq
        --report # 生成分析报告到dist/report.html(vue-cli自带分析插件)
        --target lib # 生成lib包(用于npm安装或浏览器引用的js)
        --name report-table # lib包名称
        --dest lib 
        --formats umd-min # 产物包类型，默认包含common.js、.umd.js、.umd.min.js，此时表示只打包umd.min
        <./src/index.js> # 打包时的目标目录为lib，入口文件为./src/index.js
        --watch # 实时观测打包文件
```
- package.json 常用配置

```json
{
    "scripts": {
        "serve": "vue-cli-service serve", // 一般为运行开发环境(此时process.env.NODE_ENV='development')。执行命令：npm run serve
        "dev": "vue-cli-service serve --open --port=8000", // 类似serve，其中 --open 表示自动打开浏览器，--port 指定端口
        // 在vue-cli2中打包时可以修改 "build" 和 "config" 中的文件来区分不同的线上环境。而vue-cli3号称0配置，无法直接修改打包文件进行环境区分，具体见下文
        "build": "vue-cli-service build", // 一般为生成环境打包(此时process.env.NODE_ENV='production')
        // 区分环境进行打包，此时在 vue.config.js 文件的同级目录(根目录)创建文件 .env.test-sq，其中可添加变量如 `NODE_ENV = test-sq` (一行一个变量，最终都会挂载到 process.env 下)
        "build-test-sq": "vue-cli-service build --mode test-sq",
        // 生成分析报告到dist/report.html(vue-cli自带分析插件)
        "report": "vue-cli-service build --report --mode pord"
    },
}
```

### .evn

- `.env.test-sq` (多)环境变量配置。具体参考：https://cli.vuejs.org/zh/guide/mode-and-env.html

```bash
## 获取的值都是字符串类型
## 修改之后必须要重启项目才会生效

# 使用都是 process.env.xxx
NODE_ENV = test-sq
# 以 VUE_APP_ 开头的变量才会被 webpack.DefinePlugin 静态嵌入到客户端侧的包中
VUE_APP_VUE_ROUTER_BASE = /my-app/
# 可识别为json字符串(不支持字符串换行，暂未找到换行写法)
VUE_APP_JSON = {"a": 1, "b": "abc"}
```

### vue.config.js

- [官方文档](https://cli.vuejs.org/zh/config/)
- [多项目配置参考](/_posts/arch/springboot-vue.md#多项目配置)
- vue.config.js 常用配置    

```js
// process.env 可以获取node下所有的环境变量
const port = process.env.port || process.env.npm_config_port || 9528
const publicPath = process.env.NODE_ENV === 'production' ? '/' : '/'

// process.argv 可以获取node命令行全参数
// node vue-cli-service serve --mode dev
const args = process.argv.slice(2) // ['serve', '--mode', 'dev']
const hasMode = args.indexOf('--mode') >= 0

module.exports = {
    // 多项目参考 [springboot-vue.md#多项目配置](/_posts/arch/springboot-vue.md#多项目配置)
    // index.html中引入的静态文件路径，如：/js/app.28dc7003.js(如果publicPath为 /demo1/，则生成的路径为 /demo1/js/app.28dc7003.js)
    publicPath: publicPath, // 对应vue-cli2 或者 webpack中的 assetsPublicPath 参数
    outputDir: 'dist', // 打包后的文件生成在此项目的dist根文件夹，一般是把此文件夹下的文件(index.html和一些静态文件)放到www目录
    lintOnSave: false, // 保存文件时进行eslint校验，false表示保存时不校验。如果校验不通过则开发时页面无法显示
    // 打包时不生成.map文件
    // 项目打包后，代码都是经过压缩加密的，如果运行时报错，输出的错误信息无法准确得知是哪里的代码报错。有了map就可以像未加密的代码一样，准确的输出是哪一行哪一列有错。但是在生产环境中我们就不需要了
    productionSourceMap: false,

    configureWebpack: config => {
        let plugins = []
        // if (process.env.NODE_ENV === 'production') {
        //   // 打生产包，进行依赖分析
        //   const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
        //   plugins.push(new BundleAnalyzerPlugin())
        // }
        return {
            devtool: 'source-map', // 生成source-map, 否则debugger容易定位不准确
            plugins: plugins,
            // 和下文 chainWebpack 中的配置效果一样
            externals: {
                vue: 'Vue',
                'vue-router': 'VueRouter',
                'element-ui': 'ELEMENT'
            }
        }
    },

    // 对上文 configureWebpack 属性再次设置
    chainWebpack: config => {
        // 忽略的打包文件，使用CDN文件。安装和导入以模块的方式，index.html中引入对应cnd路径文件，开发/打包则使用此文件
        config.externals({
            'vue': 'Vue',
            'vue-router': 'VueRouter',
            'vuex': 'Vuex',
            'axios': 'axios',
            'element-ui': 'ELEMENT',
            'lodash': '_',
        })
        
        // key,value自行定义。在src的vue文件中可通过此别名引入文件，如 import A from '@/test/index'，相当于引入 scr/test/index.js
        // 设置了别名之后会导致通过快捷键无法快速定位到文件。此时可在项目根目录添加一个tsconfig.json(无需在devDependencies中引入额外依赖)，将其中的 paths 属性的值也加入此别名定义，从而可解决(不支持子文件夹项目)
        config.resolve.alias
            .set('@', resolve('src'))
            .set('_c', resolve('src/components'))

        // 修改插件选项
        config
            .plugin('define') // 对应 DefinePlugin 插件，其简称可通过 vue inspect > output.js 生成目标配置查看。其实通过 .env 文件定义的变量会自动加到 DefinePlugin 中
            .tap(args => {
                // 修改构造函数参数值并返回
                args[0]['process.env'].BUILD_ENV = JSON.stringify(process.env.BUILD_ENV)
                return args
            })

        // 修改 Loader 和新增 Loader
        config.module
            .rule('vue')
            .use('vue-loader')
            .tap(options => {
                // 修改它的选项...
                return options
            })
            // 你还可以再添加一个 loader
            .use('other-loader')
            .loader('other-loader')
            .end()

        // 入口文件修改
        // 会在默认的源文件(src/main.js)后加入mock.js一起打包成app.js的入口文件
        config.entry('app').add('./src/mock.js')
        // vue-cli默认生成的入口文件为app.js(chunk文件)，clear方法会把vue-cli默认的.entry('app')清空
        // config.entryPoints.clear().end()
        //     .entry('main').add('./src/main.js').end() // main chunk. 可以在同一个chunk，add多个模块
        //     .entry('routes').add('./src/app-routes.js');

    },

    pluginOptions: {
        'style-resources-loader': {
            preProcessor: 'less',
            patterns: [path.resolve(__dirname, 'src/styles/theme/index.less')]
        }
    },

    // 多页面配置，可为每个页面定义入口文件
    pages: {
        index: {
            entry: 'src/views/index/main.js',
            template: 'public/index.html',
            // 在 dist/index.html 的输出
            filename: 'index.html',
            // 提取出来的通用 chunk 和 vendor chunk
            chunks: ['chunk-vendors', 'chunk-common', 'index']
        },
        preview: {
            entry: 'src/views/preview/main.js',
            template: 'public/preview.html',
            filename: 'preview.html',
            chunks: ['chunk-vendors', 'chunk-common', 'preview']
        }
    },

    devServer: {
        // host: 'localhost', // target host
        port: port,
        open: true,
        // 解决使用花生壳内网穿透进行调试时，打开网页显示：invalid host header（需要重启项目, 好像修改代码之后仍然需要重启项目）
        disableHostCheck: true,
        overlay: {
            warnings: false,
            errors: true
        },
        // 参考：https://www.cnblogs.com/liuguiqian/p/11362211.html
        proxy: {
            // /api/xxx
            '^/api': {
                target: `http://127.0.0.1:${port}/mock`, // url = target + uri(使用pathRewrite去掉原url根路径)
                changeOrigin: true, // 如果接口跨域，需要进行这个参数配置
                // ws: true, // proxy websockets
                pathRewrite: {          // 不重写url为 `http://127.0.0.1:${port}/mock/api/xxx`
                    '^/api': '/',       // 重写之后url为 `http://127.0.0.1:${port}/mock/xxx`
                    '^/api': '/api2'    // 重写之后url为 `http://127.0.0.1:${port}/mock/api2/xxx`
                }
            }
        }
    },

    // 一般开发组件库时用到. build打包时，--watch时默认为css内联样式，此处设置成非内联模式(样式生成到单独的css文件中)；非 --watch 默认就是true
    // css: {
    //     extract: true
    // }
}
```

## 文档框架vuepress

- [vuepress](https://vuepress.vuejs.org/zh/) 官方推出的文档框架
    - [demo](https://gitee.com/changhaojun/vuepress-demo)
- 可结合[vuese](https://github.com/vuese/vuese) 先对vue组件进行解析成markdown
- 其他框架
    - Docsify/Docute
        - 这两个项目同样都是基于 Vue，然而它们都是完全的运行时驱动，因此对 SEO 不够友好
    - Hexo
        - Vue 的文档一直使用此框架，Hexo 最大的问题在于他的主题系统太过于静态以及过度地依赖纯字符串，二vuepress可以使用vue来处理布局和交互
    - GitBook
        - GitBook 最大的问题在于当文件很多时，每次编辑后的重新加载时间长得令人无法忍受
    - ​docz​
    - [docsite](https://github.com/txd-team/docsite) 阿里开源(React), 对SEO友好

## 插件收集

- 自定义右键菜单 [vue-contextmenujs](https://github.com/GitHub-Laziji/menujs) 包大小130K
    - 可以在指定元素上开启自定义右键菜单
- 栅格布局 [Vue Grid Layout](https://jbaysolutions.github.io/vue-grid-layout/zh/)
    - 如可用于首页自定义栅格






---

参考文章

[^1]: https://www.cnblogs.com/-ding/p/6339740.html (动态组件)
[^2]: https://segmentfault.com/a/1190000008879966#articleHeader14 (vue生命周期)
[^3]: https://asyncoder.com/2018/07/20/%E8%AE%B0%E4%B8%80%E6%AC%A1Vue%E4%B8%AD%E7%9A%84v-for%E8%B8%A9%E5%9D%91%E4%B9%8B%E6%97%85/
[^4]: https://juejin.im/post/5b4ca076f265da0f900e0a7d
[^5]: https://juejin.im/post/5b41bdef6fb9a04fe63765f1
[^6]: https://www.yuque.com/zeka/vue/vu60wg
[^7]: https://www.njleonzhang.com/2018/08/21/vue-jsx.html
[^8]: https://juejin.im/entry/5c30f46be51d4551b508fec0
[^9]: https://juejin.im/post/5b960fcae51d450e9d645c5f (Vue 应用性能优化指南)
[^10]: https://juejin.im/post/5d5e89aee51d453bdb1d9b61
[^11]: https://juejin.im/post/59bf501ff265da06602971b9 (性能优化之组件懒加载: Vue Lazy Component 介绍)
[^12]: https://juejin.im/post/5d548b83f265da03ab42471d (Vue 项目性能优化 — 实践指南)
[^13]: https://juejin.im/post/6844903584899792909

