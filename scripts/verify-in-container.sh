#!/usr/bin/env sh

set -eu

usage() {
  echo "usage: $0 [flake|home|system|all ...]" >&2
}

if [ $# -eq 0 ]; then
  set -- all
fi

engine="${CONTAINER_ENGINE:-}"
image="${NIX_CONTAINER_IMAGE:-nixos/nix:2.24.14}"
workspace="/workspace"

if [ -z "$engine" ]; then
  if command -v docker >/dev/null 2>&1; then
    engine="docker"
  elif command -v podman >/dev/null 2>&1; then
    engine="podman"
  else
    echo "missing container engine: set CONTAINER_ENGINE or install docker/podman" >&2
    exit 1
  fi
fi

if ! command -v "$engine" >/dev/null 2>&1; then
  echo "missing container engine: $engine" >&2
  exit 1
fi

run_in_container() {
  command="$1"

  "$engine" run --rm \
    -e "NIX_CONFIG=experimental-features = nix-command flakes" \
    -v "$PWD:$workspace" \
    -w "$workspace" \
    "$image" \
    sh -lc "git config --global --add safe.directory '$workspace' && $command"
}

for target in "$@"; do
  case "$target" in
    flake)
      echo "==> nix flake check --no-build"
      run_in_container "nix flake check --no-build"
      ;;
    home)
      echo "==> nix build --no-link .#homeConfigurations.ryjen@nixos.activationPackage"
      run_in_container "nix build --no-link .#homeConfigurations.ryjen@nixos.activationPackage"
      ;;
    system)
      echo "==> nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel"
      run_in_container "nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel"
      ;;
    all)
      echo "==> running flake, home, and system verification"
      "$0" flake home system
      ;;
    *)
      echo "unknown target: $target" >&2
      usage
      exit 1
      ;;
  esac
done
