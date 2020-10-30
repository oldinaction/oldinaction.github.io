---
layout: "post"
title: "iview"
date: "2017-07-23 16:11"
categories: web
tags: [vue, UI]
---

## 简介

- 默认基于`v2.x`版本

## 使用

### 注意点

- `Tree`组件在动态网节点中加入数据后（往一个数组中插入元素），点击新节点时会报错。此时需要重新赋值此数组属性：`this.treeList = JSON.parse(JSON.stringify(this.treeList))` (可能是 treeList 里面的元素改变并不会触发 vue 的渲染)
- 使用`:prop`传递数据格式为**数字、布尔值或函数**时，必须带`:`(兼容 String 除外，具体看组件文档) (1)
- prop 参数如果直接初始化则之后不可修改，只有传入变量才可修改 (2)

    ```html
    <!-- (1) -->
    <Page :current="1" :total="100"></Page>

    <Select v-model="sex" placeholder="请选择">
        <Option :value="1">男</Option>
        <Option :value="2">女</Option>
    </Select>

    <Radio-group v-model="status">
        <Radio :label="1">是</Radio>
        <Radio :label="0">否</Radio>
    </Radio-group>

    <!-- (2) -->
    <!-- 此时disabled相当于disabled=true；那么无法再修改此下拉的禁用状态，通过refs去修改也会报错；只能绑定相应的属性，如：`:disabled="subResultDisabled"` -->
    <Select v-model="form.subResult" @on-change="subResultChange" disabled placeholder="请选择">
        <Option v-for="(item, index) in subResult" :value="item.id" :key="index">{{ item.nodeName }}</Option>
    </Select>
    ```
- 可通过ref使用组件内部属性
    - 获取组件名称`this.$refs.myRef.prefixCls`，如：ivu-select、ivu-date-picker、ivu-cascader
    - 如获取部分组件的展示值
        - `Select`: this.$refs.myRef.publicValue(单选时。如果要在模板中展示则不能这样调用，会出现死循环，参考下文[可编辑表单](#可编辑表单))
        - `DatePicker`: this.$refs.myRef.publicStringValue
        - `Cascader`: this.$refs.myRef.displayRender(参考下文Cascader说明)

### Select

- Select 远程搜索。问题：检索数据项的多个属性时远程搜索无效 [^1]

```html
<i-select
  v-model="user.id"
  filterable
  @on-query-change="queryChange"
  @on-change="onChange"
>
  <!-- i-option组件 :value 中数据必须包含输入的搜索内容，不然会被过滤掉 -->
  <i-option
    v-for="(option, index) in options"
    :value="option.value + ',' + queryText"
    :key="option.value"
    >{{ option.label }}</i-option
  >
</i-select>

<script>
  export default {
      data() {
        user: {},
        options: [],
        queryText: '',
        userList: [] // 赋值省略
      },
      methods: {
        queryChange(query) {
        this.queryText = query;
        if(query !== '') {
            // 继续用户名和名称过滤
            this.options = this.userList.filter(item => (item.name.indexOf(query) > -1 || item.username.indexOf(query) > -1))
            this.options = this.options.map(item => {
                return {
                    value: item.id,
                    label: item.name
                };
            });
        } else {
            this.options = [];
        }
        },
        onChange(value) {

        }
      }
</script>
```
- 手动触发click事件展示下拉选项

```js
this.$refs.mySelect.visible = true
```

### Checkbox

```html
<!-- label只在单独使用时有效；单独使用只能用value或v-model（且严格判断为true才勾选，为1不勾选） -->
<Checkbox value="xj">显示值</Checkbox>

<!-- ***** 此处v-model必须绑定顶级变量，如果绑定formData.typeCodeList则容易出现值不改变的问题 ***** -->
<!-- Checkbox标签中有值则显示此值，无值则显示label值；传入到后台的是永远是label值 -->
<CheckboxGroup v-model="typeCodeList">
    <Checkbox v-for="item in searchForm.typeCodeList" :label="item.value" :key="item.value" border>{{ item.label }}</Checkbox>
</CheckboxGroup>
```

### Table

- 去掉自带扩展行图标，换成按钮控制

![iview-expand.png](/data/images/web/iview-expand.png)

```html
<template>
  <table :columns="columns1" :data="dataList" type="expand"></table>
</template>

<script>
  export default {
    data() {
      return {
        columns1: [
          {
            type: "expand",
            width: 1, // 设置成0不行
            render: (h, params) => {
              // ExpandRow 为自定义组件
              return h(ExpandRow, {
                props: { row: params.row }
              });
            }
          },
          {
            title: "操作",
            key: "action",
            render: (h, params) => {
              return h("div", [
                h(
                  "a",
                  {
                    style: {
                      marginRight: "15px",
                      display: params.row.status == "2" ? "block" : "none"
                    },
                    on: {
                      click: () => {
                        // 点击按钮展开扩展行
                        this.expand(params.row, params.index);
                      }
                    }
                  },
                  "进度跟踪"
                )
              ]);
            }
          }
        ],
        dataList: []
      };
    },
    methods: {
      expand(item, index) {
        // 关闭其他展开行
        this.dataList.splice();
        for (let i = 0; i < this.dataList.length; i++) {
          this.dataList[i]._expanded = false;
        }

        if (item._expanded) {
          // 点击展开
          this.dataList.splice();
          this.dataList[index]._expanded = false;
        } else {
          this.dataList.splice();
          this.dataList[index]._expanded = true;
        }
      }
    }
  };
</script>

<style>
  td .ivu-table-cell-with-expand {
    .ivu-icon-ios-arrow-forward:before {
      content: "";
    }
    .ivu-table-cell-expand {
      position: absolute;
    }
  }
</style>
```

### Page 假分页

```html
<template>
    <Table :columns="columns" :data="pageList"></Table>
    <Page :total="pageTotal" :page-size="pageSize" @on-change="handlePaging" @on-page-size-change="handlePageSizeChange" size="small" show-total show-elevator show-sizer />
</template>

<script>
export default {
  data () {
    return {
      dataList: [],
      pageList: [],
      pageTotal: 0,
      pageSize: 20,
      columns: []
    }
  },
  mounted () {
    this.dataList = [{}, ...]
    this.handlePaging(1)
  },
  methods: {
    handlePaging (currentPage) {
      let list = []
      for (var i = this.pageSize * (currentPage - 1) + 1;
        i <= ((this.pageTotal > this.pageSize * currentPage) ? (this.pageSize * currentPage) : (this.pageTotal));
        i++) {
        list.push(this.dataList[i - 1])
      }
      this.pageList = list
    },
    handlePageSizeChange (pageSize) {
      this.pageSize = pageSize
      this.handlePaging(1)
    },
  }
}
</script>
```

### DatePicker

```html
<!-- (推荐) 返回的是string类型数据(配合on-change使用)。监控前台请求，此字段字符串如 2000-03-17" -->
<DatePicker type="date" :value="workLevelItem.startTm" @on-change="v => workLevelItem.startTm = v"></DatePicker>
<!-- 返回数组 -->
<DatePicker type="daterange" :value="workLevelItem.startTm" @on-change="v => workLevelItem.startTm = v"></DatePicker>
<!-- 返回的是Date类型数据。监控前台请求，此字段字符串如 2000-03-16T16:00:00.000Z" -->
<DatePicker type="date" v-model="workLevelItem.startTm"></DatePicker>
```

### Cascader数据结构(含后台)

```html
<!-- 获取 Cascader 显示值，伪代码如下 -->
<div>{{ $refs.module_editable_actual != null ? $refs.module_editable_actual.displayRender : '' }}</div>
<Cascader ref="module_editable_actual" :data="moduleList" v-model="moduleIdList" @on-change="v => moduleId = v.splice(-1)"></Cascader>

<script>
import { findLeafParent } from '@/libs/util'

export default {
    methods: {
        init() {
            // 如果重新赋值了Cascader的data 则其v-model的修改必须在$nextTick中，否则数据更新后显示不会变更。参考 https://github.com/iview/iview/issues/1637
            this.moduleList = xxx
            this.$nextTick(() => {
                this.moduleIdList = findLeafParent(this.moduleList, 'id', this.moduleId)
            })
        }
    }
}

// @/libs/util 代码
/**
 * 获取叶子节点的所有节点
 */
export function findLeafParent(array, leafKey, leafValue) {
  let retArr = []
  let going = true

  let find = (array, leafValue) => {
    array.forEach(item => {
      if (!going) return
      retArr.push(item[leafKey])
      if (item[leafKey] === leafValue) {
        going = false
      } else if (item['children']) {
        find(item['children'], leafValue)
      } else {
        retArr.pop()
      }
    })
    if (going) retArr.pop()
  }

  find(array, leafValue)

  return retArr
}
</script>
```
- java代码

```java
// select *, id value, name label from d_project_module where project_id=#{projectId} and valid_status=1 // 将value和label单独取出
List<Map<String, Object>> list = projectModuleMapper.selectCascader(map);
List<Map<String, Object>> recursion = MyUtil.recursion(list, 0, null);

// MyUtil.recursion
public static List<Map<String, Object>> recursion(List<Map<String, Object>> listData, Integer i, Object id) {
    List<Map<String, Object>> treeList = new ArrayList<Map<String, Object>>();
    Iterator it = listData.iterator();
    i++;
    while (it.hasNext()) {
        Map<String, Object> map = (Map<String, Object>) it.next();
        if(CommUtil.isEmpty(id)) {
            if(CommUtil.isEmpty(map.get("pid")) || "0".equals(map.get("pid").toString())) {
                map.put("i", i);
                treeList.add(map);
                // 使用Iterator，以便在迭代时把listData中已经添加到treeList的数据删除，迭代次数
                it.remove();
            }
        } else {
            if(String.valueOf(id).equals(String.valueOf(map.get("pid")))) {
                map.put("i", i);
                treeList.add(map);
                it.remove();
            }
        }
    }

    for (Map<String, Object> map : treeList) {
        map.put("children", recursion(map.get("id"), listData, i));
    }
    return treeList;
}
```

### Drawer

```html
<!-- style="z-index:1500; position:fixed" 防止Drawer在多层弹框/Drawer显示时被遮盖 -->
<Drawer :closable="false" v-model="fileDrawer" style="z-index:1500; position:fixed">
    123
</Drawer>
```

### Progress

- percent必须不能使用子对象属性，否则无法代码增减进度

### Modal

- 点击确定(on-ok事件)按钮不关闭弹框

```js
this.$refs.modal.visible = true
this.showModal = true
return false
```
- 全屏嵌套其他页面

```vue
<template>
  <Modal v-model="show" fullscreen footer-hide>
    <span slot="header"></span>
    <Button type="text" @click="goBack" class="go-back">
      <Icon type="md-arrow-round-back" />
    </Button>
    <Spin fix v-show="spinShow"></Spin>
    <iframe :src="extUrl" />
  </Modal>
</template>

<script>
export default {
  name: 'tab-dev-oa',
  props: ['pId', 'id', 'access', 'mainUser'],
  data () {
    return {
      show: true,
      spinShow: false,
      extUrl: null
    }
  },
  created () {
    this.init()
  },
  mounted () {
    const that = this
    document.getElementById('iframe').onload = function () {
      that.spinShow = false
    }
  },
  methods: {
    init () {
      this.extUrl = 'http://www.baidu.com'
    },
    goBack () {
      this.$emit('on-go-back')
    }
  }
}
</script>

<style lang="less" scoped>
/deep/ .ivu-modal-content {
  .ivu-modal-header {
    padding: 0;
  }
  .ivu-modal-body {
    top: 0;
    padding: 0px;
  }
  >a.ivu-modal-close {
    display: none;
  }
}

.go-back {
  top: -5px;
  left: -5px;
  position: absolute;
  font-size: 20px;
  /deep/ &.ivu-btn-text:active, &.ivu-btn-text.active, &.ivu-btn-text:hover {
    background-color: transparent;
  }
  /deep/ &.ivu-btn-text:focus {
    box-shadow: none;
  }
}

iframe {
  width: 100%;
  border: 0px;
}
@media (max-width: 1920px) {
  iframe {
    height: calc(100% - 3px) !important;
  }
}
@media (max-width: 1366px) {
  iframe {
    height: calc(100% - 1px) !important;
  }
}
</style>
```

### Form

- 表单验证
  
    ```html
    <!-- 注意:model必须赋值，且所有的prop都定义过，如：userDataForm: {username: ''}。如果不定义自定则使用 required: true 规则时会一直报错 -->
    <Form :model="userDataForm" :rules="userDataFormRule" ref="userDataForm">
        <FormItem label="Login Name" prop="username">
            <Input v-model="userDataForm.username" placeholder="Login Name"></Input>
        </FormItem>
    </Form>

    <!-- InputNumber验证时必须定义type，佛足额required一直报错。amount: [{ required: true, type:'number', message: "金额必填", trigger: "blur" }]-->
    <FormItem label="金额" prop="amount">
        <InputNumber v-model="editForm.amount"></InputNumber>
    </FormItem>
    ```
- 表单排版

```html
<!-- 一行排列多个元素使用Row-Col；如果使用Form的inline属性，则需要自定义宽度来美化 -->
<Form :model="searchModel" label-position="right" :label-width="100">
    <Row>
    <Col span="3">
        <FormItem label="项目名称">
            <Select v-model="searchModel.projectId">
            <Option v-for="item in projectList" :value="item.id" :key="item.id">{{ item.projectName }}</Option>
            </Select>
        </FormItem>
    </Col>
    <Col span="3">
        <FormItem label="创建时间">
            <DatePicker type="daterange" :v-for="searchModel.inputTm" placement="bottom-end" style="width: 200px"></DatePicker>
        </FormItem>
    </Col>
    <Col span="2">
        <FormItem>
            <Button type="primary">查询</Button>
        </FormItem>
    </Col>
    </Row>

    <!-- FormItem可嵌套使用，但不能嵌套验证 -->
    <FormItem label="时间">
        <Row type="flex" justify="start">
            <Col span="12" style="width: 210px;">
                <FormItem prop="etdTime">
                    <DatePicker :value="editForm.etdTime" @on-change="v => editForm.etdTime = v" style="width: 210px;"></DatePicker>
                </FormItem>
            </Col>
            <Col span="1" style="text-align: center">-</Col>
            <Col span="11">
                <FormItem prop="etdTimeEnd">
                    <DatePicker :value="editForm.etdTimeEnd" @on-change="v => editForm.etdTimeEnd = v" style="width: 160px;"></DatePicker>
                </FormItem>
            </Col>
        </Row>
    </FormItem>
</Form>
```

## 样式

### 主题

- 配置

```css
/* src/styles/index.less(最后在main.js中引入) */
@import '~view-design/src/styles/index.less';
@import 'theme/index.less';
@import 'common.less';

/* src/styles/theme/index.less 覆盖iview默认变量 */
@primary-color: #8c0776;

/* src/styles/common.less */
.primary-color {
    color: @primary-color; /* 由于此文件最终由main.js导入到全局，因此此处可以使用theme/index.less中的变量 */
}

/* 其他less文件中应用全局变量，请参考 [vue样式-全局样式](/_posts/web/vue.md#样式) */
```
- [内置变量](https://github.com/view-design/ViewUI/blob/master/src/styles/custom.less)

```less
// 常用
@primary-color: #32b642; // 全局主色
@warning-color: #faad14; // 警告色
@error-color: #f5222d; // 错误色
@link-color: #32b642; // 链接色
@font-size-base: 14px; // 主字号
@heading-color: rgba(0, 0, 0, 0.85); // 标题色
@text-color: rgba(0, 0, 0, 0.65); // 主文本色
@text-color-secondary : rgba(0, 0, 0, .45); // 次文本色
@disabled-color : rgba(0, 0, 0, .25); // 失效色
@border-radius-base: 4px; // 组件/浮层圆角
@border-color-base: #d9d9d9; // 边框色
@box-shadow-base: 0 2px 8px rgba(0, 0, 0, 0.15); // 浮层阴影
@line: #e8e8e8; // 分割线颜色
```

### 通用标签属性

- `transfer` 让元素置顶层显示，防止被其他元素遮挡(如果未遮挡慎用)
- 使用空的`Col`完成排版`<Col span="2">&nbsp;</Col>`

## 示例

### 可编辑表单

## iview-admin

- iview-admin刷新浏览器地址跳转到首页，将`src/components/main/main.vue#mounted()`"设置了如果当前打开页面不在标签栏中，跳到homeName页"相关代码注释


---

参考文章

[^1]: https://www.jianshu.com/p/f812d7698272
