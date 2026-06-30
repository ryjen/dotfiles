# Configctl Manifest Schema v1

This schema documents the declarative contract format under `contracts/configctl/`.

Dotfiles owns contract source files and static package manifests. Dubnium `configctl` owns contract discovery, runtime validation, planning, apply behavior, risk gating, and state files.

## Discovery

Init contracts are materialized by Home Manager to:

```text
$XDG_CONFIG_HOME/configctl/init.d/*.toml
```

Default path:

```text
~/.config/configctl/init.d/*.toml
```

Runtime state belongs to Dubnium `configctl` under:

```text
$XDG_STATE_HOME/configctl/init/<id>/state.json
```

Default path:

```text
~/.local/state/configctl/init/<id>/state.json
```

## Init manifest

Required top-level fields:

| Field | Allowed values | Notes |
| --- | --- | --- |
| `schemaVersion` | `1` | Integer schema version. |
| `id` | string | Stable unique contract ID. |
| `kind` | string | Typed handler name, for example `npm-globals`. |
| `enabled` | boolean | Whether the contract participates in normal operations. |
| `risk` | array of strings | Risks that must be explicitly approved for mutating operations. |

Optional top-level fields:

| Field | Notes |
| --- | --- |
| `description` | Human-readable purpose. |
| `tags` | Optional grouping or filter labels. |
| `profile` | Optional profile selector, for example `dubnium` or `workstation`. |
| `dependsOn` | Other contract IDs that should be applied first. |

Supported risk labels:

| Risk | Meaning |
| --- | --- |
| `network` | May fetch from a remote registry or service. |
| `mutable-user-state` | Mutates files outside the Nix store in `$HOME`. |
| `auth-required` | May require an existing login, token, or local session. |
| `destructive` | May delete or prune state. |
| `arbitrary-code` | Executes contract-provided shell or code. |
| `privileged` | Requires elevated privileges. Avoid for user-layer contracts. |

V1 dotfiles init contracts must not contain arbitrary shell hooks, auth tokens, private registry credentials, session files, caches, or generated runtime state.

## Environment expansion

Path fields may use only variables supported by Dubnium `configctl`:

```text
$HOME
$XDG_CONFIG_HOME
$XDG_STATE_HOME
$XDG_DATA_HOME
$XDG_CACHE_HOME
```

Rules:

- Expansion is performed by `configctl`, not the shell.
- Unknown variables are errors.
- `~` expands to `$HOME`.
- No command substitution.
- No shell glob expansion.

Prefer `$HOME` for paths that must match Home Manager defaults exactly.

## `npm-globals` init contract

`npm-globals` declares user-layer npm global tools managed by an explicit `configctl init apply` operation.

Required fields:

| Field | Type | Notes |
| --- | --- | --- |
| `manifest` | path string | Package manifest path. |
| `prefix` | path string | Expected npm global prefix. |
| `bin` | path string | Expected npm global bin path. |

Required risks:

```toml
risk = ["network", "mutable-user-state"]
```

Required state tracking:

```toml
[state]
trackDesiredHash = true
trackObservedHash = true
```

Required default behavior:

```toml
[behavior]
install = true
update = false
prune = false
```

Normal apply must not prune undeclared packages. Any future destructive cleanup must use a separate destructive command and require explicit destructive risk approval.

Example:

```toml
schemaVersion = 1
id = "npm-globals"
kind = "npm-globals"
description = "Install npm globals declared by dotfiles"
enabled = true
risk = ["network", "mutable-user-state"]
tags = ["npm", "codex", "workstation"]

manifest = "$HOME/.config/npm/global-packages.txt"
prefix = "$HOME/.local/share/npm"
bin = "$HOME/.local/share/npm/bin"

[state]
trackDesiredHash = true
trackObservedHash = true

[behavior]
install = true
update = false
prune = false
```

## App manifest

App manifests are a dotfiles-side ownership and composition policy surface for `configctl adopt`, `status`, `doctor`, `promote`, and future compose workflows.

Required top-level fields:

| Field | Allowed values | Notes |
| --- | --- | --- |
| `schema_version` | `1` | Integer schema version for app manifests. |
| `tool` | string | Stable tool identifier. |
| `owner` | `dotfiles` | Policy owner for this repository. |
| `profile` | string | Profile that activates the contract. |
| `status` | `active`, `planned` | Whether the contract describes current executor behavior. |
| `strategy` | `native-include`, `compose`, `direct-managed` | Runtime configuration strategy. |
| `current_runtime_owner` | string | Current writer of runtime outputs. |
| `target_runtime_owner` | string | Desired writer after migration. |
| `executor_may_validate` | boolean | Whether validation is allowed now. |
| `executor_may_adopt` | boolean | Whether adoption is allowed now. |
| `executor_may_write_outputs` | boolean | Whether writing runtime outputs is allowed now. |

Optional top-level fields:

| Field | Notes |
| --- | --- |
| `renderer_required` | Boolean marker for `compose` contracts. |
| `description` | Human-readable purpose. |

## Path layout

`[layout]` defines path roles once.

Common fields:

| Field | Meaning |
| --- | --- |
| `root` | Runtime config directory for the tool. |
| `standard` | Layout convention identifier, usually `configctl-v1`. |
| `source_inputs` | Repo-owned modules, fragments, or static source files used to produce runtime configuration. |
| `runtime_outputs` | Final files the app reads. |
| `local` | Local-only unmanaged paths. |
| `custom` | User-authored promotion candidates. |
| `adopted` | Archive/evidence paths. |
| `runtime_includes` | Paths directly loaded by apps with native include support. |
| `auxiliary_outputs` | Runtime helper files that are not composition outputs. |

All path role fields use arrays, even when they contain one item.

`source_inputs` must describe source-of-truth inputs, not generated runtime outputs. Runtime outputs belong under `runtime_outputs` or `auxiliary_outputs`.

## Composition

`[composition]` is required when `strategy = "compose"`.

| Field | Meaning |
| --- | --- |
| `source_order` | Ordered layout role names used as composition inputs. |
| `output_role` | Layout role name for rendered outputs. |
| `write_mode` | Output write mode, currently `atomic`. |
| `dry_run_required` | Must be true before output writing is enabled. |
| `requires_parser` | Optional parser requirements such as `jsonc` or `css`. |

Planned compose contracts must set:

```toml
status = "planned"
current_runtime_owner = "home-manager"
target_runtime_owner = "configctl"
executor_may_write_outputs = false
```

## Adoption

`[adoption]` is required when `executor_may_adopt = true`.

| Field | Meaning |
| --- | --- |
| `state_path` | XDG state path for adoption metadata. |
| `hash_algorithm` | Hash algorithm, currently `sha256`. |
| `mode` | Adoption mode, currently `review-gated`. |
| `ignore` | Layout role names to ignore during adoption/reconciliation. |

`ignore` must reference layout roles, not raw paths.

## Validation

`[validation]` may add role-level checks.

| Field | Meaning |
| --- | --- |
| `must_not_manage` | Layout roles that Home Manager or configctl must not own as generated files. |
| `must_exist_or_be_creatable` | Layout roles whose parent directories may be created safely. |
