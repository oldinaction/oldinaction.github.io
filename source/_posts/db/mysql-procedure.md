---
layout: "post"
title: "mysql-procedure"
date: "2017-08-24 20:33"
categories: [db]
tags: [mysql, procedure]
---

## 简介

- 存储过程调试工具：`dbForge Studio for MySQL`

## 存储过程示例

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


---
