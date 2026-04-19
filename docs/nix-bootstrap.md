# Nix Bootstrap

This repository is now Nix-first. Use `flake.nix` for both system and user config.

## Included

- `flake.nix`
- NixOS host config at `hosts/nixos/`
- Home Manager user config at `home/ryjen/home.nix`
- shared NixOS modules in `modules/nixos/`
- shared Home Manager modules in `modules/home/`
- static Home Manager files in `files/home/`
- static system files in `files/system/`

## First Use

1. Replace `hosts/nixos/hardware-configuration.nix` with generated hardware config for the target machine.
2. Review identity values in `modules/home/git.nix`.
3. Copy `secrets.yaml.example` to `secrets.yaml`, fill values, and encrypt with `sops`.
4. Initialize `pass` manually once GPG setup is in place.
5. Run `agents-update` after Home Manager switch to install external agent skills.

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
