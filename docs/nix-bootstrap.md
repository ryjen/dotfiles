# Nix Bootstrap

This repository is Nix-first. Use `flake.nix` for both system and user configuration.

## Included

- `flake.nix`
- NixOS host config at `hosts/nixos/`
- Home Manager user config at `home/USERNAME/home.nix`
- ignored local selector at `home/USERNAME/user.local.nix`
- tracked local-selector template at `home/USERNAME/user.example.nix`
- host/profile selection in `home/USERNAME/profiles/`
- shared NixOS modules in `modules/nixos/`
- shared Home Manager modules in `modules/home/`
- static Home Manager files in `files/home/`
- static system files in `files/system/`

## First Use

1. Replace `hosts/nixos/hardware-configuration.nix` with generated hardware config for the target machine.
2. Copy `home/USERNAME/user.example.nix` to `home/USERNAME/user.local.nix` and set non-secret local identity and user-wide selections.
3. Keep secrets out of `user.local.nix`; a `path:` flake copies it into the Nix store. Use `sops-nix`, `pass`, systemd credentials, or another runtime secret mechanism.
4. Only if repo-managed secrets are required, copy `secrets.yaml.example` to `secrets.yaml`, fill values, and encrypt with `sops`.
5. Initialize `pass` manually once GPG setup is in place.
6. Review `home/USERNAME/profiles/nixos.nix` and enable only host-specific overlays that belong on that machine.
7. Run `agents-update` after Home Manager switch to install external agent skills.

## Commands

Run local-selector commands from the repository root.

Evaluate tracked configuration only:

```bash
nix flake show
nix flake check --no-build
```

Evaluate with `user.local.nix` included:

```bash
nix flake check "path:$PWD"
```

Build Home Manager activation with local selections:

```bash
nix build "path:$PWD#homeConfigurations.USERNAME@nixos.activationPackage"
```

Build NixOS with local selections:

```bash
nix build "path:$PWD#nixosConfigurations.nixos.config.system.build.toplevel"
```

Switch Home Manager with local selections:

```bash
home-manager switch --flake "path:$PWD#USERNAME@nixos"
```

Switch NixOS with local selections:

```bash
sudo nixos-rebuild switch --flake "path:$PWD#nixos"
```
