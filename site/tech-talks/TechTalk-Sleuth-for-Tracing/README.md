# TechTalk: Sleuth for Tracing

* [Introduction](#introduction)
* [How it works](#how-it-works)
* [Digging Deeper](#digging-deeper)
* [Integrating in a existing WebFlux Project](#integrating-in-a-existing-webflux-project) 
* [Integration in Others Spring Boot components](#integrating-in-an-existing-no-spring-boot-project)
* [Integrating in an existing no Spring Boot Project](#integrating-in-an-existing-no-spring-boot-project) 
* [Future use (Rabbit)](#future-use-rabbit)
* [Zipkin](#zipkin)

## Introduction
[
Spring Cloud Sleuth](https://spring.io/projects/spring-cloud-sleuth) is a library to trace logs both in:

* only one microservice

* across a set of microservices

It is part of the spring stack (cloud)

Note: *Adding  Sleuth library into a existing WebFlux Reactor increases around 9 Megabytes the size of the jar, which is totally acceptable*. 

## How it works

Let’s suposse the following scenario

**Device 1 ↔︎  Service 1 ↔︎  Service 2 ↔︎  Service 3**

Each service logs whatever it is necessary, but there is not relationship among logs of Service1, Service2 and Service 3 

Now, if sleuth were used then: 

> Service 1 will receive the request from Device 1 and will “create” a identifier for the request (TraceId) to be used in its logs. But, here is the interesting thing, this TraceId will be passed to Service2 so it can log with this TraceId and so on..<br/>
> As a result of this, the logs from Service1, Service2 and Service3   will have the same TraceId. This is very useful to trace and follow the flow of a particular request across the services

## Digging Deeper

In case of HTTP Services, what Sleuth is actually passing across services is a set of headers with the data for tracing, among others:

**X-B3-TraceId:** <id> 

**X-B3-SpanId:** <id> 

**X-B3-ParentSpanId:** <id>

where <id> is a 64 bit number codified in Hexadecimal. for example c6a57393afe6c110, 1194ba035858a7f6, … 

There are two key concepts:

* **TraceId** – This is the id to trace an external request, for example a user is requesting to purchase a content, so this TraceId can be seen as the “purchaseId” to be used in all services involved.
  
* **SpanId** – Let’s assume that each step of the purchase can be seen as “unit” of work, these units of works are the Span.

 

By default, any application flow will start with same TraceId and SpanId.

# Integrating in a existing WebFlux Project 

If the project uses WebFlux Reactor, the integration requires two easy steps:

* add the dependencies in Gradle (two places)


```
//add the dependendecy management for spring cloud dependencies
// PLEASE note the version for cloud-dependencies must be compatible with the spring boot version
// see this: https://stackoverflow.com/questions/42659920/is-there-a-compatibility-matrix-of-spring-boot-and-spring-cloud
  dependencyManagement {
      imports {
              mavenBom "org.springframework.cloud:spring-cloud-dependencies:Hoxton.SR6"
              mavenBom 'org.springframework.boot:spring-boot-starter-parent:2.2.1.RELEASE'
      }
  }
 ```


```
// add the dependencies
dependencies {
    ....  
    implementation 'org.springframework.cloud:spring-cloud-starter-sleuth:2.2.3.RELEASE'
    ...
}
``` 

 

* Change the log pattern to include `spanId` and `traceId`


```
logging.pattern.console=%d{yyyy-MM-dd'T'HH:mm:ss.SSSZ} [%thread] %-5level %logger{36} - %marker %X{spanId:-}] - %X{traceId:-}] - %msg%n 
```

Example of log

```
2022-06-09T09:56:22.037+0200 [reactor-http-epoll-4] DEBUG t.m.i.s.s.service.MyService -  864365593117de60] - 864365593117de60] - message: "my log message"
 
```

Besides, Sleuth provides a Tracer class that allows to manage Sleuth behaviour, for example the following code creates  a new TraceId in case it is required.


```
@Service
public class MyService {
 ...
    @Autowired
    private Tracer tracer;
    public void myLogic() {
        Span newSpan = tracer.nextSpan().name("newSpan").start();
        String traceId = newSpan.context().spanIdString());
        ...
    }
``` 

**Please note that Sleuth works transparently with WebFlux Reactor. It is able to manage correctly the identifiers to log in the Reactive Chain** 

Integration in Others Spring Boot components
It is possible to enable sleuth in many Spring Boot components

[Spring Cloud Sleuth customization](https://docs.spring.io/spring-cloud-sleuth/docs/current-SNAPSHOT/reference/html/integrations.html) 

Redis, RestTemplate, JDBC,…

## Integrating in an existing no Spring Boot Project

In all cases, it is possible to integrate “by hand” the tracing capability of Sleuth

It  is actually a straight forward procedure as the Sleuth headers  will be received or sent as any other conventional Header.  

Once retrieved the TraceId and SpanId from the request, they can be used in the log as you wish 

At any time you can create a valid identifier as follows:


```
Long value = UUID.randomUUID().getMostSignificantBits() & Long.MAX_VALUE;
String traceId = String.format("%016x", value);
```

## Future use (Rabbit)

To do in the future how easy is to integrate Sleuth with our current messaging library

## Zipkin

Zipkin is a distributed tracing system that integrates very well with Sleuth
