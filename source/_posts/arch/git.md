---
layout: "post"
title: "Git"
date: "2016-04-16 12:40"
categories: arch
tags: [git]
---

## git简介

- [官网](https://git-scm.com/)
- [git命令学习地址](https://learngitbranching.js.org/?locale=zh_CN)
- 安装
	- windows：官网下载对应安装包
	- Centos：`yum -y install git`
	- Ubuntu：`sudo apt-get install git`
    - 客户端界面：[SmartGit V21.2.4](https://www.syntevo.com/smartgit/download/archive/) 
- 镜像

```bash
# 单文件下载
# 原文件下载地址 https://raw.githubusercontent.com/teddysun/across/master/l2tp.sh
# 使用sourcegraph下载地址 https://sourcegraph.com/github.com/teddysun/across/-/raw/l2tp.sh
```

## git入门 [^1]

### git配置

#### 全局配置

- 配置

```bash
# 列出所有配置
git config --list

## 设置全局用户名和邮箱
git config --global user.name smalle
git config --global user.email admin@qq.com
# 为单一仓库设置，下同
git config user.name "username"
git config user.email "email"

## 设置回车和换行
# Git 可以在你提交时自动地把回车CR和换行LF转换成换行LF，而在检出代码时把换行LF转换成回车CR和换行LF。Windows 系统上，把它设置成 true(但是需要和vscode的格式化保持一致)
git config --global core.autocrlf true
# 如果使用以换行（LF）作为行结束符的 Linux 或 Mac，你不需要 Git 在检出文件时进行自动的转换。然而当一个以回车（CR）和换行（LF）作为行结束符的文件不小心被引入时，你肯定想让 Git 修正
# git config --global core.autocrlf input
# 如果你是 Windows 程序员，且正在开发仅运行在 Windows 上的项目，可以设置 false 取消此功能
# git config --global core.autocrlf false

# 忽略文件权限修改导致的文件变更
git config --global core.filemode false
# 拒绝提交包含混合换行符的文件
git config --global core.safecrlf true

## 设置在命令行打印的代码带颜色
git config --global color.ui true
```

以上操作其实是对git的根目录下.gitconfig（`~/.gitconfig`，`~`代表根目录，`cat  ~/.gitconfig`查看此文件）进行的操作，也可直接对这个文件进行修改

> `cat 文件路径名`查看某个文件，如：**cat ~/.gitconfig**（`~`代表根目录）
> `vi 文件名`打开某个文件进行编辑
> - 点击键盘`insert`，进入vi编辑模式，开始编辑；
> - 点击`esc`退出编辑模式，进入到vi命令行模式；
> - 输入`:x`/`ZZ`将刚刚修改的文件进行保存，退出编辑页面，回到初始命令行
> `ls`查看当前目录结构，`ls -A`可以显示隐藏的目录

#### 项目配置

- `.git/config` 文件

```ini
# 分支信息
[remote "origin"]
    # 如果远程仓库修改了，把此处的url换掉即可，提交历史还会保留
	url = http://xxx/xxx.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
	remote = origin
	merge = refs/heads/master
[branch "develop"]
	remote = origin
	merge = refs/heads/develop
# 提交的用户信息
[user]
    name = smalle
    email = smalle@163.com
```
- `git config core.ignorecase false` 配置项目大小写敏感

#### Git通过命令行使用多个账户登录GitHub

- 使用~/.ssh/config文件解决
    - https://zhuanlan.zhihu.com/p/521768041 无需设置ssh-agent

### repository

- 创建repository(并关联远程仓库)
	- `cd d:/git/demo/`进入到项目文件夹（可使用`mkdir 文件夹名`在当前目录创建文件夹或者手动创建）

		> - 此时git bash上显示`smalle@ST-008 MINGW64 /d/git/demo`（直接在demo目录`右键-Git Bash Here`也是这个显示）
		> - 如果直接点击桌面上的git图标进入命令行显示的是`smalle@ST-008 MINGW64 ~`
		> - 创建之后，d:/git/demo/目录就是后面提到到 working 区（其实就是本地磁盘）

	- `git init` 初始化项目，提示 Initialized empty Git repository in D:/git/demo/.git/
		- 此时就产生了后面提到的 staging 和 history 区
	- `git add .` 添加所有文件到本地索引
	- `git commit -am '初始化提交'` 提交修改到本地仓库
	- `git remote add origin https://github.com/oldinaction/jekyll_demo.git` 添加远程仓库地址，保存在origin变量中
	- `git push origin master` 按照前一条命令中origin给定的git远程地址推送到远程仓库的master分支（容易和远程产生冲突）
- 克隆repository
	- `git clone https://github.com/UserName/ProjectName`，这是利用https方式克隆，还有其他如git、ssh等方式（克隆后git会在当前目录新建一个文件夹为 "ProjectName" 的项目）
	- **`git clone -b <remote branch> <remote address>`** 克隆远程仓库的某个分支/标签（如：`git clone -b develop http://192.168.1.1/test.git`，此时本地分支名默认也为develop）
	- `git clone username@aezo.cn/xxx.git` 指定用户名，用户名如果包含`@`等特殊字符需要转转义，如`@`对应`%40`(私有仓库如果未指定用户名时：全局有指定用户名则使用全局，如果全局无则弹框输入)
	- `git clone username:password@aezo.cn/xxx.git`
- 克隆远程仓库的某个文件夹
	- 建立本地仓库
		- `mkdir project_folder`
		- `cd project_folder`
		- `git init`
		- `git remote add -f origin <url>`
	- `git config core.sparsecheckout true` 允许使用Sparse Checkout模式
	- 保存需要下载的文件夹名到`.git/info/sparse-checkout`文件中。如`echo "src" >> .git/info/sparse-checkout`
	- `git pull origin master` 拉取相应分支
- 多个远程仓库(同一代码提交到oschina和github)

    ```bash
    git remote add origin git@github.com:test1/test1.git # 推送到github
    git remote add osc git@git.oschina.net:test2/test2.git # 推送到oschina

    git add .
    git commit -m 'First commit'

    git push origin master # 推送到github。默认远程，可简写为 git push
    git push osc master # 推送到oschina
    ```

### 分支

- 查看分支
	- `git branch` 查看本地分支（`*`代表当前所处的分支）
	- `git branch -a` 查看本地和运程所有分支
- 创建分支
	- `git branch 分支名` 创建一个新的分支。如果此分支和 master 是同一级分支（及在处于 master 时创建的分支），那么他们指向同一个 commit 对象
	- `git checkout -b <localBranchName>` 创建一个本地分支并且换到此分支（是`git branch 分支名` 和 `git checkout 分支名`的合并命令）
	- `git checkout -b <localBranchName> <remotesBranchName>` 相当于检出远程的某个分支到本地，远程分支名如origin/b1(使用 `git branch -a` 查看时显示为remotes/origin/b1)
		- **`git checkout -b <localBranchName> --track <remotesBranchName>`** 检出分支并创建本地分支与远程分支的追踪
		- 勿使用 `git checkout 远程分支名` 命令会是当前HEAD变为一个游离的HEAD（即现在HEAD指向的是一个没有分支名字的修订版本，游离于已知的所有分支之外，如`HEAD detached at origin/b1`）
		- `git checkout -b test1 origin/develop` 拉取远程develop分支
	- `git push origin <branch>` 创建远程分支
- 切换分支
	- `git checkout 分支名` 切换到此分支（*Switched to branch '分支名'*），此时 HEAD 指向此分支；并且本地磁盘（working 区）的内容会显示此分支的文件
- 合并分支
	- `git merge 子分支名` 将子分支名合并到当前分支(合并可能产生冲突，产生冲突后需要人为解决)
- 跟踪/关联分支 `git branch --set-upstream-to=<remotesBranchName> <localBranchName>` 
	- 必须先要有此本地分支。之后可以使用`git push/pull`直接对相应分支进行操作
	- `git branch -vv` 查看分支的关联关系
- 删除分支
	- `git branch -d 分支名` 删除此分支（只能删除除当前分支以外的分支；如果当前分支有一次提交，则需要将此分支合并到主分支之后再进行删除）
	- 删除远程分支：`git branch -r -d origin/branch-name`或者`git push origin :branch-name`
- 重命名分支：`git branch -m old-branch-name new-branch-name`
	- 在git中重命名远程分支，其实就是先删除远程分支，然后重命名本地分支，再重新提交一个远程分支

### tag标签

```bash
# 列举所有tag
git tag
# 把当前版本添加标签v1.0.0
git tag v1.0.0
# 推送标签到远程
git push origin v1.0.0
# 推送所有标签
git push --tags
# 检出标签对应版本
git checkout v1.0.0
# 删除本地和远程标签
git tag -d v1.0.0
git push origin v1.0.0
```

### 添加、提交文件

- 利用`git add <file>` / `git add .`将 working 中此文件或者所有文件添加到 staging 区（**&lt;file&gt;** 为必输的文件名）
- 利用`git commit -m '提交时的备注'` 将 staging 区中的此文件提交到 history 区（如果不加`-m`则命令行会打开一个vi编辑器供用户填写提交时的备注）
- 利用`git commit -a` 将 working 中此文件直接提交到文件到history 区（此时一般加上参数`-m`，即`git commit -am '提交时的备注'`）

![git运行流程图](/data/images/2016/04/git流程图.png)

### 丢弃/暂存/撤销/重置

- 丢弃

```bash
# 丢弃本地修改：他会将文件从 working 区删掉(等同于没有修改)
git checkout <file1> <file2>
# 丢弃本地所有修改
git checkout .
# 撤销对文件的 add 操作：他会从 staging 区中将此文件取出并还原到 working 区（其中文件名为相对.git文件夹的路径名）
git checkout -- <file>
# 撤销对文件的 add 操作：他会从 history 区中将此文件取出并还原到 working 区
git checkout HEAD <file>
```
- 暂存和恢复暂存

```bash
# 把所有没有提交的修改暂存到stash里面
git stash
# 恢复暂存的修改到本地空间
git stash pop
```
- 撤销和重置
    - `revert` 是放弃指定提交的修改，但是会生成一次新的提交，需要填写提交注释，以前的历史记录都在
    - `reset` 是指将HEAD指针指到指定提交，历史记录中不会出现放弃的提交记录

```bash
# 参考：https://blog.csdn.net/QQxiaoqiang1573/article/details/68074847
# 假设修改 README.md 文件存在以下提交记录. `git log`显示的提交历史是按照时间降序排列的(最近的提交在上面)
# 3: commit 3
# 2: commit 2
# 1: commit 1

## 撤销和重置最近一次提交
# 撤销最近一次提交(命名为3)，执行后需要输入提交备注，输入备注保存后此撤销提交就回被记录，之后推送到远程也会有此撤销提交记录(命名为4)
git revert HEAD
# 推送到远程(此时无需-f强制，因为当前版本要超前于远程版本)
git push origin master
# 1.=>重置最近一次提交(上文的4，重置后代码版本相当于恢复到3，而且从日志中完全看不到之前有做过revet动作，即4这此提交会被删除)，此时不需要输入任何备注
# 注意：--hard执行重置后，提交的代码会直接丢弃(提交日志也没有了，容易丢代码)。--soft参考下文
git reset --hard HEAD^
# 推送到远程。-f 参数是强制提交，因为reset之后本地库落后于远程库一个版本，因此需要强制提交
git push origin master -f
# 2.=>撤销本次提交
# --soft重置只撤销commit，且对应修改会回到 staging 区
git reset --soft HEAD^
# --cache 保留文件到 working 区(之后可直接删除文件进行丢弃)，如果只留 -f 参数则是直接丢弃文件
git rm <file> -f --cache # 等同于 git reset HEAD <file>

## 重置到某次提交
# "commit-id"替换为想要删除的提交ID(如要删除commit 2这次提交ID: 839e358d6b22f8e0b3591a889e149ba4d561325f)，需要注意最后的^号，意思是commit id的前一次提交(如此时commit-id对应commit 2这次提交，即：git rebase -i "839e358d6b22f8e0b3591a889e149ba4d561325f"^)
git rebase -i "<commit-id>"^
# 执行上述条命令后会打开一个编辑框，内容中列出了包含上文commit-id在内之后的所有提交(即commit 2和commit 3对应的commit-id前7位id，内容中下面有一个#行为提示信息)
# 然后在编辑框中删除你想要删除的提交所在行(如`pick 839e358 commit 2`)
# 然后保存退出；如果有冲突，保存后会提示`CONFLICT`，假设 README.md 文件冲突
    # `vi README.md` 解决冲突
    # `git add .`
    # `git commit -am 'resolve conflict'` 提交解决的冲突文件
    # `git rebase --continue` 继续进行rebase操作 (中途也可 `git rebase --abort` 放弃整个操作; 注意`git rebase --skip`会将冲突的提交全部丢弃掉然后继续进行rebase操作)
# 最后再推送到远程即可
git push origin master -f

## 修改历史某次提交(未测试)
# 这种情况的解决方法类似于第二种情况，只需要在第二条打开编辑框之后，将你想要修改的提交所在行的pick替换成edit然后保存退出，这个时候rebase会停在你要修改的提交，然后做你需要的修改，修改完毕之后，执行以下命令：
git add .
git commit --amend
git rebase --continue
# 如果你在之前的编辑框修改了n行，也就是说要对n次提交做修改，则需要重复执行以上步骤n次
```
- 撤销所有的提交(相当于初始化项目)

```bash
# 参考: https://blog.csdn.net/icansoicrazy/article/details/128342811
# git checkout --orphan 类似git init的状态创建新的非父分支，也就是创建一个无提交记录的分支; 之后删除master分支再重命名当前分支为master分支
# 重建Maven仓库(清除原来所有的git提交历史)
git checkout --orphan latest_branch
git add -A
git commit -am 'init'
git branch -D master
git branch -m master
git push -f --set-upstream origin master
```

### 删除文件

**在用使用 `git clean` 前，强烈建议加上 -n 参数来先看看会删掉哪些文件，防止重要文件被误删**

- `git clean -nf` **查看删除文件**
	- `git clean -f` 删除 untracked files
- `git clean -nfd`
	- `git clean -fd` 连 untracked 的目录也一起删掉
- `git clean -nxfd`
	- `git clean -xfd` 连 gitignore 的untrack 文件/目录也一起删掉 （慎用，一般这个是用来删掉编译出来的文件用的）
- `git rm <file>` 将此文件从 repository 中删除
- `git rm --cached <file>` 将此文件从 staging 区中删除，此时 working 区中还有
- `git mv README.txt README.md` 将 README.txt 文件重命名为 README.md（markdown格式）

### 与远程仓库同步

- `git fetch 远程仓库地址` 下载远程仓库的变动到当前分支的历史区
- `git pull 远程仓库地址` 取回远程仓库的变化到当前分支的工作区
	- `git pull` 获取本分支追踪的远程分支
	- `git pull origin develop` 获取远程develop分支(使用 `git branch -a` 查看时显示为remotes/origin/develop)
	- `git pull origin master:test` 取回远程的master分支到本地test分支
- `git push 远程仓库地址` 将本地仓库内容同步到远程仓库，回车后输入用户名和密码即可

#### 同步两个远程仓库

- 参考 https://zhuanlan.zhihu.com/p/391712989

```bash
# 指定当前 fork 将要同步的上游远程仓库地址(upstream只是一个别名，可使用其他代替)
git remote add upstream https://github.com/ORIGINAL_OWNER/ORIGINAL_REPOSITORY.git
# 拉取上游代码，然后将上游代码分支upstream/master合并到本地master分支
git fetch upstream
```

### 查看git状态和文件差别

- 利用`git status`查看文件状态，`git status -s`显示文件扼要信息
	- Git内部只有三个状态，分别是未修改unmodified、修改modified、暂存staged。对于没有加入Git控制的文件，可以视为第四种状态未跟踪untracked
	- 提示 *Untracked files* 表示没有向 git 进行登记，需要增加到 git 进行版本控制（下面文件显示红色）。使用`git add <file>` / `git add .`
	- 提示 *Changes to be committed* 表示文件被修改，等待提交（下面文件显示绿色）。使用`git commit -m '提交时的备注'`
	- 提示 *nothing to commit, working directory clean* 表示没有文件需要提交
	- 运行`git status -s`命令，显示的标识位信息分别表示staging 和 working两个区
		- `A_`其中 A 表示 staging 中新加的文件，空格表示 working 没有变化（其中`_`表示空格）
		- `_M`其中空格表示 staging 中没有改变，M 表示 working 做了修改
		- `MM`表示 staging 和 working 都发生了变化
		- `D_`表示 staging 中此文件被删除了
		- `R_`表示 staging 中此文件进行了重命名
		- `??`表示此文件没有被 git 进行版本控制
    - `git status --untracked-files` 以文件的形式展示(默认以文件夹)
- 利用`git diff`查看文件差别，`git diff --stat`是对文件差别的扼要描述
	- `-红色字体`表示删除的
	- `+绿色字体`表示增加的
	- `git diff`默人对`git status -s`的第二个标识位（working）进行详细描述；
	-  使用`git diff --staged` / `git diff --cached`则是对第一个标识位（staging）进行详细描述；
	- 使用`git diff HEAD`则是对 history 区此文件的描述
- 注意事项
	- git不监控文件权限属性变化

### 其他

#### 查看日志和帮助

- `git help` 查看帮助。`[]`为可选，`<>`为必输

- `git log`查看提交日志，`Ctrl+Z` 退出查看
    - `git log -1` 查看最近一条提交
	- `git log --oneline` 可以显示更加短小的提交ID
	- `git log --graph` 显示何时出现了分支和合并等信息
	- `git log --pretty=raw` 显示所有提交对象的parent属性
	- `git reflog` 查看每个提交版本信息(排在上面的为最新版本)

- `git cat-file -p 哈希码(或简写)或者对象名` 展示此对象的详细信息
- `git cat-file -t 哈希码(或简写)` 查看Git对象的类型，主要的git对象包括tree，commit，parent，和blob等
	- 如：`git cat-file -t HEAD`的结果是commit表示此HEAD指向一个commit 对象

- `cat .git/HEAD` 查看HEAD指向(当前分支)。如打印 `.git/refs/heads/master`
- `cat .git/refs/heads/master` 查看HEAD的哈希码(简写取前7位)
- `git rev-parse HEAD` 获取 HEAD 对象的哈希码

#### 暂存工作区

```bash
# 备份当前的工作区的内容，从最近的一次提交中读取相关内容，让工作区保证和上次提交的内容一致。同时，将当前的工作区内容保存到Git栈中（比如有紧急Bug需要修复）
git stash
git stash save '本次暂存的标识名字'
# 从Git栈中读取最近一次保存的内容，恢复工作区的相关内容
# pop恢复后，暂存区域会删除当前暂存记录；apply恢复后不会删除暂存区记录
git stash pop
git stash pop stash@{index} # index为暂存的索引(可通过git stash list查看索引)，需要保留{}
git stash apply stash@{index}
# 显示Git栈内的所有备份，可以利用这个列表来决定从那个地方恢复
git stash list
# 清空Git暂存栈
git stash clear
```

#### commit对象

- commit 对象中 parent 属性指向前一个 commit，tree 属性指向一个 tree 对象（此 tree 对象可以指向文件或者文件夹）
- HEAD 指向 master（只有一个分支的情况下），master 指向最新的 commit；HEAD~（或master~）表示前一个 commit；HEAD~2（或master~2）表示上上一个 commit，以此类推；- HEAD~2^ 表示 HEAD~2 的父提交（此时和HEAD~3是同一个对象）
- HEAD 的哈希码存放在 `.git/refs/heads/xxx` 文件中(当前处于xxx分支)

#### 解决冲突

- 如下，`<<<<<<< HEAD` 和 `=======` 中间的是自己的代码，`=======` 和 `>>>>>>>` 中间的是其他人修改的代码

```bash
$ cat .eslintignore
build/*.js
<<<<<<< HEAD
config/*.js
src
=======
src/assets
public
dist
>>>>>>> develop/test
```
- 查看

```bash
# 查看操作状态
git status
# 解决某文件的冲突：修改文件
vi .eslintignore
# 暂存并提交
git add .eslintignore
git commit -m "conflict fixed"
# 查看合并后分支情况
git log --graph --pretty=oneline --abbrev-commit
# 删除已合并分支
git branch -d develop/test
```

#### git凭证存储

- [官网凭证存储说明](https://git-scm.com/book/zh/v2/ch00/r_credential_caching)
- `git config --list`中`credential.helper`即为凭证存储模式
- `git config --global credential.helper store` 设置凭证存储为store模式
- 凭证存储模式
	- manage 使用windows凭证管理(控制面板 - 用户管理 - 凭证管理，Git-2.15.1.2-64-bit默认)
	- cache 凭证保存在内存中，默认15分钟有效，过期运行git命令则需要重新登录
	- store 以明文形式保存在home目录磁盘。/home/xxx/.gitconfig(清除或修改)
	- osxkeychain mac系统专属，加密后存放在磁盘
- 常见问题`remote: Repository not found`，重新安装`credential-manager`
	- `git credential-manager uninstall`
	- `git credential-manager install`

#### git免密码登录

- 法一：使用manage保存凭证(不适合同一台机器上使用多个git账号，就windows而言，这个凭据放在windows的凭据管理器中)
	- `git config credential.helper manager`
- 法二：使用SSH方式
	- `ssh-keygen -C 'smalle-pc'` git客户端执行生成秘钥，会在用户家目录下的.ssh文件夹中生成2个名为id_rsa和id_rsa.pub的文件
	- 以github为例：Github - Setting - SSH and GPG keys - New SSH key - Name可随便标识，把id_rsa.pub公钥文件内容保存在Key中 **(客户端一定要将私钥文件id_rsa保存到.ssh目录，普通的ssh登录客户端貌似无需私钥文件？)**
	- `git config --global  user.name "git服务器用户名"`
	- `git config --global user.email "邮箱"`
	- `git remote set-url origin git@github.com:USERNAME/REPOSITORY.git`
	- `ssh -T git@github.com` 测试是否可以正常登录，`ssh -vT git@github.com` 显示登录信息
		- 常见问题：`Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password)`，参考文章：https://blog.51cto.com/11975865/2308044，https://www.cnblogs.com/sloong/p/6132892.html。实际操作gitlab遇到的是另外一个问题，具体如下
		
		```bash
		# 1.一直提示以下内容
		debug1: Next authentication method: gssapi-with-mic # 表示使用gssapi-with-mic进行验证
		debug1: Unspecified GSS failure.  Minor code may provide more information
		No Kerberos credentials available (default cache: KEYRING:persistent:0)

		debug1: Unspecified GSS failure.  Minor code may provide more information
		No Kerberos credentials available (default cache: KEYRING:persistent:0)

		debug1: Next authentication method: publickey # 使用publickey进行验证
		debug1: Offering RSA public key: /root/.ssh/id_rsa
		debug1: Server accepts key: pkalg ssh-rsa blen 279
		debug1: Trying private key: /root/.ssh/id_dsa
		debug1: Trying private key: /root/.ssh/id_ecdsa
		debug1: Trying private key: /root/.ssh/id_ed25519
		debug1: No more authentication methods to try.
		Permission denied (publickey,gssapi-keyex,gssapi-with-mic).

		# 2.git客户端登录的是root用户，原本只存在文件/root/.ssh/id_rsa.pub，发现上面使用的是id_rsa，则仅仅将id_rsa.pub改成id_rsa文件(仍然是公钥文件)
		Enter passphrase for key # 要求输入密码，但是生成秘钥对的时候并没有密码

		# 3.直接使用原始生成的id_rsa秘钥文件，则将之前生成的秘钥文件也加入到此目录
		Permissions 0644 for '/root/.ssh/id_rsa' are too open.
		It is required that your private key files are NOT accessible by others.

		# 4.提示上面文件开放权限太大，在git客户端设置`chmod 600 /root/.ssh/id_rsa`，可正常使用
		```
- 通过ssh获取代码时，在命令行可以正常获取，在idea界面中无法拉取代码(idea的命令行可以)
    - 设置idea中Git配置项的SSH executable=Native

#### 忽略控制文件

- `.gitignore` 文件创建和设置
	- git根目录运行命令：`touch .gitignore`
	- 使用 vi 编辑器进行文件配置
- 配置语法 [^6]
	
	```bash
	#               表示此为注释,将被Git忽略
	*.a             #表示忽略所有 .a 结尾的文件
	!lib.a          #表示但lib.a除外
	/TODO           #表示仅仅忽略项目根目录下的 TODO 文件，不包括 subdir/TODO
	build/          #表示忽略 build/目录下的所有文件，过滤整个build文件夹；
	doc/*.txt       #表示会忽略doc/notes.txt但不包括 doc/server/arch.txt
	
	bin/:           #表示忽略当前路径下的bin文件夹，该文件夹下的所有内容都会被忽略，不忽略 bin 文件
	/bin:           #表示忽略根目录下的bin文件
	/*.c:           #表示忽略cat.c，不忽略 build/cat.c
	debug/*.obj:    #表示忽略debug/io.obj，不忽略 debug/common/io.obj和tools/debug/io.obj
	**/foo:         #表示忽略/foo,a/foo,a/b/foo等
	a/**/b:         #表示忽略a/b, a/x/b,a/x/y/b等
	!/bin/run.sh    #表示不忽略bin目录下的run.sh文件
	*.log:          #表示忽略所有 .log 文件
	config.php:     #表示忽略当前路径的 config.php 文件
	
	/mtk/           #表示过滤整个文件夹
	*.zip           #表示过滤所有.zip文件
	/mtk/do.c       #表示过滤某个具体文件

	# 	----------------------------------------------------------------------------------
	#想象一个场景：假如我们只需要管理/mtk/目录中的one.txt文件，这个目录中的其他文件都不需要管理，那么.gitignore规则应写为：
	#注意/mtk/*不能写为/mtk/，否则父目录被前面的规则排除掉了，one.txt文件虽然加了!过滤规则，也不会生效！
	/mtk/*
	!/mtk/one.txt

	#说明：忽略目录 fd1 下的全部内容，但不包含one.txt；注意，不管是根目录下的 /fd1/ 目录，还是某个子目录 /child/fd1/ 目录，都会被忽略；
	*/fd1/*
	!*/fd1/one.txt
	
	#说明：忽略根目录下的 /fd1/ 目录的全部内容；
	/fd1/*
	
	#说明：忽略全部内容，但是不忽略 .gitignore 文件、根目录下的 /fw/bin/ 和 /fw/sf/ 目录；注意要先对bin/的父目录使用!规则，使其不被排除。
	/*
	!.gitignore
	!/fw/ 
	/fw/*
	!/fw/bin/
	!/fw/sf/
	```
- 已经提交的文件(git已经管理了此文件，仓库已经存在此文件)无法忽略解决办法
	- 先删除对应文件，提交版本，再将此文件加到.gitignore中，再次提交则不会出现
	- 如果是未提交的文件，此时不管.gitignore文件是否提交，.gitignore文件都是生效的
- 删除.DS_Store文件，然后加入忽略
    `sudo find /project/demo -name ".DS_Store" -depth -exec rm {} \;`

#### 处理Linux/Unix/MacOS文件格式的EOL

https://help.github.com/en/articles/configuring-git-to-handle-line-endings

#### 大文件删除及管理

- 参考：https://blog.csdn.net/dddd6666qq/article/details/107404658
- 查看大文件

```bash
git rev-list --objects --all \
| git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
| sed -n 's/^blob //p' \
# 已第2个字段(文件大小)进行排序
| sort --numeric-sort --key=2 \
# (可省略)显示hash的前12个字符
# | cut -c 1-12,41- \
# 排除HEAD分支中存在的文件
| grep -vF --file=<(git ls-tree -r HEAD | awk '{print $3}') \
# 过滤文件大于1M=2^20B的
| awk '$2 >= 2^20' \
# (可省略)显示的文件大小更易读，K/M为单位。mac无numfmt命令，需要安装`brew install coreutils`(核心工具命令)
| $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest

# 显示如
7e692fbf52d41f0df8420a269fc5688feddc773b  4.3MiB sqbiz-plugin/sqbiz-druid-plugin/target/sqbiz-druid-plugin.ark.plugin
```
- 基于bfg.jar清理

```bash
## bfg清理
# 下载bfg.jar到`/Users/smalle/software/git-bfg`
# bfg默认会保护当前版本(HEAD所指的版本)不去清理
# 删除超过1M的文件. demo为仓库根目录，执行完后会生成一个日志文件夹
java -jar /Users/smalle/software/git-bfg/bfg.jar --strip-blobs-bigger-than 1M demo
# 删除文件
java -jar /Users/smalle/software/git-bfg/bfg.jar --delete-files test.txt demo
# 删除指定目录
java -jar /Users/smalle/software/git-bfg/bfg.jar --delete-folders testdir demo

## git gc 
# 在完成上面的指令后，实际上这些数据/文件并没有被直接删除，这时候需要使用git gc指令来清除
git reflog expire --expire=now --all && git gc --prune=now --aggressive

## 推送。gitee的话还需去后台点下git gc按钮
git push
``` 

## gitflow工作流

- 参考 [^5]

![git-workflow](/data/images/arch/git-workflow.png)

## git提交规范

```bash
1. 提交格式
git commit -m <type>[optional scope]: <description>
	
2. 常用的type类别
type ：用于表明我们这次提交的改动类型，是新增了功能？还是修改了测试代码？又或者是更新了文档？总结以下 11 种类型：
• build：主要目的是修改项目构建系统(例如 glup，webpack，rollup 的配置等)的提交
• ci：主要目的是修改项目继续集成流程(例如 Travis，Jenkins，GitLab CI，Circle等)的提交
• docs：文档更新
• feat：新增功能
• fix：bug 修复
• perf：性能优化
• refactor：重构代码(既没有新增功能，也没有修复 bug)
• style：不影响程序逻辑的代码修改(修改空白字符，补全缺失的分号等)
• test：新增测试用例或是更新现有测试
• revert：回滚某个更早之前的提交
• chore：不属于以上类型的其他类型(日常事务)
optional scope：一个可选的修改范围。用于标识此次提交主要涉及到代码中哪个模块。
description：一句话描述此次提交的主要内容，做到言简意赅。

例如：
git commit -m 'feat: 增加 xxx 功能'
git commit -m 'bug: 修复 xxx 功能'
```

## Github使用

- 镜像站
    - https://hub.連接.台灣
    - https://hub.fastgit.org/
- emoji语法: https://gist.github.com/rxaviers/7360908
- 对于私有项目，通过https访问时不能通过密码验证，可通过[github-cli](https://cli.github.com/manual/)验证

```bash
# cli 使用手册: https://cli.github.com/manual/
# Centos安装
dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
dnf install gh
gh -v

# 登录
gh auth login
# 之后需要任意浏览器访问: https://github.com/login/device
# 并输入命令行显示的秘钥，如 889E-F742

# 下载
gh repo clone https://xxxx

# 认证之后可直接使用git命令
git pull
```
- 更新fork项目/提交请求(`pull request`，简称 `PR`)
    - Github线上提交 `New pull request` - 选择`base repository` - 选择`head repository` - 如果看不到仓库名可点击`compare across forks` - 点击`Create pull request`填写提交说明并确认
        - 表示将head提交到base。如果为更新fork项目，则base选择自己fork的仓库，head选择源仓库(此时可能需要点击`compare across forks`才能看到仓库名)；如果是提交代码到源仓库，则base选择源仓库
    - 命令行提交(以更新fork项目为例)

        ```bash
        # 查看远程仓库信息
        git remote -v
        # 添加源仓库信息
        git remote add upstream git@github.com:xxx/xxx.git
        # 下载远程代码
        git fetch upstream
        # 将源仓库的upstream/master分支合并到当前分支
        git merge upstream/master
        # 推送到远程(fork的项目远程)
        git push
        ```
- gitee下fork项目同步
    - 基于命令行模式 https://blog.csdn.net/weixin_53385000/article/details/117780266
    - 基于界面 https://blog.csdn.net/luoyeyilin/article/details/108994031 (前提: 自己重新定义一个分支当成最新分支)

## svn扩展

- 下载项目：检出
- 更新代码到SVN
	- 项目右键(yitong)-Team-与资源库同步
	- 选择模式：IncomingMode将别人提交的代码同步到本地；outcomingMode将本地修改的代码同步到SVN，Incoming/outcomingMode双向。选择后并没有触发更新
	- 冲突：表示有两个或者多个人同时修改了一个文件。必须先解决冲突再进行更新。让两个人的代码共存:先备份自己修改后的那个文件，再将此文件还原到初始状态，再将SVN别人提交的代码同步到本地，最后将我修改过的代码加到此文件上。
- 同步代码到本地
	- 选择IncomingMode
	- 打开所有的树形结构，文件没有红色标示的则表示和本地文件没有冲突。选择没有冲突的文件-右键-更新
	- 有冲突的先解决冲突。
- 提交代码到SVN
	- 选择outcomingMode
	- 打开所有的树形结构，文件没有红色标示的则表示和本地文件没有冲突。选择没有冲突的文件-右键-提交
	- 有冲突的先解决冲突。(先备份该文件，再将冲突文件Team-还原，再与资源库同步更新别人修改后的该文件，再将自己的修改加上去，最后进行同步提交)
	- 解决冲突后,再提交(先更新一下)

---

参考文章

[^1]: http://edu.51cto.com/course/course_id-1838.html (Git入门视频)
[^2]: http://www.ruanyifeng.com/blog/2014/06/git_remote.html (Git远程操作详解)
[^3]: http://www.ruanyifeng.com/blog/2015/12/git-cheat-sheet.html (常用Git命令清单)
[^4]: http://blog.csdn.net/oldinaction/article/details/49704969 (Git入门及上传项目到github中)
[^5]: https://github.com/xirong/my-git/blob/master/git-workflow-tutorial.md (git-workflow-tutorial)
[^6]: https://www.cnblogs.com/kevingrace/p/5690241.html (Git忽略提交规则)
