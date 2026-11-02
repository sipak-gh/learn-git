#!/usr/bin/env bash
# Chapter 13 exercise solutions.
. "$(dirname "$0")/../lib.sh"
sandbox ch13x
git init -q ex1; cd ex1
note "ex1 (random data, so sizes vary per run)"
r 'base64 /dev/urandom | head -c 100000 > f; git add f; git commit -qm 1; sed -i "3s/.*/changed/" f; git commit -qam 2; du -sb .git | cut -f1'
r 'git gc -q; du -sb .git | cut -f1'
note "ex2"
r 'git verify-pack -v .git/objects/pack/*.idx | awk "NF==7"'
note "ex3"
r 'git bundle create ../all.bundle --all 2>&1 | tail -1; cd ..; git clone -q all.bundle copy; git -C copy log --oneline | wc -l'
note "ex4"
r 'git clone -q --depth 1 file://$PWD/ex1 shallow; git -C shallow rev-list --count HEAD'
r 'git -C shallow fetch -q --unshallow; git -C shallow rev-list --count HEAD; test -f shallow/.git/shallow || echo "no .git/shallow"'
