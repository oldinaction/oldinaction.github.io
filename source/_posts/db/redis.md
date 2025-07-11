---
layout: "post"
title: "redis"
date: "2016-07-02 12:11"
categories: db
tags: redis
---

## Redis简介

- [redis.cn](http://redis.cn/)、[官网：http://redis.io/](http://redis.io/)、[Redis Github](https://github.com/antirez/redis)、[redis 在线测试](https://try.redis.io/)
- Redis
    - 是一款开源的，基于 BSD 许可的，高级键值 (key-value) 缓存 (cache) 和存储 (store) 系统
    - 由于 Redis 的键包括 `string`，`hash`，`list`，`set`，`sorted set`，`bitmap` 和 `hyperloglog`，所以常常被称为数据结构服务器
    - 单实例，单进程、单线程(epoll)，占用资源少(单实例只使用1M内存)
        - 版本3.×（最早版本）为单线程
        - 版本4.×，负责处理客户端请求的线程单线程，但是开始加了点多线程的东西（异步删除）
        - 版本6.x 开始，全面支持多线程。将网络数据读写、请求协议解析通过多个IO线程来处理，真正执行命令的线程仍然是主线程单独进行操作
- [常见的缓存memcached、redis比较参考](/_posts/arch/分布式架构原理及选型方案.md#缓存)
- redis windows客户端(64x，官网不提供window安装包)：[https://github.com/MSOpenTech/redis](https://github.com/MSOpenTech/redis)
- redis客户端连接管理软件
    - Navicat Premium 17支持redis
    - (推荐)[AnotherRedisDesktopManager](https://github.com/qishibo/AnotherRedisDesktopManager/releases/tag/v1.5.9)
    - [RedisDesktopManager](https://github.com/RedisInsight/RedisDesktopManager/releases/tag/0.9.3)
- java操作redis(客户端jar)
    - [Redisson](https://github.com/redisson/redisson)
    - [jedis](https://github.com/xetorthio/jedis)
- bio-nio-select-epoll，参考[网络IO](/_posts/linux/计算机底层知识.md#网络IO)

![bio-nio-select-epoll](/data/images/linux/bio-nio-select-epoll.png)

## 安装Redis服务

- Windows
    - 方式一: 下载[Redis-7.4.2-Windows-x64-cygwin-with-Service.zip](https://github.com/redis-windows/redis-windows/releases)
        - 执行`install_redis_service.bat`安装到服务；默认没有设置密码，可修改redis.conf设置requirepass参数
    - 方式二: 下载redis windows客户端（3.2.100）：[https://github.com/MSOpenTech/redis](https://github.com/MSOpenTech/redis)
        - 直接启动解压目录下的：`redis-server.exe`服务程序；`redis-cli.exe`客户端程序，即可在客户端使用命令行进行新增和查看数据（默认没有设置密码）
    - **设置密码**
        - 修改`redis.windows.conf`，将`# requirepass foobared` 改成 `requirepass your_password`(行前不能有空格)
        - cmd进入到redis解压目录，运行`redis-server redis.windows.conf`，之后登录则需要密码
- Linux

```bash
## 简单的可直接安装
yum install redis -y
# 配置文件 /etc/redis.conf，如果需要密码，需先修改配置文件后启动
systemctl restart redis && systemctl enable redis && systemctl status redis

## 下载源码(或手动下载后上传)
wget http://download.redis.io/releases/redis-5.0.8.tar.gz
tar -zxvf redis-5.0.8.tar.gz
cd redis-5.0.8
# 可查看README.md进行安装

## 编译及安装
# 编译测试(可能会提示：Redis need tcl 8.5 or newer。解决办法：yum install tcl。其他问题参考：http://blog.csdn.net/for_tech/article/details/51880647)
# 编译测试不通过也可正常运行
make test # 可选，make需要有gcc(yum -y install gcc)
make install # 在源码目录安装(建议如下文安装到特定目录)
# make distclean # 安装失败可进行清除
# 编译成功后，可直接在源码目录运行命令(一般为临时测试)：启动 `src/redis-server`，客户端连接 `src/redis-cli`

## 安装到特定目录
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
./utils/install_server.sh # 默认即可。多次运行安装多节点时可输入不同的端口
# 安装成功后会自动启动(自启动脚本在/etc/init.d目录)并设置为开机启动，查看服务状态。像创建Redis Cluster仍然需要源码中的脚本
service redis_6379 status

## 测试
redis-cli # 启动客户端
127.0.0.1:6379> ping # PONG
127.0.0.1:6379> set foo bar # 设置
127.0.0.1:6379> get foo # bar, 取值
```
- Mac
    - 安装 `brew install redis`
    - 启动 `brew services start redis`
    - 配置文件路径如`/opt/homebrew/etc/redis.conf`
- 解决服务器Redis无法连接问题(内网)：https://blog.csdn.net/qq_57408330/article/details/129681386

### 配置文件

```bash
# 如果设置为yes，那么只允许我们在本机的回环连接，其他机器无法连接
# protected-mode设置为yes的情况下，为了我们的应用服务可以正常访问Redis，我们需要设置Redis的bind参数或者密码参数requirepass
protected-mode yes
```

## 命令使用

- [string](#string)
    - 字符类型
    - 数值类型计算
    - bitmap位图
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
redis-cli -h # 进入命令行，也可输入help + 空格 +Tab获取帮助，如`help @set`
redis-cli -p 6379 -n 1 -a <password> # 连接6379的第一个数据库(默认从0开始，总共有16个库)
# redis是二进制安全的
# 如果客户端以不同的编码(如GBK/UTF-8)连接；当GBK连接时存储"中"，则占用2个字节，如果UTF-8连接时，则占用3个字节
# 实际存储是按照二进制存储的，如果不加--raw默认以16进制显示(只能显示ASCII码)，加了--raw会按照此时的客户端连接编码进行解码显示出"中"
redis-cli --raw
redis-cli --pipe # cat pipe.txt | redis-cli --pipe # 通过文件批量发送命令，pipe.txt中每一行一个命令

## redis-cli命令行，命令不区分大小写
exit # 退出redis-cli命令行
help @string # 查看string类型的相关操作
help set # 查看set命令：group为string则说明set操作的是字符串
info # 查看服务器信息
info Replication # 查看服务器主从复制相关信息

select 2 # 选择2号数据库
flushdb # 清空整个库(删除全部数据)，生产环境一般改写此命令
keys * # 查看所有key，生产环境一般改写此命令
keys key* # 查看所有key开头的key
del key1 # 删除某个key

type key1 # 查看key1值的类型
object encoding key1 # 查看key1编码类型，如返回int说明此字符串可以进行计算
```

### 字符串(string)

```bash
set name smalle
get name # 返回 smalle
getset <key> <value> # 设置key的值并返回旧值

# 基于命名空间(namespace)定义key名(可视化可分目录展示成app1/module1/name)
set app1:module1:name smalle

# 批量设置
mset k1 123 k2 v2
mget k1 k2 # 返回123、v2两行

# 追加
append name ", hi" # smalle, hi
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
# 从b1中的第0个字节到第1个字节查找第一个1的下标
bitpos b1 1 0 1 # 1
# 统计b1中第**0到1字节(前16位)**出现1的次数
bitcount b1 0 1 # 3
# 统计b1中第**0到-1(倒数第二位)字节(即除掉倒数第一个字节)**出现1的次数
bitcount b1 0 -1 # 3

# 设置b2下标1的二进制位为1，最终得到b2=A(01000001)，b3=B(01000010)
setbit b2 1 1
setbit b2 7 1
setbit b3 1 1
setbit b3 6 1
# 按位与操作，并将结果赋值给andkey1：有0则0，全1为1 => 且
bitop and andkey1 b2 b3 # andkey1=@ (01000000)
# 按位或操作：有1则1，全0为0 => 或
bitop or orkey1 b2 b3 # C(01000011)
```
- setbit二进制图

![redis-bit](/data/images/db/redis-bit.png)

### list

- 首字母L/R代表left/right，L有时候可能指list，B代表blocking
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
# 从右边（负号）开始移除1个"2"元素，k3=[1,2,a,2]
lrem k3 -1 2

# 返回list长度
llen k2 # 3

# 如果kn1对应的list存在，则向左边插入值。此时不存在
lpushx kn1 1 # (integer) 0

# 从左边弹出k4，如果k4没有则等待一定超时时间，0表示一直阻塞直到k4有值；如果有多个客户端阻塞弹出k4的值，则谁先阻塞谁先弹出，且一次只能弹出1个(放掉一个客户端) => 阻塞，单播队列，FIFO
blpop k4 0
```

### hash(map)

- 命令字母H开头表示hash

```bash
help @hash
# 设置h1这个hash为 {name: test}
hset h1 name test
hset h1 age 18
hget h1 age # 18

hmget h1 name age # 返回test、18两行
hkeys h1 # 返回name、age两行
hgetall h1 # 返回name、test、age、18四行

# 对属性age增加0.5（负数则表示减少）
hincrbyfloat h1 age 0.5 # 18.5
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
# 移除元素b、c(修改后顺序可能变化)，移除后k1=[a,e,d]
srem k1 b c
sadd k2 d e f
# 获取交集（intersection），直接返回e、d两行
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

- Z开头命令表示sorted set，REV表示取反（reversal）
- 排序器实现原理：[skip list(跳跃表)](/_posts/linux/algorithms.md#跳跃表(skip-list))

```bash
help @sorted_set
# 基于分值(会基于分值从小到大排序)添加元素，物理内存左小右大
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
- `set my_lock id_12345678 nx ex 60` 实现**分布式锁**(nx不存在才能创建进行加锁，ex过期时间是60s防止死锁)，参考下文[实现分布式锁](#实现分布式锁)。其中nx表示如果不存在此key时才允许创建
- `msetnx`命令：nx如上，m表示set多个key，此时要么都成功要么都失败。可用于字符串类型的**原子性赋值操作**
- `setbit`位图命令使用。参考上文setbit相关案例

    ```bash
    ## 记录每个用户一年365天是否登录过 => 46字节*1000w ~= 460M => 相比存储空间小且速度快
    setbit smalle 0 1
    setbit smalle 7 1
    setbit smalle 364 1
    strlen smalle # 46，只需46个字节即可保存一个人一年的登录状态
    bitcount smalle -7 -1 # 1，获取用户最近一周的登录次数；bitcount统计smalle中-7到-1字节(最后7个字节)出现1的次数

    ## 统计一段时间的活跃用户数。假设A用户使用第1号位，B用户使用第7号位，且A用户在1-1(0101)、1-2(0102)号登录了，B用户只在1-2登录
    setbit 0101 1 1
    setbit 0102 1 1
    setbit 0102 7 1
    bitop or destkey 0101 0102 # 按位或操作，并将结果赋值给destkey
    bitcount destkey 0 -1 # 2 => 这两天的活跃用户数为2
    ```

### 发布订阅

```bash
# 客户端A往p1通道里面发送消息
publish p1 hello
# 客户端B监听在通道p1上(可监听多个)，会阻塞客户端；由于在A发送消息之后监听，因此默认无法收到之前的消息
subscribe p1 # 执行后打印3行：1) "subscribe"、2) "p1"、3) (integer) 1
publish p1 hi # 客户端A再次发送消息，客户端B收到消息：1) "message"、2) "p1"、3) "hi"

# 基于正则(通道名)监听消息，可写多个正则。此时*表示监听所有通道消息
psubscribe * # 收到消息时打印如：1) "pmessage"、2) "*"、3) "p2"、4) "hi"
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
# 观测某个key(必须在multi之前)，可以为 Redis 事务提供 check-and-set（CAS）行为
# 如果开启事务前和提交事务前的值一致则事务提交成功(观测的客户端修改此值，事务可正常提交；其他客户端修改此值事务提交失败)；
# 否则事务执行失败，返回(nil)，不报错
watch
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

### 数据有效期(作为缓存)

- redis作为缓存数据不重要、不是全量数据，缓存应该随着访问变化(保存热数据，内存是有限的)

#### key的有效期

- 通常Redis keys创建时没有设置相关过期时间，他们会一直存在，除非使用显示的命令移除，例如使用DEL命令
- `expire` 倒计时，当key执行过期操作时，Redis会确保按照规定时间删除他们(尽管中途使用过，过期时间也不会自动改变)。从 Redis 2.6 起，过期时间误差缩小到0-1毫秒
- `expireat` 设定再某个时间点失效
- `pexpire` 基于正则的倒计时
- `pexpireat`
- 过期判定原理：**被动访问判定、主动轮询判定**
    - 被动访问判定：当访问某个key时判断其是否过期，过期则先执行移除
    - 主动轮询判定为增量
      - 默认每秒进行10次扫描，每次随机取20个key判断，超过25%过期，则再取20个判断，并且默认的每次扫描时间上限不会超过25ms
      - 目的：redis是单线程，此时稍微牺牲下内存(延时过期)，但是保住了redis性能为王

```bash
## expire和expireat
set k1 "hello"
# 设置k1在10s之后过期(删除此key，设置为负值则相当于认为已经过期)。尽管中途使用过，初始过期时间也不会自动改变(且实际过期时间会随着时间流逝而减少)
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

## 注意事项
# 1.设值并设置过期时间为300s
set k3 hello ex 300
# 2.set/getset会丢失过期时间；incr/lpush/hset不会丢失过期时间
set k3 hi # 过期时间会丢失
# 3.持久化一个key，会清除过期时间
persist k3
# 4.重命名key，过期时间会转到新key上
rename k2 k2_new 
```

#### 回收策略配置/数据淘汰机制

- 回收策略不同于上文过期策略，二者有一定的区别
- [将redis当做使用LRU算法的缓存来使用](http://redis.cn/topics/lru-cache.html)

```bash
# 编辑支持的最大内存(maxmemory)和回收策略
vi /etc/redis/6379.conf

# maxmemory <bytes> # 配置Redis存储数据时指定限制的内存大小，比如100m。**当缓存消耗的内存超过这个数值时, 将触发数据淘汰**。该数据配置为0时，表示缓存的数据量没有限制, 即LRU功能不生效。64位的系统默认值为0，32位的系统默认内存限制为3GB

# MAXMEMORY POLICY: how Redis will select what to remove when maxmemory
# is reached. You can select among five behaviors:
# volatile-lru -> Evict using approximated LRU among the keys with an expire set.   # 回收最久使用的键，但仅对设置了过期时间的键
# allkeys-lru -> Evict any key using approximated LRU.                              # 回收最久使用的键
# volatile-lfu -> Evict using approximated LFU among the keys with an expire set.   # 回收最少使用的键，但仅对设置了过期时间的键
# allkeys-lfu -> Evict any key using approximated LFU.                              # 回收最少使用的键
# volatile-random -> Remove a random key among the ones with an expire set.         # 随机回收建，但仅对设置了过期时间的键
# allkeys-random -> Remove a random key, any key.                                   # 随机回收建
# volatile-ttl -> Remove the key with the nearest expire time (minor TTL)           # 回收生存时间TTL(Time To Live)更小的键（即将过期），但仅对设置了过期时间的键
# noeviction -> Don't evict anything, just return an error on write operations.     # 当客户端需要使用更多内存，且内存不足时返回错误
#
# LRU means Least Recently Used # 最近使用的
# LFU means Least Frequently Used # 最频繁使用的
# 
# The default is:
# maxmemory-policy noeviction
```

### 持久化(数据库)

- redis持久化主要有：RDB、AOF、**AOF&RDB**(默认)
- redis作为数据库，数据不能丢失，即需要做持久化，一般使用AOF(最好结合RDB)；如果作为缓存使用RDB就行，数据丢失可再从数据库获取

#### RDB方式持久化

- 调用bgsave命令时，使用`fork()`进程时的`copy-on-write`写时复制机制来实现。具体参考[Copy-On-Write写时复制](/_posts/linux/计算机底层知识.md#Copy-On-Write写时复制)
- RDB特点
    - 优点：恢复速度相对快
    - 不支持拉链，只有一个dump.rdb文件(为二进制编码，但是以REDIS开头)
    - 丢失数据相对多一些，两次持久化之间的数据容易丢失
- rdb配置

```bash
################################ SNAPSHOTTING  ################################
# save "" # 关闭写磁盘

# 以下条件将会被触发自动保存 => 创建子进程进行数据持久化
save 900 1 # 当900s(15m)后有1个及以上key发生了改变则会触发save
save 300 10 # 当300s(5m)后有10个及以上key发生了改变则会触发save
save 60 10000 # 当60s(1m)...
# 如900后有1个key发送改变时的日志如下
# 7447:S 11 Jul 2020 15:49:17.306 * 1 changes in 900 seconds. Saving...
# 7447:S 11 Jul 2020 15:49:17.307 * Background saving started by pid 7582           # 开启（fork）新进程保存数据到磁盘
# 7582:C 11 Jul 2020 15:49:17.514 * DB saved on disk                                # 数据已经保存到磁盘上
# 7582:C 11 Jul 2020 15:49:17.515 * RDB: 4 MB of memory used by copy-on-write       # 4M 内存数据使用copy-on-write的方式被使用
# 7447:S 11 Jul 2020 15:49:17.551 * Background saving terminated with success       # 保存成功, 进程中断

# 数据持久化的文件名
dbfilename dump.rdb
# 数据保存的文件目录
dir /var/lib/redis/6379
```
- 执行备份导出及导入

```bash
## 连接待导出的redis成功后. 查看目录，如: /var/lib/redis
config get dir
# redis命令行执行`save`(会占用主进程)或`bgsave`(后台运行)生成dump文件
bgsave
# 备份完成后，进入到对应目录下载文件 /var/lib/redis/dump.rdb

## 连接待导入的redis成功后. 查看配置目录，备份当前redis的dump.rdb，并停止redis
# 覆盖导出的dump.rdb到当前redis目录
# 重启redis即可
```

#### AOF方式持久化

- `AOF`(Append Only Mode) Redis的写操作记录到文件中。默认是关闭的，可通过配置文件`appendonly yes`开启
- 特点
    - 丢失数据少
    - 弊端：体量大、恢复慢。减少日志量的方法如下可通过重写实现
- AOF重写
    - 手动重写命令rewriteaof和bgrewriteaof
    - aof自动重写条件参考下文配置文件
    - 重写时先fork一个子进程并创建aof临时文件，然后将数据库中的数据通过命令保存到aof临时文件(如果开启了AOF&RDB混合使用，则将数据通过RDB的方式保存到AOF临时文件中)，最后用临时文件覆盖掉原AOF文件
- 推荐使用**AOF&RDB混合使用**
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

# aof自动重写，也可调用bgrewriteaof手动重写。AOF重写不会读取老的AOF文件，而是根据当前服务器的状态生成一份新的AOF文件，将老的AOF文件进行替换
# aof文件增长比例，指当前aof文件比上次重写的增长比例大小为100%时触发重写
auto-aof-rewrite-percentage 100
# aof文件重写最小的文件大小，即最开始aof文件必须要达到这个文件时才触发，后面的每次重写就不会根据这个变量了(根据上一次重写完成之后的大小)
auto-aof-rewrite-min-size 64mb

# 是否开启RDB和AOF混合使用(v4.0才有，重写前先将老的数据RDB到AOF文件中)
aof-use-rdb-preamble yes
```
- aof文件说明

```bash
# 表示是RDB和AOF混合使用
#REDIS...
# *代表需要读取的记录行，此时读取两个：select 0
*2
# $表示读取的字节
$6
# 为实际的命令组成
select
$1
0
```

### 集群方式

- redis单机(单节点、单实例)问题
    - 单点故障
    - 容量有限
    - 压力太大
- AKF拆分原则
    - X轴：表示主备，全量备份
    - Y轴：基于业务模块进行细分，可再结合X周特性进行主备
    - Z轴：在XY的情况下，对某模块下的单一业务再次划分XY(如对用户基于身份证号进行划分)
    - 设计微服务的4个原则：AKF拆分原则、前后端分离原则、无状态服务、Restful的通信风格
- 数据同步方式
    - 同步(强一致性)：client对主请求，主保存数据后通知给备，等所有备返回后再返回给client。可能丢失可用性
    - 异步(弱一致性)：client对主请求，主保存数据后立即返回给client。之后再同步给备。可能产生数据不一致
    - 队列(最终一致性)：client对主请求，主保存数据后并发送给队列(如kafka)，然后返回给client。之后从节点从队列中获取数据并保存
- 主备和主从(redis的这两种模式可进行配置，默认主备)
    - 主备：一般只有主对外提供服务(无特殊说明，有时候提到的主从也是主备的意思)
    - 主从：主提供全量服务，从提供部分服务
    - 这两种情况都需要有一个主，如果主挂了则也不可用，因此需要对主做高可用(HA)
- 高可用(HA)方式
    - 一般使用奇数节点监控，并超过半数进行主备切换
        - 为什么使用奇数节点进行监控：如3台和4台都允许挂1台，同样的情况使用4台更容易挂掉一台
- 集群相关配置

```bash
# 当一个slave失去和master的连接，或者同步正在进行中，slave的行为有两种可能：
# 1) "yes" (默认值)，slave会继续响应客户端请求，可能是正常数据，也可能是还没获得值的空数据
# 2) "no"，slave会回复"正在从master同步（SYNC with master in progress）"来处理各种请求，除了 INFO 和 SLAVEOF 命令
replica-serve-stale-data yes
# 从节点是否为只读(no则可接受写请求)
replica-read-only yes
# 是否不使用磁盘方式进行同步。同步策略: 磁盘或socket(网络)，默认磁盘方式；磁盘方式表示先数据线落到主节点磁盘，然后同步给子节点；网络方式表示直接通过网络同步给子节点
repl-diskless-sync no
# 设置数据备份的backlog大小。backlog是一个slave在一段时间内断开连接时记录新增的数据缓冲，所以一个slave在重新连接时，不必要全量的同步，而是一个增量同步就足够了，将在断开连接的这段时间内把slave丢失的部分数据传送给它
# 同步的backlog越大，slave能够进行增量同步并且允许断开连接的时间就越长。backlog只分配一次并且至少需要一个slave连接
repl-backlog-size 1mb
# 当健康的slave的个数小于3个时，mater就禁止写入。这个配置虽然不能保证N个slave都一定能接收到master的写操作，但是能避免没有足够健康的slave的时候，master不能写入来避免数据丢失。设置为0是关闭该功能，默认是关闭
min-replicas-to-write 3
# 延迟小于等于10秒的slave才认为是健康的slave。是从最后一个从slave接收到的ping（通常每秒发送）开始计数
min-replicas-max-lag 10
```

#### Redis Cluster

- [Redis官方集群方案](https://redis.io/topics/cluster-tutorial)
- redis预分区

    ![redis-预分区](/data/images/db/redis-预分区.png)
    - 假设刚开始只有2个节点，一般此时算法是hash%2，此时可改成直接hash%10(实际会更大，Redis 集群有16384个哈希槽)，那么所有数据会在刚开始就分布在不同的槽位(0-9)；当新增节点时，只需要将部分槽位的数据复制到新节点即可；当客户端查询的数据不在该节点时，会自动路由到目标节点
- Redis Cluster特点
    - 多主(高可用)多从(主备模式)，去中心化，支持分区：从节点作为备用，复制主节点，不做读写操作，不提供服务
    - 支持动态扩容节点
    - 节点之间相互通信，相互选举，不再依赖sentinel
        - 相比较sentinel模式，多个master节点保证主要业务（比如master节点主要负责写）稳定性，不需要搭建多个sentinel实例监控一个master节点
        - Sentinel模式主要针对高可用（HA），而Cluster模式是不仅针对大数据量，高并发，同时也支持HA
    - 直连某个redis，会自动进行跳转（下文的代理则是连接代理端口）
    - 部分情况下，支持事物（多条命令执行期间，没有进行redis端口跳转的情况下才支持）
    - 支持hash tag
- Redis Cluster测试

```bash
# Redis Cluster 在5.0之后取消了ruby脚本 redis-trib.rb的支持。而是集成在redis-cli进行集群管理，查看Redis Cluster帮助
redis-cli --cluster help

## 安装
# 进入redis源码目录，查看README文件的集群配置帮助
utils/create-cluster
# 可修改配置，如PORT、NODES、REPLICAS
vi create-cluster
./create-cluster start # 启动实例
# 创建集群(需要输入yes进程插槽划分)：创建6个节点，--cluster-replicas为1表示创建一个副本(从节点)，因此是6/(1+1)=3套主从(3个主，3个从，一般是前3个节点为主)
redis-cli --cluster create 127.0.0.1:30001 127.0.0.1:30002 127.0.0.1:30003 127.0.0.1:30004 127.0.0.1:30005 127.0.0.1:30006 --cluster-replicas 1

## 测试
redis-cli -c -p 30001 # 使用以上其他端口进行连接亦可
# redis命令操作记录
127.0.0.1:30001> set k1 1
# -> Redirected to slot [12706] located at 127.0.0.1:30003      # 根据key进行hash得出k1应该在30003上，因此自动路由(跳转)到30003
# OK
127.0.0.1:30003> set k2 2
# -> Redirected to slot [449] located at 127.0.0.1:30001        # k2应该在30001上，再跳转到30001
# OK
127.0.0.1:30001> set k3 3
# OK
127.0.0.1:30001> multi                                          # 在30001上开启了事物
# OK
127.0.0.1:30001> set k1 2                                       # k1在30003上，因此跳转到了30003
# -> Redirected to slot [12706] located at 127.0.0.1:30003
# OK
127.0.0.1:30003> exec                                           # 在30003上提交事物报错，因为30003并没有开启事物
# (error) ERR EXEC without MULTI
127.0.0.1:30003> set {order}k1 1                                # 基于hash tag设置(相同tag会落到同一机器)
OK
127.0.0.1:30003> multi
OK
127.0.0.1:30003> set {order}k1 2
QUEUED
127.0.0.1:30003> exec                                           # 提交事物成功。此结果是因为中途没有跳转到其他机器，如果跳转到其他机器事物仍然执行失败
1) OK
```

#### 基于docker搭建集群

- (3主3从)参考：https://juejin.cn/post/7095675331696132127
    - 需要提前创建网络如`docker network create sq-redis`

#### 主备设置实践(replicaof)

- 推荐使用[Redis Cluster(参考下文)](#Redis%20Cluster)
- 主备设置相关命令

```bash
# 在备节点(6380)中运行，追随主节点(6379)。5.0之前的命令使用slaveof
replicaof 127.0.0.1 6379 # 此时会先把备节点的数据删除掉，然后再同步主节点数据
# 当主节点挂了之后，此时可手动将某个从节点设置为不追随(此时数据不会丢失)，然后将其他从节点通过replicaof命令重新追随新的主
replicaof no one
```

<details>
<summary>主备配置完整测试(伪主备)</summary>

```bash
# 1.在一台机器上安装2个redis服务(伪主备)，先关闭所有redis服务，之后手动启动
# 2.复制一份配置文件出来测试(生产环境不需要)。修改配置文件中的port端口，修改`daemonize no`(不后台运行)，注释`logfile /var/log/redis_xxx.log`(日志打印在前台)
cp /etc/redis/6379.conf .
cp /etc/redis/6380.conf .

# 3.启动服务端，打印日志如下
redis-server ./6379.conf
redis-server ./6380.conf
# 打印日志如
# 7507:M 11 Jul 2020 15:33:15.083 * DB loaded from disk: 0.000 seconds
# 7507:M 11 Jul 2020 15:33:15.083 * Ready to accept connections

# 4.启动2个客户端连接不同的服务端
redis-cli -p 6379 # A客户端
redis-cli -p 6380 # B

# 5.B客户端执行，使6380追随6379。或者在启动6380时使用`redis-server --port 6380 --slaveof 127.0.0.1 6379`(也可写到配置文件)
replicaof 127.0.0.1 6379
# 此时6379打印日志(PID: 7442)
# 7442:M 11 Jul 2020 15:35:11.247 * Replica 127.0.0.1:6380 asks for synchronization
# 7442:M 11 Jul 2020 15:35:11.247 * Partial resynchronization not accepted: Replication ID mismatch (Replica asked for '8a87f600ddb2cace3efff018319c1964f0c38909', my replication IDs are '8a51a8a1a9eddd18477322b15611a839230c2cb9' and '0000000000000000000000000000000000000000')
# 7442:M 11 Jul 2020 15:35:11.247 * Starting BGSAVE for SYNC with target: disk      # 开始保存数据到磁盘
# 7442:M 11 Jul 2020 15:35:11.455 * Background saving started by pid 7549           # 开启（fork）新进程保存数据到磁盘
# 7549:C 11 Jul 2020 15:35:11.641 * DB saved on disk
# 7549:C 11 Jul 2020 15:35:11.642 * RDB: 6 MB of memory used by copy-on-write
# 7442:M 11 Jul 2020 15:35:11.655 * Background saving terminated with success
# 7442:M 11 Jul 2020 15:35:11.655 * Synchronization with replica 127.0.0.1:6380 succeeded
# 此时6380打印日志(PID: 7447)
# 7447:S 11 Jul 2020 15:35:11.145 * Before turning into a replica, using my master parameters to synthesize a cached master: I may be able to synchronize with the new master with just a partial transfer.
# 7447:S 11 Jul 2020 15:35:11.145 * REPLICAOF 127.0.0.1:6379 enabled (user request from 'id=3 addr=127.0.0.1:41764 fd=7 name= age=55 idle=0 flags=N db=0 sub=0 psub=0 multi=-1 qbuf=44 qbuf-free=32724 obl=0 oll=0 omem=0 events=r cmd=replicaof')
# 7447:S 11 Jul 2020 15:35:11.246 * Connecting to MASTER 127.0.0.1:6379
# 7447:S 11 Jul 2020 15:35:11.247 * MASTER <-> REPLICA sync started
# 7447:S 11 Jul 2020 15:35:11.247 * Non blocking connect for SYNC fired the event.
# 7447:S 11 Jul 2020 15:35:11.247 * Master replied to PING, replication can continue...
# 7447:S 11 Jul 2020 15:35:11.247 * Trying a partial resynchronization (request 8a87f600ddb2cace3efff018319c1964f0c38909:1).
# 7447:S 11 Jul 2020 15:35:11.460 * Full resync from master: 7a40d80043aa6c94a09ee0efbd1139515a2e39bf:0
# 7447:S 11 Jul 2020 15:35:11.460 * Discarding previously cached master state.
# 7447:S 11 Jul 2020 15:35:11.655 * MASTER <-> REPLICA sync: receiving 330 bytes from master
# 7447:S 11 Jul 2020 15:35:11.655 * MASTER <-> REPLICA sync: Flushing old data                      # 删除本地之前老的数据，好准备同步主节点数据
# 7447:S 11 Jul 2020 15:35:11.656 * MASTER <-> REPLICA sync: Loading DB in memory
# 7447:S 11 Jul 2020 15:35:11.656 * MASTER <-> REPLICA sync: Finished with success

# 6.对A节点增加数据
set k1 hello
# 然后在B节点获取数据
get k1 # 返回hello
set k2 hello # 默认从节点是不能进行写操作的。(error) READONLY You can't write against a read only replica.

# 此时让6379挂掉，从节点打印如下日志，但是数据不会丢失
# 7447:S 11 Jul 2020 15:56:19.049 # Connection with master lost.
# 7447:S 11 Jul 2020 15:56:19.049 * Caching the disconnected master state.
# 7447:S 11 Jul 2020 15:56:19.131 * Connecting to MASTER 127.0.0.1:6379
# 7447:S 11 Jul 2020 15:56:19.131 * MASTER <-> REPLICA sync started
# 7447:S 11 Jul 2020 15:56:19.131 # Error condition on socket for SYNC: Connection refused

# 7.在B节点运行，让6380不再追随其他节点，此时此节点可但对对外提供服务
replicaof no one
# 7447:M 11 Jul 2020 15:57:39.542 # Setting secondary replication ID to 7a40d80043aa6c94a09ee0efbd1139515a2e39bf, valid up to offset: 1838. New replication ID is a7579908c5a0445e4da0e53ee1b9a35f543d257e
# 7447:M 11 Jul 2020 15:57:39.542 * Discarding previously cached master state.
# 7447:M 11 Jul 2020 15:57:39.542 * MASTER MODE enabled (user request from 'id=3 addr=127.0.0.1:41764 fd=7 name= age=1404 idle=0 flags=N db=0 sub=0 psub=0 multi=-1 qbuf=36 qbuf-free=32732 obl=0 oll=0 omem=0 events=r cmd=replicaof')
set k2 hello
```
</details>

#### 高可用(基于Sentinel哨兵)

- 说明
    - 主挂了，自动选择出一个新的主节点，Sentinel模式主要针对高可用（HA）
    - 更推荐使用[Redis Cluster(参考下文)](#Redis%20Cluster)
- Sentinel实践

```bash
# 默认`redis-sentinel`程序在redis安装源码的src目录，安装到特定目录时只是将`redis-sentinel`程序链接到`redis-server`(即只能通过redis-server启动)

# 1.创建sentinel-26379.conf、sentinel-26380.conf、sentinel-26381.conf，写入以下配置(注意修改port)，哨兵启动后会动态修改此配置文件。详细配置文件在下载的redis源码目录的`sentinel.conf`文件中，主要如下
port 26379                                      # Sentinel监听的端口
sentinel monitor mymaster 127.0.0.1 6379 2      # 监控的redis集群的主节点配置(可监听多个集群，给此集群取名为mymaster)，2表示投票达到2票才算通过(此时一般使用3个Sentinel节点)。sentinel各节点无需手动关联，原因是各节点之间是通过PUB/SUB发布订阅进行探测的各哨兵节点，通道为__sentinel__:hello

# 2.如主备设置实践中启动3个服务端，并让其他节点追随6379

# 3.启动3个sentinel进程。基于redis-server启动sentinel(此redis-server并不对外提供redis服务)
redis-server ./sentinel-26379.conf --sentinel
# 启动后打印日志如下
# 7639:X 11 Jul 2020 16:26:56.733 # Sentinel ID is 6a0417e39932ff9648ad92fd6a2bebcc739cf17a
# 7639:X 11 Jul 2020 16:26:56.733 # +monitor master mymaster 127.0.0.1 6379 quorum 2
# 7639:X 11 Jul 2020 16:26:56.735 * +slave slave 127.0.0.1:6380 127.0.0.1 6380 @ mymaster 127.0.0.1 6379
# 7639:X 11 Jul 2020 16:26:56.736 * +slave slave 127.0.0.1:6381 127.0.0.1 6381 @ mymaster 127.0.0.1 6379
# 7639:X 11 Jul 2020 16:27:10.755 * +sentinel sentinel 83ea631a6cc216429ebce610f8c6f6ce60e4e718 127.0.0.1 26380 @ mymaster 127.0.0.1 6379
# 7639:X 11 Jul 2020 16:27:21.476 * +sentinel sentinel cc806355286a306e2f7298b5de9f8f3a020b68d7 127.0.0.1 26381 @ mymaster 127.0.0.1 6379

# 4.使6379退出，此时会自动从6380/6381中选取一个作为主节点，并让另外一个追随新的主节点
# 5.使用6379重新启动，此时会发现6379会自动追随刚选出来的新主节点
```

#### 分区/片

- 一般针对业务无法拆分的功能，受到单机容量限制，从而需要进行分区/片(每个节点存放的不是全量数据)
- 分区方式(以下3个模式均不能做数据库用)
    - 基于`modula`算法(hash取模)拆分
        - 缺点：取模的数必须固定，影响分布式下的扩展性(增加节点必须全量重新hash计算)
    - 基于`random`算法拆分(随机放到不同的节点)
        - 缺点：客户端不能精确知道数据具体存放的节点
        - 应用场景：消息队列
            - 客户端通过lpush存放到某个key的集合中，另外一个客户端只需要通过rpop任意取出一个进行消费即可
            - 类似kafka，此时key可理解为topic，redis节点可认为是partition
    - 基于`ketama`算法(一致性hash算法)拆分
        - **一致性hash算法** [^5]
            - 是对2^32方取模，即一致性Hash算法将整个Hash空间组织成一个虚拟的圆环，Hash函数的值空间为0 ~ 2^32 - 1(一个32位无符号整型)
            - 规划一个虚拟哈希环，不同的节点通过hash算法落到此环的某个点，数据通过key进行hash得到该环的位置，并将数据存放在最近的节点上
        - 优点：新增节点可以分担其他节点的压力，不会造成全局洗牌
        - 缺点：新增节点造成一小部分数据不能命中(如增加node3，key为xxx对应数据原本在node1，此时客户端会到最近的node3上去找)
            - 问题：击穿，压到mysql
            - 方案：去取最近的2个物理节点获取数据(只能减少一部分问题)
        - 数据倾斜问题：节点太少可能在某一节点的数据太多，可创建多个虚拟节点
    - 图解

        ![redis-sharding](/data/images/db/redis-sharding.png)
    - 缺点
        - 以上3个模式均不能做数据库用，主要是新增节点时会出现一段时间的数据丢失
        - 解决方案：[预分区、Redis Cluster](#Redis%20Cluster)
- 数据分治(分区)产生问题
    - 聚合操作很难实现(不同的key分布在不同的节点)，因此涉及多个key的操作通常不会被支持
    - 事务很难实现
    - 分区时动态扩容或缩容可能非常复杂
- hash tag
    - 命令可以为`{tag1}key1`、`{tag1}key2`，从而可将相同的tag放到同一个节点，实现一定程度的支持事物等功能

#### 代理

- 更推荐使用[Redis Cluster(参考下文)](#Redis%20Cluster)。直连某个redis，会自动进行跳转，无需代理
- 如果客户端直接连接redis各节点会产生较高的连接成本，因此可使用代理(类似nginx)，客户端只连接代理

    ![redis-proxy](/data/images/db/redis-proxy.png)
- 常见redis代理组件
    - [twemproxy](https://github.com/twitter/twemproxy)
        - twitter开源
        - 仅支持分区模式
        - 不支持事物等命令
        - 不支持hash tag（形如`{xx}key`）
    - [predixy](https://github.com/joyieldInc/predixy)
        - 性能较高
        - 支持分区、主备模式
        - 支持监控一套主备的哨兵模式（仅支持主备，分区则不支持），此情况才支持事物等命令（分区后不支持事物）
        - 支持hash tag（分区+主备也支持）
    - codis
    - redis-cerberus
- redis代理组件对比：https://blog.csdn.net/rebaic/article/details/76384028

    ![redis-proxy-vs](/data/images/db/redis-proxy-vs.png)

##### twemproxy测试

```bash
## 安装
yum install -y git automake libtool
git clone https://github.com/twitter/twemproxy.git
cd twemproxy
autoreconf -fvi
./configure
make # 编译，会在src目录生成nutcracker的可执行文件
src/nutcracker -h # 查看帮助

## 上述nutcracker可直接使用，下面将它设置成服务
cp scripts/nutcracker.init /etc/init.d/twemproxy
chmod +x /etc/init.d/twemproxy
chkconfig --add twemproxy # 设置twemproxy为服务
systemctl status twemproxy
mkdir /etc/nutcracker # 复制nutcracker.yml等配置文件到scripts/nutcracker.init脚本中指定的位置
cp conf/* /etc/nutcracker
cp src/nutcracker /usr/bin/ # 复制可执行程序到scripts/nutcracker.init脚本中指定的位置

## 测试
vi /etc/nutcracker/nutcracker.yml # 参考下文进行代理配置
# 参考上文[主备设置实践](#主备设置实践(replicaof))启动两个redis节点。然后启动twemproxy并连接
systemctl start twemproxy
redis-cli -p 22121
# 1.普通设值
set k1 hello # 存放在6379
set k1 hi # 存放在6379
set 1 1 # 存放在6380
get k1 # hello
# redis-cli -p 6379 # 单独连接各节点，发现3个key分布在不同节点(如果在同一节点可设置不同的key试试)
# 2.在代理客户端上执行，keys *、watch k1、mulit等命令不能执行(由于进行了分片，key可能落在多个节点)
keys * # Error: Server closed the connection
# 3.断开6380节点，发现6379的数据可正常get，但是挂掉的6380数据无法正常访问
get 1 # (error) ERR Connection refused
set 1 2 # OK。6380挂掉后，重新设置此key会保存到6379
# 4.不支持形如`{xx}key`的hash tag
```
- /etc/nutcracker/nutcracker.yml测试配置

```yml
# 代理名称
alpha:
  listen: 127.0.0.1:22121       # 代理监听的地址，之后客户端连接此地址访问redis即可
  hash: fnv1a_64                # hash算法 
  distribution: ketama          # 分片方式(每个节点存放的不是全量数据)
  auto_eject_hosts: true
  redis: true
  server_retry_timeout: 2000
  server_failure_limit: 1
  servers:
   - 127.0.0.1:6379:1           # 节点配置，最后的1表示权重(不同节点存放数据量的多少)
   - 127.0.0.1:6380:1
# 可配置多个代理
```

##### predixy测试

```bash
# https://github.com/joyieldInc/predixy/blob/master/README_CN.md
## 安装
wget https://github.com/joyieldInc/predixy/releases/download/1.0.5/predixy-1.0.5-bin-amd64-linux.tar.gz
tar -zxvf predixy-1.0.5-bin-amd64-linux.tar.gz
cd predixy-1.0.5
# bin/predixy conf/predixy.conf # 启动

## 测试
# 修改主配置：打开监听端口`Bind 127.0.0.1:7617`；使用哨兵模式，导入配置`Include sentinel.conf`(去掉此行注释，并注释掉`Include try.conf`)
vi conf/predixy.conf
vi conf/sentinel.conf # 修改predixy中的哨兵配置，如下文

# 启动哨兵。配置如下文(同样启动26380/26381)，并监听两套主从节点
vi ~/sentinel-26379.conf
redis-server ./sentinel-26379.conf --sentinel

# 启动redis主备。参考上文[主备设置实践](#主备设置实践(replicaof))启动两套redis主从(36379、36380和46379、46380)
redis-server ./36379.conf
redis-server ./36380.conf --slaveof 127.0.0.1 36379

# 启动并连接
bin/predixy conf/predixy.conf
redis-cli -p 7617

# 1.普通设值
set k1 1 # 存放在36379主从中
set k2 2 # 存放在46379主从中
# 2.hash tag设值。以{order}开头的全部存放在同一节点
set {order}k1 1
set {order}k2 2
# 3.当前版本只支持Sentinel搭配一个Group的主从时才支持事物等功能，此处conf/sentinel.conf有两个Group(xxx、yyy)因此无法支持以下命令
multi # (error) ERR forbid transaction in current server pool
keys * # (error) ERR unknown command 'keys'
# 4.挂掉某一套的从节点，系统仍然可用
# 5.挂掉某一套的主节点，系统刚开始不可用，等到哨兵重新设置主节点后恢复可用
set k3 3 # (error) ERR server connection close => (error) ERR no server connection avaliable => OK
# 6.挂掉了一套主从节点(整个一套全部挂掉)，此时如果某hash tag存放在此节点，则同样的hash tag将无法继续创建
set {order}k3 3 # (error) ERR server connection close
# 7.配置conf/sentinel.conf中只保留一个Group(实际Sentinel仍然监控了两套主从)，则可支持事物
keys * # (error) ERR unknown command 'keys'
multi # OK
keys * # QUEUED
exec # 通过事物执行keys *可成功
watch k1 # OK
```
- 测试配置

```bash
## conf/sentinel.conf
SentinelServerPool {
    Databases 16
    Hash crc16
    HashTag "{}"
    Distribution modula
    MasterReadPriority 60
    StaticSlaveReadPriority 50
    DynamicSlaveReadPriority 50
    RefreshInterval 1
    ServerTimeout 1
    ServerFailureLimit 10
    ServerRetryTimeout 1
    KeepAlive 120
    # 配置3个哨兵节点
    Sentinels {
        + 127.0.0.1:26379
        + 127.0.0.1:26380
        + 127.0.0.1:26381
    }
    # 哨兵配置文件中定义监控组名称(xxx为一套主从，yyy为一套主从)。如果需要支持事物，此处只能配置一个Group
    Group xxx {
    }
    Group yyy {
    }
}

## sentinel-26379.conf(监控两套主从)，同理创建26380、26381
port 26379
sentinel monitor xxx 127.0.0.1 36379 2
sentinel monitor yyy 127.0.0.1 46379 2
```

### 击穿/穿透/雪崩

- 击穿、穿透、雪崩
    - 击穿
        - 某个(热点)key突然失效，造成大量请求同时访问数据库
        - 解决方案：setnx加锁取数据到redis，并设置加锁超时时间(防止死锁)
    - 穿透
        - 访问了大量不存在的(redis中没有)数据
        - 解决方案：使用布隆过滤器、布谷鸟过滤器
    - 雪崩
        - 大量key同时失效，造成同时大量访问数据库
        - 解决方案：缓存预热、随机过期时间、二级缓存、加锁或队列

    ![redis-击穿-穿透-雪崩](/data/images/db/redis-击穿-穿透-雪崩.png)

- 击穿解决方案：setnx加锁，伪代码如下

```java
public String get(key) {
    String value = redis.get(key);
    if (value == null) { // 代表缓存值过期
        // 加锁，并设置3min的超时，防止del操作失败的时候，下次缓存过期一直不能load db
        if (redis.setnx(key_mutex, 1, 3 * 60) == 1) { // 代表设置成功
            value = db.get(key); // 如果这一步很耗时，可以考虑多线程(一个线程取DB，一个线程监控数据是否取回来并更新锁)
            redis.set(key, value, expire_secs);
            redis.del(key_mutex);
        } else { // 这个时候代表有其他线程获取到锁，已经或正在load db并回设到缓存，这时候重试获取缓存值即可
            sleep(50);
            value = get(key); // 重试（递归调用，如果值为空还是会尝试获取锁）
        }
    }
    return value;
}
```
- 穿透解决方案：布隆过滤器、布谷鸟过滤器
- 雪崩解决方案：随机过期时间、二级缓存、加锁或队列（针对时点性高的场景）

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
## 安装
wget https://github.com/RedisBloom/RedisBloom/archive/v2.2.3.zip
yum install unzip
unzip v2.2.3.zip
cd RedisBloom-2.2.3/
make # 编译，会生成bloom.so库
cp redisbloom.so /opt/soft/redis5/

## 操作(该模块提供了bf.*、cf.*等命令)
# 启动时载入布隆模块，也可在配置文件的MODULES部分进行配置
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

### 双写一致性问题

- 当更新数据时，数据库和缓存的更新如何保证数据一致
- 从理论上来说，给缓存设置过期时间，是保证最终一致性的解决方案
- 如果不考虑设置过期时间，存在一下几种方式 [^6]
    - 先更新缓存，再更新数据库：不推荐，明显很容易出现数据不一致的问题
    - 先更新数据库，再更新缓存：不推荐，A/B线程先后更新了数据库，B/A先后更新了缓存，导致最终数据不一致
    - 先删除缓存，再更新数据库：不推荐，如删除缓存后，在数据库更新完成前，另外一个线程重新读取数据把旧数据写入到缓存
        - 可采用延时双删策略，即先删缓存 - 更新数据库 - 延迟一定时间(确保数据读取完成/分库分别同步完成)再删除缓存
        - 由于需要延迟会导致吞吐量下降，可使用异步显示进行删除（但是会存在第二次删除失败的情况）
    - **先更新数据库，再删除缓存**
        - 可能出现数据不一致的概率较小(缓存失效线程A查询到一个旧值，线程B更新了数据库并完成了缓存删除，线程A把读取的旧值写入到缓存。出现概率小的原因是读一般是比写快，上述情况是在完成一个写的情况下，读还没完成导致)
        - 也可进行解决：进行异步延迟删除，如果更新失败则通过消息队列重试更新。（为了减少对业务代码的入侵，可更新数据库后，订阅binlog日志，进行缓存更新，再结合消息队列处理失败的更新）

## Java使用

### SpringBoot使用Redis

- 引入依赖

    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    ```
- 配置

    ```yml
    # Redis缓存配置
    spring:
      redis:
       host: 127.0.0.1
       port: 6379
       database: 0
       password:
    ```
- 使用

    ```java
    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    // 存储String
    redisTemplate.opsForValue().set("myRedisKey", "hello world");
    redisTemplate.opsForValue().get("myRedisKey");

    // 存储Map
    redisTemplate.opsForHash().put("myRedisKey", "myMapKey", "hello world");
    redisTemplate.opsForHash().get("myRedisKey", "myMapKey");
    ```

### Jedis使用

- Jedis为java中操作redis的客户端
- 引入jar包(参考上文pom)
    - 使用Java操作Redis需要jedis-3.0.1.jar
    - 如果需要使用Redis连接池的话，还需commons-pool2-2.6.2.jar
- 简单使用

```java
// 获取连接，如果使用空参构造，默认值 localhost:6379 端口
redis.clients.jedis.Jedis jedis = new redis.clients.jedis.Jedis();
// 字符串
jedis.set("name", "zhangsan");
String name = jedis.get("name"); // zhangsan
// hash类型：map格式
jedis.hset("user", "name", "zhangsan");
jedis.hset("user", "id", "13");
jedis.hget("user", "name"); // zhangsan
Map<String, String> user = jedis.hgetAll("user"); // 获取全部数据
// 列表类型：list格式
jedis.lpush("list", "a"); // 左边添加数据
jedis.rpush("list", "b"); // 右边添加数据
String list = jedis.rpop("list"); // 移除最右边的数据并返回值
// 集合类型：set格式
jedis.sadd("set", "a");
jedis.sadd("set", "b");
Set<String> set = jedis.smembers("set");
// 关闭连接
jedis.close();
```
- 使用连接池连接redis集群(jedis v3)

```java
// 参考: https://blog.51cto.com/u_14402/9184932
public class JedisClusterUtil {

    private static JedisCluster jedis = null;

    //可用连接实例的最大数目，默认为8；特别多的并发的情况也可以设置的高，如500或更高 (服务器集群默认最大允许10000个连接)
    //如果赋值为-1，则表示不限制，如果pool已经分配了maxActive个jedis实例，则此时pool的状态为exhausted(耗尽)
    private static Integer MAX_TOTAL = 10;
    //控制一个pool最多有多少个状态为idle(空闲)的jedis实例，默认值是8；其他如20
    private static Integer MAX_IDLE = 5;
    //等待可用连接的最大时间，单位是毫秒，默认值为-1，表示永不超时。
    //如果超过等待时间，则直接抛出JedisConnectionException
    private static Integer MAX_WAIT_MILLIS = 10000;
    //在borrow(用)一个jedis实例时，是否提前进行validate(验证)操作；
    //如果为true，则得到的jedis实例均是可用的
    private static Boolean TEST_ON_BORROW = true;
    //在空闲时检查有效性, 默认false
    private static Boolean TEST_WHILE_IDLE = true;
    //是否进行有效性检查
    private static Boolean TEST_ON_RETURN = true;

    //访问密码
    private static String AUTH = "1234@abcd";

    /**
     * 静态块，初始化Redis连接池
     */
    static {
        try {
            JedisPoolConfig config = new JedisPoolConfig();
            /*注意：
                在高版本的jedis jar包，比如本版本2.9.0，JedisPoolConfig没有setMaxActive和setMaxWait属性了
                这是因为高版本中官方废弃了此方法，用以下两个属性替换。
                maxActive  ==>  maxTotal
                maxWait ==>  maxWaitMillis
            */
            config.setMaxTotal(MAX_TOTAL);
            config.setMaxIdle(MAX_IDLE);
            config.setMaxWaitMillis(MAX_WAIT_MILLIS);
            config.setTestOnBorrow(TEST_ON_BORROW);
            config.setTestWhileIdle(TEST_WHILE_IDLE);
            config.setTestOnReturn(TEST_ON_RETURN);

            Set<HostAndPort> jedisClusterNode = new HashSet<HostAndPort>();
            jedisClusterNode.add(new HostAndPort("192.168.0.31", 6380));
            jedisClusterNode.add(new HostAndPort("192.168.0.32", 6380));
            jedisClusterNode.add(new HostAndPort("192.168.0.33", 6380));
            jedisClusterNode.add(new HostAndPort("192.168.0.34", 6380));
            jedisClusterNode.add(new HostAndPort("192.168.0.35", 6380));
            jedisClusterNode.add(new HostAndPort("192.168.0.36", 6380));

            jedis = new JedisCluster(jedisClusterNode,2000,2000,5,AUTH,config);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }


    public static JedisCluster getJedis() {
        return jedis;
    }
}
```

- 使用连接池连接redis单机(jedis v3)

```java
public class JedisUtil {
    private static JedisPool jedisPool;

    static {
        // 读取配置文件
        InputStream resourceAsStream = JedisUtil.class.getClassLoader().getResourceAsStream("jedis.properties");
        Properties properties = new Properties();
        try {
            properties.load(resourceAsStream);
        } catch (IOException e) {
            e.printStackTrace();
        }
        // 创建配置文件对象
        JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
        // 控制一个pool可分配多少个jedis实例，通过pool.getResource()来获取；低版本使用(如v2.9.0之前) setMaxActive
        // 如果赋值为-1，则表示不限制；如果pool已经分配了maxActive个jedis实例，则此时pool的状态为exhausted(耗尽)。  
        jedisPoolConfig.setMaxTotal(Integer.parseInt(properties.getProperty("maxTotal"))); // 500
        // 控制一个pool最多有多少个状态为idle(空闲的)的jedis实例
        jedisPoolConfig.setMaxIdle(Integer.parseInt("maxIdle")); // 默认 8
        // 表示当borrow(引入)一个jedis实例时，最大的等待时间，如果超过等待时间，则直接抛出JedisConnectionException
        // config.setMaxWait(1000 * 100);  
        // 在borrow一个jedis实例时，是否提前进行validate操作；如果为true，则得到的jedis实例均是可用的
        // config.setTestOnBorrow(true);
        // 初始化jedispool, localhost:6379
        jedisPool = new JedisPool(jedisPoolConfig, properties.getProperty("host"), Integer.parseInt(properties.getProperty("port")));

    }

    //获取连接
    public static JedisPool getJedisPool() {
        return jedisPool;
    }

    /**
     * 返还到连接池
     * @param pool  
     * @param redis
     */  
    public static void returnResource(Jedis redis) {
        if (redis != null) {
            jedisPool.returnResource(redis);
        }  
    }

    /**
     * 获取字符串数据示例
     */  
    public static void main(String[] args) {
        JedisPool jedisPool = null;
        Jedis jedis = null;
        try {
            jedisPool = JedisUtil.getJedisPool();
            jedis = jedisPool.getResource();

            String value = jedis.get("name");
            System.out.println(value);
        } catch (Exception e) {
            // 释放redis对象
            jedisPool.returnBrokenResource(jedis);
            e.printStackTrace();
        } finally {
            // 返还到连接池
            JedisUtil.returnResource(pool, jedis);
        }
    }
}
```

### 解决session一致性(session共享)

- 参考[nginx.md#反向代理和负载均衡](/_posts/arch/nginx.md#反向代理和负载均衡)

### 实现分布式锁

- 分布式场景方案：https://blog.csdn.net/asd051377305/article/details/108384490
- 示例 [^4]

```java
public class RedisTool {
    private static final String LOCK_SUCCESS = "OK";
    private static final String SET_IF_NOT_EXIST = "NX";
    private static final String SET_WITH_EXPIRE_TIME = "PX";
    private static final Long RELEASE_SUCCESS = 1L;

    /**
     * 尝试获取分布式锁
     * @param jedis Redis客户端
     * @param lockKey 锁
     * @param requestId 请求标识
     * @param expireTime 超期时间
     * @return 是否获取成功
     */
    public static boolean tryGetDistributedLock(Jedis jedis, String lockKey, String requestId, int expireTime) {
        String result = jedis.set(lockKey, requestId, SET_IF_NOT_EXIST, SET_WITH_EXPIRE_TIME, expireTime);
        if (LOCK_SUCCESS.equals(result)) {
            return true;
        }
        return false;
    }

    /**
     * 释放分布式锁
     * @param jedis Redis客户端
     * @param lockKey 锁
     * @param requestId 请求标识
     * @return 是否释放成功
     */
    public static boolean releaseDistributedLock(Jedis jedis, String lockKey, String requestId) {
        // Lua脚本，从而确保解锁操作是原子性的
        String script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
        // 将Lua代码传到jedis.eval()方法里，并使参数KEYS[1]赋值为lockKey，ARGV[1]赋值为requestId。eval()方法是将Lua代码交给Redis服务端执行
        Object result = jedis.eval(script, Collections.singletonList(lockKey), Collections.singletonList(requestId));
        if (RELEASE_SUCCESS.equals(result)) {
            return true;
        }
        return false;
    }
}
```
- `jedis.set(String key, String value, String nxxx, String expx, int time)` 对应如 **`set my_lock id_12345678 nx ex 60`**
    - 使用key来当锁，因为key是唯一的
    - value传的是requestId，就可知道这把锁是哪个请求加的了，在解锁的时候就可以有依据。**解铃还须系铃人**。requestId可以使用UUID.randomUUID().toString()方法生成
    - NX，意思是SET IF NOT EXIST，即当key不存在时，进行set操作；若key已经存在，则不做任何操作。**互斥性**
    - PX，意思是要给这个key加一个过期的设置，具体时间由第五个参数决定。**防止死锁**
    - time，与第四个参数相呼应，代表key的过期时间
    - **此时只考虑Redis单机部署的场景，所以没有考虑容错性**，可使用[Redisson](https://github.com/redisson/redisson/wiki/8.-Distributed-locks-and-synchronizers)
- 分布式锁错误使用
    - 错误方式：jedis.setnx()和jedis.expire()组合使用
        - 由于这是两条Redis命令，不具有原子性，如果程序在执行完setnx()之后突然崩溃，导致锁没有设置过期时间，那么将会发生死锁
        - 网上之所以有人这样实现，是因为低版本的jedis并不支持多参数的set()方法
    - 错误方式：jedis.del()方法删除锁
        - 这种不先判断锁的拥有者而直接解锁的方式，会导致任何客户端都可以随时进行解锁，即使这把锁不是它的


### redis对模糊查询的缺陷及解决方案

> redis本身适合作为缓存工具，不建议使用模糊查询等操作

- 使用[https://code.google.com/archive/p/redis-search4j/](redis-search4j) ，使用了分词，解决了中文的模糊查询。（效果不好，测试发现会在服务器中存储大量无用的key）

## 高级

### Redis通信协议规范

- Redis通信协议
  - Redis客户端使用RESP协议（Redis的序列化协议）与Redis的服务器端进行通信
  - 客户端连接到Redis的服务器，创建到端口6379的TCP连接
  - 请求-响应模型
- RESP协议描述（RESP protocol description）
  - 支持以下数据类型的序列化协议：简单字符串（Simple Strings，响应的第一个字节为`+`），整数（Integers，`:`），数组（Arrays，`*`），块字符串/批量字符串（Bulk Strings，`$`）和错误（Errors，`-`）
  - 请求-响应流程
    - 客户端将命令作为批量字符串的RESP数组发送到Redis服务器
    - 服务器（Server）根据命令执行的情况返回一个具体的RESP类型作为回复，有些的数据类型取决于响应的第一个字节（参考上文）


---

参考文章

[^1]: http://www.runoob.com/redis/redis-tutorial.html (菜鸟教程)
[^2]: http://wiki.jikexueyuan.com/project/redis-guide/ (极客学院 Wiki)
[^3]: http://www.cnblogs.com/edisonfeng/p/3571870.html (java对redis的基本操作)
[^4]: https://www.cnblogs.com/moxiaotao/p/10829799.html
[^5]: https://www.jianshu.com/p/528ce5cd7e8f
[^6]: https://www.cnblogs.com/wangwust/p/9467586.html

