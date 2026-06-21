#!/usr/bin/env sh
set -eu

if [ "$#" -gt 1 ]; then
  echo "usage: $0 [repo-root]" >&2
  exit 2
fi

if [ "$#" -eq 1 ]; then
  repo_root="$1"
else
  repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fi

flake_file="$repo_root/flake.nix"

if [ ! -f "$flake_file" ]; then
  echo "missing flake.nix at $flake_file" >&2
  exit 1
fi

script_refs="$(
  grep -Eo '\./scripts/[^"[:space:]}]+' "$flake_file" \
    | sed 's|^\./||' \
    | sort -u
)"

if [ -z "$script_refs" ]; then
  echo "no ./scripts/... references found in flake.nix"
  exit 0
fi

status=0

fail() {
  printf '[fail] %s\n' "$*" >&2
  status=1
}

ok() {
  printf '[ok] %s\n' "$*"
}

is_git_checkout=false
if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  is_git_checkout=true
fi

printf 'Verifying flake script executable contract\n\n'

for script_ref in $script_refs; do
  script_path="$repo_root/$script_ref"

  if [ ! -f "$script_path" ]; then
    fail "$script_ref missing"
    continue
  fi

  if [ ! -x "$script_path" ]; then
    fail "$script_ref is not executable on disk"
  else
    ok "$script_ref executable on disk"
  fi

  if [ "$is_git_checkout" = true ]; then
    index_mode="$(git -C "$repo_root" ls-files --stage -- "$script_ref" | awk '{ print $1 }')"

    if [ -z "$index_mode" ]; then
      fail "$script_ref is not tracked in Git"
    elif [ "$index_mode" != "100755" ]; then
      fail "$script_ref has Git index mode $index_mode, expected 100755"
    else
      ok "$script_ref executable in Git index"
    fi
  fi
done

exit "$status"
