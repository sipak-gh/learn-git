#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"
sandbox ch05x
git init -q d; cd d
printf 'x1\nx2\nx3\nx4\nx5\nx6\nx7\nx8\nx9\n' > long.txt; git add .; c base
sed -i -e '1s/.*/X1/' -e '9s/.*/X9/' long.txt
git diff -U1 long.txt > ../full.patch
r 'grep -n "^@@" ../full.patch'
n=$(grep -n '^@@' ../full.patch | sed -n 2p | cut -d: -f1)
head -n $((n-1)) ../full.patch > ../first.patch
r 'git apply --cached --recount ../first.patch && git diff --cached --stat && git diff --stat'
