---
layout: "post"
title: "Go"
date: "2019-04-30 09:14"
categories: lang
tags: [go]
---

## 简介

- [官网](https://golang.org/)、[中文网](https://studygolang.com/dl)
- GO安装后会自动生成`GOROOT`、`GOPATH`环境变量。如`GOROOT=D:\software\go`，且会把`%GOPATH%\bin`添加到`Path`中。(GOPATH名称不能改成GO_HOME等)
- `GOPATH`允许多个目录，当有多个目录时windows使用分号分隔，当有多个GOPATH时默认将`go get`获取的包存放在第一个目录下。可设置`GOPATH=D:\software\go\gopath`。GOPATH目录约定有三个子目录
    - `src` 存放源代码(比如：.go .c .h .s等)，按照golang默认约定，go run，go install等命令的当前工作路径（即在此路径下执行上述命令）
    - `pkg` 编译时生成的中间文件(比如：.a)
    - `bin` 编译后生成的可执行文件
### 常用命令

- `go env` 查看go环境信息
- `go get` 安装包(先下载包，然后执行编译安装`go install`)
- `go install` 如果编译可执行文件则生成到bin目录；如果是一个普通的包则会放到pkg目录，以.a结尾

## 常用包

- `gvt` 包管理工具
    - 安装 `go get -u github.com/FiloSottile/gvt`
    - 通过gvt安装包 `gvt fetch github.com/fatih/color`








---

参考文章

[^1]: https://www.cnblogs.com/pyyu/p/8032257.html (Go语言之讲解GOROOT、GOPATH、GOBIN)







