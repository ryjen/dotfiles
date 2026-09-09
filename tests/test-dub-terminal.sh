#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
helper="$repo_root/files/home/.local/bin/dub-terminal"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_contains() {
	grep -F -- "$2" "$1" >/dev/null || fail "expected $1 to contain: $2"
}

assert_not_contains() {
	if grep -F -- "$2" "$1" >/dev/null; then
		fail "expected $1 not to contain: $2"
	fi
}

write_mocks() {
	mkdir -p "$tmp/mock-bin"

	cat >"$tmp/mock-bin/kitty" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'kitty'
  printf ' <%s>' "$@"
  printf '\n'
} >>"$MOCK_TERMINAL_LOG"

if [ "${1:-}" = "--title" ]; then
  shift 2
fi

if [ "${1:-}" = "zellij" ]; then
  exec "$@"
fi

exit "${MOCK_TERMINAL_STATUS:-0}"
EOF

	cat >"$tmp/mock-bin/zellij" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log() {
  {
    printf 'zellij'
    printf ' <%s>' "$@"
    printf '\n'
  } >>"$MOCK_ZELLIJ_LOG"
}

case "${1:-}" in
list-sessions)
  [ ! -s "$MOCK_ZELLIJ_STATE" ] || cat "$MOCK_ZELLIJ_STATE"
  ;;
attach)
  if [ "${2:-}" = "--create-background" ]; then
    session="${3:-}"
    log "$@"
    [ "${4:-}" = options ] || exit 64
    [ "${5:-}" = --session-serialization ] || exit 64
    [ "${6:-}" = false ] || exit 64
    if grep -Fx -- "$session" "$MOCK_ZELLIJ_STATE" >/dev/null 2>&1; then
      exit 1
    fi
    [ -z "${MOCK_CREATE_DELAY:-}" ] || sleep "$MOCK_CREATE_DELAY"
    printf '%s\n' "$session" >>"$MOCK_ZELLIJ_STATE"
  else
    session="${2:-}"
    log "$@"
    if [ -n "${MOCK_HOLD_DIR:-}" ]; then
      mkdir -p "$MOCK_HOLD_DIR/ready"
      : >"$MOCK_HOLD_DIR/ready/$session"
      while [ -e "$MOCK_HOLD_DIR/hold-$session" ]; do
        sleep 0.02
      done
    fi
  fi
  ;;
kill-session)
  session="${2:-}"
  log "$@"
  grep -Fxv -- "$session" "$MOCK_ZELLIJ_STATE" >"$MOCK_ZELLIJ_STATE.tmp" || true
  mv "$MOCK_ZELLIJ_STATE.tmp" "$MOCK_ZELLIJ_STATE"
  ;;
*)
  log "$@"
  exit 64
  ;;
esac
EOF

	cat >"$tmp/mock-bin/kitten" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'kitten'
  printf ' <%s>' "$@"
  printf '\n'
} >>"$MOCK_REMOTE_LOG"
EOF

	cat >"$tmp/mock-bin/mosh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'mosh'
  printf ' <%s>' "$@"
  printf '\n'
} >>"$MOCK_REMOTE_LOG"
EOF

	chmod +x "$tmp/mock-bin"/*
}

reset_fixture() {
	rm -rf "$tmp/runtime" "$tmp/hold"
	mkdir -p "$tmp/runtime" "$tmp/hold"
	: >"$tmp/terminal.log"
	: >"$tmp/zellij.log"
	: >"$tmp/zellij.state"
	: >"$tmp/remote.log"
	export DUB_TERMINAL="$tmp/mock-bin/kitty"
	export DUB_TERMINAL_MANAGED_SESSIONS=1
	export XDG_RUNTIME_DIR="$tmp/runtime"
	export MOCK_TERMINAL_LOG="$tmp/terminal.log"
	export MOCK_ZELLIJ_LOG="$tmp/zellij.log"
	export MOCK_ZELLIJ_STATE="$tmp/zellij.state"
	export MOCK_REMOTE_LOG="$tmp/remote.log"
	export MOCK_HOLD_DIR="$tmp/hold"
	export PATH="$tmp/mock-bin:$ORIGINAL_PATH"
	unset MOCK_CREATE_DELAY MOCK_TERMINAL_STATUS WAYLAND_DISPLAY
}

wait_for_file() {
	local path="$1"
	local attempts=0
	while [ ! -e "$path" ]; do
		attempts=$((attempts + 1))
		[ "$attempts" -lt 200 ] || fail "timed out waiting for $path"
		sleep 0.01
	done
}

ORIGINAL_PATH="$PATH"
write_mocks
[ -x "$helper" ] || fail "dub-terminal does not exist or is not executable"

# Explicit Kitty arguments remain on the historical direct-launch path.
reset_fixture
bash "$helper" --title btop btop
assert_contains "$MOCK_TERMINAL_LOG" 'kitty <--title> <btop> <btop>'
[ ! -s "$MOCK_ZELLIJ_LOG" ] || fail "direct command unexpectedly touched Zellij"

# Hosts without managed-session ownership retain a plain bare terminal.
reset_fixture
export DUB_TERMINAL_MANAGED_SESSIONS=0
bash "$helper"
assert_contains "$MOCK_TERMINAL_LOG" 'kitty'
[ ! -s "$MOCK_ZELLIJ_LOG" ] || fail "unmanaged bare terminal unexpectedly touched Zellij"

# A managed bare terminal allocates the lowest free slot, disables resurrection,
# attaches locally, and kills the session when the owner terminal exits.
reset_fixture
printf '%s\n' term-01 >"$MOCK_ZELLIJ_STATE"
bash "$helper"
assert_contains "$MOCK_ZELLIJ_LOG" 'zellij <attach> <--create-background> <term-02> <options> <--session-serialization> <false>'
assert_contains "$MOCK_ZELLIJ_LOG" 'zellij <attach> <term-02>'
assert_contains "$MOCK_ZELLIJ_LOG" 'zellij <kill-session> <term-02>'
assert_contains "$MOCK_TERMINAL_LOG" '<--title>'
assert_contains "$MOCK_TERMINAL_LOG" '<term-02>'
grep -Fx term-01 "$MOCK_ZELLIJ_STATE" >/dev/null || fail "existing session was modified"
assert_not_contains "$MOCK_ZELLIJ_STATE" 'term-02'

# Owner cleanup also runs if the terminal process itself fails.
reset_fixture
export MOCK_TERMINAL_STATUS=7
if bash "$helper"; then
	fail "failing terminal unexpectedly succeeded"
else
	status=$?
fi
[ "$status" -eq 7 ] || fail "terminal failure status was not preserved"
assert_contains "$MOCK_ZELLIJ_LOG" 'zellij <kill-session> <term-01>'
assert_not_contains "$MOCK_ZELLIJ_STATE" 'term-01'

# Two live owners receive distinct slots; closing either owner reclaims only its
# own session. Holding the first attach keeps its ownership window alive.
reset_fixture
: >"$MOCK_HOLD_DIR/hold-term-01"
bash "$helper" &
first_pid=$!
wait_for_file "$MOCK_HOLD_DIR/ready/term-01"
: >"$MOCK_HOLD_DIR/hold-term-02"
bash "$helper" &
second_pid=$!
wait_for_file "$MOCK_HOLD_DIR/ready/term-02"
assert_contains "$MOCK_ZELLIJ_STATE" 'term-01'
assert_contains "$MOCK_ZELLIJ_STATE" 'term-02'
rm "$MOCK_HOLD_DIR/hold-term-02"
wait "$second_pid"
assert_contains "$MOCK_ZELLIJ_STATE" 'term-01'
assert_not_contains "$MOCK_ZELLIJ_STATE" 'term-02'
rm "$MOCK_HOLD_DIR/hold-term-01"
wait "$first_pid"
[ ! -s "$MOCK_ZELLIJ_STATE" ] || fail "owned sessions were not reclaimed"

# SSH/Mosh are attachment-only paths: they launch remote Zellij clients but do
# not create or kill a local/remote owner session themselves.
reset_fixture
bash "$helper" --host dubnium --session term-02
assert_contains "$MOCK_TERMINAL_LOG" '<kitten> <ssh> <-t> <dubnium>'
assert_contains "$MOCK_TERMINAL_LOG" "<zellij attach 'term-02'>"
[ ! -s "$MOCK_ZELLIJ_LOG" ] || fail "SSH attachment unexpectedly touched local Zellij ownership"

reset_fixture
bash "$helper" --host dubnium --session term-03 --transport mosh
assert_contains "$MOCK_TERMINAL_LOG" '<mosh> <dubnium> <--> <zellij> <attach> <term-03>'
[ ! -s "$MOCK_ZELLIJ_LOG" ] || fail "Mosh attachment unexpectedly touched local Zellij ownership"

# Wrapper-controlled values reject shell/option injection before transport.
reset_fixture
if bash "$helper" --host dubnium --session 'term-01;touch-pwned'; then
	fail "unsafe session name unexpectedly accepted"
fi
[ ! -s "$MOCK_TERMINAL_LOG" ] || fail "invalid session reached terminal launcher"

reset_fixture
if bash "$helper" --host '--proxy-command=bad' --session term-01; then
	fail "unsafe host unexpectedly accepted"
fi
[ ! -s "$MOCK_TERMINAL_LOG" ] || fail "invalid host reached terminal launcher"

printf 'dub-terminal tests passed\n'
