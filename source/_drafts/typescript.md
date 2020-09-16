



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

