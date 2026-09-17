# TechTalk: From Sleuth to Micrometer Tracing[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-From-Sleuth-to-Micrometer-Tracing/README.md)

**Spring Cloud Sleuth is discontinued.** It has no Spring Boot 3 version: its functionality moved into [Micrometer Tracing](https://docs.micrometer.io/tracing/reference/), and the ecosystem converged on [OpenTelemetry](https://opentelemetry.io/). This talk explains what changed, why, and how to migrate.

It supersedes the [Sleuth for Tracing](../TechTalk-Sleuth-for-Tracing) talk, which stays published as a reference for projects still on Spring Boot 2.

 - [Introduction](#introduction)
 - [Why Sleuth disappeared](#why-sleuth-disappeared)
 - [The three signals and one idea](#the-three-signals-and-one-idea)
 - [Migrating](#migrating)
 - [Correlating the logs](#correlating-the-logs)
 - [Instrumenting our own code](#instrumenting-our-own-code)
 - [Sampling](#sampling)
 - [Good practices](#good-practices)
 - [Appendix: the equivalence table](#appendix-the-equivalence-table)

<br/>

## Introduction

The problem tracing solves has not changed since the Sleuth talk: a request crosses six services, something is slow or broken, and the logs of each service in isolation tell us nothing. We need to follow **one** request across all of them.

What changed is who does it and how it is transported. And this is not cosmetic: it is the difference between an instrumentation tied to Spring and an **industry standard**.

## Why Sleuth disappeared

Sleuth was a Spring project solving a Spring problem. It worked very well, and it had two structural limitations:

*   it only instrumented **Spring**. Anything outside it had to be instrumented by hand

*   its propagation format, **B3**, was a Zipkin convention, not a standard

Meanwhile, OpenTelemetry appeared: a vendor neutral specification, with its own propagation format - **W3C Trace Context** - and agents for every language. A trace started in a Java service and continued in a Python one stopped being a project.

So the Spring team did the sensible thing: instead of maintaining a parallel instrumentation, they moved the abstraction into **Micrometer**, which was already the metrics abstraction, and made it delegate to OpenTelemetry or Brave through a bridge.

The result is that we do not depend on a tracing library any more. We depend on **Micrometer's API**, and the backend is a dependency we swap.

## The three signals and one idea

The idea that makes the new model click is the **Observation**.

Previously, metrics and traces were two separate worlds, instrumented twice. Micrometer unified them: we declare **one observation** around a piece of work, and from that single declaration come:

*   a **metric** - how many times, how long, how many errors

*   a **span** - this piece of work, inside this trace, with this parent

*   a **log context** - the trace id, available to write in every log line

One instrumentation, three signals. That is the whole point of the redesign, and it is why the API we touch is called `ObservationRegistry` and not `Tracer`.

## Migrating

Out with Sleuth:

```xml
<!-- REMOVE -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
```

In with Micrometer Tracing, bridged to OpenTelemetry, exporting over OTLP:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
```

```properties
spring.application.name=car-service
management.tracing.sampling.probability=0.1
management.otlp.tracing.endpoint=http://otel-collector:4318/v1/traces
```

Two details that cost time if nobody says them:

**Actuator is mandatory now.** Tracing auto configuration lives there. Without `spring-boot-starter-actuator`, none of this activates and nothing complains.

**The bridge is a choice.** `micrometer-tracing-bridge-otel` for OpenTelemetry, `micrometer-tracing-bridge-brave` for Zipkin/Brave. Our code does not change - only the bridge and the exporter do. That is exactly the point of the abstraction.

## Correlating the logs

This is the part that matters day to day, and it is the same idea as in the Sleuth talk: a trace is only useful if we can **jump from a log line to the trace, and back**.

Micrometer puts `traceId` and `spanId` in the MDC, so the log pattern picks them up:

```properties
logging.pattern.level=%5p [${spring.application.name:},%X{traceId:-},%X{spanId:-}]
```

which produces the familiar line:

```
INFO [car-service,3f9a1c4e8b2d7f10,8b2d7f1044e2] c.e.CarController - request completed status=200 time=142ms
```

Everything in the [Logging Policy](../TechTalk-Logging-Policy) talk applies without a single change, and gains from this: **one summary line per request**, carrying the `traceId`. That line is the bridge between the two worlds - we find the problem in the logs and open the trace, or the other way round.

## Instrumenting our own code

HTTP in and out, JDBC and messaging come instrumented. What is not instrumented is our own business logic, and that is usually where the time goes.

The declarative way:

```java
@Observed(name = "car.pricing", contextualName = "calculate-rental-price")
public Price calculate(RentalRequest request) {
    ...
}
```

The programmatic way, when we need to attach data:

```java
Observation.createNotStarted("car.pricing", observationRegistry)
        .lowCardinalityKeyValue("brand", request.brand())      // few distinct values: becomes a metric tag
        .highCardinalityKeyValue("plate", request.plate())     // many distinct values: span only
        .observe(() -> pricingEngine.calculate(request));
```

That distinction is the single most important thing to understand in this API, and it is a direct consequence of unifying metrics and traces:

*   **low cardinality** keys become **metric tags**. A tag with a thousand distinct values creates a thousand time series and kills the metrics backend

*   **high cardinality** keys stay in the **span** only, where one more attribute costs nothing

Rule of thumb: **an identifier is never low cardinality**. A plate, a user id, an order number: high cardinality, always.

## Sampling

We do not trace 100% of the traffic in production. The volume and the cost are not worth it, and the information is redundant.

```properties
management.tracing.sampling.probability=0.1
```

Two things worth knowing:

The decision is taken **once, at the start of the trace**, and travels with the context. Either the whole trace is sampled or none of it is - there are no traces with holes in the middle. So the value has to be consistent across services, or the entry point has to own the decision.

And 10% is a reasonable default for steady traffic, but it is exactly the wrong thing when we are chasing a rare error: the failing request is probably one of the 90% that was dropped. This is why **tail sampling** exists - deciding after the fact, keeping every trace that has an error or is slow - and it is configured in the collector, not in our service.

## Good practices

### AntiPattern: keeping the B3 headers by inertia

Sleuth propagated with **B3** by default. OpenTelemetry propagates with **W3C Trace Context**, the `traceparent` header.

During a migration both formats coexist, and a service that only reads `traceparent` talking to one that only sends B3 **silently breaks the trace**: nothing fails, no error appears, we simply get two disconnected traces and we blame the collector.

While the migration lasts, accept both:

```properties
management.tracing.propagation.consume=w3c,b3
management.tracing.propagation.produce=w3c
```

and remove the `b3` once the last service is migrated. Consume both, produce one.

### Instrument boundaries, not methods

The temptation after wiring this up is to put `@Observed` on everything. A trace with four hundred spans per request is as useless as no trace at all, and it costs real money to store.

What deserves a span is a **boundary**: a call leaving our process, a database query, a message published, a genuinely expensive block of business logic. Not a getter.

### Do not put personal data in a span

A span goes to an external system, is stored for weeks and is visible to anybody who can open the tracing UI. It is not the place for emails, names, tokens or full request payloads. The same judgement we apply to a log line applies here, and with less supervision.

### Traces do not replace logs

They answer different questions. A trace tells us **where** the time went and **which** service failed. The log tells us **why**. Whoever removes the logs because "we have tracing now" discovers the difference during the first serious incident.

## Appendix: the equivalence table

| Sleuth (Spring Boot 2) | Micrometer Tracing (Spring Boot 3) |
|---|---|
| `spring-cloud-starter-sleuth` | `micrometer-tracing-bridge-otel` + exporter |
| `Tracer` (Sleuth) | `Tracer` (Micrometer) or `ObservationRegistry` |
| `@NewSpan` | `@Observed` |
| `spring.sleuth.sampler.probability` | `management.tracing.sampling.probability` |
| B3 headers by default | W3C `traceparent` by default |
| `spring.sleuth.enabled=false` | `management.tracing.enabled=false` |

One last note for anybody coming from a reactive codebase: context propagation across threads is no longer automatic in every case. Micrometer ships the `context-propagation` library exactly for this, and it is the first thing to check when the `traceId` appears empty halfway through a chain. The same applies to virtual threads - see [Virtual Threads vs Reactive](../TechTalk-Virtual-Threads-vs-Reactive).
