# Hermes custom YAML layers

This directory is the repository-side home for Hermes configuration fragments promoted through `configctl`.

Live user-authored fragments use:

```text
~/.config/hermes/custom.d/*.yaml
```

Machine-local overrides belong in `~/.config/hermes/local.yaml` and must not be promoted. The Hermes app contract remains write-disabled until parser-aware YAML composition is available in configctl.
