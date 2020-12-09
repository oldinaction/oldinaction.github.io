# node v8.17.0
cd D:/gitwork/coding/blog
hexo clean
git add .
git commit -am "update blog"
git push origin master:source
export HEXO_ALGOLIA_INDEXING_KEY=3330f3cbaa099dfc30395de5f5b20151
hexo g && gulp && hexo d

