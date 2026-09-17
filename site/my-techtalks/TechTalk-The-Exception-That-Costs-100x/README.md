# TechTalk: The Exception That Costs 100x[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-The-Exception-That-Costs-100x/README.md)

"Exceptions are slow" is one of those things everybody repeats and almost nobody has measured. It is also wrong in an interesting way: **throwing is cheap, what is expensive is capturing the stack**. And that part can be turned off.

 - [Introduction](#introduction)
 - [Where the cost actually is](#where-the-cost-actually-is)
 - [The constructor nobody uses](#the-constructor-nobody-uses)
 - [When this is legitimate, and when it is not](#when-this-is-legitimate-and-when-it-is-not)
 - [The NPE with no stack trace](#the-npe-with-no-stack-trace)
 - [Good practices](#good-practices)
 - [Appendix: measuring it properly](#appendix-measuring-it-properly)

<br/>

## Introduction

Let's suppose a service that validates incoming requests, and does it by throwing:

```java
public Car parse(String plate) {
    if (!PATTERN.matcher(plate).matches()) {
        throw new InvalidPlateException("invalid plate: " + plate);
    }
    ...
}
```

Perfectly reasonable code. Under normal traffic nobody notices anything.

Then a client starts sending malformed plates - a bad integration, a retry loop, whatever - and suddenly **the service is spending most of its CPU building exceptions that are caught two frames above and turned into an HTTP 400**.

The interesting question is why. An exception is just an object.

## Where the cost actually is

Three things happen when we throw, and their costs are wildly different:

1. **allocating the object**: the same as any other object. Nothing special
2. **unwinding the stack** to find the handler: cheap, and the JIT is good at it
3. **`fillInStackTrace()`**: a **native** call that walks the entire call stack, frame by frame, and records class, method, file and line for each one

Number three is where essentially all the cost lives, and it is called from the `Throwable` constructor - **before we have even thrown anything**.

And the crucial detail: its cost is **proportional to the depth of the stack**. In a `main` with three frames it is almost nothing. In a Spring controller, behind a filter chain, three proxies, an interceptor and a servlet container, the stack is 60 or 80 frames deep, and it has to walk all of them.

That is why the same exception is cheap in a microbenchmark and expensive in production: the benchmark does not have the stack that production has.

> **the cost of an exception is not in throwing it, it is in the depth of the stack where it is created**

## The constructor nobody uses

Since Java 7, `Throwable` has a four argument constructor:

```java
protected Throwable(String message, Throwable cause,
                    boolean enableSuppression,
                    boolean writableStackTrace)
```

With `writableStackTrace = false`, **`fillInStackTrace` is never called**. The exception has no stack trace and costs roughly what allocating a small object costs.

```java
public class InvalidPlateException extends RuntimeException {

    public InvalidPlateException(String message) {
        super(message, null, false, false);
    }
}
```

That is the whole technique. Four lines, one class, no dependencies.

The older variant, for a codebase that cannot change the constructor, is to override the method:

```java
@Override
public synchronized Throwable fillInStackTrace() {
    return this;
}
```

Same effect, and it works on Java 6. The four argument constructor is cleaner because it also disables suppression, which we are not using either.

The difference is one to two orders of magnitude, depending on stack depth. But do not take that number from here - the point of this talk is that it is easy to measure in your own stack, and the appendix shows how.

## When this is legitimate, and when it is not

This is the part that matters, because a stackless exception is a **loss of information**, and information is exactly what we want when something goes wrong.

It is legitimate when **all three** of these hold:

- the exception represents an **expected** outcome, not a failure: validation rejected, not found, parse failed, cache miss
- it is handled **close by**, by code that knows what to do with it
- the **message and the type** are enough to diagnose it - nobody will ever need to know which line threw it

The validation above qualifies: we know where it comes from, the message contains the offending plate, and it becomes a 400. A stack trace of 80 frames through Spring adds nothing at all.

It is **not** legitimate for anything unexpected. If the exception represents a bug, a failing dependency, a state that should not exist, then the stack trace is the single most valuable thing we have, and saving a few microseconds by throwing it away is a terrible trade.

Rule of thumb:

> **if you are going to log it, it needs a stack trace. If you are going to handle it, it may not**

Which lines up with the [Logging Policy](../TechTalk-Logging-Policy) talk: an `ERROR` carries the full trace, because something unexpected happened. A controlled situation that the code handles is a `WARN`, and often the message alone is the whole story.

### The next step: reusing the instance

If the exception has no stack trace and no per-case state, it does not need to be created at all:

```java
private static final InvalidPlateException INVALID_PLATE = new InvalidPlateException("invalid plate");
```

Now throwing costs literally nothing. This is what Netty and several parsers do internally, and it is the same idea as the [Interning](../TechTalk-Interning) talk: one instance representing all the equal ones.

But be honest about what is lost: **the message can no longer contain the offending value**, and every occurrence is indistinguishable. Only worth it in a genuinely hot path, and never in something a human will read.

## The NPE with no stack trace

There is a related phenomenon that costs people entire afternoons, and it is worth knowing because it looks like a broken JVM.

An error appears in production:

```
java.lang.NullPointerException
	at ... (nothing)
```

A `NullPointerException` with **an empty stack trace**. It is not a bug and nothing is corrupted: it is HotSpot optimising.

When the JIT sees that an *implicit* exception - NPE, `ArrayIndexOutOfBounds`, `ClassCastException`, division by zero - is thrown repeatedly at the same site, it recompiles that code to throw a **preallocated, shared instance with no stack trace**. The flag is on by default:

```
-XX:+OmitStackTraceInFastThrow
```

The JVM effectively applied this talk's technique on its own, for us. The problem is that it applies it **after the fact**: the first occurrences do have a trace, and by the time we go looking at the logs, only the useless ones are left.

The fix while investigating:

```shell
-XX:-OmitStackTraceInFastThrow
```

Turn it off, reproduce, get the trace, turn it back on. And take the empty trace as a signal in itself: **it means that exception is being thrown a lot**, which is usually the more important finding.

## Good practices

### AntiPattern: exceptions as control flow in a loop

```java
for (String value : values) {
    try {
        result.add(Integer.parseInt(value));
    } catch (NumberFormatException e) {
        // ignore the ones that are not numbers
    }
}
```

With a few malformed values it is fine. With a file where half the rows are not numbers, this is building hundreds of thousands of stack traces to decide *"this is not a number"*.

And `NumberFormatException` comes from the JDK, so we cannot make it stackless. The fix is not to make the exception cheaper, it is **not to reach the exception**:

```java
if (DIGITS.matcher(value).matches()) {
    result.add(Integer.parseInt(value));
}
```

Rule of thumb: **an exception should not be the expected outcome of the common case**. When it is, the cheapest exception is the one that is never created.

### Do not do this by default

Everything here is a hot path optimisation. Applying it across the codebase produces a system where nothing has a stack trace and the first serious incident takes three times as long to diagnose.

The right order is: measure, find the one exception that is being thrown millions of times, fix that one. Not the other way round.

### AntiPattern: catching to log, and rethrowing

```java
} catch (InvalidPlateException e) {
    log.error("invalid plate", e);     // a full trace, for an expected case
    throw e;
}
```

Beyond duplicating the log - which the [Logging Policy](../TechTalk-Logging-Policy) talk already covers - `log.error(msg, e)` **formats the stack trace into a String**. Which we had just decided not to build. If the exception is stackless, the log line is useless; if it is not, we are paying the cost twice.

### Leave the trace on anything unexpected

Worth repeating because it is the one that hurts: a business exception that reaches the top without a trace, in an incident at three in the morning, turns a five minute diagnosis into an hour of guessing.

## Appendix: measuring it properly

Anything in this area measured with `System.nanoTime` in a `main` is worthless: the JIT will optimise away an exception whose result nobody uses. JMH:

```java
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@State(Scope.Benchmark)
public class ExceptionBenchmark {

    @Benchmark
    public Object withStackTrace() {
        try {
            return deep(20, true);
        } catch (RuntimeException e) {
            return e;
        }
    }

    @Benchmark
    public Object withoutStackTrace() {
        try {
            return deep(20, false);
        } catch (RuntimeException e) {
            return e;
        }
    }

    private Object deep(int depth, boolean trace) {
        if (depth == 0) {
            throw trace ? new RuntimeException("x") : new StacklessException("x");
        }
        return deep(depth - 1, trace);
    }
}
```

Run it at several depths - 5, 20, 50 - because the whole point is that the cost scales with depth. That is the graph worth having, and it is the argument that convinces a team far better than any article.

On an application already running, without touching the code, the [Arthas](../TechTalk-Arthas-Tool) talk shows how to count how many times a constructor is being called, which answers the only question that matters first: **is this exception actually being thrown enough to care?**
