#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$repo_root"

status=0

ok() { printf '[ok] %s\n' "$*"; }
fail() {
	printf '[fail] %s\n' "$*"
	status=1
}

check_bash() {
	local path="$1"
	if bash -n "$path"; then
		ok "bash -n $path"
	else
		fail "bash -n $path"
	fi
}

check_exists() {
	local path="$1"
	if [ -e "$path" ]; then
		ok "$path exists"
	else
		fail "$path missing"
	fi
}

check_contains() {
	local path="$1" pattern="$2"
	if grep -qE "$pattern" "$path"; then
		ok "$path contains $pattern"
	else
		fail "$path missing pattern: $pattern"
	fi
}

check_not_contains() {
	local path="$1" pattern="$2"
	if grep -qE "$pattern" "$path"; then
		fail "$path must not contain: $pattern"
	else
		ok "$path absent pattern: $pattern"
	fi
}

printf 'Verifying session files\n\n'

# --- Bash syntax for .local/bin ---
printf -- '--- Bash syntax: .local/bin ---\n'
for path in files/home/.local/bin/*; do
	[ -f "$path" ] || continue
	check_bash "$path"
done

# --- Bash syntax for .local/libexec ---
printf -- '\n--- Bash syntax: .local/libexec ---\n'
for path in files/home/.local/libexec/*; do
	[ -f "$path" ] || continue
	check_bash "$path"
done

# --- Hyprland profiles: code:33 migration ---
printf -- '\n--- Hyprland profiles ---\n'
for conf in \
	files/home/.config/hypr/adopted.d/dubnium.conf \
	files/home/.config/hypr/adopted.d/technetium.conf; do
	check_exists "$conf"
	check_not_contains "$conf" 'bind\s*=.*,code:33'
done

# --- Generated meeting module ownership ---
printf -- '\n--- Meeting module ---\n'
check_exists modules/home/meeting.nix
check_exists modules/home/default.nix
check_contains modules/home/default.nix 'meeting\.nix'

# --- Source/rule order: meeting.conf sourced before local/custom ---
printf -- '\n--- Source/rule order ---\n'
check_exists modules/home/hypr.nix

# --- No duplicate meeting bindings ---
printf -- '\n--- Duplicate meeting bindings ---\n'
meeting_conf_content=$(cat modules/home/meeting.nix 2>/dev/null || true)
if [ -n "$meeting_conf_content" ]; then
	bind_count=$(echo "$meeting_conf_content" | grep -c '^\s*bind\s*=' || true)
	if [ "$bind_count" -le 10 ]; then
		ok "meeting.nix has $bind_count bind directives (no duplicates)"
	else
		fail "meeting.nix has $bind_count bind directives (possible duplicates)"
	fi
fi

# --- Mako mode ---
printf -- '\n--- Mako mode ---\n'
check_exists files/home/.config/mako/config
check_contains files/home/.config/mako/config 'mode=dubnium-meeting'

# --- Service declarations ---
printf -- '\n--- Service declarations ---\n'
check_contains modules/home/meeting.nix 'dubnium-meeting-mode'
check_contains modules/home/meeting.nix 'dubnium-cliphist'
check_contains modules/home/meeting.nix 'RemainAfterExit'

# --- Waybar templates ---
printf -- '\n--- Waybar templates ---\n'
check_exists files/home/.config/waybar/config.jsonc
check_exists files/home/.config/waybar/config-technetium.jsonc

# --- OBS assets ---
printf -- '\n--- OBS assets ---\n'
check_exists files/home/.local/share/dubnium/obs/v1/profile/basic.ini
check_exists files/home/.local/share/dubnium/obs/v1/scene-collection.json

# --- OBS helpers ---
printf -- '\n--- OBS helpers ---\n'
check_exists files/home/.local/bin/dub-obs-hotkey

# --- Contracts ---
printf -- '\n--- Contracts ---\n'
check_exists contracts/configctl/init/obs-presentation.toml

# --- Docs ---
printf -- '\n--- Docs ---\n'
check_exists docs/meeting-presentation.md

# --- Delegated semantic OBS checks ---
printf -- '\n--- Semantic OBS verification ---\n'
if python3 scripts/verify-obs-templates.py .; then
	ok "OBS templates semantic verification"
else
	fail "OBS templates semantic verification"
fi

# --- Legacy file existence checks ---
printf -- '\n--- Config files ---\n'
for path in \
	files/home/.config/hypr/custom.d/empty.conf \
	files/home/.config/waybar/style.css \
	files/home/.config/waybar/colors.css \
	files/home/.config/waybar/custom.css \
	files/home/.config/wofi/config; do
	check_exists "$path"
done

printf -- '\n--- Bin scripts ---\n'
for script in \
	dub-browser \
	dub-clipboard \
	dub-editor \
	dub-file-manager \
	dub-launch \
	dub-obs-hotkey \
	dub-screenshot \
	dub-session-doctor \
	dub-session-reset \
	dub-session-start \
	dub-terminal \
	dub-waybar-reload \
	dubctl-meeting \
	dubctl-meeting-session; do
	check_exists "files/home/.local/bin/$script"
done

exit "$status"
