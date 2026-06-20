#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/files/home/.config/npm/global-packages.txt"
npm_module="$repo_root/modules/home/npm.nix"
agents_module="$repo_root/modules/home/agents.nix"
default_module="$repo_root/modules/home/default.nix"

fail() {
  echo "verify-npm-global-env: $*" >&2
  exit 1
}

[ -f "$npm_module" ] || fail "missing modules/home/npm.nix"
[ -f "$manifest" ] || fail "missing files/home/.config/npm/global-packages.txt"

grep -q './npm.nix' "$default_module" || fail "modules/home/default.nix does not import ./npm.nix"
grep -q 'prefix=' "$npm_module" || fail "npm module does not manage .npmrc prefix"
grep -q '.local/share/npm' "$npm_module" || fail "npm module does not use the expected npm prefix"
grep -q 'home.sessionPath' "$npm_module" || fail "npm module does not add npm bin to home.sessionPath"
grep -q 'pkgs.nodejs' "$npm_module" || fail "npm module does not install nodejs"

if grep -q 'pkgs.codex' "$agents_module"; then
  fail "pkgs.codex is still installed by agents.nix; Codex must have one owner"
fi

if grep -q 'pkgs.nodejs' "$agents_module"; then
  fail "pkgs.nodejs is still installed by agents.nix; nodejs should be owned by npm tooling"
fi

grep -q '^@openai/codex$' "$manifest" || fail "npm package manifest does not declare @openai/codex"

awk '
  /^[[:space:]]*$/ { next }
  /^[[:space:]]*#/ { next }
  /[[:space:]]#/ { sub(/[[:space:]]#.*/, "") }
  /[[:space:]]/ { print "invalid whitespace in package spec: " $0; bad=1 }
  END { exit bad ? 1 : 0 }
' "$manifest" || fail "npm package manifest contains invalid package specs"

echo "verify-npm-global-env: ok"
