# Hermes provider config layers

This directory contains source layers for the configctl-owned Hermes provider config.

Runtime output:

```text
~/.hermes/config.toml
```

Layer order:

1. `adopted.d/*.toml`
2. `custom.d/*.toml`
3. `local.toml`

`configctl` also applies the active Dubnium mode when rendering `providers.vllm-qwen.model`:

- desktop: `Qwen/Qwen2.5-7B-Instruct-1M`
- compute: `/var/lib/dubnium/models/Qwen3-14B`
