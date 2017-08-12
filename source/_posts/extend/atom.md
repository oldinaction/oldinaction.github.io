---
layout: "post"
title: "atom"
date: "2017-03-19 15:33"
categories: [extend]
tags: [ide]
---

## atom安装

## atom快捷键

1. 快捷键查看：`File - Settings - Keybindings`
    - 编辑用户快捷键：`File - Settings - Keymap`(编辑后无需重启)
    - 插件快捷键可能会冲突。搜索某个快捷键时，后面表示会覆盖前面的
2. 常用快捷键设置

    ```bash
    ##### 我自己加的快捷键 START #####
    # 打开命令Panel: ctrl-shift-p

    # 删除一行(ctrl-d) / ctrl-shift-k(默认)
    'atom-text-editor:not([mini])':
      'ctrl-d': 'editor:delete-line'
    # 上下移动一行 ctrl-up、ctrl-down

    # html预览切换（插件atom-html-preview）
    'atom-text-editor[data-grammar~=html]':
      'ctrl-shift-b': 'atom-html-preview:toggle'
    ##### 我自己加的快捷键 END #####
    ```

## atom插件

- [插件排行榜](https://atom.io/packages/list)
- `minimap` 代码地图
- `atom-beautify` 代码美化，Ctrl+Alt+B
- `file-icons` 文件图标美化
- `script` 脚本运行器，可运行几乎所有语言(有些需要运行环境)，**`Ctrl+Shift+B` 运行脚本**
- `atom-html-preview` html预览
    - 可在Atom编辑器中启一个预览的Tab，在预览页右键-Open Devtools可打开控制台
- `markdown-writer` 可快速markdown文件(结合jekyll写博客)
- `git-plus` git增强工具。在设置中配置`git path`为`git.exe`的路径(如：`D:\java\Git\cmd\git.exe`)
- `platformio-ide-terminal` 终端嵌入(安装前需要安装git，并将git配置到path中)

- `vue-autocomplete` vue.js自动补全
- `language-vue` .vue文件高亮
- `autocomplete-python` python自动补全. 需要将python的执行版本设置到python中
- `autocomplete-php` 自动补全php. 需要配置php.exe的执行位置
- `php-server` 启动php服务器



## 常见错误

1. win安装或更新插件时，报错：`gyp ERR! stack Error: EPERM: operation not permitted`
    - 解决办法：以管理员身份运行atom
