# Codex config layers

Codex runtime configuration is canonically reconciled by `configctl` from this layered TOML source tree.

```text
~/.config/codex/
├── adopted.d/*.toml   # dotfiles-managed fragments adopted from previous runtime config
├── custom.d/*.toml    # promoted custom fragments
└── local.toml         # machine-local overrides, not managed here
```

The generated runtime output is:

```text
~/.codex/config.toml
```

Home Manager installs only the source layers and init contract. Runtime composition is owned by `configctl`.

Until Home Manager is wired to call `configctl` directly, generate the runtime file with:

```text
configctl init apply codex-config --allow mutable-user-state --yes
```

`configctl` composes layers in this order:

1. `~/.config/codex/adopted.d/*.toml`, lexically sorted
2. `~/.config/codex/custom.d/*.toml`, lexically sorted
3. `~/.config/codex/local.toml`, when present

`local.toml` is intentionally not installed by Home Manager. It is local mutable state and may be created by `configctl adopt codex` or by the user.

The runtime file should be a normal user-writable file, not a symlink into the Nix store. This preserves the ability for Codex and `configctl` to update mutable state such as project trust.

Do not manage `~/.codex/config.toml` directly with `home.file`.
