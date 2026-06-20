# Configctl Manifest Contracts

This directory is the dotfiles-owned contract surface consumed by Dubnium's `configctl` executor.

The manifests are declarative policy. They describe what this repository owns, which user paths are intentionally local-only, and which files may be adopted or composed by explicit tooling. They do not execute shell, perform network I/O, install packages, or mutate user state by themselves.

## Contract roots

```text
contracts/configctl/
├── apps/       # per-application config ownership and composition contracts
└── init/       # explicit first-run mutable state contracts
```

## Rules

- Dotfiles owns manifests for user-owned app configuration.
- Dubnium owns the executor implementation and validation UX.
- Home Manager may create deterministic source/generated files, but it must not create or overwrite `local.*` escape hatches.
- `local.*` paths are never promotion candidates.
- `custom.d/*` paths are promotion candidates only through an explicit adopt workflow.
- `adopted.d/*` paths are archive/evidence paths, ignored during normal runtime unless a manifest says otherwise.
- Hashes are evidence for review and reconciliation. They are not authority to silently rewrite or delete user files.
- V1 manifests must not include arbitrary shell commands.

## Manifest semantics

### App manifests

Files under `apps/` describe application configuration that dotfiles owns or exposes to `configctl`.

Important fields:

| Field | Meaning |
| --- | --- |
| `tool` | Stable tool identifier used by `configctl`. |
| `owner` | Policy owner. This should be `dotfiles` for user-layer config here. |
| `profile` | Optional profile that activates the contract. |
| `strategy` | `native-include`, `compose`, or `direct-managed`. |
| `managed_files` | Files generated or installed by Home Manager/dotfiles. |
| `local_only` | Unmanaged machine-local files that must not be overwritten. |
| `promotion_sources` | User-authored files eligible for explicit adoption. |
| `adopted_paths` | Archive/evidence paths for already adopted fragments. |
| `renderer_required` | Whether an executor must render a final runtime file. |

`native-include` means the app can load managed/local/custom fragments itself, so `configctl` mostly validates and adopts. `compose` means the app needs a renderer because it lacks usable include semantics for the desired layering model. `direct-managed` means the app remains Home Manager-owned only; no local/adopt workflow is promised.

### Init manifests

Files under `init/` describe initial mutable state that may be created by an explicit `configctl init <tool>` flow.

Important constraints:

- Init is for first-run mutable tool state only.
- Init may create directories and empty files with safe permissions.
- Init must not run arbitrary commands in v1.
- Init must not fetch network resources.
- Init must not prune or rewrite existing user content unless the manifest explicitly marks the action as non-destructive and the executor confirms it.

## Current coverage

| Tool | Manifest | Strategy | Runtime status |
| --- | --- | --- | --- |
| Hyprland | `apps/hypr.toml` | native include | active |
| Zsh | `apps/zsh.toml` | native include | active |
| Hyprpaper | `apps/hyprpaper.toml` | compose | manifest only |
| Mako | `apps/mako.toml` | compose | manifest only |
| Eww | `apps/eww.toml` | compose | manifest only |
| Waybar | `apps/waybar.toml` | compose | manifest only |
| Variety | `init/variety.toml` | init | Home Manager currently performs equivalent setup; this manifest documents the future explicit boundary |

## Non-goals

- No `configctl` executable implementation in this repository.
- No npm global package management.
- No network-backed init.
- No automatic promotion, pruning, or garbage collection.
- No public mdBook generation.
