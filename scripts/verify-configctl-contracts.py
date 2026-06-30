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
        if kind == "codex-config":
            validate_codex_config(path, contract)
        elif kind == "npm-globals":
            validate_npm_globals(path, contract)
        elif kind == "pip-globals":
            validate_pip_globals(path, contract)
        elif kind == "skill-deployment":
            validate_skill_deployment(path, contract)
        if enabled:
            active_contracts += 1

    if active_contracts == 0:
        fail("expected at least one enabled init contract")

    print(f"validated {len(seen_ids)} configctl init contract(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
