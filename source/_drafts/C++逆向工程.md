---
layout: "post"
title: "C++逆向工程"
date: "2022-06-20 18:18"
categories: lang
tags: [C, C++, 安全]
---

## 零散

- [Windows 中的三种常用 DLL 注入技术](https://blog.csdn.net/langshanglibie/article/details/123853030)
- [远程线程注入](https://www.cnblogs.com/cunren/p/15176485.html)
- [使用Detours-setdll调试远程线程注入的dll](https://juejin.cn/post/7026212102175981575)
    - [源码](https://github.com/Cavan2477/DllInjectTest)
    - 说明: 调试只需要用到setdll.exe(源码中包含了)，也可以自己手动通过Detours源码编译
- PC微信逆向
    - WeTool(很多盗版网站. 如: https://wetools.pro/)
    - 鬼手逆向 https://github.com/TonyChen56/WeChatRobot
        - 使用HOOK拦截二维码：https://blog.csdn.net/qq_38474570/article/details/92798577
        - 发送与接收消息的分析与代码实现：https://blog.csdn.net/qq_38474570/article/details/93339861
        - 两种姿势教你解密数据库文件：https://blog.csdn.net/qq_38474570/article/details/96606530
    - 微信版本过低绕过方式
        - https://www.ez4leon.top/archives/skip-wechat-version-check 可以成功但是需要每次启动微信都修改
        - https://gitee.com/SHIKEAIXYY/Trss-ComWeChat-Yunzai/tree/dev#%E5%85%B3%E4%BA%8E%E4%BD%8E%E7%89%88%E6%9C%AC%E5%BE%AE%E4%BF%A1%E6%97%A0%E6%B3%95%E7%99%BB%E5%BD%95%E9%97%AE%E9%A2%98 可以成功但是需要每次启动微信都修改
- 工具
    - `OD (OllyDbg)` 反汇编软件，动态追踪工具
    - `CE (Cheat Engine)` 用于查找、修改内存数据，是游戏逆向的基础工具
        - [官网下载](https://www.cheatengine.org/downloads.php)、[CE修改器7.4汉化版](https://hqsfx.lanzouw.com/iyuqq07zlr0b)
    - `setdll.exe` 往进程中注入dll(上文提到源码中可下载，也可通过Detours源码编译)



