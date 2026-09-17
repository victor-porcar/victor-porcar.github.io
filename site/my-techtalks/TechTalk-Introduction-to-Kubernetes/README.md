# TechTalk: Introduction to Kubernetes[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Introduction-to-Kubernetes/README.md)

This is an introduction to [Kubernetes](https://kubernetes.io/) for a Java developer whose Spring Boot service is already in a container and now has to run in a cluster.

It assumes the [Introduction to Docker](../TechTalk-Introduction-to-Docker) talk. The official documentation is [here](https://kubernetes.io/docs/home/)

 - [Introduction](#introduction)
 - [The mental model: declare, do not command](#the-mental-model-declare-do-not-command)
 - [The objects that actually matter](#the-objects-that-actually-matter)
     - [Pod](#pod)
     - [Deployment](#deployment)
     - [Service](#service)
     - [ConfigMap and Secret](#configmap-and-secret)
 - [Deploying a Spring Boot service](#deploying-a-spring-boot-service)
 - [Probes: the part Java developers get wrong](#probes-the-part-java-developers-get-wrong)
 - [Requests and limits](#requests-and-limits)
 - [Day to day: when something is broken](#day-to-day-when-something-is-broken)
 - [Good practices](#good-practices)
 - [Appendix: commands worth remembering](#appendix-commands-worth-remembering)

<br/>

## Introduction

Docker solved how to package **one** service and run it on **one** machine.

That leaves a set of questions unanswered, and they are the questions that actually take our time:

*   this container died at four in the morning, **who restarts it?**

*   we need six instances of it, **on which of the twenty machines?**

*   an instance moved to another node and its IP changed, **how does anybody find it now?**

*   we are releasing version 1.4.3, **how do we replace the running instances without dropping requests?**

Kubernetes is the answer to all of them, and that is why it is big. It is not a tool, it is a **distributed operating system** whose unit of execution is the container instead of the process.

The cost is a real learning curve. The good news for us is that a Java developer does not need all of it: with five objects and six `kubectl` commands we can work comfortably. That is the scope of this talk.

## The mental model: declare, do not command

This is the single idea that makes everything else fall into place, and it is very different from how we usually think.

We do not tell Kubernetes _"start a container"_. We **declare a desired state**:

> _I want three instances of this image, each with 1 GB of memory, reachable on port 8080_

and we hand that declaration over. From then on, a **controller** runs a loop, forever:

```
   compare desired state  <-->  actual state
   if they differ, act to close the gap
   repeat
```

A node catches fire and three pods disappear. Nobody raises an alarm and nobody calls anybody: the loop notices that there are zero and three are wanted, and it creates three more somewhere else.

This is called **reconciliation**, and two consequences follow:

*   **our YAML is the source of truth**, not the cluster. It belongs in git, next to the code

*   anything we fix by hand in the cluster **will be undone**, because the loop will restore whatever the declaration says. A manual fix is not a fix, it is a countdown

## The objects that actually matter

There are dozens. These four cover almost all of our daily work.

### Pod

The **smallest deployable unit**. A pod is one or more containers that share network and lifecycle: they are always on the same node, they see each other on `localhost`, and they live and die together.

In practice, for a Spring Boot service, **a pod is our container**. The multi container case exists - a sidecar that ships logs, a proxy - but it is not the starting point.

The important property is that **a pod is disposable and has no identity**. It gets an IP, and when it dies it is not restarted: a **new** pod is created, with a new name and a new IP. Never write down a pod's IP anywhere.

### Deployment

We almost never create pods directly. We declare a **Deployment**, which says _"I want N pods like this one"_ and takes care of the rest: recreating them when they die and, crucially, **replacing them gradually** on a new release.

A deploy in Kubernetes is: change the image tag in the YAML, apply it, and the Deployment starts a new pod, waits for it to be **ready**, then removes an old one, and repeats. No downtime, and a rollback is one command.

That _waits for it to be ready_ is doing a lot of work, and it depends entirely on the probes. We will get to them.

### Service

Pods come and go and their IPs change, so something stable has to sit in front. A **Service** is a fixed name and a fixed virtual IP that load balances across whichever pods match a label.

Inside the cluster, that name is DNS:

```
http://car-service:8080/api/cars
```

Same idea as the service name in Docker Compose, and the same rule: **we address services by name, never by IP**.

### ConfigMap and Secret

Configuration does not travel inside the image - that was the whole point of not baking it in. It is injected by the cluster, either as environment variables or as mounted files.

A **ConfigMap** holds plain configuration. A **Secret** holds passwords and tokens. One honest warning: a Secret is only **base64 encoded**, not encrypted. It is better than a ConfigMap because access to it is controlled separately, but it is not a vault.

## Deploying a Spring Boot service

The whole thing, and it is shorter than it looks:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: car-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: car-service        # which pods this Deployment owns
  template:
    metadata:
      labels:
        app: car-service      # must match the selector above
    spec:
      containers:
        - name: car-service
          image: my-registry/car-service:1.4.2
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_PROFILES_ACTIVE
              value: production
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: car-service-secrets
                  key: db-password
          resources:
            requests:
              memory: "1Gi"
              cpu: "500m"
            limits:
              memory: "1Gi"
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8080
            periodSeconds: 10
          startupProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            failureThreshold: 30
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: car-service
spec:
  selector:
    app: car-service          # the pods it load balances to
  ports:
    - port: 8080              # the port of the service
      targetPort: 8080        # the port of the container
```

```shell
kubectl apply -f car-service.yaml
```

Everything is glued together by **labels**. The Deployment owns the pods carrying `app: car-service`, and the Service routes to the pods carrying `app: car-service`. There is no direct reference between them: if a selector does not match, nothing fails loudly, we simply get a Service that routes to nowhere. It is the first thing to check when a service is unreachable.

## Probes: the part Java developers get wrong

Three probes, and confusing them causes most of the mysterious behaviour in a cluster.

*   **livenessProbe**: _are you alive?_ If it fails, **the pod is killed and restarted**

*   **readinessProbe**: _can you take traffic right now?_ If it fails, the pod is **removed from the Service**, but it is left alone

*   **startupProbe**: _have you finished starting?_ While it has not succeeded, the other two are **suspended**

The distinction between the first two is everything. A service that is alive but temporarily unable to work - its database is down, it is warming a cache - should say **not ready**, so it stops receiving requests, and **not** say _not alive_, because restarting it will not bring the database back. It will just produce a restart loop while the real problem is somewhere else.

Rule of thumb:

> **liveness fails only when a restart would genuinely fix it**

The third one exists because of us specifically. A Spring Boot service with a decent context can take thirty seconds to start. Without a `startupProbe`, the liveness probe starts checking immediately, gets no answer, decides the pod is dead and kills it. The pod restarts, takes thirty seconds again, and is killed again: **an infinite restart loop on an application that is perfectly healthy**. The `startupProbe` with a generous `failureThreshold` gives it the time it needs without making the liveness check slow afterwards.

Spring Boot supports these two endpoints natively through Actuator, and enables them automatically when it detects it is running in Kubernetes:

```properties
management.endpoint.health.probes.enabled=true
management.endpoints.web.exposure.include=health
```

which gives us `/actuator/health/liveness` and `/actuator/health/readiness`, already integrated with the application lifecycle.

Also worth knowing: Spring Boot supports **graceful shutdown**, so that when Kubernetes asks a pod to stop, in flight requests are allowed to finish instead of being cut:

```properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=20s
```

## Requests and limits

Two numbers that look similar and mean very different things:

*   **request** is what the pod is **guaranteed**. The scheduler uses it to decide which node has room. It is a reservation

*   **limit** is the **ceiling**. Going over it has consequences

And the consequences are not symmetric, which is the part to remember:

*   over the **CPU** limit, the process is **throttled**. It slows down. Nothing dies, but latency degrades in a way that is hard to diagnose

*   over the **memory** limit, the process is **killed**. Exit code 137, `OOMKilled`, no stack trace, no log line

Everything in the [Docker](../TechTalk-Introduction-to-Docker) talk about `MaxRAMPercentage` applies here without changes, and it matters more: the container limit and the JVM heap have to be set consistently, or we get a pod that is killed by the kernel while the JVM believed it still had room.

Rule of thumb: for a Java service, set **memory request equal to memory limit**. Memory is not compressible - a JVM that reserved its heap does not give it back - so allowing it to burst above the reservation only buys an unpredictable death later.

## Day to day: when something is broken

The order in which to look, which is almost always the same:

```shell
kubectl get pods                      # is it running? how many restarts?
kubectl describe pod <pod>            # the Events at the bottom: why it is not starting
kubectl logs <pod>                    # our own logs
kubectl logs <pod> --previous         # the logs of the instance that just died
```

`kubectl describe` is the underused one. The **Events** section at the bottom is where Kubernetes explains itself: the image cannot be pulled, there is no node with enough memory, the probe is failing. Most _"it does not start and I do not know why"_ is answered there.

And `--previous` is the one that saves the day in a restart loop: by the time we look, the pod that failed is already gone and its logs with it. That flag reads the logs of the previous instance, which is the one that actually has the error.

To reach a service from our machine:

```shell
kubectl port-forward svc/car-service 8080:8080
```

For several services at once, there is a tool in this repository that automates it: [kubenv](../../my-scripts/kubenv)

And to diagnose a JVM that is misbehaving inside a pod without restarting it, the [Arthas](../TechTalk-Arthas-Tool) talk has an appendix specifically about doing it in Kubernetes.

## Good practices

### AntiPattern: fixing things with `kubectl edit`

Avoid this:

```shell
kubectl scale deployment car-service --replicas=6
kubectl edit deployment car-service
```

It works, and it is a trap. The cluster now says six replicas and the YAML in git says three. The next time anybody applies that file, the fix silently disappears. And nobody will connect the incident with a command somebody typed three weeks ago.

**The YAML in git is the truth.** Change it there, apply it from there. `kubectl edit` is for investigating, never for fixing.

### Always set requests and limits

A pod with no `requests` is invisible to the scheduler, which will happily pack it onto a full node. A pod with no `limits` can consume the whole node and take down every other service on it. It is the fastest way to turn one broken service into a broken cluster.

### Never hardcode a pod IP, ever

It is worth repeating because the temptation appears the first time something does not resolve. A pod IP is valid until the pod dies, which may be in ten seconds. Services exist exactly for this.

### AntiPattern: the `latest` tag, again

```yaml
image: my-registry/car-service:latest
```

Here it is even worse than in Docker. Kubernetes decides whether to re-pull an image by comparing **tags**, so with `latest` there are pods running different builds under the same name, and no way to tell which. On top of that, a rollback needs a version to roll back **to**, and `latest` is not one.

### Keep a namespace per environment

`kubectl` always acts on a namespace, and the default one is `default`. The accident of applying to the wrong cluster or namespace is common and expensive. Being explicit costs nothing:

```shell
kubectl apply -f car-service.yaml -n development
kubectl config set-context --current --namespace=development   # or set it once
```

### Design the service to be killed at any moment

This is the real conclusion, the same as with containers but stronger. Kubernetes **will** kill our pods: to move them to another node, to scale down, to deploy. Not as an exception - as normal operation.

So the service must be **stateless**: no session in memory, no temporary files it expects to find later, no assumption that the instance handling the second request is the one that handled the first. Anything that must survive goes to a database, a cache or a queue.

A service that cannot be killed at any moment does not belong in a cluster, and Kubernetes will make that evident within a week.

## Appendix: commands worth remembering

```shell
kubectl get pods -o wide              # with the node and the IP
kubectl get all                       # everything in the namespace
kubectl describe pod <pod>            # Events at the bottom
kubectl logs -f <pod>                 # follow
kubectl logs <pod> --previous         # the instance that died
kubectl exec -it <pod> -- sh          # a shell inside the pod
kubectl port-forward svc/<svc> 8080:8080
```

Deploying and going back:

```shell
kubectl apply -f car-service.yaml
kubectl rollout status deployment/car-service     # wait and report
kubectl rollout undo deployment/car-service       # roll back to the previous version
kubectl rollout history deployment/car-service
```

And the one to check before anything else, more than once:

```shell
kubectl config current-context        # WHICH CLUSTER am I actually talking to?
```
