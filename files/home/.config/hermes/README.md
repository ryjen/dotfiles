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

Managed providers:

- `nous-cloud`: default cloud provider.
- `local`: local OpenAI-compatible provider at `http://127.0.0.1:8000/v1` using model alias `dubnium-local`.
