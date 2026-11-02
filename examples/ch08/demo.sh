#!/usr/bin/env bash
# Chapter 8: reading and searching history.
. "$(dirname "$0")/../lib.sh"
sandbox ch08
git init -q lab; cd lab
as() { export GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2"; }
as "Ada Lovelace" ada@example.com
cat > calc.py <<'EOF'
def add(a, b):
    return a + b

def sub(a, b):
    return a - b
EOF
git add .; c "Add add and sub"; git tag v0.1
as "Grace Hopper" grace@example.com
cat >> calc.py <<'EOF'

def mul(a, b):
    """Multiply two numbers together and return the product."""
    return a * b
EOF
git add .; c "Add mul"
as "Ada Lovelace" ada@example.com
sed -i 's/return a - b/return a-b/' calc.py; git add .; c "Tighten sub"
cat >> calc.py <<'EOF'

def div(a, b):
    if b == 0:
        raise ZeroDivisionError("b is zero")
    return a / b
EOF
git add .; c "Add div with zero check"
as "Grace Hopper" grace@example.com
sed -i 's/ZeroDivisionError("b is zero")/ValueError("b is zero")/' calc.py; git add .; c "Use ValueError"
python3 - <<'EOF'
s = open('calc.py').read()
i = s.index("\ndef mul"); j = s.index("\ndef div")
open('calc.py', 'w').write(s[:i] + s[j:] + s[i:j])
EOF
git add .; c "Move mul to the end"
git mv calc.py mathlib.py; c "Rename calc to mathlib"
r 'git log --oneline'
r 'git log --format="%h %an <%ae> %ad %s" --date=short -3'
r 'git log --pretty=format:"%h|%an|%ar|%s" -n2 | cut -d"|" -f1,2,4; echo'
r 'git log --stat --format="--- %h %s" -2'
r 'git log --name-status --format=%s -3'
r 'git log --author=Grace --format=%s'
r 'git log --grep="^Add" --format=%s'
r 'git log --grep=valueerror -i --format=%s'
echo
note "pickaxe: -S counts occurrences, -G greps changed lines"
r 'git log -S"ZeroDivisionError" --oneline'
r 'git log -S"b is zero" --oneline'
r 'git log -G"b is zero" --oneline'
r 'git log -G"a ?- ?b" --oneline'
r 'git log -L:sub:mathlib.py --format="--- %h %s"'
r 'git log -L 4,5:mathlib.py --format="--- %h %s" -s'
echo
note "blame"
r 'git blame mathlib.py'
r 'git blame -L 4,5 --porcelain mathlib.py | head -12'
r 'git blame -e -L1,1 mathlib.py'
echo
note "blame -w, -M, -C and ignore-revs"
git switch -q -c refactor
sed -i 's/^    return a + b/        return a + b/' mathlib.py
tick; git commit -qam "Indent add by 4 more"; IND=$(git rev-parse HEAD)
r 'git blame -L 1,2 mathlib.py'
r 'git blame -w -L 1,2 mathlib.py'
r 'echo "$IND # indent only" > .git-blame-ignore-revs; git blame --ignore-revs-file .git-blame-ignore-revs -L 1,2 mathlib.py'
python3 - <<'EOF'
s = open('mathlib.py').read()
i = s.index("def mul")
open('extra.py', 'w').write("# extras\n\n" + s[i:])
open('mathlib.py', 'w').write(s[:i].rstrip() + "\n")
EOF
git add .; c "Move mul to extra.py"
r 'git blame -L 3,5 extra.py'
r 'git blame -C -L 3,5 extra.py'
echo
note "shortlog, describe, grep"
git switch -q main
r 'git shortlog -sn HEAD'
r 'git shortlog -sne HEAD'
r 'git shortlog -n HEAD'
r 'git describe --tags'
r 'git describe --tags --long --match "v*"'
r 'git grep -n "def " -- "*.py"'
r 'git grep -c "return"'
r 'git grep -n -e "ValueError" --or -e "Multiply"'
r 'git grep -n "return a + b" HEAD~3'
r 'git grep --heading --break -n "def" HEAD~3'
echo
note "bisect"
cd ..; git init -q bis; cd bis
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if [ $i -ge 8 ]; then w state broken; else w state fine; fi
  w n $i; git add .; c "commit $i"
done
git tag good HEAD~11
printf '#!/bin/sh\ngrep -qx fine state\n' > ../test.sh; chmod +x ../test.sh
r 'git bisect start HEAD good'
r 'git bisect run ../test.sh'
r 'git bisect log | head -12'
r 'git bisect reset'
note "manual bisect"
r 'git bisect start HEAD good'
r 'git bisect good'
r 'git bisect bad'
r 'git bisect bad'
r 'git bisect reset'
echo
note "range-diff"
cd ..; git init -q rd; cd rd
for i in 1 2 3; do w f$i x; done; git add .; c base
git switch -q -c topic
for i in 1 2 3; do seq 1 6 > g$i; git add .; c "Add g$i"; done
git switch -q main; w main.txt m; git add .; c "Main moves on"
git switch -q -c v2 main
git cherry-pick topic~2 >/dev/null
git cherry-pick -n topic~1 >/dev/null; echo "extra" >> g2; git add .; tick; git commit -q -C topic~1
git cherry-pick topic >/dev/null
r 'git range-diff main topic v2'
