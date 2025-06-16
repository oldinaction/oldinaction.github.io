---
layout: "post"
title: "Windows"
date: "2017-05-10 15:26"
categories: [linux]
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

### 激活

- 基础知识
    - 镜像常见来源
        - MSDN: 主要是提供开发人员订阅测试的版本，并不是正式版本。(未内置GVLK秘钥，可通过命令安装秘钥)
        - VLSC: 拥有产品账号的客户可以从VLSC中心下载镜像。(如果是从VLSC下载VL版本已经内置GVLK秘钥，VL版本的镜像文件名是SW_DVD开头)
        - 微软官网提供的无需账号，开放下载的零售版镜像
    - 可是密钥分为好多种，KMS密钥、OEM密钥、GVLK密钥等
        - GVLK英文全称Generic Volume License Key，表示批量授权许可密钥。凡是使用KMS激活的windows系统还是Office，使用的都是GVLK密钥，密钥是由微软提供，KMS激活期限是180天期限
        - OEM密钥一般是oem厂商预装系统使用，OEM密钥是永久
    - 通用许可秘钥GVLK
        - [Windows通用许可秘钥GVLK](https://learn.microsoft.com/zh-cn/windows-server/get-started/kms-client-activation-keys)
        - [Office通用许可秘钥GVLK](https://learn.microsoft.com/zh-cn/DeployOffice/vlactivation/gvlks?redirectedfrom=MSDN)
    - KMS: Key Management Server密钥管理服务。这些是公司用来使用自己的激活服务器激活其批量许可软件的产品密钥。通过 KMS 激活不是永久性的。电脑必须定期(7天一次)访问公司的 KMS 服务器刷新激活，否则激活会过期(180天访问不到则过期)
    - KMS38: 支持离线。并不是属于微软的正常渠道的激活方式，最大激活到2038年(至于为什么是2038年？因为在有符号32位整数时间戳里面2038是最大值)
- [WIN10多种激活密钥让你傻傻分不清 一文看懂OEM、GVLK、KMS等密钥区别](https://www.cnblogs.com/hahajava/p/13609195.html)
- [KMS激活Windows/Office口袋指南](https://blog.03k.org/post/kms.html)
- 激活工具
    - [HEU KMS Activator](https://www.hezibuluo.com/7942.html)
- `slmgr` 软件授权管理工具

```bash
## win10激活(新建bat文件并运行)
# 设置KMS服务器地址 kms.03k.org可换成其他KMS服务器地址
slmgr /skms kms.03k.org
# 激活
slmgr /ato
```

### 永久关闭Windows自动更新

- https://blog.csdn.net/lihuiyun184291/article/details/125260468

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
- 基于创建bat脚本
    - 法一：参考下文`任务计划`(**成功**)
    - 法二：**将bat脚本的快捷方式放到启动目录**
        - 全局启动目录
            - 对应目录 `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp`(.../「开始」菜单/程序/启动)
        - 用户启动目录(**需要用户登录进去才开始自动重启**)
            - Win+R - `shell:startup` 打开对应目录
            - 或手动打开 `C:\Users\smalle\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`
    - 法三：基于bat和vb

        ```bash
        # 1.创建 start_my_app.bat
        java -jar my_app.jar
        # 2.创建 start_my_app.vb
        Set ws = CreateObject("Wscript.Shell")
        ws.run "cmd /c D:\test\start_my_app.bat",vbhide
        # 3.将start_my_app.vb文件放到 C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup 目录
        ```
- 基于组策略编辑器(**成功**)
    - Windows+R运行，输入`gpedit.msc`进入组策略编辑器 - 选中windows设置 - 双击脚本(启动/关机) - 添加 - 浏览 - 选择脚本 - 确定
- 基于注册表(**成功**，可解决策略编辑器、任务计划不成功的情况)
    - `regedit`打开注册表 - 搜索`Hkey_local_machine\software\wow6432node\microsoft\windows\currentversion\run` - 右键新建字符串值 - 名称可自定义，类型REG_SZ，值如`"C:\Program Files (x86)\Tencent\DeskGo\2.9.1051.127\DesktopMgr.exe" --cmd=autorun`
- 基于创建服务也可实现
    - 如使用[Windows Service Wrapper](https://github.com/kohsuke/winsw)工具注册服务，此处以nginx注册成服务为例
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

### 任务计划程序(定时任务)

- 运行栏输入`taskschd.msc`打开`计划任务工具/程序`
- 如创建开机启动任务
    - 任务计划程序库 - 选择用户 - 创建任务
        - 常规：任务名称`start-outlook`，描述`开机启动outlook`；勾选"不管用户是否登录都要运行"，可选"使用最高权限运行"
        - 触发器：新建 - 开始任务"启动时" - 确定
        - 操作：新建 - 启动程序 - 选择程序或脚本(如果安装了bash.exe，也可以执行sh脚本)
    - 运行exe程序的最好写成bat脚本运行。如nginx.exe写到bat脚本中去运行，然后任务中运行此脚本
- 创建定时任务
    - 打开任务计划程序程序后 - 创建基本任务 - 设置运行频率和脚本即可
- 更新任务时提示`一个或多个指定的参数无效`: 常规 - 安全选项 - 更改用户或组 - 高级 - 立即查找 - 选择当前管理员用户名后“确定”

### 共享文件夹

- 右键点击文件夹 - 共享 - 添加共享用户(选择 Everyone 表示允许局域网内的所有用户访问) - 设置共享权限
- 启用网络发现和文件共享: 控制面板 - 网络和 Internet
    - 设置网络为专用网络(当然其他网络也行)
    - 高级网络设置 - 高级共享设置 - 设置专用网络开启网络发现和共享 - 修改所有网络(关闭密码保护的共享)

### 远程桌面

- Win+R运行`mstsc`打开远程桌面
    - `mstsc -admin` 以管理模式进入远程桌面，可以解决`由于没有远程桌面授权服务器可以提供许可证`问题(或者修改目标服务器的注册表)

### 关闭安全中心通知

- Win+R运行`gpedit.msc` - “计算机配置”→“管理模板”→“Windows 组件”→“Windows 安全中心” - 通知 - 隐藏所有通知 - 改成“已启用”

### 文件管理器不显示边框

- Win+R运行`systempropertiesadvanced.exe`，性能设置 - 勾选"在窗口下显示阴影"

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

- `Navicat`
    - Navicat Premium 17破解: 安装后, 下载破解证书winmm.dll到安装路径, 管理员身份执行navicat.bat, 参考: https://blog.csdn.net/weixin_44491016/article/details/144092393
    - Navicat 15破解教程: https://www.cnblogs.com/poloyy/p/12231357.html
    - 使用手册: https://www.navicat.com.cn/support/online-manual
    - **快捷键**: https://www.navicat.com.cn/manual/online_manual/cn/navicat_16/mac_manual/#/hot_keys
        - `Ctrl + N` 新开查询窗口
        - `Ctrl + R` 执行
        - `Ctrl + /` 注释
        - `Ctrl + D` 从数据视图进入设计视图
- `Visio` 流程图。[Microsoft visio pro 2019 32位/64位](https://www.jb51.net/softs/634165.html#downintro2)
- `DBeaver` 数据库连接工具(开源免费，支持数据库丰富)
  - 驱动JAR下载(官网提供的下载地址无法访问)
    - 下载仓库`https://gitee.com/moshowgame/dbeaver-driver-all.git`中的jar
    - 编辑连接 - 编辑驱动设置 - 库 - 添加文件(夹) - 找到刚刚下载的git仓库中对应数据库文件夹(如drivers-mysql-mysql8-xxx.jar)
  - 连接Oracle
    - 基于SID连接(ORCL)，mac配置时客户端下拉可留空

## 软件使用

### ssh客户端(不好用)

> **使用cmder即可**

- 下载openssh: [https://github.com/PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
- 解压后将其根目录设置到Path中即可在cmd命令中使用ssh命令连接linux服务器

### ssh服务器

- Cygwin
- [OpenSSH](https://www.openssh.com/): Windows 10以上自带，也可自行安装. 包含了 ssh, scp, sftp; sshd, sftp-server, ssh-agent; ssh-add, ssh-keysign, ssh-keyscan, ssh-keygen 命令
    - 基于zip包安装
    - https://blog.csdn.net/nl9788/article/details/131653284
- WSL: Windows 子系统 for Linux, Windows 10以上自带
- [freeSSHd and freeFTPd](http://www.freesshd.com/)
- MobaXterm包含的ssh服务器
- [PowerShell Server](https://www.nsoftware.com/powershell/server/)，部分命令语法和cmd不同，详细查看
    - Service - Run as a Windows Service 作为服务运行则可自动启动(默认为普通程序运行)
    - Server Setting 设置端口和欢迎语
    - SFTP：尽管不勾选也是开启SFTP的，保险起见可勾选。修改SFTP根目录
    - Authentication 认证信息，默认是基于windows密码认证；可增加基于秘钥认证，勾选Enable Public Key，选择File Based Public Key Authentication对应保存公钥的认证文件authentication_keys(文件名无所谓，但是需要一行一个公钥)
    - Other：Write log to File记录日志到文件，Text Encoding为UTF-8(防止中文件名乱码)

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
            - Devel子目录: 默认情况下gcc并不会被安装，为了使我们安装的Cygwin能够编译程序，我们需要安装gcc编译器。选择安装`binutils`、`gcc-core`(编译C)、`gcc-g++`(编译c++)、`gdb`(GNU Debugger，可选择和gcc-core同一个大版本)、`mingw64-x86_64-gcc-core`(可选择和gcc-core同一个大版本)、`mingw64-x86_64-gcc-g++`
            - Web子目录: 勾选`wget`(当使用apt-cgy时需使用)
            - Net子目录: openssh
- 更新包/新增包
    - 重新执行安装包`setup-x86_64.exe`，下一步到选择新包，执行安装。不会丢失之前的数据
- 卸载
    - 重新执行安装包`setup-x86_64.exe`，选择Category展示，在All目录上选择Uninstall
    - 删除注册表`HKEY_CURRENT_USER/Software/Cygwin`和`HKEY_LOCAL_MACHINE/SOFTWARE/Cygwin`
    - 删除目录        

#### apt-cgy

- apt-cyg是Cygwin环境下的软件安装工具，相当于Ubuntu下的apt-get命令 [^2]
- [github主页](https://github.com/transcode-open/apt-cyg)
- 安装：从github上下载`apt-cyg`脚本文件，并将其放到`%CYGWIN_HOME%/bin`目录下，注意文件的换行符为Linux格式
- 启动Cygwin，运行`apt-cyg`检查是否安装成功
- `apt-cyg install openssh` 安装sshd服务

#### 常用包安装

> 可通过重新执行安装包`setup-x86_64.exe`，或执行`apt-cyg install openssh`进行安装(openssh为再界面上看到的包名)。查看包名：http://mirrors.aliyun.com/cygwin/x86_64/release/

- openssh(sshd服务器) [^3]
    - 安装Cygwin和openssh都无需重启服务器

```bash
# 安装. 或重新执行安装包`setup-x86_64.exe`找到Net目录
apt-cyg install openssh

# 管理员运行Cygwin64 Terminal, 然后执行命令进行配置: 基本都输入yes, 遇到`Enter the value of CYGWIN for thedaemon: []`直接回车即可
# (新版本貌似不需要, 直接使用Administrator登录即可)需要创建一个windows用户，根据提示创建后如：`User 'cyg_server' has been created with password 'root'.`
# 安装成功后，会在windows上安装sshd服务，服务名称为: CYGWIN cygsshd
ssh-host-config

# 启动sshd服务(使用`cyg_server`用户运行的此服务)，启动的为`%CYGWIN_HOME%/usr/sbin/sshd.exe`
cygrunsrv -S sshd

# 连接服务器, 有可能需要在客户端先执行一次`ssh-keygen -f "/home/smalle/.ssh/known_hosts" -R "192.168.1.1"`
ssh Administrator@192.168.1.1
```
    - 常见问题
        - 执行`ping`等命令返回乱码：如果是Cgywin客户端，则设置文本-编码为zh_CN/GBK；如果是xshell连接的，则设置xshell的编码为GBK
        - ls显示颜色：在`~/.bashrc`文件中加入`alias ls='ls --color --show-control-chars'`
        - 建立SSH隧道时，运行一段时间会出现客户端进行的连接会一直增多，且通过`netstat -ano | findstr "10010"` 查询打此通道上的PID，但是在任务管理器和tasklist都无法查询到此进程ID，如果需要重启服务职能将sshd/ssh相关的进程全部关闭，再重启sshd服务

### Outlook

- Outlook开机启动：参考上文将快捷方式加入到用户的启动目录
- 禁止退出：参考 https://www.cnblogs.com/beeone/p/10556609.html
- 最小化隐藏任务栏：右键图标 - 最小化隐藏
- Outlook可和Foxmail互导联系人

### 其他软件

- SpaceSniffer v1.1.2 空间占用检查
- [spacedesk](https://spacedesk.net/) 分屏软件(Windows和ipad分屏)
- [PilotEdit](https://www.pilotedit.com/) 大文件查看搜索编辑(10G免费)

## 服务器相关

- 添加可登录用户
    - 控制面板 - 用户账户 - 管理其他账户 - 添加账户(标准用户)
    - Win11等可使用`netplwiz`添加本地用户（默认是添加网络用户）
    - 设置标准用户可进行远程登录(默认只能管理员远程登录)
        - 控制面板 - 系统和安全 - 允许远程访问(系统属性-远程) - 选择用户 - 添加 - 输入对象名称后点击检查 - 确定即可
- 设置服务器可同时有多个远程桌面连接
    - https://blog.csdn.net/zhang0000dehai/article/details/124748863
    - 切换会话: 退出重新连接；或者任务管理器 - 用户 - 右键连接(可能需要输入密码)
    - 开启多个会话开机时，如果是一个用户，启动文件夹下的脚步会重复启动一次(像java这种会报端口冲突，问题不大，关掉窗口即可，下次连接不会产生)
- 设置文件管理器显示边框: https://jingyan.baidu.com/article/19192ad835356ea43f570712.html

### 软件安装

- Java
    - `JAVA_HOME=D:\soft\jdk1.8.0_202` `CLASSPATH=.;%JAVA_HOME%\lib\dt.jar;%JAVA_HOME%\lib\tools.jar;` `Path=;%JAVA_HOME%\bin`
- [Mysql镜像](https://mirrors.aliyun.com/mysql/MySQLInstaller/)
    - [mysql-installer-community-5.7.38.0.msi](http://mirrors.aliyun.com/mysql/MySQLInstaller/mysql-installer-community-5.7.38.0.msi)
    - [mysql-installer-community-8.0.29.0.msi](http://mirrors.aliyun.com/mysql/MySQLInstaller/mysql-installer-community-8.0.29.0.msi)



---

参考文章

[^1]: https://www.cnblogs.com/skyofbitbit/p/3706057.html
[^2]: https://blog.csdn.net/callinglove/article/details/39855305
[^3]: http://zsaber.com/blog/p/126
