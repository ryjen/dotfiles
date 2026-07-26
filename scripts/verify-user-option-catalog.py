#!/usr/bin/env python3
"""Verify the portable Home Manager option catalog and local import contract."""

from __future__ import annotations

import re
import sys
from pathlib import Path


OPTION_NAMESPACE = re.compile(r"options\.dotfiles\.([A-Za-z][A-Za-z0-9_-]*)")
CATALOG_NAMESPACE = re.compile(r"dotfiles\.([A-Za-z][A-Za-z0-9_-]*)\.")
HOME_CONFIG = re.compile(r"mkHomeConfig\s+\./home/ryjen/([A-Za-z0-9_-]+\.nix)")
LOCAL_IMPORT = "lib.optional (builtins.pathExists ./user.local.nix) ./user.local.nix"


def fail(messages: list[str]) -> None:
    for message in messages:
        print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    modules = root / "modules" / "home"
    catalog_path = root / "home" / "ryjen" / "user.example.nix"
    flake_path = root / "flake.nix"

    errors: list[str] = []
    declared: set[str] = set()
    for path in sorted(modules.rglob("*.nix")):
        declared.update(OPTION_NAMESPACE.findall(path.read_text(encoding="utf-8")))

    catalog_text = catalog_path.read_text(encoding="utf-8")
    catalogued = set(CATALOG_NAMESPACE.findall(catalog_text))
    missing = sorted(declared - catalogued)
    if missing:
        errors.append(
            "user.example.nix is missing dotfiles option namespaces: " + ", ".join(missing)
        )

    flake_text = flake_path.read_text(encoding="utf-8")
    configs = sorted(set(HOME_CONFIG.findall(flake_text)))
    for name in configs:
        path = root / "home" / "ryjen" / name
        text = path.read_text(encoding="utf-8")
        if LOCAL_IMPORT not in text:
            errors.append(f"{path.relative_to(root)} does not optionally import user.local.nix")

    # The NixOS-integrated module imports dubnium-home.nix directly, so ensure
    # it is covered even if its standalone homeConfiguration is later removed.
    dubnium_home = root / "home" / "ryjen" / "dubnium-home.nix"
    if LOCAL_IMPORT not in dubnium_home.read_text(encoding="utf-8"):
        errors.append("home/ryjen/dubnium-home.nix does not optionally import user.local.nix")

    if errors:
        fail(errors)

    print(
        f"user option catalog covers {len(declared)} namespaces across "
        f"{len(configs)} Home Manager outputs"
    )


if __name__ == "__main__":
    main()
