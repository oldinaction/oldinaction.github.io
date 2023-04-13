---
layout: "post"
title: "SQL Procedure"
date: "2017-08-24 20:33"
categories: [db]
tags: [oracle, mysql, procedure]
---

## 简介

- Mysql存储过程调试工具：`dbForge Studio for MySQL`

## Oracle

- PL/SQL 语句结束一定要加分号`;`，如果没加运行会提示下一行出错
- oracle转义字符为 `'` ，如 `''` 转义后就是 `'`
- sqlplus查看存储过程 `select text from all_source where name = 'my_procedure';`
- **通过select执行函数**`select my_func(select id from user where username='test') mf from dual;`可以到函数返回值
- [Oracle内置包/方法](https://docs.oracle.com/cd/E11882_01/appdev.112/e40758/toc.htm)

### 控制语句

- if-else

```sql
if ... end if;
if ... else ... end if;
if ... elsif ... end if; -- 注意是 elsif
```
- goto
    - `<<xxx>>`的标记符号，常用来跳出循环，使用goto可以跳到标记的位置

```sql
for i in 1..100 loop
    if i > 10 then
        goto end_loop;
    end if;
end loop;
<<outer>>
dbms_output.put_line('loop 循环了10次提前结束了！');
```

### Oracle存储过程示例

- `call p_up_user_role();` 调用存储过程

```sql
-- 定义
create or replace procedure p_up_user_role is
	cursor c is 
		select t.* from user_login t; -- 游标
	china_id number;
begin
	begin
        -- 在使用into给查询语句赋值时，是一次性into，例：select a,b,c into d,e,f from...而不是分别进行into，例： select a into d, b into e from...
		select t.id into china_id from t_structure t where t.structure_type_status = 1 and t.node_level = 6 and t.node_name = '中国'; --可能出现运行时异常：ORA-01403 no data found
	exception
		when no_data_found then china_id := -1;
	end;

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
create table logs_proc
(
	id number primary key,
	proc varchar2(255),
	pidtype varchar2(255),
	pid varchar2(20),
	code number,
	msg varchar2(1024),
	uptime date
);
create sequence seq_logs_proc start with 1 increment by 1;

-- ============ 创建存储过程  ============
create or replace procedure p_up_storage is
	type ref_cursor_type is ref cursor; --定义一个游标类型(动态游标使用)

	cursor c is
		select yls.* from yyard_location_set yls, ybase_party_company ypc
		where ypc.party_id = yls.yard_party_id
			and ypc.company_num = 'DW1' 
			and yls.region_num in ('Y0');

	v_cur_storage ref_cursor_type; -- 动态游标
	r_storage     ycross_storage%ROWTYPE;
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
	
		--使用连接符拼接成一条完整SQL. oracle转义字符为 ' ，如 '' 转义后就是 '
		v_sql := 'select * from ycross_storage t where t.yes_storage = 1 and t.location_id = ' || loc.location_id;

		--打开游标
		open v_cur_storage for v_sql; -- open v_cur_storage for 'select 1 from dual';
		loop -- 此处不能使用 for ... in ... loop的语句
			fetch v_cur_storage into r_storage;
			exit when v_cur_storage%notfound; -- 跳出循环

			update ycross_storage t set t.ycross_x = v_x, t.ycross_y = v_y where t.id = r_storage.id;

			if v_y < 7 then -- 也可以使用 like 等关键字
				v_y := v_y + 1;
			else
				if v_x < 30 then
					v_x := v_x + 1;
					v_y := 1;
				else
					raise_application_error(-20001, v_errmsg || '位置超出堆位结构'); -- 抛出异常
				end if;
			end if;

			-- 基于r_storage实现新增和修改
			insert into ycross_storage values r_storage;
			update ycross_storage set row = r_storage where id = 10000;
		end loop;
		close v_cur_storage;
	
	end loop;
	commit;

	return; -- 提前返回
	dbms_output.put_line('不会打印');
exception
	-- 捕获异常
	when others then
		--WHEN excption_name THEN ...WHEN OTHERS THEN ...
		rollback;
		v_errcode := SQLCODE; --出错代码
		v_errmsg  := v_errmsg || ', [msg]' || SQLERRM; --出错信息（直接使用SQLERRM报错，需先用变量接收）
		v_errmsg := v_errmsg || '; ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE; -- 报错行号
		insert into logs_proc(id, code, mesg, uptime)
		values
			(seq_logs_proc.nextval, v_errcode, v_errmsg, sysdate);
		commit;
end;
```

### 异常

- 异常属性
	- `SQLCODE` 出错代码. 如：`-1722`
	- `SQLERRM` 出错信息. 如：`ORA-01722: invalid number`
	- `DBMS_UTILITY.FORMAT_ERROR_BACKTRACE` 报错行号等信息. 如：`ORA-06512: at "CRMADM.P_UP_CUSTOMER_LOCK", line 39`
- 抛出异常 `raise_application_error` 该函数是将应用程序专有的错误从服务器端转达到客户端应用程序(其他机器上的sqlplus或者前台开发语言)
	- `raise_application_error(error_number_in in number, error_msg_in in varchar2);` 如 **raise_application_error(-20500, '执行出错');**
	- `error_number_in`: 自定义的错误码，容许从 -20000 到 -20999 之间，这样就不会与 oracle 的任何错误代码发生冲突。
	- `error_msg_in`: 长度不能超过 2k，否则截取 2k
- 捕获异常类型参考官方文档：https://docs.oracle.com/cd/B19306_01/appdev.102/b14261/errors.htm
	- `no_data_found` 无数据(select...into...语句需要捕获。`select count(1) into v_count from ...`无需捕获，无数据则为0)
	- `too_many_rows` 数据返回行数太多(select...into...语句可以捕获)
	- `value_error` 值异常(转换异常、字段大小异常)
	- `others` 所有未捕获的异常(也可捕获自定义异常)
- 防止select into无数据报错情况，可使用`select max(name) into str from ...`
- 在`[for...in...]loop...end loop`循环中捕捉异常，必须用`begin...end`包起来。捕获子异常也需要`begin...end`包起来

	```sql
	loop
		begin
		-- ...
		exception
			when others then dbms_output.put_line('出错'); -- 捕获异常后继续下一次循环
			-- when others then null; -- 捕获异常后继续下一次循环
			continue; -- 继续下一个循环
		end;
	end loop;
	```

### Oracle过程语句

```sql
set serverout on; --sqlplus执行时可开启服务器输出(通过@my.sql执行文件亦可). PL/SQL则不需要 
declare 
	i integer;
begin
	dbms_output.put_line('hello world');
	p_up_user_role(); -- 调用上述存储过程
end;
-- 运行过程语句
/
```

### forall与bulk collect语句提高效率

参考：[http://blog.aezo.cn/2018/07/27/db/sql-optimize/](/_posts/db/sql-optimization.md#批量更新优化)

### 自治事务

- 使用`PRAGMA AUTONOMOUS_TRANSACTION`
- 参考: https://www.cnblogs.com/it-note/archive/2013/06/14/3136134.html

### 常用类型

```sql
-- 用于 sq_split 函数function
create or replace type sq_type_split as table of varchar2(4000);

drop type sq_type_big_table;
drop type sq_type_big_table_row;

-- 定义动态大表: 如用于sql_pivot_dynamic_col动态行转列
-- 定义行类型
create or replace type sq_type_big_table_row as object (
	c1 VARCHAR2(255), c2 VARCHAR2(255), c3 VARCHAR2(255), c4 VARCHAR2(255), c5 VARCHAR2(255), c6 VARCHAR2(255), c7 VARCHAR2(255), c8 VARCHAR2(255), c9 VARCHAR2(255), c10 VARCHAR2(255),
	c11 VARCHAR2(255), c12 VARCHAR2(255), c13 VARCHAR2(255), c14 VARCHAR2(255), c15 VARCHAR2(255), c16 VARCHAR2(255), c17 VARCHAR2(255), c18 VARCHAR2(255), c19 VARCHAR2(255), c20 VARCHAR2(255),
	c21 VARCHAR2(255), c22 VARCHAR2(255), c23 VARCHAR2(255), c24 VARCHAR2(255), c25 VARCHAR2(255), c26 VARCHAR2(255), c27 VARCHAR2(255), c28 VARCHAR2(255), c29 VARCHAR2(255), c30 VARCHAR2(255),
	c31 VARCHAR2(255), c32 VARCHAR2(255), c33 VARCHAR2(255), c34 VARCHAR2(255), c35 VARCHAR2(255), c36 VARCHAR2(255), c37 VARCHAR2(255), c38 VARCHAR2(255), c39 VARCHAR2(255), c40 VARCHAR2(255),
	c41 VARCHAR2(255), c42 VARCHAR2(255), c43 VARCHAR2(255), c44 VARCHAR2(255), c45 VARCHAR2(255), c46 VARCHAR2(255), c47 VARCHAR2(255), c48 VARCHAR2(255), c49 VARCHAR2(255), c50 VARCHAR2(255)
);
-- 定义表类型
create or replace type sq_type_big_table is table of sq_type_big_table_row;
-- 删除时, 需要先删除sq_type_big_table
drop type sq_type_big_table;
drop type sq_type_big_table_row;
```

### 常用函数

#### sq_split字符串分割

```sql
-- 创建类型
create or replace type sq_type_split as table of varchar2(4000);

-- 创建函数(使用pipelined)
create or replace function sq_split(p_list varchar2, p_sep varchar2 := ',')
  return sq_type_split
  pipelined is
  l_idx  pls_integer;
  v_list varchar2(50) := p_list;
begin
  loop
    l_idx := instr(v_list, p_sep);
    if l_idx > 0 then
      pipe row(substr(v_list, 1, l_idx - 1));
      v_list := substr(v_list, l_idx + length(p_sep));
    else
      pipe row(v_list);
      exit;
    end if;
  end loop;
  return;
end sq_split;

-- 使用: 返回3行数据(COLUMN_VALUE)
select * from table(sq_split('A,BC,D',','));
```

#### sql_pivot_dynamic_col动态行转列

- 前提
    - 创建sq_type_big_table_row、sq_type_big_table类型(参考上文)
    - 调用自定义函数sq_split(参考上文)

```sql
/**
 * 动态行转列
 * 
 * sql_pivot_col 动态列字段(内部会进行去重): select <sql_pivot_col> from <sql_table> <sql_where> <sql_pivot_tail>
 * sql_table 查询的表(用于获取动态列字段 + 最终的行转列查询)
 * sql_where 查询条件(用于获取动态列字段 + 最终的行转列查询)
 * sql_pivot_tail 获取动态列时的尾部SQL, 如基于字段排序(可控制列的顺序)
 * sql_select_other_col 最终的行转列查询时, 除了查询动态列外的其他列(会拼接到动态列前面), 如果未非字符串(数字等)需要使用to_char转成字符串
 * sql_pivot 最终的行转列查询时的pivot语句, 其in子句中的内容需要使用@pivot_col_in@占位符代替
 * run_type 运行方式: 1获取列名行, 2获取值行, 3获取列名行+值行
 * sql_select_other_col_alias 查询额外列时对应列的别名
 * 
 * eg:
 * select * from table(sql_pivot_dynamic_col('bill_fee_cod', 'bill_fee', 'where PORT_ID = ''1'' and TRUST_COD = ''CUL''', 'order by bill_fee_cod'
	,'to_char(ship_no), bill_nbr', 'pivot (SUM(MONEY_NUM) for bill_fee_cod in(@pivot_col_in@))', 3, '船号,提单号'));
 */
CREATE OR REPLACE function sql_pivot_dynamic_col(sql_pivot_col varchar2, sql_table varchar2, sql_where varchar2, sql_pivot_tail varchar2, 
	sql_select_other_col in varchar2, sql_pivot in varchar2, run_type IN NUMBER, sql_select_other_col_alias in varchar2 := '')
return sq_type_big_table pipelined as v_row sq_type_big_table_row;
       -- 需要和sq_type_big_table_row对应列数相同
       sq_type_big_table_col_count NUMBER(10) := 50;
       sqlstr varchar2(4000);
       pivot_col_select varchar2(1000);
       pivot_col_in varchar2(1000);
       pivot_col_in_tmp varchar2(1000);
       pivot_col_select_count NUMBER(10);
       col_other_total NUMBER(10);
       col_total NUMBER(10);
       col_alias varchar2(100);
       -- 列名, 需要有sq_type_big_table_col_count个列名
       c1 varchar2(255);
       c2 varchar2(255);
       c3 varchar2(255);
       c4 varchar2(255);
       c5 varchar2(255);
       c6 varchar2(255);
       c7 varchar2(255);
       c8 varchar2(255);
       c9 varchar2(255);
       c10 varchar2(255);
       c11 varchar2(255);
       c12 varchar2(255);
       c13 varchar2(255);
       c14 varchar2(255);
       c15 varchar2(255);
       c16 varchar2(255);
       c17 varchar2(255);
       c18 varchar2(255);
       c19 varchar2(255);
       c20 varchar2(255);
       c21 varchar2(255);
       c22 varchar2(255);
       c23 varchar2(255);
       c24 varchar2(255);
       c25 varchar2(255);
       c26 varchar2(255);
       c27 varchar2(255);
       c28 varchar2(255);
       c29 varchar2(255);
       c30 varchar2(255);
       c31 varchar2(255);
       c32 varchar2(255);
       c33 varchar2(255);
       c34 varchar2(255);
       c35 varchar2(255);
       c36 varchar2(255);
       c37 varchar2(255);
       c38 varchar2(255);
       c39 varchar2(255);
       c40 varchar2(255);
       c41 varchar2(255);
       c42 varchar2(255);
       c43 varchar2(255);
       c44 varchar2(255);
       c45 varchar2(255);
       c46 varchar2(255);
       c47 varchar2(255);
       c48 varchar2(255);
       c49 varchar2(255);
       c50 varchar2(255);
       type cursor_type is ref cursor;
       my_cursor cursor_type;
BEGIN
  -- 获取动态列个数和对应动态列SQL片段
  -- select wm_concat(distinct 'to_char("' || bill_fee_cod || '")'), wm_concat(distinct '''' || bill_fee_cod || '''' || ' "' || bill_fee_cod || '"'), count(distinct bill_fee_cod) from bill_fee where port_id = '1' and MONEY_NUM != 0 order by BILL_FEE_COD;
  -- (1) 查询列 to_char("DOF"), to_char("LESS") (2) pivot in列 'DOF' "DOF", 'LESS' "LESS" (3) 列个数 2
  sqlstr := 
  	'select 
		wm_concat(distinct ''to_char("'' || ' || sql_pivot_col || ' || ''")'') pivot_col_select
		,wm_concat(distinct '''''''' || ' || sql_pivot_col || ' || '''''''' || '' "'' || ' || sql_pivot_col || ' || ''"'') pivot_col_in
		,count(distinct ' || sql_pivot_col || ') pivot_col_select_count
	from ' || sql_table || ' ' || sql_where || ' ' || sql_pivot_tail;
  
  open my_cursor for sqlstr;
  loop
    fetch my_cursor into pivot_col_select, pivot_col_in, pivot_col_select_count;
    exit when my_cursor%notfound;
    SELECT count(1) INTO col_other_total FROM table(sq_split(sql_select_other_col));
    col_total := col_other_total + pivot_col_select_count;
    IF col_total > sq_type_big_table_col_count THEN
      raise_application_error(-20000, '动态列个数超长');
    END IF;
    IF col_total < sq_type_big_table_col_count THEN
      for i in (col_total + 1)..sq_type_big_table_col_count loop
        pivot_col_select := pivot_col_select || ' ,'''' C' || i || ' ';
      end loop;
    END IF;
    IF sql_select_other_col IS NOT NULL THEN
    	pivot_col_select := ',' || pivot_col_select;
    END IF;
  end loop;
  close my_cursor;

  -- 拼接基于pivot的查询sql
  select 'select ' || sql_select_other_col || pivot_col_select 
  	 	|| ' from ' || sql_table || ' ' || replace(sql_pivot, '@pivot_col_in@', pivot_col_in)
  	    || ' ' || sql_where into sqlstr from dual;
  -- 如果需要返回列名行，需要将不足的列进行拼接
  IF run_type = 1 OR run_type = 3 THEN
  	IF col_other_total > 0 THEN
  		FOR i IN 1..col_other_total LOOP
	  	  IF sql_select_other_col_alias IS NOT NULL THEN
	  	  	SELECT t.COLUMN_VALUE INTO col_alias FROM (SELECT rownum rn, a.* FROM table(sq_split(sql_select_other_col_alias)) a) t WHERE rn = i;
	  	  END IF;
	  	  IF col_alias IS NULL THEN
	  	  	col_alias := '';
	  	  END IF;
  		  pivot_col_in_tmp := pivot_col_in_tmp || '''' || col_alias || ''' C' || i || ',';
  		end LOOP;
  		pivot_col_in := pivot_col_in_tmp || pivot_col_in;
  	END IF;
  	IF col_total < sq_type_big_table_col_count THEN
	  for i in (col_total + 1)..sq_type_big_table_col_count loop
	    pivot_col_in := pivot_col_in || ' ,'''' C' || i || ' ';
	  end loop;
	END IF;
  END IF;
  IF run_type = 1 THEN
    -- 返回列名行
  	select 'select ' || pivot_col_in || ' from dual' into sqlstr from dual;
  ELSE 
  	IF run_type = 2 THEN
  	  -- 返回值行
  	  sqlstr := sqlstr;
	ELSE
	  -- 返回列名行和值行
  	  select 'select ' || pivot_col_in || ' from dual union all ' || sqlstr into sqlstr from dual;
	END IF;
  END IF;
  -- dbms_output.put_line(sqlstr);

  open my_cursor for sqlstr;
  loop
    fetch my_cursor into 
    	c1, c2, c3, c4, c5, c6, c7, c8, c9, c10,
    	c11, c12, c13, c14, c15, c16, c17, c18, c19, c20,
    	c21, c22, c23, c24, c25, c26, c27, c28, c29, c30,
    	c31, c32, c33, c34, c35, c36, c37, c38, c39, c40,
    	c41, c42, c43, c44, c45, c46, c47, c48, c49, c50;
    exit when my_cursor%notfound;
    v_row := sq_type_big_table_row(
   		c1, c2, c3, c4, c5, c6, c7, c8, c9, c10,
    	c11, c12, c13, c14, c15, c16, c17, c18, c19, c20,
    	c21, c22, c23, c24, c25, c26, c27, c28, c29, c30,
    	c31, c32, c33, c34, c35, c36, c37, c38, c39, c40,
    	c41, c42, c43, c44, c45, c46, c47, c48, c49, c50
   	);
    -- 返回行数据到sq_type_big_table表中
    pipe row(v_row);
  end loop;
  close my_cursor;
  return;
end sql_pivot_dynamic_col;
```
- 使用

```sql
-- 获取每个提单对应的费目和金额(将费目行转列)
select * from table(sql_pivot_dynamic_col('bill_fee_cod', 'bill_fee', 'where PORT_ID = ''1'' and TRUST_COD = ''CUL''', 'order by bill_fee_cod'
,'to_char(ship_no), bill_nbr', 'pivot (SUM(MONEY_NUM) for bill_fee_cod in(@pivot_col_in@))', 3, '船号,提单号'));
-- 结果如(run_type=3)
列      C1      C2              C3      C4      C5      ...
值      船号     提单号           DOF     AOF     LESS
值      56143	CSI0135291              20
值      56143	CSI0135292      10      30      40
值      56144	CSI0135293              20      40
```

## Mysql存储过程示例

- 示例1(简单)

```sql
/*delimiter指分割符，Mysql默认的分割符是分号';'，如果没有声明分割符，那么编译器会把存储过程当成SQL语句来处理，容易报错，声明之后则把';'当成过程中的代码*/
drop procedure if exists p;/*如果存储过程p存在就将它删除*/
delimiter //
create procedure p
	(in v_a int, v_b int, out v_ret int, inout v_temp int)/*注意参数类型(in、out、inout)在参数名称之前*/
begin/*存储过程的过程体以begin开头，end结果*/
	if(v_a > v_b) then
		set v_ret = v_a;/*使用 "set" 和 "=" 进行变量赋值*/
	else
		set v_ret = v_b;
	end if;
	set v_temp = v_temp + 1;
end; //
delimiter ;/*还原Mysql默认的分割符*/

/*调用存储过程*/
set @v_a = 3;/*给参数赋值，用户变量一般以@开头*/
set @v_b = 4;
set @v_c = 0;/*out输出参数，最终会被改变*/
set @v_temp = 5;
call p(@v_a, @v_b, @v_c, @v_temp);/*运行存储过程p*/
/*展示结果*/
select @v_c, @v_temp;

+------+---------+
| @v_c | @v_temp |
+------+---------+
|    4 |       6 |
+------+---------+
```

- 示例2(高级)

```sql
-- 从用户表中提取某省份的区县字典表（已存在省份城市表）
drop procedure if exists test_county;
delimiter //
create 
definer = 'root'@'localhost' -- 省略此句则默认当前登录用户配置
procedure test_county(in `in_provid_id` int, in `in_inputer` varchar(100))
begin
	declare v_sql varchar(1000);
	declare v_city_id integer;
	declare v_city_name varchar(20);
	declare v_county_name varchar(20);
	declare v_city_id2 integer;
	declare v_star_provid integer;
    declare v_err_msg varchar(255);
    declare v_count int default 0;

	-- 是否未找到数据标记(要在游标之前定义)
	declare done int default false;

	-- 定义第一个游标（根据省份查询所有城市）
	declare cur1 cursor for
		select t.city_id, t.city_name from dict_city t where t.provid_id = in_provid_id;

	-- 临时表游标
	declare cur2 cursor for
		select city_id, city_name from temp_county;

    -- 错误处理。语法：DECLARE action {CONTINUE|EXIT} HANDLER FOR condition_value statement;
        -- 如果一个错误条件的值符合 condition_value，MySQL 就会执行对应的 statement，并根据 action 指定关键字确定是 `继续` 还是 `退出` 当前的代码块（当前代码块就是包含此错误处理器的最近的那对 BEGIN 和 END围出来的代码段。当有多层begin end的时候，每层都应该有自己的异常处理）
        -- action取值
            -- CONTINUE: 当前代码段会从出错的地方继续执行
            -- EXIT: 当前代码段从出错的地方终止执行
        -- condition_value 指定了会激活错误处理器的一个特定的条件或者一类错误条件。可以是
            -- 一个 MySQL 错误码
            -- 一个标准的 SQLSTATE 值，或SQLWARNING、SQLEXCEPTION（为 SQLSTATE 中类型相近的值，一个 SQLSTATE 可以对应到多个 MySQL 错误码）
            -- 一个与特定 MySQL 错误代码或者 SQLSTATE 值关联的命名错误条件
        -- statement 则可以是个简单的语句或者被 BEGIN 和 END 围起来的多条语句
        -- 错误处理优先级：Mysql错误码 > SQLSTATE 值
        -- 使用命名错误条件，语法：DECLARE condition_name CONDITION FOR condition_value;
            -- condition_value 可以是一个 MySQL 错误码，或者一个 SQLSTATE 值，然后 condition_name 就可以代表 condition_value 来使用了
        -- 存储过程中的错误被错误处理器捕获了之后，如果还想用类似 mysql 命令行那样的格式返回对应的错误，可以声明一个辅助函数，具体见下文
    
	-- 循环终止的标志，游标中如果没有数据就设置done为true(停止遍历)
	declare continue handler for not found set done = true;
	-- 错误处理：发生对应错误时返回select结果。参考：https://segmentfault.com/a/1190000006834132
	declare exit handler for 1062 select 'duplicate keys error encountered'; -- 发生了主键重复的错误(MySQL的错误码为1062)
    declare exit handler for sqlexception show errors; -- 或者 `show warnings` 显示错误信息(Level、Code、Message)
    declare exit handler for sqlstate '23000' select 'sqlstate 23000';
    -- 自定义命名错误条件，出错后退出，并执行begin...end中语句
    declare table_not_found condition for 1051;
    declare exit handler for table_not_found begin
        rollback;
        -- 使用下文自定义辅助函数
        set v_err_msg = fn_get_error();
        select 'an error has occurred, operation rollbacked and the stored procedure was terminated';
    end;

	-- 创建临时表
	drop table if exists temp_county;
	create temporary table if not exists temp_county (
		id int(11) not null auto_increment primary key,
		city_id int(10),
		county_name varchar(20)
	);

    set autocommit = 0;

	-- mysql不能直接定义变量结果集, 此处将结果集放到临时表中, 用于后面变量
	open cur1;
	flag_loop: loop
        set v_count = v_count+1;
		-- 取出每条记录并赋值给相关变量，注意顺序
		-- 用游标select的字段数需要与fetch into的变量数一致，**且变量的定义不要和select的列的键同名**, 否则fetch into 会失败！
		fetch cur1 into v_city_id, v_city_name;

		-- 调试输出. 运行时会打印在控制台
		select v_city_id, v_city_name;

		-- fetch之后, 如果没有数据则会运行set done = true
		if done then
			-- 跳出循环，类似于break
			leave flag_loop;
		end if;

		-- 测试handler(实际操作上可以在循环开始之前判断)
		begin
			-- **此处必须重新定义handler**，防止此处未获取到数据(not found)触发上面定义的handler，直接导致循环退出
			declare continue handler for not found set done = false;
			select t.star_provid into v_star_provid from dict_country t where t.provid_id = in_provid_id; -- star_provid是否为星标城市
			if v_star_provid is null then
				-- 类似于continue
				iterate flag_loop;
            else
                -- ...
			end if;
		end;

		-- 字符串截取，从第一位开始，截取2位
		set v_city_name = substring(v_city_name, 1, 2);

		-- 动态sql执行后的结果记录集在mysql中无法获取，因此需要转变思路将其放置到一个临时表中（基于城市名成模糊查询房源信息表中的所有区县）
		-- 动态sql需要使用concat(a, b, c, ....)拼接
		set v_sql = concat("insert into temp_county(city_id, county_name) select ", v_city_id,
			", t.county_name from t_house_addr t where t.city_name like '%", v_city_name, "%'");

		-- 如果以@开头的变量可以不用通过declare语句事先声明
		set @v_sql = v_sql;
		-- 预处理需要执行的动态sql，其中stmt是一个变量
		prepare stmt from @v_sql;
		-- 执行sql语句
		execute stmt;
		-- 释放掉预处理段
		deallocate prepare stmt;
        
        if (v_count)%500=0 then
			commit;
		end if;
	end loop;
	close cur1;

	-- 调试输出, 打印使用select
	select * from temp_county;

	-- 还原终止的标志, 用于第二个游标
	set done = false;

	open cur2;
	flag_loop: loop
		fetch cur2 into v_city_id2, v_county_name;
		if done then
			leave flag_loop;
		end if;

		insert into dict_county(city_id, county_name, s_state, inputer) values(v_city_id2, v_county_name, '1', in_inputer); -- county_id会自增
	end loop;
	close cur2;
    
    commit;
    set autocommit = 1;

	-- 删除临时表
	drop temporary table temp_county;
end; //
delimiter ;

--调用存储过程
call test_county(1, 1);
```

### 自定义函数

- handler错误处理时的辅助函数

```sql
-- 如果开启了bin-log，则需要设置 `set global log_bin_trust_function_creators=TRUE;`，或者my.cnf配置文件中添加 `log_bin_trust_function_creators=1`
drop function if exists fn_get_error; -- 没有这一行，直接第一行为`delimiter $$`会报错
delimiter $$
create function fn_get_error()
returns varchar(255)
begin
    declare code char(5) default '00000';
    declare msg text;
    declare errno int;
    
    -- `GET DIAGNOSTICS CONDITION 1` 是从mysql错误缓存区读取第一条错误信息
    GET DIAGNOSTICS CONDITION 1
        code = RETURNED_SQLSTATE, errno = MYSQL_ERRNO, msg = MESSAGE_TEXT;
    
    -- COALESCE(expression_1, expression_2, ...,expression_n)：将控制替换为其他值，依次参考各参数表达式，遇到非null值即停止并返回该值
    return coalesce(concat("ERROR ", errno, " (", code, "): ", msg), '-NA-');
end; $$
delimiter ;
```

### 存储过程调试

- Mysql存储过程调试工具：`dbForge Studio for MySQL`

## SQLServer

```sql
 --分页查询
ALTER proc [dbo].[SP_Test]
	@Table nvarchar(50),--表.视图
	@PageSize int,--每页显示数量
	@PageIndex int,--当前显示页码
	@Conditions nvarchar(300),--筛选条件
	@Pages int output--返回总共有多少页
as
	declare @start int ,--当前页开始显示的No
	@end int,--当前页结束显示的No
	@Context nvarchar(1024), --动态sql语句
	@pkey nvarchar(10)--主键或索引
	set @start=(@PageIndex-1)*@PageSize+1
	set @end=@start+@PageSize-1
	set @pkey=index_col(@Table,1,1)--获取主键，或索引
	--通过条件将符合要求的数据汇聚到临时表#temp上
	set @Context='select row_number() over(order by '+@pkey+') as [No],* into #temp  from '+@Table
	--判断是否有筛选条件传入
	if(@Conditions is not null) set @Context=@Context+' where '+@Conditions
	--通过查询#temp 表实现分页.
	set @Context=@Context+'  select * from #temp where No between '+cast(@start as nvarchar(4))+' and '+cast(@end as nvarchar(4))
	--返回出总共可以分成多少页
	set @Context=@Context+'  declare @count int  select @count=count(*) from #temp  set @Pages= @count/'+cast(@PageSize as nvarchar(4))+'  if(@count%'+cast(@PageSize as nvarchar(4))+'<>0) set @Pages=@Pages+1 '

	exec sp_executesql @Context,N'@Pages int output', @Pages output
	-- sp_executesql @动态sql语句，@动态sql语句中需要的参数，@传入动态sql语句参数的值（个人理解）
```

## Oracle的PL/SQL语言(笔记)

- PL/SQL和C、C++、Java一样是第三代语言，是一种注重过程的语言，可以解决复杂的事物关系。PL/SQL能处理的Java一般也能处理
- 函数和存储过程的区别：函数只能返回一个变量的限制。而存储过程可以返回多个。而函数是可以嵌入在sql中使用的,可以在select中调用，而存储过程不行。执行的本质都一样。 
- 函数限制比较多，比如不能用临时表，只能用表变量．还有一些函数都不可用等等．而存储过程的限制相对就比较少
- 变量声明的规则：
    - 每一行只能声明一个变量
    - 不要与数据库的表或者列同名
    - 变量名不能使用保留关键字，如from、select等
    - 第一个字符必须是字母
    - 变量名最多包含30个字符
- 数据类型
    - `char`		定长字符串；存取时效率高，空间可能会浪费
    - `varchar2`	变长字符串,大小可达4Kb(4096个字节)；存取时效率高；varchar2支持世界所有的文字，varchar不支持
    - `long`		变长字符串，大小可达到2G
    - `number`		数字；number(5, 2)表示此数字有5位，其中小数含有2位
    - `date`		日期
    - `binary_integer`	整数，主要用来计数而不是用来表示字段类型
    - `boolean`		布尔类型，可以取值为true、false和null值。最好给出默认值
- 零散语句
    - `set serveroutput on;` 此时设置了在服务器端输出数据，默认不在服务器端做输出
    - `show error` 显示详细错误信息。当PL/SQL存在语法错误时，程序只提示有编译错误，如果想了解哪一行出错，需使用语句show error
- 示例

```sql
-- 1.输出Hello World!
begin 
	dbms_output.put_line('Hello World!');/*输出*/
end;/*在程序末尾回车敲正斜线运行程序*/

-- 2.变量声明、赋值、输出
declare
	v_name varchar2(20);/*声明变量*/
begin
	v_name := 'myname';/*变量赋值，使用符号 := */ 
	dbms_output.put_line(v_name);/*输出变量*/
end;

-- 3.使用%type动态声明变量的类型
declare
	v_empno number(4);/*声明变量*/
	v_empno2 emp.empno%type;/*此时使用%type后v_empno2的类型会根据emp.empno的类型变化而变化*/
	v_empno3 v_empno2%type;
begin
	dbms_output.put_line('Hello');
end;

-- 4.Table变量类型(复合数据类型，相当于java中的数组.) 属于本地集合，无法和表进行关联，无法放在sql的in字句中
-- 更多参考：https://docs.oracle.com/cd/B28359_01/appdev.111/b28370/collections.htm#CHDEIDIC 、 https://stackoverflow.com/questions/20329078/oracle-insert-into-a-table-type
declare
	type type_table_emp_empno is table of emp.empno%type index by binary_integer;/*声明一个数组类型type_table_emp_empno，里面装的是emp.empno的类型*/
	v_empnos type_table_emp_empno;/*声明变量v_empnos的数据类型为type_table_emp_empno*/
begin
	-- select distinct t.username bulk collect into v_empnos from t_user t; -- 默认从1开始填充

	v_empnos(0) := 7369;
	v_empnos(1) := 7839; 
	v_empnos(-1) := 9999;
	dbms_output.put_line(v_empnos(-1));
end;
-- (2)
declare
	type my_type is table of varchar2(64) index by varchar2(64);
	v_table  my_type;
	i varchar2(64);
begin
	-- 添加值
	v_table('hello') := 'world';
	v_table('name') := 'smalle';
	v_table('age') := '18';
	-- 改变值
	v_table('name') := 'aezocn';
	-- 打印
	i := v_table.first;
	while i is not null loop
		dbms_output.put_line('v_table of ' || i || ' is ' || v_table(i));
		i := v_table.next(i);
	end loop;
end;

-- 5.Record变量类型(复合数据类型，相当于java中的类)
declare
	type type_record_dept is record
		(
			deptno dept.deptno%type,
			dname dept.dname%type,
			loc dept.loc%type
		);/*定义一种变量类型type_record_dept*/
		v_temp type_record_dept;/*声明变量*/
begin
	v_temp.deptno := 50;/*按java类的方式进行赋值*/
	v_temp.dname := 'abc';
	v_temp.loc := 'bj';
	dbms_output.put_line(v_temp.deptno || ' ' || v_temp.dname);/*输出变量，Oracle中||表示连接字符串*/
end;

-- 6.使用%rowtype声明record变量(会根据表的列改变而改变)
declare
		v_temp dept%rowtype;/*按照dept表的列进行动态声明变量*/
begin
	v_temp.deptno := 50;/*按java类的方式进行赋值*/
	v_temp.dname := 'abc';
	v_temp.loc := 'bj';
	dbms_output.put_line(v_temp.deptno || ' ' || v_temp.dname);/*输出变量*/
	update my_table set row = v_temp where id = 10000;
	-- 这样插入，不会自动填充字段默认值，普通insert语句是可以填充默认值的
	insert into my_table values v_temp;
end;

-- 7.使用select要与into一起使用，且返回值要有且只有一条
declare
	v_ename emp.ename%type;
	v_sal emp.sal%type;
begin
	select ename,sal into v_ename,v_sal from emp where empno = 7369;/*将取出来的ename的值放到v_ename变量中*/
	dbms_output.put_line(v_ename || ' ' || v_sal);
end;

-- 8.创建一张表。格式：要使用 `execute immediate 'create语句';`里面在设置字段username的默认值smalle时，需要用两个单引号表示一个单引号
begin
	execute immediate 'create table T(username varchar2(20) default ''smalle'')';
end;

-- 9.if语句(注意判断相等用"=")
declare
	v_sal emp.sal%type;
begin
	select sal into v_sal from emp where empno = 7369;
	if (v_sal < 1200) then
		dbms_output.put_line('low');
	elsif (v_sal < 2000) then
		dbms_output.put_line('middle');
	else
		dbms_output.put_line('high');
	end if;
end;

-- 10.loop循环（相当于java的while...循环）
declare
	i binary_interger :=1 ;
begin
	when i <11 loop
		dbms_output.put_line(i);
		i := i + 1;
	end loop;
end;

-- 11.loop循环（相当于java的增强for循环）(exit; --退出循环。EXIT WHEN condition;以某个条件退出循环。continue;执行下一个循环)
begin
	for j in 1..10 loop/*此时不需要声明变量j，会自动声明。从1到10循环*/
		dbms_output.put_line(j);
	end loop;

	for j in reverse 1..10 loop/*从10到1循环*/
		dbms_output.put_line(j);
	end loop;
end;

-- 12.loop循环（相当于java的do...while...循环）
declare
	k binary_interger :=1 ;
begin
	loop
		dbms_output.put_line(k);
		k := k + 1;
		exit when(k >= 11);
	end loop;
end;

-- 13.处理异常
declare
	v_num number := 0;
begin
	v_num := 2/v_num;
	dbms_output.put_line(v_num);
exception
	when others then/*相当于java异常中的exception*/
		dbms_output.put_line('error');
end;

-- 14.处理异常2
declare
	v_temp number(4);
begin
	select emptno into v_temp from emp where deptno = 10;
exception
	when too_many_rows then/*捕获异常too_many_rows*/
		dbms_output.put_line('太多记录，实际返回的行数大于请求的行数');
	when others then/*相当于java异常中的exception*/
		dbms_output.put_line('error');
end;

-- 15.日志处理案例
create table errorlog
(
id number primary key,
errcode number,
errmsg varchar2(1024),
errdate date
);
create sequence seq_errorlog_id start with 1 increment by 1;/*产生一个从1开始每次递增1的序列*/
declare
	v_deptno dept.deptno%type := 10;/*此时删不了，因为这个部门被emp里面的deptno参考*/
	v_errcode number;
	v_errmsg varchar2(1024);
begin
	delete from dept where deptno = v_deptno;
	commit;/*提交这个事物*/
exception
	when others then /*WHEN excption_name THEN ...WHEN OTHERS THEN ...*/
		rollback;/*撤销操作*/
		v_errcode := SQLCODE;/*SQLCODE是关键字，代表出错代码*/
		v_errmsg := SQLERRM;/*SQLERRM是关键字，代表出错信息*/
		insert into errorlog values(seq_errorlog_id.nextval, v_errcode, v_errmsg, sysdate);
		commit;
end;

-- 16.游标cursor。 取出emp表中所有记录的ename字段
-- 法一（do...while...循环）
declare
	cursor c is select * from emp;/*声明一个游标，此时游标c指在这个结果集上*/
	v_emp c%rowtype;/*v_emp为一个record变量*/
begin
	open c;/*打开游标*/
	loop
		fetch c into v_emp;/*把当前游标所处的条目取出放到v_emp上，并把游标下移一条*/
		exit when(c%notfound);/*"游标%notfound"当游标没有找到记录就返回true；"游标%found"则表示游标找到记录就返回true*/
		dbms_output.put_line(v_emp.ename);
	end loop;
	close c;/*关闭游标*/
end;
-- 法二（for循环）：（推荐）
declare
	cursor c is select * from emp;/*声明一个游标，此时游标c指在这个结果集上*/
begin
	for v_emp in c loop/*for循环不需要声明变量，会自动将v_emp声明为record变量*/
		dbms_output.put_line(v_emp.ename);
	end loop;
end;

-- 17.带参数的游标
declare
	cursor c(v_deptno emp.deptno%type, v_job emp.job%type) is
		select ename, sal from emp where deptno = v_deptno and job = v_job;
	--v_temp c%rowtype;这是注释；此时不需要声明v_temp
begin
	for v_temp in c(30, 'CLERK') loop
		dbms_output.put_line(v_temp.ename);
	end loop;
end;

-- 18.可更新的游标
declare
	cursor c is select * from emp2 for update;/*加上for update表示可更新的游标*/
begin
	for v_temp in c loop
		if(v_temp.sal < 2000) then
			update emp2 set sal = sal*2 where current of c;/*current of c表示游标c指在那条记录上，那条记录就可以更改*/
		elsif(v_temp.sal = 5000) then/*注意此时判断用=*/
			delete from emp2 where current of c;
		end if;
	end loop;
	commit;
end;

-- 19.创建存储过程procedure
create or replace procedure p is/*创建或者替换一个存储过程procedure，过程名为p*/
	cursor c is
		select * from emp2 for update;
begin
	for v_emp in c loop
		if(v_emp.deptno = 10) then
			update emp2 set sal = sal+10 where current of c;
		elsif(v_emp.deptno = 20) then
			update emp2 set sal = sal+20 where current of c;
		else
			update emp2 set sal = sal+50 where current of c;
		end if;
	end loop;
	commit;
end;
/
--注释：此时提示过程已成功创建，但是并没有执行
exec p;/*执行存储 过程*/
--注释：PL/SQL过程已成功完成

-- 20.带参数的存储过程
create or replace procedure p
	(v_a in number, v_b number, v_ret out number, v_temp in out number)
		--注释：in表示传入参数(谁调用存储过程，谁给他赋值)，out表示传出参数(由于存储过程没有返回值，故用传出参数表示返回值)
		--注释：默认为in，如此时的v_b也为传入参数。in out表示既可传入也可传出
is
begin
	if(v_a > v_b) then
		v_ret := v_a;
	else
		v_ret := v_b;
	end if;
	v_temp := v_temp + 1;
end;
/
--注释：此时提示过程已成功创建
--注释：下面的代码调用了存储过程p
declare
	v_a number := 3;
	v_b number := 4;
	v_ret number;
	v_temp number := 5;
begin
	p(v_a, v_b, v_ret, v_temp);/*调用存储过程p*/
	dbms_output.put_line(v_ret);/*结果打印4*/
	dbms_output.put_line(v_temp);/*结果打印6*/
end;

-- 21.删除一个存储过程
drop procedure p;/*删除存储过程p*/

-- 22.函数function
create or replace function sal_tax(v_sal number) return numbre/*声明或替换一个函数sal_tax，返回值是number类型*/
is
begin
	if(v_sal < 2000) then
		return 0.10;
	elsif(v_sal < 2750) then
		return 0.15;
	else
		return 0.20;
	end if;
end;
/
--注释：此时提示函数已创建
--注释：函数的使用同Oracle自带的函数
select lower(ename), sal_tax(sal) from emp;

-- 23.触发器trigger。将对表emp2的操作记录在表emp2_log中
create table emp2_log
(
uname varchar2(20),
action varchar2(10),
atime date
);
create or replace trigger trig
	after insert or delete or update on emp2 for each row
--注释：上面是创建一个触发器trig，在表emp2被插入后(也可为插入前before insert)、删除、更新时被触发
--注释：for each row是指每插入、删除、更新一行就触发一次
begin
--注释：inserting、updating、deleting、USER都是关键字
	if inserting then
		 insert into emp2_log values(USER, 'insert', sysdate);
	elsif updating then
		 insert into emp2_log values(USER, 'update', sysdate);
	elsif deleting then
		 insert into emp2_log values(USER, 'delete', sysdate);
	end if;
end;
/
--注释：此时提示触发器已创建
--注释：下面是触发此触发器的操作
update emp2 set sal = sal*2 where deptno = 30;
--注释：检查是否被触发
select * from emp2_log;

-- 24.触发器解决外键约束后不能执行更新操作（一般很少使用）当执行update dept set deptno = 99 where deptno = 10;时会报错，因为dept中的deptno被emp中的deptno参考。使用触发器解决此问题：
create or replace trigger t
    -- 当修改dept.dname字段时触发
	after update of dname on dept for each row
begin
	update emp set deptno = :NEW.deptno where deptno = :OLD.deptno;
end;
/
--注释：此时提示触发器已创建
--注释：下面是触发此触发器的操作
update dept set deptno = 99 where deptno = 10;
--注释：此时不报错，因为语句中的:NEW.deptno现在指99，而:OLD.deptno指10。就是将emp中参考的deptno进行提前更新

-- 25.删除一个触发器
drop trigger trig;/*删除触发器p*/
```


---
