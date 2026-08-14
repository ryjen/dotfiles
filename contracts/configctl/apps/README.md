# App contracts

Application contracts describe config ownership, layering, adoption, and composition policy consumed by Dubnium `configctl` workflows.

Managed music coverage:

- `mpd.toml`: active native-include layering; Home Manager owns the generated root config while configctl owns local/custom overrides.
- `rmpc.toml`: planned RON composition; configctl is the target runtime owner after renderer support lands.
- `beets.toml`: planned YAML adoption/composition from the existing user-owned config; configctl is the target runtime owner and writes remain disabled until safe composition is implemented.

A planned compose contract may retain `current_runtime_owner = "user"` when adopting pre-existing user configuration. Such contracts must remain write-disabled until review-gated adoption and a parser-aware renderer are available.
