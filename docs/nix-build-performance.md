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

## Baseline procedure

Collect at least three samples for each representative scenario:

1. warm/no-op `build`;
2. a small tracked Home Manager configuration change;
3. a representative custom-package source change;
4. optional cold or partial-cache measurements performed manually and
   documented separately.

Do not delete the Nix store or run garbage collection as part of the benchmark.
A cold experiment should use an isolated store or an explicitly documented
machine state rather than destructively modifying the workstation.

Attach the JSON result and a brief description of machine activity to issue
#124. Keep CPU-intensive unrelated work idle so comparisons remain meaningful.

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

The Variety wallpaper activation contract is covered by a repository check:

```bash
nix build .#checks.x86_64-linux.variety-activation-tests
```

That check executes the activation body and verifies no-op modification-time
stability, unmanaged-setting preservation, managed-setting enforcement,
permission correction, error propagation, and cleanup-trap isolation.

## Audit tracking

Performance work is intentionally split into focused, reviewable boundaries:

- #124 tracks the overall interactive Nix build and activation programme;
- #127 coordinates source invalidation and Home Manager activation work;
- #150 inventories and times remaining activation hooks and adjacent scripts;
- #151 inventories and narrows custom derivation source boundaries.

Confirmed problems should receive their own small issue and pull request rather
than expanding the parent audits into a broad refactor. Intentional remaining
network activity, broad source dependencies, scans, or restarts must be
recorded with their rationale and failure behaviour.
