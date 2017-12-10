---
layout: "post"
title: "oracle-function"
date: "2017-09-30 12:51"
categories: [db]
tags: [oracle, function]
---

## 常用函数

## 聚合函数

## 其他

- `wm_concat`行转列(默认用","分割，select的其他字段需要是group by字段)
    - `select replace(wm_concat(name), ',', '|') from test;`替换分割符

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
