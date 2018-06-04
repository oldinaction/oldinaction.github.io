---
layout: "post"
title: "db-procedure"
date: "2017-08-24 20:33"
categories: [db]
tags: [oracle, mysql, procedure]
---

## 简介

- Mysql存储过程调试工具：`dbForge Studio for MySQL`

## Mysql存储过程示例

```sql
create definer = 'root'@'localhost'
procedure test.county(in `in_provid` int, in `in_urlid` int)
begin
  declare v_sql varchar(1000);
  declare c_cityid integer;
  declare c_cityname varchar(20);
  declare c_countyname varchar(20);
  declare c_cityid_tmp integer;

  # 是否未找到数据标记(要在游标之前定义)
  declare done int default false;

  -- 定义第一个游标
  declare cur1 cursor for
  select
    t.n_cityid,
    t.s_cityname
  from dict_city t
  where t.n_provid = in_provid;

  # 临时表游标
  declare cur2 cursor for
  select
    s_countyname,
    n_cityid as cityid
  from tmp_table;

  # 循环终止的标志，游标中如果没有数据就设置done为true(停止遍历)
  declare continue handler for not found set done = true;

  # 创建临时表
  drop table if exists tmp_table;
  create temporary table if not exists tmp_table (
    id int(11) not null auto_increment primary key,
    s_countyname varchar(20),
    n_cityid int(10)
  );

  # mysql不能直接变量结果集, 此出场将结果集放到临时表中, 用于后面变量
  open cur1;
  flag_loop: loop
    # 取出每条记录并赋值给相关变量，注意顺序
    # 变量的定义不要和你的select的列的键同名, 否则fetch into 会失败！
    fetch cur1 into c_cityid, c_cityname;

    # fetch之后, 如果没有数据则会运行set done = true
    if done then
      # 跳出循环
      leave flag_loop;
    end if;

    # 字符串截取，从第一位开始，截取2位
    set c_cityname = substring(c_cityname, 1, 2);

    # 动态sql执行后的结果记录集在mysql中无法获取，因此需要转变思路将其放置到一个临时表中
    # 动态sql需要使用concat(a, b, c, ....)拼接
    set v_sql = concat("insert into tmp_table(s_countyname, n_cityid) select t.`name`, ", c_cityid, " from sm_renthouse_url t where
    t.pid in (select p.id from sm_renthouse_url p where p.pid = ", in_urlid, " and p.`name` like '%", c_cityname, "%')");

    # 如果以@开头的变量可以不用通过declare语句事先声明
    set @v_sql = v_sql;
    # 预处理需要执行的动态sql，其中stmt是一个变量
    prepare stmt from @v_sql;
    # 执行sql语句
    execute stmt;
    # 释放掉预处理段
    deallocate prepare stmt;
  end loop;
  close cur1;

  # 调试输出, 打印使用select
  select
    *
  from tmp_table;

  # 还原终止的标志, 用于第二个游标
  set done = false;

  open cur2;
  flag_loop: loop
    fetch cur2 into c_countyname, c_cityid_tmp;
    if done then
      leave flag_loop;
    end if;

    insert into dict_county (s_countyname, n_cityid, s_state)
      values (c_countyname, c_cityid_tmp, '1');

  end loop;
  close cur2;

  # 删除临时表
  drop temporary table tmp_table;
end
```

## Oracle

### Oracle存储过程示例

```sql
  -- 定义
  create or replace procedure p_up_user_role is
    cursor c is 
      select t.* from user_login t; -- 游标
    china_id number;
  begin
    select t.id into china_id from t_structure t where t.structure_type_status = 1 and t.node_level = 6 and t.node_name = '中国'; --可能出现运行时异常：ORA-01403 no data found

    delete from user_login_security_group t where t.group_id = 'dw_dept_admin';
    --for循环不需要声明变量，会自动将user_item声明为record变量
    for user_item in c loop
        insert into user_login_security_group(user_login_id, group_id, from_date) 
              values(user_item.user_login_id, 'dw_dept_admin', '2017-11-01 00:00:00.000000');
    end loop;
    commit;
  end;

  -- 运行
  call p_up_user_role();

  -- 删除
  drop procedure p_up_user_role;
```

- 示例二（动态游标、异常处理）

  ```sql
  -- 创建错误日志表
  create table yimp_errorlog
  (
        id number primary key,
        errcode number,
        errmsg varchar2(1024),
        errdate date
  );
  create sequence seq_errorlog_id start with 1 increment by 1;

  -- 创建存储过程
  create or replace procedure p_up_storage is
    TYPE ref_cursor_type IS REF CURSOR; --定义一个游标类型(动态游标使用)

    cursor c is
      select yls.*
        from yyard_location_set yls, ybase_party_company ypc
      where ypc.party_id = yls.yard_party_id
        and ypc.company_num = 'DW1' 
        and yls.region_num in ('Y0');

    v_cur_storage ref_cursor_type; -- 动态游标
    v_storage     ycross_storage%ROWTYPE;
    v_sql         varchar2(1000);
    v_x           number := 1;
    v_y           number := 1;

    v_errcode number;
    v_errmsg  varchar2(1024);
  begin
    for loc in c loop
      v_errmsg := '[code]p_up_storage==>' || loc.YARD_PARTY_ID || '-' || loc.REGION_NUM || loc.SET_NUM;
      -- 更新此堆位下场存
      v_x := 1;
      v_y := 1;
    
      --使用连接符拼接成一条完整SQL
      v_sql := 'select * from ycross_storage t where t.yes_storage = 1 and t.location_id = ' ||
              loc.location_id;
      --打开游标
      open v_cur_storage for v_sql;
      loop
        fetch v_cur_storage into v_storage;
        exit when v_cur_storage%notfound; -- 跳出循环
        update ycross_storage t
          set t.ycross_x = v_x, t.ycross_y = v_y
        where t.id = v_storage.id;

        if v_y < 7 then
          v_y := v_y + 1;
        else
          if v_x < 30 then
            v_x := v_x + 1;
            v_y := 1;
          else
            raise_application_error(-20001, v_errmsg || '位置超出堆位结构'); -- 抛出异常
          end if;
        end if;
      end loop;
      close v_cur_storage;
    
    end loop;
    commit;
  exception
    -- 捕获异常
    when others then
      --WHEN excption_name THEN ...WHEN OTHERS THEN ...
      rollback;
      v_errcode := SQLCODE; --出错代码
      v_errmsg  := v_errmsg || ', [msg]' || SQLERRM; --出错信息
      insert into yimp_errorlog
      values
        (seq_errorlog_id.nextval, v_errcode, v_errmsg, sysdate);
      commit;
  end;
  ```

### 异常

- 抛出异常 `raise_application_error` 该函数是将应用程序专有的错误从服务器端转达到客户端应用程序(其他机器上的sqlplus或者前台开发语言)
  - `procedure raise_application_error(error_number_in in number, error_msg_in in varchar2);`
  - `error_number_in`: 自定义的错误码，容许从 -20000 到 -20999 之间，这样就不会与 oracle 的任何错误代码发生冲突。
  - `error_msg_in`: 长度不能超过 2k，否则截取 2k
- 在`[for...in...]loop...end loop`循环中捕捉异常，必须用`begin...end`包起来

  ```sql
  loop
    begin
    -- ...
    exception
      when others then dbms_output.put_line('出错'); -- 捕获异常后继续下一次循环
      -- when others then  null; -- 捕获异常后继续下一次循环
  end;
  ```

### oracle函数

```sql
  declare 
    i integer;
  begin
    dbms_output.put_line('hello world');
    p_up_user_role(); -- 调用上述存储过程
  end;
```




---

参考文章