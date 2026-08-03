#!/usr/bin/env python3
"""Compare Home Manager profile evaluation cost without realizing outputs.

This script intentionally measures evaluation only. It invokes the existing
benchmark harness once per tracked Home Manager profile, preserves each complete
JSON result, and writes a compact aggregate suitable for attaching to an issue.
"""

from __future__ import annotations

import argparse
import json
import statistics
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Sequence

DEFAULT_PROFILES = (
    "verify",
    "headless",
    "wsl",
    "technetium",
    "dubnium",
    "meeting-verify",
)
MAX_REPEAT = 20


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare evaluation cost across tracked Home Manager profiles",
    )
    parser.add_argument(
        "--flake-dir",
        type=Path,
        default=Path("."),
        help="tracked dotfiles flake directory",
    )
    parser.add_argument(
        "--repeat",
        type=int,
        default=3,
        help=f"evaluation samples per profile (1-{MAX_REPEAT})",
    )
    parser.add_argument(
        "--profile",
        action="append",
        dest="profiles",
        help="profile name to measure; may be repeated",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("benchmark-results/home-profile-evaluation"),
        help="directory for individual and aggregate JSON results",
    )
    return parser.parse_args(argv)


def validate(args: argparse.Namespace) -> str | None:
    if not args.flake_dir.is_dir():
        return "--flake-dir must be an existing directory"
    if args.repeat < 1 or args.repeat > MAX_REPEAT:
        return f"--repeat must be between 1 and {MAX_REPEAT}"
    profiles = args.profiles or DEFAULT_PROFILES
    if not profiles:
        return "at least one profile is required"
    for profile in profiles:
        if not profile or any(character not in "abcdefghijklmnopqrstuvwxyz0123456789-" for character in profile):
            return f"invalid profile name: {profile!r}"
    return None


def target_for(profile: str) -> str:
    return f'.#homeConfigurations."ryjen@{profile}".activationPackage'


def run_profile(
    *,
    flake_dir: Path,
    profile: str,
    repeat: int,
    result_path: Path,
) -> dict[str, Any]:
    command = [
        sys.executable,
        str(flake_dir / "scripts" / "benchmark-nix-build.py"),
        "build",
        "--flake-dir",
        str(flake_dir),
        "--target",
        target_for(profile),
        "--repeat",
        str(repeat),
        "--json",
        str(result_path),
    ]
    completed = subprocess.run(
        command,
        cwd=flake_dir,
        text=True,
        stdout=subprocess.PIPE,
        stderr=None,
        check=False,
    )
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(
            f"benchmark output for {profile} was not valid JSON: {error}"
        ) from error
    if completed.returncode != 0:
        raise RuntimeError(
            f"benchmark failed for {profile} with exit code {completed.returncode}"
        )
    return payload


def evaluation_values(result: dict[str, Any]) -> list[float]:
    values = [
        float(sample["elapsed_seconds"])
        for sample in result.get("samples", [])
        if sample.get("phase") == "evaluate" and sample.get("exit_code") == 0
    ]
    if not values:
        raise RuntimeError("benchmark result contained no successful evaluation samples")
    return values


def compact_profile_result(profile: str, result: dict[str, Any]) -> dict[str, Any]:
    values = evaluation_values(result)
    return {
        "profile": profile,
        "target": result.get("target"),
        "count": len(values),
        "samples_seconds": values,
        "median_seconds": round(statistics.median(values), 6),
        "min_seconds": round(min(values), 6),
        "max_seconds": round(max(values), 6),
    }


def atomic_write(path: Path, payload: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            temporary.write(payload)
        temporary_path.replace(path)
    except OSError:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
        raise


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    error = validate(args)
    if error is not None:
        print(error, file=sys.stderr)
        return 64

    flake_dir = args.flake_dir.resolve()
    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = flake_dir / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    profiles = tuple(dict.fromkeys(args.profiles or DEFAULT_PROFILES))
    compact_results: list[dict[str, Any]] = []
    shared_metadata: dict[str, Any] | None = None

    try:
        for profile in profiles:
            result_path = output_dir / f"{profile}.json"
            result = run_profile(
                flake_dir=flake_dir,
                profile=profile,
                repeat=args.repeat,
                result_path=result_path,
            )
            compact_results.append(compact_profile_result(profile, result))
            if shared_metadata is None:
                shared_metadata = {
                    "schema_version": result.get("schema_version"),
                    "timestamp_utc": result.get("timestamp_utc"),
                    "repository": result.get("repository"),
                    "nix": result.get("nix"),
                    "host": result.get("host"),
                }
    except (OSError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        return 1

    ranked = sorted(compact_results, key=lambda item: item["median_seconds"])
    fastest = ranked[0]["median_seconds"]
    for item in ranked:
        item["delta_from_fastest_seconds"] = round(
            item["median_seconds"] - fastest,
            6,
        )

    aggregate = {
        "schema_version": 1,
        "kind": "home-profile-evaluation-comparison",
        "repeat": args.repeat,
        "profiles": ranked,
        "metadata": shared_metadata,
    }
    payload = json.dumps(aggregate, indent=2, sort_keys=True) + "\n"
    try:
        atomic_write(output_dir / "summary.json", payload)
    except OSError as error:
        print(f"unable to write aggregate result: {error}", file=sys.stderr)
        return 73

    sys.stdout.write(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
