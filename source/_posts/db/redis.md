---
layout: "post"
title: "redis"
date: "2016-07-02 12:11"
categories: db
tags: redis
---

## Redis简介

- Redis 是一款开源的，基于 BSD 许可的，高级键值 (key-value) 缓存 (cache) 和存储 (store) 系统。由于 Redis 的键包括 `string`，`hash`，`list`，`set`，`sorted` `set`，`bitmap` 和 `hyperloglog`，所以常常被称为数据结构服务器
- [redis.cn](http://redis.cn/)、[官网：http://redis.io/](http://redis.io/)、[Redis Github](https://github.com/antirez/redis)
- 常见的缓存如：memcached、redis
    - memcached的value无类型概念，部分场景可使用json代替，但是如果要从value中过滤获取部分数据则需要在客户端完成(服务器只能返回整个value值)
    - redis的value有类型概念，弥补了memcached上述弊端
- redis windows客户端(64x，官网不提供window安装包)：[https://github.com/MSOpenTech/redis](https://github.com/MSOpenTech/redis)
- redis客户端连接管理软件：`RedisDesktopManager`
- `jedis`：java操作redis(jar)，[jedis Github](https://github.com/xetorthio/jedis)
- 常识
    - 磁盘寻址是ms级，带宽是G、M
    - 内存寻址是ns级，带宽很大；磁盘比内存寻址慢了10w倍
    - 磁盘扇区大小一般是512Byte，此时获取数据成本较高，因此无论读取数据多少，操作系统每次都是从磁盘中拿4K的数据
    - 计算机的2个基础设施
        - 冯诺依曼体系的硬件
        - 以太网，tcp/ip的网络
- bio-nio-select-epoll

![bio-nio-select-epoll](/data/images/linux/bio-nio-select-epoll.png)

## 安装Redis服务

- Windows
    - 下载redis windows客户端（3.2.100）
    - 直接启动解压目录下的：`redis-server.exe`服务程序；`redis-cli.exe`客户端程序，即可在客户端使用命令行进行新增和查看数据（默认没有设置密码）
    - 设置密码
        - 修改`redis.windows.conf`，将`# requirepass foobared` 改成 `requirepass yourpassword`(行前不能有空格)
        - cmd进入到redis解压目录，运行`redis-server redis.windows.conf`，之后登录则需要密码
- Linux
    
    ```bash
    ## 下载源码(或手动下载后上传)
    wget http://download.redis.io/releases/redis-5.0.8.tar.gz
    tar -zxvf redis-5.0.8.tar.gz
    cd redis-5.0.8
    # 可查看README.md进行安装

    ## 编译
    # 编译测试(可能会提示：Redis need tcl 8.5 or newer。解决办法：yum install tcl。其他问题参考：http://blog.csdn.net/for_tech/article/details/51880647)
    # 编译测试不通过也可正常运行
    make test # 可选
    make install # 需要有gcc(yum -y install gcc)
    # make distclean # 安装失败可进行清除
    # 编译成功后，可直接在源码目录运行命令(一般为临时测试)：启动 `src/redis-server`，客户端连接 `src/redis-cli`

    ## 安装
    make PREFIX=/opt/soft/reds5 install
    vi /etc/profile
    # 增加以下两行
    #export REDIS_HOME=/opt/soft/redis5
    #export PATH=$PATH:$REDIS_HOME/bin
    source /etc/profile
    redis-server # 即可启动服务
    
    ## 安装成服务
    # 一个物理机中可以有多个redis实例(进程)，通过port区分
    # 可执行程序就一份在目录，但是内存中未来的多个实例需要各自的配置文件，持久化目录等资源
    ./utils/install_server.sh
    # 安装成功后会自动启动(自启动脚本在/etc/init.d目录)，查看服务状态
    service redis_6379 status

    ## 测试
    redis-cli # 启动客户端
    127.0.0.1:6379> ping # PONG
    127.0.0.1:6379> set foo bar # 设置
    127.0.0.1:6379> get foo # bar, 取值
    ```

## 命令使用

- [string](#string)
    - 字符类型
    - 数值类型计算
    - bitmaps位图
- [list](#list)
    - 栈(同向操作)
    - 队列(反向操作)
    - 数组
    - 阻塞，单播队列(FIFO)
- [hash](#hash)
- [set](#set)
    - 无序去重集合
    - 随机事件，如可用于抽奖
- [sorted set](#sorted_set)

### 基础

```bash
redis-cli # 启动客户端
redis-cli -h # 进入命令行，也可输入help+Tab获取帮助，如`help set`
redis-cli -p 6379 -n 1 # 连接6379的第一个数据库(默认从0开始，总共有16个库)
redis-cli --raw # redis是二进制安全的。如果客户端以不同的编码(如GBK/UTF-8)连接；当GBK连接时存储"中"，则占用2个字节，如果UTF-8连接时，则占用3个字节；实际存储是按照二进制存储的，如果不加--raw默认以16进制显示(只能显示ASCII码)，加了--raw会按照此时的客户端连接编码进行解码显示出"中"

## redis-cli命令行，命令不区分大小写
exit # 退出redis-cli命令行
select 2 # 选择2号数据库
help @string # 查看string类型的相关操作
help set # 查看set命令：group为string则说明set操作的是字符串
keys * # 查看所有key
keys key* # 查看所有key开头的key
flushdb # 清空整个库(删除全部数据)，生产环境一般改写此命令
del key1 # 删除某个key
type key1 # 查看key1值的类型
object encoding key1 # 查看key1编码类型，如返回int说明此字符串可以进行计算
```

### 字符串(string)

```bash
set name smalle
get name # 返回 smalle

# 批量设置
mset k1 123 k2 v2
mget k1 k2 # 返回123、v2两行

# 追加，smalle, hi
append name ", hi"
# 获取索引8-9(左右都包含)之间的值
getrange name 8 9 # hi
# redis包含正负向索引，正向从左到右从0递增，负向从右到左从-1递减
getrange name 8 -1 # hi
# 插入，smalle, hello
setrange name 8 hello

# 查看字符串字节长度
strlen name # 13
type k1 # string，k2也是
object encoding k1 # int，k2返回embstr。key实际是一个对象

# 对数据值加1
incr k1 # 124，此时k2不能计算
# 对数据减去指定值
decrby k1 2 # 122

# nx表示如果不存在name这个key才允许创建。可用于分布式锁
set name hello nx
# m批量，nx不存在key才设置。此时会设置失败(但不会报错)，可用于原子性赋值操作
msetnx k1 100 k3 abc

# 基于二进制设置字符串，参考下文二进制图
setbit b1 1 1 # 设置b1的第1位(下标1/索引1，对应二进制位)值为1 => 01000000 => `get b1`得到字符值为@(可通过`man ascii`查看字符集) => `strlen b1`得到字节长度为1
setbit b1 7 1 # 基于之前的值设置 => 01000010(设置第7个二进制位为1) => 字符值为A => 字节长度为1
setbit b1 9 1 # 基于之前的值设置 => 01000010 01000000(中间实际没有空格，设置第9个二进制位为1) => 字符值为A@ => 字节长度为2
# 从b1中的第0个字节到第1个字节查找第一个1
bitpos b1 1 0 1 # 1
# 统计b1中0-1字节出现1的次数
bitcount b1 0 1 # 3

# 设置b2下标1的二进制位为1，最终得到b2=A(01000001)，b3=B(01000010)
setbit b2 1 1
setbit b2 7 1
setbit b3 1 1
setbit b3 6 1
# 按位与操作：有0则0，全1为1 => 且
bitop and andkey1 b2 b3 # andkey1=@ (01000000)
# 按位或操作：有1则1，全0为0 => 或
bitop or orkey1 b2 b3 # C(01000011)
```
- setbit二进制图

![redis-bit](/data/images/db/redis-bit.png)

### list

- 首字母L/R代表left/right，L有时候可能值list，B代表blocking
- list结构

![redis-list](/data/images/db/redis-list.png)

```bash
help @list
# 向左边插入数据(重复执行会重复往此key中追加)，最终为：c b a
lpush k1 a b c
# 向右边插入数据，最终为：a b c
rpush k2 a b c
# 获取list的从0到-1(最后一个)的数据
lrange k1 0 -1 # 返回 c b a 三行
# 弹出左边的元素(会从数组中删除这个元素) => FILO => lpush + lpop(同向操作)相当于栈
lpop k1 # 返回c，此时k1=[b, a]
# 弹出右边元素 => FIFO => lpush + rpop(反向操作)相当于队列
rpop k1 # 返回a，此时k1=[b]

# 获取k2的下标为2的元素 => 相当于数组
lindex k2 2 # c
# 设置k2下标2的值为d，k2=[a,b,b]
lset k2 2 b

# 在k2的第一个b元素后面(before/after)插入1，k2=[a,b,1,b]
linsert k2 after b 1
rpush k3 1 a a 2 a 2 2 # k3=[1,a,a,2,a,2,2]
# 从左边开始移除(count=2的值为正数则从左边开始移除)2个a元素，k3=[1,2,a,2,2]
lrem k3 2 a
# 从右边开始移除2元素1个，k3=[1,2,a,2]
lrem k3 -1 2

# 返回list长度
llen k2 # 3
# 如果list存在，则向左边插入值
lpushx kn 1 # (integer) 0

# 从左边弹出k4，如果k4没有则等待一定超时时间，0表示一直阻塞直到k4有值；如果有多个客户度阻塞弹出k4的值，则谁先阻塞谁先弹出，且一次只能弹出1个(放掉一个客户端) => 阻塞，单播队列，FIFO
blpop k4 0
```

### hash(map)

- 命令字母H开头表示hash

```bash
help @hash
# 设置smalle这个hash为 {name: smalle}
hset smalle name smalle
hset smalle age 18
hget smalle age # 18

hmget smalle name age # 返回smalle、18两行
hkeys smalle # 返回name、age两行
hgetall smalle # 返回name、smalle、age、18四行

# 对属性age增加0.5
hincrbyfloat smalle age 0.5 # 18.5
# 对属性age减少1
hincrbyfloat smalle age -1 # 17.5
```

### set

```bash
help @set
# 插入后无序，可能为k1=[c,b,d,a,e]
sadd k1 a b c d e a
# 获取集合(多次获取顺序一样)，返回c、b、d、a、e五行
smembers k1
# 返回集合元素个数
scard k1 # 5
# 移除元素b、c(修改后顺序可能编号)，移除后k1=[a,e,d]
srem k1 b c 
sadd k2 d e f
# 获取交集，直接返回e、d两行
sinter k1 k2
# 获取交集，将结果放到destkey中
sinterstore destkey k1 k2
# 获取并集，直接返回e、a、f、d
sunion k1 k2 
# 取差集(k1是被减数)，直接返回a
sdiff k1 k2
# 取差集，直接返回f
sdiff k2 k1
# 随机获取5个值，由于是正数，因此返回结果不会重复，但是结果数可能小于期望数
srandmember k1 5
# 随机获取5个值，由于是负数，因此结果可能会重复，结果数等于期望数
srandmember k1 -5
# 弹出一个值并返回(会移除此元素)
spop k1
```

### sorted_set

- Z开头命令表示sorted set，REV表示取反
- 排序细实现原理：[skip list(跳跃表)](/_posts/linux/algorithms.md#跳跃表(skip-list))

```bash
help @sorted_set
# 基于分值(会基于分值从小到大排序)添加元素，物理内存做小右大
zadd k1 5 apple 2 banana 7 orange

# 获取元素：banana,apple,orange
zrange k1 0 -1
# 获取元素和分值：banana,2,apple,5,orange,7
zrange k1 0 -1 withscores
# 取出分值4-7的元素：apple、orange
zrangebyscore k1 4 7
# rev取反：orange、apple
zrevrange k1 0 1

# 获取分数：5
zscore k1 apple
# 获取元素apple在集合中的下标：1
zrank k1 apple

# 对banana的分值加4.5 => 之后k1排序结果为：apple,5,banana,6.5,orange,7
zincrby k1 4.5 banana

zadd k2 3 apple 1 pear # k2为：pear,1,apple,3
# 取并集(会合计分值)，`zrange destkey1 0 -1` => pear,1,banana,6.5,orange,7,apple,8
zunionstore destkey1 2 k1 k2
# 基于权重(k1的权重为0.5，则k1的分值*0.5的权重后再去做加法)取并集 => pear,1,banana,3.25,orange3.5,apple,5.5
zunionstore destkey2 2 k1 k2 weights 0.5 1
```

## 进阶

### 使用场景

- `incr` 可用于统计不要求太精准的字段，如点赞数、评论数、抢购、秒杀等。从而规避并发下对数据库的事物操作，完全由redis内存操作代替
- `nx` 表示如果不存在此key时才允许创建。可用于分布式锁
- `msetnx`命令：nx如上，m表示set多个key，此时要么都成功要么都失败。可用于原子性赋值操作
- `setbit`位图命令使用

    ```bash
    ## 记录每个用户一年365天是否登录过 => 46字节*1000w ~= 460M => 相比存储空间小且速度快
    setbit smalle 0 1
    setbit smalle 7 1
    setbit smalle 364 1
    strlen smalle # 46，只需46个字节即可保存一个人一年的登录状态
    bitcount smalle -7 -1 # 1，获取用户最近一周的登录次数

    ## 统计一段时间的活跃用户数。假设A用户使用第1号位，B用户使用第7号位，且A用户在1-1、1-2号登录了，B用户只在1-2登录
    setbit 0101 1 1
    setbit 0102 1 1
    setbit 0102 7 1
    bitop or destkey 0101 0102
    bitcount destkey 0 -1 # 2 => 这两天的活跃用户数为2
    ```

### pipeline管道

- 在管道中可一次性发送多条命令

```bash
# nc连接服务器，然后直接发数据回车即可获得返回
# -e支持换行符，一次性发送多条命令
echo -e "set k1 1\nkeys *\nincr k1" | nc 127.0.0.1 6379

# 通过文件批量发送命令，pipe.txt中每一行一个命令
cat pipe.txt | redis-cli --pipe
```

### transactions事物

- 注意redis是单线程的，因此是按照时间先后顺序响应客户端命令

```bash
## 相关命令
multi # 开启一个事务，它总是返回 OK
exec # 提交事务。将每条命令的结果放在数组中返回
discard # 放弃事务。事务队列会被清空，并且客户端会从事务状态中退出
watch # 观测某个key(必须在multi之前)，可以为 Redis 事务提供 check-and-set（CAS）行为。如果开启事务前和提交事务前的值一致则事务提交成功(观测的客户端修改此值，事务可正常提交；其他客户端修改此值事务提交失败)；否则事务执行失败，返回(nil)，不报错
unwatch # 去掉所有观测

## 案例1
# 客户端1执行
multi
set k1 hello # 返回QUEUED
keys * # 返回QUEUED
# 客户端2执行
multi
get k1
# 客户端2执行，返回：1) (nil)
exec
# 客户端1执行，返回：1) OK、2) 1) "k1"
exec
# 如果客户端1先执行exec提交事务，客户端2后提交事务，则客户端2执行exec是返回：1) "hello"

## 案例2
# 客户端1执行
set k1 hello
watch k1
multi
get k1
# 客户端2执行
multi
set k1 world
exec
# 客户端1执行，此时返回：(nil)。由于观测的值以及发生了变化
exec
```

### redis作为缓存

- 缓存数据不重要、不是全量数据，缓存应该随着访问变化(保存热数据，内存是有限的)

#### key的有效期

- 通常Redis keys创建时没有设置相关过期时间，他们会一直存在，除非使用显示的命令移除，例如使用DEL命令
- `expire` 倒计时，当key执行过期操作时，Redis会确保按照规定时间删除他们(尽管中途使用过，过期时间也不会自动改变)。从 Redis 2.6 起，过期时间误差缩小到0-1毫秒
- `expireat` 定时失效
- 过期判定原理
    - 被动访问时判定、主动周期轮询判定(增量：随机取20个key判断，超过25%，则再取20个判断)
    - 目的，稍微牺牲下内存(延时过期)，但是保住了redis性能为王

```bash
set k1 "hello"
# 设置k1在10s之后过期(删除此key)。尽管中途使用过，过期时间也不会自动改变
expire k1 10
# 查看k1剩余有效期，-2表示此key已经不存在，-1表示此key永远不会过期
ttl k1 # (integer) 5、(integer) -2等
set k1 world
ttl k1 # (integer) -1

# 获取当前时间戳：1) "1594293836"、2) "713339"
time
set k2 hello
expireat k1 1594294836
ttl k2
```

#### 布隆和布谷鸟过滤器

- `布隆过滤器`(Bloom Filter)：一种比较巧妙的概率型数据结构，**它可以告诉你某种东西一定不存在或者可能存在**
    - 布隆过滤器相对于Set、Map 等数据结构来说，它可以更高效地插入和查询，并且占用空间更少。缺点是判断某种东西是否存在时，可能会被误判，但是只要参数设置的合理，它的精确度也可以控制的相对精确，只会有小小的误判概率
    - 牺牲存储空间来换查询速度

    ![redis-bloom](/data/images/db/redis-bloom.png)
- `布谷鸟过滤器`
    - 相比布谷鸟过滤器而言布隆过滤器有以下不足：查询性能弱、空间利用效率低、不支持反向操作（删除）以及不支持计数
- **解决缓存穿透的问题**
    - 一般情况下，先查询缓存是否有该条数据，缓存中没有时，再查询数据库。当数据库也不存在该条数据时，每次查询都要访问数据库，这就是缓存穿透。缓存穿透带来的问题是，当有大量请求查询数据库不存在的数据时，就会给数据库带来压力，甚至会拖垮数据库
    - 可以使用布隆过滤器解决缓存穿透的问题，把已存在数据的key存在布隆过滤器中。当有新的请求时，先到布隆过滤器中查询是否存在，如果缓存中不存在该条数据直接返回；如果缓存中存在该条数据再查询数据库
- redis中可以手动添加[布隆过滤器模块(包含布谷鸟)](https://github.com/RedisBloom/RedisBloom)，实际也可在客户端实现布隆算法从而到达过滤效果

```bash
# 安装
wget https://github.com/RedisBloom/RedisBloom/archive/v2.2.3.zip
yum install unzip
unzip v2.2.3.zip
cd RedisBloom-2.2.3/
make # 编译，会生成bloom.so库
cp redisbloom.so /opt/soft/redis5/

# 操作(该模块提供了bf.*、cf.*等命令)
redis-server --loadmodule /opt/soft/redis5/redisbloom.so # 启动时加载布隆过滤器模块
redis-cli
bf.add k1 123 # 通过布隆过滤器添加元素123到k1中
type k1 # MBbloom--
bf.exists k1 abc # (integer) 0，判断k1中是否存在abc
bf.exists k1 123 # (integer) 1

# 布谷鸟过滤器，使用同上
cf.add
cf.exists
```

#### 回收策略配置

- [将redis当做使用LRU算法的缓存来使用](http://redis.cn/topics/lru-cache.html)

```bash
# 编辑支持的最大内存(maxmemory)和回收策略
vi /etc/redis/6379.conf
# maxmemory <bytes>

# MAXMEMORY POLICY: how Redis will select what to remove when maxmemory
# is reached. You can select among five behaviors:
# volatile-lru -> Evict using approximated LRU among the keys with an expire set.   # 回收最久使用的键，但仅限于在过期集合的键
# allkeys-lru -> Evict any key using approximated LRU.                              # 回收最久使用的键
# volatile-lfu -> Evict using approximated LFU among the keys with an expire set.   # 回收最少使用的键，但仅限于在过期集合的键
# allkeys-lfu -> Evict any key using approximated LFU.                              # 回收最少使用的键
# volatile-random -> Remove a random key among the ones with an expire set.         # 随机回收建，但仅限于在过期集合的键
# allkeys-random -> Remove a random key, any key.                                   # 随机回收建
# volatile-ttl -> Remove the key with the nearest expire time (minor TTL)           # 回收在过期集合的键，并且优先回收存活时间（TTL）较短的键
# noeviction -> Don't evict anything, just return an error on write operations.     # 当客户端需要使用更多内存，且内存不足时返回错误
#
# LRU means Least Recently Used # 最近使用的
# LFU means Least Frequently Used # 最频繁使用的
# 
# The default is:
# maxmemory-policy noeviction
```

### redis作为数据库

- 数据不能丢失，即需要做持久化
- `RDB`方式
    - 使用fork()进程时的`copy on write`来实现，参考![特殊符号-管道符`|`](/_posts/linux/shell.md#特殊符号)
    - 特点
        - 优点：恢复速度相对快
        - 不支持拉链，只有一个dump.rdb文件
        - 丢失数据相对多一些，两次持久化话之间的数据容易丢失
    - rdb配置

        ```bash
        ################################ SNAPSHOTTING  ################################
        # save "" # 关闭写磁盘

        # 以下条件将会被触发自动保存 => 创建子进程进行数据持久化
        save 900 1 # 当900s后有1个key发生了改变则会触发save
        save 300 10 # 当300s后有10个key发生了改变则会触发save
        save 60 10000

        # 数据持久化的文件名
        dbfilename dump.rdb
        # 数据保存的文件目录
        dir /var/lib/redis/6379
        ```
- `AOF`(Append Only Mode) Redis的写操作记录到文件中
    - 丢失数据少
    - 弊端：体量大、恢复慢。减少日志量的方法如下
        - v4.0前，重写(删除抵消的命令，合并重复的命令)
        - v4.0后，重写前先将老的数据RDB到AOF文件中，将增量以指令的方式Append到AOF中(AOF使用了RDB的快速，利用了日志的全量)
    - redis中，RDB和AOF可同时开启。如果开启了AOF，只会用AOF恢复。v4.0后，AOF包含RDB全量，增加记录新的写操作
    - redis当做内存数据库，写操作会触发IO，相关配置如

        ```bash
        ############################## APPEND ONLY MODE ###############################
        # 默认是关闭AOF，开启设置成yes
        appendonly no
        # 记录日志的文件
        appendfilename "appendonly.aof"

        # 进行flush的时机
        # appendfsync always # 每个写指令都进行flush
        appendfsync everysec # 每秒调用flush
        # appendfsync no # redis不控制flush，交由OS控制
        ```




## 应用

### 解决session一致性(session共享)

参考《nginx》的【反向代理和负载均衡】部分

### springboot使用redis

- 引入依赖

    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    ```
- 使用

    ```java
    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    // 存储Value
    redisTemplate.opsForValue().set("myRedisKey", "hello world");
    redisTemplate.opsForValue().get("myRedisKey");

    // 存储Map
    redisTemplate.opsForHash().put("myRedisKey", "myMapKey", "hello world");
    redisTemplate.opsForHash().get("myRedisKey", "myMapKey");
    ```

### java中操作Redis

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

### redis对模糊查询的缺陷及解决方案

> redis本身适合作为缓存工具，不建议使用模糊查询等操作

- 使用[https://code.google.com/archive/p/redis-search4j/](redis-search4j) ，使用了分词，解决了中文的模糊查询。（效果不好，测试发现会在服务器中存储大量无用的key）


---

参考文章

[^1]: http://www.runoob.com/redis/redis-tutorial.html (菜鸟教程)
[^2]: http://wiki.jikexueyuan.com/project/redis-guide/ (极客学院 Wiki)
[^3]: http://www.cnblogs.com/edisonfeng/p/3571870.html (java对redis的基本操作)
