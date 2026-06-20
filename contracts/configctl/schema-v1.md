# Configctl Manifest Schema v1

This schema documents the declarative contract format under `contracts/configctl/`.

The schema is intentionally small. It avoids duplicated path lists by defining path roles once in `[layout]` and referencing those roles from behavior sections.

## App manifest

Required top-level fields:

| Field | Allowed values | Notes |
| --- | --- | --- |
| `schema_version` | `1` | Integer schema version. |
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
| `managed_sources` | Repo or Home Manager-owned source inputs. |
| `runtime_outputs` | Final files the app reads. |
| `local` | Local-only unmanaged paths. |
| `custom` | User-authored promotion candidates. |
| `adopted` | Archive/evidence paths. |
| `runtime_includes` | Paths directly loaded by apps with native include support. |

All path role fields use arrays, even when they contain one item.

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

## Init manifest

Required top-level fields:

| Field | Allowed values | Notes |
| --- | --- | --- |
| `schema_version` | `1` | Integer schema version. |
| `tool` | string | Stable tool identifier. |
| `owner` | `dotfiles` | Policy owner. |
| `profile` | string | Profile that activates the contract. |
| `kind` | `initial-mutable-state` | Init contract kind. |
| `status` | `active`, `planned` | Whether executor ownership is current. |
| `current_runtime_owner` | string | Current owner of the mutable state behavior. |
| `target_runtime_owner` | string | Target owner after migration. |
| `executor_may_validate` | boolean | Whether validation is allowed now. |
| `executor_may_initialize` | boolean | Whether init mutation is allowed now. |

Required safety flags:

| Field | Required value for v1 |
| --- | --- |
| `network` | `false` |
| `arbitrary_commands` | `false` |
| `destructive` | `false` |
| `dry_run_required` | `true` |

Init manifests may contain `directories`, `files`, and `settings` arrays. Those entries must be declarative and non-destructive.
