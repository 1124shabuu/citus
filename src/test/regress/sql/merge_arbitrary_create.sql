SHOW server_version \gset
SELECT substring(:'server_version', '\d+')::int >= 15 AS server_version_ge_15
\gset
\if :server_version_ge_15
\else
\q
\endif

DROP SCHEMA IF EXISTS merge_arbitrary_schema CASCADE;
CREATE SCHEMA merge_arbitrary_schema;
SET search_path TO merge_arbitrary_schema;
SET citus.shard_count TO 4;
SET citus.next_shard_id TO 6000000;
CREATE TABLE target_cj(tid int, src text, val int);
CREATE TABLE source_cj1(sid1 int, src1 text, val1 int);
CREATE TABLE source_cj2(sid2 int, src2 text, val2 int);

SELECT create_distributed_table('target_cj', 'tid');
SELECT create_distributed_table('source_cj1', 'sid1');
SELECT create_distributed_table('source_cj2', 'sid2');

CREATE TABLE prept(t1 int, t2 int);
CREATE TABLE preps(s1 int, s2 int);

SELECT create_distributed_table('prept', 't1'), create_distributed_table('preps', 's1');

PREPARE insert(int, int, int) AS
MERGE INTO prept
USING (SELECT $2, s1, s2 FROM preps WHERE s2 > $3) as foo
ON prept.t1 = foo.s1
WHEN MATCHED THEN
        UPDATE SET t2 = t2 + $1
WHEN NOT MATCHED THEN
        INSERT VALUES(s1, s2);

PREPARE delete(int) AS
MERGE INTO prept
USING preps
ON prept.t1 = preps.s1
WHEN MATCHED AND prept.t2 = $1 THEN
        DELETE
WHEN MATCHED THEN
        UPDATE SET t2 = t2 + 1;

-- Citus local tables
CREATE TABLE t1(id int, val int);
CREATE TABLE s1(id int, val int);

SELECT citus_add_local_table_to_metadata('t1');
SELECT citus_add_local_table_to_metadata('s1');
