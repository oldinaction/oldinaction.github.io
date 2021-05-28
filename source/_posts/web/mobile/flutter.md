---
layout: "post"
title: "Flutter"
date: "2019-11-22 14:54"
categories: [web]
tags: [App, dart, mobile]
---

## 简介

- [Flutter](https://flutter.dev/)、[Dart](https://dart.dev/)、[Flutter 实战](https://book.flutterchina.club/)
- `Flutter` 是 `Google` 推出并开源的移动应用开发框架，主打跨平台、高保真、高性能。开发者可以通过 `Dart` 语言开发 App，一套代码同时运行在 iOS 和 Android 平台
- 移动开发中的跨平台技术
    
    ![mobile-dev](/data/images/lang/mobile-dev.png)
- AOT和JIT
    - 程序主要有两种运行方式：静态编译与动态解释
    - `静态编译`的程序在执行前全部被翻译为机器码，通常将这种类型称为`AOT`(Ahead of time)，即"提前编译"
    - `解释执行`的则是一句一句边翻译边运行，通常将这种类型称为`JIT`(Just-in-time)，即"即时编译"
    - AOT程序的典型代表是用C/C++开发的应用，它们必须在执行前编译成机器码；而JIT的代表则非常多，如JavaScript、python等，事实上，所有脚本语言都支持JIT模式
    - 一般认为只要需要编译，无论其编译产物是字节码还是机器码，都属于AOT。如Java、Python，它们可以在第一次执行时编译成中间字节码
- Flutter特性
    - 基于JIT的快速开发周期：Flutter在开发阶段采用，采用JIT模式
    - 基于AOT的发布包：Flutter在发布时可以通过AOT生成高效的ARM代码以保证应用性能
    - 类型安全：由于Dart是类型安全的语言，支持静态类型检测
- `Dart`的设计目标应该是同时借鉴了Java和JavaScript。Dart在静态语法方面和Java非常相似，如类型定义、函数声明、泛型等，而在动态特性方面又和JavaScript很像，如函数式特性、异步支持等

## 安装及运行

### 安装

- 配置环境变量
    
    ```bash
    export PUB_HOSTED_URL=https://pub.flutter-io.cn
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    ```
- 安装git
- [下载Flutter SDK](https://github.com/flutter/flutter/releases)，解压，并将`%flutter_home%/bin`设置到环境变量，执行`flutter doctor`看是否成功安装(可运行即可)
- `Dart SDK`已经捆绑在Flutter SDK中，故无需在单独安装Dart SDK
- 安装Android SDK，参考[android.md#安装](/_posts/lang/android.md#安装)
- 配置编辑器(任意一种)
    - Android Studio：为Flutter提供完整的IDE体验
    - IntelliJ IDEA：安装插件Flutter、Dart
    - VS Code：安装Flutter插件
- 修改`%flutter_home%\packages\flutter_tools\gradle\flutter.gradle`为国内镜像。否则编译项目报错`Error running Gradle`

    ```js
    repositories {
        // google()
        // jcenter()
		maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/jcenter' }
        maven { url 'http://maven.aliyun.com/nexus/content/groups/public' }
    }
    ```
    - 如果仍然无法下载依赖，则修改项目目录的`android/build.gradle`文件，在`buildscript.repositories`和`allprojects.repositories`(建议也要配置一下)同上述一样修改。(出现于需要安装系统尚未安装的Android SDK版本)
- 真机调试
    - USB连接必须选择传输文件或者MTP(多媒体传输)
    - 手机设置开启USB调试
    - `flutter devices` 查看设备

### 运行(vscode)

- 命令行运行
    - 进入项目目录，`flutter run`即可，修改代码后在命令行`R`热加载
- debug运行
    - 打开`lib/main.dart`，点击`调试-启动调试`，此时会自动编译。期间会提示安装Dart Devtools插件(会自动在浏览器打开类似Vue Devtools的展示页面)
    - 或者进入调试界面，点击下拉，选择项目添加配置，此时会在项目中产生`.vscode/launch.json`文件(或者手动创建)。如下可创建多个调试(可同时启动)

        ```json
        {
            "version": "0.2.0",
            "configurations": [
                {
                    "name": "simple_material_app", // 调试名称
                    "program": "flutter-examples/simple_material_app/lib/main.dart", // 相对项目根目录调试入口文件
                    "request": "launch",
                    "type": "dart"
                },
                {
                    "name": "using_theme",
                    "program": "flutter-examples/using_theme/lib/main.dart",
                    "request": "launch",
                    "type": "dart"
                }
            ]
        }
        ```

### flutter 命令

```bash
flutter -h
# 检查flutter环境
flutter doctor

## 项目根目录执行
# 根据 pubspec.yaml 获取依赖包
flutter packages get
# 运行项目。r/R 重新加载(热加载)
flutter run
```

## 语法






