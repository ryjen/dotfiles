# Home Manager Layer Contract for Dubnium Consumers

## Purpose

This document defines the Home Manager contract exported by `ryjen/dotfiles` for consumers such as `ryjen/dubnium`.

The goals are:

1. keep tracked Home Manager configuration reproducible;
2. permit explicit, ignored local program selections during local builds and switches; and
3. keep host, user, mutable-state, and secret ownership boundaries clear.

## Ownership model

```text
Dubnium / NixOS
  owns host packages, system services, hardware prerequisites, diagnostics,
  and host-oriented operator commands

Dotfiles / Home Manager
  owns user packages, shell/session policy, user configuration, app manifests,
  and user-facing feature options

user.local.nix
  owns ignored, local, non-secret user-wide selections and Git identity

configctl
  owns explicit validation, composition, init, adopt, and reconciliation flows
  for mutable user configuration
```

Dubnium must not duplicate per-program Home Manager policy or silently mutate user-owned configuration during system activation.

## Home Manager composition

Stable entry points import:

```text
one module-set layer
+ one concrete host/profile file
+ optional home/ryjen/user.local.nix
```

Current entry points:

| Output | Module layer | Profile | Contract |
| --- | --- | --- | --- |
| `ryjen@dubnium` | `graphical.nix` | `dubnium.nix` | Graphical workstation; not laptop-specific. |
| `ryjen@technetium` | `graphical.nix` | `technetium.nix` | Graphical laptop; owns laptop-specific Waybar behavior. |
| `ryjen@nixos` | `graphical.nix` | `nixos.nix` | Compatibility workstation output. |
| `ryjen@headless` | `lightweight.nix` | `headless.nix` | Non-graphical shell/server output. |
| `ryjen@wsl` | `lightweight.nix` | `wsl.nix` | WSL-safe output with user systemd disabled. |
| `ryjen@verify` | `lightweight.nix` | `verify.nix` | Lightweight tracked verification output. |

Layer files answer which reusable module set is imported. Profile files express tracked host-role constraints and defaults. `user.local.nix` expresses local non-secret selections that should not be committed.

## Local selector contract

The ignored selector is:

```text
home/ryjen/user.local.nix
```

The tracked template is:

```text
home/ryjen/user.example.nix
```

Create it with:

```bash
cp home/ryjen/user.example.nix home/ryjen/user.local.nix
```

Git-backed flakes exclude ignored files. Any build, check, or switch that must include `user.local.nix` must therefore evaluate the checkout as an explicit path flake from the repository root:

```bash
home-manager switch --flake "path:$PWD#ryjen@dubnium"
nix build "path:$PWD#homeConfigurations.ryjen@dubnium.activationPackage"
nix flake check "path:$PWD"
```

Ordinary Git-flake commands intentionally validate tracked defaults without local selections:

```bash
nix flake check --no-build
nix build .#homeConfigurations.ryjen@verify.activationPackage
```

CI validates the tracked configuration only. It does not validate a user's ignored local selection matrix.

## Local selector restrictions

`user.local.nix` may contain:

- explicit program and capability enablement;
- non-secret Git identity;
- non-secret local user preferences that affect Home Manager evaluation.

It must not contain secrets. A `path:` flake source is copied into the Nix store. Use `sops-nix`, `pass`, systemd credentials, or another runtime secret mechanism for private values.

## Feature ownership

Importing a module registry should define options without implicitly enabling optional user-facing programs.

Each feature module owns:

- its required runtime packages;
- generated files;
- wrappers and desktop entries;
- shell/session integration;
- user services and systemd units;
- required assertions and dependency checks.

Dependency rules:

| Dependency type | Treatment |
| --- | --- |
| Internal runtime dependency | Install inside the owning feature module. |
| Shared user-facing tool | Give it its own explicit enable option. |
| Required cross-module capability | Set with `lib.mkDefault` or reject invalid combinations with an assertion. |
| Optional integration | Give it a separate nested option and validate prerequisites. |

## Profile boundaries

Tracked profiles contain host-role information such as:

- graphical, laptop, workstation, headless, or WSL capability;
- hardware/display constraints;
- host-specific paths;
- tracked role-specific defaults.

Profiles should not become a second taxonomy for user-facing program selection. Individual program or capability options remain the source of truth.

## Mutable and generated state

Home Manager activation may:

- install declarative user packages;
- generate deterministic user configuration;
- expose session variables and PATH entries;
- declare app contracts and manifests.

Home Manager activation must not:

- perform network-backed mutation;
- silently rewrite local files;
- act as a general repair hook;
- materialize secrets into Nix-store-rendered files;
- make the host repository own per-app user policy.

Use explicit `configctl init`, adopt, compose, or reconcile workflows for mutable first-run and post-activation state.

## Config layout

When an application supports layering, prefer:

```text
~/.config/<tool>/
├── managed.*      # generated and owned by Home Manager
├── local.*        # machine-local, never auto-promoted
├── custom.d/      # user-authored promotion candidates
└── adopted.d/     # fragments already represented by managed config
```

Runtime and reconciliation metadata belongs under XDG state paths, not managed config directories.

## Consumer requirements

Dubnium consumers must:

- import stable Home Manager entry points instead of reassembling module internals;
- keep system activation limited to deterministic host-level state;
- use `dubctl` for host diagnostics and operator UX;
- use `configctl` for explicit user-config mutation workflows;
- treat dotfiles-authored manifests as contracts;
- avoid embedding assumptions about individual Home Manager module internals.

## Non-goals

- no silent promotion or reconciliation;
- no automatic network-backed mutation during activation;
- no host ownership of per-program Home Manager semantics;
- no management of machine secrets through `user.local.nix`;
- no assumption that tracked CI validates ignored local selections.
