---
layout: "post"
title: "TypeScript"
date: "2020-11-01 13:06"
categories: web
tags: [js]
---

## 简介

- [官网](https://www.typescriptlang.org/)、[中文Doc](https://www.tslang.cn/index.html)

## 声明文件语法

- 示例 [^2]

```ts
// 全局变量
declare var count: number;

// 全局函数
declare function hello(greeting: string): void;
// 函数重载
declare function getPerson(id: number): Person;
declare function getPerson(name: string): Person[];

// 带属性的对象
/*
let result = myLib.hello("hello, world");
*/
declare namespace myLib {
    function hello(s: string): string;
    let num: number;
}

// 类
/*
const p = new Person("hello, world");
p.hello = "hi~";
p.showHello();

class SpecialPerson extends Person {
    constructor() {
        super("Very special person");
    }
}
*/
declare class Person {
    constructor(hello: string);

    hello: string;
    showHello(): void;
}

// 可重用类型（接口）
/*
declare function showHello(setting: PersonSetting): void; // 实现略

showHello({hello: "hello world", duration: 4000});
*/
interface PersonSetting {
  hello: string;
  duration?: number; // ? 表示可选
  color?: string;
}

// 可重用类型（类型别名）
/*
declare function showHello(g: PersonLike): void; // 实现略

class MyPerson extends Person {}

showHello("hello");
showHello(() => "hi");
showHello(new MyPerson("haha"));
*/
type PersonLike = string | (() => string) | MyPerson; // 可以为字符串/函数/MyPerson对象

// 组织类型（使用命名空间组织类型或嵌套命名空间）
/*
const p = new Person("Hello");
p.log({ verbose: true });
p.alert({ modal: false, title: "Current Greeting" });
*/ 
declare namespace PersonLog {
    interface LogOptions {
        verbose?: boolean;
    }
}
declare namespace PersonLog.Options {
    // Refer to via PersonLog.Options.Log
    interface Log {
        verbose?: boolean;
    }
    interface Alert {
        modal: boolean;
        title?: string;
        color?: string;
    }
}
```

## tsconfig.json

- 常用配置(基于vue项目)

```js
{
  "compilerOptions": {
    // 与 Vue 的浏览器支持保持一致
    "target": "es5",
    // 这可以对 `this` 上的数据 property 进行更严格的推断
    "strict": true,
    // 指定基础目录
    "baseUrl": "./",
    // 输出目录
    "outDir": "./dist/",
    // 在表达式和声明上有隐含的any类型时报错
    "noImplicitAny": false,
    // 允许编译javascript文件
    "allowJs": true,
    // 移除注释
    "removeComments": true,
    // 把 ts 文件编译成 js 文件的时候，同时生成对应的 map 文件
    "sourceMap": true,
     // 指定生成哪个模块系统代码
    "module": "esnext",
    // 启用装饰器
    "experimentalDecorators": true,
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "isolatedModules": false,
    "emitDecoratorMetadata": true,
    "noImplicitReturns": true,
    "importHelpers": true,
    "listFiles": true,
    "suppressImplicitAnyIndexErrors": true,
    "types": [
      // 打包项目时，报错`573:15 Interface 'NodeJS.Module' incorrectly extends interface '__WebpackModuleApi.Module'.`。尝试解决：增加"webpack-env"，或者增加 compilerOptions.skipLibCheck=true
      "webpack-env"
    ],
    // 项目中用到的别名(vue.config.js和此处都需要配置)
    "paths": {
      "@/*": ["*", "src/*"],
      "@model/*": ["src/model/*"],
      "_c/*": ["src/components/*"]
    },
    // 添加需要的解析的语法，否则TS会检测出错
    "lib": ["dom", "es2015", "es2015.promise", "es2016"]
  },
  // 目中需要按照typescript编译的文件路径
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

## Vue结合Typescript

- Vue项目改造成支持TS [^3]
    - 安装依赖(项目基于vue-cli@3.X创建)

        ```bash
        # @vue/cli-plugin-typescript 为解析ts语法插件，基于 ts-loader
        npm install typescript @vue/cli-plugin-typescript -D
        # Vue 相关特性的装饰(注解)
        npm install vue-class-component vue-property-decorator -S
        ```
    - 加入`tsconfig.json`文件，参考上文
    - 加入`src/shims-vue.d.ts`垫片(shims-vue文件名可随便取)

        ```js
        /**
        * 告诉 TypeScript *.vue 后缀的文件可以交给 vue 模块来处理
        * 而在代码中导入 *.vue 文件的时候，需要写上 .vue 后缀。原因还是因为 TypeScript 默认只识别 *.ts 文件，不识别 *.vue 文件
        */
        declare module "*.vue" {
            import Vue from 'vue'
            export default Vue
        }
        ```
    - 修改`main.js`为`main.ts`
        - 代码中导入 `*.vue` 文件的时候，需要写上 `.vue` 后缀
        - (可选)部分场景可能需要在`vue.config.js`或webpack增加相关配置(以vue-cli为例)

            ```js
            module.exports = {
                configureWebpack: {
                    // 入口文件
                    entry: {
                        main: ['src/main.ts']
                    }
                }
            }
            ```
    - (可选)对于额外挂载在vue原型上的变量，可使用类型增强进行声明。如在src任意目录创建`service.d.ts`（或者添加在 shims-vue.d.ts 中）

        ```ts
        import Vue from 'vue';

        declare module 'vue/types/vue' {
            interface Vue {
                $ajax: any;
                $apiUrl: string;
            }
        }
        ```
    - **vue的javascript语法转typescript语法异同**：https://www.cnblogs.com/wenxinsj/p/13297155.html

        ```ts
        import { Component, Prop, Watch, Mixins, Vue } from "vue-property-decorator";
        import CommonFunc from './CommonFunc'
        
        // 不加 @Component 注解，会报一些奇奇怪怪的错：（1）is not defined on the instance but referenced during render. Make sure that this property is reactive, either in the data option, or for class-based components, by initializing the property(说子组件的DOM中不能直接使用prop，需要data接收。实际是子组件中可直接使用prop)（2）Error in render: "TypeError: vnode.children.slice is not a function"
        // @Component // 此缩写也行
        @Component({
            components: { XXXComp }
        })
        export default class Order extends Mixins(CommonFunc) {
            @Prop({ type: String, default: "" }) init!: string;

            // data
            value: string = ''

            @Watch("tokenExpire", { immediate: true, deep: true })
            changeToken(val: "tokenExpire") {
                
            }

            // computed
            get loginUrl() {
                let { loginUrl } = this.commonHosts;
                return loginUrl;
            }

            created() {
                this.hello()
            }
        }

        // CommonFunc.ts 文件名建议大写
        import { Vue, Component, Prop, Watch, Mixins } from "vue-property-decorator";
        @Component
        export default class CommonFunc extends Vue {
            hello: any = null;

            get helloName() {
                return this['value'] + this.hello + 'Name'
            }

            hello () : void {
                console.log('hello...')
            }
        }

        ```
- Vue组件script标签引入模块

```html
<!-- js方式 -->
<script>
import * as math from 'mathjs'
// const math = require('mathjs') // 此方式也生效
</script>

<!-- ts方式 -->
<script lang="ts">
import * as math from 'mathjs' // 与js引入方式存在差异，不能使用require
</script>
```

## Webpack转译Typescript现有方案

- 方式一：`ts-loader + babel-loader` [^1]
    - **当 webpack 编译的时候，ts-loader 会调用 typescript（所以本地项目需要安装 typescript），然后 typescript 运行的时候会去读取本地的 tsconfig.json 文件**
    - vue-cli内置`ts-loader`
    - 默认情况下，ts-loader 会进行转译和类型检查，每当文件改动时，都会重新去转译和类型检查，当文件很多的时候，就会特别慢，影响开发速度。所以可以搭配 `fork-ts-checker-webpack-plugin`，开辟一个单独的线程去执行类型检查的任务，这样就不会影响 webpack 重新编译的速度。并行构建不再适合新版本的 webpack 了
        - 并行化构建有两种方式： happypack 和 thread-loader
        - 并行化构建对于 webpack 2/3 的性能有明显的提升，使用 webpack 4+时，速度提升的收益似乎要少得多
- 方式二：`babel-loader + @babel/preset-typescript`
    - **当 webpack 编译的时候，babel-loader 会读取 .babelrc 里的配置，不会调用 typescript（所以本地项目无需安装 typescript），不会去检查类型。**但是 tsconfig.json 是需要配置的，因为需要在开发代码时，让 IDE 提示错误信息
- 方式三：`awesome-typescript-loader`（停止更新）
- 问题说明
    - **使用了 TypeScript，为什么还需要 Babel**
        - 大部分已存项目依赖了 babel，有些需求/功能需要 babel 的插件去实现（如：按需加载）
        - babel 有非常丰富的插件，它的生态发展得很好；babel7 之前，只能用上述1/3两种方案来转译 TS；babel7 之后，babel 直接移除 TS，转为 JS，这使得它的编译速度飞快
    - **为什么用了 ts-loader 后，还要使用 babel-loader**
        - ts-loader 是不会读取 .babelrc 里的配置，即无法使用 babel 系列的插件，所以直接使用 ts-loader 将 ts/tsx 转成 js ，就会出现垫片无法按需加载、antd 无法按需引入的问题。所以需要用 ts-loader 把 ts/tsx 转成 js/jsx，然后再用 babel-loader 去调用 babel 系列插件，编译成最终的 js
    - **Typescript 官方转向 ESLint 的原因**
        - TSLint 执行规则的方式存在一些架构问题，从而影响了性能，而修复这些问题会破坏现有规则；
        - ESLint 的性能更好并且使用者较多
    - **使用了 TypeScript，为什么还需要 ESLint**
        - TS 主要是用来做类型检查和语言转换的，顺带一小部分的语法检查
        - ESLint 主要是用来检查代码风格和语法错误的
    - 如果在使用 babel-loader + @babel/preset-typescript 这种方案时，也想要类型检查
        - 再开一个 npm 脚本自动检查类型：`"type-check": "tsc --watch"`，tsconfig.json中配置compilerOptions.noEmit=true
    - 使用 @babel/preset-typescript 需要注意有四种语法在 babel 中是无法编译的
        - namespace（已过世）
        - 类型断言：`let p1 = {age: 18} as Person;`
        - 常量枚举：`const enum Sex {man, woman}`
        - 历史遗留风格的 import/export 语法：`import xxx= require(…) 和 export = xxx`

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

---

参考文章

[^1]: https://juejin.im/post/6844904052094926855#heading-0 (Webpack 转译 Typescript 现有方案)
[^2]: https://www.tslang.cn/docs/handbook/declaration-files/by-example.html
[^3]: https://cn.vuejs.org/v2/guide/typescript.html

