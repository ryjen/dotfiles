#!/usr/bin/env python3
"""Benchmark Nix evaluation/build and optional Home Manager activation phases.

The harness is intentionally non-destructive by default: it does not garbage
collect, delete store paths, mutate configuration, or activate a generation
unless the caller explicitly selects the ``activate`` phase.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import statistics
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Sequence

DEFAULT_TARGET = '.#homeConfigurations."ryjen@dubnium".activationPackage'


@dataclass(frozen=True)
class Sample:
    phase: str
    iteration: int
    elapsed_seconds: float
    exit_code: int


def run(
    command: Sequence[str],
    *,
    capture: bool = False,
    check: bool = False,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(command),
        check=check,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
        env=os.environ.copy(),
    )


def capture(command: Sequence[str], fallback: str = "unknown") -> str:
    try:
        completed = run(command, capture=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return fallback
    return completed.stdout.strip() or fallback


def repository_metadata() -> dict[str, Any]:
    revision = capture(["git", "rev-parse", "HEAD"])
    dirty_output = capture(["git", "status", "--porcelain"], fallback="")
    return {
        "revision": revision,
        "dirty": bool(dirty_output),
    }


def nix_metadata() -> dict[str, Any]:
    settings: dict[str, str] = {}
    try:
        completed = run(["nix", "show-config", "--json"], capture=True, check=True)
        raw = json.loads(completed.stdout)
        for key in ("max-jobs", "cores", "max-substitution-jobs", "substituters"):
            value = raw.get(key)
            if isinstance(value, dict) and "value" in value:
                settings[key] = str(value["value"])
            elif value is not None:
                settings[key] = str(value)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        settings = {"error": "unable to read nix configuration"}

    return {
        "version": capture(["nix", "--version"]),
        "settings": settings,
    }


def timed_command(phase: str, iteration: int, command: Sequence[str]) -> Sample:
    started = time.perf_counter()
    try:
        completed = run(command)
        exit_code = completed.returncode
    except OSError as error:
        print(f"failed to execute {command[0]}: {error}", file=sys.stderr)
        exit_code = 127
    elapsed = time.perf_counter() - started
    return Sample(
        phase=phase,
        iteration=iteration,
        elapsed_seconds=round(elapsed, 6),
        exit_code=exit_code,
    )


def build_command(target: str, out_link: Path | None = None) -> list[str]:
    command = [
        "nix",
        "build",
        target,
        "--print-build-logs",
    ]
    if out_link is None:
        command.append("--no-link")
    else:
        command.extend(["--out-link", str(out_link)])
    return command


def plan_command(target: str) -> list[str]:
    return ["nix", "build", target, "--dry-run", "--no-link"]


def benchmark_build(target: str, repeat: int) -> list[Sample]:
    samples: list[Sample] = []
    for iteration in range(1, repeat + 1):
        samples.append(timed_command("build", iteration, build_command(target)))
        if samples[-1].exit_code != 0:
            break
    return samples


def benchmark_plan(target: str) -> list[Sample]:
    return [timed_command("plan", 1, plan_command(target))]


def benchmark_activation(target: str, repeat: int) -> list[Sample]:
    samples: list[Sample] = []
    with tempfile.TemporaryDirectory(prefix="dotfiles-nix-benchmark-") as directory:
        out_link = Path(directory) / "activation-package"
        build_sample = timed_command("activation-build", 1, build_command(target, out_link))
        samples.append(build_sample)
        if build_sample.exit_code != 0:
            return samples

        activation_program = out_link / "activate"
        if not activation_program.is_file():
            print(
                f"activation program not found at {activation_program}",
                file=sys.stderr,
            )
            samples.append(Sample("activate", 1, 0.0, 66))
            return samples

        for iteration in range(1, repeat + 1):
            samples.append(
                timed_command("activate", iteration, [str(activation_program)])
            )
            if samples[-1].exit_code != 0:
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark Dubnium Nix build and activation phases",
    )
    parser.add_argument(
        "phase",
        choices=("plan", "build", "activate", "suite"),
        help="phase to benchmark; activation is explicit and may change user state",
    )
    parser.add_argument(
        "--target",
        default=DEFAULT_TARGET,
        help=f"flake target (default: {DEFAULT_TARGET})",
    )
    parser.add_argument(
        "--repeat",
        type=int,
        default=3,
        help="number of build/activation samples (default: 3)",
    )
    parser.add_argument(
        "--json",
        dest="json_path",
        type=Path,
        help="write the complete result as JSON",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.repeat < 1 or args.repeat > 20:
        print("--repeat must be between 1 and 20", file=sys.stderr)
        return 64

    samples: list[Sample] = []
    if args.phase in ("plan", "suite"):
        samples.extend(benchmark_plan(args.target))
    if args.phase in ("build", "suite") and all(s.exit_code == 0 for s in samples):
        samples.extend(benchmark_build(args.target, args.repeat))
    if args.phase == "activate":
        samples.extend(benchmark_activation(args.target, args.repeat))

    result = {
        "schema_version": 1,
        "target": args.target,
        "requested_phase": args.phase,
        "repeat": args.repeat,
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "host": {
            "hostname": platform.node(),
            "platform": platform.platform(),
            "machine": platform.machine(),
            "cpu_count": os.cpu_count(),
        },
        "repository": repository_metadata(),
        "nix": nix_metadata(),
        "samples": [asdict(sample) for sample in samples],
        "summary": summarize(samples),
    }

    print(json.dumps(result, indent=2, sort_keys=True))
    if args.json_path is not None:
        args.json_path.parent.mkdir(parents=True, exist_ok=True)
        args.json_path.write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    return 0 if samples and all(sample.exit_code == 0 for sample in samples) else 1


if __name__ == "__main__":
    raise SystemExit(main())
