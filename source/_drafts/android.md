---
layout: "post"
title: "Android应用开发"
date: "2019-11-25 13:23"
categories: [lang]
tags: [android]
---

## 简介

- 安卓模拟器：`Genymotion`

## 安装

- 安装Android SDK(任意一种)
    - 直接安装Android Studio可内置安装Android SDK和Android模拟器(Tools菜单)
    - 基于SDK Tools安装
- 基于SDK Tools安装（参考https://zhuanlan.zhihu.com/p/37974829)）
  - 国内在 https://www.androiddevtools.cn/ 下载 SDK Tools 进行 Android SDK 安装
    - zip包下载地址：https://dl.google.com/android/android-sdk_r24.4.1-windows.zip?utm_source=androiddevtools&utm_medium=website
  - 启动SDK Manager，安装Tools、API、Extras（可使用代理下载）
  - 设置`ANDROID_HOME=D:\software\android-sdk`
  - 把`%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools`添加到Path环境变量中
  - 命令行输入`adb`测试是否安装成功

## 命令

### adb

> https://developer.android.google.cn/studio/command-line/adb

- ADB (Android Debug Birdge 调试桥) 是一种功能多样的命令行工具，可让您与设备进行通信 [^1]
  - ADB 分为三部分：PC上的`adb client`、`adb server` 和 Android设备上的`adb daemon`(adbd)
  - `ADB client`：Client本质上就是Shell，用来发送命令给Server。发送命令时，首先检测PC上有没有启动Server，如果没有Server，则自动启动一个Server，然后将命令发送到Server，并不关心命令发送过去以后会怎样
  - `ADB server`：运行在PC上的后台程序，目的是检测USB接口何时连接或者移除设备
    - ADB Server对本地的TCP 5037端口进行监听，等待ADB Client的命令尝试连接5037端口
    - ADB Server维护着一个已连接的设备的链表，并且为每一个设备标记了一个状态：offline，bootloader，recovery或者online
    - Server一直在做一些循环和等待，以协调client和Server还有daemon之间的通信
  - `ADB Daemon`：运行在Android设备上的一个进程，作用是连接到adb server（通过usb或tcp-ip）。并且为client提供一些服务
- 命令（位于`android_sdk/platform-tools/`）

```bash
# 打开开发者模式：USB线连接手机和电脑，并且在开发者选项当中，开启USB调试
# 列举设备(会显示设备编号如：emulator-5555)
adb devices

# 进入设备 emulator-5555 系统命令行(linux命令行)
adb -s emulator-5555 shell
```
- 无线连接Android设备

```bash
adb tcpip 5555
adb kill-server
adb connect 192.168.1.12:5555 # 手机的IP地址
adb disconnect 192.168.1.12:5555 # 断开设备连接

# 切换到USB模式 
adb usb
# 切换到WIFI无线调试
adb tcpip 5555
```

### sdkmanager

> https://developer.android.google.cn/studio/command-line/sdkmanager.html

- 位于`android_sdk/tools/bin/`



---

参考文章

[^1]: https://www.jianshu.com/p/6769bfc3e2da
