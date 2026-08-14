#!/usr/bin/env python3
"""Extend configctl contract validation with Hermes and managed-music app contracts."""

from __future__ import annotations

import importlib.util
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else Path.cwd().resolve()
LEGACY_VALIDATOR = REPO_ROOT / "scripts" / "verify-configctl-contracts.py"
APP_DIR = REPO_ROOT / "contracts" / "configctl" / "apps"

spec = importlib.util.spec_from_file_location("configctl_contracts", LEGACY_VALIDATOR)
if spec is None or spec.loader is None:
    raise SystemExit(f"unable to load configctl validator: {LEGACY_VALIDATOR}")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)

validator.SUPPORTED_ACTIVE_KINDS.add("hermes")
original_validate_common = validator.validate_common


def validate_hermes(path: Path, contract: dict[str, Any]) -> None:
    expected_strings = {
        "home": "$HOME/.hermes",
        "configDir": "$XDG_CONFIG_HOME/hermes",
        "configFile": "$XDG_CONFIG_HOME/hermes/local.yaml",
    }
    for key, expected in expected_strings.items():
        value = validator.require_type(contract, path, key, str)
        if value != expected:
            validator.fail(f"{path}: {key} must be {expected!r}")

    if set(contract["risk"]) != {"mutable-user-state"}:
        validator.fail(f"{path}: hermes risk must be exactly mutable-user-state")

    behavior = contract.get("behavior")
    if not isinstance(behavior, dict):
        validator.fail(f"{path}: missing [behavior] table")
    if set(behavior) != {"createMissing"}:
        validator.fail(f"{path}: hermes behavior may contain only createMissing")
    if behavior.get("createMissing") is not True:
        validator.fail(f"{path}: [behavior].createMissing must be true")


def validate_common(
    path: Path,
    contract: dict[str, Any],
    seen_ids: set[str],
) -> tuple[str, str, bool]:
    result = original_validate_common(path, contract, seen_ids)
    if result[1] == "hermes":
        validate_hermes(path, contract)
    return result


def require_string_role(path: Path, layout: dict[str, Any], role: str, *, required: bool = True) -> list[str]:
    value = layout.get(role)
    if value is None and not required:
        return []
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        validator.fail(f"{path}: layout.{role} must be a list of strings")
    return value


def load_music_app(tool: str) -> tuple[Path, dict[str, Any]]:
    path = APP_DIR / f"{tool}.toml"
    if not path.is_file():
        validator.fail(f"missing managed-music app contract: {path.relative_to(REPO_ROOT)}")
    try:
        contract = tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as exc:
        validator.fail(f"{path}: invalid TOML: {exc}")

    expected_top = {
        "schema_version": 1,
        "tool": tool,
        "owner": "dotfiles",
        "profile": "dubnium",
        "executor_may_validate": True,
        "executor_may_adopt": True,
        "executor_may_write_outputs": False,
    }
    for key, expected in expected_top.items():
        if contract.get(key) != expected:
            validator.fail(f"{path}: {key} must be {expected!r}")

    layout = contract.get("layout")
    if not isinstance(layout, dict):
        validator.fail(f"{path}: missing [layout] table")
    if layout.get("standard") != "configctl-v1":
        validator.fail(f"{path}: layout.standard must be 'configctl-v1'")

    for role in ("source_inputs", "local", "custom", "adopted"):
        require_string_role(path, layout, role)
    require_string_role(path, layout, "promoted_inputs", required=False)
    require_string_role(path, layout, "auxiliary_outputs", required=False)

    adoption = contract.get("adoption")
    if not isinstance(adoption, dict):
        validator.fail(f"{path}: missing [adoption] table")
    if adoption.get("hash_algorithm") != "sha256" or adoption.get("mode") != "review-gated":
        validator.fail(f"{path}: adoption must use sha256 and review-gated mode")
    ignored = adoption.get("ignore")
    if not isinstance(ignored, list) or not all(isinstance(item, str) for item in ignored):
        validator.fail(f"{path}: adoption.ignore must be a list of role names")

    for source in layout["source_inputs"]:
        if source.startswith(("~", "$")) or "*" in source:
            continue
        if not (REPO_ROOT / source).exists():
            validator.fail(f"{path}: source input does not exist: {source}")

    for promoted in layout.get("promoted_inputs", []):
        if not promoted.startswith(f"files/home/.config/{tool}/custom.d/dubnium/"):
            validator.fail(
                f"{path}: promoted_inputs must stay under the profile-scoped configctl promote destination"
            )
        if "*" not in promoted:
            validator.fail(f"{path}: promoted_inputs must use a bounded fragment glob")

    return path, contract


def validate_compose_app(
    tool: str,
    parser: str,
    *,
    expected_promoted: str,
    expected_source_order: list[str],
) -> None:
    path, contract = load_music_app(tool)
    if contract.get("status") != "planned" or contract.get("strategy") != "compose":
        validator.fail(f"{path}: {tool} must be a planned compose contract")
    if contract.get("target_runtime_owner") != "configctl":
        validator.fail(f"{path}: target_runtime_owner must be 'configctl'")
    if contract.get("renderer_required") is not True:
        validator.fail(f"{path}: renderer_required must be true")

    layout = contract["layout"]
    if layout.get("promoted_inputs") != [expected_promoted]:
        validator.fail(
            f"{path}: promoted_inputs must exactly match configctl promote output {expected_promoted!r}"
        )

    composition = contract.get("composition")
    if not isinstance(composition, dict):
        validator.fail(f"{path}: missing [composition] table")
    if composition.get("write_mode") != "atomic" or composition.get("dry_run_required") is not True:
        validator.fail(f"{path}: composition must require atomic writes and dry-run")
    if parser not in composition.get("requires_parser", []):
        validator.fail(f"{path}: composition.requires_parser must include {parser!r}")
    if composition.get("source_order") != expected_source_order:
        validator.fail(
            f"{path}: source_order must preserve base/adopted, managed, promoted, local, then live custom precedence"
        )


def validate_music_apps() -> None:
    path, mpd = load_music_app("mpd")
    if mpd.get("status") != "active" or mpd.get("strategy") != "native-include":
        validator.fail(f"{path}: MPD must be an active native-include contract")
    if mpd.get("current_runtime_owner") != "home-manager":
        validator.fail(f"{path}: current_runtime_owner must be 'home-manager'")
    if mpd.get("target_runtime_owner") != "home-manager":
        validator.fail(f"{path}: target_runtime_owner must remain 'home-manager'")
    if mpd.get("renderer_required") is not False:
        validator.fail(f"{path}: renderer_required must be false")

    expected_includes = [
        "custom.d/dubnium/*.conf",
        "custom.d/*.conf",
        "local.conf",
    ]
    if mpd["layout"].get("runtime_includes") != expected_includes:
        validator.fail(
            f"{path}: runtime_includes must load promoted profile, live custom, then local overrides"
        )

    validate_compose_app(
        "rmpc",
        "ron",
        expected_promoted="files/home/.config/rmpc/custom.d/dubnium/*.ron",
        expected_source_order=["source_inputs", "promoted_inputs", "local", "custom"],
    )
    validate_compose_app(
        "beets",
        "yaml",
        expected_promoted="files/home/.config/beets/custom.d/dubnium/*.yaml",
        expected_source_order=["adopted", "auxiliary_outputs", "promoted_inputs", "local", "custom"],
    )


validator.validate_common = validate_common
legacy_result = validator.main()
if legacy_result != 0:
    raise SystemExit(legacy_result)
validate_music_apps()
print("validated managed-music configctl app contracts")
raise SystemExit(0)
