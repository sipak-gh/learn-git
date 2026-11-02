# Chapter 13 — Transport and Packfiles

Loose objects (chapter 4) are simple but wasteful: one zlib-compressed file per object, no sharing between versions. Git stores history compactly in **packfiles** — the same format it uses to send objects over the network. This chapter looks inside packs, then at `gc`/`repack`/`prune`, `fsck`, bundles, shallow and partial clones, the wire protocol, and `git maintenance`. Previous: [Chapter 12 — Remotes in Depth](12-remotes-in-depth.md). Next: [Chapter 14 — Submodules, Subtrees and Large Repos](14-submodules-subtrees-large-repos.md).

Transcripts: [`examples/ch13/demo.sh`](examples/ch13/demo.sh) → `output.txt` (Git 2.34.1). Hashes are reproducible by running the script. `/home/you` replaces the scratch path. The lab repository has one 2000-line file (`big.txt`, 8921 bytes) and four later commits that each append one line.

## Loose objects

```console
$ git count-objects -v
count: 15
size: 60
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
$ find .git/objects -type f | wc -l
15
```

15 loose objects (5 commits, 5 trees, 5 blobs), `size` in KiB of disk blocks (60: each tiny file occupies a 4 KiB block — loose storage wastes space on small objects). Every version of `big.txt` is stored as a *whole* compressed blob.

## Packing: `git gc`

```console
$ git gc -q; git count-objects -v
count: 0
size: 0
in-pack: 15
packs: 1
size-pack: 6
prune-packable: 0
garbage: 0
size-garbage: 0
$ ls .git/objects/pack
pack-1d275fc639a735a2195d7244fd027650d0f165eb.idx
pack-1d275fc639a735a2195d7244fd027650d0f165eb.pack
$ du -b big.txt; du -b .git/objects/pack/*.pack
8921	big.txt
5273	.git/objects/pack/pack-1d275fc639a735a2195d7244fd027650d0f165eb.pack
```

All five versions of a 9 KB file plus everything else now fit in 5273 bytes. The pack's file name is its trailer checksum: the SHA-1 of the pack contents stored in its last 20 bytes (`tail -c 20` of this pack prints `1d275fc6…`). (Very old Gits named packs after the sorted object names instead.) A `.pack` holds the objects, a `.idx` is the lookup table.

### How deltas show up

`git verify-pack -v` lists every object: `SHA type size size-in-pack offset [depth base-SHA]`.

```console
$ git verify-pack -v .git/objects/pack/*.idx | head -12
e6532b75718e30cf9a16a24dffef0a6cb8e5398b commit 215 145 12
b06c14c91d8aeea53bd4dfada0acb060618b88ce commit 215 147 157
23a6c1809caad24f12b6fc6c92836a9a25cbe460 commit 215 147 304
bceb4a54ded53cbd8a80a29d6763e87905234458 commit 215 147 451
579a9739580547dc18ad6ab7be42624a38f6e990 commit 167 120 598
c8c803175e80982651d2c59fdab6dca41fddd842 blob   8921 4235 718
0048b9bba0d084799e37bc0eeddd0066da047522 tree   35 46 4953
830d707734b626ab73a51e19b7ca045484aa92be tree   35 45 4999
171c3f02e5035fbd31c6a9f3822a74f718610440 blob   7 18 5044 1 c8c803175e80982651d2c59fdab6dca41fddd842
f6972f486e9ed7a91ed92352c690d2b1ac6ba8b4 tree   35 45 5062
2889e90c6765d5074d429bc0a464131bf83f3e4e blob   7 18 5107 1 c8c803175e80982651d2c59fdab6dca41fddd842
b3820b72af648fc23b7d2bb474eb008f399046f0 tree   35 46 5125
$ git verify-pack -v .git/objects/pack/*.idx | tail -3
non delta: 11 objects
chain length = 1: 4 objects
.git/objects/pack/pack-1d275fc639a735a2195d7244fd027650d0f165eb.pack: ok
```

Look at the blobs: the *newest* version of `big.txt` (`c8c8…`, 8921 bytes) is stored whole (compressed to 4235 bytes), while the four older versions are **deltas** against it: for a deltified entry the `size` column is the size of the delta itself (7 bytes, stored in 18), not of the ~8.9 KB blob it reconstructs (`depth 1`, base `c8c8…`). Git deltas go *backward* in time — the recent version, the one you check out most, is the base. Deltas are *not* tied to commit order or to a path: `pack-objects` sorts objects by type, name/size hints and recency, then tries each against a sliding window of earlier candidates (`--window`, default 10) up to a chain `--depth` (default 50) and keeps the best saving. A delta is a small program: "copy N bytes from base offset X; insert these literal bytes".

Raw index and pack headers (formats in [Appendix B](appendix-b-plumbing-and-file-formats.md#packfiles-and-pack-indexes)):

```console
$ xxd -l 12 .git/objects/pack/*.pack
00000000: 5041 434b 0000 0002 0000 000f            PACK........
$ xxd .git/objects/pack/*.idx | head -2
00000000: ff74 4f63 0000 0002 0000 0001 0000 0001  .tOc............
00000010: 0000 0001 0000 0001 0000 0001 0000 0001  ................
```

`ff744f63` is the idx v2 magic, `00000002` the version, then the 256-entry fan-out table (cumulative object counts by first byte of the name). The pack starts with `PACK`, version `00000002`, and `0000000f` = 15 objects.

```console
$ git show-index < .git/objects/pack/*.idx | head -3
4953 0048b9bba0d084799e37bc0eeddd0066da047522 (fcfeae36)
5044 171c3f02e5035fbd31c6a9f3822a74f718610440 (feeab750)
304 23a6c1809caad24f12b6fc6c92836a9a25cbe460 (46c741c1)
```

Offset, object name, CRC-32 of the packed data. The index is sorted by object name, so Git finds an object by binary search (with the fan-out table narrowing the range by the first byte) and then reads at the offset in the `.pack`.

`cat-file` can show per-object sizes, including size *on disk* (packed):

```console
$ git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize) %(objectsize:disk)" | sort | uniq -c | sort -rn | head -5
      3 tree 35 46
      3 commit 215 147
      2 tree 35 45
      1 commit 215 145
      1 commit 167 120
```

(Only the top five groups are printed. Here `%(objectsize)` is the real object size: the four deltified blobs show 8893–8914 bytes with an on-disk size of 18.)

### `pack-objects`: the packing engine

Anything that moves objects — `gc`, `repack`, `push`, `fetch`, `bundle` — ends in `git pack-objects`, which reads a list of object names on stdin:

```console
$ git rev-list --objects --all | git pack-objects --stdout | wc -c
5345
$ git rev-list --objects --all | git pack-objects -q out-pack; ls out-pack*; rm out-pack*
874696b5bceddc22ecd2e2950c44198c830d6ae9
out-pack-874696b5bceddc22ecd2e2950c44198c830d6ae9.idx
out-pack-874696b5bceddc22ecd2e2950c44198c830d6ae9.pack
```

`--stdout` writes the pack to stdout (this is what a server does for a `fetch`). Without `--thin`, packs sent over the wire are self-contained; with `--thin` the sender may delta against objects it knows the receiver has, and the receiver (`index-pack --fix-thin`) completes them.

## `repack`, `prune` and `gc`

- **`git repack -a -d`** puts everything reachable in one new pack and deletes the old ones (`-f`/`--no-reuse-delta` recompute deltas; `--depth`/`--window` tune the search).
- **`git prune`** deletes **unreachable loose** objects; `gc` runs it with an expiry of `gc.pruneExpire`, default 2 weeks. (Tested: after `git gc`, an unreachable blob with an mtime 13 days ago survived and one 15 days old was gone.) Objects reachable from any ref, reflog entry or the index are safe.
- **`git gc`** = `reflog expire` + `repack` + `prune` + `pack-refs` + `rerere gc` + `worktree prune` (+ `commit-graph`). `gc --auto` runs after some commands when there are too many loose objects (`gc.auto`, default 6700) or packs (`gc.autoPackLimit`, 50). It estimates by counting the files in `.git/objects/17/` and triggers above `(6700 + 255) / 256` = 27. In a test, 7400 loose objects (26 of them in `17/`) did not trigger it; 8400 (31 in `17/`) printed `Auto packing the repository in background for optimum performance.` `gc --aggressive` uses a deeper/larger delta search and is rarely worth the time.

An unreachable object, then pruning (the `--expire=now` override is needed since the object is brand new):

```console
$ git cat-file -t 9711d37cd6606e9c05a0443544000adbd4cd1a6f
blob
$ git count-objects -v | head -2
count: 1
size: 4
$ git prune --dry-run
9711d37cd6606e9c05a0443544000adbd4cd1a6f blob
$ git prune --expire=now -v; git count-objects -v | head -1
9711d37cd6606e9c05a0443544000adbd4cd1a6f blob
count: 0
$ git repack -a -d -q; ls .git/objects/pack | wc -l
2
$ git repack -a -d -f --depth=10 --window=20 -q; git count-objects -v | grep -E "^(in-pack|packs)"
in-pack: 15
packs: 1
$ git gc --aggressive -q; git count-objects -v | grep -E "^(in-pack|packs)"
in-pack: 15
packs: 1
```

(`.git/objects/pack` holds one `.pack` and one `.idx`, hence `2` files.) Without `-q`, `gc` prints "Enumerating/Counting/Compressing objects" progress. Unreachable objects *inside* packs aren't removed by `prune`. `repack -a -d` drops them at once, while `repack -A -d` (what `gc` uses) writes them out as loose objects so that `prune`'s grace period applies. Cruft packs (`--cruft`) came later (2.37) and are not available here.

## `fsck`: verifying the database

`git fsck` checks that every object parses, hashes to its name, and that links (tree→blob, commit→tree/parents, refs→commits) resolve. Silence is success:

```console
$ git fsck
$ git fsck --full --strict; echo rc=$?
rc=0
```

`fsck` also reports *dangling* objects — unreachable but present — which is how you recover lost work (chapter 17), and `--lost-found` writes them out.

## Bundles: a repository in a file

A bundle is a pack plus a header listing refs: a way to move history over USB, e-mail, or any channel where no server exists.

```console
$ git bundle create ../lab.bundle HEAD main 2>&1 | tail -1; ls -l ../lab.bundle | wc -l
1
$ git bundle verify ../lab.bundle 2>&1
../lab.bundle is okay
The bundle contains these 2 refs:
e6532b75718e30cf9a16a24dffef0a6cb8e5398b HEAD
e6532b75718e30cf9a16a24dffef0a6cb8e5398b refs/heads/main
The bundle records a complete history.
$ git bundle list-heads ../lab.bundle
e6532b75718e30cf9a16a24dffef0a6cb8e5398b HEAD
e6532b75718e30cf9a16a24dffef0a6cb8e5398b refs/heads/main
```

(`HEAD` is listed explicitly: a bundle of only `main` clones with `warning: remote HEAD refers to nonexistent ref, unable to checkout.` Run outside a repository, `git bundle verify` fails with `error: need a repository to verify a bundle`, so the script runs it from inside the lab.) An **incremental** bundle holds only new commits and *requires* the receiver to have a prerequisite:

```console
$ git bundle create ../inc.bundle main~2..main 2>&1 | tail -1; git bundle verify ../inc.bundle 2>&1
../inc.bundle is okay
The bundle contains this ref:
e6532b75718e30cf9a16a24dffef0a6cb8e5398b refs/heads/main
The bundle requires this ref:
23a6c1809caad24f12b6fc6c92836a9a25cbe460 
$ cd ..; head -4 inc.bundle | cut -c1-60
# v2 git bundle
-23a6c1809caad24f12b6fc6c92836a9a25cbe460 edit 3
e6532b75718e30cf9a16a24dffef0a6cb8e5398b refs/heads/main

$ git clone -q lab.bundle from-bundle; git -C from-bundle log --oneline | head -2; git -C from-bundle remote -v | head -1
e6532b7 edit 5
b06c14c edit 4
origin	/home/you/lab.bundle (fetch)
```

The text header (`# v2 git bundle`, `-<prerequisite>` lines, ref lines, blank line) is followed by a normal pack. A bundle works as a remote: `git fetch lab.bundle main:refs/remotes/bundle/main`, `git pull`, `git clone` all accept it.

## Shallow clones

`--depth N` truncates history; the cut points are recorded in `.git/shallow` (the *grafted* boundary commits, whose parents are pretended not to exist):

```console
$ git clone -q --depth 2 file://$PWD/lab shallow 2>&1; git -C shallow log --oneline
e6532b7 edit 5
b06c14c edit 4
$ cat shallow/.git/shallow
b06c14c91d8aeea53bd4dfada0acb060618b88ce
$ git -C shallow rev-list --count HEAD
2
$ git -C shallow fetch --deepen 1 2>&1 | tail -1; git -C shallow log --oneline | wc -l
3
$ git -C shallow fetch -q --unshallow; git -C shallow log --oneline | wc -l; ls shallow/.git/shallow 2>&1 | head -1
5
ls: cannot access 'shallow/.git/shallow': No such file or directory
```

Note `file://`: a plain local path would hardlink/copy objects and ignore `--depth`. Shallow repos save time and space in CI, but `log`, `blame`, `merge-base` and `describe` see a truncated history, and pushing from them can be limited. `--shallow-since=<date>` and `--shallow-exclude=<ref>` cut by date/ref instead of count.

## Partial clones

A partial clone omits some objects and fetches them on demand from a **promisor remote**. `--filter=blob:none` skips all file contents (commits and trees come down, so history operations work offline; blobs arrive when needed). The server must allow filters (`uploadpack.allowFilter`, set on the lab repo; hosting services typically enable it):

```console
$ git clone -q --filter=blob:none --no-checkout file://$PWD/lab partial 2>&1; git -C partial config --get-regexp "^remote.origin.(promisor|partialclonefilter)"
remote.origin.promisor true
remote.origin.partialclonefilter blob:none
$ git -C partial count-objects -v | grep -E "^(count|in-pack)"
count: 0
in-pack: 10
$ git -C partial rev-list --objects --all --missing=print | grep -c "^?"
5
$ git -C partial cat-file -t HEAD:big.txt
blob
$ git -C partial rev-list --objects --all --missing=print | grep -c "^?"
4
```

The clone has 10 objects (5 commits + 5 trees) and *5 blobs missing* (the `?` lines). Merely asking for the type of `HEAD:big.txt` made Git fetch that blob lazily (4 now missing). Other filters: `blob:limit=<size>`, `tree:<depth>`; combine with sparse-checkout in chapter 14. Caveats: operations like `blame` or `log -p` over old history trigger many single-object fetches; a lost server means lost data.

## Protocol v2, as seen on the wire

Fetch and push run `git-upload-pack` / `git-receive-pack` on the other end and talk **pkt-line** framing: each line starts with four hex digits giving its length (including those four), `0000` is a flush packet. Protocol version 2 (default since Git 2.26, briefly reverted in 2.27 and default again from 2.28, so in effect here) begins with a capability advertisement and then command requests (`ls-refs`, `fetch`, `object-info`). Tracing the server's side of `ls-remote` (timestamps and the 15-character prefix cut off):

```console
$ GIT_TRACE_PACKET=1 git ls-remote file://$PWD/lab 2>&1 | head -12 | cut -c16-110
 pkt-line.c:80           packet:  upload-pack> version 2
 pkt-line.c:80           packet:  upload-pack> agent=git/2.34.1
 pkt-line.c:80           packet:  upload-pack> ls-refs=unborn
 pkt-line.c:80           packet:  upload-pack> fetch=shallow wait-for-done filter
 pkt-line.c:80           packet:  upload-pack> server-option
 pkt-line.c:80           packet:  upload-pack> object-format=sha1
 pkt-line.c:80           packet:  upload-pack> object-info
 pkt-line.c:80           packet:  upload-pack> 0000
 pkt-line.c:80           packet:    ls-remote< version 2
 pkt-line.c:80           packet:    ls-remote< agent=git/2.34.1
 pkt-line.c:80           packet:    ls-remote< ls-refs=unborn
 pkt-line.c:80           packet:    ls-remote< fetch=shallow wait-for-done filter
```

The server advertises `ls-refs`, `fetch` (with the `shallow` and `filter` features seen above, hence shallow/partial clones), `object-format=sha1` and `object-info`. Version 0 (`-c protocol.version=0`), the original protocol, makes the server dump *every* ref up front:

```console
$ git -c protocol.version=0 ls-remote lab 2>&1 | head -1 | cut -c1-60; GIT_TRACE_PACKET=1 git -c protocol.version=0 ls-remote file://$PWD/lab 2>&1 | grep -m1 "upload-pack>" | cut -c16-90
e6532b75718e30cf9a16a24dffef0a6cb8e5398b	HEAD
 pkt-line.c:80           packet:  upload-pack> e6532b75718e30cf9a16a24dffef
```

(Output of the first command is plain `ls-remote`, which prints the same either way.) A normal `fetch` negotiates in rounds: the client sends `want <oid>` for what it needs and `have <oid>` for commits it already has, the server finds the common ancestors, and then sends a (thin) pack built by `pack-objects`. Push sends ref-update commands and a pack to `receive-pack`. A full fetch or push trace is not shown; run `GIT_TRACE_PACKET=1 git fetch` against a `file://` clone to see the `want`/`have` lines.

## `commit-graph` and `git maintenance`

`git commit-graph write --reachable` stores a precomputed summary of the commit DAG (parents, generation numbers, dates) in `.git/objects/info/commit-graph`, which makes `log --graph`, `merge-base`, `--contains` and reachability queries much faster in big repositories:

```console
$ git -C lab commit-graph write --reachable; ls lab/.git/objects/info
commit-graph
packs
$ git -C lab commit-graph verify; echo rc=$?
rc=0
```

`git maintenance` (`run` since Git 2.29, `register`/`start` since 2.30; systemd timers as a scheduler since 2.34) runs housekeeping *tasks* — `gc`, `commit-graph`, `prefetch`, `loose-objects`, `incremental-repack`, `pack-refs` — either on demand or on a schedule that it installs in cron/systemd/launchd (`git maintenance start`). *Unverified:* `start` was not run for this course, since it installs a scheduler on the machine. On demand and registration:

```console
$ git -C lab maintenance run --task=commit-graph --task=loose-objects; echo rc=$?
rc=0
$ git -C lab maintenance register; git config --global --get-all maintenance.repo | sed "s#.*/work#/home/you#"; git -C lab config --get maintenance.strategy
/home/you/lab
incremental
```

`register` records the repository in the (sandboxed) global config `maintenance.repo` and, if unset, sets `maintenance.strategy=incremental` in the repository's own config; that preset is what the scheduler will run (hourly `prefetch`/`commit-graph`, daily `loose-objects`/`incremental-repack`, weekly `pack-refs`; never `gc`). Features newer than 2.34, not available here: cruft packs (`gc --cruft`, 2.37) and `reftable` ref storage (2.45).

## Summary

- Loose objects are zlib files named by hash; `gc` packs them: one `.pack` (objects, often deltified) plus one `.idx` (sorted names → offsets).
- Deltas are chosen by a sliding-window search and usually make *older* versions deltas of newer ones; chains are limited by depth.
- `pack-objects` is the engine behind gc, repack, push, fetch and bundles.
- `prune` removes unreachable loose objects past the expiry; `gc` also expires reflogs and repacks; `fsck` verifies and finds dangling objects.
- Bundles are packs with a ref header; shallow clones truncate by depth; partial clones omit objects and fetch lazily from a promisor remote.
- Protocol v2 uses pkt-lines and capability advertisement; `commit-graph` and `maintenance` speed up large repos.

## Exercises

Solutions: [`examples/ch13/exercises.sh`](examples/ch13/exercises.sh).

1. Make a repository with a 100 KB random text file, commit it, change one line, commit again. Compare the `.git` size before and after `git gc`.

   <details><summary>Solution</summary>

   ```console
   $ base64 /dev/urandom | head -c 100000 > f; git add f; git commit -qm 1; sed -i "3s/.*/changed/" f; git commit -qam 2; du -sb .git | cut -f1
   257707
   $ git gc -q; du -sb .git | cut -f1
   156399
   ```

   The numbers vary slightly with the random data. Most of the remaining size is the one full compressed blob plus Git's sample hooks.

   </details>

2. In your packed repository, find which blobs are stored as deltas and what they are based on.

   <details><summary>Solution</summary>

   ```console
   $ git verify-pack -v .git/objects/pack/*.idx | awk "NF==7"
   f6b77e7dd6b5c8ba4208c080ac1535c366d1efec blob   23 37 76329 1 223c28f73ee243c2c3f71bff1270aee2c1594ba2
   ```

   Delta entries have seven fields: the last two are the chain depth and the base object. The older blob is a 23-byte delta against the newer one (names, sizes and offsets vary with exercise 1's random data).

   </details>

3. Create a bundle of everything in a repository and clone from it.

   <details><summary>Solution</summary>

   ```console
   $ git bundle create ../all.bundle --all 2>&1 | tail -1; cd ..; git clone -q all.bundle copy; git -C copy log --oneline | wc -l
   2
   ```

   `--all` includes `HEAD`, so the clone has a branch to check out.

   </details>

4. Make a depth-1 clone of a local repository and convert it to a full clone.

   <details><summary>Solution</summary>

   ```console
   $ git clone -q --depth 1 file://$PWD/ex1 shallow; git -C shallow rev-list --count HEAD
   1
   $ git -C shallow fetch -q --unshallow; git -C shallow rev-list --count HEAD; test -f shallow/.git/shallow || echo "no .git/shallow"
   2
   no .git/shallow
   ```

   The `file://` prefix matters: with a plain path, `--depth` is ignored for local clones.

   </details>

Sources for this chapter: [REFERENCES.md](REFERENCES.md#chapter-13--transport-and-packfiles)
