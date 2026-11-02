#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"
sandbox ch03x
git init -q d; cd d
w a 1; git add .; c base
git switch -q -c x; w x 1; git add .; c x
git switch -q main; w m 1; git add .; c m
r 'git merge x -m merge'
r "git log -1 --format='%p' main"
r 'git rev-list --parents -n1 main | wc -w'
