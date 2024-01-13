# Logging Policy

 
Introduction
============

Broadly speaking, logging policy is often a controversial issue in software engineering.

The amount of log generated in services receiving thousand of request in a short period of time may have an impact in terms of:

*   **space to save the logs**: the amount of space is finite and expensive
    
*   **reduced capability to exploit these logs using tools like kibana** 
    
*   **performance**: services and its underlying infrastructure may have an impact on performance
    

Based on this,  the following is a guideline to address and mitigage these issues

Log level
---------

Typically, there are four log levels to be used:

*   **INFO**: to be used when everything goes smoothly, nothing unexpected happened
    

*   **WARN**: to be used when something **unexpected** happened, but this doesn’t prevent to continue the execution, in other words, when there is a scenario that brokes the implicit or explicit _contract_ but there is a “way out” of the problem, perhaps by assuming default values or behaviour.
    

*   **ERROR:** something **unexpected** happened that prevented the execution
    

*   **TRACE / DEBUG**: to be used to describe relevant data or execution flow that may help the developer to find out a problem or explain a behaviour. The differences between TRACE and DEBUG are subtle.
    

### Log amount

Code may fall into two categories:

#### Infrequently executed code

*   this code is typically executed at startup time or in periodic tasks
    

*   Rule of thumb:
    
    *   use **INFO** / **WARN** / **ERROR**
        
    *   only detailed data or subtle details in **DEBUG / TRACE.**
        

#### Frequently executed code

*   this code is typically executed in services processing many requests/events per second.
    
*   Rule of thumb:
    
    *   use **TRACE/DEBUG** as many times as necessary
        
    *   use **WARN** as many times as necessary
        
    *   After finishing the request execution there will only be **ONE** log line that summarizes the request. It should include data such as relevant parameters/headers, response time and status code. The log level will be one of the following:
        
        *   **INFO**: if everything went well, the contract is matched 100%
            
        *   **ERROR**: if an error that prevented the execution happened. **ReasonCode** must be included in the log as well as the full stack trace or the exception message
            
        *   **WARN**: There is a _controlled_ situation that prevents to process the **expected** flow. Please keep in mind that by definion, if the situation is _controlled_, then it can not log as an **ERROR.** Examples**:**
            
            *   if the incoming request parameters “break” the _contract_ of the endpoint or process, for example, a mandatory field is not sent, an incorrect authentication token…
                
            *   in order to process the incoming request, the service requires another service to be up and running, but that is not the case and this is managed in a custom manner.
                

 
  As explained, there will be only one log line that summarizes the request execution, which could be <strong>INFO</strong>, <strong>ERROR</strong> or <strong>WARN</strong>.</p><p>Typically this log will be written by the top class of the execution hierarchy, which is normally a <strong>Controller</strong> or <strong>Handler</strong>
 



Following logs of the same request / task
-----------------------------------------

In non reactive environments it is easy to follow all the logs of a particular request because they will log the executing **threadId**, which is the same in all lifecycle of the request.

In reactive environments specially (Ratpack or WebFluxReactor), the **threadId** can not be used to follow the lines of logs because the executing thread may change and that is a problem, the solution is to used a **Identifier of the request**

### **WebFlux Reactor**

Althoug WebFlux creates a particular logId for every request, it is much better to use [Sleuth]([https://mirada.atlassian.net/wiki/spaces/BAC/pages/3965353985/Sleuth+for+Tracing](https://spring.io/projects/spring-cloud-sleuth/)) , which manages automatically the logging in to the reactive chain and much much more interesting features.

### **Ratpack**

logId can be retrieved from context

```groovy
import ratpack.handling.Context;
...
String logId = ((RequestId) context.get(RequestId.class)).toString();
...
```

However, the recommended approach is to integrate with [Sleuth Headers](https://mirada.atlassian.net/wiki/spaces/BAC/pages/3965353985/Sleuth+for+Tracing#Integrating-in-a-existing-no-WebFlux-Project)

#### MDC for Ratpack

One way to preserve the requestId troughout the context of the request is by using the [MDC](https://www.slf4j.org/api/org/slf4j/MDC.html) class for adding _diagnosis context._ More about its usage [here](https://logback.qos.ch/manual/mdc.html). Basically it offers a Map which will be preserved in the context thread, and then used in the logging. Since in frameworks like Webflux and Ratpack the threads can be switched between executions of the same request, you would need to take into account and refer to official documentation about how to setup MDC correctly.

![](images/icons/grey_arrow_down.png)Ratpack

```java
registry
.add(MDCInterceptor.withInit(e ->
    e.maybeGet(RequestId.class).ifPresent(requestId ->
        MDC.put("requestId", requestId.toString())
    )
))
```

Webflux: [stackoverflow](https://stackoverflow.com/a/67421363) and [official doc](https://github.com/reactor/reactor-core/blob/main/docs/asciidoc/faq.adoc#what-is-a-good-pattern-for-contextual-logging-mdc)

Then, you need to configure the logger pattern, to add the MDC property (`%X{requestId}`), for example:  
`logging.pattern.console=%d{yyyy-MM-dd'T'HH:mm:ss.SSSZ} [%thread] %-5level %logger{36} - [%X{requestId}] - %marker - %msg%n`

Markers
-------

Markers are **standard** way to _mark_ a group of one or more lines of logs by a certain criterion, for example logic blocks of code or functionality.

It allows to analyse and understand easily the log _chaos._

Markers are defined in _slf4j_, which means almost all java implementations support them, including our (Mirada log library).

The logging pattern in all sdp services includes Markers

```groovy
logging.pattern.console=%d{yyyy-MM-dd'T'HH:mm:ss.SSSZ} [%thread] %-5level %logger{36} - %marker - %msg%n
```
…


The interesting thing is that a Marker is an object that can be passed as parameter, so it can be used in “general” methods

```groovy
public class Indexer {
 public static Marker INDEXER_MARKER = MarkerFactory.getMarker("INDEXER");
 
 ...

 @Autowired
 HttpService httpService;   // this is a common service

 ...
 
 public void beginIndex() {
   LOG.debug(INDEXER_MARKER, "Beginning indexing...");
   ...
   httpService.doPost(INDEXER_MARKER, "http://localhost:8981/solr/powersearch", data);
   ...
   
 }

}
```

```groovy
public class HttpService {

  public doPost(Marker marker, String url, String data) {
  
  ...
  
  LOG.debug(marker, "doPost operation successful ...");
  
  }

}
```


Avoid printing useless stack trace lines
----------------------------------------

Sometimes we need to show more than only the error message, for example when an unexpected error has occurred. In these cases, a huge amount of stack trace lines from different external libraries and frameworks are usually displayed, which do not have any relevant information and may even lead to some confusion when trying to trace the source of the problem.

There is a simple solution for this problem: add regular expressions in the log pattern configuration to exclude them from the log when stacktrace lines are displayed.

Check more information in about this feature in the [logback documentation](https://logback.qos.ch/manual/layouts.html#ex).

Don’t log and throw Exception
-----------------------------

Avoid this antipattern

<table data-table-width="760" data-layout="default" data-local-id="fd258021-5ca7-4d5c-8704-2a2e10afef2c" class="confluenceTable"><colgroup><col style="width: 680.0px;"></colgroup><tbody><tr><td data-highlight-colour="initial" class="confluenceTd"><div class="code panel pdl" style="border-width: 1px;"><div class="codeContent panelContent pdl"><pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: groovy; gutter: false; theme: Default" data-theme="Default">try {
&nbsp;
&nbsp;&nbsp;// do some logic
&nbsp;
} catch (JsonProcessingException e) {
&nbsp;&nbsp;log.error("Problem converting ...",e);
&nbsp;&nbsp;throw e;
}</pre></div></div></td></tr></tbody></table>

Ideally replace it by

<table data-table-width="760" data-layout="default" data-local-id="b284e275-bde7-4416-9645-f133771ce69e" class="confluenceTable"><colgroup><col style="width: 680.0px;"></colgroup><tbody><tr><td data-highlight-colour="initial" class="confluenceTd"><div class="code panel pdl" style="border-width: 1px;"><div class="codeContent panelContent pdl"><pre class="syntaxhighlighter-pre" data-syntaxhighlighter-params="brush: groovy; gutter: false; theme: Default" data-theme="Default">try {
&nbsp;
&nbsp;&nbsp;// do some logic
&nbsp;
} catch (JsonProcessingException e) {
&nbsp;&nbsp;throw new MyBusinessException("Problem converting ...", e);
}</pre></div></div></td></tr></tbody></table>

where `MyBusinessException` is a custom exception which gives much more semantic meaning.

This exception should be catched properly at the corresponding level and will trace there according to the aforementioned rules

Good practices
--------------

There are not universal rules

As a rule of thumb → Log or Propagate ONLY thing that provides information !!!!

### Controlled situation (warning) ignoring exception

At some point we need to retrieve recordings from TvRecord, but there is an error in the returned json

The business rules tell us that if for somereason recordings can not be retrieved, then assume No recordings

```groovy
List<Recording> getRecordingsFromJson(String jsonRecording) {

  try {
	return Arrays.asList(objectMapper.readValue(jsonRecording, Recording.class));
  } catch (JsonProcessingException e) {
     // Logging the whole original stack trace exception does not provide information
     
	 	Log.warn("can not deserialize json {}. Cause={} From this point assuming no recordings", 
				jsonRecording, 
				e.getMessage());
				
	 return Collection.emptyList();
  }

}
```

### Controlled situation (error) ignoring original exception

The business rules tells us that if for some reason recordings can not be retrieved, then it can not follow with the execution → error

```groovy
List<Recording> getRecordingsFromJson(String jsonRecording) {

  try {
	return Arrays.asList(objectMapper.readValue(jsonRecording, Recording.class));
  } catch (JsonProcessingException e) {
    // original exception is not added as cause because it Does not provides information?
    throws new RecordingException("can not deserialize json " + jsonRecording + " because:" + e.getMessage());
  }

}
```

### UnControlled situation (error)

In this case it make sense to add as a cause the original exception as it can help us to see the actual problem

As a rule of thumb → if catch general `Exception` rather than a specific one, then it is good idea to add it as a cause

```groovy
indexSolr() {
   try {
			List<Content> contentList = hollowMetadataLoader.getContent();
			...
			List<Document> documentList = createDocumentsFromContent(contentList);
   
   } catch (Exception e) {
		throw new IndexSolrException("Can not index Solr",e)
}
  
```

APPENDIX: Exception chaining in Java
------------------------------------

Java keeps the whole exception chain when logging

```groovy
package tv.mirada.iris.sdp.search.test;

/* this is a just a quick sample to prove how Java chains exceptions 
without any external library
in a real project don't log with System.out.println or print stack track
using e.printStackTrace()
*/

public class Test {

    public static void main (String args[]) {
        try {
            method1();            
        } catch (Exception e) {
            e.printStackTrace();
        }        
    }

    public static void method1() {
        try {
            System.out.println("init method 1");
            method2();
            System.out.println("end method 1");
        } catch (Exception e) {
            throw new Sample1Exception("Exception method 1", e);
        }
    }

    public static void method2() {
        System.out.println("init method 2");
        throw new Sample2Exception("Exception method 2");
    }
}
```

Result:

```groovy
init method 1
init method 2
tv.mirada.iris.sdp.search.test.Sample1Exception: Exception method 1
	at tv.mirada.iris.sdp.search.test.Test.method1(Test.java:19)
	at tv.mirada.iris.sdp.search.test.Test.main(Test.java:7)
Caused by: tv.mirada.iris.sdp.search.test.Sample2Exception: Exception method 2
	at tv.mirada.iris.sdp.search.test.Test.method2(Test.java:25)
	at tv.mirada.iris.sdp.search.test.Test.method1(Test.java:16)
	... 1 more
```

But cleverly enough, Java avoids to repeat stack trace lines

(1.. more) is actually:

`at tv.mirada.iris.sdp.search.test.Test.main(Test.java:7)`
