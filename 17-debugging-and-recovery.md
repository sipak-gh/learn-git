# Chapter 17 — Debugging and Recovery

Git almost never destroys data immediately: objects stay in the database until `gc` prunes them, and refs and reflogs say where things used to be. This chapter shows how to find lost commits and blobs, what a corrupted object looks like, how to repair from another copy, how `bisect run` automates bug hunting, and how to trace what Git is doing. Previous: [Chapter 16 — Collaboration and Patches](16-collaboration-and-patches.md). Next: [Chapter 18 — Mini-Git and Where Next](18-mini-git-and-where-next.md).

Transcripts come from [`examples/ch17/demo.sh`](examples/ch17/demo.sh) (Git 2.34.1). Paths and timestamps are trimmed; hashes are reproducible by running the script.

## Recovery decision list

1. Did it ever get **committed**? Look in `git reflog` (HEAD and per-branch: `git reflog show feature`).
2. Not in a reflog (branch deleted, reflog expired)? `git fsck --lost-found` lists unreachable objects.
3. Only **added** (staged) and then lost? Its blob exists; fsck finds it. Never added? Gone.
4. Object file damaged? Restore it from another clone, or re-fetch.

## Deleted branch

Deleting a branch removes only the ref. The commit remains, and the HEAD reflog recorded it when you were on it:

```console
$ git branch -D feature
Deleted branch feature (was 467e7a7).
$ git reflog --format="%h %gd %gs" | head -5
4e9827c HEAD@{0} checkout: moving from feature to main
467e7a7 HEAD@{1} commit: feature work
4e9827c HEAD@{2} checkout: moving from main to feature
4e9827c HEAD@{3} commit: commit 6
395f741 HEAD@{4} commit: commit 5
```

`git branch feature 467e7a7` brings it back. (`branch -D` itself prints the old hash: note it.)

## fsck and dangling objects

`git fsck` checks connectivity and object validity. An object no ref can reach is *unreachable*; a *dangling* one is an unreachable object that no other unreachable object points at either, the tip of a lost chain (`--unreachable` lists them all). Plain `git fsck` counts reflog entries as references, so straight after `branch -D` it reports nothing: the commit is still in `HEAD`'s reflog. `--lost-found` implies `--no-reflogs`, so it reports the commit, and it also writes dangling objects under `.git/lost-found/`.

```console
$ git fsck --lost-found 2>&1 | head -3
dangling commit 467e7a74bef8db13d23912c3919f11f498b66aa4
$ git log --oneline -1 467e7a74bef8db13d23912c3919f11f498b66aa4
467e7a7 feature work
$ git branch feature 467e7a74bef8db13d23912c3919f11f498b66aa4; git log --oneline -2 feature
467e7a7 feature work
4e9827c commit 6
```

### Undoing `reset --hard`

`reset --hard` moves the branch and rewrites the working tree, but the old tip is in the reflog, so `HEAD@{n}` gets you back (tracked, committed work only):

```console
$ git reset -q --hard HEAD~2; git log --oneline -1
99b52de commit 4
$ git reflog -3 --format="%h %gd %gs"
99b52de HEAD@{0} reset: moving to HEAD~2
4e9827c HEAD@{1} checkout: moving from feature to main
467e7a7 HEAD@{2} commit: feature work
$ git reset -q --hard HEAD@{1}; git log --oneline -1
4e9827c commit 6
```

### Staged-then-lost content

`git add` writes the blob immediately. If you then lose the index entry, the blob is dangling:

```console
$ git fsck --lost-found 2>&1 | head -2
dangling blob fbbdf22a3483e250b1a1ffe75e0dab4e58d7af3c
$ git cat-file -p fbbdf22a3483e250b1a1ffe75e0dab4e58d7af3c
precious
$ ls .git/lost-found/other | head -2
fbbdf22a3483e250b1a1ffe75e0dab4e58d7af3c
```

Blobs have no names; you identify them by content. Content that was never `add`ed, or committed, cannot be recovered by Git.

## Expiry and gc: when it really is gone

Reflog entries expire after 90 days, or 30 days for entries no longer reachable from the ref's current tip (`gc.reflogExpire`, `gc.reflogExpireUnreachable`), and `gc` prunes unreachable loose objects older than `gc.pruneExpire` (2 weeks). These defaults were checked in a separate test with back-dated commits and file times (`git reflog expire --all` dropped reachable entries 95 and 100 days old and unreachable ones 35 and 40 days old, but kept an unreachable one 20 days old; see [chapter 13](13-transport-and-packfiles.md#repack-prune-and-gc) for the 2-week prune). The demo forces both:

```console
$ git reflog expire --expire=now --all; git reflog -2 --format="%h %gs"
$ git gc --prune=now -q; git fsck --lost-found 2>&1 | head -2; echo rc=$?
rc=0
```

After this, the dangling blob and everything else unreachable is deleted: fsck reports nothing. So: fix mistakes within days, and do not run `gc --prune=now` or `reflog expire --expire=now` while you still need a way back.

## Corruption

A damaged object is an invalid zlib stream or a hash mismatch. Here a clone (`--no-local`, so objects are not hard-linked to the source) makes one commit, then its loose object file is overwritten:

```console
$ git fsck 2>&1; echo rc=$?
rc=0
$ git fsck 2>&1 | head -4
error: inflate: data stream error (incorrect header check)
error: unable to parse header of .git/objects/f0/f2a6f2c03ddafd9c6b00616c236c32e0805d22
error: f0f2a6f2c03ddafd9c6b00616c236c32e0805d22: object corrupt or missing: .git/objects/f0/f2a6f2c03ddafd9c6b00616c236c32e0805d22
error: inflate: data stream error (incorrect header check)
$ git cat-file -p f0f2a6f2c03ddafd9c6b00616c236c32e0805d22 2>&1 | head -2
error: inflate: data stream error (incorrect header check)
error: unable to unpack f0f2a6f2c03ddafd9c6b00616c236c32e0805d22 header
```

After deleting the bad file, the refs and reflogs still point at it:

```console
$ git fsck 2>&1 | head -3
error: refs/heads/main: invalid sha1 pointer f0f2a6f2c03ddafd9c6b00616c236c32e0805d22
error: HEAD: invalid sha1 pointer f0f2a6f2c03ddafd9c6b00616c236c32e0805d22
error: HEAD: invalid reflog entry f0f2a6f2c03ddafd9c6b00616c236c32e0805d22
```

This commit was only local, so the fix is to point the branch back at a good commit (`origin/main`), expire the reflogs that mention it, and reset:

```console
$ git update-ref refs/heads/main origin/main; git reflog expire --expire=now --all; git reset -q --hard main; git fsck 2>&1; echo rc=$?
dangling tree e70101f13ba47e96076cffb2c547fccc120da061
rc=0
```

(Plain `git reset --hard origin/main` also works, but prints `error: update_ref failed for ref 'ORIG_HEAD': … trying to write ref 'ORIG_HEAD' with nonexistent object …`, since it saves the old, now-missing tip in `ORIG_HEAD`; tested separately.) The leftover dangling tree belonged to the lost commit.

General repair strategy for a repo whose objects are missing or corrupt:

1. Back up the directory first.
2. Find the damage with `git fsck --full` (also checks packs; `git verify-pack` for a single pack).
3. If a healthy copy exists (another clone, the remote), copy the **same object** from it, or `git fetch` from it; Git skips objects it believes it has, so remove the corrupt file first.
4. If the object is gone everywhere, reset refs to the newest good commit and accept the loss.

Corrupted *packs* are handled the same way, with more care (`git unpack-objects` can salvage a pack's readable objects). *Unverified:* pack repair was not exercised for this course.

## bisect, automated

`git bisect run <cmd>` binary-searches history: exit 0 = good, 1–127 except 125 = bad, 125 = skip, and 128 or more aborts the bisection. Only 0/1 appear in the transcript; in a separate test, a script that always exited 125 ended with `There are only 'skip'ped commits left to test.`, 126 and 127 counted as bad, and 128, 200 and 255 stopped with `bisect run failed: exit code N from '…' is < 0 or >= 128`. The script below treats a `f.txt` version number under 4 as good:

```console
$ git bisect start HEAD good >/dev/null; git bisect run ../check.sh 2>&1 | grep -E "^(running|bisecting|[0-9a-f]{40}|bisect)" | cut -c1-70
running  '../check.sh'
running  '../check.sh'
99b52de431ea3dfb2a35dfa05569fd9924e9dee6 is the first bad commit
bisect found first bad commit
$ git bisect log | tail -3; git bisect reset 2>&1 | tail -1
# good: [3bb8548809edf5852b9bcb9ed703b6cea6374ddc] commit 3
git bisect good 3bb8548809edf5852b9bcb9ed703b6cea6374ddc
# first bad commit: [99b52de431ea3dfb2a35dfa05569fd9924e9dee6] commit 4
Switched to branch 'main'
```

`bisect log` can be saved and replayed (`git bisect replay`). Chapter 8 covers the manual flow.

## Tracing Git itself

Environment variables switch on tracing to stderr: `GIT_TRACE` (commands, aliases, subprocesses), `GIT_TRACE_PERFORMANCE`, `GIT_TRACE_SETUP` (repo discovery), `GIT_TRACE_PACKET` (wire protocol), `GIT_CURL_VERBOSE` (HTTP), `GIT_TRACE2` (structured events). Leading timestamps are stripped below.

```console
$ GIT_TRACE=1 git st 2>&1 | sed -E "s/^[0-9:.]+ +//; s/^([a-z_.-]+\.c:[0-9]+) +/\1 /" | head -4
git.c:742 trace: exec: git-st
run-command.c:668 trace: run_command: git-st
git.c:396 trace: alias expansion: st => status -s
git.c:803 trace: exec: git status -s
$ GIT_TRACE_PERFORMANCE=1 git status -s 2>&1 | sed -E "s/^[0-9:.]+ +//; s/^([a-z_.-]+\.c:[0-9]+) +/\1 /" | sed -E 's/performance: [0-9.]+ s/performance: N s/' | head -2
read-cache.c:2398 performance: N s:  read cache .git/index
read-cache.c:1690 performance: N s:  refresh index
$ GIT_TRACE_SETUP=1 git status -s 2>&1 | sed -E "s/^[0-9:.]+ +//; s/^([a-z_.-]+\.c:[0-9]+) +/\1 /" | sed 's#/home/you/lab#.#' | head -3
trace.c:387 setup: git_dir: .git
trace.c:388 setup: git_common_dir: .git
trace.c:389 setup: worktree: .
```

(The `sed` commands strip the timestamps, collapse the padding after `file.c:line`, replace the varying duration with `N` and shorten the path.) `GIT_TRACE=1 git st` shows how an alias is resolved: first it tries an external `git-st`, then expands the alias. `GIT_TRACE_PACKET` was shown in [Chapter 13](13-transport-and-packfiles.md). Related debugging tools: `git bugreport` (writes system info and a template to `git-bugreport-<date>.txt`; `-o <dir>` picks the directory), `git config --show-origin`, `git check-ignore -v`, `git check-attr -a`.

## Summary

- Recover committed work from reflogs; recover unreferenced objects with `fsck --lost-found`; staged-only content survives as dangling blobs.
- Reflog expiry plus `gc --prune` is what makes data truly unrecoverable.
- Corruption shows as zlib errors or missing objects; repair by restoring objects from another copy or by moving refs to a good commit.
- `bisect run` turns "find the breaking commit" into a script.
- `GIT_TRACE*` variables explain what Git executes.

## Exercises

Solutions: [`examples/ch17/exercises.sh`](examples/ch17/exercises.sh) (a repository with six commits of `f.txt` containing `version 1` … `version 6`, and tag `v1.0` on commit 2).

1. Create a branch with one commit, delete it with `-D`, and bring it back using only `git reflog`.

   <details><summary>Solution</summary>

   ```console
   $ git switch -q -c tmp; echo x > t; git add t; git commit -q -m tmp; git switch -q main; git branch -D tmp
   Deleted branch tmp (was ee50d3a).
   $ git reflog --format="%h %gs" | grep "commit: tmp"
   ee50d3a commit: tmp
   $ git branch tmp "$(git reflog --format="%h %gs" | grep -m1 "commit: tmp" | cut -d" " -f1)"; git log --oneline -1 tmp
   ee50d3a tmp
   ```

   Interactively you would just read the hash and run `git branch tmp ee50d3a`.

   </details>

2. Stage a file, then `git rm --cached -f` it and delete it from disk. Recover its content.

   <details><summary>Solution</summary>

   ```console
   $ echo precious > p.txt; git add p.txt; git rm -q --cached -f p.txt; rm p.txt; git fsck --lost-found 2>&1 | grep blob
   dangling blob fbbdf22a3483e250b1a1ffe75e0dab4e58d7af3c
   $ git cat-file -p "$(git fsck --lost-found 2>/dev/null | awk "/dangling blob/{print \$3}")"
   precious
   ```

   The same content is also in `.git/lost-found/other/fbbdf22…`.

   </details>

3. A test script exits 0 on good commits (here `../t.sh`, good while the version in `f.txt` is below 4). Run an automated bisect between `v1.0` (good) and `HEAD` and return to your branch afterwards.

   <details><summary>Solution</summary>

   ```console
   $ git bisect start HEAD v1.0 >/dev/null; git bisect run ../t.sh 2>&1 | grep "is the first bad commit"; git bisect reset 2>&1 | tail -1
   d417420f5ad7bc83d526e5c1c9c17cacef6ed101 is the first bad commit
   Switched to branch 'main'
   ```

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-17--debugging-and-recovery)
