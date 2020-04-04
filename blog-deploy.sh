cd D:/gitwork/coding/blog
hexo clean
git add .
git commit -am "update blog"
git push origin master:source
export HEXO_ALGOLIA_INDEXING_KEY=a91f1b54121e881506b95730276f6884
hexo g && gulp && hexo algolia && hexo d