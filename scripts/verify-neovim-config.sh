#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

: "${DUBNIUM_DOTFILES_CONFIG_HOME:?DUBNIUM_DOTFILES_CONFIG_HOME must be set}"

export XDG_CONFIG_HOME="$DUBNIUM_DOTFILES_CONFIG_HOME"
export XDG_CACHE_HOME="$tmpdir/cache"
export XDG_DATA_HOME="$tmpdir/data"
export XDG_STATE_HOME="$tmpdir/state"

nvim --headless +qa
