# Home Manager profile evaluation comparison

Use the profile comparison after collecting a normal Dubnium benchmark baseline.
It measures evaluation only and does not activate a generation, clear caches, or
garbage-collect the Nix store.

```bash
cd ~/.local/src/dotfiles

python3 scripts/benchmark-home-profile-evaluation.py \
  --repeat 3 \
  --output-dir benchmark-results/home-profile-evaluation \
  | jq .profiles
```

The default target set is:

- `ryjen@verify`
- `ryjen@headless`
- `ryjen@wsl`
- `ryjen@technetium`
- `ryjen@dubnium`
- `ryjen@meeting-verify`

Each complete benchmark result is retained as `<profile>.json`. The compact
comparison is written to `summary.json` and printed to stdout. Profiles are
ranked by median evaluation time, with a delta from the fastest tracked profile.

To measure a smaller subset:

```bash
python3 scripts/benchmark-home-profile-evaluation.py \
  --profile headless \
  --profile dubnium \
  --repeat 5
```

Keep unrelated CPU- and disk-intensive work idle. Run from a clean tracked
revision and attach `summary.json` to issues #130 and #127 with any relevant
machine activity noted.

## Interpretation

- A high common floor across all profiles points toward nixpkgs/Home Manager or
  shared module-catalog cost.
- A large Dubnium delta points toward workstation, graphical, external-input,
  or Dubnium-specific configuration.
- A small delta does not justify partitioning the module catalog solely for
  performance; option visibility and maintenance cost should take precedence.

This comparison does not yet provide a minimal synthetic Home Manager baseline
or incremental shared/graphical/workstation variants. Those should be added only
if tracked-profile results cannot localize the dominant layer.
