---
layout: "post"
title: "C#"
date: "2018-11-19 17:23"
categories: lang
tags: [.NET, C#]
---

## 简介

- [.NET](https://dotnet.microsoft.com/)
- [Microsoft Docs](https://docs.microsoft.com/zh-cn)、[.NET Docs](https://docs.microsoft.com/zh-cn/dotnet/)
- [.NET Download](https://dotnet.microsoft.com/download)
- .NET、C#、ASP.NET [^1]
    - 微软在2002年推出了`Visual Studio .NET` 1.0版本的开发者平台。微软还在2002年宣布推出一个特性强大并且与.NET平台无缝集成的编程语言，即`C#` 1.0正式版
        - `C#`(C sharp)就是为宣传`.NET`而创立的，它直接集成于`Visual Studio .NET`中，`VB`也在.NET 1.0发布后对其进行支持。只要是.NET支持的编程语言，开发者就可以通过.NET平台提供的工具服务和框架支持便捷的开发应用程序
        - 跨语言：即只要是面向`.NET`平台的编程语言(C#、Visual Basic、C++/CLI、Eiffel、F#、IronPython、IronRuby、PowerBuilder、Visual COBOL 以及 Windows PowerShell)，用其中一种语言编写的类型可以无缝地用在另一种语言编写的应用程序中的互操作性
    - `.NET` 实现包括 `.NET Framework`、`.NET Core` 和 `Mono`。 .NET 的所有实现都有一个名为 `.NET Standard` 的通用 API 规范。[版本对应](https://docs.microsoft.com/zh-cn/dotnet/standard/net-standard)
        - **`.NET Core` 是 .NET 的跨平台实现**，可在 Windows、macOS 和 Linux 上运行。JAVA和.NET不同的一点是java是跨平台的，不跨语言的
        - `.NET Framework` 是自 2002 年起就已存在的原始 .NET 实现，**因此经常将 `.NET Framework` 简称为 `.NET`**。当前 .NET 开发人员经常使用的 .NET Framework。**.NET Framework 4.5 版以及更高版本实现 .NET Standard**
        - `Mono` 是主要在需要小型运行时使用的 .NET 实现。 它是在 Android、Mac、iOS、tvOS 和 watchOS 上驱动 Xamarin 应用程序的运行时，且主要针对小内存占用。 Mono 还支持使用 Unity 引擎生成的游戏
        - `UWP` 是用于为物联网 (IoT) 生成新式触控 Windows 应用程序和软件的 .NET 实现
    - .NET框架的组成分为两部分
        - `CLR`(Common Language Runtime)：公共语言运行时，提供内在管理，代码安全性检测等功能。包含
            - `CLS`：公共语言规范，获取各种语言转换成统一的语法规范
            - `CTS`：通用类型系统，将各种语言中的数据类型转换成统一的类型
            - `JIT`：实时编译器，用于将转换之后的语言编译为二进制语言，交给CPU执行
        - `FLC`(.NET Framework Class Library)：.NET框架类库，提供大量应用类库
    - 运行机制
        - `.NET`：各种语言(c#、F#、j#等对应的源程序) —> 经过CLS、CTS第一次编译 —> 统一规范语言(中间语言)MSIL(.EXE,.DLL) —> JIT第二次编译 —> 二进制语言 —> 运行在CPU中
        - `Java`：Java —> 编译 —> 字节码文件(.CLASS) —> jvm解释(jvm虚拟机) —> 二进制语言 —> 运行在CPU中
    - `ASP.NET` 是一种用来快速创建动态Web网站的技术，是.NET框架中的一个应用模型，不是语言。可以用C#或VB.NET来开发，编译后形成CLR，通过服务器的IIS+.NET FrameWork再次编译来运行
    - .NET 分成两个方面：`WinForm`和`WebForm`，ASP.NET就是属于WebForm，也就是平时说的B/S模式的开发；而WinForm就是属于C/S模式
- 相关术语
    - CLR：公共语言运行时
    - 程序集(assembly)：.dll/.exe 文件，其中包含一组可由应用程序或其他程序集调用的 API。程序集可以包括接口、类、结构、枚举和委托等类型
- 常用开发工具`Microsoft Visual Studio`

### 概念说明

- VS解决方案A文件夹：A下的*.sln => eclipse的.project；A下的packages类似jar包；A下的项目文件夹(如：A)
- 添加引用 => 导入jar包；导入命名空间(using System) => 代码中的`import java.lang.System`
- `.sln`和`.csproj`区别：`.csproj`为一个c#项目/模块，里面配置有此项目/模块的引用路径；`.sln`则是对多个`.csproj`的描述

## Web

### VS创建Web应用程序(Hello World)

#### .NET Framework

- VS - 文件 - 新建 - 项目 - Visual C# - Web - ASP.NET Web应用程序(.NET Framework)。创建的项目目录说明
    - App_Data 操作数据库文件夹(存放数据库连接.mdf文件)
    - Controllers 控制类文件夹
    - Models 实体类文件夹
    - Views 前端页面文件夹
    - Web.config 项目配置文件
- VS中启动`IIS Express`(会调用系统iis程序启动单独进程)，会自动打开浏览器，稍等片刻会自动打开浏览器，如下图

    ![net-hello-world](/data/images/lang/net-hello-world.png)
- VS添加引用，类似添加jar包(需要停止项目)
    - 下载`dll`引用文件，如存放在`D:/work/dll`
    - VS - 解决方案管理器 - 当前项目 - 引用 - 右键添加引用 - 浏览 - 选择上述dll文件 - 确定 - 重新生成项目并启动
    - 之后此dll文件不能删除，删除后就会丢失引用
- 启动项目
    - 选中项目模块 - 右键 - 设为启动项目
    - 选中项目模块 - 右键 - 属性 - Web - 服务器 - 项目URL（如http://localhost:8080/） - 创建虚拟目录 - 去掉覆盖引用程序根URL
    - 然后修改项目目录下`.vs/MyModule/config/applicationhost.config`文件，配置`system.applicationHost#sites#site#bindingInformation="*:8080:localhost"`或`bindingInformation="*:8080:192.168.1.100"`对外访问

#### .NET Core

- [文档](https://docs.microsoft.com/zh-cn/aspnet/)
- 基于上文`.NET Framework`流程，亦可创建`ASP.NET Core Web应用程序`(ASP.NET Core 3.0)则可跨平台运行。可基于不同模板创建，如`Web应用程序(模型视图控制器，ASP.NET MVC)`或者`React.js`
- 打包发布
    - 生成 - 发布`WebApplication1` - 发布目标选择文件夹 - 创建文件夹 - 发布
    - 可在`D:\work\net\WebApplication1\WebApplication1\bin\Release\netcoreapp3.0\publish`项目发布目录看到生成的文件，其中`WebApplication1.exe`双击默认会开启一个cmd窗口
    - 然后可访问`http://localhost:5000`查看页面
- 部署到IIS
    - IIS默认不支持ASP.NET Core，需要安装`AspNetCoreModuleV2`模块，否则报500。在[官网下载中心](https://dotnet.microsoft.com/download/dotnet-core/3.0)进行[下载ASP.NET Core/.NET Core: Runtime & Hosting Bundle](https://download.visualstudio.microsoft.com/download/pr/bf608208-38aa-4a40-9b71-ae3b251e110a/bc1cecb14f75cc83dcd4bbc3309f7086/dotnet-hosting-3.0.0-win.exe)。此时下载的是
    - 下载后直接安装，在IIS-模块中可看到
    - IIS - 网站 - 添加网站。网站名称如`WebApplication1`，物理路径如`D:\work\net\WebApplication1\WebApplication1\bin\Release\netcoreapp3.0\publish`，输入端口9081
    - 然后可访问`http://localhost:9081`查看页面

##### 在Centos7上运行

> 参考：https://dotnet.microsoft.com/learn/aspnet/hello-world-tutorial/intro

```bash
## 安装
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo yum install -y dotnet-sdk-3.0 # 安装sdk(包含开发工具包)
# sudo yum install -y aspnetcore-runtime-3.0 # 安装运行时环境，可用于正式环境安装
dotnet --info

## 创建项目并运行
dotnet new webApp -o myWebApp --no-https
cd myWebApp
dotnet run # 在项目目录运行
# dotnet bin/Debug/netcoreapp3.0/myWebApp.dll # 或者直接指定dll文件进行运行(正式环境可操作)
# 默认监听在 http://localhost:5000
```

### IIS

- 开启windows的IIS：控制面板 - 程序和功能 - 打开或关闭Windows功能 - Internet信息服务(Internet Information Services) - 此时在开始菜单中会出现`Internet Information Services (IIS)管理器`
- 修改端口：网站 - 选择站点 - 绑定 - 修改端口
- IIS默认会占用80端口，如果nginx也需要使用80端口，则无法启动(如果nginx的server均没有80端口则可正常运行)
    - `netstat -ano | find "80"` 查看占用80端口的进程。如果是普通进程可直接kill，如果是System进程(PID=4)，可参看下述流程
    - 需要将IIS(程序中搜"Internet Information Services")的所有和80端口绑定的应用修改成其他端口
    - 再检查是否安装Sqlserver，其Reporting Service也会占用80端口(参考：https://www.jianshu.com/p/4b07e23414c2)
        - 可直接关闭服务 SQL Server Reporting Services (MSSQLSERVER)，并设置成手动启动
        - 或者停止服务实例：程序中搜索"Reporting Services 配置管理器" - 连接(相应实例) - 停止
        - 或者修改其绑定端口：连接进服务实例 - 报表管理器Url - 高级 - 编辑端口 - 确定后会自动重启报表Web服务
    - 最后可考虑是否重启IIS
        - 在管理员命令行运行`iisreset/stop`可停止IIS，开启使用`iisreset/start`
        - 服务里重启`World Wide Web Publishing Service`
- 右键某个网站-管理网站-高级设置-物理路径：可查看项目部署目录

### 使用Oracle

- 项目的`Web.config`增加配置

    ```xml
    <!-- data source为TNS Name名称 -->
    <connectionStrings>
        <add name="MyConnectionName1" connectionString="data source=local;user id=root;password=root;" />
        <add name="MyConnectionName2" connectionString="data source=local;user id=root;password=root;" />
    </connectionStrings>
    ```
- 需要启动TNS服务，并在tnsnames.ora中配置上述数据源
- 如果报错`The provider is not compatible with the version of Oracle client`需要确认`Oracle.DataAccess.dll`的版本是否和ODAC版本一致。右键`Oracle.DataAccess.dll`可查看其版本，如11.02.3，则需要`ODAC112030`版本（ODAC 4 112.3），参考[oracle-dba.md#ODAC和ODBC](/_posts/db/oracle-dba.md#ODAC和ODBC)

## 窗体应用(Winform)

- 开发窗体应用(`Winform`)：文件 - 新建 - windows 窗体应用

## 案例

### Hello world

```c#
static void Main(string[] args)
{

    Console.WriteLine ("{0} command line arguments were specified", args.Length);
    foreach (string arg in args)
    {
        Console.WriteLine(arg);
    }

    Console.ReadLine();
}
```

### 使用oracle数据库

```c#
static void Main(string[] args)
{
    try
    {
        string connString = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)));Persist Security Info=True;User ID=root;Password=root;";
        OracleConnection con = new OracleConnection(connString);
        con.Open();

        string cmdQuery = "select name, password from user where id = 1";

        // Create the OracleCommand
        OracleCommand cmd = new OracleCommand(cmdQuery);
        cmd.Connection = con;
        // cmd.CommandType = CommandType.Text;
        // Execute command, create OracleDataReader object
        OracleDataReader reader = cmd.ExecuteReader();

        while (reader.Read())
        {
            Console.WriteLine("Name : " + reader.GetString(0));
            Console.WriteLine("Password : " + reader.GetString(1));
        }
        Console.ReadKey();

        // Clean up
        reader.Dispose();
        cmd.Dispose();
        con.Dispose();
    }
    catch (Exception ex)
    {
        Console.WriteLine("出错!");
    }
}
```





---

参考文章

[^1]: https://www.cnblogs.com/yy1234/p/9258805.html
