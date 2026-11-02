#!/usr/bin/env bash
# Chapter 11: stash, worktrees, cleaning, restore --source, checkout -p.
. "$(dirname "$0")/../lib.sh"
sandbox ch11
git init -q lab; cd lab
printf 'one\ntwo\nthree\n' > a.txt; printf 'x\n' > b.txt
echo 'build/' > .gitignore
git add .; c "initial"
note "stash basics"
echo changed >> a.txt; echo staged >> b.txt; git add b.txt
echo untracked > new.txt; mkdir build; echo o > build/out.o
r 'git status -s'
r 'git stash push -m "wip: a and b"'
r 'git status -s'
r 'git stash list'
r 'git stash show'
r 'git stash show -p stash@{0} | head -12'
r 'git stash apply && git status -s'
r 'git stash drop'
r 'git stash list; echo "(empty)"'
git reset -q --hard
echo
note "index, untracked, ignored, pathspec"
echo changed >> a.txt; echo staged >> b.txt; git add b.txt
r 'git stash push -u -m "with untracked"'
r 'ls; git status -s'
r 'git stash pop --index'
r 'git status -s'
git reset -q --hard; rm -f new.txt
echo changed >> a.txt; echo staged >> b.txt
r 'git stash push -m "only a" -- a.txt'
r 'git status -s'
r 'git stash pop'
git reset -q --hard
mkdir -p build; echo o > build/out.o
r 'git stash push -a -m "all"; ls; git stash pop -q; ls build'
echo
note "stash internals: it is commits"
echo changed >> a.txt; echo staged >> b.txt; git add b.txt; echo untracked > new.txt
git stash push -u -q -m "inspect"
r 'cat .git/refs/stash | wc -c; git log --graph --oneline stash --all | head -4'
r 'git cat-file -p stash | sed "s/^\(author\|committer\).*/\1 .../"'
r 'git cat-file -p stash^3 | head -1; git ls-tree stash^3'
r 'git reflog show stash'
echo
note "stash branch, conflicts"
r 'git stash branch from-stash'
r 'git status -s; git stash list | wc -l'
git reset -q --hard; git switch -q main
echo changed-in-stash >> a.txt; git stash push -q
echo different >> a.txt; git commit -qam "main moves"
r 'git stash pop'
r 'git stash list'
git checkout -q --theirs a.txt 2>/dev/null; git reset -q --hard; git stash drop -q
echo
note "restore --source, checkout -p"
printf 'v1\n' > v.txt; git add .; c "v1"
printf 'v2\n' > v.txt; git commit -qam "v2"
r 'git restore --source=HEAD~1 v.txt && cat v.txt && git status -s'
r 'git restore --source=HEAD --staged --worktree v.txt && cat v.txt'
r 'git restore -p --source=HEAD~1 v.txt <<< n'
printf 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\nl11\nl12\n' > p.txt; git add .; c "p"
sed -i -e '2s/.*/CHANGED2/' -e '11s/.*/CHANGED11/' p.txt
r 'printf "n\ny\n" | git restore -p p.txt >/dev/null; git diff -U0 | grep "^[-+][^-+]"'
git reset -q --hard
echo
note "git clean"
mkdir -p dir build; echo u > untracked1; echo u > dir/untracked2; echo o > build/x.o
r 'git clean -n'
r 'git clean -nd'
r 'git clean -f; ls'
r 'git clean -fd; ls'
r 'git clean -ndx'
r 'git clean -fdx; ls build 2>&1 | head -1'
r 'git clean 2>&1'
echo
note "worktrees"
r 'git worktree add ../lab-hotfix -b hotfix'
r 'git worktree list'
r 'ls ../lab-hotfix; cat ../lab-hotfix/.git'
r 'ls .git/worktrees; cat .git/worktrees/lab-hotfix/gitdir; cat .git/worktrees/lab-hotfix/HEAD'
(cd ../lab-hotfix; w hot.txt fix; git add .; c "hotfix commit")
r 'git log --oneline -1 hotfix'
r 'git switch hotfix 2>&1'
r 'git worktree add ../lab-detached --detach HEAD~1; git worktree list'
r 'git worktree lock --reason "on usb" ../lab-detached; git worktree list'
r 'git worktree unlock ../lab-detached; git worktree remove ../lab-detached; git worktree list'
rm -rf ../lab-hotfix
r 'git worktree list; git worktree prune -v; git worktree list'
