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
- [OpenLDAP](http://www.openldap.org/doc/admin24/) 为Opensource开源的项目。其他如`SUNONE Directory Server`(SUN)、`IBM Directory Server`、`Microsoft Active Directory`
- LDAP客户端使用：[LDAPAdmin下载](http://www.ldapadmin.org/download/index.html)、`ApacheDirectoryStudio`
    - Host：192.168.1.100:389；Base：dc=demo,dc=com；Username：填写dn，如：cn=admin,dc=demo,dc=com；Password：填写用户属性userPassword
    - LDAPAdmin使用参考：https://cloud.tencent.com/developer/article/1380076
- LDAP web客户端：`ldap-account-management`、`phpLDAPadmin`

## LDAP的基本模型

### 条目

- LDAP的信息模型是建立在"条目"(entries)的基础上。一个条目是一些属性的集合，并且具有一个全局唯一的"可区分名称"DN，一个条目可以通过DN来引用。每一个条目的属性具有一个类型和一个或者多个值。类型通常是容易记忆的名称，比如"cn"是通用名称(common name)，或者"mail"是电子邮件地址。条目的值的语法取决于属性类型。比如，cn属性可能具有一个值"Babs Jensen"。一个mail属性可能包含"bbs@kevin.com"。一个jpegphoto属性可能包含一幅JPEG(二进制)格式的图片 [^2] [^3]

### objectClass

- LDAP通过条目属性`objectClass`来控制哪一个属性必须出现或允许出现在一个条目中，它的值决定了该条目必须遵守的模式规则
- 取值如下
    - `olcGlobal` 全局配置文件类型，主要是 cn=config.ldif 的配置项
    - `top` 顶层的对象
    - `organization` 组织，比如公司名称，顶层的对象
    - `organizationalUnit` 重要， 一个目录节点，通常是group，或者部门这样的含义
    - `inetOrgPerson` 重要， 我们真正的用户节点类型，person类型， 叶子节点
    - `groupOfNames` 重要， 分组的group类型，标记一个group节点
    - `olcModuleList` 配置模块的对象

### 常用属性名

- `objectClass`
- `dn`  (Distinguished Name)：唯一名称(一条记录的唯一位置)，有三个属性，分别是：CN、OU、DC。如"uid=xiaoer.li,ou=oa组,dc=example,dc=com"
- `cn`  (Common Name)：公共名称，如"Thomas Johansson"(一条记录的名称)
- `ou`  (Organization Unit)：组织单位，组织单位可以包含其他各种对象(包括其他组织单元)，如"oa组"(一条记录的所属组织)
- `dc`  (Domain Component)：域名的部分，其格式是将完整的域名分成几部分，如域名为example.com变成dc=example,dc=com(一条记录的所属位置)
- `upn` (User Principal Name)：用户主体名称，每个用户还可以有一个比DN更短、更容易记忆的 UPN，例如张三隶属于 example.com，则其 UPN 可以为 zhangsan@example.com。用户登录时所输入的账户名最好是 UPN，因为无论此用户的账户被移动到哪一个域，其 UPN 都不会改变，因此用户可以一直使用同一个名称来登录
- `uid` (User Id)：用户ID(10000/smalle, 一条记录的ID)
- `rdn` (Relative dn)：相对辨别名，类似于文件系统中的相对路径，它是与目录树结构无关的部分，如"uid=tom"或"cn= Thomas Johansson"
- `sn`  (Surname)：姓，如"李"
- `c`	(Country)：国家，如"CN"或"US"等
- `o`	(Organization) 组织名，如"Example, Inc."
- `userPassword` 用户密码，如：111111(直接使用明文登录)、{SSHA}UkTxshLTluIE8ubsJ3PvWtFmOEKJdXHE(使用此SSHA加密前的数据登录)
- `title` 职称
- `mail` 邮件
- `displayName` 展示名
- `departmentNumber` 部门编号
- `telephoneNumber` 电话号码

### 其他

- `Schema` 类似数据库表定义，定义了属性/字段名称(如：objectClass)和类型(如：Text)。文件位置`/etc/openldap/schema`
- `Base DN` 目录树的最顶部就是根，也就是所谓的 "base dn"，如 "dc=demo,dc=com"
- `LDIF`(LDAP Data Interchange Format) 数据交换格式，是LDAP数据库信息的一种文本格式，用于数据的导入导出，每行都是"属性: 值"对
- `DIT`(The Directory Information Tree) 目录信息树，如：demo.com的根节点开始为一个DIT
- `ACL`(Access Control List) 表示权限控制
- `OLC`(on-line configuration) 运行时配置，通过配置 DIT 条目 cn=config 达到运行时配置(无需停止服务器)

## OpenLDAP安装及配置(服务端)

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

### yum安装

```bash
yum install -y openldap openldap-clients openldap-servers
systemctl start slapd && systemctl enable slapd

# 默认安装加载了core.ldif，还需加载几个常用的schema
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# 默认域为dc=my-domain,dc=com。配置位于 /etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif
```
- 说明
    - 默认监听在389端口
    - 默认匿名用户可以查看，但是无法编辑，权限配置参考ACL
    - 配置文件目录`/etc/openldap`
    - 默认没有memberof模块，增加此模块可参考：[^2] (使用LDAP Admin无法看到memberOf字段，可通过ldap命令查看)

### 禁止匿名用户访问

```bash
cat > disable_anon.ldif << 'EOF'
dn: cn=config
changetype: modify
add: olcDisallows
olcDisallows: bind_anon

dn: cn=config
changetype: modify
add: olcRequires
olcRequires: authc

dn: olcDatabase={-1}frontend,cn=config
changetype: modify
add: olcRequires
olcRequires: authc
EOF

ldapadd -Y EXTERNAL -H ldapi:/// -f disable_anon.ldif
```

### 配置ACL

> http://www.openldap.org/doc/admin24/access-control.html

- 语法

```bash
# 通过access to约束我们访问的范围（resources），通过by设定哪个用户（who）获取对这个约束范围有什么权限（type of access granted），并控制（control）这个by语句完成后是否继续执行下一个by语句或者下一个ACL指令
<access directive> ::= access to <what>
    [by <who> [<access>] [<control>] ]+
<what> ::= * |
    [dn[.<basic-style>]=<regex> | dn.<scope-style>=<DN>]
    [filter=<ldapfilter>] [attrs=<attrlist>]
<basic-style> ::= regex | exact
<scope-style> ::= base | one | subtree | children
<attrlist> ::= <attr> [val[.<basic-style>]=<regex>] | <attr> , <attrlist>
<attr> ::= <attrname> | entry | children
<who> ::= * | [anonymous | users | self
        | dn[.<basic-style>]=<regex> | dn.<scope-style>=<DN>]
    [dnattr=<attrname>]
    [group[/<objectclass>[/<attrname>][.<basic-style>]]=<regex>]
    [peername[.<basic-style>]=<regex>]
    [sockname[.<basic-style>]=<regex>]
    [domain[.<basic-style>]=<regex>]
    [sockurl[.<basic-style>]=<regex>]
    [set=<setspec>]
    [aci=<attrname>]
<access> ::= [self]{<level>|<priv>}
<level> ::= none | disclose | auth | compare | search | read | write | manage
<priv> ::= {=|+|-}{m|w|r|s|c|x|d|0}+
<control> ::= [stop | continue | break]
# 示例
access to * by self write by users read by anonymous auth

### resources可以有多种形式，如DN，attrs, Filters
## 通过DN约束
# 任何人都没有权限访问这个dn。其中，超级管理员也就是ldap配置文件里写的rootdn："cn=admin,dc=demo,dc=com"可进行访问
access to dn="uid=test,ou=Users,dc=example,dc=com" by * none
# 任何人都没有权限访问ou=Usersdc=example,dc=com以及其子树的信息
    # dn.base：约束这个特定DN的访问。他和dn.exact和dn.baselevel是相同的意思
    # dn.one：约束这个特定的DN第一级子树的访问。dn.onelevel是同义词
    # dn.children：这个和dn.subtree类似，都是对其以下的子树访问权的约束。不同点在于，这个的约束是不包含自己本身DN。而subtree包含了本身的DN
access to dn.subtree="ou=Users,dc=example,dc=com" by * none
## 通过约束attrs访问
# 任何人都没有权限访问属性为homePhone和homePostalAddress的信息
access to attrs=homePhone,homePostalAddress by * none
# 任何人都不能访问organizationalPerson对象里面的属性。注：organizationalPerson对象类是person的子类
access to attrs=@organizationalPerson by * none
# 所有人除了organizationalPerson的属性，其他属性均不能访问
access to attrs=!organizationalPerson by * none
# 设置约定某个值
access to attrs=givenName val="Matt" by * none
# 基于正则设置约定某个值
access to attrs=givenName val.regex="M.*" by * none
# val.children
access to attrs=member val.children="ou=Users,dc=example,dc=com" by * none

## 通过Filters访问
# 表示可以约束所有记录中包含对象类为simpleSecurityObject的信息
access to filter="(objectClass=simpleSecurityObject)" by * none
# 过滤出givenName为Matt或者Barbara，或者surname为Kant的信息
access to filter="(|(|(givenName=Matt)(givenName=Barbara))(sn=Kant))" by * none
```
- 通过ldif文件修改。ldif文件只需将上文`access to`换成`{0}to`，{0}为规则序号

```bash
cat > update_acl.ldif << 'EOF'
dn: olcDatabase={2}hdb,cn=config
changetype: modify

# 只有自己可以修改密码，不允许匿名访问，允许g-admin组修改
add: olcAccess
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by group.exact="cn=g-admin,ou=Group,dc=demo,dc=com" write by * none
# 多个条目之间可以使用-或者空行进行分割，连在一起也可以
-
# 自己可以修改自己的信息，g-admin可以修改任何信息
add: olcAccess
olcAccess: {1}to * by self write by group.exact="cn=g-admin,ou=Group,dc=demo,dc=com" write by * none
EOF

ldapmodify -H ldapi:// -Y EXTERNAL -f update_acl.ldif
```

### 配置多DIN

- 配置多DIN(The Directory Information Tree)可理解为在mysql服务器上创建多个数据库，且多个DIN上的uid等可以重复，第三方使用LDAP认证时只能连接一个DIN
- Openldap增加DIT配置参考：http://blog.sina.com.cn/s/blog_92dc41ea0102wrf0.html

```bash
## 配置
cd /etc/openldap/
cp -a slapd.d slapd.d.backup # -a参数保留文件及文件夹的所有者，权限，安全上下文等属性
cd slapd.d/cn\=config/
cp -a olcDatabase\=\{2\}hdb.ldif  olcDatabase\=\{3\}hdb.ldif # 测试时hdb前面已有编号2了，此处增加为3

# 修改：{2}hdb为{3}hdb；olcDbDirectory为/var/lib/ldap-my-domain2；将dc=my-domain改成dc=my-domain2
vi olcDatabase\=\{3\}hdb.ldif
# 在olcAccess: {0}后面增加一条olcAccess{1}，且修改dc=my-domain2
vi olcDatabase\=\{1\}monitor.ldif

# 创建用户数据目录
mkdir /var/lib/ldap-my-domain2
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap-my-domain2/DB_CONFIG
chown -R ldap.ldap /var/lib/ldap-my-domain2

systemctl restart slapd

## 增加base组织结构，类似下文ldapad命令导入base.ldif、add_user.ldif的示例
```

## 使用

### LDAP命令

- ldap主要命令有`ldapadd`、`ldapmodify`、`ldapsearch` [^2] [^3]w    /'}|
- 参数说明
    - `-H` ldap server地址， 可以是`ldap://192.168.1.100:389`表示tcp，可以是`ldap:///`表示本地的tcp，可以是`ldapi:///`本地unix socket连接
    - `-Y EXTERNAL` 本地执行，修改配置文件，比如basedn, rootdn, rootpw, acl, module等信息
    - `-b` basedn 根目录， 将在此目录下查询
    - `-x` 启用简单认证，通过`-D <dn> -w <密码>`的方式认证
    - `-D` 用来绑定服务器的DN
    - `-f` 指定要修改的文件，如`my.ldif`
    - `-a` 使用ldapmodify增加一个entry的时候等同于ldapadd
    - `-c` 出错后继续执行程序不终止，默认出错即停止

#### ldapadd 添加条目

- 添加schema配置命令 `ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif`，所有的schema文件位置`/etc/openldap/schema`
- 添加额外的module命令，如增加memberof模块
    
```bash
cat > add_module_group.sh << 'EOF'
dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
olcModulePath: /usr/lib64/openldap

dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: memberof.la
EOF

cat > add_group_objectClass.sh << 'EOF'
dn: olcOverlay=memberof,olcDatabase={2}hdb,cn=config
objectClass: olcConfig
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: top
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfNames
olcMemberOfMemberAD: member     
olcMemberOfMemberOfAD: memberOf
EOF

ldapadd -Q -Y EXTERNAL -H ldapi:/// -f add_module_group.sh
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f add_group_objectClass.sh
```
- 添加普通entry命令 `ldapadd -x -D cn=admin,dc=demo,dc=com -w admin -f base.ldif`

```bash
cat > base.ldif << 'EOF'
# 注释...
dn: dc=demo,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: ldap测试组织
dc: demo

dn: cn=Manager,dc=demo,dc=com
objectClass: organizationalRole
cn: Manager
description: 组织管理人

dn: ou=People,dc=demo,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=demo,dc=com
objectClass: organizationalUnit
ou: Group
EOF

cat > add_user.ldif << 'EOF'
dn: ou=研发部门,ou=People,dc=demo,dc=com
changetype: add
objectClass: organizationalUnit
ou: 研发部门

dn: ou=后台组,ou=研发部门,ou=People,dc=demo,dc=com
changetype: add
objectClass: organizationalUnit
ou: 后台组

dn: cn=san.zhang,ou=后台组,ou=研发部门,ou=People,dc=demo,dc=com
changetype: add
objectClass: inetOrgPerson
cn: san.zhang
departmentNumber: 1
sn: Miao
title: 架构师
mail: san.zhang@demo.com
uid: 10000
displayName: 张三
EOF
```

#### ldapmodify 修改条目

- 管理员修改用户密码

```bash
# 获取密码
slappasswd # 重复输入密码my_new_pass，则返回{SSHA}UkTxshLTluIE8ubsJ3PvWtFmOEKJdXHE

cat > update_pass.ldif << 'EOF'
# 所有条目(包括cn=config配置)均可类似修改
dn: cn=san.zhan,ou=后台组,ou=研发部门,ou=People,dc=demo,dc=com
# add/modify/delete/modrdn 从DIT中新增、修改、删除、移动条目
changetype: modify

# add/replace/delete 对此条目新增、修改、删除某属性
replace: userPassword
userPassword: {SSHA}UkTxshLTluIE8ubsJ3PvWtFmOEKJdXHE
EOF

ldapmodify -a -H ldap://127.0.0.1:389 -D "cn=admin,dc=demo,dc=com" -w admin -f update_pass.ldif 
```
- 个人修改自己的密码 `ldappasswd -x -h 127.0.0.1 -p 389 -D "cn=san.zhan,dc=demo,dc=org" -w my_old_pass -s my_new_pass`

#### ldapsearch 查询条目

```bash
# 语法格式
ldapsearch -H ldapi:/// -D cn=admin,cn=demo,cn=com -w admin [-s sub] ["filter"] [attr]

# `-s scope` 指定查询范围，有 base|one|sub|children，主要用sub表示base之下的所有子目录
# `filter` 语法，正则语法。因为使用的时候传递过来的通常是username, 需要比较username在ldap中的字段，比如：(|(cn=Steve*)(sn=Steve*)(mail=Steve*)(givenName=Steve*)(uid=Steve*))
# `attr` 要返回的字段，必须返回的字段可以在配置文件里查看。默认返回全部，memberof非必须

ldapsearch  -Y EXTERNAL -H ldapi:/// -b cn=config dn # 查看所有配置项
ldapsearch  -Y EXTERNAL -H ldapi:/// -b cn=config "olcDatabase={2}hdb" # 查看olcDatabase具体配置
# 查询并备份到文件
ldapsearch -H ldap:/// -x -D cn=admin,dc=demo,dc=com -w admin -b dc=demo,dc=com > ldap-20200116.ldif
```

#### ldapdelete、ldappasswd

- `ldapdelete -x -D "cn=admin,dc=demo,dc=com" -W "uid=10000,ou=People,dc=demo,dc=com"` 使用admin用户登录，删除uid=10000
- `ldappasswd -x -h 127.0.0.1 -p 389 -D "cn=san.zhan,dc=demo,dc=org" -w my_old_pass -s my_new_pass`

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
[^2]: https://www.cnblogs.com/woshimrf/p/ldap.html
[^3]: https://www.cnblogs.com/kevingrace/p/5773974.html (详细的ldap介绍)



