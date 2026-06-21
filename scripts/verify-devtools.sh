#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
devtools_module="$repo_root/modules/home/devtools.nix"
agents_module="$repo_root/modules/home/agents.nix"
default_module="$repo_root/modules/home/default.nix"
verify_module="$repo_root/modules/home/verify.nix"

fail() {
  echo "verify-devtools: $*" >&2
  exit 1
}

[ -f "$devtools_module" ] || fail "missing modules/home/devtools.nix"

grep -q './devtools.nix' "$default_module" || fail "modules/home/default.nix does not import ./devtools.nix"
grep -q './devtools.nix' "$verify_module" || fail "modules/home/verify.nix does not import ./devtools.nix"

for package in \
  pkgs.ffmpeg \
  pkgs.gh \
  pkgs.git \
  pkgs.openssh \
  pkgs.python311 \
  pkgs.ripgrep \
  pkgs.uv; do
  grep -q "$package" "$devtools_module" || fail "devtools module does not declare $package"
done

for unrelated_package in \
  pkgs.ffmpeg \
  pkgs.gh \
  pkgs.openssh \
  pkgs.python311 \
  pkgs.ripgrep \
  pkgs.uv; do
  if grep -q "$unrelated_package" "$agents_module"; then
    fail "agents module should not declare unrelated developer package $unrelated_package"
  fi
done

echo "verify-devtools: ok"
