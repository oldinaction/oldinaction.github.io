---
layout: "post"
title: "Kotlin"
date: "2025-04-11 21:22"
categories: lang
tags: [java]
---

## 简介

- [Kotlin中文站](https://www.kotlincn.net/)

## 语法

- Kotlin中标准函数run、with、let、also与apply
    - 参考: https://www.jb51.net/article/137056.htm

```java
// object 关键字用于创建一个匿名对象
mSearchViewItem = object : SearchViewItem(this, searchMenuItem) {
    // ...
}.apply {
    // 调用 setQueryCallback 函数, 此函数接收一个接口的匿名实现类(通过lamda实现了其方法, 此方法接收一个String参数)
    setQueryCallback { query: String? -> submitQuery(query) }
}
```

- companion object
    - 在 Kotlin 中，companion object 是一种特殊的对象声明，它用于在类内部创建静态成员。这是 Kotlin 对 Java 中静态成员的一种替代方案，因为 Kotlin 自身不直接支持传统意义上的静态方法或属性
    - 参考: https://www.cnblogs.com/yongdaimi/p/17921940.html

```java
class MainActivity : BaseActivity(), DelegateHost, HostActivity {

    companion object {
        private val TAG = MainActivity::class.java.simpleName

        // 调用如 MainActivity.shouldRecreateMainActivity = true
        var shouldRecreateMainActivity = false

        // 调用如 MainActivity.launch(this)
        @JvmStatic
        fun launch(context: Context) = context.startActivity(getIntent(context).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))

        @JvmStatic
        fun getIntent(context: Context?) = Intent(context, MainActivity::class.java)
    }
}
```
- `?`、`!!`使用

```java
// 若 mSearchViewItem 为 null，collapse 方法不会被调用，整个表达式的值为 null
mSearchViewItem?.collapse()
// 若 mSearchViewItem 不为 null，let 函数中的代码块会被执行，it 代表 mSearchViewItem 对象；若为 null，代码块则不会执行
mSearchViewItem?.let {
    it.collapse()
}

// ? 用于表示该参数是可空类型
private fun submitQuery(query: String?) {}
// 此时query不能为空
private fun submitQuery2(query: String) {}

// 在 Kotlin 里，!! 属于非空断言运算符。其作用是告知编译器，你能确保某个可空类型的变量此刻不为空，要是该变量实际上为空，就会抛出 NullPointerException
mSearchViewItem!!.collapse()
```

