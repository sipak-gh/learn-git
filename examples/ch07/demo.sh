#!/usr/bin/env bash
# Chapter 7: revisions and ranges.
. "$(dirname "$0")/../lib.sh"
sandbox ch07
git init -q lab; cd lab
for n in A B; do w f.txt $n; git add .; c $n; done
git tag base
git switch -q -c topic; for n in X Y; do w t.txt $n; git add .; c $n; done
git switch -q main; for n in C D; do w m.txt $n; git add .; c $n; done
tick; git merge -q topic -m "M merge topic"
w f.txt E; git add -u; c E
git switch -q topic; w t.txt Z; git add .; c Z; git switch -q main
r 'git log --oneline --graph --decorate --all'
note "single revisions"
r 'git rev-parse HEAD HEAD^ HEAD~1 HEAD~1^1 HEAD~1^2 HEAD~2 HEAD~1^2~1'
r 'git rev-parse --short main@{1}'
r 'git log --format=%s -1 :/"merge topic"'
r 'git log --format=%s -1 :/^C'
r 'git show --format=%s -s HEAD^{/Y}'
r 'git rev-parse HEAD:f.txt; git show HEAD~2:m.txt; git show :f.txt'
r 'git rev-parse main@{upstream} 2>&1 | tail -1'
r 'git rev-parse @ HEAD'
r 'git rev-parse --verify -q nosuch; echo rc=$?'
r 'git rev-parse --symbolic-full-name topic'
r 'git rev-parse --git-dir --is-bare-repository --show-prefix'
r 'git rev-parse --short=10 HEAD'
echo
note "repository discovery"
mkdir -p src/deep
r 'cd src/deep; git rev-parse --show-prefix --show-cdup; git log --oneline -1; cd ../..'
r 'cd ..; GIT_CEILING_DIRECTORIES=$PWD git log --oneline -1 2>&1'
r 'git --git-dir=lab/.git log --oneline -1; GIT_DIR=lab/.git git rev-parse --is-inside-work-tree; cd lab'
echo
note "ranges"
r 'git log --format=%s main..topic'
r 'git log --format=%s topic..main'
r 'git log --format=%s main...topic'
r 'git log --left-right --format="%m %s" main...topic'
r 'git log --format=%s ^topic main'
r 'git log --format=%s main --not topic base'
r 'git log --format=%s HEAD~2..HEAD'
r 'git log --format=%s -n2 --first-parent'
r 'git log --format=%s --first-parent base..main'
r 'git log --format=%s --no-merges base..main'
r 'git log --format=%s --merges'
r 'git log --format=%s --ancestry-path base..topic'
r 'git log --format=%s -- m.txt'
echo
note "rev-list and merge-base"
r 'git rev-list --count main'
r 'git rev-list --count topic..main'
r 'git rev-list --left-right --count main...topic'
r 'git rev-list --max-count=2 --reverse main'
r 'git rev-list --parents -n1 HEAD~1'
r 'git rev-list --objects -n2 main | head -4'
r 'git merge-base main topic'
r 'git merge-base --is-ancestor topic main; echo rc=$?'
r 'git merge-base --all HEAD~1 topic'
r 'git merge-base --octopus main topic base'
r 'git branch --merged main; git branch --no-merged main'
r 'git branch --contains base'
r 'git log --since="2024-01-01T03:00:00" --until="2024-01-01T05:00:00" --format="%s %cd" --date=iso'
r 'git diff --stat base HEAD'
r 'git diff topic...main --stat'
r 'git diff topic..main --stat'
