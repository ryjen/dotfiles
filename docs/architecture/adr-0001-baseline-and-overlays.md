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

The repository will use a two-layer model:

1. Shared baseline modules provide reusable defaults that are safe across machines.
2. Host/profile overlays enable machine-, employer-, or context-specific behavior through explicit `dotfiles.profiles.*` options.

Concrete implications:

- `modules/home/` may define both baseline modules and disabled-by-default overlay modules.
- `home/USERNAME/profiles/` selects overlays for a concrete machine.
- personal Git identity is configured outside the shared baseline, using `home/USERNAME/git-local.nix` or another explicit overlay.
- organization-specific Git/SSH/Zsh behavior belongs behind overlays, not in the baseline.
- repo-managed Git assets referenced by the baseline must be provisioned declaratively by Home Manager.

## Consequences

Positive:

- reusable baseline is clearer and safer to apply on a new machine
- host- and org-specific behavior becomes auditable and intentional
- documentation can describe one stable architecture instead of a migration exception

Tradeoffs:

- one more layer of indirection exists between baseline modules and concrete host behavior
- new overlays must be explicitly enabled in profile files
