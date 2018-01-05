---
layout: "post"
title: "oracle-function"
date: "2017-09-30 12:51"
categories: [db]
tags: [oracle, function]
---

## 常用函数

- `decode(被判断表达式, 值1, 转换成值01, 值2, 转换成值02, ..., 转换成默认值)`
  - `select decode(length(ys.ycross_x), 1, '0' || ys.ycross_x, ys.ycross_x) from ycross_storage ys` 如果ys.ycross_x的长度只有1未就在前面加0，否则取本身

## 聚合函数

- `wm_concat` 行转列 (默认用","分割，select的其他字段需要是group by字段)
    - `select replace(wm_concat(name), ',', '|') from test;`替换分割符

## 分析函数 [^1] [^2] [^3]

- 分析函数和聚合函数的不同之处是什么：普通的聚合函数用group by分组，每个分组返回一个统计值，而分析函数采用partition by分组，并且每组每行都可以返回一个统计值
- 分析函数带有一个开窗函数`over()`，包含三个分析子句，形式如：`over(partition by xxx order by yyy rows between aaa and bbb)`
  - 分组(partition by)
  - 排序(order by)
  - 窗口(rows)：窗口子句包含rows方式的窗口，range方式和滑动窗口

```sql
-- 查询场存，并获取每个场存需要移动的次数和最早一次移动计划的id
select *
  from (select ys.id
               ,count(*) over(partition by ys.id) as total
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
[^1]: [分析函数1](http://www.cnblogs.com/linjiqin/archive/2012/04/04/2431975.html)
[^2]: [分析函数2](http://www.cnblogs.com/linjiqin/archive/2012/04/05/2433633.html)
[^3]: [分析函数3](http://www.cnblogs.com/linjiqin/archive/2012/04/06/2434806.html)