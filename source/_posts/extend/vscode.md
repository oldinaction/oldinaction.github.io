---
layout: "post"
title: "vscode"
date: "2017-11-28 21:24"
categories: [extend]
tags: [ide, web]
---

## 快捷键(基于`IntelliJ IDEA Keybindings`插件模式)

- `Ctrl+K Ctrl+S` `文件-首选项-键盘快捷方式` 可查看快捷键
- `Alt+Shift+A` 注释/取消注释
- `Ctrl+Shift+L` 选择所有找到的查找匹配项，此时所有的匹配项都有光标，可同时进行修改（如全部转大小写）
- 自定义
	- `Ctrl+Shift+U` 转大写
	- `Ctrl+Shift+Y` 转小写

## 插件推荐

> 可参考：[https://github.com/varHarrie/YmxvZw/issues/10](https://github.com/varHarrie/YmxvZw/issues/10)

- `Atom One Dark Theme` 类似Atom的黑色主题. 安装后重启：`文件-首选项-颜色主题`
- `Vetur` Vue工具包(高亮等)

    ```json
    // 格式化vue文件
    "vetur.format.defaultFormatter.html": "js-beautify-html",
    // 关闭对vue文件eslint校验
    "vetur.validation.template": false
    ```
- `ESLint` 代码书写规范(语法和格式校验)
    - `.eslintrc.js`(推荐)、`.eslintrc.json`、`.eslintrc.yml` 校验规则配置
        - 关闭校验：将`.eslintrc.js`中的`extends`和`rules`注释掉即可
    - vscode首选项配置(ide + eslint)
        
        ```js
        "eslint.validate": [
            "javascript",
            "javascriptreact",
            "html",
            {
                "language": "vue",
                "autoFix": true
            }
        ],
        "eslint.options": {
            "plugins": [
                "html"
            ]
        }
        ```
    - vue项目的`build/webpack.base.config.js`中加入eslint的loader(ci + eslint)。项目编译的时候会进行格式校验
- `IntelliJ IDEA Keybindings` idea快捷键配置
- `Beautify` 文件格式化，加下列配置格式化vue文件

	```json
	"beautify.language": {
        "html": [
          "htm",
          "html",
          "vue"
        ]
    },
	```
- `Markdown All in One` 可现实md文件菜单
- `VSCode Browser Sync` 可开启一个静态服务器，并实时渲染。启动方式
	- `Ctrl+Shift+P` 打开命令数据框
	- 输入 `Server mode in browser`(再本地浏览器中打开)、`Server mode in side panel`(再vscode右边打开窗口)

## 用户配置

```json
// 关闭预览模式。预览模式：单击文件会在一个预览窗口中覆盖显示(文件名显示为斜体)，双击文件/双击Tab标题则是真正打开文件
// "workbench.editor.enablePreview": false,

// 文件自动保存
"files.autoSave": "afterDelay",
	
// tab占的空格数
"editor.tabSize": 2,
// markdown文件格式
"[markdown]": {
	"editor.tabSize": 4
},

"beautify.language": {
	"html": [
		"htm",
		"html",
		"vue"
	]
},

// 关闭vue文件eslint校验
"vetur.validation.template": false,
// 格式化vue文件(不能安装一些不兼容的格式化插件)
"vetur.format.defaultFormatter.html": "js-beautify-html",

// 开启emmet对vue的支持，如输入div>ul>li按下Tab可快速构建一个dom树，更多语法参考emmet
"emmet.triggerExpansionOnTab": true,
"emmet.includeLanguages": {
    "vue-html": "html",
    "vue": "html"
}
```

## 用户代码片段

- `javascript.json` 

```json
{
	// Place your snippets for javascript here. Each snippet is defined under a snippet name and has a prefix, body and 
	// description. The prefix is what is used to trigger the snippet and the body will be expanded and inserted. Possible variables are:
	// $1, $2 for tab stops, $0 for the final cursor position, and ${1:label}, ${2:another} for placeholders. Placeholders with the 
	// same ids are connected.
	// Example:
	"Print to console": {						// 描述
		"prefix": "log",						// 需要键入的代码
		"body": [								// 补全的内容
			"console.log($1)"
		],
		"description": "Log output to console"	// 显示的描述信息
	},
	"Debugger": {
		"prefix": "deb",
		"body": [
			"debugger"
		],
		"description": "Debugger"
	}
}
```

- `vue.json` 在编辑器中打`vue`就会有此代码片段提示

```json
{
	// Place your snippets for HTML here. Each snippet is defined under a snippet name and has a prefix, body and 
	// description. The prefix is what is used to trigger the snippet and the body will be expanded and inserted. Possible variables are:
	// $1, $2 for tab stops, ${id} and ${id:label} and ${1:label} for variables. Variables with the same id are connected.
	// Example:
	"Create vue template": {
		"prefix": "vue",
		"body": [
			"<template>",
			"",
			"</template>",
			"",
			"<script>",
			"export default {",
			"  name: \"${1:component_name}\",",
			"  data () {",
			"    return {",
			"    };",
			"  }",
			"}",
			"</script>",
			"",
			"<style lang=\"${2:css}\">",
			"</style>"
		],
		"description": "Create vue template"
	}
}
```