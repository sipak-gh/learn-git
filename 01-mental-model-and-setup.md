# Chapter 1 — Mental Model and Setup

Git is a content-addressed store of snapshots with a thin layer of names and history on top. Get the mental model right and every later command is a variation on a few ideas. This chapter covers snapshots vs. diffs, the three areas, configuration levels, identity, the help system and how the course's examples are produced. Previous: [README](README.md). Next: [Chapter 2 — The Everyday Loop](02-the-everyday-loop.md).

## Snapshots, not diffs

A commit does not store "what changed". It stores a pointer to a complete **tree** (a snapshot of every tracked file) plus a pointer to its parent commit(s). Diffs are computed on demand by comparing two trees. Files that did not change are not copied again: the new tree points at the same **blob** (file content object) as the old one, because objects are named by the hash of their content. [Chapter 4](04-the-object-database.md) shows this byte by byte.

```console
$ git ls-tree HEAD
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	hello.txt
```

That one line is the whole snapshot: mode, object type, object ID, name.

## The three areas

| Area | Also called | Lives in | Holds |
|---|---|---|---|
| Working tree | work dir | your files | what you edit |
| Index | staging area, cache | `.git/index` | the proposed next snapshot |
| Repository | object database | `.git/objects` | all commits, trees, blobs |

`git add` copies content from the working tree to the index. `git commit` turns the index into a tree and a commit. Because you commit the *index*, you can stage a subset of your changes. Short status codes have two columns: left = index vs. `HEAD`, right = working tree vs. index.

```console
$ git status -s
?? hello.txt
$ git add hello.txt && git status -s
A  hello.txt
$ git commit -q -m "first" && git status -s
$ echo "hello, world" > hello.txt
$ git status -s
 M hello.txt
$ git diff --stat
 hello.txt | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git diff --staged --stat
```

(The last command is empty: nothing is staged.) `HEAD` is "the commit you are on"; you will see exactly what it is in [Chapter 6](06-references-and-head.md).

## Configuration levels

Git reads `key=value` settings from four places, later ones overriding earlier ones:

| Scope | File | Flag |
|---|---|---|
| system | `/etc/gitconfig` | `--system` |
| global (user) | `~/.config/git/config`, then `~/.gitconfig` | `--global` |
| local (repo) | `.git/config` | `--local` (default when writing) |
| worktree | `.git/config.worktree` | `--worktree` |

Then `git -c key=value` overrides config for one command. Some environment variables also beat config: `GIT_AUTHOR_NAME` is not a config key, but it overrides `user.name` for the author line. See where each value comes from:

```console
$ git config --global core.editor "vim"
$ git config --show-origin --get user.name
file:/home/you/.gitconfig	Ada Lovelace
$ git config --local user.email "ada@work.example"
$ git config --show-scope --list | grep -v "^local	core"
global	user.name=Ada Lovelace
global	user.email=ada@example.com
global	init.defaultbranch=main
global	advice.detachedhead=false
global	core.editor=vim
local	user.email=ada@work.example
```

`--show-scope` needs Git 2.26+. Section and variable names are case-insensitive (hence the lowercase listing); a subsection, the quoted part as in `[remote "origin"]` or `branch.Main.remote`, is case-sensitive. Minimum first-time setup:

```console
$ git config --global user.name  "Your Name"
$ git config --global user.email "you@example.com"
$ git config --global init.defaultBranch main
```

The identity is recorded in every commit and is **not authentication**; anyone can claim any name. Override per command with `GIT_AUTHOR_NAME`/`GIT_COMMITTER_EMAIL` etc. (environment wins over config), which this course uses to make hashes reproducible.

## Getting help

```console
$ git help -a | head -8
See 'git help <command>' to read about a specific subcommand

Main Porcelain Commands
   add                  Add file contents to the index
   am                   Apply a series of patches from a mailbox
   archive              Create an archive of files from a named tree
   bisect               Use binary search to find the commit that introduced a bug
$ git help -g | head -6

The Git concept guides are:
   attributes          Defining attributes per path
   cli                 Git command-line interface and conventions
   core-tutorial       A Git core tutorial for developers
   credentials         Providing usernames and passwords to Git
```

- `git <cmd> -h` short usage; `git help <cmd>` or `man git-<cmd>` full manual.
- `git help -g` lists guides (`gitrevisions`, `gitglossary`, `gitattributes`, `githooks`, `gitformat-*` …); `git help glossary` defines every term.
- `git help --config` lists all configuration variables (about 800 lines in 2.34).
- **Porcelain** = user-facing commands (`commit`, `rebase`); **plumbing** = scriptable low-level commands (`hash-object`, `update-ref`), stable in output format. Chapters 4–6 use plumbing to show what porcelain does.

## How this course's examples work

Every chapter has `examples/chNN/demo.sh`. It sources `examples/lib.sh`, builds a sandbox repository under `.scratch/` (git-ignored) with a fixed identity, fixed clock and an isolated `HOME`, runs commands and prints them with a `$ ` prompt. The captured result is `examples/chNN/output.txt`; transcripts in the chapters are copied from it. Because identity and dates are fixed, object IDs in the text are reproducible by running the scripts. If you type the commands yourself, your hashes will differ (your name and the time are part of every commit). Home-directory paths in transcripts are shortened to `/home/you`. All output is from Git 2.34.1.

## Summary

- A commit = one snapshot (tree) + parents + metadata; diffs are derived.
- Three areas: working tree → (`add`) → index → (`commit`) → repository.
- Config scopes: system < global < local < worktree < environment/`-c`; inspect with `git config --show-origin --list`.
- `git help <cmd>`, `-h`, `help -g`, `help --config` are your reference.

## Exercises

1. Find which file sets `user.email` for the repository you're in, and its scope, in one command.

   <details><summary>Solution</summary>

   ```console
   $ git config --show-origin --show-scope --get user.email
   local	file:.git/config	ada@work.example
   ```

   (Verified in the sandbox; with both a global and local value, `--get` prints the last one, the highest precedence.)

   </details>

2. Predict the two-column `git status -s` code for a tracked file that you modified, staged, then modified again.

   <details><summary>Solution</summary>

   `MM`: staged change in the left column, further unstaged change in the right. [Chapter 2](02-the-everyday-loop.md) reproduces this with `git add -p`.

   </details>

3. Run a single command with a different author name without touching any config file.

   <details><summary>Solution</summary>

   ```console
   $ git -c user.name="Grace Hopper" commit --allow-empty -m "as grace" -q
   $ git log -1 --format=%an
   Grace Hopper
   ```

   Note: if `GIT_AUTHOR_NAME` is set in the environment (as in the demo scripts) it wins over `-c user.name`.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-1--mental-model-and-setup)
