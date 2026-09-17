# TechTalk: Virtual Threads vs Reactive[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Virtual-Threads-vs-Reactive/README.md)

Virtual threads arrived as a final feature in **Java 21**, and they invalidate the main argument we used to justify reactive programming. This talk is about what exactly they invalidate, and what they do not.

It is the natural continuation of the [Reactive programming in WebFlux](../TechTalk-Reactive-Programming-and-WebFlux) talk. The JEP is [here](https://openjdk.org/jeps/444)

 - [Introduction](#introduction)
 - [The problem we were actually solving](#the-problem-we-were-actually-solving)
 - [What a virtual thread is](#what-a-virtual-thread-is)
 - [Using them](#using-them)
 - [What virtual threads do NOT solve](#what-virtual-threads-do-not-solve)
 - [So which one do we choose?](#so-which-one-do-we-choose)
 - [Good practices](#good-practices)
 - [Appendix: pinning](#appendix-pinning)

<br/>

## Introduction

Let's start by being honest about why we adopted reactive programming.

It was not because the API was nicer. `flatMap`, `zipWith` and an unreadable stack trace are not nicer than a `for` loop. We adopted it because of **one specific problem**, and it is worth stating it precisely, because that is the only way to judge whether the solution is still needed.

## The problem we were actually solving

A platform thread in Java is a **thin wrapper over an operating system thread**. That means:

*   it costs around **1 MB of stack**, reserved

*   creating one is a system call, which is expensive

*   switching between them goes through the kernel scheduler

So we never create them on demand: we keep a **pool**. And here is the problem, in one sentence:

> in the classic model, a thread is **blocked and useless** for the entire duration of an I/O call

Let's suppose a service with a pool of 200 threads whose job is to call another service that takes 100 ms. Those 200 threads spend 100 ms doing **nothing at all**, just waiting for a socket. Our throughput ceiling is 200 / 0.1 = **2000 requests per second**, and no amount of CPU will change it. The CPU is idle. We are limited by an accounting problem.

Reactive programming solved this by **never blocking**: the thread registers a callback and moves on to another request. A handful of threads can serve thousands of concurrent requests.

It worked. And the price we paid was enormous:

*   **the whole stack has to be reactive**. One blocking JDBC driver in the middle and the benefit evaporates

*   we lost the **stack trace**, the debugger and the profiler, because the logical flow is no longer the call stack

*   `ThreadLocal` stopped working, and with it everything built on it, which in an enterprise application is a lot: security context, transactions, tracing

*   the code stopped reading like the business logic it implements

## What a virtual thread is

A virtual thread is a thread **managed by the JVM, not by the operating system**. Thousands of them are multiplexed over a small pool of platform threads, called **carrier threads**.

The mechanism is the only thing that matters, and it is simple: when a virtual thread performs a blocking operation, the JVM **unmounts** it from its carrier thread, saves its stack on the heap, and lets the carrier run another virtual thread. When the I/O completes, the virtual thread is mounted again, possibly on a different carrier.

The consequence is the sentence that changes everything:

> **blocking a virtual thread does not block an operating system thread**

So the accounting problem disappears. We can have a million virtual threads. They cost a few hundred bytes each, they grow on demand, and creating one is cheaper than fetching an object from a pool.

And, crucially, **it is still a `Thread`**. The stack trace is real. The debugger works. `ThreadLocal` works. The code is sequential, blocking, boring code - the code we know how to write, read and debug.

## Using them

In Spring Boot 3.2 and later, one property:

```properties
spring.threads.virtual.enabled=true
```

That is genuinely all. Tomcat serves each request on a virtual thread, and our existing blocking controller, with its blocking JDBC call, stops being limited by the thread pool.

Directly, without a framework:

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<Car>> futures = plates.stream()
            .map(plate -> executor.submit(() -> carClient.fetch(plate)))   // blocking call
            .toList();

    for (Future<Car> future : futures) {
        process(future.get());
    }
}
```

Ten thousand plates, ten thousand virtual threads, blocking calls, and it works. The same code with a platform thread pool would either exhaust memory or serialize on the pool size.

Note `newVirtualThreadPerTaskExecutor`: **one virtual thread per task**, created and discarded. Pooling them would be pointless - the pool exists to amortize a cost that no longer exists.

## What virtual threads do NOT solve

This is the part that gets skipped, and it is the reason reactive is not dead.

**They do not give us backpressure.** If our service can create a million virtual threads, it will happily accept a million concurrent requests and forward them all to a database that has 20 connections. Reactive forces us to think about the rate at which a consumer can absorb work. Virtual threads let us ignore it, right up to the moment it collapses. **The bottleneck moved, it did not disappear.**

**They do not give us composition operators.** Merging two streams, debouncing, retrying with backoff, windowing by time, cancelling a whole branch of work: all of that is what Reactor actually gives us, and it has nothing to do with threads.

**They do not help with CPU bound work.** A virtual thread only yields its carrier when it **blocks**. A tight computation loop holds the carrier exactly like a platform thread would. For CPU work, the right number of threads is still roughly the number of cores.

**They do not make a streaming API.** Server-sent events, a WebSocket pushing updates, an infinite stream of data: that is a genuinely reactive problem, and a blocking thread per subscriber is the wrong model no matter how cheap the thread is.

## So which one do we choose?

Rule of thumb:

> **virtual threads for request/response over blocking I/O, which is 90% of an enterprise application. Reactive for streams, backpressure and composition**

In more detail:

*   **new service, classic REST over a database**: virtual threads, without hesitation. The reactive complexity buys nothing here any more

*   **existing WebFlux service that works**: leave it alone. Rewriting working code to remove complexity that is already paid for is not an improvement

*   **streaming, event processing, fan out to many slow sources with cancellation**: Reactor still earns its place

*   **mixed**: perfectly legitimate. Blocking controllers on virtual threads, and Reactor only in the two components that stream

And a warning worth stating: **virtual threads make it cheap to write code that hammers a downstream service**. Which is exactly why the next talk in this list matters - see [Resilience](../TechTalk-Resilience-Patterns).

## Good practices

### AntiPattern: pooling virtual threads

Avoid this:

```java
ExecutorService executor = Executors.newFixedThreadPool(200, Thread.ofVirtual().factory());
```

This is the worst of both worlds: we reintroduced the 200 limit we were trying to remove, and we gained nothing, because the cost the pool amortizes does not exist any more.

If we want to **limit concurrency** - and often we do, to protect something downstream - the tool is a semaphore, not a pool:

```java
private final Semaphore dbGuard = new Semaphore(20);   // the pool has 20 connections

public Car fetch(String plate) throws InterruptedException {
    dbGuard.acquire();
    try {
        return carRepository.findByPlate(plate);
    } finally {
        dbGuard.release();
    }
}
```

The difference is intent: a pool limits **threads**, a semaphore limits **access to a scarce resource**. With virtual threads, threads are not the scarce resource any more. The database connection is.

### Watch the ThreadLocal

`ThreadLocal` works, but the assumption behind it changed. With a pool of 200 threads, 200 copies of whatever we stored existed. With one virtual thread per request and 50000 concurrent requests, there are 50000 copies. A heavy object in a `ThreadLocal` used to be a rounding error and is now a memory problem.

For values that are constant during a task, `ScopedValue` is the right modern tool.

### Do not chase the benchmark

Virtual threads do not make anything **faster**. A request that took 100 ms still takes 100 ms. What changes is **how many we can have in flight at once**. If our service is CPU bound, or if its bottleneck is the database, virtual threads will change exactly nothing, and measuring is the only way to know which case we are in.

### They change how we size things

With platform threads, the pool size was the implicit protection for everything downstream. That protection is gone. Connection pool limits, rate limiters and bulkheads stop being optional and become the actual mechanism that keeps the system standing.

## Appendix: pinning

A virtual thread can fail to unmount from its carrier. This is called **pinning**, and while pinned, blocking it does block a platform thread - exactly the problem we were escaping.

The two classic causes:

*   blocking inside a **`synchronized`** block

*   blocking inside a **native call** (JNI)

The first one was the serious one, because `synchronized` is everywhere, including inside old drivers and libraries. **JDK 24 removed that limitation**, so a virtual thread blocking inside `synchronized` now unmounts normally. On Java 21 and 23 it is still a real concern, and the workaround is to replace `synchronized` with a `ReentrantLock` in the paths that block.

To detect it:

```shell
java -Djdk.tracePinnedThreads=full -jar my-service.jar
```

It prints the stack trace every time a virtual thread is pinned. Worth running once against a real workload before concluding that a migration went well.

And for finding out what the JVM is really doing with all those threads at runtime, everything in the [Arthas](../TechTalk-Arthas-Tool) talk applies.
