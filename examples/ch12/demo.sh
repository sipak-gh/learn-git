#!/usr/bin/env bash
# Chapter 12: remotes in depth, using local bare repositories.
. "$(dirname "$0")/../lib.sh"
sandbox ch12
git init -q --bare origin.git
git clone -q origin.git seed 2>/dev/null; cd seed
w README one; git add .; c "initial"; git push -q -u origin main 2>&1
cd ..
git clone -q origin.git alice
git clone -q origin.git bob; (cd bob; git config user.name Bob; git config user.email bob@example.com)
cd alice
note "what clone configured"
r 'git config --get-regexp "^(remote|branch)"'
r 'cat .git/config | sed -n "/remote/,\$p"'
r 'git remote -v'
r 'git remote show origin'
echo
note "remote-tracking branches live under refs/remotes"
r 'git branch -a -vv'
r 'git for-each-ref refs/remotes'
r 'cat .git/refs/remotes/origin/HEAD'
r 'git rev-parse origin/main main'
echo
note "refspecs"
r 'git ls-remote origin'
r 'git fetch origin "refs/heads/main:refs/remotes/origin/copy" 2>&1; git branch -r'
r 'git fetch origin main 2>&1; cat .git/FETCH_HEAD'
r 'git config --get-all remote.origin.fetch'
echo
note "fetch vs pull; ahead/behind"
cd ../bob; w bob.txt B; git add .; c "bob work"; git push -q origin main 2>&1
cd ../alice
r 'git fetch'
r 'git status -sb'
r 'git log --oneline main..origin/main'
r 'git pull --ff-only'
echo
note "rejected push, force-with-lease"
w a.txt A; git add .; c "alice local"
cd ../bob; w b2.txt B2; git add .; c "bob second"; git push -q origin main 2>&1; cd ../alice
r 'git push origin main'
r 'git fetch -q; git status -sb | head -1'
r 'git pull --rebase 2>&1 | tail -1'
r 'git push origin main 2>&1 | tail -2'
echo
note "force-with-lease"
git commit -q --amend -m "alice local (amended)" --date="2024-02-01T00:00:00"
r 'git push --force-with-lease origin main 2>&1 | tail -2'
cd ../bob; git pull -q --rebase; w b3.txt B3; git add .; c "bob third"; git push -q origin main 2>&1; cd ../alice
git commit -q --amend -m "alice amended again"
r 'git push --force-with-lease origin main 2>&1 | tail -4'
r 'git fetch -q; git reset -q --hard origin/main; git log --oneline -3'
echo
note "upstream tracking"
r 'git switch -c feature'
w f.txt f; git add .; c "feature"
r 'git push 2>&1 | head -3'
r 'git push -u origin feature 2>&1 | tail -2'
r 'git branch -vv'
r 'git config push.default'
r 'git config push.autoSetupRemote true; git switch -q -c f2; w f2 f2; git add .; c f2; git push 2>&1 | head -2'
r 'git config --unset push.autoSetupRemote'
r 'git branch -u origin/main f2; git rev-parse --abbrev-ref f2@{upstream}'
echo
note "delete, prune"
cd ../bob; git fetch -q; git push origin --delete feature 2>&1 | tail -1; cd ../alice
r 'git branch -r'
r 'git fetch --prune 2>&1; git branch -r'
r 'git remote prune origin; echo ok'
r 'git config fetch.prune true; git config --get fetch.prune'
echo
note "tags"
git tag -a v1 -m "release 1"; r 'git push origin v1 2>&1 | tail -1'
r 'git ls-remote --tags origin'
r 'git push origin --tags 2>&1 | tail -1'
echo
note "multiple remotes; triangular workflow"
cd ..; git clone -q --bare origin.git upstream.git
cd alice
r 'git remote add upstream ../upstream.git; git remote -v'
r 'git config remote.pushDefault origin; git config --get remote.pushDefault'
r 'git fetch upstream 2>&1; git branch -r'
r 'git remote rename upstream canon; git branch -r | tr "\n" " "'
r 'git remote set-url origin ../origin.git; git remote get-url origin'
r 'git remote remove canon; git branch -r | tr "\n" " "'
echo
note "push refspec tricks"
r 'git push origin HEAD:refs/heads/from-alice 2>&1 | tail -1'
r 'git push origin :from-alice 2>&1 | tail -1'
r 'git push --dry-run origin main 2>&1'
echo
note "url rewriting and credentials"
r 'git config url."https://example.invalid/".insteadOf "ex:"; git remote add tmp ex:foo.git; git remote get-url tmp'
r 'git config credential.helper; git credential-store 2>&1 | head -1'
printf 'protocol=https\nhost=example.com\nusername=ada\npassword=pw-example-123\n' | git -c credential.helper="store --file=$PWD/.git/cred" credential approve
r 'wc -l < .git/cred'
r 'printf "protocol=https\nhost=example.com\n\n" | git -c credential.helper="store --file=$PWD/.git/cred" credential fill'
