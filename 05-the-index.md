# Chapter 5 — The Index

The index (staging area) is a binary file, `.git/index`, that lists every tracked path with its mode, blob ID and cached `stat` data. It is the "proposed next commit", the cache that makes `git status` fast, and the workspace where merges record conflicts. This chapter inspects it with `ls-files` and `update-index`, shows conflict stages, intent-to-add, how `add -p` really works, racy-Git handling, `skip-worktree` and the sparse index. Previous: [Chapter 4 — The Object Database](04-the-object-database.md). Next: [Chapter 6 — References and HEAD](06-references-and-head.md).

Examples: `examples/ch05/demo.sh`.

## What is in the index

```console
$ git ls-files -s
100644 5626abf0f72e58d7a153368ba57db4c673c0e171 0	a.txt
100644 f719efd430d52bcfc8566a43b2eb655688d38871 0	b.txt
100644 2bdf67abb163a4ffb2d7f3f0880c9fe5068ce782 0	d/c.txt
$ git ls-files --debug a.txt
a.txt
  ctime: 1793533760:712137778
  mtime: 1793533760:712137778
  dev: 2096	ino: 430788
  uid: 1000	gid: 1000
  size: 4	flags: 0
$ xxd .git/index | head -1
00000000: 4449 5243 0000 0002 0000 0003 6ae7 2740  DIRC........j.'@
```

(Times, `dev` and `ino` differ on your machine.) Per entry: `mode`, blob ID, **stage** (the `0`, normally), path, plus a copy of the file's `stat` fields. The file starts with `DIRC` ("dircache"), version `2`, and the entry count (`3`); full layout in [Appendix B](appendix-b-plumbing-and-file-formats.md#the-index-gitindex).

Unlike a tree, the index is flat (full paths, sorted), which is why `git add` of a nested path doesn't need to touch parent directories. `git write-tree` converts it to nested tree objects ([Chapter 4](04-the-object-database.md)); the index also stores a *cache-tree* extension so unchanged directories need not be recomputed at commit.

## Three-way comparison

Every status/diff command compares two of {`HEAD` tree, index, working tree}:

```console
$ echo ONE > a.txt
$ git ls-files -m
a.txt
$ git update-index --refresh
a.txt: needs update
$ git diff-files --name-status
M	a.txt
$ git add a.txt; git diff-index --cached HEAD --name-status
M	a.txt
$ git diff-index HEAD --name-status
M	a.txt
```

`diff-files` = worktree vs index (`git diff`); `diff-index --cached` = index vs tree (`git diff --staged`); `diff-index <tree>` = worktree vs tree. These plumbing commands have stable output for scripts, unlike `git status`.

## Editing the index directly

`git update-index` is the low-level `add`/`rm`. `--cacheinfo mode,id,path` creates an entry with no working-tree file:

```console
$ git update-index --add --cacheinfo 100644,$(echo hi | git hash-object -w --stdin),virtual.txt && git status -s
AD virtual.txt
$ git update-index --force-remove virtual.txt && git status -s
```

`AD` = added to the index, missing from the working tree. Any command can use a different index file via `GIT_INDEX_FILE`, a trick for building trees without disturbing your staging area:

```console
$ GIT_INDEX_FILE=.git/tmp-index git read-tree HEAD && GIT_INDEX_FILE=.git/tmp-index git ls-files | head -2
a.txt
b.txt
$ git read-tree --empty && git status -s | head -3
D  a.txt
D  b.txt
D  d/c.txt
$ git reset -q && git status -s
```

`read-tree` loads a tree into the index; after `--empty`, the index has nothing, so everything looks "staged for deletion" relative to `HEAD`. `git reset` (mixed) rebuilds the index from `HEAD` ([Chapter 10](10-rewriting-history.md)).

## How `add -p` works

`git add -p` (and `-e`, `restore -p`, `stash -p`, `checkout -p`) is a Perl/C front end around one idea: build a **patch** of the chosen hunks and apply it **to the index only**. You can do it by hand:

```console
$ git diff -U1 long.txt > ../full.patch
$ grep -c "^@@" ../full.patch
2
$ git apply --cached --recount ../full.patch && git diff --cached --stat
 long.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```

`apply --cached` changes only the index; the working tree keeps your edits. In `add -p`, answering `e` opens the hunk in your editor so you can hand-edit the patch (delete `+` lines to not stage them, turn `-` lines into context spaces to keep them); `--recount` is how Git tolerates the edited hunk header. This is how you stage *part of a line-group*.

## Intent to add

`git add -N path` (`--intent-to-add`) puts an empty placeholder in the index so a new file shows in `git diff` and can be staged piecemeal with `add -p`.

```console
$ git add -N new.txt && git status -s && git diff | head -5
 A new.txt
diff --git a/new.txt b/new.txt
new file mode 100644
index 0000000..d5a09df
--- /dev/null
+++ b/new.txt
$ git ls-files -s new.txt
100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	new.txt
```

`e69de29…` is the well-known empty blob. Note the status code ` A` (unstaged add).

## Conflicts: stages 1, 2, 3

During a merge, a path that can't be merged automatically leaves **three entries** in the index instead of stage 0: stage 1 = common ancestor, 2 = "ours" (current branch), 3 = "theirs". The working-tree file holds the conflict markers.

```console
$ git merge side
Auto-merging a.txt
CONFLICT (content): Merge conflict in a.txt
Automatic merge failed; fix conflicts and then commit the result.
$ git ls-files -s a.txt
100644 5626abf0f72e58d7a153368ba57db4c673c0e171 1	a.txt
100644 ba2906d0666cf726c7eaadd2cd3db615dedfdf3a 2	a.txt
100644 2299c37978265a95cbe835a4b0f0bbf15aad5549 3	a.txt
$ git ls-files -u
100644 5626abf0f72e58d7a153368ba57db4c673c0e171 1	a.txt
100644 ba2906d0666cf726c7eaadd2cd3db615dedfdf3a 2	a.txt
100644 2299c37978265a95cbe835a4b0f0bbf15aad5549 3	a.txt
$ git show :1:a.txt; git show :2:a.txt; git show :3:a.txt
one
main
side
$ git status -s
UU a.txt
$ cat a.txt
<<<<<<< HEAD
main
=======
side
>>>>>>> side
```

`:N:path` is revision syntax for "path at stage N". `UU` = unmerged, both modified (other pairs: `AA`, `DU`, `UD`, `AU`, `UA`, `DD`). Resolution is *adding a stage-0 entry*:

```console
$ git checkout --ours a.txt && git add a.txt && git ls-files -s a.txt
Updated 1 path from the index
100644 ba2906d0666cf726c7eaadd2cd3db615dedfdf3a 0	a.txt
$ git merge --abort 2>&1; git status -s
```

`git add` collapses stages 1–3 into stage 0; `git merge --abort` restores the pre-merge state. Resolution strategies and tools are in [Chapter 9](09-diff-and-merge-internals.md). (`rerere` stores resolutions keyed by these exact conflict shapes.)

## Racy Git and the stat cache

To answer "did this file change?" without reading every file, Git compares the cached `stat` data (mtime, ctime, size, inode…) to the file. If they match, it assumes the content is the same. That fails when a file is modified in the same timestamp tick as the index was written ("**racily clean**"): the mtime equals the index's own timestamp, so equality proves nothing. Git handles it by treating any entry whose mtime is not older than the index file's as suspect and comparing content instead (and when it writes a new index it re-checks such entries; one whose content really differs is "smudged" by recording its size as 0, so it can never look clean again by stat alone). You never need to do anything, but it explains why `git status` is sometimes slower right after `git add`, and why the stat fields exist. Tuning knobs: `core.trustctime`, `core.checkStat` (`default`/`minimal`), `core.untrackedCache`, `core.fsmonitor` (a hook-based file-watcher interface in 2.34; the built-in `git fsmonitor--daemon` arrived in 2.37), and `git update-index --refresh`.

## Flags: `assume-unchanged`, `skip-worktree`, sparse checkout

Per-entry flags tell Git to skip the stat/content check:

```console
$ git update-index --skip-worktree b.txt && git ls-files -v | head -3
H a.txt
S b.txt
H d/c.txt
$ echo edited > b.txt; git status -s
$ git update-index --no-skip-worktree b.txt && git status -s
 M b.txt
```

`-v` prefixes `H` (normal) or `S` (skip-worktree); `h` is assume-unchanged. `--assume-unchanged` is a performance promise ("I won't change this"), not a way to ignore files: Git may overwrite your changes. `--skip-worktree` means "this path is intentionally absent or different from the index"; **sparse checkout** uses it. In *cone mode* the top-level files and the listed directories are kept:

```console
$ git sparse-checkout init --cone && git sparse-checkout set d; git sparse-checkout list; git ls-files -v; ls
d
H a.txt
H b.txt
H d/c.txt
S e/f.txt
H long.txt
a.txt
b.txt
d
long.txt
$ git sparse-checkout disable && ls
a.txt
b.txt
d
e
long.txt
```

`e/f.txt` is still in the index (`S`) but removed from the disk. The **sparse index** (`index.sparse=true`, or `git sparse-checkout init --cone --sparse-index`; experimental since 2.32, with more commands supporting it in 2.33 and 2.34) can go further and store a whole excluded directory as one tree-like entry (extension `sdir`), shrinking the index in huge monorepos. It is relatively new and tool support varies; many commands expand the index anyway. More in [Chapter 14](14-submodules-subtrees-large-repos.md).

## Summary

- The index is a sorted flat list of (mode, blob ID, stage, path, stat data); `write-tree` turns it into tree objects.
- `diff-files`, `diff-index [--cached]`, `ls-files -s/-u/-m` expose it; `update-index --cacheinfo` and `GIT_INDEX_FILE` let you script it.
- `add -p` = build a patch, `apply --cached`. `add -N` = empty placeholder entry.
- Conflicts = stages 1/2/3 for a path; `git add` resolves; `git show :N:path` reads each side.
- Stat caching + racy-git rules make status fast and still correct; `skip-worktree` powers sparse checkout.

## Exercises

1. In a conflicted merge, write "theirs" (stage 3) of a file to `theirs.txt` without touching the working tree.

   <details><summary>Solution</summary>

   ```console
   $ git show :3:a.txt > theirs.txt
   $ cat theirs.txt
   side
   ```

   (Stage numbers are in the transcript above; `git checkout --theirs a.txt` would instead overwrite `a.txt`.)

   </details>

2. Stage only the first of two hunks of `long.txt` without `add -p`.

   <details><summary>Solution</summary>

   Make a patch with only the first hunk (delete the second `@@` block from `full.patch`) and run `git apply --cached --recount that.patch`. The full-patch version above staged both hunks (`2 insertions(+), 2 deletions(-)`); `git diff --cached --stat` after the trimmed patch shows `1 insertion(+), 1 deletion(-)`, and `git diff --stat` shows the other hunk still unstaged.

   </details>

3. What does status code `AD` mean and how can it arise?

   <details><summary>Solution</summary>

   Added in the index, deleted in the working tree: the index has an entry (e.g. from `update-index --cacheinfo`, or `git add` then `rm`) but the file is missing from disk. Shown above for `virtual.txt`.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-5--the-index)
