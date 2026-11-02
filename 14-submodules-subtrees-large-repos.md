# Chapter 14 — Submodules, Subtrees and Large Repos

Real projects depend on other repositories, or grow so large that nobody wants all of them. This chapter covers the two ways to embed one repository in another (submodules and subtrees), and the tools for working with only part of a big repository: sparse-checkout, partial clones (chapter 13) and a mention of Git LFS. Previous: [Chapter 13 — Transport and Packfiles](13-transport-and-packfiles.md). Next: [Chapter 15 — Hooks, Attributes and Config](15-hooks-attributes-and-config.md).

Transcripts: [`examples/ch14/demo.sh`](examples/ch14/demo.sh) → `output.txt` (Git 2.34.1). `/home/you` replaces the scratch path. The script sets `protocol.file.allow=always` in its sandboxed global config: newer security fixes (also applied to Ubuntu's 2.34.1 package) block submodule clones over the local `file` transport by default, and these demos use local repositories as "remotes". Don't set that globally on a real machine.

## Submodules

A **submodule** is a normal repository checked out inside another one, with the outer repository (the *superproject*) recording **exactly which commit** of it to use. Setup: `libfoo` (two commits) and `app`.

```console
$ git submodule add ../libfoo vendor/foo 2>&1 | tail -3
Cloning into '/home/you/app/vendor/foo'...
done.
$ cat .gitmodules
[submodule "vendor/foo"]
	path = vendor/foo
	url = ../libfoo
$ git status -s
A  .gitmodules
A  vendor/foo
$ git ls-files -s vendor/foo .gitmodules
100644 f542d301c3d896e513252c40cb51504c89f1d35e 0	.gitmodules
160000 898cf323bc98488b64cfb622a7cedd5bd060f1ff 0	vendor/foo
```

Three things were created:

1. **`.gitmodules`** — a tracked config file: path → URL (a relative URL, resolved against the superproject's own remote URL).
2. **A gitlink**: an index/tree entry of mode **`160000`** whose "object" is a *commit of another repository*. The superproject's tree holds no content for that directory, just the pinned commit hash. (`git ls-tree` shows it as `commit`; see below.)
3. **The submodule's own repository**, with its git directory under the superproject's `.git/modules/`, and a `.git` *file* in the checkout pointing at it:

```console
$ git diff --cached --submodule
diff --git a/.gitmodules b/.gitmodules
new file mode 100644
index 0000000..f542d30
--- /dev/null
+++ b/.gitmodules
@@ -0,0 +1,3 @@
+[submodule "vendor/foo"]
+	path = vendor/foo
+	url = ../libfoo
Submodule vendor/foo 0000000...898cf32 (new submodule)
$ cat vendor/foo/.git; ls .git/modules
gitdir: ../../.git/modules/vendor/foo
vendor
$ git config --get-regexp "^submodule"
submodule.vendor/foo.url /home/you/libfoo
submodule.vendor/foo.active true
```

The last line is the submodule's own summary (`0000000` = not there before). Note the two copies of the URL: `.gitmodules` (shared, versioned) and `.git/config` (`submodule.<name>.url`, your local, activated copy; change one without the other and you get confusing results — `git submodule sync` copies `.gitmodules` URLs into config). After committing, the tree shows the directory as a tree whose only entry is a commit:

```console
$ git cat-file -p HEAD^{tree}
100644 blob f542d301c3d896e513252c40cb51504c89f1d35e	.gitmodules
100644 blob ba2906d0666cf726c7eaadd2cd3db615dedfdf3a	main.c
040000 tree b82df9a475e6fc739844b4f9c7e800dc6c79a74d	vendor
$ git submodule status
 898cf323bc98488b64cfb622a7cedd5bd060f1ff vendor/foo (heads/main)
```

(`vendor` is a tree; inside it the entry `foo` has mode 160000, `type commit`.) `submodule status` prefixes: space = in sync, `-` = not initialized, `+` = checked-out commit differs from the recorded one, `U` = merge conflicts.

### Cloning: nothing is fetched by default

A plain clone creates empty directories for submodules; `submodule update --init` fills them; `--recurse-submodules` does it in one go:

```console
$ git clone -q app app-clone; ls app-clone/vendor/foo | wc -l; git -C app-clone submodule status
0
-898cf323bc98488b64cfb622a7cedd5bd060f1ff vendor/foo
$ git -C app-clone submodule update --init 2>&1 | tail -2; git -C app-clone submodule status
done.
Submodule path 'vendor/foo': checked out '898cf323bc98488b64cfb622a7cedd5bd060f1ff'
 898cf323bc98488b64cfb622a7cedd5bd060f1ff vendor/foo (heads/main)
$ git clone -q --recurse-submodules app app-clone2 2>&1 | tail -1; ls app-clone2/vendor/foo
foo.c
foo.h
```

Add `--recursive` (`--init --recursive`) for nested submodules; `git config submodule.recurse true` makes many commands (`checkout`, `pull`, `diff`…) recurse.

### Updating a submodule

The submodule is checked out at a **detached `HEAD`** of the pinned commit. When upstream moves, you advance the pointer, then record it in the superproject with a normal commit:

```console
$ git submodule update --remote --merge 2>&1 | tail -2; git submodule status
 1 file changed, 1 insertion(+), 1 deletion(-)
Submodule path 'vendor/foo': merged in 'be7707b854afa0f67fe85cffcd6725830258c258'
+be7707b854afa0f67fe85cffcd6725830258c258 vendor/foo (remotes/origin/HEAD)
$ git status -s; git diff --submodule
 M vendor/foo
Submodule vendor/foo 898cf32..be7707b:
  > foo v2
$ git diff
diff --git a/vendor/foo b/vendor/foo
index 898cf32..be7707b 160000
--- a/vendor/foo
+++ b/vendor/foo
@@ -1 +1 @@
-Subproject commit 898cf323bc98488b64cfb622a7cedd5bd060f1ff
+Subproject commit be7707b854afa0f67fe85cffcd6725830258c258
$ git submodule summary HEAD~1 2>&1 | head -4
* vendor/foo 898cf32...be7707b (1):
  > foo v2

```

`+` in `submodule status` means the working submodule is ahead of the recorded commit; the superproject sees `M vendor/foo` and the plain diff is just two hashes. Config `diff.submodule=log` and `status.submoduleSummary` make this nicer. `git add vendor/foo && git commit` records the bump. Without `--remote`, `submodule update` checks out the commit *the superproject records*; with `--remote` it follows the branch named in `.gitmodules` (`submodule.<n>.branch`, default the remote's HEAD).

### Pitfalls

**Detached HEAD**: commits you make inside a submodule while detached are easy to lose. If you work inside it, create a branch first. Even then, an innocent `submodule update` returns to the *recorded* commit:

```console
$ git -C vendor/foo status -sb | head -1
## HEAD (no branch)
$ git -C vendor/foo switch -q -c work; echo "local edit" > vendor/foo/foo.c; git -C vendor/foo commit -qam "local commit"; git status -s
 M vendor/foo
$ git -C vendor/foo rev-parse --short HEAD; git ls-tree HEAD vendor/foo | cut -c1-60
df756ab
160000 commit be7707b854afa0f67fe85cffcd6725830258c258	vendo
$ git submodule update 2>&1 | tail -1; git -C vendor/foo status -sb | head -1
Submodule path 'vendor/foo': checked out 'be7707b854afa0f67fe85cffcd6725830258c258'
## HEAD (no branch)
```

The local commit `df756ab` is still on branch `work` inside the submodule, but the work tree went back to the pinned commit and detached — a classic "where did my change go?" moment. The superproject's tree entry shows mode `160000`, type `commit`, as promised.

**Forgetting to push the submodule first.** If you commit a bump in the superproject that points to a submodule commit you never pushed, everyone else's `submodule update` fails with "not our ref". Guard with `git push --recurse-submodules=check` (refuses) or `=on-demand` (pushes submodules first), or the config `push.recurseSubmodules`. In the transcript below no submodule commits were unpushed, so the check passes:

```console
$ git config push.recurseSubmodules; git push --recurse-submodules=check origin HEAD:refs/heads/x 2>&1 | head -3
To /home/you/app
 * [new branch]      HEAD -> x
```

**Other traps**: `git clone` without `--recurse-submodules` leaves empty directories; switching branches doesn't update submodules unless `submodule.recurse` or `git submodule update`; relative `url`s break when the superproject remote moves in unexpected ways; a dirty submodule shows as modified (`-dirty` in `git describe`); merging two bumps of the same submodule is a conflict on the pointer.

**Removing** takes several steps, and Git leaves the repository data behind on purpose:

```console
$ git submodule deinit -f vendor/foo 2>&1; git rm -q -f vendor/foo; ls vendor 2>&1; cat .gitmodules 2>&1 | wc -c; ls .git/modules
Cleared directory 'vendor/foo'
Submodule 'vendor/foo' (../libfoo) unregistered for path 'vendor/foo'
0
vendor
```

`deinit` unregistered it, `git rm` deleted the gitlink and edited `.gitmodules` (now empty, 0 bytes); the copy under `.git/modules/` remains until you `rm -rf .git/modules/vendor/foo` (so re-adding is fast, and nothing is lost).

## Subtrees: copy it in

`git subtree` (a `contrib` script shipped with Git, here at `/usr/lib/git-core/git-subtree`) takes the opposite approach: the other project's files are **ordinary files in your tree**, in a subdirectory. Everyone just clones and gets them; there is no `.gitmodules`, no pointer, no extra commands for consumers.

```console
$ git subtree 2>&1 | head -2; ls $(git --exec-path)/git-subtree 2>&1 | head -1
usage: git subtree add   --prefix=<prefix> <commit>
   or: git subtree add   --prefix=<prefix> <repository> <ref>
/usr/lib/git-core/git-subtree
$ git subtree add --prefix=lib/foo ../libfoo main --squash 2>&1 | tail -2
 * branch            main       -> FETCH_HEAD
Added dir 'lib/foo'
$ ls lib/foo; git log --oneline -3
foo.c
foo.h
8f8c361 Merge commit '8cb8f25ec35dde2aacddbe73b31f9c8ae614337d' as 'lib/foo'
07abe87 drop submodule
8cb8f25 Squashed 'lib/foo/' content from commit be7707b
$ git log -1 --format=%B HEAD^2 | head -5
Squashed 'lib/foo/' content from commit be7707b

git-subtree-dir: lib/foo
git-subtree-split: be7707b854afa0f67fe85cffcd6725830258c258
```

The `--squash` form brings the other history in as **one** commit with a trailer (`git-subtree-dir`, `git-subtree-split`) that remembers the origin commit, then merges it under the prefix (the "Merge commit … as 'lib/foo'" line; it uses the `subtree` machinery of chapter 9). `git subtree pull --prefix=lib/foo <repo> <ref> --squash` updates; `git subtree push` (or `split`) extracts commits touching the prefix back into a standalone history so you can send changes upstream. Drawbacks: subtree commands are slower on large histories, you must remember the prefix and URL (no `.gitmodules`), and a project can end up with duplicate, hard-to-track vendored history.

| | Submodule | Subtree |
|---|---|---|
| Content stored | pointer to commit of another repo | files copied into your history |
| Consumers must | `submodule update --init` | nothing |
| Pin version | exact commit, explicit | whatever you last merged |
| Contribute back | work inside the submodule repo | `subtree push` / `split` |
| Repo size | small | includes the other project's content |

A third option is a package manager or plain `read-tree --prefix=` vendoring (chapter 9).

## Sparse-checkout: only part of the work tree

For a monorepo you can keep the full history but check out only some directories. Four directories (`api`, `web`, `docs`, `tools`, three files each) plus a top-level `README`:

```console
$ git sparse-checkout init --cone; git sparse-checkout set api docs; ls; cat .git/info/sparse-checkout
README
api
docs
/*
!/*/
/api/
/docs/
$ git sparse-checkout list; git config core.sparseCheckout; git ls-files -v | grep -c "^S"
api
docs
true
6
$ git sparse-checkout add web; ls
README
api
docs
web
$ git sparse-checkout disable; ls
README
api
docs
tools
web
```

In **cone mode** you give *directories* and Git keeps all top-level files plus the listed directories (and their parents' files); the pattern file `/*  !/*/  /api/  /docs/` means "all top-level files, no top-level dirs, except api and docs". `git ls-files -v` marks files outside the cone `S` (6 here, the `tools` and `web` files) — they stay in the index, with the skip-worktree bit set, but are not written to disk. Non-cone mode accepts arbitrary `.gitignore`-style patterns (discouraged in newer documentation; slower). `sparse-checkout disable` restores everything.

**Combine with a partial clone** to avoid even downloading what you don't need (`--sparse` limits the initial checkout to top-level files; `--filter=blob:none` fetches blobs on demand):

```console
$ git clone -q --filter=blob:none --sparse file://$PWD ../mono-partial; cd ../mono-partial; git sparse-checkout set api; ls; git config --get-regexp "^(core.sparse|extensions|remote.origin.(promisor|partial))"; cd ../mono
api
remote.origin.promisor true
remote.origin.partialclonefilter blob:none
extensions.worktreeconfig true
core.sparsecheckout true
```

Notice that `README` is missing from `ls`: on Git 2.34, `sparse-checkout set` in a repository where you did not run `init --cone` uses *non-cone* pattern mode (just `api`). Cone mode as the default for `set`/`--sparse` arrived in 2.37; on 2.34 run `git sparse-checkout init --cone` first. Beware: `set --cone` only exists from 2.35, and 2.34 silently takes `--cone` as a *pattern* (see the transcript below). (The `extensions.worktreeConfig` line is created because sparse settings are stored per-worktree.) The `uploadpack.allowFilter` option was enabled on the demo "server"; without it Git warns and clones everything (last command below).

Related: the **sparse index** (`index.sparse`, `git sparse-checkout init --cone --sparse-index`, added in 2.32 as experimental; 2.33 and 2.34 taught more commands to use it) shrinks the index itself by collapsing each out-of-cone directory into a single entry naming a tree. Commands not yet taught about it expand it to a full index in memory, so `git ls-files` still lists every file; the raw file shows the difference:

```console
$ git sparse-checkout init --cone --sparse-index; git sparse-checkout set docs; git config index.sparse; tr -c "[:print:]" "\n" < .git/index | grep -E "^(README|[a-z]+/)"
true
README
api/
docs/f1.txt
docs/f2.txt
docs/f3.txt
tools/
web/
$ git sparse-checkout disable; git sparse-checkout set --cone docs; cat .git/info/sparse-checkout; git sparse-checkout disable
--cone
docs
$ git config uploadpack.allowFilter false; git clone -q --filter=blob:none file://$PWD ../no-filter 2>&1 | head -1
warning: filtering not recognized by server, ignoring
```

`api/`, `tools/` and `web/` are single index entries (directory names with a trailing slash). The second command shows the 2.34 `set --cone` trap. `git clone --filter=tree:0` is for very large repos (chapter 13).

## Git LFS

**Git LFS** ("Large File Storage") is a separate extension (a `git-lfs` binary and server support) that replaces big binary files in commits with small *pointer files* via clean/smudge filters and `.gitattributes` (`*.psd filter=lfs diff=lfs merge=lfs -text`, chapter 15); the real bytes live on an LFS server. It is not part of Git and is not installed here:

```console
$ git lfs version 2>&1 | head -1
git: 'lfs' is not a git command. See 'git --help'.
```

*Unverified:* LFS itself was not run for this course. Alternatives for big data: partial clones, `git-annex`, or not storing it in Git at all.

## Summary

- A submodule = separate repository + gitlink (mode `160000`) pinning one commit + `.gitmodules` + a copy under `.git/modules/`. Clone with `--recurse-submodules`; update with `submodule update [--remote]`; commit the bump.
- Pitfalls: detached HEAD, unpushed submodule commits (`push --recurse-submodules`), stale URLs, leftover `.git/modules`.
- `git subtree` vendors another project's files into yours; consumers need nothing, but history gets heavier.
- Sparse-checkout limits the work tree (cone mode = directories), skip-worktree files stay in the index (`S`); combined with `--filter=blob:none` it limits downloads too. On 2.34 cone mode must be requested with `init --cone` (`set --cone` needs 2.35).
- LFS is a separate tool built on filters; not run here.

## Exercises

Solutions: [`examples/ch14/exercises.sh`](examples/ch14/exercises.sh) (local repositories `foo`, `app` and `mono`; `protocol.file.allow=always` in the sandboxed global config, as in the demo).

1. Add a submodule at `libs/foo` from a local repository, commit it, and show which commit the superproject pins, using plumbing.

   <details><summary>Solution</summary>

   ```console
   $ git submodule add -q ../foo libs/foo; git commit -q -m "add foo"
   $ git ls-tree HEAD libs/; git ls-tree HEAD libs/foo; git ls-files -s libs/foo
   160000 commit f84bbf124a99bc2d32969d3f27ef2a2bc6600344	libs/foo
   160000 commit f84bbf124a99bc2d32969d3f27ef2a2bc6600344	libs/foo
   160000 f84bbf124a99bc2d32969d3f27ef2a2bc6600344 0	libs/foo
   ```

   A path argument without a trailing slash shows the entry itself; `libs/` lists the directory's contents, here only the gitlink.

   </details>

2. Clone a repository that has submodules so that they are populated immediately.

   <details><summary>Solution</summary>

   ```console
   $ git clone -q --recurse-submodules app app2 2>&1; git -C app2 submodule status
    f84bbf124a99bc2d32969d3f27ef2a2bc6600344 libs/foo (heads/main)
   ```

   For an existing clone: `git submodule update --init --recursive`.

   </details>

3. In a submodule, commit while detached, then bump the superproject. What must happen before pushing the superproject?

   <details><summary>Solution</summary>

   The submodule commit must reach the submodule's remote first, from a branch. `--recurse-submodules=check` refuses until it has:

   ```console
   $ git push --recurse-submodules=check origin main 2>&1 | head -3
   The following submodule paths contain changes that can
   not be found on any remote:
     libs/foo
   $ git -C libs/foo switch -q -c fix; git -C libs/foo push -q -u origin fix 2>&1; git push --recurse-submodules=check origin main 2>&1 | tail -1
    * [new branch]      main -> main
   ```

   `--recurse-submodules=on-demand` runs a push inside the submodule first, but with the superproject's refspec (`main` here). In a test where the new submodule commit was on a detached `HEAD` or on another branch, it printed `Pushing submodule 'libs/foo'`, `Everything up-to-date` and then failed exactly like `check`. Pushing the submodule branch explicitly, as above, always works.

   </details>

4. Check out only the `docs` directory of a repository using sparse-checkout, then restore the full tree.

   <details><summary>Solution</summary>

   ```console
   $ git sparse-checkout init --cone; git sparse-checkout set docs; ls
   README
   docs
   $ git sparse-checkout disable; ls
   README
   api
   docs
   web
   ```

   Cone mode always keeps top-level files such as `README`.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-14--submodules-subtrees-and-large-repos)
