---
layout: "post"
title: "sql基础"
date: "2017-09-30 12:51"
categories: [db]
tags: [mysql, oracle, sql]
---

## SQL基础

- 下文未做特殊说明的语句都是基于Mysql的语法
- [mysql练习题](https://github.com/bjmashibing/InternetArchitect/blob/master/13mysql%E8%B0%83%E4%BC%98/mysql%E7%BB%83%E4%B9%A0%E9%A2%98.md)

## 设计表

### 三范式

- 三范式
    - 第一范式：要有主键，列不可分。(如：如果要分别获取姓、名，则应该设计两个字段，而不应该设置为姓名一个字段当查询出来后再进行分割)
    - 第二范式：不能存在部分依赖。即当一张表中有多个字段作为主键时，非主键的字段不能依赖于部分主键
    - 第三范式：不能存在传递依赖。如：雇员表中描述雇员需要描述他所在部门，因此只需记录其部门编号即可，如果把部门相关的信息(部门名称、部门位置)加入到雇员表则存在传递依赖
- 三范式强调的是表不存在冗余数据(同样的数据不存第二遍)
- 符合了三范式后会增加查询难度，要做表连接

### 常用建表模型

- 字典表(t_type_code)：id、type、code、name、value、note、rank(排序)、permission_code(权限落在行级)、valid_status、input_user_id、input_time、update_user_id、update_time
- 大字段表
- 树型表(t_structure)：id、structure_type_code(树类型)、parent_id、node_level、node_code、node_name、node_note、node_rank(节点排序)
- 属性表(t_attr)：id、attr_type、parent_id、code、value、note、permission_code(属性表可和树型表连用)
- 权限相关表
    - 权限组(t_security_group)：id、security_group、note
    - 权限(t_promission)：id、promission、note
    - 权限组-权限关系表(t_security_group_promission、多对多)：id、security_group、promission
    - 用户权限组关系表(t_user_security_group、多对多)：id、user_id、security_group
- 角色相关表 `RBAC`
    - 角色类型树：如总经理、销售经理、市场经理、员工
    - 部门树
- 主要实体暂存功能

### 案例

- 根据不同的拜访目的显示不同拜访结果和子结果，根据拜访结果归纳出错误客户信息(某几个拜访结果:信息错误-电话错误; 信息错误-三次无人接听)的拜访
    - 原始情况：拜访结果和子结果以树型存储，根据不同的拜访目的存储不同"XXX拜访目的-拜访结果"树(拜访结果大致相同)，且保存树节点ID为了提高查询效率；拜访表添加一个结果状态字段用来在保存的时候根据不同的结果归纳出最终的状态(已提交/信息错误/其他)
    - 导致困境
        - 拜访结果确实可根据数据库定义的"XXX拜访目的-拜访结果"树自动联动。但是查询拜访时想获取同一类型，则搜索选项的下拉都很难显示(要基于所有的结果根据结果代码group by, 而且有可能结果的名称不同)，获取到代码后再根据代码查询到相应的节点ID，通过IN(结果ID)的进行sql查询
        - 基于不同结果提取出一个最终的状态，导致每次修改数据都要更新此状态
    - 建议方案
        - 数据库中只保存一份拜访结果和子结果(将代码和名称归纳到一起)，展示的时候写属性代码矫正联动显示；保存拜访的时候保存结果代码。(最好是拜访结果/拜访目的单独维护表)
        - 去掉归纳字段，所有的查询直接根据结果代码来(可利用索引优化查询)

### 设计树状结构的存储

```sql
/*创建表*/
create table article(
    id int primary key,
    cont text,
    pid int,/*注释：表示父id*/
    isleaf int(1),/*注释：0代表非叶子节点，1代表叶子节点*/
    alevel int(2)/*注释：表示层级(可通过层级0表示非叶子节点)*/
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

-- 使用递归打印树状结构
create or replace procedual p(v_pid acticle.pid%type, v_level binary_integer) is
  cursor c is select * from article where pid = v_pid;
  v_preStr varchar2(1024) = '';
begin
  for i in 1..v_level loop
    v_preStr := v_preStr || '****';
  end loop;
  for v_article in c loop
    dbms_output.put_line(v_preStr || v_article.cont);
    if(v_article.isleaf = 0) then
      p(v_article.id, v_preStr + 1);
    end if;  
  end loop;
end;
/
exec p(0, 0);
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

## 数据库模式定义语言DDL(Data Definition Language)

### 创建和使用数据库

- `create database sqltest;/*创建数据库*/`
- `use sqltest;/*使用数据库，之后在这个数据库上进行表的创建、展示等操作*/`

### 数据库基本

- Mysql数据类型，参考[数据类型的优化](/_posts/db/sql-optimize.md#数据类型的优化)
    - `tinyint`     超短整型，存储长度1个字节(带符号存储区间：-127 ~ 127，不带符号存储区间：0-255)
    - `smallint`    短整型，存储长度为2个字节
    - `mediumint`   中整型，存储长度为3个字节
    - `int`		    整型(Integer)，**存储长度4个字节**(2^32-1，有符号signed区间：-2147483647 ~ 2147483647，无符号unsigned区间：0 ~ 4294967295)。最大显示11个字节，int(1)也会占用4个字节，只是最大显示长度为1，insert超过1个长度的数字还是可以成功的。类似于Oracle里的的number(X)
    - `bigint`      长正型(Long)，**存储长度为8个字节**。类似于Oracle里的的number(X)
    - `double`		浮点型(Float)，相当于Oracle里的的 number(X, Y)
    - `decimal`     金额(Bigdecimal)，相当于Oracle里的的 decimal(X, Y)。decimal(2,1) 表示总数据长度不能超过2位，且小数要占1位，因此最大为9.9
    - `char`		定长字符串(String)，同Oracle的char
    - `varchar` 	变长字符串(String)，最大255字节，相当于Oracle里的的varchar2
    - `datetime`	日期(DateTime/LocalDateTime)，相当于Oracle里的date
    - `tinytext`    短文本型(String)。最大长度255个字节(2^8-1)，存储可变长度的非Unicode数据，可存储textarea中的换行格式
    - `text`		文本型(String)。最大长度为65535个字节(2^31-1)，其他同tinytext
    - `longtext`	长文本型(String)。最大4G，相当于Oracle里的long，其他同tinytext
    - `tinyblob/blob/longblob` 二进制数据(byte[])
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

- 删除表 `drop table table_name;` 如果存在外键约束，应该先删除含有外键约束的那个表，再删除被参考的那个表(也会删除表结构)

#### 复制表

- **复制表结构及数据到新表** `create table 新表 as select * from 旧表`
    - oracle不会复制到表结构的备注和默认值；mysql可以复制备注，但是主键会丢失
    - 根据备份表还原数据的时候需要delete掉原表的数据，不能drop**
    - `200w`的数据`3s`复制完成
- 只复制表结构到新表 `create table 新表 as select * from 旧表 where 1=2`
    - `create table t2 like t1` like创建出来的新表包含源表的完整表结构和索引信息(mysql适用)。oracle支持as，也是只有表结构没有索引；oracle不支持like
- 复制部分字段 `create table b as select row_id, name, age from a where 1<>1`
- **复制旧表的数据到新表(假设两个表结构一样)** `insert into 新表 select * from 旧表`
- 复制旧表的数据到新表(假设两个表结构不一样) `insert into 新表(字段1,字段2,.......) select 字段1,字段2,...... from 旧表`
- 创建临时表并复制数据 `create global temporary table ybase_tmptable_storage on commit delete rows as select * from ycross_storage where 1=2;` 其中`on commit delete rows`表示此临时表每次在事物提交的时候清空数据

### 修改表结构

- 添加一个字段 `alter table stu add(addr varchar(100));`
- 修改字段类型 `alter table stu modify addr varchar(150);`
    - 修改之后的字段容量必须大于原有数据的大小
- 修改字段名 `alter table stu change addr address varchar(50);`
- Oracle删除、添加表的约束条件
    - 删除外键约束 `alter table stu drop constraint stu_class_fk;`
	- 增加外键约束 `alter table stu add constraint stu_class_fk foreign key(class) references class(id);`

### 索引

- Mysql索引

    ```sql
    -- ALTER TABLE用来创建普通索引、UNIQUE索引或PRIMARY KEY索引
    alter table d_user add index idx_name (name)
    alter table d_user add unique (card_no)
    alter table d_user add primary key (id)

    -- CREATE INDEX可对表增加普通索引或UNIQUE索引
    create index idx_name_age on d_user (name, age)
    create unique index idx_card_no on d_user (card_no)

    -- 删除索引
    drop index d_user on talbe_name
    alter table d_user drop index index_name
    alter table table_name drop primary key -- 删除主键索引，一个表只能有一个主键，因此无需指定主键索引名

    -- 查看索引
    show index from d_user;
    show keys from d_user;
    ```
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

## 数据库操作语言DML(Data Manipulation Language，即CRUD)

> 数据参考下文【数据库表信息】
> 先登录并选择数据库mysql -uroot -proot sqltest
> 先复制表emp、dept、salgrade，如：create table dept2 as select * from dept;

### 插入记录

- 按字段顺序一一插入值 `insert into dept2 values(50, 'game', 'bj');`
- 指定部分字段的值 `insert into dept2(deptno, dname) values(60, 'game2');` 未指定的字段取默认值
- 根据从子查询的值插入 `insert into dept2 select * from dept;` 子查询拿出来的数据和表结构要一样
    - `insert into tab1(id, name, status) select t.user_id, t.username, '1' from tab2 t where t.sex = 1`
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
- `delete from emp2 where deptno in (select deptno from dept2 where deptno < 25)` 子查询不能有别名(oracle)
- `truncate table emp2;` oracle清空表数据，适用于表中含有大量数据

### 查询

#### 书写顺序

- **书写顺序和执行顺序都是按照`select-from-where-group by-having-order by-limit`进行的**

```sql
mysql>select count(num) 	/*注释：组函数(group by时，select中的字段都需要时聚合后的)*/
    ->from emp			/*注释：此语句是不能执行的*/
    ->where sal > 1000		/*注释：对数据进行过滤(group by时，where中的字段无需聚合)*/
    ->group by deptno		/*注释：对过滤后的数据进行分组*/
    ->having avg(sal) > 2000	/*注释：对分组后的数据进行限制(group by时，需要聚合)*/
    ->order by deptno desc	/*注释：对结果进行排序(group by时，需要聚合)*/
    ->limit 2,3			/*注释：从第3条数据开始，取3条数据*/
    ->;
```

#### 查询

##### 基础查询

- `select ename, sal*12 from emp;` 算年薪
- `select now(), curdate() 'current date', 2*3;` 显示系统时间和数学计算

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
    - **使用`between and`相当于 `>= and <=`**
        - `between to_date('2000-01-01', 'yyyy/mm/dd') and to_date('2000-01-31', 'yyyy/mm/dd')` 查询的是`2000-01-01 00:00:00`到`2000-01-31 00:00:00`的数据
- `select ename, sal, comm from emp where comm is not null;` 使用`is null`或者`is not null`找出有关空值的条目
    - `=、!=`默认是查询不为空的数据
- `select ename, sal from emp where ename in('king', 'allen', 'abc');` 使用`in()`或者`not in()`表示相应字段的值是否在这些值里面的条目(本质是循环查询)
- `select ename from emp where ename like '_a%';` like模糊查询
    - `_`代表任意一个字符，`%`代表任意个字符
    - '%xxx'左like、'xxx%'右like、'%xxx%'两边like
    - 如果字段中含有特殊字符，需要用反斜线转义，如：`like 'a\_%'` 表示以`a_`开头的字符串(Oracle 需为`like 'a\_%' escape '\'`)
    - 也可以修改转义字符，如：`select ename from emp where ename like '_*_a%' escape '*';` 将转义字符设为`*`
- `select ename, sal, deptno from emp order by deptno asc, ename desc;` order by排序(显示按照deptno升序排序，如果deptno相同，再按照ename降序排序)
    - 默认是asc升序；desc代表降序
    - order by 语句对null字段的默认排序（可进行设置）
        - Oracle 结论 
            - order by colum asc 时，null默认被放在最后
            - order by colum desc 时，null默认被放在最前
            - nulls first 时，强制null放在最前，不为null的按声明顺序[asc|desc]进行排序
            - nulls last 时，强制null放在最后，不为null的按声明顺序[asc|desc]进行排序 
            - 对中文排序 [1]

                ```sql
                -- 按中文拼音进行排序: schinese_pinyin_m
                -- 按中文部首进行排序: schinese_radical_m
                -- 按中文笔画进行排序: schinese_stroke_m
                select * from team order by nlssort(排序字段名, 'nls_sort = schinese_pinyin_m');
                -- 也可以设置session的或配置的排序策略
                -- 更改配置文件: 
                alter system set nls_sort='schinese_pinyin_m' scope=spfile;
                -- 更改session: 
                alter session set nls_sort = schinese_pinyin_m;
                ``` 
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
    - 出现在select列表中的字段，如果没有出现在组函数里面则必须出现在group by子句里面，**或者group by中有主表的id**
        - 如：`select deptno, max(sal) from emp group by deptno;` 求每个部门的最高工资。此时是根据部门分组，所有每个部门都只有一条输出
        - 如：`select w.work_no from d_work w left join d_work_tag wt on wt.work_id = w.id group by w.id`
- having对group by 分组后的结果进行限制
    - `select deptno, avg(sal) from emp group by deptno having avg(sal) > 2000;` 求部门平均工资大于2000的部门

##### 表连接

- 交叉连接(cross join)，又称笛卡尔连接，如果每个表分别具有n和m行，则结果集将具有n*m行。如：`select ename, dname from emp cross join dept;`
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
- **关联表时，and的位置**
    - `left join/right join` 当`and`在`on`的后面只是对关联表的过滤(主表记录默认全部取出。如果能通过on和and关联上副表最好，关联不上则副表对应字段为Null)，当`and`在`where`后面则是对关联之后的视图进行过滤(会影响主表记录的条数)
    - `join` 不管`and`在什么位置都会影响主表记录的条数
- Oracle `select 1 as a, t.b, t.c from dual left join (select 2 as b, 3 as c from dual) t on 1=1` 可返回a,b,c三个字段的值。(join必须要有一个on)

##### 子查询

- 可以把子查询当成查询到的一张表（**子查询连接到主查询上时，子查询内部无法拿到主查询数据**）
- 求出所有雇员中工资最高的那个人
    - 正确写法=>`select ename, sal from emp where sal = (select max(sal) from emp);` 利用的子查询
    - 错误写法=>`select ename, max(sal) from emp;`因为max(sal)只有一行输出，但是可能有很多人的工资都是一样的最高，所以不匹配。此时Oracle会报错，但是Mysql可以显示，但是结果是错误的
- 哪些人的工资位于所有人平均工资之上`select ename, sal from emp where sal > (select avg(sal) from emp);`
- 在from语句中的子查询需要起一个表的别名(Oracle可不写)，否则Mysql报ERROR 1248错误。子查询得到的表接在where语句中不需要别名，但如果把它当做一个值则需要加括号
    - 部门平均工资中最高的。此时不起别名(t)则报错，但是Oracle不会报错`select max(avg_sal) from (select deptno, avg(sal) 'avg_sal' from emp group by deptno) t;`

##### 子查询和表连接举例

- **子查询连接到主查询上时，子查询内部无法拿到主查询数据**
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

##### oracle分页

```sql
-- 无分页
select * from t_customer_line;

-- 无order by分页
select * from 
    (select rownum as rowno, t.* from emp t where rownum <= 10) a 
where a.rowno > 0;

-- 有order by分页
select * from 
    (select tt.*, rownum as rowno from 
        (select t.* from emp t order by create_time desc) tt 
    where rownum <= 20) a 
where a.rowno > 10;

-- 分页并返回总条数
select *
    from (select rownum as rn, paging_t1.*
            from (select t.*, count(*) over() paging_total
                    from emp t
                    order by t.id) paging_t1
            where rownum <= 20) paging_t2
    where paging_t2.rn > 10;
```

#### union合集

- Oracle `select 1 as a from dual union select 2 as b from dual`

#### intersect交集

#### except差集

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

                // 返回插入后生成的主键
                String sql = "INSERT INTO user(name) VALUES (?)";
                // PreparedStatement preparedStatement = conn.prepareStatement(sql, {"id"}); // oracle(也使用于mysql)
                PreparedStatement preparedStatement = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS); // 常用，如mysql
                preparedStatement.setString(1, "smalle");
                preparedStatement.executeUpdate();
                ResultSet generatedKeys = preparedStatement.getGeneratedKeys();
                while (generatedKeys.next()) {
                    long generateKey = generatedKeys.getLong(1); // 返回的主键
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

## (Mysql)事物

- 事物sql

```sql
--查看是否是自动提交 1表示开启(默认)，0表示关闭
select @@autocommit;
--设置关闭
set autocommit = 0;
-- 开始事物
start transaction;
-- Mysql和Oracle提交事物`commit;`；Oracle的撤销操作`rollback;`
commit;

-- 设置当前session的隔离级别
set session transaction isolation level read uncommitted;
```
- ACID
    - A原子性：innodb通过undo log实现
    - I隔离性：通过锁实现
    - D持久性：innodb通过redo log实现
    - C一致性：通过上述AID实现
- 隔离级别
    - 产生数据不一致的情况：脏读、不可重复读、幻读
        - 脏读：读到了其他事物未提交的数据
        - 不可重复读：第一次读取记录后，其他事物修改了该记录，再次读取此记录发现数据变化了
        - 幻读：第一次读取记录发现没有id=10的行，但是在插入id=10时提示已存在此行，尽管再次读取还是没有id=10
            - mysql 的幻读并非什么读取两次返回结果集不同，而是事务在插入事先检测不存在的记录时(mysql插入时会隐式读取一次)，惊奇的发现这些数据已经存在了，之前的检测读获取到的数据如同鬼影一般。**不可重复读侧重表达`读-读`，幻读则是说`读-写`，用写来证实读的是鬼影**
    - 从上往下，隔离级别越来越高，意味着数据越来越安全
        - `read uncommitted` 读未提交。会出现脏读、不可重复读、幻读
        - `read commited` 读已提交(oracle默认级别)。会出现不可重复读、幻读
        - `repeatable read` 可重复读(mysql默认级别)。会出现幻读
        - `seariable` 序列化执行，串行执行
- Oracle的transaction(事物)
    - 一个transaction起始于一个dml(增删查改)语句
    - 当执行撤销"rollback;"后，回到最原始状态，相当于此transaction结束；或当执行提交"commit;"后，此transaction结束（此时在撤销则不能回到原始状态）
    - 当执行一个ddl语句(如：创建表create table)或者一个dcl语句(如：设置权限grant)后，transaction也自动结束

## Mysql日志原理

- 参考文章 [^2] [^3]

### InnoDB日志(Redo/Undo)

- `Redo log` (重做日志)和 `Undo log` 都是innodb存储引擎才有日志文件
- `Redo Log` 是为了实现数据持久性
    - **当发生数据修改的时候， innodb引擎会先将数据更新内存并写到redo log(buffer)中，此时更新就算是完成了**；同时innodb引擎会在合适的时机将记录操作到磁盘中
    - redo log是**固定大小**的，是**循环写**的过程，空间会用完(可通过参数配置其大小)
        - 如果redolog太小，会导致很快被写满，然后就不得不强行刷redolog，这样WAL机制(见下文)的能力就无法发挥出来。如果磁盘能达到几TB，那么可以将redolog设置4个一组，每个日志文件大小为1GB，写到3号文件末尾后就回到0号文件开头。`show variables like '%innodb_log_file%';`查看单个文件的大小
    - redo log是**物理日志**，数据页中为真实二级制数据，恢复速度快
    - innodb存储引擎数据的单位是页，redo log也是基于页进行存储，一个默认16K大小的页中存了很多512Byte的log block，log block的存储格式如[log block header 12Byte，log block body 492 Bytes，log block tailer 8 Bytes]
    - 用途是重做数据页。有了redo log之后，innodb就可以保证即使数据库发生异常重启，之前的记录也不会丢失，系统会自动恢复之前记录，叫做crash-safe(不包含误删数据的恢复)
- 既然要避免io，为什么写redo log的时候不会造成io的问题？

    ![mysql-redo-log.png](/data/images/db/mysql-redo-log.png)
    - 如果每次更新操作都需要直接写入磁盘 **(在磁盘中找到相关的记录并更新)**，整个过程的IO成本和查找成本都很高。针对这种情况，MySQL采用的是WAL技术（Write-Ahead Logging）：先写日志，再写磁盘(虽然写日志也是写到磁盘，但是不用考虑原数据的位置)
    - 内部是基于缓存实现，可先将数据写到log buffer。为了确保每次日志都能写入到事务日志文件中，之后操作系统定期调用fsync(等待写磁盘操作结束，然后返回)写入到磁盘
    - 图二中
        - 控制commit动作是否刷新log buffer到磁盘，可通过变量 `innodb_flush_log_at_trx_commit` 的值来决定。该变量有3种值：0、1、2，默认为1
            - 0：事务提交时不会将log buffer中日志写入到os buffer，而是每秒写入os buffer并调用fsync()写入到log file on disk中。也就是说设置为0时是(大约)每秒刷新写入到磁盘中的，当系统崩溃，会丢失1秒钟的数据
            - 1：事务每次提交都会将log buffer中的日志写入os buffer并调用fsync()刷到log file on disk中。这种方式即使系统崩溃也不会丢失任何数据，但是因为每次提交都写入磁盘，IO的性能较差
            - 2：类似0。区别是0虽然是写入到用户空间缓存，再写入到文件。但是写入文件必须通过操作系统完成，此时还是会写入到操作系统缓存，最后写入到文件
        - 安全性：1 > 0/2
        - 效率：2 > 0 > 1
- Undo Log是为了实现事务的原子性，在MySQL数据库InnoDB存储引擎中，还用Undo Log来实现多版本并发控制(简称MVCC)
    - 在操作任何数据之前，首先将数据备份到一个地方（这个存储数据备份的地方称为Undo Log），然后进行数据的修改。如果出现了错误或者用户执行了ROLLBACK语句，系统可以利用Undo Log中的备份将数据恢复到事务开始之前的状态
    - Undo log是**逻辑日志**，可以理解为
        - 当insert一条记录时，undo log中会记录一条对应的delete记录
        - 当update一条记录时，它记录一条对应相反的update记录
        - 当delete一条记录时，undo log中会记录一条对应的insert记录

### 服务端的日志Binlog

- Binlog(归档日志)是server层的日志，因此和存储引擎无关，其主要做mysql功能层面的事情
- 与Redo日志的区别
    - redo是innodb独有的， binlog是所有引擎都可以使用的
    - redo是物理日志，记录的是在某个数据页上做了什么修改，**binlog是逻辑日志（也是二进制格式）**，记录的是这个语句的原始逻辑
    - redo是循环写的，空间会用完；**binlog是可以追加写的**，不会覆盖之前的日志信息
- sync_binlog 参数来控制数据库的binlog刷到磁盘上去方式。参考[服务器参数设置](/_posts/db/sql-optimization.md#服务器参数设置)
- 有两份日志的历史原因
    - 一开始并没有InnoDB，采用的是MyISAM，但MyISAM没有crash-safe的能力，binlog日志只能用于归档
    - InnoDB是以插件的形式引入MySQL的，为了实现crash-safe，InnoDB采用了redolog的方案
- binlog一开始的设计就是不支持崩溃恢复(原库)的，如果不考虑搭建从库等操作，binlog是可以关闭的(`show variables like '%sql_log_bin%';`)
    - redolog主要用于crash-safe(原库恢复)，binlog主要用于恢复成临时库(从库)
    - 数据从 A-B-C 后，可根据binlog选择恢复的位置
- 一般在企业中数据库会有备份系统，可以定期执行备份，备份的周期可以自己设置。恢复数据的过程
    - 到最近一次的全量备份数据
    - 从备份的时间点开始，将备份的binlog取出来，重放到要恢复的那个时刻

### 数据更新的流程

![mysql-innodb-update.png](/data/images/db/mysql-innodb-update.png)

- 执行流程
    - 执行器先从存储引擎中查找数据。存储引擎查找时，如果在内存中直接返回，如果不在内存中，查询后返回
    - 执行器拿到数据之后会先修改数据，然后调用引擎接口重新写入数据
    - 存储引擎将数据更新到内存，同时写数据到redo中，此时处于prepare阶段，并通知执行器执行完成，随时可以操作
    - 执行器生成这个操作的binlog
    - 执行器调用引擎的事务提交接口，引擎把刚刚写完的redo改成commit状态，更新完成
- Redo log的两阶段提交(2PC)
    - prepare：redolog写入log buffer，并fsync持久化到磁盘，在redolog事务中记录2PC的XID，在redolog事务打上prepare标识
    - commit：binlog写入log buffer，并fsync持久化到磁盘，在binlog事务中记录2PC的XID，同时在redolog事务打上commit标识
    - 其中，prepare和commit阶段所提到的事务，都是指内部XA事务，即2PC。且此事物是包含在begin...commit的内部
    - 崩溃恢复过程
        - redolog prepare + binlog成功，提交事务
        - redolog prepare + binlog失败，回滚事务
        - 崩溃恢复后是会从checkpoint开始往后主动刷数据
            - checkpoint是当前要擦除的位置，擦除记录前需要先把对应的数据落盘
            - write pos到checkpoint之间的部分可以用来记录新的操作。checkpoint到write pos之间的部分等待落盘，恢复数据也是恢复这一部分
    - 原因
        - 可以使用binlog替代redolog进行数据恢复吗？
            - 不可以。innodb利用wal技术进行数据恢复，write ahead logging技术依赖于物理日志进行数据恢复，binlog不是物理日志是逻辑日志，因此无法使用
        - 可以只使用redolog而不使用binlog吗？
            - 不可以。redolog是循环写，写到末尾要回到开头继续写，这样的日志无法保留历史记录，无法进行数据复制
        - 为什么redolog和binlog要进行二阶段提交？
            - 如果redo log持久化并进行了提交，而binlog未持久化数据库就crash了，则从库从binlog拉取数据会少于主库，造成不一致。因此需要内部事务来保证两种日志的一致性

## SQLServer

- 表名和字段名均不区分大小写
- 命令行导入sql文件
    - `sqlcmd -S localhost -U sa -P root -d fedex -i C:\Users\smalle\Desktop\update20190528.sql`(windows上文件路径必须用右斜杠)


---

参考文章

[^1]: https://www.cnblogs.com/discuss/articles/1866953.html (Oracle中针对中文进行排序)
[^2]: https://www.cnblogs.com/f-ck-need-u/p/9010872.html
[^3]: http://zhongmingmao.me/2019/01/15/mysql-redolog-binlog/

