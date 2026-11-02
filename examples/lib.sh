# Shared helpers for the course demos. Source it: `. "$(dirname "$0")/../lib.sh"`.
# Builds a throwaway sandbox under learn-git/.scratch/ with a fixed identity and
# fixed dates, so object IDs are reproducible and your own configuration
# (~/.gitconfig, /etc/gitconfig) cannot change the output.
LIB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCRATCH_ROOT="$(cd "$LIB_DIR/.." && pwd)/.scratch"
mkdir -p "$SCRATCH_ROOT"

export LC_ALL=C TZ=UTC
export GIT_CONFIG_NOSYSTEM=1
unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_KEY_1 GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_0 GIT_CONFIG_VALUE_1 GIT_CONFIG_VALUE_2 GIT_OPTIONAL_LOCKS GIT_ASKPASS
export GIT_PAGER=cat PAGER=cat
export GIT_EDITOR=true GIT_TERMINAL_PROMPT=0

# sandbox NAME: fresh directory, isolated HOME and global config, cd into it.
sandbox() {
  SB="$SCRATCH_ROOT/$1"
  rm -rf "$SB"
  mkdir -p "$SB/home" "$SB/work"
  export HOME="$SB/home"
  export GIT_CONFIG_GLOBAL="$SB/home/.gitconfig"
  cat > "$GIT_CONFIG_GLOBAL" <<'EOF'
[user]
	name = Ada Lovelace
	email = ada@example.com
[init]
	defaultBranch = main
[advice]
	detachedHead = false
EOF
  export GIT_AUTHOR_NAME="Ada Lovelace" GIT_AUTHOR_EMAIL=ada@example.com
  export GIT_COMMITTER_NAME="Ada Lovelace" GIT_COMMITTER_EMAIL=ada@example.com
  TICK=0
  tick
  cd "$SB/work"
}

# tick: advance the fake clock by one hour.
tick() {
  TICK=$((TICK + 1))
  local ts
  ts=$(printf '2024-01-01T%02d:00:00+0000' "$TICK")
  [ "$TICK" -gt 23 ] && ts=$(printf '2024-01-02T%02d:00:00+0000' $((TICK - 24)))
  export GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts"
}

# r 'command line': print it as a prompt line, then run it (stdout+stderr).
r() {
  printf '$ %s\n' "$1"
  eval "$1" 2>&1
  return 0
}

# c MESSAGE: commit with the next fake timestamp (quiet).
c() { tick; git commit -q -m "$1"; }

# w FILE TEXT...: write a line of text to a file (overwrite).
w() { local f=$1; shift; printf '%s\n' "$*" > "$f"; }
# a FILE TEXT...: append a line.
a() { local f=$1; shift; printf '%s\n' "$*" >> "$f"; }

# note TEXT: a comment line in the output.
note() { printf '# %s\n' "$*"; }
