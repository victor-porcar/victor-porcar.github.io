# TechTalk: The Requests You Lose on Every Deploy[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Requests-Lost-On-Every-Deploy/README.md)

A rolling update is supposed to be a deploy with no downtime. It usually is not: it drops a handful of requests every single time, and nobody notices because nobody is measuring during the deploy.

Continues the [Introduction to Kubernetes](../TechTalk-Introduction-to-Kubernetes) talk.

 - [Introduction](#introduction)
 - [The race nobody told us about](#the-race-nobody-told-us-about)
 - [preStop: doing nothing, on purpose](#prestop-doing-nothing-on-purpose)
 - [Graceful shutdown in Spring Boot](#graceful-shutdown-in-spring-boot)
 - [The whole sequence](#the-whole-sequence)
 - [What else is still running](#what-else-is-still-running)
 - [Good practices](#good-practices)
 - [Appendix: measuring it](#appendix-measuring-it)

<br/>

## Introduction

We have three replicas, a rolling update, readiness probes and a service in front. The deploy finishes green, the dashboard shows nothing unusual, and everybody moves on.

Now put a load generator on it during the deploy and count the non-200s. There will be some. Not many - a handful of 502s and connection resets - but **every deploy, every time**, and in a system with several services deploying several times a day it adds up to a number of failed user requests that nobody has ever put on a slide.

The cause is not a bug. It is a race condition that is built into how Kubernetes works, and it is invisible unless you go looking for it.

## The race nobody told us about

When a pod is deleted - which is what a rolling update does - **two things happen at the same time, and they are not coordinated**:

```
   pod marked for deletion
            |
      ┌─────┴─────────────────────────────────┐
      |                                       |
  (A) SIGTERM is sent                  (B) the endpoint is removed
      to the container                     from the Service
      → immediate                          → must propagate to kube-proxy
                                             on EVERY node, and to the
                                             ingress controller
                                           → eventually consistent: takes time
```

Branch (A) is instantaneous. Branch (B) is a distributed update that has to reach every node in the cluster and every load balancer in front of it.

So there is a window - normally a second or two, sometimes more on a big cluster - in which **the pod has already been told to shut down but is still receiving traffic**, because the routing tables out there have not caught up yet.

And here is where our own good behaviour makes it worse. A well written application receives SIGTERM and shuts down promptly: it stops accepting connections and closes the listener. Which means that during that window it answers **connection refused**, and the client sees a 502.

> **the pod stops accepting requests before the cluster stops sending them**

Note what this implies: the better and faster our shutdown is, the more requests we drop. Doing the obvious thing is precisely what causes the problem.

## preStop: doing nothing, on purpose

The fix looks absurd the first time you see it:

```yaml
lifecycle:
  preStop:
    exec:
      command: ["sh", "-c", "sleep 10"]
```

A `preStop` hook runs **before** the SIGTERM is sent, and Kubernetes waits for it to finish. So this says: *when you are told to terminate, do nothing at all for ten seconds, and keep serving normally*.

Those ten seconds are exactly what branch (B) needs to finish propagating. By the time the application actually receives SIGTERM, nothing is routing traffic to it any more, and the shutdown drops nothing.

It feels wrong to add a `sleep` to production. It is not a workaround for a bug in our code - it is the only way to wait for an eventually consistent update that offers us no other signal that it has finished.

The value: long enough for the endpoint removal to propagate, and it depends on the cluster - 5 seconds is usually plenty, 10 to 15 on a large one. Measure it, do not guess: the appendix shows how.

### Why the readiness probe is not enough

The obvious alternative is to make the readiness probe fail first, so the pod is taken out of the Service before it stops.

It helps, and it is not sufficient. The probe runs on an interval - `periodSeconds` - and needs `failureThreshold` consecutive failures, so detection alone costs several seconds, and only *then* does the endpoint removal start propagating. It is the same race, started later.

`preStop` is deterministic: the cluster waits. The probe is a poll.

## Graceful shutdown in Spring Boot

Surviving the window is half the job. The other half is finishing the requests that are already in flight when SIGTERM finally arrives.

Since Spring Boot 2.3:

```properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=20s
```

With that, on SIGTERM the container stops accepting **new** connections but lets the ones in progress finish, up to the timeout. Without it, in-flight requests are cut mid-response - which from the client looks exactly like a server crash.

And this has to line up with Kubernetes:

```yaml
terminationGracePeriodSeconds: 45
```

That is the total budget from the moment the pod is marked for deletion. When it expires, **SIGKILL**, and SIGKILL does not negotiate. So the arithmetic has to work out:

```
terminationGracePeriodSeconds  >  preStop sleep  +  graceful shutdown timeout  +  margin
              45               >       10        +         20                  +  ...
```

Getting this wrong is common and silent: a `preStop` of 30 with the default grace period of 30 means the application is killed the instant the hook ends, having done no graceful shutdown at all. The configuration looks careful and achieves nothing.

## The whole sequence

Putting it together, in order:

```
 t=0    kubectl apply / rollout
        pod marked Terminating
        ├── endpoint removal starts propagating   (B)
        └── preStop hook starts                   (A, deferred)
 t=0-10 the pod KEEPS SERVING normally
        ...the propagation finishes somewhere in here
 t=10   preStop ends → SIGTERM
        Spring Boot stops accepting new connections
        in-flight requests finish
 t=~12  the JVM exits on its own
        ---
 t=45   if it had not exited: SIGKILL
```

And the corresponding manifest fragment:

```yaml
spec:
  terminationGracePeriodSeconds: 45
  containers:
    - name: car-service
      lifecycle:
        preStop:
          exec:
            command: ["sh", "-c", "sleep 10"]
      readinessProbe:
        httpGet:
          path: /actuator/health/readiness
          port: 8080
        periodSeconds: 5
```

## What else is still running

The HTTP request is the obvious one. In a real service there is usually more, and it is worth going through the list once:

**Kafka or messaging consumers.** A consumer that dies without committing leaves the messages to be redelivered, and without leaving the group cleanly it forces a rebalance with the session timeout instead of immediately. Spring Kafka stops the containers on shutdown if it is allowed to.

**Scheduled tasks and `@Async` executors.** A `ThreadPoolTaskExecutor` with `setWaitForTasksToCompleteOnShutdown(true)` and a sensible `awaitTermination` finishes what it started. Without it, the task is simply gone, mid-way.

**Client side keep-alive.** A load balancer or another service holding an open keep-alive connection to our pod will keep using it until it is closed, endpoints or no endpoints. This is why the ingress or the LB needs connection draining configured too - and it is the part that most often explains the last remaining 502s after everything above is correct.

**Open transactions.** Covered in the [@Transactional](../TechTalk-Transactional-What-Really-Happens) talk, and it applies here: a long transaction in flight at SIGKILL leaves a lock that somebody has to wait out.

## Good practices

### AntiPattern: a preStop longer than the grace period

```yaml
terminationGracePeriodSeconds: 30
lifecycle:
  preStop:
    exec:
      command: ["sh", "-c", "sleep 30"]
```

The hook consumes the entire budget, SIGKILL arrives at the same moment as SIGTERM, and there is no graceful shutdown at all. The manifest looks like somebody thought about it - which makes it worse, because nobody will look again.

### Do not use `SIGKILL` to speed up deploys

The temptation when a deploy feels slow is to lower `terminationGracePeriodSeconds`. That does make the deploy faster, and it does it by cutting requests. If the deploy is slow, the thing to fix is why the application takes so long to stop.

### The application has to be killable

None of this saves a service that keeps state in memory. All it does is stop the requests that were in flight from being lost. If the instance holds a session, a half-written file or an in-memory counter that matters, the problem is the design, not the shutdown - which is the point made in the [Kubernetes](../TechTalk-Introduction-to-Kubernetes) talk.

### Check the startup side too

The mirror image of this talk is a pod that starts receiving traffic **before** it is ready. That is what the `readinessProbe` is for, and the `startupProbe` is what stops the liveness check from killing a JVM that simply takes thirty seconds to boot. Both are in the Kubernetes talk, and a deploy is only clean when both ends are right.

### Same thing outside Kubernetes

If the deployment is a load balancer and a couple of VMs, the shape is identical: take the instance out of the pool, **wait** for the connections in flight to drain, then stop the process. Kubernetes did not invent this problem, it just made it easy to ignore.

## Appendix: measuring it

This is the part that turns an opinion into a fact, and it takes ten minutes.

Put constant load on the service and deploy while it runs:

```shell
hey -z 120s -c 20 https://car-service.example.com/api/cars
```

or, with no tooling to install:

```shell
end=$((SECONDS+120)); fail=0; total=0
while [ $SECONDS -lt $end ]; do
  code=$(curl -s -o /dev/null -w '%{http_code}' https://car-service.example.com/api/cars)
  total=$((total+1))
  [ "$code" != "200" ] && { fail=$((fail+1)); echo "$(date +%T) -> $code"; }
done
echo "$fail failures out of $total"
```

Then, in another terminal:

```shell
kubectl rollout restart deployment/car-service
kubectl rollout status deployment/car-service
```

The number that comes out is the argument. Run it before the change and after, and the difference is usually the whole conversation - it turns "deploys are fine" into a measured count of failed requests, which is exactly the kind of number that gets a ticket prioritised.

Worth watching alongside it:

```shell
kubectl get pods -w
kubectl get endpoints car-service -w      # see the propagation happen
```
