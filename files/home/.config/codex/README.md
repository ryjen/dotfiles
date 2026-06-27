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

Home Manager bootstraps `~/.codex/config.toml` during activation so Codex works immediately after flows such as:

```text
home-manager switch --flake .#USERNAME@nixos
```

The activation bootstrap mirrors the `configctl` composition order:

1. `~/.config/codex/adopted.d/*.toml`, lexically sorted
2. `~/.config/codex/custom.d/*.toml`, lexically sorted
3. `~/.config/codex/local.toml`, when present

`local.toml` is intentionally not installed by Home Manager. It is local mutable state and may be created by `configctl adopt codex` or by the user.

The runtime file is written as a normal user-writable file, not as a symlink into the Nix store. This preserves the ability for Codex and `configctl` to update mutable state such as project trust.

Do not manage `~/.codex/config.toml` directly with `home.file`. `configctl` remains the canonical reconciliation path; Home Manager only bootstraps the runtime file so Codex has managed defaults immediately after activation.
