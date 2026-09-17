### Docker and Kubernetes Cheatsheet [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-docker-kubernetes.md)

Lookup version of the two tech talks: [Introduction to Docker](../my-techtalks/TechTalk-Introduction-to-Docker) and [Introduction to Kubernetes](../my-techtalks/TechTalk-Introduction-to-Kubernetes). The talks explain the why; this is for when you already know it and just need the flag.

---

{% raw %}

#### Docker: looking around

```shell
docker ps                       # running
docker ps -a                    # including the dead, with their exit code
docker ps --filter 'status=exited' --filter 'exited=137'    # the OOM killed ones
docker stats                    # live CPU and memory, per container
docker top <container>          # processes inside
```

```shell
docker logs -f --tail 200 <container>
docker logs --since 10m <container>
docker logs <container> 2>&1 | grep -i error
```

#### Docker: the format flag

`--format` with a Go template turns any of these into something greppable:

```shell
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker inspect <container> --format '{{.State.ExitCode}} {{.State.OOMKilled}}'
docker inspect <container> --format '{{.NetworkSettings.IPAddress}}'
docker inspect <container> --format '{{json .Config.Env}}' | jq .
docker inspect <container> --format '{{.HostConfig.Memory}}'    # the limit, in bytes
```

Exit code **137** means the kernel killed it: out of memory. **143** is a clean SIGTERM.

#### Docker: getting inside

```shell
docker exec -it <container> sh          # a shell in a RUNNING container
docker exec -u root -it <container> sh  # as root, when the image runs as a user
docker run --rm -it --entrypoint sh my-image:1.4.2   # the image starts and dies: get in anyway
docker cp <container>:/app/heap.hprof .
docker cp ./config.yml <container>:/app/
```

That third one is the important one: when the container crashes on startup, `exec` is useless because there is nothing running. Overriding the entrypoint gives a shell in the same filesystem.

#### Docker: images and space

```shell
docker build -t my-service:1.4.2 .
docker build --no-cache -t my-service:1.4.2 .
docker build --progress=plain .          # see every command's output
docker history my-service:1.4.2          # layer by layer, with sizes
docker image ls --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
```

```shell
docker system df                # what is taking the disk
docker system prune             # dangling stuff
docker system prune -a --volumes    # everything not used by a running container - careful
docker builder prune            # the build cache, which grows without limit
```

`docker system df` then `prune` is the answer to "the laptop has no disk left", and it will be, sooner or later.

#### Docker Compose

```shell
docker compose up --build
docker compose up -d
docker compose logs -f my-service
docker compose ps
docker compose exec my-service sh
docker compose down -v          # -v also removes the volumes: wipes the database
docker compose config           # the effective file, with variables resolved
```

{% endraw %}

---

#### kubectl: know where you are

Before anything else, more than once:

```shell
kubectl config current-context          # WHICH CLUSTER
kubectl config get-contexts
kubectl config use-context dev
kubectl config set-context --current --namespace=development
```

```shell
kubectl get pods -A                     # every namespace
kubectl get pods -o wide                # with node and IP
kubectl get all                         # everything in the namespace
```

#### kubectl: when something is broken

The order is almost always the same:

```shell
kubectl get pods                              # running? how many restarts?
kubectl describe pod <pod>                    # the EVENTS at the bottom
kubectl logs <pod>
kubectl logs <pod> --previous                 # the instance that just died
kubectl logs -f deployment/car-service --all-containers
kubectl logs -l app=car-service --tail=100    # by label, across every pod
```

`describe` is the underused one: the Events section is where Kubernetes explains itself - image cannot be pulled, no node with room, probe failing.

```shell
kubectl get events --sort-by=.lastTimestamp | tail -30
kubectl get events --field-selector type=Warning
```

#### kubectl: getting in

```shell
kubectl exec -it <pod> -- sh
kubectl exec -it <pod> -c <container> -- sh        # multi container pod
kubectl port-forward svc/car-service 8080:8080
kubectl port-forward pod/<pod> 5005:5005           # remote debug into a pod
kubectl cp <pod>:/tmp/heap.hprof ./heap.hprof
```

For several services at once there is a script in this repository: [kubenv](../my-scripts/kubenv)

When the image has no shell - a distroless one, for instance:

```shell
kubectl debug -it <pod> --image=busybox --target=<container>
kubectl run tmp-shell --rm -it --image=nicolaka/netshoot -- sh   # network toolbox
```

`netshoot` has `dig`, `curl`, `tcpdump` and `ss`, and it is the fastest way to find out whether a service resolves from inside the cluster.

#### kubectl: deploying and rolling back

```shell
kubectl apply -f car-service.yaml
kubectl apply -f . --dry-run=server         # validate against the API, without applying
kubectl diff -f car-service.yaml            # what WOULD change
kubectl rollout status deployment/car-service
kubectl rollout history deployment/car-service
kubectl rollout undo deployment/car-service
kubectl rollout restart deployment/car-service     # restart the pods, no changes
```

`kubectl diff` before `apply` is the habit worth building: it shows exactly what is about to change in a live cluster.

#### kubectl: extracting data

```shell
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
kubectl get pod <pod> -o yaml                       # the full object, as the cluster sees it
kubectl get deployment car-service -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get pods --field-selector status.phase!=Running
kubectl get pods --sort-by=.status.containerStatuses[0].restartCount
```

That last one lists the pods by restarts: the ones at the bottom are the ones to look at.

```shell
kubectl top nodes
kubectl top pods --sort-by=memory
```

#### kubectl: config and secrets

```shell
kubectl get configmap car-config -o yaml
kubectl get secret car-secrets -o jsonpath='{.data.db-password}' | base64 -d
kubectl create secret generic car-secrets --from-literal=db-password=... --dry-run=client -o yaml
```

A Secret is only base64 encoded. That command is a reminder of it, not a trick.

#### kubectl: two reminders

```shell
kubectl explain deployment.spec.template.spec.containers    # documentation, offline
kubectl api-resources                                       # everything this cluster knows about
```

`kubectl explain` beats searching the web: it documents the exact version of the API the cluster is running.
