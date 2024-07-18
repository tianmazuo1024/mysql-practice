-- 删除表
DROP TABLE IF EXISTS t_test_2;
-- 复制表
CREATE TABLE t_test_2 AS SELECT * FROM t_test;
-- 指定主键
ALTER TABLE t_test_2 MODIFY id INT(11) NOT NULL PRIMARY KEY;
-- 创建索引
CREATE INDEX t_test_2_name ON t_test_2 (name);

-- 无索引
EXPLAIN SELECT * FROM t_test WHERE name LIKE "索引%";
-- 有索引：利用最左前缀匹配规则
EXPLAIN SELECT * FROM t_test_2 WHERE name LIKE "索引%";
-- 有索引：非最左前缀匹配规则
EXPLAIN SELECT * FROM t_test_2 WHERE name LIKE "%索引";

-- const
EXPLAIN SELECT * FROM t_test_2 WHERE id = 1;
-- ref
EXPLAIN SELECT * FROM t_test_2 WHERE name = "索引";
-- range
EXPLAIN SELECT * FROM t_test WHERE id > 1 AND id < 3;
EXPLAIN SELECT * FROM t_test_2 WHERE name > "索引";

-- 删除表
DROP TABLE IF EXISTS t_test_3;
-- 复制表
CREATE TABLE t_test_3 AS SELECT * FROM t_test;
-- 指定主键
ALTER TABLE t_test_3 MODIFY id INT(11) NOT NULL PRIMARY KEY;
-- 增加字段
ALTER TABLE t_test_3 ADD COLUMN sort TINYINT(1) NOT NULL DEFAULT '0';
-- 创建索引
CREATE INDEX t_test_3_name ON t_test_3 (name, sort);
-- 准备数据
UPDATE t_test_3 SET sort = 1 WHERE id = 1;
-- index
EXPLAIN SELECT name, sort FROM t_test_3 WHERE sort = 1;

-- 删除表
DROP TABLE IF EXISTS t_test_4;
-- 复制表
CREATE TABLE t_test_4 AS SELECT * FROM t_test;
-- 指定主键
ALTER TABLE t_test_4 MODIFY id INT(11) NOT NULL PRIMARY KEY;
-- 增加字段
ALTER TABLE t_test_4 ADD COLUMN sort TINYINT(1) NOT NULL DEFAULT '0';
-- 创建索引
CREATE INDEX t_test_4_name ON t_test_4 (name);
-- 创建索引
CREATE INDEX t_test_4_sort ON t_test_4 (sort);
-- 准备数据
UPDATE t_test_4 SET sort = 1 WHERE id = 1;
-- index_merge
EXPLAIN SELECT name, sort FROM t_test_4 WHERE id = 1 OR sort = 1;
EXPLAIN SELECT name, sort FROM t_test_4 WHERE name = "封面" OR sort = 1;

DROP TABLE IF EXISTS t_org;
CREATE TABLE t_org (
  id int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  name varchar(64) NOT NULL COMMENT '部门名称',
  PRIMARY KEY (id) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO t_org VALUES (1, '销售部');
INSERT INTO t_org VALUES (2, '研发部');

DROP TABLE IF EXISTS t_emp;
CREATE TABLE t_emp (
  id int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  branchid int(11) NOT NULL COMMENT '机构编码',
  name varchar(64) NOT NULL COMMENT '姓名',
  result varchar(128) DEFAULT NULL COMMENT '业绩',
  PRIMARY KEY (id) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO t_emp VALUES (1, 1, '张三', '优秀');
INSERT INTO t_emp VALUES (2, 1, '李四', '良好');
INSERT INTO t_emp VALUES (3, 2, '王五', '极好');
INSERT INTO t_emp VALUES (4, 2, '赵六', '较差');
INSERT INTO t_emp VALUES (5, 1, '钱七', NULL);
-- 内连接查询每个员工的业绩
EXPLAIN SELECT o.name, e.name, e.result FROM t_emp AS e, t_org AS o WHERE e.branchid = o.id AND e.name = "张三" AND o.name = "销售部";
EXPLAIN SELECT o.name, e.name, e.result FROM t_emp AS e, t_org AS o WHERE e.name = "张三" AND o.name = "销售部" AND e.branchid = o.id;
-- 外连接查询每个员工的业绩
EXPLAIN SELECT o.name, e.name, e.result FROM t_emp AS e LEFT OUTER JOIN t_org AS o ON e.branchid = o.id;

-- 删除表
DROP TABLE IF EXISTS t_test_5;
-- 复制表
CREATE TABLE t_test_5 AS SELECT * FROM t_test;
-- 指定主键
ALTER TABLE t_test_5 MODIFY id INT(11) NOT NULL PRIMARY KEY;
-- 增加字段
ALTER TABLE t_test_5 ADD COLUMN sort TINYINT(1) NOT NULL DEFAULT '0';
-- 创建索引
CREATE INDEX t_test_5_name ON t_test_5 (name);
-- 删除表
DROP TABLE IF EXISTS t_test_6;
-- 复制表
CREATE TABLE t_test_6 AS SELECT * FROM t_test;
-- 指定主键
ALTER TABLE t_test_6 MODIFY id INT(11) NOT NULL PRIMARY KEY;
-- 增加字段
ALTER TABLE t_test_6 ADD COLUMN sort TINYINT(1) NOT NULL DEFAULT '0';
-- 创建索引
CREATE INDEX t_test_6_name ON t_test_6 (name);
-- 子查询优化
SET optimizer_switch='semijoin=on';
EXPLAIN SELECT * FROM t_test_5 WHERE name IN (SELECT name FROM t_test_6 WHERE id  = 1);
EXPLAIN SELECT * FROM t_test_5 WHERE name IN (SELECT name FROM t_test_6 WHERE id IN (1, 2, 3));
-- 关闭半连接
SET optimizer_switch='semijoin=off';
EXPLAIN SELECT * FROM t_test_5 WHERE name IN (SELECT name FROM t_test_6 WHERE id  = 1);
EXPLAIN SELECT * FROM t_test_5 WHERE name IN (SELECT name FROM t_test_6 WHERE id IN (1, 2, 3));

-- NULL
EXPLAIN SELECT min(id) FROM t_test;
-- const
EXPLAIN SELECT * FROM t_test where id = 1;
EXPLAIN SELECT * FROM t_test_5 where name = "1242740190540349440";
-- PRIMARY/DEPENDENT SUBQUERY、index_subquery、func
EXPLAIN SELECT * FROM t_test_5 WHERE name IN (SELECT name FROM t_test_6) OR id = 22;
SHOW WARNINGS;
-- UNION/UNION RESULT、<union1,2>
EXPLAIN SELECT * FROM t_test_5 UNION SELECT * FROM t_test_6;
-- DEPENDENT SUBQUERY/DEPENDENT UNION/UNION RESULT、<union2,3>、func
EXPLAIN SELECT * FROM t_test WHERE name IN (SELECT name FROM t_test_5 UNION SELECT name FROM t_test_6);
SHOW WARNINGS;
-- DERIVED、<derived2>
EXPLAIN SELECT * FROM (SELECT id, COUNT(0) AS count FROM t_test GROUP BY id) AS t WHERE count > 0;

-- INSERT
EXPLAIN INSERT INTO t_test (name, value1, value2, value3) VALUES ('1', '1', '1', '1');
-- UPDATE
EXPLAIN UPDATE t_test SET name = '2' WHERE name = '1';
-- DELETE
EXPLAIN DELETE FROM t_test WHERE name = '2';

-- Using where; Using join buffer (Block Nested Loop)
CREATE TABLE t1 (c1 INT, c2 INT);
CREATE TABLE t2 (c1 INT, c2 INT);
CREATE TABLE t3 (c1 INT, c2 INT);
EXPLAIN SELECT * FROM t1 JOIN t2 ON t1.c1 = t2.c1;

-- 优化实践表结构
DROP TABLE IF EXISTS t_user;
CREATE TABLE t_user (
  id int(11) NOT NULL AUTO_INCREMENT,
  realname varchar(32) NOT NULL DEFAULT '',
  cardtype tinyint(1) NOT NULL DEFAULT '0' COMMENT '证件类型，0：身份证；1：驾照；2：护照',
  cardnum varchar(32) NOT NULL DEFAULT '' COMMENT '证件号码',
  gender tinyint(1) NOT NULL DEFAULT '-1' COMMENT '性别，-1：未知；0：女；1：男',
  age smallint(2) NOT NULL DEFAULT '0' COMMENT '年龄',
  PRIMARY KEY (id) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO t_user VALUES (1, '', 0, '', -1, -1);

DROP TABLE IF EXISTS t_user_auth;
CREATE TABLE t_user_auth (
  id int(11) NOT NULL AUTO_INCREMENT,
  userid int(11) NOT NULL,
  type tinyint(1) NOT NULL DEFAULT '0' COMMENT '登录类型，0：用户名；1：手机号；2：邮箱',
  identifier varchar(64) NOT NULL COMMENT '登录标识',
  credential varchar(64) NOT NULL COMMENT '登录凭证',
  PRIMARY KEY (id) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO t_user_auth VALUES (1, 1, 0, 'test', '123456');
INSERT INTO t_user_auth VALUES (2, 1, 1, '13888888888', '123456');
INSERT INTO t_user_auth VALUES (3, 1, 2, '123@abc.com', '123456');
INSERT INTO t_user_auth VALUES (4, 2, 0, 'test2', '123456');
INSERT INTO t_user_auth VALUES (5, 2, 1, '13999999999', '123456');
INSERT INTO t_user_auth VALUES (6, 2, 2, '456@abc.com', '123456');

-- 当数据量很少时会出现：Using join buffer (Block Nested Loop)
EXPLAIN SELECT userid, type FROM t_user_auth WHERE userid IN (SELECT id FROM t_user WHERE age BETWEEN 26 AND 33);

-- 初期数据量较少时
-- 删除表
DROP TABLE IF EXISTS user1;
-- 复制表
CREATE TABLE user1 AS SELECT * FROM user;
-- 指定主键
ALTER TABLE user1 MODIFY id INT(11) NOT NULL PRIMARY KEY;
-- 删除表
DROP TABLE IF EXISTS user_auth1;
-- 复制表
CREATE TABLE user_auth1 AS SELECT * FROM user_auth;
-- 指定主键
ALTER TABLE user_auth1 MODIFY id INT(11) NOT NULL PRIMARY KEY;
-- 仅保留user1表的10000条记录和user_auth1表的30000条记录
DELETE FROM user1 WHERE id > 10000;
DELETE FROM user_auth1 WHERE id > 30000;

SELECT COUNT(0) FROM user1;
SELECT COUNT(0) FROM user_auth1;

-- 初期查询
EXPLAIN SELECT userid, type FROM user_auth1 WHERE userid IN (SELECT id FROM user1 WHERE age BETWEEN 26 AND 33);

-- 创建索引
CREATE INDEX idx_user_age ON user1 (age);
CREATE INDEX idx_user_auth_userid ON user_auth1 (userid);
-- 删除索引
DROP INDEX idx_user_age ON user1;
DROP INDEX idx_user_auth_userid ON user_auth1;

-- 增加索引后
EXPLAIN SELECT userid, type FROM user_auth1 WHERE userid IN (SELECT id FROM user1 WHERE age BETWEEN 26 AND 33);

-- 创建索引
CREATE INDEX idx_user_age ON user (age);
CREATE INDEX idx_user_auth_userid ON user_auth (userid);
-- 删除索引
DROP INDEX idx_user_age ON user;
DROP INDEX idx_user_auth_userid ON user_auth;

-- 数据量慢慢积累起来
EXPLAIN SELECT userid, type FROM user_auth WHERE userid IN (SELECT id FROM user WHERE age BETWEEN 26 AND 33);

-- 内联接，将user作为驱动表
EXPLAIN SELECT ua.userid, ua.type FROM user u, user_auth ua WHERE u.id = ua.userid AND u.age >= 26 AND u.age <= 33;
-- 左外连接，将user作为驱动表
EXPLAIN SELECT ua.userid, ua.type FROM user u LEFT JOIN user_auth ua ON u.id = ua.userid AND u.age >= 26 AND u.age <= 33;
-- 左外连接，将user_auth作为驱动表
EXPLAIN SELECT ua.userid, ua.type FROM user_auth ua LEFT JOIN user u ON u.id = ua.userid AND u.age >= 26 AND u.age <= 33;

-- 第一次在userid上建索引，将user_auth的扫描范围从2832727缩小到2
-- 第二次在age上建索引，将user的扫描范围从1增大到470203
-- 第三次优化，利用覆盖索引，将userid单字段索引变成(userid, type)联合索引，时间从30s降到2s左右
EXPLAIN SELECT userid, type FROM user_auth WHERE userid IN (SELECT id FROM user WHERE age BETWEEN 26 AND 33);
-- 第四次优化，将范围匹配变成等值匹配：「age BETWEEN 26 AND 33」变成「age = 26」，分多次查询，单次查询时间从2s降到1s
EXPLAIN SELECT userid, type FROM user_auth WHERE userid IN (SELECT id FROM user WHERE age = 26);
-- 第五次优化，限定查询范围，增加LIMIT关键字，单次查询时间从1s降到0.005s左右
SELECT COUNT(0) FROM user u, user_auth ua WHERE u.id = ua.userid AND u.age = 26;
EXPLAIN SELECT userid, type FROM user_auth WHERE userid IN (SELECT id FROM user WHERE age = 26) LIMIT 1000;

-- 作为课后练习
-- 找出所有identifier重复的行
-- <subquery2>、<derived3>、<auto_key>、MATERIALIZED、SUBQUERY、DERIVED、Using temporary; Using filesort
EXPLAIN SELECT id, userid, type, identifier, credential FROM user_auth
WHERE identifier IN 
		(
			SELECT t.identifier FROM (SELECT identifier FROM user_auth GROUP BY identifier HAVING COUNT(0) > 1) t
		)
AND id NOT IN 
		(
			SELECT r.maxid FROM (SELECT MAX(id) AS maxid FROM user_auth GROUP BY identifier HAVING COUNT(0) > 1) r
		)
