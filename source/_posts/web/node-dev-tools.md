---
layout: "post"
title: "Node 开发工具"
date: "2017-04-02 11:13"
categories: [web]
tags: [node, tools]
---

## npm 包管理工具

### npm安装及镜像

- **安装node的时候会默认包含npm**
    - `npm install npm@latest -g` 更新npm
    - `npm -v` 查看npm版本
- 设置镜像
    
    ```bash
    # 大部分组件通过npm设置为淘宝镜像即可加速，但是像electron-mirror、node-sass等组件需要额外设置镜像地址配置到`~/.npmrc`才能成功下载。具体[参考下文mirror-config-china](#mirror-config-china)
    npm get registry # 查看镜像
    npm config set registry https://registry.npm.taobao.org/ # 设置为淘宝镜像
    npm config set registry https://registry.npmjs.org/ # 设置为官方镜像
    npm config list # 查看配置
    ```
- 或者安装[cnpm](http://npm.taobao.org/)镜像(淘宝镜像下载较快)：`npm install -g cnpm --registry=https://registry.npm.taobao.org`
    - `cnpm install <module-name>` 安装模块

### 基本命令

```bash
## 安装xxx(在当前项目安装)，**更新模块也是此命令**
npm install <module-name>
npm install <module-name>@<version>
# npm i <module-name> # 简写方式
# -g 全局安装。如果以Windows管理员运行的命令行，则会安装在nodejs安装目录的node_modules目录下；如果以普通用户运行的命令行，则会安装在用户的 AppData/Roaming/npm/node_modules 的目录下。建议以管理员运行
npm install <module-name> -g
# --save (简写`-S`) 自动将依赖更新到package.json文件的dependencies(依赖)中
# --save-dev(简写`-D`) 自动将依赖更新到package.json文件的devDependencies(运行时依赖)中
npm install <module-name> -S
npm install <module-name> -D

## 移除(全局依赖)
npm uninstall -g <module-name>

## 对于某个node项目
# 初始化项目，生成`package.json`
npm init
# 基于`package.json`安装依赖
# npm install
# npm install --registry=https://registry.npm.taobao.org
cnpm install
# 运行 package.json 中的 scripts 属性
npm run <xxx>
npm run dev # 常见的启动项目命令(具体run的命令名称根据package.json来)
npm run build # 常见的打包项目命令(具体run的命令名称根据package.json来)
```

### npm版本管理

- package.json版本

```json
{
  "name": "test",
  // 此项目版本
  "version": "1.0.0",
  // 依赖和对应版本
  "dependencies": {
      // 波浪符号（~）：固定大、中版本，只升级小版本到最新版本
      "vue": "~2.5.13",
      // 插入符号（^）：固定大版本，升级中、小版本到最新版本。当前npm安装包默认符号
      "iview": "^2.8.0",
  }
}
```

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

## nrm 镜像管理工具

- nrm 是一个 npm 源管理器，允许你快速地在 npm源间切换
- 设置npm镜像为taobao镜像

    ```bash
    npm set registry https://registry.npm.taobao.org/
    npm config ls # 查看配置
    ```
- nrm使用

```bash
# 安装
npm install -g nrm

nrm ls # 查看可选源（带*号即为当前使用源）
nrm use taobao # 切换为taobao源
nrm add myrepo http://192.168.6.130/repository/npm-public/ # 添加源
nrm del myrepo # 删除源
nrm test npm # 测试源
```

## mirror-config-china

- 大部分组件通过npm设置为淘宝镜像即可加速，但是像electron-mirror、node-sass等组件需要额外设置镜像地址配置到`~/.npmrc`才能成功下载，此插件将常用组件的镜像地址全部加入到了上述文件夹

```bash
# https://www.npmjs.com/package/mirror-config-china
# 安装
npm i -g mirror-config-china --registry=https://registry.npm.taobao.org
# 检查是否安装成功。会往用户配置文件(~/.npmrc)中写入electron-mirror、node-sass等组件的镜像源为淘宝镜像
npm config list
# 之后使用 npm install 安装即可
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

## yarn 包管理工具

- 官网：[https://yarnpkg.com/zh-Hans/](https://yarnpkg.com/zh-Hans/)
- 安装 `npm install -g yarn`，通过官网的`msi`容易报'yarn' 不是内部或外部命令，也不是可运行的程序
- 类似于`npm`，基于`package.json`进行包管理
- 设置镜像
    
    ```bash
    yarn get registry # 查看镜像
    yarn config set registry https://registry.npm.taobao.org/ # 设置为淘宝镜像
    yarn config set registry https://registry.npmjs.org/ # 设置为官方镜像
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
yarn 或 yarn install

# 运行package.json里面的脚本
yarn run dev
```

## nvm Node版本管理工具

- nvm全名node.js version management，顾名思义是一个nodejs的版本管理工具，通过它可以安装和切换不同版本的nodejs
- [windows下载](https://github.com/coreybutler/nvm-windows/releases)，安装之前可能需要先卸载之前安装的Node
- 使用

```bash
nvm install 12.16.3 # 安装指定版本Node：nvm install <version> [arch]
nvm ls # 查看本地安装的Node版本，*号代表当前使用版本
nvm use 12.16.3 # 使用某个Node版本。切换不同版本之后，之前版本安装的全局包不会丢失(存放在nvm安装目录对应的node版本文件夹下)，但是也不能再当前版本中使用
```

## vue 命令行工具(vue-cli)

- 参考[vue.md#vue-cli](/_posts/web/vue.md#vue-cli)

```bash
npm install -g @vue/cli
vue --version # @vue/cli 4.3.0
```

## eslint格式化

- vscode等编辑安装eslint插件，相关配置参考[vscode.md#插件推荐](/_posts/extend/vscode.md#插件推荐)
- 直接安装
- 基于vue-cli安装，参考：https://eslint.vuejs.org/
    - `vue add eslint` 基于vue安装插件，选择Standard、Lint on save
    - 安装完成默认会自动执行`vue-cli-service lint`，即对所有文件进行格式修复(只会修复部分，剩下的仍然需要人工修复)
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
module.exports = {
  root: true,
  'extends': [
    'plugin:vue/essential',
    '@vue/standard'
  ],
  rules: {
    // allow async-await
    'generator-star-spacing': 'off',
    // allow debugger during development
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'vue/no-parsing-error': [2, {
      'x-invalid-end-tag': false
    }],
    'no-undef': 'off',
    'camelcase': 'off',
    // function函数名和()见增加空格
    "space-before-function-paren": ["error", {
        "anonymous": "always",
        "named": "always",
        "asyncArrow": "always"
    }],
    // 不强制使用 ===
    "eqeqeq": ["error", "smart"],
    // A && B换行时，符号在行头。https://eslint.org/docs/rules/operator-linebreak
    "operator-linebreak": ["error", "before"],
  },
  parserOptions: {
    parser: 'babel-eslint'
  }
}
```
- `.eslintignore` 放在vue项目根目录

```bash
# 不进行校验的的文件或文件夹
src/components
```

## .editorconfig格式化

- **`.editorconfig`文件需要配合插件使用，如vscode的`Editorconfig`插件**。该插件的作用是告诉开发工具自动去读取项目根目录下的 .editorconfig 配置文件，如果没有安装这个插件，光有一个配置文件是无法生效的。**此插件配置的格式优先于vscode配置的，如缩进**
- Eslint、.editorconfig、.prettierrc
    - Eslint 更偏向于对语法的提示，如定义了一个变量但是没有使用时应该给予提醒
    - .editorconfig 更偏向于简单代码风格，如缩进等
    - .prettierrc 更偏向于代码美化
    - 三者并不冲突，同时配合使用可以使代码风格更加优雅
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

## .prettierrc格式化

- `.prettierrc`文件需要配合插件使用，如vscode的`Prettier`插件







---

参考文章

[^1]: http://www.ruanyifeng.com/blog/2019/02/npx.html
