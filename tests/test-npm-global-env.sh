#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
verifier="$repo_root/scripts/verify-npm-global-env.sh"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

manifest="$test_dir/global-packages.txt"
output="$test_dir/verify.log"

check_case() {
  local label="$1"
  local expected="$2"
  local package_spec="$3"
  local actual="fail"

  printf '@openai/codex\n%s\n' "$package_spec" > "$manifest"
  if bash "$verifier" "$manifest" > "$output" 2>&1; then
    actual="pass"
  fi

  if [[ "$actual" != "$expected" ]]; then
    printf 'test-npm-global-env: %s: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
    cat "$output" >&2
    exit 1
  fi

  if [[ "$expected" == "fail" ]] &&
    ! grep -Fq 'Bitwarden CLI is owned by Home Manager' "$output"; then
    printf 'test-npm-global-env: %s: rejected for wrong reason\n' "$label" >&2
    cat "$output" >&2
    exit 1
  fi
}

check_case 'unversioned duplicate' fail '@bitwarden/cli'
check_case 'versioned duplicate' fail '@bitwarden/cli@2026.10.0'
check_case 'duplicate with inline comment' fail '@bitwarden/cli # legacy'
check_case 'versioned duplicate with inline comment' fail '@bitwarden/cli@latest # legacy'
check_case 'similarly named package' pass '@bitwarden/cli-helper'
check_case 'comment-only package' pass '# @bitwarden/cli@latest'
check_case 'other package' pass '@tobilu/qmd'

echo 'test-npm-global-env: ok'
