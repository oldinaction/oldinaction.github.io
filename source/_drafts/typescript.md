

## 简介

- [中文Doc](https://www.tslang.cn/index.html)

## tsconfig.json

## Vue结合Typescript

- Vue组件script标签引入模块

```html
<!-- js方式 -->
<script>
import * as math from 'mathjs'
// const math = require('mathjs') // 此方式也生效
import { vexScrollPage, getDictMap } from "@/libs/util";
import ChargeItemTable from "./ChargeItemTable.vue";
import "@/style/public.less";
</script>

<!-- ts方式 -->
<script lang="ts">
import * as math from 'mathjs' // 与js引入方式存在差异，不能使用require
// 其他同js
</script>
```

## Webpack转译Typescript现有方案

- `awesome-typescript-loader`（停止更新）[^1]
- `ts-loader + babel-loader + fork-ts-checker-webpack-plugin`
    - 当 webpack 编译的时候，ts-loader 会调用 typescript（所以本地项目需要安装 typescript），然后 typescript 运行的时候会去读取本地的 tsconfig.json 文件。
    - 默认情况下，ts-loader 会进行 转译 和 类型检查，每当文件改动时，都会重新去 转译 和 类型检查，当文件很多的时候，就会特别慢，影响开发速度。所以需要使用 fork-ts-checker-webpack-plugin ，开辟一个单独的线程去执行类型检查的任务，这样就不会影响 webpack 重新编译的速度
    - 并行构建不再适合新版本的 webpack 了
        - 并行化构建有两种方式： happypack 和 thread-loader
        - 并行化构建对于 webpack 2/3 的性能有明显的提升，使用 webpack 4+时，速度提升的收益似乎要少得多
- `babel-loader + @babel/preset-typescript`
    - 当 webpack 编译的时候，babel-loader 会读取 .babelrc 里的配置，不会调用 typescript（所以本地项目无需安装 typescript），不会去检查类型。但是 tsconfig.json 是需要配置的，因为需要在开发代码时，让 idea 提示错误信息
- 问题说明
    - 使用了 TypeScript，为什么还需要 Babel
        - 大部分已存项目依赖了 babel，有些需求/功能需要 babel 的插件去实现（如：按需加载）
        - babel 有非常丰富的插件，它的生态发展得很好；babel 7 之前，需要前面两种方案来转译 TS；babel 7 之后，babel 直接移除 TS，转为 JS，这使得它的编译速度飞快
    - 为什么用了 ts-loader 后，还要使用 babel-loader
        - ts-loader 是不会读取 .babelrc 里的配置，即无法使用 babel 系列的插件，所以直接使用 ts-loader 将 ts/tsx 转成 js ，就会出现垫片无法按需加载、antd 无法按需引入的问题。所以需要用 ts-loader 把 ts/tsx 转成 js/jsx，然后再用 babel-loader 去调用 babel 系列插件，编译成最终的 js
    - 如果在使用 babel-loader + @babel/preset-typescript 这种方案时，也想要类型检查
        - 再开一个 npm 脚本自动检查类型：`"type-check": "tsc --watch"`，tsconfig.json中配置compilerOptions.noEmit=true
    - 使用 @babel/preset-typescript 需要注意有四种语法在 babel 中是无法编译的
        - namespace（已过世）
        - 类型断言：`let p1 = {age: 18} as Person;`
        - 常量枚举：`const enum Sex {man, woman}`
        - 历史遗留风格的 import/export 语法：`import xxx= require(…) 和 export = xxx`
    - Typescript 官方转向 ESLint 的原因
        - TSLint 执行规则的方式存在一些架构问题，从而影响了性能，而修复这些问题会破坏现有规则；
        - ESLint 的性能更好并且使用者较多
    - 使用了 TypeScript，为什么还需要 ESLint
        - TS 主要是用来做类型检查和语言转换的，顺带一小部分的语法检查
        - ESLint 主要是用来检查代码风格和语法错误的

## 临时

- 忽略TS报错

```bash
# 单行忽略（包含//）
// @ts-ignore

# 忽略全文
// @ts-nocheck

# 取消忽略全文
// @ts-check
```

- 打包项目时，报错`573:15 Interface 'NodeJS.Module' incorrectly extends interface '__WebpackModuleApi.Module'.`，解决如：

```json
// tsconfig.json配置如下，或者增加 compilerOptions.skipLibCheck=true
{
  "compilerOptions": {
    "types": [
      "webpack-env"
    ],
    "paths": {
      "@/*": [
        "src/*"
      ]
    }
  },
  "include": [
    "src/**/*.ts",
    "src/**/*.tsx",
    "src/**/*.vue",
    "tests/**/*.ts",
    "tests/**/*.tsx"
  ],
  "exclude": [
    "node_modules"
  ]
}
```


---

参考文章

[^1]: https://juejin.im/post/6844904052094926855#heading-0 (Webpack 转译 Typescript 现有方案)

