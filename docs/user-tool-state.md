# User tool state

Dotfiles owns stable user environment declarations. Mutable first-run state, package installation, and observed local drift are reconciled explicitly by user-triggered tooling such as `configctl init`.

Core boundary:

```text
Home Manager declares stable user environment state.
configctl init reconciles mutable user tool state.
```

## Ownership model

Home Manager should own:

- stable config files
- non-secret package manifests
- PATH entries
- durable profile/module enablement
- directories needed for declared user tooling
- contract manifests under `$XDG_CONFIG_HOME/configctl/init.d/`

Home Manager should not own:

- network-backed package install/update execution during activation
- auth tokens or private registry credentials
- session files, caches, or generated runtime state
- automatic promotion of local experiments
- pruning of undeclared mutable state

## Durable manifests

Tool manifests live in repo-managed paths under `files/home/` and are materialized by Home Manager.

Examples:

- npm globals: `files/home/.config/npm/global-packages.txt`
- pip globals: `files/home/.config/pip/global-packages.txt`
- uv tools: `files/home/.config/uv/tools.toml`

Manifests describe desired durable tools. They do not imply that Home Manager should run network-backed installation during activation.

## Configctl init contracts

Dotfiles-owned init contracts live under:

```text
contracts/configctl/init/*.toml
```

Home Manager materializes them to the Dubnium discovery path:

```text
~/.config/configctl/init.d/*.toml
```

`configctl` owns runtime parsing, risk gates, planning, application, verification, and state under `$XDG_STATE_HOME`.

## Tool lanes

User-installed tooling is split by package ecosystem and isolation requirement:

| Lane | Use for | Isolation |
| --- | --- | --- |
| `npm-globals` | npm-owned CLI tools | npm global prefix |
| `pip-globals` | small Python library/helper packages | shared pip prefix |
| `uv-tools` | Python CLI applications with larger dependency graphs | isolated uv tool environments |

A package should move to `uv-tools` when it behaves like an application rather than a lightweight helper package. Examples include Aider and Headroom.

## Local experiments and promotion

Users may install or configure tools manually while experimenting. Those changes are local-only drift until intentionally promoted.

Generic workflow:

1. Install or configure experimentally.
2. Inspect status with `configctl` when supported.
3. Decide whether the tool/config belongs in durable dotfiles state.
4. Add durable state to the appropriate manifest or config fragment.
5. Commit the dotfiles change.
6. Reconcile mutable state with `configctl init` when supported.

Do not automatically promote observed local state into dotfiles.

## Secrets and credentials

Do not commit tokens, private registry credentials, local sessions, auth files, or machine-local secrets.

Managed files may declare public defaults such as a package prefix or manifest path. Credentials belong in local/private mechanisms outside the shared dotfiles source.

## npm globals

Dotfiles owns the stable npm global environment:

- a user-writable npm prefix
- the npm global bin PATH entry
- a repo-managed package manifest
- a `configctl init` contract describing explicit mutable reconciliation

Mutable npm package installation is explicit user state. It is not run by Home Manager activation.

### Managed npm files

Home Manager writes:

```text
~/.npmrc
~/.config/npm/global-packages.txt
~/.config/configctl/init.d/npm-globals.toml
```

The default prefix is:

```text
~/.local/share/npm
```

The default global bin path is:

```text
~/.local/share/npm/bin
```

### Existing `.npmrc` migration

Before enabling the npm module on a machine with existing npm state, inspect any current `~/.npmrc`:

```sh
test -f ~/.npmrc && sed -n '1,120p' ~/.npmrc
```

Move npm authentication tokens, private registry settings, or machine-local options out of the managed file before running Home Manager.

If Home Manager refuses to activate because `~/.npmrc` already exists, back it up first:

```sh
mv ~/.npmrc ~/.npmrc.local-backup
home-manager switch --flake .#USERNAME@nixos
```

Then re-apply only non-secret local npm settings through an explicit local/private mechanism. Do not commit auth tokens or private registry credentials.

### npm package manifest

Durable npm global tools are declared in:

```text
files/home/.config/npm/global-packages.txt
```

The manifest supports blank lines and `#` comments.

Current durable npm globals include Codex and other npm-owned CLI tools:

```text
@openai/codex
@bitwarden/cli
@tobilu/qmd
opencode-ai
```

Do not add npm authentication, registry credentials, or machine-local settings to managed files.

### npm experimental package flow

Ad-hoc installs are allowed for experimentation:

```sh
npm install -g some-tool
```

That package remains local-only drift until it is intentionally promoted.

Inspect npm global drift with:

```sh
configctl init status npm-globals
```

Expected categories:

- declared and installed
- declared but missing
- installed but undeclared

### Promoting an npm package

To make an experimental package durable:

1. Verify npm is the canonical or preferred upstream.
2. Check for binary-name conflicts with Nix packages.
3. Add the package spec to `files/home/.config/npm/global-packages.txt`.
4. Commit the manifest change.
5. Reconcile with `configctl init`.

```sh
configctl init plan npm-globals
configctl init apply npm-globals --allow network,mutable-user-state --yes
configctl init verify npm-globals
```

Normal apply should not prune undeclared packages.

### npm inspection and repair

```sh
npm config get prefix
printf '%s\n' "$PATH" | tr ':' '\n' | grep "$HOME/.local/share/npm/bin"
mkdir -p "$HOME/.local/share/npm/bin"
npm install -g @openai/codex
hash -r
command -v codex
```

Avoid `sudo npm install -g`. The configured prefix is user-writable by design.

## pip globals

`pip-globals` is for small Python packages and helper libraries that are acceptable in a shared user prefix.

Current durable pip globals are declared in:

```text
files/home/.config/pip/global-packages.txt
```

Python CLI applications with larger dependency graphs should not be added here. Prefer `uv-tools` so their dependencies remain isolated.

## uv tools

`uv-tools` is for Python CLI applications installed into isolated uv-managed environments while exposing executables through `~/.local/bin`.

Home Manager writes:

```text
~/.config/uv/tools.toml
~/.config/configctl/init.d/uv-tools.toml
```

Current durable uv tools include:

```text
aider-chat
headroom-ai[all]
rtk
```

Inspect and reconcile with:

```sh
configctl init plan uv-tools
configctl init apply uv-tools --allow network,mutable-user-state --yes
configctl init verify uv-tools
```

### Headroom wrapper support

Headroom is declared as an isolated uv tool, but wrapper mode also expects an `rtk` command on PATH. `rtk` is therefore declared in the uv tools manifest so `configctl init apply uv-tools` can expose it through `~/.local/bin`.

Manual checks:

```sh
command -v headroom
command -v rtk
headroom wrap --help
```

If `rtk` does not install cleanly through `uv-tools`, verify whether the upstream package name differs from the exposed command name before moving it to another lane or adding custom package handling.

Wrapper mode should be treated as more sensitive than a plain CLI tool because it may sit between local developer tools and model/provider calls. Do not commit wrapper traces, prompt caches, provider tokens, local logs, or generated proxy state.

## Verification

Run repo-side contract validation after editing init contracts or package manifests:

```sh
nix run .#verify-configctl-contracts
nix build .#checks.x86_64-linux.configctl-contracts
```
