# npm global tooling

This repo manages npm global tooling through the Home Manager user layer.

## Design

- npm global prefix: `$HOME/.local/share/npm`
- npm global bin path: `$HOME/.local/share/npm/bin`
- managed npm config: `~/.npmrc`
- package declaration: `~/.config/npm/global-packages.txt`
- sync command: `npm-globals-sync`

The sync command is intentionally manual. Home Manager activation creates the prefix directory and manages config, but it does not perform network-mutating npm installs during every activation.

## Adding a package

Edit:

```text
files/home/.config/npm/global-packages.txt
```

Entries may be plain package names or pinned versions:

```text
some-tool
some-tool@1.2.3
```

Blank lines and comments are ignored.

## Syncing packages

After applying Home Manager:

```bash
npm-globals-sync
```

Dry-run the parser:

```bash
npm-globals-sync --dry-run
```

## Codex ownership

Codex is npm-owned in this repo. The expected package declaration is:

```text
@openai/codex
```

`pkgs.codex` should not be installed by the agent module at the same time unless ownership is intentionally moved back to Nix.

## Verification

```bash
npm config get prefix
command -v codex
codex --version
```

Expected prefix:

```text
$HOME/.local/share/npm
```

Expected Codex path should resolve below:

```text
$HOME/.local/share/npm/bin
```

## Repair

Do not use `sudo npm install -g`. Repair the user prefix instead:

```bash
npm config set prefix "$HOME/.local/share/npm"
mkdir -p "$HOME/.local/share/npm/bin"
npm-globals-sync
hash -r
command -v codex
```

## Secrets

Do not commit npm auth tokens. Keep registry credentials in local machine/user config, `npm login` state, or an environment-backed secret flow.
