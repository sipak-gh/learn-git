# Chapter 18 — Mini-Git and Where Next

The best test of understanding is to rebuild the core. [`examples/ch18/minigit.py`](examples/ch18/minigit.py) is a ~130-line Python script that implements `init`, `add`, `commit`, `log` and `cat-file` by writing **real** Git data: zlib-compressed loose objects, a binary index (v2), and plain-text refs. Real Git then reads the repository it produced. Previous: [Chapter 17 — Debugging and Recovery](17-debugging-and-recovery.md). Back to the [README](README.md).

Transcripts are from [`examples/ch18/demo.sh`](examples/ch18/demo.sh) (Git 2.34.1, Python 3.10). Paths are shortened.

## The core: one function

Everything in [Chapter 4](04-the-object-database.md) reduces to this:

```python
def write_object(kind, data):
    raw = b"%s %d\0" % (kind.encode(), len(data)) + data      # "blob 5\0hello"
    sha = hashlib.sha1(raw).hexdigest()                        # name = hash of header+content
    path = os.path.join(GIT, "objects", sha[:2], sha[2:])      # fan-out directory
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(zlib.compress(raw))                        # stored deflated
    return sha
```

The rest maps onto earlier chapters:

| minigit function | Git concept | Chapter |
|---|---|---|
| `write_object` / `read_object` | loose objects, content addressing | 4 |
| `write_index` / `read_index` | index v2 binary format (entries sorted, padded to 8 bytes, SHA-1 trailer) | 5, appendix B |
| `write_tree` | recursive trees, entries sorted with directories compared as `name/` | 4 |
| `commit` | commit object with `tree`, `parent`, `author`, `committer`; branch ref update | 4, 6 |
| `head_ref`, `current` | symbolic `HEAD` → `refs/heads/main` → hash | 6 |
| `log` | walk first parents | 7, 8 |

What it leaves out: file stat data in the index (it writes zeros, so Git re-hashes files when refreshing), merges, packfiles, branches, reflogs, `.gitignore`, deletes, file modes other than 644/755, symlinks, locking, and any error handling.

## Running it, and checking with real Git

The demo `init`s, adds two files (one in a subdirectory), commits, and then asks the real `git` to inspect everything:

```console
$ python3 examples/ch18/minigit.py init; ls .git; cat .git/HEAD
HEAD
objects
refs
ref: refs/heads/main
$ python3 examples/ch18/minigit.py add hello.txt src/main.c
$ git ls-files -s
100644 ce013625030ba8dba906f756967f9e9ca394464a 0	hello.txt
100644 f7e582f82533be28c5813e8ea91918eb7fa61cdc 0	src/main.c
$ git status -s; echo rc=$?
A  hello.txt
A  src/main.c
rc=0
$ python3 examples/ch18/minigit.py commit 'first commit'
ff16743be7175299bdc9d39552c5a12f86923322
$ git fsck --strict; echo rc=$?
rc=0
$ git log --format='%H %an %s'
ff16743be7175299bdc9d39552c5a12f86923322 Ada Lovelace first commit
```

Git parsed minigit's index (`ls-files -s`), saw the staged files (`status`), and `fsck --strict` found no problems. A second commit and minigit's own `log`/`cat-file`:

```console
$ python3 examples/ch18/minigit.py add hello.txt
$ python3 examples/ch18/minigit.py commit 'second commit'
b803952ccd5501a88057b0dd5542674827c43f37
$ python3 examples/ch18/minigit.py log
commit b803952ccd5501a88057b0dd5542674827c43f37

    second commit

commit ff16743be7175299bdc9d39552c5a12f86923322

    first commit

$ python3 examples/ch18/minigit.py cat-file $(git rev-parse HEAD^{tree})
100644 13ab7f7412573d479aa8b41ce1e29a9f9f2a62d5 hello.txt
040000 b1a8becadd478624373132f066d206859ade455f src
$ git ls-tree -r HEAD
100644 blob 13ab7f7412573d479aa8b41ce1e29a9f9f2a62d5	hello.txt
100644 blob f7e582f82533be28c5813e8ea91918eb7fa61cdc	src/main.c
```

Because object IDs depend only on bytes, an independently written implementation can produce the **identical** commit. Real `git commit-tree`, given the same tree, parent, message and fixed dates, gives the same hash:

```console
$ git commit-tree -p HEAD~1 -m 'second commit' $(git rev-parse HEAD^{tree}) | cut -c1-12; git rev-parse --short=12 HEAD
b803952ccd55
b803952ccd55
$ git fsck --strict; echo rc=$?
rc=0
```

(The demo exports the same fixed time in `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE`; `commit-tree` reads both, minigit uses `GIT_COMMITTER_DATE` for both lines.)

A bug worth knowing about: copying the ISO date from `GIT_COMMITTER_DATE` verbatim into the commit. A commit written that way with `git hash-object -t commit -w --stdin` still showed up in `git log`, but `git fsck --strict` reported `error in commit 7aa5ed2…: badDate: invalid author/committer line - bad date`. Commits need `<unix-seconds> <±hhmm>`. This is why `fsck --strict` is a good validator for anything that writes objects by hand.

## Where next

- **Read the formats**: [Appendix B](appendix-b-plumbing-and-file-formats.md), then the `gitformat-*` pages listed in [REFERENCES.md](REFERENCES.md).
- **Extend minigit**: write `read-tree`/checkout; compute `status` from stat data; add branches and merges (a commit with two `parent` lines); read a packfile (see [Chapter 13](13-transport-and-packfiles.md)); or switch to SHA-256 objects (`git init --object-format=sha256`; interoperating with SHA-1 repositories is limited).
- **Read the source**: Git's own `t/` test suite is the best behavioural documentation; the `Documentation/technical/` directory covers pack heuristics, protocols, sparse index and more.
- **Tools beyond core Git**: `git filter-repo` (history rewriting), Git LFS, `git-absorb`, `tig`, `lazygit`, forges' APIs. *Unverified:* none of these is installed here, and they were not tested for this course.
- **Newer Git**: this course ran 2.34.1. Features such as `zdiff3`, `--update-refs`, `push.autoSetupRemote`, `git maintenance start`'s scheduler integration, reftable and newer sparse-checkout defaults are worth checking against `git --version` and the release notes before relying on them.

## Summary

- A Git repository is a directory of hashed, deflated objects plus a few small text files; a hundred lines can write one that real Git accepts.
- Same bytes, same hash: independent implementations agree.
- `git fsck --strict` is the oracle for hand-made objects.

## Exercises

1. Run `minigit.py add` on an executable file, then `git ls-files -s`. What mode do you expect, and what does Git say?

   <details><summary>Solution</summary>

   ```console
   $ python3 minigit.py init; printf '#!/bin/sh\necho hi\n' > run.sh; chmod +x run.sh; echo x > plain
   $ python3 minigit.py add run.sh plain; git ls-files -s
   100644 587be6b4c3f93f93c489c0111bba5596147a26cb 0	plain
   100755 4163036efa65bd4a469e752267498f01ea36a55c 0	run.sh
   ```

   `100755`: minigit checks `os.access(p, os.X_OK)`, and Git records only the executable bit, never other permission bits. After `minigit.py commit`, `git fsck --strict` is silent and `git ls-tree HEAD` shows the same modes.

   </details>

2. Write a tiny `hash-object` (blob only) in shell or Python and compare it with `git hash-object` on `printf 'hello\n'`.

   <details><summary>Solution</summary>

   ```console
   $ printf 'blob 6\0hello\n' | sha1sum
   ce013625030ba8dba906f756967f9e9ca394464a  -
   $ printf 'hello\n' | git hash-object --stdin
   ce013625030ba8dba906f756967f9e9ca394464a
   ```

   It is also the `hello.txt` blob in the first transcript above.

   </details>

3. Make `minigit.py log` follow a merge commit's second parent too. Which Chapter 7 option would you be re-implementing?

   <details><summary>Solution</summary>

   Keep a queue and a visited set instead of following `parents[0]`:

   ```python
   def log():
       todo, seen = [current()], set()
       while todo:
           sha = todo.pop(0)
           if sha in seen:
               continue
           seen.add(sha)
           _, body = read_object(sha)
           head, _, msg = body.decode().partition("\n\n")
           print("commit " + sha + "\n\n    " + msg.strip() + "\n")
           todo += [l.split()[1] for l in head.split("\n") if l.startswith("parent ")]
   ```

   On a repository made by real Git (loose objects only, so no `gc`) with a merge of a branch `side`, the original prints `Merge branch 'side'`, `main2`, `base`; this version prints `Merge branch 'side'`, `main2`, `side`, `base`, the same commits in the same order as `git log --format=%s` there. The original behaviour is `git log --first-parent`. Real `git log` orders by commit date rather than breadth-first, so on other histories the order can differ.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-18--mini-git-and-where-next)
