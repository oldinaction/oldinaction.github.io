---
layout: "post"
title: "ofbiz任务(定时/异步)"
date: "2018-02-24 16:27"
categories: java
tags: [ofbiz, async]
---

## 源码分析

- `org.ofbiz.service.job.JobPoller` 加载时会启动一个自动执行任务的线程

```java
private static final JobPoller instance = new JobPoller();

// ...

// 自动执行任务线程
private final Thread jobManagerPollerThread;

private JobPoller() {
    if (pollEnabled()) {
        jobManagerPollerThread = new Thread(new JobManagerPoller(), "OFBiz-JobPoller");
        jobManagerPollerThread.setDaemon(false);
        jobManagerPollerThread.start();
    } else {
        jobManagerPollerThread = null;
    }
    ServiceConfigUtil.registerServiceConfigListener(this);
}
```




















---