---
layout: "post"
title: "HTTP"
date: "2019-12-15 15:41"
categories: web
tags: [web]
---


## 常见错误码

```bash
## 1XX	信息性状态码（Informational）	服务器正在处理请求

## 2XX	成功状态码（Success）	请求已正常处理完毕
200 OK # 请求正常处理完毕
204 No Content # 请求成功处理，没有实体的主体返回
206 Partial Content # GET范围请求已成功处理

## 3XX	重定向状态码（Redirection）	需要进行额外操作以完成请求
301 Moved Permanently # 永久重定向，资源已永久分配新URI
302 Found # 临时重定向，资源已临时分配新URI
303 See Other # 临时重定向，期望使用GET定向获取
304 Not Modified # 发送的附带条件请求未满足
307 Temporary Redirect # 临时重定向，POST不会变成GET

## 4XX	客户端错误状态码（Client Error）	客户端原因导致服务器无法处理请求
400 Bad Request # 请求报文语法错误或参数错误
401 Unauthorized # 需要通过HTTP认证，或认证失败
403 Forbidden # 请求资源被拒绝
404 Not Found # 无法找到请求资源（服务器无理由拒绝）

## 5XX	服务器错误状态码（Server Error）	服务器原因导致处理请求出错
500 Internal Server Error # 服务器故障或Web应用故障
503 Service Unavailable # 服务器超负载或停机维护
```