---
layout: "post"
title: "Mac"
date: "2021-08-30 16:11"
categories: linux
tags: [system]
---

## 简介

- 版本：Mac M1 11.4
- Mac软件下载
    - https://macwk.cn/
    - https://www.macapp.so/ 收费
    - https://xclient.info/
    - https://www.mfpud.com/
    - https://iosmacapps.com/ 老外
    - https://appstorrent.ru/ 俄罗斯
    - https://foxirj.com/
    - https://www.macbl.com/
    - ~~ https://www.macwk.com/ ~~ 应用闪退问题解决如下
        - https://www.macwk.com/article/apple-silicon-m1-application-crash-repair
        - https://www.macwk.com/article/macos-beta-damage

## M1模拟x86环境

- Mac M1(默认只能执行arm结构)执行x86(Intel)程序，可基于Rosetta，参考下文安装多版本brew
- 参考: https://notemi.cn/installing-python-on-mac-m1-pyenv.html
- 参考上文安装完后设置命令别名(brew和pyenv可选)

```bash
vi ~/.zshrc

## ===arm(m1) or x86(intel) ===
# switch arch zsh: mzsh 和 xzsh，输入别名及切换环境，而不需要切换终端
alias mzsh="arch -arm64 zsh"
alias xzsh="arch -x86_64 zsh"
if [ "$(uname -p)" = "i386" ]; then
  echo "zsh Running in i386(x86) mode (Rosetta). use 'xzsh' switch to i386(x86), use 'mzsh' switch to ARM(M1)"
  eval "$(/usr/local/bin/brew shellenv)"
  alias brew='arch -x86_64 /usr/local/bin/brew'
  alias pyenv='arch -x86_64 /usr/local/bin/pyenv'
else
  echo "zsh Running in ARM mode (M1). use 'xzsh' switch to i386(x86), use 'mzsh' switch to ARM(M1)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  alias brew='/opt/homebrew/bin/brew'
  alias pyenv='$HOME/.pyenv/bin/pyenv'
fi
# x86版本
alias xpyenv='arch -x86_64 /usr/local/bin/pyenv'
alias xbrew="/usr/local/bin/brew"
# arm版本
alias mpyenv='$HOME/.pyenv/bin/pyenv'
alias mbrew="/opt/homebrew/bin/brew"
## ===arm(m1) or x86(intel) ===
```

## 快捷键

```bash
cmd+c # 复制
cmd+v # 粘贴
cmd+opt+c # 复制文件夹绝对路径
cmd+opt+v # 剪贴(相当于剪切文件，需先复制)

cmd+shift+. # 在 Finder 中显示隐藏文件
cmd+shift+g # 在 Finder 中前往目标目录，打开后不能Cmd+v粘贴，需要右键粘贴

# 组合按键
delete: cmd+删除键
insert: ESC -> i # 按一下ESC键，随后 i 代表
replace: ESC -> r
home: fn＋左
end: fn＋右
```

## 命令

- `open /root` 在Finder中打开某个目录(默认有些目录时不会显示在Finder中的)
- `lsof -i -P | grep 21` 查看端口占用情况，或`lsof -i :21`(类似netstat查找端口功能)

## 个性化配置

- 终端文件夹颜色：基于别名完成，在`~/.bash_profile`中加入，然后设置`echo 'source ~/.bash_profile' >> ~/.zshrc`让每次打开终端都生效

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

- Keka 压缩/解压工具
- Easy New File 快捷创建新的文件和文件夹
- OmniPlayer Pro 视频播放器
- NeatDownloadManager 下载管理器，类似IDM
- Royal TSX 类似xshell/xftp，类似参考下文
- JD-GUI Java反编译工具
- Proxifier 代理工具(类似windows SocksCap小红帽)

## 开发软件安装

### brew

#### brew安装

- 安装[brew](https://brew.sh/)包管理工具
- 更换镜像

```bash
## 更换镜像(arm和x86模式需要分别设置)，参考：https://www.cnblogs.com/trotl/p/11862796.html
cd "$(brew --repo)"
git remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
git remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-core.git
cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git

# 替换homebrew-bottles
# echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles' >> ~/.bash_profile
# source ~/.bash_profile

# 解决brew安装包一直卡在Updating Homebrew
echo 'export HOMEBREW_NO_AUTO_UPDATE=true' >> ~/.bash_profile
source ~/.bash_profile
```
- arm和x86模式安装

```bash
## arm(M1)安装v3.2.11
# 安装位置 /opt/homebrew, 安装的包位置 /opt/homebrew/opt, 配置文件位置 /etc
# (需要命令行设置代理FQ下载速度会快些，可能需要多试几次)
bash -c "$(curl -fsSL https://sourcegraph.com/github.com/Homebrew/install@master/-/raw/install.sh)"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
# 安装完后会生成如下两条命令
# 加入到用户配置文件，每次用户登录，使/opt/homebrew/bin生效
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
source ~/.bash_profile
# eval "$(/opt/homebrew/bin/brew shellenv)" # 直接时/opt/homebrew/bin在当前命令行生效


## x86(Inter)安装v3.6.21
# 安装位置 /usr/local/Homebrew, 安装的包位置 /usr/local/Cellar, 配置文件位置 /usr/local/etc
# 前期准备工作参考: https://towardsdatascience.com/how-to-use-manage-multiple-python-versions-on-an-apple-silicon-m1-mac-d69ee6ed0250
# 安装Rosetta: https://www.bilibili.com/read/cv14826978
softwareupdate --install-rosetta
# 然后复制一个item2出来并重命名为item2 Rosetta，打开简介，勾选使用Rosetta打开；之后使用item2 Rosetta执行的命令就是模拟x86环境，或者使用普通item2在执行命令前加`arch -x86_64`，如`arch -x86_64 bash -c ...`
# 打开item2 Rosetta并执行安装
bash -c "$(curl -fsSL https://sourcegraph.com/github.com/Homebrew/install@master/-/raw/install.sh)"
# 为 x86 的 Homebrew 设定 alias
# vi ~/.bash_profile 增加下列代码
alias xbrew='arch -x86_64 /usr/local/bin/brew'
# 生效
source ~/.bash_profile
```

#### brew使用

```bash
## brew 使用
brew -v
brew update  # 升级brew
brew upgrade # 升级所有包(也可单独指定)
brew install wget
brew uninstall wget
# 安装指定版本
brew search gcc
brew install gcc@7

# brew services(第一次运行会自动安装)
brew services list  # 查看使用brew安装的服务列表
brew services run nginx|--all  # 启动服务（仅启动不注册）
brew services start nginx|--all  # 启动服务，并注册
brew services stop nginx|--all   # 停止服务，并取消注册
brew services restart nginx|--all  # 重启服务，并注册
brew services cleanup  # 清除已卸载应用的无用的配置

# 查看nginx服务信息(包括启动脚本、配置文件)
brew info nginx
```

#### brew安装常用软件

```bash
# brew安装nginx仅稳定版，如果需要安装其他版本可基于docker运行
# 安装目录：/opt/homebrew/opt/nginx
# 配置文件目录：/opt/homebrew/etc/nginx/nginx.conf
brew install nginx

# 核心工具命令，如：numfmt
brew install coreutils

# c++ qt框架
brew install qt

# 生成目录树命令(windows可直接使用)
brew install tree
# -L打印层级；mac上tree命令不支持忽略多个文件夹，多个需配合grep使用；默认不会打印影藏的文件和目录
tree -L 3 -I "node_modules" | grep -v -e "dist"

# 配置文件路径如`/opt/homebrew/etc/redis.conf`
brew install redis

# rabbitmq
brew install rabbitmq
brew services restart rabbitmq # 后台启动
CONF_ENV_FILE="/opt/homebrew/etc/rabbitmq/rabbitmq-env.conf" /opt/homebrew/opt/rabbitmq/sbin/rabbitmq-server # 命令行启动
# 管理端 http://localhost:15672 guest/guest
```

### VPN(PPTP)

- https://vladtalks.tech/vpn/setup-pptp-vpn-on-mac

### Royal TSX

- 支持多SSH/FTP/SFTP/RemoteDesktop终端管理
- 快捷键
    - Cmd+0 切换左侧导航显示
    - Cmd+i 显示当前连接配置
- New - Terminal 新建连接
    - Terminal
        - 只有通过SSH连接才能开启Tunnal，如果通过Customer Terminal + expect脚本则不行(且不能直接连接SFTP)
    - Credentials
        - ssh基于秘钥连接时: Credentials - Credential中用户名密码只需要配置用户名；Private Key File填秘钥路径
    - Custom Properties
        - 配置Key-Value键值对后: 可在连接配置 - 右键 - Copy to Clipboard - 可复制配置的键值对
    - Tunnels
        - Dynamic 只能绑定到本地(无法开放给局域网访问)，如果基于局域网可以通过快捷命令完成
- New - Secure Gateway 新建加密网关
    - 如访问生产环境一般需要跳板机，此处的加密网关就是配置登录跳板机，如果是基于秘钥的登录则需要先设置全局密码
- Application - Credentials 设置全局密码(可用于加密网关)
    - 如果是基于秘钥的可同时设置账号(不用设置密码) + 秘钥文件
- Application - Tasks 全局命令(命令只能调用本地Terminal, 不能发送到Royal Terminal)
    - 命令中可使用很多变量，如`$URI$`表示当前连接的ip地址

### Item2

- 终端管理相关软件
    - Royal TSX比较好用(收费,可破解)
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
    - **在 Finder 中打开当前目录 `open .`**
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
- **设置代理，加速访问github等**

```bash
# vi ~/.zshrc
# 编辑好文件后，重新打开item2 Tab，执行proxy开启代理。可使用`curl cip.cc`测试当前IP地址
alias proxy="export ALL_PROXY=socks5://127.0.0.1:1088"
alias unproxy="unset ALL_PROXY"

## 使用
# 参考下文，使用item2快速脚本启动代理
# 网络设置里面设置网线(USB)/Wifi对应适配器的SOCKS代理即可, 如 127.0.0.1 1088
# 命令行执行proxy/unproxy启用/关闭当前命令行代理 (使用v2ray全局代理对应命令行无效)

## 命令行加速也可以使用Item2+Proxifier方式，参考下文
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
    - API参考：https://iterm2.com/python-api/index.html
    - 脚本案例: 启动代理(配合Proxifier可实现软件网络代理)

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
        - 使用
            - 启动此脚本
            - 设置Proxifier Rules
            - 访问目标网址，如: https://cip.cc
- 基于lrzsz进行文件上传和下载

```bash
# 参考：https://mikuac.com/archives/882/
# 1.mac安装lrzsz
brew install lrzsz
# 查询lrzsz位置并设置软连接
brew list lrzsz
ln -s /opt/homebrew/Cellar/lrzsz/0.12.20_1/bin/lrz /usr/local/bin/rz
ln -s /opt/homebrew/Cellar/lrzsz/0.12.20_1/bin/lsz /usr/local/bin/sz

# 参考：https://blog.csdn.net/weixin_42948074/article/details/120494608
# 2.增加iterm2-zmodem脚本，并chmod +x设置可执行
# 3.配置item2触发器
```

### JAVA

- 到Oracle官网下载dmg格式文件进行安装，可安装多个版本
- `/usr/libexec/java_home -V` 查看可用的JDK版本
    - 切换版本参考下文jenv，也可修改`~/.zshrc`中配置中的JAVA_HOME
- 安装完后删除`/Library/Internet Plug-Ins/JavaAppletPlugin.plugin`目录
    - 如`sudo mv /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin.bak`
    - 否则mvn命令执行时报错，参考：https://blog.csdn.net/w605283073/article/details/111770386

### PHP

- mac系统自带的php在目录/usr/bin/php，php-fpm在目录/user/sbin/php-fpm
- 重新安装php(基于arm安装，x86安装参考下文)

```bash
# arm(M1)安装的brew为v3.2.11. 安装位置 /opt/homebrew, 安装的包位置 /opt/homebrew/opt
# x86(Inter)安装的brew为v3.6.21. 安装位置 /usr/local/Homebrew, 安装的包位置 /usr/local/Cellar
# 安装最新版本php(对应路径为/opt/homebrew/opt/php)
brew install php
# 安装某个版本php
# 有可能安装php@7.4提示：Error: php@7.4 has been disabled because it is a versioned formula!
# 解决办法参考：https://stackoverflow.com/questions/70417377/error-php7-3-has-been-disabled-because-it-is-a-versioned-formula (`brew tap shivammathur/php`, `brew install shivammathur/php/php@7.4`)
brew install php@7.4
# 查看安装好的php路径
brew --prefix php@7.4

# 启动php-fpm
brew services start php@7.4

# 切换版本: 先取消原关联版本, 再切换到其他版本
# 可通过 brew list 查看按照的包名称
brew unlink php@7.3
brew link php@7.4
```
- 基于x86模式安装

```bash
# 命令行切换成x86模式
# php7.3、php7.4尚未安装成功
/usr/local/Homebrew/bin/brew install php@8.0
/usr/local/Cellar/php@8.0/8.0.27_1/bin/php -v
brew services start php@8.0

# 安装composer
curl -sS https://getcomposer.org/installer | /usr/local/Cellar/php@8.0/8.0.27_1/bin/php
# 查看composer
/usr/local/Cellar/php@8.0/8.0.27_1/composer.phar
```

### IDEA

- 插件目录 `/Users/smalle/Library/Application\ Support/JetBrains/IntelliJIdea2021.2/plugins`

### Notepad Next

- https://github.com/dail8859/NotepadNext

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
    - 部分使用sudo仍然安装失败，可使用如`sudo npm install --unsafe-perm=true --allow-root -g mirror-config-china --registry=https://registry.npm.taobao.org`
- 常见问题
    - 在npm install进行包依赖安装是，部分包需要依赖autoreconf命令，从而提示`/bin/sh: autoreconf: command not found`。此时可通过`brew install autoconf automake libtool`先手动安装autoreconf，并将`PATH="/opt/homebrew/opt/libtool/libexec/gnubin:$PATH"`添加到`~/.zshrc`

### FTP/SFTP

- MAC开启SFTP服务
    - 偏好设置 - 共享 - 勾选远程登录 - 添加允许登录用户
    - 执行`sftp localhost`即可

### Jad-GUI

- jad-gui打开报错需要按照jdk 1.8+，解决办法参考：https://blog.csdn.net/lei182/article/details/111914142

### Jenv(Java多版本管理工具)

- 参考：https://blog.csdn.net/aigestudio/article/details/99641818
- 使用

```bash
brew install jenv
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(jenv init -)"' >> ~/.bash_profile
# 查看可用的JDK路径（需提前手动安装，jenv只能切换版本，不能进行安装），安装JDK参考上文[JAVA](#JAVA)
/usr/libexec/java_home -V
# 将可用的JDK加入到jenv中管理
jenv add /Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home
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

### 安卓模拟器

```bash
# 参考: https://ov-vo.cn/573.html
# 安装ADB
brew install android-platform-tools
# 测试是否正常安装
adb devices
# 查看安装的位置
brew info android-sdk
# 安装Android-Emulator并打开
https://github.com/google/android-emulator-m1-preview/releases/tag/0.3
# 配置ADB
打开设置窗口 - Settings- 取消勾选Use detected ADB location
点击后面的文件夹图标找到ADB文件路径(Cmd+Shift+G前往opt目录) /opt/homebrew/Caskroom/android-platform-tools/33.0.1.../platform-tools/adb
# 修改虚拟机基本设置(可选)
编辑/applications/android \ emulator.app/cottents/macos/Pixel_5_API_31/config.ini 配置文件
默认分配 4CPU 4GBRAM 5GB用户空间 分辨率2340*1080 DPI400，可按需修改
# 可直接将豌豆荚下载好拖拽到模拟器进行安装
```

### CrossOver

- CrossOver 20.0.4支持OSX 11.x上运行Windows应用，但是收费
- Wineskin 类似CrossOver，且免费

### wine

- `wine` 已经不支持 OSX 11.x(由于OSX不再支持32bit程序)
    - 有说可使用`https://hub.fastgit.org/Gcenx/WineskinServer`解决(没成功)
    - **可使用CrossOver代替**
- wine依赖`XQuartz`，就是俗称的X11，是苹果电脑为Mac OS X上X Window系统的实作

```bash
# 参考：https://wiki.winehq.org/MacOS
# 需先安装xquartz, 下载 https://www.xquartz.org/
# 下载winehq pkg包：https://dl.winehq.org/wine-builds/macosx/download.html
```

## 相关技巧

### 微信双开

- 参考: https://github.com/CLOUDUH/dual-wechat
    - 运行`nohup /Applications/WeChat.app/Contents/MacOS/WeChat > /dev/null 2>&1 &`即可(只支持双开)
    - 或者将上面的命令封装成自动脚本
        - 自动操作 - (新建)应用程序 - (搜索)运行Shell脚本 - 再脚本中填入上述命令 - 保存自动操作文稿(app到应用程序目录)
        - 可修改自动操作图标: 右键自动操作程序 - 简介 - 将icns图片复制粘贴到左上角的图标处（但是双击脚本启动的双开微信应用图标还是原来的）

## 相关限制

- 不支持修改`/etc/profile`等配置，可修改`~/.zprofile`或`~/.bash_profile`代替。类似的文件`.zshrc`
- 不支持向`/usr/bin`目录添加文件，可向`/usr/local/bin`目录添加来实现直接运行程序目的

## 常见问题

- Mac压缩文件，里面会包含`_MACOSX`等影藏文件夹
    - 参考：https://www.zhihu.com/question/475167014

