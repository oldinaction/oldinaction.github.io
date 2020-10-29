

## 简介

- [中文Doc](https://www.tslang.cn/index.html)

## tsconfig.json

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

