---
layout: "post"
title: "VSCode"
date: "2017-11-28 21:24"
categories: [extend]
tags: [ide, web]
---

## 简介

### 下载安装

```bash
https://az764295.vo.msecnd.net/stable/83bd43bc519d15e50c4272c6cf5c1479df196a4d/VSCodeUserSetup-ia32-1.68.0.exe
# 将az764295.vo.msecnd.net替换为vscode.cdn.azure.cn，镜像下载快的飞起
https://vscode.cdn.azure.cn/stable/83bd43bc519d15e50c4272c6cf5c1479df196a4d/VSCodeUserSetup-ia32-1.68.0.exe
```

## 快捷键

- 基于`IntelliJ IDEA Keybindings`插件模式，参考[idea.md#快捷键](/_posts/extend/idea.md#快捷键)
- 待记忆
    - `Ctrl+Shift+L` 选择所有找到的查找匹配项，此时所有的匹配项都有光标，可同时进行修改（如全部转大小写）
- 其他
    - `Ctrl+K Ctrl+S` `文件-首选项-键盘快捷方式` 可查看快捷键
    - `Alt+Shift+A` 注释/取消注释
    - 自定义
        - `Ctrl+Shift+U` 转大写
        - `Ctrl+Shift+Y` 转小写

## 插件推荐

> 可参考：[https://github.com/varHarrie/YmxvZw/issues/10](https://github.com/varHarrie/YmxvZw/issues/10)

- `Atom One Dark Theme` 类似Atom的黑色主题. 安装后重启：`文件-首选项-颜色主题`
- `IntelliJ IDEA Keybindings` IDEA快捷键配置
- `VSCode Browser Sync` 可开启一个静态服务器，并实时渲染。启动方式
	- `Ctrl+Shift+P` 打开命令数据框
	- 输入 `Server mode in browser`(再本地浏览器中打开)、`Server mode in side panel`(再vscode右边打开窗口)
- `Live Server` 启动静态服务器，并可实时刷新
- `PlantUML` PlantUML语法支持。支持markdown文件编写文本生成uml(可预览)，也可以支持单独 `*.wsd`/`*.plantuml` 文件编写代码生成uml
	- `Mermaid Preview` 基于Mermaid语法编写代码生成UML(可预览)
- `Vetur` Vue工具包(高亮等)

    ```json
    // 格式化vue文件
    "vetur.format.defaultFormatter.html": "js-beautify-html",
    // 关闭对vue文件eslint校验
    "vetur.validation.template": false
    ```
- [ESLint](https://eslint.org/) 代码书写规范(语法和格式校验)
    - `.eslintrc.js`(推荐)、`.eslintrc.json`、`.eslintrc.yml` 校验规则配置
        - **对某个项目关闭校验**：将`.eslintrc.js`中的`extends`和`rules`注释掉即可
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
    - `.eslintrc.js`个人习惯配置

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
                "eqeqeq": ["error", "smart"], // smart特点：数字比较必须要 ===
                // A && B换行时，符号在行头。https://eslint.org/docs/rules/operator-linebreak
                "operator-linebreak": ["error", "before"]
            },
            parserOptions: {
                parser: 'babel-eslint'
            }
        }
        ```
- `Beautify` 文件格式化，加下列配置格式化vue文件(推荐使用Prettier)

	```json
	"beautify.language": {
        "html": [
          "htm",
          "html",
          "vue"
        ]
    },
	```
- `Bracket Pair Colorizer 2` 代码括号对应颜色标识
- `Git Graph` git图片提交历史图形界面
- `GitLens` 显示每一行的提交人(会卡顿)
- `c/c++` 高亮及提示c/c++代码(运行还需安装MinGW/gcc编译器)
- `code-runner` 运行代码, 如c(还需按照c/c++插件)

    ```json
    {
        // 防止c语言运行乱码
        "code-runner.runInTerminal": true,
        "code-runner.executorMap": {
            // 其他语言的运行命令覆盖可在插件设置中修改executorMap
            "c": "chcp 65001 && cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt"
        }
    }
    ```
- `Flutter` Flutter开发插件
- `php debug`
    - php安装扩展xdebug
    - vscode安装扩展php-debug(xdebug的adapter)
    - https://www.cnblogs.com/studyskill/p/6873588.html
    - https://sriharibalgam.wordpress.com/2017/08/23/installing-xdebug-for-xampp-with-php-5-x-7-x/

## 用户配置

- 打开文件空格个数发生变化异常：去勾选User Settings -> Text Editor -> Detect Indentation
- json文件配置(新版本打开设置后在右上角点击打开json配置按钮)

```json
// 关闭预览模式。预览模式：单击文件会在一个预览窗口中覆盖显示(文件名显示为斜体)，双击文件/双击Tab标题则是真正打开文件
// "workbench.editor.enablePreview": false,

// 文件自动保存
"files.autoSave": "afterDelay",

"editor.snippetSuggestions": "top", // 将用户代码片段显示在提示的最上方
"editor.detectIndentation": false, // 因为vscode默认启用了根据文件类型自动设置tabsize的选项
"editor.fontSize": 16,
// tab占的空格数。Vue项目中尽管设置了Tab空格数为2，但是打开文件依旧变成了4个空格，则需要配置`.editconfig`文件中的空格数，参考[.editconfig文件](/_posts/arch/springboot-vue.md#.editorconfig格式化)
"editor.tabSize": 2,
"[html]": {
    "editor.tabSize": 2,
    "editor.defaultFormatter": "esbenp.prettier-vscode"
},
"[javascript]": {
    "editor.tabSize": 2,
    "editor.defaultFormatter": "esbenp.prettier-vscode"
},
// 函数function和()间增加空格
"javascript.format.insertSpaceBeforeFunctionParenthesis": true,
"javascript.updateImportsOnFileMove.enabled": "always",
"[vue]": {
    // "editor.defaultFormatter": "octref.vetur",
    "editor.defaultFormatter": "esbenp.prettier-vscode", // 使用 prettier 格式化插件
    "editor.tabSize": 2
},
"[less]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
},
"[markdown]": {
    "editor.tabSize": 4,
    "editor.defaultFormatter": "yzhang.markdown-all-in-one"
},
"[jsonc]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
}

// beautify美化插件
"beautify.language": {
	"html": [
		"htm",
		"html",
		"vue"
	]
},

// 格式化、校验、修复：https://juejin.im/post/5aeddf14f265da0b736d8a66 (部分参数过时)
// vetur默认配置
"vetur.format.defaultFormatterOptions": {
    // js-beautify-html 参数说明：https://github.com/HookyQR/VSCodeBeautify/blob/master/Settings.md
    "js-beautify-html": {
        "wrap_line_length": 140,
        // "wrap_attributes": "auto",
        "wrap_attributes": "aligned-multiple", // 当超出折行长度时，将属性进行垂直对齐，还有其他几个参数可选
        // "wrap_attributes": "force-aligned", // 当超出折行长度时，将属性进行垂直对齐，且每个属性一行
        "end_with_newline": false
    },
    "prettyhtml": {
        "printWidth": 140, // 默认80(适配1366屏幕，1920可设置成140)
        "singleQuote": false,
        "wrapAttributes": false,
        "sortAttributes": false
    }
},
// 使用格式化vue文件的html(不能安装一些不兼容的格式化插件)
"vetur.format.defaultFormatter.html": "js-beautify-html",
// 使用typescript语法格式化js，屏蔽vetur的js格式化(none)
"vetur.format.defaultFormatter.js": "vscode-typescript",
// 关闭vetur的eslint校验
"vetur.validation.template": false,
// 关闭保存时自动格式化
"editor.formatOnSave": false,
// 保存时自动fix(需要安装ESLint插件，且项目中有.eslintrc.js等文件；如果是自动保存，可文件右键-源代码操作-Fix)
"editor.codeActionsOnSave": {
    "source.fixAll.tslint": true
},

// 开启emmet对vue的支持，如输入div>ul>li按下Tab可快速构建一个dom树，更多语法参考emmet
"emmet.triggerExpansionOnTab": true,
"emmet.includeLanguages": {
    "vue-html": "html",
    "vue": "html"
},

"files.associations": {
    "*.wpy": "vue"
},
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
	"Print to console": {
		"prefix": "log",
		"body": [
			"console.log('$1')",
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
			"  name: '${1:component_name}',",
			"  data() {",
			"    return {",
			"    }",
            "  },",
            "  created() {",
            "    this.init()",
            "  },",
            "  methods: {",
            "    init() {",
            "      this.fetchData()",
            "    },",
            "    fetchData() {",
            "    }",
            "  }",
			"}",
			"</script>",
			"",
			"<style lang=\"${2:less}\" scoped>",
            "</style>",
            ""
		],
		"description": "Create vue template"
	}
}
```
