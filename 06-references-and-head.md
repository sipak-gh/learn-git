# Chapter 6 — References and HEAD

A reference (ref) is a human-friendly name for an object ID. Branches, tags, remote-tracking branches, `HEAD` and a handful of "state" refs are all just files (or lines in `packed-refs`) holding an ID or the name of another ref. This chapter covers the `refs/` namespace, `packed-refs`, symbolic refs, detached `HEAD`, the reflog, the special refs (`ORIG_HEAD`, `FETCH_HEAD`, `MERGE_HEAD`), `update-ref`, and the three kinds of tag. Previous: [Chapter 5 — The Index](05-the-index.md). Next: [Chapter 7 — Revisions and Ranges](07-revisions-and-ranges.md).

Examples: `examples/ch06/demo.sh`.

## Branches are files

```console
$ cat .git/HEAD
ref: refs/heads/feature
$ cat .git/refs/heads/main
5d077e43fac11abb40dece318520511f16739eeb
$ find .git/refs -type f
.git/refs/heads/feature
.git/refs/heads/main
$ git rev-parse main
5d077e43fac11abb40dece318520511f16739eeb
$ git symbolic-ref HEAD
refs/heads/feature
$ git symbolic-ref --short HEAD
feature
$ git rev-parse --abbrev-ref HEAD
feature
$ git branch --show-current
feature
```

Namespaces: `refs/heads/*` local branches, `refs/tags/*` tags, `refs/remotes/<remote>/*` remote-tracking branches, `refs/stash`, `refs/notes/*`, `refs/replace/*`. `HEAD` is a **symbolic ref**: its content `ref: refs/heads/feature` means "I am on `feature`". `git commit` writes the new commit, then updates whatever `HEAD` points to; `git switch` rewrites `HEAD`. Names must pass `git check-ref-format` rules (no `..`, spaces, `~^:?*[\`, no leading/trailing `.` or `/`, no `.lock` suffix):

```console
$ git check-ref-format --branch "bad..name"; echo rc=$?
fatal: 'bad..name' is not a valid branch name
rc=128
$ git check-ref-format refs/heads/ok/name; echo rc=$?
rc=0
```

## Plumbing for refs

```console
$ git for-each-ref
5d077e43fac11abb40dece318520511f16739eeb commit	refs/heads/feature
5d077e43fac11abb40dece318520511f16739eeb commit	refs/heads/main
242b50ef9ddbe332c623bb649867d40d8c912377 tag	refs/tags/v1.0
$ git for-each-ref --format="%(refname:short) %(objecttype) %(subject)" refs/tags
v1.0 tag Version 1.0
$ git show-ref
5d077e43fac11abb40dece318520511f16739eeb refs/heads/feature
5d077e43fac11abb40dece318520511f16739eeb refs/heads/main
242b50ef9ddbe332c623bb649867d40d8c912377 refs/tags/v1.0
$ git update-ref refs/heads/scratch HEAD~2 && git branch -v
* feature 5d077e4 three
  main    5d077e4 three
  scratch 4d14821 one
$ git update-ref -d refs/heads/scratch && git branch
* feature
  main
$ git update-ref refs/heads/x HEAD HEAD~1 2>&1
fatal: update_ref failed for ref 'refs/heads/x': cannot lock ref 'refs/heads/x': unable to resolve reference 'refs/heads/x'
```

`for-each-ref --format` (with `--sort`, `--merged`, `--contains`, `--points-at`) is the scriptable way to list refs. `update-ref <ref> <new> [<old>]` is the safe primitive: with `<old>` it is an atomic compare-and-swap, which is why the last command failed (`x` doesn't exist, so it can't have the expected old value). `-m reason` writes the reflog message; `--no-deref` updates `HEAD` itself instead of the branch it points at. `git branch -f`, `git reset` and `git push` ultimately perform `update-ref`-style operations.

## `packed-refs`

Thousands of ref files are slow, so `git pack-refs` (run by `gc`) moves them into one sorted file:

```console
$ git pack-refs --all && find .git/refs -type f; cat .git/packed-refs
# pack-refs with: peeled fully-peeled sorted 
5d077e43fac11abb40dece318520511f16739eeb refs/heads/feature
5d077e43fac11abb40dece318520511f16739eeb refs/heads/main
242b50ef9ddbe332c623bb649867d40d8c912377 refs/tags/v1.0
^a234550745ed7a418114eea0d8a62f4671a5cb0b
$ git branch newbranch && find .git/refs -type f
.git/refs/heads/newbranch
$ git branch -d newbranch && cat .git/packed-refs | wc -l
Deleted branch newbranch (was 5d077e4).
5
```

The `find` printed nothing the first time: all loose ref files were gone. The `^` line stores the peeled target of an annotated tag so tag lookups don't need to open the tag object. Lookup order: a loose file wins over `packed-refs`; updating a packed ref writes a loose file, deleting rewrites `packed-refs`. A newer storage backend, **reftable** (Git 2.45, 2024), is *not* available in Git 2.34; everything here is the "files" backend.

## Detached HEAD

If `.git/HEAD` contains a bare commit ID, you are **detached**: commits you make advance only `HEAD`, no branch.

```console
$ git switch --detach HEAD~1
HEAD is now at a234550 two
$ cat .git/HEAD
a234550745ed7a418114eea0d8a62f4671a5cb0b
$ git status | head -2
HEAD detached at a234550
nothing to commit, working tree clean
$ echo "detached work" > g.txt; git add g.txt; git commit -q -m "detached commit"
$ git switch feature
Warning: you are leaving 1 commit behind, not connected to
any of your branches:

  e4812ba detached commit

Switched to branch 'feature'
$ git branch rescued HEAD@{1} && git log --oneline --graph --all
* e4812ba detached commit
| * 5d077e4 three
|/  
* a234550 two
* 4d14821 one
```

Detached HEAD is normal for inspecting an old version, building a tagged release, and during `rebase`/`bisect`. It is dangerous only if you leave without naming the commits: they become unreachable and are eventually garbage-collected ([Chapter 17](17-debugging-and-recovery.md)). The cure is `git switch -c name` *before* leaving, or afterwards `git branch name <id>` with the ID found in the reflog (`HEAD@{1}` above).

## The reflog

Every update to a ref (and to `HEAD`) is logged locally in `.git/logs/…` with old ID, new ID, identity, time and reason. It is your undo history; it is local only and never pushed.

```console
$ git reflog
5d077e4 HEAD@{0}: checkout: moving from e4812baa75a1c02be88c3c289ee3f2af33d1b714 to feature
e4812ba HEAD@{1}: commit: detached commit
a234550 HEAD@{2}: checkout: moving from feature to HEAD~1
5d077e4 HEAD@{3}: checkout: moving from main to feature
5d077e4 HEAD@{4}: commit: three
a234550 HEAD@{5}: commit: two
4d14821 HEAD@{6}: commit (initial): one
$ cat .git/logs/HEAD | head -2
0000000000000000000000000000000000000000 4d1482137da681b026efb59f0571111b4a9e9877 Ada Lovelace <ada@example.com> 1704074400 +0000	commit (initial): one
4d1482137da681b026efb59f0571111b4a9e9877 a234550745ed7a418114eea0d8a62f4671a5cb0b Ada Lovelace <ada@example.com> 1704074400 +0000	commit: two
$ git reflog show feature
5d077e4 feature@{0}: branch: Created from HEAD
$ git log -g --format="%gd %gs" -n 3
HEAD@{0} checkout: moving from e4812baa75a1c02be88c3c289ee3f2af33d1b714 to feature
HEAD@{1} commit: detached commit
HEAD@{2} checkout: moving from feature to HEAD~1
```

`ref@{n}` means "n-th previous value of ref" and `ref@{2.days.ago}` is time-based ([Chapter 7](07-revisions-and-ranges.md)). Entries expire after `gc.reflogExpire` (90 days) and entries whose commit is no longer reachable from the ref's current tip (for example the pre-rebase or pre-`reset` positions) after `gc.reflogExpireUnreachable` (30 days). Preview what an expiry would drop (with `--expire=now`, everything):

```console
$ git reflog expire --expire=now --all --dry-run | head -3
would prune commit (initial): one
would prune commit: two
would prune commit: three
```

Deleting a branch deletes its reflog; bare repositories keep no reflog by default (`core.logAllRefUpdates`).

## Special refs

Some commands leave a file in `.git/` that records state or a safety point:

| File | Written by | Meaning |
|---|---|---|
| `ORIG_HEAD` | `reset`, `merge`, `rebase`, `pull` | where `HEAD` was before the risky operation |
| `MERGE_HEAD` | `merge` (in progress) | the commit(s) being merged in; makes the next commit a merge |
| `FETCH_HEAD` | `fetch` | what was just fetched, one line per ref |
| `CHERRY_PICK_HEAD`, `REVERT_HEAD` | those commands, when stopped | the commit being applied |
| `AUTO_MERGE` | `merge` (seen in 2.34) | tree of the automatic merge attempt, so `git diff AUTO_MERGE` shows what you changed while resolving |

```console
$ git reset -q --hard HEAD~1
$ cat .git/ORIG_HEAD; git rev-parse ORIG_HEAD
5d077e43fac11abb40dece318520511f16739eeb
5d077e43fac11abb40dece318520511f16739eeb
$ git reset -q --hard ORIG_HEAD && git log --oneline -1
5d077e4 three
$ git merge --no-commit m1
Automatic merge went well; stopped before committing as requested
$ cat .git/MERGE_HEAD; git rev-parse m1; ls .git | grep MERGE
6d1124f0bd0c9d9a8518f5505bed8cb57f5b37e5
6d1124f0bd0c9d9a8518f5505bed8cb57f5b37e5
AUTO_MERGE
MERGE_HEAD
MERGE_MODE
MERGE_MSG
```

`reset --hard ORIG_HEAD` undid the accidental reset. In a fresh clone, `FETCH_HEAD` and the remote's default-branch pointer look like this (paths shortened):

```console
$ git fetch -q origin; cat .git/FETCH_HEAD
3c5a035e2873a54a0b184dd95b64849d6b8eb620		branch 'main' of /home/you/lab
5d077e43fac11abb40dece318520511f16739eeb	not-for-merge	branch 'feature' of /home/you/lab
6d1124f0bd0c9d9a8518f5505bed8cb57f5b37e5	not-for-merge	branch 'm1' of /home/you/lab
e4812baa75a1c02be88c3c289ee3f2af33d1b714	not-for-merge	branch 'rescued' of /home/you/lab
$ ls .git/refs/remotes/origin; cat .git/refs/remotes/origin/HEAD
HEAD
ref: refs/remotes/origin/main
```

The empty middle field marks what `git pull` would merge (the current branch's upstream); the rest are `not-for-merge`. `origin/HEAD` is a symbolic ref to the remote's default branch, set at clone time (re-sync with `git remote set-head origin -a`).

## Tags: lightweight, annotated, signed

| Kind | Created with | Stored as | Use |
|---|---|---|---|
| Lightweight | `git tag name [commit]` | a ref directly to the commit | private bookmarks |
| Annotated | `git tag -a -m msg name` | a `tag` object (tagger, date, message) + ref | releases |
| Signed | `git tag -s name` (GPG; SSH signing via `gpg.format=ssh` is available from 2.34) | annotated tag with a signature in its body | verifiable releases |

```console
$ git tag light
$ git tag -a -m "Version 1.0" v1.0 HEAD~1
$ find .git/refs/tags -type f
.git/refs/tags/v1.0
.git/refs/tags/light
$ cat .git/refs/tags/light; cat .git/refs/tags/v1.0
5d077e43fac11abb40dece318520511f16739eeb
242b50ef9ddbe332c623bb649867d40d8c912377
$ git rev-parse v1.0 v1.0^{} light
242b50ef9ddbe332c623bb649867d40d8c912377
a234550745ed7a418114eea0d8a62f4671a5cb0b
5d077e43fac11abb40dece318520511f16739eeb
$ git cat-file -t light; git cat-file -t v1.0
commit
tag
$ git tag -n; git tag -l "v*"
light           three
v1.0            Version 1.0
v1.0
$ git show v1.0 --stat | head -8
tag v1.0
Tagger: Ada Lovelace <ada@example.com>
Date:   Mon Jan 1 04:00:00 2024 +0000

Version 1.0

commit a234550745ed7a418114eea0d8a62f4671a5cb0b
Author: Ada Lovelace <ada@example.com>
$ git describe
v1.0-1-g5d077e4
$ git describe --always --abbrev=4 HEAD~1
v1.0
```

`describe` names a commit relative to the nearest annotated tag: `v1.0-1-g5d077e4` = one commit after `v1.0`, then `g` and the abbreviated ID. (Lightweight tags are ignored unless `--tags`.) Tags are not moved by `commit`, are **not pushed by default** (`git push origin v1.0` or `--tags`; [Chapter 12](12-remotes-in-depth.md)), and re-tagging requires `-f`. Signed tags and `git tag -v` are demonstrated in [Chapter 16](16-collaboration-and-patches.md).

## Summary

- Refs are files under `.git/refs/` (or lines in `packed-refs`); `HEAD` is a symbolic ref, or a raw ID when detached.
- `update-ref` is the atomic primitive; `for-each-ref`, `show-ref`, `symbolic-ref`, `rev-parse` read refs.
- The reflog records every movement of `HEAD` and branches locally; it is how you recover from `reset --hard` and lost detached commits.
- `ORIG_HEAD`, `MERGE_HEAD`, `FETCH_HEAD` store operation state or safety points.
- Annotated tags are objects; lightweight tags are plain refs; reftable needs Git ≥ 2.45.

## Exercises

1. You made commits while detached and then switched away. Get them back as a branch `rescued`.

   <details><summary>Solution</summary>

   `git reflog` finds the ID (`e4812ba`), then `git branch rescued e4812ba` (above, `HEAD@{1}` was the same commit). The graph showed the commit hanging off `a234550`.

   </details>

2. Move `main` to `HEAD~2` with `update-ref`, but only if it currently points at `HEAD`.

   <details><summary>Solution</summary>

   ```console
   $ git update-ref -m "manual move" refs/heads/main HEAD~2 HEAD; git log --oneline main
   f8a7fd0 one
   $ git update-ref -m "again" refs/heads/main HEAD~1 HEAD
   fatal: update_ref failed for ref 'refs/heads/main': cannot lock ref 'refs/heads/main': is at f8a7fd0fa9b0e21176f8a9463d194aef9d2b2b02 but expected ab3d8052f008fb10ad4aa4fbe223c6fd316f094e
   ```

   (Run from `feature`, which was at the same commit as `main`; see `exercises.sh`.) The second call shows the compare-and-swap refusing a stale `<old>`. Porcelain equivalent: `git branch -f main HEAD~2` (no check; refuses the checked-out branch).

   </details>

3. Tell a lightweight from an annotated tag with plumbing only.

   <details><summary>Solution</summary>

   `git cat-file -t <tag>` prints `commit` (lightweight) or `tag` (annotated), as shown above.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-6--references-and-head)
