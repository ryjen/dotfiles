# Codex configctl layering

Codex config follows the standard configctl source-layer shape:

```text
~/.config/codex/
├── local.conf
├── custom.d/
└── adopted.d/
```

`~/.codex/config.toml` is generated runtime output. It is intentionally not Home Manager-owned, because Codex may persist project trust and similar runtime state there.

The `codex-config` init contract is installed from `contracts/configctl/init/codex-config.toml` and is executed by Dubnium's `configctl` implementation.
