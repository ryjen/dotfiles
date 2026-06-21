#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
flake_file="$repo_root/flake.nix"

if [ ! -f "$flake_file" ]; then
  echo "missing flake.nix at $flake_file" >&2
  exit 1
fi

status=0

fail() {
  printf '[fail] %s\n' "$*" >&2
  status=1
}

ok() {
  printf '[ok] %s\n' "$*"
}

mapfile -t script_paths < <(
  sed -nE 's@.*\./(scripts/[A-Za-z0-9._/-]+).*@\1@p' "$flake_file" | sort -u
)

if [ "${#script_paths[@]}" -eq 0 ]; then
  echo "no script-backed flake targets found"
  exit 0
fi

for script_path in "${script_paths[@]}"; do
  full_path="$repo_root/$script_path"

  if [ ! -f "$full_path" ]; then
    fail "$script_path is referenced by flake.nix but does not exist"
    continue
  fi

  if [ ! -x "$full_path" ]; then
    fail "$script_path is referenced by flake.nix but is not executable in the flake source"
  else
    ok "$script_path is executable in the flake source"
  fi

  if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    index_mode="$(git -C "$repo_root" ls-files --stage -- "$script_path" | awk '{ print $1 }')"
    case "$index_mode" in
      100755)
        ok "$script_path is executable in the Git index"
        ;;
      100644)
        fail "$script_path is tracked but not executable in the Git index"
        ;;
      '')
        fail "$script_path is not tracked in the Git index"
        ;;
      *)
        fail "$script_path has unexpected Git index mode: $index_mode"
        ;;
    esac
  fi
done

exit "$status"
