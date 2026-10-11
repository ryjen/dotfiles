#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
helper="$repo_root/files/home/.local/bin/dub-waybar-canonicalize"
reload="$repo_root/files/home/.local/bin/dub-waybar-reload"
session_start="$repo_root/files/home/.local/bin/dub-session-start"
session_reset="$repo_root/files/home/.local/bin/dub-session-reset"
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
	local bash_bin
	bash_bin="$(command -v bash)"
	mkdir -p "$tmp/mock-bin"

	printf '#!%s\n' "$bash_bin" >"$tmp/mock-bin/systemctl"
	cat >>"$tmp/mock-bin/systemctl" <<'EOF'
set -euo pipefail
{
  printf 'systemctl'
  printf ' <%s>' "$@"
  printf '\n'
} >>"$MOCK_LOG"

if [ "${1:-}" = "--user" ] && [ "${2:-}" = "list-units" ]; then
  # `--no-legend` suppresses the header, so only emit scope rows.
  [ -z "${MOCK_HYPRLAND_WAYBAR_SCOPE:-}" ] || printf '%s\n' "$MOCK_HYPRLAND_WAYBAR_SCOPE"
fi
exit 0
EOF

	printf '#!%s\n' "$bash_bin" >"$tmp/mock-bin/pkill"
	cat >>"$tmp/mock-bin/pkill" <<'EOF'
set -euo pipefail
{
  printf 'pkill'
  printf ' <%s>' "$@"
  printf '\n'
} >>"$MOCK_LOG"
exit 0
EOF

	chmod +x "$tmp/mock-bin"/*
}

reset_fixture() {
	: >"$tmp/log"
	export MOCK_LOG="$tmp/log"
	export PATH="$tmp/mock-bin:$ORIGINAL_PATH"
	unset MOCK_HYPRLAND_WAYBAR_SCOPE
}

ORIGINAL_PATH="$PATH"
write_mocks
[ -f "$helper" ] || fail "dub-waybar-canonicalize does not exist"

# A legacy session can leave both a Hyprland-scoped Waybar and a wrapper-named
# managed process. Canonicalization stops the managed unit, reaps both naming
# modes, stops the transient Hyprland scope, then starts one managed instance.
reset_fixture
export MOCK_HYPRLAND_WAYBAR_SCOPE="app-Hyprland-waybar-1b89c78d.scope"
bash "$helper"
assert_contains "$MOCK_LOG" 'systemctl <--user> <stop> <waybar.service>'
assert_contains "$MOCK_LOG" 'pkill <-x> <waybar>'
assert_contains "$MOCK_LOG" 'pkill <-x> <.waybar-wrapped>'
assert_contains "$MOCK_LOG" 'systemctl <--user> <stop> <app-Hyprland-waybar-1b89c78d.scope>'
assert_contains "$MOCK_LOG" 'systemctl <--user> <start> <waybar.service>'

# Old owners must be reaped before the managed unit is (re)started.
stop_line="$(grep -nF 'systemctl <--user> <stop> <waybar.service>' "$MOCK_LOG" | head -n1 | cut -d: -f1)"
start_line="$(grep -nF 'systemctl <--user> <start> <waybar.service>' "$MOCK_LOG" | head -n1 | cut -d: -f1)"
[ -n "$stop_line" ] && [ -n "$start_line" ] || fail "canonicalizer did not stop/start the managed unit"
[ "$stop_line" -lt "$start_line" ] || fail "managed unit started before old instances were reaped"

# Exactly one managed instance is started, regardless of leftover owners.
start_count="$(grep -cF 'systemctl <--user> <start> <waybar.service>' "$MOCK_LOG")"
[ "$start_count" -eq 1 ] || fail "expected exactly one managed start, saw $start_count"

# With no leftover scope, the helper still canonicalizes the unit.
reset_fixture
bash "$helper"
assert_contains "$MOCK_LOG" 'systemctl <--user> <start> <waybar.service>'
assert_contains "$MOCK_LOG" 'pkill <-x> <waybar>'

# The session surfaces delegate ownership to the canonicalizer and never spawn
# an unmanaged Waybar themselves.
assert_contains "$reload" 'dub-waybar-canonicalize'
assert_not_contains "$reload" 'exec waybar'
assert_contains "$session_start" 'dub-waybar-canonicalize'
assert_not_contains "$session_start" 'start_once waybar'
assert_contains "$session_reset" 'dub-session-start'
assert_not_contains "$session_reset" 'pkill -x waybar'

printf 'waybar single-owner tests passed\n'
