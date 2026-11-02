#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"; bash "$(dirname "$0")/demo.sh" >/dev/null 2>&1; SB="$SCRATCH_ROOT/ch07"
cd "$SB/work/lab"
r 'git rev-list --reverse main..topic'
r 'git diff main...topic --stat'
r 'git merge-base --is-ancestor :/^X main; echo $?'
