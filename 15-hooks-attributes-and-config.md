# Chapter 15 — Hooks, Attributes and Config

Git is configured in layers and extended with small programs: **hooks** run at defined moments, **attributes** attach per-path behaviour (line endings, diff/merge drivers, filters, archive rules), and **config** ties it together. This chapter goes through all three, with real hooks, drivers and filters. Previous: [Chapter 14 — Submodules, Subtrees and Large Repos](14-submodules-subtrees-large-repos.md). Next: [Chapter 16 — Collaboration and Patches](16-collaboration-and-patches.md).

Transcripts: [`examples/ch15/demo.sh`](examples/ch15/demo.sh) → `output.txt` (Git 2.34.1). `/home/you` is the scratch repo; `~` is the sandboxed home directory the script uses.

## Hooks

A hook is an executable file in `.git/hooks/` (or `core.hooksPath`) with a **specific name**. Git runs it at that event, passing arguments and sometimes stdin; for most hooks a non-zero exit status aborts the operation. New repositories get `*.sample` files (inactive: the `.sample` suffix is what disables them):

```console
$ ls .git/hooks | head -5; ls .git/hooks | wc -l
applypatch-msg.sample
commit-msg.sample
fsmonitor-watchman.sample
post-update.sample
pre-applypatch.sample
13
```

Hooks live in `.git/`, which is **not versioned or cloned**, so they are personal conventions, not policy. Enforce rules in CI or on the server (`pre-receive`, or your hosting service's checks).

### Client-side hooks that matter

| Hook | When | Arguments / effect |
|------|------|--------------------|
| `pre-commit` | before the commit message is requested | none; non-zero aborts; skip with `--no-verify` |
| `prepare-commit-msg` | after the default message is made, before the editor | message file, source (`message`, `template`, `merge`, `squash`, `commit`), commit hash |
| `commit-msg` | after the message is written | message file path; non-zero aborts; skip with `--no-verify` |
| `post-commit` | after a commit | none; cannot affect it |
| `pre-rebase` | before rebase starts | upstream, branch |
| `post-checkout` | after `checkout`/`switch`/`clone` | old HEAD, new HEAD, branch-flag |
| `post-merge` | after a successful merge | squash flag |
| `pre-push` | before push transfers anything | remote name, URL; stdin: `<local ref> <local sha> <remote ref> <remote sha>` per ref; non-zero aborts; skip with `--no-verify` |
| `post-rewrite` | after `commit --amend`/`rebase` | `amend` or `rebase`; stdin: old→new hashes |
| `pre-auto-gc` | before `gc --auto` | non-zero aborts |

Server-side: `pre-receive`, `update`, `post-receive`, `post-update`, `push-to-checkout`, `proc-receive`. On either side, `reference-transaction` (2.28+) sees every ref update. Mail/patch-related: `applypatch-msg`, `pre-applypatch`, `post-applypatch`, `sendemail-validate`. Full list and exact argument rules: `man githooks` (REFERENCES.md).

### A pre-commit hook

The hook script (written to `.git/hooks/pre-commit`, mode `+x`):

```sh
#!/bin/sh
# reject commits that add the word FIXME
if git diff --cached -U0 | grep -q '^+.*FIXME'; then
  echo "pre-commit: FIXME found, aborting" >&2
  exit 1
fi
```

```console
$ git commit -m "add fixme"; echo rc=$?
pre-commit: FIXME found, aborting
rc=1
$ git commit --no-verify -q -m "skip the hook"; echo rc=$?
rc=0
```

Notes: the hook must be executable (otherwise Git ignores it with `hint: The '.git/hooks/pre-commit' hook was ignored because it's not set as executable.`, shown at the end of the chapter's script); it runs with the repository root as its working directory; for partial commits (`commit -a`, `commit <path>`) the hook sees a temporary index, so always inspect `git diff --cached`, never the work tree. `GIT_INDEX_FILE` and other `GIT_*` variables are set for the hook.

### commit-msg and prepare-commit-msg

```sh
#!/bin/sh
# $1 = path to the message file
if ! head -1 "$1" | grep -Eq '^[A-Z][^.]{0,71}$'; then
  echo "commit-msg: subject must start uppercase, <=72 chars, no trailing period" >&2
  exit 1
fi
```

```console
$ git commit -qam "lowercase subject"; echo rc=$?
commit-msg: subject must start uppercase, <=72 chars, no trailing period
rc=1
$ git commit -qam "Proper subject"; echo rc=$?
rc=0
```

`prepare-commit-msg` can edit the message before the editor opens; here it appends a ticket line (and prints its second argument, `message`, because `-m` was used):

```console
$ git commit -qam "With trailer"; git log -1 --format=%B
hook args: message
With trailer

[ticket: DEMO-1]

```

### post-commit and pre-push (stdin protocol)

```console
$ git commit -qam "Hooked commit"
post-commit: committed 6e7b566
$ git push origin main; echo rc=$?
pre-push to origin (../remote.git)
  refs/heads/main 6e7b566d4d4c5ac4bf8980a397832e4c8b298227 -> refs/heads/main 0000000000000000000000000000000000000000
error: failed to push some refs to '../remote.git'
rc=1
$ git push --no-verify -q origin main; echo rc=$?
rc=0
```

The all-zero hash is the "remote ref doesn't exist yet" marker. This `pre-push` always exits 1, so only `--no-verify` pushes. Typical real uses: run tests, forbid pushing `WIP` commits, forbid pushing to `main`.

### Sharing hooks: `core.hooksPath`

Commit your hooks in a directory in the repository (e.g. `.githooks/`) and point Git at it. Each developer runs the one-time setup:

```console
$ git commit -qam "Via hooksPath"; echo rc=$?
shared pre-commit ran
rc=0
```

(After `git config core.hooksPath .githooks`; the path is relative to the work-tree root; an absolute path works for all repos when set with `--global`.) Frameworks like `pre-commit` and `husky` build on this.

## Attributes

`.gitattributes` (tracked, versioned with the repo), `.git/info/attributes` (local) and the global `core.attributesFile` assign attributes to path patterns (the same glob rules as `.gitignore`, except that `!` negation is rejected with `warning: Negative patterns are ignored in git attributes`; last match wins, attribute by attribute). Query with `git check-attr`:

```console
$ git check-attr -a blob.bin
blob.bin: binary: set
blob.bin: diff: unset
blob.bin: merge: unset
blob.bin: text: unset
```

Here `*.bin binary` is a *macro* that expands to `-diff -merge -text`.

### Line endings: `text`, `eol`, `core.autocrlf`

On `git add`, a file marked `text` is normalized to LF in the repository; on checkout `eol=crlf|lf` selects the work-tree style (default: platform native, or `core.autocrlf`). `git ls-files --eol` shows the index (`i/`) and work-tree (`w/`) ending and the attribute applied. Start: a CRLF file committed without attributes keeps its CRLF in the repository:

```console
$ git add crlf.txt lf.txt 2>&1; git ls-files --eol crlf.txt lf.txt
i/crlf  w/crlf  attr/                 	crlf.txt
i/lf    w/lf    attr/                 	lf.txt
```

After adding `*.txt text eol=lf` to `.gitattributes` and re-adding everything, the index copy is normalized while the work tree file was left alone (and Git warns when it normalizes):

```console
$ git ls-files --eol crlf.txt lf.txt
i/lf    w/crlf  attr/text eol=lf      	crlf.txt
i/lf    w/lf    attr/text eol=lf      	lf.txt
$ git check-attr -a crlf.txt; git check-attr text eol -- lf.txt
crlf.txt: text: set
crlf.txt: eol: lf
lf.txt: text: set
lf.txt: eol: lf
```

(The `warning: CRLF will be replaced by LF in crlf.txt.` message is printed to stderr at the `git add` step.) Recommended: a committed `.gitattributes` with `* text=auto` and explicit `eol` for scripts/batch files; avoid relying on per-user `core.autocrlf`. `git add --renormalize .` re-applies the rules to already tracked files after you change them. Merges can use `-X renormalize` (chapter 9).

### `diff` drivers: `textconv`

`diff=<name>` selects a driver configured in `diff.<name>.*`. `textconv` converts the file to text before diffing (for `.docx`, PDFs, images' EXIF, …); `xfuncname` improves hunk headers (`diff.<name>.xfuncname`); `binary` tells Git to treat a type as binary. A toy driver that upper-cases content before diffing (`.gitattributes`: `*.upper diff=upper`; config `diff.upper.textconv = tr a-z A-Z <`):

```console
$ git diff note.upper
diff --git a/note.upper b/note.upper
index 5626abf..f719efd 100644
--- a/note.upper
+++ b/note.upper
@@ -1 +1 @@
-ONE
+TWO
$ git diff --no-textconv note.upper | tail -3
@@ -1 +1 @@
-one
+two
```

`git log -p` and `git show` use textconv too; `git diff --no-textconv` bypasses it. `diff.<name>.cachetextconv true` caches the converted text in a notes ref (tested in a second repository with the same driver):

```console
$ git log -p -1 n.upper | tail -2; git for-each-ref refs/notes
-ONE
+TWO
2e538000687e23396c98b0b123b1f939ced21557 commit	refs/notes/textconv/upper
```

### `merge` drivers

`merge=union` is a built-in driver: keep both sides' lines, never conflict. A custom driver is a command in config; `%O` base, `%A` ours (the file to overwrite), `%B` theirs, `%L` conflict marker size, `%P` path. A driver that exits 0 without touching `%A` ("true") means "keep ours":

```console
$ git merge x 2>&1 | tail -2; cat list.lst
 list.lst | 1 +
 1 file changed, 1 insertion(+)
base
theirs
ours
$ git merge y 2>&1 | tail -2; cat keep.cfg
Auto-merging keep.cfg
Merge made by the 'ort' strategy.
m
$ git config merge.keepours.name "always keep ours"; git config --get-regexp "^merge.keepours"
merge.keepours.driver true
merge.keepours.name always keep ours
```

(`.gitattributes`: `*.lst merge=union` and `keep.cfg merge=keepours`; `git config merge.keepours.driver true`. Both sides changed `keep.cfg`, yet no conflict arose; our `m` stayed.) A driver must be defined in each clone's config — the attribute is shared, the command is not, so a missing driver falls back to the normal merge. Use `.gitattributes` `merge=ours` only after defining it; `-s ours` and `-X ours` are different things (chapter 9).

### `filter` (clean/smudge)

A filter transforms content when staging (**clean**) and when checking out (**smudge**): keyword expansion, secrets scrubbing, LFS. Here a `redact` filter hides tokens in the *repository* copy only:

```console
$ git show HEAD:secret.conf; cat secret.conf
token=REDACTED
token=abc123
```

(`.gitattributes`: `secret.conf filter=redact`; config `filter.redact.clean = sed 's/token=[a-z0-9]*/token=REDACTED/'`, `filter.redact.smudge = cat`.) The committed blob has the redacted value; the work tree file is unchanged. Caution: filters are **not** a secrets mechanism — the unfiltered content is on your disk and the filter config must exist everywhere. `filter.<n>.required` makes a missing filter an error; `filter.<n>.process` runs one long-lived process (used by LFS). The built-in `ident` attribute expands `$Id$` to `$Id: <blob hash> $` on checkout and collapses it again on `add` (with `*.c ident`):

```console
$ rm a.c; git checkout a.c; head -1 a.c; git show HEAD:a.c | head -1; git rev-parse --short HEAD:a.c
Updated 1 path from the index
/* $Id: e3aad293e208ed11ce33c3ec87dd1899326bd611 $ */
/* $Id$ */
e3aad29
```

### `export-ignore` and `git archive`

`export-ignore` removes paths from `git archive` tarballs/zips (and thus from hosting services' "Download ZIP"); `export-subst` expands `$Format:...$` placeholders. With `tests export-ignore` and `.gitattributes export-ignore`:

```console
$ git archive HEAD | tar -t | head -12
.githooks/
.githooks/pre-commit
a.txt
blob.bin
keep.cfg
list.lst
note.upper
secret.conf
$ git archive --format=tar --prefix=proj-1.0/ HEAD | tar -t | head -3
proj-1.0/
proj-1.0/.githooks/
proj-1.0/.githooks/pre-commit
```

`tests/` and `.gitattributes` are missing from the archive even though they are tracked. `git archive` builds from a tree and ignores untracked files, so it's also the right way to export a clean snapshot. More in chapter 16.

## Config deep dive

### Levels, precedence and origin

Values come from, later overriding earlier: **system** (`/etc/gitconfig`), **global** (`$XDG_CONFIG_HOME/git/config`, default `~/.config/git/config`, then `~/.gitconfig`), **local** (`.git/config`), **worktree** (`.git/config.worktree`, if `extensions.worktreeConfig`), then **command line** (`-c key=value`) and `GIT_CONFIG_*` environment variables. Chapter 1 introduced them; two commands show provenance:

```console
$ git config --show-origin --show-scope --get user.name | sed "s|$HOME|~|"
global	file:~/.gitconfig	Ada Lovelace
$ git config --list --show-origin | sed "s|$HOME|~|" | head -8
file:~/.gitconfig	user.name=Ada Lovelace
file:~/.gitconfig	user.email=ada@example.com
file:~/.gitconfig	init.defaultbranch=main
file:~/.gitconfig	advice.detachedhead=false
file:.git/config	core.repositoryformatversion=0
file:.git/config	core.filemode=true
file:.git/config	core.bare=false
file:.git/config	core.logallrefupdates=true
```

(The `sed` shortens the home directory to `~`; keys are normalized to lower case in `--list`.) `git config -e [--global]` opens the file in your editor.

### Includes and conditional includes

`[include] path = …` splices another file in at that point. `[includeIf "<condition>"]` does so conditionally: `gitdir:<pattern>` (repo's `.git` location matches; trailing `/` means `/**`), `gitdir/i:`, `onbranch:<pattern>`, `hasconfig:remote.*.url:<pattern>` (2.36+). On 2.34 an unknown condition is silently false: with `includeIf."hasconfig:remote.*.url:**example.com**".path` set and a remote `https://example.com/x.git`, `git config user.email` still printed `ada@example.com` (end of the script). The typical use is different identities for work and personal repos:

```console
$ git -C ~/work/proj config user.email
ada@work.example
$ git config user.email
ada@example.com
```

(Global config had `includeIf."gitdir:~/work/".path` pointing at a file with `[user] email = ada@work.example`; `~` expanded to the sandboxed home in the script.) Included files are read-only from `git config --global`'s point of view: it edits the file you name, not the included one.

### Aliases

```console
$ git config --global alias.lg "log --oneline --graph --decorate -5"; git config --global alias.last "log -1 --stat"; git config --global alias.sh "!echo shell alias in \$(pwd | xargs basename)"
$ git lg | head -3; git sh; git co --help 2>&1 | head -1
* 0105b7d (HEAD -> main) export
* 6969f7a filters
*   5046d3e Merge branch 'y'
shell alias in lab
'co' is aliased to 'checkout'
```

An alias expands to a Git command line; a leading `!` runs a shell command from the repository root (so `pwd` printed the top-level directory name `lab`). Aliases can't override built-in commands. `git co` came from an included file, which leads to a subtlety:

```console
$ git config --global --unset alias.co; git config --get-regexp "^alias"
alias.co checkout
alias.lg log --oneline --graph --decorate -5
alias.last log -1 --stat
alias.sh !echo shell alias in $(pwd | xargs basename)
```

`--unset` removed nothing: `alias.co` is defined in the *included* file (`include.path = ~/extra.gitconfig`), and `git config` edits only `~/.gitconfig`. Edit the included file instead.

### Settings worth knowing

| Setting | Effect |
|---------|--------|
| `core.editor`, `core.pager` | which editor/pager (`GIT_EDITOR`, `GIT_PAGER` override) |
| `core.fileMode` | track the executable bit (`true` here; set `false` on filesystems that lie) |
| `core.autocrlf` | `true`/`input`/`false`; prefer `.gitattributes` |
| `core.whitespace` | what `diff --check`/`apply` call a whitespace error |
| `core.ignoreCase` | case-insensitive FS handling (set by `init` automatically) |
| `core.excludesFile` | global ignore file |
| `core.hooksPath` | alternative hooks directory |
| `core.quotePath` | `false` prints UTF-8 paths unescaped |
| `core.untrackedCache`, `core.fsmonitor` | speed up `status` in large repos (the built-in fsmonitor daemon needs 2.37+, Windows and macOS only) |
| `init.defaultBranch` | name of the first branch (2.28+) |
| `pull.rebase`, `pull.ff`, `merge.ff` | integration defaults |
| `rebase.autoSquash`, `rebase.autoStash` | rebase conveniences |
| `fetch.prune`, `push.default` | remote behaviour (chapter 12) |
| `diff.algorithm`, `merge.conflictStyle` | chapter 9 |
| `rerere.enabled` | chapter 9 |
| `help.autoCorrect` | run a mistyped command after a delay |
| `status.showUntrackedFiles`, `color.ui` | output |

Read what is set with `git config --list --show-origin`; the manual for all keys is `man git-config`.

### Ignoring without `.gitignore`

Per-repo untracked patterns go in `.git/info/exclude` (same syntax, never committed); personal patterns across all repos go in the file named by `core.excludesFile` (default `$XDG_CONFIG_HOME/git/ignore` or `~/.config/git/ignore`). `git check-ignore -v` tells you which rule matched:

```console
$ git status -s | head -3; git check-ignore -v scratch.log
.git/info/exclude:7:scratch.log	scratch.log
$ git config --global core.excludesFile "$HOME/.gitignore_global"; echo "*.swp" > "$HOME/.gitignore_global"; touch x.swp; git check-ignore -v x.swp | sed "s#$HOME#~#"
~/.gitignore_global:1:*.swp	x.swp
```

(`git status -s` printed nothing: `scratch.log` is excluded, and the repo had no other changes. Rule: `<source>:<line>:<pattern>`.) Remember: ignore rules don't affect files that are already **tracked**; run `git rm --cached <file>` first.

When several sources match, the most specific wins: patterns given on the command line (`ls-files --exclude`), then the `.gitignore` in the file's own directory, then those in parent directories up to the top level, then `.git/info/exclude`, then `core.excludesFile`. Within one file the last matching line wins. In a separate test, `*.log` in the top-level `.gitignore` and `!a.log` in `sub/.gitignore` left `sub/a.log` untracked but visible (`check-ignore -v` reported `sub/.gitignore:1:!a.log`), and `!a.log` in `.git/info/exclude` could not override `*.log` in `.gitignore`.

### `safe.directory`

Since the April 2022 security releases (2.35.2 and maintenance releases back to 2.30.3; Ubuntu patched its 2.34.1 package), Git refuses to use a repository whose directory is owned by another user, because that repository's config could name a hook or `core.fsmonitor` command and run code as you. You get `fatal: detected dubious ownership in repository at '<path>'` and the suggested fix `git config --global --add safe.directory <path>`. The setting is multi-valued, read only from system and global config (never from the repository itself or `-c`), and `*` disables the check. It mostly shows up with shared checkouts, containers and `sudo`. *Unverified:* the message text was read from the Git binary and `git help config`; no repository owned by another user was available to trigger it.

## Summary

- Hooks are named executables in `.git/hooks` (or `core.hooksPath`); non-zero aborts most of them; `--no-verify` skips `pre-commit`, `commit-msg` and `pre-push`. They are local; enforce policy server-side.
- `.gitattributes` assigns per-path behaviour: `text`/`eol`, `binary`, `diff`/`textconv`, `merge` drivers (`union`, custom), `filter` clean/smudge, `export-ignore`. Check with `git check-attr`, `git ls-files --eol`.
- Config has system/global/local/worktree/command-line scopes; `--show-origin` explains any value; `include`/`includeIf` split config; aliases (`!` for shell) shorten commands.
- Use `.git/info/exclude` and `core.excludesFile` for ignore rules that shouldn't be committed; the nearest `.gitignore` takes precedence over both.
- `safe.directory` (global or system config only) lists repositories owned by other users that you trust.

## Exercises

Solutions: [`examples/ch15/exercises.sh`](examples/ch15/exercises.sh).

1. Write a `pre-commit` hook that refuses to commit files larger than 100 KB. Test it with a dummy file.

   <details><summary>Solution</summary>

   `.git/hooks/pre-commit` (`chmod +x`):

   ```sh
   #!/bin/sh
   big=$(git diff --cached --name-only --diff-filter=AM | while read -r f; do
     [ "$(git cat-file -s ":$f")" -gt 102400 ] && echo "$f"; done)
   [ -z "$big" ] || { echo "pre-commit: too big: $big" >&2; exit 1; }
   ```

   ```console
   $ head -c 200000 /dev/zero > big.dat; git add big.dat; git commit -q -m "add big"; echo rc=$?
   pre-commit: too big: big.dat
   rc=1
   $ git rm -q --cached big.dat; echo small > small.txt; git add small.txt; git commit -q -m "add small"; echo rc=$?
   rc=0
   ```

   `git cat-file -s ":$f"` measures the *staged* blob, not the work-tree file. The names are collected into a variable because an `exit` inside a pipe-fed `while` loop only leaves the subshell.

   </details>

2. Make `git diff` show `.json` files pretty-printed, using `python3 -m json.tool`.

   <details><summary>Solution</summary>

   With `*.json diff=json` in `.gitattributes`, and `{"a":1}` committed in `c.json`:

   ```console
   $ git config diff.json.textconv "python3 -m json.tool"; echo "{\"a\":2,\"b\":[1]}" > c.json; git diff c.json | tail -n +5
   @@ -1,3 +1,6 @@
    {
   -    "a": 1
   +    "a": 2,
   +    "b": [
   +        1
   +    ]
    }
   ```

   </details>

3. Use `includeIf` so that repositories under `~/oss/` use a different email address.

   <details><summary>Solution</summary>

   With `~/.gitconfig-oss` containing `[user] email = ada@oss.example`:

   ```console
   $ git config --global includeIf."gitdir:~/oss/".path ~/.gitconfig-oss; git init -q ~/oss/proj; git -C ~/oss/proj config user.email; git config user.email
   ada@oss.example
   ada@example.com
   ```

   </details>

4. How can you tell exactly which file set `core.editor`?

   <details><summary>Solution</summary>

   ```console
   $ git config core.editor nano; git config --show-origin --show-scope --get core.editor
   local	file:.git/config	nano
   ```

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-15--hooks-attributes-and-config)
