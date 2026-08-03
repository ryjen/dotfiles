#!/usr/bin/env python3
"""Benchmark Nix evaluation, realization, and optional activation phases.

The harness is non-destructive by default. It never garbage-collects, deletes
store paths, mutates configuration, or activates a Home Manager generation
unless the caller explicitly selects the ``activate`` phase.

Stdout is reserved for the final JSON document. Child process diagnostics are
written to stderr so results remain safe to pipe to tools such as ``jq``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import statistics
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass, replace
from pathlib import Path
from typing import Any, Sequence

DEFAULT_TARGET = '.#homeConfigurations."ryjen@dubnium".activationPackage'
MAX_REPEAT = 20


@dataclass(frozen=True)
class Sample:
    phase: str
    iteration: int
    elapsed_seconds: float
    exit_code: int


@dataclass(frozen=True)
class Measurement:
    sample: Sample
    stdout: str


def run(
    command: Sequence[str],
    *,
    cwd: Path,
    capture_stderr: bool = False,
    check: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Run a command while keeping stdout out of the benchmark JSON stream."""
    return subprocess.run(
        list(command),
        cwd=cwd,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE if capture_stderr else None,
        env=os.environ.copy(),
    )


def capture_status(
    command: Sequence[str],
    *,
    cwd: Path,
) -> tuple[bool, str | None]:
    try:
        completed = run(command, cwd=cwd, capture_stderr=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return False, None
    return True, completed.stdout.strip()


def capture(command: Sequence[str], *, cwd: Path) -> str | None:
    succeeded, value = capture_status(command, cwd=cwd)
    if not succeeded or not value:
        return None
    return value


def repository_metadata(cwd: Path) -> dict[str, Any]:
    revision_available, revision = capture_status(
        ["git", "rev-parse", "HEAD"],
        cwd=cwd,
    )
    status_available, dirty_output = capture_status(
        ["git", "status", "--porcelain"],
        cwd=cwd,
    )
    return {
        "available": revision_available and status_available,
        "revision": revision if revision_available and revision else None,
        "dirty": bool(dirty_output) if status_available else None,
    }


def unwrap_nix_setting(value: Any) -> Any:
    if isinstance(value, dict) and "value" in value:
        return value["value"]
    return value


def substituter_fingerprint(value: Any) -> dict[str, Any]:
    value = unwrap_nix_setting(value)
    if isinstance(value, str):
        substituters = value.split()
    elif isinstance(value, list):
        substituters = [str(item) for item in value]
    elif value is None:
        substituters = []
    else:
        substituters = [str(value)]

    normalized = "\0".join(sorted(substituters)).encode("utf-8")
    return {
        "count": len(substituters),
        "sha256": hashlib.sha256(normalized).hexdigest(),
    }


def read_nix_config(cwd: Path) -> dict[str, Any] | None:
    commands = (
        ["nix", "config", "show", "--json"],
        ["nix", "show-config", "--json"],
    )
    for command in commands:
        try:
            completed = run(command, cwd=cwd, capture_stderr=True, check=True)
            raw = json.loads(completed.stdout)
        except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
            continue
        if isinstance(raw, dict):
            return raw
    return None


def nix_metadata(cwd: Path) -> dict[str, Any]:
    raw = read_nix_config(cwd)
    if raw is None:
        settings: dict[str, Any] = {
            "available": False,
            "max-jobs": None,
            "cores": None,
            "max-substitution-jobs": None,
            "substituters": None,
        }
    else:
        settings = {
            "available": True,
            "max-jobs": unwrap_nix_setting(raw.get("max-jobs")),
            "cores": unwrap_nix_setting(raw.get("cores")),
            "max-substitution-jobs": unwrap_nix_setting(
                raw.get("max-substitution-jobs")
            ),
            # Preserve comparability without exposing cache URLs or credentials.
            "substituters": substituter_fingerprint(raw.get("substituters")),
        }

    return {
        "version": capture(["nix", "--version"], cwd=cwd),
        "settings": settings,
    }


def timed_command(
    phase: str,
    iteration: int,
    command: Sequence[str],
    *,
    cwd: Path,
) -> Measurement:
    started = time.perf_counter()
    stdout = ""
    try:
        completed = run(command, cwd=cwd)
        exit_code = completed.returncode
        stdout = completed.stdout
    except OSError as error:
        print(f"failed to execute {command[0]}: {error}", file=sys.stderr)
        exit_code = 127
    elapsed = time.perf_counter() - started
    return Measurement(
        sample=Sample(
            phase=phase,
            iteration=iteration,
            elapsed_seconds=round(elapsed, 6),
            exit_code=exit_code,
        ),
        stdout=stdout,
    )


def evaluation_command(target: str) -> list[str]:
    return ["nix", "eval", "--raw", f"{target}.drvPath"]


def plan_command(drv_path: str) -> list[str]:
    return ["nix-store", "--realise", "--dry-run", drv_path]


def realization_command(drv_path: str) -> list[str]:
    return ["nix-store", "--realise", drv_path]


def evaluate_target(
    target: str,
    iteration: int,
    *,
    cwd: Path,
    phase: str = "evaluate",
) -> tuple[Sample, str | None]:
    measurement = timed_command(
        phase,
        iteration,
        evaluation_command(target),
        cwd=cwd,
    )
    sample = measurement.sample
    if sample.exit_code != 0:
        return sample, None

    values = [line.strip() for line in measurement.stdout.splitlines() if line.strip()]
    if (
        len(values) != 1
        or not values[0].startswith("/nix/store/")
        or not values[0].endswith(".drv")
    ):
        print("Nix evaluation did not return exactly one derivation path", file=sys.stderr)
        return replace(sample, exit_code=65), None
    return sample, values[0]


def parse_output_paths(stdout: str) -> list[str]:
    return [
        line.strip()
        for line in stdout.splitlines()
        if line.strip().startswith("/nix/store/")
    ]


def realize_drv(
    drv_path: str,
    iteration: int,
    *,
    cwd: Path,
) -> tuple[Sample, list[str]]:
    measurement = timed_command(
        "realize",
        iteration,
        realization_command(drv_path),
        cwd=cwd,
    )
    sample = measurement.sample
    if sample.exit_code != 0:
        return sample, []
    output_paths = parse_output_paths(measurement.stdout)
    if not output_paths:
        print("Nix realization returned no output paths", file=sys.stderr)
        return replace(sample, exit_code=66), []
    return sample, output_paths


def benchmark_build(target: str, repeat: int, *, cwd: Path) -> list[Sample]:
    samples: list[Sample] = []
    for iteration in range(1, repeat + 1):
        evaluate_sample, drv_path = evaluate_target(target, iteration, cwd=cwd)
        samples.append(evaluate_sample)
        if drv_path is None:
            break
        realize_sample, _ = realize_drv(drv_path, iteration, cwd=cwd)
        samples.append(realize_sample)
        if realize_sample.exit_code != 0:
            break
    return samples


def benchmark_plan(target: str, repeat: int, *, cwd: Path) -> list[Sample]:
    samples: list[Sample] = []
    for iteration in range(1, repeat + 1):
        evaluate_sample, drv_path = evaluate_target(
            target,
            iteration,
            cwd=cwd,
            phase="plan-evaluate",
        )
        samples.append(evaluate_sample)
        if drv_path is None:
            break
        plan_sample = timed_command(
            "plan",
            iteration,
            plan_command(drv_path),
            cwd=cwd,
        ).sample
        samples.append(plan_sample)
        if plan_sample.exit_code != 0:
            break
    return samples


def benchmark_activation(target: str, repeat: int, *, cwd: Path) -> list[Sample]:
    samples: list[Sample] = []
    evaluate_sample, drv_path = evaluate_target(target, 1, cwd=cwd)
    samples.append(evaluate_sample)
    if drv_path is None:
        return samples

    realize_sample, output_paths = realize_drv(drv_path, 1, cwd=cwd)
    samples.append(realize_sample)
    if realize_sample.exit_code != 0:
        return samples
    if len(output_paths) != 1:
        print("activation package must have exactly one output path", file=sys.stderr)
        samples.append(Sample("activate", 1, 0.0, 66))
        return samples

    activation_program = Path(output_paths[0]) / "activate"
    if not activation_program.is_file():
        print(
            f"activation program not found beneath realized output: {activation_program.name}",
            file=sys.stderr,
        )
        samples.append(Sample("activate", 1, 0.0, 66))
        return samples

    for iteration in range(1, repeat + 1):
        activation_sample = timed_command(
            "activate",
            iteration,
            [str(activation_program)],
            cwd=cwd,
        ).sample
        samples.append(activation_sample)
        if activation_sample.exit_code != 0:
            break
    return samples


def summarize(samples: Sequence[Sample]) -> dict[str, Any]:
    grouped: dict[str, list[float]] = {}
    for sample in samples:
        if sample.exit_code == 0:
            grouped.setdefault(sample.phase, []).append(sample.elapsed_seconds)

    return {
        phase: {
            "count": len(values),
            "median_seconds": round(statistics.median(values), 6),
            "min_seconds": round(min(values), 6),
            "max_seconds": round(max(values), 6),
        }
        for phase, values in grouped.items()
    }


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark Dubnium Nix evaluation, realization, and activation",
    )
    parser.add_argument(
        "phase",
        choices=("plan", "build", "activate", "suite"),
        help="phase to benchmark; activation is explicit and may change user state",
    )
    parser.add_argument(
        "--target",
        default=DEFAULT_TARGET,
        help=f"local flake target (default: {DEFAULT_TARGET})",
    )
    parser.add_argument(
        "--flake-dir",
        type=Path,
        default=Path("."),
        help="tracked local flake directory used for commands and provenance",
    )
    parser.add_argument(
        "--repeat",
        type=int,
        default=None,
        help="sample count; defaults to 1 for activate and 3 otherwise",
    )
    parser.add_argument(
        "--json",
        dest="json_path",
        type=Path,
        help="write the complete result as JSON",
    )
    parser.add_argument(
        "--include-hostname",
        action="store_true",
        help="include the literal hostname in output; omitted by default",
    )
    return parser.parse_args(argv)


def effective_repeat(args: argparse.Namespace) -> int:
    if args.repeat is not None:
        return args.repeat
    return 1 if args.phase == "activate" else 3


def validate_args(args: argparse.Namespace, repeat: int) -> str | None:
    if repeat < 1 or repeat > MAX_REPEAT:
        return f"--repeat must be between 1 and {MAX_REPEAT}"
    if not args.target.startswith(".#"):
        return "--target must identify an output in --flake-dir and begin with '.#'"
    if not args.flake_dir.is_dir():
        return "--flake-dir must be an existing directory"
    return None


def atomic_write_json(path: Path, payload: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
        delete=False,
    ) as temporary:
        temporary.write(payload)
        temporary_path = Path(temporary.name)
    try:
        temporary_path.replace(path)
    except OSError:
        temporary_path.unlink(missing_ok=True)
        raise


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repeat = effective_repeat(args)
    error = validate_args(args, repeat)
    if error is not None:
        print(error, file=sys.stderr)
        return 64

    cwd = args.flake_dir.resolve()
    samples: list[Sample] = []
    if args.phase in ("plan", "suite"):
        plan_repeat = 1 if args.phase == "suite" else repeat
        samples.extend(benchmark_plan(args.target, plan_repeat, cwd=cwd))
    if args.phase in ("build", "suite") and all(s.exit_code == 0 for s in samples):
        samples.extend(benchmark_build(args.target, repeat, cwd=cwd))
    if args.phase == "activate":
        samples.extend(benchmark_activation(args.target, repeat, cwd=cwd))

    host: dict[str, Any] = {
        "platform": platform.platform(),
        "machine": platform.machine(),
        "cpu_count": os.cpu_count(),
    }
    if args.include_hostname:
        host["hostname"] = platform.node()

    result = {
        "schema_version": 2,
        "target": args.target,
        "target_bound_to_repository": True,
        "requested_phase": args.phase,
        "repeat": repeat,
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "host": host,
        "repository": repository_metadata(cwd),
        "nix": nix_metadata(cwd),
        "samples": [asdict(sample) for sample in samples],
        "summary": summarize(samples),
    }

    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    output_error = False
    if args.json_path is not None:
        try:
            atomic_write_json(args.json_path, payload)
        except OSError as error:
            print(f"unable to write JSON result: {error}", file=sys.stderr)
            output_error = True

    # Keep stdout machine-readable even when child commands or file writes fail.
    sys.stdout.write(payload)

    if output_error:
        return 73
    return 0 if samples and all(sample.exit_code == 0 for sample in samples) else 1


if __name__ == "__main__":
    raise SystemExit(main())
