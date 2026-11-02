#!/usr/bin/env bash
# Chapter 12 exercise solutions, run against local bare repositories.
. "$(dirname "$0")/../lib.sh"
sandbox ch12x
git init -q --bare origin.git
git clone -q origin.git alice 2>/dev/null; cd alice
w a.txt a; git add .; c "initial"; git push -q origin main
cd ..; git clone -q origin.git bob; cd bob
git switch -q -c side; w s.txt s; git add .; c "side work"; git tag -a -m "tag on side" t-side
git push -q origin t-side; git push -q origin side; git push -q origin --delete side
cd ../alice
note "ex1"
r 'git config remote.origin.tagOpt --tags; git config remote.origin.prune true'
r 'git fetch 2>&1; git tag'
note "ex2"
git switch -q -c wip; w wip.txt wip; git add .; c "wip"; git switch -q main
r 'git push origin wip:refs/heads/review/wip 2>&1 | tail -1; git branch --list "review*"; git ls-remote origin "refs/heads/review/*"'
note "ex3"
w b.txt b; git add .; c "local 1"
r 'git fetch -q; git log --oneline origin/main..main'
r 'git push --dry-run origin main 2>&1'
note "ex4"
git push -q origin main
cd ../bob; git switch -q main; git pull -q --ff-only; cd ../alice
git commit -q --amend -m "local 1 (amended)"
cd ../bob; w bob.txt bob; git add .; c "bob work"; git push -q origin main; cd ../alice
r 'git push --force-with-lease origin main 2>&1 | grep "^ !"'
r 'git fetch -q; git push --force-with-lease --force-if-includes origin main 2>&1 | grep "^ !"'
r 'git push --force origin main 2>&1 | tail -1; git log --oneline -2 origin/main'
