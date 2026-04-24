# Nix Bootstrap

This repository is now Nix-first. Use `flake.nix` for both system and user config.

## Included

- `flake.nix`
- NixOS host config at `hosts/nixos/`
- Home Manager user config at `home/ryjen/home.nix`
- host/profile selection in `home/ryjen/profiles/`
- shared NixOS modules in `modules/nixos/`
- shared Home Manager modules in `modules/home/`
- static Home Manager files in `files/home/`
- static system files in `files/system/`

## First Use

1. Replace `hosts/nixos/hardware-configuration.nix` with generated hardware config for the target machine.
2. Copy `home/ryjen/git-local.nix.example` to `home/ryjen/git-local.nix` and set the default Git identity for non-overlay repos.
3. Copy `secrets.yaml.example` to `secrets.yaml`, fill values, and encrypt with `sops`.
4. Initialize `pass` manually once GPG setup is in place.
5. Review `home/ryjen/profiles/nixos.nix` and enable only the overlays that belong on that machine.
6. Run `agents-update` after Home Manager switch to install external agent skills.

## Commands

Evaluate the flake:

```bash
nix flake show
nix flake check --no-build
```

Build Home Manager activation:

```bash
nix build .#homeConfigurations.ryjen@nixos.activationPackage
```

Build NixOS system:

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Switch Home Manager:

```bash
home-manager switch --flake .#ryjen@nixos
```

Switch NixOS:

```bash
sudo nixos-rebuild switch --flake .#nixos
```
