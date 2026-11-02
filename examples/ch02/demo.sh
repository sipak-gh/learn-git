#!/usr/bin/env bash
# Chapter 2: the everyday loop.
. "$(dirname "$0")/../lib.sh"
sandbox ch02
r 'git init -q notes && cd notes'
r 'git status'
w todo.txt "buy milk"; for i in 2 3 4 5 6 7 8 9 10 11; do a todo.txt "task $i"; done; a todo.txt "sleep"
printf 'build/\n*.log\n' > .gitignore
mkdir build; w build/out.o junk; w run.log noise
r 'git status -s'
r 'git status --ignored -s'
r 'git check-ignore -v run.log'
r 'git add todo.txt .gitignore && git commit -m "Add todo list"'
r 'git log --oneline'
note "partial staging: two hunks, stage one"
sed -i -e '1s/.*/buy oat milk/' -e '$s/.*/sleep early/' todo.txt
r 'git diff'
r 'printf "y\nn\n" | git add -p'
r 'git status -s'
r 'git diff --staged'
r 'git diff'
r 'git diff HEAD --stat'
r 'git commit -q -m "Oat milk" && git commit -qam "Sleep early" && git log --oneline --stat'
echo
note "rm, mv"
r 'git mv todo.txt tasks.txt && git status -s'
r 'git rm --cached tasks.txt && git status -s'
r 'git add tasks.txt && git rm -f tasks.txt && git status -s'
r 'git restore --source=HEAD --staged --worktree todo.txt; git status -s; ls'
echo
note "undo variants"
a todo.txt "oops"
r 'git add todo.txt && git restore --staged todo.txt && git status -s'
r 'git restore todo.txt && git status -s'
r 'git switch -c feature && git branch --show-current'
r 'git log --oneline -n 2 --format="%h %an %ad %s" --date=short'
r 'git show --stat HEAD'
note "clone"
cd ..
r 'git clone -q notes notes-copy && git -C notes-copy log --oneline | head -3'
r 'git -C notes-copy remote -v'
