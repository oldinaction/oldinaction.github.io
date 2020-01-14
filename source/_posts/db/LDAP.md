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
- `OpenLDAP` 为Opensource开源的项目。其他如`SUNONE Directory Server`(SUN)、`IBM Directory Server`、`Microsoft Active Directory`
- LDAP客户端使用：[LDAP Admin 下载](http://www.ldapadmin.org/download/index.html)。使用参考：https://cloud.tencent.com/developer/article/1380076
- LDAP web客户端：`ldap-account-management`、`phpLDAPadmin`

## LDAP的基本模型

- `DN`  (Distinguished Name)：唯一名称(一条记录的唯一位置)。如"uid=xiaoer.li,ou=oa组,dc=example,dc=com"
    - DN 有三个属性，分别是 CN，OU，DC
- `CN`  (Common Name)：公共名称，如"Thomas Johansson"(一条记录的名称)
- `OU`  (Organization Unit)：组织单位，组织单位可以包含其他各种对象(包括其他组织单元)，如"oa组"(一条记录的所属组织)
- `DC`  (Domain Component)：域名的部分，其格式是将完整的域名分成几部分，如域名为example.com变成dc=example,dc=com(一条记录的所属位置)
- `UPN` (User Principal Name)：用户主体名称，每个用户还可以有一个比DN更短、更容易记忆的 UPN，例如张三隶属于 example.com，则其 UPN 可以为 zhangsan@example.com。用户登录时所输入的账户名最好是 UPN，因为无论此用户的账户被移动到哪一个域，其 UPN 都不会改变，因此用户可以一直使用同一个名称来登录
- `GUID`(Global Unique Identifier) 全局唯一标识符
- `UID` (User Id)：用户ID(xiaoer.li 一条记录的ID)
- `RDN` (Relative dn)：相对辨别名，类似于文件系统中的相对路径，它是与目录树结构无关的部分，如"uid=tom"或"cn= Thomas Johansson"
- `SN`  (Surname)：姓，如"李"
- `Base DN` ldap 目录树的最顶部就是根，也就是所谓的 "base dn"，如 "dc=moonxy,dc=com"

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
env:
  LDAP_ORGANISATION: "AEZO"
  LDAP_DOMAIN: aezo.cn
EOF

# 基于源文件安装
helm install --name openldap-devops --namespace devops ./openldap-1.2.2 -f openldap-values.yaml
# 安装后提示：ldapsearch -x -H ldap://openldap-devops-service.devops.svc.cluster.local:389 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w $LDAP_ADMIN_PASSWORD

helm upgrade openldap-devops ./openldap-1.2.2 -f openldap-values.yaml
helm del --purge openldap-devops
```
- 使用
    - 使用LDAP Admin连接。base：`dc=aezo,dc=cn`，username：`cn=admin,dc=aezo,dc=cn`
    - admin账户可以把自己删掉，防止误操作，导致管理员被删
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


