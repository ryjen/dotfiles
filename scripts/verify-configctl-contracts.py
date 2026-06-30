#!/usr/bin/env python3
"""Validate dotfiles-owned configctl contract manifests.

This intentionally validates the repository contract surface only. The Dubnium
`configctl` executor owns runtime status, planning, apply, and verification.
"""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
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
    "npm-globals",
}


def fail(message: str) -> None:
    print(f"configctl-contracts: {message}", file=sys.stderr)
    raise SystemExit(1)


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


def validate_npm_globals(path: Path, contract: dict[str, Any]) -> None:
    manifest = require_type(contract, path, "manifest", str)
    prefix = require_type(contract, path, "prefix", str)
    bin_path = require_type(contract, path, "bin", str)

    expected_prefix = "$HOME/.local/share/npm"
    expected_bin = "$HOME/.local/share/npm/bin"
    if prefix != expected_prefix:
        fail(f"{path}: prefix must match Home Manager npm prefix {expected_prefix!r}")
    if bin_path != expected_bin:
        fail(f"{path}: bin must match Home Manager npm bin path {expected_bin!r}")

    source_manifest = managed_home_path(manifest)
    if source_manifest is None:
        fail(f"{path}: manifest must be a managed $HOME-relative path")
    if not source_manifest.is_file():
        fail(f"{path}: referenced manifest does not exist: {source_manifest.relative_to(ROOT)}")

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

    risks = set(contract["risk"])
    required = {"network", "mutable-user-state"}
    missing = sorted(required - risks)
    if missing:
        fail(f"{path}: npm-globals missing required risks: {', '.join(missing)}")


def main() -> int:
    if not INIT_DIR.is_dir():
        fail(f"missing init contract directory: {INIT_DIR.relative_to(ROOT)}")

    seen_ids: set[str] = set()
    active_contracts = 0

    for path in sorted(INIT_DIR.glob("*.toml")):
        try:
            contract = tomllib.loads(path.read_text(encoding="utf-8"))
        except tomllib.TOMLDecodeError as exc:
            fail(f"{path}: invalid TOML: {exc}")

        _contract_id, kind, enabled = validate_common(path, contract, seen_ids)
        if kind == "npm-globals":
            validate_npm_globals(path, contract)
        if enabled:
            active_contracts += 1

    if active_contracts == 0:
        fail("expected at least one enabled init contract")

    print(f"validated {len(seen_ids)} configctl init contract(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
