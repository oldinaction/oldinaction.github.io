---
layout: "post"
title: "maven"
date: "2016-12-29 10:18"
categories: [extend, tools]
tags: [maven]
---

1. maven镜像修改
    - 在~/.m2目录下的settings.xml文件中，（如果该文件不存在，则需要从maven/conf目录下拷贝一份），找到<mirrors>标签，添加如下子标签

        ```xml
            <mirror>  
                <id>alimaven</id>  
                <name>aliyun maven</name>  
                <url>http://maven.aliyun.com/nexus/content/groups/public/</url>  <mirrorOf>central</mirrorOf>          
            </mirror>  
        ```
