#!/usr/bin/env python3
"""Reject private host-runtime dependencies from standalone dotfiles composition."""

from __future__ import annotations

import sys
from pathlib import Path

FORBIDDEN_SOURCE_MARKERS = (
    "git+ssh://",
    "ssh://git@github.com/",
    "git@github.com:",
)

COMPOSITION_FILES = (
    "flake.nix",
    "flake.lock",
    "modules/home/default.nix",
    "home/ryjen/profiles/dubnium.nix",
    "home/ryjen/user.example.nix",
    "scripts/benchmark-home-feature-evaluation.py",
    ".github/workflows/nix-ci.yml",
)


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    errors: list[str] = []

    for relative in COMPOSITION_FILES:
        path = root / relative
        if not path.is_file():
            errors.append(f"missing composition file: {relative}")
            continue
        text = path.read_text(encoding="utf-8")
        for marker in FORBIDDEN_SOURCE_MARKERS:
            if marker in text:
                errors.append(f"{relative} contains forbidden SSH source marker: {marker}")
        if "ops-cadence" in text or "opsCadence" in text:
            errors.append(f"{relative} still references private ops-cadence ownership")

    removed_paths = (
        "modules/home/ops-cadence.nix",
        "checks/verify-ops-cadence-timers.py",
        ".github/workflows/ops-cadence-module.yml",
        "fixtures/ops-cadence/flake.nix",
        "docs/ops-cadence-timers.md",
        "docs/ops-cadence-credential-isolation.md",
    )
    for relative in removed_paths:
        if (root / relative).exists():
            errors.append(f"obsolete ops-cadence surface still exists: {relative}")

    if errors:
        for item in errors:
            print(f"error: {item}", file=sys.stderr)
        return 1

    print("standalone dotfiles source boundary is credential-independent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
