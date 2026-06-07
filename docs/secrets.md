# Secrets

Default policy: do not put real secrets in this repository.

Machine installs should keep private values in local overlays, local shell
fragments, password-store, or host-specific environment injection. The repo may
carry secret plumbing, example key names, and documentation, but not live
tokens.

## Local-First Handling

Use local files for installation-specific secrets:

- `~/.config/zsh/local.zsh`
- unmanaged files under `~/.config/zsh/config.d/`
- local Home Manager overlays outside the tracked repo
- `pass` / `~/.password-store`
- service-specific credential stores

These files are machine state. They should not be copied into `files/home/` or
committed.

## Optional Repo-Managed Secrets

The repo has optional `sops-nix` support for secrets that must be reproducible
through Home Manager.

It is disabled unless `secrets.yaml` exists:

```nix
imports = [
  # shared modules
] ++ lib.optional (builtins.pathExists ../../secrets.yaml) ./secrets.nix;
```

If needed:

```bash
cp secrets.yaml.example secrets.yaml
sops secrets.yaml
```

Keep `secrets.yaml` encrypted before committing. Never commit plaintext secret
files.

Current encrypted key shape is intentionally small:

- `github_token`
- `openai_api_key`
- `anthropic_api_key`

Add more only when a repo-managed workflow actually needs them.

## GPG Private Keys

Do not sync `~/.gnupg` with Syncthing and do not place a GPG private key in
`secrets.yaml`. The GnuPG home contains private key material, trust database
state, sockets, and permission-sensitive files that are not safe as ordinary
synced dotfiles. A private key encrypted by the same key also creates a
bootstrap loop on a fresh host.

If a GPG private key needs to be recoverable across machines, store an
encrypted export artifact, not the live GnuPG home. Prefer exporting secret
subkeys instead of the primary key:

```bash
gpg --armor --export-secret-subkeys KEY_FINGERPRINT > /tmp/gpg-secret-subkeys.asc
```

Encrypt that exported file with `sops` using a non-circular recipient, such as
an `age` identity or a separate offline recovery key, then sync or commit only
the encrypted artifact:

```bash
mkdir -p secrets
sops --encrypt --input-type binary --output-type yaml \
  /tmp/gpg-secret-subkeys.asc > secrets/gpg-secret-subkeys.asc.sops.yaml
```

On a new host, decrypt only long enough to import:

```bash
sops --decrypt --input-type yaml --output-type binary \
  secrets/gpg-secret-subkeys.asc.sops.yaml | gpg --import
```

After import, inspect the key, set ownertrust if needed, and remove any
temporary plaintext export:

```bash
gpg --list-secret-keys --keyid-format LONG
rm /tmp/gpg-secret-subkeys.asc
```

Home Manager may manage GPG configuration and `gpg-agent`, but private key
import remains an explicit operator action.

## Zsh Runtime

When `secrets.yaml` exists, `modules/home/secrets.nix` writes a managed zsh
fragment:

```text
~/.config/zsh/config.d/10-user-runtime-secrets.zsh
```

That fragment sources the decrypted sops template and exports runtime variables
for tools that require environment variables.

For local-only installs, prefer `~/.config/zsh/local.zsh` or another unmanaged
local file instead.

## What Not To Adopt

Do not move these into tracked zsh config:

- API tokens
- cloud credentials
- registry tokens
- OAuth client secrets
- personal access tokens
- private endpoint credentials
- GPG private keys or `~/.gnupg`

Non-secret shell behavior may be adopted separately, such as PATH additions,
aliases, completions, and helper functions.

## New Host Rule

New hosts should work without repo-managed secrets. If a host needs credentials,
add them locally first. Promote a secret into encrypted `sops-nix` only when the
same secret contract must be shared across machines or automated builds.

## Rotation

If a token has ever lived in plaintext under a tracked repo or a copied shell
fragment, rotate it before relying on the new setup.
