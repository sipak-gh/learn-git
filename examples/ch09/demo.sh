#!/usr/bin/env bash
# Chapter 9: diff internals and merge mechanics.
. "$(dirname "$0")/../lib.sh"
sandbox ch09
git init -q lab; cd lab
note "diff algorithms: a file where Myers and patience disagree"
printf '\nu0\n}\n\n}\n    return 0;\nu3\n    return 0;\n\n' > old.c
printf '\n}\n}\n\n    return 0;\nu3\n    return 0;\n\n' > new.c
r 'git diff --no-index --diff-algorithm=myers old.c new.c | tail -n +5'
r 'git diff --no-index --diff-algorithm=patience old.c new.c | tail -n +5'
r 'git diff --no-index --diff-algorithm=histogram old.c new.c | tail -n +5'
r 'git diff --no-index --diff-algorithm=minimal --stat old.c new.c'
r 'git config diff.algorithm histogram; git config --get diff.algorithm'
git config --unset diff.algorithm
echo
note "word diff"
printf 'The quick brown fox jumps over the lazy dog.\n' > s1; printf 'The quick red fox leaps over the lazy cat.\n' > s2
r 'git diff --no-index --word-diff s1 s2'
r 'git diff --no-index --word-diff=porcelain s1 s2'
r 'git diff --no-index --word-diff-regex=. --word-diff=plain s1 s2 | tail -1'
r 'git diff --no-index --color-words --color=always s1 s2 | cat -v | tail -1'
r 'git diff --no-index -U0 --ignore-all-space s1 s1; echo rc=$?'
rm -f old.c new.c s1 s2
echo
note "rename detection"
seq 1 40 > data.txt; git add .; c "data"
git mv data.txt renamed.txt; sed -i '5s/.*/five/' renamed.txt; git add .
r 'git diff --cached --stat -M'
r 'git diff --cached --name-status -M50%'
r 'git diff --cached --name-status --no-renames'
sed -i '1,30s/.*/changed &/' renamed.txt; git add .
r 'git diff --cached --name-status -M'
r 'git diff --cached --name-status -M30%'
c "rename"
cp renamed.txt copy.txt; echo more >> copy.txt; git add .
r 'git diff --cached --name-status -C'
r 'git diff --cached --name-status -C --find-copies-harder'
git reset -q --hard
echo
note "three-way merge by hand with merge-file"
printf 'a\nb\nc\nd\ne\n' > base.txt
printf 'a\nB-ours\nc\nd\ne\n' > ours.txt
printf 'a\nb\nc\nd\nE-theirs\n' > theirs.txt
r 'git merge-file -p ours.txt base.txt theirs.txt'
printf 'a\nb-theirs\nc\nd\ne\n' > theirs2.txt
r 'git merge-file -p ours.txt base.txt theirs2.txt; echo rc=$?'
r 'git merge-file -p --diff3 ours.txt base.txt theirs2.txt'
r 'git merge-file -p --zdiff3 ours.txt base.txt theirs2.txt 2>&1 | head -3'
rm -f base.txt ours.txt theirs.txt theirs2.txt
echo
note "a real conflict"
cat > greet.txt <<'EOF'
header
hello
middle
filler1
filler2
filler3
filler4
filler5
footer
EOF
git add .; c "greet"
git switch -q -c theirs; sed -i 's/^hello/hello, world/' greet.txt; sed -i 's/^footer/footer (theirs)/' greet.txt; git commit -qam "theirs edits"
git switch -q main; sed -i 's/^hello/hello there/' greet.txt; git commit -qam "ours edit"
r 'git merge theirs'
r 'cat greet.txt'
r 'git diff'
r 'git diff --ours --stat | tail -1; git diff --theirs --stat | tail -1'
r 'git checkout --conflict=diff3 greet.txt && sed -n 1,9p greet.txt'
r 'git checkout --merge greet.txt && sed -n 1,5p greet.txt'
r 'git log --merge --oneline'
r 'git merge --abort && git status -sb'
r 'git -c merge.conflictStyle=diff3 merge theirs | head -2'
r 'git merge --abort'
r 'git -c merge.conflictStyle=zdiff3 merge theirs 2>&1 | head -2'
r 'git merge -X ours theirs && cat greet.txt && git reset -q --hard HEAD~1'
r 'git merge -X theirs theirs && sed -n 1,2p greet.txt && git reset -q --hard HEAD~1'
r 'git merge -s ours theirs -m "Merge theirs (ours)" && sed -n 1,2p greet.txt && git reset -q --hard HEAD~1'
echo
note "resolve, commit"
git merge theirs >/dev/null 2>&1
printf 'header\nhello there, world\nmiddle\nfiller1\nfiller2\nfiller3\nfiller4\nfiller5\nfooter (theirs)\n' > greet.txt
r 'git add greet.txt && git commit -m "Merge theirs" && git log --oneline --graph'
git reset -q --hard HEAD~1
echo
note "rerere"
git config rerere.enabled true
git merge theirs >/dev/null 2>&1
r 'ls .git/rr-cache | wc -l'
printf 'header\nhello there, world\nmiddle\nfiller1\nfiller2\nfiller3\nfiller4\nfiller5\nfooter (theirs)\n' > greet.txt
r 'git add greet.txt && git commit -qm "Merge theirs (resolved)"'
r 'git rerere status; ls .git/rr-cache/*'
git reset -q --hard HEAD~1
r 'git merge theirs'
r 'git diff --stat; git status -sb | head -3'
r 'cat greet.txt | sed -n 2p'
r 'git rerere diff | head -3'
git reset -q --hard HEAD~0; git merge --abort 2>/dev/null; git reset -q --hard
echo
note "octopus"
for b in o1 o2 o3; do git switch -q -c $b main; w $b.txt $b; git add .; c "$b"; done
git switch -q main
r 'git merge o1 o2 o3 -m "Octopus"'
r 'git log --oneline --graph -5 | head -8'
r 'git cat-file -p HEAD | grep -c ^parent'
echo
note "subtree merge strategy option"
cd ..; git init -q lib; cd lib; w lib.c "lib"; git add .; c "lib v1"; cd ../lab
git remote add lib ../lib; git fetch -q lib
r 'git merge -s ours --no-commit --allow-unrelated-histories lib/main 2>&1 | head -2'
r 'git read-tree --prefix=vendor/lib/ -u lib/main && git commit -qm "Vendor lib" && ls vendor/lib'
