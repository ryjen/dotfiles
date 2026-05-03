# Home Config Migration Checklist

This checklist captures relevant configuration found under `~/` that should be reviewed as part of the Nix migration. It is based on the current home-directory audit and is intended to separate declarative config from secrets and machine-local state.

## Core Environment

- [x] Port session variables from [~/.profile](/home/USERNAME/.profile) into Nix-managed `home.sessionVariables` or NixOS environment settings.
- [x] Decide which Wayland and desktop variables from [~/.profile](/home/USERNAME/.profile) are host-specific versus shared defaults.
- [x] Port `EDITOR`, `VISUAL`, `GIT_EDITOR`, and terminal-related defaults into Home Manager.
- [x] Keep JetBrains Toolbox PATH additions from [~/.profile](/home/USERNAME/.profile) and [~/.zprofile](/home/USERNAME/.zprofile) behind the workstation overlay instead of the shared baseline.

## Zsh

- [x] Review [~/.config/zsh/.zshrc](/home/USERNAME/.config/zsh/.zshrc) and model the non-secret behavior declaratively in `modules/home/zsh.nix`.
- [x] Port shell history and option settings from [~/.config/zsh/config.d/options](/home/USERNAME/.config/zsh/config.d/options).
- [x] Port non-secret aliases and integrations from [~/.config/zsh/config.d/](/home/USERNAME/.config/zsh/config.d).
- [x] Fold plugin sourcing from [~/.config/zsh/config.d/zsh-system](/home/USERNAME/.config/zsh/config.d/zsh-system) into Home Manager package/plugin management.
- [x] Port completion and PATH setup for non-secret tooling such as `asdf`, `pnpm`, `bun`, `kubectl`, `direnv`, `fzf`, `bat`, `lsd`, `wl-copy`, `ssh`, `systemctl`, and `virsh`.
- [x] Decide whether convenience hooks such as [~/.config/zsh/config.d/fortunes](/home/USERNAME/.config/zsh/config.d/fortunes) should remain part of the baseline shell experience.
- [ ] Review whether Neovim-related shell aliases in [~/.config/zsh/config.d/nvim](/home/USERNAME/.config/zsh/config.d/nvim) should stay deferred until the editor refactor.
- [ ] Keep secret-bearing files under [~/.config/zsh/config.d/](/home/USERNAME/.config/zsh/config.d) out of git-backed Home Manager config.

## Git

- [x] Keep default Git identity outside the shared baseline by using [home/USERNAME/git-local.nix.example](/home/USERNAME/.local/src/dotfiles/home/USERNAME/git-local.nix.example) or an explicit overlay.
- [x] Review include structure in [~/.config/git/includes.conf](/home/USERNAME/.config/git/includes.conf) and decide which includes belong in Home Manager.
- [x] Move project-specific identity and transport behavior into explicit overlays instead of relying on [~/.config/git/local.conf](/home/USERNAME/.config/git/local.conf).
- [x] Port useful global ignore rules from [~/.config/git/ignore](/home/USERNAME/.config/git/ignore).
- [x] Manage the shared commit template and Git template directory declaratively from the repo.

## GPG and Pass

- [ ] Decide whether the trusted key entry in [~/.gnupg/gpg.conf](/home/USERNAME/.gnupg/gpg.conf) should be preserved in the managed config.
- [ ] Reconcile pinentry choice between [~/.gnupg/gpg-agent.conf](/home/USERNAME/.gnupg/gpg-agent.conf) and [modules/home/gpg.nix](/home/USERNAME/.local/src/dotfiles/modules/home/gpg.nix).
- [ ] Keep `~/.gnupg` key material out of the repo and document import/bootstrap steps instead.
- [ ] Decide whether `pass` should remain the source of truth for user secrets during migration.
- [ ] Document any required initialization for [~/.password-store/](/home/USERNAME/.password-store) on a new NixOS host.

## Terminal and CLI Tools

- [ ] Confirm whether [~/.config/starship.toml](/home/USERNAME/.config/starship.toml) should fully replace the current minimal starship module settings.
- [ ] Confirm whether Kitty should be supported alongside Alacritty based on [~/.config/kitty/kitty.conf](/home/USERNAME/.config/kitty/kitty.conf).
- [ ] Review whether Byobu needs any persistent config beyond the current autostart behavior.
- [ ] Confirm whether the current Taskwarrior migration should incorporate any of the older include-based structure referenced by [~/.taskrc.orig](/home/USERNAME/.taskrc.orig).
- [ ] Decide whether empty or generated config trees such as `~/.config/task`, `~/.config/byobu`, and `~/.config/profile.d` should remain unmanaged.

## Secrets Migration

- [ ] Inventory all secret-bearing shell snippets currently stored under [~/.config/zsh/config.d/](/home/USERNAME/.config/zsh/config.d).
- [ ] Rotate any credentials that were previously stored in plaintext shell config.
- [x] Use `sops-nix` as the repository's Nix-compatible secret management path.
- [ ] Move shared secrets out of shell startup files and into encrypted secret material.
- [ ] Keep machine-local or temporary credentials out of the repository entirely.

## Explicitly Skip or Defer

- [ ] Skip direct migration of [~/.bashrc](/home/USERNAME/.bashrc) and [~/.bash_profile](/home/USERNAME/.bash_profile) unless Bash remains a supported interactive shell.
- [ ] Skip generated state such as Zsh completion dumps and welcome markers.
- [ ] Defer direct migration of editor-specific local state until Neovim is refactored.
- [x] Keep machine-specific Android and vendor CLI setup behind explicit overlays rather than the shared baseline.

## Completion Criteria

- [ ] Shared shell behavior is declarative.
- [ ] Shared Git and GPG behavior is declarative.
- [ ] Secrets are no longer stored in plaintext startup files.
- [x] Host-specific and machine-local config is clearly separated from the shared baseline using overlays.
- [ ] A fresh NixOS machine can bootstrap the intended shell environment without relying on the legacy home-directory state.
