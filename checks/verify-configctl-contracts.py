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

validator.SUPPORTED_ACTIVE_KINDS.add("hermes-config")
original_validate_common = validator.validate_common


def validate_hermes_config(path: Path, contract: dict[str, Any]) -> None:
    expected_strings = {
        "root": "$XDG_CONFIG_HOME/hermes",
        "output": "$HOME/.hermes/config.toml",
        "localProviderName": "local",
        "localBaseUrl": "http://127.0.0.1:8000/v1",
        "localModel": "dubnium-local",
    }
    for key, expected in expected_strings.items():
        value = validator.require_type(contract, path, key, str)
        if value != expected:
            validator.fail(f"{path}: {key} must be {expected!r}")

    if set(contract["risk"]) != {"mutable-user-state"}:
        validator.fail(f"{path}: hermes-config risk must be exactly mutable-user-state")


def validate_common(
    path: Path,
    contract: dict[str, Any],
    seen_ids: set[str],
) -> tuple[str, str, bool]:
    result = original_validate_common(path, contract, seen_ids)
    if result[1] == "hermes-config":
        validate_hermes_config(path, contract)
    return result


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
        value = layout.get(role)
        if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
            validator.fail(f"{path}: layout.{role} must be a list of strings")

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

    return path, contract


def validate_compose_app(tool: str, parser: str) -> None:
    path, contract = load_music_app(tool)
    if contract.get("status") != "planned" or contract.get("strategy") != "compose":
        validator.fail(f"{path}: {tool} must be a planned compose contract")
    if contract.get("target_runtime_owner") != "configctl":
        validator.fail(f"{path}: target_runtime_owner must be 'configctl'")
    if contract.get("renderer_required") is not True:
        validator.fail(f"{path}: renderer_required must be true")

    composition = contract.get("composition")
    if not isinstance(composition, dict):
        validator.fail(f"{path}: missing [composition] table")
    if composition.get("write_mode") != "atomic" or composition.get("dry_run_required") is not True:
        validator.fail(f"{path}: composition must require atomic writes and dry-run")
    if parser not in composition.get("requires_parser", []):
        validator.fail(f"{path}: composition.requires_parser must include {parser!r}")


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
    if mpd["layout"].get("runtime_includes") != ["custom.d/*.conf", "local.conf"]:
        validator.fail(f"{path}: runtime_includes must load custom overrides then local.conf")

    validate_compose_app("rmpc", "ron")
    validate_compose_app("beets", "yaml")


validator.validate_common = validate_common
legacy_result = validator.main()
if legacy_result != 0:
    raise SystemExit(legacy_result)
validate_music_apps()
print("validated managed-music configctl app contracts")
raise SystemExit(0)
