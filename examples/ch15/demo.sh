#!/usr/bin/env bash
# Chapter 15: hooks, attributes, config.
. "$(dirname "$0")/../lib.sh"
sandbox ch15
git init -q lab; cd lab
w a.txt one; git add .; c "initial"
note "hooks: samples and a pre-commit hook"
r 'ls .git/hooks | head -5; ls .git/hooks | wc -l'
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
# reject commits that add the word FIXME
if git diff --cached -U0 | grep -q '^+.*FIXME'; then
  echo "pre-commit: FIXME found, aborting" >&2
  exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
echo "FIXME later" >> a.txt; git add a.txt
r 'git commit -m "add fixme"; echo rc=$?'
r 'git commit --no-verify -q -m "skip the hook"; echo rc=$?'
cat > .git/hooks/commit-msg <<'EOF'
#!/bin/sh
# $1 = path to the message file
if ! head -1 "$1" | grep -Eq '^[A-Z][^.]{0,71}$'; then
  echo "commit-msg: subject must start uppercase, <=72 chars, no trailing period" >&2
  exit 1
fi
EOF
chmod +x .git/hooks/commit-msg
echo more >> a.txt
r 'git commit -qam "lowercase subject"; echo rc=$?'
r 'git commit -qam "Proper subject"; echo rc=$?'
cat > .git/hooks/prepare-commit-msg <<'EOF'
#!/bin/sh
# $1 = message file, $2 = source (message, template, merge, squash, commit)
echo "hook args: $2" >&2
printf '\n[ticket: DEMO-1]\n' >> "$1"
EOF
chmod +x .git/hooks/prepare-commit-msg
echo more >> a.txt; tick
r 'git commit -qam "With trailer"; git log -1 --format=%B'
rm .git/hooks/prepare-commit-msg
echo
note "post-* hooks and pre-push"
cat > .git/hooks/post-commit <<'EOF'
#!/bin/sh
echo "post-commit: committed $(git rev-parse --short HEAD)"
EOF
cat > .git/hooks/pre-push <<'EOF'
#!/bin/sh
# stdin: <local ref> <local sha> <remote ref> <remote sha>
echo "pre-push to $1 ($2)" >&2
while read lref lsha rref rsha; do echo "  $lref $lsha -> $rref $rsha" | cut -c1-120 >&2; done
exit 1
EOF
chmod +x .git/hooks/post-commit .git/hooks/pre-push
echo more >> a.txt; tick
r 'git commit -qam "Hooked commit"'
git init -q --bare ../remote.git; git remote add origin ../remote.git
r 'git push origin main; echo rc=$?'
r 'git push --no-verify -q origin main; echo rc=$?'
echo
note "core.hooksPath: shared, versioned hooks"
rm .git/hooks/post-commit .git/hooks/pre-push .git/hooks/commit-msg .git/hooks/pre-commit
mkdir .githooks
cat > .githooks/pre-commit <<'EOF'
#!/bin/sh
echo "shared pre-commit ran"
EOF
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
echo x >> a.txt; tick
r 'git commit -qam "Via hooksPath"; echo rc=$?'
git config --unset core.hooksPath
echo
note "gitattributes: text/eol"
printf 'a\r\nb\r\n' > crlf.txt; printf 'a\nb\n' > lf.txt
r 'git add crlf.txt lf.txt 2>&1; git ls-files --eol crlf.txt lf.txt'
echo '*.txt text eol=lf' > .gitattributes; git add .gitattributes; tick; git commit -qm "Add attributes"
git rm -q --cached -r . ; git add . 2>&1
r 'git ls-files --eol crlf.txt lf.txt'
r 'git check-attr -a crlf.txt; git check-attr text eol -- lf.txt'
r 'git ls-files --eol a.txt'
rm -f crlf.txt lf.txt; git add -A; tick; git commit -qm "Drop eol samples"
echo
note "binary and diff drivers"
printf '\x00\x01\x02' > blob.bin; echo '*.bin binary' >> .gitattributes; git add .; tick; git commit -qm "Binary"
r 'git check-attr -a blob.bin'
printf 'one\n' > note.upper; echo '*.upper diff=upper' >> .gitattributes
git config diff.upper.textconv "tr a-z A-Z <"
git add .; tick; git commit -qm "upper"
printf 'two\n' > note.upper
r 'git diff note.upper'
r 'git diff --no-textconv note.upper | tail -3'
git config diff.upper.textconv ""
git commit -qam "Edit" 2>/dev/null
echo
note "merge drivers"
echo '*.lst merge=union' >> .gitattributes
printf 'base\n' > list.lst; git add .; tick; git commit -qm "list"
git switch -q -c x; echo ours >> list.lst; git commit -qam "x"
git switch -q main; echo theirs >> list.lst; git commit -qam "main"
r 'git merge x 2>&1 | tail -2; cat list.lst'
git config merge.keepours.driver "true"
echo 'keep.cfg merge=keepours' >> .gitattributes; printf 'v1\n' > keep.cfg; git add .; tick; git commit -qm "cfg"
git switch -q -c y; echo y > keep.cfg; git commit -qam "y"; git switch -q main; echo m > keep.cfg; git commit -qam "m"
r 'git merge y 2>&1 | tail -2; cat keep.cfg'
r 'git config merge.keepours.name "always keep ours"; git config --get-regexp "^merge.keepours"'
echo
note "clean/smudge filter and ident"
git config filter.redact.clean "sed 's/token=[a-z0-9]*/token=REDACTED/'"
git config filter.redact.smudge cat
printf 'token=abc123\n' > secret.conf; echo 'secret.conf filter=redact' >> .gitattributes
git add .; tick; git commit -qm "filters"
r 'git show HEAD:secret.conf; cat secret.conf'
echo
note "export-ignore and git archive"
echo 'tests export-ignore' >> .gitattributes; mkdir -p tests; echo t > tests/t.txt
echo '.gitattributes export-ignore' >> .gitattributes
git add .; tick; git commit -qm "export"
r 'git archive HEAD | tar -t | head -12'
r 'git archive --format=tar --prefix=proj-1.0/ HEAD | tar -t | head -3'
echo
note "config: levels, origin, includes, aliases"
r 'git config --show-origin --show-scope --get user.name | sed "s|$HOME|~|"'
r 'git config --list --show-origin | sed "s|$HOME|~|" | head -8'
mkdir -p "$HOME/work"; printf '[user]\n\temail = ada@work.example\n' > "$HOME/work.gitconfig"
git config --global includeIf."gitdir:$HOME/work/".path "$HOME/work.gitconfig"
git config --global include.path "$HOME/extra.gitconfig"; printf '[alias]\n\tco = checkout\n' > "$HOME/extra.gitconfig"
git init -q "$HOME/work/proj"
r 'git -C ~/work/proj config user.email'
r 'git config user.email'
r 'git config --global alias.lg "log --oneline --graph --decorate -5"; git config --global alias.last "log -1 --stat"; git config --global alias.sh "!echo shell alias in \$(pwd | xargs basename)"'
r 'git lg | head -3; git sh; git co --help 2>&1 | head -1'
r 'git config --global --unset alias.co; git config --get-regexp "^alias"'
r 'git config core.fileMode; git config core.autocrlf; git config --get core.editor; echo "(unset: $?)"'
echo
note "info/exclude and global ignore"
echo 'scratch.log' >> .git/info/exclude; echo log > scratch.log
r 'git status -s | head -3; git check-ignore -v scratch.log'
r 'git config --global core.excludesFile "$HOME/.gitignore_global"; echo "*.swp" > "$HOME/.gitignore_global"; touch x.swp; git check-ignore -v x.swp | sed "s#$HOME#~#"'
echo
note "ident, cachetextconv, a non-executable hook, includeIf hasconfig (2.36+)"
cd ..; git init -q more; cd more
echo '*.c ident' > .gitattributes; printf '/* $Id$ */\nint x;\n' > a.c; git add .; c "ident"
r 'rm a.c; git checkout a.c; head -1 a.c; git show HEAD:a.c | head -1; git rev-parse --short HEAD:a.c'
echo '*.upper diff=upper' >> .gitattributes; echo one > n.upper; git add .; c "upper 1"; echo two > n.upper; git commit -qam "upper 2"
git config diff.upper.textconv "tr a-z A-Z <"; git config diff.upper.cachetextconv true
r 'git log -p -1 n.upper | tail -2; git for-each-ref refs/notes'
printf '#!/bin/sh\necho never runs\n' > .git/hooks/pre-commit
r 'git commit -q --allow-empty -m "hook not executable" 2>&1'
printf '[user]\n\temail = ada@hasconfig.example\n' > "$HOME/hc.gitconfig"
git config --global includeIf."hasconfig:remote.*.url:**example.com**".path "$HOME/hc.gitconfig"
git remote add origin https://example.com/x.git
r 'git config user.email'
