---
layout: "post"
title: "LDAP"
date: "2019-11-22 16:52"
categories: db
tags: [auth]
---

## 简介

- `LDAP`(Light Directory Access Portocol)，它是基于X.500标准的轻量级目录访问协议 [^1]
- 特点
    - 目录是一个为查询、浏览和搜索而优化的数据库，它成树状结构组织数据，类似文件目录一样
    - 目录数据库和关系数据库不同，它有优异的读性能，但写性能差，并且没有事务处理、回滚等复杂功能，不适于存储修改频繁的数据。所以目录天生是用来查询的，就好象它的名字一样
    - LDAP目录服务是由目录数据库和一套访问协议组成的系统
- `OpenLDAP` 为Opensource开源的项目。其他如`SUNONE Directory Server`(SUN)、`IBM Directory Server`、Microsoft Active Directory
- LDAP客户端使用：[LDAP Admin 下载](http://www.ldapadmin.org/download/index.html)。使用参考：https://cloud.tencent.com/developer/article/1380076

## LDAP的基本模型

- dc  (Domain Component)：域名的部分，其格式是将完整的域名分成几部分，如域名为example.com变成dc=example,dc=com(一条记录的所属位置)
- uid (User Id)：用户ID songtao.xu（一条记录的ID）
- ou  (Organization Unit)：组织单位，组织单位可以包含其他各种对象(包括其他组织单元)，如"oa组"(一条记录的所属组织)
- cn  (Common Name)：公共名称，如"Thomas Johansson"(一条记录的名称)
- sn  (Surname)：姓，如"许"
- dn  (Distinguished Name)：唯一名称。如"uid=songtao.xu,ou=oa组,dc=example,dc=com"，一条记录的位置(唯一)
- rdn (Relative dn)：相对辨别名，类似于文件系统中的相对路径，它是与目录树结构无关的部分，如"uid=tom"或"cn= Thomas Johansson"

## OpenLDAP安装(服务端)

### 基于k8s安装

> https://hub.kubeapps.com/charts/stable/openldap

```bash
helm fetch stable/openldap --version=1.2.2
# 修改 templates/service.yaml，为参数 spec.ports['ldap-port'] 增加属性`nodePort: {{ .Values.service.nodePort }}`

cat > openldap-values.yaml << 'EOF'
# admin账户密码
adminPassword: Test1
configPassword: Test2
persistence:
  enabled: true
  storageClass: 'nfs-client'
service:
  type: NodePort
  nodePort: 30005
EOF

# 基于源文件安装
helm install --name openldap-devops --namespace devops ./openldap-1.2.2 -f openldap-values.yaml
# 安装后提示：ldapsearch -x -H ldap://openldap-devops-service.devops.svc.cluster.local:389 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w $LDAP_ADMIN_PASSWORD

helm upgrade openldap-devops ./openldap-1.2.2 -f openldap-values.yaml
helm del --purge openldap-devops
```
- 使用
    - 使用LDAP Admin连接
    - admin账户可以把自己删掉，防止误操作
    - 默认匿名用户也可以连接

## 使用

### PHP

```php
$ldapconn = ldap_connect("10.1.8.78")
$ldapbind = ldap_bind($ldapconn, 'username', $ldappass);
$searchRows= ldap_search($ldapconn, $basedn, "(cn=*)");
$searchResult = ldap_get_entries($ldapconn, $searchRows);
ldap_close($ldapconn);
```


---

参考文章

[^1]: https://www.cnblogs.com/wilburxu/p/9174353.html


