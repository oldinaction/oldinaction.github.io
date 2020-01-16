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

### Select 远程搜索

- Select 标签，检索数据项的多个属性时远程搜索无效 [^1]

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

### 表格

#### 去掉自带扩展行图标，换成按钮控制

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
              return h(expandRow, {
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

## 样式

### 通用标签属性

- `transfer` 让元素置顶层显示，防止被其他元素遮挡(如果未遮挡慎用)
- 使用空的`Col`完成排版`<Col span="2">&nbsp;</Col>`

---

参考文章

[^1]: https://www.jianshu.com/p/f812d7698272
