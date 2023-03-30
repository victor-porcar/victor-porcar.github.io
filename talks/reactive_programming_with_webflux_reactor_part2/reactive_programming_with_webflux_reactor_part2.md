# Reactive Programming with WebFlux Reactor (part II)

Once understood the basic concepts of WebFlux Reactor explained in Reactive Programming with WebFlux Reactor (part I), it is good idea to
read Reactive Code Primer , which gives a lot of extra useful information.
In order to get the most of Spring WebFlux, it is important to use the reactive I/O components properly.
As explained in Reactive Programming with WebFlux Reactor (part I), the following components are included in Spring WebFlux out of the box to
be used by developers:

### Web Client

#### GET

## Response content is retrieved using a flow Use FLUX

To be used when:

```
when the response is well structured as Json as array and the number of entities is long bespoke components
```
## Response content is retrieved in “one shot” Use MONO

To be used when:

when the response is not well structured as Json array example: Solr HTTP Response, Mirada APIs
when the response size is “short”: Even having a structured response, perhaps it is not worthy to use Flux

### RestController

Similar to the conventional spring web controller, but methods should return Mono or Flux

### Redis

based on templates, similar to the non reactive API
org.springframework.data.redis.core.ReactiveRedisTemplate
Basic operations (get / set) use opsForValue()

## SET VALUE

## GET VALUE

There are multidata version which are very useful:


## SET MAP KEY - VALUE

## DELETE one or more keys

### Database

At the moment there is not a fully working implementation of a Reactive driver for Oracle database (11g)
Project Oracle R2DBC: https://github.com/oracle/oracle-r2dbc The Oracle R2DBC Driver has been verified with Oracle Database versions
19c and 21c.
Dave Moten wrote a driver: https://github.com/davidmoten/rxjava2-jdbc
Originally written in RxJava, not Reactor, however it is fully integrated in Reactor

Known issues
DO NOT USE block() on a MONO returned by the driver, if so, it will “kept” the executing thread indefinitely and the service will soon
collapse

### MQTT

HiveMQ MQTT Client Reactor Module???


