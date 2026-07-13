# Bitwarden clients

The Dubnium workstation profile installs both the Bitwarden desktop application and the `bw` CLI. Each can be overridden independently in `home/ryjen/user.local.nix`:

```nix
dotfiles.bitwarden.cli.enable = true;
dotfiles.bitwarden.desktop.enable = true;
```

## Connect to Vaultwarden

After the Vaultwarden service is deployed, configure the CLI with its HTTPS URL:

```sh
bw config server https://<vaultwarden-host>
bw login
```

For the desktop application, select **Self-hosted** on the login screen and enter the same server URL.

Do not commit credentials, vault exports, API keys, or `BW_SESSION` values. Prefer a short-lived shell session:

```sh
export BW_SESSION="$(bw unlock --raw)"
# use bw commands
bw lock
unset BW_SESSION
```

Avoid placing `BW_SESSION` in shell startup files, tracked environment files, command wrappers, or the Nix store.

The Firefox profile already installs the Bitwarden browser extension through managed browser policy. Configure its self-hosted server URL separately from the desktop and CLI clients.
