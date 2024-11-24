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

## 不同数据库差异

- 可使用ETL工具[kettle](https://www.oschina.net/p/kettle)对不同数据库中的数据做迁移和同步
- [Oracle迁移MySQL注意事项](https://z.itpub.net/article/detail/981AEFD121E9C508F063228A878ED6E0)
- Oracle 11g表名最大长度为30，Mysql最大长度为64

### 数据类型转换

- mysql：`cast()`和 `convert()` 可将一个类型转成另外一个类型
    - 语法：cast(expr as type)、convert(expr, type)、convert(expr using transcoding_name)   

```sql
-- mysql、h2。可用类型：二进制 BINARY、字符型，可带参数 CHAR()、日期 DATE、TIME、DATETIME、浮点数 DECIMAL、整数 SIGNED、无符号整数 UNSIGNED
-- 可将LONG/CLOB等转成字符串
select cast(ID as char) from user limit 1;
select cast('123.45' as decimal(10, 2));

-- 日期时间转换
-- mysql
select now(), date_format(now(), '%Y-%m-%d %H:%i:%s'), date_format(now(),'%Y-%m-%d');
select str_to_date('2016-01-02 10:00:00.000','%Y-%m-%d %H:%i:%s.%f');
select to_days(now()); -- 727666 从0年开始到当前的天数
select to_days('2016-01-02');
-- oracel(oracle也支持cast)
select to_char(sysdate, 'yyyy-MM-dd HH24:mi:ss') from dual;
select to_date('2016-01-02 10:00:00', 'yyyy-MM-dd HH24:mi:ss') from dual;
select to_number('0') from dual;
select cast(100 as varchar2(10)) from dual;
--sqlserver
select convert(varchar(10), getdate(), 120); -- 格式化日期(120为一种格式) 2000-01-01
select convert(datetime, '2000-01-01', 20); -- 字符串转日期 2000-01-01 00:00:00.000
```

### 日期

- 日期数据类型转换见上文: [数据类型转换参考](#数据类型转换)

```sql
-- mysql
-- quarter:季，week:周，day:天，hour:小时，minute:分钟，second:秒，microsecond:毫秒
date_add('1970-01-01', interval -7 day ); -- 对应时间-7天. 不能直接 `now()-7`
date_sub(now(), interval 1 week); -- 该时间-1周 
-- 2000-01-01、2000-01-01 00:00:00、2000-01-01 23:59:59
select CURDATE(), DATE_FORMAT(CURDATE(),'%Y-%m-%d %H:%i:%s'), DATE_SUB(DATE_ADD(CURDATE(), INTERVAL 1 DAY),INTERVAL 1 SECOND);
-- 本月第一天, 本月最后一天
select date_add(curdate(), interval - day(curdate()) + 1 day), last_day(curdate());
-- 更多参考
-- https://blog.csdn.net/weixin_36419499/article/details/113464438

-- oracle
sysdate + interval '1' year -- 当前日期加1年，还可使用：month、day、hour、minute、second
sysdate + interval '1 1:1' day to minute -- 当前日期 + 1日1时1分
sysdate + 1 -- 加1天
sysdate - 1/24/60/60 -- 减1秒
select sysdate, add_months(sysdate, -12) from dual; -- 减1年
select trunc(sysdate) from dual; -- 取得当天0时0分0秒
select trunc(sysdate)+1-1/86400 from dual; -- 取得当天23时59分59秒(在当天0时0分0秒的基础上加1天后再减1秒)
select to_char(sysdate,'yyyy-mm')||'-01' firstday, 
       to_char(last_day(sysdate),'yyyy-mm-dd') lastday from dual; -- 在oracle中如何得到当天月份的第一天和最后一天
select to_date('1970', 'yyyy') from dual;
select to_date('2022-03-12 10:10', 'yyyy-mm-dd hh24:mi:ss') from dual; -- 2022-03-12 10:10:00
-- 产生随机时间
select to_date(to_char(sysdate + trunc(dbms_random.value(1,3)), 'yyyy-mm-dd')
  || ' ' || to_char(trunc(dbms_random.value(8,17)), 'fm00') || ':' || to_char(trunc(dbms_random.value(0,59)), 'fm00') || ':' || to_char(trunc(dbms_random.value(0,59)), 'fm00'), 'yyyy-mm-dd hh24:mi:ss')
from dual;

-- sqlserver
select 
    GETDATE(), -- 获取当前时间(带时间) 2000-01-01 08:11:12.000
    GETUTCDATE(), -- 当前UTC时间 2000-01-01 00:11:12.000
    DATEDIFF(hour, GETUTCDATE(), GETDATE()), -- 获取当前时间-当前UTC时间的相差小时 8
    dateadd(DD,-10,getdate()), -- 当前时间减10天
    DATEADD(hour, DATEDIFF(hour, GETUTCDATE(), GETDATE()), GETUTCDATE()); -- 对UTC时间增加时区差 2000-01-01 08:11:12.000
select DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE())); -- 2000-01-01 00:00:00.000
select CAST(CAST(GETDATE() as date) as varchar(10)) + ' 00:00:00'; -- 2000-01-01 00:00:00.000
```

#### 时区相关

- 参考: https://www.cnblogs.com/scoopr/p/5592339.html
- Oracle和MySQL中的timestamp的作用是不同的
    - Oracle中，TIMESTAMP是对date的更高精度的一种存储，是作为datetime的延展，但它不存储时区信息（Date不含微妙级时间）
    - Oracle中，TIMESTAMP WITH TIME ZONE存储时区信息
    - Oracle中，TIMESTAMP WITH LOCAL TIME ZONE不会存储时区信息，会将传入时间数据转换为数据库时区的时间数据进行存储，但不存储时区信息；客户端检索时，oracle会将数据库中存储的时间数据转换为客户端session时区的时间数据后返回给客户端
    - MYSQL中，TIMESTAMP是为了更少的存储单元（DATETIME为4字节，TIMESTAMP为1个字节）但是范围为1970的某时的开始到2037年，而且会根据客户端的时区判断返回值，MYSQL的TIMESTAMP时区敏感这点和ORACLE的TIMESTAMP WITH LOCAL TIME ZONE一致
- ORACLE和MYSQL的函数返回不一样
    - oracle读取的时区信息是以client端为准，CURRENT_TIMESTAMP都受到客户端SESSION TIMEZONE影响，而SYSDATE,SYSTIMESTAP不受影响
    - mysql读取的时区信息是以server端为准，NOW(),SYSDATE(),CURRENT_TIMESTAMP 均不受到客户端连接时区影响
- Oracle的DBTIMEZONE只和TIMESTAMP WITH LOCAL TIME ZONE有关。MySQL中的time_zone直接影响所有的timestamp取值
- 为了返回一致的数据MYSQL设置TIME_ZONE参数即可，因为他是每个连接都会用到的；但是ORACLE最好使用SYSDATE或者SYSTIMESTAMP来直接取DB SERVER端时间
- MySQL修改时区信息，只要CLIENT端的时区信息不变，此无影响
- Oracle修改时区信息，同理，TIMESTAMP WITH LOCAL TIME ZONE不受影响，TIMESTAMP和TIMESTAMP WITH TIME ZONE会发生变化
- 如果在client中不指定时区信息，oracle以client端的时区信息为准，要进行转换，mysql以server端的时区信息为准

```sql
-- oracle
-- 设置数据库的时区(只会影响CURRENT_TIMESTAMP等函数，对时间插入和查询的数值不会影响)
ALTER DATABASE SET TIME_ZONE = 'Asia/Shanghai';
ALTER SESSION SET TIME_ZONE = 'Asia/Shanghai';
-- 代码处理(当前session时区为Asia/Shanghai)
SELECT CURRENT_TIMESTAMP -- 2020-07-26 12:43:53.576491 +08:00
    ,CAST(CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS TIMESTAMP) utc_time -- 2020-07-26 04:43:53.576491 +08:00
    ,CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Bangkok' AS magu_time -- 2020-07-26 11:43:53.576491 +07:00
    ,to_timestamp_tz('2023-07-24 18:00:00', 'yyyy-mm-dd hh24:mi:ss') -- 2023-07-24 18:00:00.000000 +08:00
FROM DUAL;

-- 案例2
-- (当前session时区为Asia/Shanghai) 2020-07-26 11:38:50.314000,2020-07-26 10:38:50.314000 +07:00,2020-07-26 10:38:50.314000,2020-07-26 11:38:50.314000,2020-07-26 10:38:50.314000 +07:00
-- (当前session时区为Asia/Bangkok) 2020-07-26 11:38:50.314000,2020-07-26 10:38:50.314000 +07:00,2020-07-26 11:38:50.314000,2020-07-26 12:38:50.314000,2020-07-26 12:38:50.314000 +07:00
SELECT
    t.INPUT_TM a -- INPUT_TM为TIMESTAMP类型(无时区信息)
    -- **FROM_TZ相当于标记了INPUT_TM对应时区为Asia/Shanghai，然后将其转换成Asia/Bangkok，因此session时区不影响最终输出**
    ,FROM_TZ(CAST(t.INPUT_TM AS TIMESTAMP), 'Asia/Shanghai') AT TIME ZONE 'Asia/Bangkok' AS b
    ,CAST(t.INPUT_TM AT TIME ZONE 'Asia/Bangkok' AS TIMESTAMP) c -- 将INPUT_TM转成Asia/Bangkok的时区，再转成TIMESTAMP格式；当session时区为Asia/Shanghai时(会先将INPUT_TM标记为Asia/Shanghai时区)，转换后最终结果会少1个小时；当session时区为Asia/Bangkok时，最终结果不变
    ,CAST(t.INPUT_TM AT TIME ZONE 'Asia/Shanghai' AS TIMESTAMP) d
    ,CAST(t.INPUT_TM AT TIME ZONE 'Asia/Shanghai' AS TIMESTAMP) AT TIME ZONE 'Asia/Bangkok' AS e
FROM t_test t where t.id = 1;
-- 2024-07-26 11:38:50.314000,2024-07-26 10:38:50.314000 +07:00,2024-07-26 10:38:50.314000,2024-07-26 10:38:50
SELECT
    t.INPUT_TM a
    ,FROM_TZ(CAST(t.INPUT_TM AS TIMESTAMP), 'Asia/Shanghai') AT TIME ZONE 'Asia/Bangkok' AS b
    ,cast(FROM_TZ(CAST(t.INPUT_TM AS TIMESTAMP), 'Asia/Shanghai') AT TIME ZONE 'Asia/Bangkok' as timestamp) c
    ,to_char(FROM_TZ(CAST(t.INPUT_TM AS TIMESTAMP), 'Asia/Shanghai') AT TIME ZONE 'Asia/Bangkok', 'yyyy-mm-dd hh24:mi:ss') d
FROM t_test t where t.id = 1;
```

### 其他

- 查询空白表

```sql
-- mysql
select 1;
-- oracle
select 1 from dual;
```
- 关键字转义

```sql
select * from `user`; -- mysql
select * from [Order]; -- sqlserver
```
- 空值

```sql
-- oracle null包含了空字符串('' == null)
select * from users where last_name is null;
select * from users where last_name is not null;
nvl(counts, 0)

-- mysql null不包含空字符串('' != null)
select * from users where (last_name is null or last_name = '');
select * from users where last_name is not null and last_name != '';
-- 终极判断: (case when #{name} is null then #{default} else if(#{name}='', #{default}, #{name}) end)
select ifnull(null, 1), ifnull('', 1), if(''='', 1, 0); -- 1 '' 1

-- sqlserver
isnull(counts, 0)
```
- 空值排序

```sql
order by my_field [asc|desc] nulls [first|last] -- oracle
order by if(isnull(my_field),1,0), my_field [asc|desc] -- mysql默认将null值放在下面
order by if(isnull(my_field),0,1), my_field [asc|desc] -- mysql默认将null值放在上面
```
- 中文排序

```sql
-- mysql
select * from tags order by convert(name USING gbk) COLLATE gbk_chinese_ci asc;
```
- 字符串类型值

```sql
-- Mysql 可以使用单引号或双引号，Oracle只能使用单引号
select name from user where name = "smalle";
select name from user where name = 'smalle';
```
- as用法

```sql
-- Mysql/Oracle两种写均支持。只不过mybatis操作oracle返回map时，第一种写法的key全部为大写，第二种写法的key为小写
select name as username from user where name = "smalle";
select name as "username" from user where name = "smalle";
```
- 多字段查询

```sql
-- oracle
select * from user t where (t.name, t.sex) in (('张三', 1)); -- 此处用=也得在外面多加一层括号
```
- 数值比较

```sql
-- 假设两个字段一个是number(10, 2)的, 一个是FLOAT的则比较可能会有问题，可进行cast/round转换再比较
select 1 from test where num1 > cast(num2 as number(10, 2));
```
- (oracle)decode替代

```sql
-- oracle
select decode(t.sex, 1, '男', 0, '女', '未知') from t_user;
-- mysql
select if(t.sex = 1, '男', if(t.sex = 0, '女', '未知')) from t_user; -- if函数只支持3个参数
select case when ... end from t_user;

```

### 复制表数据

- [复制表结构参考](/_posts/db/mysql/mysql-backup-recover.md#Mysql相关语法)
    - create table ... as select
- 复制表数据
    - insert into ... select

### 关联表进行数据更新

- **`update set from where`** 将一张表的数据同步到另外一张表
    
```sql
-- Oracle：如果a表和b表的字段相同，最好给两张表加别名. **注意where条件**，idea可能出警告
-- 如果b表关联了c表则关联条件中不能使用a表字段，只能在where条件中使用a表字段
update test a set (a.a1, a.a2, a.a3) = (select b.b1, b.b2, b.b3 from test2 b where a.id = b.id);
where exists (select 1 from test2 b where a.id = b.id);

-- Mysql：update的表不能加别名，oracle可以加别名。当字段相同时直接使用表名做前缀
update a, b set a1 = b1, a2 = b2, a3 = b3 where a.id = b.id;
update a left join b on a0 = b0 set a1 = b1, a2 = b2, a3 = b3 where a.valid_status = 1;
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

### 更新前几行数据

```sql
-- oracle: 优先更新某个字段完全匹配的数据，没有完全匹配则更新该字段为空的数据
UPDATE t_users a
SET a.age = a.age + 1
WHERE a.name = 'test'
and a.sex || '_NULL_' = (
    -- 防止sex为空
    select sex || '_NULL_' from (
        SELECT a.*
        FROM t_users a
        WHERE a.name = 'test'
        and (a.sex is null or a.sex = 'Boy')
        order by case when a.sex = 'Boy' then 0 else 1 end
    ) where ROWNUM <= 1
);

-- mysql: 未测试
update test_table test set test.aaa = 'xxx' where test.aaa = 'XXX' order by test.xxx desc limit 1;
```

### 不查询某个字段(获取列信息)

```sql
-- mysql
select GROUP_CONCAT(COLUMN_NAME) cols 
from information_schema.COLUMNS
where table_schema = '数据库' AND table_name = '表名'
AND COLUMN_NAME NOT IN ('id','name');
-- select '上面的查询结果' from test;


-- oracle 用户表
select listagg( t.column_name,',') within group ( order by t.column_name ) cols
from user_tab_columns t 
where t.table_name = '表名' and t.column_name not in ('id');
-- oracle 同义词表
select listagg( atc.column_name,',') within group ( order by atc.column_name ) cols
from all_tab_columns atc
left join all_synonyms s on (atc.owner = s.table_owner and atc.table_name = s.table_name)
where s.owner = 'SAMIS45_SHSD_WEB' and atc.table_name = 'BILL_CNTR'
and atc.column_name not in ('BILL_NO');


-- sqlserver
-- sys.objects 表说明 https://learn.microsoft.com/zh-cn/sql/relational-databases/system-catalog-views/sys-objects-transact-sql?view=sql-server-2017
-- 查看表信息
SELECT schemas.name AS schema_name,
	objects.name AS table_name,
	objects.OBJECT_ID AS object_id,
	objects.type AS object_type,
	properties.value AS remarks 
FROM sys.objects AS objects
INNER JOIN sys.schemas AS schemas ON objects.SCHEMA_ID = schemas.SCHEMA_ID AND ( objects.type= 'U' OR objects.type= 'V' ) 
LEFT JOIN sys.extended_properties AS properties ON objects.OBJECT_ID = properties.major_id AND properties.minor_id= 0
where cast(properties.value as varchar(100)) like '%用户表%';

-- 查看字段信息
SELECT schemas.name as schema_name,
	objects.name as table_name,
	objects.object_id as object_id,
	columns.name as column_name,
	columns.column_id as column_id,
	columns.max_length as max_length,
	columns.precision as precision,
	columns.scale as scale,
	columns.system_type_id as system_type_id,
	types.name as type_name,
	properties.value as remarks
FROM sys.objects AS objects
INNER JOIN sys.schemas AS schemas ON objects.SCHEMA_ID = schemas.SCHEMA_ID AND ( objects.type= 'U' OR objects.type= 'V' ) 
inner join sys.columns columns on columns.object_id=objects.object_id
left join sys.extended_properties AS properties ON objects.OBJECT_ID = properties.major_id and properties.minor_id = columns.column_id
left JOIN sys.types as types on columns.user_type_id=types.user_type_id
where 1=1
and schemas.name='dbo' -- 指定schema
-- and objects.name='指定表/视图'
and cast(properties.value as varchar(100)) like '%发票抬头%';

-- 查看表最后更新时间(不是很准确，貌似是DDL的最后更新时间)
SELECT * FROM sys.objects A 
WHERE (A.[type]='S' OR A.[type]='IT' OR A.[type]='U')
AND A.modify_date >= dateadd(DD,-10,getdate()) -- 最近10天更新的
ORDER BY A.modify_date DESC;
```

### 环境变量和自定义变量

- oracle案例: [记录数据变动日志](/_posts/db/oracle-dba.md#记录数据变动日志)
- oracle: https://blog.csdn.net/db_murphy/article/details/115186884
- mysql: https://blog.csdn.net/qq_36528734/article/details/81187863

## 复杂查询

- count是统计该字段不为空的行数，可结合distinct使用，如`count(distinct case when u.sex = '1' then u.city else null end )`

### 基于用户属性表统计每个公司不同用户属性的用户数

```sql
-- 1个公司对应多个用户，1个用户对应多个属性
select
	c.id,
	c.name,-- 公司名称
	count( distinct u.id ) count_user,-- 该公司的用户数
	count( distinct case when ua.key = 'JobTitle' and ua.value = 'employee' then u.id end ) count_employee, -- 该公司的普通员工数。也可加上`else null`(因为count是统计该字段不为空的行数)
	count( case when ua.key = 'JobTitle' and ua.value = 'manager' then c.id end ) count_manager -- 该公司的经理数(c.id本身就group by了, 冗余的就是用户数)
from
	company c
	left join users u on c.id = u.company_id
	left join user_attr ua on ua.user_id = u.id 
group by
	c.id,
	c.name
```

### 基于关系表统计多个关系同时存在的主表记录

```sql
/*
通知表：notice
通知-用户关系表：notice_relation
发布通知时可选择部分用户，此时查询出用户1、2、3同时收到的通知记录，并统计出每个通知的已读和未读人数
*/
select nr.notice_id, count(1) as send_user_counts,
    count(case when nm.read_status = 1 then 1 end) yes_read,
    count(case when nm.read_status = 0 then 1 end) no_read
from notice_relation nr
where nr.user_id in (1, 2, 3)
group by nr.notice_id
having count(1) = 3
```

### 基于主子孙表求和统计

```sql
select count(1) "艘次", sum(a.net_ton) "总净吨", sum(a.gweight_ton) "代理货物总量（万吨）", sum(a.bc_count) "代理集装箱量"
from
(
    select s.ship_no, sd.net_ton, round(sum(sb.gweight_ton)/10000,0) gweight_ton, a.bc_count bc_count
    from ship s
    left join c_ship_data sd on sd.e_ship_nam = s.e_ship_nam
    left join ship_bill sb on s.ship_no = sb.ship_no
    left join (
        select sb.ship_no,sum(decode(bc.cntr_size_cod, '20', 1, 2)) bc_count -- 存在拼箱问题
        from ship s -- 主表
        join ship_bill sb on s.ship_no = sb.ship_no -- 子表
        join bill_cntr bc on sb.bill_no = bc.bill_no -- 孙表
        where s.leav_port_tim > sysdate-30 and sb.port_id in ('0','1')
        group by sb.ship_no
    ) a on a.ship_no = s.ship_no
    where s.leav_port_tim > sysdate-30 and sb.port_id in ('0','1')
    group by s.ship_no, sd.net_ton, a.bc_count
) a
```

### 行转列/列转行

```sql
/*
-- course
id  stu_no  course_name course_score
1   1       yuewen      90
2   1       shuxue      80
3   1       yingyu      85
4   2       yuewen      95
5   2       shuxue      100
6   2       yingyu      55

-- course2
stu_no  yuewen  shuxue  yingyu
1       90      80      85
2       95      100     55
*/
```

#### oracle

- 使⽤ decode 与聚合函数实现

    ```sql
    select t.name,
        sum(decode(t.course,'chinese', score, null)) as CHINESE,
        sum(decode(t.course,'math', score, null)) as MATH,
        sum(decode(t.course,'english', score, null)) as ENGLISH
    from students t
    group by t.name
    order by t.name
    ```
- 使⽤ case when 与聚合函数实现，类似decode
- 使⽤ pivot 函数

    ```sql
    select * from
        select name, chhinese, math, english from students
        pivot(
            max(score) -- max ⾥是要转的列的值
            for course -- 需要转的列名称
            in('chinese' chhinese, 'math' math, 'english' english)
        )
    order by name;

    -- 扩展说明: pivot的xml字句
    -- bill_fee_cod_xml为xmltype格式(mybatis无法解析), getstringval为转成XML字符串(但是最大长度时4000), getclobval为转成clob格式(内容还是xml)
    select ship_no, bill_nbr, bill_fee_cod_xml, (bill_fee_cod_xml).getstringval(), (bill_fee_cod_xml).getclobval() 
        from bill_fee
        -- 以 XML 格式显示 pivot 操作的输出，在plsql中显示成了xmltype；此时对应字段为bill_fee_cod的后面加上_xml
        pivot xml (sum(MONEY_NUM) for bill_fee_cod in(select BILL_FEE_COD from bill_fee where port_id = '1' and trust_cod = 'CUL'))
    where port_id = '1' and trust_cod = 'CUL'
    ```
- 动态行转列(列名不固定)
    - 基于存储过程动态拼接SQL，参考[sql-procedure.md#sql_pivot_dynamic_col动态行转列](/_posts/db/sql-procedure.md#sql_pivot_dynamic_col动态行转列)
    - 基于存储过程动态拼接SQL和视图 https://blog.csdn.net/Huay_Li/article/details/82924443
        - 查询每次新增临时查询ID和时间，再定时删掉老的数据；第一次查询创建几百个字段的视图(无实际意义的字段名)，并把列头以一行值的形式显示到结果中(第一行值充当列头)
- 合并到一个字段
    - 参考[wm_concat行转列](#wm_concat行转列)
    - 参考[listagg within group行转列, 类似wm_concat](#listagg%20within%20group行转列)

#### mysql

```sql
-- 参考：https://www.cnblogs.com/xiaoxi/p/7151433.html
-- 行转列
select stu_no,
    sum(case `course_name` when 'yuewen' then course_score else 0 end) as 'yuewen',
    sum(case `course_name` when 'shuxue' then course_score else 0 end) as 'shuxue',
    sum(case `course_name` when 'yingyu' then course_score else 0 end) as 'yingyu'
from course 
group by stu_no
-- 方式二
select ifnull(userid,'total') as userid,
    sum(if(`course_name`='yuewen',course_score,0)) as yuewen, -- IF(condition, value_if_true, value_if_false)
    sum(if(`course_name`='shuxue',course_score,0)) as shuxue,
    sum(if(`course_name`='yingyu',course_score,0)) as yingyu,
    sum(course_score) as total 
from course
group by stu_no with rollup;
-- 方式三：适用于不确定的列
SET @EE='';
SELECT @EE :=CONCAT(@EE,'sum(if(course_name=\'',course_name,'\',course_score,0)) as ',course_name, ',') AS aa FROM (SELECT DISTINCT course_name FROM course) A; -- (1) sum(if(`subject`='语文',score,0)) as 语文; (2) sum(if(`subject`='语文',score,0)) as 语文, sum(if(`subject`='数学',score,0)) as 数学; ...
SET @QQ = CONCAT('select ifnull(stu_no,\'-NA-\')as stu_no,',@EE,' from course group by stu_no');
PREPARE stmt FROM @QQ;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```

#### sqlserver

- 行转列：`PIVOT`用于将列值旋转为列名；也可用聚合函数配合CASE语句实现
- 列转行：`UNPIVOT`用于将列明转为列值；也可以用UNION来实现

```sql
-- ## 行转列
-- 基于pivot
select a.stu_no, max(a.yuwen) as yuwen, max(a.shuxue) as shuxue, max(a.yingyu) as yingyu
from course pivot(max(course_score) for course_name in(yuwen,shuxue,yingyu)) a 
group by a.stu_no

-- 基于case when
select stu_no,
max(case course_name when 'yuwen' then course_score else 0 end) as 'yuwen',
max(case course_name when 'shuxue' then course_score else 0 end) as 'shuxue',
max(case course_name when 'yingyu' then course_score else 0 end) as 'yingyu'
from course group by stu_no

-- ## 列转行
select a.stu_no , a.course_name, a.course_score from course2 unpivot(course_score for course_name in(yuwen,shuxue,yingyu)) a

select t.stu_no, t.course_name, t.course_score from
(
	select stu_no, course_name='yuwen', course_score=yuwen from course2
	union all
	select stu_no, course_name='shuxue', course_score=shuxue from course2
	union all
	select stu_no, course_name='yingyu', course_score=yingyu from course2
) t order by t.stu_no, case t.course_name when 'yuwen' then 1 when 'shuxue' then 2 when 'yingyu' then 3 end
```

#### 拆分以逗号分隔的字符串为多行

- oracle参考下文[正则表达式 regexp_substr](#正则表达式)

## Mysql

### 常见问题

- 查询空格问题。如：`select * from test t where t.name = 'ABC';`和`select * from test t where t.name = 'ABC  ';`(后面有空格)结果一致，`ABC`和`ABC  `都可以查询到数据库中`ABC`的数据
	- 使用like：`select * from test t where t.name like 'ABC';`(不要加%，**使用`mybatis-plus`插件可开启字符串like查询**)
	- 使用关键字 binary：`select * from test t where t.name = binary'ABC';`
	- 使用length：`select * from test t where t.name = 'ABC' and length(t.name) = length('ABC');`
- **字段值不区分大小写问题(oracle默认区分大小写，sqlserver也不区分大小写)**
	- 如果字段为`utf8_general_ci`存储时，可以在字段前加`binary`强行要求此字段进行二进制查询，即区分大小写。如`select * from `t_test` where binary username = 'aezocn'`
	- **设置字段排序规则为`utf8_bin`/`utf8mb4_bin`**(`utf8_general_ci`中`ci`表示case insensitive，即不区分大小写)。设置成`utf8_bin`只是说字段值中每一个字符用二进制数据存储，区分大小写，显示和查询并不是二进制。设置成bin之后`select * from user t where name = 'Test';`区分大小写
- `null`判断问题
	- 判空需要使用`is null`或者`is not null`
	- `select * from t_test where username = 'smalle' and create_tm > '2000-01-01'` 直接使用 =、> 等字符比较，包含了此字段不为空的含义 
	- `select * from t_test where (username is not null or username != '')` 这样判断才能确保username不为空白字符串(**oracle的`''`和`null`相同，判断is not null即可**)
- `null`排序问题
	- 字段排序时，null默认最小
	- `select * from t_test order by username is null, username asc;` 此时先按照是否为null进行排序，是空的排在下面(返回1)
- 字段类型和大小
	- varchar(10)表示可以显示10个字符，字符集utf8时一个中文为一个字符。mysql的utf8编码最大只能存放3个字节；utf8mb4中mb4指most bytes 4，因此最大可以存放4个字节。中文有可能占用2、3、4个字节
- **`between...and` 左右边界都包含。**当处理时间时(类型为datetime)，语句`between '2018-10-01' and '2018-11-01'`，实际执行`between 2018-10-01 00:00:00 and 2018-11-01 00:00:00`，从而少算了11-1的数据。解决办法
    - 写全时分秒，2018-10-01 00:00:00至2018-10-01 23:59:59
    - 如果create_time类型为date(日期类型，而不是日期时间)，则使用between...and没什么问题
    - `date_format(a.create_time,'%Y-%m-%d') between '2018-10-01' and '2018-11-01'` 转成字符串进行比较
    - `between '2018-10-01' and date_add('2018-11-01', interval 1 day)` 多算了2018-11-02 00:00:00这一秒中的数据

### 关键字

### 常用函数

#### concat/concat_ws/group_concat

```sql
-- 将多个字符串连接成一个字符串。任何一个值为null则整体为null
concat(str1, str2,...)

-- 将多个字符串连接成一个字符串，但是可以一次性指定分隔符concat_ws就是concat with separator）
concat_ws(separator, str1, str2, ...)

-- 将group by产生的同一个分组中的值连接起来，返回一个字符串结果。类似oracle的wm_concat
-- 语法：group_concat( [distinct] 要连接的字段 [order by 排序字段 asc/desc ] [separator '分隔符(默认为,)'] )
-- group_concat默认限制长度为1024，可进行修改配置：https://blog.csdn.net/guo_qiangqiang/article/details/126528901
select userId, group_concat(orderId order by orderId desc separator ';') as orderList from t_orders group by userId;
```

#### instr/find_in_set

```sql
-- instr (oracle也支持)
    -- linux/unix下的行结尾符号是`\n`，windows中的行结尾符号是`\r\n`，Mac系统下的行结尾符号是`\r`
    -- 回车符：\r=0x0d (13) (carriage return)
    -- 换行符：\n=0x0a (10) (newline)
select * from t_test where instr(username, char(13)) > 0 or instr(username, char(10)) > 0; -- 查找表中某字段含有`\r\n`的数据

-- find_in_set
    -- type字段表示：1头条、2推荐、3热点。现在有一篇文章即是头条又是热点，即type=1,2
select * from article where find_in_set('2', type); -- 找出所有热点的文章

SELECT
    t.id, t.company_type -- customer,provider
    ,(select GROUP_CONCAT(d.name) from sys_dict d where d.parent_code = 'company_type' and FIND_IN_SET(d.code, t.company_type)) "企业类型" -- 客户,供应商
FROM rt_company t
group by t.id
```

#### 日期

```sql
-- sysdate
update t_test t set t.update_tm = sysdate() where id = 1; -- 其中`sysdate()`可获取当前时间
```

#### with as

- 参考下文[with-as用法](#with-as用法)

#### RECURSIVE CTE递归

- Mysql 8.0才支持此语法

```sql
SELECT t.* FROM (
    WITH RECURSIVE cte (`id`, `parent_id`, `depth`, `path`) AS (
        SELECT `id`, `parent_id`, 1 AS `depth`, CONCAT(' ' , `name`) AS `path`
        FROM `pt_permission`
        WHERE `parent_id` = 0
        UNION ALL
        SELECT t.`id`, t.`parent_id`, `depth` + 1, CONCAT(cte.`path`, ' > ', ' ' , t.`name`)
        FROM `pt_permission` t
        INNER JOIN cte ON cte.`id` = t.`parent_id`
    )
    SELECT * FROM cte
) t
ORDER BY t.`path` ASC;

-- 显示效果
id                  parent_id           depth   path
1676821713360293890	0	                1	    一级权限1
1676823255891087361	0	                1	    一级权限2
1676823326061793281	1676823255891087361	2	    一级权限2 >  二级权限21
1676836467395039233	1676823326061793281	3	    一级权限2 >  二级权限21 >  三级权限211
1676823380998787073	1676823255891087361	2	    一级权限2 >  二级权限22
1676832879327350785	1676823255891087361	2	    一级权限2 >  二级权限23
1676823277630164993	0	                1	    一级权限3
1676833272383967233	1676823277630164993	2	    一级权限3 >  二级权限31
```

### 自定义变量

- 自定义变量的限制
    - 无法使用查询缓存
    - 不能在使用常量或者标识符的地方使用自定义变量，例如表名、列名或者limit子句
    - 用户自定义变量的生命周期是在一个连接中有效，所以不能用它们来做连接间的通信
    - 不能显式地声明自定义变量地类型
    - mysql优化器在某些场景下可能会将这些变量优化掉，这可能导致代码不按预想地方式运行
    - 赋值符号：=的优先级非常低，所以在使用赋值表达式的时候应该明确的使用括号
    - 使用未定义变量不会产生任何语法错误
    - 用户自定义变量只在session有效，退出后数据丢失
- 自定义变量的使用案例

    ```sql
    -- 自定义变量的使用(@@为系统自定义变量)
    set @one :=1;
    select @one;
    set @min_actor :=(select min(actor_id) from actor);
    set @last_week :=(current_date-interval 1 week);
    -- 在给一个变量赋值的同时使用这个变量
    select actor_id,@rownum:=@rownum+1 as rownum from actor limit 10;

    -- 避免重新查询刚刚更新的数据。eg:当需要高效的更新一条记录的时间戳，同时希望查询当前记录中存放的时间戳是什么
    update t1 set lastUpdated=now() where id =1;
    select lastUpdated from t1 where id =1;
    -- 优化后：避免重新查询刚刚更新的数据
    update t1 set lastupdated = now() where id = 1 and @now:=now();
    select @now;

    -- 注意where和select在查询的不同阶段执行
    set @rownum:=0;
    select actor_id,@rownum:=@rownum+1 as cnt from actor where @rownum<=1; -- 有问题的
    select actor_id,@rownum as cnt from actor where (@rownum:=@rownum+1)<=1;
    ```

### JSON数据类型

- 参考官网：https://dev.mysql.com/doc/refman/5.7/en/json.html、https://dev.mysql.com/doc/refman/5.7/en/json-functions.html
    - json_unquote 去掉了引号和转义符(和`->`结合使用等同于`->>`)
    - json_extract 基于path提取json字段值(类似`->`)
    - json_contains
    - json_object 字符串转json对象 `select json_object('a', 1, 'b', 'b1'); -- {"a": 1, "b": "b1"}`
    - json_array 字符串转json数组
    - json_table json转成临时表
    - json_set 修改json
- 参考：https://www.cnblogs.com/zhusf/p/15704599.html

```sql
-- 创建数据类型为json的字段val（如果字段类型为字符串也是可以使用相关函数的，只不过存在隐式转换；且如果类型是json，则在插入数据时会进行格式校验）
create table test (val json);
insert into test(val) values('{"name": "smalle", "hello": "Hi, \\"AEZO\\"", "hobby": [{"item": {"name": "book", "weight": 5}}, "game"], "attr": {"t1": "v1", "t2": [1, true, false]}}');
/*
{
  "attr": {
    "t1": "v1",
    "t2": [
      1,
      true,
      false
    ]
  },
  "name": "smalle",
  "hello": "Hi, \"AEZO\"",
  "hobby": [
    {
      "item": {
        "name": "book",
        "weight": 5
      }
    },
    "game"
  ]
}
*/

-- 查询
select val from test; -- {"attr": {"t1": "v1", "t2": [1, true, false]}, "name": "smalle", "hello": "Hi, \"aezo\"", "hobby": [{"item": {"name": "book", "weight": 5}}, "game"]}
-- 可以使用column-path运算符 ->
select val->"$.hello" from test; -- "Hi, \"aezo\""
-- 或内联路径运算符 ->> (去掉了引号和转义符)。可能由于服务器no_backslash_escapes的配置导致无法使用 ->>，可如下使用 json_unquote + json_extract
select val->>"$.hello" from test; -- Hi, "aezo"
select json_unquote(val->"$.hello"), json_unquote(val->"$.hobby[0]") from test; -- Hi, "aezo"
select json_length('[1,2,{"a":3}]'); -- 3 获取数组长度，不计算嵌套的长度

-- (推荐)搜索. json_extract类似->
select json_unquote(json_extract(val, '$.*')) from test; -- 将所有一级key对应的值放入到数组中：[{"t1": "v1", "t2": [1, true, false]}, "smalle", "Hi, \"AEZO\"", [{"item": {"name": "book", "weight": 5}}, "game"]]
select json_unquote(json_extract(val, '$.name')) from test; -- smalle
select json_unquote(json_extract(val, '$.hobby[0].item')) from test; -- {"name": "book", "weight": 5}
select json_unquote(json_extract(val, '$**.name')) from test; -- 返回所有最底相应key值：["smalle", "book"]
select json_unquote(json_extract(val, '$.hobby[*].item.*')) from test; -- ["book", 5]
select json_unquote(json_extract(val->'$.hobby', '$[0].item.name')) from test; -- book
select json_unquote(json_extract('[1, 2, 3]', '$[0]')); -- 1

-- 数组处理
select json_array_insert('["a",["b","c"],"d"]','$[1][1]',3), json_array_append('["a",["b","c"],"d"]','$[1][0]',3); -- ["a", ["b", 3, "c"], "d"]     ["a", [["b", 3], "c"], "d"]
select json_replace('[1,2]', '$[1]', json_object('a', 1)); -- [1, {"a": 1}]

-- 如果存放json的字段类型为字符串，取出数据时可进行转换编码
select convert(json_unquote(json_extract('["张三", "李四"]', '$[0]')) using utf8mb4); -- 张三


-- json转成临时表
select * from
json_table ('[{"a": 1, "b": [11,111]}, {"a": 2, "b": [22,222]}, {"a":3}]',
    -- $[*]表示对JSON数组每一项进行处理
    '$[*]' columns (
        id for ordinality, -- 自增ID
        a int path '$.a',
        nested path '$.b[*]' columns (b int path '$') 
    )
) t where b is not null;
-- 结果
+------+------+
|   a  |   b  |
+------+------+
|    1 |   11 |
|    1 |  111 |
|    2 |   22 |
|    2 |  222 |
+------+------+


-- 修改json
select json_set(
    '{"name":{"en":"约翰"},"age": 25}',
    '$.name.en', (select translation from translations where text='john' and language='en'),
    '$.age', 18
) as translated_json;
update t_user set json_info = json_set(ifnull(json_info, '{}'), '$.age', 18) where id = 1;

-- 数组案例: 记录位置信息(保留最近12次)
update user_info set location_up_time = now()
,location_up_json = (
	case when location_up_json is null then concat('[{"la": ', #{latitude},', "lo": ', #{longitude},', "s": ', #{speed},', "t": "', now(),'"}]')
        when json_length(location_up_json) &lt; 12 then json_array_insert(location_up_json, concat('$[', json_length(location_up_json), ']'), json_object('la', #{latitude}, 'lo', #{longitude}, 's', #{speed}, 't', concat(now(), '')))
        else json_array_insert(json_remove(location_up_json, '$[0]'), concat('$[', json_length(location_up_json) - 1, ']'), json_object('la', #{latitude}, 'lo', #{longitude}, 's', #{speed}, 't', concat(now(), '')))
    end
)
where id = 1
```

### 定时任务(事件)

- 可基于Navicat或者手动执行SQL创建任务
    - 参考：https://www.cnblogs.com/JamelAr/p/16612820.html

```sql
-- 创建数据全局(mysql)定时任务日志表(可选)
create table `mysql`.`t_event_history` (
  `db_name` varchar(128) not null default '',
  `event_name` varchar(128) not null default '',
  `start_time` datetime not null default current_timestamp,
  `end_time` datetime default null,
  `is_success` int(11) default null,
  `duration` int(11) default null, -- 执行秒数
  `error_message` varchar(512) default null,
  `rand_no` int(11) default null,
  `data` varchar(512) default null,
  primary key (`db_name`,`event_name`,`start_time`),
  key `ix_end_time` (`end_time`),
  key `ix_starttime_randno` (`start_time`,`rand_no`)
) engine=innodb default charset=utf8;


-- 创建定时任务
-- Navicat事件新增时，除了输入定义、还需输入计划(如: Every 1 HOUR, START 2100-01-01 00:00:00), interval 表示延迟多长时间后开始执行/结束
delimiter $$
create event `e_sum_test_month`
    on schedule 
    every 30 minute starts '2023-05-10 23:30:00' ends '2023-05-11 12:00:00'
    on completion preserve -- on completion [not] preserve: 当event到期了,event会被disable,但是该event还是会存在,否则event会自动删除掉
    enable -- [enable | disable | disable on slave(表示事件在从机中是关闭)]
    comment '这是注释'
    do
-- Navicat事件新增界面-定义 START
begin
    declare v_start_date varchar(100);
    declare v_count int(11);

    -- 记录日志相关变量
	declare r_code char(5) default '00000';
	declare r_msg text;
	declare v_error integer;
	declare v_start_time datetime default now();
	declare v_rand_no integer default floor(rand()*100001);
	
	insert into mysql.t_event_history (db_name,event_name,start_time,rand_no) values(database(),'e_sum_test_month', v_start_time,v_rand_no);
	
    begin
        -- 异常处理段
        declare continue handler for sqlexception  
        begin
            set v_error = 1;
            get diagnostics condition 1 r_code = returned_sqlstate , r_msg = message_text;
        end;
        
        -- 此处为实际调用的用户程序过程 START
        -- 以[基于月份进行循环处理](/_posts/db/sql-procedure.md#基于月份进行循环处理)为例
        select t.note into v_start_date from t_dict t where t.`code` = 'p_sum_test_month' and t.status = 0; -- 获取当前过程的起始日期
        if v_start_date is not null then
            update t_dict set `status` = 1, input_tm = now() where `code` = 'p_sum_test_month'; -- 当前过程正在执行中
            
            select datediff(last_day(v_start_date), v_start_date) + 1 into v_count; -- 当月天数
            
            update mysql.t_event_history set data = concat('v_start_date=', v_start_date, ', v_count=', v_count) where start_time=v_start_time and rand_no=v_rand_no; -- 记录执行数据
            
            call p_sum_test_month(str_to_date(concat(v_start_date, ' 00:00:00'), '%y-%m-%d %h:%i:%s'), 1, v_count); -- 调用存储过程
            
            update t_dict set status = 0, note = date_format(date_add(str_to_date(v_start_date, '%y-%m-%d')-day(str_to_date(v_start_date, '%y-%m-%d'))+1,interval 1 month),'%y-%m-%d'), update_tm = now() where `code` = 'p_sum_test_month'; -- 记录下一次执行的起始时间
        else
            set v_error = 2;
            set r_msg = '前一次仍在执行，本次忽略';
        end if;
        -- 此处为实际调用的用户程序过程 END
    END;
	
	update mysql.t_event_history set end_time=now(),is_success=isnull(v_error),duration=timestampdiff(second,start_time,now()), error_message=concat('error=',r_code,', message=',r_msg),rand_no=null
    where start_time=v_start_time and rand_no=v_rand_no;
end
-- Navicat事件新增界面-定义 END
$$
delimiter ;


-- 查看所有事件. 如果 last_executed 字段有更新说明事件是执行了的, 如果事件中存在错误代码(报错)是不能直接查看到日志的
select * from mysql.event;

-- 启用/禁用当前定时任务
alter event e_sum_test_month on completion preserve enable;
alter event e_sum_test_month on completion preserve disable;

-- 查看/开启/关闭事件配置(mysql默认是关闭的，需先开启，定时任务才会自动执行)
-- 防止mysql重启失效，需将 `event_scheduler=1` 配置到 my.ini
select @@event_scheduler; -- 或 show variables like 'event%';
set global event_scheduler = on;
set global event_scheduler = off;
```

## Oracle

- [在线演示环境](https://livesql.oracle.com/)

### 常用函数

#### decode和case when

- `decode(被判断表达式, 值1, 转换成值01, 值2, 转换成值02, ..., 转换成默认值)` 只能判断=，不能判断like(like可考虑case when)
	- `select decode(length(ys.ycross_x), 1, '0' || ys.ycross_x, ys.ycross_x) from ycross_storage ys` 如果ys.ycross_x的长度为1那就在前面加0，否则取本身
	- `select sum(decode(shipcomp.company_num, 'CMA', 1, 0)) cma, sum(decode(shipcomp.company_num, 'MSK', 1, 0)) msk from ycross_in_out_regist yior ...(省略和shipcomp的关联)` 统计进出场记录中cma和msk的数量
	- `order by decode(col, 'b', 1, 'c', 2, 'a', 3, col)` 按值排序
- `case when then [when then ...] else end` 比decode强大
	- `case when t.name = 'admin' then 'admin' when t.name like 'admin%' then 'admin_user' else decode(t.role, 'admin', 'admin', 'admin_user') end`
	- `sum(case when yior.plan_classification_code = 'Empty_Temporary_Fall_Into_Play' and yardparty.company_num = 'DW1' then 1 end) as count_dw1` sum写在case里面则需要对相关字段(plan_classification_code)进行group by，而sum写外面则不需要对此字段group by. **主要用于分组之后根据条件分列显示**

#### rollup

- `group by rollup` 分组统计
- `grouping(col)` 判断某列是否为分组列，是则返回1否则返回0
- `group_id()` 相同分组出现的次数，可以用于过滤重复数据
- `grouping_id(col1, col2, ...)` 如grouping_id(a, b)小计返回1，总计返回3，其他返回0

```sql
select
    decode(grouping(a)+grouping(b),1,'小计',2,'总计',a) a
    ,decode(grouping(b),1,count(*)||'条',b) b
    ,c, d, sum(n)
    ,group_id() gid
    ,grouping_id(a, b, c) ing
from (
    select 1 as a, 2 as b, 'C1' as c, 'D1' as d, 5 as n from dual
    union all
    select 2 as a, 1 as b, 'C2' as c, 'D2' as d, 1 as n from dual
)
-- group by rollup(a, b, c, d) -- 会在结果集中添加(A,B,C,D)、(A,B,C)、(A,B)、(A)、(null) 5种统计数据(单不是增加5行)
group by rollup(a, b, (c, d)) -- 会在结果集中添加 (A,B,C,D)、(A,B)、(A)、(null) 4种统计数据
-- group by rollup((a, b, c, d)) -- 会在结果集中添加 (A,B,C,D)、(null) 2种统计数据
```
- 结果

| A    | B    | C    | D    | SUM\(N\) | GID | ING |
| :--- | :--- | :--- | :--- | :------- | :-- | :-- |
| 1    | 2    | C1   | D1   | 5        | 0   | 0   |
| 1    | 2    | NULL | NULL | 5        | 0   | 1   |
| 小计  | 1 条 | NULL | NULL | 5        | 0   | 3   |
| 2    | 1    | C2   | D2   | 1        | 0   | 0   |
| 2    | 1    | NULL | NULL | 1        | 0   | 1   |
| 小计  | 1 条 | NULL | NULL | 1        | 0   | 3   |
| 总计  | 2 条 | NULL | NULL | 6        | 0   | 7   |

#### trunc时间处理

```sql
select trunc(sysdate-1, 'dd'), trunc(sysdate, 'dd') from dual; -- 返回昨天和今天（2018-01-01, 2018-01-02）
```

#### 字符串处理

```sql
-- length 获取字符长度; lengthb 基于字符获取长度
select length('你'), lengthb('你'), lengthb('你123Abc'), substr('你123', 1, 3), substrb('你123', 1, 3) from dual; -- 1 3 9 你12 你

-- trim 去除空格
-- 语法 select trim(leading | trailing | both string1 from string2) from dual;
select trim(' a b ') from dual; -- "a b"
select trim(leading 'a' from 'aa ab ') from dual; -- " ab "
-- 同理ltrim去除左侧空格；ltrim/rtrim 还支持第二个参数
select rtrim(' a b ') from dual; -- " a b"

-- replace 字符串替换
select replace('#ID#', '#') from dual; -- ID
select replace('#ID#', '#', '*') from dual; -- *ID*

-- instr 查找字符位置(mysql也支持) / 查找子字符串 / 判断字符串包含
select instr('#ID#', '@'), instr('#ID#', '#'), instr('#ID#', '#', 2) from dual; -- 0, 1, 4

-- substr 截取字符串; 对应基于字符的则是 substrb
select substr('hello sql!', 2) from dual; --从第2个字符开始，截取到末尾。返回 'ello sql!'
select substr('hello sql!', 3, 6) from dual; --从第3个字符开始，截取6个字符。返回 'llo sq'
select substr('hello sql!', -4, 3) from dual; --从倒数第4个字符开始，截取3个字符。返回 'sql'
select substr('hello sql!', 1, length('hello sql!') - 1) from dual; -- 返回 'hello sql'

-- 不足5位的前面补零
select lpad(123, 5, '0') from dual; -- 00123
```

#### with-as用法

- 特点
    - 特别是从多张表中取数据时，而且每张表的数据量又很大时，使用with写法可以先筛选出来一张数据量较少的表，避免全表join
    - 可认为在真正进行查询之前预先构造了一个临时表，之后便可多次使用它做进一步的分析和处理。一次分析，多次使用
- mysql版本在8.0之前不能使用with的写法；8.0之后写法同oracle
- 语法(oracle/mysql均支持)
    - 前面的with子句定义的查询在后面的with子句中可以使用，但是一个with子句内部不能嵌套with子句
    - from后面必须直接紧跟使用with as出来的表，否则需要使用join将with as出来的表关联进来；在子查询中也是这样
    - with必须开头，不能出现`select 1 from dual union all with ...`

```sql
-- 针对多个别名，e,d为“别名表”
with
     e as (select * from scott.emp),
     d as (select * from scott.dept)
select * from e, d where e.deptno = d.deptno;

-- from后面必须直接紧跟使用with as出来的表，否则需要使用join将with as出来的表关联进来
with temp as (select t.create_tm from user t where t.id = 1)
select temp.*
from dual -- from其他表时，必需要使用join将with as出来的表关联进来
full join temp on 1=1
where temp.create_tm > sysdate-7;

WITH
ASSIGN(ID, ASSIGN_AMT) AS (
    SELECT 1, 25150 FROM DUAL 
    UNION ALL SELECT 2, 19800 FROM DUAL
    UNION ALL SELECT 3, 27511 FROM DUAL
)
select * from ASSIGN;
```

#### 聚合函数(aggregate_function)

- `min`、 `max`、`sum`、`avg`、`count`、`variance`、`stddev` 
- `count(*)`、`count(1)`、`count(id)`、`count(name)` **统计行数，不能统计值的个数**。count(name)，如果有3行，但是name有值的只有2行时结果仍然为3

##### wm_concat行转列

- 为oracle内部函数，**12之后已经去掉了此函数**
- 行转列，会把多行转成1行(默认用`,`分割，select的其他字段需要是group by字段)
- 案例
    - `wm_concat(t.hobby)`
    - `wm_concat(distinct t.hobby)` 支持去重
    - `select replace(to_char(wm_concat(name)), ',', '|') from test;`替换分割符(默认为英文逗号)
- 自从oracle **`11.2.0.3`** 开始`wm_concat`返回的是LOB(CLOB)字段导致部分查询需要进行修改。参考：https://www.cnblogs.com/wsxdev/p/15416946.html
    - 可使用to_char转换成varchar类型
        - 虽然在wm_concat()函数外层包了一层to_char()函数，避免使用了LOB类型；但是由于wm_concat()函数的返回值类型LOB类型是不能进行group by、distinct以及union共存的，因此会偶发ORA-22922:错误。这里需要注意的是，是偶发，不是必然
    - 也可在应用中处理clob直接返回到前台报错问题
        - 可通过`clob.getSubString(1, (int) clob.length())`解决

            ```java
            // JDBC
            Object object = resultSet.getObject(i);
            if(object != null) {
                if(object instanceof java.sql.Clob) {
                    java.sql.Clob clob = (java.sql.Clob) object;
                    object = clob.getSubString(1, (int) clob.length());
                }
            }

            // Mybatis处理
            // https://juejin.cn/s/mybatis%20clob%20to%20string
            // https://blog.csdn.net/lizhengyu891231/article/details/132434605
            ```
        - 或者使用jackson转换器，参考：https://oomake.com/question/13622930、https://segmentfault.com/a/1190000040484998
    - 也可使用[listagg within group行转列](#listagg-within-group行转列)解决返回值为LOB的问题(但是长度最大为4000)
    - 如果长度超过4000个字符，使用to_char会报错缓冲区不足，可以使用 [xmlagg](#xmlagg行转列) 函数代替(但不支持去重)。参考：https://www.cxybb.com/article/qq_28356739/88626952
        - druid使用内置SQL解析工具类时，无法解析xmlagg函数，参考(测试无效)：https://github.com/alibaba/druid/issues/4259

##### xmlagg行转列

- 最大容量为4G，但是不支持去重

```sql
-- 解决缓冲区问题：不使用to_char函数，在Java中需要用java.sql.Clob类，进行数据的接收与转换
select
    xmlagg(xmlparse(content 合并字段 || ',' wellformed) order by 排序字段).getclobval() "my_col"
from test;

select
    -- to_char有4000个字符缓存区限制（如果超过4000个字符则转成to_char失败）
    to_char(xmlagg(xmlparse(content 合并字段 || ',' wellformed) order by 排序字段).getclobval()) "my_col"
from test;
```

##### listagg-within-group行转列

- listagg最大容量为4000
- mysql可使用group_concat

```sql
-- 查询部门为20的员工列表
select
	t.deptno,
    -- listagg 可理解为wm_concat；而 within group 表示对每一组的元素进行操作，此时是基于 t.ename 进行排序(即排序后再调用listagg)
	listagg(t.ename, ',') within group (order by t.ename) names -- 返回 ADAMS,FORD,JONES 即将多行显示在一列中
from scott.emp t
where t.deptno = '20'
group by t.deptno
```

#### 分析函数

##### 常见分析函数

- `min`、`max`、`sum`、`avg` **一般和over/keep函数联合使用** [^3]
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

##### connect by 递归关联

- mysql参考: [RECURSIVE递归](#RECURSIVE递归)
- `start with connect by prior` 递归查询(如树形结构)

```sql
select t.id, t.pid
connect_by_root(t.id) root_id, -- 显示根节点列. 写成 `connect_by_root t.id root_id` PL/SQL也是可以的，但是Durid解析的时候可能会报错
connect_by_root(t.name) root_name -- 显示根节点名称 
from my_table t 
start with t.pid = 1 -- 基于此条件进行向下查询(省略则表示基于全表为根节点向下查询，可能会有重复数据)
-- connect by nocycle -- 递归条件(递归查询不支持环形。此处nocycle表示忽略环，如果确认结构中无环形则可省略。有环形则必须加，否则报错); connect_by_iscycle 在有循环结构的查询中使用。
prior t.id = t.pid -- 增加递归条件，或者 add prior。也可自递归，如 t.id = t.id
-- add prior level <= regexp_count(t.names, '[^,]+') -- level为当前递归层级(顶层为1)，此条件无实际意义，仅为了展示其语法功能
where t.valid_status = 1 -- 将递归获取到的数据再次过滤
-- order siblings by id desc -- siblings 保留树状结构，对兄弟节点进行排序

-- 三级权限
select
connect_by_root (t.id) "一级权限id"
,case when level = 1 then connect_by_root (t.permission_name) end "一级权限名称"
,case when level = 2 then t.id when level = 3 then prior t.id end "二级权限id"
,case when level = 2 then t.permission_name end "二级权限名称"
,case when level = 3 then t.id end "三级权限id"
,case when level = 3 then t.permission_name end "三级权限名称"
,level "层次"
,sys_connect_by_path(id, '->') "层次结构"
,decode(connect_by_isleaf, 1, '是', '否') "是否子孙节点"
,opm.OPERATOR_ID "用户拥有此权限"
from s_operator_permission t
left join s_operator_permission_mapper opm on opm.permission_id = t.id and opm.operator_id = 1 -- 用户ID=1的权限映射
start with t.parent_id = 0
connect by nocycle
prior t.id = t.parent_id
```

##### over

- **Mysql也支持**
- 分析函数和聚合函数的不同之处是什么：普通的聚合函数用**group by分组，每个分组返回一个统计值**，而分析函数采用**partition by分组，并且每组每行都可以返回一个统计值** [^1]
- 开窗函数`over()`，跟在分析函数之后，包含三个分析子句。形式如：`over(partition by xxx order by yyy rows between aaa and bbb)` [^2] 
    - 子句类型
        - 分组子句(partition by)
        - 排序子句(order by)
        - 窗口子句(rows)：窗口子句包含rows、range和滑动窗口
            - 窗口子句不能单独出现，必须有`order by`子句时才能出现
            - 取值说明
                - `unbounded preceding` 第一行
                - `current row` 当前行
                - `unbounded following` 最后一行
    - 省略分组字句：则把全部记录当成一个组
        - 如果此时存在`order by`，则窗口默认(省略窗口时)为当前组的第一行到当前行(unbounded preceding and current row)
        - 如果此时不存在`order by`，则窗口默认为整个组(unbounded preceding and unbounded following)
    - 省略窗口字句
        - 如果此时**存在**`order by`，**则窗口默认是当前组的第一行到当前行**(不是整个组,是全量数据)
            - 出现`order by`子句的时候，不一定要有窗口子句(窗口子句不能单独出现，必须有`order by`子句时才能出现)
        - 如果此时**不存在**`order by`，**则窗口默认是整个组**
        - 示例（示例和图片来源：http://www.cnblogs.com/linjiqin/archive/2012/04/05/2433633.html）
            - 在线测试地址: https://livesql.oracle.com/
            
            ```sql
            -- 见图oracle-over-1: sql无排序, over排序子句省略
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno) from emp;
            -- (一般不推荐使用, 实际显示值和常规思路预期的不一致)
            -- 见图oracle-over-2: sql无排序, over排序子句有, 窗口省略
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno order by sal desc) from emp;
            -- sql无排序, over()排序子句有, 窗口也有(窗口特意强调全组数据)
            select deptno, empno, ename, sal,
                last_value(sal) over(partition by deptno order by sal desc 
                    rows between unbounded preceding and unbounded following) max_sal
            from emp;
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
  from (
    select ys.id
        ,count(yvmp.venue_move_plan_id) over(partition by ys.id) as total
        ,first_value(yvmp.venue_move_plan_id) over(partition by yvmp.storage_id order by yvmp.input_tm ASC rows between unbounded preceding and unbounded following) as first_id
    from ycross_storage ys -- 场存表
    left join yyard_venue_move_plan yvmp -- 移动表
        on yvmp.storage_id = ys.id and yvmp.yes_status = 0
  ) t
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
        -- *********错误sql一*********。(和group by混淆)
        select
        row_number() over(partition by v.customer_id, v.visit_type order by v.id desc) as rn
        -- *********错误sql一*********
        ,first_value(v.id) over(partition by v.customer_id, v.visit_type order by v.id desc) as id -- 只取一个ID也是重复的
        ,first_value(v.customer_id) over(partition by v.customer_id, v.visit_type order by v.id desc) as customer_id
        ,first_value(v.visit_type) over(partition by v.customer_id, v.visit_type order by v.id desc) as visit_type
        ,first_value(v.comments) over(partition by v.customer_id, v.visit_type order by v.id desc) as comments
        ,first_value(v.visit_tm) over(partition by v.customer_id, v.visit_type order by v.id desc) as visit_tm
        from t_visit v
        where v.valid_status = 1 and v.result is not null 
        and v.customer_id = 358330;
        -- 结果
        #   RN
        1	1	93179	358330	BS	BS-3	2018/9/20
        2	2	93179	358330	BS	BS-3	2018/9/20
        3	3	93179	358330	BS	BS-3	2018/9/20
        4	1	93252	358330	IS	IS-2	2018/10/8
        5	2	93252	358330	IS	IS-2	2018/10/8
        
        -- *********错误sql二*********。此时报max(v.id)中的id不是group by字句（使用keep的话也会有这个错）
        select
        max(v.id) over(partition by v.customer_id, v.visit_type order by v.id desc) as id -- max(v.id)：ORA-00979 not a group by expression
        -- *********错误sql一*********
        from t_visit v
        where v.valid_status = 1 and v.result is not null 
        and v.customer_id = 358330
        group by v.customer_id, v.visit_type

        -- 可再次group by；或者使用row_number()再加子查询rn=1获取最大最小值

        -- =============== 使用 Keep ===============
        -- Keep测试一(基于主表group by)。参考下文[keep](#keep)
        -- Keep测试二(基于over的partition by)。参考下文[keep](#keep)
        ```
##### keep

- keep的用法不同于通过over关键字指定的分析函数，可以用于这样一种场合下：**取同一个分组下以某个字段排序后，对指定字段取最小或最大的那个值。**从这个前提出发，我们可以看到其实这个目标通过一般的row_number分析函数也可以实现，即指定rn=1。但是，该函数无法实现同时获取最大和最小值。或者说用first_value和last_value，结合row_number实现，但是该种方式需要多次使用分析函数，而且还需要套一层SQL。于是出现了keep [^6]
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
    - `dense_rank first`，`dense_rank last`为keep函数的保留属性
        - dense_rank first 表示取分组-排序结果集中第一个(dense_rank值排第一的。可能有几行数据排序值一样，此时再可配合min/max等聚合函数取值)
        - dense_rank last 同理，为最后一个
- **Keep测试一(基于主表group by，如取最大最小值)**，场景参考上文[over使用误区](#over使用误区)

```sql
-- *****Keep测试一(基于主表group by)*****：如查分组中最新的数据(非分组字段通过keep获取，如果同最近的ID再次管理表则效率低一些)
select
v.customer_id, v.visit_type
-- 在每一组中按照v.visit_tm排序计数(BS那一组排序值为 1-1-2. 因为存在两个拜访时间2018/9/21一样，因此排序值都为1，当遇到不同排序值+1)，并取第一排序集(1-1的两条记录)中v.id最大的
,max(v.id) keep(dense_rank first order by v.visit_tm desc) as id
,max(v.visit_tm) keep(dense_rank first order by v.visit_tm desc) as visit_tm
,max(v.comments) keep(dense_rank first order by v.visit_tm desc) as comments
-- 排序值为 1-2-3
,max(v.visit_tm) keep(dense_rank first order by v.id desc) as visit_tm_id
from t_visit v
where v.valid_status = 1 and v.result is not null 
and v.customer_id = 358330
group by v.customer_id, v.visit_type; -- 先分成了两组(最终只有两组的统计值，两行数据)
-- 结果(注意第一行数据)
#
1	358330	BS	93165	2018/9/21	BS-2	2018/9/20
2	358330	IS	93252	2018/10/8	IS-2	2018/10/8

-- 案例：查询每个提单CN1101的发送情况：可在max和keep语句中使用case when进行分组后数据过滤
select sb.bill_no
    -- max中不能省略case when过滤：否则可能其他提单也会显示成了最大的一个eh.id对应的值，因为每一组bill_no都对应了所有的子表数据，此时加case when可进行过滤
    ,max(case when eh.edi_code = 'CN1101' and ell.bill_nbr is not null then eh.send_method else -1 end)
    -- keep中不能省略case when过滤：否则取到的第一组永远是最大的一个eh.id，可能是其他提单发送的
    keep(dense_rank first order by case when eh.edi_code = 'CN1101' and ell.bill_nbr is not null then eh.id else -1 end desc) as edi_send_method
FROM ship_bill sb
    -- 一个提单可能存在CN1101、IFCTST两种EDI，且此时是基于船号进行关联，从而可能会关联到其他提单的发送记录
    -- 此处不能使用join，否则业务上可能漏掉了提单
LEFT JOIN s_edi_head eh ON eh.business_no = sb.ship_no and eh.valid_status = 1 and eh.edi_code in ('CN1101', 'IFCTST')
    -- 一个报文中包含的提单
LEFT JOIN edi_log_bill ell ON ell.edi_id = eh.id and sb.bill_nbr = ell.bill_nbr
WHERE sb.ship_no = 55265 
group by sb.bill_no
```
- Keep测试二(基于over的partition by)，场景参考上文[over使用误区](#over使用误区)

  ```sql
  -- 查询每个客户的默认地址：t_customer数据条数 28.9w, t_customer_address数据条数 36.8w。(注：此测试实际场景为两张表除了主键，无其他外键和索引)
  select tmp_page.*, rownum row_id from ( -- 分页
    select t.* from ( -- 写法 2(推荐)
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

- 参考：https://www.cnblogs.com/qmfsun/p/4467904.html
- 正则函数
	- `regexp_like` (匹配)比较一个字符串是否与正则表达式匹配
        - `(srcstr, pattern [, match_option])`
	- `regexp_instr` (包含)在字符串中查找正则表达式，并且返回匹配的位置
        - `(srcstr, pattern [, position [, occurrence [, return_option [, match_option]]]])`
	- `regexp_substr` (提取) 返回与正则表达式匹配的子字符串
        - `(srcstr, pattern [, position [, occurrence [, match_option]]])`
    - `regexp_replace` (替换)搜索并且替换匹配的正则表达式
        - `(srcstr, pattern [, replacestr [, position [, occurrence [, match_option]]]])`
            - srcstr: 被查找的字符数据  
            - pattern: 正则表达式
            - position: 搜索在字符串中的开始位置。如果省略，则默认为1，这是字符串中的第一个位置
            - occurrence: 它是模式字符串中的第n个匹配位置。如果省略，默认为1
            - return_option: 默认值为0，返回该模式的起始位置；值为1则返回符合匹配条件的下一个字符的起始位置 
            - replacestr: 用来替换匹配模式的字符串 
            - match_option: 匹配方式选项。缺省为c  
                - c：case sensitive  
                - I：case insensitive  
                - n：(.)匹配任何字符(包括newline)  
                - m：字符串存在换行的时候被作为多行处理

```sql
-- 分割函数：基于,分割，返回3行数据
select regexp_substr('17,20,23', '[^,]+', 1, level, 'i') as str from dual
  connect by level <= length('17,20,23') - length(regexp_replace('17,20,23', ',', '')) + 1;

-- 正则替换只保留数字
select regexp_replace('1-2 ', '[^0-9]+', '') as str from dual; -- 12

-- 正则替换中文、\、`为空格，并取256位长度
select substr(regexp_replace('中文A\B`C', '[' || unistr('\4e00') || '-' || unistr('\9fa5') || '\\`]', ' '), 0, 256)
as rx_replace from dual;

-- 匹配纯数字
regexp_like(income,'^(\d*)$')
not regexp_like(income,'^(\d*)$') -- 匹配非纯数字
regexp_like(data,'^[0-9]{3}$') -- 3位纯数字
-- 匹配金额
regexp_like(income,'^-?([[:digit:]]*.[[:digit:]]*)$')
regexp_like(income,'^-?(\d*.\d*)$')
regexp_like(income,'^-?([0-9]*.[0-9]*)$')

-- 分别返回17 20 23
-- select regexp_instr('17,20,23', ',') from dual; -- 返回3
-- select regexp_instr('17,20,23', ',', 1, 2) from dual; -- 返回6
-- select regexp_instr('17,20,23', ',', 1, 3) from dual; -- 返回0
select substr('17,20,23', 1, regexp_instr('17,20,23', ',') - 1) from dual; -- 返回17
select substr('17,20,23', regexp_instr('17,20,23', ',') + 1, regexp_instr('17,20,23', ',', 1, 2) - regexp_instr('17,20,23', ',') - 1) from dual; -- 返回20
select substr('17,20,23', regexp_instr('17,20,23', ',', 1, 2) + 1, length('17,20,23') - regexp_instr('17,20,23', ',')) from dual; -- 返回23
```

#### 案例

##### 查找字表最新的一条记录

```sql
-- 基于 keep
select v.customer_id, v.visit_type
,max(v.id) keep(dense_rank first order by v.visit_tm desc) as id
,max(v.visit_tm) keep(dense_rank first order by v.visit_tm desc) as visit_tm
-- ,max(v.visit_tm) keep(dense_rank first order by v.id desc) as visit_tm_id
from t_visit v
where 1=1
and v.customer_id = 358330
group by v.customer_id, v.visit_type; -- 先分成了两组(最终只有两组的统计值，两行数据)


-- 子表基于 row_number
select c.id, s.score
from t_class c
left join (
    select * from (
        select row_number() over(partition by s.class_id order by s.score desc) rn, s.*
        from t_student s
    ) where rn = 1
) s on s.class_id = c.id;
```

##### 查找中文

- `select * from t_customer t where asciistr(t.customer_name) like '%\%' and instr(t.customer_name, '\') <= 0;`

##### 一个字段存多个ID进行联表查询 

- 参考[connect by 递归关联](#connect%20by%20递归关联) [^9]

```sql
-- 也可将,进行分割后使用in进行联表查询，但是效率比此方法低很多
WITH user_info_temp as (
	SELECT
    ui.id,
	ui.username,
    ui.hobby_id
	LEVEL C_LEVEL,
	REGEXP_SUBSTR(ui.hobby_id, '[^,]+', 1, LEVEL) hobby_id_item
	FROM user_info ui -- 用户表存放的爱好字段hobby_id使用逗号分割存放hobby表id
	CONNECT BY LEVEL <= REGEXP_COUNT(ui.hobby_id, '[^,]+') -- 递归关联条件：当前递归层级 <= hobby.id 的个数
	AND PRIOR ui.id = ui.id -- 递归关联条件：进行自关联
	AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL -- DBMS_RANDOM是Oracle提供的一个PL/SQL包，用于生成随机数据和字符
)
SELECT 
    uit.id,
	uit.username,
    uit.hobby_id,
	LISTAGG(TO_CHAR(h.hobby_name), ',') WITHIN GROUP(ORDER BY uit.C_LEVEL) hobby_name -- 参考[listagg within group行转列](#listagg%20within%20group行转列)
FROM user_info_temp uit
INNER JOIN hobby h ON uit.hobby_id_item = h.id
GROUP BY 
    uit.id,
	uit.username,
    uit.hobby_id;
```

### 自定义函数

#### 解析json

- 参考：https://blog.csdn.net/cyzshenzhen/article/details/17074543
    - `select pkg_common.FUNC_PARSEJSON_BYKEY('{"name": "smalle", "age": "18"}', 'name') from dual;` 取不到age?

#### 字符串分割函数

- 使用正则函数

```sql
-- 基于,分割，返回3行数据
select regexp_substr('17,20,23', '[^,]+', 1, level, 'i') as str from dual
  connect by level <= length('17,20,23') - length(regexp_replace('17,20,23', ',', '')) + 1;
```
- (1)创建字符串数组类型：`create or replace type sq_type_arr_str is table of varchar2 (60);` (一个数组，每个元素是varchar2 (60))
- (2)创建自定义函数`sq_split`

  ```sql
  create or replace function sq_split(p_str       in varchar2,
                                  p_delimiter in varchar2)
    return sq_type_arr_str
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
  end sq_split;
  ```
- 查询示例：`select * from table (cast (sq_split ('aa,,bb,cc,,', ',') as sq_type_arr_str));` (一定要加`as sq_type_arr_str`) 结果如下：

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
            from table(cast(sq_split(t.name, ',') as sq_type_arr_str)) arr
            where trim(arr.column_value) = 'aa')
  ```

### Oracle中DBlink实现跨实例查询

- 同示例，跨用户可使用别名进行访问

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

-- 查询。并且mybatis是支持oracle的@dblink，相关sql语句表名后增加dblink名即可
select * from tbl_ost_notebook@my_dblink;
```

### Oracle定时任务Job

- 说明
    - jobs是oracle数据库的对象，dbms_jobs是jobs对象的一个实例，类比emp表是tables的实例
    - 创建方式有差异，Job是通过调用dbms_scheduler.create_job包创建的，dbms_job则是通过调用dbms_job.submit包创建的
    - oracle10g以后就推荐采用dbms_scheduler包来取代dbms_job来创建定时任务
    - 任务可手动运行，无法自动运行任务
        - 确保有可用的任务队列 `select value from v$parameter where name like '%job_queue_processes%'`，如果任务队列太小或为0可通过此语句设置`alter system set job_queue_processes =100;`
        - 排查参考: https://www.modb.pro/db/394410
- [dbms_scheduler使用](https://docs.oracle.com/cd/E11882_01/appdev.112/e40758/d_sched.htm#ARPLS72236)

```sql
-- 创建任务
begin
    dbms_scheduler.create_job(
        job_name => 'my_job_test',
        job_type => 'stored_procedure', -- 固定值
        job_action => 'my_proc_name', --存储过程(还支持脚本,参数)
        start_date => sysdate, -- job的开始时间(写成希望第一次执行的实际，如果写成sysdate可能会在启用时立即执行一次)
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=5', -- job的运行频率。即每5分钟执行1次
        comments => '描述',
        -- end_date => SYSDATE + 5 / 1440, -- 可设置结束时间
        -- job_class => 'DBMS_JOB$', -- 使用内置任务类DBMS_JOB$，从而到达运行时不记录运行日志
        enabled => true -- 启用(默认为false)
    );
end;

-- 查询任务
select t.owner, t.job_name, t.JOB_ACTION, t.REPEAT_INTERVAL, t.comments, t.ENABLED
    ,to_char(t.start_date, 'yyyy-MM-dd hh24:mi:ss') start_date, to_char(t.next_run_date, 'yyyy-MM-dd hh24:mi:ss') next_run_date, to_char(t.last_start_date, 'yyyy-MM-dd hh24:mi:ss') last_start_date, t.run_count
    ,t.*
from dba_scheduler_jobs t; -- user_scheduler_jobs
-- 查看任务执行日志
select * from dba_scheduler_job_log t where t.JOB_NAME = 'MY_JOB_TEST';
SELECT * from dba_scheduler_job_run_details t WHERE t.JOB_NAME = 'MY_JOB_TEST';

begin
    -- 运行job
    dbms_scheduler.run_job(jobName);
    -- 停止任务, force=true强制停止
    dbms_scheduler.stop_job(jobName, force);
    -- 启用/禁用
    dbms_scheduler.enable(jobName);
    dbms_scheduler.disable(jobName, force);
    -- 删除任务
    dbms_scheduler.drop_job(jobName);
end;
```
- dbms_scheduler执行频率repeat_interval支持两种格式

```sql
-- repeat_interval 支持两种格式
1. 常规日期格式   
   (1) 每天：sysdate + 1   

2. 日历表达式（'FREQ': 频率，'INTERVAL'：范围 1-999，可选：BY...）
   FREQ=DAILY; INTERVAL=1 										 每天执行一次 
   FREQ=WEEKLY; INTERVAL=1; BYDAY=MON							 每周一执行一次
   FREQ=WEEKLY; INTERVAL=1; BYDAY=MON,FRI						 每周一，周五执行一次
   FREQ=WEEKLY; INTERVAL=1; BYDAY=MON; BYHOUR=8					 每周一早上8点执行一次
   FREQ=MONTHLY; INTERVAL=1; BYMONTHDAY=1; BYHOUR=8; BYMINUTE=30 每月第一天早上8点30分执行一次
   
   (1) FREQ
	   YEARLY   年  
	   MONTHLY  月 
   	   WEEKLY   周 
       DAILY    天		  
       HOURLY   时  
       MINUTELY 分  
       SECONDLY 秒
       
   (2) INTERVAL
       1 ~ 999

   (3) BYMONTH
       JAN 一月    -- January
	   FEB 二月    -- February
	   MAR 三月    -- March
	   APR 四月    -- April
	   MAY 五月    -- May
	   JUN 六月    -- June
	   JUL 七月    -- July
	   AUG 八月    -- August
	   SEP 九月    -- September
	   OCT 十月    -- October
	   NOV 十一月  -- February
	   DEC 十二月  -- December
       
   (4) BYDAY
	   MON  周一  -- Monday
	   TUE  周二  -- Tuesday
	   WED  周三  -- Wednesday
	   THU  周四  -- Thursday
	   FRI  周五  -- Friday
	   SAT  周六  -- Saturday
	   SUN  周天  -- Sunday  
	    
   (5) BYHOUR
   (6) BYMINUTE
   (7) BYSECOND

-- 常用
`REPEAT_INTERVAL => 'FREQ=DAILY; BYHOUR=16,17,18'` 每天下午4、5、6点时运行
`REPEAT_INTERVAL => 'FREQ=DAILY; BYDAY=FRI'` 每周5的时候运行
`REPEAT_INTERVAL => 'FREQ=MONTHLY; BYMONTHDAY=-1'` 每月最后一天运行
`REPEAT_INTERVAL => 'FREQ=YEARLY; BYHOUR=6; BYMINUTE=30; BYSECOND=0; BYDAY=-1FRI` 每年的最后一个周5的6点30分运行
```
- dbms_job使用

```sql
-- 查询
select * from dba_jobs; -- 还有all_jobs/user_jobs
-- 正在运行的job
select * from dba_jobs_running;

-- 其他操作
declare
    job_id number;
begin
    -- （1）创建job
    -- sys用户下dbms_job包中的submit过程(方法)，sys可以省略
    -- 在dbms_job这个package中还有其他的过程：broken、change、interval、isubmit、next_date、remove(移除一个job)、run(立即运行一个job)、submit、user_export、what；
    sys.dbms_job.submit(
        job => job_id, -- OUT，返回job_id（不能省略）
        what => 'my_proc_name;', -- 执行的存储过程名称，后面要带分号
        next_date => to_date('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), -- job的开始时间(写成希望第一次执行的实际，如果写成sysdate可能会立即执行一次)
        interval => 'trunc(sysdate, ''mi'') + 10/(24*60)' -- job的运行频率。即10分钟运行my_proc_name过程一次
    );
    commit;

    -- 带参数执行job(每日凌晨零点执行)
    dbms_job.submit(job_id, 'declare username varchar2(200); begin my_proc_name(username, ''''); end;', sysdate, 'trunc(sysdate)+1'); 

    -- （2）比如某个job返回的id为888
    dbms_job.run(888); -- 立即运行一次888这个job（如果job中next_date=4000-1-1，可能由于存储过程执行出错，修正后重新运行一次即可）
    dbms_job.remove(888); -- 移除888这个job
    commit;

	-- （3）修改
	dbms_job.what('my_proc_name;'); -- 修改要执行的存储过程名
	dbms_job.next_date(888, to_date('2000-01-02 00:00:00', 'yyyy-mm-dd hh24:mi:ss')); -- 修改 job 的起始时间
	dbms_job.interval(888, 'trunc(sysdate)+1'); -- 修改 job 的间隔时间
end;
```
- dbms_job执行频率举例
    - 每天午夜12点 `interval => 'trunc(sysdate + 1)'`
    - 每天早上8点30分 `interval => 'trunc(sysdate + 1) + (8*60+30)/(24*60)'`
    - 每星期二中午12点 `interval => 'next_day(trunc(sysdate), ''tuesday'') + 12/24'`
    - 每个月第一天的午夜12点 `interval => 'trunc(last_day(sysdate) + 1)'`
    - 每个季度最后一天的晚上11点 `interval => 'trunc(add_months(sysdate + 2/24, 3), ''q'') -1/24'`
    - 每星期六和日早上6点10分 `interval => 'trunc(least(next_day(sysdate, ''saturday''), next_day(sysdate, ''sunday''))) + (6×60+10)/(24×60)'`
    - 每30秒执行次 `interval => 'sysdate + 30/(24 * 60 * 60)'`
    - 每10分钟执行 `interval => 'trunc(sysdate, ''mi'') + 10/(24*60)'`
    - 每天的凌晨1点执行 `interval => 'trunc(sysdate) + 1 + 1/(24)'`
    - 每周一凌晨1点执行 `interval => 'trunc(next_day(sysdate, ''星期一''))+1/24'`
    - 每月1日凌晨1点执行 `interval => 'trunc(last_day(sysdate))+1+1/24'`
    - 每季度的第一天凌晨1点执行 `interval => 'trunc(add_months(sysdate, 3), ''q'') + 1/24'`
    - 每半年定时执行(7.1和1.1) `interval => 'add_months(trunc(sysdate, ''yyyy''),6)+1/24'`
    - 每年定时执行 `interval => 'add_months(trunc(sysdate, ''yyyy''), 12)+1/24'`

### 其他

```sql
-- 去除换行chr(10), 去掉回车chr(13), 去掉空格。idea从excel复制数据新增时可能会出现换行
update t_test t set t.name=trim(replace(replace(t.name,chr(10),''),chr(13),''));
-- 正则替换只保留数字. 更多参考上文
select regexp_replace('1-2 ', '[^0-9]+', '') as str from dual; -- 12
-- translate 与replace类似是替换函数，但translate是一次替换多个单个的字符
select translate('1234567','123' ,'abc') from dual ; --1替换为a,2替换为b,3替换为c
--四舍五入
select round(0.44775454545454544, 2) from dual; -- 0.45
-- 一个数A，先除以B，再乘以B，最终得到的不一定是A
select round(10.3 / 2, 1) from dual; -- 5.2
select round(5.2 * 2, 1) from dual; -- 10.4
--直接保留两位小数. 默认保留整数
select trunc(4.757545489, 2) from dual; -- 4.74
```

## SqlServer

- CET和表变量

```sql
-- 方式一
select * from Customer where Id in (select EntityId from GenericAttribute where [Key] = 'FirstName' and [Value] = 'John');

-- 方式二：使用表变量，维护性增高(子句不能有分号)；表变量实际上使用了临时表，从而增加了额外的I/O开销，不太适合数据量大且频繁查询的情况
declare @t table(EntityId nvarchar(3))
insert into @t(EntityId) (select EntityId from GenericAttribute where [Key] = 'FirstName' and [Value] = 'John')
select * from Customer where Id in (select * from @t);

-- 方式三：使用CTE公用表表达式，性能高于表变量；其中ca是一个自定义的公用表表达式
with
ca as
(
	select EntityId from GenericAttribute where [Key] = 'FirstName' and [Value] = 'John'
)
select * from Customer where Id in (select * from ca);
```

## 语法树解析

- [Druid](https://github.com/alibaba/druid)
    - 其组件[SQL-Parser](https://github.com/alibaba/druid/wiki/SQL-Parser)可进行SQL解析
- [Apache Calcite](https://github.com/apache/calcite)
    - 只支持通用的文法树，无法对不同数据库提供本地化支持
- [antlr](https://github.com/antlr/antlr4)
    - Antlr4是一个Java实现的开源项目，用户需要编写g4后缀的语法文件(有通用文件提供)，Antlr4可以自动生成词法解析器和语法解析器，提供给开发者的接口是已经解析好的抽象语法树以及易于访问的Listener和Visitor基类。支持结构性语法，SQL解析只是其中一个应用场景
- 参考文章
    - https://tech.meituan.com/2018/05/20/sql-parser-used-in-mtdp.html




---

参考文章

[^1]: http://www.cnblogs.com/linjiqin/archive/2012/04/04/2431975.html (分析函数1)
[^2]: http://www.cnblogs.com/linjiqin/archive/2012/04/05/2433633.html (分析函数2)
[^3]: http://www.cnblogs.com/linjiqin/archive/2012/04/06/2434806.html (分析函数3)
[^4]: https://www.cnblogs.com/hoojo/p/oracle_procedure_job_interval.html (Oracle-job-procedure存储过程定时任务)
[^5]: https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions065.htm#SQLRF00641 (oracle doc: keep)
[^6]: https://lanjingling.github.io/2015/10/09/oracle-fenxihanshu-3/
[^7]: https://www.cnblogs.com/seven7seven/p/3662451.html
[^9]: https://blog.csdn.net/qq_42440234/article/details/84101412
