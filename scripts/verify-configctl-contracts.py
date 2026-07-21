#!/usr/bin/env python3
"""Validate dotfiles-owned configctl contract manifests.

This intentionally validates the repository contract surface only. The Dubnium
`configctl` executor owns runtime status, planning, apply, and verification.
"""

from __future__ import annotations

import configparser
import json
import sys
import tomllib
from pathlib import Path
from typing import Any


def fail(message: str) -> None:
    print(f"configctl-contracts: {message}", file=sys.stderr)
    raise SystemExit(1)


def repo_root() -> Path:
    if len(sys.argv) > 2:
        fail("usage: verify-configctl-contracts.py [repo-root]")
    if len(sys.argv) == 2:
        return Path(sys.argv[1]).resolve()
    return Path.cwd().resolve()


ROOT = repo_root()
INIT_DIR = ROOT / "contracts" / "configctl" / "init"
FILES_HOME = ROOT / "files" / "home"

SUPPORTED_RISKS = {
    "network",
    "mutable-user-state",
    "auth-required",
    "destructive",
    "arbitrary-code",
    "privileged",
}

SUPPORTED_ACTIVE_KINDS = {
    "codex-config",
    "npm-globals",
    "pip-globals",
    "skill-deployment",
    "task-config",
    "obs-presentation",
    "uv-tools",
}

OBS_PATHS = {
    "templateProfile": "$XDG_DATA_HOME/dubnium/obs/v1/profile",
    "templateCollection": "$XDG_DATA_HOME/dubnium/obs/v1/scene-collection.json",
    "settings": "$XDG_CONFIG_HOME/dubnium/meeting/obs-init.json",
    "profileTarget": "$XDG_CONFIG_HOME/obs-studio/basic/profiles/Dubnium Presentation",
    "collectionTarget": "$XDG_CONFIG_HOME/obs-studio/basic/scenes/Dubnium Meeting Presentation.json",
}

OBS_NAMES = {
    "profileName": "Dubnium Presentation",
    "collectionName": "Dubnium Meeting Presentation",
}

OBS_BEHAVIOR = {
    "createIfMissing": True,
    "replace": False,
    "backupBeforeReplace": True,
    "atomicWrite": True,
    "refuseWhileObsRunning": True,
}

OBS_FIELDS = {
    "schemaVersion",
    "id",
    "kind",
    "enabled",
    "risk",
    "profile",
    "tags",
    "description",
    "dependsOn",
    *OBS_PATHS,
    *OBS_NAMES,
    "behavior",
}


def require_type(contract: dict[str, Any], path: Path, key: str, expected: type) -> Any:
    if key not in contract:
        fail(f"{path}: missing required field {key!r}")
    value = contract[key]
    if not isinstance(value, expected):
        fail(f"{path}: field {key!r} must be {expected.__name__}")
    return value


def managed_home_path(value: str) -> Path | None:
    if value.startswith("$HOME/"):
        return FILES_HOME / value.removeprefix("$HOME/")
    if value.startswith("~/"):
        return FILES_HOME / value.removeprefix("~/")
    return None


def validate_common(path: Path, contract: dict[str, Any], seen_ids: set[str]) -> tuple[str, str, bool]:
    schema_version = require_type(contract, path, "schemaVersion", int)
    if schema_version != 1:
        fail(f"{path}: unsupported schemaVersion {schema_version!r}")

    contract_id = require_type(contract, path, "id", str)
    if not contract_id:
        fail(f"{path}: id must not be empty")
    if contract_id in seen_ids:
        fail(f"{path}: duplicate contract id {contract_id!r}")
    seen_ids.add(contract_id)

    kind = require_type(contract, path, "kind", str)
    enabled = require_type(contract, path, "enabled", bool)
    risks = require_type(contract, path, "risk", list)
    if not all(isinstance(risk, str) for risk in risks):
        fail(f"{path}: risk entries must be strings")
    unknown_risks = sorted(set(risks) - SUPPORTED_RISKS)
    if unknown_risks:
        fail(f"{path}: unsupported risk labels: {', '.join(unknown_risks)}")

    if enabled and kind not in SUPPORTED_ACTIVE_KINDS:
        fail(
            f"{path}: enabled init contract kind {kind!r} has no active dotfiles validation rule"
        )

    return contract_id, kind, enabled


def validate_package_globals(
    path: Path,
    contract: dict[str, Any],
    *,
    tool: str,
    expected_prefix: str,
    expected_bin: str,
    required_risks: set[str],
) -> None:
    manifest = require_type(contract, path, "manifest", str)
    prefix = require_type(contract, path, "prefix", str)
    bin_path = require_type(contract, path, "bin", str)

    if prefix != expected_prefix:
        fail(f"{path}: prefix must match Home Manager {tool} prefix {expected_prefix!r}")
    if bin_path != expected_bin:
        fail(f"{path}: bin must match Home Manager {tool} bin path {expected_bin!r}")

    source_manifest = managed_home_path(manifest)
    if source_manifest is None:
        fail(f"{path}: manifest must be a managed $HOME-relative path")
    if not source_manifest.is_file():
        fail(f"{path}: referenced manifest does not exist: {source_manifest.relative_to(ROOT)}")

    risks = set(contract["risk"])
    missing = sorted(required_risks - risks)
    if missing:
        fail(f"{path}: {tool} missing required risks: {', '.join(missing)}")


def validate_npm_globals(path: Path, contract: dict[str, Any]) -> None:
    validate_package_globals(
        path,
        contract,
        tool="npm-globals",
        expected_prefix="$HOME/.local/share/npm",
        expected_bin="$HOME/.local/share/npm/bin",
        required_risks={"network", "mutable-user-state"},
    )

    state = contract.get("state")
    if not isinstance(state, dict):
        fail(f"{path}: missing [state] table")
    for key in ("trackDesiredHash", "trackObservedHash"):
        if state.get(key) is not True:
            fail(f"{path}: [state].{key} must be true")

    behavior = contract.get("behavior")
    if not isinstance(behavior, dict):
        fail(f"{path}: missing [behavior] table")
    expected_behavior = {
        "install": True,
        "update": False,
        "prune": False,
    }
    for key, expected in expected_behavior.items():
        if behavior.get(key) is not expected:
            fail(f"{path}: [behavior].{key} must be {str(expected).lower()}")


def validate_pip_globals(path: Path, contract: dict[str, Any]) -> None:
    validate_package_globals(
        path,
        contract,
        tool="pip-globals",
        expected_prefix="$XDG_DATA_HOME/pip",
        expected_bin="$XDG_DATA_HOME/pip/bin",
        required_risks={"network", "mutable-user-state"},
    )


def validate_uv_tools(path: Path, contract: dict[str, Any]) -> None:
    manifest = require_type(contract, path, "manifest", str)
    bin_path = require_type(contract, path, "bin", str)

    if bin_path != "$HOME/.local/bin":
        fail(f"{path}: bin must match Home Manager uv tool bin path '$HOME/.local/bin'")

    source_manifest = managed_home_path(manifest)
    if source_manifest is None:
        fail(f"{path}: manifest must be a managed $HOME-relative path")
    if not source_manifest.is_file():
        fail(f"{path}: referenced manifest does not exist: {source_manifest.relative_to(ROOT)}")

    risks = set(contract["risk"])
    missing = sorted({"network", "mutable-user-state"} - risks)
    if missing:
        fail(f"{path}: uv-tools missing required risks: {', '.join(missing)}")

    state = contract.get("state")
    if not isinstance(state, dict):
        fail(f"{path}: missing [state] table")
    for key in ("trackDesiredHash", "trackObservedHash"):
        if state.get(key) is not True:
            fail(f"{path}: [state].{key} must be true")

    behavior = contract.get("behavior")
    if not isinstance(behavior, dict):
        fail(f"{path}: missing [behavior] table")
    expected_behavior = {
        "install": True,
        "update": False,
        "prune": False,
    }
    for key, expected in expected_behavior.items():
        if behavior.get(key) is not expected:
            fail(f"{path}: [behavior].{key} must be {str(expected).lower()}")

    try:
        tool_manifest = tomllib.loads(source_manifest.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as exc:
        fail(f"{source_manifest}: invalid TOML: {exc}")

    tools = tool_manifest.get("tools")
    if not isinstance(tools, list) or not tools:
        fail(f"{source_manifest}: expected at least one [[tools]] entry")

    seen_packages: set[str] = set()
    for index, tool in enumerate(tools, start=1):
        if not isinstance(tool, dict):
            fail(f"{source_manifest}: [[tools]] entry {index} must be a table")
        package = tool.get("package")
        if not isinstance(package, str) or not package.strip():
            fail(f"{source_manifest}: [[tools]] entry {index} package must be a non-empty string")
        if package in seen_packages:
            fail(f"{source_manifest}: duplicate uv tool package {package!r}")
        seen_packages.add(package)
        python = tool.get("python")
        if python is not None and not isinstance(python, str):
            fail(f"{source_manifest}: [[tools]] entry {index} python must be a string")
        extra_packages = tool.get("extraPackages")
        if extra_packages is not None:
            if not isinstance(extra_packages, list) or not all(isinstance(item, str) for item in extra_packages):
                fail(f"{source_manifest}: [[tools]] entry {index} extraPackages must be a list of strings")


def validate_codex_config(path: Path, contract: dict[str, Any]) -> None:
    root = require_type(contract, path, "root", str)
    output = require_type(contract, path, "output", str)

    if root != "$XDG_CONFIG_HOME/codex":
        fail(f"{path}: root must be '$XDG_CONFIG_HOME/codex'")
    if output != "$HOME/.codex/config.toml":
        fail(f"{path}: output must be '$HOME/.codex/config.toml'")

    risks = set(contract["risk"])
    if risks != {"mutable-user-state"}:
        fail(f"{path}: codex-config risk must be exactly mutable-user-state")


def validate_skill_deployment(path: Path, contract: dict[str, Any]) -> None:
    source = require_type(contract, path, "source", str)
    target = require_type(contract, path, "target", str)

    if Path(source).is_absolute() or source.startswith("../"):
        fail(f"{path}: source must be a repository-relative path")
    if not (ROOT / source).exists():
        fail(f"{path}: source does not exist: {source}")
    if not target.startswith(("$HOME/", "~/")):
        fail(f"{path}: target must be HOME-relative")

    if contract.get("executor_may_initialize") is not False:
        fail(f"{path}: skill-deployment contracts are documentation-only until a handler exists")

    risks = set(contract["risk"])
    if risks != {"mutable-user-state"}:
        fail(f"{path}: skill-deployment risk must be exactly mutable-user-state")


def validate_task_config(path: Path, contract: dict[str, Any]) -> None:
    root = require_type(contract, path, "root", str)
    output = require_type(contract, path, "output", str)

    if root != "$XDG_CONFIG_HOME/task":
        fail(f"{path}: root must be '$XDG_CONFIG_HOME/task'")
    if output != "$HOME/.taskrc":
        fail(f"{path}: output must be '$HOME/.taskrc'")

    risks = set(contract["risk"])
    if risks != {"mutable-user-state"}:
        fail(f"{path}: task-config risk must be exactly mutable-user-state")


def contains_key(value: Any, key: str) -> bool:
    if isinstance(value, dict):
        return key in value or any(contains_key(nested, key) for nested in value.values())
    if isinstance(value, list):
        return any(contains_key(nested, key) for nested in value)
    return False


def validate_obs_presentation(path: Path, contract: dict[str, Any]) -> None:
    unsupported = sorted(set(contract) - OBS_FIELDS)
    if unsupported:
        fail(f"{path}: unsupported obs-presentation fields: {', '.join(unsupported)}")

    if contract["risk"] != ["mutable-user-state"]:
        fail(f'{path}: obs-presentation risk must be exactly ["mutable-user-state"]')

    for field, expected in OBS_PATHS.items():
        value = require_type(contract, path, field, str)
        if value != expected:
            fail(f"{path}: {field} must be {expected!r}")
    for field, expected in OBS_NAMES.items():
        value = require_type(contract, path, field, str)
        if value != expected:
            fail(f"{path}: {field} must be {expected!r}")

    behavior = contract.get("behavior")
    if not isinstance(behavior, dict):
        fail(f"{path}: missing [behavior] table")
    unsupported = sorted(set(behavior) - set(OBS_BEHAVIOR))
    if unsupported:
        fail(f"{path}: unsupported [behavior] fields: {', '.join(unsupported)}")
    for field, expected in OBS_BEHAVIOR.items():
        if behavior.get(field) is not expected:
            fail(f"{path}: [behavior].{field} must be {str(expected).lower()}")

    template_root = FILES_HOME / ".local/share/dubnium/obs/v1"
    profile = template_root / "profile"
    collection_path = template_root / "scene-collection.json"
    if not profile.is_dir():
        fail(f"{path}: referenced templateProfile does not exist: {profile.relative_to(ROOT)}")
    if not collection_path.is_file():
        fail(
            f"{path}: referenced templateCollection does not exist: "
            f"{collection_path.relative_to(ROOT)}"
        )

    profile_path = profile / "basic.ini"
    if not profile_path.is_file():
        fail(f"{path}: templateProfile is missing basic.ini")
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    try:
        with profile_path.open(encoding="utf-8") as profile_file:
            parser.read_file(profile_file)
    except (OSError, configparser.Error) as exc:
        fail(f"{profile_path}: invalid OBS profile: {exc}")
    if parser.get("General", "Name", fallback=None) != contract["profileName"]:
        fail(f"{profile_path}: [General].Name must match profileName")

    try:
        collection = json.loads(collection_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"{collection_path}: invalid OBS scene collection JSON: {exc}")
    if not isinstance(collection, dict):
        fail(f"{collection_path}: OBS scene collection must be a JSON object")
    if collection.get("name") != contract["collectionName"]:
        fail(f"{collection_path}: collection name must match collectionName")
    sources = collection.get("sources")
    if not isinstance(sources, list):
        fail(f"{collection_path}: sources must be a list")
    cameras = [
        source
        for source in sources
        if isinstance(source, dict)
        and source.get("name") == "Camera Overlay"
        and source.get("id") == "v4l2_input"
    ]
    if len(cameras) != 1:
        fail(f"{collection_path}: expected exactly one Camera Overlay v4l2_input source")
    camera = cameras[0]
    if camera.get("settings") != {}:
        fail(f"{collection_path}: camera settings must not contain device_id or other machine-local values")
    camera_uuid = camera.get("uuid")
    if not isinstance(camera_uuid, str) or not camera_uuid:
        fail(f"{collection_path}: Camera Overlay must have a non-empty uuid")
    camera_items = [
        item
        for source in sources
        if isinstance(source, dict) and isinstance(source.get("settings"), dict)
        for item in source["settings"].get("items", [])
        if isinstance(item, dict)
        and item.get("name") == "Camera Overlay"
        and item.get("source_uuid") == camera_uuid
    ]
    if not camera_items:
        fail(f"{collection_path}: no scene item references Camera Overlay")
    if contains_key(collection, "device_id"):
        fail(f"{collection_path}: device_id keys are forbidden in the versioned scene collection")


def main() -> int:
    if not INIT_DIR.is_dir():
        fail(f"missing init contract directory: {INIT_DIR.relative_to(ROOT)}")
    obs_contract_path = INIT_DIR / "obs-presentation.toml"
    if not obs_contract_path.is_file():
        fail(f"missing required OBS presentation init contract: {obs_contract_path.relative_to(ROOT)}")

    seen_ids: set[str] = set()
    active_contracts = 0
    obs_enabled = False

    for path in sorted(INIT_DIR.glob("*.toml")):
        try:
            contract = tomllib.loads(path.read_text(encoding="utf-8"))
        except tomllib.TOMLDecodeError as exc:
            fail(f"{path}: invalid TOML: {exc}")

        _contract_id, kind, enabled = validate_common(path, contract, seen_ids)
        if kind == "codex-config":
            validate_codex_config(path, contract)
        elif kind == "npm-globals":
            validate_npm_globals(path, contract)
        elif kind == "pip-globals":
            validate_pip_globals(path, contract)
        elif kind == "uv-tools":
            validate_uv_tools(path, contract)
        elif kind == "skill-deployment":
            validate_skill_deployment(path, contract)
        elif kind == "task-config":
            validate_task_config(path, contract)
        elif kind == "obs-presentation":
            validate_obs_presentation(path, contract)
        if enabled:
            active_contracts += 1
        if path == obs_contract_path and _contract_id == "obs-presentation" and kind == "obs-presentation":
            obs_enabled = enabled

    if not obs_enabled:
        fail(f"{obs_contract_path}: OBS presentation init contract must be enabled")
    if active_contracts == 0:
        fail("expected at least one enabled init contract")

    print(f"validated {len(seen_ids)} configctl init contract(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
