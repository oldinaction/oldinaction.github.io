---
layout: "post"
title: "Android应用开发"
date: "2019-11-25 13:23"
categories: [lang]
tags: [android]
---

## 简介

## 安装

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


