

- 编辑器: 初始化低代码编辑器基座项目(lowcode-demo/demo-general已经安装了编辑器，内置了一些插件和物料)
- 插件: 指为低代码编辑器增加插件，如顶部区域Logo为一个插件，可以在顶部区域或侧边栏增加插件模块
    - 在插件项目的 build.json 下面新增 "inject": true，则默认通过官方demo进行调试，设置成false则是本地调试
- 物料: 指可以拖拽的组件元素

```bash
# 报错: ERESOLVE unable to resolve dependency tree
npm install --legacy-peer-deps
```
