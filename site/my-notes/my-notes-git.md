### Git Cheatsheet [<img align="right" src="../../site/images/pencil.svg" width="14">](https://github.com/victor-porcar/victor-porcar.github.io/edit/master/site/my-notes/my-notes-git.md)

Beyond `add`, `commit` and `push`: what is actually worth knowing.

---

#### Investigating history

```shell
git log --oneline --graph --decorate --all      # the only log worth looking at
git log --since='2 weeks ago' --author=victor
git log --stat                                  # which files, how many lines
git log -p -- src/main/java/CarService.java     # the full history of ONE file
```

The two that nobody uses and solve the hardest questions:

```shell
git log -S'calculatePrice' --oneline    # commits where that string APPEARED or DISAPPEARED
git log -G'regex' --oneline             # same, but matching a regular expression
git log -L 40,60:CarService.java        # the history of those lines only
```

`-S` is the pickaxe: *"when was this deleted, and by whom"*. It is the fastest answer to "this code used to exist".

```shell
git blame -w -C -M CarService.java
#  -w  ignore whitespace changes
#  -C  detect code moved from another file
#  -M  detect code moved inside the file
```

Plain `git blame` blames whoever reformatted the file. With `-w -C -M` it blames whoever actually wrote the line.

```shell
git show <sha>                  # the whole commit
git show <sha>:path/to/File.java    # the file AS IT WAS in that commit
git diff main...feature         # what feature added since it forked (three dots)
git diff main..feature          # difference between the two tips (two dots)
```

The three-dot form is almost always what you want when reviewing a branch.

#### Finding the commit that broke it

```shell
git bisect start
git bisect bad                  # current one is broken
git bisect good v1.4.0          # this one worked
# git checks out a commit in the middle: test it and say
git bisect good    ...or...    git bisect bad
git bisect reset                # when it tells you which one it is
```

Automated, which is the version that is genuinely worth it:

```shell
git bisect start HEAD v1.4.0
git bisect run mvn -q test -Dtest=CarServiceTest
```

It walks the history on its own and prints the guilty commit. Over 500 commits it is 9 tests, not 500.

#### Undoing things

The three resets, which is the question everybody gets wrong:

```shell
git reset --soft HEAD~1     # undo the commit, KEEP the changes staged
git reset --mixed HEAD~1    # undo the commit, keep the changes unstaged (default)
git reset --hard HEAD~1     # undo the commit AND throw the changes away
```

```shell
git revert <sha>            # a NEW commit that undoes it - the only safe one on a shared branch
git restore --staged file   # unstage, keep the change
git restore file            # discard local changes to the file (destructive)
git commit --amend --no-edit    # add what is staged to the last commit
```

Rule of thumb: **`reset` rewrites history, `revert` adds to it.** On anything already pushed and shared, `revert`.

#### The safety net

```shell
git reflog
```

Everything `HEAD` has pointed at, including what a `reset --hard` supposedly destroyed. A commit is not gone until garbage collection runs, weeks later.

```shell
git reflog                       # find the sha from before the disaster
git reset --hard HEAD@{3}        # go back to it
git branch recovered <sha>       # or rescue it into a branch
```

```shell
git fsck --lost-found            # dangling commits, when even the reflog is not enough
```

#### Rewriting before pushing

```shell
git rebase -i HEAD~5
#  pick    keep
#  reword  change the message
#  squash  merge into the previous one, combining messages
#  fixup   merge into the previous one, discarding the message
#  drop    remove the commit
```

The workflow that makes this painless:

```shell
git commit --fixup <sha>            # a commit marked as "this belongs to that one"
git rebase -i --autosquash HEAD~10  # reorders and marks them as fixup automatically
```

```shell
git rebase --onto main old-base feature   # move a branch to another base
git rebase --abort                        # get out of the mess
git rebase --continue
```

#### Pushing without destroying other people's work

```shell
git push --force-with-lease
```

**Never `--force`.** `--force-with-lease` refuses to push if somebody else pushed to that branch since your last fetch. `--force` overwrites their work silently, and by the time anybody notices it is gone.

#### Staging with precision

```shell
git add -p                  # hunk by hunk: y, n, s to split, e to edit
git checkout -p             # discard changes, hunk by hunk
git stash -p                # stash only part of it
```

`git add -p` is the difference between a clean commit and one that drags in three unrelated changes.

#### Stash and worktree

```shell
git stash push -m 'wip pricing'
git stash list
git stash show -p stash@{0}
git stash pop                   # apply and remove
git stash apply                 # apply and KEEP it in the list
git stash push -u               # include untracked files
```

When the interruption is going to last, `stash` is the wrong tool:

```shell
git worktree add ../hotfix main     # a SECOND working directory, same repository
cd ../hotfix                        # fix, commit, push
git worktree remove ../hotfix
```

Two branches checked out at once, no stash, no rebuilding the IDE index. This is the one that most people do not know exists.

#### Cherry-pick

```shell
git cherry-pick <sha>
git cherry-pick <sha1>^..<sha3>     # a range
git cherry-pick -n <sha>            # apply without committing
```

#### Searching the working tree

```shell
git grep 'calculatePrice'                 # much faster than grep: only tracked files
git grep -n 'TODO' $(git rev-list --all)  # across the ENTIRE history
git grep -l 'deprecated' -- '*.java'
```

#### Cleaning

```shell
git clean -nd               # DRY RUN first, always
git clean -fd               # remove untracked files and directories
git clean -fdx              # ...including ignored ones (target/, node_modules/)
```

`-n` first. `git clean -fdx` deletes things git has never seen and cannot recover.

#### Configuration worth having

```shell
git config --global pull.rebase true          # no merge commits on every pull
git config --global rerere.enabled true       # remembers how you resolved a conflict
git config --global fetch.prune true          # remove local refs to deleted remote branches
git config --global diff.algorithm histogram  # noticeably better diffs
git config --global init.defaultBranch main
```

`rerere` is the underrated one: on a long rebase with the same conflict appearing again and again, it resolves it for you after the first time.

```shell
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.st "status -sb"
git config --global alias.last "log -1 HEAD --stat"
```

#### Repository hygiene

```shell
git count-objects -vH           # how big is this thing
git gc --aggressive --prune=now
git maintenance start           # schedule it automatically (git 2.30+)
```

```shell
git shortlog -sn --all          # commits per author
git rev-parse --abbrev-ref HEAD # current branch name, for scripts
git describe --tags --always    # a readable version for a build
```

That last one is what belongs in the `/actuator/info` of a service: it tells you exactly which commit is running.
