# ADR-0001: Reusable Baseline and Host/Profile Overlays

## Status

Accepted

## Context

This repo started as a personal Nix migration, but it mixed reusable baseline behavior with host- and organization-specific state in the same default module set. That made the shared configuration harder to reuse and caused drift between the intended architecture and the actual implementation.

Examples of drift:

- Android tooling was enabled in the default Home Manager baseline.
- Micrantha-specific SSH, Git, and Zsh config lived in the default module set.
- local workstation PATH and desktop environment state lived in the shared session baseline.
- the Git baseline referenced unmanaged local files and identities.

## Decision

The repository will use three explicit configuration responsibilities:

1. Shared modules define reusable options and own implementation dependencies.
2. Ignored `home/USERNAME/user.local.nix` selects local, non-secret user-wide capabilities and identity.
3. Tracked host/profile overlays constrain machine-, employer-, or context-specific behavior.

Concrete implications:

- `modules/home/` may define both baseline modules and disabled-by-default feature modules.
- importing the module registry should not implicitly select optional user-facing programs.
- `home/USERNAME/user.example.nix` is tracked and kept current as the template for `user.local.nix`.
- `home/USERNAME/profiles/` contains host-role deltas, capability constraints, paths, and machine-specific values.
- personal Git identity is exposed through typed module options and may be configured in `user.local.nix`.
- `git-local.nix` and unmanaged Git include files are not standard configuration surfaces.
- organization-specific Git/SSH/Zsh behavior belongs behind explicit overlays, not in the reusable baseline.
- repo-managed assets referenced by modules must be provisioned declaratively by Home Manager.
- feature modules own their required runtime packages, generated files, wrappers, integrations, and services.
- local selectors are included only when evaluating the checkout through an explicit `path:` flake reference, such as `path:$PWD` from the repository root.
- ordinary Git-flake and CI evaluation intentionally validates tracked defaults without `user.local.nix`.
- secrets do not belong in `user.local.nix`, because `path:` flake sources are copied into the Nix store.

## Consequences

Positive:

- reusable baseline behavior is clearer and safer to apply on a new machine
- local selections and identity have one documented override surface
- host- and organization-specific behavior remains auditable and intentional
- dependencies are resolved by owning modules rather than copied into user configuration
- tracked defaults remain reproducibly testable in CI

Tradeoffs:

- local build and switch commands must use an explicit `path:` flake reference
- CI does not validate the user's ignored local selection matrix
- the tracked example must be updated whenever user-selectable options change
- invalid feature combinations require assertions or explicit dependency defaults
- new overlays and optional features must be explicitly enabled
