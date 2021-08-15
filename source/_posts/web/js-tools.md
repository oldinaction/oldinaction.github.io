---
layout: "post"
title: "JS Tools"
date: "2020-10-9 15:18"
categories: web
tags: [js, tools]
---

## 开发库

### mockjs模拟数据

- 语法`Mock.mock(rurl, rtype, function(options))`
    - rurl：拦截的请求地址，支持正则。不使用正则是为完全不配，如`/user/getMenu`无法匹配`http://localhost/user/getMenu`，也无法匹配参数`/user/getMenu?type=0`
    - rtype：请求类型，get/post等
    - 回调函数，需要返回最终结果(相当于模拟后台请求返回)。options(url: 包括请求传参数、type: GET/POST等、body: body体参数)
- 示例

```js
import Mock from 'mockjs'

// 定义模拟数据
const menu = [
    [{
        label: "首页",
        path: "/index",
        icon: 'el-icon-document',
        meta: {
            i18n: 'dashboard',
        },
        parentId: 0
    }]
]

// 定义模拟拦截
Mock.mock(RegExp(process.env.VUE_APP_BASE_URL + '/user/getMenu.*'), 'get', (options) => {
    const type = getUrlParam('type', options.url)
    return {
        data: menu[type] || []
    }
})

const getUrlParam = (paramName, params) => {
  var reg = new RegExp('(^|&)' + paramName + '=([^&]*)(&|$)')
  if(!params) {
    params = window.location.search.substr(1)
  } else if(params.indexOf('http://') === 0 || params.indexOf('https://') === 0) {
    params = params.indexOf('?') < 0 ? '' : params.split('?')[1]
  }
  var r = params.match(reg)
  if (r != null) return unescape(r[2])
  return null
}
```

### babel

- [babeljs中文网](https://www.babeljs.cn)
- `babel`(@babel/core) 是一个转码器，可以将es6，es7转为es5代码
    - Babel默认只转换新的JavaScript句法（syntax），而不转换新的API，比如Iterator、Generator、Set、Maps、Proxy、Reflect、Symbol、Promise等全局对象，以及一些定义在全局对象上的方法（比如Object.assign）都不会转码
    - 所以为了使用完整的 ES6 的API，我们需要另外安装：babel-polyfill 或者 babel-runtime [^1]
        - `@babel/polyfill` 会把全局对象统统覆盖一遍，不管你是否用得到。缺点：包会比较大100k左右。如果是移动端应用，要衡量一下。一般保存在dependencies中
        - `babel-runtime` 可以按照需求引入。缺点：覆盖不全。一般在写库的时候使用。建议不要直接使用babel-runtime，因为transform-runtime依赖babel-runtime，大部分情况下都可以用`transform-runtime`预设来达成目的
- [core-js](https://github.com/zloirock/core-js) 是 babel-polyfill、babel-runtime 的核心包，他们都只是对 core-js 和 regenerator 进行的封装。core-js 通过各种奇技淫巧，用 ES3 实现了大部分的 ES2017 原生标准库，同时还要严格遵循规范。支持IE6+
    - core-js 组织结构非常清晰，高度的模块化。比如 `core-js/es6` 里包含了 es6 里所有的特性。而如果只想实现 promise 可以单独引入 `core-js/features/promise`
- babel配置文件可为 `.babelrc` 或 `babel.config.js`(v7.8.0)。已`babel.config.js`为例

    ```js
    module.exports = {
        presets: ['@vue/cli-plugin-babel/preset'],
        plugins: [
            // 一般在写库的时候使用，包含了 babel-runtime
            // 配置了 transform-runtime 插件，就不用再手动单独引入某个 `core-js/*` 特性，如 core-js/features/promise，因为转换时会自动加上而且是根据需要只抽离代码里需要的部分
            "transform-runtime",
            
            // 基于vue的预设
            // "@vue/app",
        ]
    }
    ```
- `@babel/cli` 在命令行中使用babel命令对js文件进行转换。如`babel entry.js --out-file out.js`进行语法转换
- 插件和预设（Presets）
    - 基于Babel的插件参考：https://www.babeljs.cn/docs/plugins
    - 需要基于某个环境进行开发，如typescript，则需手动安装一堆 Babel 插件，此时可以使用 Presets(包含了一批插件的组合)
    - 官方 Preset 已经针对常用环境编写了一些 preset。其他社区定义的预设可在[npm](https://www.npmjs.com/search?q=babel-preset)上获取
        - `@babel/preset-env` 对浏览器环境的通用支持
        - `@babel/preset-react` 对 React 的支持
        - `@babel/preset-typescript` 对 Typescript 支持，参考[typescript.md#Webpack转译Typescript现有方案](/_posts/web/typescript.md#Webpack转译Typescript现有方案)
        - `@babel/preset-flow` 如果使用了 [Flow](https://flow.org/en/)，则建议您使用此预设（preset），Flow 是一个针对 JavaScript 代码的静态类型检查器
- 常见安装

```bash
# 语法转换
npm install --save-dev @babel/core @babel/cli @babel/preset-env
# 通过 Polyfill 方式在目标环境中添加缺失的特性
npm install --save @babel/polyfill
```

### npm-run-all

- `npm install npm-run-all --save-dev` 安装
- `npm-run-all` 提供了多种运行多个命令的方式，常用的有以下几个
    - `--serial`: 多个命令按排列顺序执行，例如：`npm-run-all --serial clean build:**` 先执行当前package.json中 npm run clean 命令, 再执行当前package.json中所有的`build:`开头的scripts
    - `--parallel`: 并行运行多个命令，例如：npm-run-all --parallel lint build
    - `--continue-on-error`: 是否忽略错误，添加此参数 npm-run-all 会自动退出出错的命令，继续运行正常的
    - `--race`: 添加此参数之后，只要有一个命令运行出错，那么 npm-run-all 就会结束掉全部的命令

### rollup.js

- Rollup 是一个 JavaScript 模块打包器，可以将小块代码编译成大块复杂的代码，例如 library 或应用程序

## 基础库

### lodash工具类

- [lodash](https://lodash.com/)

### cross-env启动时增加环境变量

### dayjs时间操作

- [dayjs](https://github.com/iamkun/dayjs)，相对 moment 体积更小、[官方文档](https://dayjs.gitee.io/docs/zh-CN/installation/installation)
- 安装`npm i dayjs -S`
- 举例

```js
import dayjs from 'dayjs'

dayjs('2020-01-01').add(1, 'day').format('YYYY-MM-DD'); // 2020-01-02
```

### mathjs数学计算

- mathjs

```js
npm install mathjs -S

import * as math from 'mathjs'

math.add(0.1, 0.2)     //  0.30000000000000004
math.number(math.add(math.bignumber(0.1), math.bignumber(0.2))) // 0.3 math.number转换BigNumber类型为number类型
math.number(math.chain(math.bignumber(0.1)).add(math.bignumber(0.2)).add(math.bignumber(0.3)).done()) // 0.6
```

### 省市区级联

- [vue-area-linkage](https://github.com/dwqs/vue-area-linkage) 省市区选择器(需结合省市区数据)
- [area-puppeteer](https://github.com/dwqs/area-puppeteer) 省市区数据

## AJAX

### axios

- 参考[springboot-vue.md#文件上传下载案例](/_posts/arch/springboot-vue.md#文件上传案例)
- axios基本使用

```js
axios.get("/hello?id=1").then(response => {
    console.log(response.data)
});

// 如果将params换成this.$qs.stringify，后台也无法获取到数据
axios.get("/hello", {
    params: {
        userId: 1,
    }
}).then(response => {
    console.log(response.data)
});
```
#### axios参数后端接受不到 [^2]

- get请求传递数组

    ```js
    let vm = this
    this.$axios.get("/hello", {
        params: {
            typeCodes: ["CustomerSource", "VisitLevelCode"]
        },
        paramsSerializer: function(params) {
            return vm.$qs.stringify(params, {arrayFormat: 'repeat'}) // 此时this并不是vue对象
        }
    }).then(response => {
        console.log(response.data)
    });
    ```
- post请求无法接收
    - 使用`qs`插件(推荐，会自动设置请求头为`application/x-www-form-urlencoded`)
    - `axios`使用`x-www-form-urlencoded`请求，参数应该写到`param`中

        ```js
        axios({
            method: 'post', // 同jquery中的type
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            url: 'http://localhost:8080/api/login',
            params: {
                username: 'smalle',
                password: 'smalle'
            }
        }).then((res)=>{
            
        })
        ```
        - axios的params和data两者关系
            - params是添加到url的请求字符串中的，一般用于GET请求
            - data是添加到请求体body中的，用于POST请求。Spring中可在通过`getUser(@RequestBody User user)`获取body中的数据，从request对象中只能以流的形式获取
            - 如果POST请求参数写在`data`中，加`headers: {'Content-Type': 'application/x-www-form-urlencoded'}`也无法直接获取，必须通过@RequestBody)
        - jquery在执行post请求时，会设置Content-Type为application/x-www-form-urlencoded，且会把data中的数据以url序列化的方式进行传递，所以服务器能够正确解析
        - 使用原生ajax(axios请求)时，如果不显示的设置Content-Type，那么默认是text/plain，这时服务器就不知道怎么解析数据了，所以才只能通过获取原始数据流的方式来进行解析请求数据
        - SpringSecurity登录必须使用POST

### qs插件使用

- qs插件会自动设置请求头为`application/x-www-form-urlencoded`

```js
// 安装：npm install qs -D
import qs from 'qs'
Vue.prototype.$qs = qs;

this.$axios.post(this.$domain + "/base/type_code_list", this.$qs.stringify({
    name: 'smalle'
})).then(response => {

});

// (1) qs格式化日期
// qs格式化时间时，默认格式化成如`1970-01-01T00:00:00.007Z`，可使用serializeDate进行自定义格式化
// 或者后台通过java转换：new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").setTimeZone(TimeZone.getTimeZone("UTC"));
this.$qs.stringify(this.formModel, {
    serializeDate: function(d) {
        // 转换成时间戳
        return d.getTime();
    }
});

// (2) qs序列化对象属性
// 下列对象userInfo默认渲染成 `name=smalle&bobby[0][name]=game&hobby[0][level]=1`(未进行url转码)，此时springboot写好对应的POJO是无法进行转换的，报错`is neither an array nor a List nor a Map`
// 可以使用`allowDots`解决，最终返回 `name=smalle&bobby[0].name=game&hobby[0].level=1`
var userInfo = {
    name: 'smalle',
    hobby: [{
        name: 'game',
        level: 1
    }]
};
console.log(this.$qs.stringify(this.mainInfo, {allowDots: true}))
```

## Vue相关UI库

### Element-UI

- el-drawer

- 防止整个页面被遮住。modal-append-to-body的使用：遮罩层是否插入至 body 元素上，若为 false，则遮罩层会插入至 Drawer 的父元素上

```html
<template>
  <div>
    <el-drawer title="我是标题" :visible="show" :modal-append-to-body="false">
      body
    </el-drawer>
  </div>
</template>
```

### iview

- 参考[iview.md](/_posts/web/iview.md)

### Avue

- [官网](https://avuejs.com)
- [内置函数(全局API，在vue组件中可直接使用this调用)](https://avuejs.com/doc/api)
    - validatenull 校验是否为空(`null/''/0/[]/{}`)
    - findObject 从数组中查找对象，如`const parentIdProp = this.findObject(this.formColumn | this.crudOption.column, 'parentId')`
    - vaildData 校验，如`this.vaildData(this.permission.party_permission_add, false)` 默认根据第一个参数值进行判断，否则取第二个参数为默认值
    - $Print
    - $Clipboard
    - $Log
    - $NProgress
    - $Screenshot
    - deepClone
    - dataURLtoFile
    - isJson
    - setPx
    - sortArrys
    - findArray
    - downFile
    - loadScript
    - watermark
    - asyncValidator
- 内置指令
    - `v-dialogdrag` 作用于dialog，可进行拖拽
- 获取ref
    - 在crud组件中`const avatarRef = this.$refs.crud.getPropRef('avatar')`可获取到表单的avatar图片上传组件元素ref，从而使用`avatarRef.$refs.temp.handleSuccess`进行调用(temp是由于中间动态判断了表单元素)

#### 表格组件常用参数(option)

```js
{
    searchShow: true, // 是否默认显示查询条件区域，设置为不显示时，也可通过表格工具栏手动点击显示
    searchMenuSpan: 6, // 查询列默认占用宽度
    searchLabelWidth: 115, // 查询列文字描述宽度
    searchIcon: true, // 查询条件达到一定个数时，显示更多按钮进行隐藏
    searchIndex: 3, // 和searchIcon结合使用，配置显示的个数

    height: 'auto', // 表格高度自适应，可和calcHeight结合使用. 如果需要高度固定可使用具体数值，如: 270
    maxHeight: '270', // 表格最大高度，如果不使用calcHeight，则可使用此参数显示滚动条
    calcHeight: 90, // 表格自动计算高度，可手动条件以消除滚动条
    border: true, // 实现边框

    selection: true, // 列表可勾选
    tip: false, // 不显示勾选提示，默认了为true显示
    filterBtn: true, // 显示工具栏过滤按钮
    menu: true,
    viewBtn: true, // 弹框查看当前行数据。如果使用行内编辑，则必须设置成false
    addBtn: true, // 弹框新增一行数据。如果使用行内编辑，则必须设置成false
    cellBtn: true, // 开启可编辑表格
    addRowBtn: true, // 可编辑表格新增一行
    cancelBtn: true, // 可编辑时，显示取消按钮，默认true

    highlightCurrentRow: false, // 高亮当前行
   
    dialogDrag: true, // 弹框支持拖拽
    dialogTop: '2%', // 弹框顶部高度
    dialogWidth: '85%', // 弹框宽度

    tabs: true, // 字段分组时，每个组按照TAB横向显示，false则按照折叠菜单上下显示
    span: 6, // 表单编辑时，每列占用宽度，默认12
    labelWidth: 115, // 表单列文字描述宽度
    column: [
        {
            label: '销售订单号', // 字段中文名
            prop: 'saleNo', // 字段名
            type: 'input', // 字段类型：影响表单编辑。input/select/radio/tree/...
            
            search: true, // 会在查询条件中显示
            searchslot: true, // 开启当前列自定义search，在dom中还需增加`<template slot-scope="{disabled, size}" slot="saleNoSearch">`(以`xxxSearch`命名)
            searchOrder: 10, // 搜索字段排序，越大越靠前

            hide: true, // 列表中隐藏
            slot: true, // 列表显示时自定义列，在dom中还需增加`<template slot="saleNo" slot-scope="scope">`
            align: 'left', // 列表显示时，文字位置
            format: 'yyyy-MM-dd HH:mm', // 列表显示和表单显示格式化
            formatter: () => {}, // 格式化函数
            
            formslot: true, // 表单插槽，需要有`<template slot="saleNoForm" slot-scope="{type,disabled}">`, type=add/edit
            labelslot: true, // 需要 slot="saleNoLabel" 
            errorslot: true, // 需要 slot="saleNoError" 
            multiple: true, // 是否可多选
            editDisplay: true, // 编辑时显示，默认true
            span: 6, // 自定义当前列表单编辑时的占用宽度
            tip: '表单编辑时，鼠标放到表单元素框上的提示语',
            rules: [
              {
                required: true, // 表单编辑时的校验规则，必填
                message: '请输入字典代码',
                trigger: 'blur',
              },
            ],
            change: ({ value }) => {}, // 表单编辑时，值发生变化事件
            valueFormat: 'yyyy-MM-dd HH:mm:ss', // 实际值(提交到后台的值)格式化成字符串，一般用在 type='datetime'
            value: 1, // 表单编辑时的默认值

            searchFilterable: true, // 表格搜索是否可前台过滤，默认false
            filterable: true, // 表单是否可前台过滤
            remote: true, // 开启远程搜索，默认为false，此时dicUrl中{{key}}为用户输入的关键字
            // 有了dictData和dicUrl，则列表显示默认也会自动进行翻译字典值，字典中无则显示实际值
            dicData: [{
              name: '自定义字典',
              code: 1
            }],
            // 下拉时(表单编辑和查询条件)，字典资源路径，默认返回数组项为 lable/value 键值对才会自动匹配
            // 修改URL后需要更新字段，this.$refs.[form | crud].updateDic('saleNo')
            dicUrl: '/apps/system/dict/findForDict?parentCode=goods_sale_type&name={{key}}',
            props: {
              value: 'code', // 和 dicUrl 结合使用，用来指明后台返回数据结构中实际值的字段名
              label: 'name',
            },
            dicMethod: 'post', // 默认请求方式为GET，此处设置为POST
            dicQuery: {
              a: 1 // 获取字典资源时的额外参数
            },
            // 格式化ajax获取的字段数据，参考 src/core/dic.js#sendDic
            dicFormatter(res) {
                const list = res.data
                return list
            },

            // type=tree时
            defaultExpandAll: false,
            // 使用dic属性无效
            // 使用 dicUrl 属性，但是每次会进行请求
            // 使用 dicData属性。当直接写成 dicData: this.treeData 无法在弹框中显示树形数据；还需在获取到数据后修改此属性
            dicData: this.treeData,
            // 使用 lazy 和 treeLoad，即懒加载，会出现第一次无法选中
            // lazy: true,
            // treeLoad: (node, resolve) => {
            //   if (node.isLeaf) {
            //     return resolve([])
            //   }
            //   const parentId = (node.level === 0) ? '0' : node.data.id;
            //   findDeptLazyTree({ parentId }).then(res => {
            //     resolve(res.data.map(item => {
            //       return {
            //         ...item,
            //         leaf: !item.hasChildren
            //       }
            //     }))
            //   });
            // },

            // type=select时, 配置typeslot卡槽开启即可自定义下拉框的内容
            typeslot: true, // 需要增加dom `<template slot="saleNoType" slot-scope="{item,value,label}">`
            // typeformat配置回显的内容，但是你提交的值还是value并不会改变，无需插槽
            typeformat(item, label, value) {
                return `名:${item[label]}-值:${item[value]}`
            },
        },
        {
            labelWidth: 0, // 字段中文名宽度
            label: '',
            prop: 'saleOrderDetailVo',
            span: 24, // 占一整行
            hide: true, // 不显示在列表中
            formslot: true, // 表单编辑自定义。此时定义slot="saleOrderDetailVoForm"即可自定义此列。可嵌套另外一个crud组件
        }
    ],
    // 字段分组
    group: [
    ]
}
```

#### 原理介绍

- 目录结构

```bash
packages # 实际重写组件目录
    core
        common/porps.js # 通用 vue 属性，最终会被mixins
        common/event.js # 通用事件，最终会被mixins
        common/locale.js # 国际化，最终会被mixins
        components/form/index.vue # 表单组件动态判断(临时)，最终会引入avue-form(如：element-ui/form)
        components/form/index.vue
    element-ui # 基于 element-ui 框架重写的组件目录
        crud # avue-crud 组件
            column.vue # 表格列组件：动态组件列 dynamic-column，其他组件列 el-table-column
        form # avue-form 组件
        upload # 文件上传组件
    vant # 基于 vant 框架
src
```
- packages/element-ui/upload/index.vue

```html
<template>
  <!-- bem函数，基于组件名生成组件顶级class -->
  <div :class="b()"
       v-loading.lock="loading">
    <el-upload :class="b({'list':listType=='picture-img','upload':disabled})"
        ...
    </el-upload>
  </div>
</template>

<script>
import create from "core/create"; // 创建组件方法，可基于此方法再次混入功能，也可修改给组件名增加前缀
import props from "../../core/common/props.js"; // 混入 vue 通用属性
import event from "../../core/common/event.js"; // 混入通用事件
import locale from "../../core/common/locale"; // 混入国际化功能
import upload from '../../core/common/upload' // 混入上传功能
export default create({
  name: "upload",
  mixins: [props(), event(), upload(), locale],
  data () {
    return {
      menu: false,
    };
  }
});
</script>
```
- 混入功能举例说明

```js
// packages/core/common/props.js
watch: {
    // 所有组件都有一个text属性，当text属性变化后调用 handleChange 方法（event.js，见下文），在 handleChange 中最后触发了 input 事件，从而监听到 value 属性变化，调用 initVal 进行实际值处理（如传入参数为逗号分割的字符串，可经过此初始化变成数组）
    text: {
        handler (n, o) {
            this.handleChange(n)
        }
    },
    value: {
        handler (n, o) {
            this.initVal();
        }
    }
},

// packages/core/common/event.js
initVal () {
    this.text = initVal({
        type: this.type,
        multiple: this.multiple,
        dataType: this.dataType,
        value: this.value,
        separator: this.separator,
        callback: (result) => {
            this.stringMode = result;
        }
    });
},
handleChange (value) {
    let result = value;
    if (this.isString || this.isNumber || this.stringMode || this.listType === "picture-img") {
        if (Array.isArray(value)) result = value.join(',')
    }
    if (typeof this.change === 'function' && this.column.cell !== true) {
        this.change({ value: result, column: this.column });
    }
    this.$emit('input', result);
    this.$emit('change', result);
}
```

### ag-grid超强表格

- [官网案例](https://www.ag-grid.com/example.php)、[整合vue案例](https://github.com/ag-grid/ag-grid-vue-example)

### vxe-table

- 一款基于Vue的表格插件，支持大量数据渲染，编辑表格等功能
- [github](https://github.com/x-extends/vxe-table)、[doc](https://xuliangzhan_admin.gitee.io/vxe-table/#/table/start/install)
- 优点
    - 大数据表格
    - 自带打印功能：区域、分页、模板、样式等打印功能
- 说明
    - vxe-table 只能用于静态列（vxe-table-column，避免使用 v-for 去动态修改，如果要动态列其使用 v-grid）
    - vxe-grid 支持一切动态场景
        - grid 继承 table 100%的功能，vxe-grid 的性能也比 vxe-table 快一倍
        - vue 多数情况还是推荐使用语义化标签的形式；而对于动态场景用 grid 就更加灵活，可以实现远程配置化一体化
- **表格显示/隐藏后样式丢失问题，弹框表格列宽问题**
    - `auto-resize`或`sync-resize` 绑定指定的变量来触发重新计算表格。参考：https://xuliangzhan_admin.gitee.io/vxe-table/#/table/advanced/tabs
- 和iview等组件结合使用时，modal等z-index存在冲突(如表格列过长提示)，建议弹框和弹框中涉及z-index的元素使用同一组件，如全部使用vxe-table
- 多选 + 修改页面表格数据(仅修改页面数据)。选中事件方法和选中所有事件方法是两个方法

```js
// 获取行记录
let checkboxRow = this.tableRef.getCheckboxRecords();
const selectRecords = checkboxRow.map((item) => item.id); // 如果返回数据中没有id字段，则在渲染时会自动生成一个row_xxx的唯一id
if (!selectRecords || selectRecords.length === 0) {
    alert("请先选择记录");
    return;
}
// 调用修改数据api略...
// 修改页面行记录数据
checkboxRow.forEach((row) => {
    row.validStatus = 0;
    this.$refs.tableRef.reloadRow(row, null, 'validStatus'); // 仅修改单个字段
    // this.$refs.tableRef.reloadRow(currentRow, rowNewData, null); // 基于rowNewData修改一整行的数据(如果rowNewData无表格列定义的字段将会置空)
});

// 从列表中移除数据行
// 1.修改页面显示缓存，this.allData数据并没有删除
this.$refs.tableRef.remove(row)
this.$refs.tableRef.removeCheckboxRow() // 移除选中行
// 2.修改页面数据，this.allData数据删除了
this.allData = this.allData.filter((item) => item.id != row.id)
this.$refs.tableRef.loadData(this.allData)

// 重新加载整个表格数据
this.$refs.tableRef.loadData(this.allData);
```
- 监听行的选中事件

```js
// <vxe-table @checkbox-change="checkboxChange">
checkboxChange(table, event) {
    // table对应key如下
    // "row"(当前选中或取消选中行), "checked"(操作完当前行后的选中状态), "items"(所有行数据), "data"(所有行数据), "records"(目前选中的所有行数据), "selection"(目前选中的所有行数据)
    // "$table", "$grid", "$event", "reserves", "indeterminates", "$seq", "seq", "rowid", "rowIndex", "$rowIndex", "column", "columnIndex", "$columnIndex", "_columnIndex", "fixed", "type", "isHidden", "level", "visibleData", "cell"
}
```
- 表格筛选
    - 通过设置 filters 属性和 filter-method 方法可以开启列筛选功能，通过 filter-multiple=false 设置为单选
        - filters不支持动态修改筛选配置，可通过setFilter方法

            ```js
            this.hobbyOpts = XEUtils.orderBy(XEUtils.uniq(this.listData.map(x => x.hobby))).map(x => {
                return {label: x, value: x}
            })
            this.$refs.userTable.setFilter('hobby', this.hobbyOpts)
            ```
    - 如果是服务端筛选，只需加上 filter-config={remote: true} 和 filter-change 事件就可以实现
        - 本地筛选和服务端筛选不能同时使用，会优先触发filter-change，而不触发filter-method 
- 可编辑表格、滚动分页

```html
<!-- 
edit-config: 
    manual 手动触发+监听cell-dblclick双击事件
    showStatus 展示修改状态，左上角红色小角标
    mode 修改时，默认整行转成可编辑状态
    autoClear 自动保存(关闭修改) => **input类型的需要配合 immediate: true**
 -->
<vxe-table
    ref="table"
    border
    resizable
    show-overflow
    keep-source
    row-id="id"
    :loading="loading"
    @scroll="scroll"
    @checkbox-change="checkboxChange"
    @cell-dblclick="data => editRow(data.row)"
    :checkbox-config="{ checkMethod: checkMethod }"
    :edit-config="{ trigger: 'manual', mode: 'row', showStatus: true, autoClear: false }"
    @edit-actived="data => (data.row.editingMode = true)"
    @edit-closed="data => (data.row.editingMode = false)"
    @scroll="scroll"
>
    <vxe-table-column v-if="feeItemEdit" title="操作" width="80">
        <template v-slot="{ row }">
            <div v-if="$refs.table.isActiveByRow(row)">
                <Button
                    v-if="row.editingMode"
                    @click="saveRow([row])"
                    type="primary"
                    size="small"
                    icon="md-checkmark"
                    shape="circle"
                    style="margin-right:5px;"
                ></Button>
                <Button @click="cancelRow(row)" type="warning" size="small" icon="md-close" shape="circle"></Button>
            </div>
            <div v-else>
                <Button
                    @click="editRow(row)"
                    size="small"
                    icon="ios-create"
                    shape="circle"
                    style="margin-right:5px;"
                ></Button>
                <Button @click="deleteMulti(row)" size="small" icon="ios-trash" shape="circle"></Button>
            </div>
        </template>
    </vxe-table-column>

    <vxe-table-column description="结算客户" field="bizClearingCustomerId" :title="$t('customer_name1')" width="300" :edit-render="{}">
        <template v-slot:edit="scope">
            <Select
                :ref="'bccn' + scope.row.id"
                v-model="scope.row.bizClearingCustomerId"
                @on-change="
                    () => {
                        scope.row.bizClearingCustomerName = getSelectFilterableLabel(scope.row.bizClearingCustomerId, dictMap.customerList)
                        $refs.table.updateStatus(scope)
                    }
                "
                transfer
                filterable
                :remote-method="clearingCustomerRemote"
                >
                <Option v-for="item in dictMap.customerList" :value="item.value" :label="item.label" :key="item.value">
                    <span v-if="item.customerNo">{{ item.customerNo }}：</span>
                    {{ item.label }}
                </Option>
            </Select>
        </template>
        <template v-slot="{ row }">{{ row.bizClearingCustomerName }}</template>
    </vxe-table-column>
    <vxe-table-column field="feeCurrentRate" title="汇率" width="90" :edit-render="{ name: 'input', immediate: true }"></vxe-table-column>

    <!-- 自定义筛选 -->
    <vxe-table-column field="orderType" title="订单类型" sortable :filters="orderTypeList"></vxe-table-column>
    <vxe-table-column field="orderNo" title="订单号" sortable
        :filters="[{data: ''}]" :filter-method="({ option, row }) => row.orderNo === option.data">
        <template #filter="{ $panel, column }">
            <AutoComplete
                v-for="(option, index) in column.filters" :key="index"
                type="type"
                v-model="option.data"
                :data="row._orderNoFilterList"
                @on-search="(v) => {
                    row._orderNoFilterList = allData.filter(x => x.orderNo && x.orderNo.indexOf(v) >= 0).map(x => x.orderNo)
                }"
                @on-change="(value, $event) => $panel.changeOption($event, !!option.data, option)"
                @keyup.enter.native="$panel.confirmFilter()"
            ></AutoComplete>
        </template>
    </vxe-table-column>
</vxe-table>

<script>
fetchData() {
    this.$ajax({}).then(({ data }) => {
        this.dataList = data.list
        // 从结果集中提取筛选下拉，并设置到对应表格中
        this.orderTypeList = XEUtils.orderBy(XEUtils.uniq(this.dataList.map(x => x.orderType))).map(y => {
            return {label: y, value: y}
        })
        this.$refs.table.setFilter('orderType', this.orderTypeList)
    })
},
editRow(row) {
    if (!this.checkRow()) return false
    this.$refs.table.setActiveRow(row).then(() => {
        // 远程搜索解决方案
        this.$refs['bccn' + row.id].setQuery(row.bizClearingCustomerName)
    })
},
cancelRow() {
    const table = this.$refs.table
    table.clearActived().then(() => {
        table.revertData()
    })
},
checkRow() {
    const { insertRecords, updateRecords } = this.$refs.table.getRecordset()
    if (insertRecords.length > 0 || updateRecords.length > 0) {
        this.$Message.warning('您有待保存数据，请先保存')
        return false
    }
    return true
},
getSelectFilterableLabel(value, list, valueProp = 'value', labelField = 'label') {
    const item = XEUtils.find(list, item => item[valueProp] == value)
    return item ? item[labelField] : null
},
// 滚动分页
scroll (table, $event) {
    this.vexScrollPage(
        table,
        this.tableRef['$el'],
        this.allData,
        this.searchForm,
        this.fetchData
    )
},
vexScrollPage(table, el, allData, searchForm, fetchData) {
  if (allData.length >= searchForm.pageTotal) {
    return
  }
  let scrollHeight = el.getElementsByClassName('body--wrapper')[1].scrollHeight
  const scrollHeight2 = el.getElementsByClassName('vxe-body--y-space')[0].style.height.replace('px', '')
  if (scrollHeight2) {
    // 矫正，有时候scrollHeight会多出一个48px值导致无法获取下一页
    scrollHeight = Number(scrollHeight2)
  }
  const clientHeight = el.getElementsByClassName('body--wrapper')[1].clientHeight
  const scrollTop = el.getElementsByClassName('body--wrapper')[1].scrollTop
  if (scrollHeight === clientHeight + scrollTop) {
    searchForm.pageCurrent = searchForm.pageCurrent + 1
    fetchData()
  }
}
</script>
```
- vxe-grid

```html
<!-- toolbar-config: 工具栏，开启字段自定义、打印、导出；custom-config：字段自定义配置，此时将自定义字段保存到localStorage，否则每次刷新会重置（需要定义全局唯一ID，整个项目全部保存在名为VXE_TABLE_CUSTOM_COLUMN_VISIBLE的localStorage中） -->
<vxe-grid size="mini" ref="notShipTable" id="TransferManageNotShipTable"
    border resizable show-overflow keep-source
    class="sq-vxe__toolmin sq-vxe__modal"
    :loading="notShipLoading"
    :height="scrollerHeight"
    :columns="notShipCols"
    :toolbar-config="{custom: true, export: true, print: true}"
    :custom-config="{storage: {visible: true}}" :exportConfig="{}" :printConfig="{}">
</vxe-grid>
<script>
create() {
    // 不要直接在DOM中调用 getColumns, 否则编辑点击新增/编辑等按钮是，此方法会重复调用从而导致排序丢失
    this.notShipCols = this.getColumns('notShip')
}
</script>

<!-- 解决和iview Tabs结合使用问题：modal不跟随当前Tab展示 -->
<style lang="less">
.sq-vxe__toolmin {
  .vxe-grid--toolbar-wrapper {
    display: inline-block;
    position: absolute;
    right: 0;
    top: -50px;
    .vxe-toolbar {
      height: auto;
    }
  }
}
.ivu-tabs-tabpane {
  position: relative;
  .vxe-table {
    .vxe-modal--wrapper,.vxe-modal--box {
      position: absolute;
    }
  }
}
.sq-vxe__modal {
  .vxe-modal--box {
    top: 70px !important;
    left: 500px !important;
  }
}
@media screen and (max-width: 1400px){
  .sq-vxe__modal {
    .vxe-modal--box {
      top: 0px !important;
      left: 150px !important;
    }
  }
}
</style>
```
- 打印，[参考](https://xuliangzhan_admin.gitee.io/vxe-table/#/table/module/print)

```js
import VXETable from 'vxe-table'
VXETable.print({
    sheetName: '打印自定义模板',
    style: printStyle, // 自定义样式（传入content的html中只能写行内样式，块样式需从此处传入）
    // 区域打印，可自己写组件，而不是通过字符串拼接。但是有个问题，如果使用了vxe-table等插件渲染html元素，则样式会丢失，可自己写简单的html标签和样式解决
    content: nodeToString(this.$refs.printDivId.$el)
})

nodeToString ( node ) {
    let tmpNode = document.createElement("div");
    tmpNode.appendChild(node.cloneNode(true));
    let str = tmpNode.innerHTML;
    tmpNode = node = null;
    return str;
}
```

### MyUI

- [MyUI](http://newgateway.gitee.io/my/)
- 包含基础组件、**图表**、**地图**、关系图、**大屏**等功能
    - 内置了百度、高德
    - 支持与ECharts结合实现散点、飞行迁徙等基于地理位置的图表

### Quasar

- `Quasar`：基于Vue的UI框架，可以整合`Cordova`开发移动App，也可以整合`Electron`开发桌面程序
- 常用习惯
    - `Ripple` 可以使按钮展示出波纹，不使用此波纹则需要去掉`quasar.conf.js` - `directives` 中的 `Ripple` 项

## 底层硬件库

### Clipboard 复制内容到剪贴板

- 必须要绑定Dom
- 必须要触发点击事件（触发其他Dom的点击事件，然后js触发目的dom的点击事件也可）

### 扫码/条码生成

#### H5页面扫码

- 在微信浏览器打开H5页面，可引入微信的js SDK解决（需域名和微信公众号绑定）
- 在系统浏览器打开H5页面
    - 基于[jsQR](https://github.com/cozmo/jsQR)、[vue-qrcode-reader(本质基于jsQR)](https://github.com/gruhn/vue-qrcode-reader)
        - 调取摄像头(进行录像)识别二维码，每个页面需要同意调用摄像头(网页可设置永久同意)
        - 优点是无需拍照确认识别(会自动识别，出错率低)，**但是必须要https才行**
    - 基于[jsqrcode](https://github.com/LazarSoft/jsqrcode)库，可进行二维码/条形码解析，可生成条形码
        - 参考：https://www.cnblogs.com/yisuowushinian/p/5145262.html，此方案在前端 js 解析二维码，依赖`jsqrcode`
        - 这个库已经支持在浏览器端呼起摄像头的操作了，但是依赖一个叫`getUserMedia`的属性，该属性移动端的浏览器支持的都不是很好，低版本只能间接的上传图片的方式解析二维码
        - 此插件需要配合 zepto.js 或者 jQuery.js 使用(主要用来拍照的，如果使用uni-app则不需要此依赖，可使用uni.chooseImage拍照)；webpack打包需要canvas
            - 安装 `cnpm install jsqrcode -S`、`cnpm install canvas -S`
        - 扫码时无扫码框，需要点击拍照 - 确定识别（iphone7扫二维码成功，条形码不成功）
        - 缺点需要确认拍照进行识别，拍照需要清晰，出错率高
    - 基于`quagga.js`库，可进行条形码解析
        - 如uni-app插件：https://ext.dcloud.net.cn/plugin?id=1619

#### H5页面扫码案例（基于uni-app）

- 扫码流程
    - 通过微信浏览器访问的，默认调用微信扫码。需要引入`weixin-js-sdk`
    - 通过手机普通浏览器访问的，如果是https模式访问，则调用摄像头录像扫码，需引入`vue-qrcode-reader`
    - 如果是普通浏览器访问，且以http默认访问，则调用拍照扫码，需引入`jsqrcode`和`canvas`
- scan.vue

```vue
<template>
  <div>
	<text class="lg cuIcon-scan margin-right" @click="handleScan" style="font-size: 40upx;"></text>
	
    <span v-if="showQrcode">
		<view class="cu-modal show" v-show="showQrcodeDialog">
			<view class="cu-dialog">
				<view class="cu-bar bg-white justify-end scan-close">
					<view class="action" @tap="closeDialog">
						<text class="cuIcon-close text-red"></text>
					</view>
				</view>
				<view class="bg-white">
					<qrcode-stream @decode="onDecode" @init="onInit" />
				</view>
			</view>
		</view>
	</span>
  </div>
</template>

<script>
import wechat from '@/utils/wechat.js' 
import { QrcodeStream } from 'vue-qrcode-reader' // "vue-qrcode-reader": "^2.3.9"
let Canvas = require('canvas') // "canvas": "^2.6.1"
let jsqrcode = require('jsqrcode')(Canvas) // "jsqrcode": "^0.0.7"

export default {
  components: { QrcodeStream },
  props: {
	  callback: {
		  type: Function,
		  default: () => {}
	  }
  },
  data () {
    return {
	  showQrcode: false,
	  showQrcodeDialog: false
    }
  },
  methods: {
    onInit(promise) {
      promise.then(() => {
		this.showQrcodeDialog = true
      }).catch(error => {
		console.log(error);
		this.showQrcode = false
		
		let errorMessage = ""
		if (error.name === 'NotAllowedError') {
		  errorMessage = '请允许访问摄像头'
		} else if (error.name === 'NotFoundError') {
		  errorMessage = '此设备无摄像头'
		} else if (error.name === 'NotSupportedError') {
		  errorMessage = 'Seems like this page is served in non-secure context (HTTPS, localhost or file://)'
		} else if (error.name === 'NotReadableError') {
		  errorMessage = '无法访问摄像头，请确认摄像头是否正常工作'
		} else if (error.name === 'OverconstrainedError') {
		  errorMessage = '摄像头不兼容'
		} else {
		  errorMessage = 'UNKNOWN ERROR: ' + error.message
		}
		
		// 尝试使用jsqrcode
		uni.chooseImage({
			sourceType: ['camera'],
			sizeType: 'original',
			count: 1,
			success: (res) => {
				let image = new Image()
				let that = this
				image.onload = function() {
				  let result
				  try {
				    result = jsqrcode.decode(image)
				    that.callback(result)
				  } catch(e) {
					console.error(e);
					
					errorMessage += '；请确认是否为有效二维码或机器不兼容'
					uni.showToast({
						title: errorMessage,
						icon: 'none',
						duration: 4000
					})
				  }
				}
				image.src = res.tempFilePaths
			},
			fail: (err) => {
				console.log(err);
			}
		})
      })
    },
	onDecode (result) {
		this.closeDialog()
		this.callback(result)
	},
	handleScan () {
		if(uni.getStorageSync("apsm-h5-wx")) {
			wechat.scan((res) => {
				this.callback(res)
			})
		} else {
			this.showQrcode = true
		}
	},
	closeDialog() {
		this.showQrcodeDialog = false
		this.showQrcode = false
	}
  }
}
</script>
<style>
.scan-close {
	position: absolute;
	top: 0;
	right: 0;
	z-index: 1;
	background: transparent;
}
</style>
```
- wechat.js

```js
// #ifdef H5
import wx from 'weixin-js-sdk';
// #endif

const wechat = {
    scan(callback) {
        if(uni.getStorageSync("apsm-h5-wx")) {
            wx.scanQRCode({
                needResult: 1, // 默认为0，扫描结果由微信处理，1则直接返回扫描结果
                scanType: ["qrCode","barCode"], // 可以指定扫二维码还是一维码，默认二者都有
                success: function (res) {
                    callback(res.resultStr)
                },
                error: function(res) {
                    uni.showToast({
                        title: res,
                        icon: 'none'
                    });
                }
            });
        } else {
            uni.showToast({
                title: '仅支持在微信中进行扫码',
                icon: 'none'
            });
        }
    }
}
export default wechat
```
- 调用

```vue
<template>
    <div>
        <Scan :callback="handleScan"></Scan>
    </div>
</template>

<script>
export default {
    methods: {
        handleScan (res) {
            if(res) {
                uni.navigateTo({
                    url: './person?id=' + res
                });
            } else {
                uni.showToast({
                    title: "未知二维码",
                    icon: 'none'
                });
            }
        }
    }
}
</script>
```

#### 条码生成

- 相关插件
    - `jsqrcode` 可生成二维码
    - `jsbarcode` 可生成条形码
    - 对应的vue插件
        - [vue-barcode](https://github.com/lindell/vue-barcode)
        - [vue-qr](https://github.com/Binaryify/vue-qr)
        - 使用相对简单，参考：https://blog.csdn.net/qq_44833743/article/details/108773476

### 打印

- 常见打印纸大小(宽mm*高mm，可在wps中查看)：A1 = {841,594}, A2 = {420,594}, A3 = {420,297}, **A4 = {210,297}**, A5 = {210,148}, A6 = {105,148}, A7 = {105,74}, A8 = {52,74}, B1 = {1e3,707}, B2 = {500,707}, B3 = {500,353}, B4 = {250,353}, B5 = {250,176}, B6 = {125,176}, B7 = {125,88}, B8 = {62,88} [^3]

    ![a4-size.png](/data/images/web/a4-size.png)
- web打印问题(分页问题等)
    - 可使用 **`page-break-after`** 等css参数解决，如`<div style="page-break-after: auto | always"></div>`。参考：https://www.w3school.com.cn/cssref/index.asp#print
    - 修改默认打印边距 **`@page {margin: 24px 18px 0 18px;}`**，或者再chrome打印预览时通过自带界面修改
    - 修改纸张方向 **`@page {size: portrait | landscape;}`**，其中portrait纵向、landscape横向，设置后则无法在预览页面修改。谷歌支持，火狐85.0还不支持
    - 至于mm和px换算
        - 公制长度单位与屏幕分辨率进行换算时，必须用到一个DPI(Dot Per Inch, 像素/英寸)指标。网页打印中，默认采用的是96dpi(像素/英寸)，而非72dpi
        - **A4为 210mm\*297mm，而1英寸=25.41mm，浏览器默认为96dpi(像素/英寸)，因此对应像素为 794px\*1123px**
            - 此处A4，打印页边距设定为 0mm 时，网页内最大元素的分辨率794×1123
            - 可设置div高度为297mm，然后通过js获取div.clientHeight得出像素高度
        - 通过高度计算时，一般结合div的clientHeight进行计算，还需考虑页面边距。**通过 1123px 等像素和手动计算高度分页，总是存在误差，效果不好**
    - 如果元素未`display: none;` 则不会显示在打印界面
    - table打印问题(参考下文案例)
        - table包含thead、tfoot(写在tbody上面)、tbody
        - 如果一个表格太长，会自动分页，则thead和tfoot会在每一页出现(有说需额外设置`display: table-header-group`，实测无需)
        - 如果不希望thead重复出现，可将表头行写到tbody中
        - 当table分页后，没一页会自动出现一个分页横线，暂未找到简单方法去掉。可通过增加`<tfoot></tfoot>`(里面不要有数据，否则可能会出现tfoot边框无法去掉，有时候也不管用)，来占位，并设置小page边距
        - 当有多个小table时，需要自动判断一页显示的table个数。如vue，先渲染出页面，再计算每个table的高度，当超过一定高度，则增加一个`<div style="page-break-after: always"></div>`使其自动分页
- 基于[lodop](http://www.lodop.net/index.html)打印控件
- 基于[hiprint](http://hiprint.io/)插件
    - 特点：基于Jquery；可视化配置模板，自动分页打印；可免费使用
    - 缺点：源代码没开源，没有抽离 npm 包
    - 基于vue使用参考：https://blog.csdn.net/byc233518/article/details/107705278
- 基于[print-js](https://printjs.crabbly.com/)
- 使用[vxe-table](#vxe-table)等插件自带打印功能
- vue和electron打印问题

```js
// 方案一(原生API，不推荐)：VUE和electron中均可正常局部打印，只不过打印完主界面会刷新。且使用<div style="page-break-after:always"></div>强制分页也存在问题
let doc = document
let oldHtml = doc.body.innerHTML;//将body内容先行存储
let printbox = doc.getElementById("printPageId").innerHTML;//再将所要打印区域内容赋值给body
doc.body.innerHTML = printbox;//再将所要打印区域内容赋值给body
window.print();//调用全部打印事件
doc.body.innerHTML = oldHtml;//将body内容再返回原页面。必须，否则页面空白
window.location.reload();//打印取消后刷新页面防止按钮不能点击。必须

// 方案二(基于jquery)：未测试
function toPrint(obj) {
	var newWindow=window.open("打印窗口","_blank");
	var docStr = obj.innerHTML; // 可使用分页css
	var str = '<!DOCTYPE html>'  
	    str +='<html>'  
	    str +='<head>'  
	    str +='<meta charset="utf-8">'  
	    str +='<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">'
	    str +='</head>'  
	    str +='<body style="-webkit-font-smoothing: antialiased;-moz-osx-font-smoothing: grayscale;">'  
	    str +='<div style="width:250px;height:300px;">'
	    str += docStr
	    str += '</div>'
	    str +='</body>'  
	    str +='</html>'  
	  newWindow.document.write(str);
	  newWindow.document.close();
	  newWindow.print();
	  newWindow.close();  
}

// 方案三(不推荐)：VUE中可正常新开标签，打印后关闭；但是electron中无法弹出打印界面
this.webviewHref = this.$router.resolve({
    path: "/myPrint?orderId=1"
}).href
let newWindow = window.open(this.webviewHref, "_blank"); // 打开新页面，相当于局部打印
let oldMatched = false
let matched = false
newWindow.onload = function() {
    newWindow.matchMedia('print').addListener(function(e) {
        oldMatched = matched
        matched = e.matches
        if (oldMatched && !matched) {
            // 点击打印或取消
            newWindow.close();
        }
    })
}
newWindow.print();

// 方案四(基于print-js, `npm i print-js`): 可局部打印正常分页，VUE可正常打印；electron不会跳预览页面，但是可打印；可使用<div style="page-break-after:always"></div>强制分页
// 将要打印的数据放在主页面进行隐藏
<div style="width:0; height:0; overflow: hidden">
    <Print id="printPageId" :rows="checkboxRecords" @on-change="onPrint"/>
</div>

import printJS from 'print-js'
onPrint() {
    this.$nextTick(() => {
        printJS({
            printable: 'printPageId',
            type: 'html',
            // 防止Print组件中的样式不起作用
            targetStyles: ['*'],
            font: '',
            font_size: ''
        })
    })
}
// 基于electron的打印，可成功获取打印机，webview未测试成功。参考：https://zhuanlan.zhihu.com/p/63019335
```
- table打印案例

```html
<div class="sq-print">
    <div class="header" style="padding-bottom: 6px;">
        <div class="main-title">打印报表标题</div>
        <div class="sub-title">Print Demo</div>
        <div>{{ dayjs().format('YYYY年MM月DD日') }}</div>
    </div>
    <div class="content" style="font-size: 12px;">
        <div v-for="(group, index) in groupList" :key="index" style="padding-bottom: 25px;">
            <table :ref="`table${index}`">
                <!-- 部分时候表格分页直接到页底边了 -->
                <tfoot></tfoot>
                <!-- 只有增加了tr>td才会在底部留一点空白，但是存在另外一个问题：td会有一条横线无法去除 -->
                <!-- <tfoot style="border: none;background-color: #fff;color: #fff;">
                    <tr style="border: none;background-color: #fff;color: #fff;">
                        <td style="border: none;background-color: #fff;color: #fff;"></td>
                    </tr>
                </tfoot> -->
                <tbody>
                <tr style="text-align:center;">
                    <td style="width: 22%;">标题1<br/>A</td>
                    <td style="width: 14%;" colspan="2">标题2<br/>B</td>
                    <td style="width: 10%;">标题3<br/>C</td>
                    <td style="width: 5%;">标题4<br/>D</td>
                    <td style="width: 5%;">标题5<br/>E</td>
                    <td style="width: 10%;">标题6<br/>F</td>
                    <td style="width: 6%;">标题7<br/>G</td>
                    <td style="width: 6%;">标题8<br/>&nbsp;</td>
                    <td style="width: 6%;">标题9<br/>&nbsp;</td>
                    <td style="width: 16%;text-align:left;">
                    <span>标题10</span><br/>
                    <span style="border-top: 1px solid #000;width:100%;display:inline-block;">J</span>
                    </td>
                </tr>
                <tr v-for="(row, rindex) in group.list" :key="rindex">
                    <td v-for="(column, cindex) in groupField" :key="cindex" :style="{width: column.indexOf('B') > 0 ? '7%' : ''}">
                        <!-- 前后增加空格 -->
                        {{ '&nbsp;' + row[column] + '&nbsp;'}}
                    </td>
                    <td></td>
                    <td></td>
                    <td></td>
                    <td>XXX</td>
                </tr>
                </tbody>
            </table>
            <!-- 判断是否需要分页，只有二次渲染才可（第一次需要渲染出表格，并基于表格计算高度，从而进行第二次渲染） -->
            <div v-if="group.pageBreak" style="page-break-after: always"></div>
        </div>
    </div>
</div>

<script>
import './print.less'

export default {
  name: 'ReportPrint',
  data () {
    return {
      dataList: [],
      groupList: [],
      groupField: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      heightSum: 100,
      checkedHeight: false
    }
  },
  watch: {
    dataList (n) {
      this.initGroup(n)
    },
    groupList (n) {
      this.checkBreak()
    }
  },
  created () {
    this.initGroup(this.dataList)
    this.checkBreak()
  },
  methods: {
    initGroup (data) {
      // ... 大致结构
      this.groupList = [{
        pageBreak: false,
        list: []
      }, ...]
    },
    checkBreak () {
      // 每一页可以打印 760px * 1075px
      this.$nextTick(() => {
        if (this.checkedHeight || this.groupList.length === 0) {
          return
        }
        let pre = null // 循环的上一个table
        for (let index = 0; index < this.groupList.length; index++) {
          const table = this.$refs[`table${index}`]
          const curHeight = table[0].clientHeight + 25 // 25为padding
          this.heightSum += curHeight
          if (this.heightSum > 1075) {
            // 加上次table则会超出长度，从而设置上一个table需要分页，并设置下一次循环高度为当前table高度
            pre.pageBreak = true
            this.heightSum = curHeight
          }
          pre = this.groupList[index]
        }
        // 重新渲染出分页div
        this.groupList = JSON.parse(JSON.stringify(this.groupList))
        this.checkedHeight = true
      })
    }
  }
}
</script>

<style>
/* print.less */
.sq-print {
  @page { margin: 20pt 16pt 0 16pt; }
  color: #000;
  table { width: 100%; min-height: 24px; line-height: 24px; text-align: left; border-collapse: collapse; margin: 0 auto; }
  table thead tr th, table tbody tr td { border: 1px solid #000; }
  .header { margin-bottom: 5px; text-align: center; font-size: 16px; }
  .header .main-title { font-weight: 700; font-size: 24px; }
  .header .sub-title { margin: 5px 0; }
}
</style>
```

### 生成PDF

- [jsPDF插件](https://github.com/MrRio/jsPDF)、[doc](https://rawgit.com/MrRio/jsPDF/master/docs/index.html)
- jsPDF使用

```js
// 建议局部导入，此处仅做参考
import jspdf from '@/libs/jspdf.js'
Vue.use(jspdf)

this.toPDF('domId', 'pdf文件名')
this.toPDFZip(this, 'domId', 'pdf文件名')
```
- 自定义`jspdf.js`

```js
// 导出页面为PDF格式
import html2Canvas from 'html2canvas'
import jsPDF from 'jspdf'
import JSZip from 'jszip' // 导出pdf并压缩
import { saveAs } from 'file-saver'

export default {
  install (Vue, options) {
    Vue.prototype.getPDF = function (doc) {
      return new Promise((resolve, reject) => {
        html2Canvas(doc, {
          allowTaint: true
        }).then(function (canvas) {
          let contentWidth = canvas.width
          let contentHeight = canvas.height
          let pageHeight = contentWidth / 592.28 * 841.89
          let leftHeight = contentHeight
          let position = 0
          let imgWidth = 595.28
          let imgHeight = 592.28 / contentWidth * contentHeight
          let pageData = canvas.toDataURL('image/jpeg', 1.0)
          let PDF = new jsPDF('', 'pt', 'a4')
          if (leftHeight < pageHeight) {
            PDF.addImage(pageData, 'JPEG', 0, 0, imgWidth, imgHeight)
          } else {
            while (leftHeight > 0) {
              PDF.addImage(pageData, 'JPEG', 0, position, imgWidth, imgHeight)
              leftHeight -= pageHeight
              position -= 841.89
              if (leftHeight > 0) {
                PDF.addPage()
              }
            }
          }
          resolve({pdf: PDF})
        })
      })
    }

    Vue.prototype.toPDF = function (elementId, pdfTitle) {
      var title = pdfTitle
      this.getPDF(document.querySelector('#' + elementId)).then(data => {
        data.pdf.save(title + '.pdf')
      })
    }

    Vue.prototype.toPDFZip = async (that, elementId, title) => {
      var zip = new JSZip();
      const box = document.querySelector('#' + elementId)
      const items = box.querySelectorAll(".item-box")
      const func = (that, item, index) => new Promise((resolve, reject) => {
        that.getPDF(item).then(data => {
          const dataId = item.attributes["data-id"].nodeValue || index;
          try {
            zip.file(dataId + '.pdf', data.pdf.output('blob'));
            resolve()
          } catch {
            reject('Something went wrong!')
          }
        })
      })

      let arr = []
      items.forEach((item, index) => {
        arr.push(func(that, item, index))
      })
      await Promise.all(arr);

      zip.generateAsync({type:'blob'}).then(function(content) {
        saveAs(content, title + '.zip');
      });
    }
  }
}
```

### 生成ZIP文件

- 安装

```bash
npm install jszip -S
npm install file-saver -S
```
- 使用参考[生成PDF](#生成PDF)

### 网页保存为图片

- [html2canvas](https://github.com/niklasvh/html2canvas)、使用参考：https://segmentfault.com/a/1190000011478657
- html2canvas操作隐藏元素
    - `<div style="position: absolute; opacity: 0.0;">`
    - Failed to execute 'createPattern' on 'CanvasRenderingContext2D': The image argument is a canvas element with a width or height of 0. 
    - 参考 https://stackoverflow.com/questions/20605269/screenshot-of-hidden-div-using-html2canvas

## 格式规范化

### eslint格式化

- vscode等编辑安装eslint插件，相关配置参考[vscode.md#插件推荐](/_posts/extend/vscode.md#插件推荐)
- 直接安装
- 基于vue-cli安装，参考：https://eslint.vuejs.org/
    - `vue add eslint` 基于vue安装插件，选择Standard、Lint on save
    - 安装完成默认会自动执行`vue-cli-service lint`，即对所有文件进行格式修复(只会修复部分，剩下的仍然需要人工修复)
    - 安装后会在package.json中增加如下配置，安装对应的包到项目目录，并增加文件`.eslintrc.js`和`.editorconfig`

        ```json
        "scripts": {                                            
            "lint": "vue-cli-service lint",
        },
        "devDependencies": {
            "@vue/cli-plugin-eslint": "~4.5.0",
            "@vue/eslint-config-standard": "^5.1.2",
            "eslint": "^6.7.2",
            "eslint-plugin-import": "^2.20.2",
            "eslint-plugin-node": "^11.1.0",
            "eslint-plugin-promise": "^4.2.1",
            "eslint-plugin-standard": "^4.0.0",
            "eslint-plugin-vue": "^6.2.2"
        }
        ```
- 支持多种配置文件格式：.eslintrc.js、.eslintrc.yaml、.eslintrc.json、.eslintrc(弃用)、在package.json增加eslintConfig属性。且采用就近原则
- `.eslintrc.js` 放在vue项目根目录，详细参考：https://cn.eslint.org/ [^10]

```js
module.exports = {
  root: true,
  'extends': [
    'plugin:vue/essential',
    '@vue/standard'
  ],
  rules: {
    // allow async-await
    'generator-star-spacing': 'off',
    // allow debugger during development
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'vue/no-parsing-error': [2, {
      'x-invalid-end-tag': false
    }],
    'no-undef': 'off',
    'camelcase': 'off',
    // function函数名和()见增加空格
    "space-before-function-paren": ["error", {
        "anonymous": "always",
        "named": "always",
        "asyncArrow": "always"
    }],
    // 不强制使用 ===
    "eqeqeq": ["error", "smart"],
    // A && B换行时，符号在行头。https://eslint.org/docs/rules/operator-linebreak
    "operator-linebreak": ["error", "before"],
  },
  parserOptions: {
    parser: 'babel-eslint'
  }
}
```
- `.eslintignore` 放在vue项目根目录

```bash
# 不进行校验的的文件或文件夹
src/components
```
- 代码中不进行校验

```js
/* eslint-disable */
// ESLint 在校验的时候就会跳过后面的代码

/* eslint-disable no-new */
// ESLint 在校验的时候就会跳过 no-new 规则校验
```

### .editorconfig/.prettierrc/.jsbeautifyrc格式化

- **`.editorconfig`文件需要配合插件使用，如vscode的`Editorconfig`插件**
    - 该插件的作用是告诉开发工具自动去读取项目根目录下的 .editorconfig 配置文件，如果没有安装这个插件，光有一个配置文件是无法生效的
    - **此插件配置的格式优先于vscode配置的，如缩进**
- `.prettierrc` 文件需要配合插件使用，如vscode的`Prettier`插件。参考：https://prettier.io/
- `.jsbeautifyrc` 文件需要配合插件使用，如vscode的`Beautify`插件
- Eslint、.editorconfig等区别
    - Eslint 更偏向于对语法的提示，如定义了一个变量但是没有使用时应该给予提醒
    - .editorconfig 更偏向于简单代码风格，如缩进等
        - .prettierrc 更偏向于代码美化
    - 二者并不冲突，同时配合使用可以使代码风格更加优雅
- `.editorconfig` 放在vue项目根目录

```ini
# http://editorconfig.org
root = true

[*]
#缩进风格：空格
indent_style = space
#缩进大小2
indent_size = 2
#换行符lf
end_of_line = lf
#字符集utf-8
charset = utf-8
#是否删除行尾的空格
trim_trailing_whitespace = true
#是否在文件的最后插入一个空行
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
```
- .prettierrc 常用配置

```js
{
  /* 使用单引号包含字符串 */
  "singleQuote": true,
  /* 不添加行尾分号 */
  "semi": false,
  /* 在对象属性添加空格 */
  "bracketSpacing": true,
  /* 优化html闭合标签不换行的问题 */
  "htmlWhitespaceSensitivity": "ignore",
  /* 每行最大长度默认80(适配1366屏幕，1920可设置成140) */
  "printWidth": 140
}
```

## 其他

### docz项目文档生成

- https://github.com/doczjs/docz/




---

参考文章

[^1]: https://www.dazhuanlan.com/2019/12/31/5e0b08829f823/
[^2]: https://segmentfault.com/a/1190000013312233 (springBoot与axios表单提交)
[^3]: http://www.a4size.net/
