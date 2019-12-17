---
layout: "post"
title: "Git"
date: "2016-04-16 12:40"
categories: arch
tags: [git]
---

## git简介

- 官网：[https://git-scm.com/](https://git-scm.com/)
- 安装
	- windows：官网下载对应安装包
	- Centos: `yum -y install git`
	- Ubuntu：`sudo apt-get install git`

## git入门 [^1]

### git全局配置

- `git config --global user.name smalle` 设置用户名
- `git config --global user.email oldinaction@qq.com` 设置邮箱
	- `git config user.name "username"`、`git config user.email "email"` 为单一仓库设置
- `git config --global color.ui true` 设置在命令行打印的代码带颜色
- `git config --list`  列出所有配置

以上操作其实是对git的根目录下.gitconfig（`~/.gitconfig`，`~`代表根目录，`cat  ~/.gitconfig`查看此文件）进行的操作，也可直接对这个文件进行修改

> `cat 文件路径名`查看某个文件，如：**cat ~/.gitconfig**（`~`代表根目录）
> `vi 文件名`打开某个文件进行编辑
> - 点击键盘`insert`，进入vi编辑模式，开始编辑；
> - 点击`esc`退出编辑模式，进入到vi命令行模式；
> - 输入`:x`/`ZZ`将刚刚修改的文件进行保存，退出编辑页面，回到初始命令行
> `ls`查看当前目录结构，`ls -A`可以显示隐藏的目录

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

### 添加、提交文件

- 利用`git add <file>` / `git add .`将 working 中此文件或者所有文件添加到 staging 区（**&lt;file&gt;** 为必输的文件名）
- 利用`git commit -m '提交时的备注'` 将 staging 区中的此文件提交到 history 区（如果不加`-m`则命令行会打开一个vi编辑器供用户填写提交时的备注）
- 利用`git commit -a` 将 working 中此文件直接提交到文件到history 区（此时一般加上参数`-m`，即`git commit -am '提交时的备注'`）

![git运行流程图](/data/images/2016/04/git流程图.png)

### 撤销

- `git checkout -- <file>` 撤销对文件的 add 操作，他会从 staging 区中将此文件取出并还原到 working 区
    - `git checkout test.txt` **丢弃修改**
    - `git checkout .` 本地所有修改的。没有的提交的，都返回到原来的状态（删除不了请参考下方的`git clean`用法）
    - `git checkout HEAD <file>` 撤销对文件的 add 操作，他会从 history 区中将此文件取出并还原到 working 区（其中文件名为相对.git文件夹的路径名）
- `git reset <file>` 撤销对此文件的 commit 操作，他会从 history 区中将此文件取出并还原到 staging 区
    - `git reset --hard HASH` 返回到某个节点，不保留修改。如：`git reset --hard HEAD`，`git reset --hard 8a222ba`
    - `git reset --soft HASH` 返回到某个节点，保留修改
- `git stash` 把所有没有提交的修改暂存到stash里面。可用git stash pop恢复

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
	- `git pull origin master:master` 取回远程的master分支到本地master分支
- `git push 远程仓库地址` 将本地仓库内容同步到远程仓库，回车后输入用户名和密码即可

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

- `git stash` 备份当前的工作区的内容，从最近的一次提交中读取相关内容，让工作区保证和上次提交的内容一致。同时，将当前的工作区内容保存到Git栈中（比如有紧急Bug需要修复）
- `git stash pop` 从Git栈中读取最近一次保存的内容，恢复工作区的相关内容。由于可能存在多个Stash的内容，所以用栈来管理，pop会从最近的一个stash中读取内容并恢复
- `git stash list` 显示Git栈内的所有备份，可以利用这个列表来决定从那个地方恢复
- `git stash clear` 清空Git栈

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
- `git  config --global credential.helper store` 设置凭证存储为store模式
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

#### 处理Linux/Unix/MacOS文件格式的EOL

https://help.github.com/en/articles/configuring-git-to-handle-line-endings

## gitflow工作流 [^5]

![git-workflow](/data/images/arch/git-workflow.png)

## Github使用

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