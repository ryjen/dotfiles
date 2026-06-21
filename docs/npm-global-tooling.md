# npm global tooling

Dotfiles owns the stable npm global environment:

- a user-writable npm prefix
- the npm global bin PATH entry
- a repo-managed package manifest

Mutable package installation is explicit user state. It is not run by Home Manager activation.

## Managed files

Home Manager writes:

```text
~/.npmrc
~/.config/npm/global-packages.txt
```

The default prefix is:

```text
~/.local/share/npm
```

The default global bin path is:

```text
~/.local/share/npm/bin
```

## Existing `.npmrc` migration

Before enabling this module on a machine with existing npm state, inspect any current `~/.npmrc`:

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

## Package manifest

Durable npm global tools are declared in:

```text
files/home/.config/npm/global-packages.txt
```

The manifest supports blank lines and `#` comments.

Codex is npm-owned in this repository, so the manifest declares:

```text
@openai/codex
```

Do not add npm authentication, registry credentials, or machine-local settings to managed files.

## Experimental package flow

Ad-hoc installs are allowed for experimentation:

```sh
npm install -g some-tool
```

That package remains local-only drift until it is intentionally promoted.

Once Dubnium `configctl init` support is available, inspect npm global drift with:

```sh
configctl init status npm-globals
```

Expected categories:

- declared and installed
- declared but missing
- installed but undeclared

## Promoting a package

To make an experimental package durable:

1. Verify npm is the canonical or preferred upstream.
2. Check for binary-name conflicts with Nix packages.
3. Add the package spec to `files/home/.config/npm/global-packages.txt`.
4. Commit the manifest change.
5. Reconcile with `configctl init` once available.

```sh
configctl init plan npm-globals
configctl init apply npm-globals --allow network,mutable-user-state
configctl init verify npm-globals
```

Normal apply should not prune undeclared packages.

## Inspection and repair

```sh
npm config get prefix
printf '%s\n' "$PATH" | tr ':' '\n' | grep "$HOME/.local/share/npm/bin"
mkdir -p "$HOME/.local/share/npm/bin"
npm install -g @openai/codex
hash -r
command -v codex
```

Avoid `sudo npm install -g`. The configured prefix is user-writable by design.
