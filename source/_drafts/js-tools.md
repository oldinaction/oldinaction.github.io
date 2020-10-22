---
layout: "post"
title: "JS Tools"
date: "2020-10-9 15:18"
categories: js
tags: tools
---

## vxe-table

- 一款基于Vue的表格插件，支持大量数据渲染，编辑表格等功能
- [github](https://github.com/x-extends/vxe-table)、[doc](https://xuliangzhan_admin.gitee.io/vxe-table/#/table/start/install)

### 案例

- 表格显示/隐藏后样式丢失问题
  - `sync-resize` 绑定指定的变量来触发重新计算表格。参考：https://xuliangzhan_admin.gitee.io/vxe-table/#/table/advanced/tabs
- 多选 + 修改页面表格数据(仅修改页面数据缓存)

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
```



