#!/usr/bin/env bash
# Chapter 18: build a repo with minigit.py, then check it with the real git.
. "$(dirname "$0")/../lib.sh"
sandbox ch18
MG="python3 $LIB_DIR/ch18/minigit.py"
mkdir proj; cd proj
r "$MG init; ls .git; cat .git/HEAD"
w hello.txt "hello"; mkdir -p src; w src/main.c "int main(void){return 0;}"
r "$MG add hello.txt src/main.c"
r "git ls-files -s"
r "git status -s; echo rc=\$?"
r "$MG commit 'first commit'"
r "git fsck --strict; echo rc=\$?"
r "git log --format='%H %an %s'"
w hello.txt "hello again"; tick
r "$MG add hello.txt"
r "$MG commit 'second commit'"
r "$MG log"
r "$MG cat-file \$(git rev-parse HEAD^{tree})"
r "git ls-tree -r HEAD"
r "git show -s --format=%B HEAD~1"
echo
note "same bytes: ask real git to build the same commit"
r "git commit-tree -p HEAD~1 -m 'second commit' \$(git rev-parse HEAD^{tree}) | cut -c1-12; git rev-parse --short=12 HEAD"
r "git fsck --strict; echo rc=\$?"
