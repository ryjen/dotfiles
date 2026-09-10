# Hermes configctl ownership

Hermes configuration is governed through the configctl ownership model.

Source root:

```text
~/.config/hermes/
├── base.yaml
├── local.yaml
├── custom.d/*.yaml
└── adopted.d/*.yaml
```

Runtime output:

```text
~/.hermes/config.yaml
```

Ownership rules:

- `base.yaml` is the stable dotfiles-owned base.
- `local.yaml` is machine-local and must not be promoted or overwritten.
- `custom.d/*.yaml` contains user-authored promotion candidates.
- `adopted.d/*.yaml` contains adopted/archive evidence and is not part of normal composition.

The app contract is `contracts/configctl/apps/hermes.toml`. It is intentionally `planned` and write-disabled until Dubnium configctl has parser-aware YAML composition. Until then, the native runtime output `~/.hermes/config.yaml` is **user-managed**: Home Manager publishes only the read-only base layer (`base.yaml` under `~/.config/hermes`) and never writes the runtime output, so the live provider/model settings in `~/.hermes/config.yaml` are not clobbered by activation. The source base is not a complete runtime config — do not copy it over the runtime file.

The init contract is layout-only:

```bash
configctl init plan hermes
configctl init apply hermes --allow mutable-user-state --yes
configctl init verify hermes
```

Normal layer workflows use:

```bash
configctl status hermes
configctl adopt hermes
configctl promote hermes <fragment.yaml>
configctl reconcile hermes
```
