#!/usr/bin/env bash
# Chapter 16 exercise solutions.
. "$(dirname "$0")/../lib.sh"
sandbox ch16x
git init -q lab; cd lab; w f.txt base; mkdir docs; w docs/d.txt doc; git add .; c "Base"
git switch -q -c topic
GIT_AUTHOR_NAME="Bob Builder" GIT_AUTHOR_EMAIL=bob@example.com bash -c 'echo g > g.txt; git add g.txt; git commit -q -m "Add g"'; tick
GIT_AUTHOR_NAME="Bob Builder" GIT_AUTHOR_EMAIL=bob@example.com bash -c 'echo more >> f.txt; git commit -q -am "Edit f"'; tick
note "ex1"
r 'git format-patch -q -2 -o ../p; ls ../p'
r 'git clone -q -b main . ../c; cd ../c; git am -q ../p/*.patch; git log --format="%h author=%an <%ae> %ad committer=%cn" --date=short -2; cd ../lab'
r 'git log --format="%h author=%an <%ae> %ad committer=%cn" --date=short -2'
note "ex2"
r 'git notes --ref=review add -m "ok" HEAD; git log -1 --format="%h %s%n%N"; git log -1 --show-notes=review --format="%h %s%n%N"'
note "ex3"
r 'git archive --format=zip -o ../out.zip HEAD ":!docs"; python3 -m zipfile -l ../out.zip | awk "NR>1{print \$1}"'
echo 'docs/ export-ignore' > .gitattributes
r 'git archive HEAD | tar -t; git archive --worktree-attributes HEAD | tar -t'
r 'git add .gitattributes; git commit -q -m "Ignore docs in archives"; git archive --format=zip HEAD | python3 -c "import zipfile,sys,io; print(zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())).namelist())"'
