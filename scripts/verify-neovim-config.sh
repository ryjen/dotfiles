#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export XDG_CONFIG_HOME="${DOTFILES_CONFIG_HOME:-$repo_root/files/home/.config}"
export XDG_CACHE_HOME="$tmpdir/cache"
export XDG_DATA_HOME="$tmpdir/data"
export XDG_STATE_HOME="$tmpdir/state"

nvim --headless +qa
