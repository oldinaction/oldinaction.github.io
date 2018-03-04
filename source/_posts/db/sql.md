---
layout: "post"
title: "sql基础"
date: "2017-09-30 12:51"
categories: [db]
tags: [mysql, oracle, sql]
---

> 未做特殊说明的语句都是基于Mysql的语法

## 数据库操作语言DML(Data Manipulation Language，即CRUD)

> 数据参考下文【数据库表信息】
> 先登录并选择数据库mysql -uroot -proot sqltest
> 先复制表emp、dept、salgrade，如：create table dept2 as select * from dept;

### 插入记录

- 按字段顺序一一插入值 `insert into dept2 values(50, 'game', 'bj');`
- 指定部分字段的值 `insert into dept2(deptno, dname) values(60, 'game2');` 未指定的字段取默认值
- 根据从子查询的值插入 `insert into dept2 select * from dept;` 子查询拿出来的数据和表结构要一样
- 产生100w条数据

```sql
-- 1	2018-02-27 10:45:16	64	7SNNAA85AH375N09Y5II	1
create table t_test as
    select 
        rownum as id,
        to_char(sysdate + rownum / 24 / 3600, 'yyyy-mm-dd hh24:mi:ss') as input_tm,
        trunc(dbms_random.value(0, 100)) as random_no,
        dbms_random.string('x', 20) username,
        1 as is_valid
    from dual
    connect by level <= 1000000;
```

### 更新记录

- `update emp2 set sal = sal*2, ename = concat(ename, '_') where deptno = 10;` 把部门编号为10的工资提一倍，并在名称后面加下划线
- Oracle通过pl/sql更新：`select * from table_or_view for update;` 开启更新模式，然后进行更新并提交

### 删除记录(表结构不会删除)

- `delete from emp2;` 清空表emp2
- `delete from dept2 where deptno < 25;` 删除deptno < 25的条目

### 事物

- Mysql和Oracle提交事物：`commit;`；Oracle的撤销操作：`rollback;`
- Oracle的transaction(事物)：
    - 一个transaction起始于一个dml(增删查改)语句
    - 当执行撤销"rollback;"后，回到最原始状态，相当于此transaction结束；或当执行提交"commit;"后，此transaction结束（此时在撤销则不能回到原始状态）。
    - 当执行一个ddl语句(如：创建表create table)或者一个dcl语句(如：设置权限grant)后，transaction也自动结束。

### 查询

#### 书写顺序

- **书写顺序和执行顺序都是按照`select-where-group by-having-order by`进行的**

```sql
mysql>select count(num) 	/*注释：组函数*/
    ->from emp			/*注释：此语句是不能执行的*/
    ->where sal > 1000		/*注释：对数据进行过滤*/
    ->group by deptno		/*注释：对过滤后的数据进行分组*/
    ->having avg(sal) > 2000	/*注释：对分组后的数据进行限制*/
    ->order by ename desc	/*注释：对结果进行排序*/
    ->limit 2,3			/*注释：从第3条数据开始，取3条数据*/
    ->;
```

#### 查询

##### 基础查询

- `select ename, sal*12 from emp;` 算年薪
- `select curdate() 'current date', 2*3 count;` 显示系统时间和数学计算

    ```html
    +---------------------+---------------+-----+
    | now()               | current date  | 2*3 |
    +---------------------+---------------+-----+
    | 2015-10-25 13:21:29 | 2015-10-25    |   6 |
    +---------------------+---------------+-----+
    ```
    - oracle获取当前时间和数学计算：`select sysdate, 2*3 from dual;` (dual为oracle自带的虚表)
     - 别名中不能含有特殊字符（如：空格、下划线等）。如果需要含有，则应在别名上加单双引号；Oracle中下划线不需加引号，但是空格需要加引号
- 字符串连接函数`concat(字段1,字段2,或者字符串)`
    - 字符串中有单引号时，使用反斜线转义或者用两个单引号表示一个单引号。如`select concat(dname,loc,'A''AA') from dept;或者select concat(dname,loc,'A\'AA') from dept;`
    - Oracle中使用`||`连接字符串，如`select dname||loc from dept;`。使用两个单引号用来显示字符串中的单引号，如`select dname||'A''AA' from dept;`
- `select distinct deptno, job from emp;` `distinct`去掉重复的条目(此时是去掉两个字段重复的组合)
- `select * from emp where job = 'clerk' and sal between 1100 and 1500;` where过滤
    - 可以使用`=、>、<、<>`等判断大小，其中<>表示不等于，字符串是比较每个字母的ASCII码
    - 使用`between and`相当于 `>= and <=`
- `select ename, sal, comm from emp where comm is not null;` 使用`is null`或者`is not null`找出有关空值的条目
    - `=、!=`默认是查询不为空的数据
- `select ename, sal from emp where ename in('king', 'allen', 'abc');` 使用`in()`或者`not in()`表示相应字段的值是否在这些值里面的条目(本质是循环查询)
- `select ename from emp where ename like '_a%';` like模糊查询
    - `_`代表任意一个字符，`%`代表任意个字符
    - '%xxx'左like、'xxx%'右like、'%xxx%'两边like
    - 如果字段中含有特殊字符，需要用反斜线转义，如：`like 'a\_%'` 表示以`a_`开头的字符串
    - 也可以修改转义字符，如：`select ename from emp where ename like '_*_a%' escape '*';` 将转义字符设为`*`
- `select ename, sal, deptno from emp order by deptno asc, ename desc;` order by排序(显示按照deptno升序排序，如果deptno相同，再按照ename降序排序)
    - 默认是asc升序；desc代表降序
    - order by 语句对null字段的默认排序（可进行设置）
        - Oracle 结论 
            - order by colum asc 时，null默认被放在最后
            - order by colum desc 时，null默认被放在最前
            - nulls first 时，强制null放在最前，不为null的按声明顺序[asc|desc]进行排序
            - nulls last 时，强制null放在最后，不为null的按声明顺序[asc|desc]进行排序 
        - MySql 结论
            - order by colum asc 时，null默认被放在最前
            - order by colum desc 时，null默认被放在最后
            - ORDER BY IF(ISNULL(update_date),0,1) null被强制放在最前，不为null的按声明顺序[asc|desc]进行排序
            - ORDER BY IF(ISNULL(update_date),1,0) null被强制放在最后，不为null的按声明顺序[asc|desc]进行排序
- `select upper(dname) from dept;` `upper(字段)`和`lower(字段)`将相应字段转换成大小写
- `select substr(dname, 2, 3) from dept;` 截字符串，从第2个字符截取3个字符(包括第2个字符)
- `select ascii('A');`、`select char(65);` 字符和ascii码转换
    - Oracle中相应的是：`select chr(65) from dual;` 和 `select ascii('A') from dual;`
- `select round(12.753), round(12.753, 1), round(12.753, -1);` round()四舍五入

    ```html
    +---------------+------------------+-------------------+
    | round(12.753) | round(12.753, 1) | round(12.753, -1) |
    +---------------+------------------+-------------------+
    |            13 |             12.8 |                10 |
    +---------------+------------------+-------------------+
    ```
    - Oracle中为`select round(12.753) from dual;`
- `select format(sal, 4) from emp;` 格式化数据，format(数字,小数点位数)将数字转换成#,###,###,####的格式，以四舍五入的方式保留小数点位数

    ```html
    +----------------+
    | format(sal, 4) |
    +----------------+
    | 800.0000       |
    | 1,600.0000     |
    | 1,250.0000     |
    | 2,975.0000     |
    +----------------+
    ```
    - 在数字前面加上$、￥等字符则要为`select concat('￥', format(sal, 4)) from emp;`
	- Oracle中可直接定义格式，如`select to_char(sal, '$99,999.9999') from emp;和select to_char(sal, 'L00000.0000') from emp;` 这时L最终显示为￥。还可以转换日期，如：`select to_char(hiredate, 'YYYY-MM-DD HH24:MI:SS') from emp;` 其中HH24代表24小时制，不要24则为12小时
- select date_format(hiredate, '%Y-%m-%d %H:%i:%s') from emp;	格式化日期，其中的说明符参考《MySQL 5.1参考手册》的12.5章 日期和时间函数，1980-12-17 00:00:00
    - Oracle中要使用`select to_char(hiredate, 'YYYY-MM-DD HH24:MI:SS') from emp;` 其中HH24代表24小时制，不要24则为12小时
- `select ename, hiredate from emp where hiredate > '1982-01-23 00:00:00';` 注意日期格式要和表中的一致(不要时分秒也可比较)
    - Oracle中要使用`select ename, hiredate from emp where hiredate > to_date('1982-01-23 00:00:00', 'YYYY-MM-DD HH24:MI:SS');`、`select ename, sal from emp where sal > to_number('$2,500.00', '$9,999,99');` 当然就本例子可直接比较，to_numbre只是将此字符串按照某种格式转换成数字，及将$2,500.00转换为2,500.00
- `select ename, sal*12 + ifnull(comm, 0) from emp;` 空值转换`ifnull(exp1, exp2)`，如果exp1不为null,则取exp1的值，否则取exp2的值
    - 空值与任何值运算后都为空
	- Oracle中使用`nvl(exp1, exp2)`判断为空后设置默认值,即：`select ename, sal*12 + nvl(comm, 0) from cmp;`
- 显示指定行记录：`limit X, Y`（X表示索引为X的那条记录开始，选取Y条记录。索引默认从0开始）
    - `select ename from emp limit 2, 3;` 从第3条记录开始，显示3条记录
- `select ename, sal from emp where sal > 2500 order by sal desc limit 2, 3;` 按工资倒序排列，再从第3条记录开始，显示3条记录
    - Oracle默认会在结果集上加一个隐藏字段rownum，指默认排序的第几行。rownum只能与小于或小于等于号连用，不与大于及单独与等于号连用。
        - `select ename, empno from emp where rownum <= 5;` 只显示前5行
        - `select ename from (select rownum, ename from emp where rownum > 10);` Oracle非要用子查询才能显示rownum大于或等于某个数的条目
        - 按工资倒序排列，再从第3条记录开始，显示3条记录

            ```sql
            select ename, sal from
            (
            select ename, sal, rownum r from
            (select ename, sal from emp where sal > 2500 order by sal desc) 
            )
            where r >= 3 and r <= 5;
            ```
##### 组函数

- 组函数指输入多条记录，但是只有一条输出
    - `select max(sal) from emp;` 最大值
    - `min(sal)` 最小值
    - `avg(sal)` 平均值
    - `sum(sal)` 求和
    - `count(*)` 计算有多少条记录
        - 当count某个字段时，空值不会计算在内；而count(*)会把空值的字段计算在内
    - 组函数可以嵌套，但最多只能嵌套两层
- group by分组
    - `select deptno, avg(sal) from emp group by deptno;` 求每个部门的平均工资
    - `select deptno, job, max(sal) from emp group by deptno, job;` 按照多个字段进行分组
    - 出现在select列表中的字段，如果没有出现在组函数里面则必须出现在group by子句里面。如：
        - `select deptno, max(sal) from emp group by deptno;` 求每个部门的最高工资。此时是根据部门分组，所有每个部门都只有一条输出
- having对group by 分组后的结果进行限制
    - `select deptno, avg(sal) from emp group by deptno having avg(sal) > 2000;` 求部门平均工资大于2000的部门

##### 表连接

- 交叉连接(cross join)，如：`select ename, dname from emp cross join dept;`
- 等值连接，如：`select ename, dname from emp join dept on (emp.deptno = dept.deptno);`
- 多表连接，如：

    ```sql
    mysql> select ename, dname, grade, e.deptno from emp e
    -> join dept d on (e.deptno = d.deptno)
    -> join salgrade s on (e.sal between s.losal and s.hisal)
    -> where ename like '_l%';
    ```
    - *注意：此处deptno多个表含有此字段，所有e.deptno必须明确指明字段的表名，否则报错ERROR 1052
    - 结果

        ```html
        +-------+------------+-------+--------+
        | ename | dname      | grade | deptno |
        +-------+------------+-------+--------+
        | allen | sales      |     3 |     30 |
        | blake | sales      |     4 |     30 |
        | clark | accounting |     4 |     10 |
        +-------+------------+-------+--------+
        ```
- 自连接，即为同一张表起不同的别名，然后把它当成两种表来用，如求每个人相应经理人的名字。此时没有king，因为king没有经理人，可采用外连接解决：`select e1.ename, e2.ename from emp e1 join emp e2 on (e1.mgr = e2.empno);`
- 左、右、全外连接，left join、right join、full join。
    - left join和left outer join都表示左外连接，如果两个表进行连接，且连接后左边一个表中的数据不能显示出来，此时可以使用左连接(此时的king)。如：`select e1.ename, e2.ename from emp e1 left join emp e2 on (e1.mgr = e2.empno);`
- `left join`(以左边表为主)、`right join`(以右边表为主)、`inner join`(只显示on条件成立的)、`full join`(显示所有数据)、`join`(默认是inner join)

##### 子查询

- 可以把子查询当成查询到的一张表
- 求出所有雇员中工资最高的那个人
    - 正确写法=>`select ename, sal from emp where sal = (select max(sal) from emp);` 利用的子查询
    - 错误写法=>`select ename, max(sal) from emp;`因为max(sal)只有一行输出，但是可能有很多人的工资都是一样的最高，所以不匹配。此时Oracle会报错，但是Mysql可以显示，但是结果是错误的
- 哪些人的工资位于所有人平均工资之上`select ename, sal from emp where sal > (select avg(sal) from emp);`
- 在from语句中的子查询需要起一个表的别名(Oracle可不写)，否则Mysql报ERROR 1248错误。子查询得到的表接在where语句中不需要别名，但如果把它当做一个值则需要加括号
    - 部门平均工资中最高的。此时不起别名(t)则报错，但是Oracle不会报错`select max(avg_sal) from (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t;`

##### 子查询和表连接举例

- 按照部门分组之后每个部门工资最高的那个人

    ```sql
    mysql> select ename, sal from emp
        -> join (select max(sal) 'max_sal', deptno from emp group by deptno) t	/*注释：将通过子查询得到的一张表命名为t*/
        -> on (emp.sal = t.max_sal and emp.deptno = t.deptno);
    ```
- 求每个部门平均薪水的薪水等级
   
    ```sql
    mysql> select deptno, avg_sal, grade from
        -> (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t
        -> join salgrade s on (t.avg_sal between s.losal and s.hisal);
    ```
    - 其中deptno和avg_sal是从(select deptno, avg(sal) 'avg_sal' from emp group by deptno)中得到
- 求每个部门平均的薪水等级（每个人的薪水等级的平均）

    ```sql
    mysql> select deptno, avg(grade) from
        -> (select deptno, grade from emp join salgrade s on (emp.sal between s.losal and s.hisal)) t group by deptno;
    ```
- 求出那些人是经理人`select ename from emp where empno in(select distinct mgr from emp);`
- 不准用组函数，求工资最高值(面试题) `select sal from emp where sal not in (select distinct e1.sal from emp e1 join emp e2 on (e1.sal < e2.sal));`
- 求平均工资最高的部门编号

    ```sql
    /*正确写法*/
    select deptno, avg_sal from
    (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t1 /*注释：虽然t1、t2都没有使用也要加别名*/
    where avg_sal =
    (select max(avg_sal) from (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t2); /*注释：此时要加括号，把这段话当成一个最大平均值*/
    
    /*错误写法*/
    select deptno, max(avg_sal) from (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t;/*如果三个部门的平均值一样，则deptno有多个值，而max(sal)只有一个值*/
    ```
- 求平均工资最高的部门名称

    ```sql
    select dname from dept where deptno =
    (
        select deptno from
            (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t1 /*注释：虽然t1、t2都没有使用也要加别名*/
        where avg_sal =
            (select max(avg_sal) from (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t2)
    );
    ```
- 求平均工资的等级最低的部门的部门名称

    ```sql
    select dname from dept where deptno =
    (select deptno from 
        (select deptno, avg_sal, grade from
            (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t1
            join salgrade s
            on (t1.avg_sal between s.losal and s.hisal)
        ) t2 
        where grade =
        (select min(grade) from 
            (select deptno, avg_sal, grade from
                (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t1
            join salgrade s
            on (t1.avg_sal between s.losal and s.hisal)
            ) t2 /*注释：第二次用到t2这个"表"时，不能只写一个t2，要和前面一样将语句都写出来。但可以使用"视图"简化*/
        )
    );
    ```
    - 使用视图后：

        ```sql
        create view v1 as select deptno, avg(sal) 'avg_sal' from emp group by deptno;
        create view v2 as
        select deptno, avg_sal, grade from v1
        join salgrade s
        on (v1.avg_sal between s.losal and s.hisal)
        ;

        select dname from dept where deptno =
        (select deptno from v2
            where grade =
            (select min(grade) from v2
            )
        );
        ```
- 比普通员工最高工资还要高的经理人名称

    ```sql
    select ename, sal from emp
    where empno in (select distinct mgr from emp where mgr is not null)
    and sal >
    (select max(sal) from emp where empno not in (select distinct mgr from emp where mgr is not null));
    ```
- 将薪水大于1200的雇员按照部门进行分组，分组后的平均薪水必须大于1500，查询分组之内的平均工资并按照平均工资的倒序进行排列
`select deptno, avg(sal) from emp where sal > 1200 group by deptno having avg(sal) > 1500 order by avg(sal) desc limit 1,2;`

## 数据库模式定义语言DDL(Data Definition Language)

### 创建和使用数据库

- `create database sqltest;/*创建数据库*/`
- `use sqltest;/*使用数据库，之后在这个数据库上进行表的创建、展示等操作*/`

### 数据库基本

- Mysql数据类型
    - `int`		    整型，最大11个字节，相当于Oracle里的的number(X)
    - `double`		浮点型，相当于Oracle里的的number(X, Y)
    - `char`		定长字符串，同Oracle的char
    - `varchar` 	变长字符串，最大255字节，相当于Oracle里的的varchar2
    - `datetime`	日期，相当于Oracle里的date
    - `text`		文本型(存储可变长度的非Unicode数据，最大长度为2^31-1个字符，可存储textarea中的换行格式)
    - `longtext`	长字符串类型，最大4G，相当于Oracle里的long
- Oracle数据结构
    - `char`		定长字符串；存取时效率高，空间可能会浪费
    - `varchar2`	变长字符串,大小可达4Kb(4096个字节)；存取时效率高；varchar2支持世界所有的文字，varchar不支持
    - `long`		变长字符串，大小可达到2G
    - `number`		数字；number(5, 2)表示此数字有5位，其中小数含有2位
    - `date`		日期(插入时，sysdate即表示系统当前时间；select时默认展示年月日，要想展示时分秒则需要to_char转换)
    - ...还有很多，如用来存字节，可以把一张图片存在数据库（但是实际只是存图片存在硬盘，数据库中存图片路径）
- Mysql注释使用`/**/`，Oracle注释使用`/**/`或`--`

### 创建、删除、复制表、更新

- Mysql表相关约束constraint(起名不能为关键字)
    - 字段约束，加在字段的末尾加unique
    - 表约束，加在所有字段末尾
    - 约束类型：非空、唯一、主键、外键、check
    - 主键约束：唯一且非空，主键字段可代表一条单独的记录
    - 外键约束：外键约束是建立在两个字段上的，某一个字段(stu.class)会参考另一个字段(class.id)的值；且被参考的字段必须主键；当被参考的字段已经被参考了，那么则不能删除这条记录
- 创建class班级表和stu学生表示例
    - class班级表：创建stu表时需要先创建一个班级class的表

        ```sql
        create table class
        (
        id int(4) primary key,
        name varchar(20) not null
        );
        ```
    - stu学生表

        ```sql
        create table stu/*由于使用了外键约束，故创建stu表时需要先创建一个班级class的表*/
        (
        id int(6) primary key auto_increment,/*主键约束(primary key);自动递增(auto_increment)*/
        name varchar(20) not null,/*非空约束,插数据时不能为null*/
        sex int(1),
        age int(3),
        sdate timestamp,
        grade int(2) default 1,/*年级默认为1*/
        class int(4),
        email varchar(50) unique,/*字段约束;唯一约束,两个NULL值不算重复*/
        constraint stu_class_fk foreign key(class) references class(id)/*外键约束;表约束;可以省略constraint stu_class_fk即自己不命名此约束*/
        );
        ```
#### Oracle创建

- 创建班级表

    ```sql
    create table class
    (
    id number(4) primary key,
    name varchar(20) not null
    );
    ```
- 创建学生表

    ```sql
    create table stu
    (
    id number(6) primary key,/*主键约束；也可加在表级上，如：constraint stu_id_pk primary key(id)*/
    name varchar2(20) constraint stu_name_no not null,/*constraint给约束条件(非空)起名为stu_name_no；非空约束，插数据时不能为null*/
    sex number(1),
    age number(3),
    sdate date,
    grade number(2) default 1,
    class number(4) references class(id),/*外键约束；也可加在表级上，如：constraint stu_class_fk foreign key(class) references class(id)*/
    email varchar2(50),
    constraint stu_name_email_uni unique(email, name)/*表约束，此时表示email和name的组合不能重复*/
    );
    ```
- Oracle的sequence序列：唯一的自动递增的一列数
    - `create sequence seq;` 创建一个序列
    - `drop sequence seq;`  删除一个序列
    - `select seq.nextval from dual;` 利用sequence中的nextval字段获取序列中的下一个数
    - 示例：
	    `create sequence seq_stu_id start with 1 increment by 1;` 产生一个从1开始每次递增1的序列
	    `insert into stu values(seq_stu_id.nextval, 'name', 0, 18, sysdate, 1, 1, 'oldinaction@qq.com');` sysdate获取系统时间

#### 删除表

- 删除表 `drop table table_name;` 如果存在外键约束，应该先删除含有外键约束的那个表，再删除被参考的那个表
- 清空表数据 `delete from table_name;`

#### 复制表

- 复制表结构及数据到新表 `CREATE TABLE 新表 AS SELECT * FROM 旧表`
- 只复制表结构到新表 `CREATE TABLE 新表 AS SELECT * FROM 旧表 WHERE 1=2`
- 复制部分字段 `create table b as select row_id, name, age from a where 1<>1`
- 复制旧表的数据到新表(假设两个表结构一样) `INSERT INTO 新表 SELECT * FROM 旧表`
- 复制旧表的数据到新表(假设两个表结构不一样) `INSERT INTO 新表(字段1,字段2,.......) SELECT 字段1,字段2,...... FROM 旧表`
- 创建临时表并复制数据 `create global temporary table ybase_tmptable_storage on commit delete rows as select * from ycross_storage where 1=2;` 其中`on commit delete rows`表示此临时表每次在事物提交的时候清空数据

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
            and ys.yes_storage = 1) -- 可以拿到update的表ycross_storage，且不能关联进去，否则容易出现一对多错误
    where exists (select 1 from sql_ctninfo sc where ys.box_number = sc.ctnno); -- where只能拿到update的表(不能拿到form的)
    -- 除了set(里面)限制了需要更新的范围，where(外面)也需要限制
    ```

### 修改表结构

- 添加一个字段 `alter table stu add(addr varchar(100));`
- 修改字段类型 `alter table stu modify addr varchar(150);`
    - 修改之后的字段容量必须大于原有数据的大小
- 修改字段名 `alter table stu change addr address varchar(50);`
- Oracle删除、添加表的约束条件
    - 删除外键约束 `alter table stu drop constraint stu_class_fk;`
	- 增加外键约束 `alter table stu add constraint stu_class_fk foreign key(class) references class(id);`

### 索引

- Oracle索引
    - 当给表加主键或者唯一约束时，Oracle会自动将此字段建立索引；给字段建立索引后，查询快读取慢
    - `create index idx_stu_email on stu(email);` 建立索引idx_stu_email
    - `drop index idx_stu_email;` 删除索引idx_stu_email

### 视图

- 视图创建：`create view 视图名 as 表(通过select子查询得到);`
- Mysql写法

    ```sql
    create view v1 as select deptno, avg(sal) 'avg_sal' from emp group by deptno;
    create view v2 as
    select deptno, avg_sal, grade from v1
    join salgrade s
    on (v1.avg_sal between s.losal and s.hisal)
    ;
    ```
- Oracle写法

    ```sql
    create view v$_view as
	select deptno, avg_sal, grade from
	(select deptno, avg(sal) 'avg_sal' from emp group by deptno) t1
	join salgrade s
	on (t1.avg_sal between s.losal and s.hisal)
	;
    ```
- Mysql创建视图的select语句不能包含from子句中的子查询，可以创建两次视图。而Oracle可以包含子查询
- 视图就相当于一个子查询，建立视图可以简化查询、保护数据，但是增加维护难度
- 可以更新视图里面的数据，但是更新的是实际中的表的数据，故一般不这么做

### Oracle数据字典

- 描述系统自带的数据字典表 `desc dictionary;`
- `select * from dictionary;`
    - `select table_name from user_tables;` 显示当前用户下有哪些表
    - `select view_name from user_views;` 显示当前用户下有哪些视图
    - `select constraint_name, table_name from user_constraints;` 显示当前用户下有哪些约束
    - `select index_name from user_indexes;` 显示当前用户下有哪些索引

### 三范式

- 三范式
    - 第一范式：要有主键，列不可分。(如：如果要分别获取姓、名，则应该设计两个字段，而不应该设置为姓名一个字段当查询出来后再进行分割)
    - 第二范式：不能存在部分依赖。即当一张表中有多个字段作为主键时，非主键的字段不能依赖于部分主键
    - 第三范式：不能存在传递依赖。如：雇员表中描述雇员需要描述他所在部门，因此只需记录其部门编号即可，如果把部门相关的信息(部门名称、部门位置)加入到雇员表则存在传递依赖
- 三范式强调的是表不存在冗余数据(同样的数据不存第二遍)
- 符合了三范式后会增加查询难度，要做表连接

### 设计表

- 设计树状结构的存

```sql
/*创建表*/
create table article
(
id int primary key,
cont text,
pid int,/*注释：表示父id*/
isleaf int(1),/*注释：0代表非叶子节点，1代表叶子节点*/
alevel int(2)/*注释：表示层级*/
);

/*插入数据*/
insert into article values(1,'蚂蚁大战大象', 0, 0, 0);
insert into article values(2,'大象被打趴下了', 1, 0, 0);
insert into article values(3,'蚂蚁也不好过', 2, 1, 2);
insert into article values(4,'瞎说', 2, 0, 2);
insert into article values(5,'没有瞎说', 4, 1, 3);
insert into article values(6,'怎么可能', 1, 0, 1);
insert into article values(7,'怎么没有可能', 6, 1, 2);
insert into article values(8,'可能性是很大的', 6, 1, 2);
insert into article values(9,'大象进医院了', 2, 0, 2);
insert into article values(10,'护士是蚂蚁', 9, 1, 3);

/*显示*/
蚂蚁大战大象
  大象被打趴下了
    蚂蚁也不好过
    瞎说
      没有瞎说
    大象进医院了
      护士是蚂蚁
  怎么可能
    怎么没有可能
    可能性是很大的
```

## 数据库表信息

- `show databases;` 显示所有数据库

```html
+--------------------+
| Database           |
+--------------------+
| information_schema |
| sqltest            |
+--------------------+
```

> Oracle一个实例，就是一个数据库，所以没有对应的 show databases 语句。使用`select * from gv$instance;`查看所有实例

- `use sqltest` 选择数据库
- `show tables;` 显示该数据库的所有表

```html
+-------------------+
| Tables_in_sqltest |
+-------------------+
| dept              |
| emp               |
| salgrade          |
+-------------------+
```

- 雇员表`desc emp;`或者`describe emp;` 描述一张表的字段详情
    - date只包含年月日，datetime、timestamp包含了完整的日期时间

```html
+----------+-------------+------+-----+---------+-------+
| Field    | Type        | Null | Key | Default | Extra |
+----------+-------------+------+-----+---------+-------+
| empno    | int(4)      | NO   |     | NULL    |       |雇员编号
| ename    | varchar(10) | YES  |     | NULL    |       |雇员姓名
| job      | varchar(9)  | YES  |     | NULL    |       |工种
| mgr      | int(4)      | YES  |     | NULL    |       |经理人编号
| hiredate | timestamp   | YES  |     | NULL    |       |雇佣日期
| sal      | double(7,2) | YES  |     | NULL    |       |工资
| comm     | double(7,2) | YES  |     | NULL    |       |津贴
| deptno   | int(2)      | YES  |     | NULL    |       |部门编号
+----------+-------------+------+-----+---------+-------+
```
- 部门表`desc dept;`

```html
+--------+-------------+------+-----+---------+-------+
| Field  | Type        | Null | Key | Default | Extra |
+--------+-------------+------+-----+---------+-------+
| deptno | int(2)      | NO   |     | NULL    |       |部门编号
| dname  | varchar(14) | YES  |     | NULL    |       |部门名称
| loc    | varchar(13) | YES  |     | NULL    |       |所在地
+--------+-------------+------+-----+---------+-------+
- 薪资表`desc salgrade;`
+-------+---------+------+-----+---------+-------+
| Field | Type    | Null | Key | Default | Extra |
+-------+---------+------+-----+---------+-------+
| grade | int(2)  | YES  |     | NULL    |       |薪资级别
| losal | int(11) | YES  |     | NULL    |       |最低薪资
| hisal | int(11) | YES  |     | NULL    |       |最高薪资
+-------+---------+------+-----+---------+-------+
```
- sqltest中含有emp、dept、salgrade三张表，具体数据如下：

    - `select * from emp;`

    ```html
    +-------+--------+-----------+------+---------------------+---------+---------+--------+
    | empno | ename  | job       | mgr  | hiredate            | sal     | comm    | deptno |
    +-------+--------+-----------+------+---------------------+---------+---------+--------+
    |  7369 | smith  | clerk     | 7902 | 1980-12-17 00:00:00 |  800.00 |    NULL |     20 |
    |  7499 | allen  | salesman  | 7698 | 1981-02-20 00:00:00 | 1600.00 |  300.00 |     30 |
    |  7521 | ward   | salesman  | 7698 | 1981-02-20 00:00:00 | 1250.00 |  500.00 |     30 |
    |  7566 | jones  | manager   | 7839 | 1981-02-04 00:00:00 | 2975.00 |    NULL |     20 |
    |  7654 | martin | salesman  | 7698 | 1981-09-28 00:00:00 | 1250.00 | 1400.00 |     30 |
    |  7698 | blake  | manager   | 7839 | 1981-05-01 00:00:00 | 2850.00 |    NULL |     30 |
    |  7782 | clark  | manager   | 7839 | 1981-06-09 00:00:00 | 2450.00 |    NULL |     10 |
    |  7788 | scott  | analyst   | 7566 | 1987-04-19 00:00:00 | 3000.00 |    NULL |     20 |
    |  7839 | king   | president | NULL | 1981-11-17 00:00:00 | 5000.00 |    NULL |     10 |
    |  7844 | turner | salesman  | 7698 | 1981-09-08 00:00:00 | 1500.00 |    0.00 |     30 |
    |  7876 | adams  | clerk     | 7788 | 1987-05-23 00:00:00 | 1100.00 |    NULL |     20 |
    |  7900 | james  | clerk     | 7698 | 1981-03-12 00:00:00 |  950.00 |    NULL |     30 |
    +-------+--------+-----------+------+---------------------+---------+---------+--------+
    ```
    - `select * from dept;`
    
    ```html
    +--------+------------+----------+
    | deptno | dname      | loc      |
    +--------+------------+----------+
    |     10 | accounting | new york |
    |     20 | research   | dallas   |
    |     30 | sales      | chicago  |
    |     40 | operations | boston   |
    +--------+------------+----------+
    ```
    
    - `select * from salgrade;`
    
    ```html
    +-------+-------+-------+
    | grade | losal | hisal |
    +-------+-------+-------+
    |     1 |   700 |  1200 |
    |     2 |  1201 |  1400 |
    |     3 |  1401 |  2000 |
    |     4 |  2001 |  3000 |
    |     5 |  3001 |  9999 |
    +-------+-------+-------+
    ```

## Mysql连接JDBC

- 先在Mysql官网下载驱动JDBC(Mysql Drivers提供了很多语言的驱动)：mysql-connector-java-5.0.8
- 导包：在项目上右键->Build Path->Add External archives->mysql-connector-java-5.0.8-bin.jar
- 示例如下：

    ```java
    package cn.aezo.mysql;

    import java.sql.*;

    public class ConnectionMySQL {
        public static final String URL = "jdbc:mysql://127.0.0.1:3306/test";//或者jdbc:mysql://127.0.0.1:3306/test?user=用户名&password=密码
        public static final String USERNAME = "root";
        public static final String PASSWORD = "root";
        
        public static void main(String[] args) throws SQLException {
            Connection conn = null;
            Statement stmt = null;
            ResultSet rs = null;
            try {
            // 1. 实例化驱动，注册驱动(实例化时自动向DriverManager注册，不需显示调用DriverManager.registerDriver方法)
                Class.forName("com.mysql.jdbc.Driver");//或者new com.mysql.jdbc.Driver();
                // 2. 获取数据库的连接  
                conn = DriverManager.getConnection(URL, USERNAME, PASSWORD);  
                // 3. 获取表达式
                stmt = conn.createStatement();  
                // 4. 执行 SQL 
                rs = stmt.executeQuery("select * from user where id =1");
                // 5. 显示结果集里面的数据  
                while(rs.next()) {  
                    System.out.println(rs.getInt("id"));  
                    System.out.println(rs.getString("username"));  
                    System.out.println(rs.getString("password"));  
                }
            } catch (ClassNotFoundException e) {
                System.out.println("驱动类没有找到！");
                e.printStackTrace();  
            } catch (SQLException e) {  
                e.printStackTrace();  
            } finally {
                // 6. 释放资源   
                try {
                    if(rs != null) {
                        rs.close();
                        rs = null;
                    }
                    if(stmt != null) {
                        stmt.close();
                        stmt = null;
                    }
                    if(conn != null) {
                        conn.close();
                        conn = null;
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }	
            } 
        }  
    }
    ```
















---