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

The managed provider layer keeps Hermes pointed at stable provider boundaries:

- `nous-cloud`: default cloud provider.
- `local`: local OpenAI-compatible Dubnium LLM service at `http://127.0.0.1:8000/v1` using model alias `dubnium-local`.

Backend-specific local runtimes such as vLLM, llama.cpp, or Ollama stay behind the local service boundary.
