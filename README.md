# Learn Git: From the Everyday Loop to the Object Database

This course teaches Git in two steps. Chapters 1–3 cover the basics briefly: the loop you use every day, branches, merges and remotes. Chapters 4–14 then dig into how everything works: objects, the index, references, revisions, diffs and merges, history rewriting, packfiles, transports, submodules and large repositories. Chapters 15–18 cover hooks and configuration, patch-based collaboration, recovery and debugging, and finish by writing a small Git in Python.

Every command transcript is **real output**. Each chapter has a runnable script in `examples/chNN/demo.sh` that builds a scratch repository with a fixed identity and fixed dates, and the output you read in the chapter is the output that script produced (saved next to it as `output.txt`). In the end you write `minigit.py`, which writes objects that real Git accepts:

```console
$ python3 examples/ch18/minigit.py commit 'first commit'
ff16743be7175299bdc9d39552c5a12f86923322
$ git fsck --strict; echo rc=$?
rc=0
```

## Who it is for

A Linux user who knows basic shell (files, pipes, a text editor) and wants to understand Git, not memorize it. No prior Git knowledge is assumed, but the first three chapters move quickly.

## Requirements

| Tool | Version |
|------|---------|
| Git | 2.34.1 (Ubuntu 22.04); anything newer behaves the same for what is shown, except where a chapter says otherwise |
| bash, coreutils | any recent version |
| Python 3 | 3.8 or newer (Chapter 18, and one hook example) |
| gpg, ssh-keygen | for the signing section of Chapter 16 (an OpenSSH 8.x `ssh-keygen` for SSH signatures; 8.9p1 was used) |
| xxd | Chapter 13 (hex dumps of pack files) |

Installation is not covered. Some chapters mention features newer than 2.34.1 (`zdiff3`, `rebase --update-refs`, `push.autoSetupRemote`, reftable); the course states when each one was **not** available to run, and does not show output for them. A few things are described from the documentation only and are labelled *unverified* in the text: SSH and HTTPS transports (all remotes in the course are local paths or `file://` URLs), `git send-email`, `git filter-repo`, Git LFS, `git mergetool`, the `git maintenance start` scheduler and repairing corrupted packs. Version-dependent defaults and edge cases that are easy to get wrong were tested on 2.34.1, sometimes outside the demo scripts (the text says so): reflog expiry (90/30 days), `gc.auto` (6700), the 2-week prune grace period, `bisect run` exit codes, `revert -m`, `--force-if-includes`, the `ident` attribute, `diff.<driver>.cachetextconv`, the sparse index, and the absence of `includeIf "hasconfig:…"` (2.36) and `sparse-checkout set --cone` (2.35).

## How to use this course

- **Read in order.** Each chapter uses only what earlier chapters taught; Chapters 4–14 are the deepest.
- **Run the scripts.** `bash examples/chNN/demo.sh` rebuilds the scratch repository under `.scratch/` and prints the transcript. Your own `~/.gitconfig` is not used (the scripts set an isolated `HOME`). Hashes are reproducible if you run the scripts unchanged on the same Git version, except for signed commits in Chapter 16 (each run creates new keys) and exercises that use random data; paths in the chapters are shortened to `/home/you`.
- **Poke at it.** The scratch repositories stay in `.scratch/chNN/work/`; `cd` into one and run your own commands.
- **Exercises** end each chapter. Their solutions are hidden in collapsible blocks, and were run unless the text says otherwise. `examples/chNN/exercises.sh` exists for the chapters where the solutions were scripted.

## Table of contents

**Part I: The Basics, Briefly**

| # | Chapter | Topics |
|---|---------|--------|
| 1 | [Mental Model and Setup](01-mental-model-and-setup.md) | snapshots not diffs, working tree / index / repository, config levels, identity, help |
| 2 | [The Everyday Loop](02-the-everyday-loop.md) | init, clone, status, `add -p`, commit, diff variants, log, `.gitignore`, rm/mv, restore/switch |
| 3 | [Branches, Merging and Remotes in Brief](03-branches-merging-remotes-brief.md) | branch, switch, fast-forward vs merge commit, `merge --squash`, fetch/pull/push |

**Part II: How Git Works**

| # | Chapter | Topics |
|---|---------|--------|
| 4 | [The Object Database](04-the-object-database.md) | blob/tree/commit/tag, `hash-object`, `cat-file`, building a commit with plumbing, SHA-1 and SHA-256 |
| 5 | [The Index](05-the-index.md) | `ls-files`, `update-index`, conflict stages, intent-to-add, `add -p` internals, racy Git |
| 6 | [References and HEAD](06-references-and-head.md) | `refs/`, `packed-refs`, symbolic refs, detached HEAD, reflog, special refs, tag kinds |
| 7 | [Revisions and Ranges](07-revisions-and-ranges.md) | `^ ~ @{} :/`, `A..B` vs `A...B`, `rev-list`, `rev-parse`, repository discovery, `merge-base`, `--first-parent` |
| 8 | [Reading and Searching History](08-reading-and-searching-history.md) | log formats and graph, `-S`/`-G`, `-L`, blame, shortlog, describe, bisect, grep, range-diff |
| 9 | [Diff Internals and Merge Mechanics](09-diff-and-merge-internals.md) | diff algorithms, word diff, renames, three-way merge, strategies, conflict styles, rerere, `merge-file` |
| 10 | [Rewriting History](10-rewriting-history.md) | amend, reset (incl. `--keep`/`--merge`), revert, cherry-pick, rebase (interactive, `--onto`, `--rebase-merges`, `--exec`), reflog recovery, filter-branch, replace, fast-export/fast-import |
| 11 | [Stash, Worktrees and Cleaning](11-stash-worktrees-and-cleaning.md) | stash variants, `restore --source`, `clean`, linked worktrees |
| 12 | [Remotes in Depth](12-remotes-in-depth.md) | refspecs, tracking branches, fetch/pull/push semantics, upstream, `--force-with-lease`, prune, forks, credential helpers |
| 13 | [Transport and Packfiles](13-transport-and-packfiles.md) | loose vs packed, delta compression, idx, gc/repack/prune, fsck, bundles, shallow and partial clones, protocol v2, maintenance |
| 14 | [Submodules, Subtrees and Large Repos](14-submodules-subtrees-large-repos.md) | submodule workflow and pitfalls, subtree, sparse-checkout, LFS |

**Part III: Working With Git**

| # | Chapter | Topics |
|---|---------|--------|
| 15 | [Hooks, Attributes and Config](15-hooks-attributes-and-config.md) | hooks, `.gitattributes` (eol, drivers, filters, export-ignore), config includes, aliases, ignore precedence, `safe.directory` |
| 16 | [Collaboration and Patches](16-collaboration-and-patches.md) | `format-patch`/`am`/`apply`, pull requests, branching models, commit messages, notes, `archive`, GPG and SSH signing |
| 17 | [Debugging and Recovery](17-debugging-and-recovery.md) | reflog, `fsck --lost-found`, dangling objects, corruption, `bisect run`, `GIT_TRACE*` |
| 18 | [Mini-Git and Where Next](18-mini-git-and-where-next.md) | a Python script that writes real objects, index and refs; further reading |

**Appendices:** [A: Cheat Sheet](appendix-a-cheatsheet.md) ·
[B: Plumbing and File Formats](appendix-b-plumbing-and-file-formats.md)

References: [REFERENCES.md](REFERENCES.md) lists the sources behind each chapter, with archived
(Wayback Machine) copies of every link.

## Repository layout

```text
learn-git/
├── README.md, REFERENCES.md
├── NN-name.md                 chapters 01–18
├── appendix-a-cheatsheet.md, appendix-b-plumbing-and-file-formats.md
├── examples/
│   ├── lib.sh                 shared helpers: isolated HOME, fixed identity and dates
│   ├── chNN/demo.sh           builds the scratch repo and prints the transcript
│   ├── chNN/output.txt        the captured output pasted into the chapter
│   ├── chNN/exercises.sh      scripted exercise solutions (some chapters)
│   └── ch18/minigit.py        the mini-Git
└── .scratch/                  created by the scripts; git-ignored
```
