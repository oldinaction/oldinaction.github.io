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

- grouping、rollup：http://blog.csdn.net/damenggege123/article/details/38794351

## 常用函数

- `decode(被判断表达式, 值1, 转换成值01, 值2, 转换成值02, ..., 转换成默认值)` 只能判断=，不能判断like
  - `select decode(length(ys.ycross_x), 1, '0' || ys.ycross_x, ys.ycross_x) from ycross_storage ys` 如果ys.ycross_x的长度为1那就在前面加0，否则取本身
  - `select sum(decode(shipcomp.company_num, 'CMA', 1, 0)) cma, sum(decode(shipcomp.company_num, 'MSK', 1, 0)) msk from ycross_in_out_regist yior ...(省略和shipcomp的关联)` 统计进出场记录中cma和msk的数量
  - `order by decode(col, 'b', 1, 'c', 2, 'a', 3, col)` 按值排序
- `case when else end` 比decode强大
  - `case when t.name = 'admin' then 'admin' when t.name like 'admin%' then 'admin_user' else decode(t.role, 'admin', 'admin', 'admin_user') end`
  - `sum(case when yior.plan_classification_code = 'Empty_Temporary_Fall_Into_Play' and yardparty.company_num = 'DW1' then 1 end) as count_dw1` sum写在case里面则需要对相关字段group by. **主要用于分组之后根据条件分列显示**

## 聚合函数

- `count(*)`、`count(1)`、`count(id)`、`count(name)` **统计行数，不能统计值的个数**。如果有3行，但是只有name的值只有2个结果仍然为3
- `wm_concat` **行转列，会把多行转成1行** (默认用","分割，select的其他字段需要是group by字段)
    - `select replace(wm_concat(name), ',', '|') from test;`替换分割符

## 分析函数

- 分析函数和聚合函数的不同之处是什么：普通的聚合函数用group by分组，每个分组返回一个统计值，而分析函数采用partition by分组，并且每组每行都可以返回一个统计值 [^1]
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
    - 省略窗口字句：
        - 出现`order by`子句的时候，不一定要有窗口子句
        - 此时窗口默认是当前组的第一行到当前行(unbounded preceding and current row)
    - 省略分组字句：则把全部记录当成一个组
        - 如果存在`order by`则窗口默认同上，即当前组的第一行到当前行
        - 如果这时省略`order by`则窗口默认为整个组(unbounded preceding and unbounded following)
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
          from ycross_storage ys
          left join yyard_venue_move_plan yvmp
            on yvmp.storage_id = ys.id
           and yvmp.yes_status = 0) t
 group by t.id, t.total, t.first_id
```

## 其他



## 自定义函数

### 字符串分割函数

- 创建字符串数组类型：`create or replace type sm_type_arr_str is table of varchar2 (60);` (一个数组，每个元素是varchar2 (60))
- 创建自定义函数`sm_split`

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
- 查询示例：`select * from table (cast (sm_split ('aa,,bb,cc,,', ',') as sm_type_arr_str));` 结果如下：

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











---

参考文章

[^1]: [分析函数1](http://www.cnblogs.com/linjiqin/archive/2012/04/04/2431975.html)
[^2]: [分析函数2](http://www.cnblogs.com/linjiqin/archive/2012/04/05/2433633.html)
[^3]: [分析函数3](http://www.cnblogs.com/linjiqin/archive/2012/04/06/2434806.html)