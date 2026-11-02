#!/usr/bin/env bash
# Chapter 15 exercise solutions.
. "$(dirname "$0")/../lib.sh"
sandbox ch15x
git init -q lab; cd lab; w a.txt a; git add .; c "initial"
note "ex1"
cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/sh
big=$(git diff --cached --name-only --diff-filter=AM | while read -r f; do
  [ "$(git cat-file -s ":$f")" -gt 102400 ] && echo "$f"; done)
[ -z "$big" ] || { echo "pre-commit: too big: $big" >&2; exit 1; }
HOOK
chmod +x .git/hooks/pre-commit
r 'head -c 200000 /dev/zero > big.dat; git add big.dat; git commit -q -m "add big"; echo rc=$?'
r 'git rm -q --cached big.dat; echo small > small.txt; git add small.txt; git commit -q -m "add small"; echo rc=$?'
rm big.dat
note "ex2"
echo '{"a":1}' > c.json; echo '*.json diff=json' > .gitattributes; git add .; c "json"
r 'git config diff.json.textconv "python3 -m json.tool"; echo "{\"a\":2,\"b\":[1]}" > c.json; git diff c.json | tail -n +5'
git checkout -q c.json
note "ex3"
mkdir -p "$HOME/oss"; printf '[user]\n\temail = ada@oss.example\n' > "$HOME/.gitconfig-oss"
r 'git config --global includeIf."gitdir:~/oss/".path ~/.gitconfig-oss; git init -q ~/oss/proj; git -C ~/oss/proj config user.email; git config user.email'
note "ex4"
r 'git config core.editor nano; git config --show-origin --show-scope --get core.editor'
