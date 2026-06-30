# Configctl Manifest Contracts

This directory is the dotfiles-owned contract surface consumed by Dubnium's `configctl` executor.

The manifests are declarative policy. They describe what this repository owns, which user paths are intentionally local-only, and which files or mutable user-state workflows may be adopted, validated, planned, or initialized by explicit tooling. They do not include shell hooks, secrets, implicit Home Manager mutation, or automatic package installation.

## Contract roots

```text
contracts/configctl/
├── apps/       # per-application config ownership and composition contracts
├── init/       # explicit first-run mutable state contracts
└── schema-v1.md
```

Home Manager materializes init contracts to:

```text
$XDG_CONFIG_HOME/configctl/init.d/*.toml
```

This matches the Dubnium `configctl init` discovery path.

## Rules

- Dotfiles owns manifests for user-owned app configuration and user-layer initial-state contracts.
- Dubnium owns executor implementation, contract parsing, risk gates, diagnostics, apply behavior, and runtime state.
- Home Manager may create deterministic source/generated files, package manifests, PATH entries, and safe directories.
- Home Manager must not run network-backed installs during activation.
- Home Manager must not create or overwrite `local.*` escape hatches.
- `local.*` paths are never promotion candidates.
- `custom.d/*` paths are promotion candidates only through an explicit adopt workflow.
- `adopted.d/*` paths are archive/evidence paths, ignored during normal runtime unless a manifest says otherwise.
- Hashes are evidence for review and reconciliation. They are not authority to silently rewrite or delete user files.
- V1 manifests must not include arbitrary shell hooks.
- Secrets, tokens, session files, caches, and generated runtime state do not belong in repo-managed contracts.

## Optimized path model

App manifests define path roles once under `[layout]`.

Common roles:

| Role | Meaning |
| --- | --- |
| `source_inputs` | Repo-owned modules, fragments, or static source files used to produce runtime configuration. |
| `runtime_outputs` | Final runtime files the app reads; currently Home Manager-owned unless the manifest says otherwise. |
| `local` | Machine-local files that must not be overwritten or promoted. |
| `custom` | User-authored promotion candidates. |
| `adopted` | Archive/evidence paths for already adopted fragments. |
| `runtime_includes` | Files loaded directly by tools with native include support. |
| `auxiliary_outputs` | Runtime helper files that are not composition outputs. |

Behavior sections refer to roles, not duplicated path globs. For example, adoption ignores `local` and `adopted` roles instead of repeating every path.

## Lifecycle fields

Every app/init manifest must declare whether it describes current behavior or a planned migration:

| Field | Meaning |
| --- | --- |
| `status` | `active` or `planned`. |
| `current_runtime_owner` | Current writer of runtime outputs or mutable state, usually `home-manager` today. |
| `target_runtime_owner` | Intended future writer after migration. |
| `executor_may_validate` | Whether `configctl` may validate the contract now. |
| `executor_may_adopt` | Whether `configctl` may use the adoption policy now. |
| `executor_may_initialize` | Whether `configctl` may initialize mutable user state now. |
| `executor_may_write_outputs` | Whether `configctl` may write runtime outputs now. |

Planned compose manifests are intentionally not write-enabled while Home Manager still owns the runtime files.

## Manifest semantics

### App manifests

Files under `apps/` describe application configuration that dotfiles owns or exposes to `configctl`.

`native-include` means the app can load local/custom fragments itself, so `configctl` mostly validates and adopts. `compose` means the app needs a renderer because it lacks usable include semantics for the desired layering model. `direct-managed` means the app remains Home Manager-owned only; no local/adopt workflow is promised.

### Init manifests

Files under `init/` describe initial mutable state that may be created by an explicit `configctl init apply <contract>` flow.

Important constraints:

- Init is for first-run or repairable mutable user state only.
- Init may fetch or mutate only when the contract declares the required risks and the executor receives explicit approval.
- Init must not use arbitrary shell hooks.
- Init must not run from Home Manager activation.
- Init must not prune or rewrite existing user content unless a future contract and command explicitly mark the action as destructive and the executor confirms it.

## Current coverage

| Tool | Manifest | Strategy | Status | Current owner | Target owner |
| --- | --- | --- | --- | --- | --- |
| Hyprland | `apps/hypr.toml` | native include | active | Home Manager | Home Manager |
| Zsh | `apps/zsh.toml` | native include | active | Home Manager | Home Manager |
| Hyprpaper | `apps/hyprpaper.toml` | compose | planned | Home Manager | configctl |
| Mako | `apps/mako.toml` | compose | planned | Home Manager | configctl |
| Eww | `apps/eww.toml` | compose | planned | Home Manager | configctl |
| Waybar | `apps/waybar.toml` | compose | planned | Home Manager | configctl |
| npm globals | `init/npm-globals.toml` | init | active | explicit user state | configctl init |
| Variety | `init/variety.toml` | init | planned | Home Manager activation | configctl init |
| Multi-agent worktrees skill | `init/multi-agent-worktrees.toml` | init | active, validate-only | dotfiles/manual copy | configctl init |

## Verification

Run the repo-side verifier directly:

```sh
nix run .#verify-configctl-contracts
```

Or as part of flake checks:

```sh
nix flake check --no-build
```

The verifier checks that init contracts are valid TOML, use supported risk labels, have unique IDs, and that enabled contracts have dotfiles-side validation rules. For `npm-globals`, it also verifies that the contract paths match the Home Manager npm prefix and that the referenced package manifest exists.

## Non-goals

- No `configctl` executable implementation in this repository.
- No automatic npm global package management from Home Manager activation.
- No implicit network-backed init.
- No automatic promotion, pruning, or garbage collection.
- No public mdBook generation.
