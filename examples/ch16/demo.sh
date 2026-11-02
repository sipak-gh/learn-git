#!/usr/bin/env bash
# Chapter 16: patches, notes, archive, signing.
. "$(dirname "$0")/../lib.sh"
sandbox ch16
git init -q lab; cd lab
printf 'line1\nline2\nline3\n' > f.txt; git add .; c "Initial"
git switch -q -c topic
w g.txt gee; git add .; c "Add g

Longer explanation of why g exists."
printf 'line1\nline2 edited\nline3\n' > f.txt; git commit -qam "Edit f"; tick
git switch -q main
note "format-patch"
r 'git format-patch -o ../patches main..topic'
r 'cat ../patches/0001-*.patch'
r 'git format-patch -1 --stdout topic~1 | head -3 | cut -c1-70'
r 'git format-patch --cover-letter -o ../p2 main..topic >/dev/null; ls ../p2'
echo
note "apply vs am"
r 'git apply --stat ../patches/0001-*.patch'
r 'git apply --check ../patches/0001-*.patch; echo rc=$?'
r 'git am ../patches/*.patch'
r 'git log --format="%h %an %ad | %cn %cd | %s" --date=short -3'
r 'git diff --stat topic main; echo rc=$?'
echo
note "am with a conflict"
git reset -q --hard main~2
printf 'line1\nline2 CHANGED ELSEWHERE\nline3\n' > f.txt; git commit -qam "Conflicting"
r 'git am ../patches/0002-*.patch 2>&1; echo rc=$?'
r 'git status -sb | head -3'
r 'git am --abort; git status -sb | head -1'
r 'git am --3way ../patches/0002-*.patch 2>&1 | head -4'
r 'git am --show-current-patch=diff | head -3; git am --abort'
echo
note "apply to the worktree only, reject files"
r 'git apply --reject ../patches/0002-*.patch 2>&1; ls; git status -s'
r 'cat f.txt.rej | head -4'
rm -f f.txt.rej; git reset -q --hard
echo
note "request-pull"
r 'git remote add origin ../lab 2>/dev/null; git request-pull main ../lab topic 2>&1 | head -12'
echo
note "send-email (dry run)"
r 'git send-email --version 2>&1 | head -2; git send-email --help >/dev/null 2>&1; echo rc=$?'
r 'git send-email --dry-run --to=list@example.com --from=ada@example.com --smtp-server=/bin/true ../patches/0001-*.patch 2>&1 | head -8'
echo
note "notes"
git switch -q topic
r 'git notes add -m "reviewed by Bob" HEAD; git notes show HEAD'
r 'git log -1 --format=%B%n--%n%N'
r 'git notes list | head -2; git rev-parse refs/notes/commits'
r 'git notes --ref=ci add -m "build: pass" HEAD~1; git log --show-notes=ci -2 --format="%h %s%n%N"'
r 'git ls-tree --name-only refs/notes/commits | cut -c1-12 | head -1; git log --oneline refs/notes/commits'
echo
note "archive"
r 'git archive --format=tar.gz --prefix=proj/ -o ../proj.tar.gz topic; tar tzf ../proj.tar.gz'
r 'git archive --format=zip topic f.txt | python3 -c "import zipfile,sys,io; print(zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())).namelist())"'
echo
note "signing with GPG"
export GNUPGHOME="$PWD/../gnupg"; mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"
cat > ../keyparams <<'EOF'
%no-protection
Key-Type: EDDSA
Key-Curve: ed25519
Name-Real: Ada Lovelace
Name-Email: ada@example.com
Expire-Date: 0
%commit
EOF
gpg --batch --quiet --generate-key ../keyparams 2>&1 | head -2
KEY=$(gpg --list-secret-keys --with-colons | awk -F: '/^sec/{print $5; exit}')
git config user.signingkey "$KEY"
echo "$KEY" | wc -c
w s.txt sign; git add .; tick
r 'git commit -q -S -m "Signed commit" 2>&1; git log -1 --show-signature --format="%h %G? %GS" 2>&1 | sed "s/^gpg: Signature made .*/gpg: Signature made <date>/"'
r 'git cat-file -p HEAD | sed -n "/^gpgsig/,/END PGP/p" | head -3'
tick; r 'git tag -s v1.0 -m "signed tag" 2>&1; git tag -v v1.0 2>&1 | sed "s/^gpg: Signature made .*/gpg: Signature made <date>/"'
r 'git verify-commit HEAD 2>&1 | tail -1'
r 'git log --format="%h %G?" -3'
r 'git config commit.gpgsign true; git config tag.gpgsign true; git config --get-regexp "gpgsign"'
git config --unset commit.gpgsign; git config --unset tag.gpgsign
echo
note "signing with SSH keys"
unset GNUPGHOME
ssh-keygen -q -t ed25519 -N "" -C ada@example.com -f ../id_sign
git config gpg.format ssh; git config user.signingkey "$PWD/../id_sign.pub"
printf 'ada@example.com %s\n' "$(cut -d' ' -f1,2 ../id_sign.pub)" > ../allowed_signers
w s2.txt sign2; git add .; tick
r 'git commit -q -S -m "SSH signed" 2>&1; git log -1 --format="%h %G?"'
git config gpg.ssh.allowedSignersFile "$PWD/../allowed_signers"
r 'git log -1 --format="%h %G? %GS"'
r 'git verify-commit HEAD 2>&1'
r 'git cat-file -p HEAD | sed -n "/^gpgsig/,/END SSH/p" | head -2'
