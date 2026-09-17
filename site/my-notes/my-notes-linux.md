### Linux Cheatsheet [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-linux.md)

Commands worth remembering, in the order you actually need them when something is wrong.

---

#### Shell survival

```shell
!!                      # the previous command
sudo !!                 # ...run again with sudo
!$                      # the last argument of the previous command
Ctrl-R                  # search backwards in history (press again to keep going)
Alt-.                   # insert the last argument of the previous command
cd -                    # back to the previous directory
Ctrl-X Ctrl-E           # open the current command line in $EDITOR
```

```shell
mkdir -p a/b/c          # no error if it exists, creates the whole path
cp file{,.bak}          # brace expansion -> cp file file.bak
mv report.{txt,md}      # -> mv report.txt report.md
touch file-{01..10}.log
```

Every script starts with this line. Without it a failing command is silently ignored and the script carries on:

```shell
set -euo pipefail
#  -e  stop on the first error
#  -u  fail on an undefined variable
#  -o pipefail  a failure anywhere in a pipe fails the whole pipe
```

```shell
trap 'rm -f "$TMP"' EXIT      # cleanup that runs even if the script dies
```

#### Finding files

```shell
find . -name '*.log' -mtime +7 -delete            # older than 7 days
find . -name '*.jar' -newer pom.xml               # modified after a reference file
find . -type f -size +100M -exec ls -lh {} +      # '+' batches, much faster than '\;'
find . -type d -name node_modules -prune -o -name '*.java' -print
find . -type f -mmin -10                          # changed in the last 10 minutes
```

`-exec ... +` passes many files per invocation; `-exec ... \;` runs the command once per file. On thousands of files the difference is minutes.

```shell
locate pom.xml          # instant, but from an index: updatedb to refresh
which java              # first match in PATH
readlink -f $(which java)   # resolve every symlink to the real binary
```

#### Text: the pipeline that answers most questions

```shell
sort | uniq -c | sort -rn | head -20
```

That one line is the workhorse: **top N of anything**. Most visited URLs, most frequent error, noisiest IP.

```shell
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head -20
grep -c 'ERROR' app.log                       # just count
grep -rn 'TODO' --include='*.java' src/       # recursive, only java, with line numbers
grep -A3 -B3 'OutOfMemory' app.log            # context around the hit
grep -v '^#' config.properties | grep -v '^$' # strip comments and blank lines
```

```shell
awk -F: '{print $1}' /etc/passwd              # custom separator
awk '$9 >= 500 {print}' access.log            # filter by a numeric field
awk '{sum+=$10} END {print sum/NR}' access.log   # average of a column
sed -i.bak 's/localhost/prod-db/g' *.properties  # in place, keeping a backup
cut -d, -f2,5 data.csv
tr -d '\r' < windows.txt > unix.txt           # strip CRLF
column -t -s,                                 # align a CSV into columns to read it
```

JSON without leaving the terminal:

```shell
curl -s localhost:8080/actuator/health | jq .
jq -r '.items[] | .metadata.name' pods.json
jq '.[] | select(.status=="FAILED")' results.json
```

#### Processes

```shell
ps aux --sort=-%mem | head              # who is eating the memory
ps -ef --forest                         # as a tree, to see who spawned what
pgrep -af java                          # pids matching, with the full command line
pkill -f 'my-service'                   # kill by pattern
```

```shell
kill -TERM <pid>        # ask politely (15) - the default, allows cleanup
kill -QUIT <pid>        # 3: on a JVM, prints a THREAD DUMP to stdout and keeps running
kill -KILL <pid>        # 9: last resort, no cleanup, no chance to flush anything
```

`kill -3` on a Java process is the fastest thread dump there is, with no tooling installed.

```shell
nohup ./long-job.sh > job.log 2>&1 &    # survives the terminal closing
disown -h %1                            # detach a job already running
timeout 30s ./flaky-command             # give up after 30 seconds
watch -n 2 'kubectl get pods'           # re-run every 2 seconds
```

```shell
strace -p <pid> -f -e trace=network     # what system calls it is making
lsof -p <pid>                           # everything that process has open
lsof -i :8080                           # WHO is holding the port
```

#### Performance: the first five minutes

In order, when a machine is slow:

```shell
uptime                  # load average: 1, 5, 15 minutes
vmstat 1 5              # r = runnable, b = blocked, si/so = swapping
free -h                 # careful: 'available' is the real number, not 'free'
iostat -x 1             # %util near 100 = disk is the bottleneck, await = latency
pidstat -u 1            # CPU per process, over time
ss -s                   # socket summary
```

Two readings that are worth knowing:

- **load average** is not a percentage. It is the number of processes wanting CPU. Compare it against `nproc`: a load of 8 on 8 cores is full; on 2 cores it is a queue.
- **`free` low is not a problem.** Linux uses free memory as cache on purpose. The number that matters is `available`, and the one that really matters is `si/so` in `vmstat`: if it is swapping, the machine is already in trouble.

#### Disk

```shell
df -h                   # space
df -i                   # INODES - a disk that is "full" with space left is this
du -sh * | sort -h      # what is taking the space, here
du -h --max-depth=2 /var | sort -h | tail -20
ncdu /var               # interactive, much faster to explore
```

The classic that catches everybody: **deleted files still held open by a process**. `du` does not see them, `df` does:

```shell
lsof +L1                # open files with no name left on disk
```

A log rotated badly and still held by the JVM can be occupying gigabytes that no `du` will ever show. The space comes back when the process closes the descriptor, or when it restarts.

#### Network

```shell
ss -tulpn               # listening ports with the owning process (netstat is deprecated)
ss -tan state established | wc -l       # how many open connections
```

```shell
curl -sS -o /dev/null -w 'dns=%{time_namelookup}s connect=%{time_connect}s tls=%{time_appconnect}s ttfb=%{time_starttransfer}s total=%{time_total}s\n' https://example.com
```

That is the one to reach for when "the service is slow": it splits the latency into DNS, TCP, TLS and time to first byte, and usually the answer is obvious.

```shell
curl -v --resolve api.example.com:443:10.0.0.7 https://api.example.com/health   # bypass DNS
dig +short api.example.com
dig @8.8.8.8 api.example.com            # ask a specific resolver
getent hosts api.example.com            # what the SYSTEM resolves, /etc/hosts included
nc -zv db-host 5432                     # is the port open at all
traceroute -T -p 443 api.example.com
tcpdump -i any -nn port 5432 -c 100     # 100 packets and stop
```

#### systemd and logs

```shell
systemctl status my-service
systemctl list-units --failed           # what is broken, right now
systemctl cat my-service                # the effective unit file, overrides included
systemctl daemon-reload                 # after editing a unit
```

```shell
journalctl -u my-service -f                     # follow
journalctl -u my-service --since '30 min ago'
journalctl -u my-service -p err..alert          # errors and worse only
journalctl -u my-service -b -1                  # the PREVIOUS boot
journalctl --disk-usage
```

#### SSH and copying

`~/.ssh/config` is the file that saves the most typing:

```
Host prod
    HostName 10.20.30.40
    User victor
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60

Host db-prod
    HostName 10.0.0.7
    ProxyJump prod                # reach it through the bastion, transparently
```

```shell
ssh prod                                  # that is it
ssh -L 5432:db-internal:5432 prod         # local tunnel: localhost:5432 -> remote db
ssh -J bastion internal-host              # jump host without config
ssh-copy-id prod                          # install the public key
ssh prod 'journalctl -u my-service -n 200'  # run and come back
```

```shell
rsync -avz --progress src/ prod:/opt/app/     # only what changed, compressed
rsync -avz --dry-run --delete src/ prod:/opt/app/   # ALWAYS dry-run before --delete
scp prod:/var/log/app.log .
```

#### Permissions

```shell
chmod 640 file          # owner rw, group r, others nothing
chmod +x script.sh
chown -R app:app /opt/app
umask 027               # new files: 640, new directories: 750
sudo -u postgres psql   # run as another user
```

Reading octal: **4 read, 2 write, 1 execute**, added up, in order owner-group-others. `750` is `rwxr-x---`.

On a directory, `x` means "may enter", not "may execute". A directory with `r` but no `x` can be listed but nothing inside it can be opened.

#### Java installed on the system

Register all versions and switch between them:

```shell
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/java-8-openjdk-amd64/bin/javaws" 1
...
sudo update-alternatives --config java
```

```shell
update-alternatives --list java         # what is registered
readlink -f $(which java)               # which one is actually running
```

#### Loops and repetition

```shell
while true; do echo 'hola'; sleep 1; done
```

```shell
for f in *.log; do gzip "$f"; done
for i in {1..10}; do curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/health; done
until curl -sf localhost:8080/health; do sleep 2; done   # wait for something to come up
```

Parallel, which is the one people forget:

```shell
find . -name '*.png' | xargs -P 8 -I{} optipng {}    # 8 at a time
xargs -0 < files.txt                                  # null separated, survives spaces
```

#### Two things that save the day

```shell
command | tee output.log                # see it AND save it
diff <(sort a.txt) <(sort b.txt)        # process substitution: compare on the fly
```

```shell
tmux new -s work        # a session that survives disconnection
tmux attach -t work
#  Ctrl-B D  detach      Ctrl-B "  split horizontal      Ctrl-B %  split vertical
```

For anything long running on a remote machine: start it inside `tmux`. The SSH connection will drop eventually, and without it the job dies with it.

#### Downloading video (yt-dlp)

```shell
# download best quality webm
./yt-dlp_linux "https://www.youtube.com/watch?v=zSpA-DuLSIQ"

# download best quality in mp4
./yt-dlp_linux "https://www.youtube.com/watch?v=zSpA-DuLSIQ" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
```

```shell
./yt-dlp_linux -F "<url>"                  # list every available format
./yt-dlp_linux -x --audio-format mp3 "<url>"   # audio only
```
