# Controlled Home Manager feature evaluation

Use this diagnostic after the tracked-profile comparison shows a material
workstation or host-specific evaluation delta.

```bash
cd ~/.local/src/dotfiles

python3 scripts/benchmark-home-feature-evaluation.py \
  --repeat 3 \
  --output benchmark-results/home-feature-evaluation.json \
  | jq .variants
```

The default comparison evaluates an identical graphical Home Manager baseline
and then enables these feature sets independently:

- meeting support;
- Hermes;
- Antigravity;
- Headroom proxy;
- OpenWork;
- the workstation combination;
- the Dubnium combination.

Each result includes individual samples, median/minimum/maximum times, and the
delta from `graphical-base`.

## Safety boundary

The profiler:

- evaluates only `activationPackage.drvPath`;
- never realizes an output;
- never activates a Home Manager generation;
- never clears caches or garbage-collects the store;
- creates temporary Nix expressions outside the repository;
- leaves production profiles unchanged.

The generated expression uses `builtins.getFlake` with an explicit local checkout
and therefore runs `nix eval --impure`. This impurity is limited to selecting the
local tracked checkout for diagnostic evaluation. The result records the Git
revision and dirty-tree state so measurements can be attributed correctly.

Run from a clean checkout with unrelated CPU- and disk-heavy work idle. Attach
the JSON result to issues #132, #130, and #127.

## Focused comparison

A subset can be selected, but include `graphical-base` so deltas remain defined:

```bash
python3 scripts/benchmark-home-feature-evaluation.py \
  --variant graphical-base \
  --variant meeting \
  --variant hermes \
  --repeat 5
```
