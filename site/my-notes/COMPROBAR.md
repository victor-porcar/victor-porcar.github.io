### CONCEPTS
* [Open Data](https://en.wikipedia.org/wiki/Open_data): data should be freely available to everyone to use and republish as they wish, without restrictions from copyright, patents or other mechanisms of control  

* [Sharding vs Partioning](https://stackoverflow.com/questions/20771435/database-sharding-vs-partitioning)

* [B-Tree]

* *Isolation levels* and Anomalies

|Isolation_level\Anomaly|Lost_update (because of rollback)|Dirty_read|Non_repeatable_reads second_lost_update|Phantoms|Write_skew|
|:---------------|:-------:|:-------:|:-------:|:-------:|:-------:|
|Read Uncommitted|-        |may occur|may occur|may occur|may occur|
|Read Committed  |-        |-        |may occur|may occur|may occur|
|Repeatable Read |-        |-        |-        |may occur|may occur|
|Snapshot        |-        |-        |-        |-        |may occur|
|Serializable    |-        |-        |-        |-        |-        |

* [ACID](https://en.wikipedia.org/wiki/ACID)  

* [2-phase commit protocol](https://en.wikipedia.org/wiki/Two-phase_commit_protocol)  

* [3-phase commit protocol](https://en.wikipedia.org/wiki/Three-phase_commit_protocol)  

* What is [pessimistic](https://www.baeldung.com/jpa-pessimistic-locking) / [optimistic](https://en.wikipedia.org/wiki/Optimistic_concurrency_control) locking?

### SQL
* [Correlated subquery](https://en.wikipedia.org/wiki/Correlated_subquery):  it is a subquery (a query nested inside another query) that uses values from the outer query. `select id from table t where id in (Select id2 from table2 where id=t.id)`The correlated subquery is evaluated once for each row of the outer query.

* [IN = EXISTS, but beware: NOT IN is not the same as NOT EXISTS!](https://www.oratable.com/not-in-vs-not-exists/): if there is a NULL in the NOT IN list, then it will be always false `select* from test_a where col1 not in (select col1 from test_b);` if query won't return any row if test_b has nulls

* [Lookups Table](https://www.red-gate.com/simple-talk/sql/oracle/10-best-practices-for-writing-oracle-sql/): Lookup tables are useful to keep "drop downs values", basic structure COUNTRY(id, name). Watch out with not HAVING one big lookup , BEWARE in your system not HAVING one big lookup [(this is called  OTLT =One True Lookup Table, which is an antipattern](https://oracle-base.com/articles/misc/one-true-lookup-tables-otlt)

* [Master table vs Transaction table](https://stackoverflow.com/questions/35675890/difference-between-master-and-transaction-table): In a sales app, there would be  Masters tables such as CUSTOMER (id, name, ...),  PRODUCT(id,productId, name,...) which rarely changes, and the SALE (idCustomer, idProduct,...) would be transactional

* [Avoid functions in WHERE](https://www.red-gate.com/simple-talk/sql/oracle/10-best-practices-for-writing-oracle-sql/): because indexes can not be used -> perhaps refactoring the query, or using [FUNCTION BASED INDEXES in Oracle](https://medium.com/@complete_it_pro/what-is-a-function-based-index-in-oracle-and-why-should-i-create-one-6e19e6912a55)

* [Use CASE Instead of Multiple Unions](https://www.red-gate.com/simple-talk/sql/oracle/10-best-practices-for-writing-oracle-sql/):each query of the UNION is evaluated and this could be very expensive

* [UNION ALL is cheaper than UNION](https://www.red-gate.com/simple-talk/sql/oracle/10-best-practices-for-writing-oracle-sql/): UNION internally executes a DISTINCT, which is expensive.

* [Minimise the Use of DISTINCT](https://www.red-gate.com/simple-talk/sql/oracle/10-best-practices-for-writing-oracle-sql/): DISTINCT is an expensive operation to be performed. Sometimes the query can be refactored to avoid it.

* [Why doesn't Oracle RDBMS have a boolean datatype?](https://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:6263249199595#876972400346931526): Since flag `char(1) check (flag in ( 'Y', 'N' ))` serves the same purpose, requires the same amount of space and does the same thing 

* [COMMIT, ROLLBACK, SAVEPOINT](https://www.oracle-dba-online.com/sql/commit_rollback_savepoint.htm): An implicit commit occurs after DDL (CREATE, ALTER, DROP...).

* [Pseudocolumn ROWNUM and ORDER BY](https://docs.oracle.com/cd/E11882_01/server.112/e41084/pseudocolumns009.htm#SQLRF00255): ROWNUM is assigned before the ORDER BY clause is processed, WRONG: `  SELECT ... FROM ... WHERE ... ORDER BY .... WHERE ROWNUM < 1000;` RIGHT: `SELECT ... FROM ( SELECT ... FROM ... WHERE ... ORDER BY .... )  WHERE ROWNUM < 1000;`

* [DISTINCT(column) will include nulls while COUNT(column) will not]

* [The concept of NULL](https://docs.oracle.com/database/121/SQLRF/sql_elements005.htm#SQLRF30037): The definition of NULL is the “absence of information”. Sometimes it’s mischaracterized as “zero” or “blank”, but that is incorrect—a “zero”, after all, is a known quantity `select 300*NULL from dual // this is NULL because “unknown”*300 = unknown`

* [Multiple-column subquery](http://www.dba-oracle.com/t_multi_column_subquery.htm):  They exist and can be used!:  `SELECT EMPLOYEE_ID FROM EMPLOYEES WHERE (FIRST_NAME, LAST_NAME) IN (SELECT FIRST_NAME, LAST_NAME FROM CRUISE_CUSTOMERS) AND SHIP_ID = 1;`  IN operator can be replaced for = ...

* [Scalar subquery](http://sql.standout-dev.com/2015/10/subqueries-oracle-sql/#Scalar_Subqueries_Single_Row_Single_Column): they always return one value, represented in one column of one row, every time

* [Inline view](http://sql.standout-dev.com/2015/10/subqueries-oracle-sql/#Scalar_Subqueries_Single_Row_Single_Column): they are simply a subquery that appears in the FROM clause of a SELECT statement. They can be used in other parts of the main query as you would with a table or view (reference its columns, join it to other data sources, etc) . Inline views are always non-correlated subqueries.

* [Subquery Factoring (The WITH Clause)](http://sql.standout-dev.com/2015/10/subqueries-oracle-sql/#Scalar_Subqueries_Single_Row_Single_Column)

* [IMPLICIT INDEX in ORACLE (indexes created automatically)]: If you create a constraint on a table that is of type PRIMARY KEY or UNIQUE, then as part of the creation of the constraint, SQL will automatically create an index to support that constraint on the column or columns, if such an index does not already exist.

* [Difference between DELETE and TRUNCATE](https://www.geeksforgeeks.org/difference-between-delete-and-truncate/?ref=leftbar-rightbar): TRUNCATE is DDL command (Can't be rolledback) and it is much faster

* [Enhanced Aggregation, Cube, Grouping and Rollup](http://www.orafaq.com/node/56)

* [Hierarchical Queries](https://docs.oracle.com/cd/B19306_01/server.102/b14200/queries003.htm): using `START WITH`, `CONNECT BY` and `PRIOR`. Example: `SELECT LEVEL, EMPLOYEE_ID, TITLE FROM EMPLOYEE_CHART START WITH EMPLOYEE_ID = 1 CONNECT BY REPORTS_TO = PRIOR EMPLOYEE_ID;`

* [Regular Expressions ORACLE](https://www.red-gate.com/simple-talk/sql/oracle/introduction-to-regular-expressions-in-oracle/): REGEXP_LIKE , REGEXP_INSTR, REGEXP_SUBSTR, REGEXP_REPLACE and REGEXP_COUNT

* [select count(*) = select count(1) in terms of performance](https://pretius.com/oracle-count-or-count1-that-is-the-question/): It is exactly the same. Oracle internally rewrite COUNT(1)  to COUNT(*)

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


###[NORMALIZATION](https://en.wikipedia.org/wiki/Database_normalization)

* [article *A SlMPLE GUIDE TO FIVE NORMAL FORMS IN RELATIONAL DATABASE THEORY* of William Kent](http://www.roma1.infn.it/people/barone/metinf/database-normalization.pdf)

* [How far to normalize a database?](https://stackoverflow.com/questions/47711/how-do-you-determine-how-far-to-normalize-a-database): *A wise man once told me: Normalize till it hurts, Denormalize till it works* 

* Horizontal and vertical scaling.

* How to scale database? (Data partitioning, sharding(vertical/horizontal), replication(master-slave, master-master)).

* What is *synchronous multimaster replication*? (Each server can accept write requests, and modified data is transmitted from the original server to every other server before each transaction commits)

* What is *asynchronous multimaster replication*? (Each server works independently, and periodically communicates with the other servers to identify conflicting transactions. The conflicts can be resolved by users or conflict resolution rules)

* When to use messaging queue?

* MongoDB, Redis.

* Hadoop basics.

* sticky/non-sticky sessions

* *Sticky sessions* vs storing sessions in Redis.

### SOLR

* [Solr query syntax](http://www.solrtutorial.com/solr-query-syntax.html)


### ELASTIC


### RabbitMQ

### REDIS


### BASH SHELL SCRIPT


* register java versions
```shell script
#register all versions 
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/java-8-openjdk-amd64/bin/javaws" 1 
... 
sudo update-alternatives --config java 
```


### DOCKER

* What is *Blue-green Deployment*, *Canary release*, *A/B testing*? [link](https://www.javacodegeeks.com/2016/02/blue-green-deployment.html)
* What is *Docker*?

#### Docker Compose


### KUBERNETES

#### Minikube


#### Helm

### UBUNTU

* [Useful shortcuts](https://itsfoss.com/ubuntu-shortcuts/):
    * Super key: Opens Activities search. ...
    * Ctrl+Alt+T: Ubuntu terminal shortcut. ...
    * Super+L or Ctrl+Alt+L: Locks the screen. ...
    * Super+D or Ctrl+Alt+D: Show desktop. ...
    * Super+A: Shows the application menu. ...
    * Super+Tab or Alt+Tab: Switch between running applications. ...
    * Super+Arrow keys: Snap windows.

* Create a icon on desktop: create empty file with extension .desktop in Desktop with the following content (set values properly)

```shell script
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/lib/jvm/jdk1.8.0_221/bin/jvisualvm
Name=VisualVM
Comment=VisualVM
Icon=/usr/lib/jvm/jdk1.8.0_221/bin/jvisualvm.jpeg
```




### GIT
-[TODO]
-[GIT Merging vs Rebasing ](https://dzone.com/articles/merging-vs-rebasing)
 
 
-[clone all GITLAB projects](https://gist.github.com/JonasGroeger/1b5155e461036b557d0fb4b3307e1e75)

* *Git* workflow? (Master: production-ready state; Develop: latest delivered development changes for the next release; Feature Branches; Release Branches; Hotfixes) ![Git workflow](http://nvie.com/img/git-model@2x.png "Git workflow") http://nvie.com/posts/a-successful-git-branching-model/

 
### Mercurial
--[TODO]



### POWER SHELL
-[TODO]



### Virtual Box
-[Shrink a Virtualbox VM in Windows 10](https://www.maketecheasier.com/shrink-your-virtualbox-vm/)


### Publish Maven Central Repository


Basicamente hay que seguir 

https://dzone.com/articles/publish-your-artifacts-to-maven-central

Resumen de los pasos en este pdf


Lo que hago es:

1) DONE

2) crear en github una cuenta y en ella un repository y que este todo en master (paso 3)

4) no hace falta

5) hacer push a master de github

basicamente pasos 6-10 hacer lo que dice

en PUBLISHING STEPS coger como modelo el https://github.com/victormpcmun/delayed-batch-executor/blob/master/pom.xml

este fichero esta adjunto


NOTA: se adjunta la cadena de correos con el JIRA de sonatype para crear el repositorio.



=======================================================================
COMO SE PUBLICA UNA RELEASE:

STEP 8: Do the release! => sacaremos release en github

- tener en master version SNAPSHOT
- asegurarse que el setting.xml de MAVEN tiene el user / passwor de sonatype (ver abajo)

lo siguiente nos sacara la release final, y nos pondra en master la siguiente como SNAPSHOT

mvn clean
mvn release:prepare
mvn release:perform



STEP 9 : Push the tag and code to your remote repo => subiremos el artifact a un servidor "staging" de sonatype

git push–tags
git push origin master

Para: comprobar que se ha subido

https://oss.sonatype.org/#stagingRepositories

logarse con las credenciales de sonatype (Ver abajo) -> verificar que en "Staging Repositories" aparece el artifact subido

luego en https://central.sonatype.org/pages/releasing-the-deployment.html se explica como proceder, pero basicamente hay que hacer:

- pulsar "Close" -> esto dispara una serie de validaciones, si todo esta OK aparecera el boton "Relase", pulsandolo se publicara en maven central repository a los pocos minutos

https://search.maven.org/search?q=g:com.github.victormpcmun

y ya esta.

`
=======================================================================================


SI HACE FALTA INSTALAR EL PGP hacer lo siguiente: 

- Instalacion de PGP de cero con mi clave:
  1) isntalarlo el isntalable (usar el que esta aqui)
  2) copiar el directorio de aqui \gnupg en la ruta => C:\Users\<USUARIO>\AppData\Roaming\gnupg   
  asi de esta forma PGPG tendra toda la configuracion de mi clave.
  se puede probar con el siguiente comando:
  
  gpg --list-keys => tiene que salir una de victormpcmun@gmail.com
  




  ### JVM

* [The JVM Architecture Explained ](https://dzone.com/articles/jvm-architecture-explained)

* [Introduction to JVM bytecode](https://www.beyondjava.net/blog/java-programmers-guide-java-byte-code)

* [Introduction to Javassist](https://www.baeldung.com/javassist)

* [A Quick Guide to Writing Bytecode With ASM](https://www.beyondjava.net/blog/quick-guide-writing-byte-code-asm)

* [Java Bytecode Manipulation with ASM](https://www.baeldung.com/java-asm)

* [JVM arguments:7 JVM Arguments of Highly Effective Applications](https://dzone.com/articles/7-jvm-arguments-of-highly-effective-applications-1?edition=590292&utm_source=Weekly%20Digest&utm_medium=email&utm_campaign=Weekly%20Digest%202020-04-01#)

* [-XX:-OmitStackTraceInFastThrow](https://stackoverflow.com/questions/2411487/nullpointerexception-in-java-with-no-stacktrace): when a exception occurs often enough, the stack trace is not printed anymore (default behaviour).

* [JNI](https://www.baeldung.com/jni)

* [JVM inlining](https://www.baeldung.com/jvm-method-inlining): JVM inline by JIT XX:FreqInlineSize flag => small methods and not public if it is possible to allow maximum inlining

* [Optimizing memory access with CPU cache](https://dzone.com/articles/optimizing-memory-access-with-cpu-cache)

* [Volatile vs Transient](https://stackoverflow.com/questions/3544919/what-are-transient-and-volatile-modifiers)

* [Java Memory Model (Stack and Heap)](https://www.baeldung.com/java-stack-heap)

* [Java Memory Leaks](https://www.baeldung.com/java-memory-leaks)

* [Garbage collection](https://www.baeldung.com/jvm-garbage-collectors): 
    * Serial Garbage Collector: freezes all application threads when it runs. Hence, it is not a good idea to use it in multi-threaded applications like server environments.
    * Parallel Garbage Collector: the default one. It uses multiple threads for managing heap space. But it also freezes other application threads while performing GC.
    * CMS Garbage Collector:applications using this type of GC respond slower on average but do not stop responding to perform garbage collection.
    * G1 Garbage Collector:G1 collector will replace the CMS collector since it's more performance efficient.   


### LANGUAGE

* [Waste space in Java Collections](https://dzone.com/articles/preventing-your-java-collections-from-wasting-memo): empty ArrayList() wastes 36 or 72 bytes. Use lazy creations

* [Covariance, Contravariance](https://www.logicbig.com/tutorials/core-java-tutorial/java-language/java-subtyping-rules.html)  -  [Covariance, Contravariance](https://dzone.com/articles/covariance-and-contravariance): 
    * Covariant (? extends MyClass  => A feature which allows to substitute a subtype with supertype): Java Arrays are Covariant, Java Generics with wildcard '? extends' are Covariant (suitable for reading) 
    * Contravariant (? super MyClass => A feature which allows to substitute a supertype with subtype): Java Generics with wildcard '? super' are Contravariant (suitable for writing)  
    * NOTE: a mnemonic word [PECS (Producer Extends Consumer Super)](https://stackoverflow.com/questions/2723397/what-is-pecs-producer-extends-consumer-super)

* [Type Erasure](https://www.baeldung.com/java-type-erasure)

* [Project Lombok](https://www.baeldung.com/intro-to-project-lombok)

* [Fail-Fast and Fail-Safe iterators](https://www.baeldung.com/java-fail-safe-vs-fail-fast-iterator)

* [Overriding vs Overloading](https://www.journaldev.com/32182/overriding-vs-overloading-in-java)
    * Overloading: same method name but different parameters in the same class
    * Overriding: same method signature in both superclass and child class

* [Checked vs Unchecked exceptions](https://www.baeldung.com/java-checked-unchecked-exceptions)
 
* [Difference between NoClassDefFoundError and ClassNotFoundException](https://dzone.com/articles/java-classnotfoundexception-vs-noclassdeffounderro)
  
* [How does ConcurrentHashMap work in Java?,  is ConcurrentHashMap is thread-safe?, ](https://javarevisited.blogspot.com/2011/04/difference-between-concurrenthashmap.html)

* [What is the difference between CountDownLatch and CyclicBarrier in Java?](https://javarevisited.blogspot.com/2012/07/cyclicbarrier-example-java-5-concurrency-tutorial.html)

* [Java @SafeVarargs and @SupressWarnings Annotation](https://www.baeldung.com/java-safevarargs)

* [sun.misc.Unsafe](https://www.baeldung.com/java-unsafe)
 
* [@Nullable, @NonNull, @NonNullApi](https://www.baeldung.com/spring-null-safety-annotations) 

* [Spring AOP](https://www.codejava.net/frameworks/spring/understanding-spring-aop)

* [Java versions and Features](https://dzone.com/articles/a-guide-to-java-versions-and-features)

* [Java Future](https://www.baeldung.com/java-future)

* [Thread Pools](https://www.baeldung.com/thread-pool-java-and-guava)

* [Class Loaders](https://www.baeldung.com/java-classloaders)

* [Flattening Nested Collections](https://www.baeldung.com/java-classloaders)

* [Atomic Variables](https://www.geeksforgeeks.org/atomic-variables-in-java-with-examples/?ref=leftbar-rightbar)

* [MUST READ:10 Things You Didn’t Know About Java: There is no such thing as a checked exception, You can have method overloads differing only in return types, GOTO, type aliases,Type intersections,...](https://blog.jooq.org/2014/11/03/10-things-you-didnt-know-about-java/)

* [JPA Inheritance strategies](https://www.baeldung.com/hibernate-inheritance):
    * MappedSuperclass
    * Single Table
    * Joined Table
    * Table-Per-Class

* [Memoization in Java 8](https://dzone.com/articles/java-8-automatic-memoization)

* [Java Closures](https://dzone.com/articles/java-8-lambas-limitations-closures)

* [Weak, Soft, and Phantom References](https://dzone.com/articles/weak-soft-and-phantom-references-in-java-and-why-they-matter)

* [Serializable / Externalizable](https://stackoverflow.com/questions/817853/what-is-the-difference-between-serializable-and-externalizable-in-java)
 
* [Difference between <?>, \<Object\>, <? extends Object> and no generic type?](http://stackoverflow.com/questions/8055389/whats-the-difference-between-and-extends-object-in-java-generics)

* [Syncronized](https://www.baeldung.com/java-synchronized)

### JEE

PUT ALL THE CERTIFICATION

### SPRING / SPRING BOOT

* [Spring Boot Actuator](https://www.baeldung.com/spring-boot-actuators)

#### REACTOR

* [Introduction](https://www.baeldung.com/reactor-core)

* [Concurrency in Project Reactor with Scheduler](https://huongdanjava.com/concurrency-in-project-reactor-with-scheduler.html)

* [Spring Webflux: EventLoop vs Thread Per Request Model](https://dzone.com/articles/spring-webflux-eventloop-vs-thread-per-request-mod)

* [Reactor map vs flatmap](reactor map vs flatmap)

* [Reactive extensions](http://reactivex.io)

* [What is *asynchronous* and *non-blocking*?](https://www.linkedin.com/pulse/java-servlets-asynchronous-non-blocking-aliaksandr-liakh)

* [Backpressure in WebFlux](https://stackoverflow.com/questions/52244808/backpressure-mechanism-in-spring-web-flux)

### Concurrency

* [Deadlock](https://en.wikipedia.org/wiki/Deadlock), [Livelock](https://en.wikipedia.org/wiki/Deadlock#Livelock):Deadlock is a situation in which two or more competing actions are each waiting for the other to finish, and thus neither ever does. A livelock is similar to a deadlock, except that the states of the processes involved in the livelock constantly change with regard to one another, none progressing.

* [Deadlock avoidance](https://www.geeksforgeeks.org/deadlock-prevention). (prevention, detection, avoidance (Mutex hierarchy), and recovery)

* [starvation](https://en.wikipedia.org/wiki/Starvation_(computer_science))? (a problem encountered in concurrent computing where a process is perpetually denied necessary resources to process its work)

* [race condition](https://en.wikipedia.org/wiki/Race_condition)? (Behavior of software system where the output is dependent on the sequence or timing of other uncontrollable events)

* [happens-before](https://en.wikipedia.org/wiki/Happened-before) relation?

* [thread contention](https://stackoverflow.com/questions/1970345/what-is-thread-contention)? (Contention is simply when two threads try to access either the same resource or related resources in such a way that at least one of the contending threads runs more slowly than it would if the other thread(s) were not running). Contention occurs when multiple threads try to acquire a lock at the same time

* [thread-safe](https://en.wikipedia.org/wiki/Thread_safety) function? (Can be safely invoked by multiple threads at the same time)

* [Publish/Subscribe](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) pattern

* [2-phase locking](https://en.wikipedia.org/wiki/Two-phase_locking)? (Growing phase, shrinking phase. Guarantees serializablity for transactions, doesn't prevent deadlock).

* [What is the difference between *thread* and *process*?]: Threads (of the same process) run in a shared memory space, while processes run in separate memory spaces)

* [false sharing](https://en.wikipedia.org/wiki/False_sharing), [cache pollution](https://en.wikipedia.org/wiki/Cache_pollution), *cache miss*, [thread affinity](https://en.wikipedia.org/wiki/Processor_affinity), [ABA-problem](https://en.wikipedia.org/wiki/ABA_problem), [speculative execution](https://en.wikipedia.org/wiki/Speculative_execution)?

* [obstruction-free algorithm](https://en.wikipedia.org/wiki/Non-blocking_algorithm#Obstruction-freedom): if all other threads are paused, then any given thread will complete its operation in a bounded number of steps

* [lock-free algorithm](https://en.wikipedia.org/wiki/Non-blocking_algorithm#Lock-freedom): if multiple threads are operating on a data structure, then after a bounded number of steps one of them will complete its operation

* [wait-free algorithm](https://en.wikipedia.org/wiki/Non-blocking_algorithm#Wait-freedom): every thread operating on a data structure will complete its operation in a bounded number of steps, even if other threads are also operating on the data structure

* [sequential consistency](https://en.wikipedia.org/wiki/Sequential_consistency): the result of any execution is the same as if the operations of all the processors were executed in some sequential order, and the operations of each individual processor appear in this sequence in the order specified by its program).

* [memory barrier](https://en.wikipedia.org/wiki/Memory_barrier): a memory barrier, also known as a membar, memory fence or fence instruction, is a type of barrier instruction that causes a CPU or compiler to enforce an ordering constraint on memory operations issued before and after the barrier instruction)

* Synchonization aids in Java
  * CountDownLatch
  * CyclicBarrier
  * Phaser
  * ReentrantLock
  * Exchanger
  * Semaphore
  * LinkedTransferQueue

* What is *data race*? (When a program contains two conflicting accesses that are not ordered by a [happens-before](https://docs.oracle.com/javase/specs/jls/se12/html/jls-17.html#jls-17.4.5) relationship, it is said to contain a data race. Two accesses to (reads of or writes to) the same variable are said to be conflicting if at least one of the accesses is a write. But see [this](https://stackoverflow.com/questions/16615140/is-volatile-read-happens-before-volatile-write/16615355#16615355))

* Java [memory model](https://docs.oracle.com/javase/specs/jls/se12/html/jls-17.html#jls-17.4)
  * A program is correctly synchronized if and only if all sequentially consistent executions are free of data races
  * Correctly synchronized programs have sequentially consistent semantics. If a program is correctly synchronized, then all executions of the program will appear to be sequentially consistent
  * Causality requirement for incorrectly synchronized programs: [link](https://pdfs.semanticscholar.org/c132/11697f5c803221533a07bd6db839fa60b7b8.pdf)

* What is *monitor* in Java? (Each object in Java is associated with a monitor, which a thread can lock or unlock)

* What is *safe publication*?

* What is *wait*/*notify*?

* [Amdahl's law](https://en.wikipedia.org/wiki/Amdahl%27s_law)? (Speedup = 1 / (1 - p + p / n))

* [Dining philosophers problem](https://en.wikipedia.org/wiki/Dining_philosophers_problem) (Resource hierarchy (first take lower-indexed fork), arbitrator, communication (dirty/clean forks)).

* [Produces/consumer](https://en.wikipedia.org/wiki/Producer%E2%80%93consumer_problem) problem.

* [Readers/writers](https://en.wikipedia.org/wiki/Readers%E2%80%93writers_problem) problem.

* [Transactional memory](https://en.wikipedia.org/wiki/Software_transactional_memory)

* [Coroutine](https://en.wikipedia.org/wiki/Coroutine)


### MAVEN

### GRADLE



### LIBRARIES

* [LMAX Disruptor](https://www.baeldung.com/lmax-disruptor-concurrency)

* [Netflix Hystrix](https://www.baeldung.com/introduction-to-hystrix)

* [Netflix Archaius](https://www.baeldung.com/netflix-archaius-database-configurations)

* [Netflix Hollow](https://hollow.how/)

* [Prometheus and Grafana for metrics monitoring](https://www.callicoder.com/spring-boot-actuator-metrics-monitoring-dashboard-prometheus-grafana/)


### [BOOK: Effective JAVA (Block), third Edition](https://dzone.com/articles/jvm-architecture-explained)

NOTE: this is copied directly from [here](https://github.com/david-sauvage/effective-java-summary/blob/master/README.md)


#### Creating and destroying objects

__Item 1 : Static factory methods__

Pros
 - They have a name
 - You can use them to control the number of instance (Example : Boolean.valueOf)
 - You can return a subtype of the return class 

Cons
 - You can't subclass a class without public or protected constructor
 - It can be hard to find the static factory method for a new user of the API

Example :
```java
public static Boolean valueOf(boolean b){
  return b ? Boolean.TRUE :  Boolean.FALSE;
}
```

__Item 2 : Builder__

Pros
 - Builder are interesting when your constructor may need many arguments
 - It's easier to read and write
 - Your class can be immutable (Instead of using a java bean)
 - You can prevent inconsistent state of you object

Example :
```java
public class NutritionFacts {
  private final int servingSize;
  private final int servings;
  private final int calories;
  private final int fat;
  private final int sodium;

  public static class Builder {
    //Required parameters
    private final int servingSize:
    private final int servings;
    //Optional parameters - initialized to default values
    private int calories    = 0;
    private int fat       = 0;
    private int sodium      = 0;

    public Builder (int servingSize, int servings) {
      this.servingSize = servingSize;
      this.servings = servings;
    }
    public Builder calories (int val) {
      calories = val;
      return this;        
    }
    public Builder fat (int val) {
      fat = val;
      return this;        
    }
    public Builder sodium (int val) {
      sodium = val;
      return this;        
    }
    public NutritionFacts build(){
      return new NutritionFacts(this);
    }
  }
  private NutritionFacts(Builder builder){
    servingSize   = builder.servingSize;
    servings    = builder.servings;
    calories    = builder.calories;
    fat       = builder.fat;
    sodium      = builder.sodium;
  }
}
```

__Item 3 : Think of Enum to implement the Singleton pattern__

Example :
```java
public enum Elvis(){
  INSTANCE;
  ...
  public void singASong(){...}
}
```

__Item 4 : Utility class should have a private constructor__

A utility class with only static methods will never be instantiated. Make sure it's the case with a private constructor to prevent the construction of a useless object.

Example :
```java
public class UtilityClass{
  // Suppress default constructor for noninstantiability
  private UtilityClass(){
    throw new AssertionError();
  }
  ...
}
```

__Item 5 : Dependency Injection__

A common mistake is the use of a singleton or a static utility class for a class that depends on underlying ressources.
The use of dependency injection gives us more flexibility, testability and reusability

Example : 
```java
public class SpellChecker {
  private final Lexicon dictionary;
  public SpellChecker (Lexicon dictionary) {
    this.dictionary = Objects.requireNonNull(dictionary);
  }
  ...
}
```

__Item 6 : Avoid creating unnecessary objects__

When possible use the static factory method instead of constructor (Example : Boolean)
Be vigilant on autoboxing. The use of the primitive and his boxed primitive type can be harmful. Most of the time use primitives.

__Item 7 : Eliminate obsolete object references__

Memory leaks can happen in  :
 - A class that managed its own memory
 - Caching objects
 - The use of listeners and callback

In those three cases the programmer needs to think about nulling object references that are known to be obsolete

Example : 
In a stack implementation, the pop method could be implemented this way :

```java
public pop(){
  if (size == 0) {
    throw new EmptyStackException();
  }
  Object result = elements[--size];
  elements[size] = null; // Eliminate obsolete references.
  return result;
}
```

__Item 8 : Avoid finalizers and cleaners__

Finalizers and cleaners are not guaranteed to be executed. It depends on the garbage collector and it can be executed long after the object is not referenced anymore.
If you need to let go of resources, think about implementing the *AutoCloseable* interface.

__Item 9 : Try with resources__

When using try-finally blocks exceptions can occur in both the try and finally block. It results in non clear stacktraces.
Always use try with resources instead of try-finally. It's clearer and the exceptions that can occured will be clearer.

Example :
```java
static void copy(String src, String dst) throws IOException {
  try (InputStream in = new InputStream(src); 
    OutputStream out = new FileOutputStream(dst)) {
    byte[] buf = new byte[BUFFER_SIZE];
    int n;
    while ((n = in.read(buf)) >= 0) {
      out.write(buf, 0, n);
    }
  }
}
```

#### Methods of the Object class

__Item 10 : equals__

The equals method needs to be overriden  when the class has a notion of logical equality.
This is generally the case for value classes.

The equals method must be :
 - Reflexive (x = x)
 - Symmetric (x = y => y = x)
 - Transitive (x = y and y = z => x = z)
 - Consistent
 - For non null x, x.equals(null) should return false
 
Not respecting those rules will have impact on the use of List, Set or Map.

__Item 11 : hashCode__

The hashCode method needs to be overriden if the equals method is overriden.

Here is the contract of the hashCode method :
 - hashCode needs to be consistent
 - if a.equals(b) is true then a.hashCode() == b.hashCode()
 - if a.equals(b) is false then a.hashCode() doesn't have to be different of b.hashCode()  
 
If you don't respect this contract, HashMap or HashSet will behave erratically.

__Item 12 : toString__

Override toString in every instantiable classes unless a superclass already did it.
Most of the time it helps when debugging.
It needs to be a full representation of the object and every informations contained in the toString representation should be accessible in some other way in order to avoid programmers to parse the String representation.

__Item 13 : clone__

When you implement Cloneable, you should also override clone with a public method whose return type is the class itself.
This method should start by calling super.clone and then also clone all the mutable objects of your class.

Also, when you need to provide a way to copy classes, you can think first of copy constructor or copy factory except for arrays.

__Item 14 : Implementing Comparable__

If you have a value class with an obvious natural ordering, you should implement Comparable.

Here is the contract of the compareTo method : 
 - signum(x.compareTo(y)) == -signum(y.compareTo(x))
 - x.compareTo(y) > 0 && y.compareTo(z) > 0 => x.compareTo(z) > 0
 - x.compareTo(y) == 0 => signum(x.compareTo(z)) == signum(y.compareTo(z))
 
It's also recommended that (x.compareTo(y) == 0) == x.equals(y).
If it's not, it has to be documented that the natural ordering of this class is inconsistent with equals.

When confronted to different types of Object, compareTo can throw ClassCastException.

#### Classes and Interfaces

__Item 15 : Accessibility__

Make accessibility as low as possible. Work on a public API that you want to expose and try not to give access to implementation details.

__Item 16 : Accessor methods__

Public classes should never expose its fields. Doing this will prevent you to change its representation in the future.
Package private or private nested classes, can, on the contrary, expose their fields since it won't be part of the API.

__Item 17 : Immutability__

To create an immutable class : 
 - Don't provide methods that modify the visible object's state
 - Ensure that the class can't be extended
 - Make all fields final
 - Make all fields private
 - Don't give access to a reference of a mutable object that is a field of your class
 
As a rule of thumb, try to limit mutability.

__Item 18 : Favor composition over inheritance__

With inheritance, you don't know how your class will react with a new version of its superclass.
For example, you may have added a new method whose signature will happen to be the same than a method of its superclass in the next release.
You will then override a method without even knowing it.

Also, if there is a flaw in the API of the superclass you will suffer from it too.
With composition, you can define your own API for your class.

As a rule of thumb, to know if you need to choose inheritance over composition, you need to ask yourself if B is really a subtype of A.

Example :
```java
// Wrapper class - uses composition in place of inheritance
public class InstrumentedSet<E> extends ForwardingSet<E> {
  private int addCount = 0;
  public InstrumentedSet (Set<E> s){
    super(s)
  }

  @Override
  public boolean add(E e){
    addCount++;
    return super.add(e);
  }

  @Override
  public boolean addAll (Collection< ? extends E> c){
    addCount += c.size();
    return super.addAll(c);
  }

  public int getAddCount() {
    return addCount;
  }
}

// Reusable forwarding class
public class ForwardingSet<E> implements Set<E> {
  private final Set<E> s; // Composition
  public ForwardingSet(Set<E> s) { this.s = s ; }

  public void clear() {s.clear();}
  public boolean contains(Object o) { return s.contains(o);}
  public boolean isEmpty() {return s.isEmpty();}
  ...
}
```

__Item 19 : Create classes for inheritance or forbid it__

First of all, you need to document all the uses of overridable methods.
Remember that you'll have to stick to what you documented.
The best way to test the design of your class is to try to write subclasses.
Never call overridable methods in your constructor.

If a class is not designed and documented for inheritance it should be me made forbidden to inherit her, either by making it final, or making its constructors private (or package private) and use static factories.


__Item 20 : Interfaces are better than abstract classes__

Since Java 8, it's possible to implements default mechanism in an interface.
Java only permits single inheritance so you probably won't be able to extends your new abstract class to exising classes when you always will be permitted to implements a new interface.

When designing interfaces, you can also provide a Skeletal implementation. This type of implementation is an abstract class that implements the interface. 
It can help developers to implement your interfaces and since default methods are not permitted to override Object methods, you can do it in your Skeletal implementation.
Doing both allows developers to use the one that will fit their needs.


__Item 21 : Design interfaces for posterity__

With Java 8, it's now possible to add new methods in interfaces without breaking old implemetations thanks to default methods.
Nonetheless, it needs to be done carefully since it can still break old implementations that will fail at runtime.

__Item 22 : Interfaces are mean't to define types__

Interfaces must be used to define types, not to export constants.

Example :

```java
//Constant interface antipattern. Don't do it !
public interface PhysicalConstants {
  static final double AVOGADROS_NUMBER = 6.022_140_857e23;
  static final double BOLTZMAN_CONSTANT = 1.380_648_52e-23;
  ...
}
//Instead use
public class PhysicalConstants {
  private PhysicalConstants() {} //prevents instatiation
  
  public static final double AVOGADROS_NUMBER = 6.022_140_857e23;
  public static final double BOLTZMAN_CONSTANT = 1.380_648_52e-23;
  ...
}
```

__Item 23 : Tagged classes__

Those kinds of classes are clutted with boilerplate code (Enum, switch, useless fields depending on the enum).
Don't use them. Create a class hierarchy that will fit you needs better.


__Item 24 : Nested classes__

If a member class does not need access to its enclosing instance then declare it static.
If the class is non static, each intance will have a reference to its enclosing instance. That can result in the enclosing instance not being garbage collected and memory leaks.

__Item 25 : One single top level class by file__

Even thow it's possible to write multiple top level classes in a single file, don't !
Doing so can result in multiple definition for a single class at compile time.

#### Generics

__Item 26 : Raw types__

A raw type is a generic type without its type parameter (Example : *List* is the raw type of *List\<E>*)
Raw types shouldn't be used. They exist for compatibility with older versions of Java.
We want to discover mistakes as soon as possible (compile time) and using raw types will probably result in error during runtime.
We still need to use raw types in two cases : 
 - Usage of class litrals (List.class)
 - Usage of instanceof
 
Examples :

```java
//Use of raw type : don't !
private final Collection stamps = ...
stamps.add(new Coin(...)); //Erroneous insertion. Does not throw any error
Stamp s = (Stamp) stamps.get(i); // Throws ClassCastException when getting the Coin

//Common usage of instance of
if (o instanceof Set){
  Set<?> = (Set<?>) o;
}
```

__Item 27 : Unchecked warnings__

Working with generics can often create warnings about them. Not having those warnings assure you that your code is typesafe.
Try as hard as possible to eliminate them. Those warnings represents a potential ClassCastException at runtime.
When you prove your code is safe but you can't remove this warning use the annotation @SuppressWarnings("unchecked") as close as possible to the declaration.
Also, comment on why it is safe.

__Item 28 : List and arrays__

Arrays are covariant and generics are invariant meaning that Object[] is a superclass of String[] when List\<Object> is not for List\<String>.
Arrays are reified when generics are erased. Meaning that array still have their typing right at runtime when generics don't. In order to assure retrocompatibility with previous version List\<String> will be a List at runtime.
Typesafety is assured at compile time with generics. Since it's always better to have our coding errors the sooner (meaning at compile time), prefer the usage of generics over arrays.

__Item 29 : Generic types__ 

Generic types are safer and easier to use because they won't require any cast from the user of this type.
When creating new types, always think about generics in order to limit casts.

__Item 30 : Generic methods__

Like types, methods are safer and easier to use it they are generics. 
If you don't use generics, your code will require users of your method to cast parameters and return values which will result in non typesafe code.

__Item 31 : Bounded wildcards__

Bounded wildcards are important in order to make our code as generic as possible. 
They allow more than a simple type but also all their sons (? extends E) or parents (? super E)

Examples :

If we have a stack implementation and we want to add two methods pushAll and popAll, we should implement it this way :
```java
//We want to push in everything that is E or inherits E
public void pushAll(Iterable<? Extends E> src){
  for (E e : src) {
    push(e);
  }
}

//We want to pop out in any Collection that can welcome E
public void popAll(Collection<? super E> dst){
  while(!isEmpty()) {
    dst.add(pop());
  }
}
```

__Item 32 : Generics and varargs__

Even thow it's not legal to declare generic arrays explicitly, it's still possible to use varargs with generics.
This inconsistency has been a choice because of its usefulness (Exemple : Arrays.asList(T... a)).
This can, obviously, create problems regarding type safety. 
To make a generic varargs method safe, be sure :
 - it doesn't store anything in the varargs array
 - it doesn't make the array visible to untrusted code
When those two conditions are met, use the annotation @SafeVarargs to remove warnings that you took care of and show users of your methods that it is typesafe.

__Item 33 : Typesafe heterogeneous container__

Example : 

```java
public class Favorites{
  private Map<Class<?>, Object> favorites = new HashMap<Class<?>, Object>();

  public <T> void putFavorites(Class<T> type, T instance){
    if(type == null)
      throw new NullPointerException("Type is null");
    favorites.put(type, type.cast(instance));//runtime safety with a dynamic cast
  }

  public <T> getFavorite(Class<T> type){
    return type.cast(favorites.get(type));
  }
}
```

#### Enums and annotations

__Item 34 : Enums instead of int constants__

Prior to enums it was common to use int to represent enum types. Doing so is now obsolete and enum types must be used.
The usage of int made them difficult to debug (all you saw was int values).

Enums are classes that export one instance for each enumeration constant. They are instance controlled. They provide type safety and a way to iterate over each values.

If you need a specific behavior for each value of your enum, you can declare an abstract method that you will implement for each value.

Enums have an automatically generated valueOf(String) method that translates a constant's name into the constant. If the toString method is overriden, you should write a fromString method.

Example : 

```java
public enum Operation{
  PLUS("+") { double apply(double x, double y){return x + y;}},
  MINUS("-") { double apply(double x, double y){return x - y;}},
  TIMES("*") { double apply(double x, double y){return x * y;}},
  DIVIDE("/") { double apply(double x, double y){return x / y;}};

  private final String symbol;
  private static final Map<String, Operation> stringToEnum = Stream.of(values()).collect(toMap(Object::toString, e -> e));
  
  Operation(String symbol) {
    this.symbol = symbol;
  }
  
  public static Optional<Operation> fromString(String symbol) {
    return Optional.ofNullable(stringToEnum.get(symbol);
  }
  
  @Override
  public String toString() {
    return symbol;
  }
  
  abstract double apply(double x, double y);
}
```

__Item 35 : Instance fields instead of ordinals__

Never use the ordinal method to calculate a value associated with an enum.

Example : 

```java
//Never do this !
public enum Ensemble{
  SOLO, DUET, TRIO, QUARTET;
  public int numberOfMusicians(){
    return ordinal() + 1;
  }
}

//Instead, do this : 
public enum Ensemble{
  SOLO(1), DUET(2), TRIO(3), QUARTET(4);
  
  private final int numberOfMusicians;
  
  Ensemble(int size) {
    this.numberOfMusicians = size;
  }
  
  public int numberOfMusicians(){
    return numberOfMusicians;
  }
}

```

__Item 36 : EnumSet instead of bit fields__

Before enums existed, it was common to use bit fields for enumerated types that would be used in sets. This would allow you to combine them but they have the same issues than int constants we saw in item 34.
Instead use EnumSet to combine multiple enums.

Example : 

```java
public class Text {
  public enum Style {BOLD, ITALIC, UNDERLINE}
  public void applyStyle(Set<Style> styles) {...}
}

//Then you would use it like this : 
text.applyStyle(EnumSet.of(Style.BOLD, Style.ITALIC));
```

__Item 37 : EnumMap instead of ordinal__

You may want to store data by a certain enum. For that you could have the idea to use the ordinal method. This is a bad practice.
Instead, prefer the use of EnumMaps.

__Item 38 : Emulate extensible enums with interfaces__

The language doesn't allow us to write extensible enums. In the few cases that we would want an enum type to be extensible, we can emulate it with an interface written for the basic enum.
Users of the api will be able to implements this interface in order to "extend" your enum.

__Item 39 : Annotations instead of naming patterns__

Prior to JUnit 4, you needed to name you tests by starting with the word "test". This is a bad practice since the compiler will never complain if, by mistake, you've names a few of them "tset*".
Annotations are a good way to avoid this kind of naming patterns and gives us more security.

Example : 

```java
//Annotation with array parameter
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface ExceptionTest {
 Class<? extends Exception>[] value();
}

//Usage of the annotation
@ExceptionTest( {IndexOutOfBoundsException.class, NullPointerException.class})
public void myMethod() { ... }

//By reflexion you can use the annotation this way 
m.isAnnotationPresent(ExceptionTest.class);
//Or get the values this way : 
Class<? extends Exception>[] excTypes = m.getAnnotation(ExceptionTest.class).value();
```

__Item 40 : Use @Override__

You should use the @Override for every method declaration that you believe to override a superclass declaration.

Example : 

```java
//Following code won't compile. Why ?
@Override
public boolean equals(Bigram b) {
  return b.first == first && b.second == second;
}

/**
This won't compile because we aren't overriding the Object.equals method. We are overloading it !
The annotation allows the compiler to warn us of this mistake. That's why @Override is really important !
**/
```

__Item 41 : Marker interfaces__

A marker interface is an interface that contains no method declaration. It only "marks" a class that implements this interface. One common example in the JDK is Serializable.
Using marker interface results in compile type checking.

#### Lambdas and streams

__Item 42 : Lambdas are clearer than anonymous classes__

Lambdas are the best way to represent function objects. As a rule of thumb, lambdas needs to be short to be readable. Three lines seems to be a reasonnable limit.
Also the lambdas needs to be self-explanatory since it lacks name or documentation. Always think in terms of readability.

__Item 43 : Method references__

Most of the time, method references are shorter and then clearer. The more arguments the lambdas has, the more the method reference will be clearer.
When a lambda is too long, you can refactor it to a method (which will give a name and documentation) and use it as a method reference.

They are five kinds of method references : 

|Method ref type|Example|Lambda equivalent|
|--|--|--|
|Static|Integer::parseInt|str -> Integer.parseInt(str)|
|Bound|Instant.now()::isAfter|Instant then = Instant.now(); t->then.isAfter(t)|
|Unbound|String::toLowerCase|str -> str.toLowerCase()|
|Class Constructor|TreeMap<K,V>::new|() -> new TreeMap<K,V>|
|Array Constructor|int[]::new|len -> new int[len]|

__Item 44 : Standard functional interfaces__

java.util.Function provides a lot of functional interfaces. If one of those does the job, you should use it

Here are more common interfaces : 

|Interface|Function signature|Example|
|--|--|--|
|UnaryOperator<T>|T apply(T t)|String::toLowerCase|
|BinaryOperator<T>|T apply(T t1, T t2)|BigInteger::add|
|Predicate<T>|boolean test(T t)|Collection::isEmpty|
|Function<T,R>|R apply(T t)|Arrays::asList|
|Supplier<T>|T get()|Instant::now|
|Consumer<T>|void accept(T t)|System.out::println|

When creating your own functional interfaces, always annotate with @FunctionalInterfaces so that it won't compile unless it has exactly one abstract method.

__Item 45 : Streams__

Carefully name parameters of lambda in order to make your stream pipelines readable. Also, use helper methods for the same purpose.

Streams should mostly be used for tasks like : 
 - Transform a sequence of elements
 - Filter a sequence of elements
 - Combine sequences of elements 
 - Accumulate a sequence of elements inside a collection (perhaps grouping them)
 - Search for en element inside of a sequence

__Item 46 : Prefer side-effect-free functions in streams__
 
Programming with stream pipelines should be side effect free. 
The terminal forEach method should only be used to report the result of a computation not to perform the computation itself.
In order to use  streams properly, you need to know about collectors. The most importants are toList, toSet, toMap, groupingBy and joining.

__Item 47 : Return collections instead of streams__

The collection interface is a subtype of Iterable and has a stream method. It provides both iteration and stream access.
If the collection in too big memory wise, return what seems more natural (stream or iterable)

__Item 48 : Parallelization__

Parallelizing a pipeline is unlikely to increase its performance if it comes from a Stream.iterate or the limit method is used.
As a rule of thumb, parallelization should be used on ArrayList, HashMap, HashSet, ConcurrentHashMap, arrays, int ranges and double ranges. Those structure can be divided in any desired subranged and so on, easy to work among parrallel threads.

#### Methods

__Item 49 : Check parameters for validity__

When writing a public or protected method, you should begin by checking that the parameters are not enforcing the restrictions that you set.
You should also document what kind of exception you will throw if a parameter enforce those restrictions.
The *Objects.requireNonNull* method should be used for nullability checks.

__Item 50 : Defensive copies__

If a class has mutable components that comes from or goes to the client, the class needs to make defensive copies of those components.

Example : 

```java
//This example is a good example but since java 8, we would use Instant instead of Date which is immutable
public final class Period{
  private final Date start;
  private final Date end;
  /**
  * @param start the beginning of the period
  * @param end the end of the period; must not precede start;
  * @throws IllegalArgumentException if start is after end
  * @throws NullPointerException if start or end is null
  */
  public Period(Date start, Date end) {
    this.start = new Date(start.getTime());
    this.end = new Date(end.getTime());
    if(start.compare(end) > 0) {
      throw new IllegalArgumentException(start + " after " + end );
    }
  }

  public Date start(){
    return new Date(start.getTime());
  }

  public Date end(){
    return new Date(end.getTime());
  }
  ...
}
```

__Item 51 : Method signature__

Few rules to follow when designing you API :
 - Choose your methode name carefully. Be explicit and consistent.
 - Don't provide too many convenience methods. A small API is easier to learn and use.
 - Avoid long parameter lists. Use helper class if necessary.
 - Favor interfaces over classes for parameter types.
 - Prefer enum types to boolean parameters when it makes the parameter more explicit.
 
__Item 52 : Overloading__

Example : 

```java
// Broken! - What does this program print?
public class CollectionClassifier {
  public static String classify(Set<?> s) {
    return "Set";
  }
  public static String classify(List<?> lst) {
    return "List";
  }
  public static String classify(Collection<?> c) {
    return "Unknown Collection";
  }
  public static void main(String[] args) {
    Collection<?>[] collections = {
      new HashSet<String>(),
      new ArrayList<BigInteger>(),
      new HashMap<String, String>().values()
    };
  for (Collection<?> c : collections)
    System.out.println(classify(c)); // Returns "Unknown Collection" 3 times
  }
}
```

As shown in the previous example overloading can be confusing. It is recommanded to never export two overloadings with the same number of parameters.
If you have to, consider giving different names to your methods. (writeInt, writeLong...)

__Item 53 : Varargs__

Varargs are great when you need to define a method with a variable number of arguments. Always precede the varargs parameter with any required parameter.

__Item 54 : Return empty collections or arrays instead of null__

Returning null when you don't have elements to return makes the use of your methods more difficult. Your client will have to check if you object is not null.
Instead always return an empty array of collection.

__Item 55 : Return of Optionals__

You should declare a method to return Optional<T> if it might not be able to return a result and clients will have to perform special processing if no result is returned.
You should never use an optional of a boxed primitive. Instead use OptionalInt, OptionalLong etc...

__Item 56 : Documentation__

Documentation should be mandatory for exported API. 

#### General programming

__Item 57 : Minimize the scope of local variables__

To limit the scope of your variables, you should : 
 - declare them when first used
 - use for loops instead of while when doable
 - keep your methods small and focused
 
```java
//Idiom for iterating over a collection 
for (Element e : c) {
  //Do something with e
}

//Idiom when you need the iterator
for (Iterator<Element> i = c.iterator() ; i.hasNext() ; ) {
  Element e = i.next();
  //Do something with e
}

//Idiom when the condition of for is expensive
for (int i = 0, n = expensiveComputation() ; i < n ; i++) {
  //Do something with i
}
```

__Item 58 : For each loops instead of traditional for loops__

The default for loop must be a for each loop. It's more readable and can avoid you some mistakes.

Unfortunately, there are situations where you can't use this kind of loops : 
 - When you need to delete some elements
 - When you need to replace some elements
 - When you need to traverse multiple collections in parallel
 
__Item 59 : Use the standard libraries__

When using a standard library you take advantage of the knowledge of experts and the experience of everyone who used it before you.
Don't reinvent the wheel. Library code is probably better than code that we would write simply because this code receives more attention than what we could afford.

__Item 60 : Avoid float and double for exact answers__

Float and double types are not suited for monetary calculations. Use BigDecimal, int or long for this kind of calculation.
 
__Item 61 : Prefer primitives to boxed primitives__

Use primitives whenever you can. The use of boxed primitives is essentially for type parameters in parameterized types (example : keys and values in collections)

```java
//Can you spot the object creation ?
Long sum = 0L;
for (long i = 0 ; i < Integer.MAX_VALUE ; i++) {
  sum += i;
}
System.out.println(sum);

//sum is repeatably boxed and unboxed which cause a really slow running time.

```

__Item 62 : Avoid Strings when other types are more appropriate__

Avoid natural tendency to represent objects as Strings when there is better data types available.

__Item 63 : String concatenation__

Don't use the String concatenation operator to combine more than a few strings. Instead, use a StringBuilder.

__Item 64 : Refer to objects by their interfaces__

If an interface exists, parameters, return values, variables and fields should be declared using this interface to insure flexibility.
If there is no appropriate interface, use the least specific class that provides the functionality you need.

__Item 65 : Prefer interfaces to reflection__

Reflextion is a powerful tool but has many disadvantages. 
When you need to work with classes unknown at compile time, try to only use it to instantiate object and then access them by using an interface of superclass known at compile time.

__Item 66 : Native methods__

It's really rare that you will need to use native methods to improve performances. If it's needed to access native libraries use as little native code as possible.

__Item 67 : Optimization__

Write good programs rather than fast one. Good programs localize design decisions within individual components so those individuals decisions can be changed easily if performance becomes an issue.
Good designs decisions will give you good performances.
Measure performance before and after each attempted optimization.

__Item 68 : Naming conventions__

| Indentifier Type        |  Examples                       |
|-------------------------|-----------------------------------------------|
| Package                 | org.junit.jupiter, com.google.common.collect  |
| Class or Interface      | Stream, FutureTask, LinkedHashMap, HttpServlet|
| Method or Field         | remove, groupBy, getCrc               |
| Constant Field          | MIN_VALUE, NEGATIVE_INFINITY              |
| Local Variable        | i, denom, houseNum                    |
| Type Parameter      | T, E, K, V, X, R, U, V, T1, T2          |

#### Exceptions

__Item 69 : Exceptions are for exceptional conditions__

Exceptions should never be used for ordinary control flow. They are designed for exceptional conditions and should be used accordingly.

__Item 70 : Checked exceptions and runtime exceptions__

Use checked exceptions for conditions from which the caller can reasonably recover.
Use runtime exceptions to indicate programming errors.
By convention, *errors* are only used by the JVM to indicate conditions that make execution impossible. 
Therefore, all the unchecked throwables you implement must be a subclass of RuntimeException.

__Item 71 : Avoid unnecessary use of checked exceptions__

When used sparingly, checked exceptions increase the reliability of programs. When overused, they make APIs painful to use.
Use checked exceptions only when you want the callers to handle the exceptional condition.
Remember that a method that throws a checked exception can't be used directly in streams.

__Item 72 : Standard exceptions__

When appropriate, use the exceptions provided by the jdk. Here's a list of the most common exceptions : 

| Exception                       |  Occasion for Use                                                              |
|---------------------------------|--------------------------------------------------------------------------------|
| IllegalArgumentException        |  Non-null parameter value is inappropriate                                     |
| IllegalStateException           |  Object state is inappropriate for method invocation                           |
| NullPointerException            |  Parameter value is null where prohibited                                      |
| IndexOutOfBoundsException       |  Index parameter value is out of range                                         |
| ConcurrentModificationException |  Concurrent modification of an object has been detected where it is prohibited |
| UnsupportedOperationException   |  Object does not support method                                                |

__Item 73 : Throw exceptions that are appropriate to the abstraction__

Higher layers should catch lower level exceptions and throw exceptions that can be explained at their level of abstraction.
While doing so, don't forget to use chaining in order to provide the underlying cause for failure.

__Item 74 : Document thrown exceptions__

Document every exceptions that can be thrown by your methods, checked or unchecked. This documentation should be done by using the @throws tag.
Nonetheless, only checked exceptions must be declared as thrown in your code.

__Item 75 : Include failure capture information in detail messages__

The detailed message of an exception should contain the values of all parameters that lead to such failure.

Example : 

```java
public IndexOutOfBoundsException(int lowerBound, int upperBound, int index) {
  super(String.format("Lower bound : %d, Upper bound : %d, Index : %d", lowerBound, upperBound, index));
  
  //Save for programmatic access
  this.lowerBound = lowerBound;
  this.upperBound = upperBound;
  this.index = index;
}

```

__Item 76 : Failure atomicity__

A failed method invocation should leave the object in the state that it was before the invocation.

__Item 77 : Don't ignore exceptions__

An empty catch block defeats the purpose of exception which is to force you to handle exceptional conditions.
When you decide with *very* good reasons to ignore an exception the catch block should contain a comment explaining those reasons and the variable should be named ignored.

#### Concurrency

__Item 78 : Synchronize access to shared mutable data__

Synchronization is not guaranteed to work unless both read and write operations are synchronized.
When multiple threads share mutable data, each of them that reads or writes this data must perform synchronization.

__Item 79 : Avoid excessive synchronization__

As a rule, you should do as little work as possible inside synchronized regions.
When designing a mutable class think about whether or not it should be synchronized.

__Item 80 : Executors, tasks and streams__

The java.util.concurrent package added a the executor framework. It contains class such as ExecutorService that can help you run Tasks in other threads.
You should refrain from using Threads and now using this framework in order to parallelize computation when needed.

__Item 81 : Prefer concurrency  utilities to wait and notify__

Using wait and notify is quite difficult. You should then use the higher level concurrency utilities such as the Executor Framework, concurrent collections and synchronizers.
 - Common concurrent collections : ConcurrentHashMap, BlockingQueue
 - Common synchronizers : CountdownLatch, Semaphore
 
__Item 82 : Document thread safety__

Every class should document its thread safety. When writing and unconditionnally thread safe class, consider using a private lock object instead of synchronized methods. This will give you more flexibility.

Example : 

```java
// Private lock object idiom - thwarts denial-of-service attack
private final Object lock = new Object();

public void foo() {
  synchronized(lock) {
    ...
  }
}
```

__Item 83 : Lazy initialization__

In the context of concurrency, lazy initialization is tricky. Therefore, normal initialization is preferable to lazy initialization.

On a static field you can use the lazy initialization holder class idiom :
```java
// Lazy initialization holder class idiom for static fields
private static class FieldHolder {
  static final FieldType field = computeFieldValue();
}
static FieldType getField() { return FieldHolder.field; }
```

On an instance field you can use the double-check idiom :
```java
// Double-check idiom for lazy initialization of instance fields
private volatile FieldType field;
FieldType getField() {
  FieldType result = field;
  if (result == null) { // First check (no locking)
    synchronized(this) {
      result = field;
      if (result == null) // Second check (with locking)
        field = result = computeFieldValue();
    }
  }
  return result;
}
```

__Item 84 : Don't depend on the thread scheduler__

The best way to write a robust and responsive program is to ensure that the average number of *runnable* threads is not significantly greater than the number of processors.
Thread priorities are among the least portable features of Java.

####  Serialization

__Item 85 : Prefer alternatives to Java serialization__

Serialization is dangerous and should be avoided. Alternatives such as JSON should be used.
If working with serialization, try not deserialize untrusted data. If you have no other choice, use object deserialization filtering.

__Item 86 : Implement *Serializable* with great caution__

Unless a class will only be used in a protected environment where versions will never have to interoperate and servers will never be exposed to untrusted data, implementing Serializable should be decided with great care.

__Item 87 : Custom serialized form__

Use the default serialized form only if it's a reasonable description of the logical state of the object. Otherwise, write your own implementation in order to only have its logical state.

__Item 88 : Write readObject methods defensively__

When writing a readObject method, keep in mind that you are writing a public constructor and it must produce a valid instance regardless of the stream it is given.

__Item 89 : For instance control, prefer enum types to readResolve__

When you need instance control (such a Singleton) use enum types whenever possible.

__Item 90 : Serialization proxies__

The serialization proxy pattern is probably the easiest way to robustly serialize objects if those objects can't be extendable or does not contain circularities.

```java
// Serialization proxy for Period class
private static class SerializationProxy implements Serializable {
  private final Date start;
  private final Date end;

  SerializationProxy(Period p) {
    this.start = p.start;
    this.end = p.end;
  }

  private static final long serialVersionUID = 234098243823485285L; // Any number will do (Item 75)
}

// writeReplace method for the serialization proxy pattern
private Object writeReplace() {
  return new SerializationProxy(this);
}

// readObject method for the serialization proxy pattern
private void readObject(ObjectInputStream stream) throws InvalidObjectException {
  throw new InvalidObjectException("Proxy required");
}

// readResolve method for Period.SerializationProxy
private Object readResolve() {
  return new Period(start, end); // Uses public constructor
}
```




### Concepts

* [Fundamental theorem of software engineering](https://en.wikipedia.org/wiki/Fundamental_theorem_of_software_engineering): We can solve any problem by introducing an extra level of indirection

* [Pareto principle](https://en.wikipedia.org/wiki/Pareto_principle): in general the 80% of a certain piece of software can be written in 20% of the total allocated time. Conversely, the hardest 20% of the code takes 80% of the time.  

* [Ninety-ninety rule](https://en.wikipedia.org/wiki/Ninety-ninety_rule): done 99%. This indicates a common scenario where planned work is completed but cannot be signed off, pending a single final activity which may not occur for a substantial amount of time (1% to finish costs a lot of time!)  

* [Hofstadter's law](https://en.wikipedia.org/wiki/Hofstadter%27s_law): *It always takes longer than you expect, even when you take into account Hofstadter's Law* to describe the widely experienced difficulty of accurately estimating the time it will take to complete tasks of substantial complexity  

* [SMOP (small matter of programming](https://en.wikipedia.org/wiki/Small_matter_of_programming)): is a phrase used to ironically indicate that a suggested feature or design change would in fact require a great deal of effort  

* [Peter Principle](https://en.wikipedia.org/wiki/Peter_principle): states that people are promoted to their level of incompetence  

* [Software Peter principle](https://en.wikipedia.org/wiki/Software_Peter_principle): describe a dying project which has become too complex to be understood even by its own developers. It is well known in the industry as a silent killer of projects  

* [Dunning–Kruger effect](https://en.wikipedia.org/wiki/Dunning%E2%80%93Kruger_effect): people with low ability at a task overestimate their ability  

* [Wirth's law](https://en.wikipedia.org/wiki/Wirth%27s_law):  software is getting slower more rapidly than hardware is becoming faster (ms word. Computer manufacturers keep increasing processing power and the amount of memory our computers can hold, software developers simply add more complexity to programs in order to make them do more -- and that's exactly what they do, somehow it is it the contrary of Wirth's Law  Moore's law  

* [Moore's law](https://en.wikipedia.org/wiki/Moore%27s_law):  doubling every year in the number of components per integrated circuit, somehow it is it the contrary of Wirth's Law  

* [Brooks's law](https://en.wikipedia.org/wiki/Brooks%27s_law): adding manpower to a late software project makes it later

* [Occam's razor](https://en.wikipedia.org/wiki/Occam%27s_razor): the simplest solution is most likely the right one". Occam's razor says that when presented with competing hypotheses that make the same predictions, one should select the solution with the fewest assumptions. Principles like YAGNI and KISS are examples of Occam’s Razor in coding. 

* [Osborne effect](https://en.wikipedia.org/wiki/Osborne_effect): states that prematurely discussing future, unavailable products damages sales of existing products  

* [Second-system effect](https://en.wikipedia.org/wiki/Second-system_effect): When one is designing the successor to a relatively small, elegant, and successful system, there is a tendency to become grandiose in one's success and design an elephantine feature-laden monstrosity    

* [GIGO (Garbage In, Garbage Out)](https://en.wikipedia.org/wiki/Garbage_in,_garbage_out):implies bad input will result in bad output.Because computers operate using strict logic, invalid input may produce unrecognizable output, or "garbage"

* [Canonical](https://www.webopedia.com/TERM/C/canonical.html): Martin Fowler's book Refactoring: Improving the Design of Existing Code is the *canonical* reference  

* [Impostor syndrome](https://en.wikipedia.org/wiki/Impostor_syndrome): It is a psychological pattern in which one doubts one's accomplishments and has a persistent internalized fear of being exposed as a "fraud"

* [Teorema del punto gordo y la recta astuta](https://matemelga.wordpress.com/2013/07/26/dos-teoremas-de-geometria/): si no cuadra algo se hace cuadrar!

* [RFI - RFQ - RFP](https://www.cobalt.net/rfi-rfq-rfp-whats-the-difference/): Request For Information / Quotation / Proposal

### Computer Architecture

* [Out Of Order Execution](https://en.wikipedia.org/wiki/Out-of-order_execution)

* [Branch Predictor](https://en.wikipedia.org/wiki/Branch_predictor)

* [Speculative Execution](https://en.wikipedia.org/wiki/Speculative_execution)

* [Tomasulo algorithm](https://en.wikipedia.org/wiki/Tomasulo_algorithm)

* [Z80 Processor](https://en.wikipedia.org/wiki/Zilog_Z80)

### Theory of Computation




* [Cheat Sheets](https://github.com/dideler/cheat-sheets/blob/master/4P61-Computation/cheatsheet.pdf)

* [MoreCheatSheets](http://homepage.divms.uiowa.edu/~hbarbosa/teaching/cs4330/notes/30-summary-automata.pdf)

* [MORE_SUMMARIES](https://www.geeksforgeeks.org/theory-of-computation-automata-tutorials/)

#### Compilers

* [*Recursive descent parser*](https://en.wikipedia.org/wiki/Recursive_descent_parser)

* [*LL parser*](https://en.wikipedia.org/wiki/LL_parser)

* [*LR parser*](https://en.wikipedia.org/wiki/LR_parser)

* [*Context-free grammar*](https://en.wikipedia.org/wiki/Context-free_grammar)

* [*Chomsky hierarchy*](https://en.wikipedia.org/wiki/Chomsky_hierarchy)
 

### Networking

- reverse proxy
* OSI model (Physical, Data link, Network, Transport, Session, Presentation, Application)
* Multithreading vs select
* [*Switch*](https://en.wikipedia.org/wiki/Network_switch), 
* [*hub*](https://en.wikipedia.org/wiki/Ethernet_hub),
* [*router*](https://en.wikipedia.org/wiki/Router_(computing))
* [*TCP congestion*](https://en.wikipedia.org/wiki/TCP_congestion_control)
* *TCP back-pressure*

### Distributed


* [*Consensus*](https://en.wikipedia.org/wiki/Consensus_(computer_science))
* [*Raft*](https://en.wikipedia.org/wiki/Raft_(computer_science)) ([In Search of an Understandable Consensus Algorithm](https://raft.github.io/raft.pdf))
* [*Paxos*](https://en.wikipedia.org/wiki/Paxos_(computer_science))
* What is [*CAP theorem*](https://en.wikipedia.org/wiki/CAP_theorem)? [Illustrated proof](https://mwhittaker.github.io/blog/an_illustrated_proof_of_the_cap_theorem/). [CAP-FAQ](http://www.the-paper-trail.org/page/cap-faq) (It is impossible for a distributed computer system to simultaneously provide all three of the following guarantees: *consistency*, *availability*, *partition tolerance*). [Gilbert and Lynch's paper](https://users.ece.cmu.edu/~adrian/731-sp04/readings/GL-cap.pdf). ["Please stop calling databases CP or AP"](https://martin.kleppmann.com/2015/05/11/please-stop-calling-databases-cp-or-ap.html)).
![CAP theorem](http://guide.couchdb.org/draft/consistency/01.png "CAP theorem")
* What is *map-reduce*? (Word count example)
* *Sharding counters*.
* Distributed software:
  * Distributed streaming platforms: **kafka**
  * Distributed key-value store: **zookeeper**, **etcd**, **Consul**
  * Map-reduce: **hadoop**, **spark**
  * Distributed file system: **hbase**
  * Cluster management: **kubernetes**, **docker-swarm**, **mesos**
* [Herlihy’s consensus hierarchy](https://en.wikipedia.org/wiki/Read-modify-write). Every shared object can be assigned a consensus number, which is the maximum number of processes for which the object can solve wait-free consensus in an asynchronous system.
```
1 Read-write registers
2 Test-and-set, swap, fetch-and-add, queue, stack
⋮ ⋮
∞ Augmented queue, compare-and-swap, sticky byte
```
* [*Consistency models*](https://en.wikipedia.org/wiki/Consistency_model):
  * [*Sequential consistency*](https://en.wikipedia.org/wiki/Sequential_consistency)
  * [*Causal consistency*](https://en.wikipedia.org/wiki/Causal_consistency)
  * [*Eventual consistency*](https://en.wikipedia.org/wiki/Eventual_consistency)
  * [*Monotonic Read Consistency*](https://en.wikipedia.org/wiki/Consistency_model#Monotonic_Read_Consistency)
  * [*Monotonic Write Consistency*](https://en.wikipedia.org/wiki/Consistency_model#Monotonic_Write_Consistency)
  * [*Read-your-writes Consistency*](https://en.wikipedia.org/wiki/Consistency_model#Read-your-writes_Consistency)
  * [*Writes-follows-reads Consistency*](https://en.wikipedia.org/wiki/Consistency_model#Writes-follows-reads_Consistency)
* *Consensus number*. Maximum number of threads for which objects of the class can solve consensus problem.
* [*Logical clock*](https://en.wikipedia.org/wiki/Logical_clock)
* [*Vector clock*](https://en.wikipedia.org/wiki/Vector_clock)


* What is *write-through* and *write-behind* caching? (write-through (synchronous), write-behind (asynchronous))
* HTTP cache options?



### WEB
* WEB security vulnerabilities ([*XSS*](https://en.wikipedia.org/wiki/Cross-site_scripting), [*CSRF*](https://en.wikipedia.org/wiki/Cross-site_request_forgery), [*session fixation*](https://en.wikipedia.org/wiki/Session_fixation), [*SQL injection*](https://en.wikipedia.org/wiki/SQL_injection), [*man-in-the-middle*](https://en.wikipedia.org/wiki/Man-in-the-middle_attack), [*buffer overflow*](https://en.wikipedia.org/wiki/Buffer_overflow))
* *CSRF prevention* (CSRF-token)
* What is [*JSONP*](https://en.wikipedia.org/wiki/JSONP), [*CORS*](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing)? (A communication technique used in JavaScript programs running in web browsers to request data from a server in a different domain, something prohibited by typical web browsers because of the same-origin policy)
* [*HTTPS*](https://en.wikipedia.org/wiki/HTTPS) negotiation steps.
* What is HTTP Strict Transport Security ([*HSTS*](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security))? (Prevents Man in the Middle attacks)
* Browser-server communication methods: WebSocket, EventSource, Comet(Polling, Long-Polling, Streaming)
* [*Character encoding*](https://en.wikipedia.org/wiki/Character_encoding)
* What is [*role-based access control*](https://en.wikipedia.org/wiki/Role-based_access_control) and [*access control list*](https://en.wikipedia.org/wiki/Access_control_list)?
* What is session and persistent cookies, sessionStorage and [localStorage](https://en.wikipedia.org/wiki/Web_storage#Local_and_session_storage)?
* How to implement *remember-me*? (http://jaspan.com/improved_persistent_login_cookie_best_practice)
* Authentication using cookies, [*JWT*](https://en.wikipedia.org/wiki/JSON_Web_Token) (JSON Web Tokens).
What is CORS
-[Short-polling vs Long-polling for real tim


 * Token JWT
 * Oauth2
 *  OWASP
 * clavue publica /privada
 * PGP
 
 
### Security / Cryptography

#### [[⬆]](#toc) <a name='cryptography'>Cryptography:</a>
* [*Public-key cryptography*](https://en.wikipedia.org/wiki/Public-key_cryptography)
* [*Public key certificate*](https://en.wikipedia.org/wiki/Public_key_certificate)
* [*Blockchain*](https://en.wikipedia.org/wiki/Blockchain)
* [*Proof-of-work system*](https://en.wikipedia.org/wiki/Proof-of-work_system)
* [*Secret sharing*](https://en.wikipedia.org/wiki/Secret_sharing)
* [*RSA*](https://en.wikipedia.org/wiki/RSA_(cryptosystem))
```
select 2 primes: p,q
n = p*q
phi(n) = (p-1)*(q-1)
select 1<e<phi(n), gcd(e,phi(n))=1
d=e^-1 mod phi(n)
(e,n) - public key
(d,n) - private key
c = m^e mod n
m = c^d mod n = m^(e*d) mod n = m^(e*d mod phi(n)) mod n = m
```

#### [[⬆]](#toc) <a name='security'>Security:</a>
* What is *OpenID and OAuth2.0 and OpenID Connect*?
* Four main actors in an OAuth system (clients, resource owners, authorization servers, and protected resources)
* What is *access_token, refresh_token, SAML token, JWT token*?
* *Sticky session vs Session Replication*.
* What is hash [*salt*](https://en.wikipedia.org/wiki/Salt_(cryptography))?
* What is *Federated Authentication* ?
* What is *CSP* and *SRI hash* ?
* What is *Clickjacking* and *Cursorjacking* ? How to prevent it ? 

### Internet Of Things






  
-[ICSR](https://en.wikipedia.org/wiki/International_Conference_on_Software_Reuse "International Conference on Software Reuse")  

-[Don't repeat yourself](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself "Don't repeat yourself")  

-[Inheritance (object-oriented programming)](https://en.wikipedia.org/wiki/Inheritance_(object-oriented_programming))  

-[Package principles](https://en.wikipedia.org/wiki/Package_principles)  

-[Don't repeat yourself](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)  

-[GRASP (object-oriented design)](https://en.wikipedia.org/wiki/GRASP_(object-oriented_design))  

-[KISS principle](https://en.wikipedia.org/wiki/KISS_principle)  

-[YAGNI You aren't gonna need it](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it)  

-[Overengineering](https://en.wikipedia.org/wiki/Overengineering)  

-[Technical debt](https://en.wikipedia.org/wiki/Technical_debt): if technical debt is not repaid, it can accumulate 'interest', making it harder to implement changes  

-[Software Entropy or Software rot](https://www.webopedia.com/TERM/S/software_entropy.html): refers to the tendency for software, over time, to become difficult and costly to maintain, even it if it is untouched (new compilers that does not compile the code...)  

-[Software brittleness](https://en.wikipedia.org/wiki/Software_brittleness): Old software that has been patched so many times that even small changes to the source code make the program fail. The term stems from metal that has been worked and reworked so often that it becomes brittle  

-[Inheritance](https://en.wikipedia.org/wiki/Inheritance_(computer_science) "Inheritance (computer science)")  

-[Language binding](https://en.wikipedia.org/wiki/Language_binding "Language binding")  

-[Not invented here](https://en.wikipedia.org/wiki/Not_invented_here "Not invented here") ([antonym](https://en.wikipedia.org/wiki/Antonym "Antonym"))  

-[Polymorphism](https://en.wikipedia.org/wiki/Type_polymorphism "Type polymorphism")  

-[Procedural programming](https://en.wikipedia.org/wiki/Procedural_programming "Procedural programming")  

-[Reinventing the wheel](https://en.wikipedia.org/wiki/Reinventing_the_wheel "Reinventing the wheel") ([antonym](https://en.wikipedia.org/wiki/Antonym "Antonym"))  

-[Reusability](https://en.wikipedia.org/wiki/Reusability "Reusability")  

-[Reuse metrics](https://en.wikipedia.org/wiki/Reuse_metrics "Reuse metrics")  

-[Single source of truth](https://en.wikipedia.org/wiki/Single_source_of_truth "Single source of truth")  

-[inversion of control](https://en.wikipedia.org/wiki/Inversion_of_control)

-[single version of truth](https://en.wikipedia.org/wiki/Single_version_of_the_truth) 

-[Software framework](https://en.wikipedia.org/wiki/Software_framework "Software framework")  

-[*let it crash principle*](https://en.wikipedia.org/wiki/Crash-only_software)

-[Virtual inheritance](https://en.wikipedia.org/wiki/Virtual_inheritance "Virtual inheritance")  

-[Abstraction principle (programming)](https://en.wikipedia.org/wiki/Abstraction_principle_(programming) "Abstraction principle (programming)")  

-[Code duplication](https://en.wikipedia.org/wiki/Code_duplication "Code duplication")  

-[Code reuse](https://en.wikipedia.org/wiki/Code_reuse "Code reuse")  

-[Copy and paste programming](https://en.wikipedia.org/wiki/Copy_and_paste_programming "Copy and paste programming")  

-[Database normalization](https://en.wikipedia.org/wiki/Database_normalization "Database normalization") and [Denormalization](https://en.wikipedia.org/wiki/Denormalization "Denormalization")  

-[Disk mirroring](https://en.wikipedia.org/wiki/Disk_mirroring "Disk mirroring")  

-[Redundancy (engineering)](https://en.wikipedia.org/wiki/Redundancy_(engineering) "Redundancy (engineering)")  

-[Rule of three (computer programming)](https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming) "Rule of three (computer programming)")  popularised by Martin Fowler in Refactoring and attributed to Don Roberts

-[Separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns "Separation of concerns")  

-[Single source of truth](https://en.wikipedia.org/wiki/Single_source_of_truth "Single source of truth") (SSOT/SPOT)  

-[Structured programming](https://en.wikipedia.org/wiki/Structured_programming "Structured programming")  

[*Worse is better*](https://en.wikipedia.org/wiki/Worse_is_better)

#### [-DESIGN PATTERNS GoF](https://en.wikipedia.org/wiki/Design_Patterns)

**[Creational patterns](https://en.wikipedia.org/wiki/Creational_pattern "Creational pattern")**:are ones that create objects, rather than having to instantiate objects directly. This gives the program more flexibility in deciding which objects need to be created for a given case.  

*   [Abstract factory](https://en.wikipedia.org/wiki/Abstract_factory_pattern "Abstract factory pattern") groups object factories that have a common theme.  
*   [Builder](https://en.wikipedia.org/wiki/Builder_pattern "Builder pattern") constructs complex objects by separating construction and representation.  
*   [Factory method](https://en.wikipedia.org/wiki/Factory_method_pattern "Factory method pattern") creates objects without specifying the exact class to create.  
*   [Prototype](https://en.wikipedia.org/wiki/Prototype_pattern "Prototype pattern") creates objects by cloning an existing object.  
*   [Singleton](https://en.wikipedia.org/wiki/Singleton_pattern "Singleton pattern") restricts object creation for a class to only one instance.  

**Structural**:These concern class and object composition. They use inheritance to compose interfaces and define ways to compose objects to obtain new functionality.  

*   [Adapter](https://en.wikipedia.org/wiki/Adapter_pattern "Adapter pattern") allows classes with incompatible interfaces to work together by wrapping its own interface around that of an already existing class.  
*   [Bridge](https://en.wikipedia.org/wiki/Bridge_pattern "Bridge pattern") decouples an abstraction from its implementation so that the two can vary independently.  
*   [Composite](https://en.wikipedia.org/wiki/Composite_pattern "Composite pattern") composes zero-or-more similar objects so that they can be manipulated as one object.  
*   [Decorator](https://en.wikipedia.org/wiki/Decorator_pattern "Decorator pattern") dynamically adds/overrides behaviour in an existing method of an object.  
*   [Facade](https://en.wikipedia.org/wiki/Facade_pattern "Facade pattern") provides a simplified interface to a large body of code.  
*   [Flyweight](https://en.wikipedia.org/wiki/Flyweight_pattern "Flyweight pattern") reduces the cost of creating and manipulating a large number of similar objects.  
*   [Proxy](https://en.wikipedia.org/wiki/Proxy_pattern "Proxy pattern") provides a placeholder for another object to control access, reduce cost, and reduce complexity.  

**Behavioral**: Most of these design patterns are specifically concerned with communication between **objects**.  

*   [Chain of responsibility](https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern "Chain-of-responsibility pattern") delegates commands to a chain of processing objects.  
*   [Command](https://en.wikipedia.org/wiki/Command_pattern "Command pattern") creates objects which encapsulate actions and parameters.  
*   [Interpreter](https://en.wikipedia.org/wiki/Interpreter_pattern "Interpreter pattern") implements a specialized language.  
*   [Iterator](https://en.wikipedia.org/wiki/Iterator_pattern "Iterator pattern") accesses the elements of an object sequentially without exposing its underlying representation.  
*   [Mediator](https://en.wikipedia.org/wiki/Mediator_pattern "Mediator pattern") allows [loose coupling](https://en.wikipedia.org/wiki/Loose_coupling "Loose coupling") between classes by being the only class that has detailed knowledge of their methods.  
*   [Memento](https://en.wikipedia.org/wiki/Memento_pattern "Memento pattern") provides the ability to restore an object to its previous state (undo).  
*   [Observer](https://en.wikipedia.org/wiki/Observer_pattern "Observer pattern") is a publish/subscribe pattern which allows a number of observer objects to see an event.  
*   [State](https://en.wikipedia.org/wiki/State_pattern "State pattern") allows an object to alter its behavior when its internal state changes.  
*   [Strategy](https://en.wikipedia.org/wiki/Strategy_pattern "Strategy pattern") allows one of a family of algorithms to be selected on-the-fly at runtime.  
*   [Template method](https://en.wikipedia.org/wiki/Template_method_pattern "Template method pattern") defines the skeleton of an algorithm as an abstract class, allowing its subclasses to provide concrete behavior.  
*   [Visitor](https://en.wikipedia.org/wiki/Visitor_pattern "Visitor pattern") separates an algorithm from an object structure by moving the hierarchy of methods into one object.  

-[Hexagonal architecture](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)):  It aims at creating loosely coupled application components that can be easily connected to their software environment by means of ports and adapters

-[Orthogonality](https://www.jasoncoffin.com/cohesion-and-coupling-principles-of-orthogonal-object-oriented-programming/)is the union of the principles [Cohesion](https://en.wikipedia.org/wiki/Cohesion_(computer_science)) and [Coupling](https://en.wikipedia.org/wiki/Coupling_(computer_programming)): In mathematics, orthogonality describes the property two vectors have when they are perpendicular to each other. Each vector will advance indefinitely into space, never to intersect. Well designed software is orthogonal  


#### [-Non-Functional Requirements=Service Level Agreement=quality of service (QoS)](https://en.wikipedia.org/wiki/Non-functional_requirement)  
*   [Functional Requirements vs Non Functional Requirements](https://www.guru99.com/functional-vs-non-functional-requirements.html)
*   [Architecting For The -ilities](https://towardsdatascience.com/architecting-for-the-ilities-6fae9d00bf6b)
*   [Non-Functional Requirements from SCEA](https://www.informit.com/articles/article.aspx?p=29030&seqNum=5)  
    - Performance: measured in terms of response time for a given screen transaction per user. In addition to response time, performance can also be measured in transaction throughput, which is the number of transactions in a given time period, usually one second.  
    
    - Scalability: is the ability to support the required quality of service as the system load increases without changing the system. A system can be considered scalable if, as the load increases, the system still responds within the acceptable limits.  
    
    - Reliability: ensures the integrity and consistency of the application and all its transactions. As the load increases on your system, your system must continue to process requests and handle transactions as accurately as it did before the load increased. Reliability can have a negative impact on scalability.  
    
    - Availability: ensures that a service/resource is always accessible. Reliability can contribute to availability, but availability can be achieved even if components fail.  
    
    - Extensibility: is the ability to add additional functionality or modify existing functionality without impacting existing system functionality.  
    
    - Maintainability: is the ability to correct flaws in the existing functionality without impacting other components of the system.  
    
    - Manageability: is the ability to manage the system to ensure the continued health of a system with respect to scalability, reliability, availability, performance, and security.  
    
    - Security: is the ability to ensure that the system cannot be compromised. Security is by far the most difficult systemic quality to address. Security includes not only issues of confidentiality and integrity, but also relates to Denial-of-Service (DoS) attacks that impact availability.  
    

-[Single Point Of Failure](https://en.wikipedia.org/wiki/Single_point_of_failure): It is a part of a system that, if it fails, will stop the entire system from working

-[Memoization](https://en.wikipedia.org/wiki/Memoization): It is an optimization technique used primarily to speed up computer programs by storing the results of expensive function calls and returning the cached result when the same inputs occur again

-[Linux Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy): Do One Thing and Do It Well - [The designs of today's Linux systems are "diametrically opposed" to the UNIX philosophy](https://www.reddit.com/r/linux/comments/16ygjy/the_designs_of_todays_linux_systems_are/)

-[Software craftsmanship](https://en.wikipedia.org/wiki/Software_craftsmanship):

is GOTO legitimate or not (https://stackoverflow.com/questions/46586/goto-still-considered-harmful) : famous Djistra article "The goto statement considered harmful" (https://dl.acm.org/doi/10.1145/362929.362947)   -> !Gotos are good when they add clearity. If you have a long nested loop, it can be better to goto out of it than setting "break" variables and breaking until you get out.", "There is one thing clearly worse than using goto: hacking structured programming tools together to implement a goto."


#### [-CODE SMELLS from book REFACTORING](http://www.laputan.org/pub/patterns/fowler/smells.pdf)
*   Duplicated code
*   Long Method
*   Large Classes
*   Long Parameter List
*   Divergent Change
*   Shotgun Surgery
*   Feature Envy
*   Data Clumps
*   Primitive Obsession
*   Switch Statements
*   Parallel Inheritance Hierarchies
*   Lazy Class
*   Speculative Generality
*   Temporary Field
*   Message Chain
*   Middle Man
*   Inappropriate Intimacy
*   Alternative Classes with Different Interfaces
*   Incomplete Library Class
*   Data Class
*   Refused Bequest
*   Comments

### [REST]





idempotent and PUT (don't user POST to create/update): https://stackoverflow.com/questions/611906/http-post-with-url-query-parameters-good-idea-or-not  =>

If your action is not idempotent, then you MUST use POST. If you don't, you're just asking for trouble down the line. GET, PUT and DELETE methods are required to be idempotent. Imagine what would happen in your application if the client was pre-fetching every possible GET request for your service – if this would cause side effects visible to the client, then something's wrong.

I agree that sending a POST with a query string but without a body seems odd, but I think it can be appropriate in some situations.

Think of the query part of a URL as a command to the resource to limit the scope of the current request. Typically, query strings are used to sort or filter a GET request (like ?page=1&sort=title) but I suppose it makes sense on a POST to also limit the scope (perhaps like ?action=delete&id=5).






* [*The Clean Architecture*](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html)
* [*Clean Code Cheat Sheet*](https://www.planetgeek.ch/wp-content/uploads/2014/11/Clean-Code-V2.4.pdf)
* [*One key abstraction*](http://wiki3.cosc.canterbury.ac.nz/index.php/One_key_abstraction)
* [*Aspect-oriented programming*](https://en.wikipedia.org/wiki/Aspect-oriented_programming)
* [*The Twelve-Factor App*](http://12factor.net)
* [*Domain-driven design*](https://en.wikipedia.org/wiki/Domain-driven_design)
* [*Microservices*](https://en.wikipedia.org/wiki/Microservices) are a style of software architecture that involves delivering systems as a set of very small, granular, independent collaborating services. 
  * Pros of *microservices* (The services are easy to replace, Services can be implemented using different programming languages, databases, hardware and software environment, depending on what fits best)
* *Design patterns*.
  * **Creational**: [*Builder*](https://refactoring.guru/design-patterns/builder), [*Object Pool*](https://en.wikipedia.org/wiki/Object_pool_pattern), [*Factory Method*](https://refactoring.guru/design-patterns/factory-method), [*Singleton*](https://refactoring.guru/design-patterns/singleton), [*Multiton*](https://en.wikipedia.org/wiki/Multiton_pattern), [*Prototype*](https://refactoring.guru/design-patterns/prototype), [*Abstract Factory*](https://refactoring.guru/design-patterns/abstract-factory)
   * **Structural**: [*Adapter*](https://refactoring.guru/design-patterns/adapter), [*Bridge*](https://refactoring.guru/design-patterns/bridge), [*Composite*](https://refactoring.guru/design-patterns/composite), [*Decorator*](https://refactoring.guru/design-patterns/decorator), [*Facade*](https://refactoring.guru/design-patterns/facade), [*Flyweight*](https://refactoring.guru/design-patterns/flyweight), [*Proxy*](https://refactoring.guru/design-patterns/proxy)
   * **Behavioral**: [*Chain of Responsibility*](https://refactoring.guru/design-patterns/chain-of-responsibility), [*Command*](https://refactoring.guru/design-patterns/command), [*Interpreter*](https://en.wikipedia.org/wiki/Interpreter_pattern), [*Iterator*](https://refactoring.guru/design-patterns/iterator), [*Mediator*](https://refactoring.guru/design-patterns/mediator), [*Memento*](https://refactoring.guru/design-patterns/memento), [*Observer*](https://refactoring.guru/design-patterns/observer), [*State*](https://refactoring.guru/design-patterns/state), [*Strategy*](https://refactoring.guru/design-patterns/strategy), [*Template Method*](https://refactoring.guru/design-patterns/template-method), [*Visitor*](https://refactoring.guru/design-patterns/visitor)
* [*Enterprise integration patterns*](https://en.wikipedia.org/wiki/Enterprise_Integration_Patterns), [*SOA patterns*](www.soapatterns.org).
* [*3-tier architecture*](https://en.wikipedia.org/wiki/Multitier_architecture) (Presentation tier, Application tier, Data tier)
* *3-layer architecture* (DAO (Repository), Business (Service) layer, Controller)
* [*REST*](https://en.wikipedia.org/wiki/Representational_state_transfer) (Representational state transfer), [*RPC*](https://en.wikipedia.org/wiki/Remote_procedure_call)
* [*Idempotent operation*](https://en.wikipedia.org/wiki/Idempotence) (The PUT and DELETE methods are referred to as idempotent, meaning that the operation will produce the same result no matter how many times it is repeated)
* *Nullipotent operation* (GET method is a safe method (or nullipotent), meaning that calling it produces no side-effects)
* [*Naked objects*](https://en.wikipedia.org/wiki/Naked_objects), [*Restful objects*](https://en.wikipedia.org/wiki/Restful_Objects).
* Why do you need *web server* (tomcat, jetty)?
* [*Inheritance*](https://en.wikipedia.org/wiki/Inheritance_(object-oriented_programming)) vs [*Composition*](https://en.wikipedia.org/wiki/Object_composition) (Inheritance - is-a relationship, whether clients will want to use the subclass type as a superclass type. Composition - has-a or part-of relationship).
* [*Multiple inheritance (diamond) problem*](https://en.wikipedia.org/wiki/Multiple_inheritance#The_diamond_problem)
* Advantages of using *modules*. (reuse, decoupling, namespace)
* Drawbacks of not using [*separation of concerns*](https://en.wikipedia.org/wiki/Separation_of_concerns)
  * Adding new features will take an order of magnitude longer
  * Impossible to optimize
  * Extremely difficult to test
  * Fixing and debugging can be a nightmare (fixing something in one place can lead to something else breaking that seems completely unrelated).
* What is [*uniform access principle*](https://en.wikipedia.org/wiki/Uniform_access_principle)? (client code should not be affected by a decision to implement an attribute as a field or method)
* [Conway's law](https://en.wikipedia.org/wiki/Conway%27s_law) (organizations which design systems ... are constrained to produce designs which are copies of the communication structures of these organizations)
* [GRASP](https://en.wikipedia.org/wiki/GRASP_(object-oriented_design))




* [*Polymorphism*](https://en.wikipedia.org/wiki/Polymorphism_(computer_science)) (Variable of type Shape could refer to an object of type Square, Circle... Ability of a function to handle objects of many types)
* [*Encapsulation*](https://en.wikipedia.org/wiki/Encapsulation_(computer_programming)) (Packing of data and functions into a single component)
* [*Virtual function*](https://en.wikipedia.org/wiki/Virtual_function) (Overridable function)
* [*Virtual method table*](https://en.wikipedia.org/wiki/Virtual_method_table)
* [*Dynamic binding*](https://en.wikipedia.org/wiki/Late_binding) (Actual method implementation invoked is determined at run time based on the class of the object, not the type of the variable or expression)
* How does [*garbage collector*](https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) work? (Mark and sweep: mark: traverse object graph starting from root objects, sweep: garbage collect unmarked objects. Optimizations: young/old generations, incremental mark and sweep)
* [*Tail recursion*](https://en.wikipedia.org/wiki/Tail_call) (A tail call is a subroutine call performed as the final action of a procedure)
* [*Semantic versioning*](http://semver.org)

-[Backpressure](https://medium.com/@jayphelps/backpressure-explained-the-flow-of-data-through-software-2350b3e77ce7)

-[REST vs RESTful](https://stackoverflow.com/questions/1568834/whats-the-difference-between-rest-restful)

-[RESTful and RESTless](https://stackoverflow.com/questions/13025417/what-is-the-different-between-restful-and-restless)


-[Mechanical Sympathy](https://dzone.com/articles/mechanical-sympathy): It was coined by racing driver Jackie Stewart and applied to software by Martin Thompson ([LMAX Disruptor](https://www.baeldung.com/lmax-disruptor-concurrency)). Jackie Stewart said, “You don’t have to be an engineer to be be a racing driver, but you do have to have Mechanical Sympathy.”
* *A common meme in our industry is, “avoid pre- optimization.” I used to preach this myself. I am now very sorry that I did*
* *One of the great myths about high-performance programming is that high-performance solutions are more complex than “normal” solutions. This is just not true*

 

--------------------------------------------------------------------------------------------



Análisis de impacto	
KTP (Knowledge Transfer Process)	
Alcance = scope del proyecto	definir lo que entra en el trabajo acordado y lo que queda fuera
Puesta en Marcha = release	
 Baseline = version	
OWASP	
PKI	
ortogonal	
Normalizar / Desnormalizar / Formas normales	
Pruebas de regresion	
Test unitario  / Regresion	
metodos: ¿ Un solo punto de salida o varios ?	
A Team	
explotacion	
Idempotente (HTTP Get should be idempotent. What does this mean?)	tiene que ver con REST, que utiliza los verbos del protocolo HTTP para hacer operaciones "GET" coger datos, "PUT" guardar,…, pues bien, que sea idempotente significa que dos GET seguidos deben devolver el mismo resultado, esto se consigue al hacer que una operacion GET NUNCA cambie ningun estado.
Principio YAGNI	
SOLID	
decalaje	retraso, decalaje de 1 dia
Cadena de transferencia	
Automata	
agile	
scrum	
Plan de pruebas	
Plan de Supervision	
Ciclo de vida Mercadona	Inicialmente se aborda una mejoransdfds sfdds
Mejora	
EAC / EFC	
tablas maestras	
prefijo de la app en nombre de tablas,…	Asi se evitan colisiones de nombre en las queries entre distintos esquemas, bbdd..
erwin/powerdesigner/ e/R studio	herramientas lideres de modelado de datos
tener caudal	
PostgreSQL  / oracle / mysql / h2	RDBMS mas populares
regla 80/20	
crear FK  y deshabilitarla	en general va bien crear FK, pero a veces no conviene o no se quiere, pero en este caso es mejor crearla y desahibilitarla ¿Por qué? Porque le da informacion a oracle y es MAS RAPIDO (comprobado por pruebas realizadas)
plano (conceptual / logico…)	diagrama
pctree,initran	parametros de una tabla
estrategia espejo en tablas	se trata de tener dos tablas espejo y se va cambiando el sinonimo para evitar problemas de indisponibilidad por actualizacion refresco.
defecto	error 
OID / OHS (balanceo)	
internet of things	
aws = amazon web services	
docker architecture	
tamaño A3, A4	formula matematica
algoritmo de TOMASULO	para  procesadores 
informe AWR de performance	
magnitudes de carga "normal", que nodos de WebLogic y cuanta memoria hace falta para atender n peticiones simultaneas "normalitas", cuello de la BBDD?...	
Arquitectura tipica de una aplicación web, por ejemplo teletienda, DMZ, nodos, potencia de cada nodo, etc…	
corporate governance -> subtipo = IT Governance -> subtipo = SOA governance	
HTML 5 y websocket 	
NOSQL	
JSON	
QCC	
24x7 QoS, el portal es 24x7 alta disponibilidad	
batch vs web service para enviar datos: el batch tiene la ventaja que se puede relanzar	
cuando se utilizan dates, es mejor calcularla y pasarla a las queries desde java o en la propia query como sysdate ?	
model (oracle sql stament), muy potente!!!	
SQL Antipatterns (libro de Bill Karwin)	
update or insert  comando muy utilizado se puede hacer en oracle con merge (ConstantesDAO.INCREMENTA_NUMERO_ACCESOS_DENEGADOS)	
aprovisionar	
![image](https://github.com/user-attachments/assets/4f9240b8-f197-40df-ae31-9f99daf90d27)

