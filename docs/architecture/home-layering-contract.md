# Home Manager Layer Contract for Dubnium Consumers

## Purpose

This document defines the contract exported by this repository's Home Manager layer when it is consumed by host/platform repositories such as `ryjen/dubnium`.

The contract has two jobs:

1. keep Home Manager-managed user configuration reproducible; and
2. make the boundary explicit enough that Dubnium can provide host prerequisites, diagnostics, and executors without duplicating user-layer policy.

This repository owns the user-layer policy. Dubnium may import this layer and inspect repo-authored manifests, but should not redefine per-tool Home Manager behavior.

## Consumer model

```text
Dubnium host / NixOS layer
  owns: host packages, system services, service enablement, operators, diagnostics

Dotfiles Home Manager layer
  owns: user packages, shell/session behavior, user config policy, user app manifests

configctl / dubctl executors
  own: validation, read-only inspection, explicit mutation workflows
  consume: dotfiles-authored contracts/manifests where the app config is user-owned
```

Rules:

- Dubnium may import `home/ryjen/dubnium-home.nix` as the Dubnium-facing Home Manager entry point.
- `home/ryjen/dubnium-home.nix` imports `modules/home/default.nix` plus the Dubnium profile.
- `modules/home/default.nix` is the broad module hub, not a promise that every imported module is public API.
- Profile files under `home/ryjen/profiles/` express user-layer capability selection.
- `configctl` may consume dotfiles-owned manifests for apps whose config is owned here.
- Dubnium should not bake assumptions about individual dotfiles module internals into NixOS modules or activation scripts.

## Stable entry points

### Dubnium-facing entry point

```text
home/ryjen/dubnium-home.nix
```

This is the stable import target for Dubnium's Home Manager integration. It sets the user, home directory, Home Manager state version, imports the common module hub, imports the Dubnium profile, and conditionally imports local Git identity.

### Module hub

```text
modules/home/default.nix
```

This is the internal aggregation point for reusable Home Manager modules. Dubnium may treat the existence of this hub as part of the integration contract, but should avoid depending on the exact module list unless a module is explicitly promoted into a manifest or documented profile contract.

Current module categories:

| Category | Examples | Contract status |
| --- | --- | --- |
| Shell/session | `common.nix`, `session.nix`, `zsh.nix`, `starship.nix`, `direnv.nix` | user-layer policy |
| Editors/terminals | `neovim.nix`, `helix.nix`, `tmux.nix`, `alacritty.nix` | user-layer policy |
| Desktop/app config | `hypr.nix`, `browser.nix`, `input.nix`, `pinentry.nix` | user-layer policy; may expose app manifests |
| Developer tools | `git.nix`, `gpg.nix`, `android.nix`, `agents.nix`, `micrantha.nix` | profile-gated where appropriate |
| Optional secret-backed config | `secrets.nix` | local/private input; not a host contract |

### Profile entry point

```text
home/ryjen/profiles/dubnium.nix
```

The Dubnium profile currently enables the workstation and browser profiles, disables Android and Micrantha-specific profiles, and selects the Dubnium Hypr adopted profile.

Dubnium may use this as the user-layer profile contract. It should not infer that every workstation host must enable every optional system service.

## Ownership matrix

| Concern | Owner | Notes |
| --- | --- | --- |
| Host packages required before login | Dubnium/NixOS | Base system tools, graphical/session prerequisites, system service dependencies. |
| System services and timers | Dubnium/NixOS | Enablement must be explicit; profiles should not silently enable heavy optional services. |
| User packages | dotfiles/Home Manager | CLI/editor/user apps belong here unless needed before login or by system services. |
| Node/npm global tooling | dotfiles/Home Manager | User-layer tool state; see `ryjen/dotfiles#22` and `ryjen/dubnium#109`. |
| `configctl` executable | Dubnium | Executor and diagnostics implementation. |
| `configctl` app contracts/manifests | dotfiles, when app config is user-owned | Consumed by Dubnium tooling; defined close to the owned config. |
| Runtime/generated app config | generated under user config dirs | Mark as generated; do not hand-edit. |
| Mutable post-activation tool state | explicit `configctl init`/adopt contracts | Network-backed mutation must be opt-in and risk-gated. |
| Local unmanaged overrides | user/machine local | `local.*` and local-only files are explicit opt-outs from repo management. |
| Private secrets | host/user local secret mechanism | Must not be materialized into Nix-store-rendered user config. |
| Public material | owning repo or generated config, depending on use | Do not label public identifiers as private secrets. |

## Profile boundaries

### Workstation GUI profile

The workstation profile is the correct place for user-layer GUI defaults: shell behavior, editor defaults, terminal defaults, browser/user app config, and desktop-session preferences.

It must not imply that host-level optional services such as n8n, GitHub runner, vLLM, k3s, or exposed local AI endpoints are enabled.

### WSL/dev profile

WSL/dev support should prefer shell, editor, Git, language tooling, and path/session behavior. It should avoid desktop-only configuration and systemd assumptions unless explicitly guarded by the host layer.

### Developer/tooling profiles

Developer profiles may enable user-level developer tools and user-owned initialization manifests. They should not require root-owned mutation or host activation hooks to repair user state.

### Headless profile

If a headless Home Manager profile is added, it should be a user-layer profile for shells, editors, Git, agents, and CLI tooling. It should not become a duplicate Dubnium host profile or a hidden service bundle.

## Session environment contract

Dotfiles owns user-visible session behavior:

- shell PATH additions;
- Home Manager session variables;
- XDG user directories and state/cache/data separation;
- editor/tool launch environment;
- user service environment where Home Manager manages it.

Dubnium owns host/session prerequisites:

- system packages required before login;
- display/session services;
- systemd service units and environment for system services;
- host-level validation that the user environment is visible where expected.

When a value must be visible to shells, Hyprland, user services, and app launchers, prefer defining it once in the Home Manager layer and validating visibility from Dubnium diagnostics. Do not duplicate policy in host activation scripts.

## Config layout contract

Home Manager-managed configuration should use this shape when the target app can safely support layering:

```text
~/.config/<tool>/
├── managed.*      # generated by Home Manager/dotfiles; never edit directly
├── local.*        # machine-specific; never automatically promoted
├── custom.d/      # user-authored promotion candidates
└── adopted.d/     # fragments already promoted or represented by managed config
```

Ownership rules:

```text
managed.*    -> governed source of truth
local.*      -> machine-specific, ignored by promotion
custom.d/*   -> promotion candidates
adopted.d/*  -> archived/adopted fragments, ignored during normal load
```

Managed files should carry a generated-file header that identifies this repository as the source of truth and documents any active local/custom include hooks.

Apps without native include semantics require explicit composition manifests. Those manifests belong in dotfiles when the app config is owned by dotfiles, even if Dubnium implements the composition executor.

## Source, generated, mutable, and local-only state

| State class | Example | Policy |
| --- | --- | --- |
| Source fragments | repo-managed module inputs, app fragments, manifests | Reviewed in Git; durable source of truth. |
| Generated runtime config | composed `managed.*` output | Regenerated by Home Manager or explicit tooling; never hand-edit. |
| Mutable user state | npm global install state, first-run tool initialization | Managed by explicit init/adopt contracts, not system activation. |
| Local-only overrides | `local.*`, `git-local.nix`, machine-specific files | Never silently promoted, overwritten, or garbage-collected. |
| Adoption metadata | hashes/provenance for adopted fragments | Stored under XDG state, not managed config paths. |

## XDG state separation

Use:

```text
XDG_STATE_HOME = ~/.local/state
XDG_DATA_HOME  = ~/.local/share
XDG_CACHE_HOME = ~/.cache
```

Runtime state must not be written into managed config paths.

Adoption and reconciliation metadata belongs under XDG state, not under `~/.config/<tool>/`.

## Mutable state policy

Home Manager activation writes declarative user config. It is not a general lifecycle orchestrator.

Allowed:

- creating deterministic user config files;
- installing declarative user packages;
- exposing session variables and PATH entries;
- writing generated user config from repo-managed inputs;
- declaring app contracts/manifests for explicit tools to consume.

Not allowed:

- `sudo npm install -g` or root-owned user tool state;
- network-backed mutation from NixOS system activation;
- silently rewriting `local.*` files;
- treating Home Manager activation as an all-purpose repair hook;
- embedding private values in Nix-store-rendered files;
- making Dubnium system activation own user app policy.

`configctl init` and related adopt/reconcile flows should handle mutable first-run tool state. Those flows must be explicit, dry-run capable where practical, and risk-gated when they perform network or destructive actions.

## Promotion semantics

Promotion should produce:

1. a managed configuration change in dotfiles; and
2. adoption metadata proving a local fragment is represented by managed config.

Promotion must be review-gated through Git. A tool may propose a promotion, but the durable state change is a reviewed repository change.

`local.*` files are never promotion candidates. They are machine-specific escape hatches.

## Reconciliation semantics

Future reconciliation should be dry-run first.

```text
custom.d/* hash matches adoption metadata
  -> candidate to move to adopted.d/

custom.d/* differs from adopted hash
  -> conflict

local.*
  -> ignore

adopted.d/*
  -> ignore unless explicitly garbage-collected
```

Reconciliation must not silently move, delete, or promote user-authored files.

## Adoption metadata

Future state path:

```text
~/.local/state/home-layering/adoptions.toml
```

or another repo-approved XDG state path.

Example:

```toml
[[adoptions]]
id = "hypr-keybinds-001"
tool = "hypr"
source = "custom.d/keybinds.conf"
adopted_path = "adopted.d/keybinds.conf"
hash = "sha256:..."
promoted_at = "2026-05-31T18:00:00-07:00"
promoted_by = "dubnium-workstation"

[adoptions.managed]
repo = "ryjen/dotfiles"
path = "modules/home/hypr.nix"
commit = "abc123"
```

## Dubnium consumption requirements

Dubnium consumers should follow these constraints:

- Import the stable Home Manager entry point instead of reassembling dotfiles modules.
- Keep system activation limited to host-level prerequisites and deterministic system state.
- Keep read-only diagnostics separate from mutation.
- Prefer diagnostics before adopt/init/composition mutation.
- Treat dotfiles-owned manifests as contracts, not generated implementation detail.
- Link implementation PRs back to the relevant cross-repo issue when changing boundaries.

Related work:

- `ryjen/dotfiles#22` — npm global tooling and Codex ownership.
- `ryjen/dotfiles#37` — dotfiles-owned config composition manifests.
- `ryjen/dotfiles#38` — dotfiles-owned init/adopt manifests.
- `ryjen/dubnium#99` — canonical QART cleanup tracker.
- `ryjen/dubnium#109` — npm/Codex ownership split.
- `ryjen/dubnium#113` — `configctl adopt` and initial tool-state contracts.
- `ryjen/dubnium#114` — `configctl` composition contracts.

## Initial implementation target

Start with Hyprland.

Rationale:

- machine-local display/input tweaks are common;
- user keybinding experiments are common;
- managed config can source local/custom fragments safely;
- adopted fragments can be ignored; and
- Dubnium can validate the convention without owning the policy.

## QART notes

### Questions

- Which Home Manager modules are stable public contract versus internal organization?
- Should profile selection be dotfiles-native, Dubnium-driven, or both?
- Which tools need first-run mutable state after declarative config is applied?
- Which desktop apps require generated runtime config because they lack native include semantics?
- Which session variables must be visible consistently across shells, Hyprland, user services, and launchers?

### Alternatives

- Keep the boundary implicit and handle each issue ad hoc.
- Move more responsibility into Dubnium system modules.
- Move all user-layer contracts into dotfiles and keep Dubnium as executor/provider only.
- Treat Home Manager activation as the lifecycle hook for every user tool.

### Recommendation

Keep dotfiles as the policy source for user state. Keep Dubnium responsible for host-level prerequisites, system services, validation, diagnostics, and executor implementation. Require dotfiles-owned manifests for user/app-specific behavior consumed by `configctl`.

### Tradeoffs

- Explicit contracts add doc and manifest maintenance overhead.
- Some behavior now needs a two-repo change: dotfiles for policy, Dubnium for executor support.
- The payoff is fewer cross-repo regressions, less hidden coupling, and safer separation between declarative user config, generated config, mutable tool state, and host activation.

## Non-goals

- no automatic mutation initially;
- no silent promotion;
- no global overlay filesystem;
- no standalone `configctl` implementation in dotfiles;
- no reconciliation apply mode until dry-run behavior is proven;
- no host repository ownership of per-tool Home Manager semantics;
- no network-backed user-state mutation from NixOS system activation;
- no management of local-only/private files such as machine secrets or intentionally unmanaged `local.*` files.
