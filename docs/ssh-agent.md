# SSH agent session contract

Dotfiles treats SSH authentication as user-session infrastructure, not as a per-terminal or application-owned process.

## Ownership

On hosts with Home Manager user systemd support, the default is:

```nix
dotfiles.sshAgent.enable = true;
```

This enables Home Manager's `services.ssh-agent`, which creates `ssh-agent.service` for the user session. The service owns the canonical OpenSSH agent socket under `$XDG_RUNTIME_DIR`.

The default follows `dotfiles.host.userSystemd.enable`, so profiles such as WSL that do not provide the normal user-systemd contract do not incorrectly require the agent service.

Do not start a second agent from shell startup files with patterns such as:

```bash
eval "$(ssh-agent -s)"
```

The intended model is:

```text
login/user systemd
  -> ssh-agent.service
    -> session SSH_AUTH_SOCK
      -> shells and SSH/Git clients
      -> explicitly authorized sandbox consumers
```

## Alternate SSH-agent providers

Exactly one component should deliberately own the SSH-agent socket. If Bitwarden, 1Password, KeePassXC, a forwarded agent, or another trusted provider is selected as the agent implementation, disable the Home Manager OpenSSH agent explicitly:

```nix
dotfiles.sshAgent.enable = false;
```

Installing an alternate password-manager client alone does not make it the SSH-agent owner. Change the ownership only when that provider is deliberately configured to expose `SSH_AUTH_SOCK`.

## Shell and forwarded-agent behavior

Home Manager initializes interactive shells for its session agent while preserving an already valid `SSH_AUTH_SOCK`. This matters for SSH forwarding: a forwarded agent should not be overwritten simply because the local session also has an OpenSSH agent service.

Applications that do not inherit the shell environment should not require a second agent. Consumers that need local SSH authority should either inherit the session socket or use the canonical Home Manager runtime socket through an explicit integration.

## OpenWork

OpenWork is a consumer of the session agent, never its owner.

The Bubblewrap sandbox denies SSH-agent access by default:

```nix
dotfiles.openwork.sandbox.allowSshAgent = false;
```

When enabled, OpenWork first uses a live inherited `SSH_AUTH_SOCK`. If none is available and the Home Manager OpenSSH agent is enabled, the wrapper falls back to Home Manager's canonical runtime socket. The socket is then mounted into the sandbox and exported as `SSH_AUTH_SOCK`.

The Dubnium Home Manager profile deliberately enables this capability:

```nix
dotfiles.openwork.sandbox.allowSshAgent = true;
```

This permits Git/SSH authentication from OpenWork while preserving the wider sandbox boundary. Other sandbox consumers should receive the agent only when their workflow genuinely requires authentication/signing authority.

Access to an SSH-agent socket is a high-trust capability. A process with access to the socket can request authentication/signing operations using identities loaded in the agent, even though it does not receive the private key files directly.

## Verification

After applying the Home Manager configuration, verify the session contract with:

```bash
systemctl --user is-enabled ssh-agent.service
systemctl --user status ssh-agent.service
echo "$SSH_AUTH_SOCK"
ssh-add -l
```

The repository session diagnostic also checks the agent:

```bash
dub-session-doctor
```

Expected results on a normal user-systemd workstation are:

- `ssh-agent.service` is enabled;
- `ssh-agent.service` is active;
- `SSH_AUTH_SOCK` names a live Unix socket;
- `ssh-add -l` either lists loaded identities or reports that the agent currently has no identities.

An empty agent is not a service failure. Load keys deliberately according to the key-management policy in use.

## Troubleshooting

If `SSH_AUTH_SOCK` is unset in a new interactive shell, first verify the service itself rather than launching another agent:

```bash
systemctl --user status ssh-agent.service
systemctl --user show-environment | grep '^SSH_AUTH_SOCK=' || true
```

If a sandboxed application cannot authenticate, verify its capability policy separately. For OpenWork:

```nix
dotfiles.openwork.sandbox.allowSshAgent = true;
```

If an alternate agent provider is selected, confirm both sides of the ownership change:

1. `dotfiles.sshAgent.enable = false` prevents the Home Manager OpenSSH service from becoming a competing owner.
2. The selected provider actually exposes a valid `SSH_AUTH_SOCK` to the intended session/consumer.

Do not solve socket propagation problems by globally exposing credential sockets to every graphical application. Prefer inheritance for ordinary trusted clients and explicit delegation for sandboxed consumers.

## Security invariants

- one deliberate SSH-agent owner per session;
- no per-terminal `ssh-agent` processes;
- alternate providers require an explicit ownership change;
- sandbox access is deny-by-default and capability-scoped;
- OpenWork consumes but does not create the agent;
- SSH-agent sockets are never exposed to untrusted CI or unrelated containers;
- diagnostics distinguish service availability from whether identities are currently loaded.

## Related

- `modules/home/common.nix` — session agent option and Home Manager service wiring
- `modules/home/openwork.nix` — explicit sandbox socket delegation
- `home/ryjen/profiles/dubnium.nix` — Dubnium OpenWork opt-in
- `files/home/.local/bin/dub-session-doctor` — runtime diagnostics
- `scripts/verify-session-files.sh` — static session-contract checks
- issue #172 — architecture/documentation tracking
- PR #159 — initial implementation
