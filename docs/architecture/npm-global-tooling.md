# npm global tooling architecture

## Decision

npm global tooling is managed in the Home Manager user layer, not NixOS system activation.

The default prefix is:

```text
$HOME/.local/share/npm
```

The default global bin path is:

```text
$HOME/.local/share/npm/bin
```

## Rationale

Npm global tools are mutable and registry-backed. Running global installs from NixOS activation would create root-owned state and make rebuilds dependent on network availability.

Home Manager should own:

- the npm prefix config
- session PATH integration
- the package declaration file
- the sync command

The user should explicitly run the network-mutating sync step.

## Codex ownership

Codex is npm-owned for this workflow.

That means:

- `@openai/codex` is declared in `files/home/.config/npm/global-packages.txt`.
- `pkgs.codex` is not installed by `modules/home/agents.nix`.
- `$HOME/.local/share/npm/bin` should win for `command -v codex`.

## Non-goals

- No npm auth tokens are committed.
- No `sudo npm install -g` workflow is supported.
- No npm registry writes occur during normal Home Manager activation.
