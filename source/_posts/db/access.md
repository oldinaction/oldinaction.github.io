---
layout: "post"
title: "access"
date: "2018-11-20 14:06"
categories: [db]
tags: [microsoft, db]
---

## access数据简介

- `Access 2000-2003`文件格式`*.mdb`，数据加密容易被破解
- `Access > 2007`文件格式为`*.accdb`

## 特殊语法

- 仅查询10条数据：`select top 10 * from my_table order by id`

## java连接(基于springboot)

### 基于`UcanAccess`驱动连接

> 参考项目：https://github.com/oldinaction/springboot/tree/master/z-exe4j-accessdb
   
- [官网](http://ucanaccess.sourceforge.net/site.html)
- 内部基于`HSQLDB`实现。无需ODBC支持
- 缺点
    - UcanAccess默认是(memory=true)，将先access数据加载到内存，以`HSQLDB`形式保存在内存。当数据文件较大时，需要设置JVM参数调整堆内存(350M的access测试时需要1G堆内存)。
    - 可以通过设置memory=false，并设置keepmirror，即将access数据以`HSQLDB`形式保存到硬盘，这种情况下次连接可以继续使用。但是第一次解析非常慢(5-10分钟)，而且解析时也需要耗费一定的内存(400M堆内存左右)，并且不支持有密码的access数据文件
    - `mirrorFolder`：当memory=falses时，生成的数据文件保存路径，会在此路径生成一个类似`Ucanaccess_net.ucanaccess.jdbc.DBReference@328d761b`的文件夹，并每次启动会重新生成，而且启动时解析很慢
    - 总之：UcanAccess只适合连接小量数据且有密码的access数据库，或大量数据的无密码的access数据库
- 数据源路径支持绝对路径、相对路径、局域网路径(不支持FTP/HTTP)。**其中使用局域网路径时，第一次访问保存目标数据所在主机的登录凭证即可，下次(运行程序过程中)无需登录。**
- pom.xml

```xml
<!--连接access驱动-->
<dependency>
    <groupId>net.sf.ucanaccess</groupId>
    <artifactId>ucanaccess</artifactId>
    <version>3.0.1</version>
</dependency>

<!-- 连接加密access数据库时需要 -->
<!-- https://mvnrepository.com/artifact/com.healthmarketscience.jackcess/jackcess -->
<dependency>
    <groupId>com.healthmarketscience.jackcess</groupId>
    <artifactId>jackcess</artifactId>
    <version>2.1.0</version>
</dependency>
<!-- https://mvnrepository.com/artifact/com.healthmarketscience.jackcess/jackcess-encrypt -->
<dependency>
    <groupId>com.healthmarketscience.jackcess</groupId>
    <artifactId>jackcess-encrypt</artifactId>
    <version>2.1.4</version>
</dependency>
```
- application.yml

```yml
spring:
  datasource:
    driver-class-name: net.ucanaccess.jdbc.UcanaccessDriver
    # url: jdbc:ucanaccess://D:/gitwork/springboot/z-exe4j-accessdb/test.accdb;memory=true
    # 通过vm参数传递，可传递相对路径。jackcessOpener为加密access配置
    jdbc-url: jdbc:ucanaccess://${myexe.dbpath};jackcessOpener=cn.com.unilog.fedex.config.CryptCodecOpener;memory=true
    password: 123456F0C2785DA271888
```
- 访问加密数据源时需要

```java
@Configuration
public class CryptCodecOpener implements JackcessOpenerInterface {
    public Database open(File fl,String pwd) throws IOException {
        DatabaseBuilder dbd =new DatabaseBuilder(fl);
        dbd.setAutoSync(false);
        dbd.setCodecProvider(new CryptCodecProvider(pwd));
        dbd.setReadOnly(false);
        return dbd.open();
    }
}
```

### 基于ODBC连接

- odbc为微软的数据库连接工具，jdbc为java标准的数据连接工具，jdbc-odbc是java针对odbc提供的桥接工具。**jdbc-odbc工具自jdk1.8已经移除，一定要使用只能自行编译。**
- 使用jdk1.8通过odbc的方式连接access库，会提示找不到类`sun.jdbc.odbc.JdbcOdbcDriver`。解决办法参考：https://www.youtube.com/watch?v=Um273dtsUt8
    - 将jdk1.7(包含jdbc-odbc)的rt.jar复制出来，通过压缩工具进行解压。解压后将`sun.jdbc`和`sun.security.action`目录复制出来(根目录为sun)
    - `jar -cvf jdbc-odbc64.jar sun`对上述class文件夹进行重新生成jar(项目中使用此jar)
    - 且需要复制`JRE7/bin/JdbcOdbc.dll`到`JDK/bin`/`JRE8/bin`目录
- 需要在windows上面安装access驱动，并配置驱动。参考：https://1017401036.iteye.com/blog/2260786
    - windows搜索odbc - 设置ODBC数据源(64位) - 系统DNS - 添加 - 选择accdb的驱动 - 完成
    - 数据源名如为`test`(代码中连接的名) – 选择数据库 – 选择access文件 – 确定
    - 含密码的access，可以再高级配置选项中输入密码，用户名可不同填写
- 连接代码

```java
Connection connect = null;
PreparedStatement stmt = null;
ResultSet rs = null;
try{
    String db = "test"; // 上述数据源名
    Class.forName("sun.jdbc.odbc.JdbcOdbcDriver");
    Properties p = new Properties();
    p.put("charSet", "GBK"); // Access中的数据库默认编码为GBK，本地项目为UTF-8，若不转码会出现乱码
    connect = DriverManager.getConnection("jdbc:odbc:" + db, p);
    rs = stmt.executeQuery(); // 执行SQL
    if(rs != null) {
        while(rs.next()) {
            System.out.println(rs.getString(1));
        }
    }
} catch(Exception e) {
    e.printStackTrace();
} finally {
    // ... close
}
```

## nodejs连接

> 参考项目：https://github.com/oldinaction/smweb/tree/master/nwjs-demo/demo3-accessdb

- 安装插件[node-adodb](https://github.com/nuintun/node-adodb)
    - `npm install node-adodb` 即可使用
- 常见错误
    - 未找到提供程序。该程序可能未正确安装
        - 需要按照access版本安装驱动。本案例基于win64操作系统，Access2016 32位，因此此时需要下载Access2016 32位驱动(https://www.microsoft.com/en-us/download/details.aspx?id=54920)。打包nw.js后，客户端也需要安装对于驱动
        - Access 2000-2003 (*.mdb) Microsoft.Jet.OLEDB.4.0 (对于 Windows XP SP2 以上系统默认支持 Microsoft.Jet.OLEDB.4.0)
        - Access > 2007 (*.accdb) 如Access2016对应配置为：Microsoft.ACE.OLEDB.16.0
    - 文件名无效(-2147467259, Not a valid file name)
        - `Data Source`中文件支持绝对路径、相对路径、局域网路径(不支持FTP/HTTP)，主要字符串编码和路径分隔符
    - 不可识别的数据库格式(-2147467259)
        - 使用`Microsoft.Jet.OLEDB.4.0`连接字符串，去连接Access2016的文件(.accdb)则报此错误，此时需要Access2016驱动
        - 使用`Microsoft.ACE.OLEDB.16.0`可以同时解析`.accdb`和`.mdb`(对于 Windows XP SP2 以上系统默认支持 Microsoft.Jet.OLEDB.4.0，其它需要自己安装支持)


