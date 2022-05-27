---
layout: "post"
title: "标记语言"
date: "2020-10-21 14:11"
categories: lang
tags: [yaml, json]
---

## yaml

- 参考 [Yaml解析(基于jyaml)](/_posts/java/java-tools.md#Yaml解析(基于jyaml))
- json-yaml互转工具：https://www.bejson.com/json/json2yaml
- yaml多行配置规则参考：https://www.cnblogs.com/didispace/p/12524194.html

```yml
# 配置与显示，都严格按段落展示
## 直接使用\n来换行
string: "Hello,\n\
         World."
## 使用｜(文中自动换行 + 文末新增一空行。测试可行)、｜+(文中自动换行 + 文末新增两个空行)、|-(文中自动换行 + 文末不新增空行)
string: |
  Hello,
  World.

# 配置按段落，显示不需要按段落
string: 'Hello,
         World.'
# 使用>(文中不自动换行 + 文末新增一空行)、>+、>-
string: >
  Hello,
  World.

# Java配置文件可以映射为 Map
map:
  key: val
map2: {}
```

## json

### json格式

- json格式校验工具：https://qqe2.com/
- 正确的json字符串

```json
{
    "name": "smalle",
    "age": 18,
    "hobbys": ["a", "b", 1]
}

[
    {
        "name": "smalle"
    }, 
    2
]
```
- 错误的json字符串

```js
{
    name: "smalle" // key必须要双引号。且json字符串不能有注释
}

{
    "name": "smalle", // 此处不该有逗号
}
```

### jsonpath

- 类似xpath获取json值
- [jmespath](https://jmespath.org/)
    - 提供Javascript、Java、Python、PHP相关类库：https://jmespath.org/libraries.html
    - [js版本的jmespath](https://github.com/jmespath/jmespath.js)
    - 问题
        - 好像不能对json进行修改
    - 使用

    ```js
    // 安装
    npm install jmespath -S

    import jmespath from 'jmespath'

    // 特殊key取值方式(v0.16.0)，官网引入的jmespath版本(v2015)可以通过"a.b-1"进行取值
    // js库不支持search(path, obj)函数(python库支持)
    jmespath.search({'a': {'b-1': 1}}, 'a."b-1"') // 1
    ```
    - 解决无法修改json(建议直接使用 lodash.merge 等函数)
    
    ```js
    let originReport = {
        extMapJson: {
            print: true,
            event: {
                "checkbox-all": "() => {}"
            }
        }
    }
    const assignReport = {
        extMapJson: {
            print: false,
            prop: {
                height: "100px"
            }
        }
    }
    deepAssignReport(originReport, assignReport, '', assignReport)
    // originReport = JSON.parse(JSON.stringify(originReport))
    /*
    {
        extMapJson: {
            print: false,
            event: {
                "checkbox-all": "() => {}"
            },
            prop: {
                height: "100px"
            }
        }
    }
    */
    console.log(originReport)

    deepAssignReport (originReport, assignReport, prefix, obj) {
      if (obj == null || typeof obj === 'string' || typeof obj === 'number' || typeof obj === 'function') {
        let originObj = originReport
        const jkeyArr = this.getJkeyArr(prefix)
        if (jkeyArr[0]) {
          originObj = jmespath.search(originReport, jkeyArr[0])
          if (originObj == null) {
            // eg: extMapJson.prop 为空
            originObj = {}
            const jkeyArrParent = this.getJkeyArr(jkeyArr[0])
            const parentObj = jmespath.search(originReport, jkeyArrParent[0])
            parentObj[jkeyArrParent[1]] = originObj
          }
        }
        originObj[jkeyArr[1]] = obj
      } else if (obj && typeof obj === 'object') {
        if (obj instanceof Array) {
            // todo...
        } else {
          const keys = Object.getOwnPropertyNames(obj)
          for (const key of keys) {
            if (key === '__ob__') {
              continue
            }
            let jkey = key
            if (key.indexOf('-') >= 0) {
              jkey = '"' + key + '"'
            }
            const childPrefix = prefix ? prefix + '.' + jkey : jkey
            const childObj = jmespath.search(assignReport, childPrefix)
            this.deepAssignReport(originReport, assignReport, childPrefix, childObj)
          }
        }
      }
    },

    function getJkeyArr (jkey) {
      let prefix = ''
      let last = ''
      let arr = jkey.split('.')
      if (arr.length < 2) {
        return [prefix, jkey]
      } else {
        // func.doCheckbox
        // event."checkbox-all"
        // tailTables[0].prop."footer-method"
        last = arr[arr.length - 1]
        prefix = arr.slice(0, arr.length - 1).join('.')
      }
      if (last.indexOf('[') > 0) {
        prefix = prefix + '.' + last.substr(0, last.indexOf('['))
        last = last.substr(last.indexOf('[') + 1).replaceAll(']', '')
      }
      last = last.replaceAll('"', '')
      return [prefix, last]
    },
    ```
- JsonPath
    - 提供Javascript、Java、Python、PHP相关类库；js库没找到
    - [java版本的json-path](https://github.com/json-path/JsonPath)

## xpath




