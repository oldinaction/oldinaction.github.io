---
layout: "post"
title: "vscode"
date: "2017-11-28 21:24"
categories: [extend]
tags: [ide]
---

## 插件推荐

> 可参考：[https://github.com/varHarrie/YmxvZw/issues/10](https://github.com/varHarrie/YmxvZw/issues/10)

- `Atom One Dark Theme` 类似Atom的黑色主题
- `Vetur` Vue工具包(高亮)
- `ESLint` js代码书写规范(语法和格式校验). 并在vscode的配置中加，这样每次保存的时候就可以根据根目录下.eslintrc.js你配置的eslint规则来检查和做一些简单的fix

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