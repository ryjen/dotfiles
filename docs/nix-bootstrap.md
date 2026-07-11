# Nix Bootstrap

This repository is now Nix-first. Use `flake.nix` for both system and user config.

## Included

- `flake.nix`
- NixOS host config at `hosts/nixos/`
- Home Manager user config at `home/USERNAME/home.nix`
- ignored local user config at `home/USERNAME/user.nix`
- tracked user config template at `home/USERNAME/user.example.nix`
- host/profile selection in `home/USERNAME/profiles/`
- shared NixOS modules in `modules/nixos/`
- shared Home Manager modules in `modules/home/`
- static Home Manager files in `files/home/`
- static system files in `files/system/`

## First Use

1. Replace `hosts/nixos/hardware-configuration.nix` with generated hardware config for the target machine.
2. Copy `home/USERNAME/user.example.nix` to `home/USERNAME/user.nix` and set local identity and user-wide selections.
3. Keep secrets local by default. Use `user.nix`, `~/.config/zsh/local.zsh`, `pass`, or host environment injection as appropriate; do not commit secrets.
4. Only if repo-managed secrets are required, copy `secrets.yaml.example` to `secrets.yaml`, fill values, and encrypt with `sops`.
5. Initialize `pass` manually once GPG setup is in place.
6. Review `home/USERNAME/profiles/nixos.nix` and enable only host-specific overlays that belong on that machine.
7. Run `agents-update` after Home Manager switch to install external agent skills.

## Commands

Evaluate the flake:

```bash
nix flake show
nix flake check --no-build
```

Build Home Manager activation:

```bash
nix build .#homeConfigurations.USERNAME@nixos.activationPackage
```

Build NixOS system:

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Switch Home Manager:

```bash
home-manager switch --flake .#USERNAME@nixos
```

Switch NixOS:

```bash
sudo nixos-rebuild switch --flake .#nixos
```
