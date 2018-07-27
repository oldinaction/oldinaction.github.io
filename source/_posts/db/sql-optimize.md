---
layout: "post"
title: "SQL优化"
date: "2018-07-27 14:58"
categories: [db]
tags: [oracle, dba, sql]
---

> 如无特殊说明，此文测试环境均为 Oracle 11.2g

## 索引

- https://www.cnblogs.com/wishyouhappy/p/3681771.html
- 索引在逻辑上和物理上都与相关的表和数据无关，当创建或者删除一个索引时，不会影响基本的表。Oracle在创建时会做相应操作，因此创建后就会看到效果

## SQL优化

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
          left join t_customer_contact cc
            on cc.customer_id = t.id
           and (cc.tel_no is not null or cc.cellphone is not null)
         group by t.customer_name_cn
        having count(cc.id) = 0) -- 此处还无法使用上面定义的 counts
```

## 批量更新优化

- `update`语句比较耗资源，测试一条update语句修改2万条数据(总共18万条数据的表，查询出这2万条很快)，运行时间太长，基本不可行。
  - 使用pl/sql里面的Test Window(可进行调试)写循环更新，2万条更新耗时0.7s。如果数据量再大一些可以分批commit

## Oracle执行计划(Explain Plan)

- http://www.cnblogs.com/xqzt/p/4467867.html

### 案例一: 添加索引

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

### 案例二: 改写sql

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

