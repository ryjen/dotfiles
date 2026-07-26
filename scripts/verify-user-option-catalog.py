#!/usr/bin/env python3
"""Verify the portable Home Manager option catalog and local import contract."""

from __future__ import annotations

import re
import sys
from pathlib import Path


OPTION_CONSTRUCTOR = r"lib\.mk(?:EnableOption|Option)\b"
DIRECT_OPTION = re.compile(
    rf"^\s*options\.dotfiles\.([A-Za-z][A-Za-z0-9_.-]*)\s*=\s*{OPTION_CONSTRUCTOR}"
)
DIRECT_OPTION_PREFIX = re.compile(
    r"^\s*options\.dotfiles\.([A-Za-z][A-Za-z0-9_.-]*)\s*=\s*$"
)
CONSTRUCTOR_LINE = re.compile(rf"^\s*{OPTION_CONSTRUCTOR}")
OPTIONS_BLOCK = re.compile(
    r"^\s*options\.dotfiles(?:\.([A-Za-z][A-Za-z0-9_.-]*))?\s*=\s*\{\s*$"
)
NESTED_BLOCK = re.compile(r"^\s*([A-Za-z][A-Za-z0-9_.-]*)\s*=\s*\{\s*$")
NESTED_OPTION = re.compile(
    rf"^\s*([A-Za-z][A-Za-z0-9_.-]*)\s*=\s*{OPTION_CONSTRUCTOR}"
)
CATALOG_OPTION = re.compile(r"dotfiles\.([A-Za-z][A-Za-z0-9_.-]*)\s*=")
HOME_CONFIG = re.compile(r"mkHomeConfig\s+\./home/ryjen/([A-Za-z0-9_-]+\.nix)")
LOCAL_IMPORT = "lib.optional (builtins.pathExists ./user.local.nix) ./user.local.nix"
NON_PORTABLE_PREFIXES = ("host",)
NON_PORTABLE_OPTIONS = {
    "agents.antigravity.package",
    "opsCadence.package",
}


def brace_delta(line: str) -> int:
    """Count structural braces after removing comments and quoted strings."""
    code = line.split("#", 1)[0]
    code = re.sub(r'"(?:\\.|[^"\\])*"', '""', code)
    return code.count("{") - code.count("}")


def join_path(prefix: tuple[str, ...], suffix: str) -> str:
    return ".".join((*prefix, *suffix.split(".")))


def declared_option_paths(text: str) -> set[str]:
    """Extract exact dotfiles option paths from nixfmt-formatted module declarations."""
    declared: set[str] = set()
    depth = 0
    scopes: list[tuple[int, tuple[str, ...]]] = []
    pending_direct: str | None = None

    for raw_line in text.splitlines():
        line = raw_line.split("#", 1)[0].rstrip()

        if pending_direct is not None and line.strip():
            if CONSTRUCTOR_LINE.match(line):
                declared.add(pending_direct)
            pending_direct = None

        while scopes and depth < scopes[-1][0]:
            scopes.pop()

        direct = DIRECT_OPTION.match(line)
        if direct:
            declared.add(direct.group(1))
        else:
            direct_prefix = DIRECT_OPTION_PREFIX.match(line)
            if direct_prefix:
                pending_direct = direct_prefix.group(1)

        block = OPTIONS_BLOCK.match(line)
        if block:
            prefix = tuple((block.group(1) or "").split(".")) if block.group(1) else ()
            next_depth = depth + brace_delta(line)
            scopes.append((next_depth, prefix))
        elif scopes:
            prefix = scopes[-1][1]
            option = NESTED_OPTION.match(line)
            if option:
                declared.add(join_path(prefix, option.group(1)))
            else:
                nested = NESTED_BLOCK.match(line)
                if nested:
                    next_depth = depth + brace_delta(line)
                    scopes.append((next_depth, tuple(join_path(prefix, nested.group(1)).split("."))))

        depth += brace_delta(line)
        while scopes and depth < scopes[-1][0]:
            scopes.pop()

    return declared


def is_portable(path: str) -> bool:
    if path in NON_PORTABLE_OPTIONS:
        return False
    return not any(path == prefix or path.startswith(f"{prefix}.") for prefix in NON_PORTABLE_PREFIXES)


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
        declared.update(declared_option_paths(path.read_text(encoding="utf-8")))
    portable = {path for path in declared if is_portable(path)}

    catalog_text = catalog_path.read_text(encoding="utf-8")
    catalogued = set(CATALOG_OPTION.findall(catalog_text))
    missing = sorted(portable - catalogued)
    if missing:
        errors.append("user.example.nix is missing portable options: " + ", ".join(missing))

    stale = sorted(catalogued - portable)
    if stale:
        errors.append("user.example.nix contains unknown or non-portable options: " + ", ".join(stale))

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
        f"user option catalog covers {len(portable)} exact portable options across "
        f"{len(configs)} Home Manager outputs"
    )


if __name__ == "__main__":
    main()
