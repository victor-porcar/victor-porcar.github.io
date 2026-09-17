# TechTalk: Introduction to Docker[<img align="right" src="../../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-techtalks/TechTalk-Introduction-to-Docker/README.md)

This is an introduction to [Docker](https://www.docker.com/) from the point of view of a Java developer who has to package a Spring Boot service and run it somewhere that is not his laptop.

The official documentation is [here](https://docs.docker.com/)

 - [Introduction](#introduction)
 - [The mental model](#the-mental-model)
 - [Dockerizing a Spring Boot service](#dockerizing-a-spring-boot-service)
     - [The naive Dockerfile](#the-naive-dockerfile)
     - [The layer cache](#the-layer-cache)
     - [A proper Dockerfile](#a-proper-dockerfile)
 - [Running the container](#running-the-container)
 - [The JVM inside a container](#the-jvm-inside-a-container)
 - [Docker Compose for local development](#docker-compose-for-local-development)
 - [Good practices](#good-practices)
 - [Appendix: commands worth remembering](#appendix-commands-worth-remembering)

<br/>

## Introduction

The problem Docker solves is an old one:

> _it works on my machine_

It works on my machine because my machine has a particular JDK version, a particular locale, a particular set of libraries installed and an `/etc/hosts` that somebody edited two years ago. The server has none of that.

The traditional answer was a document explaining how to prepare the server. The document was always out of date.

Docker's answer is different: **we ship the environment together with the application**, as a single immutable artifact. Whatever runs in our laptop is byte by byte what runs in production.

A common misunderstanding is to think of this as a virtual machine. It is not:

*   a **virtual machine** emulates hardware and boots a complete operating system, with its own kernel. It takes minutes and gigabytes

*   a **container** is just a **process** running on the host kernel, isolated by Linux features (namespaces and cgroups) so that it sees its own filesystem, its own network and its own process tree

That is the key sentence of this whole talk: **a container is a process, not a machine**. Most of the surprises come from forgetting it. A container with no running process stops existing. There is nothing to _log into_, nothing _inside_ that keeps running on its own.

## The mental model

Only two concepts, and they are easy to mix up:

*   an **image** is the immutable artifact: a filesystem plus the metadata saying which process to start. It is the equivalent of our `jar`

*   a **container** is a running instance of an image. It is the equivalent of the JVM process running that `jar`

One image, many containers. Exactly as one `jar` can be started many times.

An image is built in **layers**, one per instruction in the `Dockerfile`. Each layer is a diff over the previous one, layers are immutable and, this is the important part, **they are shared and cached**. Two images built from the same base share that base on disk and over the network.

Everything about build speed and image size follows from this.

## Dockerizing a Spring Boot service

### The naive Dockerfile

This is the version everybody writes first, and it works:

```dockerfile
FROM eclipse-temurin:17-jdk
COPY . /app
WORKDIR /app
RUN ./mvnw clean package
CMD ["java", "-jar", "target/my-service.jar"]
```

It works, and it is wrong in four different ways. Let's go one by one, because each one teaches something.

**It ships the whole JDK.** We need a compiler to build, but not to run. A JDK image is roughly three times the size of a JRE one, and every megabyte is downloaded on every deployment, on every node.

**It ships the source code, the tests, the `.git` directory and the Maven cache.** Everything `COPY . /app` found. Our source code is now inside an artifact that will be pushed to a registry.

**It runs as root.** By default the process inside the container is root. If somebody escapes the container, they are root on the host.

**And the worst one: it destroys the layer cache on every build.** This is the one that deserves its own section.

### The layer cache

When Docker builds an image, it goes instruction by instruction and, for each one, it asks: _have I built this exact layer before, from this exact parent?_ If yes, it reuses it.

The consequence is a rule that governs every `Dockerfile` ever written:

> **once one layer changes, every layer after it is rebuilt**

In the naive `Dockerfile`, `COPY . /app` copies the source code. The source code changes on every single commit. So that layer always changes, and therefore `RUN ./mvnw clean package` always runs from scratch: **every build downloads the whole internet again**.

The fix follows directly from the rule: **order the instructions from least likely to change to most likely to change**.

Dependencies change once a month. Our code changes twenty times a day. So dependencies go first:

```dockerfile
COPY pom.xml .
RUN ./mvnw dependency:go-offline     # cached until pom.xml changes
COPY src ./src
RUN ./mvnw clean package -o          # only this is rebuilt on a normal commit
```

### A proper Dockerfile

Now we fix the rest with a **multi stage build**: one stage that has the tools to build, and a second stage that only takes the result. Everything in the first stage - compiler, Maven cache, source code - is thrown away.

```dockerfile
# ---------- build stage ----------
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /build

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline -B

COPY src ./src
RUN ./mvnw clean package -DskipTests -B

# Spring Boot can split its fat jar into layers that change at different rates
RUN java -Djarmode=layertools -jar target/*.jar extract --destination extracted

# ---------- runtime stage ----------
FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app

# never run as root
RUN addgroup --system spring && adduser --system --ingroup spring spring
USER spring

# from the least to the most frequently changed, again
COPY --from=builder --chown=spring:spring /build/extracted/dependencies/ ./
COPY --from=builder --chown=spring:spring /build/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=spring:spring /build/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=spring:spring /build/extracted/application/ ./

EXPOSE 8080
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
```

Two details worth explaining.

**The layered jar.** A Spring Boot fat jar contains our code, a few hundred kilobytes, mixed with all the dependencies, tens of megabytes. As a single file, changing one line of our code invalidates the whole thing. `layertools` splits it by rate of change, so a normal deployment only pushes and pulls the small layer. _(In Spring Boot 3.3 and later this was renamed to `-Djarmode=tools ... extract --layers`; the idea is identical.)_

**`.dockerignore`.** The build context is everything sent to the daemon before the build even starts. Without this file we are sending our entire `target/` directory and `.git` on every build:

```
target/
.git/
.idea/
*.iml
```

## Running the container

```shell
docker build -t my-service:1.4.2 .
docker run --rm -p 8080:8080 -e SPRING_PROFILES_ACTIVE=dev my-service:1.4.2
```

Three things a Java developer meets immediately:

**Ports are not published by default.** `EXPOSE 8080` in the `Dockerfile` is documentation, nothing else. What actually opens the port is `-p 8080:8080`, and the order is `host:container`.

**`localhost` inside the container is the container itself.** A service that connects to a database on `localhost:5432` will not find it once containerized. This is the single most common first day problem.

**Logs go to stdout.** Not to a file. The container has no logrotate, no `/var/log` that anybody will read, and it may disappear at any moment. Everything we discussed in the [Logging Policy](../TechTalk-Logging-Policy) talk still applies, but the destination is always the standard output, and the platform collects it.

## The JVM inside a container

This deserves its own section because it bites Java developers specifically, and the symptom is confusing.

A container can be given a memory limit. If the process goes over it, the kernel **kills it**: no exception, no stack trace, no `OutOfMemoryError`. The container simply dies with exit code **137**, and in the logs there is nothing at all.

Modern JVMs are container aware and read the cgroup limit instead of the host's memory. The problem is the default: the heap is capped at **25% of the limit**. Give the container 2 GB and the JVM will use 512 MB of heap and refuse to grow, while we wonder why it is running out of memory in a container that looks half empty.

So the limit has to be told explicitly:

```dockerfile
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"
```

Rule of thumb: **75% is a reasonable starting point**, never 100%. The remaining 25% is not wasted - it is for metaspace, thread stacks, code cache and direct buffers, which live outside the heap and are very much counted by the kernel.

And to diagnose what is going on inside that JVM without restarting it, everything in the [Arthas](../TechTalk-Arthas-Tool) talk works in a container too.

## Docker Compose for local development

The real benefit for our daily work is not production, it is the ability to start the whole stack with one command:

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: cars
      POSTGRES_PASSWORD: local_only_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 10

  my-service:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/cars
    depends_on:
      postgres:
        condition: service_healthy
```

```shell
docker compose up --build
```

Note `jdbc:postgresql://postgres:5432/cars`. **The service name is the hostname**: Compose gives every service a DNS entry on a shared network. This is the same idea we will find again in Kubernetes.

Note also the `healthcheck` with `condition: service_healthy`. A plain `depends_on` only waits for the container to **start**, not for Postgres to be **ready to accept connections**, and our service will happily start and fail to connect.

## Good practices

### AntiPattern: the `latest` tag

Avoid this:

```dockerfile
FROM eclipse-temurin:17-jre
```
```shell
docker run my-service:latest
```

`latest` is not a version, it is a **mutable pointer**. The image we tested and the image that is deployed three days later may be different, and the build is no longer reproducible. Worse, we cannot roll back to something we cannot name.

Use an explicit version, ideally the digest for base images:

```dockerfile
FROM eclipse-temurin:17.0.13_11-jre-alpine
```
```shell
docker run my-service:1.4.2
```

### AntiPattern: secrets in the image

Avoid this:

```dockerfile
ENV DB_PASSWORD=Sup3rS3cr3t
```

An image is not a safe place. Anybody who can pull it can read it, and a layer is immutable: **deleting the file in a later instruction does not remove it**, it is still there in the previous layer, waiting for `docker history`.

Secrets are injected at runtime, as environment variables or mounted files, by whoever runs the container.

### One process per container

The temptation is to put the service and its nginx and its cron in the same container, because it feels like a small server. It is not a server, it is a process. Two processes mean the container does not die when the important one dies, health checks lie, and logs are mixed.

### Do not store state in the container

The filesystem of a container is as ephemeral as the container itself. Anything that has to survive goes into a **volume** or, better, into a database. A container should be disposable: that is the property everything else is built on.

### Keep the image small, but do not obsess

Smaller images pull faster and have less to attack. But `alpine` uses `musl` instead of `glibc`, which occasionally produces subtle differences in DNS resolution or locales. For a Java service the sensible default is a `-jre` image of a normal distribution, and alpine only if we measured that we need it.

## Appendix: commands worth remembering

```shell
docker ps                      # running containers
docker ps -a                   # including the dead ones, with their exit code
docker logs -f <container>     # follow the logs
docker exec -it <container> sh # a shell inside a RUNNING container
docker inspect <container>     # the whole truth: mounts, network, env, limits
docker history <image>         # layer by layer, with sizes
docker stats                   # live CPU and memory per container
```

Two that save an afternoon:

{% raw %}
```shell
# why did it die?
docker inspect <container> --format '{{.State.ExitCode}} {{.State.OOMKilled}}'

# the image builds but the app does not start: get in without starting the app
docker run --rm -it --entrypoint sh my-service:1.4.2
```
{% endraw %}

And the one to run when the laptop runs out of disk, which it will:

```shell
docker system df       # what is taking the space
docker system prune -a # remove everything not used by a running container
```
