# Chapter 7 — Revisions and Ranges

Nearly every Git command takes a *revision* (one commit, written in a mini-language) or a *range* (a set of commits). Knowing the syntax (`man gitrevisions`) makes `log`, `diff`, `rebase`, `cherry-pick` and `reset` all predictable. This chapter covers `^`, `~`, `@{}`, `:/`, `rev:path`, the range operators `A..B`, `A...B`, `^A`/`--not`, `rev-list`, `rev-parse` (and how Git finds the repository), `merge-base` and `--first-parent`. Previous: [Chapter 6 — References and HEAD](06-references-and-head.md). Next: [Chapter 8 — Reading and Searching History](08-reading-and-searching-history.md).

Examples: `examples/ch07/demo.sh`. The history (letters are commit subjects; `base` is a tag on `B`):

```console
$ git log --oneline --graph --decorate --all
* 1358ca2 (topic) Z
| * cc87476 (HEAD -> main) E
| *   ef05127 M merge topic
| |\  
| |/  
|/|   
* | 3e3e5b8 Y
* | e03fb4e X
| * 94e968b D
| * 5622c10 C
|/  
* 7b9aee2 (tag: base) B
* cd3f8ab A
```

(`main` merged `topic` at `M` when `topic` was at `Y`; `Z` came later on `topic`.)

## Naming one commit

| Syntax | Meaning |
|---|---|
| `<hex>` | full or unambiguous abbreviated ID |
| `name` | resolved in order: `.git/<name>`, `refs/<name>`, `refs/tags/`, `refs/heads/`, `refs/remotes/`, `refs/remotes/<name>/HEAD` |
| `@` | alias for `HEAD` |
| `rev^` / `rev^N` | first / N-th **parent** (`^2` only for merges) |
| `rev~N` | N-th generation **first-parent** ancestor; `~` = `~1`; `~N` equals `^1` repeated N times |
| `rev@{N}`, `rev@{date}` | reflog: N-th previous value; value at that time (`@{yesterday}`, `@{2.days.ago}`) |
| `@{-N}` | the N-th previously checked-out branch (`git switch -` = `@{-1}`) |
| `branch@{upstream}`, `@{u}`, `@{push}` | the configured upstream / push target |
| `:/text` | youngest commit **in any branch** whose message matches the regex |
| `rev^{/text}` | youngest commit reachable from `rev` matching the regex |
| `rev^{commit}`, `rev^{tree}`, `rev^{}` | peel to a type / peel tags fully |
| `rev:path` | the blob or tree at `path` in `rev` |
| `:N:path`, `:path` | path from the index at stage N (0 default) |

```console
$ git rev-parse HEAD HEAD^ HEAD~1 HEAD~1^1 HEAD~1^2 HEAD~2 HEAD~1^2~1
cc87476ea0ccc42ef73574ec5dbb264ea964f365
ef051277a781ac0d734a04cc735ef3c04ae3ac66
ef051277a781ac0d734a04cc735ef3c04ae3ac66
94e968b8a19ebf4620afdcf8c9b03389d1c5e4b8
3e3e5b80fc56ca4cafac6a2053124c2fa85c2926
94e968b8a19ebf4620afdcf8c9b03389d1c5e4b8
e03fb4e5e533679a714478bd3f2d0e83b30b47ce
```

Read in order: `E`; `E^` = `M`; `E~1` = `M`; `M^1` = `D`; `M^2` = `Y`; `E~2` = `D` (first-parent chain `E→M→D`); `M^2~1` = `X`. **`~` walks back along first parents; `^N` picks among the parents of one commit.** `HEAD^2` on a non-merge commit is an error (`unknown revision`), which is why the demo uses `HEAD~1^2`.

```console
$ git rev-parse --short main@{1}
ef05127
$ git log --format=%s -1 :/"merge topic"
M merge topic
$ git log --format=%s -1 :/^C
C
$ git show --format=%s -s HEAD^{/Y}
Y
$ git rev-parse HEAD:f.txt; git show HEAD~2:m.txt; git show :f.txt
1c507261389e25abfe3620ddd348c73f4eb3b91e
D
E
$ git rev-parse main@{upstream} 2>&1 | tail -1
fatal: no upstream configured for branch 'main'
```

`:/regex` is a regular expression, anchored by you (`^C`); with a space, quote it. `HEAD~2:m.txt` is the file as of two commits ago; `:f.txt` (leading colon) is the index version.

## `rev-parse`: the revision parser as a tool

```console
$ git rev-parse @ HEAD
cc87476ea0ccc42ef73574ec5dbb264ea964f365
cc87476ea0ccc42ef73574ec5dbb264ea964f365
$ git rev-parse --verify -q nosuch; echo rc=$?
rc=1
$ git rev-parse --symbolic-full-name topic
refs/heads/topic
$ git rev-parse --git-dir --is-bare-repository --show-prefix
.git
false

$ git rev-parse --short=10 HEAD
cc87476ea0
```

`--verify` (with `-q`) is the scripting idiom for "does this resolve to exactly one object?". `--show-toplevel`, `--git-dir`, `--show-prefix` locate you in a repo (`--show-prefix` is empty at the top level, hence the blank line).

### How Git finds the repository

Every command first has to find the repository. Git looks for `.git` (a directory, or a file containing `gitdir: <path>` as in linked worktrees and submodules) in the current directory, then in each parent until it finds one, reaches the filesystem root, or hits a directory listed in `GIT_CEILING_DIRECTORIES`. The directory containing `.git` is the top of the working tree:

```console
$ cd src/deep; git rev-parse --show-prefix --show-cdup; git log --oneline -1; cd ../..
src/deep/
../../
cc87476 E
$ cd ..; GIT_CEILING_DIRECTORIES=$PWD git log --oneline -1 2>&1
fatal: not a git repository (or any of the parent directories): .git
$ git --git-dir=lab/.git log --oneline -1; GIT_DIR=lab/.git git rev-parse --is-inside-work-tree; cd lab
cc87476 E
true
```

`--show-cdup` is the way back up to the top. The ceiling stopped the search from the parent directory, which keeps the result the same even if the course itself sits inside a Git checkout. `--git-dir`/`GIT_DIR` skip discovery entirely, and `--work-tree`/`GIT_WORK_TREE` name the working tree; with only `GIT_DIR` set, Git takes the *current directory* as the top of the working tree, which is why the last command said `true` from outside `lab`. `GIT_TRACE_SETUP` ([Chapter 17](17-debugging-and-recovery.md#tracing-git-itself)) prints what discovery decided.

## Ranges: sets of commits

A range selects commits reachable from *included* tips but not from *excluded* ones.

| Syntax | Set |
|---|---|
| `A` | A and all its ancestors |
| `^A B`, `B --not A`, `A..B` | reachable from B, **not** from A |
| `A...B` | symmetric difference: reachable from either, not from both |
| `A^@` | A's parents and so all their ancestors, but not A itself |
| `A^!` | A alone (`A --not A^@`) |
| `A^-`, `A^-N` | `A^1..A` / `A^N..A`: what a merge brought in, plus the merge itself |
| `-n N`, `--since`, `--until`, `-- path` | extra filters |

```console
$ git log --format=%s main..topic
Z
$ git log --format=%s topic..main
E
M merge topic
D
C
$ git log --left-right --format="%m %s" main...topic
> Z
< E
< M merge topic
< D
< C
$ git log --format=%s ^topic main
E
M merge topic
D
C
$ git log --format=%s main --not topic base
E
M merge topic
D
C
```

`main..topic` = "what's on `topic` that `main` lacks" (what a PR would add); `topic..main` is the reverse; `main...topic` is both, and `--left-right` marks the side (`<` = left = `main`). Note `main..topic` doesn't include `Y`/`X`: they are reachable from `main` via the merge. Leaving out one side of `..` or `...` means `HEAD`: `@{u}..` is what you would push, `..@{u}` what you would pull.

For `git diff` the dots mean something different, because `diff` compares two *trees*, not a commit set:

```console
$ git diff topic...main --stat
 f.txt | 2 +-
 m.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
$ git diff topic..main --stat
 f.txt | 2 +-
 m.txt | 1 +
 t.txt | 2 +-
 3 files changed, 3 insertions(+), 2 deletions(-)
```

`diff A..B` ≡ `diff A B` (tip vs. tip, includes `Z` reverted). `diff A...B` = `diff $(merge-base A B) B`: only the changes made on `B` since it forked (the "PR diff"). `t.txt` is absent in the three-dot output because `main` didn't change it after the fork point (`Y`).

## History shape: `--first-parent`, `--merges`, `--ancestry-path`

```console
$ git log --format=%s -n2 --first-parent
E
M merge topic
$ git log --format=%s --first-parent base..main
E
M merge topic
D
C
$ git log --format=%s --no-merges base..main
E
D
C
Y
X
$ git log --format=%s --merges
M merge topic
$ git log --format=%s --ancestry-path base..topic
Z
Y
X
$ git log --format=%s -- m.txt
D
C
```

`--first-parent` follows only the first parent at each merge, giving the "mainline" view (each merged feature as one line); `--no-merges` hides merge commits but keeps the side-branch commits; `--ancestry-path A..B` only commits that descend from `A`. `-- path` limits to commits that touch the path (history simplification hides merges that don't change it).

## `rev-list` and `merge-base`

`rev-list` is the plumbing under `log`: it prints IDs only, stable for scripts.

```console
$ git rev-list --count main
8
$ git rev-list --left-right --count main...topic
4	1
$ git rev-list --max-count=2 --reverse main
ef051277a781ac0d734a04cc735ef3c04ae3ac66
cc87476ea0ccc42ef73574ec5dbb264ea964f365
$ git rev-list --parents -n1 HEAD~1
ef051277a781ac0d734a04cc735ef3c04ae3ac66 94e968b8a19ebf4620afdcf8c9b03389d1c5e4b8 3e3e5b80fc56ca4cafac6a2053124c2fa85c2926
$ git rev-list --objects -n2 main | head -4
cc87476ea0ccc42ef73574ec5dbb264ea964f365
ef051277a781ac0d734a04cc735ef3c04ae3ac66
d11091665bc95a962f3c1da06c2c82353ecfe2c3 
1c507261389e25abfe3620ddd348c73f4eb3b91e f.txt
```

`--left-right --count A...B` prints "ahead behind" counts (what `git status` computes). `--parents` prints each commit followed by its parents. `--objects` also lists the trees and blobs needed: this is how `pack-objects` decides what to send ([Chapter 13](13-transport-and-packfiles.md)).

```console
$ git merge-base main topic
3e3e5b80fc56ca4cafac6a2053124c2fa85c2926
$ git merge-base --is-ancestor topic main; echo rc=$?
rc=1
$ git merge-base --all HEAD~1 topic
3e3e5b80fc56ca4cafac6a2053124c2fa85c2926
$ git merge-base --octopus main topic base
7b9aee2c2a1a191a009d9e25ee3871aaec761950
$ git branch --merged main; git branch --no-merged main
* main
  topic
$ git branch --contains base
* main
  topic
```

`merge-base A B` = the best common ancestor (the merge's "base" in [Chapter 9](09-diff-and-merge-internals.md)); `--all` lists several when history is criss-cross; `--is-ancestor` exits 0/1 and is the proper script test for "is X already in Y?" (here `Z` isn't in `main`). `--octopus` = best base of ≥3 commits. `branch --merged`/`--no-merged` and `--contains` filter by reachability (`--merged main` printed `* main`, `--no-merged main` printed `  topic`; `--contains base` lists both).

Time filters take approximate dates or ISO strings:

```console
$ git log --since="2024-01-01T03:00:00" --until="2024-01-01T05:00:00" --format="%s %cd" --date=iso
Y 2024-01-01 05:00:00 +0000
X 2024-01-01 04:00:00 +0000
B 2024-01-01 03:00:00 +0000
```

## Summary

- `^N` selects a parent; `~N` walks first parents; `@{N}` walks the reflog; `:/re` greps messages; `rev:path` names a blob/tree.
- `A..B` = in B not A; `A...B` = in either, not both; for **diff** `A...B` means "since the merge-base".
- `--first-parent`, `--no-merges`, `--ancestry-path`, `-- path` reshape history; `rev-list` is the scriptable form of `log`.
- `merge-base` finds the common ancestor; `--is-ancestor` is a boolean test.
- Git finds the repository by walking up to the nearest `.git`; `GIT_DIR`, `GIT_WORK_TREE` and `GIT_CEILING_DIRECTORIES` override or limit the search.

## Exercises

1. List the commits your branch `topic` has that `main` doesn't, oldest first, as IDs only.

   <details><summary>Solution</summary>

   ```console
   $ git rev-list --reverse main..topic
   1358ca298eb3c61ce3db3edae71fc1de1951324d
   ```

   Only `Z`: `X` and `Y` are already in `main` through the merge.

   </details>

2. Show what a PR from `topic` into `main` would change, ignoring what `main` did meanwhile.

   <details><summary>Solution</summary>

   ```console
   $ git diff main...topic --stat
    t.txt | 2 +-
    1 file changed, 1 insertion(+), 1 deletion(-)
   ```

   Three dots diff `merge-base(main, topic)` against `topic`; here the merge base is `Y`, so only `Z`'s `t.txt` change appears.

   </details>

3. Is `X` an ancestor of `main`? Answer with an exit code.

   <details><summary>Solution</summary>

   ```console
   $ git merge-base --is-ancestor :/^X main; echo $?
   0
   ```

   `X` came in through the merge. Use `git merge-base --is-ancestor topic main` for `topic`, which exits `1` (see above).

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-7--revisions-and-ranges)
