#!/usr/bin/env bash
# Chapter 1: setup, config levels, help, three areas.
. "$(dirname "$0")/../lib.sh"
sandbox ch01
r 'git --version'
r 'git config --global --list'
r 'git config --global core.editor "vim"'
r 'git config --show-origin --get user.name'
r 'git init -q demo'
cd demo
r 'git rev-parse --git-dir'
r 'git config --local user.email "ada@work.example"'
r 'git config --show-scope --list | grep -v "^local	core"'
r 'git config --list --show-origin | grep user'
echo
note "three areas"
w hello.txt "hello"
r 'git status -s'
r 'git add hello.txt && git status -s'
r 'git commit -q -m "first" && git status -s'
w hello.txt "hello, world"
r 'git status -s'
r 'git diff --stat'
r 'git diff --staged --stat'
echo
note "snapshots, not diffs: the commit's tree lists whole files"
r 'git ls-tree HEAD'
echo
note "help"
r 'git help -a | head -8'
r 'git commit -h 2>&1 | head -4'
r 'git help --config | grep -c .'
r 'git help -g | head -6'
