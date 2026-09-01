# App contracts

Application contracts describe config ownership, layering, adoption, promoted-layer materialization, and composition policy consumed by Dubnium `configctl` workflows.

## Promoted-layer ownership

The app policy `profile` is an **activation selector**. It is not the machine namespace used by `configctl promote`. The machine profile is resolved separately (`dubnium`, `technetium`, etc.) and reviewed fragments remain under that namespace.

Every app contract declares `[materialization].promoted`:

| Owner | Meaning |
| --- | --- |
| `home-manager` | Home Manager projects reviewed machine-profile fragments into the runtime tree and the native app consumes them. |
| `direct-render` | The configctl renderer consumes reviewed repo fragments directly; no runtime projection copy is created. |
| `configctl-sync` | Reserved for a future explicit configctl-owned projection boundary. No current app uses it. |
| `none` | Promoted projection is not applicable. |

Current classification:

- Home Manager: `git`, `hypr`, `mpd`, `task`, `zsh`.
- Direct render: `beets`, `eww`, `hermes`, `hyprpaper`, `mako`, `rmpc`, `waybar`.
- Configctl sync: none.

Home Manager-owned native-include apps preserve the runtime precedence:

```text
reviewed promoted machine-profile layer
    < live root custom promotion candidates
    < machine-local override
```

A Home Manager projection contract declares both `runtime_projection` and `runtime_consumption`. This prevents a reviewed profile directory from being materialized but never loaded by the application.

Broad activation selectors such as `all` and `workstation` must not be substituted into promoted repo paths. Explicit `layout.promoted_inputs` are permitted only for concrete machine-scoped contracts; otherwise configctl derives the promoted path from `layout.custom` plus the active machine profile.

Managed music coverage:

- `mpd.toml`: active native-include layering; Home Manager owns the generated root config and projects the machine-profile promoted layer.
- `rmpc.toml`: planned RON composition; configctl is the target runtime owner after renderer support lands, and reviewed promoted fragments are direct-render inputs.
- `beets.toml`: planned YAML adoption/composition from the existing user-owned config; configctl is the target runtime owner and writes remain disabled until safe composition is implemented.

A planned compose contract may retain `current_runtime_owner = "user"` when adopting pre-existing user configuration. Such contracts must remain write-disabled until review-gated adoption and a parser-aware renderer are available.

See `../schema-v1.md` and [ryjen/dubnium#858](https://github.com/ryjen/dubnium/issues/858) for the cross-repo reconciliation contract.
