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
CREATE DEFINER = 'root'@'localhost'
PROCEDURE test.county(IN `in_provid` int, IN `in_urlid` int)
BEGIN
  DECLARE v_sql varchar(1000);
  DECLARE c_cityid integer;
  DECLARE c_cityname varchar(20);
  DECLARE c_countyname varchar(20);
  DECLARE c_cityid_tmp integer;

  # 是否未找到数据标记(要在游标之前定义)
  DECLARE done INT DEFAULT FALSE;

  -- 定义第一个游标
  DECLARE cur1 CURSOR FOR
  SELECT
    t.N_CITYID,
    t.S_CITYNAME
  FROM dict_city t
  WHERE t.N_PROVID = in_provid;

  # 临时表游标
  DECLARE cur2 CURSOR FOR
  SELECT
    S_COUNTYNAME,
    N_CITYID AS cityid
  FROM tmp_table;

  # 循环终止的标志，游标中如果没有数据就设置done为TRUE(停止遍历)
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  # 创建临时表
  DROP TABLE IF EXISTS tmp_table;
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_table (
    ID int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    S_COUNTYNAME varchar(20),
    N_CITYID int(10)
  );

  # mysql不能直接变量结果集, 此出场将结果集放到临时表中, 用于后面变量
  OPEN cur1;
  flag_loop: LOOP
    # 取出每条记录并赋值给相关变量，注意顺序
    # 变量的定义不要和你的select的列的键同名, 否则fetch into 会失败！
    FETCH cur1 INTO c_cityid, c_cityname;

    # FETCH之后, 如果没有数据则会运行SET done = TRUE
    IF done THEN
      # 跳出循环
      LEAVE flag_loop;
    END IF;

    # 字符串截取，从第一位开始，截取2位
    SET c_cityname = SUBSTRING(c_cityname, 1, 2);

    # 动态sql执行后的结果记录集在MySQL中无法获取，因此需要转变思路将其放置到一个临时表中
    # 动态sql需要使用CONCAT(a, b, c, ....)拼接
    SET v_sql = CONCAT("insert into tmp_table(S_COUNTYNAME, N_CITYID) select t.`name`, ", c_cityid, " from sm_renthouse_url t where
    t.pid in (select p.id from sm_renthouse_url p where p.pid = ", in_urlid, " and p.`name` like '%", c_cityname, "%')");

    # 如果以@开头的变量可以不用通过declare语句事先声明
    SET @v_sql = v_sql;
    # 预处理需要执行的动态SQL，其中stmt是一个变量
    PREPARE stmt FROM @v_sql;
    # 执行SQL语句
    EXECUTE stmt;
    # 释放掉预处理段
    DEALLOCATE PREPARE stmt;
  END LOOP;
  CLOSE cur1;

  # 调试输出, 打印使用SELECT
  SELECT
    *
  FROM tmp_table;

  # 还原终止的标志, 用于第二个游标
  SET done = FALSE;

  OPEN cur2;
  flag_loop: LOOP
    FETCH cur2 INTO c_countyname, c_cityid_tmp;
    IF done THEN
      LEAVE flag_loop;
    END IF;

    INSERT INTO dict_county (S_COUNTYNAME, N_CITYID, S_STATE)
      VALUES (c_countyname, c_cityid_tmp, '1');

  END LOOP;
  CLOSE cur2;

  # 删除临时表
  DROP TEMPORARY TABLE tmp_table;
END
```

## Oracle存储过程示例

```sql
  -- 定义
  create or replace procedure p_up_user_role is
    cursor c is 
      select t.* from User_Login t; -- 游标
  begin
    delete from User_Login_Security_Group t where t.group_id = 'DW_DEPT_ADMIN';
    --for循环不需要声明变量，会自动将user_item声明为record变量
    for user_item in c loop
        insert into User_Login_Security_Group(User_Login_Id, Group_Id, From_Date) 
              values(user_item.user_login_id, 'DW_DEPT_ADMIN', '2017-11-01 00:00:00.000000');
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
    TYPE ref_cursor_type IS REF CURSOR; --定义一个游标类型

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
        exit when v_cur_storage%notfound;
      
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
            RAISE_APPLICATION_ERROR(-20001, v_errmsg || '位置超出堆位结构'); -- 抛出异常
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

## 异常

- `RAISE_APPLICATION_ERROR` 抛出异常函数，该函数是将应用程序专有的错误从服务器端转达到客户端应用程序(其他机器上的SQLPLUS或者前台开发语言)
- `PROCEDURE RAISE_APPLICATION_ERROR( error_number_in IN NUMBER, error_msg_in IN VARCHAR2);`
    - `error_number_in`: 自定义的错误码，容许从 -20000 到 -20999 之间，这样就不会与 ORACLE 的任何错误代码发生冲突。
    - `error_msg_in`: 长度不能超过 2k，否则截取 2k

## oracle函数

```sql
  declare 
    i integer;
  begin
    dbms_output.put_line('hello world');
    p_up_user_role();
  end;
```




---
