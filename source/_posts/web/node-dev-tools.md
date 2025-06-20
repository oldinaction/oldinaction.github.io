---
layout: "post"
title: "Node 开发工具"
date: "2017-04-02 11:13"
categories: [web]
tags: [node, tools]
---

## 简介

- 推荐操作

```bash
# 设置镜像
npm config set registry https://registry.npmmirror.com/
# electron-mirror、node-sass等组件需要单独设置镜像
npm i -g mirror-config-china --registry=https://registry.npmmirror.com
# mac下安装报无权限解决方法
# sudo npm install --unsafe-perm=true --allow-root -g mirror-config-china --registry=https://registry.npmmirror.com
```

## nvm Node版本管理工具

- nvm全名node.js version management，顾名思义是一个nodejs的版本管理工具，通过它可以安装和切换不同版本的nodejs
    - 相似的如`n`
    - 参考下文基于目录自动切换node版本
- 下载安装
    - [windows下载](https://github.com/coreybutler/nvm-windows/releases)，安装之前可能需要先卸载之前安装的Node
    - Unix: `curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash`
        - Mac M1 安装v11.4安装成功，但是安装node v10.x失败，v12.x成功
        - Mac M1 安装v14.20.1失败：需要切换成x86模式才能安装成功，参考[mac.md#M1模拟x86环境](/_posts/linux/mac.md#M1模拟x86环境)
            - 报错`libtool: unrecognized option -static'`，解决方案: https://stackoverflow.com/questions/38301930/libtool-unrecognized-option-static (前提是通过`xcode-select --install`安装了CommandLineTools, 即有次文件夹)
            - 报错`'stdio.h' file not found`，解决方案: https://blog.51cto.com/u_15639793/5297367 (3个步骤都要执行)
            - 报错`clang: error: linker command failed`，**暂未解决**
                - https://stackoverflow.com/questions/65251887/clang-7-error-linker-command-failed-with-exit-code-1-for-macos-big-sur
- 使用

```bash
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
# 查看可用LTS node版本
nvm ls-remote --lts
# 安装指定版本Node：nvm install <version> [arch]
nvm install 16.20.2
# 查看本地安装的Node版本，*号代表当前使用版本
# MAC M1 安装失败，需要切换成x86模式才能安装成功，参考[mac.md#M1模拟x86环境](/_posts/linux/mac.md#M1模拟x86环境)
nvm ls
# 使用某个Node版本。切换不同版本之后，之前版本安装的全局包不会丢失(存放在nvm安装目录对应的node版本文件夹下)，但是也不能再当前版本中使用
nvm use v16.20.2
# 设置系统默认版本
nvm alias default v16.20.2

## 常用版本
# vue2使用 lts/dubnium -> v10.24.1 (npm v6.14.12)
# vue3使用 lts/gallium -> v16.20.2 (npm v8.19.4)
```
- 基于目录自动切换node版本
    - 使用avn工具: https://segmentfault.com/a/1190000040908989
    - 使用自定义脚本: https://stackoverflow.com/questions/23556330/run-nvm-use-automatically-every-time-theres-a-nvmrc-file-on-the-directory
        - 在`.zshrc`或`.bashrc`目录创建脚本
        - 在需要切换node版本的目录创建`.nvmrc`文件，并写入对应版本如`v16.19.0`
        - 此时打开此目录命令行就会自动执行命令进行node切换

## npm 包管理工具

### npm安装及镜像

- **安装node的时候会默认包含npm**
    - `npm install npm@latest -g` 更新npm
    - `npm -v` 查看npm版本
- 设置镜像

```bash
# 大部分组件通过npm设置为淘宝镜像即可加速，但是像electron-mirror、node-sass等组件需要额外设置镜像地址配置到`~/.npmrc`才能成功下载。具体[参考下文mirror-config-china](#mirror-config-china)
npm get registry # 查看镜像
npm config set registry https://registry.npmmirror.com/ # 设置为淘宝镜像
npm config set registry https://registry.npmjs.org/ # 设置为官方镜像
npm config list # 查看配置

# 查看全局npm包未知
npm root -g
```
- 或者安装[cnpm](http://npmmirror.com/)镜像(淘宝镜像下载较快)：`npm install -g cnpm --registry=https://registry.npmmirror.com`
    - `cnpm install <pkg>` 安装模块

### .npmrc文件

- `.npmrc` 可以理解成npm running cnfiguration，即npm运行时配置文件
- .npmrc 配置文件的优先级
    - 临时配置(如`npm --registry=https://registry.npmmirror.com [npm命令]`)
    - 项目配置文件: /project/.npmrc
    - 用户配置文件: ~/.npmrc (可通过`npm config get userconfig`获取)
    - 全局配置文件: $PREFIX/etc/npmrc (可通过`npm config get prefix`获取全局文件路径)
    - npm安装包默认的路径: /path/to/npm/npmrc
- 配置(以key=value的形式存储)

```bash
# 以@test开头的包从 registry=https://npm.xx.com 这里下载，其余全去淘宝镜像下载
registry=https://registry.npmmirror.com
@test:registry=https://npm.xx.com
# 设置 SASS 镜像源，效果与 SASS_BINARY_SITE=https://registry.npmmirror.com/-/binary/node-sass npm install node-sass 相同
sass_binary_site=https://registry.npmmirror.com/-/binary/node-sass

# 可以使用环境变量; 对于一些私有仓库(如Nexus)则必须设置always-auth才能进行拉取和推送; _auth为私有仓库秘钥(可通过`echo -n 'username:password' | openssl base64`获取)
registry=${CORP_NEXUS_NPM}
always-auth=true
_auth=${CORP_NEXUS_NPM_PASSWORD}
```
- 配置用户和全局配置文件

```bash
# 增加或删除某个配置
# npm config set registry https://registry.npmmirror.com
npm config set registry https://registry.npmmirror.com
npm config delete registry

# 设置全局配置文件
# npm config set registry https://registry.npmmirror.com -g
npm config set registry https://registry.npmmirror.com -g
```

### 查看包/安装包/启动项目

- NPM包分析工具
    - CND访问
        - 国内的CND一般从 https://cdnjs.com/ 上同步的，但是CNDJS上的NPM包不全
        - **国内支持所有NPM的(类似unpkg)**
            - 饿了么: npm.elemecdn.com、github.elemecdn.com
                - https://npm.elemecdn.com/@sqbiz/wplugin-tinymce-vue@1.0.0-biz-minions/lib/WpluginTinymceVue.umd.min.js
            - 知乎: unpkg.zhimg.com
        - 基于国外 `https://unpkg.com/<package>@<version>/<file>`
            - 如: https://unpkg.com/@sqbiz/wplugin-tinymce-vue@1.0.0-biz-minions/lib/WpluginTinymceVue.umd.min.js
        - 基于国外 `https://cdn.jsdelivr.net/npm/<package>@<version>/<file>`
            - 如查找https://www.jsdelivr.com/package/npm/@tarojs/taro
    - [npm包源码在线查看工具](https://uiwjs.github.io/npm-unpkg/), npm官网也提供源码查看功能
    - [npm软件包的体积和加载性能在线分析工具](https://bundlephobia.com/)
    - [npm依赖在线分析工具(显示有点乱)](http://npm.anvaka.com/)
        - 本地可使用`npm ls > tree.log`查看，参考下文
        - 参考：https://www.cnblogs.com/shengulong/p/9463435.html

```bash
npm -h
npm help install


# 查看模块信息
npm view vue
# 查看模块历史版本
npm view vue versions
# 查看对应版本信息
npm view vue@2.7.13
# 查看对应版本对node版本的最低限制
npm view vue@2.7.13 engines
# 查看对应版本的依赖
npm view vue@2.7.13 dependencies


## 列出所有依赖
npm ls # 列出依赖树，默认是顶级
npm ls --depth=10 # 列出依赖树深度
npm ls webpack # 查看依赖此包的列表
npm ls > tree.log # 记录到文件
npm ls -g # 查看全局依赖
npm ll # 列出依赖和介绍
# 使用插件，查看npmjs网站上的包的依赖(无需下载安装项目，但是速度极慢)
# npm install -g npm-remote-ls
# npm-remote-ls webpack


## 安装xxx(在当前项目安装)，**更新模块也是此命令**
npm install <pkg>
npm install [<@scope>/]<pkg>@<version>
# npm i <pkg> # 简写方式
# -g 全局安装。如果以Windows管理员运行的命令行，则会安装在nodejs安装目录的node_modules目录下；如果以普通用户运行的命令行，则会安装在用户的 AppData/Roaming/npm/node_modules 的目录下。建议以管理员运行
npm install <pkg> -g
# --save (简写`-S`) 自动将依赖更新到package.json文件的dependencies(依赖)中
# --save-dev(简写`-D`) 自动将依赖更新到package.json文件的devDependencies(运行时依赖)中
npm install <pkg> -S
npm install <pkg> -D
# 按照本地项目(最终会已相对路径保存到package.json中, 只适合独自开发)。功能类似npm link
npm install <folder>
# 基于git仓库进行安装，参考下文
npm install <git://url>


## 移除(全局依赖)
npm uninstall -g <pkg>


## 对于某个node项目
# 初始化项目，生成`package.json`
npm init
# 基于`package.json`安装依赖
npm install
# npm install --registry=https://registry.npmmirror.com
# npm --registry=https://registry.npmjs.org install @aezocn/report-table@1.0.5-release.1 -S
# cnpm install

# 运行 package.json 中的 scripts 属性
npm run <xxx>
npm run dev # 常见的启动项目命令(具体run的命令名称根据package.json来)
npm run build # 常见的打包项目命令(具体run的命令名称根据package.json来)


## 移除npm缓存
# 如果发现本地包的sha和远程仓库不一样，且重新安装无效，需要先清除缓存
# 然后删除`package-lock.json`(每次重新安装会校验此文件中的integrity sha512值和远程仓库中的integrity，不一致会报错，所以要先清除)，再重新安装
# 清除所有缓存，yarn可以基于某个模块单独清理
npm cache clean -f
```

### 发布包

- NPM包分析工具

```bash
## 发布包: https://blog.csdn.net/imqdcn/article/details/126569123
# 发布包时，**源必须要是npm的，如果为taobao等镜像则会出现重定向问题，可使用nrm来回切换镜像**
nrm use npm
# 查看源
npm get registry
# 登录. 输入用户名/密码, 如果提示需要输入one-time password则打开命令行中的验证链接，会进入浏览器，点击登录，进行Mac指纹验证，此时会显示随机码，输入即可
npm login
# 该指令只有登录状态才能显示当前登录名
npm whoami
# 先打包好
npm run build
# 发布. 或者基于lerna publish发布
# npm不支持发布私有包，即需要设置`"private": false`
# 如果package.json#name以`@xxx/`开头(npm scope特性)，则默认会按照私有包发布，可以增加参数`--access public`，或在package.json中增加`publishConfig: {"access": "public"}`(适用于lerna)。此时会推送到npm对应xxx组织下
npm publish
# 切回taobao源
nrm use taobao

# 删除某个包. **删除这个版本后，不能再发布同版本的包，必须要大于这个版本号的包才行**
# 命令执行成功后，展示列表会有延迟，过一会在刷新才能看到移删除结果
npm unpublish xxx@x.x.x --force

# 废弃某个包. 废弃的包除了安装时会有警示，并不影响使用
npm deprecate xxx@x.x.x '不在更新了'
```

### 自动递增版本

- npm 允许在package.json文件里面，使用scripts字段定义脚本命令
    - 比较特别的是，npm run新建的这个 Shell，会将当前目录的node_modules/.bin子目录加入PATH变量，执行结束后，再将PATH变量恢复原样
    - 这意味着，当前目录的node_modules/.bin子目录里面的所有脚本，都可以直接用脚本名调用，而不必加上路径
- [package.json参考](/_posts/web/nodejs.md#packagejson)
- 命令行修改版本号(执行命令会读取并修改package.json中的版本)

```bash
# major.minor.patch premajor/preminor/prepatch/prerelease

# version = v1.0.0
npm version patch # v1.0.1 # major.minor.patch 如果之前为稳定版，则会在对应位置+1，下级位置清空为0；如果之前为预发布版，则还会额外去掉预发布版标识
npm version minor # v1.1.0
npm version major # v2.0.0

npm version prepatch # v2.0.1-0 # 如果之前为稳定版，则会先按照 major.minor.patch 的规律 +1，再在版本末尾加上预发布标识`-0`
npm version preminor # v2.1.0-0
npm version premajor # v3.0.0-0
npm version premajor # v4.0.0-0 # 重复运行 premajor 则只增加 major.minor.patch，且 prepatch/preminor 同理
npm version prerelease # v4.0.0-1 # 如果没有预发布号，则增加预发布号为 `-0`；如果之前为预发布版本，则对预发布版 +1
npm version prerelease --preid=alpha # v4.0.0-alpha.0 (预发布推荐方式) # npm 6.4.0 之后，可以使用 --preid 参数，取值如：alpha/beta
npm version 1.0.0-alpha.1 # 1.0.0-alpha.1 # 直接指定版本

# version = v4.0.0-1
npm version minor # v4.0.0 # 如果有预发布版本，则将预发布版本去掉。且如果下级位置为0，则不升级中号；如果下级位置不为0，则升级中号，并将下级位置清空。major同理
# version = v4.0.1-1
npm version minor # v4.1.0
```

### 其他特性

- npm link 本地库文件关联
    - 参考[vue.md#打包与导入](/_posts/web/vue.md#打包与导入)
    - 其他如npm link引用本地模块的方法参考：https://blog.csdn.net/zhangxin09/article/details/119344515

```bash
# 将当前包关联到本地全局路径
npm link
# npm list -g --depth 0 # 查看全局安装的包

# npm link用来在本地项目和本地npm模块之间建立连接，可以在本地进行模块测试
# npm link xxx之后eslint报错，可在主项目中增加`.eslintignore`文件，并加入`**/xxx`
# 有时候失败了，可以尝试用yarn link xxx；反之同理
npm link xxx
npm unlink xxx
```
- 传参和通配符
    - 向 npm 脚本传入参数，要使用--标识。对于脚本`"lint": "jshint **.js"`，执行`npm run lint`命令传入参数，必须写成`npm run lint --  --reporter checkstyle > checkstyle.xml`
    - 上面代码中，*表示任意文件名，**表示任意一层子目录；如果要将通配符传入原始命令，防止被 Shell 转义，要将星号转义，如`"test": "tap test/\*.js"`
- 变量

    ```json
    "script": {
        // 通过`npm_package_`前缀，npm 脚本可以拿到package.json里面的字段。如: npm_package_scripts_prebuild 可以拿到上文属性值
        // 通过`npm_config_`前缀，拿到 npm 的配置变量，即`npm config get xxx`命令返回的值。注意，package.json里面的config对象，可以被环境变量覆盖
        "view": "echo $npm_config_tag",
        // `env`命令可以列出所有环境变量
        // 只要执行 vue-cli-service build 则 process.env.NODE_ENV='production'
        "lib": "vue-cli-service build --target lib --dest lib --name WpluginVariantForm install.js"
    }
    ```
    - `process.env.npm_config_argv`
        - 如执行`npm run lib` 则上述参数为字符串`'{"remain":[],"cooked":["run","lib"],"original":["run", "lib"]}'`，可通过`JSON.parse(process.env.npm_config_argv).original`拿到原始命令参数。但是如果是cnpm执行则获取的参数顺序可能不一样
    - `process.argv`
        - 如执行`npm run build --target lib` 则上述参数为数组`['/usr/local/bin/node', '/Users/smalle/demo/node_modules/.bin/vue-cli-service', 'build', '--target', 'lib', '--dest', 'lib', '--name', 'WpluginVariantForm', 'install.js']`
- 执行顺序
    - `npm run script1.js & npm run script2.js` 并行执行
    - `npm run script1.js && npm run script2.js` 顺序执行
- 钩子

    ```json
    "script": {
        // 钩子: npm 脚本有pre和post两个钩子
        // 用户执行npm run build的时候, 相当于执行 npm run prebuild && npm run build && npm run postbuild
        // process.env.npm_lifecycle_event 可获取当前运行的脚本名称
        "prebuild": "echo I run before the build script",
        "build": "cross-env NODE_ENV=production webpack",
        "postbuild": "echo I run after the build script",
    }
    ```
- 默认值
    - `npm run start`的默认值是node server.js，前提是项目根目录下有server.js这个脚本
    - `npm run install`的默认值是node-gyp rebuild，前提是项目根目录下有binding.gyp文件

### 基于GitHub-Packages创建npm私有库

- 参考: https://www.jianshu.com/p/9b7c2d9b30b3
- 此方法产生的npm包，不会出现在npm官网上。且只支持私有库
- 模块package.json中增加如

```json
{
    // 必须以@<github用户名>/开头，后为该package名称
    "name": "@aezocn/report-table",
    "repository": {
        "type": "git",
        "url": "git+https://github.com/aezocn/npm-repo.git"
        //,"directory": "packages/my-name"
    },
    "publishConfig": {
        "access": "public"
        // 不要定义此registry配置，否则--registry命令行参数都无法覆盖
        // ,"registry": "https://npm.pkg.github.com/aezocn"
    }
}
```
- 创建脚本`github-npm-publish.sh` (脚本中的github密码使用token代替，可在github个人中心中创建token)

```bash

#!/bin/bash
# 登录
/usr/bin/expect<<-EOF
set timeout 60
spawn npm login --registry=https://npm.pkg.github.com
expect "Username: " {send "$SQ_GITHUB_NPM_USERNAME\r"}
expect "Password: " {send "$SQ_GITHUB_NPM_PASSWORD\r"}
expect "Email:" {send "$SQ_GITHUB_NPM_EMAIL\r"}
expect eof
EOF
# 发布
npm run build
npm publish --registry https://npm.pkg.github.com/aezocn
```
- 发布完成在aezocn的主页-Packages中会显示
- 使用
    - 在应用项目中创建`.npmrc`，并设置镜像(此处单独设置aezocn开头的包此使用此镜像进行拉取)
    - 然后`npm i`即可

```bash
@aezocn:registry=https://npm.pkg.github.com/aezocn
```

### 基于Nexus搭建私有仓库

- 参考[基于nexus实现npm私有仓库](/_posts/java/maven.md#基于nexus实现npm私有仓库)

### 基于git仓库进行安装

- 参考：https://blog.csdn.net/xiaolinlife/article/details/119760310
- 创建私有包package.json

```json
{
    // import ReportTable from 'report-table' 的入口文件
    "main": "./lib/report-table.umd.min.js",
    "scripts": {},
    // 项目包含的文件或目录. (通过git)安装时，只会将此处指定的文件下载到本地
    "files": [
        "src",
        "lib"
    ],
    // 一般公司的非开源项目，都会设置 private 属性的值为 true，这是因为 npm 拒绝发布私有模块，通过设置该字段可以防止私有模块被无意间发布出去
    "private": true
}
```
- 打包项目到lib包中，并将项目上传到git仓库
- 应用项目安装此模块

```bash
# 如果是公开项目则可省略用户名密码(私有项目不填则在安装是需要输入仓库密码)
# 其中 #1.0.0 可省略，则默认是 master 分支. # 后面可使用 branch/tag
npm install git+https://myusername:mypassword@gitlab.com/test/demo.git#1.0.0

# 如果默认是master等, 当包更新后, 重新npm install不会更新, 解决如下 https://cn.horecapolis.info/716438-make-npm-fetch-latest-package-LILLEF
# 法一: 删除后重新安装
rm -rf node_modules/mymod npm install
# 法二: 通过 package.json 脚本重新安装
"scripts": { "update:mymod": 'npm install git+ssh://git@GIT_URL_HERE#master' } 
```

## yarn 包管理工具

- 官网：[https://yarnpkg.com/zh-Hans/](https://yarnpkg.com/zh-Hans/)
- 安装 `npm install -g yarn`，通过官网的`msi`容易报'yarn' 不是内部或外部命令，也不是可运行的程序
- 类似于`npm`，基于`package.json`进行包管理
- 设置镜像
    
```bash
yarn config get registry # 查看镜像
yarn config set registry https://registry.npmmirror.com/ # 设置为淘宝镜像
# yarn config set registry https://registry.npmjs.org/ # 设置为官方镜像
yarn config list # 查看配置
```
- 使用

```bash
# 查看版本 
yarn -v

# 初始化新项目 (新建package.json)
yarn init

# 添加依赖包
yarn add [package]
yarn add [package]@[version]
yarn add [package]@[tag]

# 将依赖项添加到不同依赖项类别，分别添加到 devDependencies、peerDependencies 和 optionalDependencies：
yarn add [package] --dev
yarn add [package] --peer
yarn add [package] --optional

# 升级依赖包
yarn upgrade [package]
yarn upgrade [package]@[version]
yarn upgrade [package]@[tag]

# 移除依赖包
yarn remove [package]

# 安装项目的全部依赖
yarn # 或 yarn install

# 运行package.json里面的脚本
yarn run dev

# link
yarn link [xxx]
```

## pnpm 包管理工具

- [pnpm](https://pnpm.io/)
- performant npm，意味"高性能的 npm"，pnpm由npm/yarn衍生而来
- 速度快、节约磁盘空间、支持monorepo、安全性高

```bash
# 安装
npm i pnpm -g
pnpm -v
# 查看源
pnpm config get registry
# 切换淘宝源
pnpm config set registry https://registry.npmmirror.com
pnpm install
pnpm run dev

# --filter 过滤包名. 在如 pnpm-workspace.yaml 指定的工作空间中查找package.json中的包名，此时相当于同时执行这两个包的dev命令
pnpm --filter "runtime-vue3" --filter "tmagic-playground" dev

# pnpm默认包含所有子目录，指定此文件进行指定和排除目录(但是根目录下的package目录也总是被包含)
pnpm-workspace.yaml
```

## nrm 镜像管理工具

- nrm 是一个 npm 源管理器，允许你快速地在 npm源间切换
- 设置npm镜像为taobao镜像

    ```bash
    npm set registry https://registry.npmmirror.com/
    npm config ls # 查看配置
    ```
- nrm使用

```bash
# 安装
npm install -g nrm

nrm ls # 查看可选源（带*号即为当前使用源）. 默认包含npm、yarn、cnpm、taobao等
nrm use taobao # 切换为taobao源
nrm add myrepo http://192.168.6.130/repository/npm-public/ # 添加源
nrm del myrepo # 删除源
nrm test npm # 测试源
```

## mirror-config-china

- 大部分组件通过npm设置为淘宝镜像即可加速，但是像electron-mirror、node-sass等组件需要额外设置镜像地址配置到`~/.npmrc`才能成功下载，此插件将常用组件的镜像地址全部加入到了上述文件夹
- 250214貌似有问题: 生成的仍然是npm.taobao.org域名(目前已经改成了npmmirror.com)

```bash
# https://www.npmjs.com/package/mirror-config-china
# 安装
npm i -g mirror-config-china --registry=https://registry.npmmirror.com
# 检查是否安装成功。会往用户配置文件(~/.npmrc)中写入electron-mirror、node-sass等组件的镜像源为淘宝镜像
npm config list
# 之后使用 npm install 安装即可

# 为项目生成(镜像)配置文件(写入到.npmrc中)
mirror-config-china --registry=https://registry.npmmirror.com
```

## npx Node包执行工具

- npm 从5.2版开始，增加了 npx 命令，用来执行Node包命令
  - npm内置此工具，或手动安装`npm install -g npx`
- 使用 [^1]

```bash
## 调用项目安装的模块（会到node_modules/.bin路径和环境变量$PATH里面去检查命令）
# 假设项目安装了mocha，之前需要执行 node-modules/.bin/mocha --version
npx mocha --version

## 避免全局安装模块。除了调用项目内部模块，npx 还能避免全局安装的模块
# 如，此时create-react-app这个模块是全局可访问的，npx 可以随处运行它，但不用进行全局安装。代码运行时，npx 将create-react-app下载到一个临时目录，使用以后再删除。所以，以后再次执行上面的命令，会重新下载create-react-app
npx create-react-app my-react-app # 运行临时下载的命令
npx uglify-js@3.1.0 main.js -o ./dist/main.js # 指定版本
npx --no-install http-server # --no-install：让 npx 强制使用本地模块，不下载远程模块。如果本地不存在该模块，就会报错
npx --ignore-existing create-react-app my-react-app # --ignore-existing：忽略本地的同名模块，强制安装使用远程模块
npx node@0.12.8 -v # 使用不同版本的Node。原理是从 npm 下载这个版本的 node，使用后再删掉。某些场景下，这个方法用来切换 Node 版本，要比 nvm 那样的版本管理器方便一些
npx -p node@0.12.8 node -v # -p参数用于指定 npx 所要安装的模块。因此为先指定安装node，再执行node -v
npx -p lolcatjs -p cowsay -c 'cowsay hello | lolcatjs' # 如果 npx 安装多个模块，默认情况下，所执行的命令之中，只有第一个可执行项会使用 npx 安装的模块，后面的可执行项还是会交给 Shell 解释。此时使用 -c 表示两个命令均由npx解释
```

## vue 命令行工具(vue-cli)

- 参考[vue.md#vue-cli](/_posts/web/vue.md#vue-cli)

```bash
# 可选安装，只是为了快捷创建项目，或管理项目插件. mac需要root账号安装
npm install -g @vue/cli
vue --version # @vue/cli 4.3.0
```

## lerna多包管理器

- [lerna](https://github.com/lerna/lerna)
- [在一个工程下管理多个npm包](https://blog.csdn.net/yexudengzhidao/article/details/117706386)

```bash
# 目前最新版本为6.0.1, v5.6.2 要求node v14.15; v3.22.1 要求node v6.9.0
npm install lerna@3.22.1 -g
lerna -v

## 初始化
# 在项目下初始化lerna配置 => 创建 lerna.json 文件，参考下文
lerna init # --packages="packages/*"
# --independent: 可选。独立模式允许具体维护每个包的版本，包的版本由每个包的package.json的version字段维护；或者将lerna.json中的version设置为independent(如果为具体版本值，则所有的包都使用一套版本递增)
# independent模式下执行 lerna publish 会需要选择每个包的版本，否则只需要选择一次统一的版本
lerna init --independent # 简写 lerna init -i
# 添加一个package包
lerna create core
# 查看lerna.json#packages配置的目录下的package.json文件定义的包
lerna list

## 包管理(v7不在支持，可使用npm代替：https://lerna.js.org/docs/legacy-package-management#replacing-your-usage-of-lerna-bootstraplerna-link)
# 给所有模块添加第三方模块
lerna add lodash
# 单独给某个模块添加第三方模块
lerna add jquery --scope=core
# 并不会将 pkg1 安装到 pkg2 的 node_modules 里，而是通过 symlink 的形式进行关联
# npm install pkg1 -w pkg2 # v7可使用，在项目根目录运行
lerna add pkg1 --scope=pkg2
# 会重新安装所有依赖
lerna bootstrap
# 删除所有包中的node_modules
# lerna clean

## 多模块本地调试(v7不在支持，内部包会自动link)
# 需要将依赖包写入到主模块中
lerna link

## 发布包: https://zhuanlan.zhihu.com/p/372889162
# 需要提交所有代码，且需要确保npm已登录和切回成官方镜像
# nrm use npm # 之后可切回来 nrm use taobao
# 默认每次会把所有的包都发布一遍(包含没有修改的)，优化方案可参考[Lerna独立模式下如何优雅的发包](https://juejin.cn/post/7012622147726082055)
lerna publish
# 如果发布失败，可重新推送
# 会把当前标签中涉及的NPM包再发布一次，PS：不会再更新package.json，只是执行npm publish
lerna publish from-git
# 会自动比较本地package.json和远端的该文件；如果没修改代码的也不会推送，如果修改了代码但是没有修改package.json中的版本号则会发布失败: Cannot publish over previously published version
lerna publish from-package

# 执行命令，在每个包下都会执行
lerna run <script> -- [..args]
lerna exec -- <command> [..args]
```
- lerna.json 说明

```js
{
    "useWorkspaces": true, // 使用 workspaces 配置。此项为 true 的话，将使用 package.json 的 "workspaces"，下面的 "packages" 字段将不生效
    "version": "0.1.0", // 所有包版本号，独立模式-"independent"
    "npmClient": "yarn", // npm client，可设置为 cnpm、yarn 等
    "packages": [ // 包所在目录，可指定多个
        "packages/*"
    ],
    "command": { // lerna 命令相关配置
        "publish": { // 发布相关
            "ignoreChanges": [ // 指定文件或目录的变更，不触发 publish
                ".gitignore",
                "*.log",
                "*.md"
            ]
        },
        "bootstrap": { // bootstrap 相关
            "ignore": "npm-*",  // 不受 bootstrap 影响的包
            "npmClientArgs": [ // bootstr 执行参数
                "--no-package-lock"
            ]
        }
    }
}
```

## 开发库

### babel

- [babeljs中文网](https://www.babeljs.cn)
- `babel`(@babel/core) 是一个转码器，可以将es6，es7转为es5代码
    - Babel默认只转换新的JavaScript句法（syntax），而不转换新的API，比如Iterator、Generator、Set、Maps、Proxy、Reflect、Symbol、Promise等全局对象，以及一些定义在全局对象上的方法（比如Object.assign）都不会转码
    - 所以为了使用完整的 ES6 的API，我们需要另外安装：babel-polyfill 或者 babel-runtime [^2]
        - `@babel/polyfill` 会把全局对象统统覆盖一遍，不管你是否用得到。缺点：包会比较大100k左右。如果是移动端应用，要衡量一下。一般保存在dependencies中
        - `babel-runtime` 可以按照需求引入。缺点：覆盖不全。一般在写库的时候使用。建议不要直接使用babel-runtime，因为transform-runtime依赖babel-runtime，大部分情况下都可以用`transform-runtime`预设来达成目的
- [core-js](https://github.com/zloirock/core-js) 是 babel-polyfill、babel-runtime 的核心包，他们都只是对 core-js 和 regenerator 进行的封装。core-js 通过各种奇技淫巧，用 ES3 实现了大部分的 ES2017 原生标准库，同时还要严格遵循规范。支持IE6+
    - core-js 组织结构非常清晰，高度的模块化。比如 `core-js/es6` 里包含了 es6 里所有的特性。而如果只想实现 promise 可以单独引入 `core-js/features/promise`
- babel配置文件可为 `.babelrc` 或 `babel.config.js`(v7.8.0)

    ```js
    // babel.config.js
    module.exports = {
        presets: ['@vue/cli-plugin-babel/preset'],
        plugins: [
            // 一般在写库的时候使用，包含了 babel-runtime
            // 配置了 transform-runtime 插件，就不用再手动单独引入某个 `core-js/*` 特性，如 core-js/features/promise，因为转换时会自动加上而且是根据需要只抽离代码里需要的部分
            "transform-runtime",
            
            // 基于vue的预设
            // "@vue/app",
        ]
    }

    // .babelrc
    {
        "presets": [
            "@vue/app"
        ],
        "ignore": ["**/report-table.umd.min.js"]
    }
    ```
- `@babel/cli` 在命令行中使用babel命令对js文件进行转换。如`babel entry.js --out-file out.js`进行语法转换
- 插件
    - 基于Babel的插件参考：https://www.babeljs.cn/docs/plugins
- 预设(Presets, 一批插件的组合)
    - 需要基于某个环境进行开发，如typescript，则需手动安装一堆 Babel 插件，此时可以使用 Presets(包含了一批插件的组合)。可以设置到presets或plugins节点
    - 官方 Preset 已经针对常用环境编写了一些 preset。其他社区定义的预设可在[npm](https://www.npmjs.com/search?q=babel-preset)上获取
        - `@babel/preset-env` 对浏览器环境的通用支持(es6转es5)
        - `@babel/preset-react` 对 React 的支持
        - `@babel/preset-typescript` 对 Typescript 支持，参考[typescript.md#Webpack转译Typescript现有方案](/_posts/web/typescript.md#Webpack转译Typescript现有方案)
        - `@babel/preset-flow` 如果使用了 [Flow](https://flow.org/en/)，则建议您使用此预设（preset），Flow 是一个针对 JavaScript 代码的静态类型检查器
        - `@vue/app` 对 Vue 的支持
- 常见安装

```bash
# 语法转换
npm install --save-dev @babel/core @babel/cli @babel/preset-env
# 通过 Polyfill 方式在目标环境中添加缺失的特性
npm install --save @babel/polyfill
```

### npm-run-all

- `npm install npm-run-all --save-dev` 安装
- `npm-run-all` 提供了多种运行多个命令的方式，常用的有以下几个
    - `--serial`: 多个命令按排列顺序执行，例如：`npm-run-all --serial clean build:**` 先执行当前package.json中 npm run clean 命令, 再执行当前package.json中所有的`build:`开头的scripts
    - `--parallel`: 并行运行多个命令，例如：npm-run-all --parallel lint build
    - `--continue-on-error`: 是否忽略错误，添加此参数 npm-run-all 会自动退出出错的命令，继续运行正常的
    - `--race`: 添加此参数之后，只要有一个命令运行出错，那么 npm-run-all 就会结束掉全部的命令
- 案例

```js
"scripts": {
    "dev-all": "npm-run-all --parallel dev:*",
    "dev:demo1": "cd example/demo1 && npm run dev",
    "dev:demo2": "cd example/demo2 && npm run dev",
}
```
- 也可使用[基于`node run.js`的模式启动文件](/_posts/web/electron.md#使用案例)

### rollup.js

- Rollup 是一个 JavaScript 模块打包器，可以将小块代码编译成大块复杂的代码，例如 library 或应用程序
- [rollupjs](https://cn.rollupjs.org/)

### Vite

- Vite 与 Next.js
    - Vite 是构建工具，Next.js 是应用框架。Vite 可以作为 Next.js 的构建工具，提供更快的开发体验。不过目前 Next.js 默认使用的是 Webpack 进行构建，但也有社区插件支持使用 Vite
    - Next.js基于React框架
- React 与 Vue: 它们都是用于构建用户界面的框架，但设计理念和语法有所不同
- Vite 与 React、Vue
    - Vite 可以与 React 和 Vue 很好地集成，为它们提供快速的开发环境。Vite 官方提供了针对 React 和 Vue 的模板，方便开发者快速搭建项目

### patch-package手动npm包打补丁

- 参考：https://juejin.cn/post/6962554654643191815

### postcss

- https://github.com/postcss/postcss
- 用 JavaScript 工具和插件转换 CSS 代码的工具
- postcss插件编写
    - PostCSS 是利用 JS 对CSS 代码进行转换处理。借助各种 PostCSS 插件可以用来为CSS 属性进行增删改查等操作(如: 添加浏览器兼容前缀、px转rem...), PostCSS 底层已经将 CSS 转义成 AST, 而我们开发一个 PostCSS 插件其实就是通过 JS 操作这个 AST 即可。参考：https://juejin.cn/post/7126455957508325407
    - [在线 CSS to AST](https://astexplorer.net/#/2uBU1BLuJ1)
    - PostCSS 8 插件不兼容 PostCSS 7 版本
    - 事件(钩子)参考：https://postcss.org/api/#plugin
        - Root: CSS 语法树, 代表 css 文件
        - AtRule: 以@开头的内容(如: @media(screen){})
        - Rule: 已声明的选择器(如: input, button{})
        - Declaration: 属性名-属性值(如: color: red)
        - Comment: 注释
    - 案例参考(不用打包，提交npm安装即可)：https://github.com/postcss/postcss-focus
    - 初始化一个插件`npx postcss-plugin-boilerplate --npm postcss-mytest`

## 格式规范化

### eslint格式化

- vscode等编辑安装eslint插件，相关配置参考[vscode.md#插件推荐](/_posts/extend/vscode.md#插件推荐)
- 项目直接安装
- 基于vue-cli安装，参考：https://eslint.vuejs.org/
    - @vue/cli eslint插件使用参考: https://www.cnblogs.com/qq3279338858/p/16492830.html
    - `vue add eslint` 基于vue安装插件，选择Standard、Lint on save
    - **安装完成默认会自动执行`vue-cli-service lint`，即对所有文件进行格式修复(只会修复部分，剩下的仍然需要人工修复)**，实际执行命令为 `eslint --fix --ext .js,.vue src`
    - 安装后会在package.json中增加如下配置，安装对应的包到项目目录，并增加文件`.eslintrc.js`和`.editorconfig`

        ```json
        "scripts": {                                            
            "lint": "vue-cli-service lint",
        },
        "devDependencies": {
            "@vue/cli-plugin-eslint": "~4.5.0",
            "@vue/eslint-config-standard": "^5.1.2",
            "eslint": "^6.7.2",
            "eslint-plugin-import": "^2.20.2",
            "eslint-plugin-node": "^11.1.0",
            "eslint-plugin-promise": "^4.2.1",
            "eslint-plugin-standard": "^4.0.0",
            "eslint-plugin-vue": "^6.2.2"
        }
        ```
- 支持多种配置文件格式：.eslintrc.js、.eslintrc.yaml、.eslintrc.json、.eslintrc(弃用)、在package.json增加eslintConfig属性。且采用就近原则
- `.eslintrc.js` 放在vue项目根目录，详细参考：https://cn.eslint.org/ [^10]

```js
// 不填任何规则，相当于禁用了eslint(对于vscode安装了插件，但是项目又不想启动校验的情况)
module.exports = {}

// 规则说明
module.exports = {
  root: true,
  extends: ['plugin:vue/essential', '@vue/standard'],
  rules: {
    // allow debugger during development
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'no-undef': 'off',
    'camelcase': 'off',
    // 允许未使用的变量
    'no-unused-vars': 'off',
    // 不强制使用 ===
    'eqeqeq': 'off',
    // 'eqeqeq': ['error', 'smart'],
    // 允许对象中出现结尾逗号(默认不允许)
    "comma-dangle": 'off',
    // function函数名和()间必须增加空格
    // 'space-before-function-paren': ['error', {
    //     'anonymous': 'always',
    //     'named': 'always',
    //     'asyncArrow': 'always'
    // }],
    // 如果function函数名和()间增加空格会和Prettier冲突, 此处关闭空格校验
    'space-before-function-paren': 0,
    // A && B换行时，符号在行头。https://eslint.org/docs/rules/operator-linebreak
    'operator-linebreak': ['error', 'before'],
    // allow async-await
    'generator-star-spacing': 'off',

    // 允许未使用的变量
    'vue/no-unused-vars': 'off',
    // v-if和v-for可一起使用
    'vue/no-use-v-if-with-v-for': 'off',
    'vue/no-parsing-error': [2, {
      'x-invalid-end-tag': false
    }],
  },
  parserOptions: {
    parser: 'babel-eslint'
  }
}
```
- `.eslintignore` 放在vue项目根目录

```bash
# 不进行校验的的文件或文件夹
/build/
/config/
/dist/
/*.js
/test/unit/coverage/
/node_modules/*
/dist*
**/report-table.umd.min.js

src/components
```
- 代码中不进行校验

```js
/* eslint-disable */
// ESLint 在校验的时候就会跳过后面的代码

/* eslint-disable no-new */
// ESLint 在校验的时候就会跳过 no-new 规则校验
```

### .prettierrc/.jsbeautifyrc/.editorconfig格式化

- Eslint、.editorconfig等区别
    - Eslint 更偏向于对语法的提示，如定义了一个变量但是没有使用时应该给予提醒
    - .editorconfig 更偏向于简单代码风格，如缩进等
        - .prettierrc 更偏向于代码美化
    - 二者并不冲突，同时配合使用可以使代码风格更加优雅
- **Prettier插件**
    - 文件需要配合插件使用，如vscode的[Prettier插件](https://prettier.io/)(推荐)
    - 相应的配置文件(选一个即可)
        - `.prettierrc`
        - `prettier.config.js` 项目根目录配置文件，常用配置参考下文
        - `package.json`中的`prettier`属性
    - 可增加脚本进行批量格式化代码 `"prettier": "prettier --write '**/*.{js,css,scss,less,ts,vue,html}'"` (安装 eslint-plugin-prettier 和 eslint-config-prettier 模块)
- `.jsbeautifyrc` 代码格式化
    - 文件需要配合插件使用，如vscode的`Beautify`插件
- `.editorconfig`文件需要配合插件使用，如vscode的`Editorconfig`插件
    - 该插件的作用是告诉开发工具自动去读取项目根目录下的 .editorconfig 配置文件，如果没有安装这个插件，光有一个配置文件是无法生效的
    - 此插件配置的格式优先于vscode配置的，如缩进；常用配置参考下文
- prettier.config.js 常用配置

```js
module.exports = {
  printWidth: 140, // 每行代码长度（默认80, 适配1366屏幕; 1920可设置成140)
  tabWidth: 2, // 每个tab相当于多少个空格（默认2）ab进行缩进（默认false）
  useTabs: false, // 是否使用tab
  semi: false, // 声明结尾是否使用分号(默认true)
  vueIndentScriptAndStyle: false,
  singleQuote: true, // 使用单引号（默认false）
  quoteProps: 'as-needed',
  bracketSpacing: true, // 对象字面量的大括号间使用空格（默认true）
  trailingComma: 'none', // 多行使用拖尾逗号（默认none）
  jsxSingleQuote: false,
  // 箭头函数参数括号 默认avoid 可选: avoid(能省略括号的时候就省略 例如x => x) | always(总是有括号)
  arrowParens: 'always',
  insertPragma: false,
  requirePragma: false,
  proseWrap: 'never',
  // 优化html闭合标签不换行的问题. ignore: 存在span等标签格式化后出现换行空格. 参考: https://juejin.cn/post/6844904194059534350
  htmlWhitespaceSensitivity: 'strict',
  endOfLine: 'auto',
  rangeStart: 0
}
```
- `.editorconfig` 放在vue项目根目录

```ini
# http://editorconfig.org
root = true

[*]
#缩进风格：空格
indent_style = space
#缩进大小2
indent_size = 2
#换行符lf
end_of_line = lf
#字符集utf-8
charset = utf-8
#是否删除行尾的空格
trim_trailing_whitespace = true
#是否在文件的最后插入一个空行
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
```

## 前端常见文件

```json
babel.config.js     // 参考[js-tools.md#babel](/_posts/web/js-tools.md#babel)
.babelrc
.env.dev            // 参考[vue.md#vue-cli](/_posts/web/vue.md#vue-cli)。vue-cli环境变量配置文件
.env.test
.postcssrc.js
tsconfig.json       // 参考[typescript.md#tsconfig.json](/_posts/web/typescript.md#tsconfig.json)
jsconfig.json       // 解决vue文件点击后跳转(TS项目可使用tsconfig.json). https://www.cnblogs.com/leslie1943/p/13493829.html
vue.config.js       // 参考[vue.md#vue-cli](/_posts/web/vue.md#vue-cli)
.eslintrc.js        // 参考[js-tools.md#eslint格式化](/_posts/web/node-dev-tools.md#eslint格式化)
.eslintignore       // 参考[js-tools.md#eslint格式化](/_posts/web/node-dev-tools.md#eslint格式化)
.editorconfig       // 跨编辑器和IDE，保持一致的简单代码风格，就近原则（源码文件参考最近的此文件配置）。参考[js-tools.md#.editorconfig格式化](/_posts/web/node-dev-tools.md#.prettierrc/.jsbeautifyrc/.editorconfig格式化)，下同
.prettierrc         // 代码格式化，同上
.jsbeautifyrc       // 代码格式化，同上
```

### jsconfig.json文件跳转配置

- 使用WebStorm完美解决所有问题
- 解决vscode下vue文件点击后跳转(TS项目可使用tsconfig.json)
    - 部分写法仍然不能跳转，如`./module/Demo` 此时可安装`别名路径跳转`插件解决
    - 而`@views/test/Test`仍然不支持，可写成`@/views/test/Test`或`@views/test/Test.vue`
    - 但是`@comp/mod/Dmoe`则不支持(@comp对应src/components)
        - 需改写成@/comp，且vue.config.js和jsconfig.json里面都设置好`@/comp`对应`src/components` 貌似有点问题
        - `@comp/mod/Dmoe.vue` 可配置jsconfig属性`"@comp/*": ["src/components/*"]`进行跳转
    - 文件必须带.vue后缀(如`import Demo from './module/Demo.vue'`)，html标签和import变量才能直接进入组件，否则只能点击from后面的链接进入组件

```js
{
  "compilerOptions": {
    "baseUrl": "./",
    "paths": {
      "@/*": ["src/*"],
      // "@/comp/*": ["src/components/*"],
    }
  },
  "exclude": ["node_modules", "dist"],
  "include": ["src/**/*"]
}
```

## 在线工具

- [StackBlitz](https://stackblitz.com/) 是一款在线 IDE(可直接运行项目)，主要面向 Web 开发者，移植了很多 VS Code 的特性与功能




---

参考文章

[^1]: http://www.ruanyifeng.com/blog/2019/02/npx.html
[^2]: https://www.dazhuanlan.com/2019/12/31/5e0b08829f823/
