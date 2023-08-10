# 月星墙的博客

## 使用

- 相关命令(在项目根目录执行)

```bash
# node v10.24.1
hexo s -p 5000 # **启动本地服务器(本地测试)**
hexo g # 静态文件生成(修改主题文件可不用重新启动服务)
hexo clean # 清除缓存(如果未修改配置文件可不运行)
hexo d # 部署到github
```
- 更新/发布步骤如下 (或者直接执行项目目录下的`blog-deploy.sh`文件)

```shell
hexo clean # 有时候修改了静态文件需要先clean一下
git add .
git commit -am "update blog"
# git push origin master:source # 如果本地master为源码分支，远程source为源码分支(远程master为发布分支)
git push origin source:source # git push
hexo g && gulp && hexo d
```

