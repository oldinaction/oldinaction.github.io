---
layout: "post"
title: "SQL优化"
date: "2018-07-27 14:58"
categories: [db]
tags: [oracle, dba, sql]
---

## 总结

- 比如统计用户的点击情况，根据用户年龄分两种情况，年龄小于 10 岁或大于 50 岁的一次点击算作 2，其他年龄段的一次点击算作 1(实际情况可能更复杂)。如果在 where 条件中使用 or 可能会导致查询很慢，此时可以考虑查询出所有用户、年龄类别、点击次数，再在外层套一层查询通过 case when 进行合计

## Mysql 调优

- 参考：https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/Mysql%E8%B0%83%E4%BC%98.xmind
- mysql 架构：客户端 -> 服务端(连接器 - 分析器 - 优化器 - 执行器) -> 存储引擎
- mysql 测试表结构和数据：https://dev.mysql.com/doc/index-other.html (Example Databases)
    - [employee data](https://github.com/datacharmer/test_db)
    - [world database](https://downloads.mysql.com/docs/world.sql.zip)
    - [world_x database](https://downloads.mysql.com/docs/world_x-db.zip)
    - [sakila database](https://downloads.mysql.com/docs/sakila-db.zip)
        - [sakila 数据库说明](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/sakila%E6%95%B0%E6%8D%AE%E5%BA%93%E8%AF%B4%E6%98%8E.md)
    - [menagerie database](https://downloads.mysql.com/docs/menagerie-db.zip)

### 性能监控

- 使用 `show profile` 命令(**之后 mysql 版本可能会被移除**)
    - 使用
        - 此工具默认是禁用的，可以通过服务器变量在会话级别动态的修改 `set profiling=1;`
        - 当设置完成之后，在服务器上执行的所有语句，都会测量其耗费的时间和其他一些查询执行状态变更相关的数据。select \* from emp;
        - 在 mysql 的命令行模式下只能显示两位小数的时间，可以使用如下命令查看具体的执行时间 `show profiles;`
        - 执行如下命令可以查看详细的每个步骤的时间 `show profile for query 2;`
    - type
        - all：显示所有性能信息。show profile all for query n
        - block io：显示块 io 操作的次数。show profile block io for query n
        - context switches：显示上下文切换次数，被动和主动。show profile context switches for query n
        - cpu：显示用户 cpu 时间、系统 cpu 时间。show profile cpu for query n
        - IPC：显示发送和接受的消息数量。show profile ipc for query n
        - Memory：暂未实现
        - page faults：显示页错误数量。show profile page faults for query n
        - source：显示源码中的函数名称与位置。show profile source for query n
        - swaps：显示 swap 的次数。show profile swaps for query n
- 更多的是使用`performance schema`来监控 mysql。服务器默认是开启状态(关闭可在 my.ini 中设置)，开启后会有一个 performance_schema 数据库(表中数据记录在内存，服务关闭则数据销毁)

    - 数据库 CPU 飙高问题参考：[http://blog.aezo.cn/2018/03/13/java/Java%E5%BA%94%E7%94%A8CPU%E5%92%8C%E5%86%85%E5%AD%98%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90/](/_posts/devops/Java应用CPU和内存异常分析.md#Mysql)
    - [MYSQL performance schema 详解](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/MYSQL%20performance%20schema%E8%AF%A6%E8%A7%A3.md)

        ```sql
        --语句事件记录表，这些表记录了语句事件信息
        --当前语句事件表events_statements_current(_current表中每个线程只保留一条记录，一旦线程完成工作，该表中不会再记录该线程的事件信息)
        --历史语句事件表events_statements_history(_history表中记录每个线程应该执行完成的事件信息，但每个线程的事件信息只会记录10条，且总记录数量是10000，超过就会被覆盖掉)
        --长语句历史事件表events_statements_history_long
        --以及聚合后的摘要表summary，其中，summary表还可以根据帐号(account)，主机(host)，程序(program)，线程(thread)，用户(user)和全局(global)再进行细分
        show tables like '%statement%';

        --等待事件记录表，与语句事件类型的相关记录表类似
        show tables like '%wait%';

        --阶段事件记录表，记录语句执行的阶段事件的表
        show tables like '%stage%';

        --事务事件记录表，记录事务相关的事件的表
        show tables like '%transaction%';

        --监控文件系统层调用的表
        show tables like '%file%';

        --监视内存使用的表
        show tables like '%memory%';

        --动态对performance_schema进行配置的配置表。​ instruments: 生产者，用于采集mysql中各种各样的操作产生的事件信息；​consumers：消费者，对应的消费者表用于存储来自instruments采集的数据
        show tables like '%setup%';

        -- instance表记录了哪些类型的对象会被检测。这些对象在被server使用时，在该表中将会产生一条事件记录
        select * from file_instances limit 20;  -- 例如，file_instances表列出了文件I/O操作及其关联文件名
        ```

- 使用`show processlist`查看连接的线程个数，来观察是否有大量线程处于不正常的状态或者其他不正常的特征
    - command 表示当前状态
        - sleep：线程正在等待客户端发送新的请求
        - query：线程正在执行查询或正在将结果发送给客户端
        - locked：在 mysql 的服务层，该线程正在等待表锁
        - analyzing and statistics：线程正在收集存储引擎的统计信息，并生成查询的执行计划
        - Copying to tmp table：线程正在执行查询，并且将其结果集都复制到一个临时表中
        - sorting result：线程正在对结果集进行排序
        - sending data：线程可能在多个状态之间传送数据，或者在生成结果集或者向客户端返回数据
    - state 表示命令执行状态

### 执行计划(explain)

- [参考：mysql 执行计划](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/mysql%E6%89%A7%E8%A1%8C%E8%AE%A1%E5%88%92.md)
- `explain`查看执行计划。如`explain select * from t_test;`
- explain 返回字段：id、select_type、table、type、possible_keys、key、key_len、ref、rows、Extra，含义如下 [^5]
    - id：**id 越大的语句越先执行，相同的则从上向下依次执行**
    - select_type 有下列常见几种
        - SIMPLE：最简单的 SELECT 查询，没有使用 UNION 或子查询
        - PRIMARY：在嵌套的查询中是最外层的 SELECT 语句，在 UNION 查询中是最前面的 SELECT 语句
        - DERIVED：派生表 SELECT 查询，如 FROM 子句中的子查询。如：`select name fromm user u, (select id from user_class where id=1) t where t.id = u.class_id`
        - SUBQUERY：子查询中第一个 SELECT 语句
        - DEPENDENT SUBQUERY：子查询中的第一个 SELECT，取决于外面的查询（外面查询的记录会逐一带入到子查询中进行查询）。**此类型出现建议优化**
        - UNION：UNION 中第二个以及后面的 SELECT 语句
        - UNION RESULT：一个 UNION 查询的结果
        - DEPENDENT UNION：首先需要满足 UNION 的条件，及 UNION 中第二个以及后面的 SELECT 语句，**同时该语句依赖外部的查询**
    - table：显示的这一行信息是关于哪一张表的，有时候并不是真正的表名，如`<subqueryN>`为 id=N 的子查询，`<derivedN>`N 就是 id 值、`<unionM,N>`这种类型，出现在 UNION 语句中
    - **type**：type 列很重要，是用来说明表与表之间是如何进行关联操作的，有没有使用索引。主要有下面几种类别(查询速度依次递减)
        - system：这是 const 连接类型的一种特例，表仅有一行满足条件，最理想的
        - const：当确定最多只会有一行匹配的时候，MySQL 优化器会在查询前读取它而且只读取一次，因此非常快。const 只会用在将常量和主键或唯一索引进行比较时，而且是比较所有的索引字段 **(BILL_NO = 1)**
        - eq_ref：eq_ref 类型是除了 const 外最好的连接类型，它用在一个索引的所有部分被联接使用并且索引是 UNIQUE 或 PRIMARY KEY。需要注意 InnoDB 和 MyISAM 引擎在这一点上有点差别。InnoDB 当数据量比较小的情况 type 会是 All
        - ref：这个类型跟 eq_ref 不同的是，**它用在关联操作只使用了索引的最左前缀**，或者索引不是 UNIQUE 和 PRIMARY KEY。ref 可以用于使用=或<=>操作符的带索引的列
        - fulltext：联接是使用全文索引进行的，一般我们用到的索引都是 B+树
        - ref_or_null：该类型和 ref 类似。但是 MySQL 会做一个额外的搜索包含 NULL 列的操作。在解决子查询中经常使用该联接类型的优化
        - index_merger：该联接类型表示使用了`索引合并`优化方法。在这种情况下，key 列包含了使用的索引的清单，key_len 包含了使用的索引的最长的关键元素
        - unique_subquery：该类型替换了下面形式的 IN 子查询的 ref，是一个索引查找函数，可以完全替换子查询，效率更高
        - index_subquery：该联接类型类似于 unique_subquery
        - range：只检索给定范围的行，使用一个索引来选择行。key 列显示使用了哪个索引。key_len 包含所使用索引的最长关键元素。当使用`=、<>、>、>=、<、<=、IS NULL、<=>、BETWEEN、IN` 操作符，用常量比较关键字列时，可以使用 range **(BILL_NO < 10)**
            - 有时候通过主键id=1得到的是range(ref=const,Extra=Using where)，有时候是const
        - index：该联接类型与 ALL 相同，除了只有索引树被扫描。这通常比 ALL 快，因为索引文件通常比数据文件小。这个类型通常的作用是告诉我们查询是否使用索引进行排序操作 **(order by BILL_NO)**
        - ALL：最慢的一种方式，即全表扫描
    - possible_keys：指出 MySQL 能使用哪个索引在该表中找到行
    - **key**：显示 MySQL 实际决定使用的键（索引）。如果没有选择索引，键是 NULL。要想强制 MySQL 使用或忽视 possible_keys 列中的索引，在查询中使用 force index、use index 或者 ignore index. 如下

        ```sql
        -- 指定索引/强制索引。如果优化器认为全表扫描更快，会使用全表扫描，而非指定的索引; 使用Hint提示
        select * from user use index(idx_name_sex) where id > 10000;
        -- 强制指定索引。即使优化器认为全表扫描更快，也不会使用全表扫描，而是用指定的索引
        select *
        from t_user u force index(idx_create_time)
        join t_class c on c.id = u.cid
        where u.create_time > '2000-01-01';
        ```
    - key_len：显示 MySQL 决定使用的键长度。如果键是 NULL，则长度为 NULL。使用的索引的长度，在不损失精确性的情况下，长度越短越好
    - ref：显示使用哪个列或常数与 key 一起从表中选择行
    - rows：显示 MySQL 认为它执行查询时必须检查的行数。注意这是一个预估值
    - filtered：表示存储引擎返回的数据在 server 层过滤后，剩下多少满足查询的记录数量的比例，注意是百分比，不是具体记录数
    - **Extra**：显示 MySQL 在查询过程中的一些详细信息
        - Using filesort：MySQL 有两种方式可以生成有序的结果，通过排序操作或者使用索引，当 Extra 中出现了 Using filesort 说明 MySQL 使用了后者，但注意虽然叫 filesort 但并不是说明就是用了文件来进行排序，只要可能排序都是在内存里完成的。大部分情况下利用索引排序更快，**所以一般这时也要考虑优化查询了**
        - Using temporary：说明使用了临时表，一般看到它说明查询需要优化了，就算避免不了临时表的使用也要尽量避免硬盘临时表的使用。
        - Not exists：MYSQL 优化了 LEFT JOIN，一旦它找到了匹配 LEFT JOIN 标准的行，就不再搜索了。
        - Using index：说明查询是覆盖索引，并且 where 筛选条件是索引的是前导列
        - Using index condition：这是 MySQL 5.6 出来的新特性，叫做"索引条件推送"。简单说一点就是 MySQL 原来在索引上是不能执行如 like 这样的操作的，但是现在可以了，这样减少了不必要的 IO 操作，但是只能用在二级索引上。如：查询列不完全被索引覆盖，但 where 条件中是一个前导列的范围或查询条件完全可以使用到索引(包括所有范围查找)
        - Using where：使用了 WHERE 从句来限制哪些行将与下一张表匹配或者是返回给用户

### schema 与数据类型优化

> https://dev.mysql.com/doc/refman/5.7/en/optimizing-database-structure.html

#### schema 优化

- [数据类型的优化](#数据类型的优化)
- 合理使用范式和反范式
    - 在企业中很少能做到严格意义上的范式或者反范式，一般需要混合使用
        - 在一个网站实例中，这个网站，允许用户发送消息，并且一些用户是付费用户。现在想查看付费用户最近的 10 条信息。在 user 表和 message 表中都存储用户类型(account_type)而不用完全的反范式化。这避免了完全反范式化的插入和删除问题，因为即使没有消息的时候也绝不会丢失用户的信息。这样也不会把 user_message 表搞得太大，有利于高效地获取数据
        - 另一个从父表冗余一些数据到子表的理由是排序的需要
        - 缓存衍生值也是有用的。如果需要显示每个用户发了多少消息（类似论坛的），可以每次执行一个昂贵的自查询来计算并显示它；也可以在 user 表中建一个 num_messages 列，每当用户发新消息时更新这个值
    - 数据库中的表要合理规划，控制单表数据量，对于 MySQL 数据库来说，建议单表记录数控制在 2000W 以内。
    - MySQL 实例下，数据库、表数量尽可能少;数据库一般不超过 50 个，每个数据库下，数据表数量一般不超过 500 个(包括分区表)
- 主键的选择
    - 包含代理主键、自然主键(如身份证号)。一般选择代理主键，它不与业务耦合，可很好的配合主键生成策略使用
- 字符集的选择
    - 纯拉丁字符能表示的内容，可使用默认的 latin1
    - 多语言才会用到 utf8(mysql 的 utf8 编码最大只能存放 3 个字节)、utf8mb4(mb4 指 most bytes 4，因此最大可以存放 4 个字节)。中文有可能占用 2、3、4 个字节，mysql 的 utf8 编码可以存放大部分中文，而少数中文需要用到 utf8mb4
    - MySQL 的字符集可以精确到字段，可以通过对不同表不同字段使用不同的数据类型来较大程度减小数据存储量，进而降低 IO 操作次数并提高缓存命中率
- 存储引擎的选择

    ![myisam-innodb对别](/data/images/db/myisam-innodb.png)

- 适当的数据冗余
    - 被频繁引用且只能通过 Join 2 张(或者更多)大表的方式才能得到的独立小字段。这样的场景由于每次 Join 仅仅只是为了取得某个小字段的值，Join 到的记录又大，会造成大量不必要的 IO，完全可以通过空间换取时间的方式来优化。不过，冗余的同时需要确保数据的一致性不会遭到破坏，确保更新的同时冗余字段也被更新
- 适当拆分
    - 当我们的表中存在类似于 TEXT 或者是很大的 VARCHAR 类型的大字段的时候，如果我们大部分访问这张表的时候都不需要这个字段，我们就该义无反顾的将其拆分到另外的独立表中，以减少常用数据所占用的存储空间。这样做的一个明显好处就是每个数据块中可以存储的数据条数可以大大增加，既减少物理 IO 次数，也能大大提高内存中的缓存命中率
    - 分库分表：垂直拆分(不同的业务表存放在不同数据库)、水平拆分(同一表结构的不同数据存放在不同数据库，如基于 id 取模)

#### 数据类型的优化

- 占用存储空间更小的通常更好
- 整型比字符操作代价更低
- 使用 mysql 自建类型，如：不用字符串来存储日期和时间
- 用整型存储 IP 地址
    - `select INET_ATON('255.255.255.255')` 将 ip 转换成整型进行存储，最大值为 4294967295
    - `select INET_ATON(4294967295)` 将整型转换成 ip
- 尽量避免 null (通常情况下 null 的列改为 not null 带来的性能提升比较小，所有没有必要将所有的表的 schema 进行修改，但是应该尽量避免设计成可为 null 的列)
- 数据类型选择，参考[mysql 数据类型](/_posts/db/sql-base.md#数据库基本)

    - 整型：尽量使用满足需求的最小数据类型
    - 字符和字符串类型 [^6]
        - varchar 根据实际内容长度保存数据
            - varchar(n) n 小于等于 255 使用一个字节保存长度，n>255 使用两个字节保存长度
            - 5.0 版本以上，varchar(20)，指的是 20 字符，无论存放的是数字、字母还是 UTF8 汉字（每个汉字 3 字节），都可以存放 20 个。超过 20 个字符也可以存放，最大大小是 65532 字节
            - varchar 在 mysql5.6 之前变更长度，或者从 255 一下变更到 255 以上时时，都会导致锁表
            - 应用场景：存储长度波动较大的数据，如文章
        - char 固定长度的字符串
            - 最大长度 255
            - 会自动删除末尾的空格
            - 检索效率、写效率会比 varchar 高，以空间换时间
            - 应用场景：存储长度波动不大的数据，如 md5 摘要；存储短字符串、经常更新的字符串
    - BLOB 和 TEXT 类型：分别采用二进制和字符方式存储。一般不用此类型，而是将数据直接存储在文件中，并存储文件的路径到数据库
    - timestamp(常用)、datetime、date
        - **timestamp**：占用 4 个字节，可保存时区(依赖数据库设置的时区)，精确到秒，采用明整型存储，存储范围 1970-01-01 到 2038-01-19（目前 linux 已有解决方案到 2486 年）
        - datetime：占用 8 个字节，与时区无关，可保存到毫秒，存储范围 1000-01-01 到 9999-12-31
        - date：占用 3 个字节，精确到日期，存储范围同 datetime
    - 使用枚举代替字符串类型

        ```sql
        create table enum_test(e enum('fish','apple','dog') not null); -- 枚举字段排序基于枚举值定义的位置进行(mysql在内部会将每个值在列表中的位置保存为整数，并且在表的.frm文件中保存"数字-字符串"映射关系的查找表)

        insert into enum_test(e) values('fish'),('dog'),('apple');
        select e+0 from enum_test; -- 查询枚举的索引
        select e from enum_test; -- 查询显示值
        ```

    - JSON 数据类型：参考[JSON 数据类型](/_posts/db/sql-ext.md#JSON数据类型)

### 通过索引进行优化

> https://dev.mysql.com/doc/refman/5.7/en/optimization-indexes.html

#### 索引基本知识

- 操作索引语句：参考[sql-base.md#索引](/_posts/db/sql-base.md#索引)
- 索引的优点
    - 大大减少了服务器需要扫描的数据量
    - 帮助服务器避免排序和临时表
    - 将随机 io 变成顺序 io
- 索引的用处
    - 快速查找匹配 WHERE 子句的行
    - 从 consideration 中消除行。如果可以在多个索引之间进行选择，mysql 通常会使用找到最少行的索引
    - 如果表具有多列索引，则优化器可以使用索引的任何最左前缀来查找行
    - 当有表连接的时候，从其他表检索行数据
    - 查找特定索引列的 min 或 max 值
    - 如果排序或分组时在可用索引的最左前缀上完成的，则对表进行排序和分组
    - 在某些情况下，可以优化查询以检索值而无需查询数据行
- 索引的分类：主键索引、唯一索引(和主键索引的区别是可以有空值, UNIQUE)、普通索引(NORMAL)、全文索引(innodb 5.6 才支持, FULLTEXT)、组合索引(多个字段组成的索引)；其他如：空间索引(SPATIAL)
- [索引采用的数据结构](一#108#1:26:06)

    - mysql 数据文件
        - myisam 存储引擎包含三个文件，如表 test_table 对应：test_table.frm 表描述、test_table.MYD 数据、test_table.MYI 索引
        - innodb 存储引擎包含两个文件，如表 test_table 对应：test_table.frm 表描述、test_table.ibd 数据和索引保存在一起
    - mysql 使用的数据结构
        - 哈希表：memory 型的存储引擎使用的数据结构
        - B+树：myisam、innodb 等使用
    - 相关数据结构对比。[数据结构动态演示-Indexing](https://www.cs.usfca.edu/~galles/visualization/Algorithms.html)

        - 参考：[mysql 数据结构选择.png](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/mysql%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84%E9%80%89%E6%8B%A9.png)
        - 哈希表
            - 使用哈希表，必须包含一个散列算法 ，常见的是取模运算。如将数据进行取模，hash 冲突的通过链表保存
            - 利用 hash 存储需要将所有数据文件添加到内存，比较耗费内存空间。但对于 memory 型的存储引擎很适用
            - hash 对于等值运算较快(key 存储索引值)，而数据库的大多数查询是范围查询，因此此时 hash 效率不高
        - 二叉树、BST 树(二叉搜索树/二叉排序树)、AVL 树(平衡树)、红黑树。都因为每个节点只能有两个子节点，从而树的深度过深造成 io 次数变多，影响数据读取效率

            - 二叉树：缺点是倾斜问题(一个分支较长，一个分支较短)
            - BST 树(Binary Search Trees)：内部会进行排序，二分查找。二叉树和 BST 树都有倾斜问题，从而出现了 AVL 树
            - AVL 树(AVL 为三个作者的名称简写)

                - 需要保证最长子树和最短子树的高度差不能超过 1，否则需要进行旋转(需要旋转 1+N 次)
                - 旋转包括左旋(逆时针旋转)和右旋(顺时针旋转)。左旋是把 Y 节点原来的左孩子当成 X 的右孩子，右旋是把 X 原来的右孩子当成 Y 的左孩子

                    ![二叉树左旋.png](/data/images/db/二叉树左旋.png)

                - 插入删除效率较低，查询效率较高。因此出现了红黑树

            - 红黑树，参考[红黑树.png](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/%E7%BA%A2%E9%BB%91%E6%A0%91.png)
                - 需要保证最长子树不超过最短子树的 2 倍，否则需要进行旋转和变色(减少旋转次数)。特点是任意单分支中不能连续出现两个红色节点，根节点到任意节点的黑色节点个数相同
                - 通过稍微降低查询效率来提高插入和删除效率

        - B 树、B+树、B\*树

            ![b树结构.png](/data/images/db/b树结构.png)

            - B 树：根据 key 值(索引列值)对磁盘块进行分割，如`p1,10,p2,20,p3`(p1 为 key<10 的子树，10 和 20 可直接获取保存的 data 数据，p2 为 `10<=key<20` 的子树，p3 为 `key>=20` 的子树；如果读取 key=5 的 data 数据，则需要再根据 p1 获取子树进行判断)。由于 data 数据(表中的一条记录数据)占用空间较大，而 B 树的分支节点也会存储数据，导致能存储的 key 较少，从而树深度增加，因此 mysql 最终选择 B+树
            - **B+树**
                - 根节点和分支节点只存储指针和键值，而将数据全部存在叶子节点(如果索引是主键则数据存放整好数据，如果索引是其他字段则数据存放的是主键)。B+树的叶子节点互相通过指针进行连接
                - 基本 3 层树结构，即 3 次 io 可支持千万级别的索引存储
                - innodb 的由于数据文件和索引文件在一个文件，索引 data 存储的是每一行记录的所有数据，而 myisam 的 data 存储的则是行记录数据的地址，需要通过数据地址到.MYD 文件中再进行 io 查询出实际数据
            - B\*树：在 B+树的基础上，分支节点也会通过指针进行连接
- 技术名词
    - **回表**：通过普通索引找到的数据(B+树的 data 值)为主键值，如需要获取其他数据时则需要根据主键索引重新检索。`select id, name, sex from user where name = 'smalle'` 此时需要回表查询 sex（name 为索引）
    - **覆盖索引**：通过普通索引查询数据时，只取出索引字段(包括主键)，此时则不需要第二次检索。`select id,name from user where name = 'smalle'`
        - 当发起一个被索引覆盖的查询时，在 explain 的 extra 列可以看到 using index 的信息，此时就使用了覆盖索引
        - 覆盖索引只能覆盖那些只访问索引中部分列的查询，不过可以使用 innodb 的二级索引来覆盖查询
        - memory 存储引擎不支持覆盖索引
    - **最左匹配**(最左前缀)

        - 组合索引时，要么 where 条件中包含索引的字段，要么包含组合索引的第一个字段才会触发组合索引
        - 注意最左前缀，并不是是指一定要按照各个字段出现在 where 中的顺序来建立复合索引的，最终优化器会优化 sql 语句来按照组合索引顺序查询

        ```sql
        -- 如组合索引name, age
        select id, name, sex from t_user where age = 18 and name = 'smalle'; -- 会触发组合索引(优化器会跳转字段顺序)
        select id, name, sex from t_user where name = 'smalle'; -- 会触发组合索引
        select id, name, sex from t_user where age = 18; -- 不会触发组合索引
        -- 如果要实现上述3个sql都通过索引查询，有以下组合索引创建方案(组合索引创建需要考虑查询的顺序和空间使用)
        /*
        1.name + age
        2.age,name + name
        3.name,age + age 的2个索引(其中name,age可触发 name=? and age=? 和 name=? 的查询；而age则为第3个sql准备)
        第1中方案会出现索引合并从而可能降低效率；第2种和第3种的区别是单独的age索引占用磁盘空间比name索引少，从而更优。故而选择第3种
        */
        ```

    - **索引下推**

        ```sql
        -- 索引下推是在存储引擎层完成数据过滤，在(mysql)服务层完成数据过滤则不属于索引下推
        select * from t_user where name like '张%' and age > 18
        /*
        1.非索引下推：根据（name,age）组合索引查询所有满足名称以"张"开头的索引(由于是like，相当于是最左前缀)，然后回表查询出相应的全行数据，然后再筛选出满足年龄大于18的用户数据
        2.索引下推：根据（name,age）组合索引查询所有满足名称以"张"开头的索引，然后直接再筛选出年龄大于18的索引，之后再回表查询全行数据
        其中，第2种方式需要回表查询的全行数据比较少，这就是mysql的索引下推。mysql 5.7开始支持索引下推，且默认启用
        */
        ```

    - **索引合并**

        - where 条件(或者 join)的多个索引字段进行 AND 或者 OR，那么此时就有**可能**会使用到 index merge 技术。index merge 技术如果简单的说，其实就是：对多个索引分别进行条件扫描，然后将它们各自的结果进行合并(intersect/union)。索引合并的时候，会对索引进行并集(union，多个添加为 OR 连接)，交集(intersect，多个添加为 AND 连接)或者先交集再并集(先内部 intersect 然后在外面 union)操作，以便合并成一个索引
        - 这些需要合并的索引只能是一个表的，不能对多表进行索引合并
        - 相同模式的 sql 语句，仅 where 字段取值不同，可能有时能使用索引，有时不能使用索引。是否能使用索引，取决于 mysql 查询优化器对统计数据分析后，是否认为使用索引更快
        - 在使用 explain 对 sql 语句进行操作时，如果使用了索引合并，那么在输出内容的 type 列会显示 index_merge，key 列会显示出所有使用的索引

        ```sql
        -- 可能会使用索引合并
        select * from test where key1=1 and key2=2; -- 可能会使用 intersect
        select * from test where key1=1 or key2=2;  -- 可能会使用 union
        select * from test where key1_col1=1 and key1_col2=2 or key2=2;  -- 可能会使用 union
        -- 不会使用索引合并
        select * from test where key1_col2=2 and key2=2; -- 使用单一索引key2
        select * from test where key1_col2=2 or key2=2; -- 第一个索引不符合最左前缀，因此不会索引合并；且是or，因此整个语句不会使用索引
        -- 显然我们是可以在这三个字段上建立一个组合索引来进行优化的，这样就只需要扫描一个索引一次，而不是对三个所以分别扫描一次
        select * from test where key1=1 and key2=2 and key3=3;
        ```

- 索引匹配方式 (如给 staffs 表创建组合索引 name,age,position)
    - **全值匹配**：指的是和索引中的所有列进行匹配
        - `select * from staffs where name = 'July' and position = 'dev' and age = '23';` 使用 type=ref,ref=const,const,const(将索引的 3 个值当成常量)的索引，尽管此时顺序上 position 在 age 的前面，但是 mysql 优化器会进行优化成索引的顺序
        - `select * from staffs where name = 'July' and position = 1 and age = '23';` 使用 type=ref,ref=const,const(将索引的 2 个值当成常量)的索引。此时 position 字段类型为 varchar，不可能存在 position=1 的数据，因此没有用到 position 的索引
        - `select * from staffs where age = '23';` 不会使用索引，因为检索时发现 where 中没有 name 则直接跳过后面的索引列
    - **最左匹配**(最左前缀)：只匹配前面的几列
        - `select * from staffs where name = 'July' and age = '23';` 使用 type=ref,ref=const,const(将索引的 2 个值当成常量)的索引
    - **匹配列前缀**：可以匹配某一列的值的开头部分
        - `select * from staffs where name like 'J%';` 使用的是 type=range,ref=NULL 的索引
        - `select * from staffs where name like '%y';` 不会使用索引，只能匹配索引开头部分
    - **匹配范围值**：可以查找某一个范围的数据
        - `select * from staffs where name > 'Mary';` 使用 type=range,ref=NULL 的索引
    - **精确匹配某一列并范围匹配另外一列**：可以查询第一列的全部和第二列的部分
        - `select * from staffs where name = 'July' and age > 25 and position = 'dev';` 使用 type=range,ref=NULL 的索引(使用了 name 和 age 进行索引查找，由于 age 使用范围查找则后面的 position 被忽略掉)
        - `select * from staffs where name = 'July' and position > 'dev';` 使用 type=ref,ref=const 的索引(由于索引的顺序是 name,age,position，当没有 age 时，position 会被忽略，所有此处 position 并不会当成索引，而只使用了 name)
    - **覆盖索引**：只访问索引的查询，查询的时候只需要访问索引，不需要访问数据行，本质上就是覆盖索引
        - `select id,name,age,position from staffs where name = 'July' and age = 25 and position = 'dev';` 使用 type=ref,ref=const,const,const,Extra=Using index(其中 Extra=Using index 表示索引覆盖)

#### 哈希索引

- 基于哈希表的实现，只有精确匹配索引所有列的查询才有效(范围匹配不行)
- 在 mysql 中，只有 memory 的存储引擎显式支持哈希索引
- 哈希索引自身只需存储对应的 hash 值，所以索引的结构十分紧凑，这让哈希索引查找的速度非常快
- 哈希索引的限制
    - 哈希索引只包含哈希值和行指针，而不存储字段值，索引不能使用索引中的值来避免读取行(即不支持覆盖索引)
    - 哈希索引数据并不是按照索引值顺序存储的，所以无法进行排序(即不支持索引排序)
    - 哈希索引不支持部分列匹配查找，哈希索引是使用索引列的全部内容来计算哈希值(即不支持最左匹配)
    - 哈希索引支持等值比较查询，不支持任何范围查询
    - 容易出现哈希冲突。访问哈希索引的数据非常快，除非有很多哈希冲突，当出现哈希冲突的时候，存储引擎必须遍历链表中的所有行指针，逐行进行比较，直到找到所有符合条件的行
    - 哈希冲突比较多的话，维护的代价也会很高
- 案例
    - `select id fom url where url_crc=CRC32("http://www.baidu.com") and url="http://www.baidu.com";` 爬虫项目存储 url 时需要先判断是否存在此 url，此时如果直接直接将 url 作为索引，则占用空间较大，效率低；需在存储的时候将 url 按照`CRC32`算法转换并存储(转换后得到的是整数，crc32 区间为 2^32-1)，再通过 url_crc 索引检索，但是 crc32 会出现碰撞，因此加上 url 的辅助筛选
    - CRC32 算法又称循环冗余校验，类似还有 CRC64(出现碰撞的概率小)，常用于校验网络上传输的文件。对应的还有 MD5 和 SHA1 等，这些效率较 CRC32 要差，主要用于加密

#### 聚簇索引与非聚簇索引

- 聚簇索引：不是单独的索引类型，而是一种数据存储方式，指的是数据行跟相邻的键值紧凑的存储在一起。通过索引可以很快的找到数据行，IO 少。**如 InnoDB**
    - 优点
        - 可以把相关数据保存在一起
        - 数据访问更快，因为索引和数据保存在同一个树中
        - 使用覆盖索引扫描的查询可以直接使用页节点中的主键值
    - **缺点**
        - 插入速度严重依赖于插入顺序，按照主键的顺序插入是最快的方式
        - 更新聚簇索引列的代价很高，因为会强制将每个被更新的行移动到新的位置。如果批量导入数据时可以先将索引自动更新暂停，等导入成功后再开启索引自动更新，这样导入速度快
        - 基于聚簇索引的表在插入新行，或者主键被更新导致需要移动行的时候，可能面临页分裂的问题
        - 聚簇索引可能导致全表扫描变慢，尤其是行比较稀疏，或者由于页分裂导致数据存储不连续的时候
        - 聚簇数据最大限度地提高了 IO 密集型应用的性能，如果数据全部在内存，那么聚簇索引就没有什么优势
- 非聚簇索引：**数据文件跟索引文件分开存放。**基于索引的查询过程是先找到索引对应的值，即数据的地址，再根据数据的地址到数据文件中查询实际数据。**如 MyISAM**

#### 优化小细节

- 禁止使用 select \*
- 当使用索引列进行查询的时候尽量不要使用表达式，把计算放到业务层而不是数据库层
- 尽量使用主键查询，而不是其他索引，因为主键查询不会触发回表查询?
- 使用前缀索引(非最左匹配)

    - 有时候需要索引很长的字符串，这会让索引变的大且慢，通常情况下可以使用某个列开始的部分字符串，这样大大的节约索引空间，从而提高索引效率。但这会降低索引的选择性，索引的选择性是指不重复的索引值和数据表记录总数的比值，范围从 1/#T 到 1 之间。索引的选择性越高则查询效率越高，因为选择性更高的索引可以让 mysql 在查找的时候过滤掉更多的行。如数据 AB123、AB234、AB345，如果使用前 2 位作为索引则选择性低，如果使用前 3 位或前 4 位则选择性高
    - 一般情况下某个列前缀的选择性也是足够高的，足以满足查询的性能，但是对应 BLOB,TEXT,VARCHAR 类型的列，必须要使用前缀索引，因为 mysql 不允许索引这些列的完整长度，**使用前缀索引的诀窍在于要选择足够长的前缀以保证较高的选择性，但是又不能太长**
    - 前缀索引是一种能使索引更小更快的有效方法，但是也包含缺点：**mysql 无法使用前缀索引做 order by 和 group by**
    - 案例

        ```sql
        select
            count(distinct left(city,3))/count(*) as sel3, -- 0.0239. 使用前3列作为索引时，不同的值占所有值的比率
            count(distinct left(city,4))/count(*) as sel4, -- 0.0293
            count(distinct left(city,5))/count(*) as sel5, -- 0.0305
            count(distinct left(city,6))/count(*) as sel6, -- 0.0309
            count(distinct left(city,7))/count(*) as sel7, -- 0.0310
            count(distinct left(city,8))/count(*) as sel8  -- 0.0310
        from citydemo;

        -- 可以看到当前缀长度到达7之后，再增加前缀长度，选择性提升的幅度已经很小了，因此可将前7位创建为索引
        alter table citydemo add key(city(7));
        ```

- 排序优化：使用索引扫描来排序

    - mysql 有两种方式可以生成有序的结果：通过排序操作或者按索引顺序扫描。如果 explain 出来的 type=index，则说明 mysql 使用了索引扫描来做排序
    - 扫描索引本身是很快的，因为只需要从一条索引记录移动到紧接着的下一条记录。但如果索引不能覆盖查询所需的全部列，那么就不得不每扫描一条索引记录就得回表查询一次对应的行，这基本都是随机 IO，因此按索引顺序读取数据的速度通常要比顺序地全表扫描慢
    - mysql 可以使用同一个索引即满足排序，又用于查找行，如果可能的话，设计索引时应该尽可能地同时满足这两种任务
    - **只有当索引的列顺序和 order by 子句的顺序完全一致，并且所有列的排序方式都一样(都为 asc 或都为 desc)时，mysql 才能够使用索引来对结果进行排序。如果查询需要关联多张表，则只有当 order by 子句引用的字段全部为第一张表时，才能使用索引做排序。order by 子句和查找型查询的限制是一样的，需要满足索引的最左前缀的要求(where 字句和 order by 字句组合达到最左前缀也可)。**否则，mysql 都需要执行顺序操作，而无法利用索引排序。(group by 和 order by 类似)
    - 案例

        ```sql
        -- sakila数据库中rental表在rental_date,inventory_id,customer_id上有索引
        explain select rental_id,staff_id from rental where rental_date='2005-05-25' order by inventory_id,customer_id; -- type=ref,Extra=Using index condition. 此时order by子句不满足索引的最左前缀的要求，也可以用于查询排序，这是因为索引的第一列在where字句中被指定为一个常数(如果第一列是范围查询则无法触发索引排序)
        explain select rental_id,staff_id from rental where rental_date='2005-05-25' order by inventory_id desc; -- type=ref,Extra=Using where. 该查询为索引的第一列提供了常量条件，而使用第二列进行排序，将两个列组合在一起，就形成了索引的最左前缀
        explain select rental_id,staff_id from rental where rental_date > '2005-05-25' order by rental_date,inventory_id; -- -- type=ALL,Extra=Using where; Using filesort. 不会利用索引，该查询索引第一列是区间查询。**有说如果读取的数据少于30%时，此处也会使用索引排序**
        explain select rental_id,staff_id from rental where rental_date = '2005-05-25' order by inventory_id desc,customer_id asc; -- type=ALL,Extra=Using where; Using filesort. 不会使用索引，该查询使用了两中不同的排序方向，索引都是正序排的(如果索引列全部降序也可以使用索引排序)
        explain select rental_id,staff_id from rental where rental_date = '2005-05-25' order by inventory_id,staff_id; -- type=ALL,Extra=Using where; Using filesort. 不会使用索引，该查询引用了一个不在索引中的列
        ```

- union all、in、or 都能够使用索引，但是推荐使用 in。union all 最少会执行两条语句，or 会循环比对
- 优化 union 查询：除非确实需要服务器消除重复的行，否则一定要使用`union all`，因此没有 all 关键字，mysql 会在查询的时候给临时表加上 distinct 的关键字，这个操作的代价很高，需要注意 union all 可能导致数据重复
- 范围列可以用到索引
    - 范围条件是：`<、<=、>、>=、between、like(列前缀)`
    - 范围列后面的列无法用到索引，索引最多用于一个范围列
- 强制类型转换不会使用索引。如 user 表 age(int 类型)字段索引
    - `explain select * from user where age = 18;` 会使用索引
    - `explain select * from user where age = '18';` 不会使用索引
- 更新十分频繁、数据区分度不高的字段上不宜建立索引
    - 更新会变更 B+树，更新频繁的字段建立索引会大大降低数据库性能
    - 类似于性别、有效状态这类区分不大的属性，建立索引是没有意义的，不能有效的过滤数据。一般区分度在 80%以上的时候就可以建立索引，区分度可以使用 `count(distinct(列名))/count(*)` 来计算
- 创建索引的列最好不允许为 null
- 当需要进行表连接的时候，最好不要超过三张表
    - **mysql 的 join 算法**：Simple Nested-Loop Join(简单嵌套循环连接)、Index Nested-Loop Join(索引嵌套循环连接)、Block Nested-Loop Join(缓存块嵌套循环连接) [^7]
        - `Simple Nested-Loop Join` 匹配次数=外层表行数 \* 内层表行数
        - `Index Nested-Loop Join` 就是通过外层表匹配条件直接与内层表索引进行匹配，避免和内层表的每条记录去进行比较，这样极大的减少了对内层表的匹配次数，此时匹配次数变成了外层表的行数 \* 内层表索引的高度，极大的提升了 join 的性能
        - `Block Nested-Loop Join` 其优化思路是减少外层表的循环次数(io 次数)，通过一次性缓存多条数据，把参与查询的列(select 出来的)缓存到 join buffer 里，然后拿 join buffer 里的数据批量与内层表的数据进行匹配，从而减少了外层循环的次数，当不使用 Index Nested-Loop Join 的时候，默认使用的是 Block Nested-Loop Join(`Show variables like 'optimizer_switc%';`)。**其中 join buffer 的大小默认是 256kb(262144 byte)，可进行设置(64 位最大可使用 4G 的 Join Buffer 空间，查询如`Show variables like 'join_buffer_size%';`)**
    - 表连接查询的优化思路
        - 永远用小结果集驱动大结果集(其本质就是减少外层循环的数据数量)。如果 a 表结果集小于 b 表，理论上应该是 a join b 会更快；但是 mysql 优化器会进行优化，最终决定可能是 b 驱动 a，即 b join a(mysql 中指定了连接条件时，满足查询条件的记录行数少的表为驱动表；如未指定查询条件，则扫描行数少的为驱动表)；也可以通过 a straight_join b 强制让 a 进行驱动(straight_join 只能用于 inner join)，但是一般建议使用 mysql 优化器而不强制指定
        - 为匹配的条件增加索引(减少内层表的循环次数)
        - 增大 join buffer size 的大小(一次缓存的数据越多，那么外层表循环的次数就越少)
        - 减少不必要的字段查询(字段越少，join buffer 所缓存的数据就越多，外层表的循环次数就越少)
- 能使用 limit 的时候尽量使用 limit
- 单表索引建议控制在 5 个以内
- 单索引(组合索引)字段数不允许超过 5 个
- 创建索引的时候应该避免以下错误概念：索引越多越好；过早优化，在不了解系统的情况下进行优化

#### 索引监控

- `show status like 'Handler_read%';`
    - Handler_read_first：读取索引第一个条目的次数
    - **Handler_read_key**：通过 index 获取数据的次数(越大越好)
    - Handler_read_last：读取索引最后一个条目的次数
    - Handler_read_next：通过索引读取下一条数据的次数
    - Handler_read_prev：通过索引读取上一条数据的次数
    - Handler_read_rnd：从固定位置读取数据的次数
    - **Handler_read_rnd_next**：从数据节点读取下一条数据的次数(越大越好)

### 查询优化

- 查询慢的原因：网络、CPU、IO、上下文切换、系统调用、生成统计信息、锁等待时间
- 优化数据访问：减少访问数据量，需要考虑是否向数据库请求了不需要的数据
    - 减少查询不需要的记录，某些场景可以使用 limit 进行优化
    - 减少多表关联时返回全部列，禁止使用 select \*
    - 重复查询相同的数据，基于查询缓存进行优化(查询缓存只适用于改动不频繁的数据，mysql 8 已经移除了查询缓存)
- 执行过程的优化
    - 查询缓存
        - 在解析一个查询语句之前，如果查询缓存是打开的，那么 mysql 会优先检查这个查询是否命中查询缓存中的数据，如果查询恰好命中了查询缓存，那么会在返回结果之前会检查用户权限，如果权限没有问题，那么 mysql 会跳过所有的阶段，就直接从缓存中拿到结果并返回给客户端
        - 查询缓存只适用于改动不频繁的数据，mysql 8 已经移除了查询缓存
    - 查询过程优化(解析 SQL、预处理、优化 SQL 执行计划)
        - mysql 语法解析器和预处理：mysql 通过关键字将 SQL 语句进行解析，并生成 AST 抽象语法树(如开源工具[calcite](https://calcite.apache.org/)也可解析出 AST)。mysql 解析器将使用 mysql 语法规则验证和解析查询，例如验证使用使用了错误的关键字或者顺序是否正确等等，预处理器会进一步检查解析树是否合法，例如表名和列名是否存在，是否有歧义，还会验证权限等等
        - mysql 查询优化器：当语法树没有问题之后，相应的要由优化器将其转成执行计划，一条查询语句可以使用非常多的执行方式，最后都可以得到对应的结果，但是不同的执行方式带来的效率是不同的，优化器的最主要目的就是要选择最有效的执行计划，mysql 使用的是基于成本优化(CBV，还有 RBV 基于规则优化)，在优化的时候会尝试预测一个查询使用某种查询计划时候的成本，并选择其中成本最小的一个
            - 在很多情况下 mysql 会选择错误的执行计划，原因如下
                - 统计信息不准确：InnoDB 因为其 mvcc 的架构，并不能维护一个数据表的行数的精确统计信息
                - 执行计划的成本估算不等同于实际执行的成本：有时候某个执行计划虽然需要读取更多的页面，但是他的成本却更小，因为如果这些页面都是顺序读或者这些页面都已经在内存中的话，那么它的访问成本将很小，mysql 层面并不知道哪些页面在内存中，哪些在磁盘，所以查询之际执行过程中到底需要多少次 IO 是无法得知的
                - mysql 的优化是基于成本模型的优化，但是有可能不是最快的优化
                - mysql 不考虑其他并发执行的查询
                - mysql 不会考虑不受其控制的操作成本，如执行存储过程或者用户自定义函数的成本
            - 优化器的优化策略
                - 静态优化：直接对解析树进行分析，并完成优化
                - 动态优化：动态优化与查询的上下文有关，也可能跟取值、索引对应的行数有关
                - mysql 对查询的静态优化只需要一次，但对动态优化在每次执行时都需要重新评估
            - 优化器的优化类型 - 重新定义关联表的顺序：数据表的关联并不总是按照在查询中指定的顺序进行，决定关联顺序时优化器很重要的功能 
                - **将外连接转化成内连接，内连接的效率要高于外连接** 
                - 使用等价变换规则，mysql 可以使用一些等价变化来简化并规划表达式 
                - 优化 count(),min(),max()：如果某列存在索引，要找到该列的最小值，只需要查询该索引的最左端的记录即可，不需要全文扫描比较 
                - 预估并转化为常数表达式，当 mysql 检测到一个表达式可以转化为常数的时候，就会一直把该表达式作为常数进行处理 
                - 索引覆盖扫描，当索引中的列包含所有查询中需要使用的列的时候，可以使用覆盖索引 
                - 子查询优化 
                - 等值传播：如`select 1 from a join b on a.id = b.id where a.id = 1`和`select 1 from a join b on a.id = b.id where a.id = 1 and b.id = 1`效果是一样的
            - 关联查询优化：参考上文 mysql 的 join 算法
            - **排序优化**
                - 推荐使用利用索引进行排序，但是当不能使用索引的时候，mysql 就需要自己进行排序，如果数据量小则再内存中进行，如果数据量大就需要使用磁盘，mysql 中称之为 filesort。如果需要排序的数据量小于排序缓冲区(`show variables like '%sort_buffer_size%';`)，mysql 使用内存进行快速排序操作，如果内存不够排序，那么 mysql 就会先将数据分块，对每个独立的块使用快速排序进行排序，并将各个块的排序结果存放再磁盘上，然后将各个排好序的块进行合并，最后返回排序结果
                - 排序的算法 - 单次传输排序：先读取查询所需要的所有列，然后再根据给定列进行排序，最后直接返回排序结果，此方式只需要一次顺序 IO 读取所有的数据，而无须任何的随机 IO，问题在于查询的列特别多的时候，会占用大量的存储空间，无法存储大量的数据 - 两次传输排序：第一次数据读取是将需要排序的字段读取出来，然后进行排序，第二次是将排好序的结果按照需要去读取数据行。这种方式效率比较低，原因是第二次读取数据的时候因为已经排好序，需要去读取所有记录而此时更多的是随机 IO，读取数据成本会比较高。两次传输的优势，在排序的时候存储尽可能少的数据，让排序缓冲区可以尽可能多的容纳行数来进行排序操作 - 当需要排序的列的总大小超过`max_length_for_sort_data`定义的字节，mysql 会选择两次排序，反之使用单次排序，当然，用户可以设置此参数的值来选择排序的方式
    - **优化特定类型的查询**
        - 优化 count()查询 - count()、count(id)、count(1)执行效率一样
        - myisam 的 count 函数比较快，这是有前提条件的：只有没有任何 where 条件的 count()才是比较快的
        - 使用近似值：在某些应用场景中，不需要完全精确的值，可以参考使用近似值来代替，比如可以使用 explain 来获取近似的值。其实在很多 OLAP 的应用中，需要计算某一个列值的基数，有一个计算近似值的算法叫 HyperLogLog
        - 更复杂的优化：一般情况下，count()需要扫描大量的行才能获取精确的数据，其实很难优化，在实际操作的时候可以考虑使用索引覆盖扫描，或者增加汇总表，或者增加外部缓存系统
        - 优化关联查询
            - 确保 on 或者 using 子句中的列上有索引，在创建索引的时候就要考虑到关联的顺序。当表 A 和表 B 使用列 C 关联的时候，如果优化器的关联顺序是 B、A，那么就不需要再 B 表的对应列上建上索引，没有用到的索引只会带来额外的负担，一般情况下来说，只需要在关联顺序中的第二个表的相应列上创建索引
            - 确保任何的 group by 和 order by 中的表达式只涉及到一个表中的列，这样 mysql 才有可能使用索引来优化这个过程 - 优化子查询：子查询的优化最重要的优化建议是尽可能使用关联查询代替
        - **减少强制类型转换**。如日期格式的列，传入日期字符串参数则会有效率问题(可能产生现象：PL/SQL使用日期字符串效率不会影响，但是同样的SQL在Mybatis下执行就很慢，当参数全部传入日期时效率得到提升)
    - 优化 limit 分页：优化此类查询的最简单的办法就是尽可能地使用覆盖索引，而不是查询所有的列

        ```sql
        select film_id,description from film order by title limit 10000,10;
        
        -- 优化后(数据量大时才有效果)
        select a.film_id,a.description 
        from film a 
        join (select film_id from film order by title limit 10000,10) as b using(film_id);
        ```

    - 优化 union 查询：除非确实需要服务器消除重复的行，否则一定要使用`union all`，因此没有 all 关键字，mysql 会在查询的时候给临时表加上 distinct 的关键字，这个操作的代价很高
    - 推荐使用用户自定义变量：参考[sql-ext.md#自定义变量](/_posts/db/sql-ext.md#自定义变量)

### 分区表

> https://dev.mysql.com/doc/refman/5.7/en/partitioning.html

- 分区表为 mysql 功能，不同于分区分表，但是效果类似
- 对于用户而言，分区表是一个独立的逻辑表，但是底层是由多个物理子表组成。分区表对于用户而言是一个完全封装底层实现的黑盒子，对用户而言是透明的，从文件系统中可以看到多个使用#分隔命名的表文件。mysql 在创建表时使用 partition by 子句定义每个分区存放的数据，在执行查询的时候，优化器会根据分区定义过滤那些没有我们需要数据的分区，这样查询就无须扫描所有分区
- 分区表的应用场景
    - 表非常大以至于无法全部都放在内存中，或者只在表的最后部分有热点数据，其他均是历史数据
    - 分区表的数据更容易维护：批量删除大量数据可以使用清除整个分区的方式；对一个独立分区进行优化、检查、修复等操作
    - 分区表的数据可以分布在不同的物理设备上，从而高效地利用多个硬件设备
    - 可以使用分区表来避免某些特殊的瓶颈：innodb 的单个索引的互斥访问；ext3 文件系统的 inode 锁竞争
    - 可以备份和恢复独立的分区
- 分区表的限制
    - 一个表最多只能有 1024 个分区，在 5.7 版本的时候可以支持 8196 个分区(即 8196 个文件)
    - 在早期的 mysql 中，分区表达式必须是整数或者是返回整数的表达式，在 mysql5.5 中，某些场景可以直接使用列来进行分区
    - 如果分区字段中有主键或者唯一索引的列，那么所有主键列和唯一索引列都必须包含进来
    - 分区表无法使用外键约束
    - **分区表技术不是用于提升 MySQL 数据库的性能，而是方便数据的管理**
        - https://learn.lianglianglee.com/%E4%B8%93%E6%A0%8F/MySQL%E5%AE%9E%E6%88%98%E5%AE%9D%E5%85%B8/14%20%20%E5%88%86%E5%8C%BA%E8%A1%A8%EF%BC%9A%E5%93%AA%E4%BA%9B%E5%9C%BA%E6%99%AF%E6%88%91%E4%B8%8D%E5%BB%BA%E8%AE%AE%E7%94%A8%E5%88%86%E5%8C%BA%E8%A1%A8%EF%BC%9F.md
- 在使用分区表的时候需要注意的问题
    - null 值会使分区过滤无效
    - 分区列和索引列不匹配，会导致查询无法进行分区过滤
    - 选择分区的成本可能很高
    - 打开并锁住所有底层表的成本可能很高
    - 维护分区的成本可能很高
- 分区表的底层原理
    - 分区表由多个相关的底层表实现，这个底层表也是由句柄对象标识，我们可以直接访问各个分区。存储引擎管理分区的各个底层表和管理普通表一样（所有的底层表都必须使用相同的存储引擎），分区表的索引知识在各个底层表上各自加上一个完全相同的索引。从存储引擎的角度来看，底层表和普通表没有任何不同，存储引擎也无须知道这是一个普通表还是一个分区表的一部
    - 当查询/新增/删除一个分区表的时候，分区层先打开并锁住所有的底层表，优化器先判断是否可以过滤部分分区；当更新一条记录时，分区层先打开并锁住所有的底层表，mysql 先确定需要更新的记录再哪个分区，然后取出数据并更新，再判断更新后的数据应该再哪个分区，最后对底层表进行写入操作，并对源数据所在的底层表进行删除操作
    - 虽然每个操作都会"先打开并锁住所有的底层表"，但这并不是说分区表在处理过程中是锁住全表的，如果存储引擎能够自己实现行级锁，例如 innodb，则会在分区层释放对应表锁
- 分区表的类型
    - 范围分区
    - 列表分区
        - 类似于按 range 分区，区别在于 list 分区是基于列值匹配一个离散值集合中的某个值来进行选择
    - 列分区
        - mysql 从 5.5 开始支持 column 分区，可以认为 i 是 range 和 list 的升级版，在 5.5 之后，可以使用 column 分区替代 range 和 list，但是 column 分区只接受普通列不接受表达式
    - hash 分区
    - key 分区
        - 类似于 hash 分区，区别在于 key 分区只支持一列或多列，且 mysql 服务器提供其自身的哈希函数，必须有一列或多列包含整数值
    - 子分区
        - 在分区的基础之上，再进行分区后存储
    - 案例

        ```sql
        -- 范围分区
        create table members (
            username varchar(16) not null,
            joined date not null
        )
        partition by range(year(joined)) (
            partition p0 values less than (2000),
            partition p1 values less than (2010),
            partition p2 values less than maxvalue
        );

        -- 列表分区
        create table employees (
            id int not null,
            fname varchar(30),
            store_id int
        )
        partition by list(store_id) (
            partition pnorth values in (3,5,6,9,17),
            partition peast values in (1,2,10,11,19,20),
            partition pwest values in (4,12,13,14,18),
            partition pcentral values in (7,8,15,16)
        );

        -- 列分区
        create table members (
            firstname varchar(25) not null,
            lastname varchar(25) not null,
            username varchar(16) not null,
            company_id int not null
        )
        partition by range columns(company_id, firstname) (
            partition p0 values less than (5,'aaa') engine = innodb,
            partition p1 values less than (10,'bbb') engine = innodb
        );

        -- hash分区
        create table employees (
            id int not null,
            fname varchar(30),
            store_id int
        )
        partition by hash(store_id)
        partitions 4; -- 按4取模分成4个分区

        -- key分区
        create table tk (
            col1 int not null,
            col2 char(5),
            col3 date
        )
        partition by linear key (col1)
        partitions 3;

        -- 子分区
        create table ts (id int, purchased date)
        partition by range( year(purchased) )
        subpartition by hash( to_days(purchased) )
        subpartitions 2 (
            partition p0 values less than (1990),
            partition p1 values less than (2000),
            partition p2 values less than maxvalue
        );

        create table ts (id int, purchased date)
        partition by range( year(purchased) )
        subpartition by hash( to_days(purchased) ) (
            partition p0 values less than (1990) (
                subpartition s0,
                subpartition s1
            ),
            partition p1 values less than (2000),
            partition p2 values less than maxvalue (
                subpartition s2,
                subpartition s3
            )
        );
        ```

### 服务器参数设置

> https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html

- 通用参数
    - `datadir=/var/lib/mysql` 数据文件存放的目录
    - `socket=/var/lib/mysql/mysql.sock` mysql.socket 表示 server 和 client 在同一台服务器，并且使用 localhost 进行连接，就会使用 socket 进行连接
    - `pid_file=/var/lib/mysql/mysql.pid` 存储 mysql 的 pid
    - `port=3306` mysql 服务的端口号
    - `default_storage_engine=InnoDB` mysql 存储引擎
    - **`skip-grant-tables`** 当忘记 mysql 的用户名密码的时候，可以在 mysql 配置文件中配置该参数，跳过权限表验证，不需要密码即可登录 mysql
- 字符集参数
    - `character_set_server` mysql server 的默认字符集
    - `character_set_client` 客户端数据的字符集
    - `character_set_connection` mysql 处理客户端发来的信息时，会把这些数据转换成连接的字符集格式
    - `character_set_database` 数据库默认的字符集
    - `character_set_results` mysql 发送给客户端的结果集所用的字符集
- 连接参数
    - `max_connections` mysql 的最大连接数，如果数据库的并发连接请求比较大，应该调高该值
    - `max_user_connections` 限制每个用户的连接个数
    - `back_log` mysql 能够暂存的连接数量，当 mysql 的线程在一个很短时间内得到非常多的连接请求时，就会起作用，如果 mysql 的连接数量达到 max_connections 时，新的请求会被存储在堆栈中，以等待某一个连接释放资源，如果等待连接的数量超过 back_log，则不再接受连接资源
    - `wait_timeout` 和 `interactive_timeout` [^8]
        - `wait_timeout` mysql 在关闭一个非交互的连接之前需要等待的时长。默认值是 28800s(8h)，最大为 24 天。一般连接池的超时时间要小于此时间
        - `interactive_timeout` 关闭一个交互连接之前需要等待的秒数。默认值 wait_timeout
        - 控制连接最大空闲时长的 wait_timeout 参数(seesion 级别：`set session WAIT_TIMEOUT=10;`)
        - 对于交互式连接(即在 mysql_real_connect 函数中使用了 CLIENT_INTERACTIVE 选项)，类似于 mysql 客户端连接，wait_timeout 的值继承自服务器端全局变量 interactive_timeout(`set global INTERACTIVE_TIMEOUT=10;`)。对于非交互式连接，类似于 jdbc 连接，wait_timeout 的值继承自服务器端全局变量 wait_timeout
        - 判断一个连接的空闲时间，可通过 show processlist 输出中 Sleep 状态的时间
- 日志参数
    - `log_error` 指定错误日志文件名称，用于记录当 mysqld 启动和停止时，以及服务器在运行中发生任何严重错误时的相关信息
    - `log_bin` 指定二进制日志文件名称，用于记录对数据造成更改的所有查询语句
    - `binlog_do_db` 指定需要将更新记录到二进制日志的数据库名，其他所有没有显式指定的数据库更新将忽略，不记录在日志中
    - `binlog_ignore_db` 指定不将更新记录到二进制日志的数据库
    - **`sync_binlog`** 指定多少次写日志后同步磁盘
        - sync_binlog=0，表示 MySQL 不控制 binlog 的刷新，由文件系统自己控制它的缓存的刷新。这时候的性能是最好的，但是风险也是最大的。因为一旦系统 Crash，在 binlog_cache 中的所有 binlog 信息都会被丢失
        - 如果 sync_binlog>0，表示每 sync_binlog 次事务提交，MySQL 调用文件系统的刷新操作将缓存刷下去
            - 最安全的就是 sync_binlog=1 了，表示每次事务提交，MySQL 都会把 binlog 刷下去，是最安全但是性能损耗最大的设置。这样的话，在数据库所在的主机操作系统损坏或者突然掉电的情况下，系统才有可能丢失 1 个事务的数据。但是 binlog 虽然是顺序 IO，但是设置 sync_binlog=1，多个事务同时提交，同样很大的影响 MySQL 和 IO 性能。虽然可以通过 group commit 的补丁缓解，但是刷新的频率过高对 IO 的影响也非常大。对于高并发事务的系统来说，sync_binlog 设置为 0 和设置为 1 的系统写入性能差距可能高达 5 倍甚至更多
            - 所以很多 MySQL DBA 设置的 sync_binlog 并不是最安全的 1，而是 100 或者是 0。这样牺牲一定的一致性，可以获得更高的并发和性能
    - `general_log` 是否开启查询日志记录
    - `general_log_file` 指定查询日志文件名，用于记录所有的查询语句
    - **`slow_query_log`** 是否开启慢查询日志记录。`set global slow_query_log=1`
        - `slow_query_log_file` 指定慢查询日志文件名称，用于记录耗时比较长的查询语句。默认值为 host_name-slow.log
        - `long_query_time` 设置慢查询的时间，超过这个时间的查询语句才会记录日志。默认 10 秒
        - `min_examined_row_limit` 设置慢查询返回结果数，超过这个值查询语句才会记录日志。默认是 0
        - 默认情况，管理类的 SQL 语句、不使用索引的 SQL 语句都不会被记录。`log_slow_admin_statements` 和 `log_queries_not_using_indexes` 两个变量决定了是否能记录前面提到的情况
- 缓存参数
    - `key_buffer_size` 索引缓存区的大小(只对 myisam 表起作用)
    - query cache 查询缓存
        - `query_cache_type` 缓存类型，决定缓存什么样的查询
            - `0` 表示禁用
            - `1` 表示将缓存所有结果。除非 sql 语句中使用`select sql_no_cache * from test`禁用查询缓存
            - `2` 表示只缓存 select 语句中通过`select sql_cache * from test`指定需要缓存的查询
        - `query_cache_size` 查询缓存的大小，未来版本被删除，`show status like '%Qcache%';` 查看缓存的相关属性
            - `Qcache_free_blocks` 缓存中相邻内存块的个数，如果值比较大，那么查询缓存中碎片比较多
            - `Qcache_free_memory` 查询缓存中剩余的内存大小
            - `Qcache_hits` 表示有多少次命中缓存
            - `Qcache_inserts` 表示多少次未命中而插入
            - `Qcache_lowmen_prunes` 多少条 query 因为内存不足而被移除 cache
            - `Qcache_queries_in_cache` 当前 cache 中缓存的 query 数量
            - `Qcache_total_blocks` 当前 cache 中 block 的数量
        - `query_cache_limit` 超出此大小的查询将不被缓存
        - `query_cache_min_res_unit` 缓存块最小大小
    - **`sort_buffer_size`** 每个需要排序的线程分派该大小的缓冲区，通用配置。像各存储引擎如 innodb 有`innodb_sort_buffer_size`可覆盖此参数(innodb 默认 1M，1048576)
    - **`max_allowed_packet`** 限制 server 接受的数据包大小。如果太小，大量数据初始化导入时可能会报错。默认 4M，最大 1G，BLOB/JSON 数据类型的字段也受此参数限制
    - **`join_buffer_size`** 表示关联缓存的大小，默认 256kb(262144 byte)。参考上文排序优化
    - `thread_cache_size` 线程缓存
        - `Threads_cached` 代表当前此时此刻线程缓存中有多少空闲线程
        - `Threads_connected` 代表当前已建立连接的数量
        - `Threads_created` 代表最近一次服务启动，已创建现成的数量，如果该值比较大，那么服务器会一直再创建线程
        - `Threads_running` 代表当前激活的线程数
- [Innodb 存储引擎参数](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html)
    - **`innodb_buffer_pool_size`** 该参数指定大小的内存来缓冲数据和索引，默认值 128MB，最大可以设置为物理内存的 80%
    - **`innodb_flush_log_at_trx_commit`** 主要控制 innodb 将 log buffer 中的数据写入日志文件并 flush 磁盘的时间点，值分别为`0`，`1`，`2`，默认是 1。详细参考[sql-base.md#InnoDB 日志(Redo/Undo)](</_posts/db/sql-base.md#InnoDB日志(Redo/Undo)>)
    - **`innodb_log_buffer_size`** 写日志文件到磁盘的缓冲区大小，以 M 为单位，默认 8M
    - **`innodb_log_file_size`** 日志组中每个日志文件大小，以 M 为单位，默认 48M
    - **`innodb_log_files_in_group`** 日志组中日志文件个数，默认 2。InnoDB 以循环方式将日志文件写到多个文件中(第一个文件写完则写第二个，第二写完则写第一个，循环往复)
    - `read_buffer_size` mysql 读入缓冲区大小，对表进行顺序扫描的请求将分配到一个读入缓冲区
    - `read_rnd_buffer_size` mysql 随机读的缓冲区大小
    - `innodb_sort_buffer_size` 每个需要排序的线程分派该大小的缓冲区
    - `innodb_file_per_table` 此参数确定为每张表分配一个新的文件，否则数据文件都保存在`ibdata1`文件中
    - `innodb_thread_concurrency` 设置 innodb 线程的并发数，默认为 0 表示不受限制，如果要设置建议跟服务器的 cpu 核心数一致或者是 cpu 核心数的两倍

### Mysql 集群

#### 主从复制

#### 读写分离

#### 分库分表

### SQL 写法优化

- 判断是否存在

```sql
select count(*) from table where a = 1 and b = 2;
-- 性能更优
select 1 from table where a = 1 and b = 2 limit 1;
```

## Oracle

> 如无特殊说明，此文测试环境均为 Oracle 11.2g

### SQL 优化

- exists 和 in 的查询效率。如：select \* from A where id in(select id from B) - in()适合 B 表比 A 表数据小的情况 - exists()适合 B 表比 A 表数据大的情况 - 当 A 表数据与 B 表数据一样大时，in 与 exists 效率差不多，但是使用 in 时索引不会生效
- 两张大表写 join 查询比写 exists 快

```sql
-- 案例：获取没有任何联系人信息的客户数量。
-- `t_customer` 客户表，主表(一对多)。`t_customer_contact` 客户联系人表，子表

-- 优化前：使用 exists。18万条数据基本3分钟还没查询出来（单表查询更新几万条数据速度还行）
select count(1)
  from t_customer t
 where exists
 (select 1
          from t_customer_contact cc
         where cc.customer_id = t.id
           and (cc.tel_no is not null or cc.cellphone is not null))

-- 优化后：使用表关联。0.22秒
select count(1)
  from (select t.customer_name_cn,
               count(cc.id) as counts -- 此处必须统计子表字段。如果是 count(1) 则是基于主表统计
          from t_customer t
          left join t_customer_contact cc -- 关联子表容易导致主表记录多条(及时不select子表中的字段)
            on cc.customer_id = t.id
           and (cc.tel_no is not null or cc.cellphone is not null) -- 也可将on and中的条件写到where中进行过滤。特定情况可考虑根据子表id是否有值来过滤
         group by t.customer_name_cn
        having count(cc.id) = 0) -- 此处还无法使用上面定义的 counts
```
- 关联条件位置

```sql
-- 出现一个问题：cid = 2可以正常查询，cid = 1无法查询出，报错 ORA-03113
select a.*
from t_a a
left join t_b b on b.pid = a.id
where b.cid = 1
-- 可正常查询：增加关联条件并改成join，右边 t_b 这张表会变小，从而关联数据变少（上面相当于全部关联，然后再过滤）
select a.*
from t_a a
join t_b b on b.pid = a.id and b.cid = 1
```

### 批量更新优化

> https://www.cnblogs.com/Marydon20170307/p/10097243.html

- 批量更新基于 PL/SQL 分批提交更新
    - `update`语句比较耗资源
        - 测试一条 update 语句修改`2w`条数据(总共`18w`条数据的表，查询出这 2w 条很快)，运行时间太长，基本不可行
        - 在`200w`的数据中修改`300`条数据，set 基于临时表，where 中基于临时表嵌套其他表和结合 exists 进行数据过滤，耗时`3s`
    - 使用 PL/SQL Developer 里面的 Test Window(可进行调试)写循环更新，`2w`条更新耗时`0.7s`。如果数据量再大一些可以分批 commit
- **`bulk collect`与`forall`**语句提高效率 [^2] [^3]

```sql
declare
  -- 作废大连分办关联的客户 (5000条)
  cursor c is select * from t_structure_customer sc where sc.valid_status = 1 and sc.structure_id = (select s.id from t_structure s where s.node_code = 'DLC' and s.node_level = 10);
  type tb_structure is table of c%rowtype;
  rd_structure tb_structure;

  n_visit number := 0;
  n_office number := 0;
begin
  open c;
  loop
    -- rd_structure结构必须和c中的结构一致，不能是超集或子集
    fetch c bulk collect into rd_structure limit 500; -- PL/SQL引擎会向SQL引擎发送 10 次请求(防止内存溢出). 最终跑完耗时3分钟左右(下面的select可以再优化成只查询一次？)
    exit when rd_structure.count = 0; -- 不能用 `exit when c%notfound;`，否则会出现少于500条的不会执行

    /*
    -- forall的性能高于for的性能
    forall i in 1..rd_structure.count
      update t_customer c set c.valid_status = 0, c.update_tm = sysdate where c.valid_status = 1 and c.id = rd_structure(i).customer_id;
    commit;
    */
    for i in 1..rd_structure.count loop
      -- 是否有拜访记录. 拜访记录有 200w 条数据, 如果不使用bulk collect的情况下，基本无法运行(卡死，在loop的第一行都无法输出任何数据)。如果此处select小表还可以执行完此程序
      select count(1) into n_visit from t_visit v where v.valid_status = 1 and v.customer_id = rd_structure(i).customer_id;
      if n_visit > 0 then
        continue;
      end if;

      -- 是否有其他分办绑定
      select count(1) into n_office from t_structure_customer sc where sc.valid_status = 1 and sc.customer_id = rd_structure(i).customer_id;
      if n_visit > 1 then
        continue;
      end if;

      update t_customer c set c.valid_status = 0, c.update_tm = sysdate where c.valid_status = 1 and c.id = rd_structure(i).customer_id;
      update t_structure_customer sc set sc.valid_status = 0 where sc.valid_status = 1 and sc.customer_id = rd_structure(i).customer_id;
    end loop;

    commit;
  end loop;
  close c;
end;
```

### Oracle 执行计划(Explain Plan) [^1]

- 在 **PL/SQL** 的`Explain plan window`中执行并查看
- sqlplus 下执行
    - `explain plan for select * from emp;` 创建执行计划
    - `select * from table(dbms_xplan.display);` 查看执行计划

#### 案例一: 添加索引

- 功能点：使用条件查询, 查询场存
- 优化前基本查询不出来, 且经常导致数据库服务器 CPU 飙高。优化后查询时间 1 秒不到。优化方式：添加索引
- sql 语句如下

```sql
select *
  from (select rownum as rn, paging_t1.*
          from (select ys.box_number as V1, substr(bcc.bcc_cont_size, 1, 2) as V2,
                       bcc.bcc_cont_type as V3, to_char(yiorin.input_tm, 'yyyy/MM/dd HH24:mi:ss') as V10,
                       yiorin.source_Go_Code as V11, ypmpti.note as V12,
                       decode(yyi.box_Status, 'GOOD_BOX', '好', 'BAD_BOX', '坏', '') as V13,
                       yiorin.customer_Num as V17,
                       decode(ybts.match_Id, null, ybts.box_Type, ybts.box_Type || ' - ' || ybts.match_Id) as V18,
                       yiorin.plan_Remark as V19, yiorin.license_Plate_Num as V20, ypctrans.short_Name as V21, ypcbox.short_Name as V31,
                       count(*) over() paging_total
                  from Ycross_In_Out_Regist yiorin
                  left join Ycross_Storage ys on ys.in_out_regist_id = yiorin.in_out_regist_id
                  left join Ybase_Cont_Code bcc on bcc.id = ys.bcc_cont_id
                  left join Ybase_Type_Maintenance ypmpti on ypmpti.type in ('PLAN_TYPE_IN', 'PLAN_TYPE_IN_INSIDE')
                    and ypmpti.code = yiorin.plan_Classification_Code
                  left join Yrebx_Yanxiang_Info yyi on yyi.history_Id is null and yyi.yes_status not in (7) and yyi.id = yiorin.yanxiang_Id
                  left join Yyard_Box_Type_Set ybts on ybts.id = ys.box_Type_Id
                  left join Ybase_Party_Company ypctrans on ypctrans.party_id = yiorin.transport_Company_Id
                  left join Ybase_Party_Company ypcbox on ypcbox.party_id = ys.party_id
                 where 1 = 1
                   and yiorin.yes_status = 1
                   and (yiorin.input_tm between to_date('2018/07/26 00:00:00', 'yyyy/MM/dd HH24:mi:ss')
                        and to_date('2018/07/27 00:00:00', 'yyyy/MM/dd HH24:mi:ss')
                       and exists
                        (select 1 from Yyard_Location_Set yls
                          where 1 = 1 and yls.location_id = ys.location_id and yls.yard_Party_Id in ('11651')))
                 order by V1 ASC) paging_t1
         where rownum < 51) paging_t2
 where paging_t2.rn >= 1
```

- PL/SQL Explain 执行情况

![oracle-explain-yard1](/data/images/db/oracle-explain-yard1.png)

- 分析：表`YCROSS_IN_OUT_REGIST`(进出场记录)和`YCROSS_STORAGE`(场存)是进行内联循环(`NESTED LOOPS`)连接的，而在查询`YCROSS_STORAGE`的时候消耗资源值(`Cost`)为 2758(查询堆位等基础表消耗资源基本可忽略)。而场存和进出场记录进行关联是通过`in_out_regist_id`字段关联。尝试给`YCROSS_STORAGE`表添加外键`create index index_in_out_regist_id on ycross_storage(in_out_regist_id);`后，查询效率得到明显改善

#### 案例二: 改写 sql

- 功能点: 道口获取有效的计划
- sql 语句

```sql
-- select * from( -- 修改 1
select distinct ypyn.plan_yard_num_id, ypyn.plan_id, ypyn.bcc_cont_id, ypyn.cont_num,

                nvl(t12.actual_cont_num, 0) actual_cont_num, -- 2种修改都需注释
                t12.lately_input_tm, -- 2种修改都需注释
                /**
                -- 修改 1
                nvl(count(yior.in_out_regist_id) over(partition by ypyn.plan_yard_num_id), 0) actual_cont_num,
                first_value(yior.input_tm) over(partition by ypyn.plan_yard_num_id order by yior.input_tm desc rows between unbounded preceding and unbounded following) as lately_input_tm,
                **/

                /**
                -- 修改 2
                t1.actual_cont_num,
                t1.lately_input_tm,
                **/

                yp.cont_party_id, yp.plan_classification_code, yp.bl_num, yp.vessel_num, yp.voy_num, yp.customer_num,
                yp.is_appoint, yp.trans_party_id, yi.source_code, yi.box_type, yi.yard_note, yi.unrent_num, yi.unrent_party_id, yyd.is_visible
  from Ycama_Plan_Yard_Num ypyn
  join Ycama_Yard_Detail yyd on (ypyn.plan_yard_num_id = yyd.plan_yard_num_id)
  join Ycama_Plan yp on (ypyn.plan_id = yp.plan_id)
  left join Ycama_Instore yi on (yp.plan_id = yi.plan_id)

  -- 取实际完成数和最近选择计划时间

  -- 2种修改都需注释
  left join (select t1.plan_yard_num_id, t1.actual_cont_num, t2.lately_input_tm
               from (select yior1.plan_yard_num_id, count(yior1.plan_yard_num_id) actual_cont_num
                       from Ycross_In_Out_Regist yior1
                      where yior1.yes_status = 1 group by yior1.plan_yard_num_id) t1
               left join (select yior2.plan_yard_num_id, max(yior2.input_tm) lately_input_tm
                           from Ycross_In_Out_Regist yior2
                          where yior2.yes_status = 1 group by yior2.plan_yard_num_id) t2
                 on (t1.plan_yard_num_id = t2.plan_yard_num_id)) t12
    on (ypyn.plan_yard_num_id = t12.plan_yard_num_id)

    -- left join Ycross_In_Out_Regist yior on ypyn.plan_yard_num_id = yior.plan_yard_num_id and yior.yes_status = 1 -- 修改 1

    /**
    -- 修改 2
    left join (
         select ypyn.plan_yard_num_id,
         nvl(count(yior.in_out_regist_id) over(partition by ypyn.plan_yard_num_id), 0) actual_cont_num,
         first_value(yior.input_tm) over(partition by ypyn.plan_yard_num_id order by yior.input_tm desc rows between unbounded preceding and unbounded following) as lately_input_tm
         from Ycama_Plan_Yard_Num ypyn left join Ycross_In_Out_Regist yior on ypyn.plan_yard_num_id = yior.plan_yard_num_id and yior.yes_status = 1
    ) t1 on t1.plan_yard_num_id = ypyn.plan_yard_num_id
    **/

 where yp.plan_type_code = 'Approach_Plan'
  and (yp.plan_class_status_code = 'NoCompleted_Plan' or yp.plan_class_status_code = 'Carry_Plan')
  and yp.begin_time < sysdate and yp.end_time > sysdate

   -- and ypyn.cont_num > nvl(t12.actual_cont_num, 0) -- 2种修改都需注释
   -- and ypyn.cont_num > t1.actual_cont_num -- 修改 2

   and yyd.yard_party_id in (10052) and yp.plan_Class_Status_Code <> 'Fulfilment_Plan'
   and (yp.customer_num like '%TRSH180727-2%' or yp.customer_num is null)
-- ) a where a.cont_num > actual_cont_num -- 修改 1
```

- 原始 Explain 执行情况

![oracle-explain-yard2](/data/images/db/oracle-explain-yard2.png)

- 修改 1 的 Explain 执行情况

![oracle-explain-yard3](/data/images/db/oracle-explain-yard3.png)

- 修改 2 的 Explain 执行情况

![oracle-explain-yard4](/data/images/db/oracle-explain-yard4.png)

- 分析：从上述执行情况可见
    - 原始查询(执行时间 1.2 秒左右)
        - 逻辑：先根据计划编号分组统计进出场记录中每个计划的实际完成条数(actual_cont_num)和最近执行计划时间(lately_input_tm)，然后将此子查询关联到`YCAMA_PLAN_YARD_NUM`(计划表)中
        - Explain: 进行了两次`YCROSS_IN_OUT_REGIST`(进出场记录)的全表查询(`TABLE ACCESS FULL`)，并且在最后进行 distinct 去重(执行策略`HASH UNIQUE`)时消耗了很多资源(???)
    - 修改 1(执行时间 0.6 秒左右)
        - 逻辑：直接关联子表进出场记录 YCROSS_IN_OUT_REGIST，此时通过开窗函数提取 YCROSS_IN_OUT_REGIST 的字段。然后在最外层套一个查询进行条件过滤
        - Explain: 资源全部用在 YCROSS_IN_OUT_REGIST 的全表查询上，去重基本无消耗(???)
    - 修改 2(执行时间 1.2 秒左右)
        - 说明: 由于修改 1 对线上环境改动较大，尝试此写法发现 Explain 显示资源消耗明细降低，但是实际执行时间并没有多大改善。(然并卵)
        - 逻辑：先子查询中通过开窗函数得到 YCAMA_PLAN_YARD_NUM 的时间完成条数和最近执行时间，然后关联到 YCAMA_PLAN_YARD_NUM 中
        - Explain: 开窗函数消耗较多资源，去重基本无消耗(???)
- 由于上述资源消耗主要在 YCAMA_PLAN_YARD_NUM 和 YCROSS_IN_OUT_REGIST 的关联上，因此给 YCROSS_IN_OUT_REGIST 添加索引`create index index_plan_yard_num_id on ycross_in_out_regist(plan_yard_num_id);`。添加索引后 Explain 显示都有明显改善，实际执行时间：1.2 秒(原始)、0.3 秒(原始)、0.3 秒(原始)

    - 原始 Explain 执行情况(添加索引后)

    ![oracle-explain-yard5](/data/images/db/oracle-explain-yard5.png)

    - 修改 1 的 Explain 执行情况(添加索引后)

    ![oracle-explain-yard6](/data/images/db/oracle-explain-yard6.png)

    - 修改 2 的 Explain 执行情况(添加索引后，最后的表关联策略由`HASH JOIN OUTER`变为`NESTED LOOPS`)

    ![oracle-explain-yard7](/data/images/db/oracle-explain-yard7.png)

## SQL Server

```sql
SET SHOWPLAN_ALL ON; -- 开启执行计划展示，开启后再运行sql语句
SET SHOWPLAN_ALL OFF; -- 关闭执行计划展示
```

## 快速生成百万测试数据

- 生成数据工具：https://github.com/gangly/datafaker，基于python
- 简单的基于存储过程

```sql
-- 参考：https://www.cnblogs.com/peterpoker/p/9758103.html
-- 创建部门表
drop table if exists test_order;
create table test_order (
	id bigint not null primary key,
	p_id bigint,
	user_id bigint,
	user_no varchar(20) default '',
    order_no varchar(20) default '',
	valid_status int(1) default 1,
	create_date date comment '创建日期',
	ext1 varchar(20),
	ext2 varchar(20),
	ext3 varchar(20),
	ext4 varchar(20),
	ext5 varchar(20),
	ext6 varchar(20),
	ext7 varchar(20),
	ext8 varchar(20),
	ext9 varchar(20),
	ext10 varchar(20),
	ext11 varchar(20),
	ext12 varchar(20),
	ext13 varchar(20),
	ext14 varchar(20),
	ext15 varchar(20),
	ext16 varchar(20),
	ext17 varchar(20),
	ext18 varchar(20),
	ext19 varchar(20),
	ext20 varchar(20),
	ext21 varchar(20),
	ext22 varchar(20),
	ext23 varchar(20),
	ext24 varchar(20),
	ext25 varchar(20),
	ext26 varchar(20),
	ext27 varchar(20),
	ext28 varchar(20),
	ext29 varchar(20),
	ext30 varchar(20),
	ext31 varchar(20),
	ext32 varchar(20),
	ext33 varchar(20),
	ext34 varchar(20),
	ext35 varchar(20),
	ext36 varchar(20),
	ext37 varchar(20),
	ext38 varchar(20),
	ext39 varchar(20),
	ext40 varchar(20),
	ext41 varchar(20),
	ext42 varchar(20),
	ext43 varchar(20),
	ext44 varchar(20),
	ext45 varchar(20),
	ext46 varchar(20),
	ext47 varchar(20),
	ext48 varchar(20),
	ext49 varchar(20),
	ext50 varchar(20)
);

-- 创建员工表
drop table if exists test_user;
create table test_user (
	id bigint not null primary key,
  user_no varchar(20) default '0',
  user_name varchar(20) default '',
  job varchar(20) default '',
  mgr varchar(20) default '0' comment '上级编号',
  hiredate date not null comment '入职日期',
  salary decimal(7,2) comment '薪水',
  comm decimal(7,2) comment '红利',
	ext1 varchar(20),
	ext2 varchar(20),
	ext3 varchar(20),
	ext4 varchar(20),
	ext5 varchar(20),
	ext6 varchar(20),
	ext7 varchar(20),
	ext8 varchar(20),
	ext9 varchar(20),
	ext10 varchar(20),
	ext11 varchar(20),
	ext12 varchar(20),
	ext13 varchar(20),
	ext14 varchar(20),
	ext15 varchar(20),
	ext16 varchar(20),
	ext17 varchar(20),
	ext18 varchar(20),
	ext19 varchar(20),
	ext20 varchar(20),
	ext21 varchar(20),
	ext22 varchar(20),
	ext23 varchar(20),
	ext24 varchar(20),
	ext25 varchar(20),
	ext26 varchar(20),
	ext27 varchar(20),
	ext28 varchar(20),
	ext29 varchar(20),
	ext30 varchar(20),
	ext31 varchar(20),
	ext32 varchar(20),
	ext33 varchar(20),
	ext34 varchar(20),
	ext35 varchar(20),
	ext36 varchar(20),
	ext37 varchar(20),
	ext38 varchar(20),
	ext39 varchar(20),
	ext40 varchar(20),
	ext41 varchar(20),
	ext42 varchar(20),
	ext43 varchar(20),
	ext44 varchar(20),
	ext45 varchar(20),
	ext46 varchar(20),
	ext47 varchar(20),
	ext48 varchar(20),
	ext49 varchar(20),
	ext50 varchar(20)
);

-- 创建随机字符串函数，便于创建名称
drop function if exists test_rand_string;
create function test_rand_string(n int)
	returns varchar(255) -- 返回字符串，注意：此处关键字是returns 而不是return
begin
    -- 定义一个临时变量，给变量赋值'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz'
    declare chars_str varchar(100) default 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz';
    -- 定义返回结果字符串
    declare return_str varchar(255) default '';
    declare i int default 0;
    while i < n do
        set return_str = concat(return_str,substring(chars_str,floor(1+rand()*52),1));
        set i=i+1;
    end while;
    return return_str;
end;

-- 创建随机编号生成函数
drop function if exists test_rand_num;
create function test_rand_num()
	returns int(5)
begin
	declare i int default 0;
	set i = floor(10+rand()*500);
	return i;
end;

-- 插入数据存储过程
drop procedure if exists test_insert_data;
create procedure test_insert_data(in start_no int(10), in max_num int(10))
begin
	declare i int default 0;
	set autocommit = 0; -- 设置自动提交为false
	repeat
		set i = i+1;

		insert into test_user values(
				(start_no+i), test_rand_string(20), test_rand_string(12), test_rand_string(6), 0001, curdate(), test_rand_num(), 400,
				test_rand_string(1), test_rand_string(2), test_rand_string(3), test_rand_string(4), test_rand_string(5), test_rand_string(6), test_rand_string(7), test_rand_string(8), test_rand_string(9), test_rand_string(10),
				test_rand_string(11), test_rand_string(12), test_rand_string(13), test_rand_string(14), test_rand_string(15), test_rand_string(16), test_rand_string(17), test_rand_string(18), test_rand_string(19), test_rand_string(20),
				test_rand_string(1), test_rand_string(2), test_rand_string(3), test_rand_string(4), test_rand_string(5), test_rand_string(6), test_rand_string(7), test_rand_string(8), test_rand_string(9), test_rand_string(10),
				test_rand_string(11), test_rand_string(12), test_rand_string(13), test_rand_string(14), test_rand_string(15), test_rand_string(16), test_rand_string(17), test_rand_string(18), test_rand_string(19), test_rand_string(20),
				test_rand_string(1), test_rand_string(2), test_rand_string(3), test_rand_string(4), test_rand_string(5), test_rand_string(6), test_rand_string(7), test_rand_string(8), test_rand_string(9), test_rand_string(10)
		);

		insert into test_order values(
				(start_no+i), (test_rand_num()+i), test_rand_num(), test_rand_string(12), test_rand_string(20), 1, curdate(),
				test_rand_string(1), test_rand_string(2), test_rand_string(3), test_rand_string(4), test_rand_string(5), test_rand_string(6), test_rand_string(7), test_rand_string(8), test_rand_string(9), test_rand_string(10),
				test_rand_string(11), test_rand_string(12), test_rand_string(13), test_rand_string(14), test_rand_string(15), test_rand_string(16), test_rand_string(17), test_rand_string(18), test_rand_string(19), test_rand_string(20),
				test_rand_string(1), test_rand_string(2), test_rand_string(3), test_rand_string(4), test_rand_string(5), test_rand_string(6), test_rand_string(7), test_rand_string(8), test_rand_string(9), test_rand_string(10),
				test_rand_string(11), test_rand_string(12), test_rand_string(13), test_rand_string(14), test_rand_string(15), test_rand_string(16), test_rand_string(17), test_rand_string(18), test_rand_string(19), test_rand_string(20),
				test_rand_string(1), test_rand_string(2), test_rand_string(3), test_rand_string(4), test_rand_string(5), test_rand_string(6), test_rand_string(7), test_rand_string(8), test_rand_string(9), test_rand_string(10)
		);

        if (start_no+i)%500=0 then
			commit;
		end if;
	until i=max_num
	end repeat;
    commit;
    set autocommit = 1;
end;

-- 生成百万级数据
call test_insert_data(10000, 10000000);
```

---

参考文章

[^1]: http://www.cnblogs.com/xqzt/p/4467867.html (Oracle 执行计划)
[^2]: https://www.cnblogs.com/zgz21/p/5864298.html (oracle for loop 循环以及游标循环)
[^3]: https://www.cnblogs.com/hellokitty1/p/4584333.html (Oracle 数据库之 FORALL 与 BULK COLLECT 语句)
[^4]: https://www.cnblogs.com/wishyouhappy/p/3681771.html (oracle 索引)
[^5]: https://www.cnblogs.com/zhanjindong/p/3439042.html
[^6]: https://www.cnblogs.com/gomysql/p/3615897.html
[^7]: https://www.cnblogs.com/rainwang/p/12123310.html
[^8]: https://www.cnblogs.com/ivictor/p/5979731.html (MySQL 中 interactive_timeout 和 wait_timeout 的区别)
