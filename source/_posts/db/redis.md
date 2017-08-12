---
layout: "post"
title: "redis"
date: "2016-07-02 12:11"
categories: db
tags: [redis, db]
---

## redis简介

Redis 是一款开源的，基于 BSD 许可的，高级键值 (key-value) 缓存 (cache) 和存储 (store) 系统。由于 Redis 的键包括 string，hash，list，set，sorted set，bitmap 和 hyperloglog，所以常常被称为数据结构服务器。

- 官网：[http://redis.io/](http://redis.io/)
- redis源码：[redis Github](https://github.com/antirez/redis)
- redis windows客户端(64x，官网不提供window安装包)：[https://github.com/MSOpenTech/redis](https://github.com/MSOpenTech/redis)
- java操作redis(jar)：[jedis Github](https://github.com/xetorthio/jedis)

## 安装Redis服务

1. Windows
    - 下载redis windows客户端（3.2.100）
    - 直接启动解压目录下的：`redis-server.exe`服务程序；`redis-cli.exe`客户端程序，即可在客户端使用命令行进行新增和查看数据（默认没有设置密码）
    - 设置密码
        - 修改`redis.windows.conf`，将`# requirepass foobared` 改成 `requirepass yourpassword`(行前不能有空格)
        - cmd进入到redis解压目录，运行`redis-server redis.windows.conf`，之后登录则需要密码

## java中操作Redis

- 引入jar包
  - 使用Java操作Redis需要jedis-2.1.0.jar，下载地址：http://files.cnblogs.com/liuling/jedis-2.1.0.jar.zip
  - 如果需要使用Redis连接池的话，还需commons-pool-1.5.4.jar，下载地址:http://files.cnblogs.com/liuling/commons-pool-1.5.4.jar.zip

- 使用连接池实例

```java
    /**
     * 构建redis连接池
     * @return JedisPool
     */  
    public static JedisPool getPool() {  
        if (pool == null) {  
            JedisPoolConfig config = new JedisPoolConfig();  
            //控制一个pool可分配多少个jedis实例，通过pool.getResource()来获取；  
            //如果赋值为-1，则表示不限制；如果pool已经分配了maxActive个jedis实例，则此时pool的状态为exhausted(耗尽)。  
            config.setMaxActive(500);  
            //控制一个pool最多有多少个状态为idle(空闲的)的jedis实例。  
            config.setMaxIdle(5);  
            //表示当borrow(引入)一个jedis实例时，最大的等待时间，如果超过等待时间，则直接抛出JedisConnectionException；  
            config.setMaxWait(1000 * 100);  
            //在borrow一个jedis实例时，是否提前进行validate操作；如果为true，则得到的jedis实例均是可用的；  
            config.setTestOnBorrow(true);  
            pool = new JedisPool(config, "localhost", 6379);  
        }  
        return pool;  
    }  

    /**
     * 返还到连接池
     *  
     * @param pool  
     * @param redis
     */  
    public static void returnResource(JedisPool pool, Jedis redis) {  
        if (redis != null) {  
            pool.returnResource(redis);  
        }  
    }  

    /**
     * 获取字符串数据示例
     *  
     * @param key
     * @return
     */  
    public static String get(String key){  
        String value = null;  

        JedisPool pool = null;  
        Jedis jedis = null;  
        try {  
            pool = getPool();  
            jedis = pool.getResource();  

            value = jedis.get(key);  
        } catch (Exception e) {  
            //释放redis对象  
            pool.returnBrokenResource(jedis);  
            e.printStackTrace();  
        } finally {  
            //返还到连接池  
            returnResource(pool, jedis);  
        }  

        return value;  
    }
```

## redis对模糊查询的缺陷及解决方案

使用[https://code.google.com/archive/p/redis-search4j/](redis-search4j) ，使用了分词，解决了中文的模糊查询。（效果不好，测试发现会在服务器中存储大量无用的key）


> 参考文章
>
> - [1] [http://www.runoob.com/redis/redis-tutorial.html](菜鸟教程)
>
> - [2] [http://wiki.jikexueyuan.com/project/redis-guide/](极客学院 Wiki)
>
> - [3] [http://www.cnblogs.com/edisonfeng/p/3571870.html](java对redis的基本操作)
