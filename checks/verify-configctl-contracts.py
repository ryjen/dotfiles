#!/usr/bin/env python3
"""Extend configctl contract validation with the Hermes contract."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else Path.cwd().resolve()
LEGACY_VALIDATOR = REPO_ROOT / "scripts" / "verify-configctl-contracts.py"

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


validator.validate_common = validate_common
raise SystemExit(validator.main())
