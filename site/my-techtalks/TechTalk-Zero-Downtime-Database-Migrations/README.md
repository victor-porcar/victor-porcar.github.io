# TechTalk: Zero-Downtime Database Migrations[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Zero-Downtime-Database-Migrations/README.md)

We deploy without downtime, with a rolling update that replaces instances one by one. Then somebody renames a column and the whole thing falls apart. This talk is about why, and about the technique that fixes it.

The tool in the examples is [Flyway](https://documentation.red-gate.com/fd), but everything applies identically to Liquibase.

 - [Introduction](#introduction)
 - [The moment nobody thinks about](#the-moment-nobody-thinks-about)
 - [Expand and contract](#expand-and-contract)
 - [A rename, step by step](#a-rename-step-by-step)
 - [The DDL that locks the table](#the-ddl-that-locks-the-table)
 - [Backfilling a large table](#backfilling-a-large-table)
 - [Good practices](#good-practices)
 - [Appendix: a catalogue of changes](#appendix-a-catalogue-of-changes)

<br/>

## Introduction

We did the work. The service is stateless, it runs in Kubernetes, and a deploy replaces pods gradually without dropping a request. We are proud of it.

And yet every schema change still ends up in a maintenance window at three in the morning.

The reason is a contradiction we never resolved: **we deploy the application gradually and the database all at once.** The application tolerates two versions living together, because that is what rolling means. The schema does not - a migration runs once, and the instant it finishes, the old version of the application is talking to a schema it does not know.

## The moment nobody thinks about

Let's suppose we want to rename `CAR.PLATE` to `CAR.PLATE_NUMBER`. The obvious migration:

```sql
ALTER TABLE car RENAME COLUMN plate TO plate_number;
```

and the code is updated to match. Deploy, and:

```
                  migration runs here
                         |
  v1 v1 v1 v1 ───────────┼──────────── v1 v1  ← still running, still querying PLATE
                         |
              v2 ────────┼──────────── v2 v2  ← querying PLATE_NUMBER
```

Between the migration and the last old pod being replaced there is a window - **seconds or minutes, and it is enough** - in which version 1 instances are querying a column that no longer exists. Every one of their requests fails.

And it is worse than it looks, because **the rollback is also broken**. If v2 has a bug and we roll back, we return to a version that queries `PLATE` against a schema that has `PLATE_NUMBER`. We are trapped: forward is broken and backward is broken.

The rule this leads to is the whole talk in one line:

> **every schema change must be compatible with the version of the application that is already running**

Not with the one we are deploying. With the one that is **already there**.

## Expand and contract

The technique - also called *parallel change* - is to split every incompatible change into **three deployments** that are each individually compatible.

*   **Expand**: add the new thing. The schema now supports the old and the new version at once. Nothing is removed

*   **Migrate**: move the data and move the readers. The application writes to both, reads from the new

*   **Contract**: remove the old thing, once we are sure nobody uses it

Each step is a separate deployment, and each one is **backwards compatible on its own**. That is the property that makes it safe - and yes, it means a rename is three releases instead of one. That is the actual price, and it is cheaper than a maintenance window and much cheaper than an incident with no way back.

## A rename, step by step

The same rename, done properly.

**Release 1 - expand.** Migration:

```sql
ALTER TABLE car ADD COLUMN plate_number VARCHAR(16);
```

Code: writes to **both** columns, reads from the old one.

```java
public void save(Car car) {
    car.setPlate(car.getPlateNumber());          // old column, still the source of truth
    car.setPlateNumber(car.getPlateNumber());    // new column, being populated
    repository.save(car);
}
```

A v1 instance that knows nothing about `plate_number` keeps working perfectly: the column is nullable and it simply ignores it.

**Release 2 - migrate.** Backfill the existing rows:

```sql
UPDATE car SET plate_number = plate WHERE plate_number IS NULL;
```

Code: still writes to both, but now **reads from the new column**. If something is wrong, the rollback to release 1 works, because release 1 was writing both columns all along.

**Release 3 - contract.** Now, and only now:

```sql
ALTER TABLE car DROP COLUMN plate;
```

Code: writes and reads only `plate_number`.

Three releases. At no point does a running instance find a schema it does not understand, and at every point the previous release is a valid rollback target.

## The DDL that locks the table

The second way to cause downtime without noticing: a migration that is perfectly compatible but **locks the table for four minutes** while ten million rows are rewritten.

The application does not fail. It just stops, waiting for a lock. Which, from the user's point of view, is the same thing.

What matters is which statements rewrite the table and which only change metadata, and this **depends on the engine and the version**. Two that are worth knowing for PostgreSQL:

*   `ALTER TABLE ... ADD COLUMN ... DEFAULT x` used to rewrite the whole table. **Since PostgreSQL 11 it does not** - the default is stored as metadata. On older versions, and on other engines, the safe form is still: add the column nullable, backfill in batches, then set the default

*   `CREATE INDEX` locks the table against writes for the entire build. **`CREATE INDEX CONCURRENTLY` does not**, at the price of being slower and of being able to fail leaving an invalid index behind, which then has to be dropped and rebuilt

```sql
CREATE INDEX CONCURRENTLY idx_car_plate_number ON car (plate_number);
```

Rule of thumb: **a migration that takes longer than a couple of seconds on the production table is an incident, not a migration**. And the only way to know how long it takes is to run it against a copy with production volume. Never against the 400 rows in our local database.

## Backfilling a large table

`UPDATE car SET plate_number = plate` on ten million rows is a single transaction that locks rows, inflates the WAL and can run for an hour.

In batches:

```sql
UPDATE car
   SET plate_number = plate
 WHERE id IN (SELECT id FROM car WHERE plate_number IS NULL LIMIT 5000);
```

repeated until it affects zero rows, committing between batches.

This usually does **not** belong in a Flyway migration: a migration blocks the application's startup, and a backfill that takes two hours means pods that never become ready and a deployment that Kubernetes eventually gives up on. The backfill belongs in a **job** that runs separately, while the application keeps working - which it can, because in release 1 the code writes both columns.

That is the real reason the dual-write step exists: it decouples the data migration from the deployment.

## Good practices

### AntiPattern: editing a migration that has already run

Avoid this. A migration that ran in production has its checksum recorded, and changing the file makes Flyway fail on startup with a validation error. The temptation then is `flyway.repair`, or `baselineOnMigrate`, or deleting the row from `flyway_schema_history`.

All three are ways of telling the tool to stop checking the one thing it exists to check. And the schemas of the different environments quietly drift apart until nobody knows what production actually looks like.

**A migration is immutable.** If it is wrong, the fix is a new migration that corrects it. Always forward.

### Never `DROP` in the same release that stops using something

The drop is the contract step and it deserves its own release, once we are **sure** nobody uses it. And "sure" means measured, not assumed: an old instance somewhere, a report, a batch job that runs monthly.

Rule of thumb: **between stopping using a column and dropping it, let at least one full release cycle pass.** The disk it occupies is much cheaper than recovering it from a backup.

### Test the rollback, not just the migration

Everybody tests that the migration runs. Almost nobody tests that, after the migration, **the previous version of the application still works**.

That is the test that actually matters, and it is exactly the scenario of the rolling deploy. With Testcontainers it is mechanical: raise the schema at version N, run the test suite of the application at version N-1.

### Beware of Hibernate `ddl-auto`

```properties
spring.jpa.hibernate.ddl-auto=update
```

This has no place anywhere near production. It generates whatever DDL it feels like, at startup, with no review, no version and no rollback, and it will happily do it differently on each instance of a rolling deploy.

In production, `validate`. The schema is owned by the migrations, and Hibernate's job is to complain if what it finds is not what it expects.

### One logical change per migration

A migration that adds a table, alters two columns and creates three indexes is a migration that can fail halfway through. Some engines do not do transactional DDL, so *halfway through* is a real state we will have to untangle by hand at a bad moment.

Small migrations, one intent each, applied in order.

## Appendix: a catalogue of changes

| Change | Safe? | How to do it |
|---|---|---|
| Add a nullable column | yes | direct |
| Add a `NOT NULL` column | **no** | add nullable, backfill, then add the constraint |
| Drop a column | **no** | stop using it, wait a release, then drop |
| Rename a column | **no** | expand / contract, three releases |
| Change a type | **no** | new column, dual write, migrate, drop the old |
| Add an index | careful | `CONCURRENTLY`, or a window on a small table |
| Add a `FOREIGN KEY` | careful | `NOT VALID` first, then `VALIDATE CONSTRAINT` |
| Add a table | yes | direct |
| Drop a table | **no** | same as dropping a column |

The pattern in that table is worth naming: **adding is safe, removing and modifying are not**. Which is the same principle as versioning an API, and the same one behind the rolling deploy in the [Kubernetes](../TechTalk-Introduction-to-Kubernetes) talk. It is all the same rule - two versions have to coexist - applied to three different things.
