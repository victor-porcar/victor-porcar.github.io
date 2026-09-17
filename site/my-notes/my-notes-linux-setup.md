### Linux Setup [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-linux-setup.md)

From a freshly installed Ubuntu to a working backend Java environment. Follow it top to bottom, or jump to the [bootstrap script](#the-whole-thing-as-a-script) at the end.

Tested on Ubuntu 22.04 and 24.04. Everything here is idempotent: running it twice does not break anything.

---

#### 0. Before anything

```shell
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  build-essential curl wget git unzip zip tar \
  ca-certificates gnupg apt-transport-https software-properties-common \
  jq tree htop ncdu tmux \
  net-tools iproute2 dnsutils lsof strace traceroute \
  ripgrep fd-find bat
```

Two Ubuntu quirks worth fixing immediately, because they waste an afternoon otherwise: `bat` installs as **`batcat`** and `fd-find` as **`fdfind`**, both to avoid name clashes. Link them to the names every piece of documentation uses:

```shell
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat
ln -sf /usr/bin/fdfind ~/.local/bin/fd
```

`~/.local/bin` is already on the `PATH` in Ubuntu's default `.profile`, but only if it existed when you logged in. Log out and back in, or `source ~/.profile`.

---

#### 1. Directory structure

The layout matters less than having one and sticking to it. This is the one assumed by the rest of this note:

```
~/workspaces/          # one directory per client, org or context
   MY_GITHUB/
   acme/
       car-service/
       pricing-service/
~/bin/                 # your own scripts, on the PATH
~/opt/                 # tools installed by hand (not apt, not snap)
~/kubeconfig/          # one file per cluster, never merged into ~/.kube/config
~/dumps/               # heap dumps, thread dumps, JFR recordings
~/tmp/                 # scratch, safe to wipe
```

```shell
mkdir -p ~/workspaces ~/bin ~/opt ~/kubeconfig ~/dumps ~/tmp
```

Two decisions in there that are worth arguing for:

**`~/kubeconfig/` with one file per cluster** instead of everything merged into `~/.kube/config`. Merging makes `kubectl config use-context` the only thing standing between you and applying a manifest to production. Separate files mean you have to name the cluster explicitly, and that friction is the point. It is also what the [kubenv](../my-scripts/kubenv) script expects.

**`~/dumps/` as a real directory**, because the JVM flag that saves the day - `-XX:HeapDumpPath` - needs somewhere to write, and `/tmp` gets cleaned.

---

#### 2. Shell

Ubuntu's default `.bashrc` already sources `~/.bash_aliases` if it exists, so put everything there and leave `.bashrc` alone:

{% raw %}
```shell
cat >> ~/.bash_aliases <<'EOF'
# ---------- paths ----------
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export EDITOR=vim

# ---------- history ----------
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTCONTROL=ignoreboth:erasedups     # no duplicates, no leading-space commands
shopt -s histappend                          # several terminals do not overwrite each other
shopt -s cdspell                             # tolerate typos in cd

# ---------- navigation ----------
alias ws='cd ~/workspaces'
alias ll='ls -alFh'
alias ..='cd ..'
alias ...='cd ../..'

# ---------- git (see the Git cheatsheet) ----------
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gp='git pull --rebase'

# ---------- maven ----------
alias mci='mvn clean install'
alias mcist='mvn clean install -DskipTests'
alias mvnq='mvn -q'

# ---------- docker ----------
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlog='docker logs -f --tail 200'
alias dsh='docker exec -it'

# ---------- kubernetes ----------
alias k='kubectl'
alias kgp='kubectl get pods'
alias kdp='kubectl describe pod'
alias kl='kubectl logs -f'
alias kctx='kubectl config current-context'

# which cluster am I talking to, in the prompt
kube_ctx() { kubectl config current-context 2>/dev/null; }
EOF
```
{% endraw %}

Then a couple of functions that earn their place:

```shell
cat >> ~/.bash_aliases <<'EOF'
# mkdir and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# which process is holding a port
port() { sudo lsof -i :"$1"; }

# extract anything
ex() {
  case "$1" in
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.bz2)      tar xjf "$1" ;;
    *.tar.xz)       tar xJf "$1" ;;
    *.zip)          unzip "$1"   ;;
    *.gz)           gunzip "$1"  ;;
    *) echo "unknown format: $1" ;;
  esac
}

# a JVM's thread dump, straight to a file in ~/dumps
td() { jcmd "$1" Thread.print > ~/dumps/threads-$(date +%Y%m%d-%H%M%S).txt && ls -1t ~/dumps | head -1; }
EOF

source ~/.bash_aliases
```

The `HISTCONTROL=ignoreboth:erasedups` and `shopt -s histappend` pair is the one people notice: several open terminals stop overwriting each other's history, and `Ctrl-R` stops showing the same command twenty times.

---

#### 3. Java, Maven and Gradle: SDKMAN

Do **not** install the JDK from apt. A backend developer needs several versions and has to switch between them per project, and apt makes that painful.

```shell
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

```shell
sdk list java                      # see what is actually available today
sdk install java 21.0.5-tem        # Temurin 21 (LTS)
sdk install java 17.0.13-tem       # for the projects still on 17
sdk install java 8.0.432-tem       # there is always one
sdk install maven
sdk install gradle
```

```shell
sdk use java 17.0.13-tem       # this shell only
sdk default java 21.0.5-tem    # the default from now on
sdk current java
```

SDKMAN sets `JAVA_HOME` and the `PATH` for you, which is exactly what `update-alternatives` does badly. There is a `.sdkmanrc` per project:

```shell
cd ~/workspaces/acme/car-service
sdk env init        # writes .sdkmanrc with the current version
sdk env             # from then on, applies it on entering the directory
```

Commit that file: it removes the "works on my machine because I am on 17" conversation.

##### Maven settings

```shell
mkdir -p ~/.m2
```

`~/.m2/settings.xml` is where the corporate repository, the proxy and the credentials go. Keep it out of any repository, and if there is a company template, start from it. What is worth adding on a personal machine:

```xml
<settings>
  <localRepository>${user.home}/.m2/repository</localRepository>
  <interactiveMode>false</interactiveMode>
</settings>
```

---

#### 4. Docker

Use the official repository, not the `docker.io` package from Ubuntu, which lags behind and does not ship the compose plugin:

```shell
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

The step everybody forgets, and then runs everything with `sudo` forever:

```shell
sudo usermod -aG docker $USER
newgrp docker            # applies it to THIS shell; other shells need a re-login
docker run --rm hello-world
```

Being in the `docker` group is equivalent to root on the machine. That is a known and accepted trade on a development laptop; it is not acceptable on a shared server.

```shell
sudo systemctl enable --now docker
docker compose version      # 'docker compose', not 'docker-compose'
```

See the [Docker and Kubernetes cheatsheet](my-notes-docker-kubernetes.html) and the [Introduction to Docker](../my-techtalks/TechTalk-Introduction-to-Docker) talk.

---

#### 5. Kubernetes tooling

```shell
# kubectl, from the official repository (adjust the minor version)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update && sudo apt install -y kubectl
```

```shell
# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# k9s: a terminal UI over the cluster, the fastest way to look around
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
curl -sL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
  | tar xz -C ~/opt k9s && ln -sf ~/opt/k9s ~/.local/bin/k9s
```

Completion, which is what makes `kubectl` usable:

```shell
echo 'source <(kubectl completion bash)' >> ~/.bash_aliases
echo 'complete -o default -F __start_kubectl k' >> ~/.bash_aliases   # so 'k' completes too
```

That second line is the one nobody tells you: without it the `k` alias loses completion, which defeats the point of the alias.

---

#### 6. Git and SSH

```shell
git config --global user.name "Víctor Porcar"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global fetch.prune true
git config --global rerere.enabled true
git config --global diff.algorithm histogram
git config --global core.editor vim
```

```shell
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub        # paste into github.com/settings/ssh/new
ssh -T git@github.com            # verify
```

`~/.ssh/config` is the file that saves the most typing over a career:

```
Host github.com
    IdentityFile ~/.ssh/id_ed25519

Host bastion
    HostName 10.20.30.40
    User victor
    ServerAliveInterval 60

Host db-prod
    HostName 10.0.0.7
    ProxyJump bastion
```

```shell
chmod 700 ~/.ssh && chmod 600 ~/.ssh/config ~/.ssh/id_ed25519
```

More in the [Git cheatsheet](my-notes-git.html).

---

#### 7. Editors and IDEs

```shell
# IntelliJ IDEA - Toolbox manages versions and updates better than snap
# https://www.jetbrains.com/toolbox-app/   (download, tar xzf into ~/opt, run it)
sudo snap install intellij-idea-ultimate --classic    # or intellij-idea-community

# VS Code
sudo snap install code --classic
```

```shell
# Sublime Text, from the official repository
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/sublimehq-archive.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" \
  | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update && sudo apt install -y sublime-text
```

Sublime earns its place next to a full IDE for one reason: **it opens a 2 GB log file instantly**, which IntelliJ will not do. `subl` from the command line:

```shell
subl app.log
subl .          # the whole directory
```

##### The IntelliJ setting that is not in IntelliJ

On a large repository the IDE runs out of file watchers and silently stops detecting changes on disk:

```shell
echo 'fs.inotify.max_user_watches = 524288' | sudo tee /etc/sysctl.d/60-inotify.conf
sudo sysctl --system
```

The symptom is maddening precisely because nothing fails: you change a file with git and the IDE does not notice.

---

#### 8. APIs, databases and the rest

```shell
sudo snap install postman
sudo snap install dbeaver-ce           # SQL client for everything, Oracle included
sudo apt install -y httpie             # 'http GET localhost:8080/api/cars'
```

```shell
# yq: jq for YAML - essential once there are manifests around
YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name)
sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
sudo chmod +x /usr/local/bin/yq
```

```shell
# PostgreSQL client only, without installing a server
sudo apt install -y postgresql-client

# Oracle: SQLcl needs a JDK, which SDKMAN already gave us
# download from oracle.com, unzip into ~/opt/sqlcl
ln -sf ~/opt/sqlcl/bin/sql ~/.local/bin/sql
```

Useful extras:

```shell
sudo apt install -y meld           # visual diff, integrates with git
sudo apt install -y flameshot      # screenshots with annotation
sudo snap install drawio           # diagrams, and the source is a file you can commit
```

---

#### 9. Desktop shortcuts

The terminal shortcut is worth setting on day one. In Ubuntu, `Ctrl-Alt-T` already opens one; to make it something else, or to add a second binding:

```shell
BASE=/org/gnome/settings-daemon/plugins/media-keys
dconf write $BASE/custom-keybindings "['$BASE/custom-keybindings/custom0/']"
dconf write $BASE/custom-keybindings/custom0/name "'Terminal'"
dconf write $BASE/custom-keybindings/custom0/command "'gnome-terminal'"
dconf write $BASE/custom-keybindings/custom0/binding "'<Super>Return'"
```

The ones worth knowing without configuring anything:

| Shortcut | What it does |
|---|---|
| `Super` | activities and search - the fastest app launcher |
| `Super` + `Left` / `Right` | snap the window to half the screen |
| `Super` + `Page Up` / `Page Down` | switch workspace |
| `Alt` + `F2` then `r` | restart GNOME Shell without losing the session |
| `Ctrl` + `Alt` + `T` | terminal |

In the terminal itself, `Ctrl-Shift-T` for a new tab and `Alt-<number>` to jump to one.

---

#### 10. Verify it all worked

```shell
cat <<'EOF' > ~/bin/check-setup
#!/usr/bin/env bash
for c in git java javac mvn gradle docker kubectl helm jq yq rg fd bat tmux subl; do
  printf '%-10s %s\n' "$c" "$(command -v "$c" || echo 'MISSING')"
done
echo
java -version 2>&1 | head -1
mvn -v 2>/dev/null | head -1
docker --version
kubectl version --client --output=yaml 2>/dev/null | grep gitVersion
EOF
chmod +x ~/bin/check-setup && ~/bin/check-setup
```

---

#### The whole thing as a script

Everything above, idempotent, safe to re-run. Read it before running it - that applies to any script that starts with `sudo`.

```shell
cat <<'SCRIPT' > ~/bin/ubuntu-setup.sh
#!/usr/bin/env bash
set -euo pipefail

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

log "base packages"
sudo apt update
sudo apt install -y build-essential curl wget git unzip zip tar \
  ca-certificates gnupg apt-transport-https software-properties-common \
  jq tree htop ncdu tmux net-tools iproute2 dnsutils lsof strace \
  ripgrep fd-find bat meld postgresql-client httpie

log "directories"
mkdir -p ~/workspaces ~/bin ~/opt ~/kubeconfig ~/dumps ~/tmp ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat
ln -sf /usr/bin/fdfind ~/.local/bin/fd

log "docker"
if ! have docker; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  echo "NOTE: log out and back in for the docker group to apply"
fi

log "kubectl"
if ! have kubectl; then
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt update && sudo apt install -y kubectl
fi

log "helm"
have helm || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

log "sdkman, jdks, maven"
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
fi
set +u; source "$HOME/.sdkman/bin/sdkman-init.sh"; set -u
sdk install java 21.0.5-tem   || true
sdk install java 17.0.13-tem  || true
sdk install maven             || true
sdk install gradle            || true

log "sublime text"
if ! have subl; then
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
    | gpg --dearmor | sudo tee /etc/apt/keyrings/sublimehq-archive.gpg > /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" \
    | sudo tee /etc/apt/sources.list.d/sublime-text.list
  sudo apt update && sudo apt install -y sublime-text
fi

log "snaps"
have code    || sudo snap install code --classic
have postman || sudo snap install postman
sudo snap list dbeaver-ce >/dev/null 2>&1 || sudo snap install dbeaver-ce

log "inotify watches for the IDE"
echo 'fs.inotify.max_user_watches = 524288' | sudo tee /etc/sysctl.d/60-inotify.conf > /dev/null
sudo sysctl --system > /dev/null

log "done - open a new terminal, then run: check-setup"
SCRIPT
chmod +x ~/bin/ubuntu-setup.sh
```

```shell
~/bin/ubuntu-setup.sh
```

What the script deliberately does **not** do: configure git with your name and email, generate the SSH key, or write `~/.bash_aliases`. Those are personal and worth typing once, consciously, from the sections above.

---

#### After a re-install, the short version

```shell
# 1. the script
curl -fsSL <your gist or repo>/ubuntu-setup.sh | less    # read it first
~/bin/ubuntu-setup.sh

# 2. identity
git config --global user.name "..." && git config --global user.email "..."
ssh-keygen -t ed25519 -C "..." -f ~/.ssh/id_ed25519 -N "" && cat ~/.ssh/id_ed25519.pub

# 3. aliases, from section 2
# 4. log out and back in (docker group, PATH)
# 5. check-setup
```

The one thing worth keeping in a repository of its own is `~/.bash_aliases` and `~/.ssh/config`. Those two files are most of what makes a machine feel like yours, and they are the two that nobody backs up.
