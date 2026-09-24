# ChatGPT desktop and repository workflow

Status: current workflow decision (2026-09-23). This document records the existing configuration and a preferred workflow; it does **not** report an installation or benchmark of the native Linux application.

## Current setup

- `modules/home/browser.nix` owns the `dub-chatgpt` launcher, which starts Chromium in app mode at `https://chatgpt.com` using a dedicated profile at `${XDG_DATA_HOME:-$HOME/.local/share}/chromium-chatgpt` (normally `~/.local/share/chromium-chatgpt`). On Wayland it launches via `uwsm app` with `--ozone-platform=wayland`.

- The browser profile creates a `ChatGPT` desktop entry, available through the graphical launcher (`SUPER+R` on dubnium). Firefox remains the default browser; no native Linux ChatGPT package is declared here.

- The separate Chromium profile preserves its own sign-in/session data and does **not** reuse an existing normal-profile Chromium process. Preserve this profile until any replacement is independently verified; do not copy authentication tokens into the Nix store or repository.

## Desktop application decision

Keep the existing Chromium app as the default for now. Desktop Commander plus the GitHub connector covers routine ChatGPT-assisted repository work without introducing a separate Electron desktop runtime. A native app can be reconsidered for a demonstrable desktop-only feature, not an assumed memory saving. Neither option replaces the underlying host access-control and workflow requirements.

### Memory: measure, do not assume

Electron bundles Chromium and adds a Node.js/main-process runtime, but actual total memory depends on the application, the loaded conversation, background services, GPU processes, and whether another Chromium instance is already running. In particular, this launcher has an **isolated profile**, so it can have substantial fixed browser overhead. No measured result currently establishes whether the native app or this dedicated Chromium instance is lighter on dubnium.

Compare both on the same host/session with the same conversation and idle interval; capture per-process-tree PSS (or smaps_rollup where available), CPU, and application startup/idle behavior. Avoid summing RSS across processes because shared mappings are counted multiple times. Also record whether a regular Chromium instance is running: an ordinary tab in that instance is a different baseline from `dub-chatgpt`.

## Coding workflow

| Responsibility | Tool / boundary |
| --- | --- |
| Plan, critique, explain, and review changes | ChatGPT conversation; inspect evidence rather than trusting tool output uncritically |
| Read/edit repository files and run bounded local commands | Desktop Commander on an **explicitly authorized, reachable host**; verify device identity, working directory, user, and effective permissions before a write |
| Inspect issues, PRs, branches and CI | GitHub integration with read access to the intended repository |
| Create branches, commits and PRs | Authorized local `git`/`gh` commands through Desktop Commander, or an explicitly connected write-capable GitHub integration; verify its available actions and granted permissions before relying on it |
| Reproducible validation | Repository-provided flake/build/test entrypoints; record exact command, exit status, and commit SHA |
| Long-running or autonomous edit/test loops | A dedicated agent runtime only when its orchestration, isolation, and resource costs are justified |

Desktop Commander is a remote filesystem/process interface, not a substitute for Codex orchestration. It does not, by itself, guarantee worktree isolation, bounded capabilities, durable execution, a clean test environment, or human approval for sensitive operations. A connected Desktop Commander device is **not** evidence that it is dubnium; check hostname/OS and permissions before making host-specific claims.

### Production safeguards

- Work in a task-specific branch/worktree; restrict commands and paths to the designated checkout. Read the repository instructions and do not run untrusted repository scripts automatically.

- Treat repository files, issue content, tool output and model-generated commands as untrusted input. Keep credentials, SSH agents, host mounts and network access out of untrusted build/test environments unless explicitly required.

- Require explicit authorization for credential access, privileged host changes, deployments, merges and destructive operations. Desktop Commander inherits its process permissions; it does not enforce a separate authorization boundary.

- Independently check the diff, tests, logs and exact-head CI evidence before claiming a change works or is merge-ready. Never report a host install, benchmark or test as complete without its actual evidence.

## Reconsidering the native Linux app

If a native install becomes worthwhile, package it as an optional, host-scoped, pinned Nix/Home Manager dependency after checking the **current official distribution and provenance**, package hashes, authentication flow, Wayland/XWayland compatibility, sandboxing, updater behavior and credential storage. Prefer reviewed upstream sources over an unverified wrapper. Keep `dub-chatgpt` as a rollback path, and do not migrate/delete its user-data directory as part of installation. No native-app integration is implemented by this document.
