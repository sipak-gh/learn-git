# Chapter 10 — Rewriting History

Commits are immutable: "changing" one really creates a new commit with a new hash and moves a branch to it, leaving the old one in the object database (and, for a while, the reflog). This chapter covers every common way of doing that — amend, reset, revert, cherry-pick, rebase — and how to get back when you slip. Previous: [Chapter 9 — Diff Internals and Merge Mechanics](09-diff-and-merge-internals.md). Next: [Chapter 11 — Stash, Worktrees and Cleaning](11-stash-worktrees-and-cleaning.md).

Transcripts: [`examples/ch10/demo.sh`](examples/ch10/demo.sh) → `output.txt` (Git 2.34.1; fixed dates, so hashes are reproducible if you run the script).

## The golden rule

**Do not rewrite commits that other people already have.** A rewritten commit has a different hash, so anyone who built on the old one now has a diverged history. Rewrite freely what is only local (or a private topic branch you alone push to, with `--force-with-lease`, chapter 12). For published history, use `git revert`, which adds a new commit.

## `commit --amend`

Replaces the tip commit (new tree and/or message). Nothing is edited in place:

```console
$ git log --oneline
ee43cb3 add c
d993938 add b
c59dd67 add a
$ git commit --amend --no-edit -q; git log --oneline
30fb5a9 add c
d993938 add b
c59dd67 add a
$ git reflog -3
30fb5a9 HEAD@{0}: commit (amend): add c
ee43cb3 HEAD@{1}: commit: add c
d993938 HEAD@{2}: commit: add b
```

`ee43cb3` is still in the object database, reachable from `HEAD@{1}`. Useful flags: `-m`, `--no-edit`, `--reset-author`, `--date=`, `-a`. (Here `c.txt` was staged with new content first.)

## `reset`: moving the branch (and optionally the other two areas)

`git reset [--soft|--mixed|--hard] <commit>` does up to three things, matching the three areas of chapter 1:

| Mode | Moves branch (HEAD) | Resets index | Resets work tree |
|------|:---:|:---:|:---:|
| `--soft` | yes | no | no |
| `--mixed` (default) | yes | yes | no |
| `--hard` | yes | yes | **yes — destroys uncommitted changes** |

```console
$ git reset --soft HEAD~1; git status -s; git log --oneline | head -1
A  d.txt
30fb5a9 add c
$ git reset -q; git status -s
?? d.txt
$ git add d.txt; git reset --hard HEAD; git status -s; ls
HEAD is now at 30fb5a9 add c
a.txt
b.txt
c.txt
```

`--soft` "uncommits" but keeps everything staged (handy to squash the last N commits: `git reset --soft HEAD~N && git commit`). `--mixed` leaves the files modified and unstaged. `--hard` also throws away the work tree; the staged-only `d.txt` is gone (it was never committed, so it is *not* in the reflog, though the blob may be recoverable via `git fsck --lost-found`, chapter 17).

`reset` records where `HEAD` was in `ORIG_HEAD` (chapter 6), giving a one-step undo:

```console
$ git commit -q --allow-empty -m "oops"; git reset --hard HEAD~1; git log --oneline | head -1
HEAD is now at 30fb5a9 add c
30fb5a9 add c
$ git reset --hard ORIG_HEAD 2>&1; git log --oneline | head -1
HEAD is now at f1c97c1 oops
f1c97c1 oops
```

Two safer modes refuse rather than destroy: `--keep` moves the branch and updates files that differ between the two commits, but aborts (`error: Entry 'a' not uptodate. Cannot merge.`) if one of those files has local changes; local changes to other files survive. `--merge` is similar, and `git merge --abort` is documented as equivalent to `git reset --merge`. In a test, `reset --keep HEAD~1` with an unrelated edit to `b` kept the edit, and with an edit to `a` (changed by the commit being dropped) refused.

With a path, `git reset [<commit>] -- <path>` never moves `HEAD`; it only copies that path's entry from the commit (default `HEAD`) into the index, which is why it unstages. Not to be confused with `git restore`, which touches files but never moves a branch (`git restore --staged <path>` is the newer spelling of the unstage, chapter 2).

## `revert`: undo by adding a commit

```console
$ git revert --no-edit HEAD~1
[main 301f3c4] Revert "add d"
 Date: Mon Jan 1 08:00:00 2024 +0000
 1 file changed, 1 deletion(-)
 delete mode 100644 d.txt
$ git log --oneline
301f3c4 Revert "add d"
2670aaf add e
dfffeb5 add d
30fb5a9 add c
d993938 add b
c59dd67 add a
$ ls
a.txt
b.txt
c.txt
e.txt
```

Safe on shared history: it applies the inverse patch as a normal three-way merge (so it can conflict). Reverting a merge commit needs `-m <parent-number>` to say which parent is the mainline to go back to. In a separate repository where `main` merged a branch `feat` (which added `f.txt`):

```console
$ git revert --no-edit HEAD
error: commit 3c474bbeb9904d0e3e0ef4d3f394e5a637ef3d83 is a merge but no -m option was given.
fatal: revert failed
$ git revert --no-edit -m 1 HEAD; ls
[main f3dc7a1] Revert "Merge feat"
 Date: Tue Jan 2 06:00:00 2024 +0000
 1 file changed, 1 deletion(-)
 delete mode 100644 f.txt
a.txt
m.txt
$ git merge feat
Already up to date.
$ git revert --no-edit HEAD; ls
[main 00b962c] Revert "Revert "Merge feat""
 Date: Tue Jan 2 07:00:00 2024 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 f.txt
a.txt
f.txt
m.txt
```

`-m 1` keeps the first parent's (`main`'s) side and undoes what `feat` brought in. The revert does not remove `feat`'s commits from history, so Git still considers them merged: `git merge feat` brings nothing. To get the changes back, *revert the revert*.

## `cherry-pick`: copy a commit

Re-applies the change introduced by a commit onto the current branch as a **new commit** (same author, new committer date and hash):

```console
$ git cherry-pick feature~1
[main 43998e9] feature f
 Date: Mon Jan 1 09:00:00 2024 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 f.txt
$ git cherry-pick -x feature
[main f4f1f66] feature g
 Date: Mon Jan 1 10:00:00 2024 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 g.txt
```

`-x` appends `(cherry picked from commit …)` to the message — recommended when cherry-picking between published branches. Other flags: `-n` (apply without committing), ranges `A..B`, `-m <n>` for merges, `--continue/--skip/--abort` after a conflict. `git log --cherry-pick --left-right A...B` hides patch-equivalent commits; `git cherry <upstream>` is the plumbing-style equivalent (`-` = already upstream, `+` = not).

## `rebase`: replay commits

`git rebase <upstream>` lists the commits in `upstream..HEAD`, leaving out merge commits and any commit whose patch is already upstream (same patch ID, as `git cherry` computes; Git prints `warning: skipped previously applied commit <hash>`, and `--reapply-cherry-picks` keeps them), detaches `HEAD` at `upstream`, and cherry-picks each commit in turn, then moves the branch to the result. Since Git 2.26 this "merge" backend uses the merge machinery of chapter 9, so renames are detected and `rerere` helps with repeated conflicts; `--apply` selects the older backend that really does format patches and apply them with `am`. All replayed commits get new hashes.

```
before:  A---B---C  main            after:  A---B---C  main
              \                                      \
               D---E  topic                           D'---E'  topic
```

`git rebase main` on `topic` re-creates D and E (as D', E') on top of the current `main`.

### `--onto`: transplant

`git rebase --onto <newbase> <oldbase> <branch>` moves the commits in `oldbase..branch` onto `newbase`. Here `topic` was started from `base1` (an unrelated, unmerged piece of work) and should instead sit on `main`:

```console
$ git log --oneline --graph --decorate main base1 topic
* c86b8e0 (main) main moves on
| * aaf4d68 (HEAD -> topic) topic 2
| * b4805e4 topic 1
| * f29c86a (base1) base1 work
|/
* f4f1f66 feature g
* 43998e9 feature f
  …
$ git rebase --onto main base1 topic 2>&1 | tr "\r" "\n" | tail -1
Successfully rebased and updated refs/heads/topic.
$ git log --oneline --graph --decorate main base1 topic
* 321053c (HEAD -> topic) topic 2
* c2059c9 topic 1
* c86b8e0 (main) main moves on
| * f29c86a (base1) base1 work
|/
* f4f1f66 feature g
  …
```

(Older ancestors elided with `…`; the graph is otherwise verbatim.) `base1 work` is left behind; `topic 1/2` have new hashes.

### Interactive rebase

`git rebase -i <base>` writes a todo list and opens `$GIT_SEQUENCE_EDITOR` (falling back to `GIT_EDITOR`/`core.editor`). Each line is `<verb> <hash> <subject>`; lines run top to bottom and can be reordered or deleted:

| Verb | Effect |
|------|--------|
| `pick` (`p`) | use the commit |
| `reword` (`r`) | use it, edit message |
| `edit` (`e`) | stop after applying so you can amend or split |
| `squash` (`s`) | meld into previous, concatenate messages |
| `fixup` (`f`) | meld into previous, discard this message (`-C`/`-c` use this one's message) |
| `exec` (`x`) | run a shell command |
| `break` (`b`) | stop here |
| `drop` (`d`) | remove the commit (deleting the line does too) |
| `label`, `reset`, `merge` | build/rebuild merge topology (see `--rebase-merges`) |

The demo has a stand-in "editor" script that turns four `pick` lines into `pick / squash / drop / reword` (and a commit-message editor that appends `-reworded`). The todo Git generated:

```console
$ head -4 .git/last-todo
pick 21a6e60 work 1
pick 706c656 work 2
pick 631b34c work 3
pick 4e5e1b8 work 4
```

After editing it to `pick`, `squash`, `drop`, `reword`:

```console
$ git log --oneline -3
5330d52 work 4-reworded
23c9ea4 work 1
f4f1f66 feature g
$ git log -1 --format=%B HEAD~1
work 1

work 2

$ git diff --stat HEAD~2 HEAD
 w1.txt | 1 +
 w2.txt | 1 +
 w4.txt | 1 +
 3 files changed, 3 insertions(+)
```

Work 1+2 were squashed (message combined), work 3 dropped (no `w3.txt`), work 4 reworded. In real use the editor opens interactively; stopping at `edit` leaves you in a detached `HEAD` mid-rebase where you can `git commit --amend`, split with `git reset HEAD^`, then `git rebase --continue`. Always available: `git rebase --abort`, `--skip`, `--edit-todo`, and `git status` explains where you are.

### `--autosquash` and fixup commits

`git commit --fixup=<commit>` (or `--squash=`) creates a commit titled `fixup! <subject>`. `rebase -i --autosquash` (or config `rebase.autoSquash=true`) moves each to just below its target and marks it `fixup`:

```console
$ git log --oneline -2
563a783 fixup! work 1
5330d52 work 4-reworded
$ GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash HEAD~3
Rebasing (2/3)Rebasing (3/3)Successfully rebased and updated refs/heads/work.
$ git log --oneline -3
6f107c7 work 4-reworded
004b01e work 1
f4f1f66 feature g
```

(`GIT_SEQUENCE_EDITOR=true` accepts the pre-arranged todo list unchanged; `sequence.editor` is the config equivalent.) The fixup landed inside `work 1`. Since 2.32, `--fixup=amend:<commit>` also replaces the target's message (it opens the editor; `-m` is refused) and `--fixup=reword:<commit>` changes only the message.

### `--exec`: test every commit

`-x <cmd>` inserts `exec <cmd>` after each commit; a failing command stops the rebase on that commit — perfect for "does every commit build?":

```console
$ git rebase -x "test -f w1.txt" HEAD~2
Rebasing (2/4)Executing: test -f w1.txt
Rebasing (3/4)Rebasing (4/4)Executing: test -f w1.txt
Successfully rebased and updated refs/heads/work.
$ git rebase -x "test -f nonexistent.txt" HEAD~1 2>&1 | tr "\r" "\n"; git status | head -4
Rebasing (2/2)

Executing: test -f nonexistent.txt
warning: execution failed: test -f nonexistent.txt
You can fix the problem, and then run

  git rebase --continue


interactive rebase in progress; onto 004b01e
Last commands done (2 commands done):
   pick 6f107c7 work 4-reworded
   exec test -f nonexistent.txt
$ git rebase --abort; git status -sb | head -1
## work
```

### `--rebase-merges`

By default `rebase` **flattens**: merge commits are dropped and their side branches linearized. `--rebase-merges` (`-r`; replaces the old `--preserve-merges`, which Git 2.34 removed: it now fails with `fatal: --preserve-merges was replaced by --rebase-merges`) recreates the merge topology using the `label`/`reset`/`merge` todo verbs:

```console
$ git log --oneline --graph -5
*   1c5aa30 merge side
|\
| * 24b65d2 side 1
* | 7420843 rm1
|/
* fe4eea9 rm0
* c86b8e0 main moves on
$ git rebase main 2>&1 | tail -1; git log --oneline --graph -5
Rebasing (1/3)Rebasing (2/3)Rebasing (3/3)Successfully rebased and updated refs/heads/rm-base.
* 19d2ea6 side 1
* d44a8f6 rm1
* 7629572 rm0
* b9b23d1 main moves
* c86b8e0 main moves on
$ git rebase --rebase-merges main 2>&1 | tr "\r" "\n" | tail -1; git log --oneline --graph -6
Successfully rebased and updated refs/heads/rm-base.
*   642a71d merge side
|\
| * 2242bce side 1
* | d44a8f6 rm1
|/
* 7629572 rm0
* b9b23d1 main moves
* c86b8e0 main moves on
```

(The script reset the branch to `ORIG_HEAD` between the two runs, so both started from the same merge history.) Plain rebase turned the diamond into a straight line; `-r` kept it.

### Related options

- `--keep-base`, `--root` (rebase the root commit too), `--autostash` (stash, rebase, pop), `--interactive --rebase-merges`, `-X <strategy-option>`.
- `git pull --rebase` = `fetch` + `rebase` (chapter 12; config `pull.rebase`).
- `--fork-point` consults the upstream's reflog to find where your branch really forked, so commits that were dropped from a rewritten upstream are not replayed (the default when you run `git rebase` with no upstream argument).
- **`--update-refs`** (rebase stacked branches in one go) needs Git **2.38**. On 2.34.1:

```console
$ git rebase --update-refs HEAD~1 2>&1 | head -2
error: unknown option `update-refs'
usage: git rebase [-i] [options] [--exec <cmd>] [--onto <newbase> | --keep-base] [<upstream> [<branch>]]
```

## Recovering: the reflog is your undo

Every movement of `HEAD` and branch tips is logged (chapter 6). After a destructive `reset --hard`:

```console
$ git reset --hard HEAD~1; git log --oneline | head -1
HEAD is now at b9b23d1 main moves
b9b23d1 main moves
$ git reflog -3
b9b23d1 HEAD@{0}: reset: moving to HEAD~1
da9c633 HEAD@{1}: commit: will be lost
b9b23d1 HEAD@{2}: checkout: moving from rm-base to main
$ git reset --hard HEAD@{1}; git log --oneline | head -1
HEAD is now at da9c633 will be lost
da9c633 will be lost
```

After a bad rebase use `ORIG_HEAD`, or find the pre-rebase tip in `git reflog` (the line before `rebase (start)`) and `git reset --hard` to it. This only works for *committed* work and until reflog entries expire and `gc` prunes (chapter 17). Committed work is never lost by `reset --hard`; uncommitted work is.

## Rewriting a whole history: `filter-branch` and `filter-repo`

To remove a file from *every* commit (leaked secret, giant binary) or change authors repo-wide:

- `git filter-branch` ships with Git but is slow, easy to misuse, and its own man page says to prefer alternatives. It works:

```console
$ git filter-branch --tree-filter "rm -f x.txt" -- main~1..main 2>&1 | tail -2
Rewrite da9c6338fa93a88bb6a2104e7a0c8a8051a46a28 (1/1) (0 seconds passed, remaining 0 predicted)    
Ref 'refs/heads/main' was rewritten
$ git ls-tree --name-only HEAD | grep -c x.txt
0
```

- **`git filter-repo`** is the recommended replacement but is a *separate* Python tool, not part of Git; it is not installed here:

```console
$ git filter-repo --version 2>&1 | head -1
git: 'filter-repo' is not a git command. See 'git --help'.
```

*Unverified:* it was not run for this course; consult its documentation (linked in REFERENCES.md). Either way, a leaked secret must be revoked: rewriting history does not remove copies already cloned or cached by the host. After rewriting, collaborators must re-clone or hard-reset, and old objects linger in your reflog and packs until expired and garbage-collected (chapter 13).

## Rewriting without rewriting: `replace`, and `fast-export`/`fast-import`

`git replace` swaps one object for another **at read time** without touching any hash. The swap is stored as a ref `refs/replace/<old-id>` pointing at the substitute. `--graft <commit> [<parent>…]` writes a copy of the commit with different parents; with no parents it cuts history there (the old "grafts" use case):

```console
$ git log --oneline
381814b third
e4c58d8 second
367380a first
$ git replace --graft HEAD~1; git replace -l; git log --oneline
e4c58d817f4c3a75b09a8163283e56ca9f3ec839
381814b third
e4c58d8 second
$ git cat-file -p HEAD~1 | head -2; git for-each-ref refs/replace
tree 313eba2d168cdf6ede5f9caa87c9f1b5f7c3d304
author Ada Lovelace <ada@example.com> 1704186000 +0000
5c833e241c864ab63ff98852016afd969f790f7d commit	refs/replace/e4c58d817f4c3a75b09a8163283e56ca9f3ec839
$ git --no-replace-objects log --oneline | wc -l
3
$ git replace -d HEAD~1; git log --oneline | wc -l
Deleted replace ref 'e4c58d817f4c3a75b09a8163283e56ca9f3ec839'
3
```

`e4c58d8` keeps its name, but every command now reads the parentless substitute `5c833e2`. Replace refs are not pushed or fetched by the default refspecs, so the swap is local unless you share `refs/replace/*` explicitly. `git filter-branch` (above) makes such a swap permanent.

`git fast-export` writes history as a text stream of blobs, commits (with marks such as `:1`) and resets; `git fast-import` reads that stream back. Importing into an empty repository reproduces the same hashes. The two commands are the basis of repository converters and of `filter-repo`:

```console
$ git fast-export --all | head -12
blob
mark :1
data 4
one

reset refs/heads/main
commit refs/heads/main
mark :2
author Ada Lovelace <ada@example.com> 1704182400 +0000
committer Ada Lovelace <ada@example.com> 1704182400 +0000
data 6
first
$ git init -q --bare ../copy.git; git fast-export --all | git -C ../copy.git fast-import --quiet; git -C ../copy.git log --oneline main
381814b third
e4c58d8 second
367380a first
```

## Summary

- Commits are immutable; "rewriting" creates new commits and moves a ref. Old ones survive in the reflog until expiry.
- `amend` replaces the tip; `reset --soft/--mixed/--hard` moves the branch and optionally index/work tree; `ORIG_HEAD` is the quick undo; `--keep` is a `--hard` that refuses to lose local changes.
- `revert` adds an inverse commit (safe for published history); `cherry-pick` copies commits; use `-x` between public branches.
- `rebase` replays commits onto a new base; `--onto` transplants; `-i` offers pick/reword/edit/squash/fixup/drop/exec; `--autosquash`, `-x`, `-r` are the power flags.
- `--update-refs` needs Git 2.38 (not in 2.34).
- The reflog recovers committed work; the golden rule is: never rewrite published history.
- Repo-wide rewrites: `filter-branch` (built in, discouraged) or `filter-repo` (separate tool, not run here).
- `replace` substitutes objects at read time (`--graft` changes parents); `fast-export`/`fast-import` turn history into a text stream and back.

## Exercises

The solutions below were run by [`examples/ch10/exercises.sh`](examples/ch10/exercises.sh) on four commits `c1`…`c4` with files `f1`…`f4`.

1. You committed to `main` by mistake but wanted a branch `fix`. Move the commit to `fix` and restore `main`.

   <details><summary>Solution</summary>

   ```console
   $ git branch fix; git reset -q --hard HEAD~1
   $ git log --oneline -1 main; git log --oneline -1 fix
   e875221 c3
   6f9cbb6 c4
   ```

   Create the branch *before* resetting (otherwise recover the commit from the reflog), then `git switch fix` to continue there.

   </details>

2. Squash the last three commits into one using only `git reset`.

   <details><summary>Solution</summary>

   ```console
   $ git switch -q fix
   $ git reset -q --soft HEAD~3 && git commit -q -m squashed
   $ git log --oneline; git ls-files
   cea61a9 squashed
   30a968d c1
   f1
   f2
   f3
   f4
   ```

   `--soft` moves the branch back while keeping the combined changes of `c2`…`c4` staged.

   </details>

3. You ran `git reset --hard HEAD~2` and regret it. Get the commits back, two different ways.

   <details><summary>Solution</summary>

   ```console
   $ git switch -q main
   $ git reset -q --hard HEAD~2; git reset -q --hard ORIG_HEAD; git log --oneline -1
   e875221 c3
   $ git reset -q --hard HEAD~2; git reset -q --hard HEAD@{1}; git log --oneline -1
   e875221 c3
   ```

   `ORIG_HEAD` holds the position before the last reset; `HEAD@{1}` is the previous reflog entry. (`main` was at `c3` after exercise 1.)

   </details>

4. Make a rebase stop at the first commit that fails `test -f f2`.

   <details><summary>Solution</summary>

   ```console
   $ git rebase -x "test -f f2" --root 2>&1 | tr "\r" "\n" | grep -v "^Rebasing"; git status | sed -n 1,4p

   Executing: test -f f2
   warning: execution failed: test -f f2
   You can fix the problem, and then run

     git rebase --continue


   interactive rebase in progress; onto 202fe87
   Last commands done (2 commands done):
      pick 30a968d c1
      exec test -f f2
   $ git rebase --abort; git status -sb | head -1
   ## main
   ```

   `-x` adds an `exec` line after every `pick`; `--root` includes the first commit, which has no `f2`, so the rebase stops right after it. Fix the commit and `git rebase --continue`, or `git rebase --abort`.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-10--rewriting-history)
