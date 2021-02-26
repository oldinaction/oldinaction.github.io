---
layout: "post"
title: "JS Tools"
date: "2020-10-9 15:18"
categories: web
tags: [js, tools]
---

## 库说明

- `babel` 是一个转码器，可以将es6，es7转为es5代码。Babel默认只转换新的JavaScript句法（syntax），而不转换新的API，比如Iterator、Generator、Set、Maps、Proxy、Reflect、Symbol、Promise等全局对象，以及一些定义在全局对象上的方法（比如Object.assign）都不会转码，所以为了使用完整的 ES6 的API，我们需要另外安装：babel-polyfill 或者 babel-runtime [^1]
    - `babel-polyfill` 会把全局对象统统覆盖一遍，不管你是否用得到。缺点：包会比较大100k左右。如果是移动端应用，要衡量一下。一般保存在dependencies中
    - `babel-runtime` 可以按照需求引入。缺点：覆盖不全。一般在写库的时候使用。建议不要直接使用babel-runtime，因为transform-runtime依赖babel-runtime，大部分情况下都可以用`transform-runtime`来达成目的
        - 在babel的配置文件 `.babelrc` 中配置了`"plugins": ["transform-runtime"]`后，就不用再手动单独引入某个 `core-js/*` 特性，如 core-js/features/promise，因为转换时会自动加上而且是根据需要只抽离代码里需要的部分
    - `babel-cli` 在命令行中使用babel命令对js文件进行转换。如`babel entry.js --out-file out.js`进行语法转换
- [core-js](https://github.com/zloirock/core-js) 是 babel-polyfill、babel-runtime 的核心包，他们都只是对 core-js 和 regenerator 进行的封装。core-js 通过各种奇技淫巧，用 ES3 实现了大部分的 ES2017 原生标准库，同时还要严格遵循规范。支持IE6+
    - core-js 组织结构非常清晰，高度的模块化。比如 `core-js/es6` 里包含了 es6 里所有的特性。而如果只想实现 promise 可以单独引入 `core-js/features/promise`

## 基础库

### lodash工具类

- [lodash](https://lodash.com/)

### cross-env启动时增加环境变量

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

## UI库

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

### Avue

- [官网](https://avuejs.com)
- [内置函数(全局API，在vue组件中可直接使用this调用)](https://avuejs.com/doc/api)
    - validatenull 校验是否为空(`null/''/0/[]/{}`)
    - findObject 从数组中查找对象，如`const parentIdProp = this.findObject(this.formColumn/this.crudOption.column, "parentId")`
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
- 表格组件


### 原理介绍

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
- 表格显示/隐藏后样式丢失问题
  - `auto-resize`或`sync-resize` 绑定指定的变量来触发重新计算表格。参考：https://xuliangzhan_admin.gitee.io/vxe-table/#/table/advanced/tabs
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
    autoClear 自动保存(关闭修改) => input类型的需要配合 immediate: true
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
        <Button
            v-if="!row.editingMode"
            @click="editRow(row)"
            size="small"
            icon="ios-create"
            shape="circle"
            style="margin-right:5px;"
        ></Button>
        <Button
            v-if="row.editingMode"
            @click="saveRow([row])"
            type="primary"
            size="small"
            icon="md-checkmark"
            shape="circle"
            style="margin-right:5px;"
        ></Button>
        <Button v-if="!row.editingMode" @click="deleteMulti(row)" size="small" icon="ios-trash" shape="circle"></Button>
        <Button v-if="row.editingMode" @click="cancelRow(row)" type="warning" size="small" icon="md-close" shape="circle"></Button>
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
</vxe-table>

<script>
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
- 打印，[参考](https://xuliangzhan_admin.gitee.io/vxe-table/#/table/module/print)

```js
import VXETable from 'vxe-table'
VXETable.print({
    sheetName: '打印自定义模板',
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

- web打印分页的问题，可使用`page-break-after`等css参数解决。参考：https://www.w3school.com.cn/cssref/index.asp#print
- 常见打印纸大小(宽mm*高mm，可在wps中查看)：A1 = {841,594}, A2 = {420,594}, A3 = {420,297}, **A4 = {210,297}**, A5 = {210,148}, A6 = {105,148}, A7 = {105,74}, A8 = {52,74}, B1 = {1e3,707}, B2 = {500,707}, B3 = {500,353}, B4 = {250,353}, B5 = {250,176}, B6 = {125,176}, B7 = {125,88}, B8 = {62,88}
- 基于[hiprint](http://hiprint.io/)插件
    - 特点：基于Jquery；可视化配置模板，自动分页打印；可免费使用
    - 缺点：源代码没开源，没有抽离 npm 包
    - 基于vue使用参考：https://blog.csdn.net/byc233518/article/details/107705278
- 基于[print-js](https://printjs.crabbly.com/)
- 使用vxe-table等插件自带打印功能
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




---

参考文章

[^1]: https://www.dazhuanlan.com/2019/12/31/5e0b08829f823/
[^2]: https://segmentfault.com/a/1190000013312233 (springBoot与axios表单提交)
