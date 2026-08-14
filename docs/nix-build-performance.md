# Dubnium Nix build performance benchmarks

The benchmark harness measures the tracked Dubnium Home Manager activation
package without clearing caches, garbage-collecting the store, or activating a
generation unless explicitly requested.

Run the commands below from the repository root unless an explicit
`--flake-dir` is supplied.

## Commands

```bash
# Evaluation plus a dry-run realization plan
nix run .#benchmark-dubnium -- plan --repeat 3

# Measure evaluation and realization independently
nix run .#benchmark-dubnium -- build --repeat 3

# Run one plan followed by repeated build measurements
nix run .#benchmark-dubnium -- suite --repeat 3 --json result.json

# Explicitly realize and activate; defaults to one activation
nix run .#benchmark-dubnium -- activate
```

The target must be a local output beginning with `.#`. Commands and Git
provenance are evaluated relative to `--flake-dir`, which defaults to the
current directory. External flake targets are rejected so benchmark results
cannot accidentally claim provenance from an unrelated checkout.

## Output contract

Stdout contains exactly one JSON document. Nix and activation diagnostics are
left on stderr, so this remains valid:

```bash
nix run .#benchmark-dubnium -- build --repeat 3 | jq .summary
```

The result records:

- separate evaluation, realization, planning, and activation samples;
- individual samples and median/minimum/maximum summaries;
- the Git revision and dirty state when available;
- Nix version and scheduler settings;
- a fingerprint and count for substituters rather than cache URLs;
- platform, architecture, and CPU count.

Literal hostnames are omitted by default. Use `--include-hostname` only for a
result that will remain private.

## Current measured evidence

The first real warm suite on 2026-08-03 established:

- evaluation median: **11.155 s**;
- realization median: **2.719 s**;
- warm realization as low as **0.919 s** after a **47.478 s** cold/partial
  first sample;
- initial scheduler settings of `max-jobs = 12`, `cores = 0`, and
  `max-substitution-jobs = 16`.

Evaluation was therefore the dominant warm critical-path cost.

Profile and feature decomposition under #130 and #132 found:

- a shared Home Manager/nixpkgs floor of roughly **4 s**;
- Technetium at **5.317 s** median evaluation;
- Dubnium at **9.380 s** in the tracked-profile comparison;
- workstation/Dubnium enabled features, rather than the complete module
  catalog, accounted for most of the incremental cost;
- Hermes' separate nixpkgs graph was the largest isolated contributor.

PR #135 made the Hermes input follow the repository's root nixpkgs input. The
subsequent actual Dubnium evaluation median was **8.409 s**, a **2.746 s /
24.6% reduction** from the original 11.155 s baseline. Controlled Hermes-only
overhead fell **47.5%**, and controlled Dubnium-combined overhead fell
**48.9%**.

The final full-profile sample used for the 8.409 s result was repository-bound
and evaluation-only, but the checkout was dirty. Treat it as strong directional
before/after evidence; collect a clean comparable switch/activation suite before
closing the overall performance programme.

Current architectural decision: **do not restructure the broad Home Manager
module catalog based on the existing evidence**. Remaining work is focused on
realization scheduling, source invalidation, and activation behavior.

## Baseline procedure

Collect at least three samples for each representative scenario:

1. warm/no-op `build`;
2. a small tracked Home Manager configuration change;
3. a representative custom-package source change;
4. explicit activation;
5. optional cold or partial-cache measurements performed manually and
   documented separately.

Do not delete the Nix store or run garbage collection as part of the benchmark.
A cold experiment should use an isolated store or an explicitly documented
machine state rather than destructively modifying the workstation.

Attach the JSON result and a brief description of machine activity to issue
#124. Keep CPU-intensive unrelated work idle so comparisons remain meaningful.

## Scheduler boundary

Scheduler tuning is tracked by #126. It should target cold/partial realization,
peak memory/swap pressure, and interactive responsiveness. It must not claim to
remove the remaining evaluation floor.

Compare bounded `max-jobs` / `cores` candidates, retain the current settings as
a rollback baseline, and change `max-substitution-jobs` only when download
concurrency is measured as a bottleneck.

## Activation safety and idempotency

Normal Home Manager activation is part of the measured critical path and must
remain deterministic, bounded, and rollback-safe. Activation entries should:

- avoid network access during a normal no-op activation;
- preserve unmanaged user settings unless the option explicitly owns them;
- compare generated content before replacing mutable files;
- avoid metadata-only writes when content and permissions are already correct;
- propagate real read, write, and filtering failures instead of masking them;
- scope temporary files and cleanup traps so one activation entry cannot affect
  later entries;
- avoid broad service restarts, recursive scans, or package-manager operations
  unless they are change-gated and justified.

Two concrete activation defects have already been removed:

- #140 / PR #141 removed the mutable Android CLI network download;
- #143 / PR #144 made Variety configuration content- and metadata-idempotent.

The Variety wallpaper activation contract is covered by:

```bash
nix build .#checks.x86_64-linux.variety-activation-tests
```

That check executes the activation body and verifies no-op modification-time
stability, unmanaged-setting preservation, managed-setting enforcement,
permission correction, error propagation, and cleanup-trap isolation.

### Current direct activation inventory

#150 tracks the full audit. Current `main` contains eight direct
`home.activation` entries across six modules:

| Module | Direct activation behavior | Status |
| --- | --- | --- |
| `uv.nix` | create tool bin directory | bounded `mkdir -p` |
| `npm.nix` | create npm prefix/bin directories | bounded `mkdir -p` |
| `pip.nix` | create pip prefix/bin directories | bounded `mkdir -p` |
| `taskwarrior.nix` | create local/custom files only when absent | create-if-missing |
| `hypr.nix` | create local Hypr config only when absent | create-if-missing |
| `hypr.nix` | maintain Variety directories/config | change-gated by #143 |
| `gpg.nix` | ensure GnuPG home | bounded creation; permission write still unconditional |
| `gpg.nix` | write `gpg.conf` | unconditional rewrite tracked by #174 |

The direct-hook inventory does not complete #150: adjacent deployment scripts,
service restart paths, and timing evidence still need review.

## Source invalidation boundary

#151 tracks source-file invalidation separately from evaluation-graph work.
Current findings are:

- `packages/openwork.nix` uses a fixed-output `fetchurl` with an explicit hash;
- the audited current tree has no direct `src = ./.` or `cleanSource` use;
- several repository checks intentionally pass `${self}` or `cd ${self}`;
- the pre-commit check intentionally uses `src = self` because it validates
  repository-wide policy.

The broad local source boundary is therefore concentrated in repository checks,
not the current custom runtime package. Measure whether unrelated documentation
or workflow changes cause material check rebuilds before narrowing any source
set. Repository-wide security and policy checks should remain broad unless a
smaller source set is proven complete.

## Store maintenance

Nix garbage collection is scheduled outside the interactive apply path through
native NixOS configuration. The weekly policy retains recent generations and
keeps garbage collection out of the normal switch critical path.

## Audit tracking

Performance work is intentionally split into focused, reviewable boundaries:

- #124 tracks the overall interactive Nix build and activation programme;
- #126 benchmarks scheduler settings for realization and responsiveness;
- #127 coordinates invalidation and activation work;
- #150 inventories/times activation and deployment paths;
- #151 classifies and narrows source boundaries where justified;
- #174 tracks the remaining confirmed GnuPG no-op mutation;
- #128 evaluates trusted binary-cache publication only if remaining realization
  misses justify it.

Confirmed problems should receive their own small issue and pull request rather
than expanding parent audits into broad refactors. Intentional remaining
network activity, broad source dependencies, scans, or restarts must be
recorded with their rationale and failure behavior.
