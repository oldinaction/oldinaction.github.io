---
layout: "post"
title: "JS Tools"
date: "2020-10-9 15:18"
categories: web
tags: [js, tools]
---

## Tag一下

- [Alibaba Fusion Design](https://zhuanlan.zhihu.com/p/54751219)
    - 基于 React技术栈实现设计师与工程师的协作平台

## 基础库

### sass/less

- sass相关变种说明: https://www.cnblogs.com/yyh1/p/15954139.html
    - 目前sass官方主推的是 dart-sass
    - sass 是由 ts调用 dart-sass实现的工具类，来编译 sass（以前是由单纯的 ts实现的）
        - 只支持 `::v-deep`
    - dart-sass 是由 dart 实现的，通过 dart vm 运行 dart 是编译 sass（在 npm 可以看到该包已不被开放下载了）
    - node-sass 是由 node 调用 底层 c++ 实现的 libsass 来编译 sass
        - 支持`/deep/`和`::v-deep`

### lodash工具类

- [lodash](https://lodash.com/)、[lodash中文网](https://www.lodashjs.com/)
- Math 数学计算，类似[mathjs](#mathjs数学计算)
    - `add`、`subtract`、`multiply`、`divide` 两个数的加减乘除
        - `_.add(0.1, 0.2)` // 0.30000000000000004
- merge 可进行深度覆盖

```js
const a = {a: 1, b: {b1: 2}, c: [{c1: 3}]};
_.merge(a, {b: {b1: 22, b2: 23}, c: [{c1: 33, c2: 34}, {c1: 35}]});
// {a: 1, b: {b1: 22, b2: 23}, c: [{c1: 33, c2: 34}, {c1: 35}]}
console.log(a);
```
- groupBy

```js
// 多字段分组案例
// 案例参考：https://segmentfault.com/q/1010000040036335
import _ from "lodash"

const arr = [
    { status: 1, opp: 2, ad: "11" },
    { status: 1, opp: 2, ad: "22" },
    { status: 1, opp: 3, ad: "33" },
    { status: 2, opp: 4, ad: "44" },
    { status: 3, opp: 5, ad: "55" }
]

const r = _(arr) // 转成lodash表达式
    .groupBy("status") // lodash表达式序列化后 {"1":[{"status":1,"opp":2,"ad":"11"},{"status":1,"opp":2,"ad":"22"},{"status":1,"opp":3,"ad":"33"}],"2":[{"status":2,"opp":4,"ad":"44"}],"3":[{"status":3,"opp":5,"ad":"55"}]}
    .values() // lodash表达式序列化后 [[{"status":1,"opp":2,"ad":"11"},{"status":1,"opp":2,"ad":"22"},{"status":1,"opp":3,"ad":"33"}],[{"status":2,"opp":4,"ad":"44"}],[{"status":3,"opp":5,"ad":"55"}]]
    .map(it => _(it)
        .groupBy("opp")
        .values()
        .map(list => ({
            status: list[0].status,
            opp: list[0].opp,
            add: list.map(v => v.ad) // 如业务逻辑为求和，可修改此处
        }))
        .value() // 取lodash表达式值
    )
    .value()
/* 结果如下
[
    [
        {"status":1,"opp":2,"add":["11","22"]},
        {"status":1,"opp":3,"add":["33"]}
    ],
    [{"status":2,"opp":4,"add":["44"]}],
    [{"status":3,"opp":5,"add":["55"]}]
]
*/
console.log(JSON.stringify(r))
```

### cross-env启动时增加环境变量

```js
// 安装
npm install --save-dev cross-env

// 使用
"scripts": {
    "build": "cross-env NODE_ENV=production MY_KEY=value webpack --config build/webpack.config.js"
}
```

### dayjs时间操作

- [dayjs](https://github.com/iamkun/dayjs)，相对 moment 体积更小、[官方文档](https://dayjs.gitee.io/docs/zh-CN/installation/installation)
- 安装`npm i dayjs -S`
- 举例

```js
import dayjs from 'dayjs'

dayjs().format('YYYY-MM-DD HH:mm:ss'); // 2020-01-02
dayjs('2020-01-01').add(1, 'day').format('YYYY-MM-DD'); // 2020-01-02
```

### 数学计算

- js精度问题: https://www.cnblogs.com/xjnotxj/p/12639408.html
    - `0.1 + 0.2 => 0.30000000000000004`
    - **使用 toFixed() 函数(推荐)**: `parseFloat((0.1 + 0.2).toFixed(1)) => 0.3`
        - 存在问题：toFixed必须设置精度(默认是整数)
    - 使用第三方库解决
        - [decimal.js](http://mikemcl.github.io/decimal.js/) 文件大小132K
        - Math.js 文件大小1.74M
        - big.js
        - bignumber.js
    - 银行家不使用四舍五入(存在1.05这个数会让银行亏钱)，而是使用`四舍六入五取偶`。toFixed不能完全满足此近似算法，可使用第三方包`bankers-rounding`
        - 规则：四舍六入五考虑，五后非空就进一，五后为空看奇偶，五前为偶应舍去，五前为奇要进一

        ```js
        9.8249=9.82
        9.82671=9.83
        9.8350=9.84
        9.8351 =9.84
        9.8250=9.82
        9.82501=9.83
        ```
- decimal.js

```js
Decimal.add(0.1, 0.2).toNumber() // 0.3
```
- mathjs

```js
npm install mathjs -S

import * as math from 'mathjs'

// 错误结果
0.1 + 0.2 // 0.30000000000000004
_.add(0.1, 0.2) // 0.30000000000000004 loadsh
math.add(0.1, 0.2) // 0.30000000000000004

// 0.3 math.number转换BigNumber类型为number类型
// math.add(math.bignumber(0.1), math.bignumber(0.2)).toNumber()
math.number(math.add(math.bignumber(0.1), math.bignumber(0.2)))
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

- 表单同步验证

```js
let pass = true
await this.$refs.form.validate((valid) => {
    pass = valid
})
console.log(pass)
```
- 远程搜索数据回显

```html
<span v-if="!shipBill.payerCodShow">{{ shipBill.payerNam }} <Icon type="ios-create" @click="() => shipBill.payerCodShow = true"/></span>
<!-- 
    编辑时shipBill和payerCodList的值是分开异步获取的当获取到shipBill后
    手动调用一次payerCodRemoteMethod大部分时候可进行回显，但是有时候会出现下拉不出来等问题
    因此建议增加上面的span标签，默认以文本展示，在后面加一个编辑图标，点击后展示出下面的el-select即可
-->
<el-select v-if="shipBill.payerCodShow"
    v-model="shipBill.payerCod"
    filterable
    remote
    placeholder="请输入关键词"
    size="mini"
    style="display:block;"
    :remote-method="payerCodRemoteMethod"
>
    <el-option v-for="item in payerCodList" :key="item.value" :label="item.label" :value="item.value">
        {{ item.value }}：{{ item.label }}
    </el-option>
</el-select>
```
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
- z-index
    - 如果没有初始化，也没在use时给定z-index，则默认2000

### iview

- 参考[iview.md](/_posts/web/iview.md)

### Avue

- [官网](https://avuejs.com)
- [内置函数(全局API，在vue组件中可直接使用this调用)](https://avuejs.com/doc/api)
    - `validatenull` 校验是否为空(`null/''/0/[]/{}`)
    - `findObject` 从数组中查找对象
        - 如 `const saleNoObj = this.findObject(this.crudOptionData.column | this.formColumn, 'saleNo'); saleNoObj.disabled = true;` 找到对象属性配置后，并修改(动态修改属性需要有默认值，即此时必须提前设置disabled=null属性，否则vue无法动态监测新增的属性进行双向绑定)
    - `vaildData` 验证表达式/属性
        - 如`this.vaildData(this.permission.party_permission_add, false)` 默认根据第一个参数值进行判断，否则取第二个参数为默认值
    - `$Print`
    - `$Clipboard`
    - `$Log` 控制台彩色日志
    - `$NProgress`
    - `$Screenshot`
    - `deepClone` 对象/数组深拷贝
    - `dataURLtoFile`
    - `isJson`
    - `setPx` 设置css像素
    - `sortArrys`
    - `findArray`
    - `downFile`
    - `loadScript` 加载js/css文件
    - `watermark`
    - `asyncValidator`
- 内置指令
    - `v-dialogdrag` 作用于dialog，可进行拖拽
- 获取ref
    - 在crud组件中`const avatarRef = this.$refs.crud.getPropRef('avatar')`可获取到表单的avatar图片上传组件元素ref，从而使用`avatarRef.$refs.temp.handleSuccess`进行调用(temp是由于中间动态判断了表单元素)
    - 获取crud弹框表单中的element form引用：`this.$refs.crud.$refs.dialogForm.$refs.tableForm.$refs.form`

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
    addBtn: true, // 弹框新增一行数据。**如果使用行内编辑，则必须设置成false**
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
            width: 200, // 列宽度，如果需要出现横向滚动条则必须定义宽度的列宽度之和大于父box宽度
            
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
            change: ({ column, index, row, value }) => {}, // 表单编辑时，值发生变化事件
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

#### 常见问题

- 可编辑表格点击新增后还是弹框显示
    - 可编辑表格需要设置`cellBtn=true`，需要编辑的字段需要设置`cell=true`，并且需要设置`addBtn=false`(这是普通表格的新增)和`addRowBtn=true`(可编辑表格的新增)
- change事件进入两遍(Bug v2.8.26)，解决如下

```js
column: [
  {
    label: '商品',
    prop: 'goodsId',
    type: 'select',
    change: ({ value, row }) => {
        // avue change 时间会进入两次
        if (value && value !== row.$goodsId) {
            row.$goodsId = value
            // ...
        }
    }
  }
]
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
    // "row"(当前选中或取消选中行), "checked"(操作完当前行后的选中状态), "items"(可视化区域所有行数据，表格的所有数据只能通过getData获取), "data"(可视化区域所有行数据), "records"(目前选中的所有行数据), "selection"(目前选中的所有行数据)
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

### Select下拉

- 常用功能
    - 自定义前台搜索
    - 远程搜索
    - 自定义选项模板(value和label字段可自定义)
    - 选中返回item对象
    - 可多选
    - 可清除
    - 可transfer到body
- [Vue-multiselect](https://vue-multiselect.js.org/)
    - 缺点
        - 单选不能清除
- [multiple-select](https://github.com/wenzhixin/multiple-select)
    - 支持选项横向排列
    - 缺点
        - 网站速度慢，没细测试
- [Vue Treeselect](https://github.com/riophae/vue-treeselect)
    - 支持大数据量
    - 缺点
        - value和label字段无法自定义，必须后台返回字段名为id来代表value
- [vue-tree](https://github.com/halower/vue-tree)
- [Vue multi select](https://github.com/IneoO/vue-multi-select)
    - 支持选项tab分页功能

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
    - 修改默认打印边距 **`@page {margin: 24px 18px 0 18px;}`**，或者在chrome打印预览时通过自带界面修改
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
    - 特点：基于Jquery；可视化配置模板(数据基于字段名自动填充)，自动分页打印；可免费使用
    - 缺点：源代码没开源，没有抽离 npm 包。[github打包代码](https://github.com/hinnncom/hiprint)
    - 基于vue使用参考：https://blog.csdn.net/byc233518/article/details/107705278
    - 打印后关闭页面(监听事件)

    ```js
    // 方法一：只有在引入socket.io.js才生效
    hiprintTemplate.on('printSuccess', () => {})
    hiprintTemplate.on('printError', () => {})

    // 方法二 (vue案例)
    this.printTemplate(this.printData)
    this.addPrintEvent(() => {
        window.close()
    })
    // 定义
    addPrintEvent(afterPrintEvent, beforePrintEvent) {
      // setTimeout 等待hiwprint_iframe加入到body中
      setTimeout(() => {
        // hiprintTemplate.print 最终是基于 jquery.hiwprint.js 虚拟出一个 iframe 进行打印的
        let contentWindow = window.frames['hiwprint_iframe'].contentWindow
        let beforePrint = () => {
          beforePrintEvent && beforePrintEvent()
        }
        let afterPrint = () => {
          afterPrintEvent && afterPrintEvent()
        }
        if (contentWindow.matchMedia) {
          var mediaQueryList = contentWindow.matchMedia('print')
          mediaQueryList.addListener(function (mql) {
            if (mql.matches) {
              beforePrint()
            } else {
              afterPrint()
            }
          })
        }
        contentWindow.onbeforeprint = beforePrint
        contentWindow.onafterprint = afterPrint
      }, 0)
    }
    ```
- 基于[print-js](https://printjs.crabbly.com/)
- 使用[vxe-table](#vxe-table)等插件自带打印功能
- 自定义js参考

```js
/*
使用
import Print form 'util/print.js'
Vue.use(Print)

this.$print(this.$refs.table, {
    title: '自定义文件名(可用于导出PDF文件), 默认为当前网页标题'
})
*/
/* eslint-disable */
const Print = function(dom, options) {
  if (!(this instanceof Print)) return new Print(dom, options);

  this.options = this.extend(
    {
      noPrint: ".no-print"
    },
    options
  );

  if (typeof dom === "string") {
    this.dom = document.querySelector(dom);
  } else {
    this.isDOM(dom);
    this.dom = this.isDOM(dom) ? dom : dom.$el;
  }

  this.init();
};
Print.prototype = {
  init: function() {
    var content = this.getStyle() + this.getHtml();
    this.writeIframe(content);
  },
  extend: function(obj, obj2) {
    for (var k in obj2) {
      obj[k] = obj2[k];
    }
    return obj;
  },

  getStyle: function() {
    var str = "",
      styles = document.querySelectorAll("style,link");
    for (var i = 0; i < styles.length; i++) {
      str += styles[i].outerHTML;
    }
    str +=
      "<style>" +
      (this.options.noPrint ? this.options.noPrint : ".no-print") +
      "{display:none;}</style>";
    str += "<style>html,body,div{height:auto!important;}</style>";

    return str;
  },

  getHtml: function() {
    var inputs = document.querySelectorAll("input");
    var textareas = document.querySelectorAll("textarea");
    var selects = document.querySelectorAll("select");

    for (var k = 0; k < inputs.length; k++) {
      if (inputs[k].type == "checkbox" || inputs[k].type == "radio") {
        if (inputs[k].checked == true) {
          inputs[k].setAttribute("checked", "checked");
        } else {
          inputs[k].removeAttribute("checked");
        }
      } else if (inputs[k].type == "text") {
        inputs[k].setAttribute("value", inputs[k].value);
      } else {
        inputs[k].setAttribute("value", inputs[k].value);
      }
    }

    for (var k2 = 0; k2 < textareas.length; k2++) {
      if (textareas[k2].type == "textarea") {
        textareas[k2].innerHTML = textareas[k2].value;
      }
    }

    for (var k3 = 0; k3 < selects.length; k3++) {
      if (selects[k3].type == "select-one") {
        var child = selects[k3].children;
        for (var i in child) {
          if (child[i].tagName == "OPTION") {
            if (child[i].selected == true) {
              child[i].setAttribute("selected", "selected");
            } else {
              child[i].removeAttribute("selected");
            }
          }
        }
      }
    }
    // 包裹要打印的元素
    // fix: https://github.com/xyl66/vuePlugs_printjs/issues/36
    let outerHTML = this.wrapperRefDom(this.dom).outerHTML;
    return outerHTML;
  },
  // 向父级元素循环，包裹当前需要打印的元素
  // 防止根级别开头的 css 选择器不生效
  wrapperRefDom: function(refDom) {
    let prevDom = null;
    let currDom = refDom;
    // 判断当前元素是否在 body 中，不在文档中则直接返回该节点
    if (!this.isInBody(currDom)) return currDom;

    while (currDom) {
      if (prevDom) {
        let element = currDom.cloneNode(false);
        element.appendChild(prevDom);
        prevDom = element;
      } else {
        prevDom = currDom.cloneNode(true);
      }

      currDom = currDom.parentElement;
    }

    return prevDom;
  },

  writeIframe: function(content) {
    var w,
      doc,
      iframe = document.createElement("iframe"),
      f = document.body.appendChild(iframe);
    iframe.id = "myIframe";
    //iframe.style = "position:absolute;width:0;height:0;top:-10px;left:-10px;";
    iframe.setAttribute(
      "style",
      "position:absolute;width:0;height:0;top:-10px;left:-10px;"
    );
    w = f.contentWindow || f.contentDocument;
    doc = f.contentDocument || f.contentWindow.document;
    doc.open();
    doc.write(content);
    doc.close();
    var _this = this;
    iframe.onload = function() {
      _this.toPrint(w);
      setTimeout(function() {
        document.body.removeChild(iframe);
      }, 100);
    };
  },

  toPrint: function(frameWindow) {
    try {
      let that = this
      setTimeout(function() {
        frameWindow.focus();
        let title  = window.document.title
        if (that.options.title) {
          window.document.title = that.options.title
        }
        try {
          // execCommand("print") 类似 window.print()
          if (!frameWindow.document.execCommand("print", false, null)) {
            frameWindow.print();
          }
        } catch (e) {
          frameWindow.print();
        }
        window.document.title = title
        frameWindow.close();
      }, 10);
    } catch (err) {
      console.log("err", err);
    }
  },
  // 检查一个元素是否是 body 元素的后代元素且非 body 元素本身
  isInBody: function(node) {
    return node === document.body ? false : document.body.contains(node);
  },
  isDOM:
    typeof HTMLElement === "object"
      ? function(obj) {
          return obj instanceof HTMLElement;
        }
      : function(obj) {
          return (
            obj &&
            typeof obj === "object" &&
            obj.nodeType === 1 &&
            typeof obj.nodeName === "string"
          );
        }
};
const MyPlugin = {};
MyPlugin.install = function(Vue, options) {
  Vue.prototype.$print = Print;
};
export default MyPlugin;

```
- 监听打印前后事件

```js
var beforePrint = function() {
    console.log('Functionality to run before printing.');
};
var afterPrint = function() {
    console.log('Functionality to run after printing');
};
if (window.matchMedia) {
    var mediaQueryList = window.matchMedia('print');
    mediaQueryList.addListener(function(mql) {
        if (mql.matches) {
            beforePrint();
        } else {
            afterPrint();
        }
    });
}
window.onbeforeprint = beforePrint;
window.onafterprint = afterPrint;
```
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

## 其他

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

### docz项目文档生成

- https://github.com/doczjs/docz/

### codemirror代码编辑

- [codemirror](https://codemirror.net/)
- vue使用，安装`npm install vue-codemirror --save`

```html
<codemirror
ref="cm"
v-model="dataForm.code"
:options="cmOptions"
></codemirror>

<script>
// 单组件引用
import { codemirror } from 'vue-codemirror'
import 'codemirror/lib/codemirror.css'
// require('codemirror/mode/javascript/javascript') // mode: 'text/javascript'
// require('codemirror/mode/sql/sql') // mode: 'sql'

export default {
    data () {
        return {
            cmOptions: {
                // text方式进行代码高亮，如果是其他语言可能需要引入对应的样式
                mode: 'text',
                // 显示行号
                lineNumbers: true,
                // 一行超长时自动换行
                lineWrapping: true,
                tabSize: 2
            }
        }
    }
}
</script>
```

## 工具函数

### 防抖和节流

- 基于lodash
    - 其提供的throttle和debounce仍会出现重复点击按钮，还是会多次执行，只不过多次执行有几秒的间隔
    - **下文自定义的throttle方法无此问题，在2s内重复点击只执行一次**

```js
import _ from 'lodash'

// vue中使用
methods: {
    // 延迟2s，并立即执行(leading=true)
    doPost: _.throttle(function(data) {
        // doPost定义成属性，并且往throttle中传入普通函数(而非箭头函数)，此时即可拿到this
        this.$ajax...
    }, 2000, { leading: true }),
    doGet: _.debounce(function(data) {
        this.$ajax...
    }, 2000, { leading: true })
}
```
- 手动实现参考：https://www.jb51.net/article/212746.htm

```js
// 防抖
export const debounce = function (f, t = 2000, im = false) {
  let timer
  let flag = true
  return function () {
    var args = arguments
    var that = this
    // 需要立即执行的情况
    if (im) {
      if (flag) {
        f.apply(that, args)
        flag = false
      } else {
        clearTimeout(timer)
        timer = setTimeout(() => {
          f.apply(that, args)
          flag = true
        }, t)
      }
    } else {
      // 非立即执行的情况
      clearTimeout(timer)
      timer = setTimeout(() => {
        f.apply(that, args)
      }, t)
    }
  }
}

// 节流
export const throttle = function (f, t = 2000, im = false) {
  let flag = true
  return function () {
    var args = arguments
    var that = this
    if (flag) {
      flag = false
      im && f.apply(that, args)
      setTimeout(() => {
        !im && f.apply(that, args)
        flag = true
      }, t)
    }
  }
}
```


---

参考文章

[^2]: https://segmentfault.com/a/1190000013312233 (springBoot与axios表单提交)
[^3]: http://www.a4size.net/
