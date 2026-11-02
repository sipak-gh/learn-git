#!/usr/bin/env bash
# Chapter 13: packfiles, gc, fsck, bundles, shallow/partial clones, protocol.
. "$(dirname "$0")/../lib.sh"
sandbox ch13
git init -q lab; cd lab
seq 1 2000 > big.txt; git add .; c "big v1"
for i in 2 3 4 5; do echo "line $i" >> big.txt; git commit -qam "edit $i" ; tick; done
note "loose objects"
r 'git count-objects -v'
r 'find .git/objects -type f | wc -l'
r 'git count-objects -vH | grep -E "^(count|size|in-pack)"'
echo
note "pack them"
r 'git gc -q; git count-objects -v'
r 'ls .git/objects/pack'
r 'git verify-pack -v .git/objects/pack/*.idx | head -12'
r 'git verify-pack -v .git/objects/pack/*.idx | tail -3'
r 'git verify-pack -s .git/objects/pack/*.idx 2>&1 | tail -3'
r 'du -b big.txt; du -b .git/objects/pack/*.pack'
echo
note "pack-objects directly"
r 'git rev-list --objects --all | git pack-objects --stdout | wc -c'
r 'git rev-list --objects --all | git pack-objects -q out-pack; ls out-pack*; rm out-pack*'
r 'git rev-list --objects --all | cut -c1-12 | head -3'
r 'git show-index < .git/objects/pack/*.idx | head -3'
r 'git cat-file --batch-all-objects --batch-check | head -3'
r 'git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize) %(objectsize:disk)" | sort | uniq -c | sort -rn | head -5'
r 'xxd -l 12 .git/objects/pack/*.pack'
r 'xxd .git/objects/pack/*.idx | head -2'
echo
note "gc, repack, prune, reflog"
echo unreachable > lost.txt; h=$(git hash-object -w lost.txt); rm lost.txt
r "git cat-file -t $h"
r 'git count-objects -v | head -2'
r 'git prune --dry-run'
r 'git prune --expire=now -v; git count-objects -v | head -1'
r 'git repack -a -d -q; ls .git/objects/pack | wc -l'
r 'git repack -a -d -f --depth=10 --window=20 -q; git count-objects -v | grep -E "^(in-pack|packs)"'
r 'git gc --aggressive -q; git count-objects -v | grep -E "^(in-pack|packs)"'
echo
note "fsck"
r 'git fsck'
r 'git fsck --full --strict; echo rc=$?'
echo
note "bundle"
r 'git bundle create ../lab.bundle HEAD main 2>&1 | tail -1; ls -l ../lab.bundle | wc -l'
r 'git bundle verify ../lab.bundle 2>&1'
r 'git bundle list-heads ../lab.bundle'
r 'git bundle create ../inc.bundle main~2..main 2>&1 | tail -1; git bundle verify ../inc.bundle 2>&1'
r 'cd ..; head -4 inc.bundle | cut -c1-60'
r 'git clone -q lab.bundle from-bundle; git -C from-bundle log --oneline | head -2; git -C from-bundle remote -v | head -1'
echo
note "shallow clone"
r 'git clone -q --depth 2 file://$PWD/lab shallow 2>&1; git -C shallow log --oneline'
r 'cat shallow/.git/shallow'
r 'git -C shallow rev-list --count HEAD'
r 'git -C shallow fetch --deepen 1 2>&1 | tail -1; git -C shallow log --oneline | wc -l'
r 'git -C shallow fetch -q --unshallow; git -C shallow log --oneline | wc -l; ls shallow/.git/shallow 2>&1 | head -1'
echo
note "partial clone"
git -C lab config uploadpack.allowFilter true; git -C lab config uploadpack.allowAnySHA1InWant true
r 'git clone -q --filter=blob:none --no-checkout file://$PWD/lab partial 2>&1; git -C partial config --get-regexp "^remote.origin.(promisor|partialclonefilter)"'
r 'git -C partial count-objects -v | grep -E "^(count|in-pack)"'
r 'git -C partial rev-list --objects --all --missing=print | grep -c "^?"'
r 'git -C partial cat-file -t HEAD:big.txt'
r 'git -C partial rev-list --objects --all --missing=print | grep -c "^?"'
r 'git -C partial checkout -q main; git -C partial rev-list --objects --all --missing=print | grep -c "^?"'
echo
note "protocol v2 on the wire"
r 'GIT_TRACE_PACKET=1 git ls-remote file://$PWD/lab 2>&1 | head -12 | cut -c16-110'
r 'git -c protocol.version=0 ls-remote lab 2>&1 | head -1 | cut -c1-60; GIT_TRACE_PACKET=1 git -c protocol.version=0 ls-remote file://$PWD/lab 2>&1 | grep -m1 "upload-pack>" | cut -c16-90'
echo
note "maintenance and commit-graph"
r 'git -C lab commit-graph write --reachable; ls lab/.git/objects/info'
r 'git -C lab commit-graph verify; echo rc=$?'
r 'git -C lab maintenance run --task=commit-graph --task=loose-objects; echo rc=$?'
r 'git -C lab maintenance register; git config --global --get-all maintenance.repo | sed "s#.*/work#/home/you#"; git -C lab config --get maintenance.strategy'
