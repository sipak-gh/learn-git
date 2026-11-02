#!/usr/bin/env bash
# Chapter 14 exercise solutions, using local repositories as remotes.
. "$(dirname "$0")/../lib.sh"
sandbox ch14x
git config --global protocol.file.allow always
git init -q foo; cd foo; w foo.c "int foo;"; git add .; c "foo v1"; cd ..
git init -q --bare foo-remote.git; git -C foo push -q ../foo-remote.git main
git init -q app; cd app; w main.c "int main;"; git add .; c "app"
note "ex1"
r 'git submodule add -q ../foo libs/foo; git commit -q -m "add foo"'
r 'git ls-tree HEAD libs/; git ls-tree HEAD libs/foo; git ls-files -s libs/foo'
cd ..
note "ex2"
r 'git clone -q --recurse-submodules app app2 2>&1; git -C app2 submodule status'
note "ex3"
cd app; git config -f .gitmodules submodule.libs/foo.url ../foo-remote.git; git submodule sync -q
git -C libs/foo remote set-url origin "$PWD/../foo-remote.git"; git -C libs/foo fetch -q
git add .gitmodules; c "use foo-remote"
git init -q --bare ../app-remote.git; git remote add origin ../app-remote.git
git -C libs/foo commit -q --allow-empty -m "detached work"
git add libs/foo; c "bump foo"
r 'git push --recurse-submodules=check origin main 2>&1 | head -3'
r 'git -C libs/foo switch -q -c fix; git -C libs/foo push -q -u origin fix 2>&1; git push --recurse-submodules=check origin main 2>&1 | tail -1'
cd ..
note "ex4"
git init -q mono; cd mono; for d in api docs web; do mkdir $d; w $d/a.txt $d; done; w README r; git add .; c "mono"
r 'git sparse-checkout init --cone; git sparse-checkout set docs; ls'
r 'git sparse-checkout disable; ls'
