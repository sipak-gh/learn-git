# Appendix A — Cheat Sheet

Git commands at a glance, grouped by task, with the chapter that explains each. Commands marked † need a newer Git than the 2.34.1 used in this course (see the chapters for what was and was not tested). Full plumbing and format details: [Appendix B](appendix-b-plumbing-and-file-formats.md).

## Setup and help

| Command | Does | Ch |
|---|---|---|
| `git config --global user.name "N"` / `user.email "E"` | set identity | [1](01-mental-model-and-setup.md) |
| `git config --list --show-origin` | all settings and where they come from | [1](01-mental-model-and-setup.md) |
| `git help <cmd>` / `git <cmd> -h` | manual page / short usage | [1](01-mental-model-and-setup.md) |
| `git init [-b main]` / `git clone <url>` | new repo / copy a repo | [2](02-the-everyday-loop.md) |

## Everyday loop

| Command | Does | Ch |
|---|---|---|
| `git status -sb` | short status with branch | [2](02-the-everyday-loop.md) |
| `git add -p` / `git add -N f` | stage hunks / intent-to-add | [2](02-the-everyday-loop.md), [5](05-the-index.md) |
| `git commit -m M` / `-a` / `--amend` | commit / auto-stage tracked / rewrite last | [2](02-the-everyday-loop.md), [10](10-rewriting-history.md) |
| `git diff` / `--staged` / `A..B` / `--stat` | working vs index / index vs HEAD / between commits | [2](02-the-everyday-loop.md) |
| `git restore f` / `--staged f` / `--source=<rev> f` | discard / unstage / restore from a commit | [2](02-the-everyday-loop.md), [11](11-stash-worktrees-and-cleaning.md) |
| `git rm [--cached] f` / `git mv a b` | delete or untrack / rename | [2](02-the-everyday-loop.md) |
| `git log --oneline --graph --decorate --all` | compact history graph | [2](02-the-everyday-loop.md), [8](08-reading-and-searching-history.md) |

## Branches and merging

| Command | Does | Ch |
|---|---|---|
| `git switch b` / `-c b` / `-` | change / create / previous branch | [3](03-branches-merging-remotes-brief.md) |
| `git branch [-vv] [-d\|-D] b` | list with upstream / delete | [3](03-branches-merging-remotes-brief.md) |
| `git merge [--no-ff\|--ff-only\|--squash] b` | merge (`--squash`: stage the changes, no merge recorded) | [3](03-branches-merging-remotes-brief.md), [9](09-diff-and-merge-internals.md) |
| `git merge --abort` / `git rerere` | abort / reuse recorded resolutions | [9](09-diff-and-merge-internals.md) |
| `git checkout --ours/--theirs f` | pick one side of a conflict | [9](09-diff-and-merge-internals.md) |
| `git config merge.conflictStyle diff3` | show the base in markers (`zdiff3` † needs 2.35) | [9](09-diff-and-merge-internals.md) |

## Inspecting objects and refs (plumbing)

| Command | Does | Ch |
|---|---|---|
| `git cat-file -t\|-p\|-s <obj>` | type / content / size | [4](04-the-object-database.md) |
| `git hash-object [-w] f` | hash (and store) a blob | [4](04-the-object-database.md) |
| `git ls-tree -r <tree-ish>` / `git ls-files -s` | tree contents / index entries | [4](04-the-object-database.md), [5](05-the-index.md) |
| `git write-tree` / `git commit-tree` / `git update-ref` | build a commit by hand | [4](04-the-object-database.md), [6](06-references-and-head.md) |
| `git rev-parse <rev>` / `git rev-list A..B` | resolve / list commits | [7](07-revisions-and-ranges.md) |
| `git for-each-ref` / `git symbolic-ref HEAD` | list refs / read HEAD | [6](06-references-and-head.md) |
| `git reflog [show <ref>]` | where refs used to point | [6](06-references-and-head.md) |
| `git merge-base A B` | best common ancestor | [7](07-revisions-and-ranges.md) |

## Revision syntax

| Syntax | Meaning |
|---|---|
| `HEAD~2`, `HEAD^2` | grandparent via first parents / second parent of a merge |
| `@{1}`, `@{yesterday}`, `main@{upstream}` (`@{u}`) | reflog position / time / upstream |
| `:/text` | newest commit whose message matches |
| `A..B` | reachable from B but not A |
| `A...B` | symmetric difference (log) / merge-base diff (diff) |
| `A^@`, `A^!`, `A^-` | A's parents (and ancestors) / A alone / `A^1..A` |
| `@{u}..`, `..@{u}` | a missing side means `HEAD`: unpushed / unpulled |
| `v1.0^{commit}`, `HEAD^{tree}` | peel to a type |
| `rev:path`, `:0:path`, `:2:path` | file at a commit; index stage 0 / 2 (ours) |

See [Chapter 7](07-revisions-and-ranges.md).

## History search

| Command | Does | Ch |
|---|---|---|
| `git log -S str` / `-G regex` | pickaxe (count change / diff match) | [8](08-reading-and-searching-history.md) |
| `git log -L 10,20:f` / `-L :func:f` | history of a line range / function | [8](08-reading-and-searching-history.md) |
| `git blame -w -M -C f` | blame ignoring whitespace, detecting moves/copies | [8](08-reading-and-searching-history.md) |
| `git shortlog -sn <rev>` / `git describe` | counts per author / nearest tag name | [8](08-reading-and-searching-history.md) |
| `git bisect start BAD GOOD` / `run cmd` / `reset` | binary search for a bug | [8](08-reading-and-searching-history.md), [17](17-debugging-and-recovery.md) |
| `git grep -n pat [rev]` | search tracked content | [8](08-reading-and-searching-history.md) |
| `git range-diff A...B` | compare two versions of a series | [8](08-reading-and-searching-history.md) |

## Rewriting history

| Command | Does | Ch |
|---|---|---|
| `git reset --soft\|--mixed\|--hard <rev>` | move branch; keep index+tree / reset index / reset all | [10](10-rewriting-history.md) |
| `git reset --keep <rev>` | like `--hard`, but refuses to overwrite local changes | [10](10-rewriting-history.md) |
| `git revert [-m 1] <rev>` | new commit undoing one | [10](10-rewriting-history.md) |
| `git cherry-pick [-x] <rev>` | copy a commit | [10](10-rewriting-history.md) |
| `git rebase [-i] [--onto N U] [-x cmd] [--autosquash] [--rebase-merges] <upstream>` | replay commits | [10](10-rewriting-history.md) |
| `git commit --fixup=[amend:\|reword:]<rev>` | fixup commit for `--autosquash` (`amend:`/`reword:` 2.32+) | [10](10-rewriting-history.md) |
| `git rebase --update-refs` † | move stacked branches (needs 2.38) | [10](10-rewriting-history.md) |
| `git reflog` + `git reset --hard HEAD@{n}` | undo | [10](10-rewriting-history.md), [17](17-debugging-and-recovery.md) |
| `git replace --graft <c> [<parent>…]` / `-d <c>` | read-time substitute for an object | [10](10-rewriting-history.md) |
| `git fast-export --all \| git fast-import` | history as a text stream and back | [10](10-rewriting-history.md) |

Rule: never rewrite history others have based work on.

## Stash, worktrees, clean

| Command | Does | Ch |
|---|---|---|
| `git stash push [-u\|-a] [-m M] [-p] [-- paths]` | save changes | [11](11-stash-worktrees-and-cleaning.md) |
| `git stash list\|show -p\|apply\|pop\|drop\|branch` | manage stashes | [11](11-stash-worktrees-and-cleaning.md) |
| `git worktree add\|list\|move\|remove\|prune\|repair` | extra working directories | [11](11-stash-worktrees-and-cleaning.md) |
| `git clean -n[dx]` then `-f[dx]` | preview, then delete untracked | [11](11-stash-worktrees-and-cleaning.md) |

## Remotes

| Command | Does | Ch |
|---|---|---|
| `git remote add\|-v\|show\|rename\|remove\|set-url` | manage remotes | [12](12-remotes-in-depth.md) |
| `git fetch [--prune] [--all]` | update remote-tracking refs | [12](12-remotes-in-depth.md) |
| `git pull --ff-only\|--rebase` | fetch + integrate | [12](12-remotes-in-depth.md) |
| `git push -u origin b` / `--force-with-lease [--force-if-includes]` / `--delete` / `--tags` / `--atomic` | publish | [12](12-remotes-in-depth.md) |
| `git branch -u origin/b` / `git config branch.b.remote` | upstream | [12](12-remotes-in-depth.md) |
| `git ls-remote <url>` | list remote refs | [12](12-remotes-in-depth.md) |
| refspec `+refs/heads/*:refs/remotes/origin/*` | `[+]src:dst` mapping | [12](12-remotes-in-depth.md) |

## Storage, transport, maintenance

| Command | Does | Ch |
|---|---|---|
| `git count-objects -vH` | loose vs packed sizes | [13](13-transport-and-packfiles.md) |
| `git gc [--prune=now]` / `git repack -ad` / `git prune` | pack and clean | [13](13-transport-and-packfiles.md) |
| `git verify-pack -v f.idx` | pack contents and deltas | [13](13-transport-and-packfiles.md) |
| `git fsck [--lost-found] [--strict]` | check integrity, find dangling | [13](13-transport-and-packfiles.md), [17](17-debugging-and-recovery.md) |
| `git bundle create f.bundle <refs>` / `verify` | repo in a file | [13](13-transport-and-packfiles.md) |
| `git clone --depth N` / `--filter=blob:none` | shallow / partial | [13](13-transport-and-packfiles.md) |
| `git maintenance run\|register` | scheduled tasks (`start` scheduler not tested) | [13](13-transport-and-packfiles.md) |

## Submodules, subtrees, big repos

| Command | Does | Ch |
|---|---|---|
| `git submodule add\|update --init --recursive\|status\|foreach` | nested repos | [14](14-submodules-subtrees-large-repos.md) |
| `git subtree add\|pull\|push --prefix=P` | vendored history | [14](14-submodules-subtrees-large-repos.md) |
| `git sparse-checkout init --cone` / `set dirs` / `disable` | partial working tree (`set --cone` † needs 2.35) | [14](14-submodules-subtrees-large-repos.md) |

## Hooks, attributes, config

| Item | Does | Ch |
|---|---|---|
| `.git/hooks/pre-commit`, `commit-msg`, `pre-push`, … | scripts run at events; non-zero aborts | [15](15-hooks-attributes-and-config.md) |
| `.gitattributes`: `text eol=lf`, `diff=x`, `merge=x`, `filter=x`, `export-ignore` | per-path behaviour | [15](15-hooks-attributes-and-config.md) |
| `[include]`, `[includeIf "gitdir:~/work/"]`, `[alias]` | config composition, shortcuts | [15](15-hooks-attributes-and-config.md) |
| `.git/info/exclude`, `core.excludesFile` | local ignore rules (a directory's own `.gitignore` beats both) | [15](15-hooks-attributes-and-config.md) |
| `git config --global --add safe.directory <path>` | trust a repository owned by another user | [15](15-hooks-attributes-and-config.md) |

## Patches, signing, notes, export

| Command | Does | Ch |
|---|---|---|
| `git format-patch -N` / `git am [--3way]` / `git apply [--check\|--reject]` | patch series | [16](16-collaboration-and-patches.md) |
| `git request-pull` | pull-request summary text | [16](16-collaboration-and-patches.md) |
| `git commit -S` / `git tag -s` / `git verify-commit` | sign / verify (GPG, or `gpg.format=ssh`) | [16](16-collaboration-and-patches.md) |
| `git notes [--ref=r] add -m M` | annotate commits | [16](16-collaboration-and-patches.md) |
| `git archive --format=zip -o f <rev>` | export a tree | [16](16-collaboration-and-patches.md) |

## Debugging and recovery

| Command | Does | Ch |
|---|---|---|
| `git reflog`, `git fsck --lost-found` | find lost commits / objects | [17](17-debugging-and-recovery.md) |
| `git branch name <hash>` | resurrect a branch | [17](17-debugging-and-recovery.md) |
| `GIT_TRACE=1`, `GIT_TRACE_PERFORMANCE=1`, `GIT_TRACE_PACKET=1` | trace internals | [17](17-debugging-and-recovery.md) |

Sources for this appendix: [REFERENCES.md](REFERENCES.md#appendix-a--cheat-sheet)
