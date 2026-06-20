#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

status=0

ok() { printf '[ok] %s\n' "$*"; }
fail() { printf '[fail] %s\n' "$*"; status=1; }

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
  [ -e "$path" ] && ok "$path exists" || fail "$path missing"
}

check_contains() {
  local path="$1"
  local pattern="$2"
  local description="$3"

  if grep -Eq "$pattern" "$path"; then
    ok "$description"
  else
    fail "$description"
  fi
}

printf 'Verifying session files\n\n'

for path in files/home/.local/bin/*; do
  [ -f "$path" ] || continue
  check_bash "$path"
done

for path in \
  files/home/.config/hypr/adopted.d/dubnium.conf \
  files/home/.config/hypr/custom.d/empty.conf \
  files/home/.config/waybar/config.jsonc \
  files/home/.config/waybar/style.css \
  files/home/.config/waybar/colors.css \
  files/home/.config/waybar/custom.css \
  files/home/.config/wofi/config \
  files/home/.config/mako/config \
  files/home/.config/npm/global-packages.txt; do
  check_exists "$path"
done

check_contains \
  files/home/.config/npm/global-packages.txt \
  '^@openai/codex$' \
  'npm global package list declares @openai/codex'

check_contains \
  modules/home/npm.nix \
  'prefix=\$\{cfg\.prefix\}' \
  'npm module manages .npmrc prefix'

check_contains \
  modules/home/npm.nix \
  '\$\{cfg\.prefix\}/bin' \
  'npm module adds global npm bin path to session path'

check_contains \
  modules/home/npm.nix \
  'npm-globals-sync' \
  'npm-globals-sync is declared'

for script in \
  dub-browser \
  dub-clipboard \
  dub-editor \
  dub-file-manager \
  dub-launch \
  dub-screenshot \
  dub-session-doctor \
  dub-session-reset \
  dub-session-start \
  dub-terminal \
  dub-waybar-reload; do
  check_exists "files/home/.local/bin/$script"
done

exit "$status"
