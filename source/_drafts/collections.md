---
layout: "post"
title: "并发编程"
date: "2018-12-05 14:28"
categories: arch
tags: [concurrence]
---

## HashMap

- HashMap在并发场景下可能存在的问题：数据丢失、数据重复、死循环 [^1]
    - 关于死循环的问题，在Java8中已不存在。在Java8之前的版本中之所以出现死循环是因为在resize的过程中对链表进行了倒序处理；在Java8中不再倒序处理，自然也不会出现死循环
    - 产生原因：**hash碰撞与扩容导致**，具体分析见源码
        - 数据丢失：当两个线程同时进入到createEntry步骤，且hash碰撞导致`bucketIndex`相同，此时会先后修改`table[bucketIndex]`值，从而导致数据丢失
        - 数据重复：如果有两个线程同时发现自己都key不存在，而这两个线程的key实际是相同的。在向链表中写入的时候第一线程将e设置为了自己的Entry，而第二个线程执行到了e.next，此时拿到的是最后一个节点(null)，依然会将自己持有是数据插入到链表中，这样就出现了数据重复
        - 死循环：JDK1.7在resize时容易出现死循环，主要是因为hashMap在resize过程中对链表进行了一次倒序处理。假设两个线程同时进行resize，A->B 第一线程在处理过程中比较慢，第二个线程已经完成了倒序编程了B-A，那么就出现了循环B->A->B。这样就出现了就会出现CPU使用率飙升
- JDK1.7 HashMap源码解析

```java
public V put(K key, V value) {
    if (table == EMPTY_TABLE) { // 此处的table：HashMap底层是一个Entry(底层是一个链表)数组，一旦发生Hash冲突的的时候，HashMap采用拉链法解决碰撞冲突
        inflateTable(threshold);
    }
    if (key == null)
        return putForNullKey(value);
    int hash = hash(key); // 有可能不同的key最终得到的hash值一直，即为hash碰撞
    int i = indexFor(hash, table.length);
    // 两个线程同时插入相同的且不存在的key。线程一执行到e.next -> 发现为null -> 执行addEntry -> 此时线程二执行e.next -> 拿到的是最后一个节点null(正常应该是第一个节点对应的e) -> 再次执行addEntry。从而产生数据重复
    for (Entry<K,V> e = table[i]; e != null; e = e.next) { // e = null出现情况：table[i] = null 或 当前hash值的对应的Entry链表从链表头到尾都无此 hash-key(链表尾=null)
        Object k;
        if (e.hash == hash && ((k = e.key) == key || key.equals(k))) { // 符合，则相当于更新此map[key]的值
            V oldValue = e.value;
            e.value = value;
            e.recordAccess(this);
            return oldValue;
        }
    }

    modCount++;
    addEntry(hash, key, value, i); // 除了上述两线程同时table[i] = null时会同时执行；也有可能两线程获取的 table[i] 一直，且都是新增链表节点
    return null;
}

void addEntry(int hash, K key, V value, int bucketIndex) {
    if ((size >= threshold) && (null != table[bucketIndex])) {
        // JDK1.7此处在resize时容易出现死循环，主要是因为hashMap在resize过程中对链表进行了一次倒序处理。假设两个线程同时进行resize，A->B 第一线程在处理过程中比较慢，第二个线程已经完成了倒序编程了B-A，那么就出现了循环B->A->B。这样就出现了就会出现CPU使用率飙升
        resize(2 * table.length);
        hash = (null != key) ? hash(key) : 0;
        bucketIndex = indexFor(hash, table.length);
    }

    createEntry(hash, key, value, bucketIndex);
}

void createEntry(int hash, K key, V value, int bucketIndex) {
    Entry<K,V> e = table[bucketIndex]; // 获取数组中此元素(可能是put方法中的 table[i] 或者是扩容之后新的元素)保存的链表对象(链表头)
    // 当两个线程同时进入到createEntry步骤，且hash碰撞导致bucketIndex相同，此时会先后修改table[bucketIndex]值，从而导致数据丢失
    table[bucketIndex] = new Entry<>(hash, key, value, e); // 将链表头放到当前Entry的next属性，并将新链表对象(新链表头)保存到该数组元素中。相当于
    size++;
}
```
- https://juejin.im/post/5aa47ef2f265da23a0492cc8

















---

参考文章

[^1]: https://sq.163yun.com/blog/article/195978631766196224











