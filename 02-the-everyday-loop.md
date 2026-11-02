# Chapter 2 — The Everyday Loop

Ninety percent of daily Git is: look at what changed, stage the right pieces, commit, look at history, undo a mistake. This chapter covers `init`/`clone`, `status`, `add -p`, `commit`, the diff variants, `log` basics, `.gitignore`, `rm`/`mv`, and `restore`/`switch`. It is deliberately brief; later chapters explain how each command works inside. Previous: [Chapter 1 — Mental Model and Setup](01-mental-model-and-setup.md). Next: [Chapter 3 — Branches, Merging and Remotes in Brief](03-branches-merging-remotes-brief.md).

Examples: `examples/ch02/demo.sh`.

## Starting a repository

`git init` creates `.git/` in the current directory; `git clone URL [dir]` copies a repository, its whole history, and sets up `origin`.

```console
$ git init -q notes && cd notes
$ git status
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

## Ignoring files

Patterns in `.gitignore` (committed, shared) hide untracked files from `status` and `add`. Personal patterns go in `.git/info/exclude` or `core.excludesFile`. Ignoring never affects files *already tracked*.

```console
$ git status -s
?? .gitignore
?? todo.txt
$ git status --ignored -s
?? .gitignore
?? todo.txt
!! build/
!! run.log
$ git check-ignore -v run.log
.gitignore:2:*.log	run.log
```

`check-ignore -v` prints `file:line:pattern` — the fastest way to debug "why is this ignored?". A trailing `/` matches directories only; `!pattern` re-includes; `**/` matches any depth. The last matching line wins, but `!` cannot rescue a file whose *directory* is excluded, since Git never looks inside it: `build/` plus `!build/keep.txt` still ignores `keep.txt`, while `build/*` plus `!build/keep.txt` works. Git cannot track empty directories (convention: a `.gitkeep` file).

## Staging and committing

```console
$ git add todo.txt .gitignore && git commit -m "Add todo list"
[main (root-commit) 2916930] Add todo list
 2 files changed, 14 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 todo.txt
```

`git commit -a` stages all changes to *tracked* files first (not new files). `git commit -m` is fine for one-liners; without it your editor opens (`core.editor`, `GIT_EDITOR`). Convention: a ≤50-character subject, blank line, body wrapped at ~72 explaining *why* ([Chapter 16](16-collaboration-and-patches.md)).

### Partial staging with `add -p`

Edit two distant places in one file, then stage only one hunk. Git splits changes into hunks (separated by more than 6 unchanged lines, given 3 lines of context); you answer `y` (stage), `n` (skip), `s` (split), `e` (edit the patch by hand), `q`, `?`.

```console
$ git diff
diff --git a/todo.txt b/todo.txt
index 3545a88..40fa3ef 100644
--- a/todo.txt
+++ b/todo.txt
@@ -1,4 +1,4 @@
-buy milk
+buy oat milk
 task 2
 task 3
 task 4
@@ -9,4 +9,4 @@ task 8
 task 9
 task 10
 task 11
-sleep
+sleep early
$ printf "y\nn\n" | git add -p
diff --git a/todo.txt b/todo.txt
index 3545a88..40fa3ef 100644
--- a/todo.txt
+++ b/todo.txt
@@ -1,4 +1,4 @@
-buy milk
+buy oat milk
 task 2
 task 3
 task 4
(1/2) Stage this hunk [y,n,q,a,d,j,J,g,/,e,?]? @@ -9,4 +9,4 @@ task 8
 task 9
 task 10
 task 11
-sleep
+sleep early
(2/2) Stage this hunk [y,n,q,a,d,K,g,/,e,?]?
$ git status -s
MM todo.txt
```

`MM` = modified in the index *and* modified again in the working tree. (The answers come from the pipe, so they are not echoed after the prompts.) The two diffs show the split:

```console
$ git diff --staged
diff --git a/todo.txt b/todo.txt
index 3545a88..b740218 100644
--- a/todo.txt
+++ b/todo.txt
@@ -1,4 +1,4 @@
-buy milk
+buy oat milk
 task 2
 task 3
 task 4
$ git diff
diff --git a/todo.txt b/todo.txt
index b740218..40fa3ef 100644
--- a/todo.txt
+++ b/todo.txt
@@ -9,4 +9,4 @@ task 8
 task 9
 task 10
 task 11
-sleep
+sleep early
$ git diff HEAD --stat
 todo.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```

| Command | Compares |
|---|---|
| `git diff` | working tree ↔ index (unstaged) |
| `git diff --staged` (`--cached`) | index ↔ `HEAD` (what `commit` will record) |
| `git diff HEAD` | working tree ↔ `HEAD` (everything) |
| `git diff A B` / `A..B` | two commits |
| `--stat`, `--name-only`, `--name-status`, `--check` | summaries; `--check` flags whitespace errors |

Now commit the staged hunk, then the rest with `-a`:

```console
$ git commit -q -m "Oat milk" && git commit -qam "Sleep early" && git log --oneline --stat
1ab2fd7 Sleep early
 todo.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
7f7e135 Oat milk
 todo.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
2916930 Add todo list
 .gitignore |  2 ++
 todo.txt   | 12 ++++++++++++
 2 files changed, 14 insertions(+)
```

Two focused commits instead of one mixed one; this is the point of the index.

## Looking at history

Basics (the full tour is [Chapter 8](08-reading-and-searching-history.md)): `git log --oneline`, `--stat`, `-p`, `-n N`, `--format=...`, `git show <commit>`.

```console
$ git log --oneline -n 2 --format="%h %an %ad %s" --date=short
1ab2fd7 Ada Lovelace 2024-01-01 Sleep early
7f7e135 Ada Lovelace 2024-01-01 Oat milk
$ git show --stat HEAD
commit 1ab2fd792cb42635a4634ca2a507ee40f7613063
Author: Ada Lovelace <ada@example.com>
Date:   Mon Jan 1 01:00:00 2024 +0000

    Sleep early

 todo.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

## Removing, renaming

Git does not record renames; it *detects* them by similarity when comparing snapshots ([Chapter 9](09-diff-and-merge-internals.md)). `git mv a b` is just `mv` + `git add`.

```console
$ git mv todo.txt tasks.txt && git status -s
R  todo.txt -> tasks.txt
$ git rm --cached tasks.txt && git status -s
rm 'tasks.txt'
D  todo.txt
?? tasks.txt
$ git add tasks.txt && git rm -f tasks.txt && git status -s
rm 'tasks.txt'
D  todo.txt
```

`git rm --cached` untracks but keeps the file on disk; plain `git rm` deletes it too and refuses if it has unsaved changes unless `-f`.

## Undoing with `restore` and `switch`

Git 2.23 split the overloaded `checkout` into `switch` (branches) and `restore` (files). `git restore <path>` takes the file *from the index*; `--source=<rev>` takes it from a commit; `--staged` targets the index, `--worktree` (default) the working tree.

```console
$ git restore --source=HEAD --staged --worktree todo.txt; git status -s; ls
build
run.log
todo.txt
$ git add todo.txt && git restore --staged todo.txt && git status -s
 M todo.txt
$ git restore todo.txt && git status -s
$ git switch -c feature && git branch --show-current
Switched to a new branch 'feature'
feature
```

(After the first command `status` printed nothing: clean.) `git restore <path>` **destroys** uncommitted work in that file with no undo; `restore --staged` is safe because the content stays in your working tree.

## Cloning

```console
$ git clone -q notes notes-copy && git -C notes-copy log --oneline | head -3
1ab2fd7 Sleep early
7f7e135 Oat milk
2916930 Add todo list
$ git -C notes-copy remote -v
origin	/home/you/notes (fetch)
origin	/home/you/notes (push)
```

A path is a valid URL, which makes local experiments easy. `-C <dir>` runs a command as if started in `<dir>`.

## Summary

- `status -s` → `diff` / `diff --staged` → `add` (`-p` for hunks) → `commit` → `log`.
- Three diffs: worktree↔index, index↔HEAD, worktree↔HEAD.
- `.gitignore` only affects untracked files; `check-ignore -v` explains.
- `restore --staged` unstages; `restore <path>` discards; `switch` changes branches.

## Exercises

1. Stage only the second hunk of a two-hunk change using non-interactive input.

   <details><summary>Solution</summary>

   Answer `n` then `y`:

   ```console
   $ printf "n\ny\n" | git add -p >/dev/null; git diff --staged --stat
    todo.txt | 2 +-
    1 file changed, 1 insertion(+), 1 deletion(-)
   $ git diff --staged | grep '^[-+]sleep'
   -sleep
   +sleep early
   ```

   </details>

2. You staged `secret.txt` by mistake before the first commit of a repo. Unstage it without deleting the file.

   <details><summary>Solution</summary>

   ```console
   $ git restore --staged secret.txt
   fatal: could not resolve HEAD
   $ git rm --cached secret.txt
   rm 'secret.txt'
   $ git status -s
   ?? secret.txt
   ```

   Before the first commit there is no `HEAD` to restore from, so `restore --staged` fails; `git rm --cached` removes the index entry. In a repo that already has commits, `git restore --staged secret.txt` is the idiom.

   </details>

3. Why does `git diff` print nothing right after `git add file`, and which command shows the change?

   <details><summary>Solution</summary>

   `git diff` compares worktree to index, and they now match. `git diff --staged` shows index vs. `HEAD`.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-2--the-everyday-loop)
