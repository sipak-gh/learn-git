# Chapter 11 — Stash, Worktrees and Cleaning

Real work is interrupted: a bug report arrives mid-edit, you need to compare two branches side by side, or the tree is full of build debris. This chapter covers `git stash` (and what it really is), `git worktree` (several checkouts of one repository), `git clean`, and path-level restoring with `restore --source` and `-p`. Previous: [Chapter 10 — Rewriting History](10-rewriting-history.md). Next: [Chapter 12 — Remotes in Depth](12-remotes-in-depth.md).

Transcripts: [`examples/ch11/demo.sh`](examples/ch11/demo.sh) → `output.txt` (Git 2.34.1). Paths in worktree output are shortened to `/home/you/…`.

## Stash

`git stash push` saves your modified tracked files and the index, then resets the work tree to `HEAD`. Starting state: `a.txt` modified, `b.txt` staged, `new.txt` untracked, `build/` ignored.

```console
$ git status -s
 M a.txt
M  b.txt
?? new.txt
$ git stash push -m "wip: a and b"
Saved working directory and index state On main: wip: a and b
$ git status -s
?? new.txt
$ git stash list
stash@{0}: On main: wip: a and b
$ git stash show
 a.txt | 1 +
 b.txt | 1 +
 2 files changed, 2 insertions(+)
$ git stash show -p stash@{0} | head -12
diff --git a/a.txt b/a.txt
index 4cb29ea..6284eba 100644
--- a/a.txt
+++ b/a.txt
@@ -1,3 +1,4 @@
 one
 two
 three
+changed
diff --git a/b.txt b/b.txt
index 587be6b..1cafd64 100644
--- a/b.txt
```

By default untracked files stay (note `new.txt`). `apply` re-applies and keeps the entry; `pop` = `apply` + `drop`; `drop` deletes an entry:

```console
$ git stash apply && git status -s
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   a.txt
	modified:   b.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new.txt

no changes added to commit (use "git add" and/or "git commit -a")
 M a.txt
 M b.txt
?? new.txt
$ git stash drop
Dropped refs/stash@{0} (80108e7e0223da8db3a8fc799d9f7aa9953436a7)
```

Note that `apply` restored `b.txt` as *unstaged* (` M`): index state is only recreated with `--index`.

### Variants

| Command | Effect |
|---------|--------|
| `stash push -m <msg>` | name the entry (bare `git stash` gives `WIP on <branch>: <hash> <subject>`) |
| `stash push -u` (`--include-untracked`) | also stash untracked files |
| `stash push -a` (`--all`) | also ignored files |
| `stash push -- <pathspec>` | stash only some paths |
| `stash push -p` | choose hunks interactively |
| `stash push --keep-index` | stash everything but leave the index in the work tree (test what you're about to commit) |
| `stash pop/apply --index` | restore staged state too |
| `stash branch <name> [<stash>]` | create a branch at the stash's base commit, apply, drop |
| `stash show -p` | show the patch |
| `stash clear` | delete all entries (the stash reflog goes too; recoverable only via `git fsck --unreachable`) |

```console
$ git stash push -u -m "with untracked"
Saved working directory and index state On main: with untracked
$ ls; git status -s
a.txt
b.txt
build
$ git stash pop --index
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   b.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   a.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new.txt

Dropped refs/stash@{0} (6cc59198f7a52e207f9e8fb8e5016d6d98b79ef7)
$ git stash push -m "only a" -- a.txt
Saved working directory and index state On main: only a
$ git status -s
 M b.txt
$ git stash pop
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   a.txt
	modified:   b.txt

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (69ed0293a9f1fd9d468aaedbcd65d1cad5e4474a)
$ git stash push -a -m "all"; ls; git stash pop -q; ls build
Saved working directory and index state On main: all
a.txt
b.txt
Already up to date.
out.o
```

(`-a` made even the ignored `build/` disappear; `pop` restored it. The script printed `Already up to date.` from the pop's internal merge.)

### A stash is just commits

A stash entry is a **merge commit** stored at `refs/stash` (with its history in `.git/logs/refs/stash`, so `git reflog show stash` is the list). Parent 1 is `HEAD` when stashed, parent 2 the "index" commit (the staged tree), and with `-u` parent 3 holds the untracked files:

```console
$ cat .git/refs/stash | wc -c; git log --graph --oneline stash --all | head -4
41
*-.   d98a414 On main: inspect
|\ \  
| | * 4c236b2 untracked files on main: 4015102 initial
| * 1e5c347 index on main: 4015102 initial
$ git cat-file -p stash | sed "s/^\(author\|committer\).*/\1 .../"
tree b4bed8cb5cb5bbb77bc2ce342bd6ce60bf4f1cf6
parent 40151021824934c52b25b54af6098ee0b443f805
parent 1e5c347ea34e88936a8f49baba63890459826b9d
parent 4c236b2a649f053cdc93230714a244b48a271f8c
author ...
committer ...

On main: inspect$ git cat-file -p stash^3 | head -1; git ls-tree stash^3
tree eca1d9fa724b6444d38e38834f9a81ace3db5c45
100644 blob 5a72eb2edc5d0da32ff615d210d6fa90c31ed940	new.txt
$ git reflog show stash
d98a414 stash@{0}: On main: inspect
```

(The missing newline before `$ git cat-file -p stash^3` is just how `cat-file` prints this message.) The commit's tree is the work tree state. Because stashes are ordinary commits you can `git diff stash^ stash`, `git checkout stash -- file`, or `git branch rescue <stash-hash>`. A dropped stash is only a dangling commit: `git fsck --no-reflogs --unreachable | grep commit` can find it (chapter 17). Stash is **not** pushed or fetched — it lives only in your repository.

### Conflicts, and `stash branch`

`stash branch` sidesteps all conflicts: it checks out the commit the stash was made on, applies it there, and drops it:

```console
$ git stash branch from-stash
Switched to a new branch 'from-stash'
On branch from-stash
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   b.txt

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   a.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new.txt

Dropped refs/stash@{0} (d98a4140484613d77314cec7bd5cb8cdca66ad31)
$ git status -s; git stash list | wc -l
 M a.txt
M  b.txt
?? new.txt
0
```

Popping onto a branch that moved a conflicting way gives an ordinary merge conflict, and **keeps** the stash entry so nothing is lost until you drop it yourself:

```console
$ git stash pop
Auto-merging a.txt
CONFLICT (content): Merge conflict in a.txt
On branch main
Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   a.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	new.txt

no changes added to commit (use "git add" and/or "git commit -a")
The stash entry is kept in case you need it again.
$ git stash list
stash@{0}: WIP on main: 4015102 initial
```

Resolve as in chapter 9, `git add`/`git restore --staged` as desired, then `git stash drop`.

## `restore --source` and patch mode

`git restore` (chapter 2) can pull a path from *any* commit, not only the index:

```console
$ git restore --source=HEAD~1 v.txt && cat v.txt && git status -s
v1
 M v.txt
$ git restore --source=HEAD --staged --worktree v.txt && cat v.txt
v2
```

(Which copies are written: with neither flag, only the working tree; `--staged` alone, only the index; both flags, both. The source defaults to the index for the working tree and to `HEAD` for `--staged`. The older `git checkout <commit> -- <path>` always writes both index and working tree.) Add `-p` to pick hunks interactively. Here the answer `n` comes from a here-string, so the prompt is printed but the answer is not echoed:

```console
$ git restore -p --source=HEAD~1 v.txt <<< n
diff --git b/v.txt a/v.txt
index 8c1384d..626799f 100644
--- b/v.txt
+++ a/v.txt
@@ -1 +1 @@
-v2
+v1
(1/1) Apply this hunk to worktree [y,n,q,a,d,e,?]? 
```

(The diff is shown *reversed* — "b" is the work tree — because restoring means applying the difference toward the source.) With two modified hunks, answering `n` then `y` discards only the second:

```console
$ printf "n\ny\n" | git restore -p p.txt >/dev/null; git diff -U0 | grep "^[-+][^-+]"
-l2
+CHANGED2
```

The older equivalents are `git checkout -p [<tree>] [-- <path>]` (and `git reset -p` to unstage hunks). Answers: `y n q a d` (yes/no/quit/all/none-in-file), `s` split a hunk, `e` edit the hunk by hand, `?` help.

## `git clean`

Removes untracked files (never tracked ones). Because that is irreversible, Git forces a dry run unless told otherwise:

```console
$ git clean -n
Would remove untracked1
$ git clean -nd
Would remove dir/
Would remove untracked1
$ git clean -f; ls
Removing untracked1
a.txt
b.txt
build
dir
new.txt
p.txt
v.txt
$ git clean -fd; ls
Removing dir/
a.txt
b.txt
build
new.txt
p.txt
v.txt
$ git clean -ndx
Would remove build/
$ git clean -fdx; ls build 2>&1 | head -1
Removing build/
ls: cannot access 'build': No such file or directory
$ git clean 2>&1
fatal: clean.requireForce defaults to true and neither -i, -n, nor -f given; refusing to clean
```

| Flag | Meaning |
|------|---------|
| `-n` | dry run |
| `-f` | do it (required unless `clean.requireForce=false`) |
| `-d` | include untracked directories |
| `-x` | also remove ignored files; `-X` removes *only* ignored files (great for "clean build artifacts") |
| `-i` | interactive menu |
| `-e <pat>` | extra exclude pattern |

Note the progression: plain `-f` ignored the untracked `dir/` and the ignored `build/`; `-d` removed `dir/`; `-x` was needed for `build/`. Typical full reset to "what a fresh clone would have": `git reset --hard && git clean -fdx`.

## Worktrees

A repository normally has one work tree. `git worktree add` creates **additional** linked work trees that share the same object database, refs and config, each with its own `HEAD` and index. No second clone, no stash, no re-checkout:

```console
$ git worktree add ../lab-hotfix -b hotfix
Preparing worktree (new branch 'hotfix')
HEAD is now at 09d8b43 p
$ git worktree list
/home/you/lab         09d8b43 [main]
/home/you/lab-hotfix  09d8b43 [hotfix]
$ ls ../lab-hotfix; cat ../lab-hotfix/.git
a.txt
b.txt
new.txt
p.txt
v.txt
gitdir: /home/you/lab/.git/worktrees/lab-hotfix
$ ls .git/worktrees; cat .git/worktrees/lab-hotfix/gitdir; cat .git/worktrees/lab-hotfix/HEAD
lab-hotfix
/home/you/lab-hotfix/.git
ref: refs/heads/hotfix
```

The linked tree's `.git` is a **file** pointing at `.git/worktrees/<name>/` in the main repository, which holds the per-worktree `HEAD`, `index`, `logs`, etc. (`gitdir` points back). Commits made there land in the shared repository:

```console
$ git log --oneline -1 hotfix
878e8d8 hotfix commit
$ git switch hotfix 2>&1
fatal: 'hotfix' is already checked out at '/home/you/lab-hotfix'
```

A branch can be checked out in only one worktree at a time (this protects you from moving a branch under another checkout's feet; `--force` overrides). Other operations:

```console
$ git worktree add ../lab-detached --detach HEAD~1; git worktree list
Preparing worktree (detached HEAD b0b29e9)
HEAD is now at b0b29e9 v2
/home/you/lab           09d8b43 [main]
/home/you/lab-detached  b0b29e9 (detached HEAD)
/home/you/lab-hotfix    878e8d8 [hotfix]
$ git worktree lock --reason "on usb" ../lab-detached; git worktree list
/home/you/lab           09d8b43 [main]
/home/you/lab-detached  b0b29e9 (detached HEAD) locked
/home/you/lab-hotfix    878e8d8 [hotfix]
$ git worktree unlock ../lab-detached; git worktree remove ../lab-detached; git worktree list
/home/you/lab         09d8b43 [main]
/home/you/lab-hotfix  878e8d8 [hotfix]
```

`lock` protects a worktree on removable media from pruning; `remove` refuses if the tree is dirty (unless `--force`). If you delete a worktree directory by hand, Git only notices via `prune`:

```console
$ git worktree list; git worktree prune -v; git worktree list
/home/you/lab         09d8b43 [main]
/home/you/lab-hotfix  878e8d8 [hotfix] prunable
Removing worktrees/lab-hotfix: gitdir file points to non-existent location
/home/you/lab  09d8b43 [main]
```

(The `prunable` annotation is printed by this 2.34.1 build, as shown.) To relocate a worktree, use `git worktree move <worktree> <new-path>`, which updates both links. If you already moved the directory with `mv`, the main repository's `gitdir` file points at the old place, and `git worktree repair <new-path>` (2.29+) fixes it: in a separate test it printed `repair: gitdir incorrect: …/worktrees/w2/gitdir` and `worktree list` showed the new path. Gotchas: per-worktree files (`HEAD`, `index`, `refs/bisect`, `refs/worktree`) are separate; everything else, including `refs/stash`, branches and hooks, is shared; submodules in linked worktrees are poorly supported (chapter 14); `git gc` keeps worktree-referenced objects alive.

## Summary

- `stash push` saves tracked changes (and with `-u`/`-a` untracked/ignored), `pop` applies and drops, `apply` keeps; `--index` restores staging; `stash branch` avoids conflicts.
- A stash is a merge commit at `refs/stash` (parents: HEAD, index commit, optional untracked commit); it is local only and a dropped one is recoverable with `fsck`.
- `restore --source=<rev> [-p] <path>` fetches files or hunks from any commit; `checkout -p` and `reset -p` are the older spellings.
- `git clean` deletes untracked files: always `-n` first; `-d` for directories, `-x`/`-X` for ignored files.
- `git worktree add` gives extra checkouts sharing one object database; a branch can be checked out in only one at a time; `prune` forgets deleted ones.

## Exercises

The solutions were run in a small repository with tracked `a.txt` and `b.txt`, a tag `v1` on the first commit, and `build/` in `.gitignore`.

1. With both `a.txt` and `b.txt` modified, stash only `a.txt` under the message "only a", then restore it.

   <details><summary>Solution</summary>

   ```console
   $ git stash push -m "only a" -- a.txt; git status -s
   Saved working directory and index state On main: only a
    M b.txt
   $ git stash pop -q; git status -s
    M a.txt
    M b.txt
   ```

   </details>

2. You started editing on `main` but the work should be on a new branch `feature`. Move the edits without committing.

   <details><summary>Solution</summary>

   ```console
   $ git switch -c feature; git status -s
   Switched to a new branch 'feature'
    M a.txt
    M b.txt
   ```

   Uncommitted changes simply come along, because the new branch points at the same commit. If switching to an *existing* branch would overwrite them, Git refuses; then use `git stash`, `git switch feature`, `git stash pop`.

   </details>

3. List what `git clean -fdx` would delete, without deleting anything.

   <details><summary>Solution</summary>

   ```console
   $ git clean -ndx
   Would remove build/
   Would remove dir/
   Would remove junk
   ```

   `-n` turns any `clean` command into a dry run; `build/` is listed because `-x` includes ignored files.

   </details>

4. Open a second checkout of `v1` at `../review` (for example to run its tests), then remove it cleanly.

   <details><summary>Solution</summary>

   ```console
   $ git worktree add --detach ../review v1; ls ../review
   Preparing worktree (detached HEAD 35abd4c)
   HEAD is now at 35abd4c initial
   a.txt
   b.txt
   $ git worktree remove ../review; git worktree list
   /home/you/lab  4735a72 [feature]
   ```

   `v1` is a tag, not a branch, so the new worktree gets a detached `HEAD` anyway; `--detach` just makes that explicit.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-11--stash-worktrees-and-cleaning)
