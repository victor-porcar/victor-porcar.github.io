
### Notes [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-oracle-features.md)

#### SQL ORACLE RANK AS AGGREGATE OR ANALYTIC

##### As aggregate
Look at the following table

```sql
(ID, NAME, SALARY, DEPARTAMENT)  
(1,’Bill’, 50000,’Marketing’)  
(2,’John’, 70000,’Production’)  
(3,’Steve’, 60000,’Production’)  
(4,’Paul’, 85000,’Management’)  
```
It is clear that in terms of salary, the first position (rank 1) is for Paul, the second (rank 2) for John and so on…
 
Now, a new employee (‘Larry’)  wants to join the company and his salary is determined to be 65000, what would be his rank in terms of salary? That is precisely what function RANK as aggregate determines, the answer is 3 (above Steve, below John)
 
`SELECT RANK(65000) WITHIN GROUP (ORDER BY salary) from employees; // RESULT IS 3 `

Imagine now the table EMPLOYEE as follows:
```sql
(1,’Bill’, 50000,’Marketing’)
(2,’John’, 70000,’Production’)
(3,’Steve’, 60000,’Production’)
(4,’Paul’, 85000,’Management’)
(5,’Charles’, 70000,’Assembly’)
```
In this scenario, What would the rank of Larry?  4

```sql
SELECT RANK(65000) WITHIN GROUP (ORDER BY salary) from employees; // RESULT IS 4
```

This is because if you have 2 items at rank 2, the next rank listed would be ranked 4 

DENSE_RANK allows no to skip ranks in case of having ranks with multiple items,  for example 

```sql
SELECT DENSE_RANK(65000) WITHIN GROUP (ORDER BY salary) from employees; // RESULT IS 3
```

##### As analytic

The rank is calculated respective to the other rows,  for example the following query returns the range respective to other rows having the same department (note the syntax of RANK as analytic is quite different to the one for aggregate)

```sql
SELECT NAME, SALARY, RANK() OVER (PARTITION BY DEPARTAMENT ORDER BY SALARY) FROM EMPLOYEES WHERE DEPARTMENT = 'PRODUCTION';
```

```sql
(‘Charles’, 70000, 1)
(‘Steve’,60000,2)
```
Now, imagine we need to know what is the second top salary of each department.  The following query would give us this information

```sql
SELECT * FROM (SELECT NAME, SALARY, RANK() OVER (PARTITION BY DEPARTAMENT ORDER BY SALARY) RANK FROM EMPLOYEES) 
WHERE RANK=2;
```

This example shows how useful these functions are, this query without using RANK functions would be much more difficult

DENSE_RANK as analytic works in the same manner as the aggregate version
##### FUNCTIONS FIRST, LAST
Related to RANGE, For a given range of sorted values, they return either the first value (FIRST) or the last value (LAST) of the population of rows defining e1, in the sorted order. For example:

```sql
SELECT MAX(SQ_FT) KEEP (DENSE_RANK FIRST ORDER BY GUESTS)
"Largest"
FROM SHIP_CABINS;
Largest
---
225
```

#### ORACLE SQL JOINS


Joins are characterized in many ways. One way a join is defined is in terms of whether it is an inner join or an outer join. Another issue is that of equijoins and non-equijoins. These descriptions are not mutually exclusive.

##### EQUIJOINS versus NON-EQUIJOINS: 
*   **EQUIJOIN** identifies a particular column in one table’s rows, and relates that column to another table’s rows, and looks for equal values in order to join pairs of rows together, in other words, if it uses the equal operator
```sql
SELECT e.first_name, d.department_name FROM employees e INNER JOIN departments d ON e.department_id = d.department_id
```
*   **NON-EQUIJOIN** differs from the equijoin in that it doesn’t look for exact matches but instead looks for relative matches, such as one table’s value that is between two values in the second table, in other words, it if does not use the equal operator
```sql
SELECT zip_codes.zip_code, zones.ID AS zip_zone, zones.low_zip, zones.high_zip FROM zones INNER JOIN zip_codes ON zip_codes.zip_code BETWEEN zones.low_zip AND zones.high_zip
```

##### INNER versus OUTER
*   **INNER JOIN** compares a row in one table to rows in another table and only produces output from the first row if a matching row in the second table is found
```sql
SELECT SHIP_ID, SHIP_NAME, PORT_NAME
FROM SHIPS INNER JOIN PORTS // INNER is OPTIONAL
ON HOME_PORT_ID = PORT_ID
ORDER BY SHIP_ID;
```
Before we move on to outer joins, let’s review an old variation to the syntax we just reviewed for an inner join. Here it is:
```sql
SELECT S.SHIP_ID, S.SHIP_NAME, P.PORT_NAME
FROM SHIPS S, PORTS P
WHERE S.HOME_PORT_ID = P.PORT_ID
ORDER BY S.SHIP_ID;
```

*   **OUTER JOIN** compares rows in two tables and produces output whether there is a matching row or not  

    * **LEFT OUTER JOIN**: shows all the rows in one table and only the matching rows in the second
      ```sql
      SELECT SHIP_ID, SHIP_NAME, PORT_NAME
      FROM SHIPS LEFT OUTER JOIN PORTS
      ON HOME_PORT_ID = PORT_ID
      ORDER BY SHIP_ID;
      ```
    
    * **RIGHT OUTER JOIN**: right outer join does the same thing in reverse
      ```sql
      SELECT SHIP_ID, SHIP_NAME, PORT_NAME
      FROM SHIPS RIGHT OUTER JOIN PORTS
      ON HOME_PORT_ID = PORT_ID
      ORDER BY SHIP_ID;
      ``` 
    * **FULL OUTER JOIN**: shows all rows in both tables one way or the other—either as a matched rowset or as a standalone row
      ```sql
      SELECT SHIP_ID, SHIP_NAME, PORT_NAME
      FROM SHIPS FULL OUTER JOIN PORTS
      ON HOME_PORT_ID = PORT_ID
      ORDER BY SHIP_ID;
      ```
 

**NOTE**: COMPLEX QUERIES are allowed with these kinds of joins:
```sql
SELECT p.product_name, i.item_cnt
FROM (SELECT product_id, COUNT (*) item_cnt
FROM order_items
GROUP BY product_id) i RIGHT OUTER JOIN products p ON i.product_id = p.product_id;
```

##### NATURAL JOIN

does not name the connecting column but assumes that two or more tables have columns with identical names, and that these are intended to be the connecting, or joining, columns.NOTE: a natural JOIN is a inner JOIN
```sql
SELECT EMPLOYEE_ID, LAST_NAME, STREET_ADDRESS FROM EMPLOYEES NATURAL JOIN ADDRESSES;
 ```
TYPICAL QUESTION: natural join forbids such table prefixes on join column names. Their use would result in a syntax error. However, table prefixes are allowed on other columns—but not the join columns in a natural join.

If the tables COUNTRIES and CITIES have two common columns named COUNTRY and COUNTRY_ISO_CODE, the following two SELECT statements are equivalent: 
```sql
SELECT * FROM COUNTRIES NATURAL JOIN CITIES
SELECT * FROM COUNTRIES JOIN CITIES USING (COUNTRY, COUNTRY_ISO_CODE)
```
The following example is similar to the one above, but it also preserves unmatched rows from the first (left) table: 
```sql
SELECT * FROM COUNTRIES NATURAL LEFT JOIN CITIES
```

##### CARTESIAN PRODUCT (cross join)
Cartesian Product  a.k.a CROSS-JOIN. NOTE: If any of the tables of the Cartesian product is empty (no rows), the result of the query will be EMPTY  !!!!
*   The Cartesian product is also known as a cross-join
*   The cross-join connects every row in one table with every row in the other table
*   It is created by selecting from two or more tables without a join condition of any kind
*   The Cartesian product is rarely useful
```sql
SELECT * FROM VENDORS CROSS JOIN ONLINE_SUBSCRIBERS;
```
ANOTHER WAY OF ACHIEVING THIS:
```sql
SELECT * FROM VENDORS, ONLINE_SUBSCRIBERS;
```
IMPORTANT: Please Note the following:

*   If any of the tables of the Cartesian product is empty (no rows), the result of the query will be EMPTY, in other words. If  table vendors had no row, then the previous query won’t return anything, if it is required to manage scenarios in which if one of the table is empty then result of the other table still appears, then use OUTER JOIN

*   The syntax:  
```sql
SELECT * FROM VENDORS, ONLINE_SUBSCRIBERS;
```
Is similar to the “old variation” of the inner join (see before) but without the WHERE CLAUSULE, 

-------------------------------------------

NOTES ON JOINS
•	The USING keyword can empower an inner, outer, or other join to connect based on a set of commonly named columns, in much the same fashion as a natural join. 
NOTE THAT THE USING COLUMNS CAN NOT USE PREFIX (ALIAS), JUST LIKE THE NATURAL JOIN
```sql
SELECT EMPLOYEE_ID, E.LAST_NAME, A.STREET_ADDRESS
FROM EMPLOYEES E LEFT JOIN ADDRESSES A
USING (EMPLOYEE_ID);
```
•	Joins can connect two, three, or more tables
```sql
SELECT P.PORT_NAME, S.SHIP_NAME, SC.ROOM_NUMBER
FROM PORTS P JOIN SHIPS S ON P.PORT_ID = S.HOME_PORT_ID
JOIN SHIP_CABINS SC ON S.SHIP_ID = SC.SHIP_ID;
```

•	The table alias only exists for the duration of the SQL statement in which It is declared, they are necessary to eliminate ambiguity in referring to columns of the same name in a join
```sql
SELECT EM.EMPLOYEE_ID, LAST_NAME, STREET_ADDRESS
FROM EMPLOYEES EM INNER JOIN ADDRESSES AD
ON EM.EMPLOYEE_ID = AD.EMPLOYEE_ID;
```
*   Join a Table to Itself by Using a Self-Join  (recursive joins)
•	    The self-join connects a table to itself,  typically connect a column in a table with another column in the same table
•	    Self-joins can otherwise behave as equijoins, non-equijoins, inner joins, and outer joins
```sql
SELECT A.POSITION_ID, A.POSITION, B.POSITION BOSS
FROM POSITIONS A LEFT OUTER JOIN POSITIONS B
ON A.REPORTS_TO = B.POSITION_ID
ORDER BY A.POSITION_ID;
```



### PL-SQL (Oracle)
* Create or replace a procedure

```sql 
CREATE  OR REPLACE PROCEDURE emp100
as
   CURSOR c_emp IS
      SELECT *
        FROM emp
       WHERE sal< 5000;
BEGIN
   FOR i IN c_emp
   LOOP
      dbms_output.put_line(i.sal);
insert into e1 values (i.sal);
   END LOOP;
END;
```

*Invoking a existin PROCEDURE;

??? TODO




* Simple Cursor Example (to executed as a query, directly in SQLDeveloper)

```sql
DECLARE
   CURSOR c_emp IS
      SELECT * FROM Scott.emp WHERE sal< 5000;
BEGIN
   FOR i IN c_emp
   LOOP
      dbms_output.put_line(i.sal);
       insert into e1 values (i.sal);
   END LOOP;
END;

```

* Find the greatest among three numbers

```sql
Declare
    a number;
    b number;
    c number;
Begin
    dbms_output.put_line('Enter a:');
        a:=&a;
    dbms_output.put_line('Enter b:');
        b:=&b;
    dbms_output.put_line('Enter c:');
        c:=&C;
if (a>b) and (a>c)
    then
    dbms_output.put_line('A is GREATEST'||A);
elsif (b>a) and (b>c)
    then
    dbms_output.put_line('B is GREATEST'||B);
else
    dbms_output.put_line('C is GREATEST'||C);
end if;
End;
```

* Print values  (Standard Output)

```sql
SET SERVEROUTPUT ON

-------------------

DECLARE
   lines dbms_output.chararr;
   num_lines number;
BEGIN
   -- enable the buffer with default size 20000
   dbms_output.enable;
  
   dbms_output.put_line('Hello Reader!');
   dbms_output.put_line('Hope you have enjoyed the tutorials!');
   dbms_output.put_line('Have a great time exploring pl/sql!');
 
   num_lines := 3;
 
   dbms_output.get_lines(lines, num_lines);
 
   FOR i IN 1..num_lines LOOP
      dbms_output.put_line(lines(i));
   END LOOP;
END;
/
```

#### CREATE FOREIGN KEY AND DISABLE

Broadly speaking it is good idea to create FK and disable it if necessary because the fact of having that FK provides important information to Oracle in order to optimize queries

#### UPDATE OR INSERT: UPSERT (MERGE)

https://stackoverflow.com/questions/237327/how-to-upsert-update-or-insert-into-a-table



---

### SQL Cheatsheet

Recipes that come up again and again, mostly Oracle but portable where noted.

#### Analytic functions: the pattern that replaces subqueries

```sql
SELECT plate, brand, price,
       ROW_NUMBER() OVER (PARTITION BY brand ORDER BY price DESC) AS rn,
       RANK()       OVER (PARTITION BY brand ORDER BY price DESC) AS rnk,
       DENSE_RANK() OVER (PARTITION BY brand ORDER BY price DESC) AS drnk
  FROM car;
```

The difference, with a tie for second place:

- `ROW_NUMBER` → 1, 2, 3, 4 — never repeats, arbitrary between ties
- `RANK` → 1, 2, 2, 4 — leaves a gap
- `DENSE_RANK` → 1, 2, 2, 3 — no gap

**The most valuable one in practice: the latest row per group.**

```sql
SELECT * FROM (
  SELECT c.*, ROW_NUMBER() OVER (PARTITION BY plate ORDER BY updated_at DESC) rn
    FROM car_history c)
 WHERE rn = 1;
```

That replaces the correlated subquery with `MAX(updated_at)` that everybody writes first, and it reads the table once instead of twice.

```sql
SELECT plate, price,
       LAG(price)  OVER (ORDER BY updated_at) AS previous_price,
       LEAD(price) OVER (ORDER BY updated_at) AS next_price,
       price - LAG(price) OVER (ORDER BY updated_at) AS delta
  FROM price_history;
```

```sql
-- running total, and share of the group
SELECT brand, plate, price,
       SUM(price) OVER (PARTITION BY brand ORDER BY plate) AS running_total,
       SUM(price) OVER (PARTITION BY brand)                AS brand_total,
       RATIO_TO_REPORT(price) OVER (PARTITION BY brand)    AS share
  FROM car;
```

#### Duplicates

Find them:

```sql
SELECT plate, COUNT(*)
  FROM car
 GROUP BY plate
HAVING COUNT(*) > 1;
```

Delete them keeping one, the Oracle way with `ROWID`:

```sql
DELETE FROM car
 WHERE ROWID NOT IN (SELECT MIN(ROWID) FROM car GROUP BY plate);
```

Portable version, using the analytic function above:

```sql
DELETE FROM car
 WHERE id IN (
   SELECT id FROM (
     SELECT id, ROW_NUMBER() OVER (PARTITION BY plate ORDER BY id) rn
       FROM car)
    WHERE rn > 1);
```

#### CTEs instead of nested subqueries

```sql
WITH available AS (
    SELECT * FROM car WHERE status = 'AVAILABLE'
), priced AS (
    SELECT a.*, p.daily_rate
      FROM available a
      JOIN tariff p ON p.category = a.category
)
SELECT brand, AVG(daily_rate)
  FROM priced
 GROUP BY brand;
```

Same execution, far more readable, and each step can be tested on its own by selecting from it.

#### NULL, which is where the bugs are

```sql
NULL = NULL          -- is NOT true: it is unknown
x <> 'A'             -- does NOT return rows where x IS NULL
NOT IN (1, 2, NULL)  -- returns NOTHING, ever
```

That third one is worth memorising: a single NULL inside a `NOT IN` subquery makes the whole predicate return no rows, silently. Use `NOT EXISTS` instead.

```sql
COALESCE(a, b, c)    -- first non-null  (standard)
NVL(a, b)            -- Oracle, two arguments
NVL2(a, if_not_null, if_null)
NULLIF(a, b)         -- NULL if they are equal: handy against division by zero
```

Oracle quirk worth knowing: **the empty string is NULL**. `'' IS NULL` is true, which is not the case in PostgreSQL.

#### Pagination

```sql
-- Oracle 12c and later, and standard
SELECT * FROM car ORDER BY id OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;

-- older Oracle
SELECT * FROM (SELECT c.*, ROWNUM rn FROM (SELECT * FROM car ORDER BY id) c
                WHERE ROWNUM <= 30)
 WHERE rn > 20;
```

`ORDER BY` is not optional: without it the order is undefined and page 2 may repeat rows from page 1.

And on a large table, **offset pagination degrades**: `OFFSET 100000` reads and discards 100000 rows. Keyset pagination does not:

```sql
SELECT * FROM car WHERE id > :last_seen_id ORDER BY id FETCH NEXT 10 ROWS ONLY;
```

#### Queues with SKIP LOCKED

The clean way to have several workers consuming from a table without stepping on each other:

```sql
SELECT * FROM job_queue
 WHERE status = 'PENDING'
 ORDER BY created_at
 FOR UPDATE SKIP LOCKED
 FETCH NEXT 10 ROWS ONLY;
```

`FOR UPDATE` locks the rows; `SKIP LOCKED` makes other sessions ignore the ones already taken instead of queueing behind them. Available in Oracle and PostgreSQL, and it removes the need for a message broker in a lot of simple cases.

#### Reading a plan

```sql
EXPLAIN PLAN FOR SELECT ...;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

The real one, with actual rows rather than estimates:

```sql
SELECT /*+ GATHER_PLAN_STATISTICS */ ... ;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
```

What to look for, in order:

- **`TABLE ACCESS FULL`** on a large table inside a loop — the usual culprit
- a large gap between **E-Rows and A-Rows** (estimated vs actual) — the statistics are lying, and every decision after that is wrong
- **`NESTED LOOPS`** over many rows where a `HASH JOIN` belongs

#### Why an index is not being used

Almost always one of these three:

```sql
-- 1. a function on the column kills the index
WHERE UPPER(plate) = 'ABC'          -- needs a function-based index
CREATE INDEX idx_car_plate_upper ON car (UPPER(plate));

-- 2. implicit type conversion
WHERE plate = 123                   -- plate is VARCHAR2: converts the COLUMN, not the literal

-- 3. leading wildcard
WHERE plate LIKE '%123'             -- cannot use a b-tree index
```

And statistics:

```sql
EXEC DBMS_STATS.GATHER_TABLE_STATS('SCHEMA', 'CAR');
SELECT table_name, num_rows, last_analyzed FROM user_tables WHERE table_name = 'CAR';
```

A table loaded last night and never analysed has the optimizer planning for the volume it had yesterday.

#### Bind variables

```sql
-- hard parse on every execution, floods the shared pool
SELECT * FROM car WHERE plate = 'ABC123';

-- one parse, reused
SELECT * FROM car WHERE plate = :plate;
```

In Java this is the difference between a `Statement` with concatenation and a `PreparedStatement`, and it is also the difference between being vulnerable to SQL injection and not being vulnerable.

#### Who is blocking whom

```sql
-- sessions and what they are running
SELECT s.sid, s.serial#, s.username, s.status, s.machine, q.sql_text
  FROM v$session s LEFT JOIN v$sql q ON q.sql_id = s.sql_id
 WHERE s.type = 'USER';

-- blocked and blocker
SELECT s.sid, s.blocking_session, s.event, s.seconds_in_wait
  FROM v$session s
 WHERE s.blocking_session IS NOT NULL;

-- the heaviest statements
SELECT sql_id, executions, elapsed_time/1e6 secs,
       elapsed_time/NULLIF(executions,0)/1e3 ms_per_exec, sql_text
  FROM v$sql
 ORDER BY elapsed_time DESC FETCH FIRST 20 ROWS ONLY;
```

```sql
ALTER SYSTEM KILL SESSION '<sid>,<serial#>' IMMEDIATE;
```

#### Dates

```sql
TRUNC(SYSDATE)                      -- today at 00:00
TRUNC(created_at) = TRUNC(SYSDATE)  -- careful: this kills the index on created_at
```

```sql
-- range instead, so the index is used
WHERE created_at >= TRUNC(SYSDATE) AND created_at < TRUNC(SYSDATE) + 1
```

```sql
ADD_MONTHS(SYSDATE, -1)
MONTHS_BETWEEN(a, b)
LAST_DAY(SYSDATE)
TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
TO_DATE('2026-09-17', 'YYYY-MM-DD')
```

#### Data dictionary

```sql
SELECT * FROM user_tables;
SELECT * FROM user_tab_columns WHERE table_name = 'CAR';
SELECT * FROM user_indexes WHERE table_name = 'CAR';
SELECT * FROM user_constraints WHERE table_name = 'CAR';

-- who points at me
SELECT c.table_name, c.constraint_name
  FROM user_constraints c
  JOIN user_constraints p ON p.constraint_name = c.r_constraint_name
 WHERE p.table_name = 'CAR';

-- find a column anywhere
SELECT table_name, column_name FROM user_tab_columns WHERE column_name LIKE '%PLATE%';
```

`ALL_` instead of `USER_` for everything visible to you, `DBA_` for the whole instance if you have the privilege.

#### Space and schema inventory

```sql
-- size of each table, in MB (without indexes or LOBs)
SELECT segment_name, SUM(bytes)/1024/1024 mb
  FROM user_segments WHERE segment_type = 'TABLE'
 GROUP BY segment_name ORDER BY mb DESC;

-- total size of a schema, in GB
SELECT SUM(bytes)/1024/1024/1024 gb FROM dba_segments WHERE owner = 'MY_SCHEMA';

-- rows per table (from statistics: as fresh as the last gather)
SELECT table_name, num_rows FROM dba_tables WHERE owner = 'MY_SCHEMA' ORDER BY num_rows DESC;

-- tables per schema
SELECT owner, COUNT(*) FROM dba_tables GROUP BY owner;

-- tables with LOB columns
SELECT DISTINCT table_name FROM user_tab_cols WHERE data_type IN ('CLOB', 'BLOB', 'NCLOB');

-- free space per tablespace
SELECT tablespace_name, ROUND(SUM(bytes)/1024/1024) free_mb
  FROM dba_free_space GROUP BY tablespace_name ORDER BY free_mb;
```

```sql
-- every FK of a schema and the column it points to
SELECT a.table_name || '.' || a.column_name || ' --> ' || p.table_name || '.' || p.column_name
  FROM all_cons_columns a
  JOIN all_constraints c ON c.owner = a.owner AND c.constraint_name = a.constraint_name
  JOIN all_cons_columns p ON p.owner = c.r_owner AND p.constraint_name = c.r_constraint_name
                         AND p.position = a.position
 WHERE c.constraint_type = 'R' AND c.owner = 'MY_SCHEMA';

-- search a text in all the PL/SQL of the schema
SELECT name, type, line, text FROM all_source
 WHERE UPPER(text) LIKE UPPER('%orders%') ORDER BY type, name, line;

-- synonyms
SELECT synonym_name, table_owner, table_name FROM all_synonyms WHERE owner IN ('PUBLIC', USER);
```

A `UNIQUE` index behaves like a primary key as far as duplicates are concerned: it rejects them. And creating a `PRIMARY KEY` or `UNIQUE` constraint creates its index implicitly, if none exists.

#### Locks with their mode

The blocking query above says who waits for whom. This one shows every object currently locked and how:

```sql
SELECT s.sid, s.username, s.machine, o.object_name, o.object_type,
       DECODE(l.locked_mode, 1, 'no lock', 2, 'row share (SS)', 3, 'row exclusive (SX)',
                             4, 'shared table (S)', 5, 'shared row exclusive (SSX)', 6, 'exclusive (X)') lock_mode
  FROM v$locked_object l
  JOIN dba_objects o ON o.object_id = l.object_id
  JOIN v$session   s ON s.sid = l.session_id;
```

A lock is not a block: there is only a wait when two sessions want the same rows. An `UPDATE` left uncommitted in SQL Developer keeps its rows locked, and any batch process touching them waits until that commit.

#### Statistics and materialized views

```sql
-- refresh the optimizer statistics of a table after a big load
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => 'MY_SCHEMA', tabname => 'ORDERS', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE);

-- when were the materialized views refreshed, and are they stale?
SELECT mview_name, refresh_method, refresh_mode, staleness, last_refresh_type,
       TO_CHAR(last_refresh_date, 'DD/MM/YYYY HH24:MI:SS') last_refresh
  FROM user_mviews ORDER BY last_refresh_date DESC;
```

Without fresh statistics the optimizer plans for the table as it was: a table loaded from empty to millions of rows keeps being treated as empty.

#### Recovering deleted data: flashback

| Feature | Recovers | Uses |
|---|---|---|
| Flashback query | rows as they were at a point in time | undo |
| Flashback table | a whole table back to a point in time | undo |
| Flashback drop | a dropped table and its indexes | recycle bin |
| Flashback database | the whole database to a point in time | flashback logs |

```sql
SELECT * FROM orders AS OF TIMESTAMP SYSTIMESTAMP - INTERVAL '15' MINUTE WHERE id = 42;
FLASHBACK TABLE orders TO TIMESTAMP SYSTIMESTAMP - INTERVAL '15' MINUTE;   -- needs ROW MOVEMENT enabled
FLASHBACK TABLE orders TO BEFORE DROP;
```

#### Rows to a list and back

```sql
-- many rows to one delimited value
SELECT dept_id, LISTAGG(name, ',') WITHIN GROUP (ORDER BY name) names
  FROM employees GROUP BY dept_id;

-- one delimited value to many rows
SELECT REGEXP_SUBSTR('a;b;c', '[^;]+', 1, LEVEL) item
  FROM dual CONNECT BY LEVEL <= REGEXP_COUNT('a;b;c', ';') + 1;
```

#### Export and import

The old `exp` / `imp` are deprecated: Data Pump replaces them, runs on the server and is much faster.

```shell
expdp <user>@<db> tables=ORDERS directory=DATA_PUMP_DIR dumpfile=orders.dmp logfile=orders.log
expdp <user>@<db> tables=ORDERS query='ORDERS:"WHERE ROWNUM < 1000"' directory=DATA_PUMP_DIR dumpfile=sample.dmp
expdp <user>@<db> schemas=MY_SCHEMA exclude=INDEX directory=DATA_PUMP_DIR dumpfile=schema.dmp
impdp <user>@<db> tables=ORDERS directory=DATA_PUMP_DIR dumpfile=orders.dmp table_exists_action=replace
```

#### SQL Developer: an FK References tab

Save this as `fk_ref.xml`, then Tools > Preferences > Database > User Defined Extensions > Add Row, type `EDITOR`, location the file, and restart. Every table then shows which foreign keys point at it.

```xml
<items>
  <item type="editor" node="TableNode" vertical="true">
    <title><![CDATA[FK References]]></title>
    <query>
      <sql><![CDATA[select a.owner, a.table_name, a.constraint_name, a.status
                      from all_constraints a
                     where a.constraint_type = 'R'
                       and exists (select 1 from all_constraints
                                    where constraint_name = a.r_constraint_name
                                      and constraint_type in ('P', 'U')
                                      and table_name = :OBJECT_NAME
                                      and owner = :OBJECT_OWNER)
                     order by table_name, constraint_name]]></sql>
    </query>
  </item>
</items>
```

#### Habits worth keeping

- `ORDER BY` whenever the order matters: without it SQL guarantees no order at all, even if it looks stable today.
- Test queries and processes against **empty tables** too: aggregates return NULL, `MAX` of nothing is not zero.
- In a batch, **one commit at the end** (or per controlled chunk), not one per row: faster and restartable.
- Careful with dates: decide whether "now" comes from the application or from `SYSDATE`, and do not mix both in the same flow.
- After a big load, gather statistics before trusting any plan.
