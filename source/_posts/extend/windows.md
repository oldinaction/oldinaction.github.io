---
layout: "post"
title: "windows"
date: "2017-05-10 15:26"
categories: [extend]
tags: [bat]
---

## 常用命令

- `ipconfig` 查看ip地址
- `arp -a` 查看局域网下所有机器mac地址
- `ping 192.168.1.1`
- `telnet 192.168.1.1 8080`

## 常用技巧

- 开机启动java等程序
    - 基于创建服务也可实现。如使用[Windows Service Wrapper](https://github.com/kohsuke/winsw)工具注册服务，此处已nginx注册成服务为例
        - 下载`WinSW.NET4.exe`，放到nginx安装目录，并重命名为`nginx-service.exe`
        - 在nginx安装目录新建WinSW配置文件`nginx-service.xml`(需要和nginx-service.exe保持一致)，如下

            ```xml
            <service>
            <id>nginx</id>
            <name>nginx service</name>
            <description>nginx service made by WinSW.NET4</description>
            <logpath>D:/software/nginx-1.14.0/</logpath>
            <logmode>roll</logmode>
            <depend></depend>
            <executable>D:/software/nginx-1.14.0/nginx.exe</executable>
            <stopexecutable>D:/software/nginx-1.14.0/nginx.exe -s stop</stopexecutable>
            </service>
            ```
        - 管理员模式执行 `nginx-service.exe install` 进行nginx服务注册
        - `nginx-service.exe uninstall` 卸载nginx服务
    - 基于创建bat脚本
        - 法一：将bat脚本的快捷方式放到启动目录
            - 全局启动目录：`C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp`(.../「开始」菜单/程序/启动)
            - 用户启动目录：`C:\Users\smalle\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`
        - 法二：运行栏输入`taskschd.msc`打开`计划任务工具`，这里可以创建`基本任务`，有开机启动执行程序等选项可以设置
            - 运行exe程序的最好写成bat脚本运行。如nginx.exe写到bat脚本中去运行，然后任务中运行此脚本
## bat脚本

参考[bat脚本：http://blog.aezo.cn/2017/05/10/lang/bat/](/_posts/lang/bat.md)

## 破解反编译

- [反编译工具参考](https://tools.pediy.com/win/decompilers.htm)、[常用EXE文件反编译工具](http://www.cnblogs.com/ejiyuan/archive/2009/09/08/1562624.html)
- exe反编译工具(不同的语言打包出的exe可使用的反编译工具一般不同)
    - `PE Explorer` 文件 - 打开exe文件 - Resource View/Editor进行查看编辑资源
        - 如果文字中都是一些和exe无关的。如flash加壳后用此工具打开都是flash相关的文字，此时可以考虑去壳后通过flash反编译工具
    - `Resource Hacker` exe资源(图标/文字等)修改
    - `ILSpy` 可反编译C#生成的exe文件
- exe去壳工具
    - 将exe重命名rar格式，如果可正常打开说明有壳，如果打开报错可使用其他工具深入检测
    - `PEiD` (曾遇到swf格式加壳没检测出来)
- flash相关
    - [ffdec](https://www.free-decompiler.com/flash/download/)：开源的flash反编译工具。将swf反编译成fla格式的源码，再通过[AdobeFlashCS6绿色版](http://big.wy119.com/AdobeFlashCS6_gr.zip)修改后重新编译
    - 硕思闪客精灵(Sothink SWF Decompiler)：需要收费，免费试用部分功能30天。可将exe格式的flash文件转成swf格式


## 其他

### ssh客户端(不好用)

> **使用cmder即可**

- 下载openssh: [https://github.com/PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
- 解压后将其根目录设置到Path中即可在cmd命令中使用ssh命令连接linux服务器