# Chapter 16 — Collaboration and Patches

Git was built for mailing-list collaboration, and the patch tools are still the lowest-common-denominator transport: a patch is just a commit rendered as text. This chapter covers `format-patch`/`am`/`apply`, pull requests, branching models, commit messages, signing (GPG and SSH), notes and `git archive`. Previous: [Chapter 15 — Hooks, Attributes and Config](15-hooks-attributes-and-config.md). Next: [Chapter 17 — Debugging and Recovery](17-debugging-and-recovery.md).

All transcripts come from [`examples/ch16/demo.sh`](examples/ch16/demo.sh) (Git 2.34.1). Paths are shortened. Hashes are reproducible by running the script, except in the signing section: every run generates fresh GPG and SSH keys, so key IDs, signatures and the hashes of signed commits differ each time.

## format-patch: commits as mbox files

`git format-patch` writes one email-shaped file per commit. Author, date and message are preserved in the headers; the `From <sha>` line is only a marker.

```console
$ git format-patch -o ../patches main..topic
../patches/0001-Add-g.patch
../patches/0002-Edit-f.patch
$ cat ../patches/0001-*.patch
From 1334081ef6203f8df1d207325b148c3616e65042 Mon Sep 17 00:00:00 2001
From: Ada Lovelace <ada@example.com>
Date: Mon, 1 Jan 2024 03:00:00 +0000
Subject: [PATCH 1/2] Add g

Longer explanation of why g exists.
---
 g.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 g.txt

diff --git a/g.txt b/g.txt
new file mode 100644
index 0000000..5dc279d
--- /dev/null
+++ b/g.txt
@@ -0,0 +1 @@
+gee
-- 
2.34.1

$ git format-patch --cover-letter -o ../p2 main..topic >/dev/null; ls ../p2
0000-cover-letter.patch
0001-Add-g.patch
0002-Edit-f.patch
```

Useful options: `-1 <rev>` (one commit), `--stdout`, `--cover-letter` (a `0000` file you fill in), `-v2` (re-roll, `[PATCH v2]`), `--base=auto` (record the base commit).

## apply vs am

- `git apply` applies a diff to the **working tree** (or `--index`/`--cached`); it makes no commit. `--stat` and `--check` are dry runs.
- `git am` applies mbox patches **as commits**, preserving author and message.

```console
$ git apply --stat ../patches/0001-*.patch
 g.txt |    1 +
 1 file changed, 1 insertion(+)
$ git apply --check ../patches/0001-*.patch; echo rc=$?
rc=0
$ git am ../patches/*.patch
Applying: Add g
Applying: Edit f
$ git log --format="%h %an %ad | %cn %cd | %s" --date=short -3
6d36ed4 Ada Lovelace 2024-01-01 | Ada Lovelace 2024-01-01 | Edit f
eedd601 Ada Lovelace 2024-01-01 | Ada Lovelace 2024-01-01 | Add g
42e0eb9 Ada Lovelace 2024-01-01 | Ada Lovelace 2024-01-01 | Initial
```

The hashes differ from the originals (`1334081`) because `am` makes new commits: the author, author date and message come from the patch, but the committer and committer date are whoever runs `am`, now (the `--date=short` output hides that the script's clock had moved on an hour), and once the first hash changes every child's `parent` line changes too. A patch carries content, not identity.

### When the patch does not apply

```console
$ git am ../patches/0002-*.patch 2>&1; echo rc=$?
error: patch failed: f.txt:1
error: f.txt: patch does not apply
hint: Use 'git am --show-current-patch=diff' to see the failed patch
Applying: Edit f
Patch failed at 0001 Edit f
When you have resolved this problem, run "git am --continue".
If you prefer to skip this patch, run "git am --skip" instead.
To restore the original branch and stop patching, run "git am --abort".
rc=128
$ git am --abort; git status -sb | head -1
## main
$ git am --3way ../patches/0002-*.patch 2>&1 | head -4
Applying: Edit f
Using index info to reconstruct a base tree...
M	f.txt
Falling back to patching base and 3-way merge...
```

`--3way` uses the `index abc..def` lines in the patch to find the blobs, rebuilds the base, and does a real merge, so conflicts appear as normal markers (resolve, `git add`, `git am --continue`). The recovery verbs are `--continue`, `--skip`, `--abort`.

`git apply --reject` applies what it can and writes the failed hunks to `.rej` files:

```console
$ git apply --reject ../patches/0002-*.patch 2>&1; ls; git status -s
Checking patch f.txt...
error: while searching for:
line1
line2
line3

error: patch failed: f.txt:1
Applying patch f.txt with 1 reject...
Rejected hunk #1.
f.txt
f.txt.rej
?? f.txt.rej
```

## Email and pull requests

`git send-email` mails a series; `git request-pull` generates the summary text a maintainer needs to pull from your repository:

```console
$ git remote add origin ../lab 2>/dev/null; git request-pull main ../lab topic 2>&1 | head -12
The following changes since commit 42e0eb95368a2812819d95f0ff1a84e943bcd02f:

  Initial (2024-01-01 02:00:00 +0000)

are available in the Git repository at:

  ../lab topic

for you to fetch changes up to 1028b3753c3a1816e53b91d23c5557a70fac87f5:

  Edit f (2024-01-01 03:00:00 +0000)
```

**Unverified:** on this Ubuntu machine `git send-email` is not installed (`git: 'send-email' is not a git command`; it lives in the separate `git-email` package), so its flags (`--to`, `--smtp-server`, `--dry-run`) are described from the docs, not run.

A hosted **pull request** (GitHub/GitLab "merge request") is not a Git object: it is a server-side record pointing at a branch. The Git part is just push a branch, ask the host to merge it. Typical flow: fork, `git switch -c feature`, push to your fork (the triangular setup from [Chapter 12](12-remotes-in-depth.md)), open the PR, address review with fixup commits or force-pushes (`--force-with-lease`), then the maintainer merges, squashes or rebases. Choose the merge style per project: merge commits keep topology, squash gives one commit per PR, rebase-merge keeps linear history.

## Branching models and commit messages

- **Trunk-based**: short-lived branches, merge to `main` often, release from `main` (flags for unfinished work).
- **GitHub flow**: `main` is deployable; one branch per change; PR; merge.
- **Git flow**: long-lived `develop` plus `release/*` and `hotfix/*`; heavier, suited to versioned releases.
- **Kernel/mailing-list**: topic branches, patch series, maintainers pull subsystem trees.

Message convention (from `git-commit` and `SubmittingPatches`): a subject of about 50 characters in the imperative ("Add g", not "Added g"), a blank line, a body wrapped near 72 columns explaining *why*, and trailers (`Signed-off-by:`, `Co-authored-by:`, `Fixes:`) at the end. `git interpret-trailers` and `git commit -s` manage trailers. One logical change per commit keeps `bisect`, `revert` and `cherry-pick` useful.

## Notes

`git notes` attaches text to a commit **without changing its hash**. Notes live in a separate ref (`refs/notes/commits` by default), as a commit history whose tree maps commit SHA to a blob.

```console
$ git notes add -m "reviewed by Bob" HEAD; git notes show HEAD
reviewed by Bob
$ git log -1 --format=%B%n--%n%N
Edit f

--
reviewed by Bob

$ git notes list | head -2; git rev-parse refs/notes/commits
1842afeea107142fe384ed8ffd34ea90baf90ff2 1028b3753c3a1816e53b91d23c5557a70fac87f5
3a6544bb8aa590d1166ce3f782531e3b1347c5df
$ git notes --ref=ci add -m "build: pass" HEAD~1; git log --show-notes=ci -2 --format="%h %s%n%N"
1028b37 Edit f
reviewed by Bob

1334081 Add g
build: pass

$ git ls-tree --name-only refs/notes/commits | cut -c1-12 | head -1; git log --oneline refs/notes/commits
1028b3753c3a
3a6544b Notes added by 'git notes add'
```

(`notes list` prints `<note blob> <annotated commit>`.) Notes are **not** pushed or fetched by default; you must name the ref explicitly (`git push origin refs/notes/commits`, and a fetch refspec `+refs/notes/*:refs/notes/*`). Rewrites (`amend`, `rebase`) drop notes unless `notes.rewriteRef` is configured.

## git archive

`git archive` exports a tree (not history, no `.git`) as tar or zip. Paths marked `export-ignore` in `.gitattributes` are omitted ([Chapter 15](15-hooks-attributes-and-config.md)).

```console
$ git archive --format=tar.gz --prefix=proj/ -o ../proj.tar.gz topic; tar tzf ../proj.tar.gz
proj/
proj/f.txt
proj/g.txt
$ git archive --format=zip topic f.txt | python3 -c "import zipfile,sys,io; print(zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())).namelist())"
['f.txt']
```

`--remote=<repo>` archives from a remote (many hosts disable it).

## Signing commits and tags

Signatures live **inside the object**: a `gpgsig` header on commits, a trailing block in tag objects. Verification is local and trust is configured outside Git (keyring or allowed-signers file).

### GPG

A throwaway ed25519 key was generated in a scratch `GNUPGHOME` (no passphrase, demo only):

```console
$ git commit -q -S -m "Signed commit" 2>&1; git log -1 --show-signature --format="%h %G? %GS" 2>&1 | sed "s/^gpg: Signature made .*/gpg: Signature made <date>/"
gpg: Signature made <date>
gpg:                using EDDSA key 15575752F53F79D01E21D1FEC08C442E062162C9
gpg: Good signature from "Ada Lovelace <ada@example.com>" [ultimate]
1121f4c G Ada Lovelace <ada@example.com>
$ git cat-file -p HEAD | sed -n "/^gpgsig/,/END PGP/p" | head -3
gpgsig -----BEGIN PGP SIGNATURE-----
 
 iHUEABYIAB0WIQQVV1dS9T950B4h0f7AjEQuBiFiyQUCaucrjAAKCRDAjEQuBiFi
$ git tag -s v1.0 -m "signed tag" 2>&1; git tag -v v1.0 2>&1 | sed "s/^gpg: Signature made .*/gpg: Signature made <date>/"
gpg: Signature made <date>
gpg:                using EDDSA key 15575752F53F79D01E21D1FEC08C442E062162C9
gpg: Good signature from "Ada Lovelace <ada@example.com>" [ultimate]
object 1121f4ce1bc9c45b79f36c4636386092979ae545
type commit
tag v1.0
tagger Ada Lovelace <ada@example.com> 1704088800 +0000

signed tag
$ git log --format="%h %G?" -3
1121f4c G
1028b37 N
1334081 N
```

(The `sed` replaces gpg's wall-clock "Signature made" date.)

`%G?` is `G` good, `B` bad, `U` good-but-untrusted, `N` no signature, `E` cannot check. Set `commit.gpgsign` / `tag.gpgsign` to sign by default, and `user.signingkey` to pick the key.

### SSH signatures

Git 2.34 added `gpg.format=ssh`, which signs with an SSH key via `ssh-keygen -Y sign` (an OpenSSH 8.x `ssh-keygen`; 8.9p1 here). Verification needs an allowed-signers file; without it the commit is created but cannot be verified:

```console
$ git commit -q -S -m "SSH signed" 2>&1; git log -1 --format="%h %G?"
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
d9c7117 N
$ git log -1 --format="%h %G? %GS"
d9c7117 G ada@example.com
$ git verify-commit HEAD 2>&1
Good "git" signature for ada@example.com with ED25519 key SHA256:J1dxy+fSV1h4Q0taGZq8MmONBWm5MfHSnM87zAyJj1A
$ git cat-file -p HEAD | sed -n "/^gpgsig/,/END SSH/p" | head -2
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgtLDHdHRQePZcGGW4YY9k5mugar
```

(The second command ran after `gpg.ssh.allowedSignersFile` was configured with a line `ada@example.com ssh-ed25519 AAAA…`.) A signature proves the key signed these bytes; it says nothing about the key's owner unless you trust the key list.

## Summary

- `format-patch` → mbox files; `am` applies them as commits (`--3way` to merge, `--abort/--continue/--skip`); `apply` only edits files (`--check`, `--stat`, `--reject`).
- Patches carry content and authorship, not hashes.
- A PR is a host feature on top of a pushed branch; pick merge/squash/rebase deliberately.
- Notes annotate commits without rewriting them, but are not shared by default.
- `archive` exports a tree; `export-ignore` filters it.
- Signatures are embedded in objects; GPG and SSH both work on 2.34, SSH needs an allowed-signers file to verify.

## Exercises

Solutions: [`examples/ch16/exercises.sh`](examples/ch16/exercises.sh) (a `topic` branch with two commits authored by Bob Builder and committed by Ada Lovelace, on top of `main`).

1. Export the last two commits of a branch as patches and apply them with `am` to a fresh clone of the base. How do you show that authorship was preserved?

   <details><summary>Solution</summary>

   ```console
   $ git format-patch -q -2 -o ../p; ls ../p
   0001-Add-g.patch
   0002-Edit-f.patch
   $ git clone -q -b main . ../c; cd ../c; git am -q ../p/*.patch; git log --format="%h author=%an <%ae> %ad committer=%cn" --date=short -2; cd ../lab
   e94abec author=Bob Builder <bob@example.com> 2024-01-01 committer=Ada Lovelace
   7609652 author=Bob Builder <bob@example.com> 2024-01-01 committer=Ada Lovelace
   $ git log --format="%h author=%an <%ae> %ad committer=%cn" --date=short -2
   5bba5f8 author=Bob Builder <bob@example.com> 2024-01-01 committer=Ada Lovelace
   1e0f747 author=Bob Builder <bob@example.com> 2024-01-01 committer=Ada Lovelace
   ```

   Author name, email and date survive; the committer is whoever ran `am`, with the current time, so the hashes differ.

   </details>

2. Add a note to `HEAD` in `refs/notes/review`, then show it in `git log`. Why does plain `git log` not show it?

   <details><summary>Solution</summary>

   ```console
   $ git notes --ref=review add -m "ok" HEAD; git log -1 --format="%h %s%n%N"; git log -1 --show-notes=review --format="%h %s%n%N"
   5bba5f8 Edit f

   5bba5f8 Edit f
   ok

   ```

   Plain `git log` shows only `refs/notes/commits` (plus refs named in `core.notesRef` / `notes.displayRef`).

   </details>

3. Produce a zip of `HEAD` without the `docs/` directory, without touching the working tree.

   <details><summary>Solution</summary>

   With a pathspec exclusion:

   ```console
   $ git archive --format=zip -o ../out.zip HEAD ":!docs"; python3 -m zipfile -l ../out.zip | awk "NR>1{print \$1}"
   f.txt
   g.txt
   ```

   Or with `docs/ export-ignore` in `.gitattributes`. `git archive` reads attributes from the archived tree, so an uncommitted rule is ignored unless you pass `--worktree-attributes`:

   ```console
   $ git archive HEAD | tar -t; git archive --worktree-attributes HEAD | tar -t
   docs/
   docs/d.txt
   f.txt
   g.txt
   f.txt
   g.txt
   $ git add .gitattributes; git commit -q -m "Ignore docs in archives"; git archive --format=zip HEAD | python3 -c "import zipfile,sys,io; print(zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())).namelist())"
   ['.gitattributes', 'f.txt', 'g.txt']
   ```

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-16--collaboration-and-patches)
