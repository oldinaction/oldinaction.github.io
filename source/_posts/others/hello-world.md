---
layout: "post"
title: "你好，世界"
date: "2016-04-10 09:38"
categories: others
tags: [others]
---

<p>我的第一篇文章</p>

## MD 语法

- md文件中可以使用html标签
- `---`代表分割线

### 代码块

```diff
- cluster.slaveCount: 2
+ cluster.slaveCount: 3
```

### 排版

- 正文的第一级标题用h2(`##`)，标题和字段间要有换行

### 详细隐藏/展示

```html
<details>
<summary>详细隐藏/展示的标题</summary>

<p>详细内容......</p>

</details>
```

### 列表

- 列表（有序/无序）下面显示 **代码、引用、图片** 时：相对列表的该子项代码需要多缩进一个Tab（4个空格），且中间要空行，如：

  <pre>
  - 标题

    &#x60;&#x60;&#x60;html
      ...
    &#x60;&#x60;&#x60;
  </pre>
- 引用需要上下都空一行，列表只需要在上面空一行
- 子列表基于父列表要有一个Tab缩进(4个空格)，中间无需空行

### 链接

- 图片格式如：`![hello](/data/images/2017/07/hello.png)`
- 内部链接格式如：`[《nginx》http://blog.aezo.cn/2017/01/16/arch/nginx/](/_posts/arch/nginx.md#基于编译安装tengine)`，其中`#`后面为完整子标题
- hexo转义字符：`{`对应`&#123;`/`}`对应`&#125;` (如写vue代码的时会出现双大括号导致hexo编译失败，此时提示如`Template render error: (unknown path) [Line 31, Column 21]`)
- hexo文章元信息`---`后面不能有空格，否则容易报错`YAMLException: bad indentation of a sequence entry`
- 锚链接和连接带空格案例 `[MD 语法](#MD%20语法)` [MD 语法。连接中空格使用%20代替](#MD%20语法)

### 脚注

脚注支持链接跳转，注意脚注与被批注文本之间有一个空格

<pre>
标题或者文字 [^1]

---

参考文章

[^1]: [http://blog.aezo.cn](http://blog.aezo.cn)
</pre>

## github-jeykll-markdown个人书写习惯

> 2017-07-01 之后使用hexo书写博客, 格式依然可用

### 元信息

- categories和tage都可以有多个。其中`---`后面不能有空格

```html
---
categories: [cat1, cat2]
tags: [tag1, tag2, tag3]
---
```

## github-hexo-markdown个人书写习惯

### 修改文章后保存源码并更新博客

- **更新步骤如下** (或者直接执行项目目录下的**blog-deploy.sh**文件)

  ```shell
  $ hexo clean # 有时候修改了静态文件需要先clean一下
  $ git add .
  $ git commit -am "update blog"
  $ git push origin master:source
  $ hexo g && gulp && hexo d
  ```

### 博客源码管理和博客更新

- 本地处于master分支，远程有master(为博客渲染后的代码)和source(博客源码, 可设为远程默认分支)两个分支
- 更新博客 `hexo d -g`
    - `_config.yml`文件中需要指向master分支

        ```yml
        deploy:
          type: git
          repository: https://github.com/aezocn/aezocn.github.io.git
          branch: master
        ```

### 相关命令

- `hexo clean` 清除缓存(如果未修改配置文件可不运行)
- `hexo g`/`hexo generate` 静态文件生成(修改主题文件可不用重新启动服务)
- `hexo s -p 5000`(`hexo server`) **启动本地服务器(本地测试)**
- `hexo d`/`hexo deploy` 部署到github

### clone

- clone远程source分支到本地master分支
- `npm install -g hexo-cli` 全局安装hexo
- `npm install` 初始化
- 按照上述【修改文章后保存源码并更新博客】进行部署

### 功能

#### 搜索

- NexT主题本地搜索
  - 安装：`npm install --save hexo-generator-search`
  - 开启local_search
  - 还可手动写本地搜索功能 [^1]
- 基于 [Algolia](https://www.algolia.com/) 的搜索

```bash
# 注册 Algolia 账号

# 安装插件
npm install hexo-algolia --save

# 站点根目录打开_config.yml添加以下代码
# Algolia Search API Key
algolia:
  applicationID: '你的Application ID'
  apiKey: '你的Search-Only API Key'
  indexName: '输入刚才创建index name'
```

#### PlantUML

- `npm install --save hexo-filter-plantuml` 安装插件(vscode可以再配合插件`PlantUML`使用)
- markdown语法如下

<pre>
&#x60;&#x60;&#x60;plantuml
@startuml
/' 样式(背景和波浪线条)和标题。这是代码注释，不会渲染 '/
skinparam backgroundColor #EEEBDC
skinparam handwritten true
title
  标题和水印 &lt;img:http://blog.aezo.cn/aezocn.png&gt;
end title

Bob->Alice : hello
@enduml
&#x60;&#x60;&#x60;
</pre>

#### markdown标题编号(css实现)

```css
/* markdown标题编号 */
.post-body {
    /* 文章标题习惯从h2开始
    h1 {
        counter-increment: counter_h1;
        counter-reset: counter_h2;
    }
    h1:before {
        content: counter(counter_h1)"　";
    } 
    */
    h2 {
        counter-increment: counter_h2;
        counter-reset: counter_h3;
    }
    h2:before {
        content: counter(counter_h2)"　";
    }
    h3 {
        counter-increment: counter_h3;
        counter-reset: counter_h4;
    }
    h3:before {
        content: counter(counter_h2)"."counter(counter_h3)"　";
    }
    h4 {
        counter-increment: counter_h4;
        counter-reset: counter_h5;
    }
    h4:before {
        content: counter(counter_h2)"."counter(counter_h3)"."counter(counter_h4)"　";
    }
    h5 {
        counter-increment: counter_h5;
        counter-reset: counter_h6;
    }
    h5:before {
        content: counter(counter_h2)"."counter(counter_h3)"."counter(counter_h4)"."counter(counter_h5)"　";
    }
    h6 {
        counter-increment: counter_h6;
    }
    h6:before {
        content: counter(counter_h2)"."counter(counter_h3)"."counter(counter_h4)"."counter(counter_h5)"."counter(counter_h6)"　";
    }
}
```

### 主题

#### next

- 自定义代码在`/themes/next/layout/_custom/`目录下
- footer代码修改 `/themes/next/layout/_partials/footer.swig`
- 部分图片禁用fancybox，可在img上加`class="nofancybox"`。需要修改主题中的js文件，详细修改方法参考https://blog.csdn.net/cddchina/article/details/79764432


---

参考文章

[^1]: http://www.hahack.com/codes/local-search-engine-for-hexo/ (jQuery-based Local Search Engine for Hexo)