---
layout: "post"
title: "sql进阶"
date: "2017-09-30 12:51"
categories: db
tags: [sql, oracle, mysql]
---

## 基本原则

- mysql书写顺序和执行顺序都是按照`select-from-where-group by-having-order by-limit`进行的
- MySQL中子结果集必须使用别名，而Oracle中不需要特意加别名

## Mysql

### 常见问题

- 查询空格问题。`select * from test t where t.name = 'ABC';`和`select * from test t where t.name = 'ABC  ';`(后面有空格)结果一致，`ABC`可以查询到数据库中`ABC  `的，`ABC  `也可以查询到数据库中`ABC`的数据
  - 使用like：`select * from test t where t.name like 'ABC';`(不要加%，**使用`mybatis-plus`插件可开启字符串like查询**)
  - 使用关键字 binary：`select * from test t where t.name = binary'ABC';`
  - 使用length：`select * from test t where t.name = 'ABC' and length(t.name) = length('ABC');`

## Oracle

### 常用函数

#### 常用函数

- `decode(被判断表达式, 值1, 转换成值01, 值2, 转换成值02, ..., 转换成默认值)` 只能判断=，不能判断like(like可考虑case when)
  - `select decode(length(ys.ycross_x), 1, '0' || ys.ycross_x, ys.ycross_x) from ycross_storage ys` 如果ys.ycross_x的长度为1那就在前面加0，否则取本身
  - `select sum(decode(shipcomp.company_num, 'CMA', 1, 0)) cma, sum(decode(shipcomp.company_num, 'MSK', 1, 0)) msk from ycross_in_out_regist yior ...(省略和shipcomp的关联)` 统计进出场记录中cma和msk的数量
  - `order by decode(col, 'b', 1, 'c', 2, 'a', 3, col)` 按值排序
- `case when then [when then ...] else end` 比decode强大
  - `case when t.name = 'admin' then 'admin' when t.name like 'admin%' then 'admin_user' else decode(t.role, 'admin', 'admin', 'admin_user') end`
  - `sum(case when yior.plan_classification_code = 'Empty_Temporary_Fall_Into_Play' and yardparty.company_num = 'DW1' then 1 end) as count_dw1` sum写在case里面则需要对相关字段group by. **主要用于分组之后根据条件分列显示**

#### 聚合函数(aggregate_function)

- `min`、 `max`、`sum`、`avg`、`count`、`variance`、`stddev` 
- `count(*)`、`count(1)`、`count(id)`、`count(name)` **统计行数，不能统计值的个数**。如果有3行，但是只有name的值只有2个结果仍然为3
- `wm_concat` **行转列，会把多行转成1行** (默认用`,`分割，select的其他字段需要是group by字段)
    - 自从oracle **`11.2.0.3`** 开始`wm_concat`返回的是clob字段，需要通过to_char转换成varchar类型 [^8]
    - `select replace(to_char(wm_concat(name)), ',', '|') from test;`替换分割符

#### 其他函数

- grouping、rollup：http://blog.csdn.net/damenggege123/article/details/38794351
- `trunc` oracle时间处理
    
    ```sql
    select trunc(sysdate-1, 'dd'), trunc(sysdate, 'dd') from dual; -- 返回昨天和今天（2018-01-01, 2018-01-02）
    ```
- `start with connect by prior` oracle递归查询(树形结构)

    ```sql
    select * from my_table t 
    start with t.pid = 1 -- 基于此条件进行向下查询(省略则表示基于全表为根节点向下查询，可能会有重复数据)
    connect by nocycle prior t.id = t.pid -- 递归条件(递归查询不支持环形。此处nocycle表示忽略环，如果确认结构中无环形则可省略。有环形则必须加，否则报错)
    where t.valid_status = 1; -- 将递归获取到的数据再次过滤
    ```

#### 分析函数

##### 常见分析函数 [^3]

- `min`、 `max`、`sum`、`avg` **一般和over/keep函数联合使用**
- `first_value(字段名)`、`last_value(字段名)` **和over函数联合使用**
- `row_number()`、`dense_rank()`、`rank()`：为每条记录产生一个从1开始至n的自然数，n的值可能小于等于记录的总数(基于相应order by字段的值来判断)。这3个函数的唯一区别在于当碰到相同数据时的排名策略。**和over函数联合使用**
    - `row_number` 当碰到相同数据时，排名按照记录集中记录的顺序依次递增(如：1-2-3-4-5-6)
    - `dense_rank` 当碰到相同数据时，此时所有相同数据的排名都是一样的(如：1-2-3-3-3-4. **如果被排序字段的值相等则认为排名相同**)
    - `rank` 当碰到相同的数据时，此时所有相同数据的排名是一样的，同时会在最后一条相同记录和下一条不同记录的排名之间空出排名(如：1-2-3-3-3-6)
- `lag()`、`lead()` 求之前或之后的第N行。lag和lead函数可以在一次查询中取出同一字段的前n行的数据和后n行的值。这种操作可以使用对相同表的表连接来实现，不过使用lag和lead有更高的效率。**和over函数联合使用**
    - lag(列名, 偏移的offset, 超出记录窗口时的默认值)
- `rollup()`、`cube()` 排列组合分组。**和group by联合使用**
    - `group by rollup(a, b, c)`：首先会对(a、b、c)进行group by，然后再对(a、b)进行group by，其后再对(a)进行group by，最后对全表进行汇总操作
    - `group by cube(a, b, c)`：  首先会对(a、b、c)进行group by，然后依次是(a、b)，(a、c)，(a)，(b、c)，(b)，(c)，最后对全表进行汇总操作

##### over

- 分析函数和聚合函数的不同之处是什么：普通的聚合函数用group by分组，**每个分组返回一个统计值**，而分析函数采用partition by分组，并且 **每组每行都可以返回一个统计值** [^1]
- 开窗函数`over()`，跟在分析函数之后，包含三个分析子句。形式如：`over(partition by xxx order by yyy rows between aaa and bbb)` [^2] 
    - 子句类型
        - 分组(partition by)
        - 排序(order by)
        - 窗口(rows)：窗口子句包含rows、range和滑动窗口
            - 窗口子句不能单独出现，必须有`order by`子句时才能出现
            - 取值说明
                - `unbounded preceding` 第一行
                - `current row` 当前行
                - `unbounded following` 最后一行
    - 省略分组字句：则把全部记录当成一个组
        - 如果此时存在`order by`，则窗口默认(省略窗口时)为当前组的第一行到当前行(unbounded preceding and current row)
        - 如果此时不存在`order by`，则窗口默认为整个组(unbounded preceding and unbounded following)
    - 省略窗口字句
        - 出现`order by`子句的时候，不一定要有窗口子句(窗口子句不能单独出现，必须有`order by`子句时才能出现)
        - 如果此时存在`order by`，则窗口默认是当前组的第一行到当前行
        - 如果此时不存在`order by`，则窗口默认是整个组
        - 示例（示例和图片来源：http://www.cnblogs.com/linjiqin/archive/2012/04/05/2433633.html）
            
            ```sql
            -- 见图oracle-over-1：窗口默认为整个组
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno) from emp;
            -- 见图oracle-over-2：窗口默认为第一行到当前行
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno order by sal desc) from emp;
            ```

            - oracle-over-1
              
              ![oracle-over-1](/data/images/db/oracle-over-1.png)
            
            - oracle-over-2
            
              ![oracle-over-2](/data/images/db/oracle-over-2.png)

    - 两个`order by`的执行时机
        - 两者一致：如果sql语句中的order by满足分析函数分析时要求的排序，那么sql语句中的排序将先执行，分析函数在分析时就不必再排序
        - 两者不一致：如果sql语句中的order by不满足分析函数分析时要求的排序，那么sql语句中的排序将最后在分析函数分析结束后执行排序
- 使用示例

```sql
-- 查询有移动任务的场存，并获取每个场存需要移动的次数和最早一次移动计划的id
select *
  from (select ys.id
               ,count(yvmp.venue_move_plan_id) over(partition by ys.id) as total
               ,first_value(yvmp.venue_move_plan_id) over(partition by yvmp.storage_id order by yvmp.input_tm ASC rows between unbounded preceding and unbounded following) as first_id
          from ycross_storage ys -- 场存表
          left join yyard_venue_move_plan yvmp -- 移动表
            on yvmp.storage_id = ys.id
           and yvmp.yes_status = 0) t
 group by t.id, t.total, t.first_id
```

###### over使用误区

- 主表行数并不会减少(普通的聚合函数用group by分组，**每个分组返回一个统计值**，而分析函数采用partition by分组，并且**每组每行都可以返回一个统计值**
    - 查询每个客户每种拜访类型最近的一次拜访

        ```sql
        -- ========= 原始数据
        -- 原始拜访表数据(部分)
        select v.id, v.visit_type, v.customer_id, v.comments, v.visit_tm
        from t_visit v 
        where v.result is not null and v.valid_status = 1 
        and v.customer_id = 358330
        order by v.visit_type, v.id desc;
        -- 结果
        #   
        1	93179	BS	358330	BS-3	2018/9/20
        2	93165	BS	358330	BS-2	2018/9/21
        3	93164	BS	358330	BS-1	2018/9/21
        4	93252	IS	358330	IS-2	2018/10/8
        5	27094	IS	358330	IS-1	2017/11/9

        -- ========= 统计语句
        -- 错误sql一。(和group by混淆)
        select
        row_number() over(partition by v.customer_id, v.visit_type order by v.id desc) as rn
        ,first_value(v.id) over(partition by v.customer_id, v.visit_type order by v.id desc) as id -- 只取一个ID也是重复的
        ,first_value(v.customer_id) over(partition by v.customer_id, v.visit_type order by v.id desc) as customer_id
        ,first_value(v.visit_type) over(partition by v.customer_id, v.visit_type order by v.id desc) as visit_type
        ,first_value(v.comments) over(partition by v.customer_id, v.visit_type order by v.id desc) as comments
        ,first_value(v.visit_tm) over(partition by v.customer_id, v.visit_type order by v.id desc) as visit_tm
        from t_visit v
        where v.valid_status = 1 and v.result is not null 
        and v.customer_id = 358330;
        -- 结果
        #   
        1	1	93179	358330	BS	BS-3	2018/9/20
        2	2	93179	358330	BS	BS-3	2018/9/20
        3	3	93179	358330	BS	BS-3	2018/9/20
        4	1	93252	358330	IS	IS-2	2018/10/8
        5	2	93252	358330	IS	IS-2	2018/10/8
        
        -- 错误sql二。此时报max(v.id)中的id不是group by字句（使用keep的话也会有这个错）
        select
        max(v.id) over(partition by v.customer_id, v.visit_type order by v.id desc) as id -- max(v.id)：ORA-00979 not a group by expression
        from t_visit v
        where v.valid_status = 1 and v.result is not null 
        and v.customer_id = 358330
        group by v.customer_id, v.visit_type

        -- 可再次group by；或者使用row_number()再加子查询rn=1获取最大最小值

        -- =============== 使用 Keep ===============
        -- Keep测试一(基于主表group by)
        select
        v.customer_id, v.visit_type
        ,max(v.id) keep(dense_rank first order by v.visit_tm desc) as id -- 在每一组中按照v.visit_tm排序计数(BS那一组排序值为 1-1-2)，并取第一排序集(1-1)中v.id最大的
        ,max(v.visit_tm) keep(dense_rank first order by v.visit_tm desc) as visit_tm
        ,max(v.comments) keep(dense_rank first order by v.visit_tm desc) as comments
        ,max(v.visit_tm) keep(dense_rank first order by v.id desc) as visit_tm_id -- 排序值为 1-2-3
        from t_visit v
        where v.valid_status = 1 and v.result is not null 
        and v.customer_id = 358330
        group by v.customer_id, v.visit_type; -- 先分成了两组(最终只有两组的统计值，两行数据)
        -- 结果(注意第一行数据)
        #
        1	358330	BS	93165	2018/9/21	BS-2	2018/9/20
        2	358330	IS	93252	2018/10/8	IS-2	2018/10/8

        -- Keep测试二(基于over的partition by)。参考下文【Keep】
        ```
##### keep [^6]

- keep的用法不同于通过over关键字指定的分析函数，可以用于这样一种场合下：取同一个分组下以某个字段排序后，对指定字段取最小或最大的那个值。从这个前提出发，我们可以看到其实这个目标通过一般的row_number分析函数也可以实现，即指定rn=1。但是，该函数无法实现同时获取最大和最小值。或者说用first_value和last_value，结合row_number实现，但是该种方式需要多次使用分析函数，而且还需要套一层SQL。于是出现了keep
- 语法 [^5]

    ```sql
    aggregate_function -- 聚合函数
    KEEP (
        DENSE_RANK { FIRST | LAST } 
        ORDER BY expr [ DESC | ASC ] [ NULLS { FIRST | LAST } ] [, expr [ DESC | ASC ] [ NULLS { FIRST | LAST } ]]...
    ) 
    [ OVER ( [query_partition_clause] ) ]
    ```
    - 最前是聚合函数，可以是min、max、avg、sum
    - dense_rank first，dense_rank last为keep函数的保留属性。表示分组、排序结果集(dense_rank的值)中第一个(dense_rank值排第一的，可能有几行数据排序值一样)、最后一个
- Keep测试一(基于主表group by)：参考上述【over使用误区】
- Keep测试二(基于over的partition by)。测试代码和分析如下

  ```sql
  -- 查询每个客户的默认地址：t_customer数据条数 28.9w, t_customer_address数据条数 36.8w。(注：此测试实际场景为两张表除了主键，无其他外键和索引)
  select tmp_page.*, rownum row_id from ( -- 分页
    select t.* from ( -- 写法 2
      select c.customer_name_cn
        --,ca.address -- 写法 1
        ,max(ca.address) keep(dense_rank first order by decode(ca.address_type, 'Default', 1, 2)) over(partition by c.id) as address -- 写法 2
      from t_customer c
      left join t_customer_address ca on ca.valid_status = 1 and c.id = ca.customer_id -- 写法 2
      /*  -- 写法 1
      -- 也曾尝试把子查询视图管理再主查询where之后（将主查询包裹一层再和此子查询关联），没有任何改观
      left join (select ca.customer_id,
                  -- 需要根据客户地址类型排序，是导致子查询效率低的重要原因
                  max(ca.address) keep(dense_rank first order by decode(ca.address_type, 'Default', 1, 2)) as address
                from t_customer_address ca
                -- 写法1优化：通过查询主表(条件过滤之后会很少)在子查询内部过滤，主查询条件如果很多则所有的条件都需要写两遍，烦杂
                --join t_customer c on c.id = ca.customer_id and c.valid_status = 1
                where ca.valid_status = 1
                group by ca.customer_id) ca 
          on ca.customer_id = c.id
      */
      where c.valid_status = 1 -- and c.customer_name_cn = 'XXX有限公司' -- 只有一条此数据。加上次条件后写法1的分页需要 10s，写法2的分页只需 0.09s 
    ) t group by t.customer_name_cn, t.address -- 写法 2（去重。此处必须套一层select去重。在里面加group by，语法层面ca.address、ca.address_type、ca.id都需要在group by字句中，则起不到去重效果）
  ) tmp_page where rownum <= 20 -- 分页
  ```

  - 写法 1
    - 不使用分页执行计划。耗时 **3.5s** (PL/SQL自动分页显示20行) 
      
      ![oracle-keep-1](/data/images/db/oracle-keep-1.png)

    - 使用分页执行计划。耗时 **4.2s** (为什么分页导致效率变低？？？)

      ![oracle-keep-2](/data/images/db/oracle-keep-2.png)

  - 写法 2
    - 不使用分页执行计划。耗时 **0.8s** (PL/SQL自动分页显示20行) 
      
      ![oracle-keep-3](/data/images/db/oracle-keep-3.png)

    - 使用分页执行计划。耗时 **0.7s**

      ![oracle-keep-4](/data/images/db/oracle-keep-4.png)
  - 扩展测试
    - 测试1：如上述sql注释，在主查询的where处加`and c.customer_name_cn = 'XXX有限公司'`，这样查询理论上只有一条此数据。加上次条件后写法1的分页需要 10s，写法2的分页只需 0.09s
    - 测试2：此时查询主表(t_customer)数据条数28.9w,，曾测试查询主表只有2条数据(额外关联了几张较小的字段表)。写法1分页查询耗时 20s，写法2耗时 0.1s
  - 关于子查询 [^7]
    - 标准子查询：子查询先于主查询独立执行，返回明确结果供主查询使用。一般常见于where字句，且子查询返回一行/多上固定值(子查询中未使用主查询字段)
    - 相关子查询：子查询不能提前运行以得到明确结果。一般常见于select字句、where字句(子查询中使用了主查询字段，如常用的exists)
    - 此案例写法1使用子查询，不管子查询写在何处都需要子查询先返回一个视图，再供主查询调用。从而在获取子查询时必须全表扫描并排序
  - **keep和over联用，即可以查询子表最值，关联子表导致数据重复仍需group by去重**

##### rollup、cube、grouping 小计、合计

- 结合group by获取小计、合计值
https://www.cnblogs.com/mumulin99/p/9837522.html

#### 正则表达式

- 正则函数
  - `regexp_like()` 返回满足条件的字段
  - `regexp_instr()` 返回满足条件的字符或字符串的位置
  - `regexp_replace()` 返回替换后的字符串
  - `regexp_substr()` 返回满足条件的字符或字符串
- `regexp_substr(str, pattern[,start[,occurrence[match_option]]])` 参数说明
  - str 待匹配的字符串
  - pattern 正则表达式元字符构成的匹配模式
  - start 开始匹配位置，如果不指定默认为1(第一个字符串)
  - occurrence 匹配的次数，如果不指定，默认为1
  - match_option 意义同regexp_like的一样

```sql
-- 分割函数：基于,分割，返回3行数据
select regexp_substr('17,20,23', '[^,]+', 1, level, 'i') as str from dual
  connect by level <= length('17,20,23') - length(regexp_replace('17,20,23', ',', '')) + 1;

-- 返回
select regexp_instr('17,20,23', ',') from dual; -- 返回3
select regexp_instr('17,20,23', ',', 1, 2) from dual; -- 返回6
select regexp_instr('17,20,23', ',', 1, 3) from dual; -- 返回0
select substr('17,20,23', 1, regexp_instr('17,20,23', ',') - 1) from dual;
select substr('17,20,23', regexp_instr('17,20,23', ',') + 1, regexp_instr('17,20,23', ',', 1, 2) - regexp_instr('17,20,23', ',') - 1) from dual;
select substr('17,20,23', regexp_instr('17,20,23', ',', 1, 2) + 1, length('17,20,23') - regexp_instr('17,20,23', ',')) from dual;
```

#### 其他

- 查找中文：`select * from t_customer t where asciistr(t.customer_name) like '%\%' and instr(t.customer_name, '\') <= 0;`

### 数据库数据更新

##### 更新表

- **`update set from where`** 将一张表的数据同步到另外一张表
    
    ```sql
    -- Oracle
    update a set (a1, a2, a3) = (select b1, b2, b3 from b where a.id = b.id) where exists (select 1  from b where a.id = b.id)
    -- Mysql
    update a, b set a1 = b1, a2 = b2, a3 = b3 where a.id = b.id
    ```

    - 实例

    ```sql
    -- (1)
    update ycross_storage ys
    set (ys.location_id, ys.ycross_x, ys.ycross_y, ys.box_type_id) =
        (select yls.location_id,
                sc.ycrossx,
                sc.ycrossy,
                (select ybts.id from yyard_box_type_set ybts where ybts.box_type = sc.relclcd) boxtypeid --也可以不取别名
            from yyard_location_set yls, sql_ctninfo sc -- sql_ctninfo为临时表
            where 1 = 1
            and yls.region_num = sc.regionnum
            and yls.set_num = sc.setnum
            and (select ypc.company_num
                    from ybase_party_company ypc
                    where ypc.party_id = yls.yard_party_id) = ('dw' || trim(sc.yardin))
            and yls.yes_status = 1
            and sc.isinvalid = 1
            and ys.box_number = sc.ctnno
            and ys.yes_storage = 1) -- 可以拿到update的表ycross_storage(再套一层子查询则无法拿到)，且不能关联进去，否则容易出现一对多错误
    where -- where只能拿到update的表(不能拿到form的)
    -- 除了set(里面)限制了需要更新的范围，where(外面)也需要限制
    exists (select 1 from sql_ctninfo sc where ys.box_number = sc.ctnno);

    -- (2)将重庆的数据重新设置其绑定IS为最新的一条拜访的IS
    update t_customer t
      set t.update_user_id = 3,
          t.update_tm = sysdate,
          t.lock_status = 1,
          (t.bind_is_user_id) =
          -- 通过子查询获取时 (select a.visit_user_id from (select v.visit_user_id from t_visit v where t.id = v.customer_id and v.valid_status = 1 order by v.visit_tm) a where rownum = 1) 拿不到t_customer的字段
          (select a.first_id
              from (select c.id,
                          first_value(v.visit_user_id) over(partition by v.customer_id order by v.visit_tm desc rows between unbounded preceding and unbounded following) as first_id
                      from t_customer c
                      left join t_visit v
                        on c.id = v.customer_id
                      and v.valid_status = 1) a
            where a.id = t.id
              and rownum = 1)
    where t.customer_region = '500000'
      and t.valid_status = 1
      and t.info_sure_status = 1
      -- 此处加exists ?
      and exists (select 1
              from t_visit v
            where v.customer_id = t.id
              and v.valid_status = 1)
    ```

### 自定义函数

- 解析json： https://blog.csdn.net/cyzshenzhen/article/details/17074543
  - select pkg_common.FUNC_PARSEJSON_BYKEY('{"name": "smalle", "age": "18"}', 'name') from dual; 取不到age?

#### 字符串分割函数

##### 使用正则

```sql
-- 基于,分割，返回3行数据
select regexp_substr('17,20,23', '[^,]+', 1, level, 'i') as str from dual
  connect by level <= length('17,20,23') - length(regexp_replace('17,20,23', ',', '')) + 1;
```

##### 使用自定义函数

- 1.创建字符串数组类型：`create or replace type sm_type_arr_str is table of varchar2 (60);` (一个数组，每个元素是varchar2 (60))
- 2.创建自定义函数`sm_split`

  ```sql
  create or replace function sm_split(p_str       in varchar2,
                                  p_delimiter in varchar2)
    return sm_type_arr_str
    pipelined is
    j    int := 0;
    i    int := 1;
    len  int := 0;
    len1 int := 0;
    str  varchar2(4000);
  begin
    len  := length(p_str);
    len1 := length(p_delimiter);

    while j < len loop
      j := instr(p_str, p_delimiter, i);

      if j = 0 then
        j   := len;
        str := substr(p_str, i);
        pipe row(str);
        if i >= len then
          exit;
        end if;
      else
        str := substr(p_str, i, j - i);
        i   := j + len1;
        pipe row(str);
      end if;
    end loop;

    return;
  end sm_split;
  ```
- 查询示例：`select * from table (cast (sm_split ('aa,,bb,cc,,', ',') as sm_type_arr_str));` (一定要加`as sm_type_arr_str`) 结果如下：

  ```html
    COLUMN_VALUE
  1	aa
  2
  3	bb
  4	cc
  5
  ```
- 示例二

  ```sql
  select t.*
    from test_table t
    where exists (select 1
            from table(cast(sm_split(t.name, ',') as sm_type_arr_str)) arr
            where trim(arr.column_value) = 'aa')
  ```

### Oracle中DBlink实现跨实例查询

```sql
-- 创建DBLINK
create public database link my_dblink
connect to smalle identified by smalle -- 需要连接的数据库信息
    using '(DESCRIPTION =
        (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.1.1)(PORT = 1521))
        )
        (CONNECT_DATA =
            (SERVICE_NAME = orcl)
        )
    )';

-- 删除
dblink drop public database link my_dblink;

-- 查询。后台调用mybatis支持oracle的@dblink使用，所以直接在xml文件中使用sql语句即可
select * from tbl_ost_notebook@my_dblink;
```

### Oracle定时任务Job

```sql
-- 查询
select * from dba_jobs; -- 还有all_jobs/user_jobs
-- 真正运行的job
select * from dba_jobs_running;

-- 操作job
declare
    job_id number;
begin
    -- （1）创建job
    -- sys用户下dbms_job包中的submit过程(方法)，sys可以省略
    -- 在dbms_job这个package中还有其他的过程：broken、change、interval、isubmit、next_date、remove(移除一个job)、run(立即运行一个job)、submit、user_export、what；
    sys.dbms_job.submit(
        job => :job_id, -- OUT，返回job_id（不能省略）
        what => 'my_proc_name;', -- 执行的存储过程名称，后面要带分号
        next_date => to_date('2018-06-15 10:00:00', 'yyyy-mm-dd hh24:mi:ss'), -- job的开始时间. 如果写成sysdate则提交后便会执行一次
        interval => 'sysdate+1/86400' -- job的运行频率。每天86400秒钟，即一秒钟运行my_proc_name过程一次
    );
    commit;

    -- 带参数执行job(每日凌晨零点执行)
    dbms_job.submit(job_id, 'declare username varchar2(200); begin my_proc_name(username, ''''); end;', sysdate, 'trunc(sysdate)+1'); 

    -- （2）比如某个job返回的id为888
    dbms_job.run(888); -- 立即运行一次888这个job
    dbms_job.remove(888); -- 移除888这个job
    commit;
end;
```

- 执行频率举例
    - 每天午夜12点 `interval => trunc(sysdate + 1)`
    - 每天早上8点30分 `interval => trunc(sysdate + 1) + (8*60+30)/(24*60)`
    - 每星期二中午12点 `interval => next_day(trunc(sysdate), 'tuesday') + 12/24`
    - 每个月第一天的午夜12点 `interval => trunc(last_day(sysdate) + 1)`
    - 每个季度最后一天的晚上11点 `interval => trunc(add_months(sysdate + 2/24, 3), 'q') -1/24`
    - 每星期六和日早上6点10分 `interval => trunc(least(next_day(sysdate, 'saturday'), next_day(sysdate, 'sunday'))) + (6×60+10)/(24×60)`
    - 每30秒执行次 `interval => sysdate + 30/(24 * 60 * 60)`
    - 每10分钟执行 `interval => trunc(sysdate, 'mi') + 10/(24*60)`
    - 每天的凌晨1点执行 `interval => trunc(sysdate) + 1 + 1/(24)`
    - 每周一凌晨1点执行 `interval => trunc(next_day(sysdate, '星期一'))+1/24`
    - 每月1日凌晨1点执行 `interval => trunc(last_day(sysdate))+1+1/24`
    - 每季度的第一天凌晨1点执行 `interval => trunc(add_months(sysdate, 3), 'q') + 1/24`
    - 每半年定时执行(7.1和1.1) `interval => add_months(trunc(sysdate, 'yyyy'),6)+1/24`
    - 每年定时执行 `interval => add_months(trunc(sysdate, 'yyyy'), 12)+1/24`



---

参考文章

[^1]: http://www.cnblogs.com/linjiqin/archive/2012/04/04/2431975.html (分析函数1)
[^2]: http://www.cnblogs.com/linjiqin/archive/2012/04/05/2433633.html (分析函数2)
[^3]: http://www.cnblogs.com/linjiqin/archive/2012/04/06/2434806.html (分析函数3)
[^4]: https://www.cnblogs.com/hoojo/p/oracle_procedure_job_interval.html (Oracle-job-procedure存储过程定时任务)
[^5]: https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions065.htm#SQLRF00641 (oracle doc: keep)
[^6]: https://lanjingling.github.io/2015/10/09/oracle-fenxihanshu-3/
[^7]: https://www.cnblogs.com/seven7seven/p/3662451.html
[^8]: https://www.smwenku.com/a/5b8dd9d82b71771883410ce1/ 