---
layout: "post"
title: "SQL优化"
date: "2018-07-27 14:58"
categories: [db]
tags: [oracle, dba, sql]
---

## 总结

- 比如统计用户的点击情况，根据用户年龄分两种情况，年龄小于10岁或大于50岁的一次点击算作2，其他年龄段的一次点击算作1(实际情况可能更复杂)。如果在where条件中使用or可能会导致查询很慢，此时可以考虑查询出所有用户、年龄类别、点击次数，再在外层套一层查询通过case when进行合计

## Mysql调优

- mysql架构：客户端 -> 服务端(连接器 - 分析器 - 优化器 - 执行器) -> 存储引擎
- mysql测试表结构和数据：https://dev.mysql.com/doc/index-other.html (Example Databases)
    - [employee data](https://github.com/datacharmer/test_db)
    - [world database](https://downloads.mysql.com/docs/world.sql.zip)
    - [world_x database](https://downloads.mysql.com/docs/world_x-db.zip)
    - [sakila database](https://downloads.mysql.com/docs/sakila-db.zip)
    - [menagerie database](https://downloads.mysql.com/docs/menagerie-db.zip)

### 性能监控

- 使用 `show profile` 命令(**之后mysql版本可能会被移除**)
    - 使用
        - 此工具默认是禁用的，可以通过服务器变量在会话级别动态的修改 `set profiling=1;`
        - 当设置完成之后，在服务器上执行的所有语句，都会测量其耗费的时间和其他一些查询执行状态变更相关的数据。select * from emp;
        - 在mysql的命令行模式下只能显示两位小数的时间，可以使用如下命令查看具体的执行时间 `show profiles;`
        - 执行如下命令可以查看详细的每个步骤的时间 `show profile for query 2;`
    - type
        - all：显示所有性能信息。show profile all for query n
        - block io：显示块io操作的次数。show  profile block io for query n
        - context switches：显示上下文切换次数，被动和主动。show profile context switches for query n
        - cpu：显示用户cpu时间、系统cpu时间。show profile cpu for query n
        - IPC：显示发送和接受的消息数量。show profile ipc for query n
        - Memory：暂未实现
        - page faults：显示页错误数量。show profile page faults for query n
        - source：显示源码中的函数名称与位置。show profile source for query n
        - swaps：显示swap的次数。show profile swaps for query n
- 更多的是使用`performance schema`来监控mysql。服务器默认是开启状态(关闭可在my.ini中设置)，开启后会有一个performance_schema数据库(表中数据记录在内存，服务关闭则数据销毁)
    - [MYSQL performance schema详解](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/MYSQL%20performance%20schema%E8%AF%A6%E8%A7%A3.md)
    - 数据库CPU飙高问题参考：[http://blog.aezo.cn/2018/03/13/java/Java%E5%BA%94%E7%94%A8CPU%E5%92%8C%E5%86%85%E5%AD%98%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90/](/_posts/java/Java应用CPU和内存异常分析.md#Mysql)
- 使用`show processlist`查看连接的线程个数，来观察是否有大量线程处于不正常的状态或者其他不正常的特征
    - command表示当前状态
        - sleep：线程正在等待客户端发送新的请求
        - query：线程正在执行查询或正在将结果发送给客户端
        - locked：在mysql的服务层，该线程正在等待表锁
        - analyzing and statistics：线程正在收集存储引擎的统计信息，并生成查询的执行计划
        - Copying to tmp table：线程正在执行查询，并且将其结果集都复制到一个临时表中
        - sorting result：线程正在对结果集进行排序
        - sending data：线程可能在多个状态之间传送数据，或者在生成结果集或者向客户端返回数据
    - state表示命令执行状态

### 执行计划(explain)

- [参考：mysql执行计划](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/mysql%E6%89%A7%E8%A1%8C%E8%AE%A1%E5%88%92.md)
- `explain`查看执行计划。如`explain select * from t_test;`
- explain返回字段：id、select_type、table、type、possible_keys、key、key_len、ref、rows、Extra，含义如下 [^5]
  - id：id越大的语句越先执行，相同的则从上向下依次执行
  - select_type有下列常见几种
    - SIMPLE：最简单的SELECT查询，没有使用UNION或子查询
    - PRIMARY：在嵌套的查询中是最外层的SELECT语句，在UNION查询中是最前面的SELECT语句
    - UNION：UNION中第二个以及后面的SELECT语句
    - DERIVED：派生表SELECT语句中FROM子句中的SELECT语句
    - UNION RESULT：一个UNION查询的结果
    - DEPENDENT UNION：首先需要满足UNION的条件，及UNION中第二个以及后面的SELECT语句，同时该语句依赖外部的查询
    - SUBQUERY：子查询中第一个SELECT语句
    - DEPENDENT SUBQUERY：和DEPENDENT UNION相对UNION一样
  - table：显示的这一行信息是关于哪一张表的。有时候并不是真正的表名。如`<derivedN>`N就是id值、`<unionM,N>`这种类型，出现在UNION语句中
  - **type**：type列很重要，是用来说明表与表之间是如何进行关联操作的，有没有使用索引。主要有下面几种类别(查询速度依次递减)
    - const：当确定最多只会有一行匹配的时候，MySQL优化器会在查询前读取它而且只读取一次，因此非常快。const只会用在将常量和主键或唯一索引进行比较时，而且是比较所有的索引字段
    - system：这是const连接类型的一种特例，表仅有一行满足条件
    - eq_ref：eq_ref类型是除了const外最好的连接类型，它用在一个索引的所有部分被联接使用并且索引是UNIQUE或PRIMARY KEY。需要注意InnoDB和MyISAM引擎在这一点上有点差别。InnoDB当数据量比较小的情况type会是All
    - ref：这个类型跟eq_ref不同的是，它用在关联操作只使用了索引的最左前缀，或者索引不是UNIQUE和PRIMARY KEY。ref可以用于使用=或<=>操作符的带索引的列
    - fulltext：联接是使用全文索引进行的，一般我们用到的索引都是B树
    - ref_or_null：该类型和ref类似。但是MySQL会做一个额外的搜索包含NULL列的操作。在解决子查询中经常使用该联接类型的优化
    - index_merger：该联接类型表示使用了索引合并优化方法。在这种情况下，key列包含了使用的索引的清单，key_len包含了使用的索引的最长的关键元素
    - unique_subquery：该类型替换了下面形式的IN子查询的ref，是一个索引查找函数，可以完全替换子查询，效率更高
    - index_subquery：该联接类型类似于unique_subquery
    - range：只检索给定范围的行，使用一个索引来选择行。key列显示使用了哪个索引。key_len包含所使用索引的最长关键元素。在该类型中ref列为NULL。当使用=、<>、>、>=、<、<=、IS NULL、<=>、BETWEEN或者IN操作符，用常量比较关键字列时，可以使用range
    - index：该联接类型与ALL相同，除了只有索引树被扫描。这通常比ALL快，因为索引文件通常比数据文件小。这个类型通常的作用是告诉我们查询是否使用索引进行排序操作
    - ALL：最慢的一种方式，即全表扫描
  - possible_keys：指出MySQL能使用哪个索引在该表中找到行
  - key：显示MySQL实际决定使用的键（索引）。如果没有选择索引，键是NULL。要想强制MySQL使用或忽视possible_keys列中的索引，在查询中使用FORCE INDEX、USE INDEX或者IGNORE INDEX
  - key_len：显示MySQL决定使用的键长度。如果键是NULL，则长度为NULL。使用的索引的长度，在不损失精确性的情况下，长度越短越好
  - ref：显示使用哪个列或常数与key一起从表中选择行
  - rows：显示MySQL认为它执行查询时必须检查的行数。注意这是一个预估值
  - filtered：表示存储引擎返回的数据在server层过滤后，剩下多少满足查询的记录数量的比例，注意是百分比，不是具体记录数
  - **Extra**：显示MySQL在查询过程中的一些详细信息
    - Using filesort：MySQL有两种方式可以生成有序的结果，通过排序操作或者使用索引，当Extra中出现了Using filesort 说明MySQL使用了后者，但注意虽然叫filesort但并不是说明就是用了文件来进行排序，只要可能排序都是在内存里完成的。大部分情况下利用索引排序更快，所以一般这时也要考虑优化查询了
    - Using temporary：说明使用了临时表，一般看到它说明查询需要优化了，就算避免不了临时表的使用也要尽量避免硬盘临时表的使用。
    - Not exists：MYSQL优化了LEFT JOIN，一旦它找到了匹配LEFT JOIN标准的行， 就不再搜索了。
    - Using index：说明查询是覆盖了索引的，这是好事情。MySQL直接从索引中过滤不需要的记录并返回命中的结果。这是MySQL服务层完成的，但无需再回表查询记录。
    - Using index condition：这是MySQL 5.6出来的新特性，叫做"索引条件推送"。简单说一点就是MySQL原来在索引上是不能执行如like这样的操作的，但是现在可以了，这样减少了不必要的IO操作，但是只能用在二级索引上，详情点这里。
    - Using where：使用了WHERE从句来限制哪些行将与下一张表匹配或者是返回给用户

### schema与数据类型优化

> https://dev.mysql.com/doc/refman/5.7/en/optimizing-database-structure.html

- [数据类型的优化](#数据类型的优化)
- 合理使用范式和反范式
    - 在企业中很少能做到严格意义上的范式或者反范式，一般需要混合使用
        - 在一个网站实例中，这个网站，允许用户发送消息，并且一些用户是付费用户。现在想查看付费用户最近的10条信息。在user表和message表中都存储用户类型(account_type)而不用完全的反范式化。这避免了完全反范式化的插入和删除问题，因为即使没有消息的时候也绝不会丢失用户的信息。这样也不会把user_message表搞得太大，有利于高效地获取数据
        - 另一个从父表冗余一些数据到子表的理由是排序的需要
        - 缓存衍生值也是有用的。如果需要显示每个用户发了多少消息（类似论坛的），可以每次执行一个昂贵的自查询来计算并显示它；也可以在user表中建一个num_messages列，每当用户发新消息时更新这个值
- 主键的选择
    - 包含代理主键、自然主键(如身份证号)。一般选择代理主键，它不与业务耦合，可很好的配合主键生成策略使用
- 字符集的选择
    - 纯拉丁字符能表示的内容，可使用默认的 latin1
    - 多语言才会用到utf8(mysql的utf8编码最大只能存放3个字节)、utf8mb4(mb4指most bytes 4，因此最大可以存放4个字节)。中文有可能占用2、3、4个字节，mysql的utf8编码可以存放大部分中文，而少数中文需要用到utf8mb4
    - MySQL的字符集可以精确到字段，可以通过对不同表不同字段使用不同的数据类型来较大程度减小数据存储量，进而降低 IO 操作次数并提高缓存命中率
- 存储引擎的选择

    ![myisam-innodb对别](/data/images/db/myisam-innodb.png)
- 适当的数据冗余
    - 被频繁引用且只能通过 Join 2张(或者更多)大表的方式才能得到的独立小字段。这样的场景由于每次Join仅仅只是为了取得某个小字段的值，Join到的记录又大，会造成大量不必要的 IO，完全可以通过空间换取时间的方式来优化。不过，冗余的同时需要确保数据的一致性不会遭到破坏，确保更新的同时冗余字段也被更新
- 适当拆分
    - 当我们的表中存在类似于 TEXT 或者是很大的 VARCHAR类型的大字段的时候，如果我们大部分访问这张表的时候都不需要这个字段，我们就该义无反顾的将其拆分到另外的独立表中，以减少常用数据所占用的存储空间。这样做的一个明显好处就是每个数据块中可以存储的数据条数可以大大增加，既减少物理 IO 次数，也能大大提高内存中的缓存命中率
    - 分库分表：垂直拆分(不同的业务表存放再不同数据库)、水平拆分(同一表结构的不同数据存放在不同数据库，如基于id取模)

#### 数据类型的优化

- 占用存储空间更小的通常更好
- 整型比字符操作代价更低
- 使用mysql自建类型，如不用字符串来存储日期和时间
- 用整型存储IP地址
    - `select INET_ATON('255.255.255.255')` 将ip转换成整型进行存储，最大值为4294967295
    - `select INET_ATON(4294967295)` 将整型转换成ip
- 尽量避免null (通常情况下null的列改为not null带来的性能提升比较小，所有没有必要将所有的表的schema进行修改，但是应该尽量避免设计成可为null的列)
- 数据类型选择，参考[mysql数据类型](/_posts/db/sql-base.md#数据库基本)
    - 整型：尽量使用满足需求的最小数据类型
    - 字符和字符串类型 [^6]
        - varchar根据实际内容长度保存数据
            - varchar(n) n小于等于255使用一个字节保存长度，n>255使用两个字节保存长度
            - 5.0版本以上，varchar(20)，指的是20字符，无论存放的是数字、字母还是UTF8汉字（每个汉字3字节），都可以存放20个。超过20个字符也可以存放，最大大小是65532字节
            - varchar在mysql5.6之前变更长度，或者从255一下变更到255以上时时，都会导致锁表
            - 应用场景：存储长度波动较大的数据，如文章
        - char固定长度的字符串
            - 最大长度255
            - 会自动删除末尾的空格
            - 检索效率、写效率会比varchar高，以空间换时间
            - 应用场景：存储长度波动不大的数据，如md5摘要；存储短字符串、经常更新的字符串
    - BLOB和TEXT类型：分别采用二进制和字符方式存储。一般不用此类型，而是将数据直接存储在文件中，并存储文件的路径到数据库
    - datetime、timestamp(常用)、date
        - datetime：占用8个字节，与时区无关，可保存到毫秒，存储范围1000-01-01到9999-12-31
        - timestamp：占用4个字节，可保存时区(依赖数据库设置的时区)，精确到秒，采用明整型存储，存储范围1970-01-01到2038-01-19
        - date：占用3个字节，精确到日期，存储范围同datetime
    - 使用枚举代替字符串类型

        ```sql
        create table enum_test(e enum('fish','apple','dog') not null); -- 枚举字段排序基于枚举值定义的位置进行(mysql在内部会将每个值在列表中的位置保存为整数，并且在表的.frm文件中保存"数字-字符串"映射关系的查找表)

        insert into enum_test(e) values('fish'),('dog'),('apple');
        select e+0 from enum_test; -- 查询枚举的索引
        select e from enum_test; -- 查询显示值
        ```

### 通过索引进行优化

> https://dev.mysql.com/doc/refman/5.7/en/optimization-indexes.html

#### 索引基本知识

- 操作索引语句：参考[sql-base.md#索引](/_posts/db/sql-base.md#索引)
- 索引的优点
    - 大大减少了服务器需要扫描的数据量
    - 帮助服务器避免排序和临时表
    - 将随机io变成顺序io
- 索引的用处
    - 快速查找匹配WHERE子句的行
    - 从consideration中消除行。如果可以在多个索引之间进行选择，mysql通常会使用找到最少行的索引
    - 如果表具有多列索引，则优化器可以使用索引的任何最左前缀来查找行
    - 当有表连接的时候，从其他表检索行数据
    - 查找特定索引列的min或max值
    - 如果排序或分组时在可用索引的最左前缀上完成的，则对表进行排序和分组
    - 在某些情况下，可以优化查询以检索值而无需查询数据行
- 索引的分类：主键索引、唯一索引(和主键索引的区别是可以有空值)、普通索引、全文索引(innodb 5.6才支持)、组合索引(多个字段组成的索引，注意点见下文[技术名词-最左匹配])
- [索引采用的数据结构](一#108#1:26:06)
    - mysql数据文件
        - myisam存储引擎包含三个文件，如表test_table对应：test_table.frm 表描述、test_table.MYD 数据、test_table.MYI 索引
        - innodb存储引擎包含两个文件，如表test_table对应：test_table.frm 表描述、test_table.ibd 数据和索引保存在一起
    - mysql使用的数据结构
        - 哈希表：memory型的存储引擎使用的数据结构
        - B+树：innodb等使用
    - 相关数据结构对比。[数据结构动态演示-Indexing](https://www.cs.usfca.edu/~galles/visualization/Algorithms.html)
        - 参考：[mysql数据结构选择.png](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/mysql%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84%E9%80%89%E6%8B%A9.png)
        - 哈希表
            - 使用哈希表，必须包含一个散列算法 ，常见的是取模运算。如将数据进行取模，hash冲突的通过链表保存
            - 利用hash存储需要将所有数据文件添加到内存，比较耗费内存空间。但对于memory型的存储引擎很适用
            - hash对于等值运算较快(key存储索引值)，而数据库的大多数查询是范围查询，因此此时hash效率不高
        - 二叉树、BST树(二叉搜索树/二叉排序树)、AVL树(平衡树)、红黑树。都因为每个节点只能有两个子节点，从而树的深度过深造成io次数变多，影响数据读取效率
            - 二叉树：缺点是倾斜问题(一个分支较长，一个分支较短)
            - BST树(Binary Search Trees)：内部会进行排序，二分查找。二叉树和BST树都有倾斜问题，从而出现了AVL树
            - AVL树(AVL为三个作者的名称简写)
                - 需要保证最长子树和最短子树的高度差不能超过1，否则需要进行旋转(需要旋转1-N次)
                - 旋转包括左旋(逆时针旋转)和右旋(顺时针旋转)。左旋是把Y节点原来的左孩子当成X的右孩子，右旋是把X原来的右孩子当成Y的左孩子

                    ![二叉树左旋.png](/data/images/db/二叉树左旋.png)
                - 插入删除效率较低，查询效率较高。因此出现了红黑树
            - 红黑树，参考[红黑树.png](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/%E7%BA%A2%E9%BB%91%E6%A0%91.png)
                - 需要保证最长子树不超过最短子树的2倍，否则需要进行旋转和变色(减少旋转次数)。特点是任意单分支中不能连续出现两个红色节点，根节点到任意节点的黑色节点个数相同
                - 通过稍微降低查询效率来提高插入和删除效率
        - B树、B+树、B*树
            - B树：将key值(索引列值)对磁盘块进行分割，如`p1,10,p2,20,p3`(p1为key<10的子树，10和20可直接获取保存的data数据，p2为10<=key<20的子树，p3为key>=20的子树；如果读取key=5的data数据，则需要再根据p1获取子树进行判断)。由于data数据(表中的一条记录数据)占用空间较大，导致查询每个存储块能存储的key较少，因此mysql最终选择B+树
            - **B+树**
                - 根节点和分支节点只存储指针和键值，而将数据全部存在叶子节点(如果索引是主键则数据存放整好数据，如果索引是其他字段则数据存放的是主键)。B+树的叶子节点互相通过指针进行连接
                - 基本3层树结构，即3次io可支持千万级别的索引存储
                - innodb的由于数据文件和索引文件在一个文件，索引data存储的是每一行记录的所有数据，而myisam的data存储的则是行记录数据的地址，需要通过数据地址到.MYD文件中再进行io查询出实际数据
            - B*树：在B+树的基础上，分支节点也会通过指针进行连接
- 技术名词
    - **回表**：如通过普通索引找到的数据(B+树的data值)为主键值，需要获取其他数据时则需要根据主键索引重新检索。`select id, name, sex from user where name = 'smalle'`
    - **覆盖索引**：通过普通索引查询数据时，只取出主键或索引字段，此时则不需要第二次检索。`select id,name from user where name = 'smalle'`
        - 当发起一个被索引覆盖的查询时，在explain的extra列可以看到using index的信息，此时就使用了覆盖索引
        - 覆盖索引只能覆盖那些只访问索引中部分列的查询，不过可以使用innodb的二级索引来覆盖查询
        - memory存储引擎不支持覆盖索引
    - **最左匹配**：组合索引时，要么where条件中包含索引的字段，要么包含组合索引的第一个字段才会触发组合索引
        
        ```sql
        -- 如组合索引name, age
        select id, name, sex from t_user where name = 'smalle' and age = 18; -- 会触发组合索引
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
        -- 索引下推是在存储引擎层完成数据过滤，在服务层完成数据过滤则不属于索引下推
        select * from t_user where name like '张%' and age > 18
        /*
        1.非索引下推：根据（name,age）组合索引查询所有满足名称以"张"开头的索引，然后回表查询出相应的全行数据，然后再筛选出满足年龄大于18的用户数据
        2.索引下推：根据（name,age）组合索引查询所有满足名称以"张"开头的索引，然后直接再筛选出年龄大于18的索引，之后再回表查询全行数据
        其中，第2种方式需要回表查询的全行数据比较少，这就是mysql的索引下推。mysql 5.7开始支持索引下推，且默认启用
        */
        ```
- 索引匹配方式 (如给staffs表创建组合索引name,age,position)
    - **全值匹配**：指的是和索引中的所有列进行匹配
        - `select * from staffs where name = 'July' and position = 'dev' and age = '23';` 使用type=ref,ref=const,const,const(将索引的3个值当成常量)的索引，尽管此时顺序上position在age的前面，但是mysql优化器会进行优化成索引的顺序
        - `select * from staffs where name = 'July' and position = 1 and age = '23';` 使用type=ref,ref=const,const(将索引的2个值当成常量)的索引。此时position字段类型为varchar，不可能存在position=1的数据，因此没有用到position的索引
        - `select * from staffs where age = '23';` 不会使用索引，因为检索时发现where中没有name则直接跳过后面的索引列
    - **最左匹配**：只匹配前面的几列
        - `select * from staffs where name = 'July' and age = '23';` 使用type=ref,ref=const,const(将索引的2个值当成常量)的索引
    - **匹配列前缀**：可以匹配某一列的值的开头部分
        - `select * from staffs where name like 'J%';` 使用的是type=range,ref=NULL的索引
        - `select * from staffs where name like '%y';` 不会使用索引，只能匹配索引开头部分
    - **匹配范围值**：可以查找某一个范围的数据
        - `select * from staffs where name > 'Mary';` 使用type=range,ref=NULL的索引
    - **精确匹配某一列并范围匹配另外一列**：可以查询第一列的全部和第二列的部分
        - `select * from staffs where name = 'July' and age > 25 position = 'dev';` 使用type=range,ref=NULL的索引(使用了name和age进行索引查找，由于age使用范围查找则后面的position被忽略掉)
        - `select * from staffs where name = 'July' and position > 'dev';` 使用type=ref,ref=const的索引(由于索引的顺序是name,age,position，当没有age时，position会被忽略，所有此处position并不会当成索引，而只使用了name)
    - **覆盖索引**：只访问索引的查询，查询的时候只需要访问索引，不需要访问数据行，本质上就是覆盖索引
        - `select id,name,age,position from staffs where name = 'July' and age = 25 and position = 'dev';` 使用type=ref,ref=const,const,const,Extra=Using index(其中Extra=Using index表示索引覆盖)

#### 哈希索引

- 基于哈希表的实现，只有精确匹配索引所有列的查询才有效(范围匹配不行)
- 在mysql中，只有memory的存储引擎显式支持哈希索引
- 哈希索引自身只需存储对应的hash值，所以索引的结构十分紧凑，这让哈希索引查找的速度非常快
- 哈希索引的限制
    - 哈希索引只包含哈希值和行指针，而不存储字段值，索引不能使用索引中的值来避免读取行(即不支持覆盖索引)
    - 哈希索引数据并不是按照索引值顺序存储的，所以无法进行排序(即不支持索引排序)
    - 哈希索引不支持部分列匹配查找，哈希索引是使用索引列的全部内容来计算哈希值(即不支持最左匹配)
    - 哈希索引支持等值比较查询，不支持任何范围查询
    - 容易出现哈希冲突。访问哈希索引的数据非常快，除非有很多哈希冲突，当出现哈希冲突的时候，存储引擎必须遍历链表中的所有行指针，逐行进行比较，直到找到所有符合条件的行
    - 哈希冲突比较多的话，维护的代价也会很高
- 案例
    - `select id fom url where url_crc=CRC32("http://www.baidu.com") and url="http://www.baidu.com";` 爬虫项目存储url时需要先判断是否存在此url，此时如果直接直接将url作为索引，则占用空间较大，效率低；需在存储的时候将url按照`CRC32`算法转换并存储(转换后得到的是整数，crc32区间为2^32-1)，再通过url_crc索引检索，但是crc32会出现碰撞，因此加上url的辅助筛选
    - CRC32算法又称循环冗余校验，类似还有CRC64(出现碰撞的概率小)，常用于校验网络上传输的文件。对应的还有MD5和SHA1等，这些效率较CRC32要差，主要用于加密

#### 聚簇索引与非聚簇索引

- 聚簇索引：不是单独的索引类型，而是一种数据存储方式，指的是数据行跟相邻的键值紧凑的存储在一起。通过索引可以很快的找到数据化，IO少。如InnoDB
    - 优点
        - 可以把相关数据保存在一起
        - 数据访问更快，因为索引和数据保存在同一个树中
        - 使用覆盖索引扫描的查询可以直接使用页节点中的主键值
    - 缺点
        - 聚簇数据最大限度地提高了IO密集型应用的性能，如果数据全部在内存，那么聚簇索引就没有什么优势
        - 插入速度严重依赖于插入顺序，按照主键的顺序插入是最快的方式
        - 更新聚簇索引列的代价很高，因为会强制将每个被更新的行移动到新的位置
        - 基于聚簇索引的表在插入新行，或者主键被更新导致需要移动行的时候，可能面临页分裂的问题
        - 聚簇索引可能导致全表扫描变慢，尤其是行比较稀疏，或者由于页分裂导致数据存储不连续的时候
- 非聚簇索引：数据文件跟索引文件分开存放。基于索引的查询过程是先找到索引对应的值，即数据的地址，再根据数据的地址到数据文件中查询实际数据。如MyISAM

#### 优化小细节

- 禁止使用select *
- 当使用索引列进行查询的时候尽量不要使用表达式，把计算放到业务层而不是数据库层
- 尽量使用主键查询，而不是其他索引，因为主键查询不会触发回表查询
- 使用前缀索引(非最左匹配)
    - 有时候需要索引很长的字符串，这会让索引变的大且慢，通常情况下可以使用某个列开始的部分字符串，这样大大的节约索引空间，从而提高索引效率。但这会降低索引的选择性，索引的选择性是指不重复的索引值和数据表记录总数的比值，范围从1/#T到1之间。索引的选择性越高则查询效率越高，因为选择性更高的索引可以让mysql在查找的时候过滤掉更多的行。如数据AB123、AB234、AB345，如果使用前2位作为索引则选择性低，如果使用前3位或前4位则选择性高
    - 一般情况下某个列前缀的选择性也是足够高的，足以满足查询的性能，但是对应BLOB,TEXT,VARCHAR类型的列，必须要使用前缀索引，因为mysql不允许索引这些列的完整长度，**使用前缀索引的诀窍在于要选择足够长的前缀以保证较高的选择性，通过又不能太长**
    - 前缀索引是一种能使索引更小更快的有效方法，但是也包含缺点：**mysql无法使用前缀索引做order by 和 group by**
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
    - mysql有两种方式可以生成有序的结果：通过排序操作或者按索引顺序扫描。如果explain出来的type=index，则说明mysql使用了索引扫描来做排序
    - 扫描索引本身是很快的，因为只需要从一条索引记录移动到紧接着的下一条记录。但如果索引不能覆盖查询所需的全部列，那么就不得不每扫描一条索引记录就得回表查询一次对应的行，这基本都是随机IO，因此按索引顺序读取数据的速度通常要比顺序地全表扫描慢
    - mysql可以使用同一个索引即满足排序，又用于查找行，如果可能的话，设计索引时应该尽可能地同时满足这两种任务
    - **只有当索引的列顺序和order by子句的顺序完全一致，并且所有列的排序方式都一样(都为asc或都为desc)时，mysql才能够使用索引来对结果进行排序。如果查询需要关联多张表，则只有当order by子句引用的字段全部为第一张表时，才能使用索引做排序。order by子句和查找型查询的限制是一样的，需要满足索引的最左前缀的要求(where字句和order by字句组合达到最左前缀也可)。**否则，mysql都需要执行顺序操作，而无法利用索引排序。(group by也是对于一张表的字段group by才会使用索引)
    - 案例

        ```sql
        -- sakila数据库中rental表在rental_date,inventory_id,customer_id上有索引
        explain select rental_id,staff_id from rental where rental_date='2005-05-25' order by inventory_id,customer_id; -- type=ref,Extra=Using index condition. 此时order by子句不满足索引的最左前缀的要求，也可以用于查询排序，这是因为索引的第一列在where字句中被指定为一个常数(如果第一列是范围查询则无法触发索引排序)
        explain select rental_id,staff_id from rental where rental_date='2005-05-25' order by inventory_id desc; -- type=ref,Extra=Using where. 该查询为索引的第一列提供了常量条件，而使用第二列进行排序，将两个列组合在一起，就形成了索引的最左前缀
        explain select rental_id,staff_id from rental where rental_date > '2005-05-25' order by rental_date,inventory_id; -- -- type=ALL,Extra=Using where; Using filesort. 不会利用索引，该查询索引第一列是区间查询。**有说如果读取的数据少于30%时，此处也会使用索引排序**
        explain select rental_id,staff_id from rental where rental_date = '2005-05-25' order by inventory_id desc,customer_id asc; -- type=ALL,Extra=Using where; Using filesort. 不会使用索引，该查询使用了两中不同的排序方向，索引都是正序排的(如果索引列全部降序也可以使用索引排序)
        explain select rental_id,staff_id from rental where rental_date = '2005-05-25' order by inventory_id,staff_id; -- type=ALL,Extra=Using where; Using filesort. 不会使用索引，该查询引用了一个不在索引中的列
        ```
- union all、in、or都能够使用索引，但是推荐使用in。union all最少会执行两条语句，or会循环比对
- 优化union查询：除非确实需要服务器消除重复的行，否则一定要使用`union all`，因此没有all关键字，mysql会在查询的时候给临时表加上distinct的关键字，这个操作的代价很高
- 范围列可以用到索引
    - 范围条件是：<、<=、>、>=、between
    - 范围列后面的列无法用到索引，索引最多用于一个范围列
- 强制类型转换会导致全表扫描。如user表age(int类型)字段索引
    - `explain select * from user where age = 18;` 会使用索引
    - `explain select * from user where age = '18';` 不会使用索引
- 更新十分频繁、数据区分度不高的字段上不宜建立索引
    - 更新会变更B+树，更新频繁的字段建立索引会大大降低数据库性能
    - 类似于性别这类区分不大的属性，建立索引是没有意义的，不能有效的过滤数据。一般区分度在80%以上的时候就可以建立索引，区分度可以使用 `count(distinct(列名))/count(*)` 来计算
- 创建索引的列最好不允许为null
- 当需要进行表连接的时候，最好不要超过三张表
    - **mysql的join算法**：Simple Nested-Loop Join(简单嵌套循环连接)、Index Nested-Loop Join(索引嵌套循环连接)、Block Nested-Loop Join(缓存块嵌套循环连接) [^7]
        - `Simple Nested-Loop Join` 匹配次数=外层表行数 * 内层表行数
        - `Index Nested-Loop Join` 就是通过外层表匹配条件 直接与内层表索引进行匹配，避免和内层表的每条记录去进行比较， 这样极大的减少了对内层表的匹配次数，此时匹配次数变成了外层表的行数 * 内层表索引的高度，极大的提升了join的性能
        - `Block Nested-Loop Join` 其优化思路是减少外层表的循环次数，通过一次性缓存多条数据，把参与查询的列缓存到join buffer里，然后拿join buffer里的数据批量与内层表的数据进行匹配，从而减少了外层循环的次数，当不使用Index Nested-Loop Join的时候，默认使用的是Block Nested-Loop Join(`Show variables like 'optimizer_switc%';`)。其中join buffer的大小默认是256kb，可进行设置(64位最大可使用4G的Join Buffer空间，查询如`Show variables like 'join_buffer_size%';`)
    - 表连接查询的优化思路
        - 永远用小结果集驱动大结果集(其本质就是减少外层循环的数据数量)。如果a表结果集小于b表，理论上应该是a join b会更快；但是mysql优化器会进行优化，最终决定可能是b驱动a，即b join a(mysql中指定了连接条件时，满足查询条件的记录行数少的表为驱动表；如未指定查询条件，则扫描行数少的为驱动表)；也可以通过 a straight_join b 强制让a进行驱动(straight_join只能用于inner join)，但是一般建议使用mysql优化器而不强制指定
        - 为匹配的条件增加索引(减少内层表的循环次数)
        - 增大join buffer size的大小(一次缓存的数据越多，那么外层表循环的次数就越少)
        - 减少不必要的字段查询(字段越少，join buffer 所缓存的数据就越多，外层表的循环次数就越少)
- 能使用limit的时候尽量使用limit
- 单表索引建议控制在5个以内
- 单索引(组合索引)字段数不允许超过5个
- 创建索引的时候应该避免以下错误概念：索引越多越好；过早优化，在不了解系统的情况下进行优化

#### 索引监控

- `show status like 'Handler_read%';`
    - Handler_read_first：读取索引第一个条目的次数
    - **Handler_read_key**：通过index获取数据的次数(越大越好)
    - Handler_read_last：读取索引最后一个条目的次数
    - Handler_read_next：通过索引读取下一条数据的次数
    - Handler_read_prev：通过索引读取上一条数据的次数
    - Handler_read_rnd：从固定位置读取数据的次数
    - **Handler_read_rnd_next**：从数据节点读取下一条数据的次数(越大越好)

### *查询优化*

- 查询慢的原因：网络、CPU、IO、上下文切换、系统调用、生成统计信息、锁等待时间
- 优化数据访问：减少访问数据量，需要考虑是否向数据库请求了不需要的数据
    - 查询不需要的记录，某些场景可以使用limit进行优化
    - 多表关联时返回全部列
    - 总是取出全部列，禁止使用select *
    - 重复查询相同的数据，基于查询缓存优化(查询缓存只适用于改动不频繁的数据，mysql 8已经移除了查询缓存)
- 执行过程的优化
    - 查询缓存
        - 在解析一个查询语句之前，如果查询缓存是打开的，那么mysql会优先检查这个查询是否命中查询缓存中的数据，如果查询恰好命中了查询缓存，那么会在返回结果之前会检查用户权限，如果权限没有问题，那么mysql会跳过所有的阶段，就直接从缓存中拿到结果并返回给客户端
        - 查询缓存只适用于改动不频繁的数据，mysql 8已经移除了查询缓存
    - 查询过程优化(解析SQL、预处理、优化SQL执行计划)
        - mysql语法解析器和预处理：mysql通过关键字将SQL语句进行解析，并生成AST抽象语法树(如开源工具[calcite](https://calcite.apache.org/)也可解析出AST)。mysql解析器将使用mysql语法规则验证和解析查询，例如验证使用使用了错误的关键字或者顺序是否正确等等，预处理器会进一步检查解析树是否合法，例如表名和列名是否存在，是否有歧义，还会验证权限等等
        - mysql查询优化器：当语法树没有问题之后，相应的要由优化器将其转成执行计划，一条查询语句可以使用非常多的执行方式，最后都可以得到对应的结果，但是不同的执行方式带来的效率是不同的，优化器的最主要目的就是要选择最有效的执行计划，mysql使用的是基于成本优化(CBV，还有RBV基于规则优化)，在优化的时候会尝试预测一个查询使用某种查询计划时候的成本，并选择其中成本最小的一个
            - 在很多情况下mysql会选择错误的执行计划，原因如下
                - 统计信息不准确：InnoDB因为其mvcc的架构，并不能维护一个数据表的行数的精确统计信息
                - 执行计划的成本估算不等同于实际执行的成本：有时候某个执行计划虽然需要读取更多的页面，但是他的成本却更小，因为如果这些页面都是顺序读或者这些页面都已经在内存中的话，那么它的访问成本将很小，mysql层面并不知道哪些页面在内存中，哪些在磁盘，所以查询之际执行过程中到底需要多少次IO是无法得知的
                - mysql的优化是基于成本模型的优化，但是有可能不是最快的优化
                - mysql不考虑其他并发执行的查询
                - mysql不会考虑不受其控制的操作成本，如执行存储过程或者用户自定义函数的成本
            - 优化器的优化策略
                - 静态优化：直接对解析树进行分析，并完成优化
                - 动态优化：动态优化与查询的上下文有关，也可能跟取值、索引对应的行数有关
                - mysql对查询的静态优化只需要一次，但对动态优化在每次执行时都需要重新评估
            - 优化器的优化类型
	            - 重新定义关联表的顺序：数据表的关联并不总是按照在查询中指定的顺序进行，决定关联顺序时优化器很重要的功能
	            - 将外连接转化成内连接，内连接的效率要高于外连接
	            - 使用等价变换规则，mysql可以使用一些等价变化来简化并规划表达式
	            - 优化count(),min(),max()：如果某列存在索引，要找到该列的最小值，只需要查询该索引的最左端的记录即可，不需要全文扫描比较
	            - 预估并转化为常数表达式，当mysql检测到一个表达式可以转化为常数的时候，就会一直把该表达式作为常数进行处理
	            - 索引覆盖扫描，当索引中的列包含所有查询中需要使用的列的时候，可以使用覆盖索引
	            - 子查询优化
	            - 等值传播：如`select 1 from a join b on a.id = b.id where a.id = 1`和`select 1 from a join b on a.id = b.id where a.id = 1 and b.id = 1`效果是一样的
            - 关联查询优化：参考上文mysql的join算法
            - 排序优化
                - 推荐使用利用索引进行排序，但是当不能使用索引的时候，mysql就需要自己进行排序，如果数据量小则再内存中进行，如果数据量大就需要使用磁盘，mysql中称之为filesort。如果需要排序的数据量小于排序缓冲区(`show variables like '%sort_buffer_size%';`)，mysql使用内存进行快速排序操作，如果内存不够排序，那么mysql就会先将数据分块，对每个独立的块使用快速排序进行排序，并将各个块的排序结果存放再磁盘上，然后将各个排好序的块进行合并，最后返回排序结果
                - 排序的算法
	                - 两次传输排序：第一次数据读取是将需要排序的字段读取出来，然后进行排序，第二次是将排好序的结果按照需要去读取数据行。这种方式效率比较低，原因是第二次读取数据的时候因为已经排好序，需要去读取所有记录而此时更多的是随机IO，读取数据成本会比较高。两次传输的优势，在排序的时候存储尽可能少的数据，让排序缓冲区可以尽可能多的容纳行数来进行排序操作
	                - 单次传输排序：先读取查询所需要的所有列，然后再根据给定列进行排序，最后直接返回排序结果，此方式只需要一次顺序IO读取所有的数据，而无须任何的随机IO，问题在于查询的列特别多的时候，会占用大量的存储空间，无法存储大量的数据
	                - 当需要排序的列的总大小超过`max_length_for_sort_data`定义的字节，mysql会选择两次排序，反之使用单次排序，当然，用户可以设置此参数的值来选择排序的方式
    - **优化特定类型的查询**
	    - 优化count()查询
            - count(*)、count(id)、count(1)执行效率一样
		    - myisam的count函数比较快，这是有前提条件的：只有没有任何where条件的count(*)才是比较快的
		    - 使用近似值：在某些应用场景中，不需要完全精确的值，可以参考使用近似值来代替，比如可以使用explain来获取近似的值。其实在很多OLAP的应用中，需要计算某一个列值的基数，有一个计算近似值的算法叫HyperLogLog
		    - 更复杂的优化：一般情况下，count()需要扫描大量的行才能获取精确的数据，其实很难优化，在实际操作的时候可以考虑使用索引覆盖扫描，或者增加汇总表，或者增加外部缓存系统
	    - 优化关联查询
		    - 确保on或者using子句中的列上有索引，在创建索引的时候就要考虑到关联的顺序。当表A和表B使用列C关联的时候，如果优化器的关联顺序是B、A，那么就不需要再B表的对应列上建上索引，没有用到的索引只会带来额外的负担，一般情况下来说，只需要在关联顺序中的第二个表的相应列上创建索引
            - 确保任何的group by和order by中的表达式只涉及到一个表中的列，这样mysql才有可能使用索引来优化这个过程
	    - 优化子查询：子查询的优化最重要的优化建议是尽可能使用关联查询代替
	    - 优化limit分页：优化此类查询的最简单的办法就是尽可能地使用覆盖索引，而不是查询所有的列

            ```sql
			select film_id,description from film order by title limit 10000,5;
            -- 优化后(数据量大时才有效果)
			explain select a.film_id,a.description from film a join (select film_id from film order by title limit 10000,5) as b using(film_id);
            ```
	    - 优化union查询：除非确实需要服务器消除重复的行，否则一定要使用`union all`，因此没有all关键字，mysql会在查询的时候给临时表加上distinct的关键字，这个操作的代价很高
	    - 推荐使用用户自定义变量：参考[sql-ext.md#自定义变量](/_posts/db/sql-ext.md#自定义变量)
		    
### 分区表

> https://dev.mysql.com/doc/refman/5.7/en/partitioning.html

- 分区表为mysql功能，不同于分区分表，但是效果类似
- 对于用户而言，分区表是一个独立的逻辑表，但是底层是由多个物理子表组成。分区表对于用户而言是一个完全封装底层实现的黑盒子，对用户而言是透明的，从文件系统中可以看到多个使用#分隔命名的表文件。mysql在创建表时使用partition by子句定义每个分区存放的数据，在执行查询的时候，优化器会根据分区定义过滤那些没有我们需要数据的分区，这样查询就无须扫描所有分区。
- 分区表的应用场景
	- 表非常大以至于无法全部都放在内存中，或者只在表的最后部分有热点数据，其他均是历史数据
	- 分区表的数据更容易维护：批量删除大量数据可以使用清除整个分区的方式；对一个独立分区进行优化、检查、修复等操作
	- 分区表的数据可以分布在不同的物理设备上，从而高效地利用多个硬件设备
	- 可以使用分区表来避免某些特殊的瓶颈：innodb的单个索引的互斥访问；ext3文件系统的inode锁竞争
	- 可以备份和恢复独立的分区
- 分区表的限制
	- 一个表最多只能有1024个分区，在5.7版本的时候可以支持8196个分区(即8196个文件)
	- 在早期的mysql中，分区表达式必须是整数或者是返回整数的表达式，在mysql5.5中，某些场景可以直接使用列来进行分区
	- 如果分区字段中有主键或者唯一索引的列，那么所有主键列和唯一索引列都必须包含进来
	- 分区表无法使用外键约束
- 分区表的底层原理
    - 分区表由多个相关的底层表实现，这个底层表也是由句柄对象标识，我们可以直接访问各个分区。存储引擎管理分区的各个底层表和管理普通表一样（所有的底层表都必须使用相同的存储引擎），分区表的索引知识在各个底层表上各自加上一个完全相同的索引。从存储引擎的角度来看，底层表和普通表没有任何不同，存储引擎也无须知道这是一个普通表还是一个分区表的一部
    - 当查询/新增/删除一个分区表的时候，分区层先打开并锁住所有的底层表，优化器先判断是否可以过滤部分分区；当更新一条记录时，分区层先打开并锁住所有的底层表，mysql先确定需要更新的记录再哪个分区，然后取出数据并更新，再判断更新后的数据应该再哪个分区，最后对底层表进行写入操作，并对源数据所在的底层表进行删除操作
    - 虽然每个操作都会"先打开并锁住所有的底层表"，但这并不是说分区表在处理过程中是锁住全表的，如果存储引擎能够自己实现行级锁，例如innodb，则会在分区层释放对应表锁
- 分区表的类型
    - 范围分区
    - 列表分区
        - 类似于按range分区，区别在于list分区是基于列值匹配一个离散值集合中的某个值来进行选择
    - 列分区
        - mysql从5.5开始支持column分区，可以认为i是range和list的升级版，在5.5之后，可以使用column分区替代range和list，但是column分区只接受普通列不接受表达式
    - hash分区
    - key分区
        - 类似于hash分区，区别在于key分区只支持一列或多列，且mysql服务器提供其自身的哈希函数，必须有一列或多列包含整数值
    - 子分区
        - 在分区的基础之上，再进行分区后存储
    - 案例

        ```sql
        -- 范围分区
        CREATE TABLE members (
            username VARCHAR(16) NOT NULL,
            joined DATE NOT NULL
        )
        PARTITION BY RANGE(YEAR(joined)) (
            PARTITION p0 VALUES LESS THAN (2000),
            PARTITION p1 VALUES LESS THAN (2010),
            PARTITION p2 VALUES LESS THAN MAXVALUE
        );

        -- 列表分区
        CREATE TABLE employees (
            id INT NOT NULL,
            fname VARCHAR(30),
            store_id INT
        )
        PARTITION BY LIST(store_id) (
            PARTITION pNorth VALUES IN (3,5,6,9,17),
            PARTITION pEast VALUES IN (1,2,10,11,19,20),
            PARTITION pWest VALUES IN (4,12,13,14,18),
            PARTITION pCentral VALUES IN (7,8,15,16)
        );

        -- 列分区
        CREATE TABLE members (
            firstname VARCHAR(25) NOT NULL,
            lastname VARCHAR(25) NOT NULL,
            username VARCHAR(16) NOT NULL,
            company_id INT NOT NULL
        )
        PARTITION BY RANGE COLUMNS(company_id, firstname) (
            PARTITION p0 VALUES LESS THAN (5,'aaa') ENGINE = InnoDB,
            PARTITION p1 VALUES LESS THAN (10,'bbb') ENGINE = InnoDB
        );

        -- hash分区
        CREATE TABLE employees (
            id INT NOT NULL,
            fname VARCHAR(30),
            store_id INT
        )
        PARTITION BY HASH(store_id)
        PARTITIONS 4; -- 按4取模分成4个分区

        -- key分区
        CREATE TABLE tk (
            col1 INT NOT NULL,
            col2 CHAR(5),
            col3 DATE
        )
        PARTITION BY LINEAR KEY (col1)
        PARTITIONS 3;

        -- 子分区
        CREATE TABLE ts (id INT, purchased DATE)
        PARTITION BY RANGE( YEAR(purchased) )
        SUBPARTITION BY HASH( TO_DAYS(purchased) )
        SUBPARTITIONS 2 (
            PARTITION p0 VALUES LESS THAN (1990),
            PARTITION p1 VALUES LESS THAN (2000),
            PARTITION p2 VALUES LESS THAN MAXVALUE
        );

        CREATE TABLE ts (id INT, purchased DATE)
        PARTITION BY RANGE( YEAR(purchased) )
        SUBPARTITION BY HASH( TO_DAYS(purchased) ) (
            PARTITION p0 VALUES LESS THAN (1990) (
                SUBPARTITION s0,
                SUBPARTITION s1
            ),
            PARTITION p1 VALUES LESS THAN (2000),
            PARTITION p2 VALUES LESS THAN MAXVALUE (
                SUBPARTITION s2,
                SUBPARTITION s3
            )
        );
        ```

116

### 其他

索引合并


## Oracle

> 如无特殊说明，此文测试环境均为 Oracle 11.2g

### SQL优化

- exists和in的查询效率。如：select * from A where id in(select id from B)
	- in()适合B表比A表数据小的情况
	- exists()适合B表比A表数据大的情况
	- 当A表数据与B表数据一样大时，in与exists效率差不多，但是使用in时索引不会生效
- 两张大表写join查询比写exists快

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

### 批量更新优化

- 批量更新基于PL/SQL更新
    - `update`语句比较耗资源
      - 测试一条update语句修改`2w`条数据(总共`18w`条数据的表，查询出这2w条很快)，运行时间太长，基本不可行
      - 在`200w`的数据中修改`300`条数据，set基于临时表，where中基于临时表嵌套其他表和结合exists进行数据过滤，耗时`3s`
    - 使用PL/SQL Developer里面的Test Window(可进行调试)写循环更新，`2w`条更新耗时`0.7s`。如果数据量再大一些可以分批commit
- `forall`与`bulk collect`语句提高效率 [^2] [^3]

```sql
declare
  -- 作废大连分办关联的客户 (5000条)
  cursor c is select * from t_structure_customer sc where sc.valid_status = 1 and sc.structure_id = (select s.id from t_structure s where s.node_code = 'DLC' and s.node_level = 10);
  type tb_structure is table of t_structure_customer%rowtype;
  rd_structure tb_structure;

  n_visit number := 0;
  n_office number := 0;

  n_commit_count number := 0;
begin
  open c;
  loop
    fetch c bulk collect into rd_structure limit 500; -- PL/SQL引擎会向SQL引擎发送 10 次请求. 最终跑完耗时3分钟左右(下面的select可以再优化成只查询一次？？？)
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
    n_commit_count := n_commit_count + 1;
    dbms_output.put_line(n_commit_count);

    exit when c%notfound;
  end loop;
  close c;
end;
```

### Oracle执行计划(Explain Plan) [^1]

- 在PL/SQL的`Explain plan window`中执行并查看
- sqlplus下执行
    - `explain plan for select * from emp;` 创建执行计划
    - `select * from table(dbms_xplan.display);` 查看执行计划

#### 案例一: 添加索引

- 功能点：使用条件查询, 查询场存
- 优化前基本查询不出来, 且经常导致数据库服务器CPU飙高。优化后查询时间1秒不到。优化方式：添加索引
- sql语句如下

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
- PL/SQL Explain执行情况

![oracle-explain-yard1](/data/images/db/oracle-explain-yard1.png)

- 分析：表`YCROSS_IN_OUT_REGIST`(进出场记录)和`YCROSS_STORAGE`(场存)是进行内联循环(`NESTED LOOPS`)连接的，而在查询`YCROSS_STORAGE`的时候消耗资源值(`Cost`)为 2758(查询堆位等基础表消耗资源基本可忽略)。而场存和进出场记录进行关联是通过`in_out_regist_id`字段关联。尝试给`YCROSS_STORAGE`表添加外键`create index index_in_out_regist_id on ycross_storage(in_out_regist_id);`后，查询效率得到明显改善

#### 案例二: 改写sql

- 功能点: 道口获取有效的计划
- sql语句

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

- 原始Explain执行情况

![oracle-explain-yard2](/data/images/db/oracle-explain-yard2.png)

- 修改1的Explain执行情况

![oracle-explain-yard3](/data/images/db/oracle-explain-yard3.png)

- 修改2的Explain执行情况

![oracle-explain-yard4](/data/images/db/oracle-explain-yard4.png)

- 分析：从上述执行情况可见
    - 原始查询(执行时间1.2秒左右)
        - 逻辑：先根据计划编号分组统计进出场记录中每个计划的实际完成条数(actual_cont_num)和最近执行计划时间(lately_input_tm)，然后将此子查询关联到`YCAMA_PLAN_YARD_NUM`(计划表)中
        - Explain: 进行了两次`YCROSS_IN_OUT_REGIST`(进出场记录)的全表查询(`TABLE ACCESS FULL`)，并且在最后进行distinct去重(执行策略`HASH UNIQUE`)时消耗了很多资源(???)
    - 修改1(执行时间0.6秒左右)
        - 逻辑：直接关联子表进出场记录YCROSS_IN_OUT_REGIST，此时通过开窗函数提取YCROSS_IN_OUT_REGIST的字段。然后在最外层套一个查询进行条件过滤
        - Explain: 资源全部用在YCROSS_IN_OUT_REGIST的全表查询上，去重基本无消耗(???)
    - 修改2(执行时间1.2秒左右)
        - 说明: 由于修改1对线上环境改动较大，尝试此写法发现Explain显示资源消耗明细降低，但是实际执行时间并没有多大改善。(然并卵)
        - 逻辑：先子查询中通过开窗函数得到YCAMA_PLAN_YARD_NUM的时间完成条数和最近执行时间，然后关联到YCAMA_PLAN_YARD_NUM中
        - Explain: 开窗函数消耗较多资源，去重基本无消耗(???)
- 由于上述资源消耗主要在YCAMA_PLAN_YARD_NUM和YCROSS_IN_OUT_REGIST的关联上，因此给YCROSS_IN_OUT_REGIST添加索引`create index index_plan_yard_num_id on ycross_in_out_regist(plan_yard_num_id);`。添加索引后Explain显示都有明显改善，实际执行时间：1.2秒(原始)、0.3秒(原始)、0.3秒(原始)
    
    - 原始Explain执行情况(添加索引后)

    ![oracle-explain-yard5](/data/images/db/oracle-explain-yard5.png)

    - 修改1的Explain执行情况(添加索引后)

    ![oracle-explain-yard6](/data/images/db/oracle-explain-yard6.png)

    - 修改2的Explain执行情况(添加索引后，最后的表关联策略由`HASH JOIN OUTER`变为`NESTED LOOPS`)

    ![oracle-explain-yard7](/data/images/db/oracle-explain-yard7.png)

## SQL Server

```sql
SET SHOWPLAN_ALL ON; -- 开启执行计划展示，开启后再运行sql语句
SET SHOWPLAN_ALL OFF; -- 关闭执行计划展示
```



---

参考文章

[^1]: http://www.cnblogs.com/xqzt/p/4467867.html (Oracle 执行计划)
[^2]: https://www.cnblogs.com/zgz21/p/5864298.html (oracle for loop循环以及游标循环)
[^3]: https://www.cnblogs.com/hellokitty1/p/4584333.html (Oracle数据库之FORALL与BULK COLLECT语句)
[^4]: https://www.cnblogs.com/wishyouhappy/p/3681771.html (oracle索引)
[^5]: https://www.cnblogs.com/zhanjindong/p/3439042.html
[^6]: https://www.cnblogs.com/gomysql/p/3615897.html
[^7]: https://www.cnblogs.com/rainwang/p/12123310.html

