# Reactive programming in WebFlux (part 1)

## Introduction to Reactive Paradigm
 

  <IMNAGEÇ>

  

Example: Let's suppose a MQTT topic (queue) with many clients "listening" to that queue, so as soon as there is a new element in the topic, all clients will receive that element and will process it

*   MQTT queue is a  **Publisher (Produces data)**
*   Every client is a  **Subscriber (Consumes data)**
*   the Connection between the Subscriber and Publisher is called **Subscription (arrows)**

  

This scenario is **reactive** because the subscriber will **_react_** to a new data published by the Publisher **Asynchronously**

*   It is message-driven mechanism
*   Low coupling between Publishe and Subscriber

## Reactive Programming in Java
 
While **Asynchronous** **processing** is quite old in computing, in Java it can be achieved from the very first day by Managing Threads in an _ad-hoc_ solution (from Java 1) or using java.concurrent.util API (from Java 1.5)

**Reactive**  Paradigm was introduced as a trend a few years ago.

This paradigm introduced explicitely concepts such as **Publisher**, **Subscriptor**, **Subscription**...

There was an important effort to create a **common** API specification for the Java World, which is called [Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm).

Please note [Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm) is an specification, not an implementation !!!.

There are several implementations:

*   [Reactor library](https://projectreactor.io/) : the chosen implementation for Spring Boot
*   [RxJava](https://github.com/ReactiveX/RxJava): created initially by Netflix
*   [RatPack](https://github.com/ratpack/)
*   [Vert.x](https://vertx.io/)
*   [Java 9](https://www.reactive-streams.org/) 

### Spring Boot WebFlux Reactor
 

As pointed, Spring Boot uses **Reactor** as _Reactive streams_ implementation to provide Reactive Programming.

In order to get the most reactive behaviour, all the components responsible for I/O communications should be **Asynchronous (non-blocking)**

Fortunately there are some of them in the Java Ecosystem:

  

*   **Web Server**: 
    *   Netty
    *   Undertow
    *   Servlet 3.1+

  

*   **Reactive repositories:**
    *   Mongo
    *   Cassandra
    *   Redis (Lettuce)
    *   CouchBase
    *   R2DBC
    *   NOTE: There is not an official implementation for JDBC / Oracle database. See later

  

<table class="wrapped confluenceTable"><colgroup><col></colgroup><tbody><tr><th class="confluenceTh"><strong>WebFlux Reactor =&nbsp; Spring Boot + Reactor library +&nbsp; Async I/O communication modules</strong></th></tr></tbody></table>

  
 

## Why and When Reactive Programming is good idea?
 

In the context of a Web Service, let's compare a traditional approach (_Thread-per-request_) vs _reactive_ approach

### _Thread-per-Request_ processing 

  

Java applications have been built over the years following the _Thread-per-Request_  paradigm, in which the **same** thread is used for all operations required for a request, these operations may include:

*   CPU processing operations: the thread in which is executed the request is not blocked, it is "working" all the time 
*   I/O operation (database queries, request to another service): the thread is blocked until the I/O has finished

  

**Consequence**: If the load is high and there are many I/O operations → the number of concurrent threads is high, most of them will be blocked

  

Let's see some interesting related questions:

*   **Does having a lot of  concurrent threads use a lot of memory?** Yes, because the execution context of a single thread requires memory, so having a lot of threads means a lot of memory (potentially)
*   **Is having a lot of concurrent threads  bad for the performance?** Not _per se (_a blocked thread does not consume CPU cycles). However if there are many thread it forces the Operating System to swaps contexts between threads, which is an expensive operation.

  

### _Reactive Programming_

  

In reactive programming, threads are not blocked or waiting for a I/O  to complete. Instead they are notified when the I/O  is complete / the data changes.  which means:

  

<table class="wrapped confluenceTable"><colgroup><col style="width: 528.0px;"></colgroup><tbody><tr><th class="confluenceTh"><span data-colorid="dv2v52gx30"><strong>less threads are required → less resources are required to process the same&nbsp;</strong></span></th></tr></tbody></table>

The problem with Reactive Programming is the code usually is more complex → difficult to maintain and to extend


<table class="wrapped confluenceTable"><colgroup><col></colgroup><tbody><tr><th class="confluenceTh"><strong>is good idea to use WebFlux Reactor ???&nbsp;&nbsp;</strong></p><p>My opinion:&nbsp; If there is a lot of potentially blocking I/O operations then it would be good idea, otherwise stick in the<em> traditional way (not reactive)</strong></th></tr></tbody></table>

 

## Digging deeper in WebFlux Reactor
 

  

In order to understand how to build a WebFlux Reactor application, it is necessary to master the following concepts:

  

*   Types [Mono](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html) and [Flux](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) of the Reactor library → These types provides most of the Reactive functionality.
*   Exceptions / Timeouts while executing Mono or Flux
*   Blocking scenario
*   Web Applications: Reactive RestController / WebClient 
*   Reactive Repositories: to avoid blocking operations on these repositories

Besides it is interesting to understand the [Scheduler](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Scheduler.html) interface, which is a part of the Reactor library and provides  thread pool management.

  

We'll see all these concepts in detail below.

Mono
----

 It represents a Publisher that can emit _0..1_ element.

  

We can think of a Mono<T> as object that has:

*   [Consumer](https://docs.oracle.com/javase/8/docs/api/java/util/function/Consumer.html) object which is actually a  method of executable "code" that receives a a parameter a value of type T → this "code" can be provided as lambda function or method reference
*   one method call _subscribe_ 

  

As soon as the _subscribe_ method is invoke, the Mono will generate a value of type T and this value will be passed to the executable "code", in asynchronous way

In other words, a Mono<T> as a component **Publisher** that WILL _publish_ a value of type T to a provided handler (**Subscriptor**) when its method _subscribe_ is invoked. 

  

What value will it publish? well it depends on the Mono creator, for example if the Mono is created by the Reactive WebClient, the value will be the response of the performed request.

  

  

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro5712504691010265070", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=0debdf93-3f71-4b00-b634-264822ade962&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro5712504691010265070&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"0debdf93-3f71-4b00-b634-264822ade962\\",\\"id\\":\\"0debdf93-3f71-4b00-b634-264822ade962\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"0debdf93-3f71-4b00-b634-264822ade962\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\"1 Mono\\u003cEmployee\\u003e monoEmployee= getEmployeeMonoByNameUsingReactiveWebClient(\\\\\\"http://localhost:8080/demo?name=\\\\\\" + employeeN\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"0debdf93-3f71-4b00-b634-264822ade962\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

Please note:

*   if _subscribe_ method is not invoked nothing happens
*   the handler is normally executed in a different thread (see detail later), in the following example it means that line 13 could be executed before line 7
*   The generation of value of type T  implies that something has to do, in the case of Reactive Webclient it means to perform the actual request to the server...

  

  

### Operators

[The official Documentation explains very well all operat](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html)[ors](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html)

#### Map

transform the Mono by building another Mono

  

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro8205230643481613260", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=24cad579-7d93-48ed-9159-501436abe368&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro8205230643481613260&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"24cad579-7d93-48ed-9159-501436abe368\\",\\"id\\":\\"24cad579-7d93-48ed-9159-501436abe368\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"24cad579-7d93-48ed-9159-501436abe368\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" Mono\\u003cEmployee\\u003e monoEmployee= getEmployeeMonoByNameUsingReactiveWebClient(\\\\\\"http://localhost:8080/demo?name=\\\\\\" + employeeNa\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"24cad579-7d93-48ed-9159-501436abe368\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

#### FlatMap

transform the Mono by chaining another existing Mono

  

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro2738822046838682449", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=9d9f236b-d636-47cc-bb29-00da7b7a1e7f&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro2738822046838682449&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"9d9f236b-d636-47cc-bb29-00da7b7a1e7f\\",\\"id\\":\\"9d9f236b-d636-47cc-bb29-00da7b7a1e7f\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"9d9f236b-d636-47cc-bb29-00da7b7a1e7f\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\"1 Mono\\u003cEmployee\\u003e monoEmployee= getEmployeeMonoByNameUsingReactiveWebClient(\\\\\\"http://localhost:8080/demo?name=\\\\\\" + employeeN\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"9d9f236b-d636-47cc-bb29-00da7b7a1e7f\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

  

#### Zip

This operator combines two or more Mono→ subscribes to all Monos  and builds a new one as a result of the combination

  

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro3103253244765128072", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=bf117d1b-525a-4da6-bc45-ee3127c366d3&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro3103253244765128072&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"bf117d1b-525a-4da6-bc45-ee3127c366d3\\",\\"id\\":\\"bf117d1b-525a-4da6-bc45-ee3127c366d3\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"bf117d1b-525a-4da6-bc45-ee3127c366d3\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" Mono\\u003cEmployee\\u003e monoEmployee= getEmployeeMonoByNameUsingReactiveWebClient(\\\\\\"http://localhost:8080/demo?name=\\\\\\" + employeeNa\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"bf117d1b-525a-4da6-bc45-ee3127c366d3\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

Flux
----

 It represents a stream that can emit _0..n_ elements. 

The idea is the similar to Mono but with n elements

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro8266510425434823839", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=fc05100c-656d-4f05-8a88-02471b0cb50d&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro8266510425434823839&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"fc05100c-656d-4f05-8a88-02471b0cb50d\\",\\"id\\":\\"fc05100c-656d-4f05-8a88-02471b0cb50d\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"fc05100c-656d-4f05-8a88-02471b0cb50d\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" \\\\n Flux\\u003cInteger\\u003e salariesFlux = getSalariesOfAllEmployeesFlux();\\\\n \\\\n \\\\n salariesFlux.subscribe(\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"fc05100c-656d-4f05-8a88-02471b0cb50d\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

[The official Documentation explains very well all operat](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html)[ors](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html)

  

Exceptions  / timeout
---------------------

  

There are some operators to deal with exceptions happening inside of a callback, most common used:

*   **_doOnError_**
*   **_onErrorResume_**

  

The operator _**timeout**_ will propagate a  _[java.util.concurrent.TimeoutException](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/TimeoutException.html)_

  

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro4957236434907934535", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=abf56a26-1c28-4f50-b6c7-732c5e794a9b&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro4957236434907934535&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"abf56a26-1c28-4f50-b6c7-732c5e794a9b\\",\\"id\\":\\"abf56a26-1c28-4f50-b6c7-732c5e794a9b\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"abf56a26-1c28-4f50-b6c7-732c5e794a9b\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" String valueString = \\\\\\"text\\\\\\";\\\\n long millSleep=1000;\\\\n \\\\n Mono\\u003cInteger\\u003e valueIntMono = Mono.just(valueS\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"abf56a26-1c28-4f50-b6c7-732c5e794a9b\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

  

Blocking scenario
-----------------

block(): Subscribe to this [`Mono`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Mono.html "class in reactor.core.publisher") and **block indefinitely** until a next signal is received.

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro4832314938251143732", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=4649374e-4286-4b5f-b08e-6c8653b088c3&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro4832314938251143732&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"4649374e-4286-4b5f-b08e-6c8653b088c3\\",\\"id\\":\\"4649374e-4286-4b5f-b08e-6c8653b088c3\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"4649374e-4286-4b5f-b08e-6c8653b088c3\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" String valueString = \\\\\\"12\\\\\\";\\\\n long millSleep=100;\\\\n \\\\n Mono\\u003cInteger\\u003e valueIntMono = Mono.just(valueStri\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"4649374e-4286-4b5f-b08e-6c8653b088c3\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

Schedulers
----------

  

If the previous are executed, it is easy to check that the thread being used to execute the asynchronous code is actually the same thread that is running the main flow, which means that is not working really in a synchronous way, the reason is we have to provide a Thread Pool to execute async tasks

This is done by [Schedulers](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Schedulers.html), 

  

In order to define a Scheduler, there are some predefined configurations

*   [`parallel()`](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Schedulers.html#parallel--): Optimized for fast [`Runnable`](https://docs.oracle.com/javase/8/docs/api/java/lang/Runnable.html?is-external=true "class or interface in java.lang") non-blocking executions
*   [`single()`](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Schedulers.html#single--): Optimized for low-latency [`Runnable`](https://docs.oracle.com/javase/8/docs/api/java/lang/Runnable.html?is-external=true "class or interface in java.lang") one-off executions
*   [`elastic()`](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Schedulers.html#elastic--): Optimized for longer executions, an alternative for blocking tasks where the number of active tasks (and threads) can grow indefinitely
*   [`boundedElastic()`](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Schedulers.html#boundedElastic--): Optimized for longer executions, an alternative for blocking tasks where the number of active tasks (and threads) is capped
*   [`immediate()`](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Schedulers.html#immediate--): to immediately run submitted [`Runnable`](https://docs.oracle.com/javase/8/docs/api/java/lang/Runnable.html?is-external=true "class or interface in java.lang") instead of scheduling them (somewhat of a no-op or "null object" [`Scheduler`](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Scheduler.html "interface in reactor.core.scheduler"))
*   [`fromExecutorService(ExecutorService)`](https://projectreactor.io/docs/core/release/api/reactor/core/scheduler/Schedulers.html#fromExecutorService-java.util.concurrent.ExecutorService-) to create new instances around [`Executors`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/Executors.html?is-external=true "class or interface in java.util.concurrent")

  

or configurable:

  
Once the Scheduler is defined, it is possible to set it to be used by a Mono or Flux using the method _**publishOn**_  or **_SubscribeOn_**

  

*   **_publishOn_**:  It affects subsequent operators after `publishOn` - from that point the code will be executed by a thread picked from `publishOn`'s scheduler.
*   **_subscribeOn_**: similar to publishOn, but it affects  all the chain (before and after) `subscribeOn`

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro7073087223118682543", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=88ee7d4e-93b8-485a-b166-b3633cf0defb&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro7073087223118682543&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"88ee7d4e-93b8-485a-b166-b3633cf0defb\\",\\"id\\":\\"88ee7d4e-93b8-485a-b166-b3633cf0defb\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"88ee7d4e-93b8-485a-b166-b3633cf0defb\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\"1 Scheduler schedulerA = Schedulers.newParallel(\\\\\\"publisherThreads\\\\\\",2);\\\\n2\\\\n3 \\\\n4 Flux\\u003cInteger\\u003e numberFlux = Fl\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"88ee7d4e-93b8-485a-b166-b3633cf0defb\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

as it is the block

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro1267353839049048753", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=4982bc77-e039-43cc-a767-bc1fc247172e&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro1267353839049048753&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"4982bc77-e039-43cc-a767-bc1fc247172e\\",\\"id\\":\\"4982bc77-e039-43cc-a767-bc1fc247172e\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"4982bc77-e039-43cc-a767-bc1fc247172e\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\"Flux element - (1), Thread: main\\\\nFlux element - (2), Thread: main\\\\nExecution continues\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"false\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"4982bc77-e039-43cc-a767-bc1fc247172e\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

commenting line 4 and uncommenting line 5

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro7941746317290596911", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=1673cfda-fdf3-4510-9250-e4e736db4ef7&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro7941746317290596911&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"1673cfda-fdf3-4510-9250-e4e736db4ef7\\",\\"id\\":\\"1673cfda-fdf3-4510-9250-e4e736db4ef7\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"1673cfda-fdf3-4510-9250-e4e736db4ef7\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\"ExecutionContinues\\\\nFlux element - (1), Thread: publisherThreads-1\\\\nFlux element - (2), Thread: publisherThreads-1\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"false\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"1673cfda-fdf3-4510-9250-e4e736db4ef7\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

  

**Reactive Web Server**
-----------------------

  

Let's see how it works in a nutshell:

1.  the incoming HTTP request is received by the reactive engine implementation (netty / Undertow / Servlet 3.1)
2.  Spring will pass to the corresponding controller method the parameters → this method will be executed and return a Mono or Flux → Please note that the thread in which this is executed is never blocked
3.  the reactive engines will **suscribe**  to that Mono/Flux 
4.  Once the Mono/Flux has emitted all data (by invoking the consumer), the reactive server will send it back to the client

  

Note: No thread is blocked in this mechanism

  

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro600545463364513620", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=9dc74032-debe-4a3b-a953-a3f3a6538d0f&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro600545463364513620&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"9dc74032-debe-4a3b-a953-a3f3a6538d0f\\",\\"id\\":\\"9dc74032-debe-4a3b-a953-a3f3a6538d0f\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"9dc74032-debe-4a3b-a953-a3f3a6538d0f\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\"@RestController\\\\n@RequestMapping(\\\\\\"/employees\\\\\\")\\\\npublic class EmployeeController {\\\\n\\\\n\\\\t@Autowired\\\\n EmployeeRepository employeeRepo\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"9dc74032-debe-4a3b-a953-a3f3a6538d0f\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

Web Client
----------

Spring WebFlux offers a reactive version of the web client

  

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro27127405579185968", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=31ba47ae-4166-44e8-a163-644fa03f4951&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro27127405579185968&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"31ba47ae-4166-44e8-a163-644fa03f4951\\",\\"id\\":\\"31ba47ae-4166-44e8-a163-644fa03f4951\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"31ba47ae-4166-44e8-a163-644fa03f4951\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" WebClient client = WebClient.create(\\\\\\"http://localhost:8080\\\\\\");\\\\n Mono\\u003cEmployee\\u003e employeeMono = client.get().uri(\\\\\\"/employees/{\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"31ba47ae-4166-44e8-a163-644fa03f4951\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

**Redis**
---------

Example to **Get** an element, please notice the usage of operator _switchIfEmpty_ to deal with non existing entries

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro5448558742028897851", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=c2cf150e-9e2c-4ab5-8e5b-4f2ddcdfe879&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro5448558742028897851&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"c2cf150e-9e2c-4ab5-8e5b-4f2ddcdfe879\\",\\"id\\":\\"c2cf150e-9e2c-4ab5-8e5b-4f2ddcdfe879\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"c2cf150e-9e2c-4ab5-8e5b-4f2ddcdfe879\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" @Autowired\\\\n ReactiveRedisTemplate\\u003cString, Employee\\u003e pageRedisTemplate;\\\\n\\\\n\\\\t// retrieve elements\\\\n Mono\\u003cEmployee\\u003e employee\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"c2cf150e-9e2c-4ab5-8e5b-4f2ddcdfe879\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

Example to **Set** element

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro1677390605037494012", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=167883e4-0f1a-4815-8f3f-7663ec93d083&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro1677390605037494012&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"167883e4-0f1a-4815-8f3f-7663ec93d083\\",\\"id\\":\\"167883e4-0f1a-4815-8f3f-7663ec93d083\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"167883e4-0f1a-4815-8f3f-7663ec93d083\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\"\\\\t// key is id\\\\n \\\\n pageRedisTemplate.opsForValue().set(id, employee, cachePagedurationsecondsDuration).map(result -\\u003e employee)\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"167883e4-0f1a-4815-8f3f-7663ec93d083\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

**Database**
------------

There is not official implementation for a Reactive Oracle JDBC driver. However, there is an implementation of a programmer (Dave Moten)

[https://github.com/davidmoten/rxjava2-jdbc](https://github.com/davidmoten/rxjava2-jdbc)

Last commit on this library is 13-October-2020

Some known problems:

*   It is not possible to use a block() operator on a Mono/Flux returned by the library if it used a Reactive Datasource

  

  

  

Developing Applications with WebFlux Reactor
============================================

  

*   You can "mix" reactivity approach and "classical" approach in the same application, for example in Powersearch: 
    *   All code to manage searches is implemented in a **reactive** way
    *   Queries to database to tefresh of local caches that happens every 10 minutes are performed in a **no reactive** way

  

*   Broadly speaking, your code will be just a chains" of linked Mono/Flux  with map / flatMap:  
    *   You don't have to worry about Schedulers because they will be managed by  SpringWebFlux
    *   Be careful and write "clean code": a method shouldn't have more than 3 concatenated map/flatMap/zip 

  

*   Write short lambdas (SonarLint has a parameter to limit that) or refactor the code in a external method → the code is cleaner

  

*   Learn from the reference: There are many operators for Mono/Flux, all of them are well explained in the documentation

  

*   Good Practice → name references to Mono properly, put the name "mono" as part of the reference name

//<!\[CDATA\[ (function(){ var data = { "addon\_key":"com.atlassian.connect.better-code-macro.prod", "uniqueKey":"com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro767641895060685268", "key":"paste-code-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://cloud-code-macro.services.atlassian.com/macro/paste-code-macro?page\_id=4605476983&macro\_id=075ea125-35f0-4310-8426-6002d153745a&page\_version=1&output\_type=html\_export&theme=&language=java&title=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.atlassian.connect.better-code-macro.prod\_\_paste-code-macro767641895060685268&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.atlassian.connect.better-code-macro.prod&lic=none&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"confluence\\":{\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"075ea125-35f0-4310-8426-6002d153745a\\",\\"id\\":\\"075ea125-35f0-4310-8426-6002d153745a\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"1\\",\\"id\\":\\"4605476983\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4605476983\\",\\"macro.hash\\":\\"075ea125-35f0-4310-8426-6002d153745a\\",\\"space.key\\":\\"~117741573\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"1\\",\\"page.title\\":\\"Copy of Reactive Programming with WebFlux Reactor (part I)\\",\\"macro.localId\\":\\"\\",\\"language\\":\\"java\\",\\"macro.body\\":\\" Mono\\u003cEmployee\\u003e monoEmployee = ....\\",\\": = | RAW | = :\\":\\"language=java\\",\\"space.id\\":\\"1352302837\\",\\"macro.truncated\\":\\"false\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"1\\",\\"content.id\\":\\"4605476983\\",\\"macro.id\\":\\"075ea125-35f0-4310-8426-6002d153745a\\",\\"user.isExternalCollaborator\\":\\"false\\"}", "timeZone":"UTC", "origin":"https://cloud-code-macro.services.atlassian.com", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }()); //\]\]>

  

  

  

Attachments:
------------

![](images/icons/bullet_blue.gif) [Example.png](attachments/4605476983/4605477010.png) (image/png)  
![](images/icons/bullet_blue.gif) [image2021-4-30\_14-44-25.png](attachments/4605476983/4605477013.png) (image/png)  
![](images/icons/bullet_blue.gif) [image2021-4-30\_13-43-47.png](attachments/4605476983/4605477016.png) (image/png)  

Document generated by Confluence on Jan 13, 2024 06:48

[Atlassian](http://www.atlassian.com/)
