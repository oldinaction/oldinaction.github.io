---
layout: "post"
title: "SQL优化"
date: "2018-07-27 14:58"
categories: [db]
tags: [oracle, dba, sql]
---


## 总结

- 比如统计用户的点击情况，根据用户年龄分两种情况，年龄小于10岁或大于50岁的一次点击算作2，其他年龄段的一次点击算作1(实际情况可能更复杂)。如果在where条件中使用or可能会导致查询很慢，此时可以考虑查询出所有用户、年龄类别、点击次数，再在外层套一层查询通过case when进行合计

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

## Mysql

### explain说明 [^5]

- explain查看执行计划。如`explain select * from t_test;`，返回字段如：id、select_type、table、type、possible_keys、key、key_len、ref、rows、Extra
  - id：id越大的语句越先执行
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

### SQL Server

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
