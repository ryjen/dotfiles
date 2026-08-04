# Ops Cadence user timers

The `dotfiles.opsCadence` Home Manager module installs `opsctl`, writes its user configuration, and schedules three `systemd.user` timers on profiles that enable user systemd.

## Runtime prerequisite

The hardened unit definitions can be merged and evaluated independently, but native locking, `opsctl doctor`, `opsctl status --json`, and durable `run-status.json` require `ryjen/ops-cadence` commit `200baa53de06dac26bd1b96c2ab2847ff4a79c1b` or later.

The dependency is private and remains SSH-pinned. Dotfiles issue #137 tracks the authorized Dubnium-local lock refresh, activation, and runtime verification. Do not treat this module merge alone as proof that the current runtime is installed or that the timers have executed on the host.

## Schedule

| Report | Timer | Persistent |
| --- | --- | --- |
| Daily Career Intelligence | Every day around 08:00 | Yes |
| Engineering Portfolio Review | Monday around 09:30 | Yes |
| Weekly Project Review | Friday around 16:30 | Yes |

Each timer uses a five-minute accuracy window and up to five minutes of randomized delay by default. `Persistent=true` causes a missed run to execute after the user manager resumes.

## Runtime safety

The service definitions:

- allow at most 15 minutes per report by default;
- treat `opsctl` exit code `75` as a clean overlap skip;
- use `UMask=0077`;
- provision `~/.local/state/ops-cadence` declaratively with mode `0700` before the service sandbox is created;
- write only to that state directory;
- mount the remainder of the home directory read-only;
- protect the system and temporary directory;
- disable privilege escalation, realtime scheduling, SUID/SGID creation, and personality changes;
- run at reduced CPU and idle I/O priority;
- write stdout and stderr to the user journal.

After the prerequisite runtime is pinned, `opsctl` owns the cross-report lock and atomically records `run-status.json`, including report artifacts, source health, delivery state, duration, and redacted failure type.

## Credentials

Live sources are disabled by default. The service removes ambient GitHub, GitLab, Gmail, Google, OpenAI, AWS, and SSH-agent credentials before executing.

Optional read-only credentials are loaded through systemd credentials:

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

Use a fine-grained read-only GitHub token. The Gmail value must be a valid short-lived OAuth access token; durable refresh-token support remains a separate adapter concern. Credential files must not be committed to the repository.

## CareerOps artifacts

The default local contract directory is:

```text
~/.local/state/careerops
```

Expected files:

- `application-state.json`
- `discovery-candidates.json`
- `execution-capacity.json`
- `follow-up-queue.json`
- `issue-priorities.json`
- `blockers.json`

The default workflow checkout is `~/.local/src/career-workflows`.

After completing issue #137, validate configuration and local contracts before activation:

```bash
opsctl doctor --probe
```

## Activation

Build before switching:

```bash
nix build '.#homeConfigurations."ryjen@dubnium".activationPackage' --no-link
home-manager switch --flake '.#ryjen@dubnium'
```

Inspect installation:

```bash
systemctl --user daemon-reload
systemctl --user list-timers 'opsctl-*'
systemctl --user status opsctl-career-intelligence.timer
```

## Manual verification

Run each service directly:

```bash
systemctl --user start opsctl-career-intelligence.service
systemctl --user start opsctl-engineering-portfolio.service
systemctl --user start opsctl-weekly-review.service
```

Inspect operational evidence:

```bash
opsctl status --json
journalctl --user-unit opsctl-career-intelligence.service --since today
journalctl --user-unit opsctl-engineering-portfolio.service --since today
journalctl --user-unit opsctl-weekly-review.service --since today
```

A successful verification confirms:

1. the service exits successfully;
2. `run-status.json` reports `completed` or `completed_degraded`;
3. Markdown and JSON artifact paths exist;
4. source health is explicit;
5. the journal contains no credentials or raw source bodies.

## Missed-run and overlap verification

To verify persistence, stop the user timer before its schedule, pass the schedule, then start the user manager and confirm the timer invokes its service.

To verify overlap protection, hold an `opsctl run` active and invoke a second report. The second invocation must exit `75`, systemd must consider the service successful, and the active `run-status.json` must remain unchanged.

## Disable and recovery

Disable scheduling while retaining the package and configuration:

```nix
dotfiles.opsCadence.timers.enable = false;
```

Temporarily stop timers:

```bash
systemctl --user stop 'opsctl-*.timer'
```

After correcting configuration or source artifacts:

```bash
opsctl doctor --probe
systemctl --user reset-failed 'opsctl-*.service'
systemctl --user start opsctl-career-intelligence.service
```

The services cannot apply to jobs, send recruiter replies, mutate trackers or repositories, rotate secrets, close issues, or change infrastructure.
