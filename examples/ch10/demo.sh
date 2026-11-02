#!/usr/bin/env bash
# Chapter 10: rewriting history.
. "$(dirname "$0")/../lib.sh"
sandbox ch10
git init -q lab; cd lab
w a.txt one; git add .; c "add a"
w b.txt two; git add .; c "add b"
w c.txt three; git add .; c "add c"
note "amend"
r 'git log --oneline'
w c.txt three-fixed; git add .; tick
r 'git commit --amend --no-edit -q; git log --oneline'
r 'git reflog -3'
echo
note "reset: soft, mixed, hard"
w d.txt four; git add .; c "add d"
r 'git reset --soft HEAD~1; git status -s; git log --oneline | head -1'
r 'git reset -q; git status -s'
r 'git add d.txt; git reset --hard HEAD; git status -s; ls'
r 'git commit -q --allow-empty -m "oops"; git reset --hard HEAD~1; git log --oneline | head -1'
r 'git reset --hard ORIG_HEAD 2>&1; git log --oneline | head -1'
git reset -q --hard HEAD~1
echo
note "revert"
w d.txt four; git add .; c "add d"
w e.txt five; git add .; c "add e"
r 'git revert --no-edit HEAD~1'
r 'git log --oneline'
r 'ls'
echo
note "cherry-pick"
git switch -q -c feature HEAD~3
w f.txt feat; git add .; c "feature f"
w g.txt feat2; git add .; c "feature g"
git switch -q main
r 'git cherry-pick feature~1'
r 'git cherry-pick -x feature'
r 'git log --oneline -3'
echo
note "interactive rebase, scripted"
git switch -q -c work main
for n in 1 2 3 4; do w w$n.txt w$n; git add .; c "work $n"; done
r 'git log --oneline -4'
cat > .git/seq.sh <<'EOF'
#!/bin/sh
# Stand-in for the editor: save the todo list, then rewrite the first 4 lines.
cp "$1" .git/last-todo
awk 'NR==1{print "pick " $2} NR==2{print "squash " $2} NR==3{print "drop " $2} NR==4{print "reword " $2} NR>4' "$1" | grep -v '^#' > "$1.new"; mv "$1.new" "$1"
EOF
chmod +x .git/seq.sh
r 'sed -n 1,4p .git/seq.sh >/dev/null; GIT_SEQUENCE_EDITOR=.git/seq.sh GIT_EDITOR="sed -i 1s/\$/-reworded/" git rebase -i HEAD~4 2>&1 | tr "\r" "\n" | tail -3'
r 'head -4 .git/last-todo'
r 'git log --oneline -3'
r 'git log -1 --format=%B HEAD~1'
r 'git diff --stat HEAD~2 HEAD'
echo
note "autosquash and fixup commits"
w w1.txt w1-typo; git add .; c "fixup! work 1"
r 'git log --oneline -2'
r 'GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash HEAD~3'
r 'git log --oneline -3'
echo
note "--exec"
r 'git rebase -x "test -f w1.txt" HEAD~2'
r 'git rebase -x "test -f nonexistent.txt" HEAD~1 2>&1 | tr "\r" "\n"; git status | head -4'
r 'git rebase --abort; git status -sb | head -1'
echo
note "--onto"
git switch -q main
git switch -q -c base1 main; w base.txt B; git add .; c "base1 work"
git switch -q -c topic; w t1.txt t1; git add .; c "topic 1"; w t2.txt t2; git add .; c "topic 2"
git switch -q topic
git switch -q main; w mainline.txt M; git add .; c "main moves on"; git switch -q topic
r 'git log --oneline --graph --decorate main base1 topic'
r 'git rebase --onto main base1 topic 2>&1 | tr "\r" "\n" | tail -1'
r 'git log --oneline --graph --decorate main base1 topic'
echo
note "--rebase-merges"
git switch -q main
git switch -q -c rm-base; w r0.txt r0; git add .; c "rm0"
git switch -q -c side; w s1.txt s1; git add .; c "side 1"
git switch -q rm-base; w r1.txt r1; git add .; c "rm1"
tick; git merge -q --no-ff side -m "merge side"
git switch -q main; w m1.txt m1; git add .; c "main moves"
git switch -q rm-base
r 'git log --oneline --graph -5'
r 'git rebase main 2>&1 | tail -1; git log --oneline --graph -5'
git reset -q --hard ORIG_HEAD
r 'git rebase --rebase-merges main 2>&1 | tr "\r" "\n" | tail -1; git log --oneline --graph -6'
echo
note "recover with reflog"
git switch -q main
w x.txt x; git add .; c "will be lost"
LOST=$(git rev-parse --short HEAD)
r 'git reset --hard HEAD~1; git log --oneline | head -1'
r 'git reflog -3'
r "git reset --hard HEAD@{1}; git log --oneline | head -1"
echo
note "filter-branch (deprecated)"
r 'git filter-branch --tree-filter "rm -f x.txt" -- main~1..main 2>&1 | tail -2'
r 'git ls-tree --name-only HEAD | grep -c x.txt'
r 'git filter-repo --version 2>&1 | head -1'
echo
note "revert a merge commit with -m"
cd ..; git init -q revm; cd revm
w a.txt a; git add .; c "base"
git switch -q -c feat; w f.txt feat; git add .; c "feat work"
git switch -q main; w m.txt m; git add .; c "main work"
tick; git merge -q --no-ff feat -m "Merge feat"
r 'git revert --no-edit HEAD'
tick
r 'git revert --no-edit -m 1 HEAD; ls'
r 'git merge feat'
tick
r 'git revert --no-edit HEAD; ls'
echo
note "replace and fast-export/fast-import"
cd ..; git init -q repl; cd repl
w a.txt one; git add .; c "first"
w a.txt two; git add .; c "second"
w a.txt three; git add .; c "third"
r 'git log --oneline'
r 'git replace --graft HEAD~1; git replace -l; git log --oneline'
r 'git cat-file -p HEAD~1 | head -2; git for-each-ref refs/replace'
r 'git --no-replace-objects log --oneline | wc -l'
r 'git replace -d HEAD~1; git log --oneline | wc -l'
r 'git fast-export --all | head -12'
r 'git init -q --bare ../copy.git; git fast-export --all | git -C ../copy.git fast-import --quiet; git -C ../copy.git log --oneline main'
