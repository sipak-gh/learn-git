# Chapter 3 — Branches, Merging and Remotes in Brief

A branch is a movable name for a commit, which is why creating one is instant and merging is a graph operation. This chapter covers `branch`/`switch`, fast-forward vs. merge commits, and the basic `clone`/`fetch`/`pull`/`push` cycle against a remote. Everything here is revisited in depth: refs in [Chapter 6](06-references-and-head.md), merge mechanics in [Chapter 9](09-diff-and-merge-internals.md), remotes in [Chapter 12](12-remotes-in-depth.md). Previous: [Chapter 2 — The Everyday Loop](02-the-everyday-loop.md). Next: [Chapter 4 — The Object Database](04-the-object-database.md).

Examples: `examples/ch03/demo.sh`. It uses a local **bare repository** (`server.git`, no working tree) as the "server", so no network is needed.

## Branches

A branch is a 41-byte file holding a commit ID. `HEAD` says which branch you are on. Committing moves the current branch forward.

| Command | Effect |
|---|---|
| `git branch` / `-vv` / `-a` | list local (with upstream and ahead/behind) / including remote-tracking |
| `git branch name [start]` | create, don't switch |
| `git switch name` | change branch (updates index and working tree) |
| `git switch -c name [start]` | create and switch |
| `git branch -d name` / `-D` | delete if merged / force |
| `git branch -m old new` | rename |

```console
$ git remote add origin ../server.git && git push -u origin main 2>&1
To ../server.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
$ git branch topic && git switch topic
Switched to branch 'topic'
```

## Fast-forward vs. merge commit

`git merge X` brings X's history into the current branch. If the current branch is an *ancestor* of X, nothing needs combining: the branch pointer just slides forward (**fast-forward**). Otherwise Git creates a **merge commit** with two parents. After committing `topic.txt` on `topic` (the script's quiet `git add` + `git commit` steps are not echoed in these transcripts), go back and merge:

```console
$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
$ git merge topic
Updating 928aa13..8969640
Fast-forward
 topic.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 topic.txt
$ git log --oneline --graph --decorate
* 8969640 (HEAD -> main, topic) Topic work
* 928aa13 (origin/main) Start app
```

Diverged branches (both have new commits) cannot fast-forward. Here `other.txt` is committed on `other` and `main.txt` on `main` between the commands shown:

```console
$ git switch -c other
Switched to a new branch 'other'
$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
$ git merge other -m "Merge branch other"
Merge made by the 'ort' strategy.
 other.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 other.txt
$ git log --oneline --graph --decorate
*   b28015c (HEAD -> main) Merge branch other
|\  
| * 87409f0 (other) Other work
* | 71763cd Main work
|/  
* 8969640 (topic) Topic work
* 928aa13 (origin/main) Start app
```

`--no-ff` forces a merge commit even when a fast-forward is possible (keeps a visible "this was a feature" bubble); `--ff-only` refuses to create one. Below, `topic2` holds one commit made on top of `main`:

```console
$ git merge --no-ff topic2 -m "Merge topic2"
Merge made by the 'ort' strategy.
 t2.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 t2.txt
$ git log --oneline --graph -n 4
*   569a93b Merge topic2
|\  
| * 2969c73 Topic2 work
|/  
*   b28015c Merge branch other
|\  
| * 87409f0 Other work
$ git branch -d topic other topic2 && git branch -vv
Deleted branch topic (was 8969640).
Deleted branch other (was 87409f0).
Deleted branch topic2 (was 2969c73).
* main 569a93b [origin/main: ahead 6] Merge topic2
$ git push -q origin main && git branch -vv
* main 569a93b [origin/main] Merge topic2
```

Deleting a merged branch only removes the *name*; the commits stay reachable through the merge. A third option, `git merge --squash <branch>`, applies the branch's combined changes to the index and working tree but records no merge: it prints `Squash commit -- not updating HEAD`, writes no `MERGE_HEAD`, and the `git commit` you run next has a single parent. History then does not know the branch was merged, so `branch -d` will call it unmerged. (`ort` is the default merge strategy since Git 2.34; earlier it was `recursive`.) If both sides touch the same lines you get a conflict: see [Chapter 9](09-diff-and-merge-internals.md).

## Remotes: fetch, pull, push

A **remote** is a named URL (`origin`). `git fetch` downloads new objects and updates **remote-tracking branches** (`origin/main`), which are your local bookmarks of where the remote's branches were at the last fetch. It never touches your own branches or working tree. `git pull` = `fetch` + integrate (merge by default, or rebase). `git push` uploads your commits and moves the remote's branch, but only if that is a fast-forward there.

A second clone (`peer`) pushes a commit; back in `app`:

```console
$ git fetch origin
From ../server
   569a93b..27741ae  main       -> origin/main
$ git status -sb
## main...origin/main [behind 1]
$ git log --oneline main..origin/main
27741ae Peer change
$ git pull --ff-only
Updating 569a93b..27741ae
Fast-forward
 peer.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 peer.txt
$ git branch -a
* main
  remotes/origin/main
```

A rejected push (someone else pushed first) says `! [rejected] main -> main (fetch first)`; fix it by fetching and integrating (`pull`, or `fetch` + `rebase`), never by force-pushing a shared branch. `git pull --ff-only` is a safe habit: it fails rather than creating surprise merge commits. Set it globally with `git config --global pull.ff only`.

## Summary

- Branch = ref to a commit; `switch -c` creates, `merge` integrates, `branch -d` deletes the name only.
- Fast-forward when the target is an ancestor; otherwise a merge commit with two parents. `--no-ff` / `--ff-only` select; `--squash` stages the combined changes without recording a merge.
- `fetch` updates `origin/*` only; `pull` = fetch + merge/rebase; `push` needs a fast-forward on the remote.
- A bare repo on disk is the simplest remote for experiments.

## Exercises

1. In a fresh repo, create two divergent branches and produce a merge commit; confirm it has two parents.

   <details><summary>Solution</summary>

   ```console
   $ git log -1 --format='%p' main
   7baa5d7 efd36d0
   $ git rev-list --parents -n1 main | wc -w
   3
   ```

   (Commit ID plus two parents = 3 words; run in `exercises.sh`.)

   </details>

2. Show what `git pull` would bring in without changing any branch.

   <details><summary>Solution</summary>

   `git fetch`, then `git log main..origin/main` (commits to come) and `git diff main...origin/main` (their changes). Fetch is always safe.

   </details>

3. Refuse to ever create a merge commit on pull.

   <details><summary>Solution</summary>

   `git config --global pull.ff only` (or use `git pull --ff-only` per command).

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-3--branches-merging-and-remotes-in-brief)
