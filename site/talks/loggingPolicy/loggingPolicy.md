\[data-colorid=zek7472mcl\]{color:#bf2600} html\[data-color-mode=dark\] \[data-colorid=zek7472mcl\]{color:#ff6640}\[data-colorid=eigiwr8hpf\]{color:#bf2600} html\[data-color-mode=dark\] \[data-colorid=eigiwr8hpf\]{color:#ff6640}

WORK IN PROGRESS

/\*<!\[CDATA\[\*/ div.rbtoc1705128497066 {padding: 0px;} div.rbtoc1705128497066 ul {list-style: disc;margin-left: 0px;} div.rbtoc1705128497066 li {margin-left: 0px;padding-left: 0px;} /\*\]\]>\*/

*   [Introduction](#CopyofLogPolicy-Introduction)
    *   [Log level](#CopyofLogPolicy-Loglevel)
        *   [Log amount](#CopyofLogPolicy-Logamount)
            *   [Infrequently executed code](#CopyofLogPolicy-Infrequentlyexecutedcode)
            *   [Frequently executed code](#CopyofLogPolicy-Frequentlyexecutedcode)
    *   [Following logs of the same request / task](#CopyofLogPolicy-Followinglogsofthesamerequest/task)
        *   [WebFlux Reactor](#CopyofLogPolicy-WebFluxReactor)
        *   [Ratpack](#CopyofLogPolicy-Ratpack)
            *   [MDC for Ratpack](#CopyofLogPolicy-MDCforRatpack)
    *   [Markers](#CopyofLogPolicy-Markers)
    *   [Use lambdas](#CopyofLogPolicy-Uselambdas)
    *   [Avoid printing useless stack trace lines](#CopyofLogPolicy-Avoidprintinguselessstacktracelines)
        *   [Example](#CopyofLogPolicy-Example)
    *   [Don’t log and throw Exception](#CopyofLogPolicy-Don’tlogandthrowException)
    *   [Good practices](#CopyofLogPolicy-Goodpractices)
        *   [Controlled situation (warning) ignoring exception](#CopyofLogPolicy-Controlledsituation(warning)ignoringexception)
        *   [Controlled situation (error) ignoring original exception](#CopyofLogPolicy-Controlledsituation(error)ignoringoriginalexception)
        *   [UnControlled situation (error)](#CopyofLogPolicy-UnControlledsituation(error))
    *   [APPENDIX: Exception chaining in Java](#CopyofLogPolicy-APPENDIX:ExceptionchaininginJava)

Introduction
============

Broadly speaking, logging policy is often a controversial issue in software engineering.

The amount of log generated in services receiving thousand of request in a short period of time, like some of the existing in Mirada, may have an impact in terms of:

*   **space to save the logs**: the amount of space is finite and expensive
    
*   **reduced capability of the tool to exploit these logs (kibana)**: at the moment only 2 days can be queried
    
*   **performance**: services and its underlying infrastructure (kubernetes) may have an impact on performance
    

Based on the premise that Mirada services uses Mirada log library, the following is a guideline to address these issues

Log level
---------

Four levels will be used:

*   **INFO**: to be used when everything goes smoothly, nothing unexpected happened
    

*   **WARN**: to be used when something **unexpected** happened, but this doesn’t prevent to continue the execution, in other words, when there is a scenario that brokes the implicit or explicit _contract_ but there is a “way out” of the problem, perhaps by assuming default values or behaviour.
    

*   **ERROR:** something **unexpected** happened that prevented the execution
    

*   **TRACE / DEBUG**: to be used to describe relevant data or execution flow that may help the developer to find out a problem or explain a behaviour. The differences between TRACE and DEBUG are subtle.
    

<table data-table-width="760" data-layout="default" data-local-id="3c3f9ed7-6bc8-4769-8755-ce3857efd113" class="confluenceTable"><colgroup><col style="width: 253.0px;"></colgroup><tbody><tr><th class="confluenceTh"><p><strong>ERROR / WARN </strong>will be enabled in PRODUCTION at all times</p><p><strong>INFO</strong> will be enabled in PRODUCTION if and only if service does not receive massive requests, although they can be enabled if required</p><p><strong>TRACE/DEBUG</strong> won’t be enabled in PRODUCTION by default, although it can be enabled if required</p></th></tr></tbody></table>

### Log amount

Code may fall into two categories:

#### Infrequently executed code

*   this code is typically executed at startup time or in periodic tasks (scheduled task, callbacks after hollow refresh)…
    

*   Rule of thumb:
    
    *   use **INFO** / **WARN** / **ERROR**
        
    *   only detailed data or subtle details in **DEBUG / TRACE.**
        

Keep in mind that by default DEBUG/WARN is disabled, so, if there is a problem at startup time, perhaps there is no time to change the log level to see the trace.

For example library to manage solr schemas automatically (**library-solr-schema-updater)** logs everything in **INFO** because it is only exected once (at startup time).

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
                

<table data-table-width="760" data-layout="default" data-local-id="cdb01d76-d8bc-452e-8410-9aaf9589e962" class="confluenceTable"><colgroup><col style="width: 680.0px;"></colgroup><tbody><tr><th class="confluenceTh"><p>As explained, there will be only one log line that summarizes the request execution, which could be <strong>INFO</strong>, <strong>ERROR</strong> or <strong>WARN</strong>.</p><p>Typically this log will be written by the top class of the execution hierarchy, which is normally a <strong>Controller</strong> or <strong>Handler</strong></p></th></tr></tbody></table>

Following logs of the same request / task
-----------------------------------------

In non reactive environments it is easy to follow all the logs of a particular request because they will log the executing **threadId**, which is the same in all lifecycle of the request.

In reactive environments specially (Ratpack or WebFluxReactor), the **threadId** can not be used to follow the lines of logs because the executing thread may change and that is a problem, the solution is to used a **Identifier of the request**

### **WebFlux Reactor**

Althoug WebFlux creates a particular logId for every request, it is much better to use [Sleuth](https://mirada.atlassian.net/wiki/spaces/BAC/pages/3965353985/Sleuth+for+Tracing) , which manages automatically the logging in to the reactive chain and much much more interesting features.

### **Ratpack**

logId can be retrieved from context, however it is

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

for example:

Powersearch code contains different blocks of functionality:

*   Indexer
    
*   Search API
    
*   TvSearch API
    

…

So all logs belonging to the same “block” are marked with the same marker

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

Use lambdas
-----------

[IB-19559](https://mirada.atlassian.net/browse/IB-19559) - Getting issue details... STATUS

From R11.0 Mirada log library includes lambdas to avoid useless computation.

Note: a typical log sentence evaluates all parameters regardless the log is actually printed or not.

```groovy
log.debug("status {}", calculateStatus());
// if log level = info, the calculateStatus()  method is invoked useless
```

This implies sometimes useless work for the virtual machine.

One way to avoid this is by checking whether a certain log level is enabled

```groovy
if (log.isDebugEnabled()) {
  log.debug("status {}", calculateStatus());
}
```

but this is not clean, it makes code hard to read

Using lambdas is easy and clean

```groovy
log.debug("status {}", () -> calculateStatus());
```

Avoid printing useless stack trace lines
----------------------------------------

Sometimes we need to show more than only the error message, for example when an unexpected error has occurred. In these cases, a huge amount of stack trace lines from different external libraries are usually displayed, which do not have any relevant information and may even lead to some confusion when trying to trace the source of the problem.

There is a simple solution for this problem: add regular expressions in the log pattern configuration to exclude them from the log when stacktrace lines are displayed.

Check more information in about this feature in the [logback documentation](https://logback.qos.ch/manual/layouts.html#ex).

### Example

Typical exception stack trace in a reactor/netty application with our default pattern:

```groovy
logging.pattern.console=%d{yyyy-MM-dd'T'HH:mm:ss.SSSZ} %replace([%X{trackingId}] ){'\\\[\\\] ',''}[%thread] %-5level %logger{36} - %msg%n
```

```groovy
2022-07-20T09:44:07.727+0200 [reactor-http-epoll-4] ERROR t.m.i.s.s.s.response.ResponseService - TVSEARCH - POWERS-ERR-3000 - 455167879 <=== RESULT SEARCH [GET]-/managetv/tvsearch/content/pagedSearch/inspire => TvSearchRequestFromDevice(term=the boys, tvSearchScope=TITLE_AND_CREDITS, onlyFree=null, includeAdult=false, rollUpSeries=true, contentType=VOD, showType=null, excludeLinearDelivery=false, excludeOnDemandDelivery=false, deliveryLimit=0,5,0, ordering=null, jumpType=ORDINAL, jumpTo=null, count=null, view=stb_contents_list_view, identityToken=null, hdrHardwareId=5275342746513798, multiroom=null, deviceId=null, personal=false, pagedSearch=true, pageCount=10, index=null, language=SPA, maxParentalRating=null, partition=null, region=null, requestId=455167879, requestInstant=2022-07-20T07:44:07.462Z). Duration: 248 ms. Status:0, data: {"Cause":"InternalServerError","Duration":248,"HTTPStatus":"INTERNAL_SERVER_ERROR"}
java.lang.UnsupportedOperationException: null
	at java.util.AbstractList.add(AbstractList.java:148)
	Suppressed: reactor.core.publisher.FluxOnAssembly$OnAssemblyException: 
Assembly trace from producer [reactor.core.publisher.MonoMapFuseable] :
	reactor.core.publisher.Mono.map
	tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryExecutorService.querySearch(TvSearchQueryExecutorService.java:26)
Error has been observed at the following site(s):
	|_     Mono.map ⇢ at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryExecutorService.querySearch(TvSearchQueryExecutorService.java:26)
	|_ Mono.flatMap ⇢ at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryEngineService.searchElements(TvSearchQueryEngineService.java:56)
	|_     Mono.map ⇢ at tv.mirada.iris.sdp.search.service.response.ResponseService.toResponseEntity(ResponseService.java:71)
	|_ Mono.timeout ⇢ at tv.mirada.iris.sdp.search.service.response.ResponseService.toResponseEntity(ResponseService.java:94)
Stack trace:
		at java.util.AbstractList.add(AbstractList.java:148)
		at java.util.AbstractList.add(AbstractList.java:108)
		at tv.mirada.iris.sdp.search.service.seriesrollup.SeriesRollupService.rollupSeriesIfRequired(SeriesRollupService.java:62)
		at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryResultNodeService.rollupSeriesIfRequired(TvSearchQueryResultNodeService.java:114)
		at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryResultNodeService.buildTvSearchQueryResultNodes(TvSearchQueryResultNodeService.java:34)
		at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryExecutorService.lambda$0(TvSearchQueryExecutorService.java:29)
		at reactor.core.publisher.FluxMapFuseable$MapFuseableSubscriber.onNext(FluxMapFuseable.java:107)
		at reactor.core.publisher.MonoPeekTerminal$MonoTerminalPeekSubscriber.onNext(MonoPeekTerminal.java:173)
		at reactor.core.publisher.SerializedSubscriber.onNext(SerializedSubscriber.java:89)
		at reactor.core.publisher.FluxTimeout$TimeoutMainSubscriber.onNext(FluxTimeout.java:173)
		at reactor.core.publisher.Operators$MonoSubscriber.complete(Operators.java:1592)
		at reactor.core.publisher.MonoFlatMap$FlatMapInner.onNext(MonoFlatMap.java:241)
		at reactor.core.publisher.FluxMapFuseable$MapFuseableSubscriber.onNext(FluxMapFuseable.java:121)
		at reactor.core.publisher.FluxMapFuseable$MapFuseableSubscriber.onNext(FluxMapFuseable.java:121)
		at reactor.core.publisher.FluxContextStart$ContextStartSubscriber.onNext(FluxContextStart.java:103)
		at reactor.core.publisher.FluxContextStart$ContextStartSubscriber.onNext(FluxContextStart.java:103)
		at reactor.core.publisher.FluxMapFuseable$MapFuseableConditionalSubscriber.onNext(FluxMapFuseable.java:287)
		at reactor.core.publisher.FluxFilterFuseable$FilterFuseableConditionalSubscriber.onNext(FluxFilterFuseable.java:330)
		at reactor.core.publisher.Operators$MonoSubscriber.complete(Operators.java:1592)
		at reactor.core.publisher.MonoCollect$CollectSubscriber.onComplete(MonoCollect.java:145)
		at reactor.core.publisher.FluxMapFuseable$MapFuseableSubscriber.onComplete(FluxMapFuseable.java:144)
		at reactor.core.publisher.FluxPeekFuseable$PeekFuseableSubscriber.onComplete(FluxPeekFuseable.java:270)
		at reactor.core.publisher.FluxPeekFuseable$PeekFuseableSubscriber.onComplete(FluxPeekFuseable.java:270)
		at reactor.core.publisher.FluxMapFuseable$MapFuseableSubscriber.onComplete(FluxMapFuseable.java:144)
		at reactor.netty.channel.FluxReceive.terminateReceiver(FluxReceive.java:414)
		at reactor.netty.channel.FluxReceive.drainReceiver(FluxReceive.java:204)
		at reactor.netty.channel.FluxReceive.onInboundComplete(FluxReceive.java:362)
		at reactor.netty.channel.ChannelOperations.onInboundComplete(ChannelOperations.java:363)
		at reactor.netty.channel.ChannelOperations.terminate(ChannelOperations.java:412)
		at reactor.netty.http.client.HttpClientOperations.onInboundNext(HttpClientOperations.java:556)
		at reactor.netty.channel.ChannelOperationsHandler.channelRead(ChannelOperationsHandler.java:93)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:374)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:360)
		at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:352)
		at io.netty.handler.codec.MessageToMessageDecoder.channelRead(MessageToMessageDecoder.java:102)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:374)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:360)
		at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:352)
		at io.netty.channel.CombinedChannelDuplexHandler$DelegatingChannelHandlerContext.fireChannelRead(CombinedChannelDuplexHandler.java:438)
		at io.netty.handler.codec.ByteToMessageDecoder.fireChannelRead(ByteToMessageDecoder.java:326)
		at io.netty.handler.codec.ByteToMessageDecoder.channelRead(ByteToMessageDecoder.java:300)
		at io.netty.channel.CombinedChannelDuplexHandler.channelRead(CombinedChannelDuplexHandler.java:253)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:374)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:360)
		at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:352)
		at io.netty.channel.DefaultChannelPipeline$HeadContext.channelRead(DefaultChannelPipeline.java:1422)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:374)
		at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:360)
		at io.netty.channel.DefaultChannelPipeline.fireChannelRead(DefaultChannelPipeline.java:931)
		at io.netty.channel.epoll.AbstractEpollStreamChannel$EpollStreamUnsafe.epollInReady(AbstractEpollStreamChannel.java:792)
		at io.netty.channel.epoll.EpollEventLoop.processReady(EpollEventLoop.java:502)
		at io.netty.channel.epoll.EpollEventLoop.run(EpollEventLoop.java:407)
		at io.netty.util.concurrent.SingleThreadEventExecutor$6.run(SingleThreadEventExecutor.java:1050)
		at io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74)
		at io.netty.util.concurrent.FastThreadLocalRunnable.run(FastThreadLocalRunnable.java:30)
		at java.lang.Thread.run(Thread.java:748)
```

Defining the logging pattern in the _application.properties_ file as follows:

```groovy
logging.pattern.console=%d{yyyy-MM-dd'T'HH:mm:ss.SSSZ} [%thread] %-5level %logger{36} - %marker - %msg%n%ex{\
        full,\
        io.netty,\
        reactor.netty,\
        reactor.core}
```

the stack trace is reduced about 4 times, reducing useless lines:

```groovy
java.lang.UnsupportedOperationException: null
	at java.util.AbstractList.add(AbstractList.java:148)
	Suppressed: reactor.core.publisher.FluxOnAssembly$OnAssemblyException: 
Assembly trace from producer [reactor.core.publisher.MonoMapFuseable] :
	reactor.core.publisher.Mono.map
	tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryExecutorService.querySearch(TvSearchQueryExecutorService.java:26)
Error has been observed at the following site(s):
	|_     Mono.map ⇢ at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryExecutorService.querySearch(TvSearchQueryExecutorService.java:26)
	|_ Mono.flatMap ⇢ at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryEngineService.searchElements(TvSearchQueryEngineService.java:56)
	|_     Mono.map ⇢ at tv.mirada.iris.sdp.search.service.response.ResponseService.toResponseEntity(ResponseService.java:71)
	|_ Mono.timeout ⇢ at tv.mirada.iris.sdp.search.service.response.ResponseService.toResponseEntity(ResponseService.java:94)
Stack trace:
		at java.util.AbstractList.add(AbstractList.java:148)
		at java.util.AbstractList.add(AbstractList.java:108)
		at tv.mirada.iris.sdp.search.service.seriesrollup.SeriesRollupService.rollupSeriesIfRequired(SeriesRollupService.java:62)
		at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryResultNodeService.rollupSeriesIfRequired(TvSearchQueryResultNodeService.java:114)
		at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryResultNodeService.buildTvSearchQueryResultNodes(TvSearchQueryResultNodeService.java:34)
		at tv.mirada.iris.sdp.search.tvsearch.service.query.TvSearchQueryExecutorService.lambda$0(TvSearchQueryExecutorService.java:29)
		at java.lang.Thread.run(Thread.java:748) [49 skipped]
```

Please note that the own stacke trace points the number of skipped lines (49)

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