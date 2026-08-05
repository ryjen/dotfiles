# Ops Cadence credential isolation

The `dotfiles.opsCadence` Home Manager module treats live Gmail and GitHub access as explicit optional capabilities. Live sources are disabled by default.

## Fail-closed configuration

A live source can be enabled only when the global live-source gate and its dedicated credential path are both configured:

```nix
dotfiles.opsCadence = {
  liveSources = {
    enable = true;
    github = true;
    gmail = true;
  };

  credentials = {
    githubTokenFile = "%h/.config/ops-cadence/secrets/github-token";
    gmailAccessTokenFile = "%h/.config/ops-cadence/secrets/gmail-access-token";
  };
};
```

Home Manager evaluation fails when:

- Gmail or GitHub is enabled without `liveSources.enable`;
- `liveSources.enable` has no selected source;
- an enabled source has no corresponding credential path;
- a credential path is relative, stored under `/nix/store`, or contains `:` or a newline;
- CareerOps workflow, state, or professional-context paths are not absolute.

Credential files are never imported as Nix paths or embedded into generated units. Only runtime path strings are accepted.

## systemd credential boundary

Credentials are loaded with `LoadCredential=` only for capabilities that are actually enabled. A configured credential file for a disabled source is not loaded into the service.

Before exporting a credential to `opsctl`, the generated runner verifies that the systemd-provided credential file:

- exists and is non-empty;
- is no larger than 8192 bytes;
- is available only through `$CREDENTIALS_DIRECTORY`.

The service removes ambient interactive credentials, including GitHub, GitLab, Gmail, Google, OpenAI, Anthropic, Cloudflare, AWS, npm, Hugging Face, Docker, Kubernetes, and SSH-agent variables. It sets `PYTHONNOUSERSITE=1` so user-installed Python packages cannot change the packaged runtime.

Use a dedicated fine-grained GitHub token with read-only access only to the configured repositories and required metadata. Use a short-lived Gmail OAuth access token restricted to metadata retrieval. Do not reuse an interactive repository-write token.

## CareerOps input gate

The generated `ops-cadence/config.toml` includes the minimized professional-context snapshot:

```toml
[careerops]
professional_context_snapshot_path = "/home/ryjen/.local/state/careerops/professional-context.v1.json"
```

`career-intelligence.service` runs this command before every report:

```bash
opsctl doctor --probe --json
```

A failed contract or configuration probe prevents the report command from starting. Engineering Portfolio and Weekly Review remain independent timer-safe reports and do not require the CareerOps probe.

## Service file protections

Each service retains:

- `UMask=0077`;
- `ProtectSystem=strict`;
- `ProtectHome=read-only`;
- a single writable state directory;
- `PrivateTmp=true`;
- `NoNewPrivileges=true`;
- bounded execution time;
- overlap exit code `75` as a successful skip.

The module provisions `~/.local/state/ops-cadence` as mode `0700`. The pinned runtime creates report, status, lock, and SQLite files as mode `0600` and rejects unsafe or symlinked targets.

## Host verification

After the authorized private `ops-cadence` flake pin is refreshed and Home Manager is activated on Dubnium:

```bash
systemctl --user cat opsctl-career-intelligence.service
systemctl --user show opsctl-career-intelligence.service \
  -p UMask -p LoadCredential -p UnsetEnvironment -p Environment \
  -p ProtectSystem -p ProtectHome -p ReadWritePaths -p ExecStartPre
```

Verify that:

- `UMask=0077` is present;
- only enabled credential names appear under `LoadCredential`;
- no credential values appear in the unit;
- broad ambient credential names appear under `UnsetEnvironment`;
- `ExecStartPre` invokes the read-only doctor probe;
- the only writable path is the ops-cadence state directory.

Then run:

```bash
systemctl --user start opsctl-career-intelligence.service
opsctl status --json
journalctl --user-unit opsctl-career-intelligence.service --since today
```

The journal may contain failure types and bounded operational status, but it must not contain token values, raw mailbox bodies, or canonical professional evidence.

## Rotation and revocation

To rotate a credential:

1. Stop the three `opsctl-*.timer` units.
2. Replace the runtime credential file without changing its configured path.
3. Keep the credential file readable only by the user.
4. Run `home-manager switch` only when module configuration changed; credential content changes do not require rebuilding the Nix closure.
5. Run `opsctl doctor --probe --json` and one manual service invocation.
6. Re-enable the timers.

For suspected disclosure, revoke the credential first, stop timers, inspect bounded status and journal metadata, clean retained report state as documented by `ops-cadence`, then provision a new dedicated credential.
