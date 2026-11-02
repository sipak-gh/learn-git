#!/usr/bin/env bash
# Chapter 3: branches, merging, remotes in brief.
. "$(dirname "$0")/../lib.sh"
sandbox ch03
git init -q --bare server.git
git init -q app && cd app
w app.txt "line 1"; git add .; c "Start app"
r 'git remote add origin ../server.git && git push -u origin main 2>&1'
r 'git branch topic && git switch topic'
w topic.txt "topic work"; git add .; c "Topic work"
r 'git switch main'
r 'git merge topic'
r 'git log --oneline --graph --decorate'
note "diverge: merge commit"
r 'git switch -c other'
w other.txt "other"; git add .; c "Other work"
r 'git switch main'
w main.txt "main"; git add .; c "Main work"
r 'git merge other -m "Merge branch other"'
r 'git log --oneline --graph --decorate'
note "--no-ff forces a merge commit even when a fast-forward is possible"
git switch -q -c topic2; w t2.txt t2; git add .; c "Topic2 work"; git switch -q main
r 'git merge --no-ff topic2 -m "Merge topic2"'
r 'git log --oneline --graph -n 4'
r 'git branch -d topic other topic2 && git branch -vv'
r 'git push -q origin main && git branch -vv'
note "second clone and pull"
cd ..
git clone -q server.git peer && cd peer
export GIT_AUTHOR_NAME=Grace GIT_COMMITTER_NAME=Grace
w peer.txt "from peer"; git add .; c "Peer change"; git push -q origin main
cd ../app
r 'git fetch origin'
r 'git status -sb'
r 'git log --oneline main..origin/main'
r 'git pull --ff-only'
r 'git branch -a'
