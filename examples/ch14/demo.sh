#!/usr/bin/env bash
. "$(dirname "$0")/../lab_dummy" 2>/dev/null
. "$(dirname "$0")/../lib.sh"
sandbox ch14
git config --global protocol.file.allow always
git init -q libfoo; cd libfoo; w foo.c "foo v1"; git add .; c "foo v1"; w foo.h "hdr"; git add .; c "add header"; cd ..
git init -q app; cd app; w main.c "main"; git add .; c "app init"
note "submodule add"
r 'git submodule add ../libfoo vendor/foo 2>&1 | tail -3'
r 'cat .gitmodules'
r 'git status -s'
r 'git ls-files -s vendor/foo .gitmodules'
r 'git diff --cached --submodule'
r 'cat vendor/foo/.git; ls .git/modules'
r 'git config --get-regexp "^submodule"'
c "add foo submodule"
r 'git cat-file -p HEAD^{tree}'
r 'git submodule status'
echo
note "clone with submodules"
cd ..
r 'git clone -q app app-clone; ls app-clone/vendor/foo | wc -l; git -C app-clone submodule status'
r 'git -C app-clone submodule update --init 2>&1 | tail -2; git -C app-clone submodule status'
r 'git clone -q --recurse-submodules app app-clone2 2>&1 | tail -1; ls app-clone2/vendor/foo'
echo
note "upstream moves; bump the pointer"
cd libfoo; w foo.c "foo v2"; git add .; c "foo v2"; cd ../app-clone
r 'git submodule status'
r 'git submodule update --remote --merge 2>&1 | tail -2; git submodule status'
r 'git status -s; git diff --submodule'
r 'git diff'
git add vendor/foo; c "bump foo"
r 'git submodule summary HEAD~1 2>&1 | head -4'
echo
note "pitfall: detached HEAD inside a submodule"
r 'git -C vendor/foo status -sb | head -1'
r 'git -C vendor/foo switch -q -c work; w vendor/foo/foo.c "local edit"; git -C vendor/foo commit -qam "local commit"; git status -s'
r 'git -C vendor/foo rev-parse --short HEAD; git ls-tree HEAD vendor/foo | cut -c1-60'
r 'git submodule update 2>&1 | tail -1; git -C vendor/foo status -sb | head -1'
r 'git config push.recurseSubmodules; git push --recurse-submodules=check origin HEAD:refs/heads/x 2>&1 | head -3'
echo
note "removing a submodule"
cd ../app
r 'git submodule deinit -f vendor/foo 2>&1; git rm -q -f vendor/foo; ls vendor 2>&1; cat .gitmodules 2>&1 | wc -c; ls .git/modules'
c "drop submodule"
echo
note "git subtree (contrib)"
cd ../app
r 'git subtree 2>&1 | head -2; ls $(git --exec-path)/git-subtree 2>&1 | head -1'
r 'git subtree add --prefix=lib/foo ../libfoo main --squash 2>&1 | tail -2'
r 'ls lib/foo; git log --oneline -3'
r 'git log -1 --format=%B HEAD^2 | head -5'
echo
note "sparse-checkout"
cd ..
git init -q mono; cd mono
for d in api web docs tools; do mkdir -p $d; for i in 1 2 3; do w $d/f$i.txt "$d $i"; done; done; w README top; git add .; c "monorepo"
r 'git sparse-checkout init --cone; git sparse-checkout set api docs; ls; cat .git/info/sparse-checkout'
r 'git sparse-checkout list; git config core.sparseCheckout; git ls-files -v | grep -c "^S"'
r 'git sparse-checkout add web; ls'
r 'git sparse-checkout disable; ls'
git config uploadpack.allowFilter true
r 'git clone -q --filter=blob:none --sparse file://$PWD ../mono-partial; cd ../mono-partial; git sparse-checkout set api; ls; git config --get-regexp "^(core.sparse|extensions|remote.origin.(promisor|partial))"; cd ../mono'
r 'git sparse-checkout --help >/dev/null 2>&1; echo rc=$?'
note "sparse index and set --cone on 2.34"
r 'git sparse-checkout init --cone --sparse-index; git sparse-checkout set docs; git config index.sparse; tr -c "[:print:]" "\n" < .git/index | grep -E "^(README|[a-z]+/)"'
r 'git sparse-checkout disable; git sparse-checkout set --cone docs; cat .git/info/sparse-checkout; git sparse-checkout disable'
r 'git config uploadpack.allowFilter false; git clone -q --filter=blob:none file://$PWD ../no-filter 2>&1 | head -1'

r 'git lfs version 2>&1 | head -1'
