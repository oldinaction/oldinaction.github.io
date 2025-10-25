---
layout: "post"
title: "C++"
date: "2022-06-09 18:18"
categories: lang
tags: [C, C++, C#]
---

## 简介

- 2018年新版C/C++学习路线图 https://www.itcast.cn/news/20180514/17184715961.shtml
    - 缺失部分可参考黑马程序员 http://yun.itheima.com/map/25.html
- 尚学堂C++入门 day08?
    - 视频 https://edu.aliyun.com/course/477?spm=5176.8764728.aliyun-edu-course-tab.1.77b05bdehgZfhF&previewAs=guest&redirectStatus=0
    - 笔记 https://github.com/0voice/cpp_new_features/blob/main/C%2B%2B%20%E5%85%A5%E9%97%A8%E6%95%99%E7%A8%8B%EF%BC%8841%E8%AF%BE%E6%97%B6%EF%BC%89%20-%20%E9%98%BF%E9%87%8C%E4%BA%91%E5%A4%A7%E5%AD%A6.md
- C++参考手册 https://c-cpp.com/cpp

### Microsoft Visual Studio开发工具

- 安装: 通过`VisualStudioSetup.exe`选择需要按照的组件；安装完成后，如果需要增删组件库，也是运行此安装程序
- 版本说明: Visual Studio 2022对应版本简称为v143，2022下可能还有小版本如17.2、17.3等。安装组件库时需要选择正常的目标(x86、ARM等)、版本(v142、v143等)
- 关联文件: `.sln`(解决方案)
- 深色主题光标看不清: 控制面板 - 鼠标 - 设置鼠标 - 指针, 更改方案为Windows黑色

### NMAKE/GNUMake

- NMAKE和GNUMake大同小异，但是不能直接划等号，两者Makefile并不通用
- NMAKE是Visual Studio的内置工具之一，只负责执行Makefile中描述的编译链接步骤，本身并不具备编译或链接功能
- NMAKE运行环境
    - 安装完Visual Studio之后，并不是马上就能使用，还需配置PATH、INCLUDE、LIB三个环境变量
    - 需要进入要编译的项目目录
    - 然后手动调用调用"%YOUR_VS_PATH%\VC\Auxiliary\Build"中的以vcvars开头的批处理，如vcvarsamd64_x86.bat(主机64位，生成32位)。即在当前命令行配置上述3个环境变量
    - 在项目目录执行`nmake`

## MFC

- [MFC文档](https://docs.microsoft.com/zh-cn/cpp/mfc/mfc-desktop-applications)
    - [类介绍: MFC API 参考 - MFC类](https://docs.microsoft.com/zh-cn/cpp/mfc/reference/mfc-classes)
- MFC介绍
    - MFC微软基础类库的作用在Windows平台做GUI开发使用
    - MFC把Windows SDK API函数包装成几百个类，MFC给Windows操作系统提供面向对象的接口，支持可重用性、自包含性以及其他OPP原则。MFC通过编写类来封装窗口、对话框等其他对象
- MFC与QT
    - 都是C++的图形界面开发库
    - QT使用的编译器是MinGW，即Linux下的GCC移植到windows的版本；MFC使用的编译器是Visual C++
    - QT是跨平台的；MFC只能用Windows开发和运行(需要用到Windows API)
    - Qt提供了一个图形用户工具，`Qt Designer/Creator`，可以用来帮助建立用户界面
    - Qt在Unix上是可以免费获得其遵守GPL版权的版本，如果要开发不公开源代码的软件，必须购买Qt的授权；一旦购买了Visual Studio，即免费的获得MFC SDK授权
- Windows消息机制
    - Windows API函数是通过C实现的，主要在`windows.h`头文件中进行了声明
    - HANDLE(句柄): 是Windows程序的一个重要概念，在Windows程序中，有各种资源如窗口、图标、光标、画刷等
    - Windows程序设计是一种完全不同于传统DOS的程序设计方法，是一种事件驱动方式的程序设计模式，主要是基于消息的
    - WinMain函数: 是Windows程序的入口函数，与DOS程序的入口点函数main()的作用是相同的，WinMain()函数结束或返回时，Windows程序结束

### 类派生(继承)关系

- [MFC类层次结构图表](https://docs.microsoft.com/zh-cn/cpp/mfc/hierarchy-chart)
- CObject
    - CCmdTarget 
        - CWinThread
            - CWinApp
        - CWnd
            - CDialog
                - CDialogEx

### 类详细介绍

- `CWinApp` 创建 Windows 应用程序对象的基类
    - 继承自`CWinThread`
    - `InitInstance()` 重写；Windows实例初始化，例如创建(主)窗口对象。一般会将 `CWinThread::m_pMainWnd` 指向创建的窗口对象
- `CWnd` 包含所有窗口类的基本功能，如最小化窗口
    - `CloseWindow()` 最小化窗口
- `CDialog` 显示对话框的基类
    - `DoModal()` 打开对话框. 返回值: -1(创建对话框出错)/IDOK(点击确定来关闭对话框)/IDCANCEL(点击取消来关闭对话框)，如果不点击确定和取消则程序会阻塞直到有返回值

## QT

### 安装QT

```bash
# mac, 位置: /opt/homebrew/opt/qt@5
brew install qt@5
echo 'export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"' >> ~/.zshrc
# 默认安装qt6, 位置: /opt/homebrew/Cellar/qt/6.1.3
brew install qt

# 可选, Qt Designer/Creator, 下载地址(版本可根据自己需要选择)
# http://mirrors.ustc.edu.cn/qtproject/archive/qt/5.14/5.14.2/qt-opensource-mac-x64-5.14.2.dmg
```
- 使用(配置clion的CMakeLists.txt)

```bash
# test_qt为项目名
find_package(Qt5 COMPONENTS
        Core
        Gui
        Widgets
        REQUIRED)

add_executable(test_qt main.cpp)
target_link_libraries(test_qt
        Qt5::Core
        Qt5::Gui
        Qt5::Widgets
        )
```

## 框架

### mongoose

- [mongoose: 内嵌轻量级WebServer服务器](https://github.com/cesanta/mongoose)
    - 在程序中加入mongoose.h和mongoose.c文件即可(在c++中使用时刻将mongoose.c直接改成mongoose.cpp)
    - [Doc](https://mongoose.ws/tutorials)
- 代码举例(v7.7)

```c++
static void fn(struct mg_connection* c, int ev, void* ev_data, void* fn_data) {
    if (ev == MG_EV_HTTP_MSG) {
        struct mg_http_message* hm = (struct mg_http_message*)ev_data;
        if (mg_http_match_uri(hm, "/api/send_msg")) {
            char wxid[100], msg[1000];
            // mg_http_get_var 获取GET参数
            mg_http_get_var(&hm->query, "wxid", wxid, sizeof(wxid));
            mg_http_get_var(&hm->query, "msg", msg, sizeof(msg));
            wchar_t* wmsg = char2wchar(msg);
            send_msg(0, CString(wxid), CString(wmsg));
            mg_http_reply(c, 200, "", "OK\n", (int)hm->uri.len,
                hm->uri.ptr);
        }
    }
    (void)fn_data;
}

int hs_start_server(void) {
    struct mg_mgr mgr;                            // Event manager
    mg_log_set("2");                              // Set to 3 to enable debug
    mg_mgr_init(&mgr);                            // Initialise event manager
    mg_http_listen(&mgr, s_http_addr, fn, NULL);  // Create HTTP listener
    for (;;) mg_mgr_poll(&mgr, 1000);             // Infinite event loop
    mg_mgr_free(&mgr);
    return 0;
}
```

## 零散

- DLL入口函数`DllMain`，一般放在项目的`dllmain.cpp`中。当进程创建(DLL_PROCESS_ATTACH)/线程创建/进程结束(DLL_THREAD_DETACH)/线程结束时会调用
- `entern "C"` 用法: https://blog.51cto.com/sallencyxuan/1150888
- 约定`sz`开头的变量表示以0字符结尾的字符串(string terminated by 0 character)
