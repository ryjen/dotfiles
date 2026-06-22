# ADR-0002: Repo-local Hook Governance

## Status

Accepted

## Context

`dotfiles` needs one managed path for repo-local Git hooks. Local hooks are useful for fast feedback, but they are advisory: they can be bypassed and must not become the only enforcement point for critical repo invariants.

The repo already has flake checks and explicit verification scripts. Those checks remain authoritative where they encode repo contracts. Hook governance should reduce bespoke lifecycle glue, improve fresh-clone ergonomics, and keep hook configuration declarative and reviewable.

Current inventory for this slice:

- no root `.git-hooks` file is present;
- no root `.pre-commit-config.yaml` is committed;
- no dedicated `scripts/install-hooks.sh` exists;
- `flake.nix` already exposes verification apps and the `flake-script-executables` check;
- `scripts/verify-flake-script-executables.sh` owns the repo-specific executable-bit contract for scripts referenced by the flake;
- `scripts/verify-session-files.sh` owns the session-file smoke check;
- `scripts/verify-in-container.sh` owns containerized flake/home/system verification orchestration.

## Questions

- Which current repo invariants belong in local hooks?
- Which checks are cheap enough for commit-time execution?
- Which checks should remain flake-only or CI-only?
- Which existing custom scripts encode repo-specific contracts rather than generic lint/format behavior?
- How should generated hook config remain visible without becoming committed source of truth?
- Which future governance checks belong in Anthesis, CI, branch protection, or server-side hooks rather than local Git hooks?

## Alternatives

### Use `cachix/git-hooks.nix`

This is the selected path. It integrates pre-commit hooks with Nix flakes, devShells, and flake checks while keeping dependencies repo-managed.

Pros:

- Nix-native dependency wiring;
- fresh-clone setup through `nix develop`;
- manual full-repo execution through `pre-commit run --all-files`;
- flake-check integration for non-mutating hooks;
- avoids user-global hook tooling as a bootstrap requirement.

Cons:

- adds an abstraction layer over generated pre-commit configuration;
- hook behavior must remain inspectable;
- mutating formatter hooks are awkward inside `nix flake check` because flake checks run in a sandbox.

### Use `pre-commit` directly

Direct `pre-commit` has the broadest ecosystem and is familiar, but it pushes more runtime and cache management into the local environment. That is a worse fit for a Nix-first repo.

### Keep bespoke hooks

Custom hooks minimize framework adoption but preserve install/update/run/doctor lifecycle maintenance. That work is not where this repo should grow complexity.

### Use `lefthook`

`lefthook` is fast and straightforward, but it is less naturally aligned with Nix flakes and would require more repo-owned integration glue.

### Use `treefmt-nix` only

`treefmt-nix` is a strong formatter orchestrator, but hook governance needs more than formatting. It remains a possible complement, not the primary hook framework.

### Server-side hooks or self-hosted Git

Server-side hooks can enforce policy better than local hooks, but they are operationally larger and belong in a separate governance issue. They should not block local hook cleanup.

## Recommendation

Use `cachix/git-hooks.nix` as the repo-local hook framework.

Local hooks should be treated as fast advisory checks. Critical invariants should stay in `flake check`, CI, branch protection, server-side policy, or future Anthesis approval/governance flows.

Initial hook wiring should be intentionally small:

- add `cachix/git-hooks.nix` as the managed integration layer;
- add a minimal Nix formatting hook;
- wire hook installation through `nix develop`;
- keep existing repo-specific verification scripts and flake checks intact.

## Tradeoffs

- **Nix-native reproducibility over ecosystem directness:** `git-hooks.nix` is less direct than raw `pre-commit`, but it better matches this repo's flake/devShell model.
- **Generated config over committed config:** generated `.pre-commit-config.yaml` should stay ignored; the reviewed source of truth is `flake.nix`.
- **Fast feedback over authority:** hooks catch issues early, but authoritative enforcement remains outside local hooks.
- **Small initial coverage over broad migration:** this slice proves the integration path without porting every existing check.
- **Local-only over server-side governance:** server-side hooks remain a promising future direction, but not part of this migration slice.

## Consequences

Positive:

- hook setup becomes reproducible through repo-managed tooling;
- hook execution is available manually and through the devShell;
- the repo avoids growing bespoke hook lifecycle management;
- existing verification checks remain intact.

Negative:

- the flake now has another input;
- generated pre-commit config must be understood as derived state;
- future hook additions must be curated to avoid slow commits or hook-only enforcement.
