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

## Verification

Run repo-side contract validation after editing init contracts or package manifests:

```sh
nix run .#verify-configctl-contracts
nix build .#checks.x86_64-linux.configctl-contracts
```
