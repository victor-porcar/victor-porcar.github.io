### Java and JVM Cheatsheet [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-java-jvm.md)

Diagnosing a running JVM, and the Maven invocations worth remembering. For doing all of this interactively on a live process, see the [Arthas](../my-techtalks/TechTalk-Arthas-Tool) tech talk.

---

#### Which JVMs are running

```shell
jps -lvm                # pid, main class, JVM args and program args
jcmd                    # same idea, and jcmd is the tool for everything else
jcmd <pid> help         # every command available for THAT process
```

`jcmd` replaced most of the old separate tools. If you only remember one, remember this one.

#### Thread dumps

```shell
jcmd <pid> Thread.print > threads.txt
jstack -l <pid> > threads.txt       # -l adds lock information
kill -3 <pid>                       # dump to the process's stdout, no tools needed
```

Take **three, twenty seconds apart**. One dump tells you where the threads are; three tell you whether they are moving. A thread stuck on the same line in all three is the problem.

What to look for:

```shell
grep -c 'java.lang.Thread.State' threads.txt          # how many threads
grep -A1 'java.lang.Thread.State: BLOCKED' threads.txt
grep 'waiting to lock' threads.txt | sort | uniq -c   # contention on one monitor
grep 'Found one Java-level deadlock' threads.txt
```

#### Memory

```shell
jcmd <pid> GC.heap_info
jcmd <pid> GC.class_histogram | head -30     # what is filling the heap
jmap -histo:live <pid> | head -30            # same, forcing a GC first
```

`:live` triggers a full GC before counting, so it shows what actually survives. It also pauses the application - not free on a large heap.

```shell
jcmd <pid> GC.heap_dump /tmp/heap.hprof      # analyse later with MAT or VisualVM
jmap -dump:live,format=b,file=/tmp/heap.hprof <pid>
```

A heap dump is the size of the heap. On an 8 GB heap it takes time, freezes the process and fills the disk - check `df -h` first.

Native memory, for the case where the process grows but the heap does not:

```shell
# needs -XX:NativeMemoryTracking=summary at startup
jcmd <pid> VM.native_memory summary
```

#### GC behaviour, live

```shell
jstat -gcutil <pid> 1s          # % used per region, every second
jstat -gc <pid> 1s 10           # absolute numbers, 10 samples
```

The column that matters is `FGC` (full collections) and `FGCT` (total time in them). A `FGC` that grows steadily with a heap that never comes down is a leak, not a tuning problem.

#### Flight Recorder

The right tool for "it is slow in production and I cannot reproduce it":

```shell
jcmd <pid> JFR.start name=diag settings=profile duration=120s filename=/tmp/rec.jfr
jcmd <pid> JFR.check
jcmd <pid> JFR.dump name=diag filename=/tmp/rec.jfr     # dump without waiting
jcmd <pid> JFR.stop name=diag
```

Then open `rec.jfr` in JDK Mission Control. `settings=profile` costs a couple of percent of CPU; `settings=default` is designed to run permanently.

#### Flags worth having in production

```shell
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/dumps
-XX:+ExitOnOutOfMemoryError          # die instead of limping on in a broken state
-XX:MaxRAMPercentage=75.0            # in a container: see the Docker talk
-Xlog:gc*:file=/var/log/gc.log:time,uptime:filecount=5,filesize=20M
```

The first two cost nothing and are the difference between diagnosing an OOM and guessing about it.

```shell
java -XX:+PrintFlagsFinal -version | grep -i heapsize     # what the defaults ACTUALLY are
jcmd <pid> VM.flags                                       # what this process is running with
jcmd <pid> VM.system_properties
jcmd <pid> VM.uptime
```

`VM.flags` on a running process settles most arguments about whether a flag was actually applied.

#### Remote debug and JMX

```shell
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

`suspend=y` waits for the debugger before starting - useful for debugging startup, a hang otherwise.

```shell
-Dcom.sun.management.jmxremote
-Dcom.sun.management.jmxremote.port=9010
-Dcom.sun.management.jmxremote.rmi.port=9010
-Dcom.sun.management.jmxremote.local.only=false
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.ssl=false
```

Never expose that without authentication outside a trusted network: JMX allows invoking operations, not just reading them. Over SSH:

```shell
ssh -L 9010:localhost:9010 prod
```

#### Inspecting artifacts

```shell
jar tf app.jar | head                    # contents
unzip -p app.jar META-INF/MANIFEST.MF    # read one file without extracting
javap -p -c com.example.CarService       # bytecode, private members included
jdeps --multi-release 17 -s app.jar      # what it depends on
```

To find out which jar a class is really coming from when there are two versions on the classpath:

```shell
java -verbose:class -jar app.jar | grep CarService
```

#### jshell

```shell
jshell
jshell --class-path app.jar
jshell -q < script.jsh
```

Quicker than writing a `main` for checking what a regex does, how a date formats, or what a library call returns.

#### Maven

```shell
mvn -o clean install              # offline, uses only the local repository
mvn -T 1C clean install           # one thread per core
mvn -pl service-a -am install     # only that module AND what it depends on
mvn clean install -DskipTests     # compile tests, do not run them
mvn clean install -Dmaven.test.skip=true    # do not even compile them
```

```shell
mvn dependency:tree
mvn dependency:tree -Dincludes=org.slf4j           # WHO is pulling this in
mvn dependency:analyze                             # declared and unused, used and undeclared
mvn versions:display-dependency-updates
mvn help:effective-pom                             # the pom after inheritance and profiles
mvn help:active-profiles
```

`dependency:tree -Dincludes=` is the answer to every version conflict: it shows the path that brought in the wrong version.

```shell
mvn -X clean install > build.log 2>&1    # full debug, when something is inexplicable
mvn -q                                   # only errors
mvn clean install -U                     # force re-checking SNAPSHOTs
```

#### Formatting and quality, from the command line

```shell
mvn spotless:apply                       # format
mvn verify -Pcoverage                    # whatever the project calls it
mvn sonar:sonar -Dsonar.host.url=...     # see the SonarLint talk
```

#### Two snippets worth keeping

A JVM that is being killed by the kernel in a container leaves no stack trace. Confirm it from outside:

{% raw %}
```shell
docker inspect <container> --format '{{.State.OOMKilled}}'
dmesg -T | grep -i 'killed process'
```
{% endraw %}

And the fastest way to see whether an application is really listening where you think it is:

```shell
ss -tulpn | grep java
```
