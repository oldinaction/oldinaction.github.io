---
layout: "post"
title: "你好，世界"
date: "2016-04-10 09:38"
categories: others
tags: [others]
---

<p>我的第一篇文章</p>

## github-jeykll-markdown个人书写习惯

> 2017-07-01 之后使用hexo书写博客, 格式依然可用

### 元信息

categories和tage都可以有多个

```html
    categories: [cat1, cat2]
    tags: [tag1, tag2, tag3]
```

### md语法

- md文件中可以使用html标签
- `---`代表分割线

### 排版

正文的第一级标题用h2(`##`)，标题和字段间要有换行

### 列表

- 列表（有序/无序）下面显示 **代码、引用、图片** 时：相对列表的该子项代码需要多缩进一个Tab（4个空格），且中间要空行，如：

  <pre>
  - 标题

    ```html
      ...
    ```
  </pre>
- 引用需要上下都空一行，列表只需要在上面空一行

- 子列表基于父列表要有一个Tab缩进（4个空格），中间无需空行

### 脚注

脚注支持链接跳转，注意脚注与被批注文本之间有一个空格

<pre>
标题或者文字 [^1]

---

参考文章

[^1]: [http://blog.aezo.cn](http://blog.aezo.cn)
</pre>


## github-hexo-markdown个人书写习惯

### 相关命令

- `hexo clean` 清除缓存(如果未修改配置文件可不运行)
- `hexo g`/`hexo generate` 静态文件生成
- `hexo s -p 5000`/`hexo server` 启动本地服务器(本地测试)
- `hexo d`/`hexo deploy` 部署到github









-----------------------------
