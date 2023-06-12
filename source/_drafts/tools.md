---
layout: "post"
title: "Tools"
date: "2018-05-14 13:06"
categories: extends
tags: tools
---

## 通用

### 开发

#### VNC(RealVNC)

官网免费版支持5台电脑3个用户7*24小时连接
破解版下载：http://www.xdowns.com/soft/1/118/2017/Soft_224671.html
https://blog.csdn.net/runningtortoises/article/details/51425299

#### notepad++

- 插件推荐
    - `XML Tools` 格式化xml文件
        - 格式化xml文件：点击plugin，选择ML Tools，点击`pretty print xml(only-with line breaks)`即可
    - MarkdownViewer++
    - JSON Viewer
    - JSTool
    - NppAStyle

## 谷歌浏览器插件

- 参考：[http://blog.aezo.cn/2017/09/13/extend/chrome/](/_posts/extend/chrome.md#chrome插件收集)

## windows

### QuickLook 预览工具

按下空格即可快速预览文件，微软商店内的免费应用

### Wox 快速启动 [^2]

- https://github.com/Wox-launcher/Wox
- 下载`Wox-1.3.524.exe`和`Everything-1.3.4.686.x64-Setup.exe`(Wox和Everything配合使用可快速检索文件)
- `Alt+Space`启动
- `Win+R`代替windows

### 任务栏分屏

每个屏幕显示各自的任务栏

- win10：任务栏设置 - 多显示器设置 - 将任务栏按钮显示在: 打开了窗口的任务栏

### cmder

- 代替系统的cmd，支持多tab
- [下载地址，官方有点慢](http://www.softpedia.com/get/Programming/Other-Programming-Files/Cmder.shtml)
- 加入到右键菜单
    - 把Cmder.exe存放的目录添加到系统环境变量
    - cmd管理员模式运行命令`Cmder.exe /REGISTER ALL`

### Linux相关软件

- grep
    - [grep for windows](http://gnuwin32.sourceforge.net/packages/grep.htm)、[下载](http://downloads.sourceforge.net/gnuwin32/grep-2.5.4-setup.exe)

### MobaXterm

- 代替xshell、xftp客户端，用作web服务器、ssh服务器
- 保持ssh连接：settings - ssh - 勾选ssh keepalive

## 奇技淫巧

### alist加速百度下载

- go语言编写，其实是一个聚合网盘程序，但是内置功能可以实现百度网盘下载加速功能
- [alist](https://alist.nn.ci/zh/)
- [github](https://github.com/alist-org/alist)
- 使用
    - 安装参考：https://alist.nn.ci/zh/guide/install/script.html
    - `./alist server && ./alist admin` 运行程序并获取管理员信息(会在当前目录创建data数据文件夹，里面config有服务地址和端口，如: http://localhost:5244)
    - 登录管理后台 - 存储 - 添加百度网盘
        - 开启Web代理
        - 启用签名
        - 刷新令牌、客户端ID、客户端密钥，参考：https://alist.nn.ci/zh/guide/drivers/baidu.html 获取
    - 再进入首页可查看到当前百度网盘登录账号下所有文件，直接下载，速度飞快








---

参考文章

[^1]: https://www.liutf.com/posts/3720794851.html
[^2]: https://www.cnblogs.com/zhaoqingqing/p/6902113.html


