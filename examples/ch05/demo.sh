#!/usr/bin/env bash
# Chapter 5: the index.
. "$(dirname "$0")/../lib.sh"
sandbox ch05
git init -q lab; cd lab
w a.txt "one"; w b.txt "two"; mkdir d; w d/c.txt "three"
git add .; c "Base"
r 'git ls-files'
r 'git ls-files -s'
r 'git ls-files --debug a.txt'
r 'xxd .git/index | head -2'
r 'git ls-files -s | wc -l; wc -c < .git/index'
note "index vs working tree vs HEAD"
w a.txt "ONE"
r 'git ls-files -m'
r 'git update-index --refresh'
r 'git diff-files --name-status'
r 'git add a.txt; git diff-index --cached HEAD --name-status'
r 'git diff-index HEAD --name-status'
git restore --staged --worktree a.txt
echo
note "add -p is: diff -> edit -> apply --cached"
printf 'x1\nx2\nx3\nx4\nx5\nx6\nx7\nx8\nx9\n' > long.txt; git add long.txt; c "long"
sed -i -e '1s/.*/X1/' -e '9s/.*/X9/' long.txt
git diff -U1 long.txt > ../full.patch
r 'grep -c "^@@" ../full.patch'
r 'git apply --cached --recount ../full.patch && git diff --cached --stat'
git reset -q; git checkout -q long.txt
note "git apply --cached stages a patch without touching the working tree"
echo
note "intent to add"
w new.txt "brand new"
r 'git add -N new.txt && git status -s && git diff | head -5'
r 'git ls-files -s new.txt'
r 'git rm -q --cached new.txt; rm new.txt'
echo
note "plumbing without the working tree"
r 'git update-index --add --cacheinfo 100644,$(echo hi | git hash-object -w --stdin),virtual.txt && git status -s'
r 'git update-index --force-remove virtual.txt && git status -s'
r 'GIT_INDEX_FILE=.git/tmp-index git read-tree HEAD && GIT_INDEX_FILE=.git/tmp-index git ls-files | head -2'
r 'git read-tree --empty && git status -s | head -3'
r 'git reset -q && git status -s'
echo
note "conflict: stages 1, 2, 3"
git switch -q -c side; w a.txt "side"; git commit -qam "side"; tick
git switch -q main; w a.txt "main"; git commit -qam "main"
r 'git merge side'
r 'git ls-files -s a.txt'
r 'git ls-files -u'
r 'git show :1:a.txt; git show :2:a.txt; git show :3:a.txt'
r 'git status -s'
r 'cat a.txt'
r 'git checkout --ours a.txt && git add a.txt && git ls-files -s a.txt'
r 'git merge --abort 2>&1; git status -s'
echo
note "racy git: stat data cache"
r 'git ls-files --debug a.txt | sed -n 2,3p'
r 'git config core.trustctime; git config core.checkStat; git config core.untrackedCache; echo "(unset prints nothing)"'
echo
note "assume-unchanged and skip-worktree"
r 'git update-index --skip-worktree b.txt && git ls-files -v | head -3'
w b.txt "edited"
r 'git status -s'
r 'git update-index --no-skip-worktree b.txt && git status -s'
git checkout -q b.txt
note "sparse checkout sets skip-worktree on the index entries (cone mode keeps all top-level files)"
mkdir e; w e/f.txt x; git add e; c "Add e/"
r 'git sparse-checkout init --cone && git sparse-checkout set d; git sparse-checkout list; git ls-files -v; ls'
r 'git sparse-checkout disable && ls'
