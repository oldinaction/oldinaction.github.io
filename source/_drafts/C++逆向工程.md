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
    - 使用HOOK拦截二维码：https://blog.csdn.net/qq_38474570/article/details/92798577
    - 发送与接收消息的分析与代码实现：https://blog.csdn.net/qq_38474570/article/details/93339861
    - 两种姿势教你解密数据库文件：https://blog.csdn.net/qq_38474570/article/details/96606530
- 工具
    - `OD`
    - `setdll.exe` 往进程中注入dll(上文提到源码中可下载，也可通过Detours源码编译)



