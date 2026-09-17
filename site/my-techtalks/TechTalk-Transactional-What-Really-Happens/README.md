# TechTalk: @Transactional - What Really Happens[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Transactional-What-Really-Happens/README.md)

`@Transactional` is the annotation we write most and understand least. It is also the one that produces the most production bugs, because when it does not work it **does not fail** - it simply does nothing, silently.

The reference documentation is [here](https://docs.spring.io/spring-framework/reference/data-access/transaction.html)

 - [Introduction](#introduction)
 - [It is a proxy, and everything follows from that](#it-is-a-proxy-and-everything-follows-from-that)
 - [The rollback that did not happen](#the-rollback-that-did-not-happen)
 - [Propagation](#propagation)
 - [A transaction is a connection](#a-transaction-is-a-connection)
 - [readOnly is not documentation](#readonly-is-not-documentation)
 - [Publishing events after the commit](#publishing-events-after-the-commit)
 - [Good practices](#good-practices)
 - [Appendix: how to see what is going on](#appendix-how-to-see-what-is-going-on)

<br/>

## Introduction

We write `@Transactional` on a method and assume a transaction exists. Most of the time that is true. The interesting cases are the ones where it is not, and in every one of them the symptom is the same: **no error, no log, and data that should have been rolled back is committed**.

All of them come from one fact that is easy to forget.

## It is a proxy, and everything follows from that

Spring does not modify our class. It creates a **proxy** that wraps it: the proxy opens the transaction, calls our method, and commits or rolls back.

```
   caller ──→ [ proxy ] ──→ our bean
                  |
          begin / commit / rollback
```

Everything below is a consequence of this one diagram.

**Self-invocation does not work.** This is the classic, and it is worth staring at:

```java
@Service
public class CarService {

    public void importAll(List<CarDto> cars) {
        for (CarDto dto : cars) {
            save(dto);          // ← direct call: does NOT go through the proxy
        }
    }

    @Transactional
    public void save(CarDto dto) {
        repository.save(toEntity(dto));
    }
}
```

`save` is called through `this`, not through the proxy. **There is no transaction.** No error, no warning: it simply runs without one, and whether it happens to work depends on the driver's autocommit.

The fix is to cross a proxy boundary - normally by moving the transactional method to another bean, which also usually improves the design.

**A `private` method is never transactional.** The proxy cannot intercept it. Same with `final` methods and `final` classes when the proxy is a CGLIB subclass. The annotation is accepted, nothing complains, and it does nothing.

Rule of thumb: **`@Transactional` only works on a public method, called from outside the bean.** Every other case is decoration.

## The rollback that did not happen

The second silent surprise:

```java
@Transactional
public void register(Car car) throws BusinessException {
    repository.save(car);
    if (isDuplicate(car)) {
        throw new BusinessException("duplicated plate");   // checked exception
    }
}
```

The car is **saved**. The exception propagates, the caller handles it, and the row is in the database.

Because Spring's default is to roll back on **`RuntimeException` and `Error` only**. A checked exception commits.

The reason is historical - it mirrors EJB - and it does not matter. What matters is that it does not match what anybody expects, and that the code above looks entirely correct.

Two ways out:

```java
@Transactional(rollbackFor = BusinessException.class)
```

or, better in most codebases, make business exceptions unchecked, which is also what the [Logging Policy](../TechTalk-Logging-Policy) talk recommends for a different reason.

And a related trap: **catching the exception cancels the rollback**.

```java
@Transactional
public void register(Car car) {
    try {
        repository.save(car);
        validate(car);                    // throws
    } catch (ValidationException e) {
        log.error("invalid car", e);      // swallowed: the transaction commits
    }
}
```

If we handle it and do not rethrow, the proxy never sees anything wrong and commits. This is the *log and throw* antipattern's quieter cousin: **log and swallow, inside a transaction**.

Worth knowing: once an inner transactional method has failed, the transaction is often already marked `rollbackOnly`. Then catching the exception does not save us either - the commit fails at the end with `UnexpectedRollbackException`, far from where the real problem was.

## Propagation

The default, `REQUIRED`, is almost always right: join the existing transaction, or create one if there is none.

The one that deserves a warning is `REQUIRES_NEW`:

```java
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void auditAttempt(String plate) { ... }
```

It suspends the current transaction and opens a **new one, on a different connection**. Which means:

*   we are now holding **two connections** for one request. With a pool of 10 and 10 concurrent requests inside a `REQUIRES_NEW`, every connection is taken and the inner call waits for a connection that only an outer transaction can release. That is a **self-inflicted deadlock**, and it shows up under load, never in testing

*   the inner transaction **cannot see** the uncommitted changes of the outer one, which surprises people who use it for auditing

It has legitimate uses - writing an audit record that must survive a rollback is the canonical one. It is just not a free annotation.

`NESTED` is rarer and depends on savepoint support in the driver. `MANDATORY` is genuinely useful for a method that must never start its own transaction: it fails loudly if there is none, which is much better than silently working without one.

## A transaction is a connection

This is the framing that prevents most performance problems:

> an open transaction is a **connection held from the pool**, from `begin` to `commit`

So the duration of a transaction is not an abstract concern. It is the time a scarce resource is unavailable to everybody else. A pool of 10 connections and transactions that last 500 ms gives a hard ceiling of 20 transactions per second.

Which leads directly to the worst thing we can do inside one:

```java
@Transactional
public void register(Car car) {
    repository.save(car);
    pricingClient.notify(car);     // ← HTTP call, inside the transaction
    repository.updateStatus(car);
}
```

If the pricing service takes 30 seconds, we hold a database connection for 30 seconds. Ten concurrent requests and the pool is gone - the exact cascading failure described in the [Resilience](../TechTalk-Resilience-Patterns) talk, except the resource being exhausted is the connection pool rather than the thread pool.

Rule of thumb: **no remote calls inside a transaction.** Read, close the transaction, call, open another transaction to write. And if the remote call must happen only if the commit succeeds, the mechanism is further down.

Same idea for a long computation, a file being read, or a `Thread.sleep` somebody left behind.

## readOnly is not documentation

```java
@Transactional(readOnly = true)
public List<Car> findAvailable() { ... }
```

Many people write this thinking it is a comment. It does real work:

*   Hibernate sets the flush mode to `MANUAL`, so **there is no dirty checking**. It does not take a snapshot of every loaded entity to compare it at the end, which on a query returning thousands of rows is a substantial saving in CPU and memory

*   the driver can pass the hint to the database, and some replica routing setups use it to send the query to a read replica

What it is **not** is a guarantee that nothing will be written. It is a hint, not a constraint - on some engines a write inside a `readOnly` transaction will go through.

Rule of thumb: **every read-only query method gets `readOnly = true`.** It is free and it measurably reduces the cost of large reads.

## Publishing events after the commit

A very common bug, and the fix is a single annotation.

```java
@Transactional
public void register(Car car) {
    repository.save(car);
    events.publishEvent(new CarRegistered(car.getId()));
}
```

If the listener is synchronous it runs **before the commit**. If the listener is asynchronous, it may run on another thread and query the database for a row that **has not been committed yet** - so it finds nothing, intermittently, and only under load. And if the transaction then rolls back, we have already published an event about something that never happened.

```java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
public void onCarRegistered(CarRegistered event) {
    searchIndex.add(event.carId());
}
```

`AFTER_COMMIT` guarantees the listener runs once the data is really there.

Worth being honest about the limit: this is not the same as a **transactional outbox**. If the process dies between the commit and the listener, the event is lost. For an event that absolutely cannot be lost, it has to be written to the database inside the same transaction and published by a separate reader.

## Good practices

### Put it on the service, not the repository

Each Spring Data repository method is already transactional on its own. If our transaction boundary is a repository method, then saving two entities in one business operation is **two transactions**, and half the operation can commit.

The boundary should be the **business operation**, which lives in the service layer.

### AntiPattern: `@Transactional` on the controller

The transaction then covers request deserialization, validation, response serialization and whatever the view layer does. The connection is held for all of it, for no reason, and a serialization failure rolls back work that was perfectly valid.

The controller orchestrates. The service owns the transaction.

### Keep them short

Everything above reduces to this. A transaction should contain the database operations that must be atomic, and nothing else. No HTTP calls, no file I/O, no heavy computation, no waiting.

### Beware of LazyInitializationException

Not strictly transactional, but it always appears in the same conversation. If a transactional method returns an entity with lazy relations and the controller serializes it, the session is already closed and the serializer explodes.

The fix is not `open-in-view` - which is enabled by default in Spring Boot and is worth turning off, because it silently keeps a connection open for the whole request, going directly against the previous point. The fix is to **return a DTO with what we actually need**, loaded inside the transaction.

```properties
spring.jpa.open-in-view=false
```

### Test the rollback

Same argument as always: an untested path does not work. A test that provokes the failure and asserts that **nothing was written** is the only way to know that the annotation is doing what we think it is. Given how many of the cases above fail silently, this is not optional.

## Appendix: how to see what is going on

The fastest way to settle an argument about whether there is a transaction:

```properties
logging.level.org.springframework.transaction.interceptor=TRACE
logging.level.org.springframework.orm.jpa.JpaTransactionManager=DEBUG
logging.level.org.hibernate.SQL=DEBUG
```

The first one logs every transaction the proxy opens and closes, with the method name. If our method is not in that log, **there is no transaction** - and that immediately tells us we are in a self-invocation, a private method or a missing proxy.

Programmatically, inside the code:

```java
boolean active = TransactionSynchronizationManager.isActualTransactionActive();
String name = TransactionSynchronizationManager.getCurrentTransactionName();
```

And in an already running application, without restarting it and without adding logs, the [Arthas](../TechTalk-Arthas-Tool) talk covers exactly this: intercepting a method to see whether it is called through the proxy, and what it receives and returns.
