---
layout: "post"
title: "sql进阶"
date: "2017-09-30 12:51"
categories: db
tags: [sql, oracle, mysql]
---

## 常用函数

### 基本原则

- mysql书写顺序和执行顺序都是按照`select-from-where-group by-having-order by-limit`进行的
- MySQL中子结果集必须使用别名，而Oracle中不需要特意加别名

- grouping、rollup：http://blog.csdn.net/damenggege123/article/details/38794351

### 常用函数

- `decode(被判断表达式, 值1, 转换成值01, 值2, 转换成值02, ..., 转换成默认值)` 只能判断=，不能判断like
  - `select decode(length(ys.ycross_x), 1, '0' || ys.ycross_x, ys.ycross_x) from ycross_storage ys` 如果ys.ycross_x的长度为1那就在前面加0，否则取本身
  - `select sum(decode(shipcomp.company_num, 'CMA', 1, 0)) cma, sum(decode(shipcomp.company_num, 'MSK', 1, 0)) msk from ycross_in_out_regist yior ...(省略和shipcomp的关联)` 统计进出场记录中cma和msk的数量
  - `order by decode(col, 'b', 1, 'c', 2, 'a', 3, col)` 按值排序
- `case when else end` 比decode强大
  - `case when t.name = 'admin' then 'admin' when t.name like 'admin%' then 'admin_user' else decode(t.role, 'admin', 'admin', 'admin_user') end`
  - `sum(case when yior.plan_classification_code = 'Empty_Temporary_Fall_Into_Play' and yardparty.company_num = 'DW1' then 1 end) as count_dw1` sum写在case里面则需要对相关字段group by. **主要用于分组之后根据条件分列显示**

### 聚合函数

- `count(*)`、`count(1)`、`count(id)`、`count(name)` **统计行数，不能统计值的个数**。如果有3行，但是只有name的值只有2个结果仍然为3
- `wm_concat` **行转列，会把多行转成1行** (默认用","分割，select的其他字段需要是group by字段)
    - `select replace(wm_concat(name), ',', '|') from test;`替换分割符

### 分析函数

- 分析函数和聚合函数的不同之处是什么：普通的聚合函数用group by分组，每个分组返回一个统计值，而分析函数采用partition by分组，并且**每组每行都可以返回一个统计值**(一般用于取子表字段) [^1]
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
            -- 见图一：窗口默认为整个组
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno) from emp;
            -- 见图二：窗口默认为第一行到当前行
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno order by sal desc) from emp;
            ```

            ![图一](/data/images/db/oracle-over-1.png)
            
            ![图二](/data/images/db/oracle-over-2.png)

    - 两个`order by`的执行时机
        - 两者一致：如果sql语句中的order by满足分析函数分析时要求的排序，那么sql语句中的排序将先执行，分析函数在分析时就不必再排序
        - 两者不一致：如果sql语句中的order by不满足分析函数分析时要求的排序，那么sql语句中的排序将最后在分析函数分析结束后执行排序
- 常见分析函数 [^3]
    - `max()`、`min()`、`sum()`、`avg()`
    - `first_value(字段名)`、`last_value(字段名)`
    - `rank()`、`dense_rank()`、`row_number()`：为每条记录产生一个从1开始至n的自然数，n的值可能小于等于记录的总数。这3个函数的唯一区别在于当碰到相同数据时的排名策略。
        - `row_number` 当碰到相同数据时，排名按照记录集中记录的顺序依次递增 
        - `dense_rank` 当碰到相同数据时，此时所有相同数据的排名都是一样的
        - `rank` 当碰到相同的数据时，此时所有相同数据的排名是一样的，同时会在最后一条相同记录和下一条不同记录的排名之间空出排名
    - `lag()`、`lead()` 求之前或之后的第N行。lag和lead函数可以在一次查询中取出同一字段的前n行的数据和后n行的值。（这种操作可以使用对相同表的表连接来实现，不过使用lag和lead有更高的效率）
        - lag(列名, 偏移的offset, 超出记录窗口时的默认值)
    - `rollup()`、`cube()` 排列组合分组
        - `group by rollup(a, b, c)`：首先会对(a、b、c)进行group by，然后再对(a、b)进行group by，其后再对(a)进行group by，最后对全表进行汇总操作
        - `group by cube(a, b, c)`：  首先会对(a、b、c)进行group by，然后依次是(a、b)，(a、c)，(a)，(b、c)，(b)，(c)，最后对全表进行汇总操作

```sql
-- 查询场存，并获取每个场存需要移动的次数和最早一次移动计划的id
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

### 正则表达式

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

### 其他

- 查找中文：`select * from t_customer t where asciistr(t.customer_name) like '%\%' and instr(t.customer_name, '\') <= 0;`

## 数据库数据更新

#### 更新表

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

## 自定义函数

- 解析json： https://blog.csdn.net/cyzshenzhen/article/details/17074543
  - select pkg_common.FUNC_PARSEJSON_BYKEY('{"name": "smalle", "age": "18"}', 'name') from dual; 取不到age?

### 字符串分割函数

#### 使用正则
```sql
-- 基于,分割，返回3行数据
select regexp_substr('17,20,23', '[^,]+', 1, level, 'i') as str from dual
  connect by level <= length('17,20,23') - length(regexp_replace('17,20,23', ',', '')) + 1;
```

#### 使用自定义函数

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

## Oracle中DBlink实现跨实例查询

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

## Oracle定时任务Job

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