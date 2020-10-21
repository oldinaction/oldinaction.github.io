---
layout: "post"
title: "Java Tools"
date: "2020-10-9 15:18"
categories: java
tags: tools
---

## Hutool

> https://hutool.cn/docs/

### Bean/Map/Json相互转化

```java
// Bean转成JSON字符串
String str = JSONUtil.toJsonStr(person);
// JSON字符串转成Bean
Person person = JSONUtil.toBean(str, Person.class);
// 实现深度拷贝。使用 BeanUtil.copyProperties 为浅拷贝
Person newPerson = JSONUtil.toBean(JSONUtil.toJsonStr(person), Person.class);
```

### 集合

```java
// ## 做减法，如：[1, 2] - [2, 3] = [1]
List<String> oldCodes = new ArrayList<>();
// List<String> newCodes = Arrays.asList(menuIds); // 类型为 Array$ArrayList
List<String> newCodes = new ArrayList<>(Arrays.asList(menuIds)); // 类型为 ArrayList
List<String> codes = CollUtil.subtract(newCodes, oldCodes); // 返回新对象。此时两个对象类型必须一致，如其中一个为Array$ArrayList，则会报错
```

## 类型转化

```java
// ## List转成数组
List<String> oldCodes = new ArrayList<>();
Object[] objArr = oldCodes.toArray;
String[] strArr = Convert.toStrArray(list.toArray); // 将list转成 String[]
```

### Bean操作

```java
// 忽略NULL值(不会忽略空值)，和忽略部分属性
BeanUtil.copyProperties(source, target, CopyOptions.create().ignoreNullValue().setIgnoreProperties("id", "inputer", "inputTm"));
```

## Yaml解析(基于jyaml)

- 依赖

```xml
<dependency>
    <groupId>org.jyaml</groupId>
    <artifactId>jyaml</artifactId>
    <version>1.3</version>
</dependency>
```
- yaml

```yml
name: smale
age: 18
child:
  # 需要有空格，否则解析报错
  - name: aezo
    age: 10
```
- 代码

```java
// model
@Data
public class Person {
    private String name;
    private String age;
    private Person[] child; // 不能使用数组接受，否则解析失败
}

// 解析
File dataFile = new File(System.getProperty("user.dir") + "/src/gen/data.yaml");
Person person = (Person) Yaml.loadType(dataFile, Person.class);
```
