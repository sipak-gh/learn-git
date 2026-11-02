# Chapter 9 — Diff Internals and Merge Mechanics

Git stores snapshots, so every diff is computed on demand, and a merge is just a three-way diff-and-combine over three snapshots. This chapter covers how line diffs are chosen, how renames are *guessed*, how the three-way merge works, how to read and resolve conflicts, and how merge strategies differ. Previous: [Chapter 8 — Reading and Searching History](08-reading-and-searching-history.md). Next: [Chapter 10 — Rewriting History](10-rewriting-history.md).

All transcripts come from [`examples/ch09/demo.sh`](examples/ch09/demo.sh) (full output in `output.txt`), run with Git 2.34.1.

## Diff algorithms

A diff is a shortest-edit-script problem: many different scripts have the same length, so the algorithm decides which you see. `--diff-algorithm=` (or config `diff.algorithm`) picks one:

| Algorithm | Idea |
|-----------|------|
| `myers` (default) | Greedy, fast, minimal-ish edit script |
| `minimal` | Myers, but spends extra time to guarantee the smallest script |
| `patience` | Anchors on lines that are unique in both files, recurses between anchors; good for code with repeated `}` and blank lines |
| `histogram` | Patience-like, uses a frequency histogram, falls back to Myers; usually the best readability |

Same edit, three answers (the files contain repeated `}` and blank lines; headers trimmed with `tail`):

```console
$ git diff --no-index --diff-algorithm=myers old.c new.c | tail -n +5
@@ -1,8 +1,7 @@
 
-u0
 }
-
 }
+
     return 0;
 u3
     return 0;
$ git diff --no-index --diff-algorithm=patience old.c new.c | tail -n +5
@@ -1,8 +1,7 @@
 
-u0
+}
 }
 
-}
     return 0;
 u3
     return 0;
$ git diff --no-index --diff-algorithm=histogram old.c new.c | tail -n +5
@@ -1,8 +1,7 @@
 
-u0
-}
-
 }
+}
+
     return 0;
 u3
     return 0;
$ git diff --no-index --diff-algorithm=minimal --stat old.c new.c
 old.c => new.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)
```

All three are valid and apply the same change. Which one a human finds easiest varies; the choice also affects merges, because merge computes its own diffs (`-X patience`, `-X diff-algorithm=histogram`). Set a default with `git config diff.algorithm histogram`.

(This input was found by a random search; it is not a canonical example. Typical real-world differences show up when whole functions are inserted between look-alike functions.)

## Word diffs

`--word-diff[=color|plain|porcelain|none]` diffs within lines by splitting on whitespace; `--word-diff-regex=<re>` (or `--color-words=<re>`) changes what a "word" is:

```console
$ git diff --no-index --word-diff s1 s2
diff --git a/s1 b/s2
index 2fe6575..fd5daf5 100644
--- a/s1
+++ b/s2
@@ -1 +1 @@
The quick [-brown-]{+red+} fox [-jumps-]{+leaps+} over the lazy [-dog.-]{+cat.+}
$ git diff --no-index --word-diff=porcelain s1 s2
diff --git a/s1 b/s2
index 2fe6575..fd5daf5 100644
--- a/s1
+++ b/s2
@@ -1 +1 @@
 The quick 
-brown
+red
  fox 
-jumps
+leaps
  over the lazy 
-dog.
+cat.
~
$ git diff --no-index --word-diff-regex=. --word-diff=plain s1 s2 | tail -1
The quick [-b-]r[-own-]{+ed+} fox [-jum-]{+lea+}ps over the lazy [-dog-]{+cat+}.
$ git diff --no-index --color-words --color=always s1 s2 | cat -v | tail -1
The quick ^[[31mbrown^[[m^[[32mred^[[m fox ^[[31mjumps^[[m^[[32mleaps^[[m over the lazy ^[[31mdog.^[[m^[[32mcat.^[[m
```

`porcelain` is a script-friendly form (`~` marks line ends). Whitespace options: `-w` (`--ignore-all-space`), `-b`, `--ignore-space-at-eol`, `--ignore-blank-lines`; `git diff --check` flags whitespace errors. For refactors, `--color-moved` colours blocks of lines that were moved rather than changed in a different colour from real additions and deletions (and `--color-moved-ws=ignore-all-space` tolerates re-indentation).

## Rename and copy detection

Git does **not** record renames. A rename is a delete plus an add; `diff`/`log`/`merge` pair them up afterwards by content similarity. With `-M[<n>%]` (default 50%) an exact-hash match counts as 100%, otherwise a similarity score is computed over the pair:

```console
$ git diff --cached --stat -M
 data.txt => renamed.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --cached --name-status -M50%
R095	data.txt	renamed.txt
$ git diff --cached --name-status --no-renames
D	data.txt
A	renamed.txt
```

After rewriting most of the file the pair is no longer similar enough, and the rename is lost (even at a lower threshold: this file has 30 of 40 lines changed):

```console
$ git diff --cached --name-status -M
D	data.txt
A	renamed.txt
$ git diff --cached --name-status -M30%
D	data.txt
A	renamed.txt
```

Copies: `-C` only considers files *modified in the same diff* as sources; `--find-copies-harder` considers every file in the tree (slow on big repos):

```console
$ git diff --cached --name-status -C
A	copy.txt
$ git diff --cached --name-status -C --find-copies-harder
C098	renamed.txt	copy.txt
```

Consequences: `git log --follow <file>` follows renames for a single path (heuristic, one path only); `git blame -M/-C` (chapter 8) uses the same machinery; commit renames in a separate commit from large edits to keep similarity high. Config: `diff.renames` (default true), `diff.renameLimit`, `merge.renames`.

## The three-way merge

Merging `theirs` into `ours` finds the **merge base** (chapter 7), then compares each side to it:

```
          base
         /    \
     ours      theirs
```

Per file (and per hunk): changed on one side only → take that change; changed identically on both → take it once; changed differently in overlapping regions → conflict. Whole-file level: both sides modified the same path → run a content merge; one side deleted and the other modified → conflict (`modify/delete`); both added different content → `add/add`; a rename on one side and an edit on the other → the edit follows the rename (via the rename detection above).

You can run the hunk-level logic yourself with `git merge-file <ours> <base> <theirs>` (writes into the first file; `-p` prints). It exits with the number of conflicts:

```console
$ git merge-file -p ours.txt base.txt theirs.txt
a
B-ours
c
d
E-theirs
$ git merge-file -p ours.txt base.txt theirs2.txt; echo rc=$?
a
<<<<<<< ours.txt
B-ours
=======
b-theirs
>>>>>>> theirs2.txt
c
d
e
rc=1
$ git merge-file -p --diff3 ours.txt base.txt theirs2.txt
a
<<<<<<< ours.txt
B-ours
||||||| base.txt
b
=======
b-theirs
>>>>>>> theirs2.txt
c
d
e
```

Non-overlapping changes merge cleanly; changes to the *same* lines conflict (the second case: both sides rewrote line 2). Edits to *adjacent* lines conflict too, because the hunks touch: with `ours` changing line 2 and `theirs` line 3, `merge-file` also exits 1. One unchanged line between the edits is enough to merge cleanly (exercise 2).

## Anatomy of a conflict

```console
$ git merge theirs
Auto-merging greet.txt
CONFLICT (content): Merge conflict in greet.txt
Automatic merge failed; fix conflicts and then commit the result.
$ cat greet.txt
header
<<<<<<< HEAD
hello there
=======
hello, world
>>>>>>> theirs
middle
filler1
filler2
filler3
filler4
filler5
footer (theirs)
```

Note `footer (theirs)` merged cleanly: only the overlapping hunk conflicts. Between `<<<<<<<` and `=======` is our side, then theirs. While conflicted:

- The index holds three stages for the path (chapter 5: `git ls-files -u`), and `MERGE_HEAD` exists (chapter 6).
- `git diff` shows a **combined diff** (`diff --cc`), one column per parent:

```console
$ git diff
diff --cc greet.txt
index 494a944,5b3d1ab..0000000
--- a/greet.txt
+++ b/greet.txt
@@@ -1,5 -1,5 +1,9 @@@
  header
++<<<<<<< HEAD
 +hello there
++=======
+ hello, world
++>>>>>>> theirs
  middle
  filler1
  filler2
```

- `git diff --ours`/`--theirs`/`--base` compare the work tree against one stage:

```console
$ git diff --ours --stat | tail -1; git diff --theirs --stat | tail -1
 1 file changed, 5 insertions(+), 1 deletion(-)
 1 file changed, 4 insertions(+)
```

- `git log --merge` lists only the commits on either side that touch conflicted paths:

```console
$ git log --merge --oneline
149c187 ours edit
9b6d8a9 theirs edits
```

### Conflict styles

The default style shows only the two sides. `diff3` also shows the base text, which usually makes the intent of both sides clear. You can re-create the markers for a path at any time, even after you edited it (this discards your edits to the file):

```console
$ git checkout --conflict=diff3 greet.txt && sed -n 1,9p greet.txt
Recreated 1 merge conflict
header
<<<<<<< ours
hello there
||||||| base
hello
=======
hello, world
>>>>>>> theirs
middle
$ git checkout --merge greet.txt && sed -n 1,5p greet.txt
Recreated 1 merge conflict
header
<<<<<<< ours
hello there
=======
hello, world
```

Set it permanently with `git config --global merge.conflictStyle diff3`.

> **Version caveat.** `zdiff3` (like `diff3`, but moves lines common to both sides outside the markers) arrived in Git **2.35**. On 2.34.1 it is rejected:
>
> ```console
> $ git -c merge.conflictStyle=zdiff3 merge theirs 2>&1 | head -2
> fatal: unknown style 'zdiff3' given for 'merge.conflictstyle'
> $ git merge-file -p --zdiff3 ours.txt base.txt theirs2.txt 2>&1 | head -3
> error: unknown option `zdiff3'
> usage: git merge-file [<options>] [-L <name1> [-L <orig> [-L <name2>]]] <file1> <orig-file> <file2>
> ```
>
> No newer Git was run for this course, so `zdiff3` is described from its documentation only.

### Resolving and aborting

Edit the file to the final text (remove the markers), `git add` it, then `git commit` (the merge message is pre-filled). Or back out entirely with `git merge --abort`. Below, the first command backs out; the script then runs `git merge theirs` again and writes the resolved text (`hello there, world` … `footer (theirs)`) into `greet.txt` before the second command:

```console
$ git merge --abort && git status -sb
## main
$ git add greet.txt && git commit -m "Merge theirs" && git log --oneline --graph
[main 2d7b6d9] Merge theirs
*   2d7b6d9 Merge theirs
|\  
| * 9b6d8a9 theirs edits
* | 149c187 ours edit
|/  
* ef80bfc greet
* c825fe3 rename
* 56f6028 data
```

Shortcuts for one path: `git checkout --ours -- <path>` / `--theirs` take a whole side. `git mergetool` launches a configured visual tool (`merge.tool`, e.g. `vimdiff`, `meld`) per conflicted file with BASE/LOCAL/REMOTE temporary files and leaves `*.orig` backups (`mergetool.keepBackup`). *Unverified:* `mergetool` is interactive and was not run for this course.

## Strategies and strategy options

`-s <strategy>` picks the whole algorithm, `-X <option>` tunes it. Git 2.34 defaults to **ort** ("Ostensibly Recursive's Twin"; the `Merge made by the 'ort' strategy.` line below confirms it), which replaced `recursive` in 2.34 and is faster and handles renames/directory renames better. `recursive` is still selectable.

| Strategy | Meaning |
|----------|---------|
| `ort` | Default two-head merge; if several merge bases exist, merges them first into a virtual base |
| `recursive` | Previous default, same idea; `-X` options shared |
| `resolve` | Older, three-way only, no rename handling |
| `octopus` | More than two heads; refuses if manual resolution is needed |
| `ours` | Records a merge but keeps **our tree unchanged** |
| `subtree` | Like ort, shifts trees to match a vendored subdirectory |

**`-X ours/theirs` ≠ `-s ours`.** The option resolves only *conflicting hunks* in favor of one side; non-conflicting changes from both sides still merge. The strategy `ours` discards the other side's content entirely:

```console
$ git merge -X ours theirs && cat greet.txt && git reset -q --hard HEAD~1
Auto-merging greet.txt
Merge made by the 'ort' strategy.
 greet.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
header
hello there
middle
filler1
filler2
filler3
filler4
filler5
footer (theirs)
$ git merge -X theirs theirs && sed -n 1,2p greet.txt && git reset -q --hard HEAD~1
Auto-merging greet.txt
Merge made by the 'ort' strategy.
 greet.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
header
hello, world
$ git merge -s ours theirs -m "Merge theirs (ours)" && sed -n 1,2p greet.txt && git reset -q --hard HEAD~1
Merge made by the 'ours' strategy.
header
hello there
```

(Both `-X` runs kept `footer (theirs)`; `-s ours` would have dropped it too. The `git reset --hard HEAD~1` after each undoes the merge commit, safe here because it is unpublished and, as chapter 10 explains, `ORIG_HEAD`/reflog remember it.) `-s ours` is the way to *record* that a branch was merged without taking its content, e.g. to retire an abandoned line of development.

Other `-X` options: `ignore-space-change`, `ignore-all-space`, `renormalize` (re-normalize line endings before merging), `find-renames[=<n>]`, `no-renames`, `patience`, `histogram`, `diff-algorithm=<alg>`, `subtree[=<path>]`.

### Octopus

```console
$ git merge o1 o2 o3 -m "Octopus"
Fast-forwarding to: o1
Trying simple merge with o2
Trying simple merge with o3
Merge made by the 'octopus' strategy.
 o1.txt | 1 +
 o2.txt | 1 +
 o3.txt | 1 +
 3 files changed, 3 insertions(+)
 create mode 100644 o1.txt
 create mode 100644 o2.txt
 create mode 100644 o3.txt
$ git log --oneline --graph -5 | head -8
*-.   84b66ee Octopus
|\ \  
| | * 4854e85 o3
| * | 1ce2ac9 o2
| |/  
* / eca68d5 o1
|/  
* 149c187 ours edit
$ git cat-file -p HEAD | grep -c ^parent
3
```

A merge commit may have any number of parents; the octopus strategy is for tidy topic-branch integration, not conflict resolution.

### Vendoring: `subtree` and `read-tree --prefix`

To bring another project's history under a subdirectory, merge with `--allow-unrelated-histories`. The plumbing way to place its tree under a prefix:

```console
$ git merge -s ours --no-commit --allow-unrelated-histories lib/main 2>&1 | head -2
Automatic merge went well; stopped before committing as requested
$ git read-tree --prefix=vendor/lib/ -u lib/main && git commit -qm "Vendor lib" && ls vendor/lib
lib.c
```

Later updates use `git merge -s subtree lib/main` (or `-X subtree=vendor/lib`). Chapter 14 compares this with submodules and `git subtree`.

## rerere: reuse recorded resolution

With `git config rerere.enabled true`, Git records the preimage (conflicted text) and, when you commit, the postimage (resolved text) under `.git/rr-cache/<hash>/`. The next time the *same* conflict appears (rebase repeated, merge redone, long-lived branch re-merged), it is resolved automatically. Below, the script enables rerere, runs `git merge theirs` (conflict) and writes the resolved text into `greet.txt`; after the commit it undoes the merge with `git reset --hard HEAD~1` and merges again:

```console
$ ls .git/rr-cache | wc -l
1
$ git add greet.txt && git commit -qm "Merge theirs (resolved)"
Recorded resolution for 'greet.txt'.
$ git rerere status; ls .git/rr-cache/*
postimage
preimage
$ git merge theirs
Auto-merging greet.txt
CONFLICT (content): Merge conflict in greet.txt
Resolved 'greet.txt' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
$ git diff --stat; git status -sb | head -3
 greet.txt | Unmerged
 greet.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
## main
UU greet.txt
$ cat greet.txt | sed -n 2p
hello there, world
```

(`git rerere status` printed nothing because no merge was in progress at that point.) The file is resolved on disk but **not staged**: status still says `UU`; review with `git diff`, then `git add` (or set `rerere.autoUpdate=true` to have Git stage rerere's resolutions itself). `git rerere forget <path>` drops a bad recording; `git rerere gc` expires old ones.

## Summary

- Diff algorithms (`myers`, `minimal`, `patience`, `histogram`) give different but equivalent diffs; `histogram` or `patience` often read better.
- Renames and copies are never stored; `-M`/`-C` guess them by similarity (default 50%).
- A merge compares each side with the merge base; overlapping changes conflict. `git merge-file` exposes this at file level.
- During a conflict: stages 1/2/3 in the index, `MERGE_HEAD`, `diff --cc`, `git log --merge`, `checkout --conflict=diff3`.
- `-X ours/theirs` resolves only conflicting hunks; `-s ours` keeps our tree and merely records the merge.
- Default strategy in 2.34 is `ort`; `zdiff3` needs 2.35+.
- `rerere` replays recorded resolutions, leaving them unstaged.

## Exercises

1. Make `git diff` use the `patience` algorithm by default in a repo, and check with `git config`.

   <details><summary>Solution</summary>

   ```console
   $ git config diff.algorithm patience && git config --get diff.algorithm
   patience
   ```

   Drop the setting again with `git config --unset diff.algorithm`.

   </details>

2. Using only `git merge-file`, merge three files where `ours` changes line 2 and `theirs` changes line 4 of a 5-line base, without a conflict.

   <details><summary>Solution</summary>

   ```console
   $ printf 'a\nb\nc\nd\ne\n' > base; printf 'a\nB\nc\nd\ne\n' > o; printf 'a\nb\nc\nD\ne\n' > t
   $ git merge-file -p o base t; echo rc=$?
   a
   B
   c
   D
   e
   rc=0
   ```

   One untouched line (`c`) separates the two edits, so the hunks don't touch. Drop `-p` to write the result into `o` in place.

   </details>

3. After a conflicted merge, show the common ancestor's version of `greet.txt` without leaving the merge.

   <details><summary>Solution</summary>

   ```console
   $ git show :1:greet.txt | head -3
   header
   hello
   middle
   ```

   The base is index stage 1. Alternatively `git checkout --conflict=diff3 greet.txt` and read the `|||||||` section, as shown above.

   </details>

4. What is the difference between `git merge -X theirs topic` and `git merge -s ours topic`?

   <details><summary>Solution</summary>

   `-X theirs` is an option to the normal (`ort`) merge: all non-conflicting changes from both sides are merged, and only *conflicting* hunks are resolved in favour of `topic`. In the transcript it took `hello, world` (the conflicting line) and also kept `footer (theirs)` (a clean change). `-s ours` is a different strategy: the result is exactly our tree, nothing from `topic` is taken (`hello there` stayed and `footer (theirs)` was dropped), but `topic` is recorded as a second parent.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-9--diff-internals-and-merge-mechanics)
