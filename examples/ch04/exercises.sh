#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"
sandbox ch04x
git init -q d; cd d
note ex1
r 'printf "tree 0\n" > f.txt; wc -c < f.txt'
r 'printf "blob %s\0" $(wc -c < f.txt) | cat - f.txt | sha1sum'
r 'git hash-object f.txt'
note ex2
git add f.txt; T=$(git write-tree)
A=$(git commit-tree -m A $T); tick; B=$(git commit-tree -m B $T); tick
M=$(git commit-tree -m M -p $A -p $B $T)
r "git cat-file -p $M"
r "git rev-list --parents -n1 $M | wc -w"
note ex3
r "git write-tree"
r 'git cat-file -p HEAD 2>&1 | head -1'
r "git rev-parse $M^{tree} && git rev-parse $T"
