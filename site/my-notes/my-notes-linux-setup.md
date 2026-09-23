### Linux Setup [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-linux-setup.md)

From a freshly installed Ubuntu to a working backend Java environment. Not the list of packages I install, which changes every year, but the decisions behind it: where things live, what is versioned and what must never be. The runnable version of all this is my [dotfiles](https://github.com/victor-porcar/dotfiles) repository.

---

#### The home directory

A `$HOME` that still makes sense after two years comes down to one rule: **separate what is versioned, what is secret and what is disposable.**

```text
~/
├── code/          repositories, mirroring the remote: work/ personal/ oss/ sandbox/
├── notes/         knowledge: decision records, runbooks, diagrams (a git repo too)
├── dotfiles/      my configuration, in git
├── bin/           my own scripts, on the PATH
├── access/        how I reach things: VPN profiles, client certificates
├── scratch/       logs, dumps, patches. Deleted without thinking
└── archive/       finished projects
```

Everything that matters is either in git (`code`, `notes`, `dotfiles`) or backed up (`access`). Anything else can be deleted, and that is the point: nothing valuable is ever just lying around in the home directory.

Hidden directories follow the [XDG](https://specifications.freedesktop.org/basedir-spec/latest/) convention: `~/.config` for configuration I edit, `~/.local/share` for application data, `~/.cache` for what can be regenerated. That last one can be emptied whenever the disk gets tight.

---

#### Dotfiles: the machine as code

The configuration is a git repository and a symlink farm. The files live in the repository and `$HOME` only holds links to them, so editing `~/.bashrc.extra` *is* editing the repository, and `git diff` shows what I changed today.

```shell
sudo apt install -y git
git clone git@github.com:victor-porcar/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

The links are made with [GNU Stow](https://www.gnu.org/software/stow/), one package per tool, each mirroring where it ends up:

```text
dotfiles/git/.gitconfig          ->  ~/.gitconfig
dotfiles/java/.bashrc.d/java.sh  ->  ~/.bashrc.d/java.sh
dotfiles/bin/bin/scratch         ->  ~/bin/scratch
```

Two habits make this pay off:

- **The installer is idempotent.** Running it again on a machine that is half set up is safe, which means it also works as "apply what I just committed".
- **It never overwrites.** An existing `~/.gitconfig` is moved to `~/.dotfiles-backup/<date>/` before linking. The day you run it on a machine you have been using for a year, nothing is lost.

The distribution's `~/.bashrc` is left alone; mine is loaded from its last line. Each tool brings its own file into `~/.bashrc.d/`, so adding Kubernetes to a machine means adding a directory, not editing a 400-line shell file.

---

#### Nothing personal in the repository

The repository is public, so no name, token or hostname enters it. Anything personal lives in files the installer creates once from a template and then never touches again:

```shell
~/.bashrc.local      # tokens and machine-specific variables, sourced last
~/.gitconfig.local   # name, email, a different identity for ~/code/work
~/.m2/settings.xml   # the company repository and its credentials
```

The pattern is always the same: the versioned file ends by including the local one. It is what lets the same repository work on a laptop at home and on a locked-down machine at work.

---

#### Tool versions are not the distribution's business

`apt install openjdk-21-jdk` is fine until the day one service still needs Java 8 and the new one wants 21. Version managers solve it per project and without `sudo`:

```shell
sdk install java 21.0.5-tem   # SDKMAN: JDKs, Maven, Gradle, Kotlin
sdk env init                  # writes .sdkmanrc: this project uses this JDK
nvm install --lts             # Node, for the same reason
```

With `sdkman_auto_env=true`, entering a project directory switches the JDK by itself. Worth knowing: [mise](https://mise.jdx.dev) does the job of SDKMAN, nvm and pyenv at once, with a single file per project.

---

#### Kubernetes: one file per cluster

Merging every cluster into a single `~/.kube/config` makes it impossible to remember what you are pointing at. One file per cluster and an environment variable is enough:

```shell
export KUBECONFIG="$HOME/.kube/config:$(find ~/.kube/configs -name '*.yaml' | paste -sd:)"
kubectl config use-context staging
```

And the prompt says where you are, in red when the context looks like production. It is two lines of shell and it prevents the mistake nobody wants to make:

```text
victor@laptop:~/code/work/api (main *) ⎈ minikube
$
```

---

#### Scripts belong on the PATH

A `vpn` alias only exists in an interactive shell: it is invisible to other scripts and to `cron`. A file in `~/bin` is a real command, takes arguments and works everywhere. The rules I follow:

- Something that changes the current shell (`cd`, exporting variables) has to be a **shell function**, not a script: a script runs in its own process and cannot touch your terminal.
- Everything else is a script in `~/bin`, without extension, so it can be rewritten in another language without renaming the command.
- Scripts tied to a project live inside that project, not here.

---

#### The setup is testable

The point of all this is the day the laptop dies. A container is enough to prove it works, on a machine that has never seen my configuration:

```shell
docker run -it --rm ubuntu:24.04 bash
# inside: install git, clone the repository, run install.sh, look at the result
```

My repository does that in a script and checks the outcome: symlinks made, `java` and `mvn` working, the backup taken, the installer runnable twice with the same result. An untested bootstrap is a bootstrap that does not exist.

---

#### The machine in English

Interface in English, formats (dates, numbers, paper size) in Spanish: error messages you can paste into a search engine are worth more than translated menus.

```shell
sudo update-locale LANG=en_US.UTF-8 LC_TIME=es_ES.UTF-8 LC_NUMERIC=es_ES.UTF-8 LC_PAPER=es_ES.UTF-8
LANG=C xdg-user-dirs-gtk-update      # Descargas -> Downloads, and friends
```

On Ubuntu 24.04 watch out for three files fighting over this: `/etc/default/locale` (read at login), `/etc/locale.conf` (what `update-locale` writes) and `~/.pam_environment` (what the Settings dialog writes, and the one that wins). Make them agree, then log out and in again.
