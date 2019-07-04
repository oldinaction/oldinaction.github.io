---
layout: "post"
title: "亚马逊云(AWS)实践"
date: "2017-03-13 09:33"
categories: [linux]
tags: [cloud]
---

## 亚马逊服务器选型(伦敦)

- 选项方案
    - 服务器EC2(RHEL)：t2.medium (2vCPU 4G)（数据传输按量计算：10 TB/月一下$0.090 每 GB。带宽此套餐固定250-300 MBit/s）
    - 存储EBS：Amazon EBS General Purpose SSD (gp2) volumes(只需按实际使用量付费)
    - 数据库Mysql：db.t2.medium(微型实例 2vCPU 4G)

- 服务器：t2.medium (2vCPU	4G)
    - t2.large(2vCPU 8G)差不多是medium的2倍；不含税收

![aws-服务器](/data/images/linux/aws-1.png)

- 存储：Amazon EBS General Purpose SSD (gp2) volumes(只需按实际使用量付费)
    - $0.116 每月预配置存储的 GB 数（1893元/200G*年）
- Mysql数据库：db.t2.medium(微型实例 2vCPU 4G)

![aws-数据库](/data/images/linux/aws-2.png)


## 数据库

需要在数据库所在安全组中把应用服务器IP加入
