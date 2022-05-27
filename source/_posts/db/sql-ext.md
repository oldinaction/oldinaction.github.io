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

### 数据类型转换

- mysql：`cast()`和 `convert()` 可将一个类型转成另外一个类型
    - 语法：cast(expr as type)、convert(expr, type)、convert(expr using transcoding_name)   

```sql
-- mysql、h2。可用类型：二进制 BINARY、字符型，可带参数 CHAR()、日期 DATE、TIME、DATETIME、浮点数 DECIMAL、整数 SIGNED、无符号整数 UNSIGNED
-- 可将LONG/CLOB等转成字符串
select cast(ID as char) from user limit 1;

-- 日期时间转换
-- mysql
select date_format(now(), '%Y-%m-%d %H:%i:%s');
select str_to_date('2016-01-02 10:00:00.000','%Y-%m-%d %H:%i:%s.%f');
select to_days(now()); -- 727666 从0年开始到当前的天数
select to_days('2016-01-02');
-- oracel
select to_char(sysdate, 'yyyy-MM-dd HH24:mi:ss') from dual;
select to_date('2016-01-02 10:00:00', 'yyyy-MM-dd HH24:mi:ss') from dual;
--sqlserver
select CONVERT(VARCHAR(10), GETDATE(), 120); -- 格式化日期(120为一种格式) 2000-01-01
select CONVERT(datetime, '2000-01-01', 20); -- 字符串转日期 2000-01-01 00:00:00.000
```

### 日期

```sql
-- mysql
date_sub(now(), interval 7 day) -- 当前时间-7天

-- oracle
sysdate + interval '1' year -- 当前日期加1年，还可使用：month、day、hour、minute、second
sysdate + interval '1 1:1' day to minute -- 当前日期 + 1日1时1分
sysdate + 1 -- 加1天
sysdate - 1/24/60/60 -- 减1秒
select sysdate, add_months(sysdate, -12) from dual; -- 减1年
select TRUNC(SYSDATE) FROM dual; -- 取得当天0时0分0秒
SELECT TRUNC(SYSDATE)+1-1/86400 FROM dual; -- 取得当天23时59分59秒(在当天0时0分0秒的基础上加1天后再减1秒)
select to_char(sysdate,'yyyy-mm')||'-01' firstday, 
       to_char(last_day(sysdate),'yyyy-mm-dd') lastday from dual; -- 在oracle中如何得到当天月份的第一天和最后一天

-- sqlserver
select 
    GETDATE(), -- 获取当前时间(带时间) 2000-01-01 08:11:12.000
    GETUTCDATE(), -- 当前UTC时间 2000-01-01 00:11:12.000
    DATEDIFF(hour, GETUTCDATE(), GETDATE()), -- 获取当前时间-当前UTC时间的相差小时 8
    DATEADD(hour, DATEDIFF(hour, GETUTCDATE(), GETDATE()), GETUTCDATE()); -- 对UTC时间增加时区差 2000-01-01 08:11:12.000
select DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE())); -- 2000-01-01 00:00:00.000
select CAST(CAST(GETDATE() as date) as varchar(10)) + ' 00:00:00'; -- 2000-01-01 00:00:00.000
```
- 日期数据类型转换见上文

### 查询

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
select * from users where last_name is null or last_name = '';
select * from users where last_name is not null and last_name != '';
ifnull(counts, 0)
-- sqlserver
isnull(counts, 0)
```
- 字符串类型值

```sql
-- Mysql 可以使用单引号或双引号，Oracle只能使用单引号
select name from user where name = "smalle";
select name from user where name = 'smalle';
```
- as

```sql
-- Mysql/Oracle两种写均支持。只不过mybatis操作oracle返回map时，第一种写法的key全部为大写，第二种写法的key为小写
select name as username from user where name = "smalle";
select name as "username" from user where name = "smalle";
```

### 排序

- 控制排序

```sql
order by my_field [asc|desc] nulls [first|last] -- oracle
order by if(isnull(my_field),1,0), my_field [asc|desc] -- mysql默认将null值放在下面
order by if(isnull(my_field),0,1), my_field [asc|desc] -- mysql默认将null值放在上面
```

## 复杂查询

- count是统计该字段不为空的行数，可结合distinct使用，如`count(distinct case when u.sex = '1' then u.city else null end )`

### 基于用户属性表统计每个公司不同用户属性的用户数

```sql
-- 1个公司对于多个用户，1个用户对应多个属性
select
	c.id,
	c.name,-- 公司名称
	count( distinct u.id ) count_user,-- 该公司的用户数
	count( case when ua.key = 'JobTitle' and ua.value = 'employee' then c.id end ) count_employee,-- 该公司的普通员工数。也可加上`else null`(因为count是统计该字段不为空的行数); 还可以加上 distinct 进行去重
	count( case when ua.key = 'JobTitle' and ua.value = 'manager' then c.id end ) count_manager,-- 该公司的经理数
	count( case when ua.key = 'Sex' and ua.value = 'boy' then c.id end ) count_boy -- 该公司男性用户数
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

- 参考[listagg within group行转列](#listagg%20within%20group行转列)
- 参考[wm_concat行转列](#wm_concat行转列)

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
- 字段值不区分大小写问题(**oracle默认区分大小写，sqlserver也不区分大小写**)
	- 如果字段为`utf8_general_ci`存储时，可以在字段前加`binary`强行要求此字段进行二进制查询，即区分大小写。如`select * from `t_test` where binary username = 'aezocn'`
	- 设置字段排序规则为`utf8_bin`(`utf8_general_ci`中`ci`表示case insensitive，即不区分大小写)。设置成`utf8_bin`只是说字段值中每一个字符用二进制数据存储，区分大小写，显示和查询并不是二进制
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

#### WITH AS 用法

- 可认为在真正进行查询之前预先构造了一个临时表，之后便可多次使用它做进一步的分析和处理。一次分析，多次使用
- 语法

```sql
with tempName as (select ....)
select ...

-- 针对多个别名
with
   tmp as (select * from tb_name),
   tmp2 as (select * from tb_name2)
select ...
```

### 常用函数

- concat/concat_ws/group_concat

```sql
-- 将多个字符串连接成一个字符串。任何一个值为null则整体为null
concat(str1, str2,...)
-- 将多个字符串连接成一个字符串，但是可以一次性指定分隔符concat_ws就是concat with separator）
concat_ws(separator, str1, str2, ...)
-- 将group by产生的同一个分组中的值连接起来，返回一个字符串结果。类似oracle的wm_concat
group_concat( [distinct] 要连接的字段 [order by 排序字段 asc/desc ] [separator '分隔符(默认为,)'] )
select userId, group_concat(orderId order by orderId desc separator ';') as orderList from t_orders group by userId;
```
- 字符串

```sql
-- instr
    -- linux/unix下的行结尾符号是`\n`，windows中的行结尾符号是`\r\n`，Mac系统下的行结尾符号是`\r`
    -- 回车符：\r=0x0d (13) (carriage return)
    -- 换行符：\n=0x0a (10) (newline)
select * from t_test where instr(username, char(13)) > 0 or instr(username, char(10)) > 0; -- 查找表中某字段含有`\r\n`的数据

-- find_in_set
    -- type字段表示：1头条、2推荐、3热点。现在有一篇文章即是头条又是热点，即type=1,2
select * from article where find_in_set('2', type); -- 找出所有热点的文章
```
- 日期

```sql
-- sysdate
update t_test t set t.update_tm = sysdate() where id = 1; -- 其中`sysdate()`可获取当前时间
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
select val->"$.hello" from test; -- "hi, \"aezo\""
-- 或内联路径运算符 ->> (去掉了引号和转义符)。可能由于服务器no_backslash_escapes的配置导致无法使用 ->>，可如下使用json_unquote()
select val->>"$.hello" from test; -- hi, "aezo"
select json_unquote(val->"$.hello") from test; -- hi, "aezo"

-- 搜索
select json_unquote(json_extract(val, '$.*')) from test; -- 将所有一级key对应的值放入到数组中：[{"t1": "v1", "t2": [1, true, false]}, "smalle", "Hi, \"AEZO\"", [{"item": {"name": "book", "weight": 5}}, "game"]]
select json_unquote(json_extract(val, '$.name')) from test; -- smalle
select json_unquote(json_extract(val, '$.hobby[0].item')) from test; -- {"name": "book", "weight": 5}
select json_unquote(json_extract(val, '$**.name')) from test; -- 返回所有最底相应key值：["smalle", "book"]
select json_unquote(json_extract(val, '$.hobby[*].item.*')) from test; -- ["book", 5]
select json_unquote(json_extract(val->'$.hobby', '$[0].item.name')) from test; -- book
select json_unquote(json_extract('[1, 2, 3]', '$[0]')); -- 1

-- 如果存放json的字段类型为字符串，取出数据时可进行转换编码
select convert(json_unquote(json_extract('["张三", "李四"]', '$[0]')) using utf8mb4); -- 张三
```

## Oracle

### 常用函数

#### decode和case when

- `decode(被判断表达式, 值1, 转换成值01, 值2, 转换成值02, ..., 转换成默认值)` 只能判断=，不能判断like(like可考虑case when)
	- `select decode(length(ys.ycross_x), 1, '0' || ys.ycross_x, ys.ycross_x) from ycross_storage ys` 如果ys.ycross_x的长度为1那就在前面加0，否则取本身
	- `select sum(decode(shipcomp.company_num, 'CMA', 1, 0)) cma, sum(decode(shipcomp.company_num, 'MSK', 1, 0)) msk from ycross_in_out_regist yior ...(省略和shipcomp的关联)` 统计进出场记录中cma和msk的数量
	- `order by decode(col, 'b', 1, 'c', 2, 'a', 3, col)` 按值排序
- `case when then [when then ...] else end` 比decode强大
	- `case when t.name = 'admin' then 'admin' when t.name like 'admin%' then 'admin_user' else decode(t.role, 'admin', 'admin', 'admin_user') end`
	- `sum(case when yior.plan_classification_code = 'Empty_Temporary_Fall_Into_Play' and yardparty.company_num = 'DW1' then 1 end) as count_dw1` sum写在case里面则需要对相关字段(plan_classification_code)进行group by，而sum写外面则不需要对此字段group by. **主要用于分组之后根据条件分列显示**

#### grouping rollup

- http://blog.csdn.net/damenggege123/article/details/38794351

#### trunc时间处理

```sql
select trunc(sysdate-1, 'dd'), trunc(sysdate, 'dd') from dual; -- 返回昨天和今天（2018-01-01, 2018-01-02）
```

#### 聚合函数(aggregate_function)

- `min`、 `max`、`sum`、`avg`、`count`、`variance`、`stddev` 
- `count(*)`、`count(1)`、`count(id)`、`count(name)` **统计行数，不能统计值的个数**。count(name)，如果有3行，但是name有值的只有2行时结果仍然为3

##### wm_concat行转列

- 行转列，会把多行转成1行(默认用`,`分割，select的其他字段需要是group by字段)
- 自从oracle **`11.2.0.3`** 开始`wm_concat`返回的是clob字段，需要通过to_char转换成varchar类型 [^8]
- `select replace(to_char(wm_concat(name)), ',', '|') from test;`替换分割符

##### listagg within group行转列

```sql
-- 查询部门为20的员工列表
select
	t.deptno,
    -- listagg 可理解为wm_concat；而 within group 表示对没一组的元素进行操作，此时是基于 t.ename 进行排序(即排序后再调用listagg)
	listagg(t.ename, ',') within group (order by t.ename) names -- 返回 ADAMS,FORD,JONES 即将多行显示在一列中
from scott.emp t
where t.deptno = '20'
group by t.deptno
```

#### 分析函数

##### 常见分析函数 [^3]

- `min`、 `max`、`sum`、`avg` **一般和over/keep函数联合使用**
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

- `start with connect by prior` 递归查询(如树形结构)

```sql
select * from my_table t 
start with t.pid = 1 -- 基于此条件进行向下查询(省略则表示基于全表为根节点向下查询，可能会有重复数据)
connect by nocycle -- 递归条件(递归查询不支持环形。此处nocycle表示忽略环，如果确认结构中无环形则可省略。有环形则必须加，否则报错)
prior t.id = t.pid -- 增加递归条件，或者 add prior。也可自递归，如 t.id = t.id
add prior level <= regexp_count(t.names, '[^,]+') -- level为当前递归层级(顶层为1)，此条件无实际意义，仅为了展示其语法功能
where t.valid_status = 1; -- 将递归获取到的数据再次过滤
```

##### over

- 分析函数和聚合函数的不同之处是什么：普通的聚合函数用**group by分组，每个分组返回一个统计值**，而分析函数采用**partition by分组，并且每组每行都可以返回一个统计值** [^1]
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
            -- 见图oracle-over-1：窗口默认为整个组
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno) from emp;
            -- 见图oracle-over-2：窗口默认为第一行到当前行
            select deptno, empno, ename, sal, last_value(sal) over(partition by deptno order by sal desc) from emp;
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
        #   
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
##### keep [^6]

- keep的用法不同于通过over关键字指定的分析函数，可以用于这样一种场合下：**取同一个分组下以某个字段排序后，对指定字段取最小或最大的那个值。**从这个前提出发，我们可以看到其实这个目标通过一般的row_number分析函数也可以实现，即指定rn=1。但是，该函数无法实现同时获取最大和最小值。或者说用first_value和last_value，结合row_number实现，但是该种方式需要多次使用分析函数，而且还需要套一层SQL。于是出现了keep
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
    - **`dense_rank first`，`dense_rank last`**为keep函数的保留属性
        - dense_rank first 表示取分组-排序结果集中第一个(dense_rank值排第一的。可能有几行数据排序值一样，此时再可配合min/max等聚合函数取值)
        - dense_rank last 同理，为最后一个
- Keep测试一(基于主表group by)，场景参考上文[over使用误区](#over使用误区)

```sql
-- *****Keep测试一(基于主表group by)*****：如查分组中最新的数据(非分组字段通过keep获取，如果同最近的ID再次管理表则效率低一些)
select
v.customer_id, v.visit_type
,max(v.id) keep(dense_rank first order by v.visit_tm desc) as id -- 在每一组中按照v.visit_tm排序计数(BS那一组排序值为 1-1-2. 因为存在两个拜访时间2018/9/21一样，因此排序值都为1，当遇到不同排序值+1)，并取第一排序集(1-1的两条记录)中v.id最大的
,max(v.visit_tm) keep(dense_rank first order by v.visit_tm desc) as visit_tm
,max(v.comments) keep(dense_rank first order by v.visit_tm desc) as comments
,max(v.visit_tm) keep(dense_rank first order by v.id desc) as visit_tm_id -- 排序值为 1-2-3
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
    select t.* from ( -- 写法 2
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

-- 正则替换中文、\、`为空格，并取256位长度
select substr(regexp_replace('中文A\B`C', '[' || unistr('\4e00') || '-' || unistr('\9fa5') || '\\`]', ' '), 0, 256)
as rx_replace from dual

-- 匹配纯数字
regexp_like(income,'^(\d*)$')
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

### 关联表进行数据更新

- **`update set from where`** 将一张表的数据同步到另外一张表
    
    ```sql
    -- Oracle：如果a表和b表的字段相同，最好给两张表加别名. **注意where条件**
    update test a set (a.a1, a.a2, a.a3) = (select b.b1, b.b2, b.b3 from test2 b where a.id = b.id) 
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

```sql
-- 查询
select * from dba_jobs; -- 还有all_jobs/user_jobs
-- 真正运行的job
select * from dba_jobs_running;

-- 操作job(创建、手动执行、删除)
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
    dbms_job.run(888); -- 立即运行一次888这个job（如果job中next_date=4000-1-1，可能由于存储过程执行出错，修正后重新运行一次即可）
    dbms_job.remove(888); -- 移除888这个job
    commit;

	-- （3）修改
	dbms_job.what('my_proc_name;'); -- 修改要执行的存储过程名
	dbms_job.next_date(888, to_date('2018-06-15 10:00:00', 'yyyy-mm-dd hh24:mi:ss')); -- 修改 job 的间隔时间
	dbms_job.interval(888, 'trunc(sysdate)+1'); -- 修改 job 的间隔时间
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

### 其他

```sql
-- 去除换行chr(10), 去掉回车chr(13), 去掉空格。idea从excel复制数据新增时可能会出现换行
update t_test t set t.name=trim(replace(replace(t.name,chr(10),''),chr(13),''));
--四舍五入
select round(0.44775454545454544,2) from dual;
--直接保留两位小数
select trunc(4.757545489, 2) from dual;
```

## SqlServer

-CET和表变量

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
[^8]: https://www.smwenku.com/a/5b8dd9d82b71771883410ce1/ 
[^9]: https://blog.csdn.net/qq_42440234/article/details/84101412
