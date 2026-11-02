#!/usr/bin/env bash
. "$(dirname "$0")/../lib.sh"
sandbox ch10x
git init -q lab; cd lab
for n in 1 2 3 4; do w f$n $n; git add .; c "c$n"; done
echo "# ex1"
git branch fix; git reset -q --hard HEAD~1
git log --oneline main | head -1; git log --oneline fix | head -1
echo "# ex2"
git switch -q fix
git reset -q --soft HEAD~3 && git commit -q -m squashed
git log --oneline fix; git ls-files | tr '\n' ' '; echo
echo "# ex3"
git switch -q main; git reset -q --hard HEAD~2
git reset -q --hard ORIG_HEAD; git log --oneline | head -1
git reset -q --hard HEAD~2; git reset -q --hard HEAD@{1}; git log --oneline | head -1
echo "# ex4"
r 'git rebase -x "test -f f2" --root 2>&1 | tr "\r" "\n" | grep -v "^Rebasing"; git status | sed -n 1,4p'
r 'git rebase --abort; git status -sb | head -1'
