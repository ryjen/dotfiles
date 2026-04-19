# dotfiles

Nix-first dotfiles for NixOS and Home Manager.

## Layout

- `flake.nix` defines the NixOS and Home Manager entrypoints.
- `hosts/nixos/` contains the current NixOS host config.
- `home/ryjen/home.nix` is the user Home Manager entrypoint.
- `modules/nixos/` contains system modules.
- `modules/home/` contains user modules.
- `files/home/` contains static user config files managed by Home Manager.
- `files/system/` contains static system files used by NixOS modules.

## Commands

View flake outputs:

```bash
nix flake show
```

Check evaluation:

```bash
nix flake check --no-build
```

Apply Home Manager:

```bash
home-manager switch --flake .#ryjen@nixos
```

Apply NixOS:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Build Home Manager activation package:

```bash
nix build .#homeConfigurations.ryjen@nixos.activationPackage
```

Build NixOS system derivation:

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

## Secrets

Secrets use `sops-nix`. Copy `secrets.yaml.example` to `secrets.yaml`, fill values, then encrypt with `sops`.

## Agent Skills

Agent and Codex config is intentionally minimal:

- `files/home/.agents/.skill-lock.json`
- `files/home/.codex/config.toml`
- `files/home/.codex/rules/default.rules`

Run this after Home Manager switch to install or update skills from GitHub:

```bash
agents-update
```
