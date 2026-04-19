# Nix Migration

Migration is now Nix-first.

## Current State

- NixOS config lives under `hosts/nixos/` and `modules/nixos/`.
- Home Manager config lives under `home/ryjen/` and `modules/home/`.
- Static migrated config files live under `files/home/` and `files/system/`.
- Secrets use `sops-nix`.
- Legacy imperative install tooling has been removed.

## Remaining Work

- Validate `home-manager switch --flake .#ryjen@nixos` on the target user.
- Validate `sudo nixos-rebuild switch --flake .#nixos` on the target host.
- Refactor Neovim to reduce plugin bootstrap impurity if desired.
- Review `files/home/` for static files that should become native Home Manager options.
- Decide whether to add `nix-darwin` for macOS.

## Design Direction

- Prefer declarative Home Manager and NixOS module options.
- Keep host-specific state out of shared modules.
- Keep secrets in encrypted `sops-nix` files.
- Keep agent skills internet-updatable through `agents-update` rather than vendoring full skill repos.
