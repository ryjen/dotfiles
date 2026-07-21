#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
helper="$repo_root/files/home/.local/libexec/dubnium-meeting-mode"
eww_overlay="$repo_root/files/home/.local/libexec/dubnium-eww-quote-overlay"
clipboard="$repo_root/files/home/.local/bin/dub-clipboard"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_file() {
	[ -e "$1" ] || fail "expected $1 to exist"
}

assert_no_file() {
	[ ! -e "$1" ] || fail "expected $1 not to exist"
}

assert_contains() {
	grep -F -- "$2" "$1" >/dev/null || fail "expected $1 to contain: $2"
}

assert_not_contains() {
	if grep -F -- "$2" "$1" >/dev/null; then
		fail "expected $1 not to contain: $2"
	fi
}

make_core_path() {
	local command_name
	mkdir -p "$tmp/core-bin"
	for command_name in bash cat chmod dirname flock grep mkdir mktemp mv python3 rm sleep stat; do
		ln -sf "$(command -v "$command_name")" "$tmp/core-bin/$command_name"
	done
}

write_mocks() {
	mkdir -p "$tmp/mock-bin"
	cat >"$tmp/mock-bin/systemctl" <<'EOF'
#!/bin/sh
set -u
{
  printf 'systemctl'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
if [ "$#" -eq 4 ] && [ "$1" = --user ] && [ "$2" = is-active ] && [ "$3" = --quiet ] && [ "$4" = dubnium-cliphist.service ]; then
    [ -e "$MOCK_MARKER" ] || exit 97
    [ -z "${CLIPHIST_QUERY_STATUS:-}" ] || exit "$CLIPHIST_QUERY_STATUS"
    [ "$(cat "$MOCK_CLIPHIST")" = active ] && exit 0
    exit 3
elif [ "$#" -eq 3 ] && [ "$1" = --user ] && [ "$2" = stop ] && [ "$3" = dubnium-cliphist.service ]; then
    grep -Fx 'cliphist_was_active=true' "$MOCK_STATE" >/dev/null || exit 97
    grep -Fx 'cliphist_stopped=true' "$MOCK_STATE" >/dev/null || exit 97
    [ "${FAIL_CLIPHIST_STOP:-0}" != 1 ] || exit 1
    printf inactive >"$MOCK_CLIPHIST"
elif [ "$#" -eq 3 ] && [ "$1" = --user ] && [ "$2" = start ] && [ "$3" = dubnium-cliphist.service ]; then
    grep -Fx 'phase=stopping' "$MOCK_STATE" >/dev/null || exit 97
    grep -Fx 'cliphist_stopped=true' "$MOCK_STATE" >/dev/null || exit 97
    [ "${FAIL_CLIPHIST_START:-0}" != 1 ] || exit 1
    printf active >"$MOCK_CLIPHIST"
else
  exit 64
fi
EOF
	cat >"$tmp/mock-bin/makoctl" <<'EOF'
#!/bin/sh
set -u
{
  printf 'makoctl'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
if [ "$#" -eq 1 ] && [ "$1" = mode ]; then
    cat "$MOCK_MAKO"
elif [ "$#" -eq 3 ] && [ "$1" = mode ] && [ "$2" = -a ] && [ "$3" = dubnium-meeting ]; then
    grep -Fx 'mako_added=true' "$MOCK_STATE" >/dev/null || exit 97
    [ "${FAIL_MAKO_ADD:-0}" != 1 ] || exit 1
    printf '%s\n' dubnium-meeting >>"$MOCK_MAKO"
elif [ "$#" -eq 3 ] && [ "$1" = mode ] && [ "$2" = -r ] && [ "$3" = dubnium-meeting ]; then
    grep -Fx 'phase=stopping' "$MOCK_STATE" >/dev/null || exit 97
    grep -Fx 'mako_added=true' "$MOCK_STATE" >/dev/null || exit 97
    [ "${FAIL_MAKO_REMOVE:-0}" != 1 ] || exit 1
    grep -Fxv dubnium-meeting "$MOCK_MAKO" >"$MOCK_MAKO.tmp" || true
    mv "$MOCK_MAKO.tmp" "$MOCK_MAKO"
else
  exit 64
fi
EOF
	cat >"$tmp/mock-bin/hyprctl" <<'EOF'
#!/bin/sh
{
  printf 'hyprctl'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
[ "$#" -eq 2 ] && [ "$1" = monitors ] && [ "$2" = -j ] || exit 64
[ "${FAIL_HYPRCTL:-0}" -eq 0 ] || exit "$FAIL_HYPRCTL"
printf '%s\n' "${MOCK_MONITORS:-[]}"
EOF
	cat >"$tmp/mock-bin/eww" <<'EOF'
#!/bin/sh
{
  printf 'eww'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
case "${1:-}" in
  ping)
    [ "$#" -eq 1 ] || exit 64
    count=0
    [ ! -e "$EWW_PING_COUNT" ] || count="$(cat "$EWW_PING_COUNT")"
    count=$((count + 1))
    printf '%s' "$count" >"$EWW_PING_COUNT"
    [ "$count" -ge "${EWW_READY_AFTER:-1}" ]
    ;;
  close)
    [ "$#" -eq 2 ] && [ "$2" = quote_overlay ] || exit 64
    ;;
  open)
    [ "$#" -eq 4 ] && [ "$2" = quote_overlay ] && [ "$3" = --screen ] || exit 64
    ;;
  *) exit 64 ;;
esac
EOF
	cat >"$tmp/mock-bin/pkill" <<'EOF'
#!/bin/sh
{
  printf 'pkill'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
[ "$#" -eq 2 ] && [ "$1" = -RTMIN+8 ] && [ "$2" = waybar ] || exit 64
exit "${FAIL_PKILL:-0}"
EOF
	cat >"$tmp/mock-bin/cliphist" <<'EOF'
#!/bin/sh
{
  printf 'cliphist'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
if [ "$#" -eq 1 ] && [ "$1" = list ]; then
  printf 'secret clipboard row\n'
elif [ "$#" -eq 1 ] && [ "$1" = decode ]; then
  cat
else
  exit 64
fi
EOF
	cat >"$tmp/mock-bin/wl-copy" <<'EOF'
#!/bin/sh
{
  printf 'wl-copy'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
[ "$#" -eq 0 ] || exit 64
EOF
	cat >"$tmp/mock-bin/wofi" <<'EOF'
#!/bin/sh
{
  printf 'wofi'
  printf ' %s' "$@"
  printf '\n'
} >>"$MOCK_LOG"
[ "$#" -eq 3 ] && [ "$1" = --dmenu ] && [ "$2" = --prompt ] && [ "$3" = clipboard ] || exit 64
cat
EOF
	local forbidden
	for forbidden in arecord ffmpeg grim obs obs-cli obs-studio pactl pw-cli pw-record slurp v4l2-ctl wf-recorder wl-paste wlr-randr xrandr; do
		cat >"$tmp/mock-bin/$forbidden" <<EOF
#!/bin/sh
{
  printf 'FORBIDDEN $forbidden'
  printf ' %s' "\$@"
  printf '\\n'
} >>"\$MOCK_LOG"
exit 99
EOF
	done
	chmod +x "$tmp/mock-bin"/*
	ln -sf "$(command -v jq)" "$tmp/mock-bin/jq"
}

reset_fixture() {
	if [ -e "$tmp/commands.log" ]; then
		assert_not_contains "$tmp/commands.log" "FORBIDDEN"
	fi
	rm -rf "${tmp:?}/home" "$tmp/state"
	mkdir -p "$tmp/home" "$tmp/state"
	: >"$tmp/commands.log"
	: >"$tmp/mako-modes"
	printf active >"$tmp/cliphist-state"
	export HOME="$tmp/home"
	export XDG_STATE_HOME="$tmp/state"
	export MOCK_LOG="$tmp/commands.log"
	export MOCK_MAKO="$tmp/mako-modes"
	export MOCK_CLIPHIST="$tmp/cliphist-state"
	export MOCK_MARKER="$tmp/state/dubnium/meeting/active"
	export MOCK_STATE="$tmp/state/dubnium/meeting/state"
	export EWW_PING_COUNT="$tmp/eww-ping-count"
	export PATH="$tmp/mock-bin:$tmp/core-bin"
	rm -f "$EWW_PING_COUNT"
	unset CLIPHIST_QUERY_STATUS DUBNIUM_PRESENTATION_OUTPUT FAIL_CLIPHIST_START FAIL_CLIPHIST_STOP
	unset EWW_READY_AFTER FAIL_HYPRCTL FAIL_MAKO_ADD FAIL_MAKO_REMOVE FAIL_PKILL MOCK_MONITORS
}

run_helper() {
	bash "$helper" "$@"
}

state_dir() {
	printf '%s/dubnium/meeting' "$XDG_STATE_HOME"
}

seed_state() {
	mkdir -p "$(state_dir)"
	printf '%s\n' "$1" >"$(state_dir)/state"
	: >"$(state_dir)/active"
}

seed_state_raw() {
	mkdir -p "$(state_dir)"
	printf '%s' "$1" >"$(state_dir)/state"
	: >"$(state_dir)/active"
}

valid_state() {
	local state_phase="$1"
	local state_mako_added="$2"
	local state_cliphist_was_active="$3"
	local state_cliphist_stopped="$4"
	local state_cliphist_query_status="${5:-unknown}"
	printf 'version=1\nphase=%s\nmako_was_active=false\nmako_added=%s\ncliphist_was_active=%s\ncliphist_stopped=%s\ncliphist_query_status=%s\n' \
		"$state_phase" "$state_mako_added" "$state_cliphist_was_active" "$state_cliphist_stopped" "$state_cliphist_query_status"
}

make_core_path
write_mocks
[ -x "$helper" ] || fail "meeting helper does not exist or is not executable"
[ -x "$eww_overlay" ] || fail "Eww overlay helper does not exist or is not executable"

# Mock dispatch preserves argv boundaries and rejects flattened lookalikes.
reset_fixture
mkdir -p "$(state_dir)"
: >"$(state_dir)/active"
if systemctl "--user is-active" --quiet dubnium-cliphist.service; then
	fail "systemctl mock accepted a malformed argv boundary"
fi
assert_contains "$MOCK_LOG" 'systemctl --user is-active --quiet dubnium-cliphist.service'

# Normal ownership is reversible and repeated operations are no-ops.
reset_fixture
run_helper start
assert_file "$(state_dir)/active"
[ "$(stat -c %a "$(state_dir)")" = 700 ] || fail "meeting state directory is not private"
[ "$(stat -c %a "$(state_dir)/active")" = 600 ] || fail "active marker is not private"
[ "$(stat -c %a "$(state_dir)/state")" = 600 ] || fail "ownership state is not private"
if compgen -G "$(state_dir)/.state.*" >/dev/null || compgen -G "$(state_dir)/.active.*" >/dev/null; then
	fail "atomic state write left a same-directory temporary file"
fi
assert_not_contains "$MOCK_LOG" "hyprctl"
assert_contains "$MOCK_LOG" "makoctl mode -a dubnium-meeting"
assert_contains "$MOCK_LOG" "systemctl --user stop dubnium-cliphist.service"
first_log="$(cat "$MOCK_LOG")"
run_helper start
[ "$first_log" = "$(cat "$MOCK_LOG")" ] || fail "repeated start had side effects"
run_helper stop
assert_no_file "$(state_dir)/active"
assert_no_file "$(state_dir)/state"
[ "$(cat "$MOCK_CLIPHIST")" = active ] || fail "cliphist was not restored"
assert_contains "$MOCK_LOG" "makoctl mode -r dubnium-meeting"
first_log="$(cat "$MOCK_LOG")"
run_helper stop
[ "$first_log" = "$(cat "$MOCK_LOG")" ] || fail "repeated stop had side effects"

# Existing ownership and inactive cliphist are never claimed.
reset_fixture
printf '%s\n' default dubnium-meeting >"$MOCK_MAKO"
printf inactive >"$MOCK_CLIPHIST"
run_helper start
run_helper stop
assert_not_contains "$MOCK_LOG" "makoctl mode -a dubnium-meeting"
assert_not_contains "$MOCK_LOG" "makoctl mode -r dubnium-meeting"
assert_not_contains "$MOCK_LOG" "systemctl --user stop dubnium-cliphist.service"
assert_not_contains "$MOCK_LOG" "systemctl --user start dubnium-cliphist.service"

# Start failure remains fail-closed and recovery restores persisted intent.
reset_fixture
export FAIL_CLIPHIST_STOP=1
if run_helper start; then
	fail "partial start unexpectedly succeeded"
fi
assert_file "$(state_dir)/active"
assert_contains "$(state_dir)/state" "phase=recovery-needed"
unset FAIL_CLIPHIST_STOP
run_helper recover
assert_no_file "$(state_dir)/active"
assert_no_file "$(state_dir)/state"
assert_contains "$MOCK_LOG" "systemctl --user start dubnium-cliphist.service"

# A failed Mako mutation is journaled before execution and can be compensated.
reset_fixture
export FAIL_MAKO_ADD=1
if run_helper start; then
	fail "failed Mako add unexpectedly succeeded"
fi
assert_file "$(state_dir)/active"
assert_contains "$(state_dir)/state" "mako_added=true"
unset FAIL_MAKO_ADD
run_helper recover
assert_no_file "$(state_dir)/active"

# Failed stop preserves ownership until a later recovery succeeds.
reset_fixture
run_helper start
export FAIL_MAKO_REMOVE=1
if run_helper stop; then
	fail "partial stop unexpectedly succeeded"
fi
assert_file "$(state_dir)/active"
assert_contains "$(state_dir)/state" "phase=recovery-needed"
unset FAIL_MAKO_REMOVE
run_helper recover
assert_no_file "$(state_dir)/active"

# A failed cliphist restart retains only the ownership still needing restoration.
reset_fixture
run_helper start
export FAIL_CLIPHIST_START=1
if run_helper stop; then
	fail "failed cliphist restoration unexpectedly succeeded"
fi
assert_file "$(state_dir)/active"
assert_contains "$(state_dir)/state" "mako_added=false"
assert_contains "$(state_dir)/state" "cliphist_stopped=true"
unset FAIL_CLIPHIST_START
run_helper recover
assert_no_file "$(state_dir)/active"

# Waybar refresh is explicitly nonfatal.
reset_fixture
export FAIL_PKILL=1
run_helper start
run_helper stop
assert_no_file "$(state_dir)/active"

# Missing optional notification control degrades without inventing ownership.
reset_fixture
mv "$tmp/mock-bin/makoctl" "$tmp/mock-bin/makoctl.disabled"
run_helper start
assert_file "$(state_dir)/active"
run_helper status --json >"$tmp/status.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["active"] and d["degraded"]' "$tmp/status.json"
run_helper waybar private >"$tmp/degraded-private.json"
python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["text"]' "$tmp/degraded-private.json"
run_helper stop
assert_no_file "$(state_dir)/active"
mv "$tmp/mock-bin/makoctl.disabled" "$tmp/mock-bin/makoctl"

# Missing systemctl cannot resolve an unknown capture query.
reset_fixture
PATH="$tmp/core-bin" run_helper start 2>/dev/null || true
assert_file "$(state_dir)/active"
assert_contains "$(state_dir)/state" "phase=recovery-needed"
assert_contains "$(state_dir)/state" "cliphist_query_status=unknown"
if PATH="$tmp/core-bin" run_helper recover 2>/dev/null; then
	fail "recovery cleared uncertain capture state without systemctl"
fi
assert_file "$(state_dir)/active"
run_helper recover
assert_no_file "$(state_dir)/active"

# An absent optional unit is known-safe but degraded.
reset_fixture
printf '%s\n' dubnium-meeting >"$MOCK_MAKO"
export CLIPHIST_QUERY_STATUS=4
run_helper start
assert_contains "$(state_dir)/state" "cliphist_query_status=4"
run_helper status --json >"$tmp/query-failed.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["active"] and d["degraded"]' "$tmp/query-failed.json"
PATH="$tmp/core-bin" run_helper stop
assert_no_file "$(state_dir)/active"
assert_not_contains "$MOCK_LOG" "systemctl --user start dubnium-cliphist.service"

# Unknown capture state fails start and remains fail-closed until it can be revalidated.
reset_fixture
export CLIPHIST_QUERY_STATUS=1
if run_helper start; then
	fail "capture-state query error unexpectedly allowed start"
fi
assert_file "$(state_dir)/active"
assert_contains "$(state_dir)/state" "phase=recovery-needed"
assert_contains "$(state_dir)/state" "cliphist_query_status=unknown"
run_helper status --json >"$tmp/query-error.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert not d["active"] and d["degraded"] and d["phase"] == "recovery-needed"' "$tmp/query-error.json"
if run_helper recover 2>/dev/null; then
	fail "recovery cleared unknown capture state"
fi
assert_file "$(state_dir)/active"
unset CLIPHIST_QUERY_STATUS
run_helper recover
assert_no_file "$(state_dir)/active"

# A later query error cannot present an active lifecycle as trustworthy.
reset_fixture
run_helper start
export CLIPHIST_QUERY_STATUS=1
run_helper status --json >"$tmp/active-query-error.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert not d["active"] and d["degraded"] and d["phase"] == "recovery-needed"' "$tmp/active-query-error.json"
assert_contains "$(state_dir)/state" "phase=recovery-needed"
unset CLIPHIST_QUERY_STATUS
run_helper stop

# A later query error replaces an earlier inactive result with explicit uncertainty.
reset_fixture
printf inactive >"$MOCK_CLIPHIST"
run_helper start
export CLIPHIST_QUERY_STATUS=1
run_helper status --json >"$tmp/inactive-query-error.json"
assert_contains "$(state_dir)/state" "cliphist_query_status=unknown"
unset CLIPHIST_QUERY_STATUS
mv "$tmp/mock-bin/systemctl" "$tmp/mock-bin/systemctl.disabled"
if run_helper recover 2>/dev/null; then
	fail "recovery cleared later query uncertainty without systemctl"
fi
assert_file "$(state_dir)/active"
mv "$tmp/mock-bin/systemctl.disabled" "$tmp/mock-bin/systemctl"
run_helper recover
assert_no_file "$(state_dir)/active"

# Persisted pre-side-effect intent compensates both crash windows.
reset_fixture
seed_state "$(valid_state starting true false false)"
run_helper recover
assert_contains "$MOCK_LOG" "makoctl mode -r dubnium-meeting"
assert_no_file "$(state_dir)/state"

reset_fixture
seed_state "$(valid_state starting false true true 0)"
run_helper recover
assert_contains "$MOCK_LOG" "systemctl --user start dubnium-cliphist.service"
assert_no_file "$(state_dir)/state"

# Malformed ownership journals never discard evidence or execute restoration.
valid_journal="$(valid_state recovery-needed false false false)"
for malformed_journal in \
	"${valid_journal/version=1/version=2}" \
	"${valid_journal/phase=recovery-needed/phase=unknown}" \
	"${valid_journal/mako_added=false/mako_added=maybe}" \
	"${valid_journal/mako_was_active=false/}" \
	"${valid_journal}"$'\nunknown=false' \
	"${valid_journal}"$'\nphase=recovery-needed'; do
	reset_fixture
	seed_state "$malformed_journal"
	if run_helper recover 2>/dev/null; then
		fail "malformed journal unexpectedly recovered"
	fi
	assert_file "$(state_dir)/active"
	assert_file "$(state_dir)/state"
	assert_not_contains "$MOCK_LOG" "makoctl mode -r"
	assert_not_contains "$MOCK_LOG" "systemctl --user start"
done

# Unknown and duplicate trailing fields are rejected even without a final newline.
reset_fixture
seed_state_raw "${valid_journal}"$'\nunknown=false'
if run_helper recover 2>/dev/null; then
	fail "non-newline unknown field was ignored"
fi
assert_file "$(state_dir)/state"

reset_fixture
seed_state_raw "${valid_journal}"$'\nphase=recovery-needed'
if run_helper recover 2>/dev/null; then
	fail "non-newline duplicate field was ignored"
fi
assert_file "$(state_dir)/state"

reset_fixture
seed_state_raw "${valid_journal}"$'\n='
if run_helper recover 2>/dev/null; then
	fail "malformed final field boundary was ignored"
fi
assert_file "$(state_dir)/state"

# Owned cliphist restoration cannot proceed without systemctl.
reset_fixture
run_helper start
mv "$tmp/mock-bin/systemctl" "$tmp/mock-bin/systemctl.disabled"
if run_helper stop 2>/dev/null; then
	fail "owned cliphist restoration succeeded without systemctl"
fi
assert_file "$(state_dir)/active"
assert_contains "$(state_dir)/state" "phase=recovery-needed"
mv "$tmp/mock-bin/systemctl.disabled" "$tmp/mock-bin/systemctl"
run_helper recover
assert_no_file "$(state_dir)/active"

# Configured output is validated exactly and no replacement is selected.
reset_fixture
export DUBNIUM_PRESENTATION_OUTPUT=DP-1
export MOCK_MONITORS='[{"id":0,"name":"eDP-1","workspace":{"id":1,"name":"DP-1"}},{"id":1,"name":"DP-2","workspace":{"name":"presentation"}}]'
run_helper status --json >"$tmp/nested-output-only.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["degraded"] and "not connected" in d["reason"]' "$tmp/nested-output-only.json"
export MOCK_MONITORS='[{"id":0,"name":"eDP-1","workspace":{"name":"1"}},{"id":1,"name":"DP-1","workspace":{"name":"presentation"}}]'
run_helper status --json >"$tmp/output-present.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert not d["degraded"]' "$tmp/output-present.json"
export MOCK_MONITORS='[{"id":0,"name":"eDP-1","workspace":{"name":"DP-1"}}]'
run_helper status --json >"$tmp/output-missing.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["degraded"] and "DP-1" in d["reason"] and "eDP-1" not in d["reason"]' "$tmp/output-missing.json"
export MOCK_MONITORS='{malformed'
run_helper status --json >"$tmp/output-malformed.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["degraded"] and "validation unavailable" in d["reason"]' "$tmp/output-malformed.json"

# Missing jq degrades without invoking an alternate parser or selecting an output.
PATH="$tmp/core-bin:$tmp/mock-bin"
rm -f "$tmp/core-bin/jq"
mv "$tmp/mock-bin/jq" "$tmp/mock-bin/jq.disabled"
: >"$MOCK_LOG"
run_helper status --json >"$tmp/output-no-jq.json"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["degraded"] and "validation unavailable" in d["reason"]' "$tmp/output-no-jq.json"
assert_not_contains "$MOCK_LOG" "hyprctl"
mv "$tmp/mock-bin/jq.disabled" "$tmp/mock-bin/jq"
export PATH="$tmp/mock-bin:$tmp/core-bin"

# Eww opens only on an exactly discovered non-presentation monitor.
reset_fixture
export DUBNIUM_PRESENTATION_OUTPUT=DP-1
export MOCK_MONITORS='[{"id":0,"name":"DP-1","description":"Projector","focused":false,"workspace":{"id":10,"name":"presentation"}},{"id":1,"name":"eDP-1","description":"Built-in display","focused":true,"workspace":{"id":1,"name":"1"}}]'
bash "$eww_overlay"
assert_contains "$MOCK_LOG" "hyprctl monitors -j"
assert_contains "$MOCK_LOG" "eww close quote_overlay"
assert_contains "$MOCK_LOG" "eww open quote_overlay --screen eDP-1"

# Eww readiness is bounded and tolerates a delayed daemon startup.
reset_fixture
export DUBNIUM_PRESENTATION_OUTPUT=DP-1
export EWW_READY_AFTER=3
export MOCK_MONITORS='[{"id":0,"name":"DP-1"},{"id":1,"name":"eDP-1"}]'
bash "$eww_overlay"
[ "$(grep -c '^eww ping$' "$MOCK_LOG")" -eq 3 ] || fail "Eww readiness did not stop after becoming ready"
assert_contains "$MOCK_LOG" "eww close quote_overlay"
assert_contains "$MOCK_LOG" "eww open quote_overlay --screen eDP-1"

# A daemon that never becomes ready fails closed after a bounded poll.
reset_fixture
export EWW_READY_AFTER=99
bash "$eww_overlay"
[ "$(grep -c '^eww ping$' "$MOCK_LOG")" -eq 10 ] || fail "Eww readiness poll was not bounded at 10 attempts"
assert_not_contains "$MOCK_LOG" "eww close"
assert_not_contains "$MOCK_LOG" "eww open"

# No private monitor and all discovery failures close without opening.
for monitor_failure in \
	'[{"id":0,"name":"DP-1","description":"Projector","focused":true,"workspace":{"id":10,"name":"presentation"}}]' \
	'{malformed' \
	'[{"id":0,"description":"missing monitor name"}]'; do
	reset_fixture
	export DUBNIUM_PRESENTATION_OUTPUT=DP-1
	export MOCK_MONITORS="$monitor_failure"
	bash "$eww_overlay"
	assert_contains "$MOCK_LOG" "eww close quote_overlay"
	assert_not_contains "$MOCK_LOG" "eww open"
done

reset_fixture
export DUBNIUM_PRESENTATION_OUTPUT=DP-1
export FAIL_HYPRCTL=1
bash "$eww_overlay"
assert_contains "$MOCK_LOG" "eww close quote_overlay"
assert_not_contains "$MOCK_LOG" "eww open"

# Without a configured presentation output, preserve the legacy screen zero.
reset_fixture
bash "$eww_overlay"
assert_not_contains "$MOCK_LOG" "hyprctl"
assert_contains "$MOCK_LOG" "eww open quote_overlay --screen 0"

# Waybar always emits one parseable object and never emits state or monitor data.
unset DUBNIUM_PRESENTATION_OUTPUT
run_helper waybar private >"$tmp/private.json"
run_helper waybar presentation >"$tmp/presentation.json"
python3 - "$tmp/private.json" "$tmp/presentation.json" <<'PY'
import json
import sys

private = json.load(open(sys.argv[1]))
presentation = json.load(open(sys.argv[2]))
assert private["text"] == ""
assert presentation == {"text": "Presentation", "class": "presentation"}
assert "tooltip" not in presentation
PY
assert_not_contains "$tmp/presentation.json" "DP-1"
assert_not_contains "$tmp/presentation.json" "eDP-1"

# The marker blocks the clipboard UI before dependencies or cliphist list.
reset_fixture
mkdir -p "$(state_dir)"
: >"$(state_dir)/active"
set +e
bash "$clipboard" 2>/dev/null
clipboard_status=$?
set -e
[ "$clipboard_status" -eq 75 ] || fail "clipboard marker returned $clipboard_status, expected 75"
assert_not_contains "$MOCK_LOG" "cliphist list"
assert_not_contains "$MOCK_LOG" "wofi"

# Any ownership journal also blocks capture if marker creation was interrupted.
rm -f "$(state_dir)/active"
: >"$(state_dir)/state"
set +e
run_helper can-capture
capture_status=$?
set -e
[ "$capture_status" -ne 0 ] || fail "capture allowed with incomplete ownership state"

# Doctor reports a helper status command failure instead of presenting empty status as healthy.
reset_fixture
mkdir -p "$HOME/.local/libexec"
cat >"$HOME/.local/libexec/dubnium-meeting-mode" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$HOME/.local/libexec/dubnium-meeting-mode"
bash "$repo_root/files/home/.local/bin/dub-session-doctor" >"$tmp/doctor.out" 2>&1 || true
assert_contains "$tmp/doctor.out" "[warn] meeting privacy status unavailable"

# Static service and startup ownership contracts.
meeting_nix="$repo_root/modules/home/meeting.nix"
assert_contains "$meeting_nix" 'home.file.".local/libexec/dubnium-meeting-mode"'
assert_contains "$meeting_nix" 'systemd.user.services.dubnium-meeting-mode'
assert_contains "$meeting_nix" 'RemainAfterExit = true;'
assert_contains "$meeting_nix" 'ExecCondition = "%h/.local/libexec/dubnium-meeting-mode can-capture";'
assert_contains "$meeting_nix" 'WantedBy = [ "graphical-session.target" ];'
assert_not_contains "$repo_root/files/home/.local/bin/dub-session-start" "wl-paste --watch cliphist store"
assert_contains "$repo_root/files/home/.local/bin/dub-session-start" "start_once eww eww daemon"
assert_contains "$repo_root/files/home/.config/hypr/adopted.d/technetium.conf" "exec-once = eww daemon"
assert_not_contains "$eww_overlay" "eww daemon"
assert_contains "$repo_root/files/home/.config/mako/config" '[mode=dubnium-meeting]'
assert_contains "$repo_root/files/home/.config/mako/config" 'invisible=1'

assert_not_contains "$MOCK_LOG" "FORBIDDEN"
printf 'meeting mode lifecycle tests: PASS\n'
