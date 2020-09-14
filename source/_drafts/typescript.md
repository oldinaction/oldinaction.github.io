



- 打包项目时，报错`573:15 Interface 'NodeJS.Module' incorrectly extends interface '__WebpackModuleApi.Module'.`
  - 解决：在tsconfig.json中加入`compilerOptions."types": ["webpack-env"]`

