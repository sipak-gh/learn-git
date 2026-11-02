#!/usr/bin/env bash
# Chapter 6: references and HEAD.
. "$(dirname "$0")/../lib.sh"
sandbox ch06
git init -q lab; cd lab
w f.txt 1; git add .; c "one"; w f.txt 2; git commit -qam "two" ; tick; w f.txt 3; git commit -qam "three"
git switch -q -c feature; tick
r 'cat .git/HEAD'
r 'cat .git/refs/heads/main'
r 'find .git/refs -type f'
r 'git rev-parse main'
r 'git symbolic-ref HEAD'
r 'git symbolic-ref --short HEAD'
r 'git rev-parse --abbrev-ref HEAD'
r 'git branch --show-current'
echo
note "tags"
r 'git tag light'
r 'git tag -a -m "Version 1.0" v1.0 HEAD~1'
r 'find .git/refs/tags -type f'
r 'cat .git/refs/tags/light; cat .git/refs/tags/v1.0'
r 'git rev-parse v1.0 v1.0^{} light'
r 'git cat-file -t light; git cat-file -t v1.0'
r 'git tag -n; git tag -l "v*"'
r 'git show v1.0 --stat | head -8'
r 'git describe'
r 'git describe --always --abbrev=4 HEAD~1'
r 'git tag -d light'
echo
note "listing and plumbing"
r 'git for-each-ref'
r 'git for-each-ref --format="%(refname:short) %(objecttype) %(subject)" refs/tags'
r 'git show-ref'
r 'git update-ref refs/heads/scratch HEAD~2 && git branch -v'
r 'git update-ref -d refs/heads/scratch && git branch'
r 'git update-ref refs/heads/x HEAD HEAD~1 2>&1'
r 'git check-ref-format --branch "bad..name"; echo rc=$?'
r 'git check-ref-format refs/heads/ok/name; echo rc=$?'
echo
note "packed-refs"
r 'git pack-refs --all && find .git/refs -type f; cat .git/packed-refs'
r 'git branch newbranch && find .git/refs -type f'
r 'git branch -d newbranch && cat .git/packed-refs | wc -l'
echo
note "detached HEAD"
r 'git switch --detach HEAD~1'
r 'cat .git/HEAD'
r 'git status | head -2'
w g.txt "detached work"; git add g.txt; c "detached commit"
r 'git switch feature'
r 'git branch rescued HEAD@{1} && git log --oneline --graph --all'
echo
note "reflog"
r 'git reflog'
r 'cat .git/logs/HEAD | head -2'
r 'git reflog show feature'
r 'git rev-parse HEAD@{2} main@{1}'
r 'git log -g --format="%gd %gs" -n 3'
r 'git reflog expire --expire=now --all --dry-run | head -3'
echo
note "special refs"
r 'git reset -q --hard HEAD~1'
r 'cat .git/ORIG_HEAD; git rev-parse ORIG_HEAD'
r 'git reset -q --hard ORIG_HEAD && git log --oneline -1'
git switch -q main
git switch -q -c m1 main; w m.txt a; git add .; c m1; git switch -q main; w n.txt b; git add .; c n1
git merge -q --no-commit m1
r 'cat .git/MERGE_HEAD; git rev-parse m1; ls .git | grep MERGE'
git merge --abort
cd ..; git clone -q lab clone; cd clone
r 'git fetch -q origin; cat .git/FETCH_HEAD'
r 'ls .git/refs/remotes/origin; cat .git/refs/remotes/origin/HEAD'
