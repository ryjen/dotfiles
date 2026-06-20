# Configctl Manifest Contracts

This directory is the dotfiles-owned contract surface consumed by Dubnium's `configctl` executor.

The manifests are declarative policy. They describe what this repository owns, which user paths are intentionally local-only, and which files may be adopted or composed by explicit tooling. They do not execute commands, perform network I/O, install packages, or mutate user state by themselves.

## Contract roots

```text
contracts/configctl/
├── apps/       # per-application config ownership and composition contracts
├── init/       # explicit first-run mutable state contracts
└── schema-v1.md
```

## Rules

- Dotfiles owns manifests for user-owned app configuration.
- Dubnium owns the executor implementation and validation UX.
- Home Manager may create deterministic source/generated files, but it must not create or overwrite `local.*` escape hatches.
- `local.*` paths are never promotion candidates.
- `custom.d/*` paths are promotion candidates only through an explicit adopt workflow.
- `adopted.d/*` paths are archive/evidence paths, ignored during normal runtime unless a manifest says otherwise.
- Hashes are evidence for review and reconciliation. They are not authority to silently rewrite or delete user files.
- V1 manifests must not include arbitrary command execution.

## Optimized path model

App manifests define path roles once under `[layout]`.

Common roles:

| Role | Meaning |
| --- | --- |
| `managed_sources` | Repo source files or Home Manager-owned runtime files used as composition input. |
| `runtime_outputs` | Final runtime files the app reads. |
| `local` | Machine-local files that must not be overwritten or promoted. |
| `custom` | User-authored promotion candidates. |
| `adopted` | Archive/evidence paths for already adopted fragments. |
| `runtime_includes` | Files loaded directly by tools with native include support. |

Behavior sections refer to roles, not duplicated path globs. For example, adoption ignores `local` and `adopted` roles instead of repeating every path.

## Lifecycle fields

Every app/init manifest must declare whether it describes current behavior or a planned migration:

| Field | Meaning |
| --- | --- |
| `status` | `active` or `planned`. |
| `current_runtime_owner` | Current writer of runtime outputs, usually `home-manager` today. |
| `target_runtime_owner` | Intended future writer after migration. |
| `executor_may_validate` | Whether `configctl` may validate the contract now. |
| `executor_may_adopt` | Whether `configctl` may use the adoption policy now. |
| `executor_may_write_outputs` | Whether `configctl` may write runtime outputs now. |

Planned compose manifests are intentionally not write-enabled while Home Manager still owns the runtime files.

## Manifest semantics

### App manifests

Files under `apps/` describe application configuration that dotfiles owns or exposes to `configctl`.

`native-include` means the app can load local/custom fragments itself, so `configctl` mostly validates and adopts. `compose` means the app needs a renderer because it lacks usable include semantics for the desired layering model. `direct-managed` means the app remains Home Manager-owned only; no local/adopt workflow is promised.

### Init manifests

Files under `init/` describe initial mutable state that may be created by an explicit `configctl init <tool>` flow.

Important constraints:

- Init is for first-run mutable tool state only.
- Init may create directories and empty files with safe permissions.
- Init must not run arbitrary commands in v1.
- Init must not fetch network resources.
- Init must not prune or rewrite existing user content unless the manifest explicitly marks the action as non-destructive and the executor confirms it.

## Current coverage

| Tool | Manifest | Strategy | Status | Current owner | Target owner |
| --- | --- | --- | --- | --- | --- |
| Hyprland | `apps/hypr.toml` | native include | active | Home Manager | Home Manager |
| Zsh | `apps/zsh.toml` | native include | active | Home Manager | Home Manager |
| Hyprpaper | `apps/hyprpaper.toml` | compose | planned | Home Manager | configctl |
| Mako | `apps/mako.toml` | compose | planned | Home Manager | configctl |
| Eww | `apps/eww.toml` | compose | planned | Home Manager | configctl |
| Waybar | `apps/waybar.toml` | compose | planned | Home Manager | configctl |
| Variety | `init/variety.toml` | init | planned | Home Manager activation | configctl init |

## Non-goals

- No `configctl` executable implementation in this repository.
- No npm global package management.
- No network-backed init.
- No automatic promotion, pruning, or garbage collection.
- No public mdBook generation.
