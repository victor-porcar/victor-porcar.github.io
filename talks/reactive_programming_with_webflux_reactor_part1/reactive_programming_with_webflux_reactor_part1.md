# Reactive Programming with WebFlux Reactor (part I)

```
Introduction to Reactive Paradigm
Reactive Programming in Java
Spring Boot WebFlux Reactor
Why and When Reactive Programming is good idea?
Thread-per-Request processing
Reactive Programming
Digging deeper in WebFlux Reactor
Mono
Operators
Map
FlatMap
Zip
Flux
Exceptions / timeout
Blocking scenario
Schedulers
Reactive Web Server
Web Client
Redis
Database
Developing Applications with WebFlux Reactor
```
## Introduction to Reactive Paradigm

Example: Let's suppose a MQTT topic (queue) with many clients "listening" to that queue, so as soon as there is a new element in the topic, all
clients will receive that element and will process it

```
MQTT queue is a Publisher (Produces data)
Every client is a Subscriber (Consumes data)
the Connection between the Subscriber and Publisher is called Subscription (arrows)
```
This scenario is reactive because the subscriber will react to a new data published by the Publisher Asynchronously

```
It is message-driven mechanism
Low coupling between Publishe and Subscriber
```
### Reactive Programming in Java

While Asynchronous processing is quite old in computing, in Java it can be achieved from the very first day by Managing Threads in an ad-hoc
solution (from Java 1) or using java.concurrent.util API (from Java 1.5)


Reactive Paradigm was introduced as a trend a few years ago.

This paradigm introduced explicitely concepts such as Publisher, Subscriptor, Subscription...

There was an important effort to create a common API specification for the Java World, which is called Reactive Streams.

Please note Reactive Streams is an specification, not an implementation !!!.

There are several implementations:

```
Reactor library : the chosen implementation for Spring Boot
RxJava: created initially by Netflix
RatPack
Vert.x
Java 9
```
### Spring Boot WebFlux Reactor

As pointed, Spring Boot uses Reactor as Reactive streams implementation to provide Reactive Programming.

In order to get the most reactive behaviour, all the components responsible for I/O communications should be Asynchronous (non-blocking)

Fortunately there are some of them in the Java Ecosystem:

```
Web Server:
Netty
Undertow
Servlet 3.1+
```
```
Reactive repositories:
Mongo
Cassandra
Redis (Lettuce)
CouchBase
R2DBC
NOTE: There is not an official implementation for JDBC / Oracle database. See later
```
```
WebFlux Reactor = Spring Boot + Reactor library + Async I/O communication modules
```
Ratpack, which is used in Mirada, includes Netty as async web server as well·

### Why and When Reactive Programming is good idea?

In the context of a Web Service, let's compare a traditional approach (Thread-per-request) vs reactive approach

```
Thread-per-Request processing
```
Java applications have been built over the years following the Thread-per-Request paradigm, in which the same thread is used for all operations
required for a request, these operations may include:

```
CPU processing operations: the thread in which is executed the request is not blocked, it is "working" all the time
I/O operation (database queries, request to another service): the thread is blocked until the I/O has finished
```
Consequence: If the load is high and there are many I/O operations the number of concurrent threads is high, most of them will be blocked


Let's see some interesting related questions:

```
Does having a lot of concurrent threads use a lot of memory? Yes, because the execution context of a single thread requires memory,
so having a lot of threads means a lot of memory (potentially)
Is having a lot of concurrent threads bad for the performance? Not per se (a blocked thread does not consume CPU cycles). However if
there are many thread it forces the Operating System to swaps contexts between threads, which is an expensive operation.
```
```
Reactive Programming
```
In reactive programming, threads are not blocked or waiting for a I/O to complete. Instead they are notified when the I/O is complete / the data
changes. which means:

```
less threads are required less resources are required to process the same
```
The problem with Reactive Programming is the code usually is more complex difficult to maintain and to extend

```
is good idea to use WebFlux Reactor ???
```
```
My opinion: If there is a lot of potentially blocking I/O operations then it would be good idea, otherwise stick in the traditional way
(not reactive)
```
```
Examples:
```
```
xxxx receives tens of HTTP requests per second, which means a lot of I/O operations good idea at least in the component that
handles requests
yyyy which only reads database every 10 minutes not good idea
```
## Digging deeper in WebFlux Reactor

In order to understand how to build a WebFlux Reactor application, it is necessary to master the following concepts:

```
Types Mono and Flux of the Reactor library These types provides most of the Reactive functionality.
Exceptions / Timeouts while executing Mono or Flux
Blocking scenario
Web Applications: Reactive RestController / WebClient
Reactive Repositories: to avoid blocking operations on these repositories
```
Besides it is interesting to understand the Scheduler interface, which is a part of the Reactor library and provides thread pool management.

We'll see all these concepts in detail below.

### Mono

It represents a Publisher that can emit 0..1 element.


We can think of a Mono<T> as object that has:

```
Consumer object which is actually a method of executable "code" that receives a a parameter a value of type T this "code" can be provided
as lambda function or method reference
one method call subscribe
```
As soon as the subscribe method is invoke, the Mono will generate a value of type T and this value will be passed to the executable "code", in
asynchronous way

In other words, a Mono<T> as a component Publisher that WILL publish a value of type T to a provided handler (Subscriptor) when its method s
ubscribe is invoked.

What value will it publish? well it depends on the Mono creator, for example if the Mono is created by the Reactive WebClient, the value will be
the response of the performed request.

Please note:

```
if subscribe method is not invoked nothing happens
the handler is normally executed in a different thread (see detail later), in the following example it means that line 13 could be executed before
line 7
The generation of value of type T implies that something has to do, in the case of Reactive Webclient it means to perform the actual request
to the server...
```
```
Operators
```
The official Documentation explains very well all operators

## Map

transform the Mono by building another Mono

## FlatMap

transform the Mono by chaining another existing Mono

## Zip

This operator combines two or more Mono subscribes to all Monos and builds a new one as a result of the combination

### Flux

It represents a stream that can emit 0..n elements.

The idea is the similar to Mono but with n elements


The official Documentation explains very well all operators

### Exceptions / timeout

There are some operators to deal with exceptions happening inside of a callback, most common used:

```
doOnError
onErrorResume
```
The operator timeout will propagate a java.util.concurrent.TimeoutException

### Blocking scenario

block(): Subscribe to this Mono and block indefinitely until a next signal is received.

### Schedulers

If the previous are executed, it is easy to check that the thread being used to execute the asynchronous code is actually the same thread that is
running the main flow, which means that is not working really in a synchronous way, the reason is we have to provide a Thread Pool to execute
async tasks

This is done by Schedulers,

In order to define a Scheduler, there are some predefined configurations

```
parallel(): Optimized for fast Runnable non-blocking executions
single(): Optimized for low-latency Runnable one-off executions
elastic(): Optimized for longer executions, an alternative for blocking tasks where the number of active tasks (and threads) can grow
indefinitely
boundedElastic(): Optimized for longer executions, an alternative for blocking tasks where the number of active tasks (and threads) is
capped
immediate(): to immediately run submitted Runnable instead of scheduling them (somewhat of a no-op or "null object" Scheduler)
fromExecutorService(ExecutorService) to create new instances around Executors
```
or configurable:

Once the Scheduler is defined, it is possible to set it to be used by a Mono or Flux using the method publishOn or SubscribeOn

```
publishOn: It affects subsequent operators after publishOn - from that point the code will be executed by a thread picked from publishOn'
s scheduler.
subscribeOn: similar to publishOn, but it affects all the chain (before and after) subscribeOn
```
as it is the block

commenting line 4 and uncommenting line 5


#### 1.

#### 2.

#### 3.

#### 4.

### Reactive Web Server

Let's see how it works in a nutshell:

```
the incoming HTTP request is received by the reactive engine implementation (netty / Undertow / Servlet 3.1)
Spring will pass to the corresponding controller method the parameters this method will be executed and return a Mono or Flux Please
note that the thread in which this is executed is never blocked
the reactive engines will suscribe to that Mono/Flux
Once the Mono/Flux has emitted all data (by invoking the consumer), the reactive server will send it back to the client
```
Note: No thread is blocked in this mechanism

### Web Client

Spring WebFlux offers a reactive version of the web client

### Redis

Example to Get an element, please notice the usage of operator switchIfEmpty to deal with non existing entries

Example to Set element

### Database

There is not official implementation for a Reactive Oracle JDBC driver. However, there is an implementation of a programmer (Dave Moten)

https://github.com/davidmoten/rxjava2-jdbc

Last commit on this library is 13-October-

Some known problems:

```
It is not possible to use a block() operator on a Mono/Flux returned by the library if it used a Reactive Datasource
```
## Developing Applications with WebFlux Reactor

```
You can "mix" reactivity approach and "classical" approach in the same application, for example in xxxx:
All code to manage searches is implemented in a reactive way
Queries to database to tefresh of local caches that happens every 10 minutes are performed in a no reactive way
```

Broadly speaking, your code will be just a chains" of linked Mono/Flux with map / flatMap:

```
You don't have to worry about Schedulers because they will be managed by SpringWebFlux
Be careful and write "clean code": a method shouldn't have more than 3 concatenated map/flatMap/zip
```
Write short lambdas (SonarLint has a parameter to limit that) or refactor the code in a external method the code is cleaner

Learn from the reference: There are many operators for Mono/Flux, all of them are well explained in the documentation

Good Practice name references to Mono properly, put the name "mono" as part of the reference name


