---
layout: "post"
title: "jekyll"
date: "2016-04-16 13:45"
categories: extend
tag: [jekyll]
---

* 目录
{:toc}

## jekyll 介绍 [^1]

[Jekyll](http://jekyllrb.com/)（发音/'dʒiːk əl/，"杰克尔"）是一个静态站点生成器，它会根据网页源码生成静态文件。它提供了模板、变量、插件等功能，所以实际上可以用来编写整个网站。

> Github Pages
>
> - github Pages 是 GitHub 提供给用户展示项目主页的静态网页。因此利用 jekyll 搭建网站的话，我们只需要编写好网页文件(或者md文件)上传到 Github 即可（上传的文件会经过 jekyll 程序处理，最终得到我们可以浏览的网页）
> **[本教程源码下载](https://github.com/oldinaction/Git/tree/master/demo/jekyll)**

## 利用 jekyll 搭建博客初步 [^2]

### 新建GitHub项目

> 在搭建之前，你必须已经安装了 [git](https://git-scm.com/)，并且有 [github](https://github.com/) 账户。

1. 假如 github 主页是 `https://github.com/oldinaction`, 那么新建一个仓库 (repository), 仓库起名为 `oldinaction.github.io`(一定要为`用户名.github.io`)
2. 克隆到本地仓库：`git clone https://github.com/oldinaction/oldinaction.github.io.git`

### 在本地仓库创建相关文件

1. 创建配置文件：在项目根目录下，建立一个名为 `_config.yml` 的文本文件。它是jekyll的设置文件，我们暂时不需要加任何内容，有关配置可参考[官方文档](http://jekyllrb.com/docs/configuration/)。
2. 创建模板文件
  - 在项目根目录下，创建一个`_layouts`目录，用于存放模板文件
  - 进入该目录，创建一个`default.html`文件，作为Blog的默认模板。并在该文件中填入以下内容

    ![创建模版文件](/data/images/2016/07/jekyll-0.png)
    > Jekyll使用[Liquid模板语言](https://github.com/shopify/liquid/wiki/liquid-for-designers)，更多模板变量请参考[官方文档](https://jekyllrb.com/docs/templates/)。

3. 创建文章
  - 回到项目根目录，创建一个`_posts`目录，用于存放blog文章
  - 新建文件 `2016-04-10-hello-world.html`(注意，文件名必须为"年-月-日-文章标题.后缀名"的格式。也支持 markdown 格式)。 在该文件中，填入以下内容：（注意，行首不能有空格）
  ![创建文章](/data/images/2016/07/jekyll-1.png)

  > - 每篇文章的头部，必须有一个yaml文件头，用来设置一些元数据。它用三根短划线"---"，标记开始和结束，里面每一行设置一种元数据。"layout:default"，表示该文章的模板使用_layouts目录下的default.html文件；"title: 你好，世界"，表示该文章的标题是"你好，世界"，如果不设置这个值，默认使用嵌入文件名的标题，即"hello world"。
  > - 这里要注意的是，Liquid模板语言规定，**输出内容使用两层大括号，单纯的命令使用一层大括号**

4. 创建首页
  - 回到根目录，创建一个 `index.html` 文件，填入以下内容
  ![创建首页](/data/images/2016/07/jekyll-2.png)

### 提交到 github

1. 添加内容到本地仓库: 先执行命令 `$ git add .` ，再执行命令 `$ git commit -am 'jekyll demo'`
2. 访问：打开 `http://oldinaction.github.io/` 即可看到我们的博客

### 绑定域名

如果你不想用http://oldinaction.github.io/这个域名，可以换成自己的域名。具体方法是：
- 在仓库的根目录下面，新建一个名为 `CNAME` 的文本文件，里面写入你要绑定的域名，比如 `example.com` 或者 `xxx.example.com`。
- 如果绑定的是顶级域名，则DNS要新建一条A记录，指向 `204.232.175.78`。如果绑定的是二级域名，则DNS要新建一条CNAME记录，指向`username.github.com`（请将username换成你的用户名）；如果是组织类pages，则指向`username.github.io`
- 在_config.yml文件中写入`baseurl=""`

---

## windows 在本地搭建jekyll博客 [^3]

### 搭建环境

#### 安装Ruby

- 下载地址：[Ruby](http://rubyinstaller.org/downloads/)
- 安装时勾选`Add Ruby executables to your PATH` （将ruby加到环境变量的Path中）
- 检测安装：在命令行运行 `ruby -v` 显示版本号则成功

#### 安装Ruby的DevKit

- 下载地址：[DEVELOPMENT KIT](http://rubyinstaller.org/downloads/) 选择合适的版本
- 运行解压到某目录，如 `D:\software\RubyDevKit`
- 初始化devkit并将其绑定到Ruby安装
	- 在命令行cd到DevKit的安装目录RubyDevKit
	- 运行 `ruby dk.rb init`
	-  运行 `ruby dk.rb install`

#### 安装jekyll

打开命令行，运行 `gem install jekyll` ， 得一会运行

#### 安装python

- 下载地址： [python](https://www.python.org/downloads/) 我下的是2.7.11
- 勾选`Add python.exe to Path`（将python加到环境变量的Path中）
-  检测安装：在命令行运行 `python -v`（如果运行失败，看环境变量中是否有python的安装目录）

#### 安装pip

pip是一个Python包的安装和管理工具。你会需要它的安装pygments,pygments.rb突出你的代码,使用Python包。

如果Python 2 >=2.7.9 or Python 3 >=3.4，只需在命令行运行 `python -m pip install -U pip` 即可。此处是2.7.11，所有运行命令即可

### 运行jekyll

- 打开命令行，cd 到 d:/note 目录（博客的目录将会在此处生成）
- 运行 `jekyll new blog`，此时d:/note会产生一个blog目录
- cd到此目录
- 运行 `jekyll serve` ，这是本地博客服务器的启动命令
    - `Ctrl+C` 停止服务
- 访问 [http://localhost:4000](http://localhost:4000) 即可看到博客欢迎界面

---

## jekyll使用笔记

### 文章编写

1. 在atom中使用插件mdwriter写文章
2. 文章元信息中的categories可以有多个分类，如`categories: [web, js]`
3. `_posts`中目录层级不限，文章的显示只根据元信息获取
4. jekyll代码和markdown代码需要使用：{% raw %}\{% raw %\}代码\{% endraw %\}{% endraw %}

### jekyll博客主题样式

- 主页文章分页 [^4]
    - `_config.yml`中加入

        {% raw %}
            paginate: 10
            paginate_path: "page:num"
        {% endraw %}

    - 见根目录下`index.xml`
- 文章分类：见`categories.html`
- 查看分类下的文章 [^5] (**？？？**)
- markdown文章标题生成目录 [^6]

    {% raw %}

        * 目录(星号必须有，标题可随便取)
        {:toc} // {:toc #myid} 则会生成id，默认是markdown-toc

        ## 标题一

            如果要把某标题从目录树中排除，则在该标题的下一行写上 {:.no_toc}

    {% endraw %}
- 代码高亮
    - 法一：常用
        - `_config.yml`中加入`highlighter: rouge`
        - 配上css样式文件
    - 法二：使用原生高亮代码，如：{% raw %}{% highlight html %}代码{% endhighlight %}{% endraw %}
- 文章搜索(**？？？**)
- 页面新建
    - 方法一：在根目录建立`pagetest.html`的文件，访问`http://localhost:4000/pagetest`即可看到该页面
    - 方法二：在根目录新建`pages`的目录，在里面新建`test1`目录，在test1目录新建`index.html`文件，访问`http://localhost:4000/pages/test1`即可看到该页面。注意test1目录只有名为index.html的文件才生效。同理在pages目录新建test2，亦可访问test2的链接


### jekyll语法

### 其他

1. 本地运行的jekyll，修改了`_config.yml`需要重新启动，修改了所有的`.hmtl`，`.md`文件可以直接看到效果


---

参考文章

[^1]: [jekyll官方文档](http://jekyllrb.com/docs/home/)
[^2]:  [Github搭建jekyll博客](http://www.ruanyifeng.com/blog/2012/08/blogging_with_jekyll.html)
[^3]: [Windows本地安装jekyll](http://blog.csdn.net/itmyhome1990/article/details/41982625)
[^4]: [jekyll文章分类](http://www.52ij.com/jishu/99014.html)
[^6]: [markdown文章标题生成目录](http://www.111cn.net/sys/linux/70052.htm)
