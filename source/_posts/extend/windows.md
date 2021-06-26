---
layout: "post"
title: "Windows"
date: "2017-05-10 15:26"
categories: [extend]
tags: [bat]
---

## TODO

Windows 新增远程桌面会话连接数(可多人同时远程桌面，互不影响)：https://blog.csdn.net/chan_1030261721/article/details/80852121
通过代理使用远程桌面(Mstcs)：https://blog.csdn.net/stephenxu111/article/details/5685982


## 介绍

- windows版本号：https://docs.microsoft.com/zh-cn/windows/desktop/SysInfo/operating-system-version

    ```txt
    Windows 2000            5.0
    Windows XP	            5.1
    Windows Server 2003     5.2
    Windows Vista	        6.0
    Windows Server 2008	    6.0
    Windows 7	            6.1
    Windows Server 2012	    6.2
    Windows 8	            6.2
    ```
- win10激活(新建bat文件并运行)

    ```bash
    slmgr /skms kms.03k.org
    slmgr /ato
    ```

## 常用命令

- `ipconfig` 查看ip地址
- `ping 192.168.1.1`
- `telnet 192.168.1.1 8080`
- `netstat -ano | findstr 8080` 查看某个端口信息
- `tasklist | findstr "10000"` 查看进程ID信息
- `taskkill /F /pid "10000"` 结束此进程ID
- `sc delete 服务名` 卸载某服务（管理员运行）
- `arp -a` 查看局域网下所有机器mac地址
- 创建.开头文件或文件夹
  - `mkdir .ssh` 创建.开头文件夹
  - `type nul > .test` 创建.test文件
  - `echo hi > .npmignore` 创建.开头文件

## 常用技巧

### 开机启动Java等程序

- 自启动的程序可在任务管理器-启动列查看
- 基于创建服务也可实现。如使用[Windows Service Wrapper](https://github.com/kohsuke/winsw)工具注册服务，此处以nginx注册成服务为例
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
- 基于组策略编辑器(**成功**)
    - Windows+R运行，输入`gpedit.msc`进入组策略编辑器 - 选中windows设置 - 双击脚本(启动/关机) - 添加 - 浏览 - 选择脚本 - 确定
- 基于创建bat脚本
    - 法一：参考下文`任务计划`(**成功**)
    - 法二：将bat脚本的快捷方式放到启动目录
        - 用户启动目录：cmd - `shell:startup` 或手动 `C:\Users\smalle\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`
        - 全局启动目录：`C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp`(.../「开始」菜单/程序/启动)
    - 法三：基于bat和vb

        ```bash
        # 1.创建 start_my_app.bat
        java -jar my_app.jar
        # 2.创建 start_my_app.vb
        Set ws = CreateObject("Wscript.Shell")
        ws.run "cmd /c D:\test\start_my_app.bat",vbhide
        # 3.将start_my_app.vb文件放到 C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup 目录
        ```
- 基于注册表(**成功**，可解决策略编辑器、任务计划不成功的情况)
    - `regedit`打开注册表 - 搜索`Hkey_local_machine\software\wow6432node\microsoft\windows\currentversion\run` - 右键新建字符串值 - 名称可自定义，类型REG_SZ，值如`"C:\Program Files (x86)\Tencent\DeskGo\2.9.1051.127\DesktopMgr.exe" --cmd=autorun`

### 任务计划

- 运行栏输入`taskschd.msc`打开`计划任务工具`
- 如创建开机启动任务
    - 任务计划程序库 - 选择用户 - 创建任务
        - 常规：任务名称`start-outlook`，描述`开机启动outlook`
        - 触发器：新建 - 开始任务"启动时" - 确定
        - 操作：新建 - 启动程序 - 选择程序或脚本(如果安装了bash.exe，也可以执行sh脚本)
    - 运行exe程序的最好写成bat脚本运行。如nginx.exe写到bat脚本中去运行，然后任务中运行此脚本

## bat脚本

- 参考[bat脚本：http://blog.aezo.cn/2017/05/10/lang/bat/](/_posts/lang/bat.md)

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

## 软件下载推荐

- `Navicat` Navicat 15破解教程：https://www.cnblogs.com/poloyy/p/12231357.html
- `Visio` 流程图。[Microsoft visio pro 2019 32位/64位](https://www.jb51.net/softs/634165.html#downintro2)
- `DBeaver` 数据库连接工具(开源免费，支持数据库丰富)
  - 驱动JAR下载(官网提供的下载地址无法访问)
    - 下载仓库`https://gitee.com/moshowgame/dbeaver-driver-all`中的jar
    - 编辑连接 - 编辑驱动设置 - 添加文件夹 - 找到刚刚下载的git仓库中对应数据库文件夹

## 软件使用

### ssh客户端(不好用)

> **使用cmder即可**

- 下载openssh: [https://github.com/PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
- 解压后将其根目录设置到Path中即可在cmd命令中使用ssh命令连接linux服务器

### ssh服务器

- Cygwin
- [PowerShell Server](https://www.nsoftware.com/powershell/server/)，部分命令语法和cmd不同，详细查看
    - Service - Run as a Windows Service 作为服务运行则可自动启动(默认为普通程序运行)
    - Server Setting 设置端口和欢迎语
    - SFTP：尽管不勾选也是开启SFTP的，保险起见可勾选。修改SFTP根目录
    - Authentication 认证信息，默认是基于windows密码认证；可增加基于秘钥认证，勾选Enable Public Key，选择File Based Public Key Authentication对应保存公钥的认证文件authentication_keys(文件名无所谓，但是需要一行一个公钥)
    - Other：Write log to File记录日志到文件，Text Encoding为UTF-8(防止中文件名乱码)
- [freeSSHd and freeFTPd](http://www.freesshd.com/)
- MobaXterm包含的ssh服务器
- openssh

### Cygwin

- 简介：Cygwin是一个在windows平台上运行的类UNIX模拟环境。即包含bash命令行，且可安装openssh(提供sshd服务)等包提供相应服务

#### 安装

- [安装包setup-x86_64.exe](http://www.cygwin.com/setup-x86_64.exe)
- 安装 [^1]
    - 安装目录如`D:/software/cygwin`(unix可访问的根目录，此目录下的home子目录为用户目录)，Local package目录如`D:/software/cygwin/repo`
    - 设置包下载镜像地址`http://mirrors.aliyun.com/cygwin/`(点击Add添加)
    - 包安装自定义界面
        - View：Category基于目录展示包、Picked自定安装的包、UpToDate可更新的包；Search可查询包；Best默认的包版本
        - 列表展示：Package包名、Current当前安装的版本(未安装为空)、New中Skip表示跳过安装(如需要可下拉选择一个最稳当的版本进行安装)、Bin下载可执行文件、Src下载源码
        - 一般基于Category查看包，无特殊要求可直接下一步
            - 默认情况下gcc并不会被安装，为了使我们安装的Cygwin能够编译程序，我们需要安装gcc编译器，一般在Devel分目录下。选择安装`binutils`、`gcc-core`(编译C)、`gcc-g++`(编译c++)、`gdb`(GNU Debugger，可选择和gcc-core同一个大版本)、`mingw64-x86_64-gcc-core`(可选择和gcc-core同一个大版本)、`mingw64-x86_64-gcc-g++`
            - Web子目录中勾选`wget`(当使用apt-cgy时需使用)
- 更新包/新增包
    - 重新执行安装包`setup-x86_64.exe`，下一步到选择新包，执行安装。不会丢失之前的数据
- 卸载
    - 重新执行安装包`setup-x86_64.exe`，选择Category展示，在All目录上选择Uninstall
    - 删除注册表`HKEY_CURRENT_USER/Software/Cygwin`和`HKEY_LOCAL_MACHINE/SOFTWARE/Cygwin`
    - 删除目录        

#### apt-cgy

- apt-cyg是Cygwin环境下的软件安装工具，相当于Ubuntu下的apt-get命令 [^2]
- [github主页](https://github.com/transcode-open/apt-cyg)
- 安装：从github上下载`apt-cyg`脚本文件，并将其放到`%CYGWIN_HOME%/bin`目录下
- 启动Cygwin，运行`apt-cyg`检查是否安装成功
- `apt-cyg install openssh` 安装sshd服务

#### 常用包安装

> 可通过重新执行安装包`setup-x86_64.exe`，或执行`apt-cyg install openssh`进行安装(openssh为再界面上看到的包名)。查看包名：http://mirrors.aliyun.com/cygwin/x86_64/release/

- openssh(sshd服务器) [^3]
    - `apt-cyg install openssh` 安装
    - `ssh-host-config` 配置(会在windows上安装sshd服务；需要创建一个windows用户，根据提示创建后如：`User 'cyg_server' has been created with password 'root'.`)
    - `cygrunsrv -S sshd` 启动sshd服务(使用`cyg_server`用户运行的此服务)，启动的为`%CYGWIN_HOME%/usr/sbin/sshd.exe`
    - 连接服务器`ssh 192.168.1.1`，有可能需要在客户端先执行一次`ssh-keygen -f "/home/smalle/.ssh/known_hosts" -R "192.168.1.1"`
    - 常见问题
        - 执行`ping`等命令返回乱码：如果是Cgywin客户端，则设置文本-编码为zh_CN/GBK；如果是xshell连接的，则设置xshell的编码为GBK
        - ls显示颜色：在`~/.bashrc`文件中加入`alias ls='ls --color --show-control-chars'`
        - 建立SSH隧道时，运行一段时间会出现客户端进行的连接会一直增多，且通过`netstat -ano | findstr "10010"` 查询打此通道上的PID，但是在任务管理器和tasklist都无法查询到此进程ID，如果需要重启服务职能将sshd/ssh相关的进程全部关闭，再重启sshd服务

### Outlook

- Outlook开机启动：参考上文将快捷方式加入到用户的启动目录
- 禁止退出：参考 https://www.cnblogs.com/beeone/p/10556609.html
- 最小化隐藏任务栏：右键图标 - 最小化隐藏
- Outlook可和Foxmail互导联系人

### Wireshark抓包

- 如果是公网抓包，一般需要选择监听类似以太网的网卡
- 常用表达式
    - `ip.src == 192.168.1.100 && ip.dst == 114.114.114.114` 监听本机发送给114.114.114.114的包
    - `(ip.src == 192.168.1.100 && ip.dst == 114.114.114.114) || (ip.src == 114.114.114.114 && ip.dst == 192.168.1.100)` 监听本机发送和收到的114.114.114.114的包
    - `ip.src == 192.168.1.100 && tcp.dstport == 80` 监听本机发送给服务器80端口的包
- 表达式字典
    - 点击表达式输入框右侧的"表达式"按钮可显示所有支持的表达式（已经分好类）
    - 常用的如`IPv4`、`HTTP2`、`TCP`、`UDP`、`ICMP`等。如搜索IPv4或ip.src和定位到相关表达式，右侧会显示此表达式支持的关系类型(==、!=、in、contains等)

### 其他软件

- SpaceSniffer v1.1.2 空间占用检查
- [spacedesk](https://spacedesk.net/) 分屏软件(Windows和ipad分屏)


---

参考文章

[^1]: https://www.cnblogs.com/skyofbitbit/p/3706057.html
[^2]: https://blog.csdn.net/callinglove/article/details/39855305
[^3]: http://zsaber.com/blog/p/126
