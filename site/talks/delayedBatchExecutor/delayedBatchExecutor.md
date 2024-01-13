/\*<!\[CDATA\[\*/ div.rbtoc1705128461249 {padding: 0px;} div.rbtoc1705128461249 ul {list-style: disc;margin-left: 0px;} div.rbtoc1705128461249 li {margin-left: 0px;padding-left: 0px;} /\*\]\]>\*/

*   [Introduction](#DelayedBatchExecutor-Introduction)
*   [Database queries](#DelayedBatchExecutor-Databasequeries)
*   [DelayedBatchExecutor (DBE)](#DelayedBatchExecutor-DelayedBatchExecutor(DBE))
    *   [Example](#DelayedBatchExecutor-Example)
    *   [DBE Execution policies](#DelayedBatchExecutor-DBEExecutionpolicies)
        *   [\- Blocking](#DelayedBatchExecutor--Blocking)

Introduction
------------

Delayed-Batch-Executor is a public library that I wrote to optimize the usage of database in a multithread java application

[https://github.com/victormpcmun/delayed-batch-executor](https://github.com/victormpcmun/delayed-batch-executor)

[https://web.archive.org/web/20200815000143/https://dzone.com/articles/delayedbatchexecutor-how-to-optimize-database-usag](https://web.archive.org/web/20200815000143/https://dzone.com/articles/delayedbatchexecutor-how-to-optimize-database-usag)

Database queries
----------------

Let’s focus on the table CORE\_INSTALLED\_DEVICES

In production environment there are 6461058 rows

Using SQL DEVELOPER, It is easy to check that the time to perform a query for a particular hardware\_id is around 200 ms.

```groovy
SELECT * FROM CORE_INSTALLED_DEVICE WHERE HARDWARE_ID='1001B0135C201597' -- 0.2 seconds

SELECT * FROM CORE_INSTALLED_DEVICE WHERE HARDWARE_ID='1000B0A60B96E36E' -- 0.2 seconds

SELECT * FROM CORE_INSTALLED_DEVICE WHERE HARDWARE_ID='1001B01212C07433' -- 0.2 seconds

SELECT * FROM CORE_INSTALLED_DEVICE WHERE HARDWARE_ID='5275325691371502' -- 0.2 seconds
```

Now, let’s find out the time to retrieve four rows _at the same time_ using IN statement

```groovy
SELECT * FROM CORE_INSTALLED_DEVICE WHERE HARDWARE_ID in
('0027523734762669',
'5275325682723422',
'5275342746517385',
'1000B0C95998A5DD')
```

Surprisingly it takes around 0.2 seconds, same amount of time !!!! . The reason behind is database do optimize these types of queries

DelayedBatchExecutor (DBE)
--------------------------

Let’s suppose a service that offers an endpoint that requires to access database by a parameter and this endpoint has many hits per second.

DelayedBatchExecutor is a component that allows to “gather” some of the individuals parameters of the query in **time window**s as a list of parameters to perform queries using IN approach, so the number of queries are reduced. This has two important advantages:

1.  The usage of network resources is reduced dramatically: The number of round-trips to the database is 1 instead of n.
    
2.  The usage of database connections from the connection pool is reduced: there are more available connections overall, which means less waiting time for a connection on peak times.
    

**In short, it is much more efficient executing 1 query of n parameters than n queries of one parameter, which means that the system as a whole requires less resources.**

### Example

Let’s suppose an endpoint receives 18 requests in one second,

```groovy
/device/{hwid}
```

1.  each request will perform a different query to table `CORE_INSTALLED_DEVICE` using harwareId parameter
    

(function(){ var data = { "addon\_key":"com.mxgraph.confluence.plugins.diagramly", "uniqueKey":"com.mxgraph.confluence.plugins.diagramly\_\_drawio5815280361905140300", "key":"drawio", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://ac.draw.io/connect/confluence/viewer-1-4-42.html?ceoId=4565991425&diagramName=Untitled+Diagram-1701331264706.drawio&revision=4&width=440.5&height=338&tbstyle=&simple=0&lbox=1&zoom=1&links=&owningPageId=4565991425&displayName=Untitled+Diagram-1701331264706.drawio&contentId=&custContentId=4566679592&contentVer=3&inComment=0&aspect=&pCenter=0&hiRes=&templateUrl=&tmpBuiltIn=&mVer=2&pageInfo=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.mxgraph.confluence.plugins.diagramly\_\_drawio5815280361905140300&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.mxgraph.confluence.plugins.diagramly&lic=active&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"license\\":{\\"active\\":true},\\"confluence\\":{\\"editor\\":{\\"version\\":\\"\\\\\\"v2\\\\\\"\\"},\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"bb42ccfd-1233-4386-aa0c-e15c46ff4f83\\",\\"id\\":\\"bb42ccfd-1233-4386-aa0c-e15c46ff4f83\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"8\\",\\"id\\":\\"4565991425\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4565991425\\",\\"macro.hash\\":\\"bb42ccfd-1233-4386-aa0c-e15c46ff4f83\\",\\"mVer\\":\\"2\\",\\"page.type\\":\\"page\\",\\"macro.localId\\":\\"2babf4b4-db5e-4518-8060-39f0f79be26e\\",\\"simple\\":\\"0\\",\\"inComment\\":\\"0\\",\\": = | RAW | = :\\":\\"mVer=2|zoom=1|simple=0|inComment=0|custContentId=4566679592|pageId=4565991425|lbox=1|diagramDisplayName=Untitled Diagram-1701331264706.drawio|contentVer=3|revision=4|baseUrl=https://mirada.atlassian.net/wiki|diagramName=Untitled Diagram-1701331264706.drawio|pCenter=0|width=440.5|links=|tbstyle=|height=338\\",\\"space.id\\":\\"1352302837\\",\\"diagramDisplayName\\":\\"Untitled Diagram-1701331264706.drawio\\",\\"diagramName\\":\\"Untitled Diagram-1701331264706.drawio\\",\\"links\\":\\"\\",\\"tbstyle\\":\\"\\",\\"user.isExternalCollaborator\\":\\"false\\",\\"height\\":\\"338\\",\\"space.key\\":\\"~117741573\\",\\"content.version\\":\\"8\\",\\"page.title\\":\\"Delayed Batch Executor\\",\\"zoom\\":\\"1\\",\\"macro.body\\":\\"\\",\\"custContentId\\":\\"4566679592\\",\\"pageId\\":\\"4565991425\\",\\"macro.truncated\\":\\"false\\",\\"lbox\\":\\"1\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"contentVer\\":\\"3\\",\\"page.version\\":\\"8\\",\\"revision\\":\\"4\\",\\"baseUrl\\":\\"https://mirada.atlassian.net/wiki\\",\\"pCenter\\":\\"0\\",\\"content.id\\":\\"4565991425\\",\\"width\\":\\"440.5\\",\\"macro.id\\":\\"bb42ccfd-1233-4386-aa0c-e15c46ff4f83\\",\\"editor.version\\":\\"\\\\\\"v2\\\\\\"\\"}", "timeZone":"UTC", "origin":"https://ac.draw.io", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "pearApp":"true", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }());

*   In total there are 18 queries, some of them will overlap in time
    
*   the total time for each request will be the time required to perform the query + preparing the response from the data retrieved by the query
    

Now, using DBE, the queries fall in one of the time windows:

(function(){ var data = { "addon\_key":"com.mxgraph.confluence.plugins.diagramly", "uniqueKey":"com.mxgraph.confluence.plugins.diagramly\_\_drawio2891406071085563072", "key":"drawio", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://ac.draw.io/connect/confluence/viewer-1-4-42.html?ceoId=4565991425&diagramName=1701773264667-Untitled+Diagram-1701331264706.drawio&revision=2&width=430.5&height=338&tbstyle=&simple=0&lbox=1&zoom=1&links=&owningPageId=4565991425&displayName=Untitled+Diagram-1701331264706.drawio&contentId=&custContentId=4565401787&contentVer=2&inComment=0&aspect=&pCenter=0&hiRes=&templateUrl=&tmpBuiltIn=&mVer=2&pageInfo=&xdm\_e=https%3A%2F%2Fmirada.atlassian.net&xdm\_c=channel-com.mxgraph.confluence.plugins.diagramly\_\_drawio2891406071085563072&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=com.mxgraph.confluence.plugins.diagramly&lic=active&cv=1000.0.0-ed9338f6a197", "structuredContext": "{\\"license\\":{\\"active\\":true},\\"confluence\\":{\\"editor\\":{\\"version\\":\\"\\\\\\"v2\\\\\\"\\"},\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"de3e2f7f-3cdd-485b-86ad-f15f50bc94af\\",\\"id\\":\\"de3e2f7f-3cdd-485b-86ad-f15f50bc94af\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"8\\",\\"id\\":\\"4565991425\\"},\\"space\\":{\\"key\\":\\"~117741573\\",\\"id\\":\\"1352302837\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"4565991425\\",\\"macro.hash\\":\\"de3e2f7f-3cdd-485b-86ad-f15f50bc94af\\",\\"mVer\\":\\"2\\",\\"page.type\\":\\"page\\",\\"macro.localId\\":\\"d7d4b2a0-1a09-48a9-83d0-28d1ea8bb8b8\\",\\"simple\\":\\"0\\",\\"inComment\\":\\"0\\",\\": = | RAW | = :\\":\\"mVer=2|zoom=1|simple=0|inComment=0|custContentId=4565401787|pageId=4565991425|lbox=1|diagramDisplayName=Untitled Diagram-1701331264706.drawio|contentVer=2|revision=2|baseUrl=https://mirada.atlassian.net/wiki|diagramName=1701773264667-Untitled Diagram-1701331264706.drawio|pCenter=0|width=430.5|links=|tbstyle=|height=338\\",\\"space.id\\":\\"1352302837\\",\\"diagramDisplayName\\":\\"Untitled Diagram-1701331264706.drawio\\",\\"diagramName\\":\\"1701773264667-Untitled Diagram-1701331264706.drawio\\",\\"links\\":\\"\\",\\"tbstyle\\":\\"\\",\\"user.isExternalCollaborator\\":\\"false\\",\\"height\\":\\"338\\",\\"space.key\\":\\"~117741573\\",\\"content.version\\":\\"8\\",\\"page.title\\":\\"Delayed Batch Executor\\",\\"zoom\\":\\"1\\",\\"macro.body\\":\\"\\",\\"custContentId\\":\\"4565401787\\",\\"pageId\\":\\"4565991425\\",\\"macro.truncated\\":\\"false\\",\\"lbox\\":\\"1\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"contentVer\\":\\"2\\",\\"page.version\\":\\"8\\",\\"revision\\":\\"2\\",\\"baseUrl\\":\\"https://mirada.atlassian.net/wiki\\",\\"pCenter\\":\\"0\\",\\"content.id\\":\\"4565991425\\",\\"width\\":\\"430.5\\",\\"macro.id\\":\\"de3e2f7f-3cdd-485b-86ad-f15f50bc94af\\",\\"editor.version\\":\\"\\\\\\"v2\\\\\\"\\"}", "timeZone":"UTC", "origin":"https://ac.draw.io", "hostOrigin":"https://mirada.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "pearApp":"true", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } // For Confluence App Analytics. This code works in conjunction with CFE's ConnectSupport.js. // Here, we add a listener to the initial HTML page that stores events if the ConnectSupport component // has not mounted yet. In CFE, we process the missed event data and disable this initial listener. const \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_ = 20; const connectAppAnalytics = "ecosystem.confluence.connect.analytics"; window.connectHost && window.connectHost.onIframeEstablished((eventData) => { if (!window.\_\_CONFLUENCE\_CONNECT\_SUPPORT\_LOADED\_\_) { let events = JSON.parse(window.localStorage.getItem(connectAppAnalytics)) || \[\]; if (events.length >= \_\_MAX\_EVENT\_ARRAY\_SIZE\_\_) { events.shift(); } events.push(eventData); window.localStorage.setItem(connectAppAnalytics, JSON.stringify(events)); } }); }());

request parameters are “gathered” in one list:

*   only three queries, each one with several parameters (using IN clause)
    
*   The query is launched just after finishing the time window
    
*   the total time for each request will be the sum of:
    
    *   the waiting time to finish the window
        
    *   time required to perform the query
        
    *   preparing the response from the data retrieved by the query
        

Each time window is a DBE execution.

Strictly speaking, a DBE is defined by three parameters:

*   **TimeWindow**: defined as java.time.Duration
    
*   **max size**: it is the max number of items to be collected in the list
    
*   **batchCallback**: it receives the parameters list to perform a single query and must return a list with the corresponding results.
    

for example

Le’ts define a DBE that receives a parameter Integer and returns a String

```groovy
DelayedBatchExecutor2<String,Integer> dbe = 
      DelayedBatchExecutor2.create(Duration.ofMillis(50), 100, this::myBatchCallBack);

...

List<String> myBatchCallBack(List<Integer> listOfIntegers) {
  List<String>  resultList = ...// execute query:SELECT * FROM TABKE WHERE ID IN (listOfIntegers.get(0), ..., listOfIntegers.get(n));
                              // use your favourite API: JDBC, JPA, Hibernate,...
	...
	return resultList;
}
```

to use it in the code executed by each thread attending:

```groovy
// this code is executed in one of the multiple threads
int param=...;
String result = dbe.execute(param);
}
```

### DBE Execution policies

There are three policies to use a DelayedBatchExecutor from the code being executed from the threads

#### \- Blocking

*   Blocking
    
*   Non-blocking (java.util.concurrent.Future)
    
*   Non-blocking (Reactive using Reactor framework)
    

see: [https://github.com/victormpcmun/delayed-batch-executor#execution-policies](https://github.com/victormpcmun/delayed-batch-executor#execution-policies)