#!/usr/bin/env bash
# Chapter 4: the object database, built by hand with plumbing.
. "$(dirname "$0")/../lib.sh"
sandbox ch04
r 'git init -q lab && cd lab'
r 'find .git -maxdepth 1 | sort'
r 'find .git/objects | head'
note "blob: header + content, hashed with SHA-1"
r 'printf "hello\n" | git hash-object --stdin'
r 'printf "blob 6\0hello\n" | sha1sum'
r 'printf "hello\n" | git hash-object -w --stdin'
r 'find .git/objects -type f'
r 'git cat-file -t ce013625030ba8dba906f756967f9e9ca394464a'
r 'git cat-file -s ce013625030ba8dba906f756967f9e9ca394464a'
r 'git cat-file -p ce013625030ba8dba906f756967f9e9ca394464a'
r 'python3 -c "import zlib,sys; print(repr(zlib.decompress(open(\".git/objects/ce/013625030ba8dba906f756967f9e9ca394464a\",\"rb\").read())))"'
note "same content, any name: same object"
r 'echo hello > a.txt; cp a.txt b.txt; git hash-object a.txt b.txt'
echo
note "tree by hand"
r 'git update-index --add --cacheinfo 100644,ce013625030ba8dba906f756967f9e9ca394464a,hello.txt'
r 'git write-tree'
r 'git cat-file -p $(git write-tree)'
r 'git cat-file -p $(git write-tree) | git mktree | head -1'
r 'git ls-tree -r $(git write-tree)'
r 'git cat-file tree $(git write-tree) | xxd | head -4'
note "commit by hand"
tick
r 'git commit-tree -m "Hand-made commit" $(git write-tree)'
C=$(git commit-tree -m "Hand-made commit" $(git write-tree))
r "git cat-file -p $C"
r "git cat-file commit $C | od -c | head -3"
r "git update-ref refs/heads/main $C && git log --oneline"
r 'git status -s'
echo
note "a second commit, shared blob; subdirectory tree"
mkdir -p src; echo 'int main(){}' > src/main.c; echo "hello world" > a.txt
r 'git add src a.txt && git write-tree'
T=$(git write-tree)
tick
C2=$(git commit-tree -p $C -m "Second" $T)
git update-ref refs/heads/main $C2
r 'git cat-file -p HEAD^{tree}'
r 'git cat-file -p HEAD:src'
r 'git ls-tree -r -t HEAD'
r 'git cat-file -p HEAD~1^{tree}'
note "annotated tag object"
tick
git tag -a v1 -m "Release 1"
r 'git cat-file -p v1'
r 'git cat-file -t v1; git cat-file -t v1^{}'
echo
note "walk all objects"
r 'git cat-file --batch-all-objects --batch-check'
r 'git count-objects -v | head -3'
note "SHA-256 repo (experimental in 2.34)"
cd ..
r 'git init -q --object-format=sha256 s256 2>&1; cd s256 && echo hello | git hash-object --stdin && git rev-parse --show-object-format 2>&1'
