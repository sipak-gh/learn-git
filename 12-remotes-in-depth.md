# Chapter 12 — Remotes in Depth

A remote is nothing more than a named URL plus a few lines of configuration saying which refs to copy where. This chapter takes `fetch`, `pull` and `push` apart: refspecs, remote-tracking branches, upstream configuration, safe forced pushes, pruning, several remotes, the fork ("triangular") workflow, and the transports and credential helpers behind the URLs. Previous: [Chapter 11 — Stash, Worktrees and Cleaning](11-stash-worktrees-and-cleaning.md). Next: [Chapter 13 — Transport and Packfiles](13-transport-and-packfiles.md).

All experiments use **local bare repositories** as "servers" (`git init --bare origin.git`), so you can reproduce everything without a network. Transcripts: [`examples/ch12/demo.sh`](examples/ch12/demo.sh) → `output.txt` (Git 2.34.1). Scratch paths are shortened to `/home/you/…`. The script has two clones, `alice` and `bob`, of the same `origin.git`.

## What `clone` configured

```console
$ git config --get-regexp "^(remote|branch)"
remote.origin.url /home/you/origin.git
remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
branch.main.remote origin
branch.main.merge refs/heads/main
$ git remote -v
origin	/home/you/origin.git (fetch)
origin	/home/you/origin.git (push)
$ git remote show origin
* remote origin
  Fetch URL: /home/you/origin.git
  Push  URL: /home/you/origin.git
  HEAD branch: main
  Remote branch:
    main tracked
  Local branch configured for 'git pull':
    main merges with remote main
  Local ref configured for 'git push':
    main pushes to main (up to date)
```

Two sections of `.git/config`:

- `[remote "origin"]`: `url` (where) and `fetch` (the **refspec**, what to copy and where to store it).
- `[branch "main"]`: `remote` and `merge` — together the branch's **upstream**, used by argument-less `pull`, `push`, `status` and `branch -vv`.

`git remote show origin` contacts the server; `git remote` alone just lists names.

## Remote-tracking branches

`origin/main` is a local, read-only-by-convention ref under `refs/remotes/origin/` recording where `main` was on the server *the last time you talked to it*. Only `fetch`/`pull`/`push` update it:

```console
$ git branch -a -vv
* main                0562fb0 [origin/main] initial
  remotes/origin/HEAD -> origin/main
  remotes/origin/main 0562fb0 initial
$ git for-each-ref refs/remotes
0562fb0b149b46dca0dfcaf26ff15ab0c80b1507 commit	refs/remotes/origin/HEAD
0562fb0b149b46dca0dfcaf26ff15ab0c80b1507 commit	refs/remotes/origin/main
$ cat .git/refs/remotes/origin/HEAD
ref: refs/remotes/origin/main
```

`origin/HEAD` is a symbolic ref set by `clone` to the server's default branch (`git remote set-head origin -a` re-detects it; if you clone an *empty* repository there is none). You can't commit "onto" `origin/main`: checking it out gives a detached `HEAD` (chapter 6). A **local branch** (`main`) *tracks* it by upstream configuration.

## Refspecs

A refspec is `[+]<src>:<dst>`. For **fetch**, `src` is a ref on the remote and `dst` a local ref; `+` allows non-fast-forward updates; `*` matches any string, slashes included, so `feature/x` arrives as `origin/feature/x`. The default `+refs/heads/*:refs/remotes/origin/*` means "every remote branch → remote-tracking branch under `origin/`". Look at what the server has, and try a custom fetch refspec:

```console
$ git ls-remote origin
0562fb0b149b46dca0dfcaf26ff15ab0c80b1507	HEAD
0562fb0b149b46dca0dfcaf26ff15ab0c80b1507	refs/heads/main
$ git fetch origin "refs/heads/main:refs/remotes/origin/copy" 2>&1; git branch -r
From /home/you/origin
 * [new branch]      main       -> origin/copy
  origin/HEAD -> origin/main
  origin/copy
  origin/main
$ git fetch origin main 2>&1; cat .git/FETCH_HEAD
From /home/you/origin
 * branch            main       -> FETCH_HEAD
0562fb0b149b46dca0dfcaf26ff15ab0c80b1507		branch 'main' of /home/you/origin
```

With no destination in the command-line refspec, the result is recorded only in `FETCH_HEAD` (chapter 6; `git merge FETCH_HEAD` consumes it). For **push**, `src` is a local ref and `dst` the remote ref: `git push origin HEAD:refs/heads/from-alice` creates a branch from whatever is checked out, and an *empty* source deletes:

```console
$ git push origin HEAD:refs/heads/from-alice 2>&1 | tail -1
 * [new branch]      HEAD -> from-alice
$ git push origin :from-alice 2>&1 | tail -1
 - [deleted]         from-alice
$ git push --dry-run origin main 2>&1
Everything up-to-date
```

`git push origin --delete <branch>` is the readable spelling of `:<branch>`. Config can hold several `fetch =`/`push =` lines per remote (for example `fetch = +refs/pull/*/head:refs/remotes/origin/pr/*` on GitHub-style servers). That pull-request refspec was tested only against a local bare repository holding a hand-pushed `refs/pull/1/head`, which fetched as `* [new ref] refs/pull/1/head -> origin/pr/1`; not against GitHub itself.

## `fetch` vs `pull`

`fetch` downloads objects and updates remote-tracking refs; it never touches your branches or work tree. `pull` = `fetch` + integrate (`merge` by default, `rebase` with `--rebase` / `pull.rebase`). Prefer `fetch` then look:

```console
$ git fetch
From /home/you/origin
   0562fb0..e812d16  main       -> origin/main
$ git status -sb
## main...origin/main [behind 1]
$ git log --oneline main..origin/main
e812d16 bob work
$ git pull --ff-only
Updating 0562fb0..e812d16
Fast-forward
 bob.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 bob.txt
```

(`main..origin/main` is chapter 7's range: commits the server has that you don't.) `pull --ff-only` refuses anything but a fast-forward; set it as default with `git config --global pull.ff only`. Unconfigured `git pull` on 2.34.1 with diverged branches **refuses**: it prints `hint: You have divergent branches and need to specify how to reconcile them.`, lists the three settings, and ends with `fatal: Need to specify how to reconcile divergent branches.` (older Gits merged with a warning). Pick `pull.rebase` or `pull.ff` explicitly.

## Rejected pushes

A push is accepted only if it's a **fast-forward** of the remote ref (the old tip is an ancestor of what you send). Otherwise:

```console
$ git push origin main
To /home/you/origin.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '/home/you/origin.git'
hint: Updates were rejected because the remote contains work that you do
hint: not have locally. This is usually caused by another repository pushing
hint: to the same ref. You may want to first integrate the remote changes
hint: (e.g., 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
$ git fetch -q; git status -sb | head -1
## main...origin/main [ahead 1, behind 1]
$ git pull --rebase 2>&1 | tail -1
Rebasing (1/1)Successfully rebased and updated refs/heads/main.
$ git push origin main 2>&1 | tail -2
To /home/you/origin.git
   06cd7f9..86e4d74  main -> main
```

"fetch first" means the server has commits you haven't fetched; "non-fast-forward" means you have fetched them but your history doesn't contain them. Rebase or merge, then push.

## `--force-with-lease`

If you rewrote already-pushed commits (your own topic branch; chapter 10), the push must be forced. Plain `--force` overwrites whatever is there, including a colleague's commit you never saw. `--force-with-lease` forces only if the remote ref is still what your remote-tracking branch says it is:

```console
$ git push --force-with-lease origin main 2>&1 | tail -2
To /home/you/origin.git
 + 86e4d74...ac03d70 main -> main (forced update)
```

Then Bob pushes on top of that; Alice (who has *not* fetched) amends again and tries once more:

```console
$ git push --force-with-lease origin main 2>&1 | tail -4
To /home/you/origin.git
 ! [rejected]        main -> main (stale info)
error: failed to push some refs to '/home/you/origin.git'
```

Rejected as `stale info`: the server's `main` is not where Alice last saw it. She can fetch, look at Bob's commit, and decide. (Caveat: if a background process or an IDE auto-fetches, your lease is silently refreshed and the safety is lost; pin it explicitly with `--force-with-lease=main:<expected-hash>`, or add `--force-if-includes` (Git 2.30+), which additionally requires that the remote-tracking tip has been integrated into your local branch: after a background `git fetch -q`, `git push --force-with-lease --force-if-includes origin main` is rejected with `(remote ref updated since checkout)`, while a plain `--force-with-lease` would go through. See exercise 4.)

```console
$ git fetch -q; git reset -q --hard origin/main; git log --oneline -3
bb904f1 bob third
ac03d70 alice local (amended)
06cd7f9 bob second
```

## Upstream tracking

`git push` with no arguments needs to know where; for a new branch it has no idea:

```console
$ git switch -c feature
Switched to a new branch 'feature'
$ git push 2>&1 | head -3
fatal: The current branch feature has no upstream branch.
To push the current branch and set the remote as upstream, use

$ git push -u origin feature 2>&1 | tail -2
 * [new branch]      feature -> feature
Branch 'feature' set up to track remote branch 'feature' from 'origin'.
$ git branch -vv
* feature 257cfb3 [origin/feature] feature
  main    bb904f1 [origin/main] bob third
```

`-u` (`--set-upstream`) writes `branch.feature.remote/merge`. Change one later with `git branch -u origin/main f2` (and `git rev-parse --abbrev-ref f2@{upstream}` prints it):

```console
$ git branch -u origin/main f2; git rev-parse --abbrev-ref f2@{upstream}
Branch 'f2' set up to track remote branch 'main' from 'origin'.
origin/main
```

`push.default` (unset here, so Git uses `simple` — push the current branch to the same-named upstream branch, refusing if names differ) controls what bare `git push` does. **Version caveat:** `push.autoSetupRemote` (auto `-u` for new branches) was added in Git **2.37**. On 2.34.1 the setting is silently ignored, as this run shows:

```console
$ git config push.autoSetupRemote true; git switch -q -c f2; echo f2 > f2; git add .; git commit -q -m f2; git push 2>&1 | head -2
fatal: The current branch f2 has no upstream branch.
To push the current branch and set the remote as upstream, use
```

## Deleting and pruning

Deleting a branch on the server does not delete your `origin/<branch>`; stale remote-tracking refs pile up until you prune. Bob ran `git push origin --delete feature` (printing ` - [deleted]         feature`). Alice still sees it:

```console
$ git branch -r
  origin/HEAD -> origin/main
  origin/copy
  origin/feature
  origin/main
$ git fetch --prune 2>&1; git branch -r
From /home/you/origin
 - [deleted]         (none)     -> origin/copy
 - [deleted]         (none)     -> origin/feature
  origin/HEAD -> origin/main
  origin/main
$ git config fetch.prune true; git config --get fetch.prune
true
```

Pruning removed `origin/copy` too — it matched the fetch refspec but no longer existed on the server. `git remote prune origin` does the prune without fetching; `git remote prune --dry-run`/`git fetch --prune --dry-run` show what would go. Your *local* `feature` branch is untouched.

## Tags and remotes

`push` sends no tags by default (and `fetch` only brings tags that point into fetched history). Annotated tags are separate objects, visible in `ls-remote` with a peeled `^{}` line:

```console
$ git push origin v1 2>&1 | tail -1
 * [new tag]         v1 -> v1
$ git ls-remote --tags origin
95dd6d8842e5e948e5f2b3cc9d124b659e60bbb3	refs/tags/v1
13806b8a086a54f782fafbf5fa951853082ab003	refs/tags/v1^{}
$ git push origin --tags 2>&1 | tail -1
Everything up-to-date
```

`--follow-tags` pushes annotated tags reachable from what you push; there is no "tracking" for tags and they don't prune with branches (`git fetch --prune --prune-tags`, `--tags` for fetch).

## Several remotes, forks and the triangular workflow

A project you don't own is typically used through a *fork*: you **fetch** from the canonical repository (`upstream`) and **push** to your copy (`origin`). Configuration makes plain `git pull`/`git push` do that:

```console
$ git remote add upstream ../upstream.git; git remote -v
origin	/home/you/origin.git (fetch)
origin	/home/you/origin.git (push)
upstream	../upstream.git (fetch)
upstream	../upstream.git (push)
$ git config remote.pushDefault origin; git config --get remote.pushDefault
origin
$ git fetch upstream 2>&1; git branch -r
From ../upstream
 * [new branch]      main       -> upstream/main
  origin/HEAD -> origin/main
  origin/main
  upstream/main
$ git remote rename upstream canon; git branch -r | tr "\n" " "
  canon/main   origin/HEAD -> origin/main   origin/main $ git remote set-url origin ../origin.git; git remote get-url origin
../origin.git
$ git remote remove canon; git branch -r | tr "\n" " "
  origin/HEAD -> origin/main   origin/main 
```

(The transcript's lines run together because of `tr "\n" " "` without a trailing newline.) Typical fork setup: `git clone <your-fork>`; `git remote add upstream <canonical>`; branch `main` with `branch.main.remote=upstream` (pull from the canonical project) and `remote.pushDefault=origin` (push to your fork); open a pull request from the fork's branch. `remote.<name>.pushurl` gives a separate push URL; `git remote rename/remove` also migrate/delete the tracking refs and config, as shown. `pull.rebase` + `fetch upstream` + `git rebase upstream/main` keeps a topic branch current. With several remotes, `git fetch --all` (or `git remote update`) fetches each in turn (`Fetching origin`, `Fetching second`, …).

A push that updates several refs is normally applied ref by ref, so some may succeed while others are rejected. `git push --atomic` asks the server to apply all or none. In a separate test, `git push --atomic origin main main:refs/heads/b3`, with `main` behind the server, printed `! [rejected] main -> main (non-fast-forward)` and `! [rejected] main -> b3 (atomic push failed)`, and `b3` was not created.

## Transports and URLs

Git speaks to the other end with one of:

| URL form | Transport |
|----------|-----------|
| `/path/to/repo.git`, `file:///path` | local (spawns `git-upload-pack`/`git-receive-pack`; a plain path lets `clone` hard-link or copy the object files directly; `file://`, or `clone --no-local`, forces the regular pack protocol) |
| `ssh://user@host/path.git`, `user@host:path.git` | SSH; authentication is entirely SSH's (keys, agent, `~/.ssh/config`) |
| `https://host/path.git` | "smart" HTTP; credentials via credential helpers or tokens |
| `git://host/path.git` | unauthenticated daemon, read-only in practice |

Chapter 13 shows what travels over them. Only local paths were exercised for this course; *unverified:* SSH and HTTPS need servers and were not run. Rewriting URLs (e.g. to force SSH or use a mirror) is done with `insteadOf`:

```console
$ git config url."https://example.invalid/".insteadOf "ex:"; git remote add tmp ex:foo.git; git remote get-url tmp
https://example.invalid/foo.git
```

(`pushInsteadOf` rewrites only for pushing.) The `.invalid` domain is reserved and never resolves.

### Credential helpers

For HTTPS, Git runs *credential helpers* with a small key=value protocol on stdin/stdout (`git credential fill`, `approve`, `reject`). Built-ins: `cache` (in-memory with timeout), `store` (plaintext file `~/.git-credentials`, **insecure**), plus platform helpers (libsecret, osxkeychain, `manager` for Windows/GCM) and custom ones named `git-credential-<name>`. Set with `credential.helper`; scope with `credential.<url>.username`. Demonstration with the `store` helper pointed at a scratch file (the password is a made-up string; note that `fill` prints it in plain text):

```console
$ git config credential.helper; git credential-store 2>&1 | head -1
usage: git credential-store [<options>] <action>
$ wc -l < .git/cred
1
$ printf "protocol=https\nhost=example.com\n\n" | git -c credential.helper="store --file=$PWD/.git/cred" credential fill
protocol=https
host=example.com
username=ada
password=pw-example-123
```

(`credential approve` had written the single line to `.git/cred` beforehand. `git config credential.helper` printed nothing: no helper is configured by default here.) For SSH remotes use `ssh-agent`, not Git.

## Local bare repositories as a lab

Everything in this chapter works with `git init --bare` directories: a bare repository has no work tree, only what would be in `.git`, which is why servers use them. Cloning from it is cheap, and two or three clones let you rehearse collisions without risk. `git clone --bare` / `--mirror` copy a repository (the latter also all refs, for backups; `git push --mirror` overwrites the destination's refs entirely).

## Summary

- A remote = URL + fetch refspec (+ optional push settings). `origin/<branch>` are local remote-tracking refs updated only when you talk to the server.
- Refspecs `[+]src:dst` drive both fetch and push; an empty source deletes; `FETCH_HEAD` records the last fetch.
- `pull` is fetch + merge/rebase; prefer `fetch`, inspect `main..origin/main`, then integrate; set `pull.rebase` or `pull.ff`.
- Pushes must fast-forward; `--atomic` makes a multi-ref push all-or-nothing. Use `--force-with-lease` (plus `--force-if-includes` if anything fetches in the background; never bare `--force`) for rewritten branches.
- Upstream = `branch.<n>.remote/merge`, set with `-u`; `push.autoSetupRemote` needs 2.37+.
- `fetch --prune` / `fetch.prune` removes stale remote-tracking branches.
- Forks: fetch from `upstream`, push to `origin` via `remote.pushDefault`.
- Credential helpers speak a key=value protocol; `store` is plaintext.

## Exercises

Solutions: [`examples/ch12/exercises.sh`](examples/ch12/exercises.sh) (clones `alice` and `bob` of a local bare `origin.git`; Bob pushed an annotated tag `t-side` on a branch he then deleted).

1. Make `git fetch` also fetch all the server's tags into `refs/tags` and prune deleted branches automatically for `origin`, via config only.

   <details><summary>Solution</summary>

   ```console
   $ git config remote.origin.tagOpt --tags; git config remote.origin.prune true
   $ git fetch 2>&1; git tag
   From /home/you/origin
    * [new tag]         t-side     -> t-side
   t-side
   ```

   `t-side` points at a commit not reachable from any branch, so default tag following would not have fetched it. `fetch.prune true` is the all-remotes variant of `remote.origin.prune`.

   </details>

2. Push a local branch `wip` to a remote branch named `review/wip` without creating a local branch of that name.

   <details><summary>Solution</summary>

   ```console
   $ git push origin wip:refs/heads/review/wip 2>&1 | tail -1; git branch --list "review*"; git ls-remote origin "refs/heads/review/*"
    * [new branch]      wip -> review/wip
   e579e11e687d5841b0ebba728725d04e100ea607	refs/heads/review/wip
   ```

   `git branch --list "review*"` prints nothing: only the remote got the name.

   </details>

3. Show which commits you would push on `main`, before pushing.

   <details><summary>Solution</summary>

   ```console
   $ git fetch -q; git log --oneline origin/main..main
   07c5689 local 1
   $ git push --dry-run origin main 2>&1
   To /home/you/origin.git
      e64cd35..07c5689  main -> main
   ```

   </details>

4. A colleague pushed after your last fetch and you have rewritten (amended) your already-pushed commit. Show that `--force-with-lease` refuses, that it stops refusing after a fetch unless you add `--force-if-includes`, and what plain `--force` does.

   <details><summary>Solution</summary>

   ```console
   $ git push --force-with-lease origin main 2>&1 | grep "^ !"
    ! [rejected]        main -> main (stale info)
   $ git fetch -q; git push --force-with-lease --force-if-includes origin main 2>&1 | grep "^ !"
    ! [rejected]        main -> main (remote ref updated since checkout)
   $ git push --force origin main 2>&1 | tail -1; git log --oneline -2 origin/main
    + 27b6fab...047fa74 main -> main (forced update)
   047fa74 local 1 (amended)
   e64cd35 initial
   ```

   After the fetch, plain `--force-with-lease` would succeed because the lease now matches. `--force` succeeded and Bob's commit `bob work` is gone from the server: exactly the accident the other two options prevent.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-12--remotes-in-depth)
