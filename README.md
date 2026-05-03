# dotfiles

Nix-first dotfiles for NixOS and Home Manager with a reusable baseline and opt-in host/profile overlays.

## Layout

- `flake.nix` defines the NixOS and Home Manager entrypoints.
- `hosts/nixos/` contains the current NixOS host config.
- `home/USERNAME/home.nix` is the user Home Manager entrypoint.
- `home/USERNAME/profiles/` contains host/profile selections for a concrete machine.
- `modules/nixos/` contains system modules.
- `modules/home/` contains user modules.
- `files/home/` contains static user config files managed by Home Manager.
- `files/system/` contains static system files used by NixOS modules.

## Profiles

Shared baseline modules are always imported. Host- or organization-specific behavior is enabled through `dotfiles.profiles.*` options from a profile file such as `home/USERNAME/profiles/nixos.nix`.

Current overlays:

- `dotfiles.profiles.workstation.enable` for local workstation session state and PATH additions
- `dotfiles.profiles.android.enable` for Android tooling
- `dotfiles.profiles.micrantha.enable` for Micrantha SSH, Git, and Zsh config

Tracked profile entrypoints:

- `home/USERNAME/profiles/nixos.nix` for the full local machine profile
- `home/USERNAME/profiles/verify.nix` for lightweight verification without Android or other machine-specific overlays
- `modules/home/verify.nix` for the lightweight shared module set used by verification

Architecture rationale lives in `docs/architecture/adr-0001-baseline-and-overlays.md`.

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
home-manager switch --flake .#USERNAME@nixos
```

Apply NixOS:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Build Home Manager activation package:

```bash
nix build .#homeConfigurations.USERNAME@nixos.activationPackage
```

Build NixOS system derivation:

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Containerized verification:

```bash
nix run .#verify-container
```

Lightweight verification outputs:

```bash
nix build .#homeConfigurations.USERNAME@verify.activationPackage
nix build .#nixosConfigurations.verify.config.system.build.toplevel
```

## Secrets

Secrets use `sops-nix`. Copy `secrets.yaml.example` to `secrets.yaml`, fill values, then encrypt with `sops`.

## Agent Skills

Agent, Hermes, and Codex config is intentionally minimal:

- `files/home/.agents/.skill-lock.json`
- `files/home/.codex/config.toml`
- `files/home/.codex/rules/default.rules`

Codex and Hermes Agent are installed through Home Manager. Codex comes from the
pinned nixpkgs package set, while Hermes comes from the pinned `hermes-agent`
flake input. First-time Hermes state remains local to the machine under
`~/.hermes` and should not be committed.

```bash
hermes setup
hermes
```

Run this after Home Manager switch to install or update skills from GitHub:

```bash
agents-update
```

## Git

The shared Git baseline is declarative:

- `~/.gitignore` is managed from `files/home/.gitignore`
- `~/.config/git/commit-message` is managed from the repo
- `~/.config/git/project` is populated from the repo's managed hook/template tree
- default personal identity should live in `home/USERNAME/git-local.nix`
- organization-specific identity can live behind an overlay such as `dotfiles.profiles.micrantha.enable`

For isolated Linux verification, see `docs/container-verification.md`.
