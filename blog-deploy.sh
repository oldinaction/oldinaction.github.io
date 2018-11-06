cd D:/gitwork/coding/blog
git add .
git commit -am "update blog"
git push origin master:source
hexo g && gulp && hexo d