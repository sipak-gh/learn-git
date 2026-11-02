# Chapter 8 — Reading and Searching History

Version control is mostly *reading*: who changed this, when did it break, where did this code come from. This chapter covers `log` formats and filters, the pickaxe (`-S`, `-G`), line history (`-L`), `blame` with `-w -M -C` and ignore-revs, `shortlog`, `describe`, `grep`, `bisect` (including `bisect run`) and `range-diff`. Previous: [Chapter 7 — Revisions and Ranges](07-revisions-and-ranges.md). Next: [Chapter 9 — Diff Internals and Merge Mechanics](09-diff-and-merge-internals.md).

Examples: `examples/ch08/demo.sh` (history of a small `calc.py`, two authors, one tag `v0.1`).

## `log`: choosing what and how

```console
$ git log --oneline
cced086 Rename calc to mathlib
586e8bb Move mul to the end
02041a6 Use ValueError
4e64243 Add div with zero check
7f3be6a Tighten sub
d19fa8c Add mul
74aa84f Add add and sub
$ git log --format="%h %an <%ae> %ad %s" --date=short -3
cced086 Grace Hopper <grace@example.com> 2024-01-01 Rename calc to mathlib
586e8bb Grace Hopper <grace@example.com> 2024-01-01 Move mul to the end
02041a6 Grace Hopper <grace@example.com> 2024-01-01 Use ValueError
$ git log --stat --format="--- %h %s" -2
--- cced086 Rename calc to mathlib

 calc.py => mathlib.py | 0
 1 file changed, 0 insertions(+), 0 deletions(-)
--- 586e8bb Move mul to the end

 calc.py | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)
$ git log --name-status --format=%s -3
Rename calc to mathlib

R100	calc.py	mathlib.py
Move mul to the end

M	calc.py
Use ValueError

M	calc.py
```

Presentation: `--oneline`, `--graph`, `--decorate`, `--all`, `--stat`, `--name-status`, `-p`, `--format=<placeholders>` (`%H %h` hash, `%an %ae` author, `%cn` committer, `%ad %ar` author date/relative, `%s` subject, `%b` body, `%d` refs, `%m` side marker, `%C(...)` colour). Built-in `--pretty` names: `oneline`, `short`, `medium` (default), `full`, `fuller`, `reference`, `email`, `raw`; save your own as `pretty.<name>` in config. Filtering: `--author=`, `--committer=`, `--grep=` (message; `-i`, `-E`, `--all-match`, `--invert-grep`), `--since/--until`, `-n`, `--diff-filter=ACDMRT`, `--no-merges`, and `-- path`. `--follow -- file` follows a single file across renames.

```console
$ git log --author=Grace --format=%s
Rename calc to mathlib
Move mul to the end
Use ValueError
Add mul
$ git log --grep="^Add" --format=%s
Add div with zero check
Add mul
Add add and sub
$ git log --grep=valueerror -i --format=%s
Use ValueError
```

## Pickaxe: `-S` and `-G`

Searching *messages* is `--grep`; searching *content changes* is the pickaxe. `-S<string>` lists commits that change the **number of occurrences** of the string (added or removed it). `-G<regex>` lists commits whose diff has an added or removed **line matching** the regex. `--pickaxe-regex` makes `-S` a regex; `--pickaxe-all` shows the whole changeset instead of only matching files.

```console
$ git log -S"ZeroDivisionError" --oneline
02041a6 Use ValueError
4e64243 Add div with zero check
$ git log -S"b is zero" --oneline
4e64243 Add div with zero check
$ git log -G"b is zero" --oneline
02041a6 Use ValueError
4e64243 Add div with zero check
$ git log -G"a ?- ?b" --oneline
7f3be6a Tighten sub
74aa84f Add add and sub
```

`Use ValueError` rewrote the line that contains `"b is zero"` but left one occurrence, so `-S` skips it and `-G` finds it. Use `-S` for "when did this identifier appear/vanish", `-G` for "who touched lines like this".

## Line history: `-L`

`git log -L<start>,<end>:file` or `-L:<funcname>:file` shows the history of a line range or function as a series of patches, following the code through edits:

```console
$ git log -L:sub:mathlib.py --format="--- %h %s"
--- 7f3be6a Tighten sub

diff --git a/calc.py b/calc.py
--- a/calc.py
+++ b/calc.py
@@ -4,3 +4,3 @@
 def sub(a, b):
-    return a - b
+    return a-b
 
--- d19fa8c Add mul

diff --git a/calc.py b/calc.py
--- a/calc.py
+++ b/calc.py
@@ -4,2 +4,3 @@
 def sub(a, b):
     return a - b
+
--- 74aa84f Add add and sub

diff --git a/calc.py b/calc.py
--- /dev/null
+++ b/calc.py
@@ -0,0 +4,2 @@
+def sub(a, b):
+    return a - b
```

It followed the rename (`calc.py` → `mathlib.py`) automatically. The function boundary comes from the `diff=<lang>` funcname pattern ([Chapter 15](15-hooks-attributes-and-config.md)); without one, a default heuristic (a line starting with a letter, `$` or `_`) is used.

## `blame`

`git blame file` prints, for each line, the commit that last changed it. `^` marks boundary commits (the first commit in the history walked).

```console
$ git blame mathlib.py
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000  1) def add(a, b):
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000  2)     return a + b
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000  3) 
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000  4) def sub(a, b):
7f3be6a4 calc.py (Ada Lovelace 2024-01-01 04:00:00 +0000  5)     return a-b
d19fa8c3 calc.py (Grace Hopper 2024-01-01 03:00:00 +0000  6) 
4e64243c calc.py (Ada Lovelace 2024-01-01 05:00:00 +0000  7) def div(a, b):
4e64243c calc.py (Ada Lovelace 2024-01-01 05:00:00 +0000  8)     if b == 0:
02041a6e calc.py (Grace Hopper 2024-01-01 06:00:00 +0000  9)         raise ValueError("b is zero")
4e64243c calc.py (Ada Lovelace 2024-01-01 05:00:00 +0000 10)     return a / b
586e8bb8 calc.py (Grace Hopper 2024-01-01 07:00:00 +0000 11) 
586e8bb8 calc.py (Grace Hopper 2024-01-01 07:00:00 +0000 12) def mul(a, b):
586e8bb8 calc.py (Grace Hopper 2024-01-01 07:00:00 +0000 13)     """Multiply two numbers together and return the product."""
586e8bb8 calc.py (Grace Hopper 2024-01-01 07:00:00 +0000 14)     return a * b
```

The file-name column (`calc.py`) appears because the file was renamed. Useful options: `-L start,end` or `-L :func`, `-e` (emails), `--porcelain` / `--line-porcelain` (machine-readable: author, times, summary, filename), `-s` (suppress names/dates), and `<rev> -- file` to blame from an older revision. Blame says who *last touched* a line, not who *wrote* it; these options fix the commonest distortions:

- **`-w`** ignores whitespace changes.
- **`-M`** detects lines moved *within* a file; **`-C`** detects lines moved or copied *from other files modified in the same commit* (`-C -C`: also from the commit that created the file; `-C -C -C`: from any commit).
- **`--ignore-rev <rev>`**, `--ignore-revs-file <file>` (or config `blame.ignoreRevsFile`) skip mechanical reformatting commits.

```console
$ git blame -L 1,2 mathlib.py
^74aa84f calc.py    (Ada Lovelace 2024-01-01 02:00:00 +0000 1) def add(a, b):
a80b18cd mathlib.py (Grace Hopper 2024-01-01 09:00:00 +0000 2)         return a + b
$ git blame -w -L 1,2 mathlib.py
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000 1) def add(a, b):
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000 2)         return a + b
$ echo "$IND # indent only" > .git-blame-ignore-revs; git blame --ignore-revs-file .git-blame-ignore-revs -L 1,2 mathlib.py
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000 1) def add(a, b):
^74aa84f calc.py (Ada Lovelace 2024-01-01 02:00:00 +0000 2)         return a + b
```

(`$IND` is the full ID of the indent-only commit, set by the demo.) After moving `mul` to a new file `extra.py`:

```console
$ git blame -L 3,5 extra.py
18a4e3d6 (Grace Hopper 2024-01-01 10:00:00 +0000 3) def mul(a, b):
18a4e3d6 (Grace Hopper 2024-01-01 10:00:00 +0000 4)     """Multiply two numbers together and return the product."""
18a4e3d6 (Grace Hopper 2024-01-01 10:00:00 +0000 5)     return a * b
$ git blame -C -L 3,5 extra.py
d19fa8c3 calc.py (Grace Hopper 2024-01-01 03:00:00 +0000 3) def mul(a, b):
```

(The `-C` command prints three lines, all credited to `d19fa8c3`; only the first is shown here.) With `-C` the lines are credited to the commit that originally wrote them and the file they came from. The detection threshold is a minimum number of alphanumeric characters (40 by default for `-C`), so tiny moved snippets are not detected; that is why the demo's `mul` has a docstring.

## `shortlog`, `describe`, `grep`

`shortlog` summarizes by author. Give it a revision: with no revision and no terminal on stdin it reads stdin and prints nothing useful.

```console
$ git shortlog -sn HEAD
     4	Grace Hopper
     3	Ada Lovelace
$ git shortlog -sne HEAD
     4	Grace Hopper <grace@example.com>
     3	Ada Lovelace <ada@example.com>
$ git shortlog -n HEAD
Grace Hopper (4):
      Add mul
      Use ValueError
      Move mul to the end
      Rename calc to mathlib

Ada Lovelace (3):
      Add add and sub
      Tighten sub
      Add div with zero check

$ git describe --tags
v0.1-6-gcced086
```

`.mailmap` merges identities. `describe` ([Chapter 6](06-references-and-head.md)) answers "which release is this commit after?"; `git describe --contains <commit>` answers "which tag first contains it?".

`git grep` searches tracked files (or any revision) quickly: `-n` line numbers, `-c` counts, `-e A --or -e B`, `--and`, `-p` (show enclosing function), `--untracked`, and a `<rev>` to search a historical snapshot:

```console
$ git grep -n "def " -- "*.py"
mathlib.py:1:def add(a, b):
mathlib.py:4:def sub(a, b):
mathlib.py:7:def div(a, b):
mathlib.py:12:def mul(a, b):
$ git grep -c "return"
mathlib.py:5
$ git grep -n -e "ValueError" --or -e "Multiply"
mathlib.py:9:        raise ValueError("b is zero")
mathlib.py:13:    """Multiply two numbers together and return the product."""
$ git grep -n "return a + b" HEAD~3
HEAD~3:calc.py:2:    return a + b
```

## `bisect`: binary search for a regression

`git bisect` checks out the midpoint between a known-good and a known-bad commit and asks you (or a script) whether it is good. N commits need about log₂ N steps. The demo has 12 commits; the file `state` turns `broken` at commit 8; `../test.sh` exits 0 when `state` is `fine`.

```console
$ git bisect start HEAD good
Bisecting: 5 revisions left to test after this (roughly 3 steps)
[3f731e4c0f0310a688d74e64367dd3a47c12c117] commit 6
$ git bisect run ../test.sh
running  '../test.sh'
Bisecting: 2 revisions left to test after this (roughly 2 steps)
[1d543f171658316d39ab6bd2f1ed7f1c4f2a99f3] commit 9
running  '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 1 step)
[ebb2836da94accc2a4a67b41fb09ab2b1926263e] commit 8
running  '../test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[5b22b513464bc531a463162cf02651b36eaf58b6] commit 7
running  '../test.sh'
ebb2836da94accc2a4a67b41fb09ab2b1926263e is the first bad commit
commit ebb2836da94accc2a4a67b41fb09ab2b1926263e
Author: Grace Hopper <grace@example.com>
Date:   Mon Jan 1 18:00:00 2024 +0000

    commit 8

 n     | 2 +-
 state | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
bisect found first bad commit
$ git bisect log | head -6
# bad: [20b5358744dd2fa681b7b0bf944eb48d9b1f89d6] commit 12
# good: [ecbf00ab0173a2aaa2f06699bf3116ec869229e1] commit 1
git bisect start 'HEAD' 'good'
# good: [3f731e4c0f0310a688d74e64367dd3a47c12c117] commit 6
git bisect good 3f731e4c0f0310a688d74e64367dd3a47c12c117
# bad: [1d543f171658316d39ab6bd2f1ed7f1c4f2a99f3] commit 9
$ git bisect reset
Previous HEAD position was 5b22b51 commit 7
Switched to branch 'main'
```

The script's exit code decides: `0` good, `1`–`127` (except `125`) bad, `125` = "cannot test this commit, skip", ≥128 aborts the run. Manually, answer `git bisect good` / `bad` / `skip` after each checkout; `git bisect log > file` and `git bisect replay file` save and restore a session; `git bisect reset` returns to your branch (always run it). `--first-parent` bisects along the mainline only; `--term-old`/`--term-new` rename the labels for searches that are not bugs.

## `range-diff`: compare two versions of a patch series

After rebasing or editing a series, `git range-diff <base> <old> <new>` pairs commits by similarity and shows what changed *between versions*; it is the tool for "what did you change since the last review round?". Here `v2` is `topic` re-applied on a newer `main`, with an extra line in the second commit:

```console
$ git range-diff main topic v2
1:  3dce87b = 1:  ed61e2b Add g1
2:  9fb376a ! 2:  e5b3986 Add g2
    @@ g2 (new)
     +4
     +5
     +6
    ++extra
3:  6dd4604 = 3:  e6bbf2a Add g3
```

`=` unchanged patch, `!` changed (with an inner diff), `<` dropped, `>` added. It also accepts `A...B` for two ranges sharing a base (`git range-diff topic@{1}...topic` after a rebase compares the old and new series; the two-argument form takes two *ranges*, so `topic@{1} topic` fails with `fatal: not a commit range`).

## Summary

- `log` = what (revisions, paths, authors, grep) plus how (`--format`, `--graph`, `-p`, `--stat`).
- `-S` finds changes in occurrence count; `-G` changes to matching lines; `-L` follows a function or range; `--follow` follows a file.
- `blame -w -M -C` and ignore-revs remove reformat and move noise.
- `bisect run` automates regression hunting with a test script; `range-diff` compares series versions.

## Exercises

1. Which commit removed the string `ZeroDivisionError` from the code base?

   <details><summary>Solution</summary>

   ```console
   $ git log -S"ZeroDivisionError" --oneline
   02041a6 Use ValueError
   4e64243 Add div with zero check
   ```

   Both change the occurrence count; the *newest* listed is the one that removed it (`02041a6`), the oldest introduced it.

   </details>

2. Find the first bad commit automatically if the bug is "file `state` doesn't equal `fine`".

   <details><summary>Solution</summary>

   Write a test script that exits 0 when the content is right, then `git bisect start <bad> <good>` and `git bisect run ./test.sh`. In the demo it identified commit 8 (`ebb2836`) in four test runs (above). Use exit code 125 for commits that can't be built or tested.

   </details>

3. Make `blame` skip a mass-reformatting commit for everyone who uses the repository.

   <details><summary>Solution</summary>

   Commit a `.git-blame-ignore-revs` file listing full IDs (one per line, `#` comments allowed) and have each clone run `git config blame.ignoreRevsFile .git-blame-ignore-revs` (the file travels with the repository, the config does not). The effect is shown above with `--ignore-revs-file`.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-8--reading-and-searching-history)
