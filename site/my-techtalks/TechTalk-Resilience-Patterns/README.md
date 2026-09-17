# TechTalk: Resilience - Timeouts, Retries and Circuit Breakers[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Resilience-Patterns/README.md)

Logs tell us what happened and traces tell us where. This talk is about the third question: **what our service does when the one it depends on fails**.

The library is [Resilience4j](https://resilience4j.readme.io/), and the documentation is [here](https://resilience4j.readme.io/docs/getting-started)

 - [Introduction](#introduction)
 - [The failure nobody plans for](#the-failure-nobody-plans-for)
 - [Timeout: the one that is never optional](#timeout-the-one-that-is-never-optional)
 - [Retry, and how it makes things worse](#retry-and-how-it-makes-things-worse)
 - [Circuit breaker](#circuit-breaker)
 - [Bulkhead](#bulkhead)
 - [Composing them](#composing-them)
 - [Good practices](#good-practices)
 - [Appendix: what to measure](#appendix-what-to-measure)

<br/>

## Introduction

In a monolith, a call to another module either returns or throws. In a distributed system there is a third outcome, and it is the one that takes the system down:

> **it does not answer, and it does not fail either**

A slow dependency is far more dangerous than a dead one. A dead one fails fast and we handle it. A slow one holds our threads, one by one, until we have none left. And then **our** service stops answering, and whoever calls us starts holding their threads too.

That is a **cascading failure**, and the important part is the direction: the failure propagates **upwards**, from the dependency towards the user, through resources that nobody is releasing.

## The failure nobody plans for

Let's suppose a car rental service that calls a pricing service to complete every request.

The pricing service degrades: it still answers, but in 30 seconds instead of 100 ms. Nothing is down. No alert fires, because everything returns HTTP 200.

Our service has 200 threads. At 50 requests per second, the arithmetic is immediate: after four seconds every thread is waiting on the pricing service. Requests that do not need pricing at all - listing cars, checking a reservation - now fail too, because there is no thread left to serve them.

**One degraded dependency took down a service that was perfectly healthy**, including the parts that did not depend on it.

Everything that follows exists to break that chain in a different place.

## Timeout: the one that is never optional

The root cause above is a single sentence: *we waited 30 seconds*. There is no reason for that. If the pricing service normally answers in 100 ms, waiting 30 seconds does not give it a chance to recover - it just prolongs our own damage.

```java
@Bean
public RestClient pricingClient(RestClient.Builder builder) {
    var factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(Duration.ofSeconds(2));
    factory.setReadTimeout(Duration.ofSeconds(3));
    return builder.baseUrl("http://pricing-service").requestFactory(factory).build();
}
```

Rule of thumb:

> **every call that leaves our process has a timeout, and the default value is never acceptable**

Most HTTP clients, drivers and connection pools default to *infinite* or to something absurd like two minutes. Every one of those defaults is a production incident waiting for the right day.

How to choose it: look at the **p99 of the dependency in normal operation** and give it some headroom. If the p99 is 300 ms, a timeout of 1 second is generous. A timeout of 30 seconds is not caution, it is an unprotected service with a number written next to it.

And a subtlety worth stating, because it catches everybody: **the timeout of the caller must be shorter than the timeout of the caller's caller**. Otherwise the user has already given up while we keep holding resources for a response nobody will read.

## Retry, and how it makes things worse

Retrying is the most intuitive reaction and the easiest one to get wrong.

```java
RetryConfig config = RetryConfig.custom()
        .maxAttempts(3)
        .intervalFunction(IntervalFunction.ofExponentialRandomBackoff(
                Duration.ofMillis(200),   // initial wait
                2.0,                      // multiplier
                0.5))                     // jitter
        .retryOnException(e -> e instanceof IOException)
        .build();
```

Three decisions in there, and all three matter.

**Exponential backoff.** Retrying immediately is retrying against a service that has not had a millisecond to recover. Each attempt waits longer than the last.

**Jitter**, the random factor. Without it, a thousand instances that failed at the same moment retry at exactly the same moment, three times, in unison. We turned an outage into a **synchronised attack on a service that was trying to come back**. This is called a thundering herd, and jitter is the entire fix.

**Retry only what is retryable.** A connection timeout is worth retrying. An HTTP 400 will be 400 forever, and retrying it three times just triples the load for nothing.

And the decision that is not in the code:

> **do not retry an operation that is not idempotent**

A read is idempotent. A `PUT` with a full resource is idempotent. A payment, an email, an `INSERT` without an idempotency key: **not idempotent**. If the request arrived and the response was lost, retrying charges the customer twice. The timeout did not tell us whether the operation was executed - only that we did not get to read the answer.

Rule of thumb: **retries multiply load exactly when the system can least afford it**. Three attempts on three layers of a call chain is 27 requests for one user action.

## Circuit breaker

Retries and timeouts limit the damage of one call. The circuit breaker answers a different question: **when do we stop calling at all?**

If the pricing service has failed the last hundred times, attempt one hundred and one is not hope, it is waste: it costs us a thread, it costs the dependency a request it cannot serve, and it makes the user wait for a failure we could have predicted.

Three states, and the third is the interesting one:

*   **CLOSED**: everything normal, calls go through, failures are counted

*   **OPEN**: the failure rate crossed the threshold. Calls **fail immediately, without being attempted**. The dependency gets breathing room and we stop wasting resources

*   **HALF_OPEN**: after a wait, a **few** calls are let through. If they work, back to CLOSED. If not, back to OPEN

```java
CircuitBreakerConfig config = CircuitBreakerConfig.custom()
        .slidingWindowType(SlidingWindowType.COUNT_BASED)
        .slidingWindowSize(100)
        .failureRateThreshold(50)                              // % of failures to open
        .slowCallDurationThreshold(Duration.ofSeconds(2))
        .slowCallRateThreshold(50)                             // slow counts as failure
        .waitDurationInOpenState(Duration.ofSeconds(30))
        .permittedNumberOfCallsInHalfOpenState(10)
        .build();
```

```java
@CircuitBreaker(name = "pricing", fallbackMethod = "standardPrice")
public Price calculate(RentalRequest request) {
    return pricingClient.calculate(request);
}

private Price standardPrice(RentalRequest request, Throwable cause) {
    log.warn("pricing unavailable, falling back to tariff table", cause);
    return tariffTable.lookup(request.category());
}
```

Note `slowCallRateThreshold`. **A slow call counts as a failure**, and this is the setting that addresses the scenario from the beginning of the talk. Without it, a dependency that answers 200 in 30 seconds never opens the breaker, because technically nothing is failing.

And note the **fallback**, which is where the real design decision lives. A circuit breaker without a fallback just fails faster, which is already worth a lot. A circuit breaker with a sensible fallback - a standard tariff, a cached value, a degraded but useful response - is the difference between **a degraded feature and a broken service**.

## Bulkhead

The name comes from ships: the hull is divided into watertight compartments so that a hole floods one, not the whole vessel.

Applied to our service: if three dependencies share the same 200 threads, the failure of one consumes all of them and takes the other two down. A bulkhead assigns each dependency **its own quota**.

```java
BulkheadConfig config = BulkheadConfig.custom()
        .maxConcurrentCalls(20)
        .maxWaitDuration(Duration.ofMillis(100))
        .build();
```

Twenty concurrent calls to the pricing service. Call twenty one waits 100 ms and, if nothing is freed, is rejected immediately. The pricing service can be completely down, and listing cars keeps working.

This pattern became **much more important with virtual threads**. When threads were expensive, the pool size was an implicit bulkhead for everything. With a virtual thread per request, that accidental protection is gone and the limit has to be declared explicitly - see [Virtual Threads vs Reactive](../TechTalk-Virtual-Threads-vs-Reactive).

## Composing them

They stack, and **the order changes the behaviour**. Resilience4j applies them, from outside in:

```
Retry ( CircuitBreaker ( RateLimiter ( TimeLimiter ( Bulkhead ( call ) ) ) ) )
```

Which reads as: retry **a call that is protected by the breaker**. This is the order we want, and it is worth understanding why the opposite is wrong.

If the breaker were on the outside, the three retry attempts would happen inside a single protected call, and the breaker would count **one** failure instead of three. It would take three times as long to open, which is precisely when it is needed most.

With the Spring Boot starter, this order is the default and the annotations compose:

```java
@Retry(name = "pricing")
@CircuitBreaker(name = "pricing", fallbackMethod = "standardPrice")
@Bulkhead(name = "pricing")
public Price calculate(RentalRequest request) { ... }
```

## Good practices

### AntiPattern: retry inside retry

Avoid this: the HTTP client retries 3 times, the service method retries 3 times, and the caller retries 3 times.

Nobody wrote it deliberately - each layer was added by a different person, each one reasonably. The result is **27 requests** for one user action, arriving at a service that is already on the floor.

Rule of thumb: **retries belong at exactly one level**, and it should be the one closest to the failure that knows whether the operation is idempotent. Every other level fails fast and propagates.

### AntiPattern: the fallback that hides the problem

```java
private Price standardPrice(RentalRequest request, Throwable cause) {
    return new Price(BigDecimal.ZERO);      // nothing fails, everything is free
}
```

A fallback that returns an empty value and logs nothing converts a loud failure into a **silent corruption**. The service reports itself healthy while quietly giving away cars.

A fallback has to be a **deliberate business decision**: a standard tariff, the last known value, a clear error for the user. And it always logs, at `WARN`, following the criteria in the [Logging Policy](../TechTalk-Logging-Policy) talk: a controlled situation that prevents the expected flow.

### Do not protect what does not need protecting

All of this has a cost in complexity and in latency. A call to our own database, with a well sized pool, usually needs a **timeout** and nothing else. The full apparatus is for **calls leaving our process** towards something we do not control.

Adding circuit breakers everywhere produces a system that is harder to reason about and no more robust.

### Test the failure, not just the success

The fallback that nobody ever executed does not work. It is an untested code path, written under the assumption that it will never run, and it will run on the worst day.

Testcontainers or a mock that is made to fail, and a test asserting that the circuit opens, that the fallback returns what it should, and that the degraded path is actually usable. **The failure path deserves the same tests as the happy one.**

### Configuration is not a constant

`failureRateThreshold`, `waitDurationInOpenState` and the timeouts are not universal values: they depend on the real latency and the real failure rate of each dependency. Copying them from an example and never looking again produces breakers that never open, or breakers that open on their own during a normal traffic peak.

## Appendix: what to measure

Resilience4j publishes metrics through Micrometer, so they are already there if Actuator is (see [From Sleuth to Micrometer Tracing](../TechTalk-From-Sleuth-to-Micrometer-Tracing)):

```
resilience4j_circuitbreaker_state            # 0 closed, 1 open, 2 half_open
resilience4j_circuitbreaker_calls_total      # by kind: successful, failed, not_permitted
resilience4j_retry_calls_total               # how many are retried, and how many succeed after
resilience4j_bulkhead_available_concurrent_calls
```

Two alerts worth having from day one:

*   **a breaker that has been OPEN for a long time**: a dependency is down and we are serving degraded responses. It may be invisible to the user, and that is exactly why it needs an alert

*   **a breaker that flaps**, opening and closing constantly: the threshold is wrong, or the dependency is intermittently unhealthy. Both are problems

And one number that says more than any dashboard: **how many retries succeed**. If almost none do, the retry is not buying anything and is only adding load.
