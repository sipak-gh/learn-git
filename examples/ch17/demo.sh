#!/usr/bin/env bash
# Chapter 17: debugging and recovery.
. "$(dirname "$0")/../lib.sh"
sandbox ch17
git init -q lab; cd lab
for i in 1 2 3 4 5 6; do w f.txt "v$i"; git add .; c "commit $i"; done
git tag good HEAD~4
git switch -q -c feature
w g.txt feature; git add .; c "feature work"
git switch -q main
note "deleting a branch and getting it back"
r 'git branch -D feature'
r 'git reflog --format="%h %gd %gs" | head -5'
echo
note "dangling objects"
r 'git fsck --lost-found 2>&1 | head -3'
CM=$(git fsck --lost-found 2>/dev/null | awk '/dangling commit/{print $3; exit}')
r "git log --oneline -1 $CM"
r "git branch feature $CM; git log --oneline -2 feature"
echo
note "reset --hard and reflog"
r 'git reset -q --hard HEAD~2; git log --oneline -1'
r 'git reflog -3 --format="%h %gd %gs"'
r 'git reset -q --hard HEAD@{1}; git log --oneline -1'
echo
note "dangling blob (added but never committed)"
echo "precious" > p.txt; git add p.txt; git rm -qf --cached p.txt; rm p.txt
r 'git fsck --lost-found 2>&1 | head -2'
B=$(git fsck --lost-found 2>/dev/null | awk '/dangling blob/{print $3; exit}')
r "git cat-file -p $B"
r 'ls .git/lost-found/other | head -2'
echo
note "reflog expiry and gc"
r 'git reflog expire --expire=now --all; git reflog -2 --format="%h %gs"'
r 'git gc --prune=now -q; git fsck --lost-found 2>&1 | head -2; echo rc=$?'
echo
note "corruption"
cd ..; git clone -q --no-local lab broken; cd broken
w f.txt local-only; git add .; c "local only"
P=$(git rev-parse HEAD); f=.git/objects/${P:0:2}/${P:2}
r "git fsck 2>&1; echo rc=\$?"
chmod u+w $f; echo garbage > $f
r "git fsck 2>&1 | head -4"
r "git cat-file -p $P 2>&1 | head -2"
rm $f
r "git fsck 2>&1 | head -3"
r "git update-ref refs/heads/main origin/main; git reflog expire --expire=now --all; git reset -q --hard main; git fsck 2>&1; echo rc=\$?"
r "git cat-file -t $P 2>&1"
echo
note "bisect run"
cd ../lab
w f.txt v7; git add .; c "commit 7"
cat > ../check.sh <<'EOF'
#!/bin/sh
# good if f.txt is older than v4
n=$(sed 's/v//' f.txt); [ "$n" -lt 4 ]
EOF
chmod +x ../check.sh
r 'git bisect start HEAD good >/dev/null; git bisect run ../check.sh 2>&1 | grep -E "^(running|bisecting|[0-9a-f]{40}|bisect)" | cut -c1-70'
r 'git bisect log | tail -3; git bisect reset 2>&1 | tail -1'
echo
note "GIT_TRACE"
T='sed -E "s/^[0-9:.]+ +//; s/^([a-z_.-]+\.c:[0-9]+) +/\1 /"'
git config alias.st "status -s"
r "GIT_TRACE=1 git st 2>&1 | $T | head -4"
r "GIT_TRACE_PERFORMANCE=1 git status -s 2>&1 | $T | sed -E 's/performance: [0-9.]+ s/performance: N s/' | head -2"
r "GIT_TRACE_SETUP=1 git status -s 2>&1 | $T | sed 's#$PWD#.#' | head -3"
