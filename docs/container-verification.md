# Container Verification

Use this when you want to verify the flake and build targets on a host without relying on the host Nix daemon or mutating the working tree with `result` symlinks.

## What It Verifies

- `nix flake check --no-build`
- `nix build --no-link .#homeConfigurations.ryjen@verify.activationPackage`
- `nix build --no-link .#nixosConfigurations.verify.config.system.build.toplevel`

This verifies evaluation and buildability in an isolated Linux container using a lightweight verification profile. It does not replace `home-manager switch` or `nixos-rebuild switch` on the real machine.

## Requirements

- Docker or Podman available on the host
- network access from the container so Nix can fetch inputs and build dependencies

## Usage

Preferred entrypoint:

```bash
nix run .#verify-container
```

Run individual targets:

```bash
nix run .#verify-container -- flake
nix run .#verify-container -- home
nix run .#verify-container -- system
```

Script entrypoint also works:

```bash
./scripts/verify-in-container.sh
```

Use Podman instead of Docker:

```bash
CONTAINER_ENGINE=podman nix run .#verify-container
```

Override the container image if needed:

```bash
NIX_CONTAINER_IMAGE=nixos/nix:2.24.14 nix run .#verify-container
```

## Notes

- builds run with `--no-link`, so they do not create `result` symlinks in the repo
- the container bind-mounts the repository at `/workspace`
- verification uses the tracked `ryjen@verify` and `nixosConfigurations.verify` outputs, which keep Android and other machine-specific overlays disabled
- if you need final machine validation, still run `home-manager switch --flake .#ryjen@nixos` and `sudo nixos-rebuild switch --flake .#nixos` on the host
