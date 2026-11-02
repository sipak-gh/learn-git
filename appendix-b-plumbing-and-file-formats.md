# Appendix B — Plumbing and File Formats

A reference for the on-disk formats the chapters used. Everything here was observed in the demos (Git 2.34.1, SHA-1 repositories) except where marked *from docs*. Authoritative specs: the `gitformat-*` pages and `Documentation/technical/` ([REFERENCES.md](REFERENCES.md)). Chapters: [4](04-the-object-database.md), [5](05-the-index.md), [6](06-references-and-head.md), [13](13-transport-and-packfiles.md). Back to the [README](README.md).

## Repository layout (`.git/`)

| Path | Contents |
|---|---|
| `HEAD` | `ref: refs/heads/main` (symbolic) or a bare 40-hex hash (detached) |
| `config` | repository-level config (INI-like) |
| `objects/xx/yyyy…` | loose objects; `objects/pack/` packs; `objects/info/` |
| `refs/heads`, `refs/tags`, `refs/remotes`, `refs/notes`, `refs/stash` | loose refs: file containing a hash + newline |
| `packed-refs` | many refs in one text file |
| `index` | the staging area, binary |
| `logs/` | reflogs: `logs/HEAD`, `logs/refs/heads/<name>` |
| `info/exclude` | local, unshared ignore patterns |
| `hooks/` | hook scripts (samples end in `.sample`) |
| `ORIG_HEAD`, `FETCH_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD` … | transient state files |
| `worktrees/`, `modules/` | linked-worktree and submodule git dirs |
| `shallow`, `commit-graph`-related files | shallow boundaries; `objects/info/commit-graph` |

## Objects

Every object, loose or packed, is identified by `SHA-1("<type> <size>\0" + content)`. SHA-256 repositories (`git init --object-format=sha256`) use the same scheme with a 64-hex ID.

**Loose object file**: zlib-deflated `"<type> <size>\0<content>"`, stored at `objects/<first 2 hex>/<remaining 38 hex>`, read-only.

| Type | Content |
|---|---|
| `blob` | raw file bytes; no name, no mode |
| `tree` | repeated entries `"<octal mode> <name>\0<20-byte raw hash>"`, **no separators** |
| `commit` | text headers, blank line, message |
| `tag` | text headers, blank line, message (optionally a signature) |

**Tree entry modes**: `100644` regular file, `100755` executable, `120000` symlink (blob holds the target path), `040000` directory (written `40000`), `160000` gitlink (submodule commit). Entries are sorted by name bytes, with a directory compared as if its name ended in `/`.

**Commit**:

```text
tree <hash>
parent <hash>            (zero or more; two or more for merges)
author Name <email> <unix-seconds> <±hhmm>
committer Name <email> <unix-seconds> <±hhmm>
[encoding …]                               (only if not UTF-8)
[mergetag object …]                        (merging a signed tag)
[gpgsig -----BEGIN PGP SIGNATURE-----      (continuation lines start with a space)
 …
 -----END PGP SIGNATURE-----]

<message>
```

The date must be `<unix seconds> <±hhmm>`; an ISO string makes `fsck --strict` report `badDate` (see [Chapter 18](18-mini-git-and-where-next.md)).

**Annotated tag**:

```text
object <hash>
type commit
tag v1.0
tagger Name <email> <unix-seconds> <±hhmm>

<message>
[signature block]
```

## References

- A loose ref is a file `.git/refs/heads/main` containing `<hash>\n`.
- A symbolic ref contains `ref: <target>\n` (`HEAD` is the standard one).
- `packed-refs`: a header line `# pack-refs with: peeled fully-peeled sorted`, then `<hash> <refname>` lines; a line starting with `^` gives the peeled (target) commit for the annotated tag above it. A loose ref overrides a packed one.
- Reflog line (`logs/…`): `<old-hash> <new-hash> Name <email> <unix-seconds> <±hhmm>\t<message>`.
- Remote-tracking refs live under `refs/remotes/<remote>/…`; their update rules come from `remote.<name>.fetch` refspecs `+<src>:<dst>`.
- `FETCH_HEAD` lines: `<hash>\t[not-for-merge]\t<description>`.
- The reftable backend (newer Git, not available in 2.34.1) replaces loose refs and `packed-refs` with binary tables.

## The index (`.git/index`)

Binary, network byte order (*layout from `gitformat-index`; entry fields were exercised by [`minigit.py`](examples/ch18/minigit.py), version 2*):

| Part | Size | Meaning |
|---|---|---|
| signature | 4 | `DIRC` |
| version | 4 | 2, 3 or 4 |
| entry count | 4 | |
| entries | variable | sorted by path, then by stage |
| extensions | variable | `TREE` (cache tree), `REUC` (resolve-undo), `link` (split index), `UNTR`, `FSMN` … |
| checksum | 20 | SHA-1 of everything before it |

Entry (version 2): ctime (sec, nsec), mtime (sec, nsec), dev, ino, mode, uid, gid, file size: ten 4-byte fields = 40 bytes; then the 20-byte object hash; a 2-byte flags field (1 bit assume-valid, 1 bit extended, 2 bits **stage** (0 normal, 1 base, 2 ours, 3 theirs), 12 bits name length, saturating at 0xFFF); the path; then 1–8 NUL bytes so the entry length is a multiple of 8. Version 3 adds extended flags (skip-worktree, intent-to-add); version 4 prefix-compresses paths.

Inspect with `git ls-files -s`, `git ls-files --debug`, `git ls-tree`. The tree extension caches tree hashes so `write-tree` and `commit` can skip unchanged directories.

## Packfiles and pack indexes

**`.pack`**: `PACK`, version (4 bytes, 2), object count (4 bytes), then objects, then a 20-byte SHA-1 of all preceding bytes. Each object begins with a variable-length header: the first byte holds a continuation bit (MSB), a 3-bit type and the low 4 bits of the size; each further byte adds 7 more size bits. The body is zlib data.

| Type bits | Meaning |
|---|---|
| 1, 2, 3, 4 | commit, tree, blob, tag (full content) |
| 6 | `OFS_DELTA`: negative offset to the base object in the same pack, then deflated delta |
| 7 | `REF_DELTA`: 20-byte base hash, then deflated delta |

A delta is a program: source/target sizes, then *copy (offset, size) from base* and *insert literal bytes* instructions.

**`.idx` (version 2)**: magic `\377tOc`, version 2, a 256-entry **fan-out** table (cumulative count of objects whose first byte ≤ i), sorted object names, CRC-32 of each packed object, 4-byte offsets (MSB set means an index into a following table of 8-byte offsets for packs > 2 GiB), the pack's checksum, and the idx checksum. Lookup: fan-out narrows the range, binary-search the names, read the offset, seek into the pack. `git verify-pack -v` prints each object's type, size, packed size, offset and delta depth/base ([Chapter 13](13-transport-and-packfiles.md)).

Other pack-adjacent files: `.rev` (reverse index, 2.31+, not written by default in 2.34), `.bitmap` (reachability bitmaps), `multi-pack-index`, `commit-graph` (generation numbers and parents for fast ancestry queries) *(from docs, only commit-graph was exercised)*.

## Wire format basics

*From docs (`gitprotocol-*`); protocol v2 was traced in [Chapter 13](13-transport-and-packfiles.md).* Messages are **pkt-lines**: four hex digits giving the total length including the 4 bytes, then the payload; `0000` is a flush packet, `0001` a delimiter (v2). Protocol v2 is request-based: `ls-refs` lists references, `fetch` negotiates and returns a pack; `git://` and ssh use the same pkt-line framing.

## Inspecting any of this

```console
$ git cat-file -t <hash>          # type
$ git cat-file -p <hash>          # pretty-printed content
$ git cat-file --batch-check --batch-all-objects
$ git ls-tree -r <tree-ish>
$ git ls-files -s                 # index entries with stage
$ git for-each-ref                # refs with object type
$ git verify-pack -v .git/objects/pack/pack-*.idx
$ git fsck --strict               # validate everything
```

(That block shows command forms; it is not a transcript.)

Sources for this appendix: [REFERENCES.md](REFERENCES.md#appendix-b--plumbing-and-file-formats)
