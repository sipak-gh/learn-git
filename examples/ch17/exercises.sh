#!/usr/bin/env bash
# Chapter 17 exercise solutions.
. "$(dirname "$0")/../lib.sh"
sandbox ch17x
git init -q lab; cd lab
for i in 1 2 3 4 5 6; do echo "version $i" > f.txt; git add f.txt; c "commit $i"; [ $i = 2 ] && git tag v1.0; done
note "ex1"
r 'git switch -q -c tmp; echo x > t; git add t; git commit -q -m tmp; git switch -q main; git branch -D tmp'
r 'git reflog --format="%h %gs" | grep "commit: tmp"'
r 'git branch tmp "$(git reflog --format="%h %gs" | grep -m1 "commit: tmp" | cut -d" " -f1)"; git log --oneline -1 tmp'
note "ex2"
r 'echo precious > p.txt; git add p.txt; git rm -q --cached -f p.txt; rm p.txt; git fsck --lost-found 2>&1 | grep blob'
r 'git cat-file -p "$(git fsck --lost-found 2>/dev/null | awk "/dangling blob/{print \$3}")"'
note "ex3"
printf '#!/bin/sh\nv=$(sed "s/version //" f.txt)\n[ "$v" -lt 4 ]\n' > ../t.sh; chmod +x ../t.sh
r 'git bisect start HEAD v1.0 >/dev/null; git bisect run ../t.sh 2>&1 | grep "is the first bad commit"; git bisect reset 2>&1 | tail -1'
