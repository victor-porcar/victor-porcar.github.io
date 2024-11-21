
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

