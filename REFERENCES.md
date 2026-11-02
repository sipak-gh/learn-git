# References

This file lists the sources behind the facts in this course: command behavior, on-disk formats, protocols and version differences. Use it to check a claim or to read further. The `git-scm.com/docs` pages track the **latest** Git release, while the course was run on Git 2.34.1; where a chapter says a feature needs a newer version, the manual page is still the place to read about it.

Each source has two links: **original** (the live page) and **archived** (a snapshot in the Internet Archive's [Wayback Machine](https://web.archive.org/), in case the original moves or changes). Program output shown in the chapters comes from running the course's own scripts in `examples/` and isn't listed here. Claims the chapters mark as untested (for example SSH/HTTPS transports, `git send-email`, `git filter-repo`, Git LFS) rest only on the sources below.

## Primary references

Bookmark these; most entries below point into them.

- **Pro Git (2nd edition)** — Scott Chacon and Ben Straub's book, free online; the narrative companion to this course. [original](https://git-scm.com/book/en/v2) · [archived](https://web.archive.org/web/20261031192232/https://git-scm.com/book/en/v2)
- **Git reference manual** — every command's manual page, plus the format and protocol pages. [original](https://git-scm.com/docs) · [archived](https://web.archive.org/web/20261022180932/https://git-scm.com/docs)
- **gitglossary** — the definitions of Git's terms (object, ref, index, tree-ish, …). [original](https://git-scm.com/docs/gitglossary) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitglossary)
- **gitrevisions** — the full revision and range syntax. [original](https://git-scm.com/docs/gitrevisions) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitrevisions)
- **gitattributes** — per-path attributes: eol, diff, merge, filter, export-ignore. [original](https://git-scm.com/docs/gitattributes) · [archived](https://web.archive.org/web/20261022041707/https://git-scm.com/docs/gitattributes)
- **githooks** — every hook, when it runs and what its exit status means. [original](https://git-scm.com/docs/githooks) · [archived](https://web.archive.org/web/20261022045345/https://git-scm.com/docs/githooks)
- **git(1)** — the top-level page, including the environment variables (`GIT_DIR`, `GIT_TRACE*`, …). [original](https://git-scm.com/docs/git) · [archived](https://web.archive.org/web/20261021064424/https://git-scm.com/docs/git)
- **giteveryday** — a short list of the commands most people use. [original](https://git-scm.com/docs/giteveryday) · [archived](https://web.archive.org/web/20261021075411/https://git-scm.com/docs/giteveryday)
- **Git release notes** — the per-release `RelNotes` in the Git source tree, for checking when a feature appeared. [original](https://github.com/git/git/tree/master/Documentation/RelNotes) · [archived](https://web.archive.org/web/20260423064754/https://github.com/git/git/tree/master/Documentation/RelNotes)

## Chapter 1 — Mental Model and Setup

Chapter file: [01-mental-model-and-setup.md](01-mental-model-and-setup.md)

- **Pro Git: What is Git?** — snapshots versus deltas, the three states. [original](https://git-scm.com/book/en/v2/Getting-Started-What-is-Git%3F) · [archived](https://web.archive.org/web/20261016013327/https://git-scm.com/book/en/v2/Getting-Started-What-is-Git%3F)
- **Pro Git: First-Time Git Setup** — identity, editor, config levels. [original](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup) · [archived](https://web.archive.org/web/20261028212709/https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup)
- **git-config** — config files, levels, precedence, `--show-origin`. [original](https://git-scm.com/docs/git-config) · [archived](https://web.archive.org/web/20261021064424/https://git-scm.com/docs/git-config)
- **git-help** — the help system (`man`, `-h`, `--guides`). [original](https://git-scm.com/docs/git-help) · [archived](https://web.archive.org/web/20261021064424/https://git-scm.com/docs/git-help)
- **gitglossary** — terms used throughout. [original](https://git-scm.com/docs/gitglossary) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitglossary)
- **gitcli** — command-line conventions (`--`, options, revisions versus paths). [original](https://git-scm.com/docs/gitcli) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitcli)

## Chapter 2 — The Everyday Loop

Chapter file: [02-the-everyday-loop.md](02-the-everyday-loop.md)

- **Pro Git: Recording Changes to the Repository** — status, add, commit, diff, rm, mv. [original](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository) · [archived](https://web.archive.org/web/20261022041406/https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository)
- **Pro Git: Viewing the Commit History** — `git log` options. [original](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History) · [archived](https://web.archive.org/web/20261101121914/https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History)
- **Pro Git: Undoing Things** — amend, unstaging, restoring. [original](https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things) · [archived](https://web.archive.org/web/20261021054418/https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things)
- **git-init** — [original](https://git-scm.com/docs/git-init) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-init)
- **git-clone** — [original](https://git-scm.com/docs/git-clone) · [archived](https://web.archive.org/web/20261029041654/https://git-scm.com/docs/git-clone)
- **git-status** — short format, `-sb`. [original](https://git-scm.com/docs/git-status) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-status)
- **git-add** — `-p`, `-N`, `-u`. [original](https://git-scm.com/docs/git-add) · [archived](https://web.archive.org/web/20261029040511/https://git-scm.com/docs/git-add)
- **git-commit** — [original](https://git-scm.com/docs/git-commit) · [archived](https://web.archive.org/web/20261024042419/https://git-scm.com/docs/git-commit)
- **git-diff** — [original](https://git-scm.com/docs/git-diff) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-diff)
- **git-log** — [original](https://git-scm.com/docs/git-log) · [archived](https://web.archive.org/web/20261021111933/https://git-scm.com/docs/git-log)
- **gitignore** — pattern syntax and precedence. [original](https://git-scm.com/docs/gitignore) · [archived](https://web.archive.org/web/20261022043606/https://git-scm.com/docs/gitignore)
- **git-rm** — [original](https://git-scm.com/docs/git-rm) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-rm)
- **git-mv** — [original](https://git-scm.com/docs/git-mv) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-mv)
- **git-restore** — [original](https://git-scm.com/docs/git-restore) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-restore)
- **git-switch** — [original](https://git-scm.com/docs/git-switch) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-switch)

## Chapter 3 — Branches, Merging and Remotes in Brief

Chapter file: [03-branches-merging-remotes-brief.md](03-branches-merging-remotes-brief.md)

- **Pro Git: Branches in a Nutshell** — a branch is a movable pointer. [original](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell) · [archived](https://web.archive.org/web/20261101122002/https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)
- **Pro Git: Basic Branching and Merging** — fast-forward and merge commits. [original](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging) · [archived](https://web.archive.org/web/20261016062729/https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)
- **Pro Git: Working with Remotes** — [original](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes) · [archived](https://web.archive.org/web/20260923141039/https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes)
- **git-branch** — [original](https://git-scm.com/docs/git-branch) · [archived](https://web.archive.org/web/20261023004352/https://git-scm.com/docs/git-branch)
- **git-merge** — [original](https://git-scm.com/docs/git-merge) · [archived](https://web.archive.org/web/20261022042520/https://git-scm.com/docs/git-merge)
- **git-fetch** — [original](https://git-scm.com/docs/git-fetch) · [archived](https://web.archive.org/web/20261022043430/https://git-scm.com/docs/git-fetch)
- **git-pull** — [original](https://git-scm.com/docs/git-pull) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-pull)
- **git-push** — [original](https://git-scm.com/docs/git-push) · [archived](https://web.archive.org/web/20261022041340/https://git-scm.com/docs/git-push)
- **git-checkout** — the older multi-purpose command. [original](https://git-scm.com/docs/git-checkout) · [archived](https://web.archive.org/web/20261022235043/https://git-scm.com/docs/git-checkout)

## Chapter 4 — The Object Database

Chapter file: [04-the-object-database.md](04-the-object-database.md)

- **Pro Git: Plumbing and Porcelain** — [original](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain) · [archived](https://web.archive.org/web/20261017214652/https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)
- **Pro Git: Git Objects** — blobs, trees, commits by hand. [original](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) · [archived](https://web.archive.org/web/20261023055607/https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)
- **git-hash-object** — [original](https://git-scm.com/docs/git-hash-object) · [archived](https://web.archive.org/web/20261021064433/https://git-scm.com/docs/git-hash-object)
- **git-cat-file** — [original](https://git-scm.com/docs/git-cat-file) · [archived](https://web.archive.org/web/20261021064433/https://git-scm.com/docs/git-cat-file)
- **git-write-tree** — [original](https://git-scm.com/docs/git-write-tree) · [archived](https://web.archive.org/web/20261021064433/https://git-scm.com/docs/git-write-tree)
- **git-commit-tree** — [original](https://git-scm.com/docs/git-commit-tree) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-commit-tree)
- **git-mktree** — [original](https://git-scm.com/docs/git-mktree) · [archived](https://web.archive.org/web/20260916220242/https://git-scm.com/docs/git-mktree)
- **git-ls-tree** — [original](https://git-scm.com/docs/git-ls-tree) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-ls-tree)
- **hash-function-transition** — SHA-1 to SHA-256 design. [original](https://git-scm.com/docs/hash-function-transition) · [archived](https://web.archive.org/web/20261013175611/https://git-scm.com/docs/hash-function-transition)

## Chapter 5 — The Index

Chapter file: [05-the-index.md](05-the-index.md)

- **Pro Git: Interactive Staging** — `add -i`, `add -p`. [original](https://git-scm.com/book/en/v2/Git-Tools-Interactive-Staging) · [archived](https://web.archive.org/web/20261021054417/https://git-scm.com/book/en/v2/Git-Tools-Interactive-Staging)
- **git-ls-files** — [original](https://git-scm.com/docs/git-ls-files) · [archived](https://web.archive.org/web/20261021064433/https://git-scm.com/docs/git-ls-files)
- **git-update-index** — [original](https://git-scm.com/docs/git-update-index) · [archived](https://web.archive.org/web/20261022150222/https://git-scm.com/docs/git-update-index)
- **git-read-tree** — [original](https://git-scm.com/docs/git-read-tree) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-read-tree)
- **gitformat-index** — the index file format. [original](https://git-scm.com/docs/gitformat-index) · [archived](https://web.archive.org/web/20260916215014/https://git-scm.com/docs/gitformat-index)
- **racy-git** — the racy-timestamp problem. [original](https://git-scm.com/docs/racy-git) · [archived](https://web.archive.org/web/20260127174928/https://git-scm.com/docs/racy-git)
- **git-sparse-checkout** — sparse index discussion. [original](https://git-scm.com/docs/git-sparse-checkout) · [archived](https://web.archive.org/web/20260911115416/https://git-scm.com/docs/git-sparse-checkout)
- **git-add** — [original](https://git-scm.com/docs/git-add) · [archived](https://web.archive.org/web/20261029040511/https://git-scm.com/docs/git-add)

## Chapter 6 — References and HEAD

Chapter file: [06-references-and-head.md](06-references-and-head.md)

- **Pro Git: Git References** — [original](https://git-scm.com/book/en/v2/Git-Internals-Git-References) · [archived](https://web.archive.org/web/20261022040308/https://git-scm.com/book/en/v2/Git-Internals-Git-References)
- **Pro Git: Tagging** — [original](https://git-scm.com/book/en/v2/Git-Basics-Tagging) · [archived](https://web.archive.org/web/20261101002959/https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- **git-update-ref** — [original](https://git-scm.com/docs/git-update-ref) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-update-ref)
- **git-symbolic-ref** — [original](https://git-scm.com/docs/git-symbolic-ref) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-symbolic-ref)
- **git-reflog** — [original](https://git-scm.com/docs/git-reflog) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-reflog)
- **git-tag** — [original](https://git-scm.com/docs/git-tag) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-tag)
- **git-pack-refs** — [original](https://git-scm.com/docs/git-pack-refs) · [archived](https://web.archive.org/web/20260928033529/https://git-scm.com/docs/git-pack-refs)
- **git-show-ref** — [original](https://git-scm.com/docs/git-show-ref) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-show-ref)
- **git-for-each-ref** — [original](https://git-scm.com/docs/git-for-each-ref) · [archived](https://web.archive.org/web/20261021064433/https://git-scm.com/docs/git-for-each-ref)
- **gitrepository-layout** — what lives in `.git`. [original](https://git-scm.com/docs/gitrepository-layout) · [archived](https://web.archive.org/web/20261021064434/https://git-scm.com/docs/gitrepository-layout)
- **reftable** — the newer ref storage backend (not in 2.34.1). [original](https://git-scm.com/docs/reftable) · [archived](https://web.archive.org/web/20260926205306/https://git-scm.com/docs/reftable)

## Chapter 7 — Revisions and Ranges

Chapter file: [07-revisions-and-ranges.md](07-revisions-and-ranges.md)

- **Pro Git: Revision Selection** — [original](https://git-scm.com/book/en/v2/Git-Tools-Revision-Selection) · [archived](https://web.archive.org/web/20261011164900/https://git-scm.com/book/en/v2/Git-Tools-Revision-Selection)
- **gitrevisions** — [original](https://git-scm.com/docs/gitrevisions) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitrevisions)
- **git-rev-parse** — [original](https://git-scm.com/docs/git-rev-parse) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-rev-parse)
- **git-rev-list** — [original](https://git-scm.com/docs/git-rev-list) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-rev-list)
- **git-merge-base** — [original](https://git-scm.com/docs/git-merge-base) · [archived](https://web.archive.org/web/20261023125717/https://git-scm.com/docs/git-merge-base)
- **git(1)** — repository discovery: `GIT_DIR`, `GIT_WORK_TREE`, `GIT_CEILING_DIRECTORIES`. [original](https://git-scm.com/docs/git) · [archived](https://web.archive.org/web/20261021064424/https://git-scm.com/docs/git)

## Chapter 8 — Reading and Searching History

Chapter file: [08-reading-and-searching-history.md](08-reading-and-searching-history.md)

- **Pro Git: Searching** — `git grep`, `log -S`, `log -L`. [original](https://git-scm.com/book/en/v2/Git-Tools-Searching) · [archived](https://web.archive.org/web/20261019194739/https://git-scm.com/book/en/v2/Git-Tools-Searching)
- **Pro Git: Debugging with Git** — blame and bisect. [original](https://git-scm.com/book/en/v2/Git-Tools-Debugging-with-Git) · [archived](https://web.archive.org/web/20261022041820/https://git-scm.com/book/en/v2/Git-Tools-Debugging-with-Git)
- **git-log** — [original](https://git-scm.com/docs/git-log) · [archived](https://web.archive.org/web/20261021111933/https://git-scm.com/docs/git-log)
- **pretty-formats** — `--pretty` and `--format` placeholders. [original](https://git-scm.com/docs/pretty-formats) · [archived](https://web.archive.org/web/20260727221807/https://git-scm.com/docs/pretty-formats)
- **git-show** — [original](https://git-scm.com/docs/git-show) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-show)
- **git-blame** — [original](https://git-scm.com/docs/git-blame) · [archived](https://web.archive.org/web/20261022041708/https://git-scm.com/docs/git-blame)
- **git-shortlog** — [original](https://git-scm.com/docs/git-shortlog) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-shortlog)
- **git-describe** — [original](https://git-scm.com/docs/git-describe) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-describe)
- **git-bisect** — [original](https://git-scm.com/docs/git-bisect) · [archived](https://web.archive.org/web/20261020225852/https://git-scm.com/docs/git-bisect)
- **Fighting regressions with git bisect** — the long-form bisect guide. [original](https://git-scm.com/docs/git-bisect-lk2009) · [archived](https://web.archive.org/web/20261021064438/https://git-scm.com/docs/git-bisect-lk2009)
- **git-grep** — [original](https://git-scm.com/docs/git-grep) · [archived](https://web.archive.org/web/20261101121250/https://git-scm.com/docs/git-grep)
- **git-range-diff** — [original](https://git-scm.com/docs/git-range-diff) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-range-diff)

## Chapter 9 — Diff Internals and Merge Mechanics

Chapter file: [09-diff-and-merge-internals.md](09-diff-and-merge-internals.md)

- **Pro Git: Advanced Merging** — conflict markers, `diff3`, strategies, subtree merging. [original](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging) · [archived](https://web.archive.org/web/20261004024151/https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging)
- **Pro Git: Rerere** — [original](https://git-scm.com/book/en/v2/Git-Tools-Rerere) · [archived](https://web.archive.org/web/20261024032336/https://git-scm.com/book/en/v2/Git-Tools-Rerere)
- **diff-options** — algorithms, rename detection, `--word-diff`. [original](https://git-scm.com/docs/diff-options) · [archived](https://web.archive.org/web/20260822011110/https://git-scm.com/docs/diff-options)
- **git-diff** — [original](https://git-scm.com/docs/git-diff) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-diff)
- **merge-strategies** — ort, recursive, octopus, ours, subtree. [original](https://git-scm.com/docs/merge-strategies) · [archived](https://web.archive.org/web/20261010092951/https://git-scm.com/docs/merge-strategies)
- **git-merge** — conflict-marker and `merge.conflictStyle` documentation. [original](https://git-scm.com/docs/git-merge) · [archived](https://web.archive.org/web/20261022042520/https://git-scm.com/docs/git-merge)
- **git-merge-file** — [original](https://git-scm.com/docs/git-merge-file) · [archived](https://web.archive.org/web/20261009160604/https://git-scm.com/docs/git-merge-file)
- **git-mergetool** — [original](https://git-scm.com/docs/git-mergetool) · [archived](https://web.archive.org/web/20261021064426/https://git-scm.com/docs/git-mergetool)
- **git-rerere** — [original](https://git-scm.com/docs/git-rerere) · [archived](https://web.archive.org/web/20261022041947/https://git-scm.com/docs/git-rerere)
- **gitattributes** — merge drivers and diff drivers. [original](https://git-scm.com/docs/gitattributes) · [archived](https://web.archive.org/web/20261022041707/https://git-scm.com/docs/gitattributes)

## Chapter 10 — Rewriting History

Chapter file: [10-rewriting-history.md](10-rewriting-history.md)

- **Pro Git: Rewriting History** — amend, interactive rebase, filter-branch. [original](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History) · [archived](https://web.archive.org/web/20261022042504/https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)
- **Pro Git: Reset Demystified** — [original](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified) · [archived](https://web.archive.org/web/20261009140404/https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified)
- **Pro Git: Rebasing** — including the golden rule. [original](https://git-scm.com/book/en/v2/Git-Branching-Rebasing) · [archived](https://web.archive.org/web/20261028201503/https://git-scm.com/book/en/v2/Git-Branching-Rebasing)
- **git-reset** — [original](https://git-scm.com/docs/git-reset) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-reset)
- **git-revert** — [original](https://git-scm.com/docs/git-revert) · [archived](https://web.archive.org/web/20261023143636/https://git-scm.com/docs/git-revert)
- **git-cherry-pick** — [original](https://git-scm.com/docs/git-cherry-pick) · [archived](https://web.archive.org/web/20261022041658/https://git-scm.com/docs/git-cherry-pick)
- **git-rebase** — all interactive verbs, `--onto`, `--rebase-merges`, `--update-refs`. [original](https://git-scm.com/docs/git-rebase) · [archived](https://web.archive.org/web/20261028035231/https://git-scm.com/docs/git-rebase)
- **git-commit** — `--amend`, `--fixup`, `--squash`. [original](https://git-scm.com/docs/git-commit) · [archived](https://web.archive.org/web/20261024042419/https://git-scm.com/docs/git-commit)
- **git-filter-branch** — and its own warnings against use. [original](https://git-scm.com/docs/git-filter-branch) · [archived](https://web.archive.org/web/20261022041821/https://git-scm.com/docs/git-filter-branch)
- **git-filter-repo** — the recommended replacement (not installed here). [original](https://github.com/newren/git-filter-repo) · [archived](https://web.archive.org/web/20260923233822/https://github.com/newren/git-filter-repo)
- **git-reflog** — [original](https://git-scm.com/docs/git-reflog) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-reflog)
- **git-replace** — replace refs and `--graft`. [original](https://git-scm.com/docs/git-replace) · [archived](https://web.archive.org/web/20261022004716/https://git-scm.com/docs/git-replace)
- **git-fast-export** — [original](https://git-scm.com/docs/git-fast-export) · [archived](https://web.archive.org/web/20260914183443/https://git-scm.com/docs/git-fast-export)
- **git-fast-import** — the stream format. [original](https://git-scm.com/docs/git-fast-import) · [archived](https://web.archive.org/web/20261021075411/https://git-scm.com/docs/git-fast-import)

## Chapter 11 — Stash, Worktrees and Cleaning

Chapter file: [11-stash-worktrees-and-cleaning.md](11-stash-worktrees-and-cleaning.md)

- **Pro Git: Stashing and Cleaning** — [original](https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning) · [archived](https://web.archive.org/web/20261024222429/https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning)
- **git-stash** — [original](https://git-scm.com/docs/git-stash) · [archived](https://web.archive.org/web/20261023191210/https://git-scm.com/docs/git-stash)
- **git-worktree** — [original](https://git-scm.com/docs/git-worktree) · [archived](https://web.archive.org/web/20261021164010/https://git-scm.com/docs/git-worktree)
- **git-clean** — [original](https://git-scm.com/docs/git-clean) · [archived](https://web.archive.org/web/20261022043437/https://git-scm.com/docs/git-clean)
- **git-restore** — `--source`, `--staged`, `--worktree`. [original](https://git-scm.com/docs/git-restore) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-restore)
- **git-checkout** — `checkout -p`. [original](https://git-scm.com/docs/git-checkout) · [archived](https://web.archive.org/web/20261022235043/https://git-scm.com/docs/git-checkout)

## Chapter 12 — Remotes in Depth

Chapter file: [12-remotes-in-depth.md](12-remotes-in-depth.md)

- **Pro Git: Remote Branches** — remote-tracking branches and upstreams. [original](https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches) · [archived](https://web.archive.org/web/20261024034541/https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches)
- **Pro Git: The Refspec** — [original](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec) · [archived](https://web.archive.org/web/20261022043435/https://git-scm.com/book/en/v2/Git-Internals-The-Refspec)
- **Pro Git: Credential Storage** — [original](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage) · [archived](https://web.archive.org/web/20261023151151/https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
- **Pro Git: The Protocols (Git on the Server)** — local, HTTP, SSH, git. [original](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols) · [archived](https://web.archive.org/web/20261007173606/https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols)
- **Pro Git: Contributing to a Project (GitHub)** — the fork workflow. [original](https://git-scm.com/book/en/v2/GitHub-Contributing-to-a-Project) · [archived](https://web.archive.org/web/20260928165229/https://git-scm.com/book/en/v2/GitHub-Contributing-to-a-Project)
- **git-remote** — [original](https://git-scm.com/docs/git-remote) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-remote)
- **git-fetch** — refspecs, `--prune`. [original](https://git-scm.com/docs/git-fetch) · [archived](https://web.archive.org/web/20261022043430/https://git-scm.com/docs/git-fetch)
- **git-pull** — [original](https://git-scm.com/docs/git-pull) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-pull)
- **git-push** — `--force-with-lease`, `push.default`. [original](https://git-scm.com/docs/git-push) · [archived](https://web.archive.org/web/20261022041340/https://git-scm.com/docs/git-push)
- **git-ls-remote** — [original](https://git-scm.com/docs/git-ls-remote) · [archived](https://web.archive.org/web/20261002083105/https://git-scm.com/docs/git-ls-remote)
- **gitcredentials** — [original](https://git-scm.com/docs/gitcredentials) · [archived](https://web.archive.org/web/20261022041823/https://git-scm.com/docs/gitcredentials)
- **git-credential-store** — [original](https://git-scm.com/docs/git-credential-store) · [archived](https://web.archive.org/web/20260930135501/https://git-scm.com/docs/git-credential-store)
- **git-credential-cache** — [original](https://git-scm.com/docs/git-credential-cache) · [archived](https://web.archive.org/web/20260922053713/https://git-scm.com/docs/git-credential-cache)

## Chapter 13 — Transport and Packfiles

Chapter file: [13-transport-and-packfiles.md](13-transport-and-packfiles.md)

- **Pro Git: Packfiles** — [original](https://git-scm.com/book/en/v2/Git-Internals-Packfiles) · [archived](https://web.archive.org/web/20261021054418/https://git-scm.com/book/en/v2/Git-Internals-Packfiles)
- **Pro Git: Transfer Protocols** — [original](https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols) · [archived](https://web.archive.org/web/20261006160423/https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols)
- **Pro Git: Maintenance and Data Recovery** — [original](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery) · [archived](https://web.archive.org/web/20261022041821/https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery)
- **Pro Git: Bundling** — [original](https://git-scm.com/book/en/v2/Git-Tools-Bundling) · [archived](https://web.archive.org/web/20261020201933/https://git-scm.com/book/en/v2/Git-Tools-Bundling)
- **git-pack-objects** — [original](https://git-scm.com/docs/git-pack-objects) · [archived](https://web.archive.org/web/20260828094641/https://git-scm.com/docs/git-pack-objects)
- **git-unpack-objects** — [original](https://git-scm.com/docs/git-unpack-objects) · [archived](https://web.archive.org/web/20260803205337/https://git-scm.com/docs/git-unpack-objects)
- **git-index-pack** — [original](https://git-scm.com/docs/git-index-pack) · [archived](https://web.archive.org/web/20260916215014/https://git-scm.com/docs/git-index-pack)
- **git-repack** — [original](https://git-scm.com/docs/git-repack) · [archived](https://web.archive.org/web/20260816181454/https://git-scm.com/docs/git-repack)
- **git-gc** — [original](https://git-scm.com/docs/git-gc) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-gc)
- **git-prune** — [original](https://git-scm.com/docs/git-prune) · [archived](https://web.archive.org/web/20260901055505/https://git-scm.com/docs/git-prune)
- **git-fsck** — [original](https://git-scm.com/docs/git-fsck) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-fsck)
- **git-count-objects** — [original](https://git-scm.com/docs/git-count-objects) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-count-objects)
- **git-verify-pack** — [original](https://git-scm.com/docs/git-verify-pack) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-verify-pack)
- **git-bundle** — [original](https://git-scm.com/docs/git-bundle) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-bundle)
- **git-maintenance** — [original](https://git-scm.com/docs/git-maintenance) · [archived](https://web.archive.org/web/20260706052202/https://git-scm.com/docs/git-maintenance)
- **git-commit-graph** — [original](https://git-scm.com/docs/git-commit-graph) · [archived](https://web.archive.org/web/20261001214553/https://git-scm.com/docs/git-commit-graph)
- **gitformat-pack** — pack and idx formats. [original](https://git-scm.com/docs/gitformat-pack) · [archived](https://web.archive.org/web/20261023191606/https://git-scm.com/docs/gitformat-pack)
- **gitformat-bundle** — [original](https://git-scm.com/docs/gitformat-bundle) · [archived](https://web.archive.org/web/20261022081948/https://git-scm.com/docs/gitformat-bundle)
- **gitprotocol-v2** — [original](https://git-scm.com/docs/gitprotocol-v2) · [archived](https://web.archive.org/web/20261002082958/https://git-scm.com/docs/gitprotocol-v2)
- **gitprotocol-pack** — [original](https://git-scm.com/docs/gitprotocol-pack) · [archived](https://web.archive.org/web/20261020203149/https://git-scm.com/docs/gitprotocol-pack)
- **gitprotocol-http** — [original](https://git-scm.com/docs/gitprotocol-http) · [archived](https://web.archive.org/web/20261101121429/https://git-scm.com/docs/gitprotocol-http)
- **partial-clone** — design notes for `--filter`. [original](https://git-scm.com/docs/partial-clone) · [archived](https://web.archive.org/web/20261022223405/https://git-scm.com/docs/partial-clone)

## Chapter 14 — Submodules, Subtrees and Large Repos

Chapter file: [14-submodules-subtrees-large-repos.md](14-submodules-subtrees-large-repos.md)

- **Pro Git: Submodules** — [original](https://git-scm.com/book/en/v2/Git-Tools-Submodules) · [archived](https://web.archive.org/web/20261024034541/https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- **Pro Git: Advanced Merging** — includes subtree merging. [original](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging) · [archived](https://web.archive.org/web/20261004024151/https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging)
- **git-submodule** — [original](https://git-scm.com/docs/git-submodule) · [archived](https://web.archive.org/web/20261022043432/https://git-scm.com/docs/git-submodule)
- **gitsubmodules** — [original](https://git-scm.com/docs/gitsubmodules) · [archived](https://web.archive.org/web/20261101121253/https://git-scm.com/docs/gitsubmodules)
- **gitmodules** — [original](https://git-scm.com/docs/gitmodules) · [archived](https://web.archive.org/web/20261101121332/https://git-scm.com/docs/gitmodules)
- **git-sparse-checkout** — cone and non-cone modes. [original](https://git-scm.com/docs/git-sparse-checkout) · [archived](https://web.archive.org/web/20260911115416/https://git-scm.com/docs/git-sparse-checkout)
- **partial-clone** — [original](https://git-scm.com/docs/partial-clone) · [archived](https://web.archive.org/web/20261022223405/https://git-scm.com/docs/partial-clone)
- **Git LFS** — large-file storage (not installed here). [original](https://git-lfs.com) · [archived](https://web.archive.org/web/20261025113639/https://git-lfs.com/)
- **git-subtree** — the manual for `contrib/subtree` (not on git-scm.com; `git subtree -h` prints its usage where it is installed). [original](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc) · [archived](https://web.archive.org/web/20260925014450/https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc)

## Chapter 15 — Hooks, Attributes and Config

Chapter file: [15-hooks-attributes-and-config.md](15-hooks-attributes-and-config.md)

- **Pro Git: Git Hooks** — [original](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) · [archived](https://web.archive.org/web/20261022041629/https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- **Pro Git: Git Attributes** — [original](https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes) · [archived](https://web.archive.org/web/20261004165539/https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes)
- **Pro Git: Git Configuration** — [original](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration) · [archived](https://web.archive.org/web/20261027160318/https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
- **githooks** — [original](https://git-scm.com/docs/githooks) · [archived](https://web.archive.org/web/20261022045345/https://git-scm.com/docs/githooks)
- **gitattributes** — [original](https://git-scm.com/docs/gitattributes) · [archived](https://web.archive.org/web/20261022041707/https://git-scm.com/docs/gitattributes)
- **git-config** — `include`, `includeIf`, aliases, `core.*`. [original](https://git-scm.com/docs/git-config) · [archived](https://web.archive.org/web/20261021064424/https://git-scm.com/docs/git-config)
- **gitignore** — [original](https://git-scm.com/docs/gitignore) · [archived](https://web.archive.org/web/20261022043606/https://git-scm.com/docs/gitignore)
- **git-check-attr** — [original](https://git-scm.com/docs/git-check-attr) · [archived](https://web.archive.org/web/20261101121429/https://git-scm.com/docs/git-check-attr)
- **git-check-ignore** — [original](https://git-scm.com/docs/git-check-ignore) · [archived](https://web.archive.org/web/20261101121429/https://git-scm.com/docs/git-check-ignore)

## Chapter 16 — Collaboration and Patches

Chapter file: [16-collaboration-and-patches.md](16-collaboration-and-patches.md)

- **Pro Git: Distributed Workflows** — [original](https://git-scm.com/book/en/v2/Distributed-Git-Distributed-Workflows) · [archived](https://web.archive.org/web/20261023025129/https://git-scm.com/book/en/v2/Distributed-Git-Distributed-Workflows)
- **Pro Git: Contributing to a Project** — patches, commit message guidelines. [original](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project) · [archived](https://web.archive.org/web/20261030182150/https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project)
- **Pro Git: Branching Workflows** — [original](https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows) · [archived](https://web.archive.org/web/20261022041036/https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows)
- **Pro Git: Signing Your Work** — [original](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work) · [archived](https://web.archive.org/web/20261023012029/https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- **git-format-patch** — [original](https://git-scm.com/docs/git-format-patch) · [archived](https://web.archive.org/web/20261021064430/https://git-scm.com/docs/git-format-patch)
- **git-am** — [original](https://git-scm.com/docs/git-am) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-am)
- **git-apply** — [original](https://git-scm.com/docs/git-apply) · [archived](https://web.archive.org/web/20261021064427/https://git-scm.com/docs/git-apply)
- **git-send-email** — [original](https://git-scm.com/docs/git-send-email) · [archived](https://web.archive.org/web/20261030185058/https://git-scm.com/docs/git-send-email)
- **git-request-pull** — [original](https://git-scm.com/docs/git-request-pull) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/git-request-pull)
- **git-notes** — [original](https://git-scm.com/docs/git-notes) · [archived](https://web.archive.org/web/20261021064425/https://git-scm.com/docs/git-notes)
- **git-archive** — [original](https://git-scm.com/docs/git-archive) · [archived](https://web.archive.org/web/20261021064433/https://git-scm.com/docs/git-archive)
- **git-interpret-trailers** — [original](https://git-scm.com/docs/git-interpret-trailers) · [archived](https://web.archive.org/web/20260925170148/https://git-scm.com/docs/git-interpret-trailers)
- **git-verify-commit** — [original](https://git-scm.com/docs/git-verify-commit) · [archived](https://web.archive.org/web/20260408180227/https://git-scm.com/docs/git-verify-commit)
- **git-verify-tag** — [original](https://git-scm.com/docs/git-verify-tag) · [archived](https://web.archive.org/web/20260519025321/https://git-scm.com/docs/git-verify-tag)
- **gitformat-signature** — [original](https://git-scm.com/docs/gitformat-signature) · [archived](https://web.archive.org/web/20260918154943/https://git-scm.com/docs/gitformat-signature)
- **gitworkflows** — [original](https://git-scm.com/docs/gitworkflows) · [archived](https://web.archive.org/web/20261101121303/https://git-scm.com/docs/gitworkflows)
- **SubmittingPatches** — Git's own contribution guide and message conventions. [original](https://git-scm.com/docs/SubmittingPatches) · [archived](https://web.archive.org/web/20261101121305/https://git-scm.com/docs/SubmittingPatches)

## Chapter 17 — Debugging and Recovery

Chapter file: [17-debugging-and-recovery.md](17-debugging-and-recovery.md)

- **Pro Git: Maintenance and Data Recovery** — [original](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery) · [archived](https://web.archive.org/web/20261022041821/https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery)
- **Pro Git: Environment Variables** — [original](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables) · [archived](https://web.archive.org/web/20260926132525/https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables)
- **Pro Git: Debugging with Git** — [original](https://git-scm.com/book/en/v2/Git-Tools-Debugging-with-Git) · [archived](https://web.archive.org/web/20261022041820/https://git-scm.com/book/en/v2/Git-Tools-Debugging-with-Git)
- **git-fsck** — [original](https://git-scm.com/docs/git-fsck) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-fsck)
- **git-reflog** — [original](https://git-scm.com/docs/git-reflog) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-reflog)
- **git-gc** — reflog expiry and pruning defaults. [original](https://git-scm.com/docs/git-gc) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-gc)
- **git-bisect** — `bisect run` exit codes. [original](https://git-scm.com/docs/git-bisect) · [archived](https://web.archive.org/web/20261020225852/https://git-scm.com/docs/git-bisect)
- **git(1)** — `GIT_TRACE*` variables. [original](https://git-scm.com/docs/git) · [archived](https://web.archive.org/web/20261021064424/https://git-scm.com/docs/git)
- **git-bugreport** — [original](https://git-scm.com/docs/git-bugreport) · [archived](https://web.archive.org/web/20261101121306/https://git-scm.com/docs/git-bugreport)

## Chapter 18 — Mini-Git and Where Next

Chapter file: [18-mini-git-and-where-next.md](18-mini-git-and-where-next.md)

- **Pro Git: Git Objects** — [original](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) · [archived](https://web.archive.org/web/20261023055607/https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)
- **gitformat-index** — [original](https://git-scm.com/docs/gitformat-index) · [archived](https://web.archive.org/web/20260916215014/https://git-scm.com/docs/gitformat-index)
- **gitformat-pack** — [original](https://git-scm.com/docs/gitformat-pack) · [archived](https://web.archive.org/web/20261023191606/https://git-scm.com/docs/gitformat-pack)
- **git-fsck** — `--strict`. [original](https://git-scm.com/docs/git-fsck) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-fsck)
- **git-commit-tree** — [original](https://git-scm.com/docs/git-commit-tree) · [archived](https://web.archive.org/web/20261021064432/https://git-scm.com/docs/git-commit-tree)
- **hash-function-transition** — [original](https://git-scm.com/docs/hash-function-transition) · [archived](https://web.archive.org/web/20261013175611/https://git-scm.com/docs/hash-function-transition)
- **Git release notes** — for the features newer than 2.34. [original](https://github.com/git/git/tree/master/Documentation/RelNotes) · [archived](https://web.archive.org/web/20260423064754/https://github.com/git/git/tree/master/Documentation/RelNotes)

## Appendix A — Cheat Sheet

Appendix file: [appendix-a-cheatsheet.md](appendix-a-cheatsheet.md)

- **giteveryday** — [original](https://git-scm.com/docs/giteveryday) · [archived](https://web.archive.org/web/20261021075411/https://git-scm.com/docs/giteveryday)
- **gitcli** — [original](https://git-scm.com/docs/gitcli) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitcli)
- **gitrevisions** — [original](https://git-scm.com/docs/gitrevisions) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitrevisions)
- **Git reference manual** — [original](https://git-scm.com/docs) · [archived](https://web.archive.org/web/20261022180932/https://git-scm.com/docs)

## Appendix B — Plumbing and File Formats

Appendix file: [appendix-b-plumbing-and-file-formats.md](appendix-b-plumbing-and-file-formats.md)

- **gitrepository-layout** — [original](https://git-scm.com/docs/gitrepository-layout) · [archived](https://web.archive.org/web/20261021064434/https://git-scm.com/docs/gitrepository-layout)
- **gitformat-index** — [original](https://git-scm.com/docs/gitformat-index) · [archived](https://web.archive.org/web/20260916215014/https://git-scm.com/docs/gitformat-index)
- **gitformat-pack** — [original](https://git-scm.com/docs/gitformat-pack) · [archived](https://web.archive.org/web/20261023191606/https://git-scm.com/docs/gitformat-pack)
- **gitformat-commit-graph** — [original](https://git-scm.com/docs/gitformat-commit-graph) · [archived](https://web.archive.org/web/20260704193116/https://git-scm.com/docs/gitformat-commit-graph)
- **gitformat-signature** — [original](https://git-scm.com/docs/gitformat-signature) · [archived](https://web.archive.org/web/20260918154943/https://git-scm.com/docs/gitformat-signature)
- **gitformat-bundle** — [original](https://git-scm.com/docs/gitformat-bundle) · [archived](https://web.archive.org/web/20261022081948/https://git-scm.com/docs/gitformat-bundle)
- **gitprotocol-pack** — [original](https://git-scm.com/docs/gitprotocol-pack) · [archived](https://web.archive.org/web/20261020203149/https://git-scm.com/docs/gitprotocol-pack)
- **gitprotocol-v2** — [original](https://git-scm.com/docs/gitprotocol-v2) · [archived](https://web.archive.org/web/20261002082958/https://git-scm.com/docs/gitprotocol-v2)
- **reftable** — [original](https://git-scm.com/docs/reftable) · [archived](https://web.archive.org/web/20260926205306/https://git-scm.com/docs/reftable)
- **hash-function-transition** — [original](https://git-scm.com/docs/hash-function-transition) · [archived](https://web.archive.org/web/20261013175611/https://git-scm.com/docs/hash-function-transition)
- **gitglossary** — [original](https://git-scm.com/docs/gitglossary) · [archived](https://web.archive.org/web/20261021064431/https://git-scm.com/docs/gitglossary)
