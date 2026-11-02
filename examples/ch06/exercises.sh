#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"
sandbox ch06x
git init -q d; cd d
w f 1; git add .; c one; w f 2; git commit -qam two; w f 3; git commit -qam three
git switch -q -c feature
r 'git update-ref -m "manual move" refs/heads/main HEAD~2 HEAD; git log --oneline main'
r 'git update-ref -m "again" refs/heads/main HEAD~1 HEAD 2>&1'
r 'git reflog show main'
