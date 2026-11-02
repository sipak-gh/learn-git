#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"
sandbox ch01x
git init -q d; cd d
git config --local user.email "ada@work.example"
r 'git config --show-origin --show-scope --get user.email'
unset GIT_AUTHOR_NAME GIT_COMMITTER_NAME
r 'git -c user.name="Grace Hopper" commit --allow-empty -m "as grace" -q'
r 'git log -1 --format=%an'
