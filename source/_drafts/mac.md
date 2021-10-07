---
layout: "post"
title: "Mac"
date: "2021-08-30 16:11"
categories: extend
tags: [system]
---

## 简介

- 版本：Mac M1 11.4

## 快捷键

```bash
cmd+c # 复制
cmd+v # 粘贴
cmd+opt+v # 剪贴(相当于剪切文件，需先复制)

cmd+opt+c # 复制文件夹绝对路径

# 组合按键
delete: cmd+删除键
insert: ESC -> i # 按一下ESC键，随后 i 代表
replace: ESC -> r
home: fn＋左
end: fn＋右
```

## 个性化配置

- 终端文件夹颜色：基于别名完成，在`~/.zshrc`中加入

```bash
#alias cls='tput reset'
#alias egrep='egrep -G'
#alias fgrep='fgrep -G'
#alias grep='grep -G'
alias l.='ls -d .*'
alias ll='ls -l -G'
alias ls='ls -G'
alias vi='vim'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'
```

## 常用软件安装

### brew

- 安装[brew](https://brew.sh/)包管理工具

```bash
# 安装(FQ下载速度会快些)
bash -c "$(curl -fsSL https://sourcegraph.com/github.com/Homebrew/install@master/-/raw/install.sh)"
# 安装完后会生成如下两条命令
# 加入到用户配置文件，每次用户登录，使/opt/homebrew/bin生效
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
# eval "$(/opt/homebrew/bin/brew shellenv)" # 直接时/opt/homebrew/bin在当前命令行生效

# 更换镜像，参考：https://www.cnblogs.com/trotl/p/11862796.html
cd "$(brew --repo)"
git remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
git remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-core.git
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles' >> ~/.zshrc
source ~/.zshrc
# 解决brew安装包一直卡在Updating Homebrew
echo 'export HOMEBREW_NO_AUTO_UPDATE=true' >> ~/.zprofile
source ~/.zprofile

# brew 使用
brew version
brew install wget
brew uninstall wget
```

### VPN(PPTP)

- https://vladtalks.tech/vpn/setup-pptp-vpn-on-mac

## 开发软件安装

### JAVA

- 到Oracle官网下载dmg格式文件进行安装，可安装多个版本
- `/usr/libexec/java_home -V` 查看可用的JDK版本
- 安装完后删除`/Library/Internet Plug-Ins/JavaAppletPlugin.plugin`目录
    - 如`sudo mv /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin.bak`
    - 否则mvn命令执行时报错，参考：https://blog.csdn.net/w605283073/article/details/111770386

### IDEA

- 插件目录 `/Users/smalle/Library/Application\ Support/JetBrains/IntelliJIdea2021.2/plugins`

### NVM/Node

- 安装Node(基于nvm)

```bash
# 安装nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash
# 但是安装node v10.x失败，v12.x成功；**但是从node官网下载node v10.24.1安装成功**
nvm install 16.8.0

# 卸载nvm，并删除.bash_profile文件中得$NVM_HOME配置
rm -rf ~/.nvm
```
- 安装vue-cli，使用root账号安装`npm install -g @vue/cli`
- 常见问题
    - 在npm install进行包依赖安装是，部分包需要依赖autoreconf命令，从而提示`/bin/sh: autoreconf: command not found`。此时可通过`brew install autoconf automake libtool`先手动安装autoreconf，并将`PATH="/opt/homebrew/opt/libtool/libexec/gnubin:$PATH"`添加到`~/.zshrc`

### 终端管理(Item2)

- 终端管理相关软件
    - 目前发现 Item2 还算比较理想
    - mac不支持xshell
    - FinalShell、Termius 不太好用
- Item2下载(v3.4.9)：[https://iterm2.com/](https://iterm2.com/)
- 创建一个服务器Session
    - 复制一个`Profile`(可立即为一个服务器Session配置)
    - 创建文件，如`/Users/smalle/data/item2/login-aezo-ss.exp`

        ```bash
        #!/usr/bin/expect

        set timeout 30
        spawn ssh -p [lindex $argv 0] [lindex $argv 1]@[lindex $argv 2]
        expect {
            "(yes/no)?"
            {send "yes\n";exp_continue}
            "password:"
            {send "[lindex $argv 3]\n"}
        }
        interact
        ```
    - 设置文件为可执行`chmod +x /Users/smalle/data/item2/login.exp`
    - Profiles - Open Profiles - Edit Profiles - General - Command(并选择Command) - 输入`/Users/smalle/data/item2/login.exp 22 root 192.168.1.100 mypass`
    - Profiles - 双击对应Profile即可登录服务器
- 快捷键
    - 更多参考：https://www.jianshu.com/p/a0249778872e
    - 在 Finder 中打开当前目录 `open .`
    - 按住 ⌘ 键
        - 可以拖拽选中的字符串
        - 点击 url：调用默认浏览器访问该网址
        - 点击文件：调用默认程序打开文件
        - 点击文件夹：在 finder 中打开该文件夹
        - 同时按住 option 键，可以以矩形选中，类似于 vim 中的 ctrl v 操作
    - 呼出粘贴历史 `Command + Shift + h`
    - 将文本内容复制到剪切板 `pbcopy < text.md`
- 热键悬浮窗口
    - 创建一个Profile
    - Keys - Configure Hotkey Window 
        - Hotkey(如设置cmd+g): 用于打开和关闭悬浮窗口
        - Floating window: 勾选后，悬浮窗口会显示在屏幕最前面
- 使用 shell integration
    - iTerm2 可以与 unix shell 集成在一起，在安装了 iTerm2 的 shell 集成工具后，可以在 iTerm2 中看到命令历史、当前工作目录、主机名、上传下载文件等

```bash
## 安装 item2 shell integration，会往 .zshrc 文件中增加一行代码
# 在安装完 iTerm2 的 shell integration 后会在终端界面中最左侧多出一个蓝色三角形的标记
# 如需关闭标记，可以在 iTerm2 > Preferences > Profiles > (your profile) > Terminal 最下面 > Shell Integration 关闭 Show mark indicators
curl -L https://iterm2.com/misc/install_shell_integration.sh | zsh

## shell integration 支持的工具参考：https://iterm2.com/documentation-utilities.html，下载地址均为 https://iterm2.com/utilities/xxx
# 安装 it2copy: 复制文本到剪贴板(需开启 Prefs > General > Selection > Applications in terminal may access clipboard 配置)
curl "https://iterm2.com/utilities/it2copy" > it2copy
sudo chmod +x it2copy && sudo mv it2copy /usr/local/bin
# 使用
it2copy file.txt
cat file.txt | it2copy

# 安装 it2ul: 上传文件
curl "https://iterm2.com/utilities/it2ul" > it2ul
sudo chmod +x it2ul && sudo mv it2ul /usr/local/bin

# 安装 it2dl: 下载文件
curl "https://iterm2.com/utilities/it2dl" > it2dl
sudo chmod +x it2dl && sudo mv it2dl /usr/local/bin
```
- 设置代理，加速访问github等

```bash
# vi ~/.zshrc
# 编辑好文件后，重新打开item2 Tab，执行setproxy开启代理。可使用`curl cip.cc`测试当前IP地址
alias proxy="export ALL_PROXY=socks5://127.0.0.1:1088"
alias unproxy="unset ALL_PROXY"
```
- 配色方案：https://iterm2colorschemes.com/
- 防止长时间不用断线问题：在`~/.ssh/config`(可能需要新建)中加入`ServerAliveInterval 60`
- [Scripts使用](https://iterm2.com/python-api/tutorial/index.html)
    - 菜单说明
        - New Python Scripts
            - Basic(只能基于python官方库和item2库写脚本),Full(创建一个python虚拟环境)
            - Simple(命令型)、Long-Running Daemon(后台一直运行)
        - Open Python REPL(打开python命令行)
        - Reveal Scripts in Finder(在Finder中显示脚本文件)
        - Console 脚本执行日志控制台
    - 简单使用, API参考：https://iterm2.com/python-api/index.html

        ```py
        #!/usr/bin/env python3.7

        import iterm2

        async def main(connection):
            app = await iterm2.async_get_app(connection)
            window = app.current_terminal_window
            # 执行命令(开启SOCKS隧道)
            await window.async_create(connection, command='ssh -D 0.0.0.0:1088 root@8.12.12.149 "vmstat 30"')

        iterm2.run_until_complete(main)
        ```

### Jad-GUI

- jad-gui打开报错需要按照jdk 1.8+，解决办法参考：https://blog.csdn.net/lei182/article/details/111914142

### Jenv(Java多版本管理工具)

- 参考：https://blog.csdn.net/aigestudio/article/details/99641818
- 使用

```bash
brew install jenv
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(jenv init -)"' >> ~/.zshrc
# 查看可用的JDK路径（需提前手动安装，jenv只能切换版本，不能进行安装），安装JDK参考上文[JAVA](#JAVA)
/usr/libexec/java_home -V
# 将可用的JDK加入到jenv中管理
jenv add /Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home
jenv add /Library/Java/JavaVirtualMachines/jdk1.7.0_80.jdk/Contents/Home
# 查看jenv管理的jdk版本
jenv versions
# 全局切换版本，还支持：shell/local/global
# shell 用于设置终端窗口生命周期内使用的 JDK 版本
# local 用于设置当前目录下使用的 JDK 版本
# global 用于设置全局使用的 JDK 版本
jenv global 1.8
```

### CrossOver

- CrossOver 20.0.4支持OSX 11.x上运行Windows应用，但是收费

### wine

- `wine` 已经不支持 OSX 11.x(由于OSX不再支持32bit程序)
    - 有说可使用`https://hub.fastgit.org/Gcenx/WineskinServer`解决(没成功)
    - 可使用CrossOver代替
- wine依赖`XQuartz`，就是俗称的X11，是苹果电脑为Mac OS X上X Window系统的实作

```bash
# 参考：https://wiki.winehq.org/MacOS
# 需先安装xquartz, 下载 https://www.xquartz.org/
# 下载winehq pkg包：https://dl.winehq.org/wine-builds/macosx/download.html
```

## 相关限制

- 不支持修改`/etc/profile`等配置，可修改`~/.zprofile`或`~/.bash_profile`代替。类似的文件`.zshrc`
- 不支持向`/usr/bin`目录添加文件，可向`/usr/local/bin`目录添加来实现直接运行程序目的
