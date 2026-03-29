# Nix Bootstrap

This is the first incremental Nix scaffold for the repository. It does not replace the current Ansible path yet.

## Included

- `flake.nix`
- one placeholder NixOS host at `hosts/nixos/`
- one Home Manager user entrypoint at `home/ryjen/home.nix`
- one shared NixOS fonts module for JetBrainsMono Nerd Font
- shared Home Manager modules for:
  - alacritty
  - ansible
  - bat
  - byobu
  - cowsay
  - direnv
  - fortune
  - fzf
  - git
  - gpg
  - lsd
  - lolcat
  - pass
  - pinentry
  - starship
  - taskwarrior
  - tmux
  - zsh

## Current Intent

This scaffold is intentionally narrow. It covers the planned `basic` migration slice and leaves the rest of the repo unchanged.

It is safe to continue using:

- `./bootstrap.sh install`
- `./bootstrap.sh uninstall`
- the existing Ansible inventories and role tests

## Before First Real NixOS Use

1. Replace `hosts/nixos/hardware-configuration.nix` with the generated hardware config from the target machine.
2. Replace placeholder identity values in `modules/home/git.nix`.
3. Choose a secret strategy for GPG material before trying to fully replace the current Ansible vault path.
4. Decide whether `hosts/nixos/` should be renamed to the real machine hostname.
5. Initialize `pass` manually once the target GPG key setup is in place.
6. Revisit `taskwarrior` hook automation separately if you still want timewarrior or sleep-script integration.

## Expected Commands

Evaluate the NixOS config:

```bash
nix flake show
```

Build the Home Manager activation package:

```bash
nix build .#homeConfigurations.ryjen@nixos.activationPackage
```

Build the NixOS system derivation:

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Switch Home Manager directly on a non-NixOS Linux host:

```bash
home-manager switch --flake .#ryjen@nixos
```

Switch the NixOS machine once the host is real:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

## Not Included Yet

- secrets management with `sops-nix` or `agenix`
- Neovim migration
- Docker migration
- host-specific overrides
- optional tooling such as Android and agent packages
