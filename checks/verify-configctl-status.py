#!/usr/bin/env python3
"""Validate the dotfiles-owned configctl status compatibility projection."""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else Path.cwd().resolve()
CONTRACT = REPO_ROOT / "contracts" / "configctl" / "status-v1.toml"
EXPECTED_BASELINE = ["hypr", "git", "nvim", "zsh", "codex", "hermes", "mpd"]
ALLOWED_AUTHORITIES = {"app-manifest", "home-manager", "init-contract"}
ALLOWED_DRIFT = {"root", "local", "custom", "adopted"}
IDENTIFIER = re.compile(r"^[a-z][a-z0-9_.-]*$")
GLOB_CHARS = "*?["


def fail(message: str) -> None:
    raise SystemExit(message)


def load_toml(path: Path) -> dict[str, Any]:
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except OSError as exc:
        fail(f"{path}: cannot read TOML: {exc}")
    except tomllib.TOMLDecodeError as exc:
        fail(f"{path}: invalid TOML: {exc}")
    raise AssertionError("unreachable")


def safe_repo_file(raw: str, *, label: str) -> Path:
    path = Path(raw)
    if path.is_absolute() or raw.startswith(("~", "$")) or ".." in path.parts:
        fail(f"{CONTRACT}: {label} must be a safe repository-relative path: {raw!r}")
    resolved = (REPO_ROOT / path).resolve()
    try:
        resolved.relative_to(REPO_ROOT)
    except ValueError:
        fail(f"{CONTRACT}: {label} escapes repository root: {raw!r}")
    if not resolved.is_file():
        fail(f"{CONTRACT}: {label} does not exist: {raw!r}")
    return resolved


def require_segment(entry: dict[str, Any], tool: str, field: str) -> str:
    value = entry.get(field)
    if not isinstance(value, str) or not value:
        fail(f"{CONTRACT}: tools.{tool}.{field} must be a non-empty string")
    candidate = Path(value)
    if candidate.name != value or value in {".", ".."}:
        fail(f"{CONTRACT}: tools.{tool}.{field} must be one safe path segment: {value!r}")
    return value


def normalized_home_path(value: str) -> str:
    if value.startswith("~/"):
        return "$HOME/" + value[2:]
    return value


def single_layout_value(
    manifest_path: Path,
    layout: dict[str, Any],
    role: str,
    *,
    directory: bool,
) -> str | None:
    raw = layout.get(role)
    if not isinstance(raw, list) or not all(isinstance(item, str) and item for item in raw):
        fail(f"{manifest_path}: layout.{role} must be a list of non-empty strings")
    if not raw:
        return None
    if len(raw) != 1:
        fail(
            f"{manifest_path}: status compatibility requires exactly one layout.{role} pattern; "
            f"found {len(raw)}"
        )
    value = raw[0]
    path = Path(value)
    if path.is_absolute() or value.startswith(("$", "~")) or ".." in path.parts:
        fail(f"{manifest_path}: layout.{role} must remain relative to app root: {value!r}")
    if directory:
        parent = path.parent
        if str(parent) in {"", "."}:
            fail(f"{manifest_path}: layout.{role} must declare a child directory: {value!r}")
        if any(char in str(parent) for char in GLOB_CHARS):
            fail(f"{manifest_path}: layout.{role} parent must be concrete: {value!r}")
        return str(parent)
    if any(char in value for char in GLOB_CHARS):
        fail(f"{manifest_path}: layout.{role} local path must be concrete: {value!r}")
    return value


def validate_app_authority(tool: str, entry: dict[str, Any], authority_path: Path) -> set[str]:
    manifest = load_toml(authority_path)
    if manifest.get("tool") != tool:
        fail(f"{authority_path}: tool must match status tool {tool!r}")
    if manifest.get("owner") != "dotfiles":
        fail(f"{authority_path}: owner must remain 'dotfiles'")

    layout = manifest.get("layout")
    if not isinstance(layout, dict):
        fail(f"{authority_path}: missing [layout] table")

    root = layout.get("root")
    if not isinstance(root, str) or not root:
        fail(f"{authority_path}: layout.root must be a non-empty string")

    observed: set[str] = set()
    expected_root = str(entry["root"])
    if normalized_home_path(root) != normalized_home_path(expected_root):
        observed.add("root")

    comparisons = {
        "local": single_layout_value(authority_path, layout, "local", directory=False),
        "custom": single_layout_value(authority_path, layout, "custom", directory=True),
        "adopted": single_layout_value(authority_path, layout, "adopted", directory=True),
    }
    for role, declared in comparisons.items():
        if declared != entry[role]:
            observed.add(role)
    return observed


def validate_init_authority(tool: str, entry: dict[str, Any], authority_path: Path) -> set[str]:
    manifest = load_toml(authority_path)
    if manifest.get("enabled") is not True:
        fail(f"{authority_path}: init authority must remain enabled")
    tags = manifest.get("tags")
    if not isinstance(tags, list) or tool not in tags:
        fail(f"{authority_path}: init authority tags must include {tool!r}")
    root = manifest.get("root")
    if not isinstance(root, str) or not root:
        fail(f"{authority_path}: init authority root must be a non-empty string")

    observed: set[str] = set()
    if normalized_home_path(root) != normalized_home_path(str(entry["root"])):
        observed.add("root")

    refs = entry.get("authority_refs", [])
    if not refs:
        fail(
            f"{CONTRACT}: tools.{tool}.authority_refs must provide layer evidence "
            "for init-contract status authority"
        )
    evidence = ""
    for raw in refs:
        ref = safe_repo_file(raw, label=f"tools.{tool}.authority_refs")
        evidence += "\n" + ref.read_text(encoding="utf-8")

    expected_paths = {
        "local": f"~/.config/{tool}/{entry['local']}",
        "custom": f"~/.config/{tool}/{entry['custom']}/",
        "adopted": f"~/.config/{tool}/{entry['adopted']}/",
    }
    for role, expected in expected_paths.items():
        if expected not in evidence:
            fail(
                f"{CONTRACT}: tools.{tool}.{role} lacks complete rooted layer "
                f"evidence {expected!r}"
            )
    return observed


def validate_home_manager_authority(tool: str, entry: dict[str, Any], authority_path: Path) -> set[str]:
    module = authority_path.read_text(encoding="utf-8")
    if tool != "nvim":
        fail(f"{CONTRACT}: unsupported home-manager status authority for {tool!r}")
    if 'xdg.configFile."nvim"' not in module:
        fail(f"{authority_path}: must own the Neovim XDG config tree")

    refs = entry.get("authority_refs", [])
    if not refs:
        fail(f"{CONTRACT}: tools.{tool}.authority_refs must identify runtime layer evidence")
    for raw in refs:
        ref = safe_repo_file(raw, label=f"tools.{tool}.authority_refs")
        text = ref.read_text(encoding="utf-8")
        active_lines = {
            line.strip()
            for line in text.splitlines()
            if line.strip() and not line.lstrip().startswith("--")
        }
        required_calls = {
            "local": f'source_lua_file("~/.config/nvim/{entry["local"]}")',
            "custom": f'source_lua_dir("~/.config/nvim/{entry["custom"]}")',
            "adopted": f'source_lua_dir("~/.config/nvim/{entry["adopted"]}")',
        }
        for role, expected in required_calls.items():
            if expected not in active_lines:
                fail(
                    f"{ref}: missing active exact Neovim {role} layer evidence "
                    f"{expected!r}"
                )

    # Home Manager's XDG root is environment-selectable while the Python
    # compatibility surface is hard-coded beneath $HOME/.config.
    return {"root"}


def validate_entry(tool: str, entry: Any) -> None:
    if not isinstance(entry, dict):
        fail(f"{CONTRACT}: tools.{tool} must be a table")
    allowed = {
        "root",
        "local",
        "custom",
        "adopted",
        "authority",
        "authority_path",
        "authority_refs",
        "compatibility_drift",
    }
    unknown = sorted(set(entry) - allowed)
    if unknown:
        fail(f"{CONTRACT}: tools.{tool} has unsupported fields: {', '.join(unknown)}")

    expected_root = f"$HOME/.config/{tool}"
    if entry.get("root") != expected_root:
        fail(
            f"{CONTRACT}: tools.{tool}.root must preserve Python compatibility path "
            f"{expected_root!r}"
        )

    for role in ("local", "custom", "adopted"):
        require_segment(entry, tool, role)

    authority = entry.get("authority")
    if authority not in ALLOWED_AUTHORITIES:
        allowed_values = ", ".join(sorted(ALLOWED_AUTHORITIES))
        fail(f"{CONTRACT}: tools.{tool}.authority must be one of: {allowed_values}")

    raw_authority_path = entry.get("authority_path")
    if not isinstance(raw_authority_path, str) or not raw_authority_path:
        fail(f"{CONTRACT}: tools.{tool}.authority_path must be a non-empty string")
    authority_path = safe_repo_file(raw_authority_path, label=f"tools.{tool}.authority_path")

    refs = entry.get("authority_refs", [])
    if not isinstance(refs, list) or not all(isinstance(item, str) and item for item in refs):
        fail(f"{CONTRACT}: tools.{tool}.authority_refs must be a list of non-empty strings")
    if len(refs) != len(set(refs)):
        fail(f"{CONTRACT}: tools.{tool}.authority_refs must not contain duplicates")

    drift = entry.get("compatibility_drift")
    if not isinstance(drift, list) or not all(isinstance(item, str) for item in drift):
        fail(f"{CONTRACT}: tools.{tool}.compatibility_drift must be a list of strings")
    if len(drift) != len(set(drift)):
        fail(f"{CONTRACT}: tools.{tool}.compatibility_drift must not contain duplicates")
    invalid_drift = sorted(set(drift) - ALLOWED_DRIFT)
    if invalid_drift:
        fail(f"{CONTRACT}: tools.{tool} has invalid compatibility drift roles: {', '.join(invalid_drift)}")

    if authority == "app-manifest":
        observed = validate_app_authority(tool, entry, authority_path)
    elif authority == "init-contract":
        observed = validate_init_authority(tool, entry, authority_path)
    else:
        observed = validate_home_manager_authority(tool, entry, authority_path)

    declared = set(drift)
    if observed != declared:
        fail(
            f"{CONTRACT}: tools.{tool}.compatibility_drift must exactly describe observed "
            f"authority drift; declared={sorted(declared)!r}, observed={sorted(observed)!r}"
        )


def main() -> int:
    contract = load_toml(CONTRACT)
    allowed_top = {
        "schema_version",
        "mode",
        "baseline_tools",
        "discover_app_strategies",
        "default_tool",
        "tools",
    }
    unknown_top = sorted(set(contract) - allowed_top)
    if unknown_top:
        fail(f"{CONTRACT}: unsupported top-level fields: {', '.join(unknown_top)}")
    if contract.get("schema_version") != 1:
        fail(f"{CONTRACT}: schema_version must be 1")
    if contract.get("mode") != "python-compatibility":
        fail(f"{CONTRACT}: mode must be 'python-compatibility'")

    baseline = contract.get("baseline_tools")
    if baseline != EXPECTED_BASELINE:
        fail(
            f"{CONTRACT}: baseline_tools must preserve current Python order "
            f"{EXPECTED_BASELINE!r}"
        )
    if len(baseline) != len(set(baseline)):
        fail(f"{CONTRACT}: baseline_tools must not contain duplicates")
    for tool in baseline:
        if IDENTIFIER.fullmatch(tool) is None:
            fail(f"{CONTRACT}: invalid baseline tool identifier: {tool!r}")

    if contract.get("discover_app_strategies") != ["compose"]:
        fail(f"{CONTRACT}: discover_app_strategies must be exactly ['compose']")

    default_tool = contract.get("default_tool")
    if not isinstance(default_tool, dict):
        fail(f"{CONTRACT}: [default_tool] table is required")
    expected_default = {
        "tool_name_pattern": r"^[a-z][a-z0-9_.-]*$",
        "root_template": "$HOME/.config/{tool}",
        "local": "local",
        "custom": "custom.d",
        "adopted": "adopted.d",
    }
    if set(default_tool) != set(expected_default):
        fail(
            f"{CONTRACT}: default_tool fields must be exactly "
            f"{sorted(expected_default)!r}"
        )
    for key, expected in expected_default.items():
        if default_tool.get(key) != expected:
            fail(f"{CONTRACT}: default_tool.{key} must be {expected!r}")
    for role in ("local", "custom", "adopted"):
        require_segment(default_tool, "default_tool", role)

    tools = contract.get("tools")
    if not isinstance(tools, dict):
        fail(f"{CONTRACT}: [tools] tables are required")
    if set(tools) != set(baseline):
        missing = sorted(set(baseline) - set(tools))
        extra = sorted(set(tools) - set(baseline))
        fail(f"{CONTRACT}: tool tables must exactly match baseline; missing={missing!r}, extra={extra!r}")

    for tool in baseline:
        validate_entry(tool, tools[tool])

    print(f"validated configctl status compatibility contract: {CONTRACT.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
