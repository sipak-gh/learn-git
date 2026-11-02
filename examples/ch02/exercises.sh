#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"
sandbox ch02x
git init -q d; cd d
w todo.txt "buy milk"; for i in 2 3 4 5 6 7 8 9 10 11; do a todo.txt "task $i"; done; a todo.txt "sleep"
git add .; c "base"
sed -i -e '1s/.*/buy oat milk/' -e '$s/.*/sleep early/' todo.txt
note ex1
r 'printf "n\ny\n" | git add -p >/dev/null; git diff --staged --stat'
r "git diff --staged | grep '^[-+]sleep'"
note ex2
git reset -q; git checkout -q .
git init -q ../e; cd ../e
w secret.txt s; git add secret.txt
r 'git rm --cached secret.txt; git status -s'
r 'git restore --staged secret.txt'
cd ../d
git add -A; c next; w secret2.txt s; git add secret2.txt
r 'git restore --staged secret2.txt; git status -s'
