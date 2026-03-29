# Nix Migration Plan

## Goal

Port this dotfiles repository from an Ansible + Stow installation model to a Nix-based model suitable for a future NixOS machine, while preserving the current repo as the source of truth during migration.

## Current State

The current installation flow is centered on:

- `install.yml` for role orchestration
- `collections/ansible_collections/ryjen/dotfiles/roles/installer/` for package installation and file linking
- `collections/ansible_collections/ryjen/dotfiles/roles/stow/` for symlink management
- role tags such as `basic`, `default`, and `extra` for layered setups

This structure is already close to a clean Nix migration because roles are separated by concern.

## Target State

The target structure should split responsibilities as follows:

- NixOS modules for system configuration, services, fonts, shell defaults, and machine-specific settings
- Home Manager for user packages, dotfiles, shell configuration, editor configuration, and CLI tooling
- `sops-nix` or `agenix` for secret material currently handled via Ansible vault
- Small activation hooks only where a package or config cannot be expressed declaratively

## Design Principles

1. Keep migration incremental.
2. Avoid a big-bang rewrite.
3. Replace Stow with Home Manager-managed files.
4. Replace distro branching with Nix package declarations.
5. Keep host-specific configuration separate from shared user configuration.
6. Prefer declarative Neovim/plugin management over imperative bootstrap steps.
7. Preserve the existing Ansible path until the Nix path is good enough to replace it.

## Proposed Repository Layout

```text
.
├── flake.nix
├── hosts/
│   └── <hostname>/
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── nixos/
│   │   ├── docker.nix
│   │   ├── fonts.nix
│   │   ├── shell.nix
│   │   └── system-packages.nix
│   └── home/
│       ├── git.nix
│       ├── gpg.nix
│       ├── neovim.nix
│       ├── starship.nix
│       ├── tmux.nix
│       └── zsh.nix
└── home/
    └── ryjen/
        └── home.nix
```

## Role Mapping

### Move to Home Manager

- `git`
- `zsh`
- `gpg`
- `starship`
- `bat`
- `neovim`
- `pass`
- `pinentry`
- `tmux`
- `byobu`
- `direnv`
- `fzf`
- `lsd`
- `taskwarrior`
- `alacritty`
- `fortunes`
- `lolcat`
- `cowsay`
- `ansible`
- `agents`

### Move to NixOS Modules

- `docker`
- `nerdfonts`
- `input`
- `motd`
- system package defaults
- login shell defaults

### Remove Entirely

- `stow`
- most of `installer`
- distro-specific package selection under `ubuntu.yml`, `arch.yml`, and `macos.yml`

### Revisit Case by Case

- `android`
- `oh-my-zsh`
- `micrantha`

These may remain optional dev tooling, become `home.packages`, or move into dedicated dev shells rather than baseline machine config.

## Migration Phases

### Phase 1: Bootstrap Nix Structure

Create the minimal Nix entrypoints:

- `flake.nix`
- one NixOS host configuration
- one Home Manager user configuration
- shared module directories

Deliverable:

- A machine can evaluate the flake successfully.

### Phase 2: Port the `basic` Profile

Port the baseline roles first:

- `git`
- `gpg`
- `zsh`
- `input`
- `starship`

Deliverable:

- The baseline shell environment works without Ansible or Stow.

### Phase 3: Port the `default` CLI Layer

Move the common terminal tooling and editor setup:

- `bat`
- `neovim`
- `pass`
- `pinentry`
- `tmux`
- `byobu`
- `direnv`
- `fortunes`
- `fzf`
- `lolcat`
- `lsd`
- `nerdfonts`

Deliverable:

- The day-to-day terminal environment is managed declaratively.

### Phase 4: Port the `extra` and Optional Tooling

Move heavier or more machine-specific items:

- `docker`
- `android`
- `alacritty`
- `taskwarrior`
- `agents`

Deliverable:

- Optional tooling is expressed either as NixOS modules, Home Manager modules, or dev shells.

### Phase 5: Secrets and Cleanup

Replace vault usage and remove obsolete Ansible paths:

- migrate secrets from `vault/config.yml` and `vault/gpg_key.yml`
- delete `stow` role
- reduce or remove `installer`
- update `README.md`
- keep Ansible only if there is still a non-Nix target worth supporting

Deliverable:

- Nix is the primary installation path.

## First Implementation Slice

The first coding slice should stay small:

1. Add `flake.nix`.
2. Add one host under `hosts/`.
3. Add one Home Manager entrypoint under `home/`.
4. Port `git`, `zsh`, `starship`, and `gpg`.
5. Keep all existing Ansible code intact.

This gives a working baseline without forcing an immediate rewrite of Neovim, Docker, or secrets handling.

## Known Technical Changes

### Git

Replace templated git user config with Home Manager `programs.git` options and conditional includes where needed.

### GPG

Replace template rendering and import-time shell commands with:

- declarative GnuPG and agent configuration
- a secret management strategy for private key material
- optional one-time documented import procedure if full declarative import is not worth the complexity

### Zsh

Replace copied shell files with Home Manager-managed files or `programs.zsh` options.

### Neovim

The current role bootstraps Packer imperatively. This should be redesigned rather than copied directly:

- either manage plugins through Nix
- or keep plugin management in Lua while Nix manages Neovim and dependencies

The second option is a lower-friction first step.

### Agents / npm Globals

Global npm installs are usually a poor fit for a reproducible machine definition. Prefer:

- Nix packages where available
- local project dev shells
- explicit wrappers for tools that are not yet packaged

## Open Questions

1. Will this repo remain cross-platform, or become NixOS-first?
2. Do macOS hosts still need support after the Nix migration starts?
3. Should secrets be standardized on `sops-nix` or `agenix`?
4. Should Neovim plugin management be fully Nix-managed, or only partially?
5. Should optional tooling be modeled as flake apps, dev shells, or host toggles?

## Completion Criteria

The migration should be considered substantially complete when:

- a new NixOS machine can be built from this repo
- the baseline user environment works without Ansible
- secrets have a defined Nix-compatible path
- Stow is gone
- the README documents the new canonical setup flow
