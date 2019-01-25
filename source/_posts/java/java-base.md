---
layout: "post"
title: "java基础"
date: "2017-12-12 10:07"
categories: [java]
tags: [javase]
---

## 集合

### 易错点

- 时间转换

https://bbs.csdn.net/topics/390666151
https://docs.oracle.com/javase/9/docs/api/java/text/SimpleDateFormat.html
2013-11-17T11:59:22+08:00 UTC(世界协调时间格式)
formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX"); // 2013-11-17 11:59:22
2013-11-17T11:59:22+0800
formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssX"); // 2013-11-17 11:59:22

1970-01-01T00:00:00.007Z
formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");