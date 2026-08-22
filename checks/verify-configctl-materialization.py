#!/usr/bin/env python3
"""Validate promoted-layer materialization policy for configctl app contracts."""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else Path.cwd().resolve()
APP_DIR = ROOT / "contracts" / "configctl" / "apps"
MACHINE_PROFILE_TOKEN = "{machine_profile}"
MATERIALIZATION_OWNERS = {"home-manager", "configctl-sync", "direct-render", "none"}
BROAD_ACTIVATION_PROFILES = {"all", "workstation"}
EXPECTED_PRECEDENCE = ["promoted", "custom", "local"]

# Repository-level proof that every Home Manager-owned projection is both
# materialized and consumed. These markers intentionally describe the stable
# mechanism rather than every line of the Nix implementation.
HOME_MANAGER_MODULE_MARKERS: dict[str, tuple[str, tuple[str, ...]]] = {
    "git": (
        "modules/home/git.nix",
        (
            "config.dotfiles.host.name",
            "git/includes-promoted.conf",
            "git/conf.d/${machineProfileName}",
        ),
    ),
    "hypr": (
        "modules/home/hypr.nix",
        (
            "config.dotfiles.host.name",
            "hypr/custom.d/${machineProfileName}",
            "custom.d/${machineProfileName}/*.conf",
        ),
    ),
    "mpd": (
        "modules/home/music-library.nix",
        (
            "config.dotfiles.host.name",
            "mpd/custom.d/${machineProfileName}",
            "custom.d/${machineProfileName}/*.conf",
        ),
    ),
    "task": (
        "modules/home/taskwarrior.nix",
        (
            "config.dotfiles.host.name",
            "task/custom.d/promoted.rc",
            "task/custom.d/${machineProfileName}/index.rc",
        ),
    ),
    "zsh": (
        "modules/home/zsh.nix",
        (
            "config.dotfiles.host.name",
            "zsh/config.d/${machineProfileName}",
            "config.d/${machineProfileName}",
        ),
    ),
}


def fail(message: str) -> None:
    print(f"configctl-materialization: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_contract(path: Path) -> dict[str, Any]:
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError) as exc:
        fail(f"{path}: cannot load app contract: {exc}")
    if not isinstance(data, dict):
        fail(f"{path}: app contract must be a TOML table")
    return data


def require_string(data: dict[str, Any], key: str, path: Path) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value:
        fail(f"{path}: {key} must be a non-empty string")
    return value


def require_string_list(data: dict[str, Any], key: str, path: Path) -> list[str]:
    value = data.get(key)
    if not isinstance(value, list) or not value or not all(isinstance(item, str) and item for item in value):
        fail(f"{path}: {key} must be a non-empty list of strings")
    return list(value)


def optional_string_list(data: dict[str, Any], key: str, path: Path) -> list[str]:
    value = data.get(key, [])
    if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
        fail(f"{path}: {key} must be a list of strings")
    return list(value)


def safe_relative(value: str, *, field: str, path: Path) -> PurePosixPath:
    candidate = PurePosixPath(value)
    if candidate.is_absolute() or value.startswith(("~", "$")) or ".." in candidate.parts:
        fail(f"{path}: {field} must remain relative to its declared root: {value}")
    return candidate


def expected_projection_patterns(layout: dict[str, Any], path: Path) -> list[str]:
    custom = require_string_list(layout, "custom", path)
    patterns: list[str] = []
    for raw in custom:
        candidate = safe_relative(raw, field="layout.custom", path=path)
        if MACHINE_PROFILE_TOKEN in raw:
            fail(f"{path}: layout.custom must describe the live root layer, not a machine-profile projection")
        patterns.append((candidate.parent / MACHINE_PROFILE_TOKEN / candidate.name).as_posix())
    return patterns


def expanded_pattern(pattern: str, machine_profile: str, *, field: str, path: Path) -> PurePosixPath:
    if pattern.count(MACHINE_PROFILE_TOKEN) != 1:
        fail(f"{path}: {field} must contain exactly one {MACHINE_PROFILE_TOKEN}: {pattern}")
    expanded = pattern.replace(MACHINE_PROFILE_TOKEN, machine_profile)
    candidate = safe_relative(expanded, field=field, path=path)
    if machine_profile not in candidate.parts:
        fail(f"{path}: {field} expansion lost machine-profile namespace: {pattern}")
    return candidate


def static_path_prefix(pattern: PurePosixPath) -> PurePosixPath:
    parts: list[str] = []
    for part in pattern.parts:
        if any(char in part for char in "*?["):
            break
        parts.append(part)
    return PurePosixPath(*parts)


def overlaps_projection(
    projection: PurePosixPath,
    patterns: list[str],
    *,
    field: str,
    path: Path,
) -> None:
    projection_prefix = static_path_prefix(projection)
    for raw in patterns:
        if raw.startswith(("~", "$")):
            continue
        other = safe_relative(raw, field=field, path=path)
        other_prefix = static_path_prefix(other)
        if projection_prefix == other_prefix:
            fail(f"{path}: promoted projection overlaps {field}: {projection_prefix}")


def validate_explicit_promoted_inputs(contract: dict[str, Any], layout: dict[str, Any], path: Path) -> None:
    promoted = optional_string_list(layout, "promoted_inputs", path)
    if not promoted:
        return
    activation_profile = require_string(contract, "profile", path)
    if activation_profile in BROAD_ACTIVATION_PROFILES:
        fail(
            f"{path}: broad activation profile {activation_profile!r} must not use static layout.promoted_inputs; "
            "derive promoted inputs from the machine profile"
        )
    for raw in promoted:
        safe_relative(raw, field="layout.promoted_inputs", path=path)
        if f"/{activation_profile}/" not in f"/{raw}":
            fail(f"{path}: explicit promoted_inputs must be bound to its concrete machine profile")


def validate_materialization(path: Path, contract: dict[str, Any]) -> tuple[str, str]:
    tool = require_string(contract, "tool", path)
    strategy = require_string(contract, "strategy", path)
    layout = contract.get("layout")
    if not isinstance(layout, dict):
        fail(f"{path}: missing [layout] table")
    materialization = contract.get("materialization")
    if not isinstance(materialization, dict):
        fail(f"{path}: missing [materialization] table")
    owner = require_string(materialization, "promoted", path)
    if owner not in MATERIALIZATION_OWNERS:
        fail(f"{path}: unsupported materialization.promoted owner: {owner}")

    validate_explicit_promoted_inputs(contract, layout, path)

    if strategy == "compose" and owner != "direct-render":
        fail(f"{path}: compose apps must consume promoted state with direct-render")
    if strategy == "native-include" and owner != "home-manager":
        fail(f"{path}: active native-include apps must keep promoted projection under Home Manager")

    if owner in {"direct-render", "none"}:
        forbidden = sorted(set(materialization) - {"promoted"})
        if forbidden:
            fail(f"{path}: {owner} materialization must not declare runtime projection fields: {', '.join(forbidden)}")
        return tool, owner

    projection = require_string_list(materialization, "runtime_projection", path)
    consumption = require_string_list(materialization, "runtime_consumption", path)
    precedence = require_string_list(materialization, "precedence", path)
    if precedence != EXPECTED_PRECEDENCE:
        fail(f"{path}: materialization.precedence must be {EXPECTED_PRECEDENCE!r}")

    expected = expected_projection_patterns(layout, path)
    if projection != expected:
        fail(f"{path}: runtime_projection must preserve the profile namespace: expected {expected!r}")

    runtime_includes = optional_string_list(layout, "runtime_includes", path)
    missing_consumers = [item for item in consumption if item not in runtime_includes]
    if missing_consumers:
        fail(
            f"{path}: runtime_consumption is not declared by layout.runtime_includes: "
            + ", ".join(missing_consumers)
        )

    local = optional_string_list(layout, "local", path)
    runtime_outputs = optional_string_list(layout, "runtime_outputs", path)
    for machine_profile in ("dubnium", "technetium"):
        for raw in projection:
            expanded = expanded_pattern(raw, machine_profile, field="materialization.runtime_projection", path=path)
            overlaps_projection(expanded, local, field="layout.local", path=path)
            overlaps_projection(expanded, runtime_outputs, field="layout.runtime_outputs", path=path)
            # The projection must be nested beneath, not equal to, the root live custom layer.
            for custom_raw in require_string_list(layout, "custom", path):
                custom = safe_relative(custom_raw, field="layout.custom", path=path)
                if static_path_prefix(expanded) == static_path_prefix(custom):
                    fail(f"{path}: promoted projection flattens into the live custom layer: {expanded}")

    if owner == "home-manager":
        if contract.get("current_runtime_owner") != "home-manager" or contract.get("target_runtime_owner") != "home-manager":
            fail(f"{path}: home-manager materialization requires current/target runtime owner home-manager")
        if contract.get("executor_may_write_outputs") is not False:
            fail(f"{path}: Home Manager-owned materialization must keep configctl output writes disabled")
        module_spec = HOME_MANAGER_MODULE_MARKERS.get(tool)
        if module_spec is None:
            fail(f"{path}: no Home Manager projection proof registered for {tool}")
        module_rel, markers = module_spec
        module_path = ROOT / module_rel
        if not module_path.is_file():
            fail(f"{path}: Home Manager projection module is missing: {module_rel}")
        source = module_path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in source:
                fail(f"{path}: Home Manager projection is inert; {module_rel} is missing marker {marker!r}")

    if owner == "configctl-sync" and contract.get("target_runtime_owner") != "configctl":
        fail(f"{path}: configctl-sync materialization must target runtime owner configctl")

    return tool, owner


def main() -> int:
    if not APP_DIR.is_dir():
        fail(f"missing app-contract directory: {APP_DIR}")

    results: dict[str, str] = {}
    for path in sorted(APP_DIR.glob("*.toml")):
        contract = load_contract(path)
        tool, owner = validate_materialization(path, contract)
        if tool in results:
            fail(f"duplicate app contract for tool {tool!r}")
        results[tool] = owner

    if not results:
        fail("no app contracts found")

    counts = {owner: 0 for owner in sorted(MATERIALIZATION_OWNERS)}
    for owner in results.values():
        counts[owner] += 1
    summary = ", ".join(f"{owner}={counts[owner]}" for owner in sorted(counts))
    print(f"validated configctl promoted materialization contracts ({summary})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
