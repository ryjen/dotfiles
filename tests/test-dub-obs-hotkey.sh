#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
helper="$root/files/home/.local/bin/dub-obs-hotkey"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/hyprctl" <<'MOCKEOF'
#!/bin/sh
case "$*" in
  "clients -j")
    printf '%s\n' "${CLIENTS_JSON:?}"
    exit 0
    ;;
esac
printf 'hyprctl %s\n' "$*" >> "${HYPRCTL_LOG:?}"
if [ "${DISPATCH_FAIL:-0}" = 1 ]; then
  exit 1
fi
MOCKEOF
chmod +x "$tmp/hyprctl"

export PATH="$tmp:$PATH"
export HYPRCTL_LOG="$tmp/hyprctl.log"

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

run_helper() {
	local action=$1
	: >"$HYPRCTL_LOG"
	bash "$helper" "$action" >"$tmp/stdout" 2>"$tmp/stderr"
}

assert_no_dispatch() {
	[[ ! -s $HYPRCTL_LOG ]] || fail "unexpected dispatch: $(<"$HYPRCTL_LOG")"
}

assert_dispatch() {
	local expected=$1
	local actual
	actual=$(<"$HYPRCTL_LOG")
	[[ $actual == "$expected" ]] || fail "expected '$expected', got '$actual'"
}

CLIENTS_JSON='[]'
export CLIENTS_JSON
run_helper code-only || fail "no clients must be a no-op"
assert_no_dispatch

CLIENTS_JSON='[{"address":"0xCONTROL","class":"com.obsproject.Studio","title":"OBS Studio"}]'
run_helper code-only || fail "one control window must dispatch"
assert_dispatch 'hyprctl dispatch sendshortcut CTRL ALT,1,address:0xCONTROL'

CLIENTS_JSON='[
  {"address":"0xCONTROL","class":"com.obsproject.Studio","title":"OBS Studio"},
  {"address":"0xPROJECTOR","class":"com.obsproject.Studio","title":"Fullscreen Projector (Code Only)"}
]'
run_helper code-camera || fail "a projector must not make the control target ambiguous"
assert_dispatch 'hyprctl dispatch sendshortcut CTRL ALT,2,address:0xCONTROL'

CLIENTS_JSON='[{"address":"0xPROJECTOR","class":"com.obsproject.Studio","title":"Windowed Projector (Code Only)"}]'
run_helper camera-toggle || fail "projector-only clients must be a no-op"
assert_no_dispatch

CLIENTS_JSON='[
  {"address":"0xONE","class":"com.obsproject.Studio","title":"OBS Studio"},
  {"address":"0xTWO","class":"com.obsproject.Studio","title":"OBS Studio - Profile"}
]'
if run_helper code-only; then
	fail "two control windows must be rejected"
fi
assert_no_dispatch

CLIENTS_JSON='{malformed'
if run_helper code-only; then
	fail "malformed client JSON must be rejected"
fi
assert_no_dispatch

CLIENTS_JSON='[{"address":"0xCONTROL","class":"com.obsproject.Studio","title":"OBS Studio"}]'
DISPATCH_FAIL=1
export DISPATCH_FAIL
if run_helper camera-toggle; then
	fail "dispatch failure must be returned"
fi
assert_dispatch 'hyprctl dispatch sendshortcut CTRL ALT,3,address:0xCONTROL'
unset DISPATCH_FAIL

if run_helper unsupported; then
	fail "unsupported actions must be rejected"
fi
assert_no_dispatch

: >"$HYPRCTL_LOG"
if bash "$helper" code-only extra >"$tmp/stdout" 2>"$tmp/stderr"; then
	fail "extra arguments must be rejected"
fi
assert_no_dispatch

printf 'dub-obs-hotkey relay tests passed\n'
