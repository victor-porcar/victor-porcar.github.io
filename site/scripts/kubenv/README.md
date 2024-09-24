# Kubernetes kubenv

kubenv is a tool to set multiple port-forwards for a given kubernetes conf


Usage:

```
./kubenv.sh  <PATH_TO_K8S_CONFIG> <POD_PREFIX>:<LOCAL_PORT> <POD_PREFIX>:<LOCAL_PORT> ...  <POD_PREFIX>:<LOCAL_PORT>
```

For each POD_PREFIX:LOCAL_PORT, takes the first pod matching the prefix and make a port-forward of its exposed port to the given port


Example

```
./kubenv.sh  /home/victor.porcar/kubeconfig/kubeconfigdev my-service-1:10611 my-service2:10401 my-service3:10066
```


In this example the tool "knows" the exposed port of the  pod  my-service-1 is 10610 in the cluster, so it port forwards to the given port 10611, which means that this pod can be reached using localhost:10611

TODO: if the pod exposes two port, then it takes the first one which could be incorrect. It would be nice to extend the tool to deal with this case
