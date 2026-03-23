---
layout: "post"
title: "firebase"
date: "2017-03-19 21:21"
categories: [service]
tags: [google]
---

## 简介

- Firebase是google提供的快速构件应用的云服务。简单的可以说通过引入Firebase，你可以通过api去构建实时性的应用
- [官网](https://firebase.google.com/)
- [文档](https://firebase.google.com/docs?hl=zh-cn)
    - [Firestore](https://firebase.google.com/docs/firestore?hl=zh-cn)
- [价格](https://firebase.google.com/pricing)
- Firebase代替开源方案
    - 参考: https://www.nocobase.com/cn/blog/open-source-firebase-alternatives
    - Supabase

## 基础使用

- 使用 CLI 工具: https://firebase.google.com/docs/cli
    - 可通过命令行控制 firebase 项目资源

```bash
# 安装
npm install -g firebase-tools
# 登录(可能需要设置命令行代理)
# firebase login
firebase login:ci
# 列出项目
firebase projects:list
# 在当前目录中关联并设置一个新的 Firebase 项目, 会自动创建 firebase.json
firebase init

# 部署项目. eg: Firebase Hosting 网站的新版本, Cloud Firestore 的规则和索引, Cloud Functions等
firebase deploy

# 列出 Firestore 数据库实例
firebase firestore:databases:list
```
- NPM依赖说明
    - firebase-admin: 用于服务端(如Node.js)操作 Firebase 数据库, 如设置安全规则, 创建索引等
    - firebase: 用于客户端(如浏览器)操作 Firebase 数据库, 如读写数据, 监听数据变化等

## Firestore数据库

- [Firestore](https://firebase.google.com/docs/firestore?hl=zh-cn)

### 管理配置

- 安全规则
    - resource.data: 现有文档数据
    - request.resource.data: 请求中的数据
- 索引
    - 筛选+排序只有一个字段会自动索引 (Firestore 自动为每个字段维护单字段索引)
    - 多字段 == 或 in 筛选会自动走单字段索引, 如果有范围比较(大于, 小于等)获排序则需要创建复合索引
        - 不指定排序时, 默认按文档 ID 升序
        - 也可以设置按文档 ID 降序排列, 此时也不需要额外索引, 如 `query.orderBy(FieldPath.documentId, descending: true);`
    - 筛选+排序有多个字段，需要手动创建复合索引：a,b 和 a,b,c 两种查询需要创建 2 个索引
    - 字段排序方式不同，需要创建不同的索引：a asc, b asc 和 a desc, b asc 两种查询需要创建 2 个索引
    - 需要把过滤范围比较大的字段放在索引组合的前面，减少过滤数据量
        - 无 orderBy 时：索引字段顺序与查询 where 顺序无关
        - 有 orderBy 时：索引字段顺序必须「过滤字段在前，排序字段按 orderBy 顺序在后」，且排序方向要匹配
        - 范围过滤时：范围字段必须放在所有 isEqualTo 字段之后，且一个查询仅能有一个范围字段 ???
    - 索引排序: 升序效率高，如果业务上要求数据降序排列则只能创建降序索引

### 增删查改(Flutter版)

- 查询
    - 索引规则参考上文
    - 查询最多只能对一个字段进行范围查询(如时间, 此时就不能过滤年龄区间)
    - 报错: `[cloud_firestore/invalid-argument] Client specified an invalid argument. Note that this differs from failed-precondition. invalid-argument indicates arguments that are problematic regardless of the state of the system (e.g., an invalid field name).`
        - 如果查询中包含一个范围查询字段，则此字段必须处于 orderBy 子句中的第一个字段，否则可能报错
        - isNotEqualTo/whereNotIn(flutter) 等不能和 orderBy 联用，否则可能报错。将`!=`改成`> or <`

```dart
QuerySnapshot snapshot = await firestore.collection("users").where('userId', isEqualTo: userId).get();
// querySnapshot.docs.length // 集合数


// 构建分页查询
Query query = firestore.collection("users").where('userId', isEqualTo: userId);
if (startDate != null) {
    query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    query = query.orderBy('date', descending: true);
}
if (lastDocument != null) {
    query = query.startAfterDocument(lastDocument);
}
query = query.limit(limit);
// 执行查询
QuerySnapshot snapshot = await query.get();
// 返回数据
return {
    'users': querySnapshot.docs,
    'lastDocument': querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null, // 用于获取下一页
    'hasMore': querySnapshot.docs.length == limit,
}
```
- 新增

```dart
// 新增时使用系统自动生成文档ID(非自增)
firestore.collection("users")
      .add({"name": "张三", "age": 25});

// 新增时自定义文档ID
firestore.collection("users")
      .doc("${DateTime.now().millisecondsSinceEpoch}_user001") // 或使用雪花ID(比较好保证单用户递增, 不是很好保证全局严格递增)
      .set({"name": "张三", "age": 25});
```
- 日期处理

```dart
// 转换日期为 Timestamp 格式. 否则新增可能报超时异常
if (data['createdAt'] is DateTime) {
    data['createdAt'] = Timestamp.fromDate(data['createdAt']);
}
if (data['createdAt'] is String) {
    data['createdAt'] = Timestamp.fromDate(DateTime.parse(data['createdAt']));
}
if (data['createdAt'] is int) {
    data['createdAt'] = Timestamp.fromMillisecondsSinceEpoch(data['createdAt']);
}
firestore.collection("users").add(data);
```

## Functions

```bash
# 管理员登录
firebase login:ci
# 如果是新目录(项目), 初始化: (命令行按空格)选择 `Functions: Configure a Cloud Functions directory and its files`
# 会自动在当前目录创建 firebase.json 文件, 并创建 functions 文件夹(node项目) 和 functions/index.js 文件
firebase init
# 修改 index.js(参考下文) 文件后, 部署函数
firebase deploy --only functions
```
- 调试

```bash
# 在上述 firebase 项目根目录执行启动调试
# http://127.0.0.1:4000/ 可查看 firebase 项目的所有模拟器; http://127.0.0.1:5001/ 可查看云函数日志
firebase emulators:start --only functions
# 或者直接查看云函数日志
firebase functions:log --watch --function

# flutter中使用
final FirebaseFunctions _functions = FirebaseFunctions.instance;
# 设置调用云函数时, 使用本地模拟器
_functions.useFunctionsEmulator('localhost', 5001);
```
- index.js 案例

```js
// 引入Firebase Functions模块，用于创建云函数
const functions = require("firebase-functions");
// 引入Firebase Admin模块，用于管理用户、设置自定义声明等后台操作
const admin = require("firebase-admin");
// 初始化Admin SDK，赋予云函数操作Firebase服务的权限
admin.initializeApp();

// 1. 设置用户账号等级
// 功能：仅管理员可调用，为指定用户设置账号等级（如0=普通用户，1=VIP，2=SVIP）
// 入参：{ uid: 用户ID, level: 等级数值, expireAt: 失效时间戳(可选) }
exports.setUserLevel = functions.https.onCall(async (request) => {
  const data = request.data;
  const auth = request.auth;
  
  // 权限验证：检查调用者是否已登录，且是否拥有管理员权限（token中包含admin标识）
  if (!auth || !auth.token.admin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can set user levels"
    );
  }

  // 解构获取前端传入的用户ID、等级和失效时间参数
  const { uid, level, expireAt } = data;
  // 参数验证：检查uid和level是否为空
  if (!uid || level === undefined || level === null) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing uid or level parameter"
    );
  }

  // 核心操作：为指定用户设置Custom Claims（自定义声明），存储用户等级和失效时间
  const existingUser = await admin.auth().getUser(uid);
  const existingClaims = existingUser.customClaims || {};
  
  await admin.auth().setCustomUserClaims(uid, {
    ...existingClaims,
    userLevel: level, // 自定义字段：userLevel 存储用户账号等级
    userLevelExpireAt: expireAt || null, // 自定义字段：userLevelExpireAt 存储等级失效时间
  });

  // 返回操作成功结果（英文提示）
  return { success: true, message: "User level set successfully" };
});

// 2. 设置用户配置信息（轻量级）
// 功能：仅用户本人可调用，设置个人轻量级配置（如主题、通知开关等）
// 入参：{ uid: 用户ID, config: 配置对象 }
exports.setUserConfig = functions.https.onCall(async (request) => {
  const data = request.data;
  const auth = request.auth;
  
  // 权限验证：检查调用者是否已登录，且调用者UID与目标UID一致（仅本人可修改）
  if (!auth || auth.uid !== data.uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the user themselves can modify their configuration"
    );
  }

  // 解构获取前端传入的用户ID和配置参数
  const { uid, config } = data;
  // 参数验证：检查uid和config是否为空
  if (!uid || !config) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing uid or config parameter"
    );
  }

  // 核心操作：设置用户配置到Custom Claims，同时保留原有声明（避免覆盖）
  await admin.auth().setCustomUserClaims(uid, {
    // 展开原有Custom Claims，保留已存在的字段（如userLevel、shareUsers等）
    ...(await admin.auth().getUser(uid)).customClaims,
    userConfig: config, // 新增/覆盖用户配置字段
  });

  // 返回操作成功结果（英文提示）
  return { success: true, message: "User configuration set successfully" };
});
```

## Flutter版使用

- 参考: [flutter.md#整合Firebase](/_posts/mobile/flutter.md#整合Firebase)

## WEB版使用

### Firebase帐号注册

- 可通过google账户登录，选择免费版，新建一个项目
- 点击`Authentication` - `登录方法` - 启用Google登录
- 点击`overview` - `将 Firebase 添加到您的网页应用` - 复制代码供下面使用

### 下载web版示例

- [quickstart-js](https://github.com/firebase/quickstart-js)
- 该文件中包含了auth验证、database数据库、storage存储、messaging消息等示例
- 找到database/index.html，将上文复制的代码放到head中

### 为开发运行本地Web服务器

- 安装firebase命令行工具：`npm install -g firebase-tools`(重新运行安装命令，可更新此工具)
- cmd进入到上文的database文件夹
- 启动服务器 `firebase serve`
- 访问：`http://localhost:5000`
- 点击登录，就会自动调用google登录验证api
- 该示例登录进入可书写博文，数据可在控制面板的`Database`中查看

### 部署应用

最终可在控制面板的Hosting中查看
- 启动一个新的命令行，cmd进入到上文的database文件夹
- 登录Google并授权 `firebase login`
- 初始化应用 `firebase init`，运行后确认 - 选择Hosting - 选择创建的项目，创建根目录（默认会在此目录创建一个public的目作为根目录）
    - 运行 firebase init 命令会在您的项目的根目录下创建 firebase.json
    - 当您初始化应用时，系统将提示您指定用作公共根目录的目录（默认为"public"）。如果您的公共根目录下不存在有效的 index.html 文件，系统将为您创建一个。
    - 如一个firebase.json

    ```json
    {
      // 主机配置(前端静态文件映射)
      "hosting": {
        "public": "./", // 可以是 vue 的编译目录
        "rewrites": [
          {
            "source": "**",
            "destination": "/index.html"
          }
        ],
        "ignore": [
          "firebase.json",
          "**/.*",
          "**/node_modules/**",
          "functions"
        ]
      },
      // 数据库规则配置
      "database": {
        "rules": "database.rules.json"
      },
      // 函数配置
      "functions": [
        {
            "source": "functions",
            "codebase": "default",
            "disallowLegacyRuntimeConfig": true,
            "ignore": [
                "node_modules",
                ".git",
                "firebase-debug.log",
                "firebase-debug.*.log",
                "*.local"
            ]
        }
      ]
    }
    ```

- 部署项目 `firebase deploy`
    - 仅部署云函数 `firebase deploy --only functions`
    - 仅部署 Hosting `firebase deploy --only hosting` 对应网址`https://项目Id.web.app`
