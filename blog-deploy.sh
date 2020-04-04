cd D:/gitwork/coding/blog
hexo clean
git add .
git commit -am "update blog"
git push origin master:source
hexo g && gulp && hexo algolia && hexo d