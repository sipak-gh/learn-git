# Chapter 4 — The Object Database

Everything Git stores in `.git/objects` is one of four object types — blob, tree, commit, tag — each named by the hash of its content. This chapter opens the database with plumbing commands (`hash-object`, `cat-file`, `write-tree`, `commit-tree`, `update-ref`), builds a commit by hand without `git add` or `git commit`, and explains content addressing and the SHA-1/SHA-256 situation. Previous: [Chapter 3 — Branches, Merging and Remotes in Brief](03-branches-merging-remotes-brief.md). Next: [Chapter 5 — The Index](05-the-index.md).

Examples: `examples/ch04/demo.sh`. Fixed identity and dates make every ID below reproducible by running the script.

## A new repository

```console
$ git init -q lab && cd lab
$ find .git -maxdepth 1 | sort
.git
.git/HEAD
.git/branches
.git/config
.git/description
.git/hooks
.git/info
.git/objects
.git/refs
$ find .git/objects | head
.git/objects
.git/objects/info
.git/objects/pack
```

- `HEAD` — which branch (or commit) you are on ([Chapter 6](06-references-and-head.md)).
- `objects/` — the database (empty); `refs/` — branch and tag names; `config`, `hooks/`, `info/exclude`.
- Created later: `index` (staging area, [Chapter 5](05-the-index.md)), `logs/` (reflogs), `packed-refs`, `ORIG_HEAD`…

## Blobs and content addressing

An object's ID is the SHA-1 of `"<type> <size>\0"` followed by the content. A blob is a file's bytes: no name, no mode, no timestamp.

```console
$ printf "hello\n" | git hash-object --stdin
ce013625030ba8dba906f756967f9e9ca394464a
$ printf "blob 6\0hello\n" | sha1sum
ce013625030ba8dba906f756967f9e9ca394464a  -
$ printf "hello\n" | git hash-object -w --stdin
ce013625030ba8dba906f756967f9e9ca394464a
$ find .git/objects -type f
.git/objects/ce/013625030ba8dba906f756967f9e9ca394464a
```

`hash-object` computes the ID; `-w` also writes it. The first two hex digits become a directory (to keep directories small), the other 38 the file name. The file is the header plus content, zlib-compressed:

```console
$ git cat-file -t ce013625030ba8dba906f756967f9e9ca394464a
blob
$ git cat-file -s ce013625030ba8dba906f756967f9e9ca394464a
6
$ git cat-file -p ce013625030ba8dba906f756967f9e9ca394464a
hello
$ python3 -c "import zlib; print(repr(zlib.decompress(open('.git/objects/ce/013625030ba8dba906f756967f9e9ca394464a','rb').read())))"
b'blob 6\x00hello\n'
```

`cat-file -t` type, `-s` size, `-p` pretty-print by type, or `git cat-file blob <id>` for raw bytes. Consequences of naming by content:

- **Identical content is stored once**, whatever the file name or how many commits contain it.
- **Objects are immutable**: change a byte, get a different ID. A commit's ID transitively commits to its whole tree and all ancestry (a Merkle DAG), so history cannot be altered silently.
- Names and modes are not in the blob; they live in the tree.

```console
$ echo hello > a.txt; cp a.txt b.txt; git hash-object a.txt b.txt
ce013625030ba8dba906f756967f9e9ca394464a
ce013625030ba8dba906f756967f9e9ca394464a
```

## Trees

A tree is a directory listing: one entry per child with mode, type, ID and name, sorted by name. Modes: `100644` file, `100755` executable, `120000` symlink (blob holds the target path), `040000` subtree, `160000` gitlink (a submodule's commit, [Chapter 14](14-submodules-subtrees-large-repos.md)). Git records only the executable bit, not full permissions or owners.

Create the first tree without `git add`, by putting an entry directly into the index and writing it out:

```console
$ git update-index --add --cacheinfo 100644,ce013625030ba8dba906f756967f9e9ca394464a,hello.txt
$ git write-tree
aaa96ced2d9a1c8e72c56b253a0e2fe78393feb7
$ git cat-file -p $(git write-tree)
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	hello.txt
$ git cat-file -p $(git write-tree) | git mktree | head -1
aaa96ced2d9a1c8e72c56b253a0e2fe78393feb7
$ git cat-file tree $(git write-tree) | xxd | head -4
00000000: 3130 3036 3434 2068 656c 6c6f 2e74 7874  100644 hello.txt
00000010: 00ce 0136 2503 0ba8 dba9 06f7 5696 7f9e  ...6%.......V...
00000020: 9ca3 9446 4a                             ...FJ
```

The raw format is `<mode> <name>\0<20 raw bytes of ID>` repeated, with no separators. In the raw form a subtree's mode is written `40000` (no leading zero; `cat-file -p` pads it to `040000`), and entries are sorted by name bytes with a subtree's name compared as if it ended in `/`. `git mktree` rebuilds a tree from `ls-tree`-style text, so the pretty form and the raw form are interchangeable. (`write-tree` writes the *index*; `mktree` reads text from stdin.)

## Commits

A commit is text: a tree, zero or more parents, author and committer with timestamps, a blank line, the message. `commit-tree` writes one; it moves no branch.

```console
$ git commit-tree -m "Hand-made commit" $(git write-tree)
c60e6552f786d3f9455beb787e97884d932d8f93
$ git cat-file -p c60e6552f786d3f9455beb787e97884d932d8f93
tree aaa96ced2d9a1c8e72c56b253a0e2fe78393feb7
author Ada Lovelace <ada@example.com> 1704074400 +0000
committer Ada Lovelace <ada@example.com> 1704074400 +0000

Hand-made commit
```

Timestamps are Unix seconds plus a UTC offset. The author wrote the change; the committer applied it (they differ after `rebase`, `cherry-pick`, `am`). A few optional headers can follow `committer`: `encoding` for a non-UTF-8 message, `mergetag` when merging a signed tag, and `gpgsig` for a signed commit ([Chapter 16](16-collaboration-and-patches.md)). All of them are part of the hashed bytes. Nothing points at this commit yet, so a *reference* must be created. This is exactly what `git commit` does at the end:

```console
$ git update-ref refs/heads/main c60e6552f786d3f9455beb787e97884d932d8f93 && git log --oneline
c60e655 Hand-made commit
$ git status -s
 D hello.txt
?? a.txt
?? b.txt
```

`status` is accurate: the index and `HEAD` agree on `hello.txt`, but we never created it in the working tree (` D`), and `a.txt`/`b.txt` are untracked.

### A second commit with a subdirectory

Directories are subtrees, and unchanged ones are shared between commits:

```console
$ mkdir -p src; echo 'int main(){}' > src/main.c; echo "hello world" > a.txt
$ git add src a.txt && git write-tree
58acb272bc53a82ee6ef26aee0ed774066000bc9
$ git cat-file -p HEAD^{tree}
100644 blob 3b18e512dba79e4c8300dd08aeb37f8e728b8dad	a.txt
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	hello.txt
040000 tree d35fe912b068a9686f0226a47adde61b99abf5cd	src
$ git cat-file -p HEAD:src
100644 blob 979a1cd784949e8bbee5d848f6abf820e27562b3	main.c
$ git ls-tree -r -t HEAD
100644 blob 3b18e512dba79e4c8300dd08aeb37f8e728b8dad	a.txt
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	hello.txt
040000 tree d35fe912b068a9686f0226a47adde61b99abf5cd	src
100644 blob 979a1cd784949e8bbee5d848f6abf820e27562b3	src/main.c
$ git cat-file -p HEAD~1^{tree}
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	hello.txt
```

(Here `HEAD` is the second commit, created with `commit-tree -p <first>` and `update-ref`.) `hello.txt` has the same blob ID in both trees: that is the "snapshot, not diff" promise, with deduplication for free. `rev^{tree}` and `rev:path` are revision syntax ([Chapter 7](07-revisions-and-ranges.md)).

## Tags

An **annotated tag** is a fourth object type pointing at any object (usually a commit), with a tagger, date and message. A **lightweight tag** is only a ref ([Chapter 6](06-references-and-head.md)).

```console
$ git cat-file -p v1
object 6486c7564d4c7bb980eb214a17512775dfe52576
type commit
tag v1
tagger Ada Lovelace <ada@example.com> 1704081600 +0000

Release 1
$ git cat-file -t v1; git cat-file -t v1^{}
tag
commit
```

`^{}` "peels" a tag to the object it points to.

## Enumerating the database

```console
$ git cat-file --batch-all-objects --batch-check
19f0acc7333799cc625f1551210f2d3e5dbec13d tag 133
3b18e512dba79e4c8300dd08aeb37f8e728b8dad blob 12
58acb272bc53a82ee6ef26aee0ed774066000bc9 tree 100
6486c7564d4c7bb980eb214a17512775dfe52576 commit 215
979a1cd784949e8bbee5d848f6abf820e27562b3 blob 13
aaa96ced2d9a1c8e72c56b253a0e2fe78393feb7 tree 37
c60e6552f786d3f9455beb787e97884d932d8f93 commit 177
ce013625030ba8dba906f756967f9e9ca394464a blob 6
d35fe912b068a9686f0226a47adde61b99abf5cd tree 34
$ git count-objects -v | head -3
count: 9
size: 36
in-pack: 0
```

Nine loose objects: 3 blobs, 3 trees, 2 commits, 1 tag. (`size` is in KiB of disk blocks.) Loose objects are later bundled into packfiles ([Chapter 13](13-transport-and-packfiles.md)).

## SHA-1 and SHA-256

Git uses SHA-1 as a content address, not primarily as a security feature, but collision attacks (SHAttered, 2017) made it a concern. Since 2.13 Git uses a hardened SHA-1 implementation (sha1dc) that detects the known attack patterns. A transition to SHA-256 exists: `git init --object-format=sha256` gives 64-hex-digit IDs.

```console
$ git init -q --object-format=sha256 s256 2>&1; cd s256 && echo hello | git hash-object --stdin && git rev-parse --show-object-format 2>&1
2cf8d83d9ee29543b34a87727421fdecb7e3f3a183d337639025de576db9ebb4
sha256
```

Caveat, honest: in Git 2.34 SHA-256 repositories are experimental, can't interoperate with SHA-1 repositories (no cross-hash fetch/push), and hosting-service support is limited. Everything in this course uses SHA-1. Abbreviated IDs (`c60e655`) work as long as they're unambiguous (`core.abbrev`).

## Summary

- Four object types; ID = hash(`type size\0` + content); stored zlib-compressed at `objects/xx/yyyy…`.
- Blob = bytes; tree = names → (mode, ID); commit = tree + parents + author/committer + message; annotated tag = named pointer to any object, with tagger and message (optionally signed).
- Content addressing gives dedup, immutability and cheap snapshots.
- `hash-object -w`, `update-index --cacheinfo`, `write-tree`, `commit-tree`, `update-ref` are the five calls behind `add` + `commit`.
- SHA-256 repositories are experimental in 2.34.

## Exercises

1. Compute the blob ID of a file `f.txt` containing `tree 0` plus newline using only `printf`, `wc` and `sha1sum`.

   <details><summary>Solution</summary>

   ```console
   $ printf "tree 0\n" > f.txt; wc -c < f.txt
   7
   $ printf "blob %s\0" $(wc -c < f.txt) | cat - f.txt | sha1sum
   fc8207a2f90e09ed644bc2833cb0cfee0f2c60d8  -
   $ git hash-object f.txt
   fc8207a2f90e09ed644bc2833cb0cfee0f2c60d8
   ```

   </details>

2. Build a merge commit (two parents) without `git merge`.

   <details><summary>Solution</summary>

   Give `commit-tree` two `-p` options; this script reuses one tree for simplicity:

   ```console
   $ git add f.txt; T=$(git write-tree)
   $ A=$(git commit-tree -m A $T); B=$(git commit-tree -m B $T)
   $ M=$(git commit-tree -m M -p $A -p $B $T); git cat-file -p $M
   tree a37636c69dbdd5e7dcace40bf6dd39f3f66918cd
   parent 99d7ade74f3f1ae4bfacb60dc45d3a4b1c0743b3
   parent d4d9b47ac2cd856ba564e657de76189b7c58ed0d
   author Ada Lovelace <ada@example.com> 1704078000 +0000
   committer Ada Lovelace <ada@example.com> 1704078000 +0000

   M
   ```

   (IDs from `examples/ch04/exercises.sh`.) A "merge" is just a commit with more than one `parent` line; the tree is whatever you say it is.

   </details>

3. Without `git log`, how do you prove that a commit's tree is the one `write-tree` just made?

   <details><summary>Solution</summary>

   `git rev-parse <commit>^{tree}` prints the commit's tree ID; compare with `git write-tree`. In the exercise run both printed `a37636c69dbdd5e7dcace40bf6dd39f3f66918cd`.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-4--the-object-database)
