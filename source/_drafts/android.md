---
layout: "post"
title: "Android应用开发"
date: "2019-11-25 13:23"
categories: [lang]
tags: [android]
---

## 简介

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

- Android 调试桥 (adb) 是一种功能多样的命令行工具，可让您与设备进行通信
- 位于`android_sdk/platform-tools/`
- 命令

```bash
# 列举设备(会显示设备编号如：emulator-5555)
adb devices

# 进入设备 emulator-5555 系统命令行(linux命令行)
adb -s emulator-5555 shell
```

### sdkmanager

> https://developer.android.google.cn/studio/command-line/sdkmanager.html

- 位于`android_sdk/tools/bin/`


