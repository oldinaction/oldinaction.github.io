---
layout: "post"
title: "vscode"
date: "2017-11-28 21:24"
categories: [extend]
tags: [ide, web]
---

## 快捷键

- `Ctrl+K Ctrl+S` `文件-首选项-键盘快捷方式` 可查看快捷键
- `Alt+Shift+A` 注释/取消注释

## 插件推荐

> 可参考：[https://github.com/varHarrie/YmxvZw/issues/10](https://github.com/varHarrie/YmxvZw/issues/10)

- `Atom One Dark Theme` 类似Atom的黑色主题
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

## 用户配置

```json
// tab占的空格数
"editor.tabSize": 2,

// 开启emmet对vue的支持，如输入div>ul>li按下Tab可快速构建一个dom树，更多语法参考emmet
"emmet.triggerExpansionOnTab": true,
"emmet.includeLanguages": {
    "vue-html": "html",
    "vue": "html"
}

```

## 用户代码片段

- `vue.json` 在编辑器中打`vue`就会有此代码片段提示

```json
{
	// Place your snippets for HTML here. Each snippet is defined under a snippet name and has a prefix, body and 
	// description. The prefix is what is used to trigger the snippet and the body will be expanded and inserted. Possible variables are:
	// $1, $2 for tab stops, ${id} and ${id:label} and ${1:label} for variables. Variables with the same id are connected.
	// Example:
	"Print to console": {
		"prefix": "log",
		"body": [
			"console.log('$1');",
			"$2"
		],
		"description": "Log output to console"
	},
	"Create vue template": {
		"prefix": "vuec",
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